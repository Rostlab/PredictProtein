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
         write(*,*)' WARNING: in concat_strings: length overflow'
         write(*,*)'          cut string at: ',ilen
      ENDIF
      RESULT(1:ILEN)=STRING1(IBEG:IEND)//STRING2(JBEG:JEND)
      RETURN
      END
C     END CONCAT_STRINGS
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
            write(*,*)' ERROR in CONCAT_INT_STRING: update plus'
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
            write(*,*)' ERROR in CONCAT_INT_STRING: update minus'
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
         write(*,*)' WARNING: in concat_int_string: length overflow'
         write(*,*)'          cut string at: ',ilen
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
            write(*,*)' ERROR in CONCAT_STRING_INT: update plus'
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
            write(*,*)' ERROR in CONCAT_STRING_INT: update minus'
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
         write(*,*)' WARNING: in concat_int_string: length overflow'
         write(*,*)'          cut string at: ',ilen
      ENDIF
      RESULT(1:ILEN)=STRING(JBEG:JEND)//TEMP(IBEG:IEND)
      RETURN
      END
C     END CONCAT_STRING_INT
C......................................................................

C......................................................................
C     SUBR DEL_OLDFILE
      SUBROUTINE DEL_OLDFILE(IUNIT,FILENAME)
      CHARACTER*(*) FILENAME
      INTEGER IUNIT
      LOGICAL LEXIST,LOPEN
      INTEGER IBEG,IEND
      CHARACTER*100 TEMPNAME
      
      TEMPNAME=' '
      CALL STRPOS(FILENAME,IBEG,IEND)
      TEMPNAME(1:)=FILENAME(IBEG:IEND)
      INQUIRE(FILE=TEMPNAME,OPENED=LOPEN)
      IF (LOPEN) THEN
         CLOSE(IUNIT)
      ENDIF
      INQUIRE(FILE=TEMPNAME,EXIST=LEXIST)
      IF (LEXIST) THEN
         OPEN(IUNIT,FILE=TEMPNAME,STATUS='OLD')
         CLOSE(IUNIT,STATUS='DELETE')
      ENDIF
      RETURN
      END
C     END DEL_OLDFILE
C......................................................................

C......................................................................
C     SUB FLUSH_unit
      SUBROUTINE FLUSH_UNIT(IUNIT)
      INTEGER IUNIT
      
      CALL FLUSH(IUNIT)
      
      RETURN
      END
C     END FLUSH
C......................................................................

C......................................................................
C     SUB GET_ARG_NUMBER  
C     returns number of arguments
C     UNIX version
      SUBROUTINE GET_ARG_NUMBER(INUMBER)
      INTEGER INUMBER

      INUMBER=0
      INUMBER=IARGC()
      RETURN 
      END
C     END GET_ARG_NUMBER
C......................................................................

C......................................................................
C     SUB GET_ARGUMENT  
C     returns the content of x-th argument
C     UNIX version
      SUBROUTINE GET_ARGUMENT(INUMBER,ARGUMENT)
      CHARACTER*(*) ARGUMENT
      INTEGER INUMBER

      CALL GETARG(INUMBER,ARGUMENT)
      RETURN 
      END
C     END GET_ARGUMENT
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
      write(*,'(a,a)')' GETSIMMATRIX open metric: ',simfile(1:50)
      CALL OPEN_FILE(KSIM,SIMFILE,'READONLY,OLD',LERROR)
      IF (LERROR) GOTO 99
C----------------------------------------------------------------------
      DO WHILE (INDEX(LINE,TESTSTRING).EQ.0)
         READ(KSIM,'(A)',END=99)LINE          
         IF (INDEX(LINE,'STRUCTURE-STATES_1:') .NE. 0) THEN
            I=INDEX(LINE,':')+1
            CALL STRPOS(LINE,IBEG,IEND)
            CALL READ_INT_FROM_STRING(LINE(I:IEND),NSTRSTATES_1)
         ELSEIF (INDEX(LINE,'STRUCTURE-STATES_2:') .NE. 0) THEN
            I=INDEX(LINE,':')+1
            CALL STRPOS(LINE,IBEG,IEND)
            CALL READ_INT_FROM_STRING(LINE(I:IEND),NSTRSTATES_2)
         ELSEIF (INDEX(LINE,'I/O-STATES_1:') .NE. 0) THEN
            I=INDEX(LINE,':')+1
            CALL STRPOS(LINE,IBEG,IEND)
            CALL READ_INT_FROM_STRING(LINE(I:IEND),NIOSTATES_1)
         ELSEIF (INDEX(LINE,'I/O-STATES_2:') .NE. 0) THEN
            I=INDEX(LINE,':')+1
            CALL STRPOS(LINE,IBEG,IEND)
            CALL READ_INT_FROM_STRING(LINE(I:IEND),NIOSTATES_2)
         ELSEIF (INDEX(LINE,'DSSP-STRUCTURE') .NE. 0) THEN
            DO I=1,NSTRSTATES_1
               DO J=1,NIOSTATES_1
                  READ(KSIM,'(A)')LINE
                  READ(LINE,'(4X,A1,13X,A1)')CSTR,CIO
                  K=INDEX(CSTRSTATES,CSTR)
                  IF (K.EQ.0) THEN
	             NSTR=NSTR+1
	             K=NSTR
	             IF (NSTR .GT. MAXSTRSTATES) THEN
                        write(*,*)'*** ERROR: struct-states overflow'
                        STOP
	             ENDIF
                     CALL STRPOS(CSTRSTATES,IBEG,IEND)
	             IF (IEND+1 .GT. LEN(CSTRSTATES)) THEN
                        write(*,*)
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
                        write(*,*)'*** ERROR: I/O-states overflow'
                        STOP           
	             ENDIF
                     CALL STRPOS(CIOSTATES,IBEG,IEND)
	             IF (IEND+1 .GT. LEN(CSTRSTATES)) THEN
                        write(*,*)
     +                       '*** ERROR: CIOSTATES string too short'
                        STOP           
	             ENDIF
	             WRITE(CIOSTATES(IEND+1:IEND+1),'(A1)')CIO
                  ENDIF
                  READ(LINE,'(26X,F3.0)')IORANGE(K,L)
               ENDDO
            ENDDO
         ENDIF
      ENDDO
C----------------------------------------------------------------------
      write(*,*)' STRUCTURE-STATES_1: ',cstrstates,nstrstates_1
      write(*,*)' I/O-STATES_1      : ',ciostates,niostates_1
      write(*,*)' STRUCTURE-STATES_2: ',cstrstates,nstrstates_2
      write(*,*)' I/O-STATES_2      : ',ciostates,niostates_2
      IF (NSTRSTATES_1 .EQ. 1)NSTR=1
      IF (NIOSTATES_1  .EQ. 1)NIO=1
      IF (NSTR .NE. NSTRSTATES_1 .OR. NIO .NE. NIOSTATES_1 ) THEN
         write(*,*)'*** ERROR: number of structure-states .ne. NSTR'
         write(*,*)'    OR     number of I/O-states       .ne. NIO'
         STOP                                               
      ENDIF
C----------------------------------------------------------------------
      DO WHILE (.TRUE.)
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
         write(*,*)' *** ERROR: CTRANS from metric-file and TRANS'//
     +        ' are not the same'
         write(*,*)'GETSIMMATRIX: ',ctrans,itrans
         write(*,*)'GETSIMMATRIX: ',trans,ntrans
         STOP                            
      ENDIF

C=======================================================================
C debug
C=======================================================================
c	do istr1=1,nstrstates_1
c	   do io1=1,niostates_1
c	      do istr2=1,nstrstates_2
c	         do io2=1,niostates_2
c                  write(*,*)(simmetric(1,j,istr1,io1,istr2,io2),j=1,26)
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
      write(*,'(a)')
     +     '** ERROR reading metric in GETSIMMATRIX **'
      STOP
      END
***** end of GETSIMMETRIC
C     END GETSIMMETRIC
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
***** end of INIT_REAL_ARRAY
C     END INIT_REAL_ARRAY
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
	    WRITE(*,*)' *** NOT AN INTEGER:',CSTRING(ISTART:ISTOP)
         ENDIF
      ENDDO
      CALL CONCAT_STRING_INT('(I',ITOTAL,CTEMP)
      CALL CONCAT_STRINGS(CTEMP,')',CFORMAT)
      READ(CSTRING(ISTART:ISTOP),CFORMAT)INUMBER
      RETURN
      END
***** end of READ_INT_FROM_STRING
C     END READ_INT_FROM_STRING
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
***** end of STRPOS
C     END STRPOS
C......................................................................


