#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>

struct file_operations *fops;


//RULE: ID0018_2
#define RULE_ID0018_2

#include <linux/cdev.h>

int cdev_state = 0;

int cdev_add(struct cdev *cdev, dev_t dev, unsigned maxminor) {
	// save device
	fops = cdev->ops;
	// do checks
	int result = ldv_undef_int();
	if(!result) {
		cdev_state = 1;
	}
	return result;
}

void cdev_del(struct cdev *cdev) {
	#ifdef RULE_ID0018_2  		
		ldv_assert(cdev_state == 1);
	#endif
	cdev_state = 0;
}

//TODO: ïîñëå cdev_add äîëæíî áûòü cdev_del


