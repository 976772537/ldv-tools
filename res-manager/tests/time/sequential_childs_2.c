#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

int proc_time = 1; //ms
int number_of_procs = 1;
int call_time = 1;

void work()
{
	if (proc_time < 1000)
		ualarm (proc_time * 1000,0);
	else
		alarm (proc_time / 1000);
	for(;;)
	{
	}
}

void create_new_process()

{
	if (fork() == 0) // child
	{
		work();
	}
	int pid = wait(NULL);
	printf("Process %i finished\n",pid);
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
	
	printf("Create prosess %i times in %i ms. Each process lives %i ms.\n",number_of_procs,call_time,proc_time);
	int i;
	for (i = 0;i < number_of_procs;i++)
	{
		printf("Create %i process\n",i+1);
		create_new_process();
		usleep(call_time * 1000);
	}
	
	printf("All processes finished\n");
	return 0;
}

