#include <ncbi.h>
#include "blastapp.h"
#include "aabet.h"

/* seqfilter -- filter a sequence */
int
seqfilter(cmd, name, namelen, sp)
	CharPtr	cmd;
	CharPtr	name;
	size_t	namelen;
	BLAST_StrPtr	sp;
{
	FILE	*fp;
	CharPtr	filterdir;
	static char	permenv[2048], permenv2[2048];
	char	cmdbuf[4*FILENAME_MAX+1024];
	char	fname[FILENAME_MAX+1];
	int		omask;
	int		oframe;
	CharPtr	name_save;
	size_t	namelen_save;
	CharPtr	saveenv = NULL, tcp;
	int		i;

	errno = 0;
	if (cmd == NULL || cmd[0] == NULLB)
		return 0;
	/* No absolute or relative pathnames are permitted */
	if (cmd[0] == DIRDELIMCHR || cmd[0] == '.')
		return 1;

	omask = umask(077);

	/* Restrict system() calls to a particular directory */
	saveenv = getenv("PATH");
	filterdir = getenv("BLASTFILTER");
	if (filterdir == NULL)
		filterdir = BLASTFILTER;
	if (saveenv != NULL) {
		tcp = ckalloc(i = strlen(saveenv) + 1);
		memcpy(tcp, saveenv, i);
		saveenv = tcp;
	}
	sprintf(permenv, "PATH=%s", filterdir);
	putenv(permenv);

	name_save = sp->name;
	namelen_save = sp->namelen;
	sp->name = name;
	sp->namelen = namelen;

	fname[0] = NULLB;
	if (tmpnam(fname) == NULL)
		goto ErrReturn;
	fp = fopen(fname, "w");
	if (fp == NULL)
		goto ErrReturn;
	if (put_fasta(sp, fp) != 0)
		goto ErrReturn;
	fclose(fp);

	sprintf(cmdbuf, cmd, fname);

	fp = popen(cmdbuf, "r");
	if (fp == NULL)
		goto ErrReturn;
	if (saveenv != NULL) {
		sprintf(permenv2, "PATH=%s", saveenv);
		putenv(permenv2);
		free(saveenv);
	}

	sp->name = NULL;
	sp->namemax = sp->namelen = sp->namealloc = 0;
	oframe = sp->frame;
	if (get_fasta(sp, sp->ap, fp, TRUE, TRUE) != 0)
		goto ErrReturn;
	sp->frame = oframe;
	fflush(stderr);
	if (pclose(fp) != 0)
		goto ErrReturn;
	if (echofilter_flag)
		put_fasta(sp, stdout);
	unlink(fname);
	free(sp->name);
	(void) umask(omask);

	sp->name = name_save;
	sp->namelen = namelen_save;

	return 0;

ErrReturn:
	sp->name = name_save;
	sp->namelen = namelen_save;
	fflush(stdout);
	(void) umask(omask);
	if (errno != 0)
		perror("seqfilter");
	fflush(stderr);
	if (fname[0])
		unlink(fname);
	return 1;
}


typedef struct {
	CharPtr	name;
	BLAST_AlphaType		residue_type;
	CharPtr	command;
	} FilterList, PNTR FilterListPtr;
		
static FilterList	filterlist[] = {
		{ "seg", BLAST_ALPHATYPE_AMINO_ACID, "seg %s -x" } ,

		{ "xnu", BLAST_ALPHATYPE_AMINO_ACID, "xnu %s" } ,

		{ "seg+xnu", BLAST_ALPHATYPE_AMINO_ACID, "seg %s -x | xnu -" } ,

		{ "xnu+seg", BLAST_ALPHATYPE_AMINO_ACID, "xnu %s | seg - -x" } ,

		{ "none", BLAST_ALPHATYPE_AMINO_ACID, "" } ,
		{ "none", BLAST_ALPHATYPE_NUCLEIC_ACID, "" }
	};

CharPtr _cdecl
pick_filter(str, restype)
	register CharPtr	str;
	register BLAST_AlphaType	restype;
{
	register int		i, j;
	CharPtr	cp;
	char	estr[4096];

	if (str == NULL)
		bfatal(ERR_INVAL, "No filter method specified");

	for (i = 0; i < DIM(filterlist); ++i)
		if (restype == filterlist[i].residue_type
				&& str_casecmp(str, filterlist[i].name) == 0)
			return filterlist[i].command;

	cp = strchr(str, '%');
	if (cp != NULL && cp[1] == 's')
		return str;

	strcpy(estr, "Invalid filter option:  \"%s\".  If spelled correctly, the specified option simply may not be applicable to the type of query sequence used by this program.  The valid filters known by this program are:  ");

	for (i = j = 0; i < DIM(filterlist); ++i)
		if (restype == filterlist[i].residue_type) {
			if (j++ > 0)
				strcat(estr, ", ");
			strcat(estr, filterlist[i].name);
		}

	bfatal(ERR_INVAL, estr, str);
}
