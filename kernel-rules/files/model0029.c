//RULE: ID0029
#include <linux/device.h>
#include <linux/dmapool.h>
//TODO: several pools, several allocs
struct dma_pool * the_pool;
struct ehci_qtd	*the_qtd;

#define RULE_ID0029

/* Pool may have following states:
 * 1 - absent or destroyed
 * 2 - created
 * 3 - allocated
 * 4 - free
 */
int pool_state = 1;


//include "linux/dmapool.h"
//"linux/pci.h" - pci_pool_create is alias to dma_pool_create
struct dma_pool *dma_pool_create(const char *name, struct device *dev, 
			size_t size, size_t align, size_t allocation) {
	#ifdef RULE_ID0029
	    /* To create pool we need its state must be absent or destroyed. */
		ldv_assert(pool_state == 1);
	#endif
	the_pool = ldv_undef_ptr();
	if(the_pool)
		pool_state = 2;
	return the_pool;
}

//include "linux/dmapool.h"
//"linux/pci.h" - pci_pool_alloc is alias to dma_pool_alloc
void *dma_pool_alloc(struct dma_pool *pool, gfp_t mem_flags, dma_addr_t *handle) {
//void *dma_pool_alloc(struct dma_pool *pool, int mem_flags, dma_addr_t *handle) {
	#ifdef RULE_ID0029
	    /* Allocation of memory is possible in either created pool or 
	     * already allocated pool. */
		ldv_assert(pool_state == 2 || pool_state == 3);
		ldv_assert(pool == the_pool);
	#endif
	the_qtd = ldv_undef_ptr();
	if(the_qtd)
		pool_state = 3;
	return the_qtd;
}

//include "linux/dmapool.h"
//"linux/pci.h" - pci_pool_free is alias to dma_pool_free
void dma_pool_free(struct dma_pool *pool, void *vaddr, dma_addr_t addr) {
	#ifdef RULE_ID0029
	    /* Releasing of memory is possible just when some pool memory 
	     * was allocated. */
		ldv_assert(pool_state == 3);
		ldv_assert(pool == the_pool);
		ldv_assert(vaddr == the_qtd);
	#endif
	pool_state = 4;
}

//include "linux/dmapool.h"
void dma_pool_destroy(struct dma_pool *pool) {
	#ifdef RULE_ID0029
	    /* We may destroy either created pool or pool that has releasing
	     * memory. */
		ldv_assert(pool_state == 2 || pool_state == 4);
		ldv_assert(pool == the_pool);
	#endif
	pool_state = 1;
}

