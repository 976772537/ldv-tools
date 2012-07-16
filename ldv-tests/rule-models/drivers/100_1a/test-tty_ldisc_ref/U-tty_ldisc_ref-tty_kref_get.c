/*
 * Check that a function tty_ldisc_ref is called with a NULL
 * first actual parameter (tty). The test is for model 100_1a.
 */
#include <linux/usb.h>
#include <linux/slab.h>
#include <linux/tty.h>
#include <linux/tty_flip.h>
#include <linux/tty_ldisc.h>

struct tty_struct *dummy_source_tty;
static struct tty_struct *dummy_tty;

int ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id)
{
	struct tty_ldisc *result;
	dummy_tty = tty_kref_get(dummy_source_tty);
	result = tty_ldisc_ref(dummy_tty);
	return result;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
	if (dummy_tty) {
		kfree(dummy_tty);
	}
}
