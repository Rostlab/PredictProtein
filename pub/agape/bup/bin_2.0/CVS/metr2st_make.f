*----------------------------------------------------------------------*
*                                                                      *
*     FORTRAN code for program CONVERT_SEQ                             *
*             conversion of sequence and alignment formats             *
*                                                                      *
*----------------------------------------------------------------------*
*                                                                      *
*     Authors:                                                         *
*                                                                      *
*     Reinhard Schneider        May,        1994      version 1.0      *
*     LION			http://www.lion-ag/                    *
*     D-69120 Heidelberg	schneider@lion-ag.de                   *
*                                                                      *
*     &                                                                *
*                                                                      *
*     Burkhard Rost		May,        1994      version 1.1      *
*                   		Oct,        1998      version 2.0      *
*     EMBL/LION			http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg	rost@embl-heidelberg.de                *
*                                                                      *
*----------------------------------------------------------------------*
*                                                                      *
*     General note:   - uses library lib-maxhom.f                      *
*                                                                      *
*                                                                      *
*----------------------------------------------------------------------*

      PROGRAM MAKE_METRIC
* 
C     quick hack to produce structure/IO dependent metric used in MaxHom
*     
*     
*     
*     
************************************************************************
      IMPLICIT      NONE

C----
C---- parameters
C----
      INTEGER       NTRANS,NSTRMAX,NIOMAX,KOUT,KIN
      PARAMETER     (NTRANS=26,NSTRMAX=3,NIOMAX=3,KOUT=10,KIN=11)
      INTEGER       NSTR1,NSTR2,NIO1,NIO2,IL,IH,IB,IO,IE,N1,N2,N3,N4
C----
C----
C----
      CHARACTER     CTRANS*(NTRANS),CSTRUC*3,CIO*3
      REAL          STRVAL(NSTRMAX,NSTRMAX),IOVAL(NIOMAX,NIOMAX),
     +              VALUE(NTRANS)
      INTEGER       IORANGE(NIOMAX,NIOMAX)
      REAL          STRIOVAL(1:(NSTRMAX*NIOMAX),1:(NSTRMAX*NIOMAX))

      CHARACTER*5   CTEMP,CH
      INTEGER       ITEMP(3,3),IT1,IT2,IHVEC(1:9),FAC_STR,FAC_SEQ,
     +              ISTR1,IO1,I,ISTR2,IO2,J,MTRANS,NUMARGUMENTS

      CHARACTER*80  FILE_METRIC_SEQ,FILE_METRIC_OUT,FILE_METRIC_IN
      LOGICAL       LREAD_METRIC_IN,LHELP
      REAL          SIMSEQ(NTRANS,NTRANS,NSTRMAX,NIOMAX,NSTRMAX,NIOMAX),
     +              SIMSTR
C--------------------------------------------------
C----
C---- init defaults
C----
      FILE_METRIC_OUT='Make_metric_new.output'
      FILE_METRIC_SEQ=
     +     '/home/rost/pub/topits/mat/Maxhom_McLachlan.metric'
      FILE_METRIC_IN= 'Make_metric_new.input'
      ctrans='VLIMFWYGAPSTCHRKQENDBZX!-.'
C                                        read metric from file?
      LREAD_METRIC_IN=.FALSE.
      LREAD_METRIC_IN=.TRUE.
*                                                                      *
C--------------------------------------------------
C---- requesting input files:
C---- McLachlan (seq. metric) + file_in; file_out
C--------------------------------------------------
*                                                                      *
      CALL GET_ARG_NUMBER(NUMARGUMENTS)
      IF (NUMARGUMENTS.GT.0) THEN
         CALL GET_ARGUMENT(1,FILE_METRIC_IN)
      END IF
      IF (NUMARGUMENTS.GT.1) THEN
         CALL GET_ARGUMENT(2,FILE_METRIC_OUT)
      END IF
      IF (NUMARGUMENTS.GT.2) THEN
         CALL GET_ARGUMENT(3,FILE_METRIC_SEQ)
      END IF
      IF (NUMARGUMENTS.EQ.0) THEN
         WRITE(6,'(T2,A)')'---'
         WRITE(6,'(T2,A3,T10,A)')'----',
     +        'you can provide three input arguments:'
         WRITE(6,'(T2,A3,T10,A,T35,A)')'----','1: input metric def=',
     +        FILE_METRIC_IN
         WRITE(6,'(T2,A3,T10,A,T35,A)')'----','2: output metric def=',
     +        FILE_METRIC_OUT
         WRITE(6,'(T2,A3,T10,A,T35,A)')'----','3: sequence metric def=',
     +        FILE_METRIC_SEQ
         WRITE(6,'(T2,A)')'---'
      END IF
*                                                                      *
*                                                                      *
C percentage of match_struc / match_seq: 
C     (fac_str) * match_str + (10-fac_str) * match_seq
      FAC_STR=    10
C number of secondary structure and IO states
      NSTR1=       3
      NSTR2=       3
      NIO1=        2
      NIO2=        2
C define secondary structure states: E=beta , H=helix, L= NOT E or H
C      cstruc='ELH'
      CSTRUC='ELH'
      IE=INDEX(CSTRUC,'E')
      IL=INDEX(CSTRUC,'L')
      IH=INDEX(CSTRUC,'H')
C define match/mismatch between secondary structures states
C "ie,ie" = 3.0 ==> match between two residue in a beta strand
C give a value of 3.0
      STRVAL(IE,IE)=  4.0
      STRVAL(IE,IL)= -1.0
      STRVAL(IE,IH)= -4.0
      STRVAL(IL,IE)= -1.0
      STRVAL(IL,IL)=  1.0
      STRVAL(IL,IH)= -1.0
      STRVAL(IH,IE)= -4.0
      STRVAL(IH,IL)= -1.0
      STRVAL(IH,IH)=  4.0
C define IO states: B=buried , I=inside, O=ouside
C     cio='BIO'
      CIO='BO'
      IB=INDEX(CIO,'B')
C	ii=index(cio,'I')
      IO=INDEX(CIO,'O')
C define match/mismatch between IO states
C "ib,ib" = 3.0 ==> match between a buried residue with a buried residue
C give a value of 3.0
      IOVAL(IB,IB)=  4.0
C     IOVAL(IB,II)= -2.0
      IOVAL(IB,IO)= -2.0
C     IOVAL(II,IB)= -2.0
C     IOVAL(II,II)=  1.0
C     IOVAL(II,IO)= -2.0
      IOVAL(IO,IB)= -2.0
C     IOVAL(IO,II)= -2.0
      IOVAL(IO,IO)=  1.0
C define IO classes
C "ie,ib" = beta-strand + buried are residues with a %accessibility
C surface area below or equal to 5 percent (depndend on residue type)
      IORANGE(IE,IB)=  15
C     IORANGE(IE,II)=  16
      IORANGE(IE,IO)= 100
      IORANGE(IL,IB)=  15
C     IORANGE(IL,II)=  16
      IORANGE(IL,IO)= 100
      IORANGE(IH,IB)=  15
C     IORANGE(IH,II)=  16
      IORANGE(IH,IO)= 100

C--------------------------------------------------
C---- generate the sequence match matrix
C--------------------------------------------------
C----
C----
      CALL GETSIMMETRIC(NTRANS,CTRANS,NSTRMAX,NIOMAX,N1,N2,N3,N4,
     +     CTEMP,CTEMP,ITEMP,99,FILE_METRIC_SEQ,SIMSEQ)
C     -----------------

C--------------------------------------------------
C define match/mismatch between secondary structures and in/out
C        Eb Ee Lb Le Hb He 	
C    Eb   9  2  1 -6 -1 -8
C    Ee      7 -6  1 -8 -3
C    Lb         6 -1  1 -6
C    Le            4 -6  1
C    Hb               9  2
C    He                  7
C
C----
C E->x
      STRIOVAL(1,1)=  9.0
      STRIOVAL(1,2)=  2.0
      STRIOVAL(1,3)=  1.0
      STRIOVAL(1,4)= -6.0
      STRIOVAL(1,5)= -1.0
      STRIOVAL(1,6)= -8.0
      STRIOVAL(2,2)=  7.0
C----
C L->x
      strioval(3,3)=  6.0
      strioval(3,4)= -1.0
      strioval(4,4)=  4.0

C----
C symmetrie intuition
      STRIOVAL(2,3)=STRIOVAL(1,4)
      STRIOVAL(2,4)=STRIOVAL(1,3)
      STRIOVAL(2,5)=STRIOVAL(1,6)
      STRIOVAL(2,6)=STRIOVAL(1,5)
      STRIOVAL(3,5)=STRIOVAL(1,3)
      STRIOVAL(3,6)=STRIOVAL(1,4)
      STRIOVAL(4,5)=STRIOVAL(1,4)
      STRIOVAL(4,6)=STRIOVAL(1,3)
      STRIOVAL(5,5)=STRIOVAL(1,1)
      STRIOVAL(5,6)=STRIOVAL(1,2)
      STRIOVAL(6,6)=STRIOVAL(2,2)
C----
C symmetrie intuition
      DO IT1=1,6
         DO IT2=1,(IT1-1)
            STRIOVAL(IT1,IT2)=STRIOVAL(IT2,IT1)
         END DO
      END DO
      
C--------------------------------------------------
C read in factors and metric file?
C--------------------------------------------------
      IF (LREAD_METRIC_IN) THEN
         OPEN(KIN,FILE=FILE_METRIC_IN,STATUS='UNKNOWN',RECL=150)
         write(6,*)'--- read metric in'
         READ(KIN,'(A)',END=22114)CH
         write(6,'(A,T20,A)')'---',CH
         DO IT1=1,NSTR1*NIO1
            READ(KIN,'(A3,6I8)',END=22114)CH,
     +           (IHVEC(IT2),IT2=1,(NSTR2*NIO2))
            write(6,'(A5,I2,A1,A3,T20,6I6)')'read ',IT1,':',CH,
     +           (IHVEC(IT2),IT2=1,(NSTR2*NIO2))
            DO IT2=1,(NSTR2*NIO2)
               STRIOVAL(IT1,IT2)=IHVEC(IT2)/10.
            END DO
         END DO
         LHELP=.TRUE.
         DO WHILE (LHELP) 
            CH=' '
            READ(KIN,'(A)',END=22114)CH
            IF ( (CH(1:1).EQ.' ').OR.(CH(1:1).EQ.'*') ) THEN
               CONTINUE
            ELSEIF ( (CH(1:1).NE.'F').AND. 
     +               (CH(1:1).NE.'f') ) THEN
               write(6,*)'x.x ch=',ch(1:5)
               LHELP=.FALSE.
            ELSE
               BACKSPACE(KIN)
               READ(KIN,'(A8,I2)',END=22114)CH,FAC_STR
            END IF
         END DO
22114    CONTINUE
         CLOSE(KIN)

      END IF

c recompute factors
      FAC_SEQ=10-FAC_STR
         
C----------------------------------------------------------------------
C now summarise the setting
C----------------------------------------------------------------------

c write out onto printer
      WRITE(6,*)'--------------------------------------------------'
      WRITE(6,'(T5,A)')' '
      IF (LREAD_METRIC_IN) THEN
         WRITE(6,'(T5,A,T40,A)')'file containing metric asf.:',
     +        FILE_METRIC_IN
         WRITE(6,'(T5,A,T40,A)')'output will be in:',FILE_METRIC_OUT
         WRITE(6,'(T5,A)')'match = n*match_struc + (10-n)*match_seq '
         WRITE(6,'(T5,A,T20,I5)')'where n = ',FAC_STR
         WRITE(6,'(T5,A)')' '
      END IF
      WRITE(6,*)' '
      WRITE(6,*)'matrix generated:'
      WRITE(6,'(T10,6(A2,A1,A1,A2))')
     + '  ',cstruc(1:1),cio(1:1),'  ','  ',cstruc(1:1),cio(2:2),'  ',
     + '  ',cstruc(2:2),cio(1:1),'  ','  ',cstruc(2:2),cio(2:2),'  ',
     + '  ',cstruc(3:3),cio(1:1),'  ','  ',cstruc(3:3),cio(2:2),'  '
      DO ISTR1=1,NSTR1
         DO IO1=1,NIO1
            IT1=(ISTR1-1)*NIO1+IO1
            WRITE(6,'(A1,A1,T10,6F6.2)')
     +           CSTRUC(ISTR1:ISTR1),CIO(IO1:IO1),
     +           (STRIOVAL(IT1,IT2),IT2=1,(NSTR2*NIO2))
         END DO
      END DO
      WRITE(6,*)' '
      WRITE(6,*)'--------------------------------------------------'

C----------------------------------------------------------------------
C now write into file
C----------------------------------------------------------------------

      OPEN(KOUT,FILE=FILE_METRIC_OUT,STATUS='UNKNOWN',RECL=250)
C write header info
      WRITE(KOUT,'(A)')'#========================================='//
     +                   '=========================================='//
     +                   '=========================================='//
     +                   '==============='
      WRITE(KOUT,'(A,I3)')'STRUCTURE-STATES_1:',NSTR1
      WRITE(KOUT,'(A,I3)')'STRUCTURE-STATES_2:',NSTR2
      WRITE(KOUT,'(A,I3)')'I/O-STATES_1:',NIO1
      WRITE(KOUT,'(A,I3)')'I/O-STATES_2:',NIO2
      WRITE(KOUT,'(A)')'DSSP-STRUCTURE   I/O    %ACC-RANGE '//
     +                   '(<= less or equal)'
C write ranges for accessibility classes
      DO ISTR1=1,NSTR1
         DO IO1=1,NIO1
            WRITE(KOUT,'(4X,A,13X,A,7X,I3)')CSTRUC(ISTR1:ISTR1),
     +           CIO(IO1:IO1),IORANGE(ISTR1,IO1)
         ENDDO
      ENDDO

C write seperator lines
      WRITE(KOUT,'(A)')'#========================================='//
     +                   '=========================================='//
     +                   '=========================================='//
     +                   '==============='
      WRITE(KOUT,'(A)')'AA STR I/O  V     L     I     M     F     '//
     +                   'W     Y     G     A     P     S     T     '//
     +                   'C     H     R     K     Q     E     N     '//
     +                   'D     B     Z'
C write metric
      MTRANS=22
      DO I=1,MTRANS
         DO ISTR1=1,NSTR1
            DO IO1=1,NIO1
               DO ISTR2=1,NSTR2
                  DO IO2=1,NIO2
C---                                    old version: combine HEL be
C                       SIMSTR=
C     +                      strval(istr1,istr2) + ioval(io1,io2)
C---                                    new version: 6x6 matrix
                     SIMSTR=STRIOVAL( ((ISTR1-1)*NIO1+IO1), 
     +                    ((ISTR2-1)*NIO2+IO2) )

                     DO J=1,22 
C F*struc + (10-F)*seq
                        VALUE(J) = (FAC_STR/10. * SIMSTR) +
     +                       (FAC_SEQ/10. * SIMSEQ(I,J,1,1,1,1))
                        
                        IF (VALUE(J) .GE.  10.0) VALUE(J)=9.99
                        IF (VALUE(J) .LE. -10.0) VALUE(J)=-9.99


                     ENDDO
                     WRITE(KOUT,'(1X,A,2X,A,A,1X,A,A,1X,22(F5.2,1X))')
     +                    CTRANS(I:I),CSTRUC(ISTR1:ISTR1),
     +                    CSTRUC(ISTR2:ISTR2),CIO(IO1:IO1),
     +                    CIO(IO2:IO2),
     +                    (VALUE(J),J=1,22)
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
      END

