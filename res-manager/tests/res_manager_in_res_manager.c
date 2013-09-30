#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <signal.h>

void check(int signum)
{
	_exit(0);
}


int main(int argc, char **argv)
{
	int pid = 0;
	if (fork() == 0)
	{
		printf("Starting task 1 for 2 seconds\n");
		if (fork() == 0)
		{
			signal(SIGALRM,check);
			alarm (2);
			for(;;)
			{
			}
		}
		wait(NULL);
		printf("Subprocess 1 ended\n");
		printf("Starting subprocess 2 in res_manager\n");
		
		if (fork() == 0)
		{
			const char * res_manager = "/home/vitaly/ldv-tools/res-manager/res-manager";
			execl(res_manager, res_manager, "-m", "10Gb", "-t" , "10min", "-l", "ldv", 
				  "/home/vitaly/ldv-tools/res-manager/build/time/user", "10000", (char*)0);
		}
		wait(NULL);
		printf("Subprocess 2 ended\n");
		exit(0);
	}
	wait(NULL);
	printf("Exitig main process\n");
	return 0;
}

