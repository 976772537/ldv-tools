/** 
  *  The test checks that correct sysfs_attr_init is safe on the model 130_1a
 **/
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/sysfs.h>
#include <linux/device.h>

static DEVICE_ATTR(test, S_IRUGO, NULL, NULL);
static DEVICE_ATTR(test2, S_IRUGO, NULL, NULL);
struct device *dev;

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static int misc_open(struct inode * inode, struct file * file)
{
	int err;

	err = device_create_file(dev, &dev_attr_test);
	if (err)
		return -1;
	err = device_create_file(dev, &dev_attr_test2);
	if (err)
		return -1;
 
	/* TODO: without model for device_remove_file() this test will be Unsafe. */
	return -1;
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

