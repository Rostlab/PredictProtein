#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"
#ifdef VAR_ARGS
#include <varargs.h>
#else
#include <stdarg.h>
#endif

extern Link1Blk	citation[];

static int	pr_usage PROTO((FILE *fp));

void LIBCALL
#ifdef VAR_ARGS
busage(err, fmt, va_alist)
	enum blast_error	err;
	char	*fmt;
	va_dcl
#else
busage(enum blast_error err, char *fmt, ...)
#endif
{
	FILE	*fp;
	va_list	args;
	char	buf[4096];

	banner(&b_out, prog_name, prog_desc, prog_version, prog_rel_date,
		citation, NULL, susage, qusage);

	pr_usage(fp = b_out.fp);

	if (fmt == NULL)
		exit_code(ERR_INVAL, "improper program usage");
	else {
#ifdef VAR_ARGS
		va_start(args);
#else
		va_start(args, fmt);
#endif
		vsprintf(buf, fmt, args);
		va_end(args);

		fatal_msg(fp, buf);

		ckwarnings();

		exit_code(ERR_INVAL, buf);
	}
	/*NOTREACHED*/
}


static int
pr_usage(fp)
	FILE	*fp;
{
	if (fp == NULL)
		return 0;

	fflush(stdout);
	fflush(fp);
	fprintf(fp, "\nUsage:\n\n");
	fprintf(fp,
		"    %s database queryfile [options]\n\n", prog_name);
	fprintf(fp, "Valid %s options:  E, S, E2, S2, W, T, X, M", prog_name);
	if (prog_id == PROG_ID_BLASTN)
		fprintf(fp, ", N");
	if (prog_id == PROG_ID_BLASTX || prog_id == PROG_ID_TBLASTN || prog_id == PROG_ID_TBLASTX) {
		fprintf(fp, ", C");
	}
	fprintf(fp, ", Y, Z, H, V and B\n");
	fprintf(fp, "\t-sump  (Karlin-Altschul \"Sum\" statistics, the default)\n");
	fprintf(fp, "\t-poissonp  (Poisson statistics)\n");
	fprintf(fp, "\t-compat1.3  (revert to BLAST version 1.3 behavior, approximately)\n");
	if (qusage[0] == BLAST_ALPHATYPE_NUCLEIC_ACID) {
		fprintf(fp, "\t-top     (search only the top strand of the query)\n");
		fprintf(fp, "\t-bottom  (search only the bottom strand of the query)\n");
	}
	if (susage[0] == BLAST_ALPHATYPE_NUCLEIC_ACID && susage[1] == BLAST_ALPHATYPE_AMINO_ACID) {
		fprintf(fp, "\t-dbtop     (search only the top strand of the database)\n");
		fprintf(fp, "\t-dbbottom  (search only the bottom strand of the database)\n");
		fprintf(fp, "\t-dbgcode #  (specify a genetic code for the database)\n");
	}
	fprintf(fp, "\t-filter filtermethod  (e.g., \"seg\", \"xnu\", or \"seg+xnu\")\n");
	fprintf(fp, "\t-echofilter  (display the filtered query sequence)\n");
	fprintf(fp, "\t-ctxfactor #  (base statistics on this no. of independent contexts\n");
	fprintf(fp, "\t-gapdecayrate #\n");
	fprintf(fp, "\t-olfraction #\n");
	fprintf(fp, "\t-span2  (the default)\n");
	fprintf(fp, "\t-span1\n");
	fprintf(fp, "\t-span\n");
	fprintf(fp, "\t-prune\n");
	fprintf(fp, "\t-consistency  (turn off HSP consistency statistics)\n");
	fprintf(fp, "\t-matrix matrixfile  (specify a scoring matrix file)\n");
	fprintf(fp, "\t-altscore \"qc sc score\"\n\t\t(qc or sc may be \"any\", score may be \"min\", \"max\", or \"na\")\n");
	fprintf(fp, "\t-hspmax #  (max. no. of HSPs per db seq, default %d)\n",
			hsp_max);
	fprintf(fp, "\t-qoffset #  (adjust query coordinate numbering by this amount)\n");
	if (prog_id == PROG_ID_BLASTP || prog_id == PROG_ID_BLASTX) {
		fprintf(fp, "\t-nwstart #  (start generating neighborhood words here)\n");
		fprintf(fp, "\t-nwlen #  (generate neighborhood words for this length)\n");
	}
	fprintf(fp, "\t-dbrecmin #  (starting database record number)\n");
	fprintf(fp, "\t-dbrecmax #  (ending database record number)\n");
	fprintf(fp, "\t-gi     (display gi identifiers, when available)\n");
	fprintf(fp, "\t-qtype  (exit non-zero if query seems to be of wrong type)\n");
	fprintf(fp, "\t-qres   (exit non-zero if query contains an invalid residue code)\n");
#if 0
	if (prog_id == PROG_ID_BLASTX)
		fprintf(fp, "\t-codoninfo cdifile\n");
#endif
	fprintf(fp, "\t-sort_by_pvalue\n");
	fprintf(fp, "\t-sort_by_count\n");
	fprintf(fp, "\t-sort_by_highscore\n");
	fprintf(fp, "\t-sort_by_totalscore\n");
	fprintf(fp, "\t-warnings  (suppress warning messages)\n");
	fprintf(fp, "\t-asn1  (produce ASN.1 \"print-value\" output)\n");
	fprintf(fp, "\t-asn1bin  (produce binary-encoded ASN.1 output)\n");
	return 0;
}
