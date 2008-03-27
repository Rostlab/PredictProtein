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
#include <gish.h>
#include <gishlib.h>
#include "blastapp.h"
#include "gcode.h"

/* get_query - read the query sequence */
BLAST_StrPtr
get_query(filename, ap, sequsage, W, strands)
	char	*filename;
	BLAST_AlphabetPtr	ap;
	int	sequsage[2];
	unsigned	W;
	int	strands;
{
	BLAST_StrPtr	sp;
	FILE	*fp;
		
	sp = BlastStrNew(0, ap, 1);

	fp = ckopen(filename, "r", TRUE);
	if (get_fasta(sp, ap, fp, TRUE, qres_option) != 0)
		bfatal(ERR_UNDEF, "Could not read query sequence");
	fclose(fp);
	sp->fulllen = sp->len + (sp->offset = Qoffset);

	parse_defline(&sp->descp, sp->name);

	query_ack(sp, strands);

	if (sequsage != NULL && W > 0) {
		if (sequsage[0] != sequsage[1] && sp->len < W * CODON_LEN)
			bfatal(ERR_QUERYLEN, "the query sequence is shorter than the word length, W=%u, times the length of a codon, %d.  Thus, the minimum query sequence length is %d.",
				W, CODON_LEN, W * CODON_LEN);
		if (sequsage[0] == sequsage[1] && sp->len < W)
			bfatal(ERR_QUERYLEN, "the query sequence is shorter than the word length, W=%u.", W);
	}

	if (ckseqtype(sp) != 0 && sp->len >= 30 && qtype_option)
		bfatal(ERR_QUERYTYPE, "The query sequence appears to be of the wrong type for this program.");

	return sp;
}
