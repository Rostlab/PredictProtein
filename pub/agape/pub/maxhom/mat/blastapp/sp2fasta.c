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
char	*label = "sp";
long	nseqs, nseqs0;
char	entry[200], accession[200];
CharPtr	def, def1;
size_t	def_max;
FILE	*outfp;
unsigned long	lineno;
extern char	*sys_errlist[];
Boolean	label_opt;

main(argc, argv)
	int		argc;
	char	**argv;
{
	char	buf[120], *filename;
	CharPtr	cp2, tcp;
	register CharPtr	cp;
	register char	ch;
	FILE	*fp;
	int		i, code, newcode, lastcode, fno;

	outfp = stdout;

	module = str_dup(basename(argv[0], NULL));

	if (argc == 2 && strcmp(argv[1], "-") == 0)
		optind = argc - 1;
	else
		while ((i = getopt(argc, argv, "l:")) != -1)
			switch (i) {
			case 'l':
				label = optarg;
				label_opt = TRUE;
				continue;
			case '?':
				usage();
			default:
				usage();
			}

	if (optind >= argc)
		usage();

	for (fno = 1; fno < argc; ++fno) {
		fp = openfile(filename = argv[fno], "r");
		if (fp == NULL)
			continue;
		lineno = 0;
		nseqs = 0;
		for (; fgets(buf, sizeof(buf), fp) != NULL; ) {
			++lineno;
			newcode = ((buf[0]<<8)|buf[1]);
			if (newcode == (('X'<<8)|'X') )
				continue;
			lastcode = code;
			switch (code = newcode) {
			case ('I'<<8)|'D': /* ID line */
				if (entry[0] != NULLB)
					bfatal(ERR_DBASE, "ID line without SQ, line %lu", lineno);
				cp = strtok(buf+2, " \t\n\r");
				if (cp == NULL)
					bfatal(ERR_DBASE, "Bad ID line, line %lu", lineno);
				strcpy(entry, cp);
				if (label_opt)
					continue;
				label = "sp";
				cp = strtok(NULL, " \t\n\r");
				if (cp == NULL)
					continue;
				cp = strtok(NULL, " \t\n\r");
				if (cp == NULL)
					continue;
				if (strcasecmp(cp, "dna;") == 0 || strcasecmp(cp, "rna;") == 0)
					label = "emb";
				continue;
			case ('A'<<8)|'C': /* AC line */
				if (accession[0] != NULLB)
					continue;
				cp = strtok(buf+2, " ;\t\r\n");
				if (cp == NULL)
					bfatal(ERR_DBASE, "Bad AC line, line %lu", lineno);
				strcpy(accession, cp);
				continue;
			case ('D'<<8)|'E': /* DE line */
				if (lastcode != code && def != NULL && def[0] != NULLB)
					bfatal(ERR_DBASE, "Multiple DEfinitions for one sequence, line %lu", lineno);
				cp = buf+2;
				while (*cp != NULLB && isspace(*cp))
					++cp;
				def1 = vstr_cpy(&def, &def_max, def1, " ");
				def1 = vstr_cpy(&def, &def_max, def1, cp);
				if (def1[-1] == '\n')
					*--def1 = NULLB;
				continue;
			case ('S'<<8)|'Q': /* SQ line */
				/* Display the FASTA-format description line */
				fputc('>', outfp);
				fputs(label, outfp);
				fputc('|', outfp);
				fputs(accession, outfp);
				fputc('|', outfp);
				fputs(entry, outfp);
				if (def != NULL && def[0] != NULLB)
					fputs(def, outfp);
				fputc('\n', outfp);
				continue;
			case (' '<<8)|' ': /* sequence data */
				if (lastcode != (code = ('S'<<8)|'Q'))
					bfatal(ERR_DBASE, "Sequence data without SQ line, line %lu", lineno);
				cp = buf+5;
				for (;/* every letter or residue */;) {
					switch (ch = *cp++) {
					case '1': case '2': case '3': case '4': case '5':
					case '6': case '7': case '8': case '9': case '0':
						goto ResidueBreak;
					case '\0': case '\n':
						goto ResidueBreak;
					case ' ': case '\t':
						continue;
					case 'a': case 'b': case 'c': case 'd': case 'e':
					case 'f': case 'g': case 'h': case 'i': case 'j':
					case 'k': case 'l': case 'm': case 'n': case 'o':
					case 'p': case 'q': case 'r': case 's': case 't':
					case 'u': case 'v': case 'w': case 'x': case 'y': case 'z':
						ch = toupper(ch);
					case 'A': case 'B': case 'C': case 'D': case 'E':
					case 'F': case 'G': case 'H': case 'I': case 'J':
					case 'K': case 'L': case 'M': case 'N': case 'O':
					case 'P': case 'Q': case 'R': case 'S': case 'T':
					case 'U': case 'V': case 'W': case 'X': case 'Y': case 'Z':
						fputc(ch, outfp);
						continue;
					default:
						continue;
					}
				}
ResidueBreak:
				fputc('\n', outfp);
				continue;
			case ('/'<<8)|'/': /* End of record */
				fflush(outfp);
				++nseqs;
				code = lastcode = 0;
				entry[0] = accession[0] = NULLB;
				def1 = def;
				if (def != NULL)
					def[0] = NULLB;
				continue;
			default:
				continue;
			}
		}
		if (ferror(fp))
			bfatal(ERR_DBASE, "File read error, %s", sys_errlist[errno]);
		if (code != 0)
			fprintf(stderr, "WARNING:  file \"%s\" does not end with // record\n",
					filename);
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
	fprintf(stderr, "Purpose:  convert files in SWISS-PROT or EMBL format into FASTA format\n");
	fprintf(stderr, "Usage:  %s [-l label] spfile [spfile2...]\n", module);
	exit(1);
}
