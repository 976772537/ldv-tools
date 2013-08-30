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
#define STANDART_MEMLIMIT 100 * 10e6

#define RESMANAGER_MODIFIER "resource_manager_"
#define MEMORY_CONTROLLER "memory"
#define CPUACCT_CONTROLLER "cpuacct"
// TODO: remove leading '/' from file names but not from absolute paths below.
#define TASKS_FILE "/tasks"
#define MEM_LIMIT "/memory.limit_in_bytes"
#define MEMSW_LIMIT "/memory.memsw.limit_in_bytes"
#define CPU_USAGE "/cpuacct.usage"
#define CPU_STAT "/cpuacct.stat"
#define MEMSW_MAX_USAGE "/memory.memsw.max_usage_in_bytes"

#define CPUINFO_FILE "/proc/cpuinfo"
#define MEMINFO_FILE "/proc/meminfo"
#define VERSION_FILE "/proc/version"
#define MOUNTS_FILE "/proc/mounts"

// TODO: remove useless word 'statistics' from 'struct statistics'.
typedef struct statistics
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

// TODO: remove useless word 'parameters' from 'struct parameters'.
typedef struct parameters
{
	double timelimit; // in seconds
	long memlimit; // in bytes
	char * outputfile;
	char ** command;
	int alarm_time; // time in ms

	// cgroup parameters
	char * path_to_memory_origin;
	char * path_to_cpuacct_origin;
	char * path_to_memory;
	char * path_to_cpuacct;

// TODO: clarify what does it mean. Why doesn't 'memlimit' belong to command-line parameters.
	// command-line parameters
	int fd_stdout;
	int fd_stderr;

// TODO: clarify what does it mean.
	// errors processing
	int is_mem_dir_created;
	int is_cpu_dir_created;
	
// TODO: what is this?
	int script_signal;
} parameters;

// TODO: what is this?
parameters param;

// TODO: what is child process?
// pid of child process
int pid = 0;


static void kill_created_processes(int signum);
static void exit_res_manager(int exit_code, statistics *stats, const char *err_mes);
static int check_tasks_file(char *);

/* Library functions. */

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
	
	char *str = (char *) malloc(sizeof(char) * (number_of_chars + 1));
	if (str == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	int i;
	long count = num;
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
	if (str1 == NULL)
	{
		return strdup(str2);
	}
	if (str2 == NULL)
	{
		return strdup(str1);
	}
	char *tmp = (char *) malloc((strlen(str1) + strlen(str2) + 1) * sizeof(char));
	if (tmp == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(tmp, str1);
	strcat(tmp, str2);
	
	return tmp;
}

// TODO: replace all '()' with '(void)' for functions that don't take any parameter.
// get current time in microseconds (10^-6)
static double gettime()
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
	if (file == NULL)
	{
		return NULL;
	}
	char * line = (char *)malloc(sizeof(char) * (STR_LEN + 1));
	if (line == NULL)
	{
		exit_res_manager(errno,NULL,"Error: Not enough memory");
	}
	if (fgets(line, STR_LEN, file) == NULL)
		return NULL; // EOF
// TODO: try strchr() function and '\n'.
	while(strstr(line, "\n") == NULL)  // not full string
	{
		char * tmp_line = (char *)realloc(line, sizeof(char) * (strlen(line) + STR_LEN + 1));
		if (tmp_line != NULL)
		{
			char part_of_line[STR_LEN];
			fgets(part_of_line, STR_LEN, file);
			line = tmp_line;
			strcat(line, part_of_line);
		}
		else
		{
			exit_res_manager(errno, NULL, "Error: Not enough memory");
		}
	}

	return line;
}

// read first string from file
static char *read_string_from_file(const char *path)
{
	FILE *file;
	
	file = fopen(path,"rt");
	if (file == NULL)
	{
		exit_res_manager(errno, NULL, strerror(errno));
	}
	char *line = read_string_from_opened_file(file);
	fclose(file);

	return line;
}

// TODO: this function is often called without checking its return value (-1). It has sence to exit from it, but error message can be passed from callers.
// write string into file
static int write_into_file(const char *path, const char *str)
{
	if (access(path, F_OK) == -1) // file doesn't exist
	{
		return -1;
	}
	FILE * file;
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
static char *get_cpu()
{
	FILE *file;

	file = fopen(CPUINFO_FILE, "rt");
	if (file == NULL)
	{
		return NULL;
	}
	char * line;
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
// TODO: replace all variable length arrays with dynamically allocated memory.
		char arg[strlen(line)];
		char value[strlen(line)];
		sscanf(line, "%s %s", arg, value);
		if (strcmp(arg, "model") == 0 && strcmp(value, "name") == 0)
		{
			int i = 0;
			while (line[i] != ':')
			{
				i++;
			}
			i += 2;
			int num_of_spaces = i;
			while (line[i] != '\0')
			{
				line[i - num_of_spaces] = line[i];
				i++;
			}
			line[i - num_of_spaces] = '\0';
			fclose(file);
			
			return line;
		}
		free(line);
	}
	fclose(file);

	return NULL;
}

// get memory size
static char *get_memory()
{
	FILE *file;

	file = fopen(MEMINFO_FILE,"rt");
	if (file == NULL)
	{
		return NULL;
	}
	char * line;
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char arg[strlen(line)];
		char value[strlen(line)];
		sscanf(line, "%s %s", arg, value);
		if (strcmp(arg, "MemTotal:") == 0)
		{
			fclose(file);
			long mem_size = atol(value);
			mem_size *= 1024;

			return itoa(mem_size);
		}
		free(line);
	}
	fclose(file);

	return NULL;
}

// get kernel version
static char *get_kernel()
{
	char *line;
	
	line = read_string_from_file(VERSION_FILE);
	if (line == NULL)
	{
		return NULL;
	}
	char arg[strlen(line)];
	char value[strlen(line)];
	sscanf(line, "%s %s %s", arg, arg, value);
	int i = 0;
	while (value[i] != 0)
	{
		if (value[i] == '-')
		{
			value[i] = 0;
			break;
		}
		i++;
	}

	return strdup(value);
}

/* Control groups handling. */

// find path_to_memory and path_to_cpuacct 
static void find_cgroup_location()
{
	const char *path = MOUNTS_FILE;
	FILE *results;
	
	results = fopen(path, "rt");
	if (results == NULL)
	{
		exit_res_manager(errno, NULL, "Can't open file /proc/mounts");
	}
	char *line = NULL;
	while ((line = read_string_from_opened_file(results)) != NULL)
	{
		char name[strlen(line)];
		char path[strlen(line)];
		char type[strlen(line)];
		char subsystems[strlen(line)];

		sscanf(line, "%s %s %s %s", name, path, type, subsystems);
// TODO: why does "cgroup" name is hardcoded here and "cpuacct" doesn't? Make both the same. I would like to have CGROUP macro.
		if (strcmp(type, "cgroup") == 0 && strstr(subsystems, CPUACCT_CONTROLLER))
		{	
			param.path_to_cpuacct = (char *)malloc(sizeof(char) * (strlen(path) + 1));
			if (param.path_to_cpuacct == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
			strcpy(param.path_to_cpuacct, path);
			param.path_to_cpuacct_origin = (char *)malloc(sizeof(char) * (strlen(path) + 1));
			if (param.path_to_cpuacct_origin == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
			strcpy(param.path_to_cpuacct_origin, path);
		}
		if (strcmp(type, "cgroup") == 0 && strstr(subsystems, MEMORY_CONTROLLER))
		{	
			param.path_to_memory = (char *)malloc(sizeof(char) * (strlen(path) + 1));
			if (param.path_to_memory == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
			strcpy(param.path_to_memory, path);
			param.path_to_memory_origin = (char *)malloc(sizeof(char) * (strlen(path) + 1));
			if (param.path_to_memory_origin == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
			strcpy(param.path_to_memory_origin, path);
		}
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

// create full name for cgroup directory:
// <path from /proc/mounts>/<resmanager_dir>/resource_manager_<pid>
static void get_cgroup_name(char *resmanager_dir)
{
	// pid of process
	char *generic_name = itoa(getpid()); 
	
	// same directory
	if (resmanager_dir == NULL)
	{
// TODO: it has much sence to write malloc wrapper function that will call exit_res_manager(errno, NULL, "Error: Not enough memory") in case of failures.
		resmanager_dir = (char *)malloc(sizeof(char) * 1);
		if (resmanager_dir == NULL)
		{
			exit_res_manager(errno, NULL, "Error: Not enough memory");
		}
// TODO: why is it necessary? resmanager_dir[0] = '\0' is better?..
		strcpy(resmanager_dir, "");
	}
	
	// add "/<resmanager_dir>/RESMANAGER_MODIFIER_pid" to found path
// TODO: almost the same wrapper for realloc as for malloc.
	char *tmp_path_to_memory = realloc(param.path_to_memory, sizeof(char) * (strlen(param.path_to_memory) + strlen(generic_name) + strlen(resmanager_dir) + strlen(RESMANAGER_MODIFIER) + 3));
	if (tmp_path_to_memory != NULL) 
	{
		param.path_to_memory = tmp_path_to_memory;
		strcat(param.path_to_memory, "/");
		strcat(param.path_to_memory, resmanager_dir);
		strcat(param.path_to_memory, "/");
		strcat(param.path_to_memory, RESMANAGER_MODIFIER);
		strcat(param.path_to_memory, generic_name);
	}
	else
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	char *tmp_path_to_cpuacct = realloc(param.path_to_cpuacct, sizeof(char) * (strlen(param.path_to_cpuacct) + 
			strlen(generic_name) + strlen(resmanager_dir) + strlen(RESMANAGER_MODIFIER) + 3));
	if (tmp_path_to_cpuacct != NULL) 
	{
		param.path_to_cpuacct = tmp_path_to_cpuacct;
// TODO: absolutely the same as above -> join them together.
		strcat(param.path_to_cpuacct, "/");
		strcat(param.path_to_cpuacct, resmanager_dir);
		strcat(param.path_to_cpuacct, "/");
		strcat(param.path_to_cpuacct, RESMANAGER_MODIFIER);
		strcat(param.path_to_cpuacct, generic_name);
	}
	else
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	free(generic_name);
}

// TODO: what is global path?
// create new cgroups for known global path
static void create_cgroup()
{
	// if path to cpuacct and path to memory are equal then only one directory will be made 
	if (mkdir(param.path_to_memory, 0777) == -1)
	{
		if (errno == EACCES)
		{
			exit_res_manager(errno, NULL, concat(
				"Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", param.path_to_memory_origin));
		}
		else if (errno == EEXIST)
		{
			if (check_tasks_file(param.path_to_memory)) 
			{
				rmdir(param.path_to_memory);
				mkdir(param.path_to_memory, 0777);
// TODO: remove all commented lines of code.
				//create_cgroup();
				///return;
			}
			else
			{
				exit_res_manager(errno,NULL,concat(
					"There is control group with running processes in ", param.path_to_memory));
			}
		}
		else // other errors
		{
			exit_res_manager(errno,NULL,concat(
				"Error during creation of directory ", param.path_to_memory));
		}
	}
// TODO: move large comments directly before statements elsewhere.
	param.is_mem_dir_created = 1; // set flag for deleting this directory
	if (strcmp(param.path_to_memory,param.path_to_cpuacct) != 0) // pathes are different -> need to create two directories
	{
// TODO: this code is very similar to the one used above. Replace them with one function.
		if (mkdir(param.path_to_cpuacct, 0777) == -1)
		{
			if (errno == EACCES)
			{
				exit_res_manager(errno, NULL, concat(
					"Error: you need to change permission in cgroup directory: sudo chmod o+wt ", param.path_to_cpuacct_origin));
			}
			else if (errno == EEXIST)
			{
				if (check_tasks_file(param.path_to_cpuacct)) // if tasks file is empty -> delete this directory and try to create it once more
				{
					rmdir(param.path_to_cpuacct);
					mkdir(param.path_to_cpuacct, 0777);
					//rmdir(param.path_to_memory); // memory also should be deleted or it would be an error diring it's creation
					//create_cgroup();
					//return;
				}
				else 
				{
					exit_res_manager(errno, NULL, concat(
						"There is control group with running processes in ", param.path_to_cpuacct));
				}
			}
			else 
			{
				exit_res_manager(errno, NULL, concat(
					"Error during creation of directory ", param.path_to_cpuacct));
			}
		}
		param.is_cpu_dir_created = 1;
	}
}

// set memory limit in cgroup with memory controller
static void set_memlimit()
{
// TODO: code enclosed in these todos is used very many times and should be made as a function.
	char *path_mem = (char *)malloc((strlen(param.path_to_memory) + strlen(MEM_LIMIT) + 1) * sizeof(char));

	if (path_mem == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path_mem, param.path_to_memory);
	strcat(path_mem, MEM_LIMIT);
	chmod(path_mem, 0666);
	write_into_file(path_mem, itoa(param.memlimit));
	free(path_mem);
// TODO: end of code

	char *path_memsw = (char *)malloc((strlen(param.path_to_memory) + strlen(MEMSW_LIMIT) + 1) * sizeof(char));
	if (path_memsw == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path_memsw, param.path_to_memory);
	strcat(path_memsw, MEMSW_LIMIT); // memory+swap limit
	chmod(path_memsw, 0666);
	if (write_into_file(path_memsw,itoa(param.memlimit)) == -1)
	{
		exit_res_manager(ENOENT, NULL, "Error: Memory control group doesn't have swap extension\nYou need to set swapaccount=1 as a kernel boot parameter to be able to compute (memory+Swap) usage");
	}
	free(path_memsw);
}

// add pid of created process to tasks file
static void add_task(int pid)
{
	char *path_mem = (char *)malloc((strlen(param.path_to_memory) + strlen(TASKS_FILE) + 1) * sizeof(char));

	if (path_mem == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path_mem,param.path_to_memory);
	strcat(path_mem,TASKS_FILE);
	chmod(path_mem, 0666);
	write_into_file(path_mem,itoa(pid));
	free(path_mem);
	
	if (strcmp(param.path_to_memory, param.path_to_cpuacct) != 0)
	{
		char *path_cpu = (char *)malloc((strlen(param.path_to_cpuacct) + strlen(TASKS_FILE) + 1) * sizeof(char));
		if (path_cpu == NULL)
		{
			exit_res_manager(errno, NULL, "Error: Not enough memory");
		}
		strcpy(path_cpu, param.path_to_cpuacct);
		strcat(path_cpu, TASKS_FILE);
		chmod(path_cpu, 0666);
		write_into_file(path_cpu, itoa(pid));
		free(path_cpu);
	}
}

// read statistics
static void get_stats(statistics *stats)
{
// TODO: useless comment.
	// memor + swap
	char *path_mem = (char *)malloc((strlen(param.path_to_memory) + strlen(MEMSW_MAX_USAGE) + 1) * sizeof(char));
	
	if (path_mem == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path_mem, param.path_to_memory);
	strcat(path_mem, MEMSW_MAX_USAGE); // read (memory+swap)
	char *str = read_string_from_file(path_mem);
	if (str == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: Can't open file ",path_mem));
	}
	stats->memory = atol(str);
	free(str);
	free(path_mem);
	
	// cpu time
	char *path_cpu = (char *)malloc((strlen(param.path_to_cpuacct) + strlen(CPU_USAGE) + 1) * sizeof(char));
	if (path_cpu == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path_cpu, param.path_to_cpuacct);
	strcat(path_cpu, CPU_USAGE);
	str = read_string_from_file(path_cpu);
	if (str == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: Can't open file ",path_cpu));
	}
	stats->cpu_time = atof(str) / 10e8;
	free(str);
	free(path_cpu);
	
	// user and system time
	char *path_cpu_stat = (char *)malloc((strlen(param.path_to_cpuacct) + strlen(CPU_STAT) + 1) * sizeof(char));
	if (path_cpu_stat == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path_cpu_stat, param.path_to_cpuacct);
	strcat(path_cpu_stat, CPU_STAT);
	FILE *file;
	file = fopen(path_cpu_stat, "rt");
	if (file == NULL)
	{
		exit_res_manager(errno, NULL, concat("Error: Can't open file ",path_cpu_stat));
	}
	char *line = read_string_from_opened_file(file);
	if (line == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: Can't read the first string from cpuacct.stat file ",path_cpu_stat));
	}
	char arg[strlen(line)];
	char value[strlen(line)];
	sscanf(line, "%s %s", arg, value);
	stats->user_time = atof(value) / 10e1;
	free(line);
	
	line = read_string_from_opened_file(file);
	if (line == NULL)
	{
		exit_res_manager(ENOENT, NULL, concat("Error: Can't read the second string from cpuacct.stat file ",path_cpu_stat));
	}
	sscanf(line, "%s %s", arg, value);
	stats->sys_time = atof(value) / 10e1;
	free(line);
	free(path_cpu_stat);
	fclose(file);
}

// set specified parameter into specified file in cgroup.
// Returns -1 in case of error in opening file or 0.
static int set_cgroup_parameter(char *file_name, char *value)
{
	char *path = (char *)malloc((strlen(param.path_to_memory) + strlen(file_name) + 2) * sizeof(char));
	if (path == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path, param.path_to_memory);
	strcat(path, "/");
	strcat(path, file_name);
	chmod(path, 0666);
	return write_into_file(path,value);
}

// delete cgroups
static int remove_cgroup()
{
	int err1 = 0;
	int err2 = 0;
	//if (param.is_mem_dir_created)
		err1 = rmdir(param.path_to_memory);
	//if (param.is_cpu_dir_created)
		err2 = rmdir(param.path_to_cpuacct);
	return (err1 == 0) && (err2 == 0);
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
	if (pid > 0)
	{
		kill_created_processes(SIGKILL);
	}
	if (stats != NULL)
	{
		get_stats(stats);
	}
	remove_cgroup();
	/*if (!remove_cgroup()) // error in deleting
	{
		if (err_mes == NULL)
			print_stats(exit_code, param.script_signal, stats, "Error in deleting control groups directories. "
				"Please delete them manually");
		else
			print_stats(exit_code, param.script_signal, stats, concat(err_mes, ". Error in deleting control groups directories. "
				"Please delete them manually"));
	}
	else*/
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

	file = fopen(configfile, "rt");
	if (file == NULL)
	{
		return concat("Can't open config file ", configfile);
	}
	char *line;
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char file_name[strlen(line)];
		char value[strlen(line)];
		sscanf(line, "%s %s", file_name, value);
		if (set_cgroup_parameter(file_name, value) == -1) // error in opening file
		{
			return concat("Can't open file ", file_name);
		}
		free(line);
	}
	fclose(file);
	return NULL;
}

// check tasks file => return 1 if it's clean, 0 otherwise
static int check_tasks_file(char *path_to_cgroup)
{
	char *path = (char *)malloc((strlen(path_to_cgroup) + strlen(TASKS_FILE) + 1) * sizeof(char));

	if (path == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path, path_to_cgroup);
	strcat(path, TASKS_FILE);
	FILE *results;
	results = fopen(path, "rt");
	free(path);
	if (results == NULL)
	{
		return 0;
	}
	if(read_string_from_opened_file(results) != NULL) // there is some string
	{
		return 0;
	}
	return 1;
}

// TODO: function that contains just one statement is useless.
// finish all created processes
static void kill_created_processes(int signum)
{
	kill(pid, signum);
	/*
	// if there are still pids in tasks file => finish them
	while (check_tasks_file(param.path_to_memory) == 0)
	{
		char *path = (char*)malloc((strlen(param.path_to_memory) + strlen(TASKS_FILE) + 1)*sizeof(char));
		if (path == NULL)
		{
			exit_res_manager(errno,NULL,"Error: Not enough memory");
		}
		strcpy(path,param.path_to_memory);
		strcat(path,TASKS_FILE);
		FILE * results;
		results = fopen(path,"rt");
		free(path);
		if (results == NULL)
			return;
		char * line = NULL;
		while ((line = read_string_from_opened_file(results)) != NULL)
		{
			kill(atoi(line),signum);
			free(line);
		}
	}
	
	while (check_tasks_file(param.path_to_cpuacct) == 0)
	{
		char *path = (char*)malloc((strlen(param.path_to_cpuacct) + strlen(TASKS_FILE) + 1)*sizeof(char));
		if (path == NULL)
		{
			exit_res_manager(errno,NULL,"Error: Not enough memory");
		}
		strcpy(path,param.path_to_cpuacct);
		strcat(path,TASKS_FILE);
		FILE * results;
		results = fopen(path,"rt");
		free(path);
		if (results == NULL)
			return;
		char * line = NULL;
		while ((line = read_string_from_opened_file(results)) != NULL)
		{
			kill(atoi(line),signum);
			free(line);
		}
	}*/
	
}

// handle signals
static void terminate(int signum)
{
	param.script_signal = signum;/*
	if (pid > 0)
	{
		kill_created_processes(SIGKILL);
	}
	else // signal before starting command
	{
		statistics *stats = (statistics*)malloc(sizeof(statistics));
		if (stats == NULL)
		{
			exit_res_manager(errno,NULL,"Error: Not enough memory");
		}
		stats->exit_code = 1;
		stats->sig_number = signum;
		stats->wall_time = 0;
		exit_res_manager(0,stats,NULL);
	}*/
	if (pid > 0)
	{
		kill_created_processes(SIGKILL);
	}
	exit_res_manager(0, NULL, NULL);
}

// stop timer for checking time limit
static void stop_timer()
{
// TODO: why 1000 is needed? Try to use ualarm() always.
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
// TODO: why 1000 is needed? Try to use ualarm() always.
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
	char *path = (char *)malloc((strlen(param.path_to_cpuacct) + strlen(CPU_USAGE) + 1) * sizeof(char));
	if (path == NULL)
	{
		exit_res_manager(errno, NULL, "Error: Not enough memory");
	}
	strcpy(path, param.path_to_cpuacct);
	strcat(path, CPU_USAGE);
	char *str = read_string_from_file(path);
	double cpu_time = atof(str) / 10e8;
	free(str);
	free(path);
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
//TODO: implement error processing for this function.
static void redirect(int fd, char * path)
{
	if (path == NULL)
	{
		return;
	}
	int filedes[2];
	close(fd);
	filedes[0] = fd;

	filedes[1] = open(path, O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
// TODO: why does this statement mean?
	if (fd == 1)
		
	if (filedes[1] == -1)
		return;
	
	if (dup2(filedes[0], filedes[1]) == -1)
	{
		return;
	}
	if (pipe(filedes) == -1)
	{
		return;
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
static void print_usage()
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
static void initialize_param()
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
	param.is_mem_dir_created = 0;
	param.is_cpu_dir_created = 0;
	param.script_signal = 0;
}

int main(int argc, char **argv)
{
	initialize_param();
	char *stdoutfile = NULL;
	char *stderrfile = NULL;	
	char *resmanager_dir = ""; // path to resource manager directory in control groups
	char *configfile = NULL;
	int i;
	int comm_arg = 0;
	int c;

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
	int option_index = 0;
	static struct option long_options[] = {
		{"interval", 1, 0, 'i'},
		{"stdout", 1, 0, 's'},
		{"stderr", 1, 0, 'e'},
		{"config", 1, 0, 'c'},
		{0, 0, 0, 0}
	};
	
	// parse command line
	while ((c = getopt_long(argc, argv, "-hm:t:o:kl:0", long_options, &option_index)) != -1)
	{
		switch(c)
		{
		case 'k':
			//do nothing
			break;
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
			if (configfile == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
			strcpy(configfile, optarg);
			break;
		case 's':
			stdoutfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			if (stdoutfile == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
			strcpy(stdoutfile, optarg);
			break;
		case 'e':
			stderrfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			if (stderrfile == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
			strcpy(stderrfile, optarg);
			break;
		case 'l':
			resmanager_dir = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			if (resmanager_dir == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
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
			if (param.outputfile == NULL)
			{
				exit_res_manager(errno, NULL, "Error: Not enough memory");
			}
			strcpy(param.outputfile, optarg);
			break;
		default:
			// finish parsing optional parameters
//TODO: nevertheless replace goto statement with one more loop check.
			goto exit_parser;
		}
	}
	
	exit_res_manager(EINVAL, NULL, "Empty command");
	
exit_parser:
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
	double time_before = gettime();
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
	int status;
	int wait_res;
	wait_res = wait4(pid, &status, 0, NULL);
	int wait_errno = errno;
	if (wait_res == -1)
	{
		if (wait_errno != EINTR) // don't include error "interrupted by signal"
		{
			exit_res_manager(errno, NULL, "Error: wait failed");
		}
	}
	double time_after = gettime();
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
	statistics *stats = (statistics *)malloc(sizeof(statistics));
	if (stats == NULL)
	{
		exit_res_manager(errno, NULL, "Not enough memory");
	}
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

