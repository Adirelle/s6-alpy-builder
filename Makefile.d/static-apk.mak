
$(STATICAPK): $(CACHEDIR)/apk-tools-static.apk | $(STATICAPKDIR)
	tar -xvf $< --one-top-level=$(STATICAPKDIR)
	touch $@

$(CACHEDIR)/apk-tools-static.apk: | $(CACHEDIR)
	wget -N -O $@ $(MIRROR)/main/$(MY_ARCH)/apk-tools-static-$(STATICAPK_VERSION).apk

$(STATICAPKDIR):
	mkdir -p $@
