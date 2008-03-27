C---- ------------------------------------------------------------------
C---- contains now all previously needed libraries for Schneider stuff
C---- ------------------------------------------------------------------
C this library contains subroutines which are system specific things, 
C like get the actual date, time, open a file etc.
C ===> have one system-lib.for for VMS, UNIX is nix (SGI/PARIX).... machines
C      and link them.

C======================================================================
C......................................................................
C     SUB GETDATE
C     returns date in a string of implied length
C     UNIX version
      SUBROUTINE GETDATE(DATE)
      CHARACTER*(*) DATE
      CHARACTER CTEMP*24
      CHARACTER DAY*2, MONTH*3, YEAR*2
      
      DATE=' '
      CTEMP=' '
      CALL FDATE(CTEMP)
      MONTH = CTEMP(5:7)
      DAY = CTEMP(9:10)
      YEAR = CTEMP(23:24)
      DATE = (((DAY // '-') // MONTH) // '-') // YEAR
      RETURN 
      END
C     END GETDATE
C......................................................................

C......................................................................
C     SUB GETTIME(CTIME)
      SUBROUTINE GETTIME(CTIME)
c     returns time in a string of implied length
      CHARACTER CTIME*(*)
      CHARACTER*24 CTEMP
      CTEMP = ' '
      CALL FDATE(CTEMP)
      CTIME(1:)=CTEMP(11:22)

      RETURN
      END
C     END GETTIME(CTIME)
C......................................................................

C......................................................................
CCxC     SUB GET_CURRENT_DIR
CCxC     returns path name of the current directory
CCxC     SGI/UNIX version
CCx      SUBROUTINE GET_CURRENT_DIR(DIR_NAME)
CCx      CHARACTER*(*) DIR_NAME
CCx      INTEGER       GETCWD,ITEST
CCx      
CCx      ITEST=0
CCx      DIR_NAME=' '
CCx      ITEST=GETCWD(DIR_NAME)
CCx      IF (ITEST .NE. 0) THEN
CCx         WRITE(*,*)' GETCWD FAILED '
CCx         WRITE(*,*)' ERROR CODE IS: ',ITEST
CCx      ENDIF
CCx      RETURN 
CCx      END

C     the following is from SGI correct?

C     returns path name of the current directory
C     SGI/UNIX version
      SUBROUTINE GET_CURRENT_DIR(DIR_NAME)
      CHARACTER*(*) DIR_NAME
      INTEGER ILEN
      CHARACTER*128 TEMP_NAME
      
      TEMP_NAME=' '
C     CALL GETCWD(TEMP_NAME)
      DIR_NAME=' '
      ILEN=LEN(DIR_NAME)
      IEND=MIN(128,ILEN)
      DIR_NAME=TEMP_NAME(1:IEND)
      RETURN 
      END


C     END GET_CURRENT_DIR
C......................................................................

C......................................................................
C     SUB GET_ENVIROMENT_VARIBALE
C     RETURNS VALUE OF ENVIROMENT VARIABLE
C     UNIX version
      SUBROUTINE GET_ENVIROMENT_VARIABLE(ENV_VAR,VARIABLE)
      CHARACTER*(*) ENV_VAR,VARIABLE
      
      VARIABLE=' '
      CALL STRPOS(ENV_VAR,IBEG,IEND)
      CALL GETENV(ENV_VAR(IBEG:IEND),VARIABLE)
      RETURN 
      END
C END GET_ENVIROMENT_VARIABLE
C......................................................................

C......................................................................
C     SUB GET_MACHINE_NAME
c     returns current machine name
c     UNIX version
      SUBROUTINE GET_MACHINE_NAME(MACHINE_NAME)
      CHARACTER*(*) MACHINE_NAME
      INTEGER HOSTNM,ITEST
      
      ITEST=0
      MACHINE_NAME=' '
      ITEST=HOSTNM(MACHINE_NAME)
      IF (ITEST .NE. 0) THEN
         WRITE(*,*)' hostnm failed !!'
         WRITE(*,*)' error code is: ',itest
      ENDIF
      RETURN 
      END
C     END GET_MACHINE_NAME
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
C     SUB CHANGE_MODE
      SUBROUTINE CHANGE_MODE(FILENAME,MODE,IRETURN_VAL)
c     changes the mode of a file via the integer function "chmod"
c import
      CHARACTER*(*) FILENAME,MODE
c export
      INTEGER IRETURN_VAL
c internal
      INTEGER CHMOD

      CALL STRPOS(FILENAME,IBEG,IEND)
      CALL STRPOS(MODE,JBEG,JEND)
      IRETURN_VAL=CHMOD(FILENAME(IBEG:IEND),MODE(JBEG:JEND))
      IF (IRETURN_VAL .NE. 0) THEN
         WRITE(*,*)' *** ERROR IN CHANGE_MODE:***'
         WRITE(*,*)'     MODE CHANGE NOT PERFORMED !'
         WRITE(*,*)'     MODE: ',MODE(JBEG:JEND)
         WRITE(*,*)'     FILE: ',FILENAME(IBEG:IEND)
      ENDIF
      RETURN
      END
C     END CHANGE_MODE
C......................................................................

C......................................................................
C     SUB GET_CPU_TIME
C     get elapsed CPU time between two calls of GET_CPU_TIME
C     total_time  = elapsed CPU time
C     user_time   =  used user CPU time
C     system_time = used system CPU time
      SUBROUTINE GET_CPU_TIME(CSTRING,IDPROC,ITIME_OLD,
     +     ITIME_NEW,TOTAL_TIME,LOGSTRING)
C import export
      CHARACTER CSTRING*(*)
      CHARACTER LOGSTRING*(*)
      INTEGER IDPROC
      INTEGER ITIME_OLD(*),ITIME_NEW(*)
      REAL TOTAL_TIME
C internal
      INTEGER IBEG,IEND
      REAL XTIME(2),TOTAL

      XTIME(1)=0.0
      XTIME(2)=0.0

      TOTAL  = DTIME(XTIME)
      TOTAL_TIME = TOTAL_TIME + TOTAL

      CALL STRPOS(CSTRING,IBEG,IEND)
      WRITE(LOGSTRING,'(A,I6,4(F10.2))')CSTRING(IBEG:IEND),
     +     IDPROC,TOTAL,XTIME(1),XTIME(2),TOTAL_TIME

      RETURN
      END
C     END GET_CPU_TIME
C......................................................................

C......................................................................
C     SUB INIT_CPU_TIME
      SUBROUTINE INIT_CPU_TIME(ITIME_OLD)
C import export
      INTEGER ITIME_OLD(*)
C internal
      REAL XTIME(2),TOTAL
      
      XTIME(1)=0.0
      XTIME(2)=0.0

      TOTAL  = DTIME(XTIME)
	
      RETURN
      END
C     END INIT_CPU_TIME
C......................................................................

C......................................................................
C     SUBROUTINE GET_CPU_TIME
C     get elapsed CPU time between two calls of GET_CPU_TIME
C     total_time  = elapsed CPU time
C     user_time   =  used user CPU time
C     system_time = used system CPU time
c     subroutine get_cpu_time(total_time,user_time,system_time)
C export
c	real total_time, user_time,system_time
C internal
c	real xtime(2)

c	xtime(1)=0.0
c	xtime(2)=0.0

c	total_time  = dtime(xtime)
c	user_time   = xtime(1)
c	system_time = xtime(2)
c	write(*,*)'   total    user  system'
c	write(*,'(3(1x,f7.2))')total_time,user_time,system_time

c	return
c	end
C     END GET_CPU_TIME
C......................................................................


C......................................................................
C     SUB OPEN_FILE
      SUBROUTINE OPEN_FILE(IUNIT,FILENAME_IN,CSTRING,LERROR)
      IMPLICIT NONE
C---- input
C     CSTATUS: 'OLD' OR 'NEW' OR 'UNKNOWN'
C     CACCESS: 'APPEND' 'DIRECT'
C     FORM:    'FORMATTED' OR 'UNFORMATTED'
C     IRECLEN: RECORD LENGTH
C     NOTE:    after opening an "OLD" or "UNKNOWN" file
C              (no direct ACESS): 
C              REWIND file, because some strange compilers put file 
C              pointer at the end!
C
      CHARACTER*(*)  FILENAME_IN,CSTRING
      INTEGER        IUNIT,IRECLEN
C---- output: lerror is true if open error
      LOGICAL        LERROR
C---- internal
      CHARACTER*200 TEMPSTRING,CTEMP,FILENAME
      CHARACTER*10   CNUMBER
      LOGICAL        LNEW,LAPPEND,LUNKNOWN,LUNFORMATTED,LDIRECT,
     +               LOPENDONE,LSILENT,LREADONLY,LRECLEN
      INTEGER        IBEG,IEND,LENGTH,I,J,K

C---- ------------------------------------------------------------
C     initialise values
C---- ------------------------------------------------------------
      TEMPSTRING=   ' '
      FILENAME=     ' '
      LNEW=         .FALSE.
      LAPPEND=      .FALSE.
      LERROR=       .FALSE.
      LUNKNOWN=     .FALSE.
      LUNFORMATTED= .FALSE.
      LDIRECT=      .FALSE.
      LOPENDONE=    .FALSE.
      LSILENT=      .FALSE.
      IRECLEN=       137
      TEMPSTRING(1:)=CSTRING(1:)
      CNUMBER=       '0123456789'
C---- 
      LENGTH=LEN(TEMPSTRING)
      CALL LOWTOUP(TEMPSTRING,LENGTH)
      IF (INDEX(TEMPSTRING,'NEW').NE.0) THEN
         LNEW=.TRUE.
      ENDIF
      IF (INDEX(TEMPSTRING,'UNKNOWN').NE.0) THEN
         LUNKNOWN=.TRUE.
      ENDIF
      IF (INDEX(TEMPSTRING,'UNFORMATTED').NE.0) THEN
         LUNFORMATTED=.TRUE.
      ENDIF
      IF (INDEX(TEMPSTRING,'DIRECT').NE.0) THEN
         LDIRECT=.TRUE.
      ENDIF
      IF (INDEX(TEMPSTRING,'APPEND').NE.0) THEN
         LAPPEND=.TRUE.
      ENDIF
      IF (INDEX(TEMPSTRING,'READONLY').NE.0) THEN
         LREADONLY=.TRUE.
      ENDIF
      IF (INDEX(TEMPSTRING,'SILENT').NE.0) THEN
         LSILENT=.TRUE.
      ENDIF
      IF (INDEX(TEMPSTRING,'RECL=').NE.0) THEN
         CTEMP=' '
         K=INDEX(TEMPSTRING,'RECL=')+5
         J=LEN(TEMPSTRING)
         CTEMP(1:)=TEMPSTRING(K:J)
         J=INDEX(CTEMP,' ')-1
         
         CALL STRPOS(CTEMP,I,J)
c	  J=I
c	  DO WHILE (INDEX(CNUMBER,CTEMP(J:J)).NE.0 )
c             J=J+1
c	  ENDDO
c	  J=J-1

         READ(CTEMP(I:J),'(I6)')IRECLEN
         LRECLEN=.TRUE.
c	  write(*,*)'record length: ',ireclen
      ENDIF

      CALL STRPOS(FILENAME_IN,IBEG,IEND)
      FILENAME(1:(1+IEND-IBEG))=FILENAME_IN(IBEG:IEND)

C---- security: delete existing file if file to be generated
      IF (LNEW) THEN
         CALL DEL_OLDFILE(IUNIT,FILENAME)
      ENDIF

C---- 
C---- different parameters
C---- 
      IF (LNEW .AND. LUNFORMATTED .AND. LDIRECT) THEN
         OPEN(IUNIT,FILE=FILENAME,STATUS='NEW',FORM='UNFORMATTED',
     +        ACCESS='DIRECT',RECL=IRECLEN)
         LOPENDONE=.TRUE.
      ELSEIF (LNEW .AND. LUNFORMATTED ) THEN
         OPEN(IUNIT,FILE=FILENAME,STATUS='NEW',FORM='UNFORMATTED',
     +        RECL=IRECLEN)
         LOPENDONE=.TRUE.
      ELSEIF (LNEW .AND. .NOT. LUNFORMATTED .AND. LDIRECT ) THEN
         OPEN(IUNIT,FILE=FILENAME,ACCESS='DIRECT',STATUS='NEW',
     +        FORM='FORMATTED',CARRIAGECONTROL='LIST',
     +        RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW .AND. LUNFORMATTED 
     +        .AND. LDIRECT .AND. LREADONLY) THEN
         OPEN(IUNIT,FILE=FILENAME,STATUS='OLD',FORM='UNFORMATTED',
     +        ACCESS='DIRECT',RECL=IRECLEN,READONLY,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW .AND. LUNFORMATTED 
     +        .AND. LDIRECT .AND. .NOT. LREADONLY) THEN
         OPEN(IUNIT,FILE=FILENAME,STATUS='OLD',FORM='UNFORMATTED',
     +        ACCESS='DIRECT',RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW .AND. .NOT. LUNFORMATTED 
     +        .AND. LDIRECT .AND. LREADONLY) THEN
         OPEN(IUNIT,FILE=FILENAME,STATUS='OLD',FORM='FORMATTED',
     +        ACCESS='DIRECT',RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW .AND. .NOT. LUNFORMATTED 
     +        .AND. LDIRECT .AND. .NOT. LREADONLY) THEN
         OPEN(IUNIT,FILE=FILENAME,STATUS='OLD',FORM='FORMATTED',
     +        ACCESS='DIRECT',RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW .AND. LUNFORMATTED .AND. LREADONLY) THEN
         OPEN(IUNIT,FILE=FILENAME,STATUS='OLD',FORM='UNFORMATTED',
     +        RECL=IRECLEN,READONLY,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW .AND. LUNFORMATTED .AND. .NOT. LREADONLY) THEN
         OPEN(IUNIT,FILE=FILENAME,STATUS='OLD',FORM='UNFORMATTED',
     +        RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (LNEW .AND. LRECLEN) THEN
         OPEN(IUNIT,FILE=FILENAME,CARRIAGECONTROL='LIST',STATUS='NEW',
     +        RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (LNEW) THEN
         OPEN(IUNIT,FILE=FILENAME,CARRIAGECONTROL='LIST',STATUS='NEW',
     +        RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW .AND. LREADONLY) THEN
         OPEN(IUNIT,FILE=FILENAME,CARRIAGECONTROL='LIST',STATUS='OLD',
     +	      RECL=IRECLEN,READONLY,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (LUNKNOWN .AND. LAPPEND) THEN
         OPEN(IUNIT,FILE=FILENAME,CARRIAGECONTROL='LIST',
     +        STATUS='UNKNOWN',ACCESS='APPEND',RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW .AND. LAPPEND) THEN
         OPEN(IUNIT,FILE=FILENAME,CARRIAGECONTROL='LIST',
     +        STATUS='OLD',ACCESS='APPEND',RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSEIF (.NOT. LNEW) THEN
         OPEN(IUNIT,FILE=FILENAME,CARRIAGECONTROL='LIST',STATUS='OLD',
     +        RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ELSE
         OPEN(IUNIT,FILE=FILENAME,CARRIAGECONTROL='LIST',
     +        STATUS='UNKNOWN',RECL=IRECLEN,ERR=999)
         LOPENDONE=.TRUE.
      ENDIF
      IF (.NOT. LOPENDONE) THEN
         WRITE(*,*)' ERROR in OPEN_FILE: file not opened'
         WRITE(*,*)'  unknown specifier combination !'
         STOP
      ENDIF
      RETURN
 999  IF (.NOT. LSILENT) THEN
         WRITE(*,*)'*** ERROR: open file error for file: '
         WRITE(*,*)'***  name: ',FILENAME(1:(1+IEND-IBEG))
         WRITE(*,*)'***  unit: ',iunit
      ENDIF
      LERROR=.TRUE.
      RETURN
      END
C     END OPEN_FILE
C......................................................................

C......................................................................
C     SUB CLOSE_FILE
      SUBROUTINE CLOSE_FILE(IUNIT,FILENAME)
      INTEGER IUNIT
      CHARACTER*(*) FILENAME
      LOGICAL LOPEN
      
      INQUIRE(FILE=FILENAME,OPENED=LOPEN)
      IF (LOPEN) THEN
         CLOSE(IUNIT)
      ENDIF
      RETURN
      END
C     END CLOSE_FILE
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
C     SUB FLUSH
      SUBROUTINE FLUSH_UNIT(IUNIT)
      INTEGER IUNIT
      
      CALL FLUSH(IUNIT)
      
      RETURN
      END
C     END FLUSH
C......................................................................

C......................................................................
C     SUB C_PARIOINIT
      SUBROUTINE C_PARIOINIT(INODE,ILINK,HOSTNAME,ILEN)
      INTEGER INODE,ILEN,ILINK(*)
      CHARACTER*(*) HOSTNAME
      
      HOSTNAME=' '
      
      RETURN
      END
C     END C_PARIOINIT
C......................................................................

