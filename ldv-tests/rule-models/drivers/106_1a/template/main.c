/*
 * This is a common part of test cases for model 106_1a.
 */
#include <linux/module.h>
#include <linux/major.h>
#include <linux/usb.h>

extern int ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id);
extern void ldv_dummy_disconnect(struct usb_interface *interface);

static int usb_ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id);

static void usb_ldv_dummy_disconnect(struct usb_interface *interface);

static const struct usb_device_id id_table[] = {
	{ }                     /* Terminating entry */
};

static const struct usb_driver ldv_dummy_driver = {
	.name =         "ldv_dummy",
	.probe =        usb_ldv_dummy_probe,
	.disconnect =   usb_ldv_dummy_disconnect,
	.id_table =     id_table,
};

/* This function are defined here just to make Driver Environment Generator
 * produce their calls. So corresponding test case functions are called too.
 */
static int usb_ldv_dummy_probe(struct usb_interface *interface,
				const struct usb_device_id *id)
{
	return ldv_dummy_probe(interface, id);
}

static void usb_ldv_dummy_disconnect(struct usb_interface *interface)
{
	ldv_dummy_disconnect(interface);
}

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Mikhail Mandrykin <mandrykin@ispras.ru>");
