#!/usr/bin/perl
## -----------------------------------------------------------------------------# 
#	Copyright				May,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 2.0   	Aug,    	1998	       #
# -----------------------------------------------------------------------------# 
# 
#   TOC of this document
#   
#   - (#1) phd.pl                internal subroutines:
#   - (#2) phd.pl                external subroutines:
#   - (#3) phd.pl                description of subroutines
#   - (#4) lib-phd.pl            internal subroutines:
#   - (#5) lib-phd.pl            external subroutines:
#   - (#6) lib-phd.pl            description of subroutines
#   
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   (#1) phd.pl                 internal subroutines:
#                               ---------------------
# 
#   MAIN                        
#   ini                         initialises defaults and reads input arguments
#   iniEnv                      initialises environment variables
#   iniDef                      sets defaults
#   iniDefPP                    sets defaults for user PP
#   iniHelpAdd                  initialise help text
#   iniHelpLoop                 loop over help 
#   iniHelp                     initialise help text
#   iniHelpRdItself             reads the calling perl script (scrName),
#   iniRdCmdLine                gets all command line arguments
#   iniSet                      final correction of parameters
#   iniError                    error check for initial parameters
#   iniWrt                      write initial settings on screen
#   abortProg                   soft exit: first deleting intermediate files
#   cleanUp                     delete temporary files
#   get_in_keyboardLoc          gets info from keyboard
#   sysGetUserLoc               returns $USER (i.e. user name)
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   (#2) phd.pl                 external subroutines:
#                               ---------------------
# 
#   call from lib-phd:          crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
# 
#   call from lib-br:           convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
# 
#   call from lib-ut:           complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
# 
#   call from other:            ctime, localtime
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------------
#   (#3) phd.pl                 description of subroutines:
#                               ---------------------------
#   --------------------------   
#   MAIN                        
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   ini                         initialises defaults and reads input arguments
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniEnv                      initialises environment variables
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniDef                      sets defaults
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniDefPP                    sets defaults for user PP
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniHelpAdd                  initialise help text
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniHelpLoop                 loop over help 
#       in/out:                 see iniHelp
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniHelp                     initialise help text
#       out:                    \d,txt
#       err:                    0,$msg  -> error
#       err:                    1,'fin' -> wanted help, given help
#       err:                    1,$msg  -> continue, was just trying
#       in:                     $tmp{} with
#                               $tmp{sourceFile}=  name and path of calling script
#                               $tmp{scrName}=     name of calling script (no .pl)
#                               $tmp{scrIn}=       input arguments for script
#                               $tmp{scrGoal}=     what script does
#                               $tmp{scrNarg}=     number of argument needed for script
#                               $tmp{scrHelpTxt}=  long blabla about script
#                                   separate by '\n'
#                               $tmp{scrAddHelp}=  help option other than standard
#                                   e.g.: "help xyz     : explain .xyz "
#                                   many: '\n' separated
#                                   NOTE: this will be an entry to $tmp{$special},
#                                   -> $special =  'help xyz' will give explanation 
#                                      $tmp{$special}
#                               $tmp{special}=     'kwd1,kwd2,...' special keywords
#                               $tmp{$special}=    explanation for $special
#                                   syntax: print flat lines (or '--- $line'), separate by '\n'
#                               $tmp{scrHelpHints}= hints (tab separated)
#                               $tmp{scrHelpProblems}= known problems (tab separated)
#       in GLOBULAR:            @ARGV
#                               $par{fileHelpOpt}
#                               $par{fileHelpMan}
#                               $par{fileHelpHints}
#                               $par{fileHelpProblems}
#                               $par{fileDefautlts}
#       in unk:                 leave undefined, or give value = 'unk'
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniHelpRdItself             reads the calling perl script (scrName),
#                               searches for 'sbr iniDef', and gets comment lines
#       in:                     perl-script-source
#       out:                    (Lok,$msg,%tmp), with:
#                               $tmp{"kwd"}   = 'kwd1,kwd2'
#                               $tmp{"$kwd1"} = explanations for keyword 1
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniRdCmdLine                gets all command line arguments
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniSet                      final correction of parameters
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniError                    error check for initial parameters
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   iniWrt                      write initial settings on screen
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   abortProg                   soft exit: first deleting intermediate files
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   cleanUp                     delete temporary files
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   get_in_keyboardLoc          gets info from keyboard
#       in:                     $des :    keyword to get
#       in:                     $def :    default settings
#       in:                     $pre :    text string beginning screen output
#                                         default '--- '
#       in:                     $Lmirror: if true, the default is mirrored
#       out:                    $val : value obtained
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
#   --------------------------   
#   sysGetUserLoc               returns $USER (i.e. user name)
#       out:                    USER
#       call lib-phd:           crossListCheck,crossManager,getFiles1Phd,getInputPhd
#                               getParaPhd1,wrtList,wrtRes1,wrtRes1merde1,wrtRes1merde2
#                               wrtRes1other,wrtScreenFin,wrtScreenHeader
#       call lib-br:            convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time,getFileFormat
#                               get_id,isDafGeneral,isDsspGeneral,isFasta,isFastaMul
#                               isFsspGeneral,isHsspGeneral,isMsfGeneral,isPir,isPirMul
#                               isRdbGeneral,isSaf,isSwissGeneral,is_hssp,is_hssp_empty
#                               myprt_empty,myprt_line,open_file,phdAliWrt,phdRun,phdRun1
#                               phdRunIniFileNames,phdRunPost1,phdRunWrt,rdbphd_to_dotpred
#       call lib-ut:            complete_dir,sysCpfile,sysDate,sysMvfile,sysRunProg
# -----------------------------------------------------------------------------# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   (#4) lib-phd.pl             internal subroutines:
#                               ---------------------
# 
#   crossCpArchis               copies architectures necessary according to fileIn
#   crossListCheck              checks whether or not protein used for training
#   crossListIn                 checks whether or not protein in training list
#   crossManager                manages the cross-validation option
#   getInputPhd                 converts the input file to HSSP format and filters
#   getFiles1Phd                builds command line input for calling phd.for
#   getParaPhd1                 gets local parameter file and updates it
#   getParaPhd1Update           local copy of PHD Para_file
#   wrtList                     writes a list of RDB files for EVALSEC
#   wrtRes1                     writes the output files for one protein prediction
#   wrtRes1merde1               filters the shit part 1 in the fortran output
#   wrtRes1merde2               filters the shit part 2 in the fortran output
#   wrtRes1other                PHD -> MSF|SAF, DSSP
#   wrtScreenHeader             write header onto screen
#   wrtScreenFin                write final words onto screen
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   (#5) lib-phd.pl             external subroutines:
#                               ---------------------
# 
#   call from lib-br:           convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
# 
#   call from lib-ut:           complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
# 
#   call from system:            
#                               \\cp $tmp_file* $tmp
#                               cp $para_ok_acc $tmp  
#                               cp $para_ok_sec $tmp 
#                               gunzip $tmp 
# 
#   call from phd:              abortProg
#                               
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------------
#   (#6) lib-phd.pl             description of subroutines:
#                               ---------------------------
#   --------------------------   
#   crossCpArchis               copies architectures necessary according to fileIn
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   crossListCheck              checks whether or not protein used for training
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   crossListIn                 checks whether or not protein in training list
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   crossManager                manages the cross-validation option
#      GLOBAL                   all
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   getInputPhd                 converts the input file to HSSP format and filters
#       in:                     $fileInLoc,$formatLoc
#       out:                    $Lok,$msg,$file,$chain
#       err:                    ok -> (1,"ok sbr"), err -> (0,"msg")
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   getFiles1Phd                builds command line input for calling phd.for
#       in/out GLOBAL:          ALL
#       out GLOBAL:             
#       out GLOBAL:             $FILE_PARA_SEC,$FILE_PARA_ACC,$FILE_PARA_HTM,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   getParaPhd1                 gets local parameter file and updates it
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   getParaPhd1Update           local copy of PHD Para_file
#                               + change directory of architectures in that
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   wrtList                     writes a list of RDB files for EVALSEC
#       out:                    1|0,msg,  implicit: list
#       err:                    (1,'ok'), (0,'message')
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   wrtRes1                     writes the output files for one protein prediction
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   wrtRes1merde1               filters the shit part 1 in the fortran output
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   wrtRes1merde2               filters the shit part 2 in the fortran output
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   wrtRes1other                PHD -> MSF|SAF, DSSP
#      GLOBAL                   all
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   wrtScreenHeader             write header onto screen
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
#   --------------------------   
#   wrtScreenFin                write final words onto screen
#       call lib-br:            convHssp2msf,convMsf2Hssp,errSbr,errSbrMsg,fctSeconds2time
#                               getPhdSubset,get_id,hsspRdAli,is_hssp,is_hssp_empty
#                               is_rdb_acc,is_rdb_htm,is_rdb_htmref,is_rdb_htmtop,is_rdb_sec
#                               is_rdbf,msfWrt,myprt_empty,myprt_line,myprt_npoints
#                               myprt_txt,open_file,phdAliWrt,rdRdbAssociative,rd_rdb_associative
#                               rdbphd_to_dotpred,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,safWrt,wrt_phdpred_from_string
#       call lib-ut:            complete_dir,run_program,sysCpfile,sysMvfile,sysRunProg
# 
# -----------------------------------------------------------------------------# 

