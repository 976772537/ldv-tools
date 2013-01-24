#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/rcupdate.h>
#include <linux/slab.h>

MODULE_LICENSE("GPL");

void *test_pointer;

static int __init mod_init(void)
{
   int *p;
   p = kmalloc(sizeof(int), GFP_KERNEL);

   rcu_read_lock();
   rcu_assign_pointer(test_pointer, p);
   p = rcu_dereference(test_pointer);
   rcu_read_unlock();

   return 0;
}

static void __exit mod_exit(void)
{
}

module_init(mod_init);
module_exit(mod_exit);
