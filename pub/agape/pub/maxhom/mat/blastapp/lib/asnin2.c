#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define USESASN1
#define BLASTASN2
#include "blastapp.h"
#include "gcode.h"

#ifdef BLASTASN2

int
Bio_RequestBeginRead(biop, avp)
	BlastIoPtr	biop;
	DataValPtr	avp;
{
	AsnTypePtr	atp;
	AsnIoPtr	aip;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return Request_none;

	atp = AsnReadId(aip, amp, BLAST0_REQUEST);
	if (atp == NULL)
		return Request_none;
	if (AsnReadVal(aip, atp, avp) == 0)
		return Request_none;

	atp = AsnReadId(aip, amp, atp);
	if (atp == NULL)
		return Request_none;

	if (AsnReadVal(aip, atp, avp) == 0)
		return Request_none;

	biop->atp = atp;
	return Bio_AsnType2Request(atp);
}

int
Bio_AsnType2Request(atp)
	AsnTypePtr	atp;
{
	if (atp == BLAST0_REQUEST_hello)
		return Request_hello;
	if (atp == BLAST0_REQUEST_motd)
		return Request_motd;
	if (atp == BLAST0_REQUEST_session_get)
		return Request_session_get;
	if (atp == BLAST0_REQUEST_session_set)
		return Request_session_set;
	if (atp == BLAST0_REQUEST_prog_info)
		return Request_prog_info;
	if (atp == BLAST0_REQUEST_db_info)
		return Request_db_info;
	if (atp == BLAST0_REQUEST_search)
		return Request_search;
	if (atp == BLAST0_REQUEST_goodbye)
		return Request_goodbye;
	return Request_none;
}

int LIBCALL
Bio_SearchAsnRead(biop, spp)
	BlastIoPtr	biop;
	BSRV_SearchPtr	PNTR spp;
{
	BSRV_SearchPtr	sp;
	AsnIoPtr	aip;
	AsnTypePtr	atp;
	DataVal	av;

	if (biop == NULL || (aip = biop->aip) == NULL || spp == NULL)
		return 1;

	sp = BsrvSearchNew();
	if (sp == NULL)
		return 1;

	atp = AsnReadId(aip, amp, atp);
	if (atp == BLAST0_SEARCH_program) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		sp->program = av.ptrvalue;
		atp = AsnReadId(aip, amp, atp);
	}

	if (atp == BLAST0_SEARCH_database) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		sp->database = av.ptrvalue;
		atp = AsnReadId(aip, amp, atp);
	}

	if (atp == BLAST0_SEARCH_query) {
		if (QueryAsnRead(aip, atp, &sp->query) != 0)
			goto Error;
		atp = AsnReadId(aip, amp, atp);
	}

	if (atp == BLAST0_SEARCH_options) {
		if (get_options(aip, atp, &sp->options) != 0)
			goto Error;
		if ((atp = AsnReadId(aip, amp, atp)) == NULL)
			goto Error;
	}

	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	AsnKillValue(atp, &av);
	*spp = sp;
	return 0;

Error:
	BsrvSearchDestruct(sp);
	*spp = NULL;
	return 1;
}


int LIBCALL
get_options(AsnIoPtr aip, AsnTypePtr orig, ValNodePtr PNTR options)
{
	AsnTypePtr	atp = orig;
	DataVal	av;
	ValNodePtr	vnp;

	if (aip == NULL || orig == NULL)
		return 1;
	if (AsnReadVal(aip, atp, &av) == 0)
		return 1;

	while ((atp = AsnReadId(aip, amp, atp)) != orig) {
		if (AsnReadVal(aip, atp, &av) == 0)
			return 1;
		if (atp == BLAST0_SEARCH_options_E) {
			if (ValNodeAddPointer(options, 0, av.ptrvalue) == NULL)
				return 1;
		}
		else
			AsnKillValue(atp, &av);
	}
	if (AsnReadVal(aip, atp, &av) == 0)
		return 1;

	return 0;
}

#if 0
BSRV_SessionPtr LIBCALL
Bio_SessionSetAsnRead(BlastIoPtr biop)
{
	AsnIoPtr	aip;
	BSRV_SessionPtr	ssp;

	if (biop == NULL || (aip = biop->aip) == NULL)
		return NULL;

	atp = AsnReadId(aip, amp, BLAST0_SESSION);
	if (atp == NULL)
		goto Error;

	ssp = SessionAsnRead(aip, NULL);
	if (ssp == NULL)
		goto Error;

Error:

	return ssp;
}

BSRV_SessionPtr LIBCALL
SessionAsnRead(AsnIoPtr aip, AsnTypePtr orig)
{
	BSRV_SessionPtr	ssp;

	if (aip == NULL)
		return NULL;

	if (orig == NULL)
		atp = AsnReadId(aip, amp, BLAST0_SESSION_SET);
	else
		atp = AsnLinkType(orig, BLAST0_SESSION_SET);
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;

	ssp = Nlm_MemGet(sizeof(*ssp), MGET_CLEAR|MGET_ERRPOST);
	if (ssp == NULL)
		return NULL;

	AsnUnlinkType(orig);
	return ssp;
}
#endif
#endif /* BLASTASN1 */
