#include "engine-blast.h"

int ldv_lock = 1;

unsigned long ldv_spin_lock_irqsave(void) 
{
  ldv_assert(ldv_lock == 1);
  ldv_lock = 2;
  return ldv_undef_ulong();
}

void ldv_spin_unlock_irqrestore(void)
{
  ldv_assert(ldv_lock != 1);
  ldv_lock = 1;
}

void ldv_spin_lock(void)
{
  ldv_assert(ldv_lock == 1);
  ldv_lock = 2;
}

void ldv_spin_unlock(void)
{
  ldv_assert(ldv_lock != 1);
  ldv_lock = 1;
}

void ldv_might_sleep(void)
{
  /* Might sleep may be called just outside spinlock. */	
  ldv_assert(ldv_lock == 1);
}


void check_final_state(void) 
{
  ldv_assert(ldv_lock == 1);
}
