/*
 * This driver use export function that doesn't return -EINTR
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include "asm-generic/errno-base.h" // Here there is definition of EINTR

// This is our function
static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	int ret;
	ret = usb_disabled();
	if(ret)
		return ret;
	else
		goto error;
error:
	return -ENOMEM;
}

// This struct have function probe()
static struct usb_driver my_usb_driver = {
	.name = "my usb 1",
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

