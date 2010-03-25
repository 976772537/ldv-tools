#include <linux/kernel.h>
#include <linux/mutex.h>

extern int IN_INTERRUPT;
int ldv_mutex = 1;

/*
CONFIG_DEBUG_LOCK_ALLOC должно быть false
либо заменить
#define mutex_lock(lock) mutex_lock_nested(lock, 0)
на
extern void mutex_lock(struct mutex *lock);

To be independ on the value of this flag fix is done in corresponding 
aspect file.
*/
int /*__must_check*/ mutex_lock_interruptible(struct mutex *lock) 
{
 ldv_assert(IN_INTERRUPT==1);
 ldv_assert(ldv_mutex==1);
 if(ldv_undef_int()) {
	ldv_mutex=2;
	return 0;
 } else {
	ldv_mutex=1;
	return -EINTR;
 }
}

int __must_check mutex_lock_killable(struct mutex *lock) 
{
 ldv_assert(IN_INTERRUPT==1);
 ldv_assert(ldv_mutex==1);
 if(ldv_undef_int()) {
	ldv_mutex=2;
	return 0;
 } else {
	ldv_mutex=1;
	return -EINTR;
 }
}

void mutex_lock(struct mutex *lock) {
 ldv_assert(IN_INTERRUPT==1);
 ldv_assert(ldv_mutex==1);
 ldv_mutex=2;
}

int mutex_trylock(struct mutex *lock) {
 ldv_assert(IN_INTERRUPT==1);
 ldv_assert(ldv_mutex==1);
 if(ldv_undef_int()) {
	ldv_mutex=2;
	return 1;
 } else {
	ldv_mutex=1;
	return 0;
 }
}

void mutex_unlock(struct mutex *lock) {
 ldv_assert(IN_INTERRUPT==1);
 ldv_assert(ldv_mutex==2);
 ldv_mutex=1;
}

void check_final_state(void) {
 ldv_assert(ldv_mutex==1);
}

