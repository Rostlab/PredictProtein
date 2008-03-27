#ifndef __AABET_H__
#define __AABET_H__

#include "alphabet.h"

#define AAID_MIN	1	/* Smallest letter value in binary alphabet */
#define AAID_MAX	24	/* Maximum letter value in binary alphabet */
#define AAID_CNT	24	/* Number of letters in alphabet */
#define AAID_NAR	(AAID_MAX+1)
#define AAID_IGNORE	(AAID_MAX+3)

#define NA AAID_NAR		/* Not A residue */
#define EL (NA+1)		/* End of Line */
#define ES (NA+2)		/* End of Sequence */
#define IC AAID_IGNORE	/* Ignore this Character */

#define UNKNOWN_AA_CHR	'X'
#define STOP_AA_CHR	'*'
#define GAP_AA_CHR '-'

EXTERN int aa_atob[1<<CHAR_BIT]	/* ASCII-to-binary translation table */
#ifdef INIT
	= {
	EL,NA,NA,NA,NA,NA,NA,NA,NA,IC,EL,NA,NA,EL,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	IC,NA,NA,NA,NA,NA,NA,NA,NA,NA,24,NA,NA, 0,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	ES, 1,21, 5, 4, 7,14, 8, 9,10,NA,12,11,13, 3,NA,
	15, 6, 2,16,17,NA,20,18,23,19,22,NA,NA,NA,NA,NA,
	ES, 1,21, 5, 4, 7,14, 8, 9,10,NA,12,11,13, 3,NA,
	15, 6, 2,16,17,NA,20,18,23,19,22,NA,NA,NA,NA,NA,

	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA }
#endif
	;

/* binary-to-ASCII translation table */
EXTERN char	aa_btoa[] INITIAL("-ARNDCQEGHILKMFPSTWYVBZX*");

EXTERN Degen	aa_adegen[25]
#ifdef INIT
		= {
	'-',	1,	"-",
	'A',	1,	"A",
	'R',	1,	"R",
	'N',	1,	"N",
	'D',	1,	"D",
	'C',	1,	"C",
	'Q',	1,	"Q",
	'E',	1,	"E",
	'G',	1,	"G",
	'H',	1,	"H",
	'I',	1,	"I",
	'L',	1,	"L",
	'K',	1,	"K",
	'M',	1,	"M",
	'F',	1,	"F",
	'P',	1,	"P",
	'S',	1,	"S",
	'T',	1,	"T",
	'W',	1,	"W",
	'Y',	1,	"Y",
	'V',	1,	"V",
	'B',	2,	"DN",
	'Z',	2,	"EQ",
	'X',	20,	"ARNDCQEGHILKMFPSTWYV",
	'*',	1,	"*"
	}
#endif
	;

#undef NA
#undef EL
#undef ES
#undef IC


EXTERN double aafq[21]
#ifdef INIT
	/* Amino acid residue frequencies used by S. Altschul */
	= {0, .081, .057, .045, .054, .015, .039, .061, .068, .022, .057,
 		  .093, .056, .025, .040, .049, .068, .058, .013, .032, .067 }
#endif
	;

#endif /* !__AABET_H__ */
