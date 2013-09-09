#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define STR_LEN 80
#define STANDART_TIMELIMIT 60
#define STANDART_MEMLIMIT 1e9

#define RESMANAGER_MODIFIER "resource_manager_"
#define MEMORY_CONTROLLER "memory"
#define CPUACCT_CONTROLLER "cpuacct"
#define CGROUP "cgroup"
#define TASKS_FILE "tasks"
#define MEM_LIMIT "memory.limit_in_bytes"
#define MEMSW_LIMIT "memory.memsw.limit_in_bytes"
#define CPU_USAGE "cpuacct.usage"
#define CPU_STAT "cpuacct.stat"
#define MEMSW_MAX_USAGE "memory.memsw.max_usage_in_bytes"

#define CPUINFO_FILE "/proc/cpuinfo"
#define MEMINFO_FILE "/proc/meminfo"
#define VERSION_FILE "/proc/version"
#define MOUNTS_FILE "/proc/mounts"

// This structure holds exit status of executing command, its time and memory
// statistics.
typedef struct
{
	int exit_code;
	int sig_number;
	int memory_exhausted;
	int time_exhausted;
	double wall_time;
	double cpu_time;
	double user_time;
	double sys_time;
	long memory;
} statistics;

// This variable holds command-line parameters, parameters specified for
// cgroups, file descriptors for redirecting stdout/stdeerr, signal number
// which was send to Resource Manager.
struct
{
	// Command-line parameters.
	double timelimit; // In seconds.
	long memlimit; // In bytes.
	char *outputfile; // File for printing statistics.
	char **command; // Command for execution.
	int alarm_time; // Time in ms (10^-3 seconds).

	// Cgroup parameters.
	char *path_to_memory_origin;
	char *path_to_cpuacct_origin;
	char *path_to_memory;
	char *path_to_cpuacct;

	// File descriptors for redirecting stdout/stderr from command.
	int fd_stdout;
	int fd_stderr;

	// If Resource Manager was terminated by signal and this signal was handled
	// then script_signal stores that signal number.
	int script_signal;
} params;

// Pid of child process in which command will be executed.
int pid = 0;

static void kill_created_processes(int signum);
static void exit_res_manager(int exit_code, statistics *stats, const char *err_mes);
static int check_tasks_file(char *);

/* Library functions. */

// Allocates memory by malloc() and checks its return value.
// If it's NULL then Resource Manager will be terminated.
void *xmalloc(size_t size)
{
	void *newmem;

	if (size == 0)
	{
		exit_res_manager(EINVAL, NULL, "Error: tried to perform a zero-length allocation");
	}

	newmem = malloc(size);

	if (newmem == NULL)
	{
		exit_res_manager(errno, NULL, "Error: couldn't allocate a new memory");
	}

	return newmem;
}

// Like xmalloc() but for realloc().
void *xrealloc(void *prev, size_t size)
{
	void *newmem;

	if (size == 0)
	{
		exit_res_manager(EINVAL, NULL, "Error: tried to perform a zero-length allocation");
	}

	newmem = realloc(prev, size);

	if (newmem == NULL)
	{
		exit_res_manager(errno, NULL, "Error: couldn't allocate a new memory");
	}

	return newmem;
}

// Opens file and checks if there were any errors.
FILE *xfopen(const char *filename, const char *mode)
{
	FILE *fp;

	fp = fopen(filename, mode);

	if (fp == NULL)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	return fp;
}

// Gets string representing number.
static const char *itoa(unsigned long n)
{
	int order = 1;
	long broken_n;
	char *str;

	// Gets order of number.
	for (broken_n = n; (broken_n = broken_n / 10) > 0; order++);

	str = (char *)xmalloc(sizeof(char) * (order + 1));

	for (int i = order - 1, broken_n = n; i >= 0; i--)
	{
		str[i] = broken_n % 10 + '0';
		broken_n = broken_n / 10;
	}

	str[order] = '\0';

	return str;
}

// Concatenates variable number of strings (NULL represents the end of this
// list) and returns result.
static char *concat(const char *first, ...)
{
	char *result = (char *)xmalloc((strlen(first) + 1) * sizeof(char));
	const char *tmp;
	va_list valist;

	va_start(valist, first);

	strcpy(result, first);

	while ((tmp = va_arg(valist, const char *)) != NULL)
	{
		result = (char *)xrealloc(result, (strlen(result) + strlen(tmp) + 1) * sizeof(char));
		strcat(result, tmp);
	}

	va_end(valist);

	return result;
}

// Gets current time in microseconds.
static double gettime(void)
{
	struct timeval time;

	gettimeofday(&time, NULL);

	return time.tv_sec + time.tv_usec / 1000000.0;
}

// Returns true, if string is number.
static int is_number(char *str)
{
	if (str == NULL)
	{
		return 0;
	}

	for (int i = 0; str[i] != '\0'; i++)
	{
		if (!isdigit(str[i]))
		{
			return 0;
		}
	}

	return 1;
}

// Read string from opened file into dynamic array.
static char *read_string_from_opened_file(FILE *file)
{
	char *line;

	if (file == NULL)
	{
		return NULL;
	}

	line = (char *)xmalloc(sizeof(char) * (STR_LEN + 1));

	if (fgets(line, STR_LEN, file) == NULL)
	{
		return NULL; // EOF
	}

	while(strchr(line, '\n') == NULL)  // not full string
	{
		char *tmp_line = (char *)xrealloc(line, sizeof(char) * (strlen(line) + STR_LEN + 1));
		char part_of_line[STR_LEN];
		fgets(part_of_line, STR_LEN, file);
		line = tmp_line;
		strcat(line, part_of_line);
	}

	return line;
}



// Read first string from file.
static char *read_string_from_file(const char *path)
{
	FILE *file = xfopen(path, "rt");
	char *line;

	line = read_string_from_opened_file(file);

	fclose(file);

	return line;
}

// Get cpu info.
static const char *get_cpu_info(void)
{
	FILE *file;
	char *line;

	file = xfopen(CPUINFO_FILE, "rt");

	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char *arg = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s", arg, value);

		if (strcmp(arg, "model") == 0 && strcmp(value, "name") == 0)
		{
			int i = 0;
			int num_of_spaces;

			while (line[i] != ':')
			{
				i++;
			}

			i += 2;
			num_of_spaces = i;

			while (line[i] != '\0')
			{
				line[i - num_of_spaces] = line[i];
				i++;
			}

			line[i - num_of_spaces] = '\0';

			fclose(file);
			free(arg);
			free(value);

			return line;
		}

		free(arg);
		free(value);
		free(line);
	}

	fclose(file);

	return NULL;
}

// Get memory size.
static const char *get_memory_info(void)
{
	FILE *file;
	char *line;

	file = xfopen(MEMINFO_FILE,"rt");

	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char *arg = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s", arg, value);

		if (strcmp(arg, "MemTotal:") == 0)
		{
			long mem_size = atol(value);

			mem_size *= 1000;

			fclose(file);
			free(arg);
			free(value);
			free(line);

			return itoa(mem_size);
		}

		free(arg);
		free(value);
		free(line);
	}

	fclose(file);

	return NULL;
}

// Get kernel version.
static const char *get_kernel_info(void)
{
	char *line = read_string_from_file(VERSION_FILE);
	char *arg;
	char *value;
	int i = 0;

	if (line == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: couldn't open file", VERSION_FILE, NULL));
	}

	arg = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
	value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

	sscanf(line, "%s %s %s", arg, arg, value);

	while (value[i] != 0)
	{
		if (value[i] == '-')
		{
			value[i] = 0;
			break;
		}
		i++;
	}

	free(arg);
	free(line);

	return value;
}

/* Control groups handling. */

// Find path_to_memory and path_to_cpuacct.
static void find_cgroup_location(void)
{
	const char *path = MOUNTS_FILE;
	FILE *results;
	char *line = NULL;

	results = xfopen(path, "rt");

	while ((line = read_string_from_opened_file(results)) != NULL)
	{
		char *name = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *path = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *type = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *subsystems = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s %s %s", name, path, type, subsystems);

		if (strcmp(type, CGROUP) == 0 && strstr(subsystems, CPUACCT_CONTROLLER))
		{
			params.path_to_cpuacct = (char *)xmalloc(sizeof(char) * (strlen(path) + 1));
			strcpy(params.path_to_cpuacct, path);
			params.path_to_cpuacct_origin = (char *)xmalloc(sizeof(char) * (strlen(path) + 1));
			strcpy(params.path_to_cpuacct_origin, path);
		}

		if (strcmp(type, CGROUP) == 0 && strstr(subsystems, MEMORY_CONTROLLER))
		{
			params.path_to_memory = (char *)xmalloc(sizeof(char) * (strlen(path) + 1));
			strcpy(params.path_to_memory, path);
			params.path_to_memory_origin = (char *)xmalloc(sizeof(char) * (strlen(path) + 1));
			strcpy(params.path_to_memory_origin, path);
		}

		free(name);
		free(path);
		free(type);
		free(subsystems);
		free(line);
	}

	if (params.path_to_memory == NULL)
	{
		exit_res_manager(EACCES, NULL, "Error: you need to mount memory cgroup: sudo mount -t cgroup -o memory <name> <path>");
	}

	if (params.path_to_cpuacct == NULL)
	{
		exit_res_manager(EACCES, NULL, "Error: you need to mount cpuacct cgroup: sudo mount -t cgroup -o cpuacct <name> <path>");
	}
}

/*
 * Create full name for cgroup directory:
 * <path from /proc/mounts>/<resmanager_dir>/resource_manager_<pid>.
 */
static void get_cgroup_name(char *resmanager_dir)
{
	// Pid of process.
	const char *pid_name = itoa(getpid());

	params.path_to_memory = concat(params.path_to_memory, "/", resmanager_dir, "/", RESMANAGER_MODIFIER, pid_name, NULL);
	params.path_to_cpuacct = concat(params.path_to_cpuacct, "/", resmanager_dir, "/", RESMANAGER_MODIFIER, pid_name, NULL);
	free((void *)pid_name);
}

// Create new cgroups for known path (<path from /proc/mounts>/<resmanager_dir>/resource_manager_<pid>)
static void create_cgroup(void)
{
	// If path to cpuacct and path to memory are equal then only one directory will be made.
	char *paths[] = {params.path_to_memory, params.path_to_cpuacct};
	int i;
	int iterations = 1;
	int mkdir_errno;

	if (strcmp(params.path_to_memory, params.path_to_cpuacct) == 0)
	{
		iterations = 0;
	}

	for (i = 0; i <= iterations; i++)
	{
		if (mkdir(paths[i], 0777) == -1)
		{
			mkdir_errno = errno;
			if (mkdir_errno == EACCES) // Permission error.
			{
				if (strcmp(paths[i], params.path_to_memory) == 0)
				{
					exit_res_manager(mkdir_errno, NULL, concat(
						"Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", params.path_to_memory_origin, NULL));
				}
				else
				{
					exit_res_manager(mkdir_errno, NULL, concat(
						"Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", params.path_to_cpuacct_origin, NULL));
				}
			}
			else if (mkdir_errno == EEXIST) // Directory exists.
			{
				if (check_tasks_file(paths[i])) // Tasks file is empty.
				{
					rmdir(paths[i]);
					mkdir(paths[i], 0777);
				}
				else
				{
					exit_res_manager(mkdir_errno, NULL, concat(
						"There is control group with running processes in ", paths[i], NULL));
				}
			}
			else // other errors
			{
				exit_res_manager(mkdir_errno, NULL, concat("Error: couldn't create ", paths[i], NULL));
			}
		}
	}
}

// Set specified parameter into specified file in specified cgroup. In case of
// error Resource Manager will be terminated.
static void set_cgroup_parameter(const char *file_name, const char *controller, const char *value)
{
	char *path = concat(controller, "/", file_name, NULL);
	FILE *file;

	chmod(path, 0666);

	if (access(path, F_OK) == -1) // Chech if file exists.
	{
		if (strcmp(file_name, MEMSW_LIMIT) == 0) // special error text for memsw
		{
			exit_res_manager(ENOENT, NULL, "Error: memory control group doesn't have swap extension."
				" You need to set swapaccount=1 as a kernel boot parameter to be able to compute 'memory+Swap' usage");
		}

		exit_res_manager(errno, NULL, concat("Error: file ", path, " doesn't exist", NULL));
	}

	file = xfopen(path, "w+");

	fputs(value, file);
	fclose(file);
	free(path);
}

/*
 * Get specified parameter from specified file in specified cgroup.
 * In case of error during reading Resource Manager will be terminated.
 * Return readed string.
 */
static char *get_cgroup_parameter(char *file_name, const char *controller)
{
	char *str;
	char *path = concat(controller, "/", file_name, NULL);

	str = read_string_from_file(path);

	if (str == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: couldn't read parameter from ", path, NULL));
	}

	free(path);

	return str;
}

// Set memory limit in cgroup with memory controller.
static void set_memlimit(void)
{
	set_cgroup_parameter(MEM_LIMIT, params.path_to_memory, itoa(params.memlimit));
	set_cgroup_parameter(MEMSW_LIMIT, params.path_to_memory, itoa(params.memlimit));
}

// Add pid of created process to tasks file.
static void add_task(int pid)
{
	set_cgroup_parameter(TASKS_FILE, params.path_to_memory, itoa(pid));
	if (strcmp(params.path_to_memory, params.path_to_cpuacct) != 0)
	{
		set_cgroup_parameter(TASKS_FILE, params.path_to_cpuacct, itoa(pid));
	}
}

// Read line from cpuacct.stats file and return it's value.
static char *get_cpu_stat_line(char *line)
{
	char *result;

	if (line == NULL)
	{
		exit_res_manager(ENOENT, NULL, "Error: couldn't read string from file cpuacct.stats");
	}
	else
	{
		char *arg = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s", arg, value);
		result = value;

		free(line);
		free(arg);
	}

	return result;
}

/*
 * Read file cpuacct.stats with special format:
 * user <number_in_ms>
 * sys <number_in_ms>.
*/
static void read_cpu_stats(statistics *stats)
{
	FILE *file;
	char *line;
	char *path_cpu_stat = concat(params.path_to_cpuacct, "/", CPU_STAT, NULL);

	file = xfopen(path_cpu_stat, "rt");

	line = read_string_from_opened_file(file);
	stats->user_time = atof(get_cpu_stat_line(line)) / 1e2;

	line = read_string_from_opened_file(file);
	stats->sys_time = atof(get_cpu_stat_line(line)) / 1e2;

	free(path_cpu_stat);
	fclose(file);
}

// Read statistics.
static void get_memory_and_cpu_usage(statistics *stats)
{
	char *cpu_usage;
	char *memory_usage = get_cgroup_parameter(MEMSW_MAX_USAGE, params.path_to_memory);

	stats->memory = atol(memory_usage);
	free(memory_usage);

	cpu_usage = get_cgroup_parameter(CPU_USAGE, params.path_to_cpuacct);
	stats->cpu_time = atol(cpu_usage) / 1e9;
	free(cpu_usage);

	// User and system time (not standart format).
	read_cpu_stats(stats);
}

// Delete cgroups.
static void remove_cgroup(void)
{
	if (params.path_to_memory != NULL)
	{
		rmdir(params.path_to_memory);
	}
	if (strcmp(params.path_to_cpuacct, params.path_to_memory) != 0)
	{
		if (params.path_to_cpuacct != NULL)
		{
			rmdir(params.path_to_cpuacct);
		}
	}
}

/* Main Resource Manager functions. */

// Print stats into file/console.
static void print_stats(int exit_code, int signal, statistics *stats, const char *err_mes)
{
	FILE *out;
	const char *kernel = get_kernel_info();
	const char *memory = get_memory_info();
	const char *cpu = get_cpu_info();

	if (params.outputfile == NULL)
	{
		out = stdout;
	}
	else
	{
		out = fopen(params.outputfile, "w");

		if (out == NULL)
		{
			fprintf(stdout, "Can't create file %s\n", params.outputfile);
			out = stdout;
		}
	}

	fprintf(out, "System settings:\n");
	fprintf(out, "\tkernel version: %s\n", kernel);
	fprintf(out, "\tcpu: %s", cpu);
	fprintf(out, "\tmemory: %s bytes\n", memory);

	free((void *)kernel);
	free((void *)memory);
	free((void *)cpu);

	fprintf(out, "Resource manager settings:\n");
	fprintf(out, "\tmemory limit: %ld bytes\n", params.memlimit);
	fprintf(out, "\ttime limit: %.0f ms\n", params.timelimit * 1000);
	fprintf(out, "\tcommand: ");

	if (params.command != NULL)
	{
		int i = 0;
		while (params.command[i] != NULL)
		{
			fprintf(out, "%s ", params.command[i]);
			i++;
		}
	}

	fprintf(out, "\n");
	fprintf(out, "\tcgroup memory controller: %s\n", params.path_to_memory);
	fprintf(out, "\tcgroup cpuacct controller: %s\n", params.path_to_cpuacct);
	fprintf(out, "\toutputfile: %s\n", params.outputfile);

	fprintf(out, "Resource manager execution status:\n");

	if (err_mes != NULL)
	{
		fprintf(out, "\texit code (resource manager): %i (%s)\n", exit_code, err_mes);
	}
	else
	{
		fprintf(out, "\texit code (resource manager): %i\n", exit_code);
	}

	if (signal != 0)
	{
		fprintf(out, "\tkilled by signal (resource manager): %i (%s)\n", signal, strsignal(signal));
	}

	if (exit_code == 0 && pid > 0 && stats != NULL) // Script finished.
	{
		fprintf(out, "Command execution status:\n");
		fprintf(out, "\texit code: %i\n", stats->exit_code);

		if (stats->sig_number != 0)
		{
			fprintf(out, "\tkilled by signal: %i (%s)\n", stats->sig_number, strsignal(stats->sig_number));
		}

		if (stats->cpu_time > params.timelimit)
		{
			fprintf(out, "\ttime exhausted\n");
		}
		else if (stats->memory > params.memlimit)
		{
			fprintf(out, "\tmemory exhausted\n");
		}
		else
		{
			fprintf(out, "\tcompleted in limits\n");
		}

		fprintf(out, "Time usage statistics:\n");
		fprintf(out, "\twall time: %.0f ms\n", stats->wall_time * 1000);
		fprintf(out, "\tcpu time: %.0f ms\n", stats->cpu_time * 1000);
		fprintf(out, "\tuser time: %.0f ms\n", stats->user_time * 1000);
		fprintf(out, "\tsystem time: %.0f ms\n", stats->sys_time * 1000);

		fprintf(out, "Memory usage statistics:\n");
		fprintf(out, "\tpeak memory usage: %ld bytes\n", stats->memory);
	}

	if (params.outputfile != NULL)
	{
		fclose(out);
	}
}

// Actions, which should be made at the end of the program: kill all created processes (if they were created), print statistics, remove cgroups.
static void exit_res_manager(int exit_code, statistics *stats, const char *err_mes)
{
	// Close files, in which stdout/stderr was redirected.
	if (params.fd_stdout != -1)
	{
		close(params.fd_stdout);
	}
	if (params.fd_stderr != -1)
	{
		close(params.fd_stderr);
	}

	// Finish all running processes.
	kill_created_processes(SIGKILL);

	// Get statistics.
	if (stats != NULL)
	{
		get_memory_and_cpu_usage(stats);
	}

	// Remove cgroups.
	remove_cgroup();

	// Print statistics.
	print_stats(exit_code, params.script_signal, stats, err_mes);

	// Finish Resource Manager.
	if (exit_code != 0)
	{
		exit(exit_code);
	}
}

/*
 * Config file format:
 *	<file> <value>
 * Into each <file> will be written <value>.
 * Returns err_mes or NULL in case of success.
 */
static char *read_config_file(char *configfile)
{
	FILE *file;
	char *line;

	file = xfopen(configfile, "rt");

	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char *file_name = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s", file_name, value);
		set_cgroup_parameter(file_name, params.path_to_memory, value);

		free(line);
		free(file_name);
		free(value);
	}
	fclose(file);

	return NULL;
}

// Check tasks file => return 1 if it's clean, 0 otherwise.
static int check_tasks_file(char *path_to_cgroup)
{
	char *path = concat(path_to_cgroup, "/", TASKS_FILE, NULL);
	FILE *results;
	char *str;

	results = xfopen(path, "rt");
	free(path);

	if (results == NULL)
	{
		return 0;
	}

	if((str = read_string_from_opened_file(results)) != NULL) // There is some string.
	{
		fclose(results);
		free(str);
		return 0;
	}

	fclose(results);

	return 1;
}

// Finish all created processes.
static void kill_created_processes(int signum)
{
	if (pid > 0)
	{
		char *path;
		char *line = NULL;
		FILE *results;

		// Kill main created process.
		kill(pid, signum);

		// Kill any other created processes.
		path = concat(params.path_to_memory, "/", TASKS_FILE, NULL);
		results = fopen(path,"rt");

		if (results == NULL)
		{
			return; // File already was deleted.
		}

		free(path);

		while ((line = read_string_from_opened_file(results)) != NULL)
		{
			kill(atoi(line),signum);
			free(line);
		}

		fclose(results);
	}
}

// Handle signals.
static void terminate(int signum)
{
	params.script_signal = signum;
	kill_created_processes(SIGKILL);
	exit_res_manager(EINTR, NULL, "Killed by signal");
}

// Set timer for checking time limit.
static void set_timer(int alarm_time)
{
	struct itimerval *value = xmalloc(sizeof(struct itimerval));

	value->it_value.tv_sec = alarm_time / 1000;
	value->it_value.tv_usec = (alarm_time % 1000) * 1000;
	value->it_interval.tv_usec = 0;
	value->it_interval.tv_sec = 0;
	setitimer(ITIMER_REAL, value, NULL);

	free(value);
}

// Stop timer for checking time limit.
static void stop_timer(void)
{
	struct itimerval *value = xmalloc(sizeof(struct itimerval));

	value->it_value.tv_sec = 0;
	value->it_value.tv_usec = 0;
	value->it_interval.tv_usec = 0;
	value->it_interval.tv_sec = 0;
	setitimer(ITIMER_REAL, value, NULL);

	free(value);
}

// Handle SIGALRM, check time limit.
static void check_time(int signum)
{
	char *cpu_usage = get_cgroup_parameter(CPU_USAGE, params.path_to_cpuacct);
	double cpu_time = atof(cpu_usage) / 1e9;

	free(cpu_usage);

	if (cpu_time >= params.timelimit)
	{
		kill_created_processes(SIGKILL);
	}
	else
	{
		set_timer(params.alarm_time);
	}
}

// Redirect stderr/stdout into file.
static void redirect(int fd, char *path)
{
	int filedes[2];

	if (path == NULL)
	{
		return;
	}

	close(fd); // Close stdout/stderr in command execution.

	filedes[0] = fd;

	// Create new file, in which stdout/stderr will be redirected.
	filedes[1] = open(path, O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
	if (filedes[1] == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	// Duplicate file descriptor.
	if (dup2(filedes[0], filedes[1]) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	// Create a pipe.
	if (pipe(filedes) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	// Save file descriptor, in which stdout/stderr will be redirected.
	if (fd == 1)
	{
		params.fd_stdout = filedes[1];
	}
	else if (fd == 2)
	{
		params.fd_stderr = filedes[1];
	}
	else // Not stdout/stderr.
	{
		exit_res_manager(EINVAL, NULL, "Error: only stdout/stderr can be redirected.");
	}
}

// Print help
static void print_usage(void)
{
	printf(
		"Usage: [options] [command] [arguments] \n"

		"Options:\n"
		"\t-h\n"
		"\t\tPrint help.\n"
		"\t-m <number>\n"
		"\t\tSet memory limit to <number> bytes. Supported binary prefixes: Kb, Mb, Gb, Kib, Mib, Gib; 1Kb = 1000 bytes,\n"
		"\t\t1Mb = 1000^2, 1Gb = 1000^3, 1Kib = 1024 bytes, 1Mib = 1024^2, 1Gib = 1024^3 (standardized in IEC 60027-2).\n"
		"\t\tIf there is no binary prefix then size will be specified in bytes. Default value: 100Mb.\n"
		"\t-t <number>\n"
		"\t\tSet time limit to <number> seconds. Supported prefixes: ms, min; 1ms = 0.001 seconds, 1min = 60 seconds. \n"
		"\t\tIf there is no prefix then time will be specified in seconds. Default value: 1min.\n"
		"\t-o <file>\n"
		"\t\tPrint statistics into file with name <file>. If option isn't specified statistics will be printed into stdout.\n"
		"\t-l <dir>\n"
		"\t\tSpecify subdirectory in control group directory for Resource manager. If option isn't specified then will be used\n"
		"\t\tcontrol group directory itself.\n"
		"\t--interval <number>\n"
		"\t\tSpecify time (in ms) interval in which time limit will be checked. Default value: 1000 (1 second).\n"
		"\t--stdout <file>\n"
		"\t\tRedirect command stdout into <file>. If option isn't specified then stdout won't be redirected for command.\n"
		"\t--stderr <file>\n"
		"\t\tRedirect command stderr into <file>. If option isn't specified then stderr won't be redirected for command.\n"
		"\t-l <dir>\n"
		"\t\tSpecify config file. Config file contains pairs <parameter> <value>, parameter - name of the control group \n"
		"\t\tparameter, value will be specified for this parameter.\n"

		"Requirements:\n"
		"\tResource manager is using control groups, which require at least kernel 2.6.24 version.\n"
		"\tBefore control groups can be used temporarily file system should be mounted by command:\n"
		"\t\tsudo mount -t cgroup -o cpuacct,memory <device> <cgroup_directory>\n"
		"\t\t\tcpuacct,memory - controllers\n"
		"\t\t\t<device> - name of device (control group)\n"
		"\t\t\t<cgroup_directoty> - path to control group directory.\n"
		"\tIf control groups with controllers cpuacct and memory already has been mounted then there is no need to mount them.\n"
		"\tInformation about all mounted file systems is contained in file /proc/mounts. For specifing subdirectory in control\n"
		"\tgroup directory there is an option -l <dir>.\n"
		"\tAfter mounting permissions should be changed for control group directory:\n"
		"\t\tsudo chmod o+wt <cgroup_directory> or sudo chmod o+wt <path_to_cgroup>/<dir>.\n"
		"\tFor correct memory computation (memory + swap) next kernel flags should be set to enable:\n"
		"\t\tCONFIG_CGROUP_MEM_RES_CTLR_SWAP and CONFIG_CGROUP_MEM_RES_CTLR_SWAP_ENABLED\n"
		"\tor if kernel > 3.6 version\n"
		"\t\tCONFIG_MEMCG_SWAP and CONFIG_MEMCG_SWAP_ENABLED\n"
		"\tAlternatively kernel boot parameter swapaccount should be set to 1.\n"
		"\tMinimal kernel version for swap computation is 2.6.34.\n"

		"Description:\n"
		"\tResource manager runs specified command with given arguments. For this command will be created control group. While\n"
		"\tcommand is running Resource manager checks cpu time and memory usage. If command uses more cpu time or memory then\n"
		"\tit will be killed by signal SIGKILL. If signal was send to the command or any error occured during it's execution then\n"
		"\tcommand will be finished. When command finishes (normally or not), statistics will be written into the specified file\n"
		"\t(or to standart output), all created control groups will be deleted.\n"

		"Exit status:\n"
		"\tIf there was an error during control group creation (control group is not mounted, wrong permissions, swapaccount=0)\n"
		"\tResource manager will return error code and discription of error into output file and will finish it's work.\n"
		"\tIf there were any errors during Resource manager execution or it was killed a by signal then command will be finished by\n"
		"\tsignal SIGKILL, statistics will be printed with error code or signal number, control groups will be deleted.\n"
		"\tOtherwise return code is 0.\n"

		"Output format:\n"
		"\tSystem settings:\n"
		"\t\tkernel version: <version>\n"
		"\t\tcpu: <name of cpu>\n"
		"\t\tmemory: <max size> bytes\n"
		"\tResource manager settings:\n"
		"\t\tmemory limit: <number> bytes\n"
		"\t\ttime limit: <number> ms\n"
		"\t\tcommand: command [arguments]\n"
		"\t\tcgroup memory controller: <path to memory control group>\n"
		"\t\tcgroup cpuacct controller: <path to cpuacct control group>\n"
		"\t\toutputfile: <file>\n"
		"\tResource manager execution status:\n"
		"\t\texit code (resource manager): <number> (<description>)\n"
		"\t\tkilled by signal (resource manager): <number> (<name>)\n"
		"\tCommand execution status:\n"
		"\t\texit code: <number>\n"
		"\t\tkilled by signal: <number> (<name>)\n"
		"\t\tcompleted in limits / memory exhausted / time exhausted\n"
		"\tTime usage statistics:\n"
		"\t\twall time: <number> ms\n"
		"\t\tcpu time: <number> ms\n"
		"\t\tuser time: <number> ms\n"
		"\t\tsystem time: <number> ms\n"
		"\tMemory usage statistics:\n"
		"\t\tpeak memory usage: <number> bytes\n"
	);
}

int main(int argc, char **argv)
{
	char *stdoutfile = NULL;
	char *stderrfile = NULL;
	char *resmanager_dir = ""; // Path to Resource Manager directory in control groups.
	char *configfile = NULL;
	int i;
	int comm_arg = 0;
	int c;
	int is_options_ended = 0;
	int option_index = 0;
	double time_before, time_after;
	int wait_errno;
	static struct option long_options[] = {
		{"interval", 1, 0, 'i'},
		{"stdout", 1, 0, 's'},
		{"stderr", 1, 0, 'e'},
		{"config", 1, 0, 'c'},
		{0, 0, 0, 0}
	};
	int status;
	int wait_res;
	statistics *stats;

	// Set standart values for parameters.
	params.timelimit = STANDART_TIMELIMIT;
	params.memlimit = STANDART_MEMLIMIT;
	params.outputfile = NULL;
	params.command = NULL;
	params.alarm_time = 1000;
	params.path_to_memory_origin = NULL;
	params.path_to_cpuacct_origin = NULL;
	params.path_to_memory = NULL;
	params.path_to_cpuacct = NULL;
	params.fd_stdout = -1;
	params.fd_stderr = -1;
	params.script_signal = 0;

	// Set handlers for all signals except SIGSTOP, SIGKILL, SIGUSR1, SIGUSR2, SIGALRM, SIGWINCH.
	for (i = 1; i <= 31; i++)
	{
		if (i == SIGSTOP || i == SIGKILL ||i == SIGCHLD || i == SIGUSR1 || i == SIGUSR2 || i == SIGALRM || i == SIGWINCH)
		{
			continue;
		}
		if (signal(i, terminate) == SIG_ERR)
		{
			exit_res_manager(errno, NULL, strerror(errno));
		}
	}

	// Parse command line.
	while ((c = getopt_long(argc, argv, "-hm:t:o:l:0", long_options, &option_index)) != -1)
	{
		switch(c)
		{
		case 'h':
			print_usage();
			exit(0);
		case 'i':
			if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, "Error: expected integer number in ms as value of --interval");
			}
			params.alarm_time = atoi(optarg);
			break;
		case 'c':
			configfile = optarg;
			break;
		case 's':
			stdoutfile = optarg;
			break;
		case 'e':
			stderrfile = optarg;
			break;
		case 'l':
			resmanager_dir = optarg;
			break;
		case 'm':
			params.memlimit = atol(optarg);
			if (strstr(optarg, "Kb") != NULL)
			{
				params.memlimit *= 1000;
			}
			else if (strstr(optarg, "Mb") != NULL)
			{
				params.memlimit *= 1000 * 1000;
			}
			else if (strstr(optarg, "Gb") != NULL)
			{
				params.memlimit *= 1000;
				params.memlimit *= 1000;
				params.memlimit *= 1000;
			}
			else if (strstr(optarg, "Kib") != NULL)
			{
				params.memlimit *= 1024;
			}
			else if (strstr(optarg, "Mib") != NULL)
			{
				params.memlimit *= 1024 * 1024;
			}
			else if (strstr(optarg, "Gib") != NULL)
			{
				params.memlimit *= 1024;
				params.memlimit *= 1024;
				params.memlimit *= 1024;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, "Error: expected integer number with Kb|Mb|Gb|Kib|Mib|Gib| modifiers as value of -m");
			}
			break;
		case 't':
			params.timelimit = atof(optarg);
			if (strstr(optarg, "ms") != NULL)
			{
				params.timelimit /= 1000;
			}
			else if (strstr(optarg, "min") != NULL)
			{
				params.timelimit *= 60;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, "Error: expected number with ms|min| modifiers as value of -t");
			}
			break;
		case 'o':
			params.outputfile = optarg;
			break;
		default:
			is_options_ended = 1;
		}

		if (is_options_ended)
		{
			break;
		}
	}

	if (!is_options_ended)
	{
		exit_res_manager(EINVAL, NULL, "Error: command to be executed wasn't specified. See help for details");
	}

	optind--; // Optind - index of first argument in command; index of command is needed.
	params.command = (char **)xmalloc(sizeof(char *) * (argc - optind + 1));
	for (i = 0; i < argc - optind; i++)
	{
		params.command[i] = argv[optind + i];
		comm_arg++;
	}
	params.command[comm_arg] = NULL;

	// Create new cgroup for command.
	find_cgroup_location();
	get_cgroup_name(resmanager_dir);
	create_cgroup();

	// Configure cgroup.
	set_memlimit();
	if (configfile != NULL) // configfile was specified
	{
		char *err_mes = read_config_file(configfile);
		if (err_mes != NULL)
		{
			exit_res_manager(ENOENT, NULL, err_mes);
		}
	}

	// Set timer for checking time limit.
	if (signal(SIGALRM, check_time) == SIG_ERR)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}
	set_timer(params.alarm_time);

	// Save time before executing command.
	time_before = gettime();

	// Create new process for command.
	pid = fork();
	if (pid == 0) // Child process.
	{
		redirect(1, stdoutfile); // Redirect stdout.
		redirect(2, stderrfile); // Redirect stderr.
		add_task(getpid()); // Attach process to cgroup.
		execvp(params.command[0], params.command); // Execute command.
		exit(errno); // Exit on error.
	}
	else if (pid == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	// Parent waits untill the child will be completed or killed.
	wait_res = wait4(pid, &status, 0, NULL);
	wait_errno = errno;
	if (wait_res == -1)
	{
		if (wait_errno != EINTR) // don't include error "interrupted by signal"
		{
			exit_res_manager(errno, NULL, strerror(errno));
		}
	}

	// Get time after command has been executed.
	time_after = gettime();

	// Stop checking time limit.
	stop_timer();

	// Create statistics.
	stats = (statistics *)xmalloc(sizeof(statistics));

	// Compute wall time.
	stats->wall_time = time_after - time_before;

	// If wait was interrupted by signal and exit code, signal number are unknown.
	if (wait_errno == EINTR)
	{
		stats->exit_code = EINTR;
		stats->sig_number = SIGKILL;
	}
	else // Wait didn't failed.
	{
		stats->exit_code = WEXITSTATUS(status);
		if (WIFSIGNALED(status))
		{
			stats->sig_number = WTERMSIG(status);
		}
		else
		{
			stats->sig_number = 0;
		}
	}

	// Finish normal execution. So no error is specified as a first parameter.
	exit_res_manager(0, stats, NULL);

	return 0;
}
