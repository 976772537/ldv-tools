/*
 * Check correct methods call for model 777.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/idr.h>
#include <linux/slab.h>

static int test_driver(void)
{
	struct idr *idp = kmalloc(sizeof(*idp), GFP_KERNEL);	
		
	idr_init(idp);
	idr_destroy(idp);

	return 0;
}

static int __init my_init(void)
{
	int ret_val = test_driver();
	return ret_val;
}

module_init(my_init);

