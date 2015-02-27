#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/module.h>
#include <linux/init.h>

#define BASE_1 16
#define BASE_2 32
#define SIZE 32

void *ptr1;
void *ptr2;

static int __init test_init(void)
{
        ptr1 = ioremap(BASE_1, SIZE);
        if (ptr1 == NULL) {
            return 1;
        }
        ptr2 = ioremap(BASE_2, SIZE);
        if (ptr2 == NULL) {
            iounmap(ptr1);
            return 1;
        }
        return 0;
}

static void __exit test_exit(void)
{
        iounmap(ptr1);
        iounmap(ptr2);
}

module_init(test_init);
module_exit(test_exit);
