/*
 * Safe test for rule model 133_7a.
 * The test is for model function debug_dma_unmap_page.
 */
#include <linux/skbuff.h>
#include <linux/dma-debug.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	struct device *dummy_device;
	dma_addr_t dummy_addr;
	size_t dummy_size;
	int dummy_direction;
	bool dummy_map_single;
	consume_skb(skb1);
	// It's a heuristic for multiple skbs deallocation
        debug_dma_unmap_page(dummy_device, dummy_addr, dummy_size, dummy_direction, dummy_map_single);
	consume_skb(skb1);
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

