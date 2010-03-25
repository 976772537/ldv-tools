void lattice_error(void) {
	int a;
	ldv_fail: a=0;
	return;
}

#define ldv_assert(expr) ((expr) ? 0 : lattice_error())

int __undefined_int(void);
void *__undefined_pointer(void);
unsigned long __undefined_ulong(void);

#define ldv_undef_int() __undefined_int()
#define ldv_undef_ulong() __undefined_ulong()
#define ldv_undef_ptr() __undefined_pointer()
