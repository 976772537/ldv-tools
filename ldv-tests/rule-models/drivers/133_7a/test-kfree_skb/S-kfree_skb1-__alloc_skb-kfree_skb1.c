/*
 * Safe test for rule model 133_7a.
 * The test is for model function __alloc_skb.
 */
#include <linux/skbuff.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	unsigned int dummy_size;	
	gfp_t dummy_priority;
	int dummy_fclone, dummy_node;
	kfree_skb(skb1);
	if ((skb1 = __alloc_skb(dummy_size, dummy_priority, dummy_fclone, dummy_node)) != NULL) {
		kfree_skb(skb1);
	}
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

