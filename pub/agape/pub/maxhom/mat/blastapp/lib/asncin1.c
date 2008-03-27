#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define USESASN1
#define BLASTASN1
#include "blastapp.h"
#include "gcode.h"

#ifdef BLASTASN1

int LIBCALL
PrefaceAsnRead(aip, progname, desc, version, dev_date, bld_date, cit, notice, susage, qusage)
	AsnIoPtr	aip;
	CharPtr	PNTR progname;
	CharPtr	PNTR desc;
	CharPtr	PNTR version;
	CharPtr	PNTR dev_date;
	CharPtr	PNTR bld_date;
	Link1BlkPtr	PNTR cit;
	Link1BlkPtr	PNTR notice;
	int	PNTR susage;
	int	PNTR qusage;
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = -1;

	if (aip == NULL)
		return -1;

	atp = AsnReadId(aip, amp, BLAST0_PREFACE);

	if (atp == BLAST0_PREFACE_program) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		if (progname != NULL)
			*progname = av.ptrvalue;
		else
			AsnKillValue(atp, &av);
		atp = AsnReadId(aip, amp, atp);
	}
	if (atp == BLAST0_PREFACE_desc) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		if (desc != NULL)
			*desc = av.ptrvalue;
		else
			AsnKillValue(atp, &av);
		atp = AsnReadId(aip, amp, atp);
	}
	if (atp == BLAST0_PREFACE_version) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		if (version != NULL)
			*version = av.ptrvalue;
		else
			AsnKillValue(atp, &av);
		atp = AsnReadId(aip, amp, atp);
	}
	if (atp == BLAST0_PREFACE_dev_date) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		if (dev_date != NULL)
			*dev_date = av.ptrvalue;
		else
			AsnKillValue(atp, &av);
		atp = AsnReadId(aip, amp, atp);
	}
	if (atp == BLAST0_PREFACE_bld_date) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		if (bld_date != NULL)
			*bld_date = av.ptrvalue;
		else
			AsnKillValue(atp, &av);
		atp = AsnReadId(aip, amp, atp);
	}
	if (atp == BLAST0_PREFACE_cit) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		if (cit != NULL)
			*cit = NULL;
		while ((atp = AsnReadId(aip, amp, BLAST0_PREFACE_cit_E)) != BLAST0_PREFACE_cit) {
			if (AsnReadVal(aip, atp, &av) == 0)
				goto Error;
			if (cit != NULL)
				*cit = av.ptrvalue;
			else
				AsnKillValue(atp, &av);
		}
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		atp = AsnReadId(aip, amp, atp);
	}
	if (atp == BLAST0_PREFACE_notice) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		if (notice != NULL)
			*notice = NULL;
		while ((atp = AsnReadId(aip, amp, BLAST0_PREFACE_notice_E)) != BLAST0_PREFACE_notice) {
			if (AsnReadVal(aip, atp, &av) == 0)
				goto Error;
			if (notice != NULL)
				*notice = av.ptrvalue;
			else
				AsnKillValue(atp, &av);
		}
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		atp = AsnReadId(aip, amp, atp);
	}

	/* SeqUsageAsnRead */

	if (atp == NULL)
		goto Error;
	retval = 0;

Error:
	return retval;
}

int LIBCALL
StatsAsnRead(aip, stats)
	AsnIoPtr	aip;
	ValNodePtr	PNTR stats;
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = -1;

	if (stats != NULL)
		*stats = NULL;

	while (AsnReadId(aip, amp, BLAST0_OUTBLK_E_stats_E) == BLAST0_OUTBLK_E_stats_E) {
		if (AsnReadVal(aip, BLAST0_OUTBLK_E_stats_E, &av) == 0)
			goto Error;
		if (stats != NULL)
			ValNodeAddPointer(stats, 0, av.ptrvalue);
		else
			AsnKillValue(BLAST0_OUTBLK_E_stats_E, &av);
	}

	if (AsnReadVal(aip, BLAST0_OUTBLK_E_stats, &av) == 0)
		goto Error;

	retval = 0;

Error:
	return retval;
}

#endif /* BLASTASN1 */
