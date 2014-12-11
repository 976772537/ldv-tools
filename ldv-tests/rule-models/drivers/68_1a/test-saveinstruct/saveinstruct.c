/**
storing allocated urb request in a structure field
 */
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/usb.h>

static int my_usb_open(struct inode * inode, struct file * file);
//static void my_usb_close(struct input_dev *dev);

static void my_usb_disconnect(struct usb_interface *intf);
static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id);

static const struct file_operations my_fops = {
        .owner          = THIS_MODULE,
        .open           = my_usb_open,
};

static struct usb_driver my_usb_driver = {
	.name = "my_usb",
	.probe = my_usb_probe, 
	.disconnect = my_usb_disconnect,
	//.id_table = my_usb_id_table,
}; 

static int my_usb_open(struct inode * inode, struct file * file)
{
	return 0;
}

struct my_ctl_packet {
	u8 byte[4];
} __attribute__ ((packed));

#define USB_PKT_LEN     sizeof(struct my_ctl_packet)

struct my_dev {
	struct usb_device *udev; /* usb device */
	/* irq input channel */
	struct my_ctl_packet *irq_data;
	dma_addr_t irq_dma;
	struct urb *urb_irq;
	/* control output channel */
	struct my_ctl_packet *ctl_data;
	dma_addr_t ctl_dma;
	struct usb_ctrlrequest *ctl_req;
	struct urb *urb_ctl;
};

int my_function(struct usb_interface *intf);

static int my_usb_alloc(struct my_dev *dev)
{
	dev->urb_ctl = usb_alloc_urb(0, GFP_KERNEL);
	if (!dev->urb_ctl)
		return -1;
}

static void my_usb_cleanup(struct my_dev *dev)
{
	usb_free_urb(dev->urb_ctl);	/* parameter validation in core/urb */
	kfree(dev);
}

static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	struct usb_device *udev = interface_to_usbdev(intf);
	struct my_dev *dev;
	int error = -ENOMEM;

	dev = kzalloc(sizeof(*dev), GFP_KERNEL);
	if (!dev)
		return -ENOMEM;
	if(!my_usb_alloc(dev)) {
		goto err_out;
	}
	usb_set_intfdata(intf, dev);
	return 0;
err_out:  
	my_usb_cleanup(dev);
	return error; 
}

static void my_usb_disconnect(struct usb_interface *intf) {
	struct my_dev *dev = usb_get_intfdata(intf);

	usb_set_intfdata(intf, NULL);
	my_usb_cleanup(dev);
}

static int __init my_init(void)
{
	int retval = usb_register(&my_usb_driver);
	return retval;
}

static void __exit my_exit(void)
{
	usb_deregister(&my_usb_driver);
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vadim Mutilin <mutilin@ispras.ru>");

