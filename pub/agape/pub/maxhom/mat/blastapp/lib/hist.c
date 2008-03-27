#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

#define PAGE_WIDTH	80

#define MULTI_CHR	'='
#define SINGLE_CHR	':'
#define VAXIS_CHR	'|'

ScoreHistPtr LIBCALL
ScoreHistNew(minval, maxval, ncols)
	double	minval, maxval;
	unsigned	ncols; /* no. of columns in the histogram */
{
	ScoreHistPtr	shp;
	double	incr, y, z;

	if (minval >= maxval || minval <= 0. || ncols < 2 || ncols > 10000)
		return NULL;

	shp = (ScoreHistPtr)MemGet(sizeof(*shp), MGET_CLEAR|MGET_ERRPOST);
	if (shp == NULL)
		return shp;

	shp->minval = minval;
	shp->maxval = maxval;
	shp->dim = ncols + 1;
	shp->incr = incr = log(maxval / minval) / (double)ncols;
	shp->base = log(minval);

	shp->hist = (unsigned long *)MemGet(sizeof(*shp->hist) * shp->dim, MGET_CLEAR|MGET_ERRPOST);
	if (shp->hist == NULL)
		goto Error;

	return shp;

Error:
	if (shp->hist != NULL)
		MemFree(shp->hist);
	if (shp != NULL)
		MemFree(shp);
	return NULL;
}

ScoreHistPtr LIBCALL
ScoreHistDup(shp)
	ScoreHistPtr	shp;
{
	if (shp == NULL)
		return NULL;
	return ScoreHistNew(shp->minval, shp->maxval, shp->dim - 1);
}

void LIBCALL
ScoreHistAddPoint(shp, value)
	ScoreHistPtr	shp;
	register double	value;
{
	register int	i;

	if (shp == NULL)
		return;

	if (value < shp->minval) {
		++shp->below;
		return;
	}
	if (value > shp->maxval) {
		++shp->above;
		return;
	}

	i = (log(value) - shp->base) / shp->incr;
	++shp->hist[i];
}

void LIBCALL
ScoreHistAdd(shp0, shp)
	ScoreHistPtr	shp0, shp;
{
	register int	i;

	if (shp0 == NULL || shp == NULL || shp0 == shp || shp0->dim != shp->dim
			|| shp0->base != shp->base || shp0->incr != shp->incr)
		return;

	mproc_lock();
	shp0->below += shp->below;
	shp0->above += shp->above;
	for (i = 0; i < shp->dim; ++i)
		shp0->hist[i] += shp->hist[i];
	mproc_unlock();
}

static CharPtr
double_format(x, width, precision)
	double	x;
	int	width, precision;
{
	static char	buf[50];
	double	y;
	int	i;

	y = log(x * 1.000000001) / NCBIMATH_LN10;
	i = y;
	y = Nlm_Powi(10., i - precision + 1);
	x = Nlm_Nint(x / y) * y;
	y = Nlm_Powi(10., precision-1) - 1.e-7;
	if (x >= y)
		sprintf(buf, "%*.0lf", width, x);
	else
		sprintf(buf, "%*.*lf", width, precision - i - 1, x);
	return buf;
}

int LIBCALL
ScoreHistPrint(shp, fp, actual_expect, actual_observed)
	ScoreHistPtr	shp;
	FILE	*fp;
	double	actual_expect;
	unsigned long	actual_observed;
{
	double	x;
	unsigned long	observed, cnt, maxcnt;
	int	owidth, cwidth, hist_stop, hist_start;
	int	plotcols, npercol, ncols;
	int	once = 0;
	int	i, j;

	if (shp == NULL || fp == NULL)
		return 1;

	observed = shp->below;
	hist_stop = -1;
	for (i = 0, maxcnt = 0; i < shp->dim; ++i) {
		cnt = shp->hist[i];
		maxcnt = MAX(maxcnt, cnt);
		observed += cnt;
		if (cnt != 0 && hist_stop < 0)
			hist_stop = i;
		if (cnt != 0)
			hist_start = i;
	}

	cwidth = Nlm_Ulwidth(maxcnt, 0);
	cwidth = MAX(cwidth, 2);
	owidth = Nlm_Ulwidth(observed, 0);
	owidth = MAX(owidth, 3);

	plotcols = PAGE_WIDTH - (owidth + cwidth + 11);
	npercol = ceil((double)maxcnt / (double)plotcols);
	npercol = MAX(npercol, 1);

	putc('\n', fp);
	putc('\n', fp);
	fprintf(fp, "     Observed Numbers of Database Sequences Satisfying\n");
	fprintf(fp, "    Various EXPECTation Thresholds (E parameter values)\n");
	putc('\n', fp);
	fprintf(fp, "        Histogram units:      = %d Sequence%s",
				npercol, PLURAL(npercol));
	if (npercol > 1)
		fprintf(fp, "     : less than %d sequences\n", npercol);
	else
		putc('\n', fp);
	putc('\n', fp);
	fprintf(fp, " EXPECTation Threshold\n");
	fprintf(fp, " (E parameter)\n");
	fprintf(fp, "    |\n");
	fprintf(fp, "    V   Observed Counts-->\n");
	if (hist_stop < 0) {
		fprintf(fp, "\n\n***  histogram slots are all empty ***\n\n");
		return 0;
	}

	for (i = hist_start; i >= hist_stop; --i) {
		x = exp(shp->base + (i+1) * shp->incr);
		if (!once && x <= actual_expect + 1e-6) {
			once = 1;
			fprintf(fp,
				" >>>>>>>>>>>>>>>>>>>>>  Expect = %#0.3lg, Observed = %lu  <<<<<<<<<<<<<<<<<\n",
				actual_expect, actual_observed);
		}
		cnt = shp->hist[i];
#if 0
		fprintf(fp, " %#8.3lg %*lu %*lu %c",
					x, owidth, observed, cwidth, cnt, VAXIS_CHR);
#else
		fprintf(fp, " %s %*lu %*lu %c",
			double_format(x, 6, 3), owidth, observed, cwidth, cnt, VAXIS_CHR);
#endif
		observed -= cnt;
		ncols = shp->hist[i] / npercol;
		for (j = 0; j < ncols; ++j)
			putc(MULTI_CHR, fp);
		if (j == 0 && shp->hist[i] > 0)
			putc(SINGLE_CHR, fp);
		putc('\n', fp);
	}
	putc('\n', fp);
	return 0;
}
