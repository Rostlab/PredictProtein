#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

int LIBCALL
ckseqtype(sp)
	BLAST_StrPtr	sp;
{
	static BLAST_Letter	alist[] = { 'A', 'C', 'G', 'T', 'N', '-' };
	BLAST_AlphabetPtr	ap;
	long	cnt;
	double	fraction;
	int		rc = 0;

	ap = BlastAlphabetFindByID(BLAST_ALPHA_PRINT);
	if (ap == NULL)
		return rc;

	fraction = BlastResFreqStrAlist(sp, ap, alist, DIM(alist));

	if (fraction < 0.85) {
		if (sp->ap->alphatype == BLAST_ALPHATYPE_NUCLEIC_ACID) {
			warning("THE QUERY SEQUENCE APPEARS TO BE PROTEIN WHEN A NUCLEIC ACID SEQUENCE IS EXPECTED.");
			rc = -1;
		}
	}
	else
		if (sp->ap->alphatype == BLAST_ALPHATYPE_AMINO_ACID) {
			warning("THE QUERY SEQUENCE APPEARS TO BE NUCLEIC ACID WHEN A PROTEIN SEQUENCE IS EXPECTED.");
			rc = -1;
		}

	return rc;
}
