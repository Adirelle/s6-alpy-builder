

KERNEL_FLAVORS := grsec virtgrsec
KIMAGES :=$(addprefix $(ROOTDIR)/boot/vmlinuz-,$(KERNEL_FLAVORS))
INITRAMFS := $(addprefix $(ROOTDIR)/boot/initramfs-,$(KERNEL_FLAVORS))

MKINITCONF_SRC != find $(OVERLAYDIR)/etc/mkinitfs -type f
MKINITCONF := $(patsubst $(OVERLAYDIR)/%,$(ROOTDIR)/%,$(MKINITCONF_SRC))

.PHONY: kernel kernel-packages

kernel: | mount kernel-packages $(ROOTDIR)/boot/extlinux.conf $(INITRAMFS)

kernel-packages: | apk
	$(CHROOT) apk add --no-scripts s6-portable-utils s6-linux-utils syslinux $(addprefix linux-,$(KERNEL_FLAVORS))

$(ROOTDIR)/boot/extlinux.conf: $(ROOTDIR)/etc/update-extlinux.conf | $(ROOTDIR)/boot/ldlinux.sys
	$(CHROOT) update-extlinux

$(ROOTDIR)/etc/update-extlinux.conf: $(OVERLAYDIR)/etc/update-extlinux.conf
	$(SUDO) $(CP) $< $@

$(ROOTDIR)/boot/ldlinux.sys: | $(ROOTDIR)/dev/root
	$(CHROOT) dd if=/usr/share/syslinux/gptmbr.bin of=/dev/sda
	$(CHROOT) extlinux --install /boot

$(ROOTDIR)/dev/root:
	$(SUDO) ln -snf sda2 ${ROOTDIR}/dev/root

$(INITRAMFS): $(ROOTDIR)/boot/initramfs-%: $(MKINITCONF)
	$(CHROOT) execlineb -c 'elglob MODDIR /lib/modules/*-$(*) backtick -n KVER { basename $$MODDIR } import -u KVER mkinitfs $$KVER'

$(MKINITCONF): $(ROOTDIR)/etc/mkinitfs/%: $(OVERLAYDIR)/etc/mkinitfs/%
	$(SUDO) $(CP) $< $@
