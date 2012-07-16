/*
 * Check that a function tty_get_baud_rate is called with a non-NULL
 * first actual parameter (tty). The test is for model 100_1a.
 */
#include <linux/usb.h>
#include <linux/slab.h>
#include <linux/tty.h>
#include <linux/tty_flip.h>

struct tty_port *dummy_source_tty_port;
static struct tty_struct *dummy_tty;

int ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id)
{
	int result = -EAGAIN;
	dummy_tty = tty_port_tty_get(dummy_source_tty_port);
	if (dummy_tty) {
		tty_get_baud_rate(dummy_tty);
	}
	return result;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
	if (dummy_tty) {
		kfree(dummy_tty);
	}
}
