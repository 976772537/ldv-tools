/*
 * Check if atomic_dec_and_mutex_lock is instrumented
 */
#include <linux/skbuff.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	kfree_skb(skb1);
	kfree_skb(skb2);
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

