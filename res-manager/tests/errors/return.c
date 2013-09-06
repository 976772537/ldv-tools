#include <stdio.h>
#include <signal.h>

int main(int argv, char **args)
{
	int err = 0;
	if (argv > 1)
	{
		err = atoi(args[1]);
	}
	return err;
}
