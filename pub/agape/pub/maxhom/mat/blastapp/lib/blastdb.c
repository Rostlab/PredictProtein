#include <ncbi.h>
#include <gishlib.h>
#include "blastapp.h"

DBFilePtr
blast_db_open(dbname, restype)
	CharPtr	dbname;
	int		restype;
{
	DBFile	dbf;
	DBFilePtr	dbfp;
	BDBFILE	PNTR bp;
	char	*dirname = "";
	char	name[FILENAME_MAX];
	long	i;
	long	many;
	int		once;

	Nlm_MemSet(&dbf, 0, sizeof(dbf));
	bp = &dbf.data.blast;

	switch (restype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		bp->hdr_ext = ".ahd";
		bp->tbl_ext = ".atb";
		bp->seq_ext = ".bsq";
		bp->ap = BlastAlphabetFindByName("OldBLASTaa");
		bp->lpb = 1;
		break;
	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		bp->hdr_ext = ".nhd";
		bp->tbl_ext = ".ntb";
		bp->seq_ext = ".csq";
		bp->ap = BlastAlphabetFindByName("NCBI2na");
		bp->lpb = 4;
		bp->ap_alt = BlastAlphabetFindByName("OldBLASTna");
		bp->lpb_alt = 2;
		break;
	default:
		bfatal(ERR_DBASE, "bdb_open: unnrecognized database restype specified:  %d", restype);
	}

	if (strncmp(dbname, DIRDELIMSTR, strlen(DIRDELIMSTR)) == 0)
		once = 2;
	else
		once = 0;

RETRY:
	if (*dirname != NULLB && once < 2)
		(void) sprintf(bp->fname, "%s%s%s", dirname, DIRDELIMSTR, dbname);
	else
		SAFENCPY(bp->fname, dbname, sizeof(bp->fname));

	(void) sprintf(name, "%s%s", bp->fname, bp->tbl_ext);
	bp->tfile = mfil_open(name, "r", MFIL_OPT_ALL);
	if (bp->tfile == NULL) {
		if ((dirname = getenv("BLASTDB")) == NULL)
			dirname = BLASTDB;
		if (++once <= 1)
			goto RETRY;
		bfatal(ERR_MFILE, "couldn't open database file \"%s\".  Make sure you have specified the correct database name and requested a database of the correct type (%s) for use with this program.", name,
		(restype == BLAST_ALPHATYPE_AMINO_ACID ? "protein" : "nucleotide") );
	}

	if (restype == BLAST_ALPHATYPE_NUCLEIC_ACID)
		bp->fafile = fopen(bp->fname, "r");
	bp->fafile_open_tried = TRUE;

	if (mfil_dup_long(bp->tfile, &bp->type, 1) != 1)
		bfatal(ERR_MFILE, "Read error on file %s", name);
	if (mfil_dup_long(bp->tfile, &bp->format, 1) != 1)
		bfatal(ERR_DBASE, "Corrupted database file:  %s", name);

	switch (restype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		if (bp->type != DB_TYPE_PRO)
			bfatal(ERR_DBASE, "\"%s\" is not a protein sequence database.", dbname);
		if (bp->format != AAFORMAT)
			bfatal(ERR_DBASE, "Database format is an incompatible version; rerun \"setdb\".");
		break;
	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		if (bp->type != DB_TYPE_NUC)
			bfatal(ERR_DBASE, "\"%s\" is not a nucleotide sequence database.", dbname);
		if (bp->format != NTFORMAT)
			bfatal(ERR_DBASE, "Database format is an incompatible version; rerun \"pressdb\".");
		break;
	default:
		break;
	}

	if (mfil_dup_long(bp->tfile, &i, 1) != 1)
		bfatal(ERR_DBASE, "Corrupted database file:  %s", name);
	if ((dbf.title = mfil_get(bp->tfile, i)) == NULL)
		bfatal(ERR_DBASE, "Corrupted database file:  %s", name);
	if (i%4 != 0) {
		i = 4 - (i%4);
		mfil_seek(bp->tfile, i, SEEK_CUR);
	}
	if (dbf.title[0] == NULLB)
		dbf.title = dbname;
	dbf.title = StrSave(dbf.title);

	if (restype == BLAST_ALPHATYPE_NUCLEIC_ACID) {
		mfil_dup_long(bp->tfile, (long *)&bp->line_len, 1);
		mfil_dup_long(bp->tfile, (long *)&bp->count, 1);
		mfil_dup_long(bp->tfile, (long *)&bp->maxlen, 1);
		mfil_dup_long(bp->tfile, (long *)&bp->totdblen, 1);
		mfil_dup_long(bp->tfile, (long *)&bp->c_len, 1);
		mfil_dup_long(bp->tfile, (long *)&bp->clean_count, 1); /* sic */
	}
	if (restype == BLAST_ALPHATYPE_AMINO_ACID) {
		mfil_dup_long(bp->tfile, (long *)&bp->count, 1);
		mfil_dup_long(bp->tfile, (long *)&bp->totdblen, 1);
		if (mfil_dup_long(bp->tfile, (long *)&bp->maxlen, 1) != 1 )
			bfatal(ERR_DBASE, "corrupted database file:  %s", name);
	}

	if (bp->count <= 0 || bp->totdblen <= 0)
		bfatal(ERR_DBASE, "Nothing in the database to search!?");

	if (restype == BLAST_ALPHATYPE_NUCLEIC_ACID) {
		/* seek past the list of over-represented 8-mers */
		if (bp->clean_count > 0)
			mfil_seek(bp->tfile, bp->clean_count * BO_LONG_SIZE, SEEK_CUR);
	}

	many = bp->count + 1;
	if (restype == BLAST_ALPHATYPE_NUCLEIC_ACID) {
		bp->cseq_beg = (unsigned long *)mfil_get_long(bp->tfile, many);
		if (bp->cseq_beg == NULL)
			bfatal(ERR_DBASE, "improper offsets in table file.");
	}
	bp->seq_beg = (unsigned long *)mfil_get_long(bp->tfile, many);
	bp->header_beg = (unsigned long *)mfil_get_long(bp->tfile, many);
	if (bp->seq_beg == NULL || bp->header_beg == NULL)
		bfatal(ERR_DBASE, "improper offsets in table file.");
	if (restype == BLAST_ALPHATYPE_NUCLEIC_ACID)
		bp->ambiguity =
				(unsigned char *)mfil_get(bp->tfile, bp->count/CHAR_BIT + 1);

	(void) sprintf(name, "%s%s", bp->fname, bp->seq_ext);
	/* Attach a shared memory segment for the sequence file (if one exists) */
	bp->sfile = mfil_open(name, "r", MFIL_OPT_ALL);
	if (bp->sfile == NULL)
		bfatal(ERR_FOPEN, "Couldn't open database file %s", name);
	if ((bp->membuf = (unsigned char *)MFILE_SP(bp->sfile)) == NULL) {
#ifdef MPROC_AVAIL
		if (restype == BLAST_ALPHATYPE_AMINO_ACID) {
			long	dbsize;

			dbsize = bp->seq_beg[bp->count] - bp->seq_beg[0];
			bp->membuf = (unsigned char *)ckalloc(sizeof(*bp->membuf)*dbsize);
			bp->allocbuf = bp->membuf;
			if (mfil_read((CharPtr)bp->membuf, (size_t)dbsize, 1, bp->sfile) != 1)
				bfatal(ERR_DBASE, "Database read error.");
		}
		else {
			if (bp->c_len > CDBLEN_MAX)
				bfatal(ERR_DBASE, "database is too large; raise CDBLEN_MAX and recompile");
			bp->membuf = (PACK_TYPE *)ckalloc(bp->c_len);
			bp->allocbuf = bp->membuf;
			if (mfil_read((CharPtr)bp->membuf, bp->c_len, 1, bp->sfile) != 1)
				bfatal(ERR_DBASE, "error reading compressed database file %s", name);
		}
#else
		if (restype == BLAST_ALPHATYPE_AMINO_ACID) {
			(void) mfil_seek(bp->sfile, (long)bp->seq_beg[0], SEEK_SET);
			bp->_s_seq = bp->s_seq
					= (unsigned char *)ckalloc(sizeof(*bp->s_seq)*(bp->maxlen+2));
			*bp->s_seq++ = bp->ap->sentinel;
		}
		else {
			bp->_s_seq = bp->s_seq
					= (PACK_TYPE *)ckalloc(bp->maxlen/(CHAR_BIT/NBPN) + 2 + NSENTINELS);
			++bp->s_seq;
			mfil_seek(bp->sfile, bp->cseq_beg[0]/(CHAR_BIT/NBPN), SEEK_SET);
		}
#endif /* !MPROC_AVAIL */
	}

	dbf.link_count = 1;
	dbf.format = BLAST_DBFMT_BLAST;
	dbf.restype = bp->restype = restype;
	dbf.ambig_avail = blast_db_ambig_avail;
	dbf.ambiguous = blast_db_ambiguous;
	dbf.get_seq = blast_db_get_seq;
	dbf.get_specific = blast_db_get_specific;
	dbf.get_str_specific = blast_db_get_str_specific;
	dbf.get_header = blast_db_get_header;
	dbf.count = blast_db_count;
	dbf.totlen = blast_db_totlen;
	dbf.maxlen = blast_db_maxlen;
	dbf.link = blast_db_link;
	dbf.next = blast_db_next;
	dbf.seek = blast_db_seek;
	dbf.tell = blast_db_tell;
	dbf.close = blast_db_close;
	dbf.rel_date = get_reldate(dbf.title);
	dbf.bld_date = get_moddate(name);
	dbfp = (DBFilePtr)mem_dup(&dbf, sizeof(dbf));
	dbfp->root = dbfp;
	return dbfp;
}

long LIBCALL
blast_db_count(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->format != BLAST_DBFMT_BLAST)
		return -1;
	return dbfp->data.blast.count;
}

long LIBCALL
blast_db_totlen(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->format != BLAST_DBFMT_BLAST)
		return -1;
	return dbfp->data.blast.totdblen;
}

long LIBCALL
blast_db_maxlen(dbfp)
	DBFilePtr	dbfp;
{
	if (dbfp == NULL || dbfp->format != BLAST_DBFMT_BLAST)
		return -1;
	return dbfp->data.blast.maxlen;
}

DBFilePtr LIBCALL
blast_db_link(dbfp)
	DBFilePtr	dbfp;
{
	char	fname[FILENAME_MAX+1];
	DBFilePtr	newfp;
	BDBFILE	*bp;
	int		fd;

	if (dbfp == NULL)
		return NULL;

	mproc_lock();
	if (dbfp->format != BLAST_DBFMT_BLAST) {
		dbfp->error = BLAST_DBERR_FORMAT;
		mproc_unlock();
		return NULL;
	}

	newfp = (DBFilePtr)mem_dup(dbfp, sizeof(*dbfp));
	if (newfp != NULL) {
		bp = &newfp->data.blast;
		if (bp->tfile != NULL) {
			sprintf(fname, "%s%s", bp->fname, bp->tbl_ext);
			bp->tfile = mfil_link(bp->tfile, fname, "r");
		}
		if (bp->hfile != NULL) {
			sprintf(fname, "%s%s", bp->fname, bp->hdr_ext);
			bp->hfile = mfil_link(bp->hfile, fname, "r");
		}
		if (bp->sfile != NULL) {
			sprintf(fname, "%s%s", bp->fname, bp->seq_ext);
			bp->sfile = mfil_link(bp->sfile, fname, "r");
		}
		if (bp->fafile != NULL) {
			bp->fafile_open_tried = TRUE;
			bp->fafile = fopen(bp->fname, "r");
		}
	}
	mproc_unlock();

	return newfp;
}

int LIBCALL
blast_db_next(dbfp)
	DBFilePtr	dbfp;
{
	long	id;

	if (dbfp == NULL || dbfp->format != BLAST_DBFMT_BLAST
			|| dbfp->error != BLAST_DBERR_NONE)
		return -1;

	if ((id = dbfp->data.blast.id + 1) < dbfp->data.blast.count) {
		dbfp->data.blast.id = id;
		return 0;
	}
	dbfp->error = BLAST_DBERR_EOF;
	return -1;
}

int
blast_db_seek(dbfp, id)
	DBFilePtr	dbfp;
	long	id;
{
	BDBFILE	*bp;
	int	pad;

	if (dbfp == NULL)
		return -1;
	if (dbfp->format != BLAST_DBFMT_BLAST) {
		dbfp->error = BLAST_DBERR_FORMAT;
		return -1;
	}

	if (id < 0 || id >= dbfp->data.blast.count) {
		dbfp->error = BLAST_DBERR_RANGE;
		return -1;
	}
	if (dbfp->error != BLAST_DBERR_NONE) {
		switch (dbfp->error) {
		case BLAST_DBERR_EOF:
			break;
		default:
			return -1;
		}
		dbfp->error = BLAST_DBERR_NONE;
	}

	dbfp->data.blast.id = id;
	bp = &dbfp->data.blast;
	bp->cseqok = bp->seqok = bp->hdrok = FALSE;
	switch (bp->restype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		bp->seq_reclen = bp->seq_beg[id + 1] - bp->seq_beg[id];
		bp->len = bp->enclen = bp->seq_reclen - 1;
		if (bp->len > bp->maxlen)
			bfatal(ERR_DBASE, "Database sequence longer than maxlen!  Sequence #%lu.", id);
		if (bp->membuf != NULL) {
			bp->seqok = TRUE;
			bp->s_seq = bp->membuf + bp->seq_beg[id];
			return 0;
		}
		mfil_seek(bp->sfile, bp->seq_beg[id], SEEK_SET);
		return 0;
	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		bp->seq_reclen = (bp->cseq_beg[id + 1] / 4) - (bp->cseq_beg[id] / 4);
		bp->enclen = bp->seq_reclen - NSENTINELS;
		bp->len = bp->enclen * 4;
		pad = 4 - bp->cseq_beg[id] & 0x03;
		if (pad != 4)
			bp->len -= pad;
		if (bp->len > bp->maxlen)
			bfatal(ERR_DBASE, "Database sequence longer than maxlen!  Sequence #%lu.", bp->id);
		if (bp->membuf != NULL) {
			bp->cseqok = TRUE;
			bp->s_seq = bp->membuf + bp->cseq_beg[id] / 4;
			return 0;
		}
		mfil_seek(bp->sfile, bp->cseq_beg[id] / 4, SEEK_SET);
		return 0;
	default:
		return 1;
	}
	/*NOTREACHED*/
}

long LIBCALL
blast_db_tell(dbfp)
	DBFilePtr	dbfp;
{
	long	id;

	if (dbfp == NULL || dbfp->error != BLAST_DBERR_NONE)
		return -1;
	if (dbfp->format != BLAST_DBFMT_BLAST) {
		dbfp->error = BLAST_DBERR_FORMAT;
		return -1;
	}
	return (long)dbfp->data.blast.id;
}

/* blast_db_ambig_avail -- returns TRUE if ambiguity data is available */
int LIBCALL
blast_db_ambig_avail(dbfp)
	DBFilePtr	dbfp;
{
	BDBFILE	*bp;

	if (dbfp->format != BLAST_DBFMT_BLAST) {
		dbfp->error = BLAST_DBERR_FORMAT;
		return -1;
	}

	bp = &dbfp->data.blast;
	if (dbfp->restype == BLAST_ALPHATYPE_NUCLEIC_ACID
			&& bp->ambiguity != NULL && bp->fafile != NULL)
		return 1;
	return 0;
}

int LIBCALL
blast_db_ambiguous(dbfp)
	DBFilePtr	dbfp;
{
	register long	id;

	id = (long)dbfp->data.blast.id;
	return dbfp->data.blast.ambiguity[id / 8] & (1 << (id % 8));
}

int LIBCALL
blast_db_get_specific(dbfp, sp, offset, len)
	DBFilePtr	dbfp;
	BLAST_StrPtr	sp;
	size_t	offset;
	size_t	len;
{
	long	id;
	BDBFILE	*bp;

	if (sp->lpb != 1)
		return 1;
	return blast_db_get_str_specific(dbfp, sp->ap, sp->str + offset, offset, len);
}

int LIBCALL
blast_db_get_str_specific(dbfp, ap, str, offset, len)
	DBFilePtr	dbfp;
	BLAST_AlphabetPtr	ap;
	BLAST_LetterPtr	str;
	size_t	offset;
	size_t	len;
{
	BLAST_AlphaMapPtr	amp;
	off_t	seqoff;
	long	id;
	BDBFILE	*bp;

	bp = &dbfp->data.blast;
	id = bp->id;
	switch (bp->restype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		if (bp->seqok) {
			MemCpy(str, bp->s_seq + offset, len);
		}
		seqoff = mfil_tell(bp->sfile);
		mfil_seek(bp->sfile, offset, SEEK_CUR);
		if (mfil_read((CharPtr)str, len, 1, bp->sfile) != 1)
			bfatal(ERR_DBASE, "Error reading sequence segment");
		mfil_seek(bp->sfile, seqoff, SEEK_SET);
		if (bp->ap != ap) {
		}
		return 0;
	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		if (bp->ambiguity == NULL || !bp->ambiguity[id / 8] & (1 << (id % 8))) {
From_compressed:
			if (bp->ap_alt != ap) {
				amp = bp->amp;
				if (amp == NULL || amp->to != ap)
					bp->amp = amp = BlastAlphaMapFindCreate(bp->ap_alt, ap);
				if (bp->cseqok)
					return get_seq_from_cseq_xl((CharPtr)str, offset, len, NULL, bp->s_seq, 0, (CharPtr)amp->map);
				if (bp->membuf != NULL)
					return get_seq_from_cseq_xl((CharPtr)str, offset, len, NULL, bp->membuf, bp->cseq_beg[id]/4, (CharPtr)amp->map);
			}
			if (bp->cseqok)
				return get_seq_from_cseq(str, offset, len, NULL, bp->s_seq, 0);
			if (bp->membuf != NULL)
				return get_seq_from_cseq(str, offset, len, NULL, bp->membuf, bp->cseq_beg[id]/4);
			seqoff = mfil_tell(bp->sfile);
			get_seq_from_cseq(str, offset, len, bp->sfile, NULL, bp->cseq_beg[id]/4);
			mfil_seek(bp->sfile, seqoff, SEEK_SET);
			return 0;
		}
		if (!bp->fafile_open_tried) {
			bp->fafile_open_tried = TRUE;
			bp->fafile = fopen(bp->fname, "r");
		}
		if (bp->fafile == NULL)
			goto From_compressed;

		return get_seq_from_fasta_xl(str, offset, len, bp->fafile, bp->seq_beg[id], bp->line_len, ap);

	default:
		return 1;
	}
	/*NOTREACHED*/
}

int LIBCALL
blast_db_close(dbfp)
	DBFilePtr	dbfp;
{
	BDBFILE	*bp;

	if (dbfp == NULL)
		return -1;
	if (dbfp->format != BLAST_DBFMT_BLAST) {
		dbfp->error = BLAST_DBERR_FORMAT;
		return -1;
	}

	bp = &dbfp->data.blast;

	mproc_lock();
	mfil_close(bp->tfile);
	mfil_close(bp->hfile);
	mfil_close(bp->sfile);
	mproc_unlock();
	if (bp->fafile != NULL)
		fclose(bp->fafile);

	Nlm_MemSet(dbfp, 0, sizeof(*dbfp));
	free(dbfp);
	return 0;
}

int LIBCALL
blast_db_get_seq(dbfp, sp)
	DBFilePtr	dbfp;
	BLAST_StrPtr	sp;
{
	register BDBFILE	*bp;

	if (dbfp == NULL || dbfp->format != BLAST_DBFMT_BLAST
			|| dbfp->error != BLAST_DBERR_NONE)
		return -1;

	bp = &dbfp->data.blast;

	sp->id.data.intvalue = bp->id;
	sp->offset = 0;
	sp->src = NULL;

	switch (dbfp->restype) {
	case BLAST_ALPHATYPE_AMINO_ACID:
		sp->frame = 0;
		sp->ap = bp->ap;
		sp->lpb = bp->lpb;
		sp->offset = 0;
		sp->len = sp->enclen = sp->fulllen = bp->len;
		sp->efflen = bp->len;
		sp->str = bp->s_seq;
		if (!bp->seqok && mfil_read((CharPtr)bp->s_seq, bp->seq_reclen, 1, bp->sfile) != 1)
			bfatal(ERR_DBASE, "Error reading database sequence #%lu.", bp->id);
		bp->seqok = TRUE;
		return 0;
	case BLAST_ALPHATYPE_NUCLEIC_ACID:
		sp->frame = 1;
		sp->ap = bp->ap;
		sp->lpb = bp->lpb;
		sp->offset = 0;
		sp->len = sp->fulllen = bp->len;
		sp->efflen = sp->len;
		sp->enclen = bp->enclen;
		sp->str = bp->s_seq;
		if (!bp->cseqok && mfil_read((CharPtr)bp->s_seq, bp->seq_reclen, 1, bp->sfile) != 1)
				bfatal(ERR_DBASE, "Error reading compressed database sequence #%lu.", bp->id);
		bp->cseqok = TRUE;
		return 0;

	default:
		dbfp->error = BLAST_DBERR_RESTYPE;
		return -1;
	}
}


typedef struct dbtag_node {
	CharPtr	tag;
	int		tagid;
	size_t	taglen;
	size_t	ntokens;
	} dbtag_node, PNTR dbtag_node_ptr;

static int	dbtags_sorted;
static dbtag_node	dbtags[] = {
{ "lcl", Dbtag_lcl, 3, 1 }, /* local = lcl|integer or string */
{ "bbs", Dbtag_bbs, 3, 1 }, /* gibbsq = bbs|integer */
{ "bbm", Dbtag_bbm, 3, 1 }, /* gibbmt = bbm|integer */
{ "gim", Dbtag_gim, 3, 1 }, /* giim = gim|integer */
{ "gb",  Dbtag_gb, 2, 2 }, /* genbank = gb|accession|locus */
{ "emb", Dbtag_emb, 3, 2 }, /* embl = emb|accession|locus */
{ "pir", Dbtag_pir, 3, 2 }, /* pir = pir|accession|name */
{ "sp",  Dbtag_sp, 2, 2 }, /* swissprot = sp|accession|name */
{ "pat", Dbtag_pat, 3, 3 }, /* patent = pat|country|patent number (string)|seq number (integer) */
{ "oth",Dbtag_oth, 3, 3 }, /* other = oth|accession|name|release */
{ "gnl",Dbtag_gnl, 3, 2 }, /* general = gnl|database(string)|id (string or number) */
{ "gi", Dbtag_gi, 2, 1 }, /* gi = gi|integer */
{ "dbj",Dbtag_dbj, 3, 2 }, /* ddbj = dbj|accession|locus */
{ "prf",Dbtag_prf, 3, 2 }, /* prf = prf|accession|name */
{ "pdb",Dbtag_pdb, 3, 2 }, /* pdb = pdb|entry name (string)|chain id (char) */
{ "gp", Dbtag_gp, 2, 2 }  /* UNOFFICIAL "GenPept" gp = gp|accession|locus_# */
	};


/* retrieve the header for the provided HitList */
int LIBCALL
blast_db_get_header(dbfp, sp)
	DBFilePtr	dbfp;
	BLAST_StrPtr	sp;
{
	BDBFILE	*bp;
	unsigned long	id;
	CharPtr	cp;
	size_t	len;

	if (dbfp->format != BLAST_DBFMT_BLAST) {
		dbfp->error = BLAST_DBERR_FORMAT;
		return -1;
	}
	if (dbfp->error != BLAST_DBERR_NONE)
		return -1;
	bp = &dbfp->data.blast;

	if (!bp->hfile_open_tried) {
		DBFilePtr	root;
		BDBFILE	*rbp;
		char	fname[FILENAME_MAX+1];

		root = dbfp->root;
		rbp = &root->data.blast;
		(void) sprintf(fname, "%s%s", bp->fname, bp->hdr_ext);
		mproc_lock();
		if (!rbp->hfile_open_tried) {
			rbp->hfile_open_tried = TRUE;
			rbp->hfile = mfil_open(fname, "r", MFIL_OPT_ALL);
		}
		if (rbp != bp) {
			bp->hfile_open_tried = TRUE;
			bp->hfile = mfil_link(rbp->hfile, fname, "r");
		}
		mproc_unlock();
	}
	if (bp->hfile == NULL) {
		dbfp->error = BLAST_DBERR_NOTFOUND;
		return -1;
	}

	id = bp->id;

	len = bp->header_beg[id+1] - bp->header_beg[id] - 1;
	cp = (CharPtr)ckalloc(len+1);
	if (mfil_seek(bp->hfile, bp->header_beg[id]+1, SEEK_SET) == -1)
		bfatal(ERR_MFILE, "Seek error on header file");
	if (mfil_read(cp, len, 1, bp->hfile) != 1)
		bfatal(ERR_MFILE, "Error reading header for sequence %lu", id);

	sp->name = cp;
	cp[sp->namelen = sp->namemax = sp->namealloc = len] = NULLB;

	parse_defline(&sp->descp, sp->name);
	len = defline_len(sp->descp);
	sp->name = Realloc(sp->name, len+1);
	sp->namelen = build_defline(sp->name, sp->descp);
	if (len != sp->namelen)
		fprintf(stderr, "whoops! %d vs. %d\n", len, sp->namelen), exit(1);

	return 0;
}

int LIBCALL
defline_len(sdp)
	BLAST_SeqDescPtr	sdp;
{
	BLAST_SeqIdPtr	sip;
	int	len;
	int	anyid;

	for (len = 0; sdp != NULL; sdp = sdp->next) {
		anyid = 0;
		if (!gi_option)
			for (sip = sdp->id; sip != NULL; sip = sip->next) {
				if (sip->choice == Dbtag_gi)
					continue;
				len += strlen(sip->data.ptrvalue) + anyid;
				anyid = 1;
			}
		if (!anyid) {
			for (sip = sdp->id; sip != NULL; sip = sip->next) {
				len += strlen(sip->data.ptrvalue) + anyid;
				anyid = 1;
			}
		}
		if (sdp->deflinelen > 0)
			len += sdp->deflinelen + 1;
		if (sdp->next != NULL)
			len += 2;
	}
	return len;
}

int LIBCALL
build_defline(buf, sdp)
	CharPtr	buf;
	BLAST_SeqDescPtr	sdp;
{
	CharPtr	buf0;
	BLAST_SeqIdPtr	sip;
	int		anyid;

	buf0 = buf;
	buf[0] = NULLB;
	for (; sdp != NULL; sdp = sdp->next) {
		anyid = 0;
		if (!gi_option)
			for (sip = sdp->id; sip != NULL; sip = sip->next) {
				if (sip->choice == Dbtag_gi)
					continue;
				if (anyid)
					buf = StrMove(buf, "|");
				anyid = 1;
				buf = StrMove(buf, sip->data.ptrvalue);
			}
		if (!anyid) { /* only gi identifiers were available */
			for (sip = sdp->id; sip != NULL; sip = sip->next) {
				if (anyid)
					buf = StrMove(buf, "|");
				anyid = 1;
				buf = StrMove(buf, sip->data.ptrvalue);
			}
		}
		if (sdp->deflinelen > 0) {
			buf = StrMove(buf, " ");
			buf = StrMove(buf, sdp->defline);
		}
		if (sdp->next != NULL)
			buf = StrMove(buf, " >");
	}
	return buf - buf0;
}

int
dbtag_cmp(t1, t2)
	dbtag_node_ptr	t1, t2;
{
	if (t1->tag == NULL)
		return -1;
	if (t2->tag == NULL)
		return 1;
	return strcmp(t1->tag, t2->tag);
}

int
parse_defline(sdpp, cp)
	BLAST_SeqDescPtr	PNTR sdpp;
	CharPtr	cp;
{
	BLAST_SeqDescPtr	sdp;
	CharPtr	cp2;
	ValNodePtr	vnp;
	int	i;

	if (cp == NULL || *cp == NULLB || sdpp == NULL)
		return 0;

	if (*sdpp == NULL)
		*sdpp = (BLAST_SeqDescPtr)ckalloc0(sizeof(*sdp));
	sdp = *sdpp;

	while (parse_id(sdp, &cp))
		;

	if ((cp2 = strchr(cp, '\001')) != NULL)
		*cp2 = NULLB;
	if ((i = strlen(cp)) > 0 && isspace(cp[i-1]))
		--i;
	sdp->deflinelen = i;
	if (i > 0) {
		sdp->defline = MemDup(cp, i + 1);
		sdp->defline[i] = NULLB;
	}
	else
		sdp->defline = NULL;

	if (cp2 != NULL) {
		*cp2++ = '>';
		parse_defline(&sdp->next, cp2); /* recurse */
	}
	return 0;
}

int LIBCALL
dbtag_id(cp)
	CharPtr	cp;
{
	char	ch, tmptag[80];
	CharPtr	tp, cpsave;
	dbtag_node	tmpnode;
	dbtag_node_ptr	dnp;

	if (cp == NULL)
		return Dbtag_unk;

	if (!dbtags_sorted) {
		mproc_lock();
		if (!dbtags_sorted) {
			Nlm_HeapSort((VoidPtr)&dbtags[0], DIM(dbtags), sizeof(dbtags[0]), (int (*)())dbtag_cmp);
			dbtags_sorted = TRUE;
		}
		mproc_unlock();
	}

	tp = tmptag;
	for (cpsave = cp; (ch = *cp++) != NULLB && tp < &tmptag[DIM(tmptag)-1]; ) {
		if (ch == '|')
			break;
		*tp++ = ch;
	}
	if (ch != '|')
		return Dbtag_unk;

	*tp = NULLB;
	tmpnode.tag = tmptag;
	tmpnode.taglen = tp - tmptag;
	dnp = (dbtag_node_ptr)bsearch(&tmpnode, (VoidPtr)&dbtags[0], DIM(dbtags), sizeof(dbtags[0]), (int (*)())dbtag_cmp);
	if (dnp == NULL)
		return Dbtag_unk;
	return dnp->tagid;
}

int
parse_id(dp, cpp)
	BLAST_SeqDescPtr	dp;
	CharPtr	PNTR cpp;
{
	BLAST_SeqIdPtr	sip, sip2;
	dbtag_node_ptr	dnp;
	CharPtr	cp, cpsave, tp;
	dbtag_node	tmpnode;
	char	ch, tmptag[80];
	int	i, tagid, ntoks;

	if (dp == NULL || cpp == NULL || *cpp == NULL || **cpp == NULLB)
		return 0;

	if (!dbtags_sorted) {
		mproc_lock();
		if (!dbtags_sorted) {
			Nlm_HeapSort((VoidPtr)&dbtags[0], DIM(dbtags), sizeof(dbtags[0]), (int (*)())dbtag_cmp);
			dbtags_sorted = TRUE;
		}
		mproc_unlock();
	}

	cpsave = *cpp;
	tp = tmptag;
	for (cp = cpsave; (ch = *cp++) != NULLB && tp < &tmptag[DIM(tmptag)-1]; ) {
		if (ch == '|')
			break;
		*tp++ = ch;
	}
	if (ch != '|')
		return 0;

	*tp = NULLB;
	tmpnode.tag = tmptag;
	tmpnode.taglen = tp - tmptag;
	dnp = (dbtag_node_ptr)bsearch(&tmpnode, (VoidPtr)&dbtags[0], DIM(dbtags), sizeof(dbtags[0]), (int (*)())dbtag_cmp);
	if (dnp == NULL)
		return 0;

	ntoks = dnp->ntokens;
	tagid = dnp->tagid;
	/* skip over the tokens */
	while ((ch = *cp) != NULLB && ntoks-- > 0) {
		while ((ch = *cp++) != '|' && ch != NULLB) {
			if (ch == '\\') { /* escaped character */
				if ((ch = *cp++) == NULLB)
					return 0;
			}
			/* last tok separated from defline? */
			if (ntoks == 0 && (isspace(ch) || ch == '\001'))
				break;
		}
		if (ch == NULLB)
			--cp;
	}
	if (ntoks > 0)
		return 0;

	ch = cp[-1];
	cp[-1] = NULLB;
	*cpp = cp;

	ValNodeCopyStr(&dp->id, tagid, cpsave);
	cp[-1] = ch;
	return 1;
}
