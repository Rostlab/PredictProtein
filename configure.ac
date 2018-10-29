AC_INIT([predictprotein], [1.1.08], [https://rostlab.org/bugzilla3/enter_bug.cgi?product=predictprotein])
AC_CONFIG_SRCDIR([predictprotein])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile] [perl/Build.PL] [examples/Makefile] [helper_apps/Makefile] [resources/Makefile])

# lkajan: Module::Build integration:
AC_SUBST(INSTALL_BASE_ARG)
if test "x$prefix" != "x/usr"; then
	INSTALL_BASE_ARG=install_base=$prefix
fi

AC_OUTPUT
