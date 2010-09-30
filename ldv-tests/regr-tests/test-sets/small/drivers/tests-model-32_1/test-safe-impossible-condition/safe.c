/** 
 * The test checks if BLAST correctly treats boolean values TRUE and FALSE
 * arising from use of comparison operations (i.e. <, > or ==)
 * and logical negation (!) as proper integer values 1 and 0 accordingly.
 * There is no possible double lock here due to a condition asserting
 * that exactly two of thee same values are equal.
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/major.h>
#include <linux/fs.h>

static DEFINE_MUTEX(my_lock);

static int misc_open(struct inode * inode, struct file * file);

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static void alock(int a, int b, int c) {
    /* If exactly two of three given integers are equal */
    if ((a == b) + (a == c) + !(b != c) == 2) {
        mutex_lock(&my_lock);
        mutex_unlock(&my_lock);        
    }
}

static int misc_open(struct inode * inode, struct file * file)
{
	int __BLAST_NONDET, v = __BLAST_NONDET;
	mutex_lock(&my_lock);
	/* Three same integers given */
	alock(v, v, v);
	mutex_unlock(&my_lock);
	return 0;
}

static int __init my_init(void)
{
	if (register_chrdev(MISC_MAJOR,"misc",&misc_fops))
		goto fail_register;
	return 0;
	
fail_register:
	return -1;
}

static void __exit my_exit(void)
{
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vadim Mutilin <mutilin@ispras.ru>, Mikhail Mandrykin <misha.bear.1990@gmail.com>");

