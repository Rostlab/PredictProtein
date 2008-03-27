/*
PAM - Calculate a log-odds matrix for specified integral PAM distance.

Original author:  Stephen F. Altschul


The basic command syntax is

     pam [-s#] [-x#] <PAM distance>

where <PAM distance> is an integer from 2 to 511.

The PAM matrix is a "log-odds" matrix, and is calculated as the natural
logarithm of target over background amino acid pair frequencies, divided
by <scale>.  For the PAM120, the default value for scale is ln(2)/2 = 0.3466.
For the PAM250, the default scale is ln(2)/3 = 0.23105.  These values may be
overridden by the command line option -s<scale>.

The default scale changes with PAM distance to achieve some measure
of precision in the integer-valued substitution scores, without
generating inappropriate precision and without producing such a wide
range in the scores, from the highest individual score to the lowest,
that calculation of the Karlin-Altschul "K" parameter is unnecessarily
compute-intensive.  For significance calculations, <scale> will be
approximately equal to the parameter "lambda" (Karlin & Altschul, PNAS
87:2264-2268).  The slight difference is due to round-off errors, and to the
use of PAM matrices with proteins that have amino acid frequencies different
than those used by Dayhoff et al.

Relevant literature:

Dayhoff, M. O., Schwartz, R. M. & Orcutt, B. C. (1978).
A model of evolutionary change in proteins. In Atlas of Protein Sequence
and Structure, Vol. 5, Suppl. 3, Ed. M. O. Dayhoff, pp. 345-352.
Natl. Biomed. Res. Found., Washington.
*/

#include <ncbi.h>
#include <gish.h>
#include <gishlib.h>
#define EXTERN
#include "blastapp.h"
#include "aabet.h"

/*
Version  Date      Modification
------- -------   ------------------------------------------------------------
1.0.3   1-6-92    Substitution scores against X are weighted mean
1.0.5   3-Sep-92  Corrected substitution scores for B-X and Z-X.
1.0.6   28-Jul-93 Slightly changed the output format
*/

char version[] = "1.0.6 [28-Jul-93]";

/* One letter amino acid code */
char	aa[] = {
			'A', 'R', 'N', 'D', 'C', 'Q', 'E', 'G', 'H', 'I',
			'L', 'K', 'M', 'F', 'P', 'S', 'T', 'W', 'Y', 'V',
			'B', 'Z', 'X', '*'
			};

#define STOP_CODON_CHR	'*'

/*      Dayhoff amino acid background frequencies     */

double fq[20] = {
87.13, 40.90, 40.43, 46.87, 33.47, 38.26, 49.53, 88.61, 33.62, 36.89,
85.36, 80.48, 14.75, 39.77, 50.68, 69.58, 58.54, 10.49, 29.92, 64.72};

/*      Dayhoff mutability data         */

double mutab[20] = {
100.0,  65.0, 134.0, 106.0,  20.0,  93.0, 102.0,  49.0,  66.0,  96.0,
 40.0,  56.0,  94.0,  41.0,  56.0, 120.0,  97.0,  18.0,  41.0,  74.0};

/*      Dayhoff mutation data      */

int mut[190] = {
 30,
109, 17,
154,  0,532,
 33, 10,  0,  0,
 93,120, 50, 76,  0,
266,  0, 94,831,  0,422,
579, 10,156,162, 10, 30,112,
 21,103,226, 43, 10,243, 23, 10,
 66, 30, 36, 13, 17,  8, 35,  0,  3,
 95, 17, 37,  0,  0, 75, 15, 17, 40,253,
 57,477,322, 85,  0,147,104, 60, 23, 43, 39,
 29, 17,  0,  0,  0, 20,  7,  7,  0, 57,207, 90,
 20,  7,  7,  0,  0,  0,  0, 17, 20, 90,167,  0, 17,
345, 67, 27, 10, 10, 93, 40, 49, 50,  7, 43, 43,  4,  7,
772,137,432, 98,117, 47, 86,450, 26, 20, 32,168, 20, 40,269,
590, 20,169, 57, 10, 37, 31, 50, 14,129, 52,200, 28, 10, 73,696,
  0, 27,  3,  0,  0,  0,  0,  0,  3,  0, 13,  0,  0, 10,  0, 17, 0,
 20,  3, 36,  0, 30,  0, 10,  0, 40, 13, 23, 10,  0,260,  0, 22, 23,  6,
365, 20, 13, 17, 33, 27, 37, 97, 30,661,303, 17, 77, 10, 50, 43, 186, 0, 17};

#define M	Marray
double	M[8][DIM(fq)][DIM(fq)];
double	pam[2][DIM(fq)][DIM(fq)];
double	PAM[DIM(aa)][DIM(aa)];

Boolean	Xscore_set;
double	Xscore;

main(argc, argv)
	int		argc;
	char	*argv[];
{
	int		i, j, k, l, dist, n, index, q, qq, first, width, imin, imax, iscale;
	double	minpam, maxpam;
	double	t, E, H, scale;
	double	x, y;

	module = basename(argv[0], NULL);

	if (argc < 2)
		usage();

	scale = 0.;

	while ((i = getopt(argc, argv, "s:S:x:X:")) != -1)
		switch (i) {
			case 's': case 'S': /* user-selectable scale for the matrix */
				if (sscanf(optarg, "%lg", &scale) != 1)
					usage();
				if (scale <= 0. || scale >= 1000.)
					usage();
				break;
			case 'x': case 'X': /* user-selectable substitution score for X */
				if (sscanf(optarg, "%lg", &Xscore) != 1)
					usage();
				Xscore_set = TRUE;
				break;
			case '?':
				usage();
		}

	if (optind >= argc)
		usage();

	if (sscanf(argv[optind], "%d", &dist) != 1)
		usage();

	n = dist;

	if (dist<2) {
		fprintf(stderr,"PAM distance must be greater than 1.\n");
		exit(1);
	}
	if (dist>511) {
		fprintf(stderr,"PAM distance must be less than 512.\n");
		exit(1);
	}

	printf("#\n");
	printf("# This matrix was produced by \"pam\" Version %s\n#\n", version);

	if (scale != 0.) {
		printf("# PAM %d substitution matrix, scale = %#.6lg\n", dist, scale);
		printf("#\n");
	}

	/* Normalize background frequencies */

	for (t=i=0; i<DIM(fq); ++i)
		t += fq[i];
	for (i=0; i<DIM(fq); ++i)
		fq[i] /= t;

	/* Calculate 1 PAM transition matrix */

	for (k=0,i=1; i<DIM(M[0]); ++i)
		for (j=0; j<i; ++j)
			M[0][j][i] = M[0][i][j] = mut[k++];
	for (t=i=0; i<DIM(M[0][0]); ++i)
		t += mutab[i]*fq[i];
	t *= 100.0;
	for (i=0; i<DIM(M[0]); ++i)
		M[0][i][i] = 1.0 - (mutab[i] /= t);
	for (i=0; i<DIM(M[0]); ++i) {
		for (t=j=0; j<DIM(M[0][0]); ++j)
			if (j != i)
				t += M[0][i][j];
		t /= mutab[i];
		for (j=0; j<DIM(M[0][0]); ++j)
			if (j != i)
				M[0][i][j] /= t;
	}

	/* Calculate transition matricies for powers of 2 */

	for (i=qq=first=index=1; (index *= 2) <= n; ++i)
		for (j=0; j<DIM(M[0]); ++j)
			for (k=0; k<DIM(M[0][0]); ++k)
				for (M[i][j][k]=l=0; l<DIM(M[0][0]); ++l)
					M[i][j][k] += M[i-1][j][l]*M[i-1][l][k];

	/* Calculate transition matrix for PAM distance requested */

	for (; n; n -= index) {
		for (; index>n; index /= 2)
			--i;
		if (first) {
			for (j=first=q=0; j<DIM(M[0]); ++j)
				for (k=0; k<DIM(M[0][0]); ++k)
					pam[0][j][k] = M[i][j][k];
		}
		else {
			for (j=0; j<DIM(pam[0]); ++j)
				for (k=0; k<DIM(pam[0][0]); ++k)
					for (pam[q][j][k]=l=0; l<DIM(pam[0][0]); ++l)
						pam[q][j][k] += pam[qq][j][l]*M[i][l][k];
		}
		q = 1 - q;
		qq = 1 - qq;
	}

	/* Calculate symmetric log-odds PAM matrix */

	for (H=k=0; k<DIM(fq); ++k)
		for (j=0; j<DIM(fq); ++j) {
			H += fq[j] * pam[qq][j][k] * log(pam[qq][j][k] / fq[k]);
		}
	if (scale == 0) {
		iscale = (2.0/sqrt(H/LN2)) + 0.5;
		iscale = MAX(iscale, 2);
		scale = LN2/iscale;
		printf("# PAM %d substitution matrix, scale = ln(2)/%d = %#.6lg\n", dist, iscale, scale);
		printf("#\n");
	}

	for (E=k=0; k<DIM(fq); ++k)
		for (j=0; j<=k; ++j) {
			PAM[k][j] = PAM[j][k]
				= log(pam[qq][j][k]*pam[qq][k][j]/(fq[k]*fq[j]))/(scale*2);
			x = fq[k] * fq[j] * Nlm_Nint(PAM[j][k]);
			E += x;
			if (j != k)
				E += x;
		}

	printf("# Expected score = %#0.3lg, Entropy = %#0.3lg bits\n#\n", E, H/LN2);

	/* Estimate PAM scores for non-standard B,Z and X symbols */

	for (j=0; j<DIM(fq); ++j)
		PAM[j][20] = PAM[20][j]
			= log((pam[qq][j][2]+pam[qq][j][3])
				*(fq[2]*pam[qq][2][j]+fq[3]*pam[qq][3][j])
				/((fq[2]+fq[3])*(fq[2]+fq[3])*fq[j]))/(scale*2);

	PAM[20][20]
		= log((fq[2]*(pam[qq][2][2]+pam[qq][2][3])+fq[3]*(pam[qq][3][2]+pam[qq][3][3]))
				/((fq[2]+fq[3])*(fq[2]+fq[3])))/scale;

	for (j=0; j<DIM(fq); ++j)
		PAM[j][21] = PAM[21][j]
			= log((pam[qq][j][5]+pam[qq][j][6])
				*(fq[5]*pam[qq][5][j]+fq[6]*pam[qq][6][j])
				/((fq[5]+fq[6])*(fq[5]+fq[6])*fq[j]))/(scale*2);

	PAM[20][21] = PAM[21][20]
			= log((fq[2]*(pam[qq][2][5]+pam[qq][2][6])+fq[3]*(pam[qq][3][5]+pam[qq][3][6]))
			*(fq[5]*(pam[qq][5][2]+pam[qq][5][3])+fq[6]*(pam[qq][6][2]+pam[qq][6][3]))
			/((fq[2]+fq[3])*(fq[2]+fq[3])*(fq[5]+fq[6])*(fq[5]+fq[6])))/(scale*2);

	PAM[21][21] =
		log((fq[5]*(pam[qq][5][5]+pam[qq][5][6])+fq[6]*(pam[qq][6][5]+pam[qq][6][6]))
				/((fq[5]+fq[6])*(fq[5]+fq[6])))/scale;

	/* Set values for substituting 'X' */
	if (Xscore_set) {
		for (j=0; j<DIM(PAM); ++j)
			PAM[22][j] = PAM[j][22] = Xscore;
	}
	else {
		y = 0.;
		for (i=0; i<DIM(fq); ++i) {
			x = 0.;
			for (j=0; j<DIM(fq); ++j) {
				x += fq[j]*PAM[i][j];
				y += fq[i]*fq[j]*PAM[i][j];
			}
			PAM[22][i] = PAM[i][22] = x;
		}
		PAM[22][22] = y; /* X vs. X */

		y = fq[2] + fq[3]; /* f[B] = f[N] + f[D] */
		for (x=0., j=0; j<DIM(fq); ++j)
			x += fq[2]*fq[j]*PAM[2][j]/y + fq[3]*fq[j]*PAM[3][j]/y;
		PAM[20][22] = PAM[22][20] = x;

		y = fq[5] + fq[6]; /* fq[Z] = fq[Q] + fq[E] */
		for (x=0., j=0; j<DIM(fq); ++j)
			x += fq[5]*fq[j]*PAM[5][j]/y + fq[6]*fq[j]*PAM[6][j]/y;
		PAM[21][22] = PAM[22][21] = x;
	}

	/* Print PAM matrix */

	minpam = maxpam = PAM[0][0];
	for (i=k=0; k<DIM(fq); ++k)
		for (j=0; j<=k; ++j) {
			if (PAM[j][k] < minpam)
				minpam = PAM[j][k];
			if (PAM[j][k] > maxpam)
				maxpam = PAM[j][k];
		}

	/* Set values for substituting stop codons */
	for (i=0; i<DIM(PAM); ++i)
		PAM[DIM(PAM)-1][i] = PAM[i][DIM(PAM[0])-1] = minpam;
	PAM[DIM(PAM)-1][DIM(PAM[0])-1] = 1.;

	if (Nlm_Nint(minpam) >= 0)
		bfatal(ERR_UNDEF, "Computation error:  lowest score must be less than zero");
	if (Nlm_Nint(maxpam) <= 0)
		bfatal(ERR_UNDEF, "Computation error:  highest score must be greater than zero");

	imin = log(-minpam+0.5)/LN10;
	imax = log(maxpam+0.5)/LN10;
	width = MAX(imin+2, imax+1);

	printf("# Lowest score = %d, Highest score = %d\n",
		Nlm_Nint(minpam), Nlm_Nint(maxpam));
	printf("#\n");

	putc(' ', stdout);
	for (i=0; i<DIM(aa); ++i)
		printf("%*s%c", width, "", aa[i]);
	putc('\n', stdout);

	++width;
	for (i=0; i<DIM(PAM); ++i) {
		putc(aa[i], stdout);
		for (j=0; j<DIM(PAM[0]); ++j)
			printf("%*d", width, Nlm_Nint(PAM[i][j]));
		putc('\n', stdout);
	}

	exit(0);
}

void
usage()
{
	fflush(stdout);
	fprintf(stderr, "\n%s Version %s:  Generate a PAM matrix\n", module, version);
	fprintf(stderr, "\nUsage:\n\n    %s [-s scale] [-x value] pam-distance\n\n", module);
	fprintf(stderr, "where \"pam-distance\" is an integer from 2 to 511,\n");
	fprintf(stderr, "\"scale\" is an optional floating-point scale\n");
	fprintf(stderr, "for the log-odds matrix in the range 0. < scale <= 1000,\n");
	fprintf(stderr, "and \"-x value\" is the substitution value for X with any other letter.\n");
	exit(1);
}
