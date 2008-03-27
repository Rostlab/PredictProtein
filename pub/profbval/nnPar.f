*----------------------------------------------------------------------*
*     Burkhard Rost		May,        1998      version 0.1      *
*     EMBL/LION			http://www.embl-heidelberg.de/~rost/   *
*     D-69012 Heidelberg	rost@embl-heidelberg.de                *
*	               changed:	June,       1998      version 0.2      *
*----------------------------------------------------------------------*

***** ------------------------------------------------------------------
***** nnPar.f
***** ------------------------------------------------------------------
*     This file contains the parameters and variables for a particular *
*     run of program nn.f                                              *
C---- ------------------------------------------------------------------
      IMPLICIT      NONE
C---- ------------------------------------------------------------------
C---- PARAMETERS
C---- ------------------------------------------------------------------
C----                                number of command line arguments
      INTEGER       NUMARG_MAX
C----                                architecture of network
      INTEGER       NUMIN_MAX,NUMOUT_MAX,NUMHID_MAX
C----                                I/O-vectors (maximal number of sam)
      INTEGER       NUMSAM_MAX
C----                                error-back-propagation steps
      INTEGER       STPSWPMAX_MAX,STPMAX_MAX
C----                                number of input/output files
      INTEGER       NUMFILES_MAX
*----               -------------------------------------------------  *
C                                G  M  T

      PARAMETER    (NUMIN_MAX=          194)
      PARAMETER    (NUMOUT_MAX=           2)
      PARAMETER    (NUMSAM_MAX=      822700)
      PARAMETER    (NUMARG_MAX=         500)
      PARAMETER    (NUMHID_MAX=         500)
      PARAMETER    (NUMFILES_MAX=       336)
      PARAMETER    (STPSWPMAX_MAX=      200)
      PARAMETER    (STPMAX_MAX=    99999999)


C      CHARACTER     CTAB
C      PARAMETER    (CTAB=CHAR(9))

C---- ------------------------------------------------------------------
C---- CONSTANTS
C---- ------------------------------------------------------------------
C----                                architecture
      INTEGER       NUMLAYERS,NUMIN,NUMOUT,NUMHID,JCT_MAX,BITACC
C----                                back-propagation
      INTEGER       STPSWPMAX,STPMAX,STPINF,ERRBINSTOP
      REAL          TEMPERATURE,EPSILON,ALPHA,
     +              ERRBIAS,DICEITRVL,ERRSTOP,ERRBINACC
      CHARACTER*80  TRNTYPE,ERRTYPE,TRGTYPE
C----                                data handling
      INTEGER       DICESEED,DICESEED1,DICESEED_ADDJCT,DICESEED_ADDTRN
      REAL          ABW,INVABW,NEGINVABW,MAXCPUTIME,TIMEOUT
C----                                input/output
      LOGICAL       LOGI_RDPAR,LOGI_RDIN,LOGI_RDOUT,LOGI_SCREEN,
     +              LOGI_RDPARWRT,LOGI_RDINWRT,LOGI_RDOUTWRT,
     +              LOGI_RDJCTWRT,LOGI_TMPWRTOUT,LOGI_TMPWRTJB
C----                                general
      LOGICAL       LOGI_TRANSLATE(0:1)
C                                    for information, only!
      CHARACTER*80  MODEPRED,MODENET,MODEIN,MODEOUT,MODEJOB
*----               -------------------------------------------------  *
      COMMON /CON_ARCH/NUMLAYERS,NUMIN,NUMOUT,NUMHID,JCT_MAX,BITACC
      COMMON /CON_PROP1/TEMPERATURE,EPSILON,ALPHA,
     +              ERRBIAS,DICEITRVL,ERRSTOP,ERRBINACC
      COMMON /CON_PROP2/TRNTYPE,ERRTYPE,TRGTYPE
      COMMON /CON_PROP3/STPSWPMAX,STPMAX,STPINF,ERRBINSTOP
      COMMON /CON_DATA1/DICESEED,DICESEED1,
     +              DICESEED_ADDJCT,DICESEED_ADDTRN
      COMMON /CON_DATA2/ABW,INVABW,NEGINVABW,MAXCPUTIME,TIMEOUT
      COMMON /CON_IO1/LOGI_RDPAR,LOGI_RDIN,LOGI_RDOUT,LOGI_SCREEN,
     +              LOGI_RDPARWRT,LOGI_RDINWRT,LOGI_RDOUTWRT,
     +              LOGI_RDJCTWRT,LOGI_TMPWRTOUT,LOGI_TMPWRTJB
      COMMON /CON_GEN1/LOGI_TRANSLATE
      COMMON /CON_GEN2/MODEPRED,MODENET,MODEIN,MODEOUT,MODEJOB

C---- ------------------------------------------------------------------
C---- VARIABLES
C---- ------------------------------------------------------------------
C----                                main program
      INTEGER       LENPATH_ARCH
      CHARACTER*80  PATH_ARCH
      COMMON /MAIN1/LENPATH_ARCH
      COMMON /MAIN2/PATH_ARCH
C----                                managing command line input
      INTEGER       NUMARGUMENTS
      CHARACTER*80  PASSED_ARGC(1:NUMARG_MAX)
      LOGICAL       LOGI_INTERACTIVE,LOGI_SWITCH,LOGI_DEBUG
      COMMON /INUMARGC/PASSED_ARGC
      COMMON /INUMARGI/NUMARGUMENTS
      COMMON /INUMARGL/LOGI_INTERACTIVE,LOGI_SWITCH,LOGI_DEBUG
C----                                input files
      INTEGER       NUMFILEIN_IN,NUMFILEIN_OUT
      CHARACTER*132 FILEIN_PAR,FILEIN_JCT,FILEIN_SAM,
     +              FILEIN_IN(1:NUMFILES_MAX),FILEIN_OUT(1:NUMFILES_MAX)
C----                                output files
      INTEGER       NUMFILEOUT_JCT,NUMFILEOUT_OUT
      CHARACTER*132 FILEOUT_OUT(1:NUMFILES_MAX),
     +              FILEOUT_JCT(1:NUMFILES_MAX),
     +              FILEOUT_ERR,FILEOUT_YEAH
      COMMON /FILE1/FILEIN_PAR,FILEIN_IN,FILEIN_OUT,FILEIN_JCT,
     +              FILEIN_SAM,FILEOUT_OUT,FILEOUT_JCT,
     +              FILEOUT_ERR,FILEOUT_YEAH
      COMMON /FILE2/NUMFILEIN_IN,NUMFILEIN_OUT,
     +              NUMFILEOUT_JCT,NUMFILEOUT_OUT
*----               -------------------------------------------------  *
C----                                input vectors
      INTEGER       NUMSAM,NUMSAMFILE,MAXINPUT,POSWIN
      INTEGER*2     INPUT(1:(NUMIN_MAX+1),1:NUMSAM_MAX),
     +              OUTDES(1:NUMOUT_MAX,1:NUMSAM_MAX),
     +              OUTWIN(1:NUMSAM_MAX)
      REAL*4        OUTPUT(1:NUMOUT_MAX)
      COMMON /INVEC1/NUMSAM,NUMSAMFILE,MAXINPUT,POSWIN
      COMMON /INVEC2/INPUT,OUTDES,OUTWIN
      COMMON /INVEC3/OUTPUT
*----               -------------------------------------------------  *
C----                                junctions

C----                                for NUMLAYERS=1
C      REAL         JCT1ST(1:(NUMIN_MAX+1),1:NUMOUT_MAX),
C     +     DJCT1ST(1:(NUMIN_MAX+1),1:NUMOUT_MAX),
C     +     PDJCT1ST(1:(NUMIN_MAX+1),1:NUMOUT_MAX),
C     +     FLD1ST(1:NUMOUT_MAX)

C----                                for NUMLAYERS=2
      REAL          JCT1ST(1:(NUMIN_MAX+1),1:NUMHID_MAX),
     +              DJCT1ST(1:(NUMIN_MAX+1),1:NUMHID_MAX),
     +              PDJCT1ST(1:(NUMIN_MAX+1),1:NUMHID_MAX),
     +              FLD1ST(1:NUMHID_MAX)
      REAL          OUTHID(1:(NUMHID_MAX+1)),
     +              JCT2ND(1:(NUMHID_MAX+1),1:NUMOUT_MAX),
     +              DJCT2ND(1:(NUMHID_MAX+1),1:NUMOUT_MAX),
     +              PDJCT2ND(1:(NUMHID_MAX+1),1:NUMOUT_MAX),
     +              FLD2ND(1:NUMOUT_MAX)

      COMMON /ARCHJ/JCT1ST,DJCT1ST,PDJCT1ST,FLD1ST,OUTHID,
     +              JCT2ND,DJCT2ND,PDJCT2ND,FLD2ND

*----               -------------------------------------------------  *
C----                                back-propagation
      INTEGER       STPSWPNOW,STPNOW,STPINFNOW,STPINFCNT,
     +              PICKSAM(1:STPMAX_MAX),OKBIN(0:(STPSWPMAX_MAX+1))
      REAL          ERR(0:(STPSWPMAX_MAX+1)),
     +              ERRBIN(0:(STPSWPMAX_MAX+1))

      COMMON /PROP4/STPSWPNOW,STPNOW,STPINFNOW,STPINFCNT,PICKSAM,OKBIN
      COMMON /PROP5/ERR,ERRBIN
*----               -------------------------------------------------  *
C----                                interpretations
      REAL          THRESHOUT
      COMMON /MEANING1/THRESHOUT
*----               -------------------------------------------------  *
C----                                time
      CHARACTER*24  STARTDATE,ENDDATE
      CHARACTER*8   STARTTIME,ENDTIME
      REAL          TIMEDIFF,TIMEARRAY,TIMESTART,TIMERUN,TIMEEND
      LOGICAL       TIMEFLAG
      COMMON /CLOCK1/STARTDATE,ENDDATE,STARTTIME,ENDTIME
      COMMON /CLOCK2/TIMEARRAY,TIMEDIFF,TIMESTART,TIMERUN,TIMEEND
      COMMON /CLOCK3/TIMEFLAG
*                                                                      *
*----               -------------------------------------------------  *
C---- garbage variables in order to spare memory space (eqUIVALENCE..)
      LOGICAL       GARBAGEFLAG(1:(NUMSAM_MAX+100))
      COMMON /FLAG1/GARBAGEFLAG
C---- ------------------------------------------------------------------
***** end of nnPar
