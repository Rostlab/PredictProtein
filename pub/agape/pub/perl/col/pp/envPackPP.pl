#! /usr/pub/bin/perl -w
#
#------------------------------------------------------------------------------#
#	Copyright				  Dec,    	 1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			    br  v 0.2   	  Aug,           1995          #
#			    br  v 0.5   	  Mar,           1996          #
#			    br  v 1.0             Mar,           1997          #
#			    br  v 2.0a            Apr,           1998          #
#------------------------------------------------------------------------------#
#======================================================================
# this script is use to define phd server environment
# itdefine all env parameters and contain 1 subroutine
#  - getLocal() which give the current value of a given parameter
# when the script itself is run it checks all defined values
#======================================================================

package envPP;

INIT:{
    $[=1;
                                # ===============================
                                # determine the working directory
                                # ===============================
				# changed BR 30.6.95
    $Lis_local=0; $Lis_local=1 if ($ENV{'PPENV'} && $ENV{'PWD'});
    if ($Lis_local) {		# changed BR 30.6.95
	$dir_script=$ENV{'PWD'}; $tmp=$dir_script . "/work";
	if (-d $tmp){
	    $dir_work=$tmp;}else{$dir_work=$dir_script;}}
    elsif ($ENV{'PPWORKDIR'}) {
	$dir_work= $ENV{'PPWORKDIR'}; }
    else {
	$dir_work="/home/phd/server/work";} # hard coded ..
                                # ============================================
                                # determine current system ARCHITECTURE
                                # ============================================
#    open (ARCHFILE, "/data/WHICH_ARCH |"); # HARD_CODED
    open (ARCHFILE, "/home/phd/ut/WHICH_ARCH |"); # HARD_CODED
    while (<ARCHFILE>) {chop;
			 $ARCH= $_; 
			 last;}close(ARCHFILE);
				# hack: br 4.98
    $ARCH="SGI64" if (! defined $ARCH);	# HARD_CODED: problem with stork (procmail)
                                # ============================================
                                # define all architecture dependant parameters
                                # ============================================
    %Arch_exe_ps=        (	# ps command
			  'SGI',             "ps -ef",
			  'SGI5',            "ps -ef",
			  'SGI64',           "ps -ef",
			  'ALPHA',           "ps gw",
			  'SUN4SOL2',        "ps -awux",
			  'SUNMP',           "ps -awux");
    %Arch_exe_quota=     (	# quota command
			  'SGI',             "quota -v",
			  'SGI5',            "quota -v",
			  'SGI6',            "rsh phenix 'quota -v'",
			  'SGI64',           "quota -v",
			  'ALPHA',           "rsh phenix 'quota -v'",
			  'SUN4SOL2',        "quota -v",
			  'SUNMP',           "quota -v");

    %Arch_exe_mail=      (	# mail command
			  'SGI5',            "/usr/sbin/Mail", # mainly for stork (procmail)
			  'SGI64',           "/usr/sbin/Mail",
			  'ALPHA',           "/usr/bin/Mail");

    %Arch_exe_nice=      (	# nice
			  'SGI',             " ",
			  'SGI5',            " ",
			  'SGI64',           " ",
#			   'ALPHA',           " ",
			  'ALPHA',           "nice -10",
			  'SUN4SOL2',        " ",
			  'SUNMP',           " ");
    %Arch_exeBlastp=    (	# blast exe
			 'SGI',             "/usr/pub/bin/molbio/blastp",
			 'SGI5',            "/usr/pub/bin/molbio/blastp",
			 'SGI64',           "/usr/pub/bin/molbio/blastp",
			 'ALPHA',           "/usr/pub/bin/molbio/blastp",
			 'SUN4SOL2',        "/home/phd/bin/SUN4SOL2/blastp",
			 'SUNMP',           "/home/phd/bin/SUNMP/blastp");
    %Arch_exeConvertSeq=(	# convert sequence
			 'SGI',             "/usr/pub/bin/molbio/convert_seq",
			 'SGI5',            "/usr/pub/bin/molbio/convert_seq",
			 'SGI6',            "/usr/pub/bin/molbio/convert_seq",
#			   'SGI64',           "/usr/pub/bin/molbio/convert_seq",
			 'SGI64',           "/home/phd/bin/SGI64/convert_seq2",
#			   'ALPHA',           "/usr/pub/bin/molbio/convert_seq",
			 'ALPHA',           "/home/phd/bin/ALPHA/convert_seq2",
			 'SUN4SOL2',        "/home/phd/bin/SUN4SOL2/convert_seq",
			 'SUNMP',           "/home/phd/bin/SUNMP/convert_seq");
    %Arch_exeMaxhom=    (	# MAXHOM exe
			 'SGI',             "/home/phd/bin/SGI/maxhom",
			 'SGI5',            "/home/phd/bin/SGI/maxhom",
			 'SGI64',           "/home/phd/bin/SGI64/maxhom",
			 'ALPHA',           "/home/phd/bin/ALPHA/maxhom",
			 'SUN4SOL2',        "/home/phd/bin/SUN4SOL2/maxhom",
			 'SUNMP',           "/home/phd/bin/SUNMP/maxhom");
    %Arch_exePhd=       (	# PHD exe
			 'SGI',             "/home/phd/bin/SGI/phd",
			 'SGI5',            "/home/phd/bin/SGI/phd",
			 'SGI64',           "/home/phd/bin/SGI64/phd",
#			   'SGI64',           "/home/phd/bin/SGI64/phd_new",
			 'ALPHA',           "/home/phd/bin/ALPHA/phd",
#			   'ALPHA',           "/home/phd/bin/ALPHA/phd_new",
			 'SUN4SOL2',        "/home/phd/bin/SUN4SOL2/phd",
			 'SUNMP',           "/home/phd/bin/SUNMP/phd");
    %Arch_phdArg8=      (	# PHD arg8
			 'SGI',             "no",
			 'SGI5',            "no",
			 'SGI6',            "no",
			 'SGI64',           "no",
			 'ALPHA',           "ALPHA",
			 'SUN4SOL2',        "no");
    %Arch_exeMetric=    (	# make TOPITS metric
			 'SGI',             "/home/phd/bin/SGI/make_metr2st",
			 'SGI5',            "/home/phd/bin/SGI/make_metr2st",
			 'SGI64',           "/home/phd/bin/SGI64/make_metr2st",
			 'ALPHA',           "/home/phd/bin/ALPHA/make_metr2st",
			 'SUN4SOL2',        "/home/phd/bin/SUN4SOL2/make_metr2st",
			 'SUNMP',           "/home/phd/bin/SUNMP/make_metr2st");
    %Arch_exeEvalsec=   (	# EVALSEC exe
			 'SGI',             "/home/phd/bin/SGI/evalsec",
			 'SGI5',            "/home/phd/bin/SGI/evalsec",
			 'SGI64',           "/home/phd/bin/SGI64/evalsec",
			 'ALPHA',           "/home/phd/bin/ALPHA/evalsec",
			 'SUN4SOL2',        "/home/phd/bin/SUN4SOL2/evalsec",
			 'SUNMP',           "/home/phd/bin/SUNMP/evalsec");
    %Arch_exeWhatif=    (	# WHATIF exe
			 'SGI',             "/home/phd/bin/SGI/whatif",
			 'SGI5',            "/home/phd/bin/SGI/whatif", # 
			 'SGI64',           "/home/phd/bin/SGI64/whatif", # 
			 'ALPHA',           "/home/phd/bin/ALPHA/whatif",
			 'SUN4SOL2',        "/home/phd/bin/SUN4SOL2/whatif",
			 'SUNMP',           "/home/phd/bin/SUNMP/whatif");
    %Arch_exeProsite=   (	# prosite/prosearch exe (from Amos Bairoch)
			 'SGI64',           "/home/phd/bin/SGI64/prosearch",
			 'ALPHA',           "/home/phd/bin/ALPHA/prosearch",
			 'SUNMP',           "/home/phd/bin/SUNMP/prosearch");
    %Arch_exeCoils=     (	# coils exe (from Andrei Lupas)
			 'SGI64',           "/home/phd/bin/SGI64/coils",
			 'ALPHA',           "/home/phd/bin/ALPHA/coils",
			 'SUNMP',           "/home/phd/bin/SUNMP/coils");
    %Arch_exeRepeats=   (	# repeats exe
			 'SGI64',           "/home/phd/bin/SGI64/repeats",
			 'ALPHA',           "/home/phd/bin/ALPHA/repeats",
			 'SUNMP',           "/home/phd/bin/SUNMP/repeats");

    # ========================================================================
    # define all the environment parameters in an associative array %Local_env
    # ========================================================================
				# central directory for server
    $dppHome=                 "/home/phd";
    $dppWWW=                  "/home/www/htdocs/Services/sander/predictprotein";
    $dppServer=    $dppHome.  "/server";
				# NOTE: for WWW access MUST be writable (or change wwwPredict)
    $dppPred=      $dppServer."/prd"; 
    $dppResult=    $dppServer."/res"; 
    $dppError=     $dppServer."/err"; 
				# NOTE: for WWW access MUST be writable (or change wwwPredict)
    $dppMail=      $dppServer."/mail"; 
    $dppInProc=    $dppServer."/inProc"; 
    $dppScript=    $dppServer."/scr"; 
				# NOTE: for WWW access MUST be writable (or change wwwPredict)
    $dppLog=       $dppServer."/log";
				# embl WWW site
				# server utilities
    $dut=          $dppHome.  "/ut";
    $dutMax=       $dut.      "/max";	# maxhom
    $dutMaxMat=    $dutMax.   "/mat";
    $dutMaxBin=    $dutMax.   "/bin";
    $dutPhd=       $dut.      "/phd";	# phd
    $dutPhdPara=   $dutPhd.   "/para";
    $dutPhdScripts=$dutPhd.   "/scr";
    $dutPhdNet=    $dutPhd.   "/net";
    $dutPhdTxt=    $dutPhd.   "/txt";
    $dutTopits=    $dut.      "/topits"; # topits
    $dutTopitsMat= $dutTopits."/mat";
    $dutPerl=      $dut.      "/perl";
    $dutTxt=       $dut.      "/txt";

    if ($Lis_local){
	$dppPred=  $dppResult=$dppMail=$dir_work;
	$dppScript=$dir_script;}
				# ==================================================
				# local environment in associative array
				# ==================================================
    %envL=(			# PP: stuff
	   'ARCH',              $ARCH, # system architecture
				# candidate for prediction (machine:ps cmd:nb occ;...)
#	   'machines',          "phenix:ps -ef:3",
#	   'machines',          "phenix:ps -ef:3;tau:ps gw:1;alpha1:ps gw:1;alpha2:ps gw:1",
	   'machines',          "phenix:ps -ef:3;tau:ps gw:1;alpha1:ps gw:1;alpha2:ps gw:1;".
	                        "alpha4:ps gw:1;alpha5:ps gw:1;alpha6:ps gw",
#	   'machines',          "phenix:ps -ef:3;".
#	                        "alpha1:ps gw:1;alpha2:ps gw:1;alpha3:ps gw:1;".
#	                        "alpha4:ps gw:1;alpha5:ps gw:1;alpha6:ps gw:1",
#	   'pp_admin',          "ppadm\@embl-heidelberg.de", # email PP administrator
	   'pp_admin',          "phd2\@embl-heidelberg.de", # email PP administrator
	   'timeout_html',      "100", # HTML timeout in sec (> -> switch to email response)
	   'password_def',      "pwd", # default password
	   'timeout_query',     "2",   # query file timeout in days
	   'timeout_res',       "2",   # result file timeout in days
				# --------------------------------------------------
				# PP: executables
				# system stuff
	   'exe_batch_queue',   "/usr/local/lsf/bin/bsub", # batch queue,br: 12.97 not used)
	   'exe_quota',         $Arch_exe_quota{$ARCH},
	   'exe_ps',            $Arch_exe_ps{$ARCH},
	   'exe_nice',          $Arch_exe_nice{$ARCH},
	   'exe_mail',          $Arch_exe_mail{$ARCH},
				# packages
	   'pp_predPack',       $dppScript.    "/"."predPackPP.pl",
	   'pp_licPack',        $dppScript.    "/"."licencePackPP.pl",
	   'pp_scan',           "nice -19 ".$dppScript."/"."scannerPP.pl", # PP scanner
	   'pp_pred',           $dppScript.    "/"."predManagerPP.pl",
	   'pp_emailPred',      $dppScript.    "/"."emailPredPP.pl",
	   'pp_procmail',       $dppScript.    "/"."procmail.pl",
#	   'lib_pp',            $dutPerl.      "/"."lib-ppNew.pl", # perl lib to link (require)
#	   'lib_ppErr',         $dutPerl.      "/"."lib-ppErr.pl", # perl lib to link (require)
	   'lib_pp',            $dppScript.    "/"."lib-ppNew.pl", # perl lib to link (require)
	   'lib_ppErr',         $dppScript.    "/"."lib-ppErr.pl", # perl lib to link (require)
	   'lib_cgi',           $dutPerl.      "/"."cgi-lib.pl",   # perl lib for HTML to link
	   'lib_ctime',         $dutPerl.      "/"."ctime.pl",     # perl lib for ctime
				# utilities
	   'exe_stripstars',    $dutPerl.      "/"."stripstars.pl",
	   'exe_scan_clean',    $dutPerl.      "/"."scanCleanUp.pl", # clean up
	   'exe_status',        $dutPerl.      "/"."checkPPstatus.pl",
                                # ----------------------------------------
				# PERL SCRIPTS AND PACKAGES
                                # ----------------------------------------
				# --------------------------------------------------
				# PP: directories
	   'dir_pp_home',       "/home/phd", # home path
	   'dir_default',       "/home/phd", # where file might be created by default
	   'dir_work',          $dir_work,   # intermediate files to put here
				# NOTE: for WWW access MUST be writable (or change wwwPredict.pl)
	   'dir_predict',       $dppPred,    # files to be run by prediction
	   'par_patDirPred',    "pred_",     # files in dir_predict 'pred_e|h*'
	   'dir_result',        $dppResult,  # files with results
				# NOTE: for WWW access MUST be writable (or change wwwPredict)
	   'dir_mail',          $dppMail,    # where to place the mail query and result
	   'dir_inProc',        $dppInProc,  # where procmail-stork.pl puts mail input
				# dir_save_pred will die yyDO_ONE_DAY
#	   'dir_save_pred',     "/home/phd/server/bup", # compressed result files for bup
	   'dir_save_pred',     "/trash/phd/bup", # 
				# dir_trash will die yyDO_ONE_DAY
	   'dir_trash',         "/trash/phd/err", # temporary trace
	   'dir_bup_res',       "/trash/phd/res", # temporary trace
	   'dir_bup_errIn',     "/trash/phd/errIn", # temporary trace
	   'dir_bup_err',       "/trash/phd/err", # temporary trace
	   'dir_bup_errMail',   "/trash/phd/errMail",
				# dir_error will die yyDO_ONE_DAY
#xx	   'dir_error',         $dppError,   # where to put files in case of error
	   'dir_error',         "/trash/phd/err", # dont want to see them anymore!
	   'dir_ut',            $dut,        # perl utilities, programs, asf
	   'dir_ut_txt',        $dutTxt,     # text files
	   'dir_ut_perl',       $dutPerl,    # perl scripts
				# --------------------------------------------------
				# PP: files
	   'file_scanFlag',     $dppServer.    "/"."PHD_SCAN_RUN", # flags activity of scanner
	   'file_ppLog',        $dppLog.       "/"."phd.log", # all requests
	   'file_comLog',       $dppLog.       "/"."phd_com_pred.log", # commercial predictions
	   'file_errLog',       $dppLog.       "/"."ERROR.log", # general errors
	   'file_predMgrLog',   $dppLog.       "/"."out-predManager.log", # log for predManager.pl
	   'file_scanLog',      $dppLog.       "/"."scan.log", # requests found by scanner
	   'file_sendLog',      $dppLog.       "/"."emailSend.log", # log of email sent
	   'file_emailReqLog',  $dppLog.       "/"."pred-email.log", # log of email requests
	   'file_procmailLog',  $dppLog.       "/"."procmail.log", # log of procmail
	   'file_procmailInLog',$dppLog.       "/"."procmail-in.log", # log of procmail
				# NOTE: for WWW access MUST be writable (or change wwwPredict)
#	   'file_htmlReqLog',   $dppLog.       "/"."pred-html.log", # log of HTML requests
	   'file_htmlReqLog',   $dppLog.       "/"."pred-html2.log", # log of HTML requests
	   'file_licenceLog',   $dppLog.       "/"."licenceControl.log", # log of licence control
	   'file_crontabLog',   $dppLog.       "/"."crontab.log",	# log of crontab job
	   'file_vmsLog',       "/vms/u/phd/phd.logfile", # VMS log file 
	   'file_batchLog',     $dppLog.       "/"."bqueue.log", # batch queue out file

	   'file_htmlLicOrd',   $dppWWW.       "/"."licence_order.html", # html licence order file
	   'file_licence',      $dppLog.       "/"."phd_licence", # list of commercial licences
	   'file_key',          $dppLog.       "/"."phd_key", # file of user key 
	   'file_scanOut',      $dppLog.       "/"."scan.out",	# redirection of scanner output
	   'file_scanMach',     $dppLog.       "/"."scan.machine", # couple machine/job id
	   'file_scanErr',      $dppLog.       "/"."scan.err", # redirection of scanner error
				# STDOUT from programs such as convert_seq (as run_program)
	   'file_scanScreen',   $dppLog.       "/"."scan.screen",

	   'file_statusLog',    $dppWWW.       "/"."PPstatus.log", # WWW readable file with Status
	   'file_h_status',     $dppWWW.       "/"."PPstatus.history",
	   'file_a_status',     $dppWWW.       "/"."PPstatus.add",
	   'flag_status',       $dppWWW.       "/"."PPstatus.flag", # flag to avoid double writing

	   'file_htmlFmtErr',   $dutTxt.       "/"."appWrgFormatHtml",	# html format error

				# --------------------------------------------------
				# PP: parameters
				# --------------------------------------------------
	   'para_status',       "normal", # if "normal" -> normal execution with date
#	   'para_status',       "copy", # copy a file

				# --------------------------------------------------
				# FILES

				# ==================================================
				# PHD
				# ==================================================
				# PHD: executables
	   'exePhd',            $dutPhd.       "/"."phd.pl",
#	   'exePhd',            $dutPhd.       "/"."xphd.pl", # zzz
	   'exePhdFor',         $Arch_exePhd{$ARCH},

	   'exePhdHtmisit',     $dutPhdScripts."/"."phd_htmisit.pl",
	   'exePhdHtmfil',      $dutPhdScripts."/"."phd_htmfil.pl",
	   'exePhdHtmref',      $dutPhdScripts."/"."phd_htmref.pl",
	   'exePhdHtmtop',      $dutPhdScripts."/"."phd_htmtop.pl",

	   'exePhdRdb2kg',      $dutPhdScripts."/"."rdb_tokg.pl",
	   'exePhd2msf',        $dutPhdScripts."/"."conv_phd2msf.pl",
	   'exePhd2dssp',       $dutPhdScripts."/"."conv_phd2dssp.pl",
	   'exePhd2casp2',      $dutPhdScripts."/"."conv_phd2casp2.pl",
#	   'exeGlobe',          $dutPerl.      "/"."globe.pl",
                                # ----------------------------------------
				# PHD: directories
	   'dirPhd',            $dutPhd,
	   'dirPhdPar',         $dutPhdPara,
	   'dirPhdScr',         $dutPhdScripts,
	   'dirPhdNet',         $dutPhdNet,
	   'dirPhdTxt',         $dutPhdTxt,
                                # ----------------------------------------
				# PHD: files
	   'filePhdDefaults',   $dutPhd.       "/"."Defaults.phd",
#	   'filePhdDefaults',   $dutPhd.       "/"."xDefaults.phd",  # zzz

	   'filePhdParaAcc',    $dutPhdPara.   "/"."Para-exp152x-mar94.com",
	   'filePhdParaHtm',    $dutPhdPara.   "/"."Para-htm69-aug94.com",
	   'filePhdParaSec',    $dutPhdPara.   "/"."Para-sec317-may94.com",
#	   'filePhdParaAcc',    $dutPhdPara.   "/"."Para-exptest.com", # zzz
#	   'filePhdParaHtm',    $dutPhdPara.   "/"."Para-htmtest.com", # zzz
#	   'filePhdParaSec',    $dutPhdPara.   "/"."Para-test.com",    # zzz
                                # ----------------------------------------
				# PHD: parameters
	   'parPhdArg8',        $Arch_phdArg8{$ARCH},

	   'parPhdMinLen',      "17",  # minimal length of sequence
	   'parPhdSubsec',      "4",   # reliability cut-off for subsets
	   'parPhdSubacc',      "3",
	   'parPhdSubsymbol',   ".",   # symbol used for subset
	   'parPhdHtmDef',      "0.8", # default value for HTM segment
	   'parPhdHtmMin',      "0.2", # minimal value for HTM segment
	   'parPhdNlineMsf',    "60",  # number of character in phd.msf format
				               # smaller ones -> return no HTM
				# ==================================================
                                # TOPITS
				# ==================================================
				# TOPITS: executables
	   'exeTopits',         $dutTopits.    "/"."topits.pl",
#	   'exeTopits',         $dutTopits.    "/"."xtopits.pl", # zzz
	   'exeTopitsMaxhomCsh',$dutTopits.    "/"."maxhom_topits.csh",
	   'exeTopitsMakeMetr', $Arch_exeMetric{$ARCH},
#	   'exeTopitsWrtOwn',   $dutTopits."/scr/"."topitsWrtOwn.pl",
                                # ----------------------------------------
				# TOPITS: directories
	   'dirTopits',         $dutTopits,
	   'dirTopitsMat',      $dutTopitsMat,
                                # ----------------------------------------
                                # TOPITS: files
	   'fileTopitsDef',     $dutTopits.    "/"."Defaults.topits",
#	   'fileTopitsDef',     $dutTopits.    "/"."xDefaults.topits", # zzz
	   'fileTopitsMaxhomDef',$dutTopits.   "/"."Defaults.maxhom",

	   'fileTopitsAliList', $dutTopitsMat. "/"."Topits_dssp849.list",
#	   'fileTopitsAliList', $dutTopitsMat. "/"."Topits_dssp1213.list",
#	   'fileTopitsAliList', $dutTopitsMat. "/"."x.list",        # zzz 
#	   'fileTopitsAliList', $dutTopitsMat. "/"."x2.list",        # zzz 

	   'fileTopitsMetrIn',  $dutTopitsMat. "/"."Topits_m3c_in.metric",
	   'fileTopitsMetrSeq', $dutTopitsMat. "/"."Maxhom_McLachlan.metric",
	   'fileTopitsMetrGCG', $dutTopitsMat. "/"."Maxhom_GCG.metric",
                                # ----------------------------------------
                                # TOPITS: parameters
	   'parTopitsSmax',     "2",
	   'parTopitsGo',       "2",
	   'parTopitsMixStrSeq',"50",
	   'parTopitsLindel1',  "1",
	   'parTopitsNhits',    "20",

				# ==================================================
				# Alignment (MaxHom, Fasta, Blast, Convert_seq)
				# ==================================================
	   'exeConvertSeq',     $Arch_exeConvertSeq{$ARCH},
	   'exeBlastp',         $Arch_exeBlastp{$ARCH},
	   'exeBlastpFilter',   $dutPerl.      "/"."filter_blastp",
	   'exeFasta',          "/usr/pub/bin/molbio/fasta",
	   'exeFastaFilter',    "/usr/pub/bin/molbio/filter_fasta",

	   'exeMaxhom',         $Arch_exeMaxhom{$ARCH},
	   'exeHsspExtrHead',   $dutPerl.      "/"."hssp_extr_header.pl",
	   'exeHsspExtrHdr4pp', $dutPerl.      "/"."hssp_extr_hdr4pp.pl",

	   'exeHsspFilter',     $dutPerl.      "/"."hssp_filter.pl",
	   'exeHsspFilterFor',  $dutMaxBin.    "/"."filter_hssp.".$ARCH,
	   'exeHssp2msf',       $dutPhdScripts."/"."conv_hssp2msf.pl",
	   'exeHsspExtrStrip',  $dutPerl.      "/"."hssp_extr_strip.pl",
	   'exeHsspExtrStripPP',$dutPerl.      "/"."pp_strip2send.pl",
	   'exeHssp2pir',       $dutPerl.      "/"."hssp_extr_2pir.pl",
                                # ----------------------------------------
				# MaxHom: directories
	   'dirMaxhom',         $dutMax,
	   'dirMaxhomMat',      $dutMaxMat,
	   'dirData',           "/data", # dir of databases
	   'dirSwiss',          "/data/swissprot", # Swissprot directory
	   'dirSwissSplit',     "/data/swissprot/current", # SWISS-PROT split
	   'dirPdb',            "/data/pdb", # 
				# was dead on Feb 1, 1998
#	   'dirBrookhaven',     "/data/brookhaven", # Fasta format of PDB
                                # ----------------------------------------
				# MaxHom: files
	   'fileMaxhomDefaults',$dutMax.       "/"."maxhom.default",
	   'fileMaxhomMetrSeq', $dutMaxMat.    "/"."Maxhom_McLachlan.metric",
	   'fileMaxhomMetr',    $dutMaxMat.    "/"."Maxhom_Blosum.metric",
#	   'fileMaxhomMetr',    $dutMaxMat.    "/"."Maxhom_GCG.metric",
	   'envBlastMat',       "/home/pub/molbio/blast/blastapp/matrix",
	   'envBlastDb',        "/data/db/",
	   'envProdomBlastDb',  "/home/phd/ut/prodom/",
	   
	   'envFastaLibs',      "/home/pub/molbio/fasta/fastgbs",
	   'extPdb',            ".brk",	# PDB extension
	   'fileBrookhaven',    "/data/brookhaven/brookhaven",
                                # ----------------------------------------
				# MaxHom: parameters
	   'seq_method',        "blast", # Seq research method (blast or fasta)

	   'parFastaNhits',     "500",       # number of hits reported by FASTA
	   'parFastaThresh',    "FORMULA+1", # option for filtering FASTA
	   'parFastaScore',     "100",       # unclear...
	   'parFastaSort',      "DISTANCE",

	   'parBlastDb',        "swiss",     # database to run BLASTP against
	   'parBlastNhits',     "2000",
				             # database to run BLASTP against PRODOM
	   'parProdomBlastDb',  "/home/phd/ut/prodom/prodom_34_2",
	   'parProdomBlastN',   "500",
	   'parProdomBlastE',   "0.1",       # E=0.1 when calling BLASTP (PRODOM)
	   'parProdomBlastP',   "0.1",       # probability cut-off for PRODOM

	   'parMaxhomMinIde',   "30",        # minimal sequence identity for MAXHOM search
				
	   'parMaxhomExpMinIde',"15",        # minimal sequence identity (experts)
	   'parMaxhomMaxNres',  "5000",      # maximal length of sequence
	   'parMaxhomMaxACGT',  "80",        # max content of ACGT (otherwise=DNA,RNA?)
	   'parMaxhomLprof',    "NO",
	   'parMaxhomSmin',     -0.5,        # standard job
	   'parMaxhomSmax',     1.0,         # standard job
	   'parMaxhomGo',       3.0,         # standard job
	   'parMaxhomGe',       0.1,         # standard job
	   'parMaxhomW1',       "YES",       # standard job
	   'parMaxhomW2',       "NO",        # standard job
	   'parMaxhomI1',       "YES",       # standard job
	   'parMaxhomI2',       "NO",        # standard job
	   'parMaxhomNali',     500,         # standard job
	   'parMaxhomSort',     "DISTANCE",  # standard job
	   'parMaxhomProfOut',  "NO",        # standard job

	   'parMaxhomTimeOut',  10000,       # secnd ~ 3hrs, then: send alarm MaxHom suicide!

	   'parMinLaliPdb',     30,          # minimal length of ali to report: 'has 3D homo'
				# ==================================================
				# other jobs (Prosite, Coils, Repeats)
				# ==================================================
	   'exeProsite',        $Arch_exeProsite{$ARCH},
	   'exeCoils',          $Arch_exeCoils{$ARCH},
	   'exeRepeats',        $Arch_exeRepeats{$ARCH},
	   'parCoilsMin',       0.5,         # minimal prob for considering it a coiled-coil
	   'parCoilsMetr',      "MTK",       # two metrices allowd MTK|MTDIK
	   'parCoilsWeight',    "Y",         # weighting a & f (by 2.5), for no weight 'N'
	   'parCoilsOptOut',    "col",       # output column-wise (needed for post-processing)
	   
				# ==================================================
                                # WHATIF
				# ==================================================
                                # WHATIF: executables
	   'exeWhatif',         $Arch_exeWhatif{$ARCH},
				# --------------------------------------------------
                                # WHATIF: directories
	   'dirWhatif',         "/trash/vriend/joepie/",
				# --------------------------------------------------
                                # WHATIF: parameters
	   'parWhatifMinIde',   "50",  # minimal sequence identity for homology modelling
	   'parWhatifExpMinIde',"30",  # minimal sequence identity (experts)
	   'parWhatifMinLen',   "0.6", # minimal length ratio (L1/L2) for modelling
	   'parWhatifExpMinLen',"0.1", # minimal length ratio (L1/L2) (experts)
				# ==================================================
				# EVALSEC
				# ==================================================
				# EVALSEC: executables
	   'exeEvalsec',        $dutPerl."/"."evalsec.pl",
	   'exeEvalsecFor',     $Arch_exeEvalsec{$ARCH},
				# ==================================================
				# ==================================================
                                # ----------------------------------------
                                # miscellaneous
				# message files to be appended
				# PP: stuff
	   'fileHelpText',      $dutTxt.       "/"."Help.text",
#	   'fileHelpText',      $dutTxt.       "/"."help-98-04.text",
	   'fileHelpConcise',   $dutTxt.       "/"."Help.concise",
	   'fileNewsText',      $dutTxt.       "/"."News.text",
#	   'fileNewsText',      $dutTxt.       "/"."news-98-04.text",
	   'fileLicText',       $dutTxt.       "/"."Licence.text",
	   'fileAppErrCrypt',   $dutTxt.       "/"."appIntErr",
	   );
				# extension '.txt'
    foreach $kwd ("fileHeadPhdConcise","fileHeadPhd3","fileHeadPhdBoth",
		  "fileHeadPhdSec","fileHeadPhdAcc","fileHeadPhdHtm",
		  "fileHeadEvalsec"){
	$file=$kwd;$file=~s/^fileHead/head/g;
	$envL{"$kwd"}=           $dutTxt.       "/"."$file" . ".txt";}
    foreach $kwd ("fileAppLicPwd",       "fileAppLicExhaust",   "fileAppLicExpired",
		  "fileAppLicNew",       "fileAppWhatifNotyet", "fileAppLine",
		  "fileAppInSeqConv",    "fileAppInSeqSent",
		  "fileAppEvalsec",      "fileAppHssp",       
		  "fileAppPred",         "fileAppPredPhd",      "fileAppGlobe",        
		  "fileAppProdom",       "fileAppProsite",      "fileAppCoils",
		  "fileAppMsfWarning",   "fileAppSafWarning",   "fileAppWarnSingSeq",
		  "fileAppTopitsNohom",  "fileAppIlyaPdb",      "fileAppMembrane",

		  "fileAppRetBlastp",    "fileAppRetMsf",       "fileAppRetNoali", 
		  "fileAppRetTopitsOwn", "fileAppRetTopitsHssp","fileAppRetTopitsStrip",
		  "fileAppRetTopitsMsf", "fileAppRetPhdMsf",    "fileAppRetPhdRdb",    
		  "fileAppRetGraph",     "fileAppRetCol",       "fileAppRetPhdCasp2",

		  "fileAppWrgMsfexa",    "fileAppWrgSafexa",
#		  "fileAppInGeneSeq","fileAppInTooShort","fileAppInTooLong",
#		  "fileAppWrgColumn","fileAppWrgColphd","fileAppWrgEvalsec",
#		  "fileAppWrgFormat","fileAppWrgFormatMsf","fileAppWrgFormatSaf",
#		  "fileAppIntErr","fileAppWhatifCutoff","fileAppWrgWhatifMsf",
#		  "fileAppWhatifNohom","fileAppWhatifNotyet","fileAppWhatifOut"
		  ){
	$file=$kwd;$file=~s/^file//g;
	$tmp=substr($file,1,1);$tmp=~tr/[A-Z]/[a-z]/ if ($file=~/head|app/i);
	$file=$tmp.substr($file,2);
	$envL{"$kwd"}=           $dutTxt.       "/"."$file" ;}
}				# end of SETENV

#===============================================================================
sub isRunningEnv{
    local ($process,$ps_cmd,$fhLoc) = @_;
    local ($sbrName,$ctJobs,@result);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isRunningEnv                test if a program runs (returns nr of occ found)
#       in:                     $process,$ps_cmd,$fhLoc
#       out:                    number of jobs running
#-------------------------------------------------------------------------------
    $sbrName="isRunning";
    return(0,"*** $sbrName: no process given!")    if (! defined $process);
    return(0,"*** $sbrName: no ps_comand given!")  if (! defined $ps_cmd) ;
				# remove path
    $process=~ s/^.*\///;	# 
    if (defined $fhLoc){
	print $fhLoc "ps=$ps_cmd "."|"." grep $process "."|"." grep -v 'grep'\n";}
				# run a ps command
    @result= `$ps_cmd | grep $process | grep -v 'grep' `;
#    @result= `$ps_cmd | grep $process | grep -v 'grep' | grep -v '$process\.\.'`;

    $ctJobs=$#result;
    print "lib-pp:$sbrName: #result=$ctJobs (xx)\n";

    return (1,$ctJobs);		# return the number of processes found 
}				# end of isRunningEnv

#===============================================================================
sub getLocal{
    local ($parameter) = @_;
#-------------------------------------------------------------------------------
#   getLocal                    Put all env parameters in an associative array %envL
#-------------------------------------------------------------------------------
    if ($envL{"$parameter"}) {
	return $envL{"$parameter"} }
    else {
	return(0); }
}				# end of getLocal

1;

