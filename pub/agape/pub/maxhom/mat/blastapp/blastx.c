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
* BLASTX - Search a PROTEIN database for regions that approximately match
* regions of a TRANSLATED NUCLEOTIDE query sequence.  The basic command
* syntax is:
*
* 	BLASTX database query_sequence [parameters] [[top][bottom]]
*
* where:
* 	database names a file containing protein sequences, separated by
* 		header lines beginning with the character '>'.  A typical
* 		sequence entry is:
*
*		>CCHU (PIR) Cytochrome c - Human | 1.0,1.0,1.0,1.0,1.0
*		GDVEKGKKIFIMKCSQCHTVEKGGKHKTGP
*		NLHGLFGRKTGQAPGYSYTAANKNKGIIWG
*		EDTLMEYLENPKKYIPGTKMIFVGIKKKEE
*		RADLIAYLKKATNE
*
* 	query_sequence names a file containing a nucleotide sequence
* 
* The BLASTX command permits optional additional arguments, such as X=50,
* that reset certain internal parameters.  The available parameters are:
*
*	E or e is the expected number of HSPs
*	S or s gives the High-scoring Segment Pair (HSP) cutoff score (default 45)
*	M or m is the name of a file containing substitution costs
*		(default is "BLOSUM62")
*	T or t gives the threshold for a word match (default is usually 12 or 13)
*	X or x gives the value for terminating word extensions (default is about 20)
* Thus a typical command is
*
*	BLASTX AABANK SEQ E=50 M=PAM250
*
*	The "top" and "bottom" options must be specified last on the
*	command line, and direct BLASTX to translate only the top or
*	only the bottom strand, respectively.
*
*   (Note:  set tabstops every 4 columns for a better appearance).
*/

#define PROG_VERSION	"1.4.6"
#define PROG_DATE	"16-Oct-94"
/*
Version	Date		Description
-------	-------		------------------------------------------------------------
1.4.6	6-10-94	Final copy release of version 1.4
1.4.5	13-6-94 Moved to asn.1 spec 1.7
1.4.4	31-5-94	Fixed bug in overlap fraction in blast function library
1.4.3	4-4-94	Fixed error reporting of Karlin-Altschul calculation failure
1.4.1	19-10-93 Better consistency checks, so made -overlap2 the default
1.3.11	23-9-93	Made E2=0.15 the default
1.3.10	7-9-93	Cleaned up some of the E2/S2 usage.
1.3.9	7-7-93	Added -overlap2 option, prompted by Erik Sonnhammer
1.3.8   25-6-93 Finished gapdecayrate -- modified cutoffs()
1.3.7   22-6-93 Fixed bug in consistp.c implementation of R(i,3) -- Phil Green
1.3.6	21-6-93	Fixed bug in consistent N count calculation for (-) strand hits
1.3.5	9-6-93	Added gapdecayrate suggested by Phil Green
1.3.4   5-5-93  Karlin H was assumed to have wrong units in lib/stolen.c
1.3.3   23-4-93 Added consistent Poisson P-value calculation
1.3.2	17-2-93	Added low-cutoff (E2/S2) support
1.3.1   9-2-93	Added codon usage option
1.3.0	20-11-92	Added consistency to Poisson Event counts
1.2.13	17-11-92	Added filter option
1.2.12	4-9-92	Fixed bug in lib/hsppool.c
1.2.11	25-8-92	DEC Ultrix compatibility
1.2.10	18-6-92 Corrected the observed high score reported
1.2.9	16-6-92	Added several hitlist sorting options
1.2.8	12-6-92	Fixed bug in lambdak() when smaller alphabets are used
1.2.7	31-3-92	Added gap character '-' to the amino acid alphabet
1.2.6	9-3-92	Faster K calculation in karlin()
1.2.5	18-2-92	Switched to new dfa library
1.2.4	6-1-92	Only use unambiguous letters (non-X) when calculating K & L
1.2.3	26-12-91	Improved error reporting; new K & L options
1.2.2	23-12-91	Improvement in command line parsing, new -overlap option
1.2.1	23-10-91	Fixed bug in print_parms()
1.2.0	1-10-91		Improved Poisson statistics, screening and sorting of hits
1.1.20	25-9-91		Improved reporting of individual HSP statistics
1.1.19	13-9-91		Changed behavior of parameters V and B.
1.1.18	25-8-91		Fixed bug in extend_x()--diag_top was being updated twice!
                    This would cause data to become corrupted when many word
					hits were obtained, as diag_stack was effectively half the
					size it should have been.
1.1.17	24-8-91		Proper translation of ambiguous nucleotides;
1.1.15	22-7-91		Default X is calculated using information theory
1.1.14	3-12-91		Added calculation of default T for the case when W==3
1.1.13	2-4-91		Word-wrap sequence descriptions
1.1.12	1-28-91		Display one-line description of each db sequence hit
1.1.11	1-16-91		Fixed another bug in Poisson P-value calculation
1.1.10	1-15-91		Fixed bug in Poisson P-value calculation
1.1.9	1-14-91		Fixed bug in bldaa.c regarding perfect match words
1.1.8	12-14-90	Using more common code, new hit lists
1.1.7	12-13-90	Fixed hit extension bugs (improper use of parameter X and
					incorrect rigorous searches)
*/

#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#include <sys/stat.h>

#ifndef BLASTX
#define BLASTX
#endif
#define EXTERN
#define USESASN1
#include "blastapp.h"
#include "aabet.h"	/* the alphabet */
#include "ntbet.h"
#include "gcode.h"

static unsigned char	gcode[64], revgcode[64]; /* translation tables */

double	ccode[64], cfq[64], cbits[64];

ContxtPtr	ctxp;
ValNode	vn;
Contxt		stdctx;

static unsigned long
	*seq_beg; 		/* starts of sequences in file or memory-resident dbase */

BLAST_StrPtr	nsp, nsp_rc;
BLAST_AlphabetPtr	nt4ap, blastaa;
BLAST_ScoreBlkPtr	sbp;
BLAST_KarlinBlkPtr	kbp;
BLAST_WordFinderPtr	wfp0;
BLAST_WFContextPtr	wfcp;
BLAST_FilterPtr		searchffp;

BLAST_StrPtr	revcomp PROTO((BLAST_StrPtr));
BLAST_KarlinBlkPtr	lambdak PROTO((BLAST_StrPtr, BLAST_ScoreBlkPtr));
static void	dosearch PROTO((Nlm_VoidPtr userp, TaskBlkPtr tp));
static int	print_x PROTO((BLAST_HitListPtr));

Link1Blk	citation[] = {
	{ &citation[1],
"Gish, Warren and David J. States (1993).  Identification of protein coding regions by database similarity search.  Nat. Genet. 3:266-72."},
	{ NULL,
"Altschul, Stephen F., Warren Gish, Webb Miller, Eugene W. Myers, and David J. Lipman (1990).  Basic local alignment search tool.  J. Mol. Biol. 215:403-10."}
	};

Link1Blk	notice[] = { { NULL,
"statistical significance is estimated under the assumption that the equivalent of one entire reading frame in the query sequence codes for protein and that significant alignments will involve only coding reading frames."
	} };


int
main(argc, argv)
	int		argc;
	char	**argv;
{
	int	i, j, nok, npos;
	double	x;
	int		frame;

	InitBLAST();

	parse_args(argc, argv);

	banner(&b_out, prog_name, prog_desc, prog_version, prog_rel_date, citation, notice, susage, qusage);

	std_defaults();

	if (cdi_flag)
		get_codonfq(cdi_file, ccode, cfq, cbits);

	init_gcode(find_gcode(C), gcode, revgcode);

	blastaa = BlastAlphabetFindByName("OLDBLASTaa");
	if (blastaa == NULL)
		bfatal(ERR_UNDEF, "AlphabetFindByName failed for OLDBLASTaa:  %s", BlastErrStr(blast_errno));
	nt4ap = BlastAlphabetFindByName("NCBI4na");

	/* read file of substitution weights */
	sbp = get_weights(0, (CharPtr)M->data.ptrvalue, blastaa, blastaa, altscore);

	nsp = get_query(argv[2], nt4ap, qusage, W, query_strands);
	if (!NWstart_set)
		NWstart = 1;
	NWstart = MAX(NWstart, 1);
	NWstart = MIN(NWstart, nsp->len);
	if (!NWlen_set)
		NWlen = nsp->len;
	NWlen = MIN(NWlen, nsp->len - NWstart + 1);
	if (nsp->len < CODON_LEN)
		bfatal(ERR_QUERYLEN, "Query sequence is too short (less than %d residues)", CODON_LEN);
	if (bottom)
		nsp_rc = revcomp(nsp);

	xlat_query();

	dbfp = initdb(&b_out, argv[1], susage[0], &dbdesc);

	if (!Y_set)
		Meff = nsp->len;

	/*
	It might be better to call lambdak() for every sequence in
	the database, but then the program would be much slower.
	Another suggestion is to call lambdak() before reporting
	the probability of an HSP.  But for speed, lambdak() is
	called only once.
	*/
	for (i = nok = 0; i < nctx; ++i) {
		ctxp = &ctx[i];
		ctxp->sbp = sbp;
		kbp = ctxp->kbp = lambdak(ctxp->seq, sbp);
		if (ctxp->kbp == NULL)
			continue;
		++nok;
	}
	if (nok == 0)
		bfatal(ERR_SCORING, "There are no valid contexts in the requested search.");

	adjust_kablks(ctx, nctx, &stdctx);
	for (i = 0; i < nctx; ++i) {
		ctxp = &ctx[i];
		if (ctxp->kbp == NULL)
			continue;
		if (set_context(ctxp, W, 2, 10., 300., Neff) != 0)
			continue;
	}

	if (ctxfactor == 0.) {
		ctxfactor = context_count(ctx, nctx);
		parm_ensure_double("-ctxfactor", 10, "%#0.3lg", ctxfactor);
	}
	context_expect_set(ctx, nctx);

	sys_times(&t1);

	Bio_JobStartAsnWrite(&b_out, 1, "Neighboring", nok);

	wfp0 = BlastWordFinderNew(TRUE, nok, blastaa, 1, db_maxlen(dbfp));

	/* build table of critical (neighborhood) words */
	for (i = npos = 0; i < nctx; ++i) {
		long	ns, nl;

		ctxp = &ctx[i];
		if (!ctxp->valid)
			continue;
		vn.data.ptrvalue = ctxp;
		wfcp = BlastWordFinderContextNew(wfp0, &vn, ctxp->seq, sbp, W, ctxp->kbp);
		BlastWFContextExtendParamSet(wfcp, -ctxp->X, ctxp->S2);
		if (ctxp->stdframe > 0) {
			ns = (NWstart - 1) / CODON_LEN;
			nl = (NWlen - ctxp->stdframe + 1) / CODON_LEN;
		}
		else {
			ns = (nsp->len - NWstart - NWlen + 1) / CODON_LEN;
			nl = (NWlen + ctxp->stdframe + 1) / CODON_LEN;
		}
		if (BlastWFContextNeighborhoodAdd(wfcp, ns, nl, ctxp->T, 0) != 0)
			bfatal(ERR_UNDEF, "NeighborhoodAdd failed:  %s", BlastErrStr(blast_errno));
		Bio_JobProgressAsnWrite(&b_out, i, ++npos);
	}
	if (BlastWordFinderComplete(wfp0) != BLAST_ERR_NONE)
		bfatal(ERR_UNDEF, "WordFinderComplete failed:  %s", BlastErrStr(blast_errno));

	Bio_JobDoneAsnWrite(&b_out, nok, npos);

	wfp0->wordfinder = BlastWordFinderSelectStats(wfp0);
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
	print_HSPs(firsthl, 1.0, print_x);

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

/* print_parms() -- print the parameters */
format_parms(stp)
	ValNodePtr	PNTR stp;
{
	stk_context_parms(stp, &ctx[0], nctx, &stdctx);
	return 0;
}

static int
hsp_score_fltr(BLAST_FilterPtr ffp, BLAST_WFContextPtr wfcp, BLAST_HSPPtr hp)
{
	if (hp->score >= *(BLAST_ScorePtr)ffp->data && ffp->next != NULL)
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
	BLAST_WordFinderPtr wfp;
	BLAST_FilterPtr searchffp = NULL;
	BLAST_HitListPDataPtr	pdp;
	BLAST_HitListPtr	hlp;
	BLAST_StrPtr	dbsp;

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
	int		i, len, f, frame;
	char	name[30];

	for (frame=minframe; frame<3; ++frame) {
		ctxp = &ctx[nctx++];
		f = 2 - frame; /* convert to frame order +3, +2, +1 */
		ctxp->seq = xlat_seq(nsp->str + f, nsp->len - f, gcode);
		if (Y_set)
			ctxp->seq->efflen = Meff / CODON_LEN;
		ctxp->stdframe = f + 1;
		ctxp->seq->frame = ctxp->stdframe;
		ctxp->seq->src = nsp;
		nsp->gcode_id = C;
		sprintf(name, "Frame %+d", ctxp->stdframe);
		i = strlen(name);
		if (seqfilter(filtercmd, name, i, ctxp->seq) != 0)
			bfatal(ERR_UNDEF, "Non-zero return code from sequence filter");
	}
	for (frame=3; frame<maxframe; ++frame) {
		ctxp = &ctx[nctx++];
		ctxp->seq = xlat_seq(nsp_rc->str + frame - 3, nsp->len - frame + 3, gcode);
		if (Y_set)
			ctxp->seq->efflen = Meff / CODON_LEN;
		ctxp->stdframe = 2 - frame;
		ctxp->seq->frame = ctxp->stdframe;
		ctxp->seq->src = nsp_rc;
		nsp_rc->gcode_id = C;
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
		n1 = nt_n4tob[nseq[0]];
		n2 = nt_n4tob[nseq[1]];
		n3 = nt_n4tob[nseq[2]];
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
		warning("Could not calculate Karlin-Altschul K, Lambda and H parameters for frame %+d.",
			sp->frame);
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
print_x(hlp)
	BLAST_HitListPtr	hlp;
{
	FILE	*fp;
	unsigned long	id;
	BLAST_HSPPtr	hp;
	int		i, frame, prevframe;
	register char	*cp, *cpmax;

	fp = b_out.fp;

	id = hlp->str2.id.data.intvalue;

	db_seek(dbfp, id);
	db_get_seq(dbfp, &hlp->str2);

	if (fp != NULL) {
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
	}

	prevframe = 0;
	for (hp = hlp->hp; hp != NULL; hp = hp->next) {
		frame = hp->q_seg.frame;
		if (fp != NULL && SIGN(prevframe) != SIGN(frame)) {
			if (frame > 0)
				fprintf(fp, "\n  Plus");
			else
				fprintf(fp, "\n  Minus");
			fprintf(fp, " Strand HSPs:\n");
		}
		prevframe = frame;

		hp->s_seg.sp = &hlp->str2;
		if (hsp_print(fp, hp, TRUE) != 0)
			return 1;
	}
	return 0;
}
