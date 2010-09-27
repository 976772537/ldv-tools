/** 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/dmapool.h>

struct device mydev;

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
	int err;
	struct dma_pool *pool;
	dma_addr_t dma_handle;
	struct my_desc *item;

        /* create a pool of consistent memory blocks */
        pool = dma_pool_create("my_desc_pool",
		&mydev, sizeof(struct my_desc),
		4 /* word alignment */, 0);
	if (!pool) {
		err = -ENOMEM;
		goto err_pool_create;
	}
	dma_pool_destroy(pool);
	dma_pool_destroy(pool);
	return 0;

err_pool_create:
	return err;
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

