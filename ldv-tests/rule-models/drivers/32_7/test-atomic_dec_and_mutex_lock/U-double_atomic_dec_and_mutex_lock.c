/*
 * 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include <linux/mutex.h>

static atomic_t active_events = ATOMIC_INIT(0);

static DEFINE_MUTEX(my_mut);

static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	int err;
	err = atomic_dec_and_mutex_lock(&active_events, &my_mut);
	if(atomic_dec_and_mutex_lock(&active_events, &my_mut))
	{
		err = usb_match_one_id(intf, id);
		mutex_unlock(&my_mut);
	}
	return err;
}

static struct usb_driver my_usb_driver = {
	.name = "my usb irq",
	.probe = my_usb_probe,
}; 

static int __init my_init(void)
{
	int ret_val = usb_register(&my_usb_driver);
	return ret_val;
}

static void __exit my_exit(void)
{
	usb_deregister(&my_usb_driver);
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vladimir Gratinskiy <gratinskiy@ispras.ru>");
