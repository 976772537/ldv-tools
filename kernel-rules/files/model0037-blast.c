#include "engine-blast.h"

/* This variable has two states:
 * 1 - irq probe is either absent or turned off.
 * 2 - irq probe is on.
 */
int ldv_probe_irq = 1;

/* This variable has two states:
 * 1 - delay isn't done.
 * 2 - delay is done.
 */
int ldv_delay = 1;

void ldv_probe_irq_on(void)
{
  /* We can turn on irq probe just when it is absent or turned off. */
  ldv_assert(ldv_probe_irq == 1);
  
  ldv_probe_irq = 2;
  
  /* Also specify that at the moment delay isn't done. */
  ldv_delay = 1;
}

void ldv_probe_irq_off(void)
{
  /* We can turn off irq probe just when it is turned on and when delay 
   * was done. */
  ldv_assert(ldv_probe_irq == 2 && ldv_delay == 2);
    
  ldv_probe_irq = 1;
  
  /* Also specify that at the moment delay isn't done. */
  ldv_delay = 1;  
}

void ldv_udelay(void)
{
  /* Do delay if we are in irq probe context. */
  if (ldv_probe_irq == 2)
  {	
    ldv_delay = 2;
  }
}

void check_final_state(void) 
{
  /* At the end of execution irq probe must be turned off. */
  ldv_assert(ldv_probe_irq == 1);
}
