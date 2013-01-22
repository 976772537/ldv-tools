#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/rcupdate.h>

static int __init mod_init(void)
{
	int idx1, idx2;
	struct srcu_struct *sp = sp;

	rcu_read_lock();
	idx1 = srcu_read_lock(sp);
	rcu_read_lock_sched();
	rcu_read_unlock_sched();
	rcu_read_lock_bh();
	rcu_read_lock_sched();
	rcu_read_lock();
	idx2 = srcu_read_lock(sp);
	srcu_read_unlock(sp, idx2);
	rcu_read_unlock();
	rcu_read_unlock_sched();
	rcu_read_unlock_bh();
	srcu_read_unlock(sp, idx1);
	rcu_read_unlock();

	return 0;
}

static void __exit mod_exit(void)
{
}

module_init(mod_init);
module_exit(mod_exit);
