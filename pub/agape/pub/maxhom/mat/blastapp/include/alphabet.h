#ifndef _ALPHABET_
#define _ALPHABET_

/*
	For better performance on most platforms, ALPHASIZE_MAX and ALPHAVAL_MAX
	should have values of 2**N and (2**N - 1), respectively, for some N.
	Choose an N that is just large enough for the job, to avoid needlessly
	thrashing in small CPU caches.
*/
#define ALPHASIZE_MAX	128	/* Max. no. of letters permitted in an alphabet */
#define ALPHAVAL_MAX	127	/* Max. numerical value permitted for a letter */


/* Ambiguous residues are defined using this structure */
typedef struct degen {
		char	residue;	/* ASCII letter for this residue */
		int		ndegen;		/* no. of residues this ASCII letter matches */
		char	*list;		/* null-terminated list of matching letters */
	} Degen, DegenPtr;

	/* Use DEGENLIST macro to more easily manage data initialization */
#define DEGENLIST(Chr, List)	{ Chr, (sizeof(List)-1), (List) }

#endif /* !_ALPHABET_ */
