#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/module.h>
#include <linux/init.h>

#define BASE 16
#define SIZE 32

void *ptr;

static int __init example_init(void)
{
        ptr = ioremap(BASE, SIZE);

        return 0;
}

static void __exit example_exit(void)
{
        iounmap(ptr);
        iounmap(ptr);
}

module_init(example_init);
module_exit(example_exit);
