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
TBLASTN - Search a nucleotide database for regions that approximately match
regions of a protein query sequence.  The basic command syntax is

  TBLASTN database query_sequence

  "query_sequence" names a file containing a protein sequence

  "database" consists of nucleotide sequences that are translated
  in all 6 reading frames by default.

The TBLASTN command permits optional additional arguments, such as X=50,
that reset certain internal parameters.  The available parameters are:

  E or e is the _expected_ no. of HSPs to produce (which influences S)
	(default is 10).
  S2 or s2 gives the High-scoring Segment Pair (HSP) cutoff score
	(default is calculated from E2).
  T or t gives the threshold for a word match (default is calculated,
	but is usually about 15 with the PAM120 matrix).
  X or x gives the value for terminating word extensions (default is about 20)
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

    Karlin & Altschul, "Methods for assessing the statistical significance
        of molecular sequence features by using general scoring schemes,"
        Proc. Natl. Acad. Sci. USA 87 (1990) 2264-2268;
    Altschul, Gish, Miller, Myers and Lipman, "Basic local alignment search
        tool," J. Mol. Biol. 214 (1990) in press.

 (Note:  set tabstops every 4 columns for a better appearance).
*/

#define PROG_VERSION	"1.4.6"
#define PROG_DATE	"16-Oct-94"
/*
1.4.6	6-10-94	Final copy release of version 1.4
1.4.5	13-6-94 Moved to asn.1 spec 1.7
1.4.4	31-5-94	Fixed bug in overlap fraction in blast function library
1.4.3	4-4-94	Fixed error reporting of Karlin-Altschul calculation failure
1.4.1	19-10-93 Better consistency checks, so made -overlap2 the default
1.3.8	7-7-93	Added -overlap2 option, prompted by Erik Sonnhammer
1.3.7   25-6-93 Finished gapdecayrate -- modified cutoffs()
1.3.6   22-6-93 Fixed bug in consistp.c implementation of R(i,3) -- Phil Green
1.3.5	21-6-93	Fixed bug in consistent N count calculation for (-) strand hits
1.3.4	9-6-93	Added gapdecayrate suggested by Phil Green; fixed overflow bug
                in lib/consistp.c
1.3.3   9-5-93  Improved handling of database sequences w/ambiguity codes.
                Lowered primary cutoff score in search_aa() to be consistent
                with BLASTP; TBLASTN is thus significantly slower but more
                sensitive.
1.3.2   5-5-93  Karlin H was assumed to have wrong units in lib/stolen.c
1.3.1   23-4-93 Added consistent Poisson P-value calculation
1.3.0   22-11-92 Added consistent Poisson Event count determination
1.2.12	26-10-92  Fixed bug in segmented sequence handling
1.2.11	4-9-92	Fixed bug in lib/hsppool.c
1.2.10	25-8-92	DEC Ultrix compatibility
1.2.9	16-6-92	Added several hitlist sorting options
1.2.8	12-6-92	Fixed bug in lambdak() when smaller alphabets are used
1.2.7	31-3-92	Fixed multiprocessing bug in translate() that failed to set
				s_len for reading frame 1.
				Added gap character '-' to amino acid alphabet.
1.2.6	28-3-92	Independence from the original FASTA-format database file
1.2.5	9-3-92	Faster K calculation in karlin()
1.2.4	18-2-92	Switched to new dfa library
1.2.3	6-1-92	Only use unambiguous letters (non-X) when calculating K & L
1.2.2	26-12-91	Improved error reporting; new K & L options
1.2.1	23-12-91	Improved command line parsing, new -overlap option
1.2.0	1-10-91	Improved Poisson statistics, screening and sorting of hits
1.1.22	25-9-91	Improved reporting of individual HSP statistics
1.1.21	23-9-91	Improved efficiency in search_aa() and extend_aa().
1.1.20	15-9-91	Specific amino acids are properly inferred from ambiguous codons
1.1.19	13-9-91	Changed behavior of parameters V and B.
1.1.18	22-7-91	Default X is calculated using information theory
1.1.16	3-13-91		Added calculation of T when W=3
1.1.15	2-25-91		Added "Searching..." progress indicator
1.1.14	2-4-91		Word-wrap long sequence descriptions
1.1.13	1-28-91		Display one-line description of each db sequence hit
1.1.12	1-17-91		The longest sequence in the database was not being handled
					properly:  null terminators of the translated reading
					frames were being overwritten.
1.1.11	1-16-91		Fixed calculation of Poisson P-values
1.1.10	1-14-91		Fixed bug in bldaa.c regarding perfect matches
1.1.9	12-15-90	Using more common code, new hit lists
1.1.8	12-7-90		Using the improved DFA library code
1.1.7	12-6-90		Moved many statistical calculations into library functions
1.1.6	12-4-90		Fixed BLAST algorithm to halt hit extensions properly
1.1.5	11-24-90	When at least one HSP is found involving a given database
					sequence, it is scanned again using a lower cutoff score.
					The amount the cutoff score is reduced is the V parameter.
*/

#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>

#define EXTERN
#define USESASN1
#ifndef TBLASTN
#define TBLASTN
#endif
#include "blastapp.h"
#include "aabet.h"	/* the alphabet */
#include "ntbet.h"
#include "gcode.h"

BLAST_StrPtr	qsp, xspray[3];
BLAST_AlphabetPtr	blastaa, nt4ap, nt2ap;
BLAST_ScoreBlkPtr	sbp;
BLAST_WordFinderPtr	wfp0;
BLAST_WFContextPtr	wfcp;
BLAST_KarlinBlkPtr	kbp;

ContxtPtr	ctxp;
ValNode	vn;

unsigned char	db_gcode[64], db_revgcode[64];	/* genetic codes */

BLAST_KarlinBlkPtr	lambdak PROTO((BLAST_StrPtr,BLAST_ScoreBlkPtr));
static void	dosearch PROTO((Nlm_VoidPtr userp, TaskBlkPtr tp));
static int	print_t PROTO((BLAST_HitListPtr));

Link1Blk	citation[] = { {NULL,
"Altschul, Stephen F., Warren Gish, Webb Miller, Eugene W. Myers, and David J. Lipman (1990).  Basic local alignment search tool.  J. Mol. Biol. 215:403-10."
	} };

Link1Blk	notice[] = { { NULL,
"statistical significance is estimated under the assumption that the equivalent of one complete reading frame of the database codes for protein and that significant alignments will involve only coding reading frames."
	} };

int
main(argc, argv)
	int		argc;
	char	**argv;
{
	int		i;

	InitBLAST();

	parse_args(argc, argv);

	banner(&b_out, prog_name, prog_desc, prog_version, prog_rel_date, citation, notice, susage, qusage);

	std_defaults();

	blastaa = BlastAlphabetFindByName("OLDBLASTaa");
	nt4ap = BlastAlphabetFindByName("OldBLASTna");
	nt2ap = BlastAlphabetFindByName("NCBI2na");

	init_gcode(find_gcode(dbgcode), db_gcode, db_revgcode);

	/* read file of substitution weights */
	sbp = get_weights(0, M->data.ptrvalue, blastaa, blastaa, altscore);

	qsp = get_query(argv[2], blastaa, qusage, W, 0);
 
	if (seqfilter(filtercmd, qsp->name, qsp->namelen, qsp) != 0)
		bfatal(ERR_UNDEF, "Non-zero return code from sequence filter");
	ctxp = &ctx[nctx++];
	ctxp->seq = qsp;
	ctxp->sbp = sbp;
	
	dbfp = initdb(&b_out, argv[1], susage[0], &dbdesc);
	xspray[0] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);
	xspray[1] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);
	xspray[2] = BlastStrNew(db_maxlen(dbfp)/CODON_LEN, blastaa, 1);

	sys_times(&t1);

	/*
	It would be more accurate to call lambdak() for every sequence in
	the database, but then the program would run much slower.
	Another suggestion is to call lambdak() before reporting
	the probability of an HSP containing part of a specific database
	sequence.  For the sake of speed, though, lambdak() is called only once.
	*/
	if ((ctxp->kbp = kbp = lambdak(qsp, sbp)) == NULL)
		bfatal(ERR_SCORING, "There are no valid contexts in the requested search.");
	if (Meff == 0.)
		Meff = qsp->efflen;

	if (set_context(ctxp, W, 1, 10., 300., Neff / CODON_LEN) != 0)
		bfatal(ERR_SCORING, "Unable to determine \"context\".");
	if (ctxfactor == 0.) {
		ctxfactor = (top + bottom) * CODON_LEN;
		parm_ensure_double("-ctxfactor", 10, "%#0.3lg", ctxfactor);
	}
	context_expect_set(ctx, nctx);

	Bio_JobStartAsnWrite(&b_out, 1, "Neighboring", 1);
	wfp0 = BlastWordFinderNew(TRUE, 1, blastaa, 1, db_maxlen(dbfp)/CODON_LEN);
	vn.data.ptrvalue = ctxp;
	wfcp = BlastWordFinderContextNew(wfp0, &vn, qsp, sbp, W, kbp);
	BlastWFContextExtendParamSet(wfcp, -ctxp->X, ctxp->S2);
	if (BlastWFContextNeighborhoodAdd(wfcp, 0, qsp->len, ctxp->T, 0) != 0)
		bfatal(ERR_UNDEF, "NeighborhoodAdd failed:  %s", BlastErrStr(blast_errno));

	Bio_JobProgressAsnWrite(&b_out, 1, wfcp != NULL);
	if (BlastWordFinderComplete(wfp0) != BLAST_ERR_NONE)
		bfatal(ERR_UNDEF, "WordFinderComplete failed:  %s", BlastErrStr(blast_errno));
	wfp0->wordfinder = BlastWordFinderSelectStats(wfp0);
	Bio_JobDoneAsnWrite(&b_out, 1, 1);

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

	BlastWFSearchStatsSum(&totstats, &ctx[0].wfstats);

	BlastHitListSort(&firsthl, hitlist_cmp_criteria);
	BlastHitListTruncate(&firsthl, VHlim, NULL, NULL);
	get_headers(dbfp, firsthl);

	print_headers(b_out.fp, firsthl, 1.0, TRUE);
	if (showblast < VHlim)
		BlastHitListTruncate(&firsthl, showblast, NULL, NULL);
	print_HSPs(firsthl, 1.0, print_t);

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
	stk_context_parms(stp, ctx, nctx, NULL);
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
		unsigned long	nlen, npos, qpos, spos;
		int		frame, rc;
		BLAST_LetterPtr	cp0;
		BLAST_Letter	stakbuf[10*KBYTE];

		matrix = wfcp->matrix;

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
		frame = hsp.s_seg.frame = hp->s_seg.frame;

		q0 = qsp->str;
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
	BLAST_HitListPDataPtr	pdp;
	BLAST_HitListPtr	hlp;
	int		i;
	BLAST_StrPtr	dbsp, spray[3];
	double	neff = Neff / CODON_LEN;

	ldbfp = db_link(dbfp);
	if (tp->id == 0) {
		wfp = wfp0;
		spray[0] = xspray[0];
		spray[1] = xspray[1];
		spray[2] = xspray[2];
	}
	else {
		wfp = BlastWordFinderDup(wfp0);
		spray[0] = BlastStrNew(db_maxlen(ldbfp)/CODON_LEN, blastaa, 1);
		spray[1] = BlastStrNew(db_maxlen(ldbfp)/CODON_LEN, blastaa, 1);
		spray[2] = BlastStrNew(db_maxlen(ldbfp)/CODON_LEN, blastaa, 1);
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
	db_close(ldbfp);
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
		warning("Invalid (non-negative) expected score of %lg with %s matrix.  The Karlin-Altschul K, Lambda and H parameters could not be computed.",
			(double)sfp->score_avg, sbp->name);
		goto Error;
	}

	kbp = BlastKarlinBlkNew();
	kbp->q_frame = sp->frame;
	kbp->sbp = sbp;

	if (BlastKarlinBlkCalc(kbp, sfp) != BLAST_ERR_NONE) {
		BlastKarlinBlkDestruct(kbp);
		kbp = NULL;
		warning("Could not calculate Karlin-Altschul K, Lambda and H parameters with %s matrix.",
			sbp->name);
		goto Error;
	}

Error:
	BlastResCompDestruct(rcp);
	BlastResFreqDestruct(rfp);
	BlastScoreFreqDestruct(sfp);

	return kbp;
}

static int
print_t(hlp)
	BLAST_HitListPtr	hlp;
{
	FILE	*fp;
	long	nseqlen;
	unsigned long	id;
	int		i, npos, nlen, prevframe, frame;
	BLAST_StrPtr	dbsp, tsp;
	BLAST_HSPPtr	hp;
	BLAST_LetterPtr	nbuf;
	BLAST_Letter	stackbuf[10*KBYTE];
	register char	*cp, *cpmax, ch;

	fp = b_out.fp;

	dbsp = &hlp->str2;
	id = dbsp->id.data.intvalue;
	db_seek(dbfp, id);
	db_get_seq(dbfp, dbsp);
	dbsp->gcode_id = dbgcode;
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
