/*
 * 
 */
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/timer.h>
#include <linux/sched.h>

static struct timer_list my_timer;

void my_timer_callback(unsigned long data)
{
	printk("my_timer_callback called (%ld).\n", jiffies);
}

int misc_open(struct inode *inode, struct file *file)
{
	return 0;
}

int misc_close(struct inode * inode, struct file * file)
{
	return 0;
}
static int misc_open_aux(struct inode *inode, struct file *file)
{
	return misc_open(inode, file);
}
static int misc_close_aux(struct inode *inode, struct file *file)
{
	return misc_close(inode, file);
}

static const struct file_operations misc_fops = {
	.owner          = THIS_MODULE,
	.open           = misc_open_aux,
	.release        = misc_close_aux,
};

static int __init test_init(void)
{
	int ret;
	unsigned long timeout;
	printk("Timer module installing\n");
	// my_timer.function, my_timer.data
	setup_timer(&my_timer, my_timer_callback, 0);
	printk("Starting timer to fire in 200ms (%ld)\n", jiffies);
	timeout = 400;
	ret = mod_timer(&my_timer, 0);
	if (ret) printk("Error in mod_timer\n");
	return register_chrdev(MISC_MAJOR, "misc", &misc_fops);
}

static void __exit test_exit(void)
{
  int ret;
  ret = del_timer(&my_timer);
  if (ret) printk("The timer is still in use...\n");
  printk("Timer module uninstalling\n");
  return;
}

module_init(test_init);
module_exit(test_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vladimir Gratinskiy <gratinskiy@ispras.ru>");
