/** 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/major.h>
#include <linux/fs.h>

static DEFINE_MUTEX(my_lock2);

static int misc_open2(struct inode * inode, struct file * file);

static const struct file_operations misc_fops2 = {
        .owner          = THIS_MODULE,
        .open           = misc_open2,
};

static int misc_open2(struct inode * inode, struct file * file)
{
	mutex_lock(&my_lock2);
	return 0;
}

static int __init my_init2(void)
{
	mutex_lock(&my_lock2);
	return 0;
}

static void __exit my_exit2(void)
{
	mutex_unlock(&my_lock2);
}

module_init(my_init2);
module_exit(my_exit2);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vadim Mutilin <mutilin@ispras.ru>");

