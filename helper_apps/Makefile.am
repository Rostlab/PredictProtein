helperappsdir = $(pkgdatadir)/helper_apps
dist_helperapps_SCRIPTS = \
	$(srcdir)/blast2html.pl \
	$(srcdir)/filter_blastp_big.pl \
	$(srcdir)/nors.pl \
	$(srcdir)/prosite_scan.pl

dist-hook:
	rm -rf `find $(distdir) -name .git`
