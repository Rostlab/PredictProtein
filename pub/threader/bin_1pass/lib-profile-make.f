C......................................................................
C     FUN EMPTYSTRING(STRING)
      FUNCTION EMPTYSTRING(STRING)
      LOGICAL EMPTYSTRING
      CHARACTER*(*) STRING
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
      IMPLICIT NONE
C import
      INTEGER NTRANS
      CHARACTER*(*) TRANS
      INTEGER MAXSTRSTATES,MAXIOSTATES
      INTEGER NSTRSTATES,NIOSTATES
      REAL IORANGE(MAXSTRSTATES,MAXIOSTATES)
      INTEGER NRES,NACC(*),LSQ(*),LSTR(*)
C export
      INTEGER LACC(*)
C internal
      INTEGER MAXAA
      PARAMETER (MAXAA=26)
      INTEGER ACCMAX(MAXAA)
      INTEGER I,IOSTATE,ISTR
      REAL PER
C max. Acc. in order of TRANS (VLIMFWYGAPSTCHRKQENDBZX!-.)
C  V   L   I   M   F   W   Y   G  A   P   S   T
C 142,164,169,188,197,227,222,84,106,136,130,142
C  C   H   R   K   Q   E   N   D   B   Z  X ! - .
C 135,184,248,205,198,194,157,163,157,194,0,0,0 0
      DATA ACCMAX /142,164,169,188,197,227,222,84,106,136,130,142,
     +     135,184,248,205,198,194,157,163,157,194,0,0,0,0/

      IF (TRANS .NE. 'VLIMFWYGAPSTCHRKQENDBZX!-.' ) THEN
         write(*,*)'*** ERROR: TRANS NOT IN RIGHT ORDER in ACC_TO_INT'
         STOP
      ENDIF
      IF (NTRANS .GT. MAXAA) THEN
         WRITE(*,*)'*** ERROR: NTRANS .GT. MAXAA IN ACC_TO_INT'
         STOP
      ENDIF

      IF (NIOSTATES .EQ. 1) THEN
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
	       write(*,*)'*** ERROR: LSTR .EQ. 0 IN ACC_TO_INT'
	       STOP
            ENDIF
            
            IF (ACCMAX(LSQ(I)) .NE. 0) THEN
	       PER=(NACC(I)*100.0) / ACCMAX(LSQ(I))
	       IF (PER .GE. 100.0)PER=100.0
	       IOSTATE=1
	       DO IOSTATE=1,NIOSTATES
	          IF (PER .LE. IORANGE(ISTR,IOSTATE) ) THEN
                     LACC(I)=IOSTATE
                     GOTO 100
                  ENDIF
               ENDDO
            ELSE
               LACC(I)=1
            ENDIF
 100        CONTINUE
c100	     if (i .le. 10) then  
c                write(*,*)' acctoint I,LSTR,LACC : ',i,iSTR,
c     +                 lacc(i)
c                write(*,*)accmax(lsq(i)),nacc(i),per
c	     endif
         ENDIF
      ENDDO
      RETURN
      END
C     END ACC_TO_INT
C......................................................................

C......................................................................
C     SUB CHARARRAYREPL
C replaces all occurences of c1 by c2
C Import
C Import/Export
C Internal
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
         WRITE(*,*)' open file error in CHECKFORMAT'
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
         IF (INDEX(LINE,'PROGRAM DSSP,').NE.0) THEN
            FORMATNAME='DSSP'
            GOTO 99
         ELSE IF (INDEX(LINE,'-PROFILE').NE.0) THEN
            FORMATNAME='PROFILE'
            IF (INDEX(LINE,'SECONDARY').NE.0) THEN
               FORMATNAME='PROFILE-DSSP'
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
C     SUB CHECKRANGE
      SUBROUTINE CHECKRANGE(N,NLOWER,NUPPER,VARIABLE,ROUTINE)
      CHARACTER*(*) ROUTINE, VARIABLE
      IF (N.LT.NLOWER.OR.N.GT.NUPPER ) THEN
         write(*,*)'*** fatal error in ',routine
         write(*,*) ' integer ',variable,' out of range '
         write(*,*) ' legal limits are: ',nlower, nupper
         write(*,*) ' current value is: ',n
         STOP 'in CHECKRANGE'
      ENDIF
      RETURN
      END
C     END CHECKRANGE
C......................................................................

C......................................................................
C     SUB CHECKREALEQUALITY
      SUBROUTINE CHECKREALEQUALITY(X1,X2,EPSILON,VARIABLE,ROUTINE)

      CHARACTER*(*) ROUTINE, VARIABLE
      REAL X1,X2,EPSILON

      IF (EPSILON .LT. 0.0) THEN
         write(*,*)' *** negative epsilon in checkrealequality'
      ENDIF
      IF (ABS(X1-X2) .GT. EPSILON) THEN
         write(*,*)'*** fatal error in ',routine
         write(*,*)' real nums ',variable,' are not eq within',epsilon
         write(*,*)' values are: ',x1,x2
         STOP 'IN CHECKREALEQUALITY'
      ENDIF
      RETURN
      END
***** end of CHECKREALEQUALITY

C     END CHECKREALEQUALITY
C......................................................................

C......................................................................
C     SUB CHECKSEQ
      SUBROUTINE CHECKSEQ(STRAND,BEGIN,END,CHECK)

      IMPLICIT NONE

C     sbr version of gcg function CheckSeq 18
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
            WRITE(*,'(A,A,A)')
     +           'ERROR IN EXTRACT_INTEGER: no ',cdivide,'in line'
	    STOP
         ENDIF
         CALL STRPOS(LINE(IBEG+1:J),I,J)
         CALL READ_INT_FROM_STRING(LINE(IBEG+I:IBEG+J),INTVAL)
c          write(*,'(A,A,I6)')line(1:lenkey),' is: ',intval
      ENDIF
      RETURN
      END
C     END EXTRACT_INTEGER
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
         write(*,'(A,A,A,A)')
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
            WRITE(*,'(A,A,A)')
     +           'ERROR IN EXTRACT_REAL: no ',cdivide,'in line'
	    STOP
         ENDIF
         CALL STRPOS(LINE(IBEG+1:J),I,J)
         CALL READ_REAL_FROM_STRING(LINE(IBEG+I:IBEG+J),REALVAL)
c          write(*,'(A,A,F7.2)')line(1:lenkey),' is: ',realval
      ENDIF
      RETURN
      END
C     END EXTRACT_REAL
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
            WRITE(*,'(A,A,A)')
     +           'ERROR IN EXTRACT_STRING: no ',CDIVIDE,'in line'
	    STOP
         ENDIF
         IF (J .GT. IBEG+1) THEN
	    CALL STRPOS(LINE(IBEG+1:J),I,J)
            STRING=LINE(IBEG+I:IBEG+J)
         ELSE
	    STRING=' '
         ENDIF
c          WRITE(*,*)LINE(1:LENKEY)//' is: '//LINE(IBEG+I:IBEG+J)
      ENDIF
      RETURN
      END
C     END EXTRACT_STRING
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
      IF (NSTRSTATES_2 .GT. 1) THEN
         write(*,*)' **** ERROR: nstrstates_2 .gt. 1'
         write(*,*)' not possible to fill position dependend metric'
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
               write(*,*)'fillsimmetric: lseq unknown: ',lseq(i)
               POSSIMMETRIC(I,J)=0.0
            ENDDO
         ELSE
            DO J=1,NTRANS
c	      write(*,'(a)')'fill i,j,lseq,lstr,lacc: '
c              write(*,'(5(i4))')i,j,lseq(i),istr,lacc(i)
               POSSIMMETRIC(I,J)=SIMMETRIC(LSEQ(I),J,ISTR,LACC(I),1,1)
            ENDDO
         ENDIF
      ENDDO
      RETURN
      END
C     END FILLSIMMETRIC
C......................................................................

C......................................................................
C     SUB GETARRAYINDEX
      SUBROUTINE GETARRAYINDEX(CARRAY,CTESTSTRING,NELEM,IINDEX)

      IMPLICIT NONE
C returns iindex with carray(iindex) = cteststring, or 0, if carray
C does not contain cteststring 
C Import
      INTEGER NELEM
      CHARACTER*(*) CARRAY(NELEM)
      CHARACTER*(*) CTESTSTRING
C     INTERNAL
      INTEGER IINDEX
      
      IINDEX = 1
      DO WHILE (IINDEX .LE. NELEM .AND. 
     1     CARRAY(IINDEX) .NE. CTESTSTRING)
         IINDEX = IINDEX + 1
      ENDDO
      IF ( IINDEX .EQ. NELEM+1 ) IINDEX = 0

      RETURN
      END
C     END GETARRAYINDEX
C......................................................................

C......................................................................
C     SUB GETCHAR
      SUBROUTINE GETCHAR(KCHAR,CHARARR,CTEXT)
C prompts for characters
      CHARACTER*(*) CTEXT,CHARARR
      CHARACTER*100 LINE
      INTEGER IMAX

      IMAX=LEN(CHARARR)
      WRITE(*,*)'================================================='//
     +     '=============================='
      CALL WRITELINES(CTEXT)	
 10   CONTINUE
      WRITE(*,*) 
      write(*,'(a,i3,a)')'  Enter string of length < ',imax,
     +                       '  [CR=default]'
      WRITE(*,*)'   '
      CALL STRPOS(CHARARR,IBEG,IEND)
      IF (IBEG .GT. 0 .AND. IEND .GT. 0) THEN
         write(*,'(a,a)')'  Default:  ',chararr(ibeg:iend)
      ELSE
         write(*,'(a,a)')'  Default:  ',chararr
      ENDIF
      WRITE(*,*)' '
      LINE=' '
      READ(*,'(A)',ERR=10,END=11) LINE
      IF ( LINE .NE. ' ' ) THEN
C assuming default values were set outside ....
         CALL STRPOS(LINE,IBEG,IEND)
c	  do i=1,iend
c	     iascii=ichar(line(i:i))
c	     if (iascii .lt. 32 .or. iascii .gt. 126) then
c               write(*,*)'*** Characters only, NOT: ',line(1:iend)
c               GOTO 10
c	     endif
c	  enddo
c	  iend=min(iend,imax)
         CHARARR(1:)=LINE(1:IEND)
      ENDIF
 11   write(*,'(a,a)')'   echo: ',chararr(1:iend)
      RETURN
      END
C     END GETCHAR
C......................................................................

C......................................................................
C     SUB GETDSSPFORHSSP
      SUBROUTINE GETDSSPFORHSSP(IN,FILE,MAXSQ,CHAINREMARK,PROT,
     +     HEAD,COMP,SOURCE,AUTHOR,NRES,LRES,NCHAIN,KCHAIN,PDBNO,
     +     PDBCHAINID,PDBSEQ,SECSTR,COLS,BP1,BP2,SHEETLABEL,ACC)

c reads header etc from files of type dssp. modified getdssp rs dez 88.
c reads dssp-data as line of length 38  (no h-bond-data)
      INTEGER IN,MAXSQ
      CHARACTER*(*) FILE,PROT,COMP,HEAD,SOURCE,AUTHOR,CHAINREMARK
      CHARACTER     PDBSEQ(*)
      CHARACTER*(*) PDBCHAINID(*),SECSTR(*)
      CHARACTER*1   SHEETLABEL(*)
C     LENGHT*7
      CHARACTER*7 COLS(*)
      INTEGER PDBNO(*),BP1(*),BP2(*),ACC(*)
C     INTERNAL
      PARAMETER (MAXCHAIN=100)
      CHARACTER CHAINMODE*20,CHAINID(MAXCHAIN)
      CHARACTER LINE*132,TEMPNAME*124
      LOGICAL ERRFLAG,LKEEP,LCHAIN(MAXCHAIN)
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
         READ(IN,'(A132)',END=777,ERR=999) LINE
      ENDDO
      PROT=LINE(63:66)
      PROT=LINE(63:66)
      HEAD=LINE(11:50)
      READ(IN,'(A132)',END=777,ERR=999)LINE
      COMP=LINE(11:)
      READ(IN,'(A132)',END=777,ERR=999)LINE
      SOURCE=LINE(11:)
      READ(IN,'(A132)',END=777,ERR=999)LINE
      AUTHOR=LINE(11:)
C...........FIND SEQUENCE.........
 70   READ(IN,'(A132)',END=777,ERR=999)LINE
      IF (INDEX(LINE(1:5),'#').EQ.0) GOTO 70
CD	WRITE(*,*)' # found sequence '
C............READ STRUCTURE.........
C...:....1....:....2....:....3....:...
C #  RESIDUE AA STRUCTURE BP1 BP2  ACC  
C  22   36 A S  E >   -I   24   0C  60  
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
c	   WRITE(*,*)' WILL READ CHAINS ACCORDING TO CHARACTER'

         ISTART=INDEX(CHAINREMARK,'!')+2
         DO J=1,NSELECT
            READ(CHAINREMARK(ISTART:),'(A1)')CHAINID(J)
            CALL LOWTOUP(CHAINID(J),1)
            ISTART=ISTART+2
         ENDDO
c	   WRITE(*,*)' GETDSSPFORHSSP: extract the chain(s)'
c	   DO J=1,NSELECT
c	        WRITE(*,*)' CHAIN: ',CHAINID(J)
c	   ENDDO
      ELSE
         CHAINMODE='NONE'
         IF (KCHAIN.NE.0) THEN
            WRITE(*,*)' will extract chain number: ',KCHAIN	
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
c	WRITE(*,*) NRES,' RESIDUES READ IN GETDSSPFORHSSP '
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
c	WRITE(*,*) LRES,' RESIDUES ',NRES,' POSITIONS '
      CLOSE(IN)
      RETURN
 999  WRITE(*,*)' *** READ ERROR ***'
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
C     SUB GETINDEX
      SUBROUTINE GETINDEX(CTEST,STRINGPOS,IPOS)
C get index of ctest in cstring
      INTEGER STRINGPOS(*),IPOS
      CHARACTER CTEST

      I=ICHAR(CTEST)
      IPOS=STRINGPOS(I)
c	if (ipos .eq. 0) then
c	  write(*,*)' WARNING: UNKNOWN character: ',ctest
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
      PID=' '
      TEMPNAME=' '

      CALL STRPOS(FILENAME,ISTART,IEND)
      IF (IEND .GT. LEN(TEMPNAME)) THEN
         write(*,*)' ERROR in GETPIDCODE'
         write(*,*)' tempname variable too short'
         STOP
      ENDIF

      TEMPNAME(1:IEND)=FILENAME(1:IEND)	
      CALL LOWTOUP(TEMPNAME,IEND)	
      NAME=FILENAME(ISTART:IEND)
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
c	   write(*,*)' ERROR in GETPIDCODE'
c	   write(*,*)' pid variable too short'
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
     +     LDSSP,FILENAME,COMPND,ACCNUM,CDUMMY,IOP,TRANS,NTRANS,KCHAIN,
     +	   NCHAIN,CCHAIN)
C RS 89 changed to read from PDB-file (used in MAXHOM)
C by Chris Sander, 1982 and later
C and Brigitte Altenberg, 1987 and later
C GET SEQUENCE FROM DSSP-FILE, HSSP SWISSPROT....OR FREE FORMAT FILE.
CAUTION: used by MAXHOM, PUZZLE, WINDOW-DNA (?), SEG-PRED (?) etc.
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
	
      PARAMETER  (MAXCHAIN=40)
      PARAMETER (MAXRECLEN=10000)
      CHARACTER LOWER*26,PUNCTUATION*10,FORMATNAME*4
      CHARACTER TRANS*26,CS*1,CC*1
      CHARACTER LINE*(MAXRECLEN)
cx	character*80 FILENAME
      CHARACTER*(*) FILENAME
C compound for DSSP
      CHARACTER*(*) COMPND  
C accession number and dummy string (fx. pdb-pointer from swissprot)
      CHARACTER*(*) ACCNUM,CDUMMY	
      
      CHARACTER*1 CSQ(*),STRUC(*),CH,CCHAIN
      CHARACTER*6 CRESID(*),CR
      LOGICAL TRUNCATED,ERRFLAG,LKEEP,LCHAIN(MAXCHAIN)
      LOGICAL LDSSP,LACCZERO,LHSSP
      INTEGER KACC(*),KCHAIN
      INTEGER IOP	
C     INTERNAL
      CHARACTER CTEST*1,CHAINMODE*20,CHAINID(MAXCHAIN)*1
      LOGICAL LCHAINBREAK,LEGALRES
      CHARACTER*100 CTEMP
C dont use INDEX command (CPU time)
      INTEGER NASCII
      PARAMETER (NASCII=256)
      INTEGER TRANSPOS(NASCII)
C read from BRK
      CHARACTER SEQ(2000)*3,CIDRES(2000)*6	       

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
      ACCNUM=' '	
      LINE=' '
CAUTION.. recommendation:
C calling program should allow "!" as legal residue for DSSP format
C *BA*
      IF (NTRANS.EQ.0) THEN                                              
         write(*,*)'GETSEQ: NTRANS was 0 !!!!'
         NTRANS=26
         TRANS='GAVLISTDENQKHRFYWCMPBZX!-.'
         write(*,*)'GETSEQ: TRANS set to:', TRANS
      ENDIF
      IF (NTRANS.GT.26) THEN  
         WRITE(*,*)'trans:#',TRANS,'# ntrans:',NTRANS
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
      WRITE(*,*) 'GETSEQ: ', FILENAME(1:LENFILNAM)
      IF (LENFILNAM .LE. 1) THEN
        WRITE(*,*)'GETSEQ: *** empty file name, return with NRES=0'
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
            WRITE(*,*)' WILL READ CHAINS ACCORDING TO NUMBER'
         ELSE
            CHAINMODE='CHARACTER'
            WRITE(*,*)' WILL READ CHAINS ACCORDING TO CHARACTER'
         ENDIF

         DO J=1,NSELECT
            IF (CHAINMODE.EQ.'NUMBER') THEN
               CALL READ_INT_FROM_STRING(FILENAME(ISTART:),K)
               IF (K.GT.0 .AND. K.LE.MAXCHAIN) THEN
                  LCHAIN(K)=.TRUE.
               ELSE
                  WRITE(*,*)'*** ERROR: K<1 OR K>MAXCHAIN IN GETSEQ'
                  STOP
               ENDIF
            ELSE
               READ(FILENAME(ISTART:ISTART),'(A1)')CHAINID(J)
               CALL LOWTOUP(CHAINID(J),1)
            ENDIF
            ISTART=ISTART+2
         ENDDO
         WRITE(*,*)' **** GETSEQ: extract the chain(s)'
         IF (CHAINMODE.EQ.'NUMBER') THEN
            DO J=1,MAXCHAIN
               IF (LCHAIN(J))WRITE(*,*)' CHAIN: ',J
            ENDDO
         ELSE
            DO J=1,NSELECT
               WRITE(*,*)' CHAIN: ',CHAINID(J)
            ENDDO
         ENDIF
         ISTOP=INDEX(FILENAME,'_!')-1
         FILENAME=FILENAME(1:ISTOP)
      ELSE
         CHAINMODE='NONE'
         IF (KCHAIN.NE.0) THEN
            WRITE(*,*)' will extract chain number: ',KCHAIN	
         ENDIF
         DO J=1,MAXCHAIN
            LCHAIN(J)=.TRUE.
         ENDDO
      ENDIF
C *BA*BEGIN
      CALL CHECKFORMAT(IN,FILENAME,FORMATNAME,ERRFLAG)	           
c      WRITE(*,*) ' GETSEQ: format is  ',FORMATNAME 
      IF (INDEX(FORMATNAME,'DSSP').NE.0) THEN
         LDSSP=.TRUE.
      ENDIF
      IF (INDEX(FORMATNAME,'HSSP').NE.0) THEN
         LHSSP=.TRUE.
      ENDIF
      IF (ERRFLAG) THEN
         WRITE(*,*)'GETSEQ: file open error, set NRES=0 and return'
         WRITE(*,*)'filename: ', FILENAME
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
                     WRITE(*,'(A)')
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
C ** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, VERSION OCT. 1985
C FERENCE W. KABSCH AND C.SANDER, BIOPOLYMERS 22 (1983) 2577-2637
C ADER    PANCREATIC HORMONE                      16-JAN-81   1PPT
C MPND    AVIAN PANCREATIC POLYPEPTIDE
 100  READ(IN,'(A124)',END=199)LINE
      IF (INDEX(LINE,'SECONDARY').EQ.0) THEN
         WRITE(*,*)'***GETAASEQ ERROR: DSSP file assumed, but...'
         WRITE(*,*)' the word /SECONDARY/ is missing in first line'
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
      COMPND=LINE(11:80)
C repeat until #  
 105  READ(IN,'(A)',END=199)LINE
      IF (INDEX(LINE(1:5),'#').EQ.0) GOTO 105
C23456123451x1xx1
Cxxxxxaaaaaaxaxxaxxxxxxxxxxxxxxxxxxiii
C   9    9 A S  E     -aB  35  15A   0   24,-2.3  27,-2.9  -2,-0.4  28,-0.5  -0.939  14.7-175.8-120.8 141.0   -5.5    9.8   13.0
C  21   21   Y  E     -AB  32  45A  68   24,-3.1  24,-2.9  -2,-0.3
C DSSP:     seqstr                 acc   hbonds
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
c	write(*,*)cchain
C ### ILLegal RESIDUES
               ENDIF
C CHAINS WANTED
            ENDIF
C DIMENSION OVERFLOW
         ELSE
            WRITE(IOP,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
            WRITE(*,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
            GOTO 900
         ENDIF
C     NEXT LINE             
      ENDDO
C--------------DSSP read error -----------------------------------
 199  WRITE(*,*)'***GETAASEQ: incomplete DSSP file (EOF) '
      NRES=0
      NCHAIN=0
      CALL STRPOS(FILENAME,I,LENFILNAM)
      WRITE(*,*) 'FILE: ',FILENAME(1:LENFILNAM)
      CLOSE(IN)
      RETURN
C----------------READ FROM BROOKHAVEN--------------------------------

 200  READ(IN,'(A)',END=900,ERR=999)LINE
      IF (INDEX(LINE,'HEADER').EQ.0) THEN
         WRITE(*,*)'***GETAASEQ ERROR: BRK file assumed, but...'
         WRITE(*,*)' the word /HEADER/ is missing in first line'
         RETURN
      ENDIF
      IF (IOP.NE.0)WRITE(IOP,*)LINE(1:80)
C compnd
      READ(IN,'(A)',END=900,ERR=999)LINE  
      IF (IOP.NE.0)WRITE(IOP,*)LINE(1:80)
      COMPND=LINE(1:80)
C read only the kth chain                   
C NAME OF CHAIN
      CCHAIN=' '                        
C CHAIN COUNTER
      NCHAIN=1                          
C RES LINE COUNTER
      NRESLINE=0
      NRES=0                            
210   READ(IN,'(A)',END=280,ERR=999)LINE	
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
                  WRITE(*,*)' GETAASEQ: ACE ignored at res ',NRES
                  GOTO 210
               ENDIF
               IF (NRES.NE.1) THEN
                  IF (CIDRES(NRES-1).EQ.CIDRES(NRES))NRES=NRES-1
               ENDIF
            ELSE
               WRITE(IOP,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
               WRITE(*,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
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
C---------------------------READ FROM :PIR-------------------------*BA*BEGIN
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
                  WRITE(*,'(A)')
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
            ACCNUM(1:)=LINE(6:I)
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
	       WRITE(*,*)'**** PDBREF-LINE DIMENSION OVERFLOW ***'
            ENDIF
	 ENDIF
      ENDDO
 420  CALL STRPOS(CDUMMY,ISTART,ISTOP)
      IF (ID .GT. 0) THEN
         IF ( (ISTOP+7) .LE. LEN(CDUMMY) ) THEN
	    WRITE(CDUMMY(ISTOP+1:),'(A,I4)')'||',ID
         ELSE
	    WRITE(*,*)'**** PDBREF-LINE DIMENSION OVERFLOW ***'
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
                     WRITE(*,'(A)')
     +                    '*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
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
                  WRITE(*,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ **'
                  GOTO 900
               ENDIF
C LEGAL RESIDUE                                      
            ENDIF
C NEXT RESIDUE
         ENDDO
C NEXT LINE
      ENDDO
                                                   
C---------------------------READ FROM :UWGCG-------------------------*BA*BEGIN

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
                  WRITE(IOP,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ '
                  WRITE(*,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ *'
                  GOTO 900
               ENDIF
C LEGAL RESIDUES                
            ENDIF
C NEXT RESIDUE
         ENDDO
C NEXT LINE
      ENDDO
C---------------------------READ FROM :HSSP----------------------------
 700  READ(IN,'(A)',END=199)LINE
      IF (INDEX(LINE,'HOMOLOGY').EQ.0) THEN
         WRITE(*,*)'***GETAASEQ ERROR: HSSP file assumed, but...'
         WRITE(*,*)' the word /HOMOLOGY/ is missing in first line'
         RETURN
      ENDIF
      DO WHILE(INDEX(LINE,'NOTATION ').EQ.0)	
         READ(IN,'(A)',END=199)LINE
         IF (INDEX(LINE,'HEADER').NE.0) THEN
            IF (IOP.NE.0)WRITE(IOP,*)LINE(12:)
         ELSE IF (INDEX(LINE,'COMPND').NE.0) THEN
            IF (IOP.NE.0)WRITE(IOP,*)LINE
            COMPND=LINE(12:80)
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
          WRITE(*,'(A)')'*** ERROR: DIMENSION OVERFLOW MAXSQ ***'
          GOTO 900
       ENDIF
C NEXT LINE             
      ENDDO
      IF (NRESLINE .EQ. ISEQLEN)GOTO 900
C--------------HSSP read error -----------------------------------
 799  WRITE(*,*)'***GETSEQ: incomplete HSSP file '
      NRES=0
      NCHAIN=0
      CALL STRPOS(FILENAME,I,LENFILNAM)
      WRITE(*,*) 'FILE: ',FILENAME(1:LENFILNAM)
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
            WRITE(*,*)'*******************************************'
            WRITE(*,*)'* WARNING: all accessibility values are 0 *'
            WRITE(*,*)'*******************************************'
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
         WRITE(*,*)'TRUNCATED TO   ',NDIM,' RESIDUES'
         WRITE(*,*)'****  INCREASE DIMENSION ****'
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
C     END GETSIMMETRIC
C......................................................................

C......................................................................
C     SUB GETTOKEN
      SUBROUTINE GETTOKEN(CSTRING,LEN,ITOKEN,FIRSTPOS,CTOKEN)

      IMPLICIT NONE
C 3.6.93 changed : return firstpos .eq. len+1, if ctoken contains
C ...... less than "itoken" words
C 12.10.93 changed : return firstpos .eq. 0, if ctoken contains
C ...... less than "itoken" words
C 4.11.93
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
C     END GETTOKENFINDBRKFILE
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
         WRITE(*,'(A)') 
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
C     SUB LOWTOUP
      SUBROUTINE LOWTOUP(STRING,LENGTH)
C LOWTOUP.......CONVERTS STRING......CHRIS SANDER JULY 1983
C changed by RS (speed up)
      CHARACTER*(*) STRING
      INTEGER LENGTH
CX      CHARACTER UPPER*26, LOWER*26, STRING*(*)
CX      DATA UPPER/'ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
CX      DATA LOWER/'abcdefghijklmnopqrstuvwxyz'/
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
C     SUB READHSSP
      SUBROUTINE READHSSP(IUNIT,HSSPFILE,ERROR,MAXRES,MAXALIGNS,
     +     MAXCORE,MAXINS,MAXINSBUFFER,PDBID,HEADER,COMPOUND,
     +     SOURCE,AUTHOR,SEQLENGTH,NCHAIN,KCHAIN,CHAINREMARK,
     +     NALIGN,EXCLUDEFLAG,EMBLID,STRID,IDE,SIM,IFIR,ILAS,
     +     JFIR,JLAS,LALI,NGAP,LGAP,LENSEQ,ACCNUM,PROTNAME,
     +     PDBNO,PDBSEQ,CHAINID,SECSTR,COLS,SHEETLABEL,BP1,BP2,
     +     ACC,NOCC,VAR,ALISEQ,ALIPOINTER,SEQPROF,NDEL,NINS,
     +     ENTROPY,RELENT,CONSWEIGHT,INSNUMBER,INSALI,
     +     INSPOINTER,INSLEN,INSBEG_1,INSBEG_2,INSBUFFER,
     +     LCONSERV,LHSSP_LONG_ID)
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
      IMPLICIT NONE
      INTEGER MAXALIGNS,MAXRES,MAXCORE,MAXINS,MAXAA,NBLOCKSIZE
      INTEGER MAXINSBUFFER
      PARAMETER (MAXAA=20, NBLOCKSIZE=70)
C============================ import ==================================
      CHARACTER HSSPFILE*(*)
      INTEGER IUNIT
      LOGICAL ERROR	
C     ATTRIBUTES OF SEQUENCE WITH KNOWN STRUCTURE
      CHARACTER*(*) PDBID,HEADER,COMPOUND,SOURCE,AUTHOR
      CHARACTER PDBSEQ(MAXRES),CHAINID(MAXRES),SECSTR(MAXRES)
C.......LENGHT*7
      CHARACTER*(*) COLS(MAXRES),CHAINREMARK 
      CHARACTER SHEETLABEL(MAXRES)
      INTEGER SEQLENGTH,PDBNO(MAXRES),NCHAIN,KCHAIN,NALIGN
      INTEGER BP1(MAXRES),BP2(MAXRES),ACC(MAXRES)
C     ATTRIBUTES OF ALIGNEND SEQUENCES
      CHARACTER*(*) EMBLID(MAXALIGNS),STRID(MAXALIGNS)
      CHARACTER*(*) ACCNUM(MAXALIGNS),PROTNAME(MAXALIGNS)
      CHARACTER ALISEQ(MAXCORE)	
      CHARACTER EXCLUDEFLAG(MAXALIGNS)
      INTEGER ALIPOINTER(MAXALIGNS)
      INTEGER IFIR(MAXALIGNS),ILAS(MAXALIGNS),JFIR(MAXALIGNS)
      INTEGER JLAS(MAXALIGNS),LALI(MAXALIGNS),NGAP(MAXALIGNS)
      INTEGER LGAP(MAXALIGNS),LENSEQ(MAXALIGNS)
      REAL IDE(MAXALIGNS),SIM(MAXALIGNS)
C     ATTRIBUTES OF PROFILE
      INTEGER VAR(MAXRES)
      INTEGER SEQPROF(MAXRES,MAXAA)
      INTEGER NOCC(MAXRES),NDEL(MAXRES),NINS(MAXRES),RELENT(MAXRES)
      REAL ENTROPY(MAXRES)
      REAL CONSWEIGHT(MAXRES)
      INTEGER INSNUMBER,INSALI(MAXINS),INSPOINTER(MAXINS)
      INTEGER INSLEN(MAXINS),INSBEG_1(MAXINS),INSBEG_2(MAXINS)
      CHARACTER INSBUFFER(MAXINSBUFFER)
C.......
      LOGICAL LCONSERV,LHSSP_LONG_ID
C=======================================================================
C internal	
      INTEGER MAXALI_INT
      PARAMETER (MAXALI_INT=5000)
      CHARACTER CTEMP*(NBLOCKSIZE),TEMPNAME*80
      CHARACTER*132 LINE
      CHARACTER     CHAINSELECT
      LOGICAL LCHAIN
      INTEGER ICHAINBEG,ICHAINEND,NALIGNORG
      INTEGER I,J,K,IPOS,ILEN,NRES,IRES,NBLOCK,IALIGN,IBLOCK,IALI
C     INTEGER I,J,K,IPOS,JPOS,ILEN,NRES,IRES,NBLOCK,IALIGN,IBLOCK,IALI
      INTEGER IBEG,IEND
      INTEGER IPOINTER(5000),IPOINT,IINS
C     ORDER OF AMINO ACID SYMBOLS IN THE HSSP SEQUENCE PROFILE BLOCK
C     PROFILESEQ='VLIMFWYGAPSTCHRKQEND'
      ERROR=.FALSE.
      NALIGN=0
      CHAINREMARK=' '
      CHAINSELECT=' '
      DO I=1,MAXINSBUFFER
         INSBUFFER(I)=' '
      ENDDO
      DO I=1,MAXALI_INT
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
         write(*,*)'*** ReadHSSP: extract the chain: ',chainselect
      ELSE IF (J.NE.0) THEN
         TEMPNAME(1:)=HSSPFILE(1:J+3)
         LCHAIN=.TRUE.
         READ(HSSPFILE(J+5:),'(A1)')CHAINSELECT
         write(*,*)'*** ReadHSSP: extract the chain: ',chainselect
      ENDIF

      CALL OPEN_FILE(IUNIT,TEMPNAME,'old,readonly',error)
      IF (ERROR)GOTO 99
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
         write(6,'(A)')'*** HSSP-file contains no alignments ***'
         CLOSE(IUNIT)
c	   error=.true.
         RETURN
      ENDIF
C parameter overflow handling
      IF (NALIGNORG.GT.MAXALIGNS) THEN
         write(6,'(A)')'*** HSSP-file contains too many alignments **'
         write(6,'(A)')'***   INCREASE MAXALIGNS IN COMMOM BLOCK  ***'
         CLOSE(IUNIT)
         ERROR=.TRUE.
         RETURN
      ENDIF
      IF (NALIGNORG .GT. MAXALI_INT) THEN
         write(*,*)'READHSSP: maxali_int overflow, increase !!'
         STOP
      ENDIF

      IF (SEQLENGTH+KCHAIN-1.GT.MAXRES) THEN
         write(6,'(A)')'*** PDB-sequence in HSSP-file too long ***'
         write(6,'(A)')'***  INCREASE MAXRES ***'	
         write(6,'(A,I6,A,I6)')
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
     +           LGAP(IALIGN),LENSEQ(IALIGN),ACCNUM(IALIGN),
     +           PROTNAME(IALIGN)
         ELSE   
            READ(IUNIT,100,ERR=99)
     +           EXCLUDEFLAG(IALIGN),EMBLID(IALIGN)(1:),STRID(IALIGN),
     +           IDE(IALIGN),SIM(IALIGN),IFIR(IALIGN),ILAS(IALIGN),
     +           JFIR(IALIGN),JLAS(IALIGN),LALI(IALIGN),NGAP(IALIGN),
     +           LGAP(IALIGN),LENSEQ(IALIGN),ACCNUM(IALIGN),
     +           PROTNAME(IALIGN)
         ENDIF
         IF (IFIR(IALIGN) .GE. ICHAINBEG .AND. 
     +	      ILAS(IALIGN) .LE. ICHAINEND) THEN
            IPOINTER(I)=IALIGN
            IALIGN=IALIGN+1
         ELSE
            write(*,*)'INFO: skip alignment: ',i
c	      write(*,*)ifir(ialign),ichainbeg,ilas(ialign),ichainend
         ENDIF
      ENDDO
 50   FORMAT(5X,A1,2X,A40,A6,1X,F5.2,1X,F5.2,8(1X,I4),2X,A10,1X,A)
 100  FORMAT(5X,A1,2X,A12,A6,1X,F5.2,1X,F5.2,8(1X,I4),2X,A10,1X,A)
      NALIGN=IALIGN-1
      write(*,*)' number of alignments: ',nalign
      write(*,*)'   PROTEINS   block done'
C init pointer ; aliseq contains the alignments (amino acid symbols)
C stored in the following way ; '/' separates alignments
C alignment(x) is stored from:
C           aliseq(alipointer(x)) to aliseq(ilas(x)-ifir(x))
C  aliseq(1........46/48.........60/62....)
C         |           |             |
C         |           |             |
C         pointer     pointer       pointer 
C         ali 1       ali 2         ali 3
C init pointer
      IPOS=1
      DO I=1,NALIGN
         IF (IPOS.GE.MAXCORE) THEN
            WRITE(6,'(A)')' *** ERROR: INCREASE MAXCORE ***'
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
                     IF (CTEMP(IPOS:IPOS) .NE. ' ') THEN
c			if (ipointer(iali) .le. 0 ) then
c			   write(*,*)' readhssp: ',iali,ialign,ipos
c			endif
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
      WRITE(*,*)'   ALIGNMENTS block done'
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
      write(*,*)'   PROFILE    block done'
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
                  WRITE(*,*)'*** ERROR: MAXINS OVERFLOW, INCREASE !'
                  GOTO 99
               ENDIF
               IINS=IINS+1
               INSPOINTER(IINS)=IPOINT
               READ(LINE,'(4(I6))')INSALI(IINS),INSBEG_1(IINS),
     +              INSBEG_2(IINS),INSLEN(IINS)
               
               IF (IPOINT + INSLEN(IINS)+3 .GT. MAXINSBUFFER) THEN
                  write(*,*)
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
         write(*,*)'   INSERTION  list  done'
         INSNUMBER=IINS
      ELSE IF (LINE(1:2) .NE. '//') THEN
         GOTO 99
      ENDIF
      CLOSE(IUNIT)
      CALL STRPOS(HSSPFILE,IBEG,IEND)
      write(*,'(A,A,A)')' ReadHSSP: ',hsspfile(ibeg:iend),' OK' 

      RETURN
 99   write(6,'(A,A)')'**** READHSSP: ERROR reading: ',hsspfile
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
      IMPLICIT NONE

C order of amino acids
      INTEGER NTRANS
      CHARACTER*(*) TRANS
      LOGICAL LDSSP
      INTEGER	    NACID
      PARAMETER   (NACID=20)
      INTEGER     KPROF,MAXRES,NRES,ACC(MAXRES),BP1(MAXRES)
      INTEGER     BP2(MAXRES),NOCC(MAXRES),NCHAIN,PDBNO(MAXRES)
      REAL        PROFILEMETRIC(MAXRES,NTRANS),GAPOPEN(MAXRES)
      REAL        GAPELONG(MAXRES),CONSWEIGHT(MAXRES)
      REAL        SMIN,SMAX,MAPLOW,MAPHIGH
      CHARACTER*(*) HSSPID,HEADER,COMPOUND,SOURCE,AUTHOR,METRICFILE
      CHARACTER*(*) PROFILENAME,SEQ(MAXRES),STRUC(MAXRES)
      CHARACTER*(*) CHAINID(MAXRES)
      CHARACTER*7   COLS(MAXRES)
      CHARACTER*1   SHEETLABEL(MAXRES)
      CHARACTER*300 LINE
      INTEGER     MAXBOX,NBOX,PROFILEBOX(MAXBOX,2)
C internal
      INTEGER I,J,K,IBOX
      CHARACTER     CDIVIDE1,CDIVIDE2
      LOGICAL LERROR
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
         WRITE(*,'(A,A)')
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
         READ(LINE,100)PDBNO(I),CHAINID(I),SEQ(I),
     +        STRUC(I),COLS(I),BP1(I),BP2(I),SHEETLABEL(I),ACC(I),
     +        NOCC(I),GAPOPEN(I),GAPELONG(I),CONSWEIGHT(I),
     +        (PROFILEMETRIC(I,J),J=1,NACID)
 100     FORMAT(6X,1X,I4,1X,A1,1X,A1,2X,A1,1X,A7,2(I4),A1,2(I4,1X),
     +        2(F6.2),F7.2,20(F8.3))
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
         PROFILEMETRIC(K,J)=PROFILEMETRIC(K,I)
      ENDDO
      I=INDEX(TRANS,'Q')
      J=INDEX(TRANS,'Z')
      DO K=1,NRES
         PROFILEMETRIC(K,J)=PROFILEMETRIC(K,I)
      ENDDO
      RETURN
C     read error
 999  CLOSE(KPROF)
      write(*,*)'*** ERROR: read error in MAXHOM-PROFILE'
      NRES=0
      RETURN
      END
C     END READPROFILE
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
C     END READ_INT_FROM_STRING
C......................................................................

C......................................................................
C     SUB READ_MSF
      SUBROUTINE READ_MSF(KUNIT,FILENAME,MAXALIGNS,MAXCORE,
     1     ALISEQ,ALIPOINTER,IFIR,ILAS,JFIR,JLAS,TYPE,
     2     SEQNAMES,WEIGHT,SEQCHECK,MSFCHECK,ALILEN,NSEQ,
     3     ERROR)

C	Implicit None

C     IMPORT
      INTEGER MAXALIGNS, MAXCORE
      INTEGER KUNIT
      CHARACTER*(*) FILENAME
C     EXPORT
      INTEGER NSEQ
      INTEGER ALIPOINTER(MAXALIGNS)
      INTEGER ALILEN
      INTEGER MSFCHECK
      INTEGER IFIR(MAXALIGNS), ILAS(MAXALIGNS)  
      INTEGER JFIR(MAXALIGNS), JLAS(MAXALIGNS)  
C     'P' = PROTEIN SEQUENCES, 'N' = NUCLEOTIDE SEQ
      CHARACTER*1 TYPE
      CHARACTER*(*) SEQNAMES(MAXALIGNS)
      CHARACTER ALISEQ(MAXCORE)	
      REAL WEIGHT(MAXALIGNS)
      INTEGER SEQCHECK(MAXALIGNS)
      LOGICAL ERROR
C     INTERNAL
      INTEGER CODELEN_INTERNAL
      INTEGER MAXALIGNS_INTERNAL, MAXRES_INTERNAL
      INTEGER LINELEN
      PARAMETER ( CODELEN_INTERNAL = 14 )
      PARAMETER ( MAXALIGNS_INTERNAL = 2000 )
      PARAMETER ( MAXRES_INTERNAL = 10000 )
      PARAMETER ( LINELEN = 132 )
      
      INTEGER TESTCHECK
      INTEGER LASTOCCUPIED(MAXALIGNS_INTERNAL)
      INTEGER I, IPOS, ISEQ, THISSEQ
      INTEGER ISTART, ISTOP
      INTEGER SEQSTART
      INTEGER ILEN,DIFF, CFREE,FPOS
      INTEGER LENGTH(MAXALIGNS_INTERNAL)
      INTEGER NSEQLINES(MAXALIGNS_INTERNAL)
      CHARACTER CGAPCHAR
      CHARACTER*132 ERRORMESSAGE, CTOKEN
      CHARACTER*(CODELEN_INTERNAL) CNAME
      CHARACTER*(LINELEN) LINE, TMPSTRING
      CHARACTER*(MAXRES_INTERNAL) STRAND
      CHARACTER*20 CFORMAT
      LOGICAL INSIDE(MAXALIGNS_INTERNAL)
      LOGICAL INGAP(MAXALIGNS_INTERNAL)
      LOGICAL NO_ENDGAPS
      LOGICAL LCHECK, LTYPE, LALILEN
      LOGICAL NEXT_IS_ALILEN, NEXT_IS_CHECK, NEXT_IS_TYPE
      LOGICAL NEXT_IS_NAME, NEXT_IS_LEN, NEXT_IS_SEQCHECK
      LOGICAL NEXT_IS_WEIGHT

C REFORMAT of: *.Frag
C Nfi.Msf  MSF: 594  Type: P  February 17, 1992  14:37  Check: 1709  ..
C Name: Cnfi02           Len:   594  Check: 7754  Weight:  1.00
C Name: Cnfi03           Len:   594  Check: 4932  Weight:  1.00
C//
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
      LALILEN = .FALSE.
      LCHECK = .FALSE.
      LTYPE =  .FALSE.
      NEXT_IS_ALILEN = .FALSE.
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
         IF ( NEXT_IS_ALILEN ) THEN
            NEXT_IS_ALILEN = .FALSE.
            
            CALL MAKE_FORMAT_INT(ISTOP-ISTART+1,CFORMAT)
            
            READ(CTOKEN(ISTART:ISTOP),CFORMAT) ALILEN
         ELSE IF ( NEXT_IS_TYPE ) THEN
            TYPE = CTOKEN(ISTART:ISTOP)
            NEXT_IS_TYPE = .FALSE.
         ELSE IF ( NEXT_IS_CHECK ) THEN
            CALL MAKE_FORMAT_INT(ISTOP-ISTART+1,CFORMAT)
            READ(CTOKEN(ISTART:ISTOP),CFORMAT) MSFCHECK
            NEXT_IS_CHECK = .FALSE.
         ENDIF
         IF ( CTOKEN(ISTART:ISTOP) .EQ. 'MSF:' ) THEN
            LALILEN = .TRUE.
            NEXT_IS_ALILEN = .TRUE.
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
      IF ( .NOT. LALILEN ) THEN
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
      NSEQ = 0
      DO WHILE ( INDEX(LINE,'Name: ') .NE. 0 )
         NSEQ = NSEQ + 1
         IF ( NSEQ .GT. MAXALIGNS .OR. 
     1        NSEQ .GT. MAXALIGNS_INTERNAL) THEN
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
         CALL GETTOKEN(LINE,LINELEN,I,FPOS,CTOKEN)
         DO WHILE ( FPOS .NE. 0 ) 
            CALL STRPOS(CTOKEN,ISTART,ISTOP)
            CALL LOWTOUP(CTOKEN, LEN(CTOKEN))
            IF ( NEXT_IS_NAME ) THEN
               NEXT_IS_NAME = .FALSE.
               SEQNAMES(NSEQ) = CTOKEN(ISTART:ISTOP)
            ELSE IF ( NEXT_IS_LEN ) THEN
               NEXT_IS_LEN = .FALSE.
               CALL MAKE_FORMAT_INT(ISTOP-ISTART+1,CFORMAT)
               READ(CTOKEN(ISTART:ISTOP),CFORMAT) ILEN
               ALILEN = MAX(ALILEN,ILEN)
            ELSE IF ( NEXT_IS_SEQCHECK ) THEN
               NEXT_IS_SEQCHECK = .FALSE.
               CALL MAKE_FORMAT_INT(ISTOP-ISTART+1,CFORMAT)
               READ(CTOKEN(ISTART:ISTOP),CFORMAT) SEQCHECK(NSEQ)
            ELSE IF ( NEXT_IS_WEIGHT ) THEN
               NEXT_IS_WEIGHT = .FALSE.
               READ(CTOKEN(ISTART:ISTOP),*) WEIGHT(NSEQ)
            ENDIF
            IF ( CTOKEN(ISTART:ISTOP) .EQ. 'NAME:' ) THEN
               NEXT_IS_NAME = .TRUE.
            ELSE IF ( CTOKEN(ISTART:ISTOP) .EQ. 'LEN:' ) THEN
               NEXT_IS_LEN = .TRUE.
            ELSE IF ( CTOKEN(ISTART:ISTOP) .EQ. 'CHECK:' ) THEN
               NEXT_IS_SEQCHECK = .TRUE.
            ELSE IF ( CTOKEN(ISTART:ISTOP) .EQ. 'WEIGHT:' ) THEN
               NEXT_IS_WEIGHT = .TRUE.
            ENDIF
            I = I + 1
            CALL GETTOKEN(LINE,LINELEN,I,FPOS,CTOKEN)
         ENDDO
         READ(KUNIT,'(A)',END = 99) LINE
      ENDDO

      ERROR = .FALSE.
      CALL MSFCHECKSEQ(SEQCHECK,NSEQ,TESTCHECK)
      IF ( TESTCHECK .NE. MSFCHECK ) THEN
C     ERROR = .TRUE. 
         ERRORMESSAGE = 
     1        ' Total checksum incompatible with single checksums !!'

         WRITE(*,'(A)') ERRORMESSAGE
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
      DO ISEQ = 1, NSEQ
         NSEQLINES(ISEQ) = 0
         LENGTH(ISEQ) = 0
         LASTOCCUPIED(ISEQ) = 0
         INSIDE(ISEQ) =.FALSE.
C TEMPORARY assignment!
         IF ( ISEQ .EQ. 1 ) THEN
            ALIPOINTER(ISEQ) = 1
         ELSE
            ALIPOINTER(ISEQ) = ALIPOINTER(ISEQ-1)+ALILEN+1 
         ENDIF
         JFIR(ISEQ) = 1
         JLAS(ISEQ) = 0
      ENDDO
      ERROR = .TRUE.
      ERRORMESSAGE = ' ALIGNMENT MISSING !! '
      READ(KUNIT,'(A)',END=99) LINE
      ERROR = .FALSE.
      DO WHILE ( .TRUE. )
         CALL GETTOKEN(LINE,LINELEN,1,FPOS,CNAME)
         CALL LOWTOUP(CNAME, LEN(CNAME) )
         CALL GETARRAYINDEX(SEQNAMES,CNAME,NSEQ,THISSEQ)
         IF ( THISSEQ .GT. 0 ) THEN
C     ONE OF THE NAMES FOUND
            NSEQLINES(THISSEQ) = NSEQLINES(THISSEQ) + 1 
            CALL GETTOKEN(LINE,LINELEN,2,SEQSTART,TMPSTRING)
C 25.10.94
            CALL LOWTOUP(LINE,LEN(LINE))
            DO IPOS = SEQSTART, LINELEN
               IF ( LINE(IPOS:IPOS) .NE. ' ' .AND.
     1              LINE(IPOS:IPOS) .NE. CHAR(0)   ) THEN
                  
                  LENGTH(THISSEQ) = LENGTH(THISSEQ) + 1
C 17.10.94
C                    write(*,'(1x,i4,1x,i4)') 
C     1                   length(thisseq), thisseq
                  IF ( LENGTH(THISSEQ) .GT. ALILEN ) THEN
                     WRITE(*,'(A)')
     1'*** error in read_msf : SEQUENCE LENGTH EXCEEDS ' //
     2'ALIGNMENT LENGTH GIVEN IN HEADER !!! ***'
                     WRITE(*,*)LINE(1:LEN(LINE))
                     WRITE(*,*)LENGTH(THISSEQ),' > ',ALILEN
                     STOP
                  ENDIF

                  IF ( LINE(IPOS:IPOS) .EQ. CGAPCHAR ) THEN
                     INGAP(THISSEQ) = .TRUE.
                     IF ( INSIDE(THISSEQ) )  
     1           ALISEQ(ALIPOINTER(THISSEQ)+LENGTH(THISSEQ)-1)=CGAPCHAR
                  ELSE
                     INGAP(THISSEQ) = .FALSE.
                     LASTOCCUPIED(THISSEQ) = LENGTH(THISSEQ)
                     IF ( .NOT. INSIDE(THISSEQ) ) THEN
                        INSIDE(THISSEQ) = .TRUE.
                        IFIR(THISSEQ) = LENGTH(THISSEQ)
                     ENDIF
                     JLAS(THISSEQ) = JLAS(THISSEQ) + 1
                     ALISEQ(ALIPOINTER(THISSEQ)+LENGTH(THISSEQ)-1)=
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
         DO ISEQ = 2,NSEQ
            IF ( NSEQLINES(ISEQ) .NE. NSEQLINES(1) ) THEN
               ERROR = .TRUE.
               ERRORMESSAGE = 
     1              ' Inconsistent sequence names  !!'
            ENDIF
         ENDDO
      ENDIF
      
      IF ( ERROR ) THEN
         WRITE(*,'(A)') ERRORMESSAGE
         RETURN
      ENDIF
      
      NO_ENDGAPS = .TRUE.
      DO ISEQ = 1,NSEQ
         NO_ENDGAPS = NO_ENDGAPS .AND. ( .NOT. INGAP(ISEQ))
         ILAS(ISEQ) = LASTOCCUPIED(ISEQ) 
      ENDDO
 
C delete n- and c-terminal gaps from aliseq;
C set ifir and ilas accordingly;
C set pointers to alignments
C 1.6.94 : truncate ALILEN to be the last position occupied in at least one 
C ........ one of the sequences !

      DIFF = 0
      CFREE = ALILEN + 1
      IPOS = 1
      DO ISEQ = 1,NSEQ
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
         DIFF = DIFF + ( ALILEN - ILAS(ISEQ) )
C     SMALLEST DISTANCE OF LAST OCCUPIED POSITION TO LAST ALIGNMENT POSITION
C     .. SHOULD BE ZERO, IF AT LEAST ONE SEQUENCE EXTENDS TO THE VERY END
         CFREE = MIN(CFREE,(ALILEN - ILAS(ISEQ)) )
      ENDDO
      
      IF ( CFREE .GT. 0 ) THEN
         WRITE(*,'(1X,A)') 
     1        ' *** WARNING : empty c-terminal positions truncated ***'
         ALILEN = ALILEN - CFREE
      ENDIF
      
      ERROR = .FALSE.
      DO ISEQ = 1, NSEQ
         STRAND = ' '
         CALL GET_SEQ_FROM_ALISEQ(ALISEQ,IFIR,ILAS,ALIPOINTER,
     1        ALILEN,ISEQ,STRAND,NREAD,
     2        ERROR )
         IF ( NO_ENDGAPS ) THEN
            CALL CHECKSEQ(STRAND,1,ILAS(ISEQ),TESTCHECK)
         ELSE
            CALL CHECKSEQ(STRAND,1,ALILEN,TESTCHECK)
         ENDIF
         IF ( TESTCHECK .NE. SEQCHECK(ISEQ) ) THEN
C     ERROR = .TRUE.
            CALL STRPOS(SEQNAMES(ISEQ),ISTART,ISTOP)
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
C    'X' OR 'XXX' FOR NON-STANDARD OR UNKNOWN AMINO ACID RESIDUES
      DO I=1,NRES
         DO J=1,24
CD        WRITE(*,*)'S3TOS1: ',SEQ3(I),I,' =?= ',AA3(J),J
            IF (SEQ3(I).EQ.AA3(J)) THEN
               SEQ1(I)=AA1(J)
               GOTO 9
            ENDIF
         ENDDO
         SEQ1(I)='X'
         WRITE(*,100) SEQ3(I),SEQ1(I)
         WRITE(*,*)' legal residues are: '
         WRITE(*,*) (AA3(J),J=1,24)
 9       CONTINUE
      ENDDO
 100  FORMAT(' UNUSUAL RESIDUE NAME <',A3,'> TRANSLATED TO <',A1,'>')
c      ENTRY S1TOS3(SEQ3,SEQ1,NRES)
c      DO I=1,NRES
c        DO J=1,24
c        IF (SEQ1(I).EQ.AA1(J)) THEN
c          SEQ3(I)=AA3(J)
c        GOTO 99
c        ENDIF
c        ENDDO
c        SEQ3(I)='XXX'
c        WRITE(*,100) SEQ1(I),SEQ3(I)
c99      CONTINUE
c      ENDDO
      RETURN
      END
C     END S3TOS1
C......................................................................

C......................................................................
C     SUB SCALEINTERVAL
      SUBROUTINE SCALEINTERVAL(S,N,SMIN,SMAX,MAPLOW,MAPHIGH)
C imported: old values in S(1..N)
C           maplow and maphigh
C target limits SMAX, SMIN
C exported: new values in S(1..N)
C internal: SHI, SLO
C SHI.........*.........SLO      map this interval onto
C      SMAX...*...SMIN               this interval or 
C      MAPLOW     MAPHIGH
      REAL S(*),MAPLOW,MAPHIGH,SMIN,SMAX,SHI,SLO
      SHI=-1.0E+10
      SLO=1.0E+10
      IF (SMIN.EQ.0.0 .AND. SMAX.EQ.0.0 .AND. 
     +     MAPLOW.EQ.0.0 .AND. MAPHIGH.EQ.0.0) THEN
         WRITE(*,*)' SCALEINTERVAL: NO SCALING '
         RETURN
      ENDIF
      IF (MAPLOW.EQ.0.0 .AND. MAPHIGH.EQ.0.0) THEN
c     WRITE(*,*)' SCALEINTERVAL: scale between SMIN/SMAX'
         DO I=1,N
            IF (S(I) .GT. SHI)SHI=S(I)
            IF (S(I) .LT. SLO)SLO=S(I)
         ENDDO
      ELSE
         WRITE(*,*)' SCALEINTERVAL: scale between MAPLOW/MAPHIGH'
         SHI=MAPHIGH
         SLO=MAPLOW
      ENDIF
c	write(*,*)'high/low: ',shi,slo,n,(SHI-SLO),(SMAX-SMIN)+SMIN 
      DO I=1,N
         S(I)=((S(I)-SLO)/(SHI-SLO))*(SMAX-SMIN)+SMIN 
      ENDDO
c        WRITE(*,'(20F5.2)')(S(I),I=1,N)
      RETURN
      END
C     END  SCALEINTERVAL
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

      NN=MAXRES*NTRANS
C=======================================================================
C reset value for chain breaks etc...
C add 'X' '!' and "-"
      J=INDEX(TRANS,'X')
      K=INDEX(TRANS,'!')
      L=INDEX(TRANS,'-')
      M=INDEX(TRANS,'.')
      IF (J.EQ.0 .OR. K.EQ.0 .OR. L.EQ.0 .or. M.eq. 0) THEN
         WRITE(*,*)'*** ERROR: "X","!","-" or "." unknown in '//
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
         WRITE(*,*)'*** ERROR: "X","!","-" or "." unknown in '//
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
            IF ( INDEX(STR_STATES(J),STRUC(I)) .NE. 0) THEN
               GOTO 100
            ENDIF
         ENDDO
c	   iclass(i)=0
c           class(i:i)='U'
c	   write(*,*)' symbol not known in STR_TO_CLASS: ',struc(i)
 100     ICLASS(I)=J
         CLASS(I:I)=STR_STATES(J)(1:1)
c	   write(*,*)i,j,iclass(i),str_states(j)(1:1)
      ENDDO

      RETURN
      END
C     END STR_TO_CLASS
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
         WRITE(*,*)CSTRING(ICUTBEGIN(I):ICUTEND(I))
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
      line=' SeqNo  PDBNo AA STRUCTURE BP1 BP2  ACC NOCC  '//
     +     'OPEN ELONG  WEIGHT   '//
     +     'V       L       I       M       F       W       Y       '//
     +     'G       A       P       S       T       C       H       '//
     +     'R       K       Q       E       N       D'
      CALL STRPOS(LINE,ISTART,ISTOP)
      WRITE(KPROF,'(A)')LINE(:ISTOP)

      DO I=1,NRES
         IF (I.GT.MAXRES) THEN
            write(*,*)' *** ERROR IN WRITEPROFILE: NRES.GT.MAXRES'
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


