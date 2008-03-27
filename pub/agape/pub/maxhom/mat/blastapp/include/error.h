#ifndef EXTERN
#define EXTERN extern
#endif

enum blast_error {
	ERR_NONE = 0, /* No error */
	ERR_UNDEF, /* Undefined/unspecified error */
	ERR_MEM, /* Insufficient memory */
	ERR_CPUTIME, /* Cpu time limit reached or exceeded */
	ERR_TERMINATED, /* Terminated by SIGTERM signal */
	ERR_INVAL, /* Invalid parameter */
	ERR_DOMAIN, /* Invalid domain for parameter */
	ERR_RANGE, /* Parameter out of range */
	ERR_FOPEN, /* fopen() error */
	ERR_WORDSIZE, /* Bad word size */
	ERR_DFALIB, /* Error in dfa library */
	ERR_NOWORDS, /* No words in neighborhood */
	ERR_HSPCNT, /* Too many HSPs found */
	ERR_DIAGCNT, /* Too many diagonals */
	ERR_MFILE, /* mfil_ function error */
	ERR_SUBFILE, /* Bad substitution matrix file format */
	ERR_SCORING, /* Undefined error in scoring */
	ERR_QUERYLEN, /* Query sequence too long or short */
	ERR_DBASE, /* Database error */
	ERR_RECORD3, /* Insufficient storage for 3-way alignments */
	ERR_REMEMBER, /* Too many db sequences had HSPs to remember */
	ERR_MPFORK, /* Could not fork for multiprocessing */
	ERR_ALARM, /* Alarm clock expired */
	ERR_CONTEXTS, /* No valid contexts for searching */
	ERR_QUERYTYPE, /* Query sequence appears to be of the wrong residue type */
	ERR_QUERYRES, /* Query sequence contained an invalid residue code */
	ERR_MAX };

