
MY_ARCH != uname -m
ARCH ?= $(MY_ARCH)
MIRROR := http://dl-cdn.alpinelinux.org/alpine/latest-stable
APK_VERSION := 2.6.8-r2

DISKIMG := disks/disk-$(ARCH).raw
DISKSIZE := 8

ROOTDIR ?= mnt

.PHONY: all clean dist-clean bootstrap mount umount chroot run

all: bootstrap

clean: umount
	rm -f ${DISKIMG}

dist-clean: clean
	rm -rf .cache/* apk-tools

bootstrap: | $(ROOTDIR)/bin/ash

$(ROOTDIR)/bin/ash: | mount apk-tools/sbin/apk.static .cache/keys
	tools/bootstrap ${ROOTDIR} ${ARCH} ${MIRROR}

mount: | .cache $(ROOTDIR) $(DISKIMG)
	tools/mount $(DISKIMG) $(ROOTDIR)

$(DISKIMG): | disks
	tools/mkdisk $(DISKIMG) $(DISKSIZE)

apk-tools/sbin/apk.static: .cache/apk-tools-static.apk | apk-tools
	tar -xvf $< --one-top-level=apk-tools
	touch $@

.cache/apk-tools-static.apk: | .cache
	wget -O $@ $(MIRROR)/main/$(MY_ARCH)/apk-tools-static-$(APK_VERSION).apk

.cache/keys: | .cache
	wget -r -nd -nH -L -np -nv -A alpine-*.rsa.pub -P .cache/keys https://www.alpinelinux.org/keys/

umount:
	tools/umount $(DISKIMG) $(ROOTDIR)

chroot: | mount $(ROOTDIR)/bin/ash
	tools/chroot ${ROOTDIR}

run: | umount $(DISKIMG)
	tools/run $(DISKIMG)

.cache apk-tools $(ROOTDIR) disks:
	mkdir $@

ifneq ($(MY_ARCH), $(ARCH))
bootstrap: $(ROOTDIR)$(QEMU_USER)

$(ROOTDIR)$(QEMU_USER): | mount $(QEMU_USER)
	sudo cp $< $@

endif
