#include <linux/completion.h>
#include <linux/kernel.h>
#include <linux/module.h>


struct completion my_completion;

/*Trace declare->complete->complete
Check if we can wait for completion from other thread*/

static int test_driver(void)
{
	init_completion(&my_completion);
	int nondet1,nondet2;
	if (nondet1 > 0)
	{
		wait_for_completion(&my_completion);
	}
	if (nondet2 > 0)
	{
		wait_for_completion(&my_completion);
	}
	return 0;
}


static int __init my_init(void)
{
	int ret_val = test_driver();
	return ret_val;
}

static void __exit my_exit(void)
{
}
module_init(my_init);
module_exit(my_exit);
