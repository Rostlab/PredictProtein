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
#include "blastapp.h"

/*
	fmaxscore(sp, start, len, sbp)
	returns the maximum achievable segment score

Note:  effect of BLAST parameter X is not taken into consideration.
*/
BLAST_Score
fmaxscore(sp, start, len, sbp)
	BLAST_StrPtr	sp;
	BLAST_Coord	start, len;
	BLAST_ScoreBlkPtr	sbp;
{
	register BLAST_LetterPtr	seq, maxseq;
	register BLAST_Score	sum, maxsum;
	register BLAST_ScorePtr	maxscore; /* max. score for each letter */

	maxscore = sbp->maxcost;

	seq = sp->str + start;
	maxseq = seq+len;
	sum = 0;
	maxsum = BLAST_SCORE_MIN;
	while (seq < maxseq) {
		if ((sum += maxscore[*seq++]) > maxsum)
			maxsum = sum;
		if (sum < 0)
			sum = 0;
	}
	return maxsum;
}
