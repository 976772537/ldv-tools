/*
Данный код не используется
*/
int counter = 0;

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/usb.h>
#include <linux/tty.h>
#include <linux/tty_driver.h>
#include <linux/tty_flip.h>

#define RULE_ID0068

void *env_malloc(int size) {
       void *p = ldv_undef_ptr();
       if(p!=NULL)
	    return (void *)counter++;
       else 
	    return NULL;
}

int unlink_urb_count = 0;

int usb_unlink_urb(struct urb *urb) {
    unlink_urb_count++;
    ldv_assert(unlink_urb_count<=1);
    return ldv_undef_int();
}

int usb_submit_urb(struct urb *urb, gfp_t mem_flags) {
    ldv_assert(unlink_urb_count==0);
    unlink_urb_count = 0;
    switch(ldv_undef_int()) {
    	case 0: return 0;
    	case 1: return -ENOMEM;
    	case 2: return -ENODEV;
    	case 3: return -EPIPE;
    	case 4: return -EAGAIN;
    	case 5: return -EFBIG;
    	case 6: return -EINVAL;    	 
    }
    return 0;
}

#define URB_SIZE 3
struct urb *the_urb;
int urb_state;

void env_init_urb(void) {
	the_urb = NULL;
	urb_state = 0;
}

struct urb *usb_alloc_urb(int iso_packets, gfp_t mem_flags) {
	void *new_urb = env_malloc(sizeof(struct urb));
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
	if(the_urb==urb) {
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

