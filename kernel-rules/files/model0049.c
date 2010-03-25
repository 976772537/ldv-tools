#include "model0039.c"
extern int IN_INTERRUPT;

#include <linux/kref.h>
int kref_put(struct kref *kref, void (*release) (struct kref *kref)) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

//TODO check for macros with aspectator
//include/linux/preempt.h#L30
//#define preempt_disable()
//#define preempt_enable() 
//#define preempt_enable_no_resched()

#include  "model0049-2.6.31.c"


