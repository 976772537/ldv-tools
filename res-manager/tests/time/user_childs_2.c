#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

int work_time = 1;

void work(int child)
{
	if (work_time < 1000)
		ualarm (work_time * 1000,0);
	else
		alarm (work_time / 1000);
	for(;;)
	{
	}
}

int main(int argc, char **argv)
/* Create argv[1] parallel processes for argv[2] ms.
sys~=0
*/
{
	int number_of_procs = 0;
	if (argc > 1)
	{
		number_of_procs = atoi(argv[1]);
	}
	if (argc > 2)
	{
		work_time = atoi(argv[2]);
	}
	printf("Create %i processes and work %ims in each of them.\n",number_of_procs,work_time);
	int pid = 0;
	int i;
	for (i = 0; i < number_of_procs; i++)
	{
		pid = fork();
		if (pid == 0) // child i
		{
			work(i+1);
		}
	}
	//parent
	while ((pid = wait4(0, NULL, WUNTRACED, NULL)) > 0)
	{
		//printf("Process %i ended.\n",pid);
	}
	printf("All processes are finished\n");
	return 0;
}

