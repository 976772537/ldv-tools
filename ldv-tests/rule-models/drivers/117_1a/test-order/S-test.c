#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

#define CDEV_NESTED_SECOND 2

MODULE_LICENSE( "GPL" );

static int __init
mod_init( void )
{
   unsigned long flags;
   spinlock_t lock;

   local_irq_disable();
      local_irq_save( flags );
      local_irq_restore( flags );
   local_irq_enable();
   
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_restore( flags );
   local_irq_restore( flags );
   local_irq_restore( flags );
   local_irq_restore( flags );
   local_irq_restore( flags );
   spin_unlock_irqrestore(&lock, flags);
   spin_unlock_irqrestore(&lock, flags);

   spin_lock_irq(&lock);
   spin_unlock_irq(&lock);

        spin_lock_irq(&lock);
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_save( flags );
   local_irq_save( flags );
   spin_unlock_irqrestore(&lock, flags);
   spin_unlock_irqrestore(&lock, flags);
   spin_unlock_irqrestore(&lock, flags);
   spin_unlock_irqrestore(&lock, flags);
   spin_unlock_irqrestore(&lock, flags);
	spin_unlock_irq(&lock);

   spin_lock_irqsave(&lock, flags);
   local_irq_save( flags );
   spin_lock_irqsave(&lock, flags);
   local_irq_save( flags );
   spin_lock_irqsave(&lock, flags);
   local_irq_save( flags );
   spin_lock_irqsave(&lock, flags);
   spin_unlock_irqrestore(&lock, flags);
   spin_unlock_irqrestore(&lock, flags);
   local_irq_restore( flags );
   spin_unlock_irqrestore(&lock, flags);
   spin_unlock_irqrestore(&lock, flags);
   local_irq_restore( flags );
   spin_unlock_irqrestore(&lock, flags);

   if(spin_trylock_irq(&lock))
   {
	spin_unlock_irq(&lock);
   }

   spin_lock_irqsave_nested(&lock, flags, CDEV_NESTED_SECOND);
   spin_unlock_irqrestore(&lock, flags);
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

