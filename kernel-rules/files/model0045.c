#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/slub_def.h>
//#include <linux/slab.h>

// RULE ID0045
#define RULE_ID0045
void * guard_kmalloc_Ptr  = 0;

/* Requires modification of header linux/slub_def.h */
void *ldv_env_kmalloc(size_t size, gfp_t flags) {
//void *kmalloc(size_t size, int flags) {
	void * result = ldv_undef_ptr();
	#ifdef RULE_ID0045
		guard_kmalloc_Ptr   = result;
	#endif
	return result;
}

/*
/home/mvadim/vinny/linux-2.6.9.TEST/include/asm/string.h
(asm = asm-i386)
Ñòðîêè 427-433 çàêîììåíòèðîâàíû, òàê êàê îáúÿâëÿëè memset êàê ìàêðîñ
*/
// #include <linux/string.h>
void * ldv_env_memset(void *pdst,
             int c,
             size_t plen)
{
	ldv_assert(pdst != guard_kmalloc_Ptr);
	return pdst;
}
	
