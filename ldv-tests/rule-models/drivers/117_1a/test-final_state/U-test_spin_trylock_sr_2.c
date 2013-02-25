#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

MODULE_LICENSE( "GPL" );

static int __init
mod_init( void )
{
   spinlock_t lock;
   unsigned long flags;
   int res;
   res = spin_trylock_irqsave(&lock, flags);
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

