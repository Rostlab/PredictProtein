#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

#ifdef VAR_ARGS
#include <varargs.h>
#else
#include <stdarg.h>
#endif


/* stkprint - print message into a stack of output line */
void LIBCALL
#ifdef VAR_ARGS
stkprint(stk, format, va_alist)
	ValNodePtr	PNTR stk;
	char	*format;
	va_dcl
#else
stkprint(ValNodePtr PNTR stk, char * format, ...)
#endif
{
	va_list	args;
	char	buf[4096];

	if (stk == NULL)
		return;

#ifdef VAR_ARGS
	va_start(args);
#else
	va_start(args, format);
#endif
	vsprintf(buf, format, args);
	va_end(args);

	ValNodeCopyStr(stk, 0, buf);
}

void LIBCALL
stkprintnl(stp)
	ValNodePtr	PNTR stp;
{
	if (stp == NULL)
		return;
	ValNodeCopyStr(stp, 0, "");
}

int LIBCALL
print_stack(biop, title, stk)
	BlastIoPtr	biop;
	CharPtr	title;
	register ValNodePtr	stk;
{
	register FILE	*fp;
	CharPtr	cp;
	int	tokcnt = 0;
	int	i;

	if (biop == NULL || (fp = biop->fp) == NULL)
		return 0;

	putc('\n', fp);
	putc('\n', fp);
	fputs(title, fp);
	putc('\n', fp);
	for (; stk != NULL; stk = stk->next) {
		if ((cp = stk->data.ptrvalue) != NULL && (i = strlen(cp)) > 0) {
			if (tokcnt == 0) {
				putc(' ', fp);
				putc(' ', fp);
			}
			fputs(cp, fp);
			++tokcnt;
		}
		else {
			putc('\n', fp);
			tokcnt = 0;
		}
	}
	if (tokcnt > 0)
		putc('\n', fp);
	return 0;
}
