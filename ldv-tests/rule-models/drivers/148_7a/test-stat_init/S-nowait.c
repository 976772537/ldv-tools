#include <linux/completion.h>
#include <linux/kernel.h>
#include <linux/module.h>

struct completion my_completion;

/*Trace declare
Check if we can wait for completion from other thread*/

static int test_driver(void)
{
	DECLARE_COMPLETION(my_completion);

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
