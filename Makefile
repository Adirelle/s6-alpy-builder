
THIS_ARCH != uname -m
ARCH ?= $(THIS_ARCH)
MIRROR := http://dl-cdn.alpinelinux.org/alpine/
VERSION := 3.5.1
FLAVOR := virt

ISOFILE := alpine-$(FLAVOR)-$(VERSION)-$(ARCH).iso
CDROM := disks/$(ISOFILE)

DISKIMG := disks/disk-$(ARCH).raw
DISKSIZE := 8

all: $(CDROM) $(DISKIMG)

nuke:
	rm -f $(CDROM) $(DISKIMG)

$(CDROM):
	wget -O $(CDROM) $(MIRROR)/latest-stable/releases/$(ARCH)/$(ISOFILE)

$(DISKIMG):
	tools/mkdisk $(DISKIMG) $(DISKSIZE)

