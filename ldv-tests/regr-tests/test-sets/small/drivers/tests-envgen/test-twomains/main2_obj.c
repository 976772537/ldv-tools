/** 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/major.h>
#include <linux/fs.h>

static DEFINE_SPINLOCK(my_lock2);

static int misc_open2(struct inode * inode, struct file * file);

static const struct file_operations misc_fops2 = {
        .owner          = THIS_MODULE,
        .open           = misc_open2,
};

static int misc_open2(struct inode * inode, struct file * file)
{
	return 0;
}

static int __init my_init2(void)
{
	spin_lock(&my_lock2);
	return 0;
}

static void __exit my_exit2(void)
{
	unsigned long flags;
	spin_lock_irqsave(&my_lock2, flags);
}

