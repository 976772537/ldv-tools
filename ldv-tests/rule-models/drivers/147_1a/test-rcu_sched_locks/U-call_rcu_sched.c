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
   struct rcu_head *head;   

   rcu_read_lock_sched();
   p = rcu_dereference(test_pointer);
   call_rcu_sched(head, test_pointer);
   rcu_read_unlock_sched();

   
   return 0;
}

static void __exit mod_exit(void)
{
}

module_init(mod_init);
module_exit(mod_exit);
