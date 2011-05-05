/*
 * Check that memory allocation with atomic value of GFP flags is safely 
 * performed for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>


int misc_open(struct inode *inode, struct file *file)
{
	kmalloc(1, GFP_ATOMIC);

	return 0;
}
