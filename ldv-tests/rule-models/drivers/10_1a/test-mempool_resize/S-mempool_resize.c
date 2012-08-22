/*
 * 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include <linux/irq.h>
#include <linux/mempool.h>

static struct my_struct
{
	const char *name;
	mempool_t *pool;
	unsigned int *irq;
	int *min_nr;
	
};

static irqreturn_t my_func_irq(int irq, void *dev_id)
{
	struct my_struct *ret;
	int res;
	res = mempool_resize(ret->pool, ret->min_nr, GFP_ATOMIC);
	if(!res)
		return 0;
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
