/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/module.h>

struct module* sample;

int misc_open(struct inode *inode, struct file *file)
{
	__module_get(sample);

	// nonseekable_open should always return 0; let's see if it's instrumented.  If it's not, then misc_close won't be called, and we'll get an error (sample: drivers/isdn/mISDN/mISDN_core.ko
	return nonseekable_open(inode,file);
}

int misc_close(struct inode * inode, struct file * file)
{
	module_put(sample);
	return 0;
}

