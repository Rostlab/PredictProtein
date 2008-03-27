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
C     CHARACTER*200 ERRORFILE

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
                  WRITE(6,*)K,SUM,METRIC_1(II,K),METRIC_2(JJ,K),
     +                 METRIC_1(II,K) * METRIC_2(JJ,K)
               ENDDO
c	      sim  = (sum/ntrans)
               SIM  = SUM
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
               ENDDO
               MAX2=-10000.0
               DO K=1,NTRANS
                  IF (METRIC_2(JJ,K) .GT. MAX2)MAX2=METRIC_2(JJ,K)
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
