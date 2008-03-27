#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

BSRV_DbDescPtr _cdecl dbdesc_get PROTO((BSRV_DbDescPtr ddp, CharPtr dbinfodir, CharPtr dbname));
BSRV_DbInfoPtr _cdecl dbinfo_find PROTO((BSRV_DbInfoPtr dip, CharPtr dbname));

BSRV_DbInfoPtr _cdecl
dbinfo_get(CharPtr dbinfodir, CharPtr configdir, CharPtr group)
{
	char	buf[512];
	char	fname[FILENAME_MAX+1];
	FILE	*permfp, *infofp;
	BSRV_DbDesc	desc;
	BSRV_DbInfoPtr	dip0 = NULL, dip, dip2;
	CharPtr	cp;
	int		retval;

	sprintf(fname, "%s/dbperm.%s", configdir, group);
	permfp = fopen(fname, "r");
	if (permfp == NULL)
		return NULL;
	while (fgets(buf, sizeof buf, permfp) != NULL) {
		cp = strchr(buf, '#');
		if (cp != NULL)
			*cp = NULLB;
		if (buf[0] == NULLB)
			continue;
		cp = strtok(buf, " \t\n\r");
		if (cp == NULL)
			continue;

		MemSet((VoidPtr)&desc, 0, sizeof(desc));
		if (dbdesc_get(&desc, dbinfodir, cp) == NULL)
			continue;

		dip2 = (BSRV_DbInfoPtr)ckalloc0(sizeof(*dip2));
		if (dip0 == NULL)
			dip0 = dip2;
		else
			dip->next = dip2;
		dip = dip2;
		dip->dbname = MemDup(cp, strlen(cp)+1);
		MemCpy((VoidPtr)&dip->desc, (VoidPtr)&desc, sizeof(dip->desc));
		/* read the list of the programs that can be used with this database */
		while (cp = strtok(NULL, " \t\n\r")) {
			(void) ValNodeCopyStr(&dip->progs, 0, cp);
		}
	}

	dblist_get(dip0, configdir, "dblist");

	return dip0;
}

BSRV_DbDescPtr _cdecl
dbdesc_get(BSRV_DbDescPtr ddp, CharPtr dbinfodir, CharPtr dbname)
{
	BSRV_DbDescPtr	ddp0 = ddp;
	char	fname[FILENAME_MAX+1];
	FILE	*fp;
	char	buf[256];
	long	count, totlen, maxlen;
	int		dbtype;

	sprintf(fname, "%s/%s", dbinfodir, dbname);
	fp = fopen(fname, "r");
	if (fp == NULL)
		return NULL;
	if (ddp == NULL) {
		ddp = (BSRV_DbDescPtr)ckalloc0(sizeof(*ddp));
	}
	if (fgets(buf, sizeof buf, fp) == NULL)
		goto Error;
	strtrunc(buf);
	ddp->name = StrSave(buf);
	if (fscanf(fp, "%d\n", &dbtype) != 1)
		dbtype = 0;
	ddp->type = dbtype;
	if (fgets(buf, sizeof buf, fp) == NULL)
		goto Error;
	strtrunc(buf);
	if (buf[0] != NULLB)
		ddp->def = Nlm_StrSave(buf);
	if (fgets(buf, sizeof buf, fp) == NULL)
		goto Error;
	strtrunc(buf);
	if (buf[0] != NULLB)
		ddp->rel_date = Nlm_StrSave(buf);
	if (fgets(buf, sizeof buf, fp) == NULL)
		goto Error;
	strtrunc(buf);
	if (buf[0] != NULLB)
		ddp->bld_date = Nlm_StrSave(buf);
	if (fscanf(fp, "%ld\n", &count) != 1)
		count = -1;
	if (fscanf(fp, "%ld\n", &totlen) != 1)
		totlen = -1;
	if (fscanf(fp, "%ld\n", &maxlen) != 1)
		maxlen = -1;
	ddp->count = count;
	ddp->totlen = totlen;
	ddp->maxlen = maxlen;
	fclose(fp);
	return ddp;
Error:
	fclose(fp);
	mem_free(ddp->name);
	mem_free(ddp->def);
	mem_free(ddp->rel_date);
	mem_free(ddp->bld_date);
	if (ddp != ddp0)
		mem_free(ddp);
	return NULL;
}

int _cdecl
dblist_get(BSRV_DbInfoPtr dip0, CharPtr configdir, CharPtr dblist)
{
	BSRV_DbInfoPtr	dip, dip2;
	char	fname[FILENAME_MAX+1];
	char	buf[1024];
	CharPtr	cp, cpmax, cp2;
	FILE	*fp;

	if (dip0 == NULL || configdir == NULL || dblist == NULL)
		return 1;

	sprintf(fname, "%s/%s", configdir, dblist);
	fp = fopen(fname, "r");
	if (fp == NULL)
		return 1;

	while (fgets(buf, sizeof buf, fp) != NULL) {
		cp = strchr(buf, '#');
		if (cp != NULL)
			*cp = NULLB;
		if (buf[0] == NULLB)
			continue;
		cp = strtok(buf, " \t\n\r");
		if (cp == NULL)
			continue;
		dip = dbinfo_find(dip0, cp);
		if (dip == NULL)
			continue;
		if ((cp = strtok(NULL, " \t\n\r")) == NULL) /* dbtags */
			continue;
		if (strcmp(cp, "*") != 0) {
			cpmax = cp + strlen(cp);
			while (cp < cpmax) {
				if ((cp2 = strchr(cp, ',')) != NULL)
					*cp2 = NULLB;
				else
					cp2 = cpmax;
				ValNodeCopyStr(&dip->dbtags, 0, cp);
				cp = cp2 + 1;
			}
		}

		if ((cp = strtok(NULL, " \t\n\r")) == NULL) /* divisions */
			continue;
		dbinfo_dbstr_parse(dip0, &dip->divisions, cp);
		if ((cp = strtok(NULL, " \t\n\r")) == NULL) /* updatedby */
			continue;
		dbinfo_dbstr_parse(dip0, &dip->updatedby, cp);

		if ((cp = strtok(NULL, " \t\n\r")) == NULL) /* contains */
			continue;
		dbinfo_dbstr_parse(dip0, &dip->contains, cp);

		if ((cp = strtok(NULL, " \t\n\r")) == NULL) /* derivof */
			continue;
		dbinfo_dbstr_parse(dip0, &dip->derivof, cp);
	}
	fclose(fp);
	return 0;
}

int _cdecl
dbinfo_dbstr_parse(dip0, vnpp, cp)
	BSRV_DbInfoPtr	dip0;
	ValNodePtr	PNTR vnpp;
	CharPtr	cp;
{
	BSRV_DbInfoPtr	dip;
	CharPtr	cpmax, cp2;

	if (strcmp(cp, "*") != 0) {
		cpmax = cp + strlen(cp);
		while (cp < cpmax) {
			if ((cp2 = strchr(cp, ',')) != NULL)
				*cp2 = NULLB;
			else
				cp2 = cpmax;
			dip = dbinfo_find(dip0, cp);
			if (dip != NULL && dip->desc.name != NULL)
				if (ValNodeAddPointer(vnpp, 0, (Nlm_VoidPtr)dip) == NULL)
					return 1;
			cp = cp2 + 1;
		}
	}
	return 0;
}

BSRV_DbInfoPtr _cdecl
dbinfo_find(BSRV_DbInfoPtr dip, CharPtr dbname)
{
	while (dip != NULL) {
		if (strcmp(dip->dbname, dbname) == 0)
			return dip;
		dip = dip->next;
	}
	return NULL;
}
