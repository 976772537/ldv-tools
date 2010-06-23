/** 
 * The test checks that correct spin lock is safe on the models 39_1,39_2
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/major.h>
#include <linux/fs.h>

static DEFINE_SPINLOCK(my_lock);

struct my_desc {
	int a,b;
};

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static int misc_open(struct inode * inode, struct file * file)
{
	unsigned long flags;
	struct my_desc *d, *d2;
	spin_lock(&my_lock);
	d = kmalloc(sizeof(struct my_desc),GFP_KERNEL);
	spin_unlock(&my_lock);
	spin_lock_irqsave(&my_lock, flags);
	d2 = kmalloc(sizeof(struct my_desc),GFP_KERNEL);	
	spin_unlock_irqrestore(&my_lock, flags);
	kfree(d);
	kfree(d2);
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

