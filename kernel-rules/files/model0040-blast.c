#include <linux/usb.h>
#include "engine-blast.h"

#define LDV_ZERO_STATE 1

#define LDV_CHECK(state, value) ldv_assert(state == value);

#define LDV_CHECK_AND_INCREASE(state, value) ldv_assert(state == value); \
                                             state++;
#define LDV_CHECK_AND_ZEROIZE(state, value) ldv_assert(state == value); \
                                            state = LDV_ZERO_STATE; 

enum { 
/* There are 4 possible states of urb. */
  LDV_NO_URB = LDV_ZERO_STATE,  /* There is no urb or urb was cleaned. */
  LDV_ALLOCATED_URB,            /* Urb was created. */
  LDV_INITIALIZED_URB,          /* Urb was initialized. */
  LDV_SUBMITTED_URB,            /* Urb was submitted. */
};

/* There is no urb at the beginning. */
static int ldv_urb_state = LDV_NO_URB;


struct urb *usb_alloc_urb(int iso_packets, gfp_t mem_flags)
{
  /* Urb can be allocated just if it wasn't or was cleaned. */
  LDV_CHECK_AND_INCREASE(ldv_urb_state, LDV_NO_URB)
  
  return ldv_undef_ptr();
}

void ldv_init_urb(void)
{
  /* Urb can be initialized just if it was allocated. */
  LDV_CHECK_AND_INCREASE(ldv_urb_state, LDV_ALLOCATED_URB)
}

int usb_submit_urb(struct urb *urb, gfp_t mem_flags)
{
  /* Urb can be submittted just if it was initialized. */
  LDV_CHECK_AND_INCREASE(ldv_urb_state, LDV_INITIALIZED_URB)
  
  return ldv_undef_int();
}

void usb_free_urb(struct urb *urb)
{
  /* Urb can be cleaned just if it was submitted. */
  LDV_CHECK_AND_ZEROIZE(ldv_urb_state, LDV_SUBMITTED_URB)
}

void check_final_state(void) 
{
  /* At the end there must be no urb or urb must be cleaned. */	
  LDV_CHECK(ldv_urb_state, LDV_NO_URB)
}






