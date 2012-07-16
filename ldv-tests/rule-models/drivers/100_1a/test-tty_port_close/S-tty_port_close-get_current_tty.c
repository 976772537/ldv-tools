/*
 * Check that a function tty_port_close is called with a non-NULL
 * first actual parameter (tty). The test is for model 100_1a.
 */
#include <linux/usb.h>
#include <linux/slab.h>
#include <linux/tty.h>
#include <linux/tty_flip.h>
#include <linux/fs.h>

static struct tty_struct *dummy_tty;
static struct tty_port dummy_tty_port;
static struct file dummy_file;

int ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id)
{
	dummy_tty = get_current_tty();
	if (dummy_tty) {
		tty_port_close(&dummy_tty_port, dummy_tty, &dummy_file);
	}
	return 0;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
	if (dummy_tty) {
		kfree(dummy_tty);
	}
}
