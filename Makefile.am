EXTRA_DIST = perl/lib/RG/PP/ACL.pm
SUBDIRS = examples helper_apps resources

man_MANS = predictprotein.1

dist_noinst_DATA = perl/Build.PL.in perl/MANIFEST perl/MANIFEST.SKIP
dist_pkgdata_DATA = predictproteinrc.default MakefilePP.mk

dist_bin_SCRIPTS = predictprotein

CLEANFILES = $(dist_man_MANS)

all-local: build-stamp

clean-local:
	if [ -e perl/Build ]; then ( cd perl && perl Build clean ) && rm -f perl/Build build-stamp; fi
	rm -f $(man_MANS)

distclean-local:
	rm -rf perl/_build perl/MYMETA.{json,yml} perl/MANIFEST.SKIP.bak

build-stamp: perl/Build.PL
	( cd perl && perl Build.PL installdirs=vendor && perl Build ) && touch build-stamp

install-data-local:
	cd perl && perl Build install destdir=$(DESTDIR) $(INSTALL_BASE_ARG) create_packlist=0

%.1:	%
	sed -e 's|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;s|__VERSION__|$(VERSION)|g;s|__PACKAGE_VERSION__|$(PACKAGE_VERSION)|g;' "$<" | \
	pod2man -c 'User Commands' -r "$(VERSION)" -name $(shell tr '[:lower:]' '[:upper:]' <<< "$(basename $@)") > "$@"

dist-hook:
	rm -rf `find $(distdir) -name .git`

install-data-hook:
	sed -i -e 's|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g;s|__bindir__|$(bindir)|g;' "$(DESTDIR)$(pkgdatadir)/predictproteinrc.default"

install-exec-hook:
	sed -i -e 's|__docdir__|$(docdir)|g;s|__pkgdatadir__|$(pkgdatadir)|g;s|__sysconfdir__|$(sysconfdir)|g; s|__PACKAGE_VERSION__|$(PACKAGE_VERSION)|g;' "$(DESTDIR)$(bindir)/predictprotein"

