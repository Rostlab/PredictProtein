/**************************************************************************
*                                                                         *
*                             COPYRIGHT NOTICE                            *
*                                                                         *
* This software/database is categorized as "United States Government      *
* Work" under the terms of the United States Copyright Act.  It was       *
* produced as part of the author's official duties as a Government        *
* employee and thus can not be copyrighted.  This software/database is    *
* freely available to the public for use without a copyright notice.      *
* Restrictions can not be placed on its present or future use.            *
*                                                                         *
* Although all reasonable efforts have been taken to ensure the accuracy  *
* and reliability of the software and data, the National Library of       *
* Medicine (NLM) and the U.S. Government do not and can not warrant the   *
* performance or results that may be obtained by using this software,     *
* data, or derivative works thereof.  The NLM and the U.S. Government     *
* disclaim any and all warranties, expressed or implied, as to the        *
* performance, merchantability or fitness for any particular purpose or   *
* use.                                                                    *
*                                                                         *
* In any work or product derived from this material, proper attribution   *
* of the author(s) as the source of the software or data would be         *
* appreciated.                                                            *
*                                                                         *
**************************************************************************/
#include <ncbi.h>
#include "blastapp.h"

static void	hsp_chain_print PROTO((FILE *,BLAST_HSPPtr));

static char	*plabel PROTO((BLAST_HSPPtr));
static long coord0 PROTO((BLAST_SegPtr, unsigned long off));
static long coord1 PROTO((BLAST_SegPtr, unsigned long off));
static CharPtr	framelabel PROTO((BLAST_SegPtr));
static CharPtr	framestr PROTO((BLAST_SegPtr));
static void printmid0 PROTO((FILE *fp, BLAST_LetterPtr s1, BLAST_LetterPtr s2, int len, BLAST_ScoreBlkPtr sbp, int width));
static void printmid1 PROTO((FILE *fp, BLAST_LetterPtr s1, BLAST_LetterPtr s2, int len, BLAST_ScoreBlkPtr sbp, int width));
static void printmid2 PROTO((FILE *fp, BLAST_LetterPtr s1, BLAST_LetterPtr s2, int len, BLAST_ScoreBlkPtr sbp, int width));
static void printmid3 PROTO((FILE *fp, BLAST_LetterPtr s1, BLAST_LetterPtr s2, int len, BLAST_ScoreBlkPtr sbp, int width));

#define CODON_LEN	3
#define SEQLINE_LEN	60

/* hsp_print - print HSP when query & subject are both a.a. sequences */
int
hsp_print(fp, hp, compat)
	FILE	*fp;
	BLAST_HSPPtr	hp;
	int		compat; /* TRUE ==> compatibility mode of output format */
{
	void	(*printmid)();
	BLAST_ScoreMat	matrix;
	BLAST_LetterPtr	q0, q, s0, s;
	unsigned long	qpos, spos;
	char	outbuf[SEQLINE_LEN];
	register CharPtr	bp, bpmax;
	register UcharPtr	cp;
	UcharPtr	qmax;
	int		mlen, width;
	unsigned long	nbr_ident, nbr_pos;
	long	qcoord, scoord;
	size_t	j;
	register unsigned char	cs, cq;
	BLAST_ScoreBlkPtr	sbp;
	BLAST_LetterPtr	map1, map2;
	BLAST_AlphabetPtr	a1, a2;

	if (fp == NULL || hp == NULL)
		return 0;

	q0 = q = hp->q_seg.sp->str + hp->q_seg.offset;
	qpos = hp->q_seg.offset;
	s0 = s = hp->s_seg.sp->str + hp->s_seg.offset;
	spos = hp->s_seg.offset;

	sbp = hp->sbp;

	a1 = hp->q_seg.sp->ap;
	a2 = hp->s_seg.sp->ap;
	map1 = a1->outmap->map;
	map2 = a2->outmap->map;

	nbr_ident = nbr_pos = 0;
	matrix = sbp->matrix;
	if (a1 != a2 && sbp->amp12 != NULL) {
		register BLAST_LetterPtr	map;

		printmid = printmid0;
		map = sbp->amp12->map;
		for (qmax = q + hp->len; q < qmax; )
			if (matrix[cq = *q++][cs = *s++] > 0) {
				++nbr_pos;
				nbr_ident += (map[cq] == cs);
			}
	}
	else
		if (a1 == a2) {
			if (a1->alphatype == BLAST_ALPHATYPE_AMINO_ACID)
				printmid = printmid1;
			else
				printmid = printmid2;
			for (qmax = q + hp->len; q < qmax; )
				if (matrix[cq = *q++][cs = *s++] > 0) {
					++nbr_pos;
					nbr_ident += (cq == cs);
				}
		}
		else {
			printmid = printmid3;
			for (qmax = q + hp->len; q < qmax; )
				nbr_pos += (matrix[*q++][*s++] > 0);
		}


	if (putc('\n', fp) == EOF)
		return 1;

#if 0
	hsp_chain_print(fp, hp);
#endif

	fprintf(fp, " Score = %ld (%.1lf bits), Expect = %#0.2lg, ",
			(long)hp->score, ((double)hp->score)*(hp->kbp->Lambda/LN2),
			hp->evalue);

	if (hp->n < 2)
		fprintf(fp, "P = %#0.2lg\n", hp->pvalue);
	else
		fprintf(fp, "%sP(%u) = %#0.2lg\n", plabel(hp), hp->n, hp->pvalue);

	fprintf(fp,
			" Identities = %lu/%u (%u%%), Positives = %lu/%u (%u%%)",
			nbr_ident, hp->len, (unsigned)((100*nbr_ident)/hp->len),
			nbr_pos, hp->len, (unsigned)((100*nbr_pos)/hp->len) );

	if ((bp = framelabel(&hp->q_seg)) != NULL ||
			(bp = framelabel(&hp->s_seg)) != NULL) {
		fputs(", ", fp);
		fputs(bp, fp);
		fputs(" = ", fp);
		bp = framestr(&hp->q_seg);
		if (bp != NULL) {
			fputs(bp, fp);
			bp = framestr(&hp->s_seg);
			if (bp != NULL) {
				fputs(" / ", fp);
				fputs(bp, fp);
			}
		}
		else {
			bp = framestr(&hp->s_seg);
			if (bp != NULL)
				fputs(bp, fp);
		}
	}
	if (!compat) {
		fputs(", Matrix ", fp);
		if (sbp->name != NULL)
			fputs(sbp->name, fp);
		else
			fprintf(fp, "%d", hp->sbp->id.data.intvalue);
	}
	putc('\n', fp);

	for (q = q0, s = s0; q < qmax; ) {
		mlen = MIN(qmax - q, SEQLINE_LEN);
		qcoord = coord0(&hp->q_seg, qpos);
		scoord = coord0(&hp->s_seg, spos);
		width = MAX(5, Lwidth(qcoord,1));
		width = MAX(width, Lwidth(scoord,1));

		bp = outbuf, bpmax = bp + mlen;
		cp = q;
		do {
			*bp++ = map1[*cp++];
		} while (bp < bpmax);

		fprintf(fp, "\nQuery: %*ld ", width, qcoord);
			fwrite(outbuf, mlen, 1, fp);
			qcoord = coord1(&hp->q_seg, qpos + mlen - 1);
			fprintf(fp, " %ld\n", qcoord);

		(*printmid)(fp, q, s, mlen, sbp, width);

		bp = outbuf, bpmax = bp + mlen;
		cp = s;
		do {
			*bp++ = map2[*cp++];
		} while (bp < bpmax);

		fprintf(fp, "Sbjct: %*ld ", width, scoord);
			fwrite(outbuf, mlen, 1, fp);
			scoord = coord1(&hp->s_seg, spos + mlen - 1);
			fprintf(fp, " %ld\n", scoord);

		q += mlen;
		s += mlen;
		qpos += mlen;
		spos += mlen;
	}
	return ferror(fp);
}

static CharPtr
framelabel(seg)
	BLAST_SegPtr	seg;
{
	if (seg->frame == 0)
		return NULL;
	switch (seg->sp->ap->alphatype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		return "Frame";
	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		return "Strand";
	case BLAST_ALPHATYPE_UNDEFINED:
	default:
		return NULL;
	}
	/*NOTREACHED*/
}

static CharPtr
framestr(seg)
	BLAST_SegPtr	seg;
{
	static char	buf[24];

	if (seg->frame == 0)
		return NULL;
	switch (seg->sp->ap->alphatype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		switch (seg->frame) {
		case 1: return "+1";
		case 2: return "+2";
		case 3: return "+3";
		case -1: return "-1";
		case -2: return "-2";
		case -3: return "-3";
		default:
			sprintf(buf, "%+d", seg->frame);
			return buf;
		}
	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		if (seg->frame > 0)
			return "Plus";
		if (seg->frame < 0)
			return "Minus";
	case BLAST_ALPHATYPE_UNDEFINED:
	default:
		return NULL;
	}
	/*NOTREACHED*/
}


static char *
plabel(hp)
	BLAST_HSPPtr	hp;
{
	switch (hp->etype) {
	case VSCORE_POISSONP:
	case VSCORE_CONSISTP:
	case VSCORE_CONSISTE:
		return "Poisson ";
	case VSCORE_SUMP:
		return "Sum ";
	case VSCORE_UNDEFINED:
	default:
		return "";
	}
	/*NOTREACHED*/
}

static long
coord0(seg, off)
	register BLAST_SegPtr	seg;
	register unsigned long	off;
{
	register BLAST_StrPtr	ntsrc;

	off += seg->sp->offset;
	ntsrc = seg->sp->src;

	switch (seg->sp->ap->alphatype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		if (seg->frame == 0) {
			return off + 1;
		}
		if (seg->frame > 0) {
			return off * CODON_LEN + seg->frame + ntsrc->offset;
		}
		return ntsrc->len - off * CODON_LEN + seg->frame + 1 + ntsrc->offset;

	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		if (seg->frame >= 0) {
			return off + 1;
		}
		return seg->sp->len - off;

	case BLAST_ALPHATYPE_UNDEFINED:
	default:
		return off + 1;
	}
	/*NOTREACHED*/
}

static long
coord1(seg, off)
	register BLAST_SegPtr	seg;
	register unsigned long	off;
{
	register BLAST_StrPtr	ntsrc;

	off += seg->sp->offset;
	ntsrc = seg->sp->src;

	switch (seg->sp->ap->alphatype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		if (seg->frame == 0) {
			return off + 1;
		}
		if (seg->frame > 0) {
			return off * CODON_LEN + seg->frame + 2 + ntsrc->offset;
		}
		return ntsrc->len - off * CODON_LEN + seg->frame - 1 + ntsrc->offset;

	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		if (seg->frame >= 0) {
			return off + 1;
		}
		return seg->sp->len - off;

	case BLAST_ALPHATYPE_UNDEFINED:
	default:
		return off + 1;
	}
	/*NOTREACHED*/
}

static void
printmid0(fp, s1, s2, len, sbp, width)
	FILE	*fp;
	register BLAST_LetterPtr	s1, s2;
	int		len;
	BLAST_ScoreBlkPtr	sbp;
	int		width;
{
	BLAST_ScoreMat	matrix = sbp->matrix;
	BLAST_LetterPtr	cmpmap, outmap;
	register CharPtr	bp, bpmax;
	register unsigned char	c1, c2;
	int		i;
	char	buf[SEQLINE_LEN];

	cmpmap = sbp->amp12->map;
	outmap = sbp->a1->outmap->map;

	for (i = 0; i < width+8; ++i)
		putc(' ', fp);
	for (bp = buf, bpmax = bp + len; bp < bpmax; ++bp) {
		if (matrix[c1 = *s1++][c2 = *s2++] > 0)
			if (cmpmap[c1] == c2)
				*bp = '|';
			else
				*bp = '+';
		else
			*bp = ' ';
	}
	fwrite(buf, len, 1, fp);
	putc('\n', fp);
}

static void
printmid1(fp, s1, s2, len, sbp, width)
	FILE	*fp;
	register BLAST_LetterPtr	s1, s2;
	int		len;
	BLAST_ScoreBlkPtr	sbp;
	int		width;
{
	BLAST_ScoreMat	matrix = sbp->matrix;
	BLAST_LetterPtr	outmap;
	register CharPtr	bp, bpmax;
	register unsigned char	c1, c2;
	int		i;
	char	buf[SEQLINE_LEN];

	outmap = sbp->a1->outmap->map;

	for (i = 0; i < width+8; ++i)
		putc(' ', fp);
	for (bp = buf, bpmax = bp + len; bp < bpmax; ++bp) {
		if (matrix[c1 = *s1++][c2 = *s2++] > 0)
			if (c1 == c2)
				*bp = outmap[c1];
			else
				*bp = '+';
		else
			*bp = ' ';
	}
	fwrite(buf, len, 1, fp);
	putc('\n', fp);
}

static void
printmid2(fp, s1, s2, len, sbp, width)
	FILE	*fp;
	register BLAST_LetterPtr	s1, s2;
	int		len;
	BLAST_ScoreBlkPtr	sbp;
	int		width;
{
	BLAST_ScoreMat	matrix = sbp->matrix;
	register CharPtr	bp, bpmax;
	register unsigned char	c1, c2;
	int		i;
	char	buf[SEQLINE_LEN];

	for (i = 0; i < width+8; ++i)
		putc(' ', fp);
	for (bp = buf, bpmax = bp + len; bp < bpmax; ++bp) {
		if (matrix[c1 = *s1++][c2 = *s2++] > 0)
			if (c1 == c2)
				*bp = '|';
			else
				*bp = '+';
		else
			*bp = ' ';
	}
	fwrite(buf, len, 1, fp);
	putc('\n', fp);
}

static void
printmid3(fp, s1, s2, len, sbp, width)
	FILE	*fp;
	register BLAST_LetterPtr	s1, s2;
	int		len;
	BLAST_ScoreBlkPtr	sbp;
	int		width;
{
	register CharPtr	bp, bpmax;
	BLAST_ScoreMat	matrix = sbp->matrix;
	int		i;
	char	buf[SEQLINE_LEN];

	for (i = 0; i < width+8; ++i)
		putc(' ', fp);
	for (bp = buf, bpmax = bp + len; bp < bpmax; ++bp) {
		if (matrix[*s1++][*s2++] > 0)
			*bp = '|';
		else
			*bp = ' ';
	}
	fwrite(buf, len, 1, fp);
	putc('\n', fp);
}

#if 0
static void
hsp_chain_print(fp, hp)
	FILE	*fp;
	BLAST_HSPPtr	hp;
{
	register BLAST_HSPPtr	hp2;
	register int	cnt;
	register int		totcnt;
	BLAST_HSPPtr	PNTR hpp, hpstack[100];

	if (hp->revptr == NULL && hp->fwdptr == NULL) {
		return;
	}

	fprintf(fp, " %s. Chain:  ", BlastHSPLabel(hp));

	for (cnt = 0, hp2 = hp->revptr; hp2 != NULL; hp2 = hp2->revptr)
		++cnt;
	totcnt = hp->n;

	if (cnt > DIM(hpstack)) {
		hpp = BlastMalloc(cnt * sizeof(hp));
		if (hpp == NULL)
			return;
	}
	else
		hpp = hpstack;

	for (cnt = 0, hp2 = hp->revptr; hp2 != NULL; hp2 = hp2->revptr)
		hpp[cnt++] = hp2;
	while (cnt > 0) {
		hp2 = hpp[--cnt];
		BlastHSPLabelPutFile(hp2, fp);
		if (--totcnt > 0)
			putc('-', fp);
	}

	for (hp2 = hp; hp2 != NULL; hp2 = hp2->fwdptr) {
		BlastHSPLabelPutFile(hp2, fp);
		if (hp2 == hp)
			putc('*', fp);
		if (--totcnt > 0)
			putc('-', fp);
	}

	putc('\n', fp);

	if (hpp != hpstack)
		BlastFree(hpp);
}
#endif
