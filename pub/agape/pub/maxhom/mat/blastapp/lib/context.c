#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

double LIBCALL
context_count(ctx, nctx)
	ContxtPtr	ctx;
	int	nctx;
{
	ContxtPtr	ctxp;
	BLAST_KarlinBlkPtr	kbp;
	double	x, y, sum;
	int	i;

	if (nctx <= 0)
		return 0.;

	sum = x = 0.;
	for (i = 0; i < nctx; ++i) {
		ctxp = &ctx[i];
		if (!ctxp->valid)
			continue;
		kbp = ctxp->kbp;
		y = kbp->K * ctxp->seq->efflen;
		x = MAX(x, y);
		sum += y;
	}
	if (sum == 0.)
		return 0.;

	return sum / x;
}


int LIBCALL
set_context(ctxp, w, sensitivity, Xbits, avglen, neff)
	ContxtPtr	ctxp;
	int		w;
	int		sensitivity; /*...determines T, neighborhood wordscore threshold */
	double	Xbits;
	double	avglen; /* "average" length of one sequence */
	double	neff; /* length of the entire database */
{
	BLAST_KarlinBlkPtr	kbp;
	BLAST_Score	s, s2, t, x, maxscore;
	double	meff, e, e2;

	if (ctxp == NULL)
		return 1;

	ctxp->valid = FALSE;
	ctxp->E = -1.;
	ctxp->S = -1;
	ctxp->W = -1;
	ctxp->T = -1;
	ctxp->X = -1;
	ctxp->S2 = -1;
	ctxp->E2 = -1.;
	ctxp->maxscore = -1;
	ctxp->highs_exp = -1;

	if (ctxp->seq == NULL ||
			ctxp->kbp == NULL ||
			ctxp->sbp == NULL) {
		return 1;
	}

	kbp = ctxp->kbp;
	if (T_set)
		t = T;
	else
		t = BlastNWSThreshold(kbp, w, sensitivity);
	if (t < 0)
		t = BLAST_SCORE_MAX;

	if (X_set)
		x = X;
	else
		x = ceil(Xbits * NCBIMATH_LN2 / kbp->Lambda);

	s = S;
	e = E;
	s2 = S2;
	e2 = E2;
	if (S_set && !E_set)
		e = 0.;

	meff = ctxp->seq->efflen;
	BlastCutoffs(&s, &e, kbp, meff, neff, TRUE);

	/* Determine the secondary cutoff score, S2, to use */
	if (e2 == 0. && !S2_set)
		s2 = s;
	if ((E2_set && !S2_set && e2 == 0.) || (S2_set && s2 > s))
		e2 = 0., s2 = s;
	else {
		if (S2_set && !E2_set)
			e2 = 0.;
		BlastCutoffs(&s2, &e2, kbp, MIN(avglen,meff), avglen, TRUE);
		/* Adjust s2 to be in line with s, as necessary */
		s2 = MAX(s2, 1);
		if (s2 > s)
			s2 = s;
		e2 = BlastKarlinStoE(s2, kbp, MIN(avglen,meff), avglen);
	}

	x = MIN(x, s);

	maxscore = fmaxscore(ctxp->seq, 0, ctxp->seq->len, ctxp->sbp);

	ctxp->E = e;
	ctxp->S = s;
	ctxp->W = w;
	ctxp->T = t;
	ctxp->X = x;
	ctxp->S2 = s2;
	ctxp->E2 = e2;
	ctxp->maxscore = maxscore;
	ctxp->highs_exp = BlastExpHighScore(kbp, meff, neff);

	ctxp->valid = TRUE;
	return 0;
}

int LIBCALL
context_expect_set(ctx0, nctx)
	ContxtPtr	ctx0;
	int	nctx;
{
	ContxtPtr	ctxp;
	double	emin = 1.e20;
	int	i;

	if (ctx0 == NULL || nctx <= 0)
		return 0;
	if (S_set) {
		for (i = 0; i < nctx; ++i) {
			ctxp = &ctx[i];
			if (!ctxp->valid)
				continue;
			emin = MIN(emin, ctxp->E);
		}
		emin *= ctxfactor;

		if (E_set)
			E = MIN(emin, E);
		else
			E = emin;
	}

	parm_ensure_double("E", 1, NULL, E);

	return 0;
}

int LIBCALL
adjust_kablks(ctx0, nctx, stdctx)
	ContxtPtr	ctx0, stdctx;
	int	nctx;
{
	BLAST_KarlinBlkPtr	stdkbp, kbp;
	int	i;

	stdkbp = stdctx->kbp;
	if (stdkbp == NULL)
		return 1;
	for (i = 0; i < nctx; ++i) {
		kbp = ctx0[i].kbp;
		if (kbp == NULL)
			continue;
		if (kbp->Lambda > stdkbp->Lambda) {
			kbp->Lambda = stdkbp->Lambda;
			kbp->K = stdkbp->K;
			kbp->logK = stdkbp->logK;
			kbp->H = stdkbp->H;
		}
	}
	return 0;
}

int LIBCALL
stk_context_parms(stp, ctxp0, nctx, stdctxp)
	ValNodePtr	PNTR stp;
	ContxtPtr	ctxp0;
	int	nctx;
	ContxtPtr	stdctxp; /* standard context */
{
	ContxtPtr	ctxp;
	BLAST_ScoreBlkPtr	sbp, sbp2;
	BLAST_KarlinBlkPtr	kbp;
	BLAST_KarlinBlk	kb;
	CharPtr	ctxtype = "Frame ";
	int	i, j;
	int	mw=12, sw=1, ww=1, tw=3, xw=1, s2w=1;

	if (stp == NULL || ctxp0 == NULL || nctx <= 0)
		return 1;

	stkprintnl(stp);

	/* Display the matrice(s) used */
	for (i = 0; i < nctx; ++i) {
		ctxp = &ctxp0[i];
		if (ctxp->seq != NULL && ctxp->seq->ap->alphatype == BLAST_ALPHATYPE_NUCLEIC_ACID)
			ctxtype = "Strand";
		sbp = ctxp->sbp;
		if (sbp == NULL)
			continue;
		mw = MAX(mw, (int)strlen(basename(sbp->name, NULL)));
	}

	kb.Lambda = kb.K = kb.H = kb.Lambda_real = kb.K_real = kb.H_real = -1.;

	stkprint(stp, "Query                    %*s-----  As Used  -----    -----  Computed  ----", mw-8, "");
	stkprintnl(stp);
	stkprint(stp,     "%s MatID Matrix name %*sLambda    K       H      Lambda    K       H",
			ctxtype, mw-8, "");
	stkprintnl(stp);
	if (stdctxp != NULL) {
		kbp = stdctxp->kbp;
		if (kbp == NULL)
			kbp = &kb;
		sbp = stdctxp->sbp;
		stkprint(stp, " Std.   %2d   %*s %*s%#8.3lg %#7.3lg %#7.3lg",
				sbp->id.data.intvalue,
				-mw, basename(sbp->name, NULL),
				25, "",
				kbp->Lambda, kbp->K, kbp->H
				);
		stkprintnl(stp);
	}
	for (i = 0; i < nctx; ++i) {
		ctxp = &ctxp0[i];
		kbp = ctxp->kbp;
		if (kbp == NULL || !ctxp->valid)
			kbp = &kb;
		sbp = ctxp->sbp;
		stkprint(stp, " %+d    %3d   %*s ",
				ctxp->stdframe,
				sbp->id.data.intvalue,
				-mw, basename(sbp->name, NULL) );
#if 0
		stkprint(stp, " %+d    %3d   %*s %#8.3lg %#7.3lg %#7.3lg",
				ctxp->stdframe,
				sbp->id.data.intvalue,
				-mw, basename(sbp->name, NULL),
#endif
		if (kbp->Lambda > 0.)
			stkprint(stp, "%#8.3lg ", kbp->Lambda);
		else
			stkprint(stp, "     NA  ");
		if (kbp->K > 0.)
			stkprint(stp, "%#7.3lg ", kbp->K);
		else
			stkprint(stp, "    NA  ");
		if (kbp->H > 0.)
			stkprint(stp, "%#7.3lg", kbp->H);
		else
			stkprint(stp, "    NA  ");

		if (kbp->Lambda == kbp->Lambda_real && kbp->Lambda > 0.)
			stkprint(stp, "    same ");
		else
			if (kbp->Lambda_real < 0.)
				stkprint(stp, "     NA ");
			else
				stkprint(stp, " %#8.3lg", kbp->Lambda_real);

		if (kbp->K == kbp->K_real && kbp->K > 0.)
			stkprint(stp, "   same  ");
		else
			if (kbp->K_real < 0.)
				stkprint(stp, "     NA ");
			else
				stkprint(stp, " %#7.3lg", kbp->K_real);

		if (kbp->H == kbp->H_real && kbp->H > 0.)
			stkprint(stp, "  same");
		else
			if (kbp->H_real < 0.)
				stkprint(stp, "     NA");
			else
				stkprint(stp, " %#7.3lg", kbp->H_real);
		stkprintnl(stp);
	}
	stkprintnl(stp);

	for (i = 0; i < nctx; ++i) {
		ctxp = &ctxp0[i];
		if (!ctxp->valid)
			continue;
		sw = MAX(sw, Lwidth(ctxp->S, 1));
		ww = MAX(ww, Lwidth(ctxp->W, 1));
		if (ctxp->T < BLAST_SCORE_MAX)
			tw = MAX(tw, Lwidth(ctxp->T, 1));
		xw = MAX(xw, Lwidth(ctxp->X, 1));
		s2w = MAX(s2w, Lwidth(ctxp->S2, 1));
	}
	stkprint(stp, "Query");
	stkprintnl(stp);
	/* still need to report W, T-bits, X-bits, # neighborhood words */
	stkprint(stp, "%s MatID  Length  Eff.Length   E %*sS%*sW%*sT%*sX%*sE2%*sS2",
		ctxtype,
		sw+1, "",
		ww, "",
		tw, "",
		xw, "",
		5, "",
		s2w, ""
		);
	stkprintnl(stp);
	for (i = 0; i < nctx; ++i) {
		ctxp = &ctxp0[i];
		if (!ctxp->valid)
			continue;
		sbp = ctxp->sbp;
		stkprint(stp, " %+d    %3d  %7s   %7.0f %#8.2lg%*d%*d%*s%*d%#8.2lg%*d",
				ctxp->stdframe,
				sbp->id.data.intvalue,
				Ltostr(ctxp->seq->len,1),
				ctxp->seq->efflen,
				ctxp->E,
				sw+1, ctxp->S,
				ww+1, ctxp->W,
				tw+1, (ctxp->T < BLAST_SCORE_MAX ? Ltostr(ctxp->T,0) : "N/A"),
				xw+1, ctxp->X,
				ctxp->E2,
				s2w+1, ctxp->S2
				);
		stkprintnl(stp);
	}

	return 0;
}

int LIBCALL
stk_context_stats(stp, ctxp0, nctx)
	ValNodePtr	PNTR stp;
	ContxtPtr	ctxp0;
	int	nctx;
{
	ContxtPtr	ctxp;
	BLAST_Score	highs_obs;
	CharPtr	ctxtype = "Frame ";
	char	buf[64];
	int	i, j, n, nmax;
	double	x;
	int	ew=2, fw=2, ow=2;

	if (stp == NULL || ctxp0 == NULL || nctx <= 0)
		return 1;

	for (i = 0; i < nctx; ++i) {
		ctxp = &ctxp0[i];
		if (!ctxp->valid)
			continue;
		if (ctxp->seq != NULL && ctxp->seq->ap->alphatype == BLAST_ALPHATYPE_NUCLEIC_ACID)
			ctxtype = "Strand";
		ew = MAX(ew, Lwidth(ctxp->highs_exp, 1));
		x = ctxp->highs_exp * ctxp->kbp->Lambda / NCBIMATH_LN2;
		sprintf(buf, "%.1lf", x);
		fw = MAX(fw, (int)strlen(buf));
		highs_obs = ctxp->wfstats.high_score;
		ow = MAX(ow, Lwidth(highs_obs, 1));
		x = highs_obs * ctxp->kbp->Lambda / NCBIMATH_LN2;
		sprintf(buf, "%.1lf", x);
		fw = MAX(fw, (int)strlen(buf));
	}

	stkprint(stp, "Query          Expected%*sObserved           HSPs       HSPs", ew+fw+2, "");
	stkprintnl(stp);
	stkprint(stp,     "%s MatID  High Score%*sHigh Score       Reportable  Reported", ctxtype, ew+fw, "");
	stkprintnl(stp);
	for (i = 0; i < nctx; ++i) {
		ctxp = &ctxp0[i];
		if (!ctxp->valid)
			continue;
		highs_obs = ctxp->wfstats.high_score;
		nmax = 48;
		if (ctxp->valid) {
			stkprint(stp, " %+d    %3d    %*ld (%.1lf bits)  %*ld (%.1lf bits)%n",
				ctxp->stdframe,
				ctxp->sbp->id.data.intvalue,
				ew, ctxp->highs_exp,
				((double)ctxp->highs_exp)*ctxp->kbp->Lambda / NCBIMATH_LN2,
				ow, highs_obs,
				((double)highs_obs)*ctxp->kbp->Lambda / NCBIMATH_LN2,
				&n);
			nmax = MAX(n, nmax);
			stkprint(stp, "%*s%7lu    %7lu",
				nmax - n, "",
				(unsigned long)ctxp->wfstats.reportable,
				(unsigned long)ctxp->wfstats.reported
				);
		}
		stkprintnl(stp);
	}

	stkprintnl(stp);
	stkprint(stp, "Query         Neighborhd  Word      Excluded    Failed   Successful  Overlaps");
	stkprintnl(stp);
	stkprint(stp,     "%s MatID   Words      Hits        Hits    Extensions Extensions  Excluded",
		ctxtype);
	stkprintnl(stp);
	for (i = 0; i < nctx; ++i) {
		ctxp = &ctxp0[i];
		if (!ctxp->valid)
			continue;
		stkprint(stp, " %+d    %3d  %8lu %11.0lf %11.0lf %11.0lf %8lu %9u",
			ctxp->stdframe,
			ctxp->sbp->id.data.intvalue,
			(unsigned long)(ctxp->wfstats.neighborhood_words + ctxp->wfstats.exact_words),
			(double)(ctxp->wfstats.xword_hits),
			(double)(ctxp->wfstats.xword_hits - ctxp->wfstats.xfailed_extensions - ctxp->wfstats.spanned - ctxp->wfstats.saved),
			(double)(ctxp->wfstats.xfailed_extensions),
			(unsigned long)(ctxp->wfstats.passed),
/* unsigned long)(ctxp->wfstats.saved + ctxp->wfstats.spanned), */
			(unsigned long)(ctxp->wfstats.spanned)
			);
		stkprintnl(stp);
	}

	return 0;
}
