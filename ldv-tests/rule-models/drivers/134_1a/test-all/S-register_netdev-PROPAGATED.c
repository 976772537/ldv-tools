/*
 * A safe test for 134_1a rule model correctly propagating register_netdev return value.
 */

#include <linux/module.h>
#include <linux/usb.h>
#include <linux/netdevice.h>

struct usb_driver *dummy_driver;
struct net_device *dummy_net_device;

int ldv_dummy_probe(struct usb_interface *interface,
			const struct usb_device_id *id)
{
	int ret = register_netdev(dummy_net_device);
	if (ret < 0) {
		return ret;
	}
	return 0;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
}
