/**
linux-2.6.37	68_1	drivers/hid/usbhid/usbmouse.ko	ldv_main0_sequence_infinite_withcheck_stateful
(false unsafe:savedata)
usb_alloc_urb without free 
usb_mouse_disconnect does not call usb_free_urb(mouse->irq)
In disconnect: BLAST does not know that mouse must not be zero
mouse = usb_get_intfdata (intf)
assert (mouse==0) 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/usb.h>

struct my_device {
	struct module mod;
} mydev;

static int my_usb_open(struct inode * inode, struct file * file);
//static void my_usb_close(struct input_dev *dev);

static void my_usb_disconnect(struct usb_interface *intf);
static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id);

static const struct file_operations my_fops = {
        .owner          = THIS_MODULE,
        .open           = my_usb_open,
        //.close           = my_usb_close,
};

static struct usb_driver my_usb_driver = {
	.name = "usbmouse",
	.probe = my_usb_probe, 
	.disconnect = my_usb_disconnect,
	//.id_table = my_usb_id_table,
}; 

static int my_usb_open(struct inode * inode, struct file * file)
{
	return 0;
}

struct my_usb_data {
	struct urb *irq;
};

static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	struct my_usb_data *mouse;
	int error = -ENOMEM; 
	mouse = kzalloc(sizeof(struct my_usb_data), GFP_KERNEL);
	
	if (!mouse) 
		goto fail1;
	mouse->irq = usb_alloc_urb(0, GFP_KERNEL); 
	if (!mouse->irq) 
		goto fail1;
 
	usb_set_intfdata(intf, mouse);
	return 0;
fail1:  
	kfree(mouse); 
	return error; 
}

static void my_usb_disconnect(struct usb_interface *intf) {
	struct my_usb_data *mouse = usb_get_intfdata (intf); 
	usb_set_intfdata(intf, NULL);
	if (mouse) {
		usb_free_urb(mouse->irq);
		kfree(mouse);
	}
}

static int __init my_init(void)
{
	int retval = usb_register(&my_usb_driver);
	return retval;
}

static void __exit my_exit(void)
{
	usb_deregister(&my_usb_driver);
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vadim Mutilin <mutilin@ispras.ru>");

