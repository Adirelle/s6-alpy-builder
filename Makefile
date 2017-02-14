
MY_ARCH != uname -m
ARCH ?= $(MY_ARCH)
MIRROR := http://dl-cdn.alpinelinux.org/alpine/latest-stable

STATICAPKDIR := apk-tools
CACHEDIR := .cache
DISKDIR := disks
ROOTDIR ?= mnt
OVERLAYDIR := rootfs

STATICAPK_VERSION := 2.6.8-r2
APK_KEYS_ID := 4a6a0840 4d07755e 5243ef4b 524d27bb 5261cecb 58199dcc

DISKIMG := $(DISKDIR)/disk-$(ARCH).raw
DISKSIZE := 8

SUDO := sudo
CHROOT := $(SUDO) chroot $(ROOTDIR) env PATH="/sbin:/usr/sbin:/bin:/usr/bin"
CP := cp  -dr --preserve=mode,timestamps,links

.PHONY: all clean dist-clean bootstrap mount umount chroot run sync

all: bootstrap

clean: umount
	rm -f $(DISKIMG)

dist-clean: clean
	rm -rf $(STATICAPKDIR)
	sudo rm -rf $(CACHEDIR)/*

mount: | $(CACHEDIR) $(ROOTDIR) $(DISKIMG)
	tools/mount $(DISKIMG) $(ROOTDIR) $(CACHEDIR)

umount:
	tools/umount $(DISKIMG) $(ROOTDIR)

bootstrap: | mount apk kernel

chroot: | mount $(ROOTDIR)/bin/ash
	tools/chroot $(ROOTDIR)

run: | bootstrap umount $(DISKIMG)
	tools/run $(DISKIMG)

sync: | mount $(STATICAPK)
	tools/sync_overlay $(ROOTDIR) $(OVERLAYDIR) $(STATICAPK)

$(ROOTDIR):
	mkdir $@

$(CACHEDIR):
	mkdir $@
	chmod g+ws $@

include Makefile.d/*.mak
