#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/major.h>
#include <linux/fs.h>
static void level1(void);
static void level2(void);
static void level3(void);
static void level4(void);
static void level5(void);
static void level6(void);
static void level7(void);
static void undef_func(void);

static DEFINE_MUTEX(ls_lock);

static void level1(void) {  level2(); };
static void level2(void) {  level3(); };
static void level3(void) {  level4(); };
static void level4(void) {  level5(); };
static void level5(void) {
	level6();
	undef_func();
        mutex_lock(&ls_lock);
        mutex_lock(&ls_lock);
        mutex_unlock(&ls_lock);
};
static void level6(void) {  
	level7(); 
	undef_func();
};
static void level7(void) { 
	undef_func();
};

static int misc_open(struct inode * inode, struct file * file)
{
        return 0;
}

static const struct file_operations misc_fops = {
        .owner          = THIS_MODULE,
        .open           = misc_open,
};

static int __init test_init( void )
{
        //mutex_init(&ls_lock);
        level1();
        return 0;
}

module_init(test_init);

