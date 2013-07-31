#include <stdio.h>
#include <signal.h>
#include <string.h>

int main(int argv, char **args)
{
	int sleep_time = 1;
	int sig_num = SIGKILL;
	if (argv > 1)
	{
		sig_num = atoi(args[1]);
	}
	if (argv > 2)
	{
		sleep_time = atoi(args[2]);
	}
	printf("Kill the process in %is with %s.\n",sleep_time,strsignal(sig_num));
	sleep(sleep_time);
	kill(getpid(),sig_num);
	for ( ; ; )
	{
	}
	return 0;
}
