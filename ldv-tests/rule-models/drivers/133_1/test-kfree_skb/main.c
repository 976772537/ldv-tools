/*
 * This is a common part of test cases for model 133_1.
 */
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>

extern int ldv_dummy_init(void);
extern void ldv_dummy_exit(void);

/* This function is defined here just to make Driver Environment Generator
 * produce its call. So a corresponding test case function is called too. 
 */ 
static int ldv_dummy_open_aux(struct inode *inode, struct file *file)
{
	return 0;
}
static int ldv_dummy_close_aux(struct inode *inode, struct file *file)
{
	return 0;
}

static const struct file_operations misc_fops = {
	.owner          = THIS_MODULE,
	.open           = ldv_dummy_open_aux,
	.release        = ldv_dummy_close_aux,
};

static int __init ldv_dummy_init_aux(void)
{
	int result = register_chrdev(MISC_MAJOR, "misc", &misc_fops);
	if (result)
		return result;
	ldv_dummy_init();
}

static void __exit ldv_dummy_exit_aux(void)
{
	ldv_dummy_exit();
}

module_init(ldv_dummy_init_aux);
module_exit(ldv_dummy_exit_aux);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Mikhail Mandrykin <joker@ispras.ru>");
