#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

void sleep_for(int sleep_time, int child)
{
	printf("Sleep for %ims in child %i.\n",sleep_time,child);
	do{
		usleep(sleep_time * 1000);
	}while (0);
}

int main(int argc, char **argv)
/*
Create parallel processes for (argv[1] .. ) walltime ms.
user~=0
sys~=0
*/
{
	int *sleep_time = (int *) malloc (sizeof(int) * (argc - 1));
	int i;
	for (i = 0; i < argc - 1; i++)
	{
		sleep_time[i] = atoi(argv[i + 1]);
	}
	
	int pid = 0;

	
	for (i = 0; i < argc - 1; i++)
	{
		pid = fork();
		if (pid == 0) // child i
		{
			sleep_for(sleep_time[i], i+1);
			_exit(0);
		}

	}
	//parent
	while ((pid = wait4(0, NULL, WUNTRACED, NULL)) > 0)
	{
		printf("Process %i ended.\n",pid);
	}
	return 0;
}

