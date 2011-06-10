/*
 * This is a common part of test cases for model 08_1a.
 */
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>

extern int misc_open(struct inode *, struct file *);

/* This function is defined here just to make Driver Environment Generator
 * produce its call. So a corresponding test case function is called too. 
 */ 
static int misc_open_aux(struct inode *inode, struct file *file)
{
	return misc_open(inode, file);
}

static const struct file_operations misc_fops = {
	.owner          = THIS_MODULE,
	.open           = misc_open_aux,
};

static int __init test_init(void)
{
	return register_chrdev(MISC_MAJOR, "misc", &misc_fops);
}

static void __exit test_exit(void)
{
}

module_init(test_init);
module_exit(test_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Evgeny Novikov <joker@ispras.ru>");
