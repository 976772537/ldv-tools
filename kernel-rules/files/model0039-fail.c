#include <linux/kernel.h>
#include <linux/spinlock.h>

void lattice_error(void) {
int a;
ldv_fail: a=0;
return;
}

int ldv_lock;

unsigned long nondet_ulong(void);

unsigned long  _spin_lock_irqsave(spinlock_t *lock) {
 if(ldv_lock!=0) lattice_error();
 //bug 
 //ldv_lock=1;
 return nondet_ulong();
}

void  _spin_unlock_irqrestore(spinlock_t *lock, unsigned long flags)  {
 if(ldv_lock==0) lattice_error();
 ldv_lock=0;
}

//int ldv_lock_2;

void _spin_lock(spinlock_t *lock) {
 if(ldv_lock!=0) lattice_error();
 //bug
 //ldv_lock=1;
}

void  _spin_unlock(spinlock_t *lock)  {
 if(ldv_lock==0) lattice_error();
 ldv_lock=0;
}


