#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"
/*
Used to ensure that hitlists are sorted by their order of appearance
in the database.  This permits faster retrieval of header lines
when the header file is kept on disk.
*/
int
cmp_hitlists_by_seqid(hli, hlj)
	BLAST_HitListPtr	*hli, *hlj;
{
	register unsigned long	hi = (*hli)->str2.id.data.intvalue, hj = (*hlj)->str2.id.data.intvalue;

	if (hi > hj)
		return 1;
	if (hi < hj)
		return -1;
	return 0;
}
