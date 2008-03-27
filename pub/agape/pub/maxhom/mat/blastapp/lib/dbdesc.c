#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"


int LIBCALL
get_dbdesc_bld_date(ddp, filename)
	BSRV_DbDescPtr	ddp;
	char	*filename;
{
	char	moddate[64];
	struct stat	statbuf;
	struct tm	*tp;
	char	*cp, *cp2;
	int		i;

	if (filename == NULL || stat(filename, &statbuf) == -1)
		return 1;
	tp = localtime(&statbuf.st_mtime);
	strftime(moddate, DIM(moddate)-1, "%r %Z %h %d, %Y" , tp);
	if (moddate[20] == '0')
		strcpy(moddate+20, moddate+21);
	strcpy(moddate+5, moddate+8);
	cp = moddate;
	if (cp[0] == '0')
		++cp;
	ddp->bld_date = StrSave(cp);
	return ddp->bld_date == NULL;
}

int
get_dbdesc_rel_date(ddp)
	BSRV_DbDescPtr	ddp;
{
	static char	tokstr[] = " \t\n\r,.";
	CharPtr	cp, defline, newdef, reldate;
	char	*word[200];
	int		nwords = 0, wordoff[DIM(word)];
	int		i, j, iy;

	if (ddp == NULL)
		return 1;
	if ((defline = ddp->def) == NULL)
		return 0;

	reldate = NULL;
	newdef = StrSave(defline);
	if (newdef == NULL)
		return 1;

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

	free(newdef);
	ddp->rel_date = reldate;
	return 0;
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
