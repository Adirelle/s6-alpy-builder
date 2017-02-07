
$(DISKIMG): | $(DISKDIR)
	tools/mkdisk $(DISKIMG) $(DISKSIZE)

$(DISKDIR):
	mkdir -p $@
