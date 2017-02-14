
OVERLAY_SRCS != find $(OVERLAYDIR) \! -type d -printf "%p\n"
OVERLAY_DIRS != find $(OVERLAYDIR) -type d -printf "%p\n"
OVERLAY_TARGETS := $(patsubst $(OVERLAYDIR)/%,$(ROOTDIR)/%,$(OVERLAY_SRCS))
OVERLAY_TARGET_DIRS := $(patsubst $(OVERLAYDIR)/%,$(ROOTDIR)/%,$(OVERLAY_DIRS))


$(ROOTDIR)/usr/bin/s6-rc:
	$(CHROOT) apk add s6 s6-rc

$(ROOTDIR)/usr/bin/s6-init: $(ROOTDIR)/usr/bin/s6-rc
	$(CHROOT) apk add s6-portable-utils s6-linux-utils s6-linux-init

$(ROOTDIR)/etc/s6-rc/compiled: $(ROOTDIR)/usr/bin/s6-rc $(ROOTDIR)/etc/s6-rc/source
	$(CHROOT) s6-rc-compile -v2 /etc/s6-rc/compiled.initial /etc/s6-rc/source
	ln -snf $(ROOTDIR)/etc/s6-rc/compiled.initial $(ROOTDIR)/etc/s6-rc/compiled
