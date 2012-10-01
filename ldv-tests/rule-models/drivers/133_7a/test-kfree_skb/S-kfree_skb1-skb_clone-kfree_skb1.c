/*
 * Safe test for rule model 133_7a.
 * The test is for model function skb_clone.
 */
#include <linux/skbuff.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	gfp_t dummy_priority;
	kfree_skb(skb1);
	if ((skb1 = skb_clone(skb1, dummy_priority)) != NULL) {
		kfree_skb(skb1);
	}
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

