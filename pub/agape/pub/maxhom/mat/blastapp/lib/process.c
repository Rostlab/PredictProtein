/* ===========================================================================
*
*                            PUBLIC DOMAIN NOTICE
*               National Center for Biotechnology Information
*
*  This software/database is a "United States Government Work" under the
*  terms of the United States Copyright Act.  It was written as part of
*  the author's official duties as a United States Government employee and
*  thus cannot be copyrighted.  This software/database is freely available
*  to the public for use. The National Library of Medicine and the U.S.
*  Government have not placed any restriction on its use or reproduction.
*
*  Although all reasonable efforts have been taken to ensure the accuracy
*  and reliability of the software and data, the NLM and the U.S.
*  Government do not and cannot warrant the performance or results that
*  may be obtained by using this software or data. The NLM and the U.S.
*  Government disclaim all warranties, express or implied, including
*  warranties of performance, merchantability or fitness for any particular
*  purpose.
*
*  Please cite the author in any work or product based on this material.
*
* ===========================================================================*/
#include <ncbi.h>
#include <blastapp.h>

/*	process_hits

	Process hits (save/discard), based on their features (statistical
	significance, etc.)
*/
void
process_hits(tp, hlp, Neff)
	TaskBlkPtr	tp;
	register BLAST_HitListPtr	hlp;
	double	Neff;
{
	register BLAST_HSPPtr	hp;
	register BLAST_HitListPtr	new_hlp;
	register double	x;
	MPDEF

	if (hlp->hp == NULL)
		return; /* No HSPs were found */

	if (hlp->hspcnt > hsp_max) {
		mproc_lock();
		++hsp_max_exceeded;
		hsp_max_max = MAX(hlp->hspcnt, hsp_max_max);
		mproc_unlock();
		LinkSort((VoidPtr PNTR)&hlp->hp, offsetof(BLAST_HSP,next), BlastHSPCmpByNormScore);
		BlastHSPTruncate(hlp, hsp_max);
	}

	eval_hits(hlp, Neff);

	x = hlp->best_hsp->evalue;
	if (ctxfactor != 1.)
		x *= ctxfactor;
	ScoreHistAddPoint(score_hist[tp->id], x);

	if (x > E) {
DiscardEverything:
		BlastHitListHSPPutAll(hlp);
		return; /* hitlist was not suitable for saving */
	}

	MPINIT(tp->id);
	++MPPTR hasHSP;
	BlastHSPSort(&hlp->hp, hsp_cmp_criteria);
	if (ctxfactor != 1.)
		for (hp = hlp->hp; hp != NULL; hp = hp->next) {
			hp->evalue *= ctxfactor;
		}
	if (!prune_option) {
		if (sump_option)
			BlastHitListPruneLinksByCutoff(hlp, BLAST_HSPSCORE_EVALUE, E);
		else
			BlastHitListTruncateByCutoff(hlp, BLAST_HSPSCORE_EVALUE, E);
	}
	MPPTR totHSP += hlp->hspcnt;
	for (hp = hlp->hp; hp != NULL; hp = hp->next)
		hp->wfcp->stats.reportable++;
	if (BlastHitListCmpStd(cmphl, hlp, hitlist_cmp_criteria) < 0)
		goto DiscardEverything;
	TaskPosIncr(tp);
	++MPPTR realHSP;
	BlastHSPNumber(hlp->hp);
	for (hp = hlp->hp; hp != NULL; hp = hp->next)
		hp->pvalue = BlastKarlinEtoP(hp->evalue);
	new_hlp = BlastHitListSave(hlp);
	new_hlp->next = MPPTR firsthl;
	MPPTR firsthl = new_hlp;
	if (tot_real() - remember_cut > remember_max)
		purge_flag = TRUE;
	return;
}

/*	eval_hits

	Performs statistical evaluation of the hitlist.
*/
void
eval_hits(hlp, Neff)
	register BLAST_HitListPtr	hlp;
	double	Neff; /* effective database length */
{
	if (hlp->hp == NULL)
		return; /* No HSPs were found */

	if (sump_option) {
		consist_sum(blast_config, hlp, overlap_fraction);
		sump(blast_config, hlp, Neff);
	}
	else
		if (consistency_flag) {
			consistn_dynamic(blast_config, hlp, overlap_fraction);
			consist_evals(blast_config, hlp, Neff);
		}
		else {
			pcnt(hlp);
			evals(blast_config, hlp, Neff);
		}
	return;
}
