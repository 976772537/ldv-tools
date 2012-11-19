#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/err.h>
#include <linux/netdevice.h>

#define IS_ERR_OR_NULL_assert(ret) ret = 0
#define ERR_PTR_assert(ret) return 0

static struct net_device *test_err;
static struct net_device *test_err2;


static struct net_device *ERR_undef_ptr(void)
{
	return test_err2;
}

static int misc_open(struct inode * inode, struct file * file)
{
	int ret = 0;
	
	test_err = ERR_undef_ptr();
	if (IS_ERR_OR_NULL(test_err))
	{
		test_err2 = ERR_PTR(-EINVAL);
		ERR_PTR_assert(test_err2);
		return 0;
	}
	IS_ERR_OR_NULL_assert(ret);
	
	return ret;
}

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

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
