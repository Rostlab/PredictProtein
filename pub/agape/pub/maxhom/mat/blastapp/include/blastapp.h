/**************************************************************************
*                                                                         *
*              National Center for Biotechnology Information              *
*       Bldg. 38A, NIH,  8600 Rockville Pike,  Bethesda, MD  20894        *
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

Karlin, Samuel and Stephen F. Altschul (1990).  Methods for assessing
the statistical significance of molecular sequence features by using
general scoring schemes.  Proc. Natl. Acad. Sci. USA 87:2264-2268.

Altschul, Stephen F., Warren Gish, Webb Miller, Eugene W. Myers, and
David J. Lipman (1990).  A basic local alignment search tool.
J. Mol. Biol. 215:403-410.

Gish, Warren and David J. States (1993).  Identification of protein
coding regions by database similarity search.  Nature Genetics 3:266-72.
**************************************************************************/
/* (For a better look, set tabstops every 4 columns) */
#ifndef __BLAST_H__
#define __BLAST_H__
#include <blast.h>
#include <signal.h>
#include <gish.h>

/* EXTERN should be defined in the main program module only */
#ifndef EXTERN
#define EXTERN	extern
#ifndef INITIAL
#define INITIAL(x)
#endif
#else
#ifndef INITIAL
#define INITIAL(x) = x
#endif
#ifndef INIT
#define INIT
#endif
#endif

/* location of substitution matrix (Dayhoff, PAM, BLOSUM, Gonnet) files */
#define BLASTMAT "/usr/ncbi/blast/matrix"
/* location of database files */
#define BLASTDB "/usr/ncbi/blast/db"
/* location of sequence filter programs */
#define BLASTFILTER "/usr/ncbi/blast/filter"
/* location of codon frequency information files */
#define BLASTCDI "/usr/ncbi/blast/cdi"

#ifdef OS_UNIX
/* qsort based on the BSD UNIX version provides 2X faster sorting */
#define hsort qsort
#endif

enum blast_prog_id {
	PROG_ID_UNKNOWN = 0,
	PROG_ID_BLASTP,
	PROG_ID_BLASTN,
	PROG_ID_BLASTX,
	PROG_ID_TBLASTN,
	PROG_ID_TBLASTX,
	PROG_ID_BLAST3,
	PROG_ID_MAX
	};

#define AA_SEQTYPE	BLAST_ALPHATYPE_AMINO_ACID
#define NT_SEQTYPE	BLAST_ALPHATYPE_NUCLEIC_ACID

/* Filename extensions used by the two types of databases (a.a. and nt.) */
#define AA_HEADER_EXT	".ahd"
#define AA_TABLE_EXT	".atb"
#define AA_SEARCHSEQ_EXT	".bsq"
#define NT_HEADER_EXT	".nhd"
#define NT_TABLE_EXT	".ntb"
#define NT_SEARCHSEQ_EXT	".csq"

#ifdef BLASTP
#undef BLASTP
#define BLASTP	1
#define PROG_ID	PROG_ID_BLASTP
#define PROG_NAME	"blastp"
#define PROG_DESC	"compare a protein query sequence to a protein sequence database"
#define QUERY_RAW	BLAST_ALPHATYPE_AMINO_ACID
#define QUERY_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DB_RAW	BLAST_ALPHATYPE_AMINO_ACID
#define DB_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DEFAULT_E_MAX	10000.
#define DEFAULT_E2	0.5
#define DEFAULT_M	"BLOSUM62"
#define DEFAULT_W	3
#define DEFAULT_T	13 /* an empirical value is computed if possible */
#define MATRIX_MAX	BLAST_WORDFINDER_CONTEXT_MAX
#endif
#ifdef BLASTN
#undef BLASTN
#define BLASTN	1
#define PROG_ID	PROG_ID_BLASTN
#define PROG_NAME	"blastn"
#define PROG_DESC	"compare a nucleotide query sequence to a nucleotide sequence database"
#define PROC_MAX	3
#define QUERY_RAW	BLAST_ALPHATYPE_NUCLEIC_ACID
#define QUERY_COOKED	BLAST_ALPHATYPE_NUCLEIC_ACID
#define DB_RAW	BLAST_ALPHATYPE_NUCLEIC_ACID
#define DB_COOKED	BLAST_ALPHATYPE_NUCLEIC_ACID
#define DEFAULT_E_MAX	10000.
#define DEFAULT_E2	0.05
#define DEFAULT_M	NULL
#define DEFAULT_W	11
#define DEFAULT_T	(5*DEFAULT_W)
#define MATRIX_MAX	1
#endif
#ifdef BLASTX
#undef BLASTX
#define BLASTX	1
#define PROG_ID	PROG_ID_BLASTX
#define PROG_NAME	"blastx"
#define PROG_DESC	"compare a translated nucleotide query sequence to a protein sequence database"
#define QUERY_RAW	BLAST_ALPHATYPE_NUCLEIC_ACID
#define QUERY_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DB_RAW	BLAST_ALPHATYPE_AMINO_ACID
#define DB_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DISPLAYGCODES	display_gcodes
#define DEFAULT_E_MAX	10000.
#define DEFAULT_E2	0.25
#define DEFAULT_M	"BLOSUM62"
#define DEFAULT_W	3
#define DEFAULT_T	14 /* an empirical value is computed if possible */
#define MATRIX_MAX	1
#endif
#ifdef TBLASTN
#undef TBLASTN
#define TBLASTN	1
#define PROG_ID	PROG_ID_TBLASTN
#define PROG_NAME	"tblastn"
#define PROG_DESC	"compare a protein query sequence to a translated nucleotide sequence database"
#define QUERY_RAW	BLAST_ALPHATYPE_AMINO_ACID
#define QUERY_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DB_RAW	BLAST_ALPHATYPE_NUCLEIC_ACID
#define DB_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DISPLAYGCODES	display_gcodes
#define DEFAULT_E_MAX	10000.
#define DEFAULT_E2	0.15
#define DEFAULT_M	"BLOSUM62"
#define DEFAULT_W	3
#define DEFAULT_T	13 /* an empirical value is computed if possible */
#define MATRIX_MAX	1
#endif
#ifdef TBLASTX
#undef TBLASTX
#define TBLASTX	1
#define PROG_ID	PROG_ID_TBLASTX
#define PROG_NAME	"tblastx"
#define PROG_DESC	"compare a translated nucleotide query sequence to a translated nucleotide sequence database"
#define QUERY_RAW	BLAST_ALPHATYPE_NUCLEIC_ACID
#define QUERY_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DB_RAW	BLAST_ALPHATYPE_NUCLEIC_ACID
#define DB_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DISPLAYGCODES	display_gcodes
#define DEFAULT_E_MAX	10000.
#define DEFAULT_E2	0.1
#define DEFAULT_M	"BLOSUM62"
#define DEFAULT_W	3
#define DEFAULT_T	15 /* an empirical value is computed if possible */
#define MATRIX_MAX	1
#endif
#ifdef BLAST3
#undef BLAST3
#define BLAST3	1
#define PROG_ID	PROG_ID_BLAST3
#define PROG_NAME	"blast3"
#define QUERY_RAW	BLAST_ALPHATYPE_AMINO_ACID
#define QUERY_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DB_RAW	BLAST_ALPHATYPE_AMINO_ACID
#define DB_COOKED	BLAST_ALPHATYPE_AMINO_ACID
#define DEFAULT_E	1000.	/* Need many insignificant HSPs for 3-way stuff */
#define MATRIX_MAX	1
#endif

#ifndef PROG_ID
#define PROG_ID	PROG_ID_UNKNOWN
#endif
#ifndef PROG_NAME
#define PROG_NAME	NULL
#endif
#ifndef PROG_VERSION
#define PROG_VERSION	"not available"
#endif
#ifndef PROG_DATE
#define PROG_DATE	"not available"
#endif
#ifndef PROG_DESC
#define PROG_DESC	"not available"
#endif

#ifndef PROC_MAX
#define PROC_MAX	THREADS_MAX
#endif


#if QUERY_COOKED == NT_SEQTYPE && DB_COOKED == NT_SEQTYPE
#define WORDSIZE_MIN	1		/* min. length of critical word */
#define WORDSIZE_MAX	20		/* max. length of critical word */
#else
#define WORDSIZE_MIN	1		/* min. length of critical word */
#define WORDSIZE_MAX	12		/* max. length of critical word */
#endif

#ifndef QUERYLEN_MAX
#if QUERY_COOKED == NT_SEQTYPE
#define QUERYLEN_MAX	700000
#else
#define QUERYLEN_MAX	50000
#endif
#endif /* !QUERYLEN_MAX */

/* Define the common default parameters */
#ifndef DEFAULT_E
#define DEFAULT_E	10.		/* default expect for reporting HSPs */
#endif
#ifndef DEFAULT_E_MAX
#define DEFAULT_E_MAX	1000.
#endif
#ifndef DEFAULT_M
#define DEFAULT_M	NULL
#endif
#ifndef MATRIX_MAX
#define MATRIX_MAX	0
#endif
#ifndef QUERY_RAW
#define QUERY_RAW	0
#endif
#ifndef QUERY_COOKED
#define QUERY_COOKED
#endif
#ifndef DB_RAW
#define DB_RAW	0
#endif
#ifndef DB_COOKED
#define DB_COOKED	0
#endif
#ifndef DISPLAYGCODES
#define DISPLAYGCODES	NULL
#endif
#ifndef DEFAULT_E2
#define DEFAULT_E2	0.25
#endif
#ifndef DEFAULT_W
#define DEFAULT_W	3
#endif
#ifndef DEFAULT_V
#define DEFAULT_V	500
#endif
#ifndef DEFAULT_C
#define DEFAULT_C	BLAST_GCODE_DEFAULT	/* default genetic code is Standard */
#endif
#ifndef REMEMBER_EXTRA
/* max. no. of extra db sequences to remember above what will be reported */
#define REMEMBER_EXTRA	200
#endif
#ifndef HSP_MAX
/* max. no. of HSPs to save per database sequence */
#define HSP_MAX	100
#endif
#ifndef DEFAULT_showhist
#define DEFAULT_showhist	0
#endif
#ifndef DEFAULT_showblast
#define DEFAULT_showblast	250
#endif

#define NTICKS	50 /* Max. number of ticks to show in the search progress */

#define PLURAL(i)	((i) == 1 ? "" : "s")

#include "error.h"
#include "alphabet.h"

#define _DFA_PRIVATE_
#include <dfa.h>

enum score_type {
	SCORET_UNDEFINED = 0,
	SCORET_EXPECT = 1,
	SCORET_PVALUE = 2
	};

typedef unsigned char	PACK_TYPE;	/* Compressed nuc. sequence datatype */

typedef struct {
		Boolean	valid;
		BLAST_StrPtr	seq;
		int		stdframe;	/* standard frame number (+3, +2, +1, -1, -2, -3) */
		int		W;
		BLAST_Score
				S2,			/* cutoff score for this context */
				S,			/* equiv. HSP cutoff for this reading context */
				X,			/* drop-off score for this reading frame */
				T,
				maxscore,	/* maximum achievable score */
				highs_exp;	/* expected high score */
		double	E, E2;
		BLAST_ScoreBlkPtr	sbp;
		BLAST_KarlinBlkPtr	kbp;
		BLAST_WFSearchStats	wfstats;
	} Contxt, PNTR ContxtPtr;

#ifdef MPROC_AVAIL
	/* Multiprocessing context, one for each processor */
typedef struct mpcontext {
		int		id;	/* task id number */
		long
				realHSP,
				hasHSP,
				totHSP;
		BLAST_HitListPtr	firsthl;
	} MPContext, *MPContextPtr;
#define MP	mp
#define MPC	mp,
#define MPPROTO	MPContextPtr
#define MPPROTOC	MPContextPtr,
#define MPDEF	MPContextPtr	mp;
#define MPPTR	mp->
#define MPINIT(n)	{mp = &mpc[(n)];mp->id = n;}
#else /* !MPROC_AVAIL */
/* Dummy definitions when multiprocessing is not used */
#define MP
#define MPC
#define MPPROTO
#define MPPROTOC
#define MPDEF
#define MPPTR
#define MPINIT(n)
#endif /* !MPROC_AVAIL */

#ifdef BLAST3
struct record {
		BLAST_Score	score;
		BLAST_Score	scor3;
		unsigned long	seq2;
		unsigned long	seq3;
		long	start1;
		long	dg2;
		long	dg3;
		long	length;
	};
#define RECORD_MAX	40000
#endif


typedef struct {
	int		id;/* genetic code identifiers selected from NCBI Toolbox domain */
	CharPtr	name; /* visible name for this code */
	CharPtr	code; /* the genetic code itself */
	CharPtr	inits; /* potential initiator methionines */
	} GenCode, PNTR GenCodePtr;

typedef struct score_hist {
	unsigned long	PNTR hist;
	unsigned long	below, above;
	int	dim; /* dimension of *hist (0...dim-1) */
	double	minval, maxval, base, incr;
	} ScoreHist, PNTR ScoreHistPtr;

typedef enum {
	ALTSCORE_SPECIFIC = 0, /* specific value provided in "altscore" element */
	ALTSCORE_MIN = 1, /* minium of any value observed in the matrix */
	ALTSCORE_MAX, /* maximum of any value observed in the matrix */
	ALTSCORE_NA /* juxtaposition of residue(s) not allowed */
	} AltScoreClass, PNTR AltScoreClassPtr;

typedef struct altscores {
	Boolean		c1any, c2any;
	BLAST_Letter	c1, c2;
	AltScoreClass	class;
	BLAST_Score	altscore;
	} AltScore, PNTR AltScorePtr;

#define TOP_STRAND	1
#define BOTTOM_STRAND	2

#include "blastasn.h"
#include "dbase.h"

void LIBCALL	usage PROTO((void));
void LIBCALL	busage VPROTO((enum blast_error err, char *format, ...));
int LIBCALL	parse_args PROTO((int argc, CharPtr PNTR argv));
void	banner PROTO((BlastIoPtr boutp, CharPtr progname, CharPtr desc, CharPtr version, CharPtr rel_date, Link1BlkPtr citation, Link1BlkPtr notice, int PNTR susage, int PNTR qusage));
int LIBCALL std_defaults PROTO((void));
int LIBCALL parm_ensure_flag PROTO((CharPtr opt, int minlen));
int LIBCALL parm_ensure_int PROTO((CharPtr opt, int minlen, int value));
int LIBCALL parm_ensure_long PROTO((CharPtr opt, int minlen, long value));
int LIBCALL parm_ensure_double PROTO((CharPtr opt, int minlen, CharPtr format, double value));
BLAST_StrPtr	get_query PROTO((CharPtr filename, BLAST_AlphabetPtr ap, int sequsage[2], unsigned W, int strands));
void	query_ack PROTO((BLAST_StrPtr sp, int strands));

BLAST_ScoreBlkPtr get_weights PROTO((int matid, CharPtr mname, BLAST_AlphabetPtr ap1, BLAST_AlphabetPtr ap2, ValNodePtr altscores));
int LIBCALL apply_altscores PROTO((BLAST_ScoreBlkPtr sbp, ValNodePtr altscores));
double LIBCALL context_count PROTO((ContxtPtr ctxp, int nctx));
int LIBCALL set_context PROTO((ContxtPtr ctxp, int W, int sensitivity, double Xbits, double avglen, double dblen));
int LIBCALL context_expect_set PROTO((ContxtPtr ctxp, int nctx));
int LIBCALL adjust_kablks PROTO((ContxtPtr ctx0, int nctx, ContxtPtr stdctx));
int LIBCALL stk_context_parms PROTO((ValNodePtr PNTR stp, ContxtPtr ctxp0, int nctx, ContxtPtr stdctxp));

GenCodePtr	find_gcode PROTO((int id));
int LIBCALL display_gcodes PROTO((FILE *fp));
void init_gcode PROTO((GenCodePtr, unsigned char [64], unsigned char [64]));
BLAST_Letter	codon2aa PROTO((UcharPtr,BLAST_Letter,BLAST_Letter,BLAST_Letter));

void	sort_HSPs PROTO((BLAST_HitListPtr));
void	sort_hitlists_by_seqid PROTO((void));

DBFilePtr LIBCALL	initdb PROTO((BlastIoPtr biop, CharPtr dbname, int restype, BSRV_DbDescPtr ddp));
int LIBCALL get_seq_from_fasta PROTO((CharPtr buf, BLAST_Coord start, unsigned long len, FILE *fp, off_t offset, int line_len));
int LIBCALL get_seq_from_fasta_xl PROTO((BLAST_LetterPtr buf, BLAST_Coord start, size_t len, FILE *fp, off_t offset, int line_len, BLAST_AlphabetPtr ap));
int LIBCALL get_seq_from_cseq PROTO((BLAST_LetterPtr buf, BLAST_Coord start, unsigned long len, MFILE *mfp, unsigned char *c_seq0, off_t offset));
int LIBCALL get_seq_from_cseq_xl PROTO((CharPtr buf, BLAST_Coord start, unsigned long len, MFILE *mfp, unsigned char *c_seq0, off_t offset, CharPtr xltab));

void	get_headers PROTO((DBFilePtr dbfp, BLAST_HitListPtr hlp));
int		print_headers PROTO((FILE *fp, BLAST_HitListPtr hlp, double maxpval, int hasframe));
int LIBCALL	dbtag_id PROTO((CharPtr fastaId));

int		wrap PROTO((FILE *fp, char *pref, char *s, int slen, int linelen, int margin));

int		print_HSPs PROTO((BLAST_HitListPtr hlp, double maxpval, int (*)()));

void	eval_hits PROTO((BLAST_HitListPtr, double));
void	process_hits PROTO((TaskBlkPtr, BLAST_HitListPtr, double));
BLAST_Score	fmaxscore PROTO((BLAST_StrPtr sp, BLAST_Coord start, BLAST_Coord len, BLAST_ScoreBlkPtr sbp));
void	pcnt PROTO((BLAST_HitListPtr));
void	pvals PROTO((BLAST_HitListPtr hlp, unsigned long qlen, unsigned long tlen, unsigned long dblen));

int		get_fasta PROTO((BLAST_StrPtr, BLAST_AlphabetPtr, FILE *, int noisy, int qres_option));
int		put_fasta PROTO((BLAST_StrPtr, FILE *));

int		seqfilter PROTO((CharPtr cmd, CharPtr name, size_t namelen, BLAST_StrPtr sp));
CharPtr _cdecl	pick_filter PROTO((CharPtr cmdstring, BLAST_AlphaType restype));

int LIBCALL format_parms PROTO((ValNodePtr PNTR));
int LIBCALL format_stats PROTO((ValNodePtr PNTR));

int LIBCALL	print_stack PROTO((BlastIoPtr, CharPtr cp, ValNodePtr stk));
void LIBCALL	stkprint VPROTO((ValNodePtr PNTR stk, char *format, ...));
int		hsp_asnout PROTO((AsnIoPtr aip, BLAST_HSPPtr hp, BLAST_ScoreBlkPtr));
int		hsp_print PROTO((FILE *fp, BLAST_HSPPtr hp, int compat));
long	nox_coord PROTO((unsigned long seqlen, int frame, unsigned long off));
long	nt_coord PROTO((unsigned long seqlen, int frame, unsigned long off));
long	apo_to_nt1 PROTO((unsigned long ntlen, int frame, unsigned long aaoff));
long	apo_to_nt3 PROTO((unsigned long ntlen, int frame, unsigned long aaoff));
CharPtr	str_frame PROTO((int frame));
CharPtr	str_strand PROTO((int frame));

void	sort_hitlists PROTO((BLAST_HitListPtr PNTR first, int (*)()));

void	print_hist PROTO((BLAST_Score score_hist_dim, unsigned long *score_hist,
							BLAST_Score S, BLAST_Score T,
							BLAST_KarlinBlkPtr kbp,
							double qlen, double dblen, unsigned long nbr_seqs));

size_t	hsp_count PROTO((BLAST_HitListPtr hlp));
size_t	hitlist_count PROTO((BLAST_HitListPtr hlp));
void		hitlist_truncate PROTO((BLAST_HitListPtr PNTR hlpp, unsigned cnt));
void		hitlist_save PROTO((BLAST_HLPoolPtr pbp, BLAST_HitListPtr PNTR head, BLAST_HitListPtr hlp));


EXTERN int	(*spanfunc) PROTO((BLAST_HSPPtr hp1, BLAST_HSPPtr hp2)) INITIAL(span2);

EXTERN CharPtr	overlap_option;
EXTERN Boolean	gi_option;
EXTERN Boolean	qtype_option;
EXTERN Boolean	qres_option;
#ifndef IDLEN_MAX
#define IDLEN_MAX	25
#endif
EXTERN int	idlen_max INITIAL(IDLEN_MAX);

EXTERN Contxt	ctx[BLAST_WORDFINDER_CONTEXT_MAX];
EXTERN int	nctx;
EXTERN double	ctxfactor;
EXTERN Boolean	ctxfactor_set;

void	hsp_save_default PROTO((MPPROTOC BLAST_HSPPtr hp));	/* General alloc. and save of an HSP */

int LIBCALL	get_dbdesc_bld_date PROTO((BSRV_DbDescPtr ddp, CharPtr fname));
int LIBCALL get_dbdesc_rel_date PROTO((BSRV_DbDescPtr ddp));

int		cmp_hitlists_by_seqid PROTO((BLAST_HitListPtr *, BLAST_HitListPtr *));
int		ckseqtype PROTO((BLAST_StrPtr str));

int		translate PROTO((BLAST_StrPtr nsp, BLAST_StrPtr t1, BLAST_StrPtr t2, BLAST_StrPtr t3, unsigned char gcode[64]));
int		btranslate PROTO((BLAST_StrPtr nsp, BLAST_StrPtr t1, BLAST_StrPtr t2, BLAST_StrPtr t3, unsigned char revgcode[64]));
void	trans2 PROTO((BLAST_LetterPtr nt, BLAST_LetterPtr aa, int len, unsigned char gcode[64]));
void	rtrans2 PROTO((BLAST_LetterPtr nt, BLAST_LetterPtr aa, int len, unsigned char revgcode[64]));
void	trans2b PROTO((BLAST_LetterPtr nt, BLAST_LetterPtr aa, int len, unsigned char gcode[64]));
void	rtrans2b PROTO((BLAST_LetterPtr nt, BLAST_LetterPtr aa, int len, unsigned char gcode[64]));

ScoreHistPtr LIBCALL ScoreHistNew PROTO((double minval, double maxval, unsigned ncols));
ScoreHistPtr LIBCALL ScoreHistDup PROTO((ScoreHistPtr));
void LIBCALL ScoreHistAddPoint PROTO((ScoreHistPtr shp, double value));
int LIBCALL	ScoreHistPrint PROTO((ScoreHistPtr shp, FILE *fp, double real_expect, unsigned long real_observed));
void LIBCALL ScoreHistAdd PROTO((ScoreHistPtr sum, ScoreHistPtr shp));

void	RunWild PROTO((int jobid, char *desc, unsigned long n, void (*func)()));
void	collate_hits PROTO((BLAST_WordFinderPtr));
long	tot_real PROTO((void));
int		merge_purge PROTO((TaskBlkPtr tp));

FILE	*ckopen PROTO((char *fname, char *mode, int die));
VoidPtr	ckalloc PROTO((size_t amt)),	/* storage allocator */
		ckrealloc PROTO((VoidPtr ptr,size_t amt)), /* realloc() */
		ckalloc0 PROTO((size_t amt));	/*   with zero initialization */

void	bfatal VPROTO((enum blast_error blastapp_errno, char *format, ...));
int LIBCALL	fatal_msg PROTO((FILE *fp, char *msg));
void	exit_code PROTO((enum blast_error, CharPtr reason));
void	warning VPROTO((char *format, ...));
void	ckwarnings PROTO((void));
void	SigTerm PROTO((int sig));

enum Dbtag_ids {
	Dbtag_unk = -1,
	Dbtag_notset = 0,
	Dbtag_lcl = 1,
	Dbtag_bbs,
	Dbtag_bbm,
	Dbtag_gim,
	Dbtag_gb,
	Dbtag_emb,
	Dbtag_pir,
	Dbtag_sp,
	Dbtag_pat,
	Dbtag_oth,
	Dbtag_gnl,
	Dbtag_gi,
	Dbtag_dbj,
	Dbtag_prf,
	Dbtag_pdb,
	Dbtag_gp
	};


EXTERN char	*module;	/* Program name */

EXTERN CharPtr	filtercmd INITIAL("");

EXTERN double	gapdecayrate INITIAL(0.5);

EXTERN DBFilePtr	dbfp;

EXTERN BSRV_DbDesc	dbdesc;

/* Non-zero ==> show the hit-extension histogram */
EXTERN int	showhist INITIAL(DEFAULT_showhist);

/* Non-zero ==> show full pairwise alignments */
EXTERN int	showblast INITIAL(DEFAULT_showblast);

EXTERN Nlm_Boolean	echofilter_flag;

EXTERN double	Meff,		/* Effective length of the query sequence */
				Neff;		/* Effective length of the database */
EXTERN unsigned long *header_beg;	/* Start of header line for each db seq */
EXTERN unsigned long nbr_seqs;	/* No. of sequences in database */
				/* First, Last, and Current HitLists */
EXTERN BLAST_HitListPtr	firsthl;
EXTERN BLAST_HitListPtr	cmphl;
EXTERN ScoreHistPtr	shp;	/* histogram of log(expectations) */

EXTERN Boolean
	C_set,
	E_set,
	E2_set,
	S_set,
	S2_set,
	M_set,
	N_set,
	T_set,
	X_set,
	V_set,
	Y_set,
	Z_set,
	W_set
	;

EXTERN int
	W INITIAL(DEFAULT_W), /* word length used in blast algorithm */
	W_max INITIAL(WORDSIZE_MAX),
	C INITIAL(DEFAULT_C), /* genetic code */
	dbgcode INITIAL(DEFAULT_C) /* genetic code for TBLASTX database xlation */
	;

EXTERN BLAST_Score
	S, /* equivalent cutoff score for reporting HSP(s) */
	S2, /* primary cutoff score for saving HSPs */
	X,
	T
	;

EXTERN double
	E INITIAL(DEFAULT_E), /* Expected number of database sequences reported */
	E_max INITIAL(DEFAULT_E_MAX),
	E2 INITIAL(DEFAULT_E2) /* Expected no. of HSPs per avg. sequence comparison */
	;

EXTERN CharPtr
	M_default INITIAL(DEFAULT_M);

EXTERN ValNodePtr	M;
EXTERN int	nmats;
EXTERN int	matrix_max INITIAL(MATRIX_MAX);
EXTERN BLAST_Score	s_reward INITIAL(5), s_penalty INITIAL(-4);
EXTERN ValNodePtr	altscore; /* adjustments to be made to scoring matrix */

EXTERN ValNodePtr	hsp_si; /* score information for HSPs */
EXTERN int	hsp_max INITIAL(HSP_MAX); /* max. no. of HSPs to save per db seq */
EXTERN int	hsp_max_exceeded; /* no. of times hsp_max was exceeded */
EXTERN int	hsp_max_max;

/* max. number of HSPs to report */
EXTERN long		V INITIAL(DEFAULT_V);

EXTERN Boolean
	top INITIAL(TRUE),
	bottom INITIAL(TRUE),
	dbtop INITIAL(TRUE),
	dbbottom INITIAL(TRUE)
	;
EXTERN int	query_strands INITIAL(TOP_STRAND | BOTTOM_STRAND),
			db_strands INITIAL(TOP_STRAND | BOTTOM_STRAND);
EXTERN int	minframe INITIAL(0), maxframe INITIAL(6);


EXTERN PACK_TYPE	*c_seq;	/* Pointer to compressed database sequence */
EXTERN long		numhits;	/* No. of word hits against database */
EXTERN long		totHSP;		/* Total no. of HSPs found against the database */
EXTERN long		hasHSP;		/* No. of db sequences with at least one HSP */
EXTERN long		realHSP;	/* No. of db sequences actually saved */
EXTERN int	VHlim;
EXTERN int	remember_max;
EXTERN int	remember_cut;
EXTERN Boolean	consistency_flag INITIAL(TRUE);
EXTERN Boolean	cdi_flag INITIAL(FALSE);
EXTERN CharPtr	cdi_file; /* codon frequencies filename */
EXTERN Boolean	sump_option INITIAL(TRUE);
EXTERN Boolean	prune_option;
EXTERN Boolean	purge_flag;
EXTERN Boolean	warning_option;
EXTERN int		nprocs;		/* Count of the current number of processes */
EXTERN int		numprocs
#if defined(MPROC_AVAIL) && defined(THREADS_MAX)
	 INITIAL(PROC_MAX)
#endif
	;

#ifdef MPROC_AVAIL
EXTERN MPContext	mpc[THREADS_MAX];
#endif	/* MPROC_AVAIL */

EXTERN BLAST_WFSearchStats
		totstats;

EXTERN ScoreHistPtr	score_hist[THREADS_MAX];

EXTERN ValNodePtr	hitlist_cmp_criteria;
EXTERN ValNodePtr	hsp_cmp_criteria;

EXTERN int (LIBCALLBACK *displaygcodes)() INITIAL(DISPLAYGCODES);

EXTERN double	overlap_fraction INITIAL(0.125);
EXTERN Boolean	overlap_fraction_set INITIAL(FALSE);
EXTERN long	Qlen, Qoffset, Slen, Soffset;
EXTERN long	NWstart, NWlen;
EXTERN Boolean	NWstart_set, NWlen_set;

EXTERN int	prog_id INITIAL(PROG_ID);
EXTERN CharPtr	prog_name INITIAL(PROG_NAME);
EXTERN CharPtr	prog_version INITIAL(PROG_VERSION);
EXTERN CharPtr	prog_desc INITIAL(PROG_DESC);
EXTERN CharPtr	prog_rel_date INITIAL(PROG_DATE);
EXTERN int	qusage[2]
#ifdef INIT
	= { QUERY_RAW, QUERY_COOKED }
#endif
	;
EXTERN int	susage[2]
#ifdef INIT
	= { DB_RAW, DB_COOKED }
#endif
	;


EXTERN ValNodePtr	parmstk, statstk;

EXTERN unsigned long	seqbogus; /* # of db sequences with non-ACGT codes */
EXTERN unsigned long	dfanstates, dfastatesize, dfasize, dfaextent;
EXTERN Cputime_t	t0, t1, t2, t3, t4;

EXTERN long	dbrecmin INITIAL(-1);
EXTERN long	dbrecmax;
EXTERN long	dbreccnt;

EXTERN BlastIo	b_out
#ifdef INIT
	= { stdout, NULL }
#endif
	;

#if defined(__DATE__) && defined(__TIME__)
EXTERN CharPtr
		cc_date INITIAL(__DATE__),
		cc_time INITIAL(__TIME__);
#endif /* defined(__DATE__) && defined(__TIME__) */

#endif /* __BLAST_H__ */
