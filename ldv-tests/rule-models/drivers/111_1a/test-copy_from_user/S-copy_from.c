/*
 * 
 */
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <asm/uaccess.h>

struct module* sample;

int misc_open(struct inode *inode, struct file *file)
{
	__module_get(sample);
	int err;
	char ps_name[] = "hello, error!";
	char ps_str[30];
	int len = 500;
	err = copy_from_user(ps_name, ps_str, len);
	if(err)
	{
		return -EFAULT;
	}
	return 0;
}

int misc_close(struct inode * inode, struct file * file)
{
	module_put(sample);
	return 0;
}
static int misc_open_aux(struct inode *inode, struct file *file)
{
	return misc_open(inode, file);
}
static int misc_close_aux(struct inode *inode, struct file *file)
{
	return misc_close(inode, file);
}

static const struct file_operations misc_fops = {
	.owner          = THIS_MODULE,
	.open           = misc_open_aux,
	.release        = misc_close_aux,
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
MODULE_AUTHOR("LDV Project, Vladimir Gratinskiy <gratinskiy@ispras.ru>");
