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
#include <gishlib.h>
#include "blastapp.h"

int LIBCALL
format_stats(stp)
	ValNodePtr	PNTR stp;
{
	char	buf[80];

	if (stp == NULL)
		return 0;

	stk_context_stats(stp, &ctx[0], nctx);
	stkprintnl(stp);

	stkprint(stp, "Database:  %s", dbdesc.def);
	stkprintnl(stp);
	stkprint(stp, "  Release date:  %s",
		(dbdesc.rel_date != NULL ? dbdesc.rel_date : "unknown"));
	stkprintnl(stp);
	stkprint(stp, "  Posted date:  %s",
		(dbdesc.bld_date != NULL ? dbdesc.bld_date : "unknown"));
	stkprintnl(stp);
	stkprint(stp, "# of letters in database:  %s", Ultostr(dbdesc.totlen,1));
	if (Z_set)
		stkprint(stp, "  (Z = %0.lf)", Neff);
	stkprintnl(stp);
	stkprint(stp, "# of sequences in database:  %s", Ultostr(dbdesc.count,1));
	stkprintnl(stp);
	stkprint(stp, "# of database sequences satisfying E:  %s", Ultostr(hasHSP,1));
	stkprintnl(stp);

	if (seqbogus && dbfp->data.blast.fafile == NULL)
		warning("*%d of the reported database sequences %s known to contain non-ACGT letters, but %s could not be retrieved from the original FASTA format file.  Alignments involving such sequences may contain incorrectly matched letters at the positions where non-ACGT letters should be.",
			seqbogus,
			(seqbogus == 1 ? "is" : "are"),
			(seqbogus == 1 ? "it" : "they")
			);
	stkprint(stp, "No. of states in DFA:  %s (%s KB)", Ultostr(dfanstates,1),
				Ultostr(HOWMANY(dfanstates*dfastatesize, KBYTE),1));
	stkprintnl(stp);
	stkprint(stp, "Total size of DFA:  %s KB (%s KB)",
				Ultostr(HOWMANY(dfasize, KBYTE),1),
				Ultostr(HOWMANY(dfaextent, KBYTE),1));
	stkprintnl(stp);
	sys_strtime(buf, &t1, &t2);
	stkprint(stp, "Time to generate neighborhood:  %s", buf);
	stkprintnl(stp);
#ifdef MPROC_AVAIL
	stkprint(stp, "No. of processors used:  %d", numprocs);
	stkprintnl(stp);
#endif
	sys_strtime(buf, &t2, &t3);
    stkprint(stp, "Time to search database:  %s", buf);
	stkprintnl(stp);
	sys_strtime(buf, (Cputime_t *)NULL, &t4);
    stkprint(stp, "Total cpu time:  %s", buf);
	stkprintnl(stp);
	return 0;
}
