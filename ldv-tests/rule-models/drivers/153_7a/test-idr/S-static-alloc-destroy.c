/*
 * Check correct methods call for model 777.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/idr.h>
#include <linux/slab.h>

static DEFINE_IDR(idp);

static int test_driver(void)
{
	int id, start, end;

	id = idr_alloc(&idp, NULL, start, end, GFP_KERNEL);
	idr_destroy(&idp);

	return 0;
}

static int __init my_init(void)
{
	int ret_val = test_driver();
	return ret_val;
}

module_init(my_init);

