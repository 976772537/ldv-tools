#include <linux/spinlock.h>
#include "linux/module.h"
#include "linux/kernel.h"
#include "media/videobuf-vmalloc.h"

struct my_device {
	spinlock_t lock;
};

static int __init my_init(void)
{
	struct my_device *mydev;
	struct videobuf_queue *q;
	struct videobuf_queue_ops *ops;
	struct device *dev;
	enum v4l2_buf_type type;
	enum v4l2_field field;
	unsigned int msize;
	void *priv;
	struct mutex *ext_lock;

	videobuf_queue_vmalloc_init(q, ops, dev, &mydev->lock, type, field, msize, priv, ext_lock);	

	spin_lock_irq(&mydev->lock);

	return 0;
}

static void __exit my_exit(void)
{
	
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("LDV Project, Marina Makienko <makienko@ispras.ru>");
MODULE_DESCRIPTION("Test");

