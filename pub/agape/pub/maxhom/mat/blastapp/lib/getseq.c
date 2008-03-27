#include <ncbi.h>
#include "blastapp.h"
#include "ntbet.h"

/*
	get_seq_from_fasta

	Used to obtain ASCII sequence representation with NUL terminator.
*/
int LIBCALL
get_seq_from_fasta(buf, start, len, fp, offset, line_len)
	CharPtr	buf;
	BLAST_Coord	start;
	unsigned long	len;
	FILE	*fp;
	off_t	offset;
	int		line_len;
{
	char	*p, *q;
	unsigned long	in_len, line;

	if (fp == NULL)
		return -1;

	line = start/line_len;
	in_len = len + len/line_len + (start%line_len != 0);
	if (fseek(fp, offset + start + line, SEEK_SET) == -1)
		bfatal(ERR_DBASE, "fseek failed in FASTA database sequence file");
	if (fread(buf, in_len, 1, fp) != 1)
		bfatal(ERR_DBASE, "unexpected error reading FASTA sequence file");
	buf[in_len] = NULLB;
	for (p = q = buf; p < buf + len; ++q) {
		if (*q != '\n') {
			if ((*p++ = TOUPPER(*q)) == NULLB)
				bfatal(ERR_DBASE, "database files are inconsistent");
		}
	}
	buf[len] = NULLB;
	return 0;
}


/*
	get_seq_from_cseq_xl

	Used to obtain sequence translated representation with no NUL terminator.
*/

int LIBCALL
get_seq_from_cseq_xl(buf, start, len, mfp, c_seq0, offset, btoa)
	CharPtr	buf;
	BLAST_Coord	start;
	unsigned long	len;
	MFILE	*mfp;
	unsigned char	*c_seq0;
	off_t	offset; /* starting offset of the complete, compressed sequence */
	register CharPtr	btoa;
{
	CharPtr	cbuf;
	unsigned long	clen, m1;
	int		m0, mf;
	unsigned char	ch;

	m0 = (start%(CHAR_BIT/NBPN));
	if (m0 != 0)
		m0 = (CHAR_BIT/NBPN) - m0; /* no. of stragglers in first byte */
	mf = (start+len) % (CHAR_BIT/NBPN); /* no. of stragglers in final byte */
	if (start/(CHAR_BIT/NBPN) == (start+len)/(CHAR_BIT/NBPN)) {
		m1 = 0;
		clen = 1; /* total compressed bytes to read */
	}
	else {
		m1 = (len - mf - m0) / (CHAR_BIT/NBPN); /* no. of complete bytes */
		clen = (m0 != 0) + m1 + (mf != 0); /* total compressed bytes to read */
	}
	offset += start/(CHAR_BIT/NBPN);

	if (c_seq0 != NULL)
		cbuf = (CharPtr)c_seq0 + offset + clen - 1;
	else {
		if (mfil_seek(mfp, offset, SEEK_SET) == -1)
			bfatal(ERR_DBASE, "fseek failed in BLAST compressed sequence database file");
		if (mfil_read(buf, clen, 1, mfp) != 1)
			bfatal(ERR_DBASE, "unexpected error reading BLAST compressed sequence database file");
		cbuf = buf + clen - 1;
	}

	buf += len;
	--buf; /* no NUL terminator */

	ch = *cbuf--;

	if (clen == 1) {
		if (mf)
			ch >>= (NBPN * ((CHAR_BIT/NBPN) - mf));
		while (len--) {
			*buf-- = btoa[ch&BITMASK(NBPN)];
			ch >>= NBPN;
		}
		return 0;
	}

	if (mf) {
		ch >>= (NBPN * ((CHAR_BIT/NBPN) - mf));
		while (mf--) {
			*buf-- = btoa[ch&BITMASK(NBPN)];
			ch >>= NBPN;
		}
		ch = *cbuf--;
	}

	while (m1--) {
		*buf-- = btoa[ch&BITMASK(NBPN)];
		ch >>= NBPN;
		*buf-- = btoa[ch&BITMASK(NBPN)];
		ch >>= NBPN;
		*buf-- = btoa[ch&BITMASK(NBPN)];
		*buf-- = btoa[ch>>NBPN];
		ch = *cbuf--;
	}

	while (m0--) {
		*buf-- = btoa[ch&BITMASK(NBPN)];
		ch >>= NBPN;
	}

	return 0;
}

/*
	get_seq_from_fasta_xl

	Used to obtain binary sequence representation, with no terminator.
*/
int LIBCALL
get_seq_from_fasta_xl(buf, start, len, fp, offset, line_len, ap)
	register BLAST_LetterPtr	buf;
	BLAST_Coord	start;
	size_t	len;
	FILE	*fp;
	off_t	offset;
	int		line_len;
	BLAST_AlphabetPtr	ap;
{
	unsigned long	lineno;
	register int	i;
	register size_t	in_len;
	register BLAST_LetterPtr	bufmax;
	register Boolean	PNTR maptst;
	register BLAST_LetterPtr	map;

	if (fp == NULL)
		return -1;

	map = ap->inmap->map;
	maptst = ap->inmap->maptst;

	lineno = start/line_len;
	in_len = len + len/line_len + (start%line_len != 0);
	if (fseek(fp, offset + start + lineno, SEEK_SET) == -1)
		bfatal(ERR_DBASE, "fseek failed in FASTA database sequence file");

	for (bufmax = buf + len; buf < bufmax && in_len > 0; --in_len) {
		if ((i = getc(fp)) == EOF)
			bfatal(ERR_DBASE, "premature end-of-file encountered while reading FASTA database file");
		if (maptst[i])
			*buf++ = map[i];
		else
			if (i != '\n')
				bfatal(ERR_DBASE, "unexpected letter in FASTA file database sequence:  \"%c\"", i);
	}
	if (buf < bufmax)
		bfatal(ERR_DBASE, "FASTA database file has improper format or is the wrong one to be reading");

	/* no null termination! */
	return 0;
}


/*
	get_seq_from_cseq

	Used to obtain binary sequence representation, with no NUL terminator.
*/
int LIBCALL
get_seq_from_cseq(buf, start, len, mfp, c_seq0, offset)
	BLAST_LetterPtr	buf;
	BLAST_Coord	start;
	unsigned long	len;
	MFILE	*mfp;
	unsigned char	*c_seq0;
	off_t	offset; /* starting offset of the complete, compressed sequence */
{
	CharPtr	cbuf;
	unsigned long	clen, m1;
	int		m0, mf;
	unsigned char	ch;

	m0 = (start%(CHAR_BIT/NBPN));
	if (m0 != 0)
		m0 = (CHAR_BIT/NBPN) - m0; /* no. of stragglers in first byte */
	mf = (start+len) % (CHAR_BIT/NBPN); /* no. of stragglers in final byte */
	if (start/(CHAR_BIT/NBPN) == (start+len)/(CHAR_BIT/NBPN)) {
		m1 = 0;
		clen = 1; /* total compressed bytes to read */
	}
	else {
		m1 = (len - mf - m0) / (CHAR_BIT/NBPN); /* no. of complete bytes */
		clen = (m0 != 0) + m1 + (mf != 0); /* total compressed bytes to read */
	}
	offset += start/(CHAR_BIT/NBPN);

	if (c_seq0 != NULL)
		cbuf = (CharPtr)c_seq0 + offset + clen - 1;
	else {
		if (mfil_seek(mfp, offset, SEEK_SET) == -1)
			bfatal(ERR_DBASE, "fseek failed in BLAST compressed sequence database file");
		if (mfil_read((CharPtr)buf, clen, 1, mfp) != 1)
			bfatal(ERR_DBASE, "unexpected error reading BLAST compressed sequence database file");
		cbuf = (CharPtr)buf + clen - 1;
	}

	buf += len;
#if 1
	--buf;
#else
	*buf-- = NULLB; /* install the null terminator */
#endif

	ch = *cbuf--;

	if (clen == 1) {
		if (mf)
			ch >>= (NBPN * ((CHAR_BIT/NBPN) - mf));
		while (len--) {
			*buf-- = ch&BITMASK(NBPN);
			ch >>= NBPN;
		}
		return 0;
	}

	if (mf) {
		ch >>= (NBPN * ((CHAR_BIT/NBPN) - mf));
		while (mf--) {
			*buf-- = ch&BITMASK(NBPN);
			ch >>= NBPN;
		}
		ch = *cbuf--;
	}

	while (m1--) {
		*buf-- = ch&BITMASK(NBPN);
		ch >>= NBPN;
		*buf-- = ch&BITMASK(NBPN);
		ch >>= NBPN;
		*buf-- = ch&BITMASK(NBPN);
		*buf-- = ch>>NBPN;
		ch = *cbuf--;
	}

	while (m0--) {
		*buf-- = ch&BITMASK(NBPN);
		ch >>= NBPN;
	}

	return 0;
}
