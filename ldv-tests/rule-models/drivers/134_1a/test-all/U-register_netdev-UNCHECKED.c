/*
 * Empty test for 134_1a rule model.
 */

#include <linux/module.h>
#include <linux/usb.h>
#include <linux/netdevice.h>

struct usb_driver *dummy_driver;
struct net_device *dummy_net_device;

int ldv_dummy_probe(struct usb_interface *interface,
			const struct usb_device_id *id)
{
	register_netdev(dummy_net_device);
	return 0;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
}
