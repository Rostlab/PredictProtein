SUBDIRS = example helper_apps resources

man_MANS = predictprotein.1
dist_noinst_DATA = predictprotein.pod.in

dist_pkgdata_DATA = predictproteinrc.default

dist_bin_SCRIPTS = predictprotein

CLEANFILES = $(dist_man_MANS)

predictprotein.pod:	predictprotein.pod.in
	sed -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;' "$<" > "$@"

predictprotein.1:	predictprotein.pod
	pod2man -c 'User Commands' -r "$(VERSION)" $< $@

distclean-local:
	rm -f predictprotein.pod predictprotein.1

dist-hook:
	rm -rf `find $(distdir) -name .svn`

install-data-hook:
	find '$(DESTDIR)$(pkgdatadir)/predictproteinrc.default' -type f -exec sed -i -e 's|__datadir__|$(datadir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;' '{}' \;

install-exec-hook:
	sed -i -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;' "$(DESTDIR)$(bindir)/predictprotein"

