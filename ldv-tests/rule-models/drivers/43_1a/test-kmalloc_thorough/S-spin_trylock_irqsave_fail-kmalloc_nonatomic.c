/*
 * Check that memory allocation with nonatomic value of GFP flags is safely 
 * performed in failing spin irqsave try lock for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	unsigned long flags;

	/* If spin_trylock_irqsave returns 0 then lock wasn't acquired. */
	if (!spin_trylock_irqsave(&test_lock, flags))
		kmalloc(1, GFP_KERNEL);
	else
		spin_unlock_irqrestore(&test_lock, flags);

	return 0;
}
