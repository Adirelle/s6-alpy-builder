
ifneq ($(MY_ARCH), $(ARCH))
bootstrap: $(ROOTDIR)$(QEMU_USER)

$(ROOTDIR)$(QEMU_USER): | mount $(QEMU_USER)
	sudo cp $< $@

endif
