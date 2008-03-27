#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define USESASN1
#define BLASTASN2
#include "blastapp.h"
#include "gcode.h"

#ifdef BLASTASN2

int LIBCALL
ResponseIgnoreAsnRead(aip, choice)
	AsnIoPtr	aip;
	int	choice;
{
	AsnTypePtr	orig, atp;
	DataVal	av;
	int	retval = -1;

	orig = Bio_ResponseFindType(choice);
	atp = orig;
	while ((atp = AsnReadId(aip, amp, atp)) != NULL && atp != orig) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		AsnKillValue(atp, &av);
	}
	if (AsnReadVal(aip, orig, &av) == 0)
		goto Error;
	retval = 0;

Error:
	return retval;
}

int LIBCALL
ResponseBeginRead(aip, avp)
	AsnIoPtr	aip;
	DataValPtr	avp;
{
	AsnTypePtr	atp;

	if (aip == NULL || atp == NULL)
		return Response_none;

	atp = AsnReadId(aip, amp, BLAST0_RESPONSE);
	if (atp == NULL)
		return Response_none;
	if (AsnReadVal(aip, atp, avp) == 0)
		return Response_none;

	atp = AsnReadId(aip, amp, atp);
	if (atp == NULL)
		return Response_none;

	if (AsnReadVal(aip, atp, avp) == 0)
		return Response_none;

	return AsnType2Response(atp);
}

int LIBCALL
AsnType2Response(atp)
	AsnTypePtr	atp;
{
	if (atp == BLAST0_RESPONSE_hello)
		return Response_hello;
	if (atp == BLAST0_RESPONSE_motd)
		return Response_motd;
	if (atp == BLAST0_RESPONSE_session_get)
		return Response_session_get;
	if (atp == BLAST0_RESPONSE_session_set)
		return Response_session_set;
	if (atp == BLAST0_RESPONSE_prog_info)
		return Response_prog_info;
	if (atp == BLAST0_RESPONSE_db_info)
		return Response_db_info;
	if (atp == BLAST0_RESPONSE_ack)
		return Response_ack;
	if (atp == BLAST0_RESPONSE_goodbye)
		return Response_goodbye;
	if (atp == BLAST0_RESPONSE_queued)
		return Response_queued;
	if (atp == BLAST0_RESPONSE_preface)
		return Response_preface;
	if (atp == BLAST0_RESPONSE_query)
		return Response_query;
	if (atp == BLAST0_RESPONSE_dbdesc)
		return Response_dbdesc;
	if (atp == BLAST0_RESPONSE_matrix)
		return Response_matrix;
	if (atp == BLAST0_RESPONSE_matrix_E)
		return Response_matrix_e;
	if (atp == BLAST0_RESPONSE_kablk)
		return Response_kablk;
	if (atp == BLAST0_RESPONSE_kablk_E)
		return Response_kablk_e;
	if (atp == BLAST0_RESPONSE_job_start)
		return Response_job_start;
	if (atp == BLAST0_RESPONSE_job_progress)
		return Response_job_progress;
	if (atp == BLAST0_RESPONSE_job_done)
		return Response_job_done;
	if (atp == BLAST0_RESPONSE_result)
		return Response_result;
	if (atp == BLAST0_RESPONSE_parms)
		return Response_parms;
	if (atp == BLAST0_RESPONSE_parms_E)
		return Response_parms_e;
	if (atp == BLAST0_RESPONSE_stats)
		return Response_stats;
	if (atp == BLAST0_RESPONSE_stats_E)
		return Response_stats_e;
	if (atp == BLAST0_RESPONSE_warning)
		return Response_warning;
	if (atp == BLAST0_RESPONSE_status)
		return Response_status;
	if (atp == BLAST0_RESPONSE_goodbye)
		return Response_goodbye;
	return Response_none;
}

int LIBCALL
ResponseQueuedAsnRead(aip, qname, qlength)
	AsnIoPtr	aip;
	CharPtr PNTR	qname;
	int	PNTR qlength;
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = -1;

	if (aip == NULL)
		return -1;

	if (AsnReadId(aip, amp, BLAST0_QUEUED_name) == 0)
		goto Error;
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	if (qname != NULL)
		*qname = av.ptrvalue;
	else
		AsnKillValue(BLAST0_QUEUED_name, &av);

	if (AsnReadId(aip, amp, BLAST0_QUEUED_length) == 0)
		goto Error;
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	if (qlength != NULL)
		*qlength = av.intvalue;

	if (AsnReadId(aip, amp, BLAST0_QUEUED) == 0)
		goto Error;
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	retval = 0;

Error:
	return retval;
}

int LIBCALL
ResponseStatsAsnRead(aip, stats)
	AsnIoPtr	aip;
	ValNodePtr	PNTR stats;
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = -1;

	if (stats != NULL)
		*stats = NULL;

	while (AsnReadId(aip, amp, BLAST0_RESPONSE_stats_E) == BLAST0_RESPONSE_stats_E) {
		if (AsnReadVal(aip, BLAST0_RESPONSE_stats_E, &av) == 0)
			goto Error;
		if (stats != NULL)
			ValNodeAddPointer(stats, 0, av.ptrvalue);
		else
			AsnKillValue(BLAST0_RESPONSE_stats_E, &av);
	}

	if (AsnReadVal(aip, BLAST0_RESPONSE_stats, &av) == 0)
		goto Error;

	retval = 0;

Error:
	return retval;
}

#endif /* BLASTASN2 */
