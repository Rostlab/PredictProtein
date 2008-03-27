*----------------------------------------------------------------------*
*                                                                      *
*     FORTRAN code for program CONVERT_SEQ                             *
*             conversion of sequence and alignment formats             *
*                                                                      *
*----------------------------------------------------------------------*
*                                                                      *
*     Authors:                                                         *
*                                                                      *
*     Reinhard Schneider        Mar,        1991      version 1.0      *
*     Ulrike Goebel             Mar,        1997      version 1.1      *
*     Reinhard Schneider        Mar,        1997      version 2.0      *
*     LION			http://www.lion-ag/                    *
*     D-69120 Heidelberg	schneider@lion-ag.de                   *
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
*                                                                      *
*----------------------------------------------------------------------*

      PROGRAM CONVERT_SEQ

      IMPLICIT        NONE
C----
C---- parameters
C----
      INTEGER         MAXRES,MAXCHAIN,MAXINS,MAXINSBUF,IN,OUT,
     +                CODELEN,MAXALIGNS,MAXCORE,MAXAA,MAX_NAME_LEN
      PARAMETER      (MAXRES=                10000)
      PARAMETER      (MAXALIGNS=             19999)
      PARAMETER      (MAXINS=                50000)
      PARAMETER      (MAXINSBUF=            200000)
      PARAMETER      (MAXCORE=             2888888)
      PARAMETER      (MAXCHAIN=                 50)
      PARAMETER      (CODELEN=                  40)
      PARAMETER      (MAXAA=                    20)
      PARAMETER      (MAX_NAME_LEN=            200)
C     only used to get rid of INDEX command (CPU time)
      INTEGER         NASCII
      PARAMETER      (NASCII=                  256)
C     files
      PARAMETER      (IN=                       12)
      PARAMETER      (OUT=                      14)
 
      INTEGER         ISTART,ISTOP,NBLOCKS,NSYMBOLS,NBREAKS,NREAD,
     +                IALIGN, CHANGEPOS,NCHAIN,KCHAIN,NRES,CALLS,
     +                NTRIALS,NRESTMP
      INTEGER         RANGE(2),CHBPOS(MAXCHAIN-1)

      CHARACTER*1     C,CGAPCHAR,CGAPCHARPIR
      CHARACTER*(4*MAXCHAIN)   CCHAIN
      CHARACTER*(MAXRES) SEQ,  STRUC
      CHARACTER*(MAX_NAME_LEN) FILENAME,BASENAME,OUTNAME,TEMPNAME,
     +                VARMETRIC
      CHARACTER*130   QUESTION
      CHARACTER       ACCNUM*80,PDBREF*10,TRANS*26,INFORMAT*4,
     +                OUTFORMAT*1
      LOGICAL         LFILTER,LINSERT,LDELETE,LDOEXP, LDOCLIP,
     +                TRUNCATED, ERROR,MULTFORMAT, DO_INIT_INSBUF
C MSFTOSEQ
C     pointer arrays: ifir(i) begin of PDBSEQ against alignment i
      INTEGER         IFIR(MAXALIGNS),ILAS(MAXALIGNS),
     +                ALIPOINTER(MAXALIGNS),
     +                NALIGN, ALILEN,MSFCHECK,SEQCHECK(MAXALIGNS)
      CHARACTER*(CODELEN) PDBNAME
      CHARACTER       ALISEQ(MAXCORE)
      CHARACTER*1     TYPE
      REAL            WEIGHT(MAXALIGNS)
C READHSSP
      LOGICAL         LCONSERV,LOLDVERSION,LHSSP_LONG_ID
C attributes of sequence with known structure
      CHARACTER       PDBSEQ(MAXRES),CHAINID(MAXRES),
     +                SECSTR_HSSP(MAXRES),SHEETLABEL(MAXRES)
      CHARACTER*7     COLS(MAXRES)
      CHARACTER*12    PDBID
      CHARACTER*40    HEADER
      CHARACTER*400   COMPND,SOURCE,AUTHOR,CHAINREMARK
      INTEGER         PDBNO(MAXRES),BP1(MAXRES),BP2(MAXRES),ACC(MAXRES)
C attributes of aligned sequences

C     flags (take ' ', else other)
      CHARACTER       EXCLUDEFLAG(MAXALIGNS)
      CHARACTER*5     STRID(MAXALIGNS)
      CHARACTER*10    ACCNUM_HSSP(MAXALIGNS)
      CHARACTER*40    EMBLID(MAXALIGNS)
      CHARACTER*60    PROTNAME(MAXALIGNS)
      INTEGER         JFIR(MAXALIGNS),JLAS(MAXALIGNS),LALI(MAXALIGNS),
     +                NGAP(MAXALIGNS),LGAP(MAXALIGNS),LENSEQ(MAXALIGNS),
     +                INSNUMBER,INSALI(MAXINS),INSPOINTER(MAXINS),
     +                INSLEN(MAXINS),INSBEG_1(MAXINS),INSBEG_2(MAXINS)
      REAL            IDE(MAXALIGNS),SIM(MAXALIGNS)
      CHARACTER       INSBUFFER(MAXINSBUF)
C attributes of profile
      INTEGER         VAR(MAXRES),SEQPROF(MAXRES,MAXAA),NOCC(MAXRES),
     +                NDEL(MAXRES),NINS(MAXRES),RELENT(MAXRES)
      REAL            ENTROPY(MAXRES)
      REAL            CONSWEIGHT(MAXRES),CONSWEIGHT_MIN
C threshold  
      INTEGER         I
C----
C----
C---- end of settings
C---- ------------------------------------------------------------------
C----
C---- ------------------------------------------------------------------
C     initialisation
      NTRIALS=       0
      CALLS=         1
      CGAPCHAR=      '.'
      CGAPCHARPIR=   '-'
      OUTNAME=       ' '
      LCONSERV=      .FALSE.
      LOLDVERSION=   .FALSE.
      LHSSP_LONG_ID= .FALSE.
      VARMETRIC=     '/home/rost/pub/max/mat/Maxhom_GCG.metric'
      DO_INIT_INSBUF=.TRUE.
      TRANS=         'VLIMFWYGAPSTCHRKQENDBZX!-'
      TEMPNAME=      ' '

      CONSWEIGHT_MIN=0.01

C-----------------------------------------------------------------------
c        tempname = '/data/hssp/1acx.hssp'
 1    CALL GETCHAR(MAX_NAME_LEN, TEMPNAME, 
     +     ' Name of input sequence file :')
C-----------------------------------------------------------------------
      CALL EXTRACT_CHAINS(TEMPNAME,FILENAME,MAXCHAIN,CCHAIN)
      CALL CHECKFORMAT(IN,FILENAME,INFORMAT,ERROR)
      IF ( ERROR ) THEN
         IF ( NTRIALS .LT. 3 ) THEN
            NTRIALS = NTRIALS + 1
            GOTO 1
         ELSE
            STOP 'NO VALID SEQUENCE FILE GIVEN ! '
         ENDIF
      ENDIF
      CALL GETPIDCODE(FILENAME,BASENAME)

C-----------------------------------------------------------------------
c...read sequence(s)
 
      MULTFORMAT = .FALSE.
      CALL STRPOS(INFORMAT,ISTART,ISTOP)
      IF ( INFORMAT(ISTART:ISTOP) .EQ. 'HSSP' ) THEN
         MULTFORMAT = .TRUE.
         CALL READHSSP(IN,FILENAME,ERROR,MAXRES,MAXALIGNS,
     +        MAXCORE,MAXINS,MAXINSBUF,PDBID,HEADER,COMPND,
     +        SOURCE,AUTHOR,ALILEN,NCHAIN,KCHAIN,CHAINREMARK,
     +        NALIGN,EXCLUDEFLAG,EMBLID,STRID,IDE,SIM,IFIR,
     +        ILAS,JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,ACCNUM_HSSP,
     +        PROTNAME,PDBNO,PDBSEQ,CHAINID,SECSTR_HSSP,
     +        COLS,SHEETLABEL,BP1,BP2,ACC,NOCC,VAR,ALISEQ,
     +        ALIPOINTER,SEQPROF,NDEL,NINS,ENTROPY,RELENT,
     +        CONSWEIGHT,INSNUMBER,INSALI,INSPOINTER,INSLEN,
     +        INSBEG_1,INSBEG_2,INSBUFFER,LCONSERV,
     +        LHSSP_LONG_ID)
         IF (ERROR) THEN
            WRITE(6,*)' *** ERROR reading HSSP-file:',FILENAME
            STOP '*** ERROR reading HSSP-file'
            GOTO 1
         ENDIF
         ALILEN = ALILEN + KCHAIN - 1
         CALL MARK_DUPLICATES(EMBLID,NALIGN)

      ELSE IF ( INFORMAT(ISTART:ISTOP) .EQ. 'MSF' ) THEN
         MULTFORMAT = .TRUE.
         CALL READ_MSF(IN,FILENAME,MAXALIGNS,MAXCORE,ALISEQ,
     1        ALIPOINTER,IFIR,ILAS,JFIR,JLAS,TYPE,EMBLID,
     2        WEIGHT,SEQCHECK,MSFCHECK,ALILEN,NALIGN,ERROR)
         IF (ERROR) THEN
            WRITE(*,*)'*** ERROR READING MSF-FILE:',FILENAME
            GOTO 1
            STOP '*** ERROR reading MSF-file'
         ENDIF
      ELSE
         SEQ = ' '
         CALL GET_SEQ(IN,FILENAME,TRANS,CCHAIN,
     +        COMPND,ACCNUM,PDBREF,PDBNO,NRES,SEQ,
     +        STRUC,ACC,TRUNCATED,ERROR)
         IF ( ERROR ) THEN
            WRITE(6,*)'*** ERROR in GET_SEQ for file=',FILENAME
            STOP
         ENDIF
      ENDIF
C--------------------------------------------------------------------

      RANGE(1) = 1
      IF ( MULTFORMAT ) THEN
         RANGE(2) = ALILEN
      ELSE
         RANGE(2) = NRES
         CALL CHAINBREAKPOS( SEQ,RANGE(1),RANGE(2),MAXCHAIN-1,
     1        NBREAKS,CHBPOS, ERROR )
         IF ( ERROR ) STOP
      ENDIF
C-------------------select output format------------------------------
 
C return label for next choice of format
 2    CONTINUE

      IF  ( MULTFORMAT ) THEN
         OUTFORMAT = 'm'
         CALL GETCHAR (1,OUTFORMAT,
     +        'Output-format? [*m*]: m = MSF/n'                  //
     +        '                      h = HSSP/n'                 //
     +        '                      p = PIR/n'                  //
     +        '                      f = FASTA/Pearson/n'        //
     +        '                      d = DAF/n'        //
     +        '                      y = PHYLIP ' )
      ELSE
         OUTFORMAT = 'g'
         CALL GETCHAR (1,OUTFORMAT,
     1        'Output-format? [*g*]: g = GCG/n'                    //
     2        '                      a = Alb/n'                    //
     3        '                      k = Klein (old-NBRF-format)/n'//
     4        '                      p = PIR/n'                    //
     5        '                      e = EMBL/SWISS/n'             //
     6        '                      s = star/n'                   //
     7        '                      f = FASTA/Pearson ' )
      ENDIF
      CALL LOWTOUP(OUTFORMAT,1)
C-----------------------------------------------------------------------
      IF ( OUTFORMAT .EQ. 'H' ) THEN
         CALL GETCHAR(MAX_NAME_LEN,VARMETRIC,
     1        ' use which metric file for variability calculation ? ' )
         CALL STRPOS(INFORMAT,ISTART,ISTOP)
         IF ( INFORMAT(ISTART:ISTOP) .EQ. 'MSF' ) THEN
            C = 'N'
C            LDOCLIP=.FALSE.
            CALL GETCHAR(1,C,
     1           ' treat gaps in master sequence as insertions ? ')
            CALL LOWTOUP(C,1)
C            IF (C .EQ. 'Y') LDOCLIP=.TRUE.
            LDOCLIP = C .EQ. 'Y'
         ENDIF
      ELSE
c...select residue range

         RANGE(1) = 1
         IF ( MULTFORMAT ) THEN
            RANGE(2)= ALILEN
            QUESTION=
     1      'Do you want to select a fragment of this alignment?[*N*]'
         ELSE
            RANGE(2)= NRES
            QUESTION=
     1      'Do you want to select a fragment of this protein?[*N*]'
         ENDIF
         NRESTMP=RANGE(2)
         CALL STRPOS(INFORMAT,ISTART,ISTOP)
         C = 'N'
         CALL GETCHAR(1,C,QUESTION)
         CALL LOWTOUP(C,1)
         IF ( C .NE. 'N' .AND. C .NE. ' ') THEN
            CALL GETINT
     1           (2,RANGE,
     2           ' Enter residue numbers of fragment start and stop: ')
C----            br 98.05: correct for too high
            IF (RANGE(2).GT.NRESTMP) THEN
               RANGE(2)= MIN(RANGE(2),NRESTMP)
               WRITE(6,'(A,I5)')' *** oops, 2nd number too large, '//
     +              'corrected to: ',RANGE(2)
            END IF
            IF (RANGE(1).GT.NRESTMP) THEN
               RANGE(1)= 1
               WRITE(6,'(A,I5)')' *** oops, 1st number too large, '//
     +              'corrected to: ',RANGE(1)
            END IF
            IF (RANGE(1).EQ.RANGE(2)) THEN
               WRITE(6,'(A,I5,A3,I5)')' *** oops you wanted: ',
     +              RANGE(1),' - ',RANGE(2)
               RANGE(1)=1
               RANGE(2)=NRESTMP
               WRITE(6,'(A,I5,A3,I5)')' *** was deemed strange and'//
     +              ' corrected to: ',RANGE(1),' - ',RANGE(2)
            END IF
         ENDIF
      ENDIF
C-----------------------------------------------------------------------
c...make up a default name for outfile

      CALL STRPOS(BASENAME,ISTART,ISTOP)
      IF ( OUTFORMAT .EQ. 'M' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.msf'
      ELSE IF ( OUTFORMAT .EQ. 'H' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.hssp'
      ELSE IF ( OUTFORMAT .EQ. 'D' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.daf'
      ELSE IF ( OUTFORMAT .EQ. 'P' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.pir'
C        else if ( outformat .eq. 'F' ) then
C           outname = basename(istart:istop) // '.pearson'
      ELSE IF ( OUTFORMAT .EQ. 'F' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.f'
      ELSE IF ( OUTFORMAT .EQ. 'S' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.star'
      ELSE IF ( OUTFORMAT .EQ. 'A' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.alb'
      ELSE IF ( OUTFORMAT .EQ. 'K' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.klein'
      ELSE IF ( OUTFORMAT .EQ. 'E' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.embl'
      ELSE IF ( OUTFORMAT .EQ. 'G' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.gcg'
C        else if ( outformat .eq. 'Y' ) then
C           outname = basename(istart:istop) // '.phylip'
      ELSE IF ( OUTFORMAT .EQ. 'Y' ) THEN
         OUTNAME = BASENAME(ISTART:ISTOP) // '.phy'
      ENDIF
      CALL GETCHAR(MAX_NAME_LEN,OUTNAME,' output file name ?' )
C-----------------------------------------------------------------------
      CALL OPEN_FILE(OUT,OUTNAME,'new',error)
      IF ( ERROR ) STOP
C-----------------------------------------------------------------------

C----
C---- --------------------------------------------------
C---- alignment formats
C---- --------------------------------------------------
C----
      IF ( MULTFORMAT ) THEN
         IF ( CALLS .EQ. 1 ) THEN
            CALL STRPOS(INFORMAT,ISTART,ISTOP)

            IF ( INFORMAT(ISTART:ISTOP) .EQ. 'HSSP' ) THEN
C msftoseq does not care about lowercase letters !
               DO I=1,ALILEN
                  IF(PDBSEQ(I) .EQ. '!')THEN
                     PDBSEQ(I)= CGAPCHAR
                  ENDIF
               ENDDO
c	         call CHARARRAYREPL(pdbseq,alilen,'!',cgapchar)
               CALL DSSP_NOTATION_TO_CYS(PDBSEQ,ALILEN)
 
C pdbseq will be "changepos"th sequence in aliseq
               PDBNAME = PDBID

               CALL LEFTADJUST(PDBNAME,1,CODELEN)
               CHANGEPOS = 1
               LINSERT = .TRUE.
               LDELETE = .FALSE.

               CALL CHANGE_ALISEQ(MAXALIGNS,MAXCORE,MAXINS,MAXRES,
     +              LINSERT,LDELETE,CHANGEPOS,NALIGN,
     1              PDBSEQ,1,ALILEN,PDBNAME,
     2              ALILEN,ALISEQ,ALIPOINTER,IFIR,ILAS,JFIR,JLAS,
     3              LALI,NGAP,LGAP,LENSEQ,STRID,IDE,SIM,EXCLUDEFLAG,
     4              ACCNUM_HSSP,EMBLID,PROTNAME,INSALI,INSNUMBER)
               
               IF (OUTFORMAT .NE. 'D')THEN
                  DO IALIGN = 1,NALIGN
                     WEIGHT(IALIGN) = 1.0
                  ENDDO
               ENDIF
            ENDIF
         ENDIF

         IF ( OUTFORMAT .EQ. 'P' ) THEN
            NSYMBOLS = 30
            DO IALIGN = 1,NALIGN
               CALL GET_SEQ_FROM_ALISEQ(ALISEQ,IFIR,ILAS,
     1              ALIPOINTER,ALILEN,IALIGN,SEQ,NREAD,
     2              ERROR )
               IF ( ERROR ) STOP
               CALL STRREPLACE(SEQ,ALILEN,CGAPCHAR,CGAPCHARPIR)
               CALL WRITE_PIR(OUT,SEQ,FILENAME,OUTNAME,ACCNUM,
     1              EMBLID(IALIGN),NSYMBOLS,RANGE(1),
     2              RANGE(2),ERROR)
               IF ( ERROR ) STOP
            ENDDO
C---- 
C----    out HSSP
C----
         ELSE IF ( OUTFORMAT .EQ. 'H' ) THEN
C even if chains are not regularily counted, dont have "nchain=0"
C .... in the header!
            NCHAIN = 1
            CALL MAKE_HSSP(MAXRES,MAXALIGNS,MAXCORE,
     +           MAXAA,MAXINS,MAXINSBUF,
     +           OUT,OUTNAME,FILENAME,PDBID,HEADER,
     +           COMPND,SOURCE,AUTHOR,ALILEN,NCHAIN,KCHAIN,
     +           CHAINREMARK,NALIGN,EXCLUDEFLAG,EMBLID,STRID,
     +           IDE,SIM,IFIR,ILAS,JFIR,JLAS,LALI,NGAP,LGAP,
     +           LENSEQ,ACCNUM_HSSP,PROTNAME,PDBNO,PDBSEQ,CHAINID,
     +           SECSTR_HSSP,COLS,SHEETLABEL,BP1,BP2,ACC,NOCC,
     +           VAR,ALISEQ,ALIPOINTER,SEQPROF,NDEL,NINS,ENTROPY,
     +           RELENT,CONSWEIGHT_MIN,CONSWEIGHT,LCONSERV,LOLDVERSION,
     +           CGAPCHAR,LFILTER,VARMETRIC,LDOCLIP,
     +           INSNUMBER,INSALI,INSPOINTER,INSLEN,INSBEG_1,
     +           INSBEG_2,INSBUFFER,DO_INIT_INSBUF,ERROR,
     $           LHSSP_LONG_ID)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'Y' ) THEN
            NBLOCKS = 5
            CALL WRITE_PHYLIP(OUT,MAXALIGNS,MAXCORE,RANGE(1),
     1           RANGE(2),NBLOCKS,ALISEQ,ALIPOINTER,
     2           IFIR,ILAS,EMBLID,NALIGN,ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'M' ) THEN
            TYPE = 'P'
            NBLOCKS = 5
            CALL STRPOS(INFORMAT,ISTART,ISTOP)
            IF ( INFORMAT(ISTART:ISTOP) .EQ. 'HSSP' ) THEN
               C = 'N'
               CALL GETCHAR(1,C,
     1        ' Expand sequences according to HSSP insertion list ? ')
               CALL LOWTOUP(C,1)
               LDOEXP = C .EQ. 'Y'
            ELSE
               LDOEXP = .FALSE.
            ENDIF
C	      call write_msf(out,filename,outname,MAXALIGNS,MAXRES,

            CALL WRITE_MSF(OUT,FILENAME,OUTNAME,MAXALIGNS,MAXRES,
     1           MAXCORE,MAXINS,MAXINSBUF,RANGE(1),RANGE(2),NBLOCKS,
     2           ALISEQ,ALIPOINTER,IFIR,ILAS,TYPE,EMBLID,WEIGHT,
     3           SEQCHECK,MSFCHECK,ALILEN,NALIGN,INSNUMBER,INSALI,
     4           INSPOINTER,INSLEN,INSBEG_1,INSBUFFER,
     5           LDOEXP,ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'D' ) THEN
            TYPE = 'P'
            NBLOCKS = 1
            CALL STRPOS(INFORMAT,ISTART,ISTOP)
            IF ( INFORMAT(ISTART:ISTOP) .EQ. 'HSSP' ) THEN
               LDOEXP = .TRUE.
            ENDIF
            CALL WRITE_DAF(OUT,FILENAME,OUTNAME,MAXALIGNS,MAXRES,
     1           MAXCORE,MAXINS,MAXINSBUF,RANGE(1),RANGE(2),
     2           ALISEQ,ALIPOINTER,IDE,IFIR,ILAS,EMBLID,WEIGHT,
     3           ALILEN,NALIGN,LALI,INSNUMBER,INSALI,
     4           INSPOINTER,INSLEN,INSBEG_1,INSBUFFER,
     5           ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'F' ) THEN
            NBLOCKS = 6
            DO IALIGN = 1,NALIGN
               CALL GET_SEQ_FROM_ALISEQ(ALISEQ,IFIR,ILAS,
     1              ALIPOINTER,ALILEN,IALIGN,SEQ,NREAD,
     2              ERROR )
               IF ( ERROR ) STOP
               CALL WRITE_PEARSON(OUT,OUTNAME,SEQ,NBLOCKS,
     1              EMBLID(IALIGN),COMPND,RANGE(1),
     2              RANGE(2),ERROR)
               IF ( ERROR ) STOP
            ENDDO
         ELSE
            WRITE(*,*)' wat is tipp wat richtiges, bloedmann'
C            GOTO 2
            STOP
         ENDIF
      ELSE
         IF ( OUTFORMAT .EQ. 'S' ) THEN
            NBLOCKS = 7
            CALL WRITE_STAR(OUT,SEQ,NBLOCKS,FILENAME,OUTNAME,
     1           COMPND,RANGE(1),RANGE(2),ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'A' ) THEN
            NBLOCKS = 5
            CALL WRITE_ALB(OUT,OUTNAME,SEQ,NBLOCKS,COMPND,FILENAME,
     1           RANGE(1),RANGE(2),CHBPOS,NBREAKS,ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'K' ) THEN
            NBLOCKS = 6
            CALL WRITE_KLEIN(OUT,SEQ,NBLOCKS,BASENAME,FILENAME,
     1           OUTNAME,COMPND,RANGE(1),RANGE(2),
     2           ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'P' ) THEN
            NSYMBOLS = 30
            CALL STRREPLACE(SEQ,NRES,CGAPCHAR,CGAPCHARPIR)
            CALL WRITE_PIR(OUT,SEQ,FILENAME,OUTNAME,ACCNUM,COMPND,
     1           NSYMBOLS,RANGE(1),RANGE(2),ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'E' ) THEN
            NBLOCKS = 6
            CALL WRITE_EMBL(OUT,SEQ,NBLOCKS,FILENAME,OUTNAME,COMPND,
     1           RANGE(1),RANGE(2),ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'G' ) THEN
            NBLOCKS = 5
            CALL WRITE_GCG(OUT,SEQ,NBLOCKS,NBREAKS,FILENAME,OUTNAME,
     1           COMPND,RANGE(1),RANGE(2),ERROR)
            IF ( ERROR ) STOP
         ELSE IF ( OUTFORMAT .EQ. 'F' ) THEN
            NBLOCKS = 6
            CALL WRITE_PEARSON(OUT,OUTNAME,SEQ,NBLOCKS,ACCNUM,
     1           COMPND,RANGE(1),RANGE(2),ERROR)
            IF ( ERROR ) STOP
         ELSE
            WRITE(*,*)' wat is tipp wat richtiges, bloedmann'
C            GOTO 2
            STOP
         ENDIF
      ENDIF
 
      CLOSE(OUT)
 
      C = 'N'
      CALL GETCHAR(1,C,' write another format ?')
      CALL LOWTOUP(C,1)
      IF ( C .NE. 'N' ) THEN
         CALLS = CALLS + 1
         DO_INIT_INSBUF = .FALSE.
         GOTO 2
      ENDIF
 
      END
C     END PROGRAM CONVERT
C......................................................................
 
C......................................................................
C     SUB CHAINBREAKPOS
      SUBROUTINE CHAINBREAKPOS( SEQ,BEGIN,END,MAXBREAK,NBREAKS,
     1     CHBPOS, ERROR )
	
      IMPLICIT        NONE
C Import
      INTEGER         MAXBREAK,BEGIN,END
      CHARACTER*(*)   SEQ
C Export
      INTEGER         NBREAKS,CHBPOS(MAXBREAK)
      LOGICAL         ERROR
C Internal
      INTEGER         IPOS
*----------------------------------------------------------------------*
 
      NBREAKS = 0
      DO IPOS = BEGIN,END
         IF ( SEQ(IPOS:IPOS) .EQ. '!' ) THEN
            NBREAKS = NBREAKS + 1
            IF ( NBREAKS .GT. MAXBREAK ) THEN
               ERROR = .TRUE.
               WRITE(*,'(A)')
     1              ' MAXBREAK overflow in chainbreakpos !'
               RETURN
            ENDIF
            CHBPOS(NBREAKS) = IPOS
         ENDIF
      ENDDO
      
      RETURN
      END
C     END CHAINBREAKPOS
C......................................................................
 
C......................................................................
C     SUB CHOOSE_NAME
      SUBROUTINE CHOOSE_NAME(EMBLID,NSEQS,NUMBER)
C 21.10.92
      IMPLICIT        NONE
C Import
      INTEGER         NSEQS
      CHARACTER*(*)   EMBLID(NSEQS)
C Export
      INTEGER         NUMBER
C Internal
      INTEGER         NAMELEN_LOC
      PARAMETER      (NAMELEN_LOC=              13)
      INTEGER INAME
      CHARACTER*(NAMELEN_LOC) ANSWER
      CHARACTER*(NAMELEN_LOC) TEST
      LOGICAL LFOUND
      
      ANSWER = EMBLID(1)
      
      DO INAME = 1,NSEQS
         WRITE(*,'(1X,A)') EMBLID(INAME)
      ENDDO
 1    CONTINUE
      CALL GETCHAR(NAMELEN_LOC,ANSWER,
     1     'Choose name of HSSP master sequence :' )
      CALL LOWTOUP(ANSWER,NAMELEN_LOC)
C position of sequence in alignment = return information
      LFOUND = .FALSE.
      NUMBER = 1
      INAME = 1
      DO WHILE ( INAME .LE. NSEQS .AND. .NOT. LFOUND )
         TEST = EMBLID(INAME)
         CALL LOWTOUP(TEST,NAMELEN_LOC)
         IF ( ANSWER .EQ. TEST ) THEN
            LFOUND = .TRUE.
         ELSE
            INAME = INAME + 1
            NUMBER = NUMBER + 1
         ENDIF
      ENDDO
      IF ( .NOT. LFOUND ) THEN
         WRITE(*,'(1X,A)') ' *** INVALID CHOICE ***'
         STOP
C         GOTO 1
      ENDIF
 
      RETURN
      END
C     END CHOOSE_NAME
C......................................................................
 
C......................................................................
C     SUB CLIP_ALISEQ
      SUBROUTINE CLIP_ALISEQ(MAXALIGNS,MAXCORE,MAXINS,
     1     MAXINSBUF,ALISEQ,ALIPOINTER,NALIGN,CGAPCHAR,NRES,
     2     IFIR,ILAS,JFIR,JLAS,DELPOS,NDEL,INSNUMBER,INSALI,
     3     INSPOINTER,INSLEN,INSBEG_1,INSBEG_2,INSBUFFER,
     4     ERROR)
C 5.7.93
C delete the regions indicated in "delpos" from all sequences of the
C passed "aliseq" structure;
C copy the regions to "insbuffer"
      IMPLICIT        NONE
C Import
      INTEGER         MAXALIGNS, MAXCORE, MAXINS, MAXINSBUF,NALIGN,NRES
      INTEGER         IFIR(MAXALIGNS),ILAS(MAXALIGNS),
     +                JFIR(MAXALIGNS),JLAS(MAXALIGNS),
     +                ALIPOINTER(MAXALIGNS)
      INTEGER         DELPOS(2,*),NDEL
      CHARACTER*1     CGAPCHAR
C Export
      INTEGER         INSNUMBER,INSALI(MAXINS),INSPOINTER(MAXINS),
     +                INSLEN(MAXINS),INSBEG_1(MAXINS),INSBEG_2(MAXINS)
      CHARACTER       ALISEQ(MAXCORE)
      CHARACTER       INSBUFFER(MAXINSBUF)
      LOGICAL         ERROR
C Internal
      INTEGER         MAXTEMPBUF
      PARAMETER      (MAXTEMPBUF=             1000)
      INTEGER         I,IALIGN,IDEL,MAXLENDEL,LENDEL,
     +                IPOS,JPOS,IAP,ISP,NTERMDEL,
     +                NEXTPOS_INS,LGAP,NSYMBOLS,LASTPOS,POS,LEN
      CHARACTER*1     C
      CHARACTER*(MAXTEMPBUF) TEMPBUF
*----------------------------------------------------------------------*
        
      INSNUMBER = 0
      NEXTPOS_INS = 1
      MAXLENDEL = 0
        
      DO IALIGN = 1,NALIGN
         NTERMDEL = 0
         LGAP = 0
         LASTPOS = IFIR(IALIGN)
         LENDEL = 0
         IPOS = ALIPOINTER(IALIGN)-1
         ISP = JFIR(IALIGN) - 1
         DO IDEL = 1,NDEL
            POS = DELPOS(1,IDEL)
            LEN = DELPOS(2,IDEL)
            IF ( POS .LE. IFIR(IALIGN) ) THEN
               NTERMDEL = NTERMDEL + LEN
C     IF ( POS+LEN-1 .LT. IFIR(IALIGN) ) THEN
C     NTERMDEL = NTERMDEL + LEN
C     ELSE IF ( POS       .LT. IFIR(IALIGN) .AND.
C     1                  pos+len-1 .ge. ifir(ialign)       ) then
C                 ntermdel = ntermdel + len
            ELSE IF ( POS .GT. IFIR(IALIGN) .AND.
     1              POS .LE. ILAS(IALIGN)        ) THEN
               DO IAP = LASTPOS,POS-1
                  IPOS = IPOS + 1
                  IF ( ALISEQ(IPOS) .NE. CGAPCHAR ) THEN
                     ISP = ISP + 1
                  ENDIF
               ENDDO
               IPOS = IPOS + 1
               ISP = ISP + 1
               NSYMBOLS = 0
               TEMPBUF = ' '
               DO JPOS = 1,LEN
                  IF ( ALISEQ(IPOS+JPOS-1) .NE. CGAPCHAR ) THEN
                     NSYMBOLS = NSYMBOLS + 1
                     TEMPBUF(NSYMBOLS:NSYMBOLS) =
     1                    ALISEQ(IPOS+JPOS-1)
                  ELSE
                     LGAP = LGAP + 1
                  ENDIF
               ENDDO
               DO JPOS = IPOS,ALIPOINTER(IALIGN)+
     1              (ILAS(IALIGN)-IFIR(IALIGN))-LEN
                  ALISEQ(JPOS) = ALISEQ(JPOS+LEN)
               ENDDO
               IF ( NSYMBOLS .GT. 0 ) THEN
                  INSNUMBER = INSNUMBER + 1
                  IF ( INSNUMBER .GT. MAXINS ) THEN
                     WRITE(*,'(1X,A)')
     1                    'MAXINS overflow in clip_aliseq !'
                     ERROR = .TRUE.
                     RETURN
                  ENDIF
                  INSPOINTER(INSNUMBER) = NEXTPOS_INS
                  INSBEG_1(INSNUMBER) = POS-LENDEL-1
                  INSBEG_2(INSNUMBER) = ISP-1
                  INSALI(INSNUMBER) = IALIGN
                  INSLEN(INSNUMBER) = NSYMBOLS
                  IF ( IPOS .GT. 1 ) THEN
                     C = ALISEQ(IPOS-1)
                     JPOS = IPOS-1
                     IF ( C .EQ. CGAPCHAR ) THEN
                        DO WHILE ( JPOS .GT. 1 .AND.
     1                       ALISEQ(JPOS) .EQ. CGAPCHAR )
                           JPOS = JPOS - 1
                           C = ALISEQ(JPOS)
                        ENDDO
                     ENDIF
                     CALL UPTOLOW(C,1)
                     ALISEQ(JPOS) = C
                  ENDIF
                  INSBUFFER(NEXTPOS_INS) = C
                  DO I = 1,NSYMBOLS
                     INSBUFFER(NEXTPOS_INS+I) = TEMPBUF(I:I)
                  ENDDO
                  C = ALISEQ(IPOS)
                  JPOS = IPOS
                  IF ( C .EQ. CGAPCHAR ) THEN
                     DO WHILE
     1                    ( JPOS .LT.
     2                    ALIPOINTER(IALIGN)+ILAS(IALIGN)-IFIR(IALIGN)
     3                    .AND.
     4                    ALISEQ(JPOS) .EQ. CGAPCHAR )
                        JPOS = JPOS + 1
                        C = ALISEQ(JPOS)
                     ENDDO
                  ENDIF
                  CALL UPTOLOW(C,1)
                  ALISEQ(JPOS) = C
                  INSBUFFER(NEXTPOS_INS+NSYMBOLS+1) = C
                  NEXTPOS_INS =
     1                 NEXTPOS_INS + NSYMBOLS + 3
                  IF ( NEXTPOS_INS .GT. MAXINSBUF ) THEN
                     WRITE(*,'(1X,A)')
     1                    'MAXINSBUF overflow in clip_aliseq !'
                     ERROR = .TRUE.
                     RETURN
                  ENDIF
               ENDIF
               LASTPOS = POS + LEN + 1
               LENDEL = LENDEL + LEN
            ENDIF
         ENDDO
         MAXLENDEL = MAX(MAXLENDEL,LENDEL)
         IFIR(IALIGN) = IFIR(IALIGN)-NTERMDEL
         IF ( IFIR(IALIGN) .LT. 1 ) THEN
C delete n-terminal gaps
            DO JPOS = ALIPOINTER(IALIGN),
     1           ALIPOINTER(IALIGN)+
     2           (ILAS(IALIGN)-1)-(1-IFIR(IALIGN))
               ALISEQ(JPOS) = ALISEQ(JPOS+(1-IFIR(IALIGN)))
            ENDDO
            IFIR(IALIGN) = 1
         ENDIF
         ILAS(IALIGN) = ILAS(IALIGN)-LENDEL-NTERMDEL
         JLAS(IALIGN) = JLAS(IALIGN)-LENDEL-NTERMDEL +LGAP
      ENDDO
C>>>>>
      NRES = NRES - MAXLENDEL
 
      RETURN
      END
C     END CLIP_ALISEQ
C......................................................................
 
C......................................................................
C     SUB CHANGE_ALISEQ
      SUBROUTINE CHANGE_ALISEQ(MAXALIGNS,MAXCORE,MAXINS,MAXRES,
     1     LINSERT,LDELETE,CHANGEPOS,NALIGN,
     +     NEWSEQ,NEWSEQSTART,NEWSEQSTOP,NEWSEQNAME,
     2     FILLUP,ALISEQ,ALIPOINTER,
     3     IFIR,ILAS,JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,STRID,
     4     IDE,SIM,EXCLUDEFLAG,ACCNUM,EMBLID,PROTNAME,INSALI,
     5     INSNUMBER)
 
      IMPLICIT     NONE
C Import
      INTEGER      MAXALIGNS,MAXCORE,MAXINS,MAXRES,CHANGEPOS
C mutually exclusive logicals:
C ........ if ( linsert ) "newseq" is inserted into aliseq at position
C ........ "changepos". Its name, stop/start values and so on are
C ........ added to the appropriate arrays.
C ........ if ( ldelete ), the "changepos"th sequence is deleted from
C ........ aliseq ( so is its name, start/stop values .. from emblid,
C ........ ifir, ilas .. ) and is returned in "newseq".  Its name is
C ........ returned in "newseqname".
      LOGICAL       LINSERT, LDELETE
C Import / Export
      INTEGER       NALIGN,FILLUP,ALIPOINTER(MAXALIGNS)
      INTEGER       NEWSEQSTART,NEWSEQSTOP
      CHARACTER     ALISEQ(MAXCORE),NEWSEQ(MAXRES),NEWSEQNAME*(*)
C  attributes of aligned sequences
C---- first and last residue of guide (ifir), and aligned (jfir)
      INTEGER       IFIR(MAXALIGNS),ILAS(MAXALIGNS),
     +              JFIR(MAXALIGNS),JLAS(MAXALIGNS)
      INTEGER       LALI(MAXALIGNS),NGAP(MAXALIGNS),
     +              LGAP(MAXALIGNS),LENSEQ(MAXALIGNS),
     +              INSALI(MAXINS),INSNUMBER
      CHARACTER*(*) STRID(MAXALIGNS),ACCNUM(MAXALIGNS),
     +              EMBLID(MAXALIGNS),PROTNAME(MAXALIGNS)
C---- ' ' if no flag, '*' if to exclude
      CHARACTER     EXCLUDEFLAG(MAXALIGNS)
C---- percentage identity       similarity
      REAL          IDE(MAXALIGNS),SIM(MAXALIGNS)

C Internal
      INTEGER       IALIGN,IINS,IPOS,JPOS,LEN,IBEG,IEND,ITMP,I
      INTEGER       NEWSEQLEN
      CHARACTER*1   CGAPCHAR
      
      CGAPCHAR = '.'
C----------------------------------------------------------------------
      IF ( LINSERT ) THEN
C----------------------------------------------------------------------
 
         NEWSEQLEN = NEWSEQSTOP-NEWSEQSTART+1
         IF ( CHANGEPOS .GT. NALIGN+1 ) THEN
 
            WRITE(*,'(A,I4)') ' cannot add after position ', NALIGN+1
            RETURN
         ELSE IF ( CHANGEPOS .EQ. NALIGN+1 ) THEN
            ALIPOINTER(CHANGEPOS) =
     1           ALIPOINTER(NALIGN)+ILAS(NALIGN)-IFIR(NALIGN)+1
         ELSE IF ( CHANGEPOS .LE. NALIGN ) THEN
            DO IPOS = ALIPOINTER(NALIGN)+ILAS(NALIGN)-IFIR(NALIGN)+1,
     1           ALIPOINTER(CHANGEPOS),-1
               IF ( IPOS+NEWSEQLEN+1 .LE. MAXCORE ) THEN
C shift by newseqlen+1, because a '/' is to be inserted after newseq
                  ALISEQ(IPOS+NEWSEQLEN+1 ) = ALISEQ(IPOS)
               ELSE
                  STOP 'MAXCORE OVERFLOW IN ADD_SEQ_TO_ALISEQ !'
               ENDIF
            ENDDO
C insert new member into arrays ifir .. at position changepos
C  and push following members by one
            DO IINS = 1,INSNUMBER
               IF ( INSALI(IINS) .GE. CHANGEPOS ) THEN
                  INSALI(IINS)=INSALI(IINS)+1
               ENDIF
            ENDDO
            DO IALIGN = NALIGN,CHANGEPOS,-1
               IFIR(IALIGN+1)=IFIR(IALIGN)
               ILAS(IALIGN+1)=ILAS(IALIGN)
               JFIR(IALIGN+1)=JFIR(IALIGN)
               JLAS(IALIGN+1)=JLAS(IALIGN)
               LALI(IALIGN+1)=LALI(IALIGN)
               NGAP(IALIGN+1)=NGAP(IALIGN)
               LGAP(IALIGN+1)=LGAP(IALIGN)
               LENSEQ(IALIGN+1)=LENSEQ(IALIGN)
               STRID(IALIGN+1)=STRID(IALIGN)
               ACCNUM(IALIGN+1)=ACCNUM(IALIGN)
               EMBLID(IALIGN+1)=EMBLID(IALIGN)
               PROTNAME(IALIGN+1)=PROTNAME(IALIGN)
               EXCLUDEFLAG(IALIGN+1)=EXCLUDEFLAG(IALIGN)
               IDE(IALIGN+1)=IDE(IALIGN)
               SIM(IALIGN+1)=SIM(IALIGN)
               ALIPOINTER(IALIGN+1) = ALIPOINTER(IALIGN)+NEWSEQLEN+1
            ENDDO
         ENDIF
 
C insert newseq into aliseq
C changepos............last res, '/'
C                            = +1
         LEN = NEWSEQSTART
         DO IPOS = ALIPOINTER(CHANGEPOS),
     1        (ALIPOINTER(CHANGEPOS)+NEWSEQLEN-1)
            IF (IPOS.GT.0) THEN
               ALISEQ(IPOS)= NEWSEQ(LEN)
               LEN=          LEN + 1
            ENDIF
         ENDDO
         ALISEQ(IPOS) = '/'
         IFIR(CHANGEPOS)=1
         ILAS(CHANGEPOS)=NEWSEQLEN
         JFIR(CHANGEPOS)=1
         JLAS(CHANGEPOS)=NEWSEQLEN
         LALI(CHANGEPOS)=NEWSEQLEN
         NGAP(CHANGEPOS)=0
         LGAP(CHANGEPOS)=0
         LENSEQ(CHANGEPOS)=NEWSEQLEN
         STRID(CHANGEPOS )= ' '
         ACCNUM(CHANGEPOS) = ' '
         EMBLID(CHANGEPOS)= NEWSEQNAME
         PROTNAME(CHANGEPOS)= ' '
         EXCLUDEFLAG(CHANGEPOS)= ' '
         IDE(CHANGEPOS)=0.0
         SIM(CHANGEPOS)=0.0
         
         NALIGN = NALIGN + 1

C------- br 99-03: watch names
         IF (EMBLID(1).EQ.EMBLID(CHANGEPOS)) THEN
            CALL STRPOS(EMBLID(1),IBEG,IEND)
            EMBLID(1)((IEND+1):(IEND+1))="0"
         ENDIF
C-----------------------------------------------------------------------
      ELSE IF ( LDELETE .AND. CHANGEPOS.NE.0) THEN
C-----------------------------------------------------------------------

C save sequence in "newseq"
         JPOS=0
C----    all before to gap (really what you want?)
         IF (IFIR(CHANGEPOS) .GE. 2) THEN
            DO JPOS=1,(IFIR(CHANGEPOS)-1)
               NEWSEQ(JPOS)= CGAPCHAR
            ENDDO
            JPOS=         JPOS - 1
         ENDIF

         NEWSEQLEN=       0
         IBEG=            ALIPOINTER(CHANGEPOS)
         IEND=            IBEG+ILAS(CHANGEPOS)-IFIR(CHANGEPOS)
C----    read real sequence for the respective range
         DO IPOS=IBEG,IEND
Cxx            write(6,*)'xx ipos=',ipos,' len=',lenseq(changepos)
            IF (IPOS.GT.0) THEN
               NEWSEQLEN=             NEWSEQLEN+1
               NEWSEQ(NEWSEQLEN+JPOS)=ALISEQ(IPOS)
            ENDIF
         ENDDO
C----    fill up with GAP
         DO IPOS=(ILAS(CHANGEPOS)+1),FILLUP
            NEWSEQ(IPOS)=          CGAPCHAR
         ENDDO
         NEWSEQSTART= IFIR(CHANGEPOS)
         NEWSEQSTOP=  ILAS(CHANGEPOS)
         
         IF ( CHANGEPOS .LT. NALIGN ) THEN
C if the last sequence is to be deleted, nothing has actually to be
C ...done to "aliseq". Otherwise: pull all following sequences and
C ...array entries by one, overwriting sequence No. "changepos"
            DO IPOS= ALIPOINTER(CHANGEPOS+1),
     1           ALIPOINTER(NALIGN)+ILAS(NALIGN)-IFIR(NALIGN)+1
C shift by newseqlen+1, because a '/' is to be inserted after newseq
               ALISEQ(IPOS-NEWSEQLEN-1 ) = ALISEQ(IPOS)
            ENDDO
            NEWSEQNAME= EMBLID(CHANGEPOS)
            DO IINS = 1,INSNUMBER
               IF (INSALI(IINS) .GE. CHANGEPOS) THEN
                  INSALI(IINS)=INSALI(IINS)-1
               ENDIF
            ENDDO
            DO IALIGN=CHANGEPOS,(NALIGN-1)
               IFIR(IALIGN)=       IFIR(IALIGN+1)
               ILAS(IALIGN)=       ILAS(IALIGN+1)
               JFIR(IALIGN)=       JFIR(IALIGN+1)
               JLAS(IALIGN)=       JLAS(IALIGN+1)
               LALI(IALIGN)=       LALI(IALIGN+1)
               NGAP(IALIGN)=       NGAP(IALIGN+1)
               LGAP(IALIGN)=       LGAP(IALIGN+1)
               LENSEQ(IALIGN)=     LENSEQ(IALIGN+1)
               STRID(IALIGN)=      STRID(IALIGN+1)
               ACCNUM(IALIGN)=     ACCNUM(IALIGN+1)
               EMBLID(IALIGN)=     EMBLID(IALIGN+1)
               PROTNAME(IALIGN)=   PROTNAME(IALIGN+1)
               EXCLUDEFLAG(IALIGN)=EXCLUDEFLAG(IALIGN+1)
               IDE(IALIGN)=        IDE(IALIGN+1)
               SIM(IALIGN)=        SIM(IALIGN+1)
               ALIPOINTER(IALIGN)= ALIPOINTER(IALIGN+1)-NEWSEQLEN-1
            ENDDO
         ENDIF

C----    reduce number of alignments (since CHANGEPOSnth seq removed)
         NALIGN=NALIGN-1
C----------------------------------------------------------------------
      ENDIF
C----------------------------------------------------------------------
      RETURN
      END
C     END CHANGE_ALISEQ
C......................................................................
 
C......................................................................
C     SUB DSSP_NOTATION_TO_CYS
      SUBROUTINE DSSP_NOTATION_TO_CYS(SEQIN,LEN)
 
      IMPLICIT        NONE
C 20.3.92
C Import:
      CHARACTER       SEQIN(*)
      INTEGER         LEN
C Internal:
C only used to get rid of INDEX command (CPU time)
      INTEGER         NASCII
      PARAMETER      (NASCII=                  256)
      INTEGER         LOWERPOS(NASCII),IRES, I
      CHARACTER*26    LOWER
      CHARACTER*1     C
*----------------------------------------------------------------------*

C used to convert lower case characters from the DSSP-seq to 'C' (Cys)
      LOWER='abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,NASCII)
 
      IRES = 1
      DO WHILE ( IRES .LE. LEN)
         C = SEQIN(IRES)
         CALL GETINDEX(C,LOWERPOS,I)
         IF(I.NE.0) C='C'
         SEQIN(IRES) = C
         IRES = IRES + 1
      ENDDO
 
      RETURN
      END
C     END DSSP_NOTATION_TO_CYS
C......................................................................
 
C......................................................................
C     SUB EXTRACT_CHAINS
      SUBROUTINE EXTRACT_CHAINS(TEMPNAME,FILENAME,MAXCHAINS,
     1     CCHAIN)
 
      IMPLICIT NONE
C chain is given as an appendix to filename as follows:
C filename_!_chain
C
C IF CHAINID IS A DIGIT, IT IS TAKEN TO BE THE "DIGIT"TH CHAIN !
C
C Import
      INTEGER MAXCHAINS
      CHARACTER*(*) TEMPNAME
C Export
      CHARACTER*(*) FILENAME
      CHARACTER*(*) CCHAIN
C Internal
      INTEGER I,II,J
      CHARACTER*32 OUTFORMAT
	
      CCHAIN = ' '
      I = INDEX(TEMPNAME,'!')
      IF ( I .NE. 0 ) THEN
         FILENAME = TEMPNAME(1:I-2)
      ELSE
         FILENAME = TEMPNAME
         WRITE(OUTFORMAT,'(A,I4,A)') '( ',MAXCHAINS, '(I3,1X))'
         WRITE(CCHAIN,OUTFORMAT) (J,J=1,MAXCHAINS)
      ENDIF
      J = 1
      II = I
      DO WHILE ( II .NE. 0 )
         IF ( J .EQ. 1 ) THEN
            CCHAIN(1:1) = TEMPNAME(I+2:I+2)
         ELSE
            CCHAIN(2*J-1:2*J-1) = TEMPNAME(I+1:I+1)
         ENDIF
         II = INDEX(TEMPNAME(I+1:),',')
         I = I + II
         J = J + 1
      ENDDO
      RETURN
      END
C     END EXTRACT_CHAINS
C......................................................................
 
C......................................................................
C     SUB GETCONSWEIGHT_BR
      SUBROUTINE GETCONSWEIGHT_BR(MAXSTRSTATES,MAXIOSTATES,
     +     MAXRES,MAXALIGNS,MAXCORE,NTRANS,NASCII,NALIGN,NRES,
     +     IDE,IFIR,ILAS,LALI,ALIPOINTER,PDBSEQ,ALISEQ,
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

      IMPLICIT       NONE  

C---- ------------------------------
C---- import
C---- ------------------------------
C---- 
C     parameters for array
      INTEGER        MAXSTRSTATES,MAXIOSTATES,MAXRES,MAXALIGNS,MAXCORE,
     +               NTRANS,NASCII
C     actual values
      INTEGER        NALIGN,NRES
C     pointer arrays
      INTEGER        IFIR(MAXALIGNS),ILAS(MAXALIGNS),
     +               ALIPOINTER(MAXALIGNS)
C     alignment length lali(i) length of ali between PDBSEQ and ali i
      INTEGER        LALI(MAXALIGNS)
C     guide sequence
      CHARACTER      PDBSEQ(MAXRES)
C     all aligned sequences
      CHARACTER      ALISEQ(MAXCORE)
C      CHARACTER*(*)  ALISEQ(MAXCORE)
C     flags (take ' ', else other)
      CHARACTER      EXCLUDEFLAG(MAXALIGNS)
C     percentage sequence identity
      REAL           IDE(MAXALIGNS),IDEMAX
C     comparison metric
      REAL           MATRIX(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                      MAXSTRSTATES,MAXIOSTATES)   
C     normalised to sum over 0 (by SETCONSERVATION)
      REAL           SIMCONSERV(NTRANS,NTRANS)
C     allowed sequence symbols
      CHARACTER      CTRANS*26
C     minimal conservation weight
      REAL           CONSWEIGHT_MIN
C     only used to get rid of INDEX command (CPU time)
      INTEGER        MATPOS(NASCII)

C----
C---- output from sbr
C----
C     conservation weight
      REAL           CONSWEIGHT(MAXRES)

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
         WRITE(6,*)'*** ERROR: NRES .GT. MAXRES IN GETCONSWEIGHT_BR'
         WRITE(6,*)'*** INCREASE MAXRES ****'
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

C      WRITE(6,*)'XX in getCONS PDB='
C      WRITE(6,'(40A1)')(PDBSEQ(I),I=1,NRES)

      
C---- ------------------------------------------------------------------
C---- guide against all
C---- ------------------------------------------------------------------
C---- store PDB sequence in integer array
      DO IRES=1,NRES
C         write(6,*)'xx ires=',ires,' pdb=',pdbseq(ires),','
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
C---- hack br 1999-12: problem with 'treat gaps as insertions'
C---- somehow the thing has IFIR(JALIGN) not defined!!
         IF ( EXCLUDEFLAG(JALIGN) .EQ. ' ') THEN
            IF (IFIR(JALIGN).EQ.0 .OR. ILAS(JALIGN).EQ.0) THEN
               EXCLUDEFLAG(JALIGN)="*"
            END IF
         END IF
C---- end of hack br 1999-12

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
     +                                     JALIGN_SEQ(IRES))
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
C     SUB GETSEQSIM_BR
      SUBROUTINE GETSEQSIM_BR(MAXSTRSTATES,MAXIOSTATES,
     +     MAXRES,MAXALIGNS,NTRANS,NASCII,NALIGN,NRES,
     +     IFIR,ILAS,LALI,ALIPOINTER,PDBSEQ,ALISEQ,
     +     EXCLUDEFLAG,CTRANS,MATRIX,SIMCONSERV,MATPOS,SIM,CONSWEIGHT)
C---- 
C---- BR 99-03
C---- 
C---- Calculate the sequence similarity.
C---- EXCLUDEFLAG(iali)='*' if the identity of alignment number
C---- 'iali' to any other sequence is above IDEMAX (threshold input)
C---- 
C---- 
C---- out:           output is the conservation weight
C---- 
C---- ------------------------------------------------------------------
C---- 
C---- 
C---- ------------------------------------------------------------------
C---- 

      IMPLICIT       NONE  

C---- 
C---- import
C---- 
C     parameters for array
      INTEGER        MAXSTRSTATES,MAXIOSTATES,MAXRES,MAXALIGNS,
     +               NTRANS,NASCII
C     actual values
      INTEGER        NALIGN,NRES
C     pointer arrays
      INTEGER        IFIR(MAXALIGNS),ILAS(MAXALIGNS),
     +               ALIPOINTER(MAXALIGNS)
C     alignment length lali(i) length of ali between PDBSEQ and ali i
      INTEGER        LALI(MAXALIGNS)
C     guide sequence
      CHARACTER      PDBSEQ(MAXRES)
C     all aligned sequences
      CHARACTER*(*)  ALISEQ(*)
C     flags (take ' ', else other)
      CHARACTER      EXCLUDEFLAG(MAXALIGNS)
C     percentage sequence identity
C      REAL           IDE(MAXALIGNS),IDEMAX
C     comparison metric
      REAL           MATRIX(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                      MAXSTRSTATES,MAXIOSTATES)   
C     normalised to sum over 0 (by SETCONSERVATION)
      REAL           SIMCONSERV(NTRANS,NTRANS)
C     allowed sequence symbols
      CHARACTER      CTRANS*26
C     only used to get rid of INDEX command (CPU time)
      INTEGER        MATPOS(NASCII)
C     conservation weight
      REAL           CONSWEIGHT(MAXRES)
C----
C---- output from sbr
C----
C     percentage sequence similarity
      REAL           SIM(MAXRES)

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

C---- big: seq ide distance for pair i,j
      INTEGER         NPOS,NRES_OVERLAP
      REAL            SIM_XX(1000),SIM_XX2(1000)

      CHARACTER       LINE*(MAXLEN)
      LOGICAL         LERROR

C---- ------------------------------------------------------------------
C---- 
C---- defaults, ini

C---- ------------------------------------------------------------------
C---- now work on it      
C---- ------------------------------------------------------------------
      WRITE(6,*)  '--- GETSEQSIM_BR begin'
C---- 
C---- calculate variability only for the 22 (BZ) amino acids
C---- 
      DO I=1,NASCII 
         MATPOS(I)=0
      ENDDO
      CALL GETPOS(CTRANS(1:22),MATPOS,NASCII)
      IF (NRES .GT. MAXRES) THEN
         WRITE(*,*)'*** ERROR: NRES .GT. MAXRES IN GETSEQSIM_BR'
         WRITE(*,*)'*** INCREASE MAXRES ****'
         STOP
      ENDIF
C---- 
C---- ERROR!
C---- 
      IF (NRES .LE. 0) RETURN

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
C----       store alignment sequence in integer array (for j)
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
C----       get overlap of aligned sequences
C----
            IBEG=        MAX(1,   IFIR(JALIGN))
            IEND=        MIN(NRES,ILAS(JALIGN))

C----       ini new value for sequence similarity
            NRES_OVERLAP=0
            SIM(JALIGN)= 0
            SIM_XX(JALIGN)= 0
         
            DO IRES=IBEG,IEND
               IF ( (JALIGN_SEQ(IRES) .NE. 0) .AND.
     +              (JALIGN_SEQ(IRES) .NE. 0) ) THEN
                  NRES_OVERLAP=NRES_OVERLAP+1
C---- 
C----             sequence similarity
C---- 
C                  SIM(JALIGN)=SIM(JALIGN)+
C     +                 MATRIX(IALIGN_SEQ(IRES),JALIGN_SEQ(IRES),1,1,1,1)
C                  SIM(JALIGN)=SIM(JALIGN)+
C     +                 CONSWEIGHT(IRES)*
C     +                 MATRIX(IALIGN_SEQ(IRES),JALIGN_SEQ(IRES),1,1,1,1)
                  SIM(JALIGN)=SIM(JALIGN)+
     +                 CONSWEIGHT(IRES)*
     +                 SIMCONSERV(IALIGN_SEQ(IRES),JALIGN_SEQ(IRES))
C                  SIM_XX(JALIGN)=SIM_XX(JALIGN)+
C     +                 MATRIX(IALIGN_SEQ(IRES),JALIGN_SEQ(IRES),1,1,1,1)
                  SIM_XX(JALIGN)=SIM_XX(JALIGN)+
     +                 SIMCONSERV(IALIGN_SEQ(IRES),JALIGN_SEQ(IRES))
               END IF
            END DO
C----
C----       normalise sequence similarity to ratio
C----
            SIM_XX2(JALIGN)=SIM_XX(JALIGN)
            IF (NRES_OVERLAP.GT.0)  
     +           SIM_XX2(JALIGN)=
     +                    SIM_XX2(JALIGN)/REAL(NRES_OVERLAP)
            
            
            NRES_OVERLAP=1+ILAS(JALIGN)-IFIR(JALIGN)
            
            IF (NRES_OVERLAP.GT.0)  
     +           SIM(JALIGN)=
     +                    SIM(JALIGN)/REAL(NRES_OVERLAP)
            IF (NRES_OVERLAP.GT.0)  
     +           SIM_XX(JALIGN)=
     +                    SIM_XX(JALIGN)/REAL(NRES_OVERLAP)
         ENDIF
C----    end of: exclude?
      ENDDO
C---- end loop over all sequences aligned to guide
      write(6,*)'xx upon leaving got:'
      DO I=1,NALIGN
         write(6,'(i3,a,f5.2,a,f5.2,a,f5.2)')
     +        i,'xx sim=',SIM(i),' xx=',SIM_XX(i),
     +        ' nnt=',sim_xx2(i)
      END DO
      do i=1,22
C         write(6,'(i2,22i3)')i,(int(100*MATRIX(i,j,1,1,1,1)),j=1,22)
         write(6,'(i2,22i3)')i,(int(100*SIMCONSERV(i,j)),j=1,22)
      enddo
      stop

      write(6,*)'xx dia'
      write(6,'(22i4)')(int(100*MATRIX(j,j,1,1,1,1)),j=1,22)
      
      stop
      
Cxxx      

      WRITE(6,*)  '--- GETSEQSIM_BR ended'
      RETURN
      END
C     END GETSEQSIM_BR 
C......................................................................


C......................................................................
C     SUB IDENTITY
      SUBROUTINE IDENTITY(BEGIN,END,CGAPCHAR,SEQ1,SEQ2,IDE1,NOVERLAP)
C 26.10.92
      IMPLICIT      NONE
C Import
      INTEGER       BEGIN,END
      CHARACTER*1   CGAPCHAR
      CHARACTER*(*) SEQ1,SEQ2
C Export
      INTEGER       NOVERLAP
      REAL          IDE1
C Internal
      INTEGER       I,NIDE
      CHARACTER*1   C1, C2
 
      NOVERLAP= 0
      NIDE=     0
      
      DO I= BEGIN,END
         C1= SEQ1(I:I)
         C2= SEQ2(I:I)
         CALL LOWTOUP(C1,1)
         CALL LOWTOUP(C2,1)
         IF ( C1 .NE. CGAPCHAR .AND. C2 .NE. CGAPCHAR )  THEN
            NOVERLAP = NOVERLAP + 1
            IF ( C1 .EQ. C2 ) NIDE = NIDE + 1
         ENDIF
      ENDDO

      IF ( NOVERLAP .GT. 0 ) THEN
         IDE1 = FLOAT(NIDE) / FLOAT(NOVERLAP)
      ELSE
         WRITE(*,'(A)')
     1        ' ** sequences with no overlap : %ide set to 0 **'
         IDE1 = 0.0
      ENDIF
 
      RETURN
      END
C     END IDENTITY
C......................................................................
 
C......................................................................
C     SUB MAKE_HSSP
      SUBROUTINE MAKE_HSSP(MAXRES,MAXALIGNS,
     +     MAXCORE,MAXAA,MAXINS,MAXINSBUF,
     +     KOUT,OUTNAME,INFILE,PDBID,HEADER,
     +     COMPOUND,SOURCE,AUTHOR,ALILEN,NCHAIN,KCHAIN,
     +     CHAINREMARK,NALIGN,EXCLUDEFLAG,EMBLID,STRID,
     +     IDE,SIM,IFIR,ILAS,JFIR,JLAS,LALI,NGAP,LGAP,
     +     LENSEQ,ACCNUM_HSSP,PROTNAME,PDBNO,PDBSEQ,CHAINID,
     +     SECSTR_HSSP,COLS,SHEETLABEL,BP1,BP2,ACC,NOCC,
     +     VAR,ALISEQ,ALIPOINTER,SEQPROF,NDEL,NINS,ENTROPY,
     +     RELENT,CONSWEIGHT_MIN,CONSWEIGHT,LCONSERV,LOLDVERSION,
     +     CGAPCHAR,LFILTER,METRICFILE, LDOCLIP,
     +     INSNUMBER,INSALI,INSPOINTER,INSLEN,INSBEG_1,
     +     INSBEG_2,INSBUFFER,DO_INIT_INSBUF,ERROR,
     +     LHSSP_LONG_ID)
C 26.10.92
C 5.7.93 write insertion lists
C---- ------------------------------------------------------------------
      IMPLICIT        NONE
C Import
      INTEGER         MAXRES,MAXALIGNS,MAXCORE,MAXAA,MAXINS,MAXINSBUF,
     +                NALIGN
C HSSP descricptiption variables
      LOGICAL         LCONSERV,LOLDVERSION,LHSSP_LONG_ID
C attributes of sequence with known structure
      CHARACTER       PDBSEQ(MAXRES),CHAINID(MAXRES),
     +                SECSTR_HSSP(MAXRES),SHEETLABEL(MAXRES)
      CHARACTER*(*)   PDBID,COLS(MAXRES),HEADER,
     +                COMPOUND,SOURCE,AUTHOR,CHAINREMARK
      INTEGER         NCHAIN, KCHAIN, NREAD,ACC(MAXRES),
     +                PDBNO(MAXRES),BP1(MAXRES),BP2(MAXRES)
C attributes of aligned sequences
      INTEGER         IFIR(MAXALIGNS), ILAS(MAXALIGNS),
     +                ALIPOINTER(MAXALIGNS),
     +                INSNUMBER,INSALI(MAXINS),INSPOINTER(MAXINS),
     +                INSLEN(MAXINS),INSBEG_1(MAXINS),INSBEG_2(MAXINS)
      CHARACTER       INSBUFFER(MAXINSBUF),ALISEQ(MAXCORE),
     +                EXCLUDEFLAG(MAXALIGNS)
      CHARACTER*(*)   STRID(MAXALIGNS),ACCNUM_HSSP(MAXALIGNS),
     +                EMBLID(MAXALIGNS),PROTNAME(MAXALIGNS)
      INTEGER         JFIR(MAXALIGNS),JLAS(MAXALIGNS),
     +                LALI(MAXALIGNS),NGAP(MAXALIGNS),
     +                LGAP(MAXALIGNS),LENSEQ(MAXALIGNS)
      REAL            IDE(MAXALIGNS),SIM(MAXALIGNS)
C attributes of profile
      INTEGER         VAR(MAXRES),SEQPROF(MAXRES,MAXAA),RELENT(MAXRES),
     +                NOCC(MAXRES),NDEL(MAXRES),NINS(MAXRES)
      REAL            ENTROPY(MAXRES)
C threshold
      INTEGER         ISOLEN(100),NSTEP,ISAFE
      LOGICAL         LFORMULA,LALL
      REAL            CONSWEIGHT(MAXRES),ISOIDE(100),CONSWEIGHT_MIN
C .. and others
      INTEGER         KOUT,ALILEN
      CHARACTER       CGAPCHAR
      CHARACTER*(*)   OUTNAME,INFILE,METRICFILE
      LOGICAL         LFILTER, LDOCLIP, DO_INIT_INSBUF
C Export
C .. output to unit kout
      LOGICAL         ERROR
C Internal
      INTEGER         KSIM,CODELEN_LOC,NTRANS,MAXRES_LOC,
     +                MAXINS_LOC,MAXSTRSTATES,MAXIOSTATES
      PARAMETER      (KSIM=                     98)
      PARAMETER      (CODELEN_LOC=              40)
      PARAMETER      (MAXINS_LOC=            50000)
      PARAMETER      (MAXRES_LOC=            10000)
      PARAMETER      (NTRANS=                   26)
      PARAMETER      (MAXSTRSTATES=              3)
      PARAMETER      (MAXIOSTATES=               4)
      INTEGER         I, J, ISTART, IFIN,NPARALINE, CHANGEPOS,
     +                NSTRSTATES,NIOSTATES,NOVERLAP,
     +                SEQSTART,SEQSTOP, NDELETED,
     +                DELPOS(2,MAXINS_LOC),NDELPOS,NRES
C     comparison metric
      REAL            MATRIX (NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                        MAXSTRSTATES,MAXIOSTATES)
C     normalised to sum over 0 (by SETCONSERVATION)
      REAL            SIMCONSERV(NTRANS,NTRANS)
C
      REAL            IORANGE(MAXSTRSTATES,MAXIOSTATES,2),
     +                SMIN, SMAX, MAPLOW, MAPHIGH, THISIDE

      CHARACTER*(MAXRES_LOC)  SEQ1, SEQ2
      CHARACTER*(NTRANS)           TRANS
      CHARACTER*(CODELEN_LOC) PDBNAME
      CHARACTER*9     CDATE
      CHARACTER*80    ISOSIGFILE,DATABASE
      CHARACTER*132   CPARAMETER(5),HSSPLINE
      CHARACTER       CSTRSTATES*(MAXSTRSTATES),CIOSTATES*(MAXIOSTATES)
      LOGICAL         LINSERT, LDELETE

C----
C---- only used to get rid of INDEX command (CPU time)
C----
      INTEGER         NASCII
      PARAMETER      (NASCII=                  256)
      INTEGER         MATPOS(NASCII)


C---- ------------------------------------------------------------------
C---- 
C---- initialise
C---- 
      LFORMULA=    .FALSE.
      LALL=        .TRUE.
      LCONSERV=    .FALSE.
      LOLDVERSION= .FALSE.
C---- 
      SMIN=        0.0 
      SMAX=        1.0 
      MAPLOW=      0.0 
      MAPHIGH=     0.0
      CSTRSTATES=  ' ' 
      CIOSTATES=   ' '
C---- 
      HSSPLINE='HSSP       HOMOLOGY DERIVED SECONDARY STRUCTURE ' //
     1     'OF PROTEINS , VERSION 1.0 1991'
      CALL STRPOS(INFILE,ISTART,IFIN)
      DATABASE=    'SEQBASE    ' // INFILE(ISTART:IFIN)
      HEADER=      ' '
      COMPOUND=    ' '
      SOURCE=      ' '
      AUTHOR=      ' '
      CHAINREMARK= ' '
      ISOSIGFILE=  'ALL'
      NPARALINE=   1
      LFILTER=     .FALSE.
C---- 
      TRANS='VLIMFWYGAPSTCHRKQENDBZX!-.'
C---- 
      CALL CHOOSE_NAME(EMBLID,NALIGN,CHANGEPOS)
      LINSERT=     .FALSE.
      LDELETE=     .TRUE.
      SEQSTART=    0
      SEQSTOP=     0
      PDBSEQ(1)=   ' '
      PDBNAME=     ' '
C---- 
C---- ------------------------------------------------------------------
C---- 
C---- 
C delete the master sequence from aliseq data structure
C ( later restore it .. could be done more clever !! )
C---- also returns PDBSEQ=

      CALL CHANGE_ALISEQ(MAXALIGNS,MAXCORE,MAXINS,MAXRES,
     1     LINSERT,LDELETE,CHANGEPOS,NALIGN,
     +     PDBSEQ,SEQSTART,SEQSTOP,PDBNAME,
     2     ALILEN,ALISEQ,ALIPOINTER,
     +     IFIR,ILAS,JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,STRID,
     3     IDE,SIM,EXCLUDEFLAG,ACCNUM_HSSP,EMBLID,PROTNAME,INSALI,
     5     INSNUMBER)
C      write(6,'(a)')'xx after change_aliseq pdb='
C      write(6,'(40a1)')(PDBSEQ(I),I=SEQSTART,SEQSTOP)
C----  br 99-03: tried to be smart, failed
C      EXCLUDEFLAG(CHANGEPOS)='*'

      IF ( LDOCLIP ) THEN
C remove gaps from master sequence
         LDELETE= .TRUE.
C hack br: 99-12
         DO I=1,ALILEN
            SEQ1(I:I)=PDBSEQ(I)
         END DO
         CALL MARK_LOC_RUNS(LDELETE,SEQ1,1,ALILEN,CGAPCHAR,
     1        DELPOS,NDELETED,NDELPOS)
 
C .. and delete gapped stretches in ALL alignments; 
C...     save them in "insbuffer"
C >>> THIS IS A IRREVERSIBLE CHANGE TO "ALISEQ" <<<<<<<<<<<<<<<<<<<<<
         IF (NDELPOS .GT. 0) THEN
            CALL CLIP_ALISEQ(MAXALIGNS,MAXCORE,MAXINS,
     1           MAXINSBUF,ALISEQ,ALIPOINTER,NALIGN,CGAPCHAR,
     2           ALILEN,IFIR,ILAS,JFIR,JLAS,DELPOS,NDELPOS,
     3           INSNUMBER,INSALI,INSPOINTER,INSLEN,INSBEG_1,
     4           INSBEG_2,INSBUFFER,ERROR)
            IF ( ERROR ) STOP
            DO J = 1,ALILEN
               PDBSEQ(J)= SEQ1(J:J)
            ENDDO
         ELSE
C            write(6,*)'xx clip 2 alilen=',alilen
            DO J = 1,ALILEN
               SEQ1(J:J)=PDBSEQ(J)
C               write(6,*)'xx pdbseq(j=',j,')=',pdbseq(j)
            ENDDO
         ENDIF

C         WRITE(6,*)'XX AFTER CLIP STRPOS PDB='
C         WRITE(6,'(40A1)')(PDBSEQ(I),I=1,ALILEN)
      ENDIF
 
      CALL STRPOS(PDBNAME,ISTART,IFIN)
      PDBID = PDBNAME(ISTART:IFIN)
      CPARAMETER(1) = ' CONVERTSEQ of ' // pdbname(istart:IFIN)
 
      IF (LHSSP_LONG_ID) THEN
         NPARALINE=NPARALINE+1
         CPARAMETER(NPARALINE)='  LONG-ID : YES'
      ENDIF
      
      LDELETE = .FALSE.
      DO I= 1,NALIGN
         SEQ2 =          ' '
         CALL GET_SEQ_FROM_ALISEQ(ALISEQ,IFIR,ILAS,ALIPOINTER,
     1        ALILEN,I,SEQ2,NREAD,ERROR)
         IF ( ERROR ) STOP
         CALL IDENTITY(IFIR(I),ILAS(I),CGAPCHAR,SEQ1,SEQ2,THISIDE,
     1        NOVERLAP)
         IDE(I)=         THISIDE
         LALI(I)=        ILAS(I)-IFIR(I)+1
         CALL MARK_LOC_RUNS(LDELETE,SEQ2,IFIR(I),ILAS(I),
     1        CGAPCHAR,DELPOS,LGAP(I),NGAP(I))
         SEQ2 =          ' '
         JFIR(I)=        1
         JLAS(I)=        LALI(I)-LGAP(I)
         LENSEQ(I)=      JLAS(I)
         PROTNAME(I)=    ' '
         EXCLUDEFLAG(I)= ' '
         STRID(I)=       ' '
         ACCNUM_HSSP(I)= ' '
      ENDDO
      DO I = 1,ALILEN
         SECSTR_HSSP(I)= ' '
         SHEETLABEL(I)=  ' '
         CHAINID(I)=     ' '
         PDBNO(I)=       I
         COLS(I)=        ' '
         ACC(I)=         0
         BP1(I)=         0
         BP2(I)=         0
         CONSWEIGHT(I)=  1.0
      ENDDO
      CALL GETDATE(CDATE)
      ISAFE=             0
      NRES=              ALILEN

C---- 
C---- get similarity metric and scale according to smin/smax
C---- 
      CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,
     +     MAXIOSTATES,NSTRSTATES,NIOSTATES,
     +     NSTRSTATES,NIOSTATES,CSTRSTATES,
     +     CIOSTATES,IORANGE,KSIM,METRICFILE,MATRIX)
C---- 
C---- 98-10: br & rs 
C---- normalise MATRIX -> SIMCONSERV
C----    such that SIMCONSERV has an average of 0
C---- 
      CALL SETCONSERVATION(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES,NIOSTATES,CSTRSTATES,CIOSTATES,IORANGE,KSIM,
     +     METRICFILE,MATRIX,SIMCONSERV)
C---- 
C---- 98-10: br
C---- 98-10: br & rs 
C---- compile conservation weights
C---- 99-03: br add sequence similarity
C---- 
C      WRITE(6,*)'XX BEFORE CONS PDB='
C      WRITE(6,'(40A1)')(PDBSEQ(I),I=1,NRES)

      CALL GETCONSWEIGHT_BR(MAXSTRSTATES,MAXIOSTATES,
     +     MAXRES,MAXALIGNS,MAXCORE,NTRANS,NASCII,NALIGN,NRES,
     +     IDE,IFIR,ILAS,LALI,ALIPOINTER,PDBSEQ,ALISEQ,
     +     EXCLUDEFLAG,TRANS,MATRIX,SIMCONSERV,MATPOS,
     +     CONSWEIGHT_MIN,CONSWEIGHT)
C      STOP 'xx after get cons'
C---- 
C---- rescale metric
C---- 
      CALL SCALEMETRIC(NTRANS,TRANS,MAXSTRSTATES,
     +     MAXIOSTATES,MATRIX,SMIN,SMAX,MAPLOW,MAPHIGH)

C----        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
C---- 
C---- 99-03: br add sequence similarity
Cxxxxxxxxx   wanted to, failed...
C----        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
C---- 
C      CALL GETSEQSIM_BR(MAXSTRSTATES,MAXIOSTATES,
C     +     MAXRES,MAXALIGNS,NTRANS,NASCII,NALIGN,NRES,
C     +     IFIR,ILAS,LALI,ALIPOINTER,PDBSEQ,ALISEQ,
C     +     EXCLUDEFLAG,TRANS,MATRIX,SIMCONSERV,MATPOS,SIM,
C     +     CONSWEIGHT)
C----        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
C---- 
C---- calculate variability
C---- 
      CALL CALC_VAR(NALIGN,ALILEN,PDBSEQ,IDE,IFIR,
     +     ILAS,ALIPOINTER,ALISEQ,EXCLUDEFLAG,
     +     MAXSTRSTATES,MAXIOSTATES,NTRANS,TRANS,
     +     MATRIX,VAR)
C---- 
C---- profiles
C---- 
      CALL CALC_PROF(MAXRES,MAXAA,ALILEN,PDBSEQ,NALIGN,
     +     EXCLUDEFLAG,IDE,IFIR,ILAS,
     +     ALISEQ,ALIPOINTER,TRANS,
     +     SEQPROF,NOCC,NDEL,NINS,ENTROPY,RELENT)
C---- 
C---- finally write the HSSP file
C---- 

C---- write header
      CALL HSSPHEADER(KOUT,OUTNAME,HSSPLINE,PDBID,CDATE,
     +     DATABASE,CPARAMETER,NPARALINE,
     +     ISOSIGFILE,ISAFE,LFORMULA,
     +     HEADER,COMPOUND,SOURCE,AUTHOR,ALILEN,
     +     NCHAIN,KCHAIN,CHAINREMARK,NALIGN)

C---- write data (alignments)
      CALL WRITE_HSSP(KOUT,MAXRES,NALIGN,ALILEN,EMBLID,STRID,
     +     ACCNUM_HSSP,IDE,SIM,IFIR,ILAS,JFIR,JLAS,
     +     LALI,NGAP,LGAP,LENSEQ,PROTNAME,ALIPOINTER,
     +     ALISEQ,PDBNO,CHAINID,PDBSEQ,SECSTR_HSSP,COLS,
     +     BP1,BP2,SHEETLABEL,ACC,NOCC,VAR,SEQPROF,
     +     NDEL,NINS,ENTROPY,RELENT,CONSWEIGHT,
     +     INSNUMBER,INSALI,INSPOINTER,INSLEN,
     +     INSBEG_1,INSBEG_2,INSBUFFER,ISOLEN,
     +     ISOIDE,NSTEP,LFORMULA,LALL,ISAFE,
     +     EXCLUDEFLAG,LCONSERV,LHSSP_LONG_ID)
 
C finally restore aliseq data structure (! THINK OF SOMETHING BETTER ! )
      LINSERT = .TRUE.
      LDELETE = .FALSE.
      CALL CHANGE_ALISEQ(MAXALIGNS,MAXCORE,MAXINS,MAXRES,LINSERT,
     1     LDELETE,CHANGEPOS,NALIGN,PDBSEQ,SEQSTART,SEQSTOP,
     2     PDBNAME,ALILEN,ALISEQ,ALIPOINTER,IFIR,ILAS,JFIR,
     3     JLAS,LALI,NGAP,LGAP,LENSEQ,STRID,IDE,SIM,
     4     EXCLUDEFLAG,ACCNUM_HSSP,EMBLID,PROTNAME,INSALI,
     5     INSNUMBER)
 
      RETURN
      END
C     END MAKE_HSSP
C......................................................................
 
C......................................................................
C     SUB MARK_DUPLICATES
      SUBROUTINE MARK_DUPLICATES(LIST,NENTRIES)
C 12.8.93
      IMPLICIT        NONE
C Import
      INTEGER         NENTRIES
C Import / Export
      CHARACTER*(*)   LIST(*)
C Internal
      INTEGER         ENTRYLEN
      PARAMETER      (ENTRYLEN=                 41)
      INTEGER         I,J,ISTART,ISTOP,JSTART,JSTOP,NTIMES
      CHARACTER*(ENTRYLEN) CSTRING
*----------------------------------------------------------------------*
      
      
      DO J = 1,NENTRIES-1
         NTIMES = 1
         CALL STRPOS(LIST(J),JSTART,JSTOP)
         DO I = J+1,NENTRIES
            CALL STRPOS(LIST(I),ISTART,ISTOP)
            IF ( LIST(J)(JSTART:JSTOP) .EQ.
     1           LIST(I)(ISTART:ISTOP)      ) THEN
               NTIMES = NTIMES + 1
               CALL CONCAT_STRING_INT(LIST(I),NTIMES,CSTRING)
               LIST(I)(1:40) = CSTRING
            ENDIF
         ENDDO
      ENDDO
 
      RETURN
      END
C     END MARK_DUPLICATES
C......................................................................
 
C......................................................................
C     SUB MARK_LOC_RUNS
***** ------------------------------------------------------------------
***** SUB MARK_LOC_RUNS
***** ------------------------------------------------------------------
C---- 
C---- NAME : MARK_LOC_RUNS
C---- ARG  : 1 LDELETE=       logical if true: delete from sequence
C---- ARG  : 2 SEQUENCE=      string
C---- ARG  : 3 IBEG=          first residue position in SEQUENCE
C---- ARG  : 4 IEND=          last residue position in SEQUENCE
C---- ARG  : -->              SEQUENCE(IBEG:IEND)
C---- ARG  : 5 SYMBOL         character to search (count and delete)
C---- ARG  : 6 RUNPOS         
C---- ARG  : 7 RUNLEN         
C---- ARG  : 8 NRUN           number of occurrences of SYMBOL in 
C---- ARG  :                  SEQUENCE
C---- DES  : Checks how often SYMBOL occurs in SEQUENCE, possibly
C---- DES  : deletes it (e.g. remove insertions!)
C---- 
*----------------------------------------------------------------------*
      SUBROUTINE MARK_LOC_RUNS(LDELETE,SEQUENCE,IBEG,IEND,
     1     SYMBOL,RUNPOS,RUNLEN,NRUN)
C 5.7.93
C 20.10. only internal runs
      IMPLICIT        NONE
C Import
C ..  "begin", "end" is left unchanged, 
C     even if some positions are actually deleted !!
      INTEGER         IBEG, IEND

      INTEGER         RUNLEN
      CHARACTER*1     SYMBOL
      LOGICAL         LDELETE

C Import/Export
      CHARACTER*(*)   SEQUENCE
C Export
      INTEGER         NRUN
      INTEGER         RUNPOS(2,*)
C Internal
      INTEGER         LAST_NONSYMBOL,IPOS,JPOS,RLEN,IRUN
      LOGICAL         INSIDE, IS_LOC_RUN
******------------------------------*-----------------------------******
 
C---- ini
      NRUN=          0
      RUNLEN=        0
      INSIDE=        .FALSE.
      IS_LOC_RUN=    .FALSE.
      LAST_NONSYMBOL=IEND
C---- 
C---- loop over all residues of sequence
C----    
C----    NRUN=        number of occurrences of SYMBOL
C----    RUNPOS(1,i)= [i=1,NRUN] the position of the ith occurrence
C----    RUNPOS(2,i)= [i=1,NRUN] ?? 
C----    LAST_NONSYMBOL=position of the last NON-hit (counts up)
C----    

      DO IPOS=IBEG,IEND
C------- is insertion ('.')
         IF ( SEQUENCE(IPOS:IPOS) .EQ. SYMBOL .AND. 
     +        IS_LOC_RUN .EQV. .TRUE. ) THEN
            IF ( .NOT. INSIDE ) THEN
               INSIDE=         .TRUE.
               NRUN=           NRUN + 1
               RUNPOS(1,NRUN)= IPOS
               RUNPOS(2,NRUN)= 0
            ENDIF
            RUNPOS(2,NRUN)=    RUNPOS(2,NRUN) + 1
            RUNLEN=            RUNLEN + 1
C------- is NOT insertion
         ELSE IF ( SEQUENCE(IPOS:IPOS) .NE. SYMBOL ) THEN
C---------- reset flag
            IF ( INSIDE )      INSIDE = .FALSE.
            IS_LOC_RUN=        .TRUE.
            LAST_NONSYMBOL=    IPOS
         ENDIF
      ENDDO

C---- trailing insertion - DO NOT COUNT
C----    -> reduce by 1!
      IF (NRUN.GT.0) THEN
         IF ( RUNPOS(1,NRUN) .EQ. LAST_NONSYMBOL+1 ) THEN
            NRUN=NRUN - 1
         ENDIF
      ENDIF
      
      IF ( LDELETE .AND. (NRUN.GT.0) ) THEN
         RLEN = 0
         IRUN = 1
         DO IPOS = IBEG,IEND
            IF ( IPOS .EQ. RUNPOS(1,IRUN) ) THEN
               DO JPOS = IPOS-RLEN,IEND-RUNPOS(2,IRUN)
                  SEQUENCE(JPOS:JPOS) =
     1                 SEQUENCE(JPOS+RUNPOS(2,IRUN):JPOS+RUNPOS(2,IRUN))
               ENDDO
               RLEN = RLEN + RUNPOS(2,IRUN)
               IRUN = IRUN + 1
            ENDIF
         ENDDO
      ENDIF
      RETURN
      END
C     END MARK_LOC_RUNS
C......................................................................
 
C......................................................................
C     SUB SETCONSERVATION
      SUBROUTINE SETCONSERVATION(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES,NIOSTATES,CSTRSTATES,CIOSTATES,IORANGE,KSIM,
     +     METRIC_FILENAME,MATRIX,SIMCONSERV)
C 1. set conservation weights to 1.0
C 2. rescale matrix for the 22 amino residues such that the sum over
C    the matrix is 0.0 (or near)
C this matrix is used to calculate the conservation weights (SIMCONSERV)
c	implicit none
C import
      CHARACTER*(*)   METRIC_FILENAME
      REAL            MATRIX(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                      MAXSTRSTATES,MAXIOSTATES)
      REAL            SIMCONSERV(1:26,1:26)
      INTEGER         NSTRSTATES,NIOSTATES,KSIM
      CHARACTER*(*)   CSTRSTATES,CIOSTATES
      REAL            IORANGE(MAXSTRSTATES,MAXIOSTATES)
     
C internal
      INTEGER         NACID,MAXSQ
      PARAMETER      (NACID=                    22)
      PARAMETER      (MAXSQ=                100000)

      CHARACTER       TRANS*26

      INTEGER         I,J
      REAL            XLOW,XHIGH,XMAX,XMIN,XFACTOR,SUMMAT
      REAL            CONSWEIGHT_1(MAXSQ),CONSWEIGHT_2(MAXSQ),CONSMIN
      LOGICAL         LFIRSTWEIGHT
*----------------------------------------------------------------------*

C
      DO I=1,MAXSQ 
         CONSWEIGHT_1(I)=1.0
      ENDDO
      LFIRSTWEIGHT=.TRUE.

C     get metric
C     98-10 br: already done
C      CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
C     +     NSTRSTATES,NIOSTATES,NSTRSTATES,NIOSTATES,
C     +     CSTRSTATES,CIOSTATES,IORANGE,KSIM,METRIC_FILENAME,MATRIX)

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

C......................................................................
C     SUB STRREPLACE
      SUBROUTINE STRREPLACE(STRING,LENGTH,C1,C2)
c	Implicit None
C replaces all occurences of c1 by c2
 
C Import
      INTEGER         LENGTH
      CHARACTER*1     C1, C2
C Import/Export
      CHARACTER*(*)   STRING
C Internal
      INTEGER IPOS
      
      DO IPOS = 1,LENGTH
         IF ( STRING(IPOS:IPOS) .EQ. C1 ) STRING(IPOS:IPOS) = C2
      ENDDO
 
      RETURN
      END
C     END STRREPLACE
C......................................................................
 
C......................................................................
C     SUB WRITE_DAF
      SUBROUTINE WRITE_DAF(KUNIT,INFILE,OUTFILE,MAXALIGNS,MAXRES,
     1     MAXCORE,MAXINS,MAXINSBUF,BEGIN,END,ALISEQ,
     2     ALIPOINTER,IDE,IFIR,ILAS,EMBLID,WEIGHT,
     3     ALILEN,NSEQ,LALI,INSNUMBER,INSALI,INSPOINTER,
     4     INSLEN,INSBEG_1,INSBUFFER,ERROR)

      IMPLICIT        NONE
C---- import
      INTEGER         MAXALIGNS,MAXRES,MAXCORE,MAXINS,MAXINSBUF,
     +                KUNIT,BEGIN,END,NSEQ,ALILEN,INSNUMBER
      INTEGER         ALIPOINTER(MAXALIGNS),LALI(MAXALIGNS),
     +                IFIR(MAXALIGNS),ILAS(MAXALIGNS),
     +                INSALI(MAXINS),INSPOINTER(MAXINS),
     +                INSLEN(MAXINS),INSBEG_1(MAXINS)
      CHARACTER*(*)   INFILE, OUTFILE
      CHARACTER*(*)   EMBLID(MAXALIGNS)
      CHARACTER       ALISEQ(MAXCORE),INSBUFFER(MAXINSBUF)
      REAL            WEIGHT(MAXALIGNS),IDE(MAXALIGNS)
C---- export
      LOGICAL         ERROR
C---- internal
      INTEGER         LINELEN,MAXRES_INTERN,MAXALIGNS_INTERN
      PARAMETER      (MAXRES_INTERN=         10000)
      PARAMETER      (LINELEN=               22000)
      PARAMETER      (MAXALIGNS_INTERN=      10000)
      INTEGER         CODELEN,I,J,ISTART,ISTOP,ISEQ,IINS,K,
     +                IPOS,JPOS,KPOS,LENSEQ(MAXALIGNS_INTERN)
      CHARACTER*8     TIMESTRING
      CHARACTER*9     DATESTRING
      CHARACTER*(LINELEN) LINE
      CHARACTER*(MAXRES_INTERN) STRAND,SEQ1_STRING
      CHARACTER*50    TRANS
C---- ------------------------------------------------------------------ 
C---- ini
      ERROR=  .FALSE.
      TRANS=  'VLIMFWYGAPSTCHRKQENDBZX.'
C---- try to open outfile; return if unsuccessful	
      CALL OPEN_FILE(KUNIT,OUTFILE,'new,recl=22000',error)
C---- error messages are alredy issued by OPEN_FILE
      IF (ERROR) RETURN
      IF (NSEQ.GT.MAXALIGNS) THEN
         WRITE(*,'(1X,A)') 'MAXALIGNS (global) overflow in write_daf !'
         ERROR = .TRUE.
         RETURN
      ENDIF
      IF (NSEQ.GT.MAXALIGNS_INTERN) THEN
         WRITE(*,'(1X,A)') 'MAXALIGNS (intern) overflow in write_daf !'
         ERROR= .TRUE.
         RETURN
      ENDIF
      IF (ALILEN.GT.MAXRES) THEN
         WRITE(*,'(1X,A)') 'MAXRES (global) overflow in write_daf !'
         ERROR= .TRUE.
         RETURN
      ENDIF
      IF (ALILEN.GT.MAXRES_INTERN ) THEN
         WRITE(*,'(1X,A)') 'MAXRES (intern) overflow in write_daf !'
         ERROR= .TRUE.
         RETURN
      ENDIF
C---- ------------------------------------------------------------------ 
C---- start
      CODELEN = 1
      DO I=1,NSEQ
         CALL STRPOS(EMBLID(I),ISTART,ISTOP)
         IF (ISTOP.GT.CODELEN) CODELEN=ISTOP+2
      ENDDO
      IF (CODELEN.GT.LEN(EMBLID(1))) CODELEN=LEN(EMBLID(1))
C----
C---- header
C----
      WRITE(KUNIT,'(A)') '# DAF (dirty alignment format)'
      CALL STRPOS(INFILE,ISTART,ISTOP)
      WRITE(KUNIT,'(A,A,A,I4,A,I4)')
     +     '# SOURCE:       converted from ',
     +     infile(istart:istop),' from: ',begin,' to: ',end
C---- get current date and time
      CALL GETDATE(DATESTRING)
      CALL GETTIME(TIMESTRING)
      WRITE(KUNIT,'(A,A,A)')
     1     '# DATE:         ',DATESTRING,TIMESTRING
      WRITE(KUNIT,'(A,A)')  '# ALISYM:       ',TRANS
      WRITE(KUNIT,'(A,I6)') '# NPAIRS:       ',NSEQ
      WRITE(KUNIT,'(A)') '#'
      WRITE(KUNIT,'(A)') '#'
      WRITE(KUNIT,'(A)') '# ALIGNMENTS'
      WRITE(KUNIT,'(A)') 'idSeq idStr lenSeq lenStr '//
     +     'lenAli pide seq str'
C----
C---- sequence information
C----
      DO ISEQ=2,NSEQ
         SEQ1_STRING=' '
         STRAND= ' '
         J = 1
         JPOS = ALIPOINTER(ISEQ)
         LENSEQ(ISEQ)=ILAS(ISEQ)-IFIR(ISEQ)+1
         DO IPOS = IFIR(ISEQ),ILAS(ISEQ)
            IF ( ICHAR(ALISEQ(JPOS)) .GT. 96 .AND.
     +           ICHAR(ALISEQ(JPOS)) .LT. 123) THEN
               STRAND(J:J) = ALISEQ(JPOS)
               CALL LOWTOUP(STRAND(J:J),1)
               SEQ1_STRING(J:J) = ALISEQ(IPOS)
               J = J + 1
               JPOS=JPOS+1
               DO IINS=1,INSNUMBER
                  IF(INSALI(IINS) .EQ. ISEQ .AND.
     +                 INSBEG_1(IINS) .EQ. IPOS)THEN
                     KPOS=INSPOINTER(IINS)+1
                     DO K=1,INSLEN(IINS)
                        STRAND(J:J) = INSBUFFER(KPOS)
                        SEQ1_STRING(J:J) = '.'
                        J=J+1
                        KPOS=KPOS+1
                     ENDDO
                  ENDIF
               ENDDO
            ELSE
               STRAND(J:J) = ALISEQ(JPOS)
               SEQ1_STRING(J:J) = ALISEQ(IPOS)
               J = J + 1
               JPOS=JPOS+1
            ENDIF
 
         ENDDO
         CALL STRPOS(STRAND,I,J)
 
C         WRITE(KUNIT,'(A,1X,A,1X,F7.1,1X,A,A,A)')
         WRITE(KUNIT,'(A,1X,A,1X,I6,I6,I6,F7.1,1X,A,A,A)')
     +        EMBLID(1)(1:CODELEN),
     +        EMBLID(ISEQ)(1:CODELEN),
     +        ALILEN,LALI(ISEQ),LENSEQ(ISEQ),
     +        (IDE(ISEQ)*100.0),SEQ1_STRING(I:J),'  ',STRAND(I:J)
 
      ENDDO
      CLOSE(KUNIT)
 
      RETURN
      END
C END WRITE_DAF...................................................

