/*
	gb2fasta.c

	Convert a list of GenBank-format sequence files into FASTA format
	(for subsequent processing by PRESSDB and use by BLASTN).

	Usage:  gb2fasta gbpri.seq gbrod.seq gbmam.seq ... > genbank.total

	Suggested alternative usage:

	gb2fasta -l GenPept genpept.seq > genpept

	Tested successfully on GenBank Release 66.0

	7/22/90 WRG
*/
#include <ncbi.h>
#include <gishlib.h>

FILE	*fp;
#define BUFFER_SIZE	256
char	buf[BUFFER_SIZE];

char	*label = "gb";
char	*module;
char	locus[128];
char	accession[128];
char	definition[4096];

main(ac, av)
	int		ac;
	char	**av;
{
	FILE	*fdopen();
	int		i, len, len2;
	register char	*cp, ch;

	module = str_dup(basename(av[0], NULL));

	if (ac == 2 && strcmp(av[1], "-") == 0)
		optind = ac-1;
	else
		while ((i = getopt(ac, av, "l:")) != -1)
			switch (i) {
			case 'l':
				label = optarg;
				continue;
			default:
				usage();
			}

	if (ac == optind)
		usage();

	for (i = optind; i < ac; ++i) {
		fp = openfile(av[i], "rb");
		if (fp == NULL)
			goto NextFile;

		for (;/* Each Nt. Sequence */;) {
			locus[0] = accession[0] = definition[0] = NULLB;
			for (;/* Each Record */;) {
				if (fgets(buf, BUFFER_SIZE, fp) == NULL)
					goto NextFile;
Switch:
				switch (buf[0]) {
				case 'L':
					if (strncmp(buf, "LOCUS", 5))
						continue;
					get_locus(buf);
					continue;
				case 'D':
					if (strncmp(buf, "DEFINITION", 10))
						continue;
					get_definition(buf);
					goto Switch;
				case 'A':
					if (strncmp(buf, "ACCESSION", 9))
						continue;
					if (accession[0] != NULLB)
						continue;
					if (strtok(buf, " \t\n\r") != NULL) {
						cp = strtok(NULL, " \t\n\r");
						if (cp != NULL)
							strcpy(accession, cp);
					}
					continue;
				case 'O':
					if (strncmp(buf, "ORIGIN", 6) == 0)
						goto GetSeq;
					continue;
				default:
					continue;
				}
			}

GetSeq:
			putchar('>');
			if (label[0] != NULLB)
				fputs(label, stdout);
			else
				fputs("???", stdout);
			putchar('|');
			if (accession[0] != NULLB)
				fputs(accession, stdout);
			putchar('|');
			if (locus[0] != NULLB)
				fputs(locus, stdout);

			if (definition[0]) {
				putchar(' ');
				fputs(definition, stdout);
			}
			putchar('\n');

			while (fgets(buf, BUFFER_SIZE, fp) != NULL && buf[0] != '/') {
				cp = buf;
				while ((ch = *cp++) != NULLB)
					if (isalpha(ch)) {
						if (islower(ch))
							ch = toupper(ch);
						putchar(ch);
					}
				putchar('\n');
			}

		} /* for (;;) */
		

NextFile:
		if (fp != NULL)
			fclose(fp);
		continue;
	}
	exit(0);
}


int
get_locus(buf)
	register CharPtr	buf;
{
	register CharPtr	cp;
	register int	ch, len;

	if (locus[0] != NULLB) {
		fprintf(stderr, "\nLOCUS without a sequence\n");
		fprintf(stderr, "LOCUS %s\n", locus);
		exit(1);
	}
	cp = buf+5;
	while (*cp != NULLB && isspace(*cp))
		++cp;
	for (len = 0; (ch = *cp) != NULLB && !isspace(ch); ++cp) {
		locus[len++] = ch;
	}
	locus[len] = NULLB;
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
	while (fgets(buf, BUFFER_SIZE, fp) != NULL &&
				buf[0] == ' ') {
		cp = buf+1;
		while ((ch = *cp) != NULLB && isspace(ch))
			++cp;
		if (ch != NULLB) {
			len2 = strlen(cp) - 1;
			definition[len++] = ' ';
			Nlm_MemCpy(definition + len, cp, len2);
			len += len2;
			definition[len] = NULLB;
		}
	}
	if (len == 1 && definition[0] == '.')
		strcpy(definition, "No DEFINITION available");
	return 0;
}


usage()
{
	fprintf(stderr, "Purpose:  convert a GenBank-format file into FASTA format.\n");
	fprintf(stderr, "Usage:  %s [-l label] dbfile\n", module);
	exit(1);
}
