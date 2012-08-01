/*
 * This driver use function usb_lock_device_for_reset(..) that can return -EINTR
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include "asm-generic/errno-base.h" // Here there is definition of EINTR

// This is our function
static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	struct hso_device *hso_dev;
	struct usb_device *usb;
	int result;
	result = usb_lock_device_for_reset(usb, intf);
	// We skip return value = -EINTR
	if(result == -EINTR)
	{
		return 0;
	}
	return -ENOMEM;
}

// This struct have function probe()
static struct usb_driver my_usb_driver = {
	.name = "my usb 3",
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

