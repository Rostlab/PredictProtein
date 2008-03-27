#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define USESASN1
#define BLASTASN1
#include "blastapp.h"
#include "gcode.h"

#ifdef BLASTASN1

AsnTypePtr LIBCALL	Bio_ResponseEnter PROTO((BlastIoPtr biop, int choice));
AsnTypePtr LIBCALL	Bio_OutblkEnter PROTO((BlastIoPtr biop, int choice));
AsnTypePtr LIBCALL	Bio_ResponseFindType PROTO((BSRV_Response));
AsnTypePtr LIBCALL	Bio_OutblkFindType PROTO((int));

static long asn_coord0 PROTO((BLAST_SegPtr, unsigned long off));
static long asn_coord1 PROTO((BLAST_SegPtr, unsigned long off));

static long asn_coord0 PROTO((BLAST_SegPtr, unsigned long off));
static long asn_coord1 PROTO((BLAST_SegPtr, unsigned long off));

int PrefaceAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, CharPtr progname, CharPtr desc, CharPtr version, CharPtr dev_date, CharPtr bld_date, Link1BlkPtr cit, Link1BlkPtr notice, int PNTR susage, int PNTR qusage));

int WarningAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, int code, CharPtr reason));

int	StatusAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, int exitcode, CharPtr reason));

static int JobDescAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, int jobid, CharPtr desc, unsigned long size));
static int JobProgressAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, unsigned long done, long positives));

int	DbDescAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BSRV_DbDescPtr dp));

static int HistogramAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, ScoreHistPtr shp, double expected, unsigned long observed));
static int HistogramBarAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, double expected, unsigned long observed));
static int ResultAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, ScoreHistPtr shp, double expected, unsigned long observed, int dim, ValNodePtr sids, BLAST_HitListPtr hits));
static int ScoreInfoAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BSRV_ScoreInfoPtr sip));

static int HitListAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BLAST_HitListPtr hits));

int _cdecl QueryAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BSRV_QueryPtr qp, int flags));

static int SequenceAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BLAST_StrPtr sp, int flags));

static int SeqDescAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BLAST_SeqDescPtr sp));

static int SeqidAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BLAST_SeqIdPtr sip));

static int HSPAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BLAST_HSPPtr hp));

static int ScoreAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, int scoretype, int datatype, Nlm_VoidPtr scoreptr));

static int SegmentAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BLAST_SegPtr seg, unsigned long len));

static int IntervalAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BSRV_SeqIntervalPtr sip));

static int SeqDataAsnWrite PROTO((AsnIoPtr aip, AsnTypePtr orig, BLAST_StrPtr sp, size_t offset, size_t len));

static int cvt1 PROTO((BLAST_AlphabetPtr ap, register BLAST_LetterPtr lp, size_t offset, size_t len, BLAST_LetterPtr outbuf));
static int cvt4 PROTO((BLAST_AlphabetPtr ap, register BLAST_LetterPtr lp, size_t offset, size_t len, BLAST_LetterPtr outbuf));


int
BlastIoAsnClose(biop)
	BlastIoPtr	biop;
{
	AsnIoPtr	aip;

	if (biop != NULL && biop->aip != NULL) {
		aip = biop->aip;
		biop->aip = NULL;
		return (int)AsnIoClose(aip);
	}
	return 0;
}

int
Bio_Open(biop, t, stream)
	BlastIoPtr	biop;
	int		t;
	FILE	*stream;
{
	if (biop->aip == NULL) {
		biop->aip = AsnIoNew(t, stream, NULL, NULL, NULL);
		if (biop->aip == NULL)
				return 1;
	}
	if (biop->outblk)
		return Bio_OutblkOpen(biop, NULL);
	return 0;
}

int
Bio_Close(biop)
	BlastIoPtr	biop;
{
	if (biop->aip == NULL)
		return 0;
	if (biop->outblk)
		Bio_OutblkClose(biop);
	AsnIoClose(biop->aip);
	biop->aip = NULL;
	biop->orig = biop->atp = NULL;
	return 0;
}

int
Bio_OutblkOpen(biop, orig)
	BlastIoPtr	biop;
	AsnTypePtr	orig;
{
	AsnTypePtr	atp;
	AsnIoPtr	aip;

	if (biop == NULL || (aip = biop->aip) == NULL || !biop->outblk)
		return 0;

	atp = AsnLinkType(orig, BLAST0_OUTBLK);
	if (atp == NULL)
		return 1;

	if (AsnOpenStruct(aip, atp, NULL) == 0)
		return 1;

	biop->orig = orig;
	biop->atp = atp;
	return 0;
}

AsnTypePtr
Bio_FindType(biop, choice)
	BlastIoPtr	biop;
	int		choice;
{
	AsnTypePtr	orig;

	if (biop == NULL || biop->aip == NULL)
		return NULL;
	if (!biop->outblk)
		return Bio_ResponseFindType(choice);
	return Bio_OutblkFindType(choice);
}

AsnTypePtr
Bio_OutblkFindType(choice)
	int	choice;
{
	AsnTypePtr	atp;

	switch (choice) {
	default:
	case Response_hello:
	case Response_motd:
	case Response_session_get:
	case Response_session_set:
	case Response_db_info:
	case Response_ack:
	case Response_goodbye:
	case Response_queued:
		return NULL;
	case Response_preface:
		atp = BLAST0_OUTBLK_E_preface; break;
	case Response_query:
		atp = BLAST0_OUTBLK_E_query; break;
	case Response_dbdesc:
		atp = BLAST0_OUTBLK_E_dbdesc; break;
	case Response_matrix:
		atp = BLAST0_OUTBLK_E_matrix; break;
	case Response_matrix_e:
		atp = BLAST0_OUTBLK_E_matrix_E; break;
	case Response_kablk:
		atp = BLAST0_OUTBLK_E_kablk; break;
	case Response_kablk_e:
		atp = BLAST0_OUTBLK_E_kablk_E; break;
	case Response_job_start:
		atp = BLAST0_OUTBLK_E_job_start; break;
	case Response_job_progress:
		atp = BLAST0_OUTBLK_E_job_progress; break;
	case Response_job_done:
		atp = BLAST0_OUTBLK_E_job_done; break;
	case Response_result:
		atp = BLAST0_OUTBLK_E_result; break;
	case Response_parms:
		atp = BLAST0_OUTBLK_E_parms; break;
	case Response_parms_e:
		atp = BLAST0_OUTBLK_E_parms_E; break;
	case Response_stats:
		atp = BLAST0_OUTBLK_E_stats; break;
	case Response_stats_e:
		atp = BLAST0_OUTBLK_E_stats_E; break;
	case Response_warning:
		atp = BLAST0_OUTBLK_E_warning; break;
	case Response_status:
		atp = BLAST0_OUTBLK_E_status; break;
	}
	return atp;
}

AsnTypePtr
Bio_Enter(biop, choice)
	BlastIoPtr	biop;
	int		choice;
{
	AsnTypePtr	orig;

	if (biop == NULL || biop->aip == NULL)
		return NULL;
	if (!biop->outblk)
		return Bio_ResponseEnter(biop, choice);
	return Bio_OutblkEnter(biop, choice);
}

AsnTypePtr
Bio_OutblkEnter(biop, choice)
	BlastIoPtr	biop;
	int		choice;
{
	AsnTypePtr	atp;

	if (biop == NULL || biop->aip == NULL || !biop->outblk)
		return NULL;

	atp = Bio_OutblkFindType(choice);
	if (atp != NULL && AsnWriteChoice(biop->aip, BLAST0_OUTBLK_E, choice, NULL) != 0)
		return atp;
	return NULL;
}

int
Bio_Exit(biop, choice)
	BlastIoPtr	biop;
	int		choice;
{
	if (biop == NULL || biop->aip == NULL)
		return;
	AsnPrintNewLine(biop->aip);
	AsnIoFlush(biop->aip);
	return;
}

int
Bio_OutblkClose(biop)
	BlastIoPtr	biop;
{
	AsnIoPtr	aip;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;
	if (AsnCloseStruct(aip, biop->atp, NULL) == 0)
		return 1;
	AsnUnlinkType(biop->orig);
	AsnPrintNewLine(aip);
	AsnIoFlush(aip);
	return 0;
}

int
Bio_PrefaceAsnWrite(biop, progname, desc, version, dev_date, bld_date, cit, notice, susage, qusage)
	BlastIoPtr	biop;
	CharPtr	progname, desc, version, dev_date, bld_date;
	Link1BlkPtr	cit, notice;
	int		PNTR susage, PNTR qusage;
{
	AsnIoPtr	aip;
	AsnTypePtr	orig;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;

	orig = Bio_Enter(biop, Response_preface);

	if (PrefaceAsnWrite(aip, orig,
			progname, desc, version, dev_date, bld_date, cit, notice,
			susage, qusage) != 0)
		return 1;

	Bio_Exit(biop, Response_preface);
	return 0;
}

int
PrefaceAsnWrite(aip, orig, progname, desc, version, dev_date, bld_date, cit, notice, susage, qusage)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	CharPtr	progname;
	CharPtr	desc;
	CharPtr	version;
	CharPtr	dev_date, bld_date;
	Link1BlkPtr	cit;
	Link1BlkPtr	notice;
	int		PNTR susage;
	int		PNTR qusage;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_PREFACE);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.ptrvalue = progname;
	if (AsnWrite(aip, BLAST0_PREFACE_program, &av) == 0)
		goto Error;

	if (desc != NULL) {
		av.ptrvalue = desc;
		if (AsnWrite(aip, BLAST0_PREFACE_desc, &av) == 0)
			goto Error;
	}
	if (version != NULL) {
		av.ptrvalue = version;
		if (AsnWrite(aip, BLAST0_PREFACE_version, &av) == 0)
			goto Error;
	}
	if (dev_date != NULL) {
		av.ptrvalue = dev_date;
		if (AsnWrite(aip, BLAST0_PREFACE_dev_date, &av) == 0)
			goto Error;
	}
	if (bld_date != NULL) {
		av.ptrvalue = bld_date;
		if (AsnWrite(aip, BLAST0_PREFACE_bld_date, &av) == 0)
			goto Error;
	}
	if (cit != NULL) {
		if (AsnOpenStruct(aip, BLAST0_PREFACE_cit, NULL) == 0)
			goto Error;
		do {
			if (cit->cp != NULL) {
				av.ptrvalue = cit->cp;
				if (AsnWrite(aip, BLAST0_PREFACE_cit_E, &av) == 0)
					goto Error;
			}
		} while ((cit = cit->next) != NULL);
		if (AsnCloseStruct(aip, BLAST0_PREFACE_cit, NULL) == 0)
			goto Error;
	}
	if (notice != NULL) {
		if (AsnOpenStruct(aip, BLAST0_PREFACE_notice, NULL) == 0)
			goto Error;
		do {
			if (notice->cp != NULL) {
				av.ptrvalue = notice->cp;
				if (AsnWrite(aip, BLAST0_PREFACE_notice_E, &av) == 0)
					goto Error;
			}
		} while ((notice = notice->next) != NULL);
		if (AsnCloseStruct(aip, BLAST0_PREFACE_notice, NULL) == 0)
			goto Error;
	}
	if (SeqUsageAsnWrite(aip, BLAST0_PREFACE_susage, susage) != 0)
		goto Error;
	if (SeqUsageAsnWrite(aip, BLAST0_PREFACE_qusage, qusage) != 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

int
SeqUsageAsnWrite(aip, orig, usage)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	int		*usage;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 0;
	atp = AsnLinkType(orig, BLAST0_SEQ_USAGE);
	if (atp == NULL)
		return 1;

	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;
	av.intvalue = (usage ? usage[0] : 0);
	if (AsnWrite(aip, BLAST0_SEQ_USAGE_raw, &av) == 0)
		goto Error;
	av.intvalue = (usage ? usage[1] : 0);
	if (AsnWrite(aip, BLAST0_SEQ_USAGE_cooked, &av) == 0)
		goto Error;
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

int
Bio_StatusAsnWrite(biop, code, reason)
	BlastIoPtr	biop;
	int		code;
	CharPtr	reason;
{
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	int		retval;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;

	orig = Bio_Enter(biop, Response_status);

	retval = StatusAsnWrite(aip, orig, code, reason);

	Bio_Exit(biop, Response_status);
	return retval;
}

int
WarningAsnWrite(aip, orig, code, reason)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	int		code;
	CharPtr	reason;
{
	AsnTypePtr	atp;
	int		retval = 1;

	if (aip == NULL)
		return 1;
	if ((atp = AsnLinkType(orig, BLAST0_WARNING)) == NULL)
		return 1;

	if (StatusAsnWrite(aip, atp, code, reason) != 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

int
StatusAsnWrite(aip, orig, exitcode, reason)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	int		exitcode;
	CharPtr	reason;
{
	AsnTypePtr	atp;
	DataVal	av;

	if (aip == NULL)
		return 0;

	atp = AsnLinkType(orig, BLAST0_STATUS);
	if (atp == NULL)
		return 0;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = exitcode;
	if (AsnWrite(aip, BLAST0_STATUS_code, &av) == 0)
		goto Error;
	if (reason != NULL) {
		av.ptrvalue = reason;
		if (AsnWrite(aip, BLAST0_STATUS_reason, &av) == 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	AsnUnlinkType(orig);
	return 0;

Error:
	AsnUnlinkType(orig);
	return 1;
}

int
Bio_WarningAsnWrite(biop, code, reason)
	BlastIoPtr	biop;
	int		code;
	CharPtr	reason;
{
	AsnTypePtr	atp;

	if (biop == NULL || biop->aip == NULL)
		return 0;

	if ((atp = Bio_Enter(biop, Response_warning)) == NULL)
		return 1;

	if (StatusAsnWrite(biop->aip, atp, code, reason) != 0)
		return 1;

	Bio_Exit(biop, Response_warning);
	return 0;
}


int
Bio_JobStartAsnWrite(biop, jobid, desc, size)
	BlastIoPtr	biop;
	int		jobid;
	CharPtr	desc;
	unsigned long	size;
{
	AsnIoPtr	aip;
	AsnTypePtr	orig;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;

	orig = Bio_Enter(biop, Response_job_start);

	if (JobDescAsnWrite(aip, orig, jobid, desc, size) != 0)
		return 1;

	Bio_Exit(biop, Response_job_start);
	return 0;
}

static int
JobDescAsnWrite(aip, orig, jobid, desc, size)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	int		jobid;
	CharPtr	desc;
	unsigned long	size;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 0;

	atp = AsnLinkType(orig, BLAST0_JOB_DESC);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = jobid;
	if (AsnWrite(aip, BLAST0_JOB_DESC_jid, &av) == 0)
		goto Error;
	if (desc == NULL)
		desc = "Nondescript";
	av.ptrvalue = desc;
	if (AsnWrite(aip, BLAST0_JOB_DESC_desc, &av) == 0)
		goto Error;
	av.intvalue = size;
	if (AsnWrite(aip, BLAST0_JOB_DESC_size, &av) == 0)
		goto Error;
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

int
Bio_JobProgressAsnWrite(biop, done, positives)
	BlastIoPtr	biop;
	unsigned long	done;
	long	positives;
{
	AsnIoPtr	aip;
	AsnTypePtr	orig;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;

	orig = Bio_Enter(biop, Response_job_progress);

	if (JobProgressAsnWrite(aip, orig, done, positives) != 0)
		return 1;

	Bio_Exit(biop, Response_job_progress);
	return 0;
}

static int
JobProgressAsnWrite(aip, orig, done, positives)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	unsigned long	done;
	long	positives;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 0;

	atp = AsnLinkType(orig, BLAST0_JOB_PROGRESS);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = done;
	if (AsnWrite(aip, BLAST0_JOB_PROGRESS_done, &av) == 0)
		goto Error;
	if (positives >= 0) {
		av.intvalue = positives;
		if (AsnWrite(aip, BLAST0_JOB_PROGRESS_positives, &av) == 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

int
Bio_JobDoneAsnWrite(biop, done, positives)
	BlastIoPtr	biop;
	unsigned long	done;
	long	positives;
{
	AsnTypePtr	orig;
	AsnIoPtr	aip;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;

	orig = Bio_Enter(biop, Response_job_done);

	if (JobProgressAsnWrite(aip, orig, done, positives) != 0)
		return 1;

	Bio_Exit(biop, Response_job_done);
	return 0;
}

int
Bio_DbDescAsnWrite(biop, ddp)
	BlastIoPtr	biop;
	BSRV_DbDescPtr	ddp;
{
	AsnIoPtr	aip;
	AsnTypePtr	orig;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;

	orig = Bio_Enter(biop, Response_dbdesc);

	if (DbDescAsnWrite(aip, orig, ddp) != 0)
		return 1;

	Bio_Exit(biop, Response_dbdesc);
	return 0;
}

int
DbDescAsnWrite(aip, orig, ddp)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	BSRV_DbDescPtr	ddp;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_DB_DESC);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.ptrvalue = ddp->name;
	if (AsnWrite(aip, BLAST0_DB_DESC_name, &av) == 0)
		goto Error;
	av.intvalue = ddp->type;
	if (AsnWrite(aip, BLAST0_DB_DESC_type, &av) == 0)
		goto Error;

	if (ddp->def != NULL) {
		av.ptrvalue = ddp->def;
		if (AsnWrite(aip, BLAST0_DB_DESC_def, &av) == 0)
			goto Error;
	}
	if (ddp->rel_date != NULL) {
		av.ptrvalue = ddp->rel_date;
		if (AsnWrite(aip, BLAST0_DB_DESC_rel_date, &av) == 0)
			goto Error;
	}
	if (ddp->bld_date != NULL) {
		av.ptrvalue = ddp->bld_date;
		if (AsnWrite(aip, BLAST0_DB_DESC_bld_date, &av) == 0)
			goto Error;
	}
	if (ddp->count >= 0) {
		av.intvalue = ddp->count;
		if (AsnWrite(aip, BLAST0_DB_DESC_count, &av) == 0)
			goto Error;
	}
	if (ddp->totlen >= 0) {
		av.intvalue = ddp->totlen;
		if (AsnWrite(aip, BLAST0_DB_DESC_totlen, &av) == 0)
			goto Error;
	}
	if (ddp->maxlen >= 0) {
		av.intvalue = ddp->maxlen;
		if (AsnWrite(aip, BLAST0_DB_DESC_maxlen, &av) == 0)
			goto Error;
	}

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	return retval;
}

int
Bio_QueryAsnWrite(biop, qp, flags)
	BlastIoPtr	biop;
	BSRV_QueryPtr	qp;
	int	flags;
{
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	int	retval = 1;

	if (biop == NULL || (aip = biop->aip) == NULL || qp == NULL)
		return 1;

	orig = Bio_Enter(biop, Response_query);

	if (QueryAsnWrite(aip, orig, qp, flags) != 0)
		goto Error;

	Bio_Exit(biop, Response_query);
	retval = 0;
Error:
	return retval;
}

int _cdecl
QueryAsnWrite(AsnIoPtr aip, AsnTypePtr orig, BSRV_QueryPtr qp, int flags)
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL || qp == NULL || qp->sp == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_QUERY);
	if (atp == NULL)
		return 1;

	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	if (SequenceAsnWrite(aip, BLAST0_QUERY_seq, qp->sp, flags) != 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

int LIBCALL
Bio_KABlkAsnWrite(biop, ctxp, nctx)
	BlastIoPtr	biop;
	ContxtPtr	ctxp;
	int		nctx;
{
	BLAST_KarlinBlkPtr	kbp;
	ContxtPtr	ctxp0 = ctxp, ctxp2;
	AsnTypePtr	orig, atp, foo();
	AsnIoPtr	aip;
	int		retval = 1;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;
	if (nctx > 0 && ctxp == NULL)
		return 1;

	orig = Bio_Enter(biop, Response_kablk);

	if (AsnOpenStruct(aip, orig, NULL) == 0)
		goto Error;
	atp = Bio_FindType(biop, Response_kablk_e);
	for (; nctx-- > 0; ++ctxp) {
		if ((kbp = ctxp->kbp) == NULL)
			continue;
		/* make sure the same kbp is not output twice */
		for (ctxp2 = ctxp0; ctxp2 < ctxp; ++ctxp2) {
			if (ctxp2->kbp == kbp)
				break;
		}
		if (ctxp2 == ctxp && KABlkAsnWrite(aip, atp, kbp) != 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, orig, NULL) == 0)
		goto Error;

	Bio_Exit(biop, Response_kablk);
	retval = 0;
Error:
	return retval;
}

int
KABlkAsnWrite(aip, orig, kbp)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	BLAST_KarlinBlkPtr	kbp;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL || kbp == NULL)
		return 0;

	atp = AsnLinkType(orig, BLAST0_KA_BLK);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = kbp->sbp->id.data.intvalue;
	if (AsnWrite(aip, BLAST0_KA_BLK_matid, &av) == 0)
		goto Error;
	av.intvalue = 2; /* 2 frames */
	if (AsnWrite(aip, BLAST0_KA_BLK_n_way, &av) == 0)
		goto Error;

	if (AsnOpenStruct(aip, BLAST0_KA_BLK_frames, NULL) == 0)
		goto Error;
	av.intvalue = kbp->q_frame;
	if (AsnWrite(aip, BLAST0_KA_BLK_frames_E, &av) == 0)
		goto Error;
	av.intvalue = kbp->s_frame;
	if (AsnWrite(aip, BLAST0_KA_BLK_frames_E, &av) == 0)
		goto Error;
	if (AsnCloseStruct(aip, BLAST0_KA_BLK_frames, NULL) == 0)
		goto Error;

	av.realvalue = kbp->Lambda;
	if (AsnWrite(aip, BLAST0_KA_BLK_lambda, &av) == 0)
		goto Error;
	av.realvalue = kbp->K;
	if (AsnWrite(aip, BLAST0_KA_BLK_k, &av) == 0)
		goto Error;
	av.realvalue = kbp->H;
	if (AsnWrite(aip, BLAST0_KA_BLK_h, &av) == 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;
Error:
	AsnUnlinkType(orig);
	AsnIoFlush(aip);
	return retval;
}

int LIBCALL
Bio_ScoreBlkAsnWrite(biop, ctxp, nctx, fullreport)
	BlastIoPtr	biop;
	ContxtPtr	ctxp;
	int		nctx;
	int		fullreport;
{
	ContxtPtr	ctxp0 = ctxp, ctxp2;
	BLAST_ScoreBlkPtr	sbp;
	AsnIoPtr	aip;
	AsnTypePtr	atp, atp2;
	int		retval = 1;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;
	if (nctx > 0 && ctxp == NULL)
		return 1;

	atp = Bio_Enter(biop, Response_matrix);
	atp2 = Bio_FindType(biop, Response_matrix_e);
	if (atp == NULL || atp2 == NULL)
		return 1;

	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;
	for (; nctx-- > 0; ++ctxp) {
		if ((sbp = ctxp->sbp) == NULL)
			continue;
		for (ctxp2 = ctxp0; ctxp2 < ctxp; ++ctxp2) {
			if (ctxp2->sbp == sbp)
				break;
		}
		if (ctxp2 == ctxp && MatrixAsnWrite(aip, atp2, sbp, fullreport) != 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;

	retval = 0;
Error:
	Bio_Exit(biop, Response_matrix);
	return retval;
}

int
MatrixAsnWrite(aip, orig, sbp, fullreport)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	BLAST_ScoreBlkPtr	sbp;
	int		fullreport; /* TRUE ==> report comments and scores */
{
	AsnTypePtr	atp;
	DataVal	av;
	BLAST_AlphabetPtr	ap1, ap2, outap1, outap2;
	BLAST_Letter	ch1, ch2;
	BLAST_Score	s;
	BLAST_AlphaMapPtr	map1 = NULL, map2 = NULL;
	static BLAST_AlphabetPtr	ncbistdaa, ncbi4na;
	int		i1, i2;
	ValNodePtr	vnp;
	int		retval = 1;

	if (aip == NULL || sbp == NULL)
		return 1;

	if (ncbistdaa == NULL)
		ncbistdaa = BlastAlphabetFindByName("NCBIstdaa");
	if (ncbi4na == NULL)
		ncbi4na = BlastAlphabetFindByName("NCBI4na");

	atp = AsnLinkType(orig, BLAST0_MATRIX);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = sbp->id.data.intvalue;
	if (AsnWrite(aip, BLAST0_MATRIX_matid, &av) == 0)
		goto Error;
	av.ptrvalue = sbp->name;
	if (AsnWrite(aip, BLAST0_MATRIX_name, &av) == 0)
		goto Error;

	if (fullreport && sbp->comments != NULL) {
		if (AsnOpenStruct(aip, BLAST0_MATRIX_comments, NULL) == 0)
			goto Error;
		for (vnp = sbp->comments; vnp != NULL; vnp = vnp->next) {
			av.ptrvalue = vnp->data.ptrvalue;
			if (AsnWrite(aip, BLAST0_MATRIX_comments_E, &av) == 0)
				goto Error;
		}
		if (AsnCloseStruct(aip, BLAST0_MATRIX_comments, NULL) == 0)
			goto Error;
	}


	ap1 = sbp->a1;
	if (ap1->alphatype == BLAST_ALPHATYPE_AMINO_ACID) {
		av.intvalue = 11;
		outap1 = ncbistdaa;
	}
	else {
		av.intvalue = 4;
		outap1 = ncbi4na;
	}
	if (ap1 != outap1)
		map1 = BlastAlphaMapFindCreate(outap1, ap1);
	if (AsnWrite(aip, BLAST0_MATRIX_qalpha, &av) == 0)
		goto Error;

	ap2 = sbp->a2;
	if (ap2->alphatype == BLAST_ALPHATYPE_AMINO_ACID) {
		av.intvalue = 11;
		outap2 = ncbistdaa;
	}
	else {
		av.intvalue = 4;
		outap2 = ncbi4na;
	}
	if (ap2 != outap2)
		map2 = BlastAlphaMapFindCreate(outap2, ap2);
	if (AsnWrite(aip, BLAST0_MATRIX_salpha, &av) == 0)
		goto Error;


	if (!fullreport) /* Exit stage left! */
		goto Done;

	if (AsnWriteChoice(aip, BLAST0_MATRIX_scores, 1, NULL) == 0)
		goto Error;

	if (AsnOpenStruct(aip, MATRIX_scores_scaled_ints, NULL) == 0)
		goto Error;
	av.realvalue = 0.;
	if (AsnWrite(aip, scores_scaled_ints_scale, &av) == 0)
		goto Error;
	if (AsnOpenStruct(aip, MATRIX_scores_scaled_ints_ints, NULL) == 0)
		goto Error;

	for (i1 = 0; i1 < outap1->alphasize; ++i1) {
		ch1 = outap1->alist[i1];
		if (map1 != NULL) {
			if (BlastAlphaMapTst(map1, ch1))
				ch1 = BlastAlphaMapChr(map1, ch1);
			else { /* there is no mapping of ch1 */
				for (i2 = 0; i2 < outap2->alphasize; ++i2) {
					av.intvalue = INT4_MIN;
					if (AsnWrite(aip, scores_scaled_ints_ints_E, &av) == 0)
						goto Error;
				}
				continue;
			}
		}
		for (i2 = 0; i2 < outap2->alphasize; ++i2) {
			ch2 = outap2->alist[i2];
			if (map2 != NULL) {
				if (BlastAlphaMapTst(map2, ch2))
					ch2 = BlastAlphaMapChr(map2, ch2);
				else { /* there is no mapping of ch2 */
					av.intvalue = INT4_MIN;
					if (AsnWrite(aip, scores_scaled_ints_ints_E, &av) == 0)
						goto Error;
					continue;
				}
			}
			s = sbp->matrix[ch1][ch2];
			if (s < BLAST_SCORE_1MIN)
				s = INT4_MIN;
			av.intvalue = s;
			if (AsnWrite(aip, scores_scaled_ints_ints_E, &av) == 0)
				goto Error;
		}
	}
	if (AsnCloseStruct(aip, MATRIX_scores_scaled_ints_ints, NULL) == 0)
		goto Error;

	if (AsnCloseStruct(aip, MATRIX_scores_scaled_ints, NULL) == 0)
		goto Error;

Done:
	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

int
Bio_ResultAsnWrite(biop, shp, expected, observed, dim, sids, hits)
	BlastIoPtr	biop;
	ScoreHistPtr	shp;
	double	expected;
	unsigned long	observed;
	int		dim; /* dimensionality of the segments in the hitlist (us. 2) */
	ValNodePtr	sids; /* linked list of scoretype identifiers (intvalues) */
	BLAST_HitListPtr	hits;
{
	AsnIoPtr	aip;
	AsnTypePtr	atp;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return 0;

	atp = Bio_Enter(biop, Response_result);
	if (atp == NULL)
		return 1;

	if (ResultAsnWrite(aip, atp, shp, expected, observed, dim, sids, hits) != 0)
		return 1;

	Bio_Exit(biop, Response_result);
	return 0;
}

static int
ResultAsnWrite(aip, orig, shp, expected, observed, dim, sids, hits)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	ScoreHistPtr	shp;
	double	expected;
	unsigned long	observed;
	int		dim;
	ValNodePtr	sids;
	BLAST_HitListPtr	hits;
{
	BSRV_ScoreInfoPtr	sip;
	BLAST_HitListPtr	hlp;
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;
	int		cnt;

	if (aip == NULL)
		return 0;

	atp = AsnLinkType(orig, BLAST0_RESULT);
	if (atp == NULL)
		return 0;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	if (shp != NULL) {
		if (HistogramAsnWrite(aip, BLAST0_RESULT_hist, shp, expected, observed) != 0)
			goto Error;
	}

	for (cnt = 0, hlp = hits; hlp != NULL; hlp = hlp->next) {
		++cnt;
	}
	av.intvalue = cnt;
	if (AsnWrite(aip, BLAST0_RESULT_count, &av) == 0)
		goto Error;

	av.intvalue = dim;
	if (AsnWrite(aip, BLAST0_RESULT_dim, &av) == 0)
		goto Error;

	if (AsnOpenStruct(aip, BLAST0_RESULT_hsp_si, NULL) == 0)
		goto Error;
	for (; sids != NULL; sids = sids->next) {
		sip = BsrvScoreInfoFind(sids->data.intvalue);
		if (sip == NULL)
			continue;
		if (ScoreInfoAsnWrite(aip, BLAST0_RESULT_hsp_si_E, sip) != 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, BLAST0_RESULT_hsp_si, NULL) == 0)
		goto Error;

	if (AsnOpenStruct(aip, BLAST0_RESULT_hitlists, NULL) == 0)
		goto Error;
	for (hlp = hits; hlp != NULL; hlp = hlp->next) {
		if (HitListAsnWrite(aip, BLAST0_RESULT_hitlists_E, hlp) != 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, BLAST0_RESULT_hitlists, NULL) == 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
HistogramAsnWrite(aip, orig, shp, actual_expected, actual_observed)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	ScoreHistPtr	shp;
	double	actual_expected;
	unsigned long	actual_observed;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		i, hist_start, hist_stop;
	double	expected;
	unsigned long	observed, cnt;
	int		retval = 1;

	if (aip == NULL || shp == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_HISTOGRAM);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.realvalue = actual_expected;
	if (AsnWrite(aip, BLAST0_HISTOGRAM_expect, &av) == 0)
		goto Error;
	av.intvalue = actual_observed;
	if (AsnWrite(aip, BLAST0_HISTOGRAM_observed, &av) == 0)
		goto Error;

	hist_start = 0;
	hist_stop = -1;
	observed = shp->below;
	for (i = 0; i < shp->dim; ++i) {
		cnt = shp->hist[i];
		observed += cnt;
		if (cnt > 0 && hist_stop < 0)
			hist_stop = i;
		if (cnt > 0)
			hist_start = i;
	}
	av.intvalue = hist_start - hist_stop + 1;
	if (AsnWrite(aip, BLAST0_HISTOGRAM_nbars, &av) == 0)
		goto Error;
	if (AsnOpenStruct(aip, BLAST0_HISTOGRAM_bar, NULL) == 0)
		goto Error;
	for (i = hist_start; i >= hist_stop; --i) {
		cnt = shp->hist[i];
		expected = exp(shp->base + (i+1) * shp->incr);
		if (HistogramBarAsnWrite(aip, BLAST0_HISTOGRAM_bar_E, expected, observed) != 0)
			goto Error;
		observed -= cnt;
	}
	if (AsnCloseStruct(aip, BLAST0_HISTOGRAM_bar, NULL) == 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
HistogramBarAsnWrite(aip, orig, x, n)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	double	x;
	unsigned long	n;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_HISTOGRAM_BAR);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.realvalue = x;
	if (AsnWrite(aip, BLAST0_HISTOGRAM_BAR_x, &av) == 0)
		goto Error;
	av.intvalue = n;
	if (AsnWrite(aip, BLAST0_HISTOGRAM_BAR_n, &av) == 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
ScoreInfoAsnWrite(aip, orig, sip)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	BSRV_ScoreInfoPtr	sip;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL || sip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_SCORE_INFO);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = sip->sid;
	if (AsnWrite(aip, BLAST0_SCORE_INFO_sid, &av) == 0)
		goto Error;
	av.ptrvalue = sip->tag;
	if (AsnWrite(aip, BLAST0_SCORE_INFO_tag, &av) == 0)
		goto Error;

	if (sip->desc != NULL && sip->desc[0] != NULLB) {
		av.ptrvalue = sip->desc;
		if (AsnWrite(aip, BLAST0_SCORE_INFO_desc, &av) == 0)
			goto Error;
	}

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
HitListAsnWrite(aip, orig, hlp)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	BLAST_HitListPtr	hlp;
{
	BLAST_HSPPtr	hp;
	BLAST_StrPtr	sp;
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL || hlp == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_HITLIST);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = hlp->hspcnt;
	if (AsnWrite(aip, BLAST0_HITLIST_count, &av) == 0)
		goto Error;

	if (AsnOpenStruct(aip, BLAST0_HITLIST_hsps, NULL) == 0)
		goto Error;
	for (hp = hlp->hp; hp != NULL; hp = hp->next) {
		if (HSPAsnWrite(aip, BLAST0_HITLIST_hsps_E, hp) != 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, BLAST0_HITLIST_hsps, NULL) == 0)
		goto Error;

	if (AsnOpenStruct(aip, BLAST0_HITLIST_seqs, NULL) == 0)
		goto Error;
	sp = &hlp->str2;
	if (sp->ap->alphatype == BLAST_ALPHATYPE_AMINO_ACID && sp->src != NULL &&
				sp->src->ap->alphatype == BLAST_ALPHATYPE_NUCLEIC_ACID)
		sp = sp->src;
	if (SequenceAsnWrite(aip, BLAST0_HITLIST_seqs_E, sp, 0) != 0)
		goto Error;
	if (AsnCloseStruct(aip, BLAST0_HITLIST_seqs, NULL) == 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
SequenceAsnWrite(aip, orig, sp, flags)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	BLAST_StrPtr	sp;
	int	flags;
{
	BLAST_SeqDescPtr	sdp;
	BLAST_StrPtr	src;
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 1;
	atp = AsnLinkType(orig, BLAST0_SEQUENCE);
	if (atp == NULL)
		return 1;

	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	if (AsnOpenStruct(aip, BLAST0_SEQUENCE_desc, NULL) == 0)
		goto Error;
	for (sdp = sp->descp; sdp != NULL; sdp = sdp->next) {
		if (SeqDescAsnWrite(aip, BLAST0_SEQUENCE_desc_E, sdp) != 0)
			goto Error;
	}
	if (AsnCloseStruct(aip, BLAST0_SEQUENCE_desc, NULL) == 0)
		goto Error;

	av.intvalue = sp->len;
	if (AsnWrite(aip, BLAST0_SEQUENCE_length, &av) == 0)
		goto Error;

	/* attrib SEQUENCE OF BLAST0-attrib OPTIONAL */

	if (sp->gcode_id > 0 && sp->gcode_id != BLAST_GCODE_DEFAULT) {
		av.intvalue = sp->gcode_id;
		if (AsnWrite(aip, BLAST0_SEQUENCE_gcode, &av) == 0)
			goto Error;
	}

	/* seq BLAST0-Seq-data OPTIONAL */
	if (flags != 0 && SeqDataAsnWrite(aip, BLAST0_SEQUENCE_seq, sp, 0, sp->len) != 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
SeqDescAsnWrite(AsnIoPtr aip, AsnTypePtr orig, BLAST_SeqDescPtr sdp)
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = 1;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_SEQ_DESC);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	if (SeqidAsnWrite(aip, BLAST0_SEQ_DESC_id, sdp->id) != 0)
		goto Error;
	
	if (sdp->defline != NULL) {
		if (AsnBufWrite(aip, BLAST0_SEQ_DESC_defline, sdp->defline, sdp->deflinelen) == 0)
			goto Error;
	}

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
SeqidAsnWrite(AsnIoPtr aip, AsnTypePtr orig, BLAST_SeqIdPtr sip)
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = 1;
	CharPtr	cp;
	long	giid = 0;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_SEQ_ID);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	for (; sip != NULL; sip = sip->next) {
		if (sip->choice == 0)
			continue;
		if ((cp = sip->data.ptrvalue) == NULL)
			continue;
		if (strncmp(cp, "gi|", 3) == 0) {
			if (AsnWriteChoice(aip, BLAST0_SEQ_ID_E, 1, NULL) == 0)
				goto Error;
			giid = atol(cp+3);
			av.intvalue = giid;
			if (AsnWrite(aip, BLAST0_SEQ_ID_E_giid, &av) == 0)
				goto Error;
			continue;
		}
		if (AsnWriteChoice(aip, BLAST0_SEQ_ID_E, 2, NULL) == 0)
			goto Error;
		av.ptrvalue = sip->data.ptrvalue;
		if (AsnWrite(aip, BLAST0_SEQ_ID_E_textid, &av) == 0)
			goto Error;
	}

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
HSPAsnWrite(aip, orig, hp)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	BLAST_HSPPtr	hp;
{
	AsnTypePtr	atp;
	DataVal	av;
	long	i;
	double	d;
	int		scoretype;
	int		retval = 1;

	if (aip == NULL || hp == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_HSP);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = hp->sbp->id.data.intvalue;
	if (AsnWrite(aip, BLAST0_HSP_matid, &av) == 0)
		goto Error;

	if (AsnOpenStruct(aip, BLAST0_HSP_scores, NULL) == 0)
		goto Error;

	i = hp->score;
	if (i > 0 && ScoreAsnWrite(aip, BLAST0_HSP_scores_E, Score_type_score, 1, &i) == 0)
		goto Error;

	i = hp->n;
	if (sump_option)
		scoretype = Score_type_sum_n;
	else
		scoretype = Score_type_poisson_n;
	if (i > 1 && ScoreAsnWrite(aip, BLAST0_HSP_scores_E, scoretype, 1, &i) == 0)
		goto Error;

	d = hp->pvalue;
	if (hp->n == 1)
		scoretype = Score_type_p_value;
	else {
		if (sump_option)
			scoretype = Score_type_sum_p;
		else
			scoretype = Score_type_poisson_p;
	}
	if (d >= 0. && ScoreAsnWrite(aip, BLAST0_HSP_scores_E, scoretype, 0, &d) == 0)
		goto Error;

	d = hp->evalue;
	if (hp->n == 1)
		scoretype = Score_type_e_value;
	else {
		if (sump_option)
			scoretype = Score_type_sum_e;
		else
			scoretype = Score_type_poisson_e;
	}
	if (d >= 0. && ScoreAsnWrite(aip, BLAST0_HSP_scores_E, scoretype, 0, &d) == 0)
		goto Error;

	if (AsnCloseStruct(aip, BLAST0_HSP_scores, NULL) == 0)
		goto Error;

	av.intvalue = hp->len;
	if (AsnWrite(aip, BLAST0_HSP_len, &av) == 0)
		goto Error;

	if (AsnOpenStruct(aip, BLAST0_HSP_segs, NULL) == 0)
		goto Error;
	if (SegmentAsnWrite(aip,  BLAST0_HSP_segs_E, &hp->q_seg, hp->len) == 0)
		goto Error;
	if (SegmentAsnWrite(aip,  BLAST0_HSP_segs_E, &hp->s_seg, hp->len) == 0)
		goto Error;
	if (AsnCloseStruct(aip, BLAST0_HSP_segs, NULL) == 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}


static int
ScoreAsnWrite(aip, orig, scoretype, islong, scoreptr)
	AsnIoPtr	aip;
	AsnTypePtr	orig;
	int		scoretype;
	int		islong; /* 1 ==> scoreptr points to long, 0 ==> double */
	Nlm_VoidPtr	scoreptr;
{
	AsnTypePtr	atp;
	DataVal	av;
	int		retval = 1;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_SCORE);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	av.intvalue = scoretype;
	if (AsnWrite(aip, BLAST0_SCORE_sid, &av) == 0)
		goto Error;

	if (AsnWriteChoice(aip, BLAST0_SCORE_value, islong, NULL) == 0)
		goto Error;

	if (islong) {
		av.intvalue = *(long PNTR)scoreptr;
		if (AsnWrite(aip, BLAST0_SCORE_value_i, &av) == 0)
			goto Error;
	}
	else {
		av.realvalue = *(double PNTR)scoreptr;
		if (AsnWrite(aip, BLAST0_SCORE_value_r, &av) == 0)
			goto Error;
	}

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 1;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
SegmentAsnWrite(AsnIoPtr aip, AsnTypePtr orig, BLAST_SegPtr seg, unsigned long len)
{
	AsnTypePtr	atp;
	DataVal	av;
	BSRV_SeqInterval	si;
	int		strand;

	if (aip == NULL)
		return 0;

	atp = AsnLinkType(orig, BLAST0_SEGMENT);
	if (atp == NULL)
		return 0;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	strand = Strand_none;
	if (seg->frame > 0)
		strand = Strand_plus;
	else
		if (seg->frame < 0)
			strand = Strand_minus;

	if (strand != Strand_none && seg->sp->ap->alphatype == BLAST_ALPHATYPE_AMINO_ACID) {
		strand += 4;
	}

	si.next = NULL;
	si.strand = strand;
	if (strand == Strand_none || (strand & Strand_plus)) {
		si.from = asn_coord0(seg, seg->offset);
		si.to = asn_coord1(seg, seg->offset + len - 1);
		if (IntervalAsnWrite(aip, BLAST0_SEGMENT_loc, &si) != 0)
			goto Error;
	}
	else {
		si.from = asn_coord1(seg, seg->offset + len - 1);
		si.to = asn_coord0(seg, seg->offset);
		if (IntervalAsnWrite(aip, BLAST0_SEGMENT_loc, &si) != 0)
			goto Error;
	}

	/* str BLAST0-Seq-data OPTIONAL */
	if (SeqDataAsnWrite(aip, BLAST0_SEGMENT_str, seg->sp, seg->offset, len) != 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	AsnUnlinkType(orig);
	return 1;

Error:
	AsnUnlinkType(orig);
}

static int
SeqDataAsnWrite(AsnIoPtr aip, AsnTypePtr orig, BLAST_StrPtr sp, size_t offset, size_t len)
{
	AsnTypePtr	atp;
	DataVal	av;
	register BLAST_LetterPtr	lp = NULL, src = NULL;
	register size_t	i;
	BLAST_Letter	stacklp[10*KBYTE];
	BLAST_AlphabetPtr	ap;
	static BLAST_AlphaMapPtr	amp;
	static BLAST_AlphabetPtr	ncbistdaa;

	if (aip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_SEQ_DATA);
	if (atp == NULL)
		return 1;

	if (AsnWriteChoice(aip, atp, 1, NULL) == 0)
		goto Error;

	ap = sp->ap;

	if (ap->alphatype == BLAST_ALPHATYPE_AMINO_ACID) {
		if (ncbistdaa == NULL)
			ncbistdaa = BlastAlphabetFindByName("NCBIstdaa");
		src = sp->str + offset;
		if (ap == ncbistdaa)
			lp = src;
		else {
			if (amp == NULL || amp->from != sp->ap)
				amp = BlastAlphaMapFindCreate(sp->ap, ncbistdaa);
			if (amp == NULL)
				goto Error;

			if (len < DIM(stacklp))
				lp = stacklp;
			else
				lp = ckalloc(len);
			for (i = 0; i < len; ++i)
				lp[i] = amp->map[src[i]];
			if (lp != stacklp && lp != src)
				mem_free(lp);
		}

		if (AsnBufWrite(aip, BLAST0_SEQ_DATA_ncbistdaa, (CharPtr)lp, len) == 0)
			goto Error;
	}
	if (ap->alphatype == BLAST_ALPHATYPE_NUCLEIC_ACID) {
		size_t	enclen;

		enclen = len / 2 + (len % 2);
		if (enclen < DIM(stacklp))
			lp = stacklp;
		else
			lp = ckalloc(enclen);
		if (sp->lpb == 1)
			cvt1(sp->ap, sp->str, offset, len, lp);
		if (sp->lpb == 4)
			cvt4(sp->ap, sp->str, offset, len, lp);
		if (AsnBufWrite(aip, BLAST0_SEQ_DATA_ncbi4na, (CharPtr)lp, enclen) == 0)
			goto Error;
		if (lp != stacklp && lp != src)
			mem_free(lp);
	}

	AsnUnlinkType(orig);
	return 0;

Error:
	if (lp != stacklp && lp != src)
		mem_free(lp);
	AsnUnlinkType(orig);
	return 1;
}

static int
cvt1(BLAST_AlphabetPtr ap, register BLAST_LetterPtr lp, size_t offset, size_t len, BLAST_LetterPtr outbuf)
{
	register BLAST_Letter	ch;
	register BLAST_LetterPtr	lpmax, map;
	static BLAST_AlphaMapPtr	amp;
	static BLAST_AlphabetPtr	ncbi4na;

	if (ncbi4na == NULL)
		ncbi4na = BlastAlphabetFindByName("NCBI4na");
	if (ap != ncbi4na) {
		if (amp == NULL || amp->from != ap) {
			ncbi4na = BlastAlphabetFindByName("NCBI4na");
			amp = BlastAlphaMapFindCreate(ap, ncbi4na);
		}
		map = amp->map;
		for (lp += offset, lpmax = lp + len; lp < lpmax; ) {
			ch = map[*lp++] << 4; /* should check that a mapping exists */
			if (lp < lpmax) {
				ch |= map[*lp++]; /* should check that a mapping exists */
			}
			*outbuf++ = ch;
		}
	}

	for (lp += offset, lpmax = lp + len; lp < lpmax; ) {
		ch = *lp++ << 4;
		if (lp < lpmax) {
			ch |= *lp++;
		}
		*outbuf++ = ch;
	}

	return 0;
}

static int
cvt4(BLAST_AlphabetPtr ap, register BLAST_LetterPtr lp, size_t offset, size_t len, BLAST_LetterPtr outbuf)
/***** This function doesn't do what it claims!! *****/
{
	register BLAST_Letter	ch;
	register BLAST_LetterPtr	lpmax, map;
	int		i, j;
	static BLAST_AlphaMapPtr	amp;
	static BLAST_AlphabetPtr	ncbi4na;

	if (amp == NULL || amp->from != ap) {
		ncbi4na = BlastAlphabetFindByName("NCBI4na");
		amp = BlastAlphaMapFind(ap, ncbi4na);
	}
	map = amp->map;

	lp += offset / 4;
	ch = *lp++;
	j = offset % 4;
	switch (j) {
	case 3:
		ch >>= 2;
	case 2:
		ch >>= 2;
	case 1:
		ch >>= 2;
	case 0:
		i = 4 - j;
	}
	i = MIN(i, len);

	return 0;
}

static int
IntervalAsnWrite(AsnIoPtr aip, AsnTypePtr orig, BSRV_SeqIntervalPtr sip)
{
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = 1;

	if (aip == NULL || sip == NULL)
		return 1;

	atp = AsnLinkType(orig, BLAST0_SEQ_INTERVAL);
	if (atp == NULL)
		return 1;
	if (AsnOpenStruct(aip, atp, NULL) == 0)
		goto Error;

	if (sip->strand != Strand_none) {
		av.intvalue = sip->strand;
		if (AsnWrite(aip, BLAST0_SEQ_INTERVAL_strand, &av) == 0)
			goto Error;
	}

	av.intvalue = sip->from;
	if (AsnWrite(aip, BLAST0_SEQ_INTERVAL_from, &av) == 0)
		goto Error;

	av.intvalue = sip->to;
	if (AsnWrite(aip, BLAST0_SEQ_INTERVAL_to, &av) == 0)
		goto Error;

	if (AsnCloseStruct(aip, atp, NULL) == 0)
		goto Error;
	retval = 0;

Error:
	AsnUnlinkType(orig);
	return retval;
}

static int
frame_restricted_seg(seg)
	BLAST_SegPtr	seg;
{
	int	frame;

	frame = seg->frame;
	switch (seg->sp->ap->alphatype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		if (frame == 0)
			return FALSE;
		return TRUE;

	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		return FALSE;

	case BLAST_ALPHATYPE_UNDEFINED:
	default:
		return FALSE;
	}
}

static long
asn_coord0(seg, off)
	register BLAST_SegPtr	seg;
	register unsigned long	off;
{
	BLAST_StrPtr	ntsrc;
	register int	frame;

	frame = seg->frame;
	off += seg->sp->offset;

	switch (seg->sp->ap->alphatype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		if (frame == 0)
			return off;
		if (frame > 0)
			return off * CODON_LEN + frame - 1;
		ntsrc = seg->sp->src;
		return ntsrc->len - off * CODON_LEN + frame;

	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		if (frame >= 0)
			return off;
		return seg->sp->len - off - 1;

	case BLAST_ALPHATYPE_UNDEFINED:
	default:
		return off;
	}
	/*NOTREACHED*/
}

static long
asn_coord1(seg, off)
	register BLAST_SegPtr	seg;
	register unsigned long	off;
{
	register int	frame;
	BLAST_StrPtr	ntsrc;

	off += seg->sp->offset;
	frame = seg->frame;

	switch (seg->sp->ap->alphatype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		if (frame == 0)
			return off;
		if (frame > 0)
			return off * CODON_LEN + frame + 1;
		ntsrc = seg->sp->src;
		return ntsrc->len - off * CODON_LEN + frame - 2;

	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		if (frame >= 0)
			return off;
		return seg->sp->len - off - 1;

	case BLAST_ALPHATYPE_UNDEFINED:
	default:
		return off;
	}
	/*NOTREACHED*/
}

int LIBCALL
Bio_ParmsAsnWrite(BlastIoPtr biop, ValNodePtr stk)
{
	AsnTypePtr	atp0, atp1;

	if ((atp0 = Bio_Enter(biop, Response_parms)) == NULL)
		return 1;

	if ((atp1 = Bio_FindType(biop, Response_parms_e)) == NULL)
		return 1;

	if (StkAsnWrite(biop->aip, atp0, atp1, stk) != 0)
		return 1;

	Bio_Exit(biop, Response_parms);
	return 0;
}

int LIBCALL
Bio_StatsAsnWrite(BlastIoPtr biop, ValNodePtr stk)
{
	AsnTypePtr	atp0, atp1;

	if ((atp0 = Bio_Enter(biop, Response_stats)) == NULL)
		return 1;

	if ((atp1 = Bio_FindType(biop, Response_stats_e)) == NULL)
		return 1;

	if (StkAsnWrite(biop->aip, atp0, atp1, stk) != 0)
		return 1;

	Bio_Exit(biop, Response_stats);
	return 0;
}

int LIBCALL
StkAsnWrite(AsnIoPtr aip, AsnTypePtr atp0, AsnTypePtr atp1, ValNodePtr stk)
{
	if (aip == NULL || stk == NULL)
		return 1;

	if (AsnOpenStruct(aip, atp0, NULL) == 0)
		return 1;

	for (; stk != NULL; stk = stk->next) {
		if (stk->data.ptrvalue != NULL)
			if (AsnWrite(aip, atp1, &stk->data) == 0)
				return 1;
	}

	if (AsnCloseStruct(aip, atp0, NULL) == 0)
		return 1;
	return 0;
}
#endif /* BLASTASN1 */
