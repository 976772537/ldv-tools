/*
 * Check that memory allocation with nonatomic value of GFP flags is safely 
 * performed in failing atomic decrement and spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	atomic_t *atomic;

	/* If atomic_dec_and_lock returns 0 then lock wasn't acquired. */
	if (!atomic_dec_and_lock(atomic, &test_lock))
		kmalloc(1, GFP_KERNEL);
	else
		spin_unlock(&test_lock);

	return 0;
}
