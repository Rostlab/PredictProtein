#include <ncbi.h>
#include "blastapp.h"

BLAST_ScoreBlkPtr
get_weights(matid, mname, ap1, ap2, altscore)
	int	matid;
	CharPtr	mname;
	BLAST_AlphabetPtr	ap1, ap2;
	ValNodePtr	altscore;
{
	BLAST_ScoreBlkPtr	sbp;
	char buf[FILENAME_MAX], *cp;
	FILE	*fp;
	int		once = 0;

	sbp = BlastScoreBlkNew(ap1, ap2);
	if (sbp == NULL)
		bfatal(ERR_UNDEF, "ScoreBlkNew failed; %s", BlastErrStr(blast_errno));
	sbp->id.data.intvalue = matid;
	sbp->name = (CharPtr)StrSave(mname);

Retry:
	if ((fp = ckopen(mname, "r", 0)) == NULL) {

		if (++once > 1)
			bfatal(ERR_FOPEN, "Could not find or open a substitution matrix file named:  %s", mname);
		cp = getenv("BLASTMAT");
		sprintf(buf, "%s%s%s%s%s",
				(cp == NULL ? BLASTMAT : cp),
				DIRDELIMSTR,
				(ap1->alphatype == BLAST_ALPHATYPE_AMINO_ACID ? "aa" : "nt"),
				DIRDELIMSTR,
				mname);
		mname = buf;
		goto Retry;
	}

	if (BlastScoreBlkMatRead(sbp, fp) != BLAST_ERR_NONE) {
		BlastFree(sbp);
		sbp = NULL;
		bfatal(ERR_SUBFILE, "Syntax error in the scoring matrix file named %s",
				mname);
	}

	(void) fclose(fp);

	apply_altscores(sbp, altscore);

	return sbp;
}

int LIBCALL
apply_altscores(sbp, altscore)
	BLAST_ScoreBlkPtr	sbp;
	ValNodePtr	altscore;
{
	AltScorePtr	asp;
	BLAST_Letter	c1, c2;
	BLAST_Score	score;
	int	i;

	/* Apply alternate scores, if specified */
	for (; altscore != NULL; altscore = altscore->next) {
		if (altscore->choice != 0 && altscore->choice != sbp->id.data.intvalue)
			continue;
		asp = (AltScorePtr)altscore->data.ptrvalue;
		if (asp == NULL)
			continue;
		/* don't allow user to make the mistake of using too high a score */
		switch (asp->class) {
		case ALTSCORE_SPECIFIC:
		default:
			score = asp->altscore;
			score = MIN(score, BLAST_SCORE_1MAX);
			score = MAX(score, BLAST_SCORE_1MIN);
			break;
		case ALTSCORE_MIN:
			score = sbp->loscore;
			break;
		case ALTSCORE_MAX:
			score = sbp->hiscore;
			break;
		case ALTSCORE_NA:
			score = BLAST_SCORE_MIN / BLAST_WORDSIZE_MAX;
			break;
		}

		if (!asp->c1any) {
			if (BlastAlphaMapTst(sbp->a1->inmap, asp->c1))
				c1 = BlastAlphaMapChr(sbp->a1->inmap, asp->c1);
			else
				continue;
		}
		if (!asp->c2any) {
			if (BlastAlphaMapTst(sbp->a2->inmap, asp->c2))
				c2 = BlastAlphaMapChr(sbp->a2->inmap, asp->c2);
			else
				continue;
		}
		if (asp->c1any) {
			for (i = 0; i < sbp->a1->alphasize; ++i) {
				c1 = sbp->a1->alist[i];
				sbp->matrix[c1][c2] = score;
			}
			continue;
		}
		if (asp->c2any) {
			for (i = 0; i < sbp->a2->alphasize; ++i) {
				c2 = sbp->a2->alist[i];
				sbp->matrix[c1][c2] = score;
			}
			continue;
		}
		sbp->matrix[c1][c2] = score;
	}

	return 0;
}
