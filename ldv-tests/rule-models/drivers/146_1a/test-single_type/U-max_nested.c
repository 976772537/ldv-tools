#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/rcupdate.h>

static int __init mod_init(void)
{
   // 11 nested lock
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();
   rcu_read_lock();

   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();
   rcu_read_unlock();

   return 0;
}

static void __exit mod_exit(void)
{
}

module_init(mod_init);
module_exit(mod_exit);
