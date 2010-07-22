pkgdataexampledir = $(pkgdatadir)/example
dist_pkgdataexample_DATA = \
	$(srcdir)/cad23.in \
	$(srcdir)/p53.in \
	$(srcdir)/tquick.in \
	$(srcdir)/*.fasta

dist-hook:
	rm -rf `find $(distdir) -name .svn`
