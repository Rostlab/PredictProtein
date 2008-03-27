#include <ncbi.h>
#include <gishlib.h>
#include <blastapp.h>

int
get_fasta(sp, ap, fp, noisy, qres_option)
	BLAST_StrPtr	sp;
	BLAST_AlphabetPtr	ap;
	FILE	*fp;
	int	noisy;
	int	qres_option;
{
	CharPtr	buf0;
	size_t	*bufmax;
	CharPtr	buf;
	Boolean	badtst[BLAST_LETTER_MAX+1];
	Boolean	badone = FALSE;
	register Nlm_Boolean	PNTR maptst;
	register BLAST_LetterPtr	map;
	register CharPtr	bufp, cp;
	register int	ch;
	size_t	len;

	if (sp == NULL || ap == NULL || fp == NULL)
		return 1;

	if (noisy || qres_option) {
		MemSet(badtst, 0, sizeof badtst);
	}

	while ((ch = getc(fp)) != '>') {
		switch (ch) {
		case '\n': case '\r': case ' ': case '\t':
			continue;
		case EOF:
			return 1;
		default:
			fprintf(stderr, "\nFile is not in FASTA format\n");
			exit(6);
		}
	}
	if (vfgets(&sp->name, &sp->namealloc, &sp->name, fp) == NULL)
		return 1;
	sp->namemax = sp->namealloc;
	len = strlen(sp->name);
	if (len > 0 && sp->name[len-1] == '\n')
		--len;
	sp->name[sp->namelen = len] = NULLB;

	if (sp->str == NULL) {
		sp->_str = (BLAST_LetterPtr)Nlm_Malloc(2*sizeof(sp->_str[0]));
		if (sp->_str == NULL)
			return 1;
		sp->str = sp->_str + 1;
		sp->alloclen = 2*sizeof(sp->_str[0]);
		sp->len = sp->enclen = 0;
	}
	sp->ap = ap;
	sp->lpb = 1;
	sp->frame = 0;
	sp->offset = 0;
	if (ap->alphatype == BLAST_ALPHATYPE_NUCLEIC_ACID)
		sp->frame = 1;

	maptst = ap->inmap->maptst;
	map = ap->inmap->map;
	sp->_str[0] = ap->sentinel;
	buf0 = (CharPtr)sp->_str;
	cp = buf = buf0 + sizeof(sp->_str[0]);
	while ((ch = getc(fp)) != '>' && ch != EOF) {
		ungetc(ch, fp);
		if (vfgets(&buf0, &sp->alloclen, &buf, fp) == NULL)
			break;
		cp = buf;
		while (maptst[ch = *cp]) {
			*cp++ = (char)map[ch];
			if (maptst[ch = *cp])
				*cp++ = (char)map[ch];
			else
				break;
		}
		if (ch != '\n' && ch != NULLB) {
			bufp = cp;
			for (;;) {
				if (badtst[ch] == FALSE) {
					badtst[ch] = TRUE;
					if (!isspace(ch)) {
						badone = TRUE;
						if (noisy)
							warning("One or more invalid %s codes \"%c\" encountered in query sequence will be skipped.",
							(ap->alphatype == BLAST_ALPHATYPE_AMINO_ACID ? "amino acid" : "nucleotide"),
								ch);
					}
				}
				while (maptst[ch = *++bufp])
					*cp++ = (char)map[ch];
				if (ch == '\n' || ch == '\r' || ch == NULLB)
					break;
			}
		}
		buf = cp;
	}
	if (badone && qres_option)
		bfatal(ERR_QUERYRES, "One or more invalid residue codes was encountered in the query sequence.");

	if (ch == '>')
		ungetc(ch, fp);
	sp->_str = (BLAST_LetterPtr)buf0;
	sp->str = sp->_str + 1;
#if BLAST_LETTER_SIZE == 1
	*cp = ap->sentinel;
	sp->maxlen = sp->alloclen;
	sp->len = sp->enclen = cp - buf0 - 1;
#else
	sp->len = sp->enclen = cp - buf0 - sizeof(BLAST_Letter);
	if (sp->len > sp->alloclen / sizeof(BLAST_Letter)) {
		size_t	len = (sp->len + 2) * sizeof(BLAST_Letter);

		sp->_str = Nlm_Realloc(sp->_str, len);
		if (sp->_str == NULL)
			return 1;
		sp->alloclen = len;
	}
	sp->maxlen = sp->alloclen / sizeof(BLAST_Letter);
	{
		register BLAST_LetterPtr	lp, lpmin;

		lpmin = sp->str;
		lp = lpmin + sp->len;
		*lp = ap->sentinel;
		cp = ((CharPtr)sp->str) + sp->len;
		while (lp > lpmin)
			*--lp = (BLAST_Letter)*--cp;
	}
#endif
	sp->efflen = sp->len;
	sp->fulllen = sp->len;
	return sp->len == 0;
}

int
put_fasta(sp, fp)
	BLAST_StrPtr	sp;
	FILE	*fp;
{
	BLAST_AlphaMapPtr	amp;
	register BLAST_LetterPtr	seq, map;
	size_t	seqlen;
	size_t	len;
	register size_t	i;
	char	buf[60];

	if (sp == NULL || sp->ap == NULL || sp->lpb != 1)
		return 1;
	amp = sp->ap->outmap;
	map = amp->map;
	if (putc('>', fp) != '>')
		return 1;
	if (sp->descp != NULL && (sp->descp->defline != NULL || sp->descp->id != NULL)) {
		if (put_seqdesc(sp->descp, fp) != 0)
			return 1;
	}
	else
		fwrite(sp->name, sp->namelen, 1, fp);
	putc('\n', fp);
	seq = sp->str;
	seqlen = sp->len;
	while (seqlen > 0) {
		len = MIN(sizeof(buf), seqlen);
		for (i = 0; i < len; ++i)
			buf[i] = (char)map[seq[i]];
			/*buf[i] = (char)BlastAlphaMapChr(amp, seq[i]);*/
		fwrite(buf, len, 1, fp);
		putc('\n', fp);
		seq += len;
		seqlen -= len;
	}
	return 0;
}

int
put_seqdesc(sdp, fp)
	BLAST_SeqDescPtr	sdp;
	FILE	*fp;
{
	BLAST_SeqIdPtr	sip;

	if (sdp == NULL || fp == NULL)
		return 0;

	for (sip = sdp->id; sip != NULL && sip->choice != 0; ) {
		fwrite(sip->data.ptrvalue, strlen(sip->data.ptrvalue), 1, fp);
		if ((sip = sip->next) != NULL && sip->choice != 0)
			putc('|', fp);
	}
	if (sdp->defline != NULL && sdp->deflinelen > 0) {
		putc(' ', fp);
		fwrite(sdp->defline, sdp->deflinelen, 1, fp);
	}
	if (sdp->next != NULL) {
		putc(' ', fp);
		putc('>', fp);
		if (put_seqdesc(sdp->next, fp) != 0)
			return 1;
	}
	return ferror(fp);
}
