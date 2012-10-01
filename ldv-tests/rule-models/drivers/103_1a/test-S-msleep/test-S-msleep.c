/** 
  *  The test checks that correct msleep is detected on the model 103_1a
 **/
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/jiffies.h>
#include <linux/delay.h>

static int misc_open(struct inode *inode, struct file *file)
{
  unsigned long flags;
  
  msleep(10);
  
  return 0; 	
}

static const struct file_operations misc_fops = {
	.owner          = THIS_MODULE,
	.open           = misc_open,
};


static int __init test_init(void)
{
  if (register_chrdev(MISC_MAJOR,"misc",&misc_fops))
    goto fail_register;
  return 0;
	
  fail_register:
    return -1;
}
static void __exit test_exit(void)
{
}

module_init(test_init);
module_exit(test_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Ilya Shchepetkov <shchepetkov@ispras.ru>");