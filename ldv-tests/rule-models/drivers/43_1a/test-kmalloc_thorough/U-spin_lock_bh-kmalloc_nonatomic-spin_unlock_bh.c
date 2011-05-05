/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin bh locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	spin_lock_bh(&test_lock);
	kmalloc(1, GFP_KERNEL);
	spin_unlock_bh(&test_lock);

	return 0;
}
