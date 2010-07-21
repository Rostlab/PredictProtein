SUBDIRS = example helper_apps resources

man_MANS = predprot.1 predictprotein.1
dist_noinst_DATA =

dist_pkgdata_DATA = predictproteinrc.default MakefilePP.mk

dist_bin_SCRIPTS = predictprotein

CLEANFILES = $(dist_man_MANS)

predictprotein.pod:	predictprotein
	sed -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;s|__pkgver__|$(PACKAGE_VERSION)|g;' "$<" > "$@"

predictprotein.1:	predictprotein.pod
	pod2man -c 'User Commands' -r "$(VERSION)" $< $@

predprot.1:		predictprotein.1
	cp $< $@

distclean-local:
	rm -f predictprotein.pod $(man_MANS)

dist-hook:
	rm -rf `find $(distdir) -name .svn`

install-data-hook:
	sed -i -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;' "$(DESTDIR)$(pkgdatadir)/predictproteinrc.default"

install-exec-hook:
	sed -i -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g; s|__pkgver__|$(PACKAGE_VERSION)|g;' "$(DESTDIR)$(bindir)/predictprotein"
	ln -s predictprotein $(DESTDIR)$(bindir)/predprot

