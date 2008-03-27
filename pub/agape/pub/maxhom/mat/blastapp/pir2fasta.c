#include <ncbi.h>
#include <gishlib.h>
#ifdef VAR_ARGS
#include <varargs.h>
#else
#include <stdarg.h>
#endif

#define EXTERN
#include "blastapp.h"

#define TOKSTR	" \t\n\r"

char	*module;
long	nseqs, nseqs0;

typedef struct fielddef {
		CharPtr	str;
		int		len;
	} FieldDef, PNTR FieldDefPtr;

FieldDef	field[] = {
	/* list these items in alphabetical order! */
	{ "///", 3 },
	{ "ACCESSION", 9 },
	{ "ENTRY", 5 },
	{ "PLACEMENT", 9 },
	{ "SEQUENCE", 8 },
	{ "TITLE", 5 }
	};
#define EOR_ID	0 /* end of record */
#define ACCESSION_ID	1
#define ENTRY_ID	2
#define PLACEMENT_ID	3
#define SEQUENCE_ID	4
#define TITLE_ID	5

char	*label = "pir";
char	*title, *title1, *entry, *placement, *placement1, *accession;
size_t	title_max, entry_max, placement_max, accession_max;
FILE	*outfp;

extern int	optind; extern char *optarg;

main(argc, argv)
	int		argc;
	char	**argv;
{
	char	buf[256], *filename;
	char	*pcp;
	register char	*cp, ch;
	register int	len;
	FILE	*fp;
	int		c, fno, fi, lastfi, lc;

	outfp = stdout;

	module = str_dup(basename(argv[0], NULL));

	if (argc == 2 && strcmp(argv[1], "-") == 0)
		optind = argc - 1;
	else
		while ((c = getopt(argc, argv, "l:")) != -1)
			switch (c) {
			case 'l':
				label = optarg;
				continue;
			default:
				usage();
			}

	if (argc <= optind)
		usage();

	for (fno = optind; fno < argc; ++fno) {
		fp = openfile(filename = argv[fno], "r");
		if (fp == NULL)
			continue;

		/* Skip any initial file header */
		while ((cp = fgets(buf, sizeof buf, fp)) != NULL) {
			if (strncmp(buf, "\\\\\\", 3) == 0)
				break;
		}
		if (cp == NULL)
			bfatal(ERR_DBASE, "Premature EOF:  %s", filename);

		nseqs = 0;

		lastfi = -1;
		for (; fgets(buf, sizeof buf, fp) != NULL;) { /* break on error / EOF */
Search:
			cp = buf;
			ch = *cp;
			for (fi = 0; fi < DIM(field); ++fi) {
				if (ch < field[fi].str[0])
					break;
				if (ch == field[fi].str[0]
						&& strncmp(cp, field[fi].str, field[fi].len) == 0)
					goto Found;
			}
			if (cp == NULL) {
				if (lastfi == -1)
					break;
				bfatal(ERR_DBASE, "Premature EOF:  %s", filename);
			}
			continue;

Found:
			switch (fi) {
			case EOR_ID:
				lastfi = -1;
				if (title) title[0] = NULLB;
				if (entry) entry[0] = NULLB;
				if (placement) placement[0] = NULLB;
				if (accession) accession[0] = NULLB;
				break;

			case ENTRY_ID:
				if (lastfi != -1)
					bfatal(ERR_DBASE, "Fields out of order at seq. no. %d", nseqs);
				/* Parse and save the entry name */
				cp = str_tok(buf, TOKSTR);
				cp = str_tok(NULL, TOKSTR);
				vstr_cpy(&entry, &entry_max, entry, cp);
				lastfi = ENTRY_ID;
				continue;

			case TITLE_ID:
				/* Parse and save the TITLE line plus continuation lines */
				cp += field[TITLE_ID].len;
				title1 = title;
				do {
					while (*cp != NULLB && isspace(*cp))
						++cp;
					title1 = vstr_cpy(&title, &title_max, title1, " ");
					title1 = vstr_cpy(&title, &title_max, title1, cp);
					if (title1[-1] == '\n')
						*--title1 = NULLB;
				} while ((cp = fgets(buf, sizeof(buf), fp)) != NULL
							&& *cp != NULLB && isspace(*cp));
				lastfi = TITLE_ID;
				continue;

			case PLACEMENT_ID:
				if (lastfi == -1)
					continue;
				placement1 = vstr_cpy(&placement, &placement_max, placement, " |");
				if ((cp = str_tok(cp, TOKSTR)) && (cp = str_tok(NULL, TOKSTR)))
					do {
						placement1 = vstr_cpy(&placement, &placement_max, placement1, " ");
						placement1 = vstr_cpy(&placement, &placement_max, placement1, cp);
					} while ((cp = str_tok(NULL, TOKSTR)) != NULL);

				if (placement && (strchr(placement, '@') != NULL || strncmp(placement, " 0.0 ", 5) == 0))
					placement[0] = NULLB;
				continue;

			case ACCESSION_ID:
				if (lastfi == -1)
					continue;
				cp += field[ACCESSION_ID].len;
				cp = str_tok(cp, " ;\\\t\n\r");
				if (cp != NULL)
					vstr_cpy(&accession, &accession_max, accession, cp);
				continue;

			case SEQUENCE_ID:
				++nseqs;
				printf(">%s|", label);
				if (lastfi == -1)
					printf(">%d", nseqs);
				else {
					if (accession != NULL && accession[0] != NULLB)
						fputs(accession, outfp);
					putchar('|');
					if (entry != NULL && entry[0] != NULLB)
						fputs(entry, outfp);
				}
				if (title != NULL && title[0] != NULLB)
					fputs(title, outfp);
				if (placement && placement[0] != NULLB)
					fputs(placement, outfp);
				putchar('\n'); /* end of title line */

				/* Skip the numbering line */
				if (fgets(buf, sizeof buf, fp) == NULL)
					bfatal(ERR_DBASE, "Premature EOF:  %s", filename);

				/* Parse and write out the sequence */
				lc = 0;
				while ((cp = fgets(buf, sizeof buf, fp)) != NULL && *cp != '/') {
					while ((ch = *cp++) != NULLB)
						if (!isdigit(ch) && !isspace(ch) && ch != '\n')
							putchar(ch);
					if (++lc > 1) {
						putchar('\n');
						lc = 0;
					}
				}
				if (lc)
					putchar('\n');
				if (cp != NULL
						&& strncmp(cp, field[EOR_ID].str, field[EOR_ID].len) == 0)
					lastfi = -1;
				continue;
			default:
				continue;
			}
		}
		if (lastfi != -1)
			bfatal(ERR_DBASE, "%s: Premature EOF", filename);
		fclose(fp);
		fprintf(stderr, "%s:  %d sequences\n", filename, nseqs);
		nseqs0 += nseqs;
	}
	fprintf(stderr, "Total of %d sequences\n", nseqs0);
	exit(0);
}

void
usage()
{
	fprintf(stderr, "Purpose:  convert a file in PIR format into FASTA format\n");
	fprintf(stderr, "Usage:  %s pirfile\n", module);
	exit(1);
}
