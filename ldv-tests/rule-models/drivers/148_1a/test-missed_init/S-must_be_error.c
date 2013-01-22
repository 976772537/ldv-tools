#include <linux/completion.h>
#include <linux/kernel.h>


struct completion my_completion;

/*Trace declare->complete->Declare
Check if we can declare the same completion after it was completed.*/
static int test_driver(void)
{
	init_completion(&my_completion);
	int nondet1;
	wait_for_completion(&my_completion);
	if (nondet1 > 0)
	{
		DECLARE_COMPLETION(my_completion);
		wait_for_completion(&my_completion);
	}
	return 0;
}


static int __init my_init(void)
{
	int ret_val = test_driver();
	return ret_val;
}


module_init(my_init);

