/*
 * Check that memory allocation with atomic value of GFP flags is safely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/usb.h>

static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	struct urb *my_urb;
	spin_lock(&test_lock);
	my_urb = usb_alloc_urb(0, GFP_ATOMIC);
	spin_unlock(&test_lock);

	return 0;
}
