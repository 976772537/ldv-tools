/*
 * 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/usb.h>
#include <linux/irq.h>
#include <linux/gfp.h>
#include <linux/skbuff.h>
#include <linux/slab.h>
#include <linux/dmapool.h>
#include <linux/mempool.h>
#include <linux/dma-mapping.h>

static struct my_struct
{
	const char *name;
	unsigned int irq;
	unsigned long addr;
	int order;
	struct vm_area_struct *vma;
	dma_addr_t * dma;
	struct usb_device * dev;
	struct net_device *netdev;
	struct kmem_cache *k;
	struct dma_pool *pool;
	mempool_t *mpool;
	struct urb *urb;
	struct device *simple_dev;
};

static struct my_res
{
	void *err;
	int x;
	struct sk_buff *skbf;
	struct page *my_page;
};

static irqreturn_t my_func_irq(int irq, void *dev_id)
{
	struct my_struct *ret;
	struct my_res *res;
	struct sk_buff *skb;
	const void *p;
	ret->order = sizeof(ret);
	res->my_page = alloc_page_vma(GFP_ATOMIC, ret->vma, ret->addr);
	res->skbf = skb_copy_expand(skb, ret->order, ret->irq, GFP_ATOMIC);
	res->x = pskb_expand_head(skb, ret->order, ret->irq, GFP_ATOMIC);
	res->err = usb_alloc_coherent(ret->dev, sizeof(ret), GFP_ATOMIC, ret->dma);
	res->skbf = __netdev_alloc_skb(ret->netdev, ret->irq, GFP_ATOMIC);
	res->err = krealloc(p, sizeof(ret), GFP_ATOMIC);
	res->err = kcalloc(sizeof(p), sizeof(ret), GFP_ATOMIC);
	res->err = kmem_cache_zalloc(ret->k, GFP_ATOMIC);
	res->err = kzalloc_node(sizeof(ret), GFP_ATOMIC, ret->irq);
	res->err = dma_pool_alloc(ret->pool, GFP_ATOMIC, ret->dma);
	res->err = mempool_alloc(ret->mpool, GFP_ATOMIC);
	res->err = kmem_cache_alloc(ret->k, GFP_ATOMIC);
	res->err = kmalloc_node(sizeof(ret), GFP_ATOMIC, ret->order);
	res->err = usb_alloc_urb(ret->irq, GFP_ATOMIC);
	res->x = usb_submit_urb(ret->urb, GFP_ATOMIC);
	res->skbf = skb_unshare(skb, GFP_ATOMIC);
	res->skbf = skb_clone(skb, GFP_ATOMIC);
	res->skbf = skb_share_check(skb, GFP_ATOMIC);
	res->skbf = skb_copy(skb, GFP_ATOMIC);
	res->skbf = alloc_skb_fclone(ret->irq, GFP_ATOMIC);
	res->skbf = alloc_skb(ret->irq, GFP_ATOMIC);
	res->err = dma_zalloc_coherent(ret->simple_dev, sizeof(ret), ret->dma, GFP_ATOMIC);
	return IRQ_HANDLED;
}


static int my_usb_probe(struct usb_interface *intf, const struct usb_device_id *id) 
{
	struct my_struct *err;
	err->name = "struct_name";
	err = request_irq(err->irq, my_func_irq, IRQF_SHARED, err->name, err);
	return PTR_ERR(err);
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
