#include "linux/module.h"
#include "linux/kernel.h"
#include "linux/netdevice.h"
#include "linux/skbuff.h"

static int enqueue_to_backlog(struct sk_buff *skb, int cpu, unsigned int *qtail);

static int __init my_init(void)
{
	struct sk_buff *skb;
	int cpu;
	unsigned int *qtail;

	enqueue_to_backlog(skb, cpu, qtail);

	return 0;
}

static void __exit my_exit(void)
{
	
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("LDV Project, Marina Makienko <makienko@ispras.ru>");
MODULE_DESCRIPTION("Test");

