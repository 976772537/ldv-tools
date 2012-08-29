/*
 * 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include <linux/irq.h>
#include <linux/dmapool.h>

static struct my_struct
{
	const char *name;
	struct dma_pool *pool;
	unsigned int *irq;
	
};

static irqreturn_t my_func_irq(int irq, void *dev_id)
{
	dma_addr_t *dma;
	struct my_struct *ret;
	ret->pool = dma_pool_create("data", NULL, sizeof(struct my_struct), 0, 0);
	ret = dma_pool_alloc(ret->pool, GFP_ATOMIC, dma);
	return IRQ_HANDLED;
}


static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	struct my_struct *err;
	err->name = "struct_name";
	err = request_irq(err->irq, my_func_irq, IRQF_SHARED, err->name, err);
	return PTR_ERR(err);
}

static struct usb_driver my_usb_driver = {
	.name = "my usb irq",
	.probe = my_usb_probe,
}; 

static int __init my_init(void)
{
	int ret_val = usb_register(&my_usb_driver);
	return ret_val;
}

static void __exit my_exit(void)
{
	usb_deregister(&my_usb_driver);
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vladimir Gratinskiy <gratinskiy@ispras.ru>");
