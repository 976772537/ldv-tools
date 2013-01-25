#include <linux/completion.h>
#include <linux/kernel.h>
#include <linux/module.h>

struct completion x;

/*Trace ->complete
Check if we can wait for completion from other thread*/

static int test_driver(void)
{
	int nondet;
	if (nondet == 10)
	{
		DECLARE_COMPLETION(x);
	}
	unsigned long tmp_ul;
	if (nondet > 0)
	{
		nondet = wait_for_completion_timeout(&x, tmp_ul);
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
