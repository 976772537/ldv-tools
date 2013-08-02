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

#define STR_LEN 80
#define STANDART_TIMELIMIT 60
#define STANDART_MEMLIMIT 100 * 1024 * 1024

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

// cgroup parameters
char * path_to_memory = "";
char * path_to_cpuacct = "";
char * resmanager_dir = ""; // path to resource manager directory in control groups
const char * resmanager_modifier = "resource_manager_"; // modifier to the names of resource manager cgroups

// command line parameters
double timelimit = STANDART_TIMELIMIT; // in seconds
long memlimit = STANDART_MEMLIMIT; // in bytes
int kill_at_once = 0;
char * outputfile;

//errors processing
int is_mem_dir_created = 0;
int is_cpu_dir_created = 0;
char ** command = NULL;
int pid = 0; // pid of child process
int is_command_started = 0;

void get_stats(statistics *stats);
void kill_created_processes(int signum);

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
	fprintf(out,"\ttime limit: %.3f seconds\n",timelimit);
	fprintf(out,"\tcommand: ");
	print_command(out, command);
	fprintf(out,"\tcgroup memory controller: %s\n",path_to_memory);
	fprintf(out,"\tcgroup cpuacct controller: %s\n",path_to_cpuacct);
	fprintf(out,"\toutputfile: %s\n",outputfile);

	fprintf(out,"Resource manager execution status:\n");
	
	if (err_mes != NULL)
		fprintf(out,"\texit code: %i (%s)\n",exit_code, err_mes);
	else
		fprintf(out,"\texit code: %i\n",exit_code);
	if (signal != 0)
		fprintf(out,"\tkilled by signal: %i (%s)\n",signal,strsignal(signal));
	
	if (exit_code == 0 && is_command_started ) // script finished
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
		fprintf(out,"\twall time: %.3f seconds\n",stats->wall_time);
		fprintf(out,"\tcpu time: %.3f seconds\n",stats->cpu_time);
		fprintf(out,"\tuser time: %.3f seconds\n",stats->user_time);
		fprintf(out,"\tsystem time: %.3f seconds\n",stats->sys_time);
	
		fprintf(out,"Memory usage statistics:\n");
		fprintf(out,"\tpeak memory usage: %d bytes\n",stats->memory);
	}
	
	if (outputfile != NULL)
		fclose(out);
}

void exit_res_manager(int exit_code, int signal, statistics *stats, const char * err_mes)
{
	if (pid > 0)
		kill_created_processes(SIGKILL);
	if (stats != NULL)
		get_stats(stats);
	print_stats(exit_code, signal, stats, err_mes);
	if (is_mem_dir_created)
		rmdir(path_to_memory);
	if (is_cpu_dir_created)
		rmdir(path_to_cpuacct);
	
	/*
	statistics *new_st = parse_outputfile(outputfile);
	outputfile = NULL;
	print_stats(0, 0, new_st, err_mes);
	*/
	exit(0);
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

void print_help()
{
	const char * err_mes = "Usage: [-h] [-m <size>] [-t <number>] command [arguments] ...\n\t-m <size>Kb|Mb|Gb| - set memlimit=size\n\t-t <number>ms|min| - set timelimit=size\n";
	
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
/*
void remove_cgroup()
// try to delete cgroups 
{
	rmdir(path_to_cpuacct);
	rmdir(path_to_memory);
}
*/
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
		//fprintf(stderr,"Can't create directory %s - you need to change permissions: sudo chmod o+wt %s\n",path_to_memory,error_path);
		exit_res_manager(errno,0,NULL,"Error: you need to change permission in cgroup directory: sudo chmod o+wt <path_to_cgroup>");
	}
	is_mem_dir_created = 1;
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
			//fprintf(stderr,"Can't create directory %s - you need to change permissions: sudo chmod o+wt %\n", path_to_cpuacct, error_path);
			exit_res_manager(errno,0,NULL,"Error: you need to change permission in cgroup directory: sudo chmod o+wt <path_to_cgroup>");
		}
	is_cpu_dir_created = 1;
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
	if (str == NULL)
	{
		stats = NULL;
		return;
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

void kill_created_processes(int signum)
{
	// read pids from tasks; 
	// for each pid kill (pid,SIGKILL);
	/*
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
	//*/kill(pid,signum);
}

void terminate(int signum)
{
	if(pid > 0)
		kill_created_processes(SIGKILL);
	statistics *stats = (statistics *)malloc(sizeof(statistics));
	if (stats == NULL)
	{
		exit_res_manager(errno,0,NULL,"Error: Not enough memory");
	}
	stats->exit_code = 1;
	stats->sig_number = signum;
	exit_res_manager(0,signum,stats,NULL);
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
	else alarm(1);
}
/*
void print_stderr(statistics stats)
// print stderr
{
	if (stats.cpu_time > timelimit)
		fprintf(stderr,"TIMEOUT %f CPU",stats.cpu_time);
	if (stats.memory > memlimit)
		fprintf(stderr,"MEM %ld",stats.memory);
}
*/
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
	
	sscanf(line,"%s %s %s",arg,tmp,value);
	exit_code = atoi(value);
	
	line = read_string_from_opened_file(results); // res_manager signal - optional
	sscanf(line,"%s",arg);//printf("%s",line);
	if (strcmp(arg,"killed") == 0)
	{
		sscanf(line,"%s %s %s %s",arg,tmp,tmp,value);
		sig_number = atoi(value);
		line = read_string_from_opened_file(results);
	}
	//read_string_from_opened_file(results); // passing header "Command execution status:"
	line = read_string_from_opened_file(results); // command exit_code
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
			stats->wall_time = atof(value);
		if (strcmp(arg,"cpu") == 0)
			stats->cpu_time = atof(value);
		if (strcmp(arg,"user") == 0)
			stats->user_time = atof(value);
		if (strcmp(arg,"system") == 0)
			stats->sys_time = atof(value);
	}
	
	read_string_from_opened_file(results); // passing header "Memory usage statistics:" 
	line = read_string_from_opened_file(results);
	sscanf(line,"%s %s %s %s",tmp,arg,tmp,value);
	if (strcmp(arg,"memory") == 0)
		stats->memory = atol(value);
	fclose(results);
	
	
	printf("script exit_code = %i\n",exit_code);
	printf("script signal = %i\n",sig_number);
	
	return stats;
}

int main(int argc, char **argv)
{
//	char * outputfile;
//	char ** command;
	
	
	int i;
	int comm_arg = 0;
	int c;
	for (i = 1; i <= 31; i++)
	{
		if (i == SIGSTOP || i == SIGKILL ||i == SIGCHLD || i == SIGUSR1 || i == SIGUSR2 || i == SIGALRM)
			continue;
		signal(i,terminate);
	}
	
	while ((c = getopt(argc, argv, "-m:t:o:kl:")) != -1)
	{
		switch(c)
		{
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
				exit_res_manager(EINVAL,0,NULL,"Expected integer number with Kb|Mb|Gb| modifiers in -m");
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
	signal(SIGALRM,check_time);
	
	alarm(1);
	double time_before = gettime();
	pid = fork();
	if (pid == 0)
	{
		add_task(getpid());
		execvp(command[0],command);
		exit(errno);
	}
	is_command_started = 1;
	int status;
	wait4(pid,&status,0,NULL);
	double time_after = gettime();
	alarm(0);
	
	statistics *stats = (statistics *)malloc(sizeof(statistics));
	if (stats == NULL)
	{
		exit_res_manager(errno,0,NULL,"Error: Not enough memory");
	}
	stats->wall_time = time_after - time_before;
	stats->exit_code = WEXITSTATUS(status);
	if (WIFSIGNALED(status))
		stats->sig_number = WTERMSIG(status);
	else 
		stats->sig_number = 0;
	get_stats(stats);
	exit_res_manager(0, 0, stats, NULL);
	
	
	return 0;
}

