#include "engine-blast.h"

void ldv_old_spin_lock_unlocked_macro(void) 
{
  /* Always assert whenever old macro is used. */	
  ldv_assert(0);
}	
