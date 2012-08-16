/*
	Test check that there is calling of function blk_put_request after successfully blk_get_request.
	The expected verdict is safe.

*/
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/buffer_head.h>
#include <linux/major.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <linux/kernel.h>
#include <linux/mm.h>
#include <linux/slab.h> 
#include <linux/cdrom.h>
#include <linux/sysctl.h>
#include <linux/proc_fs.h>
#include <linux/blkpg.h>
#include <linux/init.h>
#include <linux/fcntl.h>
#include <linux/blkdev.h>
#include <linux/times.h>

#include <asm/uaccess.h>

static int cdrom_read_cdda_bpc(struct cdrom_device_info *cdi, __u8 __user *ubuf,
			       int lba, int nframes);

struct my_device {
	struct module mod;
} mydev;

static int cdrom_read_cdda_bpc(struct cdrom_device_info *cdi, __u8 __user *ubuf,
			       int lba, int nframes)
{
	struct request_queue *q;
	struct request *rq;

	rq = blk_make_request(q, READ, GFP_KERNEL);

	if (rq)
	{
		blk_put_request(rq);
	}

	return 0;
}

static int __init cdrom_init(void)
{
	struct cdrom_device_info *cdi;
	__u8 __user *ubuf;
	return cdrom_read_cdda_bpc(cdi, ubuf, 0, 0);
}

static void __exit cdrom_exit(void)
{
}

module_init(cdrom_init);
module_exit(cdrom_exit);
MODULE_LICENSE("GPL");
