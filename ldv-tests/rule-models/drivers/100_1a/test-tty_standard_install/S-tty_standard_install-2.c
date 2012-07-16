/*
 * Check that a function tty_standard_install is called with a NULL
 * first actual parameter (tty). The test is for model 100_1a.
 */
#include <linux/usb.h>
#include <linux/slab.h>
#include <linux/tty.h>
#include <linux/tty_flip.h>
#include <linux/tty_driver.h>

static struct tty_struct *dummy_tty;
static struct tty_driver dummy_tty_driver;

int ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id)
{
	dummy_tty = kmalloc(sizeof (struct tty_struct), GFP_ATOMIC);
	tty_standard_install(&dummy_tty_driver, dummy_tty);
	return 0;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
	if (dummy_tty) {
		kfree(dummy_tty);
	}
}
