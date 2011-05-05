/*
 * Check that memory allocation with nonatomic value of GFP flags is safely 
 * performed in failing spin irq try lock for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	/* If spin_trylock_irq returns 0 then lock wasn't acquired. */
	if (!spin_trylock_irq(&test_lock))
		kmalloc(1, GFP_KERNEL);
	else
		spin_unlock_irq(&test_lock);

	return 0;
}
