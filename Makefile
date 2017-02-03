
THIS_ARCH != uname -m
ARCH ?= $(THIS_ARCH)
MIRROR := http://dl-cdn.alpinelinux.org/alpine/
VERSION := 3.5.1
FLAVOR := virt

ISOFILE := alpine-$(FLAVOR)-$(VERSION)-$(ARCH).iso
CDROM := disks/$(ISOFILE)

DISKIMG := disks/disk-$(ARCH).raw
DISKSIZE := 8

ROOTDIR ?= rootfs

.PHONY: all clean dist-clean bootstrap mount umount chroot run

all: bootstrap

clean: umount
	rm -f ${DISKIMG}

dist-clean: clean
	rm -f ${CDROM}

bootstrap: | $(ROOTDIR)/bin/ash

$(ROOTDIR)/bin/ash: | $(ROOTDIR)/bin
	tools/bootstrap ${ROOTDIR}

$(ROOTDIR)/bin: | $(DISKIMG) $(CDROM)
	tools/mount $(DISKIMG) $(ROOTDIR) $(CDROM)

$(DISKIMG):
	tools/mkdisk $(DISKIMG) $(DISKSIZE)

mount: | $(ROOTDIR)/bin

umount: | $(ROOTDIR)/.gitignore

$(ROOTDIR)/.gitignore:
	tools/umount $(ROOTDIR)

$(CDROM):
	wget -O $(CDROM) $(MIRROR)/latest-stable/releases/$(ARCH)/$(ISOFILE)

chroot: mount $(ROOTDIR)/bin/ash
	tools/chroot ${ROOTDIR}

run: umount | $(DISKIMG)
	tools/run $(DISKIMG)
