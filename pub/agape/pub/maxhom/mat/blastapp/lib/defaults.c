
#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

int LIBCALL
std_defaults()
{
	alarmprocset();
	
	VHlim = MAX(showblast, V);
	remember_max = VHlim + REMEMBER_EXTRA;

	if (showhist == 0 && VHlim == 0)
		bfatal(ERR_INVAL, "All output is suppressed--no search will be performed");

	if (showhist)
		shp = ScoreHistNew(0.001, E_max,
			(log(E_max / 0.001) / NCBIMATH_LN10 + 1.e-7) * 5);

	BlastHitListCmpCriterionAdd(&hitlist_cmp_criteria, BLAST_HLCMP_EVALUE);
	BlastHitListCmpCriterionAdd(&hitlist_cmp_criteria, BLAST_HLCMP_SCORE);
	ValNodeAddFunction(&hitlist_cmp_criteria, 0, (FnPtr)cmp_hitlists_by_seqid);

	BlastHSPCmpCriterionAdd(&hsp_cmp_criteria, BLAST_HSPCMP_FRAME);
	BlastHSPCmpCriterionAdd(&hsp_cmp_criteria, BLAST_HSPCMP_NORMSCORE);
	BlastHSPCmpCriterionAdd(&hsp_cmp_criteria, BLAST_HSPCMP_EVALUE);
	BlastHSPCmpCriterionAdd(&hsp_cmp_criteria, BLAST_HSPCMP_LENGTH);
	BlastHSPCmpCriterionAdd(&hsp_cmp_criteria, BLAST_HSPCMP_OFFSET);

	if (M == NULL && M_default != NULL) {
		ValNodeCopyStr(&M, 0, M_default);
		nmats = 1;
	}

	if (top == 0 && bottom == 0)
		top = bottom = 1, query_strands = TOP_STRAND | BOTTOM_STRAND;
	if (dbtop == 0 && dbbottom == 0)
		dbtop = dbbottom = 1, db_strands = TOP_STRAND | BOTTOM_STRAND;
	minframe = (top ? 0 : 3);
	maxframe = (bottom ? 6 : 3);

	/* parm_ensure_double("E", 1, NULL, E); */
	parm_ensure_long("V", 1, V);
	parm_ensure_int("B", 1, showblast);

	ValNodeAddInt(&hsp_si, 0, Score_type_score);
	ValNodeAddInt(&hsp_si, 0, Score_type_p_value);
	ValNodeAddInt(&hsp_si, 0, Score_type_e_value);
	if (sump_option) {
		ValNodeAddInt(&hsp_si, 0, Score_type_sum_p);
		ValNodeAddInt(&hsp_si, 0, Score_type_sum_e);
		ValNodeAddInt(&hsp_si, 0, Score_type_sum_n);
	}
	else {
		ValNodeAddInt(&hsp_si, 0, Score_type_poisson_p);
		ValNodeAddInt(&hsp_si, 0, Score_type_poisson_e);
		ValNodeAddInt(&hsp_si, 0, Score_type_poisson_n);
	}

	return 0;
}

int LIBCALL
parm_ensure_flag(opt, minlen)
	CharPtr	opt;
	int	minlen;
{
	ValNodePtr	vnp;
	CharPtr	cp0, cp;

	for (vnp = parmstk; vnp != NULL; vnp = vnp->next) {
		if (str_ncasecmp(vnp->data.ptrvalue, opt, minlen) == 0)
			return 0;
	}

	stkprint(&parmstk, "%s", opt);
	stkprintnl(&parmstk);
	return 0;
}

int LIBCALL
parm_ensure_int(opt, minlen, value)
	CharPtr	opt;
	int	minlen;
	int	value;
{
	ValNodePtr	vnp;
	CharPtr	cp0, cp;

	for (vnp = parmstk; vnp != NULL; vnp = vnp->next) {
		if (minlen < 3) {
			cp = strchr(cp0 = vnp->data.ptrvalue, '=');
			if (cp == NULL)
				continue;
			if (cp - cp0 != minlen)
				continue;
		}
		if (str_ncasecmp(vnp->data.ptrvalue, opt, minlen) == 0)
			return 0;
	}

	stkprint(&parmstk, "%s=%d", opt, value);
	stkprintnl(&parmstk);
	return 0;
}

int LIBCALL
parm_ensure_long(opt, minlen, value)
	CharPtr	opt;
	int	minlen;
	long	value;
{
	ValNodePtr	vnp;
	CharPtr	cp0, cp;

	for (vnp = parmstk; vnp != NULL; vnp = vnp->next) {
		if (minlen < 3) {
			cp = strchr(cp0 = vnp->data.ptrvalue, '=');
			if (cp == NULL)
				continue;
			if (cp - cp0 != minlen)
				continue;
		}
		if (str_ncasecmp(vnp->data.ptrvalue, opt, minlen) == 0)
			return 0;
	}

	stkprint(&parmstk, "%s=%ld", opt, value);
	stkprintnl(&parmstk);
	return 0;
}

int LIBCALL
parm_ensure_double(opt, minlen, format, value)
	CharPtr	opt;
	int	minlen;
	CharPtr	format;
	double	value;
{
	char	fmt[80];
	ValNodePtr	vnp;
	CharPtr	cp0, cp;

	if (format == NULL)
		format = "%lg";
	sprintf(fmt, "%%s=%s", format);
	for (vnp = parmstk; vnp != NULL; vnp = vnp->next) {
		if (minlen < 3) {
			cp = strchr(cp0 = vnp->data.ptrvalue, '=');
			if (cp == NULL)
				continue;
			if (cp - cp0 != minlen)
				continue;
		}
		if (str_ncasecmp(vnp->data.ptrvalue, opt, minlen) == 0)
			return 0;
	}

	stkprint(&parmstk, fmt, opt, value);
	stkprintnl(&parmstk);
	return 0;
}
