#include "blastdb.h"

typedef enum {
	BLAST_DBFMT_UNKNOWN = 0,
	BLAST_DBFMT_BLAST = 1,
	BLAST_DBFMT_FASTA
	} DBFormat, PNTR DBFormatPtr;

typedef enum {
	BLAST_DBERR_NONE = 0,
	BLAST_DBERR_EOF = 1, /* End-Of-File reached */
	BLAST_DBERR_RANGE = 2,	/* argument out of range */
	BLAST_DBERR_RESTYPE = 3,
	BLAST_DBERR_FORMAT = 4,
	BLAST_DBERR_NOTFOUND = 5 /* a file or other resource was not found */
	} DBFileError, PNTR DBFileErrorPtr;

#define DBFILE_MAGIC	0xa0b0c0d0

typedef struct _blast_dbfile {
	struct _blast_dbfile	PNTR root;
	unsigned long	magic;
	DBFormat	format;
	int			restype;
	int			link_count;
	DBFileError	error;
	int		(*ambiguous) PROTO((struct _blast_dbfile PNTR));
	int		(*get_seq) PROTO((struct _blast_dbfile PNTR,BLAST_StrPtr));
	int		(*get_specific) PROTO((struct _blast_dbfile PNTR,BLAST_StrPtr,size_t,size_t));
	int		(*get_str_specific) PROTO((struct _blast_dbfile PNTR,BLAST_AlphabetPtr,BLAST_LetterPtr,size_t,size_t));
	int		(*get_header) PROTO((struct _blast_dbfile PNTR,BLAST_StrPtr));
	int		(*next) PROTO((struct _blast_dbfile PNTR));
	long	(*tell) PROTO((struct _blast_dbfile PNTR));
	int		(*seek) PROTO((struct _blast_dbfile PNTR,long));
	struct _blast_dbfile PNTR	(*link) PROTO((struct _blast_dbfile PNTR));
	long	(*count) PROTO((struct _blast_dbfile PNTR));
	long	(*totlen) PROTO((struct _blast_dbfile PNTR));
	long	(*maxlen) PROTO((struct _blast_dbfile PNTR));
	int		(*ambig_avail) PROTO((struct _blast_dbfile PNTR));
	int		(*close) PROTO((struct _blast_dbfile PNTR));
	CharPtr	title;
	CharPtr	rel_date;
	CharPtr	bld_date;
	union {
		BDBFILE	blast;
		} data;
	} DBFile, PNTR DBFilePtr;

DBFilePtr LIBCALL db_open PROTO((CharPtr dbname, DBFormat format, int restype));
DBFilePtr LIBCALL db_link PROTO((DBFilePtr));
int LIBCALL db_close PROTO((DBFilePtr));
int LIBCALL db_get_seq PROTO((DBFilePtr,BLAST_StrPtr));
int LIBCALL db_get_specific PROTO((DBFilePtr,BLAST_StrPtr,size_t,size_t));
int LIBCALL db_get_str_specific PROTO((DBFilePtr,BLAST_AlphabetPtr,BLAST_LetterPtr,size_t,size_t));
int LIBCALL db_ambig_avail PROTO((DBFilePtr));
int LIBCALL db_ambiguous PROTO((DBFilePtr));
int LIBCALL db_get_header PROTO((DBFilePtr,BLAST_StrPtr));
int LIBCALL db_seek PROTO((DBFilePtr,long));
long LIBCALL db_count PROTO((DBFilePtr));
long LIBCALL db_totlen PROTO((DBFilePtr));
long LIBCALL db_maxlen PROTO((DBFilePtr));

CharPtr LIBCALL get_moddate PROTO((CharPtr filename));
CharPtr LIBCALL get_reldate PROTO((CharPtr title));
