/*
 * 
 */
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/rwsem.h>

static DECLARE_RWSEM(my_sem);

static int n;

int my_func(void)
{
	return (n > 10) ? (-EINTR) : 0;
}
int misc_open(struct inode *inode, struct file *file)
{
	int res = my_func();
	if(!n)
	{
		if(n == 4)
		{
			down_write(&my_sem);
		}
		else if(n == 5)
		{
			down_write_nested(&my_sem, n);
		}
		else
		{
			if(!down_write_trylock(&my_sem))
			{
				goto error;
			}
		}
	}
	if(rwsem_is_locked(&my_sem))
	{
		up_write(&my_sem);
	}

	down_read(&my_sem);

	if(rwsem_is_locked(&my_sem))
	{
		goto error;
	}

	up_read(&my_sem);

	return res;
error:
	return (-EINVAL);
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
	return register_chrdev(MISC_MAJOR, "misc", &misc_fops);
}

static void __exit test_exit(void)
{
  return;
}

module_init(test_init);
module_exit(test_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vladimir Gratinskiy <gratinskiy@ispras.ru>");
