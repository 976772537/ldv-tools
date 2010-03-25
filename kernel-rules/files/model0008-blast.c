#include "engine-blast.h"

/* Module locks counter. */ 
int ldv_module_lock = 1;

/* Just increase module locks counter. */ 
void ldv_module_get(void) 
{
  ldv_module_lock++;
}

/* Decrease module locks counter but with checking that it's >= 1. */
void ldv_module_put(void) 
{
  ldv_assert(ldv_module_lock >= 1);
  ldv_module_lock--;
}

/* At the end of execution module locks counter must be the same as at 
 * the beginning. */
void check_final_state(void) 
{
  ldv_assert(ldv_module_lock == 1);
}
