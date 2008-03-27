*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*----------------------------------------------------------------------*
***** ------------------------------------------------------------------
***** internal navigation:
***** 
***** MAIN NN
*****      -> main program
***** FUNCTIONS fff
*****      -> sorted alphabetically
***** SUBROUTINES sss
*****      -> sorted alphabetically
***** 
***** for further details: Doc-nn.txt
***** 
***** ------------------------------------------------------------------

***** ------------------------------------------------------------------
***** MAIN NN
***** ------------------------------------------------------------------
      PROGRAM NN
C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       ITER,STPTMP
      INTEGER       FILEN_STRING
      REAL          TIME0,SECNDS
C      CHARACTER*80  INTERFILEBANK
      CHARACTER*132 HC
      LOGICAL       LWRITE,LERR,LBIN

******------------------------------*-----------------------------******
*     LWRITE        controls whether calls of time and date are written*
*                   into the printer                                   *
*     SECNDS        external function returning seconds elapsed since  *
*                   midnight                                           *
******------------------------------*-----------------------------******

C---- ------------------------------------------------------------------
C---- input  (getting started)
C---- ------------------------------------------------------------------

C----
C---- command line
C----
C     get number of command line argumentss
      CALL GET_ARG_NUMBER(NUMARGUMENTS)
C     too many arguments?
      IF (NUMARGUMENTS.GT.NUMARG_MAX) THEN
         WRITE(6,'(T2,A,T10,A)')'***','ERROR: NN too many cmd line args'
         STOP
      END IF
C     get command line arguments
      DO ITER=1,NUMARGUMENTS
         CALL GET_ARGUMENT(ITER,PASSED_ARGC(ITER))
      END DO
*                                                                      *
C---- 
C---- general stuff for CPU time
C---- 
C     run time
      TIMEFLAG=.FALSE.
      LWRITE=.FALSE.
      CALL SRDTIME(1,LWRITE)
      LWRITE=.FALSE.
      CALL SCFDATE(1,LWRITE,STARTDATE)
C     elapsed time: real: seconds since midnight-supplied arg
      TIME0=0.0
      TIMESTART=SECNDS(TIME0)

      LERR=.TRUE.
      LBIN=.TRUE.
C----
C---- initialise parameters and read command line
C----
      CALL ININN
C----
C---- read files
C----
C     read parameters 
      IF (LOGI_RDPAR) THEN
         CALL RDPAR
      END IF
C     read input vectors 
      IF (LOGI_RDIN) THEN
         CALL RDIN
      END IF

C     read output vectors 
      IF (LOGI_RDOUT) THEN
         CALL RDOUT
      END IF
C     read succession of training
      IF (STPSWPMAX.GT.0) THEN
         CALL RDSAM
      END IF
C     read junctions (only if training from tabula rasa)
      IF (FILEIN_JCT(1:3).NE.'NEW') THEN
         CALL RDJCT
      ELSE
         CALL INIJCT
C         CALL WRTJCT(10,FILEOUT_JCT(1))
      END IF
C     ini threshold units
      CALL INITHRUNT
C     security
      IF (BITACC.EQ.0) THEN
         WRITE(6,'(A)')'*** ERROR MAIN BITACC MAY NOT be zero'
         STOP '*** ERROR MAIN BITACC not set'
      END IF

C---- ------------------------------------------------------------------
C---- network training, or triggering
C---- ------------------------------------------------------------------

C---- ------------------------------
C---- network switch only
      IF (STPSWPMAX.EQ.0) THEN
C----                                1st: Lerr, 2nd: Lbin, 3rd: stp
         IF (LOGI_SWITCH) THEN
            LERR=.FALSE.
            LBIN=.FALSE.
         ELSE
            LERR=.TRUE.
            LBIN=.TRUE.
         END IF
         CALL NETOUT(LERR,LBIN,1)
C----                                stp=1 for all
         CALL WRTOUT(10,FILEOUT_OUT(1),1,1)
         IF (.NOT.LOGI_SWITCH) THEN
            CALL WRTJCT(10,FILEOUT_JCT(1))
         END IF

C---- ------------------------------
C---- training
      ELSE
C------- optimized online training
         IF (NUMLAYERS.EQ.2) THEN
C           **********
            CALL TRAIN
C           **********
         ELSE
            WRITE(6,*)'*** TRAINPERC not yet implemented'
            STOP
C           **************
C            CALL TRAINPERC
C           **************
         END IF
      END IF

C---- ------------------------------------------------------------------
C---- output
C---- ------------------------------------------------------------------
*                                                                      *

C---- write results onto printer
      IF (.NOT.LOGI_SWITCH) THEN
         IF (STPSWPMAX.EQ.0) STPTMP=1
         IF (STPSWPMAX.GT.0) STPTMP=STPINFCNT
         CALL WRTSCR(STPTMP)
         CALL WRTERR(10,FILEOUT_ERR,STPTMP)
         CALL WRTYEAH(10,FILEOUT_YEAH)
      ELSEIF (LOGI_DEBUG .AND. 
     +        FILEOUT_OUT(1)(1:4).NE.'none') THEN
         WRITE(6,'(A,A)')
     +        '--- NN finished fine! FILEOUT=',
     +        FILEOUT_OUT(1)(1:FILEN_STRING(FILEOUT_OUT(1)))  
      END IF

      END
***** end of NN

***** ------------------------------------------------------------------
***** FUNCTIONS fff
***** ------------------------------------------------------------------

***** ------------------------------------------------------------------
***** FCT TRG1ST
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRG1ST
C---- ARG  : x
C---- DES  : This sigmoid function works as a trigger generating in
C---- DES  : layer l an output between 0 and 1 from the input (local 
C---- DES  : filed) of the previous layer (l-1).  Thus TRG1ST 
C---- DES  : determins the state of the  'neurons' in layer l. 
C---- DES  : 
C---- DES  : The particular choice (any monotonically increasing 
C---- DES  : function that can be differentiated will do) is:
C---- DES  :    TRG1ST (x) = 1./ (1.+exp(-x))  
C---- DES  : the derivation is given by: 
C---- DES  :    f''(x)=f(x)*( 1-f(x) ) ] 
C---- IN   : input parameters are the 'local fields' 
C---- FROM :
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     CUBIC/LION                http://cubic.bioc.columbia.edu         *
*     Columbia University       rost@columbia.edu                      *
*                      changed: Mar,        1994        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      REAL FUNCTION TRG1ST (X)
      IF (X.LT.-50) THEN
         TRG1ST=0.
      ELSEIF (X.GT.50) THEN
         TRG1ST=1.
      ELSE
         TRG1ST = 1./ ( 1. + EXP (-X) )
      END IF
      END
***** end of TRG1ST

***** ------------------------------------------------------------------
***** SUB TRG2ND
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRG2ND
C---- ARG  : X
C---- DES  : see TRG1ST 
C---- 
*     procedure:    
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     CUBIC/LION                http://cubic.bioc.columbia.edu         *
*     Columbia University       rost@columbia.edu                      *
*                      changed: Mar,        1994        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      REAL FUNCTION TRG2ND (X)
      IF (X.LT.-50) THEN
         TRG2ND=0.
      ELSEIF (X.GT.50) THEN
         TRG2ND=1.
      ELSE
         TRG2ND = 1./ ( 1. + EXP (-X) )
      END IF
      END
***** end of TRG2ND

***** ------------------------------------------------------------------
***** FCT TRGNORM
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRGNORM
C---- ARG  :  
C---- DES  : The normal trigger function f(h(i)) with df/dh(j)
C---- DES  : =0 is substituted by a function containing the sum 
C---- DES  : over all output fields as a normalization 
C---- 
C---- NOTE : f''(h)=f(h)( 1-f(h) ) 
C---- NOTE :   i.e., the same as for TRG1ST, and TRG2ND
C---- 
*     procedure:    
*----------------------------------------------------------------------*
*     Burkhard Rost             Aug,        1998        version 1.0    *
*     CUBIC/LION                http://cubic.bioc.columbia.edu         *
*     Columbia University       rost@columbia.edu                      *
*                      changed: Mar,        1994        version 0.1    *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      REAL FUNCTION TRGNORM (X)
      INCLUDE       'nnPar.f'
      INTEGER       ITOUT
      REAL          X,HELPSUM
      HELPSUM=0.
      IF (NUMLAYERS.EQ.1) THEN
         DO ITOUT=1,NUMOUT
            HELPSUM=EXP(FLD1ST(ITOUT))
         END DO
      ELSE
         WRITE(6,*)' NUMLAYERS>1 not yet implemented for TRGNORM'
         STOP
      END IF
      TRGNORM=(1./HELPSUM)*EXP(X)
      END
***** end of TRGNORM


***** ------------------------------------------------------------------
***** SUBROUTINES sss
***** ------------------------------------------------------------------

***** ------------------------------------------------------------------
***** SUB ININN
***** ------------------------------------------------------------------
C---- 
C---- NAME : ININN
C---- ARG  : 
C---- DES  : Parameters (numbers, characters, flags) for executing a
C---- DES  : particular NN job are initially assigned.
C---- IN   : PASSED_ARGC (common)
C---- OUT  : setting of initial defaults     
C---- FROM : MAIN 
C---- CALL2: INIPAR_CON, INIPAR_DEFAULT, INIPAR_ASK 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University       rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE ININN

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local functions
C      INTEGER         FILEN_STRING
C---- local variables
      INTEGER       IT
C      LOGICAL       LTEST,LTESTTRN
      LOGICAL       LHELP,LERROR
      CHARACTER*80  ARG1,ARG2
******------------------------------*-----------------------------******
C---- get help?
      LHELP=.FALSE.
      LERROR=.FALSE.
      IF (NUMARGUMENTS.LT.1) THEN
         LERROR=.TRUE.
      ELSEIF ((NUMARGUMENTS.EQ.1).AND.
     +        (INDEX(PASSED_ARGC(1),'help').NE.0)) THEN
         LHELP=.TRUE.
      END IF
      IF (LERROR) THEN
         WRITE(6,'(A,T5,A)')'---','start program with:'
         WRITE(6,'(A,T5,A)')'---','      exe [help]'
         WRITE(6,'(A,T5,A)')'---','or:   exe fPar'
         WRITE(6,'(A,T5,A)')'---','or:   exe [inter] '
         WRITE(6,'(A,T5,A)')'---','          (will bring up dialog)'
         STOP
      ELSEIF (LHELP) THEN
         WRITE(6,'(A,T5,A)')'---','start the program with:'
         WRITE(6,'(A,T5,A)')'---','      exe [inter] '
         WRITE(6,'(A,T5,A)')'---','          (will bring up dialog)'
         WRITE(6,'(A,T5,A)')'---','          '
         WRITE(6,'(A,T5,A)')'---','or:   exe filePar '
         WRITE(6,'(A,T5,A)')'---','      filePar = file with input'//
     +        ' parameters (also gives fileIn, fileOut)'
         WRITE(6,'(A,T5,A)')'---','          '
         WRITE(6,'(A,T5,A)')'---','or:   exe switch AND_following_args'
         WRITE(6,'(A,T5,A)')'---','          '
         WRITE(6,'(A,T5,A)')'---','       1: "switch"'
         WRITE(6,'(A,T5,A)')'---','       2: number of input units'
         WRITE(6,'(A,T5,A)')'---','       3: number of hidden units'
         WRITE(6,'(A,T5,A)')'---','       4: number of output units'
         WRITE(6,'(A,T5,A)')'---','       5: number of samples'
         WRITE(6,'(A,T5,A)')'---','       6: bitacc (typically 100)'
         WRITE(6,'(A,T5,A)')'---','       7: file with input vectors'
         WRITE(6,'(A,T5,A)')'---','       8: file with junctions'
         WRITE(6,'(A,T5,A)')'---','       9: file with output of NN'
         WRITE(6,'(A,T5,A)')'---','          ="none" -> no file written'
         WRITE(6,'(A,T5,A)')'---','      10: optional=dbg'
         WRITE(6,'(A,T5,A)')'---','      NOTES:'
         WRITE(6,'(A,T5,A)')'---','        - 1st MUST be "switch"!'
         WRITE(6,'(A,T5,A)')'---','        - tested only with 2 layers!'
         WRITE(6,'(A,T5,A)')'---','          '
         WRITE(6,'(A,T5,A)')'---','SORRY no further help, yet!'
         STOP
      END IF
C---- usually untouched constants
      CALL INIPAR_CON
C---- handle the arguments passed to program
      DO IT=(NUMARGUMENTS+1),NUMARG_MAX
         PASSED_ARGC(IT)='UNK'
      END DO
C---- --------------------------------------------------
C---- initialising according to input read
      ARG1=PASSED_ARGC(1)
      IF (NUMARGUMENTS.GT.1) ARG2=PASSED_ARGC(1)

C---- ask for input
      IF ((ARG1(1:5).EQ.'INTER').OR.(ARG1(1:5).EQ.'inter')) THEN
         CALL INIPAR_DEFAULT
         LOGI_INTERACTIVE=.TRUE.
         CALL INIPAR_ASK

C---- ask for input
      ELSE IF ((ARG1(1:6).EQ.'switch').OR.(ARG1(1:6).EQ.'switch')) THEN
         CALL INIPAR_DEFAULT
         LOGI_SWITCH=  .TRUE.
         CALL INIPAR_SWITCH

C---- read input from files
      ELSE
         FILEIN_PAR= ARG1
         LOGI_RDPAR= .TRUE.
         LOGI_RDIN=  .TRUE.
         LOGI_RDOUT= .TRUE.
         IF (NUMARGUMENTS.GT.1 .AND. ARG2(1:3).EQ.'dbg') THEN
            LOGI_DEBUG= .TRUE.
         END IF
      END IF
      
C---- end of initialising the main stuff
C---- --------------------------------------------------
*                                                                      *
      END
***** end of ININN

***** ------------------------------------------------------------------
***** SUB INIPAR_ASK
***** ------------------------------------------------------------------
C---- 
C---- NAME : INIPAR_ASK
C---- ARG  : 
C---- DES  : Asking for input parameters 
C---- DES  : 
C---- IN   : 
C---- FROM : ININN  
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University       rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE INIPAR_ASK

C---- include parameter files
      INCLUDE       'nnPar.f'
      INTEGER       IH(1:2)
      CHARACTER*132 FILETMP
******------------------------------*-----------------------------******
      CALL GETCHAR(80,PATH_ARCH,' path of architectures ? ')

      CALL GETCHAR(80,FILEIN_PAR,' parameter file? (`i` if interactive')
      IF ((INDEX(FILEIN_PAR,'i').NE.0) .OR. 
     +     (INDEX(FILEIN_PAR,'I').NE.0) ) THEN
         LOGI_RDPAR= .TRUE.
      ELSE
         WRITE(6,*)'*** missing ini.f: ask for parameters'
         STOP
      END IF

      CALL GETCHAR(80,FILETMP,' input file? (`i` if interactive')
      IF ((FILETMP(1:1).EQ.'i').OR.(FILETMP(1:1).EQ.'I')) THEN
         LOGI_RDIN=  .TRUE.
      ELSE
         WRITE(6,*)'*** missing ini.f: ask for input data'
         STOP
      END IF

      CALL GETCHAR(80,FILETMP,' output file? (`i` if interactive')
      IF ((FILETMP(1:1).EQ.'i').OR.(FILETMP(1:1).EQ.'I')) THEN
         LOGI_RDOUT= .TRUE.
      ELSE
         WRITE(6,*)'*** missing ini.f: ask for parameters'
         STOP
      END IF

C      CALL ASK(' realinput ? ',LOGI_REALINPUT)
C      IH(1)=INT(MAXQ3*100)
C      CALL GETINT(1,IH(1),' 100 * MAXQ3 (i.e. for 0.95 give 95) ')

      IH(1)=STPINF
      CALL GETINT(1,IH(1),' STPINF ')
      STPINF=IH(1)
      IH(1)=STPMAX
      CALL GETINT(1,IH(1),' STPMAX ')
      STPMAX=IH(1)
      IH(1)=STPSWPMAX
      CALL GETINT(1,IH(1),' STPSWPMAX ')
      STPSWPMAX=IH(1)

      IH(1)=INT(EPSILON*100)
      CALL GETINT(1,IH(1),' 100 * EPSILON ')
      EPSILON=IH(1)/100.
      IH(1)=INT(ALPHA*100)
      CALL GETINT(1,IH(1),' 100 * ALPHA ')
      ALPHA=IH(1)/100.
      IH(1)=INT(TEMPERATURE*100)
      CALL GETINT(1,IH(1),' 100 * TEMPERATURE ')
      TEMPERATURE=INT(IH(1)/100.)


      END
***** end of INIPAR_ASK

***** ------------------------------------------------------------------
***** SUB INIPAR_CON
***** ------------------------------------------------------------------
C---- 
C---- NAME : INIPAR_CON
C---- ARG  : 
C---- DES  : Initialising constants that are usually not touched
C---- IN   : 
C---- FROM : ININN 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University       rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE INIPAR_CON

C---- include parameter files
      INCLUDE       'nnPar.f'
******------------------------------*-----------------------------******
C---- --------------------------------------------------
*     Various numerical constants
C----                                number of layers
      NUMLAYERS=            2
C----                                grids ...
      BITACC=               1
C                                    (if out<ERRBINACC -> outbin=0)
      ERRBINACC=            0.2
C----                                end, bias asf.
      ERRBIAS=              0.0
C      ERRBIAS=              0.05
      ERRSTOP=              0.005
      ERRBINSTOP=           0.95
      THRESHOUT=            0.5
      DICEITRVL=            0.1
C----                                random number generation
      DICESEED=        100025
      DICESEED_ADDJCT=      0
      DICESEED_ADDTRN=      0
      ABW=                  10E-10
C      ABW=                  0.00001
      MAXCPUTIME=     1000000.
      TIMEOUT=            300.

C---- --------------------------------------------------
*     Various flags and names
C----                                modes
      TRGTYPE=         '1/(1+EXP(-X))'
      TRNTYPE=         'ONLINE'
      ERRTYPE=         'DELTASQ'
C      ERRTYPE=         'LN(1-DELTASQ)'

C----                                temporary output
      LOGI_TMPWRTOUT=  .FALSE.
      LOGI_TMPWRTJB=   .FALSE.
C---- 
      LOGI_TRANSLATE(0)=.FALSE.
      LOGI_TRANSLATE(1)=.TRUE.
C----                                ------------------------------
C      ------------
C      alternatives
C      ------------
C      TRGTYPE='EXP(X(I))/SUM(J,EXP(X(J)))'
C      TRNTYPE='BATCH'
C      ERRTYPE='LN(1-DELTASQ)'
C----            ---------------------------------------------------
*                                                                      *
      END
***** end of INIPAR_CON

***** ------------------------------------------------------------------
***** SUB INIPAR_DEFAULT
***** ------------------------------------------------------------------
C---- 
C---- NAME : INIPAR_DEFAULT
C---- ARG  : 
C---- DES  : Initialising constants                             
C---- IN   : 
C---- FROM : ININN   
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University       rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE INIPAR_DEFAULT

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local functions
C      INTEGER       FILEN_STRING
******------------------------------*-----------------------------******
C---- --------------------------------------------------
C---- set path for architecture files
      PATH_ARCH=' '
      LENPATH_ARCH=     1

C---- --------------------------------------------------
C---- architecture 
C----                                number of hidden units
      NUMHID=          15
C----                                number of layers (now <= 2)
      NUMLAYERS=        2

C---- --------------------------------------------------
C---- end, cycles asf
C----                                cycles and info per cycle
C              G  M  T
C----                                number of steps before write
      STPINF=       40000
C----                                maximal number of steps
      STPMAX=      200000
C----                                maximal number of sweeps
C----                                   STPMAX < NPATTERN*STSWPMAX
      STPSWPMAX=      200

C---- --------------------------------------------------
C---- speed
C----                                learning speed
      EPSILON=          0.05
C----                                momentum
      ALPHA=            0.20
C----                                speed reduction
      TEMPERATURE=      1.00

C---- --------------------------------------------------
C---- flags
      LOGI_INTERACTIVE= .FALSE.
      LOGI_SWITCH=      .FALSE.
      LOGI_DEBUG=       .FALSE.
C                                    input files
      LOGI_RDPAR=       .FALSE.
      LOGI_RDIN=        .FALSE.
      LOGI_RDOUT=       .FALSE.

      END
***** end of INIPAR_DEFAULT

***** ------------------------------------------------------------------
***** SUB INIPAR_SWITCH
***** ------------------------------------------------------------------
C---- 
C---- NAME : INIPAR_SWITCH
C---- ARG  : 
C---- DES  : switch mode: input to fortran script MUST be:
C---- DES  : arg  1= "switch" keyword!
C---- DES  : arg  2= number of input units
C---- DES  : arg  3= number of hidden units
C---- DES  : arg  4= number of output units
C---- DES  : arg  5= number of samples
C---- DES  : arg  6= bitacc (is typically 100)
C---- DES  : arg  7= file with input vectors
C---- DES  : arg  8= file with junctions
C---- DES  : arg  9= file with output of NN
C---- DES  :         if = 'none' no output file written
C---- DES  : arg 10= optional if set: debug mode
C---- DES  : 
C---- IN   : PASSED_ARGC(it) GLOBAL (nnPar.f)
C---- FROM : ININN  
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Dec,        1999      version 1.0      *
*----------------------------------------------------------------------*
      SUBROUTINE INIPAR_SWITCH

C---- include parameter files
      INCLUDE       'nnPar.f'
      INTEGER       FILEN_STRING
      INTEGER       IT,IH(1:10),CTNUM
      CHARACTER*132 FILETMP,VARIN
      CHARACTER*20  CTMP
******------------------------------*-----------------------------******

C---- 
C---- set defaults for SWITCH mode (1)
C---- 
      NUMFILEIN_IN=  1
      NUMFILEIN_OUT= 0
      NUMFILEOUT_OUT=1
C
      STPSWPMAX=     0
C
      LOGI_RDPAR=    .FALSE.
      LOGI_RDIN=     .TRUE.
      LOGI_RDOUT=    .FALSE.
      LOGI_RDINWRT=  .FALSE.
      LOGI_RDJCTWRT= .FALSE.
C 
      BITACC=        100

C---- 
C---- get integers (argument 2-5)
C---- 
      DO IT=2,6
         CALL SCHAR_TO_INT(PASSED_ARGC(IT),IH(IT))
      END DO
      NUMIN= IH(2)
      NUMHID=IH(3)
      NUMOUT=IH(4)
      NUMSAM=IH(5)
      BITACC=IH(6)

C---- 
C---- set dependent defaults for SWITCH mode (2)
C---- 
      NUMLAYERS=     2
      IF (NUMHID.EQ.0) NUMLAYERS=1

C---- 
C---- get file names
C---- 
      CTNUM=6
      VARIN=          PASSED_ARGC(CTNUM+1)
      FILEIN_IN(1)=   VARIN(1:FILEN_STRING(VARIN))
      VARIN=          PASSED_ARGC(CTNUM+2)
      FILEIN_JCT=     VARIN(1:FILEN_STRING(VARIN))
      VARIN=          PASSED_ARGC(CTNUM+3)
      FILEOUT_OUT(1)= VARIN(1:FILEN_STRING(VARIN))

C---- 
C---- debug mode?
C---- 
      IF (NUMARGUMENTS.GE.(CTNUM+4)) THEN
         LOGI_DEBUG=  .TRUE.
      END IF

C---- ------------------------------------------------------------------
C---- write what we got
C---- ------------------------------------------------------------------
      IF (LOGI_DEBUG) THEN
         CTMP=' '
         CTMP='--- INIPAR_SWITCH: ' 
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMIN',    NUMIN
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMHID',   NUMHID
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMOUT',   NUMOUT
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMLAYERS',NUMLAYERS
C---- 
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMSAM',   NUMSAM
C---- 
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMFILEIN_IN',  NUMFILEIN_IN
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMFILEIN_OUT', NUMFILEIN_OUT
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMFILEOUT_OUT',NUMFILEOUT_OUT
         WRITE(6,'(A,T20,A,T35,I8)')CTMP,'NUMFILEOUT_JCT',NUMFILEOUT_JCT
C---- 
         DO IT=1,NUMFILEIN_IN
            WRITE(6,'(A,T20,A,T35,I4,A1,A)')CTMP,'FILEIN_IN',IT,' ',
     +           FILEIN_IN(IT)(1:FILEN_STRING(FILEIN_IN(IT)))
         END DO
         WRITE(6,'(A,T20,A,T40,A)')CTMP,
     +        'FILEIN_JCT',FILEIN_JCT(1:FILEN_STRING(FILEIN_JCT))
         DO IT=1,NUMFILEOUT_OUT
            WRITE(6,'(A,T20,A,T35,I4,A1,A)')CTMP,'FILEOUT_OUT',IT,' ',
     +           FILEOUT_OUT(IT)(1:FILEN_STRING(FILEOUT_OUT(IT)))
         END DO
      END IF

      END
***** end of INIPAR_SWITCH

***** ------------------------------------------------------------------
***** SUB INITHRUNT
***** ------------------------------------------------------------------
C---- 
C---- NAME : INITHRUNT
C---- ARG  : 
C---- DES  : the additional input/hidden units for writing the
C---- DES  : thresholds/biases as parts of the junctions.
C---- IN   : NUMSAM,NUMIN,NUMHID/1,NUMSAM
C---- OUT  : INPUT(NUMIN+1,MUE),
C---- OUT  : OUTHID(HID+1,MUE),OUTHID1(HID1+1,MUE)
C---- FROM : MAIN
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE INITHRUNT

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       MUE
******------------------------------*-----------------------------******

C---- NUMLAYERS=1                               -----
      IF (NUMLAYERS.EQ.1) THEN
         DO MUE=1,NUMSAM
            INPUT((NUMIN+1),MUE)=BITACC
         END DO
C---- NUMLAYERS=2                               -----
      ELSEIF (NUMLAYERS.EQ.2) THEN
         DO MUE=1,NUMSAM
            INPUT((NUMIN+1),MUE)=BITACC
            OUTHID((NUMHID+1))=1.
         END DO
      END IF
      END
***** end of INITHRUNT 

***** ------------------------------------------------------------------
***** SUB RDJCT
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDJCT
C---- ARG  : 
C---- DES  : Architecture read from file 
C---- IN   : 
C---- FROM : MAIN 
C---- CALL2: RDJCT_HEAD, RDJCT_JCT1, RDJCT_JCT2, RDJCT_WRT
C---- LIB  : SFILEOPEN 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDJCT

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables                                                  *
      CHARACTER*80  HC,MREAD
      LOGICAL       LDONE,LREAD
******------------------------------*-----------------------------******
C     message onto screen
C      WRITE(6,'(A)')'--- '
      IF (.NOT. LOGI_SWITCH .OR. LOGI_DEBUG) THEN
         WRITE(6,'(A,T16,A)')'--- RDjct file=',
     +        FILEIN_JCT(1:FILEN_STRING(FILEIN_JCT))
      END IF
C---- 
C---- read file with junctions
C---- 
      CALL SFILEOPEN(10,FILEIN_JCT,'OLD',150,'READONLY')
      LDONE=.FALSE.
      DO WHILE (.NOT.LDONE)
         LREAD=.FALSE.
         READ(10,'(A9)',END=2057)HC
C---- terminate reading
         IF     (HC(1:2).EQ.'//') THEN
            LDONE=.TRUE.
            LREAD=.FALSE.
         ELSEIF (HC(1:9).EQ.'* overall') THEN
            LREAD=.FALSE.
            MREAD='H'
         ELSEIF (HC(1:9).EQ.'* jct 1st') THEN
            LREAD=.FALSE.
            MREAD='1'
         ELSEIF (HC(1:9).EQ.'* jct 2nd') THEN
            LREAD=.FALSE.
            MREAD='2'
         ELSEIF (HC(1:1).NE.'*') THEN
            BACKSPACE 10
            LREAD=.TRUE.
         ELSE
            LREAD=.FALSE.
         END IF
C---- 
C     header (numin,numsam,numsamfile)
C----
         IF     (LREAD.AND.(MREAD.EQ.'H')) THEN
            CALL RDJCT_HEAD
         ELSEIF (LREAD.AND.(MREAD.EQ.'1')) THEN
            CALL RDJCT_JCT1
         ELSEIF (LREAD.AND.(MREAD.EQ.'2')) THEN
            CALL RDJCT_JCT2
         ELSEIF (LREAD) THEN
            WRITE(6,'(A,T10,A,A,A)')'***',
     +           'ERROR RDJCT MREAD not recognised:',MREAD,':'
            STOP '*** RDJCT: left due to error in reading inJct'
         END IF
      END DO

 2057 CONTINUE
      CLOSE(10)

C---- 
C     header (numin,numsam,numsamfile)
C----
C     control write
      IF (LOGI_RDJCTWRT) THEN
         CALL RDJCT_WRT
      END IF
      END 
***** end of RDJCT
         
***** ------------------------------------------------------------------
***** SUB RDJCT_HEAD
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDJCT_HEAD
C---- ARG  : 
C---- DES  : reading and checking header of file with input vec
C---- IN   : 
C---- FROM : RDJCT 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDJCT_HEAD

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables
      INTEGER       VARIN,IT,NUMINLOC,NUMHIDLOC,NUMOUTLOC
      CHARACTER*80  HC,VARINC,MODEPREDLOC,MODENETLOC,MODEJOBLOC,
     +              MODEINLOC,MODEOUTLOC
      LOGICAL       LERROR
******------------------------------*-----------------------------******
      LERROR=.FALSE.
C---- 
C---- loop over 3 INTEGERS: NUMIN, NUMHID, NUMOUT
C---- 
      DO IT=1,3
         READ(10,'(A20,T25,I8)')HC,VARIN
         IF     (HC(1:5).EQ.'NUMIN') THEN
            NUMINLOC=VARIN
         ELSEIF (HC(1:6).EQ.'NUMHID') THEN
            NUMHIDLOC=VARIN
         ELSEIF (HC(1:6).EQ.'NUMOUT') THEN
            NUMOUTLOC=VARIN
         ELSE
            WRITE(6,'(T2,A,T10,A,A,A)')'***',
     +           'ERROR RDJCT_HEAD I HC not recognised:',HC,':'
            LERROR=.TRUE.
         END IF
      END DO
C---- 
C---- loop over modes: MODEPRED, MODENET, MODEJOB, MODEIN, 
C---- 
      DO IT=1,5
         READ(10,'(A20,T25,A)')HC,VARINC
         IF     (INDEX(HC,'MODEPRED').NE.0) THEN
            MODEPREDLOC=VARINC(1:FILEN_STRING(VARINC))
         ELSEIF (INDEX(HC,'MODENET') .NE.0) THEN
            MODENETLOC=VARINC(1:FILEN_STRING(VARINC))
         ELSEIF (INDEX(HC,'MODEJOB') .NE.0) THEN
            MODEJOBLOC=VARINC(1:FILEN_STRING(VARINC))
         ELSEIF (INDEX(HC,'MODEIN')  .NE.0) THEN
            MODEINLOC=VARINC(1:FILEN_STRING(VARINC))
         ELSEIF (INDEX(HC,'MODEOUT') .NE.0) THEN
            MODEOUTLOC=VARINC(1:FILEN_STRING(VARINC))
         ELSE
            WRITE(6,'(T2,A,T10,A,A,A)')'***',
     +           'ERROR RDJCT_HEAD A HC not recognised:',HC,':'
            LERROR=.TRUE.
         END IF
      END DO
C---- 
C---- error check (consistency with file.para)
C---- 
      CALL RDJCT_CHECK(NUMINLOC,NUMHIDLOC,NUMOUTLOC,
     +     MODEPREDLOC,MODENETLOC,MODEJOBLOC,MODEINLOC,MODEOUTLOC)

C---- 
C     error -> back
C---- 
      IF (LERROR) THEN
         WRITE(6,'(T2,A,T10,A)')'***',
     +        'RDJCT_HEAD: reading header of input vectors'
         STOP '*** RDJCT_HEAD: left due to error in reading inJct'
      END IF
      END
***** end of RDJCT_HEAD

***** ------------------------------------------------------------------
***** SUB RDJCT_JCT1
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDJCT_JCT1
C---- ARG  : 
C---- DES  : reading and checking JCT1 of architecture 
C---- IN   : 
C---- FROM : RDJCT 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDJCT_JCT1

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       ITHID,ITIN
******------------------------------*-----------------------------******
      DO ITHID=1,NUMHID
         READ(10,'(10F10.4)')
     +        (JCT1ST(ITIN,ITHID),ITIN=1,(NUMIN+1))
      END DO
      END
***** end of RDJCT_JCT1

***** ------------------------------------------------------------------
***** SUB RDJCT_JCT2
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDJCT_JCT2
C---- ARG  : 
C---- DES  : reading and checking JCT2 of architecture 
C---- IN   : 
C---- FROM : RDJCT
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDJCT_JCT2

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       ITHID,ITOUT
******------------------------------*-----------------------------******
      DO ITHID=1,(NUMHID+1)
         READ(10,'(10F10.4)')(JCT2ND(ITHID,ITOUT),ITOUT=1,NUMOUT)
      END DO
      END
***** end of RDJCT_JCT2

***** ------------------------------------------------------------------
***** SUB RDJCT_CHECK
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDJCT_CHECK
C---- ARG  : 
C---- DES  : compares parameters read from JCT and PAR  
C---- IN   :
C---- FROM : RDJCT_HEAD
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost             Oct,        1998        version 1.0    *
*     CUBIC/LION                http://cubic.bioc.columbia.edu         *
*     Columbia University        rost@columbia.edu                      *
*                      changed: Oct,        1998        version 0.1    *
*----------------------------------------------------------------------*
      SUBROUTINE RDJCT_CHECK(NUMINLOC,NUMHIDLOC,NUMOUTLOC,
     +     MODEPREDLOC,MODENETLOC,MODEJOBLOC,MODEINLOC,MODEOUTLOC)

C---- include parameter files
      INCLUDE       'nnPar.f'

C---- variables passed
      INTEGER       NUMINLOC,NUMHIDLOC,NUMOUTLOC
      CHARACTER*80  MODEPREDLOC,MODENETLOC,MODEJOBLOC,
     +              MODEINLOC,MODEOUTLOC
C---- local variables                                                  *
      LOGICAL       LERROR,LWARN
******------------------------------*-----------------------------******
      LERROR=  .FALSE.
      LWARN=   .FALSE.
C---- 
C---- archictecture (NUMIN,NUMHID,NUMOUT)
C---- 
      IF (NUMINLOC.NE.NUMIN) THEN
         WRITE(6,'(T2,A,T10,A,I6,A,I6)')'***',
     +        'ERROR RDJCT_CHECK: NUMIN para=',
     +        NUMIN,' file_jct=',NUMINLOC
         LERROR=.TRUE.
      END IF
      IF (NUMHIDLOC.NE.NUMHID) THEN
         WRITE(6,'(T2,A,T10,A,I6,A,I6)')'***',
     +        'ERROR RDJCT_CHECK: NUMHID para=',
     +        NUMHID,' file_jct=',NUMHIDLOC
         LERROR=.TRUE.
      END IF
      IF (NUMOUTLOC.NE.NUMOUT) THEN
         WRITE(6,'(T2,A,T10,A,I6,A,I6)')'***',
     +        'ERROR RDJCT_CHECK: NUMOUT para=',
     +        NUMOUT,' file_jct=',NUMOUTLOC
         LERROR=.TRUE.
      END IF
C---- 
C---- modes
C---- 
      IF (LOGI_SWITCH.EQV..FALSE.) THEN
         IF (MODEPREDLOC.NE.MODEPRED) THEN
            WRITE(6,'(T2,A,T10,A,A,A,A)')'***',
     +           'ERROR RDJCT_CHECK: MODEPRED para=',
     +           MODEPRED,' file_jct=',MODEPREDLOC
            LERROR=.TRUE.
         END IF
         IF (MODENETLOC .NE.MODENET) THEN
            WRITE(6,'(T2,A,T10,A,A,A,A)')'***',
     +           'ERROR RDJCT_CHECK: MODENET para=',
     +           MODENET,' file_jct=',MODENETLOC
            LERROR=.TRUE.
         END IF
         IF (MODEJOBLOC .NE.MODEJOB) THEN
            WRITE(6,'(T2,A,T10,A,A,A,A)')'***',
     +           'ERROR RDJCT_CHECK: MODEJOB para=',
     +           MODEJOB,' file_jct=',MODEJOBLOC
            LERROR=.TRUE.
         END IF
         IF (MODEINLOC  .NE.MODEIN) THEN
            WRITE(6,'(T2,A,T10,A,A,A,A)')'***',
     +           'ERROR RDJCT_CHECK: MODEIN para=',
     +           MODEIN,' file_jct=',MODEINLOC
            LERROR=.TRUE.
         END IF
         IF (MODEOUTLOC .NE.MODEOUT) THEN
            WRITE(6,'(T2,A,T10,A,A,A,A)')'***',
     +           'ERROR RDJCT_CHECK: MODEOUT para=',
     +           MODEOUT,' file_jct=',MODEOUTLOC
            LERROR=.TRUE.
         END IF
      END IF
C---- 
C     error -> back
C---- 
      IF (LERROR) THEN
         WRITE(6,'(T2,A,T10,A)')'***',
     +        'RDJCT_CHECK: reading header of input vectors'
         STOP '*** RDJCT_HEAD: left due to error in reading inJct'
      END IF
      END 
***** end of RDJCT_CHECK

***** ------------------------------------------------------------------
***** SUB RDJCT_WRT
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDJCT_WRT
C---- ARG  : 
C---- DES  : writes the architecture read  
C---- IN   : 
C---- FROM : RDJCT
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDJCT_WRT

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       ITIN,ITHID,ITOUT,KUNIT
      CHARACTER*80  CTMP,CTMP2
******------------------------------*-----------------------------******
C---- 
C      WRITE(6,'(A)')'--- '
      KUNIT=6
      CTMP='--- RDjct: '
      CTMP2='--------------------------------------------------'
      WRITE(KUNIT,'(A,T16,A50)')CTMP,CTMP2
      WRITE(KUNIT,'(A,T16,A)')CTMP,'Architecture vectors read:'
C---- 
C---- 1st layer
C---- 
      WRITE(KUNIT,'(A,T16,A)')CTMP,' '
      WRITE(KUNIT,'(A,T16,A,I8)')CTMP,'JCT1: col=1..NUMHID =',NUMHID
      WRITE(KUNIT,'(A,T16,A,I8)')CTMP,'JCT1: row=1..NUMIN+ =',(NUMIN+1)
      DO ITHID=1,NUMHID
         WRITE(KUNIT,'(10F10.4)')(JCT1ST(ITIN,ITHID),ITIN=1,(NUMIN+1))
      END DO
C---- 
C---- 2nd layer
C---- 
      WRITE(KUNIT,'(A,T16,A)')CTMP,' '
      WRITE(KUNIT,'(A,T16,A,I8)')CTMP,'JCT2: col=1..NUMHID+=',(NUMHID+1)
      WRITE(KUNIT,'(A,T16,A,I8)')CTMP,'JCT2: row=1..NUMHID =',NUMOUT
      DO ITHID=1,(NUMHID+1)
         WRITE(KUNIT,'(10F10.4)')(JCT2ND(ITHID,ITOUT),ITOUT=1,NUMOUT)
      END DO
      WRITE(KUNIT,'(A,T16,A,T35)')CTMP,'end of reading architecture'

      IF (KUNIT.NE.6) THEN
         CLOSE(KUNIT)
      END IF

      END
***** end of RDJCT_WRT

***** ------------------------------------------------------------------
***** SUB RDIN
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDIN
C---- ARG  : 
C---- DES  : Reads the protein input from file
C---- IN   : 
C---- FROM : MAIN 
C---- CALL2: RDIN_HEAD, RDIN_DATA, RDIN_WRT 
C---- LIB  : SFILEOPEN
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDIN

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables
      INTEGER       ITFILE,CNTTOT,CNTRD,NUMINLOC,NUMSAMLOC
      CHARACTER*80  HC,MREAD
      LOGICAL       LDONE,LREAD
******------------------------------*-----------------------------******
C     message onto screen
C      WRITE(6,'(A)')'--- '

      CNTTOT=0
C---- 
C---- loop over input files
C---- 
      DO ITFILE=1,NUMFILEIN_IN
C     message onto screen
         IF (.NOT. LOGI_SWITCH .OR. LOGI_DEBUG) THEN
C            WRITE(6,'(A,T16,A)')'--- RDin file=',
C     +           FILEIN_IN(ITFILE)(1:FILEN_STRING(FILEIN_IN(ITFILE)))
            WRITE(6,'(A,T16,A)')'--- RDin',
     +           FILEIN_IN(ITFILE)(1:FILEN_STRING(FILEIN_IN(ITFILE)))
         END IF
C     read
         CALL SFILEOPEN(10,FILEIN_IN(ITFILE),'OLD',150,'READONLY')

         LDONE=.FALSE.
         DO WHILE (.NOT.LDONE)
            LREAD=.FALSE.
            READ(10,'(A9)',END=4057)HC
C     terminate reading
            IF     (HC(1:2).EQ.'//') THEN
               LDONE=.TRUE.
               LREAD=.FALSE.
            ELSEIF (HC(1:9).EQ.'* overall') THEN
               LREAD=.FALSE.
               MREAD='H'
            ELSEIF (HC(1:9).EQ.'* samples') THEN
               LREAD=.FALSE.
               MREAD='D'
            ELSEIF (HC(1:1).NE.'*') THEN
               BACKSPACE 10
               LREAD=.TRUE.
            ELSE
               LREAD=.FALSE.
            END IF
C---- 
C     header (numin,numsam,numsamfile)
C----
            IF     (LREAD.AND.(MREAD.EQ.'H')) THEN
               CALL RDIN_HEAD(NUMINLOC,NUMSAMLOC)
            ELSEIF (LREAD.AND.(MREAD.EQ.'D')) THEN
               CALL RDIN_DATA(CNTRD,NUMINLOC)
               CNTTOT=CNTTOT+CNTRD
               IF (CNTTOT.GT.NUMSAM) THEN
                  WRITE(6,'(A,T10,A,A,I8,A,I8)')'***','ERROR RDIN ',
     +                 ' NUMSAM=',NUMSAM,' already CNTTOT=',CNTTOT
                  STOP '*** RDIN: left due to error in reading inIn'
               END IF
            ELSEIF (LREAD) THEN
               WRITE(6,'(A,T10,A,A,A)')'***',
     +              'ERROR RDIN MREAD not recognised:',MREAD,':'
               STOP '*** RDIN: left due to error in reading inIn'
            END IF
         END DO
 4057    CONTINUE
         CLOSE(10)
      END DO
C     end of loop over input files
C---- ------------------------------

C----
C     number of samples ok?
C---- 
      IF (CNTTOT.NE.NUMSAM) THEN
         WRITE(6,'(A,T10,A,I6,A,I6)')'***',
     +        'ERROR RDin: NUMSAM (from para)=',NUMSAM,
     +        ' NUMSAM read (from filein)=',CNTTOT
         STOP '*** RDIN: left due to error in read inIn'
      END IF
C---- 
C     control write
C---- 
      IF (LOGI_RDINWRT) THEN
         CALL RDIN_WRT
      END IF
      END 
***** end of RDIN
         
***** ------------------------------------------------------------------
***** SUB RDIN_HEAD(NUMINLOC,NUMSAMLOC)
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDIN_HEAD(NUMINLOC,NUMSAMLOC)
C---- ARG  : 
C---- DES  : reading and checking header of file with input vec
C---- IN   : 
C---- FROM : RDIN
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDIN_HEAD(NUMINLOC,NUMSAMLOC)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       VARIN,NUMINLOC,NUMSAMLOC,IT
      CHARACTER*80  HC
      LOGICAL       LERROR
******------------------------------*-----------------------------******
      LERROR=.FALSE.
C     loop over 3 variables
      DO IT=1,2
         READ(10,'(A20,T25,I8)')HC,VARIN
         IF     (HC(1:5) .EQ.'NUMIN') THEN
            NUMINLOC=VARIN
         ELSEIF (HC(1:10).EQ.'NUMSAMFILE') THEN
            NUMSAMFILE=VARIN
         ELSE
            WRITE(6,'(A,T10,A,A,A)')'***',
     +           'ERROR RDIN_HEAD HC not recognised:',HC,':'
            LERROR=.TRUE.
         END IF
      END DO
C---- 
C---- check
C---- 
      IF (NUMIN.NE.NUMINLOC) THEN
         WRITE(6,'(A,T10,A,A,I8,A,I8)')'***','ERROR RDIN_HEAD ',
     +        ' NUMIN=',NUMIN,' NUMINLOC=',NUMINLOC
         LERROR=.TRUE.
      END IF
C      IF (NUMSAM.NE.NUMSAMLOC) THEN
C         WRITE(6,'(A,T10,A,A,I8,A,I8)')'***','ERROR RDIN_HEAD ',
C     +        ' NUMSAM=',NUMSAM,' NUMSAMLOC=',NUMSAMLOC
C         LERROR=.TRUE.
C      END IF
      IF (LERROR) THEN
         WRITE(6,'(T2,A,T10,A)')'***',
     +        'RDIN_HEAD: reading header of input vectors'
         STOP '*** RDIN_HEAD: left due to error in reading inIn'
      END IF
      END
***** end of RDIN_HEAD

***** ------------------------------------------------------------------
***** SUB RDIN_DATA(CNTRD,NUMINLOC)
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDIN_DATA(CNTRD,NUMINLOC)
C---- ARG  : 
C---- DES  : reading and checking DATA of file with input vec 
C---- IN   : 
C---- FROM : RDIN
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDIN_DATA(CNTRD,NUMINLOC)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       ITSAMRD,ITSAM,ITIN,CNTRD,NUMINLOC
      CHARACTER*80  HC
******------------------------------*-----------------------------******
      CNTRD=0
C---- loop over all samples in local file
      DO ITSAM=1,NUMSAMFILE
         READ(10,'(A8,I8)')HC,ITSAMRD
         READ(10,'(25I6)')(INPUT(ITIN,ITSAMRD),ITIN=1,NUMINLOC)
         CNTRD=CNTRD+1
      END DO
      END
***** end of RDIN_DATA

***** ------------------------------------------------------------------
***** SUB RDIN_WRT
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDIN_WRT
C---- ARG  : 
C---- DES  : writes the input vectors read      
C---- IN   : 
C---- FROM : RDIN
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDIN_WRT

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       ITSAM,ITIN
      CHARACTER*80  CTMP,CTMP2
******------------------------------*-----------------------------******
C---- 
C      WRITE(6,'(A)')'--- '
      CTMP='--- RDin: '
      CTMP2='--------------------------------------------------'
      WRITE(6,'(A,T16,A50)')CTMP,CTMP2
      WRITE(6,'(A,T16,A)')CTMP,'Input vectors read:'
C---- 
C---- integers
C---- 
      WRITE(6,'(A,T16,A)')CTMP,' '
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMIN',NUMIN
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMSAM',NUMSAM
C---- 
C---- vectors
C---- 
      WRITE(6,'(A,T16,A)')CTMP,' '
      DO ITSAM=1,NUMSAM
         WRITE(6,'(A,T16,A10,I6,A3)')CTMP,'ITSAM=',ITSAM,' : '
         WRITE(6,'(25I4)')(INPUT(ITIN,ITSAM),ITIN=1,NUMIN)
      END DO
      WRITE(6,'(A,T16,A,T35)')CTMP,'end of reading input vectors'
      END
***** end of RDIN_WRT

***** ------------------------------------------------------------------
***** SUB RDOUT
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDOUT
C---- ARG  : 
C---- DES  : Reads the protein input from file 
C---- IN   : 
C---- FROM : MAIN 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDOUT

C---- include parameter files
      INCLUDE 'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables                                                  *
      INTEGER      ITFILE,CNTTOT,CNTRD
Cxx
      INTEGER      COUNT_CLASS(1:10),ITOUT,ITSAM
Cxx
      CHARACTER*80 HC,MREAD
      LOGICAL      LDONE,LREAD
******------------------------------*-----------------------------******
C     message onto screen
C      WRITE(6,'(A)')'--- '
      CNTTOT=0
C---- 
C---- loop over input files
C---- 
      DO ITFILE=1,NUMFILEIN_OUT
C     message onto screen
C         WRITE(6,'(A,T16,A)')'--- RDout file=',
C     +        FILEIN_OUT(ITFILE)(1:FILEN_STRING(FILEIN_OUT(ITFILE)))
         WRITE(6,'(A,T16,A)')'--- RDout',
     +        FILEIN_OUT(ITFILE)(1:FILEN_STRING(FILEIN_OUT(ITFILE)))
C     read
         CALL SFILEOPEN(10,FILEIN_OUT(ITFILE),'OLD',150,'READONLY')

         LDONE=.FALSE.
         DO WHILE (.NOT.LDONE)
            LREAD=.FALSE.
            READ(10,'(A9)',END=3057)HC
C     terminate reading
            IF     (HC(1:2).EQ.'//') THEN
               LDONE=.TRUE.
               LREAD=.FALSE.
            ELSEIF (HC(1:9).EQ.'* overall') THEN
               LREAD=.FALSE.
               MREAD='H'
            ELSEIF (HC(1:9).EQ.'* samples') THEN
               LREAD=.FALSE.
               MREAD='D'
            ELSEIF (HC(1:1).NE.'*') THEN
               BACKSPACE 10
               LREAD=.TRUE.
            ELSE
               LREAD=.FALSE.
            END IF
C---- 
C     header (numin,numsam,numsamfile)
C----
            IF     (LREAD.AND.(MREAD.EQ.'H')) THEN
               CALL RDOUT_HEAD
            ELSEIF (LREAD.AND.(MREAD.EQ.'D')) THEN
               CALL RDOUT_DATA(CNTRD)
               CNTTOT=CNTTOT+CNTRD
               IF (CNTTOT.GT.NUMSAM) THEN
                  WRITE(6,'(A,T10,A,A,I8,A,I8)')'***','ERROR RDOUT ',
     +                 ' NUMSAM=',NUMSAM,' already CNTTOT=',CNTTOT
                  STOP '*** RDOUT: left due to error in reading inOut'
               END IF
            ELSEIF (LREAD) THEN
               WRITE(6,'(A,T10,A,A,A)')'***',
     +              'ERROR RDOUT MREAD not recognised:',MREAD,':'
               STOP '*** RDOUT: left due to error in reading inOut'
            END IF
         END DO
 3057    CONTINUE
         CLOSE(10)
      END DO
C     end of loop over input files
C---- ------------------------------

C---- write stat
      DO ITOUT=1,NUMOUT
         COUNT_CLASS(ITOUT)=0
      END DO


      DO ITSAM=1,NUMSAM
         DO ITOUT=1,NUMOUT
            IF (OUTDES(ITOUT,ITSAM).GT.0) THEN
               COUNT_CLASS(ITOUT)=COUNT_CLASS(ITOUT)+1
            END IF
         END DO
      END DO
      WRITE(6,*)'xx stat on class'
      DO ITOUT=1,NUMOUT
         WRITE(6,'(A,I,A,F6.1,A,I)')
     +        'xx stat i=',ITOUT,
     +        ' perc=',(100*COUNT_CLASS(ITOUT))/REAL(NUMSAM),
     +        ' num=', COUNT_CLASS(ITOUT)
      END DO

C     control write
      IF (LOGI_RDOUTWRT) THEN
         CALL RDOUT_WRT
      END IF
      END 
***** end of RDOUT
         
***** ------------------------------------------------------------------
***** SUB RDOUT_HEAD
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDOUT_HEAD
C---- ARG  : 
C---- DES  : reading and checking header of file with input vec
C---- IN   : 
C---- FROM : RDOUT
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDOUT_HEAD

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       VARIN,NUMOUTLOC,NUMSAMLOC,IT
      CHARACTER*80  HC
      LOGICAL       LERROR
******------------------------------*-----------------------------******
      LERROR=.FALSE.
C     loop over 3 variables
      DO IT=1,2
         READ(10,'(A20,T25,I8)')HC,VARIN
         IF     (HC(1:6) .EQ.'NUMOUT') THEN
            NUMOUTLOC=VARIN
         ELSEIF (HC(1:10).EQ.'NUMSAMFILE') THEN
            NUMSAMFILE=VARIN
         ELSE
            WRITE(6,'(T2,A,T10,A,A,A)')'***',
     +           'ERROR RDOUT_HEAD HC not recognised:',HC,':'
            LERROR=.TRUE.
         END IF
      END DO
C---- 
C---- check DATA read
C---- 
      IF (NUMOUT.NE.NUMOUTLOC) THEN
         WRITE(6,'(A,T10,A,A,I8,A,I8)')'***','ERROR RDOUT_HEAD ',
     +        ' NUMOUT=',NUMOUT,' NUMOUTLOC=',NUMOUTLOC
         LERROR=.TRUE.
      END IF
C      IF (NUMSAM.NE.NUMSAMLOC) THEN
C         WRITE(6,'(A,T10,A,A,I8,A,I8)')'***','ERROR RDOUT_HEAD ',
C     +        ' NUMSAM=',NUMSAM,' NUMSAMLOC=',NUMSAMLOC
C         LERROR=.TRUE.
C      END IF
      IF (LERROR) THEN
         WRITE(6,'(T2,A,T10,A)')'***',
     +        'RDOUT_HEAD: reading header of input vectors'
         STOP '*** RDOUT_HEAD: left due to error in reading inIn'
      END IF
      END
***** end of RDOUT_HEAD

***** ------------------------------------------------------------------
***** SUB RDOUT_DATA(CNTRD)
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDOUT_DATA(CNTRD)
C---- ARG  : 
C---- DES  : reading and checking DATA of file with input vec
C---- IN   : 
C---- FROM : RDOUT  
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDOUT_DATA(CNTRD)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       ITSAMRD,ITSAM,ITOUT,CNTRD
      CHARACTER*80  HC
******------------------------------*-----------------------------******
      CNTRD=0
C---- loop over all samples in local file
      DO ITSAM=1,NUMSAMFILE
         READ (10,'(I8,A1,25I6)')ITSAMRD,HC,
         WRITE(6,'(I8,A1,25I6)')ITSAMRD,
     +        (OUTDES(ITOUT,ITSAMRD),ITOUT=1,NUMOUT)
         CNTRD=CNTRD+1
      END DO
      END
***** end of RDOUT_DATA

***** ------------------------------------------------------------------
***** SUB RDOUT_WRT
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDOUT_WRT
C---- ARG  : 
C---- DES  : writes the input vectors read 
C---- IN   : 
C---- FROM : RDOUT
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDOUT_WRT

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       ITSAM,ITOUT
      CHARACTER*80  CTMP,CTMP2
******------------------------------*-----------------------------******
C---- 
C      WRITE(6,'(A)')'--- '
      CTMP='--- RDout: '
      CTMP2='--------------------------------------------------'
      WRITE(6,'(A,T16,A50)')CTMP,CTMP2
      WRITE(6,'(A,T16,A)')CTMP,'Output vectors read:'
C---- 
C---- integers
C---- 
      WRITE(6,'(A,T16,A)')CTMP,' '
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMOUT',NUMOUT
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMSAM',NUMSAM
C---- 
C---- vectors
C---- 
      WRITE(6,'(A,T16,A)')CTMP,' '
      DO ITSAM=1,NUMSAM
         WRITE(6,'(A,T16,I8,A3,25I4)')CTMP,ITSAM,' : ',
     +        (OUTDES(ITOUT,ITSAM),ITOUT=1,NUMOUT)
      END DO
      WRITE(6,'(A,T16,A,T35)')CTMP,'end of reading output vectors'
      END
***** end of RDOUT_WRT

***** ------------------------------------------------------------------
***** SUB RDPAR
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDPAR
C---- ARG  : 
C---- DES  : Reads the architecture specifica parameters from 
C---- DES  : perl (nnWrt.pl) generated file        
C---- IN   : 
C---- FROM : MAIN
C---- CALL2: RDPAR_WRT, RDPAR_I,_F,_A
C---- LIB  : SFILEOPEN
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDPAR

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables
      CHARACTER*80  HC,MREAD
      LOGICAL       LDONE,LREAD
******------------------------------*-----------------------------******
C     message onto screen
C      WRITE(6,'(A)')'--- '
      WRITE(6,'(A,T16,A)')'--- RDpar file=',
     +     FILEIN_PAR(1:FILEN_STRING(FILEIN_PAR))
C---- read parameters from file NN_InPar
      CALL SFILEOPEN(10,FILEIN_PAR,'OLD',150,'READONLY')

      LDONE=.FALSE.
      DO WHILE (.NOT.LDONE)
         LREAD=.FALSE.
C>>>>>>>                GOTO END
         READ(10,'(A3)',END=15047)HC
C------- terminate reading
         IF     (HC(1:2).EQ.'//') THEN
            LDONE=.TRUE.
            LREAD=.FALSE.
         ELSEIF (HC(1:3).EQ.'* I') THEN
            LREAD=.FALSE.
            MREAD='I'
         ELSEIF (HC(1:3).EQ.'* F') THEN
            LREAD=.FALSE.
            MREAD='F'
         ELSEIF (HC(1:3).EQ.'* A') THEN
            LREAD=.FALSE.
            MREAD='A'
         ELSEIF (HC(1:1).NE.'*') THEN
            BACKSPACE 10
            LREAD=.TRUE.
         ELSE
            LREAD=.FALSE.
         END IF

         IF (LREAD) THEN
            IF     (MREAD.EQ.'I') THEN
               CALL RDPAR_I
            ELSEIF (MREAD.EQ.'F') THEN
               CALL RDPAR_F
            ELSEIF (MREAD.EQ.'A') THEN
               CALL RDPAR_A
            ELSE
               WRITE(6,'(A,T10,A,A,A)')'***',
     +              'ERROR RDPAR MREAD not recognised:',MREAD,':'
               STOP '*** RDPAR: left due to error in reading inPar'
            END IF
         END IF
      END DO
15047 CONTINUE
      CLOSE(10)
*                                                                      *
C---- control write
      IF (LOGI_RDPARWRT) THEN
         CALL RDPAR_WRT
      END IF
      END
***** end of RDPAR

***** ------------------------------------------------------------------
***** SUB RDPAR_I
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDPAR_I
C---- ARG  : 
C---- DES  : reading and interpreting one line with I8 input
C---- IN   : 
C---- FROM : 
C---- CALL2: RDPAR 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDPAR_I

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       VARIN
      CHARACTER*80  HC
      CHARACTER*132 CHAR_RD
******------------------------------*-----------------------------******
C---- read
      READ(10,'(A20,T25,I8)')HC,VARIN
C---- ------------------------------
C---- interpret
      IF     (HC(1:5) .EQ.'NUMIN') THEN
         NUMIN=VARIN
         CALL RDPAR_ERR('NUMIN',VARIN)
      ELSEIF (HC(1:6) .EQ.'NUMHID') THEN
         NUMHID=VARIN
         CALL RDPAR_ERR('NUMHID',VARIN)
      ELSEIF (HC(1:6) .EQ.'NUMOUT') THEN
         NUMOUT=VARIN
         CALL RDPAR_ERR('NUMOUT',VARIN)
      ELSEIF (HC(1:9) .EQ.'NUMLAYERS') THEN
         NUMLAYERS=VARIN
      ELSEIF (HC(1:6) .EQ.'NUMSAM') THEN
         NUMSAM=VARIN
         CALL RDPAR_ERR('NUMSAM',VARIN)
C---- 
C---- number of files
C---- 
      ELSEIF (HC(1:12).EQ.'NUMFILEIN_IN') THEN
         NUMFILEIN_IN=VARIN
         CALL RDPAR_ERR(HC,VARIN)
      ELSEIF (HC(1:13).EQ.'NUMFILEIN_OUT') THEN
         NUMFILEIN_OUT=VARIN
         CALL RDPAR_ERR(HC,VARIN)
      ELSEIF (HC(1:14).EQ.'NUMFILEOUT_OUT') THEN
         NUMFILEOUT_OUT=VARIN
         CALL RDPAR_ERR(HC,VARIN)
      ELSEIF (HC(1:14).EQ.'NUMFILEOUT_JCT') THEN
         NUMFILEOUT_JCT=VARIN
         CALL RDPAR_ERR(HC,VARIN)
C---- 
C---- training times
C---- 
      ELSEIF (HC(1:9) .EQ.'STPSWPMAX') THEN
         STPSWPMAX=VARIN
         CALL RDPAR_ERR('STPSWPMAX',VARIN)
      ELSEIF (HC(1:6) .EQ.'STPMAX') THEN
         STPMAX=VARIN
         CALL RDPAR_ERR('STPMAX',VARIN)
      ELSEIF (HC(1:6) .EQ.'STPINF') THEN
         STPINF=VARIN
         CALL RDPAR_ERR('STPINF',VARIN)
      ELSEIF (HC(1:6) .EQ.'BITACC') THEN
         BITACC=VARIN
      ELSEIF (HC(1:10).EQ.'ERRBINSTOP') THEN
         ERRBINSTOP=VARIN
C---- 
C---- miscellaneous
C---- 
      ELSEIF (HC(1:8) .EQ.'DICESEED') THEN
         DICESEED=VARIN
      ELSEIF (HC(1:15).EQ.'DICESEED_ADDJCT') THEN
         DICESEED_ADDJCT=VARIN
      ELSEIF (HC(1:15).EQ.'DICESEED_ADDTRN') THEN
         DICESEED_ADDTRN=VARIN
C---- 
C---- logicals
C---- 
      ELSEIF (HC(1:13) .EQ.'LOGI_RDPARWRT') THEN
         LOGI_RDPARWRT=LOGI_TRANSLATE(VARIN)
      ELSEIF (HC(1:13) .EQ.'LOGI_RDINWRT') THEN
         LOGI_RDINWRT=LOGI_TRANSLATE(VARIN)
      ELSEIF (HC(1:13) .EQ.'LOGI_RDOUTWRT') THEN
         LOGI_RDOUTWRT=LOGI_TRANSLATE(VARIN)
      ELSEIF (HC(1:13) .EQ.'LOGI_RDJCTWRT') THEN
         LOGI_RDJCTWRT=LOGI_TRANSLATE(VARIN)
C---- 
C---- unrecognised
C---- 
      ELSE
         WRITE(6,'(A,T10,A,A,I8)')'***',
     +        'RDPAR_I: no interpretation of',HC,VARIN
         STOP '*** RDPAR_I: left due to error in reading inPar'
      END IF
      END
***** end of RDPAR_I
         
***** ------------------------------------------------------------------
***** SUB RDPAR_F
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDPAR_F
C---- ARG  : 
C---- DES  : reading and interpreting one line with F12.3 input
C---- IN   : 
C---- FROM : 
C---- CALL2: RDPAR 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*----------------------------------------------------------------------*
      SUBROUTINE RDPAR_F

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables
      REAL          VARIN
      CHARACTER*80  HC
******------------------------------*-----------------------------******
C---- read
      READ(10,'(A20,T25,F15.6)')HC,VARIN
C---- ------------------------------
C---- interpret
      IF     (HC(1:7) .EQ.'EPSILON') THEN
         EPSILON=VARIN
      ELSEIF (HC(1:5) .EQ.'ALPHA') THEN
         ALPHA=VARIN
      ELSEIF (HC(1:11).EQ.'TEMPERATURE') THEN
         TEMPERATURE=VARIN
C----
      ELSEIF (HC(1:7) .EQ.'ERRSTOP') THEN
         ERRSTOP=VARIN
      ELSEIF (HC(1:7) .EQ.'ERRBIAS') THEN
         ERRBIAS=VARIN
      ELSEIF (HC(1:10).EQ.'ERRBINACC') THEN
         ERRBINACC=VARIN
C----
      ELSEIF (HC(1:10).EQ.'THRESHOUT') THEN
         THRESHOUT=VARIN
      ELSEIF (HC(1:10).EQ.'DICEITRVL') THEN
         DICEITRVL=VARIN
C---- 
C---- unrecognised
C---- 
      ELSE
         WRITE(6,'(A,T10,A,A,I8)')'***',
     +        '*** RDPAR_F: no interpretation of',HC,VARIN
         STOP '*** RDPAR_F: left due to error in reading inPar'
      END IF
      END
***** end of RDPAR_F

***** ------------------------------------------------------------------
***** SUB RDPAR_A
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDPAR_A
C---- ARG  : 
C---- DES  : reading and interpreting one line with A132 input
C---- DES  : 
C---- IN   : 
C---- FROM : RDPAR
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*----------------------------------------------------------------------*
      SUBROUTINE RDPAR_A

C---- include parameter files
      INCLUDE 'nnPar.f'
C---- local function
C      CHARACTER*80 FCUT_SPACES
      INTEGER       FILEN_STRING
C---- local variables
      INTEGER       IT
      CHARACTER*132 VARIN,HC2
      CHARACTER*80  HC
      LOGICAL       LERROR
******------------------------------*-----------------------------******
      LERROR=.FALSE.
C---- read
      READ(10,'(A20,T25,A)')HC,VARIN
      HC2=VARIN(1:FILEN_STRING(VARIN))
      VARIN=' '
      VARIN=HC2
C---- ------------------------------
C---- interpret
C----
C---- modes
      IF     (HC(1:7) .EQ.'TRNTYPE') THEN
         TRNTYPE=VARIN(1:FILEN_STRING(VARIN))
         IF ((TRNTYPE.NE.'BATCH').AND.(TRNTYPE.NE.'ONLINE')) THEN
            WRITE(6,'(A,T10,A,A)')'***',
     +           'RDPAR_A: TRNTYPE=[BATCH|ONLINE], is=',VARIN
            LERROR=.TRUE.
         END IF
      ELSEIF (HC(1:7) .EQ.'TRGTYPE') THEN
         TRGTYPE=VARIN(1:FILEN_STRING(VARIN))
         IF ((TRGTYPE.NE.'SIG').AND.(TRGTYPE.NE.'LOG')) THEN
            WRITE(6,'(A,T10,A,A)')'***',
     +           'RDPAR_A: TRGTYPE=[SIG|LOG], is=',VARIN
            LERROR=.TRUE.
         END IF
      ELSEIF (HC(1:7) .EQ.'ERRTYPE') THEN
         ERRTYPE=VARIN
         IF ( (ERRTYPE(1:7) .NE.'DELTASQ').AND.
     +        (ERRTYPE(1:12).NE.'LN_1-DELTASQ')) THEN
            WRITE(6,'(A,T10,A,A)')'***',
     +           'RDPAR_A: ERRTYPE=[DELTASQ|LN_1-DELTASQ], is=',
     +           VARIN
            LERROR=.TRUE.
         END IF
      ELSEIF (HC(1:8) .EQ.'MODEPRED') THEN
         MODEPRED=VARIN(1:FILEN_STRING(VARIN))
      ELSEIF (HC(1:7) .EQ.'MODENET') THEN
         MODENET=VARIN(1:FILEN_STRING(VARIN))
      ELSEIF (HC(1:6) .EQ.'MODEIN') THEN
         MODEIN=VARIN(1:FILEN_STRING(VARIN))
      ELSEIF (HC(1:7) .EQ.'MODEOUT') THEN
         MODEOUT=VARIN(1:FILEN_STRING(VARIN))
      ELSEIF (HC(1:7) .EQ.'MODEJOB') THEN
         MODEJOB=VARIN(1:FILEN_STRING(VARIN))
C----
C---- input files
C----
      ELSEIF (HC(1:9) .EQ.'FILEIN_IN') THEN
         FILEIN_IN(1)=VARIN(1:FILEN_STRING(VARIN))
         DO IT=2,NUMFILEIN_IN
C---------- read again
            READ(10,'(A20,T25,A)')HC,FILEIN_IN(IT)
            IF (HC(1:9).NE.'FILEIN_IN') THEN
               WRITE(6,'(A,T10,A,A,A,A)')'***',
     +              'RDPAR_A:loop read filein_in, is',
     +              HC,' V=',VARIN
               LERROR=.TRUE.
            END IF
         END DO
      ELSEIF (HC(1:10).EQ.'FILEIN_OUT') THEN
         FILEIN_OUT(1)=VARIN(1:FILEN_STRING(VARIN))
         DO IT=2,NUMFILEIN_OUT
C---------- read again
            READ(10,'(A20,T25,A)')HC,FILEIN_OUT(IT)
            IF (HC(1:10).NE.'FILEIN_OUT') THEN
               WRITE(6,'(A,T10,A,A,A,A)')'***',
     +              'RDPAR_A:loop read filein_OUT, is',
     +              HC,' V=',VARIN
               LERROR=.TRUE.
            END IF
         END DO
      ELSEIF (HC(1:10).EQ.'FILEIN_JCT') THEN
         FILEIN_JCT=VARIN(1:FILEN_STRING(VARIN))
      ELSEIF (HC(1:10).EQ.'FILEIN_SAM') THEN
         FILEIN_SAM=VARIN(1:FILEN_STRING(VARIN))
C----
C---- output files
C----
      ELSEIF (HC(1:11).EQ.'FILEOUT_OUT') THEN
         FILEOUT_OUT(1)=VARIN
         DO IT=2,NUMFILEOUT_OUT
C---------- read again
            READ(10,'(A20,T25,A)')HC,FILEOUT_OUT(IT)
            IF (HC(1:11).NE.'FILEOUT_OUT') THEN
               WRITE(6,'(A,T10,A,A,A,A)')'***',
     +              'RDPAR_A:loop read FILEOUT_OUT, is',
     +              HC,' V=',VARIN
               LERROR=.TRUE.
            END IF
         END DO
      ELSEIF (HC(1:11).EQ.'FILEOUT_JCT') THEN
         FILEOUT_JCT(1)=VARIN
         DO IT=2,NUMFILEOUT_JCT
C---------- read again
            READ(10,'(A20,T25,A)')HC,FILEOUT_JCT(IT)
            IF (HC(1:11).NE.'FILEOUT_JCT') THEN
               WRITE(6,'(A,T10,A,A,A,A)')'***',
     +              'RDPAR_A:loop read FILEOUT_JCT, is',
     +              HC,' V=',VARIN
               LERROR=.TRUE.
            END IF
         END DO
      ELSEIF (HC(1:11).EQ.'FILEOUT_ERR') THEN
         FILEOUT_ERR=VARIN(1:FILEN_STRING(VARIN))
      ELSEIF (HC(1:12).EQ.'FILEOUT_YEAH') THEN
         FILEOUT_YEAH=VARIN(1:FILEN_STRING(VARIN))
C---- 
C---- unrecognised
C---- 
      ELSE
         WRITE(6,'(A,T10,A,A,A,A)')'***',
     +        'RDPAR_A: no interpretation of: hc= (',HC,
     +        '), var=(',VARIN,')'
         STOP '*** RDPAR_A: left due to error in reading inPar'
      END IF
*                                                                      *
C---- --------------------------------------------------
C---- error while reading?
      IF (LERROR) THEN
         WRITE(6,'(A,T10,A)')'***',
     +        'RDPAR_A: succession of parameters wrong'
         STOP '*** RDPAR_A: left due to error in reading inPar'
      END IF
      END
***** end of RDPAR_A

***** ------------------------------------------------------------------
***** SUB RDPAR_ERR
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDPAR_ERR
C---- ARG  : CHAR,VARIN 
C---- DES  : checks some typical errors of the parameter file read
C---- 
*     purpose:      T
*     in:           character indicating which variable is currently
*     in:           treated
*     out:          
*     called by:    READPAR_I,READPAR_F,READPAR_A
*     calling:      
*     lib:          
*     procedure:    
*----------------------------------------------------------------------*
*     Burkhard Rost             Sep,        1999        version 1.0    *
*     CUBIC                     http://www.columbia.edu                *
*     New York                  rost@columbia.edu                      *
*                      changed: Sep,        1999        version 0.1    *
*----------------------------------------------------------------------*
      SUBROUTINE RDPAR_ERR(CHAR_RD,VARIN)
C---- include parameter files
      INCLUDE 'nnPar.f'
C---- variables passed
      CHARACTER*132 CHAR_RD
      INTEGER       VARIN
C---- local parameters

C---- local variables                                                  *
******------------------------------*-----------------------------******
*                                                                      *
******------------------------------*-----------------------------******

C---- ------------------------------------------------------------------
C---- 
C---- ------------------------------------------------------------------
      IF     (CHAR_RD .EQ. 'NUMIN' .AND. NUMIN .GT. NUMIN_MAX) THEN
         WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +        'RDPAR_ERR: NUMIN read=',NUMIN,' NUMIN_MAX=',NUMIN_MAX
         STOP '*** RDPAR_ERR: left due to error in RDPAR_I'
      ELSEIF (CHAR_RD .EQ. 'NUMHID' .AND. NUMHID .GT. NUMHID_MAX) THEN
         WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +        'RDPAR_ERR: NUMHID read=',NUMHID,' NUMHID_MAX=',NUMHID_MAX
         STOP '*** RDPAR_ERR: left due to error in RDPAR_I'
      ELSEIF (CHAR_RD .EQ. 'NUMOUT' .AND. NUMOUT .GT. NUMOUT_MAX) THEN
         WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +        'RDPAR_ERR: NUMOUT read=',NUMOUT,' NUMOUT_MAX=',NUMOUT_MAX
         STOP '*** RDPAR_ERR: left due to error in RDPAR_I'
      ELSEIF (CHAR_RD .EQ. 'NUMSAM' .AND. NUMSAM .GT. NUMSAM_MAX) THEN
         WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +        'RDPAR_ERR: NUMSAM read=',NUMSAM,' NUMSAM_MAX=',NUMSAM_MAX
         STOP '*** RDPAR_ERR: left due to error in RDPAR_I'
      ELSEIF (CHAR_RD(1:7) .EQ. 'NUMFILE' .AND. 
     +        VARIN .GT. NUMFILES_MAX) THEN
         WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +        'RDPAR_ERR: NUMFILE* read=',VARIN,' NUMFILE_MAX=',
     +        NUMFILES_MAX
         STOP '*** RDPAR_ERR: left due to error in RDPAR_I'
      ELSEIF (CHAR_RD(1:9) .EQ. 'STPSWPMAX' .AND. 
     +        VARIN .GT. STPSWPMAX_MAX) THEN
         WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +        'RDPAR_ERR: STPSWPMAX read=',VARIN,' STPSWPMAX_MAX=',
     +        STPSWPMAX_MAX
         STOP '*** RDPAR_ERR: left due to error in RDPAR_I'
      ELSEIF (CHAR_RD(1:6) .EQ. 'STPMAX' .AND. 
     +        VARIN .GT. STPMAX_MAX) THEN
         WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +        'RDPAR_ERR: STPMAX read=',VARIN,' STPMAX_MAX=',
     +        STPMAX_MAX
         STOP '*** RDPAR_ERR: left due to error in RDPAR_I'
      ELSEIF (CHAR_RD(1:6) .EQ. 'STPINF' .AND. 
     +        VARIN .GT. STPMAX_MAX) THEN
         WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +        'RDPAR_ERR: STPINF read=',VARIN,' STPMAX_MAX=',
     +        STPMAX_MAX
         STOP '*** RDPAR_ERR: left due to error in RDPAR_I'
      END IF
      END 
***** end of RDPAR_ERR

***** ------------------------------------------------------------------
***** SUB RDPAR_WRT
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDPAR_WRT
C---- ARG  : 
C---- DES  : reading and interpreting one line with F12.3 input
C---- IN   : 
C---- FROM : RDPAR  
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDPAR_WRT

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables
      INTEGER       IT
      CHARACTER*80  CTMP,CTMP2
******------------------------------*-----------------------------******
C---- 
      CTMP='--- RDpar: '
      CTMP2='--------------------------------------------------'
C      WRITE(6,'(A)')'--- '
      WRITE(6,'(A,T16,A50)')CTMP,CTMP2
      WRITE(6,'(A,T16,A)')CTMP,'Parameters read:'
C---- 
C---- integers
C---- 
      WRITE(6,'(A,T16,A)')CTMP,' '
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMIN',NUMIN
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMHID',NUMHID
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMOUT',NUMOUT
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMLAYERS',NUMLAYERS
C---- 
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMSAM',NUMSAM
C---- 
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMFILEIN_IN',NUMFILEIN_IN
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMFILEIN_OUT',NUMFILEIN_OUT
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMFILEOUT_OUT',NUMFILEOUT_OUT
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'NUMFILEOUT_JCT',NUMFILEOUT_JCT
C---- 
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'STPSWPMAX',STPSWPMAX
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'STPMAX',STPMAX
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'STPINF',STPINF
      WRITE(6,'(A,T16,A,T35,I8)')CTMP,'ERRBINSTOP',ERRBINSTOP
C---- 
C---- reals
C---- 
      WRITE(6,'(A,T16,A)')CTMP,' '
      WRITE(6,'(A,T16,A,T35,F15.6)')CTMP,'EPSILON',EPSILON
      WRITE(6,'(A,T16,A,T35,F15.6)')CTMP,'ALPHA',ALPHA
      WRITE(6,'(A,T16,A,T35,F15.6)')CTMP,'TEMPERATURE',TEMPERATURE
C---- 
      WRITE(6,'(A,T16,A,T35,F15.6)')CTMP,'ERRSTOP',ERRSTOP
      WRITE(6,'(A,T16,A,T35,F15.6)')CTMP,'ERRBIAS',ERRBIAS
C---- 
C---- characters
C---- 
      WRITE(6,'(A,T16,A)')CTMP,' '
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'TRNTYPE',TRNTYPE(1:FILEN_STRING(TRNTYPE))
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'TRGTYPE',TRGTYPE(1:FILEN_STRING(TRGTYPE))
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'ERRTYPE',ERRTYPE(1:FILEN_STRING(ERRTYPE))
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'MODEPRED',MODEPRED(1:FILEN_STRING(MODEPRED))
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'MODENET',MODENET(1:FILEN_STRING(MODENET))
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'MODEIN',MODEIN(1:FILEN_STRING(MODEIN))
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'MODEJOB',MODEJOB(1:FILEN_STRING(MODEJOB))
C---- 
C---- files
C---- 
      DO IT=1,NUMFILEIN_IN
         WRITE(6,'(A,T16,A,T30,I4,A1,A)')CTMP,'FILEIN_IN',IT,' ',
     +        FILEIN_IN(IT)(1:FILEN_STRING(FILEIN_IN(IT)))
      END DO
      DO IT=1,NUMFILEIN_OUT
         WRITE(6,'(A,T16,A,T30,I4,A1,A)')CTMP,'FILEIN_OUT',IT,' ',
     +        FILEIN_OUT(IT)(1:FILEN_STRING(FILEIN_OUT(IT)))
      END DO
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'FILEIN_JCT',FILEIN_JCT(1:FILEN_STRING(FILEIN_JCT))
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'FILEIN_SAM',FILEIN_SAM(1:FILEN_STRING(FILEIN_SAM))
      DO IT=1,NUMFILEOUT_OUT
         WRITE(6,'(A,T16,A,T30,I4,A1,A)')CTMP,'FILEOUT_OUT',IT,' ',
     +        FILEOUT_OUT(IT)(1:FILEN_STRING(FILEOUT_OUT(IT)))
      END DO
      DO IT=1,NUMFILEOUT_JCT
         WRITE(6,'(A,T16,A,T30,I4,A1,A)')CTMP,'FILEOUT_JCT',IT,' ',
     +        FILEOUT_JCT(IT)(1:FILEN_STRING(FILEOUT_JCT(IT)))
      END DO
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'FILEOUT_ERR',FILEOUT_ERR(1:FILEN_STRING(FILEOUT_ERR))
      WRITE(6,'(A,T16,A,T35,A)')CTMP,
     +     'FILEOUT_YEAH',FILEOUT_YEAH(1:FILEN_STRING(FILEOUT_YEAH))
      WRITE(6,'(A,T16,A,T35)')CTMP,'end of reading parameters'
      END
***** end of RDPAR_WRT

***** ------------------------------------------------------------------
***** SUB RDSAM
***** ------------------------------------------------------------------
C---- 
C---- NAME : RDSAM
C---- ARG  : 
C---- DES  : reads the succession of samples   
C---- IN   : 
C---- FROM : MAIN 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE RDSAM

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables                                                  *
      INTEGER       IT,STPMAXLOC,VARIN
      CHARACTER*80  HC,MREAD
      LOGICAL       LDONE,LREAD
******------------------------------*-----------------------------******
C     message onto screen
C      WRITE(6,'(A)')'--- '
      WRITE(6,'(A,T16,A)')'--- RDsam file=',
     +     FILEIN_SAM(1:FILEN_STRING(FILEIN_SAM))
C---- read parameters from file NN_InPar
      CALL SFILEOPEN(10,FILEIN_SAM,'OLD',150,'READONLY')
      LDONE=.FALSE.

      DO WHILE (.NOT.LDONE)
         LREAD=.FALSE.
         READ(10,'(A3)',END=6067)HC
C------- terminate reading
         IF     (HC(1:2).EQ.'//') THEN
            LDONE=.TRUE.
            LREAD=.FALSE.
         ELSEIF (HC(1:3).EQ.'* o') THEN
            LREAD=.FALSE.
            MREAD='H'
         ELSEIF (HC(1:3).EQ.'* p') THEN
            LREAD=.FALSE.
            MREAD='D'
         ELSEIF (HC(1:1).NE.'*') THEN
            BACKSPACE 10
            LREAD=.TRUE.
         ELSE
            LREAD=.FALSE.
         END IF

         IF (LREAD) THEN
            IF     (MREAD.EQ.'H') THEN
               READ(10,'(A20,T25,I8)',END=6067)HC,VARIN
               STPMAXLOC=VARIN
               IF     (HC(1:6).NE.'STPMAX') THEN
                  WRITE(6,'(A,T10,A,A)')'***',
     +                 'ERROR RDSAM not NUMSAM:',HC
                  STOP '*** RDSAM: left due to error in reading inSam'
               ELSEIF (STPMAXLOC.LT.STPMAX) THEN
                  WRITE(6,'(A,T10,A,I8,A,I8)')'***',
     +                 'ERROR RDSAM STPMAXLOC=',STPMAXLOC,
     +                 ' STPMAX=',STPMAX
Cxx                  STOP '*** RDPAR: left due to error in reading inSam'
               END IF
            ELSEIF (MREAD.EQ.'D') THEN
               READ(10,'(25I8)',END=6067)(PICKSAM(IT),IT=1,STPMAXLOC)
Cxx               READ(10,'(25I8)',END=6067)(PICKSAM(IT),IT=1,STPMAX)
               LDONE=.TRUE.
            ELSE
               WRITE(6,'(A,T10,A,A,A)')'***',
     +              'ERROR RDSAM MREAD not recognised:',MREAD,':'
               STOP '*** RDPAR: left due to error in reading inPar'
            END IF
         END IF
      END DO
 6067 CONTINUE
      CLOSE(10)
      END 
***** end of RDSAM

***** ------------------------------------------------------------------
***** SUB NETOUT(LERR,LBIN,STP)
***** ------------------------------------------------------------------
C---- 
C---- NAME : NETOUT
C---- ARG  : LERR,LBIN,STP
C---- DES  : executes network NETOUT function  input --> output 
C---- IN   : logicals : do error? do error bin?, current step 
C---- FROM : MAIN, TRAIN 
C---- CALL2: NETOUT_MUE, NETOUT_BIN, NETOUT_ERR 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE NETOUT(LERR,LBIN,STP)

C---- parameters/global variables
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       MUE,STP,ITOUT
      LOGICAL       LBIN,LERR
******------------------------------*-----------------------------******
*     INPUT (NUMHID,NUMIN+) input matrix                               *
*                   is used                                            *
*     INVABW        =1/ABW for avoiding too high quantities            *
*     FLD           the local fields (abbr.: h) are defined by:        *
*                   h(I,MUE )= sum(k,{J(k,i)*s(k,mue))+b(i,mue)        *
*     NEGINVABW     =-INVABW                                           *
******------------------------------*-----------------------------******
C---- cutoffs
      INVABW=1./ABW
      NEGINVABW=(-1.)*INVABW
*                                                                      *
C---- --------------------------------------------------
C---- loop over all samples (residues)
C---- --------------------------------------------------
      DO MUE=1,NUMSAM
C----    
C----    this burns CPU! network input-> output
C----    
         CALL NETOUT_MUE(MUE)
C         WRITE(6,'(A,I5,A,3I4,A,3I4)')'dbg: NETOUT mue=',MUE,
C     +        ' out=',(INT(100*OUTPUT(ITOUT)),ITOUT=1,NUMOUT),
C     +        ' des=',(OUTDES(ITOUT,MUE),ITOUT=1,NUMOUT)

C         WRITE(6,'(A,I5,A,3I4)')'dbg: NETOUT mue=',MUE,
C     +        ' out=',(INT(100*OUTPUT(ITOUT)),ITOUT=1,NUMOUT)

C---- 
C----    this HAS burned CPU! network input-> output
C---- 

C        winner-take-all decision
         IF (LBIN) THEN
            CALL NETOUT_BIN(MUE)
         END IF
C        compile network error
         IF (LERR) THEN
            CALL NETOUT_ERR(MUE,STP)
         END IF
      END DO
C      WRITE(6,*)'yy err=',err(stp),' bin=',errbin(stp)

      END
***** end of NETOUT

***** ------------------------------------------------------------------
***** SUB NETOUT_MUE
***** ------------------------------------------------------------------
C---- 
C---- NAME : NETOUT_MUE
C---- ARG  : MUE
C---- DES  : executes network NETOUT function  input --> output 
C---- DES  : for one pattern 
C---- IN   : number of current pattern 
C---- FROM : NETOUT, TRAIN, WRTOUT   
C---- CALL2: 
C---- 
C---- IN GLOBAL  : INPUT, JCT1st, JCT2ND, NUMHID,*IN,*OUT,BITACC, 
C---- OUT GLOBAL : OUTPUT, FLD1st, FLD2nd 
C---- 
C----        *********************
C---- NOTE : heavy in terms of CPU  
C----        *********************
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE NETOUT_MUE(MUE)

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables                                                  *
      INTEGER       MUE,ITHID,ITIN,ITOUT
******------------------------------*-----------------------------******
C----
C---- compute local fields for hidden unit
C----
      DO ITHID=1,NUMHID
         FLD1ST(ITHID)=0.
         DO ITIN=1,NUMIN
            IF (INPUT(ITIN,MUE).NE.0.) THEN
               FLD1ST(ITHID)=FLD1ST(ITHID)
     +              +JCT1ST(ITIN,ITHID)*INPUT(ITIN,MUE)
            END IF
         END DO
C     rescale with BITACC
         FLD1ST(ITHID)=FLD1ST(ITHID)/REAL(BITACC)
C     threshold units
         FLD1ST(ITHID)=FLD1ST(ITHID)+JCT1ST((NUMIN+1),ITHID)
      END DO
C----
C---- compute value of hidden units
C----
C     VECTOR
      DO ITHID=1,NUMHID
         IF ( ABS(FLD1ST(ITHID)).LT.INVABW) THEN
            OUTHID(ITHID)=(1./(1.+EXP (- FLD1ST(ITHID) ) ))
         ELSEIF (FLD1ST(ITHID).LE.NEGINVABW) THEN
            OUTHID(ITHID)=0.
         ELSEIF (FLD1ST(ITHID).GE.INVABW) THEN
            OUTHID(ITHID)=1.
         ELSE
            WRITE(6,'(T2,A,T10,A,I8)')'***',
     +           'ERROR in NETOUT_MUE: wrong assignment MUE=',MUE
            WRITE(6,'(T2,A,T10,A)')'***',
     +           'intermediate output!! Stopped at 12-10-92-1'
            STOP '*** NETOUT_MUE: left due to error (FLD1ST wrong)'
         END IF
      END DO
C     END VECTOR
C----
C---- compute local field for second layer
C----
      DO ITOUT=1,NUMOUT
         FLD2ND(ITOUT)=0.
C        PARALLEL
         DO ITHID=1,NUMHID
            IF (OUTHID(ITHID).GT.ABW) THEN
               FLD2ND(ITOUT)=FLD2ND(ITOUT)+
     +              (JCT2ND(ITHID,ITOUT)*OUTHID(ITHID))
            END IF
         END DO
C        END PARALLEL
C     threshold unit
         FLD2ND(ITOUT)=FLD2ND(ITOUT)+JCT2ND((NUMHID+1),ITOUT)
      END DO
C----
C---- compute output
C----
      DO ITOUT=1,NUMOUT
         IF ((ABS(FLD2ND(ITOUT)).LT.INVABW).AND.
     +        (FLD2ND(ITOUT).GT.NEGINVABW)) THEN
            OUTPUT(ITOUT)=1./(1.+ EXP (- FLD2ND(ITOUT) ))
         ELSEIF (FLD2ND(ITOUT).LE.NEGINVABW) THEN
            OUTPUT(ITOUT)=0.
         ELSEIF (FLD2ND(ITOUT).GE.INVABW) THEN
            OUTPUT(ITOUT)=1.
         ELSE
            WRITE(6,'(T2,A,T10,A,I8)')'***',
     +           'ERROR in NETOUT_MUE: output wrong assigned, MUE=',MUE
            WRITE(6,'(T2,A,T10,A)')'***','stopped at 12-10-92-2'
            STOP '*** NETOUT_OUT: left due to error (FLD2ND wrong)'
         END IF
      END DO
      
      END 
***** end of NETOUT_MUE

***** ------------------------------------------------------------------
***** SUB NETOUT_BIN
***** ------------------------------------------------------------------
C---- 
C---- NAME : NETOUT_BIN
C---- ARG  : MUE
C---- DES  : winner-take-all decision, only maximal unit will be
C---- DES  : set to 1 
C---- IN   : number of current pattern 
C---- FROM : NETOUT, TRAIN 
C---- CALL2: 
C---- LIB  : FRMAX1 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE NETOUT_BIN(MUE)

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local functions
      REAL          FRMAX1
C---- local variables
      INTEGER       MUE,ITOUT
      REAL          HELPMAX
******------------------------------*-----------------------------******
C---- 
C---- the winner takes it all
C---- 
      OUTWIN(MUE)=0
      IF (NUMOUT.EQ.1) THEN
         IF (OUTPUT(1).GT.THRESHOUT) THEN
            OUTWIN(MUE)=1
         END IF
      ELSE
C     security: set zero
         DO ITOUT=(NUMOUT+1),NUMOUT_MAX
            OUTPUT(ITOUT)=0
         END DO
C     find max
         HELPMAX=FRMAX1(OUTPUT,NUMOUT_MAX)
C     which unit
         DO ITOUT=1,NUMOUT
            IF (OUTPUT(ITOUT).EQ.HELPMAX) THEN
               OUTWIN(MUE)=ITOUT
            END IF
         END DO
      END IF
*                                                                      *
C---- 
C---- at least one bin = 1 ?
C---- 
      IF ((OUTWIN(MUE).EQ.0).AND.(NUMOUT.GT.1)) THEN
         WRITE(6,'(T2,A,T10,A,I8)')'***',
     +        'ERROR NETOUT_BIN no winner, mue=',mue
         WRITE(6,'(T2,A,T10,10F5.2)')'***',
     +        (OUTPUT(ITOUT),ITOUT=1,NUMOUT)
         STOP '*** NETOUT_BIN: left due to error (no winner)'
      END IF
      END
***** end of NETOUT_BIN

***** ------------------------------------------------------------------
***** SUB NETOUT_ERR
***** ------------------------------------------------------------------
C---- 
C---- NAME : NETOUT_ERR
C---- ARG  : MUE,STP
C---- DES  : compiles the current error committed by the NN 
C---- IN   : number of current pattern, number of current step
C---- OUT  : ERR(STP), OKBIN(STP), ERRBIN(STP) 
C---- note : additive, initialised for first pattern
C---- 
C---- FROM : NETOUT, TRAIN 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE NETOUT_ERR(MUE,STP)

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables                                                  *
      INTEGER       ITOUT,MUE,STP
      REAL          DELTA,RHELP
******------------------------------*-----------------------------******
C---- 
C---- setting zero for first pattern
C---- 
      IF (MUE.EQ.1) THEN
         ERR(STP)=0.
         OKBIN(STP)=0
         ERRBIN(STP)=100
      END IF
C---- 
C---- error per sample
C---- 
C     real error
      RHELP=0.0
      DO ITOUT=1,NUMOUT
         DELTA=OUTPUT(ITOUT)-(OUTDES(ITOUT,MUE)/BITACC)
         IF ( ABS(DELTA).GT.ABW) THEN
            RHELP=RHELP+(DELTA)**2
         END IF
      END DO
C     binary error
      IF (NUMOUT.EQ.1) THEN
         IF (((OUTDES(1,MUE).EQ.0).AND.
     +        (OUTPUT(1).LT.ERRBINACC)).OR.
     +       ((OUTDES(1,MUE).EQ.BITACC).AND.
     +        (OUTPUT(1).GT.(1-ERRBINACC)))) THEN
            OKBIN(STP)=OKBIN(STP)+1
         END IF
      ELSE
         POSWIN=OUTWIN(MUE)
         IF (((OUTPUT(POSWIN).LT.ERRBINACC).AND.
     +        (OUTDES(POSWIN,MUE).EQ.0)).OR.
     +        ((OUTPUT(POSWIN).GT.(1-ERRBINACC)).AND.
     +        (OUTDES(POSWIN,MUE).EQ.BITACC))) THEN
            OKBIN(STP)=OKBIN(STP)+1
         END IF
      END IF
C     total error
      ERR(STP)=ERR(STP)+RHELP
C---- 
C---- scaling error for last sample
C---- 
      IF (MUE.EQ.NUMSAM) THEN
C         ERR(STP)=(1./REAL(NUMSAM))*(1./REAL(NUMOUT))*ERR(STP)
         ERR(STP)=(1./REAL(NUMSAM))*(1./REAL(NUMOUT))*ERR(STP)
         ERRBIN(STP)=100*(1.-(OKBIN(STP)/REAL(NUMSAM)))
      END IF
      END 
***** end of NETOUT_ERR

***** ------------------------------------------------------------------
***** SUB TRAIN
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRAIN
C---- ARG  : 
C---- DES  : optimized version of error back-prop training 
C---- IN   : 
C---- FROM : MAIN 
C---- CALL2: TRAIN_BACKPROP
C---- CALL2: TRAIN_INIMUE  -> NETOUT_MUE, lib: SRSTE2, SRSTZ2 
C---- CALL2: TRAIN_INISWP  ->             lib: STRSTZ2           
C---- CALL2: TRAIN_STOP                                          
C---- CALL2: TRAIN_WRT                                           
C---- CALL2: NETOUT        -> NETOUT_MUE|BIN|ERR                 
C---- CALL2: WRTJCT        ->             lib: SFILEOPEN, WRTHEAD
C---- CALL2: WRTOUT        -> NETOUT_MUE, WRTHEAD, lib: SFILEOPEN
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE TRAIN

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       MUE,ITIN,ITHID,ITOUT
      REAL          DELTA(1:NUMOUT_MAX),FACDELTA(1:NUMOUT_MAX)
      REAL*4        RHELP,VECSUM
      CHARACTER*80  CTMP,CTMP2
      LOGICAL       LERR,LBIN,LSTOP,LCONT
******------------------------------*-----------------------------******
      LERR=.TRUE.
      LBIN=.TRUE.
      CTMP='--- TRAIN: '
      CTMP2='--------------------------------------------------'

C     writing into header (arrived at OTRNON asf)
      WRITE(6,'(A15,A50)')CTMP,CTMP2
      WRITE(6,'(A15)')CTMP
      WRITE(6,'(A15,A)')CTMP,'----------------'
      WRITE(6,'(A15,A)')CTMP,'arrived in TRAIN'
      WRITE(6,'(A15,A)')CTMP,'----------------'
      WRITE(6,'(A15)')CTMP

C     initialise 1: check training accuracy asf.
      CALL NETOUT(LERR,LBIN,STPNOW)
      CALL TRAIN_STOP(LSTOP,STPNOW,CTMP)
      CALL TRAIN_WRT(CTMP,0,0)

      IF (LSTOP) THEN
C     never enter the while !
         LCONT=    .FALSE.
      ELSE
C     ini for first sweep (stpswp)
         LCONT=    .TRUE.
         STPSWPNOW=1
         STPNOW=   0
      END IF

C-----------------------------------------------------------------------
C---- THE LOOP: by intrinsic time scale: STPNOW
C----           intrinsic time scale given by training set
C-----------------------------------------------------------------------
      DO WHILE ((STPSWPNOW.LE.STPSWPMAX) .AND. 
     +          (STPNOW.LE.STPMAX) .AND. LCONT) 

C----    (0) PDJCT1ST,PDJCT2ND,DJCT1ST,DJCT1ST == 0
C----    (n) count up (STPNOW,STPSWPNOW,STPINFNOW)
         CALL TRAIN_INISWP(CTMP)

C----    end learning after STPMAX steps
         IF (STPNOW.GT.STPMAX) THEN
            STPSWPNOW=STPSWPMAX
            STPNOW=   STPNOW-1
            LCONT=    .FALSE.
         ELSE
            MUE=PICKSAM(STPNOW)
            IF (MUE .EQ.0) THEN
               WRITE(6,*)'*** ERROR TRAIN: (MUE=0) STPNOW=',STPNOW
               STOP
            ENDIF
C----       set OUTPUT for current MUE
            CALL TRAIN_INIMUE(MUE)

C----       here goes THE thing 
            CALL TRAIN_BACKPROP(MUE)
         END IF

C------- write info about how far things have come
         IF (STPINFNOW.EQ.STPINF) THEN
            STPINFNOW=0
            STPINFCNT=STPINFCNT+1
C---------- network input -> output
            CALL NETOUT(LERR,LBIN,STPINFCNT)
C---------- write onto screen
            CALL TRAIN_WRT(CTMP,STPINFCNT,STPNOW)
C---------- write the current output into file
            CALL WRTOUT(10,FILEOUT_OUT(STPINFCNT),STPINFCNT,STPNOW)
C---------- write current junctions into file
            CALL WRTJCT(10,FILEOUT_JCT(STPINFCNT))
C---------- error low enough?
            CALL TRAIN_STOP(LSTOP,STPNOW,CTMP)
C---------- terminate!
            IF (LSTOP) THEN
               LCONT= .FALSE.
            END IF
         END IF
C------- end of one back-prop step
      END DO
C---- end of loop over STPSWP (i.e. all samples)
C-----------------------------------------------------------------------

      IF (STPSWPNOW.GE.STPSWPMAX) THEN
         WRITE(6,'(A15,A,I8,A,I8)')CTMP,'end reached for STSWPNOW=',
     +        STPSWPNOW,' >= STPSWPMAX=',STPSWPMAX
      END IF
      IF (STPNOW.GE.STPMAX) THEN
         WRITE(6,'(A15,A,I8,A,I8)')CTMP,'end reached for STNOW=',
     +        STPNOW,' >= STPMAX=',STPMAX
      END IF
      END
***** end of TRAIN

***** ------------------------------------------------------------------
***** SUB TRAIN_BACKPROP
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRAIN_BACKPROP
C---- ARG  : MUE
C---- DES  : optimized version of error back-prop training 
C---- IN   : current pattern MUE
C---- FROM : TRAIN
C---- CALL2: 
C---- 
*     procedure:    back-prop algorithm
*                   
*                   d(i) = desired output for unit i (1..numout=N2)
*                   o(i) = output for unit i (1..numout=N2)
*                   h(j) = hidden output for unit j (1..numhid=N1)
*                   s(k) = input for unit k (1..numin=N0)
*                   
*                   J1   : junction between hidden and input
*                   J2   : junction between output and hidden
*                   
*                   f(x)     = 1 / (1 + e^(-x)) sigmoid
*                   df/dx    = f ( 1 - f)       (df/dx)
*                   
*                   
*                                  N1+1            
*                   o(i)     = f ( SUM J2(ij)* f ( h(j) ) )
*                                   j              
*                   
*                                  N0+1
*                   h(j)     = f ( SUM J1(jk) * s(k) )
*                                   k
*                               N2                 
*                   E        = SUM ( o(i) - d(i) ) **2 
*                               i
*                   
*                   DELTA(i) = o(i) - d(i)
*                   
*                                         +--- is f' ---+
*                     dE                  |             |
*                   -------   = DELTA(i) * o(i)*(1-o(i)) * h(j)
*                   dJ2(ij)
*                                     +--- is f' ---+
*                     dE              |             |
*                   -------   = s(k) * h(j)*(1-h(j)) * VECSUM(j)
*                   dJ1(jk)
*                                N2
*                   VECSUM(j) = SUM J2(ij) * o(i)*(1-o(i)) * DELTA(i)
*                                i
*                                         dE       DELTA(i)
*                   E -> ln ( 1 - E ) => ---- -> -----------------
*                                         dJ      1 - DELTA(i)**2
*                   
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE TRAIN_BACKPROP(MUE)

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables                                                  *
      INTEGER       MUE,ITIN,ITHID,ITOUT
      REAL          DELTA(1:NUMOUT_MAX),FACDELTA(1:NUMOUT_MAX),DIFF
      REAL*4        RHELP,VECSUM
      CHARACTER*80  CTMP,CTMP2
      LOGICAL       LERR,LBIN,LSTOP,LCONT
*                                                                      *
******------------------------------*-----------------------------******
*     FACDELTA      the factor of 'all deltas', i.e.:                  *
*                   FACDELTA= f''(out)*(out-des), or corresponding     *
*                   quantity for algorithms other than sigmoid         *
*     MOMENTUM      intermediately required variable storing the       *
*                   'momentum' = alpha * olddeljunc                    *
*     STPINFCNT     counts the steps of learning up to each STPINFth   *
*                   one and is set zero then                           *
*     DELTA         for particular i,mue: output(i,mue)-desired(i,mue) *
*     PDELJCT1st/2nd  stores the changes from the last TIME            *
******------------------------------*-----------------------------******

C---- ------------------------------------------------------------------
C---- prefactors for changing junctions 
C---- 
C---- i=1,numout:
C----    DELTA(i)=    [ OUT(i) - OUTDES(i) ]
C----    FACDELTA(i)= DELTA(i) * OUT(i) * (1-OUT(i))
C---- where:
C----    OUT*(1-OUT)= derivative of sigmoid!
C---- ------------------------------------------------------------------
      DO ITOUT=1,NUMOUT
         IF (ERRBIAS.EQ.0.) THEN
            DELTA(ITOUT)=OUTPUT(ITOUT)-(OUTDES(ITOUT,MUE)/REAL(BITACC))
         ELSE
            IF (OUTDES(ITOUT,MUE).EQ.BITACC) THEN
               DELTA(ITOUT)= ERRBIAS+OUTPUT(ITOUT)-1.
            ELSE
               DELTA(ITOUT)=-ERRBIAS
     +              +OUTPUT(ITOUT)-(OUTDES(ITOUT,MUE)/REAL(BITACC))
            END IF
         END IF
C------- different for E = ln (1 -deltasq)
C----    note: not activated to speed up!!
Csleep         IF (ERRTYPE(1:12).EQ.'LN_1-DELTASQ') THEN
         DIFF= 1 - ( DELTA(ITOUT)*DELTA(ITOUT) )
C         IF (ABS(DIFF).LT.10E-8) THEN
         IF (ABS(DIFF).LT.ABW) THEN
            DELTA(ITOUT)=1.
         ELSE
            DELTA(ITOUT)=DELTA(ITOUT)/DIFF
         END IF
Csleep         END IF
C------- final factors
         FACDELTA(ITOUT)=
     +        DELTA(ITOUT) * OUTPUT(ITOUT)*(1.-(OUTPUT(ITOUT)))
C------- setting FACDELTA to zero, if below threshold ABW
C         IF (ABS(FACDELTA(ITOUT)).LT.10E-10) THEN
         IF (ABS(FACDELTA(ITOUT)).LT.ABW) THEN
            FACDELTA(ITOUT)=0.
         END IF
      END DO
C---- end of prefactors for output units

C---- ------------------------------------------------------------------
C---- changes for last layer
C---- 
C---- i=1,numout; k=1,numhid+1
C----    DJ2(k,i)=-1 * epsilon * FACDELTA(i) * OUTHID(k) 
C----                      + alpha * previousDJ2(k,i)
C---- ------------------------------------------------------------------
      DO ITOUT=1,NUMOUT
         RHELP=(-1) * EPSILON * FACDELTA(ITOUT)
         DO ITHID=1,(NUMHID+1)
C---------- momentum
            IF ( (ALPHA.GT.0).AND.
     +           (ABS(PDJCT2ND(ITHID,ITOUT)).GT.ABW)) THEN
               DJCT2ND(ITHID,ITOUT)=RHELP*OUTHID(ITHID)
     +              + ALPHA*PDJCT2ND(ITHID,ITOUT)
            ELSE
               DJCT2ND(ITHID,ITOUT)=RHELP*OUTHID(ITHID)
            END IF
         END DO
      END DO

C---- ------------------------------------------------------------------
C---- changes for first layer
C---- 
C---- k=1,numhid; m=1,numin+1
C----    DJ1(m,k)=-1 * epsilon * J2(k,i) * FACDELTA(i) 
C----                * OUTHID(k) * (1-OUTHID(k)) * INPUT(m) 
C----                      + alpha * previousDJ1(k,m)
C---- 
C---- 
C---- ------------------------------------------------------------------
      DO ITHID=1,NUMHID
         VECSUM=0.
         DO ITOUT=1,NUMOUT
            IF (FACDELTA(ITOUT).NE.0.) THEN
               VECSUM=VECSUM+(JCT2ND(ITHID,ITOUT)*FACDELTA(ITOUT))
            END IF
         END DO
         VECSUM=VECSUM*(-1)*EPSILON*OUTHID(ITHID)*(1.-OUTHID(ITHID))
         DO ITIN=1,(NUMIN+1)
C---------- momentum
            IF ( (ALPHA.GT.0).AND.
     +           (ABS(PDJCT1ST(ITIN,ITHID)).GT.ABW)) THEN
               DJCT1ST(ITIN,ITHID)=
     +              VECSUM*(INPUT(ITIN,MUE)/REAL(BITACC))
     +              + ALPHA*PDJCT1ST(ITIN,ITHID)
            ELSE
               DJCT1ST(ITIN,ITHID)=
     +                 VECSUM*(INPUT(ITIN,MUE)/REAL(BITACC))
            END IF
         END DO
      END DO

C---- ------------------------------
C---- update junctions for MUE
C---- ------------------------------
C     first layer
      DO ITHID=1,NUMHID
         DO ITIN=1,(NUMIN+1)
            IF (ABS(DJCT1ST(ITIN,ITHID)).GT.ABW) THEN
               JCT1ST(ITIN,ITHID)=
     +              JCT1ST(ITIN,ITHID)+DJCT1ST(ITIN,ITHID)
            END IF
         END DO
      END DO
      
C     second layer
      DO ITOUT=1,NUMOUT
         DO ITHID=1,(NUMHID+1)
            IF (ABS(DJCT1ST(ITHID,ITOUT)).GT.ABW) THEN
               JCT2ND(ITHID,ITOUT)=
     +              JCT2ND(ITHID,ITOUT)+DJCT2ND(ITHID,ITOUT)
            END IF
         END DO
      END DO

C---- ------------------------------------------------------------------
C---- end of back-propagation for SAMPLE MUE
C---- ------------------------------------------------------------------

      END 
***** end of TRAIN_BACKPROP

***** ------------------------------------------------------------------
***** SUB TRAIN_INIMUE
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRAIN_INIMUE
C---- ARG  : MUE
C---- DES  : initialises DJ1, DJ2, 
C---- IN   : 
C---- FROM : TRAIN
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE TRAIN_INIMUE(MUE)

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables                                                  *
      INTEGER       MUE
******------------------------------*-----------------------------******
C---- setting previous changes to olddel
      IF ((ALPHA.GT.0).AND.((EPSILON/ALPHA).LE.10)) THEN
         CALL SRSTE2(PDJCT1ST,DJCT1ST,(NUMIN_MAX+1),NUMHID_MAX)
         CALL SRSTE2(PDJCT2ND,DJCT1ST,(NUMHID_MAX+1),NUMOUT_MAX)
      END IF
C---- setting deltaJ to 0
      IF (STPNOW.GT.1) THEN
         CALL SRSTZ2(DJCT1ST,(NUMIN_MAX+1),NUMHID_MAX)
         CALL SRSTZ2(DJCT1ST,(NUMHID_MAX+1),NUMOUT_MAX)
      END IF
C---- call trigger
      CALL NETOUT_MUE(MUE)
      END 
***** end of TRAIN_INIMUE

***** ------------------------------------------------------------------
***** SUB TRAIN_INISWP
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRAIN_INISWP
C---- ARG  : CTMP
C---- DES  : 
C---- IN   : 
C---- FROM : 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE TRAIN_INISWP(CTMP)

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables                                                  *
      CHARACTER*80  CTMP
******------------------------------*-----------------------------******

C---- for first step set deltaJ and previous deltaJ to zero
      IF (STPNOW.EQ.0) THEN
         CALL SRSTZ2(PDJCT1ST,(NUMIN_MAX+1),NUMHID_MAX)
         CALL SRSTZ2(PDJCT2ND,(NUMHID_MAX+1),NUMOUT_MAX)
         CALL SRSTZ2(DJCT1ST,(NUMIN_MAX+1),NUMHID_MAX)
         CALL SRSTZ2(DJCT1ST,(NUMHID_MAX+1),NUMOUT_MAX)
         WRITE(6,'(A15,A)')CTMP,'First cycle PDJ, DJ: all set to zero'
      END IF

C---- count up
      STPNOW=      STPNOW+1
      STPINFNOW=   STPINFNOW+1
C---- count up STPSWPNOW ? 
      IF (STPSWPNOW*NUMSAM .LE. STPNOW) THEN
         STPSWPNOW=STPSWPNOW+1
      END IF
      END 
***** end of TRAIN_INISWP

***** ------------------------------------------------------------------
***** SUB TRAIN_STOP(LSTOP,STPLOC,CTMP)
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRAIN_STOP(LSTOP,STPLOC,CTMP)
C---- ARG  : 
C---- DES  : checks whether stop condition reached 
C---- IN   : 
C---- FROM : TRAIN
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE TRAIN_STOP(LSTOP,STPLOC,CTMP)

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       STPLOC,ITER
      CHARACTER*80  CTMP
      LOGICAL       LSTOP
******------------------------------*-----------------------------******
      LSTOP=.FALSE.
      IF ( (ERR(STPINFCNT).LE.ERRSTOP).OR.
     +     (ERRBIN(STPINFCNT).LE.ERRBINSTOP) ) THEN
         WRITE(6,'(A15)')CTMP
         WRITE(6,'(A15,60A1)')CTMP,('-',ITER=1,60)
         WRITE(6,'(A15,A,I8)')CTMP,
     +        'stop condition reached in stpinfcnt=',STPINFCNT
         IF (ERR(STPINFCNT).LE.ERRSTOP) THEN
            WRITE(6,'(A15,A,F10.4,A,F10.4)')CTMP,
     +           'REAL ERROR:',ERR(STPINFCNT),' < ',ERRSTOP
         ELSE
            WRITE(6,'(A15,A,F8.2,A,F8.2)')CTMP,
     +           'BIN  ERROR:',ERRBIN(STPINFCNT),' < ',ERRBINSTOP

         END IF
         WRITE(6,'(A15,A6,A2,I8,A,A2,F10.4,A,F10.4)')CTMP,
     +        'STP   ',': ',STPLOC,   '  ERR   ',': ',ERR(STPINFCNT),
     +        '   ERRSTOP   :',ERRSTOP
         WRITE(6,'(A15,A6,A2,I8,A,A2,F8.2,A,F8.2)')CTMP,
     +        'STPINF',': ',STPINFCNT,'  ERRBIN',': ',ERRBIN(STPINFCNT),
     +        '     ERRBINSTOP:',ERRBINSTOP
         LSTOP=.TRUE.
      END IF
      END 
***** end of TRAIN_STOP

***** ------------------------------------------------------------------
***** SUB TRAIN_WRT(CTMP,STPINFLOC,STPLOC,STPMAX,STPSWPNOW,STPSWPMAX)
***** ------------------------------------------------------------------
C---- 
C---- NAME : TRAIN_WRT(CTMP,STPINF,STPNOW,STPMAX,STPSWPNOW,STPSWPMAX)
C---- ARG  : 
C---- DES  : write current accuracy onto screen  
C---- IN   : CTMP   begin of line to write
C---- IN   : STPINF number of times all information about accuracy
C---- IN   :        has been written so far (including current step)
C---- IN   : STPNOW current step
C---- IN   : STPMAX maximal number of steps allowed (then stop!)
C---- IN   : STPSWPNOW number of sweeps (one sweep = once through
C---- IN   :        ALL patterns)
C---- IN   : STPSWPMAX maximal number of sweeps allowed (then stop!)
C---- IN   : 
C---- FROM : TRAIN 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998      version 1.0      *
*                      changed: Sep,        1999      version 1.0      *
*----------------------------------------------------------------------*
      SUBROUTINE TRAIN_WRT(CTMP,STPINFLOC,STPLOC)

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       STPINFLOC,STPLOC,STPINFMAXLOC,
     +              STPSWPNOWLOC,STPSWPMAXLOC
      CHARACTER*(*) CTMP
******------------------------------*-----------------------------******
C---- 
C---- current accuracy (err,errbin, asf)
C---- 
      WRITE(6,'(A15,A)')CTMP,'--------------------'
      WRITE(6,'(A15,A)')CTMP,'accuracy: '
C      WRITE(6,'(A15,4(A,I8))')CTMP,
C     +     'STPSWP',STPSWPNOWLOC,' max=',STPSWPMAXLOC,
C     +     'STPINF',STPINFLOC,' max=',STPMAXLOC
      WRITE(6,'(A15,A6,A2,I8,A,A2,F10.4)')CTMP,
     +     'STP   ',': ',STPLOC,   '  ERR   ',': ',ERR(STPINFLOC)
      WRITE(6,'(A15,A6,A2,I8,A,A2,F8.2)')CTMP,
     +     'STPINF',': ',STPINFLOC,'  ERRBIN',': ',ERRBIN(STPINFLOC)
      END 
***** end of TRAIN_WRT

***** ------------------------------------------------------------------
***** SUB WRTJCT(KUNIT,FILE)
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRTJCT(KUNIT,FILE)
C---- ARG  : 
C---- DES  : writes the current architecture 
C---- IN   : 
C---- FROM : MAIN
C---- CALL2: WRTHEAD
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRTJCT(KUNIT,FILE)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables
      INTEGER       ITIN,ITHID,ITOUT,KUNIT
      CHARACTER*(*) FILE
******------------------------------*-----------------------------******
C---- open file 
      IF (KUNIT.NE.6) THEN
         CALL SFILEOPEN(KUNIT,FILE,'UNKNOWN',150,' ')
      END IF
C---- 
C---- header tag
C---- 
      WRITE(KUNIT,'(A2,A20,A)')'* ',
     +     'NNout_jct            ',
     +     'file from FORTRAN NN.f (junctions)'
C---- 
C---- header blabla
C---- 
      CALL WRTHEAD(KUNIT)
C---- 
C---- header numbers
C----
      WRITE(KUNIT,'(A2,A)')'* ','--------------------'
      WRITE(KUNIT,'(A2,A)')'* ','overall: (A,T25,I8)'
      WRITE(KUNIT,'(A,A2,T25,I8)')'NUMIN',': ',NUMIN
      WRITE(KUNIT,'(A,A2,T25,I8)')'NUMHID',': ',NUMHID
      WRITE(KUNIT,'(A,A2,T25,I8)')'NUMOUT',': ',NUMOUT
C----
      WRITE(KUNIT,'(A,A2,T25,A)')
     +     'MODEPRED',': ',MODEPRED(1:FILEN_STRING(MODEPRED))
      WRITE(KUNIT,'(A,A2,T25,A)')
     +     'MODENET',': ', MODENET(1:FILEN_STRING(MODENET))
      WRITE(KUNIT,'(A,A2,T25,A)')
     +     'MODEJOB',': ', MODEJOB(1:FILEN_STRING(MODEJOB))
      WRITE(KUNIT,'(A,A2,T25,A)')
     +     'MODEIN',': ',  MODEIN(1:FILEN_STRING(MODEIN))
      WRITE(KUNIT,'(A,A2,T25,A)')
     +     'MODEOUT',': ', MODEOUT(1:FILEN_STRING(MODEOUT))
C---- 
C---- 1st layer
C---- 
      WRITE(KUNIT,'(A2,A)')'* ','--------------------'
      WRITE(KUNIT,'(A2,A)')'* ',
     +     'jct 1st layer: row=numhid (10F10.4), col=(numin+1)'
C     jct1st
      DO ITHID=1,NUMHID
         WRITE(KUNIT,'(10F10.4)')
     +        (JCT1ST(ITIN,ITHID),ITIN=1,(NUMIN+1))
      END DO
C---- 
C---- 2nd layer
C---- 
      WRITE(KUNIT,'(A2,A)')'* ','--------------------'
      WRITE(KUNIT,'(A2,A)')'* ',
     +     'jct 2nd layer: row=numhid+1 (10F10.4), col=numout'
C     jct2nd
      DO ITHID=1,(NUMHID+1)
         WRITE(KUNIT,'(10F10.4)')(JCT2ND(ITHID,ITOUT),ITOUT=1,NUMOUT)
      END DO
C---- 
C---- control end
C---- 
      IF (KUNIT.NE.6) THEN
         WRITE(KUNIT,'(A2)')'//'
         CLOSE(KUNIT)
      END IF
      END
***** end of WRTJCT

***** ------------------------------------------------------------------
***** SUB WRTOUT(KUNIT,FILE,STPINFLOC,STPLOC)
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRTOUT(KUNIT,FILE,STPINFLOC,STPLOC)
C---- ARG  : 
C---- DES  : writes the input vectors read  
C---- IN   : 
C---- FROM : TRAIN, MAIN
C---- CALL2: WRTHEAD, NETOUT_MUE
C---- LIB  : SFILEOPEN 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRTOUT(KUNIT,FILE,STPINFLOC,STPLOC)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables
      INTEGER       ITSAM,ITOUT,KUNIT,STPINFLOC,STPLOC
      CHARACTER*(*) FILE
      CHARACTER*80  CTMP
      LOGICAL       LOGI_WRTFILE
******------------------------------*-----------------------------******
      LOGI_WRTFILE=    .TRUE.
C---- 
C---- write to screen if FILE='none'
C---- 
      IF (FILE(1:4).EQ.'none'.OR.FILE(1:4).EQ.'NONE') THEN
         LOGI_WRTFILE= .FALSE.
         KUNIT=6
      END IF
C---- open file 
      IF (KUNIT.NE.6) THEN
         OPEN(KUNIT,FILE=FILE(1:FILEN_STRING(FILE)))
      END IF
      CTMP='--- WRTOUT: '
C---- 
C---- header tag
C---- 
      IF (LOGI_WRTFILE) THEN
         WRITE(KUNIT,'(A2,A20,A)')'* ',
     +        'NNout_out            ',
     +        'file from FORTRAN NN.f (output)'
      ELSE 
         WRITE(KUNIT,'(A2,A)')'* ',
     +        'Copyright: Burkhard Rost rost@columbia.edu'
         WRITE(KUNIT,'(A2,A)')'* ','NEURAL NETWORK output syntax: '
         WRITE(KUNIT,'(A2,A,A)')'* ',
     +        'residue_number(I8) SPACE(A1) output values (100I4)'
      END IF
C---- 
C---- header blabla
C---- 
      IF (LOGI_WRTFILE) THEN
         CALL WRTHEAD(KUNIT)
      END IF
C---- 
C---- header numbers
C----
      IF (LOGI_WRTFILE) THEN
         WRITE(KUNIT,'(A2,A)')'* ','--------------------'
         WRITE(KUNIT,'(A2,A)')'* ','overall: (A,T25,I8)'
         WRITE(KUNIT,'(A,A2,T25,I8)')'NUMOUT', ': ',NUMOUT
         WRITE(KUNIT,'(A,A2,T25,I8)')'NUMSAM', ': ',NUMSAM
C----
         WRITE(KUNIT,'(A,A2,T25,A)')
     +        'MODEPRED',': ',MODEPRED(1:FILEN_STRING(MODEPRED))
         WRITE(KUNIT,'(A,A2,T25,A)')
     +        'MODENET',': ',MODENET(1:FILEN_STRING(MODENET))
         WRITE(KUNIT,'(A,A2,T25,A)')
     +        'MODEIN',': ',MODEIN(1:FILEN_STRING(MODEIN))
         WRITE(KUNIT,'(A,A2,T25,A)')
     +        'MODEJOB',': ',MODEJOB(1:FILEN_STRING(MODEJOB))
C---- 
C---- current accuracy (err,errbin, asf)
C---- 
         WRITE(KUNIT,'(A2,A)')'* ','--------------------'
         WRITE(KUNIT,'(A2,A)')'* ','accuracy: (A,T25,I8)'
         WRITE(KUNIT,'(A,A2,T25,I8)')  'STPINF',': ',STPINFLOC
         WRITE(KUNIT,'(A,A2,T25,I8)')  'STP',   ': ',STPLOC
         WRITE(KUNIT,'(A,A2,T25,F8.4)')'ERRBIN',': ',ERRBIN(STPINFLOC)
         WRITE(KUNIT,'(A,A2,T25,F8.4)')'ERR',   ': ',ERR(STPINFLOC)
C----
C---- output vectors
C----
         WRITE(KUNIT,'(A2,A)')'* ','--------------------'
         WRITE(KUNIT,'(A2,A)')'* ','out vec: (I8,A1,100I4)'
      END IF

C---- yy tmp beg
C      IF (KUNIT.NE.6) THEN
C         WRITE(6,'(A15,A8,10(I2,A3,A3))')CTMP,'yy mue',
C     +        (ITOUT,'o ',' d',ITOUT=1,NUMOUT)
C      END IF
C---- yy tmp end

      DO ITSAM=1,NUMSAM
         CALL NETOUT_MUE(ITSAM)
         WRITE(KUNIT,'(I8,A1,100I4)')ITSAM,' ',
     +        (INT(BITACC*OUTPUT(ITOUT)),ITOUT=1,NUMOUT)

C----    yy tmp beg
C         WRITE(6,'(A15,I8,10(I4,I4))')CTMP,ITSAM,
C     +        (INT(BITACC*OUTPUT(ITOUT)),OUTDES(ITOUT,ITSAM),
C     +        ITOUT=1,NUMOUT)
C----    yy tmp end

      END DO
      IF (KUNIT.NE.6) THEN
         CLOSE(KUNIT)
      END IF
      END
***** end of WRTOUT

***** ------------------------------------------------------------------
***** SUB WRTERR
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRTERR
C---- ARG  : KUNIT,FILE,STPTMP
C---- DES  : writes the history of the error propagation  
C---- IN   : unit, file-to-write, last step
C---- FROM : MAIN, WRTSCR
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRTERR(KUNIT,FILE,STPTMP)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables                                                  *
      INTEGER       IT,KUNIT,STPTMP
      CHARACTER*(*) FILE
      CHARACTER     XC,CTAB
******------------------------------*-----------------------------******
C---- spacer
      CTAB=CHAR(9)
      XC=CTAB
C---- open file 
      IF (KUNIT.NE.6) THEN
         CALL SFILEOPEN(KUNIT,FILE,'UNKNOWN',150,' ')
      END IF
C---- 
C---- header 
      IF (KUNIT.NE.6) THEN
C----    header tag
         WRITE(KUNIT,'(A)')'# Perl-RDB'
         WRITE(KUNIT,'(A2,A,T25,A)')'# ',
     +        'NNout_err','file from FORTRAN NN.f (error)'
C----    number of steps executed
         WRITE(KUNIT,'(A2,A,T25,I5)')'# ','PARA: STPINF =',STPTMP
      END IF

C---- names
      WRITE(KUNIT,'(A5,A,A8,A,A8,A,A8)')
     +     'NO',XC,'STEP',XC,'ERROR',XC,'ERRBIN'

C---- formats
      IF (KUNIT.NE.6) THEN
         WRITE(KUNIT,'(A5,A,A8,A,A8,A,A8)')
     +        '5N',XC,'8N',XC,'8.4F',XC,'8.4F'
      END IF
C---- 
C---- data (history of error)
C---- 
      IF (STPTMP.EQ.0) THEN
         WRITE(KUNIT,'(I5,A,I8,A,F8.4,A,F8.4)')
     +        0,XC,(0),XC,ERR(0),XC,ERRBIN(0)
         
      ELSE
         DO IT=1,STPTMP
            WRITE(KUNIT,'(I5,A,I8,A,F8.4,A,F8.4)')
     +           IT,XC,(IT*STPINF),XC,ERR(IT),XC,ERRBIN(IT)
         END DO
      END IF

      IF (KUNIT.NE.6) THEN
         CLOSE(KUNIT)
      END IF
      END 
***** end of WRTERR

***** ------------------------------------------------------------------
***** SUB WRTHEAD
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRTHEAD
C---- ARG  : KUNIT
C---- DES  : write header for files  
C---- IN   : 
C---- FROM : MAIN, WRTOUT, WRTJCT, WRTSCREEN
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRTHEAD(KUNIT)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local variables                                                  *
      INTEGER       KUNIT
******------------------------------*-----------------------------******
*                                                                      *
C     general information (address asf)
      CALL WRTHEAD_GEN(KUNIT)
C     specific information
      CALL WRTHEAD_JOB(KUNIT)
      END 
***** end of WRTHEAD

***** ------------------------------------------------------------------
***** SUB WRTHEAD_GEN
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRTHEAD_GEN
C---- ARG  : KUNIT
C---- DES  : writes address asf onto KUNIT 
C---- IN   : 
C---- FROM : WRTHEAD
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRTHEAD_GEN(KUNIT)

C---- local function
      CHARACTER*24  FDATE
C---- local variables
      INTEGER       KUNIT
      CHARACTER*80  CTMP
******------------------------------*-----------------------------******
      CTMP='*    '
C     header
      WRITE(KUNIT,'(A5)')CTMP
C     title
      WRITE(KUNIT,'(A5,A)')CTMP,'-------------------------------'
      WRITE(KUNIT,'(A5,A)')CTMP,'Output from neural network (NN)'
      WRITE(KUNIT,'(A5,A)')CTMP,'-------------------------------'
      WRITE(KUNIT,'(A5,A)')CTMP,' '
C     address
      WRITE(KUNIT,'(A5,A)')CTMP,
     +     'author: Burkhard Rost, Columbia Univ NYC / LION Heidelberg'
      WRITE(KUNIT,'(A5,A)')CTMP,'fax:    +1-212-305-7932'
      WRITE(KUNIT,'(A5,A)')CTMP,'email:  rost@columbia.edu'
      WRITE(KUNIT,'(A5,A)')CTMP,
     +     'www:    http://cubic.bioc.columbia.edu/'
      WRITE(KUNIT,'(A5,A)')CTMP,' '
      WRITE(KUNIT,'(A5,A)')CTMP,'All rights reserved.'
      WRITE(KUNIT,'(A5,A)')CTMP,' '
C     date
C      WRITE(KUNIT,'(A5,A7,A24)')CTMP,'date:  ',FDATE()
      WRITE(KUNIT,'(A5,A7,A24)')CTMP,'date:  ',FDATE
      WRITE(KUNIT,'(A5)')CTMP
      END
***** end of WRTHEAD_GEN

***** ------------------------------------------------------------------
***** SUB WRTHEAD_JOB
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRTHEAD_JOB
C---- ARG  : KUNIT
C---- DES  : writes specific details about current job
C---- IN   : 
C---- FROM : WRTHEAD 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRTHEAD_JOB(KUNIT)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables
      INTEGER       KUNIT
      CHARACTER*80  CTMP
******------------------------------*-----------------------------******
      CTMP='*    '
      WRITE(KUNIT,'(A5)')CTMP
C     modes 
      WRITE(KUNIT,'(A5,A,T35,A)')CTMP,
     +     'MODEPRED',MODEPRED(1:FILEN_STRING(MODEPRED))
      WRITE(KUNIT,'(A5,A,T35,A)')CTMP,
     +     'MODENET',MODENET(1:FILEN_STRING(MODENET))
      WRITE(KUNIT,'(A5,A,T35,A)')CTMP,
     +     'MODEIN',MODEIN(1:FILEN_STRING(MODEIN))
      WRITE(KUNIT,'(A5,A,T35,A)')CTMP,
     +     'MODEJOB',MODEJOB(1:FILEN_STRING(MODEJOB))
C     training, trigger, and error type
      WRITE(KUNIT,'(A5,A,T35,3(A10,A1))')CTMP,'TRN-, TRG-, ERRTYPE',
     +     TRNTYPE(1:FILEN_STRING(TRNTYPE)),',',
     +     TRGTYPE(1:FILEN_STRING(TRGTYPE)),',',
     +     ERRTYPE(1:FILEN_STRING(ERRTYPE)),' '
C     architecture
      WRITE(KUNIT,'(A5,A,T35,3(I8,A1))')CTMP,'NUMIN, -HID, -OUT',
     +     NUMIN,',',NUMHID,',',NUMOUT,' '
C     samples asf
      WRITE(KUNIT,'(A5,A,T35,I8)')CTMP,'NUMSAM',NUMSAM
      WRITE(KUNIT,'(A5,A,T35,3(I8,A1))')CTMP,'STPSWPMAX, -MAX, -INF',
     +     STPSWPMAX,',',STPMAX,',',STPINF,' '
      WRITE(KUNIT,'(A5,A,T35,I8,A1,F8.4)')CTMP,'ERRBINSTOP, -STOP',
     +     ERRBINSTOP,',',ERRSTOP
C     training
      WRITE(KUNIT,'(A5,A,T35,3(F8.4,A1))')CTMP,'EPSILON, ALPHA, TEMP',
     +     EPSILON,',',ALPHA,',',TEMPERATURE,' '
      WRITE(KUNIT,'(A5)')CTMP
      END
***** end of WRTHEAD_JOB

***** ------------------------------------------------------------------
***** SUB WRTSCR
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRTSCR
C---- ARG  : STPTMP
C---- DES  : writes control output onto screen 
C---- IN   : last step
C---- FROM : MAIN 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRTSCR(STPTMP)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING,STPTMP
      CHARACTER*24  FDATE
C---- local variables
      INTEGER       IT
      CHARACTER*80  CTMP,CTMP2
******------------------------------*-----------------------------******
      CTMP= '--- WRTscr: '
      CTMP2='--------------------------------------------------'
      WRITE(6,'(A15,A50)')        CTMP,CTMP2
      WRITE(6,'(A15)')            CTMP
      WRITE(6,'(A15,A)')          CTMP,'Final results of NN'
      WRITE(6,'(A15,A)')          CTMP,'-------------------'
      WRITE(6,'(A15)')            CTMP
C      WRITE(6,'(A15,A24)')        CTMP,FDATE()
      WRITE(6,'(A15,A24)')        CTMP,FDATE
      WRITE(6,'(A15)')            CTMP
C---- 
C---- header numbers
C----
      WRITE(6,'(A15,A)')          CTMP,'--------------------'
      WRITE(6,'(A15,A)')          CTMP,'overall: (A,T25,I8)'
      WRITE(6,'(A15,A,T35,I8)')   CTMP,'NUMIN',    NUMIN
      WRITE(6,'(A15,A,T35,I8)')   CTMP,'NUMHID',   NUMHID
      WRITE(6,'(A15,A,T35,I8)')   CTMP,'NUMOUT',   NUMOUT
      WRITE(6,'(A15,A,T35,I8)')   CTMP,'NUMSAM',   NUMSAM
      WRITE(6,'(A15)')            CTMP
C---- 
      WRITE(6,'(A15,A,T35,I8)')   CTMP,'STPSWPMAX',STPSWPMAX
      WRITE(6,'(A15,A,T35,I8)')   CTMP,'STPMAX',   STPMAX
      WRITE(6,'(A15,A,T35,I8)')   CTMP,'STPINF',   STPINF
      WRITE(6,'(A15)')            CTMP
C---- 
C---- reals
C---- 
      WRITE(6,'(A15,A)')          CTMP,' '
      WRITE(6,'(A15,A,T35,F15.6)')CTMP,'EPSILON',    EPSILON
      WRITE(6,'(A15,A,T35,F15.6)')CTMP,'ALPHA',      ALPHA
      WRITE(6,'(A15,A,T35,F15.6)')CTMP,'TEMPERATURE',TEMPERATURE
      WRITE(6,'(A15)')            CTMP
C---- 
      WRITE(6,'(A15,A,T35,I8)')   CTMP,'ERRBINSTOP', ERRBINSTOP
      WRITE(6,'(A15,A,T35,F15.6)')CTMP,'ERRSTOP',    ERRSTOP
      WRITE(6,'(A15)')            CTMP
C---- 
C---- characters
C---- 
      WRITE(6,'(A15,A)')          CTMP,' '
      WRITE(6,'(A15,A,T35,A)')    CTMP,'TRNTYPE',
     +     TRNTYPE(1:FILEN_STRING(TRNTYPE))
      WRITE(6,'(A15,A,T35,A)')    CTMP,'TRGTYPE',
     +     TRGTYPE(1:FILEN_STRING(TRGTYPE))
      WRITE(6,'(A15,A,T35,A)')    CTMP,'ERRTYPE',
     +     ERRTYPE(1:FILEN_STRING(ERRTYPE))
      WRITE(6,'(A15)')            CTMP
      WRITE(6,'(A15,A,T35,A)')    CTMP,'MODEPRED',
     +     MODEPRED(1:FILEN_STRING(MODEPRED))
      WRITE(6,'(A15,A,T35,A)')    CTMP,'MODENET',
     +     MODENET(1:FILEN_STRING(MODENET))
      WRITE(6,'(A15,A,T35,A)')    CTMP,'MODEIN',
     +     MODEIN(1:FILEN_STRING(MODEIN))
      WRITE(6,'(A15,A,T35,A)')    CTMP,'MODEJOB',
     +     MODEJOB(1:FILEN_STRING(MODEJOB))
C---- 
C---- files
C---- 
      DO IT=1,NUMFILEIN_IN
         WRITE(6,'(A15,A,T30,I4,A1,A)')CTMP,'FILEIN_IN',IT,' ',
     +        FILEIN_IN(IT)(1:FILEN_STRING(FILEIN_IN(IT)))
      END DO
      DO IT=1,NUMFILEIN_OUT
         WRITE(6,'(A15,A,T30,I4,A1,A)')CTMP,'FILEIN_OUT',IT,' ',
     +        FILEIN_OUT(IT)(1:FILEN_STRING(FILEIN_OUT(IT)))
      END DO
      WRITE(6,'(A15,A,T35,A)')CTMP,
     +     'FILEIN_JCT',FILEIN_JCT(1:FILEN_STRING(FILEOUT_JCT))
C      DO IT=1,NUMFILEOUT_OUT
      DO IT=1,STPTMP
         WRITE(6,'(A15,A,T30,I4,A1,A)')CTMP,'FILEOUT_OUT',IT,' ',
     +        FILEOUT_OUT(IT)(1:FILEN_STRING(FILEOUT_OUT(IT)))
      END DO
C      DO IT=1,NUMFILEOUT_JCT
      DO IT=1,STPTMP
         WRITE(6,'(A15,A,T30,I4,A1,A)')CTMP,'FILEOUT_JCT',IT,' ',
     +        FILEOUT_JCT(IT)(1:FILEN_STRING(FILEOUT_JCT(IT)))
      END DO
      WRITE(6,'(A15,A,T35)')CTMP,'end of reading parameters'
C---- 
C---- error history
C---- 
      CALL WRTERR(6,'STDOUT',STPTMP)
C---- 
C---- current accuracy (err,errbin, asf)
C---- 
      WRITE(6,'(A15,A)')          CTMP,'--------------------'
      WRITE(6,'(A15,A)')          CTMP,'accuracy: '
      WRITE(6,'(A15,A6,A2,I8,A,A2,F8.4)')CTMP,
     +     'STP   ',': ',STPNOW,   '  ERR   ',': ',ERR(STPINFCNT)
      WRITE(6,'(A15,A6,A2,I8,A,A2,F8.4)')CTMP,
     +     'STPINF',': ',STPINFCNT,'  ERRBIN',': ',ERRBIN(STPINFCNT)
C---- 
      WRITE(6,'(A15)')            CTMP
      WRITE(6,'(A15,A50)')        CTMP,CTMP2
      END 
***** end of WRTSCR

***** ------------------------------------------------------------------
***** SUB WRTYEAH
***** ------------------------------------------------------------------
C---- 
C---- NAME : WRTYEAH
C---- ARG  : KUNIT,FILE
C---- DES  : writes specific details about current job
C---- IN   : 
C---- FROM : MAIN 
C---- CALL2: 
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     CUBIC/LION		http://cubic.bioc.columbia.edu         *
*     Columbia University	rost@columbia.edu                      *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE WRTYEAH(KUNIT,FILE)

C---- include parameter files
      INCLUDE       'nnPar.f'
C---- local function
      INTEGER       FILEN_STRING
C---- local variables
      INTEGER       KUNIT
      CHARACTER*(*) FILE
      CHARACTER*80  CTMP
******------------------------------*-----------------------------******
C---- open file 
      IF (KUNIT.NE.6) THEN
         CALL SFILEOPEN(KUNIT,FILE,'UNKNOWN',150,' ')
      END IF
C---- write
      CTMP='--- WRTYEAH '
      WRITE(KUNIT,'(A5)')CTMP
      WRITE(KUNIT,'(A,T16,A)')CTMP,'everything seems fine! HAPPY??'
C---- close file
      IF (KUNIT.NE.6) THEN
         CLOSE(KUNIT)
      END IF
      END
***** end of WRTYEAH

