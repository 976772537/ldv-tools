/*
 * Check that a function tty_encode_baud_rate is called with a NULL
 * first actual parameter (tty). The test is for model 100_1a.
 */
#include <linux/usb.h>
#include <linux/slab.h>
#include <linux/tty.h>
#include <linux/tty_flip.h>

#define DUMMY_IBAUD 32
#define DUMMY_OBAUD 32

struct tty_port *dummy_source_tty_port;
static struct tty_struct *dummy_tty;

int ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id)
{
	dummy_tty = tty_port_tty_get(dummy_source_tty_port);
	tty_encode_baud_rate(dummy_tty, DUMMY_IBAUD, DUMMY_OBAUD);
	return 0;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
	if (dummy_tty) {
		kfree(dummy_tty);
	}
}
