#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/rcupdate.h>
#include <linux/slab.h>
#include <linux/rculist.h>

MODULE_LICENSE("GPL");

void *test_pointer;

static int __init mod_init(void)
{
   int *p;
   int idx;
   p = kmalloc(sizeof(int), GFP_KERNEL);
   struct srcu_struct *sp = sp;
   struct list_head *new;
   struct list_head *head;
   struct hlist_node *hnew;
   struct hlist_node *hold;

   rcu_read_lock();
   rcu_read_lock_bh();
   rcu_read_lock();
   rcu_read_unlock();
   rcu_read_lock_sched();
   idx = srcu_read_lock(sp);
   p = rcu_dereference(test_pointer);
   srcu_read_unlock(sp, idx);
   rcu_read_unlock_sched();
   rcu_read_unlock_bh();
   rcu_read_lock_sched();
   rcu_read_unlock_sched();
   rcu_read_unlock();

   list_add_rcu(new, head);
   list_add_tail_rcu(new, head);
   list_del_rcu(head);
   list_replace_rcu(head, new);
   hlist_del_rcu(hnew);
   hlist_replace_rcu(hold, hnew);
   hlist_add_head_rcu(hnew, hold);
   hlist_add_after_rcu(hnew, hold);
   hlist_add_before_rcu(hnew, hold);
   list_splice_init_rcu(new, head, test_pointer);
   __list_add_rcu(new, head, new);

   return 0;
}

static void __exit mod_exit(void)
{
}

module_init(mod_init);
module_exit(mod_exit);
