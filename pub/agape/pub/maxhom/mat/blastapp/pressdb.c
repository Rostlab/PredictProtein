/**************************************************************************
*                                                                         *
*                             COPYRIGHT NOTICE                            *
*                                                                         *
* This software/database is categorized as "United States Government      *
* Work" under the terms of the United States Copyright Act.  It was       *
* produced as part of the author's official duties as a Government        *
* employee and thus can not be copyrighted.  This software/database is    *
* freely available to the public for use without a copyright notice.      *
* Restrictions can not be placed on its present or future use.            *
*                                                                         *
* Although all reasonable efforts have been taken to ensure the accuracy  *
* and reliability of the software and data, the National Library of       *
* Medicine (NLM) and the U.S. Government do not and can not warrant the   *
* performance or results that may be obtained by using this software,     *
* data, or derivative works thereof.  The NLM and the U.S. Government     *
* disclaim any and all warranties, expressed or implied, as to the        *
* performance, merchantability or fitness for any particular purpose or   *
* use.                                                                    *
*                                                                         *
* In any work or product derived from this material, proper attribution   *
* of the author(s) as the source of the software or data would be         *
* appreciated.                                                            *
*                                                                         *
**************************************************************************/
/*
Last modified:  4/8/92


PRESSDB - Produce a nucleotide sequence database for searching with the
programs BLASTN and TBLASTN.

Usage:

    pressdb [-t title] [-c clean-bound] database

where "database" names a file in FASTA format containing DNA sequences,
separated by header lines beginning with the character '>'.  A typical
sequence entry is:

>BOVHBPP3I  Bovine beta-globin psi-3 pseudogene, 5' end.
GGAGAATAAAGTTTCTGAGTCTAGACACACTGGATCAGCCAATCACAGATGAAGGGCACT
GAGGAACAGGAGTGCATCTTACATTCCCCCAAACCAATGAACTTGTATTATGCCCTGGGC
TAATCTGCTCTCAGCAGAGAGGGCAGGGGGCTGGGTGGGGCTCACAAGCAAGACCAGGGC
CCCTACTGCTTACACTTGCTTCTAACACAACTTGCAACTGCACAAACACACATCATGGTG
CATCTGACTCTTGAGGGGAAGGCTACTTGTCACT

It is >>>ABSOLUTELY REQUIRED<<< that all lines, except header lines and the
last line of a sequence entry, have the SAME length.  Furthermore, the last
line of the database must end with a newline ('\n') character, and there can
be no spaces or tabs in the sequence.  If two consecutive lines in the file
begin with '>', PRESSDB assumes that there is supposed to be an intervening
sequence with zero length.  In other words, a sequence can have one and only
one header line associated with it.

PRESSDB produces three output files that assist database searching.  If
the database is named DNABANK, for example, then the three output files
are named DNABANK.csq, DNABANK.nhd and DNABANK.ntb.  The .csq file is
a 4-to-1 byte compressed version of the sequences in the FASTA-format file;
the .nhd file contains the header lines/descriptions; and the .ntb file
contains indices for the .csq, .nhd, and input FASTA files.

After formatting with PRESSDB, the database can then be searched
using the command:

       blastn DNABANK query.seq

The original input FASTA-format file, which may be voluminous, was once
required by the BLASTN and TBLASTN programs, but is not strictly
necessary in current versions.  If a database sequence is known to
contain one or more nucleotide ambiguity codes, the maintenance of the
original FASTA-format file will enable BLASTN and TBLASTN to assess
whether ambiguity codes are present in segments where matching
was observed; if the FASTA file is unavailable and an ambiguous
sequence is hit against, BLASTN and TBLASTN will merely issue a
warning.  If none of the sequences in the FASTA file contain ambiguity
codes, then BLASTN and TBLASTN will never attempt to refer to the FASTA file,
rendering this file completely superfluous for the purposes of BLAST searching.

The optional clean-bound argument to pressdb, which must be a positive
integer, characterizes a (possibly empty) set of 8-mers that are to be
"cleaned" from a query sequence prior to searching the database.  Any
octomer that occurs at least clean-bound times in the database (and at
coordinate positions within the sequences that are divisible by four)
will be marked as "uninformative" and neglected in word searches by
BLASTN.  If clean-bound is not specified, no octomers will be cleaned.

	Some clean-bound statistics gathered on GenBank Release 64.0

	Clean-bound		# of 8-mers cleaned
	===========		===================
	 100			34,578
	 200			 8,246
	 300			 1,876
	 400			   631
	 500			   275
	 600			   153
	 700			    96


*/
#include <ncbi.h>
#include <signal.h>
#include <gishlib.h>

#define EXTERN
#include "blastapp.h"
#include "ntbet.h"

#ifdef WORDSIZE_MIN
#undef WORDSIZE_MIN
#endif
#define WORDSIZE_MIN	8		/* Smallest hash word size */

#define ENTRY_MAX	(2000*1024)		/* maximum number of database entries */
#define BUCKETS		65536		/* 4**8 */

/* type to pack values 0..255 in one byte; unsigned char for SUN */
#define PACK_TYPE unsigned char

/* contents of the ".ntb" file */
long
	dbtype = DB_TYPE_NUC,	/* database type indicator */
	dbformat = NTFORMAT;	/* database format (version) indicator */
unsigned long	
	c_len,
	line_len,		/* length of database lines */
	entries,		/* number of database entries */
	ntcount,		/* number of nucleotides in database */
	clean_count,		/* count of cleaned 8mers */
	cseq_beg[ENTRY_MAX+1],	/* points to compressed sequences + pad sizes */
	seq_beg[ENTRY_MAX+1];	/* points to sequences */

char	hadzerolen;

char
	ambiguity_ray[ENTRY_MAX/8 + sizeof(long)]; /* bit array of ambiguity flags*/

char	*buf;
size_t	bufmax, obufmax;

char	*fname, filename[FILENAME_MAX+1];
char	*dbtitle = "";

PACK_TYPE *cbuf;

FILE	*ofile, *cfile, *tfile, *hdrfile;

Boolean	had_ambiguity;
long	bad_one;

void	put_tail();

#if defined(SIGINT) || defined(SIGHUP) || defined(SIGTERM)
void	sighandler();
#endif

int	clean_bound = 0,
	occurs[BUCKETS];

#define mask	(BUCKETS-1)
char	qname[73];

int	long_write PROTO((long, FILE *));

int
main(argc,argv)
	int		argc;
	char	**argv;
{
	long	i, len;
	int		c, ibyte, shortlen=0, lastlen = 0, theline = 0, seqline, fileline=1;
	char	*eof, *b, *compress();
	unsigned long	seqlen = 0, maxlen = 0;

	module = str_dup(basename(argv[0], NULL));

	while ((c = getopt(argc, argv, "t:c:")) != -1)
		switch (c) {
		case 't':
			dbtitle = optarg;
			break;
		case 'c':
			clean_bound = atoi(optarg);
			if (clean_bound < 1)
				fatal(ERR_INVAL, "the clean limit must be a positive integer");
			break;
		case '?':
			usage();
		}

	if (argc - optind != 1) /* Need one more argument on the command line */
		usage();

	fname = argv[optind];

#ifdef SIGINT
	if (signal(SIGINT, sighandler) == SIG_IGN)
		signal(SIGINT, SIG_IGN);
#endif
#ifdef SIGHUP
	if (signal(SIGHUP, sighandler) == SIG_IGN)
		signal(SIGHUP, SIG_IGN);
#endif
#ifdef SIGTERM
	signal(SIGTERM, sighandler);
#endif

	ofile = ckopen(fname, "r", 1);
	sprintf(filename, "%s%s", fname, NT_SEARCHSEQ_EXT);
	cfile = ckopen(filename, "w", 1);
	sprintf(filename, "%s.ntb", fname);
	tfile = ckopen(filename, "w", 1);
	sprintf(filename, "%s.nhd", fname);
	hdrfile = ckopen(filename, "w", 1);

	header_beg = (unsigned long *)ckalloc(sizeof(unsigned long)*(ENTRY_MAX+1));

	rnd_seed((long)123456789 * time(NULL));

	/* Skip over any initial comment lines */
	do {
		ibyte = ftell(ofile);
		eof = vfgets(&buf, &bufmax, &buf, ofile);
		if (bufmax != obufmax) {
			obufmax = bufmax;
			if (cbuf == NULL)
				cbuf = (PACK_TYPE *)ckalloc(bufmax/(CHAR_BIT/NBPN) + 1);
			else {
				cbuf = (PACK_TYPE *)realloc((char *)cbuf, bufmax/(CHAR_BIT/NBPN) + 1);
				if (cbuf == NULL)
					fatal(ERR_MEM, "out of memory, line length approx. = %d.", bufmax);
			}
		}
	} while (buf[0] != '>' && eof != NULL);

	fputc(NT_MAGIC_BYTE, cfile); /* MAGIC prefix byte */

	b = buf;
	for (entries = 0; eof != NULL && entries < ENTRY_MAX; ++entries) {
		header_beg[entries] = ftell(hdrfile);
		/* Write the header line without the newline character */
		if (fwrite(b, i = strlen(b)-1, 1, hdrfile) != 1)
			fatal(ERR_DBASE, "Error writing file %s.nhd", fname);
		memcpy(qname, b, MIN(i,sizeof(qname)-1));
		qname[MIN(i,sizeof(qname)-1)] = NULLB;
		b = buf;
		hadzerolen = FALSE;
		cseq_beg[entries] = ftell(cfile) * (CHAR_BIT/NBPN);
		seq_beg[entries] = ftell(ofile);
		seqline = 0;
		while ((ibyte = ftell(ofile)) && ++fileline &&
		  (eof = vfgets(&buf, &bufmax, &b, ofile)) != NULL) {
			if (bufmax != obufmax) {
				obufmax = bufmax;
				if (cbuf == NULL)
					cbuf = (PACK_TYPE *)ckalloc(bufmax/(CHAR_BIT/NBPN) + 1);
				else {
					cbuf = (PACK_TYPE *)realloc(cbuf, bufmax/(CHAR_BIT/NBPN) + 1);
					if (cbuf == NULL)
						fatal(ERR_MEM, "out of memory, line length approx. = %d.", bufmax);
				}
			}
			if (*b == '>') {
				put_tail(b, entries);
				seqlen = 0;
				break;
			}
			++seqline;
			len = strlen(b);
			b[--len] = NULLB; /* Remove the terminal newline character */
			if (line_len > 0) {
				if (len == 0) {
					hadzerolen = TRUE;
				}
				else
				if ((seqline == 1 && len > line_len) ||
						hadzerolen ||
						(seqline > 1 && lastlen != line_len))
					fatal(ERR_DBASE, "database sequence lines must have equal length; see line %d",
							fileline);
			}
			else
				if (seqline > 1) {
					if (shortlen > lastlen)
						fatal(ERR_DBASE, "database sequence lines must have equal length; see line %d",
							theline);
					line_len = lastlen;
				}
				else
					if (shortlen < len) {
						theline = fileline;
						shortlen = len;
					}
			lastlen = len;
			ntcount += len;
			seqlen += len;
			if (seqlen > maxlen)
				maxlen = seqlen;
			b = compress(b+len);
		}
	}
	if (eof != NULL && entries >= ENTRY_MAX)
		fatal(ERR_DBASE, "database too big; raise ENTRY_MAX");

	if (line_len == 0)
		line_len = maxlen;

	seq_beg[entries] = ftell(ofile);
	header_beg[entries] = ftell(hdrfile);
	if (entries > 0)
		put_tail(b, entries-1);
	cseq_beg[entries] = ftell(cfile) * (CHAR_BIT/NBPN);

	c_len = ftell(cfile);
	if (clean_bound > 0)
		for (i = clean_count = 0; i < BUCKETS; ++i)
			if (occurs[i] > clean_bound)
				++clean_count;
		

	long_write(dbtype, tfile);
	long_write(dbformat, tfile);

	len = strlen(dbtitle) + 1;
	long_write(len, tfile);
	fwrite(dbtitle, len, 1, tfile);
	if (len%4 != 0) {
		long	i4 = 0;
		fwrite((char *)&i4, 4-(len%4), 1, tfile);
	}

	long_write(line_len, tfile);
	long_write(entries, tfile);
	long_write(maxlen, tfile);
	long_write(ntcount, tfile);
	long_write(c_len, tfile);
	long_write(clean_count, tfile);

	if (clean_count > 0) {
		for (i = 0; i < BUCKETS; ++i)
			if (occurs[i] > clean_bound)
				long_write(i, tfile);
	}
	for (i = 0; i <= entries; ++i)
		long_write((long)cseq_beg[i], tfile);
	for (i = 0; i <= entries; ++i)
		long_write((long)seq_beg[i], tfile);
	for (i = 0; i <= entries; ++i)
		long_write((long)header_beg[i], tfile);
	fwrite(ambiguity_ray, sizeof(ambiguity_ray[0]), entries/CHAR_BIT+1, tfile);

	(void) fclose(cfile);
	(void) fclose(tfile);
	if (hdrfile != NULL)
		(void) fclose(hdrfile);
	if (ofile != NULL)
		(void) fclose(ofile);

	printf("%d 8mers cleaned from database\n", clean_count);
	printf("%s entries (%s nucleotides) packed to %s bytes\n",
			Ltostr(entries,1), Ltostr(ntcount,1), Ltostr(c_len,1));

	exit (0);
}

/* compress - pack buf into cbuf, leaving < 4 characters in buf */

/* randomly map unknown letters into A, C, G, and T */
#define PRESS_NUC(n)	((nt_atob[(n)] < 4) ? nt_atob[(n)] : random_nuc((n), nt_atob[(n)]))

int	nt;

char *
compress(end)
	register char	*end;
{
	register char	*p;
	register PACK_TYPE	*c, *d;
	register long	bucket;
	long	len;

	for (c = cbuf, p = buf; p+4 <= end; ++c, p += 4)
		*c = (PRESS_NUC(p[0])<<6) | (PRESS_NUC(p[1])<<4)
				| (PRESS_NUC(p[2])<<2) | PRESS_NUC(p[3]);

	bucket = *cbuf;
	for (d = cbuf+1; d < c; ++d) {
		bucket = ((bucket<<8) | *d) & mask;
		++occurs[bucket];
	}
	len = strlen(p);
	Nlm_MemCpy((CharPtr)buf, (CharPtr)p, len+1);
	fwrite((char *)cbuf, sizeof(cbuf[0]), c - cbuf, cfile);
	return buf+len;
}

void
put_tail(b, seq_nbr)
	char	*b;
	int		seq_nbr;
{
	PACK_TYPE	c;
	register int	many;
	register int	i;

	/* Save whether an ambiguity letter was encountered in current sequence */
	ambiguity_ray[seq_nbr/CHAR_BIT]
			|= had_ambiguity<<(seq_nbr%CHAR_BIT);
	had_ambiguity = FALSE;

	if ((many = b - buf) > 0) {
		c = PRESS_NUC(buf[0])<<6;
		if (many > 1)
			c |= PRESS_NUC(buf[1])<<4;
		if (many > 2)
			c |= PRESS_NUC(buf[2])<<2;
		fwrite((char *)&c, sizeof(c), 1, cfile);

		cseq_beg[seq_nbr] |= many;
	}

	/* Append magic bytes to act as a sentinel */
	for (i=0; i<NSENTINELS; ++i)
		fputc(NT_MAGIC_BYTE, cfile);

	if (bad_one > 0) {
		fprintf(stderr, "%s:  sequence no. %d contains %d invalid nucleic acid code(s).\n",
			module, entries+1, bad_one);
		bad_one = 0;
		exit(2);
	}
}

/*
	random_nuc()

	input:  a binary-encoded nucleotide abbreviation
	output: a randomly chosen binary nucleotide from the list of matchers
*/
random_nuc(c0, c)
	int		c0, c;
{
	had_ambiguity = 1;
	if (c > NUCID_MAX) {
		if (bad_one == 0)
			fprintf(stderr, "\n%s: sequence #%d\n\t%s\n", module, entries+1, qname);
		if (bad_one < 10) {
			if (isalnum(c0) || ispunct(c0))
				fprintf(stderr, "\tinvalid letter:  \"%c\"\n", c0);
			else
				fprintf(stderr, "\tinvalid letter, numeric value %d\n", c0);
		}
		if (bad_one == 10)
			fprintf(stderr, "\tadditional invalid letter(s) are not displayed.\n");
		++bad_one;
		return RANDOM_BNUC(nt_atob['N']);
	}
	return RANDOM_BNUC(c) & 0x03;
}


#if defined(SIGINT) || defined(SIGHUP) || defined(SIGTERM)
void
sighandler()
{
	char	buf[FILENAME_MAX+1];

	if (fname == NULL)
		exit(1);
	if (cfile != NULL) {
		(void) fclose(cfile);
		sprintf(buf, "%s%s", fname, NT_SEARCHSEQ_EXT);
		unlink(buf);
	}
	if (tfile != NULL) {
		(void) fclose(tfile);
		sprintf(buf, "%s.ntb", fname);
		unlink(buf);
	}
	if (hdrfile != NULL) {
		(void) fclose(hdrfile);
		sprintf(buf, "%s.nhd", fname);
		unlink(buf);
	}
	exit(1);
}
#endif

void
usage()
{
	fprintf(stderr,
		"Purpose:  produce a nt. sequence database for BLAST from a file in FASTA format\n");
	fprintf(stderr,
		"Usage:  %s [-t title] [-c cleanlimit] ntdbname\n", module);
	exit(1);
}

int
long_write(i, fp)
	long	i;
	FILE	*fp;
{
	register CharPtr	ip;

	LONG_BIGENDIAN(i);
	ip = (CharPtr) &i;
	ip += (sizeof(long) - BO_LONG_SIZE);
	return fwrite(ip, BO_LONG_SIZE, 1, fp);
}
