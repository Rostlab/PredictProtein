#include <ncbi.h>
#include "blastapp.h"
#include "ntbet.h"
#include "aabet.h"
#include "gcode.h"

#define TOKSTR	" \t\n\r"

int
get_codonfq(fname, gcode, fq, bits)
	char	*fname;
	char	gcode[64];
	double	fq[64];
	double	bits[64];
{
	FILE	*fp;
	char	buf[512], *cp;
	char	fn[FILENAME_MAX+1];
	int		i, lineno = 0;
	int	n1, n2, n3, codon;
	int		once = 0;

	for (i=0; i<64; ++i) {
		gcode[i] = '\0';
		fq[i] = 0.;
		bits[i] = 0.;
	}

	if (fname == NULL)
		return 0;

Retry:
	strcpy(buf, fname);
	strcat(buf, ".cdi");
	if ((fp = ckopen(buf, "r", 0)) == NULL) {
		if (++once > 1)
			bfatal(ERR_FOPEN, "Could not find or open a codon frequency info file named:  %s", fname);
		cp = getenv("BLASTCDI");
		if (cp == NULL)
			sprintf(buf, "%s%s", BLASTCDI, fname);
		else
			sprintf(buf, "%s%s", cp, fname);
		fname = buf;
		goto Retry;
	}

	for (i=0, ++lineno; i < 64 && fgets(buf, sizeof buf, fp) != NULL; ++lineno) {
		cp = strtok(buf, TOKSTR);
		if (cp == NULL || *cp == '#')
			continue;
		++i;
		if (strlen(cp) != CODON_LEN)
			bfatal(ERR_UNDEF, "codon longer than %d letters on line %d", CODON_LEN, lineno);
		n1 = nt_atob[cp[0]];
		n2 = nt_atob[cp[1]];
		n3 = nt_atob[cp[2]];
		if (n1 > 3)
			bfatal(ERR_UNDEF, "\"%c\" in the codon on line %d is an invalid nucleotide",
				cp[0], lineno);
		if (n2 > 3)
			bfatal(ERR_UNDEF, "\"%c\"in the codon on line %d is an invalid nucleotide",
				cp[1], lineno);
		if (n3 > 3)
			bfatal(ERR_UNDEF, "\"%c\" in the codon on line %d is an invalid nucleotide",
				cp[2], lineno);
		codon = n1*4*4 + n2*4 + n3;

		cp = strtok(NULL, TOKSTR);
		if (cp == NULL || strlen(cp) != 1)
			goto Format;
		if (gcode[codon] != '\0')
			bfatal(ERR_UNDEF, "Duplicate codon found on line %d: %s", lineno, fname);
		gcode[codon] = *cp;
		if (aa_atob[*cp] > AAID_MAX)
			bfatal(ERR_UNDEF, "Unrecognized amino acid on line %d:  %c", lineno, *cp);

		cp = strtok(NULL, TOKSTR);
		if (cp == NULL)
			goto Format;
		if (sscanf(cp, "%lg", &fq[codon]) != 1)
			goto Format;

		cp = strtok(NULL, TOKSTR); /* freq/aa */
		if (cp == NULL)
			goto Format;
		cp = strtok(NULL, TOKSTR); /* odds */
		if (cp == NULL)
			goto Format;

		cp = strtok(NULL, TOKSTR); /* bits */
		if (cp == NULL)
			goto Format;
		if (sscanf(cp, "%lg", &bits[codon]) != 1)
			goto Format;
		/*
		bits[codon] *= 10.;
		*/
	}
	if (i < 64)
		bfatal(ERR_UNDEF, "Premature end-of-file; Only %d codons are specified in %s",
				i, fname);

	(void) fclose(fp);
	return 0;

Format:
	bfatal(ERR_UNDEF, "File format error on line %d:  %s", lineno, fname);
}
