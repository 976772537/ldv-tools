#include <linux/module.h>
#include <linux/kernel.h>	
#include <linux/mutex.h>
#include <linux/mmc/sdio_func.h>
#include <linux/mmc/host.h>
#include <linux/mmc/card.h>
#include <linux/wait.h>
#include <linux/slab.h>
irqreturn_t handler(void){return IRQ_HANDLED;}

/*this is a safe test for rule 0150 to verify that the implementation is working correctly and it supports multiple nested claims*/
int __init my_init(void)
{
	int* err_ret = kmalloc(sizeof(int), 0);
	struct mmc_host* test_host = mmc_alloc_host(0, 0);
	struct mmc_host* test_host1 = mmc_alloc_host(0, 0);
	struct mmc_card test_card;
	struct mmc_card test_card1;
	struct sdio_func test_func;
	struct sdio_func test_func1;

	test_card.type = MMC_TYPE_SDIO;
	test_card1.type = MMC_TYPE_SDIO;

	test_card.host = test_host;
	test_func.card = &test_card;
	test_card1.host = test_host1;
	test_func1.card = &test_card1;

	test_func.device = 1;
	test_func1.device = 2;

	sdio_claim_host(&test_func);
	printk(KERN_DEBUG "two sdio func claimed\n");

	sdio_enable_func(&test_func);
	sdio_disable_func(&test_func);
	sdio_claim_irq(	&test_func, handler);
	sdio_release_irq(&test_func);
	sdio_readb(&test_func, 0, err_ret);
	sdio_readw(&test_func, 0, err_ret);
	sdio_readl(&test_func, 0, err_ret);
	sdio_readsb(&test_func, 0, 0, 0);
	sdio_writeb(&test_func, 0, 0 ,err_ret);
	sdio_writew(&test_func, 0, 0, err_ret);
	sdio_writel(&test_func, 0, 0, err_ret);
	sdio_writesb(&test_func, 0, 0, 0);
	sdio_writeb_readb(&test_func, 0, 0, err_ret);
	sdio_memcpy_fromio(&test_func, 0 , 0, 0);
	sdio_memcpy_toio(&test_func, 0, 0, 0);
	sdio_f0_readb(&test_func, 0, err_ret);
	sdio_f0_writeb(&test_func, 0, 0 ,err_ret);

	sdio_release_host(&test_func);
	sdio_claim_host(&test_func);
	sdio_release_host(&test_func);
	
	sdio_claim_host(&test_func1);
	sdio_release_host(&test_func1);
	return 0;
}
 
void __exit my_exit(void)
{
	return;
}

module_init(my_init);
module_exit(my_exit);
 
