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
C=======================================================================
C                 DO SOME STUFF OUTSIDE THE LOOPS:
C=======================================================================
C                          initialize
C=======================================================================
C      WRITE(*,*) ' info: inside SETMATRIX_FAST, profilemode= ',
C     +     PROFILEMODE
C      WRITE(6,*) ' info: N1BEG,N1END,N2BEG,N2END ',
C     +     N1BEG,N1END,N2BEG,N2END
      BESTVAL=-99999.0       
      BESTNOW=-99999.0
      BESTIIPOS=-1           
      BESTJJPOS=-1
      NSIZE1=N1END-N1BEG+1   
      NSIZE2=N2END-N2BEG+1
      
      J=MIN(N1BEG-1,N2BEG-1) 
      K=MAX(N1END+1,N2END+1)
      DO I=J,K
c	do i=0,maxsq+1
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
            IF(PROFILEMODE .EQ. 7) THEN
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
            IF(PROFILEMODE .EQ. 7) THEN
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
            IF(PROFILEMODE .EQ. 8) THEN
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
            IF(PROFILEMODE .EQ. 8) THEN
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
c	WRITE(*,'(A,I6)')' NUMBER OF ANTIDIAGONALS: ',NDIAGONAL
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

C         WRITE(6,*)' BESTVAL ',BESTVAL
C--------------------------------------------------------------------
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
C      DO I=1, N1-1
C         DO J=1 , N2-1
C            WRITE(6,*)'I,J,DIAG_LH(I,J) ',I,J,DIAG_LH(I,J)
C         ENDDO
C      ENDDO


      RETURN
      END              
C     END SETMATRIX_FAST
C......................................................................

