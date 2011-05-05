/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin nested irqsave locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	unsigned long flags;
	int subclass;

	spin_lock_irqsave_nested(&test_lock, flags, subclass);
	kmalloc(1, GFP_KERNEL);
	spin_unlock_irqrestore(&test_lock, flags);

	return 0;
}
