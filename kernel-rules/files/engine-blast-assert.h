#ifndef	_ASSERT_H
#define	_ASSERT_H	1

/* THE ERROR LABEL */
void __blast_assert(void) {
ERROR: goto ERROR;
}


#define assert(expr) ((expr) ? 0 : __blast_assert())



#endif /* NDEBUG.  */
