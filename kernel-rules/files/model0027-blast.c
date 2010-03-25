#include <linux/blkdev.h>
#include "engine-blast.h"

#define LDV_ZERO_STATE 1

#define LDV_CHECK(state, value) ldv_assert(state == value);

#define LDV_CHECK_AND_INCREASE(state, value) ldv_assert(state == value); \
                                             state++;
#define LDV_CHECK_AND_ZEROIZE(state, value) ldv_assert(state == value); \
                                            state = LDV_ZERO_STATE; 

enum { 
/* There are 2 possible states of queue. */
  LDV_NO_QUEUE = LDV_ZERO_STATE,  /* There is no queue or queue was cleaned. */
  LDV_INITIALIZED_QUEUE           /* Queue was created. */
};

/* There is no queue at the beginning. */
static int ldv_queue_state = LDV_NO_QUEUE;


struct request_queue *blk_init_queue(request_fn_proc *arg1, spinlock_t *arg2)
{
  /* Queue can be initialized just if it wasn't. */
  LDV_CHECK_AND_INCREASE(ldv_queue_state, LDV_NO_QUEUE)
  
  return ldv_undef_ptr();
}

struct request_queue *blk_alloc_queue(gfp_t arg1)
{
  /* Queue can be allocated just if it wasn't. */
  LDV_CHECK_AND_INCREASE(ldv_queue_state, LDV_NO_QUEUE)
  
  return ldv_undef_ptr();	
}

void blk_cleanup_queue(struct request_queue *arg1)
{
  /* Queue can be cleaned just if it was created. */
  LDV_CHECK_AND_ZEROIZE(ldv_queue_state, LDV_INITIALIZED_QUEUE)
}

void check_final_state(void) 
{
  /* At the end there must be no queue or queue must be cleaned. */	
  LDV_CHECK(ldv_queue_state, LDV_NO_QUEUE)
}
