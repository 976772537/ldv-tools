/*
 * Safe test for rule model 133_7a.
 * The test is for model function debug_dma_unmap_sg.
 */
#include <linux/skbuff.h>
#include <linux/dma-debug.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	struct device *dummy_device;
	struct scatterlist *dummy_sglist;
	int dummy_nelems, dummy_dir;
	consume_skb(skb1);
	// It's a heuristic for multiple skbs deallocation
        debug_dma_unmap_sg(dummy_device, dummy_sglist, dummy_nelems, dummy_dir);
	consume_skb(skb1);
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

