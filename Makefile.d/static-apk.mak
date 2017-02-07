
APK_ARCHIVE := $(CACHEDIR)/apk-tools-static.apk

$(STATICAPK): $(APK_ARCHIVE) | $(STATICAPKDIR)
	tar -xvf $< --one-top-level=$(STATICAPKDIR)
	touch $@

$(APK_ARCHIVE): | $(CACHEDIR)
	wget -N -O $@ $(MIRROR)/main/$(MY_ARCH)/apk-tools-static-$(STATICAPK_VERSION).apk

$(STATICAPKDIR):
	mkdir -p $@
