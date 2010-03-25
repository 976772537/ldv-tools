#include <linux/kernel.h>
#include <linux/mutex.h>

#include "engine-blast.h"

extern int IN_INTERRUPT;

int ldv_mutex = 1;

int /*__must_check*/ ldv_mutex_lock_interruptible(struct mutex *lock) 
{
  ldv_assert(IN_INTERRUPT == 1);
  ldv_assert(ldv_mutex == 1);

  if(ldv_undef_int()) 
  {
    ldv_mutex = 2;
    return 0;
  } 
  else 
  {
    ldv_mutex = 1;
    return -EINTR;
  }
}

int __must_check ldv_mutex_lock_killable(struct mutex *lock) 
{
  ldv_assert(IN_INTERRUPT == 1);
  ldv_assert(ldv_mutex == 1);
  
  if(ldv_undef_int()) 
  {
    ldv_mutex = 2;
    return 0;
  } 
  else 
  {
    ldv_mutex = 1;
    return -EINTR;
  }
}

void ldv_mutex_lock(struct mutex *lock) 
{
  ldv_assert(IN_INTERRUPT == 1);
  ldv_assert(ldv_mutex == 1);
  
  ldv_mutex = 2;
}

int mutex_trylock(struct mutex *lock) 
{
  ldv_assert(IN_INTERRUPT == 1);
  ldv_assert(ldv_mutex == 1);
  
  if(ldv_undef_int()) 
  {
    ldv_mutex = 2;
	return 1;
  } 
  else 
  {
    ldv_mutex = 1;
    return 0;
  }
}

void mutex_unlock(struct mutex *lock) 
{
  ldv_assert(IN_INTERRUPT == 1);
  ldv_assert(ldv_mutex == 2);
  
  ldv_mutex = 1;
}

void check_final_state(void) 
{
  ldv_assert(ldv_mutex == 1);
}
