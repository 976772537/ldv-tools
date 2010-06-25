#include <linux/spinlock.h>

void acquires_thelock(spinlock_t *lock) {
	spin_lock(lock);
}

void alock(spinlock_t *lock) {
	unsigned long flags;
	spin_lock_irqsave(lock, flags);
	spin_unlock_irqrestore(lock, flags);
}

