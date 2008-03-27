#include <ncbi.h>
#include <blastapp.h>

main(ac, av)
	int	ac;
	char	**av;
{
	int		fcnt;
	int		hadanerror = 0;

	if (ac < 2)
		usage();

	for (fcnt = 1; fcnt < ac; ++fcnt) {
		if (get_desc(av[fcnt]) == 0) {
			put_desc();
			fflush(stdout);
		}
		else {
			hadanerror = 1;
			fprintf(stderr, "Error on file:  %s\n", av[fcnt]);
		}
	}

	exit(hadanerror);
}

void
usage()
{
	fprintf(stderr, "\nUsage:  dbinfo dbfilelist\n");
	exit(1);
}

char	*reldate, moddate[64], *dbtypestr;
long	dbtype, dbformat, dbtitlelen, nseqs, dbtotlen, maxlen, fill;
char	*dbname, *dbtitle;

int
get_desc(filename)
	char	*filename;
{
	char	*find_dbfile();
	struct stat	statbuf;
	struct tm	*tp;
	char	*cp, *cp2;
	MFILE	*mfp;
	int		i;

	filename = find_dbfile(filename);
	if (filename == NULL)
		return 1;

	if (stat(filename, &statbuf) == -1)
		return 1;
	tp = localtime(&statbuf.st_mtime);
	strftime(moddate, DIM(moddate)-1, "%r %Z %h %d, %Y" , tp);
	if (moddate[20] == '0')
		strcpy(moddate+20, moddate+21);
	strcpy(moddate+5, moddate+8);
	if (moddate[0] == '0')
		strcpy(moddate, moddate+1);

	mfp = mfil_open(filename, "rb", MFIL_OPT_NONE);
	if (mfp == NULL)
		return 1;

	cp = basename(filename, NULL);
	cp2 = strrchr(cp, '.');
	if (cp2 != NULL)
		*cp2 = NULLB;
	dbname = strdup(cp);
	if (cp2 != NULL)
		*cp2 = '.';

	if (mfil_dup_long(mfp, &dbtype, 1) != 1)
		goto ErrReturn;
	if (mfil_dup_long(mfp, &dbformat, 1) != 1)
		goto ErrReturn;
	if (dbtype == DB_TYPE_PRO) {
		dbtype = 1;
		dbtypestr = "aa";
		if (dbformat != AAFORMAT)
			goto ErrReturn;
	}
	else
		if (dbtype == DB_TYPE_NUC) {
			dbtype = 2;
			dbtypestr = "nt";
			if (dbformat != NTFORMAT)
				goto ErrReturn;
		}
		else
			dbtype = 0, dbtypestr = "not-set";

	if (mfil_dup_long(mfp, &dbtitlelen, 1) != 1)
		goto ErrReturn;
	if (dbtitlelen > 1) {
		dbtitle = mfil_get(mfp, dbtitlelen);
		if (dbtitle == NULL)
			goto ErrReturn;
		if (dbtitlelen % 4 != 0) {
			i = 4 - (dbtitlelen % 4);
			mfil_seek(mfp, i, SEEK_CUR);
		}
		parse_reldate(dbtitle);
	}
	else {
		dbtitle = strdup(dbname);
		parse_reldate("");
	}

	if (dbtype == 2) {
		if (mfil_dup_long(mfp, &fill, 1) != 1) /* FASTA line length */
			goto ErrReturn;
	}

	if (mfil_dup_long(mfp, &nseqs, 1) != 1)
		goto ErrReturn;
	if (dbtype == 1) {
		if (mfil_dup_long(mfp, &dbtotlen, 1) != 1)
			goto ErrReturn;
		if (mfil_dup_long(mfp, &maxlen, 1) != 1)
			goto ErrReturn;
	}
	else
		if (dbtype == 2) {
			if (mfil_dup_long(mfp, &maxlen, 1) != 1)
				goto ErrReturn;
			if (mfil_dup_long(mfp, &dbtotlen, 1) != 1)
				goto ErrReturn;
		}

	mfil_close(mfp);
	return 0;

ErrReturn:
	mfil_close(mfp);
	return 1;
}

int
parse_reldate(str)
	char	*str;
{
	char	*cp, *newstr;
	char	*word[200];
	int		nwords = 0, wordoff[DIM(word)];
	int		i, j, iy;

	reldate = NULL;

	newstr = strdup(str);
	cp = strtok(newstr, " \t\n\r,.");
	if (cp != NULL) {
		wordoff[0] = cp - newstr;
		word[nwords++] = cp;
		while ((cp = strtok(NULL, " \t\n\r,.")) != NULL) {
			wordoff[nwords] = cp - newstr;
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
				cp = str + wordoff[i];
				while (cp > str && *cp != ',') {
					--cp;
				}
				if (cp <= str)
					break;
				*cp = NULLB;
				do {
					++cp;
				} while (isspace(*cp));
				str[wordoff[iy] + 4] = NULLB;
				reldate = strdup(cp);
				break;
			}
		}
	}

	free(newstr);
	if (reldate == NULL)
		reldate = strdup("");
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

int
put_desc()
{
	printf("%s\n", dbname);
	free(dbname);
	printf("%u\n", dbtype);
	printf("%s\n", dbtitle);
	free(dbtitle);
	printf("%s\n", reldate);
	printf("%s\n", moddate);
	free(reldate);
	printf("%lu\n", nseqs);
	printf("%lu\n", dbtotlen);
	printf("%lu\n", maxlen);
	putc('/', stdout);
	putc('/', stdout);
	putc('\n', stdout);
	return 0;
}

char *
find_dbfile(fname)
	char	*fname;
{
	static char	fnbuf[FILENAME_MAX];
	struct stat	sbuf;
	char	*cp;

	if (stat(fname, &sbuf) == 0)
		return fname;

	cp = getenv("BLASTDB");
	if (cp != NULL) {
		sprintf(fnbuf, "%s/%s", cp, fname);
		if (stat(fnbuf, &sbuf) == 0)
			return fnbuf;
	}
#ifdef BLASTDB
	sprintf(fnbuf, "%s/%s", BLASTDB, fname);
	if (stat(fnbuf, &sbuf) == 0)
		return fnbuf;
#endif
	return NULL;
}
