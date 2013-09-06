#include <stdio.h>
#include <limits.h>
#include <stdlib.h>

int main(int argv, char **argc)
{
	int allocate_bytes = 0;
	if (argv > 1)
	{
		allocate_bytes = atoi(argc[1]);
	}
	printf("Allocate %ib.\n",allocate_bytes);
	char *allocated_array = (char *)malloc (allocate_bytes);
	int i;
	for(i=0;i<allocate_bytes;i++)
	{
		allocated_array[i] = '0';
	}
	sleep(1);
	return 0;
}

