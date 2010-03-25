#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/slub_def.h>

//RULE: ID0010
#define RULE_ID0010
extern int IN_INTERRUPT;

/* Requires aspectator for kmalloc in the header linux/slub_def.h */
void ldv_env_kmalloc(size_t size, gfp_t flags) {
	#ifdef RULE_ID0010
		ldv_assert(IN_INTERRUPT == 1 || (flags==GFP_ATOMIC));
	#endif
}	



