
THIS_ARCH != uname -m
ARCH ?= $(THIS_ARCH)
MIRROR := http://dl-cdn.alpinelinux.org/alpine/
VERSION := 3.5.1
FLAVOR := virt

ISOFILE := alpine-$(FLAVOR)-$(VERSION)-$(ARCH).iso
CDROM := disks/$(ISOFILE)

DISKIMG := disks/disk-$(ARCH).raw
DISKSIZE := 8

ROOTDIR ?= mnt

.PHONY: all nuke mount umount bootstrap

all: $(CDROM) $(DISKIMG)

$(CDROM):
	wget -O $(CDROM) $(MIRROR)/latest-stable/releases/$(ARCH)/$(ISOFILE)

$(DISKIMG):
	tools/mkdisk $(DISKIMG) $(DISKSIZE)

nuke:
	rm -f $(CDROM) $(DISKIMG)

mount: $(DISKIMG) | $(ROOTDIR)/bin

$(ROOTDIR)/bin:
	tools/mount $(DISKIMG) $(ROOTDIR)

umount: $(ROOTDIR)/.gitignore

$(ROOTDIR)/.gitignore:
	tools/umount $(ROOTDIR)


