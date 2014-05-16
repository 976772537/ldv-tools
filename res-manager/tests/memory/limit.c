#include <stdio.h>
#include <limits.h>
#include <stdlib.h>

int main(int argv, char **argc)
{
	unsigned long long allocate_bytes = 0;
	if (argv > 1)
	{
		allocate_bytes = atoll(argc[1]);
	}
	printf("Allocate %llub.\n",allocate_bytes);
	char *allocated_array = (char *)malloc (allocate_bytes);
	unsigned long long i;
	for(i=0;i<allocate_bytes;i++)
	{
		allocated_array[i] = '0';
	}
	sleep(1);
	return 0;
}

