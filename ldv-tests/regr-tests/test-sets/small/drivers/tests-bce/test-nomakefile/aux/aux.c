#include <linux/module.h>
#include <linux/interrupt.h>
#include <linux/firmware.h>
#include <linux/delay.h>
#include <linux/irq.h>
#include <linux/spi/spi.h>
#include <linux/crc32.h>
#include <linux/etherdevice.h>
#include <linux/spi/wl12xx.h>

#include "../wl12xx.h"
#include "../wl12xx_80211.h"
#include "../reg.h"
#include "../wl1251.h"
#include "../spi.h"
#include "../event.h"
#include "../tx.h"
#include "../rx.h"
#include "../ps.h"
#include "../init.h"
#include "../debugfs.h"

#include "aux.h"

void aux(struct wl12xx *wl)
{
  mutex_lock(&wl->mutex);  
}
