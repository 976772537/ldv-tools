#include <linux/module.h>
#include <linux/init.h>

#include <linux/sched.h>
#include <linux/slab.h> /* kmalloc() */
#include <linux/types.h>  /* size_t */
#include <linux/errno.h>  /* error codes */

#include <linux/netdevice.h>   /* struct device, and other headers */
#include <linux/skbuff.h> /* ? */
#include <linux/etherdevice.h>

struct net_device *test_dev;
struct napi_struct *napi;

struct test_priv {
};

static void test_exit(void)
{
}


static int __init test_init_module(void)
{
	int result, ret = -ENOMEM;
	
	netif_napi_add(test_dev, napi, 1, 1);
  
	return	0;
}



module_init(test_init_module);
module_exit(test_exit);

MODULE_AUTHOR("LDV Project, Ilya Shchepetkov <shchepetkov@ispras.ru>");
MODULE_LICENSE("Apache 2.0");