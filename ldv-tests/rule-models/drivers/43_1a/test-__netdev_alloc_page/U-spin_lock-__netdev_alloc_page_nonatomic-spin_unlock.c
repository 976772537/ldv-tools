/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/skbuff.h>
#include <linux/net.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	struct net_device *dev;

	spin_lock(&test_lock);
	__netdev_alloc_page(dev, GFP_KERNEL);
	spin_unlock(&test_lock);

	return 0;
}
