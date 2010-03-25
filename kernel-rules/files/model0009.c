#include <linux/mm.h>
#include <asm/page.h>
//RULE: ID0009
#define RULE_ID0009

/* Requires modification of header page.h*/
int ldv_env_get_order(unsigned long size) {
	#ifdef RULE_ID0009
		ldv_assert(size == PAGE_ALIGN(size));
	#endif
	return ldv_undef_int();
}

