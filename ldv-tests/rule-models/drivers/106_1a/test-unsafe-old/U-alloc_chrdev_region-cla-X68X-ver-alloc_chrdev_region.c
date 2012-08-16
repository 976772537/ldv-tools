/*
 * Template file for test generator (rule model 106_1a).
 * 
 */
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
#include <linux/slab.h>

#include <linux/device.h>

#include <linux/types.h>
#include <linux/fs.h>
#include <linux/usb/gadget.h>

#define DUMMY_BASEMINOR 0
#define DUMMY_COUNT 1

#define ASSURE_SUCCESS(E) while((E))
#define ASSURE_SUCCESS_PTR(E) while((IS_ERR(E)))
#define ASSURE_ERROR(E) if(!(E)) while(1)
#define ASSURE_ERROR_PTR(E) if(!(IS_ERR(E))) while(1)

struct module *dummy_module;
const char *dummy_name ="ldv_dummy_name";
struct class *dummy_class;
dev_t *dummy_dev;
struct usb_gadget_driver *dummy_driver;
int (*dummy_bind)(struct usb_gadget *);

int ldv_dummy_probe(struct usb_interface *interface,
			const struct usb_device_id *id)
{
	int result = 0;

	ASSURE_SUCCESS(result = alloc_chrdev_region(dummy_dev, DUMMY_BASEMINOR, DUMMY_COUNT, dummy_name));
	ASSURE_SUCCESS_PTR(dummy_class = class_create(dummy_module, dummy_name));
	unregister_chrdev_region(*dummy_dev, DUMMY_COUNT);
	ASSURE_SUCCESS(result = usb_gadget_register_driver(dummy_driver));
	ASSURE_ERROR(result = alloc_chrdev_region(dummy_dev, DUMMY_BASEMINOR, DUMMY_COUNT, dummy_name));


	if (IS_ERR(dummy_class)) {
		result = PTR_ERR(dummy_class);
	}
	return result;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{

}
