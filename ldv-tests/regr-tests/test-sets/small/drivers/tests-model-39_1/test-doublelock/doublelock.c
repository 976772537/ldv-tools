/** 
 * The test checks that double spin lock is detected on the models 39_1,39_2
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/major.h>
#include <linux/fs.h>

static DEFINE_SPINLOCK(my_lock);

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static void alock(void) {
	unsigned long flags;
	spin_lock_irqsave(&my_lock, flags);
	spin_unlock_irqrestore(&my_lock, flags);
}

static int misc_open(struct inode * inode, struct file * file)
{
	unsigned long flags;
	spin_lock_irqsave(&my_lock, flags);
	alock();
	spin_unlock_irqrestore(&my_lock, flags);
	return 0;
}

static int __init my_init(void)
{
	if (register_chrdev(MISC_MAJOR,"misc",&misc_fops))
		goto fail_register;
	return 0;
	
fail_register:
	return -1;
}

static void __exit my_exit(void)
{
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vedim Mutilin <mutilin@ispras.ru>");

