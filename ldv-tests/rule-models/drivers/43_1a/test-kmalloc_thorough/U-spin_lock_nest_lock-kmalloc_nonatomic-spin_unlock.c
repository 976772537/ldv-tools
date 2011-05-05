/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in nest lock spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/rwsem.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	struct rw_semaphore *semaphore;

	spin_lock_nested(&test_lock, semaphore);
	kmalloc(1, GFP_KERNEL);
	spin_unlock(&test_lock);

	return 0;
}
