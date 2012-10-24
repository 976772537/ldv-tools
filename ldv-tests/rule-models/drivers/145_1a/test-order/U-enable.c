#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include <linux/clk.h>

static struct clk *clk;

static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	int ret = 1;
	struct device *dev;
	//we can't call this function here
	clk_enable(clk);
	clk = clk_get(dev, "phy");
	if(IS_ERR(clk))
	{
		ret = PTR_ERR(clk);
		goto err_clk;
	}
	clk_enable(clk);
	ret = 0;
	clk_disable(clk);
	clk_put(clk);
err_clk:
        return ret;
}

static struct usb_driver my_usb_driver = {
	.name = "my usb irq",
	.probe = my_usb_probe,
}; 

static int __init my_init(void)
{
	return usb_register(&my_usb_driver);
}

static void __exit my_exit(void)
{
	usb_deregister(&my_usb_driver);
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vladimir Gratinskiy <gratinskiy@ispras.ru>");
