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
   struct rcu_head *head;
   p = kmalloc(sizeof(int), GFP_KERNEL);
   struct srcu_struct *sp = sp;

   rcu_read_lock();
   synchronize_rcu();
   rcu_read_lock_bh();
   rcu_read_lock();
   rcu_read_unlock();
   synchronize_rcu_bh();
   rcu_read_lock_sched();
   idx = srcu_read_lock(sp);
   p = rcu_dereference(test_pointer);
   srcu_read_unlock(sp, idx);
   rcu_read_unlock_sched();
   rcu_read_unlock_bh();
   call_rcu(head, test_pointer);
   rcu_read_lock_sched();
   rcu_read_unlock_sched();
   rcu_read_unlock();

   return 0;
}

static void __exit mod_exit(void)
{
}

module_init(mod_init);
module_exit(mod_exit);
