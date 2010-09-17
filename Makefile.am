SUBDIRS = example helper_apps resources

man_MANS = predprot.1 predictprotein.1

dist_noinst_DATA = debian/changelog  debian/compat  debian/control  debian/copyright
dist_noinst_SCRIPTS = debian/rules

dist_pkgdata_DATA = predictproteinrc.default MakefilePP.mk

dist_bin_SCRIPTS = predictprotein

CLEANFILES = $(dist_man_MANS)

.INTERMEDIATE: predictprotein.1.in
predictprotein.1.in:	predictprotein
	sed -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;s|__PACKAGE_VERSION__|$(PACKAGE_VERSION)|g' "$<" > "$@"

predictprotein.1:	predictprotein.1.in
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") $< $@

predprot.1:		predictprotein.1
	cp $< $@

distclean-local:
	rm -f predictprotein.pod $(man_MANS)

dist-hook:
	rm -rf `find $(distdir) -name .svn`

install-data-hook:
	sed -i -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;' "$(DESTDIR)$(pkgdatadir)/predictproteinrc.default"

install-exec-hook:
	sed -i -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g; s|__PACKAGE_VERSION__|$(PACKAGE_VERSION)|g;' "$(DESTDIR)$(bindir)/predictprotein"
	rm -f $(DESTDIR)$(bindir)/predprot && ln -s predictprotein $(DESTDIR)$(bindir)/predprot

