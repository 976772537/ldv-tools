/** 
  *  The test checks that correct usb_lock_device_for_reset() is safe on the model 77_1
 **/
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/usb.h>
#include <linux/slab.h>
 
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
	struct my_desc *i;
	struct usb_device mydev;
	const struct usb_interface myface;
	int temp;
	
	temp = usb_lock_device_for_reset(&mydev, &myface);
	i = kmalloc(sizeof(struct my_desc),GFP_NOIO);
	if (temp == 0)
	  usb_unlock_device(&mydev);
	
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
MODULE_AUTHOR("LDV Project, Ilya Shchepetkov <shchepetkov@ispras.ru>");

