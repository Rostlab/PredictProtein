#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define USESASN1
#define BLASTASN1
#include "blastapp.h"
#include "gcode.h"

#ifdef BLASTASN1

BLAST_StrPtr SequenceAsnRead PROTO((AsnIoPtr aip, AsnTypePtr orig));
BSRV_SeqIntervalPtr LIBCALL SeqIntervalAsnRead PROTO((AsnIoPtr aip, AsnTypePtr orig));
BLAST_SeqDescPtr LIBCALL SeqDescAsnRead PROTO((AsnIoPtr aip, AsnTypePtr orig));
BLAST_SeqIdPtr LIBCALL SeqIdAsnRead PROTO((AsnIoPtr aip, AsnTypePtr orig));
BLAST_StrPtr LIBCALL get_seqdata PROTO((AsnIoPtr aip, AsnTypePtr orig, int querylen));

int _cdecl
QueryAsnRead(AsnIoPtr aip, AsnTypePtr orig, BSRV_QueryPtr PNTR qpp)
{
	BSRV_QueryPtr	qp = NULL;
	BSRV_SeqIntervalPtr	sip;
	AsnTypePtr	atp;
	DataVal	av;
	int	retval = 1;

	if (qpp != NULL) {
		BsrvQueryDestruct(*qpp);
		*qpp = NULL;
	}
	if (aip == NULL)
		return 1;

	if (orig == NULL)
		atp = AsnReadId(aip, amp, BLAST0_QUERY);
	else
		atp = AsnLinkType(orig, BLAST0_QUERY);
	if (atp == NULL)
		return 1;
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;

	qp = BsrvQueryNew();
	if (qp == NULL)
		goto Error;

	if ((atp = AsnReadId(aip, amp, atp)) == NULL)
		goto Error;
	if (atp != BLAST0_QUERY_seq)
		return 1;

	if ((qp->sp = SequenceAsnRead(aip, atp)) == NULL)
		goto Error;

	if ((atp = AsnReadId(aip, amp, atp)) == NULL)
		goto Error;
	if (atp == BLAST0_QUERY_nw_mask) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		AsnKillValue(atp, &av);
		if ((atp = AsnReadId(aip, amp, atp)) == NULL)
			goto Error;
		while (atp == BLAST0_QUERY_nw_mask_E) {
			if (AsnReadVal(aip, atp, &av) == 0)
				goto Error;
			AsnKillValue(atp, &av);
			sip = SeqIntervalAsnRead(aip, atp);
			if ((atp = AsnReadId(aip, amp, atp)) == NULL)
				goto Error;
			if (AsnReadVal(aip, atp, &av) == 0)
				goto Error;
			qp->nw_mask = BsrvSeqIntervalAppend(qp->nw_mask, sip);
			if ((atp = AsnReadId(aip, amp, atp)) == NULL)
				goto Error;
		}
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		AsnKillValue(atp, &av);
	}
	if (atp == BLAST0_QUERY_x_mask) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		AsnKillValue(atp, &av);
		if ((atp = AsnReadId(aip, amp, atp)) == NULL)
			goto Error;
		while (atp == BLAST0_QUERY_x_mask_E) {
			if (AsnReadVal(aip, atp, &av) == 0)
				goto Error;
			AsnKillValue(atp, &av);
			sip = SeqIntervalAsnRead(aip, atp);
			if ((atp = AsnReadId(aip, amp, atp)) == NULL)
				goto Error;
			if (AsnReadVal(aip, atp, &av) == 0)
				goto Error;
			qp->x_mask = BsrvSeqIntervalAppend(qp->x_mask, sip);
			if ((atp = AsnReadId(aip, amp, atp)) == NULL)
				goto Error;
		}
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		AsnKillValue(atp, &av);
	}
	if (atp == BLAST0_QUERY_hard_mask) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		AsnKillValue(atp, &av);
		if ((atp = AsnReadId(aip, amp, atp)) == NULL)
			goto Error;
		while (atp == BLAST0_QUERY_hard_mask_E) {
			if (AsnReadVal(aip, atp, &av) == 0)
				goto Error;
			AsnKillValue(atp, &av);
			sip = SeqIntervalAsnRead(aip, atp);
			if ((atp = AsnReadId(aip, amp, atp)) == NULL)
				goto Error;
			if (AsnReadVal(aip, atp, &av) == 0)
				goto Error;
			qp->hard_mask = BsrvSeqIntervalAppend(qp->hard_mask, sip);
			if ((atp = AsnReadId(aip, amp, atp)) == NULL)
				goto Error;
		}
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		AsnKillValue(atp, &av);
	}
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	AsnKillValue(atp, &av);

	retval = 0;
	*qpp = qp;

Error:
	AsnUnlinkType(orig);
	if (retval != 0)
		BsrvQueryDestruct(qp);
	return retval;
}

BSRV_SeqIntervalPtr _cdecl
SeqIntervalAsnRead(AsnIoPtr aip, AsnTypePtr orig)
{
	BSRV_SeqIntervalPtr	sip;
	AsnTypePtr	atp;
	DataVal	av;

	if (aip == NULL)
		return NULL;

	if (orig == NULL)
		atp = AsnReadId(aip, amp, NULL);
	else
		atp = AsnLinkType(orig, BLAST0_SEQ_INTERVAL);

	sip = BsrvSeqIntervalNew();
	if (sip == NULL)
		return NULL;
	AsnUnlinkType(orig);
	return sip;
}

BLAST_StrPtr
SequenceAsnRead(AsnIoPtr aip, AsnTypePtr orig)
{
	BLAST_StrPtr	sp = NULL;
	AsnTypePtr	atp, atp2;
	DataVal	av;
	BLAST_StrPtr	retval = NULL;
	BLAST_SeqDescPtr	sdp0 = NULL, sdp, sdp2;
	int	gcode_id = BLAST_GCODE_STANDARD;
	int	querylen;

	if (aip == NULL)
		return NULL;
	if (orig == NULL)
		atp = AsnReadId(aip, amp, BLAST0_SEQUENCE);
	else
		atp = AsnLinkType(orig, BLAST0_SEQUENCE);
	if (atp == NULL)
		return NULL;
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;

	if ((atp = AsnReadId(aip, amp, atp)) == NULL)
		goto Error;
	if (atp != BLAST0_SEQUENCE_desc)
		goto Error;
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	while ((atp = AsnReadId(aip, amp, atp)) == BLAST0_SEQUENCE_desc_E) {
		if ((sdp = SeqDescAsnRead(aip, atp)) == NULL)
			goto Error;
		if (sdp0 == NULL)
			sdp0 = sdp;
		else
			sdp2->next = sdp;
		sdp2 = sdp;
	}
	if (atp == NULL)
		goto Error;
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	AsnKillValue(atp, &av);

	if ((atp = AsnReadId(aip, amp, atp)) == NULL)
		goto Error;
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	if (atp != BLAST0_SEQUENCE_length)
		goto Error;
	querylen = av.intvalue;

	if ((atp = AsnReadId(aip, amp, atp)) == NULL)
		goto Error;
	if (atp == BLAST0_SEQUENCE_attrib) {
		if (get_attribs(aip, atp) != 0)
			goto Error;
		if ((atp = AsnReadId(aip, amp, atp)) == NULL)
			goto Error;
	}

	if (atp == BLAST0_SEQUENCE_gcode) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		gcode_id = av.intvalue;
		if ((atp = AsnReadId(aip, amp, atp)) == NULL)
			goto Error;
	}

	if (atp == BLAST0_SEQUENCE_seq) {
		if ((sp = get_seqdata(aip, atp, querylen)) == NULL)
			goto Error;
		if ((atp = AsnReadId(aip, amp, atp)) == NULL)
			goto Error;
	}
	else {
		/* null sequence */
		sp = BlastStrNew(0, BlastAlphabetFindByName("NCBIstdaa"), 1);
		if (sp == NULL)
			goto Error;
	}
	sp->descp = sdp0;
	sp->gcode_id = gcode_id;

	while (atp != orig) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto Error;
		if ((atp = AsnReadId(aip, amp, atp)) == NULL)
			goto Error;
	}
	if (AsnReadVal(aip, atp, &av) == 0)
		goto Error;
	AsnKillValue(atp, &av);
	retval = sp;

Error:
	AsnUnlinkType(orig);
	if (retval == NULL && sp != NULL)
		BlastStrDestruct(sp);
	return retval;
}

BLAST_SeqDescPtr LIBCALL
SeqDescAsnRead(AsnIoPtr aip, AsnTypePtr orig)
{
	DataVal av;
	AsnTypePtr atp;
	BLAST_SeqDescPtr sdp;

	if (aip == NULL)
		return NULL;

	if (orig == NULL) /* BLAST_SeqDesc ::= (self contained) */
		atp = AsnReadId(aip, amp, BLAST0_SEQ_DESC);
	else
		atp = AsnLinkType(orig, BLAST0_SEQ_DESC);

	/* link in local tree */
	if (atp == NULL)
		return NULL;

	sdp = (BLAST_SeqDescPtr)ckalloc0(sizeof(*sdp));
	if (sdp == NULL)
		goto erret;
	if (AsnReadVal(aip, atp, &av) <= 0) /* read the start struct */
		goto erret;

	atp = AsnReadId(aip,amp, atp);
	if (atp == BLAST0_SEQ_DESC_id) {
		sdp -> id = SeqIdAsnRead(aip, atp);
		if (sdp -> id == NULL)
			goto erret;
		atp = AsnReadId(aip,amp, atp);
	}
	if (atp == BLAST0_SEQ_DESC_defline) {
		if (AsnReadVal(aip, atp, &av) <= 0)
			goto erret;
		sdp -> defline = av.ptrvalue;
		sdp -> deflinelen = strlen(av.ptrvalue);
		atp = AsnReadId(aip,amp, atp);
	}

	if (AsnReadVal(aip, atp, &av) <= 0)
		goto erret;
   /* end struct */

ret:
   AsnUnlinkType(orig);       /* unlink local tree */
   return sdp;

erret:
   BlastSeqDescDestruct(sdp);
   sdp = NULL;
   goto ret;
}

BLAST_SeqIdPtr LIBCALL
SeqIdAsnRead(AsnIoPtr aip, AsnTypePtr orig)
{
	char	buf[64];
	DataVal	av;
	AsnTypePtr	atp, atp0;
	BLAST_SeqIdPtr	sip0 = NULL;
	Uint1	choice;

	if (aip == NULL)
		return NULL;

	if (orig == NULL)
		atp = AsnReadId(aip, amp, BLAST0_SEQ_ID);
	else
		atp = AsnLinkType(orig, BLAST0_SEQ_ID);
	if (atp == NULL)
		return NULL;

	atp0 = atp;
	if (AsnReadVal(aip, atp, &av) == 0)
		return NULL;

	while ((atp = AsnReadId(aip, amp, atp)) != atp0) {
		if (AsnReadVal(aip, atp, &av) == 0)
			goto erret;
		if (atp == BLAST0_SEQ_ID_E_giid) {
			sprintf(buf, "gi|%ld", (long)av.intvalue);
			if (ValNodeCopyStr(&sip0, Dbtag_gi, buf) == NULL)
				goto erret;
			continue;
		}
		if (atp == BLAST0_SEQ_ID_E_textid) {
			if (ValNodeAddPointer(&sip0, dbtag_id(av.ptrvalue), av.ptrvalue) == NULL)
				goto erret;
		}
	}

	if (AsnReadVal(aip, atp, &av) == 0)
		goto erret;
ret:
	AsnUnlinkType(orig);
	return sip0;

erret:
	sip0 = ValNodeFreeData(sip0);
	goto ret;
}

int
get_attribs(AsnIoPtr aip, AsnTypePtr orig)
{
	AsnTypePtr	atp = orig;
	DataVal	av;

	if (AsnReadVal(aip, atp, &av) == 0)
		return 1;

	while ((atp = AsnReadId(aip, amp, atp)) != orig) {
		if (AsnReadVal(aip, atp, &av) == 0)
			return 1;
		AsnKillValue(atp, &av);
	}
	return 0;
}

BLAST_StrPtr LIBCALL
get_seqdata(AsnIoPtr aip, AsnTypePtr orig, int querylen)
{
	BLAST_StrPtr	sp = NULL;
	BLAST_AlphabetPtr	queryap;

	ByteStorePtr	bsp;
	AsnTypePtr	atp;
	DataVal	av;
	register int	i, ch;
	register CharPtr	cp, cpmax;
	BLAST_AlphabetPtr	ap;
	BLAST_AlphaMapPtr	themap;
	register BLAST_LetterPtr	map;
	register unsigned char	bch;

	if (aip == NULL)
		return NULL;
	if (orig == NULL)
		atp = AsnReadId(aip, amp, BLAST0_SEQ_DATA);
	else
		atp = AsnLinkType(orig, BLAST0_SEQ_DATA);
	if (atp == NULL)
		return NULL;
	if (AsnReadVal(aip, atp, &av) == 0)
		return NULL;

	if ((atp = AsnReadId(aip, amp, atp)) == NULL)
		return NULL;
	if (AsnReadVal(aip, atp, &av) == 0)
		return NULL;

	bsp = (ByteStorePtr) av.ptrvalue;

	BSSeek(bsp, 0, SEEK_SET);
	if (atp == BLAST0_SEQ_DATA_ncbistdaa) {
		if (BSLen(bsp) != querylen)
			/*fatalf(err_qlen, "query length not equal to SEQ_DATA length");*/
			return NULL;
		queryap = BlastAlphabetFindByName("NCBIstdaa");
		if (queryap == NULL)
			return NULL;
		sp = BlastStrNew(querylen, queryap, 1);
		if (sp == NULL)
			return NULL;
		cp = (CharPtr)sp->str;
		for (i = 0; (ch = BSGetByte(bsp)) != EOF; ++i) {
			cp[i] = ch;
		}
		sp->len = querylen;
	}
	if (atp == BLAST0_SEQ_DATA_ncbi4na) {
		if (BSLen(bsp) != (querylen/2 + querylen%2))
			/*fatalf(err_qlen, "query sequence bytestore has improper length");*/
			return NULL;
		queryap = BlastAlphabetFindByName("NCBI4na");
		if (queryap == NULL)
			return NULL;
		sp = BlastStrNew(querylen, queryap, 1);
		if (sp == NULL)
			return NULL;
		cp = (CharPtr)sp->str;
		cpmax = cp + querylen;
		while (cp < cpmax) {
			bch = (unsigned char)BSGetByte(bsp);
			*cp++ = (char)(bch>>4);
			if (cp >= cpmax)
				break;
			*cp++ = (char)(bch & 0x0f);
		}
		sp->len = querylen;
	}
	if (atp == BLAST0_SEQ_DATA_ncbi2na) {
		if (BSLen(bsp) != (querylen/4 + (querylen%4 != 0)))
			/*fatalf(err_qlen, "query sequence bytestore has improper length");*/
			return NULL;
		queryap = BlastAlphabetFindByName("NCBI4na");
		if (queryap == NULL)
			return NULL;
		sp = BlastStrNew(querylen, queryap, 1);
		if (sp == NULL)
			return NULL;
		ap = BlastAlphabetFindByName("NCBI2na");
		if (ap == NULL)
			return NULL;
		themap = BlastAlphaMapFind(ap, queryap);
		if (themap == NULL)
			return NULL;
		map = themap->map;
		cp = (CharPtr)sp->str;
		cpmax = cp + querylen;
		while (cp < cpmax) {
			bch = (unsigned char)BSGetByte(bsp);
			*cp++ = (char)map[bch>>6];
			if (cp >= cpmax)
				break;
			bch <<= 2;
			*cp++ = (char)map[bch>>6];
			if (cp >= cpmax)
				break;
			bch <<= 2;
			*cp++ = (char)map[bch>>6];
			if (cp >= cpmax)
				break;
			bch <<= 2;
			*cp++ = (char)map[bch>>6];
		}
		sp->len = querylen;
	}

	AsnKillValue(atp, &av);
	return sp;
}
#endif /* BLASTASN1 */
