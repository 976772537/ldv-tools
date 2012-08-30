#include <linux/spinlock.h>
#include "linux/module.h"
#include "linux/kernel.h"
#include "linux/dcache.h"

struct my_device {
	spinlock_t lock;
};

static int __init my_init(void)
{
	struct my_device *mydev;

	spin_lock_nested(&mydev->lock, DENTRY_D_LOCK_NESTED);

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

