#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

int proc_time = 1;
int number_of_procs = 1;
int call_time = 1;

int calls_number = 0;

void work()
{
	usleep(proc_time * 1000);
	printf("Process finished\n");
	_exit(0);
}


void create_new_process(int signum)
{
	calls_number++;
	printf("Create %i process\n",calls_number);
	if (fork() == 0) // child
	{
		work();
	}
	if (call_time < 1000)
		ualarm (call_time * 1000,0);
	else
		alarm (call_time / 1000);
	wait(NULL);
}

int main(int argc, char **argv)
/* Create process argv[1] times in argv[3] ms for argv[2]ms.
*/
{
	
	if (argc > 1)
	{
		number_of_procs = atoi(argv[1]);
	}
	if (argc > 2)
	{
		proc_time = atoi(argv[2]);
	}
	if (argc > 3)
	{
		call_time = atoi(argv[3]);
	}
	
	printf("Create prosess %i times in %i ms. Each process lives %i ms. \n",number_of_procs,call_time,proc_time);
	signal(SIGALRM, create_new_process);
	if (call_time < 1000)
		ualarm (call_time * 1000,0);
	else
		alarm (call_time / 1000);
	for (;;)
	{
		if (calls_number >= number_of_procs)
			break;
		wait4(0, NULL, WUNTRACED, NULL);
	}
	printf("Process finished\n");
	return 0;
}

