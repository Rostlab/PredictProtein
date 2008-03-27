#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"


DBFilePtr LIBCALL
initdb(biop, dbname, restype, ddp)
	BlastIoPtr	biop;
	CharPtr	dbname;
	int		restype;
	BSRV_DbDescPtr	ddp;
{
	DBFilePtr	dbfp;
	long	totlen, count;
	FILE	*fp;

	dbfp = db_open(dbname, BLAST_DBFMT_BLAST, restype);
	if (dbfp == NULL)
		return NULL;

	if ((count = db_count(dbfp)) <= 0 || (totlen = db_totlen(dbfp)) <= 0)
		bfatal(ERR_DBASE, "There seems to be nothing in the database to search!?");

	ddp->next = NULL;
	ddp->name = StrSave(dbname);
	ddp->type = dbfp->restype;
	ddp->def = StrSave(dbfp->title);
	ddp->rel_date = (dbfp->rel_date != NULL ? StrSave(dbfp->rel_date) : NULL);
	ddp->bld_date = (dbfp->bld_date != NULL ? StrSave(dbfp->bld_date) : NULL);
	ddp->count = count;
	ddp->totlen = totlen;
	ddp->maxlen = db_maxlen(dbfp);

	if (!Z_set || Neff <= 0.)
		Neff = totlen;
	dbrecmin = MAX(dbrecmin, 0);
	dbrecmax = (dbrecmax > 0 ? MIN(dbrecmax, count) : count);
	dbreccnt = dbrecmax - dbrecmin;
	if ((fp = biop->fp) != NULL) {
		putc('\n', fp);
		wrap(fp, "Database:  ", dbfp->title, -1, 79, 11);
		fprintf(fp, "           %s sequences; %s total letters.\n",
				Ltostr(count,1), Ltostr(totlen,1));
		if (dbreccnt < count) {
			fprintf(fp, "           Subset of database from %ld to %ld.\n",
				dbrecmin+1, dbrecmax);
		}
		fflush(fp);
	}
	Bio_DbDescAsnWrite(biop, ddp);
	return dbfp;
}
