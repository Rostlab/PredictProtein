/*
o open database, returns file handle
o close database file handle
o read record #
o read next record
o duplicate file handle
o isindexed
o seek to record #
o index database
*/

#define CDBLEN_MAX	(96*KBYTE*KBYTE)
#define DB_TYPE_PRO 0x78857a4f	/* Magic # for a protein sequence database */
#define DB_TYPE_NUC 0x788325f8	/* Magic # for a nt. sequence database */
 
#define AAFORMAT	3	/* Latest a.a. database format ID number */
#define NTFORMAT	6	/* Latest nt. database format ID number */

#define NT_MAGIC_BYTE 0xfc /* Magic sentinel byte at end of compressed nt db */
#define NSENTINELS	2
#define NBPN	2	/* no. of bits per nucleotide */

typedef struct _blast_db_data {
	unsigned char	PNTR membuf;
	unsigned char	PNTR allocbuf;
	unsigned char	PNTR _s_seq, PNTR s_seq;
	Nlm_Boolean	cseqok, seqok, hdrok;
	unsigned long	len; /* length of this sequence */
	unsigned long	enclen; /* encoded length of this sequence */
	unsigned long	seq_reclen; /* no. of bytes in the sequence file record */
	MFILE	PNTR tfile; /* table file (index to sequence and defline records) */
	MFILE	PNTR hfile; /* defline file */
	MFILE	PNTR sfile; /* sequence file */
	FILE	*fafile; /* FASTA file */
	long	type;
	long	format;
	int		restype;
	int		lpb, lpb_alt; /* letters per byte, natural & alternate alphabets */
	unsigned long	count; /* no. of sequences in database */
	unsigned long	maxlen;	/* length of the single longest sequence */
	unsigned long	totdblen;	/* total length of all sequences */
	unsigned long	c_len;	/* length of compressed database */
	unsigned long	line_len;	/* line length in FASTA file (nt. only) */
	unsigned long	clean_count;	/* no. of 8-mers to clean */
	BLAST_AlphabetPtr	ap, ap_alt;
	BLAST_AlphaMapPtr	amp;
	long	id;
	unsigned long	PNTR seq_beg;
	unsigned long	PNTR cseq_beg;
	unsigned long	PNTR header_beg;
	UcharPtr	ambiguity;
	unsigned long	numbogus;
	Boolean		hfile_open_tried;
	Boolean		fafile_open_tried;
	CharPtr	tbl_ext, seq_ext, hdr_ext;
	char	fname[FILENAME_MAX+1];
	} BDBFILE;

struct _blast_dbfile PNTR blast_db_open PROTO((CharPtr dbname, int restype));
struct _blast_dbfile PNTR blast_db_link PROTO((struct _blast_dbfile PNTR));
int LIBCALL blast_db_get_seq PROTO((struct _blast_dbfile PNTR,BLAST_StrPtr));
int LIBCALL blast_db_get_specific PROTO((struct _blast_dbfile PNTR,BLAST_StrPtr,size_t,size_t));
int LIBCALL blast_db_get_str_specific PROTO((struct _blast_dbfile PNTR,BLAST_AlphabetPtr,BLAST_LetterPtr,size_t,size_t));
int LIBCALL blast_db_ambig_avail PROTO((struct _blast_dbfile PNTR));
int LIBCALL blast_db_ambiguous PROTO((struct _blast_dbfile PNTR));
int LIBCALL blast_db_get_header PROTO((struct _blast_dbfile PNTR,BLAST_StrPtr));
long LIBCALL blast_db_count PROTO((struct _blast_dbfile PNTR));
long LIBCALL blast_db_totlen PROTO((struct _blast_dbfile PNTR));
long LIBCALL blast_db_maxlen PROTO((struct _blast_dbfile PNTR));
int LIBCALL blast_db_next PROTO((struct _blast_dbfile PNTR));
int LIBCALL blast_db_seek PROTO((struct _blast_dbfile PNTR dbfp, long id));
long LIBCALL blast_db_tell PROTO((struct _blast_dbfile PNTR));
int LIBCALL blast_db_close PROTO((struct _blast_dbfile PNTR));

