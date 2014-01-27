#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/rcupdate.h>

MODULE_LICENSE( "GPL" );

void *test_pointer;

static int __init
mod_init( void )
{
   void *p;
   int idx;
   struct srcu_struct *sp = sp;

   rcu_read_lock();
   rcu_read_lock_bh();
   rcu_read_lock_sched();
   srcu_read_lock(sp);
      p = rcu_dereference( test_pointer );
   rcu_read_unlock();
      p = rcu_dereference_bh( test_pointer );
   rcu_read_unlock_bh();
      p = rcu_dereference_sched( test_pointer );
   rcu_read_unlock_sched();
      p = srcu_dereference(test_pointer, sp);
   srcu_read_unlock(sp, idx);
  
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

