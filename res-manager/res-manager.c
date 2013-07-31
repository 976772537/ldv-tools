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

char * path_to_memory = NULL;
char * path_to_cpuacct = NULL;

double timelimit = STANDART_TIMELIMIT; // in seconds
long memlimit = STANDART_MEMLIMIT; // in bytes

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
		char part_of_line [STR_LEN];
		fgets(part_of_line, STR_LEN, file);
		if (tmp_line != NULL)
		{
			line = tmp_line;
			strcat(line, part_of_line);
		}
		else
		{
			fprintf(stderr, "Error: Not enough memory\n");
			exit(10);
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
	char com [strlen(path) + strlen(number) + 9];
	strcpy(com,"echo ");
	strcat(com,number);
	strcat(com," > ");
	strcat(com,path);
	com[strlen(com)] = 0;
	system(com);
}

char * itoa(long num)
{
	int number_of_chars = get_num(num);
	char * str = (char *) malloc (sizeof(char *) * (number_of_chars + 1));
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
	const char * path = "/proc/mounts";
	FILE * results;
	results = fopen(path,"rt");
	if (results == NULL)
	{
		fprintf(stderr,"Can't open file /proc/mounts\n");
		return 1;
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
			strcpy(path_to_cpuacct, path);
		}
		if (strcmp(type,"cgroup") == 0 && strstr(subsystems,"memory"))
		{	
			path_to_memory = (char*)malloc(sizeof(char) * strlen(path + 1));
			strcpy(path_to_memory, path);
		}
		free(line);
	}
	if (path_to_memory == NULL)
	{
		fprintf(stderr,"You need to mount memory cgroup: sudo mount -t cgroup -o memory <name> <path>\n");
		return 1;
	}
	if (path_to_cpuacct == NULL)
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
	char * tmp_path_to_memory = realloc (path_to_memory, sizeof(char) * (strlen(path_to_memory) + strlen(generic_name) + 2));
	if (tmp_path_to_memory != NULL) 
	{
		path_to_memory = tmp_path_to_memory;
		strcat (path_to_memory, "/");
		strcat (path_to_memory, generic_name);
	}
	else
	{
		fprintf(stderr, "Error: Not enough memory\n");
	}
	char * tmp_path_to_cpuacct = realloc (path_to_cpuacct, sizeof(char) * (strlen(path_to_cpuacct) + strlen(generic_name) + 2));
	if (tmp_path_to_cpuacct != NULL) 
	{
		path_to_cpuacct = tmp_path_to_cpuacct;
		strcat (path_to_cpuacct, "/");
		strcat (path_to_cpuacct, generic_name);
	}
	else
	{
		fprintf(stderr, "Error: Not enough memory\n");
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
		fprintf(stderr,"Can't create directory %s - you need to change permissions: sudo chmod o+wt %s\n",path_to_memory,error_path);
		return -1;
	}
	if (strcmp(path_to_memory,path_to_cpuacct)!=0)
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
			fprintf(stderr,"Can't create directory %s - you need to change permissions: sudo chmod o+wt %s\n",
					path_to_cpuacct,error_path);
			return -1;
		}
	return 0;
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
	char path [strlen(path_to_memory) + 23];
	strcpy(path,path_to_memory);
	strcat(path,"/memory.limit_in_bytes");
	path[strlen(path)] = 0;
	chmod(path,0777);
	write_int_to_file(path,itoa(memlimit));
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
	char path_mem [strlen(path_to_memory) + 27];
	strcpy(path_mem,path_to_memory);
	strcat(path_mem,"/memory.max_usage_in_bytes");
	path_mem[strlen(path_mem)] = 0;
	char * str = read_string_from_file(path_mem);
	(*stats).memory = atol(str);
	free(str);
	
	char path_cpu [strlen(path_to_cpuacct) + 15];
	strcpy(path_cpu,path_to_cpuacct);
	strcat(path_cpu,"/cpuacct.usage");
	path_cpu[strlen(path_cpu)] = 0;
	str = read_string_from_file(path_cpu);
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
	
	char arg [strlen(line)];
	char value [strlen(line)];
	sscanf(line,"%s %s",arg,value);
	(*stats).user_time = atof(value) / 10e1;
	free(line);
	
	line = read_string_from_opened_file(file);
	sscanf(line,"%s %s",arg,value);
	(*stats).sys_time = atof(value) / 10e1;
	free(line);
	
	fclose(file);
}

void kill_created_processes(int signum)
{
	// read pids from tasks; 
	// for each pid kill (pid,SIGKILL);
	
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
	//kill(pid,signum);
}

void terminate(int signum)
{
	kill_created_processes(signum);
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
		kill_created_processes(signum);
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
	if (file == NULL)
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
		fprintf(out,"\tkilled by signal: %i (%s)\n",-stats.exit_code,strsignal(-stats.exit_code));
	if (stats.cpu_time > timelimit)
		fprintf(out,"\ttime exhausted\n");
	else if (stats.memory > memlimit)
		fprintf(out,"\tmemory exhausted\n");
	else fprintf(out,"\tcompleted in limits\n");
	
	fprintf(out,"Resource limits:\n");
	fprintf(out,"\tmemory limit: %ld bytes\n",memlimit);
	fprintf(out,"\ttime limit: %.3f seconds\n",timelimit);
	
	fprintf(out,"Time usage statistics:\n");
	fprintf(out,"\twall time: %.3f seconds\n",stats.wall_time);
	fprintf(out,"\tcpu time: %.3f seconds\n",stats.cpu_time);
	fprintf(out,"\tuser time: %.3f seconds\n",stats.user_time);
	fprintf(out,"\tsystem time: %.3f seconds\n",stats.sys_time);
	
	fprintf(out,"Memory usage statistics:\n");
	fprintf(out,"\tpeak memory usage: %d bytes\n",stats.memory);
	
	if (file != NULL)
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
	char * outputfile;
	char ** command;
	int i;
	int comm_arg = 0;
	int c;
	while ((c = getopt(argc, argv, "-m:t:o:")) != -1)
	{
		switch(c)
		{
		case 'm':
			memlimit = atol(optarg);
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
				memlimit *= 1024;
				memlimit *= 1024;
				memlimit *= 1024;
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
			outputfile = (char *)malloc(sizeof(char) * (strlen(optarg) + 1));
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
	signal(SIGABRT,terminate);
	signal(SIGHUP,terminate);
	signal(SIGQUIT,terminate);
	
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
		kill_created_processes(SIGKILL);
	}
	statistics stats;
	if (WIFEXITED(status))
		stats.exit_code = WEXITSTATUS(status);
	else
		stats.exit_code = -WTERMSIG(status);
	stats.wall_time = time_after - time_before;
	get_stats(&stats);
	
	print_stats(outputfile,stats,command);
	
	free(path_to_memory);
	free(path_to_cpuacct);
	if (outputfile != NULL)
		free(outputfile);
	remove_cgroup();
	
	return 0;
}

