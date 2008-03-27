#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
#
#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system # 
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost		rost@columbia.edu			                  #
# http://cubic.bioc.columbia.edu/~rost/	                                          #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu  	                          #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu        	                  #
#                                                                                 # 
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 # 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #   
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            # 
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               # 
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#------------------------------------------------------------------------------   #
#	Copyright				  Dec,    	 1994	          #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			          #
#	Antoine de Daruvar	daruvar@lion-ag.de                                #
#	Guy Yachdav             yachdav@cubic.bioc.columbia.edu  	          #
#	EMBL			http://www.embl-heidelberg.de/~rost/	          #
#	D-69012 Heidelberg						          #
#			    br  v 0.2   	  Aug,           1995             #
#			    br  v 0.5   	  Mar,           1996             #
#			    br  v 1.0             Mar,           1997             #
#			    br  v 2.0a            Apr,           1998             #
#			    br  v 2.1             Jan,           1999             #
#------------------------------------------------------------------------------   #
# 
# This file contains all (or almost all) environment variables necessary to 
#    execute the server, and all programs called.
# 
# Local subroutines:
#  - getLocal():     returns the current value of a given parameter
#  - isRunningEnv(): returns the number of scanners running
# 
#--------------------------------------------------------------------------------- #

package envPP;

INIT:{

    # ================================================================================
    # setting up all parameters
    # GLOBAL in: 
    # 
    #    $LisLocal = 1 -> then assumed to run everything in local directory
    #              = 0 -> all in GLOBAL working dir
    #                      note: set to 1 if $ENV{'PPENV'} defined!
    # ================================================================================

    $[=1;			# count from 1

                                # ==================================================
                                # determine the working directory
                                # ==================================================
    $LisLocal=0; $LisLocal=1    if ($ENV{'PPENV'} && $ENV{'PWD'});
    if ($LisLocal) {		# local
	$dirScriptTmp=$ENV{'PPENV'}; $dirScriptTmp=~s/[^\/]*$//g;
	$dirWork=$dirScriptTmp; $dirWork.="/" if ($dirWork !~/\//);
	$tmp=$dirWork."work";
	$dirWork=$tmp           if (-d $tmp); 
	$dppScrSrv=$dirScriptTmp;}
    elsif ($ENV{'PPWORKDIR'}) {	# taken from ENV
	$dirWork= $ENV{'PPWORKDIR'}; }
    else {			# HARD_CODED ..
	$dirWork="/nfs/data5/users/$ENV{USER}/server/work/"; } # HARD_CODED ..

				# ------------------------------
				# change for local execution
				# ------------------------------
    if ($LisLocal){ $dppPrd=$dppRes=$dppMail=
			$dirWork;
		    $dppScr=$dirScriptTmp;}


				# --------------------------------------------------
				# primary directories
				# --------------------------------------------------

    $dppHome=       "/nfs/data5/users/$ENV{USER}/server/";           # central directory for server
    $dirWork=       $dppHome."work/";      # HARD_CODED ..
#    $tempWorkStr =  "echo $dirWork >> /nfs/data5/users/ppuser/tempLogFile";
#    system($tempWorkStr);
    $dppWWW=        $dppHome;                      # www stuff
				                   #    other day to avoid eating disk space)
	                                           # note: cgi scripts only used in WWW HTML pages!
    $dppWWWcgi=     "/nfs/data5/users/www/cgi/pp/";	   # www cgi-scripts (links)
    $dppWWWdoc=     $dppWWW."doc/";                # www documents
    $dppData=       "/nfs/data5/users/$ENV{USER}/server/data/";      # all protein data
    $dppMolbio=     "/usr/pub/molbio/";
#Merged Additions 2003_08-24
    $dppHome=      "/nfs/data5/users/$ENV{USER}/server/";	           # central directory for server

    $dppWWW=       $dppHome;                       # www stuff 
    $dppWWWcgi=    "/nfs/data5/users/httpd/cgi/pp/";	           # www cgi-scripts (links)
    $dppData=      "/nfs/data5/users/$ENV{USER}/server/data/";       # all protein data
    $dppPpLoc=     "/nfs/data5/users/$ENV{USER}/locpp/";       # pplocal home
#End merge
				# --------------------------------------------------
                                # dependent directories
				# --------------------------------------------------
				# web documents
				# ------------------------------
    $dppWWWdoc=     $dppWWW.    "www_doc/";        # www HTML pages
    $dppWWWdemo=    $dppWWW.    "www_demo/";       # www demo
    $dppWWWlog=     $dppWWW.    "www_doc/Dlog/";   # log for PP status

				# ------------------------------
				# ftp'able result directory
				# ------------------------------
# IRIX http serv arch
#    #$dppResPub=    "/nfs/data5/users/www/htdocs/pp_res/"; # dir with all results stored for users
				             #    rather than sending a mail!
# LINUX http serv arc
    $dppResPub=    "/nfs/data5/users/httpd/html/pp_res/";     # dir with all results stored for users
				            #    rather than sending a mail!
				# ------------------------------
				# working on it
				# ------------------------------
    $dppRun=        $dppHome;	             # working files, logs, asf
  #  $dppRunDodo=   $dppHomeDodo;
#    $dppXch=        $dppRun.    "xch/";      # files for communication (input, output)

    $dppXch=        $dppRun.    "xch/";      # files for communication (input, output)
   # $dppXchDodo =  $dppRunDodo. "xch/";
#    $dppBup=        $dppRun.    "bup/";      # back up of run files

    $dppBup=        $dppRun.    "bup/";      # back up of run files
    $dppErr=        $dppBup.    "err/";      # dir with bup of errors

    $dppTrash=     "/nfs/data5/users/$ENV{USER}/server/bup/trash/";  # trash (overflow of files, clean every


    $dppLog=        $dppRun.    "log/";      # all log files
				             # NOTE: MUST be writable for WWW
                                             #       (or change wwwPredict)

				# communication (input, output files)
    
    $dppPrd=        $dppXch.    "prd/";      # put files from cgi script OR email
				             #       (procmail)
#    $dppPrdDodo=  $dppXchDodo. "prd/";       # MERGED
				             # NOTE: MUST be writable for WWW
                                             #       (or change wwwPredict)
    $dppRes=        $dppXch.    "res/";      # dir with all results

    $dppResPub=     $dppXch.    "res_pub/";   # dir with all results stored for users
				             #    rather than sending a mail!
	                                     # files will be moved to maple's web dir

    $dppResLocPP   = "/nfs/data5/users/ppuser/nesg/work/";   #  HACK (GY 11/2004)
                                                  #  dir with the results of local pp run
    				                  # the scanner on the web machine will pick the 
                                                  # the result file and dump it to an appropriate directory


    $dppResGT   = "/nfs/data5/users/ppuser/server/xch/genetegrate/res/";   #  HACK (GY 11/2005)
                                                                  #  dir with the results of genetegrate run
    				                                  # the scanner on the web machine will pick the 
                                                                  # the result file and dump it to an appropriate directory
  #  $dppResDodo=   $dppXchDodo. "res/";      # MERGED

   # $dppResPubDodo= $dppXchDodo."res_pub/";  # MERGED


    $dppLicense=    $dppXch.    "lic/";      # dir with all results
				             # NOTE: MUST be writable for WWW  
                                             #       (or change wwwPredict)
    $dppMail=       $dppXch.    "mail/";     # all outgoing stuff
				             # NOTE: MUST be writable for WWW  
                                             #       (or change wwwPredict)
  #  $dppMailDodo=  $dppXchDodo. "mail/";     # MERGED
    $dppInProc=     $dppXch.     "inProc/";  # dir with procmail stuff 
                                             #       (temp, while procmail works)
				# ------------------------------
				# PP scripts
				# ------------------------------
    $dppScr=        $dppHome;                # sources, programs
				             # all server specific scripts
    $dppScrSrv=     $dppScr.    "scr/" if (! defined $dppScrSrv || ! $dppScrSrv);
    $dppScrBin=     $dppScr.    "bin/";      # all binaries

    $dppScrLib=     $dppScrSrv. "lib/";	     # perl libraries

				# note: cgi scripts only used in WWW HTML pages!
#    $dppScrCgi=    $dppScrSrv.  "www/";      # www cgi-perl scripts

#    $dppScrMail=   $dppScrSrv.  "ut/";       # procmail scripts: note only for .procmail!!!
    $dppScrTxt=     $dppScrSrv. "txt/";	     # all kinds of blabla
    $dppScrUt=      $dppScrSrv. "ut/";       # utilities for server scripts
				# ------------------------------
				# other programs
				# ------------------------------
    $dppScrPub=     $dppScr.    "pub/";	     # central site for programs run
    $dppPrgPhd=     $dppScrPub. "phd/";	     # PHD
    $dppPrgProf=    $dppScrPub. "prof/";     # PROF
    $dppPrgTopits=  $dppScrPub. "topits/";   # TOPITS
    $dppPrgEvalsec= $dppScrPub. "evalsec/";  # EvalSec
    $dppPrgThreader=$dppScrPub. "threader/"; # Dudek's threader

				             # note: GLOBE is subroutine of PHD at moment
#    $dppPrgGlobe=  $dppScrPub.  "globe/";   # Globe

    $dppPrgMax=     $dppScrPub. "max/";	     # MaxHom
    $dppPrgBlastp=  $dppScrPub. "blastp/";   # BlastP
    $dppPrgBlastPsi=$dppScrPub. "blastpsi/"; # BlastPSI

    $dppPrgProsite= $dppScrPub. "prosite/";  # Prosite
    $dppPrgProdom=  $dppScrPub. "prodom/";   # ProDom
    $dppPrgCoils=   $dppScrPub. "ncoils/";   # Coils
    $dppPrgMview=   $dppScrPub. "mview/";    # MView
#    $dppPrgCyspred= $dppScrPub.	"cyspred/";  # cyspred
    $dppPrgDisulfind= $dppScrPub.	"disulfind/";  # disulfind
    $dppPrgNls=     $dppScrPub. "nls/";	     # NLS 
    $dppPrgAsp=     $dppScrPub. "asp/";	     # ASP
    $dppPrgNors=    $dppScrPub. "nors/";     # NORS
    $dppPrgDssp=    $dppMolbio. "dssp/";     # DSSP
    $dppPrgPfam=    $dppMolbio. "bin/"; # PFAM

    # GY Added 2004_01_30
    $dppPrgProfCon    = $dppScrPub.	"profcon/";                    # profcon
    $dppPrgPrenup     = $dppScrPub.	"prenup/";                    # prenup
    $dppPrgEcgo        = $dppScrPub.	"ecgo/";                    # ecgo
    $dppPrgPcc        = $dppScrPub.	"pcc/";                        # predict cell cycle
    $dppPrgChop       = $dppScrPub.	"chopper/";                       # CHOP
    $dppPrgChopper    = $dppScrPub.     "chopper/";                    # CHOPPER
    $dppPrgIsis       = $dppScrPub.	"isis/";                       # ISIS
    $dppPrgProfBval   = $dppScrPub.	"profbval/";                   # PROFbval
    $dppPrgSnap   =    $dppScrPub.	"snap/";                                # snap
    $dppPrgProfTmb    = $dppScrPub.	"proftmb/";                    # proftmb
    $dppPrgLocTar      = $dppScrPub.	"LOCtarget_v1/";               # locTarget
    $dppPrgAgape       = $dppScrPub.	"agape/";                      # Agape 
#    $dppPrgAgape       = "/nfs/home5/dudek/server/pub/agape/";              # Agape 
    $dppPrgNLProt       = $dppScrPub.	"nlprot/";                       # NL-Prot
    $dppPrgConBlast     = $dppScrPub.   "conblast/";                     # conblast
    $dppPrgR4S          = $dppScrPub.	"consurf/";                       # ConSurf


                                # ============================================
                                # determine current system ARCHITECTURE
                                # ============================================
    open (ARCHFILE, $dppScrUt."pvmgetarch.sh |") ||  # HARD_CODED
	# default to LINUX arch
	do { $ARCH="LINUX";
	     warn "*** WARN envPP: failed executing $dppScrUt.pvmgetarch.sh!!"; };
	#default to SGI32
#    do { $ARCH="SGI32";
	#     warn "*** WARN envPP: failed executing $dppScrUt.pvmgetarch.sh!!"; };

    while (<ARCHFILE>) { chop;
			 $ARCH= $_; 
			 last;}close(ARCHFILE);
				# hack: br 98-04
    $ARCH="ALPHA"               if (! defined $ARCH);	# HARD_CODED: problem with stork (procmail)

                                # ============================================
                                # define all architecture dependant parameters
                                # ============================================
    %Arch_exe_ps=        (	# ps command
			  'SGI32',           "ps -ef",
			  'SGI64',           "ps -ef",
			  'ALPHA',           "ps -ef",
			  'LINUX',           "ps -efl",
			  'SUNMP',           "ps -awux");
    %Arch_exe_quota=     (	# quota command
			  'SGI32',           "quota -v",
			  'SGI64',           "rsh birdie 'quota -v'",
			  'ALPHA',           "/usr/sbin/quota -v'",
			  'LINUX',           "quota -v",
			  'SUNMP',           "quota -v");
    %Arch_exe_du=        (	# du (disk usage) command
			  'SGI32',           "/usr/local/bin/du -ks",
			  'SGI64',           "/usr/local/bin/du -ks",
			  'ALPHA',           "/usr/local/bin/du",
			  'LINUX',           "du -ks",
			  'SUNMP',           "du");
    %Arch_exe_mail=      (	# mail command
			  'SGI5',            "/usr/sbin/Mail", # mainly for stork (procmail)
			  'SGI32',           "/usr/sbin/Mail",
			  'SGI64',           "/usr/sbin/Mail",
			  'ALPHA',           "/usr/bin/Mail",,
			  'LINUX',           "/bin/mail",
			  'SUNMP',           "/usr/ucb/Mail");
    %Arch_exe_nice=      (	# nice
			  'SGI5',            " ",
			  'SGI32',           " ",
			  'SGI64',           " ",
			  'LINUX',           " ",
			  'ALPHA',           "nice -10",
			  'SUNMP',           " ");

    # ========================================================================
    # define all the environment parameters in an associative array %Local_env
    # ========================================================================

    %envL=(			# PP: stuff
	   'ARCH',              $ARCH, # system architecture
				# candidate for prediction (machine:ps cmd:nb occ;...)
#	   'machines',          "parrot:ps -ef:1",
#	   'machines',          "dodo:ps -ef:1",
#	   'machines',          "tau:ps gw:2;alpha1:ps gw:1",

#	   'machines',          "dodo:ps -ef:14",
#	   'machines',          "dodo:ps -ef:10",
#	   'machines',          "dodo:ps -ef:6",
#	   'machines',          "dodo:ps -ef:8",
	   'machines',          "localhost:ps -ef:8",

#	   'pp_admin',          "ppadm\@embl-heidelberg.de",        # email PP administrator
#	   'pp_admin',          "phd2\@embl-heidelberg.de",         # email PP administrator
#	   'pp_admin',          "rost\@embl-heidelberg.de",         # email PP administrator
	   'pp_admin',          "pp_admin\@columbia.edu",         # email PP administrator
				# flag for PP_manager send errors or not?

#	   'pp_admin_sendWarn', "no",  # no warning
	   'pp_admin_sendWarn', "yes", # send warning

	   'password_def',      "pwd", # default password

				# --------------------------------------------------
				# PP: executables
				# --------------------------------------------------
				# system stuff
#	   'exe_batch_queue',   "/usr/local/lsf/bin/bsub",          # batch queue, br: 97-12 not used)
	   'exe_quota',         $Arch_exe_quota{$ARCH},              # unix quota command
	   'exe_ps',            $Arch_exe_ps{$ARCH},                 # unix ps command
	   'exe_nice',          $Arch_exe_nice{$ARCH},               # unix nice command
	   'exe_mail',          $Arch_exe_mail{$ARCH},               # unix mail (send) command
  
#	   'exe_tar',           "/usr/local/bin/tar",                # unix tar command
	   'exe_tar',           "/bin/tar",                         # unix tar command
	   'exe_find',          "/usr/local/bin/find",               # unix find command
	   'exe_find',          "/usr/bin/find",                     # unix (LINUX) find command
	   'exe_du',            $Arch_exe_du{$ARCH},                 # unix du command

	   'exe_mailHtml',      $dppScrUt.   "emailSendHtml.pl",     # script for attaching HTML
				                                     #    results to mail

				# scripts      
	   #changed by GY to start unique process 2003_08_25
#	   'exe_ppScanner',     $dppScrSrv.  "scannerPP_GY.pl",         # PP scanner: endless running and 
	   'exe_ppScanner',     $dppScrSrv.  "scannerPP.pl",         # PP scanner: endless running and 
				                                     #    managing!
	   'exe_ppScannerDB',            $dppScrSrv.  "scannerDB.pl",         # DB scanner: endless running 
	   'exe_ppGetCachedResults',     $dppScrSrv.  "getCachedResults.pl",  # get preprocessed results using md5 id
	  # end changes  2003_08_25

	   #ppLocal
	   'dir_pplocal_home',  $dppPpLoc,
           #end pplocal			
	   
	   'exe_ppPredict',     $dppScrSrv.  "predictPP.pl",         # manager for running predictions 

	   'exe_ppEmailproc',   $dppScrSrv.  "emailProcPP.pl",       # gets mail from procmail, 
				                                     #  + generates required file,
				                                     #  + puts it into run/prd
				# packages
	   'pack_predict',      $dppScrLib.  "predictPP.pm",         # runs the predictions
	   'pack_licence',      $dppScrLib.  "licencePP.pm",         # checks for licence (called by predict)

	   'lib_pp',            $dppScrLib.  "lib-pp.pm",            # PP specific perl lib to link
				# note: only for predict.pm!
	   'lib_col',           $dppScrLib.  "lib-col.pm",           # general perl lib to link
				# note: only for predict.pm!
	   'lib_err',           $dppScrLib.  "lib-err.pm",           # PP specific perl lib to link
	   'lib_cgi',           $dppScrLib.  "cgi-lib.pm",           # general perl lib for HTML to link
	   'lib_ctime',         $dppScrLib.  "ctime.pm",             # general perl lib for ctime

				# utilities
	   'exe_stripstars',    $dppScrUt.   "stripstars.pl",        # get rid of too many stars in output
	   'exe_scan_clean',    $dppScrUt.   "scanCleanUp.pl",       # clean up directories 
				                                     #   - remove expired
				                                     #   - shorten log
	   'exe_status',        $dppScrUt.   "wwwStatusPP.pl",       # writes status file for WWW display
#	   'exe_svcSubmitter',  $dppPpLoc.   "submit2Svcs.pl",       # script to submit to third party services

                                # ----------------------------------------
				# PERL SCRIPTS AND PACKAGES
                                # ----------------------------------------
				# --------------------------------------------------
				# PP: directories
	   'dir_pp_home',       $dppHome,        # home path
	   'dir_default',       $dppHome,        # where file might be created by default
#	   'dir_pp_home_dodo',  $dppHomeDodo,    # home in dodo, NFS #MERGED
	   'dir_work',          $dirWork,        # intermediate files to put here
				                 # NOTE: MUST be writable for WWW!!!
	   'dir_prd',           $dppPrd,         # files to be run by prediction
	   #'dir_prd_dodo',      $dppPrdDodo,     # dir_prd in dodo, run by dodo
	   'dir_res',           $dppRes,         # files with results
				                 # NOTE: MUST be writable for WWW!!!
#	   'dir_res_dodo',      $dppResDodo,     # files with results in dodo
				                 # NOTE: MUST be writable for WWW!!!


	   'dir_lic',           $dppLicense,     # files with licenses
				                 # NOTE: MUST be writable for WWW!!!


	   'dir_resPub',        $dppResPub,      # files with results visible on WWW, or ftp
#	   'dir_resPubDodo',    $dppResPubDodo,  # file with results visible on WWW, or ftp in dodo
           'dir_resLocPP',      $dppResLocPP,    # files with results for pplocal
	   'dir_resGT',         $dppResGT,       # files with results for Genetegrate
	   'dir_mail',          $dppMail,        # where to place the mail query and result
	   'dir_inProcmail',    $dppInProc,      # where procmail-stork.pl puts mail input

	   'dir_ut_txt',        $dppScrTxt,      # text files
	   'dir_ut_perl',       $dppScrUt,       # perl utilities, programs, asf

	   'dir_www_doc',       $dppWWWdoc,      # WWW pages (used for joinPPhelp.pl script)

				# dir_trash will die yyDO_ONE_DAY
	   'dir_trash',         $dppTrash,       # temporary trace
	   'dir_bup_res',       $dppBup."res",   # temporary save of all files
	   'dir_bup_errIn',     $dppBup."errIn", # temporary trace
	   'dir_bup_err',       $dppBup."err",   # temporary trace
	   'dir_bup_errMail',   $dppBup."errMail",
	   'dir_bup_lic',       $dppBup."lic",
				# dir_err will die yyDO_ONE_DAY
	   'dir_err',           $dppErr,          # where to put files in case of error
	   'dir_demo',          $dppWWWdemo,      # www demo

				# --------------------------------------------------
				# PP: files
				# --------------------------------------------------
	   'file_scanFlag',     $dppRun.      "PPscan.flag",         # flags activity of scanner
	   'file_scanLog',      $dppLog.      "scan.log",            # requests found by scanner
	   'file_ppLog',        $dppLog.      "phd.log",             # all requests
	   'file_comLog',       $dppLog.      "phd_com_pred.log",    # commercial predictions
	   'file_errLog',       $dppLog.      "ERROR.log",           # general errors
	   'file_predMgrLog',   $dppLog.      "out-predManager.log", # log for predManager.pl
	   'file_sendLog',      $dppLog.      "emailSend.log",       # log of email sent
	   'file_emailReqLog',  $dppLog.      "pred-email.log",      # log of email requests
	   'file_emailProcLog', $dppLog.      "emailProc.log",       # log of processing email
	   'file_procmailLog',  $dppLog.      "PROCMAIL.log",        # log of procmail
				# NOTE: named by .procmailrc !!!
	   'file_procmailInLog',$dppLog.      "procmail-in.log",     # log of procmail

				# NOTE: for WWW access MUST be writable (or change wwwPredict)
#	   'file_htmlReqLog',   $dppLog.      "pred-html.log",       # log of HTML requests
#	   'file_htmlReqLog',   $dppLog.      "pred-html2.log",      # log of HTML requests
	   'file_htmlReqLog',   $dppWWWlog.   "pred-html.log",       # log of HTML requests
	   'file_htmlCgiLog',   $dppLog.      "cgi.log",             # log of CGI activity
	   # MERGED
	   'file_cgi_user_log', $dppLog.      "cgi_user.log",        # log of CGI user
	   # END Of Merge

	   'file_licenceComLog',  $dppLog.    "licenceCom.log",      # log of licence control
				                                     # -> assumed to be com
	   'file_licenceNotLog',  $dppLog.    "licenceNot.log",      # log of licence control
				                                     # -> assumed NOT com
	   'file_badGuy',       $dppLog.      "BAD_guy.rdb",          # counts unlicensed users
	   'par_num4badGuy',    "5",                                 # requests allowed for bad ones
	   'flag_badGuy',       $dppLog.      "FLAG_writes_badGuy",  # is writing
	   
	   'file_crontabLog',   $dppLog.      "crontab.log",	     # log of crontab job
	   'file_batchLog',     $dppLog.      "bqueue.log",          # batch queue out file

	   'file_htmlLicOrd',   $dppWWWdoc.   "doc/license_payFax.html",  # html licence order file
	   'file_htmlLicCond',  $dppWWWdoc.   "doc/license_cond.html",   # licence condition

#	   'file_licence',      $dppLog.      "phd_licence",         # list of commercial licences
	   'file_licence',      $dppLog.      "licenseGiven.rdb",    # list of commercial licences
	   'file_licenceGiven', $dppLog.      "licenseGiven.rdb",    # list of commercial licences
	   'file_licenceCount', $dppLog.      "licenseCount.rdb",    # counts no of usage for com
	   'flag_licenceCount', $dppLog.      "FLAG_writes_licenceCount",
				                                     # flag to indicate that
				                                     #  licensePP writes
	   'file_licNew',       $dppLicense.  "TMP_phd_licNew",      # temporary file
	   'file_licFlag',      $dppLicense.  "TMP_flag_writing",    # flags that is writing now!

	   'file_key',          $dppLog.      "phd_key",             # file of user key 
	   'file_scanOut',      $dppLog.      "scan.out",	     # redirection of scanner output
	   'file_scanMach',     $dppLog.      "scan.machine",        # couple machine/job id
	   'file_scanErr',      $dppLog.      "scan.err",            # redirection of scanner error
	   'file_statusLog',    $dppWWWlog.   "PPstatus.log",        # WWW readable file with Status
	   'file_statusHis',    $dppWWWlog.   "PPstatus.history",
	   'file_statusAdd',    $dppWWWlog.   "PPstatus.add",
	   'file_statusFlag',   $dppWWWlog.   "PPstatus.flag",       # flag to avoid double writing 

	   'file_htmlFmtErr',   $dppScrTxt.   "app/WrgFormatHtml",   # html format error

	   'file_sorryTimeout', $dppScrTxt.   "app/SorryTimeout",    # to user if no result after 2 days
	   'file_cleanUpLog',   $dppLog.      "cleanUp.log",         # dump from cleanUpPP.pl
	   'file_releaseLockLog', $dppLog.    "releaseLock.log", # log file for removing outdated lockfiles to keep queue going

	   'file_methodwwwDoc',  $dppWWWdoc.   "doc/methodsPP.html",
	   'file_methodTemplate',$dppScrTxt.   "wwwMethods.rdb",
	   'file_methodMetaRel',               "explain_meta.html",

				# --------------------------------------------------
				# PP: prefix and suffix for files
				# --------------------------------------------------
	   'prefix_prd',        "pred",	     # files in server/prd  called pred_ID
				             #    -> scannerPP.pl 
	   'par_patDirPred',    "pred_",     # files in dir_prd 'pred_e|h*'
				             #    -> emailPredPP.pl
				             #    -> scannerPP.pl 
	   'prefix_work',       "predict",   # files in server/work called predict_ID
				             #    -> scannerPP.pl 
	   'suffix_mail',       "_query",    # files in server/mail called pred_ID_query
				             #    -> scannerPP.pl 
	   'suffix_res',        "_done",     # files in server/res  called pred_ID_done
	   'suffix_lock',	"_lock",     # lock file ended with "_lock"
				             #    -> scannerPP.pl 
	   'prefix_fileBupTar', "prd_",	     # files created to save space
	   'prefix_lic',        "license_",  # files with license written by
				             #       license.cgi (server/scr/www)
	   'pattern_lic',       "HEADER_LICENSE",
				             # keywords will be in header with the syntax
				             #    'HEADER_LICENSE kwd= VALUE'

				# --------------------------------------------------
				# PP: parameters
				# --------------------------------------------------
	   'para_status',       "normal", # if "normal" -> normal execution with date
#	   'para_status',       "copy", # copy a file

	   'ctrl_numFileKeep',  200,         # if more files in run dir: write tar file
	   'ctrl_numLinesLog',  2000,        # length of log files (longer ones cut)
	   'ctrl_checkQuota',   0,           # flag: if 1, quota is checked
	   'ctrl_checkDu',      0,           # flag: if 1, disk usage (UNIX du) is checked
	   'ctrl_kbAllocated',  8000000,     # kB allowed for the server to use before
				             #    running files are thrown!

	   'ctrl_timeoutWeb',   "100",       # HTML timeout in sec (> -> switch to email response)
				             #     NOTE: used by cgi script processing the submission
				             #           page
	   'ctrl_timeoutQuery', "2",         # query file timeout in days
	   'ctrl_timeoutRes',   "4",         # result file timeout in days
	   'ctrl_timeoutErr',   "4",         # files in error dirs deleted after n days
	   'ctrl_timeoutBup',   "5",         # files in bup dirs deleted after n days
	   'ctrl_timeoutTrash', "10",        # files in trash dirs deleted after n days
	   'ctrl_timeoutResPub',"3",         # files in public result directory del after n days

				             # default predictions
	   'para_defaultPrd',   "PHDsec,PHDacc,PHDhtm,ProSite,SEG,ProDom",
				             # default format of alignment returned
#	   'para_defaultAli',   "MSF",
	   'para_defaultChain', "",          # default chain to be extracted from a pdb

				# --------------------------------------------------
				# FILES

				# ==================================================
				# PHD
				# ==================================================
				# PHD: executables
	   'exePhd',            $dppPrgPhd.   "phd.pl",
	   'exePhdFor',         $dppScrBin.   "phd."               .$ARCH,
#	   'exePhdFor',         $dppPrgPhd.   "bin/phd."           .$ARCH,

	   'exePhdHtmfil',      $dppPrgPhd.   "scr/phd_htmfil.pl",
	   'exePhdHtmref',      $dppPrgPhd.   "scr/phd_htmref.pl",
	   'exePhdHtmtop',      $dppPrgPhd.   "scr/phd_htmtop.pl",

	   'exePhdRdb2kg',      $dppPrgPhd.   "scr/rdb_tokg.pl",
	   'exePhd2msf',        $dppPrgPhd.   "scr/conv_phd2msf.pl",
	   'exePhd2dssp',       $dppPrgPhd.   "scr/conv_phd2dssp.pl",
	   'exePhd2casp2',      $dppPrgPhd.   "scr/conv_phd2casp4.pl",
	   'exePhd2html',       $dppPrgPhd.   "scr/conv_phd2html.pl",
#	   'exeGlobe',          $.      "globe.pl",
                                # ----------------------------------------
				# PHD: directories
	   'dirPhd',            $dppPrgPhd,
                                # ----------------------------------------
				# PHD: files
	   'filePhdParaAcc',    $dppPrgPhd.   "para/Para-exp152x-mar94.com",
	   'filePhdParaHtm',    $dppPrgPhd.   "para/Para-htm69-aug94.com",
	   'filePhdParaSec',    $dppPrgPhd.   "para/Para-sec317-may94.com",
#	   'filePhdParaAcc',    $dppPrgPhd.   "para/Para-exptest.com", # zzz
#	   'filePhdParaHtm',    $dppPrgPhd.   "para/Para-htmtest.com", # zzz
#	   'filePhdParaSec',    $dppPrgPhd.   "para/Para-test.com",    # zzz
                                # ----------------------------------------
				# PHD: parameters
	   'parPhdMinLen',      "17",  # minimal length of sequence
	   'parPhdSubsec',      "4",   # reliability cut-off for subsets
	   'parPhdSubacc',      "3",
	   'parPhdSubsymbol',   ".",   # symbol used for subset
	   'parPhdHtmDef',      "0.8", # default value for HTM segment
	   'parPhdHtmMin',      "0.2", # minimal value for HTM segment
	   'parPhdNlineMsf',    "60",  # number of character in phd.msf format
				               # smaller ones -> return no HTM

				# ==================================================
				# PROF
				# ==================================================
				# PROF: executables
	   'exeProf',            $dppPrgProf.   "scr/prof.pl",
	   'exeProfFor',         $dppScrBin.    "prof."               .$ARCH,

	   'exeProfHtmfil',      $dppPrgProf.   "scr/tlprof_htmfil.pl",
	   'exeProfHtmref',      $dppPrgProf.   "scr/tlprof_htmref.pl",
	   'exeProfHtmtop',      $dppPrgProf.   "scr/tlprof_htmtop.pl",

	   'exeProfConv',        $dppPrgProf.   "scr/conv_prof.pl",

				# yy beg: for time being
	   'exeProfPhd1994',     $dppPrgProf.   "embl/phd.pl",
	   'exeProfPhd1994For',  $dppScrBin.    "phd."                .$ARCH,
				# yy end: for time being
                                # ----------------------------------------
				# PROF: directories
	   'dirProf',            $dppPrgProf,
                                # ----------------------------------------
				# PROF: files
#	   'fileProfPara3',      $dppPrgProf.   "net/PROFboth_2nd.par",
#	   'fileProfParaAcc',    $dppPrgProf.   "net/PROFacc_1st.par",
#	   'fileProfParaHtm',    $dppPrgProf.   "net/PROFsec_2nd.par",
#	   'fileProfParaSec',    $dppPrgProf.   "net/PROFsec_2nd.par",
	   'fileProfPara3',      $dppPrgProf.   "net/PROFboth.par",
	   'fileProfParaBoth',   $dppPrgProf.   "net/PROFboth.par",
	   'fileProfParaAcc',    $dppPrgProf.   "net/PROFacc.par",
	   'fileProfParaHtm',    $dppPrgProf.   "net/PROFsec.par",
	   'fileProfParaSec',    $dppPrgProf.   "net/PROFsec.par",

#	   'fileProfPara3',      $dppPrgProf.   "net/TSTboth.par",   # zz test
#	   'fileProfParaBoth',   $dppPrgProf.   "net/TSTboth.par",   # zz test
#	   'fileProfParaAcc',    $dppPrgProf.   "net/TSTacc.jct",    # zz test
#	   'fileProfParaHtm',    $dppPrgProf.   "net/TSThtm.jct",    # zz test
#	   'fileProfParaSec',    $dppPrgProf.   "net/TSTsec.jct",    # zz test
                                # ----------------------------------------
				# PROF: parameters
	   'parProfOptDef',      "both", # default to run PROF
	   'parProfMinLen',      "17",   # minimal length of sequence
	   'parProfSubsec',      "4",    # reliability cut-off for subsets
	   'parProfSubacc',      "3",
	   'parProfSubhtm',      "4",
	   'parProfSubsymbol',   ".",    # symbol used for subset
	   'parProfHtmDef',      "0.8",  # default value for HTM segment
	   'parProfHtmMin',      "0.2",  # minimal value for HTM segment
	   'parProfNlineMsf',    "60",   # number of character in prof.msf format
				               # smaller ones -> return no HTM

				# ==================================================
                                # TOPITS
				# ==================================================
				# TOPITS: executables
	   'exeTopits',         $dppPrgTopits."topits.pl",
	   'exeTopitsMaxhom',   $dppScrBin.   "maxhom."            .$ARCH, 
#	   'exeTopitsMaxhom',   $dppScrBin.   "maxhom-big."        .$ARCH, 
	   'exeTopitsMaxhomCsh',$dppPrgTopits."scr/maxhom_topits.csh",
	   'exeTopitsMakeMetr', $dppScrBin.   "metr2st_make."      .$ARCH,
#	   'exeTopitsMakeMetr', $dppPrgTopits."bin/metr2st_make."  .$ARCH,

#	   'exeTopitsWrtOwn',   $dppPrgTopits."/scr/"."topitsWrtOwn.pl",
                                # ----------------------------------------
				# TOPITS: directories
	   'dirTopits',         $dppPrgTopits,
                                # ----------------------------------------
                                # TOPITS: files
	   'fileTopitsDef',     $dppPrgTopits."mat/Defaults.topits",
	   'fileTopitsMaxhomDef', $dppPrgTopits.  "mat/Defaults.maxhom",

#	   'fileTopitsAliList', $dppPrgTopits."mat/Topits_dssp849.list",
#	   'fileTopitsAliList', $dppPrgTopits."mat/Topits_dssp1213.list",
#	   'fileTopitsAliList', $dppPrgTopits."mat/Topits_dssp_98_10.list",
#	   'fileTopitsAliList', $dppPrgTopits."mat/Topits_dssp_99_01.list",
	   'fileTopitsAliList', $dppPrgTopits."mat/Topits_dssp_00_06.list",
#	   'fileTopitsAliList', $dppPrgTopits."mat/tmp2.list",        # zzz 
#	   'fileTopitsAliList', $dppPrgTopits."mat/tmp3.list",        # zzz 

	   'fileTopitsMetrIn',  $dppPrgTopits."mat/Topits_m3c_in.metric",
#	   'fileTopitsMetrIn',  $dppPrgTopits."mat/Topits_in.metric",
	   'fileTopitsMetrSeq', $dppPrgTopits."mat/Maxhom_McLachlan.metric",
				# all possible metrices
	   'fileTopitsMetrSeqAll', 
	                        $dppPrgTopits."mat/Maxhom_McLachlan.metric".",".
	                        $dppPrgTopits."mat/Maxhom_Blosum.metric".",".
	                        $dppPrgTopits."mat/Maxhom_GCG.metric".",",
	   'fileTopitsMetrGCG', $dppPrgTopits."mat/Maxhom_GCG.metric",
                                # ----------------------------------------
                                # TOPITS: parameters
	   'parTopitsSmax',     "2",
	   'parTopitsGo',       "2",
	   'parTopitsGe',       "0.2",
	   'parTopitsMixStrSeq',"50",
	   'parTopitsLindel1',  "1",
	   'parTopitsNhits',    "20",

				# ==================================================
				# Alignment General
				# ==================================================
	   'seq_method',        "blast", # Seq research method (blast or fasta)

				# ==================================================
				# Alignment Blast
				# ==================================================
	   'exeBlastp',         $dppScrBin.   "blastp."            .$ARCH,
#	   'exeBlastp',         $dppPrgBlastp."bin/blastp."        .$ARCH,
#	   'exeBlastpFilter',   $dppPrgMax.   "scr/filter_blastp.pl",
	   'exeBlastpFilter',   $dppPrgMax.   "scr/filter_blastp_big.pl",

	   'envBlastMat',       $dppPrgBlastp."blastapp/matrix/",
	   'envBlastDb',        $dppData.     "blast",
	   
	   'parBlastDb',        "swiss",     # database to run BLASTP against
	   'parBlastDbPdb',     "pdb",
	   'parBlastDbSwiss',   "swiss",
	   'parBlastDbTrembl',  "trembl",
	   'parBlastDbBig',     "big",

	   'parBlastNhits',     "4000",


				# ==================================================
				# Alignment PSI-Blast
				# ==================================================
	   'exeBlastPsi',       $dppScrBin.   "blastpgp."            .$ARCH,
#	   'exeBlastp',         $dppPrgBlastp."bin/blastp."        .$ARCH,
#	   'exeBlastpFilter',   $dppPrgMax.   "scr/filter_blastp.pl",
#	   'exeBlastpFilter',   $dppPrgMax.   "scr/filter_blastp_big.pl",

	   'exeBlast2Saf',      $dppPrgBlastPsi."blastpgp_to_saf.pl",
#	   'exeBlast2Saf',      $dppPrgBlastPsi."blast2saf.pl",
	   'exeBlastRdbExtr4pp',$dppPrgBlastPsi."blastPsi_rdb4pp.pl",
	   'envBlastPsiMat',    $dppPrgBlastPsi."data",
	   'envBlastPsiDb',     $dppData.     "blast",
	   
#	   'parBlastPsiDb',        "big_98_X",     # default database to run BLASTPSI against
	   'parBlastPsiDb',        "big_80",     # default database to run BLASTPSI against
	   'parBlastPsiDbPdb',     "pdb",
	   'parBlastPsiDbSwiss',   "swiss",
	   'parBlastPsiDbTrembl',  "trembl",
	   'parBlastPsiDbBig',     "big",

	   'parBlastPsiNhits',     "1000",

				# specific arguments for PSI-blast
	   'parBlastTile',          "0",
	   'parBlastFilThre',       "100",
	   'parBlastMaxAli',        "3000",
#	   'parBlastPsiArg',        " -j 3 -b 3000 -e 1 -F T -h 1e-3 -d ",
	   'parBlastPsiArg',        " -j 3 -b 2000 -e 1 -F F -h 1e-3 -d ",
#	   'parBlastBigArg',	    " -b 3000 -e 1 -F T -d ",
	   'parBlastBigArg',	    " -b 1000 -e 1 -F F -d ",
		   
	   'BlastProfTmb',      ".blastPsiMatTmb",
				# ==================================================
				# Alignment Fasta
				# ==================================================
#	   'exeFasta',          "/usr/pub/bin/molbio/fasta",
#	   'exeFastaFilter',    "/usr/pub/bin/molbio/filter_fasta",

#	   'envFastaLibs',      "/home/pub/molbio/fasta/fastgbs",
#	   'envFastaLibs',      "/home/$ENV{USER}/maxhom.default",

#	   'parFastaNhits',     "500",       # number of hits reported by FASTA
#	   'parFastaThresh',    "FORMULA+1", # option for filtering FASTA
#	   'parFastaScore',     "100",       # unclear...
#	   'parFastaSort',      "DISTANCE",

				# ==================================================
				# Alignment MaxHom
				# ==================================================
	   'exeMaxhom',         $dppScrBin.   "maxhom."            .$ARCH,
                                # ----------------------------------------
				# MaxHom: directories
#	   'dirMaxhom',         $dppPrgMax,
	   'dirData',           $dppData,                           # dir of databases
	   'dirSwiss',          $dppData.     "swissprot/",         # Swissprot directory
	   'dirSwissSplit',     $dppData.     "swissprot/current/", # SWISS-PROT split
	   'dirPdb',            $dppData.     "pdb/",               # not used ..
	   'dirDssp',           $dppData.     "dssp/",              # DSSP for TOPITS
	   'dirBigSwissSplit',  $dppData.     "derived/big/splitSwiss",
	   'dirBigTremblSplit', $dppData.     "derived/big/splitTrembl",
	   'dirBigPdbSplit',    $dppData.     "derived/big/splitPdb",
                                # ----------------------------------------
				# MaxHom: files
	   'fileMaxhomDefaults',$dppPrgMax.   "mat/maxhom.default",
#	   'fileMaxhomMetrSeq', $dppPrgMax.   "mat/Maxhom_McLachlan.metric",
	   'fileMaxhomMetrSeq', $dppPrgMax.   "mat/Maxhom_Blosum.metric",
	   'fileMaxhomMetr',    $dppPrgMax.   "mat/Maxhom_Blosum.metric",
	   'fileMaxhomMetrLach',$dppPrgMax.   "mat/Maxhom_McLachlan.metric",
				# all possible metrices
	   'fileMaxhomMetrSeqAll', 
	                        $dppPrgMax.   "mat/Maxhom_McLachlan.metric".",".
	                        $dppPrgMax.   "mat/Maxhom_Blosum.metric".",".
	                        $dppPrgMax.   "mat/Maxhom_GCG.metric".",",
				             # USE for copf when msf-> hssp!!
#	   'fileMaxhomMetr',    $dppPrgMax.   "mat/Maxhom_GCG.metric",

	   'extPdb',            ".brk",	# PDB extension
#old	   'fileBrookhaven',    "/data/brookhaven/brookhaven",
                                # ----------------------------------------
				# MaxHom: parameters
	   'parMaxhomMinIde',   "25",        # minimal sequence identity for MAXHOM search
	   'parMaxhomExpMinIde',"15",        # minimal sequence identity (experts)
	   'parMaxhomMaxNres',  "5000",      # maximal length of sequence
	   'parMaxhomMaxNbig',  "1000",     # maximal length of sequence for running
				             #    against the BIG database
	   'parMaxhomMaxACGT',  "80",        # max content of ACGT (otherwise=DNA,RNA?)
	   'parMaxhomLprof',    "NO",
	   'parMaxhomSmin',     -0.5,        # standard job
	   'parMaxhomSmax',     1.0,         # standard job
	   'parMaxhomGo',       3.0,         # standard job
	   'parMaxhomGe',       0.1,         # standard job
				# br/gy: changed 2004-04-13 
				#        no longer run second round of maxhom
#	   'parMaxhomW1',       "YES",       # standard job
	   'parMaxhomW1',       "NO",        # standard job
	   'parMaxhomW2',       "NO",        # standard job
	   'parMaxhomI1',       "YES",       # standard job
	   'parMaxhomI2',       "NO",        # standard job
	   'parMaxhomNali',     500,         # standard job
	   'parMaxhomSort',     "DISTANCE",  # standard job
	   'parMaxhomProfOut',  "NO",        # standard job

	   'parMaxhomTimeOut',  600,         # secnd ~ 10min, then: send alarm MaxHom suicide!

	   'parMinLaliPdb',     30,          # minimal length of ali to report: 'has 3D homo'
	   
				
				# ==================================================
				# Alignment utilities: Convert_seq
				# ==================================================
	   'exeCopf',           $dppPrgPhd.   "scr/copf.pl",
	   'exeConvertSeq',     $dppScrBin.   "convert_seq."       .$ARCH,
#	   'exeConvertSeq',     $dppPrgMax.   "bin/convert_seq."   .$ARCH,

				# ==================================================
				# Alignment utilities: Filter_hssp
				# ==================================================
	   'exeHsspFilter',     $dppPrgPhd.   "scr/hssp_filter.pl",
	   'exeHsspFilterFor',  $dppScrBin.   "filter_hssp."       .$ARCH,
#	   'exeHsspFilterFor',  $dppPrgMax.   "bin/filter_hssp."   .$ARCH,
                                # ----------------------------------------
				# ali filter: parameters
				             # options for running hssp_filter.pl:
				             # thresh=0       : distance from threshold
				             # threshSgi=-10  : distance for sim > ide rule
				             # mode=[ide|sim|old] : mode -> which threshold to use
				             # red=90         : reduce redundancy by skipping over
				             #                  all pairs with > 90% sequence ide
				             # ''             : to leave unused
	   'parFilterAliOff',   "thresh=8 threshSgi=-10 mode=ide", 
				             # option for alignment to send
	   'parFilterAliPhd',   "thresh=8 threshSgi=-10 mode=ide red=90", 
				             # option for alignment used for PHD

				# ==================================================
				# Alignment utilities: extract from HSSP
				# ==================================================
	   'exeHsspExtrHead',   $dppPrgMax.   "scr/hssp_extr_header.pl",
	   'exeHssp2pir',       $dppPrgMax.   "scr/hssp_extr_2pir.pl",
	   'exeHsspExtrStrip',  $dppPrgTopits."scr/hssp_extr_strip.pl",

	   'exeHsspExtrHdr4pp', $dppScrUt.    "hssp_extr_hdr4pp.pl",
	   'exeHsspExtrStripPP',$dppScrUt.    "pp_strip2send.pl",


                                # ==================================================
				# other jobs threader
				# ==================================================
	   'exeThreader',        $dppPrgThreader. "scr/threader.pl",

				# ==================================================
				# other jobs Prosite
				# ==================================================
	   'exeProsite',        $dppPrgProsite. "prosite_scan.pl",
                                             # prosite database converted	   
	   'filePrositeData',   $dppPrgProsite. "mat/prosite_convert.dat",

				# ==================================================
				# other jobs Prodom
				# ==================================================
	   'envProdomBlastDb',  $dppPrgProdom.  "mat",
				             # database to run BLASTP against PRODOM
#	   'parProdomBlastDb',  $dppPrgProdom.  "mat/prodom_36",
#	   'parProdomBlastDb',  $dppPrgProdom.  "mat/prodom_99_1",
#	   'parProdomBlastDb',  $dppPrgProdom.  "mat/prodom_99_2",
	   'parProdomBlastDb',  $dppPrgProdom.  "mat/prodom_00_1",
	   'parProdomBlastN',   "500",
	   'parProdomBlastE',   "0.001",       # E=0.1 when calling BLASTP (PRODOM)
	   'parProdomBlastP',   "0.001",       # probability cut-off for PRODOM

				# ==================================================
				# other jobs Coils
				# ==================================================
	   'exeCoils',          $dppPrgCoils. "coils-wrap.pl",
#	   'exeCoils',          $dppPrgCoils. "bin/coils."         .$ARCH,

	   'parCoilsMin',       0.5,         # minimal prob for considering it a coiled-coil
	   'parCoilsMetr',      "MTIDK",       # two metrices allowd MTK|MTIDK
	   'parCoilsWeight',    "Y",         # weighting a & f (by 2.5), for no weight 'N'
	   'parCoilsOptOut',    "col",       # output column-wise (needed for post-processing)


				# ==================================================
				# other jobs: cyspred
				# ==================================================
#	   'exeCyspred',        $dppPrgCyspred. "runcyspred.run",
#	   'dirCyspred',        $dppPrgCyspred,


				# ==================================================
				# other jobs: disulfind
				# ==================================================
	   'exeDisulfind',        $dppPrgDisulfind. "predict.sh",
	   'dirDisulfind',        $dppPrgDisulfind,

				# ==================================================
				# other jobs: pfam
				# ==================================================
	   'exePfam',           $dppPrgPfam. "hmmpfam",
	   'dirPfam',           $dppPrgPfam,

				# ==================================================
				# other jobs: profcon
				# ==================================================
	   'exeProfCon',        $dppPrgProfCon. "run_prof08_CASP.pl", #this is the default profcon
#	   'exeProfCon',        $dppPrgProfCon. "run_prof08.pl",
	   'dirProfCon',        $dppPrgProfCon,


				# ==================================================
				# other jobs: prenup
				# ==================================================
	   'exePrenup',         $dppPrgPrenup. "runPreNUP.pl", #this is the default profcon
#	   'exeProfCon',        $dppPrgProfCon. "run_prof08.pl",
	   'dirPrenup',        $dppPrgPrenup,

				# ==================================================
				# other jobs: ecgo
				# ==================================================
	   'exeEcgo',           $dppPrgEcgo. "ecgo.py", #this is the default profcon
#	   'exeProfCon',        $dppPrgProfCon. "run_prof08.pl",
	   'dirEcgo',           $dppPrgEcgo,


				# ==================================================
				# other jobs: Predict Cell Cycle
				# ==================================================
	   'exePcc',            $dppPrgPcc. "pcc_wrap.pl",
	   'dirPcc',            $dppPrgPcc,


				# ==================================================
				# other jobs: ConSurf/ConSeq
				# ==================================================
	   'exeR4S',            $dppPrgR4S. "r4s.run",
	   'dirR4S',            $dppPrgR4S,

				# ==================================================
				# other jobs: Predict Prot-Prot interaction  ISIS YO
				# ==================================================
           'exeIsis',            $dppPrgIsis. "readSeqServer.pl",
	   'dirIsis',            $dppPrgIsis,
	   'parIsisChain',         " ", # defualt: chain is empty  
	   'parSolved',            "no",# defualt: find solved is false 


				# ==================================================
				# other jobs: NL-Prot
				# ==================================================
           'exeNLProt',            $dppPrgNLProt. "nlprot",
	   'dirNLProt',            $dppPrgNLProt,


                                # ==================================================
                                # other jobs: Predict Prof TMB
                                # ==================================================
#           'exeProfTmb',            $dppPrgProfTmb. "proftmb.pl",
           'exeProfTmb',            $dppPrgProfTmb. "/usr/bin/proftmb",
           'dirProfTmb',            $dppPrgProfTmb,

                                # ==================================================
				# other jobs: Predict PROFBval
                                # ==================================================
#           'exeProfTmb',            $dppPrgProfTmb. "proftmb.pl",
           'exeProfBval',            $dppPrgProfBval. "runPROFbval.pl",
           'dirProfBval',            $dppPrgProfBval,

                                # ==================================================
				# other jobs: snap
                                # ==================================================
           'exeSnap',            $dppPrgSnap. "SingleSequenceRun.pl",
           'dirSnap',            $dppPrgSnap,

				# ==================================================
				# other jobs: LOC Target
				# ==================================================
	   'exeLocTar',         $dppPrgLocTar. "predLoci.pl",
	   'dirLocTar',         $dppPrgLocTar,

				# ==================================================
				# other jobs: Agape
				# ==================================================
	   'exeAgape',         $dppPrgAgape. "scr/agape.pl",
#	   'exeAgape',         $dppPrgAgape. "agape.pl",
	   'dirAgape',         $dppPrgAgape,


				# ==================================================
				# other jobs: ConBlast
				# ==================================================
	   'exeConBlast',      $dppPrgConBlast. "conBlast_pp.pl",
	   'dirConBlast',      $dppPrgConBlast,


				# ==================================================
			        # other jobs: CHOP
				# ==================================================
	   'exeChop',           $dppPrgChop. "scr/chop.pl",
	   'dirChop',           $dppPrgChop,

	   'parChopBlastE',         0.01, # 
	   'parChoprHmmrE',         0.01, # 
	   'parChopDomCov',         80, # 
	   'parChopMinFragLen',     30, # 

				# ==================================================
			        # other jobs: CHOPPER
				# ==================================================
	   'exeChopper',           $dppPrgChopper. "scr/chopper.pl",
	   'dirChopper',           $dppPrgChopper,
				
	   'parChopperFormatOut',         'casp',  
	   'chopper_admin',        'liu@cubic.bioc.columbia.edu',

				# ==================================================
				# other jobs: nls
				# ==================================================
	   'exeNls',            $dppPrgNls. "pp_resonline.pl",

                                # ==================================================
				# other jobs: asp
				# ==================================================
	   'exeAsp',            $dppPrgAsp. "asp_cubic.pl",
	   'parAspWs',           5, # window size
	   'parAspZ',            -1.75,	# z score cutoff
	   'parAspMin',           9, # minimum mu dPr score


                                # ==================================================
				# other jobs: Nors
				# ==================================================
	   'exeNorsp',            $dppPrgNors. "nors.pl",
	   'parNorsWs',          70, # window size
	   'parNorsSecCut',      12, # structural content cutoff
	   'parNorsAccLen',      10, # minimum consecutive exposed residues



				# ==================================================
				# other jobs Repeats
				# ==================================================
#	   'exeRepeats',        $Arch_exeRepeats{$ARCH},

				# ==================================================
				# other jobs SEG
				# ==================================================
	   'exeSeg',            $dppScrBin.   "seg."               .$ARCH,
	   'parSegNorm',        "-x",        # simply replace low-complexity region
				             #    by letter 'x'
	   'parSegGlob',        "30 3.5 3.75",
	   'parSegNormMin',     10,          # minimal number of residues before reporting
				             #    low complexity regions


				# ==================================================
				# other jobs DSSP
				# ==================================================
				# executables
	   'exeDssp',           $dppPrgDssp.     "dssp",           
	   'exeDssp2Seq',       $dppScrUt.       "dsspExtrSeqSecAcc.pl",
				# ==================================================
				# other jobs MView
				# ==================================================
	   'exeMview',          $dppPrgMview. "mview.pl",
	   'parMview',          "-css on -srs on".
	                        " -html head -ruler on".
	                        " -coloring consensus -threshold 70 -consensus on -con_coloring any",	
#	   'fileMviewStyles',   $dppPrgMview. "mview_pp.css",

				# ==================================================
				# EVALSEC
				# ==================================================
				# EVALSEC: executables
	   'exeEvalsec',        $dppPrgEvalsec."evalsec.pl",
	   'exeEvalsecFor',     $dppScrBin.    "evalsec."          .$ARCH,
#	   'exeEvalsecFor',     $dppPrgEvalsec."bin/evalsec."      .$ARCH,

				# ==================================================

				# ==================================================
				# program versions
	   'version_swiss',     "SWISS-PROT release 41 (02/2003) with 122 564 proteins",
	   'version_trembl',    "TREMBL release 22 (10/2002)  with 734 427 proteins",
	   'version_pdb',       "PDB release: constantly updated",
	   'version_big',       "PDB+SWISS+TREMBL constantly updated ",

	   'version_pp',       "1.99.08",
	   'version_maxhom',   "1.99.04",
	   'version_blast',    "1.4",
	   'version_mview',    "1.40.2",
	   'version_prosite',  "99.07",
	   'version_prodom',   "2000.1",
	   'version_coils',    "1999_2.2",
	   'version_seg',      "1994",
	   'version_phd',      "1.96",
	   'version_phd_sec',  "1.96",
	   'version_phd_acc',  "1.96",
	   'version_phd_htm',  "1.96",
	   'version_prof',     "2000_04",
	   'version_prof_sec', "2000_04",
	   'version_prof_acc', "2000_04",
	   'version_prof_htm', "2000_04",
	   'version_globe',    "1.98.05",
	   'version_topits',   "1.97",
	   'version_asp',      "1.0",
	   'version_nors',     "1.0",
				# ==================================================

                                # ----------------------------------------
                                # miscellaneous
                                # ----------------------------------------
				# message files to be appended
				# PP: stuff
	   'fileHelpText',      $dppScrTxt.        "Help.txt",
	   'fileHelpConcise',   $dppScrTxt.        "Help.concise",
	   'fileNewsText',      $dppScrTxt.        "News.txt",
	   'fileLicText',       $dppScrTxt.        "Licence.txt",
	   'fileAppErrCrypt',   $dppScrTxt."app/". "IntErr",

	   'fileAppEmpty',      $dppScrTxt."app/". "EmptyFile",
	   'fileAppHtmlHead',          $dppScrTxt."app/". "HtmlHead.html",
	   'fileAppHtmlHeadChop',      $dppScrTxt."app/". "HtmlHead_chop.html",
	   'fileAppHtmlHeadProfCon',   $dppScrTxt."app/". "HtmlHead_profcon.html",
	   'fileAppHtmlHeadPrenup',    $dppScrTxt."app/". "HtmlHead_prenup.html",
	   'fileAppHtmlHeadEcgo',    $dppScrTxt."app/". "HtmlHead_ecgo.html",
	   'fileAppHtmlHeadProfBval',   $dppScrTxt."app/". "HtmlHead_profbval.html",
	   'fileAppHtmlHeadSnap',   $dppScrTxt."app/". "HtmlHead_snap.html",
	   'fileAppHtmlHeadIsis',      $dppScrTxt."app/". "HtmlHead_isis.html",
#	   'fileAppHtmlHeadProfBval',      $dppScrTxt."app/". "HtmlHead_ptofbval.html",
	   'fileAppHtmlHeadNLProt',   $dppScrTxt."app/". "HtmlHead_nlprot.html",
	   'fileAppHtmlHeadAgape',      $dppScrTxt."app/"."HtmlHead_agape.html",
           'fileAppHtmlHeadConBlast',      $dppScrTxt."app/"."HtmlHead_conblast.html",
	   'fileAppHtmlHeadProfBval',  $dppScrTxt."app/"."HtmlHead_profbval.html",
	   'fileAppHtmlHeadSnap'    ,  $dppScrTxt."app/"."HtmlHead_snap.html",
	   'fileAppHtmlFoot',          $dppScrTxt."app/". "HtmlFoot.html",
	   'fileAppHtmlMviewStyles',   $dppScrTxt."app/". "HtmlMviewStyles.html",
	   'fileAppHtmlPhdStyles',     $dppScrTxt."app/". "HtmlPhdStyles.html",
	   'fileAppHtmlStyles',        $dppScrTxt."app/". "HtmlStyles.html",
	   'fileAppHtmlQuote',         $dppScrTxt."app/". "HtmlQuote.html",

				# HTML submission form for META
	   'fileHtmlMetaSubmit',$dppWWWdoc."submit_meta.html",
#	   'fileHtmlMetaSubmit',$dppWWWdoc."submit_meta2.html",
           'fileHtmlMetaSubmitPP',$dppWWWdoc."submit_meta_phm.html", #MERGED
				# HTML submission to ESPript
	  # 'fileHtmlEspript',   "http://cubic.bioc.columbia.edu/cgi/pp/ESPript",
				# URL for SRS server
	  #MERGED
          'fileHtmlEspript',   "http://cubic.bioc.columbia.edu/cgi/pp/nph-ESPript_exe.cgi",
                                # URL for SRS server
	   'urlSrs',		"http://srs.ebi.ac.uk/srs6bin/cgi-bin/wgetz",
				# URL for PP
	   'pp_url',            "http://www.predictprotein.org",
	   );

				# headers (tables with accuracy)
    foreach $kwd ("fileHeadPhdConcise","fileHeadPhd3","fileHeadPhdBoth",
		  "fileHeadPhdSec","fileHeadPhdAcc","fileHeadPhdHtm",
		  "fileHeadEvalsec"){
	if ($kwd =~ /^fileHeadPhd/){
	    $file=$kwd;$file=~s/^fileH/h/g;
	    $envL{$kwd}=      $dppPrgPhd."mat/".$file.".txt"; }
	else {
	    $file=$kwd;$file=~s/^fileHead//g;
	    $envL{$kwd}=      $dppScrTxt."head/".$file.".txt";} }

				# abbreviations
    foreach $kwd ("fileAbbrPhd3",  "fileAbbrRdb3",  "fileAbbrPhdBoth",
		  "fileAbbrPhdSec","fileAbbrPhdAcc","fileAbbrPhdHtm",
		  ){
	$file=$kwd;$file=~s/^fileAbbr//g;
	$envL{$kwd}=          $dppScrTxt."head/".$file.".txt";}
    foreach $kwd ("fileAppLicPwd",       "fileAppLicExhaust",   "fileAppLicExpired",
		  "fileAppLicNew",       "fileAppLine",
		  "fileAppInSeqConv",    "fileAppInSeqSent",
		  "fileAppEvalsec",      "fileAppHssp",       
		  "fileAppPred",         "fileAppPredPhd",      "fileAppPredProf",
		  "fileAppGlobe",        "fileAppAsp",          "fileAppNorsp",  
		  "fileAppProdom",       "fileAppProsite",      "fileAppCoils",
		  "fileAppDisulfind",      "fileAppSegNorm",      "fileAppSegGlob",      
		  "fileAppMsfWarning",   "fileAppSafWarning",   "fileAppWarnSingSeq",
		  "fileAppTopitsNohom",  "fileAppIlyaPdb",      "fileAppMembrane",
		  "fileAppThreader",     "fileAppProfCon",     "fileAppPcc", "fileAppChop", "fileAppPrenup", "fileAppEcgo",
		  "fileAppChopper", "fileAppIsis","fileAppNLProt", "fileAppR4S","fileAppConSurf","fileAppConSeq",
		  "fileAppProfTmb",      "fileAppLocTar",      "fileAppPfam", "fileAppAgape",  "fileAppConBlast", 
		  "fileAppRetBlastp",    "fileAppRetBlastPsi", "fileAppProfBval","fileAppSnap",
		  "fileAppRetMsf",       "fileAppRetNoali",

		  "fileAppRetTopitsOwn", "fileAppRetTopitsHssp","fileAppRetTopitsStrip",
		  "fileAppRetTopitsMsf", 
		  "fileAppRetPhdMsf",    "fileAppRetPhdRdb",    
		  "fileAppRetGraph",     "fileAppRetCol",       "fileAppRetPhdCasp2",

		  "fileAppRetProfMsf",   "fileAppRetProfSaf",   "fileAppRetProfRdb",   
		  "fileAppRetProfGraph", "fileAppRetProfCol",   "fileAppRetProfCasp",

		  "fileAppWrgMsfexa",    "fileAppWrgSafexa",
		  ){
#	$file=$kwd;$file=~s/^fileApp//g;
#	$tmp=substr($file,1,1);$tmp=~tr/[A-Z]/[a-z]/ if ($file=~/head|app/i);
#	$file=$tmp.substr($file,2);
	$file=$kwd;$file=~s/^fileApp//g;
	$envL{$kwd}=            $dppScrTxt."app/".$file ;}

				# ------------------------------
				# hack (change br 1999-01):
				# make dir if not existing!
				# ------------------------------
    foreach $kwd ($dppTrash,$dppErr,
		  "dir_err","dir_trash","dir_bup_res",
		  "dir_bup_errIn","dir_bup_err","dir_bup_errMail") {
	next if (! defined $envL{$kwd});
	next if (-d $envL{$kwd});
	$dir=$envL{$kwd};
	system("mkdir $dir");}
				# ------------------------------
				# new shit...
				# ------------------------------
    $ENV{'LANG'}="C";

#    system("setenv LANG C");
#    system("env ");exit;


}				# end of SETENV

#===============================================================================
sub envMethods {
    local($sbrName,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   envMethods                  set method abouts 
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."envMethods";
				# --------------------------------------------------
				# method stuff
				# --------------------------------------------------
				# --------------------------------------------------
				# service properties (WWW and CGI URL)
    				# format: preferred sequence format
    				#        olc: one letter code
				# --------------------------------------------------
    %methods= 
	(			# all methods used in PP
	 'list'=> [
		   'predictprotein',
		   'swissprot','trembl','pdb','big',
		   'maxhom','blastp','blastpsi',
		   'prosite','prodom','seg','predictnls',
		   'phd','phdsec','phdacc','phdhtm',
		   'prof','profsec','profacc',
#		   'profhtm',
		   'globe','topits',
		   'coils','disulfind','asp','norsp',
		   'mview',
		   'espript'
		   ],
				# all types
	 'type'=> [
		   'server',
		   'db',
		   'ali',
		   'motif',
		   'struc',
		   'toolin',
		   'toolex'
		   ],
		   
	 'typetrans'=> {
	     'server'  => 'Prediction server',
	     'db'      => 'Databases searched for homologues',
	     'ali'     => 'Alignment and database searching methods',
	     'motif'   => 'Sequence motif searching methods',
	     'struc'   => 'Prediction of protein structure',

	     'toolin'  => 'Tools used for PP',
	     'toolex'  => 'Tools available with PP output'
	     },

	 'xyz'=>{
	     'cgi'     => '',
	     'url'     => '',
	     'task'    => '',
	     'taskabbr'=> '',
	     'admin'   => ',',
	     'doneby'  => '',
	     'quote'   => '',
	     'des',    => '', 
	     'abbr'    => 'xyz',
	     'version' => ''
	     },

	 'predictprotein'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'server',
	     'taskabbr'=> 'server',
	     'admin'   => 'Jinfeng Liu,liu@cubic.bioc.columbia.edu',
	     'doneby'  => 'Burkhard Rost and Jinfeng Liu (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: PHD: predicting one-dimensional protein structure by profile based neural networks. Meth. in Enzymolgy, 266, 525-539, 1996',
	     'des',    => '', 
	     'abbr'    => 'PredictProtein',
	     'version' => '2000_06'
	     },

				# databases
	 'swissprot'=>{
	     'cgi'     => 'http://expasy.cbr.nrc.ca/sprot/',
	     'url'     => 'http://expasy.cbr.nrc.ca/sprot/',
	     'task'    => 'database: protein sequence',
	     'taskabbr'=> 'db',
	     'admin'   => 'Amos Bairoch,Amos.Bairoch@isb-sib.ch',
	     'doneby'  => 'Amos Bairoch (ExPasy, Geneva, Switzerland) and Rolf Appweiler (EBI, Hinxton, England)',
	     'quote'   => 'A Bairoch, and R Apweiler:: The SWISS-PROT protein sequence database and its supplement TrEMBL in 2000. Nucleic Acids Res., 28, 45-48, 2000',
	     'des',    => 'PredictProtein is the acronym for all prediction programs run', 
	     'abbr'    => 'SWISS-PROT',
	     'version' => '39 (05/2000), updated weekly'
	     },
	 'trembl'=>{
	     'cgi'     => 'http://www.ebi.ac.uk/swissprot/',
	     'url'     => 'http://www.ebi.ac.uk/swissprot/',
	     'task'    => 'database: protein sequence',
	     'taskabbr'=> 'db',
	     'admin'   => 'Rolf Apweiler,Rolf.Apweiler@ebi.ac.uk',
	     'doneby'  => 'Rolf Appweiler (EBI, Hinxton, England)',
	     'quote'   => 'A Bairoch, and R Apweiler:: The SWISS-PROT protein sequence database and its supplement TrEMBL in 2000. Nucleic Acids Res., 28, 45-48, 2000',
	     'des',    => '', 
	     'abbr'    => 'TrEMBL',
	     'version' => '05/2000, updated weekly'
	     },
	 'pdb'=>{
	     'cgi'     => 'http://www.rcsb.org/pdb/',
	     'url'     => 'http://www.rcsb.org/pdb/',
	     'task'    => 'database: protein sequences and structures',
	     'taskabbr'=> 'db',
	     'admin'   => 'Phil Bourne,bourne@sdsc.edu',
	     'doneby'  => 'RCSB consortium',
	     'quote'   => 'H M Berman, J Westbrook, Z Feng, G Gilliland, T N Bhat, H Weissig, I N Shindyalov, P E Bourne:: The Protein Data Bank. Nucleic Acids Research, 28, 235-242, 2000',
	     'des',    => '', 
	     'abbr'    => 'PDB',
	     'version' => 'updated weekly'
	     },
	 'big'=>{
	     'cgi'     => 'local',
	     'url'     => 'local',
	     'task'    => 'database: protein sequence',
	     'taskabbr'=> 'db',
	     'admin'   => 'Dariusz Przybylski,dudek@cubic.bioc.columbia.edu',
	     'doneby'  => 'CUBIC group, Columbia University, New York',
	     'quote'   => 'see SWISS-PROT, TREMBL, PDB',
	     'des',    => '', 
	     'abbr'    => 'BIG',
	     'version' => 'updated weekly'
	     },
				# tools:intern
	 'mview'=>{
	     'cgi'     => 'http://mathbio.nimr.mrc.ac.uk/~nbrown/mview/',
	     'url'     => 'http://mathbio.nimr.mrc.ac.uk/~nbrown/mview/',
	     'task'    => 'tools:intern: display alignment in HTML format',
	     'taskabbr'=> 'toolin',
	     'admin'   => 'Nigel Brown, nbrown@nimr.mrc.ac.uk',
	     'doneby'  => 'Nigel Brown',
	     'quote'   => 'N P Brown, C Leroy, and C Sander:: MView: A Web compatible database search or multiple alignment viewer. Bioinformatics, 14, 380-381, 1998',
	     'des',    => 'MView is a program converting multiple sequence alignments into fancy HTML formatted output', 
	     'abbr'    => 'MView',
	     'version' => '1.40.2'
	     },

				# tools:extern
	 'espript'=>{
	     'cgi'     => 'http://cubic.bioc.columbia.edu/cgi/pp/ESPript',
	     'url'     => 'http://cubic.bioc.columbia.edu/cgi/pp/ESPript',
	     'task'    => 'tools:extern: display alignment in GIF, PDF, Postscript',
	     'taskabbr'=> 'toolex',
	     'admin'   => 'Patrice Gouet,gouet@ipbs.fr',
	     'doneby'  => 'Patrice Gouet and Emmanuel Courcelle',
	     'quote'   => 'P Gouet, E Courcelle, D I Stuart, and F Metoz:: ESPript: multiple sequence alignments in PostScript. Bioinformatics, 15, 305-308, 1999',
	     'des',    => '', 
	     'abbr'    => 'ESPript',
	     'version' => '1.9'
	     },

				# alignment
	 'maxhom'=>{		# 
	     'cgi'     => 'local',
	     'url'     => 'local',
	     'task'    => 'alignment and database search: dynamic programming',
	     'taskabbr'=> 'ali',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Reinhard Schneider (LION, Boston) and Chris Sander (Millenium, Boston)',
	     'quote'   => 'C Sander, and R Schneider::Database of Homology-Derived Structures and the Structural Meaning of Sequence Alignment. Proteins, 9, 56-68, 1991',
	     'des',    => 'MaxHom is a dynamic multiple sequence alignment program which finds similar sequences in a database.', 
	     'abbr'    => 'MaxHom',
	     'version' => '1.2000.06'
	     },
	 'blastp'=>{
	     'cgi'     => 'http://www.ncbi.nlm.nih.gov/BLAST/',
	     'url'     => 'http://www.ncbi.nlm.nih.gov/BLAST/',
	     'task'    => 'alignment and database search: fast search',
	     'taskabbr'=> 'ali',
	     'admin'   => 'BLASTP admin,blast-help@ncbi.nlm.nih.gov',
	     'doneby' => 'S Karlin and SF Altschul (NCBI, Washington)',
	     'quote'   => 'S Karlin,  S F Altschul:: Applications and statistics for multiple high-scoring segments in molecular sequences. PNAS, 90,5873-5877,1993',
	     'des',    => 'BLASTP is a fast database search program', 
	     'abbr'    => 'BLASTP',
	     'version' => '1.4'
	     },
	 'blastpsi'=>{
	     'cgi'     => 'http://www.ncbi.nlm.nih.gov/BLAST/',
	     'url'     => 'http://www.ncbi.nlm.nih.gov/BLAST/',
	     'task'    => 'alignment and database search: iterated, profile-based search',
	     'taskabbr'=> 'ali',
	     'admin'   => 'BLASTP admin,blast-help@ncbi.nlm.nih.gov',
	     'doneby'  => 'S F Altschul, T L Madden, A A Schäffer, J Zhang, Z Zhang, W Miller, and D J Lipman',
	     'quote'   => 'S F Altschul, T L Madden, A A Schäffer, J Zhang, Z Zhang, W Miller, and D J Lipman:: Gapped BLAST and PSI-BLAST: a new generation of protein database search programs. Nucleic Acids Res, 25,3389-3402, 1997',
	     'des',    => 'PSIblast is a fast, yet sensitive database search program', 
	     'abbr'    => 'PSIblast',
	     'version' => '2000_06'
	     },
	 
				# motifs
	 'prosite'=>{
	     'cgi'     => 'http://www.expasy.ch/prosite/',
	     'url'     => 'http://www.expasy.ch/prosite/',
	     'task'    => 'sequence motifs: functional motifs',
	     'taskabbr'=> 'motif',
	     'admin'   => 'Christian Sigrist,Christian.Sigrist@isb-sib.ch',
	     'doneby'  => 'Kay Hofmann, Philip Bucher, and Amos Bairoch (SIB, Geneva, Switzerland)',
	     'quote'   => 'K Hofmann , P Bucher, L Falquet, A Bairoch:: The PROSITE database, its status in 1999. Nucleic Acids Res, 27, 215-219, 1999',

	     'des',    => 'PROSITE is a database of functional motifs.  ScanProsite, finds all functional motifs in your sequence that are annotated in the ProSite db', 
	     'abbr'    => 'ProSite',
	     'version' => '1999_07'
	     },
	 
	 'prodom'=>{
	     'cgi'     => 'http://protein.toulouse.inra.fr/prodom.html',
	     'url'     => 'http://protein.toulouse.inra.fr/prodom.html',
	     'task'    => 'sequence motifs: domains',
	     'taskabbr'=> 'motif',
	     'admin'   => 'Jerome Gouzy,Jerome.Gouzy@toulouse.inra.fr',
	     'doneby'  => 'Florence Corpet, Florence Servant, Jerome Gouzy, and Daniel Kahn',
	     'quote'   => 'F Corpet, F Servant, J Gouzy, and D Kahn:: ProDom and ProDom-CG: tools for protein domain analysis and whole genome comparisons. Nucleic Acids Res, 28, 267-269, 2000',
	     'des',    => 'ProDom is a database of putative protein domains.  The database is searched with BLAST for domains corresponding to your protein', 
	     'abbr'    => 'ProDom',
	     'version' => '2000.1'
	     },
	 
	 'seg'=>{
	     'cgi'     => 'http://trex.musc.edu/manuals/unix/seg.html',
	     'url'     => 'http://trex.musc.edu/manuals/unix/seg.html',
	     'task'    => 'sequence motifs: sequence bias and low complexity',
	     'taskabbr'=> 'motif',
	     'admin'   => 'Scott Federhen,federhen@ncbi.nlm.nih.gov',
	     'doneby'  => 'John C Wootton and Scott Federhen (NCBI, Washington)',
	     'quote'   => 'J C Wootton, and S Federhen:: Analysis of compositionally biased regions in sequence databases. Methods in Enzymology, 266, 554-571, 1996',
	     'des',    => 'SEG divides sequences into regions of low-, and high-complexity.  Low-complexity regions typically correspond to \'simple sequences\' or \'compositionally-biased\' regions', 
	     'abbr'    => 'SEG',
	     'version' => '1994'
	     },

	 'predictnls'=>{
	     'cgi'     => 'http://cubic.bioc.columbia.edu/predictNLS',
	     'url'     => 'http://cubic.bioc.columbia.edu/predictNLS',
	     'task'    => 'sequence motifs: nuclear localisation signals',
	     'taskabbr'=> 'motif',
	     'admin'   => 'Raj Nair,nair@cubic.bioc.columbia.edu',
	     'doneby'  => 'Raj Nair, Murad Cokol, and Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'M Cokol, R Nair, and B Rost::in preparation, 2000',
	     'des',    => 'PrecitNLS finds experimentally known nuclear localisation in your protein', 
	     'abbr'    => 'PredictNLS',
	     'version' => '2000_07'
	     },
	 
				# structure prediction: CUBIC
	 'phd'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'protein structure prediction in 1D: sec + acc + htm',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: PHD: predicting one-dimensional protein structure by profile based neural networks. Methods in Enzymology, 266, 525-539, 1996',
	     'des',    => 'PHD is a suite of programs predicting 1D structure (secondary structure, solvent accessibility) from multiple sequence alignments', 
	     'abbr'    => 'PHD',
	     'version' => '1996.1'
	     },
	 'phdsec'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'protein structure prediction in 1D: secondary structure',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: PHD: predicting one-dimensional protein structure by profile based neural networks. Methods in Enzymology, 266, 525-539, 1996. \n B Rost, and C Sander:: Prediction of protein secondary structure at better than 70% accuracy. J Molecular Biol, 232, 584-599, 1993. \n B Rost, and C Sander:: Combining evolutionary information and neural networks to predict protein secondary structure. Proteins, 19, 55-77, 1994',
	     'des',    => 'PHDsec predicts secondary structure from multiple sequence alignments', 
	     'abbr'    => 'PHDsec',
	     'version' => '1996.1'
	     },
	 'phdacc'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'protein structure prediction in 1D: solvent accessibility',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: PHD: predicting one-dimensional protein structure by profile based neural networks. Methods in Enzymology, 266, 525-539, 1996. \n B Rost, and C Sander:: Conservation and prediction of solvent accessibility in protein families. Proteins, 20, 216-226, 1994',
	     'des',    => 'PHDacc predicts per residue solvent accessibility from multiple sequence alignments', 
	     'abbr'    => 'PHDacc',
	     'version' => '1996.1'
	     },
	 'phdhtm'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'protein structure prediction in 1D: membrane helices',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: PHD: predicting one-dimensional protein structure by profile based neural networks. Methods in Enzymology, 266, 525-539, 1996. \n B Rost, P Fariselli, and R Casadio:: Topology prediction for helical transmembrane proteins at 86% accuracy. Protein Science, 7, 1704-1718, 1996',
	     'des',    => 'PHDhtm predicts the location and topology of transmembrane helices from multiple sequence alignments', 
	     'abbr'    => 'PHDhtm',
	     'version' => '1996.1'
	     },
	 
	 # structure prediction: CUBIC
	 'prof'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'protein structure prediction in 1D: sec + acc',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: PROF: predicting one-dimensional protein structure by profile based neural networks. unpublished, 2000',
	     'des',    => 'Improved version of PHD: Profile-based neural network prediction of protein structure', 
	     'abbr'    => 'PROF',
	     'version' => '2000_06'
	     },
	 'profsec'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'protein structure prediction in 1D: secondary structure',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: PROF: predicting one-dimensional protein structure by profile based neural networks. unpublished, 2000',
	     'des',    => 'Improved version of PHDsec: Profile-based neural network prediction of protein secondary structure', 
	     'abbr'    => 'PROFsec',
	     'version' => '2000.06'
	     },
	 'profacc'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'protein structure prediction in 1D: solvent accessibility',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: PROF: predicting one-dimensional protein structure by profile based neural networks. unpublished, 2000',
	     'des',    => 'Improved version of PHDacc: Profile-based neural network prediction of residue solvent accessibility', 
	     'abbr'    => 'PROFacc',
	     'version' => '2000.06'
	     },
	 
	 'globe'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'protein structure prediction in 1D: globularity',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost::Short yeast ORFs: expressed protein or not? unpublished, 2000',
	     'des',    => 'GLOBE predicts the globularity of a protein', 
	     'abbr'    => 'GLOBE',
	     'version' => '1996.1'
	     },
	 
	 'topits'=>{
	     'cgi'     => 'http://www.predictprotein.org',
	     'url'     => 'http://www.predictprotein.org',
	     'task'    => 'threading: detection of remote homologues',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Burkhard Rost,rost@columbia.edu',
	     'doneby'  => 'Burkhard Rost (CUBIC, Columbia Univ, New York)',
	     'quote'   => 'B Rost:: TOPITS: Threading One-dimensional Predictions Into Three-dimensional Structures. In: C Rawlings, D Clark, R Altman, L Hunter, T Lengauer, and S Wodak (eds.) The third international conference on Intelligent Systems for Molecular Biology (ISMB), Cambridge, England, Menlo Park, CA: AAAI Press, 314-321, 1995. \n B Rost, R Schneider, and C Sander:: Protein fold recognition by prediction-based threading. J of Molecular Biology, 270, 471-480, 1997',
	     'des',    => 'TOPITS is a prediction-based threading program, that finds remote structural homologues in the DSSP database', 
	     'abbr'    => 'TOPITS',
	     'version' => '1997.1'
	     },
	 
				# structure prediction: other
	'asp'=>{
	     'cgi'     => 'local',
	     'url'     => '',
	     'task'    => 'prediction of location of conformational
switches',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Malin Young; Kent Kirshenbaum; Stefan Highsmith, mmyoung@sandia.gov; kent@cheme.caltech.edu; shighsmith@sf.uop.edu',
	     'doneby'  => 'Malin Young (Sandia National Laboratory), Kent Kirshenbaum(Caltech), and Stefan Highsmith',
	     'quote'   => 'Young et al.:: Protein Science(1999) 8:1752-64.',
	     'des',    => 'ASP finds regions that are most likely to behave as switches in proteins known to exhibit this behavior', 
	     'abbr'    => 'ASP',
	     'version' => '1.0'
	     },
	  

	 'coils'=>{
	     'cgi'     => 'local',
	     'url'     => 'local',
	     'task'    => 'protein structure prediction in 1D: coiled-coils',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Andrei Lupas,andrei.lupas@tuebingen.mpg.de',
	     'doneby'  => 'Andrei Lupas (Max Planck Institute, Tuebingen, Germany)',
	     'quote'   => 'A Lupas:: Prediction and Analysis of Coiled-Coil Structures. Methods in Enzymology, 266, 513-525, 1996',
	     'des',    => 'COILS finds coiled-coil regions in your protein', 
	     'abbr'    => 'COILS',
	     'version' => '1999_2.2'
	     },
	 
	 'cyspred'=>{
	     'cgi'     => 'http://prion.biocomp.unibo.it/cyspred.html',
	     'url'     => 'http://prion.biocomp.unibo.it/cyspred.html',
	     'task'    => 'protein structure prediction in 2D: cysteine bonds',
	     'taskabbr'=> 'struc',
	     'admin'   => 'Piero Fariselli,farisel@kaiser.alma.unibo.it',
	     'doneby'  => 'Piero Fariselli and Rita Casadio (Bologna Univ, Bologna)',
	     'quote'   => 'P Fariselli, P Riccobelli, and R Casadio:: Role of evolutionary information in predicting the disulfide-bonding state of cysteine in proteins. Proteins, 36, 340-346, 1999',
	     'des',    => 'CYSPRED finds whether the cys residue in your protein forms disulfide bridge', 
	     'abbr'    => 'CYSPRED',
	     'version' => '2000'
	     },
	 'disulfind'=>{
	     'cgi'     => '',
	     'url'     => '',
	     'task'    => 'Disulfide Connectivity Prediction using Recursive Neural Networks and Evolutionary Information',
	     'taskabbr'=> 'disul',
	     'admin'   => 'A. Vullo and P. Frasconi',
	     'doneby'  => 'A. Vullo and P. Frasconi',
	     'quote'   => 'A. Vullo and P. Frasconi. Disulfide Connectivity Prediction using Recursive Neural Networks and Evolutionary Information, Bioinformatics,20, 653-659, 2004.',
	     'des',    => 'Predicting the Disulfide Bonding State of Cysteines with Combinations of Kernel Machines', 
	     'abbr'    => 'DISULFIND',
	     'version' => '2004'
	     },

	 'norsp'=>{
	     'cgi'     => 'http://cubic.bioc.columbia.edu/services/NORSp/submit.html',
	     'url'     => 'http://cubic.bioc.columbia.edu/services/NORSp/',
	     'task'    => 'disorder: extended region of NOn Regular Secondary Structure',
	     'taskabbr'=> 'NORS',
	     'admin'   => 'Jinfeng Liu,liu@cubic.bioc.columbia.edu',
	     'doneby'  => 'Jinfeng Liu & Burkhard Rost (Columbia Univ., USA)',
	     'quote'   => 'Liu J, Tan H, Rost B:: Loopy proteins appear conserved in evolution. J Mol Biol. 322(1):53-64, 2002',
	     'des',    => 'NORSp finds extended region of NOn Regular Secondary Structure', 
	     'abbr'    => 'NORSp',
	     'version' => '2003'
	     },			
	 );
		
    
    return(1,"ok $sbrName",\%methods);
}				# end of envMethods

#===============================================================================
sub isRunningEnv{
    local ($process,$ps_cmd,$fhLoc) = @_;
    local ($sbrName,$ctJobs,@result);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isRunningEnv                test if a program runs (returns nr of occ found)
#       in:                     $process: name of program to find
#       in:                     $ps_cmd:  machine specific 'ps' command
#       in:                     $fhLoc:   file handle to report action
#       out:                    (0|1,number of jobs running)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."isRunning";
				# check input arguments
    return(0,"*** $sbrName: no process given!")    if (! defined $process);
    return(0,"*** $sbrName: no ps_comand given!")  if (! defined $ps_cmd) ;

    $ctJobs=0;			# ini
    
    $process=~s/nice\s*\d+\s*//g; # no nice
    $process=~s/^.*\///;	  # remove path

    $ps_cmd_full="$ps_cmd | grep \"$process\" | grep -v grep ";
	
				# run a ps command
    @result= `$ps_cmd_full`;
#    @result= `$ps_cmd | grep $process | grep -v 'grep' | grep -v '$process\.\.'`;

    $ctJobs = 0;
    foreach $j ( @result ) {
	next if ( $j =~ /emacs|more|less/ );
	$ctJobs++;
    }
    
#    $ctJobs=$#result;
    $ctJobs=0                   if ($ctJobs && length($result[$#result]) < 1);
				# document what it is doing
    if (defined fileno($fhLoc)){
	print $fhLoc "--- $sbrName: system $ps_cmd_full (result=$ctJobs)\n";}
    else {
	print "--- $sbrName: system $ps_cmd_full (result=$ctJobs)\n";}
    
    return (1,$ctJobs);		# return the number of processes found 
}				# end of isRunningEnv

#===============================================================================
sub getLocal{
    local ($parameter) = @_;
#-------------------------------------------------------------------------------
#   getLocal                    Put all env parameters in an associative array %envL
#-------------------------------------------------------------------------------
    if ($envL{$parameter}) {
	return $envL{$parameter} }
    else {
	return(0); }
}				# end of getLocal

1;

