#include "engine-blast.h"
#include <linux/list.h>

struct list_head *elem = NULL;

void ldv_list_add(struct list_head *new, struct list_head *head) {
  if(new!=NULL) {
	  ldv_assert(new!=elem);
	  if(ldv_undef_int())
        	elem = new;
  }
}

void ldv_list_del(struct list_head *entry) {
  if(entry==elem)
        elem=NULL;
}

/* CONFIG_DEBUG_LIST must be true */
/* see include/linux/list.h */
void __list_add(struct list_head *new,
			      struct list_head *prev,
			      struct list_head *next) {
	ldv_list_add(new, prev);
}

void list_del(struct list_head *entry) {
	ldv_list_del(entry);
}
