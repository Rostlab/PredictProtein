#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#include "blastapp.h"


static BSRV_ScoreInfo  _hsp_si[] = {
{Score_type_score, "Score", NULL },
{Score_type_p_value, "P", NULL },
{Score_type_e_value, "E", NULL },
{Score_type_pw_p_value, "PW_P", NULL },
{Score_type_pw_e_value, "PW_E", NULL },
{Score_type_poisson_p, "Poisson_P", NULL },
{Score_type_poisson_e, "Poisson_E", NULL },
{Score_type_poisson_n, "Poisson_N", NULL },
{Score_type_pw_poisson_p, "PW_Poisson_P", NULL },
{Score_type_pw_poisson_e, "PW_Poisson_E", NULL },
{Score_type_sum_p, "Sum_P", NULL },
{Score_type_sum_e, "Sum_E", NULL },
{Score_type_sum_n, "Sum_N", NULL },
{Score_type_pw_sum_p, "PW_Sum_P", NULL },
{Score_type_pw_sum_e, "PW_Sum_E", NULL },
{Score_type_link_previous, "Link_Prev", NULL },
{Score_type_link_next, "Link_Next", NULL }
};

BSRV_ScoreInfoPtr LIBCALL
BsrvScoreInfoFind(sid)
	BSRV_ScoreType	sid;
{
	int	i;

	for (i = 0; i < DIM(_hsp_si); ++i) {
		if (sid == _hsp_si[i].sid)
			return &_hsp_si[i];
	}
	return NULL;
}

BSRV_SeqIntervalPtr LIBCALL
BsrvSeqIntervalNew()
{
	return Nlm_Calloc(1, sizeof(BSRV_SeqInterval));
}

void LIBCALL
BsrvSeqIntervalDestruct(BSRV_SeqIntervalPtr sip)
{
	BSRV_SeqIntervalPtr	sip2;

	while (sip != NULL) {
		sip2 = sip->next;
		Nlm_MemSet(sip, 0, sizeof *sip);
		Nlm_Free(sip);
		sip = sip2;
	}
	return;
}

/* append second interval list to the first and return the head of the result */
BSRV_SeqIntervalPtr LIBCALL
BsrvSeqIntervalAppend(BSRV_SeqIntervalPtr sip0, BSRV_SeqIntervalPtr sip1)
{
	register BSRV_SeqIntervalPtr	sip = sip0;

	if (sip == NULL)
		return sip1;
	while (sip->next != NULL)
		sip = sip->next;
	sip->next = sip1;
	return sip0;
}

BSRV_QueryPtr LIBCALL
BsrvQueryNew(void)
{
	return Nlm_Calloc(1, sizeof(BSRV_Query));
}

void LIBCALL
BsrvQueryFree(BSRV_QueryPtr qp)
{
	if (qp == NULL)
		return;
	if (qp->sp != NULL)
		BlastStrDestruct(qp->sp);
	if (qp->nw_mask != NULL)
		BsrvSeqIntervalDestruct(qp->nw_mask);
	if (qp->x_mask != NULL)
		BsrvSeqIntervalDestruct(qp->x_mask);
	if (qp->hard_mask != NULL)
		BsrvSeqIntervalDestruct(qp->hard_mask);
	MemSet((VoidPtr)qp, 0, sizeof *qp);
}

void LIBCALL
BsrvQueryDestruct(BSRV_QueryPtr qp)
{
	if (qp == NULL)
		return;
	BsrvQueryFree(qp);
	Nlm_Free(qp);
}

BSRV_SearchPtr LIBCALL
BsrvSearchNew(void)
{
	return MemGet(sizeof(BSRV_Search), TRUE);
}

void LIBCALL
BsrvSearchDestruct(BSRV_SearchPtr sp)
{
	if (sp->program != NULL)
		Nlm_Free(sp->program);
	if (sp->database != NULL)
		Nlm_Free(sp->database);
	BsrvQueryDestruct(sp->query);
	ValNodeFreeData(sp->options);
	MemSet((VoidPtr)sp, 0, sizeof *sp);
}
