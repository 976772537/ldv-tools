/*
 * Safe test for rule model 133_7a with two different skbs
 */
#include <linux/skbuff.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	__kfree_skb(skb1);
	__kfree_skb(skb2);
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

