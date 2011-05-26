/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/dma-mapping.h>
#include <linux/dmapool.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	void *res;
	struct dma_pool *pool;
	dma_addr_t dma_handle;

	spin_lock(&test_lock);
	res = dma_pool_alloc(pool, GFP_KERNEL, &dma_handle);
	spin_unlock(&test_lock);

	return 0;
}
