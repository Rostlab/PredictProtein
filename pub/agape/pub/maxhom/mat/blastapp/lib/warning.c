#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

#ifdef VAR_ARGS
#include <varargs.h>
#else
#include <stdarg.h>
#endif

static int	warning_cnt;

/* warning - print warning message and return */
void
#ifdef VAR_ARGS
warning(format, va_alist)
	char	*format;
	va_dcl
#else
warning(char *format, ...)
#endif
{
	va_list	args;
	FILE	*fp;
	char	buf[4096];

	++warning_cnt;

	if (warning_option)
		return;

#ifdef VAR_ARGS
	va_start(args);
#else
	va_start(args, format);
#endif
	(void) vsprintf(buf, format, args);
	va_end(args);

	fp = b_out.fp;
	if (fp != NULL) {
		putc('\n', fp);
		wrap(fp, "WARNING:  ", buf, -1, 78, 10);
		fflush(fp);
		if (!SameFp(stderr, fp) && (sys_fpisfile(fp) || sys_fpisfile(stderr))) {
			putc('\n', stderr);
			wrap(stderr, "WARNING:  ", buf, -1, 78, 10);
			fflush(stderr);
		}
	}

#ifdef BLASTASN
	Bio_WarningAsnWrite(&b_out, 0, buf);
#endif

	return;
}


void
ckwarnings()
{
	if (warning_cnt > 0 && b_out.fp != NULL)
		fprintf(b_out.fp, "\nWARNINGS %s:  %d\n",
			(warning_option ? "SUPPRESSED" : "ISSUED"),
			warning_cnt);
}
