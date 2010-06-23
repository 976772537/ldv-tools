/** 
 * The test checks that correct spin lock is safe on the models 39_1,39_2
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
	struct dma_pool *pool, pool2;
	dma_addr_t dma_handle;
	struct my_desc *item, item2;

        /* create a pool of consistent memory blocks */
        pool = dma_pool_create("my_desc_pool",
		&mydev, sizeof(struct my_desc),
		4 /* word alignment */, 0);
	if (!pool) {
		err = -ENOMEM;
		goto err_pool_create;
	}
	/* create a pool of consistent memory blocks */
        pool2 = dma_pool_create("my_desc_pool2",
		&mydev, sizeof(struct my_desc),
		4 /* word alignment */, 0);
	if (!pool2) {
		err = -ENOMEM;
		goto err_pool_create2;
	}

	item = dma_pool_alloc(pool, GFP_KERNEL, &dma_handle);
	if(!item) {
		err = -ENOMEM;
		goto err_pool_alloc;
	}
	dma_pool_free(pool, item, dma_handle);

        
	item2 = dma_pool_alloc(pool2, GFP_KERNEL, &dma_handle);
	if(!item2) {
		err = -ENOMEM;
		goto err_pool_alloc2;
	}
	dma_pool_free(pool2, item2, dma_handle);

	dma_pool_destroy(pool2);
	dma_pool_destroy(pool);
	return 0;

err_pool_alloc2:
err_pool_alloc:
	dma_pool_destroy(pool2);
err_pool_create2:
	dma_pool_destroy(pool);
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
MODULE_AUTHOR("LDV Project, Vedim Mutilin <mutilin@ispras.ru>");

