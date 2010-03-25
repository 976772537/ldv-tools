#include "engine-blast-assert.h"
#define ldv_assert(cond) assert(cond)

int __undefined_int(void);
void *__undefined_pointer(void);
unsigned long __undefined_ulong(void);

#define ldv_undef_int() __undefined_int()
#define ldv_undef_ulong() __undefined_ulong()
#define ldv_undef_ptr() __undefined_pointer()
