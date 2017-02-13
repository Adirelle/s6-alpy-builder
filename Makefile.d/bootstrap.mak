
APK_KEYS_FILES := $(foreach ID,$(APK_KEYS_ID),alpine-devel@lists.alpinelinux.org-$(ID).rsa.pub)

CACHED_KEYS := $(addprefix $(CACHEDIR)/keys/,$(APK_KEYS_FILES))
INSTALLED_KEYS := $(addprefix $(ROOTDIR)/etc/apk/keys/,$(APK_KEYS_FILES))

KERNEL_FLAVORS := grsec virtgrsec
INITRAMFS := $(foreach FLAVOR,$(KERNEL_FLAVORS),$(ROOTDIR)/boot/initramfs-$(FLAVOR))

SUDO := sudo
CHROOT := $(SUDO) chroot $(ROOTDIR) env PATH="/sbin:/usr/sbin:/bin:/usr/bin"

recurse = $(foreach d,$(wildcard $1*),$(call recurse,$(d)/) $(d))

OVERLAY_SRCS := $(call recurse,$(OVERLAYDIR)/)
OVERLAY_TARGETS := $(patsubst $(OVERLAYDIR)/%,$(ROOTDIR)/%,$(OVERLAY_SRCS))

.PHONY: bootstrap-apk bootstrap-kernel

bootstrap: | bootstrap-apk bootstrap-kernel bootstrap-overlay

bootstrap-apk: | mount $(ROOTDIR)/sbin/apk

$(ROOTDIR)/sbin/apk: | $(ROOTDIR)/lib/apk/db/lock $(ROOTDIR)/etc/apk/cache
	$(SUDO) $(STATICAPK) --root=$(ROOTDIR) --arch=$(ARCH) add alpine-baselayout alpine-keys apk-tools execline busybox

$(ROOTDIR)/lib/apk/db/lock: | $(STATICAPK) $(ROOTDIR)/etc/resolv.conf $(INSTALLED_KEYS) $(ROOTDIR)/etc/apk/repositories
	$(SUDO) $(STATICAPK) --root=$(ROOTDIR) --arch=$(ARCH) add --initdb
	$(SUDO) $(STATICAPK) --root=$(ROOTDIR) --arch=$(ARCH) update

$(INSTALLED_KEYS): $(ROOTDIR)/etc/apk/keys/%: $(CACHEDIR)/keys/% | $(ROOTDIR)/etc/apk/keys
	$(SUDO) cp -av $< $@

$(CACHED_KEYS): $(CACHEDIR)/keys/%: | $(CACHEDIR)/keys
	wget -nv -O '$@' https://www.alpinelinux.org/keys/'$(@F)'

$(CACHEDIR)/keys: | $(CACHEDIR)
	mkdir -p $@

$(ROOTDIR)/etc/apk/repositories:
	$(SUDO) sh -c 'echo $(MIRROR)/main >$@'

$(ROOTDIR)/etc/apk/keys:
	$(SUDO) mkdir -p $@

$(ROOTDIR)/etc/apk/cache:
	$(SUDO) ln -s ../../var/cache/apk $@

bootstrap-kernel: | $(ROOTDIR)/boot/ldlinux.sys $(ROOTDIR)/boot/extlinux.conf $(INITRAMFS)

$(ROOTDIR)/boot/ldlinux.sys: | $(ROOTDIR)/sbin/extlinux
	$(CHROOT) extlinux --install /boot --device=/dev/sda1
	$(SUDO) dd if=$(ROOTDIR)/usr/share/syslinux/gptmbr.bin of=$(ROOTDIR)/dev/root

$(ROOTDIR)/boot/extlinux.conf: $(ROOTDIR)/etc/update-extlinux.conf | $(ROOTDIR)/sbin/extlinux
	$(CHROOT) update-extlinux -v

kflavor = $(patsubst $(ROOTDIR)/boot/initramfs-%,%,$1)
kver = $(notdir $(wildcard $(ROOTDIR)/lib/modules/*-$1))

$(INITRAMFS): $(ROOTDIR)/boot/initramfs-%: $(ROOTDIR)/etc/mkinitfs/mkinitfs.conf $(ROOTDIR)/etc/mkinitfs/init $(ROOTDIR)/etc/mkinitfs/features.d/* | $(ROOTDIR)/sbin/mkinitfs
	$(CHROOT) mkinitfs $(call kver,$(call kflavor,$@))

$(ROOTDIR)/sbin/mkinitfs $(ROOTDIR)/sbin/extlinux: | bootstrap-apk
	$(CHROOT) apk add --no-scripts syslinux $(foreach FLAVOR,$(KERNEL_FLAVORS), linux-$(FLAVOR))

bootstrap-overlay: | $(OVERLAY_TARGETS)

$(OVERLAY_TARGETS): $(ROOTDIR)/%: $(OVERLAYDIR)/%
	$(SUDO) cp -P --preserve=mode,links,timestamps $< $@

#$(ROOTDIR)/dev/root:
# 	$(SUDO) ln -snf sda2 $(ROOTDIR)/dev/root
#
$(ROOTDIR)/usr/bin/s6-rc $(ROOTDIR)/usr/bin/s6-rc:
#  	$(CHROOT) apk add s6 s6-rc
#
$(ROOTDIR)/usr/bin/s6-init: $(ROOTDIR)/usr/bin/s6-rc
	$(CHROOT) apk add s6-portable-utils s6-linux-utils s6-linux-init

$(ROOTDIR)/etc/s6-rc/compiled: $(ROOTDIR)/usr/bin/s6-rc $(ROOTDIR)/etc/s6-rc/source
	$(CHROOT) s6-rc-compile -v2 /etc/s6-rc/compiled.initial /etc/s6-rc/source
	ln -snf $(ROOTDIR)/etc/s6-rc/compiled.initial $(ROOTDIR)/etc/s6-rc/compiled

# if {
#     export PATH /bin:/usr/bin:/sbin:/usr/sbin
#     chroot ${ROOTDIR}
#     if {
#         apk add --no-scripts
#             syslinux linux-grsec linux-virtgrsec
#             s6 s6-rc s6-portable-utils s6-linux-utils s6-linux-init
#     }
# }
#
# if {
#     elglob FILES ${OVERLAYDIR}/*
#     cp -rP --preserve=links,mode ${FILES} ${ROOTDIR}
# }
#
# foreground {
#     export PATH /bin:/usr/bin:/sbin:/usr/sbin
#     chroot ${ROOTDIR}
#     if {
#         forbacktickx KVER { s6-ls /lib/modules }
#         import -u KVER
#         /sbin/mkinitfs $KVER
#     }
#     if {  }
#     if { update-extlinux }
#     if {  }
#     if {  }
#     apk add
#         man man-pages mdocml-apropos syslinux-doc
#         e2fsprogs e2fsprogs-doc
#         bkeymaps
# }
