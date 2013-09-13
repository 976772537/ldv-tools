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
#define TASKS "tasks"
#define MEM_LIMIT "memory.limit_in_bytes"
#define MEMSW_LIMIT "memory.memsw.limit_in_bytes"
#define CPU_USAGE "cpuacct.usage"
#define CPU_STAT "cpuacct.stat"
#define MEMSW_MAX_USAGE "memory.memsw.max_usage_in_bytes"
#define MEM_MAX_USAGE "memory.max_usage_in_bytes"

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
static struct
{
	// Command-line parameters.
	double timelimit; // In seconds.
	long memlimit; // In bytes.
	char *fout; // File for printing statistics.
	char **command; // Command for execution.
	int alarm_time; // Time in ms (10^-3 seconds).

	// Control group parameters.
	char *cgroup_memory_origin;
	char *cgroup_cpuacct_origin;
	char *cgroup_memory;
	char *cgroup_cpuacct;

	// File descriptors for redirecting stdout/stderr from command.
	int stdout;
	int stderr;

	// Signal number that terminates Resource Manager.
	int script_signal;
} params;

// Pid of child process in which command will be executed.
static int pid = 0;

/* Functions prototypes. */

static void add_task(int pid);
static const char *concat(const char *first, ...);
static int check_tasks(const char *cgroup);
static void check_time(int signum);
static void create_cgroup_controllers(const char *resmanager_dir);
static void exit_res_manager(int exit_code, statistics *stats, const char *err_mes);
static void find_cgroup(void);
static const char *get_cgroup_parameter(const char *fname, const char *controller);
static const char *get_kernel_info(void);
static void get_memory_and_cpu_usage(statistics *stats);
static const char *get_memory_info(void);
static const char *get_time(const char *line);
static void get_user_and_system_time(statistics *stats);
static const char *get_kernel_info(void);
static double gettime(void);
static void kill_created_processes(int signum);
static int is_number(char *str);
static const char *itoa(unsigned long n);
static void print_stats(int exit_code, int signal, statistics *stats, const char *err_mes);
static void print_usage(void);
static const char *read_first_string_from_file(const char *fname);
static const char *read_string_from_fp(FILE *fp);
static void redirect(int fd, const char *fname);
static void remove_cgroup_controllers(void);
static void set_cgroup_parameter(const char *fname, const char *controller, const char *value);
static void set_config(char *fconfig);
static void set_memlimit(void);
static void set_timer(int alarm_time);
static void stop_timer(void);
static void terminate(int signum);
static void *xmalloc(size_t size);
static FILE *xfopen(const char *fname, const char *mode);
static void *xrealloc(void *prev, size_t size);

/* Library functions. */

// Allocate memory by malloc(). Finish Resource Manager in case of any error.
static void *xmalloc(size_t size)
{
	void *newmem;
	 
	if (size == 0)
	{
		exit_res_manager(EINVAL, NULL, "Error: tried to perform a zero-length allocation");
	}

	newmem = malloc(size);

	if (newmem == NULL)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	return newmem;
}

// Like xmalloc() but for realloc().
static void *xrealloc(void *prev, size_t size)
{
	void *newmem;

	if (size == 0)
	{
		exit_res_manager(EINVAL, NULL, "Error: tried to perform a zero-length allocation");
	}

	newmem = realloc(prev, size);

	if (newmem == NULL)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	return newmem;
}

// Open file. Finish Resource Manager in case of any error.
static FILE *xfopen(const char *fname, const char *mode)
{
	FILE *fp;

	fp = fopen(fname, mode);

	if (fp == NULL)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	return fp;
}

// Get string representing number.
static const char *itoa(unsigned long n)
{
	int order = 1;
	long broken_n;
	char *str;

	// Get order of number.
	for (broken_n = n; (broken_n = broken_n / 10) > 0; order++);

	str = (char *)xmalloc(sizeof(char) * (order + 1));
	
	// Get string representation of n.
	for (int i = order - 1, broken_n = n; i >= 0; i--)
	{
		str[i] = broken_n % 10 + '0';
		broken_n = broken_n / 10;
	}
	
	// Last byte.
	str[order] = '\0';

	return str;
}

// Concatenate variable number of strings (NULL represents the end of this
// list) and return resulting string (additional memory in this function).
static const char *concat(const char *first, ...)
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

// Get current time in microseconds.
static double gettime(void)
{
	struct timeval time;

	gettimeofday(&time, NULL);

	return time.tv_sec + time.tv_usec / 1000000.0;
}

// Return true, if string is number.
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

// Return current string terminating with '\n' or EOF from opened file.
// NULL is returned if file wasn't opened or current file position is EOF.
static const char *read_string_from_fp(FILE *fp)
{
	char *line;

	// Return NULL if file is NULL.
	if (fp == NULL)
	{
		return NULL;
	}

	line = (char *)xmalloc(sizeof(char) * (STR_LEN + 1));

	// Return NULL if current file position is EOF. 
	if (fgets(line, STR_LEN, fp) == NULL)
	{
		return NULL;
	}

	// Reallocate memory for string if current string length is more then STR_LEN.
	while(strchr(line, '\n') == NULL)  
	{
		char *tmp_line = (char *)xrealloc(line, sizeof(char) * (strlen(line) + STR_LEN + 1));
		char part_of_line[STR_LEN];

		fgets(part_of_line, STR_LEN, fp);
		line = tmp_line;
		strcat(line, part_of_line);
	}

	return line;
}

// Return first string from file.
static const char *read_first_string_from_file(const char *fname)
{
	FILE *fp = xfopen(fname, "rt");
	const char *line;

	line = read_string_from_fp(fp);

	fclose(fp);

	return line;
}

// Get cpu info.
static const char *get_cpu_info(void)
{
	FILE *fp;
	const char *line;
	char *broken_line = NULL;

	fp = xfopen(CPUINFO_FILE, "rt");

	while ((line = read_string_from_fp(fp)) != NULL)
	{
		char *arg = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s", arg, value);
		
		// Find string "model name : <cpu_model>"
		if (strcmp(arg, "model") == 0 && strcmp(value, "name") == 0)
		{
			int i = 0;
			int num_of_spaces;

			broken_line = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
			strcpy(broken_line, line);
			
			// Delete all white spaces from line.
			for (i = 0; broken_line[i] != ':'; i++);

			i += 2;
			num_of_spaces = i;
			
			// Get to format "cpu_name".
			for (;broken_line[i] != '\0'; i++)
			{
				broken_line[i - num_of_spaces] = line[i];
			}

			broken_line[i - num_of_spaces] = '\0';

			fclose(fp);
			free(arg);
			free(value);

			return (const char *)broken_line;
		}

		free(arg);
		free(value);
		free((void *)line);
	}

	fclose(fp);

	return NULL;
}

// Get memory size.
static const char *get_memory_info(void)
{
	FILE *fp;
	const char *line;

	fp = xfopen(MEMINFO_FILE,"rt");

	while ((line = read_string_from_fp(fp)) != NULL)
	{
		char *arg = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s", arg, value);
		
		//Find string "MemTotal: <memory>"
		if (strcmp(arg, "MemTotal:") == 0)
		{
			fclose(fp);
			free(arg);
			free((void *)line);
			
			return value;
		}

		free(arg);
		free(value);
		free((void *)line);
	}

	fclose(fp);

	return NULL;
}

// Get kernel version.
static const char *get_kernel_info(void)
{
	const char *line = read_first_string_from_file(VERSION_FILE);
	char *arg;
	char *value;

	if (line == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: couldn't open file", VERSION_FILE, NULL));
	}

	arg = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
	value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

	sscanf(line, "%s %s %s", arg, arg, value);
	
	// Get kernel verion from string "Linux version <version>".
	for (int i = 0; value[i] != 0; i++)
	{
		if (value[i] == '-')
		{
			value[i] = 0;
			break;
		}
	}

	free(arg);
	free((void *)line);

	return value;
}

/* Control groups handling. */

// Find memory and cpuacct controllers.
static void find_cgroup(void)
{
	const char *fname = MOUNTS_FILE;
	FILE *fp;
	const char *line = NULL;

	fp = xfopen(fname, "rt");

	while ((line = read_string_from_fp(fp)) != NULL)
	{
		char *name = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *fname = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *type = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *subsystems = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s %s %s", name, fname, type, subsystems);
		
		// Cpuacct controller.
		if (strcmp(type, CGROUP) == 0 && strstr(subsystems, CPUACCT_CONTROLLER))
		{
			// Path to new cgroup.
			params.cgroup_cpuacct = (char *)xmalloc(sizeof(char) * (strlen(fname) + 1));
			strcpy(params.cgroup_cpuacct, fname);
			// Path to original cgroup.
			params.cgroup_cpuacct_origin = (char *)xmalloc(sizeof(char) * (strlen(fname) + 1));
			strcpy(params.cgroup_cpuacct_origin, fname);
		}

		//Memory controller.
		if (strcmp(type, CGROUP) == 0 && strstr(subsystems, MEMORY_CONTROLLER))
		{
			// Path to new cgroup.
			params.cgroup_memory = (char *)xmalloc(sizeof(char) * (strlen(fname) + 1));
			strcpy(params.cgroup_memory, fname);
			// Path to original cgroup.
			params.cgroup_memory_origin = (char *)xmalloc(sizeof(char) * (strlen(fname) + 1));
			strcpy(params.cgroup_memory_origin, fname);
		}

		free(name);
		free(fname);
		free(type);
		free(subsystems);
		free((void *)line);
	}

	fclose(fp);
	
	// If there is no control groups with memory controller.
	if (params.cgroup_memory == NULL)
	{
		exit_res_manager(EACCES, NULL, "Error: you need to mount memory cgroup: sudo mount -t cgroup -o memory <name> <path>");
	}

	// If there is no control groups with cpuacct controller.
	if (params.cgroup_cpuacct == NULL)
	{
		exit_res_manager(EACCES, NULL, "Error: you need to mount cpuacct cgroup: sudo mount -t cgroup -o cpuacct <name> <path>");
	}
}

// Create new memory and cpuacct controllers for a new task:
// <path from /proc/mounts>/<resmanager directory>/<resource manager pid>/<controller>.
static void create_cgroup_controllers(const char *resmanager_dir)
{
	const char *pid_str = itoa(getpid());
	const char *controllers[2];
	
	int iterations = 1;
	int mkdir_errno;

	// Get full paths for control cgroup controllers.
	params.cgroup_memory = (char *)concat(params.cgroup_memory, "/", resmanager_dir, "/", RESMANAGER_MODIFIER, pid_str, NULL);
	params.cgroup_cpuacct = (char *)concat(params.cgroup_cpuacct, "/", resmanager_dir, "/", RESMANAGER_MODIFIER, pid_str, NULL);

	controllers[0] = params.cgroup_memory;
	controllers[1] = params.cgroup_cpuacct;

	free((void *)pid_str);

	// If cpuacct and memory controllers are equal then only one directory will be made.
	if (strcmp(params.cgroup_memory, params.cgroup_cpuacct) == 0)
	{
		iterations = 0;
	}

	for (int i = 0; i <= iterations; i++)
	{
		// Create new directory.
		if (mkdir(controllers[i], 0777) == -1)
		{
			mkdir_errno = errno;
			if (mkdir_errno == EACCES) // Permission error.
			{
				// Text message for memory controller.
				if (strcmp(controllers[i], params.cgroup_memory) == 0)
				{
					exit_res_manager(mkdir_errno, NULL, concat(
						"Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", params.cgroup_memory_origin, NULL));
				}
				else // Text message for cpuacct controller.
				{
					exit_res_manager(mkdir_errno, NULL, concat(
						"Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", params.cgroup_cpuacct_origin, NULL));
				}
			}
			else if (mkdir_errno == EEXIST) // Directory already exist.
			{
				if (check_tasks((const char *)controllers[i])) // If tasks file is empty this directory can be removed.
				{
					rmdir(controllers[i]);
					mkdir(controllers[i], 0777);
				}
				else // If there is a processes in tasks file Resource Manager will be finished.
				{
					exit_res_manager(mkdir_errno, NULL, concat(
						"There is control group with running processes in ", controllers[i], NULL));
				}
			}
			else // Other errors, Resource Manager also will be finished.
			{
				exit_res_manager(mkdir_errno, NULL, concat("Error: couldn't create ", controllers[i], NULL));
			}
		}
	}
}

// Set parameter into file in control groups. In case of errors Resource Manager
// will be terminated.
static void set_cgroup_parameter(const char *fname, const char *controller, const char *value)
{
	const char *fname_new = concat(controller, "/", fname, NULL);
	FILE *fp;

	if (chmod(fname_new, 0666) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}
		
	if (access(fname_new, F_OK) == -1) // Check if file exists.
	{
		// If there is no files for memsw special error message.
		if (strcmp(fname, MEMSW_LIMIT) == 0)
		{
			exit_res_manager(ENOENT, NULL, "Error: memory control group doesn't have swap extension."
				" You need to set swapaccount=1 as a kernel boot parameter to be able to compute 'memory+Swap' usage");
		}

		exit_res_manager(errno, NULL, concat("Error: file ", fname_new, " doesn't exist", NULL));
	}

	fp = xfopen(fname_new, "w+");

	// Write value to the file. 
	fputs(value, fp);

	fclose(fp);
	free((void *)fname_new);
}

/*
 * Get parameter from file in control groups.
 * In case of errors during reading Resource Manager will be terminated.
 * Returns found string.
 */
static const char *get_cgroup_parameter(const char *fname, const char *controller)
{
	const char *str;
	const char *fname_new = concat(controller, "/", fname, NULL);

	str = read_first_string_from_file(fname_new);

	// Parameter can't be read. 
	if (str == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: couldn't read parameter from ", fname_new, NULL));
	}

	free((void *)fname_new);

	return str;
}

// Set memory limit into memory controller.
static void set_memlimit(void)
{
	set_cgroup_parameter(MEM_LIMIT, params.cgroup_memory, itoa(params.memlimit));
	set_cgroup_parameter(MEMSW_LIMIT, params.cgroup_memory, itoa(params.memlimit));
}

// Add pid of created process to tasks file.
static void add_task(int pid)
{
	set_cgroup_parameter(TASKS, params.cgroup_memory, itoa(pid));

	if (strcmp(params.cgroup_memory, params.cgroup_cpuacct) != 0)
	{
		set_cgroup_parameter(TASKS, params.cgroup_cpuacct, itoa(pid));
	}
}

// Read sys/user time and return it.
static const char *get_time(const char *line)
{
	const char *time;

	if (line == NULL)
	{
		exit_res_manager(ENOENT, NULL, "Error: couldn't read string from file cpuacct.stats");
	}
	else
	{
		char *arg = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		
		// Read value from the string (arg is "user" or "system").
		if(!(strcmp(arg, "user") != 0 && strcmp(arg, "system") != 0))
			return NULL;
		
		sscanf(line, "%s %s", arg, value);
		time = value;
		
		free((void *)line);
		free(arg);
	}

	return time;
}

/*
 * Read user and system time from cpuacct controller with special format:
 *   user <number in ms>
 *   sys <number in ms>.
*/
static void get_user_and_system_time(statistics *stats)
{
	FILE *fp;
	const char *line;
	const char *fcpu_stat = concat(params.cgroup_cpuacct, "/", CPU_STAT, NULL);

	fp = xfopen(fcpu_stat, "rt");
	free((void *)fcpu_stat);

	line = read_string_from_fp(fp);
	stats->user_time = atof(get_time(line)) / 1e2;

	line = read_string_from_fp(fp);
	stats->sys_time = atof(get_time(line)) / 1e2;

	fclose(fp);
}

// Read statistics from controllers.
static void get_memory_and_cpu_usage(statistics *stats)
{
	const char *cpu_usage = get_cgroup_parameter(CPU_USAGE, params.cgroup_cpuacct);
	const char *memory_usage = get_cgroup_parameter(MEMSW_MAX_USAGE, params.cgroup_memory);
	
	if (memory_usage == NULL)
	{
		memory_usage = get_cgroup_parameter(MEM_MAX_USAGE, params.cgroup_memory);
	}

	// Get cpu time usage.
	stats->cpu_time = atol(cpu_usage) / 1e9;
	free((void *)cpu_usage);

	// Get memory usage.
	stats->memory = atol(memory_usage);
	free((void *)memory_usage);

	// User and system time (not standart format).
	get_user_and_system_time(stats);
}

// Delete control group controllers.
static void remove_cgroup_controllers(void)
{
	if (params.cgroup_memory != NULL)
	{
		rmdir(params.cgroup_memory);
	}
	// Delete two directories only if they are different.
	if (strcmp(params.cgroup_cpuacct, params.cgroup_memory) != 0)
	{
		if (params.cgroup_cpuacct != NULL)
		{
			rmdir(params.cgroup_cpuacct);
		}
	}
}

/* Main Resource Manager functions. */

// Print statistics into file/console.
static void print_stats(int exit_code, int signal, statistics *stats, const char *err_mes)
{
	FILE *fp;
	const char *kernel = get_kernel_info();
	const char *memory = get_memory_info();
	const char *cpu = get_cpu_info();

	// If fout is not specified statistics willbe printed into the stdout.
	if (params.fout == NULL)
	{
		fp = stdout;
	}
	else
	{
		fp = fopen(params.fout, "w");

		if (fp == NULL)
		{
			fprintf(stdout, "Couldn't create file %s\n", params.fout);
			fp = stdout;
		}
	}

	// Print System settings.
	fprintf(fp, "System settings:\n");
	fprintf(fp, "\tkernel version: %s\n", kernel);
	fprintf(fp, "\tcpu: %s", cpu);
	fprintf(fp, "\tmemory: %s Kb\n", memory);

	free((void *)kernel);
	free((void *)memory);
	free((void *)cpu);

	// Print Resource Manager settings.
	fprintf(fp, "Resource manager settings:\n");
	fprintf(fp, "\tmemory limit: %ld bytes\n", params.memlimit);
	fprintf(fp, "\ttime limit: %.0f ms\n", params.timelimit * 1000);
	fprintf(fp, "\tcommand: ");

	if (params.command != NULL)
	{
		for (int i = 0; params.command[i] != NULL; i++)
		{
			fprintf(fp, "%s ", params.command[i]);
		}
	}

	fprintf(fp, "\n");
	fprintf(fp, "\tcgroup memory controller: %s\n", params.cgroup_memory);
	fprintf(fp, "\tcgroup cpuacct controller: %s\n", params.cgroup_cpuacct);
	fprintf(fp, "\toutputfile: %s\n", params.fout);

	// Print Resource manager execution status.
	fprintf(fp, "Resource manager execution status:\n");
	if (err_mes != NULL)
	{
		fprintf(fp, "\texit code (resource manager): %i (%s)\n", exit_code, err_mes);
	}
	else
	{
		fprintf(fp, "\texit code (resource manager): %i\n", exit_code);
	}

	if (signal != 0)
	{
		fprintf(fp, "\tkilled by signal (resource manager): %i (%s)\n", signal, strsignal(signal));
	}

	// Only if Resource Manager finished correctly.
	if (exit_code == 0 && pid > 0 && stats != NULL) 
	{
		// Print command execution status.
		fprintf(fp, "Command execution status:\n");
		fprintf(fp, "\texit code: %i\n", stats->exit_code);

		if (stats->sig_number != 0)
		{
			fprintf(fp, "\tkilled by signal: %i (%s)\n", stats->sig_number, strsignal(stats->sig_number));
		}

		if (stats->cpu_time > params.timelimit)
		{
			fprintf(fp, "\ttime exhausted\n");
		}
		else if (stats->memory > params.memlimit)
		{
			fprintf(fp, "\tmemory exhausted\n");
		}
		else
		{
			fprintf(fp, "\tcompleted in limits\n");
		}

		// Print time and memory usage. 
		fprintf(fp, "Time usage statistics:\n");
		fprintf(fp, "\twall time: %.0f ms\n", stats->wall_time * 1000);
		fprintf(fp, "\tcpu time: %.0f ms\n", stats->cpu_time * 1000);
		fprintf(fp, "\tuser time: %.0f ms\n", stats->user_time * 1000);
		fprintf(fp, "\tsystem time: %.0f ms\n", stats->sys_time * 1000);

		fprintf(fp, "Memory usage statistics:\n");
		fprintf(fp, "\tpeak memory usage: %ld bytes\n", stats->memory);
	}

	if (params.fout != NULL)
	{
		fclose(fp);
	}
}

/*
 * Perform actions, which should be made at the end of Resource Manager:
 *   kill all created processes (if they were created),
 *   print statistics,
 *   remove control group controllers.
 */
static void exit_res_manager(int exit_code, statistics *stats, const char *err_mes)
{
	if (exit_code && !err_mes)
	{
		exit_res_manager(EINVAL, NULL, "Error: sanity check failed. Error message wasn't specified but Resource Manager is going to return an error");
	}

	if (!exit_code && err_mes)
	{
		exit_res_manager(EINVAL, NULL, "Error: sanity check failed. Error message was specified but Resource Manager is going to finish successfully");
	}

	// Close files, in which stdout/stderr was redirected.
	if (params.stdout != -1)
	{
		close(params.stdout);
	}
	if (params.stderr != -1)
	{
		close(params.stderr);
	}

	// Finish all running processes.
	kill_created_processes(SIGKILL);

	// Get statistics.
	if (stats != NULL)
	{
		get_memory_and_cpu_usage(stats);
	}

	// Remove control group controllers.
	remove_cgroup_controllers();

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
 *   <file> <value>
 * Write <value> into each <file>.
 * Return err_mes or NULL in case of success.
 */
static void set_config(char *fconfig)
{
	FILE *fp;
	const char *line;

	fp = xfopen(fconfig, "rt");

	while ((line = read_string_from_fp(fp)) != NULL)
	{
		char *controller = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *fname = (char *)xmalloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)xmalloc((strlen(line) + 1) * sizeof(char));

		sscanf(line, "%s %s %s", controller, fname, value);
		// Set parameters for cpuacct controller.
		if (strcmp(controller, CPUACCT_CONTROLLER) == 0)
		{
			set_cgroup_parameter(fname, params.cgroup_cpuacct, value);
		}
		// Set parameters for memory controller.
		else if (strcmp(controller, MEMORY_CONTROLLER) == 0)
		{
			set_cgroup_parameter(fname, params.cgroup_memory, value);
		}
		free((void *)line);
		free(fname);
		free(value);
		free(controller);
	}

	fclose(fp);

}

// Check tasks file and returns 1 if it's clean or 0 otherwise.
static int check_tasks(const char *cgroup)
{
	const char *fname = concat(cgroup, "/", TASKS, NULL);
	FILE *fp;
	const char *line;

	fp = xfopen(fname, "rt");
	free((void *)fname);

	if((line = read_string_from_fp(fp)) != NULL) // There is some string.
	{
		fclose(fp);
		free((void *)line);

		return 0;
	}

	fclose(fp);

	return 1;
}

// Finishe all created processes.
static void kill_created_processes(int signum)
{
	if (pid > 0)
	{
		const char *fname;
		const char *line = NULL;
		FILE *fp;

		// Kill main created process.
		kill(pid, signum);

		// Kill any other created processes.
		fname = concat(params.cgroup_memory, "/", TASKS, NULL);
		fp = fopen(fname, "rt");

		if (fp == NULL)
		{
			return; // File already was deleted.
		}

		free((void *)fname);
		
		// Kill processes by pids from tasks file.
		while ((line = read_string_from_fp(fp)) != NULL)
		{
			kill(atoi(line),signum);
			free((void *)line);
		}

		fclose(fp);
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

	if (setitimer(ITIMER_REAL, value, NULL) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

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

	if (setitimer(ITIMER_REAL, value, NULL) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	free(value);
}

// Handle SIGALRM, check time limit.
static void check_time(int signum)
{
	const char *cpu_usage = get_cgroup_parameter(CPU_USAGE, params.cgroup_cpuacct);
	double cpu_time = atof(cpu_usage) / 1e9;

	free((void *)cpu_usage);

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
static void redirect(int fd, const char *fname)
{
	int fdes[2];

	if (fname == NULL)
	{
		return;
	}

	close(fd); // Close stdout/stderr in command execution.

	fdes[0] = fd;

	// Create new file, in which stdout/stderr will be redirected.
	fdes[1] = open(fname, O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
	if (fdes[1] == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	// Duplicate file descriptor.
	if (dup2(fdes[0], fdes[1]) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	// Create a pipe.
	if (pipe(fdes) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	// Save file descriptor, in which stdout/stderr will be redirected.
	if (fd == 1)
	{
		params.stdout = fdes[1];
	}
	else if (fd == 2)
	{
		params.stderr = fdes[1];
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
	char *fstdout = NULL;
	char *fstderr = NULL;
	char *resmanager_dir = ""; // Path to Resource Manager directory in control groups.
	char *fconfig = NULL;
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
	params.fout = NULL;
	params.command = NULL;
	params.alarm_time = 1000;
	params.cgroup_memory_origin = NULL;
	params.cgroup_cpuacct_origin = NULL;
	params.cgroup_memory = NULL;
	params.cgroup_cpuacct = NULL;
	params.stdout = -1;
	params.stderr = -1;
	params.script_signal = 0;

	// Set handlers for all signals except SIGSTOP, SIGKILL, SIGUSR1, SIGUSR2, SIGALRM, SIGWINCH.
	for (int i = 1; i <= 31; i++)
	{
		void *prev_handler; 
		if (i == SIGSTOP || i == SIGKILL ||i == SIGCHLD || i == SIGUSR1 || i == SIGUSR2 || i == SIGALRM || i == SIGWINCH)
		{
			continue;
		}
		if ((prev_handler = signal(i, terminate)) == SIG_ERR)
		{
			exit_res_manager(errno, NULL, strerror(errno));
		}
		if (prev_handler == SIG_IGN && i == SIGHUP)
		{
			signal(SIGHUP, SIG_IGN);
		}
	}

	// Parse command line.
	while ((c = getopt_long(argc, argv, "-hm:t:o:l:0", long_options, &option_index)) != -1)
	{
		switch(c)
		{
		case 'h': // Help.
			print_usage();
			exit(0);
		case 'i': // Interval for alarm in ms.
			if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, "Error: expected integer number in ms as value of --interval");
			}
			params.alarm_time = atoi(optarg);
			break;
		case 'c': // Config file.
			fconfig = optarg;
			break;
		case 's': // Stdout file.
			fstdout = optarg;
			break;
		case 'e': // Sterr file.
			fstderr = optarg;
			break;
		case 'l': // Directory in cgroups.
			resmanager_dir = optarg;
			break;
		case 'm': // Memory limit.
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
		case 't': // Time limit.
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
		case 'o': // File for statistics.
			params.fout = optarg;
			break;
		default: // Command.
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

	// Parse command and its args.
	optind--; // Optind - index of first argument in command; index of command is needed.
	params.command = (char **)xmalloc(sizeof(char *) * (argc - optind + 1));
	for (int i = 0; i < argc - optind; i++)
	{
		params.command[i] = argv[optind + i];
		comm_arg++;
	}
	params.command[comm_arg] = NULL;

	// Create new cgroup for command.
	find_cgroup();
	create_cgroup_controllers(resmanager_dir);

	// Configure control groups.
	set_memlimit();

	if (fconfig != NULL) // configfile was specified
	{
		set_config(fconfig);
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
		redirect(1, fstdout); // Redirect stdout.
		redirect(2, fstderr); // Redirect stderr.
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
