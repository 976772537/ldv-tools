/*
 * Check that memory allocation with atomic value of GFP flags is safely 
 * performed in failing spin try lock for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	/* If spin_trylock returns 0 then lock wasn't acquired. */
	if (!spin_trylock(&test_lock))
		kmalloc(1, GFP_ATOMIC);
	else
		spin_unlock(&test_lock);

	return 0;
}
