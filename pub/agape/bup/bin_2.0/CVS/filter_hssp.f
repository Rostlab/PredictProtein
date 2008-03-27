*----------------------------------------------------------------------*
*                                                                      *
*     FORTRAN code for program FILTER_HSSP                             *
*             filters an HSSP file                                     *
*                                                                      *
*----------------------------------------------------------------------*
*                                                                      *
*     Author:                                                          *
*                                                                      *
*     Reinhard Schneider        Mar,        1990      version 1.0      *
*                         ->    Mar,        1997      version 2.0      *
*     LION			http://www.lion-ag/                    *
*     D-69120 Heidelberg	schneider@lion-ag.de                   *
*                                                                      *
*                                                                      *
*     Changes:                                                         *
*                                                                      *
*     Burkhard Rost		May,        1998      version 2.1      *
*                   		Oct,        1998      version 2.2      *
*                                                                      *
*     EMBL/LION			http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg	rost@embl-heidelberg.de                *
*                                                                      *
*----------------------------------------------------------------------*
*                                                                      *
*     General note:   - uses library lib-maxhom.f                      *
*                                                                      *
*----------------------------------------------------------------------*
*                                                                      *
*     Description (from RS):                                           *
*                                                                      *
C=======================================================================
C 
C ------------------------------
C INSTALLATION:
C ------------------------------
C 
C 1. change the character variable "metricfile" to your enviroment path
C 2. compile it
C 
C=======================================================================
C  INCREASE THE NUMBER OF FOLLOWING THREE PARAMETER IF NECESSARY
C=======================================================================
C 
C  maxaligns    = maximal number of alignments in a HSSP-file
C  maxres       = maximal number of residues in a PDB-protein
C  maxcore      = maximal space for storing the alignments
C  maxins       = maximal number of insertions in alignend sequences
C  maxinsbuffer = total size for buffer of all insertions
C 
C=======================================================================
C
C ------------------------------
C  Explanation of variables:
C ------------------------------
C
C  maxaa= 20 amino acids
C  pdbid= Brookhaven Data Bank identifier
C  header,compound,source,author= informations about the PDB-protein
C  pdbseq= amino acid sequence of the PDB-protein
C  chainid= chain identifier (chain A etc.)
C  secstr= DSSP secondary structure summary
C  bp1,bp2= beta-bridge partner
C  cols= DSSP hydrogen bonding patterns for turns and helices,
C        geometrical bend, chirality, one character name of beta-ladder
C        and of beta-sheet
C  sheetlabel= chain identifier of beta bridge partner
C  seqlength= number of amino acids in the PDB-protein
C  pdbno= residue number as in PDB file
C  nchain= number of different chains in pdbid.DSSP data set
C  kchain= number of chains used in HSSP data set
C  nalign= number of alignments
C  acc= solvated residue surface area in A**2
C  emblid= EMBL/SWISSPROT identifier of the alignend protein
C  strid= if the 3-D structure of this protein is known, then strid
C         (structure ID) is the Protein Data Bank identifier as taken
C         from the EMBL/SWISSPROT entry
C  protname= one line description of alignend protein
C  aliseq= sequential storage for the alignments
C  alipointer= points to the beginning of alignment X ( 1>= X <=nalign )
C  ifir,ilas= first and last position of the alignment in the test
C             protein
C  jfir,jlas= first and last position of the alignment in the alignend
C             protein
C  lali= length of the alignment excluding insertions and deletions
C  ngap= number of insertions and deletions in the alignment
C  lgap= total length of all insertions and deletions
C  lenseq= length of the entire sequence of the alignend protein
C  ide= percentage of residue identity of the alignment
C  var= sequence variability as derived from the nalign alignments
C  seqprof= relative frequency for each of the 20 amino acids
C  nocc= number of alignend sequences spanning this position (including
C        the test sequence
C  ndel= number of sequences with a deletion in the test protein at this
C        position
C  nins= number of sequences with an insertion in the test protein at
C        this position
C  entropy= entropy measure of sequence variability at this position
C  relent= relative entropy (entropy normalized to the range 0-100)
C======================================================================
C 
C ------------------------------
C CHANGES:
C ------------------------------
C  IDEMAX_ANSWER =  maximal pairwise sequence identity to not get
C                   excluded
*----------------------------------------------------------------------*

      PROGRAM FILTER_HSSP

      IMPLICIT        NONE

C----
C---- overall memory limiting parameters
C----
      INTEGER         MAXALIGNS,MAXRES,MAXCORE,MAXAA,MAXINS
      INTEGER         MAXINSBUFFER
      PARAMETER      (MAXALIGNS=             19999)
      PARAMETER      (MAXRES=                10000)
      PARAMETER      (MAXINS=                50000)
      PARAMETER      (MAXINSBUFFER=        4321432)
      PARAMETER      (MAXCORE=             3213213)
      PARAMETER      (MAXAA=                    20)
C----
C---- other parameters
C----
      INTEGER         MAXSTEP
C---- used for variability
      INTEGER         NTRANS,MAXSTRSTATES,MAXIOSTATES
      REAL            SMIN,SMAX
      PARAMETER      (MAXSTEP=                 100)
      PARAMETER      (NTRANS=                   26)
      PARAMETER      (MAXSTRSTATES=              3)
      PARAMETER      (MAXIOSTATES=               4)
      PARAMETER      (SMIN=                      0.0)
      PARAMETER      (SMAX=                      1.0)
C     only used to get rid of INDEX command (CPU time)
      INTEGER         NASCII
      PARAMETER      (NASCII=                  256)
C     files
      INTEGER         KIN,KOUT,KMAT,KISO
      PARAMETER      (KIN=                      10)
      PARAMETER      (KOUT=                     11)
      PARAMETER      (KMAT=                     12)
      PARAMETER      (KISO=                     14)

C----
C---- attributes of sequence with known structure
C----
      CHARACTER*40    PDBID,HEADER
      CHARACTER*80    COMPOUND,SOURCE,AUTHOR,CHAINREMARK
      CHARACTER       PDBSEQ(MAXRES),CHAINID(MAXRES),SECSTR(MAXRES),
     +                COLS(MAXRES)*7,SHEETLABEL(MAXRES)
      INTEGER         SEQLENGTH,PDBNO(MAXRES),NCHAIN,KCHAIN,NALIGN,
     +                NALIGN_FILTER,BP1(MAXRES),BP2(MAXRES),ACC(MAXRES)
C----
C---- attributes of aligned sequences
C----
      CHARACTER*40    EMBLID(MAXALIGNS)
      CHARACTER*6     STRID(MAXALIGNS)
      CHARACTER*10    ACCNUM(MAXALIGNS)
      CHARACTER*60    PROTNAME(MAXALIGNS)
      CHARACTER       ALISEQ(MAXCORE),EXCLUDEFLAG(MAXALIGNS)
      INTEGER         ALIPOINTER(MAXALIGNS),
     +                IFIR(MAXALIGNS),ILAS(MAXALIGNS),JFIR(MAXALIGNS),
     +                JLAS(MAXALIGNS),LALI(MAXALIGNS),NGAP(MAXALIGNS),
     +                LGAP(MAXALIGNS),LENSEQ(MAXALIGNS),
     +                INSNUMBER,INSALI(MAXINS),INSPOINTER(MAXINS),
     +                INSLEN(MAXINS),INSBEG_1(MAXINS),INSBEG_2(MAXINS)
C----
C---- buffer to store insertions of alignments
C----
      CHARACTER       INSBUFFER(MAXINSBUFFER)
      REAL            IDE(MAXALIGNS),SIM(MAXALIGNS)
C----
C---- attributes of profile
C----
      INTEGER         VAR(MAXRES),SEQPROF(MAXRES,MAXAA),NOCC(MAXRES),
     +                NDEL(MAXRES),NINS(MAXRES),RELENT(MAXRES)
      REAL            ENTROPY(MAXRES),CONSWEIGHT(MAXRES),CONSWEIGHT_MIN
C----
C---- miscellaneous
C----
      LOGICAL         LERROR,LCONSERV,LHSSP_LONG_ID,LIDE_100,LSAME
      CHARACTER*9     CDATE
C----
C---- threshold
C----
      LOGICAL         LCONSIDER,LFORMULA,LALL
      INTEGER         ISOLEN(MAXSTEP),NSTEP,ISAFE
      REAL            ISOIDE(MAXSTEP),IDEMAX
      CHARACTER*80    IDEMAX_ANSWER
C----
C---- value of best match
C----
      INTEGER         NSTRSTATES,NIOSTATES
C----
C---- comparison metric
C----
      REAL            MATRIX(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                     MAXSTRSTATES,MAXIOSTATES)
C----
C---- normalised to sum over 0 (by SETCONSERVATION)
C---- 
      REAL            SIMCONSERV(NTRANS,NTRANS)

      REAL            IORANGE(MAXSTRSTATES,MAXIOSTATES)

      CHARACTER       CSTRSTATES*(MAXSTRSTATES),CIOSTATES*(MAXIOSTATES)
C---- 
C---- 
C......
      CHARACTER*80    HSSPLINE,DATABASE
      CHARACTER*132   CPARAMETER(10),LINE
      CHARACTER       TRANS*(NTRANS)
C.....
      CHARACTER*132   HSSPFILE,OUTFILE,METRICFILE,OUTFILE_TMP,
     +                DISTANCE_TABLE,DISTANCE_TABLE_TMP
      CHARACTER*80    THRESHOLD,EXCLUDE_IDENTICAL,TEMPNAME
      CHARACTER       PID*40,LOWER*26
C----
C---- only used to get rid of INDEX command (CPU time)
C----
      INTEGER         LOWERPOS(NASCII)
      INTEGER         MATPOS(NASCII)
C----
C---- internal
C----
      INTEGER         ISTART,ISTOP,I,J,ILINE,NPARALINE,IALIGN,JALIGN,
     +                NRES,ILEN
      REAL            DISTANCE
      CHARACTER*80    CTEMP
      LOGICAL         LDIST_TABLE

C---- end of variables
C---- ------------------------------------------------------------------

C     order of amino acids in HSSP sequence profile
      TRANS=        'VLIMFWYGAPSTCHRKQENDBZX!-.'
C     used to convert lower case char from DSSP-seq to 'C' (Cys)
      LOWER=        'abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,NASCII)
      INSNUMBER=0
      DO I=1,MAXINS
         INSPOINTER(I)=0
         INSLEN(I)=    0
         INSBEG_1(I)=  0
         INSBEG_2(I)=  0
      ENDDO
C---- ------------------------------------------------------------------
C     defaults:  CHANGE TO LOCAL ENVIROMENT
C---- ------------------------------------------------------------------
      METRICFILE=       '/home/rost/pub/max/mat/Maxhom_GCG.metric'
      THRESHOLD=        'formula+5'
      IDEMAX_ANSWER=    '1.00'
      HSSPFILE=         ' '	
      LFORMULA=         .FALSE.
      LALL=             .FALSE.
      DATABASE=         ' '
      HSSPLINE=         ' '
      EXCLUDE_IDENTICAL='NO'
      DISTANCE_TABLE=   'NO'
      LIDE_100=         .FALSE.
      LINE=             ' '
      LDIST_TABLE=      .FALSE.
      LHSSP_LONG_ID=    .FALSE.

      CONSWEIGHT_MIN=   0.01

C---- end of settings
C---- ------------------------------------------------------------------

C---- ------------------------------------------------------------------
C---- blabla for user
C---- ------------------------------------------------------------------
      WRITE(*,*)' '
      WRITE(*,*)'****************************  HSSP-FILE FILTER ***'//
     +          '*****************************'
      WRITE(*,*)' R. Schneider, 1990 and later, EMBL-Heidelberg'
      WRITE(*,*)'**************************************************'//
     +          '****************************'
      WRITE(*,*)' '
      WRITE(*,*)' If you want to exclude an alignment independent'//
     +     ' from the threshold, mark the'
      WRITE(*,*)' alignment in your "personal" copy of the HSSP-'//
     +     'file in the following way:'
      WRITE(*,*)' '
      WRITE(*,*)' type a character (non blank, overstrike mode)'//
     +     ' after the alignment number'
      WRITE(*,*)' in the PROTEINS-block, like the "*" in:'
      WRITE(*,*)' '
      WRITE(*,*)'                        15*: REV1_YEAST'
      WRITE(*,*)'                          ^'

C---- ------------------------------------------------------------------
C---- prompt for input
C---- ------------------------------------------------------------------
C---- query name of input file      
      CALL GETCHAR(132,HSSPFILE,  '  HSSP input file ?')
      CALL GETPIDCODE(HSSPFILE,PID)
      CALL STRPOS(PID,ISTART,ISTOP)

C---- query name of output file
      OUTFILE=PID(1:ISTOP)//'.hssp_fil'
      CALL GETCHAR(132,OUTFILE_TMP,   '  HSSP output file ?')
      CALL STRPOS(OUTFILE_TMP,ISTART,ISTOP)
      OUTFILE(1:)=OUTFILE_TMP(ISTART:ISTOP)

C---- query metric used to convert identity to similarity
      CALL GETCHAR(132,METRICFILE,'  metric file (HSSP-VARIABILITY) ?')

C---- query cut-off threshold 
      CALL GETCHAR(80,THRESHOLD, '  threshold ? /n '//
     +     ' /n '//
     +     '  formula+x   : formula value plus x percent /n '//
     +     '  ALL         : no threshold or /n '//
     +     '  "file name" : with threshold specification ')
C---- maximal pairwise sequence identity
      CALL GETCHAR(80,IDEMAX_ANSWER,'  exclude too similar pairs?/n'//
     +     ' positive real number < 1 (like: 0.8)')
      CALL LOWTOUP(IDEMAX_ANSWER,80)
      CALL STRPOS(IDEMAX_ANSWER,ISTART,ISTOP)
      CALL READ_REAL_FROM_STRING(IDEMAX_ANSWER(ISTART:ISTOP),IDEMAX)
C---- end of new stuff

C---- query 'you want to clean up identical pairs?'
      CALL GETCHAR(80,EXCLUDE_IDENTICAL,'  clean up 100% '//
     +     'identical pairs ?')

C---- query name of distance table (or NO for no table written)
      CALL GETCHAR(132,DISTANCE_TABLE,'  write distance table ?/n'//
     +     '  NO          : default no file written/n'//
     +     '  YES         : default file = PDBid_distance.table/n'//
     +     '  FILE_NAME   : written into this file written/n')
      DISTANCE_TABLE_TMP=DISTANCE_TABLE
      CALL LOWTOUP(DISTANCE_TABLE_TMP,80)	
      IF (INDEX(DISTANCE_TABLE_TMP,'NO') .NE. 0) THEN
         LDIST_TABLE=.FALSE.
      ELSE IF (INDEX(DISTANCE_TABLE_TMP,'YES') .NE. 0) THEN
         LDIST_TABLE=.TRUE.
         DISTANCE_TABLE="DEFAULT"
      ELSE 
         LDIST_TABLE=.TRUE.
      ENDIF

      TEMPNAME(1:)=THRESHOLD
      CALL LOWTOUP(TEMPNAME,80)	
      IF (INDEX(TEMPNAME,'FORMULA') .NE. 0) THEN
         LFORMULA=.TRUE.
         I=INDEX(THRESHOLD,'+')
         J=INDEX(THRESHOLD,'-')
C---- extract 'safe' range
         IF (I.NE.0) THEN
            CALL STRPOS(THRESHOLD,ISTART,ISTOP)
            READ(THRESHOLD(I+1:ISTOP),'(I2)')ISAFE
            WRITE(*,'(A,I2,A)')' use formula value +',isafe,' %'
         ELSE IF (J.NE.0) THEN
            CALL STRPOS(THRESHOLD,ISTART,ISTOP)
            READ(THRESHOLD(J:ISTOP),'(I2)')ISAFE
            WRITE(*,'(A,I2,A)')' use formula value ',isafe,' %'
         ELSE
            ISAFE=0
         ENDIF
      ELSE IF (INDEX(TEMPNAME,'ALL') .NE. 0) THEN
         LALL=.TRUE.
      ELSE
C---- read threshold from file (for details look in routine gethsspcut)
         CALL GETHSSPCUT(KISO,MAXSTEP,THRESHOLD,ISOLEN,ISOIDE,NSTEP)
      ENDIF
      WRITE(*,*)'=================================================='//
     +     '============================'
      CALL LOWTOUP(EXCLUDE_IDENTICAL,80)
      IF ( INDEX(EXCLUDE_IDENTICAL,'Y') .NE. 0) LIDE_100=.TRUE.

C---- ------------------------------------------------------------------
C---- read HSSP-file
C---- ------------------------------------------------------------------

      CALL READHSSP(KIN,HSSPFILE,LERROR,
     +     MAXRES,MAXALIGNS,MAXCORE,MAXINS,MAXINSBUFFER,
     +     PDBID,HEADER,COMPOUND,SOURCE,AUTHOR,SEQLENGTH,
     +     NCHAIN,KCHAIN,CHAINREMARK,NALIGN,
     +     EXCLUDEFLAG,EMBLID,STRID,IDE,SIM,IFIR,ILAS,
     +     JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,ACCNUM,PROTNAME,
     +     PDBNO,PDBSEQ,CHAINID,SECSTR,COLS,SHEETLABEL,BP1,
     +     BP2,ACC,NOCC,VAR,ALISEQ,ALIPOINTER,
     +     SEQPROF,NDEL,NINS,ENTROPY,RELENT,CONSWEIGHT,
     +     INSNUMBER,INSALI,INSPOINTER,INSLEN,INSBEG_1,
     +     INSBEG_2,INSBUFFER,LCONSERV,LHSSP_LONG_ID)
      IF (LERROR) THEN
         WRITE(*,*)'*** ERROR reading HSSP-file (after READHSSP)'
         STOP
      ENDIF
C---- 
C---- read 'old' database specification and parameter
C---- 
      CALL OPEN_FILE(KIN,HSSPFILE,'old,readonly',lerror)
      DO WHILE(INDEX(LINE,'HSSP').EQ.0)
         READ(KIN,'(A)')LINE
      ENDDO
      I=LEN(HSSPLINE)
      HSSPLINE(1:I)=LINE(1:I)
      DO WHILE (INDEX(LINE,'SEQBASE').EQ.0 .AND.
     +     INDEX(LINE,'DATABASE').EQ.0)
         READ(KIN,'(A)')LINE
      ENDDO
      I=LEN(DATABASE)
      DATABASE(1:I)=LINE(1:I)
      LINE=' '
      ILINE=1
      DO WHILE (INDEX(LINE,'THRESHOLD').EQ.0)
         READ(KIN,'(A)')LINE
         IF (INDEX(LINE,'PARAMETER').NE.0) THEN
            CPARAMETER(ILINE)=LINE(11:)
            ILINE=ILINE+1
         ENDIF
      ENDDO
      NPARALINE=ILINE-1
      CLOSE(KIN)
      NRES=SEQLENGTH+KCHAIN-1
C---- 
C---- read SIMILARITY MATRIX
C---- 
      CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES,NIOSTATES,NSTRSTATES,NIOSTATES,
     +     CSTRSTATES,CIOSTATES,IORANGE,KMAT,METRICFILE,MATRIX)
C---- 
      CALL SCALEMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     MATRIX,SMIN,SMAX,0.0,0.0)
C---- 
C---- GET ACTUAL DATE
C---- 
      CDATE=' '
      CALL GETDATE (CDATE)
C---- 

C---- ------------------------------------------------------------------
C---- check all pairwise identities, and exclude all pairs i,j with:
C---- j > i, and identity(i,j) > IDEMAX
C---- ------------------------------------------------------------------
      IF (IDEMAX.LT.1) THEN
         CALL DIST_TABLE_EXCLUDE(IDEMAX,NALIGN,NRES,IDE,IFIR,ILAS,
     +        LALI,ALIPOINTER,ALISEQ,EXCLUDEFLAG,NTRANS,TRANS)
      END IF
C---- 
C---- ------------------------------------------------------------------
C---- get number of alignments after 'clean up'
C---- ------------------------------------------------------------------
      WRITE(*,*)'=================================================='//
     +     '============================'
      NALIGN_FILTER=0
      DO IALIGN=1,NALIGN
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            CALL CHECKHSSPCUT(LALI(IALIGN),IDE(IALIGN)*100,ISOLEN,
     +           ISOIDE,NSTEP,LFORMULA,LALL,ISAFE,LCONSIDER,DISTANCE)
            IF (LCONSIDER) THEN
               NALIGN_FILTER=NALIGN_FILTER+1
C---- 
C---- for exclusion of identical alignments
C---- 
               IF (LIDE_100) THEN
                  IF (IDE(IALIGN).EQ.1.0 .AND. IFIR(IALIGN).EQ.1 .AND.
     +                 ILAS(IALIGN) .EQ. NRES ) THEN
                     EXCLUDEFLAG(IALIGN)='*'
                     WRITE(*,'(i6,a)')ialign,'. ALIGNMENT excluded: '//
     +                    'identical to master'
                     NALIGN_FILTER=NALIGN_FILTER-1
                  ELSE
C---- 
C---- loop over other alignments and check for identity
C---- 
                     DO JALIGN=IALIGN+1,NALIGN
                        IF (EXCLUDEFLAG(JALIGN) .EQ. ' ') THEN
                           IF (IFIR(IALIGN) .EQ. IFIR(JALIGN) .AND.
     +                          ILAS(IALIGN) .EQ. ILAS(JALIGN) ) THEN
                              LSAME=.TRUE.
                              I=0
                              ILEN=ILAS(IALIGN)-IFIR(IALIGN)+1
                              DO WHILE( LSAME .AND. I .LE. ILEN)
                                 IF (ALISEQ(ALIPOINTER(IALIGN)+I).NE.
     +                               ALISEQ(ALIPOINTER(JALIGN)+I)) THEN
                                    LSAME=.FALSE.
                                 ENDIF
                                 I=I+1
                              ENDDO
                              IF (LSAME) THEN
                                 EXCLUDEFLAG(JALIGN)='*'
                                 WRITE(*,'(I6,A,I6)')JALIGN,
     +                          ' ALIGNMENT excluded: identical to'//
     +                                ' alignment: ',ialign
                              ENDIF
                           ENDIF
                        ENDIF
                     ENDDO
                  ENDIF
               ENDIF
            ELSE
               EXCLUDEFLAG(IALIGN)='*'
               WRITE(*,'(I6,A)')IALIGN,'. ALIGNMENT excluded: threshold'
            ENDIF
         ELSE
            WRITE(*,'(I6,A)')IALIGN,'. ALIGNMENT excluded: marked'
         ENDIF
      ENDDO

C---- --------------------------------------------------
C---- write header of HSSP file
C---- --------------------------------------------------
      IF (CHAINREMARK .NE. ' ') THEN
         CTEMP(1:)=CHAINREMARK(1:)
         I=INDEX(CTEMP,':')
         CHAINREMARK(1:)=CTEMP(I+1:)
      ENDIF
C---- 
C---- write header
C---- 
      CALL HSSPHEADER(KOUT,OUTFILE,HSSPLINE,PDBID,CDATE,
     +     DATABASE,CPARAMETER,NPARALINE,
     +     THRESHOLD,ISAFE,LFORMULA,
     +     HEADER,COMPOUND,SOURCE,AUTHOR,SEQLENGTH,
     +     NCHAIN,KCHAIN,CHAINREMARK,NALIGN_FILTER)
      
C---- END IF empty!
      IF (NALIGN_FILTER .EQ. 0) THEN
         WRITE(6,*)'-*- WARNING FILTER_HSSP file empty (no ali found)!'
         WRITE(KOUT,'(A)')'//'
         CLOSE(KOUT)
         STOP
      ENDIF

C---- --------------------------------------------------
C---- conservation weights, profile, and variance
C---- --------------------------------------------------
C---- 
C---- 98-10: br & rs 
C---- normalise MATRIX -> SIMCONSERV
C----    such that SIMCONSERV has an average of 0
C---- 
      CALL SETCONSERVATION(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES,NIOSTATES,CSTRSTATES,CIOSTATES,IORANGE,KMAT,
     +     METRICFILE,MATRIX,SIMCONSERV)
C---- 
C---- 98-10: br
C---- 98-10: br & rs 
C---- compile conservation weights
C---- 
      CALL GETCONSWEIGHT_BR(MAXSTRSTATES,MAXIOSTATES,
     +     MAXRES,MAXALIGNS,NTRANS,NASCII,NALIGN,NRES,
     +     IDE,IFIR,ILAS,LALI,ALIPOINTER,PDBSEQ,ALISEQ,
     +     EXCLUDEFLAG,TRANS,MATRIX,SIMCONSERV,MATPOS,
     +     CONSWEIGHT_MIN,CONSWEIGHT)
C---- 
C---- rescale metric
C---- 
      CALL SCALEMETRIC(NTRANS,TRANS,MAXSTRSTATES,
     +     MAXIOSTATES,MATRIX,SMIN,SMAX,0.0,0.0)
C---- 
C---- calculate variability
C---- 
      CALL CALC_VAR(NALIGN,NRES,PDBSEQ,IDE,IFIR,ILAS,
     +     ALIPOINTER,ALISEQ,EXCLUDEFLAG,MAXSTRSTATES,
     +     MAXIOSTATES,NTRANS,TRANS,MATRIX,VAR)
C---- 
C---- profiles
C---- 
      CALL CALC_PROF(MAXRES,MAXAA,NRES,PDBSEQ,NALIGN,EXCLUDEFLAG,IDE,
     +     IFIR,ILAS,ALISEQ,ALIPOINTER,TRANS,SEQPROF,
     +     NOCC,NDEL,NINS,ENTROPY,RELENT)
C---- 
C---- finally write new HSSP file
C---- 
      CALL WRITE_HSSP(KOUT,MAXRES,NALIGN,NRES,EMBLID,STRID,ACCNUM,IDE,
     +     SIM,IFIR,ILAS,JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,
     +     PROTNAME,ALIPOINTER,ALISEQ,PDBNO,CHAINID,PDBSEQ,
     +     SECSTR,COLS,BP1,BP2,SHEETLABEL,ACC,NOCC,VAR,
     +     SEQPROF,NDEL,NINS,ENTROPY,RELENT,CONSWEIGHT,
     +     INSNUMBER,INSALI,INSPOINTER,INSLEN,INSBEG_1,
     +     INSBEG_2,INSBUFFER,ISOLEN,ISOIDE,NSTEP,
     +     LFORMULA,LALL,ISAFE,EXCLUDEFLAG,LCONSERV,
     +     LHSSP_LONG_ID)
C---- 
C---- additionally write table with sequence identity ij ?
C---- 
      IF (LDIST_TABLE) THEN
         IF (DISTANCE_TABLE .EQ. 'DEFAULT') THEN
            CALL STRPOS(PDBID,ISTART,ISTOP)
            DISTANCE_TABLE=PDBID(ISTART:ISTOP)//'_distance.table'
         ENDIF
         CALL DIST_TABLE2(KOUT,DISTANCE_TABLE,NALIGN,NRES,PDBID,
     +        EMBLID,IDE,IFIR,ILAS,LALI,ALIPOINTER,ALISEQ,
     +        EXCLUDEFLAG,NTRANS,TRANS)
         WRITE(6,'(A,A)')'--- distance table into file:',DISTANCE_TABLE
      ENDIF
      END
C     end of FILTER_HSSP
C......................................................................

C......................................................................
C     SUB DIST_TABLE
      SUBROUTINE DIST_TABLE(KOUT,FILENAME,NALIGN,NRES,
     +     PDB_ID,EMBL_ID,IDE,IFIR,ILAS,LALI,
     +     ALIPOINTER,ALISEQ,EXCLUDEFLAG,NTRANS,CTRANS)
CPLAN speed up this routine
C RS May 93
C calculate and write distance table for all pairs of alignend
C sequences in one HSSP-file
C
C---- import
      IMPLICIT        NONE  
      INTEGER         KOUT,NALIGN,NRES,NTRANS,
     +                IFIR(*),ILAS(*),LALI(*),ALIPOINTER(*)
      REAL            IDE(*)
      CHARACTER       FILENAME*(*)
      CHARACTER*(*)   ALISEQ(*),EXCLUDEFLAG(*),PDB_ID*(*),EMBL_ID(*)
C---- allowed sequence symbols
      CHARACTER*(*)   CTRANS
C----
C---- internal
C----
      INTEGER         MAXRES,NASCII,MAXLEN
      PARAMETER      (NASCII=                  256)
      PARAMETER      (MAXRES=                10000)
      PARAMETER      (MAXLEN=                20000)
      INTEGER         IALIGN_SEQ(MAXRES),JALIGN_SEQ(MAXRES),
     +                I,IALIGN,JALIGN,ILEN,IRES,
     +                IPOS,JPOS,IBEG,IEND,KPOS,IAGR,ISTEP
      REAL            SEQDIST
      CHARACTER       LINE*(MAXLEN)
      LOGICAL         LERROR
C---- only used to get rid of INDEX command (CPU TIME)
      INTEGER         MATPOS(NASCII)
C---- ------------------------------------------------------------------
C---- now work on it      
C---- ------------------------------------------------------------------
      WRITE(6,*)' dist_table'
C---- 
C---- calculate variability only for the 22 (BZ) amino acids
C---- 
      DO I=1,NASCII 
         MATPOS(I)=0
      ENDDO
      CALL GETPOS(CTRANS(1:22),MATPOS,NASCII)
      IF (NRES .GT. MAXRES) THEN
         WRITE(6,*)'ERROR: NRES .GT. MAXRES IN DIST_TABLE'
         WRITE(6,*)'**** INCREASE MAXRES max=',
     +        MAXRES,' is ',NRES,' ****'
         STOP
      ENDIF
C---- 
C---- initialize 
C----
      DO I=1,NRES
         IALIGN_SEQ(I)=0
         JALIGN_SEQ(I)=0
      ENDDO
      LINE=' '
      ISTEP=14
      KPOS=13
C----
C---- output file
C----
      CALL OPEN_FILE(KOUT,FILENAME,'NEW,RECL=50000',LERROR)
      CALL STRPOS(PDB_ID,IBEG,IEND)
      WRITE(KOUT,'(A,A)')PDB_ID(IBEG:IEND),' distance table' 
      WRITE(KOUT,'(A,I6)')'number of alignments: ',nalign 
C----
C---- first line gives identities and alignment lengths of the HSSP
C----
      WRITE(LINE(KPOS:),'(A,A)')'|',PDB_ID(1:12)
      KPOS=KPOS+ISTEP
      DO IALIGN=1,NALIGN-1
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            IF (KPOS .GT. MAXLEN) THEN
               WRITE(6,*)'*** ERROR: MAXLEN overflow in DIST_TABLE'//
     +              ' (filter_hssp) '
	       WRITE(6,*)'*** INCREASE DIMENSION to > ',KPOS
	       STOP
            ENDIF
            WRITE(LINE(KPOS:),'(A,A)')'|',EMBL_ID(IALIGN)
            KPOS=KPOS+ISTEP
         ENDIF
      ENDDO
      CALL STRPOS(LINE,IBEG,IEND)
      WRITE(KOUT,*)LINE(1:IEND)
      DO I=1,IEND
         LINE(I:I)='='
      ENDDO
      WRITE(KOUT,*)LINE(1:IEND)

C---- ------------------------------------------------------------------
C---- loop over all alignments
C---- ------------------------------------------------------------------
      DO IALIGN=1,NALIGN
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            LINE=' '
            KPOS=27
C----
C---- first distance to pdb-seq
C----
            SEQDIST=1.0-IDE(IALIGN)
            WRITE(LINE(1:),'(A,A,2X,F4.2,1X,I5)')
     +           EMBL_ID(IALIGN),'|',SEQDIST,LALI(IALIGN)
            IPOS=ALIPOINTER(IALIGN)-IFIR(IALIGN)
C----
C---- store alignment sequence in integer array
C----
            DO IRES=IFIR(IALIGN),ILAS(IALIGN)
               IALIGN_SEQ(IRES)=MATPOS( ICHAR( ALISEQ(IPOS+IRES) ) )
               IF ( IALIGN_SEQ(IRES) .EQ. 0) THEN
	          IF (ALISEQ(IPOS+IRES) .GE. 'a' .AND. 
     +                 ALISEQ(IPOS+IRES) .LE. 'z') THEN
                     IALIGN_SEQ(IRES)=
     +                    MATPOS(ICHAR(ALISEQ(IPOS+IRES))-32)
                  ENDIF
               ENDIF
            ENDDO
C----
C---- loop over pair partners
C----
            DO JALIGN=1,IALIGN-1
	       IF ( EXCLUDEFLAG(JALIGN) .EQ. ' ') THEN
                  JPOS=ALIPOINTER(JALIGN)-IFIR(JALIGN)
                  DO IRES=IFIR(JALIGN),ILAS(JALIGN)
                     JALIGN_SEQ(IRES)=MATPOS(ICHAR(ALISEQ(JPOS+IRES)))
                     IF ( JALIGN_SEQ(IRES) .EQ. 0) THEN
                        IF (ALISEQ(JPOS+IRES) .GE. 'a' .AND. 
     +                       ALISEQ(JPOS+IRES) .LE. 'z') THEN
                           JALIGN_SEQ(IRES)=
     +                          MATPOS(ICHAR(ALISEQ(JPOS+IRES))-32)
                        ENDIF
                     ENDIF
                  ENDDO
                  SEQDIST=0.0
                  IAGR=0
                  ILEN=0
C----
C---- get distance between overlap of alignend sequences
C----
                  IBEG= MAX(IFIR(IALIGN),IFIR(JALIGN))
                  IEND= MIN(ILAS(IALIGN),ILAS(JALIGN))
                  DO IRES= IBEG,IEND
                     IF ( IALIGN_SEQ(IRES) .NE. 0 .AND.
     +                    JALIGN_SEQ(IRES) .NE. 0) THEN
                        IF (IALIGN_SEQ(IRES) .EQ. JALIGN_SEQ(IRES)) THEN
                           IAGR=IAGR+1
                        ENDIF
                        ILEN=ILEN+1
                     ENDIF
                  ENDDO
                  IF (ILEN .NE. 0) THEN
                     SEQDIST=1.0-(FLOAT(IAGR)/ILEN)
                  ENDIF
C----
C---- build up output line
C----
                  WRITE(LINE(KPOS:),'(A,2X,F4.2,1X,I5)')'|',SEQDIST,ILEN
                  KPOS=KPOS+14
                  IF (KPOS .GT. MAXLEN) THEN
                     WRITE(6,*)'*** ERROR: MAXLEN overflow in'//
     +                    '  DIST_TABLE (lib-maxhom)'
                     WRITE(6,*)'*** INCREASE DIMENSION > ',KPOS
                     STOP
                  ENDIF
               ENDIF
            ENDDO
C----       end loop over pairs
            CALL STRPOS(LINE,IBEG,IEND)
            WRITE(KOUT,'(A)')LINE(IBEG:IEND)
         ENDIF
      ENDDO
C---- end loop over all alignments
      CLOSE(KOUT)
      RETURN
      END
C     END DIST_TABLE
C......................................................................

C......................................................................
C     SUB DIST_TABLE2
      SUBROUTINE DIST_TABLE2(KOUT,FILENAME,NALIGN,NRES,
     +     PDB_ID,EMBL_ID,IDE,IFIR,ILAS,LALI,
     +     ALIPOINTER,ALISEQ,EXCLUDEFLAG,NTRANS,CTRANS)
CPLAN speed up this routine
C RS May 93
C calculate and write distance table for all pairs of alignend
C sequences in one HSSP-file
C
C---- import
      IMPLICIT        NONE  
      INTEGER         KOUT,NALIGN,NRES,NTRANS,
     +                IFIR(*),ILAS(*),LALI(*),ALIPOINTER(*)
      REAL            IDE(*)
      CHARACTER       FILENAME*(*)
      CHARACTER*(*)   ALISEQ(*),EXCLUDEFLAG(*),PDB_ID*(*),EMBL_ID(*)
C---- allowed sequence symbols
      CHARACTER*(*)   CTRANS
C----
C---- internal
C----
      INTEGER         MAXRES,NASCII,MAXLEN
      PARAMETER      (NASCII=                  256)
      PARAMETER      (MAXRES=                10000)
      PARAMETER      (MAXLEN=                20000)
      INTEGER         IALIGN_SEQ(MAXRES),JALIGN_SEQ(MAXRES),
     +                I,IALIGN,JALIGN,ILEN,IRES,
     +                IPOS,JPOS,IBEG,IEND,KPOS,IAGR,ISTEP
      REAL            SEQDIST
      CHARACTER       LINE*(MAXLEN)
      LOGICAL         LERROR
      CHARACTER       XC
C---- only used to get rid of INDEX command (CPU TIME)
      INTEGER         MATPOS(NASCII)
C---- ------------------------------------------------------------------
C---- now work on it      
C---- ------------------------------------------------------------------
C---- spacer
      XC=CHAR(9)
      XC='  '
      XC='|'
      WRITE(6,*)' dist_table'
C---- 
C---- calculate variability only for the 22 (BZ) amino acids
C---- 
      DO I=1,NASCII 
         MATPOS(I)=0
      ENDDO
      CALL GETPOS(CTRANS(1:22),MATPOS,NASCII)
      IF (NRES .GT. MAXRES) THEN
         WRITE(6,*)'ERROR: NRES .GT. MAXRES IN DIST_TABLE'
         WRITE(6,*)'**** INCREASE MAXRES ****'
         STOP
      ENDIF
C---- 
C---- initialize 
C----
      DO I=1,NRES
         IALIGN_SEQ(I)=0
         JALIGN_SEQ(I)=0
      ENDDO
      LINE=' '
      ISTEP=12
      KPOS=12

C---- ------------------------------------------------------------------
C---- output file
C----
      CALL OPEN_FILE(KOUT,FILENAME,'NEW,RECL=50000',LERROR)
C----
C---- header
C----
      CALL STRPOS(PDB_ID,IBEG,IEND)
      WRITE(KOUT,'(A)')   '# HSSP_FILTER DISTANCE TABLE'
      WRITE(KOUT,'(A,A)') '# PDBID     ',PDB_ID(IBEG:IEND)
      WRITE(KOUT,'(A,I6)')'# NALIGN    ',NALIGN
      WRITE(KOUT,'(A,A)') '# NOTATION  ','ROWS:      i = 1   .. nali'
      WRITE(KOUT,'(A,A)') '# NOTATION  ','EACH ROW : j = i+1 .. nali'
      WRITE(KOUT,'(A,A)') '# NOTATION  ','EACH CELL: PIDE,LALI'
C----
C---- how long will lines be?
C----
      KPOS=ISTEP
      DO IALIGN=2,NALIGN
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            IF (KPOS .GT. MAXLEN) THEN
               WRITE(6,*)'*** ERROR: MAXLEN overflow in DIST_TABLE'//
     +              ' (lib-maxhom)'
	       WRITE(6,*)'*** INCREASE DIMENSION!!'
	       STOP
            ENDIF
            KPOS=KPOS+ISTEP
         ENDIF
      ENDDO
      IEND=KPOS
C---- beautiful FORTRAN ASCII
      DO I=1,IEND
         LINE(I:I)='='
      ENDDO
      WRITE(KOUT,'(A,A)')"# ",LINE(1:IEND)
C----
C---- first line gives identities and alignment lengths of the HSSP
C----
      WRITE(LINE(1:),'(A)')PDB_ID(1:12)
      KPOS=ISTEP
      DO IALIGN=2,NALIGN
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            WRITE(LINE(KPOS:),'(A,A)')XC,EMBL_ID(IALIGN)
            KPOS=KPOS+ISTEP
         ENDIF
      ENDDO
      CALL STRPOS(LINE,IBEG,IEND)
      WRITE(KOUT,*)LINE(1:IEND)

C---- ------------------------------------------------------------------
C---- loop over all alignments
C---- ------------------------------------------------------------------
      DO IALIGN=1,NALIGN
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            LINE=' '
            KPOS=1+ISTEP
C---- 
C---- first distance to pdb-seq
C----
            SEQDIST=1.0-IDE(IALIGN)
            WRITE(LINE(1:),'(A,A,I4,A1,I5)')
     +           EMBL_ID(IALIGN)(1:ISTEP),XC, 
     +           INT(100*SEQDIST),',',LALI(IALIGN)
            IPOS=ALIPOINTER(IALIGN)-IFIR(IALIGN)
C----
C----       store alignment sequence in integer array (for i)
C----
            DO IRES=IFIR(IALIGN),ILAS(IALIGN)
               IALIGN_SEQ(IRES)=MATPOS( ICHAR( ALISEQ(IPOS+IRES) ) )
               IF ( IALIGN_SEQ(IRES) .EQ. 0) THEN
	          IF (ALISEQ(IPOS+IRES) .GE. 'a' .AND. 
     +                 ALISEQ(IPOS+IRES) .LE. 'z') THEN
                     IALIGN_SEQ(IRES)=
     +                    MATPOS(ICHAR(ALISEQ(IPOS+IRES))-32)
                  ENDIF
               ENDIF
            ENDDO
C----
C---- loop over pair partners
C----
            DO JALIGN=(IALIGN+1),NALIGN
	       IF ( EXCLUDEFLAG(JALIGN) .EQ. ' ') THEN
                  JPOS=ALIPOINTER(JALIGN)-IFIR(JALIGN)
C----
C----             store alignment sequence in integer array (for j)
C----
                  DO IRES=IFIR(JALIGN),ILAS(JALIGN)
                     JALIGN_SEQ(IRES)=MATPOS(ICHAR(ALISEQ(JPOS+IRES)))
                     IF ( JALIGN_SEQ(IRES) .EQ. 0) THEN
                        IF (ALISEQ(JPOS+IRES) .GE. 'a' .AND. 
     +                       ALISEQ(JPOS+IRES) .LE. 'z') THEN
                           JALIGN_SEQ(IRES)=
     +                          MATPOS(ICHAR(ALISEQ(JPOS+IRES))-32)
                        ENDIF
                     ENDIF
                  ENDDO
                  SEQDIST=0.0
                  IAGR=0
                  ILEN=0
C----
C----             get distance between overlap of alignend sequences
C----
                  IBEG= MAX(IFIR(IALIGN),IFIR(JALIGN))
                  IEND= MIN(ILAS(IALIGN),ILAS(JALIGN))
                  DO IRES= IBEG,IEND
                     IF ( IALIGN_SEQ(IRES) .NE. 0 .AND.
     +                    JALIGN_SEQ(IRES) .NE. 0) THEN
                        IF (IALIGN_SEQ(IRES) .EQ. JALIGN_SEQ(IRES)) THEN
                           IAGR=IAGR+1
                        ENDIF
                        ILEN=ILEN+1
                     ENDIF
                  ENDDO
                  IF (ILEN .NE. 0) THEN
                     SEQDIST=1.0-(FLOAT(IAGR)/ILEN)
                  ENDIF
C----
C---- build up output line
C----
C                 WRITE(LINE(KPOS:),'(A,2X,F4.2,1X,I5)')'|',SEQDIST,ILEN
                  WRITE(LINE(KPOS:),'(A,I4,A1,I5)')
     +                 XC, INT(100*SEQDIST),',',ILEN
                  KPOS=KPOS+ISTEP
                  IF (KPOS .GT. MAXLEN) THEN
                     WRITE(6,*)'*** ERROR: MAXLEN overflow in'//
     +                    '  DIST_TABLE (lib-maxhom)'
                     WRITE(6,*)'*** INCREASE DIMENSION!!'
                     STOP
                  ENDIF
               ENDIF
            ENDDO
C----       end loop over pairs
            CALL STRPOS(LINE,IBEG,IEND)
            WRITE(KOUT,'(A)')LINE(IBEG:IEND)
         ENDIF
      ENDDO
C---- end loop over all alignments
      CLOSE(KOUT)
      RETURN
      END
C     END DIST_TABLE2
C......................................................................

C......................................................................
C     SUB DIST_TABLE_EXCLUDE
      SUBROUTINE DIST_TABLE_EXCLUDE(IDEMAX,NALIGN,NRES,IDE,
     +     IFIR,ILAS,LALI,ALIPOINTER,ALISEQ,EXCLUDEFLAG,NTRANS,CTRANS)
C---- 
C---- BR May 98
C---- 
C---- Calculate pairwise levels of sequence identity, and returns
C---- EXCLUDEFLAG(iali)='*' if the identity of alignment number
C---- 'iali' to any other sequence is above IDEMAX (threshold input)
C---- 
C---- out:           output is the changed vectore EXCLUDEFLAG
C---- 
C---- import
      IMPLICIT        NONE  
      INTEGER         NALIGN,NRES,NTRANS,
     +                IFIR(*),ILAS(*),LALI(*),ALIPOINTER(*)
      REAL            IDE(*),IDEMAX
      CHARACTER*(*)   ALISEQ(*),EXCLUDEFLAG(*)
C---- allowed sequence symbols
      CHARACTER*(*)   CTRANS
C----
C---- internal
C----
      INTEGER         MAXRES,NASCII,MAXLEN
      PARAMETER      (NASCII=                  256)
      PARAMETER      (MAXRES=                10000)
      PARAMETER      (MAXLEN=               100000)
C     br 2000-04: was 20000!
C      PARAMETER      (MAXLEN=               20000)
      INTEGER         IALIGN_SEQ(MAXRES),JALIGN_SEQ(MAXRES),
     +                I,IALIGN,JALIGN,ILEN,IRES,
     +                IPOS,JPOS,IBEG,IEND,KPOS,IAGR,ISTEP
      REAL            SEQIDE
      CHARACTER       LINE*(MAXLEN)
      LOGICAL         LERROR
C---- only used to get rid of INDEX command (CPU TIME)
      INTEGER         MATPOS(NASCII)
C---- ------------------------------------------------------------------
C---- now work on it      
C---- ------------------------------------------------------------------
      WRITE(6,*)  '--- lib-maxhom:DIST_TABLE_EXCLUDE'
C---- 
C---- calculate variability only for the 22 (BZ) amino acids
C---- 
      DO I=1,NASCII 
         MATPOS(I)=0
      ENDDO
      CALL GETPOS(CTRANS(1:22),MATPOS,NASCII)
      IF (NRES .GT. MAXRES) THEN
         WRITE(6,*)'*** ERROR: NRES .GT. MAXRES IN DIST_TABLE_EXCLUDE'
         WRITE(6,*)'*** INCREASE MAXRES to > ',NRES
         STOP
      ENDIF
C---- 
C---- initialize 
C----
      DO I=1,NRES
         IALIGN_SEQ(I)=0
         JALIGN_SEQ(I)=0
      ENDDO
      ISTEP=14
      KPOS=13
C----
C---- first line gives identities and alignment lengths of the HSSP
C----
      KPOS=KPOS+ISTEP
      DO IALIGN=1,NALIGN-1
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            IF (KPOS .GT. MAXLEN) THEN
               WRITE(6,*)'*** ERROR: MAXLEN overflow in'//
     +              ' DIST_TABLE_EXCLUDE (lib-maxhom)'
	       WRITE(6,*)'*** INCREASE DIMENSION to > ',KPOS
	       STOP
            ENDIF
            KPOS=KPOS+ISTEP
         ENDIF
      ENDDO

C---- ------------------------------------------------------------------
C---- loop over all alignments
C---- ------------------------------------------------------------------
      DO IALIGN=1,NALIGN
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            KPOS=27
C----
C---- first distance to pdb-seq
C----
            SEQIDE=IDE(IALIGN)
            IPOS=ALIPOINTER(IALIGN)-IFIR(IALIGN)
C----
C---- store alignment sequence in integer array
C----
            DO IRES=IFIR(IALIGN),ILAS(IALIGN)
               IALIGN_SEQ(IRES)=MATPOS( ICHAR( ALISEQ(IPOS+IRES) ) )
               IF ( IALIGN_SEQ(IRES) .EQ. 0) THEN
	          IF (ALISEQ(IPOS+IRES) .GE. 'a' .AND. 
     +                 ALISEQ(IPOS+IRES) .LE. 'z') THEN
                     IALIGN_SEQ(IRES)=
     +                    MATPOS(ICHAR(ALISEQ(IPOS+IRES))-32)
                  ENDIF
               ENDIF
            ENDDO
C----
C---- loop over pair partners
C----
C            DO JALIGN=1,IALIGN-1
            DO JALIGN=IALIGN+1,NALIGN
	       IF ( EXCLUDEFLAG(JALIGN) .EQ. ' ') THEN
                  JPOS=ALIPOINTER(JALIGN)-IFIR(JALIGN)
                  DO IRES=IFIR(JALIGN),ILAS(JALIGN)
                     JALIGN_SEQ(IRES)=MATPOS(ICHAR(ALISEQ(JPOS+IRES)))
                     IF ( JALIGN_SEQ(IRES) .EQ. 0) THEN
                        IF (ALISEQ(JPOS+IRES) .GE. 'a' .AND. 
     +                       ALISEQ(JPOS+IRES) .LE. 'z') THEN
                           JALIGN_SEQ(IRES)=
     +                          MATPOS(ICHAR(ALISEQ(JPOS+IRES))-32)
                        ENDIF
                     ENDIF
                  ENDDO
                  SEQIDE=0.0
                  IAGR=0
                  ILEN=0
C----
C---- get distance between overlap of alignend sequences
C----
                  IBEG= MAX(IFIR(IALIGN),IFIR(JALIGN))
                  IEND= MIN(ILAS(IALIGN),ILAS(JALIGN))
                  DO IRES= IBEG,IEND
                     IF ( IALIGN_SEQ(IRES) .NE. 0 .AND.
     +                    JALIGN_SEQ(IRES) .NE. 0) THEN
                        IF (IALIGN_SEQ(IRES) .EQ. JALIGN_SEQ(IRES)) THEN
                           IAGR=IAGR+1
                        ENDIF
                        ILEN=ILEN+1
                     ENDIF
                  ENDDO
                  IF (ILEN .NE. 0) THEN
                     SEQIDE=(FLOAT(IAGR)/ILEN)
                  ENDIF
C---- exclude if too similar
                  IF (SEQIDE.GE.IDEMAX) THEN
                     EXCLUDEFLAG(JALIGN)='*'
                  ENDIF
C----
C---- build up output line
C----
                  KPOS=KPOS+14
                  IF (KPOS .GT. MAXLEN) THEN
                     WRITE(6,*)'*** ERROR: MAXLEN overflow in'//
     +                    '  DIST_TABLE_EXCLUDE (lib-maxhom)'
                     WRITE(6,*)'*** INCREASE DIMENSION > ',KPOS
                     STOP
                  ENDIF
               ENDIF
            ENDDO
C----       end loop over pairs
         ENDIF
      ENDDO
C---- end loop over all alignments
      RETURN
      END
C     END DIST_TABLE_EXCLUDE
C......................................................................

C......................................................................
C     SUB GETCONSWEIGHT_BR
      SUBROUTINE GETCONSWEIGHT_BR(MAXSTRSTATES,MAXIOSTATES,
     +     MAXRES,MAXALIGNS,NTRANS,NASCII,
     +     NALIGN,NRES,IDE,IFIR,ILAS,LALI,ALIPOINTER,PDBSEQ,ALISEQ,
     +     EXCLUDEFLAG,CTRANS,MATRIX,SIMCONSERV,MATPOS,
     +     CONSWEIGHT_MIN,CONSWEIGHT)
C---- 
C---- BR May 98 + Oct 98
C---- 
C---- Calculate the conservation weight, taking into account the
C---- EXCLUDEFLAG(iali)='*' if the identity of alignment number
C---- 'iali' to any other sequence is above IDEMAX (threshold input)
C---- 
C---- 
C---- out:           output is the conservation weight
C---- 
C---- ------------------------------------------------------------------
C----
C---- formula: 
C----                 nali
C----                 -----
C----                 \      (1 - IDE(s,a,b)) * SIM(s,a,b)
C----          CW(s)=  >     -----------------------------       
C----                 /                DISTSUM
C----                 -----
C----                 a,b
C----                 
C---- with:    CW(s):       conservation weight for residue s
C----          a,b:         alignment between protein a and b
C----          IDE(s,a,b):  identity of residue s in a and s in b
C----                       = 0 || 1
C----          SIM(s,a,b):  similarity of residue s in a and s in b
C----                 
C----          DISTSUM(s):  sum over all distances at position s
C----                       and the following definition:
C---- 
C----                 nali   nres = overlap (a,b)
C----                 -----  ----
C----                 \      \             delta(s,a,b)
C----     DISTSUM(s)=  >      >     ------------------------------
C----                 /      /      number of overlapping residues
C----                 -----  ----
C----                 a,b    s
C----                 
C---- with:    delta(s,a,b) = 1 if residue s in a = residue s in b
C----                         0 else
C---- 
C---- normalise:
C----          finally normalised weights to have an average of 1:
C---- 
C----                 nres
C----                 -----
C----                 \      
C----        NORM(s)=  >     CW(s)
C----                 /           
C----                 -----
C----                 s
C---- 
C----     CW_NORM(s)= CW(s) / NORM
C---- 
C---- 
C---- ------------------------------------------------------------------
C---- 

      IMPLICIT        NONE  

C---- 
C---- import
C---- 
C     parameters for array
      INTEGER         MAXSTRSTATES,MAXIOSTATES,MAXRES,MAXALIGNS,
     +                NTRANS,NASCII
C     actual values
      INTEGER         NALIGN,NRES
C     pointer arrays
      INTEGER         IFIR(MAXALIGNS),ILAS(MAXALIGNS),
     +                ALIPOINTER(MAXALIGNS)
C     alignment length lali(i) length of ali between PDBSEQ and ali i
      INTEGER         LALI(MAXALIGNS)
C     guide sequence
      CHARACTER       PDBSEQ(MAXRES)
C     all aligned sequences
      CHARACTER*(*)   ALISEQ(*)
C     flags (take ' ', else other)
      CHARACTER*(*)   EXCLUDEFLAG(MAXALIGNS)
C     percentage sequence identity
      REAL            IDE(MAXALIGNS),IDEMAX
C     comparison metric
      REAL            MATRIX(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                      MAXSTRSTATES,MAXIOSTATES)   
C     normalised to sum over 0 (by SETCONSERVATION)
      REAL            SIMCONSERV(NTRANS,NTRANS)
C     allowed sequence symbols
      CHARACTER*(*)   CTRANS
C     minimal conservation weight
      REAL            CONSWEIGHT_MIN
C     only used to get rid of INDEX command (CPU time)
      INTEGER         MATPOS(NASCII)

C----
C---- output from sbr
C----
C     conservation weight
      REAL            CONSWEIGHT(MAXRES)

C---- ------------------------------------------------------------------
C---- internal
C---- ------------------------------------------------------------------
C----
C      INTEGER        NASCII,MAXLEN
      INTEGER         MAXRES_LOC,MAXLEN
      PARAMETER      (MAXRES_LOC=            10000)
      PARAMETER      (MAXLEN=                20000)
      INTEGER         IALIGN_SEQ(MAXRES_LOC),JALIGN_SEQ(MAXRES_LOC),
     +                I,J,IALIGN,JALIGN,ILEN,IRES,
     +                IPOS,JPOS,IBEG,IEND,KPOS,IAGR,ISTEP,ISAFERANGE,
     +                IALIGN_SEQTMP,JALIGN_SEQTMP
      INTEGER         NOCC(MAXRES_LOC)

C---- big: seq ide distance for pair i,j
      REAL            SUM,MEAN,XVAL
      INTEGER         NPOS

      REAL            SIMDIST_POS(MAXRES_LOC)
      REAL            SEQDIST_POS(MAXRES_LOC)

      REAL            SEQDIST
      CHARACTER       LINE*(MAXLEN)
      LOGICAL         LERROR

C---- ------------------------------------------------------------------
C---- 
C---- defaults, ini

C---- 
C---- FORMULA+ISAFERANGE -> include into averaging
      ISAFERANGE= 5
C---- br: make 'safer' for weights
      ISAFERANGE= 5
C---- ------------------------------------------------------------------
C---- now work on it      
C---- ------------------------------------------------------------------
      WRITE(6,*)  '--- GETCONSWEIGHT_BR begin'
C---- 
C---- calculate variability only for the 22 (BZ) amino acids
C---- 
      DO I=1,NASCII 
         MATPOS(I)=0
      ENDDO
      CALL GETPOS(CTRANS(1:22),MATPOS,NASCII)
      IF (NRES .GT. MAXRES) THEN
         WRITE(*,*)'*** ERROR: NRES .GT. MAXRES IN GETCONSWEIGHT_BR'
         WRITE(*,*)'*** INCREASE MAXRES ****'
         STOP
      ENDIF
C---- 
C---- ERROR!
C---- 
      IF (NRES .LE. 0) RETURN
C---- 
C---- initialize 
C----
      DO I=1,NRES
         IALIGN_SEQ(I)= 0
         JALIGN_SEQ(I)= 0
         SIMDIST_POS(I)=0.0
         SEQDIST_POS(I)=0.0
         NOCC(I)=       0
      ENDDO
      
C---- ------------------------------------------------------------------
C---- guide against all
C---- ------------------------------------------------------------------
C---- store PDB sequence in integer array
      DO IRES=1,NRES
         IALIGN_SEQ(IRES)=MATPOS(ICHAR(PDBSEQ(IRES)))
         IF ( IALIGN_SEQ(IRES) .EQ. 0) THEN
            IF ( PDBSEQ(IRES) .GE. 'a' .AND. 
     +           PDBSEQ(IRES) .LE. 'z') THEN
               IALIGN_SEQ(IRES)=
     +              MATPOS(ICHAR(PDBSEQ(IRES))-32)
            ENDIF
         ENDIF
      ENDDO
      
C----
C---- loop over all aligned sequences
C----
      DO JALIGN=1,NALIGN
         IF ( EXCLUDEFLAG(JALIGN) .EQ. ' ') THEN
C----          store alignment sequence in integer array (for j)
            JPOS=ALIPOINTER(JALIGN)-IFIR(JALIGN)
            DO IRES=IFIR(JALIGN),ILAS(JALIGN)
               JALIGN_SEQ(IRES)=MATPOS(ICHAR(ALISEQ(JPOS+IRES)))
               IF ( JALIGN_SEQ(IRES) .EQ. 0) THEN
                  IF (ALISEQ(JPOS+IRES) .GE. 'a' .AND. 
     +                 ALISEQ(JPOS+IRES) .LE. 'z') THEN
                     JALIGN_SEQ(IRES)=
     +                    MATPOS(ICHAR(ALISEQ(JPOS+IRES))-32)
                  ENDIF
               ENDIF
            ENDDO
C---- 
C---- passed into SBR: IDE(i)
C---- 
            SEQDIST= 1.0 - IDE(JALIGN)
C----
C----       get overlap of aligned sequences
C----
            IBEG= MAX(1,   IFIR(JALIGN))
            IEND= MIN(NRES,ILAS(JALIGN))
            DO IRES= IBEG,IEND
               IF ( (IALIGN_SEQ(IRES) .NE. 0) .AND.
     +              (JALIGN_SEQ(IRES) .NE. 0) ) THEN
C---- 
C---- count up number of pairs found for current residue
C---- 
                  NOCC(IRES)=NOCC(IRES)+1
C----
C----             position specific distances
C----               
                  SEQDIST_POS(IRES)=
     +                 SEQDIST_POS(IRES) + SEQDIST
                  SIMDIST_POS(IRES)=
     +                 SIMDIST_POS(IRES) + 
     +                 SEQDIST * SIMCONSERV(IALIGN_SEQ(IRES),
     +                                      JALIGN_SEQ(IRES))
               END IF
            END DO
         ENDIF
C----    end of: exclude?
      ENDDO
C---- end loop over all sequences aligned to guide

C---- ------------------------------------------------------------------
C---- all against all: get all pair distances
C---- ------------------------------------------------------------------
      DO IALIGN=1,NALIGN
C----    to exclude?
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
C----       store alignment sequence in integer array (for i)
            IPOS=ALIPOINTER(IALIGN)-IFIR(IALIGN)
            DO IRES=IFIR(IALIGN),ILAS(IALIGN)
               IALIGN_SEQ(IRES)=MATPOS( ICHAR( ALISEQ(IPOS+IRES) ) )
               IF ( IALIGN_SEQ(IRES) .EQ. 0) THEN
	          IF (ALISEQ(IPOS+IRES) .GE. 'a' .AND. 
     +                 ALISEQ(IPOS+IRES) .LE. 'z') THEN
                     IALIGN_SEQ(IRES)=
     +                    MATPOS(ICHAR(ALISEQ(IPOS+IRES))-32)
                  ENDIF
               ENDIF
            ENDDO
C----
C----       loop over pair partners
C----
            DO JALIGN=IALIGN+1,NALIGN
	       IF ( EXCLUDEFLAG(JALIGN) .EQ. ' ') THEN
C----             store alignment sequence in integer array (for j)
                  JPOS=ALIPOINTER(JALIGN)-IFIR(JALIGN)
                  DO IRES=IFIR(JALIGN),ILAS(JALIGN)
                     JALIGN_SEQ(IRES)=MATPOS(ICHAR(ALISEQ(JPOS+IRES)))
                     IF ( JALIGN_SEQ(IRES) .EQ. 0) THEN
                        IF (ALISEQ(JPOS+IRES) .GE. 'a' .AND. 
     +                       ALISEQ(JPOS+IRES) .LE. 'z') THEN
                           JALIGN_SEQ(IRES)=
     +                          MATPOS(ICHAR(ALISEQ(JPOS+IRES))-32)
                        ENDIF
                     ENDIF
                  ENDDO
C----
C---- get distance between overlap of aligned sequences
C----
                  IAGR=0
                  ILEN=0
                  IBEG= MAX(IFIR(IALIGN),IFIR(JALIGN))
                  IEND= MIN(ILAS(IALIGN),ILAS(JALIGN))
                  DO IRES=IBEG,IEND
                     IF ( IALIGN_SEQ(IRES) .NE. 0 .AND.
     +                    JALIGN_SEQ(IRES) .NE. 0) THEN

C---- count up number of pairs found for current residue
                        NOCC(IRES)=NOCC(IRES)+1

                        IF (IALIGN_SEQ(IRES).EQ.JALIGN_SEQ(IRES)) THEN
                           IAGR=IAGR+1
                        ENDIF
                        ILEN=ILEN+1
                     ENDIF
                  ENDDO
                  IF (ILEN .NE. 0) THEN
                  
                     SEQDIST= 1.0 - (FLOAT(IAGR)/ILEN)

                     DO IRES=IBEG,IEND
                        IF ( IALIGN_SEQ(IRES).NE.0 .AND.
     +                       JALIGN_SEQ(IRES).NE.0 ) THEN
                           SEQDIST_POS(IRES)=
     +                          SEQDIST_POS(IRES) + SEQDIST
                           SIMDIST_POS(IRES)=
     +                          SIMDIST_POS(IRES) + 
     +                          SEQDIST * SIMCONSERV(IALIGN_SEQ(IRES),
     +                                               JALIGN_SEQ(IRES))
                        ENDIF
                     END DO
                  END IF
               ENDIF
C----          end of: exclude?
            ENDDO
C----       end loop over pairs
         ENDIF
      ENDDO
C---- end loop over all alignments

C---- ------------------------------------------------------------------
C---- assign conservation weights
C---- ------------------------------------------------------------------

      DO IRES=1,NRES
         IF ((SEQDIST_POS(IRES) .GT. 0) .AND.
     +       (NOCC(IRES) .GT. 0) ) THEN
            CONSWEIGHT(IRES)=
     +           SIMDIST_POS(IRES)/SEQDIST_POS(IRES)
C            write(6,'(a,i4,a,f8.3,a,f8.3,a,f8.3)')'xx before norm i=',
C     +           ires,' cw=',consweight(ires),
C     +           ' sim=',simdist_pos(ires),
C     +           ' dis=',seqdist_pos(ires)
         ELSE 
            CONSWEIGHT(IRES)=1.0
         END IF
C----
C----    no negative values for conservation weight
C----
         IF (CONSWEIGHT(IRES) .LT. CONSWEIGHT_MIN) THEN
            CONSWEIGHT(IRES)=CONSWEIGHT_MIN
         ENDIF
      END DO

C---- ------------------------------------------------------------------
C---- weight conservation weights (average = 1)
C---- ------------------------------------------------------------------

      NPOS= 0 
      MEAN= 1.0
      SUM=  0.0
      DO IRES=1,NRES
         IF (NOCC(IRES).NE.0) THEN
            SUM = SUM  + CONSWEIGHT(IRES) 
            NPOS=NPOS+1
         ENDIF
      ENDDO
      IF (NPOS .NE. 0) THEN 
         MEAN=SUM/NPOS 
      ENDIF
      WRITE(6,*)'GETCONSWEIGHT: SUM,MEAN ',SUM,MEAN
      IF (MEAN.GT. 0.99 .AND. MEAN .LT. 1.01) RETURN
      XVAL=1.0-MEAN

      DO IRES=1,NRES
         IF (NOCC(IRES).NE.0) CONSWEIGHT(IRES)=CONSWEIGHT(IRES)+XVAL
      ENDDO

      WRITE(6,*)  '--- GETCONSWEIGHT_BR ended'
      RETURN
      END
C     END GETCONSWEIGHT_BR 
C......................................................................

C......................................................................
C     SUB SETCONSERVATION
      SUBROUTINE SETCONSERVATION(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES,NIOSTATES,CSTRSTATES,CIOSTATES,IORANGE,KMAT,
     +     METRIC_FILENAME,MATRIX,SIMCONSERV)
C 1. set conservation weights to 1.0
C 2. rescale matrix for the 22 amino residues such that the sum over
C    the matrix is 0.0 (or near)
C this matrix is used to calculate the conservation weights (SIMCONSERV)
c	implicit none
C import
      CHARACTER*(*)   METRIC_FILENAME
      REAL            MATRIX(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                       MAXSTRSTATES,MAXIOSTATES)
      REAL            SIMCONSERV(1:26,1:26)
      INTEGER         NSTRSTATES,NIOSTATES,KMAT
      CHARACTER*(*)   CSTRSTATES,CIOSTATES
      REAL            IORANGE(MAXSTRSTATES,MAXIOSTATES)
     
C internal
      INTEGER         NACID,MAXRES_LOC
      PARAMETER      (NACID=                    22)
      PARAMETER      (MAXRES_LOC=            10000)

      CHARACTER*(26)  TRANS

      INTEGER         I,J
      REAL            XLOW,XHIGH,XMAX,XMIN,XFACTOR,SUMMAT
      REAL            CONSWEIGHT_1(MAXRES_LOC),
     +                CONSWEIGHT_2(MAXRES_LOC),CONSMIN
*----------------------------------------------------------------------*

C
      DO I=1,MAXRES_LOC 
         CONSWEIGHT_1(I)=1.0
      ENDDO
      LFIRSTWEIGHT=.TRUE.

C     get metric
C     98-10 br: already done
C      CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
C     +     NSTRSTATES,NIOSTATES,NSTRSTATES,NIOSTATES,
C     +     CSTRSTATES,CIOSTATES,IORANGE,KMAT,METRIC_FILENAME,MATRIX)

c     rescale matrix that the sum over matrix is +- 0.0 
      XLOW=     0.0 
      XHIGH=    0.0
      XMAX=     1.0 
      XMIN=    -1.0 
      XFACTOR=100.0
	
C (re)store original values in simconserv()
 20   DO J=1,NTRANS 
         DO I=1,NTRANS
            SIMCONSERV(I,J)=MATRIX(I,J,1,1,1,1) 
         ENDDO
      ENDDO
c scale with xmin/xmax
      CALL SCALEINTERVAL(SIMCONSERV,NTRANS**2,XMIN,XMAX,XLOW,XHIGH)
C RESEt the values for 'X' '!' and '-'
      I=INDEX(TRANS,'X')
      DO J=1,NTRANS
         SIMCONSERV(I,J)=0.0 
         SIMCONSERV(J,I)=0.0
      ENDDO
      I=INDEX(TRANS,'!')
      DO J=1,NTRANS
         SIMCONSERV(I,J)=0.0 
         SIMCONSERV(J,I)=0.0
      ENDDO
      I=INDEX(TRANS,'-')
      DO J=1,NTRANS
         SIMCONSERV(I,J)=0.0 
         SIMCONSERV(J,I)=0.0
      ENDDO
      I=INDEX(TRANS,'.')
      DO J=1,NTRANS
         SIMCONSERV(I,J)=0.0 
         SIMCONSERV(J,I)=0.0
      ENDDO
C calculate sum over matrix (22 amino acids) after scaling
      SUMMAT=0.0
      DO I=1,NACID 
         DO J=1,NACID
            SUMMAT=SUMMAT+SIMCONSERV(I,J)
         ENDDO
      ENDDO
cd	write(*,*)' sum: ',summat,xmin
c check sum=0.0 (+- 0.01) ; if not xmin=xmin/2 ; scale again
      IF (SUMMAT .GT. 0.01) THEN
         XMIN=XMIN+(XMIN/XFACTOR)
      ELSE IF (SUMMAT .LT. -0.01) THEN
         XMIN=XMIN-(XMIN/XFACTOR)
      ELSE
         WRITE(*,*)' SETCONSERVATION: sum over matrix: ',summat
         WRITE(*,*)'                  smin is : ',xmin
         RETURN
      ENDIF
      GOTO 20
      END
C     END SETCONSERVATION
C......................................................................

