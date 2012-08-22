#include "linux/tty.h"
#include "linux/module.h"
#include "linux/kernel.h"
#include "linux/usb.h"
#include "linux/usb/serial.h"

struct my_device {
	struct module mod;
} mydev;

int usb_serial_register(struct usb_serial_driver *s_driver);
int usb_register_driver(struct usb_driver *, struct module *, const char *);
void usb_serial_deregister(struct usb_serial_driver *s_driver);
void usb_deregister(struct usb_driver *driver);

static int __init my_init(void)
{
	return 0;
}

static void __exit my_exit(void)
{
	struct usb_driver *driver;

	usb_deregister(driver);
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("LDV Project, Marina Makienko <makienko@ispras.ru>");
MODULE_DESCRIPTION("Test");

