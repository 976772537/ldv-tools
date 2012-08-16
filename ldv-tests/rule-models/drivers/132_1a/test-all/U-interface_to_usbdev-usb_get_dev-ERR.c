/*
 * An unsafe test with successful probe for 132_1a rule model.
 */
#include <linux/usb.h>
#include <linux/slab.h>

struct usb_device *dummy_udev_ref;

int ldv_dummy_probe(struct usb_interface *interface,
			const struct usb_device_id *id)
{
	struct usb_device *udev;
	void *err_ptr;
	udev = interface_to_usbdev(interface);
	dummy_udev_ref = usb_get_dev(udev);
	while(!IS_ERR(err_ptr));
	return PTR_ERR(err_ptr);
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
}
