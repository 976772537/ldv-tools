/*
 * Check that memory allocation with nonatomic value of GFP flags is safely 
 * performed on spin irqsave unlocking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	unsigned long flags;

	spin_lock_irqsave(&test_lock, flags);
	spin_unlock_irqrestore(&test_lock, flags);
	kmalloc(1, GFP_KERNEL);

	return 0;
}
