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
	return (n > 0) ? (-EINTR) : 0;
}

int misc_open(struct inode * inode, struct file * file)
{
        return 0;
}

int misc_flush(struct file *file, fl_owner_t id)
{
	int res = -1;
	if(n == 7)
	{
		if(down_write_trylock(&my_sem))
		{
			res = my_func();
			goto end;
		}
	}
	else if(n == 6)
	{
		if(down_read_trylock(&my_sem))
		{
			res = my_func();
			goto end;
		}
	}
end:
	return 0;
	if(down_read_trylock(&my_sem))
        {
		up_read(&my_sem);
                up_read(&my_sem);
        }
	else
	{
		up_write(&my_sem);
	}
	return res;
}

int misc_close(struct inode * inode, struct file * file)
{
	return 0;
}

static int misc_open_aux(struct inode *inode, struct file *file)
{
	return misc_open(inode, file);
}
static int misc_flush_aux(struct file *file, fl_owner_t id)
{
        return misc_flush(file, id);
}
static int misc_close_aux(struct inode *inode, struct file *file)
{
	return misc_close(inode, file);
}

static const struct file_operations misc_fops = {
	.owner          = THIS_MODULE,
	.open           = misc_open_aux,
	.flush		= misc_flush_aux,
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
