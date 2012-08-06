/*
	Test check that there is calling of function blk_put_request after successfully blk_get_request.
	The expected verdict is safe.

*/
#include <linux/spinlock.h>
#include <linux/slab.h>
#include <linux/blkdev.h>
#include <linux/hdreg.h>
#include <linux/module.h>
#include <linux/virtio.h>
#include <linux/virtio_blk.h>
#include <linux/scatterlist.h>
#include <linux/string_helpers.h>
#include <scsi/scsi_cmnd.h>
#include <linux/idr.h>

struct my_device {
	struct module mod;
} mydev;

static int virtblk_get_id(struct gendisk *disk, char *id_str)
{
	struct request_queue *q;
	struct bio *bio;
	int req;

	req = blk_make_request(q, bio, GFP_KERNEL);

	return 0;
}


static int __init cdrom_init(void)
{
	struct gendisk *disk;
	char *id_str;
	return virtblk_get_id(disk, id_str);
}

static void __exit cdrom_exit(void)
{
}

module_init(cdrom_init);
module_exit(cdrom_exit);
MODULE_LICENSE("GPL");
