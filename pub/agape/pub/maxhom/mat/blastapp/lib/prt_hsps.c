#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

/* Print all HitLists where the smallest pvalue in the list is below a cutoff */
int
print_HSPs(hlp, maxpval, print_hit)
	register BLAST_HitListPtr	hlp;
	register double	maxpval;
	int		(*print_hit) PROTO((BLAST_HitListPtr));
{
	register BLAST_HSPPtr	hp;
	long	cnt, noprt, unsatisfactory;

	if (showblast == 0)
		return 0;

	/* For each HitList in the linked list... */
	for (unsatisfactory = cnt = 0; hlp != NULL; hlp = hlp->next) {
		if (hlp->best_hsp->pvalue <= maxpval) {
			if (cnt < showblast || showblast < 0) {
				++cnt;
				for (hp = hlp->hp; hp != NULL; hp = hp->next) {
					++ctx[hp->context].wfstats.reported;
				}
				if ((*print_hit)(hlp) != 0)
					return -1;
			}
		}
		else
			++unsatisfactory;
	}
	noprt = hasHSP - cnt - unsatisfactory;
	if (showblast > 0 && noprt > 0) {
		if (b_out.fp != NULL)
			putc('\n', b_out.fp);
		warning("HSPs involving %s database sequences were not reported due to the limiting value of parameter B = %ld.",
				Ltostr(noprt,1),
				showblast);
	}
	return 0;
}
