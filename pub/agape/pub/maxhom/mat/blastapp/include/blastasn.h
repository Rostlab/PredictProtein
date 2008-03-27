#ifndef __BLASTASN_H__
#define __BLASTASN_H__

#define BLAST_ASN_VERSION	0

#if defined(BLASTASN) && defined(USESASN1)
#include <asn.h>
#ifdef BLASTASN1
#include "asndefs1.h"
#endif
#ifdef BLASTASN2
#include "asndefs2.h"
#endif

#else

#define AsnIoPtr	Nlm_VoidPtr
#define AsnTypePtr	Nlm_VoidPtr
#define DataValPtr	Nlm_VoidPtr

#endif /* !defined(BLASTASN) || !defined(USESASN1) */


typedef struct blastio {
	FILE	*fp;
	AsnIoPtr	aip;
	AsnTypePtr	orig, atp;
	Boolean	outblk;
	} BlastIo, PNTR BlastIoPtr;

typedef enum bsrv_request {
	Request_none = 0,
	Request_hello = 1,
	Request_motd,
	Request_session_get,
	Request_session_set,
	Request_prog_info,
	Request_db_info,
	Request_search,
	Request_goodbye,
	Request_max
	} BSRV_Request, PNTR BSRV_RequestPtr;

typedef enum bsrv_response {
	Response_none = 0,
	Response_hello = 1,
	Response_motd,
	Response_session_get,
	Response_session_set,
	Response_db_info,
	Response_prog_info,
	Response_ack,
	Response_goodbye,
	Response_queued,
	Response_preface,
	Response_query,
	Response_dbdesc,
	Response_matrix,
	Response_matrix_e,
	Response_kablk,
	Response_kablk_e,
	Response_job_start,
	Response_job_progress,
	Response_job_done,
	Response_result,
	Response_parms,
	Response_parms_e,
	Response_stats,
	Response_stats_e,
	Response_warning,
	Response_status,
	Response_max
	} BSRV_Response, PNTR BSRV_ResponsePtr;

enum BSRV_Strand {
	Strand_none = 0,
	Strand_plus = 1,
	Strand_minus = 2,
	Strand_both = 3,
	Strand_plus_rf = 5,
	Strand_minus_rf = 6
	};

typedef enum {
	Score_type_score = 1,
	Score_type_p_value = 2,
	Score_type_e_value = 3,
	Score_type_pw_p_value = 4,
	Score_type_pw_e_value = 5,
	Score_type_poisson_p = 6,
	Score_type_poisson_e = 7,
	Score_type_poisson_n = 8,
	Score_type_pw_poisson_p = 9,
	Score_type_pw_poisson_e = 10,
	Score_type_sum_p = 11,
	Score_type_sum_e = 12,
	Score_type_sum_n = 13,
	Score_type_pw_sum_p = 14,
	Score_type_pw_sum_e = 15,
	Score_type_link_previous = 16,
	Score_type_link_next = 17,
	Score_type_max
	} BSRV_ScoreType, PNTR BSRV_ScoreTypePtr;

enum BSRV_SessionPriority {
	Priority_ignore = -1,
	Priority_not_set = 0,
	Priority_scavenger = 1,
	Priority_batch_low = 2,
	Priority_batch_med = 3,
	Priority_batch_high = 4,
	Priority_interactive_low = 5,
	Priority_interactive_med = 6,
	Priority_interactive_high = 7
	};

typedef struct bsrv_session {
	enum BSRV_SessionPriority	priority;
	int		search_max;
	int		tot_cpu_max;
	int		tot_real_max;
	int		cpu_max;
	int		real_max;
	int		idle_max;
	int		imalive;
	} BSRV_Session, PNTR BSRV_SessionPtr;


typedef struct bsrv_seq_interval {
	struct bsrv_seq_interval	PNTR next;
	enum BSRV_Strand	strand;
	unsigned long	from, to;
	} BSRV_SeqInterval, PNTR BSRV_SeqIntervalPtr;

typedef struct bsrv_query {
	struct bsrv_query	PNTR next;
	BLAST_StrPtr	sp;
	BSRV_SeqIntervalPtr	nw_mask;
	BSRV_SeqIntervalPtr	x_mask;
	BSRV_SeqIntervalPtr	hard_mask;
	} BSRV_Query, PNTR BSRV_QueryPtr;

typedef struct bsrv_search {
	struct bsrv_search	PNTR next;
	CharPtr	program;
	CharPtr	database;
	BSRV_QueryPtr	query;
	ValNodePtr	options;
	} BSRV_Search, PNTR BSRV_SearchPtr;

typedef struct bsrv_dbdesc {
	struct bsrv_dbdesc	PNTR next;
	CharPtr	name;
	int	type;
	CharPtr	def;
	CharPtr	rel_date;
	CharPtr	bld_date;
	long	count;
	long	totlen;
	long	maxlen;
	} BSRV_DbDesc, PNTR BSRV_DbDescPtr;

typedef struct bsrv_dbinfo {
	struct bsrv_dbinfo	PNTR next;
	CharPtr	dbname;
	BSRV_DbDesc	desc;
	ValNodePtr	dbtags; /* list of FASTA identifier tags found in this db */
	ValNodePtr	divisions; /* points to the divisions */
	ValNodePtr	updatedby; /* points to the update */
	ValNodePtr	contains; /* linked list of databases contained by this one */
	ValNodePtr	derivof;	/* list of databases this one was derived from */
	ValNodePtr	progs;
	} BSRV_DbInfo, PNTR BSRV_DbInfoPtr;

typedef struct bsrv_scoreinfo {
	BSRV_ScoreType	sid;
	CharPtr	tag;
	CharPtr	desc;
	} BSRV_ScoreInfo, PNTR BSRV_ScoreInfoPtr;

int LIBCALL get_dbdesc_bld_date PROTO((BSRV_DbDescPtr ddp, CharPtr fname));
int LIBCALL get_dbdesc_rel_date PROTO((BSRV_DbDescPtr ddp));

AsnTypePtr LIBCALL Bio_ResponseFindType PROTO((BSRV_Response choice));
AsnTypePtr LIBCALL Bio_RequestFindType PROTO((BSRV_Request choice));

BSRV_SearchPtr LIBCALL	BsrvSearchNew PROTO((void));
void LIBCALL	BsrvSearchDestruct PROTO((BSRV_SearchPtr));
BSRV_QueryPtr LIBCALL	BsrvQueryNew PROTO((void));
void LIBCALL	BsrvQueryDestruct PROTO((BSRV_QueryPtr));
BSRV_SeqIntervalPtr LIBCALL	BsrvSeqIntervalNew PROTO((void));
BSRV_SeqIntervalPtr LIBCALL BsrvSeqIntervalAppend PROTO((BSRV_SeqIntervalPtr orig, BSRV_SeqIntervalPtr new));
void LIBCALL	BsrvSeqIntervalDestruct PROTO((BSRV_SeqIntervalPtr));
BSRV_ScoreInfoPtr LIBCALL BsrvScoreInfoFind PROTO((BSRV_ScoreType sid));

int LIBCALL	Bio_ResponseAckAsnWrite PROTO((BlastIoPtr biop, int code, CharPtr reason, int cputime, int cum_cputime));
int LIBCALL Bio_ResultAsnWrite PROTO((BlastIoPtr biop, ScoreHistPtr shp, double expected, unsigned long observed, int dim, ValNodePtr hsp_si, BLAST_HitListPtr hlp));
AsnTypePtr LIBCALL Bio_RequestReadId PROTO((BlastIoPtr biop, DataValPtr avp));
int LIBCALL	Bio_AsnType2RequestType PROTO((AsnTypePtr atp));
int LIBCALL Bio_GoodbyeAsnWrite PROTO((BlastIoPtr biop, int code, CharPtr reason, long cpuused, long cpuremains));
int LIBCALL Bio_ScoreBlkAsnWrite PROTO((BlastIoPtr biop, ContxtPtr ctxp, int nctx, int fullreport));
int LIBCALL Bio_KABlkAsnWrite PROTO((BlastIoPtr biop, ContxtPtr ctxp, int nctx));

int LIBCALL RequestHelloAsnWrite PROTO((AsnIoPtr aip, CharPtr hello));
int LIBCALL RequestSearchAsnWrite PROTO((AsnIoPtr aip, CharPtr program, CharPtr database, BSRV_QueryPtr query, ValNodePtr options));


#endif /* !__BLASTASN_H__ */
