/** 
 * The test checks that correct spin lock is safe on the models 39_1,39_2
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/list.h>
#include <linux/major.h>
#include <linux/fs.h>

static LIST_HEAD(my_list);
static LIST_HEAD(my_list2);

struct my_device {
	struct list_head list;
} mydev;

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static int misc_open(struct inode * inode, struct file * file)
{
	struct my_device mydev2;
	INIT_LIST_HEAD(&mydev.list);
	INIT_LIST_HEAD(&mydev2.list);
	list_add(&mydev.list, &my_list);
	list_add(&mydev2.list, &my_list);
	list_del(&mydev.list);
	list_del(&mydev2.list);
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

