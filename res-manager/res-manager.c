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

typedef struct parameters
{
	
} parameters;


double timelimit = STANDART_TIMELIMIT; // in seconds
long memlimit = STANDART_MEMLIMIT; // in bytes
int kill_at_once = 0;
char * outputfile;
char * stdoutfile = NULL;
char * stderrfile = NULL;
char ** command = NULL;
int alarm_time = 1000; // time in ms
char * resmanager_dir = ""; // path to resource manager directory in control groups
int script_signal = 0;

// cgroup parameters
char * path_to_memory = "";
char * path_to_cpuacct = "";

const char * resmanager_modifier = "resource_manager_"; // modifier to the names of resource manager cgroups

// command line parameters
int fd_stdout, fd_stderr;
//errors processing
int is_mem_dir_created = 0;
int is_cpu_dir_created = 0;
int pid = 0; // pid of child process
int is_command_started = 0;

void get_stats(statistics *stats);
void kill_created_processes(int signum);

long get_rss();
long get_swap();

statistics * parse_outputfile(const char * file);

void print_command(FILE * file, char ** command)
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
	
	if (exit_code == 0 && is_command_started && stats != NULL) // script finished
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
	
	if (outputfile != NULL)
		fclose(out);
}

void remove_cgroup()
// delete cgroups 
{
	if (is_mem_dir_created)
		rmdir(path_to_memory);
	if (is_cpu_dir_created)
		rmdir(path_to_cpuacct);
}

void exit_res_manager(int exit_code, int signal, statistics *stats, const char * err_mes)
{
	if (pid > 0)
		kill_created_processes(SIGKILL);
	if (stats != NULL)
		get_stats(stats);
	print_stats(exit_code, script_signal, stats, err_mes);
	remove_cgroup();
	/*
	statistics *new_st = parse_outputfile(outputfile);
	outputfile = NULL;
	print_stats(0, 0, new_st, err_mes);
	*/
	close(fd_stdout);
	close(fd_stderr);
	exit(exit_code);
}

char * read_string_from_opened_file(FILE * file)
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
{
	FILE * file;
	file = fopen(path,"rt");
	if (file == NULL)
		return NULL;
	char * line = read_string_from_opened_file(file);
	fclose(file);
	return line;
}

int get_num(long num)
{
	int ret = 1;
	long count = num;
	while ((count = count/10) > 0) ret++;
	return ret;
}

int write_int_to_file(const char * path,const char * number)
{
	FILE * file;
	file = fopen(path,"a+");
	if (file == NULL)
		return -1;
	fputs(number, file);
	fclose(file);
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

void print_usage()
{
	printf("Usage: [-h] [options] command [arguments] \n");
	printf("\t-h print usage\n");
	printf("\t-m <size>Kb|Mb|Gb|Kib|Mib|Gib| - set memlimit=size\n");
	printf("\t-t <number>ms|min| - set timelimit=number\n");
	printf("\t-o <outputfile> - set output file\n");
	printf("\t-l <dir> - specify directory in control groups for resource manager\n");
	printf("\t--interval <time> - specify time (ms) interval in which timelimit will be checked\n");
	printf("\t--stdout <file> - redirect command stdout into file\n");
	printf("\t--stderr <file> - redirect command stderr into file\n");
}

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
		if (strcmp(type,"cgroup") == 0 && strstr(subsystems,"cpuacct"))
		{	
			path_to_cpuacct = (char*)malloc(sizeof(char) * strlen(path + 1));
			if (path_to_cpuacct == NULL)
			{
				exit_res_manager(errno,0,NULL,"Error: Not enough memory");
			}
			strcpy(path_to_cpuacct, path);
		}
		if (strcmp(type,"cgroup") == 0 && strstr(subsystems,"memory"))
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

char * concat(char * str1, char * str2)
{
	char tmp[strlen(str1) + strlen(str2) + 1];
	strcpy(tmp,str1);
	strcat(tmp,str2);
	return strdup(tmp);
}


void create_cgroup()
// create cgroups in founded locations with name
// return 1 in case of success, 0 - can't create new directories (permission error)
{
	//remove_cgroup();
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

void set_permissions()
// set permissions into tasks file
{
	char path_mem [strlen(path_to_memory) + 7];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,"/tasks");
	path_mem[strlen(path_mem)] = 0;
	chmod(path_mem,0777);
	
	char path_cpu [strlen(path_to_cpuacct) + 7];
	strcpy(path_cpu,path_to_cpuacct);
	strcat(path_cpu,"/tasks");
	path_cpu[strlen(path_cpu)] = 0;
	chmod(path_cpu,0777);
}

void set_memlimit()
// set memlimit
{
	char path [strlen(path_to_memory) + 35];
	strcpy(path,path_to_memory);
	strcat(path,"/memory.limit_in_bytes"); // memory limit
	path[strlen(path)] = 0;
	chmod(path,0777);
	write_int_to_file(path,itoa(memlimit));
	
	strcpy(path,path_to_memory);
	strcat(path,"/memory.memsw.limit_in_bytes"); // memory+swap limit
	path[strlen(path)] = 0;
	chmod(path,0777);
	if (write_int_to_file(path,itoa(memlimit)) == -1)
	{
		exit_res_manager(errno,ENOENT,NULL,"Error: Memory control group doesn't have swap extension\nYou need to set swapaccount=1 as a kernel boot parameter to be able to compute (memory+Swap) usage");
	}
	
	// set parameter swappiness in memory cgroup, default=60, values: 0-100
	/*
	strcpy(path,path_to_memory);
	strcat(path,"/memory.swappiness");
	path[strlen(path)] = 0;
	chmod(path,0777);
	write_int_to_file(path,"60");*/
}

void add_task(int pid)
// add task to tasks file
{
	char path_mem [strlen(path_to_memory) + 7];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,"/tasks");
	path_mem[strlen(path_mem)] = 0;
	write_int_to_file(path_mem,itoa(pid));
	
	char path_cpu [strlen(path_to_cpuacct) + 7];
	strcpy(path_cpu,path_to_cpuacct);
	strcat(path_cpu,"/tasks");
	path_cpu[strlen(path_cpu)] = 0;
	write_int_to_file(path_cpu,itoa(pid));
}

void get_stats(statistics *stats)
// read stats
{
	char path_mem [strlen(path_to_memory) + 35];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,"/memory.memsw.max_usage_in_bytes"); // read (memory+swap)
	path_mem[strlen(path_mem)] = 0;
	char * str = read_string_from_file(path_mem);
	if (str == NULL) // most likely there is no memsw in memory cgroup => exit with error in script
	{
		exit_res_manager(errno,ENOENT,NULL,"Error: Memory control group doesn't have swap extension\nYou need to set swapaccount=1 as a kernel boot parameter to be able to compute (memory+Swap) usage");
	}
	(*stats).memory = atol(str);
	free(str);
	
	char path_cpu [strlen(path_to_cpuacct) + 15];
	strcpy(path_cpu,path_to_cpuacct);
	strcat(path_cpu,"/cpuacct.usage");
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
	strcat(path_cpu,"/cpuacct.stat");
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

long get_rss()
{
	char path_mem [strlen(path_to_memory) + 35];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,"/memory.max_usage_in_bytes");
	path_mem[strlen(path_mem)] = 0;
	char * str = read_string_from_file(path_mem);
	if (str == NULL)
	{
		return 0;
	}
	return atol(str);
}

long get_swap()
{
	char path_mem [strlen(path_to_memory) + 35];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,"/memory.stat");
	path_mem[strlen(path_mem)] = 0;
	FILE * file;
	file = fopen(path_mem,"rt");
	if (file == NULL)
	{
		return 0;
	}
	char * line;
	while ((line = read_string_from_opened_file(file)) != NULL)
	{
		char arg [strlen(line)];
		char value [strlen(line)];
		sscanf(line,"%s %s",arg,value);
		printf("%s %s\n",line , value);
		if (strcmp(arg, "total_swap") == 0)
		{
			fclose(file);
			return atol(value);
		}
		free(line);
	}
	fclose(file);
	return 0;
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
	if (is_command_started)
	{
		kill_created_processes(SIGKILL);
	}
	else // signal before starting command
	{
		if (pid > 0)
			kill_created_processes(SIGKILL);
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
{
	if (path == NULL)
		return;
	int filedes[2];
	close(fd);
	filedes[0] = fd;
	filedes[1] = creat(path, 0777);
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

double gettime()
{
	struct timeval time;
	gettimeofday(&time, NULL);
	return time.tv_sec + time.tv_usec / 1000000.0;
}

int is_number(char * str)
//return true, if str is number
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

statistics * parse_outputfile(const char * file)
// parser for current output file
{
	statistics *stats = (statistics*)malloc(sizeof(statistics));
	FILE * results;
	results = fopen(file,"r");
	if (results == NULL)
	{
		fprintf(stderr,"Failed to parse output file: %s\n",file);
		return NULL;
	}
	
	char arg [STR_LEN];
	char value [STR_LEN];
	char tmp [STR_LEN];
	int i;
	char * line;
	
	int exit_code = 0;
	int sig_number = 0;
	
	// passing command options section
	for (i = 0; i < 8; i++)
	{
		line = read_string_from_opened_file(results);

	}
	line = read_string_from_opened_file(results); // res_manager exit_code
	
	sscanf(line,"%s %s %s %s %s",arg,tmp,tmp,tmp,value);
	exit_code = atoi(value);
	
	line = read_string_from_opened_file(results); // res_manager signal - optional
	sscanf(line,"%s",arg);
	if (strcmp(arg,"killed") == 0)
	{
		sscanf(line,"%s %s %s %s %s %s",arg,tmp,tmp,tmp,tmp,value);
		sig_number = atoi(value);
		line = read_string_from_opened_file(results);
	}
	// passing header "Command execution status:"
	
	line = read_string_from_opened_file(results); // command exit_code
	if (line != NULL)
	{
		sscanf(line,"%s %s %s",arg,tmp,value);
		stats->exit_code = atoi(value);
	
		line = read_string_from_opened_file(results); // command signal - optional
		sscanf(line,"%s",arg);
		if (strcmp(arg,"killed") == 0)
		{
			sscanf(line,"%s %s %s %s",arg,tmp,tmp,value);
			stats->sig_number = atoi(value);
			line = read_string_from_opened_file(results);
		}
		else
			stats->sig_number = 0;

	//	line = read_string_from_opened_file(results); // exhausted
		sscanf(line,"%s",arg);
		if (strcmp(arg,"time") == 0)
			stats->time_exhausted = 1;
		else
			stats->time_exhausted = 0;
		if (strcmp(arg,"memory") == 0)
			stats->memory_exhausted = 1;
		else
			stats->memory_exhausted = 0;
		read_string_from_opened_file(results); // passing header "Time usage statistics:"
		for (i = 0; i < 4; i++) // process 4 parameters
		{
			line = read_string_from_opened_file(results);
			sscanf(line,"%s %s %s",arg,tmp,value);
			if (strcmp(arg,"wall") == 0)
				stats->wall_time = atof(value) / 1000;
			if (strcmp(arg,"cpu") == 0)
				stats->cpu_time = atof(value) / 1000;
			if (strcmp(arg,"user") == 0)
				stats->user_time = atof(value) / 1000;
			if (strcmp(arg,"system") == 0)
				stats->sys_time = atof(value) / 1000;
		}
	
		read_string_from_opened_file(results); // passing header "Memory usage statistics:" 
		line = read_string_from_opened_file(results);
		sscanf(line,"%s %s %s %s",tmp,arg,tmp,value);
		if (strcmp(arg,"memory") == 0)
			stats->memory = atol(value);
	
	}
	fclose(results);
	
	
	printf("script exit_code = %i\n",exit_code);
	printf("script signal = %i\n",sig_number);
	
	return stats;
}

int main(int argc, char **argv)
{
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
			kill_at_once = 1;
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

	find_cgroup_location();
	create_cgroup();
	set_permissions();
	set_memlimit();
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
	
	is_command_started = 1;
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

