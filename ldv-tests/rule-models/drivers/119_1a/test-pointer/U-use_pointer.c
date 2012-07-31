/*
 * This driver have function fuse_get_req that can return -EINTR(void *)
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include <linux/file.h>
#include "asm-generic/errno-base.h" // Here there is definition of EINTR
#include "asm-generic/../../fs/fuse/fuse_i.h" //Here there is definition of function fuse_get_req and its structs and return value

// This is our function
static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	struct fuse_conn *fc;
	struct fuse_req *my_fuse;
	int rc;
	my_fuse = fuse_get_req(fc);
	if (IS_ERR(my_fuse))
	{
		rc = PTR_ERR(my_fuse);
		// Sometimes rc = -EINTR
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

