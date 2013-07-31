#include <stdio.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

void check(int signum)
{
	system("rm tmpfile"); // delete created file
	exit(0);
}

int main(int argc, char **argv)
/*
walltime~=sys
user~=0
sys~=argv[1]
*/
{
	int sleep_time = 0;
	if (argc > 1)
	{
		sleep_time = atoi(argv[1]);
	}
	printf("Work for %ims (system).\n",sleep_time);
	signal(SIGALRM, check);
	if (sleep_time < 1000)
		ualarm (sleep_time * 1000,0);
	else
		alarm (sleep_time / 1000);
	int fd = creat("tmpfile", 0777);
	while(1)
	{
		write(fd, "", 1);
	}
	return 0;
}

