#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <stdlib.h>

void check(int signum)
{
	exit(0);
}

int main(int argc, char **argv)
/*
walltime~=user
user~=argv[1]
sys~=0
*/
{
	int sleep_time = 0;
	if (argc > 1)
	{
		sleep_time = atoi(argv[1]);
	}
	printf("Work for %i ms (user).\n",sleep_time);
	signal(SIGALRM, check);
	if (sleep_time < 1000)
		ualarm (sleep_time * 1000,0);
	else
		alarm (sleep_time / 1000);
	double fi;
	for ( ; ; )
	{
		if (fi > 10) fi = -10;
		fi+=1/1000;
	}
	return 0;
}
