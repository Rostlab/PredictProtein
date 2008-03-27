#include <ncbi.h>
#include "blastapp.h"
#include "gcode.h"
#include "ntbet.h"

static BLAST_AlphabetPtr	nt2ap, blastaa;

int
translate(nsp, tsp1, tsp2, tsp3, gcode)
	BLAST_StrPtr	nsp; /* input nucleotide sequence */
	BLAST_StrPtr	tsp1, tsp2, tsp3; /* translation products */
	unsigned char	gcode[64];
{
	register int	i;
	register BLAST_Letter	ch;
	register BLAST_LetterPtr	sp1, sp2, sp3;
	register BLAST_LetterPtr	cp;
	register BLAST_LetterPtr	cend;
	unsigned long	nlen;
	BLAST_LetterPtr	spray[CODON_LEN];
	int		j;

	if (nt2ap == NULL) {
		nt2ap = BlastAlphabetFindByName("NCBI2na");
		blastaa = BlastAlphabetFindByName("OLDBLASTaa");
	}

	if (nsp->lpb != 4 || nsp->ap != nt2ap)
		goto Error;

	tsp1->lpb = tsp2->lpb = tsp3->lpb = 1;
	tsp1->src = tsp2->src = tsp3->src = nsp;

	tsp1->len = tsp1->enclen = nsp->len / CODON_LEN;
	tsp1->efflen = tsp1->len;

	tsp2->len = tsp2->enclen = (nsp->len - 1) / CODON_LEN;
	tsp2->efflen = tsp2->len;

	tsp3->len = tsp3->enclen = (nsp->len - 2) / CODON_LEN;
	tsp3->efflen = tsp3->len;

	sp1 = tsp1->str;
	tsp1->frame = +1;
	sp2 = tsp2->str;
	tsp2->frame = +2;
	sp3 = tsp3->str;
	tsp3->frame = +3;
	sp1[-1] = sp2[-1] = sp3[-1] = blastaa->sentinel;

	if (nsp->len < (CODON_LEN+2)) {
		tsp3->len = tsp3->enclen = 0;
		tsp3->efflen = 0.;
		tsp3->str[0] = blastaa->sentinel;
		if (nsp->len < (CODON_LEN+1)) {
			tsp2->len = tsp2->enclen = 0;
			tsp2->efflen = 0.;
			tsp2->str[0] = blastaa->sentinel;
			if (nsp->len < CODON_LEN) {
				tsp1->len = tsp1->enclen = 0;
				tsp1->efflen = 0.;
				tsp1->str[0] = blastaa->sentinel;
				return 0;
			}
		}
	}

	cp = nsp->str;
	cend = cp + nsp->len/4;
	ch = *cp;
	i = (ch>>6);
	i <<= 2;
	i |= (ch>>4)&3;
	j = nsp->len%4;

#define XBASE0(p)	i<<=2, i&=0x3f, i|=(ch>>6), *p++ =gcode[i]
#define XBASE1(p)	i<<=2, i&=0x3f, i|=(ch>>4)&3, *p++ =gcode[i]
#define XBASE2(p)	i<<=2, i&=0x3f, i|=(ch>>2)&3, *p++ =gcode[i]
#define XBASE3(p)	i<<=2, i&=0x3f, i|=ch&3, *p++ =gcode[i]

	if (cp < cend) {
		for (;;) {
			XBASE2(sp1);
			XBASE3(sp2);
			if (++cp >= cend)
				goto Break1;
			ch = *cp;
			XBASE0(sp3);
			XBASE1(sp1);
			XBASE2(sp2);
			XBASE3(sp3);
			if (++cp >= cend)
				goto Break2;
			ch = *cp;
			XBASE0(sp1);
			XBASE1(sp2);
			XBASE2(sp3);
			XBASE3(sp1);
			if (++cp >= cend)
				goto Break3;
			ch = *cp;
			XBASE0(sp2);
			XBASE1(sp3);
		}
Break1:
		spray[0] = sp3;
		spray[1] = sp1;
		spray[2] = sp2;
		goto Break;
Break2:
		spray[0] = sp1;
		spray[1] = sp2;
		spray[2] = sp3;
		goto Break;
Break3:
		spray[0] = sp2;
		spray[1] = sp3;
		spray[2] = sp1;
Break:
		if (j == 0)
			goto Terminate;
		ch = *cp;
		XBASE0(spray[0]);
		if (j > 1)
			XBASE1(spray[1]);
		if (j > 2)
			XBASE2(spray[2]);
	}
	else {
		if (j > 2)
			XBASE2(sp1);
		spray[0] = sp1;
		spray[1] = sp2;
		spray[2] = sp3;
	}

Terminate:
	*spray[0] = *spray[1] = *spray[2] = blastaa->sentinel;
	return 0;

Error:
	tsp1->len = tsp2->len = tsp3->len = 0;
	tsp1->enclen = tsp2->enclen = tsp3->enclen = 0;
	tsp1->efflen = tsp2->efflen = tsp3->efflen = 0.;
	return 1;
}

int
btranslate(nsp, tsp1, tsp2, tsp3, revgcode)
	BLAST_StrPtr	nsp;
	BLAST_StrPtr	tsp1, tsp2, tsp3;
	unsigned char	revgcode[64];
{
	register int	i;
	register BLAST_Letter	ch;
	register BLAST_LetterPtr	sp1, sp2, sp3;
	register BLAST_LetterPtr	cp = nsp->str;
	register BLAST_LetterPtr	cbeg;
	BLAST_LetterPtr	spray[CODON_LEN];
	int		j;

	if (nt2ap == NULL) {
		nt2ap = BlastAlphabetFindByName("NCBI2na");
		blastaa = BlastAlphabetFindByName("OLDBLASTaa");
	}

	if (nsp->lpb != 4 || nsp->ap != nt2ap)
		goto Error;

	tsp1->src = tsp2->src = tsp3->src = nsp;
	tsp1->lpb = tsp2->lpb = tsp3->lpb = 1;
	tsp1->frame = -1;
	tsp2->frame = -2;
	tsp3->frame = -3;
	sp1 = spray[0] = tsp1->str;
	sp2 = spray[1] = tsp2->str;
	sp3 = spray[2] = tsp3->str;
	sp1[-1] = sp2[-1] = sp3[-1] = blastaa->sentinel;

	tsp1->len = tsp1->enclen = nsp->len/CODON_LEN;
	tsp1->efflen = tsp1->len;
	tsp2->len = tsp2->enclen = (nsp->len-1)/CODON_LEN;
	tsp2->efflen = tsp2->len;
	tsp3->len = tsp3->enclen = (nsp->len-2)/CODON_LEN;
	tsp3->efflen = tsp3->len;

	if (tsp1->len > tsp1->maxlen)
		goto Error;
	if (tsp2->len > tsp1->maxlen)
		goto Error;
	if (tsp3->len > tsp1->maxlen)
		goto Error;

	if (nsp->len < (CODON_LEN+2)) {
		tsp3->len = tsp3->enclen = 0;
		tsp3->efflen = 0.;
		tsp3->str[0] = blastaa->sentinel;
		if (nsp->len < (CODON_LEN+1)) {
			tsp2->len = tsp2->enclen = 0;
			tsp2->efflen = 0.;
			tsp2->str[0] = blastaa->sentinel;
			if (nsp->len < CODON_LEN) {
				tsp1->len = tsp1->enclen = 0;
				tsp1->efflen = 0.;
				tsp1->str[0] = blastaa->sentinel;
				return 0;
			}
		}
	}


	cbeg = nsp->str;
	cp = nsp->str + (nsp->len+3)/4 - 1;
	j = nsp->len%4;
	/* skip over pad bits */
	ch = *cp;
	if (j == 0)
		j = 4;
	else
		ch >>= 2*(4-j);

#define XBASE(p)	i<<=2, i&=0x3c, i|=ch&3, ch>>=2, *p++ =revgcode[i]

	/* Finish off the terminal byte */
	i = ch&3;
	if (j > 1) {
		ch >>= 2;
		i <<= 2;
		i |= ch&3;
		ch >>= 2;
		if (j > 2) {
			XBASE(sp1);
			if (j == 4) {
				XBASE(sp2);
			}
		}
	}

	if (cp > cbeg) {
		ch = *--cp;
		/* Start work on the penultimate byte */
		switch (j) {
		case 1:
			i <<= 2;
			i |= ch&3;
			ch >>= 2;
			XBASE(sp1);
			spray[0] = sp2;
			spray[1] = sp3;
			spray[2] = sp1;
			break;
		case 2:
			XBASE(sp1);
			XBASE(sp2);
			spray[0] = sp3;
			spray[1] = sp1;
			spray[2] = sp2;
			break;
		case 3:
			XBASE(sp2);
			XBASE(sp3);
			spray[0] = sp1;
			spray[1] = sp2;
			spray[2] = sp3;
			break;
		case 4:
			XBASE(sp3);
			XBASE(sp1);
			spray[0] = sp2;
			spray[1] = sp3;
			spray[2] = sp1;
			break;
		}
		sp1 = spray[0];
		sp2 = spray[1];
		sp3 = spray[2];
		/* Finish the penultimate byte and process all further bytes */
		for (;;) {
			XBASE(sp1);
			XBASE(sp2);
			if (--cp < cbeg)
				break;
			ch = *cp;
			XBASE(sp3);
			XBASE(sp1);
			XBASE(sp2);
			XBASE(sp3);
			if (--cp < cbeg)
				break;
			ch = *cp;
			XBASE(sp1);
			XBASE(sp2);
			XBASE(sp3);
			XBASE(sp1);
			if (--cp < cbeg)
				break;
			ch = *cp;
			XBASE(sp2);
			XBASE(sp3);
		}
	}

	*sp1 = *sp2 = *sp3 = blastaa->sentinel;
	return 0;

Error:
	tsp1->len = tsp2->len = tsp3->len = 0;
	tsp1->enclen = tsp2->enclen = tsp3->enclen = 0;
	tsp1->efflen = tsp2->efflen = tsp3->efflen = 0.;
	return 1;
}

void
trans2(ntq, aaq, n, gcode)
	register BLAST_LetterPtr	ntq;	/* input nucleotide sequence */
	register BLAST_LetterPtr	aaq;	/* output amino acid sequence */
	int		n;			/* length of translated protein */
	unsigned char	gcode[64];
{
	register BLAST_LetterPtr	aaqmax = aaq+n;
	register BLAST_Letter	i, j, k;

	while (aaq < aaqmax) {
		i = nt_n4tob[*ntq++];
		j = nt_n4tob[*ntq++];
		k = nt_n4tob[*ntq++];
		*aaq++ = codon2aa(gcode, i, j, k);
	}
	/* NOT NULL TERMINATED! */
}

void
rtrans2(ntq, aaq, n, revgcode)
	register BLAST_LetterPtr	ntq;
	register BLAST_LetterPtr	aaq;
	int		n;
	unsigned char	revgcode[64];
{
	register BLAST_LetterPtr	aaqmax = aaq+n;
	register BLAST_Letter	i, j, k;

	ntq += CODON_LEN*n;
	while (aaq < aaqmax) {
		i = nt_n4tob[*--ntq];
		j = nt_n4tob[*--ntq];
		k = nt_n4tob[*--ntq];
		*aaq++ = codon2aa(revgcode, i, j, k);
	}
	/* NOT NULL TERMINATED! */
}

void
trans2b(ntq, aaq, n, gcode)
	register BLAST_LetterPtr	ntq;	/* input nucleotide sequence */
	register BLAST_LetterPtr	aaq;	/* output amino acid sequence */
	int		n;			/* length of translated protein */
	unsigned char	gcode[64];
{
	register BLAST_LetterPtr	aaqmax = aaq+n;
	register BLAST_Letter	i, j, k;

	while (aaq < aaqmax) {
		i = *ntq++;
		j = *ntq++;
		k = *ntq++;
		*aaq++ = codon2aa(gcode, i, j, k);
	}
	/* NOT NULL TERMINATED! */
}

void
rtrans2b(ntq, aaq, n, revgcode)
	register BLAST_LetterPtr	ntq;
	register BLAST_LetterPtr	aaq;
	int		n;
	unsigned char	revgcode[64];
{
	register BLAST_LetterPtr	aaqmax = aaq + n;
	register BLAST_Letter	i, j, k;

	ntq += CODON_LEN*n;
	while (aaq < aaqmax) {
		i = *--ntq;
		j = *--ntq;
		k = *--ntq;
		*aaq++ = codon2aa(revgcode, i, j, k);
	}
	/* NOT NULL TERMINATED! */
}
