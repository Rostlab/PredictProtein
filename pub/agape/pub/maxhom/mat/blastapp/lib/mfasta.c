#include <ncbi.h>
#include <gishlib.h>
#include <blastapp.h>

int
mget_fasta(sp, ap, mfp)
	BLAST_StrPtr	sp;
	BLAST_AlphabetPtr	ap;
	MFILE	*mfp;
{
	CharPtr	buf0;
	size_t	*bufmax;
	CharPtr	buf;
	register Nlm_Boolean	PNTR maptst;
	register BLAST_LetterPtr	map;
	register CharPtr	bufp, cp;
	register int	ch;
	size_t	len;

	if (sp == NULL || ap == NULL || mfp == NULL)
		return 1;

	while ((ch = mfil_getc(mfp)) != '>') {
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
	if (mfil_vgets(&sp->name, &sp->namealloc, &sp->name, mfp) == NULL)
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
	sp->frame = +1;

	maptst = ap->inmap->maptst;
	map = ap->inmap->map;
	sp->_str[0] = ap->sentinel;
	buf0 = (CharPtr)sp->_str;
	cp = buf = buf0 + sizeof(sp->_str[0]);
	while ((ch = mfil_getc(mfp)) != '>' && ch != EOF) {
		mfil_ungetc(ch, mfp);
		if (mfil_vgets(&buf0, &sp->alloclen, &buf, mfp) == NULL)
			break;
		cp = buf;
		while (maptst[ch = *cp]) {
			*cp++ = (char)map[ch];
			if (maptst[ch = *cp] == 0)
				break;
			*cp++ = (char)map[ch];
		}
		if (ch != '\n' && ch != NULLB) {
			bufp = cp;
			for (;;) {
				while (maptst[ch = *++bufp])
					*cp++ = (char)map[ch];
				if (ch == '\n' || ch == NULLB)
					break;
			}
		}
		buf = cp;
	}
	if (ch == '>')
		mfil_ungetc(ch, mfp);
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
	return sp->len == 0;
}
