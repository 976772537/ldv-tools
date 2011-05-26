/*
 * Check that memory allocation with atomic value of GFP flags is safely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/usb.h>

static DEFINE_SPINLOCK(test_lock);


struct A {
	int a,b;
};

int misc_open(struct inode *inode, struct file *file)
{
	struct device *dev;
	dma_addr_t *dma_handle;
	void *my_res;
	spin_lock(&test_lock);
	my_res = usb_alloc_coherent(dev, sizeof(struct A), GFP_ATOMIC, dma_handle);
	spin_unlock(&test_lock);

	return 0;
}
