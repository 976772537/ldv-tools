#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/rcupdate.h>

static int __init mod_init(void)
{
	int idx;
	struct srcu_struct *sp = sp;

	idx = srcu_read_lock(sp);
	rcu_read_lock();
	srcu_read_unlock(sp, idx);
	rcu_read_unlock();

	return 0;
}

static void __exit mod_exit(void)
{
}

module_init(mod_init);
module_exit(mod_exit);
