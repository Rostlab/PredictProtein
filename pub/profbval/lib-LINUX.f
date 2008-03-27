***** ------------------------------------------------------------------
***** SUB INIJCT
***** ------------------------------------------------------------------
C---- 
C---- NAME : INIJCT
C---- ARG  : 
C---- DES  : Generation of the initial couplings and biases of
C---- DES  : the network. Options: 
C---- DES  :    RANDOM : locfield (i,j,TIMEST=0) = [-/+diceintervall]
C---- DES  :             with equal distribution
C---- IN  p: NUMSAM,NUMIN,NUMHID,NUMOUT, DICESEED
C---- IN  v: JCT1ST,JCT2ND,BIAS1ST,BIAS2ND 
C---- OUT  : setting of JCT1ST, JCT2ND 
C---- FROM : MAIN
C---- CALL2: 
C---- LIB  : RAN(SEED), creates random numbers between 0 and    *
C---- LIB+ :           1 (1 excluded, 0 included), it is called by com-*
C---- LIB+ :           piling with -lV77, each call initializes next   *
C---- LIB+ :           seed, according to: seed=6909*seed+mod(2**32)   *
C---- 
*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     EMBL/LION			http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg	rost@embl-heidelberg.de                *
*	               changed:	June,       1998      version 0.2      *
*                      changed: Aug,        1998        version 1.0    *
*----------------------------------------------------------------------*
      SUBROUTINE INIJCT

C---- global parameters and variables
      INCLUDE       'nnPar.f'
C---- local variables
      INTEGER       I,J,NUMHIDFIRST,NUMHIDLAST
Cunix
C      REAL          RAN,DICE1,DICE2,DICEINTERVX
Clinux
      REAL          RAND,DICE1,DICE2,DICEINTERVX
******------------------------------*-----------------------------******
*     I,J                serve as iteration variables                  *
*     DICE1,2            =RAN(DICESEED1),i.e. random number between 0,1*
*     NUMHIDFIRST        number of units in the first hidden layer     *
*     NUMHIDLAST         number of units in the last hidden layer      *
******------------------------------*-----------------------------******

      DICEINTERVX=DICEITRVL

C---- ------------------------------------------------------------------
C---- first layer junctions 
C---- ------------------------------------------------------------------
      DICESEED1=DICESEED+DICESEED_ADDJCT
      IF (NUMLAYERS.EQ.1) THEN
         NUMHIDFIRST=NUMOUT
         NUMHIDLAST=0
      ELSE
         NUMHIDFIRST=NUMHID
         NUMHIDLAST=NUMHID
      END IF
C---- loop over hidden units
      DO I=1,NUMHIDFIRST
C------- junctions (loop over input units)
         DO J=1,NUMIN
C---------- generating random numbers from [0,1)
Cunix
C            DICE1= RAN(DICESEED1)
C            DICE2= RAN(DICESEED1)
Clinux
            DICE1= RAND(DICESEED1)
            DICE2= RAND(DICESEED1)
            IF (DICE1.LT.0.5) THEN
               JCT1ST(J,I)= (-1.)*DICEINTERVX*DICE2
            ELSE
               JCT1ST(J,I)= DICEINTERVX*DICE2
            END IF
         END DO
C------- thresholds (resp. biases)
C------- generating random numbers from [0,1)
Cunix
C         DICE1= RAN(DICESEED1)
C         DICE2= RAN(DICESEED1)
Clinux
         DICE1= RAND(DICESEED1)
         DICE2= RAND(DICESEED1)
         IF (DICE1.LT.0.5) THEN
            JCT1ST((NUMIN+1),I)=
     +           (-1.)*DICEINTERVX*DICE2
         ELSE
            JCT1ST((NUMIN+1),I)=DICEINTERVX*DICE2
         END IF
      END DO
C---- ------------------------------------------------------------------
C---- last layer junctions
C---- ------------------------------------------------------------------
      DO I=1,NUMOUT
C------- junctions
         DO J=1,NUMHIDLAST
C---------- generating random numbers from [0,1)
Cunix
C            DICE1= RAN(DICESEED1)
C            DICE2= RAN(DICESEED1)
Clinux
            DICE1= RAND(DICESEED1)
            DICE2= RAND(DICESEED1)
            IF (DICE1.LT.0.5) THEN
               JCT2ND(J,I)=(-1.)*DICEINTERVX*DICE2
            ELSE
               JCT2ND(J,I)=DICEINTERVX*DICE2
            END IF
         END DO
C------- thresholds (resp. biases)
C------- generating random numbers from [0,1)
Cunix
C         DICE1= RAN(DICESEED1)
C         DICE2= RAN(DICESEED1)
Clinux
         DICE1= RAND(DICESEED1)
         DICE2= RAND(DICESEED1)
         IF (DICE1.LT.0.5) THEN
            JCT2ND((NUMHID+1),I)=(-1.)*DICEINTERVX*DICE2
         ELSE
            JCT2ND((NUMHID+1),I)=DICEINTERVX*DICE2
         END IF
      END DO
      END
***** end of INIJCT

***** ------------------------------------------------------------------
***** SUB SRDTIME
***** ------------------------------------------------------------------
C---- 
C---- NAME : SRDTIME
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
***                                                                  ***
***                                                                  ***
***   SUBROUTINE SRDTIME                                             ***
***                                                                  ***
***                                                                  ***
*----------------------------------------------------------------------*
      SUBROUTINE SRDTIME(LOGIUNK,LOGIWRITE)

      IMPLICIT         NONE
Cunix
C      REAL             TIMEARRAYM,TIMEDIFF,DTIME,TIME_TMP
Clinux
      REAL             TIMEARRAYM(1:2),TIMEDIFF,DTIME
      INTEGER          ITER
      LOGICAL          LOGIWRITE,LOGIUNK

Cunix
C      TIMEDIFF=DTIME(TIMEARRAYM,TIME_TMP)
Clinux
      TIMEDIFF=DTIME(TIMEARRAYM)
C      TIMEDIFF= TIMEDIFFX(1)
      
      IF (LOGIWRITE) THEN
         WRITE(6,*)
         WRITE(6,'(T10,7A5)')('-----',ITER=1,7)
         WRITE(6,*)
         WRITE (6,'(T10,A12,T25,F9.3,A5)')
     +        'total time: ',TIMEDIFF,'  sec'
         WRITE(6,*)
         WRITE(6,'(T10,7A5)')('-----',ITER=1,7)
         WRITE(6,*)
      END IF

      END
***** end of SRDTIME

