*----------------------------------------------------------------------*
C---- ------------------------------------------------------------------
C---- contains now all previously needed libraries for Schneider stuff
C---- ------------------------------------------------------------------
C......................................................................
C     FUN EMPTYSTRING(STRING)
      FUNCTION EMPTYSTRING(STRING)
      LOGICAL         EMPTYSTRING
      CHARACTER*(*)   STRING
      EMPTYSTRING=.TRUE.

      DO I=1,LEN(STRING)  
         IF (STRING(I:I).NE.' ') THEN
            EMPTYSTRING=.FALSE.
            GOTO 10
         ENDIF
      ENDDO
 10   RETURN
      END
C     END EMPTYSTRING
C......................................................................

C......................................................................
C     FUN LCHAINBREAK
      LOGICAL FUNCTION LCHAINBREAK (CS,IS)
C CS March 1988
C Check for '!', which is DSSP chain break
      CHARACTER CS*1
      LCHAINBREAK=CS .EQ. '!'
      IF (LCHAINBREAK) THEN                                       
         WRITE (*,*)'INFO: chain break detected at residue',IS
      ENDIF
      RETURN
      END
C     END LCHAINBREAK
C......................................................................

C......................................................................
C     FUN LEGALRES
      LOGICAL FUNCTION LEGALRES(CS,IS,TRANS,NTRANS,PUNCTUATION)
C Brigitte Altenberg  Dec 1987, changes by CS March 1988
C Check for legal residues. Unknown residues are reported (warning), 
C except for declared punctation.

      CHARACTER*(*) PUNCTUATION,TRANS,CS
C Punctations are not reported. They are format-specific.
C  PIR:    PUNCTUATION='     ,.:;()+'  
            
      LEGALRES=.TRUE.
      L=INDEX(TRANS(1:NTRANS),CS)   
      IF (L.EQ.0 .AND. PUNCTUATION .NE.' ') THEN
         M=INDEX(PUNCTUATION,CS)   
         IF (M.EQ.0) THEN
            WRITE (*,*)'LEGALRES: unknown RESIDUE:',CS,
     +           ': with ASCIIcode: ',ICHAR(CS),
     +           ' after sequence position', IS
            WRITE (*,*)'CAUTION: GETAASEQ will replace this by "-"'
         ENDIF
         LEGALRES=.FALSE.
      ENDIF
      RETURN  
      END
C     END LEGALRES
C......................................................................

C......................................................................
C     SUB ACC_TO_INT
      SUBROUTINE ACC_TO_INT(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES,NIOSTATES,IORANGE,NRES,LSQ,LSTR,NACC,LACC)
      IMPLICIT        NONE
C import
      INTEGER         NTRANS
      CHARACTER*(*)   TRANS
      INTEGER         MAXSTRSTATES,MAXIOSTATES,
     +                NSTRSTATES,NIOSTATES
      REAL            IORANGE(MAXSTRSTATES,MAXIOSTATES)
      INTEGER         NRES,NACC(*),LSQ(*),LSTR(*)
C export
      INTEGER         LACC(*)
C internal
      INTEGER         MAXAA
      PARAMETER      (MAXAA=                    26)
      INTEGER         ACCMAX(MAXAA),I,IOSTATE,ISTR
      REAL            PER
C max. Acc. in order of TRANS (VLIMFWYGAPSTCHRKQENDBZX!-.)
C  V   L   I   M   F   W   Y   G  A   P   S   T
C 142,164,169,188,197,227,222,84,106,136,130,142
C  C   H   R   K   Q   E   N   D   B   Z  X ! - .
C 135,184,248,205,198,194,157,163,157,194,0,0,0 0
      DATA ACCMAX /142,164,169,188,197,227,222,84,106,136,130,142,
     +     135,184,248,205,198,194,157,163,157,194,0,0,0,0/

C      WRITE(*,*)' info:entering ACC_TO_INT, NIOSTATES IS ',NIOSTATES
      IF (TRANS .NE. 'VLIMFWYGAPSTCHRKQENDBZX!-.' ) THEN
         WRITE(6,*)'*** ERROR: TRANS NOT IN RIGHT ORDER in ACC_TO_INT'
         STOP
      ENDIF
      IF (NTRANS .GT. MAXAA) THEN
         WRITE(6,*)'*** ERROR: NTRANS .GT. MAXAA IN ACC_TO_INT'
         STOP
      ENDIF

      IF (NIOSTATES .EQ. 1) THEN
         WRITE(*,*)' info: only one IO state set'
         CALL INIT_INT_ARRAY(1,NRES,LACC,1)
         RETURN
      ENDIF
      DO I=1,NRES
         IF (LSQ(I) .EQ. 0) THEN
            LACC(I)=0
         ELSE
            ISTR=LSTR(I)
            IF (NSTRSTATES .EQ. 1)ISTR=1
            IF (ISTR .EQ. 0) THEN
	       WRITE(6,*)'*** ERROR: LSTR .EQ. 0 IN ACC_TO_INT'
	       STOP
            ENDIF
            
C            WRITE(*,*)'info:I LSQ ACCMAX NACC ',
C     +           I,LSQ(I),ACCMAX(LSQ(I)),NACC(I) 
            IF (ACCMAX(LSQ(I)) .NE. 0) THEN
	       PER=(NACC(I)*100.0) / ACCMAX(LSQ(I))
	       IF (PER .GE. 100.0)PER=100.0
	       IOSTATE=1
	       DO IOSTATE=1,NIOSTATES
C                  WRITE(*,*)'info: IORANGE, ISTR, IOSTATE ',
C     +                 IORANGE(ISTR,IOSTATE),ISTR,IOSTATE
	          IF (PER .LE. IORANGE(ISTR,IOSTATE) ) THEN
                     LACC(I)=IOSTATE
C                     WRITE(*,*)' info:',I,LACC(I)
                     GOTO 100
                  ENDIF
               ENDDO
            ELSE
               LACC(I)=1
            ENDIF
 100        CONTINUE
C100	     if (i .le. 10) then  
C                WRITE(6,*)' acctoint I,LSTR,LACC : ',i,iSTR,
C     +                 lacc(i)
C                WRITE(6,*)accmax(lsq(i)),nacc(i),per
C	     endif
         ENDIF
      ENDDO
      RETURN
      END
C     END ACC_TO_INT
C......................................................................

C......................................................................
C     SUB ALISEQENVIRONMENT
      SUBROUTINE ALISEQENVIRONMENT(MAXRES,MAXALIGNS,
     1     NRES,NALIGN,IFIR,ILAS,INSNUMBER,INSALI,INSLEN,
     2     INSAP,LINS,NINS,TOTALINSLEN,ERROR)
C 21.6.93
      IMPLICIT        NONE
C     IMPORT
      INTEGER         MAXRES,MAXALIGNS,NRES,NALIGN,INSNUMBER
      INTEGER         IFIR(*),ILAS(*),INSALI(*),INSLEN(*),INSAP(*)
C     EXPORT
      INTEGER         TOTALINSLEN(MAXRES)
      INTEGER*2       NINS(MAXRES,0:MAXALIGNS)
      LOGICAL         ERROR,LINS(MAXRES)
C     INTERNAL
      INTEGER*2       INT2_TEMP
      INTEGER         MAXALIGNS_LOC
      PARAMETER      (MAXALIGNS_LOC=         9999)
      INTEGER         IALIGN,IPOS,IAP,IINS,TIL
*----------------------------------------------------------------------*
      
      IF ( NALIGN .GT. MAXALIGNS .OR.
     1     NALIGN .GT. MAXALIGNS_LOC ) THEN
         WRITE(6,'(1X,A)') 
     1        'MAXALIGNS overflow in AliseqEnvironment !'
         ERROR = .TRUE.
         RETURN
      ENDIF
      IF ( NRES .GT. MAXRES ) THEN
         WRITE(6,'(1X,A)') 'MAXRES overflow in AliseqEnvironment !'
         ERROR = .TRUE.
         RETURN
      ENDIF

      IPOS = 0
      IINS = 1
      DO IAP = 1,NRES
         TOTALINSLEN(IAP) = 0
         NINS(IAP,0) = 0
      ENDDO
      DO IALIGN = 1,NALIGN
         DO WHILE ( IINS .LT. INSNUMBER        .AND. 
     1        INSALI(IINS) .LT. IALIGN )
            IINS = IINS + 1
         ENDDO
         DO IAP = IFIR(IALIGN),ILAS(IALIGN)
            IPOS = IPOS + 1
            IF ( INSALI(IINS) .EQ. IALIGN .AND.
     1           INSAP(IINS) .EQ. IAP ) THEN
               NINS(IAP,IALIGN) = IINS
C     CONVERSION INT*4 TO INT*2
               INT2_TEMP = INSLEN(IINS)
               NINS(IAP,0) = MAX(NINS(IAP,0),INT2_TEMP)
               LINS(IAP) = .TRUE.
               IF ( INSALI(IINS+1) .EQ. IALIGN ) IINS = IINS + 1
            ENDIF
         ENDDO
      ENDDO
      TIL = 0
      DO IAP = 1,NRES
         IF ( LINS(IAP) ) TIL = TIL + NINS(IAP,0)
         TOTALINSLEN(IAP) = TIL
      ENDDO

      RETURN
      END
C     END ALISEQENVIRONMENT
C......................................................................

C......................................................................
C     SUB ALITOSTRUCRMS
      SUBROUTINE ALITOSTRUCRMS(MAXALSQ,MAXSQ,BRKFILE_1,BRKFILE_2,
     +     KBRK,PDBNO_1,CHAINID_1,PDBNO_2,CHAINID_2,
     +     ALI_1,ALI_2,LENALI,IFIR,ILAS,JFIR,JLAS,LCALPHA,RMS)
C RS 89
C import an alignment, cut it in pieces (if necessary) and 
C calculate the RMS between pieces
C use routines SETPIECES,GETCOOR,COMPALISTRUC
C IMPORT :
C	BRKFILE_1,BRKFILE_2 : filename of coordinate files
C	KBRK                : unit for coordinate files
C	ALI_1,ALI_2         : alignment string (see remark in SETPIECES)
C	LENALI              : length of alignment including insertions
C	IFIR,ILAS           : first and last position of seq 1
C	JFIR,JLAS           : first and lasr position of seq 2
C	LCALPHA             : compare only C-alpha atoms if true
C OUTPUT:
C	RMS	
C
      IMPLICIT        NONE
C---- import

      INTEGER         MAXALSQ,MAXSQ
      INTEGER         KBRK,LENALI,IFIR,ILAS,JFIR,JLAS
      CHARACTER*(*)   BRKFILE_1,BRKFILE_2
      CHARACTER*1     ALI_1(MAXALSQ),ALI_2(MAXALSQ)
      CHARACTER*1     CHAINID_1(MAXSQ),CHAINID_2(MAXSQ)
      INTEGER         PDBNO_1(MAXSQ),PDBNO_2(MAXSQ)
      REAL            RMS

C---- internal parameters
      INTEGER         MXRES,MXATM
      PARAMETER      (MXRES=                 10000)
      PARAMETER      (MXATM=10*MXRES)

C---- internal variables
C      REAL           RMS
C      INTEGER        LENALI,IFIR,ILAS,JFIR,JLAS,KBRK
C
C if true compare only C-alpha
      LOGICAL         LCALPHA
      CHARACTER*200    BRKBEFORE1,BRKBEFORE2
c alignment
C      CHARACTER*1     ALI_1(MAXALSQ),ALI_2(MAXALSQ)
C      CHARACTER*(*)   CHAINID_1(*),CHAINID_2(*)
C      INTEGER         PDBNO_1(*),PDBNO_2(*)

C very long sequences are cut in pieces
      INTEGER          NSHIFTED
      COMMON/CSHIFT1/NSHIFTED
      LOGICAL          LSHIFTED
      COMMON/CSHIFT2/LSHIFTED
c molecule attributes
C      CHARACTER*(*) BRKFILE_1,BRKFILE_2
      CHARACTER        NAMMOL1(5)*200,NAMMOL2(5)*200
      INTEGER          NRES_1,NRES_2,NATM1,NATM2
c residue attributes ; number and chain
      CHARACTER*6      CIDRES_1(MXRES),CIDRES_2(MXRES)     
C points to first, last and CEN atom. center residue coors
      INTEGER          IPATM1RES(3,MXRES),IPATM2RES(3,MXRES) 
      REAL             RRES1(3,MXRES),RRES2(3,MXRES)            
C atom attributes
C atom belongs to res number IPRESATM
C atom coors
C superposition weights.
      CHARACTER*4      NAMATM1(MXATM),NAMATM2(MXATM)
      INTEGER          IPRES1ATM(MXATM),IPRES2ATM(MXATM)       
      REAL             RATM1(3,MXATM),RATM2(3,MXATM)              
      REAL             WSUP1(MXATM),WSUP2(MXATM)                  
c piece attributes
      INTEGER          MXPIECES
      PARAMETER       (MXPIECES=50)
      INTEGER          IRESPIE,NPIECES,NRESPIE,NATMPIE
      COMMON /CPIECE/IRESPIE(2,2,MXPIECES),NPIECES,NRESPIE(2),
     +     NATMPIE(2)
C compare only if sequences of BRK and DSSP are the same
      LOGICAL          LCHECK   
*----------------------------------------------------------------------*

C---- ------------------------------------------------------------------
C         
C---- ------------------------------------------------------------------
c get pieces from alignment
      IF (LSHIFTED) THEN 
         RMS=-1.0 
         RETURN 
      ENDIF
      CALL SETPIECES(MAXALSQ,ALI_1,ALI_2,LENALI,IFIR,ILAS,JFIR,
     +     JLAS,IRESPIE,MXPIECES,NPIECES)
c.get coordinates
c if coordinates are still in memory dont read them again
      IF (BRKFILE_1 .NE. BRKBEFORE1) THEN
         CALL GETCOORFORHSSP(BRKFILE_1,KBRK,NAMMOL1,NRES_1,NATM1,MXRES,
     +        MXATM,CIDRES_1,IPATM1RES,RRES1,
     +        NAMATM1,IPRES1ATM,RATM1)
      ENDIF
      IF (BRKFILE_2.NE.BRKBEFORE2) THEN
         CALL GETCOORFORHSSP(BRKFILE_2,KBRK,NAMMOL2,NRES_2,NATM2,MXRES,
     +        MXATM,CIDRES_2,IPATM2RES,RRES2,
     +        NAMATM2,IPRES2ATM,RATM2)
      ENDIF
      IF (NRES_1.EQ.0 .OR. NRES_2.EQ.0) THEN
         WRITE(6,*)'**** IN ALITOSTRUCRMS *****'
         WRITE(6,*)' READ ERROR IN FILE: ',BRKFILE_1,' OR ',BRKFILE_2
         WRITE(6,*)' STRUCTURE ALIGNMENT SKIPPED '
         RMS=-1.0 
         RETURN
      ELSE
         BRKBEFORE1=BRKFILE_1 
         BRKBEFORE2=BRKFILE_2
      ENDIF
      CALL CHECKPOSITION(PDBNO_1,CHAINID_1,PDBNO_2,CHAINID_2, 
     +     CIDRES_1,CIDRES_2,NRES_1,NRES_2,LCHECK)
      IF (LCHECK) THEN
         CALL COMPALISTRUC(BRKFILE_1,BRKFILE_2,
     +        NRES_1,NRES_2,NATM1,NATM2,
     +        IPATM1RES,IPATM2RES,RRES1,RRES2,
     +        RATM1,RATM2,WSUP1,WSUP2,LCALPHA,RMS)
      ELSE 
         RMS=-1.0 
      ENDIF
      RETURN
      END
C     END ALITOSTRUCRMS
C......................................................................

C......................................................................
C     SUB ASCIIFILTER
      SUBROUTINE ASCIIFILTER(LINE)
C  Chris Sander, May 1986 (changed by RS 92)
C  replaces non-printable characters by blanks.
C  specification in terms of ASCII-table integers
C  system and choice dependent 
      PARAMETER      (LOWLIMIT=                 32)
      PARAMETER      (HILIMIT=                 126)
c import
      CHARACTER*(*)   LINE
*----------------------------------------------------------------------*

      CALL STRPOS(LINE,IBEG,IEND)
      DO I=IBEG,IEND
         IASCII=ICHAR(LINE(I:I))
         IF ( IASCII .LT. LOWLIMIT .OR. IASCII .GT. HILIMIT ) THEN
	    LINE(I:I)=' '
            WRITE(6,*)'* ASCIIFILTER: funny character replaced by blank'
	    WRITE(6,*)'               integer value is: ',IASCII
         ENDIF
      ENDDO
      RETURN
      END
C     END ASCII-FILTER
C......................................................................

C......................................................................
C     SUB CALC_PROF
      SUBROUTINE CALC_PROF(MAXRES,MAXAA,NRES,PDBSEQ,NALIGN,
     +     EXCLUDEFLAG,IDE,IFIR,ILAS,ALISEQ,ALIPOINTER,TRANS,
     +     SEQPROF,NOCC,NDEL,NINS,ENTROPY,RELENT)
      IMPLICIT        NONE
C import
      REAL            IDE(*)
      INTEGER         MAXRES,MAXAA,NRES,NALIGN,
     +                IFIR(*),ILAS(*),ALIPOINTER(*)
      CHARACTER       PDBSEQ(*),ALISEQ(*),EXCLUDEFLAG(*)
      CHARACTER*(*)   TRANS
C export
      INTEGER         SEQPROF(MAXRES,MAXAA),RELENT(*),
     +                NDEL(*),NINS(*),NOCC(*)
      REAL            ENTROPY(*)
C internal
      INTEGER         NASCII,MAXALIGNS_LOC
      PARAMETER      (NASCII=                  256)
      PARAMETER      (MAXALIGNS_LOC=         9999)

      REAL            SUMENTROPY,X,XENTROPY,XMAXENTROPY
      INTEGER         IRES,IALIGN,IPOS,I,J,
     +                LOWERPOS(NASCII),ITEST
      INTEGER*2       INS_START(MAXALIGNS_LOC)
      CHARACTER       C1,LOWER*26
*----------------------------------------------------------------------*
	
      WRITE(6,*)' CALC_PROF'

      IF (NALIGN .GT. MAXALIGNS_LOC) THEN
         WRITE(6,*)' CALC_PROF: MAXALIGNS_LOC overflow'
         STOP
      ELSE IF (NALIGN .LE. 0) THEN
         RETURN
      ENDIF
C used to convert lower case characters from the DSSP-seq to 'C' (Cys)
      LOWER='abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,NASCII)
C initialize 
      DO I=1,MAXRES
         DO J=1,MAXAA
            SEQPROF(I,J)=0
         ENDDO
         NOCC(I)=0
         NDEL(I)=0
         NINS(I)=0
         ENTROPY(I)=0 
         RELENT(I)=0 
      ENDDO
      DO IALIGN=1,NALIGN
         INS_START(IALIGN)=0
      ENDDO

C     CALCULATE SEQUENCE PROFILE AND ENTROPY
      SUMENTROPY=0.0
      DO IRES=1,NRES  
C residue of DSSP-sequence (SEQ1)
         C1=PDBSEQ(IRES) 
C convert lower case character in DSSP to 'Cys'
         I=LOWERPOS(ICHAR(C1))
         IF (I.NE.0) C1='C'	
         CALL GETSEQPROF(C1,TRANS,IRES,NOCC,SEQPROF,MAXRES,MAXAA)
C residues of aligned sequences
         DO IALIGN=1,NALIGN
            IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
               IF (IRES.GE.IFIR(IALIGN).AND.
     +              IRES.LE.ILAS(IALIGN)) THEN
                  IPOS=ALIPOINTER(IALIGN)+IRES-IFIR(IALIGN)
                  C1=ALISEQ(IPOS)
               ELSE
                  C1=' '
               ENDIF
               I=LOWERPOS(ICHAR(C1))
C if lower case character: insertions
               IF (I.NE.0 .AND. INS_START(IALIGN) .EQ. 0) THEN
                  NINS(IRES)=NINS(IRES)+1
                  CALL LOWTOUP(C1,1)
                  INS_START(IALIGN)=1
               ELSE IF (INS_START(IALIGN) .EQ. 1) THEN
                  INS_START(IALIGN)=0
               ENDIF
               IF (C1 .NE.' ' ) THEN
                  IF (C1.NE.'.') THEN
                     CALL GETSEQPROF(C1,TRANS,IRES,NOCC,
     +                    SEQPROF,MAXRES,MAXAA)
                  ELSE 
C     if '.' : deletion
                     NDEL(IRES)=NDEL(IRES)+1 
                  ENDIF
               ENDIF
            ENDIF
         ENDDO
      ENDDO

C calculate ENTROPY
      DO IRES=1,NRES
         SUMENTROPY=0.0
         IF (NOCC(IRES).GT.1) THEN 
            DO I=1,MAXAA
               IF (SEQPROF(IRES,I).NE. 0) THEN
                  X=FLOAT (SEQPROF(IRES,I)) / FLOAT (NOCC(IRES))
                  XENTROPY=X * (-LOG(X))
                  SUMENTROPY=SUMENTROPY+XENTROPY
               ENDIF
            ENDDO
            ENTROPY(IRES)=SUMENTROPY
            IF (NOCC(IRES).LE.20) THEN
               XMAXENTROPY = -LOG (1 / FLOAT(NOCC(IRES)))
            ELSE
C log(0.05) = ln (1/20) 
               XMAXENTROPY = -LOG(0.05)           
            ENDIF
            RELENT(IRES)=NINT(SUMENTROPY*100/ XMAXENTROPY)
         ENDIF
      ENDDO
C normalize sequence profile
      DO IRES=1,NRES
         DO I=1,MAXAA
            IF (NOCC(IRES).GE.1) THEN
               X=FLOAT(SEQPROF(IRES,I)) *100.0 / FLOAT(NOCC(IRES))
               SEQPROF(IRES,I)=NINT(X)
            ENDIF
         ENDDO
C         ITEST=0
C         DO I=1,MAXAA
C            ITEST=ITEST+SEQPROF(IRES,I)
C         ENDDO
C         IF (ITEST .NE. 100) THEN
C            WRITE(6,*)'calc_prof: itest .ne. 100: ',itest
C            WRITE(6,*)ires,nocc(ires)
C         ENDIF
      ENDDO
      RETURN
      END
C     END CALCPROFILE
C......................................................................

C......................................................................
C     SUB CALC_VAR
      SUBROUTINE CALC_VAR(NALIGN,NRES,PDBSEQ,IDE,IFIR,ILAS,
     +     ALIPOINTER,ALISEQ,EXCLUDEFLAG,
     +     MAXSTRSTATES,MAXIOSTATES,NTRANS,MATSEQ,
     +     MATRIX,VAR)
C---- import
      IMPLICIT        NONE  
      INTEGER         NALIGN,NRES,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                IFIR(*),ILAS(*),ALIPOINTER(*)
      CHARACTER       PDBSEQ(*), ALISEQ(*),EXCLUDEFLAG(*)
      REAL            IDE(*)
C     used for variability
      CHARACTER*(*)   MATSEQ
      REAL            MATRIX(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                      MAXSTRSTATES,MAXIOSTATES)   
C---- export
      INTEGER         VAR(*)

C---- internal
      INTEGER         MAXRES,NASCII
      PARAMETER      (NASCII=                  256)
      PARAMETER      (MAXRES=                10000)
      INTEGER         I,J,IALIGN,JALIGN,ILEN,IRES,
     +                IPOS,JPOS,IBEG,IEND,IAGR,ICYS,MALIGN,KALIGN,
     +                IPDB_SEQ(MAXRES),
     +                IALIGN_SEQ(MAXRES),JALIGN_SEQ(MAXRES)
      REAL            SUMVAR(MAXRES),SUMDIST(MAXRES),
     +                TMPVAL(MAXRES),SEQDIST
      LOGICAL         LEGALRES(MAXRES)
C     value of best match
      REAL            VALMAX
C     only used to get rid of INDEX command (CPU time)
      INTEGER         MATPOS(NASCII),LOWERPOS(NASCII)
      CHARACTER       LOWER*26
*----------------------------------------------------------------------*
C---- ------------------------------------------------------------------

      WRITE(6,*)' calc_var'
C used to convert lower case characters from the DSSP-seq to 'C' (Cys)
      LOWER='abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,NASCII)
C     calculate variability only for the 22 (BZ) amino acids
      DO I=1,NASCII 
         MATPOS(I)=0
      ENDDO
      CALL GETPOS(MATSEQ(1:22),MATPOS,NASCII)
      IF (NRES .GT. MAXRES) THEN
         WRITE(6,*)'ERROR: nres.gt.maxres in calc_var'
         WRITE(6,*)'**** increase maxres ****'
         STOP
      ENDIF
C---- initialise
      VALMAX=0.0
      DO I=1,NTRANS
         DO J=1,NTRANS
            IF (MATRIX(J,I,1,1,1,1) .GT. VALMAX) THEN
               VALMAX=MATRIX(J,I,1,1,1,1)
            ENDIF
         ENDDO
      ENDDO
      DO I=1,NRES
         VAR(I)=0
         SUMVAR(I)=0.0
         SUMDIST(I)=0.0
         IALIGN_SEQ(I)=0
         JALIGN_SEQ(I)=0
      ENDDO
      IF (NALIGN .LE. 0) RETURN
C.....................................................
C     CALCULATE VARIABILITY
C       variability= distance(k,l) * matrix(i,j,1,1,1,1)
C                    k,l = sequence 
C                    i,j = residue
C       distance= 1-(matches/length)
C	length=length of alignment - gaps
C
C convert DSSP-seq and first 'good' alignment seq to integers
      ICYS=MATPOS(ICHAR('C'))
      DO I=1,NRES
         IPDB_SEQ(I)=MATPOS( ICHAR(PDBSEQ(I) ) )
         IF ( IPDB_SEQ(I) .EQ. 0) THEN
            J=LOWERPOS( ICHAR(PDBSEQ(I)) )
            IF (J .NE. 0) IPDB_SEQ(I)=ICYS
         ENDIF
      ENDDO
C find last alignment to be considered and store sequence of last 
C alignment in ialign_seq for first iteration of next loop
      MALIGN=0
      DO IALIGN=1,NALIGN
         IF ( EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
            MALIGN=IALIGN
         ENDIF
      ENDDO
      IALIGN=MALIGN
C---- BR 99.09: correct if none found
      IF (IALIGN .EQ. 0) RETURN
      IPOS=ALIPOINTER(IALIGN)-IFIR(IALIGN)
      DO IRES=IFIR(IALIGN),ILAS(IALIGN)
         IF (IRES .GT. 0) THEN
            IALIGN_SEQ(IRES)=MATPOS( ICHAR( ALISEQ(IPOS+IRES) ) )
            IF ( IALIGN_SEQ(IRES) .EQ. 0) THEN
               IF (ALISEQ(IPOS+IRES) .GE. 'a' .AND. 
     +              ALISEQ(IPOS+IRES) .LE. 'z') THEN
                  IALIGN_SEQ(IRES)=MATPOS(ICHAR(ALISEQ(IPOS+IRES))-32)
               ENDIF
            ENDIF
         END IF
      ENDDO

C loop from last 'good' alignment till first
      DO IALIGN=MALIGN,1,-1
         IF ( IALIGN .GT. 0 .AND.
     +        EXCLUDEFLAG(IALIGN) .EQ. ' ' .AND.
     +        IFIR(IALIGN) .GT. 0) THEN
C distance between PDBseq and alignment
            SEQDIST=1.0-IDE(IALIGN)
C accumulate distance etc.
            DO IRES=IFIR(IALIGN),ILAS(IALIGN)
	       IF (IPDB_SEQ(IRES).NE.0.AND.IALIGN_SEQ(IRES).NE.0) THEN
                  SUMVAR(IRES)=SUMVAR(IRES) + 
     +                 (SEQDIST * 
     +                 MATRIX(IPDB_SEQ(IRES),IALIGN_SEQ(IRES),1,1,1,1))
                  SUMDIST(IRES)=SUMDIST(IRES)+SEQDIST
	       ENDIF
            ENDDO
         ENDIF
C pairwise comparison of alignend sequences from first to "ialign"
C store last 'good' alignment before "ialign" in "kalign" so we can 
C use the last "jalign"-seq for the next iteration of the "ialign"-seq
         KALIGN=0
         DO JALIGN=1,IALIGN-1
            IF ( EXCLUDEFLAG(JALIGN) .EQ. ' ') THEN
	       KALIGN=JALIGN
	       JPOS=ALIPOINTER(JALIGN)-IFIR(JALIGN)
	       DO IRES=IFIR(JALIGN),ILAS(JALIGN)
                  IF (IRES .GT. 0) THEN
                     JALIGN_SEQ(IRES)=
     +                    MATPOS( ICHAR( ALISEQ(JPOS+IRES) ) )
                     IF ( JALIGN_SEQ(IRES) .EQ. 0) THEN
                        IF (ALISEQ(JPOS+IRES) .GE. 'a' .AND. 
     +                       ALISEQ(JPOS+IRES) .LE. 'z') THEN
                           JALIGN_SEQ(IRES)=
     +                          MATPOS(ICHAR(ALISEQ(JPOS+IRES))-32)
                        ENDIF
                     ENDIF
                  ENDIF
               ENDDO
	       SEQDIST=0.0
               IAGR=0
	       ILEN=0
C get distance between overlap of alignend seqs 
	       IBEG= MAX(IFIR(IALIGN),IFIR(JALIGN))
	       IEND= MIN(ILAS(IALIGN),ILAS(JALIGN))
               DO IRES= IBEG,IEND
                  IF (IRES .GT. 0) THEN
                     LEGALRES(IRES)=.FALSE.
                     IF ( IALIGN_SEQ(IRES) .NE. 0 .AND.
     +                    JALIGN_SEQ(IRES) .NE. 0) THEN
                        LEGALRES(IRES)=.TRUE.
                        IF (IALIGN_SEQ(IRES) .EQ. JALIGN_SEQ(IRES))
     +                       IAGR=IAGR+1
                        TMPVAL(IRES)=
     +                       MATRIX(IALIGN_SEQ(IRES),
     +                              JALIGN_SEQ(IRES),1,1,1,1)
                        ILEN=ILEN+1
                     ENDIF
                  ENDIF
	       ENDDO
	       IF (ILEN .NE. 0) THEN
                  SEQDIST=1.0-(FLOAT(IAGR)/ILEN)
                  DO IRES=IBEG,IEND
                     IF (LEGALRES(IRES)) THEN
                        SUMDIST(IRES)=SUMDIST(IRES)+SEQDIST
                        SUMVAR(IRES)=SUMVAR(IRES)+(SEQDIST*TMPVAL(IRES))
                     ENDIF
                  ENDDO
	       ENDIF
            ENDIF
         ENDDO
         IF (KALIGN .GT. 0) THEN
            DO I=IFIR(KALIGN),ILAS(KALIGN)
               IF (I .GT. 0) THEN
                  IALIGN_SEQ(I)=JALIGN_SEQ(I)
               ENDIF
            ENDDO
         ENDIF
      ENDDO
C calculate variability
      DO IRES=1,NRES
         IF (SUMDIST(IRES) .NE. 0.0) THEN
            VAR(IRES)=NINT((VALMAX- (SUMVAR(IRES)/SUMDIST(IRES)) )*100)
         ENDIF
      ENDDO
      RETURN
      END
C     END CALC_VAR
C......................................................................

C......................................................................
C     SUB CHARARRAYREPL
c	subroutine CHARARRAYREPL(string,length,c1,c2)
c	Implicit None
C replaces all occurences of c1 by c2

C Import
c	integer length
c	character*1 c1, c2
C Import/Export
c	character string(*)
C Internal
c	integer ipos

c	do ipos = 1,length
c           if ( string(ipos) .eq. c1 ) string(ipos) = c2
c        enddo

c	return
c	end
C     END CHARARRAYREPL
C......................................................................

C......................................................................
C     SUB CHECKFORMAT
      SUBROUTINE CHECKFORMAT(IN,INNAME,FORMATNAME,ERRFLAG)
C CHECK IF FORMAT ONE OF :DSSP,PIR,EMBL,GCG OR SOMETHING NOT SPECIFIED
 
      LOGICAL ERRFLAG
	
      CHARACTER*(*) FORMATNAME,INNAME
      CHARACTER*1000 FILENAME,LINE

      FORMATNAME='UNK' 
      LINE=' '
      FILENAME=' '
      I=INDEX(INNAME,'_!_')
      J=0
      K=0
C      J=INDEX(INNAME,'hssp_')
C      K=INDEX(INNAME,'dssp_')
      L=INDEX(INNAME,'dssp_ca_')
      M=INDEX(INNAME,'dssp_mod')
      IF (I.NE.0) THEN
         FILENAME=INNAME(:I-1)
      ELSE IF (J .NE. 0) THEN
         FILENAME=INNAME(:J+3)
      ELSE IF ( (K .NE. 0) .AND. (L .LE. 0) .AND. (M .EQ. 0) ) THEN
         FILENAME=INNAME
C         FILENAME=INNAME(:K+3)
      ELSE
         FILENAME=INNAME
      ENDIF
      CALL OPEN_FILE(IN,FILENAME,'READONLY,OLD',ERRFLAG)
      IF (ERRFLAG) THEN
         WRITE(6,*)' open file error in CHECKFORMAT'
         GOTO 11
      ENDIF
      I=0
      LENGTH=LEN(LINE)
      DO WHILE(.TRUE.)
	 I=I+1
         READ(IN,'(A)',END=99) LINE
	 IF (INDEX(LINE(:2),'ID').NE.0) THEN
            DO WHILE (.TRUE.)
C LOOK FOR DIFF:EMBL,GCG
               READ (IN,'(A)',END=10)LINE    
               IF (INDEX(LINE,'..').NE.0) THEN
C there are still some swissprot files with '..'
                  CALL LOWTOUP(LINE,LENGTH)
                  IF (INDEX(LINE,'CHECK:').NE.0 .AND. 
     +                 INDEX(LINE,'MSF:').NE.0) THEN
                     FORMATNAME='MSF'
                     GOTO 99
                  ELSE IF (INDEX(LINE,'CHECK:').NE.0) THEN
                     FORMATNAME='GCG'
                     GOTO 99
                  ENDIF
               ENDIF
            ENDDO
 10         FORMATNAME='EMBL'
       	 ENDIF
         IF (INDEX(LINE,'PROGRAM DSSP,').NE.0 .OR.
     +       INDEX(LINE,'program DSSP,').NE.0 ) THEN
            FORMATNAME='DSSP'
            GOTO 99
         ELSE IF (INDEX(LINE,'-PROFILE').NE.0) THEN
            FORMATNAME='PROFILE'
            IF (INDEX(LINE,'SECONDARY').NE.0) THEN
               FORMATNAME='PROFILE-DSSP'
            ENDIF
            IF (INDEX(LINE,'SS-SA').NE.0) THEN
               FORMATNAME='PROFILE-SS-SA'
            ENDIF
            GOTO 99
         ELSE IF (INDEX(LINE(1:5),'HSSP ').NE.0) THEN
            FORMATNAME='HSSP'
            GOTO 99
         ELSE IF ( (I.EQ.1) .AND. (LINE(1:6) .EQ. 'HEADER') ) THEN
            FORMATNAME='BRK'
            GOTO 99
         ELSE IF (INDEX(LINE,'..').NE.0) THEN
            CALL LOWTOUP(LINE,LENGTH)
            IF (INDEX(LINE,'CHECK:').NE.0 .AND. 
     +           INDEX(LINE,'MSF:').NE.0) THEN
               FORMATNAME='MSF'
               GOTO 99
            ELSE IF (INDEX(LINE,'CHECK:').NE.0) THEN
               FORMATNAME='GCG'
               GOTO 99
            ENDIF
	 ELSE IF ( LINE(1:1) .EQ. '>') THEN
            FORMATNAME='FASTA'
            READ(IN,'(A)',END=99)LINE
            IF (LINE .NE. ' ') THEN
               CALL LOWTOUP(LINE,LEN(LINE))
               CALL STRPOS(LINE,ISTART,ISTOP)
               DO I=ISTART,ISTOP
                  IASCII=ICHAR(LINE(I:I))
                  IF ( (IASCII .EQ. 85) .OR.
     +                 (IASCII .EQ. 79) .OR.
     +                 (IASCII .EQ. 74) .OR.
     +                 (IASCII .GE. 33 .AND. IASCII .LE. 64) .OR.
     +                 (IASCII .GE. 91 ) ) THEN
                     FORMATNAME='PIR'
                     GOTO 20
                  ENDIF
               ENDDO
            ELSE
               FORMATNAME='PIR'
            ENDIF
 20         DO WHILE(.TRUE.)
               READ(IN,'(A)',END=99)LINE
               IF ( LINE(1:1) .EQ. '>') THEN
                  FORMATNAME='FASTA-DB'
                  GOTO 99
               ENDIF
            ENDDO
            GOTO 99
	 ELSE IF (LINE(1:1) .EQ. '*') THEN
            FORMATNAME='STAR'
            GOTO 99
         ENDIF
      ENDDO
 99   CLOSE (IN)
      RETURN
 11   RETURN      
      END                                        
C     END CHECKFORMAT
C......................................................................

C......................................................................
C     SUB CHECKHSSPCUT
      SUBROUTINE CHECKHSSPCUT(LEN,IDENTITY,ISOLEN,ISOIDE,NSTEP,
     +     LFORMULA,LALL,ISAFE,LCONSIDER,DISTANCE)
C RS 89  
C check if sequence identity <==> length of alignment are in the 'good'
C part of the HSSP-PLOT
C if OK : LCONSIDER= TRUE
      IMPLICIT NONE
      INTEGER I,LEN,IRANGE,JRANGE
      REAL IDENTITY,DISTANCE,Y
      LOGICAL LCONSIDER,LFORMULA,LALL
      INTEGER ISOLEN(*),NSTEP,ISAFE
      REAL    ISOIDE(*)
      LCONSIDER=.FALSE.
      DISTANCE=0.0
C equation from cutoffs in the HSSP-plot
      IF (LFORMULA .OR. LALL) THEN
         IF (LEN.LT.10) THEN
            IF (.NOT. LFORMULA)LCONSIDER=.TRUE.
            RETURN
         ENDIF
         IF (LEN.GT.200) THEN
            Y= 24.767 + ISAFE
C     DISTANCE IS ALWAYS DISTANCE FROM ORIGINAL CURVE
            DISTANCE=IDENTITY - (290.15* (200**(-0.56158)) )
         ELSE
            Y=( 290.15* (LEN**(-0.56158)) ) + ISAFE
C distance is always distance from original curve
            DISTANCE=IDENTITY - (290.15* (LEN**(-0.56158)) )
         ENDIF
         IF (IDENTITY .GE. Y)LCONSIDER=.TRUE.
         IF (.NOT. LFORMULA)LCONSIDER=.TRUE.
         RETURN
      ELSE
C dont consider alignments less than smallest length in datafile
         IF (LEN .GE. ISOLEN(1)) THEN
            DO I=1,NSTEP
               IRANGE=ISOLEN(I)
C if length is longer than longest specified set upper range to LENGTH+1
               IF (I.NE.NSTEP) THEN
	          JRANGE=ISOLEN(I+1)
               ELSE
	          JRANGE=LEN+1
	       ENDIF
	       IF (LEN .GE. IRANGE .AND. LEN .LT. JRANGE) THEN 
C if identity .GE. than ISOSIG-data 
                  IF (IDENTITY.GE.ISOIDE(I)) THEN
                     LCONSIDER=.TRUE.
	             DISTANCE=IDENTITY-ISOIDE(I)
CD                   WRITE(6,*)len,identity,isolen(i),isoide(i)
                     GOTO 10
	          ENDIF
	       ENDIF
	    ENDDO
         ELSE
            LCONSIDER=.FALSE.
         ENDIF
 10      RETURN 
      ENDIF
      END
C     END CHECKHSSPCUT
C......................................................................

C......................................................................
C     SUB CHECKPOSITION
      SUBROUTINE CHECKPOSITION(PDBNO_1,CHAINID_1,PDBNO_2,CHAINID_2,
     +     CBRKID_1,CBRKID_2,NRES_1,NRES_2,LMATCH)
C RS 89
C check if pieces from DSSP-alignment match the position in the 
C Brookhaven coordinate file
C if not this routine tries to find the right position
C piece attributes
      INTEGER         MXPIECES
      PARAMETER      (MXPIECES=                 50)
      COMMON /CPIECE/IRESPIE(2,2,MXPIECES),NPIECES,NRESPIE(2),
     +     NATMPIE(2)
C     ALIGNMENT AND SEQUENCES
C     BRK-NUMBER FROM DSSP
      INTEGER         PDBNO_1(*),PDBNO_2(*)
      CHARACTER*(*)   CHAINID_1(*),CHAINID_2(*)   
C     BRK-NUMBER FROM BRK
      CHARACTER*(*)   CBRKID_1(*),CBRKID_2(*)   
C     INTERNAL
C     TRUE IF PIECES ARE THE SAME
      LOGICAL         LMATCH                  
      CHARACTER*6     CTEST
*----------------------------------------------------------------------*
      LMATCH=.FALSE.
C     CHECK PIECES
      DO IPIECE=1,NPIECES
C     CHECK PIECE FROM TEST SEQUENCE
         IB=IRESPIE(1,1,IPIECE) 
         IE=IRESPIE(2,1,IPIECE)
C put chain identifier of BRK at first position; in DSSP last position
         WRITE(CTEST,'(A,I4,A)')CHAINID_1(IB),PDBNO_1(IB),' '  
         IF (CTEST .NE. CBRKID_1(IB)) THEN
            WRITE(6,*)' CHECKPOSITION: DSSP/BRK pieces are '//
     +           'different try to find right positions in piece 1'
            DO IPOS=-NRES_1,NRES_1
               IF (IB+IPOS .GT. 0 .AND. IB+IPOS .LT. NRES_1) THEN
                  IF (CTEST .EQ. CBRKID_1(IB+IPOS)) THEN           
                     IRESPIE(1,1,IPIECE)=IB+IPOS
                     IRESPIE(2,1,IPIECE)=IE+IPOS
                     LMATCH=.TRUE.
                     WRITE(6,*)' CHECKPOSITION: right position found '
                     WRITE(6,*)' IPIECE     : ',ipiece
                     WRITE(6,*)' DSSP-piece is: ',ib,ie
                     WRITE(6,*)' BRK-piece  is: ',ib+ipos,ie+ipos
                     GOTO 100
                  ENDIF
               ENDIF
            ENDDO
         ELSE 
            LMATCH=.TRUE.
         ENDIF
 100     CONTINUE
         IF (.NOT. LMATCH) THEN
            WRITE(6,*)'CHECKPOSITION : NO MATCH, 3D COMPARISON SKIPPED'
            RETURN
         ENDIF
c check piece of comparison sequence
         LMATCH=.FALSE.
         IB=IRESPIE(1,2,IPIECE) 
         IE=IRESPIE(2,2,IPIECE)
         WRITE(CTEST,'(A,I4,A)')CHAINID_2(IB),PDBNO_2(IB),' '
         IF (CTEST .NE. CBRKID_2(IB)) THEN
            WRITE(6,*)' CHECKPOSITION: DSSP/BRK pieces are different'//
     +           ' try to find right positions in piece 2'
            DO IPOS=-NRES_2,NRES_2
               IF (IB+IPOS .GT. 0 .AND. IB+IPOS .LT. NRES_2) THEN
                  WRITE(6,*)':',CTEST,':',CBRKID_2(IB+IPOS),':'
                  IF (CTEST .EQ. CBRKID_2(IB+IPOS) ) THEN            
                     IRESPIE(1,2,IPIECE)=IB+IPOS
                     IRESPIE(2,2,IPIECE)=IE+IPOS
                     LMATCH=.TRUE.
                     WRITE(6,*)' CHECKPOSITION: right position found '
                     WRITE(6,*)' IPIECE     : ',ipiece
                     WRITE(6,*)' DSSP-piece is: ',ib,ie
                     WRITE(6,*)' BRK-piece  is: ',ib+ipos,ie+ipos
                     GOTO 200
                  ENDIF
               ENDIF
            ENDDO
         ELSE 
            LMATCH=.TRUE.
         ENDIF
         IF (.NOT. LMATCH) THEN
            WRITE(6,*)'CHECKPOSITION : NO MATCH, 3D COMPARISON SKIPPED'
            RETURN
         ENDIF
 200     CONTINUE
      ENDDO
      RETURN 
      END
C     END CHECKPOSITION
C......................................................................
                   
C......................................................................
C     SUB CHECKRANGE
      SUBROUTINE CHECKRANGE(N,NLOWER,NUPPER,VARIABLE,ROUTINE)
      CHARACTER*(*) ROUTINE, VARIABLE
      IF (N .LT. NLOWER .OR. N .GT. NUPPER ) THEN
         WRITE(6,*)'*** fatal error in ',routine
         WRITE(6,*) ' integer ',variable,' out of range '
         WRITE(6,*) ' legal limits are: ',nlower, nupper
         WRITE(6,*) ' current value is: ',n
         STOP 'IN CHECKRANGE'
      ENDIF
      RETURN
      END
C     END CHECKRANGE
C......................................................................

C......................................................................
C     SUB CHECKINEQUALITY
      SUBROUTINE CHECKINEQUALITY(N,M,VARIABLE,ROUTINE)

      CHARACTER*(*) ROUTINE, VARIABLE
      INTEGER N,M
      IF (N .EQ. M) THEN
         WRITE(6,*)'*** fatal error in ',routine
         WRITE(6,*)variable,' are equal but should be uneq'
         WRITE(6,*) ' current value is: ',n,m
         STOP 'IN CHECKINEQUALITY'
      ENDIF
      RETURN
      END
C     END CHECKINEQUALITY
C......................................................................

C......................................................................
C     SUB CHECKREALEQUALITY
      SUBROUTINE CHECKREALEQUALITY(X1,X2,EPSILON,VARIABLE,ROUTINE)

      CHARACTER*(*) ROUTINE, VARIABLE
      REAL X1,X2,EPSILON

      IF (EPSILON .LT. 0.0) THEN
         WRITE(6,*)' *** negative epsilon in checkrealequality'
      ENDIF
      IF (ABS(X1-X2) .GT. EPSILON) THEN
         WRITE(6,*)'*** fatal error in ',routine
         WRITE(6,*)' real nums ',variable,' are not eq within',epsilon
         WRITE(6,*)' values are: ',x1,x2
         STOP 'IN CHECKREALEQUALITY'
      ENDIF
      RETURN
      END
C     END CHECKREALEQUALITY
C......................................................................

C......................................................................
C     SUB CHECKSEQ
      SUBROUTINE CHECKSEQ(STRAND,BEGIN,END,CHECK)

      IMPLICIT NONE

C     sub version of gcg function CheckSeq 18
C Changes:
C - return value now additional parameter "check"
C - additional parameters "begin","end" : Strand is now read 
C   from begin to end, no longer from 1 to first occurence of char(0)

C     IMPORT
      CHARACTER*(*) STRAND
C     UG
      INTEGER BEGIN, END
C     INTERNAL
      INTEGER CHECKTMP, COUNT, I
      INTEGER TABLE(0:255)
      
      CHARACTER C
C     EXPORT
      INTEGER CHECK
      
      DO I = 0, 255
         C = CHAR(I)
         CALL LOWTOUP(C,1)
         TABLE(I) = ICHAR(C)
      END DO
      
      CHECKTMP = 0
      COUNT = 0
      DO I = BEGIN, END
         COUNT = COUNT + 1
         CHECKTMP = CHECKTMP + COUNT * TABLE(ICHAR(STRAND(I:I)))
         IF ( COUNT.EQ.57 ) COUNT = 0
      END DO
      
      CHECK = MOD(CHECKTMP, 10000)
      
      RETURN
      END 
C     END CHECKSEQ
C......................................................................

C......................................................................
C     SUB COMPALISTRUC
C COMPARE-PROTEIN-STRUCTURES.
C C.SANDER MAY 1983, as CELLO subroutine July 1985. 
C calcs best overlap of two protein pieces
CP pass storage for spliced molecule as argument  RRES1SPL RATM1SPL etc
CP then remove parameter here - should only exist in GRAFIX-MOLEC:COMM
c	subroutine compalistruc()
      SUBROUTINE COMPALISTRUC(FILCOO1,FILCOO2,NRES_1,NRES_2,NATM1,
     +     NATM2,IPATM1RES,IPATM2RES,RRES1,
     +     RRES2,RATM1,RATM2,WSUP1,WSUP2,LCALPHA,
     +     RMS)
      IMPLICIT        NONE

      INTEGER         MXRESMOL,MXATMMOL
      PARAMETER      (MXRESMOL=                600)
      PARAMETER      (MXATMMOL=10*MXRESMOL)
c molecule attributes
      CHARACTER*(*)   FILCOO1, FILCOO2
      INTEGER         NRES_1,NRES_2,NATM1,NATM2
C+++++variables shared with GETCOOR/S3TOS1 - from GET-PROTEIN-LIB
C points to first, last and CEN atom
      INTEGER         IPATM1RES(3,*), IPATM2RES(3,*)
C center residue coors
      REAL            RRES1(3,*),RRES2(3,*)
C atom coors
      REAL            RATM1(3,*), RATM2(3,*)
C superposition weights.
      REAL            WSUP1(*), WSUP2(*)
      LOGICAL         LCALPHA
C compare 3-d structure piece by piece
      LOGICAL         LPIEBYPIE
C result variables
C     BEST TRANSROT FROM SUPERPOSE
      REAL            TRANS(3), ROT(3,3), RMS
C piece attributes
      INTEGER         MXPIECES
      PARAMETER      (MXPIECES=                 50)
      INTEGER         IPRESPIE,NPIECES,NRESPIE,NATMPIE
      COMMON /CPIECE/IPRESPIE(2,2,MXPIECES),NPIECES,NRESPIE(2),
     +     NATMPIE(2)
C local atom storage for spliced coordinates
      REAL            RRES1SPL(3,MXRESMOL), RRES2SPL(3,MXRESMOL)
      REAL            RATM1SPL(3,MXATMMOL), RATM2SPL(3,MXATMMOL)
C internal
      INTEGER         I,K,IATM,IPIECE,LMOL,NRES,IRESPIE,IATMPIE,
     +                IRES,IRES1,IRES2,IPIE1,IER
      REAL            TOTALLEN,XRMSTOTAL,XRMS

C     [mol1 <piece> mol1]
C     [mol2 <piece> mol2]
C
C  pointers:         relative to beginning of each molecule
C
C  molecule          1,NRESMOL            residues
C                    1,NATMMOL            atoms
C
C  piece             IPRESPIE(2,2,MXPIECES)
C                            (2,2,MXPIECES)=(beg-end,mol1-mol2,IPIECE)
C                    NATMPIE(2)
C                    NRESPIE(2)          (2)=(mol1-mol2)
C
C-----------------------------------------------------------------------
      WRITE(6,*)' enter COMPARE-STRUCS for molecules: '
      WRITE(6,'(a,a,i6,a,i6)')FILCOO1(1:40),
     +     '  NRES=',NRES_1,' NATM= ',NATM1
      WRITE(6,'(a,a,i6,a,i6)')FILCOO2(1:40),
     +     '  NRES=',NRES_2,' NATM= ',NATM2
C Set defaults
      LPIEBYPIE=.FALSE.
      DO I=1,NATM1 
         WSUP1(I)=1.0 
      ENDDO
      DO I=1,NATM2 
         WSUP2(I)=1.0 
      ENDDO
      GOTO 200
C COMPARE STRUCS
 200  CONTINUE
C get compare limits
      WRITE(6,*) 
      WRITE(6,*)' ---------------------------------'
      WRITE(6,*)' mol A is: ',FILCOO1(1:50)
      WRITE(6,*)' mol B is: ',FILCOO2(1:50)
C reset upper limit if needed
      DO IPIECE=1,NPIECES
         DO LMOL=1,2
            IF (LMOL.EQ.1) THEN  
               NRES=NRES_1 
            ENDIF
            IF (LMOL.EQ.2) THEN  
               NRES=NRES_2 
            ENDIF
            IF (IPRESPIE(1,LMOL,IPIECE) .LT. 1) THEN
               IPRESPIE(1,LMOL,IPIECE)=1
            ENDIF
            IF (IPRESPIE(2,LMOL,IPIECE) .GT. NRES) THEN
               IPRESPIE(2,LMOL,IPIECE)=NRES
            ENDIF
         ENDDO
      ENDDO
C===============================================================
C GET RMS FOR EACH PIECE AND ADD RMSS
      IF (LPIEBYPIE) THEN	
         WRITE(6,*)' compare structure piece by piece '
         RMS=0.0 
         TOTALLEN=0.0 
         XRMSTOTAL=0.0
         DO IPIECE=1,NPIECES 
            XRMS=0.0
            DO LMOL=1,2
               IRESPIE=0 
               IATMPIE=0
               IRES1=IPRESPIE(1,LMOL,IPIECE)
               IRES2=IPRESPIE(2,LMOL,IPIECE)
               DO IRES=IRES1,IRES2
                  IRESPIE=IRESPIE+1
                  IF (LMOL.EQ.1) THEN
                     DO K=1,3
                        RRES1SPL(K,IRESPIE)=RRES1(K,IRES)
                     ENDDO
C     first atom of residue to last atom of residue IRES
                     DO IATM=IPATM1RES(1,IRES),IPATM1RES(2,IRES)
                        IATMPIE=IATMPIE+1
                        IF (IATMPIE .GT. MXATMMOL) THEN
                           WRITE(6,*)' MXATMMOL overflow '
                           STOP
                        ENDIF
                        DO K=1,3
                           RATM1SPL(K,IATMPIE)=RATM1(K,IATM) 
                        ENDDO
                     ENDDO
                  ENDIF
                  IF (LMOL.EQ.2) THEN
                     DO K=1,3
                        RRES2SPL(K,IRESPIE)=RRES2(K,IRES)
                     ENDDO
C     first atom of residue to last atom of residue IRES
                     DO IATM=IPATM2RES(1,IRES),IPATM2RES(2,IRES)
                        IATMPIE=IATMPIE+1
                        IF (IATMPIE .GT. MXATMMOL) THEN
                           WRITE(6,*)' MXATMMOL overflow '
                           STOP
                        ENDIF
                        DO K=1,3
                           RATM2SPL(K,IATMPIE)=RATM2(K,IATM) 
                        ENDDO
                     ENDDO
                  ENDIF
C FOR IRES=IRES1,IRES2
               ENDDO
               NRESPIE(LMOL)=IRESPIE 
               NATMPIE(LMOL)=IATMPIE
C FOR LMOL=1,2
            ENDDO
            WRITE(6,*) ' IPIECE : ',IPIECE
            WRITE(6,*)' MOL1: from ',IPRESPIE(1,1,IPIECE),' to ',
     +           IPRESPIE(2,1,IPIECE) 
            WRITE(6,*)' MOL2: from ',IPRESPIE(1,2,IPIECE),' to ',
     +           IPRESPIE(2,2,IPIECE) 
C superpose using U3B of Wolfgang Kabsch
            IPIE1=1
C first atom and number of residues of piece 1 and 2
            WRITE(6,*)'      # of residues         '
            WRITE(6,'(2I10)') ( NRESPIE(K),K=1,2 )
            WRITE(6,*)'----------------------------'
            WRITE(6,*)' CALL U3B'
            CALL U3B(WSUP2,RRES1SPL(1,1),RRES2SPL(1,1),NRESPIE(IPIE1),
     +           0,XRMS,ROT,TRANS,IER)
cx            XN=FLOAT(NRESPIE(IPIE1))
CX XRMS=SQRT(XRMS/XN)      IS NOW IN U3B
            WRITE(6,'('' RMS     '',F18.7)') XRMS
            TOTALLEN=TOTALLEN+NRESPIE(IPIE1)
            XRMSTOTAL=XRMSTOTAL+NRESPIE(IPIE1)*XRMS
C     FOR IPIECE=1,NPIECES
         ENDDO
         RMS=XRMSTOTAL/TOTALLEN
         WRITE(6,*)' TOTAL RMS ',RMS
C               
C end block: splice-coors  (piece by piece)
C==================================================================
      ELSE
         WRITE(6,*)' compare structures: splice-coors'
C...block: splice-coors
         DO LMOL=1,2
            IRESPIE=0 
            IATMPIE=0
            DO IPIECE=1,NPIECES
               IRES1=IPRESPIE(1,LMOL,IPIECE) 
               IRES2=IPRESPIE(2,LMOL,IPIECE)
               DO IRES=IRES1,IRES2
                  IRESPIE=IRESPIE+1
                  IF (LMOL.EQ.1) THEN
                     DO K=1,3 
                        RRES1SPL(K,IRESPIE)=RRES1(K,IRES) 
                     ENDDO
C....first atom of residue to last atom of residue IRES
                     DO IATM=IPATM1RES(1,IRES),IPATM1RES(2,IRES)
                        IATMPIE=IATMPIE+1
                        IF (IATMPIE .GT. MXATMMOL) THEN
                           WRITE(6,*)' MXATMMOL overflow '
                           STOP
                        ENDIF
                        DO K=1,3 
                           RATM1SPL(K,IATMPIE)=RATM1(K,IATM) 
                        ENDDO
                     ENDDO
                  ENDIF
                  IF (LMOL.EQ.2) THEN
                     DO K=1,3 
                        RRES2SPL(K,IRESPIE)=RRES2(K,IRES) 
                     ENDDO
C.... first atom of residue to last atom of residue IRES
                     DO IATM=IPATM2RES(1,IRES),IPATM2RES(2,IRES)
                        IATMPIE=IATMPIE+1
                        IF (IATMPIE .GT. MXATMMOL) THEN
                           WRITE(6,*)' MXATMMOL overflow '
                           STOP
                        ENDIF
                        DO K=1,3 
                           RATM2SPL(K,IATMPIE)=RATM2(K,IATM) 
                        ENDDO
                     ENDDO
                  ENDIF
C FOR IRES=IRES1,IRES2
               ENDDO
C FOR IPIECE=1,NPIECES
            ENDDO
            NRESPIE(LMOL)=IRESPIE 
            NATMPIE(LMOL)=IATMPIE
C FOR LMOL=1,2
         ENDDO
C               
C end block: splice-coors
C
         CALL REPORTPIECES
         RMS=0.0
C superpose using U3B of Wolfgang Kabsch
         IPIE1=1
C first atom and number of residues of piece 1 and 2
         IF (LCALPHA) THEN
            WRITE(6,*)'      # of residues         '
            WRITE(6,'(2I10)') ( NRESPIE(K),K=1,2 )
            WRITE(6,*)'----------------------------'
            WRITE(6,*)' CALL U3B'
            CALL U3B(WSUP2,RRES1SPL(1,1),RRES2SPL(1,1),NRESPIE(IPIE1),
     +           0,RMS,ROT,TRANS,IER)
         ELSE
            WRITE(6,*)'      # of    atoms         '
            WRITE(6,'(2I10)') ( NATMPIE(K),K=1,2 )
            WRITE(6,*)'----------------------------'
            
            CALL U3B(WSUP2,RATM1SPL(1,1),RATM2SPL(1,1),NATMPIE(IPIE1),
     +           0,RMS,ROT,TRANS,IER)
         ENDIF
         WRITE(6,'('' RMS     '',F18.7)') RMS
C LPIEBYPIE
      ENDIF
      WRITE(6,*)
      RETURN
      END
C     END COMPALISTRUC
C......................................................................

C......................................................................
C     SUB CONCAT_STRINGS
      SUBROUTINE CONCAT_STRINGS(STRING1,STRING2,RESULT)
C concatenate "string1" and "string2" into "result"
      CHARACTER*(*) STRING1,STRING2,RESULT
      INTEGER IBEG,IEND,JBEG,JEND,ILEN

      RESULT=' '
      CALL STRPOS(STRING1,IBEG,IEND)
      CALL STRPOS(STRING2,JBEG,JEND)
      ILEN= (IEND-IBEG+1) + (JEND-JBEG+1)
      IF (ILEN .GT. LEN(RESULT) ) THEN
         ILEN=LEN(RESULT)
         WRITE(6,*)' WARNING: in concat_strings: length overflow'
         WRITE(6,*)'          cut string at: ',ilen
      ENDIF
      RESULT(1:ILEN)=STRING1(IBEG:IEND)//STRING2(JBEG:JEND)
      RETURN
      END
C     END CONCAT_STRINGS
C......................................................................

C......................................................................
C     SUB CONCAT_3STRINGS
      SUBROUTINE CONCAT_3STRINGS(STRING1,STRING2,STRING3,RESULT)
C concatenate "string1" and "string2" and "string3" into "result"
      CHARACTER*(*) STRING1,STRING2,STRING3,RESULT
      INTEGER IBEG,IEND,JBEG,JEND,KBEG,KEND,ILEN

      RESULT=' '
      CALL STRPOS(STRING1,IBEG,IEND)
      CALL STRPOS(STRING2,JBEG,JEND)
      CALL STRPOS(STRING3,KBEG,KEND)
      ILEN= (IEND-IBEG+1) + (JEND-JBEG+1) + (KEND-KBEG+1)
      IF (ILEN .GT. LEN(RESULT) ) THEN
         ILEN=LEN(RESULT)
         WRITE(6,*)' WARNING: IN CONCAT_STRINGS: LENGTH OVERFLOW'
         WRITE(6,*)'          cut string at: ',ilen
      ENDIF
      RESULT(1:ILEN)=STRING1(IBEG:IEND)//STRING2(JBEG:JEND)//
     +     STRING3(KBEG:KEND)
      RETURN
      END
C     END CONCAT_3STRINGS
C......................................................................

C......................................................................
C     SUB CONCAT_INT_STRING
      SUBROUTINE CONCAT_INT_STRING(INUMBER,STRING,RESULT)
C concatenate "inumber" and "string2" into "result"
C import/export
      CHARACTER*(*) STRING,RESULT
      INTEGER INUMBER
C internal
      CHARACTER TEMP*64,CFORMAT*100
      INTEGER IBEG,IEND,JBEG,JEND,ILEN,ILOG
C init
      TEMP=' '
      RESULT=' '
      ILOG=1
C get size of number

C CAUTION can produce wrong results with very high opt-levels
c	xnumber=float( inumber )
c	if (xnumber .gt. 0.0) then
c	  ilog = nint( log10(xnumber) + 0.5 )
c	else if (xnumber .lt. 0.0) then
c	  ilog = nint( log10( abs(xnumber) ) + 1.5 )
c	endif

      IF (INUMBER .GT. 0) THEN
         IF (INUMBER .LT. 10) THEN
            ILOG=1
         ELSE IF (INUMBER .LT. 100) THEN
            ILOG=2
         ELSE IF (INUMBER .LT. 1000) THEN
            ILOG=3
         ELSE IF (INUMBER .LT. 10000) THEN
            ILOG=4
         ELSE IF (INUMBER .LT. 100000) THEN
            ILOG=5
         ELSE IF (INUMBER .LT. 1000000) THEN
            ILOG=6
         ELSE IF (INUMBER .LT. 10000000) THEN
            ILOG=7
C too big for INT4 ?
c	   else if (inumber .lt. 100000000) then
c	      ilog=8
         ELSE
            WRITE(6,*)' ERROR in CONCAT_INT_STRING: update plus'
            CALL FLUSH_UNIT(6)
         ENDIF
      ELSE IF (INUMBER .LT. 0) THEN
         IF (INUMBER .GT. -10) THEN
            ILOG=2
         ELSE IF (INUMBER .GT. -100) THEN
            ILOG=3
         ELSE IF (INUMBER .GT. -1000) THEN
            ILOG=4
         ELSE IF (INUMBER .GT. -10000) THEN
            ILOG=5
         ELSE IF (INUMBER .GT. -100000) THEN
            ILOG=6
         ELSE IF (INUMBER .GT. -1000000) THEN
            ILOG=7
c	   else if (inumber .gt. -10000000) then
c	      ilog=8
c	   else if (inumber .gt. -100000000) then
c	      ilog=9
         ELSE
            WRITE(6,*)' ERROR in CONCAT_INT_STRING: update minus'
            CALL FLUSH_UNIT(6)
         ENDIF
      ENDIF
      CALL CONCAT_STRING_INT('(I',ILOG,TEMP)
      CALL CONCAT_STRINGS(TEMP,')',CFORMAT)
      TEMP=' '
      WRITE(TEMP(1:),CFORMAT)INUMBER
      CALL STRPOS(TEMP,IBEG,IEND)
      CALL STRPOS(STRING,JBEG,JEND)
      IEND=IBEG+ILOG-1
      ILEN= (IEND-IBEG+1) + (JEND-JBEG+1)
      IF (ILEN .GT. LEN(RESULT) ) THEN
         ILEN=LEN(RESULT)
         WRITE(6,*)' WARNING: in concat_int_string: length overflow'
         WRITE(6,*)'          cut string at: ',ilen
      ENDIF
      RESULT(1:ILEN)=TEMP(IBEG:IEND)//STRING(JBEG:JEND)
      RETURN
      END
C     END CONCAT_INT_STRING
C......................................................................

C......................................................................
C     SUB CONCAT_STRING_INT
      SUBROUTINE CONCAT_STRING_INT(STRING,INUMBER,RESULT)
C concatenate "inumber" and "string2" into "result"
C import/export
      CHARACTER*(*) STRING,RESULT
      INTEGER INUMBER
C internal
      CHARACTER TEMP*64,CFORMAT*100
      INTEGER IBEG,IEND,JBEG,JEND,ILEN,ILOG
C init
      TEMP=' '
      RESULT=' '
      ILOG=1
C get size of number
c with some agressive optimizations, this can go wrong
c	xnumber=float( inumber )
c	if (xnumber .gt. 0.0) then
c	  ilog = nint( log10(xnumber) ) + 1
c	else if (xnumber .lt. 0.0) then
c	  ilog = nint( log10( abs(xnumber) ) ) + 2
c	endif

      IF (INUMBER .GT. 0) THEN
         IF (INUMBER .LT. 10) THEN
            ILOG=1
         ELSE IF (INUMBER .LT. 100) THEN
            ILOG=2
         ELSE IF (INUMBER .LT. 1000) THEN
            ILOG=3
         ELSE IF (INUMBER .LT. 10000) THEN
            ILOG=4
         ELSE IF (INUMBER .LT. 100000) THEN
            ILOG=5
         ELSE IF (INUMBER .LT. 1000000) THEN
            ILOG=6
         ELSE IF (INUMBER .LT. 10000000) THEN
            ILOG=7
C too big for INT4 ?
c	   else if (inumber .lt. 100000000) then
c	      ilog=8
c	   else if (inumber .lt. 1000000000) then
c	      ilog=9
c	   else if (inumber .lt. 10000000000) then
c	      ilog=10
         ELSE
            WRITE(6,*)' ERROR in CONCAT_STRING_INT: update plus'
            CALL FLUSH_UNIT(6)
         ENDIF
      ELSE IF (INUMBER .LT. 0) THEN
         IF (INUMBER .GT. -10) THEN
            ILOG=2
         ELSE IF (INUMBER .GT. -100) THEN
            ILOG=3
         ELSE IF (INUMBER .GT. -1000) THEN
            ILOG=4
         ELSE IF (INUMBER .GT. -10000) THEN
            ILOG=5
         ELSE IF (INUMBER .GT. -100000) THEN
            ILOG=6
         ELSE IF (INUMBER .GT. -1000000) THEN
            ILOG=7
c	   else if (inumber .gt. -10000000) then
c	      ilog=8
c	   else if (inumber .gt. -100000000) then
c	      ilog=9
c	   else if (inumber .gt. -1000000000) then
c	      ilog=10
         ELSE
            WRITE(6,*)' ERROR in CONCAT_STRING_INT: update minus'
            CALL FLUSH_UNIT(6)
         ENDIF
      ENDIF
      
      CALL MAKE_FORMAT_INT(ILOG,CFORMAT)
      WRITE(TEMP(1:),CFORMAT)INUMBER
      CALL STRPOS(TEMP,IBEG,IEND)
      CALL STRPOS(STRING,JBEG,JEND)
      IEND=IBEG+ILOG-1
      ILEN= (IEND-IBEG+1) + (JEND-JBEG+1)
      IF (ILEN .GT. LEN(RESULT) ) THEN
         ILEN=LEN(RESULT)
         WRITE(6,*)' WARNING: in concat_int_string: length overflow'
         WRITE(6,*)'          cut string at: ',ilen
      ENDIF
      RESULT(1:ILEN)=STRING(JBEG:JEND)//TEMP(IBEG:IEND)
      RETURN
      END
C     END CONCAT_STRING_INT
C......................................................................

C......................................................................
C     SUB DAMP_GAPWEIGHT
      SUBROUTINE DAMP_GAPWEIGHT(IBEG,IEND,VALUE,NDAMP,PUNISH)
C damp the gap-open weights by taking the mean of the range +- ndamp
C CAUTION set "punish" high enough
C NOT true anymore: if indels in sec-struc are not allowed these
C positions are not taken into account (punish)

      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      REAL PUNISH
C     INPUT
      REAL VALUE(*)
      INTEGER IBEG,IEND,NDAMP,NPOS
C     INTERNAL
      INTEGER I,J
      REAL SUM
      
      DO I=IBEG,IEND
         SUM=0.0
         NPOS=0
         DO J=MAX(I-NDAMP,IBEG),MIN(I+NDAMP,IEND)
            SUM=SUM + VALUE(J)
            NPOS=NPOS+1
         ENDDO
         VALUE(I)= SUM / FLOAT(NPOS)
      ENDDO
      RETURN
      END
C     END DAMP_GAPWEIGHT
C......................................................................

C......................................................................
C     SUB DO_ALIGN
      SUBROUTINE DO_ALIGN(LH1,LH2,ISET,IALIGN,NRECORD,SDEV) 
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
C 
C import implicit 
C     LPASS2=(from maxhom) true if protein IALIGN to take for 2nd pass
C 
C import
C     ISET=  (from maxhom) number of processor (=0 if not parallel)
C     IALIGN=(from maxhom) number of proteins aligned before, i.e.
C                          current protein is (IALIGN+1)!
C     
      INTEGER   ISET,IALIGN,NRECORD
      REAL      SDEV
C internal
      REAL      LH1(0:MAXMAT)
      INTEGER*2 LH2(0:MAXTRACE)

C     REAL LH(0:MAXMAT*2)
      LOGICAL   LERROR
      INTEGER   I,IBEG,IEND,ND1,ND2,NDMAT,N2,N2NEW,N2REST
      INTEGER   NTEST,BESTIIPOS,BESTJJPOS,NREGION,IBREAK,JBREAK
      INTEGER   IPOSBEG,IPOSEND,JPOSBEG,JPOSEND
      REAL      BESTVAL
      CHARACTER CSYMBOL
      LOGICAL   LDBG_LOCAL
      INTEGER   JLOC
C---- ------------------------------------------------------------------
C     INIT
C---- ------------------------------------------------------------------
      LTRACEOUT= .FALSE.
C     BR 99.09: just to write out dbg
      LDBG_LOCAL=.FALSE.
C      LDBG_LOCAL=.TRUE.
      
      
      IF (LDSSP_2) THEN
         CALL LOWER_TO_CYS(CSQ_2,N2IN)
      ENDIF
      CALL SEQ_TO_INTEGER(CSQ_2,LSQ_2,N2IN,TRANSPOS)

C     get position of chain breaks
      CALL GETCHAINBREAKS(N2IN,LSQ_2,STRUC_2,TRANS,NBREAK_2,IBREAKPOS_2)

      IF (LDSSP_2) THEN
C         WRITE(*,*)' here check :second file is DSSP,NIO_2',NIOSTATES_2
         CALL STR_TO_INT(N2IN,STRUC_2,LSTRUC_2,STRTRANS )
         CALL STR_TO_CLASS(MAXSTRSTATES,STR_CLASSES,N2IN,STRUC_2,
     +        STRCLASS_2,LSTRCLASS_2)
         CALL ACC_TO_INT(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +        NSTRSTATES_2,NIOSTATES_2,IORANGE,N2IN,
     +        LSQ_2,LSTRCLASS_2,NSURF_2,LACC_2)

C     not DSSP
      ELSE
         I=INDEX(STRTRANS,'U')
         CALL INIT_INT_ARRAY(1,N2IN,LSTRUC_2,I)
         DO I=1,MAXSTRSTATES
            IF ( INDEX(STR_CLASSES(I),STRUC_2(1)) .NE. 0) THEN
               CALL INIT_INT_ARRAY(1,N2IN,LSTRCLASS_2,I)
               CSYMBOL=STR_CLASSES(I)(1:1) 
            ENDIF
         ENDDO
         DO I=1,N2IN 
            STRCLASS_2(I:I)=CSYMBOL 
         ENDDO
         
         CALL INIT_INT_ARRAY(1,N2IN,LACC_2,1)
      ENDIF

C     set gap-open to a high value in SECONDARY STRUCTURE SEGMENTS
      IF (.NOT. LINSERT_2 .AND. LDSSP_2) THEN
         CALL PUNISH_GAP(N2IN,STRUC_2,'HE',PUNISH,GAPOPEN_2 )
      ENDIF
      
      IEND=    0
      LSHIFTED=.FALSE.
      N2=      N2IN
      N2REST=  N2IN
      NSHIFTED=0

C     ATTEMPT TO USE N2 FOR ALIGNMENT
C     RESET N2 TO A VALUE SMALLER THAN N2REST IF NEEDED
C     SET ND1 AND ND2, THE MATRIX DIMENSION TO BE USED
CAUTION LH(O:ND1,0:ND2)
 350  ND1=     N1+1 
      ND2=     N2+1 
      NDMAT=   (1+ND1)*(1+ND2)
      LSHIFTED=(NDMAT.GT.MAXTRACE)
      IF (LSHIFTED) THEN
         ND2= (INT(MAXTRACE/(ND1+1)) )-1
         N2=ND2-1
         CALL OPEN_FILE(KWARN,WARNFILE,'UNKNOWN,APPEND',LERROR)
         CALL STRPOS(NAME_2,IBEG,IEND)
         WRITE(LOGSTRING(1:),'(A,I10,I10,I10,A,I8,A,A)')
     +        ' *** WARN: MAXTRACE or MAXMAT OVERFLOW: ',
     +        MAXTRACE,MAXMAT,NDMAT,
     +        ' TRUNCATED TO:',N2,' FOR: ',name_2(ibeg:iend)
         CALL LOG_FILE(KLOG,LOGSTRING,1)
         CALL LOG_FILE(KWARN,LOGSTRING,0)
         NDMAT=(1+ND1)*(1+ND2)
         CALL CLOSE_FILE(KWARN,WARNFILE)
      ENDIF
C=======================================================================
C TRACE-FILE
C HEADERS TO PLOT FILE..(after the second run )
C=======================================================================
      LTRACEOUT=.FALSE.
      IF (LTRACE .AND. .NOT. LPASS2) THEN
         LTRACEOUT=.TRUE.
      ENDIF
C=======================================================================
C THE MEAT
C=======================================================================
      NTEST=0 
      BESTVAL=1000000.0
C=======================================================================
C the NBEST alignments are selected via TRACE
C=======================================================================
      NREGION=(NBREAK_1+1) * (NBREAK_2+1)
      DO WHILE (NTEST .LT. NREGION*NBEST .AND. BESTVAL.GT.0.0)
         DO IBREAK=1,NBREAK_1+1
            IF (IBREAK .GT. NBREAK_1) THEN 
               IPOSEND=N1
            ELSE 
               IPOSEND=IBREAKPOS_1(IBREAK)-1
            ENDIF
            IF (IBREAK .EQ. 1) THEN 
               IPOSBEG=1
            ELSE 
               IPOSBEG=IBREAKPOS_1(IBREAK-1)+1
            ENDIF
            DO JBREAK=1,NBREAK_2+1
               IF (JBREAK .GT. NBREAK_2) THEN 
                  JPOSEND=N2
               ELSE 
                  JPOSEND=IBREAKPOS_2(JBREAK)-1
               ENDIF
               IF (JBREAK .EQ. 1) THEN 
                  JPOSBEG=1
               ELSE 
                  JPOSBEG=IBREAKPOS_2(JBREAK-1)+1
               ENDIF

C check if the 2 sequences are identical
               LSAMESEQ=.FALSE.
               IF (.NOT. LSHOW_SAMESEQ) THEN
                  IF (IPOSEND-IPOSBEG .EQ. JPOSEND-JPOSBEG) THEN
	             LSAMESEQ=.TRUE.
	             I=1
	             DO WHILE (I .LT. (IPOSEND-IPOSBEG+1) 
     +                    .AND. LSAMESEQ)
	                IF (CSQ_1(I:I) .NE. CSQ_2(I:I) ) THEN
                           LSAMESEQ=.FALSE.
			ENDIF
	                I=I+1
	             ENDDO
	             IF (LSAMESEQ) WRITE(6,*)' identical sequences '
                  ENDIF
               else
               ENDIF
c default trace is diagonal
               IF (LBACKWARD) THEN
                  DO I=0,NDMAT 
                     LH2(I)=1 
                  ENDDO
c		    do i=ndmat,ndmat*2 ; lh(i)=20000.0 ; enddo
cwrong	            call init_real_array(ndmat,ndmat*2,lh,20000.0)
                  WRITE(6,*)' SETMATRIX sub not modified yet'
                  STOP
                  CALL SETMATRIX(IPOSBEG,IPOSEND,JPOSBEG,
     +                 JPOSEND,N2,LH1,LH2)
                  CALL GETBEST(IPOSBEG+1,IPOSEND+1,JPOSBEG+1,
     +                 JPOSEND+1,1,NTEST,LH1,LH2,ND1,ND2,
     +                 BESTVAL,BESTIIPOS,BESTJJPOS)
                  WRITE(6,*)BESTVAL,BESTIIPOS,BESTJJPOS
                  SUBOPT_VAL=BESTVAL-((FILTER_VAL*BESTVAL)/100.0)
                  CALL SETBACK(IPOSBEG,IPOSEND,JPOSBEG,
     +                 JPOSEND,N2,LH1,LH2,BESTVAL)
               ELSE
                  CALL INIT_INT2_ARRAY(0,NDMAT,LH2,1)
                  WRITE(6,*)' INFO: PROFILEMODE=',PROFILEMODE
                  CALL SETMATRIX_FAST(IPOSBEG,IPOSEND,JPOSBEG,
     +                 JPOSEND,N2,LH2,BESTVAL,BESTIIPOS,
     +                 BESTJJPOS)
C                  DO I=1,IPOSEND
C                  WRITE(6,*)' info:LH2 '
C                  WRITE(6,111)(LH2(I),I=1,NDMAT)
C                  ENDDO
C 111                 FORMAT(15(I6))
C                  WRITE(6,*)'BESTVAL,BESTIIPOS,BESTJJPOS ',
C     +                 BESTVAL,BESTIIPOS,BESTJJPOS
               ENDIF

C     NOTE:    TRACE will aplpy threshold, and return LCONSIDER=.FALSE.
C              if below threshold!
               IF (BESTVAL.GT.0.0) THEN
                  CALL TRACE(ISET,ND1,ND2,LH2,IPOSBEG,JPOSBEG,
     +                 BESTVAL,BESTIIPOS,BESTJJPOS,NTEST,SDEV,
     +                 IALIGN,NRECORD)
               ENDIF
            ENDDO
         ENDDO
      ENDDO

C=======================================================================
      IF (.NOT. LPASS2 .AND. LTRACE) THEN
         LTRACE=.FALSE. 
         LTRACEOUT=.FALSE.
         CLOSE(KPLOT)
      ENDIF
C=======================================================================
C     ENTRY FOR SHIFTED REPEAT OF TOO LONG SEQUENCE
C     N2 was used in previous alignment
      IF (LSHIFTED) THEN
         IEND=N2-1
         IF (IEND.EQ.0) THEN
            STOP' MAXMAT, MAXTRACE OR MAXSQ TOO SMALL, IEND=0'
         ENDIF
         DO I=1,N2REST-IEND
            CSQ_2(I:I)=CSQ_2(I+IEND:I+IEND)
            STRUC_2(I)=STRUC_2(I+IEND)
            LSQ_2(I)=LSQ_2(I+IEND) 
            NSURF_2(I)=NSURF_2(I+IEND)
         ENDDO
         DO I=N2REST-IEND+1,N2REST
            CSQ_2(I:I)=' ' 
            STRUC_2(I)=' '
            LSQ_2(I)=0     
            NSURF_2(I)=0
         ENDDO
         N2NEW=N2REST-IEND
C     NEW LENGTH TO USE IS N2NEW
         N2REST=N2NEW
         NSHIFTED=NSHIFTED+IEND
c	  WRITE(6,'(a,i6)')'>>REPEAT PASS, TOTAL SHIFT:',nshifted
         N2=N2REST
         GOTO 350
      ENDIF
C=======================================================================
C calculate conservation weights
C then next sequence in file list or global sort
C=======================================================================

      IF ( LALIOVERFLOW .EQV. .FALSE.) THEN
         IF (LPASS2 .EQV. .TRUE.        .AND.
     +        LCONSERV_1 .EQV. .TRUE.   .AND.
     +        LCONSIMPORT .EQV. .FALSE. .AND.
     +        IALIGN .GT. 0) THEN
C            WRITE(6,*)' CALL GETCONSWEIGHT i=',IALIGN
            CALL GETCONSWEIGHT(N1,IALIGN,LSQ_1)
         ENDIF
         IALIGNOLD=IALIGN
      ENDIF
      
C=======================================================================
C debug 
C=======================================================================
C      IF (LDBG_LOCAL) THEN
C         DO I=1,N1
C            WRITE(6,'(I,F7.2)')I,SMIN
C         ENDDO
C	DO I=1,N1 
C           WRITE(6,'(I,F7.2)')I,SMAX
C        ENDDO
C	DO I=1,N1 
C           WRITE(6,'(I,F7.2)')I,OPEN_1
C        ENDDO
C	DO I=1,N1
C           WRITE(6,'(I,F7.2)')I,SMIN*CONSWEIGHT_1(I)
C	ENDDO
C	DO I=1,N1
C           WRITE(6,'(I,F7.2)')I,SMAX*CONSWEIGHT_1(I)
C	ENDDO
C	DO I=1,N1
C           WRITE(6,'(I,F7.2)')I,OPEN_GAP_1(I)
C        ENDDO
C      END IF
C     end dbg

C=======================================================================
      RETURN
      END
C     END DO_ALIGN
C......................................................................

C......................................................................
C     SUB EXTRACT_INTEGER
      SUBROUTINE EXTRACT_INTEGER(LINE,CDIVIDE,KEYWORD,INTVAL)
C extract an integer from a line beginning with a keyword ; cdivide 
C indicates the border between keyword and value for keyword
C like:    THIS_IS_A_KEYWORD : this_is_the_value_for_keyword
      IMPLICIT NONE
C import
      CHARACTER*(*) LINE,KEYWORD,CDIVIDE
c export
      INTEGER INTVAL
c internal
      INTEGER LENKEY,I,J,IBEG
c======================================================================
      CALL STRPOS(KEYWORD,I,J)
      LENKEY=J-I+1

      IF ( LINE(1:LENKEY) .EQ. KEYWORD(I:J) ) THEN
         CALL STRPOS(LINE,I,J)
         IBEG=INDEX(LINE,CDIVIDE)
         IF (IBEG .EQ. 0) THEN
            WRITE(6,'(A,A,A)')
     +           'ERROR IN EXTRACT_INTEGER: no ',cdivide,'in line'
	    STOP
         ENDIF
         CALL STRPOS(LINE(IBEG+1:J),I,J)
         CALL READ_INT_FROM_STRING(LINE(IBEG+I:IBEG+J),INTVAL)
c          WRITE(6,'(A,A,I6)')line(1:lenkey),' is: ',intval
      ENDIF
      RETURN
      END
C     END EXTRACT_INTEGER
C......................................................................

C......................................................................
C     SUB EXTRACT_REAL
      SUBROUTINE EXTRACT_REAL(LINE,CDIVIDE,KEYWORD,REALVAL)
C extract an integer from a line beginning with a keyword ; cdivide 
C indicates the border between keyword and value for keyword
C like:    THIS_IS_A_KEYWORD : this_is_the_value_for_keyword
      IMPLICIT NONE
C import
      CHARACTER*(*) LINE,KEYWORD,CDIVIDE
c export
      REAL REALVAL
c internal
      INTEGER LENKEY,I,J,IBEG
c======================================================================
      CALL STRPOS(KEYWORD,I,J)
      LENKEY=J-I+1
      
      IF ( LINE(1:LENKEY) .EQ. KEYWORD(I:J) ) THEN
         CALL STRPOS(LINE,I,J)
         IBEG=INDEX(LINE,CDIVIDE)
         IF (IBEG .EQ. 0) THEN
            WRITE(6,'(A,A,A)')
     +           'ERROR IN EXTRACT_REAL: no ',cdivide,'in line'
	    STOP
         ENDIF
         CALL STRPOS(LINE(IBEG+1:J),I,J)
         CALL READ_REAL_FROM_STRING(LINE(IBEG+I:IBEG+J),REALVAL)
c          WRITE(6,'(A,A,F7.2)')line(1:lenkey),' is: ',realval
      ENDIF
      RETURN
      END
C     END EXTRACT_REAL
C......................................................................

C......................................................................
C     SUB EXTRACT_INTEGER_RANGE
      SUBROUTINE EXTRACT_INTEGER_RANGE(LINE,CDIVIDE1,CDIVIDE2,INTVAL)
C extract two integers from a line ; 
C cdivide1 indicates the border between keyword and values for keyword
C cdivide2 seperetes the two values
C like:    THIS_IS_A_KEYWORD : first_value_for_keyword - second_value
      IMPLICIT NONE
C import
      CHARACTER*(*) LINE,CDIVIDE1,CDIVIDE2
c export
      INTEGER INTVAL(1,2)
c internal
      INTEGER I,J,IBEG1,IBEG2
c======================================================================
      IBEG1=INDEX(LINE,CDIVIDE1)
      IBEG2=INDEX(LINE,CDIVIDE2)
      IF (IBEG1.EQ.0 .OR. IBEG2 .EQ. 0) THEN
         WRITE(6,'(A,A,A,A)')
     +        'ERROR IN EXTRACT_INTEGER_RANGE: no ',cdivide1,' or ',
     +        cdivide2
         STOP
      ENDIF
      CALL STRPOS(LINE(IBEG1+1:IBEG2-1),I,J)
      CALL READ_INT_FROM_STRING(LINE(IBEG1+I:IBEG1+J),INTVAL(1,1) )
      CALL STRPOS(LINE(IBEG2+1:),I,J)
      CALL READ_INT_FROM_STRING(LINE(IBEG2+I:IBEG2+J),INTVAL(1,2) )
      RETURN
      END
C     END EXTRACT_INTEGER_RANGE
C......................................................................

C......................................................................
C     SUB EXTRACT_STRING
      SUBROUTINE EXTRACT_STRING(LINE,CDIVIDE,KEYWORD,STRING)
C extract a string from a line beginning with a keyword ; cdivide 
C indicates the border between keyword and value for keyword
C like:    THIS_IS_A_KEYWORD : this_is_the_string_for_keyword
      IMPLICIT NONE
C import
      CHARACTER*(*) LINE,KEYWORD,CDIVIDE
C export
      CHARACTER*(*) STRING
C internal
      INTEGER LENKEY,I,J,IBEG
C======================================================================
      CALL STRPOS(KEYWORD,I,J)
      LENKEY=J-I+1

      IF ( LINE(1:LENKEY) .EQ. KEYWORD(I:J) ) THEN
         CALL STRPOS(LINE,I,J)
         IBEG=INDEX(LINE,CDIVIDE)
         IF (IBEG.EQ.0) THEN
            WRITE(6,'(A,A,A)')
     +           'ERROR IN EXTRACT_STRING: no ',CDIVIDE,'in line'
	    STOP
         ENDIF
         IF (J .GT. IBEG+1) THEN
	    CALL STRPOS(LINE(IBEG+1:J),I,J)
            STRING=LINE(IBEG+I:IBEG+J)
         ELSE
	    STRING=' '
         ENDIF
c          WRITE(6,*)LINE(1:LENKEY)//' is: '//LINE(IBEG+I:IBEG+J)
      ENDIF
      RETURN
      END
C     END EXTRACT_STRING
C......................................................................

C......................................................................
C     SUB EVALPRED
      SUBROUTINE EVALPRED(PROTEIN,METHOD,PRED,STRUC,NRES,LDSSP,
     +     KOUT,KSTA)
C EXTERNAL
      LOGICAL         LDSSP
      CHARACTER*1     STRUC(*),PRED(*)
      CHARACTER*(*)   METHOD, PROTEIN
      INTEGER         NRES, KOUT, KSTA
C files KOUT and KSTA must be open for write
C INTERNAL  
      PARAMETER      (MSTATES=                   3)
C *10 ALIASES
      CHARACTER*10    STATES(MSTATES)    
C                (PREDICTED,OBSERVED)  sub=0 means undefined symbol.
      DIMENSION       NC(0:MSTATES,0:MSTATES),NCOBS(0:MSTATES)
      DIMENSION       NCPRE(0:MSTATES),MPERPRE(MSTATES),MPEROBS(MSTATES)
CAUTION - ANY CHANGE IN THE ORDER OF 
C STATES MUST BE MADE IN PRED-STAT AS WELL
C                     SHEET        LOOP        HELIX   
      DATA STATES/'EBAPMebapm','TCLS tcls ','HGI..hgi..'/
*----------------------------------------------------------------------*
C PROCEDURE
      DO NP=0,MSTATES
         DO NS=0,MSTATES
            NC(NP,NS)=0
         ENDDO
      ENDDO
      NUNPRED=0
      NPRED=0   
      DO I=1,NRES
C FIND STRUCTURE INDEX
         NP=0
         NS=0
         DO LS=1,MSTATES
            IF (INDEX(STATES(LS), PRED(I))  .NE. 0) NP=LS
            IF (INDEX(STATES(LS), STRUC(I)) .NE. 0) NS=LS
         ENDDO
C OBS only via DSSP 
         IF (LDSSP) THEN
            IF (NS .EQ. 0) THEN
               WRITE(6,*)'UNKNOWN DSSP STATE AT RES',I, struc(i)
c     STOP'*** error in  EVALPRED '
            ENDIF
         ELSE
            NS=0
         ENDIF
C INCREMENT COUNTER
         NC(NP,NS)=NC(NP,NS)+1
         IF (NP .NE. 0) THEN
            NPRED=NPRED+1
         ELSE
            NUNPRED=NUNPRED+1
         ENDIF
      ENDDO
C   (I,J) = (PREDICTED,OBSERVED)
C    SUCCESS RATES: NCII=SUM(OVER I.NE.0) NC(I,I)
C                   NCOBS(J)=SUM(OVER I=1..3) NC(I,J) 
C                            of those predicted
C                   NCPRE(I)=SUM(OVER J=0..3) NC(I,J)  of all
C PREDICTED RES   : NPRED=SUM(OVER I=1..3) NCPRE(I)
C UNPREDICTED       NUNPRED=NCPRE(0)
      NCII=0
      DO I=0,MSTATES
         NCOBS(I)=0
         NCPRE(I)=0
         DO J=0,MSTATES
            IF (I .EQ. J .AND. I .NE. 0) NCII=NCII+NC(I,J)
C not the unpredicted
            IF (J .NE. 0) NCOBS(I)=NCOBS(I)+NC(J,I)  
C all (not) observed
            NCPRE(I)=NCPRE(I)+NC(I,J)  
         ENDDO
      ENDDO
      IF (NRES.NE.0) THEN
         PERPRED=NINT(100.*NPRED/FLOAT(NRES))
      ELSE
         PERPRED=0.0
         WRITE(6,*)'***EVALPRED: NRES=0'
      ENDIF
C check for consistency
      IF (NUNPRED .NE. NCPRE(0)) THEN
         WRITE(6,*) NUNPRED,NCPRE(0)
         STOP '*** EVALPRED: NUNPRED.NE.NCPRE(0), you idiot '
      ENDIF
      IF (NPRED.NE.NRES-NUNPRED) THEN
         WRITE(6,*) NPRED, NUNPRED, NRES
         WRITE(6,*)'*** EVALPRED ERROR: NPRED,NUNPRED,NRES dont add up'
      ENDIF
C print
      IF (LDSSP) THEN
         IF (NPRED.NE.0) THEN
            CORRECT=NCII/FLOAT(NPRED)*100
         ELSE
            CORRECT=0.0
            WRITE(6,*)'***EVALPRED: NPRED=0'
         ENDIF
         IF (KOUT.NE.0) THEN
            WRITE(KOUT,110) PROTEIN,METHOD,NRES,NPRED,PERPRED,CORRECT
	 ENDIF
         WRITE(   *,110) PROTEIN,METHOD,NRES,NPRED,PERPRED,CORRECT
      ELSE
         CORRECT=0.0
         IF (KOUT.NE.0) THEN
            WRITE(KOUT,110) PROTEIN,METHOD,NRES,NPRED,PERPRED
	 ENDIF
         WRITE(   *,110) PROTEIN,METHOD,NRES,NPRED,PERPRED
 110     FORMAT(1X,A4,1X,A10,I5,' residues',I5,' predicted.',/,
     +        ' Result: ',F5.1,'% predicted',F7.1,'% correct')
C LDSSP
      ENDIF
C percentage in the universe of predicted (NPRED.LE.NRES)
      DO I=1,MSTATES
         IF (NPRED.NE.0) THEN
            MPERPRE(I)=NINT(NCPRE(I)/FLOAT(NPRED)*100.0)
         ELSE
            MPERPRE(I)=0
         ENDIF
         IF (NPRED.NE.0) THEN
            MPEROBS(I)=NINT(NCOBS(I)/FLOAT(NPRED)*100.0)
         ELSE
            MPEROBS(I)=0
         ENDIF
      ENDDO
C
      IF (KOUT.NE.0) THEN
	 WRITE(KOUT,113)
 113     FORMAT(40X,'P R E D I C T E D ')
         WRITE(KOUT,114) (STATES(J),J=1,MSTATES),'total','    %'
 114     FORMAT(40X,10(1X,A5))
         IF (LDSSP) THEN
            DO J=1,MSTATES
               WRITE(KOUT,112)'OBS',STATES(J),(NC(I,J),I=1,MSTATES),
     +              NCOBS(J),MPEROBS(J)
            ENDDO
         ENDIF
C     DSSP or no DSSP:
         WRITE(KOUT,112)' ',' ',(NCPRE(I), I=1,MSTATES)
 112     FORMAT(1X,30X,A3,1X,A5,10I6)
         WRITE(KOUT,112)' ','!',(MPERPRE(I), I=1,MSTATES)
      ENDIF
C output for prediction statistics
      WRITE(KSTA,111) PROTEIN,METHOD,NRES,NPRED,CORRECT,
     +     ((NC(I,J),I=1,MSTATES),J=1,MSTATES)
 111  FORMAT(A4,1X,A10,2I5,F5.1,'%',20I5)
      RETURN
      END
C END EVALPRED
C......................................................................

C================================================================
c$$$	subroutine fetch_sw_seq(path,indexfile,datafile,kindex,kdat,
c$$$  +                   MAXSQ,nres,name,compnd,ACCESSION,pdbref,
c$$$     +                       seq,lend)
c$$$
c$$$	implicit none
c$$$C import
c$$$	integer MAXSQ,kindex,kdat
c$$$	character*(*) path,indexfile,datafile
c$$$C export
c$$$	integer nres
c$$$	character*(*) name,compnd,ACCESSION,pdbref,seq
c$$$	logical lend,lbinary
c$$$C internal
c$$$	integer maxchar,indexreclen,nsize
c$$$	parameter (maxchar=38,indexreclen=40,nsize=12)
c$$$
c$$$	integer i,j,ipos,jpos,irec,idatindex,ifile
c$$$	logical lfound,lerror
c$$$	character*132 templine,filename
c$$$	character     alphabet*(maxchar)
c$$$	character     testline*(indexreclen)
c$$$
c$$$	alphabet='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_.'
c$$$	idatindex=0
c$$$	lbinary=.true.
c$$$
c$$$	call concat_strings(path,indexfile,filename)
c$$$	call open_file(kindex,filename,
c$$$     +             'OLD,DIRECT,FORMATTED,READONLY,RECL=40',lerror)
c$$$
c$$$	call strpos(name,i,j)
c$$$
c$$$	lfound=.false.
c$$$	ipos=index(alphabet,name(i:i))
c$$$	jpos=index(alphabet,name(i+1:i+1))
c$$$	irec= ( ( (ipos-1) * maxchar) + jpos) + 1
c$$$	read(kindex,'(2x,i8)',rec=irec)irec
c$$$        if (irec .eq. 0)goto 900
c$$$
c$$$	do while(.not. lfound)
c$$$           read(kindex,'(a)',rec=irec)testline
c$$$           if (index (testline,name(i:j)) .ne. 0) then
c$$$             read(testline,'(12x,a,i8,i8)')
c$$$     +              ACCESSION(1:nsize),idatindex,ifile
c$$$	     lfound=.true.
c$$$	   endif
c$$$	   irec=irec+1
c$$$	enddo
c$$$	close(kindex)
c$$$	if (idatindex .ge. 1) then
c$$$	  call concat_int_string(ifile,datafile,filename)
c$$$	  call concat_strings(path,filename,templine)
c$$$	  call open_file(kdat,templine,'OLD',lerror)
c$$$	  do i=1,idatindex-1 
c$$$	     read(kdat,'(a)')testline(1:1)
c$$$	  enddo
c$$$     call get_swiss_entry(MAXSQ,kdat,lbinary,nres,name,compnd,
c$$$     +                         ACCESSION,pdbref,seq,lend)
c$$$	  close(kdat)
c$$$          return
c$$$        endif
c$$$900     WRITE(6,*)'*** ERROR: index in fetch_sw_seq is 0 ;'
c$$$        WRITE(6,*)'           or nothing found'
c$$$	nres=0
c$$$	name=' '
c$$$        compnd=' '
c$$$        ACCESSION=' '
c$$$        pdbref=' '
c$$$	seq=' '
c$$$        return
c$$$	end
C======================================================================
C......................................................................

C......................................................................
C     SUB FILLSIMMETRIC
      SUBROUTINE FILLSIMMETRIC(MAXRES,NTRANS,MAXSTRSTATES,maxiostates,
     +     NSTRSTATES_1,NSTRSTATES_2,CSTRSTATES,SIMMETRIC,NRES,
     +     LSEQ,LSTR,LACC,POSSIMMETRIC)
      
      IMPLICIT NONE
      INTEGER NTRANS,MAXRES,NRES
      INTEGER MAXSTRSTATES,maxiostates
      INTEGER NSTRSTATES_1,NSTRSTATES_2
      CHARACTER*(*) CSTRSTATES
      
      REAL SIMMETRIC(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +     MAXSTRSTATES,MAXIOSTATES)
      INTEGER LSEQ(*),LACC(*),LSTR(*)
      REAL POSSIMMETRIC(MAXRES,*)
C internal
      INTEGER I,J,ISTR
C
      IF (NSTRSTATES_2 .GT. 1) THEN
         WRITE(6,*)' **** ERROR: nstrstates_2 .gt. 1'
         WRITE(6,*)' not possible to fill position dependend metric'
         STOP
      ENDIF

      DO I=1,NRES
         IF (NSTRSTATES_1 .GT.1) THEN
            ISTR=LSTR(I)
            IF (ISTR .EQ. 0)ISTR=1
         ELSE
            ISTR=1
         ENDIF
         IF (LSEQ(I) .EQ. 0) THEN
            DO J=1,NTRANS
               WRITE(6,*)'fillsimmetric: lseq unknown: ',lseq(i)
               POSSIMMETRIC(I,J)=0.0
            ENDDO
         ELSE
            DO J=1,NTRANS
c	      WRITE(6,'(a)')'fill i,j,lseq,lstr,lacc: '
c              WRITE(6,'(5(i4))')i,j,lseq(i),istr,lacc(i)
               POSSIMMETRIC(I,J)=SIMMETRIC(LSEQ(I),J,ISTR,LACC(I),1,1)
            ENDDO
         ENDIF
      ENDDO
      RETURN
      END
C     END FILLSIMMETRIC
C......................................................................

C......................................................................
C     SUB FINDBRKFILE
      SUBROUTINE FINDBRKFILE(PDBFILE,PDBPATH,PID,KPDB,KLOG,LERROR)

      IMPLICIT NONE
      CHARACTER*(*) PDBFILE,PDBPATH,PID
      CHARACTER CEXT*30
      LOGICAL LERROR
      INTEGER KPDB,KLOG
C internal
      CHARACTER*200 LOGSTRING
      
      LERROR=.FALSE.

      cext='.brk'
c       cext='.pdb'
      IF (PDBPATH.EQ.' ') THEN
         CALL CONCAT_STRINGS(PID,CEXT,PDBFILE)
      ELSE
         CALL CONCAT_STRINGS(PID,CEXT,LOGSTRING)
         CALL CONCAT_STRINGS(PDBPATH,LOGSTRING,PDBFILE)
      ENDIF
      CALL OPEN_FILE(KPDB,PDBFILE,'OLD,READONLY',LERROR)
      IF (LERROR) THEN
         CALL CONCAT_STRINGS('PDB-FILE NOT FOUND: ',PDBFILE,LOGSTRING)
         CALL LOG_FILE(KLOG,LOGSTRING,1)
      ENDIF
      CLOSE(KPDB)
      RETURN
      END
C     END FINDBRKFILE
C......................................................................

C......................................................................
C     SUB GET_DEFAULT
      SUBROUTINE GET_DEFAULT()
C get the system specific location of files
C MAXHOM_DEFAULT is a logical name pointing to the maxhom.default file
C VMS : assign $1:[schneider.public]maxhom.default
C UNIX: setenv maxhom_default /home/schneider/public/maxhom.default
C a file "maxhom.default" in the current directory has higher priority
C METRIC_PATH    : location of exchange metrices
C SWISSPROT_SEQ  : location of swissprot files
C RELEASE_NOTES  : release notes of EMBL/SWISSPROT
C PDB_PATH       : location of Brookhaven files
C DSSP_PATH      : location of DSSP files
C COREPATH       : directory path for corefile
C COREFILE       : where to put the temporary binary file to store the
C                  alignments
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
c internal
      INTEGER       IBEG,IEND
      LOGICAL       LEXIST,LERROR
      CHARACTER*200  LINE
      CHARACTER*1   CDIVIDE
C     INIT
      LEXIST=.FALSE.
      METRICPATH=' ' 
      SWISSPROT_SEQ=' '
      SW_CURRENT=' '
      
      SPLIT_DB_NAMES=' '
C     SW_DATA=' ' ; SW_INDEX=' ' ; SW_PATH=' '
      
      RELNOTES=' ' 
      PDBPATH=' ' 
      DSSP_PATH=' '
      COREPATH=' ' 
      COREFILE=' ' 
      FILTER_FASTA_EXE=' '
      FASTA_EXE=' ' 
      FILTER_BLASTP_EXE=' '
      BLASTP_EXE=' '
      CONVERTSEQ_EXE=' ' 
      CDIVIDE=':'
C check existence of default file and open
      IF (MAXHOM_DEFAULT .EQ. ' ') THEN
         MAXHOM_DEFAULT= 'maxhom.default'
      ENDIF
      IF (MAXHOM_DEFAULT .NE. ' ') THEN
         INQUIRE(FILE=MAXHOM_DEFAULT,EXIST=LEXIST)
      ENDIF
      IF (LEXIST) THEN
         CALL STRPOS(MAXHOM_DEFAULT,IBEG,IEND)
         WRITE(6,*)' default file is: ',maxhom_default(ibeg:iend)
         CALL FLUSH_UNIT(6)
         LINE='OLD,READONLY'
         CALL OPEN_FILE(KDEF,MAXHOM_DEFAULT,LINE,LERROR)
      ELSE
         WRITE(6,*)' ERROR: can not find default file '
         WRITE(6,*)' Check enviroment variable MAXHOM_DEFAULT or '
         WRITE(6,*)' specify default file with option -d=filename '
         call flush_unit(6)
         STOP
      ENDIF
C read defaults
      DO WHILE(.TRUE.)
c         read(kdef,'(a)',end=999)line
         READ(KDEF,'(A)',END=999,ERR=999)LINE
c	  WRITE(6,*)line(1:40)
         IF (LINE(1:2) .EQ. '##') THEN 
            GOTO 999 
         ENDIF
         IF (LINE(1:1) .NE. '#' .AND. LINE .NE.' ') THEN
            CALL EXTRACT_STRING(LINE,CDIVIDE,'MACHINE',CMACHINE)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'COREPATH',COREPATH)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'COREFILE',COREFILE)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'METRIC_PATH',METRICPATH)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'SWISSPROT_SEQ',
     +           SWISSPROT_SEQ)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'SWISSPROT_CURRENT',
     +           SW_CURRENT)

            CALL EXTRACT_STRING(LINE,CDIVIDE,'SPLIT_DB',SPLIT_DB_NAMES)

c	  call extract_string(line,cdivide,'SWISSPROT_INDEX',sw_index)
c	  call extract_string(line,cdivide,'SWISSPROT_PATH',sw_path)
c	  call extract_string(line,cdivide,'SWISSPROT_DATA',sw_data)

            CALL EXTRACT_STRING(LINE,CDIVIDE,'RELEASE_NOTES',
     +           RELNOTES)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'PDB_PATH',PDBPATH)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'DSSP_PATH',DSSP_PATH)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'FILTER_FASTA_EXE',
     +           FILTER_FASTA_EXE)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'FASTA_EXE',FASTA_EXE)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'FILTER_BLASTP_EXE',
     +           FILTER_BLASTP_EXE)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'BLASTP_EXE',BLASTP_EXE)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'CONVERTSEQ_EXE',
     +           CONVERTSEQ_EXE)
	 ENDIF
      ENDDO
 999  CLOSE(KDEF)
      IF (INDEX(CMACHINE,'UNIX').NE.0) THEN
         CMACHINE='UNIX'
      ELSE IF (INDEX(CMACHINE,'VMS').NE.0) THEN   		
         CMACHINE='VMS'
      ELSE 
         WRITE(6,*)' *** MACHINE type UNKNOWN (assume UNIX) ***'
         CMACHINE='UNIX'
      ENDIF
      IF (COREFILE .EQ. ' ' ) THEN
         WRITE(6,*)' ERROR: COREFILE UNDEFINED'
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
         STOP
      ELSE IF (COREPATH .EQ. ' ' ) THEN
         WRITE(6,*)' WARNING: COREPATH UNDEFINED'
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (METRICPATH .EQ. ' ') THEN
         WRITE(6,*)' ERROR: METRIC_PATH undefined'
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
         STOP
      ELSE IF (SWISSPROT_SEQ .EQ. ' ') THEN
         WRITE(6,*)' WARNING:  SWISSPROT_SEQ undefined '
         WRITE(6,*)' no search against database possible  '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (SPLIT_DB_NAMES .EQ. ' ') THEN
         WRITE(6,*)' WARNING:  SPLIT_DB undefinned '
         WRITE(6,*)' no parallel search against database possible  '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
c	else if (sw_data .eq. ' ') then
c	  WRITE(6,*)' WARNING:  SW_DATA undefined '
c	  WRITE(6,*)' no search against database possible  '
c          WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
c	else if (sw_index .eq. ' ') then
c	  WRITE(6,*)' WARNING:  SW_INDEX undefined '
c	  WRITE(6,*)' no search against database possible  '
c          WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
c	else if (sw_path .eq. ' ') then
c	  WRITE(6,*)' WARNING:  SW_PATH undefined '
c	  WRITE(6,*)' no search against database possible  '
c          WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (SW_CURRENT .EQ. ' ') THEN
         WRITE(6,*)' WARNING:  SWISSPROT_CURRENT undefined '
         WRITE(6,*)' no search with blastp possible  '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (RELNOTES .EQ. ' ') THEN
         WRITE(6,*)' WARNING: RELEASE_NOTES undefined  '
         WRITE(6,*)' no information about database '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (PDBPATH .EQ. ' ') THEN
         WRITE(6,*)' WARNING: PDB_PATH undefined '
         WRITE(6,*)' no superposition in 3-D possible '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (DSSP_PATH .EQ. ' ') THEN
         WRITE(6,*)' WARNING: DSSP_PATH undefined '
         WRITE(6,*)' no check of pdb-pointers from SwissProt '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (FILTER_FASTA_EXE .EQ. ' ') THEN
         WRITE(6,*)' WARNING: FILTER_FASTA_EXE undefined   '
         WRITE(6,*)' no pre-filtered run against database '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (FASTA_EXE .EQ. ' ') THEN
         WRITE(6,*)' WARNING: FASTA_EXE undefined '
         WRITE(6,*)' no FASTA-pre-filtered run against database '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (FILTER_BLASTP_EXE .EQ. ' ') THEN
         WRITE(6,*)' WARNING: FILTER_BLASTP_EXE undefined   '
         WRITE(6,*)' no pre-filtered run against database '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (BLASTP_EXE .EQ. ' ') THEN
         WRITE(6,*)' WARNING: BLASTP_EXE undefined '
         WRITE(6,*)' no BLASTP-pre-filtered run against database '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ELSE IF (CONVERTSEQ_EXE .EQ. ' ') THEN
         WRITE(6,*)' WARNING: CONVERTSEQ_EXE undefined'
         WRITE(6,*)' at least no FASTA pre-filter possible '
         WRITE(6,*)' PLEASE CHECK MAXHOM.DEFAULT FILE '
      ENDIF
c	WRITE(6,*)' get_default end'
      RETURN
      END
C     END GET_DEFAULT
C......................................................................

C......................................................................
C     SUB GET_FASTA_DB_ENTRY
      SUBROUTINE GET_FASTA_DB_ENTRY(MAXSQ,KUNIT,NRES,NAME,COMPOUND,
     +     ACCESSION,PDBREF,SEQ,LEND)

      IMPLICIT        NONE
C import
      INTEGER         MAXSQ,KUNIT
C export
      CHARACTER*(*)   SEQ,NAME,COMPOUND,ACCESSION,PDBREF
      INTEGER         NRES
      LOGICAL         LEND
C internal 
      INTEGER         I,J,K,LINELEN
      PARAMETER      (LINELEN=                 500)
      CHARACTER       LINE*(LINELEN)
C======================================================================
      LEND=.FALSE.
      NRES=0
C=====================================================================

      READ(KUNIT,'(A)',END=900,ERR=999)LINE
      J=INDEX(LINE,'|')
      IF (J .GT. 0) THEN
         K=INDEX(LINE(J+1:),'|')
         IF (K .GT. 0) THEN
            I=INDEX(LINE,' ')
            NAME(1:)=LINE(2:I-1)
            COMPOUND(1:)=LINE(I+1:)
            LINE(J:J)=' '
            K=INDEX(LINE,'|')
            ACCESSION(1:)=LINE(J+1:K-1)
         ELSE
            J=INDEX(LINE,' ')
            NAME(1:)=LINE(2:J)
            COMPOUND(1:)=LINE(2:)
            ACCESSION(1:)=' '
            WRITE(6,*)'WARNING from get_fasta_db: '//
     +           'entry line looks strange (no |)'
            WRITE(6,*)LINE(1:60)
         ENDIF
      ELSE
         J=INDEX(LINE,' ')
         NAME(1:)=LINE(2:J)
         COMPOUND(1:)=LINE(2:)
         ACCESSION(1:)=' '
         WRITE(6,*)'WARNING from get_fasta_db: '//
     +        'entry line looks strange (no |)'
         WRITE(6,*)LINE(1:60)
      ENDIF
      SEQ=' '
c sequences starts in next line
 100  READ(KUNIT,'(A)',ERR=999,END=900) LINE    
      IF (LINE(1:1) .EQ. '>' .AND. NRES .NE. 0) THEN
         BACKSPACE(KUNIT)
      ELSE
         DO I=1,LINELEN
            IF ( LINE(I:I) .NE. ' ' ) THEN
               NRES=NRES+1
               IF (NRES .LE. MAXSQ ) THEN
                  SEQ(NRES:NRES)=LINE(I:I)
               ELSE   
c truncate if needed
                  WRITE(6,*)' SEQ CUT TO MAXSQ: ',MAXSQ
                  CALL FLUSH_UNIT(6)
                  NRES=MAXSQ
 200              READ(KUNIT,'(A)',ERR=999,END=900) LINE    
                  IF (LINE(1:1) .EQ. '>' ) THEN
                     BACKSPACE(KUNIT)
                     RETURN
                  ENDIF
                  GOTO 200
               ENDIF
            ENDIF
         ENDDO
         GOTO 100
      ENDIF
C======================================================================
 900  IF (NRES .EQ. 0)LEND=.TRUE.
      RETURN
 999  WRITE(6,*)' ERROR in get_fasta_db_entry ',name,nres
c	call flush_unit(6)
      STOP
      END
C     END GET_FASTA_DB_ENTRY
C......................................................................

C......................................................................
C     SUB GET_LDIREC
      SUBROUTINE GET_LDIREC(ND1,ND2,LH2,II,JJ,LDEL_DIREC)
      IMPLICIT NONE
      INTEGER ND1,ND2,II,JJ,LDEL_DIREC
      INTEGER*2 LH2(0:ND1,0:ND2)          
c	real lh(0:nd1,0:nd2,2)          

      LDEL_DIREC =ABS( LH2(II,JJ) )
c scratch once used trace
      LH2(II,JJ)=-1 

      RETURN
      END
C     END GET_LDIREC
C......................................................................

C......................................................................
C     SUB GET_LDIREC_FAST
      SUBROUTINE GET_LDIREC_FAST(ND1,ND2,LH2,II,JJ,LDEL_DIREC)
      IMPLICIT NONE
      INTEGER ND1,ND2,II,JJ,LDEL_DIREC
      INTEGER*2 LH2(0:ND1,0:ND2)          
c	real lh(0:nd1,0:nd2)          

      LDEL_DIREC =ABS( LH2(II,JJ) )
c scratch once used trace
      LH2(II,JJ)=-1 

      RETURN
      END
C END GET_LDIREC_FAST
C====================================================================== 
C  NOTE: ONLY TEMPRARY TO REDUCE MEMORY REQUIREMENTS FOR MAXHOM
C  MIXED ROUTINES FROM: 
C  SYSTEM-LIB 
C  UTILITY-LIB
C  PROTEIN-LIB
C     HSSP-LIB
C====================================================================== 

C......................................................................
C     SUB GET_SEQ
      SUBROUTINE GET_SEQ(KIN,FILENAME,TRANS,CHAINS,COMPND,ACCESSION,
     +     PDBREF,PDBNO,NRES,SEQ,STRUC,ACC,TRUNCATED,ERROR)

C	13.5.93
      IMPLICIT NONE 
C Import
      INTEGER KIN
      CHARACTER*(*) CHAINS
      CHARACTER*(*) TRANS, FILENAME, COMPND, ACCESSION, PDBREF
C Export
      INTEGER NRES
      INTEGER PDBNO(*), ACC(*)
      CHARACTER*(*) SEQ, STRUC
      LOGICAL TRUNCATED, ERROR
C Internal	
      INTEGER I,J, RLEN
      CHARACTER*20 FORMATNAME
      LOGICAL LACCZERO

C======================================================================
      ACCESSION=' '
      PDBREF=' '
      COMPND=' '
      TRUNCATED=.FALSE.

      CALL CHECKFORMAT(KIN,FILENAME,FORMATNAME,ERROR)

      IF ( ERROR ) THEN
         WRITE(6,*)'GET_SEQ: FILE OPEN ERROR, SET NRES=0 AND RETURN'
         WRITE(6,*)'FILENAME: ', FILENAME
         RETURN
      ENDIF
      CALL STRPOS(FILENAME,I,J)

C..initialize
      NRES   = 0                  
      PDBREF = ' '  
      DO I = 1,LEN(SEQ)
         SEQ(I:I)  = '-'
         STRUC(I:I)  = 'U'
         ACC(I) = 0
      ENDDO
      INQUIRE(KIN,RECL=RLEN)

      IF (FORMATNAME .EQ. 'BRK') THEN
         CALL READ_BRK(KIN,FILENAME,CHAINS,TRANS,RLEN,NRES,
     1        COMPND,SEQ,PDBNO,TRUNCATED,ERROR)
      ELSE IF (FORMATNAME .EQ. 'FASTA') THEN
         CALL READ_FASTA(KIN,FILENAME,TRANS,RLEN,NRES,ACCESSION,
     1        COMPND,SEQ,TRUNCATED,ERROR)
      ELSE IF (FORMATNAME .EQ. 'PIR') THEN
         CALL READ_PIR(KIN,FILENAME,TRANS,RLEN,NRES,ACCESSION,
     1        COMPND,SEQ,TRUNCATED,ERROR)
      ELSE IF (FORMATNAME .EQ. 'EMBL') THEN
         CALL READ_EMBL(KIN,FILENAME,TRANS,RLEN,NRES,
     1        COMPND,ACCESSION,PDBREF,SEQ,TRUNCATED,ERROR)
      ELSE IF (FORMATNAME .EQ. 'GCG') THEN
         CALL READ_GCG(KIN,FILENAME,TRANS,RLEN,NRES,
     1        COMPND,SEQ,TRUNCATED,ERROR)
      ELSE IF (FORMATNAME .EQ. 'STAR') THEN
         COMPND = ' ' 
         CALL READ_STAR(KIN,FILENAME,TRANS,RLEN,NRES,
     1        SEQ,TRUNCATED,ERROR)
      ELSE IF (FORMATNAME .EQ. 'DSSP') THEN
         CALL READ_SEQ_FROM_DSSP(KIN,FILENAME,CHAINS,TRANS,RLEN,
     1        SEQ,STRUC,ACC,PDBNO,COMPND,NRES,LACCZERO,TRUNCATED,ERROR)
         IF (LACCZERO) THEN
            WRITE(6,*)'***************************************'
            WRITE(6,*)'* WARNING: accessibility values are 0 *'
            WRITE(6,*)'***************************************'
         ENDIF

      ELSE IF (FORMATNAME .EQ. 'HSSP') THEN
         CALL READ_SEQ_FROM_HSSP(KIN,FILENAME,CHAINS,TRANS,RLEN,
     1        SEQ,STRUC,ACC,PDBNO,COMPND,NRES,LACCZERO,TRUNCATED,ERROR )
      ENDIF
      IF ( ERROR ) RETURN
      CALL STRPOS(FILENAME,I,J)
      WRITE(6,'(A,A10,A,A,A,I5)')'GET_SEQ: ',FORMATNAME,':',
     +     FILENAME(1:J),' ',NRES

      IF ( TRUNCATED ) THEN
         WRITE(6,*)'TRUNCATED TO   ',len(seq),nres,' RESIDUES'
         WRITE(6,*)'!!! INCREASE DIMENSION !!!'
         NRES=LEN(SEQ)
      ENDIF
      RETURN
      END
C     END GET_SEQ
C......................................................................

C......................................................................
C     SUB GET_SEQ_FROM_ALISEQ
      SUBROUTINE GET_SEQ_FROM_ALISEQ(ALISEQ,IFIR,ILAS,ALIPOINTER,
     1     ALILEN,ALINO,SEQUENCE,NRES,ERROR)
C 8.7.93
      IMPLICIT NONE
C Import
      INTEGER ALILEN, ALINO
      INTEGER IFIR(*),ILAS(*),ALIPOINTER(*)
      CHARACTER ALISEQ(*)
C     EXPORT
      INTEGER NRES
      CHARACTER*(*) SEQUENCE
      LOGICAL ERROR
C     INTERNAL
      INTEGER IPOS
      CHARACTER CGAPCHAR

      CGAPCHAR = '.'

      IF ( ALILEN .GT. LEN(SEQUENCE) ) THEN
         ERROR = .TRUE.
         WRITE(6,'(A)') 
     1        ' MAXRES overflow in get_seq_from_aliseq !'
         RETURN
      ENDIF
      NRES = 0
      DO WHILE ( NRES .LT. IFIR(ALINO)-1 )
         NRES = NRES + 1
         SEQUENCE(NRES:NRES) = CGAPCHAR
      ENDDO
      DO IPOS = ALIPOINTER(ALINO),
     1     ALIPOINTER(ALINO)+ILAS(ALINO)-IFIR(ALINO)
         NRES = NRES + 1
         SEQUENCE(NRES:NRES) = ALISEQ(IPOS)
      ENDDO
      DO WHILE ( NRES .LT. ALILEN )
         NRES = NRES + 1
         SEQUENCE(NRES:NRES) = CGAPCHAR
      ENDDO
      
      RETURN
      END
C     END GET_SEQ_FROM_ALISEQ
C......................................................................

C......................................................................
C     SUB GETALIGN
      SUBROUTINE GETALIGN(KFILE,IRECORD,IFIR,LEN1,LENOCC,JFIR,JLAS,
     +     IDEL,NDEL,VALUE,RMS,HOM,SIM,SDEV,DISTANCE,CHECKVAL) 
C GET ONE ALIGNMENT AS WRITTEN BY TRACE
C an alignment is:
C *  LDSSP_2 NAME_2 COMPOUND ACCESSION PDBREF VALUE  IFIR  LEN1  LENOCC
C
C  JFIR JLAS N2IN IDEL NDEL NSHIFTED RMS  HOM   SIM    DISTANCE
C
C  AL_2  [ SAL_2 (if ldssp_2 ]
C
C======================================================================
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
c input
      INTEGER   KFILE,IRECORD
      REAL      CHECKVAL
c output
C     CHARACTER AL_1*(*)
C     CHARACTER AL_2*(*),SAL_2*(*)
      INTEGER   IFIR,JFIR,JLAS,IDEL,NDEL,LEN1,LENOCC
      REAL      VALUE,SIM,SDEV,HOM,RMS,DISTANCE
C     INSERTIONS IN SEQ 2
C     INTEGER IINS,INSLEN_LOCAL(*),INSBEG_1_LOCAL(*),INSBEG_2_LOCAL(*)
C     CHARACTER INSSEQ*(*)
C     INTERNAL
      INTEGER   INSPOINTER_LOCAL
      CHARACTER LINE(4)*(MAXRECORDLEN)
      CHARACTER C*1
      INTEGER   K,IALIPOS,JALIPOS,IPOS,I,NLINE,IBEG,IEND
      REAL      XCHECK
C     INIT
C     AL_1= ' '
      C=          ' ' 
      LDSSP_2=    .FALSE. 
      NAME_2=     ' ' 
C     OMPND_2=' '
      ACCESSION_2=' ' 
      PDBREF_2=   ' ' 
      AL_2=       ' ' 
      SAL_2=      ' ' 
      LINE(1)=    ' '
      LINE(2)=    ' ' 
      LINE(3)=    ' ' 
      INSSEQ=     ' '
      IFIR=       0 
      LEN1=       0 
      LENOCC=     0 
      JFIR=       0 
      JLAS=       0 
      N2IN=       0 
      IDEL=       0
      NDEL=       0 
      NSHIFTED=   0 
      VALUE=      0.0 
      RMS=        0.0 
      HOM=        0.0 
      SIM=        0.0
      DISTANCE=   0.0 
      IINS=       0 
      INSLEN_LOCAL(1)=  0 
      INSBEG_1_LOCAL(1)=0
      INSBEG_2_LOCAL(1)=0 
      SDEV=       0.0
      LCONSIDER=  .TRUE.
      
      READ(KFILE,REC=IRECORD)C,LCONSIDER,VALUE
      IF (C .NE. '*') THEN
         WRITE(6,*)C,IRECORD
         WRITE(LOGSTRING,'(A)')
     +        '*** ERROR: INCORRECT RECORD BOUNDARY IN GETALIGN'
         CALL LOG_FILE(KLOG,LOGSTRING,1)
         STOP
      ENDIF
C     WRITE(6,*)LCONSIDER,VALUE ; CALL FLUSH_UNIT(6)
C---- --------------------------------------------------
C---- only for alignments to take!
C---- --------------------------------------------------
      IF (LCONSIDER) THEN
         IRECORD=IRECORD+1
         READ(KFILE,REC=IRECORD)NAME_2
         IRECORD=IRECORD+1
         READ(KFILE,REC=IRECORD)COMPND_2
         IRECORD=IRECORD+1
         READ(KFILE,REC=IRECORD)ACCESSION_2,PDBREF_2,LDSSP_2
         IRECORD=IRECORD+1
         READ(KFILE,REC=IRECORD)IFIR,LEN1,LENOCC,JFIR,JLAS,N2IN,
     +        IDEL,NDEL,NSHIFTED,RMS,HOM,SIM,SDEV,
     +        DISTANCE,IINS
         XCHECK=0.0
         IF (CSORTMODE .EQ. 'DISTANCE' ) THEN
            XCHECK = DISTANCE
         ELSE IF (CSORTMODE .EQ.'VALUE' .OR. CSORTMODE.EQ.'ZSCORE') THEN
	    XCHECK = VALUE
         ELSE IF (CSORTMODE .EQ. 'WSIM' ) THEN
	    XCHECK = SIM
         ELSE IF (CSORTMODE .EQ. 'SIM' ) THEN
	    XCHECK = SIM
         ELSE IF (CSORTMODE .EQ. 'SIGMA' ) THEN
	    XCHECK = VALUE / SDEV
         ELSE IF (CSORTMODE .EQ. 'IDENTITY' ) THEN
	    XCHECK = HOM
         ELSE IF (CSORTMODE .EQ. 'VALPER' ) THEN
	    XCHECK = VALUE/FLOAT(LENOCC)
         ELSE IF (CSORTMODE .EQ. 'VALFORM' ) THEN
	    XCHECK=VALUE*(LENOCC**(-0.56158))
         ENDIF
         IF (CSORTMODE .NE. 'ZSCORE' .AND. CSORTMODE .NE. 'NO' ) THEN
	    IF ( ABS (XCHECK-CHECKVAL) .GT. 0.01 ) THEN
               LOGSTRING=' '
               WRITE(LOGSTRING,'(A,F7.2,A,F7.2,A,A)')
     +              '** ERROR: XCHECK.NE.CHECKVAL ',XCHECK,' ',
     +              CHECKVAL,' ',CSORTMODE
               CALL LOG_FILE(KLOG,LOGSTRING,1)
               STOP
	    ENDIF
         ENDIF
C     
         IF (.NOT. LDSSP_2) THEN
	    DO K=1,LEN1 
               SAL_2(K:K)='U' 
            ENDDO
         ENDIF
         IALIPOS=1
         JALIPOS=MIN(LEN1,MAXRECORDLEN)
         DO  WHILE(IALIPOS .LE. LEN1)
            IRECORD=IRECORD+1 
            READ(KFILE,REC=IRECORD)LINE(2)
            IF (LDSSP_2) THEN
               IRECORD=IRECORD+1 
               READ(KFILE,REC=IRECORD)LINE(3)
               IRECORD=IRECORD+1 
               READ(KFILE,REC=IRECORD)LINE(4)
            ENDIF
            IPOS=1
            DO I=IALIPOS,JALIPOS
               AL_2(I:I)=LINE(2)(IPOS:IPOS)
               IF (LDSSP_2) THEN
                  SAL_2(I:I)=LINE(3)(IPOS:IPOS)
                  READ(LINE(4)(IPOS:IPOS),'(I1)')LACC_2(I)
               ENDIF
               IPOS=IPOS+1
            ENDDO
            IALIPOS=JALIPOS+1 
            JALIPOS=MIN(LEN1,JALIPOS+MAXRECORDLEN)
         ENDDO
C     READ INSERTIONS
         IF (IINS .GT. 0) THEN
	    INSPOINTER_LOCAL=1
	    DO I=1,IINS
	       IRECORD=IRECORD+1
	       READ(KFILE,REC=IRECORD)INSLEN_LOCAL(I),INSBEG_1_LOCAL(I),
     +              INSBEG_2_LOCAL(I)
	       INSPOINTER_LOCAL=INSPOINTER_LOCAL+INSLEN_LOCAL(I)+3
	    ENDDO
	    IF ( MOD(FLOAT(INSPOINTER_LOCAL),FLOAT(MAXRECORDLEN)) .EQ.
     +           0.0) THEN
               NLINE= INSPOINTER_LOCAL/MAXRECORDLEN
	    ELSE
               NLINE=(INSPOINTER_LOCAL/MAXRECORDLEN ) +1
	    ENDIF
	    IBEG=1 
            IEND=MAXRECORDLEN
	    DO  I=1,NLINE
               IRECORD=IRECORD+1
               READ(KFILE,REC=IRECORD)INSSEQ(IBEG:IEND)
               IBEG=IEND+1 
               IEND=IEND+MAXRECORDLEN
	    ENDDO
         ENDIF
      ENDIF
C     end of LCONSIDER
      RETURN
      END
C     END GETALIGN
C......................................................................

C......................................................................
***** ------------------------------------------------------------------
***** SUB GETARRAYINDEX
***** ------------------------------------------------------------------
C---- 
C---- NAME : GETARRAYINDEX
C---- ARG  : 1 CARRAY(1:NMAX) = array with strings
C---- ARG  : 2 CSTRING        = string to find in array
C---- ARG  : 3 NMAX           = maximal number of elements of carray
C---- ARG  : 4 INDEX          = index of element matching 
C---- DES  : Checks whether or not the string CSTRING equals 
C---- DES  : any of the strings in CARRAY.  
C---- DES  : if yes: returns the number of the array element matching
C---- DES  : if not: returns 0
C---- 
*----------------------------------------------------------------------*
      SUBROUTINE GETARRAYINDEX(CARRAY,CSTRING,NMAX,IINDEX)

      IMPLICIT      NONE

C does not contain CSTRING 
C Import
      INTEGER       NMAX
C---- br 99.03: watch hard_coded here, see maxhom.param
      CHARACTER*200 CARRAY(NMAX)
C----     -->   REASON: the following produces warnings on SGI
C      CHARACTER*(*) CARRAY(*)
C      CHARACTER*(*) CARRAY(NMAX)
      CHARACTER*(*) CSTRING
C internal
      INTEGER       IINDEX,i
      LOGICAL       LNOT
******------------------------------*-----------------------------******

C---- ini
      IINDEX= 1
      LNOT=   .TRUE.

C---- count up until ctest matches
      DO WHILE (LNOT)

C----    leave when at end of string
         IF (LNOT .AND. IINDEX.GT.NMAX)    LNOT=.FALSE.

C----    leave when match 
C----            hack br 99.03: SGI compiler crashes if IINDEX too high
C----                           (if in one if (not and carry=string)!)
         IF (LNOT) THEN
            IF (CARRAY(IINDEX).EQ.CSTRING) LNOT=.FALSE.
         ENDIF
C------- count up
         IF (LNOT)                         IINDEX=IINDEX+1
      ENDDO

C---- none found -> return 0
      IF (IINDEX .GT. NMAX ) IINDEX = 0

      RETURN
      END
C     END GETARRAYINDEX
C......................................................................

C......................................................................
C     SUB GETBEST
      SUBROUTINE GETBEST(IPOSBEG,IPOSEND,JPOSBEG,JPOSEND,NREGION,
     +     NTEST,LH1,LH2,ND1,ND2,BESTVAL,BESTIIPOS,BESTJJPOS)
C search the LH matrix for the best value, where the trace was not 
C used in a previous alignment 
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
c import
      INTEGER IPOSBEG,IPOSEND,JPOSBEG,JPOSEND,NREGION,NTEST
      INTEGER ND1,ND2
      REAL LH1(0:ND1,0:ND2)
      INTEGER*2 LH2(0:ND1,0:ND2)
      
C     REAL LH(0:ND1,0:ND2,*)
C     EXPORT
      INTEGER BESTIIPOS,BESTJJPOS
      REAL BESTVAL
C     INTERNAL
      INTEGER I,J,II,JJ,LDIREC
      LOGICAL LDONE_BEFORE
      REAL            BEST,BEST_II(0:MAXSQ+1)
      INTEGER         ITEMP,JTEMP,TEMP_II(0:MAXSQ+1),
     +                TEMP_JJ(0:MAXSQ+1)
*----------------------------------------------------------------------*
C     INIT
      BESTVAL=0.00000000 
      BESTIIPOS=0 
      BESTJJPOS=0 
C horizontal path             : ldirec=40000 ; ldel<=MAXSQ
C vertical path               : ldirec=30000 ; ldel<=MAXSQ
C diagonal match              : ldirec=20000 ; ldel=0
C unmatched terminal sequence : ldirec=10000 ; ldel=0
      IF (NTEST .LT. NREGION) THEN
C     GET BEST VALUE
         DO I=IPOSBEG,IPOSEND
            BEST_II(I)=0.0 
            TEMP_II(I)=0 
            TEMP_JJ(I)=0
         ENDDO
         DO J=JPOSEND,JPOSBEG,-1
            DO I=IPOSBEG,IPOSEND
               IF (LH1(I,J) .GT. BEST_II(I)+0.0001 ) THEN
                  BEST_II(I)= LH1(I,J)
                  TEMP_II(I) = I 
                  TEMP_JJ(I) = J
               ENDIF
            ENDDO
         ENDDO
         DO I=IPOSEND,IPOSBEG,-1
            IF (BEST_II(I) .GT. BESTVAL+0.0001) THEN
               BESTVAL=BEST_II(I)
               BESTIIPOS=TEMP_II(I) 
               BESTJJPOS=TEMP_JJ(I)
C     WRITE(6,*)BESTVAL,BEST_II(I),BESTIIPOS,BESTJJPOS
            ENDIF
         ENDDO
      ELSE
C     TRACE BACK TILL END FOR EACH NEW BEST VALUE
         DO J=JPOSEND,JPOSBEG,-1 
            DO I=IPOSEND,IPOSBEG,-1
               IF ( LH1(I,J) .GT. BESTVAL+0.0001 ) THEN
                  LDONE_BEFORE=.FALSE.
                  BEST=LH1(I,J) 
                  ITEMP=I 
                  JTEMP=J
                  II=I
                  JJ=J
                  DO WHILE ( .NOT. LDONE_BEFORE       .AND. 
     +                 LH2(II,JJ) .NE. 0 .AND.
     +                 II .GT. IPOSBEG .AND. JJ .GT. JPOSBEG)
                     LDIREC= ABS( LH2(II,JJ) )
                     IF (LDIREC .GT. 20000 ) THEN
                        II=II - ( LDIREC - 20000 )
                     ELSE IF (LDIREC .GT. 10000 ) THEN
                        JJ=JJ - ( LDIREC - 10000 )
                     ELSE IF (LH2(II,JJ) .EQ. -1) THEN
                        LDONE_BEFORE=.TRUE.
                     ELSE IF (LDIREC .EQ. 1) THEN
                        II=II-1
                        JJ=JJ-1
                     ELSE
                        WRITE(6,*)'GETBEST: LDIREC UNKNOWN: ',LDIREC
                     ENDIF
                  ENDDO
                  IF (.NOT. LDONE_BEFORE) THEN
                     BESTVAL=BEST 
                     BESTIIPOS=ITEMP 
                     BESTJJPOS=JTEMP
                  ENDIF
               ENDIF
            ENDDO
         ENDDO
      ENDIF
      RETURN
      END
C     END GETBEST
C......................................................................

C......................................................................
C     SUB GETCHAINBREAKS
      SUBROUTINE GETCHAINBREAKS(NRES,LSQ,STRUC,TRANS,NBREAK,IBREAKPOS)
C RS 89
C search for chain break(s) and store position(s) in array IBREAKPOS
C total number of breaks in protein are in NBREAK
C used to disallow alignments over chain breaks
C and to check pieces from DSSP and BRK if superpositon in 3-D wanted
C import
      INTEGER LSQ(*)
      CHARACTER TRANS*(*)
      
C     EXPORT
      INTEGER IBREAKPOS(*),NBREAK
      CHARACTER*(*) STRUC(*)
C     INTERNAL
      INTEGER ILEN
      
      ILEN=LEN(TRANS)
      NBREAK=0
      IBREAKPOS(1)=0
      IND=INDEX(TRANS(1:ILEN),'!')
      DO IRES=1,NRES
         IF (LSQ(IRES) .EQ. IND) THEN
            NBREAK=NBREAK+1
            IBREAKPOS(NBREAK)=IRES
            STRUC(IRES)='!'
C     WRITE(6,*)' CHAINBREAK : ',IRES
         ENDIF
      ENDDO
      RETURN
      END
C     END GETCHAINBREAKS
C......................................................................

C......................................................................
C     SUB GETCHAR
      SUBROUTINE GETCHAR(KCHAR,CHARARR,CTEXT)
C prompts for characters
      CHARACTER*(*) CTEXT,CHARARR
      CHARACTER*100 LINE
      INTEGER IMAX

      IMAX=LEN(CHARARR)
      WRITE(6,*)'================================================='//
     +     '=============================='
      CALL WRITELINES(CTEXT)	
 10   CONTINUE
      WRITE(6,*) 
      WRITE(6,'(a,i3,a)')'  Enter string of length < ',imax,
     +                       '  [CR=default]'
      WRITE(6,*)'   '
      CALL STRPOS(CHARARR,IBEG,IEND)
      IF (IBEG .GT. 0 .AND. IEND .GT. 0) THEN
         WRITE(6,'(a,a)')'  Default:  ',chararr(ibeg:iend)
      ELSE
         WRITE(6,'(a,a)')'  Default:  ',chararr
      ENDIF
      WRITE(6,*)' '
      LINE=' '
      READ(*,'(A)',ERR=10,END=11) LINE
      IF ( LINE .NE. ' ' ) THEN
C assuming default values were set outside ....
         CALL STRPOS(LINE,IBEG,IEND)
c	  do i=1,iend
c	     iascii=ichar(line(i:i))
c	     if (iascii .lt. 32 .or. iascii .gt. 126) then
c               WRITE(6,*)'*** Characters only, NOT: ',line(1:iend)
c               GOTO 10
c	     endif
c	  enddo
c	  iend=min(iend,imax)
         CHARARR(1:)=LINE(1:IEND)
      ENDIF
 11   WRITE(6,'(a,a)')'   echo: ',chararr(1:iend)
      RETURN
      END
C     END GETCHAR
C......................................................................

C......................................................................
C     SUB GETCONSWEIGHT
      SUBROUTINE GETCONSWEIGHT(NRES,IALIGN,LSEQ_1)
C conservation weights:
C fix weights between 1.0 and 0.1 
C where 0.0 means random distribution, because of moise its possible 
C that cons-weights have small negative values
C so cons-weights <0.1 are set to 0.1
C ISAFE is here +5 
C=======================================================================
      IMPLICIT      NONE
      INCLUDE       'maxhom.param'
      INCLUDE       'maxhom.common'
C import
      INTEGER       NRES,IALIGN,LSEQ_1(*)
C internal
      INTEGER       ISMALL,KFILE,ISAFERANGE,I,IRES,IALNEW,IDEL,NDEL,IAL,
     +              IFIR,JFIR,JLAS,LEN1,LENOCC,IBEG,IEND,IAGR,ILEN,JPOS,
     +              NPOS,IPOS,IRECORD,IND
      REAL          SEQDIST,CHECKVAL,RMS,VALUE,HOM,SIM,DISTANCE,SUM,
     +              MEAN,XVAL,SDEV
      CHARACTER*500 CONSEVOLUTION 
      LOGICAL       LEVOLUTION,LDUMMY,LERROR
C---- ------------------------------------------------------------------
C---- 
C---- defaults, ini
C---- 
C---- FORMULA+ISAFERANGE -> include into averaging
      ISAFERANGE= 5
C---- BR 99.0x: make 'safer' for weights
      ISAFERANGE= 5
      LDUMMY=     .TRUE.
      DO IRES=1,NRES 
         NOCC(IRES)=0 
      ENDDO

C---- 
C---- write cons-weights after each alignment (if lconsider=.true.) for 
C---- inspection of the conservation-weights evolution
      LEVOLUTION=.FALSE.
C      LEVOLUTION=.TRUE.
      IF (LEVOLUTION .AND. LFIRSTWEIGHT) THEN
         DO I=1,MAXSQ
            SUMDISTANCE(I)=   0.0 
            SUMVARIABILITY(I)=0.0
         ENDDO
         CALL CONCAT_STRINGS(HSSPID_1,'_EVOLUTION.DAT',CONSEVOLUTION)
         CALL OPEN_FILE(KCONS,CONSEVOLUTION,'NEW',LERROR)
         WRITE(6,*)' BACK OPEN'
         WRITE(KCONS,'(A,A)')'## ',NAME_1 
         WRITE(KCONS,'(A)')'## EVOLUTION OF CONSERVATION WEIGHTS'
         WRITE(KCONS,'(A)')'## IALIGN: Number of alignment above '//
     +	                    'threshold (list position )'
         WRITE(KCONS,'(A)')'## IRES: residue number (test-seq)'
         WRITE(KCONS,'(A)')'## WEIGHT: conservation weight'
         WRITE(KCONS,'(A)')'## I4,2X,I4,F7.2'
         WRITE(kcons,'(a)')'## IALIGN IRES WEIGHT '
         DO IRES=1,NRES
            WRITE(KCONS,'(I4,2X,I4,F7.2)')0,IRES,CONSWEIGHT_1(IRES)
         ENDDO
         LFIRSTWEIGHT=.FALSE.
      ENDIF

C---- 
C---- loop over new alis (depends on NBEST and/or no of chain breaks)
CAUTION kfile has to be open
CHANGE in future
      DO IALNEW=IALIGNOLD+1,IALIGN
	 IRECORD=IRECPOI(IALNEW)
	 IF (IRECORD .GT. 0 ) THEN
C     KFILE=KCORE -ISMALL + IFILEPOI(IALNEW)
            KFILE=KCORE 
            CHECKVAL=ALISORTKEY(IALNEW)
            CALL GETALIGN(KFILE,IRECORD,IFIR,LEN1,LENOCC,JFIR,JLAS,
     +           IDEL,NDEL,VALUE,RMS,HOM,
     +           SIM,SDEV,DISTANCE,CHECKVAL)
C LDUMMY (=LFORMULA) is true 
C use formula+ISAFERANGE percent for the calculation of cons-weight
            CALL CHECKHSSPCUT(LENOCC,HOM*100.0,ISOLEN,ISOIDE,NSTEP,
     +           LDUMMY,LALL,ISAFERANGE,LCONSIDER,DISTANCE)
            IABOVE(IALNEW)=0
C           BR 99.09: found a bug (this was missing)
            IF (.NOT. LCONSIDER) THEN
               AL_EXCLUDEFLAG(IALNEW)='*'
            ELSE
               IABOVE(IALNEW)=1
               IFIRST(IALNEW)=IFIR 
               ILAST(IALNEW)= IFIR+LEN1-1
C    FIRST CONVERT LOWER CASE CHARACTERS OF HSSP-ALIGNMENT TO UPPER CASE
C     AND CONVERT TO INTEGER
               IPOS=IFIR
               IF (ISEQPOS+LEN1+1 .LE. MAXSEQBUFFER) THEN
                  DO IRES=1,LEN1
                     IF (AL_2(IRES:IRES) .GE. 'A' .AND. 
     +                    AL_2(IRES:IRES) .LE. 'Z') THEN
                        SEQBUFFER(ISEQPOS+IRES-1)=
     +                       CHAR(ICHAR(AL_2(IRES:IRES))-32 )
                     ELSE
                        SEQBUFFER(ISEQPOS+IRES-1)=AL_2(IRES:IRES)
                     ENDIF
                     IND=TRANSPOS(ICHAR(AL_2(IRES:IRES)))
                     IF (IND .NE. 0) THEN 
                        LSEQ_2(IPOS)=IND
                     ELSE
                        LSEQ_2(IPOS)=0
C     WRITE(6,'(A)')'** UNKNOWN RESIDUE: '//AL_2(IRES:IRES)
                     ENDIF
                     IPOS=IPOS+1
                  ENDDO
                  ISEQPOINTER(IALNEW)=ISEQPOS 
                  ISEQPOS=ISEQPOS+LEN1+1
                  SEQBUFFER(ISEQPOS)='/'
               ELSE
                  WRITE(6,*)' ERROR: MAXSEQBUFFER OVERFLOW'
                  STOP
               ENDIF
C accumulate SUMVARIABILITY/SUMDISTANCE for the pair test-seq - new ali
               SEQDIST=1.0-HOM
               DO IRES=IFIRST(IALNEW),ILAST(IALNEW)
                  IF (LSEQ_1(IRES).NE.0 .AND. LSEQ_2(IRES).NE.0) THEN
                     SUMVARIABILITY(IRES)= 
     +                    SUMVARIABILITY(IRES) +
     +               (SEQDIST * SIMCONSERV(LSEQ_1(IRES),LSEQ_2(IRES)) )
                  ENDIF
                  SUMDISTANCE(IRES)=SUMDISTANCE(IRES) + SEQDIST
                  NOCC(IRES)=NOCC(IRES)+1
               ENDDO
C     IF PROFILES ARE USED, CONSERVATION WEIGHTS ARE CALCULATED FROM
C     the comparison between test sequence and aligned sequences (not 
C     between aligned seqs)	
               IF (.NOT. LPROFILE_1 .AND. .NOT. LPROFILE_2) THEN
                  DO IAL=1,IALIGNOLD
                     IF (IABOVE(IAL) .EQ. 1) THEN
C     DO THE 2 ALIGNMENTS OVERLAP ?
C----
C---- 98-10: br 
C----           correct bug
C----
Cold                        IF (IFIRST(IAL) .LT. IFIRST(IALNEW) .OR. 
Cold     +                       ILAST(IAL) .LT. ILAST(IALNEW)) THEN
Cold                           SEQDIST=0.0
                        IF (IFIRST(IAL) .LT.  ILAST(IALNEW) .OR. 
     +                       ILAST(IAL) .LT. IFIRST(IALNEW)) THEN
                           SEQDIST=0.0

                        ELSE
C     GET OVERLAP RANGE
                           IBEG=MAX(IFIRST(IAL),IFIRST(IALNEW))
                           IEND=MIN(ILAST(IAL),ILAST(IALNEW))
                           IRES=IBEG
                           DO JPOS=IBEG-IFIRST(IAL)+1,IEND-IFIRST(IAL)+1
                              IND=
     +             TRANSPOS(ICHAR(SEQBUFFER(ISEQPOINTER(IAL)+JPOS-1)))
                              IF (IND .NE. 0) THEN 
                                 LSEQTEMP(IRES)=IND
                              ELSE
                                 LSEQTEMP(IRES)=0
C     WRITE(6,'(A)')'* UNKNOWN RES:'//SEQBUFFER(ISEQPOINTER(IAL)+JPOS-1)
                              ENDIF
                              IRES=IRES+1
                           ENDDO
C     GET THE IDENTITIES AND LENGTH OF THE OVERLAPPING PART
                           IAGR=0 
                           ILEN=0
                           DO IRES=IBEG,IEND
                              IF (LSEQ_2(IRES).NE.0 .AND.
     +                             LSEQTEMP(IRES).NE.0) THEN 
                                 ILEN=ILEN+1
                                 IF (LSEQ_2(IRES) .EQ. 
     +                                LSEQTEMP(IRES))IAGR=IAGR+1
                              ENDIF
                              IBOTH_LEGAL(IRES)=0
                              IF (LSEQ_2(IRES).NE.0 .AND. 
     +                             LSEQTEMP(IRES).NE.0) THEN
                                 IBOTH_LEGAL(IRES)=1
                                 SIMVAL(IRES)=
     +                         SIMCONSERV(LSEQ_2(IRES),LSEQTEMP(IRES))
                              ENDIF
                           ENDDO
C   ACCUMULATE SUMVARIABILITY/SUMDISTANCE FOR THE PAIR NEW ALI - OLD ALI
                           IF (ILEN.NE.0) THEN
                              SEQDIST=1-(FLOAT(IAGR)/FLOAT(ILEN))
                              DO IRES=IBEG,IEND
                                 IF (IBOTH_LEGAL(IRES) .EQ. 1) THEN
                                    SUMVARIABILITY(IRES)=
     +                     SUMVARIABILITY(IRES)+(SEQDIST*SIMVAL(IRES))
                                    SUMDISTANCE(IRES)=
     +                                   SUMDISTANCE(IRES)+SEQDIST
                                 ENDIF
                              ENDDO
                           ENDIF
                        ENDIF
                     ENDIF
C     LOOP OVER OLD ALIS
                  ENDDO
C     .NOT. LPROFILE
               ENDIF
C     UPDATE WEIGHTS FOR OVERLAPPING RANGE BETWEEN TEST-SEQ AND NEW ALI
               DO IRES=IFIRST(IALNEW),ILAST(IALNEW)
                  IF (SUMDISTANCE(IRES).NE.0.0) THEN
                     CONSWEIGHT_1(IRES)=
     +                    (SUMVARIABILITY(IRES)/SUMDISTANCE(IRES))
C     NO NEGATIVE VALUES FOR CONS-WEIGHT 
                     IF (CONSWEIGHT_1(IRES).LT.CONSMIN) THEN
                        CONSWEIGHT_1(IRES)=CONSMIN
                     ENDIF
                  ENDIF
               ENDDO
C     WRITE CONSERVATION WEIGHTS TO FILE
               IF (LEVOLUTION) THEN
C     CALL CONCAT_STRINGS(HSSPID_1,'_EVOLUTION.DAT',
C     +                             CONSEVOLUTION)
C     CALL OPEN_FILE(KCONS,CONSEVOLUTION,'OLD,APPEND',LERROR)
                  WRITE(KCONS,'(A,A)')'## ',NAME_2(1:50)
                  DO IRES=1,NRES
                     WRITE(KCONS,'(I4,2X,I4,F7.2)')IALIGN,IRES,
     +                    CONSWEIGHT_1(IRES)
                  ENDDO
                  CLOSE(KCONS)
               ENDIF
C     
C     else: do NOT take (said CHECKHSSPCUT) -> updata flags!
C     
            ENDIF
C     LCONSIDER
	 ENDIF
C     LOOP OVER NEW ALIS
      ENDDO
      
 99   SUM=0.0 
      NPOS=0 
      MEAN=1.0
      DO I=1,NRES
         IF (NOCC(I).NE.0) THEN
            SUM=SUM+CONSWEIGHT_1(I) 
            NPOS=NPOS+1
         ENDIF
      ENDDO
      IF (NPOS .NE. 0) THEN 
         MEAN=SUM/NPOS 
      ENDIF
C     WRITE(6,*)'GETCONSWEIGHT: SUM,MEAN ',SUM,MEAN
      IF (MEAN.GT. 0.99 .AND. MEAN .LT. 1.01)RETURN
      XVAL=1.0-MEAN
      DO I=1,NRES
         IF (NOCC(I).NE.0) CONSWEIGHT_1(I)=CONSWEIGHT_1(I)+XVAL
      ENDDO
      GOTO 99
      END
C     END GETCONSWEIGHT
C......................................................................

C......................................................................
C     SUB GETCOORFORHSSP
      SUBROUTINE GETCOORFORHSSP(INFILE,INUNIT,CIDPROT,NRES,NATM,
     +     MXRES,MXATM,CIDRES,IPATMRES,RCA,CIDATM,IPRESATM,R)
C     AUTION HERE 'TER' LINES (CHAIN TERMINATORS) ARE COUNT AS RESIDUES
C     BECAUSE PIECES COME FROM DSSP-SEQUENCE (CHAIN BREAKS INCREMENT 
C     RESIDUE COUNTER) *RS 89
C     
C     GET-COOR-BROOK:SYMB.....CHRIS SANDER....MAY 1983...
C     FINAL DEFINITIVE PROTEIN DATA BANK COORDINATE INPUT 
C     ADAPTED FROM GCOOR OF SEGSEG, BUT WIHTOUT ADDED HYDROGENS AND
C     WITH ALTERED DATA STRUCTURE
C     FILE ATTRIBUTES
      CHARACTER*(*) INFILE
      INTEGER INUNIT
C     PROTEIN ATTRIBUTES
C     HEADER,COMPOUND,SOURCE,AUTHOR,RESOLUTION
      CHARACTER*(*) CIDPROT(*)
C     NUMBER OF RESIDUES, ATOMS  
      INTEGER NRES,NATM  
C     RESIDUE ATTRIBUTES
      CHARACTER*(*) CIDRES(*)
C     POINTS TO FIRST, LAST AND CA ATOM.
      INTEGER IPATMRES(3,*)
C     C(ALPHA) COORDINATES  
      REAL RCA(3,*)  
C     ATOM ATTRIBUTES
      CHARACTER*(*) CIDATM(MXATM)
C     ATOM BELONGS TO RESIDUE NUMBER IPRESATM
      INTEGER IPRESATM(*)  
      REAL R(3,*)
C     LOCAL STORAGE
      CHARACTER SEQ*3,LINE*200,ALT*1
      INTEGER NLIN
      LOGICAL OVERFLOW,LERROR
C     EXECUTE
      NRES=0
      NATM=0
      DO KI=1,5
         CIDPROT(KI)=' '
      ENDDO
      OVERFLOW=.FALSE.
      WRITE(6,*)'GETCOOR: OPEN ',infile(1:40)
      CALL OPEN_FILE(INUNIT,INFILE,'OLD,READONLY',LERROR)
      IF (LERROR) THEN
         WRITE(6,*)' OPEN FILE ERROR IN GETCOOR: ',infile(1:40)
         WRITE(6,*)' ....return with NRES=NATM=0 '
         RETURN
      ENDIF
C     LOOP OVER LINES
      IA=0
      IR=0
C     ATOM, RESIDUE AND LINE COUNTERS
      NLIN=0  
 10   READ(INUNIT,'(A)',END=999) LINE
      NLIN=NLIN+1
C     ATOMS
      IF (LINE(1:4) .EQ. 'ATOM') THEN  
         IA=IA+1
         IR=IR+1
         IF (IA .GT. MXATM) OVERFLOW=.TRUE.
         IF (IR .GT. MXRES) OVERFLOW=.TRUE.
         IF (OVERFLOW) THEN
	    IA=IA-1
	    IR=IR-1
	    WRITE(6,*)'***GETCOOR: CORE OVERFLOW FOR MXATM OR MXRES'
	    WRITE(6,*)'   MXATM,IA, MXRES,IR',MXATM,IA,MXRES,IR
	    WRITE(6,*)'   MOLECULE TRUNCATED'
	    GOTO 999
         ENDIF
C  MAIN INPUT
C  EXAMPLE FROM 3PTI:
C  REAL FIELDS:              111111112222222233333333
C  TOM    101  N   PRO    13      12.250  12.909  15.223  1.00  0.00      3PTI 160
C  TOM    102  CA  PRO    13      11.486  11.965  16.047  1.00  0.00      3PTI 161
C...  :....1....:....2....:....3....:....4....:....5....:....6....:....7....:....8
         CIDATM(IA)=LINE(13:16)
         ALT=LINE(17:17)
         SEQ=LINE(18:20)
         CIDRES(IR)=LINE(22:27)
         READ(LINE,'(30X,3F8.3)')(R(K,IA),K=1,3)
C     SKIP ALTERNATE ATOM POSITIONS
         IF ( ALT .NE. ' ' .AND. IA .NE. 1 .AND. 
     +        CIDATM(IA) .EQ. CIDATM(IA-1) ) THEN
	    WRITE(6,'(A,I5,1X,A4,A1,A3,1X,A6,3X,3F8.3)')
     +           'GETCOOR ALTERNATE ATOM IGNORED:  ',
     +           IA,CIDATM(IA),ALT,SEQ,CIDRES(IR),(R(K,IA),K=1,3)
	    IA=IA-1
	    IR=IR-1
	    GOTO 10
         ENDIF
calt ignore ace residue
         IF (SEQ .EQ. 'ACE' ) THEN
	    IA=IA-1
	    IR=IR-1
	    WRITE(6,*)'GETCOOR: ACE ignored at res ',ir
	    GOTO 10
         ENDIF
c set atom pointer
         IPATMRES(1,IR)=IA
         IF (IR .NE. 1) IPATMRES(2,IR-1)=IA-1
c is it a new residue ?
         IF (IR .NE. 1) THEN
	    IF ( CIDRES(IR-1) .EQ. CIDRES(IR) ) IR=IR-1
         ENDIF
c now valid ir and ia - stash away
         IPRESATM(IA)=IR  
         IF (CIDATM(IA) .EQ. ' CA ') THEN
	    IPATMRES(3,IR)=IA
	    DO K=1,3
	       RCA(K,IR)=R(K,IA)
	    ENDDO
         ENDIF
      ELSE IF (LINE(1:4) .NE. 'ATOM' ) THEN
         IF (LINE(1:4) .EQ. 'HEAD'.AND.CIDPROT(1).EQ.' ')CIDPROT(1)=LINE
         IF (LINE(1:4) .EQ. 'COMP'.AND.CIDPROT(2).EQ.' ')CIDPROT(2)=LINE
         IF (LINE(1:4) .EQ. 'SOUR'.AND.CIDPROT(3).EQ.' ')CIDPROT(3)=LINE
         IF (LINE(1:4) .EQ. 'AUTH'.AND.CIDPROT(4).EQ.' ')CIDPROT(4)=LINE
         IF ( INDEX(LINE,'RESOLUTION') .NE. 0 .AND. 
     +        CIDPROT(5).EQ.' ') THEN
            CIDPROT(5)=LINE
         ENDIF
         IF (LINE(1:3) .EQ. 'TER') THEN 
            IR=IR+1 
            SEQ='---' 
         ENDIF
      ENDIF
c next line           
      GOTO 10   
c end of file
 999  IR=IR-1
      NATM=IA
      NRES=IR
      IPATMRES(2,NRES)=NATM
      CLOSE(INUNIT)
      WRITE(6,*)'CLOSED: ',INFILE(1:40)
      WRITE(6,'(a,3(i5,a))')' exit getcoor:',nres,' residues',
     +                        natm,' atoms',nlin,' lines'
      RETURN
      END
C     END GETCOORFORHSSP
C......................................................................

C......................................................................
C     SUB GETDSSPFORHSSP
      SUBROUTINE GETDSSPFORHSSP(IN,FILE,MAXSQ,CHAINREMARK,PROT,
     +     HEAD,COMP,SOURCE,AUTHOR,NRES,LRES,NCHAIN,KCHAIN,PDBNO,
     +     PDBCHAINID,PDBSEQ,SECSTR,COLS,BP1,BP2,SHEETLABEL,ACC)

c reads header etc from files of type dssp. modified getdssp rs dez 88.
c reads dssp-data as line of length 38  (no h-bond-data)
      INTEGER         IN,MAXSQ
      CHARACTER*(*)   FILE,PROT,COMP,HEAD,SOURCE,AUTHOR,CHAINREMARK
      CHARACTER       PDBSEQ(*)
      CHARACTER*(*)   PDBCHAINID(*),SECSTR(*)
      CHARACTER*1     SHEETLABEL(*)
C     LENGHT*7
      CHARACTER*7     COLS(*)
      INTEGER         PDBNO(*),BP1(*),BP2(*),ACC(*)
C     INTERNAL
      PARAMETER      (MAXCHAIN=                100)
      CHARACTER       CHAINMODE*20,CHAINID(MAXCHAIN)
      CHARACTER       LINE*200,TEMPNAME*124
      LOGICAL         ERRFLAG,LKEEP,LCHAIN(MAXCHAIN)
*----------------------------------------------------------------------*
C     INIT
      NSELECT=1
      TEMPNAME=' '
      I=INDEX(CHAINREMARK,'_!_')
      IF (I.NE.0) THEN
         TEMPNAME(1:)=FILE(1:I-1)
      ELSE
         TEMPNAME(1:)=FILE(1:)
      ENDIF
      CALL OPEN_FILE(IN,TEMPNAME,'READONLY,OLD',ERRFLAG)
      IF (ERRFLAG)GOTO 999
C GET PROTEIN IDENTIFIER, HEADER AND COMPOUND etc
      DO LL=1,3
         READ(IN,'(A200)',END=777,ERR=999) LINE
      ENDDO
      PROT=LINE(63:66)
      PROT=LINE(63:66)
      HEAD=LINE(11:50)
      READ(IN,'(A200)',END=777,ERR=999)LINE
      COMP=LINE(11:)
      READ(IN,'(A200)',END=777,ERR=999)LINE
      SOURCE=LINE(11:)
      READ(IN,'(A200)',END=777,ERR=999)LINE
      AUTHOR=LINE(11:)
C...........FIND SEQUENCE.........
 70   READ(IN,'(A200)',END=777,ERR=999)LINE
      IF (INDEX(LINE(1:5),'#').EQ.0) GOTO 70
CD	WRITE(6,*)' # found sequence '
C............READ STRUCTURE.........
C...:....1....:....2....:....3....:...
C #  RESIDUE AA STRUCTURE BP1 BP2  ACC  
C  22   36 A S  E >   -I   24   0C  60  
C
      DO I=1,MAXCHAIN
         LCHAIN(I)=.TRUE.
      ENDDO
      I=INDEX(CHAINREMARK,'!')
C RS 90
C extract selected chains
C fx: $pdb:4hhb.dssp_!_1,2
C or: $pdb:4hhb.dssp_!_A
      IF (I.NE.0) THEN
         DO J=1,MAXCHAIN
            LCHAIN(J)=.FALSE.
         ENDDO
         NSELECT=1
         CALL STRPOS(CHAINREMARK,ISTART,ISTOP)
         DO J=ISTOP,I+1,-1
            IF (CHAINREMARK(J:J).EQ.',')NSELECT=NSELECT+1
         ENDDO
         CHAINMODE='CHARACTER'
c	   WRITE(6,*)' WILL READ CHAINS ACCORDING TO CHARACTER'

         ISTART=INDEX(CHAINREMARK,'!')+2
         DO J=1,NSELECT
            READ(CHAINREMARK(ISTART:),'(A1)')CHAINID(J)
            CALL LOWTOUP(CHAINID(J),1)
            ISTART=ISTART+2
         ENDDO
c	   WRITE(6,*)' GETDSSPFORHSSP: extract the chain(s)'
c	   DO J=1,NSELECT
c	        WRITE(6,*)' CHAIN: ',CHAINID(J)
c	   ENDDO
      ELSE
         CHAINMODE='NONE'
         IF (KCHAIN.NE.0) THEN
            WRITE(6,*)' will extract chain number: ',KCHAIN	
         ENDIF
         DO J=1,MAXCHAIN
            LCHAIN(J)=.TRUE.
         ENDDO
      ENDIF
      I=1
      NCHAIN=1
      NPICK=0
 80   READ(IN,'(A38)',END=777,ERR=999)LINE  
      LKEEP=.FALSE.
      IF (LINE(14:14).EQ.'!') THEN
         NCHAIN=NCHAIN+1 
      ELSE
         IF (KCHAIN.EQ.NCHAIN)LKEEP=.TRUE.
      ENDIF
C     KCHAIN=0 => all chains
      IF (KCHAIN.EQ.0)LKEEP=.TRUE.         
C if chains are identified by filename
      IF (CHAINMODE.EQ.'NUMBER') THEN
         IF (LCHAIN(NCHAIN)) THEN
C if the first chain wanted is not the first chain in DSSP-file, skip 
C the first position ('!')
            IF (NPICK.EQ.0) THEN
               IF (LINE(14:14).EQ.'!') THEN
                  LKEEP=.FALSE.
               ENDIF
            ELSE
               LKEEP=.TRUE.
            ENDIF
	    NPICK=1
         ELSE
	    LKEEP=.FALSE.
         ENDIF
      ELSE IF (CHAINMODE.EQ.'CHARACTER') THEN
         LKEEP=.FALSE.
         IF (LINE(14:14).EQ.'!') THEN
            IF (NPICK.EQ.0) THEN
               LKEEP=.FALSE.
            ELSE
               LKEEP=.TRUE.
	    ENDIF
         ELSE
	    CALL LOWTOUP(LINE(12:12),1)
            DO JCHAIN=1,NSELECT
               IF (CHAINID(JCHAIN).EQ. LINE(12:12)) THEN
                  LKEEP=.TRUE.
                  NPICK=1
	       ENDIF
            ENDDO
	    IF (.NOT. LKEEP .AND. I.GT.1) THEN
               IF (pdbseq(i-1).EQ.'!')I=I-1
            ENDIF
         ENDIF
      ENDIF
c pdbno,chainid,dsspseq,secstr,cols,bp1,bp2,sheetlabel,acc
      IF (LKEEP) THEN
         READ(LINE,'(6x,I4,1X,A1,1X,A1,2X,A1,1X,A7,I4,I4,A1,I4)',
     +        END=777,ERR=999)pdbno(i),pdbchainid(i),pdbseq(i),
     +        secstr(i),cols(i)(1:7),bp1(i),bp2(i),sheetlabel(i),
     +        acc(i)
         I=I+1 
         CALL CHECKRANGE (I,1,MAXSQ,'MAXSQ','GETDSSP   ')
      ENDIF
      GOTO 80             
C...............done.................. 
 777  NRES=I-1
c	WRITE(6,*) NRES,' RESIDUES READ IN GETDSSPFORHSSP '
      IF (NRES.LE.0) THEN 
         PROT=' '
         HEAD=' '
         COMP=' '
         SOURCE=' '
         AUTHOR=' ' 
      ENDIF
C.......DO NOT COUNT CHAIN BREAKS...
      LRES=NRES
      KCHAIN=1
      DO I=1,NRES
         IF (pdbseq(i).EQ.'!') THEN
            LRES=LRES-1
            KCHAIN=KCHAIN+1
         ENDIF
      ENDDO
c	WRITE(6,*) LRES,' RESIDUES ',NRES,' POSITIONS '
      CLOSE(IN)
      RETURN
 999  WRITE(6,*)' *** READ ERROR ***'
      NRES=0
      PROT=' '
      HEAD=' '
      COMP=' '
      SOURCE=' '
      AUTHOR=' ' 
      RETURN
      END
C     END GETDSSPFORHSSP
C......................................................................

C......................................................................
C     SUB GETHSSPCUT
      SUBROUTINE GETHSSPCUT(KIN,MAXSTEP,INFILE,ISOLEN,ISOIDE,NSTEP)
C RS 89
C read in isosignificance data from file
C
C.............................................................
C* isosignificance data / 70% secondary structure identity
C* a "*" indicates a comment line
C* alignments longer than the length specified in the last line
C* have the same cutoff 
C* format=(2X,I4,7X,F7.2)
C*.1234..... 1234567  
C* length   minimum % sequence identity        <===== start-line
C   10         67.41
C   20         50.22
C   ..           ..
C>  200         24.53
C.............................................................
      IMPLICIT NONE
      INTEGER MAXSTEP,KIN,I
      CHARACTER*(*) INFILE
      INTEGER ISOLEN(MAXSTEP),NSTEP
      REAL    ISOIDE(MAXSTEP)
      LOGICAL LERROR
      CHARACTER LINE*200
      
      CALL OPEN_FILE(KIN,INFILE,'READONLY,OLD',LERROR)
 10   READ(KIN,'(A)',ERR=999)LINE
      WRITE(6,*)LINE
      CALL LOWTOUP(LINE,200)
      IF (INDEX(LINE,'* LENGTH') .EQ. 0) GOTO 10
      
      I=1
 20   READ(KIN,'(2X,I4,7X,F7.2)',END=888)ISOLEN(I),ISOIDE(I)
      I=I+1
      IF (I .GT. MAXSTEP) THEN
         WRITE(6,*)' GETHSSPCUT: maxstep overflow: ',maxstep
      ENDIF
      GOTO 20
 888  NSTEP=I-1
      WRITE(6,*)' GETHSSPCUT: ',nstep,' steps '
cd	do i=1,nstep
cd	   WRITE(6,*)isolen(i),isoide(i)
cd	enddo
      CLOSE(KIN)
      RETURN
 999  WRITE(6,*)' GETHSSPCUT: ERROR READING ',INFILE
      CLOSE(KIN)
      STOP
      END
C     END GETHSSPCUT
C......................................................................

C......................................................................
C     SUB GETINT
      SUBROUTINE GETINT(KINT,INTARR,CTEXT)
C by  Chris Sander, June 1985, Feb 1986, June 1987, RS89
C For interactive use via terminal.
C Prompts for KINT integers from input unit *.
C Returns new values in INTARR(1..KINT)
C Offers previous values as default.
CUG   
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                  200)

      CHARACTER*(LINELEN) LINE
      CHARACTER*(*)   CTEXT	
      INTEGER         INTARR(*)
      LOGICAL         EMPTYSTRING
CUG
      INTEGER         NUMSTART	
      CHARACTER*20    CTEMP
*----------------------------------------------------------------------*

      WRITE(6,*)	
      WRITE(6,*)'===================================================='//
     +	        '==========================='
      CALL WRITELINES(CTEXT)	
      IF (KINT.LT.1.OR.KINT.GT.100) THEN
         WRITE(6,*)'*** INTPROMPT: KINT no good',KINT
         RETURN
      ENDIF
 10   WRITE(6,*)
      WRITE(6,'(2X,''Default: '',10I4)') (INTARR(K),K=1,KINT)
      IF (KINT.GT.1) THEN
         WRITE(6,'(2X,''Enter'',I3,'' integers [CR=default]: '')')KINT
      ELSE
         WRITE(6,'(2X,''Enter one integer  [CR=default]: '')')
      ENDIF
      LINE=' '
      READ(*,'(A200)',ERR=10,END=11) LINE
      IF (.NOT.EMPTYSTRING(LINE)) THEN
C remove comments ( 34535345 !$ comment )
         KCOMMENT=INDEX(LINE,'!$')
         IF (KCOMMENT.NE.0) LINE(KCOMMENT:linelen)=' '
C check for legal string
         DO I=1,linelen
            IF (INDEX(' ,+-0123456789',LINE(I:I)).EQ.0) THEN
               WRITE(6,'(2X,''*** not an integer: '',A40)') LINE(1:40)
               GOTO 10
            ENDIF
         ENDDO
         CALL STRPOS(LINE,ISTART,ISTOP)
         DO INUM = 1,KINT
            CALL GETTOKEN(LINE,LINELEN,INUM,NUMSTART,CTEMP)
            CALL RIGHTADJUST(CTEMP,1,20)
            READ(CTEMP,'(I20)') INTARR(INUM)
         ENDDO
      ENDIF
 11   WRITE(6,'(2X,'' echo:'',10I4)') (INTARR(K),K=1,KINT)
      RETURN
      END
C     END GETINT
C......................................................................

C......................................................................
C     SUB GETINDEX
      SUBROUTINE GETINDEX(CTEST,STRINGPOS,IPOS)
C get index of ctest in cstring
      INTEGER STRINGPOS(*),IPOS
      CHARACTER CTEST

      I=ICHAR(CTEST)
      IPOS=STRINGPOS(I)
c	if (ipos .eq. 0) then
c	  WRITE(6,*)' WARNING: UNKNOWN character: ',ctest
c	endif
      RETURN
      END
C     END GETINDEX
C......................................................................

C......................................................................
C     SUB GETPIDCODE
      SUBROUTINE GETPIDCODE(FILENAME,PID)
C extract protein ID from file name
      CHARACTER*(*) FILENAME, PID
      CHARACTER NAME*500,TEMPNAME*500	
C
      PID=' '
      TEMPNAME=' '

      CALL STRPOS(FILENAME,ISTART,IEND)
      IF (IEND .GT. LEN(TEMPNAME)) THEN
         WRITE(6,*)' ERROR in GETPIDCODE'
         WRITE(6,*)' tempname variable too short'
         STOP
      ENDIF

      TEMPNAME(1:IEND)=FILENAME(1:IEND)	
      CALL LOWTOUP(TEMPNAME,IEND)	
      NAME=FILENAME(ISTART:IEND)
C
      DO IR=IEND,1,-1
         IF (TEMPNAME(IR:IR) .EQ. '.') then
            IEND=IR-1
            GOTO 111
         ENDIF
      ENDDO
 111  TEMPNAME=' '
      DO IL=IEND,ISTART,-1
         IF ((NAME(IL:IL) .EQ. '/') .OR. (NAME(IL:IL) .EQ. ':') 
     +        .OR. (NAME(IL:IL) .EQ. ']') ) THEN
            ISTART=IL+1
            GOTO 222
         ENDIF
      ENDDO
 222  PID(1:)=FILENAME(ISTART:IEND)

c444	il=index(name(:ir),'.')
c	if (il .gt. 0) then
c	   name(il:il)='|'
c	   goto 444
c	else
c	   goto 555
c	endif

c 555	if (iend .gt. len(pid)) then
c	   WRITE(6,*)' ERROR in GETPIDCODE'
c	   WRITE(6,*)' pid variable too short'
c	   STOP
c	endif


c	PID=NAME(:IR)
      RETURN
      END
C     END GETPIDCODE
C......................................................................

C......................................................................
C     SUB GETPOS
      SUBROUTINE GETPOS(CSTRING,STRINGPOS,N)
C RS JAN 90
C store ASCII code of cstring in array stringpos
      INTEGER STRINGPOS(*),N
      CHARACTER*(*) CSTRING
      
      DO I=1,N
         STRINGPOS(I)=0
      ENDDO
      ILEN=LEN(CSTRING)
      DO I=1,ILEN
         J=ICHAR(CSTRING(I:I))
         STRINGPOS(J)=I
      ENDDO
      RETURN
      END
C     END GETPOS
C......................................................................

C......................................................................
C     SUB GETSEQ
      SUBROUTINE GETSEQ(IN,NDIM,NRES,CRESID,CSQ,STRUC,KACC,       
     +     LDSSP,FILENAME,COMPND,ACCESSION,CDUMMY,IOP,TRANS,NTRANS,
     +	   KCHAIN,NCHAIN,CCHAIN)
C RS 89 changed to read from PDB-file (used in MAXHOM)
C by Chris Sander, 1982 and later
C and Brigitte Altenberg, 1987 and later
C GET SEQUENCE FROM DSSP-FILE, HSSP SWISSPROT....OR FREE FORMAT FILE.
CAUTION: used by MAXHOM, PUZZLE, WINDOW-DNA (?), SEG-PRED (?) etc.
C
C     NDIM - MAX SPACE IN SEQUENCE ARRAY
C     NREAD - NUMBER OF RESIDUES READ
C     NRES  - NUMBER OF RESIDUES PASSED ON
C     IN   - LOGICAL UNIT NUMBER OF SEQ    FILE
C     IOP  - LOGICAL UNIT NUMBER OF OUTPUT FILE
C     KCHAIN - KCHAINTH CHAIN WANTED  (K=0 => ALL CHAINS,K<>0 => KTH 
C              CHAIN) BUT ONLY IF "_!_A,B" IS NOT SPECIFIED !!
C     NCHAIN - NUMBER OF CHAINS IN *.DSSP DATA-SET
C     CCHAIN - NAME OF CHAIN
C     LCHAIN() - true if 'x' chain wanted
	
      PARAMETER      (MAXCHAIN=                 40)
      PARAMETER      (MAXRECLEN=               200)
      CHARACTER       LOWER*26,PUNCTUATION*10,FORMATNAME*4
      CHARACTER       TRANS*26,CS*1,CC*1
      CHARACTER       LINE*(MAXRECLEN)
cx	character*200 FILENAME
      CHARACTER*(*)   FILENAME
C compound for DSSP
      CHARACTER*(*)   COMPND  
C accession number and dummy string (fx. pdb-pointer from swissprot)
      CHARACTER*(*)   ACCESSION,CDUMMY	
      
      CHARACTER*1     CSQ(*),STRUC(*),CH,CCHAIN
      CHARACTER*6     CRESID(*),CR
      LOGICAL         TRUNCATED,ERRFLAG,LKEEP,LCHAIN(MAXCHAIN)
      LOGICAL         LDSSP,LACCZERO,LHSSP
      INTEGER         KACC(*),KCHAIN
      INTEGER         IOP	
C     INTERNAL
      CHARACTER       CTEST*1,CHAINMODE*20,CHAINID(MAXCHAIN)*1
      LOGICAL         LCHAINBREAK,LEGALRES
      CHARACTER*100   CTEMP
C dont use INDEX command (CPU time)
      INTEGER         NASCII
      PARAMETER      (NASCII=                  256)
      INTEGER         TRANSPOS(NASCII)
C read from BRK
      CHARACTER       SEQ(10000)*3,CIDRES(10000)*6

C======================================================================
      IEND=0
      ISEQLEN=0
      ISTART=0
      ISTOP=0
      LOWER='abcdefghijklmnopqrstuvwxyz'                              
      LDSSP=.FALSE.
      LHSSP=.FALSE.
      IF (IOP.NE.0)WRITE(IOP,*)FILENAME                        
      CDUMMY=' '
      ACCESSION=' '	
      LINE=' '
CAUTION.. recommendation:
C calling program should allow "!" as legal residue for DSSP format
C *BA*
      IF (NTRANS.EQ.0) THEN
         WRITE(6,*)'GETSEQ: NTRANS was 0 !!!!'
         NTRANS=26
         TRANS='GAVLISTDENQKHRFYWCMPBZX!-.'
         WRITE(6,*)'GETSEQ: TRANS set to:', TRANS
      ENDIF
      IF (NTRANS.GT.26) THEN  
         WRITE(6,*)'trans:#',TRANS,'# ntrans:',NTRANS
         STOP'GETSEQ ERROR *** NTRANS.GT.26'
      ENDIF
      L=INDEX(TRANS(1:NTRANS),'-')   
      IF (L.EQ.0) THEN
         WRITE (*,*)'GETSEQ: WARNING: Trans must include"-" '
      ENDIF
      CALL GETPOS(TRANS,TRANSPOS,NASCII)
C *BA*BEGIN
      NRES=0                                                       
C......................defaults........
C in general, only blanks are allowed 
      PUNCTUATION='          '  
      DO I=1,NDIM
        KACC(I)=0
C implies that unknown residues are named -
        CSQ(I)='-'      
C undefined
        STRUC(I)='U'    
C *BA*END
      ENDDO
      COMPND=FILENAME
C read only the kth chain *BA*
C NAME OF CHAIN
      CCHAIN=' '
C CHAIN COUNTER
      NCHAIN=1                          
C RES LINE COUNTER
      NRESLINE=0                             
      NSELECT=0
      CALL strpos(FILENAME,i,LENFILNAM)                
      WRITE(6,*) 'GETSEQ: ', FILENAME(1:LENFILNAM)
      IF (LENFILNAM .LE. 1) THEN
        WRITE(6,*)'GETSEQ: *** empty file name, return with NRES=0'
        RETURN
      ENDIF
      I=INDEX(FILENAME,'_!_')
C RS 90
C extract selected chains
C fx: $pdb:4hhb.dssp_!_1,2
      IF (I.NE.0) THEN
         DO J=1,MAXCHAIN
            LCHAIN(J)=.FALSE.
         ENDDO
         NSELECT=1
         IEND=LEN(FILENAME)
         DO J=IEND,I+1,-1
            IF (FILENAME(J:J).EQ.',')NSELECT=NSELECT+1
         ENDDO
         ISTART=INDEX(FILENAME,'!_')+2
         READ(FILENAME(ISTART:ISTART),'(A1)')CTEST
         IF (INDEX('1234567890',CTEST).NE.0) THEN
            CHAINMODE='NUMBER'
            WRITE(6,*)' WILL READ CHAINS ACCORDING TO NUMBER'
         ELSE
            CHAINMODE='CHARACTER'
            WRITE(6,*)' WILL READ CHAINS ACCORDING TO CHARACTER'
         ENDIF

         DO J=1,NSELECT
            IF (CHAINMODE.EQ.'NUMBER') THEN
               CALL READ_INT_FROM_STRING(FILENAME(ISTART:),K)
               IF (K.GT.0 .AND. K.LE.MAXCHAIN) THEN
                  LCHAIN(K)=.TRUE.
               ELSE
                  WRITE(6,*)'*** ERROR: K<1 OR K>MAXCHAIN IN GETSEQ'
                  STOP
               ENDIF
            ELSE
               READ(FILENAME(ISTART:ISTART),'(A1)')CHAINID(J)
               CALL LOWTOUP(CHAINID(J),1)
            ENDIF
            ISTART=ISTART+2
         ENDDO
         WRITE(6,*)' **** GETSEQ: extract the chain(s)'
         IF (CHAINMODE.EQ.'NUMBER') THEN
            DO J=1,MAXCHAIN
               IF (LCHAIN(J))WRITE(6,*)' CHAIN: ',J
            ENDDO
         ELSE
            DO J=1,NSELECT
               WRITE(6,*)' CHAIN: ',CHAINID(J)
            ENDDO
         ENDIF
         ISTOP=INDEX(FILENAME,'_!')-1
         FILENAME=FILENAME(1:ISTOP)
      ELSE
         CHAINMODE='NONE'
         IF (KCHAIN.NE.0) THEN
            WRITE(6,*)' will extract chain number: ',KCHAIN	
         ENDIF
         DO J=1,MAXCHAIN
            LCHAIN(J)=.TRUE.
         ENDDO
      ENDIF
C *BA*BEGIN
      CALL CHECKFORMAT(IN,FILENAME,FORMATNAME,ERRFLAG)	           
c      WRITE(6,*) ' GETSEQ: format is  ',FORMATNAME 
      IF (INDEX(FORMATNAME,'DSSP').NE.0) THEN
         LDSSP=.TRUE.
      ENDIF
      IF (INDEX(FORMATNAME,'HSSP').NE.0) THEN
         LHSSP=.TRUE.
      ENDIF
      IF (ERRFLAG) THEN
         WRITE(6,*)'GETSEQ: file open error, set NRES=0 and return'
         WRITE(6,*)'filename: ', FILENAME
         RETURN
      ENDIF

      CTEMP=' '
      write(ctemp,'(a,i5)')'READONLY,OLD,RECL=',maxreclen
      CALL OPEN_FILE(IN,FILENAME,ctemp,ERRFLAG)
C *BA*END
      IF (FORMATNAME.EQ.'DSSP') GOTO 100                           
      IF (FORMATNAME.EQ.'BRK ') GOTO 200 
      IF (FORMATNAME.EQ.'PIR ') GOTO 300
      IF (FORMATNAME.EQ.'EMBL') GOTO 400               
      IF (FORMATNAME.EQ.'GCG ') GOTO 500                
      IF (FORMATNAME.EQ.'UWGC') GOTO 600 
      IF (FORMATNAME.EQ.'HSSP') GOTO 700 

C--------------NOT DSSP----NOT PIR----NOT EMBL--NOT GCG----------------
C--------------simple STAR FORMAT, probably

      DO WHILE(.TRUE.)
         READ(IN,'(A)',END=900) LINE
         IF (LINE(1:1).EQ.'*') THEN
            IF (IOP.NE.0)WRITE(IOP,*) LINE
C     NOT A COMMENT LINE
         ELSE
            CALL STRPOS(LINE,IBEG,IEND)
            DO J=1,IEND
               CS=LINE(J:J)
               CALL GETINDEX(CS,TRANSPOS,I)
C star format allows chainbreak 
               IF ( .NOT. LCHAINBREAK(CS,NRES+1) .AND. I.NE.0) THEN
                  NRES=NRES+1
                  IF (NRES.LE.NDIM) THEN
                     CSQ(NRES)=CS
                  ELSE
                     WRITE(IOP,'(A)')
     +                    '*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
                     WRITE(6,'(A)')
     +                    '*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
                  ENDIF
               ENDIF
C J, CHARACTERS IN LINE
            ENDDO
C COMMENT OR SEQUENCE LINE
         ENDIF
C NEXT LINE
      ENDDO
C-------------------------------READ FROM :DSSP-----------------
C ** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, \\
C    VERSION OCT. 1985
C FERENCE W. KABSCH AND C.SANDER, BIOPOLYMERS 22 (1983) 2577-2637
C ADER    PANCREATIC HORMONE                      16-JAN-81   1PPT
C MPND    AVIAN PANCREATIC POLYPEPTIDE
 100  READ(IN,'(A124)',END=199)LINE
      IF (INDEX(LINE,'SECONDARY').EQ.0) THEN
         WRITE(6,*)'***GETAASEQ ERROR: DSSP file assumed, but...'
         WRITE(6,*)' the word /SECONDARY/ is missing in first line'
         RETURN
      ENDIF
C reference - ignore
      READ(IN,'(A)',END=199)LINE  
C header
      READ(IN,'(A)',END=199)LINE  
C*      LINE='*'//LINE
      IF (IOP.NE.0)WRITE(IOP,*)LINE
C compnd
      READ(IN,'(A)',END=199)LINE  
C*      LINE='*'//LINE      
      IF (IOP.NE.0)WRITE(IOP,*)LINE
      COMPND=LINE(11:200)
C                     
C
C repeat until #  
 105  READ(IN,'(A)',END=199)LINE
      IF (INDEX(LINE(1:5),'#').EQ.0) GOTO 105
C
C23456123451c1cc1
Ccccccaaaaaacaccacccccccccccccccccciii
C   9    9 A S  E     -aB  35  15A   0   24,-2.3  27,-2.9  -2,-0.4  28,-0.5  -0.939  14.7-175.8-120.8 141.0   -5.5    9.8   13.0
C  21   21   Y  E     -AB  32  45A  68   24,-3.1  24,-2.9  -2,-0.3
C DSSP:     seqstr                 acc   hbonds
C
      NPICK=0 
      DO WHILE (.TRUE.)
         READ(IN,'(6X,A5,A1,1X,A1,2X,A1,18X,I3)',END=900) 
     +        CR(1:5),CH,CS,CC,IACC
C Res line counter. Note: NRES = # of res passed
         NRESLINE=NRESLINE+1   
         LKEEP=.FALSE.	
C       ......CONVERT SS-BRIDGES TO 'C'....
         IF (INDEX(LOWER,CS).NE.0) CS='C'
         IF (NRES.LT.NDIM) THEN
C incr.chains *BA*
            IF (LCHAINBREAK(CS,NRESLINE)) THEN
               NCHAIN=NCHAIN+1 
            ELSE
               IF (KCHAIN.EQ.NCHAIN)LKEEP=.TRUE.
            ENDIF
C KCHAIN=0 => all chains
            IF (KCHAIN.EQ.0)LKEEP=.TRUE.         
C if chains are identified by filename
            IF (CHAINMODE.EQ.'NUMBER') THEN
               IF (LCHAIN(NCHAIN)) THEN
C if the first chain wanted is not the first chain in DSSP-file, skip 
C the first position ('!')
                  IF (NPICK.EQ.0) THEN
                     IF (LCHAINBREAK(CS,NRESLINE)) THEN
                        LKEEP=.FALSE.
                     ENDIF
                  ELSE
                     LKEEP=.TRUE.
                  ENDIF
                  NPICK=1
               ELSE
                  LKEEP=.FALSE.
               ENDIF
            ELSE IF (CHAINMODE.EQ.'CHARACTER') THEN
               LKEEP=.FALSE.
               IF (LCHAINBREAK(CS,NRESLINE)) THEN
                  IF (NPICK.EQ.0) THEN
                     LKEEP=.FALSE.
                  ELSE
                     LKEEP=.TRUE.
                  ENDIF
               ELSE
                  CALL LOWTOUP(CH,1)
                  DO JCHAIN=1,NSELECT
                     IF (CHAINID(JCHAIN).EQ.CH) THEN
                        LKEEP=.TRUE.
                        NPICK=1
                     ENDIF
                  ENDDO
                  IF (.NOT.LKEEP) THEN
                     IF (CSQ(NRES).EQ.'!')NRES=NRES-1
                  ENDIF
               ENDIF
            ENDIF
C keep only the kth chain
            IF (LKEEP) THEN              
               CALL GETINDEX(CS,TRANSPOS,I)
               IF (I .NE. 0) THEN
CAUTION: change here (or in SEQTOINT) to L=0 implying chain break
C CAUTION: INCREMENT ONLY OF LEGAL AA OR - OR !
                  NRES=NRES+1  
                  CRESID(NRES)=CR(1:5)//CH
                  CSQ(NRES)=CS
                  KACC(NRES)=IACC
                  CCHAIN=CH
                  STRUC(NRES)=CC
c	WRITE(6,*)cchain
C ### ILLegal RESIDUES
               ENDIF
C CHAINS WANTED
            ENDIF
C DIMENSION OVERFLOW
         ELSE
            WRITE(IOP,'(A)')
     +           '*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
            WRITE(6,'(A,I)')
     +           '*** ERROR: DIMENSION OVERFLOW MAXSQ ***',
     +           MAXSQ
            GOTO 900
         ENDIF
C     NEXT LINE             
      ENDDO
C--------------DSSP read error -----------------------------------
 199  WRITE(6,*)'***GETAASEQ: incomplete DSSP file (EOF) '
      NRES=0
      NCHAIN=0
      CALL STRPOS(FILENAME,I,LENFILNAM)
      WRITE(6,*) 'FILE: ',FILENAME(1:LENFILNAM)
      CLOSE(IN)
      RETURN
C----------------READ FROM BROOKHAVEN--------------------------------

 200  READ(IN,'(A)',END=900,ERR=999)LINE
      IF (INDEX(LINE,'HEADER').EQ.0) THEN
         WRITE(6,*)'***GETAASEQ ERROR: BRK file assumed, but...'
         WRITE(6,*)' the word /HEADER/ is missing in first line'
         RETURN
      ENDIF
      IF (IOP.NE.0)WRITE(IOP,*)LINE(1:200)
C compnd
      READ(IN,'(A)',END=900,ERR=999)LINE  
      IF (IOP.NE.0)WRITE(IOP,*)LINE(1:200)
      COMPND=LINE(1:200)
C read only the kth chain                   
C NAME OF CHAIN
      CCHAIN=' '                        
C CHAIN COUNTER
      NCHAIN=1                          
C RES LINE COUNTER
      NRESLINE=0
      NRES=0                            
 210  READ(IN,'(A)',END=280,ERR=999)LINE	
      NRESLINE=NRESLINE+1
      IF (LINE(1:4).EQ.'ATOM') THEN
C if chains are identified by filename
         IF (CHAINMODE.EQ.'CHARACTER') THEN
            LKEEP=.FALSE.
            DO J=1,NSELECT
               IF (CHAINID(J).EQ.LINE(22:22))LKEEP=.TRUE.
            ENDDO
         ELSE
            LKEEP=.TRUE.
         ENDIF
         IF (LKEEP) THEN
            IF (NRES.LE.NDIM) THEN
               NRES=NRES+1
               SEQ(NRES)=LINE(18:20)
               CIDRES(NRES)=LINE(22:27)
               IF (SEQ(NRES).EQ.'ACE') THEN
                  NRES=NRES-1
                  WRITE(6,*)' GETAASEQ: ACE ignored at res ',NRES
                  GOTO 210
               ENDIF
               IF (NRES.NE.1) THEN
                  IF (CIDRES(NRES-1).EQ.CIDRES(NRES))NRES=NRES-1
               ENDIF
            ELSE
               WRITE(IOP,'(A,I)')
     +              '*** ERROR: DIMENSION OVERFLOW MAXSQ ***',
     +              MAXSQ
               WRITE(6,'(A,I)')
     +              '*** ERROR: DIMENSION OVERFLOW MAXSQ ***',
     +              MAXSQ
               GOTO 900
            ENDIF
         ENDIF
      ELSE IF (LINE(1:3).EQ.'TER') THEN
         IF (NRES.NE.0) THEN
            NRES=NRES+1
            SEQ(NRES)='!!!'
         ENDIF
      ENDIF
      GOTO 210
 280  CALL S3TOS1(SEQ,CSQ,NRES)
 290  IF (SEQ(NRES).NE.'!!!') THEN
         GOTO 900 
      ELSE
         SEQ(NRES)=' '
         CIDRES(NRES)=' '
         NRES=NRES-1
         GOTO 290
      ENDIF
C======    
C---------------------------READ FROM :PIR--------------------*BA*BEGIN
C
C
 300  CONTINUE
      PUNCTUATION=',.:;()+   '  
C Header line 1, ignore
      READ (IN,'(A)',END=999)LINE      
C     Header line 2, ignore
      READ (IN,'(A)',END=999)LINE      
c      IF (INDEX(LINE,'>').NE.0) THEN
C THERE are TWO SPECIAL LINES
c        READ (IN,'(A)',END=999)LINE   
c      ENDIF
      CALL STRPOS(LINE,IBEG,IEND)
      LINE(1:)='*'//LINE(IBEG:IEND)
C WRITE HEADER
      IF (IOP.NE.0) then
         WRITE(IOP,*)LINE(ibeg:iend)
      ENDIF
      DO WHILE(.TRUE.)                            
C IN THE NEXT LINES ARE RESIDUES
         READ (IN,'(A)',END=900)LINE
         CALL STRPOS(LINE,IBEG,IEND)
         DO J=1,IEND
            CS=LINE(J:J)                            
            IF (CS.EQ.'*') GOTO 900
            IF (LEGALRES(CS,NRES,TRANS,NTRANS,PUNCTUATION)) THEN   
               NRES=NRES+1
C CHECK FOR OVERFLOW
               IF (NRES.LE.NDIM) THEN             
                  CSQ(NRES)=CS
C OVERFLOW
               ELSE
                  WRITE(IOP,'(A)')
     +                 '*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
                  WRITE(6,'(A)')
     +                 '*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
                  GOTO 900
               ENDIF
C LEGAL RESIDUES                
            ENDIF
C NEXT RESIDUE
        ENDDO
C NEXT LINE
      ENDDO

C---------------------------READ FROM :EMBL ----------------------------

 400  CONTINUE
      ID=0
      DO WHILE (.TRUE.)                                        
         READ (IN,'(A)',END=999)LINE        
C LOOK FOR ACCESSION NUMBER AND TAKE THE FIRST ONE          
         IF (INDEX(LINE(:2),'AC').NE.0) THEN
	    I=INDEX(LINE,';')-1
            ACCESSION(1:)=LINE(6:I)
         ENDIF
C LOOK FOR DEFINITION            
         IF (INDEX(LINE(:2),'DE').NE.0) THEN
	    COMPND=' '
            COMPND(1:74)=LINE(6:79)
C WRITE ONLY DEFINITION
            IF (IOP.NE.0)WRITE (IOP,*)LINE            
            GOTO 410
         ENDIF
      ENDDO
 410  DO WHILE (.TRUE.)
C LOOK FOR LINE BEGINNING 
         READ (IN,'(A)',END=999)LINE         
C WITH "SQ"
         IF (INDEX(LINE(:2),'SQ').NE.0) THEN      
            GOTO 420
C*RS 89
C look for PDB-database pointer and store them in CDUMMY
 	 ELSE IF (INDEX(LINE(:2),'DR').NE.0 .AND. 
     +	         INDEX(LINE,'PDB;').NE.0) THEN    
            CALL STRPOS(CDUMMY,ISTART,ISTOP)
            CALL STRPOS(LINE,JSTART,JSTOP)
            IF (ISTOP+JSTOP+10 .LE. LEN(CDUMMY) ) THEN
	       IF (ID .LE. 0) THEN
                  CDUMMY(ISTOP+1:)=LINE(10:JSTOP)
               ELSE
                  CDUMMY(ISTOP+1:)='|'//LINE(10:JSTOP)
	       ENDIF
	       ID=ID+1
            ELSE
	       WRITE(6,*)'**** PDBREF-LINE DIMENSION OVERFLOW ***'
            ENDIF
	 ENDIF
      ENDDO
 420  CALL STRPOS(CDUMMY,ISTART,ISTOP)
      IF (ID .GT. 0) THEN
         IF ( (ISTOP+7) .LE. LEN(CDUMMY) ) THEN
	    WRITE(CDUMMY(ISTOP+1:),'(A,I4)')'||',ID
         ELSE
	    WRITE(6,*)'**** PDBREF-LINE DIMENSION OVERFLOW ***'
         ENDIF
      ENDIF
      DO WHILE (.TRUE.)
C SEQUENCES NEXT LINE
         READ (IN,'(A)',ERR=999,END=900) LINE    
C     END OF ROUTINE
         IF (INDEX(LINE(:2),'//').NE.0) GOTO 900     
C NO MORE TEXT ALLOWED
         IF (INDEX(LINE(:2),'  ').NE.0) THEN         
            CALL STRPOS(LINE,IBEG,IEND)
            DO J=1,iend
               CS=LINE (J:J)
               CALL GETINDEX(CS,TRANSPOS,I)
               IF (I .NE. 0) THEN     
                  NRES=NRES+1                      
C CHECK FOR OVERFLOW
                  IF (NRES.LE.NDIM) THEN             
                     CSQ(NRES)=CS
C OVERFLOW
                  ELSE
                     WRITE(IOP,'(A)')
     +                    '*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
                     WRITE(6,'(A,I)')
     +                    '*** ERROR: DIMENSION OVERFLOW MAXSQ=',
     +                    MAXSQ
                     GOTO 900
                  ENDIF
C     LEGAL RESIDUES
               ENDIF
C NEXT RESIDUE
            ENDDO
C NO TEXT BETWEEN THE LINES
         ENDIF
C NEXT LINE                           
      ENDDO

C------------------------END EMBL-READING------------------------------

C------------------------READ FROM:GCG-FORMAT--------------------------

Cold500      DO WHILE (.TRUE.)                                        
Cold          READ (IN,'(A124)',END=999)LINE        
Cold          IF (INDEX(LINE(:2),'ID').NE.0) THEN     
Cold           IF (IOP.NE.0)WRITE (IOP,*)LINE
Cold           GOTO 510
Cold          ENDIF
Cold        ENDDO

 500  DO WHILE (.TRUE.)
C GET SEQUENCE WHILE       
         READ (IN,'(A)',END=999)LINE               
         IF (IOP.NE.0)WRITE (IOP,*)LINE
         IF (INDEX(LINE,'..').NE.0)GOTO 520
      ENDDO
 520  DO WHILE (.TRUE.)
C GET THE SEQUENCES
         READ (IN,'(A)',ERR=999,END=900)LINE       
         CALL STRPOS(LINE,IBEG,IEND)
         DO J=1,IEND
            CS=LINE (J:J)
C CHECK FOR LEGAL RESIDUES
	    CALL GETINDEX(CS,TRANSPOS,I)
            IF (I .NE.0) THEN  
               NRES=NRES+1
C CHECK FOR OVERFLOW
               IF (NRES.LE.NDIM) THEN                      
                  CSQ(NRES)=CS
               ELSE
                  WRITE(IOP,'(A)')
     +                 '*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
                  WRITE(6,'(A,I)')
     +                 '*** ERROR: DIMENSION OVERFLOW MAXSQ=',
     +                 MAXSQ
                  GOTO 900
               ENDIF
C LEGAL RESIDUE                                      
            ENDIF
C NEXT RESIDUE
         ENDDO
C NEXT LINE
      ENDDO
                                                   
C---------------------------READ FROM :UWGCG------------------*BA*BEGIN

C HEADER                         
 600  READ (IN,'(A)',END=999)LINE      
      IF (INDEX(LINE,'Check').EQ.0) THEN
C THERE IS AN EMPTY LINE
         READ (IN,'(A)',END=999)LINE    
      ENDIF
      LINE='*'//LINE(1:len(line)-1)
C WRITE HEADER
      IF (IOP.NE.0)WRITE(IOP,*)LINE                    

      DO WHILE (.TRUE.)
C GET SEQUENCE WHILE       
         READ (IN,'(A)',END=999)LINE               
C LOOKING FOR A LINE
         IF (INDEX(LINE(3:50),'Length').NE.0) THEN      
C WITH 'LENGHT'AND'CHECK'
            IF (INDEX(LINE(50:124),'Check').NE.0)GOTO 610
         ENDIF
      ENDDO
 610  DO WHILE(.TRUE.)                            
C EMPTY LINE
         READ (IN,'(A)',END=900,ERR=999)LINE      
         READ (IN,'(A)',END=900,ERR=999)LINE
         CALL STRPOS(LINE,IBEG,IEND)
         DO J=9,iend
            CS=LINE(J:J)                            
            IF (CS.EQ.'*') GOTO 900
C CHECK FOR LEGAL RESIDUES   
	    CALL GETINDEX(CS,TRANSPOS,I)
            IF (I .NE. 0) THEN 
               NRES=NRES+1
C CHECK FOR OVERFLOW
               IF (NRES.LE.NDIM) THEN             
                  CSQ(NRES)=CS
C OVERFLOW
               ELSE
                  WRITE(IOP,'(A,I)')
     +                 '*** ERROR: DIMENSION OVERFLOW MAXSQ=',
     +                 MAXSQ
                  WRITE(6,'(A,I)')
     +                 '*** ERROR: DIMENSION OVERFLOW MAXSQ=',
     +                 MAXSQ
                  GOTO 900
               ENDIF
C LEGAL RESIDUES                
            ENDIF
C NEXT RESIDUE
         ENDDO
C NEXT LINE
      ENDDO
C
C---------------------------READ FROM :HSSP----------------------------
 700  READ(IN,'(A)',END=199)LINE
      IF (INDEX(LINE,'HOMOLOGY').EQ.0) THEN
         WRITE(6,*)'***GETAASEQ ERROR: HSSP file assumed, but...'
         WRITE(6,*)' the word /HOMOLOGY/ is missing in first line'
         RETURN
      ENDIF
      DO WHILE(INDEX(LINE,'NOTATION ').EQ.0)	
         READ(IN,'(A)',END=199)LINE
         IF (INDEX(LINE,'HEADER').NE.0) THEN
            IF (IOP.NE.0)WRITE(IOP,*)LINE(12:)
         ELSE IF (INDEX(LINE,'COMPND').NE.0) THEN
            IF (IOP.NE.0)WRITE(IOP,*)LINE
            COMPND=LINE(12:200)
         ELSE IF (INDEX(LINE,'SEQLENGTH ').NE.0) THEN
            call read_int_from_string(LINE(12:),iseqlen)
         ENDIF
      ENDDO
      DO WHILE(INDEX(LINE,'## ALIGNMENTS').EQ.0)
         READ(IN,'(A)',END=199)LINE
      ENDDO
      READ(IN,'(A)',END=199)LINE
      NPICK=0 

      DO IRES=1,ISEQLEN
         READ(IN,'(7X,A5,A1,1X,A1,2X,A1,18X,I3)',END=799) 
     +        CR(1:5),CH,CS,CC,IACC
C Res line counter. Note: NRES = # of res passed
         NRESLINE=NRESLINE+1   
         LKEEP=.FALSE.	
C CONVERT SS-BRIDGES TO 'C'....
         IF (INDEX(LOWER,CS).NE.0) CS='C'
         IF (NRES.LT.NDIM) THEN
C incr.chains
            IF (LCHAINBREAK(CS,NRESLINE)) THEN
	       NCHAIN=NCHAIN+1 
            ELSE
	       IF (KCHAIN.EQ.NCHAIN)LKEEP=.TRUE.
            ENDIF
C KCHAIN=0 => all chains
            IF (KCHAIN.EQ.0)LKEEP=.TRUE.
C if chains are identified by filename
            IF (CHAINMODE.EQ.'NUMBER') THEN
	       IF (LCHAIN(NCHAIN)) THEN
C if the first chain wanted is not the first chain in DSSP-file, skip 
C the first position ('!')
                  IF (NPICK.EQ.0) THEN
                     IF (LCHAINBREAK(CS,NRESLINE)) THEN
                        LKEEP=.FALSE.
                     ENDIF
                  ELSE
                     LKEEP=.TRUE.
                  ENDIF
                  NPICK=1
	       ELSE
                  LKEEP=.FALSE.
	       ENDIF
            ELSE IF (CHAINMODE.EQ.'CHARACTER') THEN
	       LKEEP=.FALSE.
               IF (LCHAINBREAK(CS,NRESLINE)) THEN
                  IF (NPICK.EQ.0) THEN
                     LKEEP=.FALSE.
                  ELSE
                     LKEEP=.TRUE.
                  ENDIF
               ELSE
                  CALL LOWTOUP(CH,1)
                  DO JCHAIN=1,NSELECT
                     IF (CHAINID(JCHAIN).EQ.CH) THEN
                        LKEEP=.TRUE.
                        NPICK=1
                     ENDIF
                  ENDDO
                  IF (.NOT.LKEEP) THEN
                     IF (CSQ(NRES).EQ.'!')NRES=NRES-1
                  ENDIF
               ENDIF
            ENDIF
C keep only the kth chain
            IF (LKEEP) THEN
C CHECK FOR LEGAL RESIDUES   
	     CALL GETINDEX(CS,TRANSPOS,I)
	     IF (I .NE. 0) THEN
CAUTION: INCREMENT ONLY OF LEGAL AA OR - OR !
                NRES=NRES+1  
                CRESID(NRES)=CR(1:5)//CH
                CSQ(NRES)=CS
                KACC(NRES)=IACC
                CCHAIN=CH
                STRUC(NRES)=CC
C ILLegal RESIDUES OR LEGAL PUNCTATION
	     ENDIF
C CHAINS WANTED
          ENDIF
C DIMENSION OVERFLOW
       ELSE
          WRITE(IOP,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
          WRITE(6,'(A,I)')
     +         '*** ERROR: DIMENSION OVERFLOW MAXSQ=',MAXSQ
          GOTO 900
       ENDIF
C NEXT LINE             
      ENDDO
      IF (NRESLINE .EQ. ISEQLEN)GOTO 900
C--------------HSSP read error -----------------------------------
 799  WRITE(6,*)'***GETSEQ: incomplete HSSP file '
      NRES=0
      NCHAIN=0
      CALL STRPOS(FILENAME,I,LENFILNAM)
      WRITE(6,*) 'FILE: ',FILENAME(1:LENFILNAM)
      CLOSE(IN)
      RETURN
C----------------------READ FILE ERROR---------------------------------
 999  WRITE (*,*)'****GETSEQ:INCOMPLETE FILE ',FILENAME(1:LENFILNAM)
      NRES=0
      CLOSE (IN)
      RETURN
C--------------------------------------------------------------*BA*END

C---all formats: -----------FINISHED READING-----------------------
 900  CLOSE(IN)
      IF (LDSSP .OR. LHSSP) THEN
         LACCZERO=.TRUE.
         DO I=1,NRES
            IF (KACC(I).NE.0) THEN
               LACCZERO=.FALSE.
               GOTO 910
	    ENDIF
         ENDDO
 910     IF (LACCZERO) THEN
            WRITE(6,*)'*******************************************'
            WRITE(6,*)'* WARNING: all accessibility values are 0 *'
            WRITE(6,*)'*******************************************'
            IF (IOP.NE.0) THEN
               WRITE(IOP,'(A)')'***************************************'
               WRITE(IOP,'(A)')'* WARNING: accessibility values are 0 *'
               WRITE(IOP,'(A)')'***************************************'
            ENDIF
	 ENDIF
      ENDIF
C TRUNCATE IF NEEDED
      TRUNCATED=(NRES.GE.NDIM)
      NREAD=NRES
      NRES=MIN(NDIM,NRES)
      IF (TRUNCATED) THEN
         WRITE(6,*)'TRUNCATED TO   ',NDIM,' RESIDUES'
         WRITE(6,*)'****  INCREASE DIMENSION ****'
      ENDIF
      
C PRINT SEQ AND STRUC
      IF (IOP.NE.0) then
          WRITE(IOP,*)'LENGTH ',NRES
	  IF (TRUNCATED)WRITE(IOP,*)'**** TRUNCATED FROM ',NREAD
C some machines have problems with list directed I/O !! RS 94
c	  DO N=0,NRES/100
c            N1=1+N*100
c            N2=min(nres,100+N*100)
c            WRITE(IOP,*)(CSQ(I),I=N1,N2)
c            IF (LDSSP)WRITE(IOP,*)(STRUC(I),I=N1,N2)
c	  ENDDO
c	  WRITE(IOP,*)' '
       ENDIF
       RETURN
       END
C     END GETSEQ 
C......................................................................

C......................................................................
C     SUB GETSEQPROF
      SUBROUTINE GETSEQPROF(CSEQ,TRANS,IRES,NOCC,SEQPROF,MAXRES,MAXAA)
C RS 89
C counts frequencies of amino acids 
C 'B' and 'Z' are assigned as well to the acid as to the amide form
C with respect to their occurence in EMBL/SWISSPROT 13.0
      IMPLICIT NONE
      INTEGER IRES,MAXRES,MAXAA
      CHARACTER*(*) TRANS,CSEQ
      INTEGER NOCC(*)
      INTEGER SEQPROF(MAXRES,MAXAA)
      REAL BTOD,BTON,ZTOE,ZTOQ
C     
      INTEGER I,J
C================
      BTOD=0.521
      BTON=0.439
      ZTOE=0.623
      ZTOQ=0.41
C lower case character
      CALL LOWTOUP(CSEQ,1)             
      IF (INDEX('BZ',CSEQ).EQ.0) THEN
         I=INDEX(TRANS(1:MAXAA),CSEQ)
         IF (I.EQ.0 .OR. I .GT. MAXAA) THEN
            WRITE(6,*)' GETSEQPROF: unknown residue symbol: ',cseq
            RETURN 
         ELSE
            SEQPROF(IRES,I)=SEQPROF(IRES,I)+1
            NOCC(IRES)=NOCC(IRES)+1
         ENDIF
      ELSE IF (CSEQ.EQ.'B') THEN
CD          WRITE(6,*)' GETSEQPROF: convert B'
         I=INDEX(TRANS,'D')
         J=INDEX(TRANS,'N')
         SEQPROF(IRES,I)=NINT( SEQPROF(IRES,I)+BTOD)
         SEQPROF(IRES,J)=NINT( SEQPROF(IRES,J)+BTON)
         NOCC(IRES)=NOCC(IRES)+1
      ELSE IF (CSEQ.EQ.'Z') THEN
CD          WRITE(6,*)' GETSEQPROF: convert Z'
         I=INDEX(TRANS,'E')
         J=INDEX(TRANS,'Q')
         SEQPROF(IRES,I)=NINT(SEQPROF(IRES,I)+ZTOE)
         SEQPROF(IRES,J)=NINT(SEQPROF(IRES,J)+ZTOQ)
         NOCC(IRES)=NOCC(IRES)+1
      ENDIF
      RETURN
      END
C     END GETSEQPROF
C......................................................................

C......................................................................
C     SUB GETSIMMETRIC
      SUBROUTINE GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,NIOSTATES_2,
     +     CSTRSTATES,CIOSTATES,
     +     IORANGE,KSIM,SIMFILE,SIMMETRIC)
      
      IMPLICIT NONE
C import
      INTEGER NTRANS
      CHARACTER*(*) TRANS
      INTEGER MAXSTRSTATES,MAXIOSTATES
      INTEGER KSIM
      CHARACTER*(*) SIMFILE
c export 
      INTEGER NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,NIOSTATES_2
      REAL IORANGE(MAXSTRSTATES,MAXIOSTATES)
      CHARACTER*(*) CSTRSTATES,CIOSTATES
      REAL SIMMETRIC(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +     MAXSTRSTATES,MAXIOSTATES)
c internal
      INTEGER I,J,K,L,I1,I2,J1,J2,ITRANS,IBEG,IEND
      INTEGER NSTR,NIO,ISTR1,IO1,ISTR2,IO2
      INTEGER MATRIXPOS
      CHARACTER CSTR,CIO,LINE*250
      CHARACTER*250 TESTSTRING
      CHARACTER*30 CTRANS
      LOGICAL LERROR
C======================================================================
C init
C======================================================================
      MATRIXPOS=22
      I= (NTRANS * NTRANS) * (MAXSTRSTATES * MAXSTRSTATES) * 
     +     (MAXIOSTATES * MAXIOSTATES)
      CALL INIT_REAL_ARRAY(1,I,SIMMETRIC,0.0)
C accessibility cut to 200% = take all
      I= MAXSTRSTATES * MAXIOSTATES 
      CALL INIT_REAL_ARRAY(1,I,IORANGE,200.0)
      TESTSTRING=' '
      LINE=' '
      CSTRSTATES=' '
      CIOSTATES=' '
      ITRANS=0
      NSTRSTATES_1=1
      NIOSTATES_1=1
      NSTRSTATES_2=1
      NIOSTATES_2=1
      NSTR=0
      NIO=0
c-----------------------------------------------------------------------
      TESTSTRING='AA STR I/O  V     L     I     M     '//
     +       'F     W     Y     G     A     P     S     T     C     '//
     +       'H     R     K     Q     E     N     D     B     Z'
      WRITE(6,'(a,a)')' GETSIMMATRIX open metric: ',simfile(1:50)
      CALL OPEN_FILE(KSIM,SIMFILE,'READONLY,OLD',LERROR)
      IF (LERROR)GOTO 99
C----------------------------------------------------------------------
      DO WHILE(INDEX(LINE,TESTSTRING).EQ.0)
         READ(KSIM,'(A)',END=99)LINE          
         IF (INDEX(LINE,'STRUCTURE-STATES_1:') .NE. 0) THEN
            I=INDEX(LINE,':')+1
            CALL STRPOS(LINE,IBEG,IEND)
            CALL READ_INT_FROM_STRING(LINE(I:IEND),NSTRSTATES_1)
         ELSE IF (INDEX(LINE,'STRUCTURE-STATES_2:') .NE. 0) THEN
            I=INDEX(LINE,':')+1
            CALL STRPOS(LINE,IBEG,IEND)
            CALL READ_INT_FROM_STRING(LINE(I:IEND),NSTRSTATES_2)
         ELSE IF (INDEX(LINE,'I/O-STATES_1:') .NE. 0) THEN
            I=INDEX(LINE,':')+1
            CALL STRPOS(LINE,IBEG,IEND)
            CALL READ_INT_FROM_STRING(LINE(I:IEND),NIOSTATES_1)
         ELSE IF (INDEX(LINE,'I/O-STATES_2:') .NE. 0) THEN
            I=INDEX(LINE,':')+1
            CALL STRPOS(LINE,IBEG,IEND)
            CALL READ_INT_FROM_STRING(LINE(I:IEND),NIOSTATES_2)
         ELSE IF (INDEX(LINE,'DSSP-STRUCTURE') .NE. 0) THEN
            DO I=1,NSTRSTATES_1
               DO J=1,NIOSTATES_1
                  READ(KSIM,'(A)')LINE
                  READ(LINE,'(4X,A1,13X,A1)')CSTR,CIO
                  K=INDEX(CSTRSTATES,CSTR)
                  IF (K.EQ.0) THEN
	             NSTR=NSTR+1
	             K=NSTR
	             IF (NSTR .GT. MAXSTRSTATES) THEN
                        WRITE(6,*)'*** ERROR: struct-states overflow'
                        STOP
	             ENDIF
C                     WRITE(6,*)' info:CSTRSTATES=',CSTRSTATES
                     CALL STRPOS(CSTRSTATES,IBEG,IEND)
C                     WRITE(6,*)' info:2 CSTRSTATES=',CSTRSTATES
	             IF (IEND+1 .GT. LEN(CSTRSTATES)) THEN
                        WRITE(6,*)
     +                       '*** ERROR: CSTRSTATES string too short'
                        STOP          
	             ENDIF
	             WRITE(CSTRSTATES(IEND+1:IEND+1),'(A1)')CSTR
                  ENDIF
                  L=INDEX(CIOSTATES,CIO)
                  IF (L.EQ.0) THEN
	             NIO=NIO+1
	             L=NIO
	             IF (NIO .GT. MAXIOSTATES) THEN
                        WRITE(6,*)'*** ERROR: I/O-states overflow'
                        STOP           
	             ENDIF
                     CALL STRPOS(CIOSTATES,IBEG,IEND)
	             IF (IEND+1 .GT. LEN(CSTRSTATES)) THEN
                        WRITE(6,*)
     +                       '*** ERROR: CIOSTATES string too short'
                        STOP           
	             ENDIF
	             WRITE(CIOSTATES(IEND+1:IEND+1),'(A1)')CIO
                  ENDIF
                  READ(LINE,'(26X,F3.0)')IORANGE(K,L)
                  WRITE(6,*)' info:K,L,IORANGE(K,L) ',K,L,IORANGE(K,L)
               ENDDO
            ENDDO
         ENDIF
      ENDDO
C----------------------------------------------------------------------
      WRITE(6,*)' STRUCTURE-STATES_1: ',cstrstates,nstrstates_1
      WRITE(6,*)' I/O-STATES_1      : ',ciostates,niostates_1
      WRITE(6,*)' STRUCTURE-STATES_2: ',cstrstates,nstrstates_2
      WRITE(6,*)' I/O-STATES_2      : ',ciostates,niostates_2
      IF (NSTRSTATES_1 .EQ. 1)NSTR=1
      IF (NIOSTATES_1  .EQ. 1)NIO=1
      IF (NSTR .NE. NSTRSTATES_1 .OR. NIO .NE. NIOSTATES_1 ) THEN
         WRITE(6,*)'*** ERROR: number of structure-states .ne. NSTR'
         WRITE(6,*)'    OR     number of I/O-states       .ne. NIO'
         STOP                                               
      ENDIF
C----------------------------------------------------------------------
      DO WHILE(.TRUE.)
         ITRANS=ITRANS+1
         DO ISTR1=1,NSTRSTATES_1
            DO IO1=1,NIOSTATES_1
               DO ISTR2=1,NSTRSTATES_2
                  DO IO2=1,NIOSTATES_2
                     READ(KSIM,'(A)',END=11)LINE
                     I1=INDEX(CSTRSTATES,LINE(5:5))
                     J1=INDEX(CIOSTATES,LINE(8:8))
                     I2=INDEX(CSTRSTATES,LINE(6:6))
                     J2=INDEX(CIOSTATES,LINE(9:9))
                     IF (I1.EQ.0.OR.I2.EQ.0.OR.J1.EQ.0.OR.J2.EQ.0) THEN
                        IF (I1.EQ.0)I1=1
                        IF (J1.EQ.0)J1=1
                        IF (I2.EQ.0)I2=1
                        IF (J2.EQ.0)J2=1
                     ENDIF
                     READ(LINE,'(1X,A1,7X,22(1X,F5.2))')
     +                    CTRANS(ITRANS:ITRANS),
     +                    (SIMMETRIC(ITRANS,K,I1,J1,I2,J2),
     +                    K=1,MATRIXPOS)
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
 11   CLOSE(KSIM)
      ITRANS=ITRANS-1
C=======================================================================
C reset value for chain breaks etc...
C add 'X'
      ITRANS=ITRANS+1
      CTRANS(ITRANS:ITRANS)='X'
      I=INDEX(TRANS,'X')
      DO J=1,NTRANS
         DO ISTR1=1,NSTRSTATES_1
            DO IO1=1,NIOSTATES_1
               DO ISTR2=1,NSTRSTATES_2
                  DO IO2=1,NIOSTATES_2
                     SIMMETRIC(I,J,ISTR1,IO1,ISTR2,IO2)=0.0
                     SIMMETRIC(J,I,ISTR1,IO1,ISTR2,IO2)=0.0
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
c add '!'
      ITRANS=ITRANS+1
      CTRANS(ITRANS:ITRANS)='!'
      I=INDEX(TRANS,'!')
      DO J=1,NTRANS
         DO ISTR1=1,NSTRSTATES_1
            DO IO1=1,NIOSTATES_1
               DO ISTR2=1,NSTRSTATES_2
                  DO IO2=1,NIOSTATES_2
                     SIMMETRIC(I,J,ISTR1,IO1,ISTR2,IO2)=0.0
                     SIMMETRIC(J,I,ISTR1,IO1,ISTR2,IO2)=0.0
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
c add '-'
      ITRANS=ITRANS+1
      CTRANS(ITRANS:ITRANS)='-'
      I=INDEX(TRANS,'-')
      DO J=1,NTRANS
         DO ISTR1=1,NSTRSTATES_1
            DO IO1=1,NIOSTATES_1
               DO ISTR2=1,NSTRSTATES_2
                  DO IO2=1,NIOSTATES_2
                     SIMMETRIC(I,J,ISTR1,IO1,ISTR2,IO2)=0.0
                     SIMMETRIC(J,I,ISTR1,IO1,ISTR2,IO2)=0.0
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
c add '.'
      ITRANS=ITRANS+1
      CTRANS(ITRANS:ITRANS)='.'
      I=INDEX(TRANS,'.')
      DO J=1,NTRANS
         DO ISTR1=1,NSTRSTATES_1
            DO IO1=1,NIOSTATES_1
               DO ISTR2=1,NSTRSTATES_2
                  DO IO2=1,NIOSTATES_2
                     SIMMETRIC(I,J,ISTR1,IO1,ISTR2,IO2)=0.0
                     SIMMETRIC(J,I,ISTR1,IO1,ISTR2,IO2)=0.0
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
C----------------------------------------------------------------------
C check input order of amino acids
C=======================================================================
      IF (TRANS(1:NTRANS) .NE. CTRANS(1:ITRANS)) THEN
         WRITE(6,*)' *** ERROR: CTRANS from metric-file and TRANS'//
     +        ' are not the same'
         WRITE(6,*)'GETSIMMATRIX: ',ctrans,itrans
         WRITE(6,*)'GETSIMMATRIX: ',trans,ntrans
         STOP                            
      ENDIF

C=======================================================================
C debug
C=======================================================================
c	do istr1=1,nstrstates_1
c	   do io1=1,niostates_1
c	      do istr2=1,nstrstates_2
c	         do io2=1,niostates_2
c                  WRITE(6,*)(simmetric(1,j,istr1,io1,istr2,io2),j=1,26)
c	         enddo
c	      enddo
c	   enddo
c	enddo
C=======================================================================
      RETURN
C=======================================================================
C unknown metric or read error
C=======================================================================
 99   CLOSE(KSIM)
      WRITE(6,'(a)')
     +     '** ERROR reading metric in GETSIMMATRIX **'
      STOP
      END
C     END GETSIMMETRIC
C......................................................................

C......................................................................
C     SUB GETSWISSBASE
      SUBROUTINE GETSWISSBASE (KUNIT,MAXRES,KLOG,NRES,CSEQ,NAME,
     +     COMPND,ACCESSION,CPDBREF,LENDFILE)

c     implicit none
      INTEGER         KUNIT,MAXRES,KLOG,NRES
      CHARACTER*(*)   CSEQ,NAME,COMPND,ACCESSION,CPDBREF
      LOGICAL         LENDFILE
      CHARACTER*500   LOGSTRING
c internal 
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                  200)
      CHARACTER       LINE*(LINELEN)
      INTEGER         NID,ISTART,ISTOP,JSTART,JSTOP,I,J
C======================================================================
      LENDFILE=.FALSE.
      NID=0
      NRES=0
      NAME=' '
      COMPND=' '
      ACCESSION=' '
      CPDBREF=' '
      CSEQ=' '
      LINE=' '
      ISTOP=0
      JSTOP=0
C=====================================================================
      DO WHILE (.TRUE.)                                        
         READ(KUNIT,'(A)',END=900,ERR=900)LINE        
C identifier
         IF ( LINE(1:2) .EQ. 'ID' ) THEN
            NAME(1:)=LINE(6:17)
c accession number
         ELSE IF ( LINE(1:2) .EQ. 'AC' ) THEN
            I=INDEX(LINE,';')-1
            ACCESSION(1:)=LINE(6:I)
c name
         ELSE IF ( LINE(1:2) .EQ. 'DE' ) THEN
            COMPND=' '
            COMPND(1:200)=LINE(6:)
            GOTO 410
         ENDIF
      ENDDO
c search for sequence
 410  READ(KUNIT,'(A)',END=999)LINE         
      IF ( LINE(1:2) .EQ. 'SQ' ) THEN      
         GOTO 420
C     STORE LATEST BROOKHAVEN-POINTER IN CPDBREF
      ELSE IF ( LINE(1:2) .EQ. 'DR' .AND. 
     +        INDEX(LINE,'PDB;') .NE. 0) THEN    
         CALL STRPOS(CPDBREF,ISTART,ISTOP)
         CALL STRPOS(LINE,JSTART,JSTOP)
         IF (LINE(JSTOP:JSTOP) .EQ. '.')JSTOP=JSTOP-1
         IF (ISTOP+JSTOP .LE. LEN(CPDBREF) ) THEN
            IF (NID .LE. 0) THEN
               CPDBREF(ISTOP+1:)=LINE(11:JSTOP)
            ELSE
               CPDBREF(ISTOP+1:)='|'//LINE(11:JSTOP)
            ENDIF
            NID=NID+1
c             else
c	       WRITE(6,*)'**** PDBREF-LINE DIMENSION OVERFLOW ***'
         ENDIF
      ENDIF
      GOTO 410
 420  IF (NID .GT. 0) THEN
         CALL STRPOS(CPDBREF,ISTART,ISTOP)
         IF ( (ISTOP+6) .LE. LEN(CPDBREF) ) THEN
	    WRITE(CPDBREF(ISTOP+1:),'(A,I4)')'||',NID
         ELSE
	    WRITE(6,*)'**** PDBREF-LINE DIMENSION OVERFLOW ***'
         ENDIF
      ENDIF
c sequences starts in next line
 430  READ(KUNIT,'(A)',ERR=999,END=999) LINE    
c end of database file reached ?
      IF ( LINE(1:2) .EQ. '//' ) RETURN
c	call strpos(line,istart,istop)
      DO ISTART=LINELEN,1,-1
         IF (LINE(ISTART:ISTART).NE.' ') THEN
            ISTOP=ISTART
            GOTO 440
         ENDIF
      ENDDO

 440  DO J=1,ISTOP
         IF ( LINE(J:J) .NE. ' ' .AND. NRES+1 .LE. MAXRES) THEN
            NRES=NRES+1
            CSEQ(NRES:NRES)=LINE(J:J)
         ELSE IF (NRES+1 .GT. MAXRES ) THEN
            WRITE(6,'(A)')'** DIMENSION OVERFLOW MAXSQ ***'
            GOTO 910
         ENDIF
      ENDDO
      GOTO 430
C=====================================================================
C END of SWISSPROT reached
C=====================================================================
 900  LENDFILE=.TRUE.
      NRES=0
      RETURN
C=====================================================================
C TRUNCATE IF NEEDED
C=====================================================================
 910  WRITE(LOGSTRING,'(A,I8,A)')'TRUNCATED TO ',MAXRES,
     +     ' RESIDUES: INCREASE DIMENSION '
c	call log_file(klog,logstring,1)
      RETURN
C======================================================================
 999  WRITE(LOGSTRING,'(A)')
     +     '*** ERROR READING SWISSPROT, SET NRES=0 AND RETURN'
c	call log_file(klog,logstring,1)
      NRES=0
      RETURN
      
      END
C     END GETSWISSBASE
C......................................................................

C......................................................................
C     SUB GET_SWISS_ENTRY
      SUBROUTINE GET_SWISS_ENTRY(MAXSQ,KUNIT,LBINARY,NRES,NAME,
     +     COMPOUND,ACCESSION,PDBREF,SEQ,LEND)

      IMPLICIT        NONE
C     IMPORT
      INTEGER         MAXSQ,KUNIT
      LOGICAL         LBINARY
C     EXPORT
      CHARACTER*(*)   SEQ,NAME,COMPOUND,ACCESSION,PDBREF
      INTEGER         NRES
      LOGICAL         LEND
C     INTERNAL 
      INTEGER         NSIZE,NSIZE2
      PARAMETER      (NSIZE=                    12)
      PARAMETER      (NSIZE2=                   200)
C======================================================================
      LEND=.FALSE.
C=====================================================================
      IF (LBINARY) THEN
         READ(KUNIT,END=900,ERR=900)NRES,NAME(1:NSIZE),
     +        ACCESSION(1:NSIZE),PDBREF(1:NSIZE),
     +        COMPOUND(1:NSIZE2)
         READ(KUNIT,END=900,ERR=999)SEQ(1:NRES)
      ELSE
         READ(KUNIT,'(I6,A,A,A,A,A)',END=900,ERR=999)NRES,
     +        NAME(1:NSIZE),ACCESSION(1:NSIZE),PDBREF(1:NSIZE),
     +        COMPOUND(1:NSIZE2),SEQ
c          read(kunit,'(i6,a,a,a,a,a)',end=900,err=999)nres,name,
c     +                          ACCESSION,pdbref,
c     +                          compound,seq
      ENDIF
c truncate if needed
      IF (NRES .GT. MAXSQ) THEN
c	  WRITE(6,*)' SEQ CUT TO MAXSQ: ',nres,MAXSQ
         NRES=MAXSQ
         CALL FLUSH_UNIT(6)
      ENDIF
      RETURN
C======================================================================
 900  LEND=.TRUE.
      NRES=0
      SEQ=' '
      NAME=' '
      ACCESSION=' '
      PDBREF=' '
      COMPOUND=' '
      RETURN
 999  WRITE(6,*)' ERROR in get_swiss_entry ',name,nres
      CALL FLUSH_UNIT(6)
      STOP
      END
C     END GET_SWISS_ENTRY
C......................................................................

C......................................................................
***** ------------------------------------------------------------------
***** SUB GETTOKEN
***** ------------------------------------------------------------------
C---- 
C---- NAME : GETTOKEN
C---- ARG  : 1 CSTRING(1:LEN) = string of length LEN
C---- ARG  : 2 LEN            = length of string
C---- ARG  : 3 ITOKEN         = number of string to matcho
C---- ARG  : 4 FIRSTPOS       = position where CSTRING matches
C---- ARG  :                    the ITOKEN nth STRING (non blank)
C---- ARG  : 5 CTOKEN         = returns ITOKEN nth string that matched
C---- ARG  :                    that matched in CSTRING
C---- DES  : Builds up the ITOKEN nth string in the string CSTRING
C---- DES  : that is not having any blank.  The first position of
C---- DES  : this string (FIRSTPOS) and the string (CTOKEN) are returned
C---- DES  : if no match: returns 0 (i.e. never matched)
C---- 
*----------------------------------------------------------------------*
C     SUB GETTOKEN
      SUBROUTINE GETTOKEN(CSTRING,LEN,ITOKEN,FIRSTPOS,CTOKEN)

      IMPLICIT NONE
C Import
      INTEGER       LEN,ITOKEN
      CHARACTER*(*) CSTRING
C Export
      INTEGER       FIRSTPOS
      CHARACTER*(*) CTOKEN
C Internal
      INTEGER       IPOS,THISTOKEN,TPOS
      LOGICAL       FINISHED,INSIDE
******------------------------------*-----------------------------******

C---- 
C---- initialise
C---- 
      CTOKEN=       ' '
      TPOS=         0
      FINISHED=     .FALSE.
      IF ( CSTRING(1:1) .EQ. ' ' ) THEN
         THISTOKEN= 0
         INSIDE=    .FALSE.
      ELSE
         THISTOKEN= 1
         INSIDE=    .TRUE.
         FIRSTPOS=  1
         IF ( THISTOKEN .EQ. ITOKEN ) THEN
            TPOS=   TPOS + 1
            CTOKEN(TPOS:TPOS)= CSTRING(1:1)
         ENDIF
      ENDIF
C---- 
C---- loop over string
C---- 
      IPOS = 2
      DO WHILE ((IPOS .LE. LEN) .AND. (.NOT. FINISHED) )
         IF ( CSTRING(IPOS:IPOS) .EQ. ' ' .OR. 
     1        IPOS .EQ. LEN ) THEN
            IF ( INSIDE ) THEN
               INSIDE = .FALSE.
               IF ( THISTOKEN .EQ. ITOKEN ) FINISHED = .TRUE.
            ENDIF
         ELSE
            IF ( .NOT. INSIDE ) THEN
               INSIDE = .TRUE.
               FIRSTPOS = IPOS
               THISTOKEN = THISTOKEN + 1   
            ENDIF
            IF ( THISTOKEN .EQ. ITOKEN ) THEN
               TPOS = TPOS + 1
               CTOKEN(TPOS:TPOS) = CSTRING(IPOS:IPOS)
            ENDIF
         ENDIF
         IPOS = IPOS + 1      
      ENDDO
      
      IF ( .NOT. FINISHED ) FIRSTPOS = 0
      RETURN
      END
C     END GETTOKEN
C......................................................................

C......................................................................
C     SUB HSSPHEADER
      SUBROUTINE HSSPHEADER(KHSSP,HSSPFILE,HSSPLINE,BRKID,CDATE,
     +     DATABASE,CPARAMETER,NPARALINE,ISOSIGFILE,ISAFE,LFORMULA,
     +     HEAD,COMP,SOURCE,AUTHOR,LRES,NCHAIN,KCHAIN,CHAINREMARK,
     +     NALIGN)

      IMPLICIT        NONE
C     import
      CHARACTER*(*)   HSSPLINE,DATABASE,CPARAMETER(*),
     +                HSSPFILE,ISOSIGFILE,CDATE
      INTEGER         KHSSP,NPARALINE,ISAFE,LRES,NCHAIN,KCHAIN,
     +                NALIGN
      LOGICAL         LFORMULA,LERROR
C     Attributes of DSSP-file 
      CHARACTER*(*)   HEAD,COMP,SOURCE,AUTHOR,BRKID,CHAINREMARK

C     internal
      INTEGER         I,LEN,ISTART,ISTOP

C---- --------------------------------------------------
C---- open HSSP-file and write header
C---- --------------------------------------------------
      CALL OPEN_FILE(KHSSP,HSSPFILE,'NEW',LERROR)
      CALL STRPOS(HSSPLINE,ISTART,ISTOP)
      WRITE(KHSSP,'(A)')HSSPLINE(1:ISTOP)
      CALL STRPOS(BRKID,ISTART,ISTOP)
      WRITE(KHSSP,'(A,A)')'PDBID      ',BRKID(ISTART:ISTOP)
      WRITE(KHSSP,'(A,A)')'DATE       file generated on ',CDATE
      CALL STRPOS(DATABASE,ISTART,ISTOP)
      WRITE(KHSSP,'(A)')DATABASE(1:ISTOP)
      DO I=1,NPARALINE
         CALL STRPOS(CPARAMETER(I),ISTART,ISTOP)
         WRITE(KHSSP,'(A,A)')'PARAMETER  ',CPARAMETER(I)(ISTART:ISTOP)
      ENDDO
C---- which formula used for filtering?
      IF (LFORMULA) THEN
         IF (ISAFE.EQ.0) THEN
            WRITE(KHSSP,'(A,A)')'THRESHOLD ',
     +           ' according to: t(L)=290.15 * L ** -0.562'
         ELSE IF (ISAFE.GT.0) THEN
            WRITE(KHSSP,'(A,A,I3)')'THRESHOLD ',
     +           ' according to: t(L)=(290.15 * L ** -0.562) +',isafe
         ELSE IF (ISAFE.LT.0) THEN
            WRITE(KHSSP,'(A,A,I3)')'THRESHOLD ',
     +           ' according to: t(L)=(290.15 * L ** -0.562) ',isafe
         ENDIF
C---- no FORMULA filtering
      ELSE
         CALL STRPOS(ISOSIGFILE,ISTART,ISTOP)
         WRITE(KHSSP,'(A,A)')'THRESHOLD  according to: ',
     +        ISOSIGFILE(ISTART:ISTOP) 
      ENDIF
      WRITE(KHSSP,'(A,A)')'REFERENCE ',' Sander C., Schneider R.'//
     +     ' : Database of homology-derived protein structures.'//
     +     ' Proteins, 9:56-68 (1991).'
      WRITE(KHSSP,'(A,A)')'CONTACT   ',
     +     ' e-mail (INTERNET) Schneider@EMBL-Heidelberg.DE or'//
     +     ' Sander@EMBL-Heidelberg.DE / fax +49-6221-387306'
      WRITE(KHSSP,'(A)')'AVAILABLE  Free academic use. Commercial'//
     +     ' users must apply for license.'
      WRITE(KHSSP,'(A)')'AVAILABLE  No inclusion in other databanks'//
     +     ' without permission.'
      CALL STRPOS(HEAD,ISTART,ISTOP)
      WRITE(KHSSP,'(A,A)')   'HEADER     ',HEAD(1:ISTOP)
      CALL STRPOS(COMP,ISTART,ISTOP)
      WRITE(KHSSP,'(A,A)')   'COMPND     ',COMP(1:ISTOP)
      CALL STRPOS(SOURCE,ISTART,ISTOP)
      WRITE(KHSSP,'(A,A)')   'SOURCE     ',SOURCE(1:ISTOP)
      CALL STRPOS(AUTHOR,ISTART,ISTOP)
      WRITE(KHSSP,'(A,A)')   'AUTHOR     ',AUTHOR(1:ISTOP)
      WRITE(KHSSP,'(A,I4)')  'SEQLENGTH  ',LRES
      CALL STRPOS(BRKID,ISTART,ISTOP)
      WRITE(KHSSP,'(A,I4,A,A,A)')'NCHAIN     ',NCHAIN,
     +     ' chain(s) in ',brkid(istart:istop),' data set'
c	WRITE(6,*)'chainremark: ',chainremark
      IF (CHAINREMARK .NE. ' ') THEN
         CALL STRPOS(CHAINREMARK,ISTART,ISTOP)
         WRITE(KHSSP,'(A,I4,A,A)')'KCHAIN     ',KCHAIN,
     +        ' chain(s) used here ; chain(s) : ',chainremark(1:istop)
      ENDIF
      WRITE(KHSSP,'(A,I4)')  'NALIGN     ',NALIGN

C---- 
C---- NOTATION part
C---- 
      WRITE(KHSSP,'(A)')'NOTATION : ID: EMBL/SWISSPROT identifier'//
     +     ' of the aligned (homologous) protein'
      WRITE(KHSSP,'(A)')'NOTATION : STRID: if the 3-D structure of'//
     +     ' the aligned protein is known, then STRID is the Protein'//
     +     ' Data Bank identifier as taken'
      WRITE(KHSSP,'(A)')'NOTATION : from the database'//
     +     ' reference or DR-line of the EMBL/SWISSPROT entry'
      WRITE(KHSSP,'(A)')'NOTATION : %IDE: percentage of residue'//
     +     ' identity of the alignment'
      WRITE(KHSSP,'(A)')'NOTATION : %SIM (%WSIM): '//
     +     ' (weighted) similarity of the alignment'
      WRITE(KHSSP,'(A)')'NOTATION : IFIR/ILAS: first and last resid'//
     +     'ue of the alignment in the test sequence'
      WRITE(KHSSP,'(A)')'NOTATION : JFIR/JLAS: first and last resid'//
     +     'ue of the alignment in the alignend protein'
      WRITE(KHSSP,'(A)')'NOTATION : LALI: length of the alignment'//
     +     ' excluding insertions and deletions'
      WRITE(KHSSP,'(A)')'NOTATION : NGAP: number of insertions'//
     +     ' and deletions in the alignment'
      WRITE(KHSSP,'(A)')'NOTATION : LGAP: total length of all'//
     +     ' insertions and deletions'
      WRITE(KHSSP,'(A)')'NOTATION : LSEQ2: length of the entire'//
     +     ' sequence of the aligned protein'
      WRITE(KHSSP,'(A)')'NOTATION : ACCESSION: SwissProt accession'//
     +     ' number'
      WRITE(KHSSP,'(A)')'NOTATION : PROTEIN: one-line description'//
     +     ' of aligned protein'
      WRITE(KHSSP,'(A)')'NOTATION : SeqNo,PDBNo,AA,STRUCTURE,BP1,'//
     +     'BP2,ACC: sequential and PDB residue numbers, amino acid '//
     +     '(lower case = Cys), secondary'
      WRITE(KHSSP,'(A)')'NOTATION : structure, bridge '//
     +     'partners, solvent exposure as in DSSP (Kabsch and Sander,'//
     +     ' Biopolymers 22, 2577-2637(1983)'
      WRITE(KHSSP,'(A)')'NOTATION : VAR: sequence variability on'//
     +     ' a scale of 0-100 as derived from the NALIGN alignments'
      WRITE(KHSSP,'(A)')'NOTATION : pair of lower case characters'//
     +     ' (AvaK) in the alignend sequence bracket a point of'//
     +     ' INSERTION IN THIS sequence'
      WRITE(KHSSP,'(A)')'NOTATION : dots (....) in the alignend'//
     +     ' SEQUENCE INDICATE POINTS of deletion in this sequence'
      WRITE(KHSSP,'(A)')'NOTATION : SEQUENCE PROFILE: relative '//
     +     'frequency of an amino acid type at each position. Asx'//
     +     ' and Glx are in their'
      WRITE(KHSSP,'(A)')'NOTATION : acid/amide'//
     +     ' form in proportion to their database frequencies'
      WRITE(KHSSP,'(A)')'NOTATION : NOCC: number of aligned sequenc'//
     +     'es spanning this position (including the test sequence)'
      WRITE(KHSSP,'(A)')'NOTATION : NDEL: number of sequences with'//
     +     ' a deletion in the test protein at this position'
      WRITE(KHSSP,'(A)')'NOTATION : NINS: number of sequences with'//
     +     ' an insertion in the test protein at this position'
      WRITE(KHSSP,'(A)')'NOTATION : ENTROPY: entropy measure of'//
     +     ' sequence variability at this position'
      WRITE(KHSSP,'(A)')'NOTATION : RELENT: relative entropy, i.e. '//
     +     ' entropy normalized to the range 0-100'
      WRITE(KHSSP,'(a)')'NOTATION : WEIGHT: conservation weight'
      WRITE(KHSSP,*)

      RETURN
      END
C     END HSSPHEADER
C......................................................................

C......................................................................
C     SUB INIT_CHAR_ARRAY
      SUBROUTINE INIT_CHAR_ARRAY(IBEG,IEND,CARRAY,SYMBOL)

      IMPLICIT NONE
      INTEGER         I,IBEG,IEND
      CHARACTER*(*)   CARRAY
      DIMENSION       CARRAY(IBEG:IEND)
      CHARACTER*(*)   SYMBOL
      
      DO I=IBEG,IEND
         CARRAY(I)=SYMBOL
      ENDDO

      RETURN
      END
C     END INIT_CHAR_ARRAY
C......................................................................

C......................................................................
C     SUB INIT_REAL_ARRAY
      SUBROUTINE INIT_REAL_ARRAY(IBEG,IEND,ARRAY,VALUE)
      
      IMPLICIT NONE
      INTEGER I,IBEG,IEND
      REAL ARRAY
      DIMENSION ARRAY(IBEG:IEND)
      REAL VALUE
      
      DO I=IBEG,IEND
         ARRAY(I)=VALUE
      ENDDO

      RETURN
      END
C     END INIT_REAL_ARRAY
C......................................................................

C......................................................................
C     SUB INIT_INT_ARRAY
      SUBROUTINE INIT_INT_ARRAY(IBEG,IEND,ARRAY,VALUE)
      
      IMPLICIT NONE
      INTEGER I,IBEG,IEND
      INTEGER ARRAY
      DIMENSION ARRAY(IBEG:IEND)
      INTEGER VALUE
      
      DO I=IBEG,IEND
         ARRAY(I)=VALUE
      ENDDO

      RETURN
      END
C     END INIT_INT_ARRAY
C......................................................................

C......................................................................
C     SUB INIT_INT2_ARRAY
      SUBROUTINE INIT_INT2_ARRAY(IBEG,IEND,ARRAY,VALUE)

      IMPLICIT NONE
      INTEGER I,IBEG,IEND
      INTEGER*2 ARRAY
      DIMENSION ARRAY(IBEG:IEND)
      INTEGER VALUE
      
      DO I=IBEG,IEND
         ARRAY(I)=VALUE
      ENDDO
      
      RETURN
      END
C     END INIT_INT2_ARRAY
C......................................................................

C......................................................................
C     SUB INT_TO_SEQ
      SUBROUTINE INT_TO_SEQ(LSEQ,SEQ,NRES,CTRANS,INDELMARK,ENDMARK)
C reverse SEQ_TO_INTEGER
C DSSP SS bridges (lower case) are lost (converted to 'C' from seqtoint)
C converts amino acid integers to string of amino acid characters
C uses translation table CHARACTER CTRANS
      IMPLICIT NONE
C import
      INTEGER NRES,LSEQ(*)
      INTEGER INDELMARK,ENDMARK
      CHARACTER*(*) CTRANS  
c export
      CHARACTER*1 SEQ(*)
C internal
      INTEGER I
C
      DO I=1,NRES
         IF (LSEQ(I) .EQ. 0) THEN
            WRITE(6,*)'** unknown res or chain separator in INT_TO_SEQ'
         ENDIF
         IF (LSEQ(I) .EQ. INDELMARK) THEN
            SEQ(I)='.'
         ELSE IF (LSEQ(I) .EQ. ENDMARK) THEN
            SEQ(I)='<'
         ELSE
            SEQ(I)=CTRANS(LSEQ(I):LSEQ(I))
         ENDIF
      ENDDO
      RETURN
      END
C END INT_TO_SEQ
C......................................................................

C......................................................................
C INT_TO_STRCLASS
      SUBROUTINE INT_TO_STRCLASS(MAXSTRSTATES,MAXALSQ,NRES,LSTRUC,
     +     STR_CLASSES,INDELMARK,ENDMARK,STRUC)  

      IMPLICIT      NONE
      INTEGER       MAXSTRSTATES,MAXALSQ
      INTEGER       NRES,LSTRUC(*),INDELMARK,ENDMARK
C---- br 99.03: watch hard_coded here, see maxhom.param
      CHARACTER*10  STR_CLASSES(MAXSTRSTATES)
C----     -->   REASON: the following produces warnings on SGI
C      CHARACTER*(*) STR_CLASSES(MAXSTRSTATES)
      CHARACTER     STRUC(MAXALSQ)
c internal
      INTEGER       I
c=======================================================================
      DO I=1,NRES
         IF (LSTRUC(I) .EQ. INDELMARK) THEN
            STRUC(I)='.'
         ELSE IF (LSTRUC(I) .EQ. ENDMARK) THEN
            STRUC(I)='<'
         ELSE
            STRUC(I)=STR_CLASSES(LSTRUC(I))(1:1)
         ENDIF
      ENDDO
      RETURN
      END
C     END INT_TO_STRCLASS
C......................................................................

C......................................................................
C     SUB INTERPRET_LINE
      SUBROUTINE INTERPRET_LINE(LINE,MAXFIELD,
     +     MACROLINE, CFIELD, CSTRING, CALFANUMERIC,
     +     CALFAMIXED,CWORD,NFIELD,NSTRING,NALFANUMERIC,
     +     NNUMBER, NREAL, NINTEGER,NPOSITIVE, NNEGATIVE, 
     +     NWORD, NALFAMIXED,IINTEGER,IPOSITIVE,
     +     INEGATIVE,XNUMBER, XREAL,IFIELD_POS)

      IMPLICIT NONE
c        INCLUDE 'interpret_line'
C input
      CHARACTER*(*) LINE 
      INTEGER MAXFIELD
      CHARACTER*(*) MACROLINE, CFIELD(*), 
     +     CSTRING(*), CALFANUMERIC(*),
     +     CALFAMIXED(*), CWORD(*) 
      INTEGER NFIELD,NSTRING,NALFANUMERIC,NNUMBER,NREAL,NINTEGER
      INTEGER NPOSITIVE, NNEGATIVE, NWORD, NALFAMIXED
      INTEGER IINTEGER(*),IPOSITIVE(*),
     +     INEGATIVE(*)
      REAL XNUMBER(*), XREAL(*)
C     POINTERS TO BEG AND END OF EACH FIELD
      INTEGER IFIELD_POS(2,*)
C     LOCAL
      LOGICAL LALFANUMERIC,LNUMBER,LREAL,LWORD
      INTEGER ID,I,ISTARTLINE,IENDLINE,IBEG,IEND
C interprets an input line
C-------example----------------------------------------------------
C input: CA Q 110  CB W -203  5.5
C output:   MACROLINE='LLCLLNR'
C   NFIELD=7 ; NSTRING=0 ; NALFANUMERIC=7 ; NNUMBER=3 ; NWORD=4
C   NALFAMIXED=0 ; NREAL=1 ; NINTEGER=2 ; NPOSITIVE=1 ; NNEGATIVE=1
C   CFIELD(2)='Q' ; XNUMBER(2)=-203. ; CSTRING(3)='CB'
C   IINTEGER(2)=-203 etc.
C-----------hierarchy of field types--------<A> = macroline symbol----
C  <S> like 4PTI.COOR    String = contains non-alfanumeric, like @#$%^&*
C  <A> like CA5          Alfamixed = mixed letters and numbers
C  <L> like TRP          Letters only = word
C  <R> like -.5E+5       Real number
C  <P> like 16           positive integer
C  <N> like -16          Negative integer or 0
C
C field       = (alfanumeric,other ASCII) (filterted by ASCII-filter)
C alfanumeric = (number, word, alfa-mixed)
C number      = (integer,real)
C integer     = (positive, negative)
C  
C STRING
C ALFANUMERIC
C   NUMBER
C     REAL
C     INTEGER
C       POSITIVE
C       NEGATIVE
C     WORD
C     ALFAMIXED
C
C macrosymbol is designed such that the whole world partitions into
C  S A L R P N, i.e. macrosymbol of a field is the lowest valid type
C
C----------------------------------------------------------------------
C step0: preliminaries
      NFIELD=0
      MACROLINE=' '
      NSTRING=0
      NALFANUMERIC=0
      NNUMBER=0
      NREAL=0
      NINTEGER=0
      NPOSITIVE=0
      NNEGATIVE=0
      NWORD=0
      NALFAMIXED=0
      DO ID=1,MAXFIELD
         CFIELD(ID)=' '
         CSTRING(ID)=' '
         CALFANUMERIC(ID)=' '
         XNUMBER(ID)=0.0
         XREAL(ID)=0.0
         IINTEGER(ID)=0
         IPOSITIVE(ID)=0
         INEGATIVE(ID)=0
         CWORD(ID)=' '
         CALFAMIXED(ID)=' '
         DO I=1,2
            IFIELD_POS(I,ID)=0
         ENDDO
      ENDDO
      CALL ASCIIFILTER(LINE)
C step1: find beg and end of each field
      CALL STRPOS(LINE,ISTARTLINE,IENDLINE)
      NFIELD=1
      IFIELD_POS(1,NFIELD)=ISTARTLINE
      DO I=ISTARTLINE,IENDLINE-1
C " x" starts field
         IF (LINE(I:I) .EQ. ' ' .AND. LINE(I+1:I+1) .NE. ' ') THEN 
            NFIELD=NFIELD+1
            IF ( NFIELD .GT. MAXFIELD) THEN
	       WRITE(6,*)'*** ERROR IN INTERPRETLINE: MAXFIELD OVERFLOW'
	       NFIELD=MAXFIELD
            ENDIF
            IFIELD_POS(1,NFIELD)=I+1
         ENDIF
C "x " ends field
         IF (LINE(I:I) .NE. ' ' .AND. LINE(I+1:I+1) .EQ. ' ') THEN 
            IFIELD_POS(2,NFIELD)=I
         ENDIF
      ENDDO
      IFIELD_POS(2,NFIELD)=IENDLINE

C step3: process each field
C-----------------------------------------------------------------------
C        NSTRING
C        NALFANUMERIC
C          NNUMBER
C            NREAL
C            NINTEGER
C              NPOSITIVE
C              NNEGATIVE
C          NWORD
C          NALFAMIXED
C-----------------------------------------------------------------------
      DO ID=1,NFIELD
C step 3.1: extract string i
         CFIELD(ID)=LINE(IFIELD_POS(1,ID):IFIELD_POS(2,ID))
         CALL STRPOS(CFIELD(ID),IBEG,IEND)
C step 3.2: determine type of field, store field, store macrosymbol
C .not. lalfanumeric
         CALL IS_ALFANUMERIC(CFIELD(ID),LALFANUMERIC)
         IF (.NOT. LALFANUMERIC) THEN
            NSTRING=NSTRING+1
            CSTRING(NSTRING)=CFIELD(ID)
            MACROLINE(ID:ID)='S'
         ELSE
C lnumber / lword / mixed
            NALFANUMERIC=NALFANUMERIC+1
            CALFANUMERIC(NALFANUMERIC)=CFIELD(ID)
            CALL IS_NUMBER(CFIELD(ID),LNUMBER)
            IF (LNUMBER) THEN
	       NNUMBER=NNUMBER+1
	       CALL IS_REAL(CFIELD(ID),LREAL)
C real / integer
	       IF (LREAL) THEN
                  NREAL=NREAL+1
                  CALL READ_REAL(CFIELD(ID),XREAL(NREAL))
                  XNUMBER(NNUMBER)=XREAL(NREAL)
                  MACROLINE(ID:ID)='R'
	       ELSE
                  CALL READ_REAL_FROM_STRING(CFIELD(ID)(IBEG:IEND),
     +                 XNUMBER(NNUMBER) )
                  NINTEGER=NINTEGER+1
                  CALL READ_INT_FROM_STRING(CFIELD(ID)(IBEG:IEND),
     +                 IINTEGER(NINTEGER) )
                  IF (IINTEGER(NINTEGER).GT.0) THEN
                     NPOSITIVE=NPOSITIVE+1
                     IPOSITIVE(NPOSITIVE)=IINTEGER(NINTEGER)
                     MACROLINE(ID:ID)='P'
                  ELSE
                     NNEGATIVE=NNEGATIVE +1
                     INEGATIVE(NNEGATIVE )=IINTEGER(NINTEGER)
                     MACROLINE(ID:ID)='N'
                  ENDIF
	       ENDIF
            ELSE
	       CALL IS_WORD(CFIELD(ID),LWORD)
	       IF (LWORD) THEN
                  NWORD=NWORD+1
                  CWORD(NWORD)=CFIELD(ID)
                  MACROLINE(ID:ID)='L'
	       ELSE
                  NALFAMIXED=NALFAMIXED+1
                  CALFAMIXED(NALFAMIXED)=CFIELD(ID)
                  MACROLINE(ID:ID)='A'
	       ENDIF
            ENDIF
         ENDIF
         GOTO 100
 100  ENDDO
C     
      RETURN
      END
C     END INTERPRET_LINE
C......................................................................

C......................................................................
C     SUB INTTOSTR
      SUBROUTINE INTTOSTR(NRES,LSTR,CSTR,LDSSP)
      IMPLICIT NONE
      INTEGER NRES,LSTR(*)
      CHARACTER CSTR(*)
      LOGICAL LDSSP
C internal
      INTEGER I
      CHARACTER*25 STRSTATES
      STRSTATES=' LTCSltcsEBAPMebapmHGIhgi'

      IF (LDSSP) THEN
         DO I=1,NRES
            IF (LSTR(I) .EQ. 99) THEN
	       CSTR(I)='.'
            ELSE IF (LSTR(I) .EQ. 999) THEN
	       CSTR(I)='<'
            ELSE
	       CSTR(I)=STRSTATES(LSTR(I):LSTR(I))
            ENDIF
         ENDDO
      ELSE
         DO I=1,NRES
            CSTR(I)='U'
         ENDDO
      ENDIF
      
      RETURN
      END
C     END INTTOSTR
C......................................................................

C......................................................................
C     SUB LEFTADJUST(STRING,NDIM,NLEN)
      SUBROUTINE LEFTADJUST(STRING,NDIM,NLEN)
C...left-adjust of a string
      IMPLICIT NONE
      CHARACTER*(*) STRING
      INTEGER NDIM, NLEN, l,il
C...find position of first non-blank
      IF (NDIM .LT. 1 .OR. NLEN .LT. 1) RETURN
      IF (NDIM .gt. 1)STOP' update routine leftadjust'

      L=1
      DO WHILE(STRING(L:L) .EQ. ' ' .AND. L .LT. NLEN)
         L=L+1
      ENDDO
      IF (L .GT. 1) THEN
C..L is position of first non-blank
         STRING(1:NLEN-L+1)=STRING(L:NLEN)
C.C..fill rest with blanks up to NLEN
         DO IL=NLEN-L+2,NLEN
            STRING(IL:IL)=' '
         ENDDO
      ENDIF

c      DO I=1,NDIM
c        L=1
c        DO WHILE(STRINGS(I)(L:L).EQ.' '.AND.L.LT.NLEN)
c          L=L+1
c        ENDDO
c        IF (L.GT.1) THEN
C..L is position of first non-blank
c          STRINGS(I)(1:NLEN-L+1)=STRINGS(I)(L:NLEN)
C.C..fill rest with blanks up to NLEN
c          DO IL=NLEN-L+2,NLEN
c            STRINGS(I)(IL:IL)=' '
c          ENDDO
c        ENDIF
c      ENDDO

      RETURN
      END
C     END LEFTADJUST
C......................................................................

C......................................................................
C     SUB IS_INTEGER
      SUBROUTINE IS_INTEGER(STRING,LINTEGER)
C LINTEGER = .TRUE. if first field of STRING is an INTEGER
C LINTEGER = first non-blank byte is + or - or a digit,  .AND.
C            all subsequent byte are digits, until blank.
      IMPLICIT NONE
C import
      CHARACTER*(*) STRING
C export
      LOGICAL LINTEGER
C local
      CHARACTER DIGITS*10, SIGNED*12
      INTEGER IBEG,IEND,K

      SIGNED='+-0123456789'
      DIGITS='0123456789'
      LINTEGER=.TRUE.

      CALL STRPOS(STRING,IBEG,IEND)
      K=IBEG
      IF (INDEX(SIGNED,STRING(K:K)).EQ.0) THEN
         LINTEGER=.FALSE.
         RETURN
      ENDIF
      K=K+1
      DO WHILE( K .LE. IEND)
         IF (INDEX(DIGITS,STRING(K:K)).EQ.0) THEN
            LINTEGER=.FALSE.
            RETURN
         ENDIF
         K=K+1
      ENDDO
      RETURN
      END
C     END IS_INTEGER
C......................................................................

C......................................................................
C     SUB IS_REAL
      SUBROUTINE IS_REAL(STRING,LREAL)
C LREAL = .TRUE. if STRING is a real number
C LREAL = integer / . / integer / E or e / integer
C import
      IMPLICIT NONE
      CHARACTER*(*) STRING
C export
      LOGICAL LREAL
C local
      CHARACTER*15 REALSYMBOL
      LOGICAL      LINTEGER
      INTEGER IBEG,IEND,K,IEXP,JEXP,IPOS,IDOT
C
      REALSYMBOL='0123456789.-+Ee'
      LREAL=.TRUE.
C not just an integer
      CALL IS_INTEGER(STRING,LINTEGER)
      IF (LINTEGER) THEN
         LREAL=.FALSE.
         RETURN
      ENDIF
      CALL STRPOS(STRING,IBEG,IEND)
      DO K=IBEG,IEND
         IF (INDEX(REALSYMBOL,STRING(K:K)).EQ. 0) THEN
            LREAL=.FALSE.
            RETURN
         ENDIF
      ENDDO
C LREAL = integer / . / integer / E or e / integer
      IDOT=INDEX(STRING,'.')
C we want one '.'
      IF (IDOT .EQ. 0) THEN
         LREAL=.FALSE.
         RETURN
      ENDIF
C the part before the '.' must be an integer
      IF (IDOT .NE. 1) THEN
         CALL IS_INTEGER(STRING(1:IDOT-1),LINTEGER)
      ELSE
C means:   .345
         LINTEGER=.TRUE.
      ENDIF
      IF (LINTEGER) THEN
         IEXP=INDEX(STRING(IDOT+1:),'E')
         JEXP=INDEX(STRING(IDOT+1:),'e')
C if no exponent is specified only an integer after the '.' is allowed
         IF (IEXP .EQ.0 .AND. JEXP .EQ. 0) THEN
            CALL IS_INTEGER(STRING(IDOT+1:),LINTEGER)
	    IF (.NOT. LINTEGER) THEN
               LREAL=.FALSE.
               RETURN
	    ENDIF
C     exponent must be an integer
         ELSE
	    IPOS=MAX(IEXP,JEXP)
            CALL IS_INTEGER(STRING(IDOT+1+IPOS:),LINTEGER)
	    IF (.NOT. LINTEGER) THEN
               LREAL=.FALSE.
               RETURN
	    ENDIF
         ENDIF
      ENDIF
      RETURN
      END
C     END IS_REAL
C......................................................................

C......................................................................
C     SUB IS_NUMBER
      SUBROUTINE IS_NUMBER(STRING,LNUMBER)
C LNUMBER=.TRUE. if STRING is a real or integer
      CHARACTER*(*) STRING
      LOGICAL LNUMBER, LINTEGER, LREAL

      CALL IS_REAL(STRING,LREAL)
      CALL IS_INTEGER(STRING,LINTEGER)
      LNUMBER= LREAL .OR. LINTEGER
      RETURN
      END
C     END IS_NUMBER
C......................................................................

C......................................................................
C     SUB IS_ALFANUMERIC
      SUBROUTINE IS_ALFANUMERIC(STRING,LALFANUMERIC)
C LALFANUMERIC=.TRUE. if STRING is alfanumeric
C LALFANUMERIC = contains only letters and digits and number 
C                punctuation (.+-)
      IMPLICIT NONE
C import
      CHARACTER*(*) STRING
C export
      LOGICAL LALFANUMERIC
C local
      CHARACTER ALFANUMERIC*65
      INTEGER IBEG,IEND,K
C init              
      ALFANUMERIC='ABCDEFGHIJKLMNOPQRSTUVWXYZ'//
     +     'abcdefghijklmnopqrstuvwxyz0123456789+-.'
      LALFANUMERIC=.TRUE.
      
      CALL STRPOS(STRING,IBEG,IEND)
      K=IBEG
      DO WHILE(K .LT. IEND)
         IF ( INDEX(ALFANUMERIC,STRING(K:K)) .EQ.0 ) THEN
            LALFANUMERIC=.FALSE.
            RETURN
         ENDIF
         K=K+1
      ENDDO
      RETURN
      END
C     END IS_ALFANUMERIC
C......................................................................

C......................................................................
C     SUB IS_WORD
      SUBROUTINE IS_WORD(STRING,LWORD)
C LWORD=.TRUE. if STRING is pure alfa.
C LWORD = contains only letters
      IMPLICIT NONE
C import
      CHARACTER*(*) STRING
C export
      LOGICAL LWORD
C local
      CHARACTER ALFA*52
      INTEGER IBEG,IEND,K
C init
      ALFA='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
      LWORD=.TRUE.
C
      CALL STRPOS(STRING,IBEG,IEND)
      K=IBEG
      DO WHILE(K .LT. IEND)
         IF ( INDEX(ALFA,STRING(K:K)) .EQ.0 ) THEN
            LWORD=.FALSE.
            RETURN
         ENDIF
         K=K+1
      ENDDO
      RETURN
      END
C     END IS_WORD
C......................................................................

C......................................................................
C     SUB LOG_FILE
      SUBROUTINE LOG_FILE(KLOG,STRING,IFLAG)
C iflag =0 ===> only in file
C iflag =1 ===> only std-out
C iflag =2 ===> both (file and std-out)
C
      IMPLICIT NONE
      INTEGER KLOG,IFLAG,IBEG,IEND,ILINE,I
      INTEGER ICUTBEGIN(20),ICUTEND(20)
      CHARACTER*(*) STRING
      
      CALL STRPOS(STRING,IBEG,IEND)
      ILINE=1
      ICUTBEGIN(ILINE)=1
      ICUTEND(ILINE)=IEND
      DO I=1,IEND-1
         IF (STRING(I:I+1).EQ.'/n') THEN
            ILINE=ILINE+1
            ICUTBEGIN(ILINE)=I+2
            ICUTEND(ILINE-1)=I-1
            ICUTEND(ILINE)=IEND
         ENDIF
      ENDDO
      DO I=1,ILINE
         IF (IFLAG .EQ. 0) THEN
            WRITE(KLOG,'(A)')STRING(ICUTBEGIN(I):ICUTEND(I))
         ELSE IF (IFLAG .EQ. 1) THEN
            WRITE(6,*)STRING(ICUTBEGIN(I):ICUTEND(I))
            CALL FLUSH_UNIT(6)
         ELSE IF (IFLAG .EQ. 2) THEN
            WRITE(KLOG,'(A)')STRING(ICUTBEGIN(I):ICUTEND(I))
            WRITE(6,*)STRING(ICUTBEGIN(I):ICUTEND(I))
            CALL FLUSH_UNIT(6)
         ENDIF
      ENDDO
      RETURN
      END
C     END LOG_FILE
C......................................................................

C......................................................................
C     SUB LOWER_TO_CYS
      SUBROUTINE LOWER_TO_CYS(SEQ,NRES)
C import
      CHARACTER*(*) SEQ
      INTEGER NRES

      DO I=1,NRES
         IF ( (SEQ(I:I) .GE. 'a') .AND. (SEQ(I:I) .LE. 'z') ) THEN
            SEQ(I:I)='C'
         ENDIF
      ENDDO
      END 
C     END LOWER_TO_CYS
C......................................................................

C......................................................................
C     SUB LOWTOUP
      SUBROUTINE LOWTOUP(STRING,LENGTH)
C LOWTOUP.......CONVERTS STRING......CHRIS SANDER JULY 1983
C changed by RS (speed up)
      CHARACTER*(*) STRING
      INTEGER LENGTH
CX      CHARACTER UPPER*26, LOWER*26, STRING*(*)
CX      DATA UPPER/'ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
CX      DATA LOWER/'abcdefghijklmnopqrstuvwxyz'/
C
      DO I=1,LENGTH
         IF (STRING(I:I) .GE. 'a' .AND. STRING(I:I) .LE. 'z') THEN
            STRING(I:I)=CHAR( ICHAR(STRING(I:I))-32 )
CX           K=INDEX(LOWER,STRING(I:I))
CX           IF (K.NE.0) STRING(I:I)=UPPER(K:K)
         ENDIF
      ENDDO
      RETURN
      END	
C     END LOWTOUP
C......................................................................

C......................................................................
C     SUB MAKE_FORMAT_INT
      SUBROUTINE MAKE_FORMAT_INT(ILEN,CFORMAT)

      INTEGER ILEN
      CHARACTER*(*) CFORMAT
      CHARACTER*20 CTEMP,CINT
      
      CFORMAT=' '
      CINT=' '
      WRITE(CINT,'(I20)')ILEN
      CALL CONCAT_STRINGS('(I',CINT,CTEMP)
      CALL CONCAT_STRINGS(CTEMP,')',CFORMAT)

      RETURN
      END
C     END MAKE_FORMAT_INT
C......................................................................

C......................................................................
C     SUB MARKALI
      SUBROUTINE MARKALI(S1,S2,N,AGREE,C)
C marks equalitites between S1 and S2 with C in string AGREE
c	implicit none

      CHARACTER*(*) S1,S2(*),AGREE(*),C
      CHARACTER CTEST
      INTEGER N,I,IAGR

      IF (N .EQ. 0) THEN
         WRITE(6,*)'*** N=0 IN MARKALI' 
         RETURN
      ENDIF
      IAGR=0
      DO I=1,N
         CTEST=S2(I)
c convert lower case letter of sequence 2
         CALL LOWTOUP(CTEST,1)
         IF (S1(I:I) .EQ. CTEST) THEN
            AGREE(I)=C 
            IAGR=IAGR+1
         ELSE
            AGREE(I)=' '
         ENDIF
      ENDDO
      RETURN
      END
C     END MARKALI
C......................................................................

C......................................................................
C     SUB MSFCHECKSEQ
      SUBROUTINE MSFCHECKSEQ(SEQCHECK,NSEQ,MSFCHECK)
      
C     IMPORT
      INTEGER NSEQ
      INTEGER SEQCHECK(NSEQ)
C     INTERNAL 
      INTEGER CHECKTMP, I
C     EXPORT
      INTEGER MSFCHECK 
      
      CHECKTMP = 0
      DO I = 1, NSEQ
         CHECKTMP = CHECKTMP + SEQCHECK(I)
      ENDDO
      MSFCHECK = MOD(CHECKTMP, 10 000)
      
      RETURN
      END
C     END MSFCHECKSEQ
C......................................................................

C......................................................................
C     SUB OPEN_SW_DATA_FILE
      SUBROUTINE OPEN_SW_DATA_FILE(KUNIT,LBINARY,IFILE,DATA,PATH,HOST)
C import
      CHARACTER*(*) DATA,PATH,HOST
      INTEGER KUNIT,IFILE
      LOGICAL LBINARY
C internal
      CHARACTER*100 TEMPNAME,LINE
      LOGICAL LERROR
      
      CALL CONCAT_INT_STRING(IFILE,DATA,LINE)
      CALL CONCAT_STRINGS(PATH,LINE,TEMPNAME)
      IF ( HOST .NE. ' ' ) THEN
         CALL STRPOS(HOST,IBEG,IEND)
         IF ( INDEX(HOST(IBEG:IEND),'unknownHost') .LE. 0 ) THEN
c	      WRITE(6,*)'host:',host,":",tempname
c	   host(iend+1:iend+1)=':'
            CALL CONCAT_STRINGS(HOST,TEMPNAME,LINE)
            TEMPNAME(1:)=LINE(1:)
         ENDIF
      ENDIF
c	WRITE(6,*)'file: ',tempname(1:60)
      CALL FLUSH_UNIT(6)

      IF (LBINARY) THEN
CAUTION RECL !!!!
         CALL OPEN_FILE(KUNIT,TEMPNAME,
     +        'OLD,READONLY,UNFORMATTED,RECL=500000',lerror)
      ELSE
         CALL OPEN_FILE(KUNIT,TEMPNAME,'OLD,READONLY',LERROR)
      ENDIF
      IF (LERROR) THEN
         WRITE(6,*)'ERROR: open file : ',tempname
         CALL FLUSH_UNIT(6)
         STOP
      ENDIF
      RETURN
      END
C     END OPEN_SW_DATA_FILE
C......................................................................
                
C......................................................................
C     SUB PREPARE_INSERTIONS
      SUBROUTINE PREPARE_INSERTIONS(MAXRES,MAXALIGNS,
     1     NRES,NALIGN,IFIR,ILAS,INSNUMBER,INSALI,INSLEN,
     2     INSAP,MAXLEN,INSLIST_POINTER,TOTALINSLEN,ERROR)
C 21.6.93
C 18.11. : AliseqEnvironment -> prepare_insertions;
C ........ return pointers to sublists of single alignments in ReadHSSP
C ........ arrays ( 0 if there is no sublist ) ;
C ........ + the maximal length of an insertion starting at any position
      IMPLICIT NONE
C Import
      INTEGER MAXRES,MAXALIGNS
      INTEGER NRES,NALIGN
      INTEGER IFIR(*), ILAS(*)
      INTEGER INSNUMBER,INSALI(*),INSLEN(*)
      INTEGER INSAP(*)
C Export
      INTEGER*2 TOTALINSLEN(MAXRES)
      INTEGER*2 MAXLEN(MAXRES), INSLIST_POINTER(MAXALIGNS)
      LOGICAL ERROR
C Internal
      INTEGER*2 INT2_TEMP
      INTEGER ALINO
      INTEGER IAP,IINS,TIL

      IF ( NALIGN .GT. MAXALIGNS ) THEN
         WRITE(6,'(1X,A)') 
     1        'MAXALIGNS overflow in prepare_insertions!'
         ERROR = .TRUE.
         RETURN
      ENDIF
      IF ( NRES .GT. MAXRES ) THEN
         WRITE(6,'(1X,A)') 'MAXRES overflow in prepare_insertions !'
         ERROR = .TRUE.
         RETURN
      ENDIF

      CALL INIT_INT2_ARRAY(1,NRES,MAXLEN,0)
      CALL INIT_INT2_ARRAY(1,NALIGN,INSLIST_POINTER,0)

      ALINO = INSALI(1)
      INSLIST_POINTER(ALINO) = 1
      MAXLEN(INSAP(1)) = INSLEN(1)
      
      DO IINS = 2,INSNUMBER
         IF ( ALINO .NE. INSALI(IINS) ) THEN
            ALINO = INSALI(IINS)
            INSLIST_POINTER(ALINO) = IINS
         ENDIF
C     NOTE: CONVERSION FROM INT4 IN INT2
         INT2_TEMP = INSLEN(IINS)
         MAXLEN(INSAP(IINS))=
     +        MAX(MAXLEN(INSAP(IINS)),INT2_TEMP)
      ENDDO
      
      TIL = 0
      DO IAP = 1,NRES
         IF ( MAXLEN(IAP) .GT. 0 ) TIL = TIL + MAXLEN(IAP)
         TOTALINSLEN(IAP) = TIL
      ENDDO

      RETURN
      END
C     END PREPARE_INSERTIONS
C......................................................................

C......................................................................
C     SUB PUNISHGAP
      SUBROUTINE PUNISHGAP(NRES,LDSSP,STRUC,GAPOPEN,PUNISH)
C======================================================================
C                INDELs in secondary structure segments
C----------------------------------------------------------------------
C if INDELS in secondary structure are NOT allowed (if DSSP-file(s))
C set gap-open(IPOS , SEQuence 1/SEQuence 2) in secondary structure segments 
C to a high value. 
C BUT NOT for the first and last residue in a segment
C          LLLLLHHHHHHHHHHLLLLLLLLL
C          ______^^^^^^^^__________
C                 punish
C
C definition of struture class is:    unknown 'U' = 0
C			             ' TCLStclss' = 1
C			             'EBAPMebapm' = 2  
C			             'HGIhgiiiii' = 3
C CAUTION: IF THE ASSIGNMENT OF STRUC CLASS IS CHANGED IN STRUCCLASS 
C ======== CHANGE IT ALSO HERE 
c=======================================================================
      IMPLICIT NONE
c import
      INTEGER NRES
      CHARACTER STRUC(*)
      LOGICAL LDSSP
      REAL PUNISH
C     CHANGED
      REAL GAPOPEN(*)
C     INTERNAL
      INTEGER I,ICLASS1,ICLASS2,ICLASS3
      CHARACTER C
C     
      IF (LDSSP) THEN
         DO I=2,NRES-1
            CALL SECSTRUC_TO_3_STATE(STRUC(I-1),C,ICLASS1)
            CALL SECSTRUC_TO_3_STATE(STRUC(I  ),C,ICLASS2)
            CALL SECSTRUC_TO_3_STATE(STRUC(I+1),C,ICLASS3)
            IF (ICLASS1.GT.1 .AND. ICLASS2.GT.1 .AND. ICLASS3.GT.1) THEN
	       GAPOPEN(I)=PUNISH
            ENDIF
         ENDDO
      ENDIF
      RETURN
      END
C     END PUNISHGAP
C......................................................................

C......................................................................
C     SUB PUNISH_GAP
      SUBROUTINE PUNISH_GAP(NRES,STRUC,STRSTATES,PUNISH,GAPOPEN)
C======================================================================
C                INDELs in secondary structure segments
C----------------------------------------------------------------------
C if INDELS in secondary structure are NOT allowed (passed in strstates)
C set gap-open(IPOS , SEQuence 1/SEQuence 2) in secondary str segments 
C to a high value. 
C BUT NOT for the first and last residue in a segment
C          LLLLLHHHHHHHHHHLLLLLLLLL
C          ______^^^^^^^^__________
C                 punish
C
c=======================================================================
      IMPLICIT NONE
C     IMPORT
      INTEGER NRES
      CHARACTER*(*) STRUC(*),STRSTATES
      REAL PUNISH
C     CHANGED
      REAL GAPOPEN(*)
C     INTERNAL
      INTEGER I,IBEG,IEND
C     
      CALL STRPOS(STRSTATES,IBEG,IEND)
      DO I=2,NRES-1
	 IF (INDEX(STRSTATES(IBEG:IEND),STRUC(I)) .NE. 0) THEN
            IF (STRUC(I).EQ.STRUC(I-1).AND.STRUC(I).EQ.STRUC(I+1)) THEN 
               GAPOPEN(I)=PUNISH
            ENDIF
	 ENDIF
      ENDDO
      RETURN
      END
C     END PUNISH_GAP
C......................................................................

C......................................................................
C     SUB PUTHEADER
      SUBROUTINE PUTHEADER(KPLOT,CSQ_1,CSQ_2,STRUC_1,STRUC_2,
     +     N1,N2,NAME_1,NAME_2)

      IMPLICIT      NONE

      INTEGER       KPLOT,N1,N2
      CHARACTER*(*) NAME_1,NAME_2
      CHARACTER*(*) CSQ_1,CSQ_2
      CHARACTER*1   STRUC_1(*),STRUC_2(*)
C internal
      INTEGER LINELEN,I,J,ISTOP,M
      CHARACTER*200 CTEMP

C init
      CTEMP=' '
      LINELEN=LEN(CTEMP)-1
                  
      write(kplot,*) '/number of residues in protein 1:'
      write(kplot,'(i10)')n1
      write(kplot,*) '/number of residues in protein 2:'
      write(kplot,'(i10)')n2 
      write(kplot,*) ' '
      write(kplot,*) '/file name for protein 1:'
      write(kplot,*)name_1
      write(kplot,*)'/file name for protein 2:' 
      write(kplot,*)name_2
      write(kplot,*)' ' 
      write(kplot,*)'/SEQUENCE 1:'
      DO I=1,N1,LINELEN
         J=1 
         ISTOP=I+LINELEN 
         IF (ISTOP.GT.N1)ISTOP=N1
         DO M=I,ISTOP
            WRITE(CTEMP(J:J),'(A)')CSQ_1(M:M) 
            J=J+1
         ENDDO
         WRITE(KPLOT,'(A)')CTEMP(:J-1)
      ENDDO
      WRITE(KPLOT,*)' ' 
      WRITE(KPLOT,*)'/SEQUENCE 2:'
      DO I=1,N2,LINELEN
         J=1 
         ISTOP=I+LINELEN 
         IF (ISTOP.GT.N2)ISTOP=N2
         DO M=I,ISTOP
            WRITE(CTEMP(J:J),'(A)')CSQ_2(M:M) 
            J=J+1
         ENDDO
         WRITE(KPLOT,'(A)')CTEMP(:J-1)
      ENDDO
      WRITE(KPLOT,*)' ' 
      WRITE(KPLOT,*) '/SECSTRUC 1:' 
      DO I=1,N1,LINELEN
         J=1 
         ISTOP=I+LINELEN 
         IF (ISTOP.GT.N1)ISTOP=N1
         DO M=I,ISTOP
            WRITE(CTEMP(J:J),'(A)')STRUC_1(M) 
            J=J+1
         ENDDO
         WRITE(KPLOT,'(A)')CTEMP(:J-1)
      ENDDO
      WRITE(KPLOT,*)' ' 
      WRITE(KPLOT,*) '/SECSTRUC 2:'
      DO I=1,N2,LINELEN
         J=1 
         ISTOP=I+LINELEN 
         IF (ISTOP.GT.N2)ISTOP=N2
         DO M=I,ISTOP
            WRITE(CTEMP(J:J),'(A)')STRUC_2(M) 
            J=J+1
         ENDDO
         WRITE(KPLOT,'(A)')CTEMP(:J-1)
      ENDDO
      WRITE(KPLOT,*) ' '
      RETURN
      END
C     END PUTHEADER
C......................................................................

C......................................................................
C     SUB READ_BRK
      SUBROUTINE READ_BRK(KIN,INFILE,CHAINS,CTRANS,RLEN,NRES,
     1     COMPND,SEQ,PDBNO,TRUNCATED,ERROR)

CAUTION ctrans2 and seq3 are character strings here but 
C       arrays in s1tos3 and s3tos1 ======>> BUG
c RS dec. 94

C 14.5.93
CHEADER    OXIDOREDUCTASE (SUPEROXIDE ACCEPTOR)    25-MAR-80   2SOD      2SOD 
CCOMPND    CU,ZN SUPEROXIDE DISMUTASE (E.C.1.15.1.1)                     2SOD 
C ..
CATOM      4  N   ALA O   1     -20.479  24.715 -21.334  1.00 16.16      2SOD 
CATOM      5  CA  ALA O   1     -19.117  24.539 -21.395  1.00 15.65      2SOD 
C1..4......11.14..1820....26....32....3840....4648....54
      IMPLICIT        NONE
C     IMPORT
      INTEGER         KIN,RLEN
      INTEGER         PDBNO(*)
      CHARACTER*(*)   CHAINS, CTRANS, INFILE
C     EXPORT
      CHARACTER*(*)   COMPND,SEQ
      LOGICAL         TRUNCATED,ERROR
C     INTERNAL
      INTEGER         MAXRES_LOC,NTRANS_LOC,LINELEN
      PARAMETER      (MAXRES_LOC=            10000)
      PARAMETER      (NTRANS_LOC=               25)
      PARAMETER      (LINELEN=                1000)
      INTEGER         ICHAIN, JCHAIN, ISTART, ISTOP, IPOS,
     +                NRES, N, NREAD, NTRANS
      CHARACTER*1     C, CHAIN
      CHARACTER*(3*MAXRES_LOC) SEQ3
      CHARACTER*10    NUMBERS
      CHARACTER*(LINELEN) LINE
      CHARACTER*(3*NTRANS_LOC) CTRANS3
*----------------------------------------------------------------------*
      
      
      WRITE(6,*)' STOP UPDATE READ_BRK'
C$$$  ERROR = .FALSE.
c$$$	
c$$$C try to open outfile; return if unsuccessful	
c$$$	call open_file(kin,infile,'old,readonly',error)
c$$$C error messages are alredy issued by OPEN_FILE   
c$$$        if ( error ) return
c$$$
c$$$	if ( linelen .lt. rlen ) then
c$$$           WRITE(6,'(1x,a)') 
c$$$     1     ' *** record length of input file too big ***'
c$$$           goto 1
c$$$        endif
c$$$
c$$$	error = .false.
c$$$	numbers = '0123456789'
c$$$	call strpos(ctrans,istart,istop)
c$$$        ntrans = istop-istart+1
c$$$	call s1tos3(ctrans3,ctrans,ntrans)
c$$$	read(kin,'(a)',err=1,end=2) line
c$$$        compnd = line(7:)
c$$$
c$$$	nres = 0
c$$$        ichain = 1
c$$$        jchain = 1
c$$$        seq3 = ' '
c$$$        call strpos(chains,istart,istop)
c$$$        call gettoken(chains,len(chains),1,ipos,chain)
c$$$        do while ( ipos .le. istop )
c$$$           do while ( line(1:4) .ne. 'ATOM' )
c$$$	      read(kin,'(a)',err=1,end=2) line
c$$$	   enddo
c$$$           c = line(22:22)
c$$$           if ( index(numbers,chain ) .ne. 0 ) then
c$$$              read(chain,'(i1)') n
c$$$              if ( n .eq. ichain ) then
c$$$	         call read_brkchain(kin,nres,ctrans3,rlen,line,seq3,
c$$$     1                           pdbno,nread,truncated,error)
c$$$                 nres = nres + nread
c$$$                 ichain = ichain + 1
c$$$                 jchain = jchain + 1
c$$$                 read(kin,'(a)',err=1,end=2) line
c$$$              else
c$$$                 call skip_brkchain(kin,rlen,line,error)
c$$$                 ichain = ichain + 1
c$$$                 read(kin,'(a)',err=1,end=2) line
c$$$              endif
c$$$           else
c$$$              if ( c .eq. chain ) then
c$$$	         call read_brkchain(kin,nres,ctrans3,rlen,line,seq3,
c$$$     1                           pdbno,nread,truncated,error)
c$$$                 nres = nres + nread
c$$$                 ichain = ichain + 1
c$$$                 jchain = jchain + 1
c$$$                 read(kin,'(a)',err=1,end=2) line
c$$$              else
c$$$                 call skip_brkchain(kin,rlen,line,error)
c$$$                 ichain = ichain + 1
c$$$                 read(kin,'(a)',err=1,end=2) line
c$$$              endif
c$$$           endif
c$$$           call strpos(chains,istart,istop)
c$$$           call gettoken(chains,len(chains),jchain,ipos,chain)
c$$$        enddo
c$$$
c$$$        goto 2
c$$$ 1	error = .true.
c$$$        WRITE(6,'(a)') ' ** error reading BRK file **'
c$$$ 2      continue
c$$$	call s3tos1(seq3,seq,nres)
c$$$     
c$$$	close(kin)

      RETURN
      END
C     END READ_BRK
C......................................................................

C......................................................................
C     SUB READ_BRKCHAIN
      SUBROUTINE READ_BRKCHAIN(KIN,SEQPOS,CTRANS,RLEN,FIRSTLINE,SEQ,
     1     PDBNO,NREAD,TRUNCATED,ERROR)
C 15.5.93
CATOM      4  N   ALA O   1     -20.479  24.715 -21.334  1.00 16.16      2SOD 232
CATOM      5  CA  ALA O   1     -19.117  24.539 -21.395  1.00 15.65      2SOD 233
C SPECIAL CASES :
CATOM    404  CA AASP    50       7.731   6.227  13.395  0.67 10.85      6PTI 
C1..4......11.14..1820....26....32....3840....4648....54
      IMPLICIT        NONE
C Import
      INTEGER         KIN,RLEN
C .. the read pointer of kin is expected to point to the next line 
C .. TO BE INTERPRETED
      INTEGER         SEQPOS
C .. may be alread partially filled. last occupied position is "seqpos"
      INTEGER         PDBNO(*)
      CHARACTER*(*)   SEQ
      CHARACTER*(*)   CTRANS, FIRSTLINE
C     EXPORT
      INTEGER         NREAD
      LOGICAL         TRUNCATED,ERROR
C .. and "seq", with "nread" more symbols; "pdbno" 
C    with "nread" more entries
C Internal
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      INTEGER         IPOS
      CHARACTER*3     C3
      CHARACTER*4     CNUMBER
      CHARACTER*(LINELEN) LINE
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      ERROR = .FALSE.
      NREAD = 0
      CNUMBER = ' '
      IPOS = SEQPOS
      LINE = FIRSTLINE
      DO WHILE ( LINE(1:3) .NE. 'TER' .AND. 
     1     .NOT. TRUNCATED )
         IF ( LINE(23:26) .NE. CNUMBER ) THEN
            CNUMBER = LINE(23:26)
            C3 = LINE(18:20)
            IF ( INDEX(CTRANS,C3) .NE. 0 ) THEN
               TRUNCATED = ( SEQPOS+NREAD+1 .GT. LEN(SEQ)/3 )
               IF ( .NOT. TRUNCATED ) THEN
                  IPOS = 3*(SEQPOS+NREAD)
                  SEQ(IPOS+1:IPOS+3) = C3
                  NREAD = NREAD + 1
                  READ (CNUMBER,'(I4)') PDBNO(SEQPOS+NREAD)
               ENDIF
            ENDIF
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO

      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') ' ** error reading BRK file **'
 2    CONTINUE

      RETURN
      END
C     END READ_BRKCHAIN
C......................................................................

C......................................................................
C     SUB READ_DSSPCHAIN
      SUBROUTINE READ_DSSPCHAIN(KIN,SEQPOS,CTRANS,RLEN,FIRSTLINE,SEQ,
     1     STRUC,ACC,PDBNO,NREAD,LACCZERO,TRUNCATED,ERROR)
C 18.5.93
C    1    1 O A              0   0   81    0, 0.0 149,-0.2   0, 0.0 104,-0.1   0.000 360.0 360.0 360.0 164.6  -19.1   24.5  -21.4
      IMPLICIT        NONE
C     IMPORT
      INTEGER         KIN, SEQPOS, RLEN
      CHARACTER*(*)   CTRANS, FIRSTLINE
C     EXPORT
      INTEGER         NREAD,PDBNO(*), ACC(*)
      CHARACTER*(*)   SEQ, STRUC
      LOGICAL         LACCZERO,TRUNCATED,ERROR
C     INTERNAL
      INTEGER         NASCII,LINELEN
      PARAMETER      (NASCII=                  256)
      PARAMETER      (LINELEN=                1000)
      INTEGER         LOWERPOS(NASCII),I
      CHARACTER*1     C
      CHARACTER*26    LOWER
      CHARACTER*(LINELEN) LINE
*----------------------------------------------------------------------*
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      ERROR = .FALSE.
C  USED TO CONVERT LOWER CASE CHARACTERS FROM THE DSSP-SEQ TO 'C' (CYS)
      LOWER='abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,NASCII)

      NREAD = 0
      LINE = FIRSTLINE
      DO WHILE ( LINE(14:14) .NE. '!' .AND. 
     1     .NOT. TRUNCATED )
         C = LINE(14:14)
         CALL GETINDEX(C,LOWERPOS,I)
         IF ( I.NE.0 ) C = 'C'
         IF ( INDEX(CTRANS,C) .NE. 0 ) THEN
            TRUNCATED = ( SEQPOS+NREAD+1 .GT. LEN(SEQ) )
            IF ( .NOT. TRUNCATED ) THEN
               NREAD = NREAD + 1
               SEQ(SEQPOS+NREAD:SEQPOS+NREAD) = C
               STRUC(SEQPOS+NREAD:SEQPOS+NREAD) = LINE(17:17)
               READ(LINE(6:10),'(I5)') PDBNO(SEQPOS+NREAD)
               READ(LINE(35:38),'(I4)') ACC(SEQPOS+NREAD)
               LACCZERO = LACCZERO .AND. (ACC(SEQPOS+NREAD) .EQ. 0)
            ENDIF
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      NREAD = NREAD + 1
      SEQ(SEQPOS+NREAD:SEQPOS+NREAD) = '!'
      STRUC(SEQPOS+NREAD:SEQPOS+NREAD) = ' '
      
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(A)') ' ** ERROR READING DSSP FILE **'
 2    CONTINUE

      RETURN
      END
C     END READ_DSSPCHAIN
C......................................................................

C......................................................................
C     SUB READ_EMBL
      SUBROUTINE READ_EMBL(KIN,INFILE,CTRANS,RLEN,NRES,COMPND,
     1     ACCESSION,PDB,SEQ,TRUNCATED,ERROR)
C 14.5.93
CDE test.pep from:    1 to:   13
CDE test.pep
CSQ   SEQUEN
C AAAAAAAAAA AAA
C//
      IMPLICIT        NONE
C     IMPORT
      INTEGER         KIN,RLEN
      CHARACTER*(*)   CTRANS,INFILE
C     EXPORT
      INTEGER         NRES
      CHARACTER*(*)   COMPND,ACCESSION,PDB, SEQ
      LOGICAL         TRUNCATED,ERROR
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      INTEGER         I,ID, ISTART, ISTOP, JSTART, JSTOP, IPOS
      CHARACTER*1     C
      CHARACTER*(LINELEN) LINE
*----------------------------------------------------------------------*
      
      ERROR = .FALSE.
      JSTOP=0
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KIN,INFILE,'old,readonly',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN

      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      ERROR = .FALSE.
      
      ID = 0
      PDB = ' '
      
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( LINE(1:2) .NE. 'SQ' )
         CALL STRPOS(LINE,ISTART,ISTOP)
         IF ( INDEX(LINE(1:2), 'AC') .NE. 0 ) THEN
            I = INDEX(LINE,';') - 1
            ACCESSION = LINE(6:I)
         ELSE IF ( INDEX(LINE(1:2), 'DE') .NE. 0 ) THEN
            COMPND = LINE(6:200)  
         ELSE IF ( INDEX(LINE(1:9), 'DR   PDB;') .NE. 0 ) THEN
C     .PDB-DATABASE POINTER 
            CALL STRPOS(PDB,ISTART,ISTOP)
            CALL STRPOS(LINE,JSTART,JSTOP)
            IF (LINE(JSTOP:JSTOP) .EQ. '.')JSTOP=JSTOP-1
C     I = LEN(PDB)
            IF ( ISTOP+JSTOP-10 .LE. LEN(PDB)) THEN
               IF ( ID .LE. 0 ) THEN
                  PDB(ISTOP+1:) = LINE(11:JSTOP)
               ELSE
                  PDB(ISTOP+1:) = '|' // LINE(11:JSTOP)
               ENDIF
               ID = ID + 1
            ELSE
               WRITE(6,*)'**** PDBREF-LINE DIMENSION OVERFLOW ***'
            ENDIF
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      CALL STRPOS(PDB,ISTART,ISTOP)
      IF ( ID .GT. 0 ) THEN
         IF ( ISTOP+7 .LE. LEN(PDB) ) THEN
            WRITE(PDB(ISTOP+1:),'(A,I4)') '||', ID 
         ELSE
            WRITE(6,*)'**** PDBREF-LINE DIMENSION OVERFLOW ***'
         ENDIF
      ENDIF
      
      NRES = 0
      READ(KIN,'(A)',ERR=1,END=2) LINE
C     SEQUENCE
      DO WHILE ( INDEX(LINE(1:2),'//') .EQ. 0 .AND.
     1     .NOT. TRUNCATED )
         CALL STRPOS(LINE,ISTART,ISTOP)
         DO IPOS = ISTART,ISTOP
            C = LINE(IPOS:IPOS)
            CALL LOWTOUP(C,1)
            IF ( INDEX(CTRANS,C) .NE. 0 ) THEN
               TRUNCATED = ( NRES+1 .GT. LEN(SEQ) )
               IF ( .NOT. TRUNCATED ) THEN
                  NRES = NRES + 1
                  SEQ(NRES:NRES) = C
               ENDIF
            ENDIF
         ENDDO
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
	
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') ' ** error reading EMBL/SWISSPROT file **'
 2    CONTINUE

      CLOSE(KIN)

      RETURN
      END
C     END READ_EMBL
C......................................................................

C......................................................................
C     SUB READ_FASTA
      SUBROUTINE READ_FASTA(KIN,INFILE,CTRANS,RLEN,NRES,
     1     ACCESSION,COMPND,SEQ,TRUNCATED,ERROR)
C 11.4.96
C>test blablabla
C A A A A A A A A A A A A A 
      IMPLICIT        NONE
C     IMPORT
      INTEGER         KIN, RLEN
      CHARACTER*(*)   CTRANS,INFILE
C     EXPORT
      INTEGER         NRES
      CHARACTER*(*)   ACCESSION,COMPND, SEQ
      LOGICAL         TRUNCATED,ERROR
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      INTEGER         IPOS, ISTART, ISTOP
      CHARACTER*1     C
      CHARACTER*(LINELEN) LINE
*----------------------------------------------------------------------*
      
      ERROR = .FALSE.
      ISTOP=0
C     TRY TO OPEN OUTFILE; RETURN IF UNSUCCESSFUL	
      CALL OPEN_FILE(KIN,INFILE,'old,readonly',error)
C     error messages are already issued by OPEN_FILE   
      IF ( ERROR ) RETURN
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( LINE(1:1) .NE. '>' )
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      CALL STRPOS(LINE,ISTART,ISTOP)
      ISTART=INDEX(LINE,' ')
      IF (ISTART .GT. 2 .AND. ISTART .LT. ISTOP) THEN
         ACCESSION(1:LEN(ACCESSION))=LINE(2:ISTART-1)
         COMPND = LINE(ISTART+1:ISTOP)
      ELSE
         ACCESSION(1:LEN(ACCESSION))=LINE(2:)
         COMPND=ACCESSION
      ENDIF
      
      NRES = 0
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( .NOT. TRUNCATED )
         CALL STRPOS(LINE,ISTART,ISTOP)
         IF ( ISTOP .NE. 0 ) THEN
            DO IPOS = ISTART,ISTOP
               C = LINE(IPOS:IPOS)
               CALL LOWTOUP(C,1)
               IF ( INDEX(CTRANS,C) .NE. 0 ) THEN
                  TRUNCATED = ( NRES+1 .GT. LEN(SEQ) )
                  IF ( .NOT. TRUNCATED ) THEN
                     NRES = NRES + 1
                     SEQ(NRES:NRES) = C
                  ENDIF
               ELSE IF (C .EQ. '*') THEN
                  GOTO 2
               ENDIF
            ENDDO
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO

      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') ' ** error reading FASTA file **'
 2    CONTINUE
       
      CLOSE(KIN)

      RETURN
      END
C     END READ_FASTA
C......................................................................

C......................................................................
C     SUB READ_GCG
      SUBROUTINE READ_GCG(KIN,INFILE,CTRANS,RLEN,NRES,COMPND,
     1     SEQ,TRUNCATED,ERROR)
C 14.5.93
C
C  Test.Pep  Length: 13  May 10, 1993  10:48  Type: N  Check: 5915  ..
C
C       1  AAAAAAAAAA AAA
C
      IMPLICIT        NONE
C     IMPORT
      INTEGER         KIN,RLEN
      CHARACTER*(*)   CTRANS,INFILE
C     EXPORT
      INTEGER         NRES
      CHARACTER*(*)   COMPND, SEQ
      LOGICAL         TRUNCATED,ERROR
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      INTEGER         IPOS,JPOS, ISTART,JSTART,JSTOP, ISTOP
      CHARACTER*1     C
      CHARACTER*10    CTOKEN
      CHARACTER*(LINELEN) LINE
*----------------------------------------------------------------------*

      ERROR = .FALSE.
	
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KIN,INFILE,'old,readonly',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN

      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF

      ERROR = .FALSE.

C     data start after a line ending with '..'
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( INDEX(LINE,'..') .EQ. 0 ) 
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
C     first word of '..' line
      CALL GETTOKEN(LINE,LINELEN,1,IPOS,COMPND)
C     sequence part     
      NRES = 0   
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( .TRUE. ) 
         CALL STRPOS(LINE,ISTART,ISTOP)
         IF ( ISTOP .GT. 0 ) THEN
C     .. FIRST WORD IS A NUMBER
            CALL GETTOKEN(LINE,LINELEN,1,JPOS,CTOKEN)
            CALL STRPOS(CTOKEN,JSTART,JSTOP)
            DO IPOS = JPOS+JSTOP-JSTART+1, ISTOP
               C = LINE(IPOS:IPOS)
               CALL LOWTOUP(C,1)
               IF ( INDEX(CTRANS,C) .NE. 0 ) THEN
                  TRUNCATED = ( NRES+1 .GT. LEN(SEQ) )
                  IF ( .NOT. TRUNCATED ) THEN
                     NRES = NRES + 1
                     SEQ(NRES:NRES) = C
                  ENDIF
               ENDIF
            ENDDO
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
	
 1    ERROR = .TRUE.
      WRITE(6,'(a)') ' ** error reading GCG file **'
 2    CONTINUE
        
      CLOSE(KIN)

      RETURN
      END
C     END READ_GCG
C......................................................................

C......................................................................
C     SUB READ_HSSPCHAIN
      SUBROUTINE READ_HSSPCHAIN(KIN,SEQPOS,CTRANS,RLEN,FIRSTLINE,SEQ,
     1     STRUC,ACC,PDBNO,NREAD,LACCZERO,TRUNCATED,ERROR)
C 18.5.93
C     1    1 O A              0   0   81   11   13  AAAAAAAA                  S   A
      IMPLICIT        NONE
C     IMPORT
      INTEGER         KIN,RLEN
      CHARACTER*(*)   CTRANS, FIRSTLINE
C     EXPORT
      INTEGER         NREAD, SEQPOS
      INTEGER         PDBNO(*), ACC(*)
      CHARACTER*(*)   SEQ, STRUC
      LOGICAL         LACCZERO,TRUNCATED,ERROR
C     INTERNAL
      INTEGER         NASCII,LINELEN
      PARAMETER      (NASCII=                  256)
      PARAMETER      (LINELEN=                1000)
      INTEGER         LOWERPOS(NASCII)
      INTEGER         I
      CHARACTER*1     C
      CHARACTER*26    LOWER
      CHARACTER*(LINELEN) LINE
*----------------------------------------------------------------------*

      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      ERROR = .FALSE.
C used to convert lower case characters from the DSSP-seq to 'C' (Cys)
      LOWER='abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,NASCII)

      NREAD = 0
      LINE = FIRSTLINE
      DO WHILE ( LINE(15:15) .NE. '!' .AND.
     1     LINE(1:2) .NE. '##'  .AND.
     2     .NOT. TRUNCATED )
         C = LINE(15:15)
         CALL GETINDEX(C,LOWERPOS,I)
         IF ( I.NE.0 ) C = 'C'
         IF ( INDEX(CTRANS,C) .NE. 0 ) THEN
            TRUNCATED = ( SEQPOS+NREAD+1 .GT. LEN(SEQ) )
            IF ( .NOT. TRUNCATED ) THEN
               NREAD = NREAD + 1
               SEQ(SEQPOS+NREAD:SEQPOS+NREAD) = C
               STRUC(SEQPOS+NREAD:SEQPOS+NREAD) = LINE(18:18)
               READ(LINE(7:11),'(I5)') PDBNO(SEQPOS+NREAD)
               READ(LINE(36:39),'(I4)') ACC(SEQPOS+NREAD)
               LACCZERO = LACCZERO .AND. (ACC(SEQPOS+NREAD) .EQ. 0 )
            ENDIF
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      NREAD = NREAD + 1
      SEQ(SEQPOS+NREAD:SEQPOS+NREAD) = '!'
      STRUC(SEQPOS+NREAD:SEQPOS+NREAD) = ' '
      
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') '*** ERROR READ_HSSPCHAIN reading HSSP file'
 2    CONTINUE

      RETURN
      END
C     END READ_HSSPCHAIN
C......................................................................

C......................................................................
C     SUB READ_INT_FROM_STRING
      SUBROUTINE READ_INT_FROM_STRING(CSTRING,INUMBER)
C import
      CHARACTER*(*) CSTRING
C export
      INTEGER INUMBER
C internal 
      CHARACTER*100 CFORMAT,CTEMP
      CHARACTER*12 CNUMBER

      CNUMBER='-=0123456789'
      CFORMAT=' '
      INUMBER=0

      CALL STRPOS(CSTRING,ISTART,ISTOP)
      ITOTAL=ISTOP-ISTART+1
      DO I=ISTART,ISTOP
         J=INDEX(CNUMBER,CSTRING(I:I))
         IF ( J .LE. 0) THEN
            ITOTAL=I-ISTART
	    WRITE(6,*)' *** NOT AN INTEGER:',CSTRING(ISTART:ISTOP)
         ENDIF
      ENDDO
      CALL CONCAT_STRING_INT('(I',ITOTAL,CTEMP)
      CALL CONCAT_STRINGS(CTEMP,')',CFORMAT)
      READ(CSTRING(ISTART:ISTOP),CFORMAT)INUMBER
      RETURN
      END
C     END READ_INT_FROM_STRING
C......................................................................

C......................................................................
C     SUB READ_MSF
      SUBROUTINE READ_MSF(KUNIT,FILENAME,MAXALIGNS,MAXCORE,
     1     ALISEQ,ALIPOINTER,IFIR,ILAS,JFIR,JLAS,TYPE,
     2     SEQNAMES,WEIGHT,SEQCHECK,MSFCHECK,NRES_ALI,NALIGN,
     3     ERROR)

C	Implicit None

C     IMPORT
      INTEGER         MAXALIGNS, MAXCORE
      INTEGER         KUNIT
      CHARACTER*(*)   FILENAME
C     EXPORT
      INTEGER         NALIGN
      INTEGER         ALIPOINTER(MAXALIGNS)
      INTEGER         NRES_ALI
      INTEGER         MSFCHECK
      INTEGER         IFIR(MAXALIGNS), ILAS(MAXALIGNS)  
      INTEGER         JFIR(MAXALIGNS), JLAS(MAXALIGNS)  
C     'P' = PROTEIN SEQUENCES, 'N' = NUCLEOTIDE SEQ
      CHARACTER*1     TYPE
      CHARACTER*(*)   SEQNAMES(MAXALIGNS)
      CHARACTER       ALISEQ(MAXCORE)	
      REAL            WEIGHT(MAXALIGNS)
      INTEGER         SEQCHECK(MAXALIGNS)
      LOGICAL         ERROR
C     INTERNAL
      INTEGER         CODELEN_LOC,MAXALIGNS_LOC, MAXRES_LOC,LINELEN
      PARAMETER      (CODELEN_LOC=              14)
      PARAMETER      (MAXALIGNS_LOC=         9999)
      PARAMETER      (MAXRES_LOC=            10000)
      PARAMETER      (LINELEN=                 200)
      
      INTEGER         TESTCHECK,I,IPOS,ISEQ,NPROT_THIS,ISTART,ISTOP,
     +                IBEG,ITMP,ILEN,DIFF,CFREE,FPOS,
     +                ISTART2,ISTOP2
      INTEGER         LASTOCCUPIED(MAXALIGNS_LOC),NRES(MAXALIGNS_LOC),
     +                NSEQLINES(MAXALIGNS_LOC)
      CHARACTER       CGAPCHAR
      CHARACTER*200   ERRORMESSAGE,CTOKEN,CTOKEN_ORIGINAL

C---- br 99.03: watch when changing this: hard_coded in GETARRAYINDEX
      CHARACTER*200   SEQNAMES_UPPER(MAXALIGNS_LOC)
     +              
      CHARACTER*(CODELEN_LOC) CNAME
      CHARACTER*(LINELEN) LINE, TMPSTRING,TMPSEQ
      CHARACTER*(MAXRES_LOC) STRAND
      CHARACTER*20    CFORMAT
      LOGICAL         INSIDE(MAXALIGNS_LOC)
      LOGICAL         INGAP(MAXALIGNS_LOC)
      LOGICAL         NO_ENDGAPS
      LOGICAL         LCHECK, LTYPE, LNRES_ALI
      LOGICAL         NEXT_IS_NRES_ALI, NEXT_IS_CHECK, NEXT_IS_TYPE
      LOGICAL         NEXT_IS_NAME, NEXT_IS_LEN, NEXT_IS_SEQCHECK
      LOGICAL         NEXT_IS_WEIGHT
*----------------------------------------------------------------------*

C REFORMAT of: *.Frag
C
C Nfi.Msf  MSF: 594  Type: P  February 17, 1992  14:37  Check: 1709  ..
C
C Name: Cnfi02           Len:   594  Check: 7754  Weight:  1.00
C Name: Cnfi03           Len:   594  Check: 4932  Weight:  1.00
C                          
C//
C
C        1                                                   50
CCnfi02  MMYSPICLTQ DEFHPFIEAL LPHVRAIAYT WFNLQARKRK YFKKHEKRMS 
CCnfi03  MMYSPICLTQ DEFHPFIEAL LPHVRAIAYT WFNLQARKRK YFKKHEKRMS 

      CGAPCHAR = '.'

      ERROR = .FALSE.
      CALL STRPOS(FILENAME,ISTART,ISTOP)
      ERRORMESSAGE = ' open error for file: ' //
     1     FILENAME(MAX(ISTART,1):MAX(1,ISTOP))
      CALL OPEN_FILE(KUNIT,FILENAME,'old,readonly',error)
      IF ( ERROR ) GOTO 99
C READ MSF IDENTIFICATION LINE
C Nfi.Msf  MSF: 594  Type: P  February 17, 1992  14:37  Check: 1709  ..
      ERROR = .TRUE.
      ERRORMESSAGE = ' MSF identification line missing  !! '
      READ(KUNIT,'(A)',END = 99) LINE
      DO WHILE ( INDEX(LINE,'MSF: ') .EQ. 0 )
         READ(KUNIT,'(A)',END = 99) LINE
      ENDDO
      LNRES_ALI = .FALSE.
      LCHECK = .FALSE.
      LTYPE =  .FALSE.
      NEXT_IS_NRES_ALI = .FALSE.
      NEXT_IS_CHECK = .FALSE.
      NEXT_IS_TYPE =  .FALSE.
C     DUMMY VALUE FOR "POSITION OF START OF NEXT WORD"
      FPOS = -1
C     ITH WORD
      I = 1
      CALL GETTOKEN(LINE,LINELEN,I,FPOS,CTOKEN)
      DO WHILE ( FPOS .NE. 0 ) 
         CALL STRPOS(CTOKEN,ISTART,ISTOP)
         CALL LOWTOUP(CTOKEN, LEN(CTOKEN))
         IF ( NEXT_IS_NRES_ALI ) THEN
            NEXT_IS_NRES_ALI = .FALSE.
            
            CALL MAKE_FORMAT_INT(ISTOP-ISTART+1,CFORMAT)
            
            READ(CTOKEN(ISTART:ISTOP),CFORMAT) NRES_ALI
         ELSE IF ( NEXT_IS_TYPE ) THEN
            TYPE = CTOKEN(ISTART:ISTOP)
            NEXT_IS_TYPE = .FALSE.
         ELSE IF ( NEXT_IS_CHECK ) THEN
            CALL MAKE_FORMAT_INT(ISTOP-ISTART+1,CFORMAT)
            READ(CTOKEN(ISTART:ISTOP),CFORMAT) MSFCHECK
            NEXT_IS_CHECK = .FALSE.
         ENDIF
         IF ( CTOKEN(ISTART:ISTOP) .EQ. 'MSF:' ) THEN
            LNRES_ALI = .TRUE.
            NEXT_IS_NRES_ALI = .TRUE.
         ELSE IF ( CTOKEN(ISTART:ISTOP) .EQ. 'TYPE:' ) THEN
            LTYPE = .TRUE.
            NEXT_IS_TYPE = .TRUE.
         ELSE IF ( CTOKEN(ISTART:ISTOP) .EQ. 'CHECK:' ) THEN
            LCHECK = .TRUE.
            NEXT_IS_CHECK = .TRUE.
         ENDIF
         I = I + 1
         CALL GETTOKEN(LINE,LINELEN,I,FPOS,CTOKEN)
      ENDDO
      IF ( .NOT. LNRES_ALI ) THEN
         ERROR = .TRUE.
         ERRORMESSAGE = ' MSF identification line missing  !! '
         GOTO 99
      ENDIF
      IF ( .NOT. LTYPE ) THEN
         ERROR = .TRUE.
         ERRORMESSAGE = ' Type identifier missing !! '
         GOTO 99
      ENDIF
      IF ( .NOT. LCHECK ) THEN
         ERROR = .TRUE.
         ERRORMESSAGE = ' CHECKSUM MISSING !! '
         GOTO 99
      ENDIF

C     READ SEQUENCE DESCRIPTION SECTION
      READ(KUNIT,'(A)',END = 99) LINE
C Name: Cnfi02           Len:   594  Check: 7754  Weight:  1.00
      ERROR = .TRUE.
      ERRORMESSAGE = ' Sequence description section missing !! '
      DO WHILE ( INDEX(LINE,'Name: ') .EQ. 0 )
         READ(KUNIT,'(A)',END = 99) LINE
      ENDDO

      ERROR = .FALSE.
      ERRORMESSAGE = ' Alignment missing !! '
C>>>
      NALIGN = 0
      DO WHILE ( INDEX(LINE,'Name: ') .NE. 0 )
         NALIGN = NALIGN + 1
         IF ( NALIGN .GT. MAXALIGNS .OR. 
     1        NALIGN .GT. MAXALIGNS_LOC) THEN
            ERROR = .TRUE.
            ERRORMESSAGE = ' MAXALIGNS overflow in read_msf !'
            GOTO 99
         ENDIF
         NEXT_IS_NAME = .FALSE.
         NEXT_IS_LEN =  .FALSE.
         NEXT_IS_SEQCHECK = .FALSE.
         NEXT_IS_WEIGHT =  .FALSE.
C     DUMMY VALUE FOR "POSITION OF START OF NEXT WORD"
         FPOS = -1
C ith word
         I = 1
         CALL GETTOKEN(LINE,LINELEN,I,FPOS,CTOKEN_ORIGINAL)
         CTOKEN=CTOKEN_ORIGINAL
         DO WHILE ( FPOS .NE. 0 ) 
            CALL STRPOS(CTOKEN,ISTART,ISTOP)
            CALL STRPOS(CTOKEN_ORIGINAL,ISTART2,ISTOP2)
            CALL LOWTOUP(CTOKEN,LEN(CTOKEN))

            IF ( NEXT_IS_NAME ) THEN
               NEXT_IS_NAME = .FALSE.
               SEQNAMES_UPPER(NALIGN)= CTOKEN(ISTART:ISTOP)
               SEQNAMES(NALIGN)=       CTOKEN_ORIGINAL(ISTART2:ISTOP2)

            ELSE IF ( NEXT_IS_LEN ) THEN
               NEXT_IS_LEN = .FALSE.
               CALL MAKE_FORMAT_INT(ISTOP-ISTART+1,CFORMAT)
               READ(CTOKEN(ISTART:ISTOP),CFORMAT) ILEN
               NRES_ALI = MAX(NRES_ALI,ILEN)
            ELSE IF ( NEXT_IS_SEQCHECK ) THEN
               NEXT_IS_SEQCHECK = .FALSE.
               CALL MAKE_FORMAT_INT(ISTOP-ISTART+1,CFORMAT)
               READ(CTOKEN(ISTART:ISTOP),CFORMAT) SEQCHECK(NALIGN)
            ELSE IF ( NEXT_IS_WEIGHT ) THEN
               NEXT_IS_WEIGHT = .FALSE.
               READ(CTOKEN(ISTART:ISTOP),*) WEIGHT(NALIGN)
            ENDIF
            IF      ( CTOKEN(ISTART:ISTOP) .EQ. 'NAME:' ) THEN
               NEXT_IS_NAME = .TRUE.
            ELSE IF ( CTOKEN(ISTART:ISTOP) .EQ. 'LEN:' ) THEN
               NEXT_IS_LEN = .TRUE.
            ELSE IF ( CTOKEN(ISTART:ISTOP) .EQ. 'CHECK:' ) THEN
               NEXT_IS_SEQCHECK = .TRUE.
            ELSE IF ( CTOKEN(ISTART:ISTOP) .EQ. 'WEIGHT:' ) THEN
               NEXT_IS_WEIGHT = .TRUE.
            ENDIF
            I = I + 1
            CALL GETTOKEN(LINE,LINELEN,I,FPOS,CTOKEN_ORIGINAL)
            CTOKEN=CTOKEN_ORIGINAL
         ENDDO
         READ(KUNIT,'(A)',END = 99) LINE
      ENDDO

      ERROR = .FALSE.
      CALL MSFCHECKSEQ(SEQCHECK,NALIGN,TESTCHECK)
      IF ( TESTCHECK .NE. MSFCHECK ) THEN
C     ERROR = .TRUE. 
         ERRORMESSAGE = 
     1        ' Total checksum incompatible with single checksums !!'

         WRITE(6,'(A)') ERRORMESSAGE
c           goto 99
      ENDIF
C SEARCH FOR "//" DIVIDER
      ERROR = .TRUE.
      ERRORMESSAGE = ' No proper MSFfile: divider missing !! '
      DO WHILE ( INDEX(LINE,'//' ) .EQ. 0 )
         READ(KUNIT,'(A)',END=99) LINE
      ENDDO
      ERROR = .FALSE.

C READ MULTIPLE ALIGNMENT
C        1                                                   50
CCnfi02  MMYSPICLTQ DEFHPFIEAL LPHVRAIAYT WFNLQARKRK YFKKHEKRMS 
C initialize 
      DO ISEQ = 1, NALIGN
         NSEQLINES(ISEQ)=    0
         NRES(ISEQ)=       0
         LASTOCCUPIED(ISEQ)= 0
         INSIDE(ISEQ)=       .FALSE.
C TEMPORARY assignment!
         IF ( ISEQ .EQ. 1 ) THEN
            ALIPOINTER(ISEQ) = 1
         ELSE
            ALIPOINTER(ISEQ) = ALIPOINTER(ISEQ-1)+NRES_ALI+1 
         ENDIF
         JFIR(ISEQ) = 1
         JLAS(ISEQ) = 0
      ENDDO
      ERROR = .TRUE.
      ERRORMESSAGE = ' ALIGNMENT MISSING !! '

C---- first line of alignment
      READ(KUNIT,'(A)',END=99) LINE

C---- --------------------------------------------------
C---- now loop over all blocks 
C----    end if overflow of some array, or file read
C----    LINELEN= maximal length of a line read
C----    
C----    
C----    
C---- --------------------------------------------------

      ERROR = .FALSE.
      DO WHILE ( .TRUE. )

C------- get the first non-blank string in the line read (CNAME)
C-------     note: this is the protein name
         CALL GETTOKEN(LINE,LINELEN,1,FPOS,CNAME)
         CALL LOWTOUP(CNAME, LEN(CNAME) )
C------- get the number of the protein with that name (CNAME)
C-------     out: NPROT_THIS=number of protein with name CNAME
C-------          NPROT_THIS=0      if none matched!
         CALL GETARRAYINDEX(SEQNAMES_UPPER,CNAME,NALIGN,NPROT_THIS)


C------  one of the names found
         IF ( NPROT_THIS .GT. 0 ) THEN
            NSEQLINES(NPROT_THIS)=NSEQLINES(NPROT_THIS)+1 
C---------- get the second non-blank string in the line read (TMPSEQ)
C----------     note: this is the sequence            
            CALL GETTOKEN(LINE,LINELEN,2,IBEG,TMPSEQ)
            CALL LOWTOUP(LINE,LEN(LINE))

C----             
C---- loop over all characters of line read
C----             
            DO IPOS=IBEG,LINELEN
C------------- if current residue neither ' ' nor TAB
               IF ( LINE(IPOS:IPOS) .NE. ' ' .AND.
     1              LINE(IPOS:IPOS) .NE. CHAR(0)   ) THEN
C---------------- count up protein length
                  NRES(NPROT_THIS)=NRES(NPROT_THIS) + 1
                  IF ( NRES(NPROT_THIS) .GT. NRES_ALI ) THEN
                     WRITE(6,'(A)')
     1           '*** ERROR in read_msf : SEQUENCE LENGTH EXCEEDS ' //
     2           'ALIGNMENT LENGTH GIVEN IN HEADER !!! ***'
                     WRITE(6,*)'*** line=',LINE(1:LEN(LINE))
                     WRITE(6,*)'*** this=',NRES(NPROT_THIS),
     +                    ' > ',NRES_ALI,' (NRES_ALI)'
                     STOP
                  ENDIF

C---------------- is gap
                  IF ( LINE(IPOS:IPOS) .EQ. CGAPCHAR ) THEN
                     INGAP(NPROT_THIS)= .TRUE.
                     IF ( INSIDE(NPROT_THIS) )  THEN
                        ITMP=ALIPOINTER(NPROT_THIS)+NRES(NPROT_THIS)-1
                        ALISEQ(ITMP)=CGAPCHAR
                     ENDIF

C---------------- is NOT gap
                  ELSE
                     INGAP(NPROT_THIS) = .FALSE.
                     LASTOCCUPIED(NPROT_THIS) = NRES(NPROT_THIS)
                     IF ( .NOT. INSIDE(NPROT_THIS) ) THEN
                        INSIDE(NPROT_THIS) = .TRUE.
                        IFIR(NPROT_THIS) = NRES(NPROT_THIS)
                     ENDIF
                     JLAS(NPROT_THIS) = JLAS(NPROT_THIS) + 1
                     ALISEQ(ALIPOINTER(NPROT_THIS)+NRES(NPROT_THIS)-1)=
     +                    LINE(IPOS:IPOS) 
                  ENDIF
               ENDIF
            ENDDO
         ENDIF
C else do nothing - blank or scale line
         READ(KUNIT,'(A)',END=99) LINE
      ENDDO
 99   CONTINUE

      IF ( .NOT. ERROR ) THEN
         DO ISEQ=2,NALIGN
            IF (NSEQLINES(ISEQ) .NE. NSEQLINES(1)) THEN
               ERROR= .TRUE.
               ERRORMESSAGE = 
     1              ' Inconsistent sequence names  !!'
               STOP
            ENDIF
         ENDDO
      ENDIF
      
      IF ( ERROR ) THEN
         WRITE(6,'(A)') ERRORMESSAGE
         RETURN
      ENDIF
      
      NO_ENDGAPS = .TRUE.
      DO ISEQ = 1,NALIGN
         NO_ENDGAPS = NO_ENDGAPS .AND. ( .NOT. INGAP(ISEQ))
         ILAS(ISEQ) = LASTOCCUPIED(ISEQ) 
      ENDDO
 
C delete n- and c-terminal gaps from aliseq;
C set ifir and ilas accordingly;
C set pointers to alignments
C 1.6.94 :
C truncate NRES_ALI to be the last position occupied in at least one 
C ........ one of the sequences !

      DIFF = 0
      CFREE = NRES_ALI + 1
      IPOS = 1
      DO ISEQ = 1,NALIGN
         ALIPOINTER(ISEQ) = IPOS
         DIFF = DIFF + IFIR(ISEQ) - 1
         I = IFIR(ISEQ)
         DO WHILE ( I .LE. ILAS(ISEQ) )
            ALISEQ(IPOS) = ALISEQ(IPOS+DIFF)
            I = I + 1
            IPOS = IPOS + 1
         ENDDO
         ALISEQ(IPOS) = '/'
         IPOS = IPOS + 1
         DIFF = DIFF + ( NRES_ALI - ILAS(ISEQ) )
C SMALLEST DISTANCE OF LAST OCCUPIED POSITION TO LAST ALIGNMENT POSITION
C  .. SHOULD BE ZERO, IF AT LEAST ONE SEQUENCE EXTENDS TO THE VERY END
         CFREE = MIN(CFREE,(NRES_ALI - ILAS(ISEQ)) )
      ENDDO
      
      IF ( CFREE .GT. 0 ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** WARNING : empty c-terminal positions truncated ***'
         NRES_ALI = NRES_ALI - CFREE
      ENDIF
      
      ERROR = .FALSE.
      DO ISEQ = 1, NALIGN
         STRAND = ' '
         CALL GET_SEQ_FROM_ALISEQ(ALISEQ,IFIR,ILAS,ALIPOINTER,
     1        NRES_ALI,ISEQ,STRAND,NREAD,
     2        ERROR )
         IF ( NO_ENDGAPS ) THEN
            CALL CHECKSEQ(STRAND,1,ILAS(ISEQ),TESTCHECK)
         ELSE
            CALL CHECKSEQ(STRAND,1,NRES_ALI,TESTCHECK)
         ENDIF
         IF ( TESTCHECK .NE. SEQCHECK(ISEQ) ) THEN
C     ERROR = .TRUE.
            CALL STRPOS(SEQNAMES_UPPER(ISEQ),ISTART,ISTOP)
            ERRORMESSAGE = 
     1         ' checksum of sequence '//seqnames(iseq)(istart:istop)//
     2         ' is not the same as checksum given in the header !' 
C                goto 99
         ENDIF
      ENDDO
      
      CLOSE(KUNIT)

      RETURN
      END                                                             
C     END READ_MSF
C......................................................................

C......................................................................
C     SUB READ_PIR
      SUBROUTINE READ_PIR(KIN,INFILE,CTRANS,RLEN,NRES,ACCESSION,
     1     COMPND,SEQ,TRUNCATED,ERROR)
C 14.5.93
C>P1; test
Ctest.pir ( test.pep from:    1 to:   13 )
C A A A A A A A A A A A A A *
      IMPLICIT        NONE
C     IMPORT
      INTEGER         KIN, RLEN
      CHARACTER*(*)   CTRANS,INFILE
C     EXPORT
      INTEGER         NRES
      CHARACTER*(*)   ACCESSION,COMPND, SEQ
      LOGICAL         TRUNCATED,ERROR
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      INTEGER         IPOS, ISTART, ISTOP
C     INTEGER JSTART, JSTOP
      CHARACTER*1     C
      CHARACTER*(LINELEN) LINE
c     logical empty
*----------------------------------------------------------------------*

      ERROR = .FALSE.
      ISTOP=0
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KIN,INFILE,'old,readonly',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( LINE(1:1) .NE. '>' )
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      ISTOP=INDEX(LINE,' ')-1
      ACCESSION(1:LEN(ACCESSION))=LINE(2:ISTOP)

c	istart=index(line,'|')+1
c	if ( istart .gt. 1) then
c	  istop=index(line(istart:),'|')-1
c	  if ( istop .gt. 0) then
c	    ACCESSION(1:len(ACCESSION))=line(istart:istart+istop-1)
c	  else
c	    ACCESSION(1:len(ACCESSION))=line(istart:)
c	  endif
c	else
c	  ACCESSION(1:len(ACCESSION))=line(2:)
c	ENDIF

C ?? one comment line ?? always ??
      READ(KIN,'(A)',ERR=1,END=2) LINE
      CALL STRPOS(LINE,ISTART,ISTOP)
      IF ( ISTOP .GT. 0 ) THEN
         COMPND = LINE(ISTART:ISTOP)
      ELSE
         COMPND = ' '
      ENDIF
c        if ( empty ) then
c           call strpos(line,istart,istop)
c           if ( istop .gt. 0 ) then
c              empty = .false.
c              compnd = line(istart:istop)
c           endif
c        endif
c        if ( empty ) then
c           call strpos(infile,istart,istop)
c           compnd = infile(istart:istop)
c        endif

      NRES = 0
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( .NOT. TRUNCATED )
         CALL STRPOS(LINE,ISTART,ISTOP)
         IF ( ISTOP .NE. 0 ) THEN
            DO IPOS = ISTART,ISTOP
               C = LINE(IPOS:IPOS)
               CALL LOWTOUP(C,1)
               IF ( INDEX(CTRANS,C) .NE. 0 ) THEN
                  TRUNCATED = ( NRES+1 .GT. LEN(SEQ) )
                  IF ( .NOT. TRUNCATED ) THEN
                     NRES = NRES + 1
                     SEQ(NRES:NRES) = C
                  ENDIF
               ELSE IF (C .EQ. '*') THEN
                  GOTO 2
               ENDIF
            ENDDO
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') ' ** error reading PIR file **'
 2    CONTINUE
       
      CLOSE(KIN)

      RETURN
      END
C     END READ_PIR
C......................................................................

C......................................................................
C     SUB READ_REAL
      SUBROUTINE READ_REAL(STRING,XREAL)
      CHARACTER*(*) STRING
      REAL XREAL
      INTEGER EXPONENT

      IEXP=INDEX(STRING,'E')
      JEXP=INDEX(STRING,'E')
      
      CALL STRPOS(STRING,IBEG,IEND)
      IF (IEXP .EQ.0 .AND. JEXP .EQ. 0) THEN
         CALL READ_REAL_FROM_STRING(STRING(IBEG:IEND),XREAL)
      ELSE 
         IPOS=MAX(IEXP,JEXP)
         CALL READ_INT_FROM_STRING(STRING(IPOS+1:IEND),EXPONENT)
         CALL READ_REAL_FROM_STRING(STRING(IBEG:IPOS-1),XREAL)
         XEXPONENT=FLOAT(EXPONENT)
         XREAL=XREAL * (10.0**XEXPONENT)
      ENDIF
      RETURN
      END
C     END READ_REAL
C......................................................................

C......................................................................
C     SUB READ_REAL_FROM_STRING
      SUBROUTINE READ_REAL_FROM_STRING(CSTRING,XNUMBER)
C import
      CHARACTER*(*) CSTRING
C export
      REAL XNUMBER
C internal 
      CHARACTER*100 CFORMAT,CTEMP
      INTEGER IPOS

      XNUMBER=0.0
      CALL STRPOS(CSTRING,ISTART,ISTOP)
      ITOTAL=ISTOP-ISTART+1
      IAFTER=0
      IPOS=INDEX(CSTRING,'.')
      IF (IPOS .GT. 0) THEN
         IAFTER=ISTOP-IPOS
      ENDIF
      CALL CONCAT_STRING_INT('(F',ITOTAL,CTEMP)
      CALL CONCAT_STRINGS(CTEMP,'.',CFORMAT)
      CALL CONCAT_STRING_INT(CFORMAT,IAFTER,CTEMP)
      CALL CONCAT_STRINGS(CTEMP,')',CFORMAT)
      READ(CSTRING(ISTART:ISTOP),CFORMAT)XNUMBER
      RETURN
      END
C     END READ_REAL_FROM_STRING
C......................................................................

C......................................................................
C     SUB READ_SEQ_FROM_DSSP
      SUBROUTINE READ_SEQ_FROM_DSSP(KIN,INFILE,CHAINS,CTRANS,RLEN,
     1     SEQ,STRUC,ACC,PDBNO,COMPND,NRES,
     2     LACCZERO,TRUNCATED,ERROR)

C 18. Dec 96, hackedihack, fixed a problem with dssp files with more
C than 9 chains, 
C NOTE: this whole routine is bullsh...; RS 96

C 14.5.93 Ulrike Goebel
C    1    1 O A              0   0   81    0, 0.0 149,-0.2   0, 0.0 104,-0.1   
      IMPLICIT        NONE
C     IMPORT
      INTEGER         KIN,RLEN
      INTEGER         PDBNO(*), ACC(*)
      CHARACTER*(*)   INFILE
C     EXPORT
      INTEGER         NRES
      CHARACTER*(*)   CHAINS
      CHARACTER*(*)   COMPND, CTRANS, SEQ, STRUC
      LOGICAL         LACCZERO,TRUNCATED,ERROR
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      INTEGER         N,ISTART,ISTOP,IPOS,JPOS,ICHAIN,JCHAIN,NREAD
      CHARACTER*1     C
      CHARACTER*(LINELEN) LINE
      CHARACTER*1000  NUMBERS
      CHARACTER*1000  TCHAINS,T2CHAINS
C ebi version 02.98 (and not: tchains, t2chains)
C      CHARACTER*10 NUMBERS
      
      ERROR = .FALSE.
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KIN,INFILE,'old,readonly',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN

      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
C not in ebi version 02.98
      TCHAINS=' '
      T2CHAINS=' '
C end ebi version 02.98
      LACCZERO = .TRUE.
      NUMBERS = '01234567891011121314151617181920'//
     1     '21222324252627282930313233343536'//
     2     '37383940414243444546474849505152'//
     3     '53545556575859606162636465666768'//
     4     '69707172737475767778798081828384'//
     5     '858687888990919293949596979899100'
C in ebi version 02.98
C      NUMBERS = '0123456789'


      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( LINE(3:12) .NE. '#  RESIDUE' )
         IF (LINE(1:6) .EQ. 'COMPND' ) THEN
            CALL STRPOS(LINE,ISTART,ISTOP)
            COMPND = LINE(7:MIN(200,ISTOP))
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
C     .. read pointer is now on first data line
      READ(KIN,'(A)',ERR=1,END=2) LINE
      
      NRES = 0
      ICHAIN = 1
      JCHAIN = 1
      CALL STRPOS(CHAINS,ISTART,ISTOP)

      TCHAINS(1:)=CHAINS(ISTART:ISTOP)
      IPOS=1
      JPOS=INDEX(TCHAINS,' ')-1

C last 3 lines not in ebi version 02.98, instead:
C      CALL GETTOKEN(CHAINS,LEN(CHAINS),1,IPOS,CHAIN)
      
      DO WHILE ( IPOS .LE. ISTOP )
         C = LINE(12:12)
         IF ( INDEX(NUMBERS,TCHAINS(1:JPOS) ) .NE. 0 ) THEN
            READ(TCHAINS(1:JPOS),'(I2)') N

C 2 lines in ebi version 02.98, instead:
C            IF ( INDEX(NUMBERS,CHAIN ) .NE. 0 ) THEN
C            READ(CHAIN,'(I1)') N

            IF ( N .EQ. ICHAIN ) THEN
               CALL READ_DSSPCHAIN(KIN,NRES,CTRANS,RLEN,LINE,SEQ,
     1              STRUC,ACC,PDBNO,NREAD,LACCZERO,
     2              TRUNCATED,ERROR)
               NRES = NRES + NREAD
               ICHAIN = ICHAIN + 1
               JCHAIN = JCHAIN + 1
               READ(KIN,'(A)',ERR=1,END=2) LINE
            ELSE
               CALL SKIP_DSSPCHAIN(KIN,RLEN,LINE,ERROR)
               ICHAIN = ICHAIN + 1
               READ(KIN,'(A)',ERR=1,END=2) LINE
            ENDIF
         ELSE
            IF ( C .EQ. CHAINS .OR. CHAINS .EQ. ' ') THEN
C line in ebi version 02.98, instead:
C           IF ( C .EQ. CHAIN .OR. CHAINS .EQ. ' ') THEN
               
               CALL READ_DSSPCHAIN(KIN,NRES,CTRANS,RLEN,LINE,SEQ,
     1              STRUC,ACC,PDBNO,NREAD,LACCZERO,
     2              TRUNCATED,ERROR)
               NRES = NRES + NREAD
               ICHAIN = ICHAIN + 1
               JCHAIN = JCHAIN + 1
               READ(KIN,'(A)',ERR=1,END=2) LINE
            ELSE
               CALL SKIP_DSSPCHAIN(KIN,RLEN,LINE,ERROR)
               ICHAIN = ICHAIN + 1
               READ(KIN,'(A)',ERR=1,END=2) LINE
            ENDIF
         ENDIF
         T2CHAINS(1:)=TCHAINS(JPOS+1:)
         CALL STRPOS(T2CHAINS,ISTART,ISTOP)
         TCHAINS(1:)=T2CHAINS(ISTART:ISTOP)
         JPOS=INDEX(TCHAINS,' ')-1
C last 4 lines in ebi version 02.98, instead:
C         CALL STRPOS(CHAINS,ISTART,ISTOP)
C         CALL GETTOKEN(CHAINS,LEN(CHAINS),JCHAIN,IPOS,CHAIN)
      ENDDO
      IF ( SEQ(NRES:NRES) .EQ. '!' ) THEN
         SEQ(NRES:NRES) = ' '
         STRUC(NRES:NRES) = ' '
         NRES = NRES - 1
      ENDIF
      
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') '*** ERROR reading DSSP file (READ_SEQ_FROM_DSSP)'
 2    CONTINUE

      CLOSE(KIN)
      RETURN
      END
C     END READ_SEQ_FROM_DSSP
C......................................................................

C......................................................................
C     SUB READ_SEQ_FROM_HSSP
      SUBROUTINE READ_SEQ_FROM_HSSP(KIN,INFILE,CHAINS,CTRANS,RLEN,SEQ,
     1     STRUC,ACC,PDBNO,COMPND,NRES,LACCZERO,TRUNCATED,ERROR )
C 14.5.93
C     1    1 O A              0   0   81   11   13  AAAAAAAA       
      IMPLICIT NONE
C     IMPORT
      INTEGER KIN, RLEN
      CHARACTER*(*) CHAINS
      CHARACTER*(*) INFILE
C     EXPORT
      INTEGER NRES
      INTEGER PDBNO(*), ACC(*)
      CHARACTER*(*) COMPND, CTRANS, SEQ, STRUC
      LOGICAL LACCZERO,TRUNCATED,ERROR
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      INTEGER         N,ISTART,ISTOP,IPOS,ICHAIN,JCHAIN,NREAD
      CHARACTER*1     C,CHAIN
      CHARACTER*(LINELEN) LINE
      CHARACTER*10    NUMBERS
*----------------------------------------------------------------------*
      
      ERROR = .FALSE.
	
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KIN,INFILE,'old,readonly',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      ERROR = .FALSE.
      LACCZERO = .TRUE.
      NUMBERS = '0123456789'
      
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( LINE(1:13) .NE. '## ALIGNMENTS' )
         IF (LINE(1:6) .EQ. 'COMPND' ) THEN
            CALL STRPOS(LINE,ISTART,ISTOP)
            COMPND = LINE(7:MIN(200,ISTOP))
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
C     .. skip 1 line
      READ(KIN,'(A)',ERR=1,END=2) LINE
C     .. read pointer is now on first data line
      READ(KIN,'(A)',ERR=1,END=2) LINE

      NRES = 0
      ICHAIN = 1
      JCHAIN = 1
      CALL STRPOS(CHAINS,ISTART,ISTOP)
      CALL GETTOKEN(CHAINS,LEN(CHAINS),1,IPOS,CHAIN)
      DO WHILE ( IPOS .LE. ISTOP )
         C = LINE(13:13)
         IF ( INDEX(NUMBERS,CHAIN ) .NE. 0 ) THEN
            READ(CHAIN,'(I1)') N
            IF ( N .EQ. ICHAIN ) THEN
               CALL READ_HSSPCHAIN(KIN,NRES,CTRANS,RLEN,LINE,SEQ,
     1              STRUC,ACC,PDBNO,NREAD,LACCZERO,
     2              TRUNCATED,ERROR)
               NRES = NRES + NREAD
               ICHAIN = ICHAIN + 1
               JCHAIN = JCHAIN + 1
               READ(KIN,'(A)',ERR=1,END=2) LINE
            ELSE
               CALL SKIP_HSSPCHAIN(KIN,RLEN,LINE,ERROR)
               ICHAIN = ICHAIN + 1
               READ(KIN,'(A)',ERR=1,END=2) LINE
            ENDIF
         ELSE
            IF ( C .EQ. CHAIN ) THEN
               CALL READ_HSSPCHAIN(KIN,NRES,CTRANS,RLEN,LINE,SEQ,
     1              STRUC,ACC,PDBNO,NREAD,LACCZERO,
     2              TRUNCATED,ERROR)
               NRES = NRES + NREAD
               ICHAIN = ICHAIN + 1
               JCHAIN = JCHAIN + 1
               READ(KIN,'(A)',ERR=1,END=2) LINE
            ELSE
               CALL SKIP_HSSPCHAIN(KIN,RLEN,LINE,ERROR)
               ICHAIN = ICHAIN + 1
               READ(KIN,'(A)',ERR=1,END=2) LINE
            ENDIF
         ENDIF
         CALL STRPOS(CHAINS,ISTART,ISTOP)
         CALL GETTOKEN(CHAINS,LEN(CHAINS),JCHAIN,IPOS,CHAIN)
      ENDDO
      IF ( SEQ(NRES:NRES) .EQ. '!' ) THEN
         SEQ(NRES:NRES) = ' '
         STRUC(NRES:NRES) = ' '
         NRES = NRES - 1
      ENDIF

      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') '*** ERROR reading HSSP file (read_seq_from_hssp)'
 2    CONTINUE
        
      CLOSE(KIN)

      RETURN
      END
C     END READ_SEQ_FROM_HSSP
C......................................................................

C......................................................................
C     SUB READ_STAR
      SUBROUTINE READ_STAR(KIN,INFILE,CTRANS,RLEN,NRES,SEQ,
     1     TRUNCATED,ERROR)
C 7.12.93
C*test.star ( test.pep from:    1 to:   13 )
C A A A A A A A A A A A A A 
      IMPLICIT NONE
C     IMPORT
      INTEGER KIN, RLEN
      CHARACTER*(*) CTRANS,INFILE
C     EXPORT
      INTEGER NRES
      CHARACTER*(*) SEQ
      LOGICAL TRUNCATED,ERROR
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      INTEGER         IPOS, ISTART, ISTOP
C     INTEGER JSTART, JSTOP
      CHARACTER*1     C
      CHARACTER*(LINELEN) LINE
C     LOGICAL EMPTY
*----------------------------------------------------------------------*

      ERROR = .FALSE.
	
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KIN,INFILE,'old,readonly',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      NRES = 0
      READ(KIN,'(A)',ERR=1,END=2) LINE
      DO WHILE ( .NOT. TRUNCATED )
         IF ( LINE(1:1) .NE. '*' ) THEN 
            CALL STRPOS(LINE,ISTART,ISTOP)
            IF ( ISTOP .NE. 0 ) THEN
               DO IPOS = ISTART,ISTOP
                  C = LINE(IPOS:IPOS)
                  CALL LOWTOUP(C,1)
                  IF ( INDEX(CTRANS,C) .NE. 0 ) THEN
                     TRUNCATED = ( NRES+1 .GT. LEN(SEQ) )
                     IF ( .NOT. TRUNCATED ) THEN
                        NRES = NRES + 1
                        SEQ(NRES:NRES) = C
                     ENDIF
                  ENDIF
               ENDDO
            ENDIF
         ENDIF
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(A)') ' ** ERROR READING STAR FILE **'
 2    CONTINUE
      
      CLOSE(KIN)
      
      RETURN
      END
C     END READ_STAR
C......................................................................

C......................................................................
C     SUB READHSSP
      SUBROUTINE READHSSP(IUNIT,HSSPFILE,ERROR,MAXRES,MAXALIGNS,
     +     MAXCORE,MAXINS,MAXINSBUFFER,PDBID,HEADER,COMPOUND,
     +     SOURCE,AUTHOR,SEQLENGTH,NCHAIN,KCHAIN,CHAINREMARK,
     +     NALIGN,EXCLUDEFLAG,EMBLID,STRID,IDE,SIM,IFIR,ILAS,
     +     JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,ACCESSION,PROTNAME,
     +     PDBNO,PDBSEQ,CHAINID,SECSTR,COLS,SHEETLABEL,BP1,BP2,
     +     ACC,NOCC,VAR,ALISEQ,ALIPOINTER,SEQPROF,NDEL,NINS,
     +     ENTROPY,RELENT,CONSWEIGHT,INSNUMBER,INSALI,
     +     INSPOINTER,INSLEN,INSBEG_1,INSBEG_2,INSBUFFER,
     +     LCONSERV,LHSSP_LONG_ID)
C
C Reinhard Schneider 1989, BIOcomputing EMBL, D-6900 Heidelberg, FRG
C please report any bug, e-mail (INTERNET):
C     schneider@EMBL-Heidelberg.DE 
C or  sander@EMBL-Heidelberg.DE    
C=======================================================================
C  INCREASE THE NUMBER OF FOLLOWING THREE PARAMETER IN THE CALLING 
C  PROGRAM IF NECESSARY
C=======================================================================
C  maxaligns = maximal number of alignments in a HSSP-file
C  maxres= maximal number of residues in a PDB-protein
C  maxcore= maximal space for storing the alignments
C=======================================================================
C
C  maxaa= 20 amino acids
C  nblocksize= number of alignments in one line
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
C         (structure ID)is the Protein Data Bank identifier as taken
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
C  consweight= conservation weight
C=======================================================================
      IMPLICIT        NONE
      INTEGER         MAXALIGNS,MAXRES,MAXCORE,MAXINS,MAXAA,NBLOCKSIZE
      INTEGER         MAXINSBUFFER
      PARAMETER      (MAXAA=                    20)
      PARAMETER      (NBLOCKSIZE=               70)
C============================ import ==================================
      CHARACTER       HSSPFILE*(*)
      INTEGER         IUNIT
      LOGICAL         ERROR	
C     ATTRIBUTES OF SEQUENCE WITH KNOWN STRUCTURE
      CHARACTER*(*)   PDBID,HEADER,COMPOUND,SOURCE,AUTHOR
      CHARACTER       PDBSEQ(MAXRES),CHAINID(MAXRES),SECSTR(MAXRES)
C.......LENGHT*7
      CHARACTER*(*)   COLS(MAXRES),CHAINREMARK 
      CHARACTER       SHEETLABEL(MAXRES)
      INTEGER         SEQLENGTH,PDBNO(MAXRES),NCHAIN,KCHAIN,NALIGN
      INTEGER         BP1(MAXRES),BP2(MAXRES),ACC(MAXRES)
C     ATTRIBUTES OF ALIGNEND SEQUENCES
      CHARACTER*(*)   EMBLID(MAXALIGNS),STRID(MAXALIGNS)
      CHARACTER*(*)   ACCESSION(MAXALIGNS),PROTNAME(MAXALIGNS)
      CHARACTER       ALISEQ(MAXCORE)	
      CHARACTER       EXCLUDEFLAG(MAXALIGNS)
      INTEGER         ALIPOINTER(MAXALIGNS),
     +                IFIR(MAXALIGNS),ILAS(MAXALIGNS),JFIR(MAXALIGNS),
     +                JLAS(MAXALIGNS),LALI(MAXALIGNS),NGAP(MAXALIGNS),
     +                LGAP(MAXALIGNS),LENSEQ(MAXALIGNS)
      REAL            IDE(MAXALIGNS),SIM(MAXALIGNS)
C     ATTRIBUTES OF PROFILE
      INTEGER         VAR(MAXRES),SEQPROF(MAXRES,MAXAA),RELENT(MAXRES),
     +                NOCC(MAXRES),NDEL(MAXRES),NINS(MAXRES),
     +                INSNUMBER,INSALI(MAXINS),INSPOINTER(MAXINS),
     +                INSLEN(MAXINS),INSBEG_1(MAXINS),INSBEG_2(MAXINS)
      REAL            ENTROPY(MAXRES),CONSWEIGHT(MAXRES)
      CHARACTER       INSBUFFER(MAXINSBUFFER)
      LOGICAL         LCONSERV,LHSSP_LONG_ID
C=======================================================================
C internal	
      INTEGER         MAXALIGNS_LOC
      PARAMETER      (MAXALIGNS_LOC=         9999)
      CHARACTER       CTEMP*(NBLOCKSIZE),TEMPNAME*200
      CHARACTER*200   LINE
      CHARACTER       CHAINSELECT
      LOGICAL         LCHAIN
      INTEGER         ICHAINBEG,ICHAINEND,NALIGNORG,
     +                I,J,K,IPOS,ILEN,NRES,IRES,NBLOCK,IALIGN,IBLOCK,
     +                IALI,IBEG,IEND,IPOINTER(300000),IPOINT,IINS

C---- ------------------------------------------------------------
C---- initialise
C---- ------------------------------------------------------------
C     ORDER OF AMINO ACID SYMBOLS IN THE HSSP SEQUENCE PROFILE BLOCK
C     PROFILESEQ='VLIMFWYGAPSTCHRKQEND'

      ERROR=.FALSE.
      NALIGN=0
      CHAINREMARK=' '
      CHAINSELECT=' '
      DO I=1,MAXINSBUFFER
         INSBUFFER(I)=' '
      ENDDO
      DO I=1,MAXALIGNS_LOC
         IPOINTER(I)=0
      ENDDO
      LCHAIN=.FALSE.
      LHSSP_LONG_ID = .FALSE.

      TEMPNAME(1:)=HSSPFILE
      I=INDEX(TEMPNAME,'_!_')
      J=INDEX(TEMPNAME,'hssp_')
      IF (I.NE.0) THEN
         TEMPNAME(1:)=HSSPFILE(1:I-1)
         LCHAIN=.TRUE.
         READ(HSSPFILE(I+3:),'(A1)')CHAINSELECT
         WRITE(6,*)'*** ReadHSSP: extract the chain: ',chainselect
      ELSE IF (J.NE.0) THEN
         TEMPNAME(1:)=HSSPFILE(1:J+3)
         LCHAIN=.TRUE.
         READ(HSSPFILE(J+5:),'(A1)')CHAINSELECT
         WRITE(6,*)'*** ReadHSSP: extract the chain: ',chainselect
      ENDIF

      CALL OPEN_FILE(IUNIT,TEMPNAME,'old,readonly',error)
      IF (ERROR) THEN
         WRITE(6,'(A,A)')'*** ERROR READHSSP failed opening file:',
     +        TEMPNAME
         GOTO 99
      END IF
      READ(IUNIT,'(A)',ERR=99)LINE
C check if it is a HSSP-file and get the release number for format flags
      IF (LINE(1:4).NE.'HSSP') THEN
         WRITE(6,'(A)')' ERROR: is not a HSSP-file'
         ERROR=.TRUE.
         RETURN
      ENDIF
C read in PDBID etc.
      DO WHILE(LINE(1:6).NE.'PDBID')
         READ(IUNIT,'(A)',ERR=99)LINE
      ENDDO
      READ(LINE,'(11X,A)',ERR=99)PDBID
      DO WHILE(LINE(1:6).NE.'HEADER')
         READ(IUNIT,'(A)',ERR=99)LINE
         IF (INDEX(LINE,'LONG-ID').NE.0) THEN
            IF (INDEX(LINE,'YES').NE.0) THEN
               LHSSP_LONG_ID = .TRUE.
            ENDIF
         ENDIF
      ENDDO
      READ(LINE ,'(11X,A)',ERR=99)HEADER
      READ(IUNIT,'(11X,A)',ERR=99)COMPOUND
      READ(IUNIT,'(11X,A)',ERR=99)SOURCE
      READ(IUNIT,'(11X,A)',ERR=99)AUTHOR
      READ(IUNIT,'(11X,I4)',ERR=99)SEQLENGTH
      READ(IUNIT,'(11X,I4)',ERR=99)NCHAIN
      IF (CHAINSELECT .NE. ' ')NCHAIN=1
      KCHAIN=NCHAIN
      READ(IUNIT,'(A)',ERR=99)LINE
      IF (INDEX(LINE,'KCHAIN').NE.0) THEN
         READ(LINE,'(11X,I4,A)',ERR=99)KCHAIN,CHAINREMARK
         READ(IUNIT,'(11X,I4)',ERR=99)NALIGNORG
      ELSE
         READ(LINE,'(11X,I4)',ERR=99)NALIGNORG
      ENDIF
C if HSSP-file contains no alignments return
      IF (NALIGNORG.EQ.0) THEN
         WRITE(6,'(A)')'*** HSSP-file contains no alignments ***'
         CLOSE(IUNIT)
c	   error=.true.
         RETURN
      ENDIF
C parameter overflow handling
      IF (NALIGNORG.GT.MAXALIGNS) THEN
         WRITE(6,'(A)')'*** HSSP-file contains too many alignments **'
         WRITE(6,'(A)')'***   INCREASE MAXALIGNS IN COMMOM BLOCK  ***'
         CLOSE(IUNIT)
         ERROR=.TRUE.
         RETURN
      ENDIF
      IF (NALIGNORG .GT. MAXALIGNS_LOC) THEN
         WRITE(6,*)'*** READHSSP: MAXALIGNS overflow, increase to >',
     +        NALIGNORG
         STOP
      ENDIF

      IF (SEQLENGTH+KCHAIN-1.GT.MAXRES) THEN
         WRITE(6,'(A)')'*** PDB-sequence in HSSP-file too long ***'
         WRITE(6,'(A)')'***  INCREASE MAXRES ***'	
         WRITE(6,'(A,I6,A,I6)')
     +        'need: ',seqlength+kchain-1,' limit is: ',maxres	
         CLOSE(IUNIT)
         ERROR=.TRUE.
         RETURN
      ENDIF

C number of sequence positions is number of residues + number of chains
C chain break is indicated by a '!'
      NRES=SEQLENGTH+KCHAIN-1
      ICHAINBEG=1
      ICHAINEND=NRES
      
      IF (LCHAIN) THEN
C search for ALIGNMENT-block
         DO WHILE (LINE(1:13).NE.'## ALIGNMENTS')
            READ(IUNIT,'(A)',ERR=99)LINE
         ENDDO
         READ(IUNIT,'(A)',ERR=99)LINE
         ICHAINBEG=0
         ICHAINEND=0
C read till end ; some PDB-chains have DSSP-chain breaks !!
         DO I=1,NRES	
            READ(IUNIT,'(7X,I4,1X,A1)',ERR=99)PDBNO(I),CHAINID(I)
            IF (CHAINID(I) .EQ. CHAINSELECT) THEN
               IF (ICHAINBEG .EQ. 0)ICHAINBEG=I
               ICHAINEND=I
            ENDIF
         ENDDO
C increment chain number for artificial chain breaks
         DO I=ICHAINBEG,ICHAINEND
            IF (CHAINID(I) .NE. CHAINSELECT)NCHAIN=NCHAIN+1
         ENDDO
         REWIND(IUNIT)
         SEQLENGTH=ICHAINEND-ICHAINBEG+1
         NRES=SEQLENGTH+NCHAIN-1
      ENDIF
C search for the PROTEINS block
      LINE=' '
      DO WHILE(LINE(1:11).NE.'## PROTEINS')
         READ(IUNIT,'(A)',ERR=99)LINE
      ENDDO
      READ(IUNIT,'(A)',ERR=99)LINE
      LCONSERV=.FALSE.
      IF (INDEX(LINE,'%WSIM').NE.0)LCONSERV=.TRUE.
C read data about the alignments
      IALIGN=1
      DO I=1,NALIGNORG
         IF ( LHSSP_LONG_ID) THEN
            READ(IUNIT,50,ERR=99)
     +           EXCLUDEFLAG(IALIGN),EMBLID(IALIGN)(1:),STRID(IALIGN),
     +           IDE(IALIGN),SIM(IALIGN),IFIR(IALIGN),ILAS(IALIGN),
     +           JFIR(IALIGN),JLAS(IALIGN),LALI(IALIGN),NGAP(IALIGN),
     +           LGAP(IALIGN),LENSEQ(IALIGN),ACCESSION(IALIGN),
     +           PROTNAME(IALIGN)
         ELSE   
            READ(IUNIT,100,ERR=99)
     +           EXCLUDEFLAG(IALIGN),EMBLID(IALIGN)(1:),STRID(IALIGN),
     +           IDE(IALIGN),SIM(IALIGN),IFIR(IALIGN),ILAS(IALIGN),
     +           JFIR(IALIGN),JLAS(IALIGN),LALI(IALIGN),NGAP(IALIGN),
     +           LGAP(IALIGN),LENSEQ(IALIGN),ACCESSION(IALIGN),
     +           PROTNAME(IALIGN)
         ENDIF
         IF ( IFIR(IALIGN) .GE. ICHAINBEG .AND. 
     +	      ILAS(IALIGN) .LE. ICHAINEND) THEN
            IPOINTER(I)=IALIGN
            IALIGN=IALIGN+1
         ELSE
            WRITE(6,*)'READHSSP INFO: skip alignment: ',IALIGN
         ENDIF
      ENDDO

 50   FORMAT (5X,A1,2X,A40,A6,1X,F5.2,1X,F5.2,8(1X,I4),2X,A10,1X,A)
 100  FORMAT (5X,A1,2X,A12,A6,1X,F5.2,1X,F5.2,8(1X,I4),2X,A10,1X,A)
      NALIGN=IALIGN-1
      WRITE(6,*)'--- number of alignments: ',nalign
      WRITE(6,*)'--- PROTEINS   block done'
C init pointer ; aliseq contains the alignments (amino acid symbols)
C stored in the following way ; '/' separates alignments
C alignment(x) is stored from:
C           aliseq(alipointer(x)) to aliseq(ilas(x)-ifir(x))
C  aliseq(1........46/48.........60/62....)
C         |           |             |
C         |           |             |
C         pointer     pointer       pointer 
C         ali 1       ali 2         ali 3
C
C                    
C init pointer
      IPOS=1
      DO I=1,NALIGN
         IF (IPOS.GE.MAXCORE) THEN
            WRITE(6,'(A)')'*** ERROR: INCREASE MAXCORE ***'
            STOP
         ENDIF
         ALIPOINTER(I)=IPOS
         ILEN=ILAS(I)-IFIR(I)+1
         IPOS=IPOS+ILEN
         ALISEQ(IPOS)='/'
         IPOS=IPOS+1
      ENDDO
      IF (NALIGN .LT. MAXALIGNS) THEN
         ALIPOINTER(NALIGN+1)=IPOS+1
      ENDIF
C number of ALIGNMENTS-blocks
      IF (MOD(FLOAT(NALIGNORG),FLOAT(NBLOCKSIZE)).EQ. 0.0) THEN
         NBLOCK=NALIGNORG/NBLOCKSIZE
      ELSE
         NBLOCK=NALIGNORG/NBLOCKSIZE+1
      ENDIF
C search for ALIGNMENT-block
      DO WHILE (LINE(1:13).NE.'## ALIGNMENTS')
         READ(IUNIT,'(A)',ERR=99)LINE
      ENDDO
      READ(IUNIT,'(A)',ERR=99)LINE
C loop over ALIGNMENTS blocks
C read in pdbno, chainid, secstr etc.
      IALIGN=0
      IALI=0
      DO IBLOCK=1,NBLOCK
         IRES=1
         DO I=1,NRES	
            READ(IUNIT,200,ERR=99)
     +           PDBNO(IRES),CHAINID(IRES),PDBSEQ(IRES),SECSTR(IRES),
     +           COLS(IRES),BP1(IRES),BP2(IRES),SHEETLABEL(IRES),
     +           ACC(IRES),NOCC(IRES),VAR(IRES),CTEMP 
 200        FORMAT(7X,I4,2(1X,A1),2X,A1,1X,A7,2(I4),A1,I4,2(1X,I4),2X,A)
C fill up aliseq
            IF (I .GE. ICHAINBEG .AND. I .LE. ICHAINEND) THEN
               IRES=IRES+1
               IF (PDBSEQ(I) .NE. '!') THEN
	          CALL STRPOS(CTEMP,IBEG,IEND)
                  DO IPOS=MAX(IBEG,1),MIN(NBLOCKSIZE,IEND)
	             IALI=IALIGN+IPOS
                     IF (CTEMP(IPOS:IPOS) .NE. ' '.AND.
     +                   IPOINTER(IALI) .GT. 0) THEN
			IF (IPOINTER(IALI) .LE. 0 ) THEN
			   WRITE(6,*)'*** READHSSP: ipointer=',
     +                          ipointer(iali),
     +                          'iali,ialign,ipos=',iali,ialign,ipos
			ENDIF
                        J=ALIPOINTER(IPOINTER(IALI)) + 
     +                       (I-IFIR(IPOINTER(IALI)))
                        ALISEQ(J)=CTEMP(IPOS:IPOS)
	             ENDIF
	          ENDDO
               ENDIF
            ENDIF
         ENDDO
         IALIGN=IALIGN+NBLOCKSIZE
         DO K=1,2
            READ(IUNIT,'(A)',ERR=99)LINE
         ENDDO
      ENDDO
      WRITE(6,*)'   ALIGNMENTS block done'
C read in sequence profile, entropy etc.
      IRES=1
      DO I=1,NRES
         READ(IUNIT,300,ERR=99)(SEQPROF(IRES,K),K=1,MAXAA),
     +        NOCC(IRES),NDEL(IRES),NINS(IRES),ENTROPY(IRES),
     +        RELENT(IRES),CONSWEIGHT(IRES)
         IF (I .GE. ICHAINBEG .AND. I .LE. ICHAINEND) THEN
            IRES=IRES+1
         ENDIF
      ENDDO
 300  FORMAT(12X,20(I4),1X,3(1X,I4),1X,F7.3,3X,I4,2X,F4.2)
      WRITE(6,*)'   PROFILE    block done'
      IF (LCHAIN) THEN
         DO I=1,NALIGN
            IFIR(I)=IFIR(I)-ICHAINBEG+1
            ILAS(I)=ILAS(I)-ICHAINBEG+1
         ENDDO
      ENDIF
C read the insertion list
COLD check if next line (last line in a HSSP-file) contains a '//'
      READ(IUNIT,'(A)',ERR=99)LINE
      IF (INDEX (LINE,'## INSERTION') .NE. 0) THEN
         READ(IUNIT,'(A)',ERR=99)LINE
         READ(IUNIT,'(A)',ERR=99)LINE
         IINS=0
         IPOINT=1
         DO WHILE (LINE(1:2) .NE. '//')
	    CALL STRPOS(LINE,IBEG,IEND)
            IF (LINE(6:6) .NE. '+') THEN
               IF (IINS+1 .GT. MAXINS) THEN
                  WRITE(6,*)'*** ERROR: MAXINS OVERFLOW, INCREASE !'
                  GOTO 99
               ENDIF
               IINS=IINS+1
               INSPOINTER(IINS)=IPOINT
               READ(LINE,'(4(I6))')INSALI(IINS),INSBEG_1(IINS),
     +              INSBEG_2(IINS),INSLEN(IINS)
               
               IF (IPOINT + INSLEN(IINS)+3 .GT. MAXINSBUFFER) THEN
                  WRITE(6,*)
     +                 '*** ERROR: MAXINSBUFFER overflow, increase !'
                  GOTO 99
c	      else
c	        insbuffer(ipoint:)=line(26:iend)
c                ipoint=ipoint+inslen(iins)+3
               ENDIF
c	    else
c	      call strpos(insbuffer,ipos,jpos)
c	      insbuffer(jpos+1:)=line(26:iend)
	    ENDIF
c changed
	    DO I=26,IEND
               INSBUFFER(IPOINT)=LINE(I:I)
	       IPOINT=IPOINT+1
	    ENDDO
c end change
	    READ(IUNIT,'(A)',ERR=99)LINE
         ENDDO
         WRITE(6,*)'   INSERTION  list  done'
         INSNUMBER=IINS
      ELSE IF (LINE(1:2) .NE. '//') THEN
         WRITE(6,'(A,A)')'*** READHSSP: missing line "//"'
         GOTO 99
      ENDIF
      CLOSE(IUNIT)
      CALL STRPOS(HSSPFILE,IBEG,IEND)
      WRITE(6,'(A,A,A)')' ReadHSSP: ',HSSPFILE(IBEG:IEND),' OK' 

      RETURN

 99   WRITE(6,'(A,A)')'*** ERROR in READHSSP reading: ',HSSPFILE
      ERROR=.TRUE.
      NALIGN=0
      SEQLENGTH=0
      RETURN
      END
C     END READHSSP
C......................................................................

C......................................................................
C     SUB READPROFILE
      SUBROUTINE READPROFILE(KPROF,PROFILENAME,MAXRES,NTRANS,TRANS,
     +     LDSSP,NRES,NCHAIN,HSSPID,HEADER,COMPOUND,SOURCE,
     +     AUTHOR,SMIN,SMAX,MAPLOW,MAPHIGH,METRICFILE,PDBNO,
     +     CHAINID,SEQ,STRUC,ACC,COLS,SHEETLABEL,BP1,BP2,
     +     NOCC,GAPOPEN,GAPELONG,CONSWEIGHT,PROFILEMETRIC,
     +     MAXBOX,NBOX,PROFILEBOX)
      IMPLICIT        NONE

C order of amino acids
      INTEGER         NTRANS
      CHARACTER*(*)   TRANS
      LOGICAL         LDSSP
      INTEGER         NACID
      PARAMETER      (NACID=                    20)
      INTEGER         KPROF,MAXRES,NRES,ACC(MAXRES),BP1(MAXRES),
     +                BP2(MAXRES),NOCC(MAXRES),NCHAIN,PDBNO(MAXRES)
      REAL            PROFILEMETRIC(MAXRES,NTRANS),GAPOPEN(MAXRES),
     +                GAPELONG(MAXRES),CONSWEIGHT(MAXRES),
     +                SMIN,SMAX,MAPLOW,MAPHIGH
      CHARACTER*(*)   HSSPID,HEADER,COMPOUND,SOURCE,AUTHOR,METRICFILE,
     +                PROFILENAME,SEQ(MAXRES),STRUC(MAXRES),
     +                CHAINID(MAXRES)
      CHARACTER*7     COLS(MAXRES)
      CHARACTER*1     SHEETLABEL(MAXRES)
      CHARACTER*300   LINE
      INTEGER         MAXBOX,NBOX,PROFILEBOX(MAXBOX,2)
C internal
      INTEGER         I,J,K,IBOX
      CHARACTER       CDIVIDE1,CDIVIDE2
      LOGICAL         LERROR
*----------------------------------------------------------------------*
C init
      LDSSP=.FALSE.
      LINE=' '
      CDIVIDE1=':'
      CDIVIDE2='-'
      SMIN=0.0
      SMAX=0.0
      MAPLOW=0.0
      MAPHIGH=0.0
      DO I=1,MAXRES 
         PDBNO(I)=0
         CHAINID(I)=' '
         SEQ(I)=' '
         STRUC(I)=' '
         COLS(I)=' '
         BP1(I)=0 
         BP2(I)=0
         SHEETLABEL(I)=' '
         ACC(I)=0
         NOCC(I)=0
         GAPOPEN(I)=0.0
         GAPELONG(I)=0.0
         CONSWEIGHT(I)=0.0
         DO J=1,NTRANS
            PROFILEMETRIC(I,J)=0.0
         ENDDO
      ENDDO
      NBOX=1
      DO I=1,MAXBOX
         PROFILEBOX(I,1)=0 
         PROFILEBOX(I,2)=0
      ENDDO
C======================================================================
      CALL OPEN_FILE(KPROF,PROFILENAME,'OLD,RECL=2000,readonly',
     +     LERROR)

      READ(KPROF,'(A)')LINE
      IF (INDEX(LINE,'-PROFILE').EQ.0) THEN
         WRITE(6,'(A,A)')
     +    '*** ERROR: file is not a proper MAXHOM-PROFILE: ',profilename
         STOP
      ELSE
         IF (INDEX(LINE,'SECONDARY').NE.0) THEN
            LDSSP=.TRUE.
         ENDIF
      ENDIF
C search for keywords
C "SMIN" and "SMAX" scale metric
C "MAPLOW" and "MAPHIGH"
C      if MAPLOW and MAPHIGH are specified the profile is rescaled
C      such that the profile values are mapped between MAPLOW and
C      MAPHIGH to ingnore outsider values
C      (fx. MAPHIGH=mean-value + standart-deviation)
      DO WHILE(INDEX(LINE,'SeqNo  PDBNo AA STRUCTURE BP1 BP2').EQ.0)
         LINE=' '
         READ(KPROF,'(A)')LINE
c	   read(kprof,'(a)',end=999)line
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'ID',HSSPID)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'HEADER',HEADER)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'COMPOUND',COMPOUND)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'SOURCE',SOURCE)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'AUTHOR',AUTHOR)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'METRIC',METRICFILE)
         CALL EXTRACT_INTEGER(LINE,CDIVIDE1,'NRES',NRES)
         CALL EXTRACT_INTEGER(LINE,CDIVIDE1,'NCHAIN',NCHAIN)
         CALL EXTRACT_INTEGER(LINE,CDIVIDE1,'NBOX',NBOX)
         CALL EXTRACT_REAL(LINE,CDIVIDE1,'SMIN',SMIN)
         CALL EXTRACT_REAL(LINE,CDIVIDE1,'SMAX',SMAX)
         CALL EXTRACT_REAL(LINE,CDIVIDE1,'MAPLOW',MAPLOW)
         CALL EXTRACT_REAL(LINE,CDIVIDE1,'MAPHIGH',MAPHIGH)
      ENDDO
C read BOX definition
      IF (NBOX .GT. 1) THEN
         REWIND(KPROF)
         LINE=' '
         IBOX=0
         DO WHILE(INDEX(LINE,'SeqNo  PDBNo AA STRUCTURE BP1 BP2').EQ.0)
	    LINE=' '
	    READ(KPROF,'(A)',END=999)LINE
	    IF (LINE(1:3).EQ.'BOX') THEN
               IBOX=IBOX+1
               CALL EXTRACT_INTEGER_RANGE(LINE,CDIVIDE1,CDIVIDE2,
     +              PROFILEBOX(IBOX,1))
	    ENDIF
         ENDDO
         IF (IBOX .NE. NBOX) THEN
            WRITE(6,*)' ERROR: number of boxes does not match number'//
     +           ' of box specification'
	    WRITE(6,*)NBOX,IBOX
	    STOP
         ENDIF
      ELSE
         PROFILEBOX(NBOX,1)=1
         PROFILEBOX(NBOX,2)=NRES
      ENDIF
      LINE=' '
      I=0
      READ(KPROF,'(A)')LINE
      DO WHILE(LINE(1:2).NE.'//')
         I=I+1
         IF (I.GT.MAXRES) THEN
            WRITE(6,'(A)')
     +           ' *** ERROR IN READROFILE: NRES.GT.MAXRES'
             STOP
          ENDIF
c	WRITE(6,*)line
c           read(line,100,end=999)pdbno(i),chainid(i),seq(i),
c     +          struc(i),cols(i),bp1(i),bp2(i),sheetlabel(i),acc(i),
c     +	        nocc(i),gapopen(i),gapelong(i),consweight(i),
c     +	        (profilemetric(i,j),j=1,nacid)
c           read(line,100,err=999,end=999)pdbno(i),chainid(i),seq(i),
          READ(LINE,100)PDBNO(I),CHAINID(I),SEQ(I),
     +         STRUC(I),COLS(I),BP1(I),BP2(I),SHEETLABEL(I),ACC(I),
     +         NOCC(I),GAPOPEN(I),GAPELONG(I),CONSWEIGHT(I),
     +         (PROFILEMETRIC(I,J),J=1,NACID)
 100      FORMAT(6X,1X,I4,1X,A1,1X,A1,2X,A1,1X,A7,2(I4),A1,2(I4,1X),
     +         2(F6.2),F7.2,20(F8.3))
          READ(KPROF,'(A)')LINE
       ENDDO
       IF (I .NE. NRES) THEN
          WRITE(6,*) ' ********************************************'
          WRITE(6,*) ' FATAL ERROR'
          WRITE(6,*) ' Heee, number of positions read in is: ',i
          WRITE(6,*) ' NRES in Header is: ',nres
	  STOP
       ENDIF
       CLOSE(KPROF)
C add 'B' 'Z' 'X' '!' '-' '.'
       I=INDEX(TRANS,'N')
       J=INDEX(TRANS,'B')
       DO K=1,NRES
          PROFILEMETRIC(K,J)=PROFILEMETRIC(K,I)
       ENDDO
       I=INDEX(TRANS,'Q')
       J=INDEX(TRANS,'Z')
       DO K=1,NRES
          PROFILEMETRIC(K,J)=PROFILEMETRIC(K,I)
       ENDDO
       RETURN
C read error
 999   CLOSE(KPROF)
       WRITE(6,*)'*** ERROR: read error in MAXHOM-PROFILE'
       NRES=0
       RETURN
       END
C     END READPROFILE
C......................................................................
C......................................................................
C     SUB READ_SSSA_PROFILE
      SUBROUTINE READ_SSSA_PROFILE(KPROF,PROFILENAME,MAXRES,
     +     NTRANS,TRANS,NSTRUCTRANS,NACCTRANS,
     +     LDSSP,NRES,NCHAIN,HSSPID,HEADER,COMPOUND,SOURCE,
     +     AUTHOR,SMIN,SMAX,MAPLOW,MAPHIGH,METRICFILE,PDBNO,
     +     CHAINID,SEQ,STRUC,ACC,COLS,SHEETLABEL,BP1,BP2,
     +     NOCC,GAPOPEN,GAPELONG,CONSWEIGHT,PROFILEMETRIC,
     +     MAXBOX,NBOX,PROFILEBOX)
      IMPLICIT NONE

C order of amino acids
      INTEGER       NTRANS
      INTEGER       NSTRUCTRANS,NACCTRANS,NACID
      CHARACTER*(*) TRANS
      LOGICAL       LDSSP
      INTEGER	    NSTATES
C      PARAMETER    (NSTATES=120)
      PARAMETER     (NACID=20)

      INTEGER       KPROF,MAXRES,NRES,ACC(MAXRES),BP1(MAXRES),
     +              BP2(MAXRES),NOCC(MAXRES),NCHAIN,PDBNO(MAXRES)
      REAL          PROFILEVECTOR(200)
      INTEGER       LAA(200),LSS(200),LSA(200)
      REAL          PROFILEMETRIC(MAXRES,NTRANS,NSTRUCTRANS,NACCTRANS),
     +              GAPOPEN(MAXRES),
     +              GAPELONG(MAXRES),CONSWEIGHT(MAXRES),
     +              SMIN,SMAX,MAPLOW,MAPHIGH
      CHARACTER*(*) HSSPID,HEADER,COMPOUND,SOURCE,AUTHOR,METRICFILE,
     +              PROFILENAME,SEQ(MAXRES),STRUC(MAXRES),
     +              CHAINID(MAXRES)
      CHARACTER*7   COLS(MAXRES)
      CHARACTER*1   SHEETLABEL(MAXRES)
      CHARACTER*1500 LINE
      INTEGER       MAXBOX,NBOX,PROFILEBOX(MAXBOX,2)
C internal
      INTEGER       I,J,K,M,N,IBOX,SIZE1,SIZE2,REST1,REST2,MODULO
      CHARACTER     CDIVIDE1,CDIVIDE2
      LOGICAL       LERROR
 
C init
      NSTATES=NTRANS*NSTRUCTRANS*NACCTRANS
C checking if number of places specifiled in format below is not too few
      
      IF (NSTATES .GE. 200) THEN
        WRITE(*,*) '*** ERROR: PROFILE format needs to be increased'
        STOP
      ENDIF
      
      MODULO=NSTRUCTRANS*NACCTRANS
      DO K=1,NSTATES
         REST1=MOD(K,MODULO)
         REST2=MOD(REST1,NACCTRANS)
         SIZE2=INT( REST1/NACCTRANS )
         SIZE1=INT( K/MODULO )
         IF(REST1 .EQ. 0) THEN
            LSA(K)=NACCTRANS
            LSS(K)=NSTRUCTRANS
            LAA(K)=SIZE1
         ELSEIF(REST2 .EQ. 0) THEN
            LSA(K)=NACCTRANS
            LSS(K)=SIZE2
            LAA(K)=SIZE1+1
         ELSE 
            LSA(K)=REST2
            LSS(K)=SIZE2+1
            LAA(K)=SIZE1+1
         ENDIF
      ENDDO
 

      LDSSP=.FALSE.
      LINE=' '
      CDIVIDE1=':'
      CDIVIDE2='-'
      SMIN=0.0
      SMAX=0.0
      MAPLOW=0.0
      MAPHIGH=0.0
      DO I=1,MAXRES 
         PDBNO(I)=0
         CHAINID(I)=' '
         SEQ(I)=' '
         STRUC(I)=' '
         COLS(I)=' '
         BP1(I)=0 
         BP2(I)=0
         SHEETLABEL(I)=' '
         ACC(I)=0
         NOCC(I)=0
         GAPOPEN(I)=0.0
         GAPELONG(I)=0.0
         CONSWEIGHT(I)=0.0
         DO J=1,NTRANS
            DO M=1,NSTRUCTRANS
               DO N=1,NACCTRANS
                  PROFILEMETRIC(I,J,M,N)=0.0
               ENDDO
            ENDDO
         ENDDO
      ENDDO
      NBOX=1
      DO I=1,MAXBOX
         PROFILEBOX(I,1)=0 
         PROFILEBOX(I,2)=0
      ENDDO
C======================================================================
      CALL OPEN_FILE(KPROF,PROFILENAME,'OLD,RECL=2000,readonly',
     +     LERROR)

      READ(KPROF,'(A)')LINE
      IF (INDEX(LINE,'-PROFILE').EQ.0) THEN
         WRITE(*,'(A,A)')
     +    '*** ERROR: file is not a proper MAXHOM-PROFILE: ',profilename
         STOP
      ELSEIF (INDEX(LINE,'ACCESSIBILITY').EQ.0) THEN
         WRITE(*,'(A,A)')
     +    '*** ERROR: file is not a proper SSSA PROFILE: ',profilename
         STOP  
C      ELSE
C         IF (INDEX(LINE,'SECONDARY').NE.0) THEN
C            LDSSP=.TRUE.
C         ENDIF
      ENDIF
C search for keywords
C "SMIN" and "SMAX" scale metric
C "MAPLOW" and "MAPHIGH"
C      if MAPLOW and MAPHIGH are specified the profile is rescaled
C      such that the profile values are mapped between MAPLOW and
C      MAPHIGH to ingnore outsider values
C      (fx. MAPHIGH=mean-value + standart-deviation)
      DO WHILE(INDEX(LINE,'SeqNo  PDBNo AA STRUCTURE BP1 BP2').EQ.0)
         LINE=' '
         READ(KPROF,'(A)')LINE
c	   read(kprof,'(a)',end=999)line
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'ID',HSSPID)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'HEADER',HEADER)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'COMPOUND',COMPOUND)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'SOURCE',SOURCE)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'AUTHOR',AUTHOR)
         CALL EXTRACT_STRING(LINE,CDIVIDE1,'METRIC',METRICFILE)
         CALL EXTRACT_INTEGER(LINE,CDIVIDE1,'NRES',NRES)
         CALL EXTRACT_INTEGER(LINE,CDIVIDE1,'NCHAIN',NCHAIN)
         CALL EXTRACT_INTEGER(LINE,CDIVIDE1,'NBOX',NBOX)
         CALL EXTRACT_REAL(LINE,CDIVIDE1,'SMIN',SMIN)
         CALL EXTRACT_REAL(LINE,CDIVIDE1,'SMAX',SMAX)
         CALL EXTRACT_REAL(LINE,CDIVIDE1,'MAPLOW',MAPLOW)
         CALL EXTRACT_REAL(LINE,CDIVIDE1,'MAPHIGH',MAPHIGH)
      ENDDO
C read BOX definition
      IF (NBOX .GT. 1) THEN
         REWIND(KPROF)
         LINE=' '
         IBOX=0
         DO WHILE(INDEX(LINE,'SeqNo  PDBNo AA STRUCTURE BP1 BP2').EQ.0)
	    LINE=' '
	    READ(KPROF,'(A)',END=999)LINE
	    IF (LINE(1:3).EQ.'BOX') THEN
               IBOX=IBOX+1
               CALL EXTRACT_INTEGER_RANGE(LINE,CDIVIDE1,CDIVIDE2,
     +              PROFILEBOX(IBOX,1))
	    ENDIF
         ENDDO
         IF (IBOX .NE. NBOX) THEN
            write(*,*)' ERROR: number of boxes does not match number'//
     +           ' of box specification'
	    WRITE(*,*)NBOX,IBOX
	    STOP
         ENDIF
      ELSE
         PROFILEBOX(NBOX,1)=1
         PROFILEBOX(NBOX,2)=NRES
      ENDIF
      LINE=' '
      I=0
      READ(KPROF,'(A)')LINE
      DO WHILE(LINE(1:2).NE.'//')
         I=I+1
         IF (I.GT.MAXRES) THEN
            WRITE(*,'(A)')
     +           ' *** ERROR IN READROFILE: NRES.GT.MAXRES'
             STOP
          ENDIF   
c	write(*,*)line
c           read(line,100,end=999)pdbno(i),chainid(i),seq(i),
c     +          struc(i),cols(i),bp1(i),bp2(i),sheetlabel(i),acc(i),
c     +	        nocc(i),gapopen(i),gapelong(i),consweight(i),
c     +	        (profilemetric(i,j),j=1,nacid)
c           read(line,100,err=999,end=999)pdbno(i),chainid(i),seq(i),
C          WRITE(6,*)'LINE ',LINE
          READ(LINE,100)PDBNO(I),CHAINID(I),SEQ(I),
     +         STRUC(I),COLS(I),BP1(I),BP2(I),SHEETLABEL(I),ACC(I),
     +         NOCC(I),GAPOPEN(I),GAPELONG(I),CONSWEIGHT(I),
     +         (PROFILEVECTOR(J),J=1,NSTATES)
 100      FORMAT(6X,1X,I4,1X,A1,1X,A1,2X,A1,1X,A7,2(I4),A1,I4,1X,I4,1X,
     +         2(F6.2),F7.2,200(F8.3))
          
C          WRITE(6,*)' info:READ_SSSA_PROFILE, I, ACC',I,ACC(I)
C     assigning values to 4-dim profile array (expensive, should be done better in FORMAT statement for example, or otherwise!!! D.P.)
          DO K=1,NSTATES
             J=LAA(K)
             M=LSS(K)
             N=LSA(K)
             PROFILEMETRIC(I,J,M,N)=PROFILEVECTOR(K)
C             WRITE(6,*)' infor:PROFILEVECTOR ',PROFILEVECTOR(K)
C             IF(PROFILEMETRIC(I,J,M,N) .NE. 0) 
C             WRITE(6,*)'K,PROFILEVECTOR(K) ',K,PROFILEVECTOR(K)
C             WRITE(6,*) 
C     +                 'K,SEQ,I,J,M,N,PROFILE ',K,' ',SEQ(I),I,J,
C     +                   M,N,PROFILEMETRIC(I,J,M,N),'****'

          ENDDO
          
          READ(KPROF,'(A)')LINE
       ENDDO
      
       IF (I .NE. NRES) THEN
          write(*,*) ' ********************************************'
          write(*,*) ' FATAL ERROR'
          write(*,*) ' Heee, number of positions read in is: ',i
          write(*,*) ' NRES in Header is: ',nres
	  STOP
       ENDIF
       CLOSE(KPROF)
C add 'B' 'Z' 'X' '!' '-' '.'
       I=INDEX(TRANS,'N')
       J=INDEX(TRANS,'B')
       DO K=1,NRES
          DO M=1,NSTRUCTRANS
             DO N=1,NACCTRANS
                PROFILEMETRIC(K,J,M,N)=PROFILEMETRIC(K,I,M,N)
             ENDDO
          ENDDO
       ENDDO
       I=INDEX(TRANS,'Q')
       J=INDEX(TRANS,'Z')
       DO K=1,NRES
          DO M=1,NSTRUCTRANS
             DO N=1,NACCTRANS
                PROFILEMETRIC(K,J,M,N)=PROFILEMETRIC(K,I,M,N)
             ENDDO
          ENDDO
       ENDDO
       RETURN
C read error
 999   CLOSE(KPROF)
       write(*,*)'*** ERROR: read error in MAXHOM-PROFILE'
       NRES=0
       RETURN
       END
C     END READ_SSSA_PROFILE
C......................................................................

C......................................................................
C     SUB RECEIVE_DATA_FROM_HOST
      SUBROUTINE RECEIVE_DATA_FROM_HOST(ILINK)
C node routine: get all relevant information about sequence 1 and 
C               control flow
C
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
      INTEGER ILINK
C internal
      CHARACTER   CPARSYTEC_BUG*(MAXSQ)
      INTEGER ISIZE,I
      INTEGER ILBACKWARD,ILINSERT_2,ILISTOFSEQ_2,ILSHOW_SAMESEQ,
     +     ILSWISSBASE,ILDSSP_1,ILCONSERV_1,ILCONSERV_2,
     +     ILCONSIMPORT,ILALL,ILFORMULA,ILTHRESHOLD,
     +     ILCOMPSTR,ILPASS2,ILTRACE,ILONG_OUT,ILBATCH,
     +     I3WAY,I3WAYDONE,IWARM_START,IBINARY
C     INTEGER ILMIXED_ARCH,
C init logicals
      ILBACKWARD=0 
      ILINSERT_2=0 
      ILISTOFSEQ_2=0
      ILSHOW_SAMESEQ=0 
      ILSWISSBASE=0 
      ILDSSP_1=0 
      ILCONSERV_1=0
      ILCONSERV_2=0 
      ILCONSIMPORT=0 
      ILALL=0 
      ILFORMULA=0
      ILTHRESHOLD=0 
      ILCOMPSTR=0 
      ILPASS2=0 
      ILTRACE=0
      ILONG_OUT=0 
      ILBATCH=0
C     ILMIXED_ARCH=0
      I3WAY=0 
      I3WAYDONE=0 
      IWARM_START=0
      LBACKWARD = .FALSE. 
      LINSERT_2 = .FALSE.
      LISTOFSEQ_2 = .FALSE. 
      LSHOW_SAMESEQ = .FALSE.
      LSWISSBASE = .FALSE. 
      LDSSP_1 = .FALSE. 
      LCONSERV_1 = .FALSE.
      LCONSERV_2 = .FALSE. 
      LCONSIMPORT = .FALSE. 
      LALL = .FALSE.
      LFORMULA = .FALSE. 
      LTHRESHOLD = .FALSE. 
      LCOMPSTR = .FALSE.
      LPASS2 = .FALSE. 
      LTRACE = .FALSE. 
      LONG_OUT = .FALSE.
      LBATCH = .FALSE. 
      L3WAY=.FALSE.
      L3WAYDONE=.FALSE. 
      LWARM_START=.FALSE. 
      LBINARY=.FALSE.
C     LMIXED_ARCH=.FALSE. 
C     INIT


      WRITE(6,*)' receive data start 1: ',idproc
      CALL FLUSH_UNIT(6)

      MSGTYPE=1
c     if (mp_model .eq. 'PARIX') then ; msgtype=idtop ; endif


      CALL MP_RECEIVE_DATA(MSGTYPE,LINK(ID_HOST))
      CALL MP_GET_INT4(MSGTYPE,ILINK,ID_HOST,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,ILINK,N1,N_ONE)
      IF (N1 .GT. 0) THEN
         ISIZE=N1
         CALL MP_GET_INT4_ARRAY(MSGTYPE,ILINK,LSQ_1,ISIZE)
         CALL MP_GET_INT4_ARRAY(MSGTYPE,ILINK,LSTRUC_1,ISIZE)
         CALL MP_GET_INT4_ARRAY(MSGTYPE,ILINK,LSTRCLASS_1,ISIZE)
         CALL MP_GET_INT4_ARRAY(MSGTYPE,ILINK,LACC_1,ISIZE)
         ISIZE=MAXBREAK
         CALL MP_GET_INT4_ARRAY(MSGTYPE,ILINK,IBREAKPOS_1,ISIZE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,NBREAK_1,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,NBEST,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,IPROFBEG,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,IPROFEND,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,PROFILEMODE,N_ONE)
         ISIZE=NASCII
         CALL MP_GET_INT4_ARRAY(MSGTYPE,ILINK,TRANSPOS,ISIZE)
         ISIZE=MAXCUTOFFSTEPS
         CALL MP_GET_INT4_ARRAY(MSGTYPE,ILINK,ISOLEN,ISIZE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,NSTEP,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ISAFE,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,NSTRSTATES_1,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,NSTRSTATES_2,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,NIOSTATES_1,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,NIOSTATES_2,N_ONE)
         ISIZE=N1
         CALL MP_GET_INT4_ARRAY(MSGTYPE,ILINK,PDBNO_1,ISIZE)
         ISIZE=MAXCUTOFFSTEPS
         CALL MP_GET_REAL4_ARRAY(MSGTYPE,ILINK,ISOIDE,ISIZE)
         ISIZE=N1
         CALL MP_GET_REAL4_ARRAY(MSGTYPE,ILINK,GAPOPEN_1,ISIZE)
         CALL MP_GET_REAL4_ARRAY(MSGTYPE,ILINK,GAPELONG_1,ISIZE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,OPEN_1,N_ONE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,ELONG_1,N_ONE)
         CALL MP_GET_REAL4_ARRAY(MSGTYPE,ILINK,CONSWEIGHT_1,ISIZE)
         ISIZE=MAXSQ*NTRANS
         CALL MP_GET_REAL4_ARRAY(MSGTYPE,ILINK,SIMMETRIC_1,ISIZE)
         IF (PROFILEMODE .EQ. 6) THEN
            ISIZE= NTRANS * NTRANS * MAXSTRSTATES * MAXIOSTATES * 
     +           MAXSTRSTATES*MAXIOSTATES
            CALL MP_GET_REAL4_ARRAY(MSGTYPE,ILINK,SIMORG,ISIZE)
         ENDIF
         CALL MP_GET_REAL4(MSGTYPE,ILINK,FILTER_VAL,N_ONE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,PUNISH,N_ONE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,CUTVALUE1,N_ONE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,CUTVALUE2,N_ONE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,SMIN,N_ONE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,SMAX,N_ONE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,MAPLOW,N_ONE)
         CALL MP_GET_REAL4(MSGTYPE,ILINK,MAPHIGH,N_ONE)
         ISIZE=MAXSTRSTATES*MAXIOSTATES
         CALL MP_GET_REAL4_ARRAY(MSGTYPE,ILINK,IORANGE,ISIZE)
         
         ISIZE=LEN(MP_MODEL)
         CALL MP_GET_STRING(MSGTYPE,ILINK,MP_MODEL,ISIZE)
         ISIZE=LEN(SPLIT_DB_PATH)
         CALL MP_GET_STRING(MSGTYPE,ILINK,SPLIT_DB_PATH,ISIZE)
         ISIZE=LEN(SPLIT_DB_DATA)
         CALL MP_GET_STRING(MSGTYPE,ILINK,SPLIT_DB_DATA,ISIZE)
         ISIZE=LEN(SWISSPROT_SEQ)
         CALL MP_GET_STRING(MSGTYPE,ILINK,SWISSPROT_SEQ,ISIZE)
         ISIZE=LEN(LISTFILE_2)
         CALL MP_GET_STRING(MSGTYPE,ILINK,LISTFILE_2,ISIZE)
         ISIZE=LEN(CSQ_1)
         CALL MP_GET_STRING(MSGTYPE,ILINK,CSQ_1,ISIZE)

c	isize=MAXSQ
c	call mp_get_string_array(msgtype,ilink,struc_1,isize)
c	call mp_get_string_array(msgtype,ilink,chainid_1,isize)

         ISIZE=N1
         CALL MP_GET_STRING(MSGTYPE,ILINK,CPARSYTEC_BUG,ISIZE)
         DO I=1,N1
            STRUC_1(I)=CPARSYTEC_BUG(I:I)
         ENDDO
         CALL MP_GET_STRING(MSGTYPE,ILINK,CPARSYTEC_BUG,ISIZE)
         DO I=1,N1
            CHAINID_1(I)=CPARSYTEC_BUG(I:I)
         ENDDO
         
         ISIZE=LEN(OPENWEIGHT_ANSWER)
         CALL MP_GET_STRING(MSGTYPE,ILINK,OPENWEIGHT_ANSWER,ISIZE)
         ISIZE=LEN(ELONGWEIGHT_ANSWER)
         CALL MP_GET_STRING(MSGTYPE,ILINK,ELONGWEIGHT_ANSWER,ISIZE)
         ISIZE=LEN(SMIN_ANSWER)
         CALL MP_GET_STRING(MSGTYPE,ILINK,SMIN_ANSWER,ISIZE)
         ISIZE=LEN(NAME_1)
         CALL MP_GET_STRING(MSGTYPE,ILINK,NAME_1,ISIZE)
         ISIZE=LEN(HSSPID_2)
         CALL MP_GET_STRING(MSGTYPE,ILINK,HSSPID_2,ISIZE)
         
         
         ISIZE=LEN(CSORTMODE)
         CALL MP_GET_STRING(MSGTYPE,ILINK,CSORTMODE,ISIZE)
         ISIZE=LEN(METRICFILE)
         CALL MP_GET_STRING(MSGTYPE,ILINK,METRICFILE,ISIZE)
         ISIZE=LEN(CURRENT_DIR)
         CALL MP_GET_STRING(MSGTYPE,ILINK,CURRENT_DIR,ISIZE)
         ISIZE=LEN(DSSP_PATH)
         CALL MP_GET_STRING(MSGTYPE,ILINK,DSSP_PATH,ISIZE)
         ISIZE=LEN(PDBPATH)
         CALL MP_GET_STRING(MSGTYPE,ILINK,PDBPATH,ISIZE)
         ISIZE=LEN(PLOTFILE)
         CALL MP_GET_STRING(MSGTYPE,ILINK,PLOTFILE,ISIZE)
         
         ISIZE=LEN(COREPATH)
         CALL MP_GET_STRING(MSGTYPE,ILINK,COREPATH,ISIZE)
         ISIZE=LEN(COREFILE)
         CALL MP_GET_STRING(MSGTYPE,ILINK,COREFILE,ISIZE)
         ISIZE=LEN(TRANS)
         CALL MP_GET_STRING(MSGTYPE,ILINK,TRANS,ISIZE)
         ISIZE=LEN(STRTRANS)
         CALL MP_GET_STRING(MSGTYPE,ILINK,STRTRANS,ISIZE)
         ISIZE=LEN(CSTRSTATES)
         CALL MP_GET_STRING(MSGTYPE,ILINK,CSTRSTATES,ISIZE)
         ISIZE=LEN(CIOSTATES)
         CALL MP_GET_STRING(MSGTYPE,ILINK,CIOSTATES,ISIZE)
         DO I=1,MAXSTRSTATES
            ISIZE=LEN(STR_CLASSES(I))
            CALL MP_GET_STRING(MSGTYPE,ILINK,STR_CLASSES(I),ISIZE)
         ENDDO

C     CALL MP_GET_INT4(MSGTYPE,ILINK,ILMIXED_ARCH,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILBACKWARD,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILINSERT_2,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILISTOFSEQ_2,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILSHOW_SAMESEQ,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILSWISSBASE,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILDSSP_1,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILCONSERV_1,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILCONSERV_2,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILCONSIMPORT,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILALL,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILFORMULA,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILTHRESHOLD,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILCOMPSTR,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILPASS2,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILTRACE,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILONG_OUT,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,ILBATCH,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,I3WAY,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,I3WAYDONE,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,IWARM_START,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,ILINK,IBINARY,N_ONE)
         
C     IF ( ILMIXED_ARCH   .EQ. 1 )LMIXED_ARCH   = .TRUE.
         IF ( ILBACKWARD     .EQ. 1 )LBACKWARD     = .TRUE.
         IF ( ILINSERT_2     .EQ. 1 )LINSERT_2     = .TRUE.
         IF ( ILISTOFSEQ_2   .EQ. 1 )LISTOFSEQ_2   = .TRUE.
         IF ( ILSHOW_SAMESEQ .EQ. 1 )LSHOW_SAMESEQ = .TRUE.
         IF ( ILSWISSBASE    .EQ. 1 )LSWISSBASE    = .TRUE.
         IF ( ILDSSP_1       .EQ. 1 )LDSSP_1       = .TRUE.
         IF ( ILCONSERV_1    .EQ. 1 )LCONSERV_1    = .TRUE.
         IF ( ILCONSERV_2    .EQ. 1 )LCONSERV_2    = .TRUE.
         IF ( ILCONSIMPORT   .EQ. 1 )LCONSIMPORT   = .TRUE.
         IF ( ILALL          .EQ. 1 )LALL          = .TRUE.
         IF ( ILFORMULA      .EQ. 1 )LFORMULA      = .TRUE.
         IF ( ILTHRESHOLD    .EQ. 1 )LTHRESHOLD    = .TRUE.
         IF ( ILCOMPSTR      .EQ. 1 )LCOMPSTR      = .TRUE.
         IF ( ILPASS2        .EQ. 1 )LPASS2        = .TRUE.
         IF ( ILTRACE        .EQ. 1 )LTRACE        = .TRUE.
         IF ( ILONG_OUT      .EQ. 1 )LONG_OUT      = .TRUE.
         IF ( ILBATCH        .EQ. 1 )LBATCH        = .TRUE.
         IF ( I3WAY          .EQ. 1 )L3WAY         = .TRUE.
         IF ( I3WAYDONE      .EQ. 1 )L3WAYDONE     = .TRUE.
         IF ( IWARM_START    .EQ. 1 )LWARM_START   = .TRUE.
         IF ( IBINARY        .EQ. 1 )LBINARY       = .TRUE.
      ENDIF

      WRITE(6,*)' receive data OK: ',idproc
      CALL FLUSH_UNIT(6)
	
      RETURN
      END
C     END RECEIVE_DATA_FROM_HOST
C......................................................................

C......................................................................
C     SUB REPORTPIECES
      SUBROUTINE REPORTPIECES
      PARAMETER      (MXPIECES=                 50)
      COMMON/CPIECE/IPRESPIE(2,2,MXPIECES),NPIECES,NRESPIE(2),
     +     NATMPIE(2)
      CALL CHECKRANGE(NPIECES,1,MXPIECES,'NPIECES   ','REPORTPIEC')
C IPRESPIE(1/2, molA/molB, IPIECE)
      WRITE(6,*)'------- you chose ---------'
      WRITE(6,'(I10,A10)') NPIECES,' pieces '
      WRITE(6,*)'---------------------------'
      WRITE(6,*)'     mol A          mol B'
      WRITE(6,*)' from...to      from...to  '
      WRITE(6,*)'----------------------------'
      DO IPIECE=1,NPIECES
         WRITE(6,'(I3,1x,2I5,5X,2I5)') IPIECE,
     +        ( (IPRESPIE(I,M,IPIECE),I=1,2), M=1,2)
C FOR IPIECE=1,NPIECES
      ENDDO
      WRITE(6,*)'----------------------------'
      RETURN
      END
C     END REPORTPIECES
C......................................................................

C......................................................................
C     SUB RightADJUST
      SUBROUTINE RIGHTADJUST(STRING,NDIM,NLEN)
C right-adjust of astring
      CHARACTER*(*) STRING
      INTEGER NDIM, NLEN, l,il
C find position of last non-blank
      IF (NDIM.LT.1.OR.NLEN.LT.1) RETURN
      IF (NDIM .gt. 1 ) STOP' update routine rightadjust'

      L=NLEN
      DO WHILE(STRING(L:L) .EQ. ' ' .AND. L .GT. 1)
         L=L-1
      ENDDO
      IF (L .LT. NLEN) THEN
C     L is position of last non-blank
         STRING(NLEN-L+1:NLEN)=STRING(1:L)
C fill rest with blanks from 1 to NLEN-L
         DO IL=1,NLEN-L
            STRING(IL:IL)=' '
         ENDDO
      ENDIF

c      DO I=1,NDIM  ! for each string
c        L=NLEN
c        DO WHILE(STRINGS(I)(L:L).EQ.' '.AND.L.GT.1)
c          L=L-1
c        ENDDO
c        IF (L.LT.NLEN) THEN
C L is position of last non-blank
c          STRINGS(I)(NLEN-L+1:NLEN)=STRINGS(I)(1:L)
C fill rest with blanks from 1 to NLEN-L
c          DO IL=1,NLEN-L
c            STRINGS(I)(IL:IL)=' '
c          ENDDO
c        ENDIF
c      ENDDO

      RETURN
      END
C     END RightADJUST
C......................................................................

C......................................................................
C     SUB S3TOS1
      SUBROUTINE S3TOS1(SEQ3,SEQ1,NRES)
C TRANSLATES A3 TO A1 AND VICE VERSA. CHRIS SANDER MAY 1983
C INPUT/OUTPUT
      CHARACTER SEQ3(*)*3,SEQ1(*)*1
      INTEGER NRES
C LOCAL
      CHARACTER AA3(24)*3, AA1(24)*1
      DATA AA3/'GLY','PRO','ASP','GLU','ALA','ASN','GLN','SER',
     +     'THR','LYS','ARG','HIS','VAL','ILE','MET','CYS',
     +     'LEU','PHE','TYR','TRP','ASX','GLX','---','!!!'/
      DATA AA1/'G','P','D','E','A','N','Q','S','T','K',
     +     'R','H','V','I','M','C','L','F','Y','W','B','Z','-','!'/
C    'X' OR 'XYZ' FOR NON-STANDARD OR UNKNOWN AMINO ACID RESIDUES
      DO I=1,NRES
         DO J=1,24
CD        WRITE(6,*)'S3TOS1: ',SEQ3(I),I,' =?= ',AA3(J),J
            IF (SEQ3(I).EQ.AA3(J)) THEN
               SEQ1(I)=AA1(J)
               GOTO 9
            ENDIF
         ENDDO
         SEQ1(I)='X'
         WRITE(6,100) SEQ3(I),SEQ1(I)
         WRITE(6,*)' legal residues are: '
         WRITE(6,*) (AA3(J),J=1,24)
 9       CONTINUE
      ENDDO
 100  FORMAT(' UNUSUAL RESIDUE NAME <',A3,'> TRANSLATED TO <',A1,'>')
C
c      ENTRY S1TOS3(SEQ3,SEQ1,NRES)
c      DO I=1,NRES
c        DO J=1,24
c        IF (SEQ1(I).EQ.AA1(J)) THEN
c          SEQ3(I)=AA3(J)
c        GOTO 99
c        ENDIF
c        ENDDO
c        SEQ3(I)='XYZ'
c        WRITE(6,100) SEQ1(I),SEQ3(I)
c99      CONTINUE
c      ENDDO
      RETURN
      END
C     END S3TOS1
C......................................................................

C......................................................................
C     SUB S1TOS3
      SUBROUTINE S1TOS3(SEQ3,SEQ1,NRES)
C TRANSLATES A3 TO A1 AND VICE VERSA. CHRIS SANDER MAY 1983
C INPUT/OUTPUT
      CHARACTER SEQ3(*)*3,SEQ1(*)*1
      INTEGER NRES
C     LOCAL
      CHARACTER AA3(24)*3, AA1(24)*1
      DATA AA3/'GLY','PRO','ASP','GLU','ALA','ASN','GLN','SER',
     +     'THR','LYS','ARG','HIS','VAL','ILE','MET','CYS',
     +     'LEU','PHE','TYR','TRP','ASX','GLX','---','!!!'/
      DATA AA1/'G','P','D','E','A','N','Q','S','T','K',
     +     'R','H','V','I','M','C','L','F','Y','W','B','Z','-','!'/
C    'X' OR 'XYZ' FOR NON-STANDARD OR UNKNOWN AMINO ACID RESIDUES
      DO I=1,NRES
         DO J=1,24
            IF (SEQ1(I).EQ.AA1(J)) THEN
               SEQ3(I)=AA3(J)
               GOTO 99
            ENDIF
         ENDDO
         SEQ3(I)='XYZ'
         WRITE(6,100) SEQ1(I),SEQ3(I)
 99      CONTINUE
      ENDDO
 100  FORMAT(' UNUSUAL RESIDUE NAME <',A3,'> TRANSLATED TO <',A1,'>')
      RETURN
      END
C     END  S1TOS3
C......................................................................

C......................................................................
C     SUB SCALE_PROFILE_METRIC
      SUBROUTINE SCALE_PROFILE_METRIC(MAXRES,NTRANS,TRANS,
     +     PROFILEMETRIC,SMIN,SMAX,MAPLOW,MAPHIGH)
C=======================================================================
C scale profile metric according to SMIN,SMAX,MAPLOW,MAPHIGH
C profilemetric is sim(maxres,26)
C=======================================================================
      IMPLICIT NONE
      INTEGER MAXRES,NTRANS
      REAL PROFILEMETRIC(MAXRES,NTRANS)
      REAL SMIN,SMAX,MAPLOW,MAPHIGH
      CHARACTER*(*) TRANS
C internal
      INTEGER NN,I,J,K,L,M
 
      WRITE(6,*) 'INFO: sub SCALE_PROFILE_METRIC executed here'
      NN=MAXRES*NTRANS
C=======================================================================
C reset value for chain breaks etc...
C add 'X' '!' and "-"
      J=INDEX(TRANS,'X')
      K=INDEX(TRANS,'!')
      L=INDEX(TRANS,'-')
      M=INDEX(TRANS,'.')
      IF (J.EQ.0 .OR. K.EQ.0 .OR. L.EQ.0 .or. M.eq. 0) THEN
         WRITE(6,*)'*** ERROR: "X","!","-" or "." unknown in '//
     +        'SCALE_PROFILE_METRIC'
      ENDIF
      DO I=1,MAXRES
         PROFILEMETRIC(I,J)=0.0
         PROFILEMETRIC(I,K)=0.0
         PROFILEMETRIC(I,L)=0.0
         PROFILEMETRIC(I,M)=0.0
      ENDDO

      CALL SCALEINTERVAL(PROFILEMETRIC,NN,SMIN,SMAX,MAPLOW,MAPHIGH)
C=======================================================================
C reset value for chain breaks etc...
C add 'X' '!' and "-"
      J=INDEX(TRANS,'X')
      K=INDEX(TRANS,'!')
      L=INDEX(TRANS,'-')
      M=INDEX(TRANS,'.')
      IF (J.EQ.0 .OR. K.EQ.0 .OR. L.EQ.0 .or. M.eq. 0) THEN
         WRITE(6,*)'*** ERROR: "X","!","-" or "." unknown in '//
     +        'SCALE_PROFILE_METRIC'
      ENDIF
      DO I=1,MAXRES
         PROFILEMETRIC(I,J)=0.0
         PROFILEMETRIC(I,K)=-200.0
         PROFILEMETRIC(I,L)=0.0
         PROFILEMETRIC(I,M)=0.0
      ENDDO
C=======================================================================
C DEBUG: WRITE MATRIX IN OUTPUT-FILE
C=======================================================================
c	OPEN(99,FILE='METRIC_DEBUG.X',STATUS='NEW',RECL=500)
c	DO I=1,50
c	   WRITE(99,'(1X,26(F7.2))')(PROFILEMETRIC(I,J),J=1,NTRANS)
c        ENDDO
c	CLOSE(99)
C=======================================================================
      RETURN
      END
C     END SCALE_PROFILE_METRIC
C......................................................................

C......................................................................
C     SUB SCALE_SSSA_PROFILE_METRIC
      SUBROUTINE SCALE_SSSA_PROFILE_METRIC(MAXRES,NTRANS,NSTRUCTRANS,
     + NACCTRANS,TRANS,PROFILEMETRIC,SMIN,SMAX,MAPLOW,MAPHIGH)
C=======================================================================
C scale profile metric according to SMIN,SMAX,MAPLOW,MAPHIGH
C profilemetric is sim(maxres,26)
C=======================================================================
      IMPLICIT NONE
      INTEGER MAXRES,NTRANS,NSTRUCTRANS,NACCTRANS
      REAL PROFILEMETRIC(MAXRES,NTRANS,NSTRUCTRANS,NACCTRANS)
      REAL SMIN,SMAX,MAPLOW,MAPHIGH
      CHARACTER*(*) TRANS
C internal
      INTEGER NN,I,J,K,L,M,ISS,IAC
 
C      WRITE(6,*) 'INFO: sub SCALE_SSSA_PROFILE_METRIC executed here'
      NN=MAXRES*NTRANS*NSTRUCTRANS*NACCTRANS
C=======================================================================
C reset value for chain breaks etc...
C add 'X' '!' and "-"
      J=INDEX(TRANS,'X')
      K=INDEX(TRANS,'!')
      L=INDEX(TRANS,'-')
      M=INDEX(TRANS,'.')
      IF (J.EQ.0 .OR. K.EQ.0 .OR. L.EQ.0 .or. M.eq. 0) THEN
         WRITE(6,*)'*** ERROR: "X","!","-" or "." unknown in '//
     +        'SCALE_PROFILE_METRIC'
      ENDIF
      DO I=1,MAXRES
         DO ISS=1,NSTRUCTRANS
            DO IAC=1,NACCTRANS
               PROFILEMETRIC(I,J,ISS,IAC)=0.0
               PROFILEMETRIC(I,K,ISS,IAC)=0.0
               PROFILEMETRIC(I,L,ISS,IAC)=0.0
               PROFILEMETRIC(I,M,ISS,IAC)=0.0
            ENDDO
         ENDDO
      ENDDO

      CALL SCALEINTERVAL(PROFILEMETRIC,NN,SMIN,SMAX,MAPLOW,MAPHIGH)
C=======================================================================
C reset value for chain breaks etc...
C add 'X' '!' and "-"
      J=INDEX(TRANS,'X')
      K=INDEX(TRANS,'!')
      L=INDEX(TRANS,'-')
      M=INDEX(TRANS,'.')
      IF (J.EQ.0 .OR. K.EQ.0 .OR. L.EQ.0 .or. M.eq. 0) THEN
         WRITE(6,*)'*** ERROR: "X","!","-" or "." unknown in '//
     +        'SCALE_PROFILE_METRIC'
      ENDIF
      DO I=1,MAXRES
         DO ISS=1,NSTRUCTRANS
            DO IAC=1,NACCTRANS
               PROFILEMETRIC(I,J,ISS,IAC)=0.0
               PROFILEMETRIC(I,K,ISS,IAC)=-200.0
               PROFILEMETRIC(I,L,ISS,IAC)=0.0
               PROFILEMETRIC(I,M,ISS,IAC)=0.0
            ENDDO
         ENDDO
      ENDDO
C=======================================================================
C DEBUG: WRITE MATRIX IN OUTPUT-FILE
C=======================================================================
c	OPEN(99,FILE='METRIC_DEBUG.X',STATUS='NEW',RECL=500)
c	DO I=1,50
c	   WRITE(99,'(1X,26(F7.2))')(PROFILEMETRIC(I,J),J=1,NTRANS)
c        ENDDO
c	CLOSE(99)
C=======================================================================
      RETURN
      END
C     END SCALE_SSSA_PROFILE_METRIC
C......................................................................

C......................................................................
C     SUB SCALEMETRIC
      SUBROUTINE SCALEMETRIC(NTRANS,TRANS,MAXSTRSTATES,
     +     MAXIOSTATES,SIMMETRIC,SMIN,SMAX,MAPLOW,MAPHIGH)
C=======================================================================
C scale matrix according to SMIN,SMAX,MAPLOW,MAPHIGH
C=======================================================================
      IMPLICIT NONE
      INTEGER NTRANS,MAXSTRSTATES,MAXIOSTATES
      REAL SIMMETRIC(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +     MAXSTRSTATES,MAXIOSTATES)
      REAL SMIN,SMAX,MAPLOW,MAPHIGH
      CHARACTER*(*) TRANS

C internal
      INTEGER NN,I,J,istr1,io1,istr2,io2

      WRITE(6,*)'INFO: sub SCALEMETRIC executed here'
      NN= (NTRANS * NTRANS) * (MAXSTRSTATES * MAXSTRSTATES) * 
     +     (MAXIOSTATES * MAXIOSTATES)
      CALL SCALEINTERVAL(SIMMETRIC,NN,SMIN,SMAX,MAPLOW,MAPHIGH)
C=======================================================================
C reset value for chain breaks etc...
C add 'X'
      I=INDEX(TRANS,'X')
      IF (I.EQ.0) THEN
         WRITE(6,*)'*** ERROR: "X" unknown in SCALEMETRIC'
         STOP
      ENDIF
      DO J=1,NTRANS
         DO ISTR1=1,MAXSTRSTATES
            DO IO1=1,MAXIOSTATES
               DO ISTR2=1,MAXSTRSTATES
                  DO IO2=1,MAXIOSTATES
                     SIMMETRIC(I,J,ISTR1,IO1,ISTR2,IO2)=0.0
                     SIMMETRIC(J,I,ISTR1,IO1,ISTR2,IO2)=0.0
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
C add '!'
      I=INDEX(TRANS,'!')
      IF (I.EQ.0) THEN
         WRITE(6,*)'*** ERROR: "!" unknown in SCALEMETRIC'
         STOP
      ENDIF
      DO J=1,NTRANS
         DO ISTR1=1,MAXSTRSTATES
            DO IO1=1,MAXIOSTATES
               DO ISTR2=1,MAXSTRSTATES
                  DO IO2=1,MAXIOSTATES
                     SIMMETRIC(I,J,ISTR1,IO1,ISTR2,IO2)=0.0
                     SIMMETRIC(J,I,ISTR1,IO1,ISTR2,IO2)=0.0
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
C add '-'
      I=INDEX(TRANS,'-')
      IF (I.EQ.0) THEN
         WRITE(6,*)'*** ERROR: "-" unknown in SCALEMETRIC'
         STOP
      ENDIF
      DO J=1,NTRANS
         DO ISTR1=1,MAXSTRSTATES
            DO IO1=1,MAXIOSTATES
               DO ISTR2=1,MAXSTRSTATES
                  DO IO2=1,MAXIOSTATES
                     SIMMETRIC(I,J,ISTR1,IO1,ISTR2,IO2)=0.0
                     SIMMETRIC(J,I,ISTR1,IO1,ISTR2,IO2)=0.0
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
C add '.'
c	I=INDEX(TRANS,'.')
c	IF (I.EQ.0) THEN
c          WRITE(6,*)'*** ERROR: "." unknown in SCALEMETRIC'
c	  STOP
c	ENDIF
c        DO J=1,NTRANS
c	   DO istr1=1,MAXSTRSTATES
c	      DO io1=1,MAXIOSTATES
c	         DO istr2=1,MAXSTRSTATES
c	            DO io2=1,MAXIOSTATES
c                       SIMMETRIC(I,J,istr1,io1,istr2,io2)=0.0
c                       SIMMETRIC(j,i,istr1,io1,istr2,io2)=0.0
c	            enddo
c	         enddo
c	     ENDDO
c	   ENDDO
c	ENDDO
C=======================================================================
C DEBUG: WRITE MATRIX IN OUTPUT-FILE
C=======================================================================
c	open(99,file='METRIC_DEBUG.X',status='NEW')
c	istr1=1
c	io1=1
c	istr2=1
c	io2=1
c        do i=1,ntrans
c	   do istr1=1,maxstrstates
c	      do io1=1,maxiostates
c	         do istr2=1,maxstrstates
c	            do io2=1,maxiostates
c	               write(99,'(1x,a1,4(1x,i3),5x,26(f6.2))')
c     +                trans(i:i),istr1,io1,istr2,io2,
c     +                (simmetric(i,j,istr1,io1,istr2,io2),j=1,ntrans)
c	            enddo
c	         enddo
c	     enddo
c	   enddo
c	enddo
c	close(99)
C=======================================================================
      RETURN
      END
C     END SCALEMETRIC
C......................................................................

C......................................................................
C     SUB SCALEINTERVAL
      SUBROUTINE SCALEINTERVAL(S,N,SMIN,SMAX,MAPLOW,MAPHIGH)
C imported: old values in S(1..N)
C           maplow and maphigh
C target limits SMAX, SMIN
C                                  
C exported: new values in S(1..N)
C internal: SHI, SLO
C SHI.........*.........SLO      map this interval onto
C      SMAX...*...SMIN               this interval or 
C      MAPLOW     MAPHIGH
C
      REAL S(*),MAPLOW,MAPHIGH,SMIN,SMAX,SHI,SLO
      SHI=-1.0E+10
      SLO=1.0E+10
C
      IF (SMIN.EQ.0.0 .AND. SMAX.EQ.0.0 .AND. 
     +     MAPLOW.EQ.0.0 .AND. MAPHIGH.EQ.0.0) THEN
         WRITE(6,*)' SCALEINTERVAL: NO SCALING '
         RETURN
      ENDIF
      IF (MAPLOW.EQ.0.0 .AND. MAPHIGH.EQ.0.0) THEN
C      WRITE(6,*)' SCALEINTERVAL: scale between SMIN/SMAX',
C     +        SMIN,SMAX
         DO I=1,N
            IF (S(I) .GT. SHI)SHI=S(I)
            IF (S(I) .LT. SLO)SLO=S(I)
         ENDDO
      ELSE
C        WRITE(6,*)' SCALEINTERVAL: scale between MAPLOW/MAPHIGH',
C     +        MAPLOW,MAPHIGH
         SHI=MAPHIGH
         SLO=MAPLOW
      ENDIF
C     WRITE(6,*)'high/low smin/smax before: ',shi,slo,smin,smax
      DO I=1,N
         S(I)=((S(I)-SLO)/(SHI-SLO))*(SMAX-SMIN)+SMIN 
      ENDDO
c        WRITE(6,'(20F5.2)')(S(I),I=1,N)

      SHI=-1.0E+10
      SLO=1.0E+10

      DO I=1,N
         IF (S(I) .GT. SHI)SHI=S(I)
         IF (S(I) .LT. SLO)SLO=S(I)
      ENDDO
C      WRITE(6,*)'high/low smin/smax after: ',shi,slo,smin,smax

      RETURN
      END
C     END SCALEINTERVAL
C......................................................................

C......................................................................
C     SUB SECSTRUC_TO_3_STATE
      SUBROUTINE SECSTRUC_TO_3_STATE(SECSTRUC,CLASS,ICLASS)
C convert DSSP-secondary structure symbol to 3-state (L,H,E) secondary 
C structure
C given SECSTRUC, what is the class number ICLASS and class 
C representative CLASS ?
C undefined states is set CLASS='U', ICLASS=0
C
C input
      CHARACTER SECSTRUC
C output
      CHARACTER CLASS
      INTEGER ICLASS
C internal
c	INTEGER MAXSTRSTATES
c	PARAMETER (MAXSTRSTATES=3)
      CHARACTER*25 STATES
c               1234567890123456789012345
      STATES='L TCSltcsEBAPMebapmHGIhgi'
c	DATA STATES/'L TCStclss','EBAPMebapm','HGIhgiiiii'/
c	CHARACTER STATES(MAXSTRSTATES)*10
C======================================================================
      ICLASS=0
      CLASS='U'
      I=INDEX(STATES,SECSTRUC)
      IF (I .NE. 0) THEN
         IF (I .LE. 9) THEN
	    ICLASS=1
	    CLASS='L'
	    RETURN
         ELSE IF (I .GE. 10 .AND. I .LE. 19) THEN
	    ICLASS=10
	    CLASS='E'
	    RETURN
         ELSE IF (I .GE. 20 .AND. I .LE. 25) THEN
	    ICLASS=20
	    CLASS='H'
	    RETURN
         ENDIF
      ENDIF

c	DO K=1,MAXSTRSTATES
c	   IF (INDEX(STATES(K),SECSTRUC).NE.0) THEN
c	      ICLASS=K
c	      CLASS=STATES(K)(1:1)
c	      RETURN
c	   ENDIF
c	ENDDO
      RETURN
      END
C     END SECSTRUC_TO_3_STATE
C......................................................................

C......................................................................
C     SUB SELECT_PDB_POINTER
      SUBROUTINE SELECT_PDB_POINTER(KUNIT,DSSP_PATH,PDBIN,PDBOUT)
C selects from a string returned from GETSEQ one pdb-pointer for HSSP
C the selection is done by a "best-guess": 
C
C 1.) check if there is a valid DSSP-file
C     if so, take the latest entry in PDB
C 2.) if not 1 then check if it is a C-alpha set
C 3.) if not 2 then check if it is a model-structure
C
C INPUT: pdbin
C        1INS; 15-JAN-91 | 2INS; 15-JAN-91 | 3INS; 20-OCT-92 ||  3
C or     1NSB; PRELIMINARY.
C OUTPUT: pdbout
C        1INS    if "normal" DSSP-file or 
C        1INS_C  if c-alpha only or 
C        1INS_M  if model structure or 
C        1INS_P  if pre-released structure or 
C        1INS_?  if none of the above cases, like the SwissProt pointer
C                is pointing to a PDB-file which is gone (renamed) in the 
C                current version of PDB OR
C                if something is wrong with the "normal" DSSP-file

      IMPLICIT        NONE
C input:
      CHARACTER*(*)   PDBIN,DSSP_PATH
      INTEGER         KUNIT
C output:
      CHARACTER*(*)   PDBOUT
C internal
      INTEGER         MAXPOINTER
      PARAMETER      (MAXPOINTER=              200)
      INTEGER         NPOINTER,SORTNUMBER(MAXPOINTER),IHIGH,
     +                IDSSP_FLAG,ISTART,ISTOP,IPOS,JPOS,IPOINTER,
     +                JPOINTER,KPOINTER,NEXTPOS,IMONTH,IYEAR
      CHARACTER*12    PDBPOINTER(MAXPOINTER)
      CHARACTER       CTEMP*50,FILENAME*200
      CHARACTER       CMONTH*36
      LOGICAL         LERROR
C used to convert entry date to sort number
      DATA CMONTH /'JANFEBMARAPRMAIJUNJULAUGSEPOCTNOVDEC'/
C init
*----------------------------------------------------------------------*
      PDBOUT=' '
      CTEMP=' '
      IF (PDBIN.EQ.' ')RETURN
C     extract number of pointers
      IPOS=INDEX(PDBIN,'||')
      IF (IPOS .NE. 0) THEN
         CALL STRPOS(PDBIN,ISTART,ISTOP)
         CALL READ_INT_FROM_STRING(PDBIN(IPOS+2:ISTOP),NPOINTER)
      ELSE
         RETURN
      ENDIF
      IF (NPOINTER .LE. 0)RETURN
C     loop over pdb-pointers
      IPOS=1
      IF (NPOINTER .GT. MAXPOINTER) THEN
         WRITE(6,*)' SELECT_PDB_POINTER: npointer .gt. maxpointer'
         WRITE(6,*)' set npointer to maxpointer'
         NPOINTER= MAXPOINTER
      ENDIF
      DO IPOINTER=1,NPOINTER
         SORTNUMBER(IPOINTER)=0
         CTEMP=' '
         NEXTPOS=INDEX(PDBIN(IPOS:),'|')+IPOS-1
         CTEMP(1:)=PDBIN(IPOS:NEXTPOS-1)
         JPOS=INDEX(CTEMP,';')
         PDBPOINTER(IPOINTER)=CTEMP(1:JPOS-1)
C     extract month and year of pdb entry
         IF (INDEX(CTEMP,'PRELIM') .EQ. 0) THEN
            JPOS=INDEX(CTEMP,'-')
            IMONTH= ( (INDEX(CMONTH,CTEMP(JPOS+1:JPOS+4) )) / 3 )+1
            CALL READ_INT_FROM_STRING(CTEMP(JPOS+5:JPOS+6),IYEAR)
C     build up a sort number 
C latest entry has largest number: 199201= JAN 1992
C with beginning of the year 2080 or so we have to add a line here :-)
            IF (IYEAR .GT. 0) THEN
	       SORTNUMBER(IPOINTER)=10000*19 + 100*IYEAR + IMONTH
            ELSE
	       SORTNUMBER(IPOINTER)=10000*20 + 100*IYEAR + IMONTH
            ENDIF
         ENDIF
C set line pointer to next entry
         IPOS=NEXTPOS+1
      ENDDO

      DO JPOINTER=1,NPOINTER
         IPOINTER=-1
         IHIGH=-1
         DO KPOINTER=1,NPOINTER
            IF (SORTNUMBER(KPOINTER) .GE. IHIGH) THEN
               IHIGH=SORTNUMBER(KPOINTER)
               IPOINTER=KPOINTER
            ENDIF
         ENDDO
         SORTNUMBER(IPOINTER)=-99
         
         CALL UPTOLOW(PDBPOINTER(IPOINTER),LEN(PDBPOINTER(IPOINTER)) )
C     LOOK IF THERE IS A "NORMAL" DSSP-FILE
         IDSSP_FLAG=4
         CALL CONCAT_3STRINGS(DSSP_PATH,PDBPOINTER(IPOINTER),'.dssp',
     +        FILENAME)
         CALL OPEN_FILE(KUNIT,FILENAME,'old,readonly,silent',lerror)
         IF (LERROR)GOTO 10
C check if there is something in the file
         CTEMP=' '
         DO WHILE(INDEX(CTEMP,'#  RES') .EQ. 0)
            READ(KUNIT,'(A10)',END=10,ERR=10)CTEMP
         ENDDO
         IDSSP_FLAG=0
 10      CALL CLOSE_FILE(KUNIT,FILENAME)
         IF (.NOT. LERROR) GOTO 100
C look if there is C-alpha model set
         CALL CONCAT_3STRINGS(DSSP_PATH,PDBPOINTER(IPOINTER),
     +        '.dssp_ca',filename)
         CALL OPEN_FILE(KUNIT,FILENAME,'old,readonly,silent',lerror)
         CALL CLOSE_FILE(KUNIT,FILENAME)
         IF (.NOT. LERROR) THEN
            IDSSP_FLAG=1
            GOTO 100
         ENDIF
C look if there is a model-structure
         CALL CONCAT_3STRINGS(DSSP_PATH,PDBPOINTER(IPOINTER),
     +        '.dssp_mod',filename)
         CALL OPEN_FILE(KUNIT,FILENAME,'old,readonly,silent',lerror)
         CALL CLOSE_FILE(KUNIT,FILENAME)
         IF (.NOT. LERROR) THEN
            IDSSP_FLAG=2
            GOTO 100
         ENDIF
C look if there is a pre-released structure
         CALL CONCAT_3STRINGS(DSSP_PATH,PDBPOINTER(IPOINTER),
     +        '.dssp_pre',filename)
         CALL OPEN_FILE(KUNIT,FILENAME,'old,readonly,silent',lerror)
         CALL CLOSE_FILE(KUNIT,FILENAME)
         IF (.NOT. LERROR) THEN
            IDSSP_FLAG=3
            GOTO 100
         ENDIF
C set pdbpointer-extension according to selection
 100     CALL STRPOS(PDBPOINTER(JPOINTER),ISTART,ISTOP)
         IF ( IDSSP_FLAG .EQ. 0) THEN
            PDBOUT=PDBPOINTER(IPOINTER)(ISTART:ISTOP)
            GOTO 200
         ELSE IF ( IDSSP_FLAG .EQ. 1) THEN
            PDBOUT=PDBPOINTER(IPOINTER)(ISTART:ISTOP)//'_C'
         ELSE IF ( IDSSP_FLAG .EQ. 2) THEN
            PDBOUT=PDBPOINTER(IPOINTER)(ISTART:ISTOP)//'_M'
         ELSE IF ( IDSSP_FLAG .EQ. 3) THEN
            PDBOUT=PDBPOINTER(IPOINTER)(ISTART:ISTOP)//'_P'
         ELSE IF ( IDSSP_FLAG .EQ. 4) THEN
            PDBOUT=PDBPOINTER(IPOINTER)(ISTART:ISTOP)//'_?'
         ENDIF
      ENDDO
 200  CALL LOWTOUP(PDBOUT,LEN(PDBOUT) )
C     
      RETURN
      END
C     END SELECT_PDB_POINTER
C......................................................................

C......................................................................
C     SUB SELECT_UNIQUE_CHAIN
      SUBROUTINE SELECT_UNIQUE_CHAIN(KFILE,FILENAME,OUTNAME)
C selects unique chains from dssp file,  builds up a new filename of the
C form: $pdb:4hhb.dssp_!_A,B

      IMPLICIT        NONE
	
      INTEGER         KFILE
      CHARACTER*(*)   FILENAME,OUTNAME
C internal
      INTEGER         MAXRES_LOC
      PARAMETER      (MAXRES_LOC=            10000)
      INTEGER         NRES,NCHAIN
      CHARACTER       CRESID(MAXRES_LOC)
C      CHARACTER*6     CRESID(MAXRES_LOC)
      CHARACTER       CSEQ(MAXRES_LOC)
C      CHARACTER       TRANS*26
      
      INTEGER          MAXCHAIN
      PARAMETER  (MAXCHAIN=100)
      INTEGER    IBREAK,IBREAKPOS(0:MAXCHAIN),I,J,ICHAIN,JCHAIN
      INTEGER    ISTART,ISTOP
      CHARACTER  CHAINID(0:MAXCHAIN) 
      CHARACTER  CTEMP*100
      LOGICAL    LALL,LSAME(MAXCHAIN,MAXCHAIN),LTAKE(MAXCHAIN)
      LOGICAL LERROR
      
C     CHARACTER LOWER*26
      CHARACTER LINE*(1000)
      
C     DONT USE INDEX COMMAND (CPU TIME)
C     INTEGER NASCII
C     PARAMETER (NASCII=256)
C     INTEGER TRANSPOS(NASCII)

c init
      LINE=' '
      NRES=1                                                       
      NCHAIN=1                          
c     lower='abcdefghijklmnopqrstuvwxyz'                              
c	TRANS='VLIMFWYGAPSTCHRKQENDBZX!-.'
      IBREAK=0
      IBREAKPOS(0)=0
      CHAINID(0)='?'
      OUTNAME=' '
      DO I=1,MAXCHAIN
         IBREAKPOS(I)=0
         CHAINID(I)=' '
         LTAKE(I)=.TRUE.
         DO J=1,MAXCHAIN
            LSAME(I,J)=.TRUE.
         ENDDO
      ENDDO
      DO I=1,MAXRES_LOC
         CSEQ(I)=' '
      ENDDO
      CALL OPEN_FILE(KFILE,FILENAME,'readonly,old',LERROR)
C READ FROM DSSP
      READ(KFILE,'(A)',END=199)LINE
      IF (INDEX(LINE,'SECONDARY').EQ.0) THEN
         IF (INDEX(LINE,'Secondary').EQ.0) THEN
            WRITE(6,*)'***select_unique... error: dssp file assumed, '
            WRITE(6,*)' but word /secondary/ is missing in first line'
            WRITE(6,*)'of file ',FILENAME,' line is:'
            WRITE(6,*) LINE
            RETURN
         ENDIF
      ENDIF
c repeat until #  
 105  READ(KFILE,'(A)',END=199)LINE
      IF (INDEX(LINE(1:5),'#').EQ.0) GOTO 105
C
C23456123451x1
C23456789011x1
Ccccccaaaaaaca
C   9    9 A S
C  21   21   Y
C
      DO WHILE (.TRUE.)
	 IF (NRES .LE. MAXRES_LOC) THEN
            READ(KFILE,'(11X,A1,1X,A1)',END=900)CRESID(NRES),CSEQ(NRES)
c          read(kfile,'(6x,a6,1x,a1)',end=900)cresid(nres),cseq(nres)
c convert ss-bridges to 'c'....
c          if (index(lower,cseq(nres)) .ne. 0) cseq(nres)='C'
            IF (CSEQ(NRES) .EQ. '!') THEN
               NCHAIN=NCHAIN+1 
            ENDIF
c illegal residues
c	  call getindex(cseq(nres),transpos,i)
c          if (i .le. 0) then
c	     WRITE(6,'(a,a)')'*** seq unknown: ',cseq(nres)
c          ENDIF
            NRES=NRES+1
c dimension overflow
	 ELSE
            WRITE(6,'(a)')'*** error: dimension overflow MAXRES_LOC ***'
            WRITE(6,*)'truncated to   ',nres,' residues'
            GOTO 900
         ENDIF
c next line             
      ENDDO
C--------------DSSP read error -----------------------------------
 199  WRITE(6,*)'*** incomplete dssp file (eof) '
      NRES=0
      NCHAIN=0
      WRITE(6,*) 'file: ',filename(1:40)
      CLOSE(KFILE)
      RETURN

c finished reading-----------------------
 900  CLOSE(KFILE)
      NRES=NRES-1
      
      IF (NCHAIN .EQ. 1)RETURN
      DO I=1,NRES
         IF (CSEQ(I) .EQ. '!') THEN
            IBREAK=IBREAK+1
            IBREAKPOS(IBREAK)=I
         ENDIF
      ENDDO
      IBREAK=IBREAK+1
      CHAINID(1)=CRESID(1)
c	chainid(1)=cresid(1)(6:6)

      DO I=1,IBREAK
         CHAINID(I+1)=CRESID(IBREAKPOS(I)+1)
c	   chainid(i+1)=cresid(ibreakpos(i)+1)(6:6)
      ENDDO
      IBREAKPOS(IBREAK)=NRES+1
      DO ICHAIN=1,IBREAK-1
         DO JCHAIN=ICHAIN+1,IBREAK
            IF (IBREAKPOS(ICHAIN)-IBREAKPOS(ICHAIN-1)-1 .EQ. 
     +           IBREAKPOS(JCHAIN)-IBREAKPOS(JCHAIN-1)-1 ) THEN
               J=IBREAKPOS(JCHAIN-1)
               DO I=IBREAKPOS(ICHAIN-1)+1,IBREAKPOS(ICHAIN)-1
                  J=J+1
                  IF (CSEQ(I) .NE. CSEQ(J)) THEN
                     LSAME(ICHAIN,JCHAIN)=.FALSE.
                     LSAME(JCHAIN,ICHAIN)=.FALSE.
                     GOTO 50
                  ENDIF
               ENDDO
 50            CONTINUE	
            ELSE
               LSAME(ICHAIN,JCHAIN)=.FALSE.
               LSAME(JCHAIN,ICHAIN)=.FALSE.
            ENDIF
         ENDDO
      ENDDO
      
      DO I=1,NCHAIN-1
         IF ( LTAKE(I) ) THEN
            DO J=I+1,NCHAIN 
               IF (LSAME(I,J)) THEN
                  LTAKE(J)=.FALSE.
               ENDIF
            ENDDO
         ENDIF
      ENDDO
      
      LALL=.TRUE.
      DO I=1,NCHAIN 
         IF (LALL) THEN
            IF ( .NOT. LTAKE(I))LALL=.FALSE.
         ENDIF
      ENDDO
      
      CTEMP=' '
      CALL STRPOS(FILENAME,ISTART,ISTOP)
      CTEMP=FILENAME(ISTART:ISTOP)//'_!_'
      DO I=1,NCHAIN 
         IF (LTAKE(I)) THEN
            CALL STRPOS(CTEMP,ISTART,ISTOP)
            IF (CHAINID(I-1) .NE. CHAINID(I)) THEN
	       WRITE(CTEMP(ISTOP+1:),'(A,A)')CHAINID(I),','
            ENDIF
         ENDIF
      ENDDO
      CALL STRPOS(CTEMP,ISTART,ISTOP)
      IF (CTEMP(ISTOP:ISTOP) .EQ. ',') THEN
         CTEMP(ISTOP:ISTOP)=' '
      ENDIF
      OUTNAME=' '
      
C     IN CASE OF "ARTIFICIAL" CHAIN-BREAKS THE END IS EMPTY
      CALL STRPOS(CTEMP,ISTART,ISTOP)
      IF (CTEMP(ISTOP-2:ISTOP) .EQ. '_!_') THEN
         CALL STRPOS(FILENAME,ISTART,ISTOP)
         OUTNAME(1:)=FILENAME(ISTART:ISTOP)
      ELSE
         WRITE(OUTNAME(1:),'(A)')CTEMP(ISTART:ISTOP)
      ENDIF
      WRITE(6,*)'select_unique: ',outname(1:60)

      RETURN
      END
C END SELECT_UNIQUE_CHAIN

c$$$  C SUB SELECT_UNIQUE_CHAIN
c$$$	subroutine select_unique_chain(kfile,filename,outname)
c$$$C selects unique chains from dssp file, and builds up a new filename of the
c$$$C form: $pdb:4hhb.dssp_!_A,B
c$$$
c$$$	implicit none
c$$$	
c$$$	integer kfile
c$$$cx	character*80 filename,outname
c$$$	character*(*) filename,outname
c$$$C internal
c$$$	integer MAXSQ
c$$$	parameter (MAXSQ=4500)
c$$$	integer nres,lacc(MAXSQ),iop,ntrans,kchain,nchain
c$$$	integer ipdbno(MAXSQ)
c$$$	character*6 cresid(MAXSQ)
c$$$	character   cseq(MAXSQ),struc(MAXSQ)
c$$$	character*80 compound
c$$$	character*12 ACCESSION,pdbref
c$$$	character    trans*26,cchain
c$$$	character    chains*26
c$$$	logical ldssp
c$$$
c$$$	integer    maxchain
c$$$	parameter  (maxchain=30)
c$$$	integer    ibreak,ibreakpos(0:maxchain),i,j,ichain,jchain
c$$$	integer    istart,istop
c$$$	character  chainid(0:maxchain) 
c$$$	character  ctemp*100
c$$$	logical    lall,lsame(maxchain,maxchain),ltake(maxchain)
c$$$	logical ltruncated,lerror
c$$$C init
c$$$	ntrans=26
c$$$	TRANS='VLIMFWYGAPSTCHRKQENDBZX!-.'
c$$$	iop=0
c$$$	ibreak=0
c$$$	ibreakpos(0)=0
c$$$	chainid(0)='?'
c$$$	do i=1,maxchain
c$$$	   ibreakpos(i)=0
c$$$	   chainid(i)=' '
c$$$	   ltake(i)=.true.
c$$$	   do j=1,maxchain
c$$$	      lsame(i,j)=.true.
c$$$	   enddo
c$$$	enddo
c$$$C all chains wanted from DSSP data set
c$$$	kchain=0
c$$$	chains=' '
c$$$
c$$$
c$$$
c$$$c	call getseq(kfile,MAXSQ,nres,cresid,cseq,struc,
c$$$c     +       lacc,ldssp,filename,compound,ACCESSION,pdbref,iop,trans,
c$$$c     +       ntrans,kchain,nchain,cchain)
c$$$
c$$$	if (nchain .eq. 1)return
c$$$	do i=1,nres
c$$$	   if (cseq(i) .eq. '!') then
c$$$	     ibreak=ibreak+1
c$$$	     ibreakpos(ibreak)=i
c$$$	   endif
c$$$        enddo
c$$$	ibreak=ibreak+1
c$$$	chainid(1)=cresid(1)(6:6)
c$$$	do i=1,ibreak
c$$$	   chainid(i+1)=cresid(ibreakpos(i)+1)(6:6)
c$$$	enddo
c$$$	ibreakpos(ibreak)=nres+1
c$$$	do ichain=1,ibreak-1
c$$$	   do jchain=ichain+1,ibreak
c$$$	      if (ibreakpos(ichain)-ibreakpos(ichain-1)-1 .eq. 
c$$$     +           ibreakpos(jchain)-ibreakpos(jchain-1)-1 ) then
c$$$                j=ibreakpos(jchain-1)
c$$$                do i=ibreakpos(ichain-1)+1,ibreakpos(ichain)-1
c$$$                   j=j+1
c$$$                   if (cseq(i) .ne. cseq(j)) then
c$$$	              lsame(ichain,jchain)=.false.
c$$$	              lsame(jchain,ichain)=.false.
c$$$                      GOTO 50
c$$$                   endif
c$$$	        enddo
c$$$50	        continue	
c$$$	      else
c$$$	        lsame(ichain,jchain)=.false.
c$$$	        lsame(jchain,ichain)=.false.
c$$$	     endif
c$$$	  enddo
c$$$	enddo
c$$$
c$$$	do i=1,nchain-1
c$$$           if ( ltake(i) ) then
c$$$	     do j=i+1,nchain 
c$$$                if (lsame(i,j)) then
c$$$                  ltake(j)=.false.
c$$$                endif
c$$$             ENDDO
c$$$	   endif
c$$$	enddo
c$$$
c$$$	lall=.true.
c$$$	do i=1,nchain 
c$$$	   if (lall) then
c$$$	      if ( .not. ltake(i))lall=.false.
c$$$	   endif
c$$$	enddo
c$$$
c$$$	ctemp=' '
c$$$	call strpos(filename,istart,istop)
c$$$	ctemp=filename(istart:istop)//'_!_'
c$$$	do i=1,nchain 
c$$$	   if (ltake(i)) then
c$$$	     call strpos(ctemp,istart,istop)
c$$$             if (chainid(i-1) .ne. chainid(i)) then
c$$$	       write(ctemp(istop+1:),'(a,a)')chainid(i),','
c$$$             endif
c$$$           endif
c$$$	enddo
c$$$	call strpos(ctemp,istart,istop)
c$$$	if (ctemp(istop:istop) .eq. ',') then
c$$$	  ctemp(istop:istop)=' '
c$$$	endif
c$$$	outname=' '
c$$$	write(outname(1:),'(a)')ctemp(istart:istop)
c$$$	WRITE(6,*)outname
c$$$
c$$$	return
c$$$	end
c$$$  C END SELECT_UNIQUE_CHAIN
C......................................................................

C......................................................................
C     SUB SEND_DATA_TO_NODE
C send start signal and all data to workers
C they have to wait until they received all information
      SUBROUTINE SEND_DATA_TO_NODE
      IMPLICIT NONE
C import
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
C internal
C ISIZE is dummy variable; otherwise we have to pass a parameter , which
C gets defined as a variable in the subroutines (not clear what happens)
      INTEGER ILINK
cc	integer iworker,iset,ilink,isize
C
C link=-1 means send to everybody
C
c	if (mp_model .eq. 'PARIX') then
c	  msgtype=idtop
c	  if (lsmall_machine) then
c	     do iworker=1,nworker
c		ilink= link(iworker)
c                call send_maxhom_data(ilink)
c	     enddo
c	  else
c	    do iset=1,nworkset
c	     ilink=sender_node(iset)
c             call send_maxhom_data(ilink)
c	     ilink=receiver_node(iset)
c	     isize=len(corepath)
c	     call mp_put_string(msgtype,ilink,corepath,isize)
c	     isize=len(corefile)
c	     call mp_put_string(msgtype,ilink,corefile,isize)
c	    enddo
c	  endif
c	else if (mp_model .eq. 'DELTA') then
c	  call mp_init_send() ; ilink=-1
c          call send_maxhom_data(ilink)
c	else if (mp_model .eq. 'PVM3') then
      CALL MP_INIT_SEND() 
      ILINK=-1
      CALL SEND_MAXHOM_DATA(ILINK)
c	else if (mp_model .eq. 'PVM') then
c	  call mp_init_send() ; ilink=-1
c          call send_maxhom_data(ilink)
c	endif
      WRITE(6,*)' send init data finished'
      CALL FLUSH_UNIT(6)
      RETURN
      END
C     END SEND_DATA_TO_NODE
C......................................................................

C......................................................................
C     SUB SEND_MAXHOM_DATA
      SUBROUTINE SEND_MAXHOM_DATA(ILINK)

C import
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
      INTEGER ILINK
C internal
      CHARACTER   CPARSYTEC_BUG*(MAXSQ)
      INTEGER ISIZE,I
      INTEGER ILBACKWARD,ILINSERT_2,ILISTOFSEQ_2,ILSHOW_SAMESEQ,
     +     ILSWISSBASE,ILDSSP_1,ILCONSERV_1,ILCONSERV_2,
     +     ILCONSIMPORT,ILALL,ILFORMULA,ILTHRESHOLD,
     +     ILCOMPSTR,ILPASS2,ILTRACE,ILONG_OUT,ILBATCH,
     +     I3WAY,I3WAYDONE,IWARM_START,IBINARY
c	integer ilmixed_arch
C init logicals
C NOTE: LOGICALS are sent in an integer variable
C on some machines its not clear what happens if one snets
C logicals as integers
      ILBACKWARD=0 
      ILINSERT_2=0 
      ILISTOFSEQ_2=0
      ILSHOW_SAMESEQ=0 
      ILSWISSBASE=0 
      ILDSSP_1=0 
      ILCONSERV_1=0
      ILCONSERV_2=0 
      ILCONSIMPORT=0 
      ILALL=0 
      ILFORMULA=0
      ILTHRESHOLD=0 
      ILCOMPSTR=0 
      ILPASS2=0 
      ILTRACE=0
      ILONG_OUT=0 
      ILBATCH=0 
      I3WAY=0
      I3WAYDONE=0 
      IWARM_START=0 
      IBINARY=0
c       ilmixed_arch=0

      MSGTYPE=1
      CALL MP_PUT_INT4(MSGTYPE,ILINK,ID_HOST,N_ONE)
      CALL MP_PUT_INT4(MSGTYPE,ILINK,N1,N_ONE)
      IF (N1 .GT. 0) THEN
         ISIZE=N1
         CALL MP_PUT_INT4_ARRAY(MSGTYPE,ILINK,LSQ_1,ISIZE)
         CALL MP_PUT_INT4_ARRAY(MSGTYPE,ILINK,LSTRUC_1,ISIZE)
         CALL MP_PUT_INT4_ARRAY(MSGTYPE,ILINK,LSTRCLASS_1,ISIZE)
         CALL MP_PUT_INT4_ARRAY(MSGTYPE,ILINK,LACC_1,ISIZE)
         ISIZE=MAXBREAK
         CALL MP_PUT_INT4_ARRAY(MSGTYPE,ILINK,IBREAKPOS_1,ISIZE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,NBREAK_1,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,NBEST,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,IPROFBEG,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,IPROFEND,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,PROFILEMODE,N_ONE)
         ISIZE=NASCII
         CALL MP_PUT_INT4_ARRAY(MSGTYPE,ILINK,TRANSPOS,ISIZE)
         ISIZE=MAXCUTOFFSTEPS
         CALL MP_PUT_INT4_ARRAY(MSGTYPE,ILINK,ISOLEN,ISIZE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,NSTEP,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ISAFE,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,NSTRSTATES_1,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,NSTRSTATES_2,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,NIOSTATES_1,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,NIOSTATES_2,N_ONE)
         ISIZE=N1
         CALL MP_PUT_INT4_ARRAY(MSGTYPE,ILINK,PDBNO_1,ISIZE)
         
         ISIZE=MAXCUTOFFSTEPS
         CALL MP_PUT_REAL4_ARRAY(MSGTYPE,ILINK,ISOIDE,ISIZE)
         ISIZE=N1
         CALL MP_PUT_REAL4_ARRAY(MSGTYPE,ILINK,GAPOPEN_1,ISIZE)
         CALL MP_PUT_REAL4_ARRAY(MSGTYPE,ILINK,GAPELONG_1,ISIZE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,OPEN_1,N_ONE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,ELONG_1,N_ONE)
         CALL MP_PUT_REAL4_ARRAY(MSGTYPE,ILINK,CONSWEIGHT_1,ISIZE)
         ISIZE=MAXSQ*NTRANS
         CALL MP_PUT_REAL4_ARRAY(MSGTYPE,ILINK,SIMMETRIC_1,ISIZE)
         IF (PROFILEMODE .EQ. 6) THEN
            ISIZE= NTRANS * NTRANS * MAXSTRSTATES * MAXIOSTATES * 
     +           MAXSTRSTATES*MAXIOSTATES
            CALL MP_PUT_REAL4_ARRAY(MSGTYPE,ILINK,SIMORG,ISIZE)
         ENDIF
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,FILTER_VAL,N_ONE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,PUNISH,N_ONE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,CUTVALUE1,N_ONE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,CUTVALUE2,N_ONE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,SMIN,N_ONE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,SMAX,N_ONE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,MAPLOW,N_ONE)
         CALL MP_PUT_REAL4(MSGTYPE,ILINK,MAPHIGH,N_ONE)
         ISIZE=MAXSTRSTATES*MAXIOSTATES
         CALL MP_PUT_REAL4_ARRAY(MSGTYPE,ILINK,IORANGE,ISIZE)
         ISIZE=LEN(MP_MODEL)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,MP_MODEL,ISIZE)
         ISIZE=LEN(SPLIT_DB_PATH)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,SPLIT_DB_PATH,ISIZE)
         ISIZE=LEN(SPLIT_DB_DATA)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,SPLIT_DB_DATA,ISIZE)
         ISIZE=LEN(SWISSPROT_SEQ)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,SWISSPROT_SEQ,ISIZE)
         ISIZE=LEN(LISTFILE_2)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,LISTFILE_2,ISIZE)
         ISIZE=LEN(CSQ_1)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,CSQ_1,ISIZE)

C Parsytec bug
c	isize=MAXSQ
c	call mp_put_string_array(msgtype,ilink,struc_1,isize)
c	call mp_put_string_array(msgtype,ilink,chainid_1,isize)

         ISIZE=N1
         DO I=1,N1
	    CPARSYTEC_BUG(I:I)=STRUC_1(I)
         ENDDO
         CALL MP_PUT_STRING(MSGTYPE,ILINK,CPARSYTEC_BUG,ISIZE)
         DO I=1,N1
            CPARSYTEC_BUG(I:I)=CHAINID_1(I)
         ENDDO
         CALL MP_PUT_STRING(MSGTYPE,ILINK,CPARSYTEC_BUG,ISIZE)
         
         
         ISIZE=LEN(OPENWEIGHT_ANSWER)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,OPENWEIGHT_ANSWER,ISIZE)
         ISIZE=LEN(ELONGWEIGHT_ANSWER)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,ELONGWEIGHT_ANSWER,ISIZE)
         ISIZE=LEN(SMIN_ANSWER)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,SMIN_ANSWER,ISIZE)
         ISIZE=LEN(NAME_1)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,NAME_1,ISIZE)
         ISIZE=LEN(HSSPID_2)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,HSSPID_2,ISIZE)
         ISIZE=LEN(CSORTMODE)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,CSORTMODE,ISIZE)
         ISIZE=LEN(METRICFILE)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,METRICFILE,ISIZE)
         ISIZE=LEN(CURRENT_DIR)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,CURRENT_DIR,ISIZE)
         ISIZE=LEN(DSSP_PATH)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,DSSP_PATH,ISIZE)
         ISIZE=LEN(PDBPATH)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,PDBPATH,ISIZE)
         ISIZE=LEN(PLOTFILE)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,PLOTFILE,ISIZE)
         ISIZE=LEN(COREPATH)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,COREPATH,ISIZE)
         ISIZE=LEN(COREFILE)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,COREFILE,ISIZE)
         ISIZE=LEN(TRANS)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,TRANS,ISIZE)
         ISIZE=LEN(STRTRANS)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,STRTRANS,ISIZE)
         ISIZE=LEN(CSTRSTATES)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,CSTRSTATES,ISIZE)
         ISIZE=LEN(CIOSTATES)
         CALL MP_PUT_STRING(MSGTYPE,ILINK,CIOSTATES,ISIZE)
         DO I=1,MAXSTRSTATES
            ISIZE=LEN(STR_CLASSES(I))
            CALL MP_PUT_STRING(MSGTYPE,ILINK,STR_CLASSES(I),ISIZE)
         ENDDO

c	  if ( lmixed_arch   ) ilmixed_arch=1
         IF ( LBACKWARD     ) ILBACKWARD=1
         IF ( LINSERT_2     ) ILINSERT_2=1
         IF ( LISTOFSEQ_2   ) ILISTOFSEQ_2=1
         IF ( LSHOW_SAMESEQ ) ILSHOW_SAMESEQ=1
         IF ( LSWISSBASE    ) ILSWISSBASE=1
         IF ( LDSSP_1       ) ILDSSP_1=1
         IF ( LCONSERV_1    ) ILCONSERV_1=1
         IF ( LCONSERV_2    ) ILCONSERV_2=1
         IF ( LCONSIMPORT   ) ILCONSIMPORT=1
         IF ( LALL          ) ILALL=1
         IF ( LFORMULA      ) ILFORMULA=1
         IF ( LTHRESHOLD    ) ILTHRESHOLD=1
         IF ( LCOMPSTR      ) ILCOMPSTR=1
         IF ( LPASS2        ) ILPASS2=1
         IF ( LTRACE        ) ILTRACE=1
         IF ( LONG_OUT      ) ILONG_OUT=1
         IF ( LBATCH        ) ILBATCH=1
         IF ( L3WAY         ) I3WAY=1
         IF ( L3WAYDONE     ) I3WAYDONE=1
         IF ( LWARM_START   ) IWARM_START=1
         IF ( LBINARY       ) IBINARY=1
         
C     CALL MP_PUT_INT4(MSGTYPE,ILINK,ILMIXED_ARCH,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILBACKWARD,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILINSERT_2,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILISTOFSEQ_2,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILSHOW_SAMESEQ,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILSWISSBASE,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILDSSP_1,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILCONSERV_1,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILCONSERV_2,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILCONSIMPORT,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILALL,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILFORMULA,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILTHRESHOLD,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILCOMPSTR,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILPASS2,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILTRACE,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILONG_OUT,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,ILBATCH,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,I3WAY,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,I3WAYDONE,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,IWARM_START,N_ONE)
         CALL MP_PUT_INT4(MSGTYPE,ILINK,IBINARY,N_ONE)
      ENDIF
c	if (mp_model .ne. 'PARIX') then
c           do ilink=1,nworker
c	      WRITE(6,*)' send data to: ',link(ilink)
c              call mp_send_data(msgtype,link(ilink))
c	   enddo
      CALL MP_CAST(NWORKER,MSGTYPE,LINK(1))
c	endif

      RETURN
      END
C     END SEND_MAXHOM_DATA
C......................................................................

C......................................................................
C     SUB SEQ_TO_INTEGER
      SUBROUTINE SEQ_TO_INTEGER(SEQ,LSEQ,NRES,TRANSPOS)
C converts string of amino acid characters to amino acid integers.
C uses integer table TRANSPOS
C DOES NOT: internally converts DSSP SS bridges to 'C' before converting to 
C integer. Call "lower_to_cys" before calling this routine
C input may contain funnies like '!'
C output will be according to transpos
      IMPLICIT NONE
C import
      CHARACTER*(*) SEQ
      INTEGER NRES
      INTEGER TRANSPOS(*)
C export
      INTEGER LSEQ(*)
C internal
      INTEGER I
      LOGICAL NOILLEGAL
C     
      NOILLEGAL=.TRUE.
      DO I=1,NRES
         LSEQ(I)=TRANSPOS ( ICHAR(SEQ(I:I)) )
         IF (LSEQ(I) .LE. 0) THEN
            IF (NOILLEGAL) THEN
	       NOILLEGAL=.FALSE.
	       WRITE(6,'(A,I,A,A,A1)')'*** ERROR SEQ_TO_INTEGER: '//
     +              'unknown res or chain separator I=',I,
     +              ' =',SEQ(I:I),'|'
            ENDIF
         ENDIF
      ENDDO
      RETURN
      END
C     END SEQ_TO_INTEGER
C......................................................................

C......................................................................
C     SUB SETBACK  
      SUBROUTINE SETBACK(N1BEG,N1END,N2BEG,N2END,N2,LH1,LH2,
     +     BESTVAL_CHECK)
C-----------------------------------------------------------------------
C  reverse SETMATRIX (see comments there also)
C  here the matrix is processed in the backward direction
C  the best path value is stored in a temporary array MAX_ALL(),
C  NO traceback is stored (this is done in SETMATRIX)
C  the original matrix values are overwritten by the sum of the forward
C  and backward path value
C  this allows the computation of all pairs of residues i,j that
C  CAN BE PART of an optimal and suboptimal alignments.
C  NOTE: optimal value forward = optimal value backward
C        LH_F(i-1,j-1) + sim_val(i,j) + LH_B(i+1,j+1) = LH_FB
C        LH_FB is the score of an optimal alignment of sequence A and B
C        which is constrained to align residue i with residue j
C  All matrix values for THE optimal path have the same value after 
C  this routine. The matrix values can be displayed as a 2-D or 3-D 
C  graph showing how reliable the alignment is.
C  in contrast to Zuker its done in the same memory
C  see:  Zuker M., Suboptimal sequence alignment in molecular biology
C                  Alignment with error analysis
C                  J.Mol.Biol. (1991) 221, 403-429
C 
C      1,1
C       \
C        \
C        LH_B(i+1,j+1)= best value from backward path up to i,j
C
C            \ LH_FB = LH_F + LH_B + sim_val(i,j)
C                      optimal path value trough i,j 
C
C               LH_F(i-1,j-1)= best value from forward path up to i,j
C                \
C                 \
C                  \
C                   N1,N2
C
C=====================================================================
C======================================================================
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
C import
C DIMENSIONS AND ACTUAL SEQ LENGTH
      INTEGER N1BEG,N1END,N2BEG,N2END,N2
      REAL BESTVAL_CHECK
C     IMPORT/EXPORT
      REAL      LH1(0:N1+1,0:N2+1)
      INTEGER*2 LH2(0:N1+1,0:N2+1)
C     REAL LH(0:N1+1,0:N2+1,2)
C     INTERNAL
      INTEGER NSIZE1,NSIZE2
      REAL SUM
      REAL BESTVAL
C     INTEGER BESTII,BESTJJ
      INTEGER I,J,II,JJ,IBEG,IEND,IIBEG,JJBEG,K
      INTEGER NDIAGONAL,LEN_DIAG,IDIAG,ISMALL_DIM,IBIG_DIM
      LOGICAL LERROR
      CHARACTER CTEMP*50
c=======================================================================
c                          initialize
c=======================================================================
c	WRITE(6,*)' setback: ',profilemode
      II=0
      NSIZE1=N1END-N1BEG+1
      NSIZE2=N2END-N2BEG+1
      K=MAX(N1+1,N2+1)
      DO I=0,K
C     DO I=0,MAXSQ+1
         MAX_H(I)=0.0 
         MAX_V(I)=0.0
         RIGHT_LH(I)=0.0 
         DOWN_LH(I)=0.0 
         DIAG_LH(I)=0.0
         MAX_ALL(I)=0.0
      ENDDO
      BESTVAL=0.0
C     BESTII=0 ; BESTJJ=0
C======================================================================
      NDIAGONAL=NSIZE1+NSIZE2-1
C     NDIAGONAL=IPROFEND-IPROFBEG+1+N2-1
      ISMALL_DIM=MIN(NSIZE1,NSIZE2) 
      IBIG_DIM=MAX(NSIZE1,NSIZE2)
      IIBEG=N1END-1 
      JJBEG=N2END 
      LEN_DIAG=0
      DO IDIAG=1,NDIAGONAL
         IF     ( IDIAG .LE. ISMALL_DIM) THEN 
            LEN_DIAG=LEN_DIAG+1
         ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
            LEN_DIAG=LEN_DIAG-1
         ENDIF
         IF (IDIAG .GT. NSIZE2) THEN 
            IIBEG=IIBEG-1
         ELSE                   
            JJBEG=JJBEG-1 
         ENDIF
         JJ=JJBEG+IIBEG
C=====================================================================
C     PROFILE 1 (NO PROFILES OR PROFILE FOR FIRST SEQUENCE)
C--------------------------------------------------------------------
         IF (PROFILEMODE .LE. 1) THEN
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
c=====================================================================
c       store best value for horizontal deletion
c=====================================================================
               IF ( ( (MAX_H(JJ-II) - ELONG_GAP_1(II+1)) .GE.
     +              (RIGHT_LH(JJ-II)-OPEN_GAP_1(II+1)) ) .AND.
     +         ( (MAX_H(JJ-II) - ELONG_GAP_1(II+1)) .GT. 0.0 ) ) THEN 
                  MAX_H(JJ-II)= (MAX_H(JJ-II) - ELONG_GAP_1(II+1)) 
               ELSE IF (( (RIGHT_LH(JJ-II)-OPEN_GAP_1(II+1)) .GE. 
     +                 (MAX_H(JJ-II) - ELONG_GAP_1(II+1)) ) .AND.  
     +            ( (RIGHT_LH(JJ-II)-OPEN_GAP_1(II+1)) .GT. 0.0)) THEN 
                  MAX_H(JJ-II)= (RIGHT_LH(JJ-II) - OPEN_GAP_1(II+1))
               ELSE
                  MAX_H(JJ-II)= 0.0
               ENDIF
c=====================================================================
c       store best value for vertical deletion
c=====================================================================
               IF ( ( (MAX_V(II) - ELONG_GAP_1(II+1)) .GE. 
     +              (DOWN_LH(II) - OPEN_GAP_1(II+1)) ) .AND.
     +              ( (MAX_V(II) - ELONG_GAP_1(II+1)) .GT. 0.0 ) ) THEN 
                  MAX_V(II)=(MAX_V(II) - ELONG_GAP_1(II+1))
               ELSE IF ( ( (DOWN_LH(II) - OPEN_GAP_1(II+1)) .GE. 
     +                 (MAX_V(II) - ELONG_GAP_1(II+1)) ) .AND. 
     +               ((DOWN_LH(II) - OPEN_GAP_1(II+1)) .GT. 0.0)) THEN 
                  MAX_V(II)= (DOWN_LH(II) - OPEN_GAP_1(II+1))
               ELSE
                  MAX_V(II)= 0.0
               ENDIF
c======================================================================
c which value is the best (diagonal,horizontal or vertical)
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+METRIC_1(II+1,LSQ_2(JJ-II+1))
               MAX_ALL(II)=MAX(MAX_D(II),MAX_V(II),MAX_H(JJ-II),0.0)
C set matrix value to forward path + backward path + sim_val 
               LH1(II+1,JJ-II+1)= LH1(II+1,JJ-II+1) + MAX_D(II)
c	      if ( lh1(ii+1,jj-ii+1) .ge. subopt_val) then
c                  lh2(ii+1,jj-ii+1)= -1 * lh2(ii+1,jj-ii+1)
c	      endif
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  LH1(II,II)= 0.0
C     LH2(II,II)= 0
                  MAX_ALL(II)=0.0
               ENDIF
               DIAG_LH(JJ-II)=DOWN_LH(II)
               RIGHT_LH(JJ-II)=MAX_ALL(II)
               DOWN_LH(II)=MAX_ALL(II)
               IF (BESTVAL .LT. MAX_ALL(II) ) THEN
                  BESTVAL=MAX_ALL(II)
C     BESTII=II ; BESTJJ=JJ-II
               ENDIF
	    ENDDO
C--------------------------------------------------------------------
C profile 2  (profile for sequence 2)
C--------------------------------------------------------------------
         ELSE IF (PROFILEMODE .EQ. 2) THEN
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               IF ( (MAX_H(JJ-II) - ELONG_GAP_2(JJ-II+1)) .GT.
     +              (RIGHT_LH(JJ-II)-OPEN_GAP_1(II+1))  .AND.
     +           (MAX_H(JJ-II) - ELONG_GAP_2(JJ-II+1)) .GT. 0.0 ) THEN 
                  MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_2(JJ-II+1))
               ELSE IF ( (RIGHT_LH(JJ-II)-OPEN_GAP_1(II+1)) .GE. 
     +                 (MAX_H(JJ-II) - ELONG_GAP_2(JJ-II+1)) .AND.  
     +               (RIGHT_LH(JJ-II)-OPEN_GAP_1(II+1)) .GT. 0.0) THEN 
                  MAX_H(JJ-II) = (RIGHT_LH(JJ-II) - OPEN_GAP_1(II+1))
               ELSE
                  MAX_H(JJ-II) = 0.0
               ENDIF
               IF ( (MAX_V(II) - ELONG_GAP_2(JJ-II+1)) .GT. 
     +              (DOWN_LH(II) - OPEN_GAP_1(II+1))   .AND.
     +              (MAX_V(II) - ELONG_GAP_2(JJ-II+1)) .GT. 0.0 ) THEN 
                  MAX_V(II) = (MAX_V(II) - ELONG_GAP_2(JJ-II+1))
               ELSE IF ( (DOWN_LH(II) - OPEN_GAP_1(II+1))   .GE. 
     +                 (MAX_V(II) - ELONG_GAP_2(JJ-II+1)) .AND. 
     +               (DOWN_LH(II) - OPEN_GAP_1(II+1))   .GT. 0.0) THEN 
                  MAX_V(II)= (DOWN_LH(II) - OPEN_GAP_1(II+1))
               ELSE
                  MAX_V(II) = 0.0
               ENDIF
               MAX_D(II)= DIAG_LH(JJ-II)+METRIC_2(JJ-II+1,LSQ_1(II+1))
               MAX_ALL(II)=MAX(MAX_D(II),MAX_V(II),MAX_H(JJ-II),0.0)
C set matrix value to forward path + backward path + sim_val 
               LH1(II+1,JJ-II+1)= LH1(II+1,JJ-II+1) + DIAG_LH(JJ-II) +
     +              METRIC_2(JJ-II+1,LSQ_1(II+1))  
               IF ( LH1(II+1,JJ-II+1) .GE. SUBOPT_VAL) THEN
                  LH2(II+1,JJ-II+1)= -1 * LH2(II+1,JJ-II+1)
               ENDIF
               DIAG_LH(JJ-II) = DOWN_LH(II)
               RIGHT_LH(JJ-II)= MAX_ALL(II)
               DOWN_LH(II)    = MAX_ALL(II)
               IF (BESTVAL .LT. MAX_ALL(II) ) THEN
                  BESTVAL=MAX_ALL(II)
C     BESTII=II ; BESTJJ=JJ-II
               ENDIF
	    ENDDO
c--------------------------------------------------------------------
c full profile alignment 
C--------------------------------------------------------------------
         ELSE IF (PROFILEMODE .EQ. 3) THEN
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II)= MAX_H(JJ-II)-
     +              (( ELONG_GAP_1(II+1)+ ELONG_GAP_2(JJ-II+1))* 0.5)
               IF ( (RIGHT_LH(JJ-II)-
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) *0.5 ))
     +              .GE. MAX_H(JJ-II) .AND.  
     +              (RIGHT_LH(JJ-II) -
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) *0.5 ))
     +              .GT. 0.0) THEN 
                  MAX_H(JJ-II) = (RIGHT_LH(JJ-II) -
     +                 ( (OPEN_GAP_1(II+1)+OPEN_GAP_2(JJ-II+1)) *0.5 ))
               ELSE IF ( MAX_H(JJ-II) .LE. 0.0) THEN
                  MAX_H(JJ-II) = 0.0
               ENDIF
               MAX_V(II)= MAX_V(II)-
     +              ( (ELONG_GAP_1(II+1)+ ELONG_GAP_2(JJ-II+1))* 0.5)
               IF ( (DOWN_LH(II) - 
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) * 0.5 ))
     +              .GE. MAX_V(II) .AND. 
     +              (DOWN_LH(II) -  
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) * 0.5 ))
     +              .GT. 0.0) THEN 
                  MAX_V(II)= (DOWN_LH(II) -
     +                 ((OPEN_GAP_1(II+1)+OPEN_GAP_2(JJ-II+1)) * 0.5 ))
               ELSE IF ( MAX_V(II) .LE. 0.0) THEN
                  MAX_V(II) = 0.0
               ENDIF
               SUM=0.0
               DO K=1,NTRANS
                  SUM = SUM + ( METRIC_1(II+1,K) * METRIC_2(JJ-II+1,K) )
               ENDDO
C     MAX_D(II) = DIAG_LH(JJ-II) + (SUM/NTRANS)
               MAX_D(II) = DIAG_LH(JJ-II) + SUM
C     SET MATRIX VALUE TO FORWARD PATH + BACKWARD PATH + SIM_VAL 
               LH1(II+1,JJ-II+1)= LH1(II+1,JJ-II+1) + DIAG_LH(JJ-II) +
     +              SUM  
               IF ( LH1(II+1,JJ-II+1) .GE. SUBOPT_VAL) THEN
                  LH2(II+1,JJ-II+1)= -1 * LH2(II+1,JJ-II+1)
               ENDIF
               MAX_ALL(II)=MAX(MAX_D(II),MAX_V(II),MAX_H(JJ-II),0.0)
               DIAG_LH(JJ-II) = DOWN_LH(II)
               RIGHT_LH(JJ-II)= MAX_ALL(II)
               DOWN_LH(II)    = MAX_ALL(II)
               IF (BESTVAL .LT. MAX_ALL(II) ) THEN
                  BESTVAL=MAX_ALL(II)
C     BESTII=II ; BESTJJ=JJ-II
               ENDIF
	    ENDDO
c--------------------------------------------------------------------
c take sequences as representatives of family
c--------------------------------------------------------------------
         ELSE IF (PROFILEMODE .EQ. 4) THEN
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II)= MAX_H(JJ-II)- 
     +              ( (ELONG_GAP_1(II+1)+ELONG_GAP_2(JJ-II+1)) *0.5)
               IF ( (RIGHT_LH(JJ-II)-
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) *0.5 ))
     +              .GE. MAX_H(JJ-II) .AND.  
     +              (RIGHT_LH(JJ-II) -
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) *0.5 ))
     +              .GT. 0.0) THEN 
                  MAX_H(JJ-II) = (RIGHT_LH(JJ-II) -
     +                 ( (OPEN_GAP_1(II+1)+OPEN_GAP_2(JJ-II+1)) *0.5 ))
               ELSE IF ( MAX_H(JJ-II) .LE. 0.0) THEN
                  MAX_H(JJ-II) = 0.0
               ENDIF
               MAX_V(II)= MAX_V(II)-
     +              ( (ELONG_GAP_1(II+1)+ ELONG_GAP_2(JJ-II+1))* 0.5)
               IF ( (DOWN_LH(II) - 
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) * 0.5 ))
     +              .GE. MAX_V(II) .AND. 
     +              (DOWN_LH(II) -  
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) * 0.5 ))
     +              .GT. 0.0) THEN 
                  MAX_V(II)= (DOWN_LH(II) -
     +                 ( (OPEN_GAP_1(II+1)+OPEN_GAP_2(JJ-II+1)) * 0.5 ))
               ELSE IF ( MAX_V(II) .LE. 0.0) THEN
                  MAX_V(II) = 0.0
               ENDIF
               MAX_D(II)= DIAG_LH(JJ-II) +
     +              (( METRIC_1 (II+1,LSQ_2(JJ-II+1)) +
     +              METRIC_2 (JJ-II+1,LSQ_1(II+1)) ) * 0.5)
               MAX_ALL(II)=MAX(MAX_D(II),MAX_V(II),MAX_H(JJ-II),0.0)
C     SET MATRIX VALUE TO FORWARD PATH + BACKWARD PATH + SIM_VAL 
               LH1(II+1,JJ-II+1)= LH1(II+1,JJ-II+1) + DIAG_LH(JJ-II) +
     +              (( METRIC_1 (II+1,LSQ_2(JJ-II+1)) +
     +              METRIC_2 (JJ-II+1,LSQ_1(II+1)) ) * 0.5)
               IF ( LH1(II+1,JJ-II+1) .GE. SUBOPT_VAL) THEN
                  LH2(II+1,JJ-II+1)= -1.0 * LH2(II+1,JJ-II+1)
               ENDIF
               DIAG_LH(JJ-II) = DOWN_LH(II)
               RIGHT_LH(JJ-II)= MAX_ALL(II)
               DOWN_LH(II)    = MAX_ALL(II)
               IF (BESTVAL .LT. MAX_ALL(II) ) THEN
                  BESTVAL=MAX_ALL(II)
C     BESTII=II ; BESTJJ=JJ-II
               ENDIF
	    ENDDO
C--------------------------------------------------------------------
C take maximal value as consensus
C--------------------------------------------------------------------
         ELSE IF (PROFILEMODE .EQ. 5) THEN
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II)=MAX_H(JJ-II) - 
     +              ((ELONG_GAP_1(II+1)+ELONG_GAP_2(JJ-II+1))*0.5)
               IF ( (RIGHT_LH(JJ-II)-
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) *0.5 ))
     +              .GE. MAX_H(JJ-II) .AND.  
     +              (RIGHT_LH(JJ-II) -
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) *0.5 ))
     +              .GT. 0.0) THEN 
                  MAX_H(JJ-II) = (RIGHT_LH(JJ-II) -
     +               ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) *0.5 ))
               ELSE IF ( MAX_H(JJ-II) .LE. 0.0) THEN
                  MAX_H(JJ-II) = 0.0
               ENDIF
               MAX_V(II)= MAX_V(II)-
     +              ( (ELONG_GAP_1(II+1)+ ELONG_GAP_2(JJ-II+1))* 0.5)
               IF ( (DOWN_LH(II) - 
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) * 0.5 ))
     +              .GE. MAX_V(II) .AND. 
     +              (DOWN_LH(II) -  
     +              ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) * 0.5 ))
     +              .GT. 0.0) THEN 
                  MAX_V(II)= (DOWN_LH(II) -
     +               ( (OPEN_GAP_1(II+1) + OPEN_GAP_2(JJ-II+1)) * 0.5 ))
               ELSE IF ( MAX_V(II) .LE. 0.0) THEN
                  MAX_V(II) = 0.0
               ENDIF
               MAX_D(II) = DIAG_LH(JJ-II) + 
     +        ((MAX_METRIC_1_VAL(II+1) + MAX_METRIC_2_VAL(II+1)) * 0.5)
               MAX_ALL(II)=MAX(MAX_D(II),MAX_V(II),MAX_H(JJ-II),0.0)
C     SET MATRIX VALUE TO FORWARD PATH + BACKWARD PATH + SIM_VAL 
               LH1(II+1,JJ-II+1)= LH1(II+1,JJ-II+1) + DIAG_LH(JJ-II) +
     +         ((MAX_METRIC_1_VAL(II+1) + MAX_METRIC_2_VAL(II+1)) * 0.5)
               IF ( LH1(II+1,JJ-II+1) .GE. SUBOPT_VAL) THEN
                  LH2(II+1,JJ-II+1)= -1 * LH2(II+1,JJ-II+1)
               ENDIF
               DIAG_LH(JJ-II) = DOWN_LH(II)
               RIGHT_LH(JJ-II)= MAX_ALL(II)
               DOWN_LH(II)    = MAX_ALL(II)
               IF (BESTVAL+0.0001 .LT. MAX_ALL(II) ) THEN
                  BESTVAL=MAX_ALL(II)
C     BESTII=II ; BESTJJ=JJ-II
               ENDIF
	    ENDDO
C====================================================================
C     PROFILE MODE SELECTION END
         ENDIF
C=======================================================================
         IF (LSAMESEQ) THEN
            I=II 
            IF (II .LE. 0)I=JJ-II
            LH1(I,I) = 0.0
            RIGHT_LH(I)= 0.0    
            DOWN_LH(I)  = 0.0
         ENDIF
C====================================================================
C next antidiagonal
C====================================================================
      ENDDO
C====================================================================
c	WRITE(6,*)' SETBACK: ',BESTVAL,BESTII,BESTJJ
C write data for SciAn, XPrism3...
      IF (ABS(BESTVAL_CHECK - BESTVAL) .GT. 0.01) THEN
         WRITE(6,*)'*** FATAL ERROR in SETBACK'
         WRITE(6,*)' bestval_check .ne. bestval: ',
     +        BESTVAL_CHECK,BESTVAL
         STOP
      ENDIF
      CTEMP=' ' 
      WRITE(CTEMP,*) '(',N2,'(F7.2))'
      CALL STRPOS(CTEMP,IBEG,IEND)
      CALL OPEN_FILE(99,'matrix.dat','new,recl=20000',lerror)
      DO I=1,N1
         WRITE(99,CTEMP(IBEG:IEND)) ( LH1(I,J),J=1,N2)
      ENDDO
      CLOSE(99)
C====================================================================
      RETURN
      END
C     END SETBACK
C......................................................................

C......................................................................
C     SUB SETMATRIX
      SUBROUTINE SETMATRIX(N1BEG,N1END,N2BEG,N2END,N2,LH1,LH2)
C   --------------------------------------------------------
C   subroutine SETMATRIX finds LH matrix for maximum homologous 
C   subsequence between any two sequences 
C   generate the homology and traceback matrix
C-----------------------------------------------------------------------
C  LH(.,.,1) is homology score     
C  LH(.,.,2) is traceback value    
C            encoding LDIREC and LDEL: DIREC + LDEL
C            LH(I,J,1) corresponds to seq postions II=I-1, JJ=J-1
C            LH(1,.,1) and LH(.,1,1) are terminal margins
C  LDIREC 10000,20000,30000,40000 for termination,diagonal,vertical,horizontal
C  LDEL   length of deletion
C  temporary values:
C  MAX_H(),MAX_V() best value for horizontal and verical deletions
C  LDEL_H,LDEL_V length of horizontal and vertical deletion
C======================================================================
C   JULY 1991 (RS)
C   MAXDEL restriction removed
C   see: O. Gotoh, An Improved Algorithm for Matching Biological 
C        Sequences, JMB (1982) 162, 705-708
C-----------------------------------------------------------------------
C   JUNE 1991 (RS)
C   matrix setting in a antidiagonal way to run it in parallel
C   see: Jones R. et.al., Protein Sequence Comparison on the Connection 
C        Machine CM-2, in: Computers and DNA, SFI Studies in the Sciences
C                        of Complexity, Vol VII, Addison-Wesley, 1990
C======================================================================
C
C               ANTIDIAGONAL SETTING OF THE MATRIX
C               ==================================
C N1,N2: length of sequence 1 and sequence 2
C ADVANTAGE: loop can run in parallel or vectorized
C
C
C  ICOUNT            2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
C     ----------------------------------------------------->    
C    |             sequence 1 ====>                 N1            
C    |              2345678901234567890123456789 <==IIBEG         
C    |            ------------------------------         
C  1 | sequence2  | ////  /                   /|        
C  2 |    |     2 |////  /                   / |       
C  3 |    |     3 |///  /                   / /| <== JJBEG
C  4 |    |     4 |//  /                   / //|    
C  5 |    v     5 |/  /                   / ///|    
C  6 |          6 |  /                   / ////|    
C  7 |          7 | /                   / /////|  
C  8 |       N2 8 |/                   / //////| 
C  9 |            -----------------------------|
C 10 |                                   
C 11 |                                  
C 12 |                                  
C 13 |
C    V           
C
C=====================================================================
C at each position take the best value of:
C
C LH(i,j,1)= MAX( LH(i-1,j-1,1) + SIM(i,j) , MAX_H(j) ,MAX_V(i) ,0)
C
C LH(i-1,j-1,1)  : best value of diagonal (no INDEL) 
C SIM(i,j)       : similarity value for position i,j
C MAX_H(j)       : best value of horizontal INDELs
C MAX_V(i)       : best value of vertical INDELs
C where:
C MAX_H(i)=MAX( LH(I-1,J,1) - gap-open , MAX_H(i-1) - gap-elongation , 0)
C MAX_V(j)=MAX( LH(I,J-1,1) - gap-open , MAX_V(j-1) - gap-elongation , 0)
C NOTE: one has to store the length of the deletion for MAX_H() and MAX_V()
C       in LDEL_H(j) and LDEL_V()
C
C
C NOTE: 
C 1) if no INDEL(s) in secondary structure allowed:
C    GAPOPEN contains PUNISH
C 2) internal deletions are (postion dependent ) weighted as:
C    GAPOPEN + GAPELONG *LENGTH 
C 3) conservation weights:
C    gap penalties are dependent on sequence-position(s), so weight 
C    gap-penalties with conservation-weights otherwise the gap penalties
C    in regions with low conservation are too big
C 4) antidiagonal matrix setting:
C    position in sequence 2 is JJBEG+IIBEG-II: step back in sequence 1 and 
C    down in sequence 2
C    
C 5) NOT LONGER VALID   
C    if the MAXDEL option is set, one has to check if the number of
C    INDEL's exceeds the MAXDEL value.
C    In addition: when the value for opening a gap is higher than 
C    for the elongation, we have to check if the previous length of
C    the gap is not greater than 0.
C    That means that for some special cases it's cheaper to punish
C    the alignment by some open-penalties in a row than to elongate
C    or continue the alignment in the diagonal.
C    open a gap if:
C           1.) OPEN .gt. ELONG or 
C           2.) LDELx()+1 .ge. MAXDEL
C           3.) but only if LDELx() .eq. 0
C======================================================================
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
C import
C ACTUAL SEQ LENGTH
      INTEGER N1BEG,N1END,N2BEG,N2END,N2
c export
      REAL      LH1(0:N1+1,0:N2+1)
      INTEGER*2 LH2(0:N1+1,0:N2+1)
c	real lh(0:n1+1,0:n2+1,2)
c internal
      INTEGER NSIZE1,NSIZE2
      REAL SUM,XMAX1,XMAX2
      INTEGER I,J,K,NDAMP,NDIAGONAL,ISMALL_DIM,IBIG_DIM,IIBEG,JJBEG
      INTEGER LEN_DIAG,IDIAG,II,JJ
C=======================================================================
C                 DO SOME STUFF OUTSIDE THE LOOPS:
C=======================================================================
C                          initialize
C=======================================================================
C      WRITE(*,*)' info: inside SETMATRIX '
      NSIZE1=N1END-N1BEG+1
      NSIZE2=N2END-N2BEG+1
      
      DO I=N1BEG-1,N1END+1
         LH1(I,N2BEG-1)=0.0 
         LH1(I,N2BEG)=0.0
      ENDDO
      DO J=N2BEG-1,N2END+1
         LH1(N1BEG-1,J)=0.0 
         LH1(N1BEG,J)=0.0
      ENDDO
      
C     DO I=0,N1+1  LH(I,0,1)=0.0 ; LH(I,1,1)=0.0 ; ENDDO
C     DO J=0,N2+1 ; LH(0,J,1)=0.0 ; LH(1,J,1)=0.0 ; ENDDO
      
      J=MIN(N1BEG-1,N2BEG-1) 
      K=MAX(N1END+1,N2END+1)
      DO I=J,K
C     DO I=0,MAXSQ+1
         MAX_H(I)=0.0 
         MAX_V(I)=0.0 
         LDEL_H(I)=0 
         LDEL_V(I)=0
         LEFT_LH(I)=0.0 
         UP_LH(I)=0.0 
         DIAG_LH(I)=0.0
      ENDDO
C=======================================================================
C update the metric values (weights)
C this can be done outside the main parallel loop
C with this we save at lot of multiplications in the parallel loop
C the update can be done in concurrent/vectorized mode 
C=======================================================================
      NDAMP=1
      
      IF (PROFILEMODE .EQ. 6) THEN
         
         IF (LCONSERV_1) THEN
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1(I) * CONSWEIGHT_1(I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I) * CONSWEIGHT_1(I)
	    ENDDO
C     DAMP PENALTIES
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ELSE
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1 (I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ENDIF
         
         IF (LCONSERV_2) THEN
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ELSE
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ENDIF
C=============================
      ELSE IF (PROFILEMODE .NE. 2) THEN
         IF (LCONSERV_1) THEN
	    DO K=1,NTRANS 
               DO I=N1BEG,N1END
                  METRIC_1(I,K) = SIMMETRIC_1(I,K) * CONSWEIGHT_1(I)
               ENDDO
            ENDDO
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1(I) * CONSWEIGHT_1(I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I) * CONSWEIGHT_1(I)
	    ENDDO
c damp penalties
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ELSE
	    DO K=1,NTRANS 
               DO I=N1BEG,N1END
                  METRIC_1(I,K) = SIMMETRIC_1(I,K)
               ENDDO
            ENDDO
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1 (I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ENDIF
      ENDIF
      IF (PROFILEMODE .GE. 2) THEN
         IF (LCONSERV_2) THEN
	    DO K=1,NTRANS 
               DO I=N2BEG,N2END 
                  METRIC_2(I,K)  = SIMMETRIC_2(I,K) * CONSWEIGHT_2(I)
               ENDDO
            ENDDO
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ELSE
	    DO K=1,NTRANS 
               DO I=N2BEG,N2END
                  METRIC_2(I,K) = SIMMETRIC_2(I,K)
               ENDDO
            ENDDO
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ENDIF
      ENDIF
      IF (PROFILEMODE .EQ. 5) THEN
         DO I=N1BEG,N1END
            MAX_METRIC_1_VAL(I)=-10000.0
            DO K=1,NTRANS
               MAX_METRIC_1_VAL(I)=
     +              MAX(METRIC_1(I,K),MAX_METRIC_1_VAL(I))
            ENDDO
         ENDDO
         DO J=N2BEG,N2END
            MAX_METRIC_2_VAL(J)=-10000.0
            DO K=1,NTRANS
               MAX_METRIC_2_VAL(J)=
     +              MAX(METRIC_2(J,K),MAX_METRIC_2_VAL(J))
            ENDDO
         ENDDO
      ENDIF
      IF ( PROFILEMODE .EQ. 3 ) THEN
         DO I=N1BEG,N1END 
            SUM=0.0
            DO K=1,NTRANS 
               SUM= SUM + ( METRIC_1(I,K) * METRIC_1(I,K) )
            ENDDO
            SUM= SQRT(SUM)
            DO K=1,NTRANS 
               METRIC_1(I,K)= METRIC_1(I,K) / SUM
            ENDDO
         ENDDO
         DO I=N2BEG,N2END 
            SUM=0.0
            DO K=1,NTRANS 
               SUM= SUM + ( METRIC_2(I,K) * METRIC_2(I,K) )
            ENDDO
            SUM= SQRT(SUM)
            DO K=1,NTRANS 
               METRIC_2(I,K)= METRIC_2(I,K) / SUM
            ENDDO
         ENDDO
      ENDIF
c======================================================================
      NDIAGONAL=NSIZE1+NSIZE2-1
c	ndiagonal=iprofend-iprofbeg+1+n2-1
c	WRITE(6,'(A,I6)')' NUMBER OF ANTIDIAGONALS: ',NDIAGONAL
      ISMALL_DIM=MIN(NSIZE1,NSIZE2) 
      IBIG_DIM=MAX(NSIZE1,NSIZE2)
      IIBEG=N1BEG 
      JJBEG=N2BEG+1 
      LEN_DIAG=0
C=====================================================================
C profile 1 (no profiles or profile for first sequence)
C--------------------------------------------------------------------
      IF (PROFILEMODE .LE. 1) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
C====================================================================
C                 THIS LOOP CAN BE EXECUTED IN VECTOR-MODE 
C======================================================================
C               compiler directives for vector
C----------------------------------------------------------------------
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
C======================================================================
C values for diagonal, horizontal and vertical (open and elongation)
C=====================================================================
C       store best value and length for horizontal deletion
C=====================================================================
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_1(II-1))
               IF ((MAX_H(JJ-II) .GE.(LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)))
     +              .AND. (MAX_H(JJ-II) .GT.0.0 )) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF (((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GE. 
     +                 MAX_H(JJ-II)) 
     +                 .AND. ((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II)= (LEFT_LH(JJ-II) - OPEN_GAP_1(II-1))
               ELSE
                  MAX_H(JJ-II)= 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_1(II-1))
               IF ((MAX_V(II).GE.(UP_LH(II) - OPEN_GAP_1(II-1))) .AND.
     +              ( MAX_V(II) .GT. 0.0) ) THEN 
                  LDEL_V(II)= LDEL_V(II) + 1 
               ELSE IF (((UP_LH(II) - OPEN_GAP_1(II-1)).GE.MAX_V(II)) 
     +                 .AND.((UP_LH(II)- OPEN_GAP_1(II-1)).GT.
     +                 0.0)) THEN 
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_1(II-1))
                  LDEL_V(II)=1
               ELSE
                  MAX_V(II)= 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+METRIC_1(II-1,LSQ_2(JJ-II-1))
               IF (      (MAX_D(II) .GE. MAX_V(II) )   .AND.
     +              (MAX_D(II) .GE. MAX_H(JJ-II)) .AND.
     +              (MAX_D(II) .GT. 0.0 )) THEN
	          LH1(II,JJ-II)= MAX_D(II)
               ELSE IF ( (MAX_V(II) .GE. MAX_D(II) )   .AND.
     +                 (MAX_V(II) .GE. MAX_H(JJ-II)) .AND.
     +                 (MAX_V(II) .GT. 0.0 )) THEN
	          LH1(II,JJ-II)= MAX_V(II)
	          LH2(II,JJ-II)= 10000 + LDEL_V(II)
               ELSE IF ( (MAX_H(JJ-II) .GE. MAX_D(II))    .AND.
     +                 (MAX_H(JJ-II) .GE. MAX_V(II)) .AND.
     +                 (MAX_H(JJ-II) .GT. 0.0 )) THEN
	          LH1(II,JJ-II)= MAX_H(JJ-II)
	          LH2(II,JJ-II)= 20000 + LDEL_H(JJ-II)
               ELSE
	          LH1(II,JJ-II)= 0.0
	          LH2(II,JJ-II)= 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  LH1(II,II)= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)= UP_LH(II)
               LEFT_LH(JJ-II)= LH1(II,JJ-II)
               UP_LH(II)= LH1(II,JJ-II)
            ENDDO

c	   if (lsameseq) then
c             x= ( float(iibeg)/ 2.0) + (float(jjbeg)/2.0) 
c	       i=nint(x)
c	       lh1(i,i) = 0.0    ; lh2(i,i)= 0
c	       left_lh(i)= 0.0
c	       up_lh(i)  = 0.0
c	       WRITE(6,*)iibeg,jjbeg,i
c	   endif
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C--------------------------------------------------------------------
C profile 2  (profile for sequence 2)
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 2) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_2(JJ-II-1))
               IF (MAX_H(JJ-II) .GT. 
     +              (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1))  .AND.
     +              MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1)) .GE.
     +                 MAX_H(JJ-II) .AND.
     +                 (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1)).GT.
     +                 0.0) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_2(JJ-II-1))
               IF (MAX_V(II).GT.(UP_LH(II) - OPEN_GAP_2(JJ-II-1)).AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ((UP_LH(II)-OPEN_GAP_2(JJ-II-1)) .GE. MAX_V(II) 
     +                 .AND.(UP_LH(II)-OPEN_GAP_2(JJ-II-1)).GT.0.0) THEN
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_2(JJ-II-1))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
c======================================================================
c which value is the best (diagonal,horizontal or vertical)
c======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+METRIC_2(JJ-II-1,LSQ_1(II-1))
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
	          LH1(II,JJ-II) = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
	          LH1(II,JJ-II) = MAX_V(II)
	          LH2(II,JJ-II) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
	          LH1(II,JJ-II) = MAX_H(JJ-II)
	          LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
               ELSE
	          LH1(II,JJ-II) = 0.0
	          LH2(II,JJ-II) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  LH1(II,II)= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= LH1(II,JJ-II)
               UP_LH(II)     = LH1(II,JJ-II)
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
c--------------------------------------------------------------------
C full profile alignment 
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 3) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG

CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               
               SUM=0.0 
               XMAX1=0.0 
               XMAX2=0.0
               DO K=1,NTRANS
                  SUM = SUM + ( METRIC_1(II-1,K) * METRIC_2(JJ-II-1,K) )
                  IF ( ( METRIC_1(II-1,K) * METRIC_2(JJ-II-1,K) )
     +                 .GT. XMAX1 ) THEN
                     XMAX1 = ( METRIC_1(II-1,K) * METRIC_2(JJ-II-1,K) )
                  ENDIF
               ENDDO
	      
               OPEN_GAP_1(II-1)     = OPEN_GAP_1(II-1)     * XMAX1
               ELONG_GAP_1(II-1)    = ELONG_GAP_1(II-1)    * XMAX1
               OPEN_GAP_2(JJ-II-1)  = OPEN_GAP_2(JJ-II-1)  * XMAX1
               ELONG_GAP_2(JJ-II-1) = ELONG_GAP_2(JJ-II-1) * XMAX1
               
               MAX_H(JJ-II)= MAX_H(JJ-II)-
     +              (( ELONG_GAP_1(II-1)+ ELONG_GAP_2(JJ-II-1))* 0.5)
               IF (MAX_H(JJ-II) .GT.  (LEFT_LH(JJ-II)-
     +              (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +              .AND. MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GE. MAX_H(JJ-II) .AND. (LEFT_LH(JJ-II)- 
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT.0.0) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
C=====================================================================
C       store best value and length for vertical deletion
C=====================================================================
               MAX_V(II)= MAX_V(II)-
     +              (( ELONG_GAP_1(II-1)+ ELONG_GAP_2(JJ-II-1))* 0.5)
               IF ( MAX_V(II) .GT. (UP_LH(II)-
     +              (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ( (UP_LH(II)- (( OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GE. MAX_V(II)
     +                 .AND.  (UP_LH(II)- ((OPEN_GAP_1(II-1)+ 
     +                 OPEN_GAP_2(JJ-II-1))*0.5)).GT.0.0) THEN
                  MAX_V(II)= (UP_LH(II)-
     +                 (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II) = DIAG_LH(JJ-II) + SUM
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
                  LH1(II,JJ-II) = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
                  LH1(II,JJ-II) = MAX_V(II)
                  LH2(II,JJ-II) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
                  LH1(II,JJ-II) = MAX_H(JJ-II)
                  LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
               ELSE
                  LH1(II,JJ-II) = 0.0
                  LH2(II,JJ-II) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  LH1(II,II)= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= LH1(II,JJ-II)
               UP_LH(II)     = LH1(II,JJ-II)
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C--------------------------------------------------------------------
C take sequences as representatives of family
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 4) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II)= MAX_H(JJ-II)- 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1)) *0.5)
               IF (MAX_H(JJ-II) .GT. (LEFT_LH(JJ-II) -
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +              .AND. MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II) - ((OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GE. MAX_H(JJ-II) 
     +                 .AND. (LEFT_LH(JJ-II) - ((OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GT. 0.0 ) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
	      ENDIF
C=====================================================================
C       store best value and length for vertical deletion
C=====================================================================
	      MAX_V(II)= (MAX_V(II)- 
     +             ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1)) *0.5))
	      IF ( MAX_V(II) .GT.  (UP_LH(II)-
     +             ((OPEN_GAP_1(II-1) +OPEN_GAP_2(JJ-II-1)) *0.5)) 
     +             .AND. MAX_V(II) .GT. 0.0 ) THEN
                 LDEL_V(II) = LDEL_V(II) + 1
              ELSE IF ( (UP_LH(II)- 
     +                ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)).GE. 
     +                MAX_V(II) 
     +                .AND.  (UP_LH(II)- ((OPEN_GAP_1(II-1) +
     +                OPEN_GAP_2(JJ-II-1)) *0.5)) .GT. 0.0 ) THEN
                 MAX_V(II)=(UP_LH(II)-
     +                ((OPEN_GAP_1(II-1) +OPEN_GAP_2(JJ-II-1)) *0.5))
                 LDEL_V(II)= 1
              ELSE
                 MAX_V(II) = 0.0 
                 LDEL_V(II)= 0
	      ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
	      MAX_D(II)= DIAG_LH(JJ-II) +
     +             (( METRIC_1 (II-1,LSQ_2(JJ-II-1)) +
     +             METRIC_2 (JJ-II-1,LSQ_1(II-1)) ) * 0.5)
	      IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +             MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +             MAX_D(II) .GT. 0.0) THEN
                 LH1(II,JJ-II) = MAX_D(II)
	      ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                MAX_V(II) .GT. 0.0) THEN
                 LH1(II,JJ-II) = MAX_V(II)
                 LH2(II,JJ-II) = 10000 + LDEL_V(II)
	      ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                MAX_H(JJ-II) .GT. 0.0) THEN
                 LH1(II,JJ-II) = MAX_H(JJ-II)
                 LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
              ELSE
                 LH1(II,JJ-II) = 0.0
                 LH2(II,JJ-II) = 0
	      ENDIF
	      IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                 LH1(II,II)= 0.0 
                 LH2(II,II)= 0
	      ENDIF
	      DIAG_LH(JJ-II)=    UP_LH(II)
	      LEFT_LH(JJ-II)= LH1(II,JJ-II)
	      UP_LH(II)     = LH1(II,JJ-II)
           ENDDO
C====================================================================
C next antidiagonal
C====================================================================
        ENDDO
C--------------------------------------------------------------------
C take maximal value as consensus
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 5) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               
               MAX_H(JJ-II)=MAX_H(JJ-II) - 
     +              ((ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1))*0.5)
               IF (MAX_H(JJ-II) .GT. (LEFT_LH(JJ-II) -
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))  
     +              .AND. MAX_H(JJ-II) .GT. 0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ((LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)).GE.
     +                 MAX_H(JJ-II) .AND. (LEFT_LH(JJ-II) -  
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT. 0.0) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
C=====================================================================
C       store best value and length for vertical deletion
C=====================================================================
               MAX_V(II)= MAX_V(II) - 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1))*0.5)
               IF ( MAX_V(II) .GT. (UP_LH(II)-
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ((UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)).GE.
     +                 MAX_V(II) .AND. (UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT. 0.0) THEN
                  MAX_V(II)= (UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II) = DIAG_LH(JJ-II) + 
     +            ((MAX_METRIC_1_VAL(II-1)+MAX_METRIC_2_VAL(II-1))*0.5)
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
	          LH1(II,JJ-II) = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
	          LH1(II,JJ-II) = MAX_V(II)
	          LH2(II,JJ-II) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
	          LH1(II,JJ-II) = MAX_H(JJ-II)
	          LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
               ELSE
	          LH1(II,JJ-II) = 0.0
	          LH2(II,JJ-II) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  LH1(II,II)= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= LH1(II,JJ-II)
               UP_LH(II)     = LH2(II,JJ-II)
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C====================================================================
      ELSE IF (PROFILEMODE .EQ. 6) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
C=====================================================================
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_1(II-1))
               IF ((MAX_H(JJ-II) .GE.(LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)))
     +              .AND. (MAX_H(JJ-II) .GT.0.0 )) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF (((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GE. 
     +                 MAX_H(JJ-II)) 
     +                 .AND.((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)).GT.
     +                 0.0)) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II)= (LEFT_LH(JJ-II) - OPEN_GAP_1(II-1))
               ELSE
                  MAX_H(JJ-II)= 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_1(II-1))
               IF ( (MAX_V(II) .GE. (UP_LH(II) - OPEN_GAP_1(II-1)))
     +              .AND.( MAX_V(II) .GT. 0.0) ) THEN 
                  LDEL_V(II)= LDEL_V(II) + 1
               ELSE IF (((UP_LH(II) - OPEN_GAP_1(II-1)).GE. MAX_V(II)) 
     +                 .AND. ((UP_LH(II) - OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_1(II-1))
                  LDEL_V(II)=1
               ELSE
                  MAX_V(II)= 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================

               MAX_D(II)= DIAG_LH(JJ-II) + 
     +              SIMORG(LSQ_1(II-1),LSQ_2(JJ-II-1),LSTRCLASS_1(II-1),
     +              LACC_1(II-1),LSTRCLASS_2(JJ-II-1),
     +              LACC_2(JJ-II-1) )
               IF (      (MAX_D(II) .GE. MAX_V(II) )   .AND.
     +              (MAX_D(II) .GE. MAX_H(JJ-II)) .AND.
     +              (MAX_D(II) .GT. 0.0 )) THEN
	          LH1(II,JJ-II)= MAX_D(II)
               ELSE IF ( (MAX_V(II) .GE. MAX_D(II) )   .AND.
     +                 (MAX_V(II) .GE. MAX_H(JJ-II)) .AND.
     +                 (MAX_V(II) .GT. 0.0 )) THEN
	          LH1(II,JJ-II)= MAX_V(II)
	          LH2(II,JJ-II)= 10000 + LDEL_V(II)
               ELSE IF ( (MAX_H(JJ-II) .GE. MAX_D(II))    .AND.
     +                 (MAX_H(JJ-II) .GE. MAX_V(II)) .AND.
     +                 (MAX_H(JJ-II) .GT. 0.0 )) THEN
	          LH1(II,JJ-II)= MAX_H(JJ-II)
	          LH2(II,JJ-II)= 20000 + LDEL_H(JJ-II)
               ELSE
	          LH1(II,JJ-II)= 0.0
	          LH2(II,JJ-II)= 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  LH1(II,II)= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)= UP_LH(II)
               LEFT_LH(JJ-II)= LH1(II,JJ-II)
               UP_LH(II)= LH1(II,JJ-II)
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C====================================================================
C PROFILE MODE SELECTION END
      ENDIF
C====================================================================
C debug: output the LH (values and trace-back)matrix 
c      call open_file(99,'matrix.dat','new,recl=2000',lerror)
c      nii=n1+1 ; njj=n2+1
c      write(99,*) 'H-MATRIX Hij'
c      write(99,*)'Index i for Seq. 1' ; write(99,*)'Index j for Seq. 2'
c      do i=1,nii 
c	  write(99,'(i6)')i ; write(99,'(2x,20(i6))')(lh1(i,j),j=1,njj)
c      enddo
c      write(99,*)'TRACE-BACK MATRIX' 
c      do i=1,nii
c	  write(99,'(i6)')i ; write(99,'(2x,20(i6))')(lh2(i,j),j=1,njj)
c      enddo
c      close(99)
C
C write data for XPrism3
c	call open_file(99,'xprism3.dat','new',lerror)
c	do I=0,N1+1 	
c          write(99,*) (lh1(i,j),J=0,N2+1)
c	enddo
c       do I=0,N1+1 ; do J=0,N2+1 	
cc          write(99,'(2x,i5,2x,i4,f7.2)')i,j,lh1(i,j)
cc          write(99,'(2x,i5,2x,i4,f7.2)')i,j,lh1(i,j)
c trace back
cc          write(99,'(2x,i5,2x,i4,f7.2,1x,i6)')i,j,lh1(i,j),lh2(i,j)
c       ENDDO; enddo
c       close(99)
C=======================================================================
      RETURN
      END              
C     END SETMATRIX
C......................................................................

C......................................................................
C     SUB SETMATRIX_FAST
      SUBROUTINE SETMATRIX_FAST(N1BEG,N1END,N2BEG,N2END,N2,LH2,
     +     BESTVAL,BESTIIPOS,BESTJJPOS)
C   --------------------------------------------------------
C   subroutine SETMATRIX_fast finds LH matrix for maximum homologous 
C   subsequence between any two sequences 
C   generate the homology and traceback matrix
C-----------------------------------------------------------------------
C  LH(.,.,1) is homology score     
C  LH(.,.,2) is traceback value    
C            encoding LDIREC and LDEL: DIREC + LDEL
C            LH(I,J,1) corresponds to seq postions II=I-1, JJ=J-1
C            LH(1,.,1) and LH(.,1,1) are terminal margins
C  LDIREC 10000,20000,30000,40000 for termination,diagonal,vertical,horizontal
C  LDEL   length of deletion
C  temporary values:
C  MAX_H(),MAX_V() best value for horizontal and verical deletions
C  LDEL_H,LDEL_V length of horizontal and vertical deletion
C======================================================================
C   JULY 1991 (RS)
C   MAXDEL restriction removed
C   see: O. Gotoh, An Improved Algorithm for Matching Biological 
C        Sequences, JMB (1982) 162, 705-708
C-----------------------------------------------------------------------
C   JUNE 1991 (RS)
C   matrix setting in a antidiagonal way to run it in parallel
C   see: Jones R. et.al., Protein Sequence Comparison on the Connection 
C        Machine CM-2, in: Computers and DNA, SFI Studies in the Sciences
C                        of Complexity, Vol VII, Addison-Wesley, 1990
C======================================================================
C
C               ANTIDIAGONAL SETTING OF THE MATRIX
C               ==================================
C N1,N2: length of sequence 1 and sequence 2
C ADVANTAGE: loop can run in parallel or vectorized
C
C
C  ICOUNT            2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
C     ----------------------------------------------------->    
C    |             sequence 1 ====>                 N1            
C    |              2345678901234567890123456789 <==IIBEG         
C    |            ------------------------------         
C  1 | sequence2  | ////  /                   /|        
C  2 |    |     2 |////  /                   / |       
C  3 |    |     3 |///  /                   / /| <== JJBEG
C  4 |    |     4 |//  /                   / //|    
C  5 |    v     5 |/  /                   / ///|    
C  6 |          6 |  /                   / ////|    
C  7 |          7 | /                   / /////|  
C  8 |       N2 8 |/                   / //////| 
C  9 |            -----------------------------|
C 10 |                                   
C 11 |                                  
C 12 |                                  
C 13 |
C    V           
C
C=====================================================================
C at each position take the best value of:
C
C LH(i,j,1)= MAX( LH(i-1,j-1,1) + SIM(i,j) , MAX_H(j) ,MAX_V(i) ,0)
C
C LH(i-1,j-1,1)  : best value of diagonal (no INDEL) 
C SIM(i,j)       : similarity value for position i,j
C MAX_H(j)       : best value of horizontal INDELs
C MAX_V(i)       : best value of vertical INDELs
C where:
C MAX_H(i)=MAX( LH(I-1,J,1) - gap-open , MAX_H(i-1) - gap-elongation , 0)
C MAX_V(j)=MAX( LH(I,J-1,1) - gap-open , MAX_V(j-1) - gap-elongation , 0)
C NOTE: one has to store the length of the deletion for MAX_H() and MAX_V()
C       in LDEL_H(j) and LDEL_V()
C
C
C NOTE: 
C 1) if no INDEL(s) in secondary structure allowed:
C    GAPOPEN contains PUNISH
C 2) internal deletions are (postion dependent ) weighted as:
C    GAPOPEN + GAPELONG *LENGTH 
C 3) conservation weights:
C    gap penalties are dependent on sequence-position(s), so weight 
C    gap-penalties with conservation-weights otherwise the gap penalties
C    in regions with low conservation are too big
C 4) antidiagonal matrix setting:
C    position in sequence 2 is JJBEG+IIBEG-II: step back in sequence 1 and 
C    down in sequence 2
C    
C 5) NOT LONGER VALID   
C    if the MAXDEL option is set, one has to check if the number of
C    INDEL's exceeds the MAXDEL value.
C    In addition: when the value for opening a gap is higher than 
C    for the elongation, we have to check if the previous length of
C    the gap is not greater than 0.
C    That means that for some special cases it's cheaper to punish
C    the alignment by some open-penalties in a row than to elongate
C    or continue the alignment in the diagonal.
C    open a gap if:
C           1.) OPEN .gt. ELONG or 
C           2.) LDELx()+1 .ge. MAXDEL
C           3.) but only if LDELx() .eq. 0
C======================================================================
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
C import
C ACTUAL SEQ LENGTH
      INTEGER N1BEG,N1END,N2BEG,N2END,N2
c export
c	real lh1(0:n1+1,0:n2+1)
      INTEGER*2 LH2(0:N1+1,0:N2+1)
c	real lh(0:n1+1,0:n2+1)
      REAL BESTVAL
      INTEGER BESTIIPOS,BESTJJPOS
c internal
      INTEGER NSIZE1,NSIZE2
      REAL SUM,XMAX1,XMAX2
      REAL BESTNOW
      
      INTEGER I,J,M,N,K,NDAMP,NDIAGONAL,ISMALL_DIM,IBIG_DIM,IIBEG,JJBEG
      INTEGER LEN_DIAG,IDIAG,II,JJ
      INTEGER ILOC
C=======================================================================
C                 DO SOME STUFF OUTSIDE THE LOOPS:
C=======================================================================
C                          initialize
C=======================================================================
C      WRITE(*,*) ' info: inside SETMATRIX_FAST, profilemode= ',
C     +     PROFILEMODE
C      WRITE(6,*)'debug SETMATRIX_FAST '
C      WRITE(6,*) ' info: N1BEG,N1END,N2BEG,N2END,N2 ',
C     +     N1BEG,N1END,N2BEG,N2END,N2
      BESTVAL=-99999.0       
      BESTNOW=-99999.0
      BESTIIPOS=-1           
      BESTJJPOS=-1
      NSIZE1=N1END-N1BEG+1   
      NSIZE2=N2END-N2BEG+1
      
C      WRITE(6,*)' info:NSIZE1,NSIZE2 ',NSIZE1,NSIZE2
      
      J=MIN(N1BEG-1,N2BEG-1) 
      K=MAX(N1END+1,N2END+1)
      DO I=J,K
c	do i=0,maxsq+1
         MAX_D(I)=0.0
         MAX_H(I)=0.0 
         MAX_V(I)=0.0 
         LDEL_H(I)=0 
         LDEL_V(I)=0
         LEFT_LH(I)=0.0 
         UP_LH(I)=0.0 
         DIAG_LH(I)=0.0
      ENDDO
C=======================================================================
C update the metric values (weights)
C this can be done outside the main parallel loop
C with this we save at lot of multiplications in the parallel loop
C the update can be done in concurrent/vectorized mode 
C=======================================================================
      NDAMP=1
      IF (PROFILEMODE .EQ. 6) THEN
         IF (LCONSERV_1) THEN
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1(I) * CONSWEIGHT_1(I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I) * CONSWEIGHT_1(I)
	    ENDDO
C     DAMP PENALTIES
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ELSE
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1 (I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ENDIF
         
         IF (LCONSERV_2) THEN
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ELSE
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ENDIF
C=============================
      ELSE IF (PROFILEMODE .NE. 2 .AND. PROFILEMODE .NE. 8) THEN
         IF (LCONSERV_1) THEN
            IF(PROFILEMODE .EQ. 7 .OR. PROFILEMODE .EQ. 9) THEN
C               WRITE(*,*) ' info: inputing conserv for profilemode 7' 
               DO K=1,NTRANS 
                  DO I=N1BEG,N1END
                     DO M=1, NSTRUCTRANS
                        DO N=1, NACCTRANS
                           SSSA_METRIC_1(I,K,M,N) = 
     +                     SIM_SSSA_METRIC_1(I,K,M,N) * CONSWEIGHT_1(I)
C                           WRITE(*,*)' infor:sssa_metric1 with conserv.'
C     +                         ,SSSA_METRIC_1(I,K,M,N) 
                        ENDDO
                     ENDDO
                  ENDDO
               ENDDO
            ELSE
               DO K=1,NTRANS 
                  DO I=N1BEG,N1END
                     METRIC_1(I,K) = SIMMETRIC_1(I,K) * CONSWEIGHT_1(I)
                  ENDDO
               ENDDO
            ENDIF
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1(I) * CONSWEIGHT_1(I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I) * CONSWEIGHT_1(I)
	    ENDDO
C     DAMP PENALTIES
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ELSE
            IF(PROFILEMODE .EQ. 7 .OR. PROFILEMODE .EQ. 9) THEN
C               WRITE(*,*) ' info: inputing not conserv for profmode 7' 
               DO K=1,NTRANS 
                  DO I=N1BEG,N1END
                     DO M=1, NSTRUCTRANS
                        DO N=1, NACCTRANS
                           SSSA_METRIC_1(I,K,M,N) = 
     +                          SIM_SSSA_METRIC_1(I,K,M,N)
C                           WRITE(*,*)' info:sssa_metric1 w/o conserv.'
C     +                          ,SSSA_METRIC_1(I,K,M,N),'cons ', 
C     +                          CONSWEIGHT_1(I)
                        ENDDO
                     ENDDO
                  ENDDO
               ENDDO
            ELSE
               DO K=1,NTRANS 
                  DO I=N1BEG,N1END
C                     WRITE(6,*) 'here SIMMETRIC_1(I,K),I,K ',
C     +                    SIMMETRIC_1(I,K),I,K
 
                     METRIC_1(I,K) = SIMMETRIC_1(I,K)
                  ENDDO
               ENDDO
            ENDIF
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1 (I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ENDIF
      ENDIF
      IF (PROFILEMODE .GE. 2 .AND. PROFILEMODE .NE. 7 ) THEN
         IF (LCONSERV_2) THEN
            IF(PROFILEMODE .EQ. 8 .OR. PROFILEMODE .EQ. 9) THEN
C               WRITE(*,*) ' info: inputing conserv for profilemode 8' 
               DO K=1,NTRANS 
                  DO I=N2BEG,N2END
                     DO M=1, NSTRUCTRANS
                        DO N=1, NACCTRANS
                           SSSA_METRIC_2(I,K,M,N) = 
     +                     SIM_SSSA_METRIC_2(I,K,M,N) * CONSWEIGHT_2(I)
C                           WRITE(*,*)' infor:sssa_metric2 with conserv.'
C     +                         ,SSSA_METRIC_2(I,K,M,N) 
                        ENDDO
                     ENDDO
                  ENDDO
               ENDDO
            ELSE
               DO K=1,NTRANS 
                  DO I=N2BEG,N2END 
                     METRIC_2(I,K)  = SIMMETRIC_2(I,K) * CONSWEIGHT_2(I)
                  ENDDO
               ENDDO
            ENDIF

	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ELSE
            IF(PROFILEMODE .EQ. 8 .OR. PROFILEMODE .EQ. 9) THEN
C     WRITE(*,*) ' info: inputing conserv for profilemode 8' 
               DO K=1,NTRANS 
                  DO I=N2BEG,N2END
                     DO M=1, NSTRUCTRANS
                        DO N=1, NACCTRANS
                           SSSA_METRIC_2(I,K,M,N) = 
     +                          SIM_SSSA_METRIC_2(I,K,M,N)
C     WRITE(*,*)' infor:sssa_metric2 without conserv.'
C     +                         ,SSSA_METRIC_2(I,K,M,N) 
                        ENDDO
                     ENDDO
                  ENDDO
               ENDDO
            ELSE
               DO K=1,NTRANS 
                  DO I=N2BEG,N2END
                     METRIC_2(I,K) = SIMMETRIC_2(I,K)
                  ENDDO
               ENDDO
            ENDIF
            
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ENDIF
      ENDIF
      IF (PROFILEMODE .EQ. 5) THEN
         DO I=N1BEG,N1END
            MAX_METRIC_1_VAL(I)=-10000.0
            DO K=1,NTRANS
               MAX_METRIC_1_VAL(I)=
     +              MAX(METRIC_1(I,K),MAX_METRIC_1_VAL(I))
            ENDDO
         ENDDO
         DO J=N2BEG,N2END
            MAX_METRIC_2_VAL(J)=-10000.0
            DO K=1,NTRANS
               MAX_METRIC_2_VAL(J)=
     +              MAX(METRIC_2(J,K),MAX_METRIC_2_VAL(J))
            ENDDO
C            WRITE(6,*)'J, MAX_METRIC_2_VAL ',J,MAX_METRIC_2_VAL(J)
         ENDDO
      ENDIF
C     
C Darek Przybylski (commented out normalization of profile vectors) 12/30/2002
C      IF ( PROFILEMODE .EQ. 3 ) THEN
C         
C         DO I=N1BEG,N1END 
C            SUM=0.0
C            DO K=1,NTRANS 
CC               WRITE(6,*)' here13', METRIC_1(I,K)
C               SUM= SUM + ( METRIC_1(I,K) * METRIC_1(I,K) )
C            ENDDO
C            WRITE(6,*)' here13 SUM', SUM
C            SUM= SQRT(SUM)
C            DO K=1,NTRANS 
C               METRIC_1(I,K)= METRIC_1(I,K) / SUM
CC               WRITE(6,*)' here13', METRIC_1(I,K)
C            ENDDO
C         ENDDO
C         DO I=N2BEG,N2END 
C            SUM=0.0
C            DO K=1,NTRANS 
C               SUM= SUM + ( METRIC_2(I,K) * METRIC_2(I,K) )
C            ENDDO
C            SUM= SQRT(SUM)
C            DO K=1,NTRANS 
C               METRIC_2(I,K)= METRIC_2(I,K) / SUM
C            ENDDO
C         ENDDO
C     ENDIF
c======================================================================
      NDIAGONAL=NSIZE1+NSIZE2-1
c	ndiagonal=iprofend-iprofbeg+1+n2-1
c	WRITE(*,'(A,I6)')' NUMBER OF ANTIDIAGONALS: ',NDIAGONAL
      ISMALL_DIM=MIN(NSIZE1,NSIZE2) 
      IBIG_DIM=MAX(NSIZE1,NSIZE2)
      IIBEG=N1BEG 
      JJBEG=N2BEG+1 
      LEN_DIAG=0

C      WRITE(6,*)'info: OPEN_GAP_1'
C      WRITE(6,110) (OPEN_GAP_1(I),I=1,N1END)
C      WRITE(6,*)'info: OPEN_GAP_2'
C      WRITE(6,110) (OPEN_GAP_2(I),I=1,N2END)
C      WRITE(6,*)'info: ELONG_GAP_1'
C      WRITE(6,110) (ELONG_GAP_1(I),I=1,N1END)  
C      WRITE(6,*)'info: ELONG_GAP_2'
C      WRITE(6,110) (ELONG_GAP_2(I),I=1,N2END) 
C      WRITE(6,*)'info: MAX_METRIC_1_VAL'
C      WRITE(6,110) (MAX_METRIC_1_VAL(I),I=1,N1END)
C      WRITE(6,*)'info: MAX_METRIC_2_VAL'
C      WRITE(6,110) (MAX_METRIC_2_VAL(I),I=1,N2END)
C 110  FORMAT(10(F8.3))
 
C=====================================================================
C profile 1 (no profiles or profile for first sequence)
C--------------------------------------------------------------------
      IF (PROFILEMODE .LE. 1) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
C====================================================================
C                 THIS LOOP CAN BE EXECUTED IN VECTOR-MODE 
C======================================================================
C               compiler directives for vector
C----------------------------------------------------------------------
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
C======================================================================
C values for diagonal, horizontal and vertical (open and elongation)
C=====================================================================
C       store best value and length for horizontal deletion
C=====================================================================
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_1(II-1))
               IF ((MAX_H(JJ-II) .GE.(LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)))
     +              .AND. (MAX_H(JJ-II) .GT.0.0 )) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF (((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GE. 
     +                 MAX_H(JJ-II)) 
     +                 .AND. ((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II)= (LEFT_LH(JJ-II) - OPEN_GAP_1(II-1))
               ELSE
                  MAX_H(JJ-II)= 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_1(II-1))
               IF ( (MAX_V(II).GE.(UP_LH(II) - OPEN_GAP_1(II-1))) .AND.
     +              ( MAX_V(II) .GT. 0.0) ) THEN 
                  LDEL_V(II)= LDEL_V(II) + 1
               ELSE IF ( ((UP_LH(II)-OPEN_GAP_1(II-1)) .GE. MAX_V(II)) 
     +                 .AND. ((UP_LH(II) - OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_1(II-1))
                  LDEL_V(II)=1
               ELSE
                  MAX_V(II)= 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+METRIC_1(II-1,LSQ_2(JJ-II-1))
C               WRITE(6,*)' I,LJ,METRIC_1(I,LJ) ',II-1,LSQ_2(JJ-II-1),
C     +              METRIC_1(II-1,LSQ_2(JJ-II-1))
               IF (      (MAX_D(II) .GE. MAX_V(II) )   .AND.
     +              (MAX_D(II) .GE. MAX_H(JJ-II)) .AND.
     +              (MAX_D(II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_D(II)
               ELSE IF ( (MAX_V(II) .GE. MAX_D(II) )   .AND.
     +                 (MAX_V(II) .GE. MAX_H(JJ-II)) .AND.
     +                 (MAX_V(II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_V(II)
	          LH2(II,JJ-II)= 10000 + LDEL_V(II)
               ELSE IF ( (MAX_H(JJ-II) .GE. MAX_D(II))    .AND.
     +                 (MAX_H(JJ-II) .GE. MAX_V(II)) .AND.
     +                 (MAX_H(JJ-II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_H(JJ-II)
	          LH2(II,JJ-II)= 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW= 0.0
	          LH2(II,JJ-II)= 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW=0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)= UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)= BESTNOW
               
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW 
                  BESTIIPOS=II 
                  BESTJJPOS=JJ-II
               ENDIF
C     END DIAGONAL
            ENDDO
            
C     IF (LSAMESEQ) THEN
C     X= ( FLOAT(IIBEG)/ 2.0) + (FLOAT(JJBEG)/2.0) 
C     I=NINT(X)
C     LH1(I,I) = 0.0    ; LH2(I,I)= 0
C     LEFT_LH(I)= 0.0
c	       up_lh(i)  = 0.0
c	       write(*,*)iibeg,jjbeg,i
c	   endif
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C         WRITE(6,*)' BESTVAL ',BESTVAL
C--------------------------------------------------------------------
C profile 2  (profile for sequence 2)
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 2) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_2(JJ-II-1))
               IF (MAX_H(JJ-II) .GT. 
     +              (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1))  .AND.
     +              MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1)) .GE.
     +                 MAX_H(JJ-II) .AND.
     +                 (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1)) .GT. 
     +                 0.0) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_2(JJ-II-1))
               IF ( MAX_V(II).GT.(UP_LH(II) - OPEN_GAP_2(JJ-II-1)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ((UP_LH(II) - OPEN_GAP_2(JJ-II-1)).GE. MAX_V(II) 
     +                 .AND. (UP_LH(II) - OPEN_GAP_2(JJ-II-1)) .GT. 
     +                 0.0) THEN
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_2(JJ-II-1))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
c======================================================================
c which value is the best (diagonal,horizontal or vertical)
c======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+METRIC_2(JJ-II-1,LSQ_1(II-1))
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
	          BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
	          BESTNOW = MAX_V(II)
	          LH2(II,JJ-II) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
	          BESTNOW = MAX_H(JJ-II)
	          LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW = 0.0
	          LH2(II,JJ-II) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
c--------------------------------------------------------------------
C full profile alignment 
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 3) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG

CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               
               SUM=0.0 
               XMAX1=0.0 
               XMAX2=0.0
               DO K=1,NTRANS
C                  WRITE(6,*)'here METRIC_1(II-1,K),II,K ',
C     +                 METRIC_1(II-1,K),II,K
                  SUM = SUM + ( METRIC_1(II-1,K) * METRIC_2(JJ-II-1,K) )
C     IF ( METRIC_1(II-1,K) .GT. XMAX1 ) THEN
C     XMAX1 =  METRIC_1(II-1,K)
C     ENDIF
C     IF ( METRIC_2(JJ-II-1,K) .GT. XMAX2 ) THEN
C     XMAX2 =  METRIC_1(JJ-II-1,K)
C     ENDIF
               ENDDO
               SUM = SUM - 50
C     OPEN_GAP_1(II-1)     = GAPOPEN_1(II-1)     * XMAX1
C     ELONG_GAP_1(II-1)    = GAPELONG_1(II-1)    * XMAX1
C     OPEN_GAP_2(JJ-II-1)  = GAPOPEN_2(JJ-II-1)  * XMAX2
C     ELONG_GAP_2(JJ-II-1) = GAPELONG_2(JJ-II-1) * XMAX2
               
c	write(*,*)ii,jj-ii,sum

c	      MAX_D(II) = DIAG_LH(JJ-II) + (SUM/NTRANS)

               MAX_H(JJ-II)= MAX_H(JJ-II)-
     +              (( ELONG_GAP_1(II-1)+ ELONG_GAP_2(JJ-II-1))* 0.5)
               IF (MAX_H(JJ-II) .GT.  (LEFT_LH(JJ-II)-
     +              (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +              .AND. MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GE. MAX_H(JJ-II) .AND. (LEFT_LH(JJ-II)- 
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT.0.0) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II)-
     +                    ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
C=====================================================================
C       store best value and length for vertical deletion
C=====================================================================
               MAX_V(II)= MAX_V(II)-
     +              (( ELONG_GAP_1(II-1)+ ELONG_GAP_2(JJ-II-1))* 0.5)
               IF ( MAX_V(II) .GT. (UP_LH(II)-
     +              (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ( (UP_LH(II)- (( OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GE. MAX_V(II)
     +                 .AND.  (UP_LH(II)- ((OPEN_GAP_1(II-1)+ 
     +                 OPEN_GAP_2(JJ-II-1))*0.5)).GT.0.0) THEN
                  MAX_V(II)= (UP_LH(II)-
     +                 (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II) = DIAG_LH(JJ-II) + SUM
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
	          BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
	          BESTNOW = MAX_V(II)
	          LH2(II,JJ-II) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
	          BESTNOW = MAX_H(JJ-II)
	          LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW = 0.0
	          LH2(II,JJ-II ) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C--------------------------------------------------------------------
C take sequences as representatives of family
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 4) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II)= MAX_H(JJ-II)- 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1)) *0.5)
               IF (MAX_H(JJ-II) .GT. (LEFT_LH(JJ-II) -
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +              .AND. MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II) - ((OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GE. MAX_H(JJ-II) 
     +                 .AND. (LEFT_LH(JJ-II) - ((OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GT. 0.0 ) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
C=====================================================================
C     STORE BEST VALUE AND LENGTH FOR VERTICAL DELETION
C=====================================================================
               MAX_V(II)= (MAX_V(II)- 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1)) *0.5))
               IF ( MAX_V(II) .GT.  (UP_LH(II)-
     +              ((OPEN_GAP_1(II-1) +OPEN_GAP_2(JJ-II-1)) *0.5)) 
     +              .AND. MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ( (UP_LH(II)- 
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GE. MAX_V(II) 
     +                 .AND.  (UP_LH(II)- ((OPEN_GAP_1(II-1) +
     +                 OPEN_GAP_2(JJ-II-1)) *0.5)) .GT. 0.0 ) THEN
                  MAX_V(II)=(UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1) +OPEN_GAP_2(JJ-II-1)) *0.5))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II) +
     +              (( METRIC_1 (II-1,LSQ_2(JJ-II-1)) +
     +              METRIC_2 (JJ-II-1,LSQ_1(II-1)) ) * 0.5)
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
                  BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
                  BESTNOW = MAX_V(II)
                  LH2(II,JJ-II ) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
                  BESTNOW = MAX_H(JJ-II)
                  LH2(II,JJ-II ) = 20000 + LDEL_H(JJ-II)
               ELSE
                  BESTNOW = 0.0
                  LH2(II,JJ-II ) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C--------------------------------------------------------------------
C take maximal value as consensus
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 5) THEN
         WRITE(6,*)' NDIAGONAL,ISMALL_DIM,IBIG_DIM,LEN_DIAG ',
     +        NDIAGONAL,ISMALL_DIM,IBIG_DIM,LEN_DIAG
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               
               MAX_H(JJ-II)=MAX_H(JJ-II) - 
     +              ((ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1))*0.5)
               IF (MAX_H(JJ-II) .GT. (LEFT_LH(JJ-II) -
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))  
     +              .AND. MAX_H(JJ-II) .GT. 0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
C                  WRITE(6,*)'H1 IDIAG,II',IDIAG,II
               ELSE IF ((LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GE.MAX_H(JJ-II) .AND. (LEFT_LH(JJ-II) -  
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT. 0.0) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
C                 WRITE(6,*)'H2 IDIAG,II',IDIAG,II
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
C                  WRITE(6,*)'H3 IDIAG,II',IDIAG,II
               ENDIF
C=====================================================================
C       store best value and length for vertical deletion
C=====================================================================
               MAX_V(II)= MAX_V(II) - 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1))*0.5)
               IF ( MAX_V(II) .GT. (UP_LH(II)-
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
C                  WRITE(6,*)'V1 IDIAG,II',IDIAG,II
               ELSE IF ((UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)) 
     +                 .GE.MAX_V(II) .AND. (UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT. 0.0) THEN
                  MAX_V(II)= (UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
                  LDEL_V(II)= 1
C                  WRITE(6,*)'V2 IDIAG,II',IDIAG,II
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
C                  WRITE(6,*)'V3 IDIAG,II',IDIAG,II
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II) = DIAG_LH(JJ-II) + 
     +              ((MAX_METRIC_1_VAL(II-1) + 
     +              MAX_METRIC_2_VAL(JJ-II-1)) * 0.5)
C               WRITE(6,*)'MAX_METRIC_1_VAL, MAX_METRIC_2_VAL,II ',
C     +              MAX_METRIC_1_VAL(II-1),MAX_METRIC_2_VAL(JJ-II-1),II
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
                  BESTNOW = MAX_D(II)
C                  WRITE(6,*)'D IDIAG,II,JJ,BESTNOW ',IDIAG,II,JJ,BESTNOW
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
                  BESTNOW = MAX_V(II)
                  LH2(II,JJ-II ) = 10000 + LDEL_V(II)
C                  WRITE(6,*)'V IDIAG,II,JJ,BESTNOW ',IDIAG,II,JJ,BESTNOW
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
                  BESTNOW = MAX_H(JJ-II)
                  LH2(II,JJ-II ) = 20000 + LDEL_H(JJ-II)
C                  WRITE(6,*)'H IDIAG,II,JJ,BESTNOW ',IDIAG,II,JJ,BESTNOW
               ELSE
                  BESTNOW = 0.0
                  LH2(II,JJ-II ) = 0
C                  WRITE(6,*)'E IDIAG,II,JJ,BESTNOW ',IDIAG,II,JJ,BESTNOW
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
C               WRITE(6,*)'II,LH2(II,JJ-II) ',II,LH2(II,JJ-II)
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C====================================================================
      ELSE IF (PROFILEMODE .EQ. 6) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
C=====================================================================
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_1(II-1))
               IF ((MAX_H(JJ-II).GE.(LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)))
     +              .AND. (MAX_H(JJ-II) .GT.0.0 )) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF (((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GE. 
     +                 MAX_H(JJ-II)) 
     +                 .AND. ((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) 
     +                 .GT. 0.0)) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II)= (LEFT_LH(JJ-II) - OPEN_GAP_1(II-1))
               ELSE
                  MAX_H(JJ-II)= 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_1(II-1))
               IF ( (MAX_V(II).GE.(UP_LH(II)-OPEN_GAP_1(II-1))) .AND.
     +              ( MAX_V(II) .GT. 0.0) ) THEN 
                  LDEL_V(II)= LDEL_V(II) + 1
               ELSE IF ( ((UP_LH(II)-OPEN_GAP_1(II-1)).GE.MAX_V(II)) 
     +                 .AND. ((UP_LH(II) - OPEN_GAP_1(II-1)) 
     +                 .GT. 0.0)) THEN 
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_1(II-1))
                  LDEL_V(II)=1
               ELSE
                  MAX_V(II)= 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================

               MAX_D(II)= DIAG_LH(JJ-II) + 
     +              SIMORG(LSQ_1(II-1),LSQ_2(JJ-II-1),LSTRCLASS_1(II-1),
     +              LACC_1(II-1),LSTRCLASS_2(JJ-II-1),
     +              LACC_2(JJ-II-1) )
               IF (      (MAX_D(II) .GE. MAX_V(II) )   .AND.
     +              (MAX_D(II) .GE. MAX_H(JJ-II)) .AND.
     +              (MAX_D(II) .GT. 0.0 )) THEN
                  BESTNOW= MAX_D(II)
               ELSE IF ( (MAX_V(II) .GE. MAX_D(II) )   .AND.
     +                 (MAX_V(II) .GE. MAX_H(JJ-II)) .AND.
     +                 (MAX_V(II) .GT. 0.0 )) THEN
                  BESTNOW= MAX_V(II)
                  LH2(II,JJ-II)= 10000 + LDEL_V(II)
               ELSE IF ( (MAX_H(JJ-II) .GE. MAX_D(II))    .AND.
     +                 (MAX_H(JJ-II) .GE. MAX_V(II)) .AND.
     +                 (MAX_H(JJ-II) .GT. 0.0 )) THEN
                  BESTNOW= MAX_H(JJ-II)
                  LH2(II,JJ-II)= 20000 + LDEL_H(JJ-II)
               ELSE
                  BESTNOW= 0.0
                  LH2(II,JJ-II)= 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)= UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)= BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C=====================================================================
C profile 7 (profile with secondary structure and accessibility for sequence 1)
C--------------------------------------------------------------------
      ELSEIF (PROFILEMODE .EQ. 7) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
C====================================================================
C                 THIS LOOP CAN BE EXECUTED IN VECTOR-MODE 
C======================================================================
C               compiler directives for vector
C----------------------------------------------------------------------
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
C======================================================================
C values for diagonal, horizontal and vertical (open and elongation)
C=====================================================================
C       store best value and length for horizontal deletion
C=====================================================================
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_1(II-1))
               IF ((MAX_H(JJ-II) .GE.(LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)))
     +              .AND. (MAX_H(JJ-II) .GT.0.0 )) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF (((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GE. 
     +                 MAX_H(JJ-II)) 
     +                 .AND. ((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II)= (LEFT_LH(JJ-II) - OPEN_GAP_1(II-1))
               ELSE
                  MAX_H(JJ-II)= 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_1(II-1))
               IF ( (MAX_V(II).GE.(UP_LH(II) - OPEN_GAP_1(II-1))) .AND.
     +              ( MAX_V(II) .GT. 0.0) ) THEN 
                  LDEL_V(II)= LDEL_V(II) + 1
               ELSE IF ( ((UP_LH(II)-OPEN_GAP_1(II-1)) .GE. MAX_V(II)) 
     +                 .AND. ((UP_LH(II) - OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_1(II-1))
                  LDEL_V(II)=1
               ELSE
                  MAX_V(II)= 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+
     +          SSSA_METRIC_1( II-1,LSQ_2(JJ-II-1),LSTRCLASS_2(JJ-II-1),
     +              LACC_2(JJ-II-1) )
C               WRITE(6,*)' I,LJ,SS_METRIC_1(I,LJ) ',II-1,LSQ_2(JJ-II-1),
C     +          SSSA_METRIC_1( II-1,LSQ_2(JJ-II-1),LSTRCLASS_2(JJ-II-1),
C     +            LACC_2(JJ-II-1) )
C               WRITE(6,*) 'SSSA:I,J,LSQ_2(J),LSTRCLASS_2(J),LACC_2(J)',
C     +              ' SSSA_METRIC_1(I,J,SS,SA)'
C               WRITE(6,*) II-1,JJ-II-1,LSQ_2(JJ-II-1),
C     +          LSTRCLASS_2(JJ-II-1),LACC_2(JJ-II-1),
C     +          SSSA_METRIC_1( II-1,LSQ_2(JJ-II-1),LSTRCLASS_2(JJ-II-1),
C     +              LACC_2(JJ-II-1) )
               IF (      (MAX_D(II) .GE. MAX_V(II) )   .AND.
     +              (MAX_D(II) .GE. MAX_H(JJ-II)) .AND.
     +              (MAX_D(II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_D(II)
               ELSE IF ( (MAX_V(II) .GE. MAX_D(II) )   .AND.
     +                 (MAX_V(II) .GE. MAX_H(JJ-II)) .AND.
     +                 (MAX_V(II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_V(II)
	          LH2(II,JJ-II)= 10000 + LDEL_V(II)
               ELSE IF ( (MAX_H(JJ-II) .GE. MAX_D(II))    .AND.
     +                 (MAX_H(JJ-II) .GE. MAX_V(II)) .AND.
     +                 (MAX_H(JJ-II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_H(JJ-II)
	          LH2(II,JJ-II)= 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW= 0.0
	          LH2(II,JJ-II)= 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW=0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)= UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)= BESTNOW
               
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW 
                  BESTIIPOS=II 
                  BESTJJPOS=JJ-II
               ENDIF
C     END DIAGONAL
            ENDDO
            
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C=====================================================================
C profile 8 (profile with secondary structure and accessibility for sequence 2)
C--------------------------------------------------------------------


      ELSE IF (PROFILEMODE .EQ. 8) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_2(JJ-II-1))
               IF (MAX_H(JJ-II) .GT. 
     +              (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1))  .AND.
     +              MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1)) .GE.
     +                 MAX_H(JJ-II) .AND.
     +                 (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1)) .GT. 
     +                 0.0) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_2(JJ-II-1))
               IF ( MAX_V(II).GT.(UP_LH(II) - OPEN_GAP_2(JJ-II-1)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ((UP_LH(II) - OPEN_GAP_2(JJ-II-1)).GE. MAX_V(II) 
     +                 .AND. (UP_LH(II) - OPEN_GAP_2(JJ-II-1)) .GT. 
     +                 0.0) THEN
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_2(JJ-II-1))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
c======================================================================
c which value is the best (diagonal,horizontal or vertical)
c======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+
     +              SSSA_METRIC_2(JJ-II-1,LSQ_1(II-1),LSTRCLASS_1(II-1),
     +              LACC_1(II-1) )
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
	          BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
	          BESTNOW = MAX_V(II)
	          LH2(II,JJ-II) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
	          BESTNOW = MAX_H(JJ-II)
	          LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW = 0.0
	          LH2(II,JJ-II) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO 
C=====================================================================
C profile 9 (profile with secondary structure and accessibility for sequence 1 and 2)
C--------------------------------------------------------------------
      ELSEIF (PROFILEMODE .EQ. 9) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II)= MAX_H(JJ-II)- 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1)) *0.5)
               IF (MAX_H(JJ-II) .GT. (LEFT_LH(JJ-II) -
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +              .AND. MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II) - ((OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GE. MAX_H(JJ-II) 
     +                 .AND. (LEFT_LH(JJ-II) - ((OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GT. 0.0 ) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
C=====================================================================
C     STORE BEST VALUE AND LENGTH FOR VERTICAL DELETION
C=====================================================================
               MAX_V(II)= (MAX_V(II)- 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1)) *0.5))
               IF ( MAX_V(II) .GT.  (UP_LH(II)-
     +              ((OPEN_GAP_1(II-1) +OPEN_GAP_2(JJ-II-1)) *0.5)) 
     +              .AND. MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ( (UP_LH(II)- 
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GE. MAX_V(II) 
     +                 .AND.  (UP_LH(II)- ((OPEN_GAP_1(II-1) +
     +                 OPEN_GAP_2(JJ-II-1)) *0.5)) .GT. 0.0 ) THEN
                  MAX_V(II)=(UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1) +OPEN_GAP_2(JJ-II-1)) *0.5))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II) +
     +              ( ( SSSA_METRIC_1( II-1,LSQ_2(JJ-II-1),
     +              LSTRCLASS_2(JJ-II-1),LACC_2(JJ-II-1) ) +
     +              SSSA_METRIC_2( JJ-II-1,LSQ_1(II-1),
     +              LSTRCLASS_1(II-1),LACC_1(II-1) ) ) * 0.5)
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
                  BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
                  BESTNOW = MAX_V(II)
                  LH2(II,JJ-II ) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
                  BESTNOW = MAX_H(JJ-II)
                  LH2(II,JJ-II ) = 20000 + LDEL_H(JJ-II)
               ELSE
                  BESTNOW = 0.0
                  LH2(II,JJ-II ) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C====================================================================
      ELSEIF (PROFILEMODE .EQ. 9999) THEN
         DO IDIAG=1,NDIAGONAL
C           WRITE(6,*)' !!!!!!!!! i am HERE1'
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
C====================================================================
C                 THIS LOOP CAN BE EXECUTED IN VECTOR-MODE 
C======================================================================
C               compiler directives for vector
C----------------------------------------------------------------------
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
C======================================================================
C values for diagonal, horizontal and vertical (open and elongation)
C=====================================================================
C       store best value and length for horizontal deletion
C=====================================================================
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_1(II-1))
               IF ((MAX_H(JJ-II) .GE.(LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)))
     +              .AND. (MAX_H(JJ-II) .GT.0.0 )) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF (((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GE. 
     +                 MAX_H(JJ-II)) 
     +                 .AND. ((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II)= (LEFT_LH(JJ-II) - OPEN_GAP_1(II-1))
               ELSE
                  MAX_H(JJ-II)= 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_1(II-1))
               IF ( (MAX_V(II).GE.(UP_LH(II) - OPEN_GAP_1(II-1))) .AND.
     +              ( MAX_V(II) .GT. 0.0) ) THEN 
                  LDEL_V(II)= LDEL_V(II) + 1
               ELSE IF ( ((UP_LH(II)-OPEN_GAP_1(II-1)) .GE. MAX_V(II)) 
     +                 .AND. ((UP_LH(II) - OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_1(II-1))
                  LDEL_V(II)=1
               ELSE
                  MAX_V(II)= 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+
     +          SSSA_METRIC_2(JJ-II-1,LSQ_1(II-1),LSTRCLASS_1(II-1),
     +              LACC_1(II-1) )
C               WRITE(6,*)' I,L,SS_METRIC_2(I,LJ),LSTRCLASS_1,LACC_1 ',
C     +              II-1,LSQ_1(II-1),
C     +     SSSA_METRIC_2(JJ-II-1,LSQ_1(II-1),LSTRCLASS_1(II-1),
C     +                                                 LACC_1(II-1) )

               IF (      (MAX_D(II) .GE. MAX_V(II) )   .AND.
     +              (MAX_D(II) .GE. MAX_H(JJ-II)) .AND.
     +              (MAX_D(II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_D(II)
               ELSE IF ( (MAX_V(II) .GE. MAX_D(II) )   .AND.
     +                 (MAX_V(II) .GE. MAX_H(JJ-II)) .AND.
     +                 (MAX_V(II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_V(II)
	          LH2(II,JJ-II)= 10000 + LDEL_V(II)
               ELSE IF ( (MAX_H(JJ-II) .GE. MAX_D(II))    .AND.
     +                 (MAX_H(JJ-II) .GE. MAX_V(II)) .AND.
     +                 (MAX_H(JJ-II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_H(JJ-II)
	          LH2(II,JJ-II)= 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW= 0.0
	          LH2(II,JJ-II)= 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW=0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)= UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)= BESTNOW
               
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW 
                  BESTIIPOS=II 
                  BESTJJPOS=JJ-II
               ENDIF
C     END DIAGONAL
            ENDDO
            
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C--------------------------------------------------------------------
C====================================================================
C PROFILE MODE SELECTION END
      ENDIF
      WRITE(6,*)' BESTVAL,BESTIIPOS,BESTJJPOS ',BESTVAL,BESTIIPOS,
     +        BESTJJPOS
C====================================================================
C debug: output the LH (values and trace-back)matrix 
c      call open_file(99,'matrix.dat','new,recl=2000',lerror)
c      nii=n1+1 ; njj=n2+1
c      write(99,*)'TRACE-BACK MATRIX' 
c      do i=1,nii
c	  write(99,'(i6)')i ; write(99,'(2x,20(i6))')(lh2(i,j),j=1,njj)
c      enddo
c      close(99)
C=======================================================================
C      DO I=1, N1-1
C         DO J=1 , N2-1
C            WRITE(6,*)'I,J,DIAG_LH(I,J) ',I,J,DIAG_LH(I,J)
C         ENDDO
C      ENDDO


      RETURN
      END              
C     END SETMATRIX_FAST
C......................................................................



C......................................................................
C     SUB SETMATRIX_FAST_OLD
      SUBROUTINE SETMATRIX_FAST_OLD(N1BEG,N1END,N2BEG,N2END,N2,LH2,
     +     BESTVAL,BESTIIPOS,BESTJJPOS)
C   --------------------------------------------------------
C   subroutine SETMATRIX_fast finds LH matrix for maximum homologous 
C   subsequence between any two sequences 
C   generate the homology and traceback matrix
C-----------------------------------------------------------------------
C  LH(.,.,1) is homology score     
C  LH(.,.,2) is traceback value    
C            encoding LDIREC and LDEL: DIREC + LDEL
C            LH(I,J,1) corresponds to seq postions II=I-1, JJ=J-1
C            LH(1,.,1) and LH(.,1,1) are terminal margins
C  LDIREC 10000,20000,30000,40000 for termination,diagonal,vertical,horizontal
C  LDEL   length of deletion
C  temporary values:
C  MAX_H(),MAX_V() best value for horizontal and verical deletions
C  LDEL_H,LDEL_V length of horizontal and vertical deletion
C======================================================================
C   JULY 1991 (RS)
C   MAXDEL restriction removed
C   see: O. Gotoh, An Improved Algorithm for Matching Biological 
C        Sequences, JMB (1982) 162, 705-708
C-----------------------------------------------------------------------
C   JUNE 1991 (RS)
C   matrix setting in a antidiagonal way to run it in parallel
C   see: Jones R. et.al., Protein Sequence Comparison on the Connection 
C        Machine CM-2, in: Computers and DNA, SFI Studies in the Sciences
C                        of Complexity, Vol VII, Addison-Wesley, 1990
C======================================================================
C
C               ANTIDIAGONAL SETTING OF THE MATRIX
C               ==================================
C N1,N2: length of sequence 1 and sequence 2
C ADVANTAGE: loop can run in parallel or vectorized
C
C
C  ICOUNT            2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
C     ----------------------------------------------------->    
C    |             sequence 1 ====>                 N1            
C    |              2345678901234567890123456789 <==IIBEG         
C    |            ------------------------------         
C  1 | sequence2  | ////  /                   /|        
C  2 |    |     2 |////  /                   / |       
C  3 |    |     3 |///  /                   / /| <== JJBEG
C  4 |    |     4 |//  /                   / //|    
C  5 |    v     5 |/  /                   / ///|    
C  6 |          6 |  /                   / ////|    
C  7 |          7 | /                   / /////|  
C  8 |       N2 8 |/                   / //////| 
C  9 |            -----------------------------|
C 10 |                                   
C 11 |                                  
C 12 |                                  
C 13 |
C    V           
C
C=====================================================================
C at each position take the best value of:
C
C LH(i,j,1)= MAX( LH(i-1,j-1,1) + SIM(i,j) , MAX_H(j) ,MAX_V(i) ,0)
C
C LH(i-1,j-1,1)  : best value of diagonal (no INDEL) 
C SIM(i,j)       : similarity value for position i,j
C MAX_H(j)       : best value of horizontal INDELs
C MAX_V(i)       : best value of vertical INDELs
C where:
C MAX_H(i)=MAX( LH(I-1,J,1) - gap-open , MAX_H(i-1) - gap-elongation , 0)
C MAX_V(j)=MAX( LH(I,J-1,1) - gap-open , MAX_V(j-1) - gap-elongation , 0)
C NOTE: one has to store the length of the deletion for MAX_H() and MAX_V()
C       in LDEL_H(j) and LDEL_V()
C
C
C NOTE: 
C 1) if no INDEL(s) in secondary structure allowed:
C    GAPOPEN contains PUNISH
C 2) internal deletions are (postion dependent ) weighted as:
C    GAPOPEN + GAPELONG *LENGTH 
C 3) conservation weights:
C    gap penalties are dependent on sequence-position(s), so weight 
C    gap-penalties with conservation-weights otherwise the gap penalties
C    in regions with low conservation are too big
C 4) antidiagonal matrix setting:
C    position in sequence 2 is JJBEG+IIBEG-II: step back in sequence 1 and 
C    down in sequence 2
C    
C 5) NOT LONGER VALID   
C    if the MAXDEL option is set, one has to check if the number of
C    INDEL's exceeds the MAXDEL value.
C    In addition: when the value for opening a gap is higher than 
C    for the elongation, we have to check if the previous length of
C    the gap is not greater than 0.
C    That means that for some special cases it's cheaper to punish
C    the alignment by some open-penalties in a row than to elongate
C    or continue the alignment in the diagonal.
C    open a gap if:
C           1.) OPEN .gt. ELONG or 
C           2.) LDELx()+1 .ge. MAXDEL
C           3.) but only if LDELx() .eq. 0
C======================================================================
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
C import
C ACTUAL SEQ LENGTH
      INTEGER N1BEG,N1END,N2BEG,N2END,N2
c export
c	real lh1(0:n1+1,0:n2+1)
      INTEGER*2 LH2(0:N1+1,0:N2+1)
c	real lh(0:n1+1,0:n2+1)
      REAL BESTVAL
      INTEGER BESTIIPOS,BESTJJPOS
c internal
      INTEGER NSIZE1,NSIZE2
      REAL SUM,XMAX1,XMAX2
      REAL BESTNOW
      
      INTEGER I,J,K,NDAMP,NDIAGONAL,ISMALL_DIM,IBIG_DIM,IIBEG,JJBEG
      INTEGER LEN_DIAG,IDIAG,II,JJ
C=======================================================================
C                 DO SOME STUFF OUTSIDE THE LOOPS:
C=======================================================================
C                          initialize
C=======================================================================
      BESTVAL=-99999.0       
      BESTNOW=-99999.0
      BESTIIPOS=-1           
      BESTJJPOS=-1
      NSIZE1=N1END-N1BEG+1   
      NSIZE2=N2END-N2BEG+1
      
      J=MIN(N1BEG-1,N2BEG-1) 
      K=MAX(N1END+1,N2END+1)
      DO I=J,K
c	do i=0,MAXSQ+1
         MAX_H(I)=0.0 
         MAX_V(I)=0.0 
         LDEL_H(I)=0 
         LDEL_V(I)=0
         LEFT_LH(I)=0.0 
         UP_LH(I)=0.0 
         DIAG_LH(I)=0.0
      ENDDO
C=======================================================================
C update the metric values (weights)
C this can be done outside the main parallel loop
C with this we save at lot of multiplications in the parallel loop
C the update can be done in concurrent/vectorized mode 
C=======================================================================
      NDAMP=1
      IF (PROFILEMODE .EQ. 6) THEN
         IF (LCONSERV_1) THEN
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1(I) * CONSWEIGHT_1(I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I) * CONSWEIGHT_1(I)
	    ENDDO
C     DAMP PENALTIES
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ELSE
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1 (I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ENDIF
         
         IF (LCONSERV_2) THEN
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ELSE
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ENDIF
C=============================
      ELSE IF (PROFILEMODE .NE. 2) THEN
         IF (LCONSERV_1) THEN
	    DO K=1,NTRANS 
               DO I=N1BEG,N1END
                  METRIC_1(I,K) = SIMMETRIC_1(I,K) * CONSWEIGHT_1(I)
               ENDDO
            ENDDO
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1(I) * CONSWEIGHT_1(I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I) * CONSWEIGHT_1(I)
	    ENDDO
C     DAMP PENALTIES
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ELSE
	    DO K=1,NTRANS 
               DO I=N1BEG,N1END
                  METRIC_1(I,K) = SIMMETRIC_1(I,K)
               ENDDO
            ENDDO
	    DO I=N1BEG,N1END
               OPEN_GAP_1(I) = GAPOPEN_1 (I)
	    ENDDO
	    DO I=N1BEG,N1END
               ELONG_GAP_1(I)= GAPELONG_1(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,OPEN_GAP_1,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N1BEG,N1END,ELONG_GAP_1,NDAMP,PUNISH)
         ENDIF
      ENDIF
      IF (PROFILEMODE .GE. 2) THEN
         IF (LCONSERV_2) THEN
	    DO K=1,NTRANS 
               DO I=N2BEG,N2END 
                  METRIC_2(I,K)  = SIMMETRIC_2(I,K) * CONSWEIGHT_2(I)
               ENDDO
            ENDDO
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)   * CONSWEIGHT_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ELSE
	    DO K=1,NTRANS 
               DO I=N2BEG,N2END
                  METRIC_2(I,K) = SIMMETRIC_2(I,K)
               ENDDO
            ENDDO
	    DO I=N2BEG,N2END
               OPEN_GAP_2(I) = GAPOPEN_2(I)
	    ENDDO
	    DO I=N2BEG,N2END
               ELONG_GAP_2(I)= GAPELONG_2(I)
	    ENDDO
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,OPEN_GAP_2,NDAMP,PUNISH)
            CALL DAMP_GAPWEIGHT(N2BEG,N2END,ELONG_GAP_2,NDAMP,PUNISH)
         ENDIF
      ENDIF
      IF (PROFILEMODE .EQ. 5) THEN
         DO I=N1BEG,N1END
            MAX_METRIC_1_VAL(I)=-10000.0
            DO K=1,NTRANS
               MAX_METRIC_1_VAL(I)=
     +              MAX(METRIC_1(I,K),MAX_METRIC_1_VAL(I))
            ENDDO
         ENDDO
         DO J=N2BEG,N2END
            MAX_METRIC_2_VAL(J)=-10000.0
            DO K=1,NTRANS
               MAX_METRIC_2_VAL(J)=
     +              MAX(METRIC_2(J,K),MAX_METRIC_2_VAL(J))
            ENDDO
         ENDDO
      ENDIF
C     
      IF ( PROFILEMODE .EQ. 3 ) THEN
         
         DO I=N1BEG,N1END 
            SUM=0.0
            DO K=1,NTRANS 
               SUM= SUM + ( METRIC_1(I,K) * METRIC_1(I,K) )
            ENDDO
            SUM= SQRT(SUM)
            DO K=1,NTRANS 
               METRIC_1(I,K)= METRIC_1(I,K) / SUM
            ENDDO
         ENDDO
         DO I=N2BEG,N2END 
            SUM=0.0
            DO K=1,NTRANS 
               SUM= SUM + ( METRIC_2(I,K) * METRIC_2(I,K) )
            ENDDO
            SUM= SQRT(SUM)
            DO K=1,NTRANS 
               METRIC_2(I,K)= METRIC_2(I,K) / SUM
            ENDDO
         ENDDO
      ENDIF
c======================================================================
      NDIAGONAL=NSIZE1+NSIZE2-1
c	ndiagonal=iprofend-iprofbeg+1+n2-1
c	WRITE(6,'(A,I6)')' NUMBER OF ANTIDIAGONALS: ',NDIAGONAL
      ISMALL_DIM=MIN(NSIZE1,NSIZE2) 
      IBIG_DIM=MAX(NSIZE1,NSIZE2)
      IIBEG=N1BEG 
      JJBEG=N2BEG+1 
      LEN_DIAG=0
C=====================================================================
C profile 1 (no profiles or profile for first sequence)
C--------------------------------------------------------------------
      IF (PROFILEMODE .LE. 1) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
C====================================================================
C                 THIS LOOP CAN BE EXECUTED IN VECTOR-MODE 
C======================================================================
C               compiler directives for vector
C----------------------------------------------------------------------
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
C======================================================================
C values for diagonal, horizontal and vertical (open and elongation)
C=====================================================================
C       store best value and length for horizontal deletion
C=====================================================================
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_1(II-1))
               IF ((MAX_H(JJ-II) .GE.(LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)))
     +              .AND. (MAX_H(JJ-II) .GT.0.0 )) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF (((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GE. 
     +                 MAX_H(JJ-II)) 
     +                 .AND. ((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II)= (LEFT_LH(JJ-II) - OPEN_GAP_1(II-1))
               ELSE
                  MAX_H(JJ-II)= 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_1(II-1))
               IF ( (MAX_V(II).GE.(UP_LH(II) - OPEN_GAP_1(II-1))) .AND.
     +              ( MAX_V(II) .GT. 0.0) ) THEN 
                  LDEL_V(II)= LDEL_V(II) + 1
               ELSE IF ( ((UP_LH(II)-OPEN_GAP_1(II-1)) .GE. MAX_V(II)) 
     +                 .AND. ((UP_LH(II) - OPEN_GAP_1(II-1)) .GT. 
     +                 0.0)) THEN 
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_1(II-1))
                  LDEL_V(II)=1
               ELSE
                  MAX_V(II)= 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+METRIC_1(II-1,LSQ_2(JJ-II-1))
               IF (      (MAX_D(II) .GE. MAX_V(II) )   .AND.
     +              (MAX_D(II) .GE. MAX_H(JJ-II)) .AND.
     +              (MAX_D(II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_D(II)
               ELSE IF ( (MAX_V(II) .GE. MAX_D(II) )   .AND.
     +                 (MAX_V(II) .GE. MAX_H(JJ-II)) .AND.
     +                 (MAX_V(II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_V(II)
	          LH2(II,JJ-II)= 10000 + LDEL_V(II)
               ELSE IF ( (MAX_H(JJ-II) .GE. MAX_D(II))    .AND.
     +                 (MAX_H(JJ-II) .GE. MAX_V(II)) .AND.
     +                 (MAX_H(JJ-II) .GT. 0.0 )) THEN
	          BESTNOW= MAX_H(JJ-II)
	          LH2(II,JJ-II)= 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW= 0.0
	          LH2(II,JJ-II)= 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW=0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)= UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)= BESTNOW
               
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW 
                  BESTIIPOS=II 
                  BESTJJPOS=JJ-II
               ENDIF
C     END DIAGONAL
            ENDDO
            
C     IF (LSAMESEQ) THEN
C     X= ( FLOAT(IIBEG)/ 2.0) + (FLOAT(JJBEG)/2.0) 
C     I=NINT(X)
C     LH1(I,I) = 0.0    ; LH2(I,I)= 0
C     LEFT_LH(I)= 0.0
c	       up_lh(i)  = 0.0
c	       WRITE(6,*)iibeg,jjbeg,i
c	   endif
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C--------------------------------------------------------------------
C profile 2  (profile for sequence 2)
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 2) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_2(JJ-II-1))
               IF (MAX_H(JJ-II) .GT. 
     +              (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1))  .AND.
     +              MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1)) .GE.
     +                 MAX_H(JJ-II) .AND.
     +                 (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1)) .GT. 
     +                 0.0) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II)-OPEN_GAP_2(JJ-II-1))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
c       store best value and length for vertical deletion
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_2(JJ-II-1))
               IF ( MAX_V(II).GT.(UP_LH(II) - OPEN_GAP_2(JJ-II-1)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ((UP_LH(II) - OPEN_GAP_2(JJ-II-1)).GE. MAX_V(II) 
     +                 .AND. (UP_LH(II) - OPEN_GAP_2(JJ-II-1)) .GT. 
     +                 0.0) THEN
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_2(JJ-II-1))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
c======================================================================
c which value is the best (diagonal,horizontal or vertical)
c======================================================================
               MAX_D(II)= DIAG_LH(JJ-II)+METRIC_2(JJ-II-1,LSQ_1(II-1))
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
	          BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
	          BESTNOW = MAX_V(II)
	          LH2(II,JJ-II) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
	          BESTNOW = MAX_H(JJ-II)
	          LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW = 0.0
	          LH2(II,JJ-II) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
c--------------------------------------------------------------------
C full profile alignment 
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 3) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG

CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               
               SUM=0.0 
               XMAX1=0.0 
               XMAX2=0.0
               DO K=1,NTRANS
                  SUM = SUM + ( METRIC_1(II-1,K) * METRIC_2(JJ-II-1,K) )
C     IF ( METRIC_1(II-1,K) .GT. XMAX1 ) THEN
C     XMAX1 =  METRIC_1(II-1,K)
C     ENDIF
C     IF ( METRIC_2(JJ-II-1,K) .GT. XMAX2 ) THEN
C     XMAX2 =  METRIC_1(JJ-II-1,K)
C     ENDIF
               ENDDO
               
C     OPEN_GAP_1(II-1)     = GAPOPEN_1(II-1)     * XMAX1
C     ELONG_GAP_1(II-1)    = GAPELONG_1(II-1)    * XMAX1
C     OPEN_GAP_2(JJ-II-1)  = GAPOPEN_2(JJ-II-1)  * XMAX2
C     ELONG_GAP_2(JJ-II-1) = GAPELONG_2(JJ-II-1) * XMAX2
               
c	WRITE(6,*)ii,jj-ii,sum

c	      MAX_D(II) = DIAG_LH(JJ-II) + (SUM/NTRANS)

               MAX_H(JJ-II)= MAX_H(JJ-II)-
     +              (( ELONG_GAP_1(II-1)+ ELONG_GAP_2(JJ-II-1))* 0.5)
               IF (MAX_H(JJ-II) .GT.  (LEFT_LH(JJ-II)-
     +              (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +              .AND. MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GE. MAX_H(JJ-II) .AND. (LEFT_LH(JJ-II)- 
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT.0.0) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II)-
     +                    ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
C=====================================================================
C       store best value and length for vertical deletion
C=====================================================================
               MAX_V(II)= MAX_V(II)-
     +              (( ELONG_GAP_1(II-1)+ ELONG_GAP_2(JJ-II-1))* 0.5)
               IF ( MAX_V(II) .GT. (UP_LH(II)-
     +              (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ( (UP_LH(II)- (( OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GE. MAX_V(II)
     +                 .AND.  (UP_LH(II)- ((OPEN_GAP_1(II-1)+ 
     +                 OPEN_GAP_2(JJ-II-1))*0.5)).GT.0.0) THEN
                  MAX_V(II)= (UP_LH(II)-
     +                 (( OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II) = DIAG_LH(JJ-II) + SUM
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
	          BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
	          BESTNOW = MAX_V(II)
	          LH2(II,JJ-II) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
	          BESTNOW = MAX_H(JJ-II)
	          LH2(II,JJ-II) = 20000 + LDEL_H(JJ-II)
               ELSE
	          BESTNOW = 0.0
	          LH2(II,JJ-II ) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C--------------------------------------------------------------------
C take sequences as representatives of family
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 4) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               MAX_H(JJ-II)= MAX_H(JJ-II)- 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1)) *0.5)
               IF (MAX_H(JJ-II) .GT. (LEFT_LH(JJ-II) -
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +              .AND. MAX_H(JJ-II) .GT.0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ( (LEFT_LH(JJ-II) - ((OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GE. MAX_H(JJ-II) 
     +                 .AND. (LEFT_LH(JJ-II) - ((OPEN_GAP_1(II-1)+
     +                 OPEN_GAP_2(JJ-II-1))*0.5)) .GT. 0.0 ) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
C=====================================================================
C     STORE BEST VALUE AND LENGTH FOR VERTICAL DELETION
C=====================================================================
               MAX_V(II)= (MAX_V(II)- 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1)) *0.5))
               IF ( MAX_V(II) .GT.  (UP_LH(II)-
     +              ((OPEN_GAP_1(II-1) +OPEN_GAP_2(JJ-II-1)) *0.5)) 
     +              .AND. MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ( (UP_LH(II)- 
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GE. MAX_V(II) 
     +                 .AND.  (UP_LH(II)- ((OPEN_GAP_1(II-1) +
     +                 OPEN_GAP_2(JJ-II-1)) *0.5)) .GT. 0.0 ) THEN
                  MAX_V(II)=(UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1) +OPEN_GAP_2(JJ-II-1)) *0.5))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II)= DIAG_LH(JJ-II) +
     +              (( METRIC_1 (II-1,LSQ_2(JJ-II-1)) +
     +              METRIC_2 (JJ-II-1,LSQ_1(II-1)) ) * 0.5)
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
                  BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
                  BESTNOW = MAX_V(II)
                  LH2(II,JJ-II ) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
                  BESTNOW = MAX_H(JJ-II)
                  LH2(II,JJ-II ) = 20000 + LDEL_H(JJ-II)
               ELSE
                  BESTNOW = 0.0
                  LH2(II,JJ-II ) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C--------------------------------------------------------------------
C take maximal value as consensus
C--------------------------------------------------------------------
      ELSE IF (PROFILEMODE .EQ. 5) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
               
               MAX_H(JJ-II)=MAX_H(JJ-II) - 
     +              ((ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1))*0.5)
               IF (MAX_H(JJ-II) .GT. (LEFT_LH(JJ-II) -
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))  
     +              .AND. MAX_H(JJ-II) .GT. 0.0 ) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF ((LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GE.MAX_H(JJ-II) .AND. (LEFT_LH(JJ-II) -  
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT. 0.0) THEN
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II) = (LEFT_LH(JJ-II) -
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
               ELSE
                  MAX_H(JJ-II) = 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
C=====================================================================
C       store best value and length for vertical deletion
C=====================================================================
               MAX_V(II)= MAX_V(II) - 
     +              ( (ELONG_GAP_1(II-1)+ELONG_GAP_2(JJ-II-1))*0.5)
               IF ( MAX_V(II) .GT. (UP_LH(II)-
     +              ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)) .AND.
     +              MAX_V(II) .GT. 0.0 ) THEN
                  LDEL_V(II) = LDEL_V(II) + 1
               ELSE IF ((UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5)) 
     +                 .GE.MAX_V(II) .AND. (UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
     +                 .GT. 0.0) THEN
                  MAX_V(II)= (UP_LH(II)-
     +                 ((OPEN_GAP_1(II-1)+OPEN_GAP_2(JJ-II-1))*0.5))
                  LDEL_V(II)= 1
               ELSE
                  MAX_V(II) = 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================
C which value is the best (diagonal,horizontal or vertical)
C store traceback 
C LDIREC and LDEL are coded in one number
C======================================================================
               MAX_D(II) = DIAG_LH(JJ-II) + 
     +              ((MAX_METRIC_1_VAL(II-1) + 
     +              MAX_METRIC_2_VAL(II-1)) * 0.5)
               IF (      MAX_D(II) .GE. MAX_V(II)    .AND.
     +              MAX_D(II) .GE. MAX_H(JJ-II) .AND.
     +              MAX_D(II) .GT. 0.0) THEN
                  BESTNOW = MAX_D(II)
               ELSE IF ( MAX_V(II) .GT. MAX_D(II)    .AND.
     +                 MAX_V(II) .GT. MAX_H(JJ-II) .AND.
     +                 MAX_V(II) .GT. 0.0) THEN
                  BESTNOW = MAX_V(II)
                  LH2(II,JJ-II ) = 10000 + LDEL_V(II)
               ELSE IF ( MAX_H(JJ-II) .GT. MAX_D(II)    .AND.
     +                 MAX_H(JJ-II) .GT. MAX_V(II) .AND.
     +                 MAX_H(JJ-II) .GT. 0.0) THEN
                  BESTNOW = MAX_H(JJ-II)
                  LH2(II,JJ-II ) = 20000 + LDEL_H(JJ-II)
               ELSE
                  BESTNOW = 0.0
                  LH2(II,JJ-II ) = 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)=    UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)     = BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C====================================================================
      ELSE IF (PROFILEMODE .EQ. 6) THEN
         DO IDIAG=1,NDIAGONAL
            IF     ( IDIAG .LE. ISMALL_DIM) THEN 
               LEN_DIAG=LEN_DIAG+1
            ELSE IF ( IDIAG .GT. IBIG_DIM  ) THEN 
               LEN_DIAG=LEN_DIAG-1
            ENDIF
            IF (IDIAG .LE. NSIZE1) THEN 
               IIBEG=IIBEG+1
            ELSE                      
               JJBEG=JJBEG+1
            ENDIF
            JJ=JJBEG+IIBEG
CPAR$ DO_PARALLEL
cccC$DIR PARALLEL
cvd$ nodepchk
            DO II=IIBEG,IIBEG-LEN_DIAG+1,-1
C=====================================================================
               MAX_H(JJ-II) = (MAX_H(JJ-II) - ELONG_GAP_1(II-1))
               IF ((MAX_H(JJ-II).GE.(LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)))
     +              .AND. (MAX_H(JJ-II) .GT.0.0 )) THEN
                  LDEL_H(JJ-II)= LDEL_H(JJ-II)+1
               ELSE IF (((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) .GE. 
     +                 MAX_H(JJ-II)) 
     +                 .AND. ((LEFT_LH(JJ-II)-OPEN_GAP_1(II-1)) 
     +                 .GT. 0.0)) THEN 
                  LDEL_H(JJ-II)= 1
                  MAX_H(JJ-II)= (LEFT_LH(JJ-II) - OPEN_GAP_1(II-1))
               ELSE
                  MAX_H(JJ-II)= 0.0 
                  LDEL_H(JJ-II)= 0
               ENDIF
c=====================================================================
               MAX_V(II) = (MAX_V(II) - ELONG_GAP_1(II-1))
               IF ( (MAX_V(II).GE.(UP_LH(II)-OPEN_GAP_1(II-1))) .AND.
     +              ( MAX_V(II) .GT. 0.0) ) THEN 
                  LDEL_V(II)= LDEL_V(II) + 1
               ELSE IF ( ((UP_LH(II)-OPEN_GAP_1(II-1)).GE.MAX_V(II)) 
     +                 .AND. ((UP_LH(II) - OPEN_GAP_1(II-1)) 
     +                 .GT. 0.0)) THEN 
                  MAX_V(II)= (UP_LH(II) - OPEN_GAP_1(II-1))
                  LDEL_V(II)=1
               ELSE
                  MAX_V(II)= 0.0 
                  LDEL_V(II)= 0
               ENDIF
C======================================================================

               MAX_D(II)= DIAG_LH(JJ-II) + 
     +              SIMORG(LSQ_1(II-1),LSQ_2(JJ-II-1),LSTRCLASS_1(II-1),
     +              LACC_1(II-1),LSTRCLASS_2(JJ-II-1),
     +              LACC_2(JJ-II-1) )
               IF (      (MAX_D(II) .GE. MAX_V(II) )   .AND.
     +              (MAX_D(II) .GE. MAX_H(JJ-II)) .AND.
     +              (MAX_D(II) .GT. 0.0 )) THEN
                  BESTNOW= MAX_D(II)
               ELSE IF ( (MAX_V(II) .GE. MAX_D(II) )   .AND.
     +                 (MAX_V(II) .GE. MAX_H(JJ-II)) .AND.
     +                 (MAX_V(II) .GT. 0.0 )) THEN
                  BESTNOW= MAX_V(II)
                  LH2(II,JJ-II)= 10000 + LDEL_V(II)
               ELSE IF ( (MAX_H(JJ-II) .GE. MAX_D(II))    .AND.
     +                 (MAX_H(JJ-II) .GE. MAX_V(II)) .AND.
     +                 (MAX_H(JJ-II) .GT. 0.0 )) THEN
                  BESTNOW= MAX_H(JJ-II)
                  LH2(II,JJ-II)= 20000 + LDEL_H(JJ-II)
               ELSE
                  BESTNOW= 0.0
                  LH2(II,JJ-II)= 0
               ENDIF
               IF (LSAMESEQ .AND. II .EQ. JJ-II) THEN 
                  BESTNOW= 0.0 
                  LH2(II,II)= 0
               ENDIF
               DIAG_LH(JJ-II)= UP_LH(II)
               LEFT_LH(JJ-II)= BESTNOW
               UP_LH(II)= BESTNOW
               IF (BESTNOW .GT. BESTVAL) THEN
                  BESTVAL=BESTNOW
                  BESTIIPOS=II
                  BESTJJPOS=JJ-II
               ENDIF
            ENDDO
C====================================================================
C next antidiagonal
C====================================================================
         ENDDO
C====================================================================
C PROFILE MODE SELECTION END
      ENDIF
C====================================================================
C debug: output the LH (values and trace-back)matrix 
c      call open_file(99,'matrix.dat','new,recl=2000',lerror)
c      nii=n1+1 ; njj=n2+1
c      write(99,*)'TRACE-BACK MATRIX' 
c      do i=1,nii
c	  write(99,'(i6)')i ; write(99,'(2x,20(i6))')(lh2(i,j),j=1,njj)
c      enddo
c      close(99)
C=======================================================================
      RETURN
      END              
C     END SETMATRIX_FAST_OLD
C......................................................................

C......................................................................
C     SUB SETPIECES
      SUBROUTINE SETPIECES(MAXALSQ,ALI_1,ALI_2,LENALI,IFIR,
     +     ILAS,JFIR,JLAS,IPIECE,MAXPIECES,NPIECES)
C RS 89
C   cut a sequence alignment in pieces if there are insertions/deletions
C   or chain-breaks (used in ALITOSTRUCRMS)
C CAUTION : dont use an alignment like in MAXHOM (HSSP)
C          (no insertion in SEQ 1)
C          alignment must be : 
C	      ALI_1  : ACVEFG....FGHKLIPYDFGAS!KLHKLH
C             ALI_2  : ACAEFGAAAAFGH...PYDFGAS!KLHKLH
C                      |    |    | |   |     | |    |
C             PIECE  : | 1  |    |2|   |  3  | |4   |
C             insertions must be marked by "."
C             chain-breaks by "!"
C INPUT:
C       ALI_1,ALI_2 : sequence string for seq 1 and seq 2 (CHARACTER*(*))
C       LENALI      : length of the total alignment (include insertions)
C       IFIR,ILAS   : first and last position of seq 1  (absolut position)
C       JFIR,JLAS   : first and last position of seq 2  (absolut position)
C OUTPUT:
C       IPIECE(2,2,MAXPIECES)  : 1. index= begin and end of piece
C                                2. index= sequence 1 or sequence 2
C                                3. index= number of piece
C       NPIECES                :    total number of pieces
C INTERNAL: 
C       ICOUNT : count alignend positions to get absolute position

      IMPLICIT      NONE
      
      INTEGER       MAXPIECES,MAXALSQ
      CHARACTER*1   ALI_1(MAXALSQ),ALI_2(MAXALSQ)
      INTEGER       IPIECE(2,2,MAXPIECES),NPIECES,
     +              LENALI,IFIR,ILAS,JFIR,JLAS

C     INTERNAL
      INTEGER IBEG,IEND,JBEG,JEND,ICOUNT,ISTART,ISTOP,K,I
      
c init
      IBEG=IFIR 
      IEND=ILAS 
      JBEG=JFIR 
      JEND=JLAS
      NPIECES=1
      ICOUNT=0		
C     D	WRITE(6,*)(ALI_1(I),I=1,LENALI)
C     D	WRITE(6,*)(ALI_2(I),I=1,LENALI)
C     AUTION: FIRST AND LAST CHARACTER IN THE ALIGNMENT IS '<'
      IF (ALI_1(1).EQ.'<' .AND. ALI_2(1).EQ.'<') THEN
         ISTART=2 
      ELSE 
         ISTART=1 
      ENDIF
      IF (ALI_1(LENALI).EQ.'<' .AND. ALI_2(LENALI).EQ.'<') THEN
         ISTOP=LENALI-1 
      ELSE 
         ISTOP=LENALI 
      ENDIF
      IF (ALI_1(ISTART).EQ. '!' .AND. ALI_2(ISTART) .EQ. '!') THEN
         ISTART=ISTART+1 
         IBEG=IBEG+1 
         JBEG=JBEG+1
      ENDIF
      IF (ALI_1(ISTOP).EQ. '!' .AND. ALI_2(ISTOP) .EQ. '!') THEN
         ISTOP=ISTOP-1 
         IEND=ILAS-1 
         JEND=JEND-1 
         ILAS=IEND 
         JLAS=JEND
      ENDIF
C     SET DEFAULT TO BEGIN AND END OF ALIGNMENT
      IPIECE(1,1,NPIECES)=IBEG 
      IPIECE(2,1,NPIECES)=IEND
      IPIECE(1,2,NPIECES)=JBEG 
      IPIECE(2,2,NPIECES)=JEND
      
      DO K=ISTART,ISTOP
         CALL CHECKRANGE(NPIECES,1,MAXPIECES,'MAXPIECES ','SETPIECES ')
C search for an insertion in SEQuence 1
         IF (ALI_1(K).EQ.'.' .AND. ALI_2(K).NE. '!') THEN
C if: set end of previous piece, store piece in IPIECE and set begin 
C     of next piece
            IF (ALI_1(K-1).NE.'.' .AND. ALI_1(K-1).NE.'!') THEN
               IEND=IBEG+ICOUNT-1 
               JEND=JBEG+ICOUNT-1
               IPIECE(1,1,NPIECES)=IBEG 
               IPIECE(2,1,NPIECES)=IEND
               IPIECE(1,2,NPIECES)=JBEG 
               IPIECE(2,2,NPIECES)=JEND
C     D    	        WRITE(6,*)' 1 SET PIECE : ',IBEG,IEND,JBEG,JEND
C     D	        WRITE(6,*)(ALI_1(I),I=1,K) 
               WRITE(6,*)(ALI_2(I),I=1,K)
               IBEG=IEND+1 
               JBEG=JEND+2
               NPIECES=NPIECES+1
            ELSE
               JBEG=JBEG+1 
            ENDIF
            ICOUNT=0
C search for an insertion in SEQuence 2
         ELSE IF (ALI_2(K).EQ.'.' .AND. ALI_1(K).NE.'!') THEN
C if: set end of previous piece, store piece in IPIECE and set begin 
C     of next piece
            IF (ALI_2(K-1).NE.'.' .AND. ALI_2(K-1).NE.'!') THEN
               IEND=IBEG+ICOUNT-1 
               JEND=JBEG+ICOUNT-1
               IPIECE(1,1,NPIECES)=IBEG 
               IPIECE(2,1,NPIECES)=IEND
               IPIECE(1,2,NPIECES)=JBEG 
               IPIECE(2,2,NPIECES)=JEND
C     D    	        WRITE(6,*)' 2 SET PIECE : ',IBEG,IEND,JBEG,JEND
C     D	        WRITE(6,*)(ALI_1(I),I=1,K) ; WRITE(6,*)(ALI_2(I),I=1,K)
               IBEG=IEND+2 
               JBEG=JEND+1
               NPIECES=NPIECES+1
            ELSE 
               IBEG=IBEG+1 
            ENDIF
            ICOUNT=0
C search for a chain-break in SEQuence 1 or SEQuence 2 and set piece
         ELSE IF (ALI_1(K).EQ.'!' .OR. ALI_2(K).EQ.'!') THEN
            IF (ALI_1(K-1).NE.'.' .AND. ALI_2(K-1).NE.'.') THEN 
	       IEND=IBEG+ICOUNT-1 
               JEND=JBEG+ICOUNT-1
	       IPIECE(1,1,NPIECES)=IBEG 
               IPIECE(2,1,NPIECES)=IEND
       	       IPIECE(1,2,NPIECES)=JBEG 
               IPIECE(2,2,NPIECES)=JEND
C     D 	       WRITE(6,*)' 3 SET PIECE : ',IBEG,IEND,JBEG,JEND
C     D	       WRITE(6,*)(ALI_1(I),I=1,K) ; WRITE(6,*)(ALI_2(I),I=1,K)
               NPIECES=NPIECES+1 
               IBEG=IEND+1 
               JBEG=JEND+1
            ENDIF
            IF (ALI_1(K).EQ.'!' .AND. ALI_2(K).EQ.'!') THEN
               IBEG=IBEG+1 
               JBEG=JBEG+1
            ELSE IF (ALI_1(K).EQ.'!') THEN 
               IBEG=IBEG+1
            ELSE IF (ALI_2(K).EQ.'!') THEN 
               JBEG=JBEG+1
            ENDIF
            ICOUNT=0
         ELSE 
            ICOUNT=ICOUNT+1
         ENDIF
      ENDDO
      IPIECE(1,1,NPIECES)=IBEG 
      IPIECE(2,1,NPIECES)=ILAS
      IPIECE(1,2,NPIECES)=JBEG 
      IPIECE(2,2,NPIECES)=JLAS
cd        WRITE(6,*)' 4 set piece : ',ibeg,ilas,jbeg,jlas
      RETURN
      END
C     END SETPIECES
C......................................................................

C......................................................................
C     SUB SKIP_BRKCHAIN
      SUBROUTINE SKIP_BRKCHAIN(KIN,RLEN,FIRSTLINE,ERROR)
C 15.5.93
      IMPLICIT        NONE
C Import
      INTEGER         KIN,RLEN
      CHARACTER*(*)   FIRSTLINE
C     EXPORT
      LOGICAL         ERROR
C     .. AND NEW LOCATION OF READ POINTER FOR UNIT KIN
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      CHARACTER*(LINELEN) LINE
*----------------------------------------------------------------------*
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      ERROR = .FALSE.
      LINE = FIRSTLINE
      DO WHILE ( LINE(1:3) .NE. 'TER' )
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') ' ** error reading BRK file **'
 2    CONTINUE

      RETURN
      END
C     END SKIP_BRKCHAIN
C......................................................................

C......................................................................
C     SUB SKIP_DSSPCHAIN
      SUBROUTINE SKIP_DSSPCHAIN(KIN,RLEN,FIRSTLINE,ERROR)
C 15.5.93
      IMPLICIT NONE
C Import
      INTEGER KIN,RLEN
      CHARACTER*(*) FIRSTLINE
C     EXPORT
      LOGICAL         ERROR
C     .. AND NEW LOCATION OF READ POINTER FOR UNIT KIN
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      CHARACTER*(LINELEN) LINE
*----------------------------------------------------------------------*
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      ERROR = .FALSE.
      LINE = FIRSTLINE
      DO WHILE ( LINE(14:14) .NE. '!' )
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(A)') ' ** error reading DSSP file **'
 2    CONTINUE
      
      RETURN
      END
C     END SKIP_DSSPCHAIN
C......................................................................

C......................................................................
C     SUB SKIP_HSSPCHAIN
      SUBROUTINE SKIP_HSSPCHAIN(KIN,RLEN,FIRSTLINE,ERROR)
C 18.5.93
      IMPLICIT NONE
C Import
      INTEGER KIN,RLEN
      CHARACTER*(*) FIRSTLINE
C     EXPORT
      LOGICAL ERROR
C     .. AND NEW LOCATION OF READ POINTER FOR UNIT KIN
C     INTERNAL
      INTEGER         LINELEN
      PARAMETER      (LINELEN=                1000)
      CHARACTER*(LINELEN) LINE
*----------------------------------------------------------------------*
      
      IF ( LINELEN .LT. RLEN ) THEN
         WRITE(6,'(1X,A)') 
     1        ' *** record length of input file too big ***'
         GOTO 1
      ENDIF
      
      LINE = FIRSTLINE
      DO WHILE ( LINE(15:15) .NE. '!' )
         READ(KIN,'(A)',ERR=1,END=2) LINE
      ENDDO
      
      GOTO 2
 1    ERROR = .TRUE.
      WRITE(6,'(a)') '*** ERROR SKIP_HSSPCHAIN reading HSSP file'
 2    CONTINUE

      RETURN
      END                                                            
C     END SKIP_HSSPCHAIN
C......................................................................

C......................................................................
C     SUB STR_TO_INT
      SUBROUTINE STR_TO_INT(NRES,STRUC,LSTRUC,STRSTATES)  

      IMPLICIT NONE
      INTEGER NRES,LSTRUC(*)
      CHARACTER*(*) STRUC(*),STRSTATES
c internal
      INTEGER I
c=======================================================================
      DO I=1,NRES
         LSTRUC(I)=INDEX(STRSTATES,STRUC(I))
         IF (LSTRUC(I) .EQ. 0) THEN
            WRITE(6,*)' unknown structure in str_to_int:',struc(i),':'
            WRITE(6,*)STRSTATES
            CALL FLUSH_UNIT(6)
            STOP
         ENDIF
      ENDDO
      RETURN
      END
C     END STR_TO_INT
C......................................................................

C......................................................................
C     SUB STR_TO_CLASS
      SUBROUTINE STR_TO_CLASS(MAXSTATES,STR_STATES,NRES,
     +     STRUC,CLASS,ICLASS)
C convert DSSP-secondary structure symbol to secondary structure 
C classes (L,H,E..) ; first symbol in str_states(x)
C str_states(1)='L TCStclss'
C str_states(2)='EBAPMebapm'
C str_states(3)='HGIhgiiiii'
C given STRUC, what is the class number ICLASS and class  representative CLASS ?
C undefined states is set CLASS='U', ICLASS=0
C
      IMPLICIT NONE
C input
      INTEGER MAXSTATES,NRES
      CHARACTER*(*) STRUC(*),STR_STATES(*)
c output
      CHARACTER*(*) CLASS
      INTEGER ICLASS(*)
C internal
      INTEGER I,J
C======================================================================
      DO I=1,NRES
         DO J=1,MAXSTATES
C            WRITE(*,*)' info:RESNUM I, STATE J, MATCH ',
C     +           I,J,INDEX(STR_STATES(J),STRUC(I))
            IF ( INDEX(STR_STATES(J),STRUC(I)) .NE. 0) THEN
               GOTO 100
            ENDIF
         ENDDO
c	   iclass(i)=0
c           class(i:i)='U'
c	   WRITE(6,*)' symbol not known in STR_TO_CLASS: ',struc(i)
 100     ICLASS(I)=J
         CLASS(I:I)=STR_STATES(J)(1:1)
         
C	   WRITE(6,*)'info: RESULT ',i,j,iclass(i),' ',str_states(j)(1:1)
      ENDDO

      RETURN
      END
C     END STR_TO_CLASS
C......................................................................

C......................................................................
C     SUB StringLen
      SUBROUTINE STRINGLEN(CSTRING,ILEN)
C searches for the last non-blank character in a string
      CHARACTER*(*) CSTRING
      INTEGER ILEN
      ILEN=LEN(CSTRING)
      DO WHILE(ILEN.GT.0 .AND. CSTRING(ILEN:ILEN).EQ. ' ')	
         ILEN=ILEN-1
      ENDDO
      RETURN
      END
C     END STRINGLEN
C......................................................................

C......................................................................
C     SUB STRTRIM
      SUBROUTINE STRTRIM(SOURCE,DEST,LENGTH)
C StrTrim(Source,Dest,Length): Dest=Source(-1:-1)//filled with blanks
C                              Length=length of Source(-1:-1)
C -------------------------------------------------------------------
      CHARACTER*(*) SOURCE,DEST
      CHARACTER*500 TEMPSTRING

      TEMPSTRING=' '
      LENGTH=0
      ISTART=1
      ISTOP= LEN(SOURCE)
      IF (ISTOP .GT. LEN(TEMPSTRING) ) THEN
         WRITE(6,*)' STRTRIM: tempstring too short'
         STOP
      ENDIF
      I=1
      DO WHILE (SOURCE(I:I) .EQ. ' ')
         I=I+1
         IF (I .GT. LEN(SOURCE)) RETURN
      ENDDO
      ISTART=I
      I=LEN(SOURCE)
      DO WHILE (SOURCE(I:I) .EQ. ' ')
         I=I-1
         IF (I .LE. 1)GOTO 10
      ENDDO
 10   ISTOP=I
      LENGTH=ISTOP-ISTART+1
      TEMPSTRING(1:)= SOURCE(ISTART:ISTOP)
      DEST(1:LENGTH)=TEMPSTRING(1:LENGTH)
      DO I=LENGTH+1,LEN(DEST)
         DEST(I:I)=' '
      ENDDO
      
      RETURN
      END
C     END STRTRIM
C......................................................................

C......................................................................
C     SUB STRPOS
      SUBROUTINE STRPOS(SOURCE,ISTART,ISTOP)
C StrPos(Source,IStart,IStop): Finds the positions of the first and
C last non-blank/non-TAB in Source. IStart=IStop=0 for empty Source
      CHARACTER*(*) SOURCE
      INTEGER ISTART,ISTOP
      
      ISTART=0
      ISTOP=0
      DO J=1,LEN(SOURCE)
         IF (SOURCE(J:J).NE.' ') THEN
            ISTART=J
            GOTO 20
         ENDIF
      ENDDO
      RETURN
 20   DO J=LEN(SOURCE),1,-1
         IF (SOURCE(J:J).NE.' ') THEN
            ISTOP=J
            RETURN
         ENDIF
      ENDDO
      ISTART=0
      ISTOP=0
      RETURN
      END
C     END STRPOS
C......................................................................

C......................................................................
C     SUB STRUC_CLASS
      SUBROUTINE STRUC_CLASS(MAXSTRSTATES,STR_CLASSES,
     +     STRUC,CLASS,ICLASS)
C given struc, what is the class number ICLASS and class 
C    representative CLASS ?
C    undefined states is set CLASS='U', ICLASS=0
      INTEGER       MAXSTRSTATES,ICLASS
C---- br 99.03: watch hard_coded here, see maxhom.param
      CHARACTER*10  STR_CLASSES(MAXSTRSTATES)
C----     -->   REASON: the following produces warnings on SGI
C      CHARACTER*(*) STR_CLASSES(MAXSTRSTATES)
      CHARACTER     STRUC,CLASS
C     INTERNAL
      INTEGER I

      CLASS='U'
      ICLASS=0
      DO I=1,MAXSTRSTATES
         IF (INDEX(STR_CLASSES(I),STRUC) .NE. 0 ) THEN
            ICLASS=I
            CLASS=STR_CLASSES(I)(1:1)
            RETURN
         ENDIF
      ENDDO
C     WRITE(6,*)' SYMBOL NOT KNOWN IN STRUC_CLASS: ',STRUC
      RETURN
      END
C     END STRUC_CLASS
C......................................................................

C......................................................................
C     SUB STRTOINT
      SUBROUTINE STRTOINT(NRES,CSTR,LSTR,LDSSP)

      IMPLICIT NONE
      INTEGER NRES,LSTR(*)
      CHARACTER CSTR(*)
      LOGICAL LDSSP
C internal
      INTEGER I
      CHARACTER*25 STRSTATES
      STRSTATES=' LTCSltcsEBAPMebapmHGIhgi'
C=======================================================================
      IF (LDSSP) THEN
         DO I=1,NRES
            LSTR(I)=INDEX(STRSTATES,CSTR(I))
            IF (LSTR(I).EQ.0) THEN
	       WRITE(6,*)' UNKNOWN STRUCTURE IN STRTOINT: ',CSTR(I)
	       STOP
            ENDIF
         ENDDO
      ELSE
         DO I=1,NRES
            LSTR(I)=0
            CSTR(I)='U'
         ENDDO
      ENDIF
      RETURN
      END
C     END STRTOINT
C......................................................................

C......................................................................
C     SUB SWISSPROTRELEASE
      SUBROUTINE SWISSPROTRELEASE(KIN,INFILE,RELEASE,NENTRIES,
     +     NRESIDUE)
C     IMPORT
      CHARACTER*(*) INFILE
      INTEGER KIN
C     EXPORT
      REAL RELEASE
      INTEGER NENTRIES,NRESIDUE
c     internal
      CHARACTER*200 LINE
      LOGICAL LERROR
C......................................................................
C reads the latest version number and number of sequences of SWISSPROT
C on VAX at EMBL logical filename is SWISS_PROT$RELEASE:RELNOTES.DOC	
C this file contains somwhere the following lines:
C     Release    Date   Number of entries     Nb of amino acids
C
C     3.0        11/86               4160               969 641
C     4.0        04/87               4387             1 036 010
C    12.0        10/89              12305             3 797 482
C
CSome 1466 new sequences have been added since the ............
C......................................................................
      CALL OPEN_FILE(KIN,INFILE,'OLD,READONLY',lerror)
      IF (LERROR .EQV. .TRUE.) THEN
         RELEASE= 0.0
         NENTRIES=0
         NRESIDUE=0
         WRITE(6,*)'Error: No SwissProt release info found '
         RETURN
      ENDIF
      LINE=' '
      DO WHILE( INDEX (LINE,'Release    Date   Number of').EQ.0 .AND.
     +     INDEX (LINE,'Release      Date ').EQ.0)
         READ(KIN,'(A)')LINE
      ENDDO
      DO I=1,3
         READ(KIN,'(A)')LINE
      ENDDO
      DO WHILE (LINE .NE. ' ')
         READ(LINE,'(3X,F4.1,25X,I6,10X,I12)')RELEASE,NENTRIES,NRESIDUE
         READ(KIN,'(A)')LINE
      ENDDO
      CLOSE(KIN)
      RETURN
      END
C     END SWISSPROTRELEASE
C......................................................................
C......................................................................
C     SUB TRACE
      SUBROUTINE TRACE(ISET,ND1,ND2,LH2,IPOSBEG,JPOSBEG,VALUE,
     +     II,JJ,NTEST,SDEV,IALIGN,NRECORD)

C     NOTE:    TRACE will aplpy threshold, and return LCONSIDER=.FALSE.
C              if below threshold!
C     
C     coming in with protein IALIGN+1, i.e. IALIGN gives alignments
C              so far!

C===================================================================
C LDIREC and LDEL are the traceback indices unpacked
C from the LH matrix.
C LDIREC=1 indicates an unmatched terminal sequence,
C LDIREC=2 indicates a diagonal optimal path,
C LDIREC=3 indicates a vertical path in the matrix,
C LDIREC=4 indicates a horizonal traceback path.
C LDEL     is the length of the deletion/insertion for LDIREC=3 or 4
C CVAL     accumulated similarity values
C CMAXVAL  accumulated self matches ==> similarity
C-------------------------------------------------------------------
C                          PROFILEMODE
C 0: no profiles, just a simple sequence alignment
C 1: profile for sequence 1 (and not for sequence 2)
C 2: profile for sequence 2 (and not for sequence 1)
C 3: full alignment of two profiles, without taking into account the
C     sequence (structure,I/O...) information 
C 4: take the sequences as a representative of the family
C 5: take the maximal value at each position as a "consensus" sequence
C-------------------------------------------------------------------
C                         weighted gap:                   
C here opening and elongation are weighted
C LDIREC=4 : horizontal deletion
C LDIREC=3 : vertical deletion
C
C  =======================================> II (matrix position)
C  |                             \
C  |  \                           \
C  |   \                           \
C  |    \                           ^    open: II
C  |     \                          |    elongation: JJ-LDEL+1 ==> JJ-1
C  V      \         LDEL            |
C  JJ      \<-----------------------  II,JJ  
C                                   \
C open:  II-LDEL                     \
C elongation: II-LDEL+1 ====> II-1    \
C                                      \
C
C horizontal gap-open: 
C      GAPOPEN(II-LDEL) * cons-weight (II-LDEL)
C horizontal gap-elong: 
C      sum (GAPELONG(II-LDEL+1) * cons-weight (II-LDEL+1) ===> (II-1) )
C-------------------------------------------------------------------
      IMPLICIT        NONE

      INCLUDE         'maxhom.param'
      INCLUDE         'maxhom.common'
C import
      INTEGER         ISET,ND1,ND2
C     REAL      LH1(0:*)          
      INTEGER*2       LH2(0:ND1,0:ND2)          
C     INTEGER*2 LH2(0:*)          
C     REAL LH(0:*)          
      REAL            VALUE,SDEV
      INTEGER         II,JJ,NTEST,IPOSBEG,JPOSBEG
C export
C alignment attributes of the MAXALIGNS best alignments
      INTEGER         IALIGN,NRECORD
C=======================================================================
C internal
      INTEGER         MAXTRACE_LOC
      PARAMETER      (MAXTRACE_LOC=         6543210)
C      PARAMETER      (MAXTRACE_LOC=         150000)
C      PARAMETER      (MAXTRACE_LOC=       30000000)
      CHARACTER*1     SK_1,SK_2
      INTEGER         IDELETION
      
      INTEGER         INSPOINTER_LOCAL,
     +                ITEMP_NO1(MAXTRACE_LOC),ITEMP_NO2(MAXTRACE_LOC),
     +                ENDMARK,INDELMARK,
     +                I,J,K,M,P,Q,ILAS,JLAS,LDEL_DIREC,
     +                LDEL,LEM,IFIR,JFIR,IDAL,
     +                IDSAL,NDEL,ICLASS,LEN1,LENOCC,LINELEN,IBLOCKLEN,
     +                ISTART,IPOS,JPOS,NLINE,IBEG,IEND,
     +                LINETHICK,LEN_INSSEQ
      CHARACTER       CTEMP_CHAIN1(MAXTRACE_LOC),
     +                CTEMP_CHAIN2(MAXTRACE_LOC),
     +                CTEMP*20000,
     +                LINE(4)*(MAXALSQ)
      CHARACTER*4     PID_1,PID_2
      REAL            MAXDEVIATION,
     +                MAX1,MAX2,SUM,SIM,CVAL,CMAXVAL,SELFSIM,
     +                OPENWEIGHT,ELONGWEIGHT,W,PER,HOM,
     +                DISTANCE,RMS
      LOGICAL         LERROR,LKINK,LCALPHA,LDBG_LOCAL
      INTEGER         ILOC,JLOC
C     CHARACTER*200 ERRORFILE

C      WRITE(6,*)'debug trace'
C      WRITE(6,*)'ISET ND1 ND2 ',ISET,ND1,ND2
C      WRITE(6,*)'IPOSBEG JPOSBEG II JJ ',IPOSBEG,JPOSBEG,II,JJ
C      WRITE(6,*)'VALUE NTEST SDEV ',VALUE,NTEST,SDEV
C      WRITE(6,*)'IALIGN NRECORD ',IALIGN,NRECORD
C      DO ILOC=0,ND1
C         DO JLOC=0,ND2
C            WRITE(6,*)'ILOC JLOC LH2 ',ILOC,JLOC,LH2(ILOC,JLOC)
C         ENDDO
C      ENDDO
C====================================================================
C init	
c	line(2)=' ' ; line(3)=' '
c	do i=1,maxalsq ; al_agree(i)=' ' ; sal_agree(i)=' ' ; enddo

C     BR 99.09: to write out some dbg msg
      LDBG_LOCAL=      .FALSE.
C      LDBG_LOCAL=      .TRUE.

      OPENWEIGHT=      0.0 
      ELONGWEIGHT=     0.0
C ENDMARK : '<'
C INDELMARK: '.'
      ENDMARK=       999
      INDELMARK=      99
      M=               0 
      NTEST=           NTEST+1 
      ILAS=            II-1 
      JLAS=            JJ-1
      SIM=             0.0 
      CVAL=            0.0  
      CMAXVAL=         0.0
      DISTANCE=        0.0
      IINS=            0  
      INSPOINTER_LOCAL=1
      INSSEQ=          ' '
C      LEN_NAME=        LEN(NAME_2) 
C      LEN_COMPND=      LEN(COMPND_2) 
C      LEN_ACCESSION=   LEN(ACCESSION_2)
C      LEN_PDBREF=      LEN(PDBREF_2)
C      LEN_LINE=        LEN( LINE(1) )

C      DO I=0, ND1
C         DO J=0, ND2
C            WRITE(6,*) 'I,J,LH2: ',I,J,LH2(I,J)
C         ENDDO
C      ENDDO



      LEN_INSSEQ=      LEN(INSSEQ)
c check subscripts
      IF (II .LE. 0 .OR. JJ .LE. 0) THEN
         WRITE(6,*)' FATAL ERROR IN TRACE'
         WRITE(6,*)' SUBSCRIPT OF II or JJ OUT OF RANGE',II,JJ
         STOP
      ENDIF
C===================== TRACE BACK ===================================
C alignment via loop back to 100
 100  IF ((II .GT. IPOSBEG) .AND. (JJ .GT. JPOSBEG)) THEN
         LDEL_DIREC =ABS( LH2(II,JJ) )
c	  if (.not. lbackward) then
c	     call get_ldirec_fast(nd1,nd2,lh2,ii,jj,ldel_direc)
c	  else
c	     call get_ldirec(nd1,nd2,lh2,ii,jj,ldel_direc)
c	  endif
c=======================================================================
C         diagonal: LIKE H(II,JJ) AND SEQ(II-1,1) SEQ(JJ-1,1)
C=======================================================================
         IF (LH2(II,JJ) .EQ. -1) THEN
	    RETURN
         ELSE IF (LDEL_DIREC .EQ. 1 ) THEN
	    M=M+1 
            II=II-1 
            JJ=JJ-1 
	    CALL CHECKRANGE(II,1,ND1-1,'subscr  II','TRACE')
	    CALL CHECKRANGE(JJ,1,ND2-1,'subscr  JJ','TRACE')
	    SELFSIM = 0.0
c--------------------------------------------------------------------
c no profile
c selfsim is match with master sequence
c--------------------------------------------------------------------
	    IF (PROFILEMODE .LT. 1) THEN
               SIM      = METRIC_1(II,LSQ_2(JJ))
               SELFSIM  = METRIC_1(II,LSQ_1(II))
c--------------------------------------------------------------------
c profile 1
c selfsim is match with best possible match at position ii
c--------------------------------------------------------------------
	    ELSE IF (PROFILEMODE .EQ. 1) THEN
               SIM      = METRIC_1(II,LSQ_2(JJ))
               SELFSIM=-9999
               DO K=1,NTRANS
                  IF ( METRIC_1(II,K) .GT. SELFSIM ) THEN
                     SELFSIM = METRIC_1(II,K)
                  ENDIF
               ENDDO
c--------------------------------------------------------------------
c profile 2
c--------------------------------------------------------------------
            ELSE IF (PROFILEMODE .EQ. 2) THEN
               SIM      = METRIC_2(JJ,LSQ_1(II))
               SELFSIM  = METRIC_2(JJ,LSQ_2(JJ)) 
C--------------------------------------------------------------------
C full profile alignment
C selfsim: sum  ( (metric_1(i,k) * metric_1(i,k))+
C           (metric_2(j,k) * metric_2(j,k) ) /2 )
C--------------------------------------------------------------------
            ELSE IF (PROFILEMODE .EQ. 3) THEN
               SUM=0.0
               SELFSIM=0.0
               DO K=1,NTRANS
                  SUM = SUM + ( METRIC_1(II,K) * METRIC_2(JJ,K) )
                  SELFSIM= SELFSIM + (METRIC_1(II,K) * METRIC_1(II,K))
C                  WRITE(6,*)K,SUM,METRIC_1(II,K),METRIC_2(JJ,K),
C     +                 METRIC_1(II,K) * METRIC_2(JJ,K)
               ENDDO
c	      sim  = (sum/ntrans)
               SIM  = SUM 
               SIM  = SIM - 50
               SELFSIM = SELFSIM - 50
c	      WRITE(6,*)sim,selfsim,metric_1(ii,1),metric_2(jj,1)
C--------------------------------------------------------------------
C take sequences as representatives of family
C selfsim: factor * (metric_1(i,lsq_1(i)) + metric_2(j,lsq_2(i))/2)
C--------------------------------------------------------------------
            ELSE IF (PROFILEMODE .EQ. 4) THEN
               SIM=(METRIC_1(II,LSQ_2(JJ))+METRIC_2( JJ,LSQ_1(II)) )*0.5
               SELFSIM =METRIC_1( II,LSQ_1(II))
c--------------------------------------------------------------------
c take maximal value as consensus
c selfsim ???
c--------------------------------------------------------------------
            ELSE IF (PROFILEMODE .EQ. 5) THEN
               MAX1=-10000.0
               DO K=1,NTRANS
                  IF (METRIC_1(II,K) .GT. MAX1)MAX1=METRIC_1(II,K)
C                  MAX1=MAX(METRIC_1(II,K),MAX1)
               ENDDO
               MAX2=-10000.0
               DO K=1,NTRANS
                  IF (METRIC_2(JJ,K) .GT. MAX2)MAX2=METRIC_2(JJ,K)
C                  MAX2=MAX(METRIC_2(JJ,K),MAX2)
               ENDDO
               SIM  = ( (MAX1 + MAX2) * 0.5 )
               SELFSIM=MAX(MAX1,MAX2)
            ELSE IF (PROFILEMODE .EQ. 6) THEN
               SIM      = SIMORG(LSQ_1(II),LSQ_2(JJ),LSTRCLASS_1(II),
     +              LACC_1(II),LSTRCLASS_2(JJ),LACC_2(JJ) )
            ELSE IF (PROFILEMODE .EQ. 7) THEN
               SIM      = SSSA_METRIC_1(II,LSQ_2(JJ),LSTRCLASS_2(JJ),
     +              LACC_2(JJ) )
               SELFSIM=-9999
               DO K=1,NTRANS
                  DO P=1,NSTRUCTRANS
                     DO Q=1,NACCTRANS
                        IF ( SSSA_METRIC_1(II,K,P,Q) .GT. SELFSIM ) THEN
                           SELFSIM = SSSA_METRIC_1(II,K,P,Q)
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO
            ELSE IF (PROFILEMODE .EQ. 8) THEN
               SIM      = SSSA_METRIC_2(JJ,LSQ_1(II),LSTRCLASS_1(II),
     +              LACC_1(II) )
               SELFSIM=-9999
               DO K=1,NTRANS
                  DO P=1,NSTRUCTRANS
                     DO Q=1,NACCTRANS
                        IF ( SSSA_METRIC_2(JJ,K,P,Q) .GT. SELFSIM ) THEN
                           SELFSIM = SSSA_METRIC_2(JJ,K,P,Q)
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO
            ELSE IF (PROFILEMODE .EQ. 9) THEN
               SIM=(
     +         SSSA_METRIC_1(II,LSQ_2(JJ),LSTRCLASS_2(JJ),LACC_2(JJ)) +
     +         SSSA_METRIC_2(JJ,LSQ_1(II),LSTRCLASS_1(II),LACC_1(II)) 
     +         ) *0.5
                   
               SELFSIM=-9999
               DO K=1,NTRANS
                  DO P=1,NSTRUCTRANS
                     DO Q=1,NACCTRANS
                        IF ( SSSA_METRIC_1(II,K,P,Q) .GT. SELFSIM ) THEN
                           SELFSIM = SSSA_METRIC_1(II,K,P,Q)
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO  
	    ENDIF
            
            
            
	    CVAL    = CVAL    + SIM 
	    CMAXVAL = CMAXVAL + SELFSIM
	    LAL_1(M)=LSQ_1(II) 
            LSAL_1(M)=LSTRCLASS_1(II)
	    LAL_2(M)=LSQ_2(JJ) 
            LSAL_2(M)=LSTRCLASS_2(JJ)
	    ITEMP_NO1(M)=PDBNO_1(II) 
            ITEMP_NO2(M)=PDBNO_2(JJ)
	    CTEMP_CHAIN1(M)=CHAINID_1(II) 
            CTEMP_CHAIN2(M)=CHAINID_2(JJ)
	    ITRACE(M)=II 
            JTRACE(M)=JJ
	    GOTO 100 
c=======================================================================
C                        horizontal deletion
C=======================================================================
         ELSE IF (LDEL_DIREC .GT. 20000) THEN
	    LDEL=LDEL_DIREC - 20000
	    IF (PROFILEMODE .LE. 1) THEN
               OPENWEIGHT = OPEN_GAP_1(II-LDEL)
	    ELSE IF (PROFILEMODE .EQ. 2) THEN
               OPENWEIGHT = OPEN_GAP_2(JJ-1)
	    ELSE IF (PROFILEMODE .EQ. 6) THEN
               OPENWEIGHT = OPEN_GAP_1(II-LDEL)
            ELSE IF (PROFILEMODE .EQ. 7) THEN
               OPENWEIGHT = OPEN_GAP_1(II-LDEL)
            ELSE IF (PROFILEMODE .EQ. 8) THEN
               OPENWEIGHT = OPEN_GAP_2(JJ-1)   
	    ELSE IF (PROFILEMODE .GE. 3) THEN
               OPENWEIGHT=(OPEN_GAP_1(II-LDEL) + OPEN_GAP_2(JJ-1)) * 0.5
	    ENDIF
	    W = OPENWEIGHT
            DO I=II-LDEL+1,II-1
	       IF (PROFILEMODE .LE. 1) THEN
                  ELONGWEIGHT = ELONG_GAP_1(I) 
	       ELSE IF (PROFILEMODE .EQ. 2) THEN
                  ELONGWEIGHT = ELONG_GAP_2(JJ-1) 
	       ELSE IF (PROFILEMODE .EQ. 6) THEN
                  ELONGWEIGHT = ELONG_GAP_1(I) 
               ELSE IF (PROFILEMODE .EQ. 7) THEN
                  ELONGWEIGHT = ELONG_GAP_1(I)
               ELSE IF (PROFILEMODE .EQ. 8) THEN
                  ELONGWEIGHT = ELONG_GAP_2(JJ-1)   
	       ELSE IF (PROFILEMODE .GE. 3) THEN
                  ELONGWEIGHT=(ELONG_GAP_1(I) + ELONG_GAP_2(JJ-1)) * 0.5
	       ENDIF
	       W = W  + ELONGWEIGHT
	    ENDDO
	    CVAL = CVAL  -  W 
	    DO K=1,LDEL
               M=M+1
               ITRACE(M)=II-K  
               JTRACE(M)=JJ-1
               LAL_1(M) = LSQ_1(II-K)    
               LAL_2(M) =INDELMARK
               LSAL_1(M)= LSTRCLASS_1(II-K) 
               LSAL_2(M)=INDELMARK
               ITEMP_NO1(M)=PDBNO_1(II-K) 
               ITEMP_NO2(M)=0
               CTEMP_CHAIN1(M)=CHAINID_1(II-K) 
               CTEMP_CHAIN2(M)=' '
	    ENDDO
            II=II-LDEL
	    GOTO 100
C=======================================================================
C     VERTICAL DELETION
C=======================================================================
         ELSE IF (LDEL_DIREC .GT. 10000) THEN
	    LDEL=LDEL_DIREC - 10000
	    IF (PROFILEMODE .LE. 1) THEN
               OPENWEIGHT  = OPEN_GAP_1(II-1)
	    ELSE IF (PROFILEMODE .EQ. 2) THEN
               OPENWEIGHT  = OPEN_GAP_2(JJ-LDEL)
	    ELSE IF (PROFILEMODE .EQ. 6) THEN
               OPENWEIGHT  = OPEN_GAP_1(II-1)
            ELSE IF (PROFILEMODE .EQ. 7) THEN
               OPENWEIGHT  = OPEN_GAP_1(II-1)
            ELSE IF (PROFILEMODE .EQ. 8) THEN
               OPENWEIGHT  = OPEN_GAP_2(JJ-LDEL)
	    ELSE IF (PROFILEMODE .GE. 3) THEN
               OPENWEIGHT=(OPEN_GAP_1(II-1) + OPEN_GAP_2(JJ-LDEL)) * 0.5
	    ENDIF
	    W = OPENWEIGHT 
            DO J=JJ-LDEL+1,JJ-1
	       IF (PROFILEMODE .LE. 1) THEN
                  ELONGWEIGHT = ELONG_GAP_1(II-1) 
	       ELSE IF (PROFILEMODE .EQ. 2) THEN
                  ELONGWEIGHT = ELONG_GAP_2(J) 
	       ELSE IF (PROFILEMODE .EQ. 6) THEN
                  ELONGWEIGHT = ELONG_GAP_1(II-1)
               ELSE IF (PROFILEMODE .EQ. 7) THEN
                  ELONGWEIGHT = ELONG_GAP_1(II-1)
               ELSE IF (PROFILEMODE .EQ. 8) THEN
                  ELONGWEIGHT = ELONG_GAP_2(J)
	       ELSE IF (PROFILEMODE .GE. 3) THEN
                  ELONGWEIGHT=(ELONG_GAP_1(II-1) +ELONG_GAP_2(J)) * 0.5
	       ENDIF
	       W = W  + ELONGWEIGHT
	    ENDDO
	    CVAL = CVAL  -  W 
C store insertions of seq2:
C iins:             insertion counter
C inslen:           length of insertion
C insbeg_1:         DSSP position of insertion (last matched residue)
C insbeg_1:         position of the insertion in the alignend sequence
C inspointer_local: pointer in the one-dim array for insertions
C *aVGHYTREe:       * is divider between different insertions
C                   lower case characters are the residues before and 
C                   after the insertions
	    IF (IINS+1 .LT. MAXINS) THEN
               IINS=IINS+1
               INSLEN_LOCAL(IINS)=LDEL
               INSBEG_1_LOCAL(IINS)=II-1
               INSBEG_2_LOCAL(IINS)=JJ-LDEL
               K=INSPOINTER_LOCAL
               IF (K+LDEL+3 .GT. LEN_INSSEQ) THEN
                  WRITE(6,*)' ERROR: MAXINSBUFFER_LOCAL OVERFLOW: '
                  WRITE(6,*)' increase: ',len_insseq
                  STOP
               ENDIF
               INSSEQ(K:K)='*'
               INSSEQ(K+1:K+1)=CSQ_2(JJ-LDEL-1:JJ-LDEL-1)
               INSSEQ(K+2:K+LDEL+2)=CSQ_2(JJ-LDEL:JJ-1)
               INSSEQ(K+LDEL+2:K+LDEL+2)=CSQ_2(JJ:JJ)
               
               CALL UPTOLOW(INSSEQ(K+1:K+1),1)
               CALL UPTOLOW(INSSEQ(K+LDEL+2:K+LDEL+2),1)
               INSPOINTER_LOCAL=INSPOINTER_LOCAL+LDEL+3
	    ELSE
               WRITE(6,*)' WARNING: maxins overflow: ',maxins
               WRITE(6,*)' insertion ingnored in HSSP-output'
	    ENDIF
	    DO K=1,LDEL
               M=M+1
               JTRACE(M)= JJ-K      
               ITRACE(M)=II-1
               LAL_1(M) = INDELMARK 
               LAL_2(M) = LSQ_2 (JJ-K)
               LSAL_1(M)= INDELMARK 
               LSAL_2(M)= LSTRCLASS_2(JJ-K)
               ITEMP_NO1(M)=0 
               ITEMP_NO2(M)=PDBNO_2(JJ-K)
               CTEMP_CHAIN1(M)=' ' 
               CTEMP_CHAIN2(M)=CHAINID_2(JJ-K)
	    ENDDO
	    JJ=JJ-LDEL
	    GOTO 100   
c=======================================================================
C                     unmatched terminal sequence
C=======================================================================
Caution if you change this: decrease/increase ISTART/ISTOP in SETPIECES 
CP unnecessary complication 
CP    do not add <
CP    do not have length+1
CP    do not replot last point 
C ENDMARK is '<')
C=======================================================================
         ELSE IF (LDEL_DIREC .EQ. 0 ) THEN
	    M=M+1
	    LAL_1(M) =ENDMARK 
            LAL_2(M) =ENDMARK
	    LSAL_1(M)=ENDMARK 
            LSAL_2(M)=ENDMARK
	    ITEMP_NO1(M)=0 
            ITEMP_NO2(M)=0
c	    replot last point
	    ITRACE(M)=ITRACE(M-1) 
            JTRACE(M)=JTRACE(M-1)
         ELSE
	    WRITE(6,*)' FATAL ERROR IN TRACE'
	    WRITE(6,*)' LDEL_DIREC NOT KNOWN',LDEL_DIREC,ii,jj
	    STOP
         ENDIF
      ENDIF
c=======================================================================
c end of trace back
c=======================================================================
      CVAL    = CVAL
      CMAXVAL = CMAXVAL
C=======================================================================
C aligned optimum subsequences of length M are in integer array 
C LAL_1(I) and LAL_2(J)

C convert back to characters
      CALL INT_TO_SEQ(LAL_1,AL_1_ARRAY,M,TRANS,INDELMARK,ENDMARK)
      CALL INT_TO_SEQ(LAL_2,AL_2_ARRAY,M,TRANS,INDELMARK,ENDMARK)
      CALL INT_TO_STRCLASS(MAXSTRSTATES,MAXALSQ,M,LSAL_1,
     +     STR_CLASSES,INDELMARK,ENDMARK,SAL_1_ARRAY)
      CALL INT_TO_STRCLASS(MAXSTRSTATES,MAXALSQ,M,LSAL_2,
     +     STR_CLASSES,INDELMARK,ENDMARK,SAL_2_ARRAY)
C process alignments
C for terminal '<' M=LEM+1
      IF (LAL_1(M) .EQ. ENDMARK) THEN
         LEM=M-1
      ELSE
         LEM=M
      ENDIF
      IFIR=ITRACE(LEM) 
      JFIR=JTRACE(LEM)
      CALL CHECKRANGE(LEM,1,MAXALSQ,'alilen LEM','TRACE')
C=======================================================================
C                 evaluate the alignments.
C=======================================================================
      IDAL=0 
      IDSAL=0 
      IDELETION=0 
      NDEL=0
c count number of deletions/insertions
c only if there is a '.' and the next character is no '.'
      DO K=1,M
         IF (K .LT. M) THEN
	    IF (LAL_1(K) .EQ. INDELMARK) THEN 
               IDELETION=IDELETION+1
               IF (LAL_1(K+1) .NE. INDELMARK ) THEN 
                  NDEL=NDEL+1 
               ENDIF
	    ENDIF
	    IF (LAL_2(K) .EQ. INDELMARK) THEN 
               IDELETION=IDELETION+1
               IF (LAL_2(K+1) .NE. INDELMARK) THEN 
                  NDEL=NDEL+1 
               ENDIF
	    ENDIF
         ENDIF
         IF (LAL_1(K) .EQ. LAL_2(K) .AND. LAL_1(K) .NE. ENDMARK) THEN
	    IDAL=IDAL+1 
            AL_AGREE(K)= '*'
         ELSE
            AL_AGREE(K)= ' '
         ENDIF
C translate to three states H,E,L
         IF (LDSSP_1 .AND. LDSSP_2 ) THEN
	    CALL STRUC_CLASS(MAXSTRSTATES,STR_CLASSES,
     +           SAL_1_ARRAY(K),SK_1,ICLASS)
	    CALL STRUC_CLASS(MAXSTRSTATES,STR_CLASSES,
     +           SAL_2_ARRAY(K),SK_2,ICLASS)
	    IF (SK_1 .EQ. SK_2 ) THEN
               IDSAL=IDSAL+1 
               SAL_AGREE(K)='+' 
	    ELSE
               SAL_AGREE(K)=' ' 
	    ENDIF
         ENDIF
      ENDDO
C=======================================================================
C LEN1  : is ILAS-IFIR+1
C LENOCC: is occupied postions (no INSDEL, used in HSSP)      
C LEM   : length in SEQuence 1 including gaps
C HOM   : is identical postion / LENOCC
C=======================================================================
      LEN1=ILAS-IFIR+1
      LENOCC=0		
      DO I=1,ILAS-IFIR+1
         IF (LAL_2(I) .NE. INDELMARK )LENOCC=LENOCC+1
      ENDDO
      PER=VALUE/LENOCC
cx	per=value/lem
      HOM=FLOAT(IDAL)/FLOAT(LENOCC)
      IF (CMAXVAL .GT. -0.00001 .AND. CMAXVAL .LT. 0.00001) THEN
         SIM=0.0
      ELSE
         SIM=(CVAL/CMAXVAL)
      ENDIF
c	WRITE(6,*)'trace ',cval,cmaxval
C=======================================================================
C     test if threshold criterion is fulfilled (if specified)
C=======================================================================
      LCONSIDER=.TRUE.	
      IF (LTHRESHOLD .OR. LALL) THEN	
         CALL CHECKHSSPCUT(LENOCC,HOM*100.0,ISOLEN,ISOIDE,NSTEP,
     +        LFORMULA,LALL,ISAFE,LCONSIDER,DISTANCE)
      ENDIF
      IF (CUTVALUE1 .GT. 0.0) THEN
         IF (VALUE .LT. (CMAXVAL/CUTVALUE1) ) LCONSIDER=.FALSE.
      ENDIF
      IF (CUTVALUE2 .GT. 0.0) THEN
         IF (VALUE .LT. CUTVALUE2 ) LCONSIDER=.FALSE.
      ENDIF
C     BR 99.09: write out debug
      IF (LDBG_LOCAL) THEN
         IF (LCONSIDER) THEN
            WRITE(6,'(A,I5,A)')' trace: nprot=',IALIGN+1,' take!'
         ELSE 
            WRITE(6,'(A,I5,A)')' trace: nprot=',IALIGN+1,' reject!'
         ENDIF
      END IF
      
C=======================================================================
C     compare 3D-structures of alignend fragments
C=======================================================================
      LCALPHA=.TRUE.
      RMS=-1.0
      IF (LCOMPSTR .AND. LCONSIDER) THEN
         IF (LDSSP_1 .AND. LDSSP_2 ) THEN
            CALL GETPIDCODE(NAME_1,PID_1)
            CALL FINDBRKFILE(BRKFILE_1,PDBPATH,PID_1,KBRK,KLOG,LERROR)
            IF (.NOT.LERROR) THEN
               CALL GETPIDCODE(NAME_2,PID_2)
	       CALL FINDBRKFILE(BRKFILE_2,PDBPATH,PID_2,KBRK,KLOG,
     +              LERROR)
               IF (.NOT.LERROR) THEN
                  I=1
                  DO K=M,1,-1
                     ALI_1(I)=AL_1_ARRAY(K)
                     ALI_2(I)=AL_2_ARRAY(K)
                     I=I+1
                  ENDDO
                  CALL ALITOSTRUCRMS(MAXALSQ,MAXSQ,BRKFILE_1,BRKFILE_2,
     +                 KBRK,PDBNO_1,CHAINID_1,PDBNO_2,CHAINID_2,
     +	               ALI_1,ALI_2,M,IFIR,ILAS,JFIR,
     +                 JLAS,LCALPHA,RMS)
               ENDIF
            ENDIF
         ENDIF
      ENDIF
C===================================================================
C PRINT ALIGNED SEQS AND HOMOLGY VALUES..
C===================================================================
c	  if (ntest.eq.1) then
c	    WRITE(6,*)'No   IFIR ILAS JFIR JLAS NPOS NDEL   '//
c     +                     'VAL   VPER NIDE  IDE  SIM   RMS DIST'
c	  endif
c	  WRITE(6,1016)ntest,ifir,ilas,jfir,jlas,lenocc,ideletion,
c     +                 value,per,idal,hom,sim,rms,distance
c1016      format(I4,2(1X,I4,'-',I4),2(I5),F7.2,F6.2,I5,1X,3(F6.1),F6.2)
C=======================================================================
C check value from setmatrix and recalculated value from trace back
C=======================================================================
      LERROR=.FALSE.
      MAXDEVIATION=0.3
      IF (ABS(CVAL-VALUE) .GT. MAXDEVIATION) LERROR=.TRUE.
      IF (LERROR) THEN
         WRITE(6,*)' *** FATAL ERROR IN TRACE ****'
         WRITE(6,*)' CVAL .NE. VALUE : ',CVAL,VALUE
         WRITE(6,*)' WRITE MATRIX AND TRACE BACK IN ??_MATRIX.ERROR'
c$$$          call getpidcode(name_1,pid_1)
c$$$	  call concat_strings(pid_1,'_MATRIX.ERROR',errorfile)
c$$$	  call open_file(99,errorfile,'NEW,RECL=2000',lerror)
c$$$	  write(99,'(a,f12.5)')' CVAL              : ',CVAL
c$$$	  write(99,'(a,f12.5)')' VALUE             : ',VALUE
c$$$C debug: output the LH (values and trace-back)matrix 
c$$$	  write(99,*) 'H-MATRIX Hij'
c$$$	  write(99,*)'Index i runs for Sequence 1'
c$$$	  write(99,*)'Index j runs for Sequence 2'
c$$$	  do i=2,nd1
c$$$	     write(99,'(i6)')i-1
c$$$	     write(99,'(2x,20(f7.1))')(lh1(i,j),j=2,nd2)
c$$$	  enddo
c$$$	  write(99,*) ; write(99,*)'TRACE-BACK MATRIX' 
c$$$	  do i=2,nd1
c$$$	     write(99,'(i6)')i-1
c$$$	     write(99,'(2x,20(f7.1))')(lh2(i,j),j=2,nd2)
c$$$	  enddo
c$$$	  close(99)
         STOP
      ENDIF

      IF (IALIGN+1 .GT. MAXALIGNS) THEN
         WRITE(6,*)'*** OVERFLOW, ALIGNMENTS TERMINATED ***'
         LALIOVERFLOW=.TRUE.
         RETURN
      ENDIF
      IALIGN=IALIGN+1
c alignments will be sorted according to this value 
      IF (CSORTMODE .EQ. 'DISTANCE' ) THEN	
         ALISORTKEY(IALIGN)=DISTANCE
      ELSE IF (CSORTMODE.EQ.'VALUE' .OR. CSORTMODE .EQ. 'ZSCORE') THEN
         ALISORTKEY(IALIGN)=VALUE
      ELSE IF (CSORTMODE .EQ. 'WSIM' ) THEN
         ALISORTKEY(IALIGN)=SIM
      ELSE IF (CSORTMODE .EQ. 'SIM' ) THEN
         ALISORTKEY(IALIGN)=SIM
      ELSE IF (CSORTMODE .EQ. 'SIGMA' ) THEN
         ALISORTKEY(IALIGN)=VALUE/SDEV
      ELSE IF (CSORTMODE .EQ. 'IDENTITY' ) THEN
         ALISORTKEY(IALIGN)=HOM
      ELSE IF (CSORTMODE .EQ. 'VALPER' ) THEN
         ALISORTKEY(IALIGN)=PER
      ELSE IF (CSORTMODE .EQ. 'VALFORM' ) THEN
         ALISORTKEY(IALIGN)=VALUE*(LENOCC**(-0.56158))
      ELSE IF (CSORTMODE .EQ. 'NO' ) THEN
         ALISORTKEY(IALIGN)=FLOAT(MAXALIGNS - IALIGN)
      ENDIF
C======================================================================
C     STORE ALIGNMENTS IN FILE
C======================================================================
      IFILEPOI(IALIGN)=-999
      IRECPOI(IALIGN)=-999
      IF (LCONSIDER) THEN
         IFILEPOI(IALIGN)=ISET
         NRECORD=NRECORD+1
         IRECPOI(IALIGN)=NRECORD
         IALIGN_GOOD=IALIGN_GOOD+1
         WRITE(KCORE,REC=NRECORD)'*',LCONSIDER,VALUE

C======================================================================
C WRITE AL_2_ARRAY(.) AND SAL_2_ARRAY(.)
C mark insertions in SEQuence 1 by lower case letters in AL_2_ARRAY(*)
         DO K=M-1,2,-1
            IF (LAL_1(K) .EQ. INDELMARK) THEN
               IF (LAL_1(K-1) .NE. INDELMARK) THEN
                  CALL UPTOLOW(AL_2_ARRAY(K-1),1)
               ENDIF
               IF (LAL_1(K+1) .NE. INDELMARK) THEN
                  CALL UPTOLOW(AL_2_ARRAY(K+1),1)
               ENDIF
            ENDIF
         ENDDO
         IPOS=1 
         DO I=M,1,-1
            IF ( (LAL_1(I) .NE. INDELMARK) .AND. 
     +           (LAL_1(I) .NE. ENDMARK) ) THEN 
               LINE(2)(IPOS:IPOS)=AL_2_ARRAY(I)
               IF (LDSSP_2) THEN
                  LINE(3)(IPOS:IPOS)=SAL_2_ARRAY(I)  
                  WRITE(LINE(4)(IPOS:IPOS),'(I1)')LACC_2(I)  
               ENDIF
               IPOS=IPOS+1
            ENDIF
         ENDDO
C======================================================================

         NRECORD=NRECORD+1
         WRITE(KCORE,REC=NRECORD)NAME_2
         NRECORD=NRECORD+1
         WRITE(KCORE,REC=NRECORD)COMPND_2
         NRECORD=NRECORD+1
         WRITE(KCORE,REC=NRECORD)ACCESSION_2,PDBREF_2,LDSSP_2    
         NRECORD=NRECORD+1
         WRITE(KCORE,REC=NRECORD)IFIR,LEN1,LENOCC,JFIR,JLAS,
     +        N2IN,IDELETION,NDEL,NSHIFTED,RMS,HOM,
     +        SIM,SDEV,DISTANCE,IINS
C store alignment
         IF (MOD(FLOAT(LEN1),FLOAT(MAXRECORDLEN)).EQ. 0.0) THEN
            NLINE= LEN1/MAXRECORDLEN
         ELSE
            NLINE=(LEN1/MAXRECORDLEN ) +1
         ENDIF
         IBEG=1 
         IEND=MAXRECORDLEN
         DO  I=1,NLINE
            NRECORD=NRECORD+1
            WRITE(KCORE,REC=NRECORD)LINE(2)(IBEG:IEND)
            IF (LDSSP_2) THEN
               NRECORD=NRECORD+1
               WRITE(KCORE,REC=NRECORD)LINE(3)(IBEG:IEND)
               NRECORD=NRECORD+1
               WRITE(KCORE,REC=NRECORD)LINE(4)(IBEG:IEND)
            ENDIF
            IBEG=IEND+1 
            IEND=IEND+MAXRECORDLEN
         ENDDO
C store insertions
         IF (IINS .GT. 0) THEN
            DO I=1,IINS
               NRECORD=NRECORD+1
               WRITE(KCORE,REC=NRECORD)INSLEN_LOCAL(I),
     +              INSBEG_1_LOCAL(I),INSBEG_2_LOCAL(I)
            ENDDO
            IF (MOD(FLOAT(INSPOINTER_LOCAL),FLOAT(MAXRECORDLEN)) .EQ.
     +           0.0) THEN
               NLINE= INSPOINTER_LOCAL/MAXRECORDLEN
            ELSE
               NLINE=(INSPOINTER_LOCAL/MAXRECORDLEN ) +1
            ENDIF
            IBEG=1 
            IEND=MAXRECORDLEN
            DO  I=1,NLINE
               NRECORD=NRECORD+1
               WRITE(KCORE,REC=NRECORD)INSSEQ(IBEG:IEND)
               IBEG=IEND+1 
               IEND=IEND+MAXRECORDLEN
            ENDDO
         ENDIF
C=====================================================================
C unmark insertions in SEQuence 1 by lower case letters in AL_2_ARRAY(*)
c=====================================================================
         DO I=1,M 
            CALL LOWTOUP(AL_2_ARRAY(I),1) 
         ENDDO
C=====================================================================
C write long output file
C=====================================================================
         IF (LONG_OUT) THEN
            WRITE(KLONG,*)' No   IFIR ILAS JFIR JLAS NPOS NDEL   '//
     +           'VAL   VPER NIDE   IDE   SIM   RMS   '//
     +           'DIST  ACCESSION    NAME'
            WRITE(KLONG,1017)NTEST,IFIR,ILAS,JFIR,JLAS,LENOCC,
     +           IDELETION,VALUE,PER,IDAL,HOM,SIM,RMS,DISTANCE,
     +           ACCESSION_2,NAME_2(1:50)
            
 1017       FORMAT(I4,2(1X,I4,'-',I4),2(I5),2(F7.2),I5,1X,4(F6.2),A,A)
            
            JPOS=M 
            ISTART=1
            CTEMP=' ' 
            J=ISTART 
            DO K=JPOS,1,-1 
               WRITE(CTEMP(J:J),'(A)')AL_AGREE(K) 
               J=J+1
            ENDDO
            WRITE(KLONG,'(A)')CTEMP(1:J)
            CTEMP=' ' 
            J=ISTART 
            DO K=JPOS,1,-1 
               WRITE(CTEMP(J:J),'(A)')AL_1_ARRAY(K) 
               J=J+1
            ENDDO
            WRITE(KLONG,'(A)')CTEMP(1:J) 
            IF (SAL_1_ARRAY(1) .NE. 'U') THEN 
               CTEMP=' ' 
               J=ISTART
               DO K=JPOS,1,-1 
                  WRITE(CTEMP(J:J),'(A)')SAL_1_ARRAY(K) 
                  J=J+1
               ENDDO
               WRITE(KLONG,'(A)')CTEMP(1:J)
            ENDIF
            CTEMP=' ' 
            J=ISTART 
            DO K=JPOS,1,-1 
               WRITE(CTEMP(J:J),'(A)')AL_2_ARRAY(K) 
               J=J+1
            ENDDO
            WRITE(KLONG,'(A)')CTEMP(1:J)
            IF (SAL_2_ARRAY(1).NE.'U') THEN 
               CTEMP=' ' 
               J=ISTART
               DO K=JPOS,1,-1 
                  WRITE(CTEMP(J:J),'(A)')SAL_2_ARRAY(K) 
                  J=J+1
               ENDDO
               WRITE(KLONG,'(A)')CTEMP(1:J)
               CTEMP=' ' 
               J=ISTART 
               DO K=JPOS,1,-1 
                  WRITE(CTEMP(J:J),'(A)')SAL_AGREE(K) 
                  J=J+1
               ENDDO
               WRITE(KLONG,'(A)')CTEMP(1:J)
            ENDIF
            WRITE(KLONG,*)' '
            J=ISTART
            DO K=JPOS,1,-1
               WRITE(KLONG,'(I6,A,2X,I6,A)')
     +              ITEMP_NO1(K),CTEMP_CHAIN1(K),
     +              ITEMP_NO2(K),CTEMP_CHAIN2(K)
C     J=J+1
            ENDDO

c              jpos=m ; ipos=m-100+1 ; linelen=100 ; iblocklen=11
c              istart=1
c              do while( jpos .ge. 1)
c	         ipos=max(ipos,1) ; ctemp=' ' ; j=istart 
c	         do k=jpos,ipos,-1 ; if (mod(j,iblocklen) .eq. 0)j=j+1
c                    write(ctemp(j:j),'(a)')al_agree(k) ; j=j+1
c	         ENDDO; write(klong,'(a)')ctemp(1:j)
c	         ctemp=' ' ; j=istart 
c	         do k=jpos,ipos,-1 ; if (mod(j,iblocklen) .eq. 0)j=j+1
c                    write(ctemp(j:j),'(a)')al_1_array(k) ; j=j+1
c	         ENDDO; write(klong,'(a)')ctemp(1:j) 
c                 if (sal_1_array(1) .ne. 'U') then ; ctemp=' ';j=istart
c	           do k=jpos,ipos,-1 ; if (mod(j,iblocklen) .eq. 0)j=j+1
c                      write(ctemp(j:j),'(a)')sal_1_array(k) ; j=j+1
c	           ENDDO; write(klong,'(a)')ctemp(1:j)
c                 endif
c	         ctemp=' ' ; j=istart 
c	         do k=jpos,ipos,-1 ; if (mod(j,iblocklen) .eq. 0)j=j+1
c                    write(ctemp(j:j),'(a)')al_2_array(k) ; j=j+1
c	         ENDDO; write(klong,'(a)')ctemp(1:j)
c                 if (sal_2_array(1).ne.'U') then ; ctemp=' ' ; j=istart
c	           do k=jpos,ipos,-1 ; if (mod(j,iblocklen).eq.0)j=j+1
c                      write(ctemp(j:j),'(a)')sal_2_array(k) ; j=j+1
c	           ENDDO; write(klong,'(a)')ctemp(1:j)
c	           ctemp=' ' ; j=istart 
c	           do k=jpos,ipos,-1 ; if (mod(j,iblocklen) .eq. 0)j=j+1
c                      write(ctemp(j:j),'(a)')sal_agree(k) ; j=j+1
c	           ENDDO; write(klong,'(a)')ctemp(1:j)
c                 endif
c                 write(klong,*)' '
c                 jpos=jpos-linelen ; ipos=ipos-linelen
c	      enddo
         ENDIF
C=====================================================================
C output to PLOT file TRACE.X
C=====================================================================
         IF (LTRACEOUT) THEN
            CALL OPEN_FILE(KPLOT,PLOTFILE,'UNKNOWN,APPEND',LERROR)
            CALL PUTHEADER(KPLOT,CSQ_1,CSQ_2,STRUC_1,STRUC_2,ND1-1,
     +           ND2-1,NAME_1,NAME_2)
            WRITE(KPLOT,'(1X,I3,A)')NTEST,' TRACE'
C if lall linethickness is value/residue; else its the distance from the
C chosen threshold
            IF (LALL) THEN 
               LINETHICK=NINT(PER)
            ELSE         
               LINETHICK=NINT(DISTANCE)
            ENDIF
            WRITE(KPLOT,'(3(I4))')ITRACE(1),JTRACE(1),LINETHICK
C output only straight line end points 
C so, plot beginning, end, and kink points
C kink if there is a discontinuity in either I or J increments
            DO K=2,M-1
               LKINK=ABS(ITRACE(K)-ITRACE(K+1)) .NE. 
     +              ABS(ITRACE(K)-ITRACE(K-1)) .OR.
     +              ABS(JTRACE(K)-JTRACE(K+1)) .NE. 
     +              ABS(JTRACE(K)-JTRACE(K-1))
               IF (LKINK) THEN
                  WRITE(KPLOT,'(3(I4))')ITRACE(K),JTRACE(K),LINETHICK
               ENDIF
            ENDDO
            WRITE(KPLOT,'(3(I4))')ITRACE(M),JTRACE(M),LINETHICK
C DEFINES END OF TRACE IN TRACE-HOMOLOGY
            ITRACE(M+1)=0 
            JTRACE(M+1)=0
            WRITE(KPLOT,'(3(I4))')ITRACE(M+1),JTRACE(M+1),LINETHICK
            CLOSE(KPLOT)
         ENDIF
      ENDIF
C     end if lconsider
C=======================================================================
      RETURN 
      END
C     END TRACE
C......................................................................

C......................................................................
C     SUB WRITE_ALB
      SUBROUTINE WRITE_ALB(KOUT,OUTFILE,SEQ,NBLOCKS,HEADERLINE,
     1     NAMELABEL,SEQSTART,SEQSTOP,CHBPOS,NBREAKS,ERROR)
      
      IMPLICIT NONE
C     IMPORT
      INTEGER KOUT
      INTEGER NBLOCKS
      INTEGER SEQSTART,SEQSTOP
      INTEGER NBREAKS,CHBPOS(*)
      CHARACTER*(*) SEQ
      CHARACTER*(*) HEADERLINE,NAMELABEL,OUTFILE
C     EXPORT
C     ( OUTPUT TO UNIT KOUT )
      LOGICAL ERROR
C     INTERNAL
      INTEGER         BLOCKSIZE
      PARAMETER      (BLOCKSIZE=                10)
      INTEGER ISTART, ISTOP, FIRSTPOS, LASTPOS, ISEQPOS
      INTEGER BEGIN, END, LENGTH, ICHAIN
      CHARACTER*(250) OUTLINE, ALBHEADLINE
      LOGICAL NOCHAINBREAKS
		
      ERROR = .FALSE.
	
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KOUT,OUTFILE,'new,recl=250',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN
      
      NOCHAINBREAKS = .TRUE.
      LENGTH = SEQSTOP-SEQSTART+1
		
C     make up standard alb headerline
C 1GD1                                                             ....
C 1336
C          ^   length in col 200
      WRITE(ALBHEADLINE,'(I4)') LENGTH - NBREAKS
      CALL RIGHTADJUST(ALBHEADLINE(1:200),1,200)
      CALL STRPOS(NAMELABEL,ISTART,ISTOP)
      ALBHEADLINE(1:ISTOP-ISTART+2) = ' ' // 
     1     NAMELABEL(MAX(ISTART,1):MAX(1,ISTOP))
C     WRITE SEQUENCE
      ISEQPOS = 0
      DO ICHAIN = 1,NBREAKS+1
         IF ( ICHAIN .EQ. 1 ) THEN
            FIRSTPOS = SEQSTART
         ELSE
            FIRSTPOS = CHBPOS(ICHAIN-1) + 1 
            WRITE(KOUT,'(A)') '='
         ENDIF
         IF ( ICHAIN .EQ. NBREAKS+1 ) THEN
            LASTPOS = SEQSTOP 
         ELSE
            LASTPOS = CHBPOS(ICHAIN) - 1 
         ENDIF
         CALL STRPOS(ALBHEADLINE,ISTART,ISTOP)
         WRITE(KOUT,'(A)') ALBHEADLINE(1:MAX(1,ISTOP))
         WRITE(OUTLINE,'(2I4)') LASTPOS-FIRSTPOS+1, ISEQPOS
         CALL STRPOS(OUTLINE,ISTART,ISTOP)
         WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
C     BEGIN = FIRSTPOS
         BEGIN = SEQSTART
C     "REPEAT UNTIL"
 1       CONTINUE
C     WRITESEQLINE RETURNS END
         CALL WRITESEQLINE(SEQ,BEGIN,BLOCKSIZE,NBLOCKS,SEQSTOP,
     1        NOCHAINBREAKS,OUTLINE,END,ERROR)
C     CALL WRITESEQLINE(SEQ,BEGIN,BLOCKSIZE,NBLOCKS,LASTPOS,
C     1                       NOCHAINBREAKS,OUTLINE,END,ERROR)
         IF ( ERROR ) STOP
         CALL STRPOS(OUTLINE,ISTART,ISTOP)
         WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
         BEGIN = END + 1
C     IF ( BEGIN .LE. LASTPOS )  GOTO 1
         IF ( BEGIN .LE. SEQSTOP )  GOTO 1
C     END "REPEAT UNTIL"
         
         CALL STRPOS(HEADERLINE,ISTART,ISTOP)
         WRITE(KOUT,'(A,A)') ' ',HEADERLINE(1:MAX(1,ISTOP))
         WRITE(KOUT,'(A)') '='
         ISEQPOS = ISEQPOS + LASTPOS-FIRSTPOS+1
      ENDDO
      
      CLOSE(KOUT)
      
      RETURN
      END   
C     END WRITE_ALB
C......................................................................

C......................................................................
C     SUB WRITE_EMBL
      SUBROUTINE WRITE_EMBL(KOUT,SEQ,NBLOCKS,INFILE,OUTFILE,
     1     HEADERLINE,SEQSTART,SEQSTOP,ERROR)
      
      IMPLICIT NONE
C     IMPORT
      INTEGER KOUT
      INTEGER NBLOCKS
      INTEGER SEQSTART,SEQSTOP
      CHARACTER*(*) SEQ
      CHARACTER*(*) HEADERLINE,INFILE,OUTFILE
C     EXPORT
C     ( OUTPUT TO UNIT KOUT )
      LOGICAL ERROR
C     INTERNAL
      INTEGER BLOCKSIZE
      PARAMETER      (BLOCKSIZE=                10)
      INTEGER ISTART, ISTOP
      INTEGER BEGIN, END, LENGTH
      CHARACTER*(250) OUTLINE
      LOGICAL NOCHAINBREAKS
*----------------------------------------------------------------------*
		
      ERROR = .FALSE.
	
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KOUT,OUTFILE,'new',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN
      
      NOCHAINBREAKS = .FALSE.
      LENGTH = SEQSTOP-SEQSTART+1
      
      OUTLINE = 'ID X'
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(MAX(ISTART,1):MAX(1,ISTOP))
C     BEGIN AND END
      CALL STRPOS(INFILE,ISTART,ISTOP)
      WRITE(OUTLINE,'(A,A,1X,A,I4,1X,A,I4)') 
     1     'DE ',infile(max(istart,1):max(1,istop)),'from: ',
     2     seqstart,'to: ',seqstop
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(MAX(ISTART,1):MAX(1,ISTOP))

C     copy passed headerline ( mark it with "DE" - not necessary (?))
      CALL STRPOS(HEADERLINE,ISTART,ISTOP)
      OUTLINE = 'DE ' // HEADERLINE(1:MAX(1,ISTOP)) 
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(MAX(ISTART,1):MAX(1,ISTOP))
C     make up standard embl headerline
C     SQ   SEQUENCE   344 AA;
      write(outline,'(a,i6,a)') 'SQ   SEQUENCE',length,' AA;' 
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))

C     write sequence
      BEGIN = SEQSTART
C     "repeat until"
 1    CONTINUE
C     writeseqline returns end
      CALL WRITESEQLINE(SEQ,BEGIN,BLOCKSIZE,NBLOCKS,SEQSTOP,
     1     NOCHAINBREAKS,OUTLINE,END,ERROR)
      IF ( ERROR ) STOP
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
      BEGIN = END + 1
      IF ( BEGIN .LE. SEQSTOP )  GOTO 1
C     end "repeat until"
        
C     standard end marker
      WRITE(KOUT,'(A)') '//'

      CLOSE(KOUT)

      RETURN
      END   
C     END WRITE_EMBL
C......................................................................

C......................................................................
C     SUB WRITE_GCG
      SUBROUTINE WRITE_GCG(KOUT,SEQ,NBLOCKS,NBREAKS,INFILE,OUTFILE,
     1     HEADERLINE,SEQSTART,SEQSTOP,ERROR)
	
      IMPLICIT NONE
C     IMPORT
      INTEGER KOUT
      INTEGER NBLOCKS, NBREAKS
      INTEGER SEQSTART,SEQSTOP
      CHARACTER*(*) SEQ
      CHARACTER*(*) HEADERLINE,INFILE, OUTFILE
C     EXPORT
C     ( OUTPUT TO UNIT KOUT )
      LOGICAL ERROR
C     INTERNAL
      INTEGER BLOCKSIZE
      PARAMETER      (BLOCKSIZE=                10)
      INTEGER ISTART, ISTOP
      INTEGER BEGIN, END
      INTEGER CHECK, LENGTH
      CHARACTER*8 CTMP
      CHARACTER*9 DATESTRING
      CHARACTER*(250) OUTLINE, SEQLINE
      LOGICAL NOCHAINBREAKS
		
      ERROR = .FALSE.
	
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KOUT,OUTFILE,'new',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN
      
      NOCHAINBREAKS = .TRUE.
      LENGTH = SEQSTOP-SEQSTART+1
      
C     BEGIN AND END
      CALL STRPOS(INFILE,ISTART,ISTOP)
      WRITE(OUTLINE,'(1X,A,1X,A,I4,1X,A,I4)') 
     1     infile(max(istart,1):max(1,istop)),'from: ',
     2     seqstart,'to: ',seqstop
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(MAX(ISTART,1):MAX(1,ISTOP))
      WRITE(KOUT,'(A)') ' '
C     COPY PASSED HEADERLINE
      CALL STRPOS(HEADERLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') HEADERLINE(1:MAX(ISTOP,1))
C     MAKE UP STANDARD GCG HEADERLINE
      CALL STRPOS(OUTFILE,ISTART,ISTOP)
      CALL GETDATE(DATESTRING)
      CALL CHECKSEQ(SEQ,SEQSTART,SEQSTOP,CHECK)
      WRITE(OUTLINE,'(1X,A,10X,A,I5,3X,A,2X,A,I5,1X,A)')
     1     outfile(max(istart,1):max(1,istop)),'Length:',
     2     length-nbreaks,datestring,'Check:',check,'..'
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(ISTOP,1))
      WRITE(KOUT,'(A)') ' '
      
C     write sequence

C       1   RPDFCLEPPY TGPCKARIIR YFYNAKAGLC QTFVYGGCRA KRNNFKSAED

      BEGIN = SEQSTART
C     "repeat until"
 1    CONTINUE
      WRITE(CTMP,'(I8)') BEGIN-SEQSTART+1
C     writeseqline returns end
      CALL WRITESEQLINE(SEQ,BEGIN,BLOCKSIZE,NBLOCKS,SEQSTOP,
     1     NOCHAINBREAKS,SEQLINE,END,ERROR)
      IF ( ERROR ) STOP
      CALL STRPOS(SEQLINE,ISTART,ISTOP)
C     gcg sequence lines are preceeded by a number (first pos. of line )
      OUTLINE = CTMP // '  ' //  
     1     SEQLINE(MAX(ISTART,1):MAX(ISTOP,1))
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(ISTOP,1))
      WRITE(KOUT,'(A)') ' '
      BEGIN = END + 1
      IF ( BEGIN .LE. SEQSTOP )  GOTO 1
C     END "REPEAT UNTIL"
      
      CLOSE(KOUT)
      
      RETURN
      END
C     END WRITE_GCG
C......................................................................

C......................................................................
C     SUB WRITE_HSSP
      SUBROUTINE WRITE_HSSP(KOUT,MAXRES,NALIGN,NGLOBALHITS,NRES,EMBLID,
     +     STRID,ACCESSION,IDE,SIM,IFIR,ILAS,JFIR,JLAS,
     +     LALI,NGAP,LGAP,LENSEQ,PROTNAME,ALIPOINTER,
     +     ALISEQ,PDBNO,CHAINID,PDBSEQ,SECSTR,COLS,
     +     BP1,BP2,SHEETLABEL,ACC,NOCC,VAR,SEQPROF,
     +     NDEL,NINS,ENTROPY,RELENT,CONSWEIGHT,
     +     INSNUMBER,INSALI,INSPOINTER,INSLEN,
     +     INSBEG_1,INSBEG_2,INSBUFFER,ISOLEN,
     +     ISOIDE,NSTEP,LFORMULA,LALL,ISAFE,
     +     EXCLUDEFLAG,LCONSERV,LHSSP_LONG_ID)

      IMPLICIT        NONE
C---- import
      INTEGER         KOUT,MAXRES,NALIGN,NGLOBALHITS,NRES,
     +                IFIR(*),ILAS(*),JFIR(*),JLAS(*),LALI(*),
     +                NGAP(*),LGAP(*),LENSEQ(*),ALIPOINTER(*),PDBNO(*),
     +                BP1(*),BP2(*),
     +                ACC(*),NOCC(*),VAR(*),SEQPROF(MAXRES,*),NDEL(*),
     +                NINS(*),RELENT(*),
     +                ISOLEN(*),NSTEP,ISAFE,
     +                INSNUMBER,INSALI(*),INSPOINTER(*),
     +                INSLEN(*),INSBEG_1(*),INSBEG_2(*)
      CHARACTER*(*)   EMBLID(*),STRID(*),ACCESSION(*),PROTNAME(*),
     +                ALISEQ(*),
     +                CHAINID(*),PDBSEQ(*),SECSTR(*),
     +                EXCLUDEFLAG(*)
      CHARACTER*7     COLS(*)
      CHARACTER*1     SHEETLABEL(*),INSBUFFER(*)
      REAL            IDE(*),SIM(*),ENTROPY(*),CONSWEIGHT(*),ISOIDE(*)
      LOGICAL         LCONSERV,LFORMULA,LALL,LHSSP_LONG_ID
C---- internal parameter
      INTEGER         NBLOCKSIZE,NBLOCKINS,
     +                MAXAA,MAXALIGNS_LOC
      PARAMETER      (NBLOCKSIZE=               70)
      PARAMETER      (NBLOCKINS=               100)
C     maximal number of symbols
      PARAMETER      (MAXAA=                    20)
C     maximal number of alignments
      PARAMETER      (MAXALIGNS_LOC=         9999)

C---- internal veriable
      INTEGER         NALIGN_FILTER,
     +                I,J,ILEN,LENLINE,K,
     +                NBLOCK,IALIGN,JUMP,ISTART,ISTOP,IRUL,IBLOCK,
     +                LPOS,JPOS,IPOS,
     +                IAL,IBEG,IEND,IINS,
     +                INS_NEW,INS_ORDER(MAXALIGNS_LOC),NRES2
      LOGICAL         LINSERTION,LCONSIDER
      CHARACTER       PROFILESEQ*(MAXAA),
     +                CRULER*(NBLOCKSIZE),
     +                CTEMP*(NBLOCKSIZE),CTEMPINS*(NBLOCKINS),
     +                LINE*512
      REAL            DISTANCE
C---- ------------------------------------------------------------------
C---- 
C---- ------------------------------------------------------------------
C     order of amino acid symbols in the HSSP sequence profile block
      PROFILESEQ='VLIMFWYGAPSTCHRKQEND'

C---- 
C---- check local array dimension
C---- 
C---- limiting alignments considered by NGLOBALHITS
      NALIGN=MIN(NALIGN,NGLOBALHITS)
C-----
      IF (NALIGN .GT. MAXALIGNS_LOC) THEN
         WRITE(6,*)'*** ERROR WRITE_HSSP: MAXALIGNS_LOC overflow'
         WRITE(6,*)'*-> increase dimension !'
         STOP
      ENDIF
C---- 
C---- 99.01 br changed
C---- 
CC C     get number of alignments after filtering
CC       NALIGN_FILTER=0
CC       DO I=1,NALIGN
CC          INS_ORDER(I)=0
CC          CALL CHECKHSSPCUT(LALI(I),IDE(I)*100,ISOLEN,
CC      +        ISOIDE,NSTEP,LFORMULA,LALL,ISAFE,LCONSIDER,DISTANCE)
CC          IF ( LCONSIDER ) THEN
CC             IF ( EXCLUDEFLAG(I) .EQ. ' ') THEN
CC 	       NALIGN_FILTER=NALIGN_FILTER+1
CC 	       INS_ORDER(I)=NALIGN_FILTER
CC             ENDIF
CC          ELSE
CC             EXCLUDEFLAG(I)='*'
CC          ENDIF
CC       ENDDO

C---- 
C---- 99.01 br: new version
C---- 
C     get number of alignments after filtering
      NALIGN_FILTER=0
      DO I=1,NALIGN
         INS_ORDER(I)=0
         IF ( EXCLUDEFLAG(I) .NE. '*') THEN
            NALIGN_FILTER=NALIGN_FILTER+1
            INS_ORDER(I)=NALIGN_FILTER
         ENDIF
      ENDDO
C---- no alignment -> write last line ('//')
      IF (NALIGN_FILTER .EQ. 0) THEN
         WRITE(6,*)'-*- WARNING WRITE_HSSP file empty (no ali found)!'
         WRITE(KOUT,'(A)')'//'
         CLOSE(KOUT)
         RETURN
      ENDIF

C=======================================================================
C     write the PROTEINS-block
C=======================================================================
C## PROTEINS : EMBL/SWISSPROT identifier and alignment statistics
C NR.    ID         STRID  %IDE %WSIM IFIR ILAS JFIR JLAS LALI NGAP LGAP LSEQ2 P
C   1 : IATR$BOVIN         0.43 12345    1   56    1   56   56    0    0  123  A
C1234AAA123456789012AAAAAAX1234512345X1234X1234X1234X1234X1234X1234X1234X1234XX1
C


C NR.    ID                                     STRID  %IDE %WSIM IFIR ILAS JFIR JLAS LALI NGAP LGAP LSEQ2 
C   1 : IATR$BOVIN..............................       0.43 12345    1   56    1   56   56    0    0  123  A
C1234AAA1234567890123456789012345678901234567890AAAAAAX1234512345X1234X1234X1234X1234X1234X1234X1234X1234XX

      WRITE(KOUT,'(A)')'## PROTEINS : EMBL/SWISSPROT identifier '//
     +     'and alignment statistics'

      IF (LCONSERV) THEN
         IF ( LHSSP_LONG_ID ) THEN
	    WRITE(KOUT,'(A)')
     +           '  NR.    ID                           '//
     +           '          STRID   %IDE %WSIM IFIR ILAS'//
     +           ' JFIR JLAS LALI NGAP LGAP LSEQ2 ACCESSION'//
     +           '     PROTEIN'
         ELSE
	    WRITE(KOUT,'(A)')
     +           '  NR.    ID         STRID   %IDE %WSIM'//
     +           ' IFIR ILAS JFIR JLAS LALI NGAP LGAP LSEQ2'//
     +           ' ACCESSION     PROTEIN'
         ENDIF
      ELSE
         IF ( LHSSP_LONG_ID ) THEN
	    WRITE(KOUT,'(A)')
     +           '  NR.    ID                           '//
     +           '          STRID   %IDE  %SIM IFIR ILAS'//
     +           ' JFIR JLAS LALI NGAP LGAP LSEQ2 ACCESSION'//
     +           '     PROTEIN'
         ELSE   
	    WRITE(KOUT,'(A)')
     +           '  NR.    ID         STRID   %IDE  %SIM'//
     +           ' IFIR ILAS JFIR JLAS LALI NGAP LGAP LSEQ2'//
     +           ' ACCESSION     PROTEIN'
         ENDIF
      ENDIF
      J=0
      DO I=1,NALIGN
         IF ( EXCLUDEFLAG(I).EQ.' ') THEN
C     --------------------------------------------------
C     terrible hack br 99-11: shorten too long proteins
            NRES2=LENSEQ(I)
            IF (NRES2.GT.9999) NRES2=9999
C     end of terrible hack
C     --------------------------------------------------

            J=J+1
            IF (LHSSP_LONG_ID ) THEN
               WRITE(LINE,50)J,' : ',EMBLID(I),STRID(I),IDE(I),SIM(I),
     +              IFIR(I),ILAS(I),JFIR(I),JLAS(I),LALI(I),NGAP(I),
     +              LGAP(I),NRES2,ACCESSION(I),PROTNAME(I)(1:41)
	       CALL STRPOS(LINE,ILEN,LENLINE)
	       WRITE(KOUT,'(A)')LINE(1:LENLINE)
            ELSE
               WRITE(LINE,100)J,' : ',EMBLID(I),STRID(I),IDE(I),SIM(I),
     +              IFIR(I),ILAS(I),JFIR(I),JLAS(I),LALI(I),NGAP(I),
     +              LGAP(I),NRES2,ACCESSION(I),PROTNAME(I)(1:41)
	       CALL STRPOS(LINE,ILEN,LENLINE)
	       WRITE(KOUT,'(A)')LINE(1:LENLINE)
            ENDIF
         ENDIF
      ENDDO
 50   FORMAT (1X,I4,A,A40,A6,1X,F5.2,1X,F5.2,8(1X,I4),2X,A10,1X,A)
 100  FORMAT (1X,I4,A,A12,A6,1X,F5.2,1X,F5.2,8(1X,I4),2X,A10,1X,A)
C number of ALIGNMENTS-blocks
      IF (MOD(FLOAT(NALIGN_FILTER),FLOAT(NBLOCKSIZE)).EQ. 0.0) THEN
         NBLOCK=NALIGN_FILTER/NBLOCKSIZE
      ELSE
         NBLOCK=NALIGN_FILTER/NBLOCKSIZE+1
      ENDIF
      IALIGN=0
      JUMP=0
      ISTOP=IALIGN+NBLOCKSIZE
      IF (ISTOP.GT.NALIGN_FILTER) ISTOP=NALIGN_FILTER
      IRUL=1
C=======================================================================
C loop over ALIGNMENTS-blocks
C=======================================================================
      DO IBLOCK=1,NBLOCK
C make ruler
         LPOS=1
         DO K=1,(NBLOCKSIZE/10)
            IF (IRUL.EQ.10) IRUL=0
            WRITE(CRULER(LPOS:LPOS+9),'(A9,I1)')'....:....',IRUL
            LPOS=LPOS+10
            IRUL=IRUL+1
         ENDDO
         WRITE(KOUT,'(2(A,I4))')'## ALIGNMENTS ',
     +        IALIGN+1-JUMP,' - ',ISTOP
         WRITE(KOUT,'(A)')' SeqNo  PDBNo AA STRUCTURE '//
     +        'BP1 BP2  ACC NOCC  VAR  '//cruler
C=======================================================================
C rearange alignment in vertical order 
C=======================================================================
         DO I=1,NRES	
            CTEMP=' '
            JPOS=1
            IPOS=1
            JUMP=0
CCCC parsytec bug
c stupid parsytec has problems here
c	      do while(ipos .le. nblocksize .and. 
C     +                (ialign+jpos) .le. nalign)
            DO WHILE(IPOS .LE. NBLOCKSIZE )
               IF ( (IALIGN+JPOS) .GT. NALIGN) THEN
                  GOTO 10
               ENDIF
               IAL=IALIGN+JPOS
               JPOS=JPOS+1
               IF ( EXCLUDEFLAG(IAL) .EQ. ' ' ) THEN
                  IF (I .GE. IFIR(IAL) .AND. I .LE. ILAS(IAL)) THEN
                     J=ALIPOINTER(IAL)+(I-IFIR(IAL))
                     CTEMP(IPOS:IPOS)=ALISEQ(J) 
                     IPOS=IPOS+1
                  ELSE
                     CTEMP(IPOS:IPOS)=' '
                     IPOS=IPOS+1
                  ENDIF
               ELSE
	          JUMP=JUMP+1
               ENDIF
            ENDDO
 10         LINE=' '
C=======================================================================
C write ALIGNMENTS-block
C=======================================================================
            WRITE(LINE,200)I,PDBNO(I),CHAINID(I),PDBSEQ(I),SECSTR(I),
     +           COLS(I),BP1(I),BP2(I),SHEETLABEL(I),ACC(I),
     +           NOCC(I),VAR(I),CTEMP
            IF (PDBNO(I).EQ.0) LINE(7:11)=' '
            CALL STRPOS(LINE,IBEG,IEND)
            WRITE(KOUT,'(A)')LINE(1:IEND)
         ENDDO
         IALIGN=IALIGN+NBLOCKSIZE+JUMP
         ISTOP=IALIGN+NBLOCKSIZE
         IF (ISTOP.GT.NALIGN_FILTER) ISTOP=NALIGN_FILTER
         IF (IBLOCK.EQ.NBLOCK) THEN
            WRITE(KOUT,'(A)')'## SEQUENCE PROFILE AND ENTROPY'
            WRITE(KOUT,'(1X,A,20(3X,A1),A,A,A,A,A,A)')'SeqNo PDBNo',
     +           (profileseq(I:I),I=1,maxaa),'  NOCC',' NDEL',
     +           ' NINS',' ENTROPY',' RELENT',' WEIGHT'
         ENDIF
      ENDDO
 200  FORMAT(2X,2(I4,1X),A1,1X,A1,2X,A1,1X,A7,2(I4),A1,2(I4,1X),I4,2X,A)
C=======================================================================
C write SEQUENCE PROFILE-block
C=======================================================================
      DO I=1,NRES
         LINE=' '
         WRITE(LINE,300)I,PDBNO(I),CHAINID(I),
     +        (SEQPROF(I,K),K=1,MAXAA),NOCC(I),NDEL(I),NINS(I),
     +        ENTROPY(I),RELENT(I),CONSWEIGHT(I)
         IF (PDBNO(I).EQ.0) LINE(7:11)=' '
         CALL STRPOS(LINE,IBEG,IEND)
         WRITE(KOUT,'(A)')LINE(1:IEND)
      ENDDO
 300  FORMAT (2(1X,I4),1X,A1,20(I4),1X,3(1X,I4),1X,F7.3,3X,I4,2X,F4.2)
C=======================================================================
C write insertion block
C=======================================================================
      LINSERTION=.FALSE.
      IINS=1
      DO WHILE (.NOT. LINSERTION .AND. IINS .LE. INSNUMBER)
         IF ( EXCLUDEFLAG (INSALI(IINS)) .EQ.' ')LINSERTION=.TRUE. 
         IINS=IINS+1  
      ENDDO
      IF ( LINSERTION ) THEN
         WRITE(KOUT,'(A)')'## INSERTION LIST'
         WRITE(KOUT,'(A)')' AliNo  IPOS  JPOS   Len Sequence'
         CTEMPINS=' '
         DO IINS=1,INSNUMBER
            IF ( EXCLUDEFLAG (INSALI(IINS)) .EQ.' ') THEN
	       JPOS=INSPOINTER(IINS)
	       INS_NEW = INS_ORDER( INSALI(IINS) )
	       IF (INSLEN(IINS)+2 .LE. NBLOCKINS) THEN
                  DO IPOS=1,INSLEN(IINS)+2
                     CTEMPINS(IPOS:IPOS)=INSBUFFER(JPOS)
                     JPOS=JPOS+1
                  ENDDO
                  WRITE(KOUT,'(4(I6),1X,A)')INS_NEW,INSBEG_1(IINS),
     +         INSBEG_2(IINS),INSLEN(IINS),CTEMPINS(1:INSLEN(IINS)+2) 
	       ELSE
                  DO IPOS=1,NBLOCKINS
                     CTEMPINS(IPOS:IPOS)=INSBUFFER(JPOS)
                     JPOS=JPOS+1
                  ENDDO
                  WRITE(KOUT,'(4(I6),1X,A)')INS_NEW,INSBEG_1(IINS),
     +                 INSBEG_2(IINS),INSLEN(IINS),CTEMPINS(1:NBLOCKINS)
                  IBEG=NBLOCKINS+1
                  DO WHILE (IBEG .LE. INSLEN(IINS)+2 )
                     IEND=MIN(IBEG+NBLOCKINS-1,INSLEN(IINS)+2 )
                     IPOS=0
                     DO J=IBEG,IEND
                        IPOS=IPOS+1
                        CTEMPINS(IPOS:IPOS)=INSBUFFER(JPOS)
                        JPOS=JPOS+1
                     ENDDO
                     WRITE(KOUT,'(A,19X,A)')'     +',CTEMPINS(1:IPOS)
                     IBEG=IBEG+NBLOCKINS
                  ENDDO
               ENDIF
            ENDIF
         ENDDO
      ENDIF
C write last line ('//')
      WRITE(KOUT,'(A)')'//'
      CLOSE(KOUT)
      RETURN
      END
C     END WRITE_HSSP
C......................................................................

C......................................................................
C     SUB WRITE_KLEIN
      SUBROUTINE WRITE_KLEIN(KOUT,SEQ,NBLOCKS,NAME,INFILE,OUTFILE,
     1     HEADERLINE,SEQSTART,SEQSTOP,ERROR)

      IMPLICIT NONE
C     IMPORT
      INTEGER KOUT
      INTEGER NBLOCKS
      INTEGER SEQSTART,SEQSTOP
      CHARACTER*(*) SEQ
      CHARACTER*(*) HEADERLINE, NAME, INFILE,OUTFILE
C     EXPORT
C     ( OUTPUT TO UNIT KOUT )
      LOGICAL ERROR
C     INTERNAL
      INTEGER BLOCKSIZE
      PARAMETER      (BLOCKSIZE=                10)
      INTEGER ISTART, ISTOP
      INTEGER BEGIN, END, LENGTH
      CHARACTER*(250) OUTLINE
      LOGICAL NOCHAINBREAKS
      
      ERROR = .FALSE.
      
C     TRY TO OPEN OUTFILE; RETURN IF UNSUCCESSFUL	
      CALL OPEN_FILE(KOUT,OUTFILE,'new',error)
C error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN
      
      NOCHAINBREAKS = .FALSE.
      LENGTH = SEQSTOP-SEQSTART+1
      
C     BEGIN AND END
      CALL STRPOS(INFILE,ISTART,ISTOP)
      WRITE(OUTLINE,'(A,A,1X,A,I4,1X,A,I4)') 
     1     '; ',INFILE(MAX(ISTART,1):MAX(1,ISTOP)),
     2     'from: ',seqstart,'to: ',seqstop
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(MAX(ISTART,1):MAX(1,ISTOP))

C     headerline is a comment line: marked by ';'
      CALL STRPOS(HEADERLINE,ISTART,ISTOP)
      OUTLINE = '; ' // HEADERLINE(MAX(ISTART,1):MAX(1,ISTOP))
      WRITE(KOUT,'(A)') OUTLINE(1:ISTOP+2)
      OUTLINE = ' '
C     make up standard klein headerline
C     1GD1          1339
      CALL STRPOS(NAME,ISTART,ISTOP)
      WRITE(OUTLINE,'(1X,A,10X,I4)') 
     1     NAME(MAX(ISTART,1):MIN(MAX(ISTOP,1),6)),LENGTH 
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
C     write sequence

      BEGIN = SEQSTART
C     "repeat until"
 1    CONTINUE
C     writeseqline returns end
      CALL WRITESEQLINE(SEQ,BEGIN,BLOCKSIZE,NBLOCKS,SEQSTOP,
     1     NOCHAINBREAKS,OUTLINE,END,ERROR)
      IF ( ERROR ) STOP
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
      BEGIN = END + 1
      IF ( BEGIN .LE. SEQSTOP )  GOTO 1
C     END "REPEAT UNTIL"
      
      CLOSE(KOUT)

      RETURN
      END   
C     END WRITE_KLEIN
C......................................................................

C......................................................................
C     SUB WRITE_MSF
      SUBROUTINE WRITE_MSF(KUNIT,INFILE,OUTFILE,MAXALIGNS,MAXRES,
     1     MAXCORE,MAXINS,MAXINSBUF,BEGIN,END,NBLOCKS,ALISEQ,
     2     ALIPOINTER,IFIR,ILAS,TYPE,SEQNAMES,WEIGHT,SEQCHECK,
     3     MSFCHECK,ALILEN,NSEQ,INSNUMBER,INSALI,INSPOINTER,
     4     INSLEN,INSBEG_1,INSBUFFER,LDOEXP,ERROR)

      IMPLICIT NONE
C 3.6.93 insertion lists
C 4.11.93

C Import
      INTEGER MAXALIGNS, MAXRES, MAXCORE, MAXINS, MAXINSBUF
      INTEGER KUNIT, BEGIN, END, NBLOCKS, NSEQ
      INTEGER ALIPOINTER(MAXALIGNS)
      INTEGER ALILEN
      INTEGER IFIR(MAXALIGNS), ILAS(MAXALIGNS)  
      INTEGER INSNUMBER,INSALI(MAXINS),INSPOINTER(MAXINS)   
      INTEGER INSLEN(MAXINS),INSBEG_1(MAXINS)
      CHARACTER*(*) INFILE, OUTFILE
C     'P' = PROTEIN SEQUENCES, 'N' = NUCLEOTIDE SEQ
      CHARACTER*1 TYPE
      CHARACTER*(*) SEQNAMES(MAXALIGNS)
      CHARACTER ALISEQ(MAXCORE)	
      CHARACTER INSBUFFER(MAXINSBUF)
      REAL WEIGHT(MAXALIGNS)
      LOGICAL LDOEXP
C     EXPORT
      INTEGER MSFCHECK
      INTEGER SEQCHECK(MAXALIGNS)
      LOGICAL ERROR
C     INTERNAL
      INTEGER BLOCKSIZE
      INTEGER CODELEN
      INTEGER MAXALIGNS_LOC,MAXRES_LOC
      INTEGER  LINELEN
      PARAMETER      (BLOCKSIZE=                10)
      PARAMETER      (MAXALIGNS_LOC=         9999)
      PARAMETER      (MAXRES_LOC=            10000)
      PARAMETER      (LINELEN=                 200)
      
      INTEGER*2 MAXLEN(MAXRES_LOC)
      INTEGER*2 INSLIST_POINTER(MAXRES_LOC)
      INTEGER*2 TOTALINSLEN(MAXRES_LOC)
      INTEGER POS1, POS2
      INTEGER I, J, K, KK, IPOS, JPOS, ISEQ, IINS
      INTEGER LASTPOS, IAP   
      INTEGER ISTART, ISTOP, I1START, I1STOP, I2START, I2STOP 
      INTEGER ILEN, THISWIDTH
      INTEGER EFFECTIVE_BEGIN,EFFECTIVE_END                       
      INTEGER LENGTH(MAXALIGNS_LOC), IOUTPOS, NSPACES
      INTEGER LAST_INSERTION(MAXALIGNS_LOC)
      INTEGER NTRANS_INS(MAXALIGNS_LOC)
C     INTEGER INSPOS(MAXALIGNS_LOC)
      INTEGER LASTLEN(MAXALIGNS_LOC) 
      INTEGER*2 IAPS(MAXRES_LOC)
      CHARACTER*1 C
      CHARACTER*1 CGAPCHAR
      CHARACTER*8 TIMESTRING
      CHARACTER*9 DATESTRING
      CHARACTER*64 DATE_TIME
      CHARACTER*(LINELEN) LINE
      CHARACTER*(MAXRES_LOC) STRAND
      LOGICAL NOCHAINBREAKS, NO_INS_HERE 
      LOGICAL PARTIAL_INSERTION(MAXALIGNS_LOC)
      
C     REFORMAT OF: *.FRAG
C     
C Nfi.Msf  MSF: 594  Type: P  February 17, 1992  14:37  Check: 1709  ..
C
C Name: Cnfi02           Len:   594  Check: 7754  Weight:  1.00
C Name: Cnfi03           Len:   594  Check: 4932  Weight:  1.00
C                          
C//
C
C        1                                                   50
CCnfi02  MMYSPICLTQ DEFHPFIEAL LPHVRAIAYT WFNLQARKRK YFKKHEKRMS 
CCnfi03  MMYSPICLTQ DEFHPFIEAL LPHVRAIAYT WFNLQARKRK YFKKHEKRMS 

	
      ERROR = .FALSE.
      IINS=0
C try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KUNIT,OUTFILE,'new,recl=200',error)
C error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN

      IF ( NSEQ .GT. MAXALIGNS .OR.
     1     NSEQ .GT. MAXALIGNS_LOC ) THEN
         WRITE(6,'(1X,A)') 
     +        'ERROR: MAXALIGNS overflow in write_msf !'
         ERROR = .TRUE.
         RETURN
      ENDIF
      IF ( ALILEN .GT. MAXRES .OR.
     1     ALILEN .GT. MAXRES_LOC ) THEN
         WRITE(6,'(1X,A)') 
     +        'ERROR: MAXRES overflow in write_msf !'
         ERROR = .TRUE.
         RETURN
      ENDIF

      CGAPCHAR = '.'
      NOCHAINBREAKS = .FALSE.
      CODELEN = 1

      DO I=1,NSEQ
         CALL STRPOS(SEQNAMES(I),ISTART,ISTOP)
         IF (ISTOP .GT. CODELEN)CODELEN=ISTOP+2
      ENDDO
      IF (CODELEN .GT. LEN(SEQNAMES(1)) )CODELEN=LEN(SEQNAMES(1))

      IF ( LDOEXP ) THEN
         CALL PREPARE_INSERTIONS(MAXRES,MAXALIGNS,
     1        ALILEN,NSEQ,
     2        IFIR,ILAS,INSNUMBER,INSALI,INSLEN,
     3        INSBEG_1,MAXLEN,INSLIST_POINTER,
     4        TOTALINSLEN,ERROR)
      ELSE
         CALL INIT_INT2_ARRAY(1,ALILEN,MAXLEN,0)
         CALL INIT_INT2_ARRAY(1,ALILEN,TOTALINSLEN,0)
         CALL INIT_INT2_ARRAY(1,NSEQ,INSLIST_POINTER,0)
      ENDIF
        
      EFFECTIVE_BEGIN = BEGIN + TOTALINSLEN(BEGIN)
      EFFECTIVE_END = END + TOTALINSLEN(END)-TOTALINSLEN(BEGIN)

      CALL STRPOS(INFILE,ISTART,ISTOP)
      WRITE(LINE,'(1X,A,A,1X,A,I4,1X,A,I4)') 'MSF of: ',
     1     INFILE(ISTART:ISTOP),'from: ',begin,
     2     'to: ',effective_end
      CALL STRPOS(LINE,ISTART,ISTOP)
      WRITE(KUNIT,'(A)') LINE(ISTART:ISTOP)

C calculate single sequence checksums  
      DO ISEQ = 1, NSEQ
C j counts positions in "strand"; i counts alignment positions
         J = 0
         DO I = 1,IFIR(ISEQ)-1
C .. no need to check whether this insertion belongs to the current seq
C .. - this is impossible inside the region of the n-terminal gap
            DO K = 1,MAXLEN(I)
               J = J + 1
               STRAND(J:J) = CGAPCHAR
            ENDDO
            J = J + 1
            STRAND(J:J) = CGAPCHAR
         ENDDO

         IPOS = ALIPOINTER(ISEQ)
         DO I = IFIR(ISEQ),ILAS(ISEQ)
            J = J + 1
            C = ALISEQ(IPOS)
            IF ( LDOEXP ) CALL LOWTOUP(C,1)
            STRAND(J:J) = C
            
            IF ( ( MAXLEN(I) .GT. 0 )  .AND.
     1           ( INSLIST_POINTER(ISEQ) .NE. 0 ) ) THEN
               IINS = INSLIST_POINTER(ISEQ)
               DO WHILE ( INSBEG_1(IINS) .NE. I .AND.
     1              INSALI(IINS) .EQ. ISEQ )
                  IINS = IINS + 1
               ENDDO
               IF ( INSALI(IINS) .NE. ISEQ ) THEN
                  NO_INS_HERE = .TRUE.
               ELSE
                  NO_INS_HERE = .FALSE.
               ENDIF
            ELSE 
               NO_INS_HERE = .TRUE.
            ENDIF
            IF ( .NOT. NO_INS_HERE )  THEN  
C                 WRITE(6,'(1x,3(i4,1x))') iseq, insali(iins), iins
C .. this insertion belongs to current sequence - copy missing symbols 
C .. from INSBUFFER
               KK = INSPOINTER(IINS)
C .. insertions are stored as lowercaseINSERTIONlowercase; with 
C .. INSPOINTER pointing to the leading "lowercase". this symbol
C .. ( also in lowercase ) preceeds the insertion in aliseq; 
C .. this can be used as a check.
               C = INSBUFFER(KK)
               IF ( C .NE. ALISEQ(IPOS) ) THEN 
                  IF (  ALISEQ(IPOS) .NE. CGAPCHAR ) THEN
                     ERROR = .TRUE.
                     STOP 'MIST'
                  ENDIF
               ENDIF
               KK = KK + 1
               DO K = 1,INSLEN(IINS)
                  J = J + 1
                  STRAND(J:J) = INSBUFFER(KK)
                  KK = KK + 1
               ENDDO
               DO K = INSLEN(IINS)+1,MAXLEN(I)
                  J = J + 1
                  STRAND(J:J) = CGAPCHAR
               ENDDO
            ELSE 
C .. this insertion does not belong to current sequence - fill with 
C    gap symbols
               DO K = 1,MAXLEN(I)
                  J = J + 1
                  STRAND(J:J) = CGAPCHAR
               ENDDO
            ENDIF
            IPOS = IPOS + 1
         ENDDO

         DO I = ILAS(ISEQ)+1,ALILEN
C .. no need to check whether this insertion belongs to the current seq
C .. - this is impossible inside the region of the n-terminal gap
            DO K = 1,MAXLEN(I)
               J = J + 1
               STRAND(J:J) = CGAPCHAR
            ENDDO
            J = J + 1
            STRAND(J:J) = CGAPCHAR
         ENDDO
         
         CALL CHECKSEQ(STRAND,1,J,
     1        SEQCHECK(ISEQ))
      ENDDO
C calculate total checksum
      CALL MSFCHECKSEQ(SEQCHECK,NSEQ,MSFCHECK)
C Write MSF identification line
C get current date
      CALL GETDATE(DATESTRING)
C get current time
      CALL GETTIME(TIMESTRING)
C date + time
      DATE_TIME = DATESTRING // ' ' // TIMESTRING
      CALL STRPOS(OUTFILE,I1START,I1STOP)
      CALL STRPOS(DATE_TIME,I2START,I2STOP)
      WRITE(KUNIT,'(1X,A,2X,A,1X,I4,2X,A,A,1X,A,2X,A,I5,2X,A)')
     1     OUTFILE(I1START:I1STOP),'MSF:',
     2     EFFECTIVE_END-EFFECTIVE_BEGIN+1,
     3     'Type: ',type,date_time(i2start:i2stop),
     4     'Check:',msfcheck,'..'
      WRITE(KUNIT,'(A)') ' '
      WRITE(KUNIT,'(A)') ' '
C Write sequence identification section
      DO ISEQ = 1,NSEQ
         WRITE(KUNIT,'(A,A,2X,A,I5,2X,A,I4,2X,A,F5.2)')
     1        ' Name: ',seqnames(iseq)(1:codelen),'Len: ',
     2        effective_end-effective_begin+1,'Check: ',
     3        seqcheck(iseq), 'Weight: ', weight(iseq)
C divider
      ENDDO
      WRITE(KUNIT,'(A)') ' ' 
      WRITE(KUNIT,'(A)') '//' 
      WRITE(KUNIT,'(A)') ' '
      WRITE(KUNIT,'(A)') ' ' 
C     WRITE ALIGNMENT
      DO ISEQ = 1,NSEQ
         LENGTH(ISEQ) = EFFECTIVE_BEGIN
         IAPS(ISEQ) = BEGIN-1
         NTRANS_INS(ISEQ) = 0
         LASTLEN(ISEQ) = 0
         LAST_INSERTION(ISEQ) = 0
         PARTIAL_INSERTION(ISEQ) = .FALSE.
      ENDDO

      ILEN = 0
      DO WHILE ( ILEN .LT. EFFECTIVE_END-EFFECTIVE_BEGIN+1 )
C new block
         LASTPOS = 
     1        MIN(ILEN+NBLOCKS*BLOCKSIZE,EFFECTIVE_END-BEGIN+1)
         THISWIDTH = MIN(NBLOCKS*BLOCKSIZE,LASTPOS-ILEN)
C write scale line
         IF ( MOD(THISWIDTH,BLOCKSIZE) .EQ. 0 ) THEN
            NSPACES = THISWIDTH / BLOCKSIZE - 1
         ELSE
            NSPACES = THISWIDTH / BLOCKSIZE 
         ENDIF
         CALL  WRITESCALELINE(CODELEN+1,CODELEN+THISWIDTH+NSPACES,
     1        ILEN+1,LASTPOS,LINE)
         WRITE(KUNIT,'(A)') LINE(1:CODELEN+THISWIDTH+NBLOCKS+1)
C provide as many symbols in "strand" as writescalline will need to 
C transfer to next output line
C .. steps :
C ... - find alignment position x which is greater or equal the
C ..... desired end point, INCLUDING INSERTIONS
C ... - in case of "greater", there is an insertion crossing the 
C ..... boundary of the line to be output. 
C ..... SPLIT this insertion
         DO ISEQ = 1,NSEQ
            IOUTPOS = 1
            IAP = IAPS(ISEQ)
            IPOS = LENGTH(ISEQ) 
            IF ( PARTIAL_INSERTION(ISEQ) ) THEN
               IF ( LAST_INSERTION(ISEQ) .NE. 0 ) THEN
                  JPOS = 
     1             INSPOINTER(LAST_INSERTION(ISEQ))+NTRANS_INS(ISEQ)+1
                  DO WHILE ( 
     1                 IPOS .LE. EFFECTIVE_END 
     2                 .AND.
     3                 IPOS .LE. LENGTH(ISEQ)+NBLOCKS*BLOCKSIZE-1 
     4                 .AND.
     5                 JPOS .LE. INSPOINTER(LAST_INSERTION(ISEQ)) +
     6                 INSLEN(LAST_INSERTION(ISEQ)) 
     7                 )
                     STRAND(IOUTPOS:IOUTPOS) = INSBUFFER(JPOS)
                     IOUTPOS = IOUTPOS + 1
                     IPOS = IPOS + 1
                     NTRANS_INS(ISEQ) = NTRANS_INS(ISEQ) + 1
                     JPOS = JPOS + 1
                  ENDDO
               ENDIF

               DO WHILE ( 
     1              IPOS .LE. EFFECTIVE_END 
     2              .AND.
     3              IPOS .LE. LENGTH(ISEQ)+NBLOCKS*BLOCKSIZE-1 
     4              .AND.
     5              NTRANS_INS(ISEQ) .LT. LASTLEN(ISEQ) 
     6              )
                  STRAND(IOUTPOS:IOUTPOS) = CGAPCHAR
                  IOUTPOS = IOUTPOS + 1
                  IPOS = IPOS + 1
                  NTRANS_INS(ISEQ) = NTRANS_INS(ISEQ) + 1
               ENDDO
               IF ( NTRANS_INS(ISEQ) .EQ. LASTLEN(ISEQ) ) THEN
                  PARTIAL_INSERTION(ISEQ) = .FALSE.
                  NTRANS_INS(ISEQ) = 0
               ENDIF
            ENDIF
            DO WHILE ( 
     1           IPOS .LE. EFFECTIVE_END .AND.
     2           IPOS .LE. LENGTH(ISEQ)+NBLOCKS*BLOCKSIZE-1 
     3                 )
               IAP = IAP  + 1
               IF ( IAP .LT. IFIR(ISEQ) .OR.
     1              IAP .GT. ILAS(ISEQ)       ) THEN
                  STRAND(IOUTPOS:IOUTPOS) = CGAPCHAR
               ELSE
                  C = ALISEQ( 
     1                 ALIPOINTER(ISEQ)+IAP-
     2                 IFIR(ISEQ)
     3                 )
                  IF ( LDOEXP ) CALL LOWTOUP(C,1)
                  STRAND(IOUTPOS:IOUTPOS) = C
               ENDIF
               IOUTPOS = IOUTPOS + 1
               IPOS = IPOS + 1
               IF ( ( MAXLEN(IAP) .GT. 0 )  .AND.
     1              ( INSLIST_POINTER(ISEQ) .NE. 0 ) ) THEN
                  IINS = INSLIST_POINTER(ISEQ)
                  DO WHILE ( INSBEG_1(IINS) .NE. IAP .AND.
     1                 INSALI(IINS) .EQ. ISEQ  )
                     IINS = IINS + 1
                  ENDDO
                  IF ( INSALI(IINS) .NE. ISEQ ) THEN
                     NO_INS_HERE = .TRUE.
                  ELSE
                     NO_INS_HERE = .FALSE.
                  ENDIF
               ELSE 
                  NO_INS_HERE = .TRUE.
               ENDIF
               IF ( .NOT. NO_INS_HERE )  THEN   
                  JPOS = INSPOINTER(IINS)+1
                  DO WHILE ( 
     1                 IPOS .LE. EFFECTIVE_END 
     2                 .AND.
     3                 IPOS .LE. (LENGTH(ISEQ)+NBLOCKS*BLOCKSIZE -1) 
     4                 .AND.
     5                 JPOS .LE. (INSPOINTER(IINS)+INSLEN(IINS))
     6                 )
                     STRAND(IOUTPOS:IOUTPOS) = INSBUFFER(JPOS)
                     IOUTPOS = IOUTPOS + 1
                     NTRANS_INS(ISEQ) = NTRANS_INS(ISEQ) + 1
                     IPOS = IPOS + 1
                     JPOS = JPOS + 1
                  ENDDO
                  DO WHILE ( 
     1                 IPOS .LE. EFFECTIVE_END 
     2                 .AND.
     3                 IPOS .LE. (LENGTH(ISEQ)+NBLOCKS*BLOCKSIZE-1) 
     4                 .AND.
     5                 NTRANS_INS(ISEQ) .LT. MAXLEN(IAP) 
     6                 )
                     STRAND(IOUTPOS:IOUTPOS) = CGAPCHAR
                     IPOS = IPOS + 1
                     IOUTPOS = IOUTPOS + 1
                     NTRANS_INS(ISEQ) = NTRANS_INS(ISEQ) + 1
                  ENDDO
                  IF ( NTRANS_INS(ISEQ) .EQ. MAXLEN(IAP) ) THEN
                     PARTIAL_INSERTION(ISEQ) = .FALSE.
                     NTRANS_INS(ISEQ) = 0
                  ELSE
                     PARTIAL_INSERTION(ISEQ) = .TRUE.
                     LAST_INSERTION(ISEQ) = IINS
                     LASTLEN(ISEQ) = MAXLEN(IAP)
                  ENDIF
               ELSE 
                  DO WHILE ( 
     1                 IPOS .LE. EFFECTIVE_END 
     2                 .AND.
     3                 IPOS .LE. LENGTH(ISEQ)+NBLOCKS*BLOCKSIZE-1 
     4                 .AND.
     5                 NTRANS_INS(ISEQ) .LT. MAXLEN(IAP) 
     6                 )
                     STRAND(IOUTPOS:IOUTPOS) = CGAPCHAR
                     IOUTPOS = IOUTPOS + 1
                     NTRANS_INS(ISEQ) = NTRANS_INS(ISEQ) + 1
                     IPOS = IPOS + 1
                  ENDDO
                  IF ( NTRANS_INS(ISEQ) .EQ. MAXLEN(IAP) ) THEN
                     PARTIAL_INSERTION(ISEQ) = .FALSE.
                     NTRANS_INS(ISEQ) = 0
                  ELSE
                     PARTIAL_INSERTION(ISEQ) = .TRUE.
                     LAST_INSERTION(ISEQ) = 0
                     LASTLEN(ISEQ) = MAXLEN(IAP)
                  ENDIF
               ENDIF
            ENDDO
            IOUTPOS = IOUTPOS - 1
            POS1 = 1
C writeseqline returns pos2 ( position of last transferred symbol )
            CALL WRITESEQLINE(STRAND,POS1,BLOCKSIZE,NBLOCKS,IOUTPOS,
     1           NOCHAINBREAKS,LINE,POS2,ERROR)
            IF ( ERROR ) STOP
            CALL STRPOS(LINE,ISTART,ISTOP)
            LENGTH(ISEQ) = LENGTH(ISEQ) + POS2 
            IAPS(ISEQ) = IAP
            LINE = SEQNAMES(ISEQ)(1:CODELEN) // LINE(ISTART:ISTOP)
            CALL STRPOS(LINE,ISTART,ISTOP)
            WRITE(KUNIT,'(A)') LINE(ISTART:ISTOP)
         ENDDO
         WRITE(KUNIT,'(A)') ' '
         ILEN = ILEN + NBLOCKS*BLOCKSIZE
      ENDDO

      CLOSE(KUNIT)

      RETURN
      END
C     END WRITE_MSF
C......................................................................

C......................................................................
C     SUB WRITE_PEARSON
      SUBROUTINE WRITE_PEARSON(KOUT,OUTFILE,SEQ,NBLOCKS,IDENTIFIER,
     1     HEADERLINE,SEQSTART,SEQSTOP,ERROR)

      IMPLICIT NONE
C     IMPORT
      INTEGER KOUT
      INTEGER NBLOCKS
      INTEGER SEQSTART,SEQSTOP
      CHARACTER*(*) SEQ
      CHARACTER*(*) OUTFILE,HEADERLINE,IDENTIFIER
C     EXPORT
C     ( OUTPUT TO UNIT KOUT )
      LOGICAL ERROR
C     INTERNAL
      INTEGER BLOCKSIZE
      PARAMETER      (BLOCKSIZE=                10)
      INTEGER ISTART, ISTOP, JSTART, JSTOP
      INTEGER BEGIN, END
C     INTEGER LENGTH
      CHARACTER*(250) OUTLINE
      LOGICAL NOCHAINBREAKS
      
      ERROR = .FALSE.
	
C     TRY TO OPEN OUTFILE; RETURN IF UNSUCCESSFUL	
      CALL OPEN_FILE(KOUT,OUTFILE,'unknown,append',error)
C     ERROR MESSAGES ARE ALREDY ISSUED BY OPEN_FILE   
      IF ( ERROR ) RETURN

      NOCHAINBREAKS = .FALSE.
C     LENGTH = SEQSTOP-SEQSTART+1
		
C     headerline is a comment line: marked by '>'
      CALL STRPOS(IDENTIFIER,ISTART,ISTOP)
      CALL STRPOS(HEADERLINE,JSTART,JSTOP)
      OUTLINE = '>' // IDENTIFIER(MAX(ISTART,1):MAX(1,ISTOP)) //
     1     ' ,  ' //
     2     HEADERLINE(MAX(JSTART,1):MAX(1,JSTOP))
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:ISTOP)
C     WRITE SEQUENCE

      BEGIN = SEQSTART
C "repeat until"
 1    CONTINUE
C writeseqline returns end
      CALL WRITESEQLINE(SEQ,BEGIN,BLOCKSIZE,NBLOCKS,SEQSTOP,
     1     NOCHAINBREAKS,OUTLINE,END,ERROR)
      IF ( ERROR ) STOP
      IF ( END .EQ. SEQSTOP ) THEN
         CALL STRPOS(OUTLINE,ISTART,ISTOP)
C     OUTLINE = OUTLINE(1:MAX(1,ISTOP)) // '*'
         OUTLINE = OUTLINE(1:MAX(1,ISTOP))
      ENDIF
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
      BEGIN = END + 1
      IF ( BEGIN .LE. SEQSTOP )  GOTO 1
C     END "REPEAT UNTIL"
      
      CLOSE(KOUT)

      RETURN
      END   
C     END WRITE_PEARSON
C......................................................................

C......................................................................
C     SUB WRITE_PHYLIP
      SUBROUTINE WRITE_PHYLIP(KOUT,MAXALIGNS,MAXCORE,BEGIN,
     1     END,NBLOCKS,ALISEQ,ALIPOINTER,
     2     IFIR,ILAS,SEQNAMES,NSEQ,ERROR)

      IMPLICIT NONE
C This routine writes an "sequential" phylip format, i.e. one sequence
C from begin to end, then next one

C     IMPORT
      INTEGER KOUT
      INTEGER MAXALIGNS, MAXCORE
      INTEGER BEGIN, END, NBLOCKS
      INTEGER NSEQ
      INTEGER ALIPOINTER(MAXALIGNS)
      INTEGER IFIR(MAXALIGNS), ILAS(MAXALIGNS)
      CHARACTER ALISEQ(MAXCORE)
      CHARACTER*(*) SEQNAMES(MAXALIGNS)
C     EXPORT
C     ( OUTPUT TO UNIT KOUT )
      LOGICAL ERROR
C     INTERNAL
      INTEGER BLOCKSIZE
      INTEGER MAXRES_LOC
      INTEGER CODELEN_LOC
      INTEGER LINELEN
      PARAMETER      (BLOCKSIZE=                10)
      PARAMETER      (LINELEN=                 250)
      PARAMETER      (MAXRES_LOC=            10000)
      PARAMETER      (CODELEN_LOC=               9)
      INTEGER IPOS,POS1,POS2,ISEQ,IOUTPOS
      INTEGER ISTART,ISTOP,ACTNBLOCKS
C     INTEGER I1START,I1STOP
      CHARACTER CGAPCHAR
      CHARACTER*(MAXRES_LOC) STRAND
      CHARACTER*(LINELEN) OUTLINE, TMPSTRING
      LOGICAL NOCHAINBREAKS
      
      CGAPCHAR = '-'
      NOCHAINBREAKS = .FALSE.
      
      IF ( LEN(SEQNAMES(1)) .LT. CODELEN_LOC ) THEN
         ERROR = .TRUE.
         WRITE(6,'(A)') ' CODELEN TOO SHORT IN WRITE_PHYLIP !'
         RETURN
      ENDIF

C     PHYLIP headerline: "  nseq  end-begin+1"
      WRITE(OUTLINE,'(I4,1X,I4)') NSEQ, END-BEGIN+1
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:ISTOP)
C     Write alignment
C     provide one whole sequence  in "strand" for w_scaleline to 
C     transfer it 
      DO ISEQ = 1,NSEQ
         IOUTPOS = 1
         DO IPOS = BEGIN,END
            IF ( IPOS .LT. IFIR(ISEQ)  .OR.
     1           IPOS .GT. ILAS(ISEQ)         ) THEN
               STRAND(IOUTPOS:IOUTPOS) = CGAPCHAR
            ELSE
               STRAND(IOUTPOS:IOUTPOS) = ALISEQ( 
     1              ALIPOINTER(ISEQ)+IPOS-IFIR(ISEQ) 
     2              )
            ENDIF
            IOUTPOS = IOUTPOS + 1
         ENDDO
         
         DO IPOS=1,IOUTPOS-1
            IF ( STRAND(IPOS:IPOS) .EQ. '.') THEN
               STRAND(IPOS:IPOS)= CGAPCHAR
            ENDIF
         ENDDO
C     CALL CHARARRAYREPL(STRAND,IOUTPOS-1,'.',CGAPCHAR)
         POS1 = BEGIN 
C     "REPEAT UNTIL"
 1       CONTINUE
         IF ( POS1 .EQ. BEGIN ) THEN
            ACTNBLOCKS = NBLOCKS - 1
         ELSE
            ACTNBLOCKS = NBLOCKS
         ENDIF
C     writeseqline returns pos2
         CALL WRITESEQLINE(STRAND,POS1,BLOCKSIZE,ACTNBLOCKS,END,
     1        NOCHAINBREAKS,TMPSTRING,POS2,ERROR)
         IF ( ERROR ) STOP
         CALL STRPOS(TMPSTRING,ISTART,ISTOP)
         IF ( POS1 .EQ. BEGIN ) THEN
C     SEQUENCE NAME APPEARS ONLY ONCE ( IN FIRST LINE )
            OUTLINE = SEQNAMES(ISEQ)(1:CODELEN_LOC) // ' ' //
     1           TMPSTRING(ISTART:ISTOP)
         ELSE
            OUTLINE = TMPSTRING(ISTART:ISTOP)
         ENDIF
         CALL STRPOS(OUTLINE,ISTART,ISTOP)
         WRITE(KOUT,'(A)') OUTLINE(1:ISTOP)
         POS1 = POS2 + 1
         IF ( POS1 .LT. END )  GOTO 1
C     END "REPEAT UNTIL"
      ENDDO
      
      RETURN
      END
C     END WRITE_PHYLIP
C......................................................................

C......................................................................
C     SUB WRITE_PIR
      SUBROUTINE WRITE_PIR(KOUT,SEQ,INFILE,OUTFILE,ACCESSION,
     1     IDENTIFIER,NSYMBOLS,SEQSTART,SEQSTOP,ERROR)
      
      IMPLICIT NONE
C     IMPORT
      INTEGER KOUT
      INTEGER NSYMBOLS
      INTEGER SEQSTART, SEQSTOP
      CHARACTER*(*) SEQ
      CHARACTER*(*) INFILE, OUTFILE,ACCESSION, IDENTIFIER
C     EXPORT
C     ( OUTPUT TO UNIT KOUT )
      LOGICAL ERROR
C     INTERNAL
      INTEGER ISTART, ISTOP
      INTEGER I1START, I1STOP, I2START, I2STOP, I3START, I3STOP
      INTEGER BEGIN, END
C     INTEGER LENGTH
      INTEGER MAX_LINE_LEN
      PARAMETER      (MAX_LINE_LEN=           1000)
      CHARACTER*(MAX_LINE_LEN) OUTLINE
      LOGICAL NOCHAINBREAKS
      
      ERROR = .FALSE.
      
C     try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KOUT,OUTFILE,'unknown,append',error)
C     error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN

      NOCHAINBREAKS = .FALSE.
c        length = seqstop-seqstart+1

      CALL STRPOS(ACCESSION,ISTART,ISTOP)
      IF (ISTART.LT.1 .OR. ISTOP.LT.1 .OR. (ISTOP-ISTART).GT.10) THEN
         ACCESSION=' '
      END IF
      WRITE(OUTLINE,'(A,A)')
     1     '>P1; ',ACCESSION(MAX(1,ISTART):MAX(1,ISTOP))
C      WRITE(OUTLINE,'(A,A)')
C     1     '>',ACCESSION(MAX(1,ISTART):MAX(1,ISTOP))
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))

c	call strpos(infile,i1start,i1stop)
c	call strpos(outfile,i2start,i2stop)
c        write(outline,'(a,1x,a,1x,a,1x,a,i4,1x,a,i4,1x,a)')
c     1       outfile(i2start:i2stop),'(', infile(i1start:i1stop),
c     2       'from: ',seqstart,'to: ', seqstop,')'


      CALL STRPOS(IDENTIFIER,ISTART,ISTOP)
      ISTOP=MIN(ISTOP,MAX_LINE_LEN)
      WRITE(OUTLINE,'(A)')
     1     IDENTIFIER(MAX(1,ISTART):MAX(1,ISTOP))
      
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
      
      BEGIN = SEQSTART
C     "REPEAT UNTIL"
 1    CONTINUE
C     WRITESEQLINE RETURNS END
      CALL WRITESEQLINE(SEQ,BEGIN,1,NSYMBOLS,SEQSTOP,
     1     NOCHAINBREAKS,OUTLINE,END,ERROR)
      IF ( ERROR ) STOP
      IF ( END .EQ. SEQSTOP ) THEN
         CALL STRPOS(OUTLINE,ISTART,ISTOP)
         OUTLINE = OUTLINE(1:MAX(1,ISTOP)) // ' *'
      ENDIF
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
      BEGIN = END + 1
      IF ( BEGIN .LE. SEQSTOP )  GOTO 1
C     END "REPEAT UNTIL"
      
      CLOSE(KOUT)

      RETURN
      END     
C     END WRITE_PIR
C......................................................................

C......................................................................
C     SUB WRITE_STAR
      SUBROUTINE WRITE_STAR(KOUT,SEQ,NBLOCKS,INFILE,OUTFILE,
     1     HEADERLINE,SEQSTART,SEQSTOP,ERROR)

      IMPLICIT NONE
C     IMPORT
      INTEGER KOUT
      INTEGER NBLOCKS
      INTEGER SEQSTART,SEQSTOP
      CHARACTER*(*) SEQ
      CHARACTER*(*) INFILE,OUTFILE,HEADERLINE
C     EXPORT
C     ( OUTPUT TO UNIT KOUT )
      LOGICAL ERROR
C     INTERNAL
      INTEGER BLOCKSIZE
      PARAMETER      (BLOCKSIZE=                10)
      INTEGER ISTART, ISTOP
      INTEGER BEGIN, END
C     INTEGER LENGTH
      CHARACTER*(250) OUTLINE
      LOGICAL NOCHAINBREAKS
      
      ERROR = .FALSE.
	
C try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KOUT,OUTFILE,'NEW',ERROR)
C error messages are alredy issued by OPEN_FILE   
      IF ( ERROR ) RETURN

      NOCHAINBREAKS = .FALSE.
c        length = seqstop-seqstart+1
		
C begin and end
      CALL STRPOS(INFILE,ISTART,ISTOP)
      WRITE(OUTLINE,'(A,A,1X,A,I4,1X,A,I4)') 
     1     '* ',infile(istart:istop),'from: ',
     2     seqstart,'to: ',seqstop
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(MAX(ISTART,1):MAX(1,ISTOP))

C headerline is a comment line: marked by '*'
      CALL STRPOS(HEADERLINE,ISTART,ISTOP)
      OUTLINE = '* ' // HEADERLINE(MAX(ISTART,1):MAX(1,ISTOP))
      WRITE(KOUT,'(A)') OUTLINE(1:ISTOP+2)
C write sequence

      BEGIN = SEQSTART
C "repeat until"
 1    CONTINUE
C writeseqline returns end
      CALL WRITESEQLINE(SEQ,BEGIN,BLOCKSIZE,NBLOCKS,SEQSTOP,
     1     NOCHAINBREAKS,OUTLINE,END,ERROR)
      IF ( ERROR ) STOP
      CALL STRPOS(OUTLINE,ISTART,ISTOP)
      WRITE(KOUT,'(A)') OUTLINE(1:MAX(1,ISTOP))
      BEGIN = END + 1
      IF ( BEGIN .LE. SEQSTOP )  GOTO 1
C     END "REPEAT UNTIL"
      
      CLOSE(KOUT)
      
      RETURN
      END   
C     END WRITE_STAR
C......................................................................

C......................................................................
C     SUB WRITELINES
      SUBROUTINE WRITELINES(CSTRING)
C if 'cstring' contains '/n' (new line) this routine writes cstring
C line by line on screen; called by GETINT,GETREAL..... 
      CHARACTER*(*) CSTRING
      INTEGER ICUTBEGIN(30),ICUTEND(30)

      CALL STRPOS(CSTRING,ISTART,ISTOP)
      ILINE=1
      ICUTBEGIN(ILINE)=1
      ICUTEND(ILINE)=ISTOP

      DO I=1,ISTOP-1
         IF (CSTRING(I:I+1).EQ.'/n') THEN
            ILINE=ILINE+1
            ICUTBEGIN(ILINE)=I+2
            ICUTEND(ILINE-1)=I-1
            ICUTEND(ILINE)=ISTOP
         ENDIF
      ENDDO
      DO I=1,ILINE
         WRITE(6,*)CSTRING(ICUTBEGIN(I):ICUTEND(I))
      ENDDO
      RETURN
      END
C     END WRITELINES
C......................................................................

C......................................................................
C     SUB WRITEPROFILE
      SUBROUTINE WRITEPROFILE(KPROF,PROFILENAME,MAXRES,
     +     NRES,NCHAIN,HSSPID,HEADER,COMPOUND,SOURCE,AUTHOR,
     +     SMIN,SMAX,MAPLOW,MAPHIGH,METRICFILE,
     +     PDBNO,CHAINID,SEQ,STRUC,ACC,COLS,SHEETLABEL,
     +     BP1,BP2,NOCC,GAPOPEN,GAPELONG,CONSWEIGHT,
     +     PROFILEMETRIC,MAXBOX,NBOX,PROFILEBOX,LDSSP)
      IMPLICIT NONE

      INTEGER	    nacid
      PARAMETER   (nacid=20)
      INTEGER     kprof,maxres,nres,acc(*),bp1(*),bp2(*),nocc(*)
      INTEGER     NCHAIN,pdbno(*)
      INTEGER     MAXBOX,NBOX,PROFILEBOX(MAXBOX,2)
      REAL        profilemetric(maxres,*),gapopen(*),gapelong(*)
      REAL        consweight(*)
      REAL        smin,smax,maplow,maphigh
      CHARACTER*(*) hsspid,header,compound,source,author,metricfile
      CHARACTER*(*) profilename,seq(*),struc(*)
      CHARACTER*(*) chainid(*)
      character*7   cols(*)
      character     sheetlabel(*)
      LOGICAL LDSSP
C internal
      CHARACTER*500 line
      INTEGER     ilen,i,j,ibox,istart,istop
      LOGICAL     lerror
C======================================================================
      CALL OPEN_FILE(KPROF,PROFILENAME,'NEW,RECL=350',LERROR)
      IF (LDSSP) THEN
         WRITE(KPROF,'(A)')
     +     '****** MAXHOM-PROFILE WITH SECONDARY-STRUCTURE V1.0 ******'
      ELSE
         WRITE(KPROF,'(A)')'****** MAXHOM-PROFILE V1.0 ******'
      ENDIF
      WRITE(KPROF,'(A)')'# '
      CALL STRPOS(HSSPID,I,J)
      WRITE(KPROF,'(A,A)')   'ID        : ',HSSPID(I:J)
      CALL STRPOS(HEADER,I,J)
      IF (I .GT. 0 .AND. J .GT. 0) THEN
         WRITE(KPROF,'(A,A)')   'HEADER    : ',HEADER(I:J)
      ELSE
         WRITE(KPROF,'(A)')   'HEADER    : '
      ENDIF
      CALL STRPOS(COMPOUND,I,J)
      IF (I .GT. 0 .AND. J .GT. 0) THEN
         WRITE(KPROF,'(A,A)')   'COMPOUND  : ',COMPOUND(I:J)
      ELSE
         WRITE(KPROF,'(A)')   'COMPOUND  : '
      ENDIF
      CALL STRPOS(SOURCE,I,J)
      IF (I .GT. 0 .AND. J .GT. 0) THEN
         WRITE(KPROF,'(A,A)')   'SOURCE    : ',SOURCE(I:J)  
      ELSE
         WRITE(KPROF,'(A)')   'SOURCE    : '
      ENDIF
      CALL STRPOS(AUTHOR,I,J)
      IF (I .GT. 0 .AND. J .GT. 0) THEN
         WRITE(KPROF,'(A,A)')   'AUTHOR    : ',AUTHOR(I:J)
      ELSE
         WRITE(KPROF,'(A)')   'AUTHOR    : '
      ENDIF
      WRITE(KPROF,'(A,I4)')  'NRES      : ',NRES
      WRITE(KPROF,'(A,I4)')  'NCHAIN    : ',NCHAIN
      WRITE(KPROF,'(A,F7.2)')'SMIN      : ',SMIN
      WRITE(KPROF,'(A,F7.2)')'SMAX      : ',SMAX
      WRITE(KPROF,'(A,F7.2)')'MAPLOW    : ',MAPLOW
      WRITE(KPROF,'(A,F7.2)')'MAPHIGH   : ',MAPHIGH
      CALL STRPOS(METRICFILE,I,J)
      IF (I .GT. 0 .AND. J .GT. 0) THEN
         WRITE(KPROF,'(A,A)')'METRIC    : ',METRICFILE(I:J) 
      ELSE
         WRITE(KPROF,'(A)')'METRIC    : '
      ENDIF
      IF (NBOX.GT.1) THEN
         WRITE(KPROF,'(A,I6)')'NBOX      : ',NBOX
         DO IBOX=1,NBOX
            WRITE(KPROF,'(A,I4,A,I4,A,I4)')'BOX',IBOX,'   : ',
     +           PROFILEBOX(IBOX,1),'-',PROFILEBOX(IBOX,2)
         ENDDO
      ENDIF
      write(kprof,'(a)')'#========================================='//
     +     '======================================================='//
     +     '======================================================='//
     +     '===================================================' 
CSeqNo  PDBNo AA STRUCTURE BP1 BP2  ACC NOCC  open elong    V   L ...  
C
      line=' SeqNo  PDBNo AA STRUCTURE BP1 BP2  ACC NOCC  '//
     +     'OPEN ELONG  WEIGHT   '//
     +     'V       L       I       M       F       W       Y       '//
     +     'G       A       P       S       T       C       H       '//
     +     'R       K       Q       E       N       D'
      CALL STRPOS(LINE,ISTART,ISTOP)
      WRITE(KPROF,'(A)')LINE(:ISTOP)

      DO I=1,NRES
         IF (I.GT.MAXRES) THEN
            WRITE(6,*)' *** ERROR IN WRITEPROFILE: NRES.GT.MAXRES'
            STOP
         ENDIF

         IF (STRUC(I).EQ.'U')STRUC(I)=' '
         WRITE(LINE,100)I,PDBNO(I),CHAINID(I),SEQ(I),STRUC(I),
     +        COLS(I),BP1(I),BP2(I),SHEETLABEL(I),ACC(I),NOCC(I)
         IF (PDBNO(I).EQ.0)LINE(7:11)=' '
         CALL STRPOS(LINE,ISTART,ISTOP)
         WRITE(LINE(ISTOP+1:),'(2(F6.2),F7.2,20(F8.3))')
     +        GAPOPEN(I),GAPELONG(I),CONSWEIGHT(I),
     +        (PROFILEMETRIC(I,J),J=1,NACID)
         
         CALL STRPOS(LINE,ISTART,ISTOP)
         WRITE(KPROF,'(A)')LINE(:ISTOP)
 100     FORMAT(2X,2(I4,1X),A1,1X,A1,2X,A1,1X,A7,2(I4),A1,2(I4,1X))
      ENDDO

      WRITE(KPROF,'(A)')'//'
      CLOSE(KPROF)
      RETURN
      END
C     END WRITEPROFILE
C......................................................................

C......................................................................
C     SUB WRITESCALELINE
      SUBROUTINE WRITESCALELINE(ISTART,ISTOP,LABEL1,LABEL2,OUTLINE)

      IMPLICIT        NONE
C     4.11.93
C     ISTART: POSITION AFTER WHICH TO PLACE LABEL1
C     ISTOP : POSITION AT WHICH LABEL2 SHOULD END
C     IMPORT
      INTEGER         ISTART,ISTOP,LABEL1,LABEL2
C     EXPORT
      CHARACTER*(*)   OUTLINE
C     INTERNAL
      INTEGER         LABELLEN
      PARAMETER      (LABELLEN=                  4)
      CHARACTER*16    FORM
      CHARACTER*(LABELLEN)  CTMP
*----------------------------------------------------------------------*
      
C     PREPARE LABEL OUTPUT FORMAT
      CTMP=' '
      WRITE(CTMP,'(I2)') LABELLEN
      CALL LEFTADJUST(CTMP,1,LABELLEN)
      FORM = '( I4'  // ')'
        
C     BUILD UP OUTLINE
      OUTLINE = ' '
      
      WRITE(CTMP,FORM) LABEL1
      
      CALL LEFTADJUST(CTMP,1,LABELLEN)
      OUTLINE = OUTLINE(1:ISTART-1) // CTMP
      
      WRITE(CTMP,FORM) LABEL2
      
      CALL RIGHTADJUST(CTMP,1,LABELLEN)
      OUTLINE = OUTLINE(1:ISTOP-LABELLEN) // CTMP
      
      RETURN
      END
C     END WRITESCALELINE
C......................................................................
      
C......................................................................
C     SUB WRITESEQLINE
      SUBROUTINE WRITESEQLINE(SEQ,ISTART,BLOCKSIZE,NBLOCKS,NRES,
     1     NOCHAINBREAKS,OUTLINE,ISTOP,ERROR)
      
      IMPLICIT NONE
C 4.11.93

C  CCCCCCCCCC CCCCCCCCCC CCCCCCCCCC CCCCCCCCCC
C  ^        ^                                ^   
C  istart:  blocksize:                       istop: 
C  first    10 here                          last    
C  seq.pos.                                  seq.pos.
C  to be                                     transferred
C  transferred                               
C        
C        
C                                            nblocks: 4 here
C line starts with 1 blank
C istart is given, istop is returned ( if ( nochainbreaks ) maybe
C some symbols are not transferred ))
C
C     IMPORT
      INTEGER ISTART, ISTOP
      INTEGER BLOCKSIZE
      INTEGER NBLOCKS, NRES
      CHARACTER*(*) SEQ
      LOGICAL NOCHAINBREAKS
C     EXPORT
      CHARACTER*(*) OUTLINE
      LOGICAL ERROR
C     INTERNAL
      INTEGER ISEQPOS, ILINEPOS,IBLOCKPOS,IBLOCK
      
      ERROR = .FALSE.
      OUTLINE = ' '
      ILINEPOS = 1
      IBLOCKPOS = 0
      IBLOCK = 1
      ISEQPOS = ISTART - 1
      DO WHILE ( ILINEPOS .LT. NBLOCKS*BLOCKSIZE+NBLOCKS .AND.
     1     ISEQPOS .LT. NRES )
         ISEQPOS = ISEQPOS + 1
         IF ( IBLOCK .LT. NBLOCKS .AND. 
     1        IBLOCKPOS .EQ. BLOCKSIZE ) THEN
            IBLOCKPOS = 0
            IBLOCK = IBLOCK + 1
            ILINEPOS = ILINEPOS + 1
            OUTLINE(ILINEPOS:ILINEPOS) = ' '
         ENDIF
         IF ( .NOT. NOCHAINBREAKS .OR. 
     1        ( NOCHAINBREAKS .AND. SEQ(ISEQPOS:ISEQPOS) .NE. '!' )
     2        ) THEN
            ILINEPOS = ILINEPOS + 1
            IBLOCKPOS = IBLOCKPOS + 1
            OUTLINE(ILINEPOS:ILINEPOS) = SEQ(ISEQPOS:ISEQPOS)
         ENDIF
      ENDDO
      ISTOP = ISEQPOS
      
      RETURN
      END
C     END WRITESEQLINE
C......................................................................

C......................................................................
C     SUB U3B
      SUBROUTINE U3B(W,X,Y,N,MODE,RMS,U,T,IER)
C this version copied July 1986. DO NOT REDISTRIBUTE.
C If you want this routine, ask Wolfgang Kabsch 
C**** CALCULATES A BEST ROTATION & TRANSLATION BETWEEN TWO VECTOR SETS
C**** SUCH THAT U*X+T IS THE CLOSEST APPROXIMATION TO Y.
C**** THE CALCULATED BEST SUPERPOSITION MAY NOT BE UNIQUE AS INDICATED
C**** BY A RESULT VALUE IER=-1. HOWEVER IT IS GARANTIED THAT WITHIN
C**** NUMERICAL TOLERANCES NO OTHER SUPERPOSITION EXISTS GIVING A
C**** SMALLER VALUE FOR RMS.
C**** THIS VERSION OF THE ALGORITHM IS OPTIMIZED FOR THREE-DIMENSIONAL
C**** REAL VECTOR SPACE.
C**** USE OF THIS ROUTINE IS RESTRICTED TO NON-PROFIT ACADEMIC
C**** APPLICATIONS.
C**** PLEASE REPORT ERRORS TO
C**** PROGRAMMER:  W.KABSCH   MAX-PLANCK-INSTITUTE FOR MEDICAL RESEARCH
C        JAHNSTRASSE 29, 6900 HEIDELBERG, FRG.
C**** REFERENCES:  W.KABSCH   ACTA CRYST.(1978).A34,827-828
C           W.KABSCH ACTA CRYST.(1976).A32,922-923
C
C  W    - W(M) IS WEIGHT FOR ATOM PAIR  # M           (GIVEN)
C  X    - X(I,M) ARE COORDINATES OF ATOM # M IN SET X       (GIVEN)
C  Y    - Y(I,M) ARE COORDINATES OF ATOM # M IN SET Y       (GIVEN)
C  N    - N IS NUMBER OF ATOM PAIRS             (GIVEN)
C  MODE  - 0:CALCULATE RMS ONLY              (GIVEN)
C      1:CALCULATE RMS,U,T   (TAKES LONGER)
C  RMS   - SUM OF W*(UX+T-Y)**2 OVER ALL ATOM PAIRS        (RESULT)
C  U    - U(I,J) IS   ROTATION  MATRIX FOR BEST SUPERPOSITION  (RESULT)
C  T    - T(I)   IS TRANSLATION VECTOR FOR BEST SUPERPOSITION  (RESULT)
C  IER   - 0: A UNIQUE OPTIMAL SUPERPOSITION HAS BEEN DETERMINED(RESULT)
C     -1: SUPERPOSITION IS NOT UNIQUE BUT OPTIMAL
C     -2: NO RESULT OBTAINED BECAUSE OF NEGATIVE WEIGHTS W
C      OR ALL WEIGHTS EQUAL TO ZERO.
C
C-----------------------------------------------------------------------
      INTEGER    IP(9),IP2312(4),I,J,K,L,M1,M,IER,N,MODE
      REAL      W(*),X(3,*),Y(3,*),U(3,*),T(*),RMS,SIGMA
c      REAL*16     R(3,3),XC(3),YC(3),WC,A(3,3),B(3,3),E0,
c     1 E(3),E1,E2,E3,D,H,G,SPUR,DET,COF,CTH,STH,SQRTH,P,TOL,
c     2 RR(6),RR1,RR2,RR3,RR4,RR5,RR6,SS(6),SS1,SS2,SS3,SS4,SS5,SS6,
c     3 ZERO,ONE,TWO,THREE,SQRT3
C most UNIX machines know only real*8
C on VAX compile it with /G_Floating
      DOUBLE PRECISION     R(3,3),XC(3),YC(3),WC,A(3,3),B(3,3),E0,
     1     E(3),E1,E2,E3,D,H,G,SPUR,DET,COF,CTH,STH,SQRTH,P,TOL,
     2     RR(6),RR1,RR2,RR3,RR4,RR5,RR6,SS(6),SS1,SS2,SS3,SS4,SS5,SS6,
     3     ZERO,ONE,TWO,THREE,SQRT3
      EQUIVALENCE (RR1,RR(1)),(RR2,RR(2)),(RR3,RR(3)),
     1     (RR4,RR(4)),(RR5,RR(5)),(RR6,RR(6)),
     2     (SS1,SS(1)),(SS2,SS(2)),(SS3,SS(3)),
     3     (SS4,SS(4)),(SS5,SS(5)),(SS6,SS(6)),
     4     (E1,E(1)),(E2,E(2)),(E3,E(3))
      DATA SQRT3,TOL/1.73205080756888D+00, 1.0D-2/
      DATA ZERO,ONE,TWO,THREE/0.0D+00, 1.0D+00, 2.0D+00, 3.0D+00/
      DATA IP/1,2,4,  2,3,5,  4,5,6/
      DATA IP2312/2,3,1,2/
      WC=ZERO
      RMS=0.0
      E0=ZERO
      DO 1 I=1,3
      XC(I)=ZERO
      YC(I)=ZERO
      T(I)=0.0
      DO 1 J=1,3
      D=ZERO
      IF (I.EQ.J)D=ONE
      U(I,J)=real(D)
      A(I,J)=D
1     R(I,J)=ZERO
      IER=-1
      IF (N.LT.1)RETURN
C**** DETERMINE CENTROIDS OF BOTH VECTOR SETS X AND Y
      IER=-2
      DO 2 M=1,N
      IF (W(M).LT.0.0)RETURN
      WC=WC+W(M)
      DO 2 I=1,3
      XC(I)=XC(I)+W(M)*X(I,M)
2     YC(I)=YC(I)+W(M)*Y(I,M)
      IF (WC.LE.ZERO)RETURN
      DO 3 I=1,3
      XC(I)=XC(I)/WC
3     YC(I)=YC(I)/WC
C**** DETERMINE CORRELATION MATRIX R BETWEEN VECTOR SETS Y AND X
      DO 4 M=1,N
      DO 4 I=1,3
      E0=E0+W(M)*((X(I,M)-XC(I))**2+(Y(I,M)-YC(I))**2)
      D=W(M)*(Y(I,M)-YC(I))
      DO 4 J=1,3
4     R(I,J)=R(I,J)+D*(X(J,M)-XC(J))
C**** CALCULATE DETERMINANT OF R(I,J)
      DET=R(1,1)*(R(2,2)*R(3,3)-R(2,3)*R(3,2))
     1   -R(1,2)*(R(2,1)*R(3,3)-R(2,3)*R(3,1))
     2   +R(1,3)*(R(2,1)*R(3,2)-R(2,2)*R(3,1))
      SIGMA=real(DET)
C**** FORM UPPER TRIANGLE OF TRANSPOSED(R)*R
      M=0
      DO 5 J=1,3
      DO 5 I=1,J
      M=M+1
5     RR(M)=R(1,I)*R(1,J)+R(2,I)*R(2,J)+R(3,I)*R(3,J)
C***************** EIGENVALUES *****************************************
C**** FORM CHARACTERISTIC CUBIC  X**3-3*SPUR*X**2+3*COF*X-DET=0
      SPUR=(RR1+RR3+RR6)/THREE
      COF=(RR3*RR6-RR5*RR5+RR1*RR6-RR4*RR4+RR1*RR3-RR2*RR2)/THREE
      DET=DET*DET
      DO 6 I=1,3
6     E(I)=SPUR
      IF (SPUR.LE.ZERO)GOTO 40
C**** REDUCE CUBIC TO STANDARD FORM Y**3-3HY+2G=0 BY PUTTING X=Y+SPUR
      D=SPUR*SPUR
      H=D-COF
      G=(SPUR*COF-DET)/TWO-SPUR*H
C**** SOLVE CUBIC. ROOTS ARE E1,E2,E3 IN DECREASING ORDER
      IF (H.LE.ZERO)GOTO 8
      SQRTH=DSQRT(H)
c      SQRTH=QSQRT(H)
      D=H*H*H-G*G
      IF (D.LT.ZERO)D=ZERO
      D=DATAN2(DSQRT(D),-G)/THREE
      CTH=SQRTH*DCOS(D)
      STH=SQRTH*SQRT3*DSIN(D)
c      D=QATAN2(QSQRT(D),-G)/THREE
c      CTH=SQRTH*QCOS(D)
c      STH=SQRTH*SQRT3*QSIN(D)
      E1=SPUR+CTH+CTH
      E2=SPUR-CTH+STH
      E3=SPUR-CTH-STH
      IF (MODE)10,50,10
C HANDLE SPECIAL CASE OF 3 IDENTICAL ROOTS
8     IF (MODE)30,50,30
C**************** EIGENVECTORS *****************************************
10    DO 15 L=1,3,2
      D=E(L)
      SS1=(D-RR3)*(D-RR6)-RR5*RR5
      SS2=(D-RR6)*RR2+RR4*RR5
      SS3=(D-RR1)*(D-RR6)-RR4*RR4
      SS4=(D-RR3)*RR4+RR2*RR5
      SS5=(D-RR1)*RR5+RR2*RR4
      SS6=(D-RR1)*(D-RR3)-RR2*RR2
      J=1
      IF (DABS(SS1).GE.DABS(SS3))GOTO 12
c      IF (QABS(SS1).GE.QABS(SS3))GOTO 12
      J=2
      IF (DABS(SS3).GE.DABS(SS6))GOTO 13
c      IF (QABS(SS3).GE.QABS(SS6))GOTO 13
11    J=3
      GOTO 13
12    IF (DABS(SS1).LT.DABS(SS6))GOTO 11
c12    IF (QABS(SS1).LT.QABS(SS6))GOTO 11
13    D=ZERO
      J=3*(J-1)
      DO 14 I=1,3
      K=IP(I+J)
      A(I,L)=SS(K)
14    D=D+SS(K)*SS(K)
      IF (D.GT.ZERO)D=ONE/DSQRT(D)
c      IF (D.GT.ZERO)D=ONE/QSQRT(D)
      DO 15 I=1,3
15    A(I,L)=A(I,L)*D
      D=A(1,1)*A(1,3)+A(2,1)*A(2,3)+A(3,1)*A(3,3)
      M1=3
      M=1
      IF ((E1-E2).GT.(E2-E3))GOTO 16
      M1=1
      M=3
16    P=ZERO
      DO 17 I=1,3
      A(I,M1)=A(I,M1)-D*A(I,M)
17    P=P+A(I,M1)**2
      IF (P.LE.TOL)GOTO 19
      P=ONE/DSQRT(P)
c      P=ONE/QSQRT(P)
      DO 18 I=1,3
18    A(I,M1)=A(I,M1)*P
      GOTO 21
19    P=ONE
      DO 20 I=1,3
      IF (P.LT.DABS(A(I,M)))GOTO 20
      P=DABS(A(I,M))
c      IF (P.LT.QABS(A(I,M)))GOTO 20
c      P=QABS(A(I,M))
      J=I
20    CONTINUE
      K=IP2312(J)
      L=IP2312(J+1)
      P=DSQRT(A(K,M)**2+A(L,M)**2)
c      P=QSQRT(A(K,M)**2+A(L,M)**2)
      IF (P.LE.TOL)GOTO 40
      A(J,M1)=ZERO
      A(K,M1)=-A(L,M)/P
      A(L,M1)=A(K,M)/P
21    A(1,2)=A(2,3)*A(3,1)-A(2,1)*A(3,3)
      A(2,2)=A(3,3)*A(1,1)-A(3,1)*A(1,3)
      A(3,2)=A(1,3)*A(2,1)-A(1,1)*A(2,3)
C****************** ROTATION MATRIX ************************************
30    DO 32 L=1,2
      D=ZERO
      DO 31 I=1,3
      B(I,L)=R(I,1)*A(1,L)+R(I,2)*A(2,L)+R(I,3)*A(3,L)
31    D=D+B(I,L)**2
      IF (D.GT.ZERO)D=ONE/DSQRT(D)
c      IF (D.GT.ZERO)D=ONE/QSQRT(D)
      DO 32 I=1,3
32    B(I,L)=B(I,L)*D
      D=B(1,1)*B(1,2)+B(2,1)*B(2,2)+B(3,1)*B(3,2)
      P=ZERO
      DO 33 I=1,3
      B(I,2)=B(I,2)-D*B(I,1)
33    P=P+B(I,2)**2
      IF (P.LE.TOL)GOTO 35
      P=ONE/DSQRT(P)
c      P=ONE/QSQRT(P)
      DO 34 I=1,3
34    B(I,2)=B(I,2)*P
      GOTO 37
35    P=ONE
      DO 36 I=1,3
      IF (P.LT.DABS(B(I,1)))GOTO 36
      P=DABS(B(I,1))
c      IF (P.LT.QABS(B(I,1)))GOTO 36
c      P=QABS(B(I,1))
      J=I
36    CONTINUE
      K=IP2312(J)
      L=IP2312(J+1)
      P=DSQRT(B(K,1)**2+B(L,1)**2)
c      P=QSQRT(B(K,1)**2+B(L,1)**2)
      IF (P.LE.TOL)GOTO 40
      B(J,2)=ZERO
      B(K,2)=-B(L,1)/P
      B(L,2)= B(K,1)/P
37    B(1,3)=B(2,1)*B(3,2)-B(2,2)*B(3,1)
      B(2,3)=B(3,1)*B(1,2)-B(3,2)*B(1,1)
      B(3,3)=B(1,1)*B(2,2)-B(1,2)*B(2,1)
      DO 39 I=1,3
      DO 39 J=1,3
39    U(I,J)=real( B(I,1)*A(J,1)+B(I,2)*A(J,2)+B(I,3)*A(J,3) )
C****************** TRANSLATION VECTOR *********************************
40    DO 41 I=1,3
41    T(I)=real ( YC(I)-U(I,1)*XC(1)-U(I,2)*XC(2)-U(I,3)*XC(3) )
C********************** RMS ERROR **************************************
50    DO 51 I=1,3
      IF (E(I).LT.ZERO)E(I)=ZERO
51    E(I)=DSQRT(E(I))
c51    E(I)=QSQRT(E(I))
      IER=0
      IF (E2.LE.(E1*1.0D-05))IER=-1
      D=E3
      IF (SIGMA.GE.0.0)GOTO 52
      D=-D
      IF ((E2-E3).LE.(E1*1.0D-05))IER=-1
52    D=D+E2+E1
      RMS=real( E0-D-D )
      IF (RMS.LT.0.0)RMS=0.0
C next line added June 1989 by Georg Tuparev
      RMS=SQRT(RMS/N)
      RETURN
      END
C     END U3B
C......................................................................

C......................................................................
C     SUB UNTAB
      SUBROUTINE UNTAB(STRING)
C removes 'tabs' from a string

      PARAMETER      (LINESIZE=                300)
      CHARACTER       STRING*(*)
      CHARACTER       TEMPLINE*(LINESIZE) 
      INTEGER         LENGTH,I,J,TABSIZE
*----------------------------------------------------------------------*

      TABSIZE=8
      J=0
      I=1
      LENGTH=LEN(STRING)
      IF (LENGTH .GT. LINESIZE) THEN
         WRITE(6,*)'*** UNTAB: string truncated'
         LENGTH=LINESIZE
      ENDIF
      DO WHILE(I .LE. LENGTH)
         J=J+1
         IF (J .LE. LINESIZE) THEN
	    IF (STRING(I:I) .NE. CHAR(9) ) THEN
	       TEMPLINE(J:J)=STRING(I:I)
	    ELSE
               TEMPLINE(J:J)=' '
               DO WHILE( MOD(J,TABSIZE) .NE. 0)
                  J=J+1
                  IF (J .LE. LINESIZE)TEMPLINE(J:J)=' '
               ENDDO
	    ENDIF
         ENDIF
         I=I+1
      ENDDO
	
      STRING(1:LENGTH)=TEMPLINE(1:LENGTH)
      RETURN
      END
C     END UNTAB
C......................................................................

C......................................................................
C     SUB UPTOLOW
      SUBROUTINE UPTOLOW(STRING,LENGTH)
      CHARACTER*(*) STRING
      INTEGER LENGTH
cx      CHARACTER UPPER*26, LOWER*26, STRING*(*)
cx      CHARACTER UPPER*26, LOWER*26, STRING*(*)
cx      DATA UPPER/'ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
cx      DATA LOWER/'abcdefghijklmnopqrstuvwxyz'/

      DO I=1,LENGTH
         IF (STRING(I:I).GE.'A' .AND. STRING(I:I).LE.'Z') THEN
            STRING(I:I)=CHAR( ICHAR(STRING(I:I))+32 )
C     X	     K=INDEX(UPPER,STRING(I:I))
C     X	     IF (K.NE.0) STRING(I:I)=LOWER(K:K)
         ENDIF
      ENDDO
      RETURN
      END
C     END UPTOLOW
C......................................................................

C......................................................................
C     SUB MP_INIT_FARM
C init a farmer worker model
C VAX/VMS dummy version ; does nothing ; just init the stuff
      SUBROUTINE MP_INIT_FARM()

      IMPLICIT      NONE
C import
      INTEGER       MAXPROC
      CHARACTER*200 HOST_FILE,HOST_NAME,NODE_NAME
C export
      INTEGER       IDPROC,NWORKER,NP,NWORKSET,
     +     IDTOP,LINK(1:100),ID_HOST,
     +     LINK_HOST,LINK_NODE_SENDER,LINK_NODE_RECEIVER,
     +     SENDER_NODE(1:100),RECEIVER_NODE(1:100),
     +     WORKSETSIZE(1:100),WORKSETBEG(1:100),WORKSETEND(1:100)
      CHARACTER*20  MP_MODEL
      LOGICAL       LMIXED_ARCH
C init
      MP_MODEL='NIX'
      ID_HOST=0
      IDPROC=0
      IDTOP=0
      LINK_HOST=0
      LINK_NODE_SENDER=0
      LINK_NODE_RECEIVER=0
      NWORKER=0
      NWORKSET=0
      LINK(1) = 0
      LMIXED_ARCH=.FALSE.
      RETURN
      END
C     END MP_INIT_FARM
C

C......................................................................
C     SUB MP_INIT_NODE
      SUBROUTINE MP_INIT_NODE(NODE_NAME,IDPROC)
      CHARACTER*(*) NODE_NAME
      INTEGER       IDPROC
      RETURN
      END
C     end mp_init_node
C......................................................................

C......................................................................
C     sub mp_getmyid
C get ID of process
C VAX/VMS dummy version ; return id=0
      SUBROUTINE MP_GETMYID(ID)
      INTEGER ID
      ID=0
      RETURN
      END
C     END MP_GETMYID
C......................................................................

C......................................................................
C     SUB MP_NPROCS
C get number of processors
C VAX/VMS dummy version ; nprocessor=1
      SUBROUTINE MP_NPROCS(NPROCESSOR)
      INTEGER NPROCESSOR
      NPROCESSOR=1
      RETURN
      END
C     END MP_NPROCS
C......................................................................

C......................................................................
C     SUB MP_SELECT
C is there somewhere a message for me ?
C VAX/VMS dummy version ;
      SUBROUTINE MP_SELECT(MSGTYPE,WORKSETBEG,WORKSETEND,LINK,IFLAG)
C import
      INTEGER MSGTYPE,WORKSETBEG,WORKSETEND,LINK(*)
C export
      INTEGER IFLAG
      IFLAG=0
      RETURN
      END
C     END MP_SELECT
C......................................................................

C......................................................................
C     SUB MP_SELECT_SUBSET
C is there somewhere a message for me ?
C VAX/VMS dummy version ;
      SUBROUTINE MP_SELECT_SUBSET(MSGTYPE,NWORKSET,SENDER_NODE,
     +     LINK,IFLAG)
C import
      INTEGER MSGTYPE,NWORKSET,SENDER_NODE(*),LINK(*)
      INTEGER IFLAG
      IFLAG=0
      RETURN
      END
C     end mp_select_subset
C......................................................................

C......................................................................
C     sub mp_init_send
C dummy version
      SUBROUTINE MP_INIT_SEND()
      
      RETURN
      END
C     end mp_init_send
C......................................................................

C......................................................................
C     sub mp_send_data
C dummy version
      SUBROUTINE MP_SEND_DATA(MSGTYPE,RECEIVER_NAME)
C input
      INTEGER MSGTYPE,LINK
      CHARACTER*(*) RECEIVER_NAME
      RETURN
      END
C     end mp_send_data
C......................................................................

C......................................................................
C     sub mp_init_receive
C dummy version
      SUBROUTINE MP_INIT_RECEIVE(MSGTYPE)
      INTEGER MSGTYPE
      RETURN
      END
C     end mp_init_receive
C......................................................................

C......................................................................
C     sub mp_receive_data
C dummy version
      SUBROUTINE MP_RECEIVE_DATA(MSGTYPE,LINK)
C input
      INTEGER MSGTYPE
C output
      INTEGER LINK
      RETURN
      END
C     end mp_receive_data
C......................................................................

C......................................................................
C     sub mp_put_int4
C VAX/VMS dummy version ; does nothing
      SUBROUTINE MP_PUT_INT4(IDTOP,LINK,DATA,NBYTE)
      INTEGER IDTOP,LINK,DATA(*),NBYTE
      RETURN
      END
C     end mp_put_int4
C......................................................................

C......................................................................
C     sub mp_get_int4
C VAX/VMS dummy version ; does nothing
      SUBROUTINE MP_GET_INT4(IDTOP,LINK,DATA,NBYTE)
      INTEGER IDTOP,LINK,NBYTE,DATA(*)
      RETURN
      END
C     end mp_get_int4
C......................................................................

C......................................................................
C     sub mp_put_real4
C VAX/VMS dummy version ; does nothing
      SUBROUTINE MP_PUT_REAL4(IDTOP,LINK,DATA,NBYTE)
      INTEGER IDTOP,LINK,NBYTE
      REAL DATA(*)
      RETURN
      END
C     end mp_put_real4
C......................................................................

C......................................................................
C     sub mp_get_real4
C VAX/VMS dummy version ; does nothing
      SUBROUTINE MP_GET_REAL4(IDTOP,LINK,DATA,NBYTE)
      INTEGER IDTOP,LINK,NBYTE
      REAL DATA(*)
      RETURN
      END
C     end mp_get_real4
C......................................................................

C......................................................................
C     sub mp_put_string_array
C dummy version
      SUBROUTINE MP_PUT_STRING_ARRAY(IDTOP,LINK,DATA,NDIM)
      INTEGER IDTOP,LINK,NDIM,INFO
      CHARACTER*(*) DATA(NDIM)
      RETURN
      END
C     end mp_put_string_array
C......................................................................

C......................................................................
C     sub mp_put_string
C dummy version
      SUBROUTINE MP_PUT_STRING(IDTOP,LINK,DATA,ILEN)
      INTEGER IDTOP,LINK,ILEN,INFO
      CHARACTER*(*) DATA
      RETURN
      END
C     end mp_put_string
C......................................................................

C......................................................................
C     sub mp_get_string_array
C dummy version
      SUBROUTINE MP_GET_STRING_ARRAY(IDTOP,LINK,DATA,NDIM)
      INTEGER IDTOP,LINK,NDIM,INFO
      CHARACTER*(*) DATA(NDIM)
      RETURN
      END
C     end mp_get_string_array
C......................................................................

C......................................................................
C     sub mp_get_string
C dummy version
      SUBROUTINE MP_GET_STRING(IDTOP,LINK,DATA,ILEN)
      INTEGER IDTOP,LINK,ILEN,INFO
      CHARACTER*(*) DATA
      RETURN
      END
C     end mp_get_string
C......................................................................

C......................................................................
C     SUB MP_LEAVE
      SUBROUTINE MP_LEAVE()
      RETURN
      END
C     END MP_LEAVE
C......................................................................

C......................................................................
C     sub mp_probe
C is there somewhere a message for me ?
C if not, return
C PVM version
      SUBROUTINE MP_PROBE(MSGTYPE,IFLAG)
C import
      INTEGER MSGTYPE
C export
      INTEGER IFLAG
      IFLAG=0
      RETURN
      END
C     end mp_probe
C......................................................................

C......................................................................
C     sub mp_get_int4
C PVM version
      SUBROUTINE MP_GET_INT4_ARRAY(IDTOP,LINK,DATA,NDATA)
      INTEGER IDTOP,LINK,NDATA,DATA(*)
      INTEGER INFO
      RETURN
      END
C     end mp_get_int4
C......................................................................

C......................................................................
C     sub mp_put_int4
C PVM version
      SUBROUTINE MP_PUT_INT4_ARRAY(IDTOP,LINK,DATA,NDATA)
      INTEGER IDTOP,LINK,DATA(*),NDATA
      INTEGER INFO
      RETURN
      END
C     end mp_put_int4
C......................................................................

C......................................................................
C     sub mp_get_real4
C PVM version
      SUBROUTINE MP_GET_REAL4_ARRAY(IDTOP,LINK,DATA,NDATA)
      INTEGER IDTOP,LINK,NDATA
      REAL DATA(*)
      INTEGER INFO
      RETURN
      END
C     end mp_get_real4
C......................................................................

C......................................................................
C     sub mp_put_real4
C PVM version
      SUBROUTINE MP_PUT_REAL4_ARRAY(IDTOP,LINK,DATA,NDATA)
      INTEGER IDTOP,LINK,NDATA
      REAL DATA(*)
      INTEGER INFO
      RETURN
      END
C     end mp_put_real4
C......................................................................

C......................................................................
C     sub mp_cast
C PVM version
      SUBROUTINE MP_CAST(NTASKS,MSGTYPE,LINK)
C input
      INTEGER NTASKS,MSGTYPE,LINK(*)
C internal
      INTEGER INFO
      RETURN
      END
C     end mp_cast
C......................................................................

