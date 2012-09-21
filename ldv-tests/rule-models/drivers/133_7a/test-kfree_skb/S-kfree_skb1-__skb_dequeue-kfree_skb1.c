/*
 * Safe test for rule model 133_7a.
 * The test is for model function __skb_dequeue.
 */
#include <linux/skbuff.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	struct sk_buff_head *dummy_list;
	kfree_skb(skb1);
	if ((skb1 = __skb_dequeue(dummy_list)) != NULL) {
		kfree_skb(skb1);
	}
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

