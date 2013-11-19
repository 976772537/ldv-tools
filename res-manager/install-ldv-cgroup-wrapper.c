#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>


#define INSTALL_LDV_CGROUP_SCRIPT  "install-ldv-cgroup"


int main()
{
  int ret;

  if (setuid(0) == -1)
  {
    printf("Couldn't change user ID to root: %s\n", strerror(errno));
    return errno;
  }

  if (setgid(0) == -1)
  {
    printf("Couldn't change group ID to root: %s\n", strerror(errno));
    return errno;
  }

  if((ret = system(INSTALL_LDV_CGROUP_SCRIPT)) == -1)
  {
    printf("Couldn't execute" INSTALL_LDV_CGROUP_SCRIPT ": %s\n", strerror(errno));
    return errno;
  }

  if (WEXITSTATUS(ret))
  {
    printf("Something went wrong\n");
    return WEXITSTATUS(ret);
  }

  printf("LDV control group was likely installed successfully\n");

  return 0;
}
