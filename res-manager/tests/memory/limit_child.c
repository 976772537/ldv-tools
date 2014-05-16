#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <sys/wait.h>

#define BYTES_FACTOR 1024
/*
	 *
   /   \
  1 ... n
*/

void allocate(unsigned long long allocate_bytes)
{
	char *allocated_array = (char *)malloc (allocate_bytes);
	unsigned long long i;
	for(i=0;i<allocate_bytes;i++)
	{
		allocated_array[i] = '0';
	}
	sleep(1);
	_exit(0);
}

int main(int argv, char **args)
{
	int number_of_procs = 0;
	int unsigned long long size = 0;
	if (argv > 1)
	{
		number_of_procs = atoi(args[1]);
	}
	if (argv > 2)
	{
		size = atoll(args[2]);
	}
	printf("Allocate %llub in %i processes.\n",size,number_of_procs);
	int pid = 0;
	int i;
	for (i = 0; i < number_of_procs; i++)
	{
		pid = fork();
		if (pid == 0) // child i
		{
			allocate(size);
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


