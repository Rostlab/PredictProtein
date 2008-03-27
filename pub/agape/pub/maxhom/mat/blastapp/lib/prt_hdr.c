#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

#define LINELEN	79	/* no. of characters per line */

static int	print_header PROTO((FILE *, BLAST_HitListPtr, int, int, int));
static int	getmaxidlen PROTO((BLAST_HitListPtr));

/* Print all headers where the smallest pvalue in the list is below a cutoff */
int
print_headers(fp, hlp, maxpval, hasframe)
	FILE	*fp;
	register BLAST_HitListPtr	hlp;
	register double	maxpval;
	int	hasframe;
{
	register int	len;
	long	cnt, noprt;
	int	descriptlen = LINELEN-19;
	int	maxidlen;
	char	*cp;

	if (fp == NULL)
		return 0;

	if (V == 0)
		return 0;

	fprintf(fp, "\n%*s\n", LINELEN-2, "Smallest");
	if (!sump_option)
		fprintf(fp, "%*s\n", LINELEN-3, "Poisson");
	else
		fprintf(fp, "%*s\n", LINELEN-5, "Sum");
	fprintf(fp, "%*s\n", LINELEN,
		(hasframe ? "Reading  High  Probability" : "High  Probability"));
	if (hasframe) {
		cp = "Frame Score  P(N)      N";
		descriptlen -= 3;
		len = descriptlen - 3;
	}
	else {
		cp = "Score  P(N)      N";
		len = descriptlen;
	}
	fprintf(fp, "%*s %s\n\n",
			-len,
			"Sequences producing High-scoring Segment Pairs:",
			cp);

	if (hlp == NULL) {
		fprintf(fp, "\n      *** NONE ***\n\n");
		return 0;
	}

	maxidlen = getmaxidlen(hlp);

	/* For each BLAST_HitList in the linked list... */
	for (cnt = noprt = 0; hlp != NULL; hlp = hlp->next) {
		if (hlp->best_hsp->pvalue <= maxpval) {
			if (V < 0 || cnt < V) {
				++cnt;
				if (print_header(fp, hlp, hasframe, descriptlen, maxidlen) != 0)
					return -1;
			}
			else
				++noprt;
		}
	}

	noprt += hasHSP - cnt;
	if (V > 0 && noprt > 0) {
		putc('\n', fp);
		warning("Descriptions of %s database sequences were not reported due to the limiting value of parameter V = %ls.",
				Ltostr(noprt,1),
				Ltostr(V,1));
	}
	putc('\n', fp);
	return ferror(fp);
}


static int
print_header(fp, hlp, hasframe, descriptlen, maxidlen)
	FILE	*fp;
	BLAST_HitListPtr	hlp;
	int	hasframe;
	int	descriptlen;
	int	maxidlen;
{
	register int	len;
	register char	*cp, *cpmax, *ocp;
	BLAST_HSPPtr	hp;
	int		frame;
	double	p;
	register int		i;

	if ((cp = hlp->str2.name) == NULL || (len = hlp->str2.namelen) == 0)
		return 0;

	cpmax = cp + len;

	if (maxidlen > 0) {
		descriptlen -= (maxidlen+1);
		/* Find first white space */
		ocp = cp;
		while (ocp < cpmax && !isspace(*ocp))
			++ocp;
		maxidlen -= (ocp - cp);
		/* Output the identifier */
		while (cp < ocp) {
			putc(*cp, fp);
			++cp;
		}
		/* Pad with white space to align the left edge of the descriptions */
		while (maxidlen-- >= 0)
			putc(' ', fp);
		/* Skip past any white space following the identifier */
		while (cp < cpmax && isspace(*cp))
			++cp;
		len -= (cp - hlp->str2.name);
	}
	if (len > descriptlen) {
		ocp = cp + (descriptlen-3);
		if (ocp < cpmax)
			cpmax = ocp;
		while (cp < cpmax) {
			putc(*cp, fp);
			++cp;
		}
		putc('.', fp);
		putc('.', fp);
		putc('.', fp);
	}
	else {
		fwrite(cp, len, 1, fp);
		for (; len < descriptlen; ++len) {
			putc(' ', fp);
		}
	}

	hp = BlastHitListHSPHighestNormScore(hlp);

	if (hasframe) {
		frame = hp->s_seg.frame;
		if (frame == 0)
			frame = hp->q_seg.frame;
		fprintf(fp, " %+d", frame);
	}
	fprintf(fp, " %5ld", hp->score);
	p = hlp->best_hsp->pvalue;
	if (p <= 0.99) {
		if (p != 0.)
			fprintf(fp, "  %#-8.2lg", p);
		else
#if 0
			fprintf(fp, " <%#-8.2lg", fct_dbl_min());
#else
			fprintf(fp, "  %#-8.2lg", 0.);
#endif
	}
	else if (p <= 0.999)
		fprintf(fp, "  %#-8.3lg", p);
	else if (p <= 0.9999)
		fprintf(fp, "  %#-8.4lg", p);
	else if (p <= 0.99999)
		fprintf(fp, "  %#-8.5lg", p);
	else if (p <  0.9999995)
		fprintf(fp, "  %#-8.6lg", p);
	else
		fprintf(fp, "  %#-8.7lg", 1.0);
	fprintf(fp, " %2d", hlp->best_hsp->n);
	putc('\n', fp);
	return ferror(fp);
}


/* Determine the length of the longest database sequence identifier */
static int
getmaxidlen(hlp)
	register BLAST_HitListPtr	hlp;
{
	CharPtr	cp0;
	register char	*cp, *cpmax;
	register int	len, maxidlen;

	if (idlen_max <= 0)
		return 0;

	maxidlen = 0;
	for (; hlp != NULL; hlp = hlp->next) {
		if ((cp = hlp->str2.name) == NULL)
			continue;
		len = hlp->str2.namelen;
		cp0 = cp;
		cpmax = cp + len;
		while (cp < cpmax && !isspace(*cp))
			++cp;
		len = cp - cp0;
		if (len > maxidlen) {
			if ((maxidlen = len) > idlen_max)
				break;
		}
	}

	if (maxidlen > idlen_max)
		maxidlen = 0; /* too long... looks like a non-standard database */

	return maxidlen;
}
