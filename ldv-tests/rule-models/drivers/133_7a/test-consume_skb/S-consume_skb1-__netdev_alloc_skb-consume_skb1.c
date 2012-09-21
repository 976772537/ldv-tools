/*
 * Safe test for rule model 133_7a.
 * The test is for model function __netdev_alloc_skb.
 */
#include <linux/skbuff.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	struct net_device *dummy_device;
	unsigned int dummy_length;
	gfp_t dummy_gfp_mask;
	consume_skb(skb1);
	if ((skb1 = __netdev_alloc_skb(dummy_device, dummy_length, dummy_gfp_mask)) != NULL) {
		consume_skb(skb1);
	}
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

