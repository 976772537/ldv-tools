#include<drm/drmP.h>
#include<linux/mutex.h>

int ldv_lock = 0;
int nondet_int(void);

/*
Подменить
drm_gem_object_unreference(include/drm/drmP.h)
на
drm_gem_object_unreference
extern void drm_gem_object_unreference(struct drm_gem_object *obj);
*/

void drm_gem_object_unreference(struct drm_gem_object *obj)
{
  if(obj == NULL)
    return;
  ldv_assert(ldv_lock==1);
  //kref_put(&obj->refcount, drm_gem_object_free);
}

/*
CONFIG_DEBUG_LOCK_ALLOC должно быть false
либо заменить
#define mutex_lock(lock) mutex_lock_nested(lock, 0)
на
extern void mutex_lock(struct mutex *lock);
*/

void mutex_lock(struct mutex *lock) {
  ldv_assert(ldv_lock==0);
  ldv_lock=1;
}

void mutex_unlock(struct mutex *lock) {
  ldv_assert(ldv_lock!=0);
  ldv_lock=0;
}

int mutex_trylock(struct mutex *lock) {
  int ret = nondet_int();
  if(ret) {
    ldv_assert(ldv_lock==0);
    ldv_lock=1;
    return 1;
  }
  return 0;
}

/*
(18:20:29) 108879279: i915_gem.c подключает заголовочный файл include/drm/drm_crtc.h 
в котором struct drm_display_mode имеет поле float hsync;
(18:21:29) 108879279: это ж переменная с плавающей точкой, а вроде как операции с плавающей точкой запрещены, что они с ней делают тогда?
(18:26:41) 108879279: если  это поле закомментировать то  drivers/gpu/drm/ отлично собирается :)
*/
