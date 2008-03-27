#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

#define GAP_MAX	12 /* Max. permissible gap between two HSPs */
#define ENDGAP_MAX 12 /* Max. permissible gap at end of sequence */

static int	cmp_by_qpos PROTO((HSPPtr *h1, HSPPtr *h2));
static int	cmp_by_dbpos PROTO((HSPPtr *h1, HSPPtr *h2));

Boolean
acceptable_coverage(MPC hlp, qlen, dblen)
	MPDEF
	HitListPtr	hlp; /* list of hits against a database sequence */
	Coord_t	qlen; /* length of query sequence */
	Coord_t	dblen;	/* length of database sequence */
{
	HSPPtr	hp;
	HSPPtr	*hpr0, *hpr, hpray[50];
	int		sgn;
	Uint4	hspcnt;
	Uint4	tot, qtot, dbtot;
	Int4	qbeg, qend, dbbeg, dbend;
	Uint4	acctot;
	Int4	i, rc = FALSE;

	hp = hlp->hp;
	hspcnt = hlp->hspcnt;
	if (hspcnt <= DIM(hpray))
		hpr0 = hpray;
	else
		hpr0 = (HSPPtr *)ckalloc(sizeof(HSPPtr)*hspcnt);
	for (sgn = -1; sgn < 3; sgn += 2) {
		if (getlimits(hp, hpr0, sgn, qlen, &qbeg, &qend, &dbbeg, &dbend) != 0)
			continue;

		if (qbeg > ENDGAP_MAX) {
			if (qlen-qend > ENDGAP_MAX) {
				if (dbbeg > ENDGAP_MAX || dblen-dbend > ENDGAP_MAX)
					continue;
			}
			else {
				if (dbbeg > ENDGAP_MAX)
					continue;
			}
		}
		else {
			if (qlen-qend > ENDGAP_MAX) {
				if (dblen-dbend > ENDGAP_MAX)
					continue;
			}
		}
		rc = TRUE;
		maintain_hsps(MPC hlp, sgn);
		break;
	}

	if (hpr0 != hpray)
		mem_free((char *)hpr0);
	return rc;
}


/* Maintain only those HSPs located on the strand indicated by sgn */
/* Any HSPs on the other strand are removed from the linked list */
maintain_hsps(MPC hlp, sgn)
	MPDEF
	HitListPtr	hlp;
	int	sgn;
{
	register HSPPtr	hp, nhp, hplast;

	hp = hlp->hp;
	while (hp != NULL && hp->frame != sgn)
		hp = hp->next;
	hlp->hp = hplast = hp;
	if (hp == NULL)
		return;

	for (hp = hp->next; hp != NULL; hp = nhp) {
		nhp = hp->next;
		if (hp->frame == sgn) {
			hplast->next = hp;
			hplast = hp;
		}
		else {
			HSPPoolReturn(MPPTR poolp, hp);
			--hlp->hspcnt;
		}
	}
	hplast->next = NULL;
	return;
}


int
getlimits(hp, hpr0, sgn, qlen, qbeg, qend, dbbeg, dbend)
	HSPPtr	hp, *hpr0;
	int	sgn;
	Coord_t	qlen;
	Int4	*qbeg, *qend, *dbbeg, *dbend;
{
	HSPPtr	*hpr;
	int	hspcnt, i, qrc, dbrc;

	/* create a linear list of just those hits on the specified strand */
	for (hpr = hpr0; hp != NULL; hp = hp->next)
		if (hp->frame == sgn)
			*hpr++ = hp;
	hspcnt = hpr - hpr0;
	if (hspcnt == 0) /* no HSPs found on the strand indicated by sgn */
		return -1;

#if 0
	if (!gaps_ok_qpos(hpr0, hspcnt, qlen, qbeg, qend))
		return -1;

	if (!gaps_ok_dbpos(hpr0, hspcnt, dbbeg, dbend))
		return -1;
#endif
	qrc = gaps_ok_qpos(hpr0, hspcnt, qlen, qbeg, qend);
	dbrc = gaps_ok_dbpos(hpr0, hspcnt, dbbeg, dbend);
	if (!qrc && !dbrc)
		return -1;

	return 0;
}

int
gaps_ok_qpos(hpr0, hspcnt, qlen, qbeg, qend)
	HSPPtr	*hpr0;
	int	hspcnt;
	Coord_t	qlen;
	Int4	*qbeg, *qend;
{
	register HSPPtr	hp;
	register Int4	q_pos, end;

	hsort((CharPtr)hpr0, hspcnt, sizeof(HSPPtr), (int (*)())cmp_by_qpos);

	hp = *hpr0++;
	q_pos = hp->q_pos;
	if (hp->frame < 0)
		q_pos = -q_pos-1;
	*qbeg = q_pos;
	end = q_pos + hp->len - 1;
	while (--hspcnt > 0) {
		hp = *hpr0++;
		q_pos = hp->q_pos;
		if (hp->frame < 0)
			q_pos = -q_pos-1;
		if (q_pos > end+GAP_MAX)
			return 0; /* Too large a gap between HSPs */
		end = MAX(q_pos + hp->len - 1, end);
	}
	*qend = end;
	return 1;
}

int
gaps_ok_dbpos(hpr0, hspcnt, dbbeg, dbend)
	HSPPtr	*hpr0;
	int	hspcnt;
	Int4	*dbbeg, *dbend;
{
	HSPPtr	hp;
	Int4	i, s_pos, end;

	hsort((CharPtr)hpr0, hspcnt, sizeof(HSPPtr), (int (*)())cmp_by_dbpos);

	hp = *hpr0++;
	*dbbeg = s_pos = hp->s_pos;
	end = s_pos + hp->len - 1;
	while (--hspcnt > 0) {
		hp = *hpr0++;
		s_pos = hp->s_pos;
		if (s_pos > end+GAP_MAX)
			return 0; /* Too large a gap between HSPs */
		end = MAX(s_pos + hp->len - 1, end);
	}
	*dbend = end;
	return 1;
}

static int
cmp_by_qpos(h1, h2)
	register HSPPtr	*h1, *h2;
{
	if ((*h2)->frame >= 0)
		return (*h1)->q_pos - (*h2)->q_pos;
	else
		return (*h2)->q_pos - (*h1)->q_pos;
}


static int
cmp_by_dbpos(h1, h2)
	register HSPPtr	*h1, *h2;
{
	return (*h1)->s_pos - (*h2)->s_pos;
}
