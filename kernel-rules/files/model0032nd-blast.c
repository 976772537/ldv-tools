#include <linux/kernel.h>
#include <linux/mutex.h>
#include "engine-blast.h"

/*
For expressing potentially infinite set of dynamically allocated lock objects
we use the universal quantification trick. We store one non-deterministically
chosen object which was locked using mutex_lock in the state variable ldv_lock.
If ldv_lock is NULL then no object was chosen in mutex_lock or the ldv_lock was
unlocked by mutex_unlock. Hence, blast independently check assertion in
mutex_lock for all single objects which can be locked. This technique has been
extensively used earlier.
*/
//State variable:
struct mutex *ldv_lock = NULL;

void ldv_mutex_lock(struct mutex *lock) {
    if(lock!=NULL) {//ignore undefined objects, TODO: think of it
          ldv_assert(lock!=ldv_lock);//no double lock
          if(ldv_undef_int()) //nondeterministic choice
                ldv_lock = lock;
    }
}

void ldv_mutex_unlock(struct mutex *lock) {
    if(lock==ldv_lock) ldv_lock=NULL;
}


void check_final_state(void) {
    ldv_assert(ldv_lock==NULL);//lock should be released at the end
}

int /*__must_check*/ mutex_lock_interruptible(struct mutex *lock) 
{
 if(ldv_undef_int()) {
	ldv_mutex_lock(lock);
	return 0;
 } else {
	return -EINTR;
 }
}

int __must_check mutex_lock_killable(struct mutex *lock) 
{
 if(ldv_undef_int()) {
	ldv_mutex_lock(lock);
	return 0;
 } else {
	return -EINTR;
 }
}

void mutex_lock(struct mutex *lock) {
 ldv_mutex_lock(lock);
}

int mutex_trylock(struct mutex *lock) {
 if(ldv_undef_int()) {
	ldv_mutex_lock(lock);
	return 1;
 } else {
	return 0;
 }
}

void mutex_unlock(struct mutex *lock) {
 ldv_mutex_unlock(lock);
}



