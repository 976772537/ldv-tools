#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <getopt.h>
#include <fcntl.h>

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

typedef struct 
{
	//command line parameters
	double timelimit; // in seconds
	long memlimit; // in bytes
	char * outputfile; // file for printing statistics
	char ** command; // command for execution
	int alarm_time; // time in ms

	// cgroup parameters
	char * path_to_memory_origin;
	char * path_to_cpuacct_origin;
	char * path_to_memory;
	char * path_to_cpuacct;

	// file descriptors for redirecting stdout/stderr from command
	int fd_stdout;
	int fd_stderr;

	// if Resource Manager was terminated by signal and this signal was handled then script_signal stores that signal number
	int script_signal;
} parameters;

// global parameters - commnad line parameters, cgroup parameters, file descriptiors for redirecting stdout/stderr
parameters param;

// pid of child process in which command will be executed
int pid = 0;

static void kill_created_processes(int signum);
static void exit_res_manager(int exit_code, statistics *stats, const char *err_mes);
static int check_tasks_file(char *);

/* Library functions. */

// wrapper for checking malloc
void check_malloc(void * allocated_memory)
{
	if (allocated_memory == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
}

// get order of number
static int get_number_order(long num)
{
	int ret = 1;
	long count = num;
	
	while ((count = count / 10) > 0)
	{ 
		ret++; 
	}
	
	return ret;
}

// get string representing long number
static char *itoa(long num)
{
	int number_of_chars = get_number_order(num);
	int i;
	long count = num;
	char *str = (char *) malloc(sizeof(char) * (number_of_chars + 1));
	check_malloc(str);
	for (i = number_of_chars - 1; i >= 0; i--)
	{
		str[i] = count % 10 + '0';
		count = count / 10;
	}
	str[number_of_chars] = '\0';

	return str;
}

// concatenate two strings, don't write into str1 and str2
static char *concat(const char *str1, const char *str2)
{
	char *tmp;
	if (str1 == NULL)
	{
		return strdup(str2);
	}
	if (str2 == NULL)
	{
		return strdup(str1);
	}
	tmp = (char *) malloc((strlen(str1) + strlen(str2) + 1) * sizeof(char));
	check_malloc(tmp);
	strcpy(tmp, str1);
	strcat(tmp, str2);
	
	return tmp;
}

// get current time in microseconds (10^-6)
static double gettime(void)
{
	struct timeval time;
	
	gettimeofday(&time, NULL);
	
	return time.tv_sec + time.tv_usec / 1000000.0;
}

// return true, if str is number
static int is_number(char *str)
{
	int i = 0;
	
	if (str == NULL)
	{
		return 0;
	}
	while (str[i] != '\0')
	{
		if (!isdigit(str[i]))
		{
			return 0;
		}
		i++;
	}
	
	return 1;
}

// read string from opened file into dynamic array 
static char *read_string_from_opened_file(FILE * file)
{
	char * line;
	if (file == NULL)
	{
		return NULL;
	}
	line = (char *)malloc(sizeof(char) * (STR_LEN + 1));
	check_malloc(line);
	if (fgets(line, STR_LEN, file) == NULL)
		return NULL; // EOF
	while(strchr(line, '\n') == NULL)  // not full string
	{
		char * tmp_line = (char *)realloc(line, sizeof(char) * (strlen(line) + STR_LEN + 1));
		char part_of_line[STR_LEN];
		check_malloc(tmp_line);
		fgets(part_of_line, STR_LEN, file);
		line = tmp_line;
		strcat(line, part_of_line);
	}
	return line;
}

// read first string from file
static char *read_string_from_file(const char *path)
{
	FILE *file;
	char *line;
	file = fopen(path,"rt");
	if (file == NULL)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}
	line = read_string_from_opened_file(file);
	fclose(file);
	return line;
}

// write string into file
// returns (-1) in case of error or 0 otherwise
static int write_into_file(const char *path, const char *str)
{
	FILE * file;
	if (access(path, F_OK) == -1) // file doesn't exist
	{
		return -1;
	}
	file = fopen(path, "w+");
	if (file == NULL) // can't open file
	{
		return -1;
	}
	fputs(str, file);
	fclose(file);
	return 0;
}

// print command in string format into file
static void print_command(FILE *file, char **command)
{
	if (command != NULL)
	{
		int i = 0;
		while (command[i] != NULL)
		{
			fprintf(file, "%s ", command[i]);
			i++;
		}
	}
	fprintf(file,"\n");
}

// get cpu name
static char *get_cpu(void)
{
	FILE *file;
	char * line;
	file = fopen(CPUINFO_FILE, "rt");
	if (file == NULL)
	{
		return NULL;
	}
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char *arg = (char *)malloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)malloc((strlen(line) + 1) * sizeof(char));
		check_malloc(arg);
		check_malloc(value);
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

// get memory size
static char *get_memory(void)
{
	FILE *file;
	char * line;
	file = fopen(MEMINFO_FILE,"rt");
	if (file == NULL)
	{
		return NULL;
	}
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char *arg = (char *)malloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)malloc((strlen(line) + 1) * sizeof(char));
		check_malloc(arg);
		check_malloc(value);
		sscanf(line, "%s %s", arg, value);
		if (strcmp(arg, "MemTotal:") == 0)
		{
			long mem_size = atol(value);
			fclose(file);
			mem_size *= 1000;
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

// get kernel version
static char *get_kernel(void)
{
	char *line = read_string_from_file(VERSION_FILE);
	char *arg;
	char *value;
	int i = 0;
	if (line == NULL)
	{
		return NULL;
	}
	arg = (char *)malloc((strlen(line) + 1) * sizeof(char));
	value = (char *)malloc((strlen(line) + 1) * sizeof(char));
	check_malloc(arg);
	check_malloc(value);
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
	return strdup(value);
}

/* Control groups handling. */

// find path_to_memory and path_to_cpuacct 
static void find_cgroup_location(void)
{
	const char *path = MOUNTS_FILE;
	FILE *results;
	char *line = NULL;
	results = fopen(path, "rt");
	if (results == NULL)
	{
		exit_res_manager(errno, NULL, "Can't open file /proc/mounts");
	}
	while ((line = read_string_from_opened_file(results)) != NULL)
	{
		char * name = (char*) malloc((strlen(line) + 1) * sizeof(char));
		char * path = (char*) malloc((strlen(line) + 1) * sizeof(char));
		char * type = (char*) malloc((strlen(line) + 1) * sizeof(char));
		char * subsystems = (char*) malloc((strlen(line) + 1) * sizeof(char));
		check_malloc(name);
		check_malloc(path);
		check_malloc(type);
		check_malloc(subsystems);
		sscanf(line, "%s %s %s %s", name, path, type, subsystems);
		if (strcmp(type, CGROUP) == 0 && strstr(subsystems, CPUACCT_CONTROLLER))
		{
			param.path_to_cpuacct = (char *)malloc(sizeof(char) * (strlen(path) + 1));
			check_malloc(param.path_to_cpuacct);
			strcpy(param.path_to_cpuacct, path);
			param.path_to_cpuacct_origin = (char *)malloc(sizeof(char) * (strlen(path) + 1));
			check_malloc(param.path_to_cpuacct_origin);
			strcpy(param.path_to_cpuacct_origin, path);
		}
		if (strcmp(type, CGROUP) == 0 && strstr(subsystems, MEMORY_CONTROLLER))
		{
			param.path_to_memory = (char *)malloc(sizeof(char) * (strlen(path) + 1));
			check_malloc(param.path_to_memory);
			strcpy(param.path_to_memory, path);
			param.path_to_memory_origin = (char *)malloc(sizeof(char) * (strlen(path) + 1));
			check_malloc(param.path_to_memory_origin);
			strcpy(param.path_to_memory_origin, path);
		}
		free(name);
		free(path);
		free(type);
		free(subsystems);
		free(line);
	}
	if (param.path_to_memory == NULL)
	{
		exit_res_manager(EACCES, NULL, "You need to mount memory cgroup: sudo mount -t cgroup -o memory <name> <path>");
	}
	if (param.path_to_cpuacct == NULL)
	{
		exit_res_manager(EACCES, NULL, "You need to mount cpuacct cgroup: sudo mount -t cgroup -o cpuacct <name> <path>");
	}
}

// create full name for cgroup for specified controller
static char * get_cgroup_controller_name(char * controller, char * generic_name, char * resmanager_dir)
{
	char *tmp_path = realloc(controller, sizeof(char) * (strlen(controller) + strlen(generic_name) + strlen(resmanager_dir) + strlen(RESMANAGER_MODIFIER) + 3));
	char * result_name;
	check_malloc(tmp_path);
	result_name = tmp_path;
	strcat(result_name, "/");
	strcat(result_name, resmanager_dir);
	strcat(result_name, "/");
	strcat(result_name, RESMANAGER_MODIFIER);
	strcat(result_name, generic_name);
	return result_name;
}

// create full name for cgroup directory:
// <path from /proc/mounts>/<resmanager_dir>/resource_manager_<pid>
static void get_cgroup_name(char *resmanager_dir)
{
	// pid of process
	char *generic_name = itoa(getpid()); 
	param.path_to_memory = get_cgroup_controller_name(param.path_to_memory, generic_name, resmanager_dir);
	param.path_to_cpuacct = get_cgroup_controller_name(param.path_to_cpuacct, generic_name, resmanager_dir);
	free(generic_name);
}

// check possible errors in creating new cgroup directory
static void check_mkdir_errors(int mkdir_errno, char * controller)
{
	if (mkdir_errno == EACCES) // permission error
	{
		if (strcmp(controller, param.path_to_memory) == 0)
		{
			exit_res_manager(mkdir_errno, NULL, concat(
				"Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", param.path_to_memory_origin));
		}
		else
		{
			exit_res_manager(mkdir_errno, NULL, concat(
				"Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", param.path_to_cpuacct_origin));
		}
	}
	else if (mkdir_errno == EEXIST) // directory exists
	{
		if (check_tasks_file(controller)) // tasks file is empty 
		{
			rmdir(controller);
			mkdir(controller, 0777);
		}
		else
		{
			exit_res_manager(mkdir_errno,NULL,concat(
				"There is control group with running processes in ", controller));
		}
	}
	else // other errors
	{
		exit_res_manager(mkdir_errno,NULL,concat("Error during creation ", controller));
	}
}

// create new cgroups for known path (<path from /proc/mounts>/<resmanager_dir>/resource_manager_<pid>)
static void create_cgroup(void)
{
	// if path to cpuacct and path to memory are equal then only one directory will be made 
	if (mkdir(param.path_to_memory, 0777) == -1)
	{
		check_mkdir_errors(errno, param.path_to_memory);
	}
	if (strcmp(param.path_to_memory,param.path_to_cpuacct) != 0) // pathes are different -> need to create two directories
	{
		if (mkdir(param.path_to_cpuacct, 0777) == -1)
		{
			check_mkdir_errors(errno, param.path_to_cpuacct);
		}
	}
}

// set specified parameter into specified file in specified cgroup
// in case of error Resource Manager will be terminated.
static void set_cgroup_parameter(const char *file_name, const char * controller, char *value)
{
	char *path = (char *)malloc((strlen(controller) + strlen(file_name) + 2) * sizeof(char));
	check_malloc(path);
	strcpy(path, controller);
	strcat(path, "/");
	strcat(path, file_name);
	chmod(path, 0666);
	if (write_into_file(path,value) == -1)
	{
		if (strcmp(file_name, MEMSW_LIMIT) == 0) // special error text for memsw
			exit_res_manager(ENOENT, NULL, "Error: Memory control group doesn't have swap extension\n"
				"You need to set swapaccount=1 as a kernel boot parameter to be able to compute (memory+Swap) usage");
		exit_res_manager(errno, NULL, concat("Can't write value to the file ", path));
	}
	free(path);
}

// get specified parameter from specified file in specified cgroup.
// in case of error during reading Resource Manager will be terminated.
// Return readed string.
static char * get_cgroup_parameter(char *file_name, const char * controller)
{
	char *str;
	char *path = (char *)malloc((strlen(controller) + strlen(file_name) + 2) * sizeof(char));
	check_malloc(path);
	strcpy(path, controller);
	strcat(path, "/");
	strcat(path, file_name);
	chmod(path, 0666);
	str = read_string_from_file(path);
	if (str == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: Can't read parameter from ", path));
	}
	free(path);
	return str;
}

// set memory limit in cgroup with memory controller
static void set_memlimit(void)
{
	set_cgroup_parameter(MEM_LIMIT, param.path_to_memory, itoa(param.memlimit));
	set_cgroup_parameter(MEMSW_LIMIT, param.path_to_memory, itoa(param.memlimit));
}

// add pid of created process to tasks file
static void add_task(int pid)
{
	set_cgroup_parameter(TASKS_FILE, param.path_to_memory, itoa(pid));
	if (strcmp(param.path_to_memory, param.path_to_cpuacct) != 0)
	{
		set_cgroup_parameter(TASKS_FILE, param.path_to_cpuacct, itoa(pid));
	}
}

// read line from cpuacct.stats file and return it's value
static char * get_cpu_stat_line(char * line)
{
	char * result;
	if (line == NULL)
	{
		exit_res_manager(ENOENT, NULL, "Error: Can't read the string from file cpuacct.stats");
	}
	else
	{
		char *arg = (char *)malloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)malloc((strlen(line) + 1) * sizeof(char));
		check_malloc(arg);
		check_malloc(value);
		sscanf(line, "%s %s", arg, value);
		result = value;
		free(line);
		free(arg);
	}
	return result;
}

// read file cpuacct.stats with special format:
// user <number_in_ms>
// sys <number_in_ms>
static void read_cpu_stats(statistics *stats)
{
	FILE *file;
	char *line;
	char *path_cpu_stat = (char *)malloc((strlen(param.path_to_cpuacct) + strlen(CPU_STAT) + 2) * sizeof(char));
	check_malloc(path_cpu_stat);
	strcpy(path_cpu_stat, param.path_to_cpuacct);
	strcat(path_cpu_stat,"/");
	strcat(path_cpu_stat, CPU_STAT);
	file = fopen(path_cpu_stat, "rt");
	if (file == NULL)
	{
		exit_res_manager(errno, NULL, concat("Error: Can't open file ",path_cpu_stat));
	}
	line = read_string_from_opened_file(file);
	stats->user_time = atof(get_cpu_stat_line(line)) / 1e2;
	line = read_string_from_opened_file(file);
	stats->sys_time = atof(get_cpu_stat_line(line)) / 1e2;
	free(path_cpu_stat);
	fclose(file);
}

// read statistics
static void get_stats(statistics *stats)
{
	char * cpu_usage;
	char * memory_usage = get_cgroup_parameter(MEMSW_MAX_USAGE, param.path_to_memory);
	stats->memory = atol(memory_usage);
	free(memory_usage);
	
	cpu_usage = get_cgroup_parameter(CPU_USAGE, param.path_to_cpuacct);
	stats->cpu_time = atol(cpu_usage) / 1e9;
	free(cpu_usage);
	
	// user and system time (not standart format)
	read_cpu_stats(stats);
}

// delete cgroups
static void remove_cgroup(void)
{
	rmdir(param.path_to_memory);
	rmdir(param.path_to_cpuacct);
}

/* Main Resource Manager functions. */

// print stats into file/console
static void print_stats(int exit_code, int signal, statistics *stats, const char *err_mes)
{
	FILE *out;

	if (param.outputfile == NULL)
	{
		out = stdout;
	}
	else
	{
		out = fopen(param.outputfile, "w");
		if (out == NULL)
		{
			fprintf(stdout, "Can't create file %s\n", param.outputfile);
			out = stdout;
		}
	}
	fprintf(out, "System settings:\n");
	fprintf(out, "\tkernel version: %s\n", get_kernel());
	fprintf(out, "\tcpu: %s", get_cpu());
	fprintf(out, "\tmemory: %s bytes\n", get_memory());
	
	fprintf(out, "Resource manager settings:\n");
	fprintf(out, "\tmemory limit: %ld bytes\n", param.memlimit);
	fprintf(out, "\ttime limit: %.0f ms\n", param.timelimit * 1000);
	fprintf(out, "\tcommand: ");
	print_command(out, param.command);
	fprintf(out, "\tcgroup memory controller: %s\n", param.path_to_memory);
	fprintf(out, "\tcgroup cpuacct controller: %s\n", param.path_to_cpuacct);
	fprintf(out, "\toutputfile: %s\n", param.outputfile);

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
		fprintf(out, "\tkilled by signal (resource manager): %i (%s)\n", signal,strsignal(signal));
	}

	if (exit_code == 0 && pid > 0 && stats != NULL) // script finished
	{
		fprintf(out, "Command execution status:\n");
		fprintf(out, "\texit code: %i\n", stats->exit_code);
		if (stats->sig_number != 0)
		{
			fprintf(out, "\tkilled by signal: %i (%s)\n", stats->sig_number, strsignal(stats->sig_number));
		}
		if (stats->cpu_time > param.timelimit)
		{
			fprintf(out, "\ttime exhausted\n");
		}
		else if (stats->memory > param.memlimit)
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
	
	if (param.outputfile != NULL)
	{
		fclose(out);
	}
}

// actions, which should be made at the end of the program: kill all created processes (if they were created),
// print statistics, remove cgroups
static void exit_res_manager(int exit_code, statistics *stats, const char *err_mes)
{
	kill_created_processes(SIGKILL);
	if (stats != NULL)
	{
		get_stats(stats);
	}
	remove_cgroup();
	print_stats(exit_code, param.script_signal, stats, err_mes);
	exit(exit_code);
}

/*
Config file format:
	<file> <value>
Into each <file> will be written <value>.
Returns err_mes or NULL in case of success.
*/
static char *read_config_file(char *configfile)
{
	FILE *file;
	char *line;
	file = fopen(configfile, "rt");
	if (file == NULL)
	{
		return concat("Can't open config file ", configfile);
	}
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char *file_name = (char *)malloc((strlen(line) + 1) * sizeof(char));
		char *value = (char *)malloc((strlen(line) + 1) * sizeof(char));
		check_malloc(file_name);
		check_malloc(value);
		sscanf(line, "%s %s", file_name, value);
		set_cgroup_parameter(file_name, param.path_to_memory, value);
		free(line);
		free(file_name);
		free(value);
	}
	fclose(file);
	return NULL;
}

// check tasks file => return 1 if it's clean, 0 otherwise
static int check_tasks_file(char *path_to_cgroup)
{
	char *path = (char *)malloc((strlen(path_to_cgroup) + strlen(TASKS_FILE) + 1) * sizeof(char));
	FILE *results;
	check_malloc(path);
	strcpy(path, path_to_cgroup);
	strcat(path, TASKS_FILE);																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																						
	results = fopen(path, "rt");
	free(path);
	if (results == NULL)
	{
		return 0;
	}
	if(read_string_from_opened_file(results) != NULL) // there is some string
	{
		fclose(results);
		return 0;
	}
	fclose(results);
	return 1;
}

// finish all created processes
static void kill_created_processes(int signum)
{
	if (pid > 0)
	{
		char *path;
		char * line = NULL;
		FILE * results;
		// kill main created process
		kill(pid, signum);
	
		// kill any other created processes 
		path = (char*)malloc((strlen(param.path_to_memory) + strlen(TASKS_FILE) + 1)*sizeof(char));
		check_malloc(path);
		strcpy(path,param.path_to_memory);
		strcat(path,TASKS_FILE);
		results = fopen(path,"rt");
		free(path);
		if (results == NULL)
			return; // file already was deleted
		while ((line = read_string_from_opened_file(results)) != NULL)
		{
			kill(atoi(line),signum);
			free(line);
		}
		fclose(results);
	}
}

// handle signals
static void terminate(int signum)
{
	param.script_signal = signum;
	kill_created_processes(SIGKILL);
	exit_res_manager(0, NULL, "Killed by signal");
}

// stop timer for checking time limit
static void stop_timer(void)
{
	if (param.alarm_time < 1000)
	{
		ualarm(0,0);
	}
	else
	{
		alarm(0);
	}
}

// set timer for checking time limit
static void set_timer(int alarm_time)
{
	if (param.alarm_time < 1000)
	{
		ualarm(param.alarm_time * 1000,0);
	}
	else
	{
		alarm(param.alarm_time / 1000);
	}
}

// handle SIGALRM, check time limit
static void check_time(int signum)
{
	char *cpu_usage = get_cgroup_parameter(CPU_USAGE, param.path_to_cpuacct);
	double cpu_time = atof(cpu_usage) / 1e9;
	free(cpu_usage);
	if (cpu_time >= param.timelimit)
	{
		kill_created_processes(SIGKILL);
	}
	else
	{
		set_timer(param.alarm_time);
	}
}

// redirect fd into file
// for example can repirect stdin == 1 into some file
static void redirect(int fd, char * path)
{
	int filedes[2];
	if (path == NULL)
	{
		return;
	}
	close(fd);
	filedes[0] = fd;
	filedes[1] = open(path, O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
	if (filedes[1] == -1)
	{
		exit_res_manager(0, NULL, "Can't open file for redirecting stdout/stderr");
	}
	
	if (dup2(filedes[0], filedes[1]) == -1)
	{
		exit_res_manager(0, NULL, "Error in duplicating file descriptor");
	}
	if (pipe(filedes) == -1)
	{
		exit_res_manager(0, NULL, "Error in creating a pipe");
	}
	if (fd == 1)
	{
		param.fd_stdout = filedes[1];
	}
	if (fd == 2)
	{
		param.fd_stderr = filedes[1];
	}
}

// print help
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

// initialize global structure
static void initialize_param(void)
{
	param.timelimit = STANDART_TIMELIMIT;
	param.memlimit = STANDART_MEMLIMIT;
	param.outputfile = NULL;
	param.command = NULL;
	param.alarm_time = 1000;
	param.path_to_memory_origin = NULL;
	param.path_to_cpuacct_origin = NULL;
	param.path_to_memory = NULL;
	param.path_to_cpuacct = NULL;
	param.fd_stdout = -1;
	param.fd_stderr = -1;
	param.script_signal = 0;
}

int main(int argc, char **argv)
{
	
	char *stdoutfile = NULL;
	char *stderrfile = NULL;	
	char *resmanager_dir = ""; // path to resource manager directory in control groups
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
	initialize_param();
	for (i = 1; i <= 31; i++)
	{
		if (i == SIGSTOP || i == SIGKILL ||i == SIGCHLD || i == SIGUSR1 || i == SIGUSR2 || i == SIGALRM || i == SIGWINCH)
		{
			continue;
		}
		if (signal(i, terminate) == SIG_ERR)
		{
			exit_res_manager(errno, NULL, "Cannot set signal handler");
		}
	}
	
	
	// parse command line
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
				exit_res_manager(EINVAL, NULL, "Expected integer number in ms as value of --interval");
			}
			param.alarm_time = atoi(optarg);
			break;
		case 'c':
			configfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			check_malloc(configfile);
			strcpy(configfile, optarg);
			break;
		case 's':
			stdoutfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			check_malloc(stdoutfile);
			strcpy(stdoutfile, optarg);
			break;
		case 'e':
			stderrfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			check_malloc(stderrfile);
			strcpy(stderrfile, optarg);
			break;
		case 'l':
			resmanager_dir = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			check_malloc(resmanager_dir);
			strcpy(resmanager_dir, optarg);
			break;
		case 'm':
			param.memlimit = atol(optarg);
			if (strstr(optarg, "Kb") != NULL)
			{
				param.memlimit *= 1000;
			}
			else if (strstr(optarg, "Mb") != NULL)
			{
				param.memlimit *= 1000 * 1000;
			}
			else if (strstr(optarg, "Gb") != NULL)
			{
				param.memlimit *= 1000;
				param.memlimit *= 1000;
				param.memlimit *= 1000;
			}
			else if (strstr(optarg, "Kib") != NULL)
			{
				param.memlimit *= 1024;
			}

			else if (strstr(optarg, "Mib") != NULL)
			{
				param.memlimit *= 1024 * 1024;
			}
			else if (strstr(optarg, "Gib") != NULL)
			{
				param.memlimit *= 1024;
				param.memlimit *= 1024;
				param.memlimit *= 1024;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, "Expected integer number with Kb|Mb|Gb|Kib|Mib|Gib| modifiers as value of -m");
			}
			break;
		case 't':
			param.timelimit = atof(optarg);
			if (strstr(optarg, "ms") != NULL)
			{
				param.timelimit /= 1000;
			}
			else if (strstr(optarg, "min") != NULL)
			{
				param.timelimit *= 60;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL, NULL, "Expected number with ms|min| modifiers as value of -t");
			}
			break;
		case 'o':
			param.outputfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			check_malloc(param.outputfile);
			strcpy(param.outputfile, optarg);
			break;
		default:
			is_options_ended = 1;
		}
		if (is_options_ended)
			break;
	}
	if (!is_options_ended)
		exit_res_manager(EINVAL, NULL, "Empty command");
	
	optind--; // optind - index of first argument in command; we need index of command
	param.command = (char **) malloc (sizeof(char *) * (argc - optind + 1));
	if (param.command == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	for (i = 0; i < argc - optind; i++)
	{
		param.command[i] = argv[optind + i];
		comm_arg++;
	}
	param.command[comm_arg] = NULL;
	// create new cgroup for command
	find_cgroup_location();
	get_cgroup_name(resmanager_dir);
	create_cgroup();
	// configure cgroup
	set_memlimit();
	if (configfile != NULL) // configfile was specified
	{
		char *err_mes = read_config_file(configfile);
		if (err_mes != NULL)
		{
			exit_res_manager(ENOENT, NULL, err_mes);
		}
	}
	
	// set timer for checking time limit
	if (signal(SIGALRM, check_time) == SIG_ERR)
	{
		exit_res_manager(errno, NULL, "Cannot set signal handler");
	}
	set_timer(param.alarm_time);
	
	// create new process for command
	time_before = gettime();
	pid = fork();
	if (pid == 0) // child process
	{
		redirect(1, stdoutfile); //redirect stdout
		redirect(2, stderrfile); // redirect stderr
		add_task(getpid()); // attach process to cgroup
		execvp(param.command[0], param.command); // run command
		exit(errno); // exit on error
	}
	else if (pid == -1)
	{
		exit_res_manager(errno, NULL, "Cannot create a new process");
	}
	
	// parent - wait
	wait_res = wait4(pid, &status, 0, NULL);
	wait_errno = errno;
	if (wait_res == -1)
	{
		if (wait_errno != EINTR) // don't include error "interrupted by signal"
		{
			exit_res_manager(errno, NULL, "Error: wait failed");
		}
	}
	time_after = gettime();
	stop_timer();
	// close files where stderr/stdout was redirected
	if (param.fd_stdout != -1)
	{
		close(param.fd_stdout);
	}
	if (param.fd_stderr != -1)
	{
		close(param.fd_stderr);
	}
	// create statistics
	stats = (statistics *)malloc(sizeof(statistics));
	check_malloc(stats);
	stats->wall_time = time_after - time_before;
	// if wait was interrupted by signal and exit code, signal number are unknown
	if (wait_errno == EINTR)
	{
		stats->exit_code = 0;
		stats->sig_number = SIGKILL;
	}
	else // wait didn't failed
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
	// get statistics from cgroup
	get_stats(stats);
	
	// print statistics, delete cgroup - normal execution
	exit_res_manager(0, stats, NULL);
	
	return 0;
}

