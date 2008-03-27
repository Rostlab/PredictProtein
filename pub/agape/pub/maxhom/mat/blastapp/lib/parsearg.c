#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

static int LIBCALL tstarg_casecmp PROTO((CharPtr pat,CharPtr opt));
static int LIBCALL tstarg_ncasecmp PROTO((CharPtr pat,CharPtr opt,int minlen));
static int LIBCALL tstarg_int PROTO((CharPtr name, CharPtr desc, CharPtr opt, CharPtr optarg, int PNTR valuep, int minval, int mineq, int maxval, int maxeq));
static int LIBCALL tstarg_long PROTO((CharPtr name, CharPtr desc, CharPtr opt, CharPtr optarg, long PNTR valuep, long minval, int mineq, long maxval, int maxeq));
static int LIBCALL tstarg_double PROTO((CharPtr name, CharPtr desc, CharPtr opt, CharPtr optarg, double PNTR valuep, double minval, int mineq, double maxval, int maxeq));


int LIBCALL
parse_args(argc, argv)
	int	argc;
	char	**argv;
{
	double	x;
	Boolean	secondary;
	int	nargs, nused, ac, optlen, i;
	CharPtr	opt, optarg;
	CharPtr	cp;
	char	o;

	if (argc < 2)
		busage(ERR_INVAL, "Missing database name and query sequence filename arguments.");
	if (argc < 3)
		busage(ERR_INVAL, "Missing query sequence filename.");

	for (ac = 3; ac < argc; (nused > 0 ? ac += nargs : ++ac) ) {
		nused = 0;
		opt = argv[ac];
		opt += (*opt == '-'); /* skip over any leading '-' */

		nargs = 2;
		optarg = NULL;
		if ((cp = strchr(opt, '=')) != NULL) {
			*cp = NULLB;
			optarg = cp + 1;
			if (*optarg != NULLB)
				nargs = 1;
			else
				optarg = NULL;
		}

		if (optarg == NULL && isdigit(opt[1])) {
			optarg = opt + 1;
			nargs = 1;
		}

		if (optarg == NULL && ac+1 < argc) {
			optarg = argv[ac+1];
			nargs = 2;
		}

		optlen = strlen(opt);
		if (tstarg_casecmp("top", opt) == 0) {
			if (qusage[0] == BLAST_ALPHATYPE_AMINO_ACID && susage[0] == BLAST_ALPHATYPE_AMINO_ACID)
				busage(ERR_INVAL, "The \"top\" option is invalid with this program.");
			if (qusage[0] == qusage[1] && susage[0] != susage[1]) {
				opt = "dbtop";
			}
			else {
				bottom = 0;
				query_strands = TOP_STRAND;
				continue;
			}
		}
		if (tstarg_casecmp("bottom", opt) == 0) {
			if (qusage[0] == BLAST_ALPHATYPE_AMINO_ACID && susage[0] == BLAST_ALPHATYPE_AMINO_ACID)
				busage(ERR_INVAL, "The \"bottom\" option is invalid with this program.");
			if (qusage[0] == qusage[1] && susage[0] != susage[1]) {
				opt = "dbbottom";
			}
			else {
				top = 0;
				query_strands = BOTTOM_STRAND;
				continue;
			}
		}
		if (tstarg_casecmp("dbtop", opt) == 0) {
			if (susage[0] == susage[1])
				busage(ERR_INVAL, "The \"dbtop\" option is invalid with this program.");
			dbbottom = 0;
			db_strands = TOP_STRAND;
			continue;
		}
		if (tstarg_casecmp("dbbottom", opt) == 0) {
			if (susage[0] == susage[1])
				busage(ERR_INVAL, "The \"dbbottom\" option is invalid with this program.");
			dbtop = 0;
			db_strands = BOTTOM_STRAND;
			continue;
		}
		if (str_casecmp("altscore", opt) == 0) {
			CharPtr	cp, cp2;
			long	i;
			AltScore	as;

			if (optarg == NULL)
				busage(ERR_INVAL, "Missing argument to the -altscore option.");
			stkprint(&parmstk, "-altscore=%s", optarg);
			stkprintnl(&parmstk);
			nused = 2;

			cp = strtok(optarg, " ,\t\n\r");
			if (cp == NULL)
				busage(ERR_INVAL, "Invalid argument to -altscore option.");
			as.c1any = (str_casecmp("any", cp) == 0);
			as.c1 = *cp;
			cp = strtok(NULL, " ,\t\n\r");
			if (cp == NULL)
				busage(ERR_INVAL, "Invalid argument to -altscore option.");
			as.c2any = (str_casecmp("any", cp) == 0);
			as.c2 = *cp;
			cp = strtok(NULL, " ,\t\n\r");
			if (cp == NULL)
				busage(ERR_INVAL, "Invalid argument to -altscore option.");
			i = 0;
			as.class = ALTSCORE_SPECIFIC;
			if (str_casecmp("na", cp) == 0)
				as.class = ALTSCORE_NA;
			if (str_casecmp("min", cp) == 0)
				as.class = ALTSCORE_MIN;
			if (str_casecmp("max", cp) == 0)
				as.class = ALTSCORE_MAX;
			if (as.class == ALTSCORE_SPECIFIC && sscanf(cp, "%ld", &i) != 1)
				busage(ERR_INVAL, "Invalid argument to -altscore option.");
			i = MAX(i, BLAST_SCORE_MIN / BLAST_WORDSIZE_MAX);
			as.altscore = (BLAST_Score)i;
			if (as.c1any && as.c2any)
				busage(ERR_INVAL, "\"Any\" can not be specified for both letters in an -altscore option.");
			ValNodeAddPointer(&altscore, nmats, MemDup(&as, sizeof as));
			continue;
		}
		if (str_casecmp("overlap2", opt) == 0) {
			opt = "span2";
			warning("The -overlap2 option has been renamed -span2.");
		}
		if (tstarg_casecmp("span2", opt) == 0) {
			spanfunc = span2;
			continue;
		}
		if (str_casecmp("overlap1", opt) == 0) {
			opt = "span1";
			warning("The -overlap1 option has been renamed -span1.");
		}
		if (tstarg_casecmp("span1", opt) == 0) {
			spanfunc = span1;
			continue;
		}
		if (str_casecmp("overlap", opt) == 0) {
			opt = "span";
			warning("The -overlap option has been renamed -span.");
		}
		if (tstarg_ncasecmp("span", opt, 4) == 0) {
			spanfunc = span0;
			continue;
		}
		if (tstarg_casecmp("prune", opt) == 0) {
			prune_option = TRUE;
			continue;
		}
		if (tstarg_casecmp("compat1.3", opt) == 0) {
			sump_option = FALSE;
			spanfunc = span1;
			overlap_fraction = 0.5;
			ctxfactor_set = TRUE;
			ctxfactor = 1.0;
			if (prog_id == PROG_ID_BLASTN)
				W = 12;
			E2 = MIN(E2, 0.15);
			if (prog_id == PROG_ID_BLASTN)
				E2 = 0.;
			if (prog_id == PROG_ID_BLASTX || prog_id == PROG_ID_TBLASTN)
				E = 5.0;
			else
				E = 10.0;
			continue;
		}
		if (tstarg_casecmp("sump", opt) == 0) {
			sump_option = TRUE;
			continue;
		}
		if (tstarg_casecmp("poissonp", opt) == 0) {
			sump_option = FALSE;
			continue;
		}
		if (tstarg_casecmp("outblk", opt) == 0) {
			if (b_out.outblk)
				continue;
			b_out.outblk = TRUE;
			Bio_OutblkOpen(&b_out, NULL);
			continue;
		}
		if (str_ncasecmp("asn1", opt, 4) == 0) {
#ifdef BLASTASN
			if (b_out.fp == NULL)
				continue;
			b_out.fp = NULL;
			if (Bio_Open(&b_out, (opt[4] == 'b' ? ASNIO_BIN_OUT : ASNIO_TEXT_OUT), stdout) != 0)
				exit(1);
			continue;
#else
			busage(ERR_INVAL, "This program was not compiled to produce ASN.1 structured ouput.");
#endif
		}
		if (tstarg_ncasecmp("warnings", opt, 5) == 0) {
			warning_option = TRUE;
			continue;
		}
		if (str_casecmp("filter", opt) == 0) {
			filtercmd = pick_filter(optarg, qusage[1]);
			stkprint(&parmstk, "-filter=%s", optarg);
			stkprintnl(&parmstk);
			nused = 2;
			continue;
		}
		if (str_casecmp("matrix", opt) == 0) {
			nused = 2;
			goto Matrix_option;
		}
		if (tstarg_casecmp("qtype", opt) == 0) {
			qtype_option = TRUE;
			continue;
		}
		if (tstarg_casecmp("qres", opt) == 0) {
			qres_option = TRUE;
			continue;
		}

		if (str_casecmp("dbgcode", opt) == 0) {
			if (qusage[0] != qusage[1] || susage[0] != susage[1])
				goto Usage;
			if (find_gcode(atoi(optarg)) != NULL) {
				dbgcode = atoi(optarg);
				stkprint(&parmstk, "dbgcode=%d (%s genetic code)",
						dbgcode, find_gcode(dbgcode)->name);
				stkprintnl(&parmstk);
				break;
			}
			if (b_out.fp != NULL && displaygcodes != NULL) {
				displaygcodes(b_out.fp);
				exit(1);
			}
			busage(ERR_INVAL, "Invalid genetic code number specified with \"-dbgcode\" option.");
		}

		if (tstarg_ncasecmp("echofilter", opt, 5) == 0) {
			echofilter_flag = TRUE;
			continue;
		}
		if (nused = tstarg_long("qoffset", "the offset to be applied to query sequence numbering", opt, optarg, &Qoffset, LONG_MIN, 0, LONG_MAX, 0))
			continue;
		if (nused = tstarg_long("nwstart", "the starting residue for neighborhood word generation", opt, optarg, &NWstart, 0, 0, LONG_MAX, 0)) {
			NWstart_set = TRUE;
			continue;
		}
		if (nused = tstarg_long("nwlen", "the length of query sequence for which neighborhood words should be generated", opt, optarg, &NWlen, 0, 0, LONG_MAX, 0)) {
			NWlen_set = TRUE;
			continue;
		}
		if (tstarg_ncasecmp("consistency", opt, 7) == 0) {
			consistency_flag = FALSE;
			continue;
		}
		if (tstarg_casecmp("gi", opt) == 0) {
			gi_option = TRUE;
			continue;
		}
		if (nused = tstarg_double("olfraction", "the fractional length of two HSPs that can overlap and still have them be considered consistent with one another", opt, optarg, &x, 0., 1, 1., 1)) {
			overlap_fraction = x;
			continue;
		}
		if (nused = tstarg_double("ctxfactor", "the number of search contexts", opt, optarg, &ctxfactor, 0., 0, 100., 1)) {
			ctxfactor_set = TRUE;
			continue;
		}
		if (nused = tstarg_long("dbrecmin", "the starting record number to be searched in the database", opt, optarg, &dbrecmin, 0, 0, LONG_MAX, 0)) {
			--dbrecmin;
			continue;
		}
		if (nused = tstarg_long("dbrecmax", "the ending record number to be searched in the database", opt, optarg, &dbrecmax, 0, 0, LONG_MAX, 0)) {
			continue;
		}
		if (nused = tstarg_int("hspmax", "the maximum number of HSPs to save per database sequence", opt, optarg, &hsp_max, 1, 1, INT_MAX, 1)) {
			continue;
		}
		if (tstarg_casecmp("sort_by_pvalue", opt) == 0) {
			BlastHitListCmpCriterionAdd(&hitlist_cmp_criteria, BLAST_HLCMP_PVALUE);
			continue;
		}
		if (tstarg_casecmp("sort_by_count", opt) == 0) {
			BlastHitListCmpCriterionAdd(&hitlist_cmp_criteria, BLAST_HLCMP_COUNT);
			continue;
		}
		if (tstarg_casecmp("sort_by_highscore", opt) == 0) {
			BlastHitListCmpCriterionAdd(&hitlist_cmp_criteria, BLAST_HLCMP_HIGHSCORE);
			continue;
		}
		if (tstarg_casecmp("sort_by_totalscore", opt) == 0) {
			BlastHitListCmpCriterionAdd(&hitlist_cmp_criteria, BLAST_HLCMP_TOTALSCORE);
			continue;
		}
		if (nused = tstarg_double("gapdecayrate", "the common ratio of a geometric progression which defines how quickly the p-values for multiple HSPs decay as their numbers increase", opt, optarg, &x, 0., 1, 1., 1)) {
			blast_config->gapdecayrate = x;
			continue;
		}
#if 0
		if (prog_id == PROG_ID_BLASTX && str_casecmp("codoninfo", theArg) == 0) {
			if (optarg == NULL)
				busage(ERR_INVAL, "Missing argument to \"%s\" option", opt);
			cdi_file = optarg;
			cdi_flag = TRUE;
			nused = 2;
			continue;
		}
#endif
		secondary = FALSE;
		if (opt[1] == '2' && optarg != opt + 1) {
			secondary = TRUE;
		}
		else
			if (opt[1] != NULLB && optarg != opt + 1)
				busage(ERR_INVAL, "Argument %d (\"%s\") is not recognized or is improperly formed.", ac, opt);
		o = *opt;
		if (islower(o))
			o = toupper(o);

		if (!secondary)
		switch (o) {
		case 'P':
			tstarg_int("P", "the number of processors to use on a multiple-processor computing platform", NULL, optarg, &numprocs, 1, 1, INT_MAX, 0);
#ifdef MPROC_AVAIL
			if (numprocs > THREADS_MAX)
				warning("%s:  Pmax = %d.", prog_name, THREADS_MAX);
#else
			warning("Parameter P is ignored--this program has not been compiled to use multiprocessing");
#endif
			numprocs = MIN(numprocs, THREADS_MAX);
			break;
		case 'M':
			if (prog_id == PROG_ID_BLASTN) {
				tstarg_long("M", "the reward score for two matching nucleotides", NULL, optarg, &s_reward, 1, 1, BLAST_SCORE_1MAX, 1);
				break;
			}
Matrix_option:
			if (nmats >= matrix_max)
				busage(ERR_INVAL, "Too many -matrix options specified; the limit for this program is %d.",
						matrix_max);
			ValNodeCopyStr(&M, 0, optarg);
			M_set = TRUE;
			++nmats;
			stkprint(&parmstk, "-matrix=%s", optarg);
			stkprintnl(&parmstk);
			break;
		case 'N':
			if (prog_id == PROG_ID_BLASTN) {
				tstarg_long("N", "the penalty score for two mismatching nucleotides", NULL, optarg, &s_penalty, BLAST_SCORE_1MIN, 1, -1, 1);
				break;
			}
			goto Unrecognized;
		case 'E':
			tstarg_double("E", "the statistical significance threshold for reporting database sequences expressed as the number of database sequences that would satisfy merely by chance", NULL, optarg, &E, 0., 0, E_max, 1);
			E_set = TRUE;
			break;
		case 'S':
			tstarg_long("S", "the minimum score for a single HSP to satisfy the significance threshold established by the E parameter", NULL, optarg, &S, 1, 1, 1000000, 1);
			S_set = TRUE;
			break;
		case 'V':
			tstarg_long("V", "the maximum number of database sequences for which one-line descriptions will be reported (regardless of how many database sequence satisfy the expectation threshold E)", NULL, optarg, &V, 0, 1, LONG_MAX, 1);
			V_set = TRUE;
			break;
		case 'B':
			tstarg_int("B", "the maximum number of database sequences for which alignments will be shown (regardless of how many database sequences actually satisfy the expectation threshold E)", NULL, optarg, &showblast, 0, 1, INT_MAX, 1);
			break;
		case 'W':
			tstarg_int("W", "the BLAST neighborhood word length", NULL, optarg, &W, 1, 1, W_max, 1);
			W_set = TRUE;
			break;
		case 'T':
			tstarg_long("T", "the BLAST neighborhood word score threshold", NULL, optarg, &T, 1, 1, BLAST_SCORE_MAX, 1);
			T_set = TRUE;
			break;
		case 'X':
			tstarg_long("X", "the BLAST word-hit extension drop-off score for terminating alignments", NULL, optarg, &X, 1, 1, BLAST_SCORE_MAX, 1);
			X_set = TRUE;
			break;
#if 0
		case 'K':
			tstarg_double("K", "the Karlin-Altschul statistics K parameter", NULL, optarg, &K, 0., 0, 1., 1);
			K_set = TRUE;
			break;
		case 'L':
			tstarg_double("L", "the Karlin-Altschul statistics Lambda parameter", NULL, optarg, &Lambda, 0., 0, 10., 1);
			L_set = TRUE;
			break;
#endif
		case 'Y':
			tstarg_double("Y", "the effective length of the query sequence in statistical significance estimates", NULL, optarg, &Meff, 0., 0, 1.e100, 1);
			Y_set = TRUE;
			break;
		case 'Z':
			tstarg_double("Z", "the effective length of the database in statistical significance estimates", NULL, optarg, &Neff, 1., 1, 1.e100, 1);
			Z_set = TRUE;
			break;
		case 'H':
			tstarg_int("H", "the histogram flag", NULL, optarg, &showhist, 0, 1, 1, 1);
			break;
		case 'C':
			if (qusage[0] == qusage[1] && susage[0] == susage[1])
				goto Usage;
			if (find_gcode(atoi(optarg)) != NULL) {
				C = atoi(optarg);
				stkprint(&parmstk, "C=%d (%s genetic code)",
						C, find_gcode(C)->name);
				stkprintnl(&parmstk);
				break;
			}
			if (qusage[0] == qusage[1])
				dbgcode = C;
			if (b_out.fp != NULL && displaygcodes != NULL) {
				displaygcodes(b_out.fp);
				exit(1);
			}
			busage(ERR_INVAL, "Invalid genetic code number specified with C option.");
		default:
Usage:
			busage(ERR_INVAL, "Invalid program option:  %s", opt);
			/*NOTREACHED*/
		}
		else
		/* Secondary search options */
		switch (o) {
		case 'E':
			tstarg_double("E2", "the expectation threshold for individual HSPs in pairwise sequence comparisons", NULL, optarg, &E2, 0., 1, E_max, 1);
			E2_set = TRUE;
			if (E2 == 0.)
				E2_set = FALSE;
			break;
		case 'S':
			tstarg_long("S2", "the cutoff score used in defining HSPs", NULL, optarg, &S2, 1, 1, BLAST_SCORE_MAX, 1);
			S2_set = TRUE;
			break;
		default:
			goto Usage;
		}
	}

	stkprintnl(&parmstk);
	return 0;

Unrecognized:
	busage(ERR_INVAL, "Argument %d (\"%s\") is not recognized or is improperly formed.", ac, opt);
	/*NOTREACHED */
	return 1;
}

static int LIBCALL
tstarg_casecmp(pat, opt)
	CharPtr	pat;
	CharPtr	opt;
{
	if (str_casecmp(pat, opt) == 0) {
		stkprint(&parmstk, "-%s", pat);
		stkprintnl(&parmstk);
		return 0;
	}
	return 1;
}

static int LIBCALL
tstarg_ncasecmp(pat, opt, minlen)
	CharPtr	pat;
	CharPtr	opt;
	int	minlen;
{
	if (str_ncasecmp(pat, opt, minlen) == 0) {
		stkprint(&parmstk, "-%s", pat);
		stkprintnl(&parmstk);
		return 0;
	}
	return 1;
}

static int LIBCALL
tstarg_int(name, desc, opt, optarg, valuep, minval, mineq, maxval, maxeq)
	CharPtr	name;
	CharPtr	desc; /* description of option */
	CharPtr	opt; /* user-specified option name */
	CharPtr	optarg; /* argument to the option */
	int	*valuep;
	int	minval;
	int	mineq;
	int	maxval;
	int	maxeq;
{
	long	x;

	if (opt != NULL && str_casecmp(name, opt) != 0)
		return 0;

	if (optarg == NULL || *optarg == NULLB)
		bfatal(ERR_INVAL, "Missing argument to %s option, %s.", name, desc);

	if (sscanf(optarg, "%ld", &x) != 1)
		bfatal(ERR_INVAL, "Invalid argument to %s option:  \"%s\".  %s, %s, requires an integral argument in the range %d %s %s %s %d.",
			name, optarg,
			name, desc,
			minval, (mineq ? "<=" : "<"),
			name,
			(maxeq ? "<=" : "<"), maxval
			);

	if (x < minval || (!mineq && x == minval))
		bfatal(ERR_INVAL,"Value specified with %s option is too small:  \"%s\".  The minimum permitted value is %d.",
				name, optarg, minval + (mineq ? 0 : 1));
	if (x > maxval || (!maxeq && x == maxval))
		bfatal(ERR_INVAL,"Value specified with %s option is too large:  \"%s\".  The maximum permitted value is %d.",
				name, optarg, maxval - (maxeq ? 0 : 1));

	stkprint(&parmstk, "%s%s=%s", (int)strlen(name) > 2 ? "-" : "", name, optarg);
	stkprintnl(&parmstk);
	*valuep = (int)x;
	return 2;
}

static int LIBCALL
tstarg_long(name, desc, opt, optarg, valuep, minval, mineq, maxval, maxeq)
	CharPtr	name;
	CharPtr	desc; /* description of option */
	CharPtr	opt; /* user-specified option name */
	CharPtr	optarg; /* argument to the option */
	long	*valuep;
	long	minval;
	int	mineq;
	long	maxval;
	int	maxeq;
{
	long	x;

	if (opt != NULL && str_casecmp(name, opt) != 0)
		return 0;

	if (optarg == NULL || *optarg == NULLB)
		bfatal(ERR_INVAL, "Missing argument to %s option, %s.", name, desc);

	if (sscanf(optarg, "%ld", &x) != 1)
		bfatal(ERR_INVAL, "Invalid argument to %s option:  \"%s\".  %s, %s, requires an integral argument in the range %ld %s %s %s %ld.",
			name, optarg,
			name, desc,
			minval, (mineq ? "<=" : "<"),
			name,
			(maxeq ? "<=" : "<"), maxval
			);

	if (x < minval || (!mineq && x == minval))
		bfatal(ERR_INVAL,"Value specified with %s option is too small:  \"%s\".  The minimum permitted value is %ld.",
				name, optarg, minval + (mineq ? 0 : 1));
	if (x > maxval || (!maxeq && x == maxval))
		bfatal(ERR_INVAL,"Value specified with %s option is too large:  \"%s\".  The maximum permitted value is %ld.",
				name, optarg, maxval - (maxeq ? 0 : 1));

	stkprint(&parmstk, "%s%s=%s", (int)strlen(name) > 2 ? "-" : "", name, optarg);
	stkprintnl(&parmstk);
	*valuep = x;
	return 2;
}

static int LIBCALL
tstarg_double(name, desc, opt, optarg, valuep, minval, mineq, maxval, maxeq)
	CharPtr	name; /* name of option */
	CharPtr	desc; /* description of option */
	CharPtr	opt; /* user-specified option */
	CharPtr	optarg; /* argument to the option */
	double	*valuep;
	double	minval;
	int	mineq;
	double	maxval;
	int	maxeq;
{
	double	x;

	if (opt != NULL && str_casecmp(name, opt) != 0)
		return 0;

	if (optarg == NULL || *optarg == NULLB)
		bfatal(ERR_INVAL, "Missing argument to %s option, %s.", name, desc);

	if (sscanf(optarg, "%lg", &x) != 1)
		bfatal(ERR_INVAL, "Invalid argument to %s option:  \"%s\".  %s, %s, requires a floating point argument in the range %lg %s %s %s %lg.",
			name, optarg,
			name, desc,
			minval, (mineq ? "<=" : "<"),
			name,
			(maxeq ? "<=" : "<"), maxval
			);

	if (x < minval || (!mineq && x == minval))
		bfatal(ERR_INVAL,"Value specified with %s option is too small:  \"%s\".  The minimum permitted value is %lg.",
				name, optarg, minval);
	if (x > maxval || (!maxeq && x == maxval))
		bfatal(ERR_INVAL,"Value specified with %s option is too large:  \"%s\".  The maximum permitted value is %lg.",
				name, optarg, maxval);

	stkprint(&parmstk, "%s%s=%s", (int)strlen(name) > 2 ? "-" : "", name, optarg);
	stkprintnl(&parmstk);
	*valuep = x;
	return 2;
}
