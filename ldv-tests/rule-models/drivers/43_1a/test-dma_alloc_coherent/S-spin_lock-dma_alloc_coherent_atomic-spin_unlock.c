/*
 * Check that memory allocation with atomic value of GFP flags is safely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/dma-mapping.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	void *res;
	struct device dev;
	dma_addr_t dma_handle;

	spin_lock(&test_lock);
	res = dma_alloc_coherent(&dev, 10, &dma_handle, GFP_ATOMIC);
	spin_unlock(&test_lock);

	return 0;
}
