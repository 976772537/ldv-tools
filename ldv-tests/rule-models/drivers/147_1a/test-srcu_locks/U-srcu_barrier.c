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
   int idx;
   struct srcu_struct *sp = sp;
   p = kmalloc(sizeof(int), GFP_KERNEL);

   idx = srcu_read_lock(sp);
   srcu_barrier(sp);
   p = srcu_dereference(test_pointer, sp);
   srcu_read_unlock(sp, idx);

   return 0;
}

static void __exit mod_exit(void)
{
}

module_init(mod_init);
module_exit(mod_exit);
