
MY_ARCH != uname -m
ARCH ?= $(MY_ARCH)
MIRROR := http://dl-cdn.alpinelinux.org/alpine/latest-stable
APK_VERSION := 2.6.8-r2

DISKIMG := disks/disk-$(ARCH).raw
DISKSIZE := 8

ROOTDIR ?= rootfs

.PHONY: all clean dist-clean bootstrap mount umount chroot run

all: bootstrap

clean: umount
	rm -rf ${DISKIMG} apk-tools/*

dist-clean: clean

bootstrap: | $(ROOTDIR)/bin/ash

$(ROOTDIR)/bin/ash: | mount apk-tools/sbin/apk.static
	tools/bootstrap ${ROOTDIR} ${ARCH} ${MIRROR}

mount: .cache | $(ROOTDIR)/.mounted
apk-tools/sbin/apk.static:
	wget -O /tmp/apk-tools-static.apk $(MIRROR)/main/$(MY_ARCH)/apk-tools-static-$(APK_VERSION).apk
	tar -xvf /tmp/apk-tools-static.apk --one-top-level=apk-tools
	rm /tmp/apk-tools-static.apk

$(ROOTDIR)/.mounted: | $(DISKIMG)
	tools/mount $(DISKIMG) $(ROOTDIR)

$(DISKIMG):
	tools/mkdisk $(DISKIMG) $(DISKSIZE)




umount: | $(ROOTDIR)/.unmounted

$(ROOTDIR)/.unmounted:
	tools/umount $(DISKIMG) $(ROOTDIR)

chroot: mount $(ROOTDIR)/bin/ash
	tools/chroot ${ROOTDIR}

run: umount | $(DISKIMG)
	tools/run $(DISKIMG)

ifneq ($(MY_ARCH), $(ARCH))
bootstrap: $(ROOTDIR)$(QEMU_USER)

$(ROOTDIR)$(QEMU_USER): | mount $(QEMU_USER)
	sudo cp $< $@

endif
