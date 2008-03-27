#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

void
get_headers(dbfp, hlp0)
	DBFilePtr	dbfp;
	BLAST_HitListPtr	hlp0;
{
	BLAST_HitListPtr	hlp;
	register BLAST_HitListPtr *hlist;
	BLAST_HitListPtr	*hlist0;
	size_t  i, nlists;

	/* Sort hitlists by seqid for faster disk seeks to get each header */

	nlists = BlastHitListCount(hlp0);

	/* Create a linear list for sorting */
	hlist = hlist0 = (BLAST_HitListPtr *)ckalloc(sizeof(hlist[0])*nlists);
	for (hlp = hlp0; hlp != NULL; hlp = hlp->next)
		*hlist++ = hlp;

	if (numprocs > 1)
		(void) Nlm_HeapSort((char *)hlist0, nlists, sizeof(*hlist0), (int (*)())cmp_hitlists_by_seqid);

	for (i = 0; i < nlists; ++i) {
		hlp = hlist0[i];
		if (db_seek(dbfp, hlp->str2.id.data.intvalue) != 0)
			continue;
		db_get_header(dbfp, &hlp->str2);
	}

	mem_free((char *)hlist0);
}
