#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/if_pppox.h>
#include <linux/uaccess.h>

struct my_device {
	struct module mod;
} mydev;

static int __init my_init(void)
{
	const unsigned long *addr;
	static int i;
	i = find_next_zero_bit(addr, 0, 0);
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

