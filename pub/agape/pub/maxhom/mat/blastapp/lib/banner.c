#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#include "blastapp.h"

/*
	banner -- display a program banner consisting of program name
	and version on stdout.
*/
void
banner(BlastIoPtr biop, CharPtr progname, CharPtr desc, CharPtr version,
	CharPtr rel_date, Link1BlkPtr citation, Link1BlkPtr notice,
	int *susage, int *qusage)
{
	FILE	*fp;
	char	ver_str[128], *ver_strp = NULL;
	char	bld_date[128], *bdp = NULL;
	Link1BlkPtr	l1bp;
	register CharPtr	cp;

	module = cp = str_dup(basename(progname, NULL));
	for (; *cp != NULLB && isalnum(*cp); ++cp) {
		if (islower(*cp))
			*cp = toupper(*cp);
	}
	*cp = NULLB;

	if (biop == NULL)
		return;

	if (version != NULL)
#ifdef MPROC_AVAIL
		sprintf(ver_strp = ver_str, "%sMP", version);
#else
		ver_strp = version;
#endif

#if defined(__DATE__) && defined(__TIME__)
		sprintf(bdp = bld_date, "%s %s", cc_time, cc_date);
#endif

#ifdef BLASTASN
	Bio_PrefaceAsnWrite(biop, module, desc, ver_strp, rel_date, bdp, citation, notice, susage, qusage);
#endif

	fp = biop->fp;
	if (fp == NULL)
		return;

	fprintf(fp, "%s", module);

	if (ver_strp != NULL)
		fprintf(fp, " %s", ver_strp);

	if (rel_date != NULL)
		fprintf(fp, " [%s]", rel_date);

	if (bdp != NULL)
		fprintf(fp, " [Build %s]", bdp);

	putc('\n', fp);

	if (citation != NULL) {
		putc('\n', fp);
		for (l1bp = citation; l1bp != NULL && l1bp->cp != NULL; l1bp = l1bp->next) {
			if (l1bp == citation)
				wrap(fp, "Reference:  ", l1bp->cp, -1, 79, 0);
			else
				wrap(fp, NULL, l1bp->cp, -1, 79, 0);
		}
	}

	if (notice != NULL) {
		putc('\n', fp);
		for (l1bp = notice; l1bp != NULL && l1bp->cp != NULL; l1bp = l1bp->next) {
			wrap(fp, "Notice:  ", l1bp->cp, -1, 79, 0);
		}
	}
}
