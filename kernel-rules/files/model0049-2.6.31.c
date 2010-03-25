/* +++++++++++++ HEADERS SECTION +++++++++++++ */
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/genhd.h>
#include <linux/kdev_t.h>
#include <linux/kernel.h>
#include <linux/blkdev.h>
#include <linux/init.h>
#include <linux/spinlock.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <linux/kmod.h>
#include <linux/kobj_map.h>
#include <linux/buffer_head.h>
#include <linux/mutex.h>
#include <linux/idr.h>
#include <linux/errno.h>
#include <linux/string.h>
#include <linux/capability.h>
#include <linux/completion.h>
#include <linux/cdrom.h>
#include <linux/times.h>
#include <asm/uaccess.h>
#include <scsi/scsi.h>
#include <scsi/scsi_ioctl.h>
#include <scsi/scsi_cmnd.h>
#include <scsi/sg.h>
#include <linux/backing-dev.h>
#include <linux/bio.h>
#include <linux/highmem.h>
#include <linux/mm.h>
#include <linux/kernel_stat.h>
#include <linux/swap.h>
#include <linux/writeback.h>
#include <linux/task_io_accounting_ops.h>
#include <linux/fault-inject.h>
#include <trace/events/block.h>
#include <linux/elevator.h>
#include <linux/compiler.h>
#include <linux/delay.h>
#include <linux/blktrace_api.h>
#include <linux/hash.h>
#include <linux/uaccess.h>
#include <linux/pagemap.h>
#include <linux/mpage.h>
#include <linux/rmap.h>
#include <linux/percpu.h>
#include <linux/notifier.h>
#include <linux/smp.h>
#include <linux/sysctl.h>
#include <linux/cpu.h>
#include <linux/syscalls.h>
#include <linux/pagevec.h>
#include <linux/migrate.h>
#include <linux/swapops.h>
#include <linux/mm_inline.h>
#include <linux/nsproxy.h>
#include <linux/topology.h>
#include <linux/cpuset.h>
#include <linux/mempolicy.h>
#include <linux/vmalloc.h>
#include <linux/security.h>
#include <linux/memcontrol.h>
#include <linux/mempool.h>
#include <linux/device.h>
#include <linux/dma-mapping.h>
#include <linux/dmapool.h>
#include <linux/list.h>
#include <linux/poison.h>
#include <linux/sched.h>
#include <linux/types.h>
#include <linux/wait.h>
#include <linux/cache.h>
#include <linux/rcupdate.h>
#include <linux/kmemtrace.h>
#include <linux/kmemleak.h>
#include <asm/atomic.h>
#include <linux/vmstat.h>
#include <linux/file.h>
#include <linux/rwsem.h>
#include <linux/kthread.h>
#include <linux/freezer.h>
#include <linux/delayacct.h>
#include <asm/tlbflush.h>
#include <asm/div64.h>
#include <linux/shm.h>
#include <linux/mman.h>
#include <linux/personality.h>
#include <linux/ima.h>
#include <linux/hugetlb.h>
#include <linux/profile.h>
#include <linux/mount.h>
#include <linux/mmu_notifier.h>
#include <linux/perf_counter.h>
#include <asm/cacheflush.h>
#include <asm/tlb.h>
#include <asm/mmu_context.h>
#include <linux/err.h>
#include <trace/events/kmem.h>
#include <linux/interrupt.h>
#include <linux/debugobjects.h>
#include <linux/kallsyms.h>
#include <linux/rbtree.h>
#include <linux/radix-tree.h>
#include <linux/pfn.h>
#include <linux/aio.h>
#include <linux/uio.h>
#include <linux/hardirq.h>
#include <asm/mman.h>
#include <linux/stddef.h>
#include <linux/jiffies.h>
#include <linux/bootmem.h>
#include <linux/kmemcheck.h>
#include <linux/suspend.h>
#include <linux/oom.h>
#include <linux/memory_hotplug.h>
#include <linux/nodemask.h>
#include <linux/stop_machine.h>
#include <linux/sort.h>
#include <linux/page-isolation.h>
#include <linux/page_cgroup.h>
#include <linux/workqueue.h>
#include <linux/random.h>
#include <linux/user_namespace.h>
#include <keys/keyring-type.h>
#include <linux/irq.h>
#include <linux/async.h>
#include <linux/nmi.h>
#include <linux/smp_lock.h>
#include <linux/debug_locks.h>
#include <linux/pid_namespace.h>
#include <linux/threads.h>
#include <linux/timer.h>
#include <linux/tsacct_kern.h>
#include <linux/kprobes.h>
#include <linux/reciprocal_div.h>
#include <linux/unistd.h>
#include <linux/hrtimer.h>
#include <linux/tick.h>
#include <linux/debugfs.h>
#include <linux/ctype.h>
#include <linux/ftrace.h>
#include <asm/irq_regs.h>
#include <trace/events/sched.h>
#include <linux/cgroup.h>
#include <linux/utsname.h>
#include <linux/kobject.h>
#include <linux/net.h>
#include <linux/sysrq.h>
#include <linux/highuid.h>
#include <linux/initrd.h>
#include <linux/key.h>
#include <linux/limits.h>
#include <linux/dcache.h>
#include <linux/nfs_fs.h>
#include <linux/acpi.h>
#include <linux/reboot.h>
#include <linux/slow-work.h>
#include <asm/processor.h>
#include <asm/nmi.h>
#include <asm/stacktrace.h>
#include <asm/io.h>
#include <asm/system.h>
#include <linux/signal.h>
#include <linux/lockdep.h>
#include <trace/events/workqueue.h>
#include <asm/dma.h>
#include <linux/tty.h>
#include <linux/iocontext.h>
#include <linux/acct.h>
#include <linux/fdtable.h>
#include <linux/binfmts.h>
#include <linux/ptrace.h>
#include <linux/taskstats_kern.h>
#include <linux/posix-timers.h>
#include <linux/cn_proc.h>
#include <linux/futex.h>
#include <linux/pipe_fs_i.h>
#include <linux/audit.h>
#include <linux/resource.h>
#include <linux/tracehook.h>
#include <linux/fs_struct.h>
#include <linux/init_task.h>
#include <asm/unistd.h>
#include <asm/pgtable.h>
#include <linux/time.h>
#include <asm/page.h>
#include <linux/math64.h>
#include <trace/events/jbd2.h>
#include <linux/fcntl.h>
#include <linux/stat.h>
#include <linux/namei.h>
#include <linux/quotaops.h>
#include <net/netlink.h>
#include <net/genetlink.h>
#include <linux/configfs.h>
#include <linux/fsnotify.h>
#include <linux/securebits.h>
#include <linux/vfs.h>
#include <linux/falloc.h>
#include <linux/exportfs.h>
#include <linux/splice.h>
#include <linux/seqlock.h>
#include <linux/bitops.h>
#include <linux/bit_spinlock.h>
#include <linux/major.h>
#include <linux/device_cgroup.h>
#include <linux/blkpg.h>
#include <linux/log2.h>
#include <linux/eventpoll.h>
#include <linux/cdev.h>
#include <linux/percpu_counter.h>
#include <linux/cpumask.h>
#include <linux/sysfs.h>
#include <linux/mnt_namespace.h>
#include <linux/ramfs.h>
#include <linux/inotify.h>
#include <linux/posix_acl.h>
#include <linux/dirent.h>
#include <linux/linkage.h>
#include <asm/ioctls.h>
#include <linux/in.h>
#include <linux/in6.h>
#include <linux/inetdevice.h>
#include <net/tcp.h>
#include <net/ipv6.h>
#include <rdma/rdma_cm.h>
#include <rdma/rdma_cm_ib.h>
#include <rdma/ib_cache.h>
#include <rdma/ib_cm.h>
#include <rdma/ib_sa.h>
#include <rdma/iw_cm.h>
#include <linux/if_arp.h>
#include <net/arp.h>
#include <net/neighbour.h>
#include <net/route.h>
#include <net/netevent.h>
#include <net/addrconf.h>
#include <net/ip6_route.h>
#include <rdma/ib_addr.h>
#include <linux/dma-attrs.h>
#include <rdma/ib_verbs.h>
#include <linux/ssb/ssb.h>
#include <linux/pci.h>
#include <linux/ssb/ssb_embedded.h>
#include <linux/memstick.h>
#include <linux/thermal.h>
#include <linux/hwmon.h>
#include <linux/input.h>
#include <linux/serio.h>
#include <linux/libps2.h>
#include <linux/ioport.h>
#include <linux/gameport.h>
#include <asm/i8253.h>
#include <linux/poll.h>
#include <linux/gpio.h>
#include <linux/of_gpio.h>
#include <linux/spi/spi.h>
#include <linux/spi/mmc_spi.h>
#include <linux/mmc/core.h>
#include <linux/mmc/host.h>
#include <linux/moduleparam.h>
#include <linux/loop.h>
#include <linux/compat.h>
#include <linux/gfp.h>
#include <scsi/scsi_device.h>
#include <scsi/scsi_host.h>
#include <scsi/scsi_tcq.h>
#include <scsi/scsi_dbg.h>
#include <asm/mtrr.h>
#include <linux/i2o.h>
#include <linux/bug.h>
#include <linux/crc-itu-t.h>
#include <linux/firewire.h>
#include <linux/firewire-constants.h>
#include <linux/kref.h>
#include <asm/byteorder.h>
#include <linux/ipmi.h>
#include <linux/ipmi_smi.h>
#include <linux/miscdevice.h>
#include <linux/tty_driver.h>
#include <linux/tty_flip.h>
#include <linux/serial.h>
#include <linux/termios.h>
#include <linux/devpts_fs.h>
#include <linux/console.h>
#include <linux/kd.h>
#include <linux/kbd_kern.h>
#include <linux/vt_kern.h>
#include <linux/selection.h>
#include <linux/nsc_gpio.h>
#include <linux/platform_device.h>
#include <linux/generic_serial.h>
#include <linux/i2c.h>
#include <linux/irqflags.h>
#include <linux/dmaengine.h>
#include <linux/rculist.h>
#include <linux/ide.h>
#include <linux/hdreg.h>
#include <linux/i2c/tps65010.h>
#include <asm/gpio.h>
#include <linux/mfd/ab3100.h>
#include <linux/clk.h>
#include <linux/regulator/machine.h>
#include <linux/i2c/twl4030.h>
#include <linux/rtc.h>
#include <linux/bcd.h>
#include <linux/phonedev.h>
#include <linux/sem.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/ethtool.h>
#include <linux/if_ether.h>
#include <linux/if_vlan.h>
#include <net/rtnetlink.h>
#include <scsi/fc/fc_els.h>
#include <scsi/fc/fc_fs.h>
#include <scsi/fc/fc_fip.h>
#include <scsi/fc/fc_encaps.h>
#include <scsi/fc/fc_fcoe.h>
#include <scsi/libfcoe.h>
#include <asm/unaligned.h>
#include <scsi/fc/fc_gs.h>
#include <scsi/fc_encode.h>
#include <scsi/scsi_driver.h>
#include <scsi/scsi_devinfo.h>
#include <scsi/scsi_transport.h>
#include <scsi/scsi_eh.h>
#include <linux/bsg.h>
#include <scsi/scsi_transport_sas.h>
#include <scsi/scsi_transport_spi.h>
#include <linux/transport_class.h>
#include <linux/parport.h>
#include <asm/irq.h>
#include <acpi/acpi_bus.h>
#include <acpi/acpi_drivers.h>
#include <linux/cpufreq.h>
#include <asm/cpufeature.h>
#include <acpi/processor.h>
#include <linux/pm.h>
#include <linux/pci-acpi.h>
#include <linux/efi.h>
#include <linux/semaphore.h>
#include <acpi/acpi.h>
#include <linux/usb.h>
#include <media/v4l2-common.h>
#include <linux/sound.h>
#include <linux/version.h>
#include <linux/io.h>
#include <media/v4l2-ioctl.h>
#include <linux/videodev2.h>
#include <asm/delay.h>
#include <media/soc_camera.h>
#include <media/v4l2-dev.h>
#include <media/videobuf-core.h>
#include <linux/videodev.h>
#include <media/v4l2-chip-ident.h>
#include <media/v4l2-device.h>
#include <linux/dvb/version.h>
#include <linux/dvb/frontend.h>
#include <linux/firmware.h>
#include <media/tuner.h>
#include <linux/tifm.h>
#include <linux/ioc4.h>
#include <linux/ktime.h>
#include <linux/pci_regs.h>
#include <linux/pci-aspm.h>
#include <xen/xenbus.h>
#include <linux/isapnp.h>
#include <linux/pnp.h>
#include <linux/bitmap.h>
#include <linux/display.h>
#include <linux/lcd.h>
#include <linux/fb.h>
#include <linux/vt.h>
#include <linux/linux_logo.h>
#include <asm/fb.h>
#include <linux/consolemap.h>
#include <linux/kbd_diacr.h>
#include <asm/shmparam.h>
#include <pcmcia/cs_types.h>
#include <pcmcia/ss.h>
#include <pcmcia/cs.h>
#include <pcmcia/cistpl.h>
#include <pcmcia/cisreg.h>
#include <pcmcia/ds.h>
#include <linux/serial_core.h>
#include <linux/serial_reg.h>
#include <linux/irqreturn.h>
#include <linux/nwpserial.h>
#include <linux/serial_8250.h>
#include <asm/serial.h>
#include <linux/skbuff.h>
#include <linux/capi.h>
#include <linux/kernelcapi.h>
#include <linux/isdn/capicmd.h>
#include <linux/isdn/capiutil.h>
#include <linux/b1lli.h>
#include <linux/isdn/capilli.h>
#include <linux/dmi.h>
#include <linux/kfifo.h>
#include <linux/sonypi.h>
#include <linux/sony-laptop.h>
#include <linux/rfkill.h>
#include <linux/rtnetlink.h>
#include <linux/wireless.h>
#include <net/net_namespace.h>
#include <net/iw_handler.h>
#include <net/lib80211.h>
#include <net/mac80211.h>
#include <linux/mii.h>
#include <linux/phy.h>
#include <linux/uio_driver.h>
#include <net/ip.h>
#include <scsi/iscsi_if.h>
#include <linux/if_pppox.h>
#include <linux/ppp_defs.h>
#include <linux/if_ppp.h>
#include <linux/ppp_channel.h>
#include <net/sock.h>
#include <linux/filter.h>
#include <linux/ppp-comp.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <net/slhc_vj.h>
#include <net/netns/generic.h>
#include <linux/scatterlist.h>
#include <asm/pgalloc.h>
#include <asm/iommu.h>
#include <asm/mmu.h>
#include <linux/dma-debug.h>
#include <asm/smp.h>
#include <asm/sections.h>
#include <asm/sparsemem.h>
#include <asm/vdso.h>
#include <asm/fixmap.h>
#include <stdarg.h>
#include <asm/param.h>
#include <asm/syscalls.h>
#include <asm/time.h>
#include <linux/ssb/ssb_driver_chipcommon.h>
#include <linux/ssb/ssb_driver_extif.h>
#include <net/checksum.h>
#include <asm/checksum.h>
#include <linux/scx200.h>
#include <linux/scx200_gpio.h>
#include <asm/mmx.h>
#include <linux/user.h>
#include <linux/elfcore.h>
#include <asm/errno.h>
#include <asm/setup.h>
#include <linux/pwm.h>
#include <sound/core.h>
#include <sound/emu8000.h>
#include <sound/emu8000_reg.h>
#include <sound/control.h>
#include <sound/initval.h>
#include <sound/minors.h>
#include <sound/seq_kernel.h>
#include <sound/seq_device.h>
#include <sound/info.h>
#include <sound/version.h>
#include <sound/pcm.h>
#include <linux/soundcard.h>
#include <sound/memalloc.h>
#include <sound/timer.h>
#include <sound/rawmidi.h>
#include <sound/tlv.h>
#include <sound/ac97_codec.h>
#include <sound/asoundef.h>
#include <sound/emu10k1.h>
#include <sound/util_mem.h>
#include <sound/asequencer.h>
#include <net/9p/9p.h>
#include <linux/parser.h>
#include <net/9p/client.h>
#include <net/9p/transport.h>
#include <linux/netfilter.h>
#include <net/protocol.h>
#include <net/ip_vs.h>
#include <linux/socket.h>
#include <linux/netfilter/x_tables.h>
#include <linux/netfilter_arp.h>
#include <net/netfilter/nf_log.h>
#include <net/netfilter/nf_queue.h>
#include <linux/if.h>
#include <net/ieee80211_radiotap.h>
#include <linux/pm_qos_params.h>
#include <net/cfg80211.h>
#include <net/xfrm.h>
#include <linux/pfkeyv2.h>
#include <linux/ipsec.h>
#include <net/bluetooth/bluetooth.h>
#include <net/wimax.h>
#include <linux/wimax.h>
#include <linux/nl80211.h>
#include <linux/sockios.h>
#include <linux/if_addr.h>
#include <asm/string.h>
#include <linux/inet.h>
#include <net/udp.h>
#include <net/pkt_sched.h>
#include <net/fib_rules.h>
#include <net/request_sock.h>
#include <linux/net_tstamp.h>
#include <linux/if_bridge.h>
#include <linux/if_macvlan.h>
#include <net/dst.h>
#include <linux/netpoll.h>
#include <net/wext.h>
#include <asm/current.h>
#include <linux/ipv6.h>
#include <linux/jhash.h>
#include <trace/events/napi.h>
#include <net/tcp_states.h>
#include <linux/pid.h>
#include <net/compat.h>
#include <net/scm.h>
#include <linux/icmpv6.h>
#include <linux/netfilter_ipv6.h>
#include <net/udplite.h>
#include <net/ipip.h>
#include <net/inet_common.h>
#include <net/transp_v6.h>
#include <net/ip6_tunnel.h>
#include <linux/mroute6.h>
#include <net/snmp.h>
#include <net/ndisc.h>
#include <linux/atmdev.h>
#include <linux/sonet.h>
#include <linux/atm.h>
#include <linux/atmclip.h>
#include <linux/atmarp.h>
#include <linux/atmsvc.h>
#include <linux/atmmpc.h>
#include <net/atmclip.h>
#include <linux/atmlec.h>
#include <linux/netfilter_bridge/ebtables.h>
#include <net/icmp.h>
#include <linux/netfilter_ipv4.h>
#include <linux/igmp.h>
#include <net/ip_fib.h>
#include <net/inet_connection_sock.h>
#include <net/raw.h>
#include <linux/mroute.h>
#include <linux/icmp.h>
#include <linux/udp.h>
#include <linux/route.h>
#include <linux/errqueue.h>
#include <linux/crypto.h>
#include <net/netdma.h>
#include <net/datalink.h>
#include <net/llc.h>
#include <net/psnap.h>

/* +++++++++++++ BODYES SECTION +++++++++++++ */

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/block/genhd.c */



int register_blkdev(unsigned int  var0  , const char * var1  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/block/genhd.c */
void unregister_blkdev(unsigned int  var2  , const char * var3  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/block/scsi_ioctl.c */
int scsi_cmd_ioctl(struct request_queue * var4  , struct gendisk * var5  , fmode_t  var6  ,
		   unsigned int  var7  , void __user * var8  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/block/blk-core.c */
void blk_cleanup_queue(struct request_queue * var9  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/block/blk-core.c */
void generic_make_request(struct bio * var10  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/block/elevator.c */
void elevator_exit(struct elevator_queue * var11  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/page-writeback.c */
int set_page_dirty_lock(struct page * var12  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/page-writeback.c */
int write_cache_pages(struct address_space * var13  ,
		      struct writeback_control * var14  , writepage_t  var15  ,
		      void * var16  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/migrate.c */
#ifdef CONFIG_BLOCK


int buffer_migrate_page(struct address_space * var17  ,
		struct page * var18  , struct page * var19  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/mempool.c */
void * mempool_alloc(mempool_t * var20  , gfp_t  var21  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/dmapool.c */
struct dma_pool * dma_pool_create(const char * var22  , struct device * var23  ,
				 size_t  var24  , size_t  var25  , size_t  var26  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/dmapool.c */
void dma_pool_destroy(struct dma_pool * var27  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/truncate.c */
void truncate_inode_pages_range(struct address_space * var28  ,
				loff_t  var29  , loff_t  var30  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/slob.c */
void kmem_cache_destroy(struct kmem_cache * var31  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/slob.c */
int kmem_cache_shrink(struct kmem_cache * var32  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/vmscan.c */
void register_shrinker(struct shrinker * var33  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/vmscan.c */
void unregister_shrinker(struct shrinker * var34  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/mmap.c */




unsigned long do_mmap_pgoff(struct file * var37  , unsigned long  var38  ,
			unsigned long  var39  , unsigned long  var40  ,
			unsigned long  var41  , unsigned long  var42  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/util.c */
void * memdup_user(const void __user * var43  , size_t  var44  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/util.c */
char * strndup_user(const char __user * var45  , long  var46  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/vmalloc.c */
void * vmalloc_user(unsigned long  var47  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/vmalloc.c */
void * vmap(struct page ** var48  , unsigned int  var49  ,
		unsigned long  var50  , pgprot_t  var51  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/filemap.c */
#ifdef CONFIG_MMU

int filemap_fault(struct vm_area_struct * var52  , struct vm_fault * var53  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/filemap.c */
struct page * find_lock_page(struct address_space * var54  , pgoff_t  var55  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/filemap.c */
ssize_t generic_file_aio_write(struct kiocb * var56  , const struct iovec * var57  ,
		unsigned long  var58  , loff_t  var59  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/filemap.c */
size_t iov_iter_copy_from_user(struct page * var60  ,
		struct iov_iter * var61  , unsigned long  var62  , size_t  var63  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/filemap.c */
int sync_page_range(struct inode * var64  , struct address_space * var65  ,
			loff_t  var66  , loff_t  var67  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/mm/page_alloc.c */
#ifndef CONFIG_NUMA
#ifdef CONFIG_HUGETLB_PAGE_SIZE_VARIABLE
#ifdef CONFIG_ZONE_DMA
#ifdef CONFIG_ZONE_DMA32
#ifdef CONFIG_HIGHMEM
#ifdef CONFIG_ARCH_POPULATES_NODE_MAP
#ifdef CONFIG_MAX_ACTIVE_REGIONS
#if MAX_NUMNODES >= 32
#if MAX_NUMNODES > 1
#ifdef CONFIG_DEBUG_VM
#ifdef CONFIG_HAVE_MLOCKED_PAGE_BIT
#ifndef CONFIG_HOLES_IN_ZONE
#ifdef CONFIG_NUMA
#ifdef CONFIG_HIBERNATION
#ifdef CONFIG_KMEMCHECK
#ifdef CONFIG_FAIL_PAGE_ALLOC
#ifdef CONFIG_FAULT_INJECTION_DEBUG_FS
#ifdef CONFIG_NUMA

struct page * __alloc_pages_nodemask(gfp_t  var81  , unsigned int  var82  ,
			struct zonelist * var83  , nodemask_t * var84  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/key.c */
key_ref_t key_create_or_update(key_ref_t  var87  ,
			       const char * var88  ,
			       const char * var89  ,
			       const void * var90  ,
			       size_t  var91  ,
			       key_perm_t  var92  ,
			       unsigned long  var93  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/key.c */
int key_instantiate_and_link(struct key * var94  ,
			     const void * var95  ,
			     size_t  var96  ,
			     struct key * var97  ,
			     struct key * var98  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/key.c */
int key_negate_and_link(struct key * var99  ,
			unsigned  var100  ,
			struct key * var101  ,
			struct key * var102  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/key.c */
void key_revoke(struct key * var103  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/key.c */
int key_update(key_ref_t  var104  , const void * var105  , size_t  var106  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/key.c */
int register_key_type(struct key_type * var107  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/key.c */
void unregister_key_type(struct key_type * var108  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/keyring.c */
int key_link(struct key * var109  , struct key * var110  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/keyring.c */
int keyring_clear(struct key * var111  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/security/keys/keyring.c */
int key_unlink(struct key * var112  , struct key * var113  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/gcov/base.c */
/*void __gcov_init(struct gcov_info * var114  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/irq/autoprobe.c */
unsigned long probe_irq_on() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sched.c */
#ifdef CONFIG_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_SMP
#ifdef CONFIG_FAIR_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_RT_GROUP_SCHED
#if defined CONFIG_SMP || defined CONFIG_RT_GROUP_SCHED
#ifdef CONFIG_SMP
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifdef CONFIG_SCHED_HRTICK
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_SCHED_DEBUG
#ifndef prepare_arch_switch
#ifndef finish_arch_switch
#ifndef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_DEBUG_SPINLOCK
#ifdef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef tsk_is_polling
#if BITS_PER_LONG == 32
#ifdef CONFIG_CGROUP_CPUACCT
#if (defined(CONFIG_SMP) && defined(CONFIG_FAIR_GROUP_SCHED)) || defined(CONFIG_RT_GROUP_SCHED)
#ifdef CONFIG_PREEMPT
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_PREEMPT_NOTIFIERS
#if defined(CONFIG_SCHEDSTATS) || defined(CONFIG_TASK_DELAY_ACCT)
#if defined(CONFIG_SMP) && defined(__ARCH_WANT_UNLOCKED_CTXSW)
#ifdef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_PREEMPT
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifndef CONFIG_VIRT_CPU_ACCOUNTING
#ifdef CONFIG_VIRT_CPU_ACCOUNTING
#if defined(CONFIG_PREEMPT) && (defined(CONFIG_DEBUG_PREEMPT) || \
				defined(CONFIG_PREEMPT_TRACER))
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PAGEALLOC
#ifdef CONFIG_PREEMPT

void __sched wait_for_completion(struct completion * var116  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sched.c */
#ifdef CONFIG_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_SMP
#ifdef CONFIG_FAIR_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_RT_GROUP_SCHED
#if defined CONFIG_SMP || defined CONFIG_RT_GROUP_SCHED
#ifdef CONFIG_SMP
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifdef CONFIG_SCHED_HRTICK
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_SCHED_DEBUG
#ifndef prepare_arch_switch
#ifndef finish_arch_switch
#ifndef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_DEBUG_SPINLOCK
#ifdef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef tsk_is_polling
#if BITS_PER_LONG == 32
#ifdef CONFIG_CGROUP_CPUACCT
#if (defined(CONFIG_SMP) && defined(CONFIG_FAIR_GROUP_SCHED)) || defined(CONFIG_RT_GROUP_SCHED)
#ifdef CONFIG_PREEMPT
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_PREEMPT_NOTIFIERS
#if defined(CONFIG_SCHEDSTATS) || defined(CONFIG_TASK_DELAY_ACCT)
#if defined(CONFIG_SMP) && defined(__ARCH_WANT_UNLOCKED_CTXSW)
#ifdef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_PREEMPT
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifndef CONFIG_VIRT_CPU_ACCOUNTING
#ifdef CONFIG_VIRT_CPU_ACCOUNTING
#if defined(CONFIG_PREEMPT) && (defined(CONFIG_DEBUG_PREEMPT) || \
				defined(CONFIG_PREEMPT_TRACER))
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PAGEALLOC
#ifdef CONFIG_PREEMPT

int __sched wait_for_completion_interruptible(struct completion * var117  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sched.c */
#ifdef CONFIG_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_SMP
#ifdef CONFIG_FAIR_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_RT_GROUP_SCHED
#if defined CONFIG_SMP || defined CONFIG_RT_GROUP_SCHED
#ifdef CONFIG_SMP
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifdef CONFIG_SCHED_HRTICK
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_SCHED_DEBUG
#ifndef prepare_arch_switch
#ifndef finish_arch_switch
#ifndef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_DEBUG_SPINLOCK
#ifdef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef tsk_is_polling
#if BITS_PER_LONG == 32
#ifdef CONFIG_CGROUP_CPUACCT
#if (defined(CONFIG_SMP) && defined(CONFIG_FAIR_GROUP_SCHED)) || defined(CONFIG_RT_GROUP_SCHED)
#ifdef CONFIG_PREEMPT
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_PREEMPT_NOTIFIERS
#if defined(CONFIG_SCHEDSTATS) || defined(CONFIG_TASK_DELAY_ACCT)
#if defined(CONFIG_SMP) && defined(__ARCH_WANT_UNLOCKED_CTXSW)
#ifdef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_PREEMPT
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifndef CONFIG_VIRT_CPU_ACCOUNTING
#ifdef CONFIG_VIRT_CPU_ACCOUNTING
#if defined(CONFIG_PREEMPT) && (defined(CONFIG_DEBUG_PREEMPT) || \
				defined(CONFIG_PREEMPT_TRACER))
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PAGEALLOC
#ifdef CONFIG_PREEMPT

unsigned long __sched wait_for_completion_interruptible_timeout(struct completion * var118  ,
					  unsigned long  var119  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sched.c */
#ifdef CONFIG_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_SMP
#ifdef CONFIG_FAIR_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_RT_GROUP_SCHED
#if defined CONFIG_SMP || defined CONFIG_RT_GROUP_SCHED
#ifdef CONFIG_SMP
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifdef CONFIG_SCHED_HRTICK
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_SCHED_DEBUG
#ifndef prepare_arch_switch
#ifndef finish_arch_switch
#ifndef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_DEBUG_SPINLOCK
#ifdef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef tsk_is_polling
#if BITS_PER_LONG == 32
#ifdef CONFIG_CGROUP_CPUACCT
#if (defined(CONFIG_SMP) && defined(CONFIG_FAIR_GROUP_SCHED)) || defined(CONFIG_RT_GROUP_SCHED)
#ifdef CONFIG_PREEMPT
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_PREEMPT_NOTIFIERS
#if defined(CONFIG_SCHEDSTATS) || defined(CONFIG_TASK_DELAY_ACCT)
#if defined(CONFIG_SMP) && defined(__ARCH_WANT_UNLOCKED_CTXSW)
#ifdef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_PREEMPT
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifndef CONFIG_VIRT_CPU_ACCOUNTING
#ifdef CONFIG_VIRT_CPU_ACCOUNTING
#if defined(CONFIG_PREEMPT) && (defined(CONFIG_DEBUG_PREEMPT) || \
				defined(CONFIG_PREEMPT_TRACER))
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PAGEALLOC
#ifdef CONFIG_PREEMPT

int __sched wait_for_completion_killable(struct completion * var120  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sched.c */
#ifdef CONFIG_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_SMP
#ifdef CONFIG_FAIR_GROUP_SCHED
#ifdef CONFIG_USER_SCHED
#ifdef CONFIG_RT_GROUP_SCHED
#if defined CONFIG_SMP || defined CONFIG_RT_GROUP_SCHED
#ifdef CONFIG_SMP
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifdef CONFIG_SCHED_HRTICK
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_SCHED_DEBUG
#ifndef prepare_arch_switch
#ifndef finish_arch_switch
#ifndef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_DEBUG_SPINLOCK
#ifdef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef __ARCH_WANT_INTERRUPTS_ON_CTXSW
#ifndef tsk_is_polling
#if BITS_PER_LONG == 32
#ifdef CONFIG_CGROUP_CPUACCT
#if (defined(CONFIG_SMP) && defined(CONFIG_FAIR_GROUP_SCHED)) || defined(CONFIG_RT_GROUP_SCHED)
#ifdef CONFIG_PREEMPT
#ifdef CONFIG_SCHEDSTATS
#ifdef CONFIG_PREEMPT_NOTIFIERS
#if defined(CONFIG_SCHEDSTATS) || defined(CONFIG_TASK_DELAY_ACCT)
#if defined(CONFIG_SMP) && defined(__ARCH_WANT_UNLOCKED_CTXSW)
#ifdef __ARCH_WANT_UNLOCKED_CTXSW
#ifdef CONFIG_PREEMPT
#if defined(CONFIG_SCHED_MC) || defined(CONFIG_SCHED_SMT)
#ifdef CONFIG_NO_HZ
#ifndef CONFIG_VIRT_CPU_ACCOUNTING
#ifdef CONFIG_VIRT_CPU_ACCOUNTING
#if defined(CONFIG_PREEMPT) && (defined(CONFIG_DEBUG_PREEMPT) || \
				defined(CONFIG_PREEMPT_TRACER))
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PREEMPT
#ifdef CONFIG_DEBUG_PAGEALLOC
#ifdef CONFIG_PREEMPT

unsigned long __sched wait_for_completion_timeout(struct completion * var121  , unsigned long  var122  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sysctl.c */
#if defined(CONFIG_SYSCTL)
#ifdef CONFIG_S390
#ifdef CONFIG_BSD_PROCESS_ACCT
#ifdef CONFIG_IA64
#ifdef CONFIG_RT_MUTEXES
#ifdef CONFIG_PROC_SYSCTL
#ifdef CONFIG_INOTIFY_USER
#ifdef CONFIG_EPOLL
#ifdef HAVE_ARCH_PICK_MMAP_LAYOUT
#ifdef CONFIG_SCHED_DEBUG
#ifdef CONFIG_PROVE_LOCKING
#ifdef CONFIG_LOCK_STAT
#ifdef CONFIG_LATENCYTOP
#ifdef CONFIG_BLK_DEV_INITRD
#ifdef CONFIG_SPARC
#ifdef CONFIG_SPARC64
#ifdef __hppa__
#ifdef CONFIG_FUNCTION_TRACER
#ifdef CONFIG_STACK_TRACER
#ifdef CONFIG_TRACING
#ifdef CONFIG_MODULES
#if defined(CONFIG_HOTPLUG) && defined(CONFIG_NET)
#ifdef CONFIG_CHR_DEV_SG
#ifdef CONFIG_MAGIC_SYSRQ
#ifdef CONFIG_MATHEMU
#if defined CONFIG_PRINTK
#if defined(CONFIG_X86_LOCAL_APIC) && defined(CONFIG_X86)
#if defined(CONFIG_X86)
#if defined(CONFIG_MMU)
#if defined(CONFIG_S390) && defined(CONFIG_SMP)
#if	defined(CONFIG_ACPI_SLEEP) && defined(CONFIG_X86)
#ifdef CONFIG_DETECT_SOFTLOCKUP
#ifdef CONFIG_DETECT_HUNG_TASK
#ifdef CONFIG_COMPAT
#ifdef CONFIG_KEYS
#ifdef CONFIG_RCU_TORTURE_TEST
#ifdef CONFIG_SLOW_WORK
#ifdef CONFIG_PERF_COUNTERS
#ifdef CONFIG_KMEMCHECK
#ifdef CONFIG_HUGETLB_PAGE
#ifdef CONFIG_MMU
#ifdef CONFIG_NUMA
#ifdef CONFIG_SMP
#if (defined(CONFIG_X86_32) && !defined(CONFIG_UML))|| \
   (defined(CONFIG_SUPERH) && defined(CONFIG_VSYSCALL))
#ifdef CONFIG_HIGHMEM
#if defined(CONFIG_BINFMT_MISC) || defined(CONFIG_BINFMT_MISC_MODULE)
#ifdef CONFIG_FILE_LOCKING
#ifdef CONFIG_DNOTIFY
#ifdef CONFIG_AIO
#if defined(CONFIG_X86) || defined(CONFIG_PPC)
#ifdef CONFIG_SYSCTL_SYSCALL
#ifdef CONFIG_SYSCTL_SYSCALL_CHECK
#ifdef CONFIG_SYSCTL_SYSCALL




#ifdef CONFIG_SYSCTL_SYSCALL



int sysctl_data(struct ctl_table * var123  ,
		void __user * var124  , size_t __user * var125  ,
		void __user * var126  , size_t  var127  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sysctl.c */
#if defined(CONFIG_SYSCTL)
#ifdef CONFIG_S390
#ifdef CONFIG_BSD_PROCESS_ACCT
#ifdef CONFIG_IA64
#ifdef CONFIG_RT_MUTEXES
#ifdef CONFIG_PROC_SYSCTL
#ifdef CONFIG_INOTIFY_USER
#ifdef CONFIG_EPOLL
#ifdef HAVE_ARCH_PICK_MMAP_LAYOUT
#ifdef CONFIG_SCHED_DEBUG
#ifdef CONFIG_PROVE_LOCKING
#ifdef CONFIG_LOCK_STAT
#ifdef CONFIG_LATENCYTOP
#ifdef CONFIG_BLK_DEV_INITRD
#ifdef CONFIG_SPARC
#ifdef CONFIG_SPARC64
#ifdef __hppa__
#ifdef CONFIG_FUNCTION_TRACER
#ifdef CONFIG_STACK_TRACER
#ifdef CONFIG_TRACING
#ifdef CONFIG_MODULES
#if defined(CONFIG_HOTPLUG) && defined(CONFIG_NET)
#ifdef CONFIG_CHR_DEV_SG
#ifdef CONFIG_MAGIC_SYSRQ
#ifdef CONFIG_MATHEMU
#if defined CONFIG_PRINTK
#if defined(CONFIG_X86_LOCAL_APIC) && defined(CONFIG_X86)
#if defined(CONFIG_X86)
#if defined(CONFIG_MMU)
#if defined(CONFIG_S390) && defined(CONFIG_SMP)
#if	defined(CONFIG_ACPI_SLEEP) && defined(CONFIG_X86)
#ifdef CONFIG_DETECT_SOFTLOCKUP
#ifdef CONFIG_DETECT_HUNG_TASK
#ifdef CONFIG_COMPAT
#ifdef CONFIG_KEYS
#ifdef CONFIG_RCU_TORTURE_TEST
#ifdef CONFIG_SLOW_WORK
#ifdef CONFIG_PERF_COUNTERS
#ifdef CONFIG_KMEMCHECK
#ifdef CONFIG_HUGETLB_PAGE
#ifdef CONFIG_MMU
#ifdef CONFIG_NUMA
#ifdef CONFIG_SMP
#if (defined(CONFIG_X86_32) && !defined(CONFIG_UML))|| \
   (defined(CONFIG_SUPERH) && defined(CONFIG_VSYSCALL))
#ifdef CONFIG_HIGHMEM
#if defined(CONFIG_BINFMT_MISC) || defined(CONFIG_BINFMT_MISC_MODULE)
#ifdef CONFIG_FILE_LOCKING
#ifdef CONFIG_DNOTIFY
#ifdef CONFIG_AIO
#if defined(CONFIG_X86) || defined(CONFIG_PPC)
#ifdef CONFIG_SYSCTL_SYSCALL
#ifdef CONFIG_SYSCTL_SYSCALL_CHECK
#ifdef CONFIG_SYSCTL_SYSCALL

int sysctl_intvec(struct ctl_table * var128  ,
		void __user * var129  , size_t __user * var130  ,
		void __user * var131  , size_t  var132  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sysctl.c */
#if defined(CONFIG_SYSCTL)
#ifdef CONFIG_S390
#ifdef CONFIG_BSD_PROCESS_ACCT
#ifdef CONFIG_IA64
#ifdef CONFIG_RT_MUTEXES
#ifdef CONFIG_PROC_SYSCTL
#ifdef CONFIG_INOTIFY_USER
#ifdef CONFIG_EPOLL
#ifdef HAVE_ARCH_PICK_MMAP_LAYOUT
#ifdef CONFIG_SCHED_DEBUG
#ifdef CONFIG_PROVE_LOCKING
#ifdef CONFIG_LOCK_STAT
#ifdef CONFIG_LATENCYTOP
#ifdef CONFIG_BLK_DEV_INITRD
#ifdef CONFIG_SPARC
#ifdef CONFIG_SPARC64
#ifdef __hppa__
#ifdef CONFIG_FUNCTION_TRACER
#ifdef CONFIG_STACK_TRACER
#ifdef CONFIG_TRACING
#ifdef CONFIG_MODULES
#if defined(CONFIG_HOTPLUG) && defined(CONFIG_NET)
#ifdef CONFIG_CHR_DEV_SG
#ifdef CONFIG_MAGIC_SYSRQ
#ifdef CONFIG_MATHEMU
#if defined CONFIG_PRINTK
#if defined(CONFIG_X86_LOCAL_APIC) && defined(CONFIG_X86)
#if defined(CONFIG_X86)
#if defined(CONFIG_MMU)
#if defined(CONFIG_S390) && defined(CONFIG_SMP)
#if	defined(CONFIG_ACPI_SLEEP) && defined(CONFIG_X86)
#ifdef CONFIG_DETECT_SOFTLOCKUP
#ifdef CONFIG_DETECT_HUNG_TASK
#ifdef CONFIG_COMPAT
#ifdef CONFIG_KEYS
#ifdef CONFIG_RCU_TORTURE_TEST
#ifdef CONFIG_SLOW_WORK
#ifdef CONFIG_PERF_COUNTERS
#ifdef CONFIG_KMEMCHECK
#ifdef CONFIG_HUGETLB_PAGE
#ifdef CONFIG_MMU
#ifdef CONFIG_NUMA
#ifdef CONFIG_SMP
#if (defined(CONFIG_X86_32) && !defined(CONFIG_UML))|| \
   (defined(CONFIG_SUPERH) && defined(CONFIG_VSYSCALL))
#ifdef CONFIG_HIGHMEM
#if defined(CONFIG_BINFMT_MISC) || defined(CONFIG_BINFMT_MISC_MODULE)
#ifdef CONFIG_FILE_LOCKING
#ifdef CONFIG_DNOTIFY
#ifdef CONFIG_AIO
#if defined(CONFIG_X86) || defined(CONFIG_PPC)
#ifdef CONFIG_SYSCTL_SYSCALL
#ifdef CONFIG_SYSCTL_SYSCALL_CHECK
#ifdef CONFIG_SYSCTL_SYSCALL

int sysctl_jiffies(struct ctl_table * var133  ,
		void __user * var134  , size_t __user * var135  ,
		void __user * var136  , size_t  var137  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sysctl.c */
#if defined(CONFIG_SYSCTL)
#ifdef CONFIG_S390
#ifdef CONFIG_BSD_PROCESS_ACCT
#ifdef CONFIG_IA64
#ifdef CONFIG_RT_MUTEXES
#ifdef CONFIG_PROC_SYSCTL
#ifdef CONFIG_INOTIFY_USER
#ifdef CONFIG_EPOLL
#ifdef HAVE_ARCH_PICK_MMAP_LAYOUT
#ifdef CONFIG_SCHED_DEBUG
#ifdef CONFIG_PROVE_LOCKING
#ifdef CONFIG_LOCK_STAT
#ifdef CONFIG_LATENCYTOP
#ifdef CONFIG_BLK_DEV_INITRD
#ifdef CONFIG_SPARC
#ifdef CONFIG_SPARC64
#ifdef __hppa__
#ifdef CONFIG_FUNCTION_TRACER
#ifdef CONFIG_STACK_TRACER
#ifdef CONFIG_TRACING
#ifdef CONFIG_MODULES
#if defined(CONFIG_HOTPLUG) && defined(CONFIG_NET)
#ifdef CONFIG_CHR_DEV_SG
#ifdef CONFIG_MAGIC_SYSRQ
#ifdef CONFIG_MATHEMU
#if defined CONFIG_PRINTK
#if defined(CONFIG_X86_LOCAL_APIC) && defined(CONFIG_X86)
#if defined(CONFIG_X86)
#if defined(CONFIG_MMU)
#if defined(CONFIG_S390) && defined(CONFIG_SMP)
#if	defined(CONFIG_ACPI_SLEEP) && defined(CONFIG_X86)
#ifdef CONFIG_DETECT_SOFTLOCKUP
#ifdef CONFIG_DETECT_HUNG_TASK
#ifdef CONFIG_COMPAT
#ifdef CONFIG_KEYS
#ifdef CONFIG_RCU_TORTURE_TEST
#ifdef CONFIG_SLOW_WORK
#ifdef CONFIG_PERF_COUNTERS
#ifdef CONFIG_KMEMCHECK
#ifdef CONFIG_HUGETLB_PAGE
#ifdef CONFIG_MMU
#ifdef CONFIG_NUMA
#ifdef CONFIG_SMP
#if (defined(CONFIG_X86_32) && !defined(CONFIG_UML))|| \
   (defined(CONFIG_SUPERH) && defined(CONFIG_VSYSCALL))
#ifdef CONFIG_HIGHMEM
#if defined(CONFIG_BINFMT_MISC) || defined(CONFIG_BINFMT_MISC_MODULE)
#ifdef CONFIG_FILE_LOCKING
#ifdef CONFIG_DNOTIFY
#ifdef CONFIG_AIO
#if defined(CONFIG_X86) || defined(CONFIG_PPC)
#ifdef CONFIG_SYSCTL_SYSCALL
#ifdef CONFIG_SYSCTL_SYSCALL_CHECK
#ifdef CONFIG_SYSCTL_SYSCALL

int sysctl_ms_jiffies(struct ctl_table * var138  ,
		void __user * var139  , size_t __user * var140  ,
		void __user * var141  , size_t  var142  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/sysctl.c */
#if defined(CONFIG_SYSCTL)
#ifdef CONFIG_S390
#ifdef CONFIG_BSD_PROCESS_ACCT
#ifdef CONFIG_IA64
#ifdef CONFIG_RT_MUTEXES
#ifdef CONFIG_PROC_SYSCTL
#ifdef CONFIG_INOTIFY_USER
#ifdef CONFIG_EPOLL
#ifdef HAVE_ARCH_PICK_MMAP_LAYOUT
#ifdef CONFIG_SCHED_DEBUG
#ifdef CONFIG_PROVE_LOCKING
#ifdef CONFIG_LOCK_STAT
#ifdef CONFIG_LATENCYTOP
#ifdef CONFIG_BLK_DEV_INITRD
#ifdef CONFIG_SPARC
#ifdef CONFIG_SPARC64
#ifdef __hppa__
#ifdef CONFIG_FUNCTION_TRACER
#ifdef CONFIG_STACK_TRACER
#ifdef CONFIG_TRACING
#ifdef CONFIG_MODULES
#if defined(CONFIG_HOTPLUG) && defined(CONFIG_NET)
#ifdef CONFIG_CHR_DEV_SG
#ifdef CONFIG_MAGIC_SYSRQ
#ifdef CONFIG_MATHEMU
#if defined CONFIG_PRINTK
#if defined(CONFIG_X86_LOCAL_APIC) && defined(CONFIG_X86)
#if defined(CONFIG_X86)
#if defined(CONFIG_MMU)
#if defined(CONFIG_S390) && defined(CONFIG_SMP)
#if	defined(CONFIG_ACPI_SLEEP) && defined(CONFIG_X86)
#ifdef CONFIG_DETECT_SOFTLOCKUP
#ifdef CONFIG_DETECT_HUNG_TASK
#ifdef CONFIG_COMPAT
#ifdef CONFIG_KEYS
#ifdef CONFIG_RCU_TORTURE_TEST
#ifdef CONFIG_SLOW_WORK
#ifdef CONFIG_PERF_COUNTERS
#ifdef CONFIG_KMEMCHECK
#ifdef CONFIG_HUGETLB_PAGE
#ifdef CONFIG_MMU
#ifdef CONFIG_NUMA
#ifdef CONFIG_SMP
#if (defined(CONFIG_X86_32) && !defined(CONFIG_UML))|| \
   (defined(CONFIG_SUPERH) && defined(CONFIG_VSYSCALL))
#ifdef CONFIG_HIGHMEM
#if defined(CONFIG_BINFMT_MISC) || defined(CONFIG_BINFMT_MISC_MODULE)
#ifdef CONFIG_FILE_LOCKING
#ifdef CONFIG_DNOTIFY
#ifdef CONFIG_AIO
#if defined(CONFIG_X86) || defined(CONFIG_PPC)
#ifdef CONFIG_SYSCTL_SYSCALL
#ifdef CONFIG_SYSCTL_SYSCALL_CHECK
#ifdef CONFIG_SYSCTL_SYSCALL

int sysctl_string(struct ctl_table * var143  ,
		  void __user * var144  , size_t __user * var145  ,
		  void __user * var146  , size_t  var147  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/rwsem.c */
#ifdef CONFIG_DEBUG_LOCK_ALLOC


void down_read_nested(struct rw_semaphore * var148  , int  var149  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/rwsem.c */
#ifdef CONFIG_DEBUG_LOCK_ALLOC
void down_read_non_owner(struct rw_semaphore * var150  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/rwsem.c */
#ifdef CONFIG_DEBUG_LOCK_ALLOC
void down_write_nested(struct rw_semaphore * var151  , int  var152  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/workqueue.c */
void flush_scheduled_work() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/dma.c */
#ifdef MAX_DMA_CHANNELS

void free_dma(unsigned int  var154  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/dma.c */
#ifdef MAX_DMA_CHANNELS

int request_dma(unsigned int  var155  , const char *  var156  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/slow-work.c */
int slow_work_register_user() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/slow-work.c */
void slow_work_unregister_user() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/mutex.c */
int atomic_dec_and_mutex_lock(atomic_t * var161  , struct mutex * var162  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/mutex.c */
#ifndef CONFIG_DEBUG_LOCK_ALLOC
void __sched mutex_lock(struct mutex * var163  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/mutex.c */
#ifndef CONFIG_DEBUG_LOCK_ALLOC
int __sched mutex_lock_interruptible(struct mutex * var164  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/kernel/mutex.c */
#ifndef CONFIG_DEBUG_LOCK_ALLOC
int __sched mutex_lock_killable(struct mutex * var165  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/jbd/journal.c */
int journal_create(journal_t * var166  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/jbd/journal.c */
int journal_flush(journal_t * var167  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/jbd/journal.c */
journal_t * journal_init_dev(struct block_device * var168  ,
			struct block_device * var169  ,
			int  var170  , int  var171  , int  var172  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/jbd/journal.c */
journal_t * journal_init_inode(struct inode * var173  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/jbd2/journal.c */
int jbd2_journal_destroy(journal_t * var174  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/jbd2/journal.c */
int jbd2_journal_flush(journal_t * var175  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/jbd2/journal.c */
journal_t * jbd2_journal_init_inode(struct inode * var181  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/fscache/cache.c */
/*int fscache_add_cache(struct fscache_cache * var182  ,
		      struct fscache_object * var183  ,
		      const char * var184  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/fscache/cache.c */
/*void fscache_withdraw_cache(struct fscache_cache * var185  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/fscache/netfs.c */
/*int __fscache_register_netfs(struct fscache_netfs * var186  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/fscache/netfs.c */
/*void __fscache_unregister_netfs(struct fscache_netfs * var187  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_acquire(struct dquot * var188  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_alloc_inode(const struct inode * var189  , qsize_t  var190  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_alloc_space(struct inode * var191  , qsize_t  var192  , int  var193  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_claim_space(struct inode * var194  , qsize_t  var195  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_commit(struct dquot * var196  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_commit_info(struct super_block * var197  , int  var198  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_drop(struct inode * var199  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_free_inode(const struct inode * var200  , qsize_t  var201  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_free_space(struct inode * var202  , qsize_t  var203  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_initialize(struct inode * var204  , int  var205  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_release(struct dquot * var206  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
void dquot_release_reserved_space(struct inode * var207  , qsize_t  var208  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_reserve_space(struct inode * var209  , qsize_t  var210  , int  var211  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int dquot_transfer(struct inode * var212  , struct iattr * var213  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int vfs_get_dqinfo(struct super_block * var214  , int  var215  , struct if_dqinfo * var216  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int vfs_quota_disable(struct super_block * var217  , int  var218  , unsigned int  var219  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int vfs_quota_enable(struct inode * var220  , int  var221  , int  var222  ,
		unsigned int  var223  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int vfs_quota_on_mount(struct super_block * var224  , char * var225  ,
		int  var226  , int  var227  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int vfs_quota_sync(struct super_block * var228  , int  var229  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/quota/dquot.c */
int vfs_set_dqinfo(struct super_block * var230  , int  var231  , struct if_dqinfo * var232  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/configfs/dir.c */
int configfs_depend_item(struct configfs_subsystem * var233  ,
			 struct config_item * var234  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/configfs/dir.c */
int configfs_register_subsystem(struct configfs_subsystem * var235  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/configfs/dir.c */
void configfs_unregister_subsystem(struct configfs_subsystem * var236  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/open.c */
#if BITS_PER_LONG == 32
#ifdef CONFIG_HAVE_SYSCALL_WRAPPERS
struct file * dentry_open(struct dentry * var237  , struct vfsmount * var238  , int  var239  ,
			 const struct cred * var240  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/direct-io.c */
ssize_t __blockdev_direct_IO(int  var241  , struct kiocb * var242  , struct inode * var243  ,
	struct block_device * var244  , const struct iovec * var245  , loff_t  var246  , 
	unsigned long  var247  , get_block_t  var248  , dio_iodone_t  var249  ,
	int  var250  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/libfs.c */
int dcache_dir_close(struct inode * var251  , struct file * var252  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/libfs.c */
loff_t dcache_dir_lseek(struct file * var253  , loff_t  var254  , int  var255  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/libfs.c */
int simple_fill_super(struct super_block * var256  , int  var257  , struct tree_descr * var258  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/libfs.c */
ssize_t simple_read_from_buffer(void __user * var259  , size_t  var260  , loff_t * var261  ,
				const void * var262  , size_t  var263  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/libfs.c */
char * simple_transaction_get(struct file * var264  , const char __user * var265  , size_t  var266  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/libfs.c */
int simple_unlink(struct inode * var267  , struct dentry * var268  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/splice.c */
ssize_t generic_file_splice_write(struct pipe_inode_info * var269  , struct file * var270  ,
			  loff_t * var271  , size_t  var272  , unsigned int  var273  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/fs-writeback.c */
int generic_osync_inode(struct inode * var274  , struct address_space * var275  , int  var276  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/fs-writeback.c */
int write_inode_now(struct inode * var277  , int  var278  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/dcache.c */
struct dentry * d_add_ci(struct dentry * var279  , struct inode * var280  ,
			struct qstr * var281  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/dcache.c */
struct dentry * d_obtain_alias(struct inode * var282  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/dcache.c */
void d_prune_aliases(struct inode * var283  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/dcache.c */
ino_t find_inode_number(struct dentry * var284  , struct qstr * var285  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/seq_file.c */
loff_t seq_lseek(struct file * var286  , loff_t  var287  , int  var288  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/seq_file.c */
ssize_t seq_read(struct file * var289  , char __user * var290  , size_t  var291  , loff_t * var292  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
int bh_submit_read(struct buffer_head * var293  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
int bh_uptodate_or_lock(struct buffer_head * var294  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
int block_page_mkwrite(struct vm_area_struct * var295  , struct vm_fault * var296  ,
		   get_block_t  var297  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
int block_read_full_page(struct page * var298  , get_block_t * var299  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
int block_truncate_page(struct address_space * var300  ,
			loff_t  var301  , get_block_t * var302  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
struct buffer_head * __bread(struct block_device * var303  , sector_t  var304  , unsigned  var305  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
void __breadahead(struct block_device * var306  , sector_t  var307  , unsigned  var308  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
void ll_rw_block(int  var309  , int  var310  , struct buffer_head ** var311 ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
int nobh_truncate_page(struct address_space * var312  ,
			loff_t  var313  , get_block_t * var314  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
int nobh_write_begin(struct file * var315  , struct address_space * var316  ,
			loff_t  var317  , unsigned  var318  , unsigned  var319  ,
			struct page ** var320  , void ** var321  ,
			get_block_t * var322  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
int sync_dirty_buffer(struct buffer_head * var323  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/buffer.c */
void unmap_underlying_metadata(struct block_device * var324  , sector_t  var325  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/super.c */
void deactivate_super(struct super_block * var326  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/super.c */
struct super_block * get_super(struct block_device * var327  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/super.c */
void lock_super(struct super_block *  var328  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/block_dev.c */
struct super_block * freeze_bdev(struct block_device * var329  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/block_dev.c */
int revalidate_disk(struct gendisk * var330  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/block_dev.c */
int thaw_bdev(struct block_device * var331  , struct super_block * var332  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/file_table.c */
void fput(struct file * var333  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namespace.c */
void put_mnt_ns(struct mnt_namespace * var334  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/attr.c */
int notify_change(struct dentry *  var335  , struct iattr *  var336  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/inode.c */
void clear_inode(struct inode * var337  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/inode.c */
void generic_delete_inode(struct inode * var338  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/inode.c */
int insert_inode_locked(struct inode * var339  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/inode.c */
int invalidate_inodes(struct super_block * var340  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/readdir.c */
int vfs_readdir(struct file * var341  , filldir_t  var342  , void * var343  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/sync.c */
int vfs_fsync(struct file * var344  , struct dentry * var345  , int  var346  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/read_write.c */
loff_t generic_file_llseek(struct file * var347  , loff_t  var348  , int  var349  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/ioctl.c */

#define SET_NO_UNMOUNTED_IO_FLAGS	(FIEMAP_EXTENT_DATA_ENCRYPTED)
#define SET_NOT_ALIGNED_FLAGS	(FIEMAP_EXTENT_DATA_TAIL|FIEMAP_EXTENT_DATA_INLINE)
int fiemap_fill_next_extent(struct fiemap_extent_info * var350  , u64  var351  ,
			    u64  var352  , u64  var353  , u32  var354  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/ioctl.c */
#ifdef CONFIG_BLOCK
int generic_block_fiemap(struct inode * var355  ,
			 struct fiemap_extent_info * var356  , u64  var357  ,
			 u64  var358  , get_block_t * var359  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namei.c */
int follow_down(struct path * var360  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namei.c */
int follow_up(struct path * var361  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namei.c */
struct dentry * lock_rename(struct dentry * var362  , struct dentry * var363  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namei.c */
void path_put(struct path * var364  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namei.c */
int vfs_link(struct dentry * var365  , struct inode * var366  , struct dentry * var367  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namei.c */
int vfs_readlink(struct dentry * var368  , char __user * var369  , int  var370  , const char * var371  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namei.c */
int vfs_rmdir(struct inode * var372  , struct dentry * var373  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/namei.c */
int vfs_unlink(struct inode * var374  , struct dentry * var375  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/exec.c */
#ifdef CONFIG_MMU
#ifdef CONFIG_MMU




int setup_arg_pages(struct linux_binprm * var376  ,
		    unsigned long  var377  ,
		    int  var378  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/cma.c */
int rdma_bind_addr(struct rdma_cm_id * var379  , struct sockaddr * var380  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/cma.c */
void rdma_destroy_id(struct rdma_cm_id * var381  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/cma.c */
void rdma_destroy_qp(struct rdma_cm_id * var382  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/device.c */
int ib_register_client(struct ib_client * var383  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/device.c */
int ib_register_device(struct ib_device * var384  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/device.c */
void ib_unregister_client(struct ib_client * var385  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/device.c */
void ib_unregister_device(struct ib_device * var386  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/addr.c */
void rdma_addr_cancel(struct rdma_dev_addr * var387  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/umem.c */
struct ib_umem * ib_umem_get(struct ib_ucontext * var388  , unsigned long  var389  ,
			    size_t  var390  , int  var391  , int  var392  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/umem.c */
void ib_umem_release(struct ib_umem * var393  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/verbs.c */
int ib_rate_to_mult(enum ib_rate  var394  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/infiniband/core/verbs.c */
enum ib_rate mult_to_ib_rate(int  var395  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/ssb/driver_pcicore.c */
int ssb_pcicore_dev_irqvecs_enable(struct ssb_pcicore * var396  ,
				   struct ssb_device * var397  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/memstick/core/memstick.c */
void memstick_remove_host(struct memstick_host * var398  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/memstick/core/memstick.c */
void memstick_resume_host(struct memstick_host * var399  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/memstick/core/memstick.c */
void memstick_suspend_host(struct memstick_host * var400  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/thermal/thermal_sys.c */
struct thermal_cooling_device * thermal_cooling_device_register(char * var401  ,
							       void * var402  ,
							       struct
							       thermal_cooling_device_ops
							       * var403  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/thermal/thermal_sys.c */
void thermal_cooling_device_unregister(struct
				       thermal_cooling_device
				       * var404  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/thermal/thermal_sys.c */
int thermal_zone_bind_cooling_device(struct thermal_zone_device * var405  ,
				     int  var406  ,
				     struct thermal_cooling_device * var407  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/thermal/thermal_sys.c */
struct thermal_zone_device * thermal_zone_device_register(char * var408  ,
							 int  var409  ,
							 void * var410  , struct
							 thermal_zone_device_ops
							 * var411  , int  var412  , int
							  var413  ,
							 int  var414  ,
							 int  var415  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/thermal/thermal_sys.c */
void thermal_zone_device_unregister(struct thermal_zone_device * var416  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/thermal/thermal_sys.c */
void thermal_zone_device_update(struct thermal_zone_device * var417  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/thermal/thermal_sys.c */
int thermal_zone_unbind_cooling_device(struct thermal_zone_device * var418  ,
				       int  var419  ,
				       struct thermal_cooling_device * var420  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/serio/libps2.c */
int ps2_command(struct ps2dev * var421  , unsigned char * var422  , int  var423  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/serio/libps2.c */
void ps2_drain(struct ps2dev * var424  , int  var425  , int  var426  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/serio/serio.c */
void serio_unregister_child_port(struct serio * var427  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/serio/serio.c */
void serio_unregister_driver(struct serio_driver * var428  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/serio/serio.c */
void serio_unregister_port(struct serio * var429  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/gameport/gameport.c */
void gameport_unregister_driver(struct gameport_driver * var430  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/gameport/gameport.c */
void gameport_unregister_port(struct gameport * var431  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
void input_close_device(struct input_handle * var432  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
int input_flush_device(struct input_handle * var433  , struct file * var434  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
int input_grab_device(struct input_handle * var435  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
int input_open_device(struct input_handle * var436  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
int input_register_device(struct input_dev * var437  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
int input_register_handle(struct input_handle * var438  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
int input_register_handler(struct input_handler * var439  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
void input_release_device(struct input_handle * var440  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
void input_unregister_device(struct input_dev * var441  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
void input_unregister_handle(struct input_handle * var442  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/input.c */
void input_unregister_handler(struct input_handler * var443  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}


/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/block/loop.c */
int loop_unregister_transfer(int  var445  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/message/i2o/device.c */
int i2o_device_claim_release(struct i2o_device * var464  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/firewire/core-card.c */
int fw_card_add(struct fw_card * var465  ,
		u32  var466  , u32  var467  , u64  var468  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/firewire/core-card.c */
int fw_core_add_descriptor(struct fw_descriptor * var469  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/firewire/core-card.c */
void fw_core_remove_card(struct fw_card * var470  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/firewire/core-card.c */
void fw_core_remove_descriptor(struct fw_descriptor * var471  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */
int ipmi_create_user(unsigned int           var472  ,
		     struct ipmi_user_hndl * var473  ,
		     void                  * var474  ,
		     ipmi_user_t           * var475  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */
int ipmi_destroy_user(ipmi_user_t  var476  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */
int ipmi_register_for_cmd(ipmi_user_t    var477  ,
			  unsigned char  var478  ,
			  unsigned char  var479  ,
			  unsigned int   var480  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */
int ipmi_register_smi(struct ipmi_smi_handlers * var481  ,
		      void		       * var482  ,
		      struct ipmi_device_id    * var483  ,
		      struct device            * var484  ,
		      const char               * var485  ,
		      unsigned char             var486  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */


int ipmi_smi_add_proc_entry(ipmi_smi_t  var487  , char * var488  ,
			    read_proc_t * var489  ,
			    void * var490  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */
int ipmi_smi_watcher_register(struct ipmi_smi_watcher * var491  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */
int ipmi_smi_watcher_unregister(struct ipmi_smi_watcher * var492  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */
int ipmi_unregister_for_cmd(ipmi_user_t    var493  ,
			    unsigned char  var494  ,
			    unsigned char  var495  ,
			    unsigned int   var496  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/ipmi/ipmi_msghandler.c */
int ipmi_unregister_smi(ipmi_smi_t  var497  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/misc.c */
int misc_deregister(struct miscdevice * var498  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/misc.c */
int misc_register(struct miscdevice *  var499  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/tty_port.c */
int tty_port_alloc_xmit_buf(struct tty_port * var500  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/tty_port.c */
void tty_port_free_xmit_buf(struct tty_port * var501  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/tty_ioctl.c */
#ifdef TIOCGETP
#ifdef TIOCGETC
#ifdef TIOCGLTC
#ifndef TCGETS2
#ifdef TCGETX
int n_tty_ioctl_helper(struct tty_struct * var502  , struct file * var503  ,
		       unsigned int  var504  , unsigned long  var505  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/tty_ioctl.c */
void tty_throttle(struct tty_struct * var506  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/tty_ioctl.c */
void tty_unthrottle(struct tty_struct * var507  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/tty_io.c */
int tty_register_driver(struct tty_driver * var508  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/tty_io.c */
int tty_unregister_driver(struct tty_driver * var509  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/nsc_gpio.c */
ssize_t nsc_gpio_read(struct file * var510  , char __user *  var511  ,
		      size_t  var512  , loff_t *  var513  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/nsc_gpio.c */
ssize_t nsc_gpio_write(struct file * var514  , const char __user * var515  ,
		       size_t  var516  , loff_t * var517  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/generic_serial.c */
int gs_getserial(struct gs_port * var518  , struct serial_struct __user * var519  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/generic_serial.c */
int gs_put_char(struct tty_struct *  var520  , unsigned char  var521  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/generic_serial.c */
int gs_setserial(struct gs_port * var522  , struct serial_struct __user * var523  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/char/generic_serial.c */
int gs_write(struct tty_struct *  var524  , 
                    const unsigned char * var525  , int  var526  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/i2c/i2c-core.c */
int i2c_add_adapter(struct i2c_adapter * var527  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/i2c/i2c-core.c */
int i2c_del_adapter(struct i2c_adapter * var528  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/i2c/i2c-core.c */
void i2c_del_driver(struct i2c_driver * var529  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/i2c/i2c-core.c */
struct i2c_adapter* i2c_get_adapter(int  var530  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/i2c/i2c-core.c */
int i2c_register_driver(struct module * var531  , struct i2c_driver * var532  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/i2c/i2c-core.c */
int i2c_transfer(struct i2c_adapter * var540  , struct i2c_msg * var541  , int  var542  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/dma/dmaengine.c */
int dma_async_device_register(struct dma_device * var543  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/dma/dmaengine.c */
void dma_async_device_unregister(struct dma_device * var544  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/dma/dmaengine.c */
void dmaengine_get() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/dma/dmaengine.c */
void dmaengine_put() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/ide/ide-proc.c */
void ide_proc_register_driver(ide_drive_t * var547  , struct ide_driver * var548  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/ide/ide-proc.c */
void ide_proc_unregister_driver(ide_drive_t * var549  , struct ide_driver * var550  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/ide/ide-ioctls.c */
int generic_ide_ioctl(ide_drive_t * var551  , struct block_device * var552  ,
		      unsigned int  var553  , unsigned long  var554  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/tps65010.c */
int tps65010_config_vregs1(unsigned  var555  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/tps65010.c */
int tps65010_set_gpio_out_value(unsigned  var556  , unsigned  var557  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/tps65010.c */
int tps65010_set_led(unsigned  var558  , unsigned  var559  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/tps65010.c */
int tps65010_set_low_pwr(unsigned  var560  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/tps65010.c */
int tps65010_set_vib(unsigned  var561  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/tps65010.c */
int tps65013_set_low_pwr(unsigned  var562  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/ab3100-core.c */
int ab3100_get_register(struct ab3100 * var563  , u8  var564  , u8 * var565  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/ab3100-core.c */
int ab3100_get_register_page(struct ab3100 * var566  ,
			     u8  var567  , u8 * var568  , u8  var569  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/ab3100-core.c */
int ab3100_mask_and_set_register(struct ab3100 * var570  ,
				 u8  var571  , u8  var572  , u8  var573  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/ab3100-core.c */
int ab3100_set_register(struct ab3100 * var574  , u8  var575  , u8  var576  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/twl4030-core.c */
int twl4030_i2c_read(u8  var577  , u8 * var578  , u8  var579  , unsigned  var580  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/twl4030-core.c */
int twl4030_i2c_write(u8  var581  , u8 * var582  , u8  var583  , unsigned  var584  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/ucb1x00-core.c */
/*int ucb1x00_register_driver(struct ucb1x00_driver * var585  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/ucb1x00-core.c */
/*void ucb1x00_unregister_driver(struct ucb1x00_driver * var586  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/menelaus.c */
int menelaus_set_mmc_opendrain(int  var587  , int  var588  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/menelaus.c */
int menelaus_set_mmc_slot(int  var589  , int  var590  , int  var591  , int  var592  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/mfd/menelaus.c */
int menelaus_set_slot_sel(int  var593  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/telephony/phonedev.c */
int phone_register_device(struct phone_device * var594  , int  var595  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/telephony/phonedev.c */
void phone_unregister_device(struct phone_device * var596  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/fcoe/libfcoe.c */
void fcoe_ctlr_destroy(struct fcoe_ctlr * var597  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/libfc/fc_lport.c */
int fc_fabric_login(struct fc_lport * var598  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/libfc/fc_lport.c */
int fc_fabric_logoff(struct fc_lport * var599  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/libfc/fc_lport.c */
void fc_linkdown(struct fc_lport * var600  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/libfc/fc_lport.c */
void fc_linkup(struct fc_lport * var601  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/libfc/fc_lport.c */
int fc_lport_destroy(struct fc_lport * var602  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/libfc/fc_lport.c */
int fc_lport_reset(struct fc_lport * var603  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/libfc/fc_lport.c */
int fc_set_mfs(struct fc_lport * var604  , u32  var605  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_scan.c */
struct scsi_device * __scsi_add_device(struct Scsi_Host * var606  , uint  var607  ,
				      uint  var608  , uint  var609  , void * var610  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_scan.c */
struct scsi_device * scsi_get_host_dev(struct Scsi_Host * var611  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_scan.c */
void scsi_scan_target(struct device * var612  , unsigned int  var613  ,
		      unsigned int  var614  , unsigned int  var615  , int  var616  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_transport_sas.c */
struct sas_rphy * sas_expander_alloc(struct sas_port * var617  ,
				    enum sas_device_type  var618  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_transport_sas.c */
void sas_port_add_phy(struct sas_port * var619  , struct sas_phy * var620  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_transport_sas.c */
struct sas_port * sas_port_alloc_num(struct device * var621  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_transport_sas.c */
void sas_port_delete(struct sas_port * var622  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_transport_sas.c */
void sas_port_delete_phy(struct sas_port * var623  , struct sas_phy * var624  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_transport_sas.c */
int sas_rphy_add(struct sas_rphy * var625  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_transport_sas.c */
void sas_rphy_free(struct sas_rphy * var626  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_sysfs.c */
void scsi_remove_device(struct scsi_device * var627  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_transport_spi.c */
void spi_dv_device(struct scsi_device * var628  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_ioctl.c */
int scsi_ioctl(struct scsi_device * var629  , int  var630  , void __user * var631  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/scsi_ioctl.c */
int scsi_nonblockable_ioctl(struct scsi_device * var632  , int  var633  ,
			    void __user * var634  , int  var635  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/hosts.c */
void scsi_remove_host(struct Scsi_Host * var636  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/parport/share.c */
void parport_announce_port(struct parport * var637  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/parport/share.c */
int parport_register_driver(struct parport_driver * var638  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/parport/share.c */
void parport_remove_port(struct parport * var639  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/parport/share.c */
void parport_unregister_driver(struct parport_driver * var640  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/cm_sbs.c */
/*struct proc_dir_entry * acpi_lock_ac_dir() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/cm_sbs.c */
/*struct proc_dir_entry * acpi_lock_battery_dir() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/cm_sbs.c */
void acpi_unlock_ac_dir(struct proc_dir_entry * var643  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/cm_sbs.c */
void acpi_unlock_battery_dir(struct proc_dir_entry * var644  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/processor_perflib.c */
int acpi_processor_preregister_performance(
		struct acpi_processor_performance * var645  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/processor_perflib.c */
int acpi_processor_register_performance(struct acpi_processor_performance
				    * var646  , unsigned int  var647  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/processor_perflib.c */
void acpi_processor_unregister_performance(struct acpi_processor_performance
				      * var648  , unsigned int  var649  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/pci_root.c */
acpi_status acpi_pci_osc_control_set(acpi_handle  var650  , u32  var651  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/acpi/osl.c */
void acpi_os_wait_events_complete(void * var652  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/em28xx/em28xx-core.c */
/*int em28xx_register_extension(struct em28xx_ops * var653  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/em28xx/em28xx-core.c */
/*void em28xx_unregister_extension(struct em28xx_ops * var654  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/saa7134/saa7134-core.c */
/*int saa7134_ts_register(struct saa7134_mpeg_ops * var655  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/saa7134/saa7134-core.c */
/*void saa7134_ts_unregister(struct saa7134_mpeg_ops * var656  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/cx231xx/cx231xx-core.c */
/*int cx231xx_register_extension(struct cx231xx_ops * var657  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/cx231xx/cx231xx-core.c */
/*id cx231xx_unregister_extension(struct cx231xx_ops * var658  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/gspca/gspca.c */
void gspca_disconnect(struct usb_interface * var659  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/cx88/cx88-core.c */
struct cx88_core* cx88_core_get(struct pci_dev * var660  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/cx88/cx88-core.c */
void cx88_core_put(struct cx88_core * var661  , struct pci_dev * var662  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/cx88/cx88-video.c */
int cx88_set_freq(struct cx88_core  * var663  ,
				struct v4l2_frequency * var664  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/cx88/cx88-mpeg.c */
/*int cx8802_register_driver(struct cx8802_driver * var665  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/cx88/cx88-mpeg.c */
/*int cx8802_unregister_driver(struct cx8802_driver * var666  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/usbvideo/usbvideo.c */
/*struct uvd * usbvideo_AllocateDevice(struct usbvideo * var667  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/soc_camera.c */
void soc_camera_device_unregister(struct soc_camera_device * var668  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/soc_camera.c */
int soc_camera_host_register(struct soc_camera_host * var669  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/soc_camera.c */
void soc_camera_host_unregister(struct soc_camera_host * var670  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/v4l2-ioctl.c */
long video_ioctl2(struct file * var671  ,
	       unsigned int  var672  , unsigned long  var673  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/v4l2-ioctl.c */



long video_usercopy(struct file * var674  , unsigned int  var675  , unsigned long  var676  ,
		v4l2_kioctl  var677  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/videobuf-dvb.c */
/*struct videobuf_dvb_frontend * videobuf_dvb_alloc_frontend(
	struct videobuf_dvb_frontends * var678  , int  var679  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/videobuf-dvb.c */
/*void videobuf_dvb_dealloc_frontends(struct videobuf_dvb_frontends * var680  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/videobuf-dvb.c */
/*int videobuf_dvb_find_frontend(struct videobuf_dvb_frontends * var681  ,
	struct dvb_frontend * var682  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/videobuf-dvb.c */
/*struct videobuf_dvb_frontend * videobuf_dvb_get_frontend(
	struct videobuf_dvb_frontends * var683  , int  var684  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/videobuf-dvb.c */
/*int videobuf_dvb_register_bus(struct videobuf_dvb_frontends * var685  ,
			  struct module * var686  ,
			  void * var687  ,
			  struct device * var688  ,
			  short * var689  ,
			  int  var690  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/v4l2-dev.c */
int video_register_device_index(struct video_device * var691  , int  var692  , int  var693  ,
					int  var694  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/video/v4l2-dev.c */
void video_unregister_device(struct video_device * var695  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/dvb-core/dvb_frontend.c */
/*int dvb_register_frontend(struct dvb_adapter*  var696  ,
			  struct dvb_frontend*  var697  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/dvb-core/dvb_frontend.c */
/*int dvb_unregister_frontend(struct dvb_frontend*  var698  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/dvb-core/dvbdev.c */
/*int dvb_register_adapter(struct dvb_adapter * var699  , const char * var700  ,
			 struct module * var701  , struct device * var702  ,
			 short * var703  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/dvb-core/dvbdev.c */
/*int dvb_register_device(struct dvb_adapter * var704  , struct dvb_device ** var705  ,
			const struct dvb_device * var706  , void * var707  , int  var708  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/dvb-core/dvbdev.c */
/*t dvb_unregister_adapter(struct dvb_adapter * var709  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/dvb-core/dvbdev.c */
/*id dvb_unregister_device(struct dvb_device * var710  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/dvb-core/dvb_ringbuffer.c */
/*ssize_t dvb_ringbuffer_read_user(struct dvb_ringbuffer * var711  , u8 __user * var712  , size_t  var713  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/dvb-usb/dvb-usb-urb.c */
/*int dvb_usb_generic_rw(struct dvb_usb_device * var714  , u8 * var715  , u16  var716  , u8 * var717  ,
	u16  var718  , int  var719  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/dvb/bt8xx/bt878.c */
/*int bt878_device_control(struct bt878 * var720  , unsigned int  var721  , union dst_gpio_packet * var722  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/common/tuners/xc5000.c */
/*struct dvb_frontend * xc5000_attach(struct dvb_frontend * var723  ,
				   struct i2c_adapter * var724  ,
				   struct xc5000_config * var725  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/media/common/tuners/tuner-xc2028.c */
/*struct dvb_frontend * xc2028_attach(struct dvb_frontend * var726  ,
				   struct xc2028_config * var727  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/misc/tifm_core.c */
void tifm_remove_adapter(struct tifm_adapter * var728  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/misc/ioc4.c */
int ioc4_register_submodule(struct ioc4_submodule * var729  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/misc/ioc4.c */
void ioc4_unregister_submodule(struct ioc4_submodule * var730  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pci/pcie/aspm.c */
void pci_disable_link_state(struct pci_dev * var731  , int  var732  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pci/search.c */
struct pci_bus * pci_find_next_bus(const struct pci_bus * var733  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pci/search.c */



struct pci_dev * pci_get_slot(struct pci_bus * var734  , unsigned int  var735  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pci/remove.c */


void pci_remove_bus(struct pci_bus * var736  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pci/bus.c */
void pci_bus_add_devices(const struct pci_bus * var737  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pci/probe.c */
struct pci_bus *__ref pci_add_new_bus(struct pci_bus * var738  , struct pci_dev * var739  , int  var740  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/xen/xenbus/xenbus_xs.c */
void * xenbus_dev_request_and_reply(struct xsd_sockmsg * var741  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}


/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pnp/manager.c */
int pnp_disable_dev(struct pnp_dev * var744  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/w1/w1_int.c */
/*int w1_add_master_device(struct w1_bus_master * var745  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

int register_cdrom(struct cdrom_device_info * var746  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/cdrom/cdrom.c */


void unregister_cdrom(struct cdrom_device_info * var747  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/video/display/display-sysfs.c */
struct display_device * display_device_register(struct display_driver * var748  ,
						struct device * var749  , void * var750  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/video/display/display-sysfs.c */
void display_device_unregister(struct display_device * var751  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/video/backlight/lcd.c */
void lcd_device_unregister(struct lcd_device * var752  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/video/backlight/backlight.c */
struct backlight_device * backlight_device_register(const char * var753  ,
		struct device * var754  , void * var755  , struct backlight_ops * var756  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/video/backlight/backlight.c */
void backlight_device_unregister(struct backlight_device * var757  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/video/backlight/generic_bl.c */
void corgibl_limit_intensity(int  var758  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/video/fbmem.c */
int lock_fb_info(struct fb_info * var759  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/video/sbuslib.c */
int sbusfb_ioctl_helper(unsigned long  var760  , unsigned long  var761  ,
			struct fb_info * var762  ,
			int  var763  , int  var764  , unsigned long  var765  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/s390/char/sclp_cpi_sys.c */
int sclp_cpi_set_data(const char * var766  , const char * var767  , const char * var768  ,
		      const u64  var769  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/s390/char/keyboard.c */
/*int kbd_ioctl(struct kbd_data * var770  , struct file * var771  ,
	  unsigned int  var772  , unsigned long  var773  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/s390/char/raw3270.c */
/*int raw3270_add_view(struct raw3270_view * var774  , struct raw3270_fn * var775  , int  var776  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/s390/char/raw3270.c */
/*struct raw3270_view * raw3270_find_view(struct raw3270_fn * var777  , int  var778  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/s390/cio/ccwgroup.c */
/*int ccwgroup_create_from_string(struct device * var779  , unsigned int  var780  ,
				struct ccw_driver * var781  , int  var782  ,
				const char * var783  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/s390/cio/ccwgroup.c */
/*void ccwgroup_driver_unregister(struct ccwgroup_driver * var784  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/ttm/ttm_memory.c */
/*void ttm_mem_global_release(struct ttm_mem_global * var785  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/ttm/ttm_bo_util.c */
/*void ttm_bo_kunmap(struct ttm_bo_kmap_obj * var786  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/ttm/ttm_global.c */
/*int ttm_global_item_ref(struct ttm_global_reference * var787  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/ttm/ttm_global.c */
/*void ttm_global_item_unref(struct ttm_global_reference * var788  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_bufs.c */
/*#if __OS_HAS_AGP


int drm_addbufs_agp(struct drm_device *  var789  , struct drm_buf_desc *  var790  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_bufs.c */


/*int drm_addbufs_pci(struct drm_device *  var791  , struct drm_buf_desc *  var792  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_bufs.c */
/*int drm_rmmap(struct drm_device * var793  , struct drm_local_map * var794  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_gem.c */
int drm_gem_mmap(struct file * var795  , struct vm_area_struct * var796  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_gem.c */
void drm_gem_vm_close(struct vm_area_struct * var797  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_vm.c */
/*#if __OS_HAS_AGP
#if defined(__i386__) || defined(__x86_64__)
#ifdef __alpha__
#if defined(__powerpc__)
int drm_mmap(struct file * var798  , struct vm_area_struct * var799  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_crtc.c */
/*void drm_connector_cleanup(struct drm_connector * var800  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_crtc.c */
/*void drm_connector_init(struct drm_device * var801  ,
		     struct drm_connector * var802  ,
		     const struct drm_connector_funcs * var803  ,
		     int  var804  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_crtc.c */
/*void drm_crtc_init(struct drm_device * var805  , struct drm_crtc * var806  ,
		   const struct drm_crtc_funcs * var807  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_crtc.c */
/*void drm_encoder_cleanup(struct drm_encoder * var808  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_crtc.c */
/*void drm_encoder_init(struct drm_device * var809  ,
		      struct drm_encoder * var810  ,
		      const struct drm_encoder_funcs * var811  ,
		      int  var812  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_crtc.c */
/*void drm_mode_config_init(struct drm_device * var813  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_crtc.c */
/*void * drm_mode_object_find(struct drm_device * var814  , uint32_t  var815  , uint32_t  var816  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_drv.c */
int drm_ioctl(struct inode * var817  , struct file * var818  ,
	      unsigned int  var819  , unsigned long  var820  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_memory.c */
/*void drm_core_ioremapfree(struct drm_local_map * var821  , struct drm_device * var822  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_fops.c */
int drm_open(struct inode * var823  , struct file * var824  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_fops.c */
int drm_release(struct inode * var825  , struct file * var826  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_irq.c */
/*int drm_irq_install(struct drm_device * var827  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/gpu/drm/drm_irq.c */
/*int drm_irq_uninstall(struct drm_device *  var828  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/soc_common.c */
int soc_common_drv_pcmcia_remove(struct device * var829  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pccard_register_pcmcia(struct pcmcia_socket * var830  , struct pcmcia_callback * var831  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pcmcia_eject_card(struct pcmcia_socket * var832  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
struct pcmcia_socket * pcmcia_get_socket_by_nr(unsigned int  var833  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pcmcia_insert_card(struct pcmcia_socket * var834  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pcmcia_register_socket(struct pcmcia_socket * var835  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pcmcia_reset_card(struct pcmcia_socket * var836  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pcmcia_resume_card(struct pcmcia_socket * var837  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pcmcia_socket_dev_resume(struct device * var838  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pcmcia_socket_dev_suspend(struct device * var839  , pm_message_t  var840  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
int pcmcia_suspend_card(struct pcmcia_socket * var841  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/pcmcia/cs.c */
void pcmcia_unregister_socket(struct pcmcia_socket * var842  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/serial/serial_core.c */
int uart_add_one_port(struct uart_driver * var843  , struct uart_port * var844  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/serial/serial_core.c */
int uart_remove_one_port(struct uart_driver * var845  , struct uart_port * var846  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/serial/serial_core.c */
int uart_resume_port(struct uart_driver * var847  , struct uart_port * var848  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/serial/serial_core.c */
int uart_suspend_port(struct uart_driver * var849  , struct uart_port * var850  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/serial/nwpserial.c */
int nwpserial_register_port(struct uart_port * var851  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/serial/nwpserial.c */
void nwpserial_unregister_port(int  var852  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/serial/8250.c */
int serial8250_register_port(struct uart_port * var853  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/serial/8250.c */
void serial8250_unregister_port(int  var854  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/staging/rtl8192su/ieee80211/ieee80211_softmac.c */
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,5,0)
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,20))
#ifdef ENABLE_DOT11D
#ifdef ENABLE_DOT11D
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,20)
#if 1
#if 0
#if 0
#if 0
#ifdef USB_TX_DRIVER_AGGREGATION_ENABLE
#ifdef ENABLE_DOT11D //if creating an ad-hoc, set its channel to 10 temporarily--this is the requirement for ASUS, not 11D, so disable 11d.
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
#ifdef PF_SYNCTHREAD
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,5,0)

int ieee80211_wpa_supplicant_ioctl(struct ieee80211_device * var855  , struct iw_point * var856  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/md/dm-table.c */
/*void dm_table_event(struct dm_table * var859  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/md/dm-target.c */
/*int dm_register_target(struct target_type * var860  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/md/dm-target.c */
/*void dm_unregister_target(struct target_type * var861  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/isdn/capi/kcapi.c */
int attach_capi_ctr(struct capi_ctr * var862  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/isdn/capi/kcapi.c */




int capi20_manufacturer(unsigned int  var863  , void __user * var864  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/isdn/capi/kcapi.c */
u16 capi20_register(struct capi20_appl * var865  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/isdn/capi/kcapi.c */
u16 capi20_release(struct capi20_appl * var866  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/isdn/capi/capifs.c */
void capifs_free_ncci(unsigned int  var867  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/platform/x86/sony-laptop.c */
int sony_pic_camera_command(int  var872  , u8  var873  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/cxgb3/cxgb3_offload.c */
/*void cxgb3_register_client(struct cxgb3_client * var874  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/cxgb3/cxgb3_offload.c */
/*void cxgb3_unregister_client(struct cxgb3_client * var875  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/hostap/hostap_main.c */


#define PRISM2_MAX_FRAME_SIZE 2304
#define PRISM2_MIN_MTU 256

#define PRISM2_MAX_MTU (PRISM2_MAX_FRAME_SIZE - (6  + 8 ))


/*struct net_device * hostap_add_interface(struct local_info * var876  ,
					 int  var877  , int  var878  ,
					 const char * var879  ,
					 const char * var880  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-scan.c */
void iwl_bg_abort_scan(struct work_struct * var881  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-scan.c */


void iwl_bg_scan_check(struct work_struct * var882  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-scan.c */
void iwl_bg_scan_completed(struct work_struct * var883  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-scan.c */


int iwl_mac_hw_scan(struct ieee80211_hw * var884  ,
		     struct cfg80211_scan_request * var885  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-scan.c */
/*int iwl_scan_cancel_timeout(struct iwl_priv * var886  , unsigned long  var887  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-core.c */

void iwl_bss_info_changed(struct ieee80211_hw * var888  ,
			  struct ieee80211_vif * var889  ,
			  struct ieee80211_bss_conf * var890  ,
			  u32  var891  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-core.c */
int iwl_mac_add_interface(struct ieee80211_hw * var892  ,
				 struct ieee80211_if_init_conf * var893  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-core.c */
int iwl_mac_config(struct ieee80211_hw * var894  , u32  var895  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-core.c */
void iwl_mac_remove_interface(struct ieee80211_hw * var896  ,
				     struct ieee80211_if_init_conf * var897  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/wireless/iwlwifi/iwl-core.c */
void iwl_mac_reset_tsf(struct ieee80211_hw * var898  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/irda/sir_dongle.c */
/*int irda_register_dongle(struct dongle_driver * var899  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/irda/sir_dongle.c */
/*int irda_unregister_dongle(struct dongle_driver * var900  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/phy/phy.c */
void phy_start(struct phy_device * var901  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/phy/phy.c */
int phy_start_aneg(struct phy_device * var902  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/phy/phy.c */
void phy_stop(struct phy_device * var903  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/phy/phy_device.c */
int genphy_resume(struct phy_device * var904  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/phy/phy_device.c */
int genphy_suspend(struct phy_device * var905  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/phy/phy_device.c */
int phy_scan_fixups(struct phy_device * var906  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/phy/mdio_bus.c */
int mdiobus_read(struct mii_bus * var907  , int  var908  , u16  var909  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/phy/mdio_bus.c */
int mdiobus_write(struct mii_bus * var910  , int  var911  , u16  var912  , u16  var913  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/cnic.c */
/*int cnic_register_driver(int  var914  , struct cnic_ulp_ops * var915  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/cnic.c */
int cnic_unregister_driver(int  var916  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/pppox.c */
int pppox_ioctl(struct socket * var917  , unsigned int  var918  , unsigned long  var919  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/net/ppp_generic.c */
void ppp_unregister_channel(struct ppp_channel * var920  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}



/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/sparc/kernel/prom_common.c */
int of_set_property(struct device_node * var925  , const char * var926  , void * var927  , int  var928  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/sh/mm/ioremap_64.c */
void __iomem * __ioremap(unsigned long  var929  , unsigned long  var930  ,
			unsigned long  var931  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/sh/mm/ioremap_64.c */
void __iounmap(void __iomem * var932  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/mm/mem.c */
#ifdef CONFIG_MEMORY_HOTPLUG
#ifndef CONFIG_NEED_MULTIPLE_NODES
#ifdef CONFIG_HIGHMEM
#ifdef CONFIG_PPC32
#ifdef CONFIG_HIGHMEM
#ifdef CONFIG_NEED_MULTIPLE_NODES
#ifdef CONFIG_NOT_COHERENT_CACHE
#ifdef CONFIG_BOOKE
#if 0
void flush_icache_user_range(struct vm_area_struct * var944  , struct page * var945  ,
			     unsigned long  var946  , int  var947  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/kernel/rtas.c */
int rtas_get_sensor(int  var961  , int  var962  , int * var963  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/kernel/rtas.c */
int rtas_set_indicator(int  var964  , int  var965  , int  var966  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/kernel/rtas.c */
int rtas_set_power_level(int  var967  , int  var968  , int * var969  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/kernel/clock.c */
void clk_disable(struct clk * var970  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/kernel/clock.c */
int clk_enable(struct clk * var971  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/kernel/clock.c */
struct clk * clk_get(struct device * var972  , const char * var973  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/kernel/clock.c */
int clk_set_parent(struct clk * var974  , struct clk * var975  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/powerpc/kernel/clock.c */
int clk_set_rate(struct clk * var976  , unsigned long  var977  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}


/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/ia64/lib/csum_partial_copy.c */
/*__wsum csum_partial_copy_nocheck(const void * var998  , void * var999  , int  var1000  , __wsum  var1001  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/mips/bcm47xx/gpio.c */
void gpio_free(unsigned  var1006  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/blackfin/lib/checksum.c */
__wsum csum_partial_copy(const void * var1023  , void * var1024  , int  var1025  , __wsum  var1026  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/mn10300/lib/checksum.c */
/*__wsum csum_and_copy_to_user(const void * var1058  , void * var1059  ,
			     int  var1060  , __wsum  var1061  ,
			     int * var1062  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/avr32/kernel/process.c */
#ifdef CONFIG_FRAME_POINTER

void show_regs(struct pt_regs * var1092  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/x86/kernel/scx200_32.c */
u32 scx200_gpio_configure(unsigned  var1094  , u32  var1095  , u32  var1096  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/x86/lib/usercopy_64.c */
unsigned long __clear_user(void __user * var1097  , unsigned long  var1098  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/x86/lib/usercopy_64.c */
unsigned long clear_user(void __user * var1099  , unsigned long  var1100  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/x86/lib/usercopy_64.c */
/*long strlen_user(const char __user * var1104  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/


long __strncpy_from_user(char * var1105  , const char __user * var1106  , long  var1107  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/x86/lib/usercopy_64.c */
long strncpy_from_user(char * var1108  , const char __user * var1109  , long  var1110  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/x86/lib/usercopy_64.c */
long __strnlen_user(const char __user * var1111  , long  var1112  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/x86/lib/usercopy_64.c */
long strnlen_user(const char __user * var1113  , long  var1114  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

unsigned long __copy_to_user_ll(void __user * var1134  , const void * var1135  ,
				unsigned long  var1136  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/s390/mm/extmem.c */
int segment_load(char * var1178  , int  var1179  , unsigned long * var1180  ,
		unsigned long * var1181  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/s390/mm/extmem.c */
int segment_modify_shared(char * var1182  , int  var1183  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/s390/mm/extmem.c */
void segment_save(char * var1184  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/s390/mm/extmem.c */
void segment_unload(char * var1185  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/s390/kernel/sysinfo.c */
/*int register_service_level(struct service_level * var1186  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/s390/kernel/sysinfo.c */
/*int unregister_service_level(struct service_level * var1187  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/plat-s3c24xx/pwm.c */
void pwm_free(struct pwm_device * var1204  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/plat-s3c24xx/pwm.c */
struct pwm_device * pwm_request(int  var1205  , const char * var1206  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/plat-mxc/iomux-mx1-mx2.c */
void mxc_gpio_release_multiple_pins(const int * var1214  , int  var1215  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/plat-mxc/clock.c */
#ifndef CONFIG_COMMON_CLKDEV


int clk_register(struct clk * var1220  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/plat-mxc/clock.c */
#ifndef CONFIG_COMMON_CLKDEV
void clk_unregister(struct clk * var1225  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mach-pxa/ssp.c */
/*void ssp_free(struct ssp_device * var1226  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mach-pxa/ssp.c */
struct ssp_device * ssp_request(int  var1227  , const char * var1228  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mm/ioremap.c */




void __iomem * __arm_ioremap_pfn(unsigned long  var1235  , unsigned long  var1236  , size_t  var1237  ,
		  unsigned int  var1238  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mach-u300/gpio.c */
#ifdef U300_COH901571_3
#ifdef CONFIG_MACH_U300_BS335
#ifdef CONFIG_MACH_U300_BS365
int gpio_direction_input(unsigned  var1269  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mach-u300/gpio.c */
#ifdef U300_COH901571_3
#ifdef CONFIG_MACH_U300_BS335
#ifdef CONFIG_MACH_U300_BS365
int gpio_direction_output(unsigned  var1270  , int  var1271  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/plat-omap/devices.c */
#if	defined(CONFIG_OMAP_DSP) || defined(CONFIG_OMAP_DSP_MODULE)

int dsp_kfunc_device_register(struct dsp_kfunc_device * var1279  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/common/clkdev.c */
/*void clkdev_add(struct clk_lookup * var1302  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/common/clkdev.c */
/*void clkdev_drop(struct clk_lookup * var1303  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/common/clkdev.c */
struct clk * clk_get_sys(const char * var1306  , const char * var1307  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mach-netx/pfifo.c */
void pfifo_free(unsigned int  var1338  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mach-netx/pfifo.c */
int pfifo_request(unsigned int  var1339  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mach-netx/xc.c */
/*void free_xc(struct xc * var1340  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/arm/mach-netx/xc.c */
struct xc * request_xc(int  var1341  , struct device * var1342  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/oss/midi_synth.c */
int midi_synth_ioctl(int  var1387  , unsigned int  var1388  , void __user * var1389  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/oss/midi_synth.c */
int midi_synth_load_patch(int  var1390  , int  var1391  , const char __user * var1392  ,
		      int  var1393  , int  var1394  , int  var1395  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/oss/ac97_codec.c */
/*int ac97_probe_codec(struct ac97_codec * var1396  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/oss/ac97_codec.c */
/*void ac97_release_codec(struct ac97_codec * var1397  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/isa/sb/emu8000.c */
int snd_emu8000_load_chorus_fx(struct snd_emu8000 * var1398  , int  var1399  , const void __user * var1400  , long  var1401  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/isa/sb/emu8000.c */
int snd_emu8000_load_reverb_fx(struct snd_emu8000 * var1402  , int  var1403  , const void __user * var1404  , long  var1405  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/seq/seq_clientmgr.c */

#define snd_seq_ioctl_compat	NULL
#endif






/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/seq/seq_memory.c */
int snd_seq_dump_var_event(const struct snd_seq_event * var1410  ,
			   snd_seq_dump_func_t  var1411  , void * var1412  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/seq/seq_memory.c */
int snd_seq_expand_var_event(const struct snd_seq_event * var1413  , int  var1414  , char * var1415  ,
			     int  var1416  , int  var1417  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/seq/seq_device.c */


void snd_seq_device_load_drivers() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/seq/seq_device.c */
int snd_seq_device_new(struct snd_card * var1419  , int  var1420  , char * var1421  , int  var1422  ,
		       struct snd_seq_device ** var1423  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/seq/seq_device.c */
int snd_seq_device_register_driver(char * var1424  , struct snd_seq_dev_ops * var1425  ,
				   int  var1426  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/seq/seq_device.c */
int snd_seq_device_unregister_driver(char * var1427  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/info_oss.c */
#if defined(CONFIG_SND_OSSEMUL) && defined(CONFIG_PROC_FS)
int snd_oss_info_register(int  var1428  , int  var1429  , char * var1430  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/pcm.c */
#ifdef CONFIG_SND_VERBOSE_PROCFS
#if defined(CONFIG_SND_PCM_OSS) || defined(CONFIG_SND_PCM_OSS_MODULE)
#if defined(CONFIG_SND_PCM_OSS) || defined(CONFIG_SND_PCM_OSS_MODULE)

int snd_pcm_notify(struct snd_pcm_notify * var1431  , int  var1432  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/memalloc.c */
size_t snd_dma_get_reserved_buf(struct snd_dma_buffer * var1433  , unsigned int  var1434  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/memalloc.c */
int snd_dma_reserve_buf(struct snd_dma_buffer * var1435  , unsigned int  var1436  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/info.c */
#ifdef CONFIG_PROC_FS
void snd_info_free_entry(struct snd_info_entry *  var1437  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/info.c */
#ifdef CONFIG_PROC_FS
int snd_info_register(struct snd_info_entry *  var1438  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/timer.c */
int snd_timer_close(struct snd_timer_instance * var1439  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/timer.c */
int snd_timer_open(struct snd_timer_instance ** var1440  ,
		   char * var1441  , struct snd_timer_id * var1442  ,
		   unsigned int  var1443  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/sound_oss.c */
#ifdef CONFIG_SND_OSSEMUL
void * snd_lookup_oss_minor_data(unsigned int  var1444  , int  var1445  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/sound_oss.c */
#ifdef CONFIG_SND_OSSEMUL
int snd_register_oss_device(int  var1446  , struct snd_card * var1447  , int  var1448  ,
			    const struct file_operations * var1449  , void * var1450  ,
			    const char * var1451  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/sound_oss.c */
#ifdef CONFIG_SND_OSSEMUL
int snd_unregister_oss_device(int  var1452  , struct snd_card * var1453  , int  var1454  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/init.c */

#define init_info_for_card(card)


int snd_card_create(int  var1455  , const char * var1456  ,
		    struct module * var1457  , int  var1458  ,
		    struct snd_card ** var1459  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/init.c */
int snd_card_disconnect(struct snd_card * var1460  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/init.c */



int snd_card_register(struct snd_card * var1461  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/init.c */
void snd_card_set_id(struct snd_card * var1462  , const char * var1463  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/rawmidi.c */
int snd_rawmidi_info_select(struct snd_card * var1464  , struct snd_rawmidi_info * var1465  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/rawmidi.c */
int snd_rawmidi_kernel_open(struct snd_card * var1466  , int  var1467  , int  var1468  ,
			    int  var1469  , struct snd_rawmidi_file *  var1470  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/sound.c */
#ifdef CONFIG_MODULES
#ifdef CONFIG_SND_DYNAMIC_MINORS
#ifdef CONFIG_SND_DYNAMIC_MINORS

int snd_add_device_sysfs_file(int  var1477  , struct snd_card * var1478  , int  var1479  ,
			      struct device_attribute * var1480  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/sound.c */



void * snd_lookup_minor_data(unsigned int  var1481  , int  var1482  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/sound.c */
#ifdef CONFIG_MODULES
#ifdef CONFIG_SND_DYNAMIC_MINORS




int snd_register_device_for_dev(int  var1483  , struct snd_card * var1484  , int  var1485  ,
				const struct file_operations * var1486  ,
				void * var1487  ,
				const char * var1488  , struct device * var1489  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/sound.c */
#ifdef CONFIG_MODULES
#ifdef CONFIG_SND_DYNAMIC_MINORS
#ifdef CONFIG_SND_DYNAMIC_MINORS

int snd_unregister_device(int  var1490  , struct snd_card * var1491  , int  var1492  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/control.c */
int snd_ctl_add(struct snd_card * var1493  , struct snd_kcontrol * var1494  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/control.c */
int snd_ctl_remove_id(struct snd_card * var1495  , struct snd_ctl_elem_id * var1496  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/core/control.c */
int snd_ctl_rename_id(struct snd_card * var1497  , struct snd_ctl_elem_id * var1498  ,
		      struct snd_ctl_elem_id * var1499  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/pci/emu10k1/memory.c */
struct snd_util_memblk * snd_emu10k1_synth_alloc(struct snd_emu10k1 * var1510  , unsigned int  var1511  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/pci/emu10k1/memory.c */
int snd_emu10k1_synth_copy_from_user(struct snd_emu10k1 * var1512  , struct snd_util_memblk * var1513  ,
				     int  var1514  , const char __user * var1515  , int  var1516  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/pci/emu10k1/memory.c */
int snd_emu10k1_synth_free(struct snd_emu10k1 * var1517  , struct snd_util_memblk * var1518  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/synth/util_mem.c */
struct snd_util_memblk * snd_util_mem_alloc(struct snd_util_memhdr * var1519  , int  var1520  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/synth/util_mem.c */
int snd_util_mem_avail(struct snd_util_memhdr * var1521  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/synth/util_mem.c */
int snd_util_mem_free(struct snd_util_memhdr * var1522  , struct snd_util_memblk * var1523  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/usb/usbmidi.c */
void snd_usbmidi_disconnect(struct list_head*  var1524  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/sound/usb/usbmidi.c */
void snd_usbmidi_input_stop(struct list_head*  var1525  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/lib/percpu_counter.c */
void percpu_counter_destroy(struct percpu_counter * var1526  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/lib/percpu_counter.c */
int __percpu_counter_init(struct percpu_counter * var1527  , s64  var1528  ,
			  struct lock_class_key * var1529  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/lib/scatterlist.c */
bool sg_miter_next(struct sg_mapping_iter * var1530  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/9p/client.c */
int p9_client_read(struct p9_fid * var1540  , char * var1541  , char __user * var1542  , u64  var1543  ,
								u32  var1544  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/ipvs/ip_vs_app.c */
int register_ip_vs_app(struct ip_vs_app * var1545  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/ipvs/ip_vs_app.c */
int register_ip_vs_app_inc(struct ip_vs_app * var1546  , __u16  var1547  , __u16  var1548  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/ipvs/ip_vs_app.c */
void unregister_ip_vs_app(struct ip_vs_app * var1549  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/x_tables.c */
struct xt_match * xt_find_match(u8  var1550  , const char * var1551  , u8  var1552  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/x_tables.c */
struct xt_target * xt_find_target(u8  var1553  , const char * var1554  , u8  var1555  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/x_tables.c */
int xt_register_match(struct xt_match * var1556  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/x_tables.c */
int xt_register_target(struct xt_target * var1557  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/x_tables.c */
void xt_unregister_match(struct xt_match * var1558  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/x_tables.c */
void xt_unregister_target(struct xt_target * var1559  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/nf_log.c */
int nf_log_bind_pf(u_int8_t  var1560  , const struct nf_logger * var1561  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/nf_log.c */
int nf_log_register(u_int8_t  var1562  , struct nf_logger * var1563  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/nf_log.c */
void nf_log_unbind_pf(u_int8_t  var1564  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/nf_log.c */
void nf_log_unregister(struct nf_logger * var1565  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/nf_sockopt.c */
int nf_register_sockopt(struct nf_sockopt_ops * var1566  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/nf_sockopt.c */
void nf_unregister_sockopt(struct nf_sockopt_ops * var1567  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/nf_queue.c */
int nf_register_queue_handler(u_int8_t  var1568  , const struct nf_queue_handler * var1569  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/nf_queue.c */
int nf_unregister_queue_handler(u_int8_t  var1570  , const struct nf_queue_handler * var1571  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/core.c */
int nf_register_hook(struct nf_hook_ops * var1572  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/netfilter/core.c */
void nf_unregister_hook(struct nf_hook_ops * var1573  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/iucv/iucv.c */
/*int iucv_register(struct iucv_handler * var1574  , int  var1575  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/iucv/iucv.c */
/*void iucv_unregister(struct iucv_handler * var1576  , int  var1577  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}*/

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/mac80211/main.c */
int ieee80211_register_hw(struct ieee80211_hw * var1578  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/mac80211/scan.c */
void ieee80211_scan_completed(struct ieee80211_hw * var1579  , bool  var1580  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/mac80211/rate.c */
int ieee80211_rate_control_register(struct rate_control_ops * var1581  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/mac80211/rate.c */
void ieee80211_rate_control_unregister(struct rate_control_ops * var1582  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/xfrm/xfrm_state.c */
int xfrm_user_policy(struct sock * var1583  , int  var1584  , u8 __user * var1585  , int  var1586  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/bluetooth/af_bluetooth.c */
int bt_sock_ioctl(struct socket * var1587  , unsigned int  var1588  , unsigned long  var1589  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/wimax/op-rfkill.c */
int wimax_rfkill(struct wimax_dev * var1590  , enum wimax_rf_state  var1591  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/wimax/op-reset.c */
int wimax_reset(struct wimax_dev * var1592  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/wireless/reg.c */
void regulatory_hint_11d(struct wiphy * var1593  ,
			u8 * var1594  ,
			u8  var1595  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/wireless/reg.c */
void wiphy_apply_custom_regulatory(struct wiphy * var1596  ,
				   const struct ieee80211_regdomain * var1597  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/wireless/core.c */
struct wiphy * wiphy_new(const struct cfg80211_ops * var1598  , int  var1599  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/wireless/core.c */
int wiphy_register(struct wiphy * var1600  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/wireless/core.c */
void wiphy_unregister(struct wiphy * var1601  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/rtnetlink.c */
void rtnl_lock() {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/sock.c */
int sock_get_timestamp(struct sock * var1603  , struct timeval __user * var1604  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/sock.c */
int sock_get_timestampns(struct sock * var1605  , struct timespec __user * var1606  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/sock.c */
ssize_t sock_no_sendpage(struct socket * var1607  , struct page * var1608  , int  var1609  , size_t  var1610  , int  var1611  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/sock.c */
int sock_setsockopt(struct socket * var1612  , int  var1613  , int  var1614  ,
		    char __user * var1615  , int  var1616  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/dev.c */
int dev_close(struct net_device * var1617  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/dev.c */
int dev_open(struct net_device * var1618  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/dev.c */
void dev_remove_pack(struct packet_type * var1619  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/dev.c */
#if defined(CONFIG_BRIDGE) || defined (CONFIG_BRIDGE_MODULE)
#if defined(CONFIG_MACVLAN) || defined(CONFIG_MACVLAN_MODULE)
#ifdef CONFIG_NET_CLS_ACT
#ifdef CONFIG_NET_CLS_ACT
#ifdef CONFIG_NETPOLL
#ifdef CONFIG_NET_DMA
#ifdef CONFIG_PROC_FS


#define dev_proc_init() 0
#endif	



int netdev_set_master(struct net_device * var1620  , struct net_device * var1621  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/dev.c */
#if defined(CONFIG_BRIDGE) || defined (CONFIG_BRIDGE_MODULE)
#if defined(CONFIG_MACVLAN) || defined(CONFIG_MACVLAN_MODULE)
#ifdef CONFIG_NET_CLS_ACT
#ifdef CONFIG_NET_CLS_ACT
#ifdef CONFIG_NETPOLL
#ifdef CONFIG_NET_DMA
#ifdef CONFIG_PROC_FS

int register_netdev(struct net_device * var1622  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/neighbour.c */
#ifdef CONFIG_SYSCTL
void neigh_sysctl_unregister(struct neigh_parms * var1623  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/datagram.c */
int skb_copy_datagram_const_iovec(const struct sk_buff * var1624  , int  var1625  ,
				  const struct iovec * var1626  , int  var1627  ,
				  int  var1628  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/datagram.c */
int skb_copy_datagram_from_iovec(struct sk_buff * var1629  , int  var1630  ,
				 const struct iovec * var1631  , int  var1632  ,
				 int  var1633  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/datagram.c */
int skb_copy_datagram_iovec(const struct sk_buff * var1634  , int  var1635  ,
			    struct iovec * var1636  , int  var1637  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/iovec.c */
int csum_partial_copy_fromiovecend(unsigned char * var1638  , struct iovec * var1639  ,
				 int  var1640  , unsigned int  var1641  , __wsum * var1642  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/iovec.c */
int memcpy_fromiovec(unsigned char * var1643  , struct iovec * var1644  , int  var1645  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/iovec.c */
int memcpy_fromiovecend(unsigned char * var1646  , const struct iovec * var1647  ,
			int  var1648  , int  var1649  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/iovec.c */
int memcpy_toiovec(struct iovec * var1650  , unsigned char * var1651  , int  var1652  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/iovec.c */
int memcpy_toiovecend(const struct iovec * var1653  , unsigned char * var1654  ,
		      int  var1655  , int  var1656  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/scm.c */
int put_cmsg(struct msghdr *  var1657  , int  var1658  , int  var1659  , int  var1660  , void * var1661  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/core/scm.c */
void scm_detach_fds(struct msghdr * var1662  , struct scm_cookie * var1663  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv6/af_inet6.c */
void inet6_unregister_protosw(struct inet_protosw * var1664  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv6/ipv6_sockglue.c */
#ifdef CONFIG_COMPAT
#ifdef CONFIG_NETFILTER

int compat_ipv6_getsockopt(struct sock * var1665  , int  var1666  , int  var1667  ,
			   char __user * var1668  , int __user * var1669  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv6/ipv6_sockglue.c */
#ifdef CONFIG_COMPAT
int ipv6_getsockopt(struct sock * var1670  , int  var1671  , int  var1672  ,
		    char __user * var1673  , int __user * var1674  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv6/protocol.c */
int inet6_del_protocol(struct inet6_protocol * var1675  , unsigned char  var1676  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}




/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/rfkill/core.c */
int __must_check rfkill_register(struct rfkill * var1683  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/rfkill/core.c */
void rfkill_unregister(struct rfkill * var1684  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/atm/resources.c */
void atm_dev_deregister(struct atm_dev * var1685  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/atm/resources.c */
struct atm_dev * atm_dev_lookup(int  var1686  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/atm/resources.c */
struct atm_dev * atm_dev_register(const char * var1687  , const struct atmdev_ops * var1688  ,
				 int  var1689  , unsigned long * var1690  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/atm/ioctl.c */
void deregister_atm_ioctl(struct atm_ioctl * var1691  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/atm/ioctl.c */
void register_atm_ioctl(struct atm_ioctl * var1692  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/bridge/netfilter/ebtables.c */
struct ebt_table * ebt_register_table(struct net * var1693  , struct ebt_table * var1694  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/bridge/netfilter/ebtables.c */
void ebt_unregister_table(struct ebt_table * var1695  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}


/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv4/af_inet.c */
void inet_unregister_protosw(struct inet_protosw * var1700  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv4/ip_sockglue.c */
#ifdef CONFIG_COMPAT
#ifdef CONFIG_NETFILTER

int compat_ip_getsockopt(struct sock * var1701  , int  var1702  , int  var1703  ,
			 char __user * var1704  , int __user * var1705  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv4/ip_sockglue.c */
#ifdef CONFIG_COMPAT
int ip_getsockopt(struct sock * var1706  , int  var1707  ,
		  int  var1708  , char __user * var1709  , int __user * var1710  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}
#endif

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv4/tcp.c */
int tcp_ioctl(struct sock * var1711  , int  var1712  , unsigned long  var1713  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv4/protocol.c */
int inet_del_protocol(struct net_protocol * var1714  , unsigned char  var1715  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv4/udp.c */
int udp_ioctl(struct sock * var1716  , int  var1717  , unsigned long  var1718  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/ipv4/udp.c */


int udp_lib_getsockopt(struct sock * var1719  , int  var1720  , int  var1721  ,
		       char __user * var1722  , int __user * var1723  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/802/psnap.c */
void unregister_snap_client(struct datalink_proto * var1724  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/compat.c */
int compat_sock_get_timestamp(struct sock * var1725  , struct timeval __user * var1726  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

/* LOCATION: /mnt/second/iceberg/ldv/toolset2/linux-2.6.31/net/compat.c */
int compat_sock_get_timestampns(struct sock * var1727  , struct timespec __user * var1728  ) {
	ldv_assert(ldv_lock == 0 && IN_INTERRUPT==0);
	return 0;
}

