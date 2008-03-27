#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define USESASN1
#define BLASTASN2
#include "blastapp.h"
#include "gcode.h"

#ifdef BLASTASN2

#ifdef INTRO
#undef INTRO
#endif
#define INTRO(choice)	int retval=1; AsnIoPtr aip; AsnTypePtr atp; DataVal av;\
		if (biop == NULL) return 0; \
		if ((aip = biop->aip) == NULL) return 1; atp = AsnLinkType(orig, BLAST0_RESPONSE);\
		if (atp == NULL) return 1;\
		if (AsnWriteChoice(aip, atp, (Int2)choice, NULL) == 0) goto Error;


AsnTypePtr LIBCALL
Bio_ResponseFindType(choice)
	BSRV_Response	choice;
{
	AsnTypePtr	orig;

	switch (choice) {
	default:
		return NULL;
	case Response_hello:
		orig = BLAST0_RESPONSE_hello; break;
	case Response_motd:
		orig = BLAST0_RESPONSE_motd; break;
	case Response_session_get:
		orig = BLAST0_RESPONSE_session_get; break;
	case Response_session_set:
		orig = BLAST0_RESPONSE_session_set; break;
	case Response_prog_info:
		orig = BLAST0_RESPONSE_prog_info; break;
	case Response_db_info:
		orig = BLAST0_RESPONSE_db_info; break;
	case Response_ack:
		orig = BLAST0_RESPONSE_ack; break;
	case Response_goodbye:
		orig = BLAST0_RESPONSE_goodbye; break;
	case Response_queued:
		orig = BLAST0_RESPONSE_queued; break;
	case Response_preface:
		orig = BLAST0_RESPONSE_preface; break;
	case Response_query:
		orig = BLAST0_RESPONSE_query; break;
	case Response_dbdesc:
		orig = BLAST0_RESPONSE_dbdesc; break;
	case Response_matrix:
		orig = BLAST0_RESPONSE_matrix; break;
	case Response_matrix_e:
		orig = BLAST0_RESPONSE_matrix_E; break;
	case Response_kablk:
		orig = BLAST0_RESPONSE_kablk; break;
	case Response_kablk_e:
		orig = BLAST0_RESPONSE_kablk_E; break;
	case Response_job_start:
		orig = BLAST0_RESPONSE_job_start; break;
	case Response_job_progress:
		orig = BLAST0_RESPONSE_job_progress; break;
	case Response_job_done:
		orig = BLAST0_RESPONSE_job_done; break;
	case Response_result:
		orig = BLAST0_RESPONSE_result; break;
	case Response_parms:
		orig = BLAST0_RESPONSE_parms; break;
	case Response_parms_e:
		orig = BLAST0_RESPONSE_parms_E; break;
	case Response_stats:
		orig = BLAST0_RESPONSE_stats; break;
	case Response_stats_e:
		orig = BLAST0_RESPONSE_stats_E; break;
	case Response_warning:
		orig = BLAST0_RESPONSE_warning; break;
	case Response_status:
		orig = BLAST0_RESPONSE_status; break;
	}
	return orig;
}

AsnTypePtr
Bio_ResponseEnter(biop, choice)
	BlastIoPtr	biop;
	int	choice;
{
	AsnIoPtr	aip;
	AsnTypePtr	atp;

	if (biop == NULL || (aip = biop->aip) == NULL || biop->outblk)
		return NULL;

	atp = Bio_ResponseFindType(choice);
	if (atp != NULL && AsnWriteChoice(aip, BLAST0_RESPONSE, choice, NULL) != 0)
		return atp;
	return NULL;
}

int LIBCALL
Bio_ResponseExit(biop, choice)
	BlastIoPtr	biop;
	int	choice;
{
	AsnIoPtr	aip;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return -1;
	AsnPrintNewLine(aip);
	AsnIoFlush(aip);
	return 0;
}

int
Bio_ResponseHelloAsnWrite(biop, msg)
	BlastIoPtr	biop;
	CharPtr	msg;
{
	AsnTypePtr	atp;
	DataVal	av;

	atp = Bio_ResponseEnter(biop, Response_hello);
	if (atp == NULL)
		return 1;
	av.ptrvalue = msg;
	if (AsnWrite(biop->aip, atp, &av) == 0)
		return 1;
	Bio_ResponseExit(biop, Response_hello);
	return 0;
}

int
Bio_ResponseMotdAsnWrite(biop, fp)
	BlastIoPtr	biop;
	FILE	*fp;
{
	AsnTypePtr	atp;
	AsnIoPtr	aip;

	atp = Bio_ResponseEnter(biop, Response_motd);
	if (atp == NULL)
		return 1;
	if (MotdAsnWrite(biop->aip, atp, fp) != 0)
		return 1;
	Bio_ResponseExit(biop, Response_motd);
	return 0;
}

int
MotdAsnWrite(aip, orig, fp)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	FILE	*fp;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;
	char	buf[256];
	CharPtr	cp;

	if (aip == NULL)
		return 1;
	atp = AsnLinkType(orig, BLAST0_MOTD);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, BLAST0_MOTD, NULL) == 0)
		goto Error;

	if (fp != NULL) {
		av.ptrvalue = buf;
		while (fgets(buf, sizeof buf, fp) != NULL) {
			cp = strchr(buf, '\n');
			if (cp != NULL)
				*cp = NULLB;
			if (AsnWrite(aip, BLAST0_MOTD_E, &av) == 0) {
				goto Error;
			}
		}
	}

	if (AsnCloseStruct(aip, BLAST0_MOTD, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

int LIBCALL
Bio_ResponseAckAsnWrite(biop, code, reason, cpu_used, cpu_remains)
	BlastIoPtr	biop;
	int		code;
	CharPtr	reason;
	int		cpu_used;
	int		cpu_remains;
{
	AsnTypePtr	atp;

	if ((atp = Bio_ResponseEnter(biop, Response_ack)) == NULL)
		return 1;

	if (AckAsnWrite(biop->aip, atp, code, reason, cpu_used, cpu_remains) != 0)
		return 1;

	Bio_ResponseExit(biop, Response_ack);
	return 0;
}

int
Bio_ResponseGoodbyeAsnWrite(biop, code, reason, cpu_used, cpu_remains)
	BlastIoPtr	biop;
	int		code;
	CharPtr	reason;
	int		cpu_used;
	int		cpu_remains;
{
	AsnTypePtr	atp;

	atp = Bio_ResponseEnter(biop, Response_goodbye);
	if (atp == NULL)
		return 1;
	if (AckAsnWrite(biop->aip, atp, code, reason, cpu_used, cpu_remains) != 0)
		return 1;
	Bio_ResponseExit(biop, Response_goodbye);
	return 0;
}

int
AckAsnWrite(aip, orig, code, reason, cpu_used, cpu_remains)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	int		code;
	CharPtr	reason;
	int		cpu_used;
	int		cpu_remains;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_ACK);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;
	av.intvalue = code;
	if (AsnWrite(aip, BLAST0_ACK_code, &av) == 0)
		goto Error;
	if (reason != NULL && *reason != NULLB) {
		av.ptrvalue = reason;
		if (AsnWrite(aip, BLAST0_ACK_reason, &av) == 0)
			goto Error;
	}
	if (cpu_used >= 0) {
		av.intvalue = cpu_used;
		if (AsnWrite(aip, BLAST0_ACK_cpu_used, &av) == 0)
			goto Error;
	}
	if (cpu_remains >= 0) {
		av.intvalue = cpu_remains;
		if (AsnWrite(aip, BLAST0_ACK_cpu_remains, &av) == 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

Bio_SessionSetAsnWrite(biop, orig, spp)
	BlastIoPtr	biop;
	AsnTypePtr	orig;
	BSRV_SessionPtr	spp;
{
	INTRO(BLAST0_RESPONSE_session_set);

	if (SessionAsnWrite(aip, orig, spp) != 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	AsnIoFlush(aip);
	return retval;
}

Bio_SessionGetAsnWrite(biop, orig, spp)
	BlastIoPtr	biop;
	AsnTypePtr	orig;
	BSRV_SessionPtr	spp;
{
	INTRO(BLAST0_RESPONSE_session_get);

	if (SessionAsnWrite(aip, orig, spp) != 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	AsnIoFlush(aip);
	return retval;
}

SessionAsnWrite(aip, orig, spp)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	BSRV_SessionPtr	spp;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_SESSION);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;
	if (spp->priority != Priority_ignore) {
		av.intvalue = spp->priority;
		if (AsnWrite(aip, BLAST0_SESSION_priority, &av) == 0)
			goto Error;
	}
	if (spp->search_max >= 0) {
		av.intvalue = spp->search_max;
		if (AsnWrite(aip, BLAST0_SESSION_search_max, &av) == 0)
			goto Error;
	}
	if (spp->tot_cpu_max >= 0) {
		av.intvalue = spp->tot_cpu_max;
		if (AsnWrite(aip, BLAST0_SESSION_tot_cpu_max, &av) == 0)
			goto Error;
	}
	if (spp->tot_real_max >= 0) {
		av.intvalue = spp->tot_real_max;
		if (AsnWrite(aip, BLAST0_SESSION_tot_real_max, &av) == 0)
			goto Error;
	}
	if (spp->cpu_max >= 0) {
		av.intvalue = spp->cpu_max;
		if (AsnWrite(aip, BLAST0_SESSION_cpu_max, &av) == 0)
			goto Error;
	}
	if (spp->real_max >= 0) {
		av.intvalue = spp->real_max;
		if (AsnWrite(aip, BLAST0_SESSION_real_max, &av) == 0)
			goto Error;
	}
	if (spp->idle_max >= 0) {
		av.intvalue = spp->idle_max;
		if (AsnWrite(aip, BLAST0_SESSION_idle_max, &av) == 0)
			goto Error;
	}
	if (spp->imalive >= 0) {
		av.intvalue = spp->imalive;
		if (AsnWrite(aip, BLAST0_SESSION_imalive, &av) == 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

Bio_ResponseQueuedAsnWrite(biop, orig, queue, length)
	BlastIoPtr	biop;
	AsnTypePtr	orig;
	CharPtr	queue;
	int		length;
{
	INTRO(BLAST0_RESPONSE_queued);

	if (QueuedAsnWrite(aip, orig, queue, length) != 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	AsnIoFlush(aip);
	return retval;
}

QueuedAsnWrite(aip, orig, queue, length)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	CharPtr	queue;
	int		length;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_QUEUED);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;
	av.ptrvalue = queue;
	if (AsnWrite(aip, BLAST0_QUEUED_name, &av) == 0)
		goto Error;
	av.intvalue = length;
	if (AsnWrite(aip, BLAST0_QUEUED_length, &av) == 0)
		goto Error;
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

int
Bio_ResponsePrefaceAsnWrite(biop, orig, program, desc, version, dev_date, bld_date, cit, notice, susage, qusage)
	BlastIoPtr	biop;
	AsnTypePtr	orig;
	CharPtr	program;
	CharPtr	desc;
	CharPtr	dev_date;
	CharPtr	bld_date;
	Link1BlkPtr	cit;
	Link1BlkPtr	notice;
	int		PNTR susage;
	int		PNTR qusage;
{
	INTRO(BLAST0_RESPONSE_preface);
	if (PrefaceAsnWrite(aip, orig, program, desc, version, dev_date, bld_date, cit, notice, susage, qusage) != 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	AsnIoFlush(aip);
	return retval;
}

Bio_ResponseWarningAsnWrite(biop, orig, code, reason)
	BlastIoPtr	biop;
	AsnTypePtr	orig;
	int		code;
	CharPtr	reason;
{
	INTRO(BLAST0_RESPONSE_warning);

	if (WarningAsnWrite(aip, orig, code, reason) != 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	AsnIoFlush(aip);
	return retval;
}

Bio_ResponseResult0AsnWrite(biop, orig)
	BlastIoPtr	biop;
	AsnTypePtr	orig;
{
	INTRO(BLAST0_RESPONSE_result);
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

static int _cdecl dbinfo_cvtwrite PROTO((AsnIoPtr aip, AsnTypePtr stp, AsnTypePtr atp, ValNodePtr vnp));

int _cdecl
DbInfoAsnWrite(AsnIoPtr aip, AsnTypePtr orig, BSRV_DbInfoPtr dip)
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = 1;

	if (aip == NULL)
		return 1;
	atp = AsnLinkType(orig, BLAST0_DB_INFO);
	if (atp == NULL)
		return 1;

	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	if (DbDescAsnWrite(aip, BLAST0_DB_INFO_desc, &dip->desc) != 0)
		goto Error;

	if (ValNodeAsnWrite(aip, BLAST0_DB_INFO_dbtags, BLAST0_DB_INFO_dbtags_E, dip->dbtags) != 0)
		goto Error;

	if (dbinfo_cvtwrite(aip, BLAST0_DB_INFO_divisions, BLAST0_DB_INFO_divisions_E, dip->divisions) != 0)
		goto Error;

	if (dbinfo_cvtwrite(aip, BLAST0_DB_INFO_updatedby, BLAST0_DB_INFO_updatedby_E, dip->updatedby) != 0)
		goto Error;

	if (dbinfo_cvtwrite(aip, BLAST0_DB_INFO_contains, BLAST0_DB_INFO_contains_E, dip->contains) != 0)
		goto Error;

	if (dbinfo_cvtwrite(aip, BLAST0_DB_INFO_derivof, BLAST0_DB_INFO_derivof_E, dip->derivof) != 0)
		goto Error;

	if (ValNodeAsnWrite(aip, BLAST0_DB_INFO_progs, BLAST0_DB_INFO_progs_E, dip->progs) != 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int _cdecl
dbinfo_cvtwrite(AsnIoPtr aip, AsnTypePtr stp, AsnTypePtr atp, ValNodePtr vnp)
{
	BSRV_DbInfoPtr	dip;
	DataVal	av;

	if (aip == NULL || stp == NULL || atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, stp, NULL) == 0)
		return 1;
	while (vnp != NULL) {
		dip = (BSRV_DbInfoPtr)vnp->data.ptrvalue;
		av.ptrvalue = dip->desc.name;
		if (AsnWrite(aip, atp, &av) == 0)
			return 1;
		vnp = vnp->next;
	}
	if (AsnCloseStruct(aip, stp, NULL) == 0)
		return 1;
	return 0;
}

int _cdecl
ValNodeAsnWrite(AsnIoPtr aip, AsnTypePtr stp, AsnTypePtr atp, ValNodePtr vnp)
{
	if (aip == NULL || stp == NULL || atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, stp, NULL) == 0)
		return 1;
	while (vnp != NULL) {
		if (AsnWrite(aip, atp, &vnp->data) == 0)
			return 1;
		vnp = vnp->next;
	}
	if (AsnCloseStruct(aip, stp, NULL) == 0)
		return 1;
	return 0;
}

int _cdecl
Bio_ResponseDbInfoAsnWrite(BlastIoPtr biop, BSRV_DbInfoPtr dip)
{
	AsnIoPtr	aip;
	int	retval = 1;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;

	if (AsnWrite(aip, BLAST0_RESPONSE, NULL) == 0)
		return 1;
	if (AsnOpenStruct(aip, BLAST0_RESPONSE_db_info, NULL) == 0)
		return 1;

	while (dip != NULL) {
		if (DbInfoAsnWrite(aip, BLAST0_RESPONSE_db_info_E, dip) != 0)
			goto Error;
		dip = dip->next;
	}

	if (AsnCloseStruct(aip, BLAST0_RESPONSE_db_info, NULL) == 0)
		return 1;

	retval = 0;

Error:
	AsnPrintNewLine(aip);
	AsnIoFlush(aip);
	return retval;
}
#endif /* BLASTASN2 */
