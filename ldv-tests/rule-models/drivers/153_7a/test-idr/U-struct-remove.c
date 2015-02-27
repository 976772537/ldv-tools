/*
 * Check correct methods call for model 777.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/idr.h>
#include <linux/slab.h>

struct A{
	struct idr idp;
};

static int test_driver(void)
{
	int id;
	struct A *a = kmalloc(sizeof(struct A), GFP_KERNEL);

	idr_remove(&a->idp, id);

	return 0;
}

static int __init my_init(void)
{
	int ret_val = test_driver();
	return ret_val;
}

module_init(my_init);



