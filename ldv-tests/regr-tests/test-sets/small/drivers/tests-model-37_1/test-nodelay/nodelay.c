/** 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/interrupt.h>

struct my_device {
	struct module mod;
} mydev;

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};


static int misc_open(struct inode * inode, struct file * file)
{
	long mask;
	int res;
	mask = probe_irq_on();
	res = probe_irq_off(mask);
	
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

