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
BLASTN - Search a DNA database for regions that approximately match
regions of a query sequence.  The basic command syntax is

    BLASTN database query_sequence

where:
	"database" names a file containing DNA sequences, separated by
 	header lines beginning with the character '>'.  A typical
 	sequence entry is:

		>BOVHBPP3I  Bovine beta-globin psi-3 pseudogene, 5' end.
		GGAGAATAAAGTTTCTGAGTCTAGACACACTGGATCAGCCAATCACAGATGAAGGGCACT
		GAGGAACAGGAGTGCATCTTACATTCCCCCAAACCAATGAACTTGTATTATGCCCTGGGC
		TAATCTGCTCTCAGCAGAGAGGGCAGGGGGCTGGGTGGGGCTCACAAGCAAGACCAGGGC
		CCCTACTGCTTACACTTGCTTCTAACACAACTTGCAACTGCACAAACACACATCATGGTG
		CATCTGACTCTTGAGGGGAAGGCTACTTGTCACT

	The database must be pre-processed by PRESSDB.

 	"query_sequence" names a file containing a DNA sequence (where the
 	header line is optional).

The BLASTN command permits optional additional arguments, such as X=50,
that reset certain internal parameters.  The available parameters are:

   E or e gives the Expected number of HSPs scoring above the cutoff
   S or s gives the cutoff score for High-scoring Segment Pairs (default 100)
   M or m gives the score for a match (default is 5)
   N or n gives the score for a mismatch (default is -4)
   X or x gives the value for terminating word extensions (default is M*W)
   W or w gives the word size (default is 12)
   Y or y gives the effective query sequence length (default is actual length)
   Z or z gives the effective database length (default is the actual length)

Thus a typical command is

    BLASTN DNABANK SEQ M=7 N=-5

   (Note:  set tabstops every 4 columns for a better appearance).
*/
#define PROG_VERSION	"1.4.7"
#define PROG_DATE	"16-Oct-94"
/*
Version	Date	Modification
-------	------	------------------------------------------------------------
1.4.7	6-10-94	Final copy release of version 1.4
1.4.6	8-7-94	Smaller memory needs and a tad faster for default W=12
1.4.4	6-6-94	Activated E2, S2 business, albeit with somewhat conservative E2
1.4.3	31-5-94	Fixed bug in overlap fraction in blast function library
1.4.1	19-10-93 Better consistency checks, so made -overlap2 the default
1.3.11	7-7-93	Added -overlap2 option, prompted by Erik Sonnhammer
1.3.10  25-6-93 Finished gapdecayrate -- modified cutoffs()
1.3.9   22-6-93 Fixed bug in consistp.c implementation of R(i,3) -- Phil Green
1.3.8   21-06-93 Fixed bug in consistent N count calc. on minus strand hits;
                 and cleaned up some cruft.
1.3.7	9-06-93 Added gapdecayrate suggested by Phil Green
1.3.6   9-05-93 SEVERE bugfix: hits on opposite strands not managed separately
1.3.5   8-05-93 Fixed problems when ambiguous nt. in database sequence
1.3.4   6-05-93 Fixed bug from 5/4/93.  First residue on compl. strand not set.
1.3.3   5-05-93 Karlin H was assumed to have wrong units in lib/stolen.c
1.3.2   5-04-93 Fixed problems with ambiguous nucleotides in query sequence
1.3.1   23-04-93 Added consistent Poisson P-value calculation
1.3.0	22-11-92	Added consistency to HSP Poisson event counts
1.2.12	4-9-92	Fixed bug in lib/hsppool.c
1.2.11	25-8-92	DEC Ultrix compatibility
1.2.10	16-6-92	Added several hitlist sorting options
1.2.9	2-4-92	Changed 'X' to '-' in the ASCII nucleotide alphabet
1.2.8	30-3-92 Fixed bug in ovlap_n that failed to remove (-) strand HSPs.
1.2.7	27-3-92	Better handling of ambiguous db seqs; independence from FASTA
1.2.6	9-3-92	Faster K calculation in karlin()
1.2.5	18-2-92	Switched to new dfa library
1.2.4	6-1-92	Only use unambiguous (non-N) letters when calculating K & L
1.2.3	31-12-91	HSP h.frame was not set in searchn.inc
1.2.2	26-12-91	Improved error reporting; new K & L options
1.2.1	23-12-91	Improved command line parsing, new -overlap option
1.2.0	1-10-91	Improved Poisson statistics, screening & sorting of hits
1.1.21	27-9-91	U now matches T
1.1.20	25-9-91	Consistent reporting of individual HSP statistics
1.1.19	19-9-91	Added TOUPPER conversion of sequences read from FASTA database
1.1.18	13-9-91	Changed behavior of parameters V and B.
1.1.17	22-7-91	Default X is calculated using information theory
1.1.15	4-2-91	Word-wrap sequence descriptions
1.1.14	28-1-91	Display one-line description of each db sequence hit
1.1.13	21-1-91	Correctly determines when a W-mer hit overruns the 3' end
				of the compressed database sequence
1.1.12	16-1-91	Fixed another bug in Poisson P-value calculation
1.1.11	15-1-91	Fixed method of Poisson P-value calculation
1.1.10	12-18	Using new hit lists; more shared program code.
1.1.9	12-7-90	Using the improved DFA library code
1.1.8	12-6	Moved many statistical calculations into library functions
1.1.7	11-23	Better handling of ambiguous letters in the query sequence
1.1.6	11-21	Corrected calculation of Poisson P-values
1.1.5	11-20	Renamed the *.tab file to *.ntb, and *.hed to *.nhd
1.1.4	11-16	Modified the *.tab file and added the *.hed file
1.1.3	11-7-90	Multiprocessing is available thru conditional compilation
				(No changes made in this version w.r.t. to uni-processing).
1.1.2	11-5-90	Changed nt. database format to NTFORMAT=4 -- each sequence
				now has terminating sentinel byte(s)
1.1.1			Added REFINED_STATS code to modify Poisson P-values
1.1.0			Added REFINED_STATS code to modify Expect
*/

#include <ncbi.h>
#include <gishlib.h>
#include <sys/stat.h>

#ifndef BLASTN
#define BLASTN
#endif
#define EXTERN
#define USESASN1
#include "blastapp.h"
#include "ntbet.h"
#include "aabet.h"
#include "gcode.h"

BLAST_StrPtr	qsp, qsp_rc; /* query string pointer & reverse complement */

BLAST_AlphabetPtr	nt2ap, nt4ap;

BLAST_WordFinderPtr	wfp0;
BLAST_WFContextPtr	wfcp;
BLAST_FilterPtr	searchffp;

BLAST_KarlinBlkPtr	kbp, kbp_rc;
BLAST_ScoreBlkPtr	sbp4, sbp2, sbp;

BLAST_StrPtr	revcomp PROTO((BLAST_StrPtr));
BLAST_KarlinBlkPtr	lambdak PROTO((BLAST_StrPtr, BLAST_ScoreBlkPtr));
static void	dosearch PROTO((Nlm_VoidPtr userp, TaskBlkPtr tp));
static void	search_nt PROTO((MPPROTO));
static int	print_n PROTO((BLAST_HitListPtr));

Link1Blk	citation[] = { { NULL,
"Altschul, Stephen F., Warren Gish, Webb Miller, Eugene W. Myers, and David J. Lipman (1990).  Basic local alignment search tool.  J. Mol. Biol. 215:403-10."
	} };

Link1Blk	notice[] = { { NULL,
"this program and its default parameter settings are optimized to find nearly identical sequences rapidly.  To identify weak similarities encoded in nucleic acid, use BLASTX, TBLASTN or TBLASTX."
	} };

ContxtPtr	ctxp;
ValNode	vn;

int
main(argc, argv)
	int		argc;
	char	**argv;
{
	int		i, nok;

	InitBLAST();

	parse_args(argc, argv);

	banner(&b_out, prog_name, prog_desc, prog_version, prog_rel_date, citation, notice, susage, qusage);

	std_defaults();

#define WTRANSITION	11
	if (W >= WTRANSITION) {
		nt4ap = BlastAlphabetFindByName("OldBLASTna");
		if (nt4ap == NULL)
			bfatal(ERR_UNDEF, "AlphabetFindByName failed for OldBLASTna; %s", BlastErrStr(blast_errno));
	}
	else {
		nt4ap = BlastAlphabetFindByName("NCBI4na");
		if (nt4ap == NULL)
			bfatal(ERR_UNDEF, "AlphabetFindByName failed for NCBI4na; %s", BlastErrStr(blast_errno));
	}

	nt2ap = BlastAlphabetFindByName("NCBI2na");
	if (nt2ap == NULL)
		bfatal(ERR_UNDEF, "AlphabetFindByName failed for NCBI2na; %s", BlastErrStr(blast_errno));

	if (M == NULL) {
		BLAST_DegenMapPtr	dmp;
		BLAST_ResFreqPtr	rfp, rfp2;

		sbp4 = BlastScoreBlkNew(nt4ap, nt4ap);
		sbp2 = BlastScoreBlkNew(nt4ap, nt2ap);

		dmp = BlastDegenMapFind(nt4ap);
		rfp = BlastResFreqFind(nt4ap);
		if (BlastScoreBlkMatchWeights(sbp4, s_reward, s_penalty, dmp, dmp, rfp, rfp) != 0)
			exit(1);
		apply_altscores(sbp4, altscore);
		rfp2 = BlastResFreqFind(nt2ap);
		if (BlastScoreBlkMatchWeights(sbp2, s_reward, s_penalty, dmp, NULL, rfp, rfp2) != 0)
			exit(1);
		apply_altscores(sbp2, altscore);
	}
	else {
		char	fname[FILENAME_MAX+1];

		sprintf(fname, "%s.4.4", M->data.ptrvalue);
		sbp4 = get_weights(0, fname, nt4ap, nt4ap, altscore);

		sprintf(fname, "%s.4.2", M->data.ptrvalue);
		sbp2 = get_weights(0, fname, nt4ap, nt2ap, altscore);
	}


	if (W < WTRANSITION)
		sbp = sbp4;
	else
		sbp = sbp2;

	qsp = get_query(argv[2], nt4ap, qusage, W, db_strands);
	if (bottom)
		qsp_rc = revcomp(qsp);

	if (top && seqfilter(filtercmd, "Plus-strand", 11, qsp) != 0)
		bfatal(ERR_UNDEF, "Non-zero return code from sequence filter");
	if (bottom && seqfilter(filtercmd, "Minus-strand", 12, qsp_rc) != 0)
		bfatal(ERR_UNDEF, "Non-zero return code from sequence filter");

	if (Y_set)
		qsp->efflen = qsp_rc->efflen = Meff;
	else
		Meff = qsp->efflen;


	dbfp = initdb(&b_out, argv[1], susage[0], &dbdesc);

	/*
	It would be best to call lambdak() for every sequence in
	the database, but then the search would take too long.
	Another suggestion is to call lambdak() before reporting
	the probability of an HSP.  But for speed, lambdak() is
	called only once.
	*/
	if (top) {
		ctx[nctx].seq = qsp;
		ctx[nctx].sbp = sbp4;
		ctx[nctx].stdframe = qsp->frame;
		ctx[nctx].kbp = kbp = kbp_rc = lambdak(qsp, sbp4);
		nctx += (kbp != NULL);
	}
	if (bottom) {
		ctx[nctx].seq = qsp_rc;
		ctx[nctx].sbp = sbp4;
		ctx[nctx].stdframe = qsp_rc->frame;
		ctx[nctx].kbp = kbp_rc = lambdak(qsp_rc, sbp4);
		if (kbp != NULL && kbp_rc != NULL && kbp->Lambda == kbp_rc->Lambda && kbp->K == kbp_rc->K) {
			BlastKarlinBlkDestruct(kbp_rc);
			ctx[nctx].kbp = kbp_rc = kbp;
		}
		if (kbp == NULL)
			kbp = kbp_rc;
		nctx += (kbp_rc != NULL);
	}

#if 1
	if (nctx == 0)
		bfatal(ERR_SCORING, "There are no valid contexts in the requested search.");
#endif
 
	sys_times(&t1);

	Bio_JobStartAsnWrite(&b_out, 1, "Neighboring", top + bottom);
	if (W < WTRANSITION)
		wfp0 = BlastWordFinderNew(T_set, top+bottom, nt4ap, 1, db_maxlen(dbfp));
	else
		wfp0 = BlastWordFinderNew(T_set, top+bottom, nt2ap, 4, db_maxlen(dbfp));

	for (nok = i = 0; i < nctx; ++i) {
		ctxp = &ctx[i];
		vn.data.ptrvalue = ctxp;
		if (set_context(ctxp, W, 1, 20., 1000., Neff) != 0)
			continue;
		wfcp = BlastWordFinderContextNew(wfp0, &vn, ctxp->seq, sbp, W, ctxp->kbp);
		BlastWFContextExtendParamSet(wfcp, -ctxp->X, ctxp->S2);
		if (!T_set) {
			if (BlastWFContextEncodedAdd(wfcp, 0, ctxp->seq->len, 0, FALSE) != 0)
				bfatal(ERR_UNDEF, "EncodedAdd failed:  %s", BlastErrStr(blast_errno));
		}
		else {
			if (BlastWFContextNeighborhoodAdd(wfcp, 0, ctxp->seq->len, T, TRUE) != 0)
				bfatal(ERR_UNDEF, "NeighborhoodAdd failed:  %s", BlastErrStr(blast_errno));
		}
		Bio_JobProgressAsnWrite(&b_out, ++nok, nctx);
	}
#if 1
	if (nok == 0)
		bfatal(ERR_CONTEXTS, "There are no valid contexts in the requested search.");
#endif

	if (ctxfactor == 0.) {
		ctxfactor = context_count(ctx, nctx);
		parm_ensure_double("-ctxfactor", 10, "%#0.3lg", ctxfactor);
	}
	context_expect_set(ctx, nctx);

	BlastWordFinderComplete(wfp0);
	wfp0->wordfinder = BlastWordFinderSelectStats(wfp0);

	Bio_JobDoneAsnWrite(&b_out, nok, nctx);

	sys_times(&t2);

	dfanstates = wfp0->dp->nstates;
	dfastatesize = wfp0->dp->statesize;
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

	print_headers(b_out.fp, firsthl, 1.0, FALSE);
	if (showblast < VHlim)
		BlastHitListTruncate(&firsthl, showblast, NULL, NULL);
	print_HSPs(firsthl, 1.0, print_n);

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

static int
hsp_score_fltr(BLAST_FilterPtr	ffp, BLAST_WFContextPtr wfcp, BLAST_HSPPtr hp)
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
hsp_ambiguity4_fltr(BLAST_FilterPtr ffp, BLAST_WFContextPtr wfcp, BLAST_HSPPtr hp)
{
	DBFilePtr	dbfp;

	dbfp = (DBFilePtr)ffp->data;
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
		BLAST_StrPtr	qsp, ssp;
		BLAST_Diag	diag;
		unsigned long	qpos, spos;
		int		frame, rc;
		BLAST_LetterPtr	cp0;
		BLAST_Letter	stakbuf[10*KBYTE];

		if (hp->len < DIM(stakbuf))
			cp0 = stakbuf;
		else
			cp0 = (BLAST_LetterPtr)BlastMalloc(hp->len * sizeof(*cp0));

		matrix = sbp4->matrix;

		hsp.hlp = NULL;
		hsp.next = NULL;
		hsp.vsp = NULL;
		hsp.wfcp = wfcp;
		hsp.context = hp->context;
		hsp.kbp = hp->kbp;
		hsp.sbp = hp->sbp;
		hsp.q_seg.sp = qsp = hp->q_seg.sp;
		hsp.q_seg.frame = hp->q_seg.frame;
		hsp.s_seg.sp = ssp = hp->s_seg.sp;
		hsp.s_seg.frame = hp->s_seg.frame;

		q0 = qsp->str;
		q = q0 + (qpos = hp->q_seg.offset);
		qf = q + hp->len;
		spos = hp->s_seg.offset;
		s0 = cp0 - spos;
		s = s0 + spos;

		diag = (BLAST_Diag)spos - (BLAST_Diag)qpos;

		if (dbfp->get_str_specific(dbfp, sbp4->a2, cp0, spos, hp->len) != 0)
			return 1;

		score = sum = 0;
		for (q_beg = q; q < qf;) {
			if ((sum += matrix[*q++][*s++]) <= 0) {
				if (score > 0) {
					q = q_end;
					s = s0 + (q_end - q0) + diag;
					if (wfcp->stats.high_score < score)
						wfcp->stats.high_score = score;
					if (score >= wfcp->cutoff) {
						/* Report the HSP */
						hsp.score = score;
						hsp.len = q_end - q_beg;
						hsp.q_seg.offset = q_beg - q0;
						hsp.s_seg.offset = hsp.q_seg.offset + diag;
						if ((rc = ((BLAST_HSPFltrFnPtr)ffp->func)(ffp, wfcp, &hsp)) != 0) {
							if (cp0 != stakbuf)
								BlastFree(cp0);
							return rc;
						}
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
		if (wfcp->stats.high_score < score)
			wfcp->stats.high_score = score;
		if (cp0 != stakbuf)
			BlastFree(cp0);
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

static int
hsp_ambiguity1_fltr(BLAST_FilterPtr ffp, BLAST_WFContextPtr wfcp, BLAST_HSPPtr hp)
{
	DBFilePtr	dbfp;

	dbfp = (DBFilePtr)ffp->data;
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
		BLAST_StrPtr	qsp, ssp;
		BLAST_Diag	diag;
		unsigned long	qpos, spos;
		int		frame, rc;

		matrix = sbp4->matrix;

		hsp.hlp = NULL;
		hsp.next = NULL;
		hsp.vsp = NULL;
		hsp.wfcp = wfcp;
		hsp.context = hp->context;
		hsp.kbp = hp->kbp;
		hsp.sbp = hp->sbp;
		hsp.q_seg.sp = qsp = hp->q_seg.sp;
		hsp.q_seg.frame = hp->q_seg.frame;
		hsp.s_seg.sp = ssp = hp->s_seg.sp;
		hsp.s_seg.frame = hp->s_seg.frame;

		q0 = qsp->str;
		q = q0 + (qpos = hp->q_seg.offset);
		qf = q + hp->len;
		spos = hp->s_seg.offset;
		s0 = ssp->str;
		s = s0 + spos;

		diag = (BLAST_Diag)spos - (BLAST_Diag)qpos;

		dbfp->get_specific(dbfp, ssp, spos, hp->len);

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
						wfcp->dd.diag_level[diag] = (q - q0) + wfcp->W;
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
		wfcp->dd.diag_level[diag] = (q - q0) + wfcp->W;
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
	BLAST_WordFinderPtr wfp;
	BLAST_FilterPtr searchffp = NULL;
	BLAST_HitListPDataPtr	pdp;
	BLAST_HitListPtr   hlp;
	DBFilePtr	ldbfp;
	BLAST_StrPtr	dbsp, ssp, str4 = NULL;

	if (tp->id == 0)
		wfp = wfp0;
	else
		wfp = BlastWordFinderDup(wfp0);
	ldbfp = db_link(dbfp);
	tp->userp = wfp;
	wfp->user.data.intvalue = tp->id;
	score_hist[tp->id] = ScoreHistDup(shp);

	pdp = BlastHitListPDataNew(100);
	hlp = BlastHitListGet(pdp);
	if (db_ambig_avail(ldbfp)) {
		if (W < WTRANSITION)
			BlastFilterStack(&searchffp, hsp_ambiguity1_fltr, 0, ldbfp);
		else
			BlastFilterStack(&searchffp, hsp_ambiguity4_fltr, 0, ldbfp);
	}
	BlastFilterStack(&searchffp, hsp_save_fltr, 0, hlp);
	BlastWordFinderFilterSet(wfp, searchffp);
	ssp = dbsp = BlastStrNew(0, nt2ap, 4);
	if (W < WTRANSITION)
		ssp = str4 = BlastStrNew(db_maxlen(ldbfp), nt4ap, 1);

	/* For each sequence in the database */
	while (TaskNext(tp) >= 0) {
		if (purge_flag)
			merge_purge(tp);
		db_seek(ldbfp, tp->task_cur + dbrecmin);
		db_get_seq(ldbfp, dbsp);
		hlp->str2.id = dbsp->id;
		if (ssp != dbsp)
			cvt_str(dbsp, ssp);

		/* search the database sequence */
		if (BlastWordFinderSearch(wfp, ssp) != BLAST_ERR_NONE)
			bfatal(ERR_UNDEF, "WordFinderSearch failed:  %s", BlastErrStr(blast_errno));
		/* Evaluate any HSPs that were found and save them if appropriate */
		process_hits(tp, hlp, Neff);
	}

	ScoreHistAdd(shp, score_hist[tp->id]);
	collate_hits(wfp);

	BlastHitListPut(hlp);
	BlastStrDestruct(dbsp);
	BlastStrDestruct(str4);
	BlastFilterDestruct(&searchffp);
	BlastWordFinderDestruct(wfp);
	db_close(ldbfp);
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
	sprc->efflen = sp->efflen;
	sprc->str[len] = sp->ap->sentinel;
	while (len-- > 0)
		t[len] = map[*s++];

	return sprc;
}

/* ----------------------------  parameter calculations  ---------------------*/
/* Version of lambdak() specifically for nucleotide alphabet used by BLASTN */
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
	/* Only count unambiguous residues */
	if (BlastAlphaMapTst(amp, 'N'))
		BlastResCompSet(rcp, BlastAlphaMapChr(amp, 'N'), 0);
	if (BlastAlphaMapTst(amp, '-'))
		BlastResCompSet(rcp, BlastAlphaMapChr(amp, '-'), 0);
	sp->efflen = BlastResCompSum(rcp);

	rfp = BlastResFreqNew(sp->ap);
	BlastResFreqResComp(rfp, rcp);
	sfp = BlastScoreFreqNew(sbp->loscore, sbp->hiscore);
	stdrfp = BlastResFreqFind(sp->ap);
	if (BlastScoreFreqCalc(sfp, sbp, rfp, stdrfp) != BLAST_ERR_NONE)
		bfatal(ERR_UNDEF, "ScoreFreqCalc failed:  %s", BlastErrStr(blast_errno));
	if (sfp->score_avg >= 0.) {
		warning("Invalid (non-negative) expected score of %lg for %+d strand with %s matrix.  The Karlin-Altschul K, Lambda and H parameters could not be computed.",
			(double)sfp->score_avg, sp->frame, sbp->name);
		goto Error;
	}

	kbp = BlastKarlinBlkNew();
	kbp->sbp = sbp;
	kbp->q_frame = sp->frame;
	if (BlastKarlinBlkCalc(kbp, sfp) != BLAST_ERR_NONE) {
		BlastKarlinBlkDestruct(kbp);
		kbp = NULL;
		warning("Could not calculate Karlin-Altschul K, Lambda and H parameters for %+d strand with %s matrix.",
			sp->frame, sbp->name);
		goto Error;
	}

Error:
	BlastResCompDestruct(rcp);
	BlastResFreqDestruct(rfp);
	BlastScoreFreqDestruct(sfp);

	return kbp;
}

static int
print_n(hlp)
	BLAST_HitListPtr	hlp;
{
	FILE	*fp;
	unsigned long	id;
	BLAST_HSPPtr	hp;
	int		i, frame, prevframe = 0;
	BLAST_StrPtr	tstr;
	register char	*cp, *cpmax;

	fp = b_out.fp;

	id = hlp->str2.id.data.intvalue;

	db_seek(dbfp, id);
	db_get_seq(dbfp, &hlp->str2);

	tstr = BlastStrNew(hlp->str2.len, nt4ap, 1);
	if (tstr == NULL)
		bfatal(ERR_UNDEF, "BlastStrNew failed:  %s", BlastErrStr(blast_errno));

	if (fp != NULL) {
		cp = hlp->str2.name;
		cpmax = cp + hlp->str2.namelen;
		while (cp < cpmax && !isspace(*cp))
			++cp;
		while (cp < cpmax && isspace(*cp))
			++cp;
		i = cp - hlp->str2.name + 1;
		i = MIN(i, 12);
		putc('\n', fp);
		putc('\n', fp);
		wrap(fp, ">", hlp->str2.name, hlp->str2.namelen, 79, i);
		fprintf(fp, "%*sLength = %s\n", i, "", Ltostr((long)hlp->str2.len,1));
	}

	cvt_str(&hlp->str2, tstr);
	hlp->str2.str = tstr->str;
	hlp->str2.ap = tstr->ap;
	hlp->str2.len = hlp->str2.enclen = tstr->len;
	hlp->str2.lpb = 1;
	for (hp = hlp->hp; hp != NULL; hp = hp->next) {
		hp->sbp = sbp4;
		hp->s_seg.sp = &hlp->str2;
		frame = hp->q_seg.frame;
		if (fp != NULL && SIGN(frame) != SIGN(prevframe)) {
			if (frame > 0)
				fprintf(fp, "\n  Plus");
			else
				fprintf(fp, "\n  Minus");
			fprintf(fp, " Strand HSPs:\n");
		}
		prevframe = frame;
		db_get_specific(dbfp, tstr, hp->s_seg.offset, hp->len);
		if (hsp_print(fp, hp, TRUE) != 0)
			return 1;
	}

	return 0;
}

int
cvt_str(src, dst)
	BLAST_StrPtr	src, dst;
{
	register BLAST_LetterPtr	sp, dp, dpmax, map;
	register BLAST_Letter	ch;
	static BLAST_AlphaMapPtr	amp;

	if (src->lpb != 4 || dst->lpb != 1)
		return 0;

	if (amp == NULL)
		amp = BlastAlphaMapFind(nt2ap, nt4ap);
	map = amp->map;

	dst->id = src->id;
	sp = src->str;  dp = dst->str;  dpmax = dp + src->len;
	*dpmax = nt4ap->sentinel;
	dst->frame = src->frame;
	dst->len = dst->enclen = src->len;
	dst->efflen = src->efflen;

	dpmax -= 4;
	while (dp < dpmax) {
		*dp++ = map[(ch = *sp++)>>6];
		*dp++ = map[(ch>>4)&3];
		*dp++ = map[(ch>>2)&3];
		*dp++ = map[ch&3];
	}
	dpmax += 4;
	while (dp < dpmax) {
		*dp++ = map[(ch = *sp++)>>6];
		if (dp >= dpmax)
			break;
		*dp++ = map[(ch>>4)&3];
		if (dp >= dpmax)
			break;
		*dp++ = map[(ch>>2)&3];
		if (dp >= dpmax)
			break;
		*dp++ = map[ch&3];
	}

	return 0;
}
