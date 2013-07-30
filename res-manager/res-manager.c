#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>

#define STR_LEN 80
#define STANDART_TIMELIMIT 900
#define STANDART_MEMLIMIT 100 * 1024 * 1024

typedef struct statistics
{
	int exit_code;
	int memory_exhausted;
	int time_exhausted;
	long memlimit;
	double timelimit;
	double wall_time;
	double cpu_time;
	double user_time;
	double sys_time;
	long memory;
} statistics;

int pid;

char path_to_memory[STR_LEN];
char path_to_cpuacct[STR_LEN];

double timelimit = STANDART_TIMELIMIT; // in seconds
long memlimit = STANDART_MEMLIMIT; // in bytes

char * read_string_from_file(const char * path)
{
	FILE * file;
	file = fopen(path,"rt");
	if (file == NULL)
		return NULL;
	char line [STR_LEN];
	fgets(line, STR_LEN, file);
	fclose(file);
	return strdup(line);
}

int get_num(int num)
{
	int ret = 1;
	int count = num;
	while ((count = count/10) > 0) ret++;
	return ret;
}

int write_int_to_file(const char * path,const char * number)
{
	char com [STR_LEN];
	strcpy(com,"echo ");
	strcat(com,number);
	strcat(com," > ");
	strcat(com,path);
	com[strlen(com)] = 0;
	system(com);
}

char * itoa(int num)
{
	int number_of_chars = get_num(num);
	char * str = (char *) malloc (sizeof(char *) * (number_of_chars + 1));
	int i;
	int count = num;
	for (i = number_of_chars - 1; i >= 0; i--)
	{
		str[i] = count%10 + '0';
		count = count / 10;
	}
	str[number_of_chars] = 0;
	return str;
}

void print_help()
{
	fprintf(stderr,"Usage: [-h] [-m <size>] [-t <number>] command [arguments] ...\n\t");
	fprintf(stderr,"-m <size>Kb|Mb|b| - set memlimit=size\n\t");
	fprintf(stderr,"-t <number>ms|s|min| - set timelimit=size\n");
}

int find_cgroup_location()
// find path_to_memory and path_to_cpuacct 
// return 1 in case of success, 0 - can't find cgroup with such controller
{
	char path [STR_LEN];
	strcpy(path,"/proc/mounts");
	path[strlen(path)] = 0;
	FILE * results;
	results = fopen(path,"rt");
	if (results == NULL)
		return 1;
	char line [2*STR_LEN];
	while (fgets(line, 2*STR_LEN, results) != NULL)
	{
		char name [STR_LEN];
		char path [STR_LEN];
		char type [STR_LEN];
		char subsystems [STR_LEN];
		sscanf(line,"%s %s %s %s",name,path,type,subsystems);
		if (strcmp(type,"cgroup") == 0 && strstr(subsystems,"cpuacct"))
			strcpy(path_to_cpuacct, path);	
		if (strcmp(type,"cgroup") == 0 && strstr(subsystems,"memory"))
			strcpy(path_to_memory, path);
	}
	if (path_to_memory[0] == 0)
	{
		fprintf(stderr,"You need to mount memory cgroup: sudo mount -t cgroup -o memory <name> <path>\n");
		return 1;
	}
	if (path_to_cpuacct[0] == 0)
	{
		fprintf(stderr,"You need to mount cpuacct cgroup: sudo mount -t cgroup -o cpuacct <name> <path>\n");
		return 1;
	}
	return 0;
}

void remove_cgroup()
// try to delete cgroups 
{
	rmdir(path_to_memory);
	rmdir(path_to_cpuacct);
}

int create_cgroup()
// create cgroups in founded locations with name
// return 1 in case of success, 0 - can't create new directories (permission error)
{
	remove_cgroup();
	char * generic_name = itoa (getpid() * getppid());
	strcat (path_to_memory, "/");
	strcat (path_to_memory, generic_name);
	strcat (path_to_cpuacct, "/");
	strcat (path_to_cpuacct, generic_name);
	if (mkdir(path_to_memory,0777) == -1)
	{
		char error_path [STR_LEN];
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
		fprintf(stderr,"Can't create directory %s - you need to change permissions: sudo chmod o+wt %s\n",path_to_memory,error_path);
		return -1;
	}
	if (strcmp(path_to_memory,path_to_cpuacct)!=0)
		if (mkdir(path_to_cpuacct,0777) == -1)
		{
			char error_path [STR_LEN];
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
			fprintf(stderr,"Can't create directory %s - you need to change permissions: sudo chmod o+wt %s\n",
					path_to_cpuacct,error_path);
			return -1;
		}
	return 0;
}

void set_permissions()
// set permissions into tasks file
{
	char path [STR_LEN];
	strcpy(path,path_to_memory);
	strcat(path,"/tasks");
	path[strlen(path)] = 0;
	chmod(path,0777);
	strcpy(path,path_to_cpuacct);
	strcat(path,"/tasks");
	path[strlen(path)] = 0;
	chmod(path,0777);
}

void set_memlimit()
// set memlimit
{
	char path [STR_LEN];
	strcpy(path,path_to_memory);
	strcat(path,"/memory.limit_in_bytes");
	path[strlen(path)] = 0;
	chmod(path,0777);
	write_int_to_file(path,itoa(memlimit));
}

void add_task(int pid)
// add task to tasks file
{
	char path [STR_LEN];
	strcpy(path,path_to_memory);
	strcat(path,"/tasks");
	path[strlen(path)] = 0;
	write_int_to_file(path,itoa(pid));
	strcpy(path,path_to_cpuacct);
	strcat(path,"/tasks");
	path[strlen(path)] = 0;
	write_int_to_file(path,itoa(pid));
}

void get_stats(statistics *stats)
// read stats
{
	char path [STR_LEN];
	strcpy(path,path_to_cpuacct);
	strcat(path,"/cpuacct.usage");
	path[strlen(path)] = 0;
	
	(*stats).cpu_time = atof(read_string_from_file(path)) / 10e8;
	strcpy(path,path_to_memory);
	strcat(path,"/memory.max_usage_in_bytes");
	path[strlen(path)] = 0;
	(*stats).memory = atoi(read_string_from_file(path));
	
	strcpy(path,path_to_cpuacct);
	strcat(path,"/cpuacct.stat");
	path[strlen(path)] = 0;
	FILE * file;
	file = fopen(path,"rt");
	if (file == NULL)
		return;
	char line [STR_LEN];
	fgets(line, STR_LEN, file);
	char arg [STR_LEN];
	char value [STR_LEN];
	sscanf(line,"%s %s",arg,value);
	(*stats).user_time = atof(value) / 10e1;
	fgets(line, STR_LEN, file);
	sscanf(line,"%s %s",arg,value);
	(*stats).sys_time = atof(value) / 10e1;
	fclose(file);
}

void kill_created_processes()
{
	// read pids from tasks; 
	// for each pid kill (pid,SIGKILL);
	
	char path [STR_LEN];
	strcpy(path,path_to_memory);
	strcat(path,"/tasks");
	path[strlen(path)] = 0;
	FILE * results;
	results = fopen(path,"rt");
	if (results == NULL)
		return;
	char line [STR_LEN];
	while (fgets(line, STR_LEN, results) != NULL)
	{
		kill(atoi(line),SIGKILL);
	}
	//kill(pid,SIGKILL);
}

void terminate(int signum)
{
	kill_created_processes();
}

void check_time(int signum)
{
	char path [STR_LEN];
	strcpy(path,path_to_cpuacct);
	strcat(path,"/cpuacct.usage");
	path[strlen(path)] = 0;
	double cpu_time = atof(read_string_from_file(path)) / 10e8;
	if (cpu_time >= timelimit)
	{
		kill_created_processes();
	}
	else alarm(1);
}

void print_command(FILE * file, char ** command)
{
	int i = 0;
	while (command[i] != NULL)
	{
		fprintf(file, "%s ",command[i]);
		i++;
	}
	fprintf(file,"\n");
}

void print_stats(char * file, statistics stats,char ** command)
// print stats into file/console
{
	FILE * out;
	if (file[0] == '\0')
	{
		out = stdout;
	}
	else
	{
		out = fopen(file,"w");
		if (out == NULL)
		{
			fprintf(stderr,"Can't create file %s\n",file);
			out = stdout;
		}
	}
	
	fprintf(out,"Execution status:\n");
	fprintf(out,"\tcommand: ");
	print_command(out, command);
	if (stats.exit_code >= 0)
		fprintf(out,"\texit code: %i\n",stats.exit_code);
	else
		fprintf(out,"\tsignal number: %i\n",-stats.exit_code);
	if (stats.cpu_time > timelimit)
		fprintf(out,"\ttime exhausted\n");
	else if (stats.memory > memlimit)
		fprintf(out,"\tmemory exhausted\n");
	else fprintf(out,"\tresourses not exhausted\n");
	
	fprintf(out,"Resources limits:\n");
	fprintf(out,"\tmemory limit: %ld bytes\n",memlimit);
	fprintf(out,"\ttime limit: %f seconds\n",timelimit);
	
	fprintf(out,"Time statistics:\n");
	fprintf(out,"\twall time: %f seconds\n",stats.wall_time);
	fprintf(out,"\tcpu time: %f seconds\n",stats.cpu_time);
	fprintf(out,"\tuser time: %f seconds\n",stats.user_time);
	fprintf(out,"\tsystem time: %f seconds\n",stats.sys_time);
	
	fprintf(out,"Memory statistics:\n");
	fprintf(out,"\tpeak memory usage: %d bytes\n",stats.memory);
	
	if (file[0] != '\0')
		fclose(out);
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

int main(int argc, char **argv)
{
	char outputfile [STR_LEN];
	outputfile[0] = '\0';
	char ** command;
	int i;
	int comm_arg = 0;
	int c;
	while ((c = getopt(argc, argv, "-m:t:o:")) != -1)
	{
		switch(c)
		{
		case 'm':
			memlimit = atoi(optarg);
			if (strstr(optarg, "Kb") != NULL)
			{
				memlimit *= 1024;
			}
			else if (strstr(optarg, "Mb") != NULL)
			{
				memlimit *= 1024 * 1024;
			}
			else if (strstr(optarg, "Gb") != NULL)
			{
				memlimit *= 1024 * 1024 * 1024;
			}
			else if (!is_number(optarg))
			{
				fprintf (stderr,"Expected integer number with Kb|Mb|Gb| modifiers, got %s\n",optarg);
				print_help();
				exit(1);
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
				fprintf (stderr,"Expected number with ms|min| modifiers, got %s\n",optarg);
				print_help();
				exit(1);
			}
			break;
		case 'o':
			strcpy(outputfile,optarg);
			break;
		default:
			// finish parsing optional parameters
			goto exit_parser;
		}
	}
	
	fprintf (stderr,"Empty command\n");
	print_help();
	exit(1);
	
	exit_parser:;
	optind--; // optind - index of first argument in command; we need index of command
	command = (char **) malloc (sizeof(char*) * (argc - optind + 1));
	for (i = 0; i < argc - optind; i++)
	{
		command[i] = argv[optind + i];
		comm_arg++;
	}
	command[comm_arg] = NULL;

	if (comm_arg == 0)
	{
		fprintf (stderr,"Empty command\n");
		print_help();
		exit(1);
	}

	if (find_cgroup_location() != 0)
		exit(2);
	if (create_cgroup() != 0)
		exit(3);
	set_permissions();
	set_memlimit();
	signal(SIGALRM,check_time);
	signal(SIGINT,terminate);
	signal(SIGTERM,terminate);
	alarm(1);
	double time_before = gettime();
	//int pid = 0;
	pid = fork();
	if (pid == 0)
	{
		add_task(getpid());
		execvp(command[0],command);
		fprintf(stderr,"Can't execute command: ");
		print_command(stderr,command);
		exit(4);
	}
	int status;
	wait4(pid,&status,0,NULL);
	double time_after = gettime();
	alarm(0);
	if (WIFEXITED(status) && WEXITSTATUS(status) || WIFSIGNALED(status))
	{
		kill_created_processes();
	}
	statistics stats;
	if (WIFEXITED(status))
		stats.exit_code = WEXITSTATUS(status);
	else
		stats.exit_code = -WTERMSIG(status);
	stats.wall_time = time_after - time_before;
	get_stats(&stats);
	print_stats(outputfile,stats,command);
	remove_cgroup();
	return 0;
}

