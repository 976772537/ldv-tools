#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/module.h>
#include <linux/init.h>

#define BASE 16
#define SIZE 32

void *ptr = 0;

static int __init example_init(void)
{
        return 0;
}

static void __exit example_exit(void)
{
        iounmap(ptr);
}

module_init(example_init);
module_exit(example_exit);

