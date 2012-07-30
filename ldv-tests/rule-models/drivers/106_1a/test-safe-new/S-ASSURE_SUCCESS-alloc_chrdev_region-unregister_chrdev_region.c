/*
 * Template file for test generator (rule model 106_1a).
 * 
 */
#include <linux/usb.h>
#include <linux/slab.h>

#include <linux/device.h>
#include <linux/module.h>
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
	unregister_chrdev_region(*dummy_dev, DUMMY_COUNT);


	if (IS_ERR(dummy_class)) {
		result = PTR_ERR(dummy_class);
	}
	return result;
}

void ldv_dummy_disconnect(struct usb_interface *interface)
{

}
