#include <linux/kernel.h>
#include <linux/mutex.h>

#include "engine-blast.h"


/* State of lock for two resources. */
static struct mutex *ldv_lock1 = (struct mutex *)1;
int ldv_islock1 = 1;
static struct mutex *ldv_lock2 = (struct mutex *)1;
int ldv_islock2 = 1;


void ldv_mutex_lock(struct mutex *lock);


void ldv_lock_too_many_resources(void)
{
  ldv_assert(0);
}

void ldv_unlock_nonlocked(void)
{
  ldv_assert(0);
}

int ldv_mutex_lock_interruptible(struct mutex *lock) 
{
  /* It can lock or doesn't do anything. */
  if(ldv_undef_int()) 
  {
	ldv_mutex_lock(lock);  
    return 0;
  } 
  /* In case of error return corresponding error code. */
  else 
  {
    return -EINTR;
  }
}

int ldv_mutex_lock_killable(struct mutex *lock) 
{
  return ldv_mutex_lock_interruptible(lock);
}

void ldv_mutex_lock(struct mutex *lock) 
{
  /* Lock the first resource. */
  if (ldv_islock1 == 1)
  {
    ldv_islock1 = 2;
    
    /* Prevent double lock of the first resource. */
    assert(ldv_lock1 != lock);
    
    ldv_lock1 = lock;
  }
  /* Lock the second resource. */
  else if (ldv_islock2 == 1)
  {
    ldv_islock2 = 2;
    
    /* Prevent double lock of the second resource. */
    assert(ldv_lock2 != lock);
    
    ldv_lock2 = lock;
  }
  else
  {
    ldv_lock_too_many_resources();
  }
}

int mutex_trylock(struct mutex *lock) 
{
  /* It can lock or doesn't do anything. */
  if(ldv_undef_int()) 
  {
    ldv_mutex_lock(lock);
	return 1;
  }
  /* In case of error return 0. */
  else 
  {
    return 0;
  }
}

void mutex_unlock(struct mutex *lock) 
{
  /* Unlock the first resource. */
  if (ldv_lock1 == lock)
  {
    /* Prevent unlock of resource that wasn't look. */
    assert(ldv_islock1 == 2);
    
    ldv_lock1 = NULL;
    ldv_islock1 = 1;
  }
  /* Unlock the second resource. */
  else if (ldv_lock2 == lock)
  {
    /* Prevent unlock of resource that wasn't look. */
    assert(ldv_islock2 == 2);
    
    ldv_lock2 = NULL;
    ldv_islock2 = 1;
  }
  else
  {
	ldv_unlock_nonlocked();
  }
}

void check_final_state(void) 
{
  ldv_assert(ldv_islock1 == 1 && ldv_islock2 == 1);
}
