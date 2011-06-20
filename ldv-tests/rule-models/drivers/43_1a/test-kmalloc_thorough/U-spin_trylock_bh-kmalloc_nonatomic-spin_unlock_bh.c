/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in successfull spin bh try lock for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	/* If spin_trylock_bh returns 0 then lock wasn't acquired. */
	if (spin_trylock_bh(&test_lock))
		{
			kmalloc(1, GFP_KERNEL);
			spin_unlock_bh(&test_lock);
		}

	return 0;
}
