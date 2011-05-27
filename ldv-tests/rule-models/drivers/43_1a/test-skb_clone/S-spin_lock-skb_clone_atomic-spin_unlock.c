/*
 * Check that memory allocation with atomic value of GFP flags is safely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/skbuff.h>


static DEFINE_SPINLOCK(test_lock);


int misc_open(struct inode *inode, struct file *file)
{
	struct sk_buff *skb;

	spin_lock(&test_lock);
	skb_clone(skb, GFP_ATOMIC);
	spin_unlock(&test_lock);

	return 0;
}
