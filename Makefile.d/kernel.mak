

KERNEL_FLAVORS := grsec virtgrsec
KIMAGES :=$(addprefix $(ROOTDIR)/boot/vmlinuz-,$(KERNEL_FLAVORS))
INITRAMFS := $(addprefix $(ROOTDIR)/boot/initramfs-,$(KERNEL_FLAVORS))

MKINITCONF_SRC != find $(OVERLAYDIR)/etc/mkinitfs -type f
MKINITCONF := $(patsubst $(OVERLAYDIR)/%,$(ROOTDIR)/%,$(MKINITCONF_SRC))

.PHONY: kernel

kernel: | mount apk $(ROOTDIR)/boot/extlinux.conf $(INITRAMFS)

$(ROOTDIR)/boot/extlinux.conf: $(OVERLAYDIR)/etc/update-extlinux.conf | $(ROOTDIR)/boot/ldlinux.sys
	$(CHROOT) update-extlinux

$(ROOTDIR)/boot/ldlinux.sys: $(ROOTDIR)/sbin/extlinux | $(ROOTDIR)/dev/root
	$(CHROOT) dd if=/usr/share/syslinux/gptmbr.bin of=/dev/sda
	$(CHROOT) extlinux --install /boot

$(ROOTDIR)/sbin/extlinux: | apk
	$(CHROOT) apk add --no-scripts syslinux

$(ROOTDIR)/dev/root:
	$(SUDO) ln -snf sda2 ${ROOTDIR}/dev/root

$(INITRAMFS): $(ROOTDIR)/boot/initramfs-%: $(ROOTDIR)/boot/vmlinuz-% $(MKINITCONF) | $(ROOTDIR)/sbin/mkinitfs
	$(CHROOT) mkinitfs $$(basename "$(ROOTDIR)/lib/modules/*-$(*)")

$(KIMAGES): $(ROOTDIR)/boot/vmlinuz-%: | apk
	$(CHROOT) apk add --no-scripts linux-$(*)

$(MKINITCONF): $(ROOTDIR)/etc/mkinitfs/%: $(OVERLAYDIR)/etc/mkinitfs/%
	$(SUDO) $(CP) $< $@
