/*
 * Safe test for rule model 133_7a.
 * The test is for model function ieee80211_pspoll_get.
 */
#include <linux/skbuff.h>
#include <net/mac80211.h>

int ldv_dummy_open(void)
{
	struct sk_buff *skb1, *skb2;
	struct ieee80211_hw *dummy_hw;
	struct ieee80211_vif *dummy_vif;
	consume_skb(skb1);
	if ((skb1 = ieee80211_pspoll_get(dummy_hw, dummy_vif)) != NULL) {
		consume_skb(skb1);
	}
	return 0;
}

int ldv_dummy_close(void)
{
	return 0;
}

