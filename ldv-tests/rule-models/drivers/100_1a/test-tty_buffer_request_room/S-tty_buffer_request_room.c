/*
 * Check that a function tty_buffer_request_room is called with a non-NULL
 * first actual parameter (tty). The test is for model 100_1a.
 */
#include <linux/usb.h>
#include <linux/slab.h>
#include <linux/tty.h>
#include <linux/tty_flip.h>

#define DUMMY_SIZE 100

static struct tty_struct *dummy_tty;

int ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id)
{
	int result = -EAGAIN;
	dummy_tty = kmalloc(sizeof (struct tty_struct), GFP_ATOMIC);
	if (dummy_tty) {
		result = tty_buffer_request_room(dummy_tty, DUMMY_SIZE);
	}
	return result;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
	if (dummy_tty) {
		kfree(dummy_tty);
	}
}
