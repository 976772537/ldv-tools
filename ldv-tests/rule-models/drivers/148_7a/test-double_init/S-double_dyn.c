#include <linux/completion.h>
#include <linux/kernel.h>


struct completion my_completion;

/*Trace declare->Declare->complete
Check if we can declare the same completion after it was declared (we suppose this trace correct for this rule).*/
static int test_driver(void)
{
	init_completion(&my_completion);
	init_completion(&my_completion);
	return 0;
}


static int __init my_init(void)
{
	int ret_val = test_driver();
	return ret_val;
}


module_init(my_init);

