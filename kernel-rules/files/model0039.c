#include <linux/kernel.h>
#include <linux/spinlock.h>

/*
CONFIG_DEBUG_SPINLOCK should be true
make menuconfig
Kernel hacking->Kernel debugging->Spinlock and rw-lock debugging: basic checks
*/
extern unsigned long ldv_spin_lock_irqsave(spinlock_t *lock);
extern void ldv_spin_unlock_irqrestore(spinlock_t *lock, unsigned long flags);
extern void ldv_spin_lock(spinlock_t *lock);
extern void ldv_spin_unlock(spinlock_t *lock);

/* in case if aspect is off */
unsigned long  _spin_lock_irqsave(spinlock_t *lock) {
	return ldv_spin_lock_irqsave(lock);
}

void  _spin_unlock_irqrestore(spinlock_t *lock, unsigned long flags)  {
	ldv_spin_unlock_irqrestore(lock, flags);
}

void _spin_lock(spinlock_t *lock) {
	ldv_spin_lock(lock);
}

void  _spin_unlock(spinlock_t *lock)  {
	ldv_spin_unlock(lock);
}
/*   */

int ldv_lock = 1;

unsigned long  ldv_spin_lock_irqsave(spinlock_t *lock) {
 ldv_assert(ldv_lock==1);
 ldv_lock=2;
 return ldv_undef_ulong();
}

void  ldv_spin_unlock_irqrestore(spinlock_t *lock, unsigned long flags)  {
 ldv_assert(ldv_lock!=1);
 ldv_lock=1;
}

//int ldv_lock_2;

void ldv_spin_lock(spinlock_t *lock) {
 ldv_assert(ldv_lock==1);
 ldv_lock=2;
}

void  ldv_spin_unlock(spinlock_t *lock)  {
 ldv_assert(ldv_lock!=1);
 ldv_lock=1;
}

void check_final_state(void) {
 ldv_assert(ldv_lock==1);
}


