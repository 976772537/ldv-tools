#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

#define SUB_CLASS 3

MODULE_LICENSE( "GPL" );

static int __init
mod_init( void )
{
	spinlock_t lock;
	unsigned long flags;
	spin_lock_irqsave_nested(&lock, flags, SUB_CLASS);
	spin_lock_irq(&lock);
	spin_unlock_irqrestore(&lock, flags);
	spin_unlock_irq(&lock);

   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

