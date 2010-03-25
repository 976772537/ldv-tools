#include "engine-cbmc-assert.h"
#define ldv_assert(cond) assert(cond)

int nondet_int();
unsigned int nondet_uint();
unsigned long nondet_ulong();

#define ldv_undef_int() nondet_int()
#define ldv_undef_ptr() (void *)nondet_uint()
#define ldv_undef_ulong() nondet_ulong()
