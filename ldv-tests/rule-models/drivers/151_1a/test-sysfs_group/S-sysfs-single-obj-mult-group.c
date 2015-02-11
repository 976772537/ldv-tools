#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/module.h>
#include <linux/init.h>

static struct attribute_group attr_group1;
static struct attribute_group attr_group2;

static struct kobject *example_kobj;

static int __init example_init(void)
{
        /* Create the files associated with this kobject */
        int ret = sysfs_create_group(example_kobj, &attr_group1);
        if (ret != 0) {
            return ret;
        }
        ret = sysfs_create_group(example_kobj, &attr_group2);
        if (ret != 0) {
            sysfs_remove_group(example_kobj, &attr_group1);
            return ret;
        }

        return 0;
}

static void __exit example_exit(void)
{
        sysfs_remove_group(example_kobj, &attr_group1);
        sysfs_remove_group(example_kobj, &attr_group2);
}

module_init(example_init);
module_exit(example_exit);

