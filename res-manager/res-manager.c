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

#define STR_LEN 80
#define STANDART_TIMELIMIT 60
#define STANDART_MEMLIMIT 100 * 10e6


const char * resmanager_modifier = "resource_manager_"; // modifier to the names of resource manager cgroups
const char * memory_controller = "memory";
const char * cpuacct_controller = "cpuacct";
const char * tasks_file = "/tasks";
const char * mem_limit = "/memory.limit_in_bytes";
const char * memsw_limit = "/memory.memsw.limit_in_bytes";
const char * cpu_usage = "/cpuacct.usage";
const char * cpu_stat = "/cpuacct.stat";
const char * memsw_max_usage = "/memory.memsw.max_usage_in_bytes";


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

double timelimit = STANDART_TIMELIMIT; // in seconds
long memlimit = STANDART_MEMLIMIT; // in bytes
char * outputfile;
char ** command = NULL;
int alarm_time = 1000; // time in ms
int script_signal = 0; // signal which killed script

// cgroup parameters
char * path_to_memory = "";
char * path_to_cpuacct = "";

// command line parameters
int fd_stdout = -1;
int fd_stderr = -1;

//errors processing
int is_mem_dir_created = 0;
int is_cpu_dir_created = 0;
int pid = 0; // pid of child process


void kill_created_processes(int signum);
void exit_res_manager(int exit_code, int signal, statistics *stats, const char * err_mes);

/*General functions*/

int get_num(long num)
{
	int ret = 1;
	long count = num;
	while ((count = count/10) > 0) ret++;
	return ret;
}

char * itoa(long num)
{
	int number_of_chars = get_num(num);
	char * str = (char *) malloc (sizeof(char *) * (number_of_chars + 1));
	if (str == NULL)
	{
		exit_res_manager(errno,0,NULL,"Error: Not enough memory");
	}
	int i;
	long count = num;
	for (i = number_of_chars - 1; i >= 0; i--)
	{
		str[i] = count%10 + '0';
		count = count / 10;
	}
	str[number_of_chars] = 0;
	return str;
}

char * concat(char * str1, char * str2)
{
	char tmp[strlen(str1) + strlen(str2) + 1];
	strcpy(tmp,str1);
	strcat(tmp,str2);
	return strdup(tmp);
}

double gettime()
// get current time in microseconds (10^-6)
{
	struct timeval time;
	gettimeofday(&time, NULL);
	return time.tv_sec + time.tv_usec / 1000000.0;
}

int is_number(char * str)
// return true, if str is number
{
	int i = 0;
	if (str == NULL)
		return 0;
	while (str[i] != '\0')
	{
		if (!isdigit(str[i]))
			return 0;
		i++;
	}
	return 1;
}

char * read_string_from_opened_file(FILE * file)
// read string from opened file into dynamic array 
{
	if (file == NULL)
		return NULL;
	char * line = (char *)malloc(sizeof(char) * (STR_LEN));
	if (fgets(line, STR_LEN, file) == NULL)
		return NULL; // EOF
	while(strstr(line,"\n") == NULL)  // not full string
	{
		char * tmp_line = (char *)realloc (line, sizeof(char) * (strlen(line) + STR_LEN + 1));
		if (tmp_line != NULL)
		{
			char part_of_line [STR_LEN];
			fgets(part_of_line, STR_LEN, file);
			line = tmp_line;
			strcat(line, part_of_line);
		}
		else
		{
			exit_res_manager(errno,0,NULL,"Error: Not enough memory");
		}
	}
	return line;
}

char * read_string_from_file(const char * path)
// read first string from file
{
	FILE * file;
	file = fopen(path,"rt");
	if (file == NULL)
		return NULL;
	char * line = read_string_from_opened_file(file);
	fclose(file);
	return line;
}

int write_into_file(const char * path,const char * str)
// write string into file
{
	if (access(path, F_OK) == -1) // file doesn't exist
		return -1;
	FILE * file;
	file = fopen(path,"w+");
	if (file == NULL) // can't open file
		return -1;
	fputs(str, file);
	fclose(file);
	return 0;
}

void print_command(FILE * file, char ** command)
// print command in string format into file
{
	if (command != NULL)
	{
		int i = 0;
		while (command[i] != NULL)
		{
			fprintf(file, "%s ",command[i]);
			i++;
		}
	}
	fprintf(file,"\n");
}

char * get_cpu()
// get cpu name
{
	FILE * file;
	file = fopen("/proc/cpuinfo","rt");
	if (file == NULL)
	{
		return NULL;
	}
	char * line;
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char arg [strlen(line)];
		char value [strlen(line)];
		sscanf(line,"%s %s",arg,value);
		if (strcmp(arg, "model") == 0 && strcmp(value, "name") == 0)
		{
			int i = 0;
			while (line[i] != ':')
			{
				line[i] = ' ';
				i++;
			}
			fclose(file);
			return line;
		}
		free(line);
	}
	fclose(file);
	return NULL;
}

char * get_memory()
// get memory size
{
	FILE * file;
	file = fopen("/proc/meminfo","rt");
	if (file == NULL)
	{
		return NULL;
	}
	char * line;
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char arg [strlen(line)];
		char value [strlen(line)];
		sscanf(line,"%s %s",arg,value);
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

char * get_kernel()
// get kernel version
{
	system("uname -r > __tmpfile__");	
	char * line;
	line = read_string_from_file("__tmpfile__");
	if (line == NULL)
	{
		return NULL;
	}
	int i = 0;
	while (line[i] != 0)
	{
		if (line[i] == '-')
		{
			line[i] = 0;
			break;
			
		}
		i++;
	}
	system("rm  __tmpfile__");
	return line;
}

/*Cgroup handling*/

void find_cgroup_location()
// find path_to_memory and path_to_cpuacct 
// return 1 in case of success, 0 - can't find cgroup with such controller
{
	const char * path = "/proc/mounts";
	FILE * results;
	results = fopen(path,"rt");
	if (results == NULL)
	{
		exit_res_manager(errno,0,NULL,"Can't open file /proc/mounts");
	}
	char * line = NULL;
	while ((line = read_string_from_opened_file(results)) != NULL)
	{
		char name [strlen(line)];
		char path [strlen(line)];
		char type [strlen(line)];
		char subsystems [strlen(line)];
		sscanf(line,"%s %s %s %s",name,path,type,subsystems);
		if (strcmp(type,"cgroup") == 0 && strstr(subsystems,cpuacct_controller))
		{	
			path_to_cpuacct = (char*)malloc(sizeof(char) * strlen(path + 1));
			if (path_to_cpuacct == NULL)
			{
				exit_res_manager(errno,0,NULL,"Error: Not enough memory");
			}
			strcpy(path_to_cpuacct, path);
		}
		if (strcmp(type,"cgroup") == 0 && strstr(subsystems,memory_controller))
		{	
			path_to_memory = (char*)malloc(sizeof(char) * strlen(path + 1));
			if (path_to_memory == NULL)
			{
				exit_res_manager(errno,0,NULL,"Error: Not enough memory");
			}
			strcpy(path_to_memory, path);
		}
		free(line);
	}
	if (path_to_memory == "")
	{
		exit_res_manager(EACCES,0,NULL,"You need to mount memory cgroup: sudo mount -t cgroup -o memory <name> <path>");
	}
	if (path_to_cpuacct == "")
	{
		exit_res_manager(EACCES,0,NULL,"You need to mount cpuacct cgroup: sudo mount -t cgroup -o cpuacct <name> <path>");
	}
}

void create_cgroup(char * resmanager_dir)
// create cgroups in founded locations with name
// return 1 in case of success, 0 - can't create new directories (permission error)
{
	char * generic_name = itoa (getpid());
	if (resmanager_dir == NULL)
	{
		resmanager_dir = (char *)malloc(sizeof(char) * 1);
		if (resmanager_dir == NULL)
		{
			exit_res_manager(errno,0,NULL,"Error: Not enough memory");
		}
		strcpy(resmanager_dir,"");
	}
	char * tmp_path_to_memory = realloc (path_to_memory, sizeof(char) * (strlen(path_to_memory) + strlen(generic_name) + strlen(resmanager_dir) + strlen(resmanager_modifier) + 3));
	if (tmp_path_to_memory != NULL) 
	{
		path_to_memory = tmp_path_to_memory;
		strcat (path_to_memory, "/");
		strcat (path_to_memory, resmanager_dir);
		strcat (path_to_memory, "/");
		strcat (path_to_memory, resmanager_modifier);
		strcat (path_to_memory, generic_name);
	}
	else
	{
		exit_res_manager(errno,0,NULL,"Error: Not enough memory");
	}
	char * tmp_path_to_cpuacct = realloc (path_to_cpuacct, sizeof(char) * (strlen(path_to_cpuacct) + strlen(generic_name) + strlen(resmanager_dir) + strlen(resmanager_modifier) + 3));
	if (tmp_path_to_cpuacct != NULL) 
	{
		path_to_cpuacct = tmp_path_to_cpuacct;
		strcat (path_to_cpuacct, "/");
		strcat (path_to_cpuacct, resmanager_dir);
		strcat (path_to_cpuacct, "/");
		strcat (path_to_cpuacct, resmanager_modifier);
		strcat (path_to_cpuacct, generic_name);
	}
	else
	{
		exit_res_manager(errno,0,NULL,"Error: Not enough memory");
	}
	free(generic_name);
	
	if (mkdir(path_to_memory,0777) == -1)
	{
		char error_path [strlen(path_to_memory) + 1];
		int i;
		memcpy(error_path,path_to_memory,strlen(path_to_memory));
		for (i=strlen(error_path);i>=0;i--)
		{
			if(error_path[i] == '/')
			{	
				error_path[i] = 0;
				break;
			}
		}
		
		exit_res_manager(errno,0,NULL,concat("Error: you need to change permissions in cgroup directory: sudo chmod o+wt ", error_path));
	}
	is_mem_dir_created = 1;
	if (strcmp(path_to_memory,path_to_cpuacct)!=0)
	{
		if (mkdir(path_to_cpuacct,0777) == -1)
		{
			char error_path [strlen(path_to_cpuacct) + 1];
			int i;
			memcpy(error_path,path_to_cpuacct,strlen(path_to_cpuacct));
			for (i=strlen(error_path);i>=0;i--)
			{
				if(error_path[i] == '/')
				{	
					error_path[i] = 0;
					break;
				}
			}
			exit_res_manager(errno,0,NULL,concat("Error: you need to change permission in cgroup directory: sudo chmod o+wt ", error_path));
			
		}
		is_cpu_dir_created = 1;
	}
}

void set_memlimit()
// set memory limit in cgroup with memory controller
{
	char path_mem [strlen(path_to_memory) + strlen(mem_limit) + 1];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,mem_limit);
	path_mem[strlen(path_mem)] = 0;
	chmod(path_mem,0666);
	write_into_file(path_mem,itoa(memlimit));
	
	char path_memsw [strlen(path_to_memory) + strlen(memsw_limit) + 1];
	strcpy(path_memsw,path_to_memory);
	strcat(path_memsw,memsw_limit); // memory+swap limit
	path_memsw[strlen(path_memsw)] = 0;
	chmod(path_memsw,0666);
	if (write_into_file(path_memsw,itoa(memlimit)) == -1)
	{
		exit_res_manager(ENOENT,0,NULL,"Error: Memory control group doesn't have swap extension\nYou need to set swapaccount=1 as a kernel boot parameter to be able to compute (memory+Swap) usage");
	}
}

void add_task(int pid)
// add pid of created process to tasks file
{
	char path_mem [strlen(path_to_memory) + strlen(tasks_file) + 1];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,tasks_file);
	path_mem[strlen(path_mem)] = 0;
	chmod(path_mem,0666);
	write_into_file(path_mem,itoa(pid));
	if (strcmp(path_to_memory, path_to_cpuacct) != 0)
	{
		char path_cpu [strlen(path_to_cpuacct) + strlen(tasks_file) + 1];
		strcpy(path_cpu,path_to_cpuacct);
		strcat(path_cpu,tasks_file);
		path_cpu[strlen(path_cpu)] = 0;
		chmod(path_cpu,0666);
		write_into_file(path_cpu,itoa(pid));
	}
}

void get_stats(statistics *stats)
// read stats
{
	char path_mem [strlen(path_to_memory) + strlen(memsw_max_usage) + 1];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,memsw_max_usage); // read (memory+swap)
	path_mem[strlen(path_mem)] = 0;
	char * str = read_string_from_file(path_mem);
	if (str == NULL) // most likely there is no memsw in memory cgroup => exit with error in script
	{
		exit_res_manager(errno,ENOENT,NULL,"Error: Memory control group doesn't have swap extension\nYou need to set swapaccount=1 as a kernel boot parameter to be able to compute (memory+Swap) usage");
	}
	(*stats).memory = atol(str);
	free(str);
	
	char path_cpu [strlen(path_to_cpuacct) + strlen(cpu_usage) + 1];
	strcpy(path_cpu,path_to_cpuacct);
	strcat(path_cpu,cpu_usage);
	path_cpu[strlen(path_cpu)] = 0;
	str = read_string_from_file(path_cpu);
	if (str == NULL)
	{
		stats = NULL;
		return;
	}
	(*stats).cpu_time = atof(str) / 10e8;
	free(str);
	
	strcpy(path_cpu,path_to_cpuacct);
	strcat(path_cpu,cpu_stat);
	path_cpu[strlen(path_cpu)] = 0;
	FILE * file;
	file = fopen(path_cpu,"rt");
	if (file == NULL)
	{
		stats = NULL;
		return;
	}
	char * line = read_string_from_opened_file(file);
	if (line == NULL)
	{
		stats = NULL;
		return;
	}
	char arg [strlen(line)];
	char value [strlen(line)];
	sscanf(line,"%s %s",arg,value);
	(*stats).user_time = atof(value) / 10e1;
	free(line);
	
	line = read_string_from_opened_file(file);
	if (str == NULL)
	{
		stats = NULL;
		return;
	}
	sscanf(line,"%s %s",arg,value);
	(*stats).sys_time = atof(value) / 10e1;
	free(line);
	
	fclose(file);
}

int set_cgroup_parameter(char * file_name, char * value)
// set specified parameter into specified file in cgroup.
// Returns -1 in case of error in opening file or 0.
{
	char path [strlen(path_to_memory) + strlen(file_name) + 2];
	strcpy(path,path_to_memory);
	strcat(path,"/");
	strcat(path,file_name);
	path[strlen(path)] = 0;
	chmod(path,0666);
	return write_into_file(path,value);
}

void remove_cgroup()
// delete cgroups
{
	if (is_mem_dir_created)
		rmdir(path_to_memory);
	if (is_cpu_dir_created)
		rmdir(path_to_cpuacct);
}

/*Script functions*/

void print_stats(int exit_code, int signal, statistics *stats, const char * err_mes)
// print stats into file/console
{
	FILE * out;
	if (outputfile == NULL)
	{
		out = stdout;
	}
	else
	{
		out = fopen(outputfile,"w");
		if (out == NULL)
		{
			fprintf(stdout,"Can't create file %s\n",outputfile);
			out = stdout;
		}
	}
	fprintf(out,"Resource manager settings:\n");
	fprintf(out,"\tmemory limit: %ld bytes\n",memlimit);
	fprintf(out,"\ttime limit: %.0f ms\n",timelimit * 1000);
	fprintf(out,"\tcommand: ");
	print_command(out, command);
	fprintf(out,"\tcgroup memory controller: %s\n",path_to_memory);
	fprintf(out,"\tcgroup cpuacct controller: %s\n",path_to_cpuacct);
	fprintf(out,"\toutputfile: %s\n",outputfile);

	fprintf(out,"Resource manager execution status:\n");
	
	if (err_mes != NULL)
		fprintf(out,"\texit code (resource manager): %i (%s)\n",exit_code, err_mes);
	else
		fprintf(out,"\texit code (resource manager): %i\n",exit_code);
	if (signal != 0)
		fprintf(out,"\tkilled by signal (resource manager): %i (%s)\n",signal,strsignal(signal));
	
	if (exit_code == 0 && pid > 0 && stats != NULL) // script finished
	{
		fprintf(out,"Command execution status:\n");
	
		fprintf(out,"\texit code: %i\n",stats->exit_code);
		if (stats->sig_number != 0)
			fprintf(out,"\tkilled by signal: %i (%s)\n",stats->sig_number,strsignal(stats->sig_number));
		if (stats->cpu_time > timelimit)
			fprintf(out,"\ttime exhausted\n");
		else if (stats->memory > memlimit)
			fprintf(out,"\tmemory exhausted\n");
		else fprintf(out,"\tcompleted in limits\n");
	
		fprintf(out,"Time usage statistics:\n");
		fprintf(out,"\twall time: %.0f ms\n",stats->wall_time * 1000);
		fprintf(out,"\tcpu time: %.0f ms\n",stats->cpu_time * 1000);
		fprintf(out,"\tuser time: %.0f ms\n",stats->user_time * 1000);
		fprintf(out,"\tsystem time: %.0f ms\n",stats->sys_time * 1000);
	
		fprintf(out,"Memory usage statistics:\n");
		fprintf(out,"\tpeak memory usage: %ld bytes\n",stats->memory);
		
		/*
		long rss = get_rss();
		long swap = get_swap();
		fprintf(out,"\tpeak rss usage: %ld\n", rss);
		fprintf(out,"\tpeak swap usage: %ld\n", swap);*/
	}
	fprintf(out,"System settings:\n");
	fprintf(out,"\tkernel version: %s\n",get_kernel());
	fprintf(out,"\tcpu %s",get_cpu());
	fprintf(out,"\tmemory: %s bytes\n",get_memory());
	
	if (outputfile != NULL)
		fclose(out);
}

void exit_res_manager(int exit_code, int signal, statistics *stats, const char * err_mes)
{
	if (pid > 0)
		kill_created_processes(SIGKILL);
	if (stats != NULL)
		get_stats(stats);
	print_stats(exit_code, script_signal, stats, err_mes);
	remove_cgroup();
	// close files where stderr/stdout was redirected
	if (fd_stdout != -1)
		close(fd_stdout);
	if (fd_stderr != -1)
		close(fd_stderr);
	exit(exit_code);
}

char * read_config_file(char * configfile)
/*
Config file format:
	<file> <value>
For each <file> will be written <value>
Returns err_mes or NULL in case of success.
*/
{
	FILE * file;
	file = fopen(configfile,"rt");
	if (file == NULL)
	{
		return concat("Can't open config file ", configfile);
	}
	char * line;
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char file_name [strlen(line)];
		char value [strlen(line)];
		sscanf(line,"%s %s",file_name, value);
		if (set_cgroup_parameter(file_name, value) == -1) // error in opening file
		{
			return concat("Can't open file ", file_name);
		}
		free(line);
	}
	fclose(file);
	return NULL;
}

void kill_created_processes(int signum)
{
	// finish created process
	int kill_res;
	kill_res = kill(pid,signum);
	
	// if there are still pids in tasks file => finish them
	char path [strlen(path_to_memory) + 7];
	strcpy(path,path_to_memory);
	strcat(path,"/tasks");
	path[strlen(path)] = 0;
	FILE * results;
	results = fopen(path,"rt");
	if (results == NULL)
		return;
	char * line = NULL;
	while ((line = read_string_from_opened_file(results)) != NULL)
	{
		kill(atoi(line),signum);
		free(line);
	}
}

void terminate(int signum)
{
	script_signal = signum;
	if (pid > 0)
	{
		kill_created_processes(SIGKILL);
	}
	else // signal before starting command
	{
		statistics *stats = (statistics *)malloc(sizeof(statistics));
		if (stats == NULL)
		{
			exit_res_manager(errno,0,NULL,"Error: Not enough memory");
		}
		stats->exit_code = 1;
		stats->sig_number = signum;
		stats->wall_time = 0;
		exit_res_manager(0,signum,stats,NULL);
	}
}

void stop_timer()
{
	if (alarm_time < 1000)
		ualarm (0,0);
	else
		alarm (0);
}

void set_timer()
{
	if (alarm_time < 1000)
		ualarm (alarm_time * 1000,0);
	else
		alarm (alarm_time / 1000);
}

void check_time(int signum)
{
	char path [strlen(path_to_cpuacct) + 15];
	strcpy(path,path_to_cpuacct);
	strcat(path,"/cpuacct.usage");
	path[strlen(path)] = 0;
	char * str = read_string_from_file(path);
	double cpu_time = atof(str) / 10e8;
	free(str);
	if (cpu_time >= timelimit)
	{
		kill_created_processes(SIGKILL);
	}
	else
		set_timer(alarm_time);
}

void redirect(int fd, char * path)
// redirect fd into file path
// for example can repirect stdin == 1 into some file
{
	if (path == NULL)
		return;
	int filedes[2];
	close(fd);
	filedes[0] = fd;
	filedes[1] = creat(path, 0666);
	if (fd == 1)
		
	if (filedes[1] == -1)
		return;
	
	if (dup2(filedes[0],filedes[1]) == -1)
		return;
	if (pipe(filedes) == -1)
		return;
	if (fd == 1)
		fd_stdout = filedes[1];
	if (fd == 2)
		fd_stderr = filedes[1];
}

void print_usage()
{
	printf("Usage: [-h] [options] command [arguments] \n");
	printf("Options:\n");
	printf("\t-h - print help;\n");
	printf("\t-m <number> - set memory limit\n");
	printf("\t\tsupported binary prefixes: Kb, Mb, Gb, Kib, Mib, Gib\n");
	printf("\t\t1Kb = 1000 bytes, 1Mb = 1000^2, 1Gb = 1000^3\n");
	printf("\t\t1Kib = 1024 bytes, 1Mib = 1024^2, 1Gib = 1024^3\n");
	printf("\t\tif there is no binary prefix then size will be specified in bytes\n");
	printf("\t\tdefault value: 100Mb;\n");
	printf("\t-t <number> - set time limit\n");
	printf("\t\tsupported prefixes: ms, min\n");
	printf("\t\t1ms = 0.001 seconds, 1min = 60 seconds\n");
	printf("\t\tif there is no prefix then time specified in seconds\n");
	printf("\t\tdefault value: 1min;\n");
	printf("\t-o <file> - set output file for statistics\n");
	printf("\t\tif option isn't specified then will be used stdout for output statistics;\n");
	printf("\t-l <dir> - specify directory in control groups for resource manager\n");
	printf("\t\tif option isn't specified then will be used control groups directory for resorce manager;\n");
	printf("\t--interval <number> - specify time (in ms) interval in which time limit will be checked\n");
	printf("\t\tdefault value: 1000 (1 second)\n");
	printf("\t--stdout <file> - redirect command stdout into file\n");
	printf("\t\tif option isn't specified then stdout won't be redirected for command;\n");
	printf("\t--stderr <file> - redirect command stderr into file\n");
	printf("\t\tif option isn't specified then stderr won't be redirected for command.\n");
	printf("Description:\n");
	printf("\tResource manager runs specified command with given arguments.\n");
	printf("\tWhile command is running resource manager checks cpu time and memory usage.\n");
	printf("\tIf command uses more cpu time or memory then it will be killed by signal SIGKILL.\n");
	printf("\tWhen command finishes, statistics will be written into the specified file (or to standart output).\n");
	printf("\tIf there were any errors during command execution then it will be finished and statistics will be printed with error code.\n");
	printf("Requirements:\n");
	printf("\tResource manager is using control groups, which require at least kernel 2.6.24 version.\n");
	printf("\tBefore control groups can be used you need to mount temporarily file system by command:\n");
	printf("\t\tsudo mount -t cgroup -o cpuacct,memory <name_of_cgroup> <path_to_cgroup>\n");
	printf("\t\t<name_of_cgroup> - name of control group; this name will be used in /proc/mounts for this file system;\n");
	printf("\t\t<path_to_cgroup> - path to control group location;\n");
	printf("\tNote: you don't need to do this if control groups with controllers cpuacct and memory already has been mounted.\n");
	printf("\tYou can check this in /proc/mounts.\n");
	printf("\tIf you want to work in specified directory inside control groups you need to set parameter -l <dir>.\n");
	printf("\tThen resource manager will use <path_to_cgroup>/<dir> directory.\n");
	printf("\tAlso you may need to change permissions for this directory by command:\n");
	printf("\t\tsudo chmod o+wt <path_to_cgroup>\n");
	printf("\t\tor if parameter -l <dir> was specified\n");
	printf("\t\tsudo chmod o+wt <path_to_cgroup>/<dir>.\n");
	printf("\tFor correct memory computation (memory + swap) you need next flags are set to enable in your kernel:\n");
	printf("\t\tCONFIG_CGROUP_MEM_RES_CTLR_SWAP and CONFIG_CGROUP_MEM_RES_CTLR_SWAP_ENABLED\n");
	printf("\t\tor if kernel 3.6 version\n");
	printf("\t\tCONFIG_MEMCG_SWAP and CONFIG_MEMCG_SWAP_ENABLED/\n");
	printf("\tAlternatively you can set 'swapaccount=1' as a kernel boot parameter.\n");
	printf("\tMinimal kernel version for swap computation is 2.6.34.\n");
	printf("Exit status:\n");
	printf("\tIf there was an error during control group creation (control group is not mounted, wrong permissions, swapaccount=0)\n");
	printf("\tresource manager will return error code and discription of error into output file.\n");
	printf("\tIf there were any errors during command execution or it was interrupted by signal then it will be finished\n");
	printf("\tand statistics will be printed with error code or signal number.\n");
	printf("\tOtherwise return code is 0.\n");
	printf("Output format:\n");
	printf("\tResource manager settings:\n");
	printf("\t\tmemory limit: <number> bytes\n");
	printf("\t\ttime limit: <number> ms\n");
	printf("\t\tcommand: command [arguments]\n");
	printf("\t\tcgroup memory controller: <path to memory control group>\n");
	printf("\t\tcgroup cpuacct controller: <path to cpuacct control group>\n");
	printf("\t\toutputfile: <file>\n");
	printf("\tResource manager execution status:\n");
	printf("\t\texit code (resource manager): <number>\n");
	printf("\t\tkilled by signal (resource manager): <number>\n");
	printf("\tCommand execution status:\n");
	printf("\t\texit code: <number>\n");
	printf("\t\tcompleted in limits / memory exhausted / time exhausted\n");
	printf("\tTime usage statistics:\n");
	printf("\t\twall time: <number> ms\n");
	printf("\t\tcpu time: <number> ms\n");
	printf("\t\tuser time: <number> ms\n");
	printf("\t\tsystem time: <number> ms\n");
	printf("\tMemory usage statistics:\n");
	printf("\t\tpeak memory usage: <number> bytes\n");
	printf("\tSystem settings:\n");
	printf("\t\tkernel version: <version>\n");
	printf("\t\tcpu: <name of cpu>\n");
	printf("\t\tmemory: <max size> bytes\n");
}

int main(int argc, char **argv)
{
	char * stdoutfile = NULL;
	char * stderrfile = NULL;	
	char * resmanager_dir = ""; // path to resource manager directory in control groups
	char * configfile = NULL;
	
	int i;
	int comm_arg = 0;
	int c;
	for (i = 1; i <= 31; i++)
	{
		if (i == SIGSTOP || i == SIGKILL ||i == SIGCHLD || i == SIGUSR1 || i == SIGUSR2 || i == SIGALRM)
			continue;
		if (signal(i,terminate) == SIG_ERR)
		{
			exit_res_manager(errno,0,NULL,"Cannot set signal handler");
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
	
	while ((c = getopt_long(argc, argv, "-hm:t:o:kl:0", long_options, &option_index)) != -1)
	{
		switch(c)
		{
		case 'h':
			print_usage();
			exit(0);
		case 'i':
			if (!is_number(optarg))
			{
				exit_res_manager(EINVAL,0,NULL,"Expected integer number in ms for --interval");
			}
			alarm_time = atoi(optarg);
			break;
		case 'c':
			configfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			if (configfile == NULL)
			{
				exit_res_manager(errno,0,NULL,"Error: Not enough memory");
			}
			strcpy(configfile,optarg);
			break;
		case 's':
			stdoutfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			if (stdoutfile == NULL)
			{
				exit_res_manager(errno,0,NULL,"Error: Not enough memory");
			}
			strcpy(stdoutfile,optarg);
			break;
		case 'e':
			stderrfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			if (stderrfile == NULL)
			{
				exit_res_manager(errno,0,NULL,"Error: Not enough memory");
			}
			strcpy(stderrfile,optarg);
			break;
		case 'k':
			// nothing
			break;
		case 'l':
			resmanager_dir = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			if (resmanager_dir == NULL)
			{
				exit_res_manager(errno,0,NULL,"Error: Not enough memory");
			}
			strcpy(resmanager_dir,optarg);
			break;
		case 'm':
			memlimit = atol(optarg);
			if (strstr(optarg, "Kb") != NULL)
			{
				memlimit *= 1000;
			}
			else if (strstr(optarg, "Mb") != NULL)
			{
				memlimit *= 1000 * 1000;
			}
			else if (strstr(optarg, "Gb") != NULL)
			{
				memlimit *= 1000;
				memlimit *= 1000;
				memlimit *= 1000;
			}
			else if (strstr(optarg, "Kib") != NULL)
			{
				memlimit *= 1024;
			}
			else if (strstr(optarg, "Mib") != NULL)
			{
				memlimit *= 1024 * 1024;
			}
			else if (strstr(optarg, "Gib") != NULL)
			{
				memlimit *= 1024;
				memlimit *= 1024;
				memlimit *= 1024;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL,0,NULL,"Expected integer number with Kb|Mb|Gb|Kib|Mib|Gib| modifiers in -m");
			}
			break;
		case 't':
			timelimit = atof(optarg);
			if (strstr(optarg, "ms") != NULL)
			{
				timelimit /= 1000;
			}
			else if (strstr(optarg, "min") != NULL)
			{
				timelimit *= 60;
			}
			else if (!is_number(optarg))
			{
				exit_res_manager(EINVAL,0,NULL,"Expected number with ms|min| modifiers in -t");
			}
			break;
		case 'o':
			outputfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
			if (outputfile == NULL)
			{
				exit_res_manager(errno,0,NULL,"Error: Not enough memory");
			}
			strcpy(outputfile,optarg);
			break;
		default:
			// finish parsing optional parameters
			goto exit_parser;
		}
	}
	
	exit_res_manager(EINVAL,0,NULL,"Empty command");
	
	exit_parser:;
	optind--; // optind - index of first argument in command; we need index of command
	command = (char **) malloc (sizeof(char*) * (argc - optind + 1));
	if (command == NULL)
	{
		exit_res_manager(errno,0,NULL,"Error: Not enough memory");
	}
	for (i = 0; i < argc - optind; i++)
	{
		command[i] = argv[optind + i];
		comm_arg++;
	}
	command[comm_arg] = NULL;

	find_cgroup_location(); // check if there are cgroups with cpuacct and memory controller and get their directories
	create_cgroup(resmanager_dir); // create new cgroups in found directories
	set_memlimit(); // set memory limit in cgroup with memory controller
	
	if (configfile != NULL) // configfile was specified
	{
		char * err_mes = read_config_file(configfile);
		if (err_mes != NULL)
			exit_res_manager(ENOENT,0,NULL,err_mes);
	}
	
	if (signal(SIGALRM,check_time) == SIG_ERR)
	{
		exit_res_manager(errno,0,NULL,"Cannot set signal handler");
	}
	
	set_timer(alarm_time);
	
	double time_before = gettime();
	pid = fork();
	if (pid == 0)
	{
		redirect(1, stdoutfile);
		redirect(2, stderrfile);
		add_task(getpid());
		execvp(command[0],command);
		exit(errno);
	}
	else if (pid == -1)
	{
		exit_res_manager(errno,0,NULL,"Cannot create a new process");
	}
	
	int status;
	int wait_res;
	wait_res = wait4(pid,&status,0,NULL);
	int wait_errno = errno;
	if (wait_res == -1)
	{
		if (wait_errno != EINTR)
			exit_res_manager(errno,0,NULL,"Error: Not enough memory");
	}
	double time_after = gettime();
	
	stop_timer(alarm_time);
	
	statistics *stats = (statistics *)malloc(sizeof(statistics));
	if (stats == NULL)
	{
		exit_res_manager(errno,0,NULL,"Error in wait");
	}
	stats->wall_time = time_after - time_before;
	if (wait_errno == EINTR)
	{
		stats->exit_code = 0;
		stats->sig_number = SIGKILL;
	}
	else
	{
		stats->exit_code = WEXITSTATUS(status);
		if (WIFSIGNALED(status))
			stats->sig_number = WTERMSIG(status);
		else 
			stats->sig_number = 0;
	}
	get_stats(stats);
	exit_res_manager(0, 0, stats, NULL);
	
	return 0;
}

