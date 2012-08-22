#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/blkdev.h>

struct my_device {
	struct module mod;
} mydev;

static void my_blk(struct request *req, int error)
{
	__blk_put_request(req->q, req);
}

static int __init cdrom_init(void)
{	
	struct request *req;
	struct request_queue *q;

	req = blk_get_request(q, READ, GFP_KERNEL);
	if (req && !IS_ERR(req))
		blk_execute_rq_nowait(req->q, NULL, req, 1, my_blk);
	
	return 0;
}

static void __exit cdrom_exit(void)
{
}

module_init(cdrom_init);
module_exit(cdrom_exit);
MODULE_LICENSE("GPL");
