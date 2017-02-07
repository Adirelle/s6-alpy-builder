
bootstrap: | $(ROOTDIR)/bin/ash

$(ROOTDIR)/bin/ash: | mount $(STATICAPK) $(CACHEDIR)/keys
	tools/bootstrap $(ROOTDIR) $(ARCH) $(MIRROR) $(OVERLAYDIR) $(CACHEDIR) $(STATICAPK)

$(CACHEDIR)/keys: | $(CACHEDIR)
	wget -N -r -nd -nH -L -np -nv -A alpine-*.rsa.pub -P $@ https://www.alpinelinux.org/keys/
