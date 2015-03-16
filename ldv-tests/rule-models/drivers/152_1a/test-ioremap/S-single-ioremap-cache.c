#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/module.h>
#include <linux/init.h>

#define BASE 16
#define SIZE 32

void *ptr;

static int __init test_init(void)
{
        ptr = ioremap_cache(BASE, SIZE);
        if (ptr == NULL) {
            return 1;
        }
        return 0;
}

static void __exit test_exit(void)
{
        iounmap(ptr);
}

module_init(test_init);
module_exit(test_exit);

