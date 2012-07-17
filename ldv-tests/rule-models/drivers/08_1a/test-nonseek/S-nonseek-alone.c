/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/module.h>


int misc_open(struct inode *inode, struct file *file)
{
	struct module* sample;
	if (nonseekable_open(inode,file) != 0)
		__module_get(sample);

	return 0;
}

int misc_close(struct inode * inode, struct file * file)
{
	return 0;
}

