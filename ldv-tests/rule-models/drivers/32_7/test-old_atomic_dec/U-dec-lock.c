/*
 * Check if atomic_dec_and_mutex_lock is instrumented
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/mutex.h>


int misc_open(struct inode *inode, struct file *file)
{
	atomic_t *ato;
	struct mutex *lock;

	if (atomic_dec_and_mutex_lock(ato,lock)){
		// Do not unlock -- let's fail at the end.
		//mutex_unlock(lock);
	}

	return 0;
}

int misc_close(struct inode * inode, struct file * file)
{
	return 0;
}

