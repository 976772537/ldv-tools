/*
 * Check that memory allocation with nonatomic value of GFP flags is safely 
 * performed for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>


int misc_open(struct inode *inode, struct file *file)
{
	kmalloc(1, GFP_KERNEL);

	return 0;
}
