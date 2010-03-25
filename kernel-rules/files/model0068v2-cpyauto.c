#include "engine-cpyauto.h"

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/usb.h>

#define RULE_ID0068

struct urb *the_urb;
int urb_state;

struct urb *usb_alloc_urb(int iso_packets, gfp_t mem_flags) {
	void *new_urb = ldv_undef_ptr();
	if(!new_urb)
		return NULL;
	if(the_urb==NULL) {
		#ifdef RULE_ID0068
			ldv_assert(urb_state==0);
		#endif
		the_urb=new_urb;
		urb_state=1;
	}
	return new_urb;
}

void usb_free_urb(struct urb *urb) {
	if(the_urb==urb && urb!=NULL) {
		#ifdef RULE_ID0068
			ldv_assert(urb_state==1);
		#endif
		urb_state=0;
	}
}

void check_on_exit(void) {
	if(the_urb!=NULL) {
		#ifdef RULE_ID0068
			ldv_assert(urb_state==0);
		#endif
	}
}

