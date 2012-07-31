/** 
  *  The test checks that correct read/write lock is safe on the model 118_1a
 **/
#include <linux/module.h>
#include <linux/major.h>
#include <linux/fs.h>
#include <linux/spinlock.h>

static DEFINE_RWLOCK(my_lock);

static int misc_open(struct inode *inode, struct file *file)
{
  unsigned long flags;
  
  read_lock_irqsave(&my_lock, flags);
  read_unlock_irqrestore(&my_lock, flags);
  
  write_lock_irqsave(&my_lock, flags);
    write_trylock(&my_lock);
    read_trylock(&my_lock);
  write_unlock_irqrestore(&my_lock, flags);
  
  read_lock(&my_lock);
  read_unlock(&my_lock);
  
  write_lock(&my_lock);
  write_unlock(&my_lock);

  if (read_trylock(&my_lock))
    read_unlock(&my_lock);
 
  if (write_trylock(&my_lock))
    write_unlock(&my_lock);   
  
  read_lock_irq(&my_lock);
  read_unlock_irq(&my_lock);
    
  write_lock_irq(&my_lock);
  write_unlock_irq(&my_lock);
  
  read_lock_bh(&my_lock);
  read_unlock_bh(&my_lock);
  
  write_lock_bh(&my_lock);
  write_unlock_bh(&my_lock); 
  
  
  return 0; 	
}

static const struct file_operations misc_fops = {
	.owner          = THIS_MODULE,
	.open           = misc_open,
};


static int __init test_init(void)
{
  if (register_chrdev(MISC_MAJOR,"misc",&misc_fops))
    goto fail_register;
  return 0;
	
  fail_register:
    return -1;
}
static void __exit test_exit(void)
{
}

module_init(test_init);
module_exit(test_exit);

MODULE_LICENSE("Apache 2.0");
MODULE_AUTHOR("LDV Project, Ilya Shchepetkov <shchepetkov@ispras.ru>");