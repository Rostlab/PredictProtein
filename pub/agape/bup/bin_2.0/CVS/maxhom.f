C=======================================================================
 
C=====================================================================
C                    MAXHOM at EMBL 1994
C C. Sander,   MPIMF, Heidelberg, 1982/1984
C R. Schneider, EMBL, Heidelberg, 1988-
C======================================================================
C best alignment(s) between sequences, and a little bit more......
C======================================================================
C Algorithm(s):
C =============
C Smith and Waterman:
C     Identification of common molecular subsequences,
C     JMB 147 (1981) 195-197
C Gotoh:
C     An Improved Algorithm for Matching Biological Sequences,
C     JMB (1982) 162, 705-708
C Jones R. et.al.:
C     Protein Sequence Comparison on the Connection Machine CM-2,
C     in: Computers and DNA, SFI Studies in the Sciences of Complexity,
C     Vol VII, Addison-Wesley, 1990
C Gribskov et.al.:
C     Profile analysis: Detection of distantly related proteins,
C     PNAS 84, (1987) 4355-4358
C Sander C., Schneider R.:
C     Database of homology derived protein structures and the structural
C     meaning of sequence alignment
C     Proteins, 9:56-58 (1991)
C + other stuff to be published
C
C======================================================================
C                            HISTORY
C======================================================================
C  plan: calculate reliability score from backward/forward
C
C  July 1995: optimized inter-processors communication
C  July 1995: optimized I/O during database scan
C  June 1995: read Fasta-database format
C  June 1995: NRDB in parallel
C  1994-Jun.95 : parallel version for single sequence, profile and
C                profile-profile (list of filenames) scan
C                ports to Parsytec PowerGC, Meiko CS2, IBM-SP2
C  1992-1994: parallel versions for PVM, P4, EXPRESS, PARIX, INTEL
C  JAN  92: matrix setting in forward and backward way
C           MAXDEL option removed; causes problem
C  DEZ  91: DO-loops in SETMATRIX vectorized
C  AUG  91: major rewritting and "clean up" (RS)
C           ====================================
C           the main changes are:
C       1.  the metric is now allways handled as a profile.
C           The following values are now position dependent:
C           metric, gap-open, gap-elongation and conservation weights
C           this allows to align:
C           a) sequence(s)    <===> sequence(s)
C           b) profile(s)     <===> sequence(s)
C           c) sequence(s)    <===> profile(s)
C           d) profile(s)     <===> profile(s)
C              1. full profile (inner product of position dependent
C                 profiles, without taking into account the actual
C                 sequence information
C              2. sequence as a representative of the family
C              3. maximum of profile position as the "consensus" sequence
C           PROFILE and METRIC files have now a standart format
C       2.  the matrix is not longer sorted. For each NBEST alignment
C           the matrix is searched for the best value which was not a
C           member of a previous best path. So the matrix dimension is
C           now "only" LH(x,y,2) and not LH(x,y,4)
C           ( like a fast TRACE back )
C       3.  selected alignments are written now to a temporay binary
C           file with direct access (necessary because of point 5).
C           Only the ALISORTKEY (pointing to the record number)
C           is sorted via QSORT
C       4.  list of filenames for sequence 1
C       5.  sequence 2 can be a database like SwissProt
C       6.  command file generator on run-time and .log file feature
C=======================================================================
C  JUL  91: use also cons-weights for the second sequence (only read in)
C  JUL  91: MAXDEL restriction removed according to Gotoh (1982) (RS)
C           NOTE: its still possible to set a MAXDEL restriction
C                 usefull if one looks for repeats.....
C  JUN  91: SETMATRIX in a anitidiagonal way (run in parallel) (RS)
C           implementation on an Alliant (GMD Bonn)
C  May  91: speed up by recoding SETMATRIX (RS)
C  APR  91: change HSSP-routines to HSSP-LIB routines (RS)
C  APR  91: sort hits according to user specification (RS)
C  APR  91: STRIP output procedure changed (no MAXLINES etc.) (RS)
C  MAR  91: cons-weight calculation debugged (RS)
C  DEZ  90: change GETSEQ, to handle chains by name (fx. x.dssp_!_A,B)
C  OKT  90: FOSFOS: Fitness Of Sequence For Structure (contact prefs for
C           second sequence (RS)
C  OKT  90: WRITE alis only in core if specified threshold is fulfilled
C           (RS)
C  SEP  90: linethickness for TRACE (RS)
C  AUG  90: two pass alignment (derive cons-weights ===> 
C           align once more) (RS)
C  AUG  90: use contact prefs from CONAN for alignment (RS)
C  JUL  90: use conservation weights (RS)
C  JAN  90: use structure dependent matrices (RS)
C  JUN  89: extract and modify GETAASEQ to GETSEQ (RS). This version 
C           reads the BRK-number to check if 
C           pieces for RMS-evaluation from DSSP and BRK
C           are the same (CHECKPOSITION)
C  MAY  89: try to replace LHQSORT by searching every time the best
C           NO ADVANTAGE LHQSORT IS STILL ACTIVE (RS)
C           the problem: most of the 'best' values are reject in TRACE
C           because the trace jumps in a previous used trace,
C           so one has to search many time the best value
C  MAY  89: speed up (RS) (SETMATRIX,LHQSORT,GETCOOR,HSSP)
C  APR  89: ALITOSTRUC (RS) (superpose alignments using U3B of W Kabsch)
C  JAN  89: and later HSSP-routine(s) (RS)
C  FEB  88: TRACE to POSTSCRIPT via TREACE2PS (Brigitte Altenberg)
C  JAN  88: seq/str homology (MODESIM = 206) debugged
C  OCT  84: NEWMETRIC option, a learning process
C  AUG  84: LSIM generalized to different types of metric switched 
C           by MODSIM
C  JUL? 84: all H etc. values converted to integer arithmetic to 
C           save storage
C  MAY  84: jobinterrupt feature for long jobs
C  DEC? 83: secondary structure prediction from DSSP homologies
C  DEC? 83: global output to strip
C  DEC? 83: storage of alignments in core for global QSORT
C  SEP  83: converted to DNA, corrected deletion weight D2*(L-1)
C  SEP  83: corrected termination test in TRACE, corrected 'a'='C' 
C           in GETAASEQ
C  SEP  83: adapted to 16-bit for testing, avoided BACKSPACE in GETSIM
C  SEP  83: repeat pass for MAXMAT overflow
C     1982: first implementation for DNA and plot interface by C Oefner.
C     1980: original algorithm by Temple Smith
C=======================================================================
C                         input files
C=======================================================================
C KGETSEQ   sequence file called by GETSEQ
C KLIS1     list of sequences for first sequences
C KLIS2     list of sequence for second sequences
C KSIM      metric-data
C KISO      isosignificance data (HSSP)
C KREL      release notes swissprot
C KBRK      according brookhaven file (structure compare)
C KBASE     SWISSPROT AND PIRONLY seq.dat files
C KINDEX    SWISSPROT index file
C KDEF      MAXHOM defaults file
C KREF      SwissProt pdb-pointer selection
C=======================================================================
C                         output files
C=======================================================================
C KSTP      STRIPFILE, STRIP.X, summary output file for globally
C           best sequences
C KLONG     long output file
C KPLOT     PLOTFILE, TRACE.X, intermediate plot file for use by TRACE
C KSTAT     STATFILE, COLLAGE-STATIS.DATA, prediction statistics file
C KWARN     WARNFILE contains different warnings
C KSTRUC    datafile for HSSP-PLOT (sec-struc and rms-d)
C KTAB      table file
C KCONS     conservation-weights (and evolution of cons-weights file)
C KPROF     MAXHOM-profile
C KLOG      MAXHOM-LOG file
C KHSSP     HSSP-output file
C KCOM      command file (*.com (VMS) .csh (UNIX))
C KHISTO
C KIORANGE  file with solvent accessibility settings for different sec str
C KDEB      debug file at various places
C=======================================================================
C                        input and output
C=======================================================================
C KCORE
C=======================================================================
C
C
C***********************************************************************
C*****       CAUTION:  INSTRUCTIONS FOR DIMENSIONING             *******
C***********************************************************************
C memory requirement around 32 MegaBytes
C MAXMAT*2*4 = 2000000*2*4= 16.0 MegaBytes  = REAL*4 LH(len1,len2,2)
C MAXSQ=longest test
C MAXALSQ is max length of aligned sequence
C N1,N2IN are actual sequence lengths.
C ND1,ND2 are used matrix dimensions, ND1=N1+1, ND2=N2+1 for margins.
C
      PROGRAM MAXHOM

      IMPLICIT        NONE

C---- include parameter files
      INCLUDE         'maxhom.param'
      INCLUDE         'maxhom.common'
 
C---- local variables
      REAL            LH1(0:MAXMAT)
      INTEGER*2       LH2(0:MAXTRACE)
      COMMON/CBIGMATRIX/LH1
      COMMON/CBIGTRACEBACK/LH2
C     parallel stuff and control flow
      LOGICAL         LPARALLEL,LAGAIN
C     WRITE selected alignments into temp binary file with direct access
      CHARACTER*200   CORETEMP
C     profile output file
      CHARACTER*200   PROFILEOUT
C     amino acid exchange metrices
      CHARACTER*200   METRIC_ADM,METRIC_GCG,METRIC_STRUC,
     +                METRIC_IO,METRIC_STRIO,PROFILEMETRIC
c	character*80 metricpath,metric_adm,metric_gcg,metric_struc,
c     +               metric_io,metric_strio,profilemetric
c     checkformat
      CHARACTER*20    SEQFORMAT
C     temporary string for strip-output
      CHARACTER       STRIPLINE(4)*(MAXSQ)
c     chain remark string for hssp-header
      CHARACTER*200   CHAINREMARK
      CHARACTER       CTEMP*1,CTEMP2*1,TEMPNAME*200,TEMPSTRING*200
C      CHARACTER       FILE_OPTION*80
      CHARACTER       FILE_OPTION*200
      CHARACTER       QUESTION*1000
      CHARACTER       PDBREFLINE*3000
C      CHARACTER       CFILTER*80,CSYMBOL
      CHARACTER       CFILTER*200,CSYMBOL
      CHARACTER       LINE*100
C     histogram
c     integer lhist(maxhist,maxhist)
      INTEGER         NFILE,NENTRIES,NAMINO_ACIDS,IFILE,NRECORD,IRECORD,
     +                LRES,NCHAIN,KCHAIN,IDSSP,NALIGN,NSELECT,KSELECT,
     +                IAL,
     +                ISTRPOS,IOPOS,INSPOS,IAGR,ICLASS,JCLASS,LINELEN,
     +                IFIR,ILAS,JFIR,JLAS,IDEL,NDEL,LEN1,LENOCC,
     +                IPOS,JPOS,
     +                I,J,K,IBEG,IEND
c     integer jbeg,jend
      INTEGER         IARG,ISET,LALI,IWORKER
c        integer istep
C     local smin,smax...
      REAL            XSMIN,XSMAX,XMAPLOW,XMAPHIGH
C     Z-scores
c	real zscore(maxaligns),zscore_temp(maxaligns)
 
      REAL            VALUE,CVALSTR,CPERRES,CHECKVAL,
     +                RMS,HOM,SIM,DISTANCE
C     if second sequence(s) are DSSP-files predict secondary structure
      LOGICAL         LPREDICTION,LSTRIP_LONG,LENDFILE
C     error flag
      LOGICAL         LERROR,LTRUNCATED
C     zscore
      REAL            SDEV,CURT,SKEW,VAR,ADEV,AVE
c     profile-calculation
      CHARACTER*40    WEIGHT_MODE
      REAL            SIGMA,BETA
     +                
C=======================================================================
C     init
C=======================================================================
C     strings
      TOTAL_TIME=0.0
      CALL INIT_CPU_TIME(ITIME_OLD)
 
      HOST_FILE=  'hosts.pvm'
      NODE_NAME=  'maxhom'
 
      CFILTER=    ' ' 
      JOB_ID=     ' ' 
      IFILE=      0 
      QUESTION=   ' '
C     PDBREFLINE=' '
c some warnings
      WARNFILE=   'MAXHOM.WARNING'
      LISTFILE_1= ' ' 
      LISTFILE_2= ' '
      COREPATH=   ' ' 
      COREFILE=   ' '
      BRKFILE_1=  ' ' 
      BRKFILE_2=  ' ' 
      BRKBEFORE1= ' ' 
      BRKBEFORE2= ' '
      TEMPNAME=   ' ' 
      TEMPSTRING= ' '
      NAME_2=     ' '
C logicals
      LISTOFSEQ_1=.FALSE. 
      LISTOFSEQ_2=.FALSE.
      LSWISSBASE= .FALSE.
      LFASTA_DB=  .FALSE.
      LNRDBBASE=  .FALSE.
      LENDFILE=   .FALSE.
      LAGAIN=     .FALSE.
      LSTRIP_LONG=.FALSE.
C run in parallel
      LPARALLEL=  .FALSE.
      MP_MODEL=   'NIX'
      IDTOP=      0 
      IDPROC=     0
      ID_HOST=    0
      LINK_HOST=  0
      NWORKER=    1
      NWORKSET=   0
C     LMIXED_ARCH=.FALSE.
      DO I = 1,NWORKER 
         LINK(I) = 0 
      ENDDO
      TOTAL_TIME= 0.0
      NFILE=      0
      N_ONE=      1
C Way3 alignment (sequence ---> database -----> profile ----> database)
      L3WAY=      .FALSE.
      L3WAYDONE=  .FALSE.
C warm start
      LFIRST_SCAN=.TRUE. 
      LWARM_START=.FALSE.
      NSEQ_WARM_START=0
c for structure dependent metrices
      CSTRSTATES= 'ELH'
      NSTRSTATES_1=1 
      NIOSTATES_1= 1
      NSTRSTATES_2=1 
      NIOSTATES_2= 1
      I= MAXIOSTATES * MAXSTRSTATES
      CALL INIT_REAL_ARRAY(1,I,IORANGE,200.0)
C matrix scaling
      XSMIN=      0.0 
      XSMAX=      0.0 
      XMAPLOW=    0.0 
      XMAPHIGH=   0.0
C weights
      ISEQPOS=    1
C----
C---- BR 98.10 do NOT see the reason why this should NOT be 0!
C----          is minimal value for conservation weight
      CONSMIN=    0.01 

      CUTVALUE1=  0.0 
      CUTVALUE2=  0.0
      VALUE=      1.0
      CALL INIT_REAL_ARRAY(1,MAXSQ,CONSWEIGHT_1,VALUE)
      VALUE=      0.0
      CALL INIT_REAL_ARRAY(1,MAXSQ,GAPOPEN_1,VALUE)
      CALL INIT_REAL_ARRAY(1,MAXSQ,GAPOPEN_2,VALUE)
C sort scores and zscores
      CALL INIT_REAL_ARRAY(1,MAXHITS,AL_VAL,VALUE)
      CALL INIT_REAL_ARRAY(1,MAXHITS,AL_HOM,VALUE)
      CALL INIT_REAL_ARRAY(1,MAXHITS,AL_SDEV,VALUE)
      CALL INIT_REAL_ARRAY(1,MAXALIGNS,ZSCORE_TEMP,VALUE)
      
      CALL INIT_REAL_ARRAY(1,MAXALIGNS,ALISORTKEY,VALUE)
      I=0
      CALL INIT_INT_ARRAY(1,MAXALIGNS,IFILEPOI,I)
      CALL INIT_INT_ARRAY(1,MAXALIGNS,IRECPOI,I)
      IALIGN_GOOD=         0
c	call init_int2_array(1,maxaligns,len2_orig,i)
cx	call init_real_array(1,maxaligns,len2_orig,value)
      SDEV=                0.0
 
      DO I=1,MAXHITS
         AL_PDB_POINTER(I)=' ' 
         AL_ACCESSION(I)=  ' '
      ENDDO
      INSNUMBER=           0
      DO I=1,MAXINSBUFFER
         INSBUFFER(I)=     ' '
      ENDDO
C secondary structure prediction
      I=MAXSQ * MAXSTRSTATES
      CALL INIT_REAL_ARRAY(1,I,STRSUM,VALUE)
C TRANS is set here
      TRANS='VLIMFWYGAPSTCHRKQENDBZX!-.'
      CALL GETPOS(TRANS,TRANSPOS,NASCII)
C secondary structure symbols and translations
      STRTRANS=      'ELHT CSBAPMGIU!'
      STR_CLASSES(1)='EBAPMebapm'
      STR_CLASSES(2)='L TCStclss'
      STR_CLASSES(3)='HGIhgiiiii'
      STR_CLASSES(4)='U!!!!!!!!!'
C structure and accessibility symbols for SS-SA profiles are set here
      SSSA_STRTRANS= 'ELH'
      SSSA_IOTRANS=  'BO'
c other
      IEND=0
C=======================================================================
C get enviroment
C=======================================================================
      MACHINE_NAME=  'PARSYTEC'
      ARCHITECTURE=  'PX'
      MAXHOM_DEFAULT='maxhom.default'
c	call get_machine_name(machine_name)
c        tempname='ARCH'
c	call get_enviroment_variable(tempname,architecture)
      TEMPNAME=      'MAXHOM_DEFAULT'
      CALL GET_ENVIROMENT_VARIABLE(TEMPNAME,MAXHOM_DEFAULT)
 
      LSMALL_MACHINE=.FALSE.
      LPARALLEL=     .TRUE.
c        lparallel=.false.
 
      CALL GET_ARG_NUMBER(IARG)
      IF (IARG .GT. 0) THEN
         DO I=1,IARG
            CALL GET_ARGUMENT(I,TEMPNAME)
            TEMPSTRING=TEMPNAME 
            CALL LOWTOUP(TEMPNAME,LEN(TEMPNAME))
            CALL STRPOS(TEMPNAME,IBEG,IEND)
            IF (INDEX(TEMPNAME,'-PAR') .NE. 0) THEN
               LPARALLEL=.TRUE.
            ELSE IF (INDEX(TEMPNAME,'-NOPAR') .NE. 0) THEN
               LPARALLEL=.FALSE.
            ELSE IF (INDEX(TEMPNAME,'-H=') .NE. 0) THEN
	       HOST_FILE(1:)=TEMPSTRING(IBEG+3:IEND)
            ELSE IF (INDEX(TEMPNAME,'-D=') .NE. 0) THEN
	       MAXHOM_DEFAULT(1:)=TEMPSTRING(IBEG+3:IEND)
            ENDIF
         ENDDO
      ENDIF
C=======================================================================
CPARALLEL
C init the parallel enviroment: farmer-worker topology.....
C=======================================================================
      IF (LPARALLEL .EQV. .TRUE.) THEN	
         CALL MP_INIT_FARM()
      ENDIF
      
      IF (NWORKER .LT. 1) THEN
         LPARALLEL=.FALSE.
      ELSE IF (NWORKER .LE. MINPROC) THEN
         LSMALL_MACHINE=.TRUE.
      ENDIF
      IF (MP_MODEL .EQ. 'PARIX') THEN 
         ARCHITECTURE='PX' 
      ENDIF
C=======================================================================
CPARALLEL
C             ONLY HOST IS ASKING THE STUFF
C=======================================================================
      IF (IDPROC .EQ. ID_HOST) THEN
C=======================================================================
         WRITE(6,*)'************************************ MAXHOM ****'//
     +        '****************************'
         WRITE(6,*)'*                                               '//
     +        '                           *'
         WRITE(6,*)'*                         Chris Sander, MPIMF, 1'//
     +        '982/1985                   *'
         WRITE(6,*)'*                   Reinhard Schneider, EMBL , 1'//
     +        '988-(?)                    *'
         WRITE(6,*)'*                                               '//
     +        '                           *'
         WRITE(6,*)'************************************************'//
     +        '****************************'
         WRITE(6,*)'*                                               '//
     +        '                           *'
         WRITE(6,*)'*  in case of strange behaviour of the program, '//
     +        '                           *'
         WRITE(6,*)'*  please check the file: MAXHOM.LOG_"PID"      '//
     +        '                           *'
         WRITE(6,*)'************************************************'//
     +        '****************************'
C=======================================================================
c          WRITE(6,*)'mp_model / ARCH / lsmall: ',mp_model,architecture,
c     +            lsmall_machine
c	  IF ( lparallel .eqv. .true.) THEN
c            WRITE(6,*)'INFO: parallel version switched ON '
c	    WRITE(6,*)'INFO: mixed architecture is: ',lmixed_arch
c            WRITE(6,*)'INFO: host_file=',host_file(1:40)
c	  endif
         WRITE(6,*)'INFO: default=',maxhom_default(1:40)
C=======================================================================
C DEFAULTS
C=======================================================================
         CALL GET_DEFAULT()
         COMMANDFILE_ANSWER=     'YES'
C test sequence
         NAME1_ANSWER=           ' '
         NAME1_ANSWER=           '/data/dssp/5p21.dssp'
c comparison sequence(s)
         NAME2_ANSWER=           'swissprot'
         PROFILE_ANSWER=         'NO'
         METRIC_ANSWER=          'LACHLAN'
C worst and best match
         SMIN_ANSWER=           '-0.5' 
         SMIN=                   -0.5
         SMAX_ANSWER=           '1.0'  
         SMAX=                   1.0
         MAPLOW=                 0.0         
         MAPHIGH=                0.0
c gap open ; gap elongation
         OPENWEIGHT_ANSWER=     '3.0'  
         OPEN_1=                 3.0
         ELONGWEIGHT_ANSWER=    '0.1' 
         ELONG_1=                0.1
c conservation weights
         WEIGHT1_ANSWER=         'NO' 
         WEIGHT2_ANSWER=         'NO'
         WAY3_ANSWER=            'NO'
C INDELs in secondary structure
         INDEL_ANSWER_1=         'NO' 
         INDEL_ANSWER_2=         'NO'
C profile normalization
         NORM_PROFILE_ANSWER=    'NO'
         PROFILE_EPSILON_ANSWER='0.1'
         PROFILE_GAMMA_ANSWER= '10.0'
C suboptimal traces
         BACKWARD_ANSWER=        'NO'
         FILTER_ANSWER=        '10.0'
         LBACKWARD=              .FALSE.
c number of alignments per pair
         NBEST_ANSWER=           '1'
c punish gap in secondary structure
         PUNISH=               9000.0
c maximum number of reported alignments
         WRITE(NGLOBALHITS_ANSWER,'(I8)')MAXHITS
         THRESHOLD_ANSWER=       'FORMULA'
C sort hits
         SORTMODE_ANSWER=        'DISTANCE'
C HSSP output and threshold
         HSSP_ANSWER=            'YES'
         LHSSP=                  .TRUE. 
         LFORMULA=               .FALSE. 
         LTHRESHOLD=             .TRUE.
         HSSP_FORMAT_ANSWER=     'NO'
c show 100% identical hits
         SAMESEQ_ANSWER=         'YES'
C compare 3D-structure if known
         COMPARE_ANSWER=         'NO' 
         LCOMPSTR=               .FALSE.
C align secondary structure symbols
         STRUC_ALIGN_ANSWER=     'NO'
C profile output
         PROFILEOUT_ANSWER=      'NO'
C strip output
         STRIPFILE_ANSWER=       'NO'
C long output file
         LONG_OUTPUT_ANSWER=     'NO'
C dot-plot output
         PLOTFILE_ANSWER=        'NO'
C pdb_path
         PDBPATH=PDBPATH_ANSWER
c similarity matrix
         CALL STRPOS(METRICPATH,IBEG,IEND)
         METRIC_ADM=METRICPATH(:IEND)//'Maxhom_McLachlan.metric'
         METRIC_GCG=METRICPATH(:IEND)//'Maxhom_GCG.metric'
         METRIC_STRUC=METRICPATH(:IEND)//'????'
         METRIC_IO=METRICPATH(:IEND)//'?????'
         METRIC_STRIO=METRICPATH(:IEND)//'Maxhom_Struc_IO.metric'
         METRIC_HSSP_VAR=METRICPATH(:IEND)//'Maxhom_GCG.metric'
C get input
c	  WRITE(6,*)' call interface'
         CALL INTERFACE
c log-file
         IF (JOB_ID .EQ. ' ') THEN
            JOB_ID='0'
         ENDIF
         CALL CONCAT_STRINGS('MAXHOM.LOG_',JOB_ID,LOGFILE)
         TEMPNAME=LOGFILE
         IF (COREPATH .NE. ' ') THEN
            CALL CONCAT_STRINGS(COREPATH,TEMPNAME,LOGFILE)
         ENDIF
         
c open log file for parameter,warnings, error.....
         TEMPNAME= 'NEW,RECL=200'
         CALL OPEN_FILE(KLOG,LOGFILE,TEMPNAME,LERROR)
         CALL LOG_FILE(KLOG,'**************************** MAXHOM-'//
     +        'LOGFILE ***************************',0)
c--------------------------------------------------------------------
         IF (LDIALOG .EQV. .TRUE.) THEN
            QUESTION=' WRITE a command file for background job and '//
     +               'stop MAXHOM afterwards ? /n'//
     +       'NO    : start the program interactive /n'//
     +       'YES   : generates a command file to run MAXHOM with '//
     +               'the specified parameters '
            CALL GETCHAR(LEN(COMMANDFILE_ANSWER),COMMANDFILE_ANSWER,
     +           QUESTION)
            CALL LOWTOUP(COMMANDFILE_ANSWER,LEN(COMMANDFILE_ANSWER))
            IF (INDEX(COMMANDFILE_ANSWER,'Y').NE.0) THEN
               COMMANDFILE_ANSWER='YES'
            ELSE
               COMMANDFILE_ANSWER='NO'
            ENDIF
         ENDIF
C======================================================================
C now ask for all the stuff
C======================================================================
C get sequence(s) one
C======================================================================
         IF (LDIALOG .EQV. .TRUE.) THEN
            QUESTION=' name of FIRST sequence(s) /n'//
     +      '"filename"  : one sequence file (Format:GCG/PIR/'//
     +                 'SWISSPROT/BRK/DSSP/HSSP/PROFILE) /n'//
     +      '"file list" : file with one sequence filename per'//
     +      ' line /n            NOTE: the filename of a "file list"'//
     +                   ' must contain one of /n'//
     +      '              the following strings: "lifi" '//
     +                   '"list" "profile"'
            CALL GETCHAR(MAXLENSTRING,NAME1_ANSWER,QUESTION)
         ENDIF
         NAME_1=NAME1_ANSWER
         LISTFILE_1=NAME1_ANSWER
         WRITE(LOGSTRING,'(A,A)')'sequence file 1: ',name_1
         CALL LOG_FILE(KLOG,LOGSTRING,0)
 
         CALL CHECKFORMAT(KGETSEQ,NAME_1,SEQFORMAT,LERROR)
         WRITE(6,*)' SEQFORMAT: ',seqformat
C if format is 'UNK' assume its a list of filenames
         IF (SEQFORMAT .EQ. 'UNK') THEN
            TEMPNAME=NAME_1 
            CALL LOWTOUP(TEMPNAME,MAXLENSTRING)
            IF ( (INDEX(TEMPNAME,'LIFI') .NE. 0) .OR.
     +           (INDEX(TEMPNAME,'LIST') .NE. 0) ) THEN
               LIST=.TRUE.	
            ENDIF
            IF ( INDEX(TEMPNAME,'PROFILE') .NE. 0 ) THEN
               LPROF_1=.TRUE.
            ENDIF
            IF ( (LIST .EQV. .TRUE.) .OR. (LPROF_1 .EQV. .TRUE.) ) THEN
               LISTOFSEQ_1=.TRUE.
            ENDIF
         ELSE
            LPROFILE_1=INDEX(SEQFORMAT,'PROFILE').NE.0
            IF (INDEX(SEQFORMAT,'SS-SA') .NE.0) THEN
               LPROF_SSSA_1=.TRUE.
C     profile is sssa type and not regular maxhom profile, thus (D.P.) 
               LPROFILE_1=.FALSE.
               LDSSP_1=.FALSE.
            ENDIF

            IF (INDEX(SEQFORMAT,'DSSP') .NE.0 .OR.
     +           INDEX(SEQFORMAT,'PROFILE-DSSP') .NE.0) THEN
               LDSSP_1=.TRUE.
            ENDIF
         ENDIF
         IF ( (LISTOFSEQ_1 .EQV. .TRUE. ) .AND.
     +        (LPARALLEL   .EQV. .TRUE. ) ) THEN
            LWARM_START= .TRUE.
         ENDIF
C======================================================================
C GET COMPARISON SEQUENCE(S)
         IF (LDIALOG .EQV. .TRUE.) THEN
            IF (COMMANDFILE_ANSWER .EQ. 'YES') THEN
               QUESTION=' name of SECOND sequence(s) /n'//
     +       '"filename"  : one sequence file (Format:GCG/PIR/'//
     +                  'SWISSPROT/BRK/DSSP/HSSP/PROFILE)  OR/n'//
     +       '              a database in FASTA-format/n'//
     +       '"file list" : file with one sequence filename per line'//
     +       '/n               NOTE: the filename of a "file list" '//
     +                   'must contain one of /n'//
     +       '              the following strings: "lifi" '//
     +                   '"list" "profile" /n'//
     +       'SWISSPROT  : search against SWISSPROT (Maxhom format)/n'//
     +       'NRDB       : search against NRDB (Maxhom format)/n'//
     +       '            ======================================== /n'//
     +       '            PRE-FILTERS for database searches: /n'//
     +       '    (necessary for deriving the conservation weights)/n'//
     +       'BLASTP      : prefilter database with BLASTP/n'//
     +       'FASTA       : prefilter database with FASTA'
            ELSE
               QUESTION=' name of second sequence /n'//
     +        '"filename"  : one sequence file (Format: GCG/PIR/'//
     +                  'SWISSPROT/BRK/DSSP/HSSP) /n'//
     +        '              a database in FASTA-format/n'//
     +        '"file list" : file with one filename per line /n'//
     +        '              NOTE: the filename of a "file list" '//
     +                   'must contain one of /n'//
     +        '                    the following strings: "lifi" '//
     +                   '"list" "profile" /n'//
     +       'SWISSPROT   : search against SWISSPROT (Maxhom) /n'//
     +       'NRDB        : search against NRDB (Maxhom format)'
            ENDIF
            CALL GETCHAR(MAXLENSTRING,NAME2_ANSWER,QUESTION)
         ENDIF
         NAME_2=NAME2_ANSWER
         LISTFILE_2=NAME2_ANSWER
         WRITE(LOGSTRING,'(A,A)')'sequence file 2: ',name_2
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         TEMPNAME=NAME_2	
         CALL LOWTOUP(TEMPNAME,MAXLENSTRING)
         CALL STRPOS(TEMPNAME,IBEG,IEND)
         IF (INDEX(SPLIT_DB_NAMES,TEMPNAME(IBEG:IEND)) .GT. 0) THEN
            IF  ( LPARALLEL  .EQV. .TRUE. ) THEN
               LWARM_START= .TRUE.
            ENDIF
            CALL OPEN_FILE(KDEF,MAXHOM_DEFAULT,'OLD,READONLY',LERROR)
            LINE=' '
            DO WHILE( LINE .NE. '##')
               READ(KDEF,'(A)')LINE
               IF (INDEX(TEMPNAME(IBEG:),'SWISSPROT') .NE. 0 ) THEN
                  LSWISSBASE=.TRUE.
                  CALL EXTRACT_STRING(LINE,':','SWISSPROT_INDEX',
     +                 SPLIT_DB_INDEX)
                  CALL EXTRACT_STRING(LINE,':','SWISSPROT_PATH',
     +                 SPLIT_DB_PATH)
                  CALL EXTRACT_STRING(LINE,':','SWISSPROT_DATA',
     +                 SPLIT_DB_DATA)
               ELSE IF ( INDEX(TEMPNAME(IBEG:),'NRDB' ) .NE.0 ) THEN
                  LNRDBBASE=.TRUE.
                  CALL EXTRACT_STRING(LINE,':','NRDB_INDEX',
     +                 SPLIT_DB_INDEX)
                  CALL EXTRACT_STRING(LINE,':','NRDB_PATH',
     +                 SPLIT_DB_PATH)
                  CALL EXTRACT_STRING(LINE,':','NRDB_DATA',
     +                 SPLIT_DB_DATA)
               ENDIF
            ENDDO
         ELSE IF (TEMPNAME(IBEG:) .EQ. 'FASTA') THEN
            CFILTER='FASTA'
         ELSE IF (TEMPNAME(IBEG:) .EQ. 'BLASTP') THEN
            CFILTER='BLASTP'
         ELSE
            CALL CHECKFORMAT(KGETSEQ,NAME_2,SEQFORMAT,LERROR)
            WRITE(6,*)' SEQFORMAT: ',SEQFORMAT
C if format is 'UNK' assume its a list of filenames
            IF (SEQFORMAT .EQ. 'UNK') THEN
               IF ( (INDEX(TEMPNAME,'LIFI') .NE. 0) .OR.
     +              (INDEX(TEMPNAME,'LIST') .NE. 0) ) THEN
                  LIST=.TRUE.	
               ENDIF
               IF ( INDEX(TEMPNAME,'PROFILE') .NE. 0) THEN
                  LPROF_2=.TRUE.
               ENDIF
               IF ( (LIST .EQV. .TRUE.) .OR.
     +              (LPROF_2 .EQV. .TRUE.)) THEN
                  LISTOFSEQ_2=.TRUE.
               ENDIF
            ELSE IF (SEQFORMAT .EQ. 'FASTA-DB') THEN
               LFASTA_DB=.TRUE.
               LHSSP_LONG_ID=.TRUE.
               HSSP_FORMAT_ANSWER='YES'
            ENDIF
            LPROFILE_2=INDEX(SEQFORMAT,'PROFILE') .NE. 0
            IF (INDEX(SEQFORMAT,'DSSP') .NE. 0 .OR.
     +           INDEX(SEQFORMAT,'PROFILE-DSSP') .NE.0) THEN
               LDSSP_2=.TRUE.
            ENDIF
         ENDIF
         WRITE(6,*)' here1: LISTOFSEQ_2 LDSSP_2 ', LISTOFSEQ_2,LDSSP_2
C--------------------------------------------------------------------
C PROFILEMODE
C 0: no profiles, just a simple sequence alignment
C 1: profile for sequence 1 (and not for sequence 2)
C 2: profile for sequence 2 (and not for sequence 1)
C 3: full alignment of two profiles (inner product of position
C    dependent profiles), without taking into account the sequence
C    (structure,I/O...) information
C 4: take the sequences as a representative of the family
C 5: take the maximal value at each position as a "consensus" sequence
C 6: metric which depends on both sequence/structure/io-states
C    like:   seq,seq2,str1,str2,io1,io2
C 7: profile with secondary structure and solvent accessibility for
C    sequence 1 and DSSP file for sequence 2
C--------------------------------------------------------------------
         LASK=.TRUE.
         IF (LDIALOG .EQV. .TRUE.) THEN
            IF ( (LPROFILE_1 .AND. LPROFILE_2 ) .OR.
     +           (LPROF_1 .AND. LPROF_2) .OR.
     +           (LPROFILE_1 .AND. LPROF_2) .OR.
     +           (LPROF_1 .AND. LPROFILE_2) ) THEN
               PROFILE_ANSWER='FULL'
               QUESTION=' profile against profile mode ? (found two '//
     +              'profiles ) /n'//
     +              'FULL  : profile alignment without sequence '//
     +                       'information /n'//
     +              'MEMBER: sequences are the representative of '//
     +                       'the family /n'//
     +              'MAX   : the maximal value at each position as '//
     +                       'consensus'
c     +              'IGNORE: ignore the 2. profile (for example if '//
c     +                       'one wants to /n'//
c     +              '        use only the weights from the 2. profile'
            ELSE
               LASK=.FALSE.
               WRITE(LOGSTRING,'(A)')'2 PROFILES MODE: NO PROFILES'
               QUESTION=
     +              ' 2 profiles mode: * disabled (NEED 2 PROFILES) *'
               CALL STRPOS(QUESTION,IBEG,IEND)
               WRITE(6,*)QUESTION(IBEG:IEND)
            ENDIF
            IF (LASK .EQV. .TRUE.) THEN
               CALL GETCHAR(MAXLENSTRING,PROFILE_ANSWER,QUESTION)
            ENDIF
         ENDIF
         CALL LOWTOUP(PROFILE_ANSWER,MAXLENSTRING)
         IF (INDEX(PROFILE_ANSWER,'FULL') .NE. 0) THEN
            PROFILEMODE=3
            WRITE(LOGSTRING,'(A)')'full profile alignment without '//
     +           'sequence information'
         ELSE IF (INDEX(PROFILE_ANSWER,'MEMBER') .NE. 0) THEN
            PROFILEMODE=4
            WRITE(LOGSTRING,'(A)')'sequences is the representative '//
     +           'of the family'
         ELSE IF (INDEX(PROFILE_ANSWER,'MAX') .NE. 0) THEN
            PROFILEMODE=5
            WRITE(LOGSTRING,'(A)')'the maximal value at each '//
     +           'position serves as a consensus sequence'
c	else IF (index(profile_answer,'IGNORE') .ne. 0) THEN
c          profilemode=1
c	  WRITE(logstring,'(a)')'second profile will be ignored '
         ELSE IF (.NOT.LPROFILE_1 .AND. (LPROFILE_2.OR.LPROF_2)) THEN
            PROFILEMODE=2
         ELSE IF ( LPROFILE_1 .AND. .NOT. LPROFILE_2) THEN
            PROFILEMODE=1
         ELSE IF ( LPROF_SSSA_1 .AND. LDSSP_2 .OR. 
     +             LPROF_SSSA_1 .AND. LISTOFSEQ_2) THEN 
            WRITE(*,*)' info: profilemode equals 7: '
            PROFILEMODE=7
         ELSE
            PROFILEMODE=0
         ENDIF
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
C get metric
C--------------------------------------------------------------------
         METRICFILE=' '
         IF (LDIALOG .EQV. .TRUE.) THEN
            IF ( (LPROF_1 .EQV. .TRUE. ) .OR. (LPROFILE_1 .EQV. .TRUE.)
     +           .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +           (LPROF_2 .EQV. .TRUE.) .OR.
     +           (LPROF_SSSA_1 .EQV. .TRUE.) ) THEN
               METRIC_ANSWER='PROFILE'
               QUESTION=' exchange metric ? /n'//
     +	             'LACHLAN    : Andrew McLachlan /n'//
     +	             'GCG        : Dayhoff used by GCG /n'//
     +               'STRUC      : secondary structure dependent /n'//
     +               'IO         : inside/outside dependent /n'//
     +               'STRUC_IO   : secondary structure and I/O '//
     +                            'dependent /n'//
     +               '"filename" : import any metric in Maxhom '//
     +                          'format (full pathname required ) /n'//
     +               'PROFILE    : use metric from profile'
            ELSE IF (LDSSP_1 .EQV. .TRUE.) THEN
               QUESTION=' exchange metric ? /n'//
     +	             'LACHLAN    : Andrew McLachlan /n'//
     +	             'GCG        : Dayhoff used by GCG /n'//
     +               'STRUC      : secondary structure dependent /n'//
     +               'IO         : inside/outside dependent /n'//
     +               'STRUC_IO   : secondary structure and I/O '//
     +                            'dependent /n'//
     +               '"filename" : import any metric in Maxhom '//
     +                          'format (full pathname required ) /n'//
     +               '** OTHER OPTIONS DISABLED (NEED PROFILE OR '//
     +               'DSSP FILE) **'
            ELSE
               QUESTION=' exchange metric ? /n'//
     +	             'LACHLAN    : Andrew McLachlan /n'//
     +	             'GCG        : Dayhoff used by GCG /n'//
     +               '"filename" : import any metric in Maxhom '//
     +                          'format (full pathname required ) /n'//
     +               '** OTHER OPTIONS DISABLED (NEED PROFILE OR '//
     +               'DSSP FILE) **'
            ENDIF
            CALL GETCHAR(MAXLENSTRING,METRIC_ANSWER,QUESTION)
         ENDIF
         IF ( (INDEX(METRIC_ANSWER,'/').NE.0) .AND.
     +        (CMACHINE.EQ.'UNIX') ) THEN
            METRICFILE=METRIC_ANSWER
         ELSE IF (INDEX(METRIC_ANSWER,'$') .NE.0 .OR.
     +           INDEX(METRIC_ANSWER,']') .NE.0 .AND.
     +           CMACHINE.EQ.'VMS' ) THEN
            METRICFILE=METRIC_ANSWER
         ELSE
            CALL LOWTOUP(METRIC_ANSWER,MAXLENSTRING)
            IF (INDEX(METRIC_ANSWER,'PROFILE') .NE. 0) THEN
               IF ((LPROF_1 .EQV. .TRUE.).OR.(LPROFILE_1 .EQV. .TRUE.)
     +              .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +              (LPROF_2.EQV. .TRUE.) .OR.
     +              (LPROF_SSSA_1 .EQV. .TRUE.) ) THEN
                  METRICFILE='PROFILE'
               ELSE
                  WRITE(LOGSTRING,'(A)')
     +                 '*** ERROR: no PROFILE to get metric'
                  CALL LOG_FILE(KLOG,LOGSTRING,1)
                  STOP
               ENDIF
            ELSE
               IF (INDEX(METRIC_ANSWER,'LACHLAN') .NE.0 ) THEN
                  METRICFILE=METRIC_ADM
               ELSE IF (INDEX(METRIC_ANSWER,'GCG') .NE. 0) THEN
                  METRICFILE=METRIC_GCG
               ELSE IF (INDEX(METRIC_ANSWER,'STRUC') .NE. 0) THEN
                  METRICFILE=METRIC_STRUC
               ELSE IF (INDEX(METRIC_ANSWER,'IO') .NE. 0) THEN
                  METRICFILE=METRIC_IO
               ELSE IF (INDEX(METRIC_ANSWER,'STRUC_IO') .NE. 0) THEN
                  METRICFILE=METRIC_STRIO
               ENDIF
               IF ( (LPROF_1 .EQV. .TRUE.).OR.(LPROFILE_1 .EQV. .TRUE.)
     +              .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +              (LPROF_2.EQV. .TRUE.)) THEN
                  WRITE(LOGSTRING,'(A)')
     +	          '**** WARNING: detect profile for first sequence '//
     +	          'and/or profile(s) for /n'//
     +	          '              comparison sequence, but '//
     +	          'metricfile is not set to /n'//
     +            '              PROFILE, will overWRITE '//
     +            'PROFILE-metric '
                  CALL LOG_FILE(KLOG,LOGSTRING,1)
               ENDIF
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'metric from: ',metricfile
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
C profile normalization
C--------------------------------------------------------------------
         LNORM_PROFILE=.FALSE.
         IF (LDIALOG .EQV. .TRUE.) THEN
            IF ( (LPROF_1 .EQV. .TRUE.) .OR. (LPROFILE_1 .EQV. .TRUE.)
     +           .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +           (LPROF_2 .EQV. .TRUE.)) THEN
               LASK=.TRUE.
               NORM_PROFILE_ANSWER='NO'
               QUESTION=' internal normalization of profile ? /n'//
     +              'YES    : calculate open and elongation.. /n'//
     +              'NO     : use values given by user'
            ELSE
               LASK=.FALSE.
               QUESTION=' normalization of profile: disabled  '
               NORM_PROFILE_ANSWER='disabled'
            ENDIF
            IF (LASK  .EQV. .TRUE.) THEN
               CALL GETCHAR(MAXLENSTRING,NORM_PROFILE_ANSWER,QUESTION)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'normalize profile: ',
     +        NORM_PROFILE_ANSWER
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL LOWTOUP(NORM_PROFILE_ANSWER,MAXLENSTRING)
         IF (INDEX(NORM_PROFILE_ANSWER,'Y') .NE. 0) THEN
            LNORM_PROFILE=.TRUE.
         ENDIF

C--------------------------------------------------------------------
C     set mean and gamma of profile	
C--------------------------------------------------------------------
         IF (LNORM_PROFILE .EQV. .TRUE.) THEN
            IF (LDIALOG .EQV. .TRUE.) THEN
               QUESTION=' mean value for profile ? /n'//
     +              ' positve real number (like: 0.05) '
               CALL GETCHAR(MAXLENSTRING,PROFILE_EPSILON_ANSWER,
     +              QUESTION)
            ENDIF
            CALL LOWTOUP(PROFILE_EPSILON_ANSWER,MAXLENSTRING)
            CALL STRPOS(PROFILE_EPSILON_ANSWER,IBEG,IEND)
            CALL READ_REAL_FROM_STRING(
     +           PROFILE_EPSILON_ANSWER(IBEG:IEND),profile_epsilon)
            
            IF (LDIALOG .EQV. .TRUE.) THEN
               QUESTION=' give factor for gap-open/gap-elong? /n'//
     +              ' positve real number (like: 10.0) '
               CALL GETCHAR(MAXLENSTRING,PROFILE_GAMMA_ANSWER,QUESTION)
            ENDIF
            CALL LOWTOUP(PROFILE_GAMMA_ANSWER,MAXLENSTRING)
            CALL STRPOS(PROFILE_GAMMA_ANSWER,IBEG,IEND)
            CALL READ_REAL_FROM_STRING(PROFILE_GAMMA_ANSWER(IBEG:IEND),
     +           PROFILE_GAMMA)
            WRITE(LOGSTRING,'(A,F6.2)')'mean value for profile: ',
     +           PROFILE_EPSILON
            CALL LOG_FILE(KLOG,LOGSTRING,0)
            WRITE(LOGSTRING,'(A,F6.2)')'factor for gap weights: ',
     +           PROFILE_GAMMA
            CALL LOG_FILE(KLOG,LOGSTRING,0)
         ELSE
            PROFILE_EPSILON_ANSWER='ignored'
            PROFILE_GAMMA_ANSWER='ignored'
            PROFILE_EPSILON=0.0
            PROFILE_GAMMA=0.0
         ENDIF

C--------------------------------------------------------------------
C     SMIN: worst amino acid mismatch
C     METRIC GOES FROM SMIN TO +1.0
C--------------------------------------------------------------------
         IF (LNORM_PROFILE .EQV. .TRUE.) THEN
            SMIN_ANSWER='IGNORE'
         ELSE
            IF (LDIALOG .EQV. .TRUE.) THEN
               IF ((LPROF_1 .EQV. .TRUE.) .OR. 
     +              (LPROFILE_1 .EQV. .TRUE.)
     +              .OR. (LPROFILE_2 .EQV. (.TRUE.)) .OR.
     +              (LPROF_2.EQV. .TRUE.)) THEN
                  SMIN_ANSWER='PROFILE'
                  QUESTION=' SMIN: worst amino acid mismatch ? /n'//
     +               ' real number (like: -0.5) or /n'//
     +               ' 0.0     : NO scaling /n'//
     +               ' PROFILE : take values from profile (NO scaling)'
               ELSE
                  QUESTION=' SMIN: worst amino acid mismatch ? /n'//
     +               ' real number (like: -0.5) or /n'//
     +               ' 0.0     : NO scaling'
                  WRITE(SMIN_ANSWER,'(F7.2)')SMIN
               ENDIF
               CALL GETCHAR(MAXLENSTRING,SMIN_ANSWER,QUESTION)
            ENDIF
         ENDIF
         CALL LOWTOUP(SMIN_ANSWER,MAXLENSTRING)
         IF (INDEX(SMIN_ANSWER,'PROFILE') .EQ. 0 .AND.
     +        INDEX(SMIN_ANSWER,'IGNORE') .EQ. 0) THEN
            CALL STRPOS(SMIN_ANSWER,IBEG,IEND)
            CALL READ_REAL_FROM_STRING(SMIN_ANSWER(IBEG:IEND),SMIN)
            IF ((LPROF_1 .EQV. .TRUE.) .OR. (LPROFILE_1 .EQV. .TRUE.)
     +           .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +           (LPROF_2 .EQV. .TRUE.)) THEN
               WRITE(LOGSTRING,'(A)')
     +	  '**** WARNING: detect profile for first sequence and/or '//
     +	                'profile(s) for /n'//
     +	  '              comparison sequence, but SMIN is '//
     +                  'not set to PROFILE, /n'//
     +	  '              rescale Profile-metric '
               CALL LOG_FILE(KLOG,LOGSTRING,1)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'smin: ',smin_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
C     SMAX: best amino acid match
C--------------------------------------------------------------------
         IF (LNORM_PROFILE .EQV. .TRUE.) THEN
            SMAX_ANSWER='IGNORE'
         ELSE
            IF (LDIALOG .EQV. .TRUE.) THEN
               IF ((LPROF_1 .EQV. .TRUE.).OR.(LPROFILE_1 .EQV. .TRUE.)
     +              .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +              (LPROF_2 .EQV. .TRUE.) ) THEN
                  SMAX_ANSWER='PROFILE'
                  QUESTION=' SMAX: best amino acid match ? /n'//
     +               ' real number (like: 1.0) or /n'//
     +               ' 0.0     : NO scaling /n'//
     +               ' PROFILE : take values from profile (NO scaling)'
               ELSE
                  QUESTION=' SMAX: best amino acid match ? /n'//
     +               ' real number (like: 1.0) or /n'//
     +               ' 0.0     : NO scaling'
                  WRITE(SMAX_ANSWER,'(F7.2)')SMAX
               ENDIF
               CALL GETCHAR(MAXLENSTRING,SMAX_ANSWER,QUESTION)
            ENDIF
         ENDIF
         CALL LOWTOUP(SMAX_ANSWER,MAXLENSTRING)
         IF (INDEX(SMAX_ANSWER,'PROFILE') .EQ. 0 .AND.
     +        INDEX(SMAX_ANSWER,'IGNORE') .EQ. 0 ) THEN
            CALL STRPOS(SMAX_ANSWER,IBEG,IEND)
            CALL READ_REAL_FROM_STRING(SMAX_ANSWER(IBEG:IEND),SMAX)
            IF ((LPROF_1 .EQV. .TRUE.) .OR. (LPROFILE_1 .EQV. .TRUE.)
     +           .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +           (LPROF_2 .EQV. .TRUE.)) THEN
               WRITE(LOGSTRING,'(A)')
     +	  '**** WARNING: detect profile for first sequence and/or '//
     +	                'profile(s) for /n'//
     +	  '              comparison sequence, but SMAX is '//
     +                  'not set to PROFILE, /n'//
     +	  '              rescale Profile-metric '
               CALL LOG_FILE(KLOG,LOGSTRING,1)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'smax: ',smax_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
C     GAP-OPENING DELETION-WEIGHT
C     DEL IS IN UNITS OF ABS(SMIN).
C--------------------------------------------------------------------
         IF (LNORM_PROFILE .EQV. .TRUE.) THEN
            OPENWEIGHT_ANSWER='IGNORE'
         ELSE
            IF (LDIALOG .EQV. .TRUE.) THEN
               IF ((LPROF_1 .EQV. .TRUE.).OR.(LPROFILE_1 .EQV. .TRUE.)
     +              .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +              (LPROF_2 .EQV. .TRUE.)) THEN
                  OPENWEIGHT_ANSWER='PROFILE'
                  QUESTION=' DELETION-WEIGHT ? (gap-opening) /n'//
     +               ' real number (like: 3.0) or /n'//
     +               ' PROFILE : get them from the profile'
               ELSE
                  WRITE(OPENWEIGHT_ANSWER,'(F7.2)')OPEN_1
                  QUESTION=' DELETION-WEIGHT ? (gap-opening) /n'//
     +                 ' real number (like: 3.0)'
               ENDIF
               CALL GETCHAR(MAXLENSTRING,OPENWEIGHT_ANSWER,QUESTION)
            ENDIF
         ENDIF
         CALL LOWTOUP(OPENWEIGHT_ANSWER,MAXLENSTRING)
         IF (INDEX(OPENWEIGHT_ANSWER,'PROFILE') .EQ. 0 .AND.
     +        INDEX(OPENWEIGHT_ANSWER,'IGNORE') .EQ. 0  ) THEN
            CALL STRPOS(OPENWEIGHT_ANSWER,IBEG,IEND)
            CALL READ_REAL_FROM_STRING(OPENWEIGHT_ANSWER(IBEG:IEND),
     +           OPEN_1)
            IF ((LPROF_1 .EQV. .TRUE.) .OR. (LPROFILE_1 .EQV. .TRUE.)
     +           .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +           (LPROF_2 .EQV. .TRUE.)) THEN
               WRITE(LOGSTRING,'(A)')
     +	  '**** WARNING: detect profile for first sequence and/or '//
     +	                'profile(s) for /n'//
     +	  '              comparison sequence, but gap-open is not '//
     +                  'set to PROFILE, /n'//
     +	  '              will overWRITE PROFILE gap-opening '
               CALL LOG_FILE(KLOG,LOGSTRING,1)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'gap_open: ',openweight_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
C     GAP-ELONGATION DELETION-WEIGHT
C--------------------------------------------------------------------
         IF (LNORM_PROFILE .EQV. .TRUE.) THEN
            ELONGWEIGHT_ANSWER='IGNORE'
         ELSE
            IF (LDIALOG .EQV. .TRUE.) THEN
               IF ((LPROF_1 .EQV. .TRUE.).OR.(LPROFILE_1 .EQV. .TRUE.)
     +              .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +              (LPROF_2 .EQV. .TRUE.)) THEN
                  ELONGWEIGHT_ANSWER='PROFILE'
                  QUESTION=' DELETION-WEIGHT ? (gap-elongation) /n'//
     +               ' real number (like: 0.1) or /n'//
     +               ' PROFILE : get them from the profile'
               ELSE
                  QUESTION=' DELETION-WEIGHT ? (gap-elongation) /n'//
     +                 ' real number (like: 0.1)'
                  WRITE(ELONGWEIGHT_ANSWER,'(F7.2)')ELONG_1
               ENDIF
               CALL GETCHAR(MAXLENSTRING,ELONGWEIGHT_ANSWER,QUESTION)
            ENDIF
         ENDIF
         CALL LOWTOUP(ELONGWEIGHT_ANSWER,MAXLENSTRING)
         IF (INDEX(ELONGWEIGHT_ANSWER,'PROFILE') .EQ. 0 .AND.
     +        INDEX(ELONGWEIGHT_ANSWER,'IGNORE') .EQ. 0) THEN
            CALL STRPOS(ELONGWEIGHT_ANSWER,IBEG,IEND)
            CALL READ_REAL_FROM_STRING(ELONGWEIGHT_ANSWER(IBEG:IEND),
     +           ELONG_1)
            IF ((LPROF_1 .EQV. .TRUE.) .OR. (LPROFILE_1 .EQV. .TRUE.)
     +           .OR. (LPROFILE_2 .EQV. .TRUE.) .OR.
     +           (LPROF_2 .EQV. .TRUE.)) THEN
               WRITE(LOGSTRING,'(A)')
     +	  '**** WARNING: detect profile for first sequence and/or '//
     +	                'profile(s) for /n'//
     +	  '              comparison sequence, but gap-elongation is '//
     +                  'not set to PROFILE, /n'//
     +	  '              will overWRITE PROFILE gap-elongation '
               CALL LOG_FILE(KLOG,LOGSTRING,1)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'gap_elongation: ',elongweight_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         
C--------------------------------------------------------------------
C     CONSERVATION WEIGHTS FOR SEQUENCE 1
C--------------------------------------------------------------------
         LASK=.TRUE.
         IF (LDIALOG .EQV. .TRUE.) THEN
            IF (LSWISSBASE .EQV. .TRUE.) THEN
               IF (LPROFILE_1 .EQV. .TRUE.) THEN
                  WEIGHT1_ANSWER='PROFILE'
                  QUESTION=' use conservation weights for first '//
     +               'sequence? /n'//
     +               'NO      : disable conservation weights /n'//
     +               'PROFILE : use weights from a MAXHOM-PROFILE'
               ELSE
                  WEIGHT1_ANSWER='NO' 
                  LASK=.FALSE.
                  QUESTION=' conservation weights for 1. sequence :'//
     +                 ' DISABLED (need PROFILE or PRE-FILTER)'
                  CALL STRPOS(QUESTION,IBEG,IEND)
                  WRITE(6,*)QUESTION(IBEG:IEND)
               ENDIF
            ELSE
               IF (LPROFILE_1 .EQV. .TRUE.) THEN
                  WEIGHT1_ANSWER='PROFILE'
                  QUESTION=' use conservation weights for first '//
     +               'sequence? /n'//
     +               'NO      : disable conservation weights /n'//
     +               'YES     : derive them from the sequence '//
     +                         'alignments /n'//
     +               'PROFILE : use weights from a MAXHOM-PROFILE'
               ELSE
                  WEIGHT1_ANSWER='NO'	
                  QUESTION=' use conservation weights for first '//
     +               ' sequence? /n'//
     +               'NO  : disable conservation weights /n'//
     +               'YES : derive them from the sequence alignments'
               ENDIF
            ENDIF
            IF (LASK  .EQV. .TRUE.) THEN
               CALL GETCHAR(MAXLENSTRING,WEIGHT1_ANSWER,QUESTION)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'conservation-weights for seq 1: ',
     +        WEIGHT1_ANSWER
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL LOWTOUP(WEIGHT1_ANSWER,MAXLENSTRING)
         IF (INDEX(WEIGHT1_ANSWER,'Y') .NE. 0) THEN
            LCONSERV_1=.TRUE. 
            LPASS2=.TRUE. 
            LCONSIMPORT=.FALSE.
         ELSE IF (INDEX(WEIGHT1_ANSWER,'NO') .NE. 0) THEN
            LCONSERV_1=.FALSE. 
            LPASS2=.FALSE. 
            LCONSIMPORT=.FALSE.
         ELSE IF (INDEX(WEIGHT1_ANSWER,'PROFILE') .NE. 0) THEN
            IF (LPROFILE_1 .EQV. .TRUE.) THEN
               LCONSIMPORT=.TRUE. 
               LCONSERV_1=.TRUE. 
               LPASS2=.FALSE.
            ELSE
               WRITE(LOGSTRING,'(A)')
     +              '*** WARNING: no profile to import '//
     +              'weights for sequence 1 ; set weights to 1.0'
               CALL LOG_FILE(KLOG,LOGSTRING,1)
            ENDIF
         ENDIF
c	IF ((lconserv_1 .eqv. .true.) .and. (.not. lconsimport)) THEN
c	  IF ((lswissbase .eqv. .true.) .or.
c     +        (lnrdbbase .eqv. .true.)) THEN
c	    WRITE(logstring,'(a)')' /n ****  HEEEE COOL DOWN  /n'//
c     +       'You want calculate the conservation-weights during a '//
c     +       'run against a DATABASE  /n'//
c     +       'That would be a two pass run over the DATABASE  /n'//
c     +      'Better get first your weights with a simple HSSP-run /n'//
c     +       '(select FASTA option) and read them afterwards via /n'//
c     +       'the profile option '
c	     call log_file(klog,logstring,1)
c	     stop
c          endif
c	endif

C--------------------------------------------------------------------
C     CONSERVATION WEIGHTS FOR SEQUENCE 2
C--------------------------------------------------------------------
         LASK=.TRUE.
         IF (LDIALOG .EQV. .TRUE.) THEN
            IF ((LPROF_2 .EQV. .TRUE.).OR.
     +           (LPROFILE_2.EQV. .TRUE.)) THEN
               WEIGHT2_ANSWER='PROFILE'
               QUESTION=
     +            ' use conservation weights for second sequence ? /n'//
     +            'NO      : disable conservation weights /n'//
     +            'PROFILE : use weights from a MAXHOM-PROFILE'
            ELSE
               WEIGHT2_ANSWER='NO' 
               LASK=.FALSE.
               QUESTION=' conservation weights for 2. sequence : '//
     +              ' *** disabled (NEED PROFILE ) ***'
               CALL STRPOS(QUESTION,IBEG,IEND)
               WRITE(6,*)QUESTION(IBEG:IEND)
            ENDIF
            IF (LASK .EQV. .TRUE.) THEN
               CALL GETCHAR(MAXLENSTRING,WEIGHT2_ANSWER,QUESTION)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'conservation-weights for seq 2: ',
     +        WEIGHT2_ANSWER
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL LOWTOUP(WEIGHT2_ANSWER,MAXLENSTRING)
         IF (INDEX(WEIGHT2_ANSWER,'NO').NE.0) THEN
            LCONSERV_2=.FALSE.
         ELSE
            LCONSERV_2=.TRUE.
         ENDIF

C--------------------------------------------------------------------
C     3 way alignment
C--------------------------------------------------------------------
         LASK=.TRUE.
         IF (LDIALOG .EQV. .TRUE.) THEN
            IF (LPROFILE_1 .EQV. .FALSE.) THEN
               WAY3_ANSWER='NO'
               QUESTION=' derive a profile and do a profile '//
     +               'alignment afterwards ? /n'//
     +               'NO  : single scan procedure/n'//
     +               'YES : do profile alignment'
            ELSE
               WAY3_ANSWER='NO' 
               LASK=.FALSE.
               QUESTION=' 3-way alignment disabled :'//
     +               ' ( already got a PROFILE )'
               CALL STRPOS(QUESTION,IBEG,IEND)
               WRITE(6,*)QUESTION(IBEG:IEND)
            ENDIF
            IF (LASK .EQV. .TRUE.) THEN
               CALL GETCHAR(MAXLENSTRING,WAY3_ANSWER,QUESTION)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')' Way3-alignment: ',way3_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL LOWTOUP(WAY3_ANSWER,MAXLENSTRING)
         IF (INDEX(WAY3_ANSWER,'Y') .NE. 0) THEN
            L3WAY=.TRUE.
         ELSE IF (INDEX(WAY3_ANSWER,'NO') .NE. 0) THEN
            L3WAY=.FALSE.
         ENDIF

C--------------------------------------------------------------------
C     INDELs in secondary structure of sequence 1
C--------------------------------------------------------------------
         LASK=.TRUE.
         IF (LDIALOG .EQV. .TRUE.) THEN
            IF (LDSSP_1 .OR. LPROFILE_1 .OR.  LISTOFSEQ_1) THEN
               QUESTION='allow insertions/deletions in secondary '//
     +               'structure segments of SEQUENCE 1? [YES/NO] '
            ELSE
               INDEL_ANSWER_1='YES' 
               LASK=.FALSE.
               QUESTION='INDEL in secondary structure of SEQUENCE 1:'//
     +      '**** disabled (need DSSP-file or PROFILES) ****'
               CALL STRPOS(QUESTION,IBEG,IEND)
               WRITE(6,*)QUESTION(IBEG:IEND)
            ENDIF
            IF (LASK ) THEN
               CALL GETCHAR(MAXLENSTRING,INDEL_ANSWER_1,QUESTION)
            ENDIF
         ENDIF
         CALL LOWTOUP(INDEL_ANSWER_1,MAXLENSTRING)
         IF (INDEX(INDEL_ANSWER_1,'Y') .NE. 0) THEN
            LINSERT_1=.TRUE.
         ELSE IF (INDEX(INDEL_ANSWER_1,'NO') .NE.0 ) THEN
            LINSERT_1=.FALSE.
         ELSE
            WRITE(6,*)'*** OPTION UNKNOWN ***'
            LINSERT_1=.TRUE.
         ENDIF
         IF (LINSERT_1) THEN
            WRITE(LOGSTRING,'(A)')
     +           'INDEL(S) in secondary structure of sequence 1 ALLOWED'
         ELSE
            WRITE(LOGSTRING,'(A)')
     +       'INDEL(s) in secondary structure of sequence 1 disallowed'
         ENDIF
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         
         IF ( LPROFILE_1 .AND. LINSERT_1) THEN
            WRITE(LOGSTRING,'(A)')'** INFO: detect PROFILE for '//
     +	       'sequence 1 and /n'//
     +         '            INDEL in secondary stucture segments '//
     +         'of SEQUENCE 1 allowed. /n'//
     +         '            If the PROFILE has high GAPOPEN values '//
     +         'for secondary /n'//
     +         '            structure segments, this will lead to '//
     +         '"gap-free" /n'//
     +         '            secondary structure segments'
            CALL LOG_FILE(KLOG,LOGSTRING,1)
            WRITE(6,*)
         ENDIF

C--------------------------------------------------------------------
C     INDELs in secondary structure of sequence 2
C--------------------------------------------------------------------
         LASK=.TRUE.
         IF (LDIALOG) THEN
            IF (LPROFILE_2 .OR. LDSSP_2 .OR. LISTOFSEQ_2) THEN
               QUESTION='allow insertions/deletions in secondary '//
     +              'structure segments of SEQUENCE 2 ? [YES/NO] '
            ELSE
               INDEL_ANSWER_2='YES' 
               LASK=.FALSE.
               QUESTION='INDEL in secondary structure of SEQUENCE 2:'//
     +      ' **** disabled (need DSSP-file or PROFILES) ****'
               CALL STRPOS(QUESTION,IBEG,IEND)
               WRITE(6,*)QUESTION(IBEG:IEND)
            ENDIF
            IF (LASK ) THEN
               CALL GETCHAR(MAXLENSTRING,INDEL_ANSWER_2,QUESTION)
            ENDIF
         ENDIF
         CALL LOWTOUP(INDEL_ANSWER_2,MAXLENSTRING)
         IF (INDEX(INDEL_ANSWER_2,'Y') .NE.0 ) THEN
            LINSERT_2=.TRUE.
         ELSE IF (INDEX(INDEL_ANSWER_2,'N') .NE.0 ) THEN
            LINSERT_2=.FALSE.
         ELSE
            WRITE(6,*)'*** OPTION UNKNOWN ***'
            LINSERT_2=.TRUE.
         ENDIF
         IF (LINSERT_2) THEN
            WRITE(LOGSTRING,'(A)')
     +           'INDEL(s) in secondary structure of SEQUENCE 2 allowed'
         ELSE
            WRITE(LOGSTRING,'(A)')
     +      'INDEL(s) in secondary structure of SEQUENCE 2 disallowed'
         ENDIF
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         
         IF ( LPROFILE_2 .AND. LINSERT_2) THEN
            WRITE(LOGSTRING,'(A)')'** WARNING: detect PROFILE for '//
     +	       'sequence 1 and/or sequence 2 and /n'//
     +         '            INDEL in secondary stucture segments '//
     +         'allowed. /n'//
     +         '            If the PROFILE has high GAPOPEN values '//
     +         'for secondary /n'//
     +         '            structure segments, this will lead to '//
     +         '"gap-free" /n'//
     +         '            secondary structure segments'
            CALL LOG_FILE(KLOG,LOGSTRING,1)
            WRITE(6,*)
         ENDIF

C--------------------------------------------------------------------
C     suboptimal by backward SETMATRIX
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            CALL GETCHAR(MAXLENSTRING,BACKWARD_ANSWER,
     +           ' suboptimal traces and reliability score ? ')
         ENDIF
         WRITE(LOGSTRING,'(A,A)')
     +      'suboptimal traces and reliability score: ',backward_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL LOWTOUP(BACKWARD_ANSWER,MAXLENSTRING)
         IF (INDEX(BACKWARD_ANSWER,'Y') .NE. 0) THEN
            LBACKWARD=.TRUE.
            IF (MAXMAT .LT. 10) THEN
               WRITE(6,*)' *** FATAL ERROR: need big array for '//
     +              'matrix, but MAXMAT is too small: ',maxmat
               STOP
            ENDIF
         ENDIF
         
C--------------------------------------------------------------------
C     filter for suboptimals
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            LASK=.TRUE.
            IF (LBACKWARD) THEN
               QUESTION=' filter range for suboptimals ? [real number]'
            ELSE
               LASK=.FALSE.
               QUESTION=' *** SUBOPTIMAL TRACES: disabled'
               CALL STRPOS(QUESTION,IBEG,IEND)
               WRITE(6,*)QUESTION(IBEG:IEND)
            ENDIF
            IF (LASK ) THEN
               CALL GETCHAR(MAXLENSTRING,FILTER_ANSWER,QUESTION)
            ENDIF
         ENDIF
         WRITE(LOGSTRING,'(A,A)')
     +        'filter range for suboptimal traces: ',filter_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL STRPOS(FILTER_ANSWER,IBEG,IEND)
         CALL READ_REAL_FROM_STRING(FILTER_ANSWER(IBEG:IEND),
     +        FILTER_VAL)

C--------------------------------------------------------------------
C     number of alignments per protein
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            CALL GETCHAR(MAXLENSTRING,NBEST_ANSWER,
     +           ' number of alignments per protein ?')
         ENDIF
         WRITE(LOGSTRING,'(A,A)')
     +        'number of alignments per protein: ',nbest_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL STRPOS(NBEST_ANSWER,IBEG,IEND)
         CALL READ_INT_FROM_STRING(NBEST_ANSWER(IBEG:IEND),NBEST)

C--------------------------------------------------------------------
C     maximum number of reported alignments
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            NGLOBALHITS=MAXHITS
            WRITE(QUESTION,'(A,I6,A)')' maximum number of reported '//
     +           'alignments ? (maximum=',maxhits,')'
            CALL GETCHAR(MAXLENSTRING,NGLOBALHITS_ANSWER,QUESTION)
         ENDIF
         CALL STRPOS(NGLOBALHITS_ANSWER,IBEG,IEND)
         CALL READ_INT_FROM_STRING(NGLOBALHITS_ANSWER(IBEG:IEND),
     +        NGLOBALHITS)
         IF (NGLOBALHITS .GT. MAXHITS) THEN
            WRITE(LOGSTRING,'(A)')'*** WARNING: NGLOBALHITS '//
     +           '.GT. MAXHITS, NGLOBALHITS is set to maximum'
            CALL LOG_FILE(KLOG,LOGSTRING,1)
            NGLOBALHITS=MAXHITS
         ENDIF
         WRITE(LOGSTRING,'(A,I6)')
     +        'maximum number of reported alignments ',nglobalhits
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
C     threshold
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            IF (LSWISSBASE .OR. LNRDBBASE) THEN
               THRESHOLD_ANSWER='formula-5'
            ENDIF
            CALL GETCHAR(MAXLENSTRING,THRESHOLD_ANSWER,
     +    ' select alignments according to threshold ? /n'//
     +    'ALL        : NO threshold /n'//
     +    'VALUE=x    : absolute value ; x=real value /n'//
     +    'CUT-x      : threshold is x percent of the maximal /n'//
     +    '             possible value (like: cut-10 ) /n'//
     +    '"filename" : import specification from file /n'//
     +    'formula    : use original HSSP-threshold curve /n'//
     +	  'formula+x  : use HSSP-theshold value plus "x" percent /n'//
     +	  'formula-x  : use HSSP-theshold value minus "x" percent')
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'threshold: ',threshold_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         ISOSIGFILE=THRESHOLD_ANSWER
         CALL LOWTOUP(THRESHOLD_ANSWER,MAXLENSTRING)
 
         IF (INDEX(THRESHOLD_ANSWER,'FORMULA') .NE. 0) THEN
            LFORMULA=.TRUE. 
            LTHRESHOLD=.TRUE. 
            LALL=.FALSE.
         ELSE IF (INDEX(THRESHOLD_ANSWER,'ALL') .NE. 0) THEN
            LFORMULA=.FALSE. 
            LTHRESHOLD=.FALSE. 
            LALL=.TRUE.
         ELSE IF (INDEX(THRESHOLD_ANSWER,'CUT') .NE. 0) THEN
            LFORMULA=.FALSE. 
            LTHRESHOLD=.FALSE. 
            LALL=.FALSE.
            IBEG=INDEX(THRESHOLD_ANSWER,'-')
            IF (IBEG .NE. 0) THEN
               CALL STRPOS(THRESHOLD_ANSWER,I,IEND)
               CALL READ_INT_FROM_STRING(
     +              THRESHOLD_ANSWER(IBEG+1:IEND),I)
               CUTVALUE1=FLOAT(I)
               WRITE(6,*)' CUTVALUE 1 IS SET TO: ',CUTVALUE1
            ELSE
               WRITE(6,*)' NO VALUE SPECIFIED; SET TO 10'
               CUTVALUE1=10.0
            ENDIF
         ELSE IF (INDEX(THRESHOLD_ANSWER,'VALUE') .NE. 0) THEN
            LFORMULA=.FALSE. 
            LTHRESHOLD=.FALSE. 
            LALL=.TRUE.
            IBEG=INDEX(THRESHOLD_ANSWER,'=')+1
            CALL READ_REAL_FROM_STRING(THRESHOLD_ANSWER(IBEG:),
     +           CUTVALUE2)
            WRITE(6,*)' CUTVALUE 2 IS SET TO: ',CUTVALUE2
         ENDIF
         
         IF (LFORMULA) THEN
            I=INDEX(ISOSIGFILE,'+') 
            J=INDEX(ISOSIGFILE,'-')
            IF (I .NE. 0) THEN
               CALL STRPOS(ISOSIGFILE,IBEG,IEND)
               CALL READ_INT_FROM_STRING(ISOSIGFILE(I+1:IEND),ISAFE)
               WRITE(6,'(A,I3,A)')' use formula value plus',
     +              ISAFE,' percent'
            ELSE IF (J .NE. 0) THEN
               CALL STRPOS(ISOSIGFILE,IBEG,IEND)
               CALL READ_INT_FROM_STRING(ISOSIGFILE(J:IEND),ISAFE)
               WRITE(6,'(A,I3,A)')' use formula value ',
     +              isafe, ' percent'
            ELSE
               ISAFE=0
            ENDIF
         ELSE IF (LTHRESHOLD) THEN	
            CALL GETHSSPCUT(KISO,MAXCUTOFFSTEPS,ISOSIGFILE,ISOLEN,
     +           ISOIDE,NSTEP)
         ENDIF

C--------------------------------------------------------------------
C     sort mode
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            IF (LSWISSBASE .OR. LNRDBBASE) THEN
               SORTMODE_ANSWER='VALUE'
            ENDIF
            CALL GETCHAR(MAXLENSTRING,SORTMODE_ANSWER,
     +           ' alignment sorting ? '//
     +    '/n NO       : no sorting (preserve order of a list)'//
     +    '/n DISTANCE : distance in %identity from HSSP-curve'//
     +    '/n VALUE    : internal score'//
     +    '/n SIGMA    : internal score / sigma'//
     +    '/n SIM/WSIM : similarity / weighted by conservation weight'//
     +    '/n IDENTITY : %identity'//
     +    '/n ZSCORE   : Gribskov Z-score'//
     +    '/n VALFORM  : apply the HSSP-formula to values'//
     +	  '/n VALPER   : internal score per residue')
         ENDIF
         CALL LOWTOUP(SORTMODE_ANSWER,MAXLENSTRING)
         IF (INDEX(SORTMODE_ANSWER,'DIST') .NE. 0) THEN
            CSORTMODE='DISTANCE'
         ELSE IF (INDEX(SORTMODE_ANSWER,'VALU') .NE. 0) THEN
            CSORTMODE='VALUE'
         ELSE IF (INDEX(SORTMODE_ANSWER,'WSIM') .NE. 0) THEN
            CSORTMODE='WSIM'
         ELSE IF (INDEX(SORTMODE_ANSWER,'SIM') .NE. 0) THEN
            CSORTMODE='SIM'
         ELSE IF (INDEX(SORTMODE_ANSWER,'SIGMA') .NE. 0) THEN
            CSORTMODE='SIGMA'
         ELSE IF (INDEX(SORTMODE_ANSWER,'IDE') .NE. 0) THEN
            CSORTMODE='IDENTITY'
         ELSE IF (INDEX(SORTMODE_ANSWER,'VALP') .NE. 0) THEN
            CSORTMODE='VALPER'
         ELSE IF (INDEX(SORTMODE_ANSWER,'VALF') .NE. 0) THEN
            CSORTMODE='VALFORM'
         ELSE IF (INDEX(SORTMODE_ANSWER,'ZSCO') .NE. 0) THEN
            CSORTMODE='ZSCORE'
         ELSE IF (INDEX(SORTMODE_ANSWER,'NO') .NE. 0) THEN
            CSORTMODE='NO'
         ELSE
            CSORTMODE='DISTANCE'	
            WRITE(LOGSTRING,'(A,A)')'**** WARNING: SORT_MODE NOT '//
     +           'KNOWN ; will use: ',CSORTMODE
            CALL LOG_FILE(KLOG,LOGSTRING,1)
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'sort mode: ',csortmode
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         
         IF (.NOT. LCONSERV_1 .AND. CSORTMODE .EQ. 'WSIM' ) THEN
            WRITE(LOGSTRING,'(a)')'*** WARNING: conservation weights'//
     +           'option is off, but sort option is "WSIM" ; '//
     +           'will switch to sortmode "SIM"'
            CALL LOG_FILE(KLOG,LOGSTRING,1)
         ENDIF

C--------------------------------------------------------------------
C     option for HSSP output
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            CALL GETCHAR(LEN(HSSP_ANSWER),HSSP_ANSWER,' HSSP output'//
     +    '/n NO       : no HSSP-file output'//
     +    '/n YES      : produce HSSP-file with default name'//
     +    '/n filename : produce HSSP-file with given name')
         ENDIF
         TEMPNAME=' ' 
         TEMPNAME(1:)=HSSP_ANSWER
         CALL LOWTOUP(HSSP_ANSWER,MAXLENSTRING)
         
         IF ( (INDEX(HSSP_ANSWER,'/') .NE. 0 ) .OR.
     +        (INDEX(HSSP_ANSWER,'.') .NE. 0 )      ) THEN
            HSSP_ANSWER=' ' 
            HSSP_ANSWER=TEMPNAME
            WRITE(LOGSTRING,'(A,A)')'HSSP-output: ',hssp_answer
            LHSSP=.TRUE.
         ELSE IF ( INDEX(HSSP_ANSWER,'YES') .NE. 0) THEN
            WRITE(LOGSTRING,'(A)')'HSSP-output: YES'
            LHSSP=.TRUE.
         ELSE IF ( INDEX(HSSP_ANSWER,'NO') .NE. 0) THEN
            WRITE(LOGSTRING,'(A)')'HSSP-output: NO'
            LHSSP=.FALSE.
         ELSE
            HSSP_ANSWER=' ' 
            HSSP_ANSWER=TEMPNAME
            WRITE(LOGSTRING,'(A,A)')'HSSP-output: ',hssp_answer
            LHSSP=.TRUE.
         ENDIF
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
         LHSSP_LONG_ID=.FALSE.
         IF (LDIALOG) THEN
            CALL GETCHAR(MAXLENSTRING,HSSP_FORMAT_ANSWER,
     +                 ' HSSP file with long ID ? '//
     +    '/n NO       : normal HSSP-file output'//
     +    '/n YES      : HSSP-file with long Protein-identifiers')
         ENDIF
         CALL LOWTOUP(HSSP_FORMAT_ANSWER,MAXLENSTRING)
         IF ( INDEX(HSSP_FORMAT_ANSWER,'YES') .NE. 0) THEN
            WRITE(LOGSTRING,'(a)')'HSSP-long ID: YES'
            LHSSP_LONG_ID=.TRUE.
            HSSP_FORMAT_ANSWER='YES'
         ELSE IF ( INDEX(HSSP_FORMAT_ANSWER,'NO') .NE. 0) THEN
            WRITE(LOGSTRING,'(A)')'HSSP-long ID: NO'
            LHSSP_LONG_ID=.FALSE.
         ELSE
            WRITE(LOGSTRING,'(A,A)')'HSSP-long ID: ',hssp_format_answer
            LHSSP_LONG_ID=.TRUE.
         ENDIF
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            CALL GETCHAR(MAXLENSTRING,SAMESEQ_ANSWER,
     +           ' show 100% identical hits ? ')
         ENDIF
         CALL LOWTOUP(SAMESEQ_ANSWER,MAXLENSTRING)
         IF (INDEX(SAMESEQ_ANSWER,'Y').NE.0) THEN
            LSHOW_SAMESEQ=.TRUE.
         ELSE
            LSHOW_SAMESEQ=.FALSE.
         ENDIF

C--------------------------------------------------------------------
C     GET GCG SIMILARITY MATRIX (HSSP-variability)
C--------------------------------------------------------------------
C     call getchar(MAXLENSTRING,metric_hssp_var,
C     +	            'METRIC FILE (HSSP-VARIABILITY) ?')
         WRITE(LOGSTRING,'(A,A)')
     +        'HSSP-variability metric: ',METRIC_HSSP_VAR
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
C     get release notes of EMBL/SWISSPROT
C--------------------------------------------------------------------
         WRITE(LOGSTRING,'(A,A)')'SWISSPROT release notes: ',relnotes
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
C     compare 3-D-structures if both are known
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            LASK=.TRUE.
            IF (LISTOFSEQ_1 .OR. LDSSP_1 ) THEN
               QUESTION=' compare 3d-structures if both are known?/n'//
     +              'YES or NO'
            ELSE
               LASK=.FALSE.
               QUESTION=' compare 3d-structures :'//
     +              ' *** disabled (NEED STRUCTURE INFORMATION) ***'
               CALL STRPOS(QUESTION,IBEG,IEND)
               WRITE(6,*)QUESTION(IBEG:IEND)
            ENDIF
            IF (LASK ) THEN
               CALL GETCHAR(MAXLENSTRING,COMPARE_ANSWER,QUESTION)
            ENDIF
         ENDIF
         CALL LOWTOUP(COMPARE_ANSWER,MAXLENSTRING)
         IF (INDEX(COMPARE_ANSWER,'Y') .NE. 0) THEN
            LCOMPSTR=.TRUE.
            WRITE(LOGSTRING,'(A)')'3D superposition: YES'
         ELSE
            WRITE(LOGSTRING,'(A)')'3D superposition: NO'
         ENDIF
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         
C--------------------------------------------------------------------
C     path for Brookhaven-files in case of private files
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            IF (LCOMPSTR) THEN
               QUESTION=' give path for the Brookhaven files '
               LASK=.TRUE.
            ELSE
               PDBPATH='OPTION DISABLED' 
               LASK=.FALSE.
               PDBPATH_ANSWER='OPTION DISABLED'
               QUESTION=' path for Brookhaven files : ** disabled **'
               CALL STRPOS(QUESTION,IBEG,IEND)
               WRITE(6,*)QUESTION(IBEG:IEND)
            ENDIF
            IF (LASK ) THEN
               CALL GETCHAR(MAXLENSTRING,PDBPATH_ANSWER,QUESTION)
            ENDIF
         ENDIF
         IF (LCOMPSTR) THEN
            PDBPATH=PDBPATH_ANSWER
            WRITE(LOGSTRING,'(A,A)')'Brookhaven files are in: ',pdbpath
            CALL LOG_FILE(KLOG,LOGSTRING,0)
         ENDIF

C--------------------------------------------------------------------
C     OUTPUT FILES
C--------------------------------------------------------------------
         IF (LDIALOG) THEN
            QUESTION=' WRITE profile for first sequence ? /n'//
     +         ' NO        : disable profile output /n'//
     +         ' YES       : WRITE profile with default filename /n'//
     +         ' "filename": WRITE profile in "filename"'
            CALL GETCHAR(MAXLENSTRING,PROFILEOUT_ANSWER,QUESTION)
         ENDIF
         PROFILEOUT=PROFILEOUT_ANSWER
         LWRITEPROFILE=.TRUE.
         CALL LOWTOUP(PROFILEOUT_ANSWER,MAXLENSTRING)
         CALL STRPOS(PROFILEOUT_ANSWER,IBEG,IEND)
         IF (PROFILEOUT_ANSWER(IBEG:IEND) .EQ. 'NO') THEN
            LWRITEPROFILE=.FALSE.
            PROFILEOUT='NO'
         ELSE IF (PROFILEOUT_ANSWER(IBEG:IEND) .EQ. 'YES') THEN
            LWRITEPROFILE=.TRUE.
            PROFILEOUT='YES'
         ENDIF
         IF ( (L3WAY .EQV. .TRUE.) .AND.
     +        (LWRITEPROFILE .EQV. .FALSE.) ) THEN
            LWRITEPROFILE=.TRUE.
            PROFILEOUT='YES'
            WRITE(6,*)' you want to do an 3-way alignment or ?'
            WRITE(6,*)' profile-out option is set now to: true'
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'profile output: ',profileout
         CALL LOG_FILE(KLOG,LOGSTRING,0)

C--------------------------------------------------------------------
         LSTRIP=.TRUE. 
         LSTRIP_LONG=.FALSE.
         IF (LDIALOG) THEN
            IF (LSWISSBASE .OR. LNRDBBASE) THEN
               STRIPFILE_ANSWER='NO'
            ENDIF
            CALL GETCHAR(MAXLENSTRING,STRIPFILE_ANSWER,
     +           'STRIP file name ? [NO=no strip file] ')
         ENDIF
         IF ( INDEX (STRIPFILE_ANSWER,'long') .GT. 0) THEN
            LSTRIP_LONG=.TRUE. 
            STRIPFILE_ANSWER='YES'
         ENDIF
 
         WRITE(LOGSTRING,'(A,A)')'strip output file: ',stripfile_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         STRIPFILE=STRIPFILE_ANSWER
         CALL LOWTOUP(STRIPFILE_ANSWER,MAXLENSTRING)
         CALL STRPOS(STRIPFILE_ANSWER,IBEG,IEND)
         IF (STRIPFILE_ANSWER(IBEG:IEND) .EQ. 'NO') THEN
            LSTRIP=.FALSE.
         ENDIF

c--------------------------------------------------------------------
         LONG_OUT=.TRUE.
         IF (LDIALOG) THEN
            IF (LSWISSBASE .OR. LNRDBBASE) THEN
               LONG_OUTPUT_ANSWER='NO'
            ENDIF
            CALL GETCHAR(MAXLENSTRING,LONG_OUTPUT_ANSWER,
     +           'long_output file name ? [NO=no output file] ')
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'long output file: ',
     +        long_output_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         LONGFILE=LONG_OUTPUT_ANSWER
         CALL LOWTOUP(LONG_OUTPUT_ANSWER,MAXLENSTRING)
         CALL STRPOS(LONG_OUTPUT_ANSWER,IBEG,IEND)
         IF (LONG_OUTPUT_ANSWER(IBEG:IEND) .EQ. 'NO') THEN
            LONG_OUT=.FALSE.
         ENDIF

C--------------------------------------------------------------------
         LTRACE=.TRUE.	
         IF (LDIALOG) THEN
            CALL GETCHAR(MAXLENSTRING,PLOTFILE_ANSWER,
     +           'Trace plot file name ? [NO=no plot file] ')
         ENDIF
         WRITE(LOGSTRING,'(A,A)')'TRACE plot file: ',plotfile_answer
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL STRPOS(PLOTFILE_ANSWER,IBEG,IEND)
         PLOTFILE=PLOTFILE_ANSWER(IBEG:IEND)
         CALL LOWTOUP(PLOTFILE_ANSWER,MAXLENSTRING)
         IF (PLOTFILE_ANSWER(IBEG:IEND) .EQ. 'NO') THEN
            LTRACE=.FALSE.
         ELSE IF (PLOTFILE_ANSWER(IBEG:IEND) .EQ. 'YES') THEN
            LTRACE=.TRUE.	
         ENDIF
         
         IF (COMMANDFILE_ANSWER .NE. 'NO' ) THEN
            CALL WRITE_MAXHOM_COM(CFILTER)
            STOP
         ENDIF


c=======================================================================
C INIT
C=======================================================================

C setting NIOSTATES, NSTRSTATES and IORANGE if SS-SA profile D.P.
         IF(LPROF_SSSA_1) THEN
            NIOSTATES_1=2
            NIOSTATES_2=2
            NSTRSTATES_1=3
            NSTRSTATES_2=3
            IORANGE(1,1)=15.00
            IORANGE(1,2)=100.00
            IORANGE(2,1)=15.00
            IORANGE(2,2)=100.00
            IORANGE(3,1)=15.00
            IORANGE(3,2)=100.00
         ENDIF


         IF (LISTOFSEQ_1) THEN
            WRITE(LOGSTRING,'(A,A)')'list of sequences for first '//
     +           'sequence: ',listfile_1
            CALL LOG_FILE(KLOG,LOGSTRING,1)
            CALL OPEN_FILE(KLIS1,LISTFILE_1,'OLD,READONLY',LERROR)
         ENDIF
CPARALLEL
C if idproc eq host:
      ENDIF
C======================================================================
 100  IF (IDPROC .EQ. ID_HOST) THEN
 
         WRITE(6,*)'============================================='//
     +         '=========================='
         WRITE(6,*)'======================== START OF COMPARISON '//
     +         '=========================='
C total number of alignments for all sequences, no of alignments above
C threshold (cons-weight)
         NALIGN=0 
         IALIGNOLD=0 
         LALIOVERFLOW=.FALSE.
C record pointer for binary tempfile
         IRECORD=0
         LDSSP_1=.FALSE. 
         CSQ_1=' '
         HEADER_1=' ' 
         COMPND_1=' ' 
         AUTHOR_1=' ' 
         SOURCE_1=' '
         ACCESSION_2=' ' 
         PDBREF_2=' '
         DO I=1,MAXSQ
            CRESID(I)=' '
            LSTRUC_1(I)=0 
            LACC_1(I)=0 
            PDBNO_1(I)=0 
            BP1_1(I)=0
            BP2_1(I)=0
         ENDDO
         CSYMBOL=' '
         CALL INIT_CHAR_ARRAY(1,MAXSQ,COLS_1,CSYMBOL)
         CALL INIT_CHAR_ARRAY(1,MAXSQ,CHAINID_1,CSYMBOL)
         CALL INIT_CHAR_ARRAY(1,MAXSQ,PREDSTR,CSYMBOL)
         CALL INIT_CHAR_ARRAY(1,MAXSQ,SHEETLABEL_1,CSYMBOL)
         CALL INIT_CHAR_ARRAY(1,MAXSQ,PREDSTRCORR,CSYMBOL)
         CSYMBOL='U'
         CALL INIT_CHAR_ARRAY(1,MAXSQ,STRUC_1,CSYMBOL)
         
         IF (LISTOFSEQ_1) THEN
            READ(KLIS1,'(A)',END=1000)FILESEQ
            CALL STRPOS(FILESEQ,IBEG,IEND) 
            NAME_1=FILESEQ(:IEND)
         ENDIF
C     all chains wanted from DSSP data set
         KCHAIN=0 
         CHAINREMARK=' ' 
         I=INDEX(NAME_1,'!')-1
         IF (I .GT. 0) THEN
            NSELECT=1 
            IEND=LEN(NAME_1)
            DO J=IEND,I+1,-1
               IF (NAME_1(J:J) .EQ. ',')NSELECT=NSELECT+1
            ENDDO
            WRITE(6,*)' use only',nselect,' chain(s) ',name_1(i:)
            CHAINREMARK(1:)=NAME_1
         ELSE
            I=LEN(NAME_1)
         ENDIF
         CALL GETPIDCODE(NAME_1(1:I),HSSPID_1)
         WRITE(LOGSTRING,'(A,A)')'sequence file 1: ',name_1
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         
         CALL CHECKFORMAT(KGETSEQ,NAME_1,SEQFORMAT,LERROR)
         LPROFILE_1=INDEX(SEQFORMAT,'PROFILE').NE.0

C  checking a type of profile (D.P.)
         IF( INDEX(SEQFORMAT,'SS-SA').NE.0 ) THEN
            LPROF_SSSA_1=.TRUE.
            LPROFILE_1=.FALSE.
         ENDIF

         IF (INDEX(SEQFORMAT,'DSSP').NE.0 .OR.
     +        INDEX(SEQFORMAT,'PROFILE-DSSP') .NE.0) THEN
            LDSSP_1=.TRUE.
         ENDIF
         NCHAIN=1
         IF (LPROFILE_1) THEN
            WRITE(*,*)' info:executing read_profile: '
            CALL READPROFILE(KPROF,NAME_1,MAXSQ,NTRANS,TRANS,LDSSP_1,
     +           N1,NCHAIN,HSSPID_1,HEADER_1,COMPND_1,
     +           SOURCE_1,AUTHOR_1,XSMIN,XSMAX,XMAPLOW,
     +           XMAPHIGH,PROFILEMETRIC,PDBNO_1,CHAINID_1,
     +           CSQ_1_ARRAY,STRUC_1,NSURF_1,COLS_1,
     +           SHEETLABEL_1,BP1_1,BP2_1,NOCC_1,GAPOPEN_1,
     +           GAPELONG_1,CONSWEIGHT_1,SIMMETRIC_1,
     +           MAXBOX,NBOX_1,PROFILEBOX_1)
         ELSE IF (LPROF_SSSA_1) THEN
            WRITE(*,*)' info:executing read_sssa_profile: '
            CALL READ_SSSA_PROFILE(KPROF,NAME_1,MAXSQ,NTRANS,TRANS,
     +           NSTRUCTRANS,NACCTRANS,
     +           LDSSP_1,N1,NCHAIN,HSSPID_1,HEADER_1,COMPND_1,
     +           SOURCE_1,AUTHOR_1,XSMIN,XSMAX,XMAPLOW,
     +           XMAPHIGH,PROFILEMETRIC,PDBNO_1,CHAINID_1,
     +           CSQ_1_ARRAY,STRUC_1,NSURF_1,COLS_1,
     +           SHEETLABEL_1,BP1_1,BP2_1,NOCC_1,GAPOPEN_1,
     +           GAPELONG_1,CONSWEIGHT_1,SIM_SSSA_METRIC_1,
     +           MAXBOX,NBOX_1,PROFILEBOX_1)    
         ELSE IF (LDSSP_1) THEN
            IF (CHAINREMARK .EQ. ' ') THEN
               CALL SELECT_UNIQUE_CHAIN(KGETSEQ,NAME_1,LINE)
            ENDIF
            CALL GETDSSPFORHSSP(KGETSEQ,NAME_1,MAXSQ,CHAINREMARK,
     +           BRKID_1,HEADER_1,COMPND_1,SOURCE_1,
     +           AUTHOR_1,N1,LRES,NCHAIN,KCHAIN,PDBNO_1,
     +           CHAINID_1,CSQ_1_ARRAY,STRUC_1,COLS_1,
     +           BP1_1,BP2_1,SHEETLABEL_1,NSURF_1)
         ELSE
             
            CALL GET_SEQ(KGETSEQ,NAME_1,TRANS,CTEMP,COMPND_1,
     +           ACCESSION_1,
     +           PDBREFLINE,PDBNO_1,N1,CSQ_1,STRUC_1_STRING,
     +           NSURF_1,LTRUNCATED,LERROR)
            DO I=1,N1
               CSQ_1_ARRAY(I)=CSQ_1(I:I)
            ENDDO
            
            IF (STRUC_1_STRING .EQ. ' ') THEN
               DO I=1,N1
                  STRUC_1(I)='U'
               ENDDO
            ELSE
               DO I=1,N1
                  STRUC_1(I)=STRUC_1_STRING(I:I)
               ENDDO
            ENDIF
C     CALL GETSEQ(KGETSEQ,MAXSQ,N1,CRESID,CSQ_1_ARRAY,STRUC_1,
C     +       NSURF_1,LDSSP_1,NAME_1,COMPND_1,ACCESSION_1,
c     +       pdbrefline,klog,trans,ntrans,kchain,nchain,ctemp)
C convert cresid to pdb-number and chain identifier, 
C used in 3d superposition
            IF (LDSSP_1) THEN
               DO I=1,N1
                  READ(CRESID(I),'(I5,A)')PDBNO_1(I),CHAINID_1(I)
               ENDDO
            ENDIF
         ENDIF
C     ERROR DURING READ
         IF (N1.EQ.0) THEN
            WRITE(LOGSTRING,'(A,A)')'*** ERROR: READ ERROR FOR: ',
     +           name_1
            CALL LOG_FILE(KLOG,LOGSTRING,1)
            GOTO 900
         ENDIF
 
         CALL SELECT_PDB_POINTER(KREF,DSSP_PATH,PDBREFLINE,PDBREF_1)
         NCHAIN_1=NCHAIN	
         NCHAINUSED=1
         DO I=1,N1
            CSQ_1(I:I)=CSQ_1_ARRAY(I)
            IF (CSQ_1(I:I) .EQ. '!')NCHAINUSED=NCHAINUSED+1
         ENDDO
         WRITE(6,*)' nchainused: ',nchainused
C build the name for the profile-output
         IF (LWRITEPROFILE .AND. PROFILEOUT_ANSWER .EQ. 'YES' ) THEN
            CALL CONCAT_STRINGS(HSSPID_1,'.profile',profileout)
         ENDIF
C build the name for the strip-output
         IF (LSTRIP .AND. STRIPFILE_ANSWER .EQ. 'YES' ) THEN
            CALL CONCAT_STRINGS(HSSPID_1,'.strip',stripfile)
         ENDIF
C build the name for the long_output
         IF (LONG_OUT .AND. LONG_OUTPUT_ANSWER .EQ. 'YES' ) THEN
            CALL CONCAT_STRINGS(HSSPID_1,'.x',longfile)
         ENDIF
C build the name for the dotplot-output
         IF (LTRACE .AND. PLOTFILE_ANSWER .EQ. 'YES' ) THEN
            CALL CONCAT_STRINGS(HSSPID_1,'.trace',plotfile)
         ENDIF
         IF (LTRACE)  CALL DEL_OLDFILE(KPLOT,PLOTFILE)
c init the conservation weights for sequence 1
         IF (LCONSERV_1 .AND. .NOT. LCONSIMPORT ) THEN
            WRITE(6,*)' CALL SETCONSERVATION'	
            CALL SETCONSERVATION(METRIC_HSSP_VAR)
            WRITE(LOGSTRING,'(a,a)')
     +           'metric for conservation weights :',metric_hssp_var
            CALL LOG_FILE(KLOG,LOGSTRING,0)
         ENDIF
C overWRITE gap-open if wanted
         IF (OPENWEIGHT_ANSWER .NE. 'PROFILE' ) THEN
            DO I=1,MAXSQ 
               GAPOPEN_1(I)=OPEN_1 
            ENDDO
            WRITE(6,*)' overWRITE gap-open penalty with: ',open_1
         ENDIF
c set gap-open to a high value in secondary structure segments
         IF (.NOT. LINSERT_1) THEN
            WRITE(6,*)' CALL PUNISHGAP'
            CALL PUNISH_GAP(N1,STRUC_1,'HE',PUNISH,GAPOPEN_1)
         ENDIF
c overWRITE gap-elongation if wanted
         IF (ELONGWEIGHT_ANSWER .NE. 'PROFILE' ) THEN
            DO I=1,MAXSQ 
               GAPELONG_1(I)=ELONG_1 
            ENDDO
            WRITE(6,*)' overWRITE gap-elongation penalty with: ',
     +           elong_1
         ENDIF
c get the beginning and end of a profile, if boxes are specified
         IPROFBEG=1 
         IPROFEND=N1
         IF (LPROFILE_1) THEN                     
            I=1 
            J=1
            DO WHILE(SIMMETRIC_1(I,J) .EQ. 0)    
               J=J+1
               IF (J .GT. NTRANS) THEN              
                  J=1 
                  I=I+1
                  IF (I .GT. N1) THEN
                     WRITE(LOGSTRING,'(A)')
     +                    '*** ERROR: the complete profile is 0.0 '
                     CALL LOG_FILE(KLOG,LOGSTRING,1)
                  ENDIF
               ENDIF
            ENDDO
            IPROFBEG=I 
            I=N1 
            J=1
            DO WHILE (SIMMETRIC_1(I,J).EQ.0)    
               J=J+1
               IF (J.GT.NTRANS) THEN              
                  J=1 
                  I=I-1 
               ENDIF
            ENDDO
            IPROFEND=I
            IF ( (IPROFBEG .NE. 1) .OR. (IPROFEND .NE. N1) ) THEN
               WRITE(6,*)'INFO: start/end set to: ',iprofbeg,iprofend
            ENDIF
         ENDIF
CTemp
CALL REVERSEAASEQ (MAXSQ,N1,CSQ_1_array,STRUC_1,NSURF_1,LDSSP_1 )
C
 
         IF (LDSSP_1) THEN
            CALL LOWER_TO_CYS(CSQ_1,N1)
         ENDIF
          
         CALL SEQ_TO_INTEGER(CSQ_1,LSQ_1,N1,TRANSPOS)
         CALL GETCHAINBREAKS(N1,LSQ_1,STRUC_1,TRANS,NBREAK_1,
     +        IBREAKPOS_1)
CAUTION LSTRUC IS NOT JUST 3 STATES
         IF (LDSSP_1) THEN
            CALL STR_TO_INT(N1,STRUC_1,LSTRUC_1,STRTRANS)
            CALL STR_TO_CLASS(MAXSTRSTATES,STR_CLASSES,N1,STRUC_1,
     +           STRCLASS_1,LSTRCLASS_1)
            CALL ACC_TO_INT(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +           NSTRSTATES_1,NIOSTATES_1,IORANGE,
     +           N1,LSQ_1,LSTRCLASS_1,NSURF_1,LACC_1)
         ELSE
            I=INDEX(STRTRANS,'U')
            CALL INIT_INT_ARRAY(1,N1,LSTRUC_1,I)
            DO I=1,MAXSTRSTATES
               IF ( INDEX(STR_CLASSES(I),STRUC_1(1)) .NE. 0) THEN
                  CALL INIT_INT_ARRAY(1,N1,LSTRCLASS_1,I)
                  CSYMBOL=STR_CLASSES(I)(1:1)
               ENDIF
            ENDDO
            DO I=1,N1 
               STRCLASS_1(I:I)=CSYMBOL 
            ENDDO
            CALL INIT_INT_ARRAY(1,N1,LACC_1,1)
         ENDIF
         
         IF (LNORM_PROFILE) THEN
            MAPLOW=0.0 
            MAPHIGH=0.0
         ELSE
            IF (LPROFILE_1 .AND. SMIN_ANSWER .EQ. 'PROFILE' ) THEN
               SMIN=XSMIN 
               SMAX=XSMAX 
               MAPLOW=XMAPLOW 
               MAPHIGH=XMAPHIGH
            ELSE IF (LPROFILE_1 .AND. SMIN_ANSWER .NE. 'IGNORE' ) THEN
               MAPLOW=XMAPLOW 
               MAPHIGH=XMAPHIGH
            ENDIF
         ENDIF
c=======================================================================
c fill simmetric if no profiles
         IF (.NOT. LPROFILE_1 .AND. (LPROFILE_2 .OR. LPROF_2)) THEN
            WRITE(6,*)'no metric for sequence 1'
         ELSE
            IF (METRICFILE .NE. 'PROFILE' ) THEN
               WRITE(*,*)' info: METRICFILE=',METRICFILE
               CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,
     +              MAXIOSTATES,NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,
     +              NIOSTATES_2,CSTRSTATES,CIOSTATES,IORANGE,
     +              KSIM,METRICFILE,SIMORG)
               CALL SCALEMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +              SIMORG,SMIN,SMAX,MAPLOW,MAPHIGH)
               CALL ACC_TO_INT(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +              NSTRSTATES_1,NIOSTATES_1,IORANGE,
     +              N1,LSQ_1,LSTRCLASS_1,NSURF_1,LACC_1)
               IF (NSTRSTATES_2 .GT. 1 .OR. NIOSTATES_2 .GT. 1) THEN
                  WRITE(6,*)' INFO: profile mode set to 6'
                  PROFILEMODE=6
               ELSE
                  CALL FILLSIMMETRIC(MAXSQ,NTRANS,MAXSTRSTATES,
     +                 MAXIOSTATES,NSTRSTATES_1,NSTRSTATES_2,
     +                 CSTRSTATES,SIMORG,N1,LSQ_1,LSTRCLASS_1,LACC_1,
     +                 SIMMETRIC_1)
                  IF (LNORM_PROFILE) THEN
                     WRITE(6,*)
     +                    ' NORM_PROFILE for profile 1 not working yet'
                     STOP
                  ELSE
                     WRITE(6,'(a,4(2x,f5.2)))')' CALL SCALE_PROFILE 1',
     +                    SMIN,SMAX,MAPLOW,MAPHIGH
                     CALL SCALE_PROFILE_METRIC(MAXSQ,NTRANS,TRANS,
     +                    SIMMETRIC_1,SMIN,SMAX,MAPLOW,MAPHIGH)
                  ENDIF
               ENDIF
C scale profile_1
            ELSE
               WRITE(6,*)' call scale_profile disabled'
c	     WRITE(6,'(a,4(2x,f5.2)))')' CALL SCALE_PROFILE 1',
c     +                                     smin,smax,maplow,maphigh
c	     call scale_profile_metric(maxsq,ntrans,trans,
c     +                           simmetric_1,smin,smax,maplow,maphigh)
            ENDIF
         ENDIF
C--------------------------------------------------------------------
         IF (LONG_OUT) THEN
            CALL OPEN_FILE(KLONG,LONGFILE,'NEW,RECL=200',LERROR)
C header to long output file
            WRITE(KLONG,'(A)')
     +            '======================================'//
     +            '============  MAXHOM-LONG  =================='//
     +            '==================================='
            CALL STRPOS(NAME_1,IBEG,IEND)
            WRITE(KLONG,'(A,A)')' test sequence    : ',
     +           name_1(ibeg:iend)
            IF (LISTOFSEQ_2) THEN
               WRITE(KLONG,'(A,A)')' list name        : ',
     +              listfile_2(1:50)
            ENDIF
            CALL STRPOS(NAME_2,IBEG,IEND)
            WRITE(klong,'(a,a)')' last name was    : ',
     +           name_2(ibeg:iend)
            WRITE(klong,'(a,i4)')' alignments       : ',nbest
            WRITE(klong,'(a,a)')' sort-mode        : ',csortmode
            WRITE(klong,'(a,a)')' weights 1        : ',
     +           weight1_answer(1:40)
            WRITE(klong,'(a,a)')' weights 2        : ',
     +           weight2_answer(1:40)
            WRITE(klong,'(a,f5.2)')' smin             : ',smin
            WRITE(klong,'(a,f5.2)')' smax             : ',smax
            WRITE(klong,'(a,f5.2)')' maplow           : ',maplow
            WRITE(klong,'(a,f5.2)')' maphigh          : ',maphigh
            WRITE(klong,'(a,a)')' gap_open         : ',
     +           openweight_answer(1:40)
            WRITE(klong,'(a,a)')' gap_elongation   : ',
     +           elongweight_answer     (1:40)
            WRITE(klong,'(a,a)')' INDEL in sec-struc of SEQ 1: ',
     +           indel_answer_1(1:40)
            WRITE(klong,'(a,a)')' INDEL in sec-struc of SEQ 2: ',
     +           indel_answer_2(1:40)
            WRITE(klong,'(a,i4)')' NBEST alignments   : ',nbest
            WRITE(klong,'(a,a)')' secondary structure alignment: ',
     +           struc_align_answer(1:40)
            WRITE(klong,'(a)')
     +           '========================================='//
     +           '==================================================='
         ENDIF


C--------------------------------------------------------------------
C HERE START SECOND PASS AFTER CALCULATING CONSERVATION WEIGHTS
C--------------------------------------------------------------------
C initialize before comparisons:
C   total number of alignments for all sequences
C   record pointer for binary tempfile
C   number of alignments above threshold (cons-weight)
C   number of dssp files compared
C
C
 200     IRECORD=0 
         IALIGNOLD=0 
         IDSSP=0 
         NRECORD=0
         IALIGN_GOOD=0
         NALIGN=0
         IF (LSWISSBASE .OR. LNRDBBASE) THEN
            NFILE=0
            CALL CONCAT_STRINGS(SPLIT_DB_PATH,SPLIT_DB_INDEX,
     +           TEMPNAME)
            CALL CONCAT_STRING_INT(
     +           'OLD,DIRECT,FORMATTED,READONLY,RECL=',INDEXRECLEN,LINE)
            CALL OPEN_FILE(KINDEX,TEMPNAME,LINE,LERROR)
            READ(KINDEX,'(A6,I6,I12,I12)',REC=1)TEMPSTRING,NFILE,
     +           NENTRIES,NAMINO_ACIDS
            IF (INDEX(TEMPSTRING,'BINARY') .NE. 0) THEN
               LBINARY=.TRUE.
            ELSE
               LBINARY=.FALSE.
            ENDIF
 
c	    read(kindex,'(i6,i12,i12)',rec=1)nfile,nentries,namino_acids
            CLOSE(KINDEX)
Caution
cdebug
c	    nfile=10
            WRITE(6,'(A,A,I4,I12,I12)')TEMPSTRING(1:6),' nfile: ',
     +           NFILE,NENTRIES,NAMINO_ACIDS
            IF ( NENTRIES .GT. MAXALIGNS) THEN
               WRITE(LOGSTRING,*)' *** FATAL ERROR: database '//
     +              'contains more entries than MAXALIGNS'
               CALL LOG_FILE(KLOG,LOGSTRING,1)
               STOP
            ENDIF
 
         ELSE IF (LISTOFSEQ_2) THEN
            CALL CONCAT_STRINGS('comparison is with a list of '//
     +           'sequences. /n Sequence names are in: ',listfile_2,
     +           LOGSTRING)
            CALL LOG_FILE(KLOG,LOGSTRING,1)
            CALL OPEN_FILE(KLIS2,LISTFILE_2,'OLD,READONLY',LERROR)
         ENDIF
 
         LDSSP_2=.FALSE.
         N2IN=0
         HEADER_2=' ' 
         COMPND_2=' ' 
         AUTHOR_2=' ' 
         SOURCE_2=' '
         CSYMBOL=' ' 
         CSQ_2=' '
         DO I=1,MAXSQ
            CRESID(I)=' '
            PDBNO_2(I)=0 
            BP1_2(I)=0 
            BP2_2(I)=0
            LACC_2(I)=0 
            LSTRUC_2(I)=0 
            CONSWEIGHT_2(I)=1.0
         ENDDO
         CALL INIT_CHAR_ARRAY(1,MAXSQ,COLS_2,CSYMBOL)
         CALL INIT_CHAR_ARRAY(1,MAXSQ,CHAINID_2,CSYMBOL)
         CALL INIT_CHAR_ARRAY(1,MAXSQ,SHEETLABEL_2,CSYMBOL)
         CALL INIT_CHAR_ARRAY(1,MAXSQ,STRUC_2,CSYMBOL)
         
         CALL CONCAT_STRINGS(COREFILE,JOB_ID,CORETEMP)
         TEMPNAME=CORETEMP
         IF (COREPATH .NE. ' ') THEN
            CALL CONCAT_STRINGS(COREPATH,TEMPNAME,CORETEMP)
         ENDIF
c          corefile=coretemp
 
         WRITE(FILE_OPTION(1:),'(A,I6)')
     +        'UNFORMATTED,DIRECT,NEW,RECL=',maxrecordlen
c	WRITE(6,*)'master: ',coretemp(1:60)
c	call flush_unit(6)
         CALL OPEN_FILE(KCORE,CORETEMP,FILE_OPTION,LERROR)
 
 
         WRITE(6,*)'***********************************************'
         WRITE(6,*)'          working...'
         WRITE(6,*)'***********************************************'
C=======================================================================
C     PARALLEL VIA MESSAGE PASSING
C=======================================================================
         IF (LPARALLEL) THEN
            IF (LSWISSBASE .OR. LNRDBBASE .OR. LISTOFSEQ_2 ) THEN
               CALL MAXHOM_PARALLEL_INTERFACE(LH1,LH2,NFILE,NALIGN,
     +              NENTRIES,NAMINO_ACIDS)
            ELSE
               WRITE(6,*)' not implemented yet' 
               STOP
            ENDIF
            CLOSE(KCORE)
C======================================================================
C     NOT PARALLEL: if only 1 processor
C======================================================================
         ELSE
            CALL GET_CPU_TIME('init phase:',
     +           IDPROC,ITIME_OLD,ITIME_NEW,TOTAL_TIME,LOGSTRING)
            CALL LOG_FILE(KLOG,LOGSTRING,2)
            
            IF (LSWISSBASE) THEN
               DO IFILE=1,NFILE
                  CALL OPEN_SW_DATA_FILE(KBASE,LBINARY,IFILE,
     +                 SPLIT_DB_DATA,SPLIT_DB_PATH,HOSTNAME)
                  LENDFILE=.FALSE.
                  DO WHILE (.NOT. LENDFILE)
                     CALL GET_SWISS_ENTRY(MAXSQ,KBASE,LBINARY,N2IN,
     +                    NAME_2,
     +                    COMPND_2,ACCESSION_2,PDBREF_2,CSQ_2,LENDFILE)
                     IF (.NOT. LENDFILE) THEN
                        CALL DO_ALIGN(LH1,LH2,IDPROC,
     +                       NALIGN,NRECORD,SDEV)
                     ENDIF
                  ENDDO
                  CLOSE(KBASE)
                  WRITE(6,'(A,I4)')'files done: ',ifile
               ENDDO
               CALL GET_CPU_TIME('database scan phase:',idproc,
     +              ITIME_OLD,ITIME_NEW,TOTAL_TIME,LOGSTRING)
               CALL LOG_FILE(KLOG,LOGSTRING,2)

C=======================================================================
            ELSE IF (LFASTA_DB) THEN
               LHSSP_LONG_ID=.TRUE.
               CALL OPEN_FILE(KBASE,NAME2_ANSWER,'OLD,READONLY',LERROR)
               LENDFILE=.FALSE.
               DO WHILE (.NOT. LENDFILE)
                  CALL GET_FASTA_DB_ENTRY(MAXSQ,KBASE,N2IN,NAME_2,
     +                 COMPND_2,ACCESSION_2,PDBREF_2,CSQ_2,LENDFILE)
                  IF (.NOT. LENDFILE) THEN
                     CALL DO_ALIGN(LH1,LH2,IDPROC,NALIGN,NRECORD,SDEV)
                  ENDIF
               ENDDO
               CLOSE(KBASE)
               CALL GET_CPU_TIME('database scan phase:',idproc,
     +              ITIME_OLD,ITIME_NEW,TOTAL_TIME,LOGSTRING)
               CALL LOG_FILE(KLOG,LOGSTRING,2)
               IF (LPASS2) THEN 
                  LPASS2=.FALSE.
                  NAME_2=LISTFILE_2	
                  LOGSTRING='*** START NOW THE SECOND PASS ***'
                  CALL LOG_FILE(KLOG,LOGSTRING,1)
                  GOTO 200
               ENDIF
C=======================================================================
            ELSE
               LENDFILE=.FALSE.
               DO WHILE (.NOT. LENDFILE)
                  IF (LISTOFSEQ_2) THEN
                     CALL READ_FILENAME(KLIS2,FILESEQ,LENDFILE,LERROR)
                     IF (.NOT. LENDFILE .AND. .NOT. LERROR) THEN
                        CALL STRPOS(FILESEQ,IBEG,IEND)
C                        WRITE(6,*)'file:',fileseq(ibeg:iend)
                        NAME_2=FILESEQ(IBEG:IEND)
                     ENDIF
                  ENDIF
                  IF (.NOT. LENDFILE) THEN
                     IF (.NOT. LISTOFSEQ_2) LENDFILE=.TRUE.
                     CALL CHECKFORMAT(KGETSEQ,NAME_2,SEQFORMAT,LERROR)
                     IF (INDEX(SEQFORMAT,'PROFILE').NE.0)
     +                    LPROFILE_2=.TRUE.
                     IF (INDEX(SEQFORMAT,'DSSP'   ).NE.0) 
     +                    LDSSP_2=.TRUE.
                     IF (LPROFILE_2) THEN
                        WRITE(LOGSTRING,'(A,A)')'read PROFILE 2: ',
     +                       NAME_2
                        CALL LOG_FILE(KLOG,LOGSTRING,1)
                        CALL READPROFILE(KPROF,NAME_2,MAXSQ,NTRANS,
     +                       TRANS,LDSSP_2,N2IN,NCHAIN,HSSPID_2,
     +                       HEADER_2,COMPND_2,SOURCE_2,AUTHOR_2,
     +                       XSMIN,XSMAX,XMAPLOW,XMAPHIGH,
     +                       PROFILEMETRIC,PDBNO_2,CHAINID_2,
     +                       CSQ_2_ARRAY,STRUC_2,NSURF_2,COLS_2,
     +                       SHEETLABEL_2,BP1_2,BP2_2,NOCC_2,
     +                       GAPOPEN_2,GAPELONG_2,CONSWEIGHT_2,
     +                       SIMMETRIC_2,MAXBOX,NBOX_2,PROFILEBOX_2)
                        DO I=1,N2IN 
                           CSQ_2(I:I)=CSQ_2_ARRAY(I) 
                        ENDDO
caution
C cstrstates,simorg and lsq_2 not known here
C pass simorg and set lsq_2
                        IF (METRICFILE .NE. 'PROFILE') THEN
                           WRITE(6,*)' option not possible, ask rs?'
                           STOP
c	              call fillsimmetric(maxsq,ntrans,maxstrstates,
c     +                           nstrstates_1,cstrstates,simorg,
c     +                           n2in,lsq_2,lstrclass_2,lacc_2,simmetric_2)
                        ENDIF
                        IF (SMIN_ANSWER .EQ. 'PROFILE') THEN
                           SMIN=XSMIN 
                           SMAX=XSMAX 
                           MAPLOW=XMAPLOW
                           MAPHIGH=XMAPHIGH
                        ELSE IF (LPROFILE_2 .AND. SMIN_ANSWER .NE.
     +                          'PROFILE') THEN
                           MAPLOW=XMAPLOW 
                           MAPHIGH=XMAPHIGH
                        ENDIF
                        IF (OPENWEIGHT_ANSWER .NE. 'PROFILE') THEN
                           DO I=1,MAXSQ 
                              GAPOPEN_2(I)=OPEN_1 
                           ENDDO
                        ENDIF
                        IF (ELONGWEIGHT_ANSWER .NE. 'PROFILE') THEN
                           DO I=1,MAXSQ 
                              GAPELONG_2(I)=ELONG_1 
                           ENDDO
                        ENDIF
C reset conservation weights for sequence 2 if not wanted
                        IF (.NOT. LCONSERV_2 ) THEN
                           DO I=1,MAXSQ 
                              CONSWEIGHT_2(I)=1.0 
                           ENDDO
                        ENDIF
                        IF (LNORM_PROFILE) THEN
                           WRITE(6,*)'CALL NORM_PROFILE '
                           SMIN=0.0   
                           SMAX=0.0
                           MAPLOW=0.0 
                           MAPHIGH=0.0
                           CALL NORM_PROFILE(MAXSQ,NTRANS,TRANS,N2IN,
     +                          N1,LSQ_1,SIMMETRIC_2,PROFILE_EPSILON,
     +                          PROFILE_GAMMA,SMIN,SMAX,MAPLOW,
     +                          MAPHIGH,GAPOPEN_2,GAPELONG_2,SDEV)
                        ELSE
                           WRITE(6,*)' call scale_profile disabled'
 
c	              WRITE(6,'(a,4(2x,f5.2)))')'CALL SCALE_PROFILE 2',
c     +                          smin,smax,maplow,maphigh
c	              call scale_profile_metric(maxsq,ntrans,trans,
c     +                            simmetric_2,smin,smax,maplow,maphigh)
                        ENDIF
                     ELSE
C all chains wanted from dssp data set
                        CALL CHECKFORMAT(KGETSEQ,NAME_2,SEQFORMAT,
     +                                   LERROR)
                        IF (INDEX(SEQFORMAT,'DSSP') .NE. 0 .OR.
     +                       INDEX(SEQFORMAT,'PROFILE-DSSP') .NE.0) THEN
                           LDSSP_2=.TRUE.
                        ENDIF
                        
                        KCHAIN=0
                        TEMPNAME=' '
                        I=INDEX(NAME_2,'!')
                        IF (I .GT. 0) THEN
                           TEMPNAME(1:)=NAME_2(1:I-2)
                           CTEMP(1:)=NAME_2(I+2:)
                        ELSE
                           TEMPNAME(1:)=NAME_2(1:)
                           CTEMP=' '
                        ENDIF
                        PDBREFLINE=' '
                        IF (LDSSP_2 .EQV. .FALSE.) THEN
                           CALL GET_SEQ(KGETSEQ,TEMPNAME,TRANS,CTEMP,
     +                          COMPND_2,ACCESSION_2,PDBREFLINE,PDBNO_2,
     +                          N2IN,CSQ_2,STRUC_2_STRING,NSURF_2,
     +                          LTRUNCATED,LERROR)
C convert cresid to pdb-number and chain identifier, used in 3d superposition
C cresid from getseq is :
C "1234AB" (number, alternate residue, chain identifier)
C here skip alternate residue and append chain_id
                           IF ( STRUC_2_STRING .EQ. ' ') THEN
                              DO I=1,N2IN
                                 STRUC_2(I)='U'
                              ENDDO
                           ELSE
                              DO I=1,N2IN
                                 STRUC_2(I)=STRUC_2_STRING(I:I)
                              ENDDO
                           ENDIF
                           DO I=1,N2IN 
                              CSQ_2_ARRAY(I)=CSQ_2(I:I)
                              READ(CRESID(I),'(I4,1X,A)')
     +                             PDBNO_2(I),CHAINID_2(I)
                           ENDDO
                        ELSE
C     ALL CHAINS WANTED FROM DSSP DATA SET
                           K=0 
                           CHAINREMARK=' '
                           TEMPNAME(1:)=NAME_2
                           I=INDEX(TEMPNAME,'!')
                           IF (I .GT. 0) THEN
                              KSELECT=1 
                              IEND=LEN(TEMPNAME)
                              DO J=IEND,I+1,-1
                                 IF (TEMPNAME(J:J) .EQ. ',')
     +                                KSELECT=KSELECT+1
                              ENDDO
c                           WRITE(6,*)' use ',kselect,' chain(s) ',
c     +                               tempname(i:)
                              CHAINREMARK(1:)=TEMPNAME
                              TEMPNAME(1:)=NAME_2(1:I-2)
                           ELSE
                              CALL SELECT_UNIQUE_CHAIN(KGETSEQ,
     +                             TEMPNAME,LINE)
                           ENDIF
                           J=1
                           CALL GETDSSPFORHSSP(KGETSEQ,TEMPNAME,
     +                          MAXSQ,CHAINREMARK,
     +                          BRKID_2,HEADER_2,COMPND_2,SOURCE_2,
     +                          AUTHOR_2,N2IN,I,J,K,PDBNO_2,
     +                          CHAINID_2,CSQ_2_ARRAY,STRUC_2,COLS_2,
     +                          BP1_2,BP2_2,SHEETLABEL_2,NSURF_2)
                           DO I=1,N2IN
                              CSQ_2(I:I)=CSQ_2_ARRAY(I)
                           ENDDO
c                        call getpidcode(name_2,pdbref_2)
                        ENDIF
                        CALL SELECT_PDB_POINTER(KREF,DSSP_PATH,
     +                       PDBREFLINE,PDBREF_2)
                     ENDIF
                     CALL DO_ALIGN(LH1,LH2,IDPROC,NALIGN,NRECORD,SDEV)
                  ENDIF
               ENDDO
               IF (LPASS2) THEN 
                  LPASS2=.FALSE.
                  REWIND(KLIS2)
                  NAME_2=LISTFILE_2	
                  LOGSTRING=
     +                 '******* START NOW THE SECOND PASS *********'
                  CALL LOG_FILE(KLOG,LOGSTRING,1)
                  GOTO 200
               ENDIF
               IF (LISTOFSEQ_2) THEN
                  CLOSE(KLIS2)
               ENDIF
            ENDIF
            CLOSE(KCORE)
C     END : NOT LPARALLEL
         ENDIF
C=======================================================================
C     ONLY HOST IS DOING THE REST
C=======================================================================
         NSELECT=NALIGN-(MIN(NALIGN,NGLOBALHITS))+1

C=======================================================================
C     QSORT for globally best alignments
C=======================================================================
 
 
CAUTION: also activate checkval in loop over selected ali below
         WRITE(6,*)' calculate ZSCORE'
c	  call open_file(kdeb,'DEBUG.X','NEW',lerror)
c	  call profilenormal(kdeb,len2_orig,
c     +                      alisortkey_global,nalign,z_order,
c     +                      zscore_temp,lerror)
c	  close(kdeb)
         IF (NALIGN .GT. 10) THEN
            CALL MOMENT(ALISORTKEY,NALIGN,AVE,ADEV,SDEV,VAR,SKEW,
     +           CURT)
            DO I=1,NALIGN
               ZSCORE_TEMP(I)=(ALISORTKEY(I) - AVE) / SDEV
            ENDDO
         ELSE
            WRITE(LOGSTRING,*)'NOT enough data for ZSCORE calculation'
            CALL LOG_FILE(KLOG,LOGSTRING,1)
         ENDIF
         IF (CSORTMODE .EQ. 'ZSCORE' ) THEN
            WRITE(6,*) 'ENTER GLOBAL QSORT for ZSCORE: SIZE',nalign
            CALL MAXHOM_QSORT(NALIGN,IRECPOI,IFILEPOI,
     +           ZSCORE_TEMP)
         ELSE
            WRITE(6,*) 'ENTER GLOBAL QSORT: SIZE',nalign
            CALL MAXHOM_QSORT(NALIGN,IRECPOI,IFILEPOI,
     +           ALISORTKEY)
         ENDIF
C=======================================================================
         IF (NALIGN .GT. 0) THEN
c	    IF (lcompstr) THEN
c	     call open_file(kstruc,'struc.data','UNKNOWN,APPEND',lerror)
c	    endif
C=======================================================================
C WRITE simple histogram of scores
C=======================================================================
c	    IF (lswissbase .or. lnrdbbase) THEN
c	      call concat_strings(hsspid_1,'.histo',histofile)
c	      call WRITE_histo(khisto,histofile,nalign,alisortkey)
c	    endif
C=======================================================================
C alis stored in 1.....NALIGN
C                <.....all.......>
C                  L ------>        index of all ALXX
C=======================================================================
C if only one file
C open datafile(s) for homogenous enviroment
            WRITE(FILE_OPTION(1:),'(A,I6)')
     +           'UNFORMATTED,DIRECT,OLD,RECL=',maxrecordlen
            CALL OPEN_FILE(KCORE,CORETEMP,FILE_OPTION,LERROR)
            IF (NWORKSET .GT. 0) THEN
C==================================================================
C send alignment requests to node
C==================================================================
c            else
               LALI=NALIGN+1 
               IAL=0
               WRITE(6,*)' send alignment requests...'
               DO WHILE(LALI .GE. (NALIGN - IALIGN_GOOD+2) )
                  LALI=LALI-1 
                  IAL=IAL+1 
                  IRECORD=IRECPOI(LALI)
                  IF (IRECORD .LE. 0) THEN
                     WRITE(6,*)' uuuppps, irecord .le. 0 '
                     LCONSIDER=.FALSE.
                  ELSE
                     IWORKER=IFILEPOI(LALI)
                     IF (IWORKER .NE. ID_HOST) THEN
                        IF (CSORTMODE .EQ. 'ZSCORE') THEN
c     zscore(ial)=zscore_temp(lali)
                           CHECKVAL=ZSCORE_TEMP(LALI)
                        ELSE
c	                zscore(ial)=zscore_temp(ial)
                           CHECKVAL=ALISORTKEY(LALI)
                        ENDIF
c                     WRITE(6,*)' send request ',iworker,irecord,ial
                        CALL SEND_ALI_REQUEST(IWORKER,IRECORD,IAL,
     +                       CHECKVAL)
                     ENDIF
                  ENDIF
               ENDDO
            ENDIF
C==================================================================
C collect alignment from node (message tag is ali-number)
C==================================================================
            LALI=NALIGN+1 
            IAL=0
            ISEQPOS=1 
            ISTRPOS=1 
            IOPOS=1 
            INSPOS=1
            LCONSIDER=.TRUE. 
            LBUFFEROVERFLOW=.FALSE.
            WRITE(6,*)' collecting best alignments...'
            
            DO WHILE ( (LALI .GE. (NALIGN - IALIGN_GOOD+2)) .AND.
     +           (LBUFFEROVERFLOW .EQV. .FALSE.) .AND.
     +           (IAL+1 .LE. MAXHITS) )
               LALI=LALI-1 
               IAL=IAL+1 
               IWORKER=IFILEPOI(LALI)
               IF (IWORKER .GE. 0) THEN
                  IF (IWORKER .NE. ID_HOST) THEN
c                  WRITE(6,*)' node alignment ',iworker,ial
                     CALL GETALIGN_FROM_WORKER(IWORKER,IAL,
     +                    IFIR,LEN1,LENOCC,JFIR,JLAS,IDEL,NDEL,
     +                    VALUE,RMS,HOM,SIM,SDEV,
     +                    DISTANCE)
                  ELSE
                     IF (CSORTMODE .EQ. 'ZSCORE') THEN
c	             zscore(ial)=zscore_temp(lali)
                        CHECKVAL=ZSCORE_TEMP(LALI)
                     ELSE
c	             zscore(ial)=zscore_temp(ial)
                        CHECKVAL=ALISORTKEY(LALI)
                     ENDIF
                     IRECORD=IRECPOI(LALI)
c                  WRITE(6,*)' host alignment ',irecord,checkval
                     CALL GETALIGN(KCORE,IRECORD,IFIR,LEN1,LENOCC,JFIR,
     +                    JLAS,IDEL,NDEL,VALUE,
     +                    RMS,HOM,SIM,SDEV,DISTANCE,CHECKVAL)
                  ENDIF
                  
                  IF (CSORTMODE .EQ. 'ZSCORE') THEN
                     ZSCORE(IAL)=ZSCORE_TEMP(LALI)
                  ELSE
                     ZSCORE(IAL)=ZSCORE_TEMP(IAL)
                  ENDIF
c store alignment pointers, identity, similarity....
C length of alignment in HSSP-output is number of occupied position
C length without insertions deletions
                  AL_IFIRST(IAL)=IFIR        
                  AL_ILAST(IAL)=IFIR+LEN1-1
                  AL_LEN(IAL)=LEN1           
                  AL_RMS(IAL)=RMS
                  AL_JFIRST(IAL)=JFIR+NSHIFTED
                  AL_JLAST(IAL)=JLAS+NSHIFTED
                  AL_VPERRES(IAL)=VALUE/LENOCC
                  AL_VAL(IAL)=VALUE
                  AL_SDEV(IAL)=SDEV
                  AL_HOM(IAL)=HOM            
                  AL_SIM(IAL)=SIM
                  AL_HOMLEN(IAL)=LENOCC      
                  AL_LSEQ_2(IAL)=N2IN
                  AL_LGAP(IAL)=IDEL          
                  AL_NGAP(IAL)=NDEL
                  AL_COMPOUND(IAL)=COMPND_2
                  AL_ACCESSION(IAL)=ACCESSION_2
                  AL_PDB_POINTER(IAL)=PDBREF_2
                  CALL GETPIDCODE(NAME_2,AL_EMBLPID(IAL))
                  TEMPNAME=NAME_2
                  I=INDEX(TEMPNAME,'!')-1
                  IF ( I .GT. 0) THEN
                     CALL CONCAT_STRINGS(AL_EMBLPID(IAL),
     +                    TEMPNAME(I+2:),LINE)
                     AL_EMBLPID(IAL)=LINE(1:LEN(AL_EMBLPID(IAL)))
                  ENDIF
                  
C store alignments in buffer SEQBUFFER
                  IF (ISEQPOS+LEN1+1 .LE. MAXSEQBUFFER) THEN
                     DO K=1,LEN1 
                        SEQBUFFER(ISEQPOS+K-1)=AL_2(K:K)
                     ENDDO
                     ISEQPOINTER(IAL)=ISEQPOS 
                     ISEQPOS=ISEQPOS+LEN1+1
                     SEQBUFFER(ISEQPOS)='/'
                  ELSE
                     WRITE(LOGSTRING,*)' MAXSEQBUFFER buffer overflow'
                     CALL LOG_FILE(KLOG,LOGSTRING,1)
                     LBUFFEROVERFLOW=.TRUE.
                  ENDIF
C store secondary structure and inside/outside in buffer STRBUFFER/CIOBUFFER
                  ISTRPOINTER(IAL)=0 
                  IOPOINTER(IAL)=0
                  IF (LDSSP_2) THEN
                     IF (ISTRPOS+LEN1+1 .LE. MAXSTRBUFFER) THEN
                        DO K=1,LEN1
                           STRBUFFER(ISTRPOS+K-1)=SAL_2(K:K)
                        ENDDO
                        ISTRPOINTER(IAL)=ISTRPOS 
                        ISTRPOS=ISTRPOS+LEN1+1
                        STRBUFFER(ISTRPOS)='/'
                     ELSE
                        WRITE(LOGSTRING,*)
     +                       ' MAXSTRBUFFER buffer overflow'
                        CALL LOG_FILE(KLOG,LOGSTRING,1)
                        LBUFFEROVERFLOW=.TRUE.
                     ENDIF
                     IF (IOPOS+LEN1+1 .LE. MAXIOBUFFER) THEN
                        DO K=1,LEN1
                           WRITE(CIOBUFFER(IOPOS+K-1),'(A1)')
     +                          CIOSTATES(LACC_2(K):LACC_2(K))
                           IF (CIOSTATES(LACC_2(K):LACC_2(K)) .EQ.
     +                          ' ') THEN
                              CIOBUFFER(IOPOS+K-1)='U'
                           ELSE
                              WRITE(CIOBUFFER(IOPOS+K-1),'(A1)')
     +                             CIOSTATES(LACC_2(K):LACC_2(K))
                           ENDIF
                        ENDDO
                        IOPOINTER(IAL)=IOPOS 
                        IOPOS=IOPOS+LEN1+1
                        CIOBUFFER(IOPOS)='/'
                     ELSE
                        WRITE(LOGSTRING,*)' MAXIOBUFFER buffer overflw'
                        CALL LOG_FILE(KLOG,LOGSTRING,1)
                        LBUFFEROVERFLOW=.TRUE.
                     ENDIF
                  ENDIF
c accumulate predicted structure
                  IF (LDSSP_2 ) THEN
C convert to structure class, evaluate STRHOM and store in al_strhom
                     IDSSP=IDSSP+1 
                     IPOS=1 
                     IAGR=0
                     DO I=IFIR,IFIR+LEN1-1
                        CALL STRUC_CLASS(MAXSTRSTATES,STR_CLASSES,
     +                       STRCLASS_1(I:I),CTEMP,ICLASS)
                        CALL STRUC_CLASS(MAXSTRSTATES,STR_CLASSES,
     +                       SAL_2(IPOS:IPOS),CTEMP,JCLASS)
                        IF (ICLASS .NE. 0 .AND. JCLASS .NE. 0) THEN
                           STRSUM(JCLASS,I)= STRSUM(JCLASS,I) + VALUE
                           IF (ICLASS .EQ. JCLASS ) IAGR=IAGR+1
                        ENDIF
                        IPOS=IPOS+1
                     ENDDO
C AL_STRHOM is fractional structure agreement for alignment L
                     AL_STRHOM(IAL)=FLOAT(IAGR) / FLOAT(LEN1)
                  ELSE
                     AL_STRHOM(IAL)=-1.0
                  ENDIF
C     store insertions of seq2 in array INSBUFFER
C     Note: insertions are stored from trace in the following way:
C
C  insertion            1.        2.           3.
C       <<<<==========aTIGHn====gHDFGt======eRTWQEp====<<<<< alignment
C insseq: *aTIGHn*gHDFGt*eRTWQEp
C here we loop from insertion number 3 to 1 and have to reverse
C the string to get the right order
C "aTIGHn" becomes now "nHGITa"
C insbuffer: pRQWTRetGFDHgnHGITa
C
                  IF (IINS .GT. 0) THEN
                     CALL STRPOS(INSSEQ,IBEG,IEND)
                     IPOS=IEND
                     IF (INSNUMBER + IINS .LE. MAXINS) THEN
                        DO I=IINS,1,-1
                           IF (INSPOS+INSLEN_LOCAL(I)+2 .LE. 
     +                          MAXINSBUFFER) THEN
                              DO K=INSPOS+INSLEN_LOCAL(I)+1,INSPOS,-1
                                 INSBUFFER(K)=INSSEQ(IPOS:IPOS) 
                                 IPOS=IPOS-1
                              ENDDO
                              INSNUMBER=INSNUMBER + 1
                              INSALI(INSNUMBER)= IAL
                              INSPOINTER(INSNUMBER)=INSPOS
                              INSBEG_1(INSNUMBER)=INSBEG_1_LOCAL(I)
                              INSBEG_2(INSNUMBER)=INSBEG_2_LOCAL(I)
                              INSLEN(INSNUMBER)=INSLEN_LOCAL(I)
                              INSPOS=INSPOS+INSLEN_LOCAL(I)+2
                              IPOS =IPOS-1
                           ELSE
                              WRITE(LOGSTRING,*)
     +                             ' BUFFER MAXINSBUFFER OVERFLOW'
                              CALL LOG_FILE(KLOG,LOGSTRING,1)
                              LBUFFEROVERFLOW=.TRUE.
                           ENDIF
                        ENDDO
                     ELSE
                        WRITE(6,*)' MAXINS overflow'
                        LBUFFEROVERFLOW=.TRUE.
                     ENDIF
                  ENDIF
c     WRITE data for HSSP-PLOT
c     IF (lcompstr) THEN	
c	           WRITE(kstruc,'(1x,i4,4(2x,f7.2),2x,i4,2x,a,2x,a)')
c     +                  lenocc,hom*100.0,sim*100.0,al_strhom(ial)*100.0,
c     +	                rms,idel,hsspid_1,name_2(1:20)
c                endif
C=======================================================================
               ENDIF
C end loop over selected alignments
            ENDDO
C close temporary files
            IF (NWORKSET .EQ. 0) THEN
               CLOSE(KCORE)
            ELSE
               MSGTYPE=6000 
               IRECORD=-1 
               CHECKVAL=0.0
               DO ISET=1,NWORKSET
                  CALL MP_INIT_SEND()
                  CALL MP_PUT_INT4(MSGTYPE,LINK(ISET),IRECORD,N_ONE)
                  CALL MP_PUT_INT4(MSGTYPE,LINK(ISET),IRECORD,N_ONE)
                  CALL MP_PUT_REAL4(MSGTYPE,LINK(ISET),CHECKVAL,N_ONE)
                  CALL MP_SEND_DATA(MSGTYPE,LINK(ISET))
               ENDDO
            ENDIF
C=======================================================================
            IF (LBUFFEROVERFLOW) THEN
               CALL CONCAT_STRING_INT('WARNING: INTERNAL BUFFER '//
     +	            'OVERFLOW /n SELECTED ALIGNMENTS: ',ial,logstring)
               CALL LOG_FILE(KLOG,LOGSTRING,1)
            ENDIF
            WRITE(LOGSTRING,*)
     +           'number of alignments above choosen threshold: ',ial
            CALL LOG_FILE(KLOG,LOGSTRING,1)
C=======================================================================
            NALIGN=IAL
c	    IF (lcompstr) THEN ; close(kstruc) ; endif
C=======================================================================
C PREDICT
C=======================================================================
            LPREDICTION=(IDSSP .NE. 0)
            IF (LPREDICTION) THEN
               DO I=1,N1 
                  STRMAX=0.0 
                  PREDSTR(I)='-'
                  DO K=1,MAXSTRSTATES
                     IF (STRSUM(K,I) .GT. STRMAX) THEN
                        STRMAX=STRSUM(K,I) 
                        PREDSTR(I)=CSTRSTATES(K:K)
                     ENDIF
                  ENDDO
               ENDDO
               IF (LDSSP_1 ) THEN
                  CALL MARKALI(STRCLASS_1,PREDSTR,N1,PREDSTRCORR,'+')
               ENDIF
            ENDIF
C=======================================================================
C WRITE STRIP file
C=======================================================================
            IF (LSTRIP) THEN	
C header to STRIPFILE
               CALL OPEN_FILE(KSTP,STRIPFILE,'NEW,RECL=10000',lerror)
               WRITE(KSTP,'(A)')
     +               '======================================'//
     +	             '============  MAXHOM-STRIP  =================='//
     +	             '==================================='
               CALL STRPOS(NAME_1,IBEG,IEND)
               WRITE(KSTP,'(A,A)')' test sequence    : ',
     +              name_1(ibeg:iend)
               IF (LISTOFSEQ_2) THEN
                  WRITE(KSTP,'(A,A)')' list name        : ',
     +                 listfile_2(1:50)
               ENDIF
               CALL STRPOS(NAME_2,IBEG,IEND)
               WRITE(kstp,'(a,a)')' last name was    : ',
     +              name_2(ibeg:iend)
               WRITE(kstp,'(a,i6)')' seq_length       : ',n1
               WRITE(kstp,'(a,i6)')' alignments       : ',nalign
               WRITE(kstp,'(a,a)')' sort-mode        : ',csortmode
               WRITE(kstp,'(a,a)')' weights 1        : ',
     +              weight1_answer(1:40)
               WRITE(kstp,'(a,a)')' weights 2        : ',
     +              weight2_answer(1:40)
               WRITE(kstp,'(a,f5.2)')' smin             : ',smin
               WRITE(kstp,'(a,f5.2)')' smax             : ',smax
               WRITE(kstp,'(a,f5.2)')' maplow           : ',maplow
               WRITE(kstp,'(a,f5.2)')' maphigh          : ',maphigh
               WRITE(kstp,'(a,f5.2)')' epsilon          : ',
     +              profile_epsilon
               WRITE(kstp,'(a,f5.2)')' gamma            : ',
     +              profile_gamma
               WRITE(kstp,'(a,a)')' gap_open         : ',
     +              openweight_answer(1:40)
               WRITE(kstp,'(a,a)')' gap_elongation   : ',
     +              elongweight_answer(1:40)
               WRITE(kstp,'(a,a)')' INDEL in sec-struc of SEQ 1: ',
     +              indel_answer_1(1:40)
               WRITE(kstp,'(a,a)')' INDEL in sec-struc of SEQ 2: ',
     +              indel_answer_2(1:40)
               WRITE(kstp,'(a,i4)')' NBEST alignments   : ',nbest
               WRITE(kstp,'(a,a)')' secondary structure alignment: ',
     +              struc_align_answer(1:40)
C list of best alignments to stripfile
               WRITE(kstp,'(a)')
     +               '======================================'//
     +               '============= SUMMARY ========================='//
     +               '=================================='
               WRITE(kstp,'(a)')
     +              ' IAL    VAL   LEN IDEL NDEL  ZSCORE   '//
     +              '%IDEN  STRHOM  LEN2   RMS SIGMA NAME'
               DO IAL=1,MIN(NALIGN,NGLOBALHITS)
                  CALL STRPOS(AL_COMPOUND(IAL),IBEG,IEND)
                  WRITE(KSTP,
     +         '(i4,1x,f7.2,3(1x,i4),3(2x,f6.2),i6,f6.2,f6.3,2(1x,a))')
     +                  IAL,AL_VAL(IAL),AL_HOMLEN(IAL),AL_LGAP(IAL),
     +                  AL_NGAP(IAL),ZSCORE(IAL),AL_HOM(IAL),
     +                  AL_STRHOM(IAL),AL_LSEQ_2(IAL),AL_RMS(IAL),
     +                  AL_SDEV(IAL),AL_EMBLPID(IAL),
     +                  AL_COMPOUND(IAL)(IBEG:IEND)
               ENDDO
c loop over linelen
               IF (LSTRIP_LONG .EQV. .TRUE.) THEN
                  LINELEN=10000
               ELSE
                  LINELEN=50
               ENDIF
               IPOS=1 
               JPOS=MIN(IPOS+LINELEN,N1)
               DO WHILE (IPOS .LE. N1+1)
                  WRITE(KSTP,'(A)')
     +                  '===================================='//
     +	            '============ ALIGNMENTS ========================'//
     +	            '==================================='
                  WRITE(KSTP,*)
C WRITE ruler, sequence, secondary structure ,predicted secondary structure
C and agreement for sequence 1
                  WRITE(KSTP,'(I4,A,I4,15X,A)')IPOS,' -',JPOS,
     +            '....:....1....:....2....:....3....:....4....:....5'
                  WRITE(KSTP,'(6X,A,15X,A)')
     +                 HSSPID_1(1:4),CSQ_1(IPOS:JPOS)
                  DO I=IPOS,JPOS 
                     CTMPCHAR_1(I:I)=STRUC_1(I) 
                  ENDDO
                  WRITE(KSTP,'(25X,A)')CTMPCHAR_1(IPOS:JPOS)
                  IF (LDSSP_1) THEN
                     DO I=IPOS,JPOS
                        IF (CIOSTATES(LACC_1(I):LACC_1(I)).EQ.' ') THEN
                           CTMPCHAR_1(I:I)='u'
                        ELSE
                           WRITE(CTMPCHAR_1(I:I),'(A1)')
     +                          CIOSTATES(LACC_1(I):LACC_1(I))
                        ENDIF
                     ENDDO
                     WRITE(KSTP,'(25X,A)')CTMPCHAR_1(IPOS:JPOS)
                  ENDIF
                  IF (LPREDICTION) THEN
                     DO I=IPOS,JPOS 
                        CTMPCHAR_1(I:I)=PREDSTR(I) 
                     ENDDO
                     WRITE(KSTP,'(25X,A)')CTMPCHAR_1(IPOS:JPOS)
                     DO I=IPOS,JPOS
                        CTMPCHAR_1(I:I)=PREDSTRCORR(I)
                     ENDDO
                     WRITE(KSTP,'(25X,A)')CTMPCHAR_1(IPOS:JPOS)
                  ENDIF
                  WRITE(KSTP,*)
C loop over alignments
                  DO IAL=1,MIN(NALIGN,NGLOBALHITS)
c check if overlap at actual sequence 1 position
                     LCONSIDER=.TRUE.
                     ILAS=AL_IFIRST(IAL) + AL_LEN(IAL)-1
                     IF (ILAS .LT. IPOS .OR. 
     +                    JPOS .LT. AL_IFIRST(IAL) ) THEN
                        LCONSIDER=.FALSE.
                     ENDIF
C     IF OVERLAP AND THRESHOLD OK FILL OUTPUT LINES
                     IF (LCONSIDER) THEN
C     MARK SEQ-IDENTITIES IN EXTRA LINE
                        ISEQPOS=ISEQPOINTER(IAL) 
                        STRIPLINE(1)=' '
                        J=AL_IFIRST(IAL)
                        DO I=1,AL_LEN(IAL)
                           CTEMP=SEQBUFFER(ISEQPOS)
                           AL_2(I:I)=CTEMP 
                           CALL LOWTOUP(CTEMP,1)
                           IF (CSQ_1(J:J) .GE. 'a' .AND.
     +                          CSQ_1(J:J) .LE. 'z') THEN
                              CTEMP2='C'
                           ELSE
                              CTEMP2=CSQ_1(J:J)
                           ENDIF
                           IF (CTEMP2 .EQ. CTEMP) THEN	
                              STRIPLINE(1)(J:J)=CTEMP2
                           ENDIF
                           ISEQPOS=ISEQPOS+1 
                           J=J+1
                        ENDDO
c WRITE alignend sequence and secondary-structure (if known)
                        STRIPLINE(2)=' '
                        WRITE(STRIPLINE(2)(AL_IFIRST(IAL):ILAS),'(A)')
     +                       AL_2(1:AL_LEN(IAL))
                        CALL STRPOS(STRIPLINE(2),I,IEND)
                        J=MIN(IEND,JPOS)
                        WRITE(KSTP,'(25X,A)')STRIPLINE(1)(IPOS:J)
                        WRITE(KSTP,'(I4,A,1X,A10,1X,F7.2,1X,A)')
     +                       IAL,'.',AL_EMBLPID(IAL),AL_VAL(IAL),
     +                       STRIPLINE(2)(IPOS:J)
                        IF (ISTRPOINTER(IAL) .NE. 0) THEN
                           STRIPLINE(3)=' ' 
                           ISTRPOS=ISTRPOINTER(IAL)
                           DO I=1,AL_LEN(IAL)
                              SAL_2(I:I)=STRBUFFER(ISTRPOS)
                              ISTRPOS=ISTRPOS+1
                           ENDDO
                           WRITE(STRIPLINE(3)(AL_IFIRST(IAL):ILAS),
     +                          '(A)')SAL_2(1:AL_LEN(IAL))
                           WRITE(KSTP,'(25X,A)')STRIPLINE(3)(IPOS:J)
                        ENDIF
                        IF (IOPOINTER(IAL) .NE. 0) THEN
                           STRIPLINE(4)=' ' 
                           IOPOS=IOPOINTER(IAL)
                           DO I=AL_IFIRST(IAL),ILAS
                              WRITE(STRIPLINE(4)(I:I),'(A)')
     +                             CIOBUFFER(IOPOS)
                              IOPOS=IOPOS+1
                           ENDDO
                           WRITE(KSTP,'(25X,A)')STRIPLINE(4)(IPOS:J)
                        ENDIF
                     ENDIF
                  ENDDO
c next block
                  IPOS=IPOS+LINELEN 
                  JPOS=MIN(JPOS+LINELEN,N1)
                  WRITE(KSTP,*)
               ENDDO
               WRITE(KSTP,'(A)')
     +	          '=================================================='//
     +	          '=================================================='//
     +	          '==================='
C lstrip
            ENDIF
C=======================================================================
C HSSP-OUTPUT
C=======================================================================
            IF (LHSSP) THEN
               WRITE(6,*)'CALL HSSP'
               CALL HSSP(NALIGN,CHAINREMARK)
               IF ( (L3WAY .EQV. .TRUE.).AND.(L3WAYDONE  .EQV. .FALSE.)
     +              .AND. (LPROFILE_1 .EQV. .FALSE.) ) THEN
                  WEIGHT_MODE='EIGEN'
                  SIGMA=0.0 
                  BETA=1.0
                  CALL PREP_PROFILE(NALIGN,N1,WEIGHT_MODE,SIGMA,BETA)
                  WRITE(6,*)' call scale_profile'
                  CALL SCALE_PROFILE_METRIC(MAXSQ,NTRANS,TRANS,
     +                 SIMMETRIC_1,SMIN,SMAX,MAPLOW,MAPHIGH)
               ENDIF
            ENDIF
 
C WRITE MAXHOM-PROFILE
            IF (LWRITEPROFILE ) THEN
c	    IF (lWRITEprofile .and. (l3waydone .eqv. .true.) ) THEN
               WRITE(6,*)' CALL WRITEPROFILE'
               CALL WRITEPROFILE(KPROF,PROFILEOUT,MAXSQ,N1,NCHAINUSED,
     +              HSSPID_1,HEADER_1,COMPND_1,SOURCE_1,
     +              AUTHOR_1,SMIN,SMAX,MAPLOW,MAPHIGH,
     +              METRICFILE,PDBNO_1,CHAINID_1,CSQ_1_ARRAY,
     +              STRUC_1,NSURF_1,COLS_1,SHEETLABEL_1,BP1_1,
     +              BP2_1,NOCC_1,GAPOPEN_1,GAPELONG_1,
     +              CONSWEIGHT_1,SIMMETRIC_1,MAXBOX,NBOX_1,
     +              PROFILEBOX_1,LDSSP_1)
               CALL CONCAT_STRINGS(HSSPID_1,'.xprism3',tempname)
               CALL OPEN_FILE(KPROF,TEMPNAME,'NEW,RECL=300',LERROR)
               DO I=1,N1
                  WRITE(KPROF,'(20(F8.3))')(SIMMETRIC_1(I,J),J=1,20)
               ENDDO
               CLOSE(KPROF)
               CALL CONCAT_STRINGS(HSSPID_1,'.stf',tempname)
               CALL OPEN_FILE(KPROF,TEMPNAME,'NEW,RECL=300',LERROR)
               WRITE(KPROF,*)'NAME field'
               WRITE(KPROF,*)'RANK 2'
               WRITE(kprof,*)'DIMENSIONS ',n1,' ',20
               WRITE(kprof,*)'BOUNDS ',1,n1,1,20
               WRITE(kprof,*)'SCALAR'
               WRITE(kprof,*)'ORDER ROW'
               WRITE(kprof,*)'DATA'
               DO I=1,N1
                  WRITE(KPROF,'(20(F8.3))')(SIMMETRIC_1(I,J),J=1,20)
               ENDDO
               CLOSE(KPROF)
            ENDIF
c no more, wind up
            WRITE(6,*)' start prediction and strip'
            IF (LPREDICTION .AND. LSTRIP) THEN
c 1. evaluate prediction
               STATFILE='collage-stat.data'
               CALL OPEN_FILE(KSTAT,STATFILE,'UNKNOWN,APPEND',LERROR)
               DO I=1,N1 
                  CTMPCHAR_ARRAY_1(I)=STRCLASS_1(I:I) 
               ENDDO
               CALL EVALPRED(HSSPID_1(1:4),'COLLAGE   ',PREDSTR,
     +              CTMPCHAR_ARRAY_1,N1,LDSSP_1,KSTP,KSTAT)
               CLOSE (KSTAT)
c evaluate alignments
c correlation
               CALL CORRELATION(AL_VAL,AL_STRHOM,NALIGN,CVALSTR)
               CALL CORRELATION(AL_VPERRES,AL_STRHOM,NALIGN,CPERRES)
               WRITE(6,'(a,2f7.3)')'seq/str correlation ',
     +              cvalstr,cperres
               WRITE(kstp,'(a,f7.3)')'CVALSTR - correlation: '//
     +              'seq hom/struc hom: ',cvalstr
               WRITE(kstp,'(a,f7.3)')' CPERRES - correlation: '//
     +              'seq hom per res/struc hom',cperres
C histogram
c$$$	      istep=nint( ( 1.0 / float(maxhist) ) + 0.5 )
c$$$	      do i=1,maxhist ; do j=1,maxhist ;lhist(i,j)=0 ;enddo;enddo
c$$$	      do ial=nalign,1,-1
c$$$                 i=nint(al_vperres(ial)/istep)
c$$$	         j=nint(al_strhom(ial)/istep)
c$$$                 i=min(i,maxhist) ; i=max(i,1) ; j=min(j,maxhist)
c$$$	         j=max(j,1) ; lhist(i,j)=lhist(i,j)+1
c$$$	      enddo
c$$$              WRITE(kstp,*)
c$$$              WRITE(kstp,*)nalign,' events in',
c$$$     +         ' histogram VALPERRES(left/right) vs. AL_STRHOM(up/down)'
c$$$	      ipos=1
c$$$	      do i=1,maxhist
c$$$	         WRITE(ctmpchar_1(ipos:),'(i5)')i ; ipos=ipos+5
c$$$	      enddo
c$$$	      call strpos(ctmpchar_1,i,j)
c$$$              WRITE(kstp,'(5x,a)')ctmpchar_1(:j)
c$$$              do i=maxhist,1,-1
c$$$	         WRITE(ctmpchar_1(1:),'(i5)')i ;ipos=6
c$$$	         do j=1,maxhist
c$$$	           WRITE(ctmpchar_1(ipos:),'(i5)')lhist(j,i)
c$$$	           ipos=ipos+5
c$$$	         enddo
c$$$	         call strpos(ctmpchar_1,ibeg,iend)
c$$$                 WRITE(kstp,'(a)')ctmpchar_1(:iend)
c$$$	      enddo
C prediction
            ENDIF
            IF (LSTRIP) CLOSE(KSTP)
C=======================================================================
C if no alignments WRITE hssp header and process next seq
         ELSE
            CALL CONCAT_STRINGS('*** WARNING: no alignments for: ',
     +           name_1,logstring)
            CALL LOG_FILE(KLOG,LOGSTRING,1)
            CALL OPEN_FILE(KWARN,WARNFILE,'UNKNOWN,APPEND',LERROR)
            CALL LOG_FILE(KWARN,LOGSTRING,0)
            CLOSE(KWARN)
            IF (LHSSP) THEN
               CALL HSSP(NALIGN,CHAINREMARK)
            ENDIF
         ENDIF
C clean up the local binary files
c	  IF (nworkset .eq. 0) THEN
c	    call concat_int_string(nworkset,corefile,coretemp)
c	  endif
c	  WRITE(6,*)' clean up: ',kcore,coretemp
         CALL DEL_OLDFILE(KCORE,CORETEMP)

C=======================================================================
C PARALLEL
C if idproc not host:
C  1.) receive start signal and data from host
C  2.) call the DO_ALIGN routine
C  3.) send results back to host
C=======================================================================
      ELSE IF (LPARALLEL .EQV. .TRUE.) THEN
         CALL NODE_INTERFACE(LH1,LH2)
c	  close(klog)
         CALL MP_LEAVE
         STOP
C end idproc .eq. host
      ENDIF
C=======================================================================
      CALL GET_CPU_TIME('time after output:',idproc,
     +     ITIME_OLD,ITIME_NEW,TOTAL_TIME,LOGSTRING)
      CALL LOG_FILE(KLOG,LOGSTRING,2)
      LAGAIN=.FALSE.
 900  IF ( (L3WAY .EQV. .TRUE.) .AND. (L3WAYDONE .EQV. .FALSE.) ) THEN
         L3WAYDONE=.TRUE.
         NAME_1=PROFILEOUT
         METRICFILE='PROFILE'
         LPROFILE_1=.TRUE.
         LCONSIMPORT=.TRUE. 
         LCONSERV_1=.TRUE. 
         LPASS2=.FALSE.
         SMIN_ANSWER='PROFILE'
         SMAX_ANSWER='PROFILE'
         OPENWEIGHT_ANSWER='PROFILE'
         ELONGWEIGHT_ANSWER='PROFILE'
         LAGAIN=.TRUE.
      ENDIF
      IF (LISTOFSEQ_1 .EQV. .TRUE.) THEN
         CALL DEL_OLDFILE(KCORE,COREFILE)
         WRITE(6,*)'****************************************'
         LOGSTRING='*** START RUN FOR NEXT TEST SEQUENCE ***'
         CALL LOG_FILE(KLOG,LOGSTRING,1)
         WRITE(6,*)'****************************************'
         LAGAIN=.TRUE.
      ENDIF
      IF (LAGAIN .EQV. .TRUE.) GOTO 100
c1000    IF (listofseq_1 .eqv. .true.) THEN
 1000 IF (LPARALLEL .EQV. .TRUE.) THEN
         N1=-999
         CALL SEND_DATA_TO_NODE
      ENDIF
      CLOSE(KLIS1)
c        endif
C=======================================================================
      IF ( IDPROC .EQ. ID_HOST) THEN
         CALL GET_CPU_TIME('time finish:',idproc,
     +        ITIME_OLD,ITIME_NEW,TOTAL_TIME,LOGSTRING)
         CALL LOG_FILE(KLOG,LOGSTRING,2)
 
         CLOSE(KLOG)
         IF (LPARALLEL .EQV. .TRUE.) THEN
            CALL MP_LEAVE
         ENDIF
         WRITE(6,*)'Juuuppdiduu: MAXHOM normal termination'
         STOP
      ENDIF
      END
C     END MAXHOM
C.......................................................................

C.......................................................................
C     SUB acchistogram
C$$$      SUBROUTINE ACCHISTOGRAM(A,B,ASTEP,BSTEP,NA,NB,LHIST,NHIST,MAXHIST)
c$$$C accumulates one doublet A,B into counts LHIST(IA,IB)
c$$$C total number of doublets is NHIST
c$$$C LHIST initialized at first call
c$$$c	implicit none
c$$$	integer maxhist,na,nb,nhist
c$$$	integer lhist(maxhist,maxhist)
c$$$	real a,astep,b,bstep
c$$$
c$$$C internal
c$$$	integer mhist,ia,ib
c$$$	mhist=0
c$$$	IF (na.gt.maxhist) THEN
c$$$	  WRITE(6,*)'*** WARN NA.GT.MAXHIST'
c$$$	  na=maxhist
c$$$	endif
c$$$	IF (nb.gt.maxhist) THEN
c$$$	  WRITE(6,*)'*** WARN NB.GT.MAXHIST'
c$$$	  nb=maxhist
c$$$	endif
c$$$	IF (mhist.eq.0) THEN
c$$$	  do ia=1,na , do ib=1,nb
c$$$	     lhist(ia,ib)=0
c$$$	  enddo, enddo
c$$$	endif
c$$$	mhist=mhist+1 , nhist=mhist
c$$$	ia=nint(a/(astep+0.5)) ; ib=nint(b/(bstep+0.5))
c$$$	IF (ia.gt.na)ia=na ; IF (ia.lt.1)ia=1
c$$$	IF (ib.gt.nb)ib=nb ; IF (ib.lt.1)ib=1
c$$$	lhist(ia,ib)=lhist(ia,ib)+1
c$$$	RETURN
c$$$	END
C     END ACCHISTOGRAM
C.......................................................................

C.......................................................................
C     SUB ADD_SEQ_TO_SEQBUFFER
      SUBROUTINE ADD_SEQ_TO_SEQBUFFER(MAXALIGNS,MAXSEQBUFFER,ADDPOS,
     +     NALIGN,NEWSEQ,NEWSEQSTART,NEWSEQSTOP,NEWSEQNAME,
     +     SEQBUFFER,ISEQPOINTER,AL_IFIRST,AL_ILAST,AL_JFIRST,
     +     AL_JLAST,AL_LEN,AL_NGAP,AL_LGAP,AL_LSEQ_2,
     +     AL_PDB_POINTER,AL_HOM,AL_SIM,AL_EXCLUDEFLAG,ACCESSION,
     +     AL_EMBLPID,AL_COMPOUND)

      IMPLICIT        NONE
C Import
      INTEGER         MAXALIGNS,MAXSEQBUFFER,ADDPOS,
     +                NEWSEQSTART,NEWSEQSTOP
      CHARACTER       NEWSEQ(*),NEWSEQNAME*(*)
C Import / Export
      INTEGER         NALIGN,ISEQPOINTER(MAXALIGNS)
      CHARACTER       SEQBUFFER(MAXSEQBUFFER)
C  attributes of alignend sequences
      INTEGER         AL_IFIRST(MAXALIGNS), AL_ILAST(MAXALIGNS),
     +                AL_JFIRST(MAXALIGNS),AL_JLAST(MAXALIGNS),
     +                AL_LEN(MAXALIGNS),AL_NGAP(MAXALIGNS),
     +                AL_LGAP(MAXALIGNS),AL_LSEQ_2(MAXALIGNS)
      CHARACTER*12    AL_PDB_POINTER(MAXALIGNS)
      CHARACTER*12    ACCESSION(MAXALIGNS)
      CHARACTER*40    AL_EMBLPID(MAXALIGNS)
      CHARACTER*200   AL_COMPOUND(MAXALIGNS)
      CHARACTER       AL_EXCLUDEFLAG(MAXALIGNS)
      REAL            AL_HOM(MAXALIGNS),AL_SIM(MAXALIGNS)
C Export
C Internal
      INTEGER         IALIGN,IPOS,I,LEN,NEWSEQLEN 
*----------------------------------------------------------------------*
      
      NEWSEQLEN = NEWSEQSTOP-NEWSEQSTART+1
      IF ( ADDPOS .GT. NALIGN+1 ) THEN
         WRITE(6,'(A,I4)') ' cannot add after position ', nalign+1 
         RETURN
      ELSE IF ( ADDPOS .EQ. NALIGN+1 ) THEN
         ISEQPOINTER(ADDPOS) = 
     +        ISEQPOINTER(NALIGN) + AL_ILAST(NALIGN) - 
     +        AL_IFIRST(NALIGN)+1
      ELSE IF ( ADDPOS .LE. NALIGN ) THEN
         I= ISEQPOINTER(NALIGN)+AL_ILAST(NALIGN)-AL_IFIRST(NALIGN)+1
         DO IPOS=I,ISEQPOINTER(ADDPOS),-1
            IF ( IPOS+NEWSEQLEN+1 .LE. MAXSEQBUFFER ) THEN
C shift by newseqlen+1, because a '/' is to be inserted after newseq
               SEQBUFFER(IPOS+NEWSEQLEN+1 ) = SEQBUFFER(IPOS)
            ELSE
               STOP 'MAXSEQBUFFER overflow in add_seq_to_seqbuffer !'
            ENDIF
         ENDDO
C insert new member into arrays al_ifirst .. at position addpos 
C  and push following members by one
         DO IALIGN = NALIGN,ADDPOS,-1
            AL_IFIRST(IALIGN+1)=AL_IFIRST(IALIGN)
            AL_ILAST(IALIGN+1)=AL_ILAST(IALIGN)
            AL_JFIRST(IALIGN+1)=AL_JFIRST(IALIGN)
            AL_JLAST(IALIGN+1)=AL_JLAST(IALIGN)
            AL_LEN(IALIGN+1)=AL_LEN(IALIGN)
            AL_NGAP(IALIGN+1)=AL_NGAP(IALIGN)
            AL_LGAP(IALIGN+1)=AL_LGAP(IALIGN)
            AL_LSEQ_2(IALIGN+1)=AL_LSEQ_2(IALIGN)
            AL_PDB_POINTER(IALIGN+1)=AL_PDB_POINTER(IALIGN)
            ACCESSION(IALIGN+1)=ACCESSION(IALIGN)
            AL_EMBLPID(IALIGN+1)=AL_EMBLPID(IALIGN)
            AL_COMPOUND(IALIGN+1)=AL_COMPOUND(IALIGN)
            AL_EXCLUDEFLAG(IALIGN+1)=AL_EXCLUDEFLAG(IALIGN)
            AL_HOM(IALIGN+1)=AL_HOM(IALIGN)
            AL_SIM(IALIGN+1)=AL_SIM(IALIGN)
            ISEQPOINTER(IALIGN+1) = ISEQPOINTER(IALIGN)+NEWSEQLEN+1
         ENDDO
      ENDIF

C insert newseq into seqbuffer
C addpos............last res, '/'
C                            = +1                    
      LEN = NEWSEQSTART
      DO IPOS = ISEQPOINTER(ADDPOS),ISEQPOINTER(ADDPOS)+NEWSEQLEN-1
         SEQBUFFER(IPOS) = NEWSEQ(LEN)
         LEN = LEN + 1
      ENDDO
      SEQBUFFER(IPOS) = '/'   
      AL_IFIRST(ADDPOS)=1
      AL_ILAST(ADDPOS)=NEWSEQLEN
      AL_JFIRST(ADDPOS)=1
      AL_JLAST(ADDPOS)=NEWSEQLEN
      AL_LEN(ADDPOS)=NEWSEQLEN
      AL_NGAP(ADDPOS)=0
      AL_LGAP(ADDPOS)=0
      AL_LSEQ_2(ADDPOS)=NEWSEQLEN
      AL_PDB_POINTER(ADDPOS )= ' '
      ACCESSION(ADDPOS) = ' '
      AL_EMBLPID(ADDPOS)= NEWSEQNAME
      AL_COMPOUND(ADDPOS)= ' '
      AL_EXCLUDEFLAG(ADDPOS)= ' '
      AL_HOM(ADDPOS)=0.0
      AL_SIM(ADDPOS)=0.0

      NALIGN = NALIGN + 1

      RETURN
      END
C     end ADD_SEQ_TO_SEQBUFFER
C.......................................................................

C......................................................................
C     SUB CALC_PROFILE
      SUBROUTINE CALC_PROFILE(MAXSQ,MAXAA,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,
     +     NIOSTATES_2,
     +     SCALE_FACTOR,LOG_BASE,SIGMA,BETA,
     +     NRES,NALIGN,
     +     AL_EXCLUDEFLAG,AL_IFIRST,AL_ILAST,
     +     SEQBUFFER,ISEQPOINTER,NTRANS,TRANS,
     +     SEQ_WEIGHT,OPEN_1,ELONG_1,
     +     GAPOPEN_1,
     +     GAPELONG_1,SIMORG,SIMMETRIC_1) 
      
      INTEGER         NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,NIOSTATES_2
c	common/strstates/ nstrstates_1,niostates_1,nstrstates_2,
c     +                    niostates_2
C import
      INTEGER         MAXSQ,MAXAA,NRES,NALIGN,NTRANS
      REAL            SCALE_FACTOR,LOG_BASE,SIGMA,BETA
      INTEGER         AL_IFIRST(*),AL_ILAST(*),ISEQPOINTER(*)
      CHARACTER       SEQBUFFER(*)
      CHARACTER       TRANS*(*),AL_EXCLUDEFLAG(*)
      REAL            SEQ_WEIGHT(*),OPEN_1,ELONG_1,GAPOPEN_1(*),
     +                GAPELONG_1(*),
     +                SIMORG(NTRANS,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +                        MAXSTRSTATES,MAXIOSTATES)
C export
      REAL            SIMMETRIC_1(MAXSQ,NTRANS)
C internal
      INTEGER         MAXTRANS
      PARAMETER      (MAXTRANS=                 26)
      INTEGER         IRES,IALIGN,I,J
      REAL            FREQUENCY(MAXTRANS),
     +                BTOD,BTON,ZTOE,ZTOQ,XOCC,XINS,XDEL
      CHARACTER       C1
      
      REAL            SIM_COPY(MAXTRANS,MAXTRANS)
      REAL            INV(MAXTRANS,MAXTRANS)
      INTEGER         INDX(MAXTRANS)
      REAL            PROB_I(MAXTRANS)

*----------------------------------------------------------------------*
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
      BTOD=0.524
      BTON=0.445
      ZTOE=0.626
      ZTOQ=0.407
      ILEN=LEN(TRANS)

      WRITE(6,*)'calc_profile'

C check if MAXHOM tries do more than we implemented here :-)
      IF (NTRANS .GT. MAXTRANS) THEN
         WRITE(6,*)' WARNING: NTRANS GT MAXTRANS'
         WRITE(6,*)' update routine: calc_profile !!!'
         STOP
      ENDIF
      IF (NSTRSTATES_1 .GT. 1 .OR. NIOSTATES_1 .GT. 1 .OR.
     +     NSTRSTATES_2 .GT. 1 .OR. NIOSTATES_2 .GT. 1) THEN
         WRITE(6,*)' WARNING: routine calc_profile not'
         WRITE(6,*)' working with STR and/or I/O dependent'
         WRITE(6,*)' metrices, update routine !!!'
         STOP
      ENDIF
C copy "simorg" in "sim_copy" so "simorg" will be unchanged !
      DO I=1,NTRANS 
         DO J=1,NTRANS 
            SIM_COPY(I,J)= SIMORG(I,J,1,1,1,1)
         ENDDO
      ENDDO
C scale metric if necessary
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
         CALL CHECKREALEQUALITY(SUM,1.0,0.002,'sum','calc_profile')
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
c	   WRITE(6,*)'sum P(i,j) | P(j): ',j,sim
         CALL CHECKREALEQUALITY(SIM,1.0,0.002,'sim','calc_profile')
      ENDDO
C     calculate sequence profile
      DO IRES=1,NRES  
         XOCC=0.0 
         XINS=0.0 
         XDEL=0.0
         DO I=1,MAXTRANS 
            FREQUENCY(I)=0.0
         ENDDO
         DO IALIGN=1,NALIGN
            IF (IRES .GE. AL_IFIRST(IALIGN) .AND. 
     +           IRES .LE. AL_ILAST(IALIGN)
     +           .AND. AL_EXCLUDEFLAG(IALIGN) .EQ. ' ') THEN
               C1=SEQBUFFER( ISEQPOINTER(IALIGN) + 
     +              IRES-AL_IFIRST(IALIGN) )
C if lower case character: insertions
               IF (C1 .GE. 'a' .AND. C1 .LE. 'z') THEN
                  C1=CHAR( ICHAR(C1)-32 )
                  XINS=XINS + SEQ_WEIGHT(IALIGN)
               ENDIF
               IF (C1 .NE. '.') THEN
                  XOCC=XOCC + SEQ_WEIGHT(IALIGN)
                  IF (INDEX('BZ',C1).EQ.0) THEN
                     I=INDEX(TRANS,C1)
                     IF (I .LE. 0 .OR. I .GT. ILEN) THEN
                        WRITE(6,*)' GETFREQUENCY: UNKNOWN RES : ',C1
                     ELSE
                        FREQUENCY(I)=FREQUENCY(I) + SEQ_WEIGHT(IALIGN)
                     ENDIF
                  ELSE IF (C1 .EQ. 'B') THEN
                     WRITE(6,*)' GETFREQUENCY: convert B'
                     I=INDEX(TRANS,'D')
                     J=INDEX(TRANS,'N')
                     FREQUENCY(I)=FREQUENCY(I)+(BTOD*SEQ_WEIGHT(IALIGN))
                     FREQUENCY(J)=FREQUENCY(J)+(BTON*SEQ_WEIGHT(IALIGN))
                  ELSE IF (C1 .EQ. 'Z') THEN
                     WRITE(6,*)' GETFREQUENCY: convert Z'
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
               SIMMETRIC_1(IRES,I)=( (1-SMOOTH) * SIM) + 
     +              (SMOOTH * FREQUENCY(I) )
C divide by the expected probability
               SIMMETRIC_1(IRES,I)=SIMMETRIC_1(IRES,I)/PROB_I(I)
c	        simmetric_1(ires,i)= frequency(i) /prob_i(i)
C log-odd
               IF (SIMMETRIC_1(IRES,I) .LE. 10E-3) THEN
                  SIMMETRIC_1(IRES,I)=10E-3
               ENDIF
               SIMMETRIC_1(IRES,I)=LOG10 ( SIMMETRIC_1(IRES,I) )



c	        WRITE(6,*)ires,trans(i:i),sum,frequency(i),
c     +                    sim,smooth,simmetric_1(ires,i)
C gap-weights 
               GAPOPEN_1(IRES) =OPEN_1  / (1.0 + ((XINS+XDEL)/SUM)) 
               GAPELONG_1(IRES)=ELONG_1 / (1.0 + ((XINS+XDEL)/SUM)) 
            ENDDO
         ELSE
            WRITE(6,*)'CALC_PROFILE: position not occupied !'
            C1=SEQBUFFER( ISEQPOINTER(1)+IRES-AL_IFIRST(1) )
            WRITE(6,*)'  sequence symbol of first sequence: ',c1
            WRITE(6,*)'  set profile row to 0.0'
            DO I=1,MAXAA 
               SIMMETRIC_1(IRES,I)=0.0 
            ENDDO
            GAPOPEN_1(IRES) = 0.0 
            GAPELONG_1(IRES)= 0.0
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
         SIMMETRIC_1(IRES,IX)=0.0
         SIMMETRIC_1(IRES,IB)=0.0
         SIMMETRIC_1(IRES,IZ)=0.0
         SIMMETRIC_1(IRES,I1)=0.0
         SIMMETRIC_1(IRES,I2)=0.0
      ENDDO

      RETURN
      END
C     END CALC_PROFILE
C......................................................................

C......................................................................
C     SUB COPY_FIELD
      SUBROUTINE COPY_FIELD(CIN,COUT,IFIELD,MAXFIELD)

C      IMPLICIT        NONE

C---- local parameters 
      INTEGER         MAXFIELDLOC,MAXFIELDLENLOC
      PARAMETER      (MAXFIELDLOC=              15)
      PARAMETER      (MAXFIELDLENLOC=          200)  
C---- import
      CHARACTER*(MAXFIELDLENLOC)    
     +                 CIN(MAXFIELDLOC)
      CHARACTER*200    COUT
      INTEGER          IFIELD,MAXFIELD
C internal
C---- local variables
      INTEGER          IBEG,IEND
*----------------------------------------------------------------------*

      IF (IFIELD+1 .GT. MAXFIELD) THEN
         CALL STRPOS(CIN(IFIELD),IBEG,IEND)
         WRITE(6,*)'**** NO VALUE GIVEN FOR: ',CIN(IFIELD)(IBEG:IEND)
      ELSE
         CALL STRPOS(CIN(IFIELD+1),IBEG,IEND)
         IF (IEND .GE. 1) THEN
            COUT=CIN(IFIELD+1)(IBEG:IEND)
	    IFIELD=IFIELD+2
         ENDIF
      ENDIF
      RETURN
      END
C     END COPY_FIELD
C......................................................................

C......................................................................
C     SUB CORRELATION
      SUBROUTINE CORRELATION(SET1,SET2,NSIZE,RCORR)
C classical correlation between sets of values set1(1..nsize) and 
C set2(1..nsize)
C import
c	implicit none
      REAL SET1(*),SET2(*)
      INTEGER NSIZE
C export
      REAL RCORR
C internal
      REAL SET1SUM,SET2SUM,SET1AVRG,SET2AVRG,TOTALSUM
      INTEGER J

      IF (NSIZE .LT. 1) THEN
         WRITE(6,*)'*** CORRELATION: nsize=0 ' 
         RETURN
      ENDIF
      SET1SUM=0.0
      SET2SUM=0.0
      DO J=1,NSIZE
         SET1SUM = SET1SUM + SET1(J) 
         SET2SUM = SET2SUM + SET2(J)
      ENDDO
      SET1AVRG=SET1SUM/NSIZE 
      SET2AVRG=SET2SUM/NSIZE
      SET1SUM=0.0 
      SET2SUM=0.0 
      TOTALSUM=0.0
cdebug
c	WRITE(6,*) 'set1avrg,set2avrg', set1avrg,set2avrg
      DO J=1,NSIZE
         TOTALSUM = TOTALSUM + (SET1(J) -SET1AVRG)*(SET2(J)-SET2AVRG)
         SET1SUM  = SET1SUM  + (SET1(J) -SET1AVRG)**2
         SET2SUM  = SET2SUM  + (SET2(J) -SET2AVRG)**2
      ENDDO
      IF ( SET1SUM * SET2SUM .NE. 0.0) THEN
         RCORR=TOTALSUM / SQRT(SET1SUM * SET2SUM)
      ELSE
         RCORR=99.9 
         WRITE(6,*)'*** CORRELATION: sum = 0.0 '
      ENDIF
      RETURN
      END
C     END CORRELATION
C......................................................................

C......................................................................
C     SUB GETALIGN_FROM_WORKER
      SUBROUTINE GETALIGN_FROM_WORKER(IWORKER,IMSGTAG,IFIR,LEN1,
     +     LENOCC,JFIR,JLAS,IDEL,NDEL,
     +     VALUE,RMS,HOM,SIM,SDEV,DISTANCE) 
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
c input
      INTEGER IWORKER,IMSGTAG
c output
      INTEGER   IFIR,JFIR,JLAS,IDEL,NDEL,LEN1,LENOCC
      REAL      VALUE,SIM,SDEV,HOM,RMS,DISTANCE
C internal
      INTEGER ISIZE
      INTEGER ILCONSIDER,ILDSSP_2
C init
      ILCONSIDER=0 
      ILDSSP_2=0
      LCONSIDER=.FALSE. 
      LDSSP_2=.FALSE.
C receive data
      MSGTYPE=IMSGTAG
      CALL MP_RECEIVE_DATA(MSGTYPE,LINK(IWORKER))

      CALL MP_GET_INT4(MSGTYPE,IWORKER,ILCONSIDER,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,ILDSSP_2,N_ONE)
      ISIZE=LEN(NAME_2)
      CALL MP_GET_STRING(MSGTYPE,IWORKER,NAME_2,ISIZE)
      ISIZE=LEN(COMPND_2)
      CALL MP_GET_STRING(MSGTYPE,IWORKER,COMPND_2,ISIZE)
      ISIZE=LEN(ACCESSION_2)
      CALL MP_GET_STRING(MSGTYPE,IWORKER,ACCESSION_2,ISIZE)
      ISIZE=LEN(PDBREF_2)
      CALL MP_GET_STRING(MSGTYPE,IWORKER,PDBREF_2,ISIZE)
      
      CALL MP_GET_REAL4(MSGTYPE,IWORKER,VALUE,N_ONE)
      
      CALL MP_GET_INT4(MSGTYPE,IWORKER,IFIR,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,LEN1,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,LENOCC,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,JFIR,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,JLAS,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,N2IN,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,IDEL,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,NDEL,N_ONE)
      CALL MP_GET_INT4(MSGTYPE,IWORKER,NSHIFTED,N_ONE)
      
      CALL MP_GET_REAL4(MSGTYPE,IWORKER,RMS,N_ONE)
      CALL MP_GET_REAL4(MSGTYPE,IWORKER,HOM,N_ONE)
      CALL MP_GET_REAL4(MSGTYPE,IWORKER,SIM,N_ONE)
      CALL MP_GET_REAL4(MSGTYPE,IWORKER,SDEV,N_ONE)
      CALL MP_GET_REAL4(MSGTYPE,IWORKER,DISTANCE,N_ONE)

      ISIZE=LEN(AL_2)
      CALL MP_GET_STRING(MSGTYPE,IWORKER,AL_2,ISIZE)
      ISIZE=LEN(SAL_2)
      CALL MP_GET_STRING(MSGTYPE,IWORKER,SAL_2,ISIZE)
      
      CALL MP_GET_INT4(MSGTYPE,IWORKER,IINS,N_ONE)
      IF (IINS .GT. 0) THEN
         CALL MP_GET_INT4_ARRAY(MSGTYPE,IWORKER,INSLEN_LOCAL,IINS)
         CALL MP_GET_INT4_ARRAY(MSGTYPE,IWORKER,INSBEG_1_LOCAL,IINS)
         CALL MP_GET_INT4_ARRAY(MSGTYPE,IWORKER,INSBEG_2_LOCAL,IINS)
         ISIZE=LEN(INSSEQ)
         CALL MP_GET_STRING(MSGTYPE,IWORKER,INSSEQ,ISIZE)
      ENDIF   
      IF ( ILCONSIDER .EQ. 1) LCONSIDER=.TRUE.
      IF ( ILDSSP_2 .EQ. 1 ) LDSSP_2=.TRUE.


      RETURN
      END
C     END GETALIGN_FROM_WORKER
C......................................................................

C.......................................................................
C SUB GETSTRHOM
C	SUBROUTINE GETSTRHOM(S1,S2,N,HOM)
c	implicit none
c
c	integer n
c	real    hom
c	character*(*) s1,s2
C internal
c	character*1 temp1,temp2
c	integer iagr,i
c	
c	IF (n .eq. 0) THEN
c	  WRITE(6,*)'*** N=0 IN GETSTRHOM'
c	  RETURN
c	endif
c	iagr=0
c	do i=1,n 
c	   temp1=s1(i:i) , call lowtoup(temp1,1) 
c	   temp2=s2(i:i) , call lowtoup(temp2,1)
c           IF (temp1 .eq. temp2) THEN , iagr=iagr+1,  endif
c	enddo
c	hom=float(iagr)/float(n)
c	
c	RETURN , END
C     END GETSTRHOM
C.......................................................................

C.......................................................................
C     SUB HELP_TEXT
      SUBROUTINE HELP_TEXT

      WRITE(6,*)' ****** YOU WILL NEVER GET THIS ... *****'

      RETURN
      END
C     END HELP_TEXT
C.......................................................................

C......................................................................
C     SUB HSSP
      SUBROUTINE HSSP(NALIGN,CHAINREMARK)
C---- 
C---- WRITE  *.HSSP files using alignment-data      RS 1988/89
C---- 
      IMPLICIT        NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
C---- import
      INTEGER         NALIGN,
     +                NPARALINE,NRES,LRES,NENTRIES,NRESIDUE,
     +                I,J,ISTART,ISTOP
      CHARACTER*(*)   CHAINREMARK
C---- internal
      CHARACTER       CTEMP*200,HSSPFILE*200,CDATE*9
      CHARACTER*200   HSSPLINE,DATABASE,CPARAMETER(10)
c	character*1    csq_1_array(maxsq)
      REAL            RMIN,RMAX,RELEASE
C---- added br 99.01
      INTEGER         NALIGN_FILTER
      REAL            DISTANCE
C---- ------------------------------------------------------------------
C---- initialize
C---- ------------------------------------------------------------------
      DO I=1,NALIGN 
         AL_EXCLUDEFLAG(I)=' '
      ENDDO
      DO J=1,MAXSQ
         DO I=1,MAXPROFAA 
            AL_SEQPROF(J,I)=0
         ENDDO
      ENDDO
      DO J=1,MAXSQ
         AL_VARIABILITY(J)=0 
         AL_ENTROPY(J)=0
         NOCC_1(J)=0 
         AL_NDELETION(J)=0 
         AL_NINS(J)=0
      ENDDO
C---- 
C---- WRITE info into string
C---- 
C     HSSP release note
      WRITE(HSSPLINE,'(A)')'HSSP       HOMOLOGY DERIVED SECONDARY'//
     +     ' STRUCTURE OF PROTEINS , VERSION 1.0 1991'
C     get swissprot release
      CALL SWISSPROTRELEASE(KREL,RELNOTES,RELEASE,NENTRIES,NRESIDUE)
      WRITE(DATABASE,'(A,F4.1,A,I6,A)')'SEQBASE    RELEASE ',RELEASE,
     +     ' OF EMBL/SWISS-PROT WITH ',NENTRIES,' SEQUENCES'
c     get actual date
      CDATE=' '
      CALL GETDATE (CDATE)
C     get GCG-metric file and scale between 0.0 and 1.0
      RMIN=0.0 
      RMAX=1.0
      CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,
     +     NIOSTATES_2,CSTRSTATES,CIOSTATES,
     +     IORANGE,KSIM,METRIC_HSSP_VAR,SIMORG)
      IF (NSTRSTATES_1 .NE. 1 .OR. NIOSTATES_1 .NE. 1) THEN
         WRITE(6,*)'**** ERROR: NSTRSTATES_1 OR NIOSTATES_1 .GT. 1'
         WRITE(6,*)'CHANGE CALC_VAR ROUTINE'
      ENDIF
      CALL SCALEMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     SIMORG,RMIN,RMAX,0.0,0.0)
C     WRITE alignment parameter in CPARAMETER (passed to HSSPHEADER)
      NPARALINE=1
      WRITE(CPARAMETER(NPARALINE),'(A,F4.1,A,F4.1)')
     +     ' SMIN: ',SMIN,'  SMAX: ',SMAX
      NPARALINE=NPARALINE+1
	
      IF (OPENWEIGHT_ANSWER .EQ. 'PROFILE' ) THEN
         WRITE(CPARAMETER(NPARALINE),'(A,A)')
     +        ' gap-open: profile',' gap-elongation: profile'
      ELSE
         WRITE(CPARAMETER(NPARALINE),'(A,F4.1,A,F4.1)')
     +    ' gap-open: ',gapopen_1(1),' gap-elongation: ',gapelong_1(1)
      ENDIF
      IF (LPROFILE_1 .OR. LPROFILE_2 .OR. LPROF_SSSA_1) THEN
         NPARALINE=NPARALINE+1
         WRITE(CPARAMETER(NPARALINE),'(A,A)')
     +	      '  profile from : ',name_1(1:100)
      ENDIF
      NPARALINE=NPARALINE+1
      IF (LCONSERV_1 .OR. LCONSERV_2 .OR. LCONSIMPORT) THEN
         WRITE(CPARAMETER(NPARALINE),'(A)')
     +        '  conservation weights: YES'
      ELSE
         WRITE(CPARAMETER(NPARALINE),'(A)')
     +        '  conservation weights: NO'
      ENDIF
      NPARALINE=NPARALINE+1
      IF (LINSERT_1) THEN
         WRITE(CPARAMETER(NPARALINE),'(A)')
     +        'InDels in secondary structure allowed: YES'  
      ELSE
         WRITE(CPARAMETER(NPARALINE),'(A)')
     +        'InDels in secondary structure allowed: NO'
      ENDIF
      NPARALINE=NPARALINE+1
      CALL CONCAT_STRINGS('  alignments sorted according to : ',
     +     CSORTMODE,CPARAMETER(NPARALINE) )
        
      IF (LHSSP_LONG_ID .EQV. .TRUE.) THEN
         NPARALINE=NPARALINE+1
         CALL CONCAT_STRINGS('  LONG-ID : ',
     +        HSSP_FORMAT_ANSWER,CPARAMETER(NPARALINE) )
      ENDIF

      IF (HSSP_ANSWER .EQ. 'YES') THEN
         CALL CONCAT_STRINGS(HSSPID_1,'.hssp',HSSPFILE)
      ELSE
         HSSPFILE=HSSP_ANSWER
      ENDIF
      BRKID_1=HSSPID_1(1:4)
C
      IF (.NOT. LDSSP_1 ) THEN
         NRES=N1 
         LRES=N1
	 HEADER_1=NAME_1(1:40)
	 COMPND_1=' ' 
         SOURCE_1=' ' 
         AUTHOR_1=' '
      ELSE
	 NRES=N1 
         LRES=NRES-NCHAINUSED+1
      ENDIF

      DO I=1,N1 
         CSQ_1_ARRAY(I)=CSQ_1(I:I) 
      ENDDO
      CALL CALC_VAR(NALIGN,NRES,CSQ_1_ARRAY,AL_HOM,
     +     AL_IFIRST,AL_ILAST,ISEQPOINTER,
     +     SEQBUFFER,AL_EXCLUDEFLAG,MAXSTRSTATES,MAXIOSTATES,
     +     NTRANS,TRANS,SIMORG,AL_VARIABILITY)
      CALL CALC_PROF(MAXSQ,MAXPROFAA,NRES,CSQ_1_ARRAY,NALIGN,
     +     AL_EXCLUDEFLAG,AL_HOM,AL_IFIRST,
     +     AL_ILAST,SEQBUFFER,ISEQPOINTER,TRANS,AL_SEQPROF,
     +     NOCC_1,AL_NDELETION,AL_NINS,AL_ENTROPY,AL_RELENT)
      
      IF (CHAINREMARK .NE. ' ') THEN
         CTEMP=' '
         I=INDEX(CHAINREMARK,'!')
         IF (I .NE. 0) THEN	
            WRITE(CTEMP,'(A)')CHAINREMARK(I+2:)
         ENDIF
         CHAINREMARK=' '
         CALL STRPOS(CTEMP,ISTART,ISTOP)
         WRITE(CHAINREMARK,'(A)')CTEMP(1:ISTOP)
      ENDIF
C---- 
C---- finally WRITE to file (HSSPFILE)
C---- 

C---- get number of alignments above threshold (new br 99.01)
      NALIGN_FILTER=0
      DO I=1,NALIGN
         CALL CHECKHSSPCUT(AL_HOMLEN(I),AL_HOM(I)*100,
     +        ISOLEN,ISOIDE,NSTEP,LFORMULA,LALL,ISAFE,
     +        LCONSIDER,DISTANCE)
         IF ( LCONSIDER ) THEN
            IF ( AL_EXCLUDEFLAG(I) .EQ. ' ') THEN
	       NALIGN_FILTER=NALIGN_FILTER+1
            ENDIF
         ELSE
            AL_EXCLUDEFLAG(I)='*'
         ENDIF
      ENDDO

C---- WRITE header (no table)
      CALL HSSPHEADER(KHSSP,HSSPFILE,HSSPLINE,HSSPID_1,CDATE,DATABASE,
     +     CPARAMETER,NPARALINE,ISOSIGFILE,ISAFE,LFORMULA,
     +     HEADER_1,COMPND_1,SOURCE_1,AUTHOR_1,LRES,
     +     NCHAIN_1,NCHAINUSED,CHAINREMARK,NALIGN_FILTER)

C---- WRITE data (table header and alignments)
      CALL WRITE_HSSP(KHSSP,MAXSQ,NALIGN,NGLOBALHITS,NRES,AL_EMBLPID,
     +     AL_PDB_POINTER,AL_ACCESSION,AL_HOM,AL_SIM,
     +     AL_IFIRST,AL_ILAST,AL_JFIRST,AL_JLAST,AL_HOMLEN,
     +     AL_NGAP,AL_LGAP,AL_LSEQ_2,AL_COMPOUND,
     +     ISEQPOINTER,SEQBUFFER,PDBNO_1,CHAINID_1,
     +     CSQ_1_ARRAY,STRUC_1,COLS_1,BP1_1,BP2_1,
     +     SHEETLABEL_1,NSURF_1,NOCC_1,AL_VARIABILITY,
     +     AL_SEQPROF,AL_NDELETION,AL_NINS,AL_ENTROPY,
     +     AL_RELENT,CONSWEIGHT_1,INSNUMBER,INSALI,
     +     INSPOINTER,INSLEN,INSBEG_1,INSBEG_2,INSBUFFER,
     +     ISOLEN,ISOIDE,NSTEP,LFORMULA,LALL,ISAFE,
     +     AL_EXCLUDEFLAG,LCONSERV_1,LHSSP_LONG_ID)
      RETURN
      END
C     END HSSP
C......................................................................

C......................................................................
C     SUB INTERFACE
      SUBROUTINE INTERFACE
C MAXFIELD   = number of fields in line
C MAXFIELDLEN = length of field in bytes

C---- include parameter files
      INCLUDE         'maxhom.param'
      INCLUDE         'maxhom.common'

C---- local parameters 
      INTEGER         MAXFIELD,MAXFIELDLEN
      PARAMETER      (MAXFIELD=                 15)
      PARAMETER      (MAXFIELDLEN=             200)  
c output
      CHARACTER*(MAXFIELDLEN) 
     +                MACROLINE,CFIELD(MAXFIELD), 
     +                CSTRING(MAXFIELD),CALFANUMERIC(MAXFIELD),
     +                CALFAMIXED(MAXFIELD),CWORD(MAXFIELD) 
      INTEGER         NFIELD,NSTRING,NALFANUMERIC,NNUMBER,NREAL,
     +                NINTEGER,NPOSITIVE,NNEGATIVE,NWORD,NALFAMIXED
     +                IINTEGER(MAXFIELD),IPOSITIVE(MAXFIELD),
     +                INEGATIVE(MAXFIELD)
      REAL            XNUMBER(MAXFIELD), XREAL(MAXFIELD)
c pointers to beg and end of each field
      INTEGER         IFIELD_POS(2,MAXFIELD)
c	common/interpret1/ macroline, cfield, cstring, calfanumeric,
c     +                     calfamixed,cword
c	common/interpret2/ nfield, nstring, nalfanumeric,nnumber,nreal, 
c     +                     ninteger, npositive, nnegative, nword,
c     +                     nalfamixed, iinteger,ipositive, inegative,
c     +                     ifield_pos
c	common/interpret3/ xnumber, xreal

C internal
      INTEGER         ID,ILEN,IBEG,IEND
      CHARACTER*500   INPUTLINE
      CHARACTER*20    KEYWORD
      INTEGER         IUNIT
      LOGICAL         LEXIST,LERROR
      CHARACTER*500   TEMP_FILE
C KEYWORDS are:  
C COMmandfile
C BATCH
C PID:
C SEQuence1
C SEQuence2
C PROFile
C NORM_profile
C METric
C conservation-WEIGht1
C sonservation-WEIGht2
C WAY3align
C INDEL in secstruc
C STRUC_align
C RELIABILITY
C FILTer_range
C THREShold
C SORTmode
C SUPERpos
C HSSP_output
C OUT_FORMAT_HSSP
C SAME_SEQ
C PDB_path
C PROFile_OUTput
C LONG_OUTput
C STRIP_output
C DOT_plot_output
C SMIN
C SMAX
C gapOPEN
C gapELONG
C MAXalign
      IUNIT=99
      CURRENT_DIR='.'
      CALL GET_CURRENT_DIR(CURRENT_DIR)
      
      LBATCH=.FALSE.
      LDIALOG=.FALSE.
      LRUN=.FALSE.
      
      WRITE(6,*)' '
      WRITE(6,*)'============================ MAXHOM DIALOG ======='//
     +     '==================='

      WRITE(6,*)' HELP            : get short help text '
      WRITE(6,*)' DIALOG          : answer questions step by step '
      WRITE(6,*)' STATUS          : show current settings '
      WRITE(6,*)' RUN/START/GO    : start program '
      WRITE(6,*)' QUIT            : stop the program '
      WRITE(6,*)' "KEYWORD VALUE" : set options '

      LEXIST=.FALSE.
      TEMP_FILE='maxhom.input'
      INQUIRE(FILE=TEMP_FILE,EXIST=LEXIST)
      IF (LEXIST .EQV. .TRUE.) THEN
         CALL OPEN_FILE(IUNIT,TEMP_FILE,'old',LERROR)
         WRITE(6,*)' ========================================='
         WRITE(6,*)' INFO: found local input file; will use it'
         WRITE(6,*)' ========================================='
      ENDIF

      KEYWORD=' ' 
      NFIELD=1
      DO WHILE (KEYWORD .NE. 'RUN' .OR. KEYWORD .NE. 'DIALOG'
     +     .OR. KEYWORD .NE. 'GO' .OR. KEYWORD .NE. 'START') 
         IF (.NOT. LBATCH) THEN
            WRITE(6,*)' '
            WRITE(6,*)'=== option: HELP, DIALOG, STATUS, RUN '//
     +           'or "KEYWORD + value" === >'
         ENDIF
         INPUTLINE=' ' 
         ID=1
         IF (LEXIST .EQV. .TRUE.) THEN
            READ(IUNIT,'(A)')INPUTLINE 
         ELSE
            READ(*,'(A)')INPUTLINE 
         ENDIF
         IF (INPUTLINE .EQ. ' ') THEN
            CFIELD(ID)='STATUS' 
            NFIELD=1
         ELSE
            CALL INTERPRET_LINE(INPUTLINE,MAXFIELD,
     +           MACROLINE, CFIELD, CSTRING, CALFANUMERIC,
     +           CALFAMIXED,CWORD,NFIELD,NSTRING,NALFANUMERIC,
     +           NNUMBER, NREAL, NINTEGER,NPOSITIVE, NNEGATIVE, 
     +           NWORD, NALFAMIXED,IINTEGER,IPOSITIVE,
     +           INEGATIVE,XNUMBER, XREAL,IFIELD_POS)
         ENDIF
         DO WHILE(ID .LE. NFIELD)
            IF (MACROLINE(ID:ID) .NE. 'R' .AND.
     +           MACROLINE(ID:ID) .NE. 'P' .AND.
     +           MACROLINE(ID:ID) .NE. 'N') THEN
               ILEN=LEN(CFIELD(ID))
               CALL LOWTOUP(CFIELD(ID),ILEN)
               CALL STRPOS(CFIELD(ID),IBEG,IEND)
               IF (CFIELD(ID)(IBEG:IEND) .EQ. 'RUN' .OR.
     +              CFIELD(ID)(IBEG:IEND) .EQ. 'GO' .OR. 
     +              CFIELD(ID)(IBEG:IEND) .EQ. 'START') THEN
                  LRUN=.TRUE. 
                  RETURN
               ELSE IF (CFIELD(ID)(IBEG:IEND) .EQ. 'DIALOG') THEN
	          LDIALOG=.TRUE. 
                  RETURN
               ELSE IF (CFIELD(ID)(IBEG:IEND) .EQ.'HELP') THEN
	          CALL HELP_TEXT 
               ELSE IF (CFIELD(ID)(IBEG:IEND) .EQ.'QUIT') THEN
	          STOP 
               ELSE IF (INDEX(CFIELD(ID),'COM').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,COMMANDFILE_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'BATCH').NE.0) THEN
                  LBATCH=.TRUE.
               ELSE IF (INDEX(CFIELD(ID),'PID:').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,JOB_ID,ID,NFIELD)
c                  CALL STRPOS(COREFILE,IBEG,IEND)
c                  CALL STRPOS(JOB_ID,ISTART,ISTOP)
c	          COREFILE(1:)=COREFILE(IBEG:IEND)//
c     +                         JOB_ID(ISTART:ISTOP)
               ELSE IF (INDEX(CFIELD(ID),'SEQ').NE.0 .AND.
     +                 INDEX(CFIELD(ID),'1').NE.0 ) THEN
	          CALL COPY_FIELD(CFIELD,NAME1_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'SEQ').NE.0 .AND.
     +                 INDEX(CFIELD(ID),'2').NE.0 ) THEN
	          CALL COPY_FIELD(CFIELD,NAME2_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'MET').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,METRIC_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'WEIG').NE.0 .AND.
     +                 INDEX(CFIELD(ID),'1').NE.0 ) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,WEIGHT1_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'WEIG').NE.0 .AND.
     +                 INDEX(CFIELD(ID),'2').NE.0 ) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,WEIGHT2_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'INDEL_1').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,INDEL_ANSWER_1,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'INDEL_2').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,INDEL_ANSWER_2,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'WAY3').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,WAY3_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'SAME').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,SAMESEQ_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'THRES').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,THRESHOLD_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'NORM').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,NORM_PROFILE_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'MEAN').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,PROFILE_EPSILON_ANSWER,ID,
     +                 NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'FACTOR').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,PROFILE_GAMMA_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'SORT').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,SORTMODE_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'OUT_FORMAT_HSSP').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,HSSP_FORMAT_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'HSSP ').NE.0) THEN
c	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,HSSP_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'SUPER').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,COMPARE_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'STRUC').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,STRUC_ALIGN_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'PDB').NE.0 .OR.
     +                 INDEX(CFIELD(ID),'BRK').NE.0 ) THEN
	          CALL COPY_FIELD(CFIELD,PDBPATH_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'DSSP') .NE.0 ) THEN
	          CALL COPY_FIELD(CFIELD,DSSP_PATH,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'PROF') .NE.0 .AND.
     +                 INDEX(CFIELD(ID),'OUT')  .NE.0 ) THEN
	          CALL COPY_FIELD(CFIELD,PROFILEOUT_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'PROF').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,PROFILE_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'STRIP').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,STRIPFILE_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'LONG_OUT').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,LONG_OUTPUT_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'DOT').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,PLOTFILE_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'SMIN').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,SMIN_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'SMAX').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,SMAX_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'OPEN').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,OPENWEIGHT_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'ELONG').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,ELONGWEIGHT_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'NBEST').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,NBEST_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'MAX').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,NGLOBALHITS_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'RELI').NE.0) THEN
	          CALL LOWTOUP(CFIELD(ID+1),ILEN)
	          CALL COPY_FIELD(CFIELD,BACKWARD_ANSWER,ID,NFIELD)
               ELSE IF (INDEX(CFIELD(ID),'FILT').NE.0) THEN
	          CALL COPY_FIELD(CFIELD,FILTER_ANSWER,ID,NFIELD)
               ELSE IF (CFIELD(ID) .EQ. 'STATUS') THEN
	          CALL STRPOS(COMMANDFILE_ANSWER,IBEG,IEND)
	          WRITE(6,*)' COMMANDFILE        : ',
     +                 COMMANDFILE_ANSWER(IBEG:IEND),' [YES/NO]'
	          CALL STRPOS(NAME1_ANSWER,IBEG,IEND)
	          WRITE(6,*)' SEQUENCE_1         : ',
     +                 NAME1_ANSWER(IBEG:IEND),
     +                 ' [filename or list of filenames]' 
	          CALL STRPOS(NAME2_ANSWER,IBEG,IEND)
	          WRITE(6,*)' SEQUENCE_2         : ',
     +                 NAME2_ANSWER(IBEG:IEND), 
     +                 ' [filename or list of filenames]' 
	          CALL STRPOS(METRIC_ANSWER,IBEG,IEND)
                  WRITE(6,*)' METRIC             : ',
     +                 METRIC_ANSWER(IBEG:IEND),' [LACHLAN/GCG/filena]' 
	          CALL STRPOS(SMIN_ANSWER,IBEG,IEND)
                  WRITE(6,*)' SMIN               : ',
     +                 SMIN_ANSWER(IBEG:IEND),
     +                 ' [real number/0.0/PROFILE]'  
	          CALL STRPOS(SMAX_ANSWER,IBEG,IEND)
                  WRITE(6,*)' SMAX               : ',
     +                 SMAX_ANSWER(IBEG:IEND),
     +                 ' [real number/0.0/PROFILE]'  
	          CALL STRPOS(OPENWEIGHT_ANSWER,IBEG,IEND)
                  WRITE(6,*)' GAP_OPEN           : ',
     +                 OPENWEIGHT_ANSWER(IBEG:IEND), 
     +                 ' [real number/PROFILE]'  
	          CALL STRPOS(ELONGWEIGHT_ANSWER,IBEG,IEND)
                  WRITE(6,*)' GAP_ELONGATION     : ',
     +                 ELONGWEIGHT_ANSWER(IBEG:IEND), 
     +                 ' [real number/PROFILE]'  
	          CALL STRPOS(WEIGHT1_ANSWER,IBEG,IEND)
                  WRITE(6,*)' WEIGHT_1           : ',
     +                 WEIGHT1_ANSWER(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(WEIGHT2_ANSWER,IBEG,IEND)
                  WRITE(6,*)' WEIGHT_2           : ',
     +                 WEIGHT2_ANSWER(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(NORM_PROFILE_ANSWER,IBEG,IEND)
                  WRITE(6,*)' NORMALIZE PROFILE  : ',
     +                 NORM_PROFILE_ANSWER(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(PROFILE_EPSILON_ANSWER,IBEG,IEND)
                  WRITE(6,*)' MEAN PROFILE       : ',
     +               PROFILE_EPSILON_ANSWER(IBEG:IEND),' [real number]' 
	          CALL STRPOS(PROFILE_GAMMA_ANSWER,IBEG,IEND)
                  WRITE(6,*)' FACTOR GAP-WEIGHTS : ',
     +               PROFILE_GAMMA_ANSWER(IBEG:IEND),' [real number]' 
	          CALL STRPOS(BACKWARD_ANSWER,IBEG,IEND)
                  WRITE(6,*)' RELIABILITY SCORE  : ',
     +                 BACKWARD_ANSWER(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(FILTER_ANSWER,IBEG,IEND)
                  WRITE(6,*)' FILTER_RANGE       : ',
     +                 FILTER_ANSWER(IBEG:IEND),' [number]' 
	          CALL STRPOS(THRESHOLD_ANSWER,IBEG,IEND)
                  WRITE(6,*)' THRESHOLD          : ',
     +                 THRESHOLD_ANSWER(IBEG:IEND),
     +                 ' [FORMULA(+-x)/ALL/filename]' 
	          CALL STRPOS(SORTMODE_ANSWER,IBEG,IEND)
                  WRITE(6,*)' SORT_MODE          : ',
     +                 SORTMODE_ANSWER(IBEG:IEND),
     +                 ' [DISTANCE,VALUE,SIM/WSIM/IDENTITY/VALPER]' 
	          CALL STRPOS(PROFILE_ANSWER,IBEG,IEND)
                  WRITE(6,*)' 2_PROFILE_OPTION   : ',
     +            PROFILE_ANSWER(IBEG:IEND),' [FULL/MEMBER/MAX/IGNORE]' 
	          CALL STRPOS(INDEL_ANSWER_1,IBEG,IEND)
                  WRITE(6,*)' INDEL_IN_SEC_STRUC_1: ',
     +                 INDEL_ANSWER_1(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(INDEL_ANSWER_2,IBEG,IEND)
                  WRITE(6,*)' INDEL_IN_SEC_STRUC_2: ',
     +                 INDEL_ANSWER_2(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(COMPARE_ANSWER,IBEG,IEND)
                  WRITE(6,*)' SUPERPOS_IN_3-D    : ',
     +                 COMPARE_ANSWER(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(HSSP_ANSWER,IBEG,IEND)
                  WRITE(6,*)' HSSP_OUTPUT        : ',
     +                 HSSP_ANSWER(IBEG:IEND),' [YES/NO]' 
                  WRITE(6,*)' OUT_FORMAT_HSSP        : ',
     +                 HSSP_FORMAT_ANSWER(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(SAMESEQ_ANSWER,IBEG,IEND)
                  WRITE(6,*)' SAME_SEQ_SHOW      : ',
     +                 SAMESEQ_ANSWER(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(PROFILEOUT_ANSWER,IBEG,IEND)
                  WRITE(6,*)' PROFILE_OUTPUT     : ',
     +                 PROFILEOUT_ANSWER(IBEG:IEND),' [YES/NO]' 
	          CALL STRPOS(STRIPFILE_ANSWER,IBEG,IEND)
                  WRITE(6,*)' STRIP_OUTPUT       : ',
     +                 STRIPFILE_ANSWER(IBEG:IEND),' [YES/NO/filename]' 
	          CALL STRPOS(LONG_OUTPUT_ANSWER,IBEG,IEND)
                  WRITE(6,*)' LONG_OUTPUT        : ',
     +                 LONG_OUTPUT_ANSWER(IBEG:IEND),
     +                 ' [YES/NO/filename]' 

	          CALL STRPOS(PLOTFILE_ANSWER,IBEG,IEND)
                  WRITE(6,*)' DOT_PLOT_OUTPUT    : ',
     +                  PLOTFILE_ANSWER(IBEG:IEND),' [YES/NO/filename]' 
	          CALL STRPOS(NBEST_ANSWER,IBEG,IEND)
                  WRITE(6,*)' NBEST              : ',
     +                      NBEST_ANSWER(IBEG:IEND),' [integer number]' 
	          CALL STRPOS(NGLOBALHITS_ANSWER,IBEG,IEND)
                  WRITE(6,*)' MAXALIGN           : ',
     +                NGLOBALHITS_ANSWER(IBEG:IEND),' [integer number]' 
	          CALL STRPOS(PDBPATH_ANSWER,IBEG,IEND)
                  WRITE(6,*)' PDB_PATH           : ',
     +                 PDBPATH_ANSWER(IBEG:IEND),' [directory path]' 
	          CALL STRPOS(DSSP_PATH,IBEG,IEND)
                  WRITE(6,*)' DSSP_PATH          : ',
     +                 DSSP_PATH(IBEG:IEND),' [directory path]' 
               ELSE
	          CALL STRPOS(CFIELD(ID),IBEG,IEND)
	          WRITE(6,*)
     +                 '***** OPTION UNKNOWN : ',CFIELD(ID)(IBEG:IEND)
               ENDIF
            ENDIF
            ID=ID+1
         ENDDO
      ENDDO

      IF (LEXIST .EQV. .TRUE.) THEN
         CLOSE(IUNIT)
      ENDIF
      RETURN
      END
C     END INTERFACE
C......................................................................

C......................................................................
C     SUB LUDCMP
      SUBROUTINE LUDCMP(A,N,NP,INDX,D)
      PARAMETER      (NMAX=                    100)
      PARAMETER      (TINY=                      1.0E-20)
      DIMENSION A(NP,NP),INDX(N),VV(NMAX)
C init
      D = 1.0
      IMAX=0
C check dimension
      IF ( N .GT. NMAX) THEN
         WRITE(6,*)'ERROR: dimesnion overflow in LUDCMP'
         STOP
      ENDIF
      DO I=1,N
         AAMAX = 0.0
         DO J=1,N
	    IF (ABS(A(I,J)) .GT. AAMAX) AAMAX = ABS(A(I,J))
         ENDDO
         IF (AAMAX .EQ. 0.0) THEN
            WRITE(6,*)'Singular matrix.'
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
         IF (J .NE. N) THEN
	    IF (A(J,J) .EQ. 0.0)A(J,J)=TINY
	    DUM=1.0 / A(J,J)
	    DO I=J+1,N
               A(I,J) = A(I,J) * DUM
	    ENDDO
         ENDIF
      ENDDO
      IF (A(N,N) .EQ. 0.0 )A(N,N)=TINY
      RETURN
      END
C     END LUDCMP
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
         IF (I .LT. N) THEN
	    DO J=I+1,N
               SUM = SUM - A(I,J) * B(J)
	    ENDDO
         ENDIF
         B(I)=SUM/A(I,I)
      ENDDO
      RETURN
      END

C     END LUBKSB
C......................................................................

C......................................................................
C     SUB MAXHOM_PARALLEL_INTERFACE
      SUBROUTINE MAXHOM_PARALLEL_INTERFACE(LH1,LH2,NFILE,NALIGN,
     +     NENTRIES,NAMINO_ACIDS)

C import
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'

c import
      REAL      LH1(0:MAXMAT)
      INTEGER*2 LH2(0:MAXTRACE)

c	real lh(0:maxmat*2)
      INTEGER NFILE,NALIGN,NENTRIES,NAMINO_ACIDS
C internal
c	integer iset,jset
	
      WRITE(6,*)' start: send init data'
      CALL SEND_DATA_TO_NODE

      CALL SEND_JOBS(LH1,LH2,NFILE,NALIGN,NENTRIES,NAMINO_ACIDS)
      WRITE(6,*)' call receive_results '
      CALL RECEIVE_RESULTS_FROM_NODE(NALIGN)
      WRITE(6,*)' receive_results finished'
      CALL GET_CPU_TIME('time dbscan:',IDPROC,
     +     ITIME_OLD,ITIME_NEW,TOTAL_TIME,LOGSTRING)

      CALL LOG_FILE(KLOG,LOGSTRING,2)
      RETURN
      END
C     END MAXHOM_PARALLEL_INTERFACE
C......................................................................

C......................................................................
C     SUB MAXHOM_QSORT
      SUBROUTINE MAXHOM_QSORT(N,IKEY,IFILE,V)
C Non-recursive version of QUICKSORT algorithm, Wolfgang Kabsch, 1981.
C The pair (V,IKEY) is ordered according to increasing values of V.
C V(1) is the smallest value 
C 2**NSTACK values can be sorted if DIMENSION ISTACK(NSTACK,2).
C ON 32 BIT MACHINE  (NSTACK= nbit-2)

c	implicit none
      INTEGER N
      INTEGER IKEY(*),IFILE(*)
      REAL    V(*)
C internal
      INTEGER NSTACK
      PARAMETER      (NSTACK=                   30)
      INTEGER ISTACK(NSTACK,2)
      INTEGER J,K,IL,IR,JL,JR
      REAL VALK,X

      IF ( N .GT. 2**NSTACK ) THEN
         WRITE(6,*) 'QSORT OVERFLOW' 
         STOP
      ENDIF
      J=1
      ISTACK(1,1)=1 
      ISTACK(1,2)=N
 10   JL=ISTACK(J,1) 
      JR=ISTACK(J,2) 
      J=J-1
 20   IL=JL 
      IR=JR 
      K=(JL+JR)/2 
C     hack br: 1999-12 K can be 0!
      IF (K     .LE. 0)    K=K+1
      VALK=V(K)
 30   IF (V(IL) .GE. VALK) GOTO 40
      IL=IL+1
      GOTO 30
 40   IF (V(IR) .LE. VALK) GOTO 50
      IR=IR-1
      GOTO 40
 50   IF (IL .GT. IR) GOTO 60
c swap v and ikey: il<-->ir
      K=IKEY(IL) 
      IKEY(IL)=IKEY(IR) 
      IKEY(IR)=K
C keep track of file pointer
      K=IFILE(IL) 
      IFILE(IL)=IFILE(IR) 
      IFILE(IR)=K
      X=V(IL) 
      V(IL)=V(IR) 
      V(IR)=X
c end swap
      IL=IL+1 
      IR=IR-1
      IF ( IL      .LE. IR      ) GOTO 30
 60   IF ( (IR-JL) .GE. (JR-IL) ) GOTO 80
      IF ( IL      .GE. JR      ) GOTO 70
      J=J+1
      IF ( J .GT. NSTACK ) THEN
         WRITE(6,*)J  
         STOP' QSORT OVERFLOW'
      ENDIF
      ISTACK(J,1)=IL 
      ISTACK(J,2)=JR
 70   JR=IR
      GOTO 100
 80   IF ( JL .GE. IR ) GOTO 90
      J=J+1
      IF ( J .GT. NSTACK ) THEN
         WRITE(6,*)J 
         STOP' QSORT OVERFLOW'
      ENDIF
      ISTACK(J,1)=JL 
      ISTACK(J,2)=IR
 90   JL=IL
 100  IF ( JL .LT. JR ) GOTO 20
      IF ( J  .GT. 0  ) GOTO 10
      RETURN
      END
C     END MAXHOM_QSORT
C......................................................................

C......................................................................
C     SUB MOMENT
      SUBROUTINE MOMENT(DATA,N,AVE,ADEV,SDEV,VAR,SKEW,CURT)

      REAL DATA(*)

      S=0.0
      DO J=1,N 
         S=S+DATA(J) 
      ENDDO
      AVE=S/N 
      ADEV=0.0 
      VAR=0.0 
      SKEW=0.0 
      CURT=0.0
      DO J=1,N
         S=DATA(J)-AVE 
         ADEV=ADEV+ABS(S)
         P=S*S 
         VAR=VAR+P 
         P=P*S 
         SKEW=SKEW+P
         P=P*S 
         CURT=CURT+P
      ENDDO
      ADEV=ADEV/N 
      VAR=VAR/(N-1) 
      SDEV=SQRT(VAR)
      IF (VAR.NE.0.) THEN
         SKEW=SKEW/(N*SDEV**3) 
         CURT=CURT/(N*VAR**2)-3.  
      ELSE
         WRITE(6,*)'no skew or kurtosis when zero variance'
      ENDIF
      RETURN
      END
C     END MOMENT
C......................................................................

C......................................................................
C     SUB NORM_PROFILE
      SUBROUTINE NORM_PROFILE(MAXRES,NTRANS,TRANS,NRES_PROF,NRES_SEQ,
     +     LSEQ,PROFILE,EPSILON,GAMMA,SMIN,SMAX,MAPLOW,MAPHIGH,
     +     GAPOPEN,GAPELONG,SDEV)

	
      INTEGER MAXRES,NRES_PROF,NRES_SEQ,NTRANS,LSEQ(*)
      REAL PROFILE(MAXRES,NTRANS)
      REAL GAPOPEN(*),GAPELONG(*)
      REAL SMIN,SMAX,MAPLOW,MAPHIGH,EPSILON,GAMMA
      CHARACTER*(*) TRANS

      REAL AVE,SDEV
      REAL SUM,P
      INTEGER J,PRES
      LOGICAL LERROR
C init
      WRITE(6,*) 'INFO: SUB: NORM_PROFILE executed here'
      SMAX=0.0 
      SMIN=0.0 
      SUM=0.0 
      SDEV=0.0 
      VAR=0.0
      MAPLOW=0.0 
      MAPHIGH=0.0
      NCOUNT= NRES_SEQ * NRES_PROF
C get mean, sdev of profile-sequence pair
      DO IRES=1,NRES_SEQ
         DO PRES=1,NRES_PROF
            SUM = SUM + PROFILE(PRES,LSEQ(IRES))  
         ENDDO
      ENDDO
      AVE=SUM / NCOUNT
      DO IRES=1,NRES_SEQ
         DO PRES=1,NRES_PROF
            SUM  = PROFILE(PRES,LSEQ(IRES)) - AVE
            P    = SUM * SUM
            VAR  = VAR + P
         ENDDO
      ENDDO
      VAR  = VAR / (NCOUNT-1)
      SDEV = SQRT(VAR)
C shift mean of the profile to epsilon * sdev
      SHIFT=AVE + ABS(EPSILON*SDEV)
      DO PRES=1,NRES_PROF
         DO JPOS=1,NTRANS
            PROFILE(PRES,JPOS)=PROFILE(PRES,JPOS) - SHIFT
         ENDDO
      ENDDO
      WRITE(6,*)' before: ave,sdev,shift  ',ave,sdev,shift
C do statistic
      SUM=0.0 
      SDEV=0.0 
      VAR=0.0
      DO IRES=1,NRES_SEQ
         DO PRES=1,NRES_PROF
            SUM = SUM + PROFILE(PRES,LSEQ(IRES))  
         ENDDO
      ENDDO
      AVE=SUM / NCOUNT
      DO IRES=1,NRES_SEQ
         DO PRES=1,NRES_PROF
            SUM  = PROFILE(PRES,LSEQ(IRES)) - AVE
            P    = SUM * SUM
            VAR  = VAR + P
         ENDDO
      ENDDO
      VAR  = VAR / (NCOUNT-1)
      SDEV = SQRT(VAR)

      WRITE(6,*)' after: ave sdev ',ave,sdev

C scale
      SMAX=-1.0E+10
      SMIN=1.0E+10
      DO PRES=1,NRES_PROF
         DO JPOS=1,NTRANS
            IF ( PROFILE(PRES,JPOS) .GT. SMAX ) SMAX=PROFILE(PRES,JPOS)
            IF ( PROFILE(PRES,JPOS) .LT. SMIN ) SMIN=PROFILE(PRES,JPOS)
         ENDDO
      ENDDO

      DO PRES=1,NRES_PROF
         GAPOPEN(PRES) =  (SDEV * GAMMA) - EPSILON
         GAPELONG(PRES)=  GAPOPEN(PRES) / 10.0
      ENDDO

      WRITE(6,*)' smin/smax ',smin,smax
      WRITE(6,*)' open/elong ',gapopen(1),gapelong(1)

c	shi=smax
c	slo=smin
c	IF (maplow .eq. 0.0 .and. maphigh .eq. 0.0) THEN
c          WRITE(6,*)' scale between maplow/maphigh'
c	  shi=abs(sdev)
c	  slo=shi * -1.0
c	endif
c	do pres=1,nres_prof
c	   do jpos=1,ntrans
c	      profile(pres,jpos)=(( profile(pres,jpos) -slo) / 
c     +                        (shi-slo))*(smax-smin)+smin 
c	   enddo
c	enddo

C=======================================================================
C reset value for chain breaks etc...
C add 'X' '!' and "-"
      J=INDEX(TRANS,'X')
      K=INDEX(TRANS,'!')
      L=INDEX(TRANS,'-')
      M=INDEX(TRANS,'.')
      IF (J .EQ. 0 .OR. K .EQ. 0 .OR. L .EQ. 0) THEN
         WRITE(6,*)'*** error: "X","!","-" or "." unknown in '//
     +              'norm_profile'
      ENDIF
      DO I=1,NRES_PROF
         PROFILE(I,J)=0.0
         PROFILE(I,K)=0.0
         PROFILE(I,L)=0.0
         PROFILE(I,M)=0.0
      ENDDO
c=======================================================================
c debug: WRITE matrix in output-file
c=======================================================================
      CALL OPEN_FILE(99,'metric_debug.x','new,recl=500',LERROR)
      DO I=1,NRES_PROF
         WRITE(99,'(1X,25(F7.2))')(PROFILE(I,J),J=1,NTRANS)
      ENDDO
      CLOSE(99)
c=======================================================================
      RETURN
      END
C     END NORM_PROFILE
C......................................................................

C......................................................................
C     SUB PREP_PROFILE
      SUBROUTINE PREP_PROFILE(NALIGN,NRES,WEIGHT_MODE,SIGMA,BETA)
      IMPLICIT        NONE
      INCLUDE         'maxhom.param'
      INCLUDE         'maxhom.common'

C import
      INTEGER         NALIGN,NRES
C used for smoothing the profile
      REAL            SIGMA,BETA

c	character*(*) profileout
      CHARACTER       WEIGHT_MODE*(*)
C internal

      INTEGER         MAXAA
      PARAMETER      (MAXAA=                    20)
C==================================================================
C used for de-log metrices
      REAL            SCALE_FACTOR,LOG_BASE,WEIGHTS(MAXHITS)
      INTEGER         I,J
      
      INTEGER         LOWERPOS(NASCII)
      CHARACTER       LOWER*26

C==================================================================
C init
C used to convert lower case characters from the DSSP-seq to 'C' (Cys)
      LOWER='abcdefghijklmnopqrstuvwxyz'
      CALL GETPOS(LOWER,LOWERPOS,NASCII)
      CALL GETPOS(TRANS,TRANSPOS,NASCII)

      WRITE(6,*)TRANS
      CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,NIOSTATES_2,
     +     CSTRSTATES,CIOSTATES,IORANGE,
     +     KSIM,METRICFILE,SIMORG)
      IF (LDSSP_1) THEN
         CALL LOWER_TO_CYS(CSQ_1,NRES)
      ENDIF
      CALL SEQ_TO_INTEGER(CSQ_1,LSQ_1,NRES,TRANSPOS)
      CALL STR_TO_CLASS(MAXSTRSTATES,STR_CLASSES,NRES,STRUC_1,
     +     STRCLASS_1,LSTRUC_1)
      CALL ACC_TO_INT(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NIOSTATES_1,IORANGE,
     +     NRES,LSQ_1,LSTRUC_1,NSURF_1,LACC_1)
      CALL FILLSIMMETRIC(MAXSQ,NTRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NSTRSTATES_2,CSTRSTATES,SIMORG,NRES,LSQ_1,
     +     LSTRUC_1,LACC_1,SIMMETRIC_1)

c        IF (ldssp_1) THEN
c	  do ires=1,nres
c	     call getindex(csq_1_array(ires) ,lowerpos,i)
c	     IF (i.ne.0)csq_1_array(ires)='C'
c	  enddo
c	endif

      CALL ADD_SEQ_TO_SEQBUFFER(MAXHITS,MAXSEQBUFFER,1,NALIGN,
     +     CSQ_1_ARRAY,1,NRES,HSSPID_1,SEQBUFFER,ISEQPOINTER,
     +     AL_IFIRST,AL_ILAST,AL_JFIRST,AL_JLAST,AL_LEN,
     +     AL_NGAP,AL_LGAP,AL_LSEQ_2,AL_PDB_POINTER,
     +     AL_HOM,AL_SIM,AL_EXCLUDEFLAG,AL_ACCESSION,
     +     AL_EMBLPID,
     +     AL_COMPOUND)
      

      NBOX_1=1
      PROFILEBOX_1(1,1)=1 
      PROFILEBOX_1(1,2)=NRES

      WRITE(6,*)'********** defaults *********************'
      CALL STRPOS(METRICFILE,I,J)
      WRITE(6,*)' metric    : ',metricfile(i:j)
      WRITE(6,*)' smin      : ',smin
      WRITE(6,*)' smax      : ',smax
      WRITE(6,*)' maplow    : ',maplow
      WRITE(6,*)' maphigh   : ',maphigh
      WRITE(6,*)' open_1    : ',open_1
      WRITE(6,*)' elong_1   : ',elong_1
      WRITE(6,*)'*****************************************'

      CALL SINGLE_SEQ_WEIGHTS(NALIGN,SEQBUFFER,
     +     ISEQPOINTER,AL_IFIRST,AL_ILAST,
     +     WEIGHT_MODE,WEIGHTS)

      IF (INDEX(METRICFILE,'osum') .NE. 0) THEN
         SCALE_FACTOR=0.5 
         LOG_BASE=2.0
      ELSE
         SCALE_FACTOR=1.0 
         LOG_BASE=10.0
      ENDIF
      WRITE(6,*)'scale_factor log_base: ',scale_factor,log_base

      WRITE(6,*)'sigma beta: ',sigma,beta
	
      CALL CALC_PROFILE(MAXSQ,MAXAA,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,
     +     NIOSTATES_2,
     +     SCALE_FACTOR,LOG_BASE,SIGMA,BETA,
     +     NRES,NALIGN,
     +     AL_EXCLUDEFLAG,AL_IFIRST,AL_ILAST,
     +     SEQBUFFER,ISEQPOINTER,NTRANS,TRANS,
     +     WEIGHTS,OPEN_1,ELONG_1,GAPOPEN_1,
     +     GAPELONG_1,SIMORG,SIMMETRIC_1) 
      
      RETURN
      END
C     END PREP_PROFILE
C......................................................................

C......................................................................
C     SUB READ_FILENAME
      SUBROUTINE READ_FILENAME(KUNIT,FILENAME,LENDFILE,LERROR)
      
      CHARACTER*(*) FILENAME
      INTEGER       KUNIT
      LOGICAL       LENDFILE,LERROR
      
      LENDFILE=     .FALSE. 
      LERROR=       .FALSE.
      FILENAME=     ' '
      READ(KUNIT,'(A)',END=100,ERR=200)FILENAME
      RETURN
 100  LENDFILE=     .TRUE.
      RETURN
 200  LERROR=       .TRUE.
      RETURN
      END
C     END READ_FILENAME
C......................................................................

C......................................................................
C     SUB RECEIVE_RESULTS_FROM_NODE
      SUBROUTINE RECEIVE_RESULTS_FROM_NODE(NALIGN)
C import
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
C export
      INTEGER NALIGN
C local for each node
c   	integer irecpoi(maxaligns),ifilepoi(maxaligns)
c   	real    alisortkey(maxaligns),len2_orig(maxaligns)
C internal
      INTEGER IWORKER,IALIGN,IBEG,IEND
      INTEGER IALIGN_GOOD_ALL
C receive result from nodes and store in GLOBAL space 
      ILINK=1 
      LOGSTRING=' '

      IALIGN_GOOD_ALL = IALIGN_GOOD

      WRITE(6,*)' receive results: nalign nworker ', nalign,
     +     NWORKER,IALIGN_GOOD
      CALL FLUSH_UNIT(6)

c	msgtype=idtop
      DO IWORKER=1,NWORKER
         MSGTYPE=4000 
         ILINK=IWORKER
         CALL MP_RECEIVE_DATA(MSGTYPE,LINK(ILINK))
         CALL MP_GET_INT4(MSGTYPE,LINK(ILINK),IALIGN,N_ONE)
         CALL MP_GET_INT4(MSGTYPE,LINK(ILINK),IALIGN_GOOD,
     +        N_ONE)

         IALIGN_GOOD_ALL = IALIGN_GOOD_ALL + IALIGN_GOOD

         WRITE(6,*)ILINK,' IALIGN/GOOD/GOOD_ALL',
     +        IALIGN,IALIGN_GOOD,IALIGN_GOOD_ALL
         CALL FLUSH_UNIT(6)
         IF (IALIGN .GT. 0) THEN
            MSGTYPE=5000
            IBEG=NALIGN 
            IEND=NALIGN+IALIGN-1
            IF (IEND .GT. MAXALIGNS) THEN
               WRITE(6,*)'FATAL ERROR: MAXALIGNS OVERFLOW, INCREASE !!'
               CALL FLUSH_UNIT(6)
               STOP
            ENDIF
            CALL MP_RECEIVE_DATA(MSGTYPE,LINK(ILINK))
            CALL MP_GET_REAL4(MSGTYPE,LINK(ILINK),
     +           ALISORTKEY(IBEG),IALIGN)
            CALL MP_GET_INT4(MSGTYPE,LINK(ILINK),
     +           IRECPOI(IBEG),IALIGN)
            CALL MP_GET_INT4(MSGTYPE,LINK(ILINK),
     +           IFILEPOI(IBEG),IALIGN)
            NALIGN=NALIGN+IALIGN
            WRITE(LOGSTRING,'(A,4(I6))')' pid / done : ',
     +           IWORKER,IALIGN
         ELSE
            WRITE(LOGSTRING,'(A,I6,I6)')'nothing found: ',
     +           IWORKER,IALIGN
         ENDIF
         CALL LOG_FILE(KLOG,LOGSTRING,0)
         CALL FLUSH_UNIT(6)
      ENDDO
      NALIGN=NALIGN-1
      IALIGN_GOOD=IALIGN_GOOD_ALL
      WRITE(6,*)' total done : ',nalign,ialign_good
      CALL FLUSH_UNIT(6)
      RETURN
      END
C     END RECEIVE_RESULTS_FROM_NODE
C......................................................................

C......................................................................
C     SUB SEND_ALI_REQUEST
      SUBROUTINE SEND_ALI_REQUEST(IWORKER,IRECORD,IMSGTAG,CHECKVAL) 
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
c input
      INTEGER IWORKER,IRECORD,IMSGTAG
      REAL CHECKVAL
      MSGTYPE=6000
      
      CALL MP_INIT_SEND()
      CALL MP_PUT_INT4(MSGTYPE,IWORKER,IRECORD,N_ONE)
      CALL MP_PUT_INT4(MSGTYPE,IWORKER,IMSGTAG,N_ONE)
      CALL MP_PUT_REAL4(MSGTYPE,IWORKER,CHECKVAL,N_ONE)
      CALL MP_SEND_DATA(MSGTYPE,LINK(IWORKER))
      
      RETURN
      END
C     END SEND_ALI_REQUEST
C......................................................................

C......................................................................
C     SUB SEND_JOBS
C get "ready" signal from node and send "nfile" jobs

      SUBROUTINE SEND_JOBS(LH1,LH2,NFILE,NALIGN,NENTRIES,
     +     NAMINO_ACIDS)
C import
      IMPLICIT NONE
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
      INTEGER NFILE,NENTRIES,NAMINO_ACIDS
c import
      REAL      LH1(0:MAXMAT)
      INTEGER*2 LH2(0:MAXTRACE)
c	real lh(0:maxmat*2)
C internal
      INTEGER IFLAG
c       integer inix
      INTEGER IFILE,JFILE,ISET,ILINK,I,NALIGN,IALIGN,IFIRST_ROUND
      INTEGER NRECORD,IPOINTER

      INTEGER IDONE(MAXPROC)

c        integer ipos,nsplit,isplit
c        logical lendbase,ldb_read_one

      LOGICAL LERROR,LENDFILE
      CHARACTER*200  FILENAME
C init
      FILENAME=' '
      JFILE=0 
      ILINK=1 
      MSGTYPE=0
      DO I=1,MAXPROC 
         IDONE(I)=0 
      ENDDO
      NALIGN=1 
      IALIGN=0
      IFILE=1 
      IFIRST_ROUND=0
      NRECORD=0 
      ISET=0 
      IPOINTER=1
      IALIGN_GOOD=0

c        ldb_read_one=.false.


c$$$        if (ldb_read_one .eqv. .true.) THEN
c$$$	   nbuffer_len = 6 + len(name_2) + len(compnd_2) + 
c$$$     +                len(ACCESSION_2) + len(pdbref_2)
c$$$           lfirst_scan=.false.
c$$$           nsplit=namino_acids / (nworker +1)
c$$$
c$$$	   iset=0 ; isplit=0
c$$$
c$$$           do while( ifile .le. nfile)
c$$$              lendbase=.false.
c$$$	      call open_sw_data_file(kbase,ifile,split_db_data,
c$$$     +                               split_db_path)
c$$$c              WRITE(6,*)ifile,nseq_warm_start,isplit,nsplit
c$$$c              call flush_unit(6)
c$$$
c$$$	      do while(lendbase .eqv. .false.)
c$$$     call get_swiss_entry(maxsq,kbase,lbinary,n2in,name_2,compnd_2,
c$$$     +                          ACCESSION_2,pdbref_2,csq_2,lendbase)
c$$$
c$$$                 if (lendbase .eqv. .false.) THEN
c$$$                    IF ( (ipointer + nbuffer_len + n2in) .gt. 
c$$$     +                maxdatabase_buffer) THEN
c$$$                      WRITE(6,*)' **** FATAL ERROR ****'
c$$$                      WRITE(6,*)' database_buffer overflow increase'
c$$$                      WRITE(6,*)' dimension of MAXDATABASE_BUFFER'
c$$$                      STOP
c$$$                    endif
c$$$                 WRITE(cbuffer_line(1:),'(i6,a,a,a,a)')n2in,name_2,
c$$$     +                compnd_2,ACCESSION_2,pdbref_2
c$$$                    do ipos=1,nbuffer_len
c$$$                      cdatabase_buffer(ipointer)=
c$$$     +                                cbuffer_line(ipos:ipos)
c$$$                      ipointer=ipointer+1
c$$$                    enddo
c$$$                    do ipos=1,n2in
c$$$                       cdatabase_buffer(ipointer)=csq_2(ipos:ipos)
c$$$                       ipointer=ipointer+1
c$$$                    enddo   
c$$$              isplit=isplit+n2in ; nseq_warm_start=nseq_warm_start+1
c$$$                    if ( (isplit .ge. nsplit) .and. 
c$$$     +                   (iset .le. nworker) ) then
c$$$                       iset=iset+1 ; ipointer=ipointer-1
c$$$                       WRITE(6,'(a,i6,i8,i10,i8)')
c$$$     +                    'internal buffer: ',iset,nseq_warm_start,
c$$$     +                    ipointer,isplit
c$$$                       call flush_unit(6)
c$$$
c$$$                       msgtype=8000 ; ilink=iset
c$$$                       call mp_init_send()
c$$$                   call mp_put_int4(msgtype,ilink,ipointer,n_one)
c$$$                   call mp_put_int4(msgtype,ilink,nseq_warm_start,
c$$$     +                                  n_one)
c$$$                       call mp_send_data(msgtype,link(ilink))
c$$$                       msgtype=9000
c$$$                       call mp_init_send()
c$$$                       call mp_put_string_array(msgtype,ilink,
c$$$     +                                 cdatabase_buffer,ipointer)
c$$$                       call mp_send_data(msgtype,link(ilink))
c$$$                       ipointer=1 ; nseq_warm_start=0 ; isplit=0
c$$$                    endif
c$$$                 else 
c$$$                    close(kbase) ; ifile=ifile+1
c$$$                 endif    
c$$$              enddo   
c$$$           enddo
c$$$           msgtype=10000 
c$$$           call mp_init_send()
c$$$           call mp_put_int4(msgtype,ilink,ipointer,n_one)
c$$$           call mp_cast(nworker,msgtype,link(1))
c$$$        endif   

      CALL GET_CPU_TIME('time init:',IDPROC,
     +     ITIME_OLD,ITIME_NEW,TOTAL_TIME,LOGSTRING)
      CALL LOG_FILE(KLOG,LOGSTRING,2)
      IPOINTER=1

      IF (LISTOFSEQ_2 .EQV. .FALSE.) THEN
         IF (LFIRST_SCAN .EQV. .TRUE.) THEN
            DO WHILE (IFILE .LE. NFILE )
               MSGTYPE=2000 
               ILINK=-1
c	        call mp_receive_data(msgtype,ilink)
c	        call mp_get_int4(msgtype,ilink,ilink,n_one)

C first test for messages
               CALL MP_PROBE(MSGTYPE,IFLAG)
C if no communication is necessary do some "real" work
               IF ( IFLAG.EQ.0 .AND. IFILE .GE. NWORKSET*MAXQUEUE) THEN
                  WRITE(LOGSTRING,*)' file to host: ',ifile
                  CALL LOG_FILE(KLOG,LOGSTRING,1)
                  CALL HOST_INTERFACE(LH1,LH2,IFILE,FILENAME,IALIGN,
     +                 NRECORD,IPOINTER)
                  IFILE=IFILE+1
                  IFIRST_ROUND=1
c we have to fill the work-queue
               ELSE
                  MSGTYPE=2000 
                  CALL MP_RECEIVE_DATA(MSGTYPE,ILINK)
                  CALL MP_GET_INT4(MSGTYPE,ILINK,ILINK,N_ONE)
                  CALL MP_INIT_SEND()
C when we communicate the fist time, we fill the queue
                  IF (IFIRST_ROUND .EQ. 0) THEN
                     ISET=ISET+1
                     JFILE=ISET
                     DO I=1,MAXQUEUE
c                    WRITE(6,'(a,i4,a,i4)')' file: ',jfile,' to: ',ilink
c                    call flush_unit(6)
                        MSGTYPE=3000
                        CALL MP_PUT_INT4(MSGTYPE,ILINK,JFILE,N_ONE)
                        JFILE=JFILE+NWORKSET
                        IFILE=IFILE+1
                     ENDDO   
                     CALL MP_SEND_DATA(MSGTYPE,LINK(ILINK))
C send one file-pointer to refill the work-queue
                  ELSE
c                  WRITE(6,'(a,i4,a,i4)')' file: ',ifile,' to: ',ilink
c                  call flush_unit(6)
                     MSGTYPE=3000
                     CALL MP_PUT_INT4(MSGTYPE,ILINK,IFILE,N_ONE)
                     IFILE=IFILE+1
                     CALL MP_SEND_DATA(MSGTYPE,LINK(ILINK))
                  ENDIF
               ENDIF
            ENDDO
            LFIRST_SCAN=.FALSE.
C now tell everybody that the work is done
            ISET=0
            DO WHILE (ISET .LT. NWORKSET)
               MSGTYPE=2000 
               ILINK=-1
               CALL MP_RECEIVE_DATA(MSGTYPE,ILINK)
               CALL MP_GET_INT4(MSGTYPE,ILINK,ILINK,N_ONE)
               IF (IDONE(ILINK) .EQ. 0) THEN
c            WRITE(6,'(a,i4)')' last from: ',ilink ; call flush_unit(6)
                  ISET=ISET+1
                  IDONE(ILINK)=1
                  MSGTYPE=3000 
                  IFILE=-1
                  CALL MP_INIT_SEND()
                  CALL MP_PUT_INT4(MSGTYPE,ILINK,IFILE,N_ONE)
                  CALL MP_SEND_DATA(MSGTYPE,LINK(ILINK))
c                else
c                   WRITE(6,'(a,i4)')' collect dead message: ',ilink
c                   call flush_unit(6)
               ENDIF
            ENDDO

            WRITE(LOGSTRING,'(a,i6,i8,i10)')'internal buffer: ',
     +           IDPROC,NSEQ_WARM_START,IPOINTER
            CALL LOG_FILE(KLOG,LOGSTRING,1)
         ELSE
            CALL HOST_INTERFACE(LH1,LH2,IFILE,FILENAME,IALIGN,
     +           NRECORD,IPOINTER)
         ENDIF
      ELSE
C ===================================================================
C list of filenames
C ===================================================================
         IFILE=0


         WRITE(6,*)' load work queue: ',ilink
         LENDFILE=.FALSE. 
         LERROR=.FALSE.
         DO ILINK=1,NWORKSET
            DO I=1,MAXQUEUE_LIST
               IF ( (LENDFILE .EQV. .FALSE.) .AND. 
     +              (LERROR .EQV. .FALSE. ) ) THEN
                  CALL READ_FILENAME(KLIS2,FILENAME,LENDFILE,
     +                 LERROR)
               ENDIF
               IF ( (LENDFILE .EQV. .TRUE.) .OR. 
     +              (LERROR .EQV. .TRUE. ) ) THEN
                  FILENAME='STOP'
               ENDIF
               WRITE(6,'(A,A,A,I4)')'file: ',filename(1:50),
     +              ' to: ',ILINK
               CALL FLUSH_UNIT(6)
               MSGTYPE=9000
               CALL MP_INIT_SEND()
               CALL MP_PUT_STRING(MSGTYPE,ILINK,FILENAME,
     +              LEN(FILENAME))
               CALL MP_SEND_DATA(MSGTYPE,LINK(ILINK))
               IF ( (LENDFILE .EQV. .TRUE.) .OR. 
     +              (LERROR .EQV. .TRUE. ) ) THEN
                  GOTO 500
               ENDIF
               IFILE=IFILE+1
            ENDDO
         ENDDO

         DO WHILE (.TRUE. )
            MSGTYPE=2000 
            ILINK=-1
C first test for messages
            CALL MP_PROBE(MSGTYPE,IFLAG)
C if no communication is necessary do some "real" work
c              IF ( iflag .eq. 0 ) THEN
c                 ifirst_round=1

c              IF ( iflag .eq. 0 .and. 
c     +            ifile .ge. (nworkset * maxqueue_list) ) THEN
c                 ifirst_round=1
c                 call read_filename(klis2,filename,lendfile,lerror)
c             IF (lendfile .eqv. .true. .or. lerror .eqv. .true.) THEN
c                    filename='STOP'
c                          goto 500
c                 endif
c                 WRITE(logstring,*)' host is working on file: ',ifile
c                 call log_file(klog,logstring,1)
c                 call host_interface(lh1,lh2,ifile,filename,ialign,
c     +                              nrecord,ipointer)
c                 ifile=ifile+1
c we have to fill the work-queue
c              else
            MSGTYPE=2000 
            CALL MP_RECEIVE_DATA(MSGTYPE,ILINK)
            CALL MP_GET_INT4(MSGTYPE,ILINK,ILINK,N_ONE)
            CALL MP_INIT_SEND()
C send one file-pointer to refill the work-queue
c                 if (ifirst_round .ne. 0) then
            CALL READ_FILENAME(KLIS2,FILENAME,LENDFILE,LERROR)
            IF ( (LENDFILE .EQV. .TRUE.)  .OR. 
     +           ( LERROR .EQV. .TRUE.) ) THEN
               FILENAME='STOP'
               GOTO 500
            ENDIF
            WRITE(6,'(A,I4)')FILENAME(1:50),ILINK
            CALL FLUSH_UNIT(6)

            MSGTYPE=3000
            CALL MP_PUT_STRING(MSGTYPE,ILINK,FILENAME,
     +           LEN(FILENAME))
            CALL MP_SEND_DATA(MSGTYPE,LINK(ILINK))
            IFILE=IFILE+1
C when we communicate the fist time, we fill the queue
c                 else  
c                 endif
c              endif   
         ENDDO
c           lfirst_scan=.false.
C now tell everybody that the work is done
 500     ISET=0
         DO WHILE (ISET .LT. NWORKSET)
            MSGTYPE=2000 
            ILINK=-1
            CALL MP_RECEIVE_DATA(MSGTYPE,ILINK)
            CALL MP_GET_INT4(MSGTYPE,ILINK,ILINK,N_ONE)
            IF (IDONE(ILINK) .EQ. 0) THEN
               WRITE(6,'(a,i4)')' last from: ',ilink
               CALL FLUSH_UNIT(6)
               ISET=ISET+1 
               IDONE(ILINK)=1
               MSGTYPE=3000 
               FILENAME='STOP'
               CALL MP_INIT_SEND()
               CALL MP_PUT_STRING(MSGTYPE,ILINK,FILENAME,
     +              LEN(FILENAME))
               CALL MP_SEND_DATA(MSGTYPE,LINK(ILINK))
c                else
c                   WRITE(6,'(a,i4)')' collect dead message: ',ilink
c                   call flush_unit(6)
            ENDIF
         ENDDO
      ENDIF
      NALIGN=NALIGN+IALIGN
      WRITE(LOGSTRING,*)' host processed: ',nseq_warm_start,
     +     IALIGN_GOOD
      CALL LOG_FILE(KLOG,LOGSTRING,1)
      RETURN
      END
C     END SEND_JOBS
C......................................................................

C......................................................................
C     SUB SETCONSERVATION
      SUBROUTINE SETCONSERVATION(METRIC_FILENAME)
C 1. set conservation weights to 1.0
C 2. rescale matrix for the 22 amino residues such that the sum over
C    the matrix is 0.0 (or near)
C this matrix is used to calculate the conservation weights (SIMCONSERV)
c	implicit none
      INCLUDE         'maxhom.param'
      INCLUDE         'maxhom.common'
C import
      CHARACTER*(*)   METRIC_FILENAME

C internal
      INTEGER         NACID
      PARAMETER      (NACID=                    22)
      INTEGER         I,J
      REAL            XLOW,XHIGH,XMAX,XMIN,XFACTOR,SUMMAT
*----------------------------------------------------------------------*

C
      DO I=1,MAXSQ 
         CONSWEIGHT_1(I)=1.0
      ENDDO
      LFIRSTWEIGHT=.TRUE.
C get metric
      CALL GETSIMMETRIC(NTRANS,TRANS,MAXSTRSTATES,MAXIOSTATES,
     +     NSTRSTATES_1,NIOSTATES_1,NSTRSTATES_2,
     +     NIOSTATES_2,CSTRSTATES,CIOSTATES,
     +     IORANGE,KSIM,METRIC_FILENAME,SIMORG)
c rescale matrix that the sum over matrix is +- 0.0 
      XLOW=0.0 
      XHIGH=0.0
      XMAX=1.0 
      XMIN=-1.0 
      XFACTOR=100.0
	
C (re)store original values in simconserv()
 20   DO J=1,NTRANS 
         DO I=1,NTRANS
            SIMCONSERV(I,J)=SIMORG(I,J,1,1,1,1) 
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
cd	WRITE(6,*)' sum: ',summat,xmin
c check sum=0.0 (+- 0.01) ; if not xmin=xmin/2 ; scale again
      IF (SUMMAT .GT. 0.01) THEN
         XMIN=XMIN+(XMIN/XFACTOR)
      ELSE IF (SUMMAT .LT. -0.01) THEN
         XMIN=XMIN-(XMIN/XFACTOR)
      ELSE
         WRITE(6,*)' SETCONSERVATION: sum over matrix: ',summat
         WRITE(6,*)'                  smin is : ',xmin
c	  kdeb=45
c	  call open_file(kdeb,'DEBUG.X','NEW',lerror)
c          do i=1,ntrans        
c	   WRITE(kdeb,'(a,26(f5.2))')trans(i:i),
c     +                (simconserv(i,j),j=1,ntrans)
c          enddo
c	  WRITE(kdeb,*)'sum over matrix: ',summat
c	  WRITE(kdeb,*)'min,max: ',xmin,xmax
c	  close(kdeb)
         RETURN
      ENDIF
      GOTO 20	
      END
C     END SETCONSERVATION
C......................................................................

C......................................................................
C     SUB SINGLE_SEQ_WEIGHTS
      SUBROUTINE SINGLE_SEQ_WEIGHTS(NALIGN,SEQBUFFER,
     +     ISEQPOINTER,AL_IFIRST,AL_ILAST,MODE,WEIGHTS)
c
c     input: hssp alignments
c       w0 -- eigenvalue iteration weights x(i) 
c       w1 -- squared eigenvectors x(i)**2
c       w2 -- sum of distances w(i)=SUM(dist(i,j))
c       w3 -- exponential weight w(i)=1/SUM(exp(-dist(i,j)/dmean))
c
      IMPLICIT        NONE
C import
      INTEGER         NALIGN
      INTEGER         AL_IFIRST(*),AL_ILAST(*),ISEQPOINTER(*)
      CHARACTER       SEQBUFFER(*)
      CHARACTER       MODE*(*)
C export
      REAL            WEIGHTS(*)
c
      INTEGER         MAXALIGNS_LOC,MAXSTEP
      PARAMETER      (MAXALIGNS_LOC=         9999)
      PARAMETER      (MAXSTEP=                 100)
      REAL            TOLERANCE
      PARAMETER      (TOLERANCE=                 0.00001)
      REAL            DIST(MAXALIGNS_LOC,MAXALIGNS_LOC)
c	real sim_table(maxaligns,maxaligns)
c	integer maxaa
c	real sel_press,xpower,xtemp1,xtemp2
      REAL            WTEMP(MAXALIGNS_LOC)
c	real vtemp(maxaligns,maxaligns)
c
      INTEGER         STEP,LENGTH,NPOS,I,J,K,K0,K1,KPOS
      CHARACTER       A1,A2
      REAL            X,S,DMEAN
*----------------------------------------------------------------------*

c	maxaa=19

      I=LEN(MODE)
      CALL LOWTOUP(MODE,I)
      IF (NALIGN .GT. MAXALIGNS_LOC) THEN
         WRITE(6,*)' maxaligns overflow in single_seq_weight NALIGN=',
     +        NALIGN
         STOP
      ENDIF

      DO I=1,NALIGN
         WEIGHTS(I)=1.0
      ENDDO
      IF (NALIGN .LE. 1) THEN
         WRITE(6,*)' SINGLE_SEQ_WEIGHT: no alignments !'
         RETURN
      ENDIF
C calculate distance/identity table
      WRITE(6,*)' calculate distance table...'
      DO I=1,NALIGN
         DIST(I,I)=0.0
c	   sim_table(i,i)=1.0
         DO J=I+1,NALIGN
            LENGTH=0
            NPOS=0
            K0=MAX(AL_IFIRST(I),AL_IFIRST(J))
            K1=MIN(AL_ILAST(I),AL_ILAST(J))
            KPOS=ISEQPOINTER(I) + K0 - AL_IFIRST(I)
            DO K=K0,K1
               NPOS=NPOS+1
               A1= SEQBUFFER(KPOS)
               A2= SEQBUFFER(KPOS)
               KPOS=KPOS+1
               IF (A1.EQ.A2) LENGTH=LENGTH+1
               IF (A1 .GE. 'a' .OR. A2 .GE. 'a') THEN
                  IF (A1 .GE. 'a' ) THEN
                     A1=CHAR( ICHAR(A1)-32 )
                  ENDIF
                  IF (A2 .GE. 'a' ) THEN
                     A2=CHAR( ICHAR(A2)-32 )
                  ENDIF
                  IF (A1.EQ.A2) LENGTH=LENGTH+1
               ENDIF

c	         IF (a1 .ge. 'a' .and. a1 .le. 'z') THEN
c	           a1=char( ichar(a1)-32 )
c	         endif
c	         IF (a2 .ge. 'a' .and. a2 .le. 'z') THEN
c	           a2=char( ichar(a2)-32 )
c	         endif

            END DO
            DIST(I,J)= 1- (FLOAT(LENGTH)/MAX(1.0,FLOAT(NPOS)) )
c	      sim_table(i,j)=float(length)/max(1.0,float(npos))
c	      dist(i,j)= 1.00 - sim_table(i,j)
            DIST(J,I)=DIST(I,J)
c              sim_table(j,i)=sim_table(i,j)
         END DO
      END DO
c	WRITE(6,*) ' distances: '
c	do i=1,nalign
c	   WRITE(6,'(26i3)') (nint(100*dist(j,i)),j=1,nalign)
c	end do
c
      IF (INDEX(MODE,'MAT'). NE. 0 ) THEN 
         WRITE(6,*)' weight mode MAT NOT active '
         STOP
c	  WRITE(6,*)' preparing identity matrix...'
c	  sel_press=0.5
c	  xpower= 1.0 / (1.0 - sel_press + (1.0/maxaa) )
c	  xtemp1= 1.0 + (1.0 / (maxaa * (1.0 - sel_press) ) )
c	  xtemp2= 1.0 / (maxaa * (1-sel_press) )
c	  do i=1,nalign ; do j=1,nalign
c             sim_table(i,j) = ( sim_table(i,j) * xtemp1 - xtemp2 )
c	     IF (sim_table(i,j) .le. tolerance) THEN
c	       WRITE(6,*)'set sim_table to tolerance ',i,j
c               sim_table(i,j) = tolerance
c	     endif
c             sim_table(i,j) = sim_table(i,j) **xpower
c	  enddo ; enddo
c	  WRITE(6,*)' calculate singular value decomposition...'
c        call svdcmp(sim_table,nalign,nalign,maxaligns,maxaligns,wtemp,
c     +                vtemp)
c	  WRITE(6,*)' calculate matrix invers...'
c	  do i=1,nalign
c	     if (wtemp(i) .le. 0.0001) THEN
c                x=0.0
c	     else
c                x= 1/wtemp(i)
c	     endif
c	     do j=1,nalign
c                sim_table(i,j) = vtemp(i,j) * x * sim_table(i,j)
c	        weights(i) = weights(i) + sim_table(i,j)
c	     enddo
c	  enddo
c=======================================================================
c     calculate one-sequence weights from a distance matrix
c     step 0: w(k)    = 1 / N * sum[dist(k,length)]
c     step i: w(k)(i) = 1 / NORM * sum[dist(k,l) * w(length)(i-1)]
c     iterate until sum[|w(k)(i)-w(k)(i-1)|] < tolerance
c=======================================================================
c  eigenvector iteration 
c=======================================================================
      ELSE IF (INDEX(MODE,'EIGEN')  .NE. 0 .OR. 
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
         IF ((STEP .LT. MAXSTEP) .AND. (S .GT. TOLERANCE)) GOTO 10
         WRITE(6,'(A,I5,A,F10.4)')' WEIGHTS AT STEP:', STEP,
     +        ' DIFFERENCE: ',S
         WRITE(6,'(13F6.3)') (NALIGN*WTEMP(I),I=1,NALIGN)
      ENDIF
c=======================================================================
c                           weights(i)=wtemp(i)**2
c=======================================================================
      IF (INDEX(MODE,'SQUARE') .NE. 0) THEN
         S=0.0
         DO I=1,NALIGN
            WEIGHTS(I)=WTEMP(I) * WTEMP(I)
            S=S+WEIGHTS(I)
         END DO
         DO I=1,NALIGN
            WEIGHTS(I)=WEIGHTS(I)/S
         END DO
         WRITE(6,*) ' squared weights '
         WRITE(6,'(13F6.3)') (NALIGN*WEIGHTS(I),I=1,NALIGN)
c=======================================================================
c                  weights(i)=SUM(dist(i,j))
c=======================================================================
      ELSE IF (INDEX(MODE,'SUM') .NE. 0) THEN
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
         WRITE(6,*) ' summed distance weights '
         WRITE(6,'(13F6.3)') (NALIGN*WEIGHTS(I),I=1,NALIGN)
c=======================================================================
c               weights(i)=1/SUM(exp(-dist(i,j)/dmean))
c=======================================================================
      ELSE IF (INDEX(MODE,'EXP') .NE. 0) THEN
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
            IF (S.GT.0.0) THEN
               WEIGHTS(I)=1/S
            ELSE
               WRITE(6,*)  ' warning: s=0 in weights '
               WEIGHTS(I)=1.0
            END IF
         END DO
c normalize to 1.0
         S=0.0
         DO I=1,NALIGN
            S=S+WEIGHTS(I)
         END DO
         DO I=1,NALIGN
            WEIGHTS(I)=WEIGHTS(I)/S
         END DO
         WRITE(6,*) ' exponential distance weights '
         WRITE(6,'(13F6.3)') (NALIGN*WEIGHTS(I),I=1,NALIGN)
      ENDIF
 
      RETURN
      END
C     end single_seq_weight
C......................................................................

C......................................................................
C     SUB SVDCMP
      SUBROUTINE SVDCMP(A,M,N,MP,NP,W,V)
      INTEGER         MAXALIGNS_LOC
      PARAMETER      (MAXSTEP=                 100)
      PARAMETER      (MAXALIGNS_LOC=         9999)
      DIMENSION       A(MP,NP),W(NP),V(NP,NP),RV1(MAXALIGNS_LOC)
*----------------------------------------------------------------------*
        
      L=0
      nm=0
      G=0.0
      SCALE=0.0
      ANORM=0.0
      IF (m .gt. nmax) THEN
         WRITE(6,*)'***ERROR: dim. overflow for RV1 in SVDCMP'
         STOP
      endif
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
               IF ((ABS(RV1(L))+ANORM).EQ.ANORM)  GOTO 2
               IF ((ABS(W(NM))+ANORM).EQ.ANORM)  GOTO 1
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
               GOTO 3
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
C     END SVDCMP 
C......................................................................

C......................................................................
C     SUB WRITE_HISTO
      SUBROUTINE WRITE_HISTO(KHISTO,HISTOFILE,NALIGN,SORTVAL)

c	implicit none
C import
      INTEGER KHISTO,NALIGN
      REAL SORTVAL(*)
      CHARACTER*(*) HISTOFILE
C internal
c	integer maxbin,maxlen
c	integer i,ibin,nbin(maxbin),maxpop,minpop,iend
c	character line*(maxlen),mark
      LOGICAL LERROR

c	mark='*'
c	do i=1,maxlen ; line(i:i)=mark ; enddo
c	do i=1,maxbin ; nbin(i)=0 ; enddo

      CALL OPEN_FILE(KHISTO,HISTOFILE,'NEW',LERROR)
c	do i=1,nalign
c          ibin=nint( sortval(i) / sortval(nalign) * maxbin)
c	  IF (ibin .le. 0) THEN
c	    ibin=1
c	  else IF (ibin .gt. maxbin) THEN
c	    ibin=maxbin
c	  endif
c          nbin(ibin)=nbin(ibin)+1
c	enddo
c
c	maxpop=-1 ; minpop=1000000
c	do i=1,maxbin
c           IF (nbin(i) .gt. maxpop)maxpop=nbin(i)
c           IF (nbin(i) .lt. minpop)minpop=nbin(i)
c	enddo
      WRITE(KHISTO,'(A,I6)')  ' number of scores: ',nalign
      WRITE(KHISTO,'(A,F7.2)')' minimal scores:   ',sortval(1)
      WRITE(KHISTO,'(A,F7.2)')' maximum scores:   ',sortval(nalign)
      WRITE(KHISTO,'(A)')'_________________________________________'//
     +     '_____________________________________________'
c	do i=1,maxbin
c	   iend=nint( (float(nbin(i)) / float(maxpop)) * float(maxlen) )
c	   IF (iend .gt.0 ) THEN
c             WRITE(khisto,'(i5,a,a)')nbin(i),' |',line(1:iend)
c	   else
c             WRITE(khisto,'(i5,a)')nbin(i),' |'
c           endif
c	enddo
c	WRITE(khisto,*)
      WRITE(KHISTO,'(A)')' values: '
      DO I=1,NALIGN
         WRITE(KHISTO,'(I5,2X,F7.2)')I,SORTVAL(I)
      ENDDO

      CLOSE(KHISTO)

      RETURN
      END
C     END WRITE_HISTO
C......................................................................

C......................................................................
C     SUB WRITE_MAXHOM_COM
      SUBROUTINE WRITE_MAXHOM_COM(CFILTER)

c	implicit none
      INCLUDE 'maxhom.param'
      INCLUDE 'maxhom.common'
      CHARACTER*(*) CFILTER
c internal
      INTEGER OPTCUT,LENFILENAME,IBEG,IEND,I,J,JBEG,JEND
      CHARACTER COMMANDFILE*200,COMEXT*4,OUTLINE*200,LINE*35
      CHARACTER COMMENTLINE*200
      LOGICAL LERROR
C init
      OUTLINE=' '
      OPTCUT=110

      COMMENTLINE='$!==========================================='//
     +     '============================'
      COMEXT='.csh'

      LENFILENAME=INDEX(NAME1_ANSWER,'!')-1
      IF (LENFILENAME .LE. 0) LENFILENAME=LEN(NAME1_ANSWER)
      CALL GETPIDCODE(NAME1_ANSWER(1:LENFILENAME),HSSPID_1)
      CALL LOWTOUP(COMMANDFILE_ANSWER,200)

      CALL STRPOS(HSSPID_1,IBEG,IEND)
      IF (CFILTER .EQ. ' ') THEN
         COMMANDFILE(1:)=HSSPID_1(IBEG:IEND)//'_maxhom'//comext
      ELSE
         COMMANDFILE(1:)=HSSPID_1(IBEG:IEND)//'_hssp'//comext
      ENDIF
      CALL OPEN_FILE(KCOM,COMMANDFILE,'NEW',LERROR)

C=======================================================================
C UNIX c-shell script
C=======================================================================
      COMMENTLINE='#==========================================='//
     +     '============================'
      WRITE(KCOM,'(A)')'#! /bin/csh'
      WRITE(KCOM,'(A)')COMMENTLINE
      IF (CFILTER .EQ. ' ') THEN
         WRITE(KCOM,'(A)')'# command file to run MAXHOM'
      ELSE
         WRITE(KCOM,'(A)')'# command file to run a PRE-FILTERED MAXHOM'
      ENDIF
      WRITE(KCOM,'(A)')'goto set_enviroment'
      WRITE(KCOM,'(A)')'start:'
      WRITE(KCOM,'(A)')COMMENTLINE
      WRITE(KCOM,'(A)')'# This .csh file WRITEs a temporary '//
     +     'command file ("MAXHOM_"process_id".temp")'
      WRITE(KCOM,'(A)')'# containing the answers to the MAXHOM '//
     +     'questions.'
      WRITE(KCOM,'(A)')COMMENTLINE

C===================================================================

      IF (CFILTER .NE.' ') THEN
C get sequence 1 
         CALL STRPOS(NAME1_ANSWER,I,J)
         IF (LISTOFSEQ_1) THEN
	    WRITE(KCOM,'(A)')'# LOOP OVER FILENAMES IN LIST'
	    WRITE(KCOM,'(A)')
     +          'foreach filename ( "`cat '//NAME1_ANSWER(I:J)//'`" )'  
         ELSE
	    WRITE(KCOM,'(A)')'set filename = '//NAME1_ANSWER(I:J)  
         ENDIF
C get identifier
         WRITE(KCOM,'(A)')COMMENTLINE
         WRITE(KCOM,'(A)')'# GET IDENTIFIER'
         WRITE(KCOM,'(A)')COMMENTLINE
         WRITE(KCOM,'(A)')'   set name1 = $filename:r'
         WRITE(KCOM,'(A)')'   set name2 = $name1:t'
C convertseq
         WRITE(KCOM,'(A)')COMMENTLINE
         WRITE(KCOM,'(A)')'# CONVERT ALL FORMATS TO FASTA'
         WRITE(KCOM,'(A)')'   echo $filename    >   MAXHOM_$$.temp'
         WRITE(KCOM,'(A)')'   echo "F"          >>  MAXHOM_$$.temp'
         WRITE(KCOM,'(A)')'   echo "N"          >>  MAXHOM_$$.temp'
         WRITE(KCOM,'(A)')'   echo $name2".y"   >>  MAXHOM_$$.temp'
         WRITE(KCOM,'(A)')'   echo "N"          >>  MAXHOM_$$.temp'
         IF (CONVERTSEQ_EXE .NE. ' ') THEN
	    CALL STRPOS(CONVERTSEQ_EXE,IBEG,IEND)
	    WRITE(KCOM,'(A)')'   echo "run convert_seq"'
	    WRITE(KCOM,'(A,A,A)')
     +        '   ',CONVERTSEQ_EXE(IBEG:IEND),
     +        '  < MAXHOM_$$.temp >& /dev/null'
         ELSE
            STOP ' ERROR: CONVERTSEQ_EXE UNDEFINED '
         ENDIF
         WRITE(KCOM,'(A)')'   rm MAXHOM_$$.temp'
C run FASTA
         IF (CFILTER .EQ. 'FASTA') THEN
            WRITE(KCOM,'(A)')'   echo $name2".y"   >   MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')'   echo "S"          >>  MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')'   echo "1"          >>  MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')'   echo "fasta.x_"$$ >>  MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')'   echo "2000"       >>  MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')'   echo " "          >>  MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')'   echo "yes"        >>  MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')'   echo " "          >>  MAXHOM_$$.temp'
            IF (FASTA_EXE .NE. ' ') THEN
               CALL STRPOS(FASTA_EXE,IBEG,IEND)
               WRITE(KCOM,'(A,A,A)')'   ',FASTA_EXE(IBEG:IEND),
     +              ' -b 2000 -d 2000 -o < MAXHOM_$$.temp > fasta.x_$$'
            ELSE
               STOP ' ERROR: FASTA_EXE UNDEFINED '
            ENDIF
            WRITE(KCOM,'(A)')'   rm MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')'   rm $name2".y"'
C get filter.list
            WRITE(KCOM,'(A)')COMMENTLINE
            WRITE(KCOM,'(A)')'# EXTRACT POSSIBL HITS FROM FASTA-OUTPUT'
            WRITE(KCOM,'(A)')' echo "fasta.x_"$$ >  MAXHOM_$$.temp'
            WRITE(KCOM,'(A)')' echo "filter.list_"$$ >> MAXHOM_$$.temp'
            I=ISAFE-5
            IF (I.GT.0) THEN
               WRITE(OUTLINE,'(A,I2)')'FORMULA+',I
            ELSE IF (I.EQ.0) THEN
               WRITE(OUTLINE,'(A)')'FORMULA'
            ELSE
               WRITE(OUTLINE,'(A,I2)')'FORMULA-',ABS(I)
            ENDIF
            CALL STRPOS(OUTLINE,I,J)
	    WRITE(KCOM,'(A)')'   echo "'//OUTLINE(I:J)//
     +           '"  >> MAXHOM_$$.temp'
	    WRITE(KCOM,'(A,I5,A)')'   echo "',OPTCUT,
     +           '"  >> MAXHOM_$$.temp'
	    WRITE(KCOM,'(A)')'   echo "distance"   >>  MAXHOM_$$.temp'
	    IF (FILTER_FASTA_EXE .NE. ' ') THEN
               CALL STRPOS(FILTER_FASTA_EXE,IBEG,IEND)
               WRITE(KCOM,'(A,A,A)')'   ',FILTER_FASTA_EXE(IBEG:IEND),
     +              '  <  MAXHOM_$$.temp'
	    ELSE
               STOP ' ERROR: FILTER_FASTA_EXE UNDEFINED '
	    ENDIF
	    WRITE(KCOM,'(A)')'   rm MAXHOM_$$.temp'
	    WRITE(KCOM,'(A)')'   rm fasta.x_$$'
C rename output files if wanted
	    IF (STRIPFILE_ANSWER.NE.'NO') THEN
               STRIPFILE_ANSWER='$name2"_strip.x"'
            ENDIF
	    IF (long_output_ANSWER.NE.'NO') THEN
               LONG_OUTPUT_ANSWER='$name2"_long.x"'
            ENDIF
	    IF (PLOTFILE_ANSWER.NE.'NO') THEN
               PLOTFILE_ANSWER='$name2"_trace.x"'
            ENDIF
C run BLASTP
         ELSE IF (CFILTER .EQ. 'BLASTP') THEN
	    IF (BLASTP_EXE .NE. ' ') THEN
               CALL STRPOS(BLASTP_EXE,IBEG,IEND)
               WRITE(KCOM,'(A)')'   echo "run blastp"'
               WRITE(KCOM,'(A,A,A)')'   ',BLASTP_EXE(IBEG:IEND),
     +              ' swiss $name2".y" B=2000 > blast.x_$$'
	    ELSE
               STOP ' ERROR: BLASTP_EXE UNDEFINED '
	    ENDIF
	    WRITE(KCOM,'(A)')'   rm MAXHOM_$$.temp'
	    WRITE(KCOM,'(A)')'   rm $name2".y"'
	    WRITE(kcom,'(a)')commentline
	    WRITE(KCOM,'(A)')'# EXTRACT HITS FROM BLASTP-OUTPUT'
	    IF (FILTER_BLASTP_EXE .NE. ' ') THEN
               CALL STRPOS(FILTER_BLASTP_EXE,IBEG,IEND)
               CALL STRPOS(sw_current,jBEG,jEND)
               WRITE(KCOM,'(A,A,A,A,A)')'   ',
     +              FILTER_BLASTP_EXE(IBEG:IEND),' ',
     +              sw_current(jbeg:jend),
     +              ' <  blast.x_$$ > filter.list_$$'
               WRITE(kcom,'(a)')'   rm blast.x_$$'
	    ELSE
               STOP ' ERROR: FILTER_BLASTP_EXE UNDEFINED '
	    ENDIF
         ENDIF
      ENDIF
C call MAXHOM 
      LINE='"            >> MAXHOM_$$.temp  ' 
      WRITE(kcom,'(a)')commentline
      WRITE(KCOM,'(A)')'# --------  finally call MAXHOM     -------'
      WRITE(kcom,'(a)')commentline
      WRITE(KCOM,'(A)')'   echo "COMMAND NO" >  MAXHOM_$$.temp'
      WRITE(KCOM,'(A)')'   echo "BATCH" >>  MAXHOM_$$.temp'
      WRITE(KCOM,'(A)')'   echo "PID: "$$    >>  MAXHOM_$$.temp'
      IF (CFILTER .NE. ' ') THEN
         WRITE(KCOM,'(A)')'   echo "SEQ_1 "$filename >> MAXHOM_$$.temp'
         WRITE(KCOM,'(A)')
     +        '   echo "SEQ_2 filter.list_"$$ >> MAXHOM_$$.temp'
      ELSE
         CALL STRPOS(NAME1_ANSWER,I,J)
         WRITE(KCOM,'(A)')'   echo "SEQ_1 '//NAME1_ANSWER(I:J)//LINE
         CALL STRPOS(NAME2_ANSWER,I,J)
         WRITE(KCOM,'(A)')'   echo "SEQ_2 '//NAME2_ANSWER(I:J)//LINE
      ENDIF
      CALL STRPOS(PROFILE_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "2_PROFILES '//
     +                   PROFILE_ANSWER(I:J)//LINE
      CALL STRPOS(METRIC_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "METRIC '//METRIC_ANSWER(I:J)//LINE

      CALL STRPOS(NORM_PROFILE_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "NORM_PROFILE '//
     +     NORM_PROFILE_ANSWER(I:J)//LINE
      CALL STRPOS(PROFILE_EPSILON_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "MEAN_PROFILE '//
     +     PROFILE_EPSILON_ANSWER(I:J)//LINE
      CALL STRPOS(PROFILE_GAMMA_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "FACTOR_GAPS '//
     +     PROFILE_GAMMA_ANSWER(I:J)//LINE
      CALL STRPOS(SMIN_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "SMIN '//SMIN_ANSWER(I:J)//LINE
      CALL STRPOS(SMAX_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "SMAX '//SMAX_ANSWER(I:J)//LINE
      CALL STRPOS(OPENWEIGHT_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "GAP_OPEN '//
     +     OPENWEIGHT_ANSWER(I:J)//LINE
      CALL STRPOS(ELONGWEIGHT_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "GAP_ELONG '//
     +     ELONGWEIGHT_ANSWER(I:J)//LINE
      CALL STRPOS(WEIGHT1_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "WEIGHT1 '//WEIGHT1_ANSWER(I:J)//LINE
      CALL STRPOS(WEIGHT2_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "WEIGHT2 '//WEIGHT2_ANSWER(I:J)//LINE
      CALL STRPOS(WAY3_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "WAY3_ALIGN '//
     +     WAY3_ANSWER(I:J)//LINE
      CALL STRPOS(INDEL_ANSWER_1,I,J)
      WRITE(KCOM,'(A)')'   echo "INDEL_1 '//
     +     INDEL_ANSWER_1(I:J)//LINE
      CALL STRPOS(INDEL_ANSWER_2,I,J)
      WRITE(KCOM,'(A)')'   echo "INDEL_2 '//
     +     INDEL_ANSWER_2(I:J)//LINE
      CALL STRPOS(BACKWARD_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "RELIABILITY '//
     +     BACKWARD_ANSWER(I:J)//LINE
      CALL STRPOS(FILTER_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "FILTER_RANGE '//
     +     FILTER_ANSWER(I:J)//LINE
      CALL STRPOS(NBEST_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "NBEST '//NBEST_ANSWER(I:J)//LINE
      CALL STRPOS(NGLOBALHITS_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "MAXALIGN '//
     +     NGLOBALHITS_ANSWER(I:J)//LINE
      CALL STRPOS(THRESHOLD_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "THRESHOLD '//
     +     THRESHOLD_ANSWER(I:J)//LINE
      CALL STRPOS(SORTMODE_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "SORT '//SORTMODE_ANSWER(I:J)//LINE
      CALL STRPOS(HSSP_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "HSSP '//HSSP_ANSWER(I:J)//LINE
      CALL STRPOS(SAMESEQ_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "SAME_SEQ_SHOW '//
     +     SAMESEQ_ANSWER(I:J)//LINE
      CALL STRPOS(COMPARE_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "SUPERPOS '//COMPARE_ANSWER(I:J)//LINE
      CALL STRPOS(PDBPATH_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "PDB_PATH '//PDBPATH_ANSWER(I:J)//LINE
      CALL STRPOS(PROFILEOUT_ANSWER,I,J)
      WRITE(KCOM,'(A)')'   echo "PROFILE_OUT '//
     +     PROFILEOUT_ANSWER(I:J)//LINE
      CALL STRPOS(STRIPFILE_ANSWER,I,J)
      IF (INDEX(STRIPFILE_ANSWER,'$name2').NE.0) THEN
         WRITE(KCOM,'(A)')'   echo "STRIP_OUT "'//
     +        STRIPFILE_ANSWER(I:J)//
     +        '     >> MAXHOM_$$.temp'
      ELSE
         WRITE(KCOM,'(A)')'   echo "STRIP_OUT '//
     +        STRIPFILE_ANSWER(I:J)//LINE
      ENDIF
      CALL STRPOS(long_output_ANSWER,I,J)
      IF (INDEX(long_output_ANSWER,'$name2').ne.0) THEN
         WRITE(KCOM,'(A)')'   echo "LONG_OUT "'//
     +        long_output_ANSWER(I:J)//
     +        '     >> MAXHOM_$$.temp'
      ELSE
         WRITE(KCOM,'(A)')'   echo "LONG_OUT '//
     +        long_output_ANSWER(I:J)//LINE
      ENDIF
      
      CALL STRPOS(PLOTFILE_ANSWER,I,J)
      IF (INDEX(PLOTFILE_ANSWER,'$name2').ne.0) THEN
         WRITE(KCOM,'(A)')'   echo "DOT_PLOT "'//PLOTFILE_ANSWER(I:J)//
     +        '      >> MAXHOM_$$.temp'
      ELSE
         WRITE(KCOM,'(A)')'   echo "DOT_PLOT '//
     +        PLOTFILE_ANSWER(I:J)//LINE
         WRITE(KCOM,'(A)')'   echo "RUN"      >> MAXHOM_$$.temp'
      ENDIF
      WRITE(KCOM,'(A)')'   maxhom -nopar < MAXHOM_$$.temp'
CALT	WRITE(KCOM,'(A)')'   $snice maxhom < MAXHOM_$$.temp'
      WRITE(KCOM,'(A)')'   rm MAXHOM_$$.temp'
      CALL STRPOS(COREFILE,IBEG,IEND)
      WRITE(KCOM,'(A,A,A)')'   rm ',COREFILE(IBEG:IEND),'$$'
      WRITE(KCOM,'(A)')'   rm filter.list_$$'
      IF (CFILTER .NE. ' ' .AND. LISTOFSEQ_1) THEN
         WRITE(KCOM,'(A)')'end'
      ENDIF
      WRITE(KCOM,'(A)')'exit'
      
      WRITE(KCOM,'(A)')COMMENTLINE
      WRITE(KCOM,'(A)')'set_enviroment:'
      WRITE(KCOM,'(A)')'nohup'
      WRITE(KCOM,'(A)')'alias rm ''rm -f'''
      WRITE(KCOM,'(A)')'goto start'
      WRITE(KCOM,'(A)')COMMENTLINE
      
      CLOSE(KCOM)
C======================================================================
      WRITE(6,*)'****************************************************'
      CALL STRPOS(COMMANDFILE,IBEG,IEND)
      WRITE(6,*)' wrote command file to: ',commandfile(ibeg:iend)
      IF (CMACHINE .EQ. 'VMS' ) THEN
         WRITE(6,*)'now submit this command file to a batch queue'
      ELSE
         CALL CHANGE_MODE(COMMANDFILE,'+x',i)
         WRITE(6,*)'to execute this file type: '
         IF (I .NE. 0) THEN
            WRITE(6,'(A,A)')'chmod +x ',COMMANDFILE(IBEG:IEND)
         ENDIF
         WRITE(6,'(2X,A,A)')COMMANDFILE(IBEG:IEND),' > /dev/null &'
      ENDIF
      WRITE(6,*)'****************************************************'

      RETURN
      END
C     END WRITE_MAXHOM_COM
C......................................................................

