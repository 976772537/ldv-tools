/** 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/major.h>
#include <linux/fs.h>

static DEFINE_MUTEX(my_lock);

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static int misc_open(struct inode * inode, struct file * file)
{
	return 0;
}

static int __init my_init(void)
{
	mutex_lock(&my_lock);
	return 0;
}

static void __exit my_exit(void)
{
	mutex_unlock(&my_lock);
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vadim Mutilin <mutilin@ispras.ru>");

