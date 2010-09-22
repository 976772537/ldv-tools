/**
 * The test demonstrates that 37_1 model can't check multiple locks when field names are equal.
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/major.h>
#include <linux/fs.h>

/* The same name as field of struct inode has */
static DEFINE_MUTEX(i_mutex);

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static void alock(void) {
	mutex_lock(&i_mutex);
	mutex_unlock(&i_mutex);
}

static int misc_open(struct inode * inode, struct file * file)
{
	mutex_lock(&inode->i_mutex);
	alock();
	mutex_unlock(&inode->i_mutex);
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

