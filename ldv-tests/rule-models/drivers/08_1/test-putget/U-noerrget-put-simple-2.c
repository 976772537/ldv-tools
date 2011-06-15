/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/module.h>

int misc_open(struct inode *inode, struct file *file)
{
	struct module *sample;

	__module_get(sample);
	// get one more time but put only once
	__module_get(sample);
	module_put(sample);

	return 0;
}

