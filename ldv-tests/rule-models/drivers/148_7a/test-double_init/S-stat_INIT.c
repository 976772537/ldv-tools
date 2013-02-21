#include <linux/completion.h>
#include <linux/kernel.h>

DECLARE_COMPLETION(my_completion);

/*Trace declare->complete->Declare
Check if we can declare the same completion after it was completed (for macro INIT_COMPLETION).*/
static int test_driver(void)
{
	int nondet1, nondet2;
	wait_for_completion(&my_completion);
	if (nondet1 > 0)
	{
		INIT_COMPLETION(my_completion);
	}
	if (nondet2 > 0)
	{
		try_wait_for_completion(&my_completion);
	}
	return 0;
}


static int __init my_init(void)
{
	int ret_val = test_driver();
	return ret_val;
}


module_init(my_init);

