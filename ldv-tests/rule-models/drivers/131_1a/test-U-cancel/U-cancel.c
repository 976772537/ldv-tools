/*
	The test checks that function hrtimer_try_to_cancel() calls only after hrtimer_start().
*/

#include <linux/module.h>
#include <linux/kernel.h>
#include "linux/hrtimer.h"

struct my_device {
	struct module mod;
} mydev;


static int __init my_init(void)
{
	struct hrtimer *timer;
	ktime_t tim;
	unsigned long delta_ns;
	const enum hrtimer_mode mode;
	int i;

	i = hrtimer_try_to_cancel(timer);

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
