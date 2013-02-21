#include <linux/completion.h>
#include <linux/kernel.h>


struct completion my_completion;

/*Error trace: complete before declare*/
static int test_driver(void)
{
	int nondet1;
	if (nondet1 > 0)
	{
		INIT_COMPLETION(my_completion);
	}
	init_completion(&my_completion);
	return 0;
}


static int __init my_init(void)
{
	int ret_val = test_driver();
	return ret_val;
}


module_init(my_init);

