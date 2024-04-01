ARCH ?= arm64
HOST ?= aarch64-linux-gnu
CROSS_COMPILE ?= aarch64-linux-gnu-

OUTPUT ?= $(CURDIR)/output
OUTPUT_BUSYBOX ?= $(OUTPUT)/busybox
OUTPUT_ETHTOOL ?= $(OUTPUT)/ethtool
OUTPUT_KERNEL ?= $(OUTPUT)/kernel
OUTPUT_PERF ?= $(OUTPUT)/perf
OUTPUT_ROOTFS ?= $(OUTPUT)/rootfs

SRC_BUSYBOX ?= $(CURDIR)/busybox/busybox-1.30.0
SRC_ETHTOOL ?= $(CURDIR)/ethtool/ethtool-5.2.tar.gz
SRC_KERNEL ?= $(CURDIR)/kernel/linux-5.0
SRC_ROOTFS ?= $(CURDIR)/rootfs
SRC_PERF ?= $(SRC_KERNEL)/tools/perf

ifeq ($(JOBS),)
JOBS :=$(SHELL grep -c ^processor /proc/cpuinfo	2 > /dev/null)
ifeq ($(JOBS),)
JOBS :=1
endif
endif

all: dtb perf rootfs busybox ethtool kernel pack

dtb: 
	$(Q)mkdir -p $(OUTPUT)

busybox:
	$(Q)mkdir -p $(OUTPUT_BUSYBOX)
	$(Q)make	ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(SRC_BUSYBOX) O=$(OUTPUT_BUSYBOX) -j$(JOBS) defconfig
	$(Q)make	ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(SRC_BUSYBOX) O=$(OUTPUT_BUSYBOX) -j$(JOBS)
	$(Q)make	ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(SRC_BUSYBOX) O=$(OUTPUT_BUSYBOX) -j$(JOBS) CONFIG_PREFIX=$(OUTPUT_ROOTFS) install

ethtool:
	$(Q)mkdir -p $(OUTPUT_ETHTOOL)
	$(Q)tar --strip-components 1 -xvf $(SRC_ETHTOOL) -C $(OUTPUT_ETHTOOL)
	$(Q)pushd $(OUTPUT_ETHTOOL); ./configure --host=$(HOST) --prefix=$(OUTPUT_ROOTFS);popd
	$(Q)make -C $(OUTPUT_ETHTOOL) -j$(JOBS)
	$(Q)make -C $(OUTPUT_ETHTOOL) -j$(JOBS) install

perf:
	$(Q)mkdir -p $(OUTPUT_PERF)
	$(Q)make	ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(SRC_PERF) O=$(OUTPUT_PERF) -j$(JOBS) LD_FLAGS+=--static WERROR=0 V=1 NO_LIBELF=1

kernel:
	$(Q)mkdir -p $(OUTPUT_KERNEL)
	$(Q)make	ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(SRC_KERNEL) O=$(OUTPUT_KERNEL) -j8 defconfig
	$(Q)make	ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(SRC_KERNEL) O=$(OUTPUT_KERNEL) -j8
	$(Q)make	ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(SRC_KERNEL) O=$(OUTPUT_KERNEL) -j8 INSTALL_MOD_PATH=$(OUTPUT_ROOTFS) INSTALL_MOD_STRIP=1 modules_install
	$(Q)cp $(OUTPUT_KERNEL)/arch/$(ARCH)/boot/Image $(OUTPUT)

rootfs:
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/bin
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/boot
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/dev
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/etc
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/etc/init.d
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/home
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/komod
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/lib
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/lib/firmware
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/lost+found
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/mnt
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/nfsroot
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/opt
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/proc
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/root
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/sbin
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/share
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/sharefs
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/sys
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/tmp
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/usr
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/usr/bin
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/usr/lib
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/usr/local/bin
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/usr/sbin
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/usr/share
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/var
	$(Q)mkdir -p $(OUTPUT_ROOTFS)/var/run

	$(Q)cp -rf $(SRC_ROOTFS)/* $(OUTPUT_ROOTFS)/
	$(Q)cp -rf $(OUTPUT_PERF)/perf $(OUTPUT_ROOTFS)/usr/local/bin
	$(Q)pushd $(OUTPUT_ROOTFS); ln -s lib lib64;popd
	$(Q)pushd $(OUTPUT_ROOTFS); ln -s sbin/init init;popd

	$(Q)cp -rf $(CURDIR)/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/aarch64-linux-gnu/libc/lib $(OUTPUT_ROOTFS)
	$(Q)find $(OUTPUT_ROOTFS) -name *.a | xargs rm -rf
	$(Q)-$(CROSS_COMPILE)strip -s $(OUTPUT_ROOTFS)/lib/*
	$(Q)-$(CROSS_COMPILE)strip -s $(OUTPUT_ROOTFS)/usr/local/bin/*

pack:
	$(Q)pushd $(OUTPUT_ROOTFS); find . | cpio -o -H newc > $(OUTPUT)/initrd
	$(Q)gzip -k -f $(OUTPUT)/initrd

clean:
	$(Q)rm -rf $(OUTPUT)

.PHONY: rootfs ethtool busybox kernel pack clean
