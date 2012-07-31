/*
 * This driver use function that return pointer that is transformed to 'long' by function PTR_ERR.
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include <linux/file.h>
#include "asm-generic/errno-base.h" // Here there is definition of EINTR

// This is our function
static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	struct usb_interface *intf_get;
	int rc;
	// Function usb_get_intf(..) skiped by rule 119_1a becouse it cann't return ERR_PTR(-EINTR)
	intf_get = usb_get_intf(intf);
	// If intf_get doesn't point to memory space
	if (IS_ERR(intf_get))
	{
		// Sometimes rc can be equal to -EINTR
		rc = PTR_ERR(intf_get);
		return rc;
	}
	return -ENXIO; 
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

