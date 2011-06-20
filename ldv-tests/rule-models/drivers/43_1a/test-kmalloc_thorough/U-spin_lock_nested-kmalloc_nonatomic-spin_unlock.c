/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in nested spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	int subclass;

	spin_lock_nested(&test_lock, subclass);
	kmalloc(1, GFP_KERNEL);
	spin_unlock(&test_lock);

	return 0;
}
