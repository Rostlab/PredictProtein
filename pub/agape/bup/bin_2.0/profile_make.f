*----------------------------------------------------------------------*
*                                                                      *
*     FORTRAN code for program MAKE_PROFILE                            *
*             makes a profile from an HSSP file                        *
*             this profile can be used for MaxHom                      *
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
*     General note:   - uses library lib-profile-make.f                *
*                                                                      *
*----------------------------------------------------------------------*
*                                                                      *
*     Description (from RS):                                           *
*                                                                      *

      PROGRAM MAKE_PROFILE

      IMPLICIT      NONE
C----
C---- overall memory limiting parameters
C----
      INTEGER       MAXALIGNS,MAXRES,MAXCORE,MAXAA
      PARAMETER    (MAXALIGNS=     2000)
      PARAMETER    (MAXRES=        3000)
      PARAMETER    (MAXCORE=     100000)
      INTEGER       MAXINS,MAXINSBUFFER
      PARAMETER    (MAXINS=       10000)
      PARAMETER    (MAXINSBUFFER=500000)
      PARAMETER    (MAXAA=           20)
C----
C---- other parameters
C----
      INTEGER       NTRANS
      PARAMETER    (NTRANS=26)

      INTEGER       MAXSTRSTATES,MAXIOSTATES
      PARAMETER    (MAXSTRSTATES=4,MAXIOSTATES=4)

      INTEGER       MAXBOX
      PARAMETER    (MAXBOX=100)
C----
C---- attributes of sequence with known structure
C----
      CHARACTER*40  PDBID
      CHARACTER     HEADER*40,COMPOUND*80,SOURCE*80,AUTHOR*80	
      CHARACTER     PDBSEQ(MAXRES),CHAINID(MAXRES),SECSTRUC(MAXRES)
      CHARACTER     COLS(MAXRES)*7,SHEETLABEL(MAXRES)
      CHARACTER*80  CHAINREMARK
      INTEGER       LSECSTRUC(MAXRES)
      INTEGER       PDBNO(MAXRES),NCHAIN,KCHAIN,NALIGN
      INTEGER       BP1(MAXRES),BP2(MAXRES),NACC(MAXRES)
C----
C---- attributes of alignend sequences
C----
      CHARACTER     EMBLID(MAXALIGNS)*40,STRID(MAXALIGNS)*5
      CHARACTER     ACCESSION(MAXALIGNS)*12
      CHARACTER     PROTNAME(MAXALIGNS)*60
      CHARACTER     ALISEQ(MAXCORE)
      CHARACTER     EXCLUDEFLAG(MAXALIGNS)
      INTEGER       ALIPOINTER(MAXALIGNS)
      INTEGER       IFIR(MAXALIGNS),ILAS(MAXALIGNS),JFIR(MAXALIGNS)
      INTEGER       JLAS(MAXALIGNS),LALI(MAXALIGNS),NGAP(MAXALIGNS)
      INTEGER       LGAP(MAXALIGNS),LENSEQ(MAXALIGNS)
      REAL          IDE(MAXALIGNS),SIM(MAXALIGNS)

C----
C---- BUFFER TO STORE INSERTIONS OF ALIGNMENTS
C----
      CHARACTER     INSBUFFER(MAXINSBUFFER)
      COMMON/CINSBUFFER/INSBUFFER
C----
C---- points to selected alignments in INSBUFFER
C----

      INTEGER       INSNUMBER,INSALI(MAXINS),INSPOINTER(MAXINS)
      INTEGER       INSLEN(MAXINS),INSBEG_1(MAXINS),INSBEG_2(MAXINS)
      COMMON/CINSBUFFERPOINTER/INSNUMBER,INSALI,INSPOINTER,INSLEN,
     +                         INSBEG_1,INSBEG_2
 
C----
C---- attributes of profile
C----
      INTEGER       VAR(MAXRES)
      INTEGER       SEQPROF(MAXRES,MAXAA)
      INTEGER       NOCC(MAXRES),NDEL(MAXRES),NINS(MAXRES)
      INTEGER       RELENT(MAXRES)
      REAL          ENTROPY(MAXRES)
C.......
      REAL          SUM
      LOGICAL       LERROR
      LOGICAL       LCONSERV,LHSSP_LONG_ID
C----
C---- used for smoothing the profile
C----
      REAL          SIGMA,BETA
C----
C---- used for de-log metrices
C----
      REAL          SCALE_FACTOR,LOG_BASE
 
      CHARACTER     TRANS*(NTRANS)
      INTEGER       NSTRSTATES_1,NIOSTATES_1
      INTEGER       NSTRSTATES_2,NIOSTATES_2
      COMMON/STRSTATES/ NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,
     +                  NIOSTATES_2
 
      CHARACTER     CSTRSTATES*(MAXSTRSTATES),CIOSTATES*(MAXIOSTATES)
      CHARACTER*10  STR_CLASSES(MAXSTRSTATES)
      CHARACTER     STRCLASS*(MAXRES)
 
      REAL          IORANGE(MAXSTRSTATES,MAXIOSTATES)
      REAL          SIMORG(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +              MAXSTRSTATES,MAXIOSTATES)
 
      INTEGER       MSFCHECK
C 'P' = protein sequences, 'N' = nucleotide seq
      CHARACTER*1   TYPE
      INTEGER       SEQCHECK(MAXALIGNS)
 
      INTEGER       LSEQ(MAXRES),LACC(MAXRES)
      REAL          GAPOPEN(MAXRES),GAPELONG(MAXRES),CONSWEIGHT(MAXRES)
      REAL          OPEN_GAP,ELONG_GAP
      REAL          PROFILEMETRIC(MAXRES,NTRANS)
      
      REAL          SMIN,SMAX,MAPLOW,MAPHIGH
 
      INTEGER       NBOX
      INTEGER       PROFILEBOX(MAXBOX,2)
      
      REAL          WEIGHTS(MAXALIGNS)
 
      LOGICAL       LDSSP,LHSSP,LPROFILE,LMSF
      LOGICAL       LPROPERTY
 
      CHARACTER*80  PROFILEOUT,METRICFILE
      INTEGER       NRES,LRES
      INTEGER       KIN,KOUT,KSIM,KDEF,KWEI
      CHARACTER*80  FILENAME,WEIGHTFILE
      CHARACTER     HSSPID*40,SEQFORMAT*40,QUESTION*500
      CHARACTER*80  TEMPSTRING
      CHARACTER     CRESID(MAXRES)*6,ACCNUM*12,PDBREF*20
	
 
      CHARACTER     WEIGHT_MODE*20
      INTEGER       I,J,K,L,K1,K2,L1,L2,IBEG,IEND,LENGTH,IBOX,IRES
      CHARACTER     TEMPSEQ*(MAXRES),TEMPSTRUC*(MAXRES)
 
      CHARACTER*80  KEYWORD
      CHARACTER     METRICPATH*80,DEFAULT_FILE*80,CMACHINE*10
      CHARACTER*200 LINE
      
      CHARACTER     ALILINE(MAXALIGNS)*(MAXRES)
 
      INTEGER       LOWERPOS(256)
      CHARACTER     LOWER*26,CTEMP
      INTEGER       NTRIALS
C---- end of variables
C---- ------------------------------------------------------------------
C---- 
C---- used to convert lower case characters from DSSP-seq to 'C' (Cys)
C---- 
      LOWER=        'abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,256)

C---- 
C---- initialisation
C---- 
C     file handles
      KIN=           10 
      KOUT=          11 
      KSIM=          12 
      KDEF=          13 
      KWEI=          14
C---- 

C---- 
C     other characters
C---- 
      CMACHINE=      'VMS'
      PDBID=         ' ' 
      HEADER=        ' ' 
      COMPOUND=      ' ' 
      SOURCE=        ' ' 
      AUTHOR=        ' '
      CHAINREMARK=   ' '
      KEYWORD=       ' '
      WEIGHT_MODE=   'EIGEN'
      TRANS=         'VLIMFWYGAPSTCHRKQENDBZX!-.'
      STR_CLASSES(1)='EBAPMEBAPM'
      STR_CLASSES(2)='L TCSTCLSS'
      STR_CLASSES(3)='HGIHGIIIII'
      STR_CLASSES(4)='!!!!!!!!!!'
C---- 
C---- alignment stuff
C---- 
      OPEN_GAP=      3.0 
      ELONG_GAP=     0.1
      SMIN=         -0.5 
      SMAX=          1.0 
      MAPLOW=        0.0 
      MAPHIGH=       0.0
      NSTRSTATES_1=  1 
      NIOSTATES_1=   1 
      NSTRSTATES_2=  1 
      NIOSTATES_2=   1
      CSTRSTATES=    ' ' 
      CIOSTATES=     ' '
      LINE=          ' '
      LHSSP_LONG_ID=.FALSE.
C---- 
C---- 
C---- 
C---- ------------------------------------------------------------------
C---- read file with defaults
C---- ------------------------------------------------------------------
C---- 
      DEFAULT_FILE='/home/rost/pub/max/mat/profile_make.default'
      CALL GET_DEFAULT(KDEF,DEFAULT_FILE,CMACHINE,METRICPATH,
     +     LINE,SMIN,SMAX,MAPLOW,MAPHIGH,OPEN_GAP,
     +     ELONG_GAP,WEIGHT_MODE)
      CALL STRPOS(METRICPATH,I,J)
      CALL STRPOS(LINE,K,L)
      METRICFILE(1:)=METRICPATH(I:J)//LINE(K:L)
C=======================================================================
      DO I=1,MAXRES
         PDBSEQ(I)=      ' ' 
         CHAINID(I)=     ' ' 
         SECSTRUC(I)=    ' '
         COLS(I)=        ' ' 
         SHEETLABEL(I)=  ' ' 
         PDBNO(I)=       0 
         BP1(I)=         0 
         BP2(I)=         0 
         NACC(I)=        0 
         VAR(I)=         0
         NOCC(I)=        0 
         NDEL(I)=        0 
         NINS(I)=        0 
         RELENT(I)=      0
         ENTROPY(I)=     0.0
         LSEQ(I)=        0 
         LACC(I)=        0 
         GAPOPEN(I)=     0.0 
         GAPELONG(I)=    0.0
         CONSWEIGHT(I)=  1.0
         DO J=1,MAXAA
            SEQPROF(I,J)=0
         ENDDO
         DO J=1,NTRANS
            PROFILEMETRIC(I,J)=0.0
         ENDDO
      ENDDO
      DO I=1,MAXALIGNS
         EMBLID(I)=      ' ' 
         STRID(I)=       ' ' 
         PROTNAME(I)=    ' '
         EXCLUDEFLAG(I)= ' ' 
         ALIPOINTER(I)=  0 
         IFIR(I)=        0 
         ILAS(I)=        0
         JFIR(I)=        0 
         JLAS(I)=        0 
         LALI(I)=        0 
         NGAP(I)=        0 
         LGAP(I)=        0
         LENSEQ(I)=      0
         WEIGHTS(I)=     1.0
      ENDDO
      DO I=1,MAXCORE
         ALISEQ(I)=      ' '
      ENDDO
      DO I=1,NTRANS 
         DO J=1,NTRANS
            DO K1=1,MAXSTRSTATES 
               DO L1=1,MAXIOSTATES
                  DO K2=1,MAXSTRSTATES 
                     DO L2=1,MAXIOSTATES
                        SIMORG(I,J,K1,L1,K2,L2)=0.0
                     ENDDO
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
C accessibility cut to 200% = take all
      DO I=1,MAXSTRSTATES 
         DO J=1,MAXIOSTATES
            IORANGE(I,J)=200.0
         ENDDO
      ENDDO
 
      DO I=2,MAXBOX
         PROFILEBOX(I,1)=0 
         PROFILEBOX(I,2)=0
      ENDDO
      LDSSP=    .FALSE. 
      LHSSP=    .FALSE. 
      LPROFILE= .FALSE.
      LERROR=   .FALSE.
      TEMPSEQ=  ' ' 
      TEMPSTRUC=' '
 
C==================================================================
      NTRIALS=0
      FILENAME='/data/hssp/5p21.hssp'
 100  QUESTION=' Make profile for which sequence ? /n'//
     +       ' (format: HSSP,MAXHOM_PROFILE,MSF,DSSP,GCG,PIR,SWISSPROT)'
      CALL GETCHAR(80,FILENAME,QUESTION)
      CALL CHECKFORMAT(KIN,FILENAME,SEQFORMAT,LERROR)	
 
      IF ( LERROR ) THEN
         IF ( NTRIALS .LT. 3 ) THEN
            NTRIALS = NTRIALS + 1
            GOTO 100
         ELSE
            STOP 'NO VALID SEQUENCE FILE GIVEN ! '
         ENDIF
      ENDIF
 
      WRITE(*,*)' seqformat: ',SEQFORMAT
 
      LHSSP=INDEX(SEQFORMAT,'HSSP') .NE. 0
      LMSF=INDEX(SEQFORMAT,'MSF') .NE. 0
      LPROFILE=INDEX(SEQFORMAT,'PROFILE') .NE. 0
      IF(INDEX(SEQFORMAT,'DSSP') .NE. 0 .OR.
     +     INDEX(SEQFORMAT,'PROFILE-DSSP') .NE.0) THEN
         LDSSP=.TRUE.
      ENDIF
 
      LENGTH=INDEX(FILENAME,'!')-1
      IF(LENGTH .LE. 0)LENGTH=LEN(FILENAME)
      CALL GETPIDCODE(FILENAME(1:LENGTH),HSSPID)
 
      IF(LPROFILE) THEN
         CALL READPROFILE(KIN,FILENAME,MAXRES,
     +        NTRANS,TRANS,LDSSP,
     +        NRES,NCHAIN,PDBID,HEADER,COMPOUND,SOURCE,AUTHOR,
     +        SMIN,SMAX,MAPLOW,MAPHIGH,METRICFILE,
     +        PDBNO,CHAINID,PDBSEQ,SECSTRUC,
     +        NACC,COLS,SHEETLABEL,
     +        BP1,BP2,NOCC,GAPOPEN,
     +        GAPELONG,CONSWEIGHT,PROFILEMETRIC,
     +        MAXBOX,NBOX,PROFILEBOX)
 
      ELSE IF(LHSSP) THEN
         CALL READHSSP(KIN,FILENAME,LERROR,
     +        MAXRES,MAXALIGNS,MAXCORE,MAXINS,MAXINSBUFFER,
     +        PDBID,HEADER,COMPOUND,SOURCE,AUTHOR,NRES,
     +        NCHAIN,KCHAIN,CHAINREMARK,NALIGN,
     +        EXCLUDEFLAG,EMBLID,STRID,IDE,SIM,IFIR,ILAS,
     +        JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,ACCESSION,
     +        PROTNAME,
     +        PDBNO,PDBSEQ,CHAINID,SECSTRUC,COLS,SHEETLABEL,BP1,
     +        BP2,NACC,NOCC,VAR,ALISEQ,ALIPOINTER,
     +        SEQPROF,NDEL,NINS,ENTROPY,RELENT,CONSWEIGHT,
     +        INSNUMBER,INSALI,INSPOINTER,INSLEN,
     +        INSBEG_1,INSBEG_2,INSBUFFER,LCONSERV,
     +        LHSSP_LONG_ID)

         IF(NALIGN .LE. 1) THEN
            WRITE(*,*)'not enough alignments'
            STOP
         ENDIF
      ELSE IF(LDSSP) THEN
         CALL GETDSSPFORHSSP(KIN,FILENAME,MAXRES,CHAINREMARK,
     +        PDBID,HEADER,COMPOUND,SOURCE,AUTHOR,NRES,LRES,NCHAIN,
     +        KCHAIN,PDBNO,CHAINID,PDBSEQ,SECSTRUC,
     +        COLS,BP1,BP2,SHEETLABEL,NACC)
      ELSE IF(LMSF) THEN
         CALL READ_MSF(KIN,FILENAME,MAXALIGNS,MAXCORE,ALISEQ,
     +        ALIPOINTER,IFIR,ILAS,JFIR,JLAS,TYPE,EMBLID,WEIGHTS,
     +        SEQCHECK,MSFCHECK,NRES,NALIGN,LERROR)
C copy first seq from aliseq to pdbseq
      ELSE
         CALL GETSEQ(KIN,MAXRES,NRES,CRESID,PDBSEQ,SECSTRUC,
     +        NACC,LDSSP,FILENAME,COMPOUND,ACCNUM,PDBREF,
     +        0,TRANS,NTRANS,KCHAIN,NCHAIN,CTEMP)
      ENDIF
 
      IF(NRES .LE. 0)GOTO 100
 
      IF(.NOT. LPROFILE) THEN
         CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +        NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,NIOSTATES_2,
     +        CSTRSTATES,CIOSTATES,IORANGE,
     +        KSIM,METRICFILE,SIMORG)
         CALL SEQTOINT(PDBSEQ,LSEQ,NRES,TRANS,NTRANS)
         CALL STR_TO_CLASS(MAXSTRSTATES,STR_CLASSES,NRES,SECSTRUC,
     +        STRCLASS,LSECSTRUC)
         CALL ACC_TO_INT(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +        NSTRSTATES_1,NIOSTATES_1,IORANGE,
     +        NRES,LSEQ,LSECSTRUC,NACC,LACC)
         write(6,*)'xx bef fill'
         CALL FILLSIMMETRIC(MAXRES,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +        NSTRSTATES_1,NSTRSTATES_2,CSTRSTATES,SIMORG,NRES,LSEQ,
     +        LSECSTRUC,LACC,PROFILEMETRIC)
         write(6,*)'xx aft fill'
      ENDIF
 
      write(6,*)'xx here '
      DO I=1,NRES
         IF( PDBSEQ(I) .NE. ' ')LDSSP=.TRUE.
         TEMPSEQ(I:I)=PDBSEQ(I)
         TEMPSTRUC(I:I)=SECSTRUC(I)
         IF(TEMPSTRUC(I:I) .EQ. ' ')TEMPSTRUC(I:I)='_'
      ENDDO
 
      write(6,*)'xx here 2'
      IF(LDSSP) THEN
         DO IRES=1,NRES
            CALL GETINDEX(PDBSEQ(IRES) ,LOWERPOS,I)
            IF(I.NE.0)PDBSEQ(IRES)='C'
         ENDDO
      ENDIF
 
      write(6,*)'xx here 3'
      IF(LHSSP) THEN
         CALL ADD_SEQ_TO_ALISEQ(MAXALIGNS,MAXCORE,1,NALIGN,
     +        PDBSEQ,1,NRES,PDBID,ALISEQ,ALIPOINTER,
     +        IFIR,ILAS,JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,STRID,
     +        IDE,SIM,EXCLUDEFLAG,ACCESSION,EMBLID,
     +        PROTNAME)
         CALL HSSP_TO_HORIZONTAL(MAXRES,ALIPOINTER,IFIR,ILAS,NALIGN,
     +        NRES,PDBSEQ,ALISEQ,ALILINE)
      ENDIF
 
      write(6,*)'xx here 4'
      CALL STRPOS(HSSPID,IBEG,IEND)
      write(6,*)'xx here 5'
      PROFILEOUT=HSSPID(IBEG:IEND)//'.profile'
      WEIGHTFILE=HSSPID(IBEG:IEND)//'.weight'
      QUESTION=' filename for profile ? '
      CALL GETCHAR(80,PROFILEOUT,QUESTION)
 
      NBOX=1
      PROFILEBOX(1,1)=1 
      PROFILEBOX(1,2)=NRES
 
      WRITE(*,*)'********** defaults *********************'
      CALL STRPOS(METRICFILE,I,J)
      WRITE(*,*)' metric    : ',metricfile(i:j)
      WRITE(*,*)' smin      : ',smin
      write(*,*)' smax      : ',smax
      write(*,*)' maplow    : ',maplow
      write(*,*)' maphigh   : ',maphigh
      write(*,*)' open_gap  : ',open_gap
      write(*,*)' elong_gap : ',elong_gap
      write(*,*)'*****************************************'
 
      DO WHILE(KEYWORD .NE. 'EXIT')
         CALL MAIN_MENU(KEYWORD)
         IF(KEYWORD .EQ. 'BOX') THEN
            CALL GET_BOX(MAXBOX,NBOX,PROFILEBOX,NRES)
            CALL SHOW_BOX(MAXBOX,NBOX,PROFILEBOX,TEMPSEQ,TEMPSTRUC,
     +           LDSSP)
         ELSE IF(KEYWORD .EQ. 'METRIC') THEN
            CALL GET_METRIC(MAXRES,NTRANS,TRANS,MAXSTRSTATES,
     +           MAXIOSTATES,NSTRSTATES_1,NIOSTATES_1,
     +           NSTRSTATES_2,NIOSTATES_2,
     +           CSTRSTATES,CIOSTATES,
     +           IORANGE,KSIM,METRICPATH,CMACHINE,
     +           LPROFILE,LDSSP,LHSSP,LPROPERTY,
     +           SMIN,SMAX,MAPLOW,MAPHIGH,SIMORG,
     +           MAXBOX,NBOX,PROFILEBOX,NALIGN,ALILINE,
     +           NRES,PDBSEQ,SECSTRUC,LSECSTRUC,STR_CLASSES,STRCLASS,
     +           NACC,LACC,LSEQ,PROFILEMETRIC,
     +           GAPOPEN,GAPELONG,METRICFILE)
         ELSE IF(KEYWORD .EQ. 'PROFILE') THEN
            WRITE(*,*)'==============================================='
            WRITE(QUESTION,'(A)')'select option: /n'//
     +           ' weight    : calculate single sequence weights /n'//
     +           ' import    : import from file /n'//
     +           ' no        : no weighting'
	
            KEYWORD='weight'
            CALL GETCHAR(80,KEYWORD,QUESTION)
            CALL LOWTOUP(KEYWORD,80)
            IF(INDEX(KEYWORD,'WEI') .NE. 0) THEN
	       WRITE(QUESTION,'(A)')' choose one the the following '//
     +              'weighting modes: /n'//
     +              ' matrix     : ......test..... /n'//
     +              ' eigenvalue : eigenvalue iteration weights /n'//
     +              ' squared    : squared eigenvectors x(i)**2 /n'//
     +              ' sum        : sum of distances w(i) /n'//
     +              ' exp        : exponential weight'
               CALL GETCHAR(20,WEIGHT_MODE,QUESTION)
               CALL LOWTOUP(WEIGHT_MODE,20)
               CALL SINGLE_SEQ_WEIGHTS(NALIGN,ALISEQ,
     +                                 ALIPOINTER,IFIR,ILAS,
     +                                 WEIGHT_MODE,WEIGHTS)
c	       call open_file(kwei,weightfile,'NEW',lerror)
c	       do i=1,nalign
c		  write(kwei,*)i,weights(i)
c	       enddo	
c	       close(kwei)
            ELSE IF(INDEX(KEYWORD,'IM') .NE. 0) THEN
               CALL GETCHAR(80,WEIGHTFILE,'filename')
               CALL OPEN_FILE(KWEI,WEIGHTFILE,'OLD',LERROR)
               I=1
               DO WHILE(.TRUE.)
                  READ(KWEI,*,END=99)WEIGHTS(I)
                  WEIGHTS(I)=WEIGHTS(I)*100
                  I=I+1
               ENDDO
 99            IF(I-1 .NE. NALIGN) THEN
                  WRITE(*,*)' i .ne. nalign :',i,nalign
                  STOP
               ENDIF
               CLOSE(KWEI)
            ENDIF
            IF (INDEX(METRICFILE,'osum') .NE. 0) THEN
	       SCALE_FACTOR=0.5 
               LOG_BASE=2.0
            ELSE
	       SCALE_FACTOR=1.0 
               LOG_BASE=10.0
            ENDIF
            WRITE(*,*)'scale_factor log_base: ',scale_factor,log_base
 
            WRITE(TEMPSTRING(1:),*)'0.0'
c	     write(tempstring(1:),*)nalign
            QUESTION='smoothing factor (number of alignments) ? /n'//
     +           ' 0.0 = no smoothing /n'//
     +           ' higher number ==>> smoothing'
            CALL GETCHAR(80,TEMPSTRING,QUESTION)
            CALL LOWTOUP(TEMPSTRING,80)
            CALL STRPOS(TEMPSTRING,IBEG,IEND)
            CALL READ_REAL_FROM_STRING(TEMPSTRING(IBEG:IEND),SIGMA)
 
            WRITE(TEMPSTRING(1:),*)'1.0'
c	     write(tempstring(1:),*)'0.5'
            QUESTION='smoothing factor (observed - not observed) ?/n'//
     +           ' 1.0 = no smoothing /n'//
     +           ' lower number ==>> smoothing'
            CALL GETCHAR(80,TEMPSTRING,QUESTION)
            CALL LOWTOUP(TEMPSTRING,80)
            CALL STRPOS(TEMPSTRING,IBEG,IEND)
            CALL READ_REAL_FROM_STRING(TEMPSTRING(IBEG:IEND),BETA)
 
            WRITE(*,*)'sigma beta: ',sigma,beta
	
            CALL CALC_PROFILE(MAXRES,MAXAA,MAXSTRSTATES,MAXIOSTATES,
     +           SCALE_FACTOR,LOG_BASE,SIGMA,BETA,
     +           NRES,NALIGN,
     +           EXCLUDEFLAG,IFIR,ILAS,
     +           ALISEQ,ALIPOINTER,NTRANS,TRANS,
     +           WEIGHTS,OPEN_GAP,ELONG_GAP,GAPOPEN,
     +           GAPELONG,SIMORG,PROFILEMETRIC)
         ELSE IF(KEYWORD .EQ. 'SCALE') THEN
            QUESTION=' give value for SMIN SMAX MAPLOW MAPHIGH'
            CALL GET_SCALING(SMIN,SMAX,MAPLOW,MAPHIGH,QUESTION)
            SUM=0.0
            DO I=1,NRES 
               DO J=1,20
                  SUM=SUM+PROFILEMETRIC(I,J)
	       ENDDO
            ENDDO
            WRITE(*,*)' sum over metric before: ',sum
            CALL SCALE_PROFILE_METRIC(MAXRES,NTRANS,TRANS,
     +           PROFILEMETRIC,SMIN,SMAX,MAPLOW,MAPHIGH)
            SUM=0.0
            DO I=1,NRES 
               DO J=1,20
                  SUM=SUM+PROFILEMETRIC(I,J)
	       ENDDO
            ENDDO
            WRITE(*,*)' sum over metric after: ',sum
         ELSE IF(KEYWORD .EQ. 'OPEN') THEN
            QUESTION=' give value and range for gap-open penalties'
            CALL GET_VALUE(GAPOPEN,QUESTION)
         ELSE IF(KEYWORD .EQ. 'ELONGATION') THEN
            QUESTION=' give value and range for gap-elongation '//
     +           'penalties'
            CALL GET_VALUE(GAPELONG,QUESTION)
         ELSE IF(KEYWORD .EQ. 'WEIGHTS') THEN
            QUESTION=' GIVE VALUE AND RANGE FOR WEIGHTS'
            CALL GET_VALUE(CONSWEIGHT,QUESTION)
         ELSE IF(KEYWORD .EQ. 'SHOW') THEN
            CALL SHOW_PROFILE(MAXRES,NRES,PDBSEQ,SECSTRUC,
     +           GAPOPEN,GAPELONG,CONSWEIGHT,
     +           PROFILEMETRIC)
         ENDIF
      ENDDO
C=======================================================================
C=======================================================================
      DO I=PROFILEBOX(1,1)-1,1,-1
         DO J=1,NTRANS
            PROFILEMETRIC(I,J)=0.0
         ENDDO
         GAPOPEN(I)=0.0 
         GAPELONG(I)=0.0 
         CONSWEIGHT(I)=1.0
         NOCC(I)=0
      ENDDO
      DO IBOX=1,NBOX-1
         DO I=PROFILEBOX(IBOX,2)+1,PROFILEBOX(IBOX+1,1)-1
            DO J=1,NTRANS
               PROFILEMETRIC(I,J)=0.0
            ENDDO
            GAPOPEN(I)=0.0 
            GAPELONG(I)=0.0 
            CONSWEIGHT(I)=1.0
            NOCC(I)=0
         ENDDO
         I=PROFILEBOX(IBOX,2)
         GAPOPEN(I)=0.0 
         GAPELONG(I)=0.0
      ENDDO
      DO I=PROFILEBOX(NBOX,2)+1,NRES
         DO J=1,NTRANS
            PROFILEMETRIC(I,J)=0.0
         ENDDO
         GAPOPEN(I)=0.0 
         GAPELONG(I)=0.0 
         CONSWEIGHT(I)=1.0
         NOCC(I)=0
      ENDDO
C=======================================================================
 
      WRITE(*,*)' call writeprofile'
      CALL WRITEPROFILE(KOUT,PROFILEOUT,MAXRES,NRES,
     +     NCHAIN,HSSPID,HEADER,COMPOUND,SOURCE,AUTHOR,
     +     SMIN,SMAX,MAPLOW,MAPHIGH,METRICFILE,
     +     PDBNO,CHAINID,PDBSEQ,SECSTRUC,NACC,
     +     COLS,SHEETLABEL,BP1,BP2,NOCC,
     +     GAPOPEN,GAPELONG,CONSWEIGHT,PROFILEMETRIC,
     +     MAXBOX,NBOX,PROFILEBOX,LDSSP)
 
      KEYWORD='NO'
      QUESTION=' write profile in a different format ? (YES or NO)'
      CALL GETCHAR(80,KEYWORD,QUESTION)
      CALL LOWTOUP(KEYWORD,80)
      IF(INDEX(KEYWORD,'YES') .NE. 0) THEN
         CALL STRPOS(HSSPID,IBEG,IEND)
         QUESTION=' which format ? (Xprism3 or SCian or AVS)'
         KEYWORD='XPRISM3'
         CALL GETCHAR(80,KEYWORD,QUESTION)
         CALL LOWTOUP(KEYWORD,80)
         IF(INDEX(KEYWORD,'X') .NE. 0) THEN
	    PROFILEOUT=HSSPID(IBEG:IEND)//'.xprism3'
	    CALL OPEN_FILE(KOUT,PROFILEOUT,'NEW,RECL=300',LERROR)
	    DO I=1,NRES
	       WRITE(KOUT,'(20(F8.3))')(PROFILEMETRIC(I,J),J=1,MAXAA)
	    ENDDO
            CLOSE(KOUT)
         ELSE IF(INDEX(KEYWORD,'SC') .NE. 0) THEN
	    PROFILEOUT=HSSPID(IBEG:IEND)//'.stf'
	    CALL OPEN_FILE(KOUT,PROFILEOUT,'NEW,RECL=300',LERROR)
	    WRITE(KOUT,*)'NAME FIELD'
	    WRITE(KOUT,*)'RANK 2'
	    WRITE(KOUT,*)'DIMENSIONS ',NRES,' ',MAXAA
	    WRITE(KOUT,*)'BOUNDS ',1,NRES,1,MAXAA
	    WRITE(KOUT,*)'SCALAR'
	    WRITE(KOUT,*)'ORDER ROW'
	    WRITE(KOUT,*)'DATA'
	    DO I=1,NRES
	       WRITE(KOUT,'(20(F8.3))')(PROFILEMETRIC(I,J),J=1,MAXAA)
	    ENDDO
            CLOSE(KOUT)
         ELSE IF(INDEX(KEYWORD,'AVS') .NE. 0) THEN
	    PROFILEOUT=HSSPID(IBEG:IEND)//'.avs'
	    CALL OPEN_FILE(KOUT,PROFILEOUT,'NEW,RECL=300',LERROR)
 
	    write(kout,*)'# AVS field file ; use READ FIELD'
	    write(kout,*)'# the ASCII data are at the end of this file'
	    write(kout,*)'ndim = 2'
	    write(kout,*)'dim1 =',maxaa
	    write(kout,*)'dim2 =',nres
	    write(kout,*)'nspace = 3'
	    write(kout,*)'veclen = 1'
	    write(kout,*)'data = float'
	    write(kout,*)'field = uniform'
	    CALL STRPOS(PROFILEOUT,IBEG,IEND)
	    write(kout,*)'variable 1 file=',profileout(ibeg:iend),
     +                   ' filetype=ascii skip=11'
	    WRITE(kout,*)'^L^L'
	    DO I=1,NRES
	       WRITE(KOUT,'(20(F8.3))')(PROFILEMETRIC(I,J),J=1,MAXAA)
	    ENDDO
         ELSE
            WRITE(*,*)' format not known !!'
         ENDIF
      ENDIF
 
      END
C     END of main MAKE_PROFILE
C......................................................................
 
C.......................................................................
C     SUB ADD_SEQ_TO_ALISEQ
      SUBROUTINE ADD_SEQ_TO_ALISEQ(MAXALIGNS,MAXCORE,ADDPOS,NALIGN,
     1     NEWSEQ,NEWSEQSTART,NEWSEQSTOP,NEWSEQNAME,ALISEQ,
     2     ALIPOINTER,IFIR,ILAS,JFIR,JLAS,LALI,NGAP,LGAP,
     3     LENSEQ,STRID,IDE,SIM,EXCLUDEFLAG,ACCNUM,EMBLID,
     4     PROTNAME)
 
      IMPLICIT NONE
C IMPORT
      INTEGER MAXALIGNS, MAXCORE,ADDPOS, NEWSEQSTART,NEWSEQSTOP
      CHARACTER NEWSEQ(*), NEWSEQNAME*(*)
C IMPORT / EXPORT
      INTEGER NALIGN
      INTEGER ALIPOINTER(MAXALIGNS)
      CHARACTER ALISEQ(MAXCORE)
C  ATTRIBUTES OF ALIGNEND SEQUENCES
      INTEGER IFIR(MAXALIGNS), ILAS(MAXALIGNS)
      INTEGER JFIR(MAXALIGNS),JLAS(MAXALIGNS)
      INTEGER LALI(MAXALIGNS),NGAP(MAXALIGNS)
      INTEGER LGAP(MAXALIGNS),LENSEQ(MAXALIGNS)
      CHARACTER*(*) STRID(MAXALIGNS)
      CHARACTER*(*) ACCNUM(MAXALIGNS)
      CHARACTER*(*) EMBLID(MAXALIGNS)
      CHARACTER*(*) PROTNAME(MAXALIGNS)
      CHARACTER EXCLUDEFLAG(MAXALIGNS)
      REAL IDE(MAXALIGNS),SIM(MAXALIGNS)
C EXPORT
C INTERNAL
      INTEGER IALIGN, IPOS, LEN
      INTEGER NEWSEQLEN
 
      NEWSEQLEN = NEWSEQSTOP-NEWSEQSTART+1
      IF ( ADDPOS .GT. NALIGN+1 ) THEN
         WRITE(*,'(a,i4)') ' cannot add after position ', nalign+1
         RETURN
 
      ELSE IF ( ADDPOS .EQ. NALIGN+1 ) THEN
 
         ALIPOINTER(ADDPOS) =
     1        ALIPOINTER(NALIGN)+ILAS(NALIGN)-IFIR(NALIGN)+1
         
      ELSE IF ( ADDPOS .LE. NALIGN ) THEN
         
         DO IPOS = ALIPOINTER(NALIGN)+ILAS(NALIGN)-IFIR(NALIGN)+1,
     1        ALIPOINTER(ADDPOS),-1
            IF ( IPOS+NEWSEQLEN+1 .LE. MAXCORE ) THEN
C shift by newseqlen+1, because a '/' is to be inserted after newseq
               ALISEQ(IPOS+NEWSEQLEN+1 ) = ALISEQ(IPOS)
            ELSE
               STOP 'MAXCORE overflow in add_seq_to_aliseq !'
            ENDIF
         ENDDO
C insert new member into arrays ifir .. at position addpos
C  and push following members by one
         DO IALIGN = NALIGN,ADDPOS,-1
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
C addpos............last res, '/'
C                            = +1
      LEN = NEWSEQSTART
      DO IPOS = ALIPOINTER(ADDPOS),ALIPOINTER(ADDPOS)+NEWSEQLEN-1
         ALISEQ(IPOS) = NEWSEQ(LEN)
         LEN = LEN + 1
      ENDDO
      ALISEQ(IPOS) = '/'
      IFIR(ADDPOS)=1
      ILAS(ADDPOS)=NEWSEQLEN
      JFIR(ADDPOS)=1
      JLAS(ADDPOS)=NEWSEQLEN
      LALI(ADDPOS)=NEWSEQLEN
      NGAP(ADDPOS)=0
      LGAP(ADDPOS)=0
      LENSEQ(ADDPOS)=NEWSEQLEN
      STRID(ADDPOS )= ' '
      ACCNUM(ADDPOS) = ' '
      EMBLID(ADDPOS)= NEWSEQNAME
      PROTNAME(ADDPOS)= ' '
      EXCLUDEFLAG(ADDPOS)= ' '
      IDE(ADDPOS)=0.0
      SIM(ADDPOS)=0.0
      
      NALIGN = NALIGN + 1
      
      RETURN
      END
C     end ADD_SEQ_TO_ALISEQ
C...................................................................... 

C......................................................................
C     SUB CALC_PROFILE
      SUBROUTINE CALC_PROFILE(MAXRES,MAXAA,MAXSTRSTATES,MAXIOSTATES,
     +     SCALE_FACTOR,LOG_BASE,SIGMA,BETA,
     +     NRES,NALIGN,
     +     EXCLUDEFLAG,IFIR,ILAS,
     +     ALISEQ,ALIPOINTER,NTRANS,TRANS,
     +     SEQ_WEIGHT,OPEN_GAP,ELONG_GAP,GAPOPEN,
     +     GAPELONG,SIMORG,PROFILEMETRIC)
      
      INTEGER NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,NIOSTATES_2
      COMMON/STRSTATES/ NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,
     +     NIOSTATES_2
C import
      INTEGER MAXRES,MAXAA,NRES,NALIGN,NTRANS
      REAL SCALE_FACTOR,LOG_BASE
      REAL SIGMA,BETA
      INTEGER IFIR(*),ILAS(*),ALIPOINTER(*)
      CHARACTER ALISEQ(*)
      CHARACTER TRANS*(*),EXCLUDEFLAG(*)
      REAL SEQ_WEIGHT(*),OPEN_GAP,ELONG_GAP,GAPOPEN(*),GAPELONG(*)
      REAL SIMORG(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +     MAXSTRSTATES,MAXIOSTATES)
C EXPORT
      REAL PROFILEMETRIC(MAXRES,NTRANS)
C INTERNAL
      INTEGER MAXTRANS
      PARAMETER (MAXTRANS=26)
      INTEGER IRES,IALIGN,I,J
      REAL FREQUENCY(MAXTRANS)
      REAL BTOD,BTON,ZTOE,ZTOQ
      REAL XOCC,XINS,XDEL
      CHARACTER C1
      
      REAL SIM_COPY(MAXTRANS,MAXTRANS)
      REAL INV(MAXTRANS,MAXTRANS)
      INTEGER INDX(MAXTRANS)
      REAL PROB_I(MAXTRANS)
      
C================
CAUTION: pass the following values from outside
CAUTION only for BLOSUM
c	scale_factor = 0.5
c	log_base = 2.0
 
c	scale_factor = 1.0
c	log_base = 10.0
 
c	beta=1.0 ; sigma=1.0
 
C 'B' and 'Z' are assigned as well to the acid as to the amide form
C with respect to their frequency in EMBL/SWISSPROT 21.0
      BtoD=0.524
      BtoN=0.445
      ZtoE=0.626
      ZtoQ=0.407
      ILEN=LEN(TRANS)
 
      WRITE(*,*)'calc_profile'
 
C check if MAXHOM tries do more than we implemented here :-)
      IF(NTRANS .GT. MAXTRANS) THEN
         WRITE(*,*)' WARNING: NTRANS GT MAXTRANS'
         WRITE(*,*)' update routine: calc_profile !!!'
         STOP
      ENDIF
      IF(NSTRSTATES_1 .GT. 1 .OR. NIOSTATES_1 .GT. 1 .OR.
     +     NSTRSTATES_2 .GT. 1 .OR. NIOSTATES_2 .GT. 1) THEN
         WRITE(*,*)' WARNING: routine calc_profile not'
         WRITE(*,*)' working with STR and/or I/O dependent'
         WRITE(*,*)' metrices, update routine !!!'
         STOP
      ENDIF
C copy "simorg" in "sim_copy" so "simorg" will be unchanged !
      DO I=1,NTRANS 
         DO J=1,NTRANS
            SIM_COPY(I,J)= SIMORG(I,J,1,1,1,1)
         ENDDO 
      ENDDO
C     scale metric if necessary
      DO I=1,MAXTRANS 
         DO J=1,MAXTRANS
            SIM_COPY(I,J)=SIM_COPY(I,J) * SCALE_FACTOR
         ENDDO 
      ENDDO
C de-log the matrix to get the ( P(i,j) / ( P(i) * P(j) ) )
      DO I=1,MAXTRANS 
         DO J=1,MAXTRANS
            SIM_COPY(I,J)= LOG_BASE ** SIM_COPY(I,J)
         ENDDO 
      ENDDO
C build diagonal matrix
      DO I=1,NTRANS
         DO J=1,NTRANS 
            INV(I,J)=0.0 
         ENDDO
         INV(I,I) =1.0
      ENDDO
C invert matrix
C NOTE: sim_copy gets changed
      CALL LUDCMP(SIM_COPY,MAXAA,MAXTRANS,INDX,D)
      DO I=1,MAXAA
         CALL LUBKSB(SIM_COPY,MAXAA,MAXTRANS,INDX,INV(1,I))
      ENDDO
C normalize to 1.0 to get the P(i)
      DO I=1,MAXAA
         SUM=0.0
         DO J=1,MAXAA 
            SUM= SUM + INV(I,J) 
         ENDDO
         PROB_I(I)=SUM
         DO J=1,MAXAA 
            INV(I,J)=INV(I,J) /SUM 
         ENDDO
C check
         SUM=0.0
         DO J=1,MAXAA 
            SUM= SUM + INV(I,J) 
         ENDDO
         CALL CHECKREALEQUALITY(SUM,1.0,0.002,'SUM','CALC_PROFILE')
      ENDDO
C restore sim_copy (changed by matrix inverse)
      DO I=1,MAXTRANS 
         DO J=1,MAXTRANS
            SIM_COPY(I,J)= SIMORG(I,J,1,1,1,1)
         ENDDO 
      ENDDO
C scale metric
      DO I=1,MAXTRANS 
         DO J=1,MAXTRANS
            SIM_COPY(I,J)=SIM_COPY(I,J) * SCALE_FACTOR
         ENDDO 
      ENDDO
C de-log the matrix and multiply by P(i) to get the conditional probabilities:
C  ( P(i,j) | P(j) )
      DO I=1,MAXTRANS 
         DO J=1,MAXTRANS
            SIM_COPY(I,J)= ( LOG_BASE ** SIM_COPY(I,J) ) * PROB_I(I)
         ENDDO 
      ENDDO
C check sum rule
      DO J=1,MAXAA
         SIM=0.0
         DO I=1,MAXAA
            SIM = SIM + SIM_COPY(I,J)
         ENDDO
         WRITE(*,*)'sum P(i,j) | P(j): ',j,sim
         CALL CHECKREALEQUALITY(SIM,1.0,0.002,'sim','calc_profile')
      ENDDO
C calculate sequence profile
      DO IRES=1,NRES
         XOCC=0.0 
         XINS=0.0 
         XDEL=0.0
         DO I=1,MAXTRANS 
            FREQUENCY(I)=0.0 
         ENDDO
         DO IALIGN=1,NALIGN
            IF(IRES .GE. IFIR(IALIGN) .AND. IRES .LE. ILAS(IALIGN)
     +           .AND. EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
               C1=ALISEQ( ALIPOINTER(IALIGN)+IRES-IFIR(IALIGN) )
C if lower case character: insertions
               IF(C1 .GE. 'a' .AND. C1 .LE. 'z') THEN
                  C1=CHAR( ICHAR(C1)-32 )
                  XINS=XINS + SEQ_WEIGHT(IALIGN)
               ENDIF
               IF(C1 .NE. '.') THEN
	          XOCC=XOCC + SEQ_WEIGHT(IALIGN)
                  IF(INDEX('BZ',C1).EQ.0) THEN
                     I=INDEX(TRANS,C1)
                     IF(I .LE. 0 .OR. I .GT. ILEN) THEN
                        WRITE(*,*)' GETFREQUENCY: unknown res : ',c1
                     ELSE
                        FREQUENCY(I)=FREQUENCY(I) + SEQ_WEIGHT(IALIGN)
                     ENDIF
	          ELSE IF(C1 .EQ. 'B') THEN
                     WRITE(*,*)' GETFREQUENCY: convert B'
                     I=INDEX(TRANS,'D')
                     J=INDEX(TRANS,'N')
                     FREQUENCY(I)=FREQUENCY(I)+(BTOD*SEQ_WEIGHT(IALIGN))
                     FREQUENCY(J)=FREQUENCY(J)+(BTON*SEQ_WEIGHT(IALIGN))
                  ELSE IF(C1 .EQ. 'Z') THEN
                     WRITE(*,*)' GETFREQUENCY: convert Z'
                     I=INDEX(TRANS,'E')
                     J=INDEX(TRANS,'Q')
                     FREQUENCY(I)=FREQUENCY(I)+(ZTOE*SEQ_WEIGHT(IALIGN))
                     FREQUENCY(J)=FREQUENCY(J)+(ZTOQ*SEQ_WEIGHT(IALIGN))
	          ENDIF
               ELSE
C if '.' : deletion
		  XDEL=XDEL+ SEQ_WEIGHT(IALIGN)
               ENDIF
            ENDIF
         ENDDO	
C======================
C profile
         SUM= 0.0
         DO I=1,MAXAA 
            SUM = SUM + FREQUENCY(I) 
         ENDDO
         IF (SUM .NE. 0.0) THEN
            DO I=1,MAXAA 
               FREQUENCY(I)= FREQUENCY(I) / SUM 
            ENDDO
C check sum rule for frequencies
            X=0.0 
            DO I=1,MAXAA 
               X = X + FREQUENCY(I) 
            ENDDO
            CALL CHECKREALEQUALITY(X,1.0,0.002,'freq','calc_profile')
C smooth the profile
C sigma: smooth dependent on the number of alignments
C beta:  mixing of the two models (expected <--> observed)
            SMOOTH= ( SUM / (SUM +SIGMA)) * BETA
C do for each of the AA types in a row
            DO I=1,MAXAA
 
               SIM=0.0
C sum up the conditional probabilities
               DO J=1,MAXAA
                  SIM = SIM + ( FREQUENCY(J) * SIM_COPY(I,J) )
               ENDDO
C add the observed frequencies and smooth
               PROFILEMETRIC(IRES,I)=( (1-SMOOTH) * SIM) +
     +              (SMOOTH * FREQUENCY(I) )
C divide by the expected probability
               PROFILEMETRIC(IRES,I)=PROFILEMETRIC(IRES,I)/PROB_I(I)
c	        profilemetric(ires,i)= frequency(i) /prob_i(i)
C log-odd
               IF (PROFILEMETRIC(IRES,I) .LE. 10E-3) THEN
                  PROFILEMETRIC(IRES,I)=10E-3
               ENDIF
               PROFILEMETRIC(IRES,I)=LOG10 ( PROFILEMETRIC(IRES,I) )
 
c	        write(*,*)ires,trans(i:i),sum,frequency(i),
c     +                    sim,smooth,profilemetric(ires,i)
C gap-weights
               GAPOPEN(IRES) =OPEN_GAP  / (1.0 + ((XINS+XDEL)/SUM) )
               GAPELONG(IRES)=ELONG_GAP / (1.0 + ((XINS+XDEL)/SUM) )
            ENDDO
         ELSE
            WRITE(*,*)'CALC_PROFILE: position not occupied !'
            C1=ALISEQ( ALIPOINTER(1)+IRES-IFIR(1) )
            WRITE(*,*)'  sequence symbol of first sequence: ',c1
            WRITE(*,*)'  set profile row to 0.0'
            DO I=1,MAXAA 
               PROFILEMETRIC(IRES,I)=0.0 
            ENDDO
            GAPOPEN(IRES) = 0.0 
            GAPELONG(IRES)= 0.0
         ENDIF
      ENDDO
C set value for chain breaks etc... to 0.0
C later there are refilled in MAXHOM (like "!" = -200.0)
      IX=INDEX(TRANS,'X')
      IB=INDEX(TRANS,'B')
      IZ=INDEX(TRANS,'Z')
      I1=INDEX(TRANS,'!')
      I2=INDEX(TRANS,'-')
      DO IRES=1,NRES
         PROFILEMETRIC(IRES,IX)=0.0
         PROFILEMETRIC(IRES,IB)=0.0
         PROFILEMETRIC(IRES,IZ)=0.0
         PROFILEMETRIC(IRES,I1)=0.0
         PROFILEMETRIC(IRES,I2)=0.0
      ENDDO
 
      RETURN
      END
C     END CALC_PROFILE
C...................................................................... 

C......................................................................
C     SUB GET_BOX
      SUBROUTINE GET_BOX(MAXBOX,NBOX,PROFILEBOX,NRES)
      
      IMPLICIT NONE
      INTEGER MAXBOX,NBOX,PROFILEBOX(MAXBOX,2),NRES
C internal
      INTEGER I,IBEG,IEND
 
      NBOX=1
      DO I=1,MAXBOX
         PROFILEBOX(I,1)=0 
         PROFILEBOX(I,2)=0
      ENDDO
      PROFILEBOX(1,1)=1 
      PROFILEBOX(1,2)=NRES
      WRITE(*,*)'================================================'
      WRITE(*,*)' Give range for profile boxes'
      WRITE(*,*)' enter 2 integers for begin and end of box'
      WRITE(*,*)' or 0 to stop definition of boxes'
      WRITE(*,*)' '
      IBEG=1
      DO WHILE(IBEG .NE.0)
         IBEG=0 
         IEND=0
         CALL GETINTRANGE(IBEG,IEND)
         IF(IBEG.NE.0) THEN
            IF(IBEG .GE. 1 .AND. IEND .LE. NRES) THEN
	       PROFILEBOX(NBOX,1)=IBEG
	       PROFILEBOX(NBOX,2)=IEND
	       NBOX=NBOX+1
            ELSE
	       WRITE(*,*)' invalid input: ',IBEG,IEND
            ENDIF
         ENDIF
      ENDDO
      NBOX=NBOX-1
CPLAN CHECK CONSISTENCY OF BOXES: NO OVERLAP ETC....
      RETURN
      END
C     END GET_BOX
C......................................................................
 
C......................................................................
C     SUB GET_DEFAULT
      SUBROUTINE GET_DEFAULT(KDEF,DEFAULT_FILE,CMACHINE,METRIC_PATH,
     +     METRICFILE,SMIN,SMAX,MAPLOW,MAPHIGH,
     +     OPEN_GAP,ELONG_GAP,WEIGHT_MODE)
C get the system specific location of files
C like:
C VMS : assign $1:[schneider.public]profile_make.default
C UNIX: setenv default_file /home/schneider/public/profile_make.default
C a file "profile_make.default" in the current directory has higher priority
C import
      INTEGER       KDEF
      CHARACTER*(*) DEFAULT_FILE
c export
C METRIC_PATH    : location of exchange metrices
      CHARACTER*(*) METRIC_PATH,CMACHINE,METRICFILE,WEIGHT_MODE
      REAL          SMIN,SMAX,MAPLOW,MAPHIGH,OPEN_GAP,ELONG_GAP
c internal
      LOGICAL       LEXIST,LERROR
      CHARACTER*80  DEFAULT_LOCAL,LINE
      CHARACTER     CDIVIDE
 
      DEFAULT_LOCAL='profile_make.default'
      metric_path=' '
      cdivide=':'
 
      INQUIRE(FILE=DEFAULT_LOCAL,EXIST=LEXIST)
      IF(LEXIST) THEN
	 WRITE(*,*)' found local default file !'
	 CALL OPEN_FILE(KDEF,DEFAULT_LOCAL,'OLD,READONLY',LERROR)
      ELSE
         WRITE(*,*)' could not find local default file try home!'
         INQUIRE(FILE=DEFAULT_FILE,EXIST=LEXIST)
         IF(LEXIST) THEN
	    CALL STRPOS(DEFAULT_FILE,IBEG,IEND)
	    WRITE(*,*)' default file is: ',default_file(ibeg:iend)
	    CALL OPEN_FILE(KDEF,DEFAULT_FILE,'OLD,READONLY',LERROR)
         ELSE
            WRITE(*,*)' ERROR: cant find default file: '
	    WRITE(*,*)DEFAULT_FILE
	    STOP
         ENDIF
      ENDIF
      
      DO WHILE(.TRUE.)
         READ(KDEF,'(A)',END=999)LINE
         IF(LINE(1:1) .NE. '#' .AND. LINE .NE.' ') THEN
            CALL EXTRACT_STRING(LINE,CDIVIDE,'MACHINE',CMACHINE)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'METRIC_PATH',METRIC_PATH)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'METRIC',METRICFILE)
            CALL EXTRACT_STRING(LINE,CDIVIDE,'WEIGHTING',WEIGHT_MODE)
            CALL EXTRACT_REAL(LINE,CDIVIDE,'SMIN',SMIN)
            CALL EXTRACT_REAL(LINE,CDIVIDE,'SMAX',SMAX)
            CALL EXTRACT_REAL(LINE,CDIVIDE,'MAPLOW',MAPLOW)
            CALL EXTRACT_REAL(LINE,CDIVIDE,'MAPHIGH',MAPHIGH)
            CALL EXTRACT_REAL(LINE,CDIVIDE,'OPEN_GAP',OPEN_GAP)
            CALL EXTRACT_REAL(LINE,CDIVIDE,'ELONG_GAP',ELONG_GAP)
	 ENDIF
      ENDDO
 999  CLOSE(KDEF)
      IF(INDEX(CMACHINE,'UNIX').NE.0) THEN
         CMACHINE='UNIX'
      ELSE IF(INDEX(CMACHINE,'VMS').NE.0) THEN   		
         CMACHINE='VMS'
      ELSE
         WRITE(*,*)' *** machine type unknown (assume UNIX) ***'
         CMACHINE='UNIX'
      ENDIF
      IF(METRIC_PATH .EQ. ' ') THEN
         WRITE(*,*)' ERROR: METRIC_PATH undefined'
         WRITE(*,*)' PLEASE CHECK DEFAULT FILE !!!'
         STOP
      ENDIF
      RETURN
      END
C     END GET_DEFAULT
C...................................................................... 

C......................................................................
C     SUB GET_METRIC
      SUBROUTINE GET_METRIC(MAXRES,NTRANS,TRANS,MAXSTRSTATES,
     +     MAXIOSTATES,NSTRSTATES_1,NIOSTATES_1,
     +     NSTRSTATES_2,NIOSTATES_2,CSTRSTATES,
     +     CIOSTATES,IORANGE,KSIM,METRICPATH,CMACHINE,LPROFILE,
     +     LDSSP,LHSSP,LPROPERTY,
     +     SMIN,SMAX,MAPLOW,MAPHIGH,SIMORG,
     +     MAXBOX,NBOX,PROFILEBOX,NALIGN,ALILINE,
     +     NRES,PDBSEQ,SECSTRUC,LSECSTRUC,STR_CLASSES,STRCLASS,
     +     NACC,LACC,LSEQ,PROFILEMETRIC,
     +     GAPOPEN,GAPELONG,METRICFILE)
 
      IMPLICIT NONE
      CHARACTER TRANS*(*),METRICPATH*(*)
      INTEGER MAXRES,NTRANS,MAXSTRSTATES,MAXIOSTATES
      INTEGER MAXBOX,NBOX,PROFILEBOX(MAXBOX,*),NALIGN
      INTEGER NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,NIOSTATES_2
      CHARACTER STR_CLASSES(*)*(*)
      CHARACTER CSTRSTATES*(*),CIOSTATES*(*)
      CHARACTER ALILINE(*)*(*)
      
      INTEGER NRES
      CHARACTER PDBSEQ(*),SECSTRUC(*),STRCLASS*(*)
      INTEGER LSECSTRUC(*)
      INTEGER NACC(*),LACC(*),LSEQ(*)
      REAL IORANGE(MAXSTRSTATES,MAXIOSTATES)
      LOGICAL LPROFILE,LDSSP,LHSSP,LPROPERTY
      CHARACTER CMACHINE*(*)
      INTEGER KSIM
      REAL SMIN,SMAX,MAPLOW,MAPHIGH
c output
      REAL PROFILEMETRIC(MAXRES,NTRANS)
      REAL GAPOPEN(MAXRES),GAPELONG(MAXRES)
      CHARACTER*(*) METRICFILE
c internal
      REAL SIMORG(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +     MAXSTRSTATES,MAXIOSTATES)
      CHARACTER QUESTION*500
      CHARACTER*80 METRIC_ANSWER
C	CHARACTER*80 SMIN_ANSWER,SMAX_ANSWER,MAPLOW_ANSWER,
C     +               MAPHIGH_ANSWER
      CHARACTER*80 METRIC_ADM,
     +     METRIC_GCG,METRIC_STRUC,METRIC_IO,METRIC_STRIO,
     +     METRIC_BLOSUM
      INTEGER IBEG,IEND
c=====================================================================
 
c similarity matrix
      CALL STRPOS(METRICPATH,IBEG,IEND)
      metric_adm=metricpath(:iend)//'Maxhom_McLachlan.metric'
      metric_gcg=metricpath(:iend)//'Maxhom_GCG.metric'
      metric_blosum=metricpath(:iend)//'Maxhom_Blosum.metric'
      metric_struc=metricpath(:iend)//'????'
      metric_io=metricpath(:iend)//'?????'
      metric_strio=metricpath(:iend)//'Maxhom_Struc_IO.metric'
      
      METRIC_ANSWER='LACHLAN'
      IF (LPROFILE) THEN
         metric_answer='PROFILE'
         QUESTION=' exchange metric ? /n'//
     +	  'LACHLAN    : Andrew McLachlan /n'//
     +	  'GCG        : Dayhoff used by GCG /n'//
     +	  'BLOSUM     : Blosum 62 /n'//
     +    'STRUC      : secondary structure dependent /n'//
     +    'IO         : inside/outside dependent /n'//
     +    'STRUC_IO   : secondary structure and I/O dependent /n'//
     +    '"filename" : import any metric in Maxhom format '//
     +                 '(full pathname required !) /n'//
     +    'PROFILE    : use metric from profile /n'//
     +    '**** OTHER OPTIONS DISABLED (NEED ALIGNMENTS) ****'
      ELSE IF(LHSSP) THEN
         QUESTION=' exchange metric ? /n'//
     +	  'LACHLAN    : Andrew McLachlan /n'//
     +	  'GCG        : Dayhoff used by GCG /n'//
     +	  'BLOSUM     : Blosum 62 /n'//
     +    'STRUC      : secondary structure dependent /n'//
     +    'IO         : inside/outside dependent /n'//
     +    'STRUC_IO   : secondary structure and I/O dependent /n'//
     +    '"filename" : import any metric in Maxhom format '//
     +                 '(full pathname required !) /n'//
     +    'PROPERTY   : use physico-chemical properties /n'//
     +    '**** OTHER OPTIONS DISABLED (NEED PROFILE) ****'
      ELSE IF(LDSSP) THEN
         QUESTION=' exchange metric ? /n'//
     +	  'LACHLAN    : Andrew McLachlan /n'//
     +	  'GCG        : Dayhoff used by GCG /n'//
     +	  'BLOSUM     : Blosum 62 /n'//
     +    'STRUC      : secondary structure dependent /n'//
     +    'IO         : inside/outside dependent /n'//
     +    'STRUC_IO   : secondary structure and I/O dependent /n'//
     +    '"filename" : import any metric in Maxhom format '//
     +                 '(full pathname required !) /n'//
     +    'PROPERTY   : use physico-chemical properties /n'//
     +    '**** OTHER OPTIONS DISABLED (NEED PROFILE) ****'
      ELSE
         QUESTION=' exchange metric ? /n'//
     +	  'LACHLAN    : Andrew McLachlan /n'//
     +	  'GCG        : Dayhoff used by GCG /n'//
     +	  'BLOSUM     : Blosum 62 /n'//
     +    '"filename" : import any metric in Maxhom format '//
     +                 '(full pathname required !) /n'//
     +    'PROPERTY   : use physico-chemical properties /n'//
     +    '**** OTHER OPTIONS DISABLED (NEED PROFILE OR DSSP FILE) ****'
      ENDIF
      CALL GETCHAR(80,METRIC_ANSWER,QUESTION)
      IF(INDEX(METRIC_ANSWER,'/').NE.0 .AND. CMACHINE.EQ.'UNIX') THEN
         METRICFILE=METRIC_ANSWER
      ELSE IF(INDEX(METRIC_ANSWER,'$') .NE.0 .OR.
     +        INDEX(METRIC_ANSWER,']') .NE.0 .AND.
     +        CMACHINE.EQ.'VMS' ) THEN
         METRICFILE=METRIC_ANSWER
      ELSE
         CALL LOWTOUP(METRIC_ANSWER,80)
         IF(INDEX(METRIC_ANSWER,'PROF').NE.0) THEN
            IF(LPROFILE) THEN
               METRICFILE='PROFILE'
            ELSE
               WRITE(*,'(a)')'*** ERROR: no PROFILE to get metric'
               STOP
            ENDIF
	 ELSE IF(INDEX(METRIC_ANSWER,'PROP') .NE. 0) THEN
	    LPROPERTY=.TRUE.
	    METRICFILE='PROPERTY'
	    CALL GET_PROPERTY_PROFILE(MAXRES,MAXBOX,NBOX,PROFILEBOX,
     +           NTRANS,TRANS,NALIGN,NRES,ALILINE,PROFILEMETRIC,
     +           GAPOPEN,GAPELONG,SMIN,SMAX,MAPLOW,MAPHIGH)
	 ELSE
            IF(INDEX(METRIC_ANSWER,'LACH').NE.0) THEN
               METRICFILE=METRIC_ADM
            ELSE IF(INDEX(METRIC_ANSWER,'GCG').NE.0) THEN
               METRICFILE=METRIC_GCG
            ELSE IF(INDEX(METRIC_ANSWER,'BLO').NE.0) THEN
               METRICFILE=METRIC_BLOSUM
            ELSE IF(INDEX(METRIC_ANSWER,'STRUC_IO').NE.0) THEN
               METRICFILE=METRIC_STRIO
            ELSE IF(INDEX(METRIC_ANSWER,'STRUC').NE.0) THEN
               METRICFILE=METRIC_STRUC
            ELSE IF(INDEX(METRIC_ANSWER,'IO').NE.0) THEN
               METRICFILE=METRIC_IO
            ENDIF
            IF(LPROFILE) THEN
               WRITE(*,*)'**** WARNING: will overwrite PROFILE-metric'
            ENDIF
	 ENDIF
      ENDIF
C=======================================================================
 
      IF(LPROFILE) THEN
         RETURN
      ELSE IF(LPROPERTY) THEN
         RETURN
      ELSE
         CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +        NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,NIOSTATES_2,
     +        CSTRSTATES,CIOSTATES,IORANGE,
     +        KSIM,METRICFILE,SIMORG)
      ENDIF
      CALL SEQTOINT(PDBSEQ,LSEQ,NRES,TRANS,NTRANS)
 
      CALL STR_TO_CLASS(MAXSTRSTATES,STR_CLASSES,NRES,SECSTRUC,
     +     STRCLASS,LSECSTRUC)
      CALL ACC_TO_INT(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NIOSTATES_1,IORANGE,
     +     NRES,LSEQ,LSECSTRUC,NACC,LACC)
      IF(.NOT. LPROFILE) THEN
         CALL FILLSIMMETRIC(MAXRES,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +        NSTRSTATES_1,NSTRSTATES_2,CSTRSTATES,SIMORG,NRES,LSEQ,
     +        LSECSTRUC,LACC,PROFILEMETRIC)
      ENDIF
      RETURN
      END
C     END GET_METRIC
C......................................................................
 
C......................................................................
C     SUB GET_PROPERTY_PROFILE
      SUBROUTINE GET_PROPERTY_PROFILE(MAXRES,MAXBOX,NBOX,PROFILEBOX,
     +     NTRANS,TRANS,NALIGN,NRES,ALILINE,PROFILEMETRIC,
     +     GAPOPEN,GAPELONG,SMIN,SMAX,MAPLOW,MAPHIGH)
C======================================================================
C make profile metric from multiple seuence alignment using
C physico-chemical properties according to:
C Bork P., Grunwald C.
C Recongnition of different nucleotide-binding sites in primary
C structures using a property-pattern approach
C Eur.J.Biochem., 191,347-358 (1990)
C rules:
C======================================================================
      IMPLICIT NONE
      
      INTEGER MAXRES,MAXBOX,NBOX,NRES,NTRANS,NALIGN
      INTEGER PROFILEBOX(MAXBOX,1)
      CHARACTER TRANS*(*),ALILINE(*)*(*)
      
      INTEGER NPROPERTY
      PARAMETER (NPROPERTY=11)
      INTEGER PROPERTY(25,NPROPERTY)
      INTEGER POSPENALTY(2000,25)
C output
      REAL PROFILEMETRIC(MAXRES,NTRANS)
      REAL GAPOPEN(MAXRES),GAPELONG(MAXRES)
      REAL SMIN,SMAX,MAPLOW,MAPHIGH
C internal
      INTEGER MAXBOXRES
      PARAMETER (MAXBOXRES=1000)
      INTEGER I,J,IPOS,IRES,IBOX,IPROPERTY,ISUM(NPROPERTY),POSPROPERTY
      REAL SUM,MEAN,MAXVALUE,MINVALUE,OPENVAL,ELONGVAL
      REAL PUNISH
      LOGICAL LCONSERVED(MAXBOXRES),LGAP(MAXBOXRES)
      LOGICAL LKEEPCONSERV(MAXBOXRES)
      INTEGER NCONSERV
      CHARACTER POSSTRING*(2000)
      CHARACTER GAPSYMBOL
C in order of TRANS='VLIMFWYGAPSTCHRKQENDBZX!-'
C properties are:
C hydrophobic, positive charge, negative charge, polar,
C charge, aliphatic, small, tiny, aromatic, proline, glycine
C
      DATA (PROPERTY( 1,I),I=1,NPROPERTY) /1,0,0,0,0,1,0,1,0,0,0/
      DATA (PROPERTY( 2,I),I=1,NPROPERTY) /1,0,0,0,0,0,0,1,0,0,0/
      DATA (PROPERTY( 3,I),I=1,NPROPERTY) /1,0,0,0,0,0,0,1,0,0,0/
      DATA (PROPERTY( 4,I),I=1,NPROPERTY) /1,0,0,0,0,0,0,0,0,0,0/
      DATA (PROPERTY( 5,I),I=1,NPROPERTY) /1,0,0,0,0,0,0,0,1,0,0/
      DATA (PROPERTY( 6,I),I=1,NPROPERTY) /1,0,0,1,0,0,0,0,1,0,0/
      DATA (PROPERTY( 7,I),I=1,NPROPERTY) /1,0,0,1,0,0,0,0,1,0,0/
      DATA (PROPERTY( 8,I),I=1,NPROPERTY) /1,0,0,0,0,1,1,0,0,0,1/
      DATA (PROPERTY( 9,I),I=1,NPROPERTY) /1,0,0,0,0,1,1,0,0,0,0/
      DATA (PROPERTY(10,I),I=1,NPROPERTY) /0,0,0,0,0,1,0,0,0,1,0/
      DATA (PROPERTY(11,I),I=1,NPROPERTY) /0,0,0,1,0,1,1,0,0,0,0/
      DATA (PROPERTY(12,I),I=1,NPROPERTY) /1,0,0,1,0,1,0,0,0,0,0/
      DATA (PROPERTY(13,I),I=1,NPROPERTY) /1,0,0,0,0,1,0,0,0,0,0/
      DATA (PROPERTY(14,I),I=1,NPROPERTY) /1,1,0,1,1,0,0,0,1,0,0/
      DATA (PROPERTY(15,I),I=1,NPROPERTY) /0,1,0,1,1,0,0,0,0,0,0/
      DATA (PROPERTY(16,I),I=1,NPROPERTY) /1,1,0,1,1,0,0,0,0,0,0/
      DATA (PROPERTY(17,I),I=1,NPROPERTY) /0,0,0,1,0,0,0,0,0,0,0/
      DATA (PROPERTY(18,I),I=1,NPROPERTY) /0,0,1,1,1,0,0,0,0,0,0/
      DATA (PROPERTY(19,I),I=1,NPROPERTY) /0,0,0,1,0,1,0,0,0,0,0/
      DATA (PROPERTY(20,I),I=1,NPROPERTY) /0,0,1,1,1,1,0,0,0,0,0/
      DATA (PROPERTY(21,I),I=1,NPROPERTY) /0,0,0,1,0,0,0,0,0,0,0/
      DATA (PROPERTY(22,I),I=1,NPROPERTY) /0,0,0,1,0,0,0,0,0,0,0/
      DATA (PROPERTY(23,I),I=1,NPROPERTY) /1,1,1,1,1,1,1,1,1,1,1/
      DATA (PROPERTY(24,I),I=1,NPROPERTY) /1,1,1,1,1,1,1,1,1,1,1/
      DATA (PROPERTY(25,I),I=1,NPROPERTY) /1,1,1,1,1,1,1,1,1,1,1/
C init
      GAPSYMBOL='-'	
      PUNISH=200.0
      MAXVALUE=4.5 
      MINVALUE=-4.5 
      OPENVAL=2.0 
      ELONGVAL=3.0
      DO I=1,MAXBOXRES
         GAPOPEN(I)=0.0
         LCONSERVED(I)=.TRUE. 
         LGAP(I)=.FALSE.
         LKEEPCONSERV(I)=.FALSE.
      ENDDO
      DO I=1,MAXRES
         DO J=1,NTRANS
            POSPENALTY(I,J)=0
            PROFILEMETRIC(I,J)=0.0
         ENDDO
      ENDDO
C search for conserved position and gap positions
      NCONSERV=0
      WRITE(*,*)NBOX,PROFILEBOX(1,1),PROFILEBOX(1,2)
 
      DO IBOX=1,NBOX
         DO IPOS=PROFILEBOX(IBOX,1),PROFILEBOX(IBOX,2)
	    POSSTRING=' '
	    DO I=1,NALIGN+1
               POSSTRING(I:I)=ALILINE(I)(IPOS:IPOS)
	    ENDDO
C loop over residues at position IPOS
	    DO I=1,NALIGN+1
C is this a conserved position ?
               IF(I.NE.1) THEN
                  IF(POSSTRING(I-1:I-1) .NE. POSSTRING(I:I)) THEN
                     LCONSERVED(IPOS)=.FALSE.
                  ENDIF
               ENDIF
C are there somewhere gaps ?
               IF(POSSTRING(I:I) .EQ. GAPSYMBOL) THEN
                  LGAP(IPOS)=.TRUE.
               ENDIF
	    ENDDO
	    IF(LCONSERVED(IPOS)) THEN
	      NCONSERV=NCONSERV+1
           ENDIF
        ENDDO
      ENDDO
C
      IF(NCONSERV .NE. 0) THEN
         WRITE(*,*)'================================================'
         WRITE(*,*)' found the following conserved postions:'
         WRITE(*,*)' if you want to keep them explicitly conserved,'
         WRITE(*,*)' give the position number(s) or 0 to end'
         WRITE(*,*)
         DO IBOX=1,NBOX
            DO IPOS=PROFILEBOX(IBOX,1),PROFILEBOX(IBOX,2)
               IF(LCONSERVED(IPOS)) THEN
                  WRITE(*,'(A,I4,A,A)')
     +	               ' position: ',IPOS,' is: ',ALILINE(1)(IPOS:IPOS)
               ENDIF
            ENDDO
         ENDDO
         WRITE(*,*)
         IPOS=1
         DO WHILE(IPOS .NE.0)
            IPOS=0
            CALL GETINTVALUE(IPOS)
            IF(IPOS.NE.0) THEN
	       LKEEPCONSERV(IPOS)=.TRUE.
            ENDIF
         ENDDO
      ENDIF
C loop over boxes and residues in boxes
      DO IBOX=1,NBOX
         DO IPOS=PROFILEBOX(IBOX,1),PROFILEBOX(IBOX,2)
	    DO IPROPERTY=1,NPROPERTY
	       ISUM(IPROPERTY)=0
	    ENDDO
	    POSSTRING=' '
	    DO I=1,NALIGN+1
               POSSTRING(I:I)=ALILINE(I)(IPOS:IPOS)
	    ENDDO
C loop over residues at position IPOS
	    DO I=1,NALIGN+1
               IRES=INDEX(TRANS,POSSTRING(I:I))
               IF(IRES.EQ.0) THEN
                  WRITE(*,*)' UNKNOWN SYMBOL: ',POSSTRING(I:I)
                  GOTO 200
               ENDIF
C accumulate property sum
               DO IPROPERTY=1,NPROPERTY
                  ISUM(IPROPERTY)=ISUM(IPROPERTY)+
     +                 PROPERTY(IRES,IPROPERTY)
               ENDDO
 200        ENDDO
	    DO IPROPERTY=1,NPROPERTY
C all residues at that position show this property
               IF(ISUM(IPROPERTY) .EQ. NALIGN+1) THEN
                  POSPROPERTY=1
C all residues at that position dont show this property
	       ELSE IF(ISUM(IPROPERTY) .EQ. 0) THEN
                  POSPROPERTY=0
C this position is indifferent
	       ELSE
                  POSPROPERTY=2
	       ENDIF
C accumulate penalty
	       DO I=1,NTRANS
		  IF(POSPROPERTY .NE. 2 .AND.
     +                 POSPROPERTY .NE. PROPERTY(I,IPROPERTY)) THEN
                     POSPENALTY(IPOS,I)=POSPENALTY(IPOS,I)+1
                  ENDIF
	       ENDDO
	    ENDDO
C at conserved positions all other residues get an extra penalty
	    IF(LCONSERVED(IPOS)) THEN
               I=INDEX(TRANS,POSSTRING(1:1))
               DO J=1,NTRANS
                  IF(J.NE.I)POSPENALTY(IPOS,J)=POSPENALTY(IPOS,J)+1
               ENDDO
	    ENDIF
C gap-open penalty:  openval by default
C                    0.0 if there is gap somewhere at this position
C                    mean value + 1.0 if mean is greater than openval
	    IF(LGAP(IPOS)) THEN
               GAPOPEN(IPOS)=0.0
	    ELSE
	      SUM=0.0
	      DO IPROPERTY=1,NPROPERTY
                 SUM=SUM + ISUM(IPROPERTY)
	      ENDDO
	      MEAN= SUM / FLOAT(NALIGN+1)
	      IF(MEAN .GT. OPENVAL) THEN
                 GAPOPEN(IPOS)= MEAN + 1.0
	      ELSE
                 GAPOPEN(IPOS)= OPENVAL
	      ENDIF
           ENDIF
C gap-elongation is ELONGVAL
           GAPELONG(IPOS)=ELONGVAL
        ENDDO
      ENDDO
C "X!-" dont get a penalty
      J=INDEX(TRANS,'X') 
      DO I=1,MAXRES 
         POSPENALTY(I,J)=0 
      ENDDO
      J=INDEX(TRANS,'!') 
      DO I=1,MAXRES 
         POSPENALTY(I,J)=0 
      ENDDO
      J=INDEX(TRANS,'-') 
      DO I=1,MAXRES 
         POSPENALTY(I,J)=0 
      ENDDO
CDEBUG
c	OPEN(99,FILE='PROPERTY.X',RECL=2000,STATUS='NEW',
c     +	        CARRIAGECONTROL='LIST')
      OPEN(99,FILE='PROPERTY.X',RECL=2000,STATUS='NEW')
      DO I=1,NRES
         WRITE(99,'(25I4)')(POSPENALTY(I,J),J=1,NTRANS)
      ENDDO
      CLOSE(99)
CDEBUG
C for a Smith/Waterman type algorithm we have to invert the penalties !
      DO I=1,NRES 
         DO J=1,NTRANS
            POSPENALTY(I,J) = POSPENALTY(I,J) * (-1)
         ENDDO 
      ENDDO
      DO I=1,NRES 
         DO J=1,NTRANS
            PROFILEMETRIC(I,J)= FLOAT( POSPENALTY(I,J) )
         ENDDO 
      ENDDO
	
C scale the metric explicitly
      SMIN=MINVALUE 
      SMAX=MAXVALUE 
      MAPLOW=0.0 
      MAPHIGH=0.0
      WRITE(*,'(A,2(F7.2))')
     +        ' property metric scaled between: ',SMIN,SMAX
      CALL SCALE_PROFILE_METRIC(MAXRES,NTRANS,TRANS,
     +                     PROFILEMETRIC,SMIN,SMAX,MAPLOW,MAPHIGH)
C scale the gap-open penalty accordingly
      SMIN=0.0 
      SMAX=MAXVALUE 
      MAPLOW=0.0 
      MAPHIGH=0.0
      WRITE(*,'(A,2(F7.2))')
     +        ' gapopen scaled between: ',SMIN,SMAX
      CALL SCALEINTERVAL(GAPOPEN,MAXRES,SMIN,SMAX,MAPLOW,MAPHIGH)
C explicit conserved positions
      DO I=1,NRES
         IF(LKEEPCONSERV(I)) THEN
            IRES=INDEX(TRANS,ALILINE(1)(I:I))
            DO J=1,NTRANS
               IF(J .NE. IRES) THEN
                  PROFILEMETRIC(I,J)=-PUNISH
               ENDIF
            ENDDO
            GAPOPEN(I) =PUNISH
            GAPELONG(I)=PUNISH
         ENDIF
      ENDDO
      DO I=1,NRES
         IF(LKEEPCONSERV(I)) THEN
            SMIN=0.0 
            SMAX=0.0 
            MAPLOW=0.0 
            MAPHIGH=0.0
            RETURN
         ENDIF
      ENDDO
      SMIN=MINVALUE 
      SMAX=MAXVALUE 
      MAPLOW=0.0 
      MAPHIGH=0.0
      RETURN
      END
C     END GET_PROPERTY_PROFILE
C...................................................................... 

C......................................................................
C     SUB GET_SCALING
      SUBROUTINE GET_SCALING(SMIN,SMAX,MAPLOW,MAPHIGH,QUESTION)
 
      IMPLICIT NONE
      REAL SMIN,SMAX,MAPLOW,MAPHIGH
      CHARACTER QUESTION*(*)
      
      INTEGER IBEG,IEND,I
      CHARACTER*80 LINE
      LOGICAL EMPTYSTRING
      
      WRITE(*,*)'================================================'
      CALL STRPOS(QUESTION,IBEG,IEND)
      WRITE(*,*)QUESTION(IBEG:IEND)
      WRITE(*,*)' like: -0.5 1.0 0.0 0.0'
 10   WRITE(*,*)' '
      WRITE(*,'(A)')'  Enter 4 reals [CReturn or 0=end ]: '
      WRITE(*,*)'  default is: ',SMIN,SMAX,MAPLOW,MAPHIGH
      LINE=' '
      READ(*,'(A)',ERR=10,END=11) LINE
      IF(.NOT.EMPTYSTRING(LINE)) THEN
         DO I=1,80
            IF(INDEX(' .-+0123456789',LINE(I:I)).EQ.0) THEN
               WRITE(*,'(A)')'  *** not a real: '//LINE(1:40)
               GO TO 10
            ENDIF
         ENDDO
         CALL STRPOS(LINE,IBEG,IEND)
         READ(LINE,*,ERR=10,END=11)SMIN,SMAX,MAPLOW,MAPHIGH
      ENDIF
 11   WRITE(*,'(A,6F7.2)')'  echo: ',SMIN,SMAX,MAPLOW,MAPHIGH
 
      RETURN
      END
C     END GET_SCALING
C......................................................................
 
C......................................................................
C     SUB GET_VALUE
      SUBROUTINE GET_VALUE(ARRAY,QUESTION)
 
      IMPLICIT NONE
      REAL ARRAY(*)
      CHARACTER QUESTION*(*)
      
      INTEGER IBEG,IEND,I
      REAL VALUE
      
      WRITE(*,*)'================================================'
      CALL STRPOS(QUESTION,IBEG,IEND)
      WRITE(*,*)QUESTION(IBEG:IEND)
      WRITE(*,*)' like: 3.0 5 10'
      VALUE=.0001
      DO WHILE(VALUE .NE. 0.0)
         VALUE=0.0 
         IBEG=0 
         IEND=0
         CALL GETREALRANGE(VALUE,IBEG,IEND)
         IF(IEND.EQ.0)IEND=IBEG
         IF(IBEG.NE.0) THEN
            DO I=IBEG,IEND
               ARRAY(I)=VALUE
            ENDDO
         ENDIF
      ENDDO
 
      RETURN
      END
C     END GET_VALUE
C......................................................................
 
C......................................................................
C     SUB GETINTVALUE
      SUBROUTINE GETINTVALUE(IVALUE)
 
      INTEGER IVALUE
      CHARACTER*80 LINE
      LOGICAL EMPTYSTRING
 
 10   WRITE(*,'(A)')'  Enter 1 INTEGER [ 0=end ]: '
      LINE=' '
      READ(*,'(A)',ERR=10,END=11) LINE
      IF(.NOT.EMPTYSTRING(LINE)) THEN
         DO I=1,80
            IF(INDEX(' -+0123456789',LINE(I:I)).EQ.0) THEN
               WRITE(*,'(A)')'  *** not an integer: '//LINE(1:40)
               GOTO 10
            ENDIF
         ENDDO
         CALL STRPOS(LINE,IBEG,IEND)
         READ(LINE,*,ERR=10,END=11)IVALUE
      ENDIF
 11   WRITE(*,'(A,I6)')'  echo: ',IVALUE
      RETURN
      END
C     END GETINTVALUE
C......................................................................
 
C......................................................................
C     SUB GETINTRANGE
      SUBROUTINE GETINTRANGE(IRANGE1,IRANGE2)
 
      INTEGER IRANGE1,IRANGE2
      CHARACTER*80 LINE
      LOGICAL EMPTYSTRING
 
 10   WRITE(*,'(A)')'  Enter 2 integers [ 0=end ]: '
      LINE=' '
      READ(*,'(A)',ERR=10,END=11) LINE
      IF(.NOT.EMPTYSTRING(LINE)) THEN
         DO I=1,80
            IF(INDEX(' -+0123456789',LINE(I:I)).EQ.0) THEN
               write(*,'(a)')'  *** not an integer: '//line(1:40)
               GOTO 10
            ENDIF
         ENDDO
         CALL STRPOS(LINE,IBEG,IEND)
         READ(LINE,*,ERR=10,END=11)IRANGE1,IRANGE2
      ENDIF
 11   WRITE(*,'(a,2i4)')'  echo: ',irange1,irange2
      RETURN
      END
C     END GETINTRANGE
C......................................................................
 
C......................................................................
C     SUB GETREALRANGE
      SUBROUTINE GETREALRANGE(VALUE,IBEGIN,IEND)
 
      REAL VALUE
      INTEGER IBEGIN,IEND
      CHARACTER*80 LINE
      LOGICAL EMPTYSTRING
 
 10   WRITE(*,*)' '
      WRITE(*,'(A)')
     +    '  Enter 1 real and 2 integer [CReturn or 0=end ]: '
      LINE=' '
      READ(*,'(A)',ERR=10,END=11) LINE
      IF(.NOT.EMPTYSTRING(LINE)) THEN
         DO I=1,80
            IF(INDEX(' .-+0123456789',LINE(I:I)).EQ.0) THEN
               WRITE(*,'(A)')'  *** not numbers: '//LINE(1:40)
               GOTO 10
            ENDIF
         ENDDO
         CALL STRPOS(LINE,IBEG,IEND)
         READ(LINE,*,ERR=10,END=11)VALUE,IBEGIN,IEND
      ENDIF
 11   WRITE(*,'(A,F7.2,2I4)')'  echo: ',VALUE,IBEGIN,IEND
      RETURN
      END
C     END GETREALRANGE
C......................................................................
 
C......................................................................
C     SUB GETREALVALUE
      SUBROUTINE GETREALVALUE(VALUE)
 
      REAL VALUE
      CHARACTER*80 LINE
      LOGICAL EMPTYSTRING
 
 10   WRITE(*,'(A)')'  Enter 1 real number [ 0=end ]: '
      LINE=' '
      READ(*,'(A)',ERR=10,END=11) LINE
      IF(.NOT.EMPTYSTRING(LINE)) THEN
         DO I=1,80
            IF(INDEX(' .-+0123456789',LINE(I:I)).EQ.0) THEN
               WRITE(*,'(A)')'  *** not a real: '//LINE(1:40)
               GOTO 10
            ENDIF
         ENDDO
         CALL STRPOS(LINE,IBEG,IEND)
         READ(LINE,*,ERR=10,END=11)VALUE
      ENDIF
 11   WRITE(*,'(A,F7.2)')'  echo: ',VALUE
      RETURN
      END
C     END GETREALVALUE
C......................................................................
 
C...................................................................... 
C     SUB HSSP_TO_HORIZONTAL
      SUBROUTINE HSSP_TO_HORIZONTAL(MAXRES,ALIPOINTER,IFIR,ILAS,
     +     NALIGN,NRES,PDBSEQ,ALISEQ,ALILINE)
 
      IMPLICIT NONE
 
      INTEGER MAXRES,ALIPOINTER(*),IFIR(*),ILAS(*),NALIGN,NRES
      CHARACTER*(*) ALILINE(*),PDBSEQ(*),ALISEQ(*)
 
      LOGICAL LGAP(2000),LBEFORE
      INTEGER IBEG,IEND,IALIGN,IRES,JRES,IPOS,JPOS,I
      CHARACTER GAPSYMBOL,FREESYMBOL
      INTEGER LOWERPOS(256)
      CHARACTER LOWER*26,CTEMP
C used to convert lower case characters from the DSSP-seq to 'C' (Cys)
      LOWER='abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,256)
 
      GAPSYMBOL='-'
      FREESYMBOL='_'
C..set logical for gap
      DO IALIGN=1,NALIGN
         IBEG=ALIPOINTER(IALIGN)
         IEND=ILAS(IALIGN)-IFIR(IALIGN)
         JRES=IFIR(IALIGN)
         
         LBEFORE=.FALSE.
         DO IPOS=IBEG,IEND
            CTEMP=ALISEQ(IPOS)
            CALL GETINDEX(CTEMP,LOWERPOS,I)
            IF(I.NE.0) THEN
               IF(.NOT. LBEFORE) THEN
                  LGAP(JRES)=.TRUE.
                  LBEFORE=.TRUE.
               ELSE
	          LBEFORE=.FALSE.
               ENDIF
            ENDIF
            JRES=JRES+1
         ENDDO
      ENDDO
      
      DO I=1,MAXRES 
         ALILINE(1)(I:I)=FREESYMBOL 
      ENDDO
      JRES=1
      DO IRES=1,NRES
         CTEMP=PDBSEQ(IRES)
         CALL GETINDEX(CTEMP,LOWERPOS,I)
         IF(I.NE.0)CTEMP='C'
         IF(CTEMP.EQ.'!')CTEMP=GAPSYMBOL
         IF(LGAP(IRES)) THEN
            ALILINE(1)(JRES:JRES)=CTEMP     
            JRES=JRES+1
            ALILINE(1)(JRES:JRES)=GAPSYMBOL 
            JRES=JRES+1
         ELSE
            ALILINE(1)(JRES:JRES)=CTEMP   
            JRES=JRES+1
         ENDIF
      ENDDO
      DO IALIGN=1,NALIGN
         DO I=1,MAXRES 
            ALILINE(IALIGN+1)(I:I)=FREESYMBOL 
         ENDDO
         IBEG=ALIPOINTER(IALIGN)
         IEND=IBEG+ILAS(IALIGN)-IFIR(IALIGN)
         
         JRES=IFIR(IALIGN) 
         JPOS=JRES
         DO IPOS=IBEG,IEND
            CTEMP=ALISEQ(IPOS)
            CALL LOWTOUP(CTEMP,1)
            IF(CTEMP.EQ.'.')CTEMP=GAPSYMBOL
            IF(LGAP(IRES)) THEN
               ALILINE(IALIGN+1)(JRES:JRES)=CTEMP     
               JRES=JRES+1
               ALILINE(IALIGN+1)(JRES:JRES)=GAPSYMBOL 
               JRES=JRES+1
            ELSE
               ALILINE(IALIGN+1)(JRES:JRES)=CTEMP   
               JRES=JRES+1
            ENDIF
            JPOS=JPOS+1
         ENDDO
      ENDDO
      
c	OPEN(99,FILE='DEBUG.X',RECL=2000,STATUS='NEW',
c     +	        CARRIAGECONTROL='LIST')
c	OPEN(99,FILE='DEBUG.X',RECL=2000,STATUS='NEW')
c	DO I=1,NALIGN+1
c           WRITE(99,'(A)')ALILINE(I)(1:NRES)
c	ENDDO
c	CLOSE(99)
 
      RETURN
      END
C     END HSSP_TO_HORIZONTAL
C...................................................................... 

C......................................................................
C     SUB LUBKSB
      SUBROUTINE LUBKSB(A,N,NP,INDX,B)
      DIMENSION A(NP,NP),INDX(N),B(N)
      
      II=0
      DO I=1,N
         LL  = INDX(I)
         SUM = B(LL)
         B(LL) = B(I)
         IF (II .NE. 0) THEN
	    DO J=II,I-1
               SUM = SUM - A(I,J) * B(J)
	    ENDDO
         ELSE IF (SUM .NE. 0.0) THEN
	    II=I
         ENDIF
         B(I)=SUM
      ENDDO
      DO I=N,1,-1
         SUM=B(I)
         IF(I .LT. N) THEN
	    DO J=I+1,N
               SUM = SUM - A(I,J) * B(J)
	    ENDDO
         ENDIF
         B(I)=SUM/A(I,I)
      ENDDO
      RETURN
      END
C     end LUBKSB
C...................................................................... 

C......................................................................
C     SUB LUDCMP
      SUBROUTINE LUDCMP(A,N,NP,INDX,D)
      PARAMETER (NMAX=100,TINY=1.0E-20)
      DIMENSION A(NP,NP),INDX(N),VV(NMAX)
C init
      D = 1.0
C check dimension
      IF( N .GT. NMAX) THEN
         WRITE(*,*)'ERROR; dimesnion overflow in LUDCMP'
         STOP
      ENDIF
      DO I=1,N
         AAMAX = 0.0
         DO J=1,N
            IF (ABS(A(I,J)) .GT. AAMAX) AAMAX = ABS(A(I,J))
         ENDDO
         IF (AAMAX .EQ. 0.0) THEN
            WRITE(*,*)'Singular matrix.'
            STOP
         ENDIF
         VV(I)=1.0 / AAMAX
      ENDDO
      DO J=1,N
         IF (J .GT. 1) THEN
            DO I=1,J-1
               SUM=A(I,J)
               IF (I .GT. 1) THEN
                  DO K=1,I-1
                     SUM = SUM - A(I,K) * A(K,J)
                  ENDDO
                  A(I,J)=SUM
               ENDIF
            ENDDO
         ENDIF
         AAMAX=0.0
         DO I=J,N
            SUM=A(I,J)
            IF (J .GT. 1) THEN
               DO K=1,J-1
                  SUM = SUM - A(I,K) * A(K,J)
               ENDDO
               A(I,J)=SUM
            ENDIF
            DUM=VV(I) * ABS(SUM)
            IF (DUM .GE. AAMAX) THEN
               IMAX=I
               AAMAX=DUM
            ENDIF
         ENDDO
         IF (J .NE. IMAX) THEN
            DO K=1,N
               DUM = A(IMAX,K)
               A(IMAX,K) = A(J,K)
               A(J,K) = DUM
            ENDDO
            D=-D
            VV(IMAX)=VV(J)
         ENDIF
         INDX(J)=IMAX
         IF(J .NE. N) THEN
            IF(A(J,J) .EQ. 0.0)A(J,J)=TINY
            DUM=1.0 / A(J,J)
            DO I=J+1,N
               A(I,J) = A(I,J) * DUM
            ENDDO
         ENDIF
      ENDDO
      IF(A(N,N) .EQ. 0.0 )A(N,N)=TINY
      RETURN
      END
C     END LUDCMP
C...................................................................... 

C......................................................................
C     SUB MAIN_MENU
      SUBROUTINE MAIN_MENU(KEYWORD)
      IMPLICIT NONE
      CHARACTER KEYWORD*(*)
 
      INTEGER IBEG,IEND
      CHARACTER QUESTION*500
 
 10   WRITE(*,*)'===================================================='
      WRITE(QUESTION,'(A)')'select option: /n'//
     +  ' Box        : definition of profile boxes /n'//
     +  ' Metric     : change exchange metric /n'//
     +  ' Profile    : calculate profile and sequence weights/n'//
     +  ' Scale      : change scaling of the metric /n'//
     +  ' Open       : change gap open penalties /n'//
     +  ' Elongation : change gap elongation penalties /n'//
     +  ' Weights    : calculate position dependent weights /n'//
     +  ' Show       : print profile on screen /n'//
     +  ' Exit       : write profile and exit'
 
      KEYWORD=' '
      CALL GETCHAR(80,KEYWORD,QUESTION)
      CALL LOWTOUP(KEYWORD,80)
      CALL STRPOS(KEYWORD,IBEG,IEND)
      IF(IBEG .LE. 0 .OR. IEND .LE. 0)GOTO 10
      IF(KEYWORD(IBEG:IBEG) .EQ. 'B' ) THEN
         KEYWORD='BOX'
      ELSE IF(KEYWORD(IBEG:IBEG) .EQ. 'M' ) THEN
         KEYWORD='METRIC'
      ELSE IF(KEYWORD(IBEG:IBEG) .EQ. 'P' ) THEN
         KEYWORD='PROFILE'
      ELSE IF(KEYWORD(IBEG:IBEG+1) .EQ. 'SC' ) THEN
         KEYWORD='SCALE'
      ELSE IF(KEYWORD(IBEG:IBEG) .EQ. 'O' ) THEN
         KEYWORD='OPEN'
      ELSE IF(KEYWORD(IBEG:IBEG+1) .EQ. 'EL' ) THEN
         KEYWORD='ELONGATION'
      ELSE IF(KEYWORD(IBEG:IBEG) .EQ. 'W' ) THEN
         KEYWORD='WEIGHTS'
      ELSE IF(KEYWORD(IBEG:IBEG+1) .EQ. 'EX' ) THEN
         KEYWORD='EXIT'
      ELSE IF(KEYWORD(IBEG:IBEG+1) .EQ. 'SH' ) THEN
         KEYWORD='SHOW'
      ENDIF
      RETURN
      END
C     END MAIN_MENU
C......................................................................
 
C......................................................................
C     SUB SEQTOINT
      SUBROUTINE SEQTOINT(SEQ,LSEQ,NRES,CTRANS,NTRANS)
C converts string of amino acid characters to amino acid integers.
C.uses translation table CHARACTER*NTRANS CTRANS, by C.Sander Nov 1984.
C.internally converts DSSP SS bridges to 'C' before converting to integer.
C.input may contain funnies like '!'
C.output will be in the range 0 <= LSEQ <= NTRANS
C.if NTRANS=23 and CTRANS='VLIMFWYGAPSTCHRKQEND-BZ' then
C.implied convention: extra AAs such as '-BZ' get LSEQ=21,22,23
C                      illegals such as '!' get LSEQ=0
C.if NTRANS=20 then '-BZ' and '!' get LSEQ=0
      INTEGER LSEQ(*)
      CHARACTER*1 SEQ(*),ALTSEQ
C! or use *23
      CHARACTER CTRANS*(*)
      LOGICAL NOILLEGAL
      CHARACTER LOWER*26
 
      DATA LOWER/'abcdefghijklmnopqrstuvwxyz'/
      NOILLEGAL=.TRUE.
 
      DO I=1,NRES
         IF(INDEX(LOWER,SEQ(I)).NE.0) THEN
            ALTSEQ='C'
         ELSE
            ALTSEQ=SEQ(I)
         ENDIF
 
         LSEQ(I)=INDEX(CTRANS(1:NTRANS),ALTSEQ)
 
         IF(LSEQ(I).EQ.0) THEN
            IF(NOILLEGAL) THEN
               NOILLEGAL=.FALSE.
               WRITE(*,'(A)')' *** unknown res or chain separator'//
     +              ' in SEQTOINT: '
            ENDIF
            WRITE(*,'(1X,A1,$)')SEQ(I)
         ENDIF
      ENDDO
      RETURN
      END
C     END SEQTOINT
C...................................................................... 

C......................................................................
C     SUB SHOW_BOX
      SUBROUTINE SHOW_BOX(MAXBOX,NBOX,PROFILEBOX,TEMPSEQ,TEMPSTRUC,
     +     LDSSP)
 
      IMPLICIT NONE
      INTEGER MAXBOX,NBOX,PROFILEBOX(MAXBOX,2)
      CHARACTER*(*) TEMPSEQ,TEMPSTRUC
      LOGICAL LDSSP
      
      INTEGER IBEG,IEND,I
      
      WRITE(*,*)'=================================== BOXES '//
     +     '===================================='
      IF(LDSSP) THEN
         WRITE(*,*)'No. begin  end  sequence and secondary structure'
      ELSE
         WRITE(*,*)'No. begin  end  sequence'
      ENDIF
      DO I=1,NBOX
         IBEG=PROFILEBOX(I,1) 
         IEND=PROFILEBOX(I,2)
         WRITE(*,'(I3,2X,I4,1X,I4,2X,A)')
     +        I,IBEG,IEND,TEMPSEQ(IBEG:IEND)
         IF(LDSSP) THEN
	    WRITE(*,'(16X,A)')TEMPSTRUC(IBEG:IEND)
         ENDIF
      ENDDO
      RETURN
      END
C     END SHOW_BOX
C......................................................................
 
C......................................................................
C     SUB SHOW_PROFILE
      SUBROUTINE SHOW_PROFILE(MAXRES,NRES,PDBSEQ,SECSTRUC,
     +     GAPOPEN,GAPELONG,CONSWEIGHT,
     +     PROFILEMETRIC)
 
C import
      INTEGER NRES
      CHARACTER PDBSEQ(*),SECSTRUC(*)
      REAL GAPOPEN(*),GAPELONG(*),CONSWEIGHT(*)
C export
      REAL PROFILEMETRIC(MAXRES,*)
C internal
      CHARACTER KEY*1,LINE*200,HEADER*132
      INTEGER I,IRES,JRES,IPOS,NSTEP,LENGTH,IBEG,IEND
 
      WRITE(HEADER,*)'V    L     I     M     F     W     Y     G'//
     +                 '     A     P     S     T     C     H     R'//
     +                 '     K     Q     E     N     D'
      CALL STRPOS(HEADER,IBEG,LENGTH)
      KEY=' '
      NSTEP=10
 
      DO I=1,NRES,NSTEP
         WRITE(*,'(a)')'ResNo seq struc  open  elong weight'
         WRITE(*,'(A)')HEADER(:LENGTH)
         DO IRES=I,MIN(I+NSTEP-1,NRES)
            IPOS=1
            DO JRES=1,20
               WRITE(LINE(IPOS:),'(F5.2)')PROFILEMETRIC(IRES,JRES)
               IPOS=IPOS+6
            ENDDO
            CALL STRPOS(LINE,IBEG,IEND)
            WRITE(*,'(I4,4X,A,3X,A,3(2X,F5.2))')IRES,PDBSEQ(IRES),
     +           SECSTRUC(IRES),GAPOPEN(IRES),GAPELONG(IRES),
     +           CONSWEIGHT(IRES)
            WRITE(*,'(I4,1X,A)')IRES,LINE(:IEND)
         ENDDO
         WRITE(*,*)'========== hit return to continue or any key '//
     +        'to exit ============'
         READ(*,'(A)')KEY
         IF(KEY .NE. ' ')RETURN
      ENDDO
      RETURN
      END
C     END SHOW_PROFILE
C...................................................................... 

C......................................................................
C     SUB SINGLE_SEQ_WEIGHTS
      SUBROUTINE SINGLE_SEQ_WEIGHTS(NALIGN,ALISEQ,
     +     ALIPOINTER,IFIR,ILAS,MODE,WEIGHTS)
c
c     input: hssp alignments
c       w0 -- eigenvalue iteration weights x(i)
c       w1 -- squared eigenvectors x(i)**2
c       w2 -- sum of distances w(i)=SUM(dist(i,j))
c       w3 -- exponential weight w(i)=1/SUM(exp(-dist(i,j)/dmean))
c
      IMPLICIT NONE
C import
      INTEGER NALIGN
      INTEGER IFIR(*),ILAS(*),ALIPOINTER(*)
      CHARACTER ALISEQ(*)
      CHARACTER MODE*(*)
C export
      REAL WEIGHTS(*)
c
      INTEGER MAXALIGNS,MAXSTEP
      PARAMETER (MAXALIGNS=1000)
      PARAMETER(MAXSTEP=100)
      REAL TOLERANCE
      PARAMETER(TOLERANCE=0.00001)
      REAL DIST(MAXALIGNS,MAXALIGNS)
      REAL SIM_TABLE(MAXALIGNS,MAXALIGNS)
      INTEGER MAXAA
      REAL SEL_PRESS,XPOWER,XTEMP1,XTEMP2
      REAL WTEMP(MAXALIGNS),VTEMP(MAXALIGNS,MAXALIGNS)
C
      INTEGER STEP
      CHARACTER A1,A2
      INTEGER LENGTH,NPOS
      INTEGER I,J,K,K0,K1
      REAL X,S,DMEAN

      MAXAA=19
 
      I=LEN(MODE)
      CALL LOWTOUP(MODE,I)
      IF(NALIGN .GT. MAXALIGNS) THEN
         WRITE(*,*)' maxaligns overflow in single_seq_weight'
         STOP
      ENDIF
 
      DO I=1,NALIGN
         WEIGHTS(I)=1.0
      ENDDO
      IF(NALIGN .LE. 1) THEN
         WRITE(*,*)' SINGLE_SEQ_WEIGHT: no alignments !'
         RETURN
      ENDIF
C     calculate distance/identity table
      WRITE(*,*)' calculate distance table...'
      DO I=1,NALIGN
         DIST(I,I)=0.0
         SIM_TABLE(I,I)=1.0
         DO J=I+1,NALIGN
            LENGTH=0
            NPOS=0
            K0=MAX(IFIR(I),IFIR(J))
            K1=MIN(ILAS(I),ILAS(J))
            DO K=K0,K1
               NPOS=NPOS+1
               A1= ALISEQ(ALIPOINTER(I)+K-IFIR(I))
               A2= ALISEQ(ALIPOINTER(J)+K-IFIR(J))
               IF(A1 .GE. 'a' .AND. A1 .LE. 'z') THEN
                  A1=CHAR( ICHAR(A1)-32 )
               ENDIF
               IF(A2 .GE. 'a' .AND. A2 .LE. 'z') THEN
                  A2=CHAR( ICHAR(A2)-32 )
               ENDIF
               IF(A1.EQ.A2) LENGTH=LENGTH+1
            END DO
            SIM_TABLE(I,J)=FLOAT(LENGTH)/MAX(1.0,FLOAT(NPOS))
            DIST(I,J)= 1.00 - SIM_TABLE(I,J)
            DIST(J,I)=DIST(I,J)
            SIM_TABLE(J,I)=SIM_TABLE(I,J)
         END DO
      END DO
c	write(*,*) ' distances: '
c	do i=1,nalign
c	   write(*,'(26i3)') (nint(100*dist(j,i)),j=1,nalign)
c	end do
c
      IF(INDEX(MODE,'MAT'). NE. 0 ) THEN
         WRITE(*,*)' preparing identity matrix...'
         SEL_PRESS=0.5
         XPOWER= 1.0 / (1.0 - SEL_PRESS + (1.0/MAXAA) )
         XTEMP1= 1.0 + (1.0 / (MAXAA * (1.0 - SEL_PRESS) ) )
         XTEMP2= 1.0 / (MAXAA * (1-SEL_PRESS) )
         DO I=1,NALIGN 
            DO J=1,NALIGN
               X=SIM_TABLE(I,J)
               SIM_TABLE(I,J) = ( SIM_TABLE(I,J) * XTEMP1 - XTEMP2 )
               IF(SIM_TABLE(I,J) .LE. TOLERANCE) THEN
                  WRITE(*,*)'set sim_table to tolerance ',i,j
                  SIM_TABLE(I,J) = TOLERANCE
               ENDIF
               SIM_TABLE(I,J) = SIM_TABLE(I,J) **XPOWER
            ENDDO 
         ENDDO
         WRITE(*,*)' calculate singular value decomposition...'
         CALL SVDCMP(SIM_TABLE,NALIGN,NALIGN,MAXALIGNS,MAXALIGNS,WTEMP,
     +        VTEMP)
         WRITE(*,*)' calculate matrix invers...'
         DO I=1,NALIGN
            IF (WTEMP(I) .LE. 0.0001) THEN
               X=0.0
            ELSE
               X= 1/WTEMP(I)
            ENDIF
            DO J=1,NALIGN
               SIM_TABLE(I,J) = VTEMP(I,J) * X * SIM_TABLE(I,J)
               WEIGHTS(I) = WEIGHTS(I) + SIM_TABLE(I,J)
            ENDDO
         ENDDO
c=======================================================================
c     calculate one-sequence weights from a distance matrix
c     step 0: w(k)    = 1 / N * sum[dist(k,length)]
c     step i: w(k)(i) = 1 / NORM * sum[dist(k,l) * w(length)(i-1)]
c     iterate until sum[|w(k)(i)-w(k)(i-1)|] < tolerance
c=======================================================================
c  eigenvector iteration
c=======================================================================
      ELSE IF(INDEX(MODE,'EIGEN')  .NE. 0 .OR.
     +        INDEX(MODE,'SQUARE') .NE. 0) THEN
         DO I=1,NALIGN
            WTEMP(I)=1.0/NALIGN
         END DO
         STEP=0
 10      STEP=STEP+1
         X=0.0
         DO I=1,NALIGN
            WEIGHTS(I)=0.0
            DO J=1,NALIGN
               WEIGHTS(I) = WEIGHTS(I) + WTEMP(J) * DIST(I,J)
            END DO
            X=X+WEIGHTS(I)
         END DO
         S=0.0
         DO I=1,NALIGN
            S = S +(WTEMP(I)-WEIGHTS(I)/X) * (WTEMP(I)-WEIGHTS(I)/X)
            WTEMP(I)=WEIGHTS(I)/X
         END DO
         S=SQRT(S/NALIGN)
         IF((STEP .LT. MAXSTEP) .AND. (S .GT. TOLERANCE)) GOTO 10
         WRITE(*,'(a,i5,a,f10.4)')' weights at step:', step,
     +        ' difference: ',s
         WRITE(*,'(13F6.3)') (NALIGN*WTEMP(I),I=1,NALIGN)
      ENDIF
c=======================================================================
c                           weights(i)=wtemp(i)**2
c=======================================================================
      IF(INDEX(MODE,'SQUARE') .NE. 0) THEN
         S=0.0
         DO I=1,NALIGN
            WEIGHTS(I)=WTEMP(I) * WTEMP(I)
            S=S+WEIGHTS(I)
         END DO
         DO I=1,NALIGN
            WEIGHTS(I)=WEIGHTS(I)/S
         END DO
         WRITE(*,*) ' SQUARED WEIGHTS '
         WRITE(*,'(13F6.3)') (NALIGN*WEIGHTS(I),I=1,NALIGN)
c=======================================================================
c     weights(i)=SUM(dist(i,j))
c=======================================================================
      ELSE IF(INDEX(MODE,'SUM') .NE. 0) THEN
         S=0.0
         DO I=1,NALIGN
            WEIGHTS(I)=0.0
            DO J=1,NALIGN
               WEIGHTS(I)=WEIGHTS(I) + DIST(I,J)
            END DO
            S=S+WEIGHTS(I)
         END DO
         DO I=1,NALIGN
            WEIGHTS(I)=WEIGHTS(I)/S
         END DO
         WRITE(*,*) ' summed distance weights '
         WRITE(*,'(13F6.3)') (NALIGN*WEIGHTS(I),I=1,NALIGN)
c=======================================================================
c               weights(i)=1/SUM(exp(-dist(i,j)/dmean))
c=======================================================================
      ELSE IF(INDEX(MODE,'EXP') .NE. 0) THEN
         S=0.0
         DO I=1,NALIGN
            DO J=I+1,NALIGN
               S=S+DIST(I,J)
            END DO
         END DO
         DMEAN=S/NALIGN/(NALIGN-1)*2
         DO I=1,NALIGN
            S=0.0
            DO J=1,NALIGN
               S=S+EXP(-DIST(I,J)/DMEAN)
            END DO
            IF(S.GT.0.0) THEN
               WEIGHTS(I)=1/S
            ELSE
               WRITE(*,*)  ' warning: s=0 in weights '
               WEIGHTS(I)=1.0
            END IF
         END DO
c     normalize to 1.0
         S=0.0
         DO I=1,NALIGN
            S=S+WEIGHTS(I)
         END DO
         DO I=1,NALIGN
            WEIGHTS(I)=WEIGHTS(I)/S
         END DO
         WRITE(*,*) ' exponential distance weights '
         WRITE(*,'(13F6.3)') (NALIGN*WEIGHTS(I),I=1,NALIGN)
      ENDIF

      RETURN
      END
C     END SINGLE_SEQ_WEIGHT
C...................................................................... 
 
C......................................................................
C     SUB SVDCMP
      SUBROUTINE SVDCMP(A,M,N,MP,NP,W,V)
      PARAMETER (NMAX=2000)
      DIMENSION A(MP,NP),W(NP),V(NP,NP),RV1(NMAX)
      G=0.0
      SCALE=0.0
      ANORM=0.0
      IF(M .GT. NMAX) THEN
         WRITE(*,*)'***ERROR: dim. overflow for RV1 in SVDCMP'
         STOP
      ENDIF
      DO 25 I=1,N
         L=I+1
         RV1(I)=SCALE*G
         G=0.0
         S=0.0
         SCALE=0.0
         IF (I.LE.M) THEN
	    DO 11 K=I,M
               SCALE=SCALE+ABS(A(K,I))
 11         CONTINUE
            IF (SCALE.NE.0.0) THEN
               DO 12 K=I,M
                  A(K,I)=A(K,I)/SCALE
                  S=S+A(K,I)*A(K,I)
 12            CONTINUE
               F=A(I,I)
               G=-SIGN(SQRT(S),F)
               H=F*G-S
               A(I,I)=F-G
               IF (I.NE.N) THEN
                  DO 15 J=L,N
                     S=0.0
                     DO 13 K=I,M
                        S=S+A(K,I)*A(K,J)
 13                  CONTINUE
                     F=S/H
                     DO 14 K=I,M
                        A(K,J)=A(K,J)+F*A(K,I)
 14                  CONTINUE
 15               CONTINUE
               ENDIF
               DO 16 K= I,M
                  A(K,I)=SCALE*A(K,I)
 16            CONTINUE
            ENDIF
         ENDIF
         W(I)=SCALE *G
         G=0.0
         S=0.0
         SCALE=0.0
         IF ((I.LE.M).AND.(I.NE.N)) THEN
            DO 17 K=L,N
               SCALE=SCALE+ABS(A(I,K))
 17         CONTINUE
            IF (SCALE.NE.0.0) THEN
               DO 18 K=L,N
                  A(I,K)=A(I,K)/SCALE
                  S=S+A(I,K)*A(I,K)
 18            CONTINUE
               F=A(I,L)
               G=-SIGN(SQRT(S),F)
               H=F*G-S
               A(I,L)=F-G
               DO 19 K=L,N
                  RV1(K)=A(I,K)/H
 19            CONTINUE
               IF (I.NE.M) THEN
                  DO 23 J=L,M
                     S=0.0
                     DO 21 K=L,N
                        S=S+A(J,K)*A(I,K)
 21                  CONTINUE
                     DO 22 K=L,N
                        A(J,K)=A(J,K)+S*RV1(K)
 22                  CONTINUE
 23               CONTINUE
               ENDIF
               DO 24 K=L,N
                  A(I,K)=SCALE*A(I,K)
 24            CONTINUE
            ENDIF
         ENDIF
         ANORM=MAX(ANORM,(ABS(W(I))+ABS(RV1(I))))
 25   CONTINUE
      DO 32 I=N,1,-1
         IF (I.LT.N) THEN
            IF (G.NE.0.0) THEN
               DO 26 J=L,N
                  V(J,I)=(A(I,J)/A(I,L))/G
 26            CONTINUE
               DO 29 J=L,N
                  S=0.0
                  DO 27 K=L,N
                     S=S+A(I,K)*V(K,J)
 27               CONTINUE
                  DO 28 K=L,N
                     V(K,J)=V(K,J)+S*V(K,I)
 28               CONTINUE
 29            CONTINUE
            ENDIF
            DO 31 J=L,N
               V(I,J)=0.0
               V(J,I)=0.0
 31         CONTINUE
         ENDIF
         V(I,I)=1.0
         G=RV1(I)
         L=I
 32   CONTINUE
      DO 39 I=N,1,-1
         L=I+1
         G=W(I)
         IF (I.LT.N) THEN
            DO 33 J=L,N
               A(I,J)=0.0
 33         CONTINUE
         ENDIF
         IF (G.NE.0.0) THEN
            G=1.0/G
            IF (I.NE.N) THEN
               DO 36 J=L,N
                  S=0.0
                  DO 34 K=L,M
                     S=S+A(K,I)*A(K,J)
 34               CONTINUE
                  F=(S/A(I,I))*G
                  DO 35 K=I,M
                     A(K,J)=A(K,J)+F*A(K,I)
 35               CONTINUE
 36            CONTINUE
            ENDIF
            DO 37 J=I,M
               A(J,I)=A(J,I)*G
 37         CONTINUE
         ELSE
            DO 38 J= I,M
               A(J,I)=0.0
 38         CONTINUE
         ENDIF
         A(I,I)=A(I,I)+1.0
 39   CONTINUE
      DO 49 K=N,1,-1
         DO 48 ITS=1,30
            DO 41 L=K,1,-1
               NM=L-1
               IF ((ABS(RV1(L))+ANORM).EQ.ANORM)  GO TO 2
               IF ((ABS(W(NM))+ANORM).EQ.ANORM)  GO TO 1
 41         CONTINUE
 1          C=0.0
            S=1.0
            DO 43 I=L,K
               F=S*RV1(I)
               IF ((ABS(F)+ANORM).NE.ANORM) THEN
                  G=W(I)
                  H=SQRT(F*F+G*G)
                  W(I)=H
                  H=1.0/H
                  C= (G*H)
                  S=-(F*H)
                  DO 42 J=1,M
                     Y=A(J,NM)
                     Z=A(J,I)
                     A(J,NM)=(Y*C)+(Z*S)
                     A(J,I)=-(Y*S)+(Z*C)
 42               CONTINUE
               ENDIF
 43         CONTINUE
 2          Z=W(K)
            IF (L.EQ.K) THEN
               IF (Z.LT.0.0) THEN
                  W(K)=-Z
                  DO 44 J=1,N
                     V(J,K)=-V(J,K)
 44               CONTINUE
               ENDIF
               GO TO 3
            ENDIF
            IF (ITS.EQ.30) PAUSE 'No convergence in 30 iterations'
            X=W(L)
            NM=K-1
            Y=W(NM)
            G=RV1(NM)
            H=RV1(K)
            F=((Y-Z)*(Y+Z)+(G-H)*(G+H))/(2.0*H*Y)
            G=SQRT(F*F+1.0)
            F=((X-Z)*(X+Z)+H*((Y/(F+SIGN(G,F)))-H))/X
            C=1.0
            S=1.0
            DO 47 J=L,NM
               I=J+1
               G=RV1(I)
               Y=W(I)
               H=S*G
               G=C*G
               Z=SQRT(F*F+H*H)
               RV1(J)=Z
               C=F/Z
               S=H/Z
               F= (X*C)+(G*S)
               G=-(X*S)+(G*C)
               H=Y*S
               Y=Y*C
               DO 45 NM=1,N
                  X=V(NM,J)
                  Z=V(NM,I)
                  V(NM,J)= (X*C)+(Z*S)
                  V(NM,I)=-(X*S)+(Z*C)
 45            CONTINUE
               Z=SQRT(F*F+H*H)
               W(J)=Z
               IF (Z.NE.0.0) THEN
                  Z=1.0/Z
                  C=F*Z
                  S=H*Z
               ENDIF
               F= (C*G)+(S*Y)
               X=-(S*G)+(C*Y)
               DO 46 NM=1,M
                  Y=A(NM,J)
                  Z=A(NM,I)
                  A(NM,J)= (Y*C)+(Z*S)
                  A(NM,I)=-(Y*S)+(Z*C)
 46            CONTINUE
 47         CONTINUE
            RV1(L)=0.0
            RV1(K)=F
            W(K)=X
 48      CONTINUE
 3       CONTINUE
 49   CONTINUE
      RETURN
      END
C     end SVDCMP
C...................................................................... 

C ======================================================================
C xxxxxx libs xxxx
C ======================================================================

