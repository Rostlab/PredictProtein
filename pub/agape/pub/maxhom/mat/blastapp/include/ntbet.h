#ifndef __NTBET_H__
#define __NTBET_H__

#include "alphabet.h"

#define NUCID_MIN	0
#define NUCID_MAX	15
#define NUCID_CNT	16
#define NUCID_NAR	(NUCID_MAX+1)
#define NUCID_IGNORE	(NUCID_MAX+3)

#define NA NUCID_NAR	/* Not A Residue */
#define EL (NA+1)		/* End of Line */
#define ES (NA+2)		/* End of Sequence */
#define IC NUCID_IGNORE	/* Ignore this Character */
#define UNKNOWN_NT_CHR	'N'
#define GAP_NT_CHR '-'


/*********************************************
*
*  ASCII-to-binary and binary-to-ASCII
*  translation tables
*
*********************************************/

EXTERN BLAST_Letter nt_atob[1<<CHAR_BIT]
#ifdef INIT
	= {
	EL,NA,NA,NA,NA,NA,NA,NA,NA,IC,EL,NA,NA,EL,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	IC,NA,NA,NA,NA,NA,NA,NA,NA,NA,ES,NA,NA,15,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	ES, 0,10, 1,11,NA,NA, 2,12,NA,NA, 7,NA, 6,14,NA,
	 4, 5, 4, 9, 3, 3,13, 8,NA, 5,NA,NA,NA,NA,NA,NA,
	ES, 0,10, 1,11,NA,NA, 2,12,NA,NA, 7,NA, 6,14,NA,
	 4, 5, 4, 9, 3, 3,13, 8,NA, 5,NA,NA,NA,NA,NA,NA,

	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,
	NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA
	}
#endif
	;

/*                             0123456789012345 */
EXTERN char	nt_btoa[] INITIAL("ACGTRYMKWSBDHVN-");


EXTERN char nt_n4toa[]
/*                 111111 */
/*       0123456789012345 */
INITIAL("-ACMGRSVTWYHKDBN");

EXTERN BLAST_Letter nt_n4tob[]
#ifdef INIT
	= {
	15, 0, 1, 6, 2, 4, 9, 13, 3, 8, 5, 12, 7, 11, 10, 14
	}
#endif
	;

EXTERN unsigned char nt_aton4[1<<CHAR_BIT]
#ifdef INIT
= {
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 1,14, 2,13, 0, 0, 4,11, 0, 0,12, 0, 3,15, 0,
     5,10, 5, 6, 8, 8, 7, 9, 0,10, 0, 0, 0, 0, 0, 0,
     0, 1,14, 2,13, 0, 0, 4,11, 0, 0,12, 0, 3,15, 0,
     5,10, 5, 6, 8, 8, 7, 9, 0,10, 0, 0, 0, 0, 0, 0,

     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
}
#endif
    ;


/*********************************************
*
*  Reverse complement tables
*
*********************************************/

EXTERN char nt_brevcomp[128] /* binary-to-binary reverse complement */
#ifdef INIT
	= {
		 3, 2, 1, 0, 5, 4, 7, 6, 8, 9,13,12,11,10,14,15,
		16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,
		16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,
		16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,
		16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,
		16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,
		16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,
		16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16
	}
#endif
	;

EXTERN char nt_arevcomp[128] /* ASCII-to-ASCII reverse complement */
#ifdef INIT
#define NANT	'?' /* Not A Nucleotide, used when rev. complement is undefined */
	= {
        NANT,NANT,NANT,NANT,NANT,NANT,NANT,NANT,
        NANT,NANT,NANT,NANT,NANT,NANT,NANT,NANT,
        NANT,NANT,NANT,NANT,NANT,NANT,NANT,NANT,
        NANT,NANT,NANT,NANT,NANT,NANT,NANT,NANT,
        NANT,NANT,NANT,NANT,NANT,NANT,NANT,NANT,
        NANT,NANT,NANT,NANT,NANT, '-',NANT,NANT,
        NANT,NANT,NANT,NANT,NANT,NANT,NANT,NANT,
        NANT,NANT,NANT,NANT,NANT,NANT,NANT,NANT,
    /*   @    A    B    C    D    E    F    G  */
        NANT,'T', 'V', 'G', 'H', NANT,NANT,'C',
    /*   H    I    J    K    L    M    N    O  */
        'D', NANT,NANT,'M', NANT,'K', 'N', NANT,
    /*   P    Q    R    S    T    U    V    W  */
        'Y', 'R', 'Y', 'S', 'A', 'A', 'B', 'W',
    /*   X    Y    Z                           */
       NANT, 'R', NANT,NANT,NANT,NANT,NANT,NANT,
    /*   `    a    b    c    d    e    f    g  */
        NANT,'T', 'V', 'G', 'H', NANT,NANT,'C',
    /*   h    i    j    k    l    m    n    o  */
        'D', NANT,NANT,'M', NANT,'K', 'N', NANT,
    /*   p    q    r    s    t    u    v    w  */
        'Y', 'R', 'Y', 'S', 'A', 'A', 'B', 'W',
    /*   x    y    z                           */
       NANT, 'R', NANT,NANT,NANT,NANT,NANT,NANT,
        }
#undef NANT
#endif
        ;

EXTERN Degen	nt_adegen[16] /* ASCII degeneracy table */
#ifdef INIT
		= {
	'A',	1,	"A",
	'C',	1,	"C",
	'G',	1,	"G",
	'T',	1,	"T",
	'R',	2,	"AG",
	'Y',	2,	"CT",
	'M',	2,	"AC",
	'K',	2,	"GT",
	'W',	2,	"AT",
	'S',	2,	"CG",
	'B',	3,	"CGT",
	'D',	3,	"AGT",
	'H',	3,	"ACT",
	'V',	3,	"ACG",
	'N',	4,	"ACGT",
	'-',	1,	"-"
	}
#endif
	;

EXTERN Degen	nt_bdegen[16] /* binary degeneracy table */
#ifdef INIT
		= {
	'\000',	1,	"\000",
	'\001',	1,	"\001",
	'\002',	1,	"\002",
	'\003',	1,	"\003",
	'\004',	2,	"\000\002",
	'\005',	2,	"\001\003",
	'\006',	2,	"\000\001",
	'\007',	2,	"\002\003",
	'\010',	2,	"\000\003",
	'\011',	2,	"\001\002",
	'\012',	3,	"\001\002\003",
	'\013',	3,	"\000\002\003",
	'\014',	3,	"\000\001\003",
	'\015',	3,	"\000\001\002",
	'\016',	4,	"\000\001\002\003",
	'\017',	1,	"\017"
	}
#endif
	;


/* Generate an appropriate random BINARY nucleotide from the list ACGT */
#define RANDOM_BNUC(c)	(c < nt_atob['-'] ? \
	nt_bdegen[c].list[(rnd_gen()>>8)%nt_bdegen[c].ndegen] \
	: ((rnd_gen()>>8) % 4) )

/* Generate an appropriate random ASCII nucleotide from the list ACGT */
#define RANDOM_ANUC(c)	(nt_atob[c] < nt_atob['-'] ? \
	nt_adegen[nt_atob[c]].list[(rnd_gen()>>8)%nt_adegen[nt_atob[c]].ndegen] \
	: nt_btoa[((rnd_gen()>>8) % 4)] )

#undef NA
#undef EL
#undef ES
#undef IC


EXTERN double	ntfq[4]
#ifdef INIT
	= { 0.25, 0.25, 0.25, 0.25 }
#endif
	;

#endif /* __NTBET_H__ */
