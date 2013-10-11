#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define STR_LEN 80
#define DEFAULT_TIME_LIMIT 60e3 /* 60 000 milliseconds or 1 minute */
#define DEFAULT_MEM_LIMIT 1e9 /* 1 000 000 000 bytes or 1 gigabyte */

#define RESOURCE_MANAGER_MODIFIER "resource_manager_"

#define CGROUP "cgroup"
#define TASKS "tasks"
#define CPUACCT_CONTROLLER "cpuacct"
#define CPU_USAGE "cpuacct.usage"
#define CPU_STAT "cpuacct.stat"
#define MEMORY_CONTROLLER "memory"
#define MEM_LIMIT "memory.limit_in_bytes"
#define MEM_MAX_USAGE "memory.max_usage_in_bytes"
#define MEMSW_LIMIT "memory.memsw.limit_in_bytes"
#define MEMSW_MAX_USAGE "memory.memsw.max_usage_in_bytes"

#define CPUINFO_FILE "/proc/cpuinfo"
#define MEMINFO_FILE "/proc/meminfo"
#define VERSION_FILE "/proc/version"
#define MOUNTS_FILE "/proc/mounts"

/*
 * This structure holds exit status of executing command, its time and memory
 * consumption statistics. Memory is stored in bytes, time is stored in
 * miliseconds (10^(-3) seconds)).
 */
typedef struct
{
	int exit_code;
	int sig_number;
	int memory_exhausted;
	int time_exhausted;
	int wall_time_exhausted;
	uint64_t wall_time;
	uint64_t cpu_time;
	uint64_t user_time;
	uint64_t sys_time;
	uint64_t memory;
} execution_statistics;

/*
 * This variable holds command-line parameters, parameters specified for
 * cgroups, file descriptors for redirecting stdout/stdeerr and signal number
 * that was send to Resource Manager if so.
 */
static struct
{
	// Command-line parameters.
	uint64_t time_limit; // In miliseconds.
	uint64_t wall_time_limit; // In miliseconds.
	uint64_t mem_limit; // In bytes.
	char *fout; // File for printing statistics.
	char **command; // Command for execution.
	uint64_t alarm_time; // Time in ms (10^-3 seconds) for specifing interval in which time limit will be checked.

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

	// Time of the start execution of the command.
	uint64_t start_time;
} params;

// Pid of child process in which command will be executed.
static int pid = 0;

/* Function prototypes. */

static void add_task(int pid);
static int check_tasks(const char *cgroup);
static void check_time(int signum);
static const char *concat(const char *first, ...);
static void create_cgroup(const char *dir);
static void exit_res_manager(int exit_code, execution_statistics *exec_stats, const char *err_mes);
static void find_cgroup_controllers(void);
static const char *get_cgroup_parameter(const char *fname, const char *controller);
static const char *get_cpu_info(void);
static const char *get_kernel_info(void);
static void get_memory_and_cpu_usage(execution_statistics *exec_stats);
static const char *get_memory_info(void);
static const char *get_sys_or_user_time(const char *line);
static uint64_t get_time(void);
static int is_number(char *str);
static const char *itoa(uint64_t n);
static void kill_created_processes(int signum);
static void print_output(int exit_code, int signal, execution_statistics *exec_stats, const char *err_mes);
static void print_usage(void);
static const char *read_first_string_from_file(const char *fname);
static const char *read_string_from_fp(FILE *fp);
static void redirect(int fd, const char *fname);
static void remove_cgroup_controllers(void);
static void set_cgroup_parameter(const char *fname, const char *controller, const char *value);
static void set_config(char *fconfig);
static void set_mem_limit(void);
static void set_timer(int alarm_time);
static void stop_timer(void);
static void terminate(int signum);
static uint64_t xatol(const char * string);
static FILE *xfopen(const char *fname, const char *mode);
static void *xmalloc(size_t size);
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
static const char *itoa(uint64_t n)
{
	int order = 1;
	uint64_t broken_n;
	char *str;

	// Get order of number.
	for (broken_n = n; (broken_n = broken_n / 10) > 0; order++);

	str = (char *)xmalloc(sizeof(char) * (order + 1));

	// Get string representation of n.
	broken_n = n;
	for (int i = order - 1; i >= 0; i--)
	{
		str[i] = broken_n % 10 + '0';
		broken_n = broken_n / 10;
	}

	// Properly terminate string.
	str[order] = '\0';

	return str;
}

/*
 * Convert string into uint64_t. Finish Resource Manager in case of any errors.
 * This function should be used instead of atol/atoi.
 */
static uint64_t xatol(const char *string)
{
	uint64_t converted_result = strtoull(string, (char **)NULL, 10);

	// Check if string cannot be represented as uint64_t.
	if (errno == ERANGE)
	{
		exit_res_manager(errno, NULL, concat(strerror(errno), ": ", string, NULL));
	}

	return converted_result;
}

/*
 * Concatenate variable number of strings (NULL represents the end of this list)
 * and return resulting string (additional memory is allocated in this
 * function).
 */
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
static uint64_t get_time(void)
{
	struct timeval time;

	gettimeofday(&time, NULL);

	return time.tv_sec * 1000 + time.tv_usec / 1000;
}

// Return true if string is number.
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

/*
 * Return current string terminating with '\n' or EOF from opened file.
 * NULL is returned if file wasn't opened or current file position is EOF.
 */
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

		// Find string "MemTotal: <memory>"
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

// Find existing memory and cpuacct controllers.
static void find_cgroup_controllers(void)
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

		// Memory controller.
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

/*
 * Create new control group with memory and cpuacct controllers for a new task:
 * <path from /proc/mounts>/<directory>/<RESOURCE_MANAGER_MODIFIER><pid>/<controller>.
 */
static void create_cgroup(const char *dir)
{
	const char *pid_str = itoa(getpid());
	const char *controllers[2];

	int iterations = 1;
	int mkdir_errno;

	// Get full paths for control cgroup controllers.
	params.cgroup_memory = (char *)concat(params.cgroup_memory, "/", dir, "/", RESOURCE_MANAGER_MODIFIER, pid_str, NULL);
	params.cgroup_cpuacct = (char *)concat(params.cgroup_cpuacct, "/", dir, "/", RESOURCE_MANAGER_MODIFIER, pid_str, NULL);

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
		// Create new directory for controller.
		if (mkdir(controllers[i], 0777) == -1)
		{
			mkdir_errno = errno;
			if (mkdir_errno == EACCES) // Permission error.
			{
				if (strcmp(controllers[i], params.cgroup_memory) == 0)
				{
					exit_res_manager(mkdir_errno, NULL, concat(
						"Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", params.cgroup_memory_origin, NULL));
				}
				else
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
				else // If there is a process in tasks file Resource Manager will be finished.
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

/*
 * Set parameter into file in control groups. In case of errors Resource Manager
 * will be terminated.
 */
static void set_cgroup_parameter(const char *fname, const char *controller, const char *value)
{
	const char *fname_new = concat(controller, "/", fname, NULL);
	FILE *fp;

	if (access(fname_new, F_OK) == -1) // Check if file exists.
	{
		// If there is no files for memsw special error message.
		if (strcmp(fname, MEMSW_LIMIT) == 0)
		{
			free((void *)fname_new);
			fname_new = concat(controller, "/", MEM_LIMIT, NULL);
		}
		else
		{
			exit_res_manager(errno, NULL, concat("Error: file ", fname_new, " doesn't exist", NULL));
		}
	}

	if (chmod(fname_new, 0666) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
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
 * Return found string.
 */
static const char *get_cgroup_parameter(const char *fname, const char *controller)
{
	const char *str;
	const char *fname_new = concat(controller, "/", fname, NULL);

	if (access(fname_new, F_OK) == -1) // Check if file exists.
	{
		// If there is no files for memsw special error message.
		if (strcmp(fname, MEMSW_MAX_USAGE) == 0)
		{
			free((void *)fname_new);
			fname_new = concat(controller, "/", MEM_MAX_USAGE, NULL);
		}
		else
		{
			exit_res_manager(errno, NULL, concat("Error: file ", fname_new, " doesn't exist", NULL));
		}
	}

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
static void set_mem_limit(void)
{
	if (params.mem_limit > 0)
	{
		set_cgroup_parameter(MEM_LIMIT, params.cgroup_memory, itoa(params.mem_limit));
		set_cgroup_parameter(MEMSW_LIMIT, params.cgroup_memory, itoa(params.mem_limit));
	}
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
static const char *get_sys_or_user_time(const char *line)
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

		sscanf(line, "%s %s", arg, value);

		if(!(strcmp(arg, "user") != 0 && strcmp(arg, "system") != 0))
		{
			exit_res_manager(ENOENT, NULL, "Error: neither user nor system time was read from file cpuacct.stats");
		}

		time = value;

		free((void *)line);
		free(arg);
	}

	return time;
}

// Read resource usage statistics from controllers.
static void get_memory_and_cpu_usage(execution_statistics *exec_stats)
{
	const char *cpu_usage = get_cgroup_parameter(CPU_USAGE, params.cgroup_cpuacct);
	const char *memory_usage = get_cgroup_parameter(MEMSW_MAX_USAGE, params.cgroup_memory);
	const char *fcpu_stat = concat(params.cgroup_cpuacct, "/", CPU_STAT, NULL);
	FILE *fp;

	if (memory_usage == NULL)
	{
		memory_usage = get_cgroup_parameter(MEM_MAX_USAGE, params.cgroup_memory);
	}

	// Save cpu time usage.
	exec_stats->cpu_time = xatol(cpu_usage) / 1e6;
	free((void *)cpu_usage);

	// Save memory usage.
	exec_stats->memory = xatol(memory_usage);
	free((void *)memory_usage);

	/*
	 * Read user and system time from cpuacct controller. They have a special
	 * format:
	 *   user <number in ms>
	 *   sys <number in ms>.
	*/
	fp = xfopen(fcpu_stat, "rt");
	free((void *)fcpu_stat);

	exec_stats->user_time = xatol(get_sys_or_user_time(read_string_from_fp(fp))) * 1e1;
	exec_stats->sys_time = xatol(get_sys_or_user_time(read_string_from_fp(fp))) * 1e1;

	fclose(fp);
}

// Delete control group controllers.
static void remove_cgroup_controllers(void)
{
	if (params.cgroup_memory != NULL)
	{
		rmdir(params.cgroup_memory);
	}
	// Delete two directories only if they are different.
	if (params.cgroup_memory != NULL && params.cgroup_cpuacct != NULL)
	{
		if (strcmp(params.cgroup_cpuacct, params.cgroup_memory) != 0)
		{
			if (params.cgroup_cpuacct != NULL)
			{
				rmdir(params.cgroup_cpuacct);
			}
		}
	}
}

/* Main Resource Manager functions. */

// Print output into file/console.
static void print_output(int exit_code, int signal, execution_statistics *exec_stats, const char *err_mes)
{
	FILE *fp;
	const char *kernel = get_kernel_info();
	const char *memory = get_memory_info();
	const char *cpu = get_cpu_info();

	// If fout is not specified output will be printed into the stdout.
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
	fprintf(fp, "\tmemory limit: %lu bytes\n", params.mem_limit);
	fprintf(fp, "\ttime limit: %lu ms\n", params.time_limit);
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
	if (exit_code == 0 && pid > 0 && exec_stats != NULL)
	{
		// Print command execution status.
		fprintf(fp, "Command execution status:\n");
		fprintf(fp, "\texit code: %i\n", exec_stats->exit_code);

		if (exec_stats->sig_number != 0)
		{
			fprintf(fp, "\tkilled by signal: %i (%s)\n", exec_stats->sig_number, strsignal(exec_stats->sig_number));
		}

		if (params.time_limit != 0 && exec_stats->cpu_time > params.time_limit)
		{
			fprintf(fp, "\ttime exhausted\n");
		}
		else if (params.mem_limit != 0 && exec_stats->memory >= params.mem_limit)
		{
			fprintf(fp, "\tmemory exhausted\n");
		}
/* TODO fix problem pattern. */
		else if (params.wall_time_limit != 0 && exec_stats->wall_time > params.wall_time_limit)
		{
			fprintf(fp, "\twall time exhausted\n");
		}
		else
		{
			fprintf(fp, "\tcompleted in limits\n");
		}

		// Print time and memory usage.
		fprintf(fp, "Time usage statistics:\n");
		fprintf(fp, "\twall time: %lu ms\n", exec_stats->wall_time);
		fprintf(fp, "\tcpu time: %lu ms\n", exec_stats->cpu_time);
		fprintf(fp, "\tuser time: %lu ms\n", exec_stats->user_time);
		fprintf(fp, "\tsystem time: %lu ms\n", exec_stats->sys_time);

		fprintf(fp, "Memory usage statistics:\n");
		fprintf(fp, "\tpeak memory usage: %lu bytes\n", exec_stats->memory);
	}

	if (params.fout != NULL)
	{
		fclose(fp);
	}
}

/*
 * Perform actions which should be made at the end of Resource Manager work:
 *   kill all created processes (if they were created),
 *   remove control group controllers,
 *   print output.
 */
static void exit_res_manager(int exit_code, execution_statistics *exec_stats, const char *err_mes)
{
	if (exit_code && !err_mes)
	{
		exit_res_manager(EINVAL, NULL, "Error: sanity check failed. Error message wasn't specified but Resource Manager is going to return an error");
	}

	if (!exit_code && err_mes)
	{
		exit_res_manager(EINVAL, NULL, "Error: sanity check failed. Error message was specified but Resource Manager is going to finish successfully");
	}

	// Close files in which stdout/stderr was redirected.
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

	// Get resource usage statistics.
	if (exec_stats != NULL)
	{
		get_memory_and_cpu_usage(exec_stats);
	}

	// Remove control group controllers.
	remove_cgroup_controllers();

	// Print output.
	print_output(exit_code, params.script_signal, exec_stats, err_mes);

	// Finish Resource Manager.
	if (exit_code != 0)
	{
		exit(exit_code);
	}
}

/*
 * Config file format:
 *   <controller> <file> <value>
 * Write <value> into <file> for <controller>.
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

// Finish all created processes.
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
			kill(xatol(line),signum);
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

	// Timer will expire every alarm_time milliseconds.
	value->it_value.tv_sec = value->it_interval.tv_sec = alarm_time / 1000;
	value->it_value.tv_usec = value->it_interval.tv_usec = (alarm_time % 1000) * 1000;

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

	if (setitimer(ITIMER_REAL, value, NULL) == -1)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}

	free(value);
}

// Handle SIGALRM, check time limits.
static void check_time(int signum)
{
	const char *cpu_usage = get_cgroup_parameter(CPU_USAGE, params.cgroup_cpuacct);
	uint64_t cpu_time = xatol(cpu_usage) / 1e6;
	uint64_t wall_time = get_time() - params.start_time;

	free((void *)cpu_usage);

	// Check whether cpu time limit happend.
	if (params.time_limit != 0)
	{
		if (cpu_time >= params.time_limit)
		{
			kill_created_processes(SIGKILL);
		}
	}

	// Otherwise check whether wall time limit happend.
	if (params.wall_time_limit != 0)
	{
		if (wall_time >= params.wall_time_limit)
		{
			kill_created_processes(SIGKILL);
		}
	}
}

// Redirect stderr/stdout into file.
static void redirect(int fd, const char *fname)
{
	int fdes[2];

	if (fd != 1 || fd != 2)
	{
		exit_res_manager(EINVAL, NULL, "Error: sanity check failed. Neither 1 (stdout) nor 2 (stderr) file descriptor was specified");
	}

	if (fname == NULL)
	{
		exit_res_manager(EINVAL, NULL, "Error: sanity check failed. File name where stderr/stdout should be redirected wasn't specified");
	}

	close(fd); // Close stdout/stderr.

	fdes[0] = fd;

	// Create new file in which stdout/stderr will be redirected.
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

	// Save file descriptor in which stdout/stderr will be redirected.
	if (fd == 1)
	{
		params.stdout = fdes[1];
	}
	else
	{
		params.stderr = fdes[1];
	}
}

// Print usage instructions.
static void print_usage(void)
{
	printf(
		"Usage: [options] [command] [arguments] \n"

		"Options:\n"
		"\t-h, --help\n"
		"\t\tPrint help.\n"
		"\t-m, --memory-limit <number>\n"
		"\t\tSet memory limit to <number> bytes. Supported binary prefixes: Kb, Mb, Gb, Kib, Mib, Gib; 1Kb = 1000 bytes,\n"
		"\t\t1Mb = 1000^2, 1Gb = 1000^3, 1Kib = 1024 bytes, 1Mib = 1024^2, 1Gib = 1024^3 (standardized in IEC 60027-2).\n"
		"\t\tIf there is no binary prefix then size will be specified in bytes. Default value: 100Mb.\n"
		"\t-t, --time-limit <number>\n"
		"\t\tSet time limit to <number> seconds. Supported prefixes: ms, min; 1ms = 0.001 seconds, 1min = 60 seconds. \n"
		"\t\tIf there is no prefix then time will be specified in seconds. Default value: 1min.\n"
		"\t-w, --wall-time-limit <number>\n"
		"\t\tSet wall time limit to <number> seconds. Supported prefixes: ms, min; 1ms = 0.001 seconds, 1min = 60 seconds. \n"
		"\t\tIf there is no prefix then time will be specified in seconds. If value set to 0 then wall time won't be checked.\n"
		"\t\tDefault value: (2 X time limit).\n"
		"\t-o <file>\n"
		"\t\tPrint output into file <file>. If option isn't specified output will be printed into stdout.\n"
		"\t-d, --command-cgroup-directory <dir>\n"
		"\t\tSpecify subdirectory in control group directory where Resource manager will \"run\" command. If option isn't specified\n"
		"\t\tthen will be used control group directory itself.\n"
		"\t-i, --interval <number>\n"
		"\t\tSpecify time (in ms) interval in which time limit will be checked. Default value: 1000 (1 second).\n"
		"\t-s, --stdout <file>\n"
		"\t\tRedirect command stdout into <file>. If option isn't specified then stdout won't be redirected for command.\n"
		"\t-e, --stderr <file>\n"
		"\t\tRedirect command stderr into <file>. If option isn't specified then stderr won't be redirected for command.\n"
		"\t-c, --config <dir>\n"
		"\t\tSpecify config file. Config file contains triples <controller> <parameter> <value>, where controller - name of control\n"
		"\t\tgroup controller, parameter - name of file (parameter) for this controller, value will be specified for this parameter.\n"

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
		"\tcommand will be finished. When command finishes (normally or not), output will be written into the specified file\n"
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
	char *dir = ""; // Path to directory in control groups where Resource Manager will "run" command.
	char *fconfig = NULL;
	int comm_arg = 0;
	int c;
	int is_options_ended = 0;
	int option_index = 0;
	uint64_t time_after;
	int wait_errno;
	static struct option long_options[] = {
		{"help", 1, 0, 'h'},
		{"memory-limit", 1, 0, 'm'},
		{"time-limit", 1, 0, 't'},
		{"wall-time-limit", 1, 0, 'w'},
		{"command-cgroup-directory", 1, 0, 'd'},
		{"interval", 1, 0, 'i'},
		{"stdout", 1, 0, 's'},
		{"stderr", 1, 0, 'e'},
		{"config", 1, 0, 'c'},
		{0, 0, 0, 0}
	};
	int status;
	int wait_res;
	execution_statistics *exec_stats;
	int is_wall_time_limit_specified = 0; // True if there was option "-w".

	// Set default values for parameters.
	params.time_limit = DEFAULT_TIME_LIMIT;
	params.mem_limit = DEFAULT_MEM_LIMIT;
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
/* TODO: fixme. */
	while ((c = getopt_long(argc, argv, "-hm:t:o:l:0", long_options, &option_index)) != -1)
	{
		switch(c)
		{
		case 'h': // Help.
			print_usage();
			exit(0);
		case 'i': // Interval for alarm in ms.
		{
			uint64_t without_mod = xatol(optarg);
			params.alarm_time = without_mod;
			// Convert into ms.
			params.alarm_time *= 1000;
			if (strstr(optarg, "ms") != NULL)
			{
				params.alarm_time /= 1000;
			}
			else if (strstr(optarg, "min") != NULL)
			{
				params.alarm_time *= 60;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, concat("Error: expected positive integer number with ms|min| modifiers as value of --interval, got ", optarg, NULL));
			}

			// Sanity check.
			if (!(params.alarm_time / (60 * 1000) == without_mod || params.alarm_time / 1000 == without_mod ||
				params.alarm_time == without_mod))
			{
				exit_res_manager(EINVAL, NULL, concat("Error: converted result for --interval option does not match expectation; got ",
					optarg, ", after converting ", itoa(params.alarm_time), ". Perhaps there was overflow in data converting. ",
					"Please, specify less positive integer number or use other modifier.", NULL));
			}
			break;
		}
		case 'c': // Config file.
			fconfig = optarg;
			break;
		case 's': // Stdout file.
			fstdout = optarg;
			break;
		case 'e': // Sterr file.
			fstderr = optarg;
			break;
/* TODO: fix RCV library. */
		case 'd': // Directory in control groups.
			dir = optarg;
			break;
		case 'm': // Memory limit.
		{
			uint64_t without_mod = xatol(optarg);
			params.mem_limit = without_mod;
			if (strstr(optarg, "Kb") != NULL)
			{
				params.mem_limit *= 1000;
			}
			else if (strstr(optarg, "Mb") != NULL)
			{
				params.mem_limit *= 1000 * 1000;
			}
			else if (strstr(optarg, "Gb") != NULL)
			{
				params.mem_limit *= 1000;
				params.mem_limit *= 1000;
				params.mem_limit *= 1000;
			}
			else if (strstr(optarg, "Kib") != NULL)
			{
				params.mem_limit *= 1024;
			}
			else if (strstr(optarg, "Mib") != NULL)
			{
				params.mem_limit *= 1024 * 1024;
			}
			else if (strstr(optarg, "Gib") != NULL)
			{
				params.mem_limit *= 1024;
				params.mem_limit *= 1024;
				params.mem_limit *= 1024;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, concat("Error: expected positive integer number with Kb|Mb|Gb|Kib|Mib|Gib| modifiers as value of -m, got ", optarg, NULL));
			}

			// Sanity check.
			if (!(params.mem_limit / (1000) == without_mod || params.mem_limit / (1000 * 1000) == without_mod ||
				params.mem_limit / (1000 * 1000 * 1000) == without_mod || params.mem_limit / (1024) == without_mod ||
				params.mem_limit / (1024 * 1024) == without_mod || params.mem_limit / (1024 * 1024 * 1024) == without_mod ||
				params.mem_limit == without_mod))
			{
				exit_res_manager(EINVAL, NULL, concat("Error: converted result for -m option does not match expectation; got ",
					optarg, ", after converting ", itoa(params.mem_limit), ". Perhaps there was overflow in data converting. ",
					"Please, specify less positive integer number or use other modifier.", NULL));
			}
			break;
		}
		case 't': // Time limit.
		{
			uint64_t without_mod = xatol(optarg);
			params.time_limit = without_mod;
			// Convert into ms.
			params.time_limit *= 1000;
			if (strstr(optarg, "ms") != NULL)
			{
				params.time_limit /= 1000;
			}
			else if (strstr(optarg, "min") != NULL)
			{
				params.time_limit *= 60;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, concat("Error: expected positive integer number with ms|min| modifiers as value of -t, got ", optarg, NULL));
			}

			// Sanity check.
			if (!(params.time_limit / (60 * 1000) == without_mod || params.time_limit / 1000 == without_mod ||
				params.time_limit == without_mod))
			{
				exit_res_manager(EINVAL, NULL, concat("Error: converted result for -t option does not match expectation; got ",
					optarg, ", after converting ", itoa(params.time_limit), ". Perhaps there was overflow in data converting. ",
					"Please, specify less positive integer number or use other modifier.", NULL));
			}
			break;
		}
/* TODO: the same as before => need a special function. */
		case 'w': // Wall time limit.
		{
			uint64_t without_mod = xatol(optarg);
			params.wall_time_limit = without_mod;
			// Convert into ms.
			params.wall_time_limit *= 1000;
			if (strstr(optarg, "ms") != NULL)
			{
				params.wall_time_limit /= 1000;
			}
			else if (strstr(optarg, "min") != NULL)
			{
				params.wall_time_limit *= 60;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, concat("Error: expected positive integer number with ms|min| modifiers as value of --wall, got ", optarg, NULL));
			}

			// Sanity check.
			if (!(params.wall_time_limit / (60 * 1000) == without_mod || params.wall_time_limit / 1000 == without_mod ||
				params.wall_time_limit == without_mod))
			{
				exit_res_manager(EINVAL, NULL, concat("Error: converted result for --wall option does not match expectation; got ",
					optarg, ", after converting ", itoa(params.wall_time_limit), ". Perhaps there was overflow in data converting. ",
					"Please, specify less positive integer number or use other modifier.", NULL));
			}
			is_wall_time_limit_specified = 1;
			break;
		}
		case 'o': // File for output.
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

	// If wall time limit was not specified then it will be (2 X time limit).
	if (!is_wall_time_limit_specified)
	{
		params.wall_time_limit = 2 * params.time_limit;
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

	// Find existing control group controllers.
	find_cgroup_controllers();
	// Create new control group for command.
	create_cgroup(dir);

	// Configure control groups.
	set_mem_limit();

	if (fconfig != NULL) // Config file was specified.
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
	params.start_time = get_time();

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
	time_after = get_time();

	// Stop checking time limit.
	stop_timer();

	// Create execution statistics.
	exec_stats = (execution_statistics *)xmalloc(sizeof(execution_statistics));

	// Compute wall time.
	exec_stats->wall_time = time_after - params.start_time;

	// If wait was interrupted by signal and exit code, signal number are unknown.
	if (wait_errno == EINTR)
	{
		exec_stats->exit_code = EINTR;
		exec_stats->sig_number = SIGKILL;
	}
	else // Wait didn't failed.
	{
		exec_stats->exit_code = WEXITSTATUS(status);
		if (WIFSIGNALED(status))
		{
			exec_stats->sig_number = WTERMSIG(status);
		}
		else
		{
			exec_stats->sig_number = 0;
		}
	}

	// Finish normal execution. So no error is specified as a first parameter.
	exit_res_manager(0, exec_stats, NULL);

	return 0;
}
