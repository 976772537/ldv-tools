/*
 * Check that memory allocation with nonatomic value of GFP flags is unsafely 
 * performed in spin locking for model 43_1a.
 */
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/spinlock.h>
#include <linux/vmalloc.h>

static DEFINE_SPINLOCK(test_lock);

struct A {
	int a,b;
};

int misc_open(struct inode *inode, struct file *file)
{
	struct A *sc;
	int node;
	spin_lock(&test_lock);
	sc = vzalloc_node(sizeof(struct A), node);
	spin_unlock(&test_lock);

	return 0;
}
