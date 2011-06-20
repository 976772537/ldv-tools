/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin locking in different functions for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>


static DEFINE_SPINLOCK(test_lock);


static void test_kmalloc (gfp_t flags)
{
	kmalloc(1, flags);
}

int misc_open(struct inode *inode, struct file *file)
{
	spin_lock(&test_lock);
	test_kmalloc(GFP_KERNEL);
	spin_unlock(&test_lock);

	return 0;
}
