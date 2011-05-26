/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/usb.h>

static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	struct urb my_urb;
	int res;
	spin_lock(&test_lock);
	res = usb_submit_urb(&my_urb, GFP_KERNEL);
	spin_unlock(&test_lock);

	return 0;
}
