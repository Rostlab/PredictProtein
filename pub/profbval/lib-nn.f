
***** ------------------------------------------------------------------
***** FCT EMPTYSTRING
***** ------------------------------------------------------------------
C---- 
C---- NAME : EMPTYSTRING
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      FUNCTION EMPTYSTRING(STRING)
      LOGICAL EMPTYSTRING
      CHARACTER STRING*(*)
      EMPTYSTRING=.TRUE.
      DO I=1,LEN(STRING)  
         IF(STRING(I:I).NE.' ') THEN
            EMPTYSTRING=.FALSE.
            RETURN
         ENDIF
      ENDDO
      RETURN
      END
***** end of EMPTYSTRING

***** ------------------------------------------------------------------
***** FCT FILEN_STRING
***** ------------------------------------------------------------------
C---- 
C---- NAME : FILEN_STRING
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Feb,        1993        version 0.1    *
*                      changed: Oct,        1994        version 0.2    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
*     purpose:        The length of a given character string is returned
*     input:          STRING     string of character*80                *
*     output:         LEN        length of string without blanks       *
*----------------------------------------------------------------------*
      INTEGER FUNCTION FILEN_STRING(STRING)
C---- variables passing
      CHARACTER       STRING*(*)
C---- local variables
      INTEGER         ITER,ITER2,COUNT,COUNTBEF,NCHAR
      CHARACTER*80    CHECK
      LOGICAL         LHELP,LHELP2
******------------------------------*-----------------------------******
C---- defaults
      CHECK(1:52)=
     +     'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
      CHECK(53:73)='1234567890-._/+=:!~*,'
      NCHAR=73

      LHELP=.TRUE.
      COUNT=0
      COUNTBEF=0
      DO ITER=1,80
         IF (LHELP) THEN
            LHELP2=.FALSE.
            DO ITER2=1,NCHAR
               IF ((.NOT.LHELP2).AND.
     +              STRING(ITER:ITER).EQ.CHECK(ITER2:ITER2)) THEN
                  LHELP2=.TRUE.
                  COUNT=COUNT+1
               END IF
            END DO
            IF (.NOT.LHELP2) THEN
               IF ( (COUNT.EQ.0).AND.(STRING(ITER:ITER).eq.' ') ) THEN
                  COUNTBEF=COUNTBEF+1
               ELSE
                  LHELP=.FALSE.
                  FILEN_STRING=ITER-1-COUNTBEF
               END IF
            END IF
         END IF
      END DO

      IF (COUNT.NE.FILEN_STRING) THEN
         WRITE(6,'(T2,A)')'-!-'
         WRITE(6,'(T2,A,T10,A)')'-!-','WARNING FILEN_STRING:'//
     +        'two different results.'
         WRITE(6,'(T2,A,T10,A,T20,I5,T30,A,T40,I5,T50,A,T60,A1,A,A1)')
     +        '-!-','first = ',FILEN_STRING,
     +        'count: ',count,'for: ','|',STRING,'|'
         WRITE(6,'(T2,A)')'-!-'
      END IF

      FILEN_STRING=COUNT
      END
***** end of FILEN_STRING

***** ------------------------------------------------------------------
***** FCT FILENSTRING
***** ------------------------------------------------------------------
C---- 
C---- NAME : FILENSTRING
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Feb,        1993        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
*     purpose:        The length of a given character string is returned
*     input:          STRING     string of character*80                *
*     output:         LEN        length of string without blanks       *
*----------------------------------------------------------------------*
      INTEGER FUNCTION FILENSTRING(STRING)
C---- variables passing
      CHARACTER       STRING*(*)
C---- local variables
      INTEGER         ICOUNT,ITER
      LOGICAL         LHELP
******------------------------------*-----------------------------******
C---- defaults
      ICOUNT=0
      LHELP=.TRUE.
      DO ITER=1,80
         IF (LHELP.AND.(STRING(ITER:ITER).NE.' ')) THEN
            ICOUNT=ICOUNT+1
         ELSE
            LHELP=.FALSE.
         END IF
      END DO
      FILENSTRING=ICOUNT
      END
***** end of FILENSTRING

***** ------------------------------------------------------------------
***** FCT FILENSTRING_ALPHANUMSEN
***** ------------------------------------------------------------------
C---- 
C---- NAME : FILENSTRING_ALPHANUMSEN
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Feb,        1993        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
*     purpose:        The length of a given character string is returned
*     --------        (only numbers 0-9, letters a-z, A-Z, and the fol-*
*                     lowing symbols are allowed: '.','-','_'.         *
*     input:          STRING     string of character*80                *
*     output:         LEN        length of string without blanks       *
*----------------------------------------------------------------------*
      INTEGER FUNCTION FILENSTRING_ALPHANUMSEN(STRING)
C---- variables passing
      CHARACTER       STRING*(*)
C---- local variables
      INTEGER         ICOUNT,ITER
      LOGICAL         LHELP,LLETTER,LREST
******------------------------------*-----------------------------******
C---- defaults
      ICOUNT=0
      LHELP=.TRUE.

      DO ITER=1,80
         IF (LHELP) THEN
            LLETTER=.FALSE.
            LREST=.FALSE.
            IF ((STRING(ITER:ITER).EQ.'A').OR.
     +           (STRING(ITER:ITER).EQ.'B').OR.
     +           (STRING(ITER:ITER).EQ.'C').OR.
     +           (STRING(ITER:ITER).EQ.'D').OR.
     +           (STRING(ITER:ITER).EQ.'E').OR.
     +           (STRING(ITER:ITER).EQ.'F').OR.
     +           (STRING(ITER:ITER).EQ.'G').OR.
     +           (STRING(ITER:ITER).EQ.'H').OR.
     +           (STRING(ITER:ITER).EQ.'I').OR.
     +           (STRING(ITER:ITER).EQ.'J').OR.
     +           (STRING(ITER:ITER).EQ.'K').OR.
     +           (STRING(ITER:ITER).EQ.'L').OR.
     +           (STRING(ITER:ITER).EQ.'M').OR.
     +           (STRING(ITER:ITER).EQ.'N').OR.
     +           (STRING(ITER:ITER).EQ.'O').OR.
     +           (STRING(ITER:ITER).EQ.'P').OR.
     +           (STRING(ITER:ITER).EQ.'Q').OR.
     +           (STRING(ITER:ITER).EQ.'R').OR.
     +           (STRING(ITER:ITER).EQ.'S').OR.
     +           (STRING(ITER:ITER).EQ.'T')) THEN
               LLETTER=.TRUE.
            END IF
            IF (.NOT.LLETTER) THEN
               IF ((STRING(ITER:ITER).EQ.'U').OR.
     +              (STRING(ITER:ITER).EQ.'V').OR.
     +              (STRING(ITER:ITER).EQ.'W').OR.
     +              (STRING(ITER:ITER).EQ.'X').OR.
     +              (STRING(ITER:ITER).EQ.'Y').OR.
     +              (STRING(ITER:ITER).EQ.'Z').OR.
     +              (STRING(ITER:ITER).EQ.'a').OR.
     +              (STRING(ITER:ITER).EQ.'b').OR.
     +              (STRING(ITER:ITER).EQ.'c').OR.
     +              (STRING(ITER:ITER).EQ.'d').OR.
     +              (STRING(ITER:ITER).EQ.'e').OR.
     +              (STRING(ITER:ITER).EQ.'f').OR.
     +              (STRING(ITER:ITER).EQ.'g').OR.
     +              (STRING(ITER:ITER).EQ.'h').OR.
     +              (STRING(ITER:ITER).EQ.'i').OR.
     +              (STRING(ITER:ITER).EQ.'j')) THEN
                  LLETTER=.TRUE.
               END IF
            END IF
            IF (.NOT.LLETTER) THEN
               IF ((STRING(ITER:ITER).EQ.'k').OR.
     +              (STRING(ITER:ITER).EQ.'l').OR.
     +              (STRING(ITER:ITER).EQ.'m').OR.
     +              (STRING(ITER:ITER).EQ.'n').OR.
     +              (STRING(ITER:ITER).EQ.'o').OR.
     +              (STRING(ITER:ITER).EQ.'p').OR.
     +              (STRING(ITER:ITER).EQ.'q').OR.
     +              (STRING(ITER:ITER).EQ.'r').OR.
     +              (STRING(ITER:ITER).EQ.'s').OR.
     +              (STRING(ITER:ITER).EQ.'t').OR.
     +              (STRING(ITER:ITER).EQ.'u').OR.
     +              (STRING(ITER:ITER).EQ.'v').OR.
     +              (STRING(ITER:ITER).EQ.'w').OR.
     +              (STRING(ITER:ITER).EQ.'x').OR.
     +              (STRING(ITER:ITER).EQ.'y').OR.
     +              (STRING(ITER:ITER).EQ.'z')) THEN
                  LLETTER=.TRUE.
               END IF
            END IF
            IF (.NOT.LLETTER) THEN
               IF ((STRING(ITER:ITER).EQ.'1').OR.
     +              (STRING(ITER:ITER).EQ.'2').OR.
     +              (STRING(ITER:ITER).EQ.'3').OR.
     +              (STRING(ITER:ITER).EQ.'4').OR.
     +              (STRING(ITER:ITER).EQ.'5').OR.
     +              (STRING(ITER:ITER).EQ.'6').OR.
     +              (STRING(ITER:ITER).EQ.'7').OR.
     +              (STRING(ITER:ITER).EQ.'8').OR.
     +              (STRING(ITER:ITER).EQ.'9').OR.
     +              (STRING(ITER:ITER).EQ.'0').OR.
     +              (STRING(ITER:ITER).EQ.'.').OR.
     +              (STRING(ITER:ITER).EQ.'-').OR.
     +              (STRING(ITER:ITER).EQ.'_').OR.
     +              (STRING(ITER:ITER).EQ.'*')) THEN
                  LREST=.TRUE.
               END IF
            END IF
            IF (LLETTER.OR.LREST) THEN
               ICOUNT=ICOUNT+1
            ELSE
               LHELP=.FALSE.
            END IF
         END IF
      END DO
      FILENSTRING_ALPHANUMSEN=ICOUNT
      END
***** end of FILENSTRING_ALPHANUMSEN

***** ------------------------------------------------------------------
***** FCT FRMAX1
***** ------------------------------------------------------------------
C---- 
C---- NAME : FRMAX1
C---- ARG  : RVEC,IROW
C---- DES  : computes the maximal value of all elements of the real 
C---- DES  : vector RVEC(IROW): 
C---- DES  : result = max/i [RVEC(i)] 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: May,        1991        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
*     purpose:        computation of maximal value of the elements of  *
*                     a real vector                                    *
*     input parameter:IROW                                             *
*     input variables:RVEC                                             *
*     output:         result = max/j [ RVEC1(j)]                       *
C-----------------------------------------------------------------------
C-----------------------------------------------------------------------
*----------------------------------------------------------------------*
      REAL FUNCTION FRMAX1(RVEC,IROW)

      INTEGER         IROW
      REAL            RESULT
      REAL            RVEC(1:IROW)

      RESULT=0.
      DO ITER=1,IROW
         RESULT=MAX(RESULT,RVEC(ITER))
      END DO

      FRMAX1=RESULT

      END
***** end of FRMAX1

***** ------------------------------------------------------------------
***** FCT FRMAX2
***** ------------------------------------------------------------------
C---- 
C---- NAME : FRMAX2
C---- ARG  : RMAT,IROW,ICOL
C---- DES  : computes the maximal value of all elements of the real 
C---- DES  : matrix RMAT(IROW,ICOL): 
C---- DES  : result = max/i,j [RVEC(i,j)] 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1991        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
*     purpose:        computation of maximal value of the elements of  *
*                     a real matrix                                    *
*     input parameter:IROW, ICOL                                       *
*     input variables:RMAT                                             *
*     output:         result = max/i,j [ RMAT(i,j)]                    *
*----------------------------------------------------------------------*
      REAL FUNCTION FRMAX2(RMAT,IROW,ICOL)

      INTEGER         IROW,ICOL,ITROW,ITCOL
      REAL            RESULT,MAX
      REAL            RMAT(1:IROW,1:ICOL)

      RESULT=0.
      DO ITCOL=1,ICOL
         DO ITROW=1,IROW
            RESULT=MAX(RESULT,RMAT(ITROW,ITCOL))
         END DO
      END DO

      FRMAX2=RESULT

      END
***** end of FRMAX2




***** ------------------------------------------------------------------
***** SUB GETCHAR
***** ------------------------------------------------------------------
C---- 
C---- NAME : GETCHAR
C---- ARG  :  
C---- DES  : prompts for printable (keyboard) characters
C---- DES  : Caution: line with '$!' is truncated as comment
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE GETCHAR(KCHAR,CHARARR,CTEXT)

      LOGICAL EMPTYSTRING   
      CHARACTER*80 LINE
      CHARACTER*(*) CTEXT	
      CHARACTER CHARARR*(*)

      WRITE(*,*)
      WRITE(*,*)'================================================='//
     +	        '=============================='
      CALL WRITELINES(CTEXT)	
      IF(KCHAR.LT.1)THEN
         WRITE(*,*)'*** CHARPROMPT: illegal KCHAR',KCHAR
         RETURN
      ENDIF
 10   CONTINUE
      WRITE(*,*) 
      IF(KCHAR.GT.1) THEN
         WRITE(*,'(2X,''Enter letter string of length <'',I3)')KCHAR
      ELSE
         WRITE(*,'(2X,''Enter one letter !'')')
      ENDIF
      WRITE(*,'(2X,''[CR=default]: '')') 
      WRITE(*, '(2X,''Default: '',80A1)' ) (CHARARR(K:K),K=1,KCHAR)
      LINE=' '
      READ(*,'(A80)',ERR=10,END=11) LINE
      IF(.NOT.EMPTYSTRING(LINE)) THEN
C                    ! assuming default values were set outside ....
C...remove comments ( 34535345 !$ comment )
         KCOMMENT=INDEX(LINE,'!$')
         IF(KCOMMENT.NE.0) LINE(KCOMMENT:80)=' '
         DO I=1,80
***** ------------------------------------------------------------------
            IF (INDEX(' ABCDEFGHIJKLMNOPQRSTUVWXYZ',LINE(I:I)).EQ.
     +           0) THEN
               IF (INDEX(' abcdefghijklmnopqrstuvwxyz',LINE(I:I)).EQ.
     +              0) THEN
C              IF (INDEX('~!@#$%^&*()_+=-{}[]:""|\;,' ,LINE(I:I)).EQ.
                  IF (INDEX('~!@#$%^&*()_+=-{}[]:""|;,' ,LINE(I:I)).EQ.
     +                 0) THEN
                     IF (INDEX('.?/><1234567890            ',LINE(I:I)).
     +                    EQ.0) THEN
                        WRITE(*,
     +                       '(2X,''*** characters only, not: '',A40)')
     +                       LINE(1:40)
                        GO TO 10
                     ENDIF
                  ENDIF
               ENDIF
	    ENDIF
	 ENDDO
         READ(LINE,'(80A1)',ERR=10,END=99) (CHARARR(K:K),K=1,KCHAR)
      ENDIF
 11   WRITE(*,'(2X,A7,60A1)') ' echo: ', (CHARARR(K:K),K=1,KCHAR)
      RETURN
 99   WRITE(*,*)' CHARPROMPT: END OF LINE DURING READ - check format!'
      END
***** end of GETCHAR

***** ------------------------------------------------------------------
***** SUB GETINT
***** ------------------------------------------------------------------
C---- 
C---- NAME : GETINT
C---- ARG  :  
C---- DES  : For interactive use via terminal.
C---- DES  : Prompts for KINT integers from input unit *.
C---- DES  : Returns new values in INTNUM. 
C---- DES  : Offers previous values as default.
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
      SUBROUTINE GETINT(KINT,INTNUM,CTEXT)

      INTEGER LINELEN
      PARAMETER(LINELEN=80)

      CHARACTER*(LINELEN) LINE
      CHARACTER*(*) CTEXT	
      INTEGER INTNUM
      LOGICAL EMPTYSTRING
      INTEGER NUMSTART	
      CHARACTER*20 CTEMP

      WRITE(*,*)	
      WRITE(*,*)'===================================================='//
     +	        '==========================='
      CALL WRITELINES(CTEXT)	
      IF(KINT.LT.1.OR.KINT.GT.100) THEN
         WRITE(*,*)'*** INTPROMPT: KINT no good',KINT
         RETURN
      ENDIF
 10   WRITE(*,*)
      WRITE(*,'(2X,''Default: '',I10)') INTNUM
      IF(KINT.GT.1) THEN
         WRITE(*,'(2X,''Enter'',I3,'' integers [CR=default]: '')')KINT
      ELSE
         WRITE(*,'(2X,''Enter one integer  [CR=default]: '')')
      ENDIF
      LINE=' '
      READ(*,'(A80)',ERR=10,END=11) LINE
      IF(.NOT.EMPTYSTRING(LINE)) THEN
C...remove comments ( 34535345 !$ comment )
         KCOMMENT=INDEX(LINE,'  !$')
         IF(KCOMMENT.NE.0) LINE(KCOMMENT:linelen)=' '
C.. check for legal string
         DO I=1,linelen
            IF(INDEX(' ,+-0123456789',LINE(I:I)).EQ.0) THEN
               WRITE(*,'(2X,''*** not an integer: '',A40)') LINE(1:40)
               GO TO 10
            ENDIF
         ENDDO
         CALL StrPos(LINE,IStart,IStop)
C terminate line by comma for ND-100
C        LINE=LINE(1:IStop)//','
CUG        READ(LINE(IStart:IStop),'(i)',ERR=10,END=11)
Cug     +                          (INTNUM(K),K=1,KINT)
CUG      
         CALL GETTOKEN(LINE,LINELEN,1,NUMSTART,CTEMP)
         CALL RIGHTADJUST(CTEMP,20)
         READ(CTEMP,'(I20)') INTNUM
      ENDIF
 11   WRITE(*,'(2X,'' echo:'',I10)') INTNUM
      RETURN
      END
***** end of GETINT

***** ------------------------------------------------------------------
***** SUB GETTOKEN
***** ------------------------------------------------------------------
C---- 
C---- NAME : GETTOKEN
C---- ARG  :  
C---- DES  : returns the itokens token of cstring in ctoken. firstpos is
C---- DES  : position in cstring at which substring ctoken starts
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE GETTOKEN(CSTRING,LEN,ITOKEN,FIRSTPOS,CTOKEN)

c	Implicit None
C Import
      INTEGER LEN, ITOKEN
      CHARACTER*(*) CSTRING
C Export
      INTEGER FIRSTPOS
      CHARACTER*(*) CTOKEN
C Internal
      INTEGER IPOS, THISTOKEN, TPOS
      LOGICAL FINISHED, INSIDE

      CTOKEN = ' '
      TPOS = 0
      FINISHED = .FALSE.
      IF ( CSTRING(1:1) .EQ. ' ' ) THEN
         THISTOKEN = 0
         INSIDE = .FALSE.
      ELSE
         THISTOKEN = 1
         INSIDE = .TRUE.
         FIRSTPOS = 1
         IF ( THISTOKEN .EQ. ITOKEN ) THEN
            TPOS = TPOS + 1
            CTOKEN(TPOS:TPOS) = CSTRING(1:1)
         ENDIF
      ENDIF
      IPOS = 2
      DO WHILE ( IPOS .LE. LEN .AND. .NOT. FINISHED )
         IF ( CSTRING(IPOS:IPOS) .EQ. ' ' ) THEN
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

      RETURN
      END
***** end of GETTOKEN

***** ------------------------------------------------------------------
***** SUB GET_ARGUMENT
***** ------------------------------------------------------------------
C---- 
C---- NAME : GET_ARGUMENT
C---- ARG  : NUMBER,ARGUMENT
C---- DES  : returns the content of x-th argument
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE GET_ARGUMENT(INUMBER,ARGUMENT)
      CHARACTER*(*) ARGUMENT
      INTEGER INUMBER

      CALL GETARG(INUMBER,ARGUMENT)
      RETURN 
      END
***** end of GET_ARGUMENT

***** ------------------------------------------------------------------
***** SUB GET_ARG_NUMBER
***** ------------------------------------------------------------------
C---- 
C---- NAME : GET_ARG_NUMBER
C---- ARG  : INUMBER
C---- DES  : returns number of arguments
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE GET_ARG_NUMBER(INUMBER)
      INTEGER INUMBER,IARGC
    
      INUMBER=0
      INUMBER=IARGC()
      RETURN 
      END
***** end of GET_ARG_NUMBER

***** ------------------------------------------------------------------
***** SUB RightADJUST
***** ------------------------------------------------------------------
C---- 
C---- NAME : RightADJUST
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RightADJUST(STRING,NLEN)

      CHARACTER*(*)  STRING
      INTEGER        NLEN

C...find position of last non-blank
      IF (NLEN.LT.1)  RETURN
      L=NLEN
      DO WHILE(STRING(L:L).EQ.' '.AND.L.GT.1)
         L=L-1
      ENDDO
      IF (L.LT.NLEN) THEN
C..L is position of last non-blank
         STRING(NLEN-L+1:NLEN)=STRING(1:L)
C.C..fill rest with blanks from 1 to NLEN-L
         DO IL=1,NLEN-L
            STRING(IL:IL)=' '
         ENDDO
      ENDIF
      RETURN
      END
***** end of RIGHTADJUST

***** ------------------------------------------------------------------
***** SUB SCFDATE
***** ------------------------------------------------------------------
C---- 
C---- NAME : SCFDATE
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Dec,        1991        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE SCFDATE(CALL,LOGIWRITE,DATEOLD)

      IMPLICIT         NONE

      CHARACTER*24     FDATE,ACTDATE,DATEOLD
      INTEGER          CALL,ITER
      LOGICAL          LOGIWRITE

C      ACTDATE=FDATE()
      ACTDATE=FDATE

      IF (LOGIWRITE) THEN
         WRITE(6,*)
         WRITE(6,'(T10,7A5)')('-----',ITER=1,7)
         WRITE(6,*)
         IF (CALL.EQ.2) THEN
            WRITE(6,'(T10,A11,A24)')'started:   ',DATEOLD
            WRITE(6,'(T10,A11,A24)')'  ended:   ',ACTDATE
         ELSE
            WRITE(6,'(T10,A11,A24)')'   time:   ',ACTDATE
         END IF
         WRITE(6,*)
         WRITE(6,'(T10,7A5)')('-----',ITER=1,7)
         WRITE(6,*)
      END IF
      IF (CALL.EQ.1) THEN
         DATEOLD=ACTDATE
      END IF

      END
***** end of SCFDATE

***** ------------------------------------------------------------------
***** SUB SFILEOPEN
***** ------------------------------------------------------------------
C---- 
C---- NAME : SFILEOPEN
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Dec,        1991        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE SFILEOPEN(UNIT,FILENAME,ACTSTATUS,LENGTH,ACTTASK)

      IMPLICIT     NONE

C---- local function
      INTEGER      FILEN_STRING

C---- local variables
      INTEGER      UNIT,LENGTH,IEND
      CHARACTER*(*) FILENAME,ACTSTATUS,ACTTASK
      CHARACTER*132 CHFILE
******------------------------------*-----------------------------******

C     purge blanks from file name
      IEND=FILEN_STRING(FILENAME)
      CHFILE(1:IEND)=FILENAME(1:IEND)

C      OPEN(UNIT,FILE=FILENAME,STATUS=ACTSTATUS)
      OPEN(UNIT,FILE=CHFILE(1:IEND),STATUS=ACTSTATUS)

C---- bullshit to avoid warnings
      IF (ACTTASK.EQ.'XX') THEN
         CONTINUE
      END IF
      IF (LENGTH.LT.1) THEN
         CONTINUE
      END IF

      RETURN
      END
***** end of SFILEOPEN

***** ------------------------------------------------------------------
***** SUB SCHAR_TO_INT
***** ------------------------------------------------------------------
C---- 
C---- NAME : SCHAR_TO_INT
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Mar,        1993        version 0.1    *
*                      changed: Apr,        1993        version 0.2    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
*     purpose:        The character CHAR is converted to an integer.   *
*     in variables:   CHAR                                             *
*     out variables:  INUM                                             *
*     SBRs calling:  from lib-comp.f:                                 *
*     --------------     SILEN_STRING(STRING,IBEG,IEND)                *
*     procedure:      be careful '-1' or 'a1' might produce errors     *
*     ----------      
*----------------------------------------------------------------------*
      SUBROUTINE SCHAR_TO_INT(CHAR,INUM)
      IMPLICIT        NONE
C---- variables passed
      INTEGER         INUM
      CHARACTER       CHAR*(*)
C---- local variables                                                  *
      INTEGER         ITER,ITER2,IBEG,IEND,ILEN,SUM,PROD
******------------------------------*-----------------------------******

C---- defaults
C---- determine non-blank length of character CHAR
C     =================
      CALL SILEN_STRING(CHAR,IBEG,IEND)
C     =================
      ILEN=IEND-IBEG+1
C---- loop over length:
      SUM=0
      DO ITER=1,ILEN
         PROD=1
         DO ITER2=1,(ILEN-ITER)
            PROD=10*PROD
         END DO
         IF (CHAR(ITER:ITER).EQ.'1') THEN
            SUM=SUM+PROD
         ELSEIF (CHAR(ITER:ITER).EQ.'2') THEN
            SUM=SUM+PROD*2
         ELSEIF (CHAR(ITER:ITER).EQ.'3') THEN
            SUM=SUM+PROD*3
         ELSEIF (CHAR(ITER:ITER).EQ.'4') THEN
            SUM=SUM+PROD*4
         ELSEIF (CHAR(ITER:ITER).EQ.'5') THEN
            SUM=SUM+PROD*5
         ELSEIF (CHAR(ITER:ITER).EQ.'6') THEN
            SUM=SUM+PROD*6
         ELSEIF (CHAR(ITER:ITER).EQ.'7') THEN
            SUM=SUM+PROD*7
         ELSEIF (CHAR(ITER:ITER).EQ.'8') THEN
            SUM=SUM+PROD*8
         ELSEIF (CHAR(ITER:ITER).EQ.'9') THEN
            SUM=SUM+PROD*9
         END IF
      END DO
      INUM=SUM
      END 
***** end of SCHAR_TO_INT

***** ------------------------------------------------------------------
***** SUB SILEN_STRING
***** ------------------------------------------------------------------
C---- 
C---- NAME : SILEN_STRING
C---- ARG  :  
C---- DES  :   
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Feb,        1993        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
*     purpose:        The length of a given character string is returned
*     --------        resp. non-blank begin (ibeg) and end (iend)      *
*     input:          STRING     string of character*80                *
*     output:         ibeg,iend                                        *
*----------------------------------------------------------------------*
      SUBROUTINE SILEN_STRING(STRING,IBEG,IEND)
C---- variables passing
      CHARACTER       STRING*(*)
C---- local variables
      INTEGER         ICOUNT,ITER,IBEG,IEND
      CHARACTER*80    HSTRING
      LOGICAL         LHELP
******------------------------------*-----------------------------******
C---- defaults
      HSTRING=STRING
      ICOUNT=0
      LHELP=.TRUE.
      DO ITER=1,80
         IF (LHELP) THEN
            IF (HSTRING(ITER:ITER).NE.' ') THEN
               IF (ICOUNT.EQ.0) THEN
                  IBEG=ITER
               END IF
               ICOUNT=ICOUNT+1
            ELSE
               IF (ICOUNT.NE.0) THEN
                  IEND=ITER-1
                  LHELP=.FALSE.
               END IF
            END IF
         END IF
      END DO
      IF (ICOUNT.EQ.0) THEN
         WRITE(6,'(T2,A,T10,A,A1,A,A1)')'***',
     +        'ERROR: Sbr SILEN_STRING: empty string:','|',STRING,'|'
      END IF
      END
***** end of SILEN_STRING

***** ------------------------------------------------------------------
***** SUB SRSTE2
***** ------------------------------------------------------------------
C---- 
C---- NAME : SRSTE2
C---- ARG  : RMAT1,RMAT2,IROW,ICOL
C---- DES  : sets real matrix RMAT1(IROW,ICOL)=
C---- DES  : real matrix RMAT2(IROW,ICOL) 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Mar,        1991        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
C     purpose: the 2-dimensional real matrix RMAT1(rows,columns) is set*
C              equal to the 2-D real one RMAT2                         *
C     input parameter:  IROW,ICOL                                      *
C     input variables:  RMAT1(real matrix) , RMAT2                     *
C     output variables: RMAT1(i,j)=RMAT2(i,j) for all i,j              *
*----------------------------------------------------------------------*
      SUBROUTINE SRSTE2(RMAT1,RMAT2,IROW,ICOL)

      REAL       RMAT1(1:IROW,1:ICOL)
      REAL       RMAT2(1:IROW,1:ICOL)
      DO ITER2=1,ICOL
         DO ITER1=1,IROW
            RMAT1(ITER1,ITER2)=RMAT2(ITER1,ITER2)
         END DO
      END DO
      END
***** end of SRSTE2

***** ------------------------------------------------------------------
***** SUB SRSTZ2
***** ------------------------------------------------------------------
C---- 
C---- NAME : SRSTZ2
C---- ARG  : RMAT,IROW,ICOL
C---- DES  : Sets zero a 2-dimensional real matrix with the 
C---- DES  : row-length 
C---- DES  : IROW, the column-length ICOL :RMAT(IROW,ICOL) 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Mar,        1991        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
C     purpose: a real two dimensional matrix RMAT(rows,columns) is set *
C              to zero                                                 *
C     input parameter:  IROW,ICOL                                      *
C     input variables:  RMAT(real matrix)                              *
C     output variables: RMAT=0. for all elements                       *
*----------------------------------------------------------------------*
      SUBROUTINE SRSTZ2(RMAT,IROW,ICOL)

      REAL       RMAT(1:IROW,1:ICOL)
      DO ITER2=1,ICOL
         DO ITER1=1,IROW
            RMAT(ITER1,ITER2)=0.
         END DO
      END DO
      END
***** end of SRSTZ2

***** ------------------------------------------------------------------
***** SUB StrPos
***** ------------------------------------------------------------------
C---- 
C---- NAME : StrPos
C---- ARG  :  
C---- DES  : StrPos(Source,IStart,IStop): Finds the positions of the 
C---- DES  : first and last non-blank/non-TAB in Source. 
C---- DES  : IStart=IStop=0 for empty Source
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE StrPos(Source,IStart,IStop)

      CHARACTER*(*) Source
      INTEGER ISTART,ISTOP

      ISTART=0
      ISTOP=0
      DO J=1,LEN(SOURCE)
         IF(SOURCE(J:J).NE.' ')THEN
            ISTART=J
            GOTO 20
         ENDIF
      ENDDO
      RETURN
 20   DO J=LEN(SOURCE),1,-1
         IF(SOURCE(J:J).NE.' ')THEN
            ISTOP=J
            RETURN
         ENDIF
      ENDDO
      ISTART=0
      ISTOP=0
      RETURN
      END
***** end of STRPOS

***** ------------------------------------------------------------------
***** SUB WRITELINES
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRITELINES
C---- ARG  :  
C---- DES  : if 'cstring' contains '/n' (new line) this routine writes
C---- DES  : cstring line by line on screen; called by GETINT,GETREAL..
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     EMBL/LION                 http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg        rost@embl-heidelberg.de                *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRITELINES(CSTRING)
	
      CHARACTER*(*) CSTRING
      INTEGER ICUTBEGIN(10),ICUTEND(10)

      CALL StrPos(CSTRING,ISTART,ISTOP)
      ILINE=1
      ICUTBEGIN(ILINE)=1
      ICUTEND(ILINE)=ISTOP

      DO I=1,ISTOP-1
         IF(CSTRING(I:I+1).EQ.'/n')THEN
            ILINE=ILINE+1
            ICUTBEGIN(ILINE)=I+2
            ICUTEND(ILINE-1)=I-1
            ICUTEND(ILINE)=ISTOP
         ENDIF
      ENDDO
      DO I=1,ILINE
         WRITE(*,*)CSTRING(ICUTBEGIN(I):ICUTEND(I))
      ENDDO
      RETURN
      END
***** end of WRITELINES

