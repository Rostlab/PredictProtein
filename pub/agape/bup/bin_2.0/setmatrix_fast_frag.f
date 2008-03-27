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

