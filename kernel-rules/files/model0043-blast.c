#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/slub_def.h>
#include "engine-blast.h"

extern int IN_INTERRUPT;

extern void ldv_spin_lock(void);
extern void ldv_spin_unlock(void);

int ldv_lock = 1;

void ldv_kmalloc(gfp_t flags) 
{
  ldv_assert(ldv_lock == 1 || (flags==GFP_ATOMIC));
}

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

void check_final_state(void) 
{
  ldv_assert(ldv_lock == 1);
}
