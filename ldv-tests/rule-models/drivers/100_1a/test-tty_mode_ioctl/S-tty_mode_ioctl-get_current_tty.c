/*
 * Check that a function tty_mode_ioctl is called with a non-NULL
 * first actual parameter (tty). The test is for model 100_1a.
 */
#include <linux/usb.h>
#include <linux/slab.h>
#include <linux/tty.h>
#include <linux/tty_flip.h>
#include <linux/fs.h>

#define DUMMY_CMD 0
#define DUMMY_ARG 0

static struct tty_struct *dummy_tty;
static struct file dummy_file;

int ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id)
{
	int result = -EAGAIN;
	dummy_tty = get_current_tty();
	if (dummy_tty) {
		result = tty_mode_ioctl(dummy_tty, &dummy_file, DUMMY_CMD, DUMMY_ARG);
	}
	return result;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{
	if (dummy_tty) {
		kfree(dummy_tty);
	}
}
