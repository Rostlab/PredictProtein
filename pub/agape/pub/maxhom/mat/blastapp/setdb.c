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
/*
SETDB - Produce a protein sequence database for searching with the
programs BLASTP, BLASTX, and BLAST3.

Usage:

 	setdb [-t title] dbname

where dbname names a file containing protein sequences in FASTA format,
each separated by a single header line that begins with the character
'>' and ends with a newline character.  The optional title will be
displayed by the BLAST programs when the database is searched.

Typical sequence entries in the FASTA-format input file to the SETDB program
look like this:

>CCHU (PIR) Cytochrome c - Human
GDVEKGKKIFIMKCSQCHTVEKGGKHKTGPNLHGLFGRKTGQAPGYSYTAANKNKGIIWG
EDTLMEYLENPKKYIPGTKMIFVGIKKKEERADLIAYLKKATNE
>CCCZ (PIR) Cytochrome c - Chimpanzee (tentative sequence)
GDVEKGKKIFIMKCSQCHTVEKGGKHKTGPNLHGLFGRKTGQAPGYSYTAANKNKGIIWG
EDTLMEYLENPKKYIPGTKMIFVGIKKKEERADLIAYLKKATNE
>CCMQR (PIR) Cytochrome c - Rhesus macaque (tentative sequence)
GDVEKGKKIFIMKCSQCHTVEKGGKHKTGPNLHGLFGRKTGQAPGYSYTAANKNKGITWG
EDTLMEYLENPKKYIPGTKMIFVGIKKKEERADLIAYLKKATNE


SETDB partitions the database into three files.  For example, if the
database is named AABANK, then the three created files are named
AABANK.ahd (containing header lines), AABANK.bsq (containing
binary-encoded sequences), and AABANK.atb (containing indices).
The input FASTA-format file is not required by BLASTP, BLASTX, or BLAST3.
(A fourth type of output file, .seq, is used by GBLASTA.  Using conditional
compilation, SETDB does not ordinarily produce a .seq file.)

The database can then be searched using the command:

    blastp aabank queryseq

*/
#define I_DONT_PLAN_TO_USE_GBLASTA

#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>

#define EXTERN
#include "blastapp.h"
#include "aabet.h"	/* the alphabet */

#define ENTRY_MAX 2000000		/* maximum number of database entries */

long
		dbtype = DB_TYPE_PRO;	/* database type indicator */
long
		dbformat = AAFORMAT;	/* database format (version) indicator */

unsigned long	seq_beg[ENTRY_MAX+1],	/* file positions of sequences */
		entry,		/* actual number of database entries */
		mxlen;		/* maximum length of a database sequence */

char	*fname;		/* Basename used for the names of database files */
char	*dbtitle = "";	/* Visible string name of the database */
char	filename[FILENAME_MAX+1];
char	*buf;
size_t	bufmax;
int		long_write PROTO((long, FILE *));

main(argc,argv)
	int		argc;
	char	**argv;
{
	FILE
		*infp,	/* input file */
		*hdrfile,	/* header file */
#ifndef I_DONT_PLAN_TO_USE_GBLASTA
		*sfile,	/* sequence file */
#endif
		*bfile,	/* binary-encoded sequence file */
		*tfile;	/* tab (index) file */
	long	len;
	long	i;
	int		c, eol;
	char	*eof;
	register char	*cp, *cp2, ch, xch;
	long	totlen=0;
	long	seqcnt=0;

	module = str_dup(basename(argv[0], NULL));

	while ((c = getopt(argc, argv, "t:")) != -1)
		switch (c) {
		case 't':
			dbtitle = optarg;
			break;
		case '?':
			usage();
		}

	if (argc - optind != 1)
		usage();

	fname = argv[optind];

	infp = ckopen(fname, "r", 1);
	sprintf(filename, "%s.ahd", fname);
	hdrfile = ckopen(filename, "wb", 1);
#ifndef I_DONT_PLAN_TO_USE_GBLASTA
	sprintf(filename, "%s.seq", fname);
	sfile = ckopen(filename, "w", 1);
#endif
	sprintf(filename, "%s%s", fname, AA_SEARCHSEQ_EXT);
	bfile = ckopen(filename, "wb", 1);
	sprintf(filename, "%s.atb", fname);
	tfile = ckopen(filename, "wb", 1);

	header_beg = (unsigned long *)ckalloc(sizeof(unsigned long)*(ENTRY_MAX+1));

	/* Skip over any initial comment lines */
	do {
		eof = vfgets(&buf, &bufmax, &buf, infp);
	} while (buf[0] != '>' && eof != NULL);

	/* Add a null prefix (sentinel) byte to each database file */
#ifndef I_DONT_PLAN_TO_USE_GBLASTA
	fputc(NULLB, sfile);
#endif
	fputc(NULLB, bfile);

	for (entry = 0; eof != NULL && entry < ENTRY_MAX; entry++) {
		header_beg[entry] = ftell(hdrfile);
		/* Write the header line without a trailing newline character */
		if (fwrite(buf, strlen(buf)-1, 1, hdrfile) != 1)
			bfatal(ERR_UNDEF, "Write error on file %s.ahd", fname);
		len = 0;
		seq_beg[entry] = ftell(bfile);
		while ((eof = vfgets(&buf, &bufmax, &buf, infp)) != NULL) {
			if (*buf == '>')
				break;
			/* extract ASCII alphabetic characters and encode them in binary */
			cp = cp2 = buf;
			while ((ch = *cp++) != NULLB) {
				if ((xch = aa_atob[ch]) < AAID_MAX+1) {
#ifndef I_DONT_PLAN_TO_USE_GBLASTA
					fputc(ch, sfile);
#endif
					*cp2++ = xch;
				}
			}
			eol = cp2 - buf;
			if (fwrite(buf, 1, eol, bfile) != eol) {
				perror(module);
				exit(2);
			}

			/* tally the byte count */
			len += eol;
		}

		++seqcnt;
		totlen += len;

		/* Add a null terminator (sentinel) byte to each sequence */
#ifndef I_DONT_PLAN_TO_USE_GBLASTA
		fputc(NULLB, sfile);
#endif
		fputc(NULLB, bfile);

		if (len > mxlen) /* mxlen doesn't take null terminator into account */
			mxlen = len;
	}
	if (eof != NULL && entry >= ENTRY_MAX)
		bfatal(ERR_DBASE, "More than %s sequences in database; increase ENTRY_MAX and recompile",
			Ultostr((unsigned long)ENTRY_MAX,1));
	seq_beg[entry] = ftell(bfile);
	header_beg[entry] = ftell(hdrfile);

	fclose(hdrfile);
#ifndef I_DONT_PLAN_TO_USE_GBLASTA
	fclose(sfile);
#endif
	fclose(bfile);

	long_write(dbtype, tfile);
	long_write(dbformat, tfile);

	/* Save the database title */
	len = strlen(dbtitle) + 1;
	long_write(len, tfile);
	fwrite(dbtitle, len, 1, tfile);
	if (len%4 != 0) {
		/* pad dbtitle to a multiple of 4 bytes */
		long	i4 = 0;
		fwrite((char *)&i4, 4-(len%4), 1, tfile);
	}

	long_write(entry, tfile);
	long_write(totlen, tfile);
	long_write(mxlen, tfile);

	for (i=0; i<entry+1; ++i)
		long_write(seq_beg[i], tfile);
	for (i=0; i<entry+1; ++i)
		long_write(header_beg[i], tfile);

	printf("%s ==> %s sequences totalling %s letters\n",
			fname, Ltostr(seqcnt,1), Ltostr(totlen,1));
	printf("Maximum sequence length %s\n", Ltostr(mxlen,1));
	exit (0);
}


void
usage()
{
	fprintf(stderr,
		"Purpose:  produce a protein database for BLAST from a file in FASTA format.\n");
	fprintf(stderr, "Usage:  %s [-t title] profilename\n", module);
	exit(1);
}

int
long_write(i, fp)
	long	i;
	FILE	*fp;
{
	register CharPtr	ip;

	LONG_BIGENDIAN(i);
	ip = (CharPtr) &i;
	ip += (sizeof(long) - BO_LONG_SIZE);
	return fwrite(ip, BO_LONG_SIZE, 1, fp);
}
