
STATICAPK := $(STATICAPKDIR)/sbin/apk.static
APK_ARCHIVE := $(CACHEDIR)/apk-tools-static.apk
APK_KEYS := $(foreach ID,$(APK_KEYS_ID),alpine-devel@lists.alpinelinux.org-$(ID).rsa.pub)
CACHED_APK_KEYS := $(addprefix $(CACHEDIR)/keys/,$(APK_KEYS))
INSTALLED_APK_KEYS := $(addprefix $(ROOTDIR)/etc/apk/keys/,$(APK_KEYS))

APK := $(SUDO) $(STATICAPK) --root=$(ROOTDIR) --arch=$(ARCH)

.PHONY: apk

apk: | mount $(ROOTDIR)/sbin/apk

apk-keys:
	echo $(INSTALLED_APK_KEYS)
	echo $(CACHED_APK_KEYS)

$(ROOTDIR)/sbin/apk: | $(STATICAPK) $(ROOTDIR)/etc/resolv.conf $(ROOTDIR)/etc/apk/repositories $(INSTALLED_APK_KEYS) $(ROOTDIR)/lib/apk/db $(ROOTDIR)/etc/apk/cache
	$(APK) update
	$(APK) add alpine-baselayout alpine-keys apk-tools execline busybox

$(ROOTDIR)/lib/apk/db: $(STATICAPK)
	$(APK) add --initdb

$(STATICAPK): $(APK_ARCHIVE) | $(STATICAPKDIR)
	tar -xvf $< --one-top-level=$(STATICAPKDIR)
	touch $@

$(APK_ARCHIVE): | $(CACHEDIR)
	wget -N -O $@ $(MIRROR)/main/$(MY_ARCH)/apk-tools-static-$(STATICAPK_VERSION).apk

$(STATICAPKDIR):
	mkdir -p $@

$(ROOTDIR)/etc/resolv.conf: $(OVERLAYDIR)/etc/resolv.conf | $(ROOTDIR)/etc
	$(SUDO) $(CP) $< $@

$(ROOTDIR)/etc/apk/repositories: | $(ROOTDIR)/etc/apk
	$(SUDO) sh -c 'echo $(MIRROR)/main >$@'

$(ROOTDIR)/etc/apk/cache:
	$(SUDO) ln -snf ../../var/cache/apk $@

$(INSTALLED_APK_KEYS): $(ROOTDIR)/etc/apk/%: $(CACHEDIR)/% | $(ROOTDIR)/etc/apk/keys
	$(SUDO) $(CP) $< $@

$(CACHED_APK_KEYS): | $(CACHEDIR)/keys
	wget -nv -O '$@' https://www.alpinelinux.org/keys/'$(@F)'

$(CACHEDIR)/keys: | $(CACHEDIR)
	mkdir -p $@

$(ROOTDIR)/etc $(ROOTDIR)/etc/apk $(ROOTDIR)/etc/apk/keys:
	$(SUDO) mkdir -p $@
