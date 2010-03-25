#include <linux/interrupt.h>
#include "engine-blast.h"

int ldv_irq_free_count = 1;

/* Our realization of free_irq function. */
void free_irq(unsigned int irq, void *dev_id)
{
  /* There may be just one call to irq_free function.
   * In fact it must be resource depended but it isn't implemented...*/
  ldv_assert(ldv_irq_free_count == 1);
  	
  /* Every call to irq_free function increase counter. */
  ldv_irq_free_count++;
}
