#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/cdev.h>

#include "engine-blast.h"

int cdev_state = 1;

int cdev_add(struct cdev *cdev, dev_t dev, unsigned maxminor) 
{
  int result = ldv_undef_int();

  if(!result) 
  {
    cdev_state = 2;
  }
  
  return result;
}

void cdev_del(struct cdev *cdev) 
{
  ldv_assert(cdev_state == 2);
  
  cdev_state = 1;
}
