#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

void check(int signum)
{
	_exit(0);
}

void sleep_for(int sleep_time, int child)
{
	printf("Work for %ims in child %i.\n",sleep_time,child);
	if (sleep_time < 1000)
		ualarm (sleep_time * 1000,0);
	else
		alarm (sleep_time / 1000);
	for(;;)
	{
	}
}

int main(int argc, char **argv)
/* Create parallel processes for (argv[1] .. ) ms.
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
		}
	}
	//parent
	while ((pid = wait4(0, NULL, WUNTRACED, NULL)) > 0)
	{
		printf("Process %i ended.\n",pid);
	}
	return 0;
}

