/*
 * Safe test for rule model 133_7a with one skb release call
 */
#include <linux/skbuff.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	consume_skb(skb1);
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

