#include <linux/kernel.h>
#include <linux/string.h>

char *ldv_env_strncat(char *dest, const char *src, size_t count, size_t size_of_dest)
{
  /* In fact the following condition must be true:
   * strlen(dest) + count < sizeof_of_dest
   * But due to lack of blast with array processing we can't use this.
   * So this rule is good just for cases when something like this is
   * used: strncat(buf, string, sizeof(buf)) where buf is char buf[n].
   */	
  ldv_assert(count < size_of_dest);

  return (char *)ldv_undef_ptr();
}
