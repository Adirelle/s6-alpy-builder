
MY_ARCH != uname -m
ARCH ?= $(MY_ARCH)
MIRROR := http://dl-cdn.alpinelinux.org/alpine/latest-stable

STATICAPKDIR := apk-tools
CACHEDIR := .cache
DISKDIR := disks
ROOTDIR ?= mnt
OVERLAYDIR := rootfs

STATICAPK_VERSION := 2.6.8-r2
STATICAPK := $(STATICAPKDIR)/sbin/apk.static

DISKIMG := $(DISKDIR)/disk-$(ARCH).raw
DISKSIZE := 8

.PHONY: all clean dist-clean bootstrap mount umount chroot run sync

all: bootstrap

clean: umount
	rm -f $(DISKIMG)

dist-clean: clean
	rm -rf $(CACHEDIR)/* $(STATICAPKDIR)

bootstrap: | $(ROOTDIR)/bin/ash

$(ROOTDIR)/bin/ash: | mount $(STATICAPK) $(CACHEDIR)/keys
	tools/bootstrap $(ROOTDIR) $(ARCH) $(MIRROR) $(OVERLAYDIR) $(CACHEDIR) $(STATICAPK)

mount: | $(CACHEDIR) $(ROOTDIR) $(DISKIMG)
	tools/mount $(DISKIMG) $(ROOTDIR) $(CACHEDIR)

$(DISKIMG): | $(DISKDIR)
	tools/mkdisk $(DISKIMG) $(DISKSIZE)

$(STATICAPK): $(CACHEDIR)/apk-tools-static.apk | $(STATICAPKDIR)
	tar -xvf $< --one-top-level=$(STATICAPKDIR)
	touch $@

$(CACHEDIR)/apk-tools-static.apk: | $(CACHEDIR)
	wget -N -O $@ $(MIRROR)/main/$(MY_ARCH)/apk-tools-static-$(STATICAPK_VERSION).apk

$(CACHEDIR)/keys: | $(CACHEDIR)
	wget -N -r -nd -nH -L -np -nv -A alpine-*.rsa.pub -P $@ https://www.alpinelinux.org/keys/

umount:
	tools/umount $(DISKIMG) $(ROOTDIR)

chroot: | mount $(ROOTDIR)/bin/ash
	tools/chroot $(ROOTDIR)

run: | umount $(DISKIMG)
	tools/run $(DISKIMG)

sync: | mount $(STATICAPK)
	tools/sync_overlay $(ROOTDIR) $(OVERLAYDIR) $(STATICAPK)

$(STATICAPKDIR) $(ROOTDIR) $(DISKDIR):
	mkdir $@

$(CACHEDIR):
	mkdir $@
	chmod g+ws $@

ifneq ($(MY_ARCH), $(ARCH))
bootstrap: $(ROOTDIR)$(QEMU_USER)

$(ROOTDIR)$(QEMU_USER): | mount $(QEMU_USER)
	sudo cp $< $@

endif
