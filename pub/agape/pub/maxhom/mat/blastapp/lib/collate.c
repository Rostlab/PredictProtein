#include <ncbi.h>
#include "blastapp.h"

/* Collate the results from one processor */
void
collate_hits(BLAST_WordFinderPtr wfp)
{
	register int	i;
	BLAST_WFContextPtr	wfcp;
	ContxtPtr	ctxp;
	BLAST_WFSearchStatsPtr	ssp;
	register BLAST_HitListPtr	hlp;

	if (wfp == NULL)
		return;
	mproc_lock();
	for (i = 0; i < wfp->context_cnt; ++i) {
		wfcp = &wfp->wfcontext[i];
		ssp = &wfcp->stats;
		ctxp = wfcp->user.data.ptrvalue;
		BlastWFSearchStatsSum(&ctxp->wfstats, ssp);
		Nlm_MemSet(ssp, 0, sizeof(*ssp));
	}
#ifdef MPROC_AVAIL
	i = wfp->user.data.intvalue;
	hasHSP += mpc[i].hasHSP;
	totHSP += mpc[i].totHSP;
	realHSP += mpc[i].realHSP;
	if ((hlp = mpc[i].firsthl) != NULL) {
		/* find the tail of the list */
		while (hlp->next != NULL) {
			hlp = hlp->next;
		}
		hlp->next = firsthl;
		firsthl = mpc[i].firsthl;
	}
	Nlm_MemSet(&mpc[i], 0, sizeof(mpc[0]));
#endif /* !MPROC_AVAIL */
	mproc_unlock();
}

long
tot_real()
{
#ifdef MPROC_AVAIL
	int		i;
	long	sum = realHSP;

	for (i = 0; i < numprocs; ++i)
		sum += mpc[i].realHSP;
	return sum;
#else /* !MPROC_AVAIL */
	return realHSP;
#endif /* !MPROC_AVAIL */
}

int
merge_purge(tp)
	TaskBlkPtr	tp;
{
	register BLAST_WordFinderPtr	wfp;
	register BLAST_HitListPtr	hlp;
	register int	i;
	Boolean	once;

	mproc_sync(tp);
	mproc_lock();
	once = purge_flag;
	purge_flag = FALSE;
	mproc_unlock();
	if (once) {
		wfp = tp->userp;
		while (wfp->previous != NULL)
			wfp = wfp->previous;
		for (; wfp != NULL; wfp = wfp->next) {
			collate_hits(wfp);
		}
		remember_cut = realHSP;
		BlastHitListSort(&firsthl, hitlist_cmp_criteria);
		for (i = VHlim, hlp = firsthl; i > 1 && hlp != NULL; --i) {
			hlp = hlp->next;
		}
		if (hlp != NULL) {
			cmphl = hlp;
			hlp->next = NULL; /* storage for hitlists needs to be recovered */
		}
	}
	mproc_sync(tp);
	return 0;
}
