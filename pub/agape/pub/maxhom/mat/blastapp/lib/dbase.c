#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"


DBFilePtr LIBCALL
db_open(dbname, dbformat, restype)
	CharPtr	dbname;
	DBFormat	dbformat;
	int		restype;
{
	DBFilePtr	dbfp;

	switch (dbformat) {
	case BLAST_DBFMT_BLAST:
		dbfp = blast_db_open(dbname, restype);
		dbfp->magic = DBFILE_MAGIC;
		return dbfp;
	default:
		return NULL;
	}
	/*NOTREACHED*/
}

int LIBCALL
db_close(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return NULL;
	return dbfp->close(dbfp);
}

DBFilePtr LIBCALL
db_link(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return NULL;
	return dbfp->link(dbfp);
}

int LIBCALL
db_get_seq(dbfp, sp)
	DBFilePtr	dbfp;
	BLAST_StrPtr	sp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC || sp == NULL)
		return -1;
	return dbfp->get_seq(dbfp, sp);
}

int LIBCALL
db_ambig_avail(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return -1;
	return dbfp->ambig_avail(dbfp);
}

int LIBCALL
db_ambiguous(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return -1;
	return dbfp->ambiguous(dbfp);
}

int LIBCALL
db_get_specific(dbfp, sp, offset, len)
	DBFilePtr	dbfp;
	BLAST_StrPtr	sp;
	size_t	offset;
	size_t	len;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return -1;
	return dbfp->get_specific(dbfp, sp, offset, len);
}

int LIBCALL
db_get_str_specific(dbfp, ap, str, offset, len)
	DBFilePtr	dbfp;
	BLAST_AlphabetPtr	ap;
	BLAST_LetterPtr	str;
	size_t	offset;
	size_t	len;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return -1;
	return dbfp->get_str_specific(dbfp, ap, str, offset, len);
}

int LIBCALL
db_get_header(dbfp, sp)
	DBFilePtr	dbfp;
	BLAST_StrPtr	sp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC || sp == NULL)
		return -1;
	return dbfp->get_header(dbfp, sp);
}

int LIBCALL
db_seek(dbfp, id)
	DBFilePtr	dbfp;
	long	id;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return -1;
	return dbfp->seek(dbfp, id);
}

long LIBCALL
db_count(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return -1;
	return dbfp->count(dbfp);
}

long LIBCALL
db_totlen(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return -1;
	return dbfp->totlen(dbfp);
}

long LIBCALL
db_maxlen(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->magic != DBFILE_MAGIC)
		return -1;
	return dbfp->maxlen(dbfp);
}

/************** utility functions *************/
CharPtr LIBCALL
get_moddate(fname)
	CharPtr	fname;
{
	char	moddate[64];
	struct stat	statbuf;
	struct tm	*tp;
	CharPtr	cp;

	if (fname == NULL || stat(fname, &statbuf) == -1)
		return NULL;

	tp = localtime(&statbuf.st_mtime);
	strftime(moddate, DIM(moddate)-1, "%r %Z %h %d, %Y" , tp);
	if (moddate[20] == '0')
		strcpy(moddate+20, moddate+21);
	strcpy(moddate+5, moddate+8);
	cp = moddate;
	if (cp[0] == '0')
		++cp;
	return StrSave(cp);
}

CharPtr
get_reldate(defline)
	CharPtr	defline;
{
	static char	tokstr[] = " \t\n\r,.";
	CharPtr	cp, newdef, reldate;
	char	*word[200];
	int		nwords = 0, wordoff[DIM(word)];
	int		i, j, iy;

	if (defline == NULL)
		return NULL;

	reldate = NULL;
	newdef = StrSave(defline);
	if (newdef == NULL)
		return NULL;

	cp = strtok(newdef, tokstr);
	if (cp != NULL) {
		wordoff[0] = cp - newdef;
		word[nwords++] = cp;
		while ((cp = strtok(NULL, tokstr)) != NULL) {
			wordoff[nwords] = cp - newdef;
			word[nwords++] = cp;
		}
	}

	for (i = nwords; --i > 2; ) {
		if (isyear(word[i]))
			break;
	}
	if (i > 2) {
		iy = i;
		for (i = iy-1; i > 2; --i) {
			cp = word[i];
			if (ismonth(cp)) {
				cp = defline + wordoff[i];
				while (cp > defline && *cp != ',') {
					--cp;
				}
				if (cp <= defline)
					break;
				*cp = NULLB;
				do {
					++cp;
				} while (isspace(*cp));
				defline[wordoff[iy] + 4] = NULLB;
				reldate = StrSave(cp);
				break;
			}
		}
	}

	Nlm_Free(newdef);
	return reldate;
}

int
isyear(cp)
	char	*cp;
{
	if (strlen(cp) != 4)
		return 0;

	if (!isdigit(cp[0]) || !isdigit(cp[1]) || !isdigit(cp[2]) || !isdigit(cp[3]))
		return 0;

	if (cp[0] == '1' && cp[1] == '9')
		return 1;
	if (cp[0] == '2' && cp[2] == '0')
		return 1;
	return 0;
}

ismonth(cp)
	char	*cp;
{
	static char	*monray[] = {
		"January", "February", "March", "April", "May", "June", "July",
		"August", "September", "October", "November", "December"
		};
	static int	monlen[] = {
		7, 8, 5, 5, 3, 4, 4, 6, 9, 7, 8, 8
		};
	int		i, cplen, len;

	cplen = strlen(cp);
	for (i = 0; i < DIM(monray); ++i) {
		if (cplen > monlen[i])
			continue;
		if (cplen == monlen[i]) {
			if (strcasecmp(cp, monray[i]) == 0)
				return 1;
		}
		else
			if (strncasecmp(cp, monray[i], cplen) == 0)
				return 1;
	}

	return 0;
}
