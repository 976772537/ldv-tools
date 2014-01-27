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
   
   srcu_read_lock(sp);
   srcu_read_unlock(sp, idx);
   srcu_read_unlock(sp, idx);
  
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

