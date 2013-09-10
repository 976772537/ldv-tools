#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

#define Kb 1024
#define Mb 1024*1024

#define EPS 1e-10

#define STR_LEN 80
#define COMM_LEN 1024

typedef struct statistics
{
	int s_sig_number;
	int s_exit_code;
	int sig_number;
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

double time_inacc = 0.6;
double mem_inacc = 0.05; 

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

void create_command(char * timeout,int memlimit,int timelimit,const char * outputfile, char str[])
{
	strcpy(str, timeout);
	strcat(str, " -m ");
	strcat(str, itoa(memlimit));
	strcat(str, " -t ");
	strcat(str, itoa(timelimit));
	strcat(str, " -o ");
	strcat(str, outputfile);
	printf("%s\n",str);
}

int passed_tests = 0;
int number_of_tests = 0;

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
	for (i = 0; i < 12; i++)
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
	
	stats->s_sig_number = sig_number;
	stats->s_exit_code = exit_code;
	
	return stats;
}

void print_stat(const char * outputfile)
{
	FILE * results;
	results = fopen(outputfile,"rt");
	if (results == NULL)
		return;
	char line [STR_LEN];
	while (fgets(line, STR_LEN, results) != NULL)
	{
		printf("%s",line);
	}
	system("rm tmpfile");
}

int check_outputfile(const char * outputfile)
//returns true, if command was terminated normally with return code 0
{
	statistics * stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	if (stats->memory_exhausted || stats->time_exhausted || stats->exit_code || stats->sig_number > 0)
		return 0;
	return 1;
}

int check_outputfile_time(const char * outputfile, double time)
//returns true, if ((time - cpu_time) / time) <= time_inacc
{
	statistics * stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	double inaccuracy = fabs(time - stats->cpu_time) / (time + EPS);
	if (inaccuracy <= time_inacc)
		return 1;
	return 0;
}

int check_outputfile_memory(const char * outputfile, int mem)
//returns true, if ((mem - cmem) / time) <= mem_inacc
{
	statistics * stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	double inaccuracy = fabs(mem - stats->memory) / (mem + EPS);
	if (inaccuracy <= mem_inacc)
		return 1;
	return 0;
}

int check_time_command(const char * outputfile, const char * time_file)
//compare results with time command
{
	statistics * stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	
	//time file
	FILE * results;
	results = fopen(time_file,"rt");
	if (results == NULL)
		return 0;
	double time_user = 0.0;
	double time_sys = 0.0;
	double time_real = 0.0;
	char line [STR_LEN];
	char arg [STR_LEN];
	char value [STR_LEN];
	while (fgets(line, STR_LEN, results) != NULL)
	{
		char arg [STR_LEN];
		char value [STR_LEN];	
		sscanf(line,"%s %s",arg,value);
		if (strcmp(arg,"user") == 0 )
			time_user = atof(value);
		if (strcmp(arg,"sys") == 0 )
			time_sys = atof(value);
		if (strcmp(arg,"real") == 0 )
			time_real = atof(value);
	}
	fclose(results);
	double inaccuracy_sys;
	double inaccuracy_user;
	double inaccuracy_cpu;
	double inaccuracy_wall;
	inaccuracy_sys = fabs(time_sys - stats->sys_time);
	inaccuracy_user = fabs(time_user - stats->user_time);
	inaccuracy_cpu = fabs( (time_user + time_sys) - stats->cpu_time);
	inaccuracy_wall = fabs(time_real - stats->wall_time);
	/*if ( inaccuracy_sys <= time_inacc_s &&
		 inaccuracy_user <= time_inacc_s &&
		 inaccuracy_cpu <= time_inacc_s &&
		 inaccuracy_wall <= time_inacc_s)*/
	if ( inaccuracy_cpu <= time_inacc &&
		 inaccuracy_wall <= time_inacc)
		return 1;
	return 0;
}

int check_outputfile_timelimit(const char * outputfile)
//returns true, if time exhausted
{
	statistics *stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	if (stats->time_exhausted)
		return 1;
	return 0;
}

int check_outputfile_memlimit(const char * outputfile)
//returns true, if memory exhausted
{
	statistics *stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	if (stats->memory_exhausted)
		return 1;
	return 0;
}

int check_outputfile_exitcode(const char * outputfile)
//returns true, if exit_code > 0 
{
	statistics *stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	if (stats->exit_code > 0)
		return 1;
	return 0;
}

int check_outputfile_signal(const char * outputfile)
//returns true, if exit_code < 0 (terminated by signal)
{
	statistics *stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	if (stats->sig_number > 0)
		return 1;
	return 0;
}

int check_outputfile_exitcode_script(const char * outputfile)
//returns true, if exit_code > 0 
{
	statistics *stats = parse_outputfile(outputfile);
	
	printf("s_exit_code: %i\n",stats->s_exit_code);
	
	if (stats == NULL)
		return 0;
	if (stats->s_exit_code > 0)
		return 1;
	return 0;
}

int check_outputfile_signal_script(const char * outputfile)
//returns true, if exit_code < 0 (terminated by signal)
{
	statistics *stats = parse_outputfile(outputfile);
	if (stats == NULL)
		return 0;
	if (stats->s_sig_number > 0)
		return 1;
	return 0;
}

/**/

void print_test_header()
{
	printf("\n");
	int i;
	for(i = 0; i < 80; i++)
		printf("*");
	printf("\nRunning test number %i\n",number_of_tests+1);
}

void wait_normal_execution(const char * outputfile)
// check if there is no errors
{
	print_test_header();
	int status;
	wait(&status);
	number_of_tests++;
	if (WIFEXITED(status) == 1 && WEXITSTATUS(status) != 0 || WIFSIGNALED(status) == 1)
	{
		printf ("TEST FAILED - can't execute command\n");
		if (WIFEXITED(status) == 1 && WEXITSTATUS(status) != 0)
		{
			printf("Process exited with return code %i\n",WEXITSTATUS(status));
		}
		else
			printf("Process was killed by signal %i\n",WTERMSIG(status) );
	}
	else
	{
		if (check_outputfile(outputfile))
		{
			printf ("TEST PASSED\n");
			passed_tests++;
		}
		else
		{
			printf ("TEST FAILED - expected normal execution\n");
		}
	}
}

void wait_help_option(const char * outputfile)
// check if there is no errors
{
	print_test_header();
	int status;
	wait(&status);
	number_of_tests++;
	if (WIFEXITED(status) == 1 && WEXITSTATUS(status) != 0 || WIFSIGNALED(status) == 1)
	{
		printf ("TEST FAILED - script finished with errors or by signal\n");
	}
	else
	{
		printf ("TEST PASSED\n");
		passed_tests++;
	}
}

void wait_and_check_memory(const char * outputfile, int mem)
// compare memory with known memory
{
	print_test_header();
	number_of_tests++;
	if (check_outputfile_memory(outputfile, mem))
	{
		printf ("TEST PASSED\n");
		passed_tests++;
	}
	else
	{
		printf ("TEST FAILED - computed memory usage and expected value are different\n");
	}
}

void wait_and_check_time(const char * outputfile, int time)
// compare cpu_time with known time
{
	print_test_header();
	number_of_tests++;
	if (check_outputfile_time(outputfile, time))
	{
		printf ("TEST PASSED\n");
		passed_tests++;
	}
	else
	{
		printf ("TEST FAILED - cpuacct time and expected time are different\n");
	}
}

void wait_and_check_time_command(const char * outputfile, const char * time_file)
// compare statistics with time command
{
	print_test_header();
	number_of_tests++;
	if (check_time_command(outputfile, time_file))
	{
		printf ("TEST PASSED\n");
		passed_tests++;
	}
	else
	{
		printf ("TEST FAILED - time command and cpuacct time are different\n");
	}
}

void wait_timelimit_execution(const char * outputfile)
// test must terminate with time limit exhausted
{
	print_test_header();
	int status;
	wait(&status);
	number_of_tests++;
	if (WIFEXITED(status) == 1 && WEXITSTATUS(status) != 0 || WIFSIGNALED(status) == 1)
	{
		printf ("TEST FAILED - can't execute command\n");
		if (WIFEXITED(status) == 1 && WEXITSTATUS(status) != 0)
			printf("Process exited with return code %i\n",WEXITSTATUS(status));
		else
			printf("Process was killed by signal %i\n",WTERMSIG(status) );
	}
	else
	{
		if (check_outputfile_timelimit(outputfile))
		{
			printf ("TEST PASSED\n");
			passed_tests++;
		}
		else
		{
			printf ("TEST FAILED - expected time exhaustion\n");
		}
	}
}

void wait_memlimit_execution(const char * outputfile)
// test must terminate with memory limit exhausted
{
	print_test_header();
	int status;
	wait(&status);
	number_of_tests++;
	if (WIFEXITED(status) == 1 && WEXITSTATUS(status) != 0 || WIFSIGNALED(status) == 1)
	{
		printf ("TEST FAILED - can't execute command\n");
		if (WIFEXITED(status) == 1 && WEXITSTATUS(status) != 0)
			printf("Script exited with return code %i\n",WEXITSTATUS(status));
		else
			printf("Script was killed by signal %i\n",WTERMSIG(status) );
	}
	else
	{
		if (check_outputfile_memlimit(outputfile))
		{
			printf ("TEST PASSED\n");
			passed_tests++;
		}
		else
		{
			printf ("TEST FAILED - expected memory exhaustion\n");
		}
	}
}

void wait_exitcode_execution(const char * outputfile)
// test must terminate normally with exit code > 0
{
	print_test_header();
	int status;
	wait(&status);
	number_of_tests++;
	if (WIFEXITED(status) == 1 && WEXITSTATUS(status) == 0 && check_outputfile_exitcode(outputfile))
	{
		printf ("TEST PASSED\n");
		passed_tests++;
	}
	else
	{
		printf ("TEST FAILED - expected exit code > 0 in command\n");
	}
}

void wait_signal_execution(const char * outputfile)
// test must terminate by signal
{
	print_test_header();
	int status;
	wait(&status);
	number_of_tests++;
	if (WIFEXITED(status) == 1 && WEXITSTATUS(status) == 0 && check_outputfile_signal(outputfile))
	{
		printf ("TEST PASSED\n");
		passed_tests++;
	}
	else
	{
		printf ("TEST FAILED - expected signal execution in command\n");
	}
}

void wait_exitcode_execution_script(const char * outputfile)
// script must terminate normally with exit code > 0
{
	print_test_header();
	int status;
	wait(&status);
	number_of_tests++;
	if (WIFEXITED(status) == 1 && WEXITSTATUS(status) == 0 && check_outputfile_exitcode_script(outputfile) || 
		WIFEXITED(status) == 1 && WEXITSTATUS(status) != 1)
	{
		printf ("TEST PASSED\n");
		passed_tests++;
	}
	else
	{
		printf ("TEST FAILED - expected error code > 0 in script\n");
	}
}

void wait_signal_execution_script(const char * outputfile)
// script must terminate by signal
{
	print_test_header();
	int status;
	wait(&status);
	number_of_tests++;
	if (check_outputfile_signal_script(outputfile))
	{
		printf ("TEST PASSED\n");
		passed_tests++;
	}
	else
	{
		printf ("TEST FAILED - expected signal execution in script\n");
	}
}

char * concat(char * pref, char * command, char * post)
{
	char tmp[strlen(pref) + strlen(command) + strlen(post) + 1];
	strcpy(tmp,pref);
	strcat(tmp,command);
	strcat(tmp,post);
	return strdup(tmp);
}

void print_help()
{
	printf("Wrong arguments\nUsage: \n\t");
	printf("test_script [options] <path_to_resmanager>\n\t");
	printf("--etime <value> - inaccuracy for time value\n\t");
	printf("--ememory <value> - inaccuracy for memory value\n");
	exit(1);
}

int main(int argc, char **argv)
{
	char * timeout;
	int i;
	for (i = 1; i < argc; i++)
	{
		if (strcmp(argv[i], "--etime") == 0)
		{
			if (argv[i+1] != NULL)
				time_inacc = atof(argv[i+1]);
			else
			{
				print_help();
			}
		}
		else if (strcmp(argv[i], "--ememory") == 0)
		{
			if (argv[i+1] != NULL)
				mem_inacc = atof(argv[i+1]);
			else
			{
				print_help();
			}
		}
		else  // path to res-manager
		{
			timeout = argv[i];
			break;
		}
	}
	
	int basetimelimit = 900;
	int basememlimit = 100*Mb;
	const char * outputfile = "tmpfile";
	const char * time_file = "time_file_";
	int basetime = 10;
	char command [COMM_LEN];
	int memlimit = basememlimit;
	int timelimit = basetime;
	int status;
	int time;

	// 1. timelimit	
	printf("1.Tests for time limits\n");
	timelimit = 5;
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/user", "4000", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/sys", "4000", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real", "4000", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);

	// 2.timelimit with children
	printf("\n\n2.Tests for time limits with children\n");

	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/user_childs_1", "2000", "2000", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit),  "-o", outputfile, "-l", "ldv", "time/sys_childs_1", "2000", "2000", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real_childs_1", "2000", "2000", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	timelimit = 11;
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real_childs_1", "1000", "2000", "3000", "4000",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/user_childs_1", "1000", "2000", "3000", "4000",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/sys_childs_1", "1000", "2000", "3000", "4000",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	timelimit = 130;
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real_childs_2", "128", "1000", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/user_childs_2", "128", "1000",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/sys_childs_2", "128", "1000",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	// 3.check time
	printf("\n\n3.Tests for checking time\n");
	timelimit = 100;
	time = 10;

	system(concat("",timeout," -m 100000000 -t 10 -o tmpfile -l ldv time/user 5000"));
	wait_and_check_time(outputfile, 5);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 10 -o tmpfile -l ldv time/user 5000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);	
	
	system(concat("",timeout," -m 100000000 -t 10 -o tmpfile -l ldv time/sys 5000"));
	wait_and_check_time(outputfile, 5);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 10 -o tmpfile -l ldv time/sys 5000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);

	system(concat("(time -p ",timeout," -m 100000000 -t 10 -o tmpfile -l ldv time/real 5000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);
	
	// 4.check time with children
	printf("\n\n4.Tests for checking time with children\n");
	
	system(concat("",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/user_childs_1 1000 2000 3000 4000"));
	wait_and_check_time(outputfile, 10);
	print_stat(outputfile);
	
	system(concat("",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/user_childs_2 4 4000"));
	wait_and_check_time(outputfile, 16);
	print_stat(outputfile);

	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/user_childs_1 1000 2000 3000 4000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);

	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/user_childs_2 16 1000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);

	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/user_childs_2 128 2000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/user_childs_2 32 12000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/sequential_childs_1 10 1000 2000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/sequential_childs_1 5 4000 6000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/sequential_childs_2 10 1 2000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/sequential_childs_2 10 1 2000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/sys_childs_1 1000 2000 3000 4000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);	
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/sys_childs_2 16 1000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);	
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/sys_childs_2 128 1000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);	
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/sys_childs_2 32 2000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);	
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/real_childs_1 1000 2000 3000 4000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/real_childs_2 16 1000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);	
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/real_childs_2 128 1000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);	
	
	system(concat("(time -p ",timeout," -m 100000000 -t 100 -o tmpfile -l ldv time/real_childs_2 32 12000) 2> time_file_"));
	wait_and_check_time_command(outputfile, time_file);
	print_stat(outputfile);	
	
	// 5. memlimit
	printf("\n\n5.Tests for memory limits\n");
	
	memlimit = 110000000;
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-o", outputfile, "-l", "ldv", "memory/limit", "100000000",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);

	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-o", outputfile, "-l", "ldv", "memory/limit_child", "10","10000000" ,(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	// 6. memlimit with children
 	printf("\n\n6.Tests for memory limits with children\n");

	system(concat("",timeout," -m 110000000 -o tmpfile -l ldv memory/limit 100000000"));
	wait_and_check_memory(outputfile, 100000000);
	print_stat(outputfile);
	
	system(concat("",timeout," -m 110000000 -o tmpfile -l ldv memory/limit_child 10 10000000"));
	wait_and_check_memory(outputfile, 100000000);
	print_stat(outputfile);

	// 7. mins
	printf("\n\n7.Tests for min values\n");
	timelimit = 1;
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/sys", "1",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/user", "1",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real", "1",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);

	memlimit = 1*Mb;
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-o", outputfile, "-l", "ldv", "memory/limit", "1" ,(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);

	// 8.check timelimit/memlimit errors
	printf("\n\n8.Tests for checking timelimit/memlimit errors\n");
	timelimit = 4;
	memlimit = basememlimit;
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/user", "5000", (char*)0);
	wait_timelimit_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/sys", "5000", (char*)0);
	wait_timelimit_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/sys_childs_1", "3000", "2000", (char*)0);
	wait_timelimit_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/user_childs_1", "3000", "2000", (char*)0);
	wait_timelimit_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/user_childs_2", "8", "1000", (char*)0);
	wait_timelimit_execution(outputfile);
	print_stat(outputfile);

	memlimit = 100000000;
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-o", outputfile, "-l", "ldv", "memory/limit", "100000000" ,(char*)0);
	wait_memlimit_execution(outputfile);
	print_stat(outputfile);

	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-o", outputfile, "-l", "ldv", "memory/limit_child","10", "100000000" ,(char*)0);
	wait_memlimit_execution(outputfile);
	print_stat(outputfile);

	// 9. errors
	printf("\n\n9.Tests for errors\n");
	timelimit = 100;
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "sdjfkhsdftime/user_childs_2", "4", (char*)0);
	wait_exitcode_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , "time", "-o", outputfile, "-l", "ldv", "time/user_childs_2", "4", (char*)0);
	wait_exitcode_execution_script(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/return", "1", (char*)0);
	wait_exitcode_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/return", "-1", (char*)0);
	wait_exitcode_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_num", "15",  (char*)0);
	wait_signal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_num", "14", (char*)0);
	wait_signal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_num", "9", (char*)0);
	wait_signal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_num", "2",(char*)0);
	wait_signal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_num", "6",(char*)0);
	wait_signal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_num", "11", (char*)0);
	wait_signal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_num", "8", (char*)0);
	wait_signal_execution(outputfile);
	print_stat(outputfile);
	
	int pid = 0;
	if ((pid = fork()) == 0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real", "100000",(char*)0);
	sleep(1);
	kill(pid, SIGINT);
	wait_signal_execution_script(outputfile);
	print_stat(outputfile);
	
	pid = 0;
	if ((pid = fork()) == 0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real", "100000",(char*)0);
	sleep(1);
	kill(pid, SIGTERM);
	wait_signal_execution_script(outputfile);
	print_stat(outputfile);

	pid = 0;
	if ((pid = fork()) == 0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real", "2000",(char*)0);
	sleep(1);
	kill(pid, SIGABRT);
	wait_signal_execution_script(outputfile);
	print_stat(outputfile);
	
	pid = 0;
	if ((pid = fork()) == 0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real", "2000",(char*)0);
	sleep(1);
	kill(pid, SIGHUP);
	wait_signal_execution_script(outputfile);
	print_stat(outputfile);
	
	pid = 0;
	if ((pid = fork()) == 0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "time/real", "2000",(char*)0);
	sleep(1);
	kill(pid, SIGQUIT);
	wait_signal_execution_script(outputfile);
	print_stat(outputfile);

	pid = 0;
	if ((pid = fork()) == 0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_ign", "2",(char*)0);
	sleep(1);
	kill(pid, SIGINT);
	wait_signal_execution_script(outputfile);
	print_stat(outputfile);
	
	pid = 0;
	if ((pid = fork()) == 0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "errors/sig_ign", "14",(char*)0);
	sleep(1);
	kill(pid, SIGTERM);
	wait_signal_execution_script(outputfile);
	print_stat(outputfile);

	// 10.additional tests
	printf("\n\n10.Additional tests for options\n");
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "lv", "errors/return", "0", (char*)0);
	wait_exitcode_execution_script(outputfile);
	print_stat(outputfile);

	if (fork()==0)
		execlp(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "--stdout", "/dev/null", "ls", "-la", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execlp(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "--stderr", "/dev/null", "time", "ls",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execlp(timeout, timeout, "-m", itoa(memlimit), "-t" , itoa(timelimit), "-o", outputfile, "-l", "ldv", "--stderr", "/dev/null", "--stdout", "/dev/null", "time", "ls",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);	
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , "1min", "-o", outputfile, "-l", "ldv", "--interval", "1", "time/user", "1000ms", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-m", itoa(memlimit), "-t" , "90ms", "-o", outputfile, "-l", "ldv", "--interval", "5", "time/user", "100", (char*)0);
	wait_timelimit_execution(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-h", (char*)0);
	wait_help_option(outputfile);
	print_stat(outputfile);
	
	system("echo -e \"memory memory.limit_in_bytes 10000000\nmemory memory.memsw.limit_in_bytes 10000000\" > tmp_file_");
	if (fork()==0)
		execl(timeout, timeout, "--config", "tmp_file_", "-o", outputfile, "-l", "ldv", "memory/limit", "11000000",(char*)0);
	wait_signal_execution(outputfile);
	print_stat(outputfile);
	system("rm tmp_file_");
	
	system("echo -e \"memory memory.swappiness 0\" > tmp_file_");
	if (fork()==0)
		execl(timeout, timeout, "--config", "tmp_file_", "-o", outputfile, "-l", "ldv", "memory/limit", "11000000",(char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	system("rm tmp_file_");
	
	system("echo -e \"memory memory.limit_in_bytes_ 10000000\" > tmp_file_");
	if (fork()==0)
		execl(timeout, timeout, "--config", "tmp_file_", "-o", outputfile, "-l", "ldv", "memory/limit", "11000000",(char*)0);
	wait_exitcode_execution_script(outputfile);
	print_stat(outputfile);
	system("rm tmp_file_");
	
	if (fork()==0)
		execl(timeout, timeout, "--config", "tmp_file_", "-o", outputfile, "-l", "ldv", "memory/limit", "11000000",(char*)0);
	wait_exitcode_execution_script(outputfile);
	print_stat(outputfile);
	
	if (fork()==0)
		execl(timeout, timeout, "-o", outputfile, "-l", "ldv", "./res_manager_in_res_manager", (char*)0);
	wait_normal_execution(outputfile);
	print_stat(outputfile);
	
	// stat
	printf("\nNumber of tests %i\nPassed tests %i \n",number_of_tests, passed_tests);
	system("rm -f time_file_");
}


