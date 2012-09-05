#include "linux/module.h"
#include "linux/kernel.h"
#include "linux/netdevice.h"

static int __init my_init(void)
{
	struct napi_struct *n;

	napi_complete(n);

	return 0;
}

static void __exit my_exit(void)
{
	
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("LDV Project, Marina Makienko <makienko@ispras.ru>");
MODULE_DESCRIPTION("Test");

