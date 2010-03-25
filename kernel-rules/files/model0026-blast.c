#include <linux/genhd.h>
#include "engine-blast.h"

#define LDV_ZERO_STATE 1

#define LDV_CHECK(state, value) ldv_assert(state == value);

#define LDV_CHECK_AND_INCREASE(state, value) ldv_assert(state == value); \
                                             state++;
#define LDV_CHECK_AND_ZEROIZE(state, value) ldv_assert(state == value); \
                                            state = LDV_ZERO_STATE; 

enum { 
/* There are 4 possible states of disk. */
  LDV_NO_DISK = LDV_ZERO_STATE, /* There is no disk or disk was put. */
  LDV_ALLOCATED_DISK,           /* Disk was allocated. */
  LDV_ADDED_DISK,               /* Disk was added. */
  LDV_DELETED_DISK              /* Disk was deleted. */
};

/* There is no disk at the beginning. */
static int ldv_disk_state = LDV_NO_DISK;


struct gendisk *alloc_disk(int minors)
{
  /* Disk can be allocated just if it wasn't or it was put. */
  LDV_CHECK_AND_INCREASE(ldv_disk_state, LDV_NO_DISK)
  
  return ldv_undef_ptr();
}

void add_disk(struct gendisk *disk)
{
  /* Disk can be added just if it was allocated. */
  LDV_CHECK_AND_INCREASE(ldv_disk_state, LDV_ALLOCATED_DISK)
}

void del_gendisk(struct gendisk *gp)
{
  /* Disk can be deleteted just if it was allocated. */
  LDV_CHECK_AND_INCREASE(ldv_disk_state, LDV_ADDED_DISK)
}

void put_disk(struct gendisk *disk)
{
  /* Disk can be put just if it was deleted previosly. */
  LDV_CHECK_AND_ZEROIZE(ldv_disk_state, LDV_ADDED_DISK)
}

void check_final_state(void) 
{
  /* At the end there must be no disk or disk must be put. */	
  LDV_CHECK(ldv_disk_state, LDV_NO_DISK)
}
