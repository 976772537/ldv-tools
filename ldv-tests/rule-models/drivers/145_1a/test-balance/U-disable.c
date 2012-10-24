#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include <linux/clk.h>

static struct clk *clk1;
static struct clk *clk2;
static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	int ret = 1;
	struct device *dev;
	clk1 = clk_get(dev, "phy");
	clk2 = clk_get(dev, "psy");
	if(IS_ERR(clk1))
	{
		ret = PTR_ERR(clk1);
		goto err_clk1;
	}
	if(IS_ERR(clk2))
	{
		ret = PTR_ERR(clk2);
		goto err_clk2;
	}
	//clk_enable(clk1);
	ret = 0;
	clk_disable(clk1);
	clk_put(clk1);
err_clk1:
	if(IS_ERR(clk2))
		return ret;
	clk_put(clk2);
        return ret;
err_clk2:
	clk_put(clk1);
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
