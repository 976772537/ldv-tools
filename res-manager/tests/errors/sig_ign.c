#include <stdio.h>
#include <signal.h>
#include <string.h>

int main(int argv, char **args)
{
	int sig = SIGINT;
	if (argv > 1)
	{
		sig = atoi(args[1]);
	}
	printf("Ignore signal %s.\n", strsignal(sig));
	signal(sig,SIG_IGN);
	for ( ; ; )
	{
	}
	return 0;
}
