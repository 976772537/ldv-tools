/**
 * The test checks model of mutex_is_locked. Should be safe.
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/major.h>
#include <linux/fs.h>

static DEFINE_MUTEX(i_mutex);

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static int misc_open(struct inode * inode, struct file * file)
{
	int is_locked = mutex_is_locked(i_mutex);
	if(is_locked) {
		mutex_unlock(i_mutex);
	} else {
		mutex_lock(i_mutex);
		mutex_unlock(i_mutex);
	}
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
MODULE_AUTHOR("LDV Project, Vadim Mutilin <mutilin@ispras.ru>");

