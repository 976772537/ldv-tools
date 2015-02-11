#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/module.h>
#include <linux/init.h>

static struct attribute_group attr_group;

static struct kobject *example_kobj;

static int __init example_init(void)
{
        /* Create the files associated with this kobject */
        return sysfs_create_group(example_kobj, &attr_group);
}

static void __exit example_exit(void)
{
        sysfs_remove_group(example_kobj, &attr_group);
}

module_init(example_init);
module_exit(example_exit);

