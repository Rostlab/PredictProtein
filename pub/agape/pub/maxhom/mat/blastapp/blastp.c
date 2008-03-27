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
BLASTP - Search a protein database for regions that approximately match
regions of a query sequence.  The basic command syntax is

 	BLASTP database query_sequence

where:
 	"database" names a file containing protein sequences, separated by
	header lines beginning with the character '>'.  A typical
	sequence entry is:

		>CCHU (PIR) Cytochrome c - Human | 1.0,1.0,1.0,1.0,1.0
		GDVEKGKKIFIMKCSQCHTVEKGGKHKTGP
		NLHGLFGRKTGQAPGYSYTAANKNKGIIWG
		EDTLMEYLENPKKYIPGTKMIFVGIKKKEE
		RADLIAYLKKATNE

	The database must be pre-processed with the SETDB program.

	"query_sequence" names a file containing a protein sequence (where the
	header line is optional).

The BLASTP command permits optional additional arguments, such as X=50,
that reset certain internal parameters.  The available parameters are:

	E or e is the _expected_ no. of HSPs to produce (which influences S)
		(default is 10).
	M or m is the name of a file containing substitution costs matrix
		(default is "BLOSUM62")
	Y or y is the effective length of the querY sequence for statistical
		significance calculations (default uses the actual query length)
	Z or z is the effective databaZe length for statistical significance
		calculations (default uses the actual database length)
	P or p is the number of processors to utilize when the program
		is compiled to run on a multi-processor computing platform.

Thus a typical command is

	blastp aabank myseq e=0.5 x=25

Literature:

    Karlin & Altschul, "Methods for assessing the statistical significance
        of molecular sequence features by using general scoring schemes,"
        Proc. Natl. Acad. Sci. USA 87 (1990) 2264-2268;
    Altschul, Gish, Miller, Myers and Lipman, "Basic local alignment search
        tool," J. Mol. Biol. 214 (1990) in press.

 (Note:  set tabstops every 4 columns for a better appearance).
*/

#define PROG_VERSION	"1.4.7"
#define PROG_DATE	"16-Oct-94"
/*
Version   Date          Modification
------- -------- ----------------------------------------------------
1.4.7	6-10-94	Final copy release of version 1.4
1.4.6	13-6-94 Moved to asn.1 spec 1.7
1.4.5	31-5-94	Fixed bug in overlap fraction in blast function library
1.4.4	1-4-94	Fixed error reporting of Karlin-Altschul calculation failure
1.4.1	19-10-93 Better consistency checks, so made -overlap2 the default
1.3.10	7-7-93	Added -overlap2 option, prompted by Erik Sonnhammer
1.3.9	25-6-93 Finished gapdecayrate -- modified cutoffs()
1.3.8   22-6-93 Fixed bug in consistp.c implementation of R(i,3) -- Phil Green
1.3.7	19-6-93 Expect values correspond now to the P-values reported
1.3.6	9-6-93	Added gapdecayrate suggested by Phil Green
1.3.5   6-5-93  Tweaked DEFAULT_E2 upward to compensate for yesterday's bugfix
1.3.4   5-5-93  Karlin H was assumed to have wrong units in lib/stolen.c
1.3.3   23-4-93   Consistent Poisson P-values to go along with N count
1.3.2   20-11-92  Consistency feature, yields more realistic Poisson N count
1.3.1   18-11-92  Added -filter option for query sequence filtering
1.3.0   16-11-92  Hitlists are pruned at the point where E is not satisfied;
                  S2 is the cutoff for manipulating HSPs, E and S determine
                  where to cutoff hit lists.
1.2.10  26-10-92  Fixed bug in segmented sequence handling
1.2.9   4-9-92    Fixed bug in lib/hsppool.c
1.2.8   25-8-92   DEC Ultrix compatibility
1.2.7   16-6-92   Added several hitlist sorting options
1.2.6   12-6-92   Fixed bug in lambdak() when smaller alphabets are used
1.2.5   31-3-92   Added gap character '-' to the amino acid alphabet
1.2.4   9-3-92    Faster K calculation in karlin()
1.2.3   18-2-92   Switched to new dfa library
1.2.2   6-1-92    Only use unambiguous letters (non-X) when calculating K & L
1.2.1   26-12-91  Improved error reporting; new K & L options
1.2.0   10-1-91   Improved Poisson statistics, sorting of hits
                 (Actually, there is no change to BLASTP other than the
                 report format, but its version is bumped to keep version
                 numbers more closely in sync between all of the programs.
1.1.22   9-25-91   Improved reporting of individual HSP statistics
1.1.21   9-23-91   Improved efficiency in search_aa() and extend_aa().
1.1.20   9-13-91   Changed behavior of parameters V and B.
1.1.19   7-22-91   Default X is calculated using information theory
1.1.18  5-5-91   Created parameter V; support for BLASTDB and BLASTPAM
                 environment variables; use of standard NCBI headers.
1.1.17  3-13-91  Added code to calculate default T when W==3.
1.1.16  2-25-91  Added the "Searching..." progress indicator
1.1.15  2-4-91   Word-wrap sequence descriptions
1.1.14  1-28-91  Display one-line description of each db sequence hit
1.1.13  1-16-91  Fixed another bug in Poisson P-value calculations
1.1.12  1-15-91  Fixed bug in Poisson P-value calculations
1.1.11  1-14-91  Fixed bug in bldaa.c regarding perfect matches
1.1.10 12-11-90  Now using linked lists of HSPs; better sorting of HSPs
1.1.9  12-7-90   Using the improved DFA library code
1.1.8  12-6-90   Moved many statistical calculations into library routines
1.1.7  12-5-90   Added histogram of highest-scoring hit extensions
1.1.6  12-4-90   Fixed hit extension algorithm to halt when score <= 0
1.1.5  11-24-90  When at least one HSP is found involving a given database
                 sequence, it is scanned again with a lower cutoff score.
1.1.4  11-21-90  Corrected the calculation of Poisson P-values.
1.1.3            Renamed *.tab file to *.atb, and *.hed to *.ahd.
1.1.2            Modified the *.tab file to include the dbtype.
1.1.1            Added REFINED_STATS code to modify Poisson P-values.
1.1.0            Added REFINED_STATS code to modify Expect.
*/

#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#include <sys/stat.h>

#define EXTERN
#define USESASN1
#ifndef BLASTP
#define BLASTP
#endif
#include "blastapp.h"
#include "aabet.h"	/* the alphabet */
#include "ntbet.h"
#include "gcode.h"

double	Esave, E2save;
BLAST_Score	Ssave, S2save;

ContxtPtr	ctxp;
ValNode	vn;

BLAST_StrPtr	qsp; /* query string pointer */

BLAST_AlphabetPtr	blastaa;
BLAST_ScoreBlkPtr	sbp;

BLAST_WordFinderPtr	wfp0;
BLAST_WFContextPtr	wfcp;

BLAST_KarlinBlkPtr	kbp;

BLAST_KarlinBlkPtr lambdak PROTO((BLAST_StrPtr, BLAST_ScoreBlkPtr));
static void	dosearch PROTO((Nlm_VoidPtr userp, TaskBlkPtr tp));
static int	print_p PROTO((BLAST_HitListPtr));

Link1Blk citation[] = {{ NULL,
"Altschul, Stephen F., Warren Gish, Webb Miller, Eugene W. Myers, and David J. Lipman (1990).  Basic local alignment search tool.  J. Mol. Biol. 215:403-10."
	}};

int
main(argc, argv)
	int		argc;
	char	**argv;
{
	int		i, nok = 0;
	ValNodePtr	m;

	InitBLAST();

	parse_args(argc, argv);

	banner(&b_out, prog_name, prog_desc, prog_version, prog_rel_date, citation, NULL, susage, qusage);

	std_defaults();

	/* OldBLASTaa alphabet must be used for compatibility with setdb program */
	blastaa = BlastAlphabetFindByName("OldBLASTaa");
	if (blastaa == NULL)
		bfatal(ERR_UNDEF, "AlphabetFindByName failed for OldBLASTaa; %s", BlastErrStr(blast_errno));

	qsp = get_query(argv[2], blastaa, qusage, W, 0);
	if (!NWstart_set)
		NWstart = 1;
	NWstart = MAX(NWstart, 1);
	NWstart = MIN(NWstart, qsp->len);
	if (!NWlen_set)
		NWlen = qsp->len;
	NWlen = MIN(NWlen, qsp->len - NWstart + 1);

	if (seqfilter(filtercmd, qsp->name, qsp->namelen, qsp) != 0)
		bfatal(ERR_UNDEF, "Non-zero return code from sequence filter");

	dbfp = initdb(&b_out, argv[1], susage[0], &dbdesc);

	sys_times(&t1);
	wfp0 = BlastWordFinderNew(TRUE, nmats, blastaa, 1, db_maxlen(dbfp));

	Bio_JobStartAsnWrite(&b_out, 1, "Neighboring", nmats);
	m = M;
	for (nctx = 0; nctx < nmats; ++nctx, Bio_JobProgressAsnWrite(&b_out, nctx, ++nok)) {
		/* read substitution matrix */
		ctxp = &ctx[nctx];
		vn.data.ptrvalue = ctxp;
		ctxp->seq = qsp;
		ctxp->sbp = sbp = get_weights(nctx, m->data.ptrvalue, blastaa, blastaa, altscore);
		m = m->next;

		/*
		It would be more accurate to call lambdak() for every sequence in
		the database, but then the program would run much slower.
		Another suggestion is to call lambdak() before reporting
		the probability of an HSP containing part of a specific database
		sequence.  For the sake of speed, though, lambdak() is called only once.
		*/
		if ((ctxp->kbp = kbp = lambdak(qsp, sbp)) == NULL) {
			if (nmats == 1)
				bfatal(ERR_UNDEF, "Could not calculate Lambda, K and H.");
			warning("Could not calculate Lambda, K and H with matrix %s",
					sbp->name);
			continue;
		}
		if (Meff == 0.)
			Meff = qsp->efflen;

		if (set_context(ctxp, W, 3, 10., 300., Neff) != 0)
			continue;

		wfcp = BlastWordFinderContextNew(wfp0, &vn, qsp, sbp, W, kbp);
		BlastWFContextExtendParamSet(wfcp, -ctxp->X, ctxp->S2);
		if (BlastWFContextNeighborhoodAdd(wfcp, NWstart-1, NWlen, ctxp->T, 0) != 0)
			bfatal(ERR_UNDEF, "NeighborhoodAdd failed:  %s", BlastErrStr(blast_errno));
	}
	Bio_JobDoneAsnWrite(&b_out, nctx, nok);

	if (nok == 0)
		bfatal(ERR_SCORING, "There are no valid contexts in the requested search.");
	/* Altschul JME 1993 shows there are equivalent of 4.6 (~5) PAM matrices */
	if (ctxfactor == 0.) {
		ctxfactor = MIN(context_count(ctx, nctx), 5);
		parm_ensure_double("-ctxfactor", 10, "%#0.3lg", ctxfactor);
	}
	context_expect_set(ctx, nctx);

	if (BlastWordFinderComplete(wfp0) != BLAST_ERR_NONE)
		bfatal(ERR_UNDEF, "WordFinderComplete failed:  %s", BlastErrStr(blast_errno));
	wfp0->wordfinder = BlastWordFinderSelectStats(wfp0);

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

	for (i = 0; i < nmats; ++i) {
		BlastWFSearchStatsSum(&totstats, &ctx[i].wfstats);
	}

	BlastHitListSort(&firsthl, hitlist_cmp_criteria);
	BlastHitListTruncate(&firsthl, VHlim, NULL, NULL);
	get_headers(dbfp, firsthl);

	print_headers(b_out.fp, firsthl, 1.0, FALSE);
	if (showblast < VHlim)
		BlastHitListTruncate(&firsthl, showblast, NULL, NULL);
	print_HSPs(firsthl, 1.0, print_p);

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
	BLAST_StrPtr	dbsp;

	if (tp->id == 0)
		wfp = wfp0;
	else
		wfp = BlastWordFinderDup(wfp0);
	ldbfp = db_link(dbfp);
	tp->userp = wfp;
	wfp->user.choice = 1;
	wfp->user.data.intvalue = tp->id;
	score_hist[tp->id] = ScoreHistDup(shp);

	pdp = BlastHitListPDataNew(100);
	hlp = BlastHitListGet(pdp);
	BlastFilterStack(&searchffp, BlastHSPExtendNoXFltr_L1, 0, NULL);
	BlastFilterStack(&searchffp, hsp_score_fltr, 0, NULL);
	BlastFilterStack(&searchffp, hsp_save_fltr, 0, hlp);
	BlastWordFinderFilterSet(wfp, searchffp);
	dbsp = BlastStrNew(0, blastaa, 1);

	/* For each sequence in the database */
	while (TaskNext(tp) >= 0) {
		if (purge_flag)
			merge_purge(tp);
		db_seek(ldbfp, tp->task_cur + dbrecmin);
		db_get_seq(ldbfp, dbsp);
		hlp->str2.id = dbsp->id;

		/* search the database sequence */
		if (BlastWordFinderSearch(wfp, dbsp) != BLAST_ERR_NONE)
			bfatal(ERR_UNDEF, "WordFinderSearch failed:  %s", BlastErrStr(blast_errno));
		/* Evaluate any HSPs that were found and save them if appropriate */
		process_hits(tp, hlp, Neff);
	}

	ScoreHistAdd(shp, score_hist[tp->id]);
	collate_hits(wfp);

	BlastHitListPut(hlp);
	BlastStrDestruct(dbsp);
	BlastFilterDestruct(&searchffp);
	BlastWordFinderDestruct(wfp);
	db_close(ldbfp);
}

/* ----------------------------  parameter calculations  ---------------------*/

/* Version of lambdak() specifically for a.a. alphabet used by BLASTP */
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
	kbp->sbp = sbp;
	kbp->q_frame = sp->frame;
	kbp->s_frame = 0;

	if (BlastKarlinBlkCalc(kbp, sfp) != BLAST_ERR_NONE) {
		BlastKarlinBlkDestruct(kbp);
		warning("Could not calculate Karlin-Altschul K, Lambda and H parameters with %s matrix.",
			sbp->name);
		kbp = NULL;
		goto Error;
	}

Error:
	BlastResCompDestruct(rcp);
	BlastResFreqDestruct(rfp);
	BlastScoreFreqDestruct(sfp);

	return kbp;
}

static int
print_p(hlp)
	BLAST_HitListPtr	hlp;
{
	FILE	*fp;
	unsigned long	id;
	BLAST_HSPPtr	hp;
	int		i;
	register char	*cp, *cpmax;

	fp = b_out.fp;

	id = hlp->str2.id.data.intvalue;

	db_seek(dbfp, id);
	db_get_seq(dbfp, &hlp->str2);

	cp = hlp->str2.name;
	cpmax = cp + hlp->str2.namelen;
	while (cp < cpmax && !isspace(*cp))
		++cp;
	while (cp < cpmax && isspace(*cp))
		++cp;
	i = cp - hlp->str2.name + 1;
	i = MIN(i, 12);
	if (fp != NULL) {
		putc('\n', fp);
		putc('\n', fp);
		wrap(fp, ">", hlp->str2.name, hlp->str2.namelen, 79, i);
		fprintf(fp, "%*sLength = %s\n", i, "", Ltostr((long)hlp->str2.len,1));
	}

	for (hp = hlp->hp; hp != NULL; hp = hp->next) {
		hp->s_seg.sp = &hlp->str2;
		if (hsp_print(fp, hp, nmats == 1) != 0)
			return 1;
	}
	return 0;
}
