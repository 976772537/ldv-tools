#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/slub_def.h>
#include "engine-blast.h"

int ldv_lock = 1;

void ldv_kmalloc(gfp_t flags) 
{
  ldv_assert(ldv_lock == 1 || (flags==GFP_ATOMIC));
}	

void ldv_usb_lock(void)
{
  ldv_assert(ldv_lock == 1);
  ldv_lock = 2;
}

int ldv_usb_trylock(void) 
{
  ldv_assert(ldv_lock == 1);
  
  if(ldv_undef_int()) 
  {
    ldv_lock = 2;
	return 1;
  } 
  else 
  {
    ldv_lock = 1;
    return 0;
  }
}

void ldv_usb_unlock(void)
{
  ldv_assert(ldv_lock != 1);
  ldv_lock = 1;
}

void check_final_state(void) 
{
  ldv_assert(ldv_lock == 1);
}
