/** 
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/types.h>

static DEFINE_SPINLOCK(my_lock);

static int misc_open(struct inode * inode, struct file * file);
static off_t misc_llseek(struct file *, loff_t, int);
static ssize_t misc_read(struct file *, char __user *, size_t, loff_t *);
ssize_t misc_write(struct file *, const char __user *, size_t, loff_t *);
static ssize_t misc_aio_read(struct kiocb *, const struct iovec *, unsigned long, loff_t);
static ssize_t misc_aio_write(struct kiocb *, const struct iovec *, unsigned long, loff_t);
static int misc_readdir(struct file *, void *, filldir_t);
static unsigned int misc_poll(struct file *, struct poll_table_struct *);
static int misc_ioctl(struct inode *, struct file *, unsigned int, unsigned long);
static long misc_unlocked_ioctl(struct file *, unsigned int, unsigned long);
static long misc_compat_ioctl(struct file *, unsigned int, unsigned long);
static int misc_mmap(struct file *, struct vm_area_struct *);
static int misc_open(struct inode *, struct file *);
static int misc_flush(struct file *, fl_owner_t id);
static int misc_release(struct inode *, struct file *);
static int misc_fsync(struct file *, struct dentry *, int datasync);
static int misc_aio_fsync(struct kiocb *, int datasync);
static int misc_fasync(int, struct file *, int);
static int misc_lock(struct file *, int, struct file_lock *);
static ssize_t misc_sendpage(struct file *, struct page *, int, size_t, loff_t *, int);
static unsigned long misc_get_unmapped_area(struct file *, unsigned long, unsigned long, unsigned long, unsigned long);
static int misc_check_flags(int);
static int misc_flock(struct file *, int, struct file_lock *);
static ssize_t misc_splice_write(struct pipe_inode_info *, struct file *, loff_t *, size_t, unsigned int);
static ssize_t misc_splice_read(struct file *, loff_t *, struct pipe_inode_info *, size_t, unsigned int);
static int misc_setlease(struct file *, long, struct file_lock **);

static struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
	.read		= misc_read,
	.lock		= misc_lock,
	.release	= misc_release,
	.llseek		= misc_llseek,
	.write		= misc_write,
        .open           = misc_open,
	
};

static int misc_release(struct inode *node, struct file *file) {
	//release should be after open
	//verdict should be safe
	spin_unlock(&my_lock);
	return 0;
}

static off_t misc_llseek(struct file *file, loff_t offs, int i) {
	return 0;
}

static ssize_t misc_read(struct file *file, char __user *buf, size_t len, loff_t *offs) {
	return 0;
}

ssize_t misc_write(struct file *file, const char __user *buf, size_t len, loff_t *offs) {
	return 0;
}

static int misc_open(struct inode * inode, struct file * file)
{
	spin_lock(&my_lock);
	return 0;
}

static int misc_lock(struct file *file, int i, struct file_lock *lock) {
	return 0;
}

static int __init my_init(void)
{
	return 0;
}

static void __exit my_exit(void)
{
}

module_init(my_init);
module_exit(my_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Vadim Mutilin <mutilin@ispras.ru>");

