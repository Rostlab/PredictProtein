#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

#ifdef VAR_ARGS
#include <varargs.h>
#else
#include <stdarg.h>
#endif

enum blast_error	blastapp_errno;


/* bfatal - print message and die */
void
#ifdef VAR_ARGS
bfatal(err, format, va_alist)
	enum blast_error	err;
	char	*format;
	va_dcl
#else
bfatal(enum blast_error err, char *format, ...)
#endif
{
	FILE	*fp;
	va_list	args;
	char	buf[4096];
	static	unsigned	counter;

	if (counter++ != 0)
		_exit(1);

	blastapp_errno = err;
	fp = b_out.fp;
	if (fp != NULL)
		fflush(fp);
#ifdef VAR_ARGS
	va_start(args);
#else
	va_start(args, format);
#endif
	vsprintf(buf, format, args);
	va_end(args);

	fatal_msg(fp, buf);

	ckwarnings();

	exit_code(blastapp_errno, buf);
}

int LIBCALL
fatal_msg(fp, msg)
	FILE	*fp;
	CharPtr	msg;
{
	if (fp != NULL) {
		putc('\n', fp);
		wrap(fp, "FATAL:  ", msg, -1, 78, 8);
		fflush(fp);
		if (!SameFp(stderr, fp)) {
			wrap(stderr, "FATAL:  ", msg, -1, 78, 8);
			fflush(stderr);
		}
	}
	return 0;
}

void
exit_code(errnum, reason)
	enum blast_error	errnum;
	CharPtr	reason;
{
	FILE	*fp;

	if (errnum != ERR_NONE)
		blastapp_errno = errnum;

#ifdef MPROC_AVAIL
	if (nprocs > 0) {
#ifdef SGI_MPROC_AVAIL
		if (m_get_myid() == 0)
			signal(SIGTERM, SIG_IGN);
		else
			_exit(errnum);
#endif
	}
#endif
	if (errnum != ERR_NONE) {
		fp = b_out.fp;
		if (fp != NULL) {
			fprintf(fp, "\nEXIT CODE %d\n", errnum);
			fflush(fp);
			if (!SameFp(stderr, fp)) {
				fprintf(stderr, "EXIT CODE %d\n", errnum);
			}
		}
	}
#ifdef BLASTASN
	Bio_StatusAsnWrite(&b_out, errnum, reason);
	Bio_Close(&b_out);
#endif
	exit(errnum);
	/*NOTREACHED*/
}
