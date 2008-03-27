/**************************************************************************
*                                                                         *
*                             COPYRIGHT NOTICE                            *
*                                                                         *
* This software/database is categorized as "United States Government      *
* Work" under the terms of the United States Copyright Act.  It was       *
* produced as part of the author's official duties as a Government        *
* employee and thus can not be copyrighted.  This software/database is    *
* freely available to the public for use without a copyright notice.      *
* Restrictions can not be placed on its present or future use.            *
*                                                                         *
* Although all reasonable efforts have been taken to ensure the accuracy  *
* and reliability of the software and data, the National Library of       *
* Medicine (NLM) and the U.S. Government do not and can not warrant the   *
* performance or results that may be obtained by using this software,     *
* data, or derivative works thereof.  The NLM and the U.S. Government     *
* disclaim any and all warranties, expressed or implied, as to the        *
* performance, merchantability or fitness for any particular purpose or   *
* use.                                                                    *
*                                                                         *
* In any work or product derived from this material, proper attribution   *
* of the author(s) as the source of the software or data would be         *
* appreciated.                                                            *
*                                                                         *
**************************************************************************/
/*
TBLASTX - Search a nucleotide database for regions that approximately match
regions of a protein query sequence.  The basic command syntax is

 	TBLASTX database query_sequence

	query_sequence names a file containing a protein sequence (where the
	> header line is optional).

The TBLASTX command permits optional additional arguments, such as X=50,
that reset certain internal parameters.  The available parameters are:

	E or e is the _expected_ no. of HSPs to produce (which influences S)
		(default is 25).
	S or s gives the High-scoring Segment Pair (HSP) cutoff score
		(default is calculated from E).
	T or t gives the threshold for a word match (default is calculated,
		but is usually about 15 with the PAM120 matrix).
	X or x gives the value for terminating word extensions (default is 20)
	M or m is the name of a file containing substitution costs matrix
		(default is "BLOSUM62")
	Y or y is the effective length of the querY sequence for statistical
		significance calculations (default uses the actual query length)
	Z or z is the effective databaZe length for statistical significance
		calculations (default uses the actual database length)
	C or c is the identifying number of the genetic code to use.  The
		default value is 0, which represents the standard genetic code.
		See gcode.h for the list of pre-defined genetic codes.
	P or p is the number of processors to utilize when the program
		is compiled to run on a multi-processor computer.

Thus a typical command is

	tblastn genbank myseq e=0.5 x=25

Literature:

	TBLASTX has not been published.

    Karlin & Altschul, "Methods for assessing the statistical significance
        of molecular sequence features by using general scoring schemes,"
        Proc. Natl. Acad. Sci. USA 87 (1990) 2264-2268;
    Altschul, Gish, Miller, Myers and Lipman, "Basic local alignment search
        tool," J. Mol. Biol. 214 (1990) in press.

 (Note:  set tabstops every 4 columns for a better appearance).
*/

#define	PROG_VERSION	"1.4.6"
#define PROG_DATE	"16-Oct-94"
/*
1.4.6	6-10-94	Final copy release of version 1.4
1.4.5	13-6-94 Moved to asn.1 spec 1.7
1.4.4	31-5-94	Fixed bug in overlap fraction in blast function library
1.4.3	4-4-94	Fixed error reporting of Karlin-Altschul calculation failure
1.4.1	19-10-93 Better consistency checks, so made -overlap2 the default
1.4.0	First version -- adapted from BLASTX and TBLASTN
*/

#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>

#define EXTERN
#define USESASN1
#ifndef TBLASTX
#define TBLASTX
#endif
#include "blastapp.h"
#include "aabet.h"	/* the alphabet */
#include "ntbet.h"
#include "gcode.h"

BLAST_StrPtr	nsp, nsp_rc, xspray[3];
BLAST_AlphabetPtr	blastaa, nt4ap, nt2ap;
BLAST_ScoreBlkPtr	sbp;
BLAST_WordFinderPtr	wfp0;
BLAST_WFContextPtr	wfcp;
BLAST_KarlinBlkPtr	kbp;

unsigned char	gcode[64], revgcode[64];	/* genetic code for query xlation */
unsigned char	db_gcode[64], db_revgcode[64]; /* ... for db xlation */

ContxtPtr	ctxp;
ValNode	vn;
Contxt		stdctx;

Boolean	cdi_flag;

BLAST_StrPtr	revcomp PROTO((BLAST_StrPtr));
BLAST_KarlinBlkPtr	lambdak PROTO((BLAST_StrPtr,BLAST_ScoreBlkPtr));
static void	dosearch PROTO((Nlm_VoidPtr userp, TaskBlkPtr tp));
static int	print_tx PROTO((BLAST_HitListPtr));

Link1Blk	citation[] = {
{ &citation[1],
"Gish, W. (1994). unpublished."
	},
{ NULL,
"Altschul, Stephen F., Warren Gish, Webb Miller, Eugene W. Myers, and David J. Lipman (1990).  Basic local alignment search tool.  J. Mol. Biol. 215:403-10."
	} };

Link1Blk	notice[] = {
	{ NULL,
"statistical significance is estimated under the assumption that the equivalent of one entire reading frame of the query sequence and one entire reading frame of the database code for protein and that significant alignments will only involve coding reading frames."
	} };

int
main(argc, argv)
	int		argc;
	char	**argv;
{
	int		i, frame, nok, npos;
	double	x;

	InitBLAST();

	parse_args(argc, argv);

	banner(&b_out, prog_name, prog_desc, prog_version, prog_rel_date, citation, notice, susage, qusage);

	std_defaults();

	blastaa = BlastAlphabetFindByName("OLDBLASTaa");
	nt4ap = BlastAlphabetFindByName("OldBLASTna");
	nt2ap = BlastAlphabetFindByName("NCBI2na");

	init_gcode(find_gcode(C), gcode, revgcode);
	init_gcode(find_gcode(dbgcode), db_gcode, db_revgcode);

	/* read file of substitution weights */
	sbp = get_weights(0, M->data.ptrvalue, blastaa, blastaa, altscore);

	nsp = get_query(argv[2], nt4ap, qusage, W, query_strands);
	if (nsp->len < CODON_LEN)
		bfatal(ERR_QUERYLEN, "Query sequence is too short (less than %d residues)", CODON_LEN);
	if (bottom)
		nsp_rc = revcomp(nsp);
 
	xlat_query();

	dbfp = initdb(&b_out, argv[1], susage[0], &dbdesc);

	xspray[0] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);
	xspray[1] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);
	xspray[2] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);

	for (nok = i = 0; i < nctx; ++i) {
		ctxp = &ctx[i];
		kbp = ctxp->kbp = lambdak(ctxp->seq, ctxp->sbp = sbp);
		if (kbp == NULL) {
			warning("Could not calculate Lambda, K, and H in frame %d",
					ctxp->stdframe);
			continue;
		}
		++nok;
		if (Y_set)
			ctxp->seq->efflen = Meff / CODON_LEN;
	}
	if (nok == 0)
		bfatal(ERR_SCORING, "There are no valid contexts in the requested search.");

	adjust_kablks(ctx, nctx, &stdctx);
	for (nok = i = 0; i < nctx; ++i) {
		ctxp = &ctx[i];
		if (ctxp->kbp == NULL)
			continue;
		if (set_context(ctxp, W, 1, 10., 300., Neff / CODON_LEN) != 0)
			continue;
		++nok;
	}
	if (ctxfactor == 0.) {
		ctxfactor = context_count(ctx, nctx) * (top + bottom) * CODON_LEN;
		parm_ensure_double("-ctxfactor", 10, "%#0.3lg", ctxfactor);
	}
	context_expect_set(ctx, nctx);

	sys_times(&t1);

	Bio_JobStartAsnWrite(&b_out, 1, "Neighboring", nok);
	wfp0 = BlastWordFinderNew(TRUE, (top + bottom)*3, blastaa, 1, db_maxlen(dbfp)/CODON_LEN);

	/* build table of critical (neighborhood) words */
	for (nok = npos = i = 0; i < nctx; ++i) {
		ctxp = &ctx[i];
		if (!ctxp->valid)
			continue;
		++nok;
		vn.data.ptrvalue = ctxp;
		wfcp = BlastWordFinderContextNew(wfp0, &vn, ctxp->seq, sbp, W, ctxp->kbp);
		BlastWFContextExtendParamSet(wfcp, -ctxp->X, ctxp->S);
		if (BlastWFContextNeighborhoodAdd(wfcp, 0, ctxp->seq->len, ctxp->T, 0) != 0)
			bfatal(ERR_UNDEF, "NeighborhoodAdd failed:  %s", BlastErrStr(blast_errno));
		++npos;
		Bio_JobProgressAsnWrite(&b_out, nok, npos);
	}
	if (BlastWordFinderComplete(wfp0) != BLAST_ERR_NONE)
		bfatal(ERR_UNDEF, "WordFinderComplete failed:  %s", BlastErrStr(blast_errno));
	wfp0->wordfinder = BlastWordFinderSelectStats(wfp0);
	Bio_JobDoneAsnWrite(&b_out, nok, npos);

	sys_times(&t2);

	dfastatesize = wfp0->dp->statesize;
	dfanstates = wfp0->dp->nstates;
	dfasize = dfa_size(wfp0->dp);
	dfaextent = dfa_extent(wfp0->dp);

	format_parms(&parmstk);
	Bio_ParmsAsnWrite(&b_out, parmstk);
	Bio_ScoreBlkAsnWrite(&b_out, ctx, nctx, TRUE);
	Bio_KABlkAsnWrite(&b_out, ctx, nctx);

	RunWild(2, "Searching", dbreccnt, dosearch);
#ifdef SIGXCPU
	/* Report results without interruption */
	signal(SIGXCPU, SIG_IGN);
#endif

	sys_times(&t3);

	if (hsp_max_exceeded > 0)
		warning("-hspmax %d was exceeded with %d of the database sequences, with as many as %d HSPs being found at one time.", hsp_max, hsp_max_exceeded, hsp_max_max);

	ScoreHistPrint(shp, b_out.fp, E, hasHSP);

	for (i = 0; i < nctx; ++i) {
		BlastWFSearchStatsSum(&totstats, &ctx[i].wfstats);
	}

	BlastHitListSort(&firsthl, hitlist_cmp_criteria);
	BlastHitListTruncate(&firsthl, VHlim, NULL, NULL);
	get_headers(dbfp, firsthl);

	print_headers(b_out.fp, firsthl, 1.0, TRUE);
	if (showblast < VHlim)
		BlastHitListTruncate(&firsthl, showblast, NULL, NULL);
	print_HSPs(firsthl, 1.0, print_tx);

	sys_times(&t4);

	print_stack(&b_out, "Parameters:", parmstk);
	format_stats(&statstk);
	print_stack(&b_out, "Statistics:", statstk);
	Bio_StatsAsnWrite(&b_out, statstk);

	Bio_ResultAsnWrite(&b_out, shp, E, hasHSP, 2, hsp_si, firsthl);

	ckwarnings();

	exit_code(ERR_NONE, NULL);
	/*NOTREACHED*/
}


format_parms(stp)
	ValNodePtr	PNTR stp;
{
	stk_context_parms(stp, ctx, nctx, &stdctx);
	return 0;
}

static int
hsp_score_fltr(BLAST_FilterPtr ffp, BLAST_WFContextPtr wfcp, BLAST_HSPPtr hp)
{
	if (hp->score >= wfcp->cutoff && ffp->next != NULL)
		return ffp->next->func(ffp->next, wfcp, hp);
	return 0;
}

static int
hsp_save_fltr(BLAST_FilterPtr ffp, BLAST_WFContextPtr wfcp, BLAST_HSPPtr hp)
{
	BLAST_HitListPtr	hlp = (BLAST_HitListPtr)(ffp->data);

	if (BlastCheckSpan(hlp, spanfunc, hp) != 0)
		return 0;
	if (ffp->next != NULL)
		return ffp->next->func(ffp->next, wfcp, hp);
	return 0;
}

static int
hsp_ambiguity_fltr(BLAST_FilterPtr ffp, BLAST_WFContextPtr wfcp, BLAST_HSPPtr hp)
{
	DBFilePtr	dbfp;
	unsigned long	id;

	dbfp = ffp->data;
	if ((ffp = ffp->next) == NULL)
		return 0;

	if (!dbfp->ambiguous(dbfp))
		return ((BLAST_HSPFltrFnPtr)ffp->func)(ffp, wfcp, hp);

	/*
		Check for ambiguity codes in the underlying nucleic acid sequence
	*/
	{
		BLAST_ScoreMat	matrix;
		BLAST_HSP	hsp;
		register BLAST_LetterPtr	q, s, q_beg, q_end;
		register BLAST_Score	score, sum;
		BLAST_LetterPtr	q0, qf, s0;
		BLAST_StrPtr	nsp, ssp;
		BLAST_Diag	diag;
		unsigned long	nlen, npos, qpos, spos;
		int		frame, rc;
		BLAST_LetterPtr	cp0;
		BLAST_Letter	stakbuf[10*KBYTE];

		matrix = wfcp->matrix;

		hsp.next = NULL;
		hsp.vsp = NULL;
		hsp.hlp = NULL;
		hsp.wfcp = wfcp;
		hsp.context = hp->context;
		hsp.kbp = hp->kbp;
		hsp.sbp = hp->sbp;
		hsp.q_seg.sp = nsp = hp->q_seg.sp;
		hsp.q_seg.frame = hp->q_seg.frame;
		hsp.s_seg.sp = ssp = hp->s_seg.sp;
		frame = hsp.s_seg.frame = hp->s_seg.frame;

		q0 = nsp->str;
		q = q0 + (qpos = hp->q_seg.offset);
		qf = q + hp->len;
		s0 = ssp->str;
		s = s0 + (spos = hp->s_seg.offset);

		diag = (BLAST_Diag)spos - (BLAST_Diag)qpos;

		nlen = hp->len * CODON_LEN;
		if (frame > 0)
			npos = spos*CODON_LEN + frame - 1;
		else
			npos =  hp->s_seg.sp->src->len - spos*CODON_LEN + frame - nlen + 1;
		if (nlen < DIM(stakbuf))
			cp0 = stakbuf;
		else
			cp0 = (BLAST_LetterPtr)BlastMalloc(nlen * sizeof(*cp0));

		if (dbfp->get_str_specific(dbfp, nt4ap, cp0, npos, nlen) != 0)
			return 1;
		if (frame > 0)
			trans2b(cp0, s0 + spos, hp->len, db_gcode);
		else
			rtrans2b(cp0, s0 + spos, hp->len, db_revgcode);

		if (cp0 != stakbuf)
			BlastFree(cp0);

		score = sum = 0;
		for (q_beg = q; q < qf;) {
			if ((sum += matrix[*q++][*s++]) <= 0) {
				if (score > 0) {
					q = q_end;
					s = s0 + (q_end - q0) + diag;
#ifdef BLAST_STATS
					if (wfcp->stats.high_score < score)
						wfcp->stats.high_score = score;
#endif
					if (score >= wfcp->cutoff) {
						/* Report the HSP */
						hsp.score = score;
						hsp.len = q_end - q_beg;
						hsp.q_seg.offset = q_beg - q0;
						hsp.s_seg.offset = hsp.q_seg.offset + diag;
						if ((rc = ((BLAST_HSPFltrFnPtr)ffp->func)(ffp, wfcp, &hsp)) != 0)
							return rc;
					}
				}
				score = sum = 0;
				q_beg = q_end = q;
			}
			else
				if (sum > score) {
					score = sum;
					q_end = q;
				}
		}
#ifdef BLAST_STATS
		if (wfcp->stats.high_score < score)
			wfcp->stats.high_score = score;
#endif
		if (score >= wfcp->cutoff) {
			/* Report the HSP */
			hsp.score = score;
			hsp.len = q_end - q_beg;
			hsp.q_seg.offset = q_beg - q0;
			hsp.s_seg.offset = hsp.q_seg.offset + diag;
			return ((BLAST_HSPFltrFnPtr)ffp->func)(ffp, wfcp, &hsp);
		}
	}
	return 0;
}

static void
dosearch(userp, tp)
	Nlm_VoidPtr	userp;
	TaskBlkPtr	tp;
{
	DBFilePtr	ldbfp;
	BLAST_WordFinderPtr	wfp;
	BLAST_FilterPtr	searchffp = NULL;
	BLAST_HitListPtr	hlp;
	BLAST_HitListPDataPtr	pdp;
	int		i;
	double	neff = Neff / CODON_LEN;
	BLAST_StrPtr	dbsp, spray[3];

	ldbfp = db_link(dbfp);
	if (tp->id == 0) {
		wfp = wfp0;
		spray[0] = xspray[0];
		spray[1] = xspray[1];
		spray[2] = xspray[2];
	}
	else {
		wfp = BlastWordFinderDup(wfp0);
		spray[0] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);
		spray[1] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);
		spray[2] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);
	}
	tp->userp = wfp;
	wfp->user.data.intvalue = tp->id;
	score_hist[tp->id] = ScoreHistDup(shp);

	pdp = BlastHitListPDataNew(100);
	hlp = BlastHitListGet(pdp);
	if (db_ambig_avail(ldbfp))
		BlastFilterStack(&searchffp, hsp_ambiguity_fltr, 0, ldbfp);
	BlastFilterStack(&searchffp, hsp_save_fltr, 0, hlp);
	BlastWordFinderFilterSet(wfp, searchffp);
	dbsp = BlastStrNew(0, nt2ap, 4);
	dbsp->gcode_id = dbgcode;

	/* For each sequence in the database */
	while (TaskNext(tp) >= 0) {
		if (purge_flag)
			merge_purge(tp);
		db_seek(ldbfp, tp->task_cur + dbrecmin);
		db_get_seq(ldbfp, dbsp);
		hlp->str2.id = dbsp->id;

		if (dbsp->len >= CODON_LEN) {
			if (db_strands & TOP_STRAND) {
				translate(dbsp, spray[0], spray[1], spray[2], db_gcode);
				for (i = 0; i < CODON_LEN; ++i) {
					if (BlastWordFinderSearch(wfp, spray[i]) != BLAST_ERR_NONE)
						bfatal(ERR_UNDEF, "WordFinderSearch failed:  %s", BlastErrStr(blast_errno));
				}
			}
			if (db_strands & BOTTOM_STRAND) {
				btranslate(dbsp, spray[0], spray[1], spray[2], db_revgcode);
				for (i = 0; i < CODON_LEN; ++i) {
					if (BlastWordFinderSearch(wfp, spray[i]) != BLAST_ERR_NONE)
						bfatal(ERR_UNDEF, "WordFinderSearch failed:  %s", BlastErrStr(blast_errno));
				}
			}
		}
		/* Evaluate any HSPs that were found and save them if appropriate */
		process_hits(tp, hlp, neff);
	}

	ScoreHistAdd(shp, score_hist[tp->id]);
	collate_hits(wfp);

	BlastHitListPut(hlp);
	BlastStrDestruct(dbsp);
	BlastFilterDestruct(&searchffp);
	BlastWordFinderDestruct(wfp);
	if (tp->id != 0) {
		BlastStrDestruct(spray[0]);
		BlastStrDestruct(spray[1]);
		BlastStrDestruct(spray[2]);
	}
}

BLAST_StrPtr
revcomp(sp)
	BLAST_StrPtr	sp;
{
	BLAST_StrPtr	sprc;
	register size_t	len;
	register BLAST_LetterPtr	s, t, map;

	map = BlastAlphaMapFind(sp->ap, sp->ap)->map;

	sprc = BlastStrNew(sp->len, sp->ap, 1);
	if (sprc == NULL)
		return sprc;

	sprc->frame = -sp->frame;
	sprc->offset = sp->offset;
	sprc->fulllen = sp->fulllen;
	s = sp->str;
	t = sprc->str;
	len = sprc->len = sprc->enclen = sp->len;
	sprc->efflen = len;
	sprc->str[len] = sp->ap->sentinel;
	while (len-- > 0)
		t[len] = map[*s++];

	return sprc;
}

/* nucleotide sequence --> amino acid sequence translation routines */

xlat_query()
{
	BLAST_StrPtr	xlat_seq PROTO((BLAST_LetterPtr, size_t, unsigned char PNTR));
	int		i, len, frame;
	char	name[30];

	for (frame=minframe; frame<3; ++frame) {
		ctxp = &ctx[nctx++];
		nsp->gcode_id = C;
		ctxp->seq = xlat_seq(nsp->str+frame, nsp->len-frame, gcode);
		ctxp->stdframe = frame + 1;
		ctxp->seq->frame = ctxp->stdframe;
		ctxp->seq->src = nsp;
		sprintf(name, "Frame %+d", ctxp->stdframe);
		i = strlen(name);
		if (seqfilter(filtercmd, name, i, ctxp->seq) != 0)
			bfatal(ERR_UNDEF, "Non-zero return code from sequence filter");
	}
	for (frame=3; frame<maxframe; ++frame) {
		ctxp = &ctx[nctx++];
		nsp_rc->gcode_id = C;
		ctxp->seq = xlat_seq(nsp_rc->str+frame-3, nsp->len-frame+3, gcode);
		ctxp->stdframe = 2 - frame;
		ctxp->seq->frame = ctxp->stdframe;
		ctxp->seq->src = nsp_rc;
		sprintf(name, "Frame%+d", ctxp->stdframe);
		i = strlen(name);
		if (seqfilter(filtercmd, name, i, ctxp->seq) != 0)
			bfatal(ERR_UNDEF, "Non-zero return code from sequence filter");
	}
}

BLAST_StrPtr
xlat_seq(nseq, nlen, gcode)
	register BLAST_LetterPtr	nseq;
	size_t	nlen;
	unsigned char	PNTR gcode;
{
	BLAST_StrPtr	sp;
	int		len;
	register BLAST_LetterPtr	cp;
	register BLAST_Letter	aa;
	register unsigned	n1, n2, n3;

	len = nlen / 3;
	len = MAX(len, 0);
	sp = BlastStrNew(len, blastaa, 1);
	cp = sp->str;

	while (nlen > 2) {
		nlen -= CODON_LEN;
		n1 = nseq[0];
		n2 = nseq[1];
		n3 = nseq[2];
		if (!cdi_flag)
			aa = codon2aa(gcode, n1, n2, n3);
		else {
			if (n1 < 4 && n2 < 4 && n3 < 4)
				aa = n1*(4*4) + n2*4 + n3 + 1;
			else
				aa = (64+1);
		}
		nseq += CODON_LEN;
		*cp++ = aa;
	}
	*cp = sp->ap->sentinel;
	sp->len = sp->enclen = cp - sp->str;
	sp->efflen = sp->len;
	sp->lpb = 1;

	return sp;
}

BLAST_KarlinBlkPtr
lambdak(sp, sbp)
	BLAST_StrPtr	sp;
	BLAST_ScoreBlkPtr	sbp;
{
	BLAST_KarlinBlkPtr	kbp = NULL;
	BLAST_ResCompPtr	rcp;
	BLAST_ResFreqPtr	rfp, stdrfp;
	BLAST_ScoreFreqPtr	sfp;
	BLAST_AlphaMapPtr	amp;

	amp = sp->ap->inmap;

	rcp = BlastResCompNew(sp->ap);
	BlastResCompStr(rcp, sp, TRUE);
	/* Only count unambiguous residues -- must know that X is ambiguous */
	if (BlastAlphaMapTst(amp, 'X'))
		BlastResCompSet(rcp, BlastAlphaMapChr(amp, 'X'), 0);
	if (BlastAlphaMapTst(amp, '-'))
		BlastResCompSet(rcp, BlastAlphaMapChr(amp, '-'), 0);
	sp->efflen = BlastResCompSum(rcp);

	rfp = BlastResFreqNew(sp->ap);
	BlastResFreqResComp(rfp, rcp);
	sfp = BlastScoreFreqNew(sbp->loscore, sbp->hiscore);
	stdrfp = BlastResFreqFind(sp->ap);
	BlastScoreFreqCalc(sfp, sbp, rfp, stdrfp);

	if (sfp->score_avg >= 0.) {
		warning("Invalid (non-negative) expected score of %lg for frame %+d with %s matrix.  The Karlin-Altschul K, Lambda and H parameters could not be computed.",
			(double)sfp->score_avg, sp->frame, sbp->name);
		goto Error;
	}

	kbp = BlastKarlinBlkNew();
	kbp->q_frame = sp->frame;
	kbp->sbp = sbp;

	if (BlastKarlinBlkCalc(kbp, sfp) != BLAST_ERR_NONE) {
		BlastKarlinBlkDestruct(kbp);
		kbp = NULL;
		warning("Could not calculate Karlin-Altschul K, Lambda and H parameters for frame %+d with %s matrix.",
			sp->frame, sbp->name);
		goto Error;
	}

Error:
	if (stdctx.kbp == NULL) {
		stdctx.kbp = BlastKarlinBlkNew();
		stdctx.sbp = sbp;
		BlastScoreFreqCalc(sfp, sbp, stdrfp, stdrfp);
		if (BlastKarlinBlkCalc(stdctx.kbp, sfp) != BLAST_ERR_NONE) {
			BlastKarlinBlkDestruct(stdctx.kbp);
			stdctx.kbp = NULL;
		}
	}

	BlastResCompDestruct(rcp);
	BlastResFreqDestruct(rfp);
	BlastScoreFreqDestruct(sfp);

	return kbp;
}

static int
print_tx(hlp)
	BLAST_HitListPtr	hlp;
{
	FILE	*fp;
	long	nseqlen;
	unsigned long	id;
	int		i, npos, nlen, prevframe, frame, ambiguous;
	BLAST_StrPtr	dbsp, tsp;
	BLAST_HSPPtr	hp;
	BLAST_LetterPtr	nbuf;
	BLAST_Letter	stackbuf[10*KBYTE];
	register char	*cp, *cpmax, ch;

	fp = b_out.fp;

	dbsp = &hlp->str2;
	id = dbsp->id.data.intvalue;
	db_seek(dbfp, dbsp->id.data.intvalue);
	db_get_seq(dbfp, dbsp);
	nseqlen = dbsp->len;

	if (fp != NULL) {
		cp = dbsp->name;
		cpmax = cp + dbsp->namelen;
		while (cp < cpmax && !isspace(*cp))
			++cp;
		while (cp < cpmax && isspace(*cp))
			++cp;
		i = cp - dbsp->name + 1;
		i = MIN(i, 12);
		putc('\n', fp);
		putc('\n', fp);
		wrap(fp, ">", dbsp->name, dbsp->namelen, 79, i);
		fprintf(fp, "%*sLength = %s\n", i, "", Ltostr(nseqlen,1));
	}

	prevframe = 0;
	for (hp = hlp->hp; hp != NULL; hp = hp->next) {
		frame = hp->s_seg.frame;
		nlen = hp->len * CODON_LEN;
		if (nlen <= DIM(stackbuf))
			nbuf = stackbuf;
		else
			nbuf = (BLAST_LetterPtr)mem_malloc(nlen * sizeof(*nbuf));
		if (frame > 0)
			npos = hp->s_seg.offset*CODON_LEN + frame - 1;
		else
			npos = nseqlen - hp->s_seg.offset*CODON_LEN + frame - nlen + 1;

		tsp = BlastStrNew(hp->len, blastaa, 1);
		tsp->src = dbsp;
		tsp->offset = hp->s_seg.offset;
		tsp->frame = hp->s_seg.frame;
		tsp->gcode_id = dbgcode;
		hp->s_seg.sp = tsp;
		hp->s_seg.offset = 0;

		db_get_str_specific(dbfp, nt4ap, nbuf, npos, nlen);
		if (frame > 0)
			trans2b(nbuf, tsp->str, hp->len, db_gcode);
		else
			rtrans2b(nbuf, tsp->str, hp->len, db_revgcode);

		if (nbuf != stackbuf)
			mem_free(nbuf);

		if (fp != NULL && SIGN(prevframe) != SIGN(frame)) {
			if (frame > 0)
				fprintf(fp, "\n  Plus");
			else
				fprintf(fp, "\n  Minus");
			fprintf(fp, " Strand HSPs:\n");
		}
		prevframe = frame;

		if (hsp_print(fp, hp, TRUE) != 0)
			return 1;
	}
	return 0;
}
