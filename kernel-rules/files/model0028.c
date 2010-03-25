#include <linux/kobject.h>

//RULE: ID0028
#define RULE_ID0028

int env_kobject_name = 0;

int kobject_set_name(struct kobject *obj, const char *str, ...) {
	int result = ldv_undef_int();
	if(result==0) {
		env_kobject_name = 1;
	}
	if(result>0)
		return -result;
	else 
		return result;
}

//was in 2.6.23.1 int kobject_add(struct kobject *obj) {
int __must_check kobject_add(struct kobject *kobj,
				    struct kobject *parent,
				    const char *fmt, ...) {
	int result = ldv_undef_int();
	#ifdef RULE_ID0028
		ldv_assert(env_kobject_name == 1);
	#endif
	if(result>0)
		return -result;
	else 
		return result;
}


