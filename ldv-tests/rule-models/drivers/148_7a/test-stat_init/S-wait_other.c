#include <linux/completion.h>
#include <linux/kernel.h>
#include <linux/module.h>

struct completion x;

static int test_driver(void)
{
	DECLARE_COMPLETION(x);
	int tmp, nondet;
	long tmp_l;
	unsigned long tmp_ul;

	if(nondet <= 0)
	{
		tmp = wait_for_completion_interruptible(&x);
	}
	else if(nondet == 1)
	{
		tmp = wait_for_completion_killable(&x);
	}
	else if(nondet == 2)
	{
		tmp_ul = wait_for_completion_timeout(&x, tmp_ul);
	}
	else if(nondet == 3)
	{
		tmp_l = wait_for_completion_interruptible_timeout(&x, tmp_ul);
	}
	else if(nondet == 4)
	{
		tmp_l = wait_for_completion_killable_timeout(&x, tmp_ul);
	}
	else
	{
		tmp = try_wait_for_completion(&x);
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
