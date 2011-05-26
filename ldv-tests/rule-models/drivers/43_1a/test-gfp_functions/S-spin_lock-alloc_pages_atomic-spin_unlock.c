/*
 * Check that memory allocation with atomic value of GFP flags is safely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/gfp.h>

static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	struct page *p;

	spin_lock(&test_lock);
	p = alloc_pages(GFP_ATOMIC, get_order(23));
	spin_unlock(&test_lock);

	return 0;
}
