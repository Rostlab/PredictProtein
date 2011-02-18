helperappsdir = $(pkgdatadir)/helper_apps
dist_helperapps_SCRIPTS = \
	$(srcdir)/blast2html.pl \
	$(srcdir)/filter_blastp_big.pl \
	$(srcdir)/nors.pl \
	$(srcdir)/prosite_scan.pl

man_MANS = prosite_scan.5

dist_noinst_DATA = prosite_scan.pod

prosite_scan.5:	prosite_scan.pod
	sed -e 's|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;s|__VERSION__|$(VERSION)|g;s|__PACKAGE_VERSION__|$(PACKAGE_VERSION)|g;' "$<" | \
	pod2man -c '' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") --section 5 > "$@"

clean-local:
	rm -f $(man_MANS)

dist-hook:
	rm -rf `find $(distdir) -name .svn`
