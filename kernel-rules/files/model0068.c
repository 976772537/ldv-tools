#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/usb.h>

int urb_state = 0;

struct urb *usb_alloc_urb(int iso_packets, gfp_t mem_flags) {	
	void *new_urb = ldv_undef_ptr();
	if(!new_urb)
		return NULL;
	
	ldv_assert(urb_state==0);
	urb_state=1;	
	return new_urb;
}

void usb_free_urb(struct urb *urb) {
	ldv_assert(urb_state==1);
	urb_state=0;
}

void check_on_exit(void) {
	ldv_assert(urb_state==0);
}

