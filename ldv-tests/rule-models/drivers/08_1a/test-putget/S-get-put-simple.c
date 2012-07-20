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

	if (try_module_get(sample)){
		// success
		// do put!
		module_put(sample);
	}else{
		// failure
		// do not put
		// module_put(sample);
	}
	return 0;
}
