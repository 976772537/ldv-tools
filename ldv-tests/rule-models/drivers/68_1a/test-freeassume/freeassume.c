/** 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/usb.h>

struct my_device {
	struct module mod;
} mydev;

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

struct my_data {
	struct urb *u;
};

static int misc_open(struct inode * inode, struct file * file)
{
	struct my_data d;
	d.u = usb_alloc_urb(0, GFP_KERNEL);
	if(d.u==0) {
		//free should not fail
		//even if it does not know that d.u==0
		usb_free_urb(d.u);
		usb_free_urb(d.u);
	} else {
		//safe
		usb_free_urb(d.u);
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

