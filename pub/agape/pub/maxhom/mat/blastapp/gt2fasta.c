/* ===========================================================================
*
*                            PUBLIC DOMAIN NOTICE
*               National Center for Biotechnology Information
*
*  This software/database is a "United States Government Work" under the
*  terms of the United States Copyright Act.  It was written as part of
*  the author's official duties as a United States Government employee and
*  thus cannot be copyrighted.  This software/database is freely available
*  to the public for use. The National Library of Medicine and the U.S.
*  Government have not placed any restriction on its use or reproduction.
*
*  Although all reasonable efforts have been taken to ensure the accuracy
*  and reliability of the software and data, the NLM and the U.S.
*  Government do not and cannot warrant the performance or results that
*  may be obtained by using this software or data. The NLM and the U.S.
*  Government disclaim all warranties, express or implied, including
*  warranties of performance, merchantability or fitness for any particular
*  purpose.
*
*  Please cite the author in any work or product based on this material.
*
* ===========================================================================*/

/*
	gt2fasta.c

	Extract protein sequences from the CDS features of GenBank-format sequence
	files and produce output in FASTA format (for subsequent processing by
	SETDB, followed by searching with BLASTP).

	Usage:  gt2fasta gbpri.seq gbrod.seq gbmam.seq ... > genbank.total

	Tested successfully on GenBank Release 73.1

	June 1992 WRG
*/
#include <ncbi.h>
#include <gishlib.h>

#define BUFFER_SIZE	256

FILE	*fp;
char	buf[BUFFER_SIZE];

char	locus[80], accession[80], definition[1024];
char	organism[1024], source[1024];
char	*label = "gp";
char	*module;

main(ac, av)
	int		ac;
	char	**av;
{
	FILE	*fdopen();
	int		fcnt, i, j, len;
	register char	*cp, ch;

	module = str_dup(basename(av[0], NULL));

	if (ac == 2 && strcmp(av[1], "-") == 0)
		optind = ac - 1;
	else
		while ((i = getopt(ac, av, "l:")) != -1)
			switch (i) {
			case 'l':
				label = optarg;
				continue;
			case '?':
			default:
				usage();
			}

	if (optind >= ac)
		usage();

	for (fcnt = optind; fcnt<ac; ++fcnt) {
		fp = openfile(av[fcnt], "rb");
		if (fp == NULL)
			goto NextFile;


		for (;/* Each Nt. Sequence */;) {
			locus[0] = accession[0] = definition[0]
				= source[0] = organism[0] = NULLB;
			for (; /* Each Record */;) {
				if (fgets(buf, BUFFER_SIZE-1, fp) == NULL)
					goto NextFile;
Switch:
				switch (buf[0]) {
				case 'L':
					if (strncmp(buf, "LOCUS", 5) != 0)
						continue;
					get_locus(buf);
					continue;
				case 'D':
					if (strncmp(buf, "DEFINITION", 10) != 0)
						continue;
					get_definition(buf);
					goto Switch;
				case 'A':
					if (strncmp(buf, "ACCESSION", 9) != 0)
						continue;
					if (accession[0] != NULLB)
						continue;
					if ((cp = strtok(buf+9, " \t\n\r")) != NULL)
						strcpy(accession, cp);
					continue;
				case 'F':
					if (strncmp(buf, "FEATURE", 7) != 0)
						continue;
					parse_translations(buf);
					continue;
				case 'S':
					if (strncmp(buf, "SOURCE", 6) != 0)
						continue;
					strncpy(source, buf+12, sizeof(source)-1);
					strip(source);
					continue;
				case ' ':
					if (buf[2] != 'O' || strncmp(buf+2, "ORGANISM", 8) != 0)
						continue;
					strncpy(organism, buf+12, sizeof(organism)-1);
					strip(organism);
					continue;
				case '/':
					goto NextSequence;
				default:
					continue;
				}
			}
NextSequence:
			continue;
		} /* for (;;) */
		

NextFile:
		if (fp != NULL)
			fclose(fp);
		fp = NULL;
		continue;
	}
	exit(0);
}

int
get_locus(buf)
	CharPtr	buf;
{
	register CharPtr	cp;
	register int	i;
	register char	ch;

	if (locus[0] != NULLB) {
		fprintf(stderr, "\nLOCUS without sequence\n");
		fprintf(stderr, "LOCUS %s\n", locus);
		exit(1);
	}
	strcpy(locus, strtok(buf+6, " \t\r\n"));
	return 0;
}


int
get_definition(buf)
	register CharPtr	buf;
{
	register CharPtr	cp;
	register int		ch, len, len2;

	if (definition[0] != NULLB) {
		fprintf(stderr, "\nDuplicate DEFINITION records for a single sequence\n");
		if (locus[0])
			fprintf(stderr, "LOCUS %s\n", locus);
		exit(2);
	}

	cp = buf+10;
	while ((ch = *cp) != NULLB && isspace(ch))
		++cp;
	definition[len = 0] = NULLB;
	if (ch != NULLB) {
		len = strlen(cp) - 1;
		Nlm_MemCpy(definition, cp, len);
		definition[len] = NULLB;
	}
	while (fgets(buf, BUFFER_SIZE-1, fp) != NULL &&
				buf[0] == ' ') {
		cp = buf+1;
		while ((ch = *cp) != NULLB && isspace(ch))
			++cp;
		if (ch != NULLB) {
			len2 = strlen(cp) - 1;
			definition[len++] = ' ';
			Nlm_MemCpy(definition + len, cp, len2);
			len += len2;
			definition[len += len2] = NULLB;
		}
	}
	return 0;
}

int
parse_translations(buf)
	CharPtr	buf;
{
	char	tmpprod[1024], product[1024];
	int		i, j, cdsno, nametype, prodtype;

	cdsno = 0;
	for (;;) {
		do {
			if (fgets(buf, BUFFER_SIZE-1, fp) == NULL)
				return 1;
		} while (buf[0] == ' ' && strncmp(buf, "     CDS", 8) != 0);
		if (buf[0] != ' ')
			break;
		prodtype = -1;
		do {
Product0:
			if (fgets(buf, BUFFER_SIZE-1, fp) == NULL)
				return 0;
Product:
			if (strncmp(buf+21, "/translation=", 13) == 0)
				goto Translation;
			if (buf[0] != ' ')
				return 0;
		} while (strncmp(buf+21, "/product=", 9) && strncmp(buf+21, "/gene=", 6) && strncmp(buf+21, "/note=", 6));
		if (strncmp(buf+21, "/note=", 6) == 0)
			nametype = 1;
		else
		if (strncmp(buf+21, "/gene=", 6) == 0)
			nametype = 2;
		else
		if (strncmp(buf+21, "/product=", 9) == 0)
			nametype = 3;
		strip(buf);
		strcpy(tmpprod, " ");
		strcat(tmpprod, strchr(buf+21, '=')+2);
		j = 0;
ProdLoop:
		i = strlen(tmpprod);
		if (tmpprod[i-1] != '"') {
			if (fgets(buf, BUFFER_SIZE-1, fp) == NULL)
				return 1;
			j = 1;
			if (buf[21] != '/') {
				strip(buf);
				strcat(tmpprod, " ");
				strcat(tmpprod, buf+21);
				goto ProdLoop;
			}
		}
		tmpprod[i-1] = NULLB;
		if (nametype == 2)
			strcat(tmpprod, " gene product");
		if (nametype > prodtype) {
			strcpy(product, tmpprod);
			prodtype = nametype;
		}
		if (j == 0)
			goto Product0;
		goto Product;

Translation:
		printf(">%s|%s|%s_%d", label, accession, locus, ++cdsno);

		switch (prodtype) {
		case -1:
		case 1:
			printf(" %s", definition);
			break;
		case 2:
		case 3:
			printf("%s", product);
			break;
		}
		if (organism[0] == NULLB || strncasecmp(organism, "Unclass", 7) == 0 &&
				source[0] != NULLB)
			strcpy(organism, source);
		printf(" [%s]\n", organism);

		strcpy(buf, buf+14);
TransLoop:
		i = strlen(buf);
		buf[--i] = NULLB;
		if (buf[i-1] == '"') {
			buf[i-1] = NULLB;
			i = -1;
		}
		printf("%s\n", buf+21);
		if (i < 0)
			continue;
		if (fgets(buf, BUFFER_SIZE-1, fp) == NULL)
			return 1;
		goto TransLoop;
	}
	fflush(stdout);
	return 0;
}


int
strip(s)
	char	*s;
{
	int	i;

	i = strlen(s)-1;
	while (i >= 0 && (s[i] == '\n' || isspace(s[i])))
		s[i--] = NULLB;
}

usage()
{
	fprintf(stderr, "Purpose:  convert a GenBank-format file into FASTA format.\n");
	fprintf(stderr, "Usage:  %s [-l label] dbfile\n", module);
	exit(1);
}
