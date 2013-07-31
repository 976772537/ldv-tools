#include <stdio.h>

int main(int argc, char **argv)
/*
walltime=argv[1] ms
user~=0
sys~=0
*/
{
	int sleep_time = 0;
	if (argc > 1)
	{
		sleep_time = atoi(argv[1]);
	}
	printf("Sleep for %i milliseconds.\n",sleep_time);
	do{
		usleep(sleep_time * 1000);
	}while (0);
	return 0;
}
