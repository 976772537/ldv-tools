#include <linux/module.h>
#include <linux/init.h>

#include <linux/sched.h>
#include <linux/slab.h> /* kmalloc() */
#include <linux/types.h>  /* size_t */
#include <linux/errno.h>  /* error codes */

#include <linux/netdevice.h>   /* struct device, and other headers */
#include <linux/skbuff.h> /* ? */


struct net_device *test_dev;

struct test_priv {
};

void test_init(struct net_device *dev)
{
}

static void test_exit(void)
{
	if (test_dev) {
		unregister_netdev(test_dev);
		free_netdev(test_dev);
	}
	return;
}


static int __init test_init_module(void)
{
	int result, ret = -ENOMEM;
	
	test_dev = alloc_netdev(sizeof(struct test_priv), "tst%d", test_init);
	if (test_dev == NULL)
		goto out;
	
	ret = -ENODEV;
	if (result = register_netdev(test_dev))
		printk("test: error %i registering device \"%s\"\n", result, test_dev->name);
	else
		ret = 0;
   out:
	if (ret)
		test_exit();
	return	ret;
}



module_init(test_init_module);
module_exit(test_exit);

MODULE_AUTHOR("LDV Project, Ilya Shchepetkov <shchepetkov@ispras.ru>");
MODULE_LICENSE("Apache 2.0");