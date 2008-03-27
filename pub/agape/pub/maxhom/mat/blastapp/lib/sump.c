#include <ncbi.h>
#include "blastapp.h"

/*
	modified-L(L,f,n) = L [2 - 2f + (n-2)(1-2f)] + (n-1)
*/

int
sump(bcp, hlp, dblen)
	BLAST_ConfigPtr	bcp;
	BLAST_HitListPtr	hlp;
	double	dblen;
{
	double	p, x, bestx;
	int		cnt;
	register BLAST_HSPPtr	hp, hp2;
	double	sumscore, xscore, logksum, xlen, xqlen, xslen;
	BLAST_HSPPtr	best_hsp;

	best_hsp = NULL;
	bestx = HUGE_VAL;
	for (hp = hlp->hp; hp != NULL; hp = hp->next) {
		cnt = 1;
		xscore = hp->score * hp->kbp->Lambda;
		logksum = hp->kbp->logK;
		xlen = BlastKarlinStoLen(hp->kbp, hp->score);
		xqlen = hp->q_seg.sp->efflen;
		xslen = hp->s_seg.sp->efflen;
		for (hp2 = hp->fwdptr; hp2 != NULL; hp2 = hp2->fwdptr) {
			++cnt;
			xscore += hp2->score * hp2->kbp->Lambda;
			logksum += hp2->kbp->logK;
			xlen += BlastKarlinStoLen(hp2->kbp, hp2->score);
			xqlen += hp2->q_seg.sp->efflen;
			xslen += hp2->s_seg.sp->efflen;
		}
		for (hp2 = hp->revptr; hp2 != NULL; hp2 = hp2->revptr) {
			++cnt;
			xscore += hp2->score * hp2->kbp->Lambda;
			logksum += hp2->kbp->logK;
			xlen += BlastKarlinStoLen(hp2->kbp, hp2->score);
			xqlen += hp2->q_seg.sp->efflen;
			xslen += hp2->s_seg.sp->efflen;
		}
		if (cnt > 1) {
			/* find mean of the effective lengths */
			xqlen /= cnt;
			xslen /= cnt;

			/* calc. a conservative estimate of the expected length */
			xlen /= cnt;
			xlen *= 2 - 2.*overlap_fraction + (cnt-2)*(1.-2.*overlap_fraction);
			xlen += (cnt-1);
		}
		xqlen = MAX(1., xqlen - xlen);
		xslen = MAX(1., xslen - xlen);
		sumscore = xscore - logksum - cnt * log(xqlen*xslen);
		if (bcp->refined_stats) {
			hp->sumscore = sumscore + Nlm_LnGammaInt(cnt + 1);
			p = BlastSumP(hp->n, hp->sumscore);
			p = BlastGapDecay(p, hp->n, bcp->gapdecayrate);
		}
		else
			p = BlastSumP(hp->n, hp->sumscore);
		x = p * dblen / hp->s_seg.sp->efflen;
		hp->evalue = x;
		hp->etype = VSCORE_SUMP;
		if (bestx > x) {
			best_hsp = hp;
			bestx = x;
		}
	}
	hlp->best_hsp = best_hsp;
	return 0;
}
