#include <linux/kobject.h>

//RULE: ID0018_1
#define RULE_ID0018_1

int kobject_state = 0;

struct kobject * kobject_get(struct kobject *obj) {
	kobject_state++;
	return ldv_undef_ptr();
}

void kobject_put(struct kobject *obj) {
	#ifdef RULE_ID0018_1
		ldv_assert(kobject_state>=1);
	#endif
	kobject_state--;
}

//TODO: check that kobject was put
//void kobject_init(struct kobject *);
//void kobject_cleanup(struct kobject *);
