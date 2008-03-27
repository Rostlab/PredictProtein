#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
##!/usr/pub/bin/perl5.00 -w
##! /usr/pub/bin/perl4
#===============================================================================
#                                                                              #
#------------------------------------------------------------------------------#
#	Copyright				        	 2003	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	       	        	http://cubic.bioc.columbia.edu/~rost/	       #
#	Jinfeng Liu             liu@cubic.bioc.columbia.edu  		       #
#       Columbia University, US                                                #
#                                                                              #
#	Copyright				        	 1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#                                                                              #
#	Copyright				  Dec,    	 1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#			    br  v 0.2   	  Sep,           1995          #
#			    br  v 0.3   	  Nov,           1995          #
#			    br  v 0.4   	  Feb,           1996          #
#			    br  v 0.5   	  Mar,           1996          #
#			    AD  v 0.6   	  Apr,           1996          #
#			    br  v 0.7   	  May,           1996          #
#			    br  v 0.8   	  Jul,           1996          #
#			    br  v 0.9   	  Sep,           1996          #
#			    br  v 1.0   	  Feb,           1997          #
#			    br  v 1.1   	  Apr,           1997          #
#			    br  v 1.2   	  Jun,           1997          #
#			    br  v 1.5             Nov,           1997          #
#			    br  v 2.0   	  Jan,           1998          #
#			    br  v 2.1   	  Feb,           1998          #
#			    br  v 2.2   	  Mar,           1998          #
#			    br  v 2.3   	  May,           1998          #
#			    br  v 2.4   	  Jan,           1999          #
#			    br  v 2.5   	  Mar,           1999          #
#			    br  v 2.6   	  Apr,           1999          #
#------------------------------------------------------------------------------#
# 
#   Note: The normal hierarchy is:
#         scanPP->predManager      scanner calls the manager
#         predManager->predPP      manager calls this package
#         predPP:                  executes the predictions, asf
#         
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text markers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  - 'xdbg'       : comment out piping the output into log files
#  
#  
#--------------------------------------------------------------------------------#

package predictPP;

INIT: {
				# --------------------------------------------------
				# Read environment parameters
				# --------------------------------------------------

				# include phd_env package as define in $PPENV or default
    if ($ENV{'PPENV'}) {
	$LisLocal=1;
	$env_pack= $ENV{'PPENV'}; }
    else {			# this is used by the automatic version!
	$LisLocal=0;
	$env_pack= "/home/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED
    $Lok=
	require "$env_pack";
				# ------------------------------
    $scrName=$0;		# get the name of this file
    $scrName=~s,.*/,,; $scrName=~s/\.pl//g;

    return(0,"*** err=10001\n*** INIT_$scrName ERROR when 'require ($env_pack)'\n")     
	if (! $Lok);

    ($Lok,$msg)=		# initialise environment (from env_pack)
	&initPackEnv();
				# ******************************
				# error in INIT
    return(0,"*** err=10002\n*** INIT_$scrName ERROR in envPP ($env_pack)'\n"."$msg\n") 
	if (! $Lok);
}				# end OF INIT SECTION

#===============================================================================
sub predict {
    ($File_name,$File_result,$User_name,$Password,$Origin,$Debug) = @_;
    local ($file_in,$command,$tmp1,$tmp2);
    $[=1;
#-------------------------------------------------------------------------------
#   predict                     Main SBR, runs the prediction process.
#                               Only routine that should be called 
#                               from external programs/sbrs
#   note:                       $User_name changed in modInterpret:extrHdr:extrHdrOneline
#                               if keyword SEND_RESULTS_TO user@machine
#-------------------------------------------------------------------------------
    $packName="predPackPP";
				# --------------------------------------------------
				# include scripts and define constants
				# --------------------------------------------------
#                               # note: global names envPP{} if you want to keep next line
    foreach $kwd ("pack_licence",
		  "lib_pp","lib_err","lib_col",
		  ){
	$Lok=0;
	$Lok=require($envPP{$kwd}) if (-e $envPP{$kwd}); 
	return(0,"*** err=10003\n*** INIT_$scrName ERROR when 'require (".$envPP{$kwd}.")'\n")
	    if (! $Lok);}


				# ------------------------------
    &iniPredict();		# initialise file names asf


    print $fhTrace 
	"--- $packName started with ($File_name,$File_result,".
	    "$User_name,$Password,$Origin,$Debug)\n";

    $file{"in"} = $File_name;

#-------------------------------------------------------------------------------
#   (1) before everything: clean file, check_licence, check_encrypt
#-------------------------------------------------------------------------------
    if ($Origin =~ /^mail|^html|^testPP/i){
	($Lok,$err,$msg)=
	    &modBefore($File_name,$filePredTmp,$filePID,$Debug,$envPP{"dir_work"},$fhOut);
				# --------------------------------------------------
				# note: Lok= 0 means internal error
				#       err= 'ok,err=N' means is error, but doesnt kill!
	if (! $Lok && ($err !~/^ok/)){ # 
	    print $fhTrace "*** ERROR in modBefore (err=$err) msg=\n$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort".$msg);  
	    $msg="err=1 ($packName)\n".$msg;
	    print $fhTrace "$err\n","$msg2\n"."$msg\n" if ($Debug && ! $Lok); 
				# **************************************************
	    return(0,"$msg");}	# <<<<< this is a bad end (1)
				# **************************************************
	elsif (! $Lok){
	    print $fhTrace "$err\n","$msg\n" if ($Debug); }}
    else {
	($Lok,$msgSys)=&sysSystem("echo '$Date' >> $filePredTmp",0);}

    &ctrlDbgMsg("end of (1) modBefore: $packName",$fhTrace,$Debug);

#-------------------------------------------------------------------------------
#   (2) extract sequence
#-------------------------------------------------------------------------------
				# default database
    $parBlastDb=$envPP{"parBlastDb"};
				# ----------------------------------------
				# origin = 'mail|html|testPP' or : ->
                                #           combi: 'blast,maxhom,phd,topits,noali'
    if ($Origin =~ /^mail|^html|^testPP/i){
	($Lok,$err,$msg,$parBlastDb)=
	    &modInterpret($File_name,$filePID,$fileHtmlTmp,$fileHtmlToc,
			  $envPP{"dir_work"},$fhOut,$fhTrace,$Debug,$envPP{"parPhdMinLen"},
			  $envPP{"parMaxhomMaxNres"},$envPP{"parMaxhomMaxACGT"});
	if    (! $Lok){		# internal ERROR
	    print $fhTrace "*** ERROR in modInterpret (err=$err) msg=\n$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort=".$msg);  print $fhTrace "$msg2\n" 
		    if ($Debug && ! $Lok);
	    $msg="err=21 ($packName)\n".$msg;
				# **************************************************
	    return(0,"$msg");}	# <<<<< this is the 2nd bad end (21)
				# **************************************************

	elsif ($err eq "help"){
	    ($Lok,$msg2)=
		&ctrlAbortPred("no err","ok=help: text is wanted");
	    print $fhTrace "$msg2\n" if ($Debug && ! $Lok);
				# ..................................................
	    return(1,"help");}  # help request (this is the first positive end)
				# ..................................................

	elsif ($Lok >= 3){	# user FORMAT ERROR
	    print $fhTrace "*** ERROR in input format from modInterpret (err=$err) msg=\n$msg\n" 
		if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort usr=".$msg);  
	    print $fhTrace "$msg2\n" if ($Debug && ! $Lok);
				# ..................................................
	    return(1,"$msg");}	# this is 'good' end: ERROR from USER!
				# ..................................................
    }

				# ----------------------------------------
                                # interactive 'manual' run of PP
    else {			#    possible arguments 'blast,maxhom,phd,topits'
	($Lok,$err,$msg)=	#    input MUST be accordingly!
	    &modInterpretManu($File_name,$filePID,$envPP{"dir_work"},$fhOut,$Debug,$Origin);
	if (! $Lok){		# note: also internal errors terminate here!
	    print $fhTrace "*** ERROR in modInterpretManu (err=$err) msg=\n$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
		    if ($Debug && ! $Lok);
	    $msg="err=24 ($packName)\n".$msg;
				# **************************************************
	    return(0,"$msg");}}	# <<<<< this is the other bad 2nd end (22)
				# **************************************************
    &ctrlDbgMsg("end of (2) modInterpret: $packName",$fhTrace,$Debug);

#-------------------------------------------------------------------------------
#   (3) convert sequence format
#-------------------------------------------------------------------------------

    if ($job{"run"}=~/convert/){
	($Lok,$err,$msg)=
	    &modConvert($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,$envPP{"dir_work"},
			$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Debug,$job{"seq"},
			$envPP{"exeCopf"},$envPP{"exeConvertSeq"},
			$envPP{"exePhd2dssp"},$envPP{"exeMaxhom"},
			$envPP{"exeHsspExtrHdr4pp"},$envPP{"fileMaxhomDefaults"},
			$envPP{"parMaxhomLprof"},
			$envPP{"fileMaxhomMetr"},$envPP{"fileMaxhomMetrLach"},
			$envPP{"parMaxhomSmin"},$envPP{"parMaxhomSmax"},
			$envPP{"parMaxhomGo"},$envPP{"parMaxhomGe"},$envPP{"parMaxhomW1"},
			$envPP{"parMaxhomW2"},$envPP{"parMaxhomI1"},$envPP{"parMaxhomI2"},
			$envPP{"parMaxhomNali"},$envPP{"parMaxhomSort"},
			$envPP{"dirPdb"},$envPP{"parMaxhomProfOut"},
			$envPP{"parMaxhomTimeOut"},$envPP{"parMinLaliPdb"},$screenMax);
	if (! $Lok){		# note: also internal errors terminate here!
	    print $fhTrace "*** ERROR in modConvert (err=$err) msg=\n$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
		    if ($Debug && ! $Lok);
	    $msg="err=31 ($packName)\n".$msg;
				# **************************************************
	    return(0,"$msg");}}	# <<<<< this is bad end 3
				# **************************************************
    &ctrlDbgMsg("end of (3) modConvert: $packName",$fhTrace,$Debug);

#-------------------------------------------------------------------------------
#   (4) alignment BLAST / MaxHom  (or EVALSEC)
#-------------------------------------------------------------------------------

    if   ( $job{"run"} !~ /chop_only/ and 
	   ($job{"run"}=~/blast|fasta|maxhom|prodom|filter|prosite/) || 
	  ($job{"out"}=~/ret.*ali.*(prof|hssp)/)) {
	($Lok,$err,$msg)=
	    &modAlign($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
		      $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Debug,
		      $job{"seq"},$job{"run"},$job{"out"},
		      $envPP{"dirData"},$envPP{"dirPdb"},$envPP{"dirSwissSplit"},
		      $envPP{"exeCopf"},$envPP{"exeConvertSeq"},
		      $envPP{"fileMaxhomMetrSeq"},$envPP{"fileMaxhomMetrSeqAll"},

		      $envPP{"exeProsite"},$envPP{"filePrositeData"},
		      $envPP{"exeSeg"},$envPP{"parSegNorm"},$envPP{"parSegNormMin"},
		      $envPP{"envProdomBlastDb"},$envPP{"parProdomBlastDb"},$envPP{"parProdomBlastN"},
		      $envPP{"parProdomBlastE"},$envPP{"parProdomBlastP"},
#		      $envPP{"exeFasta"},$envPP{"exeFastaFilter"},$envPP{"envFastaLibs"},
#		      $envPP{"parFastaNhits"},$envPP{"parFastaThresh"},$envPP{"parFastaScore"},
#		      $envPP{"parFastaSort"},
		      
		      $envPP{"exeBlastPsi"},$envPP{"exeBlast2Saf"},
		      $envPP{"envBlastPsiDb"},$envPP{"parBlastPsiArg"},$envPP{"parBlastBigArg"},
		      $envPP{"parBlastTile"},
		      $envPP{"parBlastPsiDb"},$envPP{"parBlastPsiDbBig"},$envPP{"parBlastFilThre"},
		      $envPP{"parBlastMaxAli"},$envPP{"exeBlastRdbExtr4pp"},

		      $envPP{"exeBlastp"},$envPP{"exeBlastpFilter"},
		      $envPP{"envBlastMat"},$envPP{"envBlastDb"},
		      $envPP{"parBlastNhits"},$parBlastDb,
		      $envPP{"exeMaxhom"},$envPP{"fileMaxhomDefaults"},$envPP{"parMaxhomLprof"},
		      $envPP{"parMaxhomSmin"},$envPP{"parMaxhomSmax"},$envPP{"parMaxhomGo"},
		      $envPP{"parMaxhomGe"},$envPP{"parMaxhomW1"},$envPP{"parMaxhomW2"},
		      $envPP{"parMaxhomI1"},$envPP{"parMaxhomI2"},$envPP{"parMaxhomNali"},
		      $envPP{"parMaxhomSort"},$envPP{"parMaxhomProfOut"},
		      $envPP{"parMaxhomTimeOut"},$envPP{"parMinLaliPdb"},
		      $envPP{"parMaxhomMinIde"},$envPP{"parMaxhomExpMinIde"},
		      $envPP{"exeHsspExtrHdr4pp"},$envPP{"urlSrs"},
				# filter alignment
		      $envPP{"exeHsspFilter"},$envPP{"exeHsspFilterFor"},
		      $envPP{"parFilterAliOff"},$envPP{"parFilterAliPhd"},$screenMax,
				# HTML output
		      $envPP{"exeMview"},$envPP{"parMview"}
		      );

	if (!$Lok){		# 
	    &ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n"
		if ($Debug && ! $Lok);
				# **************************************************
	    return(0,"$msg");}  # <<<<< ****** this is bad end 4
				# **************************************************
	&ctrlDbgMsg("end of (4a) modAlign: $packName",$fhTrace,Debug);}	# 


				# ------------------------------
				# EVALSEC
				# ------------------------------
    elsif ($job{"run"}=~/evalsec/){
	($Lok,$err,$msg)=
	    &runEvalsec($Origin,$Date,$niceRun,$filePID,$fhTrace,$envPP{"dir_work"},
			$filePredTmp,$Debug,$file{"seq"},
			$envPP{"exeEvalsec"},$envPP{"exeEvalsecFor"});
		  
	if (!$Lok){
	    print $fhTrace "*** ERROR in modEvalsec (err=$err) msg=\n$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
		    if ($Debug && ! $Lok);
				# **************************************************
	    return(0,"$msg");}	# <<<<< ****** this is bad end 4b
				# **************************************************
	&ctrlDbgMsg("end of (4b) runEvalsec: $packName",$fhTrace,Debug);}

				# ------------------------------
				# alignment given
				# ------------------------------
    else {
	$file{"aliPhdIn"}=$file{"ali"};}



#-------------------------------------------------------------------------------
#   (5) other predictions asf (COILS, CYSPRED, NLS ...)
#-------------------------------------------------------------------------------
				# --------------------------------------------------
				# run coils
				# --------------------------------------------------
    if ($job{"run"}=~/coils/){
	($Lok,$err,$msg)=
	    &runCoils($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
		      $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
		      $Debug,$job{"run"},$job{"out"},
		      $envPP{"exeConvertSeq"},$envPP{"exeCoils"},$envPP{"parCoilsMin"},
		      $envPP{"parCoilsMetr"},$envPP{"parCoilsWeight"},
			$screenCoils);
				# ******************************
				# hack br 99-02, problems 
	if (!$Lok){
	    print $fhTrace "*** ERROR in runCoils\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in runCoils\n*** err=$err\n*** msg=$msg\n";
	    if (0){
		($Lok,$msg2)=
		    &ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
			if ($Debug && ! $Lok);
				# **************************************************
		return(0,"$msg");}	# <<<<< ****** this is bad end 5.1
				# **************************************************
	}
    }
    &ctrlDbgMsg("end of (5a) runCoils: $packName",$fhTrace,$Debug);
	
				# -----------------------------------------------
				# run Cyspred
				# -----------------------------------------------
    if ($job{"run"} =~/cyspred/i) {
	($Lok,$err,$msg)=
	    &runCyspred ($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
			 $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
			 $Debug,$job{"run"},$job{"out"},
			 $envPP{"exeCopf"},$envPP{"exeCyspred"}, 
			 $file{"aliPhdIn"},$envPP{"dirCyspred"});
	if (!$Lok){
	    print $fhTrace "*** ERROR in runCyspred\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in runCyspred\n*** err=$err\n*** msg=$msg\n";
	    if (0){
		($Lok,$msg2)=
		    &ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
			if ($Debug && ! $Lok);
				# **************************************************
		return(0,"$msg");} # <<<<< ****** this is bad end 5.2
				# **************************************************
	}
    }
    &ctrlDbgMsg("end of (5b) runCyspred: $packName",$fhTrace,$Debug);

    if ($job{"run"} =~ /nls/i) {
	($Lok,$err,$msg)=	
	    &runNls($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
		    $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
		    $Debug,$job{"run"},$job{"out"},$envPP{"exeNls"});
	if (!$Lok) {
	    print $fhTrace "*** ERROR in runNls\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in runNls\n*** err=$err\n*** msg=$msg\n";
	}
    }
    &ctrlDbgMsg("end of (5c) runNls: $packName",$fhTrace,$Debug);



#-------------------------------------------------------------------------------
#   (6) run PHD, TOPITS
#-------------------------------------------------------------------------------
				# --------------------------------------------------
				# run PHD
				# --------------------------------------------------
    if ($job{"run"}=~/phd/){
	($Lok,$err,$msg)=
	    &runPhd($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,$envPP{"dir_work"},
		    $filePredTmp,$fileHtmlTmp,$fileHtmlToc,
		    $Debug,$job{"run"},$job{"out"},
		    $file{"aliPhdIn"},$envPP{"exePhd"},
		    $envPP{"exePhdFor"},$envPP{"exePhdHtmfil"},
		    $envPP{"exePhdHtmref"},$envPP{"exePhdHtmtop"},$envPP{"exeConvertSeq"},
		    $envPP{"exeHsspFilterFor"},$envPP{"exePhdRdb2kg"},$envPP{"exeCopf"},
		    $envPP{"exePhd2msf"},$envPP{"exePhd2dssp"},$envPP{"exePhd2casp2"},
		    $envPP{"exePhd2html"},
#		    $envPP{"exeGlobe"},
		    $envPP{"filePhdParaSec"},$envPP{"filePhdParaAcc"},
		    $envPP{"filePhdParaHtm"},
#		    $envPP{"parPhdArg8"},
		    $envPP{"parPhdHtmDef"},
		    $envPP{"parPhdHtmMin"},$envPP{"parPhdNlineMsf"},$envPP{"fileMaxhomMetr"});
	if (!$Lok){
	    print $fhTrace "*** ERROR in PHD\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
		    if ($Debug && ! $Lok);
				# **************************************************
	    return(0,$msg);}	# <<<<< ****** this is bad end 5.1
				# **************************************************
	$msg=~s/\n$//g;
	print $fhTrace "$msg\n" if ($Debug);
	&ctrlDbgMsg("end of (6a) runPhd: $packName",$fhTrace,$Debug);}

				# ----------------------------------------
				# run ASP
				# ----------------------------------------

    if ($job{"run"}=~/\basp\b/ and $job{"run"} =~ /phd/){
	($Lok,$err,$msg)=
	    &runAsp($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
		    $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
		    $Debug,$job{"run"},$job{"out"},
		    $envPP{"exeAsp"},$envPP{"parAspWs"},$envPP{"parAspZ"},
		    $envPP{"parAspMin"});
	
	if (!$Lok){
	    print $fhTrace "*** ERROR in runASP\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in runASP\n*** err=$err\n*** msg=$msg\n";

	    #return(0,"$msg"); this is not fatal
	}
    }
    &ctrlDbgMsg("end of (6b) runASP: $packName",$fhTrace,$Debug);

				# --------------------------------------------------
				# run PROF
				# --------------------------------------------------
    if ($job{"run"}=~/prof/){	
	($Lok,$err,$msg)=
	    &runProf($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,$envPP{"dir_work"},
		     $filePredTmp,$fileHtmlTmp,$fileHtmlToc,
		     $Debug,$job{"run"},$job{"out"},
		     $file{"aliPhdIn"},$envPP{"exeProf"},$envPP{"exeProfFor"},$envPP{"exeProfConv"},
		     $envPP{"exeProfHtmfil"},$envPP{"exeProfHtmref"},$envPP{"exeProfHtmtop"},
#		     $envPP{"exeConvertSeq"},$envPP{"exeHsspFilterFor"},$envPP{"exeCopf"},
		     $envPP{"parProfOptDef"},$envPP{"fileProfPara3"},$envPP{"fileProfParaBoth"},
		     $envPP{"fileProfParaSec"},$envPP{"fileProfParaAcc"},$envPP{"fileProfParaHtm"},
		     $envPP{"parProfHtmDef"},$envPP{"parProfHtmMin"},
		     $envPP{"parProfSubsec"},$envPP{"parProfSubacc"},$envPP{"parProfSubhtm"},
		     $envPP{"parProfSubsymbol"},$envPP{"parProfNlineMsf"},$envPP{"parProfMinLen"},
				# yy beg: for time being
		     $envPP{"exeProfPhd1994"},$envPP{"exeProfPhd1994For"}
				# yy end: for time being
		     );
	if (!$Lok){
	    print $fhTrace "*** ERROR in PROF\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
		    if ($Debug && ! $Lok);
				# **************************************************
	    return(0,$msg);}	# <<<<< ****** this is bad end 5.1
				# **************************************************
	$msg=~s/\n$//g;
	print $fhTrace "$msg\n" if ($Debug);
	&ctrlDbgMsg("end of (6c) runProf: $packName",$fhTrace,$Debug);}



                                # ----------------------------------------
				# run Norsp
				# ----------------------------------------
    
    if ($job{"run"}=~/\bnors\b/ and $job{"run"} =~ /coils/ and
	$job{"run"}=~/phdHtm/i and $job{"run"} =~ /prof/ ) {
	($Lok,$err,$msg)=
	    &runNorsp($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
		     $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
		     $Debug,$job{"run"},$job{"out"},
		     $envPP{"exeNorsp"},$envPP{"parNorsWs"},$envPP{"parNorsSecCut"},
		     $envPP{"parNorsAccLen"});
	
	if (!$Lok){
	    print $fhTrace "*** ERROR in runNorsp\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in runNorsp\n*** err=$err\n*** msg=$msg\n";

	    return(0,"$msg") if ( $job{"run"} =~ /nors_only/ ); # this is fatal
	}
    }
    &ctrlDbgMsg("end of (6d) runNors: $packName",$fhTrace,$Debug);

				# ------------------------------------------------
				# this is for NORSp server, run nors_only
				# wrap everything up
				# ------------------------------------------------
    if ( $job{"run"} =~ /nors_only/ ) {
	($Lok,$err,$msg)=
	    &wrapUp_nors($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
			  $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
			  $Debug,$job{"run"},$job{"out"},$opt_nors_verbose);
	
	if (!$Lok){
	    print $fhTrace "*** ERROR in wrapUp_nors\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in wrapUp_nors\n*** err=$err\n*** msg=$msg\n";

	    #return(0,"$msg"); this is not fatal
	}
    }


				# -----------------------------------------------
				# Run ProfCon
				# -----------------------------------------------

    if ($job{"run"} =~/profcon/i) {
	($Lok,$err,$msg)=
	    &runProfCon ($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
			 $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
			 $Debug,$job{"run"},$job{"out"},
			 $envPP{"exeCopf"},$envPP{"exeProfCon"}, 
			 $envPP{"dirProfCon"});
	if (!$Lok){
	    print $fhTrace "*** ERROR in runProfCon\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in runProfCon\n*** err=$err\n*** msg=$msg\n";
	    if (0){
		($Lok,$msg2)=
		    &ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
			if ($Debug && ! $Lok);
				# **************************************************
		return(0,"$msg");} # <<<<< ****** this is bad end 
				# **************************************************
	}
    }
    &ctrlDbgMsg("end of (6e) runProfCon: $packName",$fhTrace,$Debug); 



				# -----------------------------------------------
				# Run Predict Cell Cycle
				# -----------------------------------------------

    if ($job{"run"} =~/pcc/i) {
	($Lok,$err,$msg)=
	    &runPredCC  ($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
			 $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
			 $Debug,$job{"run"},$job{"out"},
			 $envPP{"exeCopf"},$envPP{"exePcc"}, 
			 $envPP{"dirPcc"});
	if (!$Lok){
	    print $fhTrace "*** ERROR in runPredCC\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in runPredCC\n*** err=$err\n*** msg=$msg\n";
	    if (0){
		($Lok,$msg2)=
		    &ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
			if ($Debug && ! $Lok);
				# **************************************************
		return(0,"$msg");} # <<<<< ****** this is bad end 
				# **************************************************
	}
    }
    &ctrlDbgMsg("end of (6f) runPredCC: $packName",$fhTrace,$Debug); 



				# -----------------------------------------------
				# Run CHOP
				# -----------------------------------------------

    if ($job{"run"} =~/chop/i) {
	($Lok,$err,$msg)=
	    &runChop ($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
			 $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
			 $Debug,$job{"run"},$job{"out"},
			 $envPP{"exeCopf"},$envPP{"exeChop"}, 
			 $envPP{"dirChop"},$envPP{"parChopBlastE"},$envPP{"parChoprHmmrE"},
		         $envPP{"parChopDomCov"}, $envPP{"parChopMinFragLen"});
	if (!$Lok){
	    print $fhTrace "*** ERROR in runPredChop\n*** err=$err\n*** msg=$msg\n" if ($Debug);
	    print "*** ERROR in runChop\n*** err=$err\n*** msg=$msg\n";
	    if (0){
		($Lok,$msg2)=
		    &ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
			if ($Debug && ! $Lok);
				# **************************************************
		return(0,"$msg");} # <<<<< ****** this is bad end 
				# **************************************************
	}
    }
    &ctrlDbgMsg("end of (6f) runChop: $packName",$fhTrace,$Debug); 



                                # -----------------------------------------------
                                # Run ProfTmb
                                # -----------------------------------------------

    if ($job{"run"} =~/proftmb/i) {
        ($Lok,$err,$msg)=
            &runProfTmb ($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
                         $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
                         $Debug,$job{"run"},$job{"out"},
                         $envPP{"exeCopf"},$envPP{"exeProfTmb"},
                         $envPP{"dirProfTmb"});
        if (!$Lok){
            print $fhTrace "*** ERROR in runProfTmb\n*** err=$err\n*** msg=$msg\n" if ($Debug);
            print "*** ERROR in runProfTmb\n*** err=$err\n*** msg=$msg\n";
            if (0){
                ($Lok,$msg2)=
                    &ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n"
		    if ($Debug && ! $Lok);
                                # **************************************************
                return(0,"$msg");} # <<<<< ****** this is bad end
                                # **************************************************
        }
    }
    &ctrlDbgMsg("end of (6g) runProfTmb: $packName",$fhTrace,$Debug);



				# -----------------------------------------------
				# Run Predict ProtProt interaction Zafi
				# -----------------------------------------------

#    if ($job{"run"} =~/zafi/i) {
	#($Lok,$err,$msg)=
	 #   &runPredZafi  ($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
		#	 $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
			# $Debug,$job{"run"},$job{"out"},
#			 $envPP{"exeMaxhom"},$envPP{"exeZafi"}, 
#			 $envPP{"dirZafi"});
#	if (!$Lok){
#	    print $fhTrace "*** ERROR in runPredZafi\n*** err=$err\n*** msg=$msg\n" if ($Debug);
#	    print "*** ERROR in runPredZafi\n*** err=$err\n*** msg=$msg\n";
#	    if (0){
#		($Lok,$msg2)=
#		    &ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
#			if ($Debug && ! $Lok);
				# **************************************************
#		return(0,"$msg");} # <<<<< ****** this is bad end 
				# **************************************************
	#}
#    }
 #   &ctrlDbgMsg("end of (6g) runPredZafi: $packName",$fhTrace,$Debug); 




				# --------------------------------------------------
				# run TOPITS
				# --------------------------------------------------
    if ($job{"run"}=~/topits/){
	
	($Lok,$err,$msg)=
	    &runTopits($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
		       $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
		       $Debug,$job{"run"},$job{"out"},$file{"phdDssp"},$envPP{"dirDssp"},
		       $envPP{"exeConvertSeq"},$envPP{"exeTopitsMaxhom"},
		       $envPP{"exeHsspFilter"},$envPP{"exeHsspFilterFor"},
		       $envPP{"exeHsspExtrStrip"},$envPP{"exeHsspExtrStripPP"},
		       $envPP{"exeHssp2pir"},$envPP{"exeTopits"},
		       $envPP{"exeTopitsMaxhomCsh"},$envPP{"exeTopitsMakeMetr"},
#		       $envPP{"exeTopitsWrtOwn"},
		       $envPP{"exePhdFor"},
		       $envPP{"dirTopits"},$envPP{"fileTopitsDef"},
		       $envPP{"fileMaxhomDefaults"},$envPP{"fileTopitsAliList"},
		       $envPP{"fileTopitsMetrSeq"},$envPP{"fileTopitsMetrSeqAll"},
		       $envPP{"fileTopitsMetrGCG"},
		       $envPP{"fileTopitsMetrIn"},$envPP{"parTopitsLindel1"},
		       $envPP{"parTopitsSmax"},$envPP{"parTopitsGo"},$envPP{"parTopitsGe"},
		       $envPP{"parTopitsMixStrSeq"},$envPP{"parTopitsNhits"},
				# HTML output
		       $envPP{"exeMview"},$envPP{"parMview"});
	if (!$Lok){
	    print $fhTrace "*** ERROR in runTopits (err=$err) msg=\n$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
		    if ($Debug && ! $Lok);
				# **************************************************
	    return(0,"$msg");}  # <<<<< ****** this is bad end 5.1
				# **************************************************
	print $fhTrace "$msg\n" if ($Debug);
	&ctrlDbgMsg("end of (6d) runTopits: $packName",$fhTrace,$Debug);}

    if ( $job{"run"}=~/cafaspThreader/){
	($Lok,$err,$msg)=
	    &runCafaspThreader($Origin,$Date,$niceRun,$filePID,$fhOut,$fhTrace,
			       $envPP{"dir_work"},$filePredTmp,$fileHtmlTmp,
			       $fileHtmlToc,
			       $Debug,$job{"run"},$job{"out"},$envPP{"exeThreader"});
	if (!$Lok){
	    print $fhTrace "*** ERROR in runCafaspThreader (err=$err) msg=\n$msg\n" 
		if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"cafasp threader abort: ".$msg);  
	    print $fhTrace "$msg2\n" 
		if ($Debug && ! $Lok);
				# **************************************************
	    return(0,"$msg");}	# <<<<< ****** this is bad end 6e
				# **************************************************
	print $fhTrace "$msg\n" if ($Debug);
	&ctrlDbgMsg("end of (6e) runCafaspThreader: $packName",$fhTrace,$Debug);}

    &ctrlDbgMsg("end of (6) runPhd/runProf/runTopits/runCafaspThreader: $packName",
		$fhTrace,$Debug);

#-------------------------------------------------------------------------------
#   (7) prepare holidays
#-------------------------------------------------------------------------------

    ($Lok,$err,$msg)=
	&modFin($Origin,$Date,$niceRun,$filePID,$fhTrace,$envPP{"dir_work"},
		$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
		$Debug,$job{"run"},$job{"out"},$filePredFin,$Password);

	if (!$Lok){
	    print $fhTrace "*** ERROR in modFin (err=$err) msg=\n$msg\n" if ($Debug);
	    ($Lok,$msg2)=
		&ctrlAbortPred($err,"abort ".$msg);  print $fhTrace "$msg2\n" 
		    if ($Debug && ! $Lok);
				# **************************************************
	    return(0,"$msg");}	# <<<<< ****** this is bad end 5.1
				# **************************************************
    &ctrlDbgMsg("Normal end of predict ($0)",$fhTrace,$Debug);

				# close and remove the error log file
    close($fhTrace)             if (-e $file_error && $fhTrace ne "STDOUT");	
	
				# mail sent is ASCII
    #GY debug info
#    &ctrlDbgMsg("$job{\"out\"}",$fhTrace,$Debug);
    # GY END
    return(1,"ok","formatSend=ascii") 
	if ($job{"out"}!~/^ret html/);

				# mail sent is HTML attachement
    return(1,"ok","formatSend=html");

}				# end of predict
# ================================================================================
# 
#--------------------------------------------------------------------------------#
#                                                                                #
#                                                                                #
#       PREDICTION and INPUT options (permitted combinations):                   #
#       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                   #
#                                                                                #
#               -------------+-----------------------+                           #
#               prediction   |         input         |                           #
#               -------------+-----+-----+-----+-----+                           #
#                            | SEQ | PIR | MSF | COL |                           #
#               -------------+-----+-----+-----+-----+                           #
#               PHD          |  x  |  x  |  x  |     |                           #
#               PHDacc       |  x  |  x  |  x  |     |                           #
#               PHDsec       |  x  |  x  |  x  |     |                           #
#               PHDhtm       |  x  |  x  |  x  |     |                           #
#               TOPITS       |  x  |  x  |  x  |  x  |                           #
#               -------------+-----+-----+-----+-----+                           #
#               WHATIF       |  x  |  x  |  x  |     |                           #
#               -------------+-----+-----+-----+-----+                           #
#               EVALSEC      |     |     |     |  x  |                           #
#               -------------+-----+-----+-----+-----+                           #
#                                                                                #
#                                                                                #
#                                                                                #
#       
#--------------------------------------------------------------------------------#
# 
# ================================================================================

#===============================================================================
sub initPackEnv {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initPackEnv              initialises the environment
#-------------------------------------------------------------------------------

    $ARCH=                      &envPP'getLocal("ARCH");    #e.e'
				# br 99-03 changed concept: all on names, not numbers
				#          will be defined by iniPredict !
#    $jobid=                     $$;
    

    $msg=                       ""; # local error message
				# ------------------------------
				# scripts, executables and files
				# ------------------------------
    foreach $kwd ("pack_licence","lib_ctime","lib_pp","lib_err","lib_col",
		  "exe_mail","exe_status","exe_stripstars","exe_ps",
#		  "envFastaLibs",
		  "envBlastMat","envBlastDb","envProdomBlastDb",
		  "envBlastPsiMat","envBlastPsiDb",
		  "fileMaxhomMetr","fileMaxhomMetrLach",
		  "fileMaxhomMetrSeq","fileMaxhomMetrSeqAll",
		  "fileMaxhomDefaults"){
	next if (length($kwd)<1);
	$envPP{$kwd}=         &envPP::getLocal($kwd);
	if (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR no def of kwd=$kwd, (envPP)";$Lerr=1;}
				# skip
	next if ($kwd =~/^(fileMaxhomMetrSeqAll)/);
	next if ($kwd =~/exe_ps/);
	if (! -e $envPP{$kwd} && ! -l $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR missing ".$envPP{$kwd}.", ($kwd)";$Lerr=1;}}
				# ------------------------------
				# directories
				# ------------------------------
    foreach $kwd ("dir_default","dir_prd",
		  "dir_trash","dir_err", # will die (replaced by bup_..) yyDO_ONE_DAY
		  "dir_resPub",	# directory for results stored for THEM!
		  "dir_work","dir_ut_txt",
		  "dir_bup_res","dir_bup_err","dir_bup_errIn", # new 3 replacing the above
		  "dirData","dirSwiss","dirSwissSplit","dirPdb","dirDssp",
		  "dirBigSwissSplit","dirBigTremblSplit","dirBigPdbSplit",
		  "dirPhd","dirProf","dirTopits","dirCyspred","dirProfCon","dirPcc", "dirChop", "dirZafi", "dirProfTmb"){
	next if (length($kwd)<1);
#	$envPP{$kwd}=         &envPP'getLocal("$kwd");    #e.e'
	$envPP{$kwd}=         &envPP::getLocal($kwd);
	if (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR no def of kwd=$kwd, (envPP)";$Lerr=1;}
	if ($envPP{$kwd}!~/\/$/){
	    $envPP{$kwd}.="/"; } # append slash to directory if necessary
	$envPP{$kwd}=~s/\/\//\//g; # '//' -> '/'
				# ok, move on
	next if (-d $envPP{$kwd} || -l $envPP{$kwd});

				# if local: make them
	if ($LisLocal && $kwd =~/dir/){
	    $dir=$envPP{$kwd};
	    ($Lok,$msgSys)=&sysSystem("mkdir $dir");}
	else {
	    $msg.="\n*** initPackEnv ERROR missing ".$envPP{$kwd}.", ($kwd)";$Lerr=1;}}
				# ------------------------------
				# miscellaneous
				# ------------------------------
    foreach $kwd ("pp_admin","pp_admin_sendWarn","file_ppLog","exe_nice",
		  "flag_status","para_status","file_statusLog","file_history_status",
		  "seq_method","extPdb",
		  "ctrl_timeoutResPub",	# delete results in resPub after that many days
		  "file_licenceGiven","file_licenceCount","file_licFlagCount","urlSrs",
		  ){
	next if (length($kwd)<1);
#	$envPP{$kwd}=         &envPP'getLocal("$kwd");    #e.e'
	$envPP{$kwd}=         &envPP::getLocal($kwd);
	if (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR no def of kwd=$kwd, (envPP)";
	    $Lerr=1;}}
				# ------------------------------
				# license new
				# ------------------------------
    foreach $kwd (
		  "file_licenceComLog","file_licenceNotLog",
		  "file_licenceGiven","file_licenceCount","flag_licenceCount",
		  "file_badGuy","flag_badGuy","par_num4badGuy",
		  ){
	next if (length($kwd)<1);
#	$envPP{$kwd}=         &envPP'getLocal("$kwd");    #e.e'
	$envPP{$kwd}=         &envPP::getLocal($kwd);
	if (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv::initPackLicence ERROR no def of kwd=$kwd, (envPP)";
	    $Lerr=1;}}
    
				# ------------------------------
				# jobs: executables
				# ------------------------------
    foreach $kwd ("exeConvertSeq","exeEvalsec",        "exeEvalsecFor",
		  "exeBlastp",    "exeBlastpFilter" ,
		  "exeBlastPsi",  "exeBlast2Saf",      "exeBlastRdbExtr4pp",
#		  "exeFasta",         "exeFastaFilter",
		  "exeProsite",   "exeCoils",          "exeCyspred",       "exeSeg",
#		  "exeRepeats",
		  "exeNls",       "exeAsp",            "exeNorsp",
		  "exeMaxhom",    "exeHsspExtrHead",   "exeHsspExtrStrip", "exeHsspExtrStripPP",
		  "exeHsspExtrHdr4pp",
		  "exeCopf",
		  "exeHssp2pir",  "exeHsspFilter",     "exeHsspFilterFor",
		  "exePhd",       "exePhdFor",
		  "exePhdHtmfil", "exePhdHtmref",      "exePhdHtmtop",
		  "exePhd2msf",   "exePhd2dssp",       "exePhd2casp2",     "exePhd2html",     
		  "exePhdRdb2kg",
		  "exeProf",      "exeProfFor",        "exeProfPhd1994",   "exeProfPhd1994For",
		  "exeProfConv",  "exeProfHtmfil","exeProfHtmref",     "exeProfHtmtop",
#		  "exeGlobe",
#		  "exeTopitsWrtOwn",
		  "exeTopits",    "exeTopitsMaxhomCsh","exeTopitsMakeMetr","exeTopitsMaxhom",
		  "exeThreader",
		  "exeMview", "exeProfCon", "exePcc", "exeChop", "exeZafi", "exeProfTmb"
		  ){
	next if (length($kwd)<1);
#	$envPP{$kwd}=         &envPP'getLocal("$kwd");    #e.e'
	$envPP{$kwd}=         &envPP::getLocal($kwd);
	if   (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR no def of kwd=$kwd, (envPP)";$Lerr=1;}
	next if ($kwd =~/exeMaxhom/);
	next if (-e $envPP{$kwd} || -l $envPP{$kwd});
	$msg.="\n*** initPackEnv ERROR missing ".$envPP{$kwd}.", ($kwd)";$Lerr=1; }
				# ------------------------------
				# jobs: files (BLASTPSI,PHD, TOPITS)
				# ------------------------------
    foreach $kwd (
		  "filePhdParaSec","filePhdParaAcc","filePhdParaHtm",
		  "fileProfPara3","fileProfParaBoth",
		  "fileProfParaSec","fileProfParaAcc","fileProfParaHtm",
#		  "filePhdDefaults",

		  "fileTopitsDef","fileTopitsMaxhomDef","fileTopitsAliList",
		  "fileTopitsMetrSeq","fileTopitsMetrSeqAll",
		  "fileTopitsMetrGCG","fileTopitsMetrIn"){
	next if (length($kwd)<1);
#	$envPP{$kwd}=         &envPP'getLocal("$kwd");    #e.e'
	$envPP{$kwd}=         &envPP::getLocal($kwd);
	if (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR no def of kwd=$kwd, (envPP)";$Lerr=1;}
				# skip from want_existence 
	next if ($kwd =~/^(fileTopitsMetrSeqAll)/);
	if (! -e $envPP{$kwd} && ! -l $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR missing ".$envPP{$kwd}.", ($kwd)";$Lerr=1;}}
				# ------------------------------
				# jobs: parameters (all)
				# ------------------------------
    foreach $kwd (
				# ASP
		  "parAspWs",        "parAspZ",       "parAspMin",
		  		# NORS
		  "parNorsWs",       "parNorsSecCut", "parNorsAccLen",

				# Chop
		  'parChopBlastE',  'parChoprHmmrE',  'parChopDomCov',  'parChopMinFragLen',  


				# COILS
		  "parCoilsMin",     "parCoilsMetr",    
		  "parCoilsWeight", "parCoilsOptOut",
				# PROSITE, PRODOM
		  "filePrositeData",
		  "parProdomBlastDb","parProdomBlastN", "parProdomBlastE","parProdomBlastP",
		  "parSegNorm",      "parSegNormMin",   "parSegGlob",      
				# FASTA, BLAST
#		  "parFastaNhits",   "parFastaThresh",  "parFastaScore",  "parFastaSort",
		  "parBlastDb",      "parBlastNhits",
		  "parBlastDbPdb",   "parBlastDbSwiss", "parBlastDbTrembl","parBlastDbBig",
				# PSI-BLAST
		  "parBlastPsiDb",    "parBlastPsiNhits",
		  "parBlastPsiDbPdb", "parBlastPsiDbSwiss", "parBlastDbPsiTrembl",
		  "parBlastPsiDbBig", "parBlastFilThre",    "parBlastMaxAli",
		  "parBlastPsiArg",   "parBlastBigArg",     "parBlastTile", 
				# MAXHOM
		  "parMaxhomLprof",  "parMaxhomSmin",   "parMaxhomSmax",
		  "parMaxhomGo",     "parMaxhomGe",     "parMaxhomW1",     "parMaxhomW2",
		  "parMaxhomI1",     "parMaxhomI2",     "parMaxhomNali",   "parMaxhomSort",
		  "parMaxhomProfOut","parMaxhomMinIde", "parMaxhomExpMinIde",
		  "parMaxhomMaxNres","parMaxhomMaxACGT","parMaxhomTimeOut","parMinLaliPdb",
		  "parMaxhomMaxNbig",
				# filtering the alignment
		  "parFilterAliOff", "parFilterAliPhd", 
				# PHD
		  "parPhdMinLen",    "parPhdHtmDef",    "parPhdHtmMin",
		  "parPhdSubsec",    "parPhdSubacc",    "parPhdSubsymbol", "parPhdNlineMsf",
				# PROF
		  "parProfOptDef",   "parProfMinLen",   
		  "parProfSubsec",   "parProfSubacc",   "parProfSubhtm",   "parProfSubsymbol",
		  "parProfHtmDef",   "parProfHtmMin",   
		  "parProfNlineMsf",
				# TOPITS
		  "parTopitsSmax",   "parTopitsGo",     "parTopitsGe",     "parTopitsNhits",
		  "parTopitsLindel1","parTopitsMixStrSeq",
		  "parMview"
		  ){
#	$envPP{$kwd}=         &envPP'getLocal("$kwd");    #e.e'
	$envPP{$kwd}=         &envPP::getLocal($kwd);
	if (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR no def of kwd=$kwd, (envPP)";$Lerr=1;}}

				# ------------------------------
				# versions
				# ------------------------------
    foreach $kwd (
		  "pp",
		  "swiss","trembl","pdb","big","prosite","prodom",
		  "maxhom","blast","mview","coils","seg",
		  "phd", "phd_sec", "phd_acc", "phd_htm",
		  "prof","prof_sec","prof_acc","prof_htm",
		  "globe","topits","cyspred","asp","norsp", "profcon", "pcc", "chop","zafi", "proftmb"
		  ){
	$kwd2="version_".$kwd;
	$envPP{$kwd2}=        &envPP::getLocal($kwd2);
	if (! defined $envPP{$kwd2}){
	    $msg.="\n*** initPackEnv ERROR no def of kwd=$kwd2, (envPP)";}}

				# ------------------------------
				# text: files append (all)
				# ------------------------------
    foreach $kwd ("fileHelpText","fileHelpConcise","fileNewsText","fileLicText",
				# note: PHD internal now
		  "fileHeadPhdConcise",  "fileHeadPhd3",        "fileHeadPhdBoth",
		  "fileHeadPhdSec",      "fileHeadPhdAcc",      "fileHeadPhdHtm",

		  "fileHeadEvalsec",
		  "fileAppLicPwd",       "fileAppLicExhaust",   "fileAppLicExpired",
		  "fileAppLicNew",       "fileAppLine",
		  "fileAppInSeqConv",    "fileAppInSeqSent",
		  "fileAppEvalsec",      "fileAppHssp",        
		  "fileAppPred",         "fileAppPredPhd",      "fileAppPredProf",  "fileAppGlobe",
		  "fileAppProdom",       "fileAppProsite",      "fileAppCoils",
		  "fileAppCyspred",      "fileAppSegNorm",      "fileAppSegGlob",      
		  "fileAppAsp",          "fileAppNorsp",         "fileAppThreader",
		  "fileAppMsfWarning",   "fileAppSafWarning",   "fileAppWarnSingSeq",
		  "fileAppTopitsNohom",  "fileAppIlyaPdb",      "fileAppMembrane",

		  "fileAppRetBlastp",    "fileAppRetMsf",       "fileAppRetNoali", 
		  "fileAppRetBlastPsi",
		  "fileAppRetTopitsOwn", "fileAppRetTopitsHssp","fileAppRetTopitsStrip",
		  "fileAppRetTopitsMsf", 
		  "fileAppRetPhdMsf",    "fileAppRetPhdRdb",    
		  "fileAppRetGraph",     "fileAppRetCol",       "fileAppRetPhdCasp2",
		  "fileAppRetProfMsf",   "fileAppRetProfRdb",    
		  "fileAppRetProfGraph", "fileAppRetProfCol",   "fileAppRetProfCasp",

		  "fileAppWrgMsfexa",    "fileAppWrgSafexa",    "fileAppErrCrypt",

		  "fileAppEmpty",        "fileAppHtmlHeadChop",
		  "fileAppHtmlHead",     "fileAppHtmlFoot", "fileAppProfCon", "fileAppPcc",     
		  "fileAppHtmlStyles",    "fileAppHtmlQuote", "fileAppChop", "fileAppZafi", "fileAppProfTmb",   
		  
				# note: PHD internal now
#		  "fileAbbrPhd3",        "fileAbbrRdb3",        "fileAbbrPhdBoth",
#		  "fileAbbrPhdSec",      "fileAbbrPhdAcc",      "fileAbbrPhdHtm",
		  ){
#	$envPP{$kwd}=         &envPP'getLocal("$kwd");    #e.e'
	$envPP{$kwd}=         &envPP::getLocal($kwd);
	if (! defined $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR no def of kwd=$kwd, (envPP)";$Lerr=1;
	    next;}
	if (! -e $envPP{$kwd} && ! -l $envPP{$kwd}){
	    $msg.="\n*** initPackEnv ERROR file=".$envPP{$kwd}.", ($kwd)";$Lerr=1;
	}
    }
				#------------------------------
				# priority
				#------------------------------
    $exe_niceSys=             $envPP{"exe_nice"};
    $tmp=$exe_niceSys;$tmp=~s/nice|\s|\-|\+//g;
    if (length($tmp)>0){ 
	setpriority (0, 0, $tmp);
	$niceRun=" ";}	# avoid nicing twice
    else {
	$niceRun=$envPP{"exe_nice"};}
    $niceRun=" " if (length($niceRun)<1);
				# ----------------------------------------
				# other parameters for all
				# ----------------------------------------
    if ($Lerr){
	print "*** ERROR already during initialisation of $scrName\n","*** msg=\n",$msg,"\n";
	return(0,"left initPackEnv"); # exit Predict: error
    }
    return(1,"ok initPackEnv");
}				# end of initPackEnv

#===============================================================================
sub iniPredict {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniPredict                  defines names needed for predict
#-------------------------------------------------------------------------------
				# ------------------------------
				# initialise date parameters
				# ------------------------------
    $Date=&sysDate();


#    ($Start_user,$Start_system,$startTimeCuser,$Start_csystem) = times;
    $tmpUser=$tmpSystem=$tmpCsystem="unk";
    ($tmpUser,$tmpSystem,$startTimeCuser,$tmpCsystem) = times;
    
				# ------------------------------
				# define working files
				# ------------------------------
				# prinicpal file name
    $filePID=      $File_name;	# input from calling program
				# remove path and extensions
    $filePID=~s/^.*\///;$filePID=~s/\..*//;
				# add the PID in the name
#    $filePID=      $filePID."-"."$jobid";
#				# change br 99-02: only number!
#    $filePID=~s/\D//g;

				# br 99-03: set jobid to filePID!!!
    $jobid=$filePID;
				# yyy
# 				# hack br 99-02: hack around too short files in PHD
# 				# yyy
#     $filePID=~s/t\-\D*/x/       if ($filePID =~/^t\-/);
#    $filePID=     $envPP{"dir_work"}.$filePID; # set in working dir

				# ------------------------------
				# temporary pred file (results)
    $filePredFin=   $envPP{"dir_work"}.$filePID . ".pred";
    $filePredTmp=   $envPP{"dir_work"}.$filePID . ".pred_temp"; 

    $fileHtmlFin=   $envPP{"dir_work"}.$filePID . ".html";
    $fileHtmlTmp=   $envPP{"dir_work"}.$filePID . ".html_temp"; 
    $fileHtmlToc=   $envPP{"dir_work"}.$filePID . ".html_toc"; 
				# ------------------------------
				# log files
    $titleLog=$ARCH."-".$jobid.".tmp";
				# br 99-03: for the time being only SGI...
    $titleLog="-".$jobid.".tmp";

    $file_error=    $envPP{"dir_work"}."ERRpp"    .$titleLog; # trace file
    $file_outpp=    $envPP{"dir_work"}."SCRpp"    .$titleLog; # trace file
    $screenTopits=  $envPP{"dir_work"}."SCRtopits".$titleLog; # topits screen
    $screenPhd=     $envPP{"dir_work"}."SCRphd"   .$titleLog; # phd screen
    $screenMax=     $envPP{"dir_work"}."SCRmax"   .$titleLog; # maxhom screen
    $screenCoils=   $envPP{"dir_work"}."SCRcoils" .$titleLog; # maxhom screen

				# ------------------------------
				# encryption status
    $Crypt_on=                "Y";     # encryption
    $Crypt_of=                "N";     # no encryption

				# ------------------------------
				# temporary files to be removed
    @kwdRm= ("file_error","file_outpp",
	     "screenTopits","screenPhd","screenMax", "screenCoils",
	     "fileHtmlFin","fileHtmlTmp","fileHtmlToc",
	     "filePredTmp","filePred");
    %file=  (
	     'filePredFin',  $filePredFin, 
	     'filePredTmp',  $filePredTmp,
	     'fileHtmlFin',  $fileHtmlFin,
	     'fileHtmlTmp',  $fileHtmlTmp,
	     'fileHtmlToc',  $fileHtmlToc,
				# 
	     'fileError',    $file_error,
	     'fileOutpp',    $file_outpp,

	     'screenMax',    $screenMax, 
	     'screenTopits', $screenTopits,  
	     'screenPhd',    $screenPhd,
	     'screenCoils',  $screenCoils,
	     );
				# ------------------------------
				# clean up for security
    foreach $kwd (keys %file){
	next if (! -e $file{$kwd});
	unlink($file{$kwd});}
				# ------------------------------
				# define error flags
    @kwdErr=("in:nofile","internal","in:noHash","in:short","in:long","in:gene",
	     "in:col","in:colNeeded","in:colTopits","in:msf","in:saf","in:pirlist",
	     "run:convert",
	     "convert:saf","convert:msf","convert:pir","convert:swiss","convert:rdb",
	     "convert:pirList","convert:noAli",
	     "align:convert","align:fasta","align:blastp","align:maxhom",
	     "phd:run","phd:rdb2kg","phd:phd2col","phd:phd2msf","phd:phd2casp2",
	     "phd:globe",
	     "prof:run","prof:prof2col","prof:prof2msf","prof:prof2dssp",
	     "prof:prof2casp","prof:globe",
	     
	     "","",
	     );
    %msgErr=('internal',        "internal software problem",
	     'in:nofile',       "input file missing",
	     'in:col',          "wrong COL format in request",
	     'in:colNeeded',    "for EVALSEC must be COL format in request file",
	     'in:colTopits',    "if giving a prediction in COL format choose TOPITS",
	     'in:noHash',       "no hash found in request file",
	     'in:msf',          "wrong MSF format in request",
	     'in:saf',          "wrong SAF format in request",
	     'in:pirlist',      "wrong PIR list format in request",
	     'in:fastalist',    "wrong FASTA list format in request",
	     'in:fastamul',     "wrong FASTA alignment format in request",
	     'in:short',        "query sequence appears too short",
	     'in:long',         "query sequence appears too long",
	     'in:gene',         "query sequence appears gene sequence",
	     'in:format',       "request seems of wrong format",
	     'convert:saf',     "conversion problem (SAF -> MSF)",
	     'convert:msf',     "conversion problem (MSF -> HSSP)",
	     'convert:pir',     "conversion problem (PIR -> FASTA)",
	     'convert:swiss',   "conversion problem (SWISS -> FASTA)",
	     'convert:rdb',     "conversion problem (PHD.rdb -> DSSP)",
	     'convert:pirList', "conversion problem (pir list -> HSSP)",
	     'convert:noAli',   "conversion problem (seq (noali) -> HSSP)",
	     'align:convert',   "alignment problem (convert seq 2 fasta)",
	     'align:fasta',     "alignment problem (run fasta)",
	     'align:blastp',    "alignment problem (run blastp)",
	     'align:maxhom',    "alignment problem (run maxhom)",
	     'predMis:convert', "conversion problem (in -> FASTA)",
	     'predMis:coils',   "coils problem",
	     'phd:run',         "phd problem (running phd.pl)",
	     'phd:rdb2kg',      "phd problem (converting rdb2kg)",
	     'phd:phd2col',     "phd problem (converting phd2col)",
	     'phd:phd2msf',     "phd problem (converting phd2msf)",
	     'phd:phd2casp2',   "phd problem (converting phd2casp2)",
	     'phd:phd2dssp',    "phd problem (converting phd2dssp)",
	     'phd:globe',       "problem after PHD: GLOBE failed",

	     'prof:run',        "prof problem (running prof.pl)",
	     'prof:prof2col',   "prof problem (converting prof2col)",
	     'prof:prof2msf',   "prof problem (converting prof2msf)",
	     'prof:prof2casp',  "prof problem (converting prof2casp2)",
	     'prof:prof2dssp',  "prof problem (converting prof2dssp)",
	     'prof:globe',      "problem after PROF: GLOBE failed",
	     '', "",
	     'run:convert',     "conversion problem ($File_name)",
	     );
    %appErr=('internal',        $envPP{"fileAppIntErr"}, 
	     'in:nofile',       $envPP{"fileAppIntErr"}, 
	     'in:col',          $envPP{"fileAppWrgColumn"},
	     'in:colNeeded',    $envPP{"fileAppWrgEvalsec"},
	     'in:colTopits',    $envPP{"fileAppWrgColphd"},
	     'in:noHash',       $envPP{"fileAppWrgFormat"},
	     'in:msf',          $envPP{"fileAppWrgFormatMsf"},
	     'in:saf',          $envPP{"fileAppWrgFormatSaf"},
	     'in:pirlist',      $envPP{"fileAppWrgFormat"},
	     'in:short',        $envPP{"fileAppInGeneSeq"},
	     'in:long',         $envPP{"fileAppInTooShort"},
	     'in:gene',         $envPP{"fileAppInTooLong"},
	     'run:convert',     $envPP{"fileAppIntErr"}, 
	     'convert:saf',     $envPP{"fileAppIntErr"}, 
	     'convert:msf',     $envPP{"fileAppIntErr"}, 
	     'convert:pir',     $envPP{"fileAppIntErr"}, 
	     'convert:swiss',   $envPP{"fileAppIntErr"}, 
	     'convert:rdb',     $envPP{"fileAppIntErr"}, 
	     'align:convert',   $envPP{"fileAppIntErr"}, 
	     'align:fasta',     $envPP{"fileAppIntErr"}, 
	     'align:blastp',    $envPP{"fileAppIntErr"}, 
	     'align:maxhom',    $envPP{"fileAppIntErr"}, 
	     'phd:run',         $envPP{"fileAppIntErr"}, 
	     'phd:rdb2kg',      $envPP{"fileAppIntErr"}, 
	     'phd:phd2col',     $envPP{"fileAppIntErr"}, 
	     'phd:phd2msf',     $envPP{"fileAppIntErr"}, 
	     'phd:phd2casp2',   $envPP{"fileAppIntErr"}, 
	     'phd:phd2dssp',    $envPP{"fileAppIntErr"}, 
	     'phd:globe',       $envPP{"fileAppIntErr"}, 
	     );


				# ------------------------------
				# open the logfile
    if (!$Debug){		# redirect output into files
	$fhTrace=     "TRACE_FILE";
	$Lok=open($fhTrace, ">$file_outpp") ||
	    warn "-*- $packName'iniPredict cannot open file_outpp=$file_error: $!\n";


#	$fhTrace="STDOUT";	# xx
	$fhOut=$fhTrace;
	$Lok=open(STDERR, ">$file_error") ||
	    warn "-*- $packName'iniPredict cannot open file_error=$file_error: $!\n";
#	select((select(TRACE_FILE), $| = 1)[0]);
    }
    else{

	$fhOut=$fhTrace="STDOUT";}
#    $Lok=open("$fhScreenMax", ">$screenMax") ||
#	warn "-*- $packName'iniPredict cannot open screenMax=$screenMax: $!\n";
    
    $| = 1;			# flush output
}				# end of iniPredict

#===============================================================================
sub iniHtmlBuild {
#-------------------------------------------------------------------------------
#   iniHtmlBuild                assigns keyword lines to keywords
#       out GLOBAL:             all
#-------------------------------------------------------------------------------

    %htmlKwd=
	('in_given',         "The following information has been received by the server",
	 'in_taken',         "The sequence was interpreted to be",
	 'mview',            "Alignment displayed by MView (N Brown)",
	 'ali_maxhom',       "MAXHOM multiple sequence alignment",
	 'ali_maxhom_head',  "MAXHOM alignment header",
	 'ali_maxhom_body',  "MAXHOM alignment",
	 'ali_maxhom_prof',  "MAXHOM alignment in HSSP format with profiles",
	 'ali_maxhom_hssp',  "MAXHOM alignment in HSSP format",
	 'ali_blast',        "BLASTP database search (A Karlin and S Altschul)",
	 'ali_psiBlast_head',"PSI-BLAST alignment header",
	 'ali_psiBlast',     "PSI-BLAST database search (A Karlin and S Altschul)",
	 
	 'prosite',          "PROSITE motif search (A Bairoch; P Bucher and K Hofmann)",
	 'prodom',           "ProDom domain search (E Sonnhammer, Corpet, Gouzy, D Kahn)",
	 'asp',              "Ambivalent Sequence Predictor(Malin Young, Kent Kirshenbaum, Stefan Highsmith)",
	 'norsp',             "predictor of NOn-Regular Secondary Structure (Jinfeng Liu & Burkhard Rost)",
	 'coils',            "COILS prediction (A Lupas)",
	 'cyspred',	     "CYSPRED prediction(P Fariselli,P Riccobelli & R Casadio)",
	 'pcc',	             "Predict Cell Cycle (Kazimierz O. Wrzeszczynski, Guy Yachdav, Phil Carter & Burkhard Rost)",
	 'proftmb',	     "Predict Cell Cycle (Kazimierz O. Wrzeszczynski, Guy Yachdav, Phil Carter & Burkhard Rost)",
	 #'zafi',	     "Predict Prot Prot interaction (Yanay Ofran,,)",
	 'chop',	     "CHOP Proteins into structural domain-like fragments (Liu, J.,Rost B)",
	 'predictNLS',	     "NLS prediction(R Nair,M Cokol & B Rost)",
	 'seg_norm',         "SEG low-complexity regions (J C Wootton & S Federhen)",

	 'phd',              "PHD predictions (B Rost)",
	 'phd_info',         "PHD information about accuracy",
	 'phd_head',         "PHD information about your protein",
	 'phd_body',         "PHD predictions",

	 'phd_col',          "PHD in COLUMN format",
	 'phd_msf',          "PHD in MSF format",
	 'phd_rdb',          "PHD in RDB format",
	 'phd_casp',         "PHD in CASP format",

	 'prof',             "PROF predictions (B Rost)",
	 'prof_info',        "PROF information about accuracy",
	 'prof_head',        "PROF information about your protein",
	 'prof_body',        "PROF predictions",

	 'prof_col',         "PROF in COLUMN format",
	 'prof_msf',         "PROF in MSF format",
	 'prof_rdb',         "PROF in RDB format",
	 'prof_casp',        "PROF in CASP format",

	 'globe',            "GLOBE prediction of globularity",
	 'seg_glob',         "SEG globularity (J C Wootton & S Federhen)",

	 'topits',           "TOPITS (prediction based threading, B Rost)",
	 'topits_own',       "Threading results in TOPITS format",
	 'topits_head',      "TOPITS (threading) header",
	 'topits_msf',       "TOPITS (threading) results in MSF format",
	 'topits_hssp',      "TOPITS (threading) results in HSSP format",
	 'topits_strip',     "TOPITS (threading) results in STRIP format",

	 'evalsec',          "EVALSEC evaluation of secondary structure",
	 'evalsec_head',     "HEADER for result of EVALSEC",
	 '',  "",
	 '',  "",
	 '',  "",
	 '',  "",
	 );
    
}				# end of iniHtmlBuild

#===============================================================================
sub iniQuotes {
#-------------------------------------------------------------------------------
#   iniQuotes                   literature quotes of methods
#       out GLOBAL:             all
#-------------------------------------------------------------------------------


    %tmp=
	(
	 'copyright_mview',  "Copyright (C) Nigel P. Brown, 1997-1998. All rights reserved."
	 );
    foreach $kwd (keys %tmp){$method{$kwd}=$tmp{$kwd};}

    foreach $kwd (
		  "pp",
		  "swiss","trembl","pdb","big",
		  "seg","prosite","prodom","predictnls",
		  "maxhom","blast","mview","coils","cyspred","asp",
		  "phd","phd_sec","phd_acc","phd_htm","nors",
		  "prof","prof_sec","prof_acc","prof_htm",
		  "globe","topits"
		  ){
	$kwd2="version_".$kwd;
	$method{$kwd2}=$envPP{$kwd2};
    }

				# ------------------------------
				# set methods env
    ($Lok,$msg,$ra_methods)=
	&envPP::envMethods();

				# ------------------------------
				# fill in stuff
       foreach $kwd ("pp",
		  "maxhom","blastp","blastpsi",
		  "mview",
		  "prosite","prodom","seg",
		  "coils","cyspred","asp","norsp",
		  "phd", "phd_sec", "phd_acc", "phd_htm",
		  "prof","prof_sec","prof_acc","prof_htm",
		  "globe","topits"
		  ){
	# from PPENV
	if (defined ($ra_methods->{$kwd})->{"abbr"}){	 
	    $tmp{"name_".$kwd}=($ra_methods->{$kwd})->{"abbr"}; }
	if (defined ($ra_methods->{$kwd})->{"quote"}){	 
	    $tmp{"quote_".$kwd}=($ra_methods->{$kwd})->{"quote"}; 
	    $tmp{"quote_".$kwd}=~s/(:)\s*:.* \. /$1/g;}	 
	if (defined ($ra_methods->{$kwd})->{"url"}){
	    $tmp{"url_".$kwd}=($ra_methods->{$kwd})->{"url"}; }
	if (defined ($ra_methods->{$kwd})->{"des"}){
	    $tmp{"des_".$kwd}=($ra_methods->{$kwd})->{"des"}; }
	if (defined ($ra_methods->{$kwd})->{"admin"}){
	    ($tmp1,$tmp2)=split(/,/,($ra_methods->{$kwd})->{"admin"});
	    $tmp{"contact_".$kwd}=$tmp2;}
	if (defined ($ra_methods->{$kwd})->{"doneby"}){
	    $tmp{"author_".$kwd}=($ra_methods->{$kwd})->{"doneby"}; }

	if (! defined $tmp{"name_".$kwd}    || 
	    ! defined $tmp{"quote_".$kwd}   || 
	    ! defined $tmp{"url_".$kwd}     || 
	    ! defined $tmp{"des_".$kwd}     || 
	    ! defined $tmp{"contact_".$kwd} ||
	    ! defined $tmp{"author_".$kwd}){
	    if    ($kwd =~ /pp/)      { 
		$name=   "PredictProtein";
		$quote=  "PredicProtein: B Rost (1996) Methods in Enzymology, 266:525-539";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "PredictProtein is the acronym for all prediction programs run."; 
		$contact='liu@cubic.bioc.columbia.edu';
		$author= "B Rost";}
	    elsif ($kwd =~ /max/)     { 
		$name=   "MaxHom";
		$quote=  "MaxHom: C Sander R Schneider (1991) Proteins, 9:56-68";
		$url=    "";
		$des=    "MaxHom is a dynamic multiple sequence alignment program which finds similar sequences in a database."; 
		$contact='schneider\@lion-ag.de';
		$author= "C Sander & R Schneider, schneider\@lion-ag.de";}
	    elsif ($kwd =~ /blast/)   { 
		$name=   "BLASTP";
		$quote=  "BLASTP: S Karlin & SF Altschul (1993) PNAS, 90:5873-5877";
		$url=    "http://www.ncbi.nlm.nih.gov/BLAST/";
		$des=    "BLAST is a fast database search program."; 
		$contact="altschul\@ncbi.nlm.nih.gov";
		$author= "S Karlin & SF Altschul";}
	    elsif ($kwd =~ /mview/)   { 
		$name=   "MView";
		$quote=  "MView: N P Brown, C Leroy & C Sander (1998) Bioinformatics, 14:380-381";
		$url=    "http://mathbio.nimr.mrc.ac.uk/~nbrown/mview/";
		$des=    "MView is a program converting multiple sequence alignments into fancy HTML formatted output."; 
		$contact="";
		$author= "N Brown, nbrown\@nimr.mrc.ac.uk";}
	    elsif ($kwd =~ /prosite/) { 
		$name=   "PROSITE";
		$quote=  "A Bairoch, P Bucher & K Hofmann (1997) Nucleic Acids Research, 25:217-221";
		$url=    "http://www.expasy.ch/prosite/";
		$des=    "PROSITE is a database of functional motifs.  ScanProsite, finds all functional motifs in your sequence that are annotated in the ProSite db."; 
		$contact="bairoch\@cmu.unige.ch";
		$author= "A Bairoch, bairoch\@cmu.unige.ch P Bucher & K Hofmann";}
	    elsif ($kwd =~ /prodom/)  { 
		$name=   "ProDom";
		$quote=  "ELL Sonnhammer & D Kahn (1994) Protein Science, 3:482-492";
		$url=    "http://protein.toulouse.inra.fr/prodom.html";
		$des=    "ProDom is a database of putative protein domains.  The database is searched with BLAST for domains corresponding to your protein.",; 
		$contact="dkahn\@zyx.toulouse.inra.fr";
		$author= "LL Sonnhammer\; J Gouzy, F Corpet, F Servant, D Kahn, dkahn\@zyx.toulouse.inra.fr";}
	    
	    elsif ($kwd =~ /cyspred/) { 
		$name=   "CYSPRED";
		$quote=  "Fariselli P, Riccobelli P & Casadio R (1999) PROTEINS 36:340-346";
		$url=    "http://prion.biocomp.unibo.it/cyspred.html";
		$des=    "CYSPRED finds whether the cys residue in your protein forms disulfide bridge."; 
		$contact="piero\@lipid.biocomp.unibo.it";
		$author= "Fariselli P, Riccobelli P, Casadio R";}
	    elsif ($kwd =~ /asp/) { 
		$name=   "A conformational switch prediction program";
		$quote=  "Young et al. Protein Science(1999) 8:1752-64.";
		$url=    "";
		$des=    "ASP finds regions that are most likely to behave as switches in proteins known to exhibit this behavior"; 
		$contact='mmyoung@sandia.gov, kent@cheme.caltech.edu, shighsmith@sf.uop.edu';
		$author= "Young M, Kirshenbaum K, Dill KA and Highsmith S.";}
	    elsif ($kwd =~ /seg/)     { 
		$name=   "SEG";
		$quote=  "J C Wootton & S Federhen (1996) Methods in Enzymology, 266:554-571";
		$url=    "wootton\@ncbi.nlm.nih.gov";
		$des=    "SEG divides sequences into regions of low-, and high-complexity.  Low-complexity regions typically correspond to 'simple sequences' or 'compositionally-biased' regions."; 
		$contact="rost\@columbia.edu";
		$author= "J C Wootton & S Federhen, wootton\@ncbi.nlm.nih.gov";}
	    elsif ($kwd =~ /phd$/)    { 
		$name=   "PHD";
		$quote=  "B Rost (1996) Methods in Enzymology, 266:525-539";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "PHD is a suite of programs predicting 1D structure (secondary structure, solvent accessibility) from multiple sequence alignments."; 
		$contact="rost\@columbia.edu";
		$author= "B Rost";}
	    elsif ($kwd =~ /phd_sec/) { 
		$name=   "PHDsec";
		$quote=  "B Rost & C Sander (1993) J. of Molecular Biology, 232:584-599";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "PHDsec predicts secondary structure from multiple sequence alignments."; 
		$contact="";
		$author= "B Rost";}
	    elsif ($kwd =~ /phd_acc/) { 
		$name=   "PHDacc";
		$quote=  "B Rost & C Sander (1994) Proteins, 20:216-226";
		$url=    "rost\@columbia.edu";
		$des=    "PHDacc predicts per residue solvent accessibility from multiple sequence alignments."; 
		$contact="";
		$author= "";}
	    elsif ($kwd =~ /phd_htm/) { 
		$name=   "PHDhtm";
		$quote=  "B Rost, P Fariselli & R Casadio (1996) Protein Science, 7:1704-1718";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "PHDhtm predicts the location and topology of transmembrane helices from multiple sequence alignments."; 
		$contact="rost\@columbia.edu";
		$author= "B Rost";}
	    elsif ($kwd =~ /prof$/)   { 
		$name=   "PROF";
		$quote=  "B Rost (2000) in submission";
		$url=    "";
		$des=    "PROF is a suite of programs predicting 1D structure (secondary structure, solvent accessibility) from multiple sequence alignments."; 
		$contact="rost\@columbia.edu";
		$author= "B Rost";}
	    elsif ($kwd =~ /prof_sec/){ 
		$name=   "PROFsec";
		$quote=  "B Rost (2000) in submission";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "PROFsec predicts secondary structure from multiple sequence alignments."; 
		$contact="rost\@columbia.edu";
		$author= "B Rost";}
	    elsif ($kwd =~ /prof_acc/){ 
		$name=   "PROFacc";
		$quote=  "B Rost (2000) in submission";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "PROFacc predicts per residue solvent accessibility from multiple sequence alignments."; 
		$contact="rost\@columbia.edu";
		$author= "B Rost";}
	    elsif ($kwd =~ /prof_htm/){ 
		$name=   "PROFhtm";
		$quote=  "B Rost (2000) in submission";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "PROFhtm predicts the location and topology of transmembrane helices from multiple sequence alignments."; 
		$contact="rost\@columbia.edu";
		$author= "B Rost";}
	    elsif ($kwd =~ /globe/)   { 
		$name=   "GLOBE";
		$quote=  "B Rost (1998) unpublished";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "GLOBE predicts the globularity of a protein."; 
		$contact="rost\@columbia.edu";
		$author= "B Rost";}
	    elsif ($kwd =~ /topits/)  { 
		$name=   "TOPITS";
		$quote=  "B Rost, R Schneider & C Sander (1997) J. of Molecular Biology, 270:1-10";
		$url=    "http://cubic.bioc.columbia.edu";
		$des=    "TOPITS is a prediction-based threading program, that finds remote structural homologues in the DSSP database."; 
		$contact="rost\@columbia.edu";
		$author= "B Rost";}
	    if (! defined $tmp{"name_".$kwd}){
		$tmp{"name_".$kwd}=$name;}
	    if (! defined $tmp{"quote_".$kwd}){
		$tmp{"quote_".$kwd}=$quote;}
	    if (! defined $tmp{"url_".$kwd}){
		$tmp{"url_".$kwd}=$url;}
	    if (! defined $tmp{"des_".$kwd}){
		$tmp{"des_".$kwd}=$des;}
	    if (! defined $tmp{"contact_".$kwd}){
		$tmp{"contact_".$kwd}=$contact;}
	    if (! defined $tmp{"author_".$kwd}){
		$tmp{"author_".$kwd}=$author;}
	}
    }
		
    foreach $kwd (keys %tmp){
	$method{$kwd}=$tmp{$kwd};}


    foreach $kwd (
#		  "phd_info",
		  "phd_body"
		  ) {
	foreach $kwd2 ("quote_","right_","version_","url_","author_","contact_","des_") {
	    $method{$kwd2.$kwd}=$method{$kwd2."phd"}; }}

    foreach $kwd ("ali_maxhom",
#		  "ali_maxhom_head",
		  "ali_maxhom_body",
		  "ali_maxhom_prof","ali_maxhom_hssp") {
	foreach $kwd2 ("quote_","right_","version_","url_","author_","contact_","des_") {
	    $method{$kwd2.$kwd}=$method{$kwd2."maxhom"}; }}

    foreach $kwd ("ali_blast") {
	foreach $kwd2 ("quote_","right_","version_","url_","author_","contact_","des_") {
	    $method{$kwd2.$kwd}=$method{$kwd2."blast"}; }}

    foreach $kwd ("seg_norm","seg_glob") {
	foreach $kwd2 ("quote_","right_","version_","url_","author_","contact_","des_") {
	    $method{$kwd2.$kwd}=$method{$kwd2."seg"}; }}

    foreach $kwd ("ali_topits",
#		  "ali_topits_head",
		  "ali_topits_own",
		  "ali_topits_strip","ali_topits_hssp","ali_topits_msf"){
	foreach $kwd2 ("quote_","right_","version_","url_","author_","contact_","des_") {
	    $method{$kwd2.$kwd}=$method{$kwd2."topits"}; }}

}				# end of iniQuotes

#===============================================================================
sub modBefore {
    local($fileInLoc,$filePredTmpLoc,$fileJobIdLoc,$LdebugLoc,$dirWork,$fhOutSbr) = @_ ;
    local($sbr,$fileTmp,$fhOutSbr,$Lok,$msg,$kwd,$msgHere,$Lfin,@tmp,$crypt_status);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   modBefore                   executes cleaning and licence control before
#                               the job ever starts off
#       NOTE:                   internal errors here dont terminate!!
#                               
#       NOTE2:                  also reads input file and detects keywords:
#                               SEND_RESULT_TO user (global out: $User_name_forced)
#                               
#                               
#                               
#       in:                     file_name,file_jobid,fhout
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       out:                    (status=0|1, error code='err=NNN', msg='blabla'
#       out:                    $job{"fin"} if to finish
#       out:                    $job{"out"} + 'optRetCrypt' if applies
#                               
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="modBefore";
    $errTxt="err=101"; $msg="*** $sbr: not def ";
    return(0,"ok,$errTxt",$msg."fileInLoc!")      if (! defined $fileInLoc );
    return(0,"ok,$errTxt",$msg."filePredTmpLoc!") if (! defined $filePredTmpLoc);
    return(0,"ok,$errTxt",$msg."fileJobIdLoc!")   if (! defined $fileJobIdLoc );
    return(0,"ok,$errTxt",$msg."dirWork!")        if (! defined $dirWork );
    $fhOutSbr="STDOUT"                            if (! defined $fhOutSbr );

    # --------------------------------------------------
    # (0a) clean up the input file
    # --------------------------------------------------
    $fileTmp=                   $dirWork.$fileJobIdLoc . ".tmp1";	
    print $fhOutSbr 
	"--- $sbr \t call filePurgeNullChar($fileInLoc,$fileInLoc,$fileTmp)\n";
    ($Lok,$msg)=
	&filePurgeNullChar($fileInLoc,$fileInLoc,$fileTmp);
    return(0,"ok,err=103","*** $sbr \n ".$msg) if (! $Lok);
    if ($fileTmp){
	$kwd="filePurgeNullChar"; push(@kwdRm,$kwd);$file{$kwd}=$fileTmp;}
				# ------------------------------
				# remove blank lines
    print $fhOutSbr 
	"--- $sbr \t call filePurgeBlankLine($fileInLoc,$fileInLoc,$fileTmp)\n";
    $fileTmp=                   $dirWork.$fileJobIdLoc . ".tmp2";	
    ($Lok,$msg)=
	&filePurgeBlankLines($fileInLoc,$fileInLoc,$fileTmp);
    return(0,"ok,err=104","*** $sbr \n ".$msg) if (! $Lok);
    if ($fileTmp){
	$kwd="filePurgeBlankLine"; push(@kwdRm,$kwd);$file{$kwd}=$fileTmp;}

    # --------------------------------------------------
    # (0b) append input file to temporary result
    # --------------------------------------------------

    $msgHere="";
				# ------------------------------
				# keyword for changing global:
				# $User_name_forced: SEND_RESULT_TO name
				# ------------------------------
    $user=            0;
    $User_name_forced=0;
    $user=`grep 'SEND_RESULT_TO' $fileInLoc`;
    if ($user) {
	$user=~s/^.*SEND_RESULT_TO\s+(\S+)\s*\.*$/$1/g;
	$User_name_forced=$user
	    if ($user=~/\@.*\.[a-z][a-z][a-z]?$/);
	print 
	    "*** ERROR in extrHdrOneLine: user=$user wrong! \n",
	    "*** line=$lineLoc\n" if (! $User_name_forced); 
    }
    if ($User_name_forced) {
	($Lok,$msg)=&sysSystem("echo 'PPhdr from: $User_name_forced' >> $filePredTmpLoc");

	($Lok,$msg)=
	    &sysCatfile("nonice",$LdebugLoc,$filePredTmpLoc,
			$fileInLoc,$envPP{"fileAppLine"});
	$msgHere.="$msg" if (!$Lok); }
	
    ($Lok,$msg)=
	&sysCatfile("nonice",$LdebugLoc,$filePredTmpLoc,$envPP{"fileAppInSeqSent"},
		    $fileInLoc,$envPP{"fileAppLine"});

    $msgHere.="$msg" if (!$Lok);

    # --------------------------------------------------
    # (1a) check_licence
    # --------------------------------------------------
				# possible out '0|"licence expired"|"licence exhausted"
				#              "no licence       "' 
    $Lfin=0;			# '0' means : ok

				# old way of doing things
#     $Licence_problem= 
# 	&licence'predict_not_allowed($User_name,$Password);   #e.e'
#     if ($Licence_problem) {
# 	print $fhOutSbr "-*- $sbr WARN: \t licence problem '$Licence_problem'\n";
# 				# no licence: do prediction, nevertheless
# 	if   ($Licence_problem =~ /no lic/)   {
# 	    @tmp=($envPP{"fileAppLicNew"},$envPP{"fileAppLine"});}
# 				# licence expired: ok
# 	elsif ($Licence_problem =~ /expired/)  {
# 	    @tmp=($envPP{"fileAppLicExpired"},$envPP{"fileAppLine"});}
# 				# licence exhausted: ok
# 	elsif ($Licence_problem =~ /exhausted/){
# 	    @tmp=($envPP{"fileAppLicExhaust"},$envPP{"fileAppLine"});}
# 				# **************************************************
# 				# abort prediction only if password is invalid
# 	elsif ($Licence_problem=~ /invalid password/) {
# 	    &ctrlDbgMsg("licence: invalid password (lead to abort)",$fhOutSbr,$LdebugLoc);
# 	    $SeqDescription= "ERROR: invalid password"; 
# 	    $Lfin=1;$job{"fin"}=1; # <<<<< ********
# 	    @tmp=($envPP{"fileAppLicPwd"},$envPP{"fileAppLine"});}
# 	push(@tmp,$envPP{"fileLicText"},$envPP{"fileAppLine"});
# 	($Lok,$msg)=
# 	    &sysCatfile("nonice",$LdebugLoc,$filePredTmpLoc,@tmp,$envPP{"fileAppLine"});
# 	$msgHere.="$msg" if (!$Lok);
# 				# ******************************
# 	if ($Lfin){
# 	    return(0,"err=105","abort=licence: invalid password,\n". # <<<<< ******
# 		   "--- $sbr invalid passw\n ");}}  # <<<<< ******

    ($Lok,$msg,$LisCommercial,$LlicenseOk)=
	&userAllowed($User_name,$Password,$Date);
				# problem with commercial?
    if ($LisCommercial && ! $LlicenseOk) {
				# no licence: do prediction, nevertheless
 	print $fhOutSbr "-*- $sbr WARN: \t licence problem '$msg' (user=$user, pwd=$password)\n";
	if    ($msg =~ /expired.*saturated/)   {
	    @tmp=($envPP{"fileAppLicExhaust"},$envPP{"fileAppLine"});}
	elsif ($msg =~ /expired.*date/)   {
	    @tmp=($envPP{"fileAppLicExpired"},$envPP{"fileAppLine"});}
				# licence expired: ok
	elsif ($msg =~ /not.*verified/i)  {
	    @tmp=($envPP{"fileAppLicNew"},$envPP{"fileAppLine"});}

				# **************************************************
				# abort prediction 
#	&ctrlDbgMsg("licence: invalid password (lead to abort)",$fhOutSbr,$LdebugLoc);
#	$SeqDescription= "ERROR: invalid password"; 
#	@tmp=($envPP{"fileAppLicPwd"},$envPP{"fileAppLine"});

	$SeqDescription= "ERROR: invalid password"; 
	$Lfin=1;$job{"fin"}=1; # <<<<< ********
	push(@tmp,$envPP{"fileLicText"},$envPP{"fileAppLine"});

	($Lok,$msg)=		# 
	    &sysCatfile("nonice",$LdebugLoc,$filePredTmpLoc,@tmp,$envPP{"fileAppLine"});
	$msgHere.="$msg" if (!$Lok);
	return(0,"err=105","abort=licence: invalid password,\n". # <<<<< ******
	       "--- $sbr invalid passw\n ");}  # <<<<< ******
    elsif ($msg=~/bad/){
	@tmp=($envPP{"fileAppLicNew"},$envPP{"fileAppLine"},
	      $envPP{"fileLicText"},$envPP{"fileAppLine"});
	($Lok,$msg)=		# 
	    &sysCatfile("nonice",$LdebugLoc,$filePredTmpLoc,@tmp,$envPP{"fileAppLine"}); }

    # --------------------------------------------------
    # (1b) check_encryption
    # --------------------------------------------------
				# remove blank lines
    $file{"lic1"}=$f1=          $dirWork.$fileJobIdLoc.".k1_lic";
    $file{"lic2"}=$f2=          $dirWork.$fileJobIdLoc.".k2_lic";
    $file{"lic3"}=$f3=          $dirWork.$fileJobIdLoc.".k3_lic";
    $file{"lic4"}=$f4=          $dirWork.$fileJobIdLoc.".k4_lic";
    $crypt_status= &licence::decrypt($User_name,$fileInLoc,$f1,$f2,$f3,$f4); 

    foreach $kwd ("lic1","lic2","lic3","lic4"){
	push(@kwdRm,$kwd) if (-e $file{$kwd});}

    if (($crypt_status ne $Crypt_on) && ($crypt_status ne $Crypt_of)) {
	print $fhOutSbr "ERROR: crypt problem $crypt_status \n";
	&ctrlAlarm("ERROR: crypt problem $crypt_status (lead to abort)");
	$job{"fin"}=1;
	$SeqDescription= "ERROR: decryption"; 
	return(0,"err=106","abort=decrypt: crypt problem, ($crypt_status) \n".
	       "--- $sbr ERROR: crypt problem $crypt_status\n ");}
    else {
	if ($crypt_status eq $Crypt_on) {
	    $job{"out"}.="optRetCrypt,"; } }
    return(1,"ok","$sbr ok");
}				# end of modBefore

#===============================================================================
sub modInterpret {
    local($fileInLoc,$fileJobIdLoc,$fileHtmlTmp,$fileHtmlToc,$dirWorkLoc,$fhOutSbr,$fhErrSbr,
	  $LdebugLoc,$paraMinLenLoc,$paraMaxLenLoc,$paraGeneLoc) = @_ ;
    local($sbr,$fhin,$tmp,$Lok,$msg,$msgRet,$seq_char_per_line,$name,$format,%tmp,
	  @tmp,$modeLoc,$LokWrt,$fileOut,$errn,$fileOutGuide,$fileOutOther);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   modInterpret                interprets the request sent, i.e., extracts the
#                               sequence, and returns all options of what to do.
#       in:                     $fileInLoc,$fileJobIdLoc,$dirWorkLoc,$fhOutSbr,$fhErrSbr,
#       in:                     $LdebugLoc,$paraMinLenLoc,$paraMaxLenLoc,$paraGeneLoc
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#         $fhErrSbr             handle for error messages
#         $fhOutSbr             handle for normal messages
#         $LdebugLoc            if 1 temporary files will be kept (and names returned)
#         $paraMinLenLoc        minimal length of sequence (for PHD)
#         $paraMaxLenLoc        maximal length of sequence (for MaxHom)
#         $paraGeneLoc          maximal ratio of ACGT content (otherwise => genome seq)
#                               
#       out GLOBAL:             $seqStatus =$msgErr{""})
#       out GLOBAL:             $job{"seq"}= only ONE of the following:
#                                    'ppOld|msf|saf|col|pirList|fastaList'
#       out GLOBAL:             $job{"out"}= many of the following possible
#                                    'ret ali    [no|prof|hssp|blastp]'
#                                    'ret phd    [msf|casp2|col|graph|mach|rdb]'
#                                    'ret topits [hssp|strip|own]'
#                                    'ret no     [coils|prosite|prodom|seg|segglob]
#                                    'ret concise'
#                                    'ret html   [| detail|,perline=n| detail,perline=n]'
#       out GLOBAL:             $job{"run"}= 
#                                    'phd (acc,sec,htm),evalsec,blastp,fasta,maxhom,prodom'
#                                    'filterAli,filterPhd,noFilterAli,noFilterPhd'
#                                    'doNotAlign,'
#                                    'segnorm,segglob',
#                                    'db=[pdb|big|swiss|trembl]'
#                                    ''
#       out GLOBAL:             $job{""}=
#       out GLOBAL:             @kwdRm
#       out GLOBAL:             $file{"seqIn"}    submitted file in 'understandable' format
#       out GLOBAL:             $file{"ali"}      if input is PIR/FASTA list SAF/MSF
#       out GLOBAL:             $file{"seqFasta"} is guide seq in FASTA format
#       out GLOBAL:              $FLAG_CHANGED_DBWANT= 1, if db changed since sequence too
#                                                 long (for searching BIG, there is a maximal
#                                                 sequence length!)
#                               
#       out:                    $Lok,$msg,$mode (mode=error,help,ok),$parBlastDb
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#       err:                    (1,'ok',txt)        -> ok
#       err:                    (0,errNumber,'msg') -> input or RUN error
#       err:                    (2,errNumber,'msg') -> help request
#       err:                    (3,errNumber,'msg') -> assumed format ERROR from user
#-------------------------------------------------------------------------------
    # --------------------------------------------------
    # initial checks
    # --------------------------------------------------
    $sbr="modInterpret";
    $errn=0;
    $errTxt="err=201"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."fileInLoc!")       if (! defined $fileInLoc);
    return(0,$errTxt,$msg."fileJobIdLoc!")    if (! defined $fileJobIdLoc);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."dirWorkLoc!")      if (! defined $dirWorkLoc);
    return(0,$errTxt,$msg."fhOutSbr!")        if (! defined $fhOutSbr);
    return(0,$errTxt,$msg."fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."paraMinLenLoc!")   if (! defined $paraMinLenLoc);
    return(0,$errTxt,$msg."paraMaxLenLoc!")   if (! defined $paraMaxLenLoc);
    return(0,$errTxt,$msg."paraGeneLoc!")     if (! defined $paraGeneLoc) ;

    if (($paraMinLenLoc =~ /\D/)||($paraMinLenLoc < 0))    {
	return(0,"err=203","*** $sbr: unreasonable paraMinLenLoc=$paraMinLenLoc,\n");}
    if (($paraMaxLenLoc =~ /\D/)||($paraMaxLenLoc < 1000)) {
	return(0,"err=203","*** $sbr: unreasonable paraMaxLenLoc=$paraMaxLenLoc,\n");}
    if (($paraGeneLoc =~ /[^0-9.]/)||($paraGeneLoc < 0.2)) {
	return(0,"err=203","*** $sbr: unreasonable paraGeneLoc=$paraGeneLoc,\n");}
    if (! -e $fileInLoc && ! -l $fileInLoc ){
	$seqStatus=$msgErr{"in:nofile"};
	return(0,"err=202","*** $sbr: miss input file '$fileInLoc'!");}
    $dirWorkLoc.="/" if ($dirWorkLoc !~ /\//); # append slash if missing in directory
    if (! -d $dirWorkLoc)       {($Lok,$msg)= &sysMkdir($dirWorkLoc);
				 return(0,"err=202","*** $sbr: \n$msg!") if (! $Lok);}
				# ------------------------------
				# ini defaults
    $seq_char_per_line= 60;     # output format
				# options
    $optSeq="";
    $optOut="msf";		# return MSF is default
   
#    $optRun="phd";		# run PHDsec+PHDacc+PHDhtm is default
    $optRun="prof,phdhtm";		# run PROFsec+PROFacc+PROFhtm is default

				# messages
    $msgHelp=         "--- $sbr: is help request";
    $msgErrCol=       $msgErr{"in:col"};
    $msgErrColNeeded= $msgErr{"in:colNeeded"};
    $msgErrColTopits= $msgErr{"in:colTopits"};
    $msgErrHash=      $msgErr{"in:noHash"};
    $msgErrIntern=    $msgErr{"internal"};
    $msgErrLong=      $msgErr{"in:long"};
    $msgErrShort=     $msgErr{"in:short"};
    $msgErrGene=      $msgErr{"in:gene"};
    $msgErrMsf=       $msgErr{"in:msf"};
    $msgErrSaf=       $msgErr{"in:saf"};
    $msgErrPirlist=   $msgErr{"in:pirlist"};
#    $msgErrPirmul=    $msgErr{"in:pirmul"};
    $msgErrFastalist= $msgErr{"in:fastalist"};
    $msgErrFastamul=  $msgErr{"in:fastamul"};
    $msgErrFormat=    $msgErr{"in:format"};
				# ------------------------------
    print $fhOutSbr		# ini wrt
	"--- $sbr starts in:\n",
	"---          $fileInLoc,$fileJobIdLoc,$dirWorkLoc,$fhOutSbr,$fhErrSbr\n",
	"---          $LdebugLoc,$paraMinLenLoc,$paraMaxLenLoc,$paraGeneLoc\n";

    # --------------------------------------------------
    # (1) extract information 
    # --------------------------------------------------
				# open files
    $fhin="FILEIN";
    open("$fhin",$fileInLoc)     || 
	return(0,"err=204","*** $sbr: cannot open input file '$fileInLoc'!");
				# ------------------------------
				# read header (before #)
    print $fhOutSbr "--- $sbr \t call extrHdr($fhin,$fhOutSbr,$fhErrSbr)\n";
				# ===============================
				# note: GLOBAL variable returned: 
				#       $optRun,$optOut,$optSeq
				# also: MAY define $User_name_forced
				#       if keyword SEND_RESULTS_TO user@machine
    $Lok=
	&extrHdr($fhin,$fhOutSbr,$fhErrSbr);
    
				# ******************************
    if    (! $Lok){		# no '#' found -> error message
	close("$fhin");
	$seqStatus=$msgErrHash;
	$SeqDescription= "ERROR: input ".$msgErrHash; 
	return(3,"err=205","abort=input problem: ".$msgErrHash.", \n"."error");}
    elsif ($optRun eq "help"){	# help request -> return help file
	close("$fhin");
	$SeqDescription= "help request";
	return(2,"help",$msgHelp);}
				# ------------------------------
				# clean up conflicts
				# NOTE: corrects optSeq 
				#        pirList   -> pirMul
				#        fastaList -> fastaMul
    print $fhOutSbr "--- $sbr \t call extrConflicts\n";
    &extrConflicts() if ( $optRun !~ /cafasp threader/ );
    if    ($optRun =~ /evalsec/ && $optSeq ne "col"){
	$seqStatus=$msgErrColNeeded;
	$SeqDescription= "ERROR: input ".$msgErrColNeeded;
	return(3,"err=206","abort=input problem: ".$msgErrColNeeded.", \n"."error");}
    elsif (($optRun !~ /evalsec/)&&($optSeq eq "col")&&($optRun !~ /topits/)){
	$seqStatus=$msgErrColNeeded;
	$SeqDescription= "ERROR: input ".$msgErrColNeeded;
	return(3,"err=229","abort=input problem: ".$msgErrColTopits.", \n"."error");}
				# ------------------------------
    $#seq=0;			# read all sequence information
				# ------------------------------
    print $fhOutSbr "--- $sbr \t read sequence information\n";
    while(<$fhin>){
	if ( $optSeq =~/^pp/ ) { # for default pp format
	    next if ( /^\s*\#/ ); # ignore header
	    if ( /^\s*\>/ ) {	# ignore fasta header
		$fastaHeader = $_;
		$fastaHeader =~ s/\s*\>\s*//g;
		$fastaHeader =~ s/\s+$//g;
		if ( $fastaHeader ) {
		    $optSeq =~ s/,.*$/,$fastaHeader/;
		    next;
		}
	    }
	}
	$_=~s/\n//g;
	$_=~s/^\s*|\s*$//g;
	next if (length($_)<1);
	push(@seq,$_);}
    close("$fhin");

				# check whether or not anything found
    if ($#seq < 1) {
	$errn=      "err=2001";
	$msg=       "no information found after line with hash (#)\n".$msgErrFormat;
	$job{"fin"}=1;
	$seqStatus=      "ERROR: $errn".$msg."\n";
	$SeqDescription= "ERROR: input ".$msg."\n";
				# debug messages and error check
	&ctrlDbgMsg("Status   =$seqStatus (from $sbr)",$fhOutSbr,$LdebugLoc);
	return(0,$errn,"input problem:$msg\n"."error");}


    $tmp=$fileInLoc;$tmp=~s/^.*\///g;

    print $fhOutSbr "--- $sbr: optOut=$optOut\n" if ($optOut !~ /^msf,/);
    print $fhOutSbr "--- $sbr: optRun=$optRun\n" if ($optRun !~ /phd/);
    print $fhOutSbr "--- $sbr: optSeq=$optSeq\n" if ($optSeq =~ /^pp/);
				# ------------------------------
				# store directives in GLOBAL var
				# note: comes from extrHdrOneLine
    $job{"seq"}=$optSeq;	# note: comes from extrHdrOneLine
				# possible: ppOld|msf|col|saf|pirList
    $job{"out"}=$optOut;	# note: comes from extrHdrOneLine
				# 
    $job{"run"}=$optRun;	# note: comes from extrHdrOneLine

    # --------------------------------------------------
    # (2) different input options
    # --------------------------------------------------
    $msgRet="";
    if  ($optSeq =~/^pp/){	# old PP mode
	$name=$optSeq;$name=~s/^ppOld\s*\s*,\s*//g;$name.=" ".$fileInLoc;
	$fileOut=               $dirWorkLoc . $fileJobIdLoc . ".fasta"; 
	$file{"seq"}=$file{"seqFasta"}=$fileOut;
	push(@kwdRm,"seq","seqFasta");
	print $fhOutSbr 
	    "--- $sbr \t call interpretSeqPP($fileOut,$name,$seq_char_per_line,".
		"$paraMinLenLoc,$paraMaxLenLoc,$paraGeneLoc)\n";
	($LokWrt,$msg,$lenTmp)=
	    &interpretSeqPP($fileOut,$name,$seq_char_per_line,
			    $paraMinLenLoc,$paraMaxLenLoc,$paraGeneLoc,@seq);
	if    (! $LokWrt) {$retVal=0;$errn="err=207";$msgRet=" ".$msgErrIntern.", \n$msg";}
	elsif ($LokWrt==2){$retVal=3;$errn="err=208";$msgRet=" ".$msgErrShort .", \n$msg";}
	elsif ($LokWrt==3){$retVal=3;$errn="err=209";$msgRet=" ".$msgErrLong  .", \n$msg";}
	elsif ($LokWrt==4){$retVal=3;$errn="err=210";$msgRet=" ".$msgErrGene  .", \n$msg";}
	else              {$retVal=1;$seqStatus="OK ";$SeqDescription="normal PP format";}
	$lenSeq=$lenTmp         if (defined $lenTmp && $lenTmp=~/^\d+$/);
	$job{"run"}.=",blastp,maxhom,blastpsi";} # output file keyword
				# ------------------------------
    elsif ($optSeq eq "msf"){	# MSF format
	$fileOut=               $dirWorkLoc . $fileJobIdLoc . ".msfIn"; 
	$fileOutGuide=          $dirWorkLoc . $fileJobIdLoc . ".fasta"; 
	$file{"seq"}=$file{"seqFasta"}=$file{"ali"}=$fileOut;
	$file{"seqFasta"}=$fileOutGuide;
	push(@kwdRm,"seq","seqFasta","ali");  
	print $fhOutSbr "--- $sbr \t call interpretSeqMsf($fileOut,$fileOutGuide,$fhErrSbr)\n";
	($LokWrt,$msg)=
	    &interpretSeqMsf($fileOut,$fileOutGuide,$fhErrSbr,@seq);
	if ($LokWrt != 1){
	    $msgMsf=$msg; $msgMsf=~s/\n//g;$msgMsf=~s/^.*(wrong MSF:[^!]*\!).*/$1/g;}
	if    (! $LokWrt) {$retVal=0;$errn="err=211";$msgRet=" ".$msgErrIntern.", \n$msg";}
	elsif ($LokWrt==2){$retVal=3;$errn="err=212";$msgRet=" ".$msgErrMsf." ($msgMsf)\n$msg";}
	elsif ($LokWrt==3){$retVal=3;$errn="err=232";$msgRet=" ".$msgErrMsf." ($msgMsf)\n$msg";}
	else              {$retVal=1;$seqStatus="OK";$SeqDescription="MSF format";}
	$job{"run"}.=",convert";} # output file keyword
				# ------------------------------
    elsif ($optSeq eq "col"){	# COL format
	if ($optRun eq "evalsec"){
	    $fileOut=           $dirWorkLoc . $fileJobIdLoc . ".colIn"; 
	    $fileOutGuide=      " "; 
	    $job{"seq"}="col";$Levalsec=1;}
	else{
	    $fileOut=           $dirWorkLoc . $fileJobIdLoc . ".dsspIn"; 
	    $fileOutGuide=      $dirWorkLoc . $fileJobIdLoc . ".fasta"; 
	    $file{"seqFasta"}=  $fileOutGuide;
	    $job{"seq"}="dssp";$Levalsec=0;}
	$file{"seq"}=$file{"phdDssp"}=$fileOut;
	$file{"seqFasta"}=$fileOutGuide;
	push(@kwdRm,"seq","seqFasta","phdDssp");  
	print $fhOutSbr 
	    "--- $sbr \t call interpretSeqCol($fileOut,$fileOutGuide,".
		"$fileInLoc,$Levalsec,$fhErrSbr)\n";
	($LokWrt,$msg)=
	    &interpretSeqCol($fileOut,$fileOutGuide,$fileInLoc,$Levalsec,$fhErrSbr,@seq);
	if    (! $LokWrt) {$retVal=0;$errn="err=213";$msgRet=" ".$msgErrIntern.", \n$msg";}
	elsif ($LokWrt==2){$retVal=3;$errn="err=214";$msgRet=" ".$msgErrCol   .", \n$msg";}
	elsif ($LokWrt==3){$retVal=3;$errn="err=233";$msgRet=" ".$msgErrCol   .", \n$msg";}
	else              {$retVal=1;$seqStatus="OK";$SeqDescription="COL format";}}
				# ------------------------------
    elsif ($optSeq eq "saf"){	# SAF format
	$fileOut=               $dirWorkLoc . $fileJobIdLoc . ".msfIn"; 
	$fileOutGuide=          $dirWorkLoc . $fileJobIdLoc . ".fasta"; 
	$file{"seq"}=$file{"ali"}=$fileOut;
	$file{"seqFasta"}=$fileOutGuide;
	push(@kwdRm,"seq","seqFasta","ali");  
	print $fhOutSbr "--- $sbr \t call interpretSeqSaf($fileOut,$fileOutGuide,$fhErrSbr)\n";
	($LokWrt,$msg)=
	    &interpretSeqSaf($fileOut,$fileOutGuide,$fhErrSbr,@seq);
	if    (! $LokWrt) {$retVal=0;$errn="err=215";$msgRet=" ".$msgErrIntern.",\n".$msg;}
	elsif ($LokWrt==2){$retVal=3;$errn="err=216";$msgRet=" ".$msgErrSaf   .",\n".$msg;}
	elsif ($LokWrt==3){$retVal=3;$errn="err=234";$msgRet=" ".$msgErrSaf   .",\n".$msg;}
	elsif ($LokWrt==4){$retVal=3;$errn="err=235";$msgRet=" ".$msgErrSaf   .",\n".$msg;}
	elsif ($LokWrt==5){$retVal=3;$errn="err=236";$msgRet=" ".$msgErrSaf   .",\n".$msg;}
	else              {$retVal=1;$seqStatus="OK";$SeqDescription="SAF format";}
	$job{"seq"}="msf";$job{"run"}.=",convert"; }
				# ------------------------------
    elsif ($optSeq eq "pirList"){ # PIR list
	$fileOutGuide=          $dirWorkLoc . $fileJobIdLoc . ".fastaGuideIn"; 
	$fileOutOther=          $dirWorkLoc . $fileJobIdLoc . ".fastaOtherIn"; 
	$file{"seq"}=$file{"seqFasta"}=$fileOutGuide;
	$file{"aliList"}=$fileOutOther;
	push(@kwdRm,"seq","aliList");
	print $fhOutSbr 
	    "--- $sbr \t call interpretSeqPirlist($fileOutGuide,$fileOutOther,".
		"$paraMinLenLoc,$fhErrSbr)\n";
	($LokWrt,$msg)=
	    &interpretSeqPirlist($fileOutGuide,$fileOutOther,$paraMinLenLoc,$fhErrSbr,
				 $optRun,@seq);
	if    (! $LokWrt) {$retVal=0;$errn="err=217";$msgRet=" ".$msgErrIntern  .", \n$msg";}
	elsif ($LokWrt==2){$retVal=3;$errn="err=218";$msgRet=" ".$msgErrPirlist .", \n$msg";}
	elsif ($LokWrt==3){$retVal=3;$errn="err=219";$msgRet=" ".$msgErrPirlist .", \n$msg";}
	elsif ($LokWrt==4){$retVal=3;$errn="err=220";$msgRet=" ".$msgErrPirlist .", \n$msg";}
	else              {$retVal=1;$seqStatus="OK";$SeqDescription="PIR list format";}}
				# ------------------------------
    elsif ($optSeq eq "pirMul"){ # PIR list (aligned)
	$fileOutGuide=          $dirWorkLoc . $fileJobIdLoc . ".fastaGuideIn"; 
	$fileOutOther=          $dirWorkLoc . $fileJobIdLoc . ".fastaOtherIn"; 
	$file{"seq"}=$file{"seqFasta"}=$fileOutGuide;
	push(@kwdRm,"seq");
	print $fhOutSbr 
	    "--- $sbr \t call interpretSeqPirmul($fileOutGuide,".
		"$paraMinLenLoc,$fhErrSbr)\n";
	($LokWrt,$msg)=
	    &interpretSeqPirmul($fileOutGuide,$paraMinLenLoc,$fhErrSbr,@seq);
	if    (! $LokWrt) {$retVal=0;$errn="err=2172";$msgRet=" ".$msgErrIntern  .", \n$msg";}
	elsif ($LokWrt==2){$retVal=3;$errn="err=2182";$msgRet=" ".$msgErrPirlist .", \n$msg";}
	elsif ($LokWrt==3){$retVal=3;$errn="err=2192";$msgRet=" ".$msgErrPirlist .", \n$msg";}
	elsif ($LokWrt==4){$retVal=3;$errn="err=2202";$msgRet=" ".$msgErrPirlist .", \n$msg";}
	else              {$retVal=1;$seqStatus="OK";$SeqDescription="PIR list format";}}
				# ------------------------------
    elsif ($optSeq eq "fastaList"){ # FASTA list (aligned)
	$fileOutGuide=          $dirWorkLoc . $fileJobIdLoc . ".fastaGuideIn"; 
	$fileOutOther=          $dirWorkLoc . $fileJobIdLoc . ".fastaOtherIn"; 
	$file{"seq"}=$file{"seqFasta"}=$fileOutGuide;
	$file{"aliList"}=$fileOutOther;
	push(@kwdRm,"seq","aliList");
	print $fhOutSbr 
	    "--- $sbr \t call interpretSeqFastalist($fileOutGuide,$fileOutOther,".
		"$paraMinLenLoc,$fhErrSbr)\n";
	($LokWrt,$msg)=
	    &interpretSeqFastalist($fileOutGuide,$fileOutOther,$paraMinLenLoc,$fhErrSbr,
				   $optRun,@seq);
	if    (! $LokWrt) {$retVal=0;$errn="err=221";$msgRet=" ".$msgErrIntern  .", \n$msg";}
	elsif ($LokWrt==2){$retVal=3;$errn="err=222";$msgRet=" ".$msgErrFastalist .", \n$msg";}
	elsif ($LokWrt==3){$retVal=3;$errn="err=223";$msgRet=" ".$msgErrFastalist .", \n$msg";}
	elsif ($LokWrt==4){$retVal=3;$errn="err=224";$msgRet=" ".$msgErrFastalist .", \n$msg";}
	else              {$retVal=1;$seqStatus="OK";$SeqDescription="FASTA list format";}}
				# ------------------------------
    elsif ($optSeq eq "fastaMul"){ # FASTA list
	$fileOutGuide=          $dirWorkLoc . $fileJobIdLoc . ".fastaGuideIn"; 
	$file{"seq"}=$file{"seqFasta"}=$fileOutGuide;
	push(@kwdRm,"seq");
	print $fhOutSbr 
	    "--- $sbr \t call interpretSeqfastamul($fileOutGuide,".
		"$paraMinLenLoc,$fhErrSbr)\n";
	($LokWrt,$msg)=
	    &interpretSeqFastamul($fileOutGuide,$paraMinLenLoc,$fhErrSbr,@seq);
	if    (! $LokWrt)  { $retVal=0;$errn="err=2212";$msgRet=" ".$msgErrIntern  .", \n$msg";}
	elsif ($LokWrt==2) { $retVal=3;$errn="err=2222";$msgRet=" ".$msgErrFastamul .", \n$msg";}
	elsif ($LokWrt==3) { $retVal=3;$errn="err=2232";$msgRet=" ".$msgErrFastamul .", \n$msg";}
	elsif ($LokWrt==4) { $retVal=3;$errn="err=2242";$msgRet=" ".$msgErrFastamul .", \n$msg";}
	else               { $retVal=1;$seqStatus="OK";$SeqDescription="FASTA list format";}}

				# --------------------------------------------------
				# ERROR check
    if ($errn){
	$seqStatus=      "ERROR: $errn".$msgRet."\n";
	$SeqDescription= "ERROR: input ".$msgRet."\n";
				# debug messages and error check
	&ctrlDbgMsg("Status   =$seqStatus (from $sbr)",
		    $fhOutSbr,$LdebugLoc); 
	return($retVal,"err=".$errn,$msgRet);}

    ($Lok,$msg)=
	&modInterpretCheck($msgRet,$LdebugLoc);
    if (! $Lok){
	$job{"fin"}=1;
	$SeqDescription= "ERROR: input format";
	return($retVal,$errn,"input problem: ".$msg." \n"."error"); } # exit predict: error
    
				# ------------------------------
				# process arguments: job control
				# ------------------------------
    if ($job{"run"} =~ /topits/){
	if    ($job{"seq"} =~ /hssp|saf|msf|pirList|fastaList/i){
	    #$job{"run"}.=",phd";}
	    $job{"run"}.=",prof";}
	elsif ($job{"seq"} =~ /pp|swiss/i){
	    #$job{"run"}.=",blastp,maxhom,phd";}}
	    $job{"run"}.=",blastp,maxhom,prof";}}
    $job{"run"}.=",convert"
	if (($job{"seq"} =~ /hssp|saf|msf|pirList|fastaList/i) && ($job{"run"} !~ /convert/));

    &ctrlDbgMsg("opt0 run=".$job{"run"},$fhOutSbr,$LdebugLoc);

				# ------------------------------
				# defaults
				# ------------------------------
				# COILS  
    $job{"run"}.=",coils"       if ($job{"out"}!~ /no coils/);

				# PROFCON  
    $job{"run"}.=",profcon"       if ($job{"out"}=~ /profcon/);
        
    # PROFTMB  
    $job{"run"}.=",proftmb"       if ($job{"out"}=~ /proftmb/);
    
    				# Predict Cell Cycle
    $job{"run"}.="pcc"           if ($job{"out"}=~ /pcc/);

#    				# Predict ProtProt interaction zafi
#    $job{"run"}.="zafi"           if ($job{"out"}=~ /zafi/);

  				# CHOP
#    $job{"run"}.="chop"           if ($job{"out"}=~ /chop/);

				    
				# ------------------------------
				# CYSPRED if phd(3|both| )
    $job{"run"}.=",cyspred"	if ($job{"out"}!~ /no cyspred/ &&
				    $job{"run"}=~/maxhom/);
				# ------------------------------
				# COILS   if phd(3|both| )
    $job{"run"}.=",nls"       if ($job{"out"}!~ /no predictnls/ );
				# ------------------------------
				# ASP   if phd(3|both| )
    $job{"run"}.=",asp"       if ($job{"out"}!~ /no asp/ &&
				    $job{"run"}=~/phd/);
				# ------------------------------
				# NORS   if prof,phdHtm,coils )
    $job{"run"}.=",nors"       if ($job{"out"}!~ /no nors/ &&
				   $job{"run"}=~/prof/i && $job{"run"} =~ /phdHtm/i
				   && $job{"run"} =~ /coils/i );
				# ------------------------------
				# PROSITE if blastp, i.e. alignment
    $job{"run"}.=",prosite"     if ($job{"out"}!~/ret no prosite/ &&
				    $job{"run"}=~/blast/); 
				# br change 99-01: also for PIR, FASTA
    $job{"run"}.=",prosite"     if ($job{"out"}!~/ret no prosite/ &&
				    $optSeq=~ /^(fasta|pir|saf|msf)/);
				# ------------------------------
				# PRODOM  if blastp, i.e. alignment
    $job{"run"}.=",prodom"      if ($job{"out"}!~/ret no prodom/ &&
				    $job{"run"}=~/blast/); 
				# br change 99-01: also for PIR, FASTA
    $job{"run"}.=",prodom"      if ($job{"out"}!~/ret no prodom/ &&
				    $optSeq=~ /^(fasta|pir)/);
				# ------------------------------
				# SEG
    $job{"run"}.=",segnorm"     if (($job{"run"}!~/seg,/ ||
				     $job{"run"}!~/seg.*norm/ ||
				     $job{"run"}!~/seg$/) &&
				    ($job{"out"}!~ /ret no seg,/ ||
				     $job{"out"}!~ /ret no seg.*norm/ ||
				     $job{"out"}!~ /ret no seg$/));
    $job{"run"}.=",segglob"     if ($job{"run"}!~/segglob/ &&
				    $job{"out"}!~ /ret no segglob/);
    
				# default: do filter for MAXHOM
    $job{"run"}.=",filterAli"   if ($job{"run"}=~/maxhom/ && $job{"run"} !~/noFilterAli/);
    $job{"run"}.=",filterPhd"   if ($job{"run"}=~/phd/    && $job{"run"} !~/noFilterPhd/);
    $job{"run"}.=",filterPhd"   if ($job{"run"}=~/prof/   && $job{"run"} !~/noFilterPhd/);

				# ------------------------------
				# clashes
    $job{"run"}=~s/\,prof[a-z]*//g  if ($job{"run"}=~/prof/  && $job{"out"}=~/ret no prof/);
    $job{"run"}=~s/\,phd[a-z]*//g   if ($job{"run"}=~/phd/   && $job{"out"}=~/ret no phd/);

    $job{"run"}=~s/\,prodom//g  if ($job{"run"}=~/prodom/  && $job{"out"}=~/ret no prodom/);
    $job{"run"}=~s/\,prosite//g if ($job{"run"}=~/prosite/ && $job{"out"}=~/ret no prosite/);
    $job{"run"}=~s/\,coils//g   if ($job{"run"}=~/coils/   && $job{"out"}=~/ret no coils/);
    $job{"run"}=~s/\,nls//g     if ($job{"run"}=~/nls/     && $job{"out"}=~/ret no predictnls/);
    $job{"run"}=~s/\,cyspred//g if ($job{"run"}=~/cyspred/ && $job{"out"}=~/ret no cyspred/);
    $job{"run"}=~s/\,asp//g     if ($job{"run"}=~/asp/     && $job{"out"}=~/ret no asp/);
    $job{"run"}=~s/\,segnorm//g if ($job{"run"}=~/segnorm/ && $job{"out"}=~/ret no segnorm/);
    $job{"run"}=~s/\,segglob//g if ($job{"run"}=~/segglob/ && $job{"out"}=~/ret no segglob/);
				# cafaspThreader doesn't want anything else
    $job{"run"}= "cafaspThreader" if ( $job{"run"} =~ /cafaspThreader/ );
				# nors_only is called from NORSp website
    
    if ( $job{"run"} =~ /nors_only/ ) {
	$parNors = $job{"run"};
	if ( $parNors =~ /(parNors\([^\)]+\))/ ) {
	    $parNors = $1;
	}
	print STDERR "--- parNors=$parNors\n";
	$job{"run"}= "blastp,maxhom,blastpsi,filterAli,filterPhd,".
	    "prof,phdHtm,coils,nors,$parNors,nors_only";
	if ( $job{"out"} =~ /ret nors verbose/) {
	    $opt_nors_verbose = 1;
	} else {
	    $opt_nors_verbose = 0;
	}
    }


    # ---------------------------------------------------------------
    # predict cell cycle externally and doesnt use any of pp services
    # ---------------------------------------------------------------
    if ( $job{"run"} =~ /pcc/ ) {
	$job{"run"}= "pcc";
    }
    # ---------------------------------------------------------------
    
    
     # ---------------------------------------------------------------
    # proftmb runs externally and doesnt use any of pp services
    # ---------------------------------------------------------------
    if ( $job{"run"} =~ /proftmb/ ) {
	$job{"run"}= "proftm";
    }
    # ---------------------------------------------------------------

    # ---------------------------------------------------------------
    # predict cell cycle externally and doesnt use any of pp services
    # ---------------------------------------------------------------
    if ( $job{"run"} =~ /zafi/ ) {
	$job{"run"}= "zafi";
    }
    # ---------------------------------------------------------------

    # ---------------------------------------------------------------
    # If run externally then run chop only
    # ---------------------------------------------------------------

    if ( $job{"run"} =~ /chop_only/ ) {
	$parChop = $job{"run"};
	if ( $parChop =~ /(parChop\([^\)]+\))/ ) {
	    $parChop = $1;
	} else {
	    $parChop = "";
	}
	print STDERR "--- parChop=$parChop\n";
	$job{"run"}= "$parChop,chop_only";
    }

	    
    
				# ------------------------------
				# clean up
    $job{"run"}=~s/^,*|,*$//g;
    @tmp=split(/,/,$job{"run"});
    undef %tmp; $job="";
    foreach $tmp(@tmp){
	if (! defined $tmp{$tmp}){
	    $tmp{$tmp}=1;$job.="$tmp,";}}
    $job=~s/,*$//g;
    $job{"run"}=$job;
				# ------------------------------
				# choose database for alignment
				# ------------------------------
    if ($job{"run"}=~/blast/ && $job{"run"}=~/db\=(\w+)/) {
	$tmp=$1; 
	if    ($tmp=~/^big$/)    { $parBlastDb=$envPP{"parBlastDbBig"}; }
	elsif ($tmp=~/^swiss$/)  { $parBlastDb=$envPP{"parBlastDbSwiss"}; }
	elsif ($tmp=~/^pdb$/)    { $parBlastDb=$envPP{"parBlastDbPdb"}; }
	elsif ($tmp=~/^trembl$/) { $parBlastDb=$envPP{"parBlastDbTrembl"}; } 
				# correct db if too long!
	if ($parBlastDb=~/(big|trembl)/ && 
	    $lenSeq > $envPP{"parMaxhomMaxNbig"}) {
	    $parBlastDb=$envPP{"parBlastDbSwiss"};
	    $FLAG_CHANGED_DBWANT=1;
	    print $fhTrace 
		"-*- WARN correct parBlastDb to swiss, since too long ($lenSeq)\n"; }
    }
				# ------------------------------
				# append HTML output
				# ------------------------------
    if ($job{"out"}=~/ret html/){ 
				# security: erase files
	unlink($fileHtmlTmp)    if (-e $fileHtmlTmp);
	unlink($fileHtmlToc)    if (-e $fileHtmlToc);
	$html{"flag_method","pp"}=1;
				# get keywords
	&iniHtmlBuild()         if (! defined %htmlKwd);
	
				# append file
	($Lok,$msg)=&htmlBuild($fileInLoc,$fileHtmlTmp,$fileHtmlToc,1,"in_given");
	if (! $Lok) { $msg="*** err=2210 ($sbr: htmlBuild failed on kwd=in_given_toc)\n".$msg."\n";
		      print $fhTrace $msg;
		      return(0,$msg); } }

				# ------------------------------
				# ini quotes
				# ------------------------------
    &iniQuotes();

    &ctrlDbgMsg("opt2  run=".$job{"run"},$fhOutSbr,$LdebugLoc);
    return(1,"ok","$sbr",$parBlastDb);
}				# end of modInterpret

#===============================================================================
sub modInterpretCheck {
    local($msgLoc,$LdebugLoc2)=@_;
#----------------------------------------------------------------------
#   modInterpretCheck           checks whether an error occurred when
#                               interpreting the input file
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
				# ------------------------------
				# trace flag and options
    foreach $kwd ("seq","run","out"){
	$opt=$job{$kwd};
	&ctrlDbgMsg("opt1  job($kwd)=$opt",$fhTrace,$LdebugLoc2);}
    foreach $kwd ("seq","ali"){
	$file=$file{$kwd};
	next if (! defined $file || ! -e $file);
	&ctrlDbgMsg("file  $kwd=$file",$fhTrace,$LdebugLoc2);}
				# ******************************
    if (length($msgLoc)>0){	# error while writing output
	if (! $LdebugLoc2){
	    foreach $kwd(@kwdRm){
		$Lok= unlink ($file{$kwd});
		$msg.="*** Lok=$Lok, for 'unlink{$kwd}'\n";}}
	$seqStatus=$msgLoc;$seqStatus=~s/\n.*$//g;
	return(0,$msgLoc."\n$msg");} # exit
    $seqStatus=0;
    return(1,"ok");
}				# end of modInterpretCheck

#===============================================================================
sub modInterpretManu {
    local($fileInLoc,$fileJobIdLoc,$dirWorkLoc,$fhOutSbr,$LdebugLoc,$modeLoc)=@_;
    local($sbr,$tmp,%tmp,@tmp,$Lok,$msg,$msgRet,$format,$kwd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   modInterpretManu            checks the input file for the manual mode of
#                               running PP, input options can be: 
#                               'blastp,maxhom,phd,topits,noali' (and combination therof)
#                               noali for running PHD without alignment
#                               will do maxhom self
#       in:   $fileInLoc =      sequence file supplied by user   
#       in:   $fileJobIdLoc =   job id for output stuff
#       in:   $dirWorkLoc =     working directory, used to name output files
#       in:   fhoutSbr/Ldebug                  
#       in:   $modeLoc =        the keywords for directing the job (see above)
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       out:                    (1,msg) or (0,error)
#       out GLOBAL:             $job{"seq"}= only ONE of the following:
#       out GLOBAL:                  'dssp|hssp|msf|saf|pirList|fastaList|swiss|noali'
#       out GLOBAL:             $job{"run"}= more than one of the following:
#       out GLOBAL:                  'convert,blastp,maxhom,phd,phd[htm|acc|sec],topits,
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="modInterpretManu";
				# ------------------------------
				# find out about file format
				# ------------------------------
    ($Lok,$txt,%tmp)=
	&getFileFormat($fileInLoc,"any");
    if (!$Lok){$msg= "*** $sbr ERROR: format of '$fileInLoc' not recognised\n";
	       $msg.="*** for 'Manual' run input file MUST be either of the following\n";
	       $msg.="    DSSP, HSSP, MSF, SAF, PIR_MUL, FASTA_MUL, PIR, FASTA, SWISS-PROT\n";
	       $SeqDescription= "ERROR: input format manual";
	       return(0,"err=230","$msg");}
    $format=$tmp{"format","1"};
				# ------------------------------
				# digest format
    if    ($format=~/dssp/i)      {$job{"seq"}="dssp";}
    elsif ($format=~/hssp/i)      {$job{"seq"}="hssp";   $file{"ali"}=$fileInLoc;}
    elsif ($format=~/msf/i)       {$job{"seq"}="msf";    $job{"run"}.="convert,";}
    elsif ($format=~/saf/i)       {$job{"seq"}="saf";    $job{"run"}.="convert,";}
    elsif ($format=~/pir_mul/i)   {$job{"seq"}="pirList";}
    elsif ($format=~/fasta_mul/i) {$job{"seq"}="fastaList";}
    elsif ($format=~/pir/i)       {$job{"seq"}="pir";    $job{"run"}.="convert,";}
    elsif ($format=~/fasta/i)     {$job{"seq"}="fasta";}
    elsif ($format=~/swiss/i)     {$job{"seq"}="swiss";  $job{"run"}.="convert,";}
    else  {$msg="*** $sbr ERROR: format of '$fileInLoc' = $format, not valid as input\n";
	   return(0,"err=231","$msg");} 
    $job{"run"}="";
				# ------------------------------
				# digest mode
    if ($modeLoc =~ /topits/){	# (1) TOPITS
	if    ($format =~ /dssp|rdb/i) {
	    $job{"run"}.="topits,";}
	elsif ($format =~ /hssp|saf|msf|pir(List|Mul)|fasta(Mul|List)/i){
	    $job{"run"}.="convert,phd,topits,";}
	else {
	    $job{"run"}.="blastp,maxhom,phd,topits,";}}
				# (2) alignments
    foreach $kwd ("blastp","maxhom","evalsec"){
	if (($modeLoc =~ /$kwd/) && ($job{"run"} !~/$kwd/)){
	    $job{"run"}.="$kwd,";}}
				# (3) PHDs
    foreach $kwd ("htm","sec","acc"){
	if (($modeLoc =~ /$kwd/) && ($job{"run"} !~/$kwd/)){
	    $job{"run"}.="phd"."$kwd,";}}
    if    ($modeLoc =~ /phd2/){$job{"run"}.="phd2,";}
    elsif ($modeLoc =~ /phd$/){$job{"run"}.="phd,";}
				# ------------------------------
				# no alignment! 
    if ($modeLoc=~/noali/)    {$job{"run"}=~s/blast\w*|maxhom//g;
			       $job{"seq"}="noali";
			       if ($job{"run"} !~/convert/){
				   $job{"run"}.="convert,";}}
				# ------------------------------
				# clean up
    $job{"run"}=~s/^,*|,*$//g;$job{"run"}=~s/,,/,/g;
    @tmp=split(/,/,$job{"run"});
    undef %tmp; $job="";
    foreach $tmp(@tmp){if (! defined $tmp{$tmp}){$tmp{$tmp}=1;$job.="$tmp,";}}
    $job=~s/,*$//g;
    $job{"run"}=$job;
    $job{"out"}="";

    return(1,"ok","$sbr ok");
}				# end of modInterpretManu

#===============================================================================
sub modConvert {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,$dirWork,
	  $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,
	  $seq,$exeCopf,$exeConvertSeq,$exePhd2dssp,$exeMax,$exeHsspExtrHdr4pp,
	  $maxDefaultG,$Lprof,$fileMaxMetr,$fileMaxMetrLach,
	  $paraMaxSmin,$paraMaxSmax,$paraMaxGo,$paraMaxGe,
	  $paraMaxWeight1,$paraMaxWeight2,$paraMaxIndel1,$paraMaxIndel2,
	  $paraMaxNali,$paraMaxSort,$dirMaxPdb,$paraMaxProfOut,$paraMaxTimeOut,
	  $paraMinLaliPdb,$fileScreenLoc)=@_;
    local($sbr,$fhin,$tmp,$Lok,@tmpAppend,$msg,$msgHere,$file,$fileOut,$pdbidFound,$id,
	  $kwd,$kwd2,$LokWrt,$fileOut,$paraMaxThreshMod,$fileStripOutMod,$cmd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   modConvert                  converts the input to appropriate (e.g. msf2hssp)
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="modConvert";
    $errTxt="err=301"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork );
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    $Ldebug=1                                 if (! defined $Ldebug);

    return(0,$errTxt,$msg."seq!")             if (! defined $seq);
    return(0,$errTxt,$msg."exeCopf!")         if (! defined $exeCopf);
    return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);
    return(0,$errTxt,$msg."exePhd2dssp!")     if (! defined $exePhd2dssp);
    return(0,$errTxt,$msg."exeMax!")          if (! defined $exeMax);
    return(0,$errTxt,$msg."exeHsspExtrHdr4pp!") if (! defined $exeHsspExtrHdr4pp);

    return(0,$errTxt,$msg."maxDefaultG!")     if (! defined $maxDefaultG );
    return(0,$errTxt,$msg."Lprof!")           if (! defined $Lprof );
    return(0,$errTxt,$msg."fileMaxMetr!")     if (! defined $fileMaxMetr );
    return(0,$errTxt,$msg."fileMaxMetrLach!") if (! defined $fileMaxMetrLach );
    return(0,$errTxt,$msg."paraMaxSmin!")     if (! defined $paraMaxSmin );
    return(0,$errTxt,$msg."paraMaxSmax!")     if (! defined $paraMaxSmax );
    return(0,$errTxt,$msg."paraMaxGo!")       if (! defined $paraMaxGo );
    return(0,$errTxt,$msg."paraMaxGe!")       if (! defined $paraMaxGe );
    return(0,$errTxt,$msg."paraMaxWeight1!")  if (! defined $paraMaxWeight1 );
    return(0,$errTxt,$msg."paraMaxWeight2!")  if (! defined $paraMaxWeight2 );
    return(0,$errTxt,$msg."paraMaxIndel1!")   if (! defined $paraMaxIndel1 );
    return(0,$errTxt,$msg."paraMaxIndel2!")   if (! defined $paraMaxIndel2 );
    return(0,$errTxt,$msg."paraMaxNali!")     if (! defined $paraMaxNali );
    return(0,$errTxt,$msg."paraMaxSort!")     if (! defined $paraMaxSort );
    return(0,$errTxt,$msg."dirMaxPdb!")       if (! defined $dirMaxPdb );
    return(0,$errTxt,$msg."paraMaxProfOut!")  if (! defined $paraMaxProfOut );
    return(0,$errTxt,$msg."paraMaxTimeOut!")  if (! defined $paraMaxTimeOut );
    return(0,$errTxt,$msg."paraMinLaliPdb!")  if (! defined $paraMinLaliPdb );
    return(0,$errTxt,$msg."fileScreenLoc!")   if (! defined $fileScreenLoc);

    $errTxt="err=302"; $msg="*** $sbr: no dir =";
    return(0,$errTxt,$msg."$dirWork!")          if (! -d $dirWork);

    return(0,$errTxt,"*** $sbr: no file=$maxDefaultG!")      if (! -e $maxDefaultG && 
								   ! -l $maxDefaultG);
    return(0,$errTxt,"*** $sbr: no file=$fileMaxMetr!")      if (! -e $fileMaxMetr &&
								   ! -l $fileMaxMetr);
    return(0,$errTxt,"*** $sbr: no file=$fileMaxMetrLach!")  if (! -e $fileMaxMetrLach &&
								   ! -l $fileMaxMetrLach);

    return(0,$errTxt,"*** $sbr: no exe =$exeMax!")           if (! -e $exeMax &&
								   ! -l $exeMax);
    return(0,$errTxt,"*** $sbr: no exe =$exeCopf!")          if (! -e $exeCopf &&
								   ! -l $exeCopf);
    return(0,$errTxt,"*** $sbr: no exe =$exeConvertSeq!")    if (! -e $exeConvertSeq &&
								   ! -l $exeConvertSeq);
    return(0,$errTxt,"*** $sbr: no exe =$exePhd2dssp!")      if (! -e $exePhd2dssp &&
								   ! -l $exePhd2dssp);
				# messages
    $msgErrIntern=    $msgErr{"internal"};
    $msgErrSaf=       $msgErr{"convert:saf"};
    $msgErrMsf=       $msgErr{"convert:msf"};
    $msgErrPir=       $msgErr{"convert:pir"};
    $msgErrSwiss=     $msgErr{"convert:swiss"};
    $msgErrRdb=       $msgErr{"convert:rdb"};
    $msgErrPirList=   $msgErr{"convert:pirList"};
    $msgErrFastaList= $msgErr{"convert:fastaList"};
    $msgErrNoAli=     $msgErr{"convert:noAli"};
    $msgHere=         "";
    $#tmpAppend=      0;
    $file2append=     0;
				# --------------------------------------------------
    if ($seq eq "saf"){		# if SAF from manual: first SAF->MSF
				# --------------------------------------------------
	$job{"run"}=~s/maxhom|blast\w*//g;$job{"run"}=~s/\,\,/\,/g; # security

	$fhin="FILEIN";$file=$file{"seq"};$#seq=0;
	open("$fhin","$file")     || 
	    return(0,"err=305","*** $sbr: cannot open input file '$file'!");
	while(<$fhin>){$_=~s/\n//g;
		       push(@seq,$_);}close($fhin);
				# store file (new one will be named 'seq')
	$file{"seq2"}=          $file{"seq"}."2";                     push(@kwdRm,"seq2");
	($Lok,$msg)=&sysCpfile($file{"seq"},$file{"seq2"});
	if (! $Lok){
	    return(0,"err=306",$msgErrIntern."\n"."$msg");}
	else {
	    $msgHere.="--- $sbr /n"."$msg";}
	$msgHere.="--- $sbr \t call interpretSeqSaf($fileOut,$fhErrSbr)\n";
				# --------------------
	($LokWrt,$msg)=		# call converter 
	    &interpretSeqSaf($file{"seq"},$fhErrSbr,@seq);

	if    (! $LokWrt) {$msgRet=" ".$msgErrIntern.", \n$msg"." \n$msgHere";}
	elsif ($LokWrt==2){$msgRet=" ".$msgErrSaf   .", \n$msg";}
	push(@tmpAppend,$envPP{"fileAppInSeqConv"},$file{"seq"},$envPP{"fileAppLine"});
	$file2append=$file{"seq"};
	$seq="msf"; }	# change key!!

				# --------------------------------------------------
    if ($seq eq "msf"){		# MSF format -> HSSP
				# --------------------------------------------------
	$file{"hssp"}=          $dirWork . $fileJobId . ".hssp";      push(@kwdRm,"hssp");
	$file{"msf_check"}=     $dirWork . $fileJobId . ".msf_check"; push(@kwdRm,"msf_check");
	$job{"run"}=~s/maxhom|blast\w*//g;$job{"run"}=~s/\,\,/\,/g; # security

	($Lok,$msg)=
	    &convMsf2HsspNew($file{"seq"},$file{"hssp"},$file{"msf_check"},
			     $exeCopf,$exeConvertSeq,$fileMaxMetrLach,
			     $dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
	return(0,"err=307",$msgErrMsf."\n"."$msg") if (! $Lok); # ******************************
	if ($file{"hssp"} && defined $file{"ali"} && -e $file{"ali"})  {
	    $file{"ali2"}=$file{"ali"}."2";push(@kwdRm,"ali2");
	    $msgHere.="-*- $sbr WARN: $file{ali} was previously defined\n".
		"-*-         now moved to 'ali2'\n";
	    ($Lok,$msg)=&sysCpfile($file{"seq"},$file{"ali2"});
	    if (! $Lok){
		return(0,"err=308",$msgErrIntern."\n"."$msg");}
	    else {$msgHere.="--- $sbr /n"."$msg";}
	    push(@kwdRm,"ali2");$file{"ali"}=$file{"hssp"};}
	$file{"ali"}=           $file{"hssp"};                        push(@kwdRm,"ali");
	if ($file{"msf_check"}){
	    $kwd="aliTmp";push(@kwdRm,$kwd);$file{$kwd}=$file{"hssp"};}}
				# --------------------------------------------------
    elsif ($seq eq "pirList" ||	# PIRlist or FASTAlist, i.e., FASTA files
	   $seq eq "fastaList"){
				# --------------------------------------------------
	$file{"ali"}=           $dirWork.$fileJobId.  ".hssp";        push(@kwdRm,"ali");
	$file{"maxDef"}=        $dirWork."maxhom_default_".$fileJobId;push(@kwdRm,"maxDef");
	foreach $kwd ("aliMissing","aliSelf","aliRet"){
	    $file{$kwd}=        $dirWork.$fileJobId.".".$kwd;         push(@kwdRm,$kwd);}
	push(@tmpAppend,$envPP{"fileAppInSeqConv"},$file{"aliRet"},$envPP{"fileAppLine"});
	$file2append=$file{"aliRet"};

	$fileOut=$file{"ali"};
	$paraMaxThreshMod=  "ALL";
	$fileStripOutMod=   "NO";
	$job{"run"}=~s/maxhom|blast\w*//g;$job{"run"}=~s/\,\,/\,/g; # security
				# ------------------------------
				# security check: is FASTA?
	if (! &isFasta($file{"seq"})) { 
	    $LdoExpandLoc=0;
	    ($Lok,$msg)=
		&copfLocal($file{"seq"},$file{"aliSelf"},0,"fasta",$LdoExpandLoc,
			   $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# conversion failed!
	    return(0,"err=315",$msgErFastaList."\n".
		   "*** $sbr: fault in copf ($exeConvertSeq)\n".$msg) if (! $Lok);}
				# ------------------------------
	($Lok,$msg)=		# local copy of default file
	    &maxhomMakeLocalDefault($maxDefaultG,$file{"maxDef"},$dirWork);
	return(0,"err=316","*** couldnt make local default of Maxhom ($maxDefaultG)\n".
	       $msgErrPirList."\n"."$msg") if (! $Lok);
				# --------------------------------------------------
				# loop over MaxHom runs
	($Lok,$pdbidFound,$LisSelf)=
	    &maxhomRunLoop($date,$nice,$exeMax,$file{"maxDef"},$fileJobId,$dirWork,
			   $file{"seq"},$file{"aliList"},$file{"ali"},
			   $fileMaxMetr,$dirMaxPdb,$Lprof,
			   $paraMaxSmin,$paraMaxSmax,$paraMaxGo,$paraMaxGe,
			   $paraMaxWeight1,$paraMaxWeight2,$paraMaxIndel1,$paraMaxIndel2,
			   $paraMaxNali,$paraMaxThreshMod,$paraMaxSort,$paraMaxProfOut,
			   $fileStripOutMod,$file{"aliMissing"},$paraMinLaliPdb,$paraMaxTimeOut,
			   $fhErrSbr,$fileScreenLoc);
				# note pdbidFound: not necessary here!
	return(0,"err=317",$msgErrPirList."\n"."$pdbidFound") if (! $Lok);
		# convert 2 msf for check
	$LdoExpandLoc=0;
	($Lok,$msg)=
	    &copfLocal($file{"ali"},$file{"aliRet"},0,"msf",$LdoExpandLoc,
		       $exeCopf,$exeConvertSeq,	$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
	return(0,"err=318",$msgErrPirList."\n".
	       "*** failed copf on hssp (".$file{"ali"}.") 2 msf (".$file{"aliRet"}.")\n".
	       $msg) if (! $Lok);}

				# --------------------------------------------------
    elsif ($seq eq "pirMul" ||	# PIRmul or FASTAmul, i.e., FASTA files
	   $seq eq "fastaMul"){
				# --------------------------------------------------
	$file{"ali"}=           $dirWork.$fileJobId.  ".hssp";        push(@kwdRm,"ali");
	foreach $kwd ("aliMissing","aliSelf"){
	    $file{$kwd}=        $dirWork.$fileJobId.".".$kwd;         push(@kwdRm,$kwd);}
	push(@tmpAppend,$envPP{"fileAppInSeqConv"},$envPP{"fileAppLine"});
	$file2append=$file{"seq"};

	$fileOut=$file{"ali"};
	$job{"run"}=~s/maxhom|blast\w*//g;$job{"run"}=~s/\,\,/\,/g; # security
				# ------------------------------
				# security check: is FASTA?
				# NOTE: the interpretSeq* sbrs in lib-pp
				#       actually convert everything to FASTA
	$LdoExpandLoc=0;
	if (! &isFasta($file{"seq"})) { 
	    ($Lok,$msg)=
		&copfLocal($file{"seq"},$file{"aliSelf"},0,"fasta",$LdoExpandLoc,
			   $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# conversion failed!
	    return(0,"err=319",$msgErrPirList."\n".
		   "*** $sbr: fault in copf ($exeConvertSeq)\n".$msg) if (! $Lok);}
				# ------------------------------
				# run copf
	($Lok,$msg)=
	    &copfLocal($file{"seq"},$file{"ali"},"fastamul","hssp",$LdoExpandLoc,
		       $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
	return(0,"err=320",$msgErrPirList."\n".
	       "*** failed copf on FASTAmul (".$file{"seq"}.") 2 HSSP (".$file{"ali"}.")\n".
	       $msg) if (! $Lok);}

				# --------------------------------------------------
    elsif ($seq eq "swiss"){	# SWISS-PROT from manual -> FASTA
				# --------------------------------------------------
	($Lok,$id,$seq)=&swissRdSeq($file{"seq"});
	return(0,"err=330","convert: $msgErrSwiss 1,\n"."$id $msgHere") if (!$Lok);
	$file{"seq2"}=          $file{"seq"}."2";                     push(@kwdRm,"seq2");
	
	($Lok,$msg)=&sysMvfile($file{"seq"},$file{$kwd2});
	if (! $Lok){
	    return(0,"err=331",$msgErrIntern."\n".
		   "convert: $msgErrSwiss 2,\n"."$msg\n $msgHere");}
	else {$msgHere.="--- $sbr /n"."$msg";}
	$fileOut=$file{"seq"};
				# write FASTA format
	$Lok=&fastaWrt($file{"seq"},$id,$seq);
	return(0,"err=332",$msgErrSwiss."\n".
	       "convert: $msgErrSwiss 3,\n"."$id $msgHere") if (! $Lok || ! -e $file{"seq"});}

				# --------------------------------------------------
    elsif ($seq eq "pir"){	# PIR from manual -> FASTA
				# --------------------------------------------------
	($Lok,$id,$seq)=&pirRdSeq($file{"seq"});

	return(0,"err=333","convert: $msgErrPir 1,\n"."$id $msgHere") if (!$Lok);
	$file{"seq2"}=          $file{"seq"}."2";                     push(@kwdRm,"seq2");

	$kwd="seq"; $kwd2="$kwd"."2";
	$fileOut=$file{"seq"};
	$file{$kwd2}=           $file{$kwd}."2";                      push(@kwdRm,"$kwd2");
	($Lok,$msg)=&sysMvfile($file{"seq"},$file{$kwd2});
	if (! $Lok){
	    return(0,"err=334",$msgErrIntern."\n".
		   "convert: $msgErrPir 2,\n"."$msg\n $msgHere");}
	else {$msgHere.="--- $sbr /n"."$msg";}
				# write FASTA format
	$Lok=&fastaWrt($file{"seq"},$id,$seq);
	return(0,"err=335","convert: $msgErrPir 3,\n"."$id $msgHere") 
	    if (! $Lok || ! -e $file{"seq"});}

				# --------------------------------------------------
    elsif ($seq eq "rdb"){	# PHD.RDB from manual -> DSSP
				# --------------------------------------------------
	$kwd="seq";$kwd2="$kwd"."2";
	$file{"phdDssp"}=       $file{$kwd};                          push(@kwdRm,"phdDssp");
	$file{$kwd2}=           $file{$kwd};                          push(@kwdRm,$kwd2);
	$file{$kwd}=~s/\..*$/\.dssp_phd/g;
	$fileOut=$file{"seq"};
	$job{"run"}=~s/maxhom|blast\w*//g;$job{"run"}=~s/\,\,/\,/g; # security
				# call external
	$cmd="$exePhd2dssp ".$file{"seq2"}." file_out=".$file{"seq"};
	($Lok,$msgSys)=&sysSystem("$cmd");
	return(0,"err=336","convert: $msgErrRdb,\n"."$Lok $msgHere")
	    if (! $Lok || ! -e $file{"seq"});}

				# --------------------------------------------------
    elsif ($seq eq "noali"){	# noali from manual -> maxhom self
				# --------------------------------------------------
	$file{"ali"}=           $dirWork.$fileJobId. ".hssp";         push(@kwdRm,"ali");
	$file{"maxDef"}=        $dirWork."maxhom_default_".$fileJobId;push(@kwdRm,"maxDef");
				# for maxhomSelf
	$file{"aliSelf"}=       $dirWork.$fileJobId. ".fastaList";    push(@kwdRm,"aliSelf");
	$fileOut=$file{"ali"};
	$job{"run"}=~s/maxhom|blast\w*//g;$job{"run"}=~s/\,\,/\,/g; # security
				# ------------------------------
				# security check: is FASTA?
	$Lok=&isFasta($file{"seq"});
	$LdoExpandLoc=0;
	if (! $Lok){
	    ($Lok,$msg)=
		&copfLocal($file{"seq"},$file{"aliSelf"},0,"fasta",$LdoExpandLoc,
			   $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# conversion failed!
	    return(0,$msgErrNoAli."\n".
		   "*** $sbr: fault in copf ($exeConvertSeq)\n".$msg) if (! $Lok);}
				# ------------------------------
	($Lok,$msg)=		# call maxhom self
	    &maxhomRunSelf($nice,$exeMax,$file{"maxDef"},$fileJobId,$file{"seq"},
			   $file{"aliSelf"},$fileMaxMetr,$file{"ali"},$exeConvertSeq,
			   $fhErrSbr);
	return(0,"err=337",$msgErrNoAli."\n"."convert: $msg,\n"."$msgHere")
	    if (! $Lok || ! -e $file{"ali"});}

				# --------------------------------------------------
				# append files to current pred_temp
				# --------------------------------------------------
				# note: fileOut can be $file{"seq"} or $file{"ali"}
    if ($origin =~ /^(mail|html|testPP)/i && ($#tmpAppend>0)){
	($Lok,$msg)=
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
	return(0,"err=309",$msgErrIntern."\n"."convert: $msg,\n"."$msgHere") if (! $Lok);}

				# ------------------------------
				# append ali hdr for FASTA, PIR, MSF, SAF
    if ($origin =~ /^(mail|html|testPP)/i && $seq =~/^(pirList|fastaList|msf|saf)/){
	$file{"aliRet"}=        $dirWork.$fileJobId.".msfRet";        push(@kwdRm,"aliRet");
	$file{"aliHdr"}=        $dirWork.$fileJobId.".hsspHdr";       push(@kwdRm,"aliHdr");

				# convert the sequence (HSSP to MSF)
	$LdoExpandLoc=0;
	($Lok,$msg)=
	    &copfLocal($file{"ali"},$file{"aliRet"},0,"msf",$LdoExpandLoc,
		       $exeCopf,$exeConvertSeq,	$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
	return(0,"err=310",$msgErrIntern."\n*** could not convert 2 msf (copf):".
	       $file{"ali"}."->".$file{"aliRet"}."\n".$msg.",\n".$msgHere) if (! $Lok);

				# ext prog hssp_extr_header.pl (reads header of HSSP file)
	$command="$exeHsspExtrHdr4pp ".$file{"ali"}." ".$file{"aliHdr"};
	$msgHere.="\n--- $sbr system '$command'\n";
	($Lok,$msgSys)=
	    &sysSystem("$command");
	return(0,"err=311",$msgErrIntern."\n*** could not extract HSSP header:".
	       $file{"ali"}."\n"."$Lok"."\n"."$msgHere") if (! -e $file{"aliHdr"});
	($Lok,$msg)=
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,$file{"aliHdr"},$envPP{"fileAppLine"});
	return(0,"err=312",$msgErrIntern."\n"."convert: $msg,\n"."$msgHere") if (! $Lok);}

				# ------------------------------
				# append HTML output
				# ------------------------------
    if ($job{"out"}=~/ret html/){
				# --------------------
				# their sequence
	if ($file2append) {
				# append file
	    ($Lok,$msg)=&htmlBuild($file2append,$fileHtmlTmp,$fileHtmlToc,1,"in_taken");
	    if (! $Lok) { $msg="*** err=2220 ($sbr: htmlBuild failed on kwd=in_taken_toc)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,$msg); } }
				# --------------------
				# ali hdr
	if ($seq =~/^(pirList|fastaList|msf|saf)/ && -e $file{"aliHdr"}){
				# append file
	    ($Lok,$msg)=&htmlBuild($file{"aliHdr"},$fileHtmlTmp,$fileHtmlToc,1,"ali_maxhom_head");
	    if (! $Lok) { $msg="*** err=2221 ($sbr: htmlBuild failed on kwd=in_taken_toc)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,$msg); } } }
    return(1,"ok","$sbr");
}				# end of modConvert

#===============================================================================
sub modAlign {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,
	  $optSeq,$optRun,$optOut,
	  $dirData,$dirPdb,$dirSwiss,
				# converting sequence
	  $exeCopf,$exeConvertSeq,$fileMaxMetr,$fileMaxMetrAll,
				# prosite
	  $exeProsite,$filePrositeData,
				# seg
	  $exeSeg,$parSegNorm,$parSegNormMin,
				# prodom
	  $envProdomBlastDb,$parProdomBlastDb,$parProdomBlastN,$parProdomBlastE,$parProdomBlastP,
				# FASTA
#	  $exeFasta,$exeFastaFilter,$envFastaLibs,
#	  $parFastaNhits,$parFastaThresh,$parFastaScore,$parFastaSort,
				# blastpsi
	  $exeBlastPsi,$exeBlast2Saf,$envBlastPsiDb,$argBlastPsi,$argBlastBig,
	  $blastTile,$parBlastPsiDb,$parBlastPsiDbBig,$blastFilThre,
	  $blastMaxAli,$exeBlastRdbExtr4pp,
				# blast
	  $exeBlast,$exeBlastFilter,$envBlastMat,$envBlastDb,$parBlastNhits,$parBlastDb,
				# maxhom
	  $exeMax,$maxDefaultG,$Lprof,$parMaxSmin,$parMaxSmax,$parMaxGo,$parMaxGe,
	  $parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,$parMaxNali,$parMaxSort,$parMaxProfOut,
	  $parMaxTimeOut,$parMinLaliPdb,
	  $parMaxMinIde,$parMaxExpMinIde,$exeHsspExtrHdr4pp,$urlSrs,
				# filter alignment
				# NOTE: default of parFilter changed according to optRun!!
	  $exeHsspFilter,$exeHsspFilterFor,$parFilterAliOff,$parFilterAliPhd,
	  $fileScreenLoc,	# maxhom screen
	  $exeMview,$parMview)=@_;
    local($sbr,$msgHere,$msg,$fileOut,$Lok,$parMaxThreshMod,$fileStripOutMod,
	  $nAli,$nAliBlastPsi,$nAliMax,$LokBlastPsi,$msgBlastPsi,
	  %rdHeader,
	  $fileAliList,$pdbidFound,@tmpAppend,$txt,$command);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   modAlign                    all ali jobs: fasta, blast, maxhom
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="modAlign";
				# ------------------------------
				# consistency check of input
    $errTxt="err=401"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optSeq!")          if (! defined $optSeq);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."dirData!")         if (! defined $dirData);
    return(0,$errTxt,$msg."dirPdb!")          if (! defined $dirPdb);
    return(0,$errTxt,$msg."dirSwiss!")        if (! defined $dirSwiss);
    return(0,$errTxt,$msg."exeCopf!")         if (! defined $exeCopf);
    return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);
    return(0,$errTxt,$msg."fileMaxMetr!")     if (! defined $fileMaxMetr );
    return(0,$errTxt,$msg."fileMaxMetrAll!")  if (! defined $fileMaxMetrAll);
    return(0,$errTxt,$msg."exeProsite!")      if (! defined $exeProsite);
    return(0,$errTxt,$msg."exeSeg!")          if (! defined $exeSeg);
    return(0,$errTxt,$msg."parSegNorm!")      if (! defined $parSegNorm);
    return(0,$errTxt,$msg."parSegNormMin!")   if (! defined $parSegNormMin);
    return(0,$errTxt,$msg."filePrositeData!") if (! defined $filePrositeData );
    return(0,$errTxt,$msg."envProdomBlastDb!")if (! defined $envProdomBlastDb);
    return(0,$errTxt,$msg."parProdomBlastN!") if (! defined $parProdomBlastN);
    return(0,$errTxt,$msg."parProdomBlastE!") if (! defined $parProdomBlastE);
    return(0,$errTxt,$msg."parProdomBlast!")  if (! defined $parProdomBlastP);
    return(0,$errTxt,$msg."exeBlastPsi!")     if (! defined $exeBlastPsi);
    #return(0,$errTxt,$msg."envBlastPsiMat!")  if (! defined $envBlastPsiMat);
    return(0,$errTxt,$msg."envBlastPsiDb!")   if (! defined $envBlastPsiDb);
    return(0,$errTxt,$msg."argBlastPsi!")     if (! defined $argBlastPsi);
    return(0,$errTxt,$msg."argBlastBig!")     if (! defined $argBlastBig);
    return(0,$errTxt,$msg."blastTile!")       if (! defined $blastTile);
    return(0,$errTxt,$msg."parBlastPsiDb!")   if (! defined $parBlastPsiDb);
    return(0,$errTxt,$msg."parBlastPsiDbBig!")   if (! defined $parBlastPsiDbBig);
    return(0,$errTxt,$msg."blastFilThre!")    if (! defined $blastFilThre);

    return(0,$errTxt,$msg."blastMaxAli!")     if (! defined $blastMaxAli);
    return(0,$errTxt,$msg."exeBlastRdbExtr4pp!") if (! defined $exeBlastRdbExtr4pp);

    return(0,$errTxt,$msg."exeBlast!")        if (! defined $exeBlast);
    return(0,$errTxt,$msg."exeBlastFilter!")  if (! defined $exeBlastFilter);
    return(0,$errTxt,$msg."envBlastMat!")     if (! defined $envBlastMat);
    return(0,$errTxt,$msg."envBlastDb!")      if (! defined $envBlastDb);
    return(0,$errTxt,$msg."parBlastNhits!")   if (! defined $parBlastNhits);
    return(0,$errTxt,$msg."parBlastDb!")      if (! defined $parBlastDb);
    return(0,$errTxt,$msg."exeMax!")          if (! defined $exeMax );
    return(0,$errTxt,$msg."maxDefaultG!")     if (! defined $maxDefaultG );
    return(0,$errTxt,$msg."Lprof!")           if (! defined $Lprof );
    return(0,$errTxt,$msg."parMaxSmin!")      if (! defined $parMaxSmin );
    return(0,$errTxt,$msg."parMaxSmax!")      if (! defined $parMaxSmax );
    return(0,$errTxt,$msg."parMaxGo!")        if (! defined $parMaxGo );
    return(0,$errTxt,$msg."parMaxGe!")        if (! defined $parMaxGe );
    return(0,$errTxt,$msg."parMaxW1!")        if (! defined $parMaxW1 );
    return(0,$errTxt,$msg."parMaxW2!")        if (! defined $parMaxW2 );
    return(0,$errTxt,$msg."parMaxI1!")        if (! defined $parMaxI1 );
    return(0,$errTxt,$msg."parMaxI2!")        if (! defined $parMaxI2 );
    return(0,$errTxt,$msg."parMaxNali!")      if (! defined $parMaxNali );
    return(0,$errTxt,$msg."parMaxSort!")      if (! defined $parMaxSort );
    return(0,$errTxt,$msg."parMaxProfOut!")   if (! defined $parMaxProfOut );
    return(0,$errTxt,$msg."parMaxTimeOut!")   if (! defined $parMaxTimeOut );
    return(0,$errTxt,$msg."parMinLaliPdb!")   if (! defined $parMinLaliPdb );
    return(0,$errTxt,$msg."parMaxMinIde!")    if (! defined $parMaxMinIde);
    return(0,$errTxt,$msg."parMaxExpMinIde!") if (! defined $parMaxExpMinIde);
    return(0,$errTxt,$msg."exeHsspExtrHdr4pp!") if (! defined $exeHsspExtrHdr4pp);
    return(0,$errTxt,$msg."exeHsspFilter!")   if (! defined $exeHsspFilter);
    return(0,$errTxt,$msg."exeHsspFilterFor!")if (! defined $exeHsspFilterFor);
    return(0,$errTxt,$msg."parFilterAliOff!") if (! defined $parFilterAliOff);
    return(0,$errTxt,$msg."parFilterAliPhd!") if (! defined $parFilterAliPhd);
    return(0,$errTxt,$msg."fileScreenLoc!")   if (! defined $fileScreenLoc);
    return(0,$errTxt,$msg."exeMview!")        if (! defined $exeMview);
    return(0,$errTxt,$msg."parMview!")        if (! defined $parMview);
				# ------------------------------
				# check existence of dir|file|exe
    $errTxt="err=402"; $msg="*** $sbr: no dir ="; # 
    foreach $dir ($dirWork,$dirData,$dirSwiss,
		  $envBlastMat,$envBlastDb,$envProdomBlastDb) {
	return(0,$errTxt,$msg."$dir!")        if (! -d $dir && ! -l $dir);}

    $errTxt="err=403"; $msg="*** $sbr: no file=";
    foreach $file ($filePredTmp,$maxDefaultG,$fileMaxMetr) {
	return(0,$errTxt,$msg."$file!")       if (! -e $file && ! -l $file); }

    $errTxt="err=404"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeCopf,$exeConvertSeq,$exeProsite,$exeBlast,$exeBlastFilter,
		  $exeMax,$exeHsspExtrHdr4pp,$exeHsspFilter,$exeHsspFilterFor,
		  $exeBlastRdbExtr4pp) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=405","*** $sbr: no seq =".$file{"seq"}."!")  
	if (! -e $file{"seq"} && ! -l $file{"seq"});

    $msgErrIntern=    $msgErr{"internal"};
    $msgErrConvert=   $msgErr{"align:convert"};
    $msgErrFasta=     $msgErr{"align:fasta"};
    $msgErrBlastp=    $msgErr{"align:blastp"};
    $msgErrMaxhom=    $msgErr{"align:maxhom"};
    $msgHere="";
    $fhoutLoc="FHOUT_modAlign";

				# --------------------------------------------------
				# extract expert options Maxhom
				#    from extrHdrOneLine:extrHdrExpertMaxhom:
				#    ',parMaxhom(ide=n go=n ge=n mat=MATRIX smax=n)'
				# --------------------------------------------------
    $optExpGo=       $parMaxGo;
    $optExpGe=       $parMaxGe;     
    $optExpIde=      $parMaxMinIde;
    $optExpSmax=     $parMaxSmax;
    $optExpMatSeq=   $fileMaxMetr; 
    $optExpMatSeqAll=$fileMaxMetrAll; 
    if ($optRun=~/parMaxhom/){
	if ($optRun=~/go=([0-9\.]+)/)          { $optExpGo=    $1;}
	if ($optRun=~/ge=([0-9\.]+)/)          { $optExpGe=    $1;}
	if ($optRun=~/smax=([0-9\.]+)/)        { $optExpSmax=  $1;}
	if ($optRun=~/ide=([0-9\.]+)/)         { $optExpIde=   $1;}
	if ($optRun=~/mat=([A-Za-z0-9\-\_]+)/) { 
	    $optExpMatSeq=$1;
	    $optExpMatSeq=~s/blossum/blosum/; # just security for typos
				# search all possible metrices
				#    will return the file matching the keyword
				#    from the list of $fileTopitsMetrSeqAll
	    ($Lok,$msg,$optExpMatSeq)=
		&getFileFromArray($optExpMatSeq,1,$optExpMatSeqAll);
	    $optExpMatSeq=$fileMaxMetr if (! $Lok || ! $optExpMatSeq); }
				# corrections
	$optExpGo=    $parMaxGo        if ($optExpGo    <=1 || $optExpGo    >= 100);
	$optExpGe=    $parMaxGe        if ($optExpGe    <=0 || $optExpGe    >= 100);
	$optExpSmax=  $parMaxSmax      if ($optExpSmax  <=0 || $optExpSmax  >= 100);
	$optExpIde=   $parMaxMinIde    if (                    $optExpIde   >  100);
	$optExpIde=   $parMaxExpMinIde if ($optExpIde   < $parMaxExpMinIde); 
    }				# end of expert options

				# ------------------------------
				# name output files/options
				# convert sequence
				# ------------------------------
    if ($optRun=~/fasta|blast|maxhom/){
	$file{"ali"}=           $dirWork.$fileJobId.".hssp";          push(@kwdRm,"ali");
	$file{"aliMax"}=        $dirWork.$fileJobId.".hsspMaxhom";    push(@kwdRm,"aliMax");
	$file{"aliFilIn"}=      $file{"aliMax"};                      push(@kwdRm,"aliFilIn");
	if (! defined $file{"maxDef"} || ! -e $file{"maxDef"}) {
	    $file{"maxDef"}=    $dirWork."maxhom_default_".$fileJobId;push(@kwdRm,"maxDef"); }
	foreach $kwd ("aliMissing","aliSelf"){
	    next if (defined $file{$kwd} && -e $file{$kwd});
	    $file{$kwd}=        $dirWork.$fileJobId.".".$kwd;         push(@kwdRm,$kwd);}
	$fileOut=$file{"ali"};
				# ------------------------------
				# local copy of default file
	if (! defined $file{"maxDef"} || ! -e $file{"maxDef"}){
	    ($Lok,$msg)=
		&maxhomMakeLocalDefault($maxDefaultG,$file{"maxDef"},$dirWork);
	    return(0,"err=415",$msgErrIntern."\n"."$msg"."\n"."$msgHere") 
		if (! $Lok);}

				# ------------------------------
	$Lok=			# security check: is FASTA?
	    &isFasta($file{"seq"});
	
				# ------------------------------
	if (! $Lok){		# not: convert_seq -> FASTA
	    $file{"seqFasta"}=$file{"seq"};
	    $LdoExpandLoc=0;
	    ($Lok,$msg)=
		&copfLocal($file{"seq"},$file{"aliSelf"},0,"fasta",$LdoExpandLoc,
			   $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# conversion failed!
	    return(0,"err=410",$msgErrConvert."\n".
		   "*** $sbr: fault in copf\n".$msgHere."\n".$msg."\n") if (! $Lok);
				# conversion appears ok: add command that did run
	    $msgHere.="\n".$msg."\n" if (! $Ldebug);
				# input MUST be fasta so move it!
	    $Lok=unlink($file{"seq"});
	    return(0,"err=411",$msgErrIntern."\n".
		   "*** $sbr no deletion of ".$file{"seq"}."\n"."$msgHere") if (! $Lok);
	    ($Lok,$msg)=&sysMvfile($file{"aliSelf"},$file{"seq"}," ");
	    return(0,"err=412",$msgErrIntern."\n"."*** $sbr: $msg"."\n"."$msgHere") if (! $Lok);
	}}
				# ------------------------------
				# input is alignment
    elsif ($optRun =~/filter/) {
    	$file{"aliFilIn"}=      $file{"ali"};                         push(@kwdRm,"aliFilIn"); }
    else {
    	$file{"aliFilIn"}=      $file{"ali"};                         push(@kwdRm,"aliFilIn"); }


				# --------------------------------------------------
				# generate FASTA formatted sequence in any case
				# --------------------------------------------------
				# get FASTA formatted sequence first
    if (! defined $file{"seqFasta"}){
	$file{"seqFasta"}=      $dirWork.$fileJobId.".f";             push(@kwdRm,"seqFasta");}
				# copy
    if (! -e $file{"seqFasta"} && &isFasta($file{"seq"})) {
	$cmd="\\cp ".$file{"seq"}." ".$file{"seqFasta"};
	($Lok,$msgSys)=&sysSystem("$cmd");}
				# run copf
    else {
	$LdoExpandLoc=0;

	($Lok,$msg)=
	    &copfLocal($file{"seq"},$file{"seqFasta"},0,"fasta",$LdoExpandLoc,
		       $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# conversion failed!
	return(0,"err=424",$msgErrConvert."\n".
	       "*** $sbr: fault in copf\n".$msgHere."\n".$msg."\n") if (! $Lok); }
    return(0,"err=425",$msgErrConvert."\n".
	   "*** $sbr: never managed to write fasta sequence\n".$msgHere."\n") 
	if (! -e $file{"seqFasta"}); 

				# --------------------------------------------------
                                # PROSITE search before alignment
				# --------------------------------------------------
    if ($optRun =~/prosite/ ){
	$file{"seqGCG"}=        $dirWork.$fileJobId.".seqGCG";        push(@kwdRm,"seqGCG");
	$file{"seqProsite"}=    $dirWork.$fileJobId.".prosite";       push(@kwdRm,"seqProsite");
	($Lok,$err,$msg)=
	    &runProsite($file{"seq"},$file{"seqGCG"},$file{"seqProsite"},$filePrositeData,
			$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$optOut,
			$exeCopf,$exeConvertSeq,$exeProsite,
			$nice,$fileJobId,$fhErrSbr,$dirWork,$Ldebug,$fhTrace);
				# note: may return Lok=2 for non fatal errors!
	return(0,$err,$msgErrIntern."\n".$msgHere."\n".$msg)
	    if (! $Lok); 
	$msgHere.=$msg; 
	print "--- $sbr ok: $msg\n" if ($Ldebug); }

				# --------------------------------------------------
                                # SEG low-complexity marking before alignment
				# --------------------------------------------------
    $lenLow=0;
    if ($optRun =~/segnorm/ ){
	$file{"segNorm"}=       $dirWork.$fileJobId.".segNorm";       push(@kwdRm,"segNorm");
	($Lok,$err,$msg,$lenLowTmp,$lenAllTmp)=
	    &runSegnorm($file{"seqFasta"},$file{"segNorm"},
			$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$optOut,
			$exeSeg,$parSegNorm,$parSegNormMin,
			$exeCopf,$exeConvertSeq,$dirWork,$fileJobId,
			$nice,$fhErrSbr,$Ldebug);
				# note: may return Lok=2 for non fatal errors!
				#       Lok=3 if no low-complexity found
	print $fhTrace "*** $sbr error in segnorm: $msg ($err)\n" if (! $Lok); 
	if ($Lok==1) { $msgHere.=$msg;
		       print "--- $sbr ok: $msg\n" if ($Ldebug); 
		       $lenLow=$lenLowTmp;
		       $lenAll=$lenAllTmp;}}

				# low complexity regions found -> take as input for BLAST
    $file{"seqBlast"}=          $dirWork.$fileJobId.".seq4blast";     push(@kwdRm,"seqBlast");
				# watch it if none left!!!
    if    ($lenLow && ( ($lenAll - $lenLow) > 20)) {
	$cmd="\\cp ".$file{"segNorm"}." ".$file{"seqBlast"};
	($Lok,$msgSys)=&sysSystem("$cmd"); }
    elsif ($optRun=~/blast/) {
	$cmd="\\cp ".$file{"seq"}." ".$file{"seqBlast"};
	($Lok,$msgSys)=&sysSystem("$cmd"); }
    
				# --------------------------------------------------
                                # pre-filter to speed up MaxHom (FASTA, BLAST)
				# --------------------------------------------------
				# ------------------------------
    if ($optRun =~/fasta/){	# FASTA
	$file{"aliFasta"}=      $dirWork.$fileJobId.".aliFasta";      push(@kwdRm,"aliFasta");
				# NOTE: MaxHom wants extension 'list' to recognise
				#       that comparison is against a list!!
				# NOTE : maxhom recognises 'list' to read a list !!!!
	$file{"aliFastaFil"}=   $dirWork.$fileJobId.".aliFil_list";   push(@kwdRm,"aliFastaFil");
	$msgHere.="\n--- $sbr \t run FASTA ($dirData,$exeFasta,$exeFastaFilter,$envFastaLibs,".
	    "$parFastaNhits,$parFastaThresh,$parFastaScore,$parFastaSort,".
		$file{"seq"}.",".$file{"aliFasta"}.",".$file{"aliFastaFil"}.",$fhErrSbr)\n";
	($Lok,$msg)=
	    &fastaRun($nice,$dirData,$envPP{"exeFasta"},$envPP{"exeFastaFilter"},
		      $envPP{"envFastaLibs"},$envPP{"parFastaNhits"},
		      $envPP{"parFastaThresh"},$envPP{"parFastaScore"},$envPP{"parFastaSort"},
		      $file{"seq"},$file{"aliFasta"},$file{"aliFastaFil"},$fhErrSbr);
	
	return(0,"err=413",$msgErrFasta."\n"."*** $sbr: $msg"."\n"."$msgHere") 
	    if (! $Lok || ! -e $file{"aliFastaFil"});}


				# -----------------------------
				# run Psi-blast first
    if ($optRun =~ /blastpsi/) {
	$file{"aliBlastPsi"}= $dirWork.$fileJobId.".blastPsiAli";
	push(@kwdRm,"blastPsiAli");
	$file{"blastPsiRdb"} = $dirWork.$fileJobId.".blastPsiRdb";
	push(@kwdRm,"blastPsiRdb");
	$file{"blastPsiCheck"} = $dirWork.$fileJobId.".blastPsiCheck";
	push(@kwdRm,"blastPsiCheck");
	$file{"blastPsiOutTmp"} = $dirWork.$fileJobId.".blastPsiOutTmp";
	push(@kwdRm,"blastPsiOutTmp");
	$file{"blastPsiMat"}=$dirWork.$fileJobId.".blastPsiMat";
	push(@kwdRm,"blastPsiMat");
	$file{"safBlastPsi"}= $dirWork.$fileJobId.".safBlastPsi";
	push(@kwdRm,"safBlastPsi");
	$file{"blastPsiTrace"}= $dirWork.$fileJobId.".blastPsiTrace";
	push(@kwdRm,"blastPsiTrace");

	$msgHere.= "\n--- $sbr \t run PSI-BLAST ($exeBlastPsi,". 
	    "$exeBlast2Saf,$envBlastPsiDb,$argBlastPsi,$argBlastBig,$blastTile,$parBlastPsiDb,". 
		"$blastFilThre,$blastMaxAli,".$file{"seqBlast"}.",".$file{"aliBlastPsi"}.
		    ",".$file{"blastPsiRdb"}.",".$file{"blastPsiCheck"}.",".$file{"safBlastPsi"}.
			",".$file{"blastPsiOutTmp"}.
			    ",".$file{"blastPsiMat"}.",".$file{"blastPsiTrace"}.",$fhErrSbr)\n";
	
	($Lok,$msg) = 
	    &blastpsiRun($nice,$exeBlastPsi,$exeBlast2Saf,
			 $envBlastPsiDb,$argBlastPsi,$argBlastBig,$blastTile,$parBlastPsiDb,
			 $parBlastPsiDbBig,$blastFilThre,$blastMaxAli,
			 $file{"seqBlast"},$file{"seq"},$file{"aliBlastPsi"},
			 $file{"blastPsiRdb"},$file{"blastPsiCheck"},$file{"blastPsiOutTmp"},
			 $file{"safBlastPsi"},
			 $file{"blastPsiMat"},$file{"blastPsiTrace"},$fhErrSbr);
	
	print $fhOutSbr "\n--- psi blast returned:\n".$msg."\n";

				# single out psi-blast error,
				# not fatal, but want to send mail to admin
				# yy temporary

	($LokBlastPsi, $msgBlastPsi) = ($Lok, $msg);
	if    ($Lok==2 && $msg=~/none/) {
	    $nAliBlastPsi = 0;
	    unlink($file{"aliBlastPsi"}) if (-e $file{"aliBlastPsi"});
	    $cmd="echo ".$file{"seqBlast"}." > ".$file{"aliBlastPsi"};
	    ($Lok,$tmp)=&sysSystem("$cmd"); 
	}
				# --------------------------------------------
				# PSI-Blast ok, convert saf -> hssp for PHD and prof
	if ( $Lok ) {
	    $file{"hsspBlastPsi"} = $dirWork.$fileJobId.".hsspBlastPsi";
	    push(@kwdRm,"hsspBlastPsi");
	    $file{"hsspPsiFil"} = $dirWork.$fileJobId.".hsspPsiFil";
	    push(@kwdRm,"hsspPsiFil");
	    ($Lok,$msg)=
		&copfLocal($file{"safBlastPsi"},$file{"hsspBlastPsi"},"saf","hssp",
			   0,$exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,
			   $fhErrSbr);
	    ($LokBlastPsi,$msgBlastPsi)=($Lok,$msg) if (! $Lok);
	    
				# ---------------------------------------------
				# filter the hssp from PsiBlast
	    $cmdLoc = "$exeHsspFilter red=80 ".$file{"hsspBlastPsi"}.
		" fileOut=".$file{"hsspPsiFil"};

	    ($Lok,$msg)=
		&sysSystem($cmdLoc);
	    ($LokBlastPsi,$msgBlastPsi)=($Lok,$msg) if (! $Lok);
	} 
    }

				# ------------------------------
    if ($optRun =~/\bblastp\b/){ # BLASTP
	$file{"aliBlastp"}=     $dirWork.$fileJobId.".aliBlastp";     push(@kwdRm,"aliBlastp");
				# NOTE : maxhom recognises 'list' to read a list !!!!
	$file{"aliBlastpFil"}=  $dirWork.$fileJobId.".aliFil_list";   push(@kwdRm,"aliBlastpFil");
	$file{"aliBlastHtml"}=  $dirWork.$fileJobId.".blastHtml";     push(@kwdRm,"aliBlastHtml");
	$msgHere.="\n--- $sbr \t run BLASTP ($dirData,$dirSwiss,$exeBlast,$exeBlastFilter,".
	    "$envBlastMat,$envBlastDb,$parBlastNhits,$parBlastDb,".
		$file{"seqBlast"}.",".$file{"aliBlastp"}.",".$file{"aliBlastpFil"}.",$fhErrSbr)\n";
	($Lok,$msg)=
	    &blastpRun($nice,$dirData,$dirSwiss,$exeBlast,$exeBlastFilter,
		       $envBlastMat,$envBlastDb,$parBlastNhits,$parBlastDb,
		       $file{"seqBlast"},$file{"aliBlastp"},$file{"aliBlastpFil"},$fhErrSbr);
				# none found
	if    ($Lok==2 && $msg=~/none/) {
	    unlink($file{"aliBlastpFil"}) if (-e $file{"aliBlastpFil"});
	    $cmd="echo ".$file{"seqBlast"}." > ".$file{"aliBlastpFil"};
	    ($Lok,$tmp)=&sysSystem("$cmd"); }
	elsif (! $Lok || ! -e $file{"aliBlastpFil"}) {
	    return(0,"err=414",$msgErrBlastp."\n"."*** $sbr: $msg"."\n"."$msgHere");
	}
    }



				# --------------------------------------------------
				# ProDom
				# --------------------------------------------------
    if   ($optRun =~/prodom/) {
	$file{"prodomTmp"}=     $dirWork.$fileJobId.".prodomTmp";     push(@kwdRm,"prodomTmp");
	$file{"prodomHtml"}=    $dirWork.$fileJobId.".prodomHtml";    push(@kwdRm,"prodomHtml");
	$file{"prodom"}=        $dirWork.$fileJobId.".prodom";        push(@kwdRm,"prodom");
	$fhoutTmp=$fhErrSbr;
	$fhoutTmp=$fhOutSbr     if ($Ldebug);
	($Lok,$err,$msg)=
	    &runProdom($file{"seqFasta"},$file{"prodomTmp"},$file{"prodom"},$file{"prodomHtml"},
		       $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$optOut,
		       $exeBlast,$envProdomBlastDb,$envBlastMat,
		       $parProdomBlastDb,$parProdomBlastN,$parProdomBlastE,$parProdomBlastP,
		       $exeMview,$parMview,$nice,$fhoutTmp,$fhTrace);
				# note: may return Lok=2 for non fatal errors!
	return(0,$err,$msgErrIntern."\n".$msgHere."\n".$msg)
	    if (! $Lok); 
	$msgHere.=$msg; 
	$Lok_prodom=1; 
				# note may return val=2 for 'empty header', val=3 for 'none found'
	$Lok_prodom=0           if ($Lok > 1);
	print "--- $sbr ok: $msg\n" if ($Ldebug); }

				# --------------------------------------------------
				# now run MaxHom
				# --------------------------------------------------
				# ------------------------------
    if ($optRun=~/maxhom/){	# local copy of default file
	$file{"ali"}=$file{"aliMax"};
	if (! defined $file{"maxDef"} || ! -e $file{"maxDef"}){
	    ($Lok,$msg)=
		&maxhomMakeLocalDefault($maxDefaultG,$file{"maxDef"},$dirWork);
	    return(0,"err=415",$msgErrIntern."\n"."$msg"."\n"."$msgHere") if (! $Lok);
	}
				# ------------------------------
	$parMaxThreshMod=	# get the arguments for the MAXHOM csh
	    &maxhomGetThresh4PP($optExpIde);
	$fileStripOutMod=   "NO"; # 
	if    ($optRun =~/fasta/){
	    $fileAliList=$file{"aliFastaFil"};}
	elsif ($optRun =~/blastp/){
	    $fileAliList=$file{"aliBlastpFil"};}
				# ------------------------------
				# files automatically generated by MAXHOM
	$tmp=$fileJobId;$tmp=~tr/[a-z]/[A-Z]/;
	$file{"MAXHOM.LOG"}=$dirWork."MAXHOM.LOG_".$tmp;              push(@kwdRm,"MAXHOM.LOG");
	$file{"MAXHOM_ALI"}=$dirWork."MAXHOM_ALI.".$tmp;              push(@kwdRm,"MAXHOM_ALI");
	$msgHere.="\n--- $sbr \t run maxhomRunLoop($date,$nice,$exeMax,".
	    $file{"maxDef"}.",$fileJobId,".$file{"seq"}.",$fileAliList,".
		$file{"aliMax"}.",$optExpMatSeq,$dirPdb,$Lprof,$parMaxSmin,".
		    "$optExpSmax,$optExpGo,$optExpGe,$parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,".
		    "$parMaxNali,$parMaxThreshMod,$parMaxSort,$parMaxProfOut,$fileStripOutMod,".
			$file{"aliMissing"}.",$parMinLaliPdb,parMaxTimeOut,$fhErrSbr)\n";

				# ------------------------------
				# now run it
				# note: if pdbidFound = 0, then none found!
	($Lok,$pdbidFound,$LisSelf)=
	    &maxhomRunLoop($date,$nice,$exeMax,$file{"maxDef"},$fileJobId,$dirWork,
			   $file{"seq"},$fileAliList,$file{"aliMax"},$optExpMatSeq,
			   $dirPdb,$Lprof,$parMaxSmin,$optExpSmax,$optExpGo,$optExpGe,
			   $parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,$parMaxNali,
			   $parMaxThreshMod,$parMaxSort,$parMaxProfOut,$fileStripOutMod,
			   $file{"aliMissing"},$parMinLaliPdb,$parMaxTimeOut,$fhErrSbr,
			   $fileScreenLoc);
	
	if ($Lok){
	    $msgHere.="\n--- Maxhom ended fine\n";}
	else {
	    $msgHere.="\n--- MAXHOM problem\n".$msgErrMaxhom."\n".$pdbidFound."\n";
	}}

				# --------------------------------------------------
				# filter ali (HSSP) or input alignment for sending!
				#    note: has been secured as file{"aliFilIn"}
				#          see above
				#    NOTE: NOT for input = MSF,SAF 
				#          as problem with similarity not resolved!!
				# --------------------------------------------------
    if ($optRun =~/filterAli/ && $optRun !~ /noFilterAli/) {
	$file{"aliFilOut"}=     $dirWork.$fileJobId.".hsspFilter";    push(@kwdRm,"aliFilOut");
				# --------------------------------------------------
				# extract expert options filter ali
				#    from extrHdrOneLine:extrHdrExpertFilter:
				#    ',parFilter(thresh=-5 threshSgi=5 extr=5)'
				# WARNING: changes default of parFilterAli!!!
				# --------------------------------------------------
	if ($optRun=~ /parFilterAli\(([^\)]+)\)/) {
	    $parFilterAliOff=$1;
	    $parFilterAliOff=~s/^\s*|\s*$//g; # purge leading blanks
	    print $fhOutSbr "-*- WARN $sbr changes option parFilterAliOff to:$parFilterAliOff\n"; }
				# change br 1999-01: NO threshSgi!!
	if ($parFilterAliOff=~/threshSgi/ && $optSeq=~/^(saf|msf)/) {
	    $parFilterAliOff=~s/threshSgi=[\d\-\.]+//g;
	    $parFilterAliOff=~s/^\s*|\s*$//g; # purge leading blanks
	    print $fhOutSbr "-*- WARN $sbr HACK_REMOVE sgi from parFilterAliOff:$parFilterAliOff\n"; }
				# run the filter
	($Lok,$msg)=
	    &filterLocal($file{"aliFilIn"},$file{"aliFilOut"},$parFilterAliOff,
			 $exeHsspFilter,$exeHsspFilterFor,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# ERROR -> not fatal, simply take original!
	if (! $Lok) {
	    $file{"aliFilOut"}= $file{"ali"};
	    $msgHere.=
		"*** ERROR $sbr filter failed to produce file (aliFilOut)=".$file{"aliFilOut"}."\n".
		    "*** did run \t $cmd\n".
			$msg."\n"; }}
    else {			# just rename
	$file{"aliFilOut"}=     $file{"aliFilIn"}; }

				# ------------------------------
				# hack change br 1999-01
    if (! defined $file {"aliFilOut"} || ! -e $file{"aliFilOut"}) {
	$file{"aliFilOut"}=$file{"aliMax"};}
    if (! defined $file {"aliFilOut"} || ! -e $file{"aliFilOut"}) {
	$file{"aliFilOut"}=$file{"ali"};}
	
				# --------------------------------------------------
				# filter HSSP or input alignment for PHD!
				#    NOTE: NOT for input = MSF,SAF 
				#          as problem with similarity not resolved!!
				# --------------------------------------------------
    if ($optRun =~/filterPhd/ && $optRun !~/noFilterPhd/) {
	$file{"aliFil4phd"}=    $dirWork.$fileJobId.".hsspMax4phd";
	push (@kwdRm,"aliFil4phd");

				# --------------------------------------------------
				# extract expert options filter phd
				#    from extrHdrOneLine:extrHdrExpertFilter:
				#    ',parFilter(thresh=-5 threshSgi=5 extr=5)'
				# WARNING: changes default of parFilterAli!!!
				# --------------------------------------------------
	if ($optRun=~ /parFilterPhd\(([^\)]+)\)/) {
	    $parFilterAliPhd=$1;
	    $parFilterAliPhd=~s/^\s*|\s*$//g; # purge leading blanks
	    print $fhOutSbr "-*- WARN $sbr changes option parFilterAliPhd to:$parFilterAliPhd\n";}
				# change br 1999-01: NO threshSgi!!
	if ($parFilterAliPhd=~/threshSgi/ && $optSeq=~/^(saf|msf)/) {
	    $parFilterAliPhd=~s/threshSgi=[\d\-\.]+//g;
	    $parFilterAliPhd=~s/^\s*|\s*$//g; # purge leading blanks
	    print $fhOutSbr "-*- WARN $sbr HACK_REMOVE sgi from parFilterAliPhd:$parFilterAliPhd\n"; }
				# run the filter
	($Lok,$msg)=
	    &filterLocal($file{"aliFilIn"},$file{"aliFil4phd"},$parFilterAliPhd,
			 $exeHsspFilter,$exeHsspFilterFor,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# ERROR -> not fatal, simply take original!
	if (! $Lok) {
#	    $file{"aliFil4phd"}= $file{"aliFilIn"};
	    $msgHere.=
		"*** ERROR $sbr filter failed to produce file(aliFil4phd)=".$file{"aliFil4phd"}.", errMsg=\n".
		    $msg."\n"; 
	    return(0,"err=423",$msgErrIntern."\n".$msgHere);
	}
    } else {			# just rename
	$file{"aliFil4phd"}=      $file{"aliFilIn"}; }
	
				# -----------------------------------------------
				# compare nAli from filtered maxhom and psi-blast
				# take the one with more nAli as the input for phd
    
				# psi-blast goes wrong, take maxhom directly    
    if ( $optRun !~ /blastpsi/ || ! $LokBlastPsi || ! -e $file{"hsspPsiFil"} ) {
	$file{"aliPhdIn"} = $file{"aliFil4phd"};
    } else {
	($Lok, %rdHeader)=	# get nAli from maxhom output
	    &hsspRdHeader($file{"aliFil4phd"},"NALIGN");
	if ( $Lok ) {
	    $nAliMax = $rdHeader{"NALIGN"};
	} else {
	    $msgHere="failed to get \"NALIGN\" from ".$file{"aliFil4phd"}."\n";
	    return (0, "err=4xx ".$msgErrIntern."\n".$msgHere);
	}			# 
	
	($Lok, %rdHeader)=	# get nAli from psi-blast output
	    &hsspRdHeader($file{"hsspPsiFil"},"NALIGN") if ( ! defined $nAliBlastPsi);
	if ( defined $nAliBlastPsi or $Lok ) {
	    $nAliBlastPsi = $rdHeader{"NALIGN"} if ( ! defined $nAliBlastPsi );
	    print "nAliMax=$nAliMax,nAliBlastPsi=$nAliBlastPsi\n" if ( $Ldebug );
	    if ( $nAliMax > $nAliBlastPsi ) {
		$nAli = $nAliMax;
		$file{"aliPhdIn"}=$file{"aliFil4phd"};
		print "take maxhom hssp as PHD input\n" if ( $Ldebug );
	    } else {
		$nAli = $nAliBlastPsi;
		$file{"aliPhdIn"}=$file{"hsspPsiFil"};
		print "take PSI-BLAST hssp as PHD input\n" if ( $Ldebug );
	    }
	} else {		# if fail, just take maxhom
	    $file{"aliPhdIn"}=$file{"aliFil4phd"};
	    print "take maxhom hssp as PHD input\n" if ( $Ldebug );
	}
    }

				# --------------------------------------------------
				# append files
				# --------------------------------------------------
    if ($origin =~ /^mail|^html|^testPP/i){
	$#tmpAppend=0;
				# ------------------------------
				# (1) check whether PDB found
	if ($optRun=~/maxhom/ && length($pdbidFound)>=4 && $optRun !~ /nors/ ){
	    ($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppIlyaPdb"});
	    return(0,"err=418",$msgErrIntern."\n".
		   "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);
	    $txt ="--- ------------------------------------------------------------\n";
	    $txt.="--- 3D homologue: the known structure that appeared to have sig-\n";
	    $txt.="--- 3D homologue: nificant sequence identity to your protein is:\n";
	    $txt.="--- 3D homologue: $pdbidFound.\n";
	    $txt.="--- 3D homologue: Note: we do  NOT  check whether the similarity\n";
	    $txt.="--- 3D homologue:       is in the region for which structure has\n";
	    $txt.="--- 3D homologue:       been determined.  Thus, please verify!  \n";
	    $txt.="--- ------------------------------------------------------------\n";
	    open($fhoutLoc,">>".$filePredTmp);
	    print $fhoutLoc $txt;
	    close($fhoutLoc);
	    $txtPdb=$txt; }
				# ------------------------------
				# (2) warning no homologue
	elsif ($optRun=~/maxhom/ && $LisSelf){
	    print $fhErrSbr "***  $sbrName no append file fileAppWarnSingSeq'".
		$envPP{"fileAppWarnSingSeq"}."'\n"
		if (! -e $envPP{"fileAppWarnSingSeq"} && $Ldebug);
	    push(@tmpAppend,$envPP{"fileAppWarnSingSeq"}) if (-e $envPP{"fileAppWarnSingSeq"});}
				# ------------------------------
				# (3) no ali to return -> leave
	if ($optOut=~/ret ali no/){
	    ($Lok,$msg)=&sysCatfile("nonice",$Ldebug,
				    $filePredTmp,$envPP{"fileAppRetNoali"});
	    return(0,"err=419",$msgErrIntern."\n"."$msg,\n"."$msgHere") if (! $Lok);
	    return(1,"ok","warn: no ali appended from $sbr was that ok?");}
				# ------------------------------
				# (4) grep database version
				# br 99.08 changed to get from internal parameters (envPP.pm)
#  	if ($optRun=~/maxhom/){
#  	    $command="grep '^SEQBASE' ".$file{"ali"}." ";
#  	    $txt=    `$command`; # system call (no control)
#  	    $txt="--- Database used for sequence comparison:\n--- ".$txt;
#  	    $command="echo '$txt'";
#  	    ($Lok,$msgSys)=&sysSystem("$command >> $filePredTmp");
#  	    $txtSwiss=$txt;}
	if ($optRun=~/maxhom|\bblast\b/){
	    if ($optRun=~/db=(\w+)/){
		$tmp=$1;
		$db_version="Error in determining database version!";
		$db_version=
		    $envPP{"version_".$tmp} if (defined $envPP{"version_".$tmp} &&
						$envPP{"version_".$tmp}); }
	    else {
		$db_version=$envPP{"version_swiss"};}
	    $tmp=$db_version;
	    $db_version= "--- \n";
	    $db_version.="--- Version of database searched for alignment:\n";
	    $db_version.="--- $tmp\n";
	    $db_version.="--- \n";
	    $file{"dbVersion"}=$dirWork.$fileJobId.".version_db"; push(@kwdRm,"version_db");
	    $command="echo '$db_version' >> ".$file{"dbVersion"};
	    $msgHere.="\n--- $sbr system '$command'\n";
	    ($Lok,$msgSys)=&sysSystem("$command");}
				# ------------------------------
				# (5) ret blastp ?
				# actually return PSI-blast 
	if ( ($optRun !~ /blastpsi/) && ($optOut =~ /ret ali blastp/) 
	    && (-e $file{"aliBlastp"})) {
	    push(@tmpAppend,$envPP{"fileAppRetBlastp"});
	    push(@tmpAppend,$file{"dbVersion"}) if (-e $file{"dbVersion"});
	    push(@tmpAppend,$file{"aliBlastp"},$envPP{"fileAppLine"});
				# --------------------
				# append HTML output
	    if ($optOut=~/ret html/) {
		($Lok,$err,$msg)=
		    &htmlBlast($file{"aliBlastp"},$exeMview,$parMview,$optOut,
			       $file{"aliBlastHtml"},$fileHtmlTmp,$fileHtmlToc,0,$fhErrSbr);
		if (! $Lok) { $msg="*** err=2239 ($sbr: htmlBlast failed on kwd=blast)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2239",$msg); } } }
	
	if (($optRun =~ /blastpsi/) && (-e $file{"aliBlastPsi"})
	    && (-e $file{"blastPsiRdb"})) {
	    $file{"blastPsiHdr"} = $dirWork.$fileJobId.".blastPsiHdr";       
	    push(@kwdRm,"blastPsiHdr");
				# ext prog blastPsi_rdb4pp.pl (reads blast RDB file)
	    $command="$exeBlastRdbExtr4pp ".$file{"blastPsiRdb"}." ".
		$file{"blastPsiHdr"}." ";
	    if ($job{"out"}=~/ret html/) { 
		$command .= " html ";
		$command .= " $urlSrs " if ( defined $urlSrs );
	    }
	   
	    $msgHere.="\n--- $sbr system '$command'\n";
	    ($Lok,$msgSys)=&sysSystem("$command");
	    return(0,"err=422",$msgErrIntern."\n*** could not extract RDB file for BLAST:".
		   $file{"blastPsiRdb"}."\n".$Lok."\n".$msgHere) 
		if (! -e $file{"blastPsiHdr"});
	    push(@tmpAppend,$envPP{"fileAppRetBlastPsi"});
	    push(@tmpAppend,$file{"dbVersion"}) if (-e $file{"dbVersion"});
	    push(@tmpAppend,$file{"blastPsiHdr"});
	    push(@tmpAppend,$file{"aliBlastPsi"}) if ($optOut =~ /ret ali blastp/); 
	    push(@tmpAppend, $envPP{"fileAppLine"}); 
				# --------------------
				# append HTML output
	    if ($optOut=~/ret html/) {
				# the header
		($Lok,$msg)=
		    &htmlBuild($file{"blastPsiHdr"},$fileHtmlTmp,$fileHtmlToc,1,"ali_psiBlast_head");
		if ($optOut =~ /ret ali blastp/) {
		    ($Lok,$err,$msg)=
			&htmlBlast($file{"aliBlastPsi"},$exeMview,$parMview,$optOut,
				   $file{"aliBlastHtml"},$fileHtmlTmp,$fileHtmlToc,
				   1,$fhErrSbr);
		    if (! $Lok) { 
			$msg=
			    "*** err=2239 ($sbr: htmlBlast failed on kwd=blast)\n".
				$msg."\n";
			print $fhTrace $msg;
			return(0,"err=2239",$msg);
		    }
		}
	    }
	}
	
    
				# ------------------------------
				# (6) ret prof
	if    ($optOut =~ /ret ali prof/){
	    push(@tmpAppend,$envPP{"fileAppHssp"});
	    push(@tmpAppend,$file{"dbVersion"}) if (-e $file{"dbVersion"});
	    push(@tmpAppend,$file{"aliFilOut"},$envPP{"fileAppLine"});
				# append HTML output
	    $file{"aliHtmlMviewIn"}=$file{"aliFilOut"}    if ($optOut=~/ret html/); }
	    
				# ------------------------------
				# (7) ret hssp without profile
	elsif ($optOut =~ /ret ali hssp/){
	    $file{"aliRet"}=    $dirWork.$fileJobId.".hsspRet";       push(@kwdRm,"aliRet");
	    ($Lok,$msg)=&hsspChopProf($file{"aliFilOut"},$file{"aliRet"});
	    return(0,"err=420",$msgErrIntern."\n*** could not chop profile for:".
		   $file{"aliFilOut"}."\n"."$msg,\n"."$msgHere") if (! $Lok);
	    push(@tmpAppend,$envPP{"fileAppHssp"});
	    push(@tmpAppend,$file{"dbVersion"}) if (-e $file{"dbVersion"});
	    push(@tmpAppend,$file{"aliRet"},$envPP{"fileAppLine"});
				# append HTML output
	    $file{"aliHtmlMviewIn"}=$file{"aliRet"}       if ($optOut=~/ret html/); }
				# ------------------------------
				# (8) ret msf (default)
	elsif ($optRun=~/maxhom/ && ! $LisSelf){
	    $file{"aliRet"}=    $dirWork.$fileJobId.".msfRet";        push(@kwdRm,"aliRet");
	    $file{"aliHdr"}=    $dirWork.$fileJobId.".hsspHdr";       push(@kwdRm,"aliHdr");
				# convert to MSF
	    $LdoExpandLoc=0;
	    $LdoExpandLoc=1     if ($optOut=~/ret ali full/);
	    ($Lok,$msg)=
		&copfLocal($file{"aliFilOut"},$file{"aliRet"},0,"msf",$LdoExpandLoc,
			   $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# conversion failed!
	    return(0,"err=421",$msgErrIntern."\n*** could not convert 2 msf:".
		   $file{"aliFilOut"}."\n".$msg."\n".$msgHere) if (! $Lok);

				# ext prog hssp_extr_header.pl (reads header of HSSP file)
	    $command="$exeHsspExtrHdr4pp ".$file{"aliFilOut"}." ".$file{"aliHdr"}." ";
	    if ($job{"out"}=~/ret html/) { 
		$command .= " html $urlSrs " if ( defined $urlSrs );
	    }
	   
	    $msgHere.="\n--- $sbr system '$command'\n";
	    ($Lok,$msgSys)=&sysSystem("$command");
	    return(0,"err=422",$msgErrIntern."\n*** could not extract HSSP header:".
		   $file{"aliFilOut"}."\n".$Lok."\n".$msgHere) if (! -e $file{"aliHdr"});
	    push(@tmpAppend,$envPP{"fileAppRetMsf"});
	    push(@tmpAppend,$file{"dbVersion"}) if (-e $file{"dbVersion"});
	    push(@tmpAppend,$file{"aliHdr"},$file{"aliRet"},$envPP{"fileAppLine"});
		 
				# --------------------
				# append HTML output
	    if ($optOut=~/ret html/) {
				# (1) header
		($Lok,$msg)=&htmlBuild($file{"aliHdr"},$fileHtmlTmp,$fileHtmlToc,1,"ali_maxhom_head");
		($Lok,$msg)=&htmlBuild($txtPdb,$fileHtmlTmp,$fileHtmlToc,1,"txt") 
		    if (defined $txtPdb && length($txtPdb)>1);
		($Lok,$msg)=&htmlBuild($db_version,$fileHtmlTmp,$fileHtmlToc,1,"txt") 
		    if (defined $db_version && length($db_version)>1);
				# (2) body
		$file{"aliHtmlMviewIn"}=$file{"aliRet"}; }}
				# ------------------------------
				# no ali to return, take PHD input
	else {			# 
				# append HTML output
	    $file{"aliHtmlMviewIn"}=$file{"ali"}       if ($optOut=~/ret html/); }
				# ------------------------------
				# (9) finally do append
	if ($#tmpAppend>0){
	    ($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
	    return(0,"err=423",$msgErrIntern."\n". # 
		   "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}

				# --------------------------------------------------
				# (10) ret HTML (append HTML output)
				# --------------------------------------------------
	if ($optOut=~/ret html/) {
	    return(0,"err=2240","*** err=2240 ($sbr: file{aliHtmlMviewIn} missing!)\n")
		if (! defined $file{"aliHtmlMviewIn"} || ! -e $file{"aliHtmlMviewIn"});

	    $file{"aliHtmlMview"}=$dirWork.$fileJobId.".htmlMview";   push(@kwdRm,"aliHtmlMview");
	    ($Lok,$err,$msg)=
		&htmlMaxhom($file{"aliHtmlMviewIn"},$file{"aliFilOut"},$exeMview,$parMview,$optOut,
			    $file{"aliHtmlMview"},$fileHtmlTmp,$fileHtmlToc,$fhErrSbr);

	    if (! $Lok) { $msg="*** err=2244 ($sbr: htmlBuild failed kwd=ali_maxhom_body)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2244",$msg); }}
	
    }				# end of append (not for manual)
				# --------------------------------------------------
    return(1,"ok","$sbr");
}				# end modAlign


#===============================================================================
sub modFin {
    local($origin,$date,$nice,$fileJobId,$fhErrSbr,$dirWork,
	  $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,$filePred,$password)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   modFin                      finishes off
#       in:                     GLOBAL
#       out:                    GLOBAL
#-------------------------------------------------------------------------------
    $sbr="modFin";
    $fhinLoc= "FHIN_". $sbr;
    $fhoutLoc="FHOUT_".$sbr;

    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    $errTxt="err=801"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."filePred!")        if (! defined $filePred);
    return(0,$errTxt,$msg."password!")        if (! defined $password);

    $errTxt="err=802"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);
    $errTxt="err=803"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $msgErrIntern=    $msgErr{"internal"};
    $msgHere="--- $sbr started\n";
				# --------------------------------------------------
				# return standard
    if ($origin=~/^mail|^html|^testPP/i){
	if ($optOut !~ /ret concise/ and  $optRun !~ /nors_only|chop_only/ ) { 
# return news unless concise output required
				# append <<< --------------------
	    ($Lok,$msg)=	# 
		&sysCatfile("nonice",$Ldebug,$filePredTmp,
			    $envPP{"fileAppLine"},$envPP{"fileNewsText"});}
	$Lok=1;
				# -----------------------------------
				# record the prediction if commercial
	&licence::record_predict($password)
	    if ($password) ;
				# ------------------------------
				# append HTML output (GLOBAL)
				# ------------------------------
	if ($optOut=~/ret html/ && -e $fileHtmlTmp){

	    if ( $optRun =~ /chop_only/ ) {
		($Lok,$msg)=
                    &htmlFin($fileJobId,$dirWork,
                             $filePredTmp,$fileHtmlTmp,$fileHtmlToc,
                             $envPP{"fileAppHtmlHeadChop"},$envPP{"fileAppEmpty"},
                             $envPP{"fileAppEmpty"},  $envPP{"fileAppEmpty"},
                             $fileHtmlFin);

	    } else {
		($Lok,$msg)=
		    &htmlFin($fileJobId,$dirWork,
			     $filePredTmp,$fileHtmlTmp,$fileHtmlToc,
			     $envPP{"fileAppHtmlHead"},$envPP{"fileAppHtmlFoot"},
			     $envPP{"fileAppHtmlQuote"},  $envPP{"fileAppHtmlStyles"},
			     $fileHtmlFin);
	    }
	    # failed -> will send the usual pred file!
	    if (! $Lok) {
		&ctrlAlarm("*** ERROR $sbr: failed in htmlFin:\n".
			   $msg."\n"); 
		$fileHtmlFin=0; }
	}			# end of appending HTML output


				# ------------------------------
				# hack: only casp
	$fileCasp=0;
	if ($optOut =~ /ret phd only casp/){
	    if (defined $file{"phdRetCasp"} && -e $file{"phdRetCasp"} ) {
		$fileCasp=$file{"phdRetCasp"};
		open($fhinLoc,$file{"phdRetCasp"})  || do { $fileCasp=0; } ; }
	    else {
		print "-*- WARN $sbr: IS 'ret only phd casp', but NO casp file (phdRetCasp)=".
		    $file{"phdRetCasp"}.", found!\n";}}
	if ($optOut =~ /ret prof only casp/){
	    if (defined $file{"profRetCasp"} && -e $file{"profRetCasp"} ) {
		$fileCasp=$file{"profRetCasp"};
		open($fhinLoc,$file{"profRetCasp"}) || do { $fileCasp=0; } ; }
	    else {
		print "-*- WARN $sbr: IS 'ret only prof casp', but NO casp file (profRetCasp)=".
		    $file{"profRetCasp"}.", found!\n";}
	}
	if ($fileCasp){
	    open($fhinLoc, $fileCasp);
	    open($fhoutLoc,">".$filePredTmp);
	    print $fhoutLoc
		"PPhdr from ".$User_name,"\n",
		"PPhdr resp "."MAIL","\n",
		"PPhdr orig ".$Origin,"\n",
		"PPhdr want "."unk","\n";
	    while(<$fhinLoc>){
		print $fhoutLoc $_;
	    }
	    close($fhinLoc);
	    close($fhoutLoc);
	}
    }				# end of mode: server

				# --------------------------------------------------
				# finally clean up the shit
				#    and append to log file
    ($Lok,$txt)=
	&ctrlCleanUp(0,0,"ok");	# no error, no input error, everything nice and fine!
    return($Lok,$txt,$msgHere);
}				# end of modFin


#===============================================================================
sub runAsp {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,
	  $optOut,$exeAsp,$parAspWs,$parAspZ,$parAspMin) = @_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$arg,$parAspExp,@tmpAppend,$txt,$command);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runASP                    : ASP
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"phdPred"}  , output from PHD
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runAsp";
    $errTxt="err=640"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeAsp")           if (! defined $exeAsp);
    return(0,$errTxt,$msg."parAspWs")         if (! defined $parAspWs);
    return(0,$errTxt,$msg."parAspZ")          if (! defined $parAspZ);
    return(0,$errTxt,$msg."parAspMin")        if (! defined $parAspMin);

    $errTxt="err=641"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=642"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=643"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeAsp) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=644","*** $sbr: no PHD output =".$file{"phdPred"}."!")   
	if (! -e $file{"phdPred"} && ! -l $file{"phdPred"});

    $msgErrIntern=    $msgErr{"internal"};
    $msgHere="";

				# --------------------------------------------------
                                # ASP program
				# --------------------------------------------------
    if ($optRun =~/asp/) {
	$file{"asp"}=        $dirWork.$fileJobId.".asp";   
	$file{"errAsp"}=     $dirWork.$fileJobId.".errASP"; 
	push(@kwdRm,"asp","errASP");

				# extract expert options
	if ( $optRun =~ /parAsp\(([^\(]+)\)/ ) {
	    $parAspExp = $1;
	    if ( $parAspExp =~ /ws\=([0-9]+)/ ) {
		$parAspWs = $1;
	    }
	    if ($parAspExp =~ /z\=([0-9\.\-]+)/ ) {
		$parAspZ = $1;
	    }
	    if ($parAspExp =~ /min\=([0-9\.]+)/ ) {
		$parAspMin = $1;
	    }
	}
				# command line arguments
	$arg = "";
	$arg .= " -ws ".$parAspWs;
	$arg .= " -z ".$parAspZ;
	$arg .= " -min ".$parAspMin;
	$arg .= " -in ".$file{"phdPred"};
	$arg .= " -out ".$file{"asp"};
	$arg .= " -err ".$file{"errAsp"};

	$command = "$nice $exeAsp $arg ";
	$msgHere="--- $sbr system '$command'";
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=645","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	    if (! $Lok || ! -e $file{"asp"}); # || -s $file{"errAsp"});

				# 
	$#tmpAppend=0;	  
	push(@tmpAppend,$envPP{"fileAppAsp"},
		 $file{"asp"},$envPP{"fileAppLine"});
	    
	    # ------------------------------
	    # append HTML output
	    # ------------------------------
	if ($optOut=~/ret html/ && -e $file{"asp"}){ 
	    # append file
	    ($Lok,$msg)=&htmlBuild($file{"asp"},$fileHtmlTmp,$fileHtmlToc,1,"asp");
	    if (! $Lok) { 
		$msg="*** err=2277 ($sbr: htmlBuild failed on kwd=asp)\n".$msg."\n";
		print $fhTrace $msg;
		return(0,"err=2277",$msg); }
	}
    
	
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=646",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }
    
    return(1,"ok","$sbr");
}			# end runAsp



#===============================================================================
sub runCafaspThreader {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeThreader)=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,@tmpAppend,$txt,$command);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runCafaspThreader         : Dudek's threader for Cafasp
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runCafaspThreader";
    $errTxt="err=501"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeThreader!")     if (! defined $exeThreader);

    $errTxt="err=502"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=503"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=504"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeThreader) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=505","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

#    $msgErrIntern=    $msgErr{"internal"};
#    $msgErrThreader=  $msgErr{"predMis:cafaspThreader"};
#    $msgErrCoils=     $msgErr{"predMis:"};
#    $msgErr=    $msgErr{":"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/cafaspThreader//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/cafaspThreader//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/cafaspThreader//g;}
    if (0){			# ******************************
				# commented out 9-4-98
				# now store the guide sequence
	$file{"seqTmp"}=    $dirWork. $fileJobId.  ".fastaTmp";
	$file{"seqTmp"}=    $fileJobId.  ".f";
	$file{"seqFasta"}=  $dirWork. $fileJobId.  ".fastaGuide";
	push(@kwdRm,"seqTmp","seqFasta");
	($Lok,$msg)=	# call FORTRAN shit to convert to FASTA
	    &convSeq2fasta($exeConvertSeq,$file{"seq"},$file{"seqTmp"},$fhErrSbr);
	return(0,"err=510",$msgErrConvert."\n".$msg."\n".
	       "*** file{seqTmp}=".$file{"seqTmp"}."\n") if (! $Lok);
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqTmp"});
	return(0,"err=511",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seqFasta"},$id,$seq);
	return(0,"err=512",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=513",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seqFasta"}."' written \n") if (! -e $file{"seqFasta"});}
				# --------------------------------------------------
                                # Threader program
				# --------------------------------------------------
    if ($optRun =~/cafaspThreader/) {
	$file{"threader"}=        $dirWork.$fileJobId.".AL";   
	push(@kwdRm,"AL");
	
	$command="$nice $exeThreader ".
	    $file{"seqFasta"}." ".$file{"threader"}.' '. $Ldebug;
	$msgHere="--- $sbr system '$command'";
				# --------------------------------------------------
				# do run CAFASP threader
				# --------------------------------------------------
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=720","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	    if (! $Lok || ! -e $file{"threader"} || ! -s $file{"threader"});

	
	$#tmpAppend=0;	  
	push(@tmpAppend,$envPP{"fileAppThreader"},
		 $file{"threader"},$envPP{"fileAppLine"});

	
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){	# 
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=570",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }
		
    return(1,"ok","$sbr");
}				# end runCafaspThreader


#===============================================================================
sub runCoils {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeConvertSeq,$exeCoils,$parCoilsMin,$parCoilsMetr,
	  $parCoilsWeight,$fileScreenCoilsLoc)=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$parMaxThreshMod,$fileStripOutMod,
	  $fileAliList,$pdbidFound,@tmpAppend,$txt,$command);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runCoils                  : coils
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runCoils";
    $errTxt="err=501"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);

    return(0,$errTxt,$msg."exeCoils!")        if (! defined $exeCoils);
    return(0,$errTxt,$msg."parCoilsMin!")     if (! defined $parCoilsMin);
    return(0,$errTxt,$msg."parCoilsMetr!")    if (! defined $parCoilsMetr);
    return(0,$errTxt,$msg."parCoilsWeight!")  if (! defined $parCoilsWeight);
#    return(0,$errTxt,$msg."parCoilsOptOut!")  if (! defined $parCoilsOptOut);
    return(0,$errTxt,$msg."fileScreenCoils!") if (! defined $fileScreenCoilsLoc);

    $errTxt="err=502"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=503"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=504"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeConvertSeq,$exeCoils) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=505","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

    $msgErrIntern=    $msgErr{"internal"};
    $msgErrConvert=   $msgErr{"predMis:convert"};
    $msgErrCoils=     $msgErr{"predMis:coils"};
#    $msgErrCoils=     $msgErr{"predMis:"};
#    $msgErr=    $msgErr{":"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/coils,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/coils,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/coils,//g;}

    if (0){			# ******************************
				# commented out 9-4-98
				# now store the guide sequence
	$file{"seqTmp"}=    $dirWork. $fileJobId.  ".fastaTmp";
	$file{"seqTmp"}=    $fileJobId.  ".f";
	$file{"seqFasta"}=  $dirWork. $fileJobId.  ".fastaGuide";
	push(@kwdRm,"seqTmp","seqFasta");
	($Lok,$msg)=	# call FORTRAN shit to convert to FASTA
	    &convSeq2fasta($exeConvertSeq,$file{"seq"},$file{"seqTmp"},$fhErrSbr);
	return(0,"err=510",$msgErrConvert."\n".$msg."\n".
	       "*** file{seqTmp}=".$file{"seqTmp"}."\n") if (! $Lok);
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqTmp"});
	return(0,"err=511",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seqFasta"},$id,$seq);
	return(0,"err=512",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=513",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seqFasta"}."' written \n") if (! -e $file{"seqFasta"});}

				# --------------------------------------------------
                                # COILS program
				# --------------------------------------------------
    if ($optRun =~/coils/) {
	$file{"coils"}=        $dirWork.$fileJobId.".coils";   
	$file{"coilsRaw"} =    $dirWork.$fileJobId.".coils_raw";  
	#$file{"coilsSyn"}=     $dirWork.$fileJobId.".coilsSyn"; 
	push(@kwdRm,"coils","coilsRaw");

				# ------------------------------
	($Lok,$msg)=		# run
	    &coilsRun($file{"seqFasta"},$file{"coils"},$file{"coilsRaw"},
		      $exeCoils,$parCoilsMetr,$parCoilsWeight,
		      $fhErrSbr,$fileScreenCoilsLoc);
	return(0,"err=520",$msgErrCoils."\n".
	       "*** $sbr: coilsRun (".$file{"seq"}.",".$file{"coils"}.",$exeCoils,$parCoilsMetr,$parCoilsWeight".") failed\n"."$msg\n") if (! $Lok);
				# ------------------------------
	($Lok,$msg)=		# analyse
	    &coilsRd($file{"coils"},$fhErrSbr);
	return(0,"err=521",$msgErrCoils."\n".
	       "*** $sbr: coilsRd (".$file{"coils"}.",".$file{"coilsSyn"}.",$parCoilsMin)". " failed\n"."$msg\n") if (! $Lok);
	print $fhErrSbr 
	    "$msgHere\n"."err=521 $msgErrCoils:\n".
		"*** $sbr: coilsRd (".$file{"coils"}.",".",$parCoilsMin)".
		    " failed\n"."$msg\n" if (! $Lok);
	$#tmpAppend=0;		# ------------------------------
	if    ($Lok==2){	# not significant
	    $Lcoils_notSignificant=1;
	    unlink($file{"coils"});
	    $fileTmp=$file{"coils"};
	    ($Lok,$msgSys)=&sysSystem("echo 'no coiled-coil above probability $parCoilsMin' >> $fileTmp");
	    push(@tmpAppend,$envPP{"fileAppCoils"},$fileTmp,$envPP{"fileAppLine"});}
	elsif ($Lok==1){ 
	    $Lcoils_notSignificant=0;
	    push(@tmpAppend,$envPP{"fileAppCoils"},
		 $file{"coils"},$envPP{"fileAppLine"});}
				# ------------------------------
				# append HTML output
				# ------------------------------
	if ($optOut=~/ret html/ && -e $file{"coils"}){ 
				# apend text
	    if ($Lcoils_notSignificant) {
		($Lok,$msg)=&htmlBuild("no coiled-coil region detected above $parCoilsMin",
				       $fileHtmlTmp,$fileHtmlToc,1,"coils"); }
	    else {
				# append file
		($Lok,$msg)=&htmlBuild($file{"coils"},$fileHtmlTmp,$fileHtmlToc,1,"coils");
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=coils)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2250",$msg); }}}
    }				


			 # --------------------------------------------------
			 # append files
			 # --------------------------------------------------
    if ($origin =~ /^mail|^html|^testPP/i){
	if ($#tmpAppend>0){	# 
	    ($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
	    return(0,"err=530",$msgErrIntern."\n". # 
		   "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}}
    return(1,"ok","$sbr");
    
}				# end runCoils


#===============================================================================
sub runCyspred {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeCopf,$exeCyspred,$fileAliPhdIn,$dirCyspred)=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$fileStripOutMod,
	  $fileAliList,$fileFastaSingle,@tmpAppend,$txt,$command, $fhcys, @tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runCyspred                : cyspred
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runCyspred";
    $errTxt="err=541"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
  #  return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);

    return(0,$errTxt,$msg."exeCyspred!")        if (! defined $exeCyspred);
    return(0,$errTxt,$msg."fileAliPhdIn")     if (! defined $fileAliPhdIn);

    $errTxt="err=542"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=543"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=544"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeCyspred) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=545","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

    return(0,"err=546","*** $sbr: no hssp =".$fileAliPhdIn."!")
	if (! -e $fileAliPhdIn && ! -l $fileAliPhdIn);

    $msgErrIntern=    $msgErr{"internal"}; 
    $msgErrConvert=   $msgErr{"runCyspred:convert"};
    $msgErrCoils=     $msgErr{"runCyspred:cyspred"};
#    $msgErr=    $msgErr{":"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/cyspred,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/cyspred,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/cyspred,//g;}
    
				# ---------------------------------------------
				# cyspred can only take single sequence
				# in case input is list, get the first fasta file
				# ---------------------------------------------
    if ( $optSeq =~ /saf|msf/) {
	$file{"seq4cys"}=    $dirWork. $fileJobId.  ".fastaSingle";
	push(@kwdRm,"seq4cys");
	
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqFasta"});
	return(0,"err=551",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seq4cys"},$id,$seq);
	return(0,"err=552",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=553",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seq4cys"}."' written \n") if (! -e $file{"seq4cys"});
    } else {
	$file{"seq4cys"} = $file{"seqFasta"};
    }


				# --------------------------------------------------
                                # CYSPRED program
				# --------------------------------------------------
    if ($optRun =~/cyspred/) {
	$file{"cyspred"}=        $dirWork.$fileJobId.".cys";   

	push(@kwdRm,"cys");

				# set env CYSPREDIR (required for the program)
	if (! defined $ENV{"CYSPREDIR"} ) {
	    $ENV{"CYSPREDIR"} = $dirCyspred;
	}

				# check whether another cycpred is running
				# due to common filename used by cycpred
				# only one should be run for safety
#	$exe_ps = $envPP{"exe_ps"};
#	while ( 1 ) {
#	    ($Lok, $njobs) =
#		&envPP::isRunningEnv($exeCyspred,$exe_ps, $fhErrSbr);
#	    if ( ! $Lok ) {
#		return ( 0, "err=555","*** ERROR $sbr\n"."$njobs\n");
#	    }
#	    if ( $njobs == 0 ) {
#	        print $fhErrSbr "--- $sbr: No cyspred is running, we are safe.\n";
#		last;
#	    } elsif ( $njobs >= 1 ) {
#		return(1,"non-fatal","$sbr:$msg cyspred is running , skipping cyspred");
#		print  $fhErrSbr "--- $sbr: Another cyspred is running, we'd better wait 5 sec.\n";
#		sleep(5);
#	    } else {
#		return ( 0, "err=555","*** ERROR $sbr\n"."$njobs\n");
#	    }
#	}


	$command="$nice $exeCyspred ".
	    "$file{\"seq4cys\"} $fileAliPhdIn $file{\"cyspred\"}";
	$msgHere="--- $sbr system '$exeCyspred $command'";

	
				# --------------------------------------------------
				# do run CYSPRED
				# --------------------------------------------------
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=560","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	if (! $Lok || ! -e $file{"cyspred"});

				# -------------------------------------------------
				# check result, inform user only when we have some 
				# bonded cycteine
				# -------------------------------------------------
	$fhcys = 'FHCYS';
	$Lok=       &open_file($fhcys,$file{"cyspred"});
	return(0,"*** ERROR $sbr: '$file{\"cyspred\"}' not opened\n") if (! $Lok);

	$Lok = 2;
	while ( <$fhcys> ) {
	    if ( /^No cys in/ ) {
		$Lok = 0;
		$msg .= $_;
		last;
	    } else {
		next if ($_ !~ /YES|NO/i);
		chomp;
		@tmp = split /\s+/;
		if ($tmp[4] eq 'YES') {
		    $Lok = 1;
		    $msg .= "Bonded cys found.\n";
		    last;
		}
	    }
	}

	close $fhcys;
#	print '=== opened file: .$file{"cyspred"}.\t Lok is $Lok\n'x10;
				# -----------------------------------
				# if we have bonded cys, write it out
 
	if ($Lok == 0 ){
	    $msg = "No cys in sequence ";
	    $command =  "cat '".$msg."' > ".$file{"cyspred"};
	    print "$command\n"x10;
	    system($command);
	}
	if ($Lok == 2 ){
	    $msg = "No bonded cys found ";
	    $command =  "echo '".$msg."' > ".$file{"cyspred"};
	    print "$command\n"x10;
	    system($command);	
	}
	if ( $Lok == 1 || $Lok == 0 || $Lok == 2) {
	    $#tmpAppend=0;	  
	    push(@tmpAppend,$envPP{"fileAppCyspred"},
		 $file{"cyspred"},$envPP{"fileAppLine"});
	    
	    # ------------------------------
	    # append HTML output
	    # ------------------------------
	    if ($optOut=~/ret html/ && -e $file{"cyspred"}){ 
		# append file
		($Lok,$msg)=&htmlBuild($file{"cyspred"},$fileHtmlTmp,$fileHtmlToc,1,"cyspred");
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=cyspred)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2250",$msg); }
	    }
	}
	
	
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){	# 
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=570",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }

    return(1,"ok","$sbr:$msg");
}				# end runCyspred





#==========================================================================================
sub runEvalsec {
    local ($origin,$date,$nice,$fileJobId,$fhErrSbr,$dirWork,
	   $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optOut,
	   $file_in,$exeEvalsec,$exeEvalsecFor) = @_ ;
    local ($title,$sbr,$command,$msgHere);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   runEvalsec                  runs the program EVALSEC
#       in:                     $file_in,$file_out,$exeEvalsec,$exeEvalsecForor,$dir_default
#       out:                    $file_out: extract from Tableqils of EVALSEC
#--------------------------------------------------------------------------------
    $sbr="runEvalsec";
    $errTxt="err=491"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);

    return(0,$errTxt,$msg."file_in!")         if (! defined $file_in);
    return(0,$errTxt,$msg."exeEvalsec!")      if (! defined $exeEvalsec);
    return(0,$errTxt,$msg."exeEvalsecFor!")   if (! defined $exeEvalsecFor);

    $errTxt="err=492"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork'!")       if (! -d $dirWork);

    $errTxt="err=493"; $msg="*** $sbr: no file=";
    foreach $file ($filePredTmp,$file_in) {
	return(0,$errTxt,$msg."$file!")       if (! -e $file && ! -l $file); }

    $errTxt="err=494"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeEvalsec,$exeEvalsecFor) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }


    $msgErrIntern=               $msgErr{"internal"};

    $file{"pred"}=               $dirWork.$fileJobId.".evalsec";
    $file{"predTmp"}=            $dirWork.$fileJobId."_evalsecTmp";
    $title=                      "evalsec_".$$;
    $title=                      "EVALSEC-".$fileJobId;
    push(@kwdRm,"pred","predTmp");

    $command="$nice $exeEvalsec ".
	"$file_in $exeEvalsecFor out=".$file{"pred"}." title=$title dirdef=$dirWork".
	    " tmp=".$file{"predTmp"};
    $msgHere="--- $sbr system '$exeEvalsec $command'";
				# --------------------------------------------------
				# do run EVALSEC
				# --------------------------------------------------
    ($Lok,$msgSys)=&sysSystem("$command");

    return (0,"err=493","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	if (! $Lok || ! -e $file{"pred"});
	
				# ------------------------------
				# append files to current predTmp
				# ------------------------------
    if ($origin =~ /^(mail|html|testPP)/){
	($Lok,$msg)=
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppEvalsec"},$envPP{"fileHeadEvalsec"},$file{"pred"});
	if (! $Lok){
	    return(0,"err=494",$msgErrIntern."\n"."evalsec: $msg,\n"."$msgHere");}}

				# ------------------------------
				# append HTML output
				# ------------------------------
    if ($optOut=~/ret html/ && -e $file{"pred"}){
	($Lok,$msg)=&htmlBuild($file{"fileHeadEvalsec"},$fileHtmlTmp,$fileHtmlToc,1,"evalsec_head");
	if (! $Lok) { $msg="*** err=2260 ($sbr: htmlBuild failed on kwd=evalsec_head)\n".$msg."\n";
		      print $fhTrace $msg;
		      return(0,"err=2260",$msg); }
	($Lok,$msg)=&htmlBuild($file{"pred"},$fileHtmlTmp,$fileHtmlToc,1,"evalsec");
	if (! $Lok) { $msg="*** err=2261 ($sbr: htmlBuild failed on kwd=evalsec)\n".$msg."\n";
		      print $fhTrace $msg;
		      return(0,"err=2261",$msg); } }
    return (1,"ok","$sbr");
}				# end of runEvalsec




#===============================================================================
sub runNls {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeNls)=@_;

    local($sbr,$msgHere,$msg,$errTxt,$Lok,$arg,$hasNls,@tmpAppend,$txt,$command);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runNls                    : NLS
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runNls";
    $errTxt="err=501"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeNls!")          if (! defined $exeNls);

    $errTxt="err=502"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=503"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=504"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeNls) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=505","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

    $msgErrIntern=    $msgErr{"internal"};
    $msgErrNls=       $msgErr{"predMis:nls"};

    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/coils,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/nls,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/nls,//g;}
				# --------------------------------------------------
                                # NLS program
				# --------------------------------------------------
    if ($optRun =~/nls/) {
	$file{"nls"}=        $dirWork.$fileJobId.".nls";    
	$file{"nlsSum"}=     $dirWork.$fileJobId.".nlsSum"; 
	$file{"nlsTrace"}=   $dirWork.$fileJobId.".nlsTrace";
	push(@kwdRm,"nls","nlsSum","nlsTrace");

				# command line arguments
	$arg = "";
	$arg .= " dirOut=".$dirWork;
	$arg .= " fileIn=".$file{"seqFasta"};
	$arg .= " fileOut=".$file{"nls"};
	$arg .= " fileSummary=".$file{"nlsSum"};
	$arg .= " fileTrace=".$file{"nlsTrace"};
	if ( $optOut=~/ret html/ ) {
	    $arg .= " html=1 ";
	} else {
	    $arg .= " html=0 ";
	}

	$command = "$nice $exeNls $arg ";
	$msgHere="--- $sbr system '$command'";
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=560",$msgErrNls."*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	    if (! $Lok || ! -e $file{"nls"} 
		|| -s $file{"nlsTrace"} || ! -e $file{"nlsSum"});

	$hasNls = `cat $file{"nlsSum"}`;
	$hasNls =~ s/\s+//g;
	
	if ( $hasNls ) {	# NLS found
	    if ($optOut=~/ret html/ && -e $file{"nls"}){ # append html output 
		($Lok,$msg)=&htmlBuild($file{"nls"},$fileHtmlTmp,$fileHtmlToc,
				       0,"predictNLS");
		if (! $Lok) { 
		    $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=predictNLS)\n".
			$msg."\n";
		    print $fhTrace $msg;
		    return(0,"err=2250",$msg); }
	    } else {		# ascii output
		$#tmpAppend=0;	
		push(@tmpAppend,$file{"nls"},$envPP{"fileAppLine"});
	    }
	} else {
	    $msg .= " No NLS found. ";
	}
    }

				# --------------------------------------------
				# append files
				# -------------------------------------------

    if ($origin =~ /^mail|^html|^testPP/i){
	if ($#tmpAppend>0){
	    ($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
	    return(0,"err=570",$msgErrIntern."\n". 
		   "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
    }			
    return(1,"ok","$sbr:$msg");
    
}				# end runNls


#===============================================================================
sub runNorsp {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,
	  $optOut,$exeNors,$parNorsWs,$parNorsSecCut,$parNorsAccLen) = @_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$arg,$parNorsExp,@tmpAppend,$txt,$command);
    local($fileRdbHtm);

    $[ =1 ;
#-------------------------------------------------------------------------------
#   runNORS                   : Nors
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"phdPred"}  , output from PHD
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runNors";
    $errTxt="err=640"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeNors")          if (! defined $exeNors);
    return(0,$errTxt,$msg."parNorsWs")        if (! defined $parNorsWs);
    return(0,$errTxt,$msg."parNorsSecCut")    if (! defined $parNorsSecCut);
    return(0,$errTxt,$msg."parNorsAccLen")    if (! defined $parNorsAccLen);

    $errTxt="err=681"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=682"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=683"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeNors) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=684","*** $sbr: no sequence file =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});
#    return(0,"err=685","*** $sbr: no PHDhtm output =".$file{"phdRdbHtm"}."!")   
#	if (! -e $file{"phdRdbHtm"} && ! -e $file{"phdNotHtm"});
    return(0,"err=686","*** $sbr: no PROF output =".$file{"profRdb"}."!")   
	if (! -e $file{"profRdb"} && ! -l $file{"profRdb"});
    return(0,"err=687","*** $sbr: no Coils output =".$file{"coils"}."!")   
	if (! -e $file{"coils"} && ! -e $file{"coilsRaw"});
    return(0,"err=687","*** $sbr: no HSSP file =".$file{"aliPhdIn"}."!")   
	if (! -e $file{"aliPhdIn"} && ! -l $file{"aliPhdIn"});

    $msgErrIntern=    $msgErr{"internal"};
    $msgHere="";

				# --------------------------------------------------
                                # NORS program
				# --------------------------------------------------
    if ($optRun =~/nors/) {
	$file{"nors"}=        $dirWork.$fileJobId.".nors";   
	$file{"sumNors"}=     $dirWork.$fileJobId.".sumNors"; 
	push(@kwdRm,"nors","sumNors");

				# extract expert options
	if ( $optRun =~ /parNors\(([^\(]+)\)/ ) {
	    $parNorsExp = $1;
	    if ( $parNorsExp =~ /ws\=([0-9]+)/ ) {
		$parNorsWs = $1;
	    }
	    if ($parNorsExp =~ /seccut\=([0-9]+)/ ) {
		$parNorsSecCut = $1;
	    }
	    if ($parNorsExp =~ /acclen\=([0-9]+)/ ) {
		$parNorsAccLen = $1;
	    }
	}

	if ( -s $file{"phdRdbHtm"} ) {
	    $fileRdbHtm = $file{"phdRdbHtm"};
	} else {
	    $fileRdbHtm = $file{"phdRdb"};
	}

				# command line arguments
	$arg = "";
	$arg .= " -win ".$parNorsWs;
	$arg .= " -secCut ".$parNorsSecCut;
	$arg .= " -accLen ".$parNorsAccLen;
	$arg .= " -fileSeq ".$file{"seq"};
	$arg .= " -fileHssp ".$file{"aliPhdIn"};
	$arg .= " -filePhd ".$file{"profRdb"};
	$arg .= " -filePhdHtm ".$fileRdbHtm;
	$arg .= " -fileCoils ".$file{"coils"};
	$arg .= " -o ".$file{"nors"};
	$arg .= " -fileSum ".$file{"sumNors"};
	if ( $optOut=~/ret html/ ) {
	    $arg .= " -html ";
	}

	$command = "$nice $exeNors $arg ";
	$msgHere="--- $sbr system '$command'";
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=688","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	    if (! $Lok || ! -e $file{"nors"}); # || -s $file{"errAsp"});

	$hasNors = `cat $file{"sumNors"}`;
	$hasNors =~ s/\s+//g;
	
	if ( $hasNors ) {	# NORS found
	    if ($optOut=~/ret html/ && -e $file{"nors"}){ # append html output 
		($Lok,$msg)=&htmlBuild($file{"nors"},$fileHtmlTmp,$fileHtmlToc,
				       0,"norsp");
		if (! $Lok) { 
		    $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=NORSp)\n".
			$msg."\n";
		    print $fhTrace $msg;
		    return(0,"err=2250",$msg); }
	    } else {		# ascii output
		$#tmpAppend=0;	
		push(@tmpAppend,$envPP{"fileAppNorsp"},$file{"nors"},$envPP{"fileAppLine"});
	    }
	} else {
	    $msg .= " No NORS found. ";
	}
    }
	
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
    if ($origin =~ /^mail|^html|^testPP/i){
	if ($#tmpAppend>0){
	    # print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
	    ($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
	    return(0,"err=646",$msgErrIntern."\n". 
		   "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
    }
    
    return(1,"ok","$sbr");
}			# end runNors


#===============================================================================
sub wrapUp_nors {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,
	  $optOut,$optVerbose) = @_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$arg,$parNorsExp,@tmpAppend,$txt,$command);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runNORS                   : Nors
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"phdPred"}  , output from PHD
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="wrapUp_nors";
    $errTxt="err=640"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);

    

    if ( $optOut =~ /ret html/ ) { 
	unlink($fileHtmlTmp)    if (-e $fileHtmlTmp);
	unlink($fileHtmlToc)    if (-e $fileHtmlToc);
	&iniHtmlBuild()         if (! defined %htmlKwd);
	if ( ! $optVerbose ) {
	    ($Lok,$msg)=&htmlBuild($file{"nors"},$fileHtmlTmp,$fileHtmlToc,
				   0,"norsp");
	    if (! $Lok) { 
		$msg="*** err=2250 ($sbr: htmlBuild failed on kwd=norsp)\n".
		    $msg."\n";
		print $fhTrace $msg;
		return(0,"err=2250",$msg); }
	    return(1,"ok",$sbr);
	} else {
				# input file
	    ($Lok,$msg)=&htmlBuild($file{"in"},$fileHtmlTmp,$fileHtmlToc,1,"in_given");
	    if (! $Lok) { $msg="*** err=2210 ($sbr: htmlBuild failed on kwd=in_given_toc)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,$msg); }

				# NORS file
	    ($Lok,$msg)=&htmlBuild($file{"nors"},$fileHtmlTmp,$fileHtmlToc,
				   0,"norsp");
	    if (! $Lok) { 
		$msg="*** err=2250 ($sbr: htmlBuild failed on kwd=NORSp)\n".
		    $msg."\n";
		print $fhTrace $msg;
		return(0,"err=2250",$msg); }

				# PROF file
	    ($Lok,$msg)=&htmlBuild($file{"profHtml"},$fileHtmlTmp,$fileHtmlToc,0,"prof_body");
	    if (! $Lok) { $msg="*** err=2301 ($sbr: htmlBuild failed on kwd=prof_body)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2301",$msg); }

				# PHDhtm
	    if ( -f $file{"phdHtml"} ) {
		($Lok,$msg)=&htmlBuild($file{"phdHtml"},$fileHtmlTmp,$fileHtmlToc,0,"phd_body");
		if (! $Lok) { $msg="*** err=2271 ($sbr: htmlBuild failed on kwd=phd_body)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2271",$msg); }
	    }
	    
				# coils
	    if ( -e $file{"coils"} ) {
		($Lok,$msg)=&htmlBuild($file{"coils"},$fileHtmlTmp,$fileHtmlToc,1,"coils");
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=coils)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2250",$msg); }
	    }
	    return (1,"ok",$sbr);
	}
    } else {			# TXT output
	unlink $filePredTmp if ( -e $filePredTmp );
	if ( ! $optVerbose ) {	# concise TXT
	    $#tmpAppend=0;	
	    push(@tmpAppend,$envPP{"fileAppNorsp"},$file{"nors"},$envPP{"fileAppLine"});

	    if ($#tmpAppend>0){
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=646",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	} else {		# verbose txt
				# input sequence
	    ($Lok,$msg)=
		&sysCatfile("nonice",$LdebugLoc,$filePredTmp,$envPP{"fileAppInSeqSent"},
			    $file{"in"},$envPP{"fileAppLine"});
	    return(0,"err=646",$msgErrIntern."\n".
		   "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);
				# build files
	    $#tmpAppend=0;	
				# NORS file
	    push(@tmpAppend,$envPP{"fileAppNorsp"},$file{"nors"},$envPP{"fileAppLine"});
				# PROF
	    if ( -e $file{"profAscii"} ) {
		push(@tmpAppend,$envPP{"fileAppPredProf"},$file{"profAscii"},$envPP{"fileAppLine"});
	    }
				# PHDhtm
	    if ( -e $file{"phdPred"} ) {
		push(@tmpAppend,$envPP{"fileAppPredPhd"},$file{"phdPred"},$envPP{"fileAppLine"});
	    }
				# COILS
	    if ( -e $file{"coils"} ) {
		push(@tmpAppend,$envPP{"fileAppCoils"},$file{"coils"},$envPP{"fileAppLine"});
	    }

	    if ($#tmpAppend>0){
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=646",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	    return (1,"ok",$sbr);
	}
    }


    return(1,"ok","$sbr");
}			# end wrapUp_nors




#==========================================================================
sub runPhd {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,$dirWork,
	  $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,$fileHssp,$exePhdPl,
	  $exePhdFor,$exeHtmFil,$exeHtmRef,$exeHtmTop,$exeConvertSeq,
	  $exeHsspFil,$exeRdb2kg,$exeCopf,$exePhd2msf,$exePhd2dssp,$exePhd2casp2,$exePhd2html,
	  $paraSec,$paraAcc,$paraHtm,$paraHtmDef,
	  $paraHtmMin,$charPerLineMsf,$hsspFilterMetr)=@_;
    local($sbr,$optPhd,$opt,$optAdd,$kwd,$kwd2,$tmp,$tmp2,$msg,
	  $msgHere,$command,$phdHdr,$Lskip,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   runPhd                      runs: phd
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $envPP{"head*"},$envPP{"abbr*"},
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#--------------------------------------------------------------------------------
    $sbr="runPhd";
    $errTxt="err=601"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."fileHssp!")        if (! defined $fileHssp);
    return(0,$errTxt,$msg."exePhdPl!")        if (! defined $exePhdPl);
    return(0,$errTxt,$msg."exePhdFor!")       if (! defined $exePhdFor);
    return(0,$errTxt,$msg."exeHtmFil!")       if (! defined $exeHtmFil);
    return(0,$errTxt,$msg."exeHtmRef!")       if (! defined $exeHtmRef);
    return(0,$errTxt,$msg."exeHtmTop!")       if (! defined $exeHtmTop);
    return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);
    return(0,$errTxt,$msg."exeHsspFil!")      if (! defined $exeHsspFil);
    return(0,$errTxt,$msg."exeRdb2kg!")       if (! defined $exeRdb2kg);
    return(0,$errTxt,$msg."exeCopf!")         if (! defined $exeCopf);
    return(0,$errTxt,$msg."exePhd2msf!")      if (! defined $exePhd2msf);
    return(0,$errTxt,$msg."exePhd2dssp!")     if (! defined $exePhd2dssp);
    return(0,$errTxt,$msg."exePhd2casp2!")    if (! defined $exePhd2casp2);
    return(0,$errTxt,$msg."exePhd2html!")     if (! defined $exePhd2html);
    return(0,$errTxt,$msg."paraSec!")         if (! defined $paraSec);
    return(0,$errTxt,$msg."paraAcc!")         if (! defined $paraAcc);
    return(0,$errTxt,$msg."paraHtm!")         if (! defined $paraHtm);
    return(0,$errTxt,$msg."paraHtmDef!")      if (! defined $paraHtmDef);
    return(0,$errTxt,$msg."paraHtmMin!")      if (! defined $paraHtmMin);
    return(0,$errTxt,$msg."charPerLineMsf!")  if (! defined $charPerLineMsf);
    return(0,$errTxt,$msg."hsspFilterMetr!")  if (! defined $hsspFilterMetr);

    $errTxt="err=602"; $msg="*** $sbr: no dir =";
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=603"; $msg="*** $sbr: no file=";
    foreach $file ($filePredTmp,$fileHssp,$paraSec,$paraAcc,$paraHtm,$hsspFilterMetr){
	return(0,$errTxt,$msg."$file!")       if (! -e $file && ! -l $file); }

    $errTxt="err=604"; $msg="*** $sbr: no exe =";
    foreach $exe ($exePhdPl,$exePhdFor,$exeHtmFil,$exeHtmRef,$exeHtmTop,$exeCopf,$exeConvertSeq,
		  $exeHsspFil,$exeRdb2kg,$exePhd2msf,$exePhd2dssp,$exePhd2casp2,$exePhd2html) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }
				# check format
    $errTxt="err=605"; $msg="*** $sbr: ";
    return(0,$errTxt,$msg."not   HSSP=$fileHssp!")    if (! &is_hssp($fileHssp));
    return(0,$errTxt,$msg."empty HSSP=$fileHssp!")    if (&is_hssp_empty($fileHssp));

    $msgErrIntern=    $msgErr{"internal"};
    $msgErrPhd=       $msgErr{"phd:run"};
    $msgErrRdb2kg=    $msgErr{"phd:rdb2kg"};
    $msgErrCol=       $msgErr{"phd:phd2col"};
    $msgErrMsf=       $msgErr{"phd:phd2msf"};
    $msgErrDssp=      $msgErr{"phd:phd2dssp"};
    $msgErrCasp2=     $msgErr{"phd:phd2casp2"};
    $msgErrGlobe=     $msgErr{"phd:globe"};

    $fhoutLoc="FHOUT_runPhd";

                                # ----------------------------------------
                                # convert Global option flag to local
    if    ($optRun=~/topits/)                         {$optPhd="both";} # for topits only sec/acc
    elsif ($optRun=~/phdsec/i && $optRun=~/phdacc/i
	   && $optRun=~/phd/i )                       {$optPhd="3";}
    elsif ($optRun=~/phdsec/i && $optRun=~/phdacc/i ) {$optPhd="both";}
    elsif ($optRun=~/phdsec/i)                        {$optPhd="sec";}
    elsif ($optRun=~/phdacc/i)                        {$optPhd="acc";}
    elsif ($optRun=~/phdhtm/i)                        {$optPhd="htm";}
    else                                              {$optPhd="3";} # default

                                # ----------------------------------------
				# build up input options
                                # default options for PHD
    $opt ="";
    $opt.=" exePhd=$exePhdFor filterHsspMetric=$hsspFilterMetr";
    $opt.=" exeHtmfil=$exeHtmFil exeHtmref=$exeHtmRef exeHtmtop=$exeHtmTop";
    $opt.=" paraSec=$paraSec paraAcc=$paraAcc paraHtm=$paraHtm";
    $opt.=" user=phd noPhdHeader dirOut=$dirWork dirWork=$dirWork jobid=$fileJobId";
                                # ----------------------------------------
                                # filenames
    foreach $kwd ("phdPred","phdRdb","phdRdbHtm","phdNotHtm","screenPhd"){
	$file{$kwd}=          $dirWork.$fileJobId.".$kwd";push(@kwdRm,"$kwd");}

    $opt.=" fileOutPhd=".$file{"phdPred"}." fileOutRdb=".$file{"phdRdb"}.
	" fileOutRdbHtm=".$file{"phdRdbHtm"}." fileNotHtm=".$file{"phdNotHtm"};
                                # ----------------------------------------
    $optAdd="";			# further
    if (length($nice)>1)  {	# nice
	$tmp=$nice;$tmp=~s/\s//g;
	$tmp2=$tmp; if ($tmp2 !~/\-/){$tmp2=~s/nice/nice\-/;
				      $tmp=$tmp2;}
	$optAdd.=" optNice=$tmp";}
    $optAdd.=" optDoHtmref=1  optDoHtmtop=1";
				# --------------------------------------------------
				# minimal 'strength' of HTM to be reported
				# 
				# extract expert options PHDhtm
				#    from extrHdrOneLine:extrHdrExpertPhdhtm:
				#    ',parPhdhtm(min=n)'
				# --------------------------------------------------
    if    ($optRun=~/(htm|min)=([0-9\.]+)/){
	$tmp=$2;}
    elsif ($optPhd eq "htm"){
	$tmp=$paraHtmMin;}
    else{
	$tmp=$paraHtmDef;}
    $optAdd.=" optHtmisitMin=$tmp";
				# ------------------------------
				# miscellaneous
    $optAdd.=" exeCopf=$exeCopf nresPerLineAli=$charPerLineMsf".
	" exePhd2msf=$exePhd2msf exePhd2dssp=$exePhd2dssp ".
	    " exeConvertSeq=$exeConvertSeq exeHsspFilter=$exeHsspFil".
		" doCleanTrace=1";


    $cmd="$exePhdPl $fileHssp $optPhd $opt verbose $optAdd >> ".$file{"screenPhd"};

				# xdbg: to avoid piping PHD screen into file
#    $cmd="$exePhdPl $fileHssp $optPhd $opt verbose $optAdd dbg";

    $msgHere="";
#    $msgHere.="--- $sbr system '$cmd'\n";
#    print $fhOutSbr "--- $sbr system \t '$cmd'\n";

				# ==================================================
				# running PHD


    ($Lok,$msgSys)=&sysSystem("$cmd",$fhOutSbr);

				# ==================================================

                                # ----------------------------------------
                                # security check for existence of pred file
                                # ----------------------------------------
    return(0,"err=611",$msgErrPhd."\n"."*** ERROR $sbr: no pred file after\n".
	   $msgHere) if (! -e $file{"phdPred"});
                                # ------------------------------
                                # correct local if no membrane
    $optPhd="both"   if ( ($optPhd eq "3") && (-e $file{"phdNotHtm"}) );
	
                                # ----------------------------------------
				# run GLOBE (note: only if NOT htm!)
                                # ----------------------------------------
    $globeOut=0;
    if ($optPhd eq "acc" || $optPhd eq "both") { # note '3' an NOT htm already corrected!
	$file{"globe"}=         $dirWork.$fileJobId.".globe";push(@kwdRm,"globe");
	$msgHere.="--- $sbr calling \&globeOne(".$file{"phdRdb"}.",$fhErrSbr)\n";
				# security erase
	unlink($file{"globe"})  if (-e $file{"globe"});
				# ------------------------------
				# run GLOBE
				# out : 1  $len
				#       2  $numExposed
				#       3  $numExpect
				#       4  $globePhdDiff
				#       5  $evaluation
				#       6  $globePhdNorm
				#       7  $globePhdProb,
				#       8  $segRatio
				#       9  $LisGlobular
				#       10 $evaluationCombi
				# in  : option 'noseg' -> no
				#       run of SEG
				# ------------------------------
	($Lok,$msg,@tmpGlobe)=
	    &globeOne($file{"phdRdb"},$fhErrSbr,"noseg");
				# ------------------------------
				# error (not fatal!)
	$msgHere.="err=622".$msgErrGlobe."\n".$msg."\n" 
	    if (! $Lok);
				# --------------------
	if ($Lok){		# write output text
	    $nexpTxt=sprintf("%5d   ",int($tmpGlobe[2]));
	    $nfitTxt=sprintf("%5d   ",int($tmpGlobe[3]));
	    $diffTxt=sprintf(" %7.2f",$tmpGlobe[4]);
				# final text
	    $globeOut ="--- \n";
	    $globeOut.="--- GLOBE: prediction of protein globularity\n";
	    $globeOut.="--- \n";
	    $globeOut.="--- nexp = $nexpTxt (number of predicted exposed residues)\n";
	    $globeOut.="--- nfit = $nfitTxt (number of expected exposed residues\n";
	    $globeOut.="--- diff = $diffTxt (difference nexp-nfit)\n";
	    $globeOut.="--- =====> $tmpGlobe[5]\n";
	    $globeOut.="--- \n";
	    $globeOut.="--- \n";
	    $globeOut.="--- GLOBE: further explanations preliminaryily in:\n";
	    $globeOut.="---        http://www.columbia.edu/~rost/Papers/98globe.html\n";
	    $globeOut.="--- \n";$globeOut.="--- END of GLOBE\n";
#	    $msgHere.="--- $sbr '$globeOut'\n"; 
#	    print $fhOutSbr "--- $sbr (GLOBE out): \n$globeOut\n";
	    open($fhoutLoc,">>".$file{"globe"});
	    print $fhoutLoc $globeOut;
	    close($fhoutLoc);
	}}
				# --------------------------------------------------
                                # select the header to append
				# --------------------------------------------------
    if    ($optOut=~/concise/){ $phdHdr=$envPP{"fileHeadPhdConcise"};}
    elsif ($optPhd eq "acc" ) { $phdHdr=$envPP{"fileHeadPhdAcc"};}
    elsif ($optPhd eq "sec" ) { $phdHdr=$envPP{"fileHeadPhdSec"};}
    elsif ($optPhd eq "htm" ) { $phdHdr=$envPP{"fileHeadPhdHtm"};}
    elsif ($optPhd eq "both") { $phdHdr=$envPP{"fileHeadPhdBoth"};}
    else                      { $phdHdr=$envPP{"fileHeadPhd3"};}
				# ------------------------------
				# (1) append standard PHD results
				# ------------------------------
    if ($origin=~/^mail|^html|^testPP/i){

				# ******************************
				# delete one day: remove from PHD
				# (a) remove the network section
	$file{"filterNN"}=$dirWork.$fileJobId."_filNN.tmp";push(@kwdRm,"filterNN");
	$file{"phdTmp"}=  $dirWork.$fileJobId.".phd.tmp";  push(@kwdRm,"phdTmp");
    
	$tmp1= "The resulting network prediction";
	$tmp2= "Some statistics";
	($Lok,$txt)=
	    &filePurgePat1Pat2($file{"phdPred"},$file{"phdTmp"},$file{"filterNN"},$tmp1,$tmp2);
	if (! $Lok){
	    $msgHere.="*** $sbrName error filtering NN section\n".$txt."\n";}
	else {
	    ($Lok,$txt)=&sysMvfile($file{"phdTmp"},$file{"phdPred"}," ");
				# (b) remove the NEWS section
	    $tmp1= "PHD: NEWS"; # second: the 
	    $tmp2= "EOF";
	    ($Lok,$txt)=
		&filePurgePat1Pat2($file{"phdPred"},$file{"phdTmp"},$file{"filterNN"},$tmp1,$tmp2);}
	if (! $Lok){
	    $msgHere.="*** $sbrName error filtering NN section\n".$txt."\n"; }
	else {
	    ($Lok,$txt)=&sysMvfile($file{"phdTmp"},$file{"phdPred"}," "); }
				# ******************************

				# append <<< --------------------
	($Lok,$msg)=		# save what you have so far
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,$phdHdr,
			$envPP{"fileAppPredPhd"},$file{"phdPred"},$envPP{"fileAppLine"});
	return(0,"err=623",$msgErrPhd."\n"."$msg\n") if (! $Lok);

				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
				# first add references
	    $html{"flag_method","phd_sec"}=1 if ($optPhd=~/sec|both|3/);
	    $html{"flag_method","phd_acc"}=1 if ($optPhd=~/acc|both|3/);
	    $html{"flag_method","phd_htm"}=1 if ($optPhd=~/htm|3/);
				# build HTML
	    ($Lok,$msg)=&htmlBuild($phdHdr,$fileHtmlTmp,$fileHtmlToc,1,"phd_info");
	    if (! $Lok) { $msg="*** err=2270 ($sbr: htmlBuild failed on kwd=phd_info)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2270",$msg); }
	    $Lok=0;
				# 1st: try neat conversion
	    if (defined $file{"phdRdb"} &&  -e $file{"phdRdb"}) {
		$file{"phdHtml"}=$dirWork.$fileJobId.".html_phd"; push(@kwdRm,"phdHtml");
		$modewrt="html:body,data:brief,data:normal";
#		$modewrt="html:all,data:brief,data:normal";
		$modewrt.=",data:detail"
		    if ($optOut=~/ret html detail/);
		$cmd= "$exePhd2html ".$file{"phdRdb"}." fileOut=".$file{"phdHtml"};
				# parameter
		$cmd.=" parHtml=$modewrt";
				# number of lines per row
		$cmd.=" nresPerRow=$1" if ($optOut=~/perline=(\d+)/);
		($Lok,$msgSys)=&sysSystem("$cmd",$fhOutSbr); 
		$fileTmp=$file{"phdHtml"}; $preTmp=0;}
				# 2nd: try to <PRE> it
	    if (! $Lok) {
		$fileTmp=$file{"phdPred"}; $preTmp=1;}
	    ($Lok,$msg)=&htmlBuild($fileTmp,$fileHtmlTmp,$fileHtmlToc,$preTmp,"phd_body");

	    if (! $Lok) { $msg="*** err=2271 ($sbr: htmlBuild failed on kwd=phd_body)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2271",$msg); }}}

				# ------------------------------
				# (2) append results from GLOBE
				# ------------------------------
    if ($origin=~/^mail|^html|^testPP/i && ($globeOut ne "0")){
				# append <<< --------------------
	($Lok,$msg)=		# save what you have so far
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppGlobe"},$file{"globe"});
	return(0,"err=624",$msgErrPhd."\n"."$msg\n") if (! $Lok);
				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"globe"},$fileHtmlTmp,$fileHtmlToc,1,"globe");
	    if (! $Lok) { $msg="*** err=2272 ($sbr: htmlBuild failed on kwd=globe)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2272",$msg); }}}


				# --------------------------------------------------
				# return options: if 'ret phd :msf|casp2|col|graph|mach|rdb]'
				#                 option there MUST be an RDB
				# --------------------------------------------------
    if (($origin=~/^mail|^html|^testPP/i)&&
	($optOut =~ /ret phd\s*[mcgr]/)&&(! -e $file{"phdRdb"})){
	return(0,"err=612",$msgErrPhd."\n"."*** ERROR $sbr: no RDB file after\n".$msgHere); }
                                # ------------------------------
				# convert to dssp if topits
                                # ------------------------------
    if ($optRun =~/topits/){
	$kwd="phdDssp";
	$file{$kwd}=          $dirWork.$fileJobId.".$kwd";push(@kwdRm,"$kwd");
	$command="$nice $exePhd2dssp ".$file{"phdRdb"}." file_out=".$file{$kwd};
	$msgHere.="--- $sbr system '$command'\n";
	($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
	if (! $Lok || ! -e $file{$kwd}){
#		return(0,"err=614",$msgErrDssp."\n"."Lok=$Lok $msgHere");
	    $msgHere.="--- WARN $sbr phd2dssp failed\n"."$msgErrDssp\n";}}
                                # ------------------------------
				# Option: ret phd graph
				# ------------------------------
    if (($origin=~/^mail|^html|^testPP/i)&&($optOut=~/ret phd gr/)){
	$kwd="phdRetKg";
	$file{$kwd}=          $dirWork.$fileJobId.".$kwd";push(@kwdRm,"$kwd");
				# --------------------
	if ($optPhd eq "3") {	# if all 3, first both, then htm
				# (1) for both
	    $command="$nice $exeRdb2kg ".$file{"phdRdb"}." ".$file{$kwd}." both";
	    $msgHere.="--- $sbr system '$command'\n";
	    ($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
	    if (! $Lok || ! -e $file{$kwd}){
#		return(0,"err=613",$msgErrRdb2kg."\n"."Lok=$Lok $msgHere");
		$msgHere.="--- WARN $sbr htmRdb -> kg failed\n"."$msgErrRdb2kg\n";}
	    ($Lok,$msg)=	# append <<< --------------------
		&sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppRetGraph"},
			    $file{"phdRetKg"},$envPP{"fileAppLine"});
				# (2) for HTM
	    $kwd2="phdRetKgHtm";
	    $file{$kwd2}=     $dirWork.$fileJobId.".$kwd";push(@kwdRm,"$kwd2");
	    $command="$nice $exeRdb2kg ".$file{"phdRdb"}." ".$file{$kwd2}." htm";
	    $msgHere.="--- $sbr system '$command'\n";
	    ($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
	    if    (! $Lok || ! -e $file{$kwd2}){ # dont leave if not existing!!
#		return(0,"err=614",$msgErrRdb2kg."\n"."Lok=$Lok $msgHere");
		$msgHere.="--- WARN $sbr htmRdb -> kg failed\n"."$msgErrRdb2kg\n";}
                                # (3) cat 2nd onto 1st
	    elsif (-e $file{$kwd2}){
		($Lok,$msg)=	# append <<< --------------------
		    &sysCatfile("nonice",$Ldebug,$filePredTmp,
				$file{$kwd2},$envPP{"fileAppLine"});}}
                                # --------------------
	else {                  # else: simply convert
	    $command="$nice $exeRdb2kg ".$file{"phdRdb"}." ".$file{$kwd}." $optPhd";
	    $msgHere.="--- $sbr system '$command'\n";
	    ($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
	    if (! $Lok || ! -e $file{$kwd}){
		return(0,"err=615",$msgErrRdb2kg."\n"."Lok=$Lok $msgHere");}
	    ($Lok,$msg)=	# append <<< --------------------
		&sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppRetGraph"},
			    $file{"phdRetKg"},$envPP{"fileAppLine"});}}

                                # ------------------------------
				# Option: ret phd col
				# ------------------------------
    if (($origin=~/^mail|^html|^testPP/i)&&($optOut=~/ret phd col/)){
	$kwd="phdRetCol";
	$file{$kwd}=          $dirWork.$fileJobId.".$kwd";push(@kwdRm,"$kwd");
	$msgHere.="--- $sbr convPhd2col(".$file{"phdRdb"}.",".$file{$kwd}.",)\n";
	($Lok,$msg)=
	    &convPhd2col($file{"phdRdb"},$file{$kwd},$optPhd);
	if (! $Lok || ! -e $file{$kwd}){
#	    return(0,"err=616",$msgErrCol."\n"."Lok=$Lok $msgHere");
	    $msgHere.="*** WARN $sbr after convPhd2col:\n".
		$msgErrCol."\n"."*** WARN $sbr msg=\n$msg\n";}
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppRetCol"},$file{$kwd},$envPP{"fileAppLine"});
	if (! $Lok ){
#	    return(0,"err=617",$msgErrInter."\n"."Lok=$Lok $msgHere");
	    $msgHere.="*** WARN $sbr after convPhd2col (cat):\n".
		$msgErrIntern."\n"."*** WARN $sbr msg=\n$msg\n";}
				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"phdRetCol"},$fileHtmlTmp,$fileHtmlToc,1,"phd_col");
	    if (! $Lok) { $msg="*** err=2273 ($sbr: htmlBuild failed on kwd=phd_col)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2273",$msg); }}}

                                # ------------------------------
    if ($optOut=~/ret phd msf/){ # Option: ret phd msf
                                # ------------------------------
	$Lskip=0;
	$kwd="phdRetMsf";
	$file{$kwd}=            $dirWork.$fileJobId.".$kwd"; push(@kwdRm,"$kwd");
	$kwd2="aliMsf";
	$tmp=                   $dirWork.$fileJobId.".$kwd2";push(@kwdRm,"$kwd2");
	$file{$kwd2}=           $dirWork.$fileJobId.".$kwd2";
	if (! -e $tmp){
	    $msgHere.="--- $sbr convHssp2msf($exeConvertSeq,$fileHssp,".$file{$kwd2}.",)\n";
	    $LdoExpandLoc=0;
	    ($Lok,$msg)=	# convert the sequence (HSSP to MSF)
		&convHssp2msf($exeConvertSeq,$fileHssp,$file{$kwd2},$LdoExpandLoc,$fhErrSbr);
	    if (!$Lok || (! -e $file{$kwd2})){
		$Lskip=1;
#		return(0,"err=618",$msgErrMsf."\n"."Lok=$Lok $msgHere");
		$msgHere.="*** WARN $sbr after convHssp2msf no out:\n".
		    "*** msg=\n$msg\n$msgHere";}}
	if (! $Lskip){
	    $command="$nice $exePhd2msf fileMsf=".$file{$kwd2}." filePhd=".$file{"phdRdb"}.
		" fileOut=".$file{$kwd}." charPerLine=$charPerLineMsf notScreen";
	    $msgHere.="--- $sbr system '$command'\n";
	    ($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
	    if (! $Lok || ! -e $file{$kwd}){
#		return(0,"err=619",$msgErrMsf."\n"."Lok=$Lok $msgHere");
		$msgHere.="*** WARN $sbr after $exePhd2msf no out:\n".$msgErrMsf."\n";}}
	if (-e $file{$kwd} && ($origin=~/^mail|^html|^testPP/i) ){
	    ($Lok,$msg)=	# append <<< --------------------
		&sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppRetPhdMsf"},
			    $file{$kwd},$envPP{"fileAppLine"})}
				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"phdRetMsf"},$fileHtmlTmp,$fileHtmlToc,1,"phd_msf");
	    if (! $Lok) { $msg="*** err=2274 ($sbr: htmlBuild failed on kwd=phd_msf)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2274",$msg); }}}

                                # ------------------------------
				# Option: ret phd casp2
                                # ------------------------------
    if ($origin=~/^mail|^html|^testPP/i && $optOut=~/ret phd casp/ ){
	$kwd="phdRetCasp";
	$file{$kwd}=          $dirWork.$fileJobId.".$kwd";push(@kwdRm,"$kwd");
				# (1) read NALIGN
	$fhin="FHIN_".$sbr."_READ_HSSP";
	open($fhin,"$fileHssp")  || warn "*** $sbr: cannot open $fileHssp!\n";
	while(<$fhin>){$tmp=$_;	    
			  last if ($_=~/^NALIGN/);}close($fhin);
	$nali=$tmp;$nali=~s/^NALIGN\s+//g;$nali=~s/\s//g;$nali=~s/[^0-9]//g;
				# (2) run exePhd2casp2
	$command="$nice $exePhd2casp2 ".$file{"phdRdb"}.
	    " fileOut=".$file{$kwd}." nali=$nali notScreen";
	$msgHere.="--- $sbr system '$command'\n";
	($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
	if (! $Lok || ! -e $file{$kwd}){
#	    return(0,"err=620",$msgErrCasp2."\n"."Lok=$Lok $msgHere");
	    $msgHere.="*** WARN $sbr after $exePhd2msf no out:\n".$msgErrCasp2."\n";}
	if (-e $file{$kwd}){
	    ($Lok,$msg)=	# append <<< --------------------
		&sysCatfile("nonice",$Ldebug,$filePredTmp,
			    $envPP{"fileAppRetPhdCasp2"},$file{$kwd});}}

				# ------------------------------
				# Option: ret phd rdb
				# ------------------------------
    if (($origin=~/^mail|^html|^testPP/i)&&($optOut=~/ret phd rdb/)){
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppRetPhdRdb"},$file{"phdRdb"});
				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"phdRdb"},$fileHtmlTmp,$fileHtmlToc,1,"phd_rdb");
	    if (! $Lok) { $msg="*** err=2275 ($sbr: htmlBuild failed on kwd=phd_rdb)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2275",$msg); }}}
    return(1,"ok",$msgHere);
}				# end of runPhd

#===============================================================================
sub runProdom {
    local($fileSeqFasta,$fileProdomTmp,$fileProdom,$fileProdomHtml,
	  $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$optOut,
	  $exeBlast,$envProdomBlastDb,$envBlastMat,
	  $parProdomBlastDb,$parProdomBlastN,$parProdomBlastE,$parProdomBlastP,
	  $exeMview,$parMview,$nice,$fhErrSbr,$fhTrace) = @_ ;
    local($sbr2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runProdom                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbr2="runProdom";
				# ------------------------------
				# consistency check of input
    $errTxt="err=4015"; $msg="*** $sbr2: not def ";
    return(0,$errTxt,$msg."fileSeqFasta!")    if (! defined $fileSeqFasta);
    return(0,$errTxt,$msg."fileProdomTmp!")   if (! defined $fileProdomTmp);
    return(0,$errTxt,$msg."fileProdom!")      if (! defined $fileProdom);
    return(0,$errTxt,$msg."fileProdomHtml!")  if (! defined $fileProdomHtml);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeBlast!")        if (! defined $exeBlast);
    return(0,$errTxt,$msg."envProdomBlastDb!")if (! defined $envProdomBlastDb);
    return(0,$errTxt,$msg."envBlastMat!")     if (! defined $envBlastMat);
    return(0,$errTxt,$msg."parProdomBlastDb!")if (! defined $parProdomBlastDb);
    return(0,$errTxt,$msg."parProdomBlastN!") if (! defined $parProdomBlastN);
    return(0,$errTxt,$msg."parProdomBlastE!") if (! defined $parProdomBlastE);
    return(0,$errTxt,$msg."parProdomBlastP!") if (! defined $parProdomBlastP);
    return(0,$errTxt,$msg."exeMview!")        if (! defined $exeMview);
    return(0,$errTxt,$msg."parMview!")        if (! defined $parMview);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    $fhTrace="STDOUT"                         if (! defined $fhTrace);

				# ------------------------------
				# check existence of dir|file|exe
    $errTxt="err=4025"; $msg="*** $sbr2: no file=";
    return(0,$errTxt,$msg."fileSeqFasta!")    if (! -e $fileSeqFasta && ! -l $fileSeqFasta);
    $msgHereLoc="";

				# --------------------------------------------------
				# do it
				# --------------------------------------------------
    
    ($Lok,$msg)=
	&prodomRun($fileSeqFasta,$fileProdomTmp,$fileProdom,$fhErrSbr,$nice,
		   $exeBlast,$envProdomBlastDb,$envBlastMat,
		   $parProdomBlastDb,$parProdomBlastN,$parProdomBlastE,$parProdomBlastP);
    if (! $Lok) {
	$msgHereLoc.="*** ERROR $sbr2 after prodomRun \n*** message = ($msg)\n";
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 
	return(2,"err=not fatal",$msgHereLoc); }
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 

				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 
				# note may return val=2 for 'empty header', val=3 for 'none found'
    return(2,"empty prodom","ok")
	if ($Lok > 1);
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 

				# ------------------------------
				# append HTML output
    if ($optOut=~/ret html/ && -e $fileProdom){
				# convert ProDom with Mview
	($Lok,$err,$msg)=
	    &htmlProdom($fileProdomTmp,$fileProdom,$exeMview,$parMview,$optOut,
			$fileProdomHtml,$fileHtmlTmp,$fileHtmlToc,$fhErrSbr);
	if (! $Lok) { 
	    $msg="*** err=2232 ($sbr2: htmlBuild failed on kwd=prodom)\n".$msg."\n";
	    print $fhTrace $msg;
	    return(0,"err=2232",$msg); }}
				# ------------------------------
				# append ASCII
    else {
	($Lok,$msg)=
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppProdom"},
			$fileProdom,$envPP{"fileAppLine"});}
				# yy no error check, do one day!
    return(1,"ok",$msgHereLoc);
}				# end of runProdom

#==========================================================================
sub runProf {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,$dirWork,
	  $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $fileHssp,$exeProfPl,$exeProfFor,$exeProfConv,$exeHtmFil,$exeHtmRef,$exeHtmTop,
#	  $exeConvertSeq,$exeHsspFil,$exeCopf,
	  $parProfOptDef,$paraProf3,$paraProfBoth,$paraProfSec,$paraProfAcc,$paraProfHtm,
	  $paraProfHtmDef,$paraProfHtmMin,$parProfSubsec,$parProfSubacc,$parProfSubhtm,
	  $parProfSubsymbol,$charPerLineMsf,$parProfMinLen,
				# yy beg: for time being
	  $exeProfPhd1994,$exeProfPhd1994For
				# yy end: for time being
	  )=@_;
    local($sbr,$optProf,$opt,$optAdd,$kwd,$kwd2,$tmp,$tmp2,$msg,
	  $msgHere,$command,$Lskip,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   runProf                     runs: prof
#                               
#                               ==================================================
#                               beg: special for PP
#                               
#                               input file MUST be HSSP format
#                               
#                               
#                               
#                               
#                               end: special for PP
#                               ==================================================
#                               
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $envPP{"head*"},$envPP{"abbr*"},
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#--------------------------------------------------------------------------------
    $sbr="runProf";
    $errTxt="err=651"; $msg="*** $sbr: not def ";

    return(0,$errTxt,$msg."origin!")           if (! defined $origin);
    return(0,$errTxt,$msg."date!")             if (! defined $date);
    return(0,$errTxt,$msg."nice!")             if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")        if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                         if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                         if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")          if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")      if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")      if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")      if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")           if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")           if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")           if (! defined $optOut);
    return(0,$errTxt,$msg."fileHssp!")         if (! defined $fileHssp);
    return(0,$errTxt,$msg."exeProfPl!")        if (! defined $exeProfPl);
    return(0,$errTxt,$msg."exeProfFor!")       if (! defined $exeProfFor);
    return(0,$errTxt,$msg."exeProfConv!")      if (! defined $exeProfConv);
    return(0,$errTxt,$msg."exeHtmFil!")        if (! defined $exeHtmFil);
    return(0,$errTxt,$msg."exeHtmRef!")        if (! defined $exeHtmRef);
    return(0,$errTxt,$msg."exeHtmTop!")        if (! defined $exeHtmTop);
#    return(0,$errTxt,$msg."exeConvertSeq!")    if (! defined $exeConvertSeq);
#    return(0,$errTxt,$msg."exeHsspFil!")       if (! defined $exeHsspFil);
#    return(0,$errTxt,$msg."exeCopf!")          if (! defined $exeCopf);
    return(0,$errTxt,$msg."parProfOptDef!")    if (! defined $parProfOptDef);
    return(0,$errTxt,$msg."paraProf3!")        if (! defined $paraProf3);
    return(0,$errTxt,$msg."paraProfBoth!")     if (! defined $paraProfBoth);
    return(0,$errTxt,$msg."paraProfSec!")      if (! defined $paraProfSec);
    return(0,$errTxt,$msg."paraProfAcc!")      if (! defined $paraProfAcc);
    return(0,$errTxt,$msg."paraProfHtm!")      if (! defined $paraProfHtm);
    return(0,$errTxt,$msg."paraProfHtmDef!")   if (! defined $paraProfHtmDef);
    return(0,$errTxt,$msg."paraProfHtmMin!")   if (! defined $paraProfHtmMin);
    return(0,$errTxt,$msg."parProfSubsec!")    if (! defined $parProfSubsec);
    return(0,$errTxt,$msg."parProfSubacc!")    if (! defined $parProfSubacc);
    return(0,$errTxt,$msg."parProfSubhtm!")    if (! defined $parProfSubhtm);
    return(0,$errTxt,$msg."parProfSubsymbol!") if (! defined $parProfSubsymbol);
    return(0,$errTxt,$msg."charPerLineMsf!")   if (! defined $charPerLineMsf);
    return(0,$errTxt,$msg."parProfMinLen!")    if (! defined $parProfMinLen);
#    return(0,$errTxt,$msg."!")  if (! defined $);
#    return(0,$errTxt,$msg."!")  if (! defined $);
				# yy beg: for time being
    return(0,$errTxt,$msg."exeProfPhd1994!")    if (! defined $exeProfPhd1994);
    return(0,$errTxt,$msg."exeProfPhd1994For!") if (! defined $exeProfPhd1994For);
				# yy end: for time being
#    return(0,$errTxt,$msg."!")  if (! defined $);
#    return(0,$errTxt,$msg."!")  if (! defined $);

    $errTxt="err=652"; $msg="*** $sbr: no dir =";
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=653"; $msg="*** $sbr: no file=";
    foreach $file ($filePredTmp,$fileHssp,
		   $paraProf3,$paraProfBoth,$paraProfSec,$paraProfAcc,$paraProfHtm
		   ){
	return(0,$errTxt,$msg."$file!")       if (! -e $file && ! -l $file); }

    $errTxt="err=654"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeProfPl,$exeProfFor,
		  $exeHtmFil,$exeHtmRef,$exeHtmTop,
		  $exeProfConv
#		  $exeCopf,$exeConvertSeq,$exeHsspFil,
		  ) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }
				# check format
    $errTxt="err=655"; $msg="*** $sbr: ";
    return(0,$errTxt,$msg."not   HSSP=$fileHssp!")    if (! &is_hssp($fileHssp));
    return(0,$errTxt,$msg."empty HSSP=$fileHssp!")    if (&is_hssp_empty($fileHssp));

    $msgErrIntern=    $msgErr{"internal"};
    $msgErrProf=      $msgErr{"prof:run"};
    $msgErrCol=       $msgErr{"prof:prof2col"};
    $msgErrMsf=       $msgErr{"prof:prof2msf"};
    $msgErrDssp=      $msgErr{"prof:prof2dssp"};
    $msgErrCasp=      $msgErr{"prof:prof2casp"};
    $msgErrGlobe=     $msgErr{"prof:globe"};

    $fhoutLoc="FHOUT_runProf";

                                # ----------------------------------------
                                # convert Global option flag to local
    if    ($optRun=~/topits/)                           { $optProf="both";} # for topits only sec/acc
    elsif ($optRun=~/profsec/i && $optRun=~/profacc/i
	   && $optRun=~/prof/i )                        { $optProf="3";}
    elsif ($optRun=~/profsec/i && $optRun=~/profacc/i ) { $optProf="both";}
    elsif ($optRun=~/profsec/i)                         { $optProf="sec";}
    elsif ($optRun=~/profacc/i)                         { $optProf="acc";}
    elsif ($optRun=~/profhtm/i)                         { $optProf="htm";}
    else                                                { $optProf=$parProfOptDef;}    # default

				# yy beg: for time being
    $optProf="both"             if ($optProf eq "3");
				# yy end: for time being

                                # ----------------------------------------
				# build up input options
                                # default options for PROF
    $opt ="";
    $opt.=" exeProfFor=$exeProfFor ";
				# yy beg: for time being
#    $opt.=" exeHtmfil=$exeHtmFil exeHtmref=$exeHtmRef exeHtmtop=$exeHtmTop";
    $opt.=" exePhd1994=$exeProfPhd1994 exePhd1994For=$exeProfPhd1994For";
				# yy end: for time being

#    $opt.=" exeConvertSeq=$exeConvertSeq exeCopf=$exeCopf";
    

    $opt.=" para3=$paraProf3 paraBoth=$paraProfBoth";
#    $opt.=" paraSec=$paraProfSec paraAcc=$paraProfAcc paraHtm=$paraProfHtm";
    $opt.=" paraSec=$paraProfSec paraAcc=$paraProfAcc";
    $opt.=" numresMin=$parProfMinLen";
    $opt.=" nresPerLineAli=$charPerLineMsf";
#    $opt.=" riSubSec=$parProfSubsec riSubAcc=$parProfSubacc riSubHtm=$parProfSubhtm";
    $opt.=" riSubSec=$parProfSubsec riSubAcc=$parProfSubacc";
    $opt.=" riSubSym=$parProfSubsymbol";

    $opt.=" dirOut=$dirWork dirWork=$dirWork jobid=$fileJobId";
                                # ----------------------------------------
                                # filenames
    foreach $kwd ("profAscii","profRdb",
				# yy beg temporary: get in again
#		  "profNotHtm",
				# yy end temporary: get in again
		  "screenProf"){
 	$file{$kwd}=            $dirWork.$fileJobId.".".$kwd; push(@kwdRm,$kwd);}

    $opt.=" fileRdb="   .$file{"profRdb"};
				# yy beg temporary: get in again
#    $opt.=" fileNotHtm=".$file{"profNotHtm"};
				# yy end temporary: get in again
	
                                # ----------------------------------------
    $optAdd="";			# further
    if (length($nice)>1)  {	# nice
	$tmp=$nice;$tmp=~s/\s//g;
	$tmp2=$tmp; if ($tmp2 !~/\-/){$tmp2=~s/nice/nice\-/;
				      $tmp=$tmp2;}
	$optAdd.=" optNice=$tmp";}
				# yy beg temporary: get in again
#    $optAdd.=" optDoHtmref=1  optDoHtmtop=1";
				# yy end temporary: get in again
				# --------------------------------------------------
				# minimal 'strength' of HTM to be reported
				# 
				# extract expert options PROFhtm
				#    from extrHdrOneLine:extrHdrExpertProfhtm:
				#    ',parProfhtm(min=n)'
				# --------------------------------------------------
				# yy beg temporary: get in again
#     if    ($optRun=~/(htm|min)=([0-9\.]+)/){
# 	$tmp=$2;}
#     elsif ($optProf eq "htm"){
# 	$tmp=$paraProfHtmMin;}
#     else{
# 	$tmp=$paraProfHtmDef;}
#     $optAdd.=" optHtmisitMin=$tmp";
				# yy end temporary: get in again

				# debug option?
    $optAdd.=" dbg"             if ($Ldebug);
    $optAdd.=" verbose"         if ($Ldebug);

				# ------------------------------
				# final ...

    $cmd="$exeProfPl $fileHssp $optProf $opt $optAdd >> ".$file{"screenProf"};

    $msgHere="";
#    print "--- $sbr system \t '$cmd'\n";

				# ==================================================
				# running PROF
    ($Lok,$msgSys)=&sysSystem("$cmd",$fhOutSbr);
				# ==================================================

                                # ----------------------------------------
                                # security check for existence of pred file
                                # ----------------------------------------
    return(0,"err=661",$msgErrProf."\n"."*** ERROR $sbr: not defined RDB file(profRdb) after PROF\n".
	   "msgSys=$msgSys\n")
	if (! $Lok || ! defined $file{"profRdb"});
    return(0,"err=661",$msgErrProf."\n"."*** ERROR $sbr: no RDB file=".$file{"profRdb"}."! after PROF\n".
	   "msgSys=$msgSys\n")
	if (! $Lok || ! -e $file{"profRdb"});

                                # ------------------------------
                                # correct local if no membrane
    $optProf="both"             if ( $optProf eq "3" && 
				    defined $file{"profNotHtm"} &&  -e $file{"profNotHtm"} );
	
                                # ----------------------------------------
				# run GLOBE (note: only if NOT htm!)
                                # ----------------------------------------
    $globeOut=0;
    if ($optProf eq "acc" || 
	$optProf eq "both") {   # note '3' do NOT run if membrane region detected!
	$file{"globeProf"}=     $dirWork.$fileJobId.".globeProf";push(@kwdRm,"globeProf");
	$msgHere.="--- $sbr calling \&globeOne(".$file{"profRdb"}.",$fhErrSbr)\n";
				# security erase
	unlink($file{"globeProf"})  if (-e $file{"globeProf"});
				# ------------------------------
				# run GLOBE
				# out : 1  $len
				#       2  $numExposed
				#       3  $numExpect
				#       4  $globeProfDiff
				#       5  $evaluation
				#       6  $globeProfNorm
				#       7  $globeProfProb,
				#       8  $segRatio
				#       9  $LisGlobular
				#       10 $evaluationCombi
				# in  : option 'noseg' -> no
				#       run of SEG
				# ------------------------------
	($Lok,$msg,@tmpGlobe)=
	    &globeOne($file{"profRdb"},$fhErrSbr,"noseg");
				# ------------------------------
				# error (not fatal!)
	$msgHere.="err=672".$msgErrGlobe."\n".$msg."\n" 
	    if (! $Lok);
				# --------------------
	if ($Lok){		# write output text
	    $nexpTxt=sprintf("%5d   ",int($tmpGlobe[2]));
	    $nfitTxt=sprintf("%5d   ",int($tmpGlobe[3]));
	    $diffTxt=sprintf(" %7.2f",$tmpGlobe[4]);
				# final text
	    $globeOut ="--- \n";
	    $globeOut.="--- GLOBE: prediction of protein globularity\n";
	    $globeOut.="--- \n";
	    $globeOut.="--- nexp = $nexpTxt (number of predicted exposed residues)\n";
	    $globeOut.="--- nfit = $nfitTxt (number of expected exposed residues\n";
	    $globeOut.="--- diff = $diffTxt (difference nexp-nfit)\n";
	    $globeOut.="--- =====> $tmpGlobe[5]\n";
	    $globeOut.="--- \n";
	    $globeOut.="--- \n";
	    $globeOut.="--- GLOBE: further explanations preliminaryily in:\n";
	    $globeOut.="---        http://www.columbia.edu/~rost/Papers/98globe.html\n";
	    $globeOut.="--- \n";$globeOut.="--- END of GLOBE\n";
#	    $msgHere.="--- $sbr '$globeOut'\n"; 
#	    print $fhOutSbr "--- $sbr (GLOBE out): \n$globeOut\n";
	    open($fhoutLoc,">>".$file{"globeProf"});
	    print $fhoutLoc $globeOut;
	    close($fhoutLoc);
	}}
				# ------------------------------
				# now convert to ASCII
				# ------------------------------
    $kwd="profAscii";
    $file{$kwd}=                $dirWork.$fileJobId.".".$kwd;push(@kwdRm,$kwd);

    $command="$nice $exeProfConv ".$file{"profRdb"}." ascii nohtml fileOut=".$file{$kwd};
				# add GRAPH
    if ($origin=~/^mail|^html|^testPP/i && 
	$optOut=~/ret prof gr/            ){

	$kwd2="profRetKg";
	$file{$kwd2}=$file{$kwd}; push(@kwdRm,$kwd2);
	$command.=" graph";
    }
    else {
	$command.=" nodet nograph";}
	
    $msgHere.="--- $sbr system '$command'\n";
    ($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);

    return(0,"err=662",$msgErrProf."\n"."*** ERROR $sbr: no ASCII file after\n".
	   $msgHere)            if (! $Lok || ! -e $file{"profAscii"});

				# ------------------------------
				# (1) append standard PROF results
				# ------------------------------
    if ($origin=~/^mail|^html|^testPP/i){

				# append <<< --------------------
	($Lok,$msg)=		# save what you have so far
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppPredProf"},$file{"profAscii"},$envPP{"fileAppLine"});
	return(0,"err=673",$msgErrProf."\n"."$msg\n") if (! $Lok);

				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
				# first add references
	    $html{"flag_method","prof_sec"}=1 if ($optProf=~/sec|both|3/);
	    $html{"flag_method","prof_acc"}=1 if ($optProf=~/acc|both|3/);
	    $html{"flag_method","prof_htm"}=1 if ($optProf=~/htm|3/);
	    $Lok=0;
				# 1st: try neat conversion
	    if (defined $file{"profRdb"} &&  -e $file{"profRdb"}) {
		$file{"profHtml"}=$dirWork.$fileJobId.".html_prof"; push(@kwdRm,"profHtml");
		$modewrt="html:body,data:brief,data:normal";
		$modewrt.=",data:detail"
		    if ($optOut=~/ret html detail/);
		$cmd= "$exeProfConv ".$file{"profRdb"}." html noascii fileOut=".$file{"profHtml"};
				# paraProfmeter
		$cmd.=" parHtml=$modewrt";
				# number of lines per row
		$cmd.=" nresPerRow=$1" if ($optOut=~/perline=(\d+)/);
		($Lok,$msgSys)=&sysSystem("$cmd",$fhOutSbr); 
		$fileTmp=$file{"profHtml"}; $preTmp=0;}

				# 2nd: try to <PRE> it
	    if (! $Lok) {
		$fileTmp=$file{"profAscii"}; $preTmp=1;}

				# now add to HTML
	    ($Lok,$msg)=&htmlBuild($fileTmp,$fileHtmlTmp,$fileHtmlToc,$preTmp,"prof_body");

	    if (! $Lok) { $msg="*** err=2301 ($sbr: htmlBuild failed on kwd=prof_body)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2301",$msg); }}}

				# ------------------------------
				# (2) append results from GLOBE
				# ------------------------------
    if ($origin=~/^mail|^html|^testPP/i && ($globeOut ne "0")){
				# append <<< --------------------
	($Lok,$msg)=		# save what you have so far
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppGlobe"},$file{"globeProf"});
	return(0,"err=624",$msgErrProf."\n"."$msg\n") if (! $Lok);
				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"globeProf"},$fileHtmlTmp,$fileHtmlToc,1,"globe");
	    if (! $Lok) { $msg="*** err=2302 ($sbr: htmlBuild failed on kwd=globeProf)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2302",$msg); }}}


				# --------------------------------------------------
				# return options: if 'ret prof :msf|casp2|col|graph|mach|rdb]'
				#                 option there MUST be an RDB
				# --------------------------------------------------
    if ($origin=~/^mail|^html|^testPP/i &&
	$optOut =~ /ret prof\s*[mcgr]/  &&
	! -e $file{"profRdb"}){
	return(0,"err=612",$msgErrProf."\n"."*** ERROR $sbr: no RDB file after\n".$msgHere); }
                                # ------------------------------
				# convert to dssp if topits
                                # ------------------------------
    if ($optRun =~/topits/){
	$kwd="profDssp";
	$file{$kwd}=          $dirWork.$fileJobId.".".$kwd;push(@kwdRm,$kwd);
	$command="$nice $exeProfConv ".$file{"profRdb"}." dssp noascii nohtml fileOut=".$file{$kwd};
	$msgHere.="--- $sbr system '$command'\n";
	($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
	$file{"phdDssp"} = $file{"profDssp"};
	if (! $Lok || ! -e $file{$kwd}){
	    $msgHere.="--- WARN $sbr prof2dssp failed\n"."$msgErrDssp\n";}}

                                # ------------------------------
				# Option: ret prof col
				# ------------------------------
    if ($origin=~/^mail|^html|^testPP/i && 
	$optOut=~/ret prof col/){
	$kwd="profRetCol";
	$file{$kwd}=            $dirWork.$fileJobId.".".$kwd;push(@kwdRm,"$kwd");
	$msgHere.="--- $sbr convProf2col(".$file{"profRdb"}.",".$file{$kwd}.",)\n";
	($Lok,$msg)=
	    &convPhd2col($file{"profRdb"},$file{$kwd},$optProf);
	if (! $Lok || ! -e $file{$kwd}){
	    $msgHere.="*** WARN $sbr after convProf2col:\n".
		$msgErrCol."\n"."*** WARN $sbr msg=\n$msg\n";}
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppRetProfCol"},$file{$kwd},$envPP{"fileAppLine"});
	if (! $Lok ){
	    $msgHere.="*** WARN $sbr after convProf2col (cat):\n".
		$msgErrIntern."\n"."*** WARN $sbr msg=\n$msg\n";}
				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"profRetCol"},$fileHtmlTmp,$fileHtmlToc,1,"prof_col");
	    if (! $Lok) { $msg="*** err=2303 ($sbr: htmlBuild failed on kwd=prof_col)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2303",$msg); }}}

                                # ------------------------------
				# Option: ret prof msf
                                # ------------------------------
    if ($optOut=~/ret prof (msf|saf)/){
	$formatWantTmp=$1;
	$Lskip=        0;
	$kwd=          "profRetAli";
	$file{$kwd}=            $dirWork.$fileJobId.".".$kwd; push(@kwdRm,$kwd);
	$kwd2="aliMsf"          if ($formatWantTmp =~ /msf/);
	$kwd2="aliSaf"          if ($formatWantTmp =~ /saf/);
	$tmp=                   $dirWork.$fileJobId.".".$kwd2;push(@kwdRm,$kwd2);
	$file{$kwd2}=           $dirWork.$fileJobId.".".$kwd2;
				# convert PROF to ali
	$command= "$nice $exeProfConv ".$file{"profRdb"}."  $formatWantTmp nohtml noascii";
	$command.=" fileAli=".$fileHssp." fileOut=".$file{$kwd}." nresPerRow=$charPerLineMsf dbg";
#	$command.=" fileAli=".$file{$kwd2}." fileOut=".$file{$kwd}." nresPerRow=$charPerLineMsf dbg";
#	$command.=" extHssp=.aliMsf";
#	$command.=" fileAli=".$file{$kwd2}." fileOut=".$file{$kwd}." nresPerRow=$charPerLineMsf";
	$msgHere.="--- $sbr system '$command'\n";
	($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
				# ERROR?
	if    (! $Lok){
	    $msgHere.="*** WARN $sbr after $exeProfConv Lok=$Lok, msg=$msgSys\n".
		"*** file($kwd)=".$file{$kwd}."!\n".$msgErrMsf."\n";}
	elsif (! defined $file{$kwd}){
	    $msgHere.=
		"*** WARN $sbr after $exeProfConv file($kwd) not defined!\n".$msgErrMsf."\n";}
	elsif (! -e $file{$kwd}){
	    $msgHere.=
		"*** WARN $sbr after $exeProfConv missing fileOut($kwd)=".$file{$kwd}."!\n".
		    $msgErrMsf."\n";}

	if (-e $file{$kwd} && ($origin=~/^mail|^html|^testPP/i) ){
	    $fileAppTmp=$envPP{"fileAppRetProfMsf"} if ($formatWantTmp =~ /msf/);
	    $fileAppTmp=$envPP{"fileAppRetProfSaf"} if ($formatWantTmp =~ /saf/);
	    ($Lok,$msg)=	# append <<< --------------------
		&sysCatfile("nonice",$Ldebug,$filePredTmp,$fileAppTmp,
			    $file{$kwd},$envPP{"fileAppLine"})}
				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"profRetAli"},$fileHtmlTmp,$fileHtmlToc,1,"prof_".$formatWantTmp);
	    if (! $Lok) { $msg="*** err=2304 ($sbr: htmlBuild failed on kwd=prof_".
			      $formatWantTmp.")\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2304",$msg); }}}

                                # ------------------------------
				# Option: ret prof casp
                                # ------------------------------
    if ($origin=~/^mail|^html|^testPP/i &&
	$optOut=~/ret prof casp/){
	$kwd="profRetCasp";
	$file{$kwd}=          $dirWork.$fileJobId.".".$kwd;push(@kwdRm,"$kwd");
				# (1) read NALIGN
	$fhin="FHIN_".$sbr."_READ_HSSP";
	open($fhin,$fileHssp)  || warn "*** $sbr: cannot open fileHssp=$fileHssp!\n";
	while(<$fhin>){$tmp=$_;	    
		       last if ($_=~/^NALIGN/);}close($fhin);
	$nali=$tmp;$nali=~s/^NALIGN\s+//g;$nali=~s/\s//g;$nali=~s/[^0-9]//g;
				# (2) run exeProf2casp
	$command= "$nice $exeProfConv ".$file{"profRdb"};
	$command.=" casp fileOutCasp=".$file{$kwd}." nohtml noascii";
	    
	$msgHere.="--- $sbr system '$command'\n";
	($Lok,$msgSys)=&sysSystem("$command",$fhOutSbr);
	$msgHere.="*** WARN $sbr after $exeProfConv no fileOut($kwd)=".$file{$kwd}."!\n".$msgErrCasp."\n"
	    if (! $Lok || ! -e $file{$kwd});
	    
	if (-e $file{$kwd}){
	    ($Lok,$msg)=	# append <<< --------------------
		&sysCatfile("nonice",$Ldebug,$filePredTmp,
			    $envPP{"fileAppRetProfCasp"},$file{$kwd});}}

				# ------------------------------
				# Option: ret prof rdb
				# ------------------------------
    if ($origin=~/^mail|^html|^testPP/i &&
	$optOut=~/ret prof rdb/){
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppRetProfRdb"},$file{"profRdb"});
				# ------------------------------
				# append HTML output
	if ($optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"profRdb"},$fileHtmlTmp,$fileHtmlToc,1,"prof_rdb");
	    if (! $Lok) { $msg="*** err=2305 ($sbr: htmlBuild failed on kwd=prof_rdb)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2305",$msg); }}}
    return(1,"ok",$msgHere);
}				# end of runProf

#===============================================================================
sub runProsite {
    local($fileSeq,$fileSeqGCG,$fileSeqProsite,$filePrositeData,
	  $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$optOut,
	  $exeCopf,$exeConvertSeq,$exeProsite,
	  $nice,$fileJobId,$fhErrSbr,$dirWork,$Ldebug,$fhTrace) = @_ ;
    local($sbr2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runProsite                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbr2="runProsite";
				# ------------------------------
				# consistency check of input
    $errTxt="err=4011"; $msg="*** $sbr2: not def ";
    return(0,$errTxt,$msg."fileSeq!")         if (! defined $fileSeq);
    return(0,$errTxt,$msg."fileSeqGCG!")      if (! defined $fileSeqGCG);
    return(0,$errTxt,$msg."fileSeqProsite!")  if (! defined $fileSeqProsite);
    return(0,$errTxt,$msg."filePrositeData!") if (! defined $filePrositeData);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeCopf!")         if (! defined $exeCopf);
    return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);
    return(0,$errTxt,$msg."exeProsite!")      if (! defined $exeProsite);

    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    $fhTrace="STDOUT"                         if (! defined $fhTrace);
#    return(0,$errTxt,$msg."!")       if (! defined $);

				# ------------------------------
				# check existence of dir|file|exe
    $errTxt="err=4021"; $msg="*** $sbr2: no file=";
    return(0,$errTxt,$msg."fileSeq!")         if (! -e $fileSeq && ! -l $fileSeq);
    return(0,$errTxt,$msg."filePrositeData!") if (! -e $filePrositeData && 
						  ! -l $filePrositeData);
    $msgHereLoc="";
				# ------------------------------
				# security erase
    unlink($fileSeqProsite)     if (-e $fileSeqProsite);

				# --------------------------------------------------
				# do it
				# --------------------------------------------------

				# convert to GCG
    $LdoExpandLoc=0;
    ($Lok,$msg)=
	&copfLocal($fileSeq,$fileSeqGCG,0,"gcg",$LdoExpandLoc,
		   $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr,$fhErrSbr);
				# conversion failed!
    if ( ! $Lok || ! -e $fileSeqGCG){
	print $fhErrSbr 
	    "*** $sbr2: fault in copf\n".$msg."\n".$msgHere."\n";
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 
	return(2,"err=not fatal","*** $sbr2: failed copf ($fileSeq -> $fileSeqGcg = GCG?)"); }
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 

				# ------------------------------
				# run PROSITE
				# conversion appears ok: add command that did run
    $msgHereLoc.="\n".$msg."\n" if (! $Ldebug);
				# build up Prosite command
    $cmd= $nice." ".$exeProsite;
				# return HTML from ProSite
    $cmd.=" -h"                 if ($optOut=~/ret html/);
		
    $cmd.=" ".$filePrositeData;
    $cmd.=" ".$fileSeqGCG;
    $cmd.=" >> ".$fileSeqProsite;
    $msgHereLoc.="\n--- $sbr2 \t call prosite:\n--- system: \t ".$cmd."\n";
		

    ($Lok,$msgSys)=&sysSystem("$cmd");

    if (! -e $fileSeqProsite) {
	print $fhErrSbr 
	    "*** $sbr2: fault in prosite ($exeProsite)\n".$msgHereLoc."\n";
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 
	return(2,"err=not fatal",$msgHereLoc); }
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 
	    
				# ------------------------------
				# append HTML output
    if    ($optOut=~/ret html/){
				# append file
	($Lok,$msg)=
	    &htmlBuild($fileSeqProsite,$fileHtmlTmp,$fileHtmlToc,0,"prosite");
	if (! $Lok) { 
	    $msg="*** err=2231 ($sbr2: htmlBuild failed on kwd=prosite)\n".$msg."\n";
	    print $fhTrace $msg;
	    return(0,"err=2231",$msg); } }
				# ------------------------------
				# append ASCII
    else {
	($Lok,$msg)=
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppProsite"},
			$fileSeqProsite,$envPP{"fileAppLine"}); }
				# yy no error check, do one day!
    return(1,"ok",$msgHereLoc);
}				# end of runProsite

#===============================================================================
sub runSegnorm {
    local($fileSeqFasta,$fileSegNorm,
	  $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$optOut,
	  $exeSeg,$parSeg,$parSegNormMin,
	  $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,
	  $nice,$fhErrSbr,$Ldebug,$fhTrace) = @_ ;
    local($sbr2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runSegnorm                  run SEG for low-complexity marking
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbr2="runSegnorm";
				# ------------------------------
				# consistency check of input
    $errTxt="err=4012"; $msg="*** $sbr2: not def ";
    return(0,$errTxt,$msg."fileSeqFasta!")    if (! defined $fileSeqFasta);
    return(0,$errTxt,$msg."fileSegNorm!")     if (! defined $fileSegNorm);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeSeg!")          if (! defined $exeSeg);
    return(0,$errTxt,$msg."parSeg!")          if (! defined $parSeg);
    return(0,$errTxt,$msg."parSegNormMin!")   if (! defined $parSegNormMin);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    $fhTrace="STDOUT"                         if (! defined $fhTrace);
				# ------------------------------
				# check existence of dir|file|exe
    $errTxt="err=4022"; $msg="*** $sbr2: no file=";
    return(0,$errTxt,$msg."fileSeqFasta!")    if (! -e $fileSeqFasta && ! -l $fileSeqFasta);
    $errTxt="err=4042"; $msg="*** $sbr2: no exe =";
    return(0,$errTxt,$msg."exeSeg!")          if (! -e $exeSeg && ! -l $exeSeg);
    $msgHereLoc="";

				# ------------------------------
				# security erase
    unlink($fileSegNorm)        if (-e $fileSegNorm);

				# --------------------------------------------------
				# do it
				# --------------------------------------------------

				# build up Segnorm command
    $cmd= $nice." ".$exeSeg." ".$fileSeqFasta." ".$parSeg;
    $cmd.=" >> ".$fileSegNorm;
    $msgHereLoc.="\n--- $sbr2 \t call seg:\n--- system: \t ".$cmd."\n";
				# run SEGNORM
    ($Lok,$msgSys)=&sysSystem("$cmd");

    if (! -e $fileSegNorm) {
	print $fhErrSbr 
	    "*** $sbr2: fault in segNorm ($exeSeg)\n".$msgHereLoc."\n";
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 
	return(2,"err=not fatal",$msgHereLoc); }
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** <*** 

				# how many found?
    ($Lok,$msg,$lenAll,$lenLow)=
	&segInterpret($fileSegNorm);
				# <--- <--- <--- <--- <--- <--- <--- <--- <--- <--- 
    return(3,"SEG: nothing to write home about",$msgHereLoc,$lenLow)
	if ($lenLow < $parSegNormMin);
				# <--- <--- <--- <--- <--- <--- <--- <--- <--- <--- 


				# --------------------------------------
				# convert to GCG format for nicer output
    $LdoExpandLoc=0;
    $file{"segGcg"} = $dirWork.$fileJobId.".segNormGcg";
    push(@kwdRm,"segGcg");

    ($Lok,$msg)=
	&copfLocal($fileSegNorm,$file{"segGcg"},0,"gcg",$LdoExpandLoc,
		   $exeCopf,$exeConvertSeq,$dirWork,$fileJobId,$nice,$Ldebug,$fhErrSbr);
				# conversion failed!
    return(0,"err=410",$msgErrConvert."\n".
	   "*** $sbr2: fault in copf\n".$msg."\n") if (! $Lok); 

				# ------------------------------
				# append HTML output
    if ($optOut=~/ret html/ && -e $fileSegNorm){
				# append file (PRE)
	($Lok,$msg)=
	    &htmlBuild($file{"segGcg"},$fileHtmlTmp,$fileHtmlToc,1,"seg_norm");
	if (! $Lok) { 
	    $msg="*** err=2234 ($sbr: htmlBuild failed on kwd=seg_norm)\n".$msg."\n";
	    print $fhTrace $msg;
	    return(0,"err=2234",$msg); } }
				# ------------------------------
    else {			# append ASCII
	($Lok,$msg)=
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppSegNorm"},
			$file{"segGcg"},$envPP{"fileAppLine"}); }
				# yy no error check, do one day!
    return(1,"ok",$msgHereLoc,$lenLow,$lenAll);
}				# end of runSegnorm

#==========================================================================================
sub runTopits {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,$dirWork,
	  $filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,$filePhdDssp,$dirDssp,
	  $exeConvertSeq,$exeMax,$exeHsspFilter,$exeHsspFilterFor,
	  $exeHsspExtrStrip,$exeHsspExtrStripPP,
	  $exeHssp2pir,$exeTopits,$exeTopitsMaxCsh,$exeTopitsMakeMetr,
#	  $exeTopitsWrtOwn,
	  $exePhdFor,
	  $dirTopits,$fileTopitsDefaults,$fileTopitsMaxDef,$fileTopitsAliList,
	  $fileTopitsMetrSeq,$fileTopitsMetrSeqAll,$fileTopitsMetrGCG,
	  $fileTopitsMetrIn,$parTopitsLindel1,
	  $parTopitsSmax,$parTopitsGo,$parTopitsGe,$parTopitsMixStrSeq,$parTopitsNhits,
	  $exeMview,$parMview)=@_;
    local($sbr,$msgHere,$txt,$msgErrIntern,$optExpGo,$optExpSmax,$optExpNhits,$optExpMix,$arg,$kwd,
	  $tmp,$cmd,$Lok,%rdHssp,@strip);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   runTopits                   prediction-based threading, call perl script             
#--------------------------------------------------------------------------------
    $sbr="runTopits";

    $ex="err=701"; $msg="*** $sbr: not def ";
    return(0,$ex,$msg."origin!")              if (! defined $origin);
    return(0,$ex,$msg."date!")                if (! defined $date);
    return(0,$ex,$msg."nice!")                if (! defined $nice);
    return(0,$ex,$msg."fileJobId!")           if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$ex,$msg."dirWork!")             if (! defined $dirWork);
    return(0,$ex,$msg."fileHtmlTmp!")         if (! defined $fileHtmlTmp);
    return(0,$ex,$msg."fileHtmlToc!")         if (! defined $fileHtmlToc);
    return(0,$ex,$msg."filePredTmp!")         if (! defined $filePredTmp);
    return(0,$ex,$msg."Ldebug!")              if (! defined $Ldebug);
    return(0,$ex,$msg."optRun!")              if (! defined $optRun);
    return(0,$ex,$msg."optOut!")              if (! defined $optOut);
    return(0,$ex,$msg."filePhdDssp!")         if (! defined $filePhdDssp);
    return(0,$ex,$msg."dirDssp!")             if (! defined $dirDssp);
    return(0,$ex,$msg."exeConvertSeq!")       if (! defined $exeConvertSeq);
    return(0,$ex,$msg."exeMax!")              if (! defined $exeMax);
    return(0,$ex,$msg."exeHsspFilter!")       if (! defined $exeHsspFilter);
    return(0,$ex,$msg."exeHsspFilterFor!")    if (! defined $exeHsspFilterFor);
    return(0,$ex,$msg."exeHsspExtrStrip!")    if (! defined $exeHsspExtrStrip);
    return(0,$ex,$msg."exeHsspExtrStripPP!")  if (! defined $exeHsspExtrStripPP);
    return(0,$ex,$msg."exeHssp2pir!")         if (! defined $exeHssp2pir);
    return(0,$ex,$msg."exeTopits!")           if (! defined $exeTopits);
    return(0,$ex,$msg."exeTopitsMaxCsh!")     if (! defined $exeTopitsMaxCsh);
    return(0,$ex,$msg."exeTopitsMakeMetr!")   if (! defined $exeTopitsMakeMetr);
#    return(0,$ex,$msg."exeTopitsWrtOwn!")     if (! defined $exeTopitsWrtOwn);
    return(0,$ex,$msg."exePhdFor!")           if (! defined $exePhdFor);
    return(0,$ex,$msg."dirTopits!")           if (! defined $dirTopits);
    return(0,$ex,$msg."fileTopitsDefaults!")  if (! defined $fileTopitsDefaults);
    return(0,$ex,$msg."fileTopitsMaxDef!")    if (! defined $fileTopitsMaxDef);
    return(0,$ex,$msg."fileTopitsAliList!")   if (! defined $fileTopitsAliList);
    return(0,$ex,$msg."fileTopitsMetrSeq!")   if (! defined $fileTopitsMetrSeq);
    return(0,$ex,$msg."fileTopitsMetrSeqAll!")if (! defined $fileTopitsMetrSeqAll);
    return(0,$ex,$msg."fileTopitsMetrGCG!")   if (! defined $fileTopitsMetrGCG);
    return(0,$ex,$msg."fileTopitsMetrIn!")    if (! defined $fileTopitsMetrIn);
    return(0,$ex,$msg."parTopitsLindel1!")    if (! defined $parTopitsLindel1);
    return(0,$ex,$msg."parTopitsSmax!")       if (! defined $parTopitsSmax);
    return(0,$ex,$msg."parTopitsGo!")         if (! defined $parTopitsGo);
    return(0,$ex,$msg."parTopitsGe!")         if (! defined $parTopitsGe);
    return(0,$ex,$msg."parTopitsMixStrSeq!")  if (! defined $parTopitsMixStrSeq);
    return(0,$ex,$msg."parTopitsNhits!")      if (! defined $parTopitsNhits);
    return(0,$ex,$msg."exeMview!")            if (! defined $exeMview);
    return(0,$ex,$msg."parMview!")            if (! defined $parMview);

    $ex="err=702"; $msg="*** $sbr: no dir =";
    return(0,$ex,$msg."$dirWork!")            if (! -d $dirWork);
    return(0,$ex,$msg."$dirTopits!")          if (! -d $dirTopits);
    
    $ex="err=703"; $msg="*** $sbr: no file=";
    foreach $file ($filePredTmp,$filePhdDssp,
		   $fileTopitsDefaults,$fileTopitsMaxDef,$fileTopitsAliList,
		   $fileTopitsMetrSeq,$fileTopitsMetrGCG,$fileTopitsMetrIn) {
	return(0,$ex,$msg."$file!")           if (! -e $file && ! -l $file); }

    $ex="err=704"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeConvertSeq,$exeMax,$exeHsspFilter,$exeHsspFilterFor,
		  $exeHsspExtrStrip,$exeHsspExtrStripPP,
		  $exeHssp2pir,$exeTopits,$exeTopitsMaxCsh,$exeTopitsMakeMetr,
		  $exePhdFor) {
	return(0,$ex,$msg."$exe!")            if (! -e $exe && ! -l $exe); }

    $msgErrIntern=    $msgErr{"internal"};
    $msgHere="--- $sbr started\n";

    				# ------------------------------
				# local copy of default file
    if (! defined $file{"maxDef"} || ! -e $file{"maxDef"}){
	$file{"maxDef"}=        $dirWork."maxhom_default_".$fileJobId;push(@kwdRm,"maxDef");
	($Lok,$msg)=
	    &maxhomMakeLocalDefault($fileTopitsMaxDef,$file{"maxDef"},$dirWork);
	return(0,"err=707",$msgErrIntern."\n"."$msg"."\n"."$msgHere") if (! $Lok);}

				# --------------------------------------------------
				# extract expert options TOPITS
				#    from extrHdrOneLine:extrHdrExpertTopits:
				#    ',parTopits(mix=n nhits=n smax=n go=n ge=n mat=MAT)'
				# --------------------------------------------------
    $optExpGo=       $parTopitsGo;
    $optExpGe=       $parTopitsGe;     
    $optExpNhits=    $parTopitsNhits;    
    $optExpMix=      $parTopitsMixStrSeq;
    $optExpSmax=     $parTopitsSmax;
    $optExpMatSeq=   $fileTopitsMetrSeq; 
    $optExpMatSeqAll=$fileTopitsMetrSeqAll; 

    if ($optRun=~/parTopits/){
	if ($optRun=~/go=([0-9\.]+)/)          { $optExpGo=    $1;}
	if ($optRun=~/ge=([0-9\.]+)/)          { $optExpGe=    $1;}
	if ($optRun=~/smax=([0-9\.]+)/)        { $optExpSmax=  $1;}
	if ($optRun=~/nhits=([0-9\.]+)/)       { $optExpNhits= $1;}
	if ($optRun=~/mix=([0-9\.]+)/)         { $optExpSmax=  $1;}
	if ($optRun=~/mat=([A-Za-z0-9\-\_]+)/) { 
	    $optExpMatSeq=$1;
	    $optExpMatSeq=~s/blossum/blosum/; # just security for typos
				# search all possible metrices
				#    will return the file matching the keyword
				#    from the list of $fileTopitsMetrSeqAll
	    ($Lok,$tmp,$optExpMatSeq)=
		&getFileFromArray($optExpMatSeq,1,$fileTopitsMetrSeqAll);
	    $optExpMatSeq=$fileTopitsMetrSeq if (! $Lok || ! $optExpMatSeq); }
				# corrections
	$optExpGo=    $parTopitsGo        if ($optExpGo    <=1 || $optExpGo    >= 100);
	$optExpGe=    $parTopitsGe        if ($optExpGe    <=0 || $optExpGe    >= 100);
	$optExpSmax=  $parTopitsSmax      if ($optExpSmax  <=0 || $optExpSmax  >= 100);
	$optExpNhits= $parTopitsNhits     if ($optExpNhits < 1 || $optExpNhits >=2000);
	$optExpMix=   $parTopitsMixStrSeq if ($optExpMix   < 0 || $optExpMix   >  100);
    }				# end of expert options

				# ------------------------------
				# now prepare running it
				# ------------------------------
    $arg= " $filePhdDssp dirWork=$dirWork dirOut=$dirWork titleOut=$fileJobId jobid=$fileJobId";
    $arg.=" defaults=$fileTopitsDefaults defaultsMaxhom=".$file{"maxDef"}." dirTopits=$dirTopits";

    $arg.=" exeMaxhom=$exeMax exeMaxhomTopits=$exeTopitsMaxCsh exeMakeMetric=$exeTopitsMakeMetr";
    $arg.=" exeHsspFilter=$exeHsspFilter exeHsspFilterFor=$exeHsspFilterFor";
    $arg.=" exeHsspExtrStrip=$exeHsspExtrStrip exeHssp2pir=$exeHssp2pir";
#    $arg.=" exeConvertSeq=$exeConvertSeq";
    $arg.=" exePhdFor=$exePhdFor";

    $arg.=" dirDssp=$dirDssp";
    $arg.=" fileMetricGCG=$fileTopitsMetrGCG fileMetricIn=$fileTopitsMetrIn";
    $arg.=" Lindel1=$parTopitsLindel1";
    $arg.=" smax=$optExpSmax go=$optExpGo ge=$optExpGe nhitsSel=$optExpNhits mixStrSeq=$optExpMix";
    $arg.=" fileMetricSeq=$optExpMatSeq";
    $arg.=" aliList=$fileTopitsAliList";

				# ------------------------------
                                # filenames
    foreach $kwd ("hsspTopits","stripTopits","stripTopitsPP","xTopits","screenTopits",
		  "headerTopits","msfTopits","topits"){
	$file{$kwd}=          $dirWork.$fileJobId.".$kwd"; push(@kwdRm,"$kwd");}

    $arg.=" fileHsspTopits=".$file{"hsspTopits"}." fileStripTopits=".$file{"stripTopits"};
    $arg.=" fileXhssp=".$file{"xTopits"}." jobid=".$$." ";
				# finally nice
    if ($nice =~/nice/){$tmp=$nice;$tmp=~s/\s*nice\s*//g;
			 $arg.=" opt_nice=$tmp ";}

                                # ========================================
				# now run it
                                # ========================================
#    $cmd="$exeTopits $arg ";	
#    $cmd="$exeTopits $arg  dbg >> ".$file{"screenTopits"};
#    $cmd="$exeTopits $arg  dbg ";
    $cmd="$exeTopits $arg >> ".$file{"screenTopits"};
#    $msgHere.="--- $sbr system \t '$cmd'\n";
#    print $fhOutSbr "--- $sbr system \t $cmd\n";

#    $cmd="$exeTopits $arg  dbg >> x.tmp " if ($User_name =~/^rost/);

				# ======================================
    
    ($Lok,$msgSys)=&sysSystem("$cmd",$fhOutSbr);

				# ======================================

                                # ----------------------------------------
                                # security check for existence of pred file
                                # ----------------------------------------
    return(0,"err=711","*** ERROR $sbr: no HSSP file (".$file{"hsspTopits"}.
	   ")after TOPITS\n".$msgHere) if (! -e $file{"hsspTopits"});
    return(0,"err=712","*** ERROR $sbr: empty HSSP file (".$file{"hsspTopits"}.
	   ")after TOPITS\n".$msgHere) if (&is_hssp_empty($file{"hsspTopits"}));
				# ------------------------------
				# interactive run => go home
    return(1,"ok","$sbr") if ($origin!~/^mail|^html|^testPP/i);

				# --------------------------------------------------
				# standard TOPITS output 
				#    PP specific: merge HSSP and STRIP header
				# --------------------------------------------------
    if (-e $file{"stripTopits"}){
	$Lok=1;}
    else {$Lok=0;
	  $msgHere.="$sbr missing strip file (".$file{"stripTopits"}.")\n";}
				# --------------------
    if ($Lok){			# read HSSP header
	($Lok,$txt,%rdHssp)=
	    &ppHsspRdExtrHeader($file{"hsspTopits"});
	$msgHere.="$sbr:ppHsspRdExtrHeader returned 0\n$txt\n" if (! $Lok);}
				# --------------------
    if ($Lok){			# convert strip to PPstrip
	$cmd =" $exeHsspExtrStripPP ".$file{"stripTopits"};
	$cmd.=" fileOut=".$file{"stripTopitsPP"};
	$cmd.=" incl=1-$optExpNhits mix=$optExpMix noScreen";

	print $fhOutSbr "--- $sbr system \t '$cmd'\n" if ($Ldebug);
	$msgHere.="--- $sbr system \t '$cmd'\n";
	($Lok,$msgSys)=
	    &sysSystem($cmd,$fhOutSbr);
	$Lok=0                 if (! -e $file{"stripTopitsPP"});
	$msgHere.="$sbr: $exeHsspExtrStripPP returned no outfile=".
	    $file{"stripTopitsPP"}.",\n"
		if (! $Lok);}
				# --------------------
    if ($Lok){			# read entire STRIP (hey this is stupid!)
	($Lok,$txt,@strip)=
	    &ppStripRd($file{"stripTopitsPP"});
	$msgHere.="$sbr:ppStripRd returned 0\n$txt\n" if (! $Lok);}
				# --------------------
    if ($Lok){			# write new header 
	($Lok,$txt)=		# !!! uses same GLOBAL variable as ppHsspRdExtrHeader=rd_hssp
	    &ppTopitsHdWrt($file{"headerTopits"},$optExpMix,@strip);
	$msgHere.="$sbr:ppTopitsHdWrt returned 0\n$txt\n" if (! $Lok);
	$msgHere.="$sbr no file headerTopits (".$file{"headerTopits"}.
	    ") after 'ppTopitsHdWrt'\n" if (! -e $file{"headerTopits"});}

				# --------------------------------------------------
				# convert HSSPtopits to MSF
				# --------------------------------------------------
    $LdoExpandLoc=0;
    $LdoExpandLoc=1             if ($optOut=~/ret ali full/);
    ($Lok,$msg)=
	&convHssp2msf($exeConvertSeq,$file{"hsspTopits"},$file{"msfTopits"},$LdoExpandLoc,
		      $fhErrSbr,$file{"screenTopits"}); 

    return(0,"err=713","*** ERROR $sbr: no MSFtopits file (".$file{"msfTopits"}.
	   ")after TOPITS\n".$msgHere) if (! $Lok);
				# --------------------------------------------------
				# convert to TOPITS own format
				# --------------------------------------------------
    if ($optOut=~/ret topits (det|own)/ && -e $file{"hsspTopits"} && -e $file{"stripTopits"}){
	$msgHere.="--- $sbr calling topitsWrtOwn (".$file{"hsspTopits"}.",".
	    $file{"stripTopits"}.",".$file{"topits"}.",$parTopitsMixStrSeq,$fhErrSbr)\n";
	($Lok,$msg)=
	    &topitsWrtOwn($file{"hsspTopits"},$file{"stripTopits"},$file{"topits"},
			  $parTopitsMixStrSeq,$fhErrSbr);
	$msgHere.="$sbr:topitsWrtOwn returned 0\n$msg\n" if (! $Lok);}
				# --------------------------------------------------
				# go through output options
				# --------------------------------------------------

				# ------------------------------
				# (1) header
    if (-e $file{"headerTopits"}){
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppPred"},$file{"headerTopits"});
				# append HTML output
	if (-e $file{"headerTopits"} && $optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"headerTopits"},$fileHtmlTmp,$fileHtmlToc,1,"topits_head");
	    if (! $Lok) { $msg="*** err=2280 ($sbr: htmlBuild failed on kwd=topits_head)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2280",$msg); }}}

				# ------------------------------
				# (2) topits MSF
    if (-e $file{"msfTopits"}){
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppRetTopitsMsf"},$file{"msfTopits"});
				# append HTML output
	if (-e $file{"msfTopits"} && $optOut=~/ret html/) {
	    $file{"topitsHtml"}=$dirWork.$fileJobId.".htmlTopits"; push(@kwdRm,"topitsHtml");
	    ($Lok,$err,$msg)=
		&htmlTopits($file{"msfTopits"},$exeMview,$parMview,$optOut,
			    $file{"topitsHtml"},$fileHtmlTmp,$fileHtmlToc,$fhErrSbr);
	    if (! $Lok) { $msg="*** err=2281 ($sbr: htmlTopits failed on kwd=topits_msf)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2281",$msg); }}}
	
				# ------------------------------
				# (3) topits HSSP
    if ($optOut=~/ret topits hssp/ && -e $file{"hsspTopits"}){
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppLine"},
			$envPP{"fileAppRetTopitsHssp"},$file{"hsspTopits"});
				# append HTML output
	if (-e $file{"hsspTopits"} && $optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"hsspTopits"},$fileHtmlTmp,$fileHtmlToc,1,"topits_hssp");
	    if (! $Lok) { $msg="*** err=2282 ($sbr: htmlBuild failed on kwd=topits_hssp)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2282",$msg); }}}

				# ------------------------------
				# (4) topits STRIP
    if ($optOut=~/ret topits strip/ && -e $file{"stripTopits"}){
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,$envPP{"fileAppLine"},
			$envPP{"fileAppRetTopitsStrip"},$file{"stripTopits"});
				# append HTML output
	if (-e $file{"stripTopits"} && $optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"stripTopits"},$fileHtmlTmp,$fileHtmlToc,1,"topits_strip");
	    if (! $Lok) { $msg="*** err=2283 ($sbr: htmlBuild failed on kwd=topits_strip)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2283",$msg); }}}

				# ------------------------------
				# (5) topits OWN
    if ($Lok && $optOut=~/ret topits (det|own)/ && -e $file{"topits"}){
	($Lok,$msg)=		# append <<< --------------------
	    &sysCatfile("nonice",$Ldebug,$filePredTmp,
			$envPP{"fileAppRetTopitsOwn"},$file{"topits"});
				# append HTML output
	if (-e $file{"topits"} && $optOut=~/ret html/) {
	    ($Lok,$msg)=&htmlBuild($file{"topits"},$fileHtmlTmp,$fileHtmlToc,1,"topits_own");
	    if (! $Lok) { $msg="*** err=2284 ($sbr: htmlBuild failed on kwd=topits_own)\n".$msg."\n";
			  print $fhTrace $msg;
			  return(0,"err=2284",$msg); }}}

    return(1,"ok","$sbr"."\n"."$msgHere");
}				# end of runTopits


#===============================================================================
sub ctrlAbortPred {
    local($errLoc,$reason)=@_;local($LerrUsr);
#----------------------------------------------------------------------
#   ctrlAbortPred               creates a prediction file ($File_pred) 
#                               when the prediction has to be aborted
#       in:                     $errLoc='err=8 err=8 ..'
#       in:                     help: "no err","ok=help: text is wanted"
#       in:                     usr:  "$errLoc","abort usr"
#       in:                     $reason: reason expected to be of form:
#                                  'txt1: txt2'
#                                  where txt1 = 'licence|decrypt'
#                               and the names of keywords for file to
#                               remove ($file{$kwd} to remove)
#       in:                     : "no err","ok=help: text is wanted"
#       NOTE:                   if not HELP, this is the END!
#----------------------------------------------------------------------
    $sbr="ctrlAbortPred";
#    $PredStatus=  "AB";		# set the prediction status to ABort
    $LerrUsr=0;			# is it error in input format (then do not move to errror dir!)
    $Labort=0;			# to abort
				# hack br 98-05: make sure it is defined here!
    $seqStatus=~s/^\s*//g       if (defined $seqStatus); # GLOBAL variable

#    if (-e $file{"screenMax"}){close($fhScreenMax);}
				# ------------------------------
				# change the help text if concise option on
    $envPP{"fileHelpText"}=
	$envPP{"fileHelpConcise"} if (defined $job{"out"} && ($job{"out"}=~/concis/));
	
				# ------------------------------
				# (1) no panick is help request!!
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    if ($reason=~/^ok=help/){	# is help request => leave
	($Lok,$msg)=&sysCatfile("nonice",$Debug,$filePredTmp,$envPP{"fileHelpText"});
	$msgHere="$msg\n" if (!$Lok);
	($Lok,$msg)=&ctrlCleanUp(0,0,"ok"); # no error, no input error
	$msgHere.="*** ERROR reason=$reason, status=seqStatus clean=> ($Lok)" if (!$Lok);
	return(1,$msgHere);}	# is help request => end of it


				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

				# ------------------------------
				# (2) really forced abort?

    if    ($reason=~ /abort usr\=(.+)/){
	$reason=$1;$Labort=1;$LerrUsr=1;}
    elsif ($reason=~ /abort\=(.+)/){
	$reason=$1;$Labort=1;}
				# ------------------------------
				# (3) get error code
    ($Lok,$msgErr,$msgTxt)=
	&ctrlGetErrCode($errLoc,$envPP{"lib_err"});

    if ($reason =~/\(.*wrong msf\s*:(.+)\)/i){ # add explanation for MSF error
	$tmp1=$1;$tmp="---   REASON may have been: $tmp1\n";
	$msgTxt=~s/(\-\-\- usr:.*\n)/$1$tmp/
	    if (length($tmp1)>1);}

				# temporary sequence file: create if missing
    ($Lok,$msg)=&sysCatfile("nonice",$Debug,$filePredTmp,
			    $envPP{"fileAppInSeqSent"},$File_name,$envPP{"fileAppLine"})
	if (! -e $filePredTmp);
				# append to report file
    open(ABORTPRED, ">>".$filePredTmp);
    print ABORTPRED $msgTxt,"\n";
    close(ABORTPRED);
				# ------------------------------
    $Lok=0;			# (4) internal stuff
    if ($reason !~ /: /){print $fhTrace "*** $sbr '$reason' should have 'tag: explanation'\n";
			 $txtErr="unk";$txtExp="unk";}
    else                {($txtErr,$txtExp)=split(/: /,$reason);}

    $txtErr=~s/\s//g;$txtExp=~s/^\s*|\s*$//g;
    $exe_stripstars=$envPP{"exe_stripstars"};
				# --------------------------------------------------
				# (5) copy input file into dir_bup_errIn to be able
				#     to run the prediction again manually
    if (! $Debug && ! $LerrUsr){
	$tmp=$File_name;$tmp=~s/^.*\///g;
	($Lok,$msg)=&sysCpfile($File_name,$envPP{"dir_bup_errIn"}.$tmp); 
	$msgHere.="$msg\n" if (!$Lok);}
				# **************************************************
				# (6a) Error detected in licence checking
    if ($Labort && ($txtErr=~/^licence/)){
	($Lok,$msgSys)=&sysSystem("$exe_stripstars $filePredTmp",$fhOutSbr);
	$msgHere.="invalid password strip=> ($Lok)\n" if (!$Lok);
	($Lok,$msg)=&ctrlCleanUp(1,0,$msgHere); # license error, no input error
	$msgHere.="invalid password clean=> ($Lok)\n" if (!$Lok);
	return(0,$msgHere.
	       "\n".$msg); }	# ******************************

				# **************************************************
				# (6b) Error detected in decryption -> end
    elsif ($Labort && ($txtErr =~ /^decrypt/)){
	if (! $Labort){		# this is not logical : get out one day (98-02)
	    $msgHere.="$txtErr and $txtExp, but not Labort => internal error in $sbr\n";
	    next;}
	$msgHere.="$msg\n" if (!$Lok);
	($Lok,$msgSys)=&sysSystem("$exe_stripstars $filePredTmp",$fhOutSbr);
	$msgHere.="decrypt problem $txtErr\n"."$txtExp\n"."strip=> ($Lok)\n" if (!$Lok);
	($Lok,$msg)=&ctrlCleanUp(1,0,$msgHere); # decrypt error, no input error
	$msgHere.="decrypt problem $txtErr\n"."$txtExp\n"."clean=> ($Lok)\n" if (!$Lok);
	return(0,$msgHere); }	# ******************************

				# **************************************************
				# (6c) Error detected in extract -> end
    elsif ($Labort && $LerrUsr){
	undef $tmp;
	foreach $kwd (@kwdErr){	# GLOBAL variable
	    next if (length($kwd)<1);
	    next if (! defined $msgErr{$kwd});
	    if ($seqStatus =~/$msgErr{$kwd}/){
		&ctrlAlarm("status=$seqStatus ($File_name)!") 
		    if ($kwd =~ /^in\:nofile|^run\:convert/);
		$tmp=$appErr{$kwd};}}
	if (defined $tmp && -e $tmp){
	    ($Lok,$msg)=&sysCatfile("nonice",$Debug,$filePredTmp,$tmp,$envPP{"fileHelpText"});}
	else {
	    ($Lok,$msg)=&sysCatfile("nonice",$Debug,$filePredTmp,$envPP{"fileHelpText"});}
	$msgHere.="\n$msg" if (!$Lok);
	($Lok,$msg)=&ctrlCleanUp(0,1,$msgHere); # no 'real error', but input error
	$msgHere.="\n ERROR seqStatus=$seqStatus clean=> ($Lok)" if (!$Lok);
	return(0,$msgHere); }	# ******************************

				# **************************************************
				# (6d) Some other error detected ...
    else {
	if ( $reason =~ /cafasp/ ) {
	    ($Lok,$msg)=&ctrlCleanUp(1,0,"cafasp $msgHere");
	} else {
	    ($Lok,$msg)=&ctrlCleanUp(1,0,$msgHere); # real run error!
	}
	$msgHere.="\n ERROR seqStatus=$seqStatus clean=> ($Lok)" if (!$Lok);
	return(0,$msgHere); }	# ******************************

    close($fhTrace)		# close and remove the error log file
	if (-e $file_error && $fhTrace ne "STDOUT");

    return(1,"ok abort");
}				# end of ctrlAbortPred

#===============================================================================
sub ctrlAlarm {
    local ($message) = @_;
#----------------------------------------------------------------------
#   ctrlAlarm                   sends alarm mail to ppAdmin
#       in:                     $message
#          GLOBAL               $envPP{"exe_mail"},$envPP{"ppAdmin"},
#                               $File_name,$User_name,$Origin,$Date,
#----------------------------------------------------------------------
				# ------------------------------
				# surpress sending warnings ?
				# ------------------------------
    $pp_admin_sendWarn=1;
    $pp_admin_sendWarn=0        if (! defined $envPP{"pp_admin_sendWarn"} || 
				    $envPP{"pp_admin_sendWarn"} eq "no");
    return()                    if ($pp_admin_sendWarn);
				# ------------------------------
				# send mail
				# ------------------------------
    $header=   "\n              $Date";
    $header .= "\n input file : $File_name";
    $header .= "\n send by    : $User_name";
    $header.=  " ($User_name_forced)" if (defined $User_name_forced);
    $header .= "\n origin     : $Origin";
    $message=  "$header" . "\n" . "$message\n";
    $exe_mail=$envPP{"exe_mail"}; $ppAdmin=$envPP{"pp_admin"};
    ($Lok,$msgSys)=
	&sysSystem("echo '$message' | $exe_mail -s PP_ERROR $ppAdmin");
}				# end of ctrlAlarm

#===============================================================================
sub ctrlCleanUp {		# 
    local($Lerror,$LerrUsrLoc,$errMsgLoc)=@_;
    local($msgHere,$sbr,$file_sv_pred,$diff,$fileTmp,$finCuser,$finUser,
	  $finCsystem,$finSystem,$name,$urlRes,$urlEspritRes);
    $[=1;
#----------------------------------------------------------------------
#   ctrlCleanUp                 delete files (unless Debug flag is set)
#       in:                     $Lerror,$LerrUsrLoc
#                               1st = 'real error', e.g. 0 for help, input format error
#                               2nd = 'input error', (in which case Lerror=0)
#----------------------------------------------------------------------
    $sbr="ctrlCleanUp";         $fhoutLoc="FHOUT_".$sbr;
    $msgHere="--- $sbr start\n";
				# avoid warning
    $startTimeCuser=0           if (! defined $startTimeCuser);

    $file_sv_pred=$filePredFin ."_CLEAN_UP";
				# remove "*" from the result file
    if (! -e $filePredFin) {
	if (! -e $filePredTmp){
	    ($Lok,$msg)=
		&sysCatfile("nonice",$LdebugLoc,$filePredTmp,$envPP{"fileAppInSeqSent"},
			    $File_name,$envPP{"fileAppLine"});}
	($Lok,$msgSys)=&sysSystem("cp $filePredTmp $filePredFin");}

    $exe=$envPP{"exe_stripstars"};
    ($Lok,$msgSys)=&sysSystem("$exe $filePredFin");
				# remove null char from the result file
    &filePurgeNullChar($filePredFin);
				# --------------------------------------------------
				# crypt the file if necessary
    if (! $Lerror && ! $LerrUsrLoc && defined $job{"out"} && ($job{"out"} =~ /encrypt/)) {
	$crypt_status="none";
	$crypt_status=
	    &licence'crypt($User_name,$filePredFin,$filePID);  #e.e '

	if ($crypt_status ne $Crypt_on ) {
	    print $fhTrace "ERROR: crypt problem $crypt_status \n";
	    &ctrlAlarm("ERROR: crypt problem $crypt_status");
				# overwrite the pred file 
                                #           ==> do not send file if it should be crypted
	    ($Lok,$msg)=&sysCatfile("nonice",$Debug,$filePredFin,
				    $envPP{"fileAppIntErr"});
	    ($Lok,$msgSys)=&sysSystem("$exe $filePred"); }}
    
    if ($filePredFin ne $file_sv_pred){
				# copy prediction into result file
	($Lok,$msgSys)=&sysSystem("cp $filePredFin $file_sv_pred"); 
	($Lok,$msgSys)=&sysSystem("chmod 666 $file_sv_pred"); 
	    
				# compress and move prediction file
	($Lok,$msgSys)=&sysSystem("gzip $filePredFin");
	$fileTmp=   $filePredFin . ".gz"; 
	($Lok,$txt)=
	    &sysMvfile($fileTmp,$envPP{"dir_bup_res"}," ");}

				# --------------------------------------------------
    if ($Lerror && ! $Debug){	# if error move to error directory
	$dir=$envPP{"dir_err"};
	($Lok,$msgSys)=&sysSystem("\\mv $File_name $dir");

	$jobid_nodir=$filePID; $jobid_nodir=~s/^.*\///g; # remove path

	if (0){			# yy still commented out in one day??? yyDO_ONE_DAY
#	if (1){			# yy still commented out in one day??? yyDO_ONE_DAY }
	    foreach $cmd ("\\mv $File_name* $dir",
			  "\\mv $filePID* $dir",
			  "\\mv *$jobid_nodir* $dir") {
		($Lok,$msgSys)=&sysSystem($cmd);
		$msgHere.="$sbr system '$cmd'\n"; }} }
    
				# ==================================================
				# move prediction file to result file
    if (defined $job{"out"} && $job{"out"} =~/ret html/ 
	&& defined $fileHtmlFin && $fileHtmlFin && -e $fileHtmlFin) {
	$fileFinal=$fileHtmlFin; }
    else {
	$fileFinal=$file_sv_pred; }
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# move to ftp site 
    if (defined $job{"out"} && $job{"out"}=~/ret store/ && 
	! $Lerror && -e $fileFinal ) {
				# give random name to file
	($Lok,$randomString)=&ranGetString();
	$tmp=$fileFinal; $tmp=~s/^.*\///g; # purge dir
	$name=$tmp; $name=$randomString if ($Lok);
				# add '.html' to name
	
	if ($job{"out"}=~/ret html/) {
	    $name.=".html";
	} else {
	    $name.=".txt";
	}

	$dir=$envPP{"dir_resPub"}; $dir.="/" if ($dir !~/\//);
	$fileStore=$dir.$name;	# name of file to store for user
	($Lok,$msgSys)=&sysSystem("mv $fileFinal $fileStore");
	open($fhoutLoc,">".$fileFinal) || warn "*** predictPP:$sbr: failed open new=$fileFinal\n";
	$userTmp=$User_name;
	$userTmp=$User_name_forced if (defined $User_name_forced && $User_name_forced);
 	print $fhoutLoc 
	    "PPhdr from: $userTmp\n",
	    "PPhdr orig: $Origin\n",
	    "PPhdr resp: MAIL\n",
	    "PPhdr want: ASCII\n",
	    "\n";
	$urlRes = "http://cubic.bioc.columbia.edu/pp_res/".$name;
	$urlEspritRes = "http://cubic.bioc.columbia.edu/cgi/pp/nph-ESPript_exe.cgi?FRAMES=YES&frompp=on&alnfile0=$urlRes";
 	print $fhoutLoc 
 	    "Since you requested this the result file is NOT emailed to you\n",
 	    "Rather you may find it on our public site:\n",
 	    "\n",
 	    "$urlRes\n";
				# for txt output
				# provide  ESPript link
	if ($job{"out"} !~ /ret html/ and $job{"run"} !~ /nors_only/ ) { 
	    print $fhoutLoc
		"To convert the PredictProtein results into fancy images,\n",
		"go to $urlEspritRes\n",
		"and click the \"RUN\" button within the lower panel.\n\n";
	}
	print $fhoutLoc    
 	    "\n",
 	    "NOTE: the file will be deleted automatically after ",$envPP{"ctrl_timeoutResPub"},
 	           " days!!!\nPlease save the file if you are going to keep it!\n";
	close($fhoutLoc); }
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    if (-e $fileFinal) {
				# xx hack, for cafasp, we don't want to send
				# back anything if error
	if ( $errMsgLoc =~ /cafasp/ ) {	
	    unlink $fileFinal;
	} else {
	    ($Lok,$msgSys)=
		&sysSystem("mv $fileFinal $File_result");
	}
    }
	    
				# ==================================================

				# ------------------------------
				# append to log-file (phd.log)
				# ------------------------------
    ($finUser,$finSystem,$finCuser,$finCsystem) = times;
    $diff= int($finCuser - $startTimeCuser);

    $fileTmp= $filePID;
    $fileTmp=~s/^.*\///;
    $filePIDtmp=$fileTmp;
				# add key for mode
    if    ($Lerror)               { $fileTmp.="_error"; }
    elsif (! defined $job{"run"}) { $fileTmp.="_unk"; }
    elsif ($job{"run"}=~/topits/) { $fileTmp.="_topits"; }
    elsif ($job{"run"}=~/phdhtm/) { $fileTmp.="_phdhtm"; }
    elsif ($job{"run"}=~/phdsec/) { $fileTmp.="_phdsec"; }
    elsif ($job{"run"}=~/phdacc/) { $fileTmp.="_phdacc"; }
    elsif ($job{"run"}=~/phd/)    { $fileTmp.="_phd"; }
    elsif ($job{"run"}=~/evalsec/){ $fileTmp.="_evalsec"; }
    else                          { $fileTmp.="_unk"; }

    $file_ppLog=$envPP{"file_ppLog"};
				# only if correct user name given!!
    if ($User_name =~ /^(rost|pp|phd)/ ||
	$User_name =~ /[\w\.]+\@/) {
	open(LOGFILE, ">>$file_ppLog");
	$SeqDescription="unk"       if (! defined $SeqDescription);
				# security: correct date
	$dateTmp=$Date; 
	$dateTmp=~s/[ ,]+/:/g;
	if ($SeqDescription=~/\n/){
	    @tmp=split(/\n/,$SeqDescription);
	    $short=$tmp[1];}
	else {
	    $short=$SeqDescription;}
	$short="unk"            if (! defined $SeqDescription ||
				    length($SeqDescription)<3 ||
				    $SeqDescription=~/^[\s\t]+$/);
	printf LOGFILE 
	    "%s %s %s %s %6.2f %s %s\n",
	    $User_name,$Password,$Origin,$fileTmp,$diff,$dateTmp,$short;
	close(LOGFILE);}
				# --------------------------------------------------
				# remove files not wanted...
				# --------------------------------------------------
    if (! $Debug){
	unlink($envPP{"fileMaxhomDefaults"}) 
	    if (-e $envPP{"fileMaxhomDefaults"} && ($envPP{"fileMaxhomDefaults"}=~/$filePID/));
	foreach $kwd (@kwdRm){
	    next if (! defined $kwd);
	    next if (($Origin !~ /^mail|^html|^testPP/i) && 
		     ($kwd eq ("ali"||"aliFasta"||"aliFastaFil"||"aliBlastp"||
			       "aliBlastpFil"||
			       "pred"||"phdPred"||"phdRdb"||"phdRdbHtm"||"phdNotHtm"||
			       "phdDssp"||"phdRetMsf"||"phdRetCasp2"||
			       "hsspTopits"||"stripTopits")));
	    next if (! defined $file{$kwd});
	    next if (! -e $file{$kwd});
	    next if ($file{$kwd} eq $File_result || 
		     $file{$kwd} eq $file_sv_pred);
	    $msgHere.="$sbr unlink 1=".$file{$kwd}."\n";
	    unlink($file{$kwd});}
				# ------------------------------
				# list all remaining files
	$tmp=$File_name;	# unique name 'predict_e00000-00000'
	$tmp=~s/^(.*\/)//g;	# purge dir

	$dirTmp="";
	$dirTmp=$1 if (defined $1); # store dir (should be working dir)
	$tmp=~tr/[a-z]/[A-Z]/;	# maxhom capitalises!

	opendir(DIR,$dirTmp);
	@fileList=grep(/(MAXHOM.*$tmp|MAXHOM.*$$)/, readdir(DIR));
	closedir(DIR);
				# working dir
	opendir(DIR,$envPP{"dir_work"});
	push(@fileList,grep(/(MAXHOM.*$tmp|MAXHOM.*$$)/, readdir(DIR)));
	closedir(DIR);

	foreach $file (@fileList){
	    $file=&completeDir($envPP{"dir_work"}).$file
		if (! -e $file);
	    next if (! -e $file);
	    print "--- $sbr unlink 2=$file\n";
	    unlink($file);}
    }
    
				# ------------------------------
    if    ($Lerror){		# fin fin 
	$dir=$envPP{"dir_err"};
	($Lok,$msgSys)=&sysSystem("mv $file_error $dir") if (-e $file_error);
	($Lok,$msgSys)=&sysSystem("mv $file_outpp $dir") if (-e $file_outpp);}
    elsif (! $Debug){
	foreach $file($file_error,$file_outpp){
	    unlink($file) if (-e $file);}}
				# ------------------------------
				# hack br 98-05 delete whatever left (sometimes *.pred)
    if (! $Debug) {
	$tmp=$File_name;	# unique name 'predict_e00000-00000'
	$tmp=~s/^.*_[he](\d+)\D.*$/$1/g;

	opendir(DIR,$envPP{"dir_work"});
	@fileList=grep(/$tmp|$jobid|$filePID|$filePIDtmp/, readdir(DIR));
	closedir(DIR);
	foreach $file (@fileList){
	    $file=&completeDir($envPP{"dir_work"}).$file
		if (! -e $file);
	    print "--- $sbr unlink '$file'\n"; 
	    next if (! -e $file);
	    unlink($file); } }
				# ------------------------------
				# ok final delete:
				#    delete the input file!!!
    ($Lok,$msgSys)=
	&sysSystem("rm $File_name") if (! $Debug && -e $File_name);

				# ------------------------------
				# annotate possible errors here:
    return(0,"$sbr claims an error happened:\n".
	   $errMsgLoc."\n")     if ($Lerror);
				# error happened just here
    return(0,"$sbr claims an error happened:\n".
	   "source removing the final result ($File_name) led to:\n".
	   $msgSys."\n")        if (! $Lok);

    return(1,"ok $sbr");
}				# end of ctrlCleanUp

#===============================================================================
sub ctrlGetErrCode {
    local($txt,$lib) = @_ ;
    local($sbr,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ctrlGetErrCode              finds the error codes, and returns messages
#                               ready to be returned to 'me' and the user!
#       in:                     $txt : 'err=NNN\n bla bla bla err=MMM ...'
#       out:                    (status=0|1, msg=blabla, txtForUser)
#-------------------------------------------------------------------------------
    $sbr="ctrlGetErrCode";
    require "$lib" ||
	return(0,"*** SHIIIT $sbr ERROR: cannot require $lib\n","internal problem");
				# get numbers
    $tmp=$txt;$#code=0;
    while ($tmp =~/err=/){$tmp=~s/^.*err=(\d+)//;
			  push(@code,$1);}
    $msgUser=$msgHere="";$codes="error code=";
    foreach $code(@code){
	$codes.="$code,";
	($Lok,$msg)=&errCode($code);
	if (! $Lok){
	    $msgHere.="*** SHIIT $sbr ERROR: code=$code undefined\n";
	    ($Lok,$msg)=&errCode(1);$msgUser.=$msg;
	    last;}
	else {
	    $msgUser.=$msg;$msgHere.=$msg;}}
    return(1,"$codes\n".$msgHere,$msgUser);
}				# end of ctrlGetErrCode

#===============================================================================
sub extrConflicts {
#--------------------------------------------------------------------------------
#   extrConflicts            resets conflicting options
#--------------------------------------------------------------------------------
#    if ($optRun=~/^phd,(evalsec|topits)/){
				# no PHD if input column format
    if ($optRun=~/topits/ &&
	$optSeq=~/col|dssp/){
	$optRun=~s/phd[a-z]*[^,]*//g;}

    if ($optRun=~/^phd,evalsec/){
	$optRun=~s/^phd,//g;}
                                # 2nd: threading (prediction will be done anyway)
    elsif ($optRun=~/^topits/){
	$optRun=~s/parPhd.*$//g;
	$optRun=~s/parMaxhom.*$//g;
	$optOut=~s/ret ali [^,]*//g;
	$optOut=~s/ret phd [^,]*//g;}
                                # no prediction for evaluation (EVALSEC)
    elsif ($optRun=~/^evalsec|,evalsec|evalsec,/){
	$optRun="evalsec";
	$optOut=~s/ret ali [^,]*//g;
	$optOut=~s/ret topits [^,]*//g;
	$optOut=~s/ret phd [^,]*//g;}

				# no alignment if aligned FASTAmul or PIRmul
    if ($optRun=~/doNotAlign/) {
				# is NOT FASTAmul or PIRmul
	if    ($optSeq !~ /^(pir|fasta)/) {
	    $optRun=~s/doNotAlign\S*\s*,//g; }
	elsif ($optSeq =~/^pir/) {
	    $optSeq="pirMul";}
	elsif ($optSeq =~/^pir/) {
	    $optSeq="fastaMul";} }
				# no PHDmsf for option 'return HTML'!
    $optOut=~s/\s*ret phd msf\s*//g
	if ($optOut =~/ret html/ && $optOut =~ /ret phd msf/);
    $optOut=~s/^,*|,*$//g;$optOut=~s/,,/,/g;
    $optRun=~s/^,*|,*$//g;$optRun=~s/,,/,/g;

				# ------------------------------
				# DEFAULTS
				# 2000-07: default concise
    $optOut.=",ret concise";



				# ------------------------------
				# hack for CASP4 (2000)
    if ($optOut =~ /ret .* only casp/){
	$optRun=~s/,prodom//;
	$optRun=~s/,prosite//;
	$optRun=~s/,coils//;
	$optRun=~s/,cyspred//;
	$optRun=~s/,seg//;
	$optRun=~s/,segglob//;
	$optRun=~s/,segnorm//;
	$optRun=~s/,phd,/,phdsec,/;
	$optRun=~s/,phdacc/,/;
	$optRun=~s/,phdhtm/,/;
	$optRun=~s/,prof,/,profsec,/;
	$optRun=~s/,profacc,/,/;
	$optRun=~s/,profhtm,/,/;}

}				# end of extrConflicts

#===============================================================================
sub extrHdr {
    local($fhInLoc,$fhOutSbr) = @_ ;
    local($sbr,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   extrHdr                     extracts the header from the request (before #)
#       out GLOBAL:             $optRun,$optOut,$optSeq
#-------------------------------------------------------------------------------
    $sbr="extrHdr";
    
				# ------------------------------
    $Lfound=0;			# read input file: header
    while( <$fhInLoc> ) {
	$_=~tr/A-Z/a-z/;	# upper case -> lower *!*
	$line=$_;
	if ($line=~/\s*help/){$optRun="help"; 
			      return(1,$optRun);}

				
				# extract options in header (before '#')
	 
	$Lfound=
	    &extrHdrOneLine($line);

       
	if ($line=~/^\s*\#/){
	    $Lfound=1;
	    last ;}}
    return($Lfound);
}				# end of extrHdr

#===============================================================================
sub extrHdrOneLine {
    local ($lineLoc) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   extrHdrOneLine              checking anything before '#' in input PP file
#       out GLOBAL:             $optRun,$optOut,$optSeq
#--------------------------------------------------------------------------------
    $Lok=0;			# set to one only when '#' found
    $optRun=""                  if (! defined $optRun);
   
				# ---------------------------------------------
                                # prediction type
				# ---------------------------------------------

				# dudek's threader, only run this, ignore others
    if ( $lineLoc =~ /cafasp threader/ ) {
	$optRun = "cafaspThreader";
	$optSeq = "ppOld";
	$optOut = "";
	return (0);
    }

    if ($lineLoc =~ /pcc/){	# only pcc ignore others
	$optRun ="pcc";
	$optOut ="";
	return (0);
    }	
    
    if ($lineLoc =~ /proftmb/){	# only proftmb ignore others
	$optRun ="proftmb";
	$optOut ="";
	return (0);
    }	    

#  if ($lineLoc =~ /zafi/){	# only pcc ignore others
#	$optRun ="zafi";
#	$optOut ="";
#	return (0);
#    }	    
    	
    if ($lineLoc =~ /chop_only/){	# Only CHOP, ignore others
	$optRun ="chop_only";
	$optOut ="";
	return (0);
    }	    
    		     




    if    ($lineLoc=~/no.*filterAli/i && $lineLoc !~/no.*filterAliPhd/i) {
	$optRun.=",noFilterAli"; }
				# ------------------------------
				# expert options for filter ALI
				# in  GLOBAL: $optRun
				# out GLOBAL: append ',parFilterAli(opt1=x1 opt2=x2)' to $optRun 
    elsif ($lineLoc=~/filter\s*Ali|filter /i  && $lineLoc !~ /filter\s*phd/i) {
	$optRun.=",filterAli"; 
	&extrHdrExpertFilter("ali",$lineLoc) if ($lineLoc=~/\S+=\S+/); }

    if    ($lineLoc=~/no.*filterphd/i || $lineLoc=~/no.*filteraliphd/i ||
	   $lineLoc=~/no.*filter/) {
	$optRun.=",noFilterPhd"; }
				# ------------------------------
				# expert options for filter PHD
				# in  GLOBAL: $optRun
				# out GLOBAL append 
				#     ',parFilterAli(opt1=x1 opt2=x2)' to $optRun 
    elsif ($lineLoc=~/filter\s*Phd |filter /i && $lineLoc !~ /filter\s*ali/i) {
	$optRun.=",filterPhd"; 
	&extrHdrExpertFilter("phd",$lineLoc) if ($lineLoc=~/\S+=\S+/); }

    
				# ------------------------------
				# expert options for MaxHom
				# in  GLOBAL: $optRun
				# out: GLOBAL append 
				#      ',parMaxhom(ide=n go=n ge=n mat=MATRIX smax=n)'
    &extrHdrExpertMaxhom($lineLoc) 
	if ($lineLoc=~/exp(ert)? max\S* |max\S* exp(ert)?/i &&
	    $lineLoc=~/(ide|go|ge|mat|smax)\s*=/i );

				# --------------------------------------------------
				# other jobs
				# --------------------------------------------------
				# normal ProDom
    $optRun.=",prodom"          if ($lineLoc=~/(run|pred\S*|do)\s+prodom/i);
    $optRun=~s/,prodom//        if ($lineLoc=~/(no)\s*prodom/i);
				# normal Prosite
    $optRun.=",prosite"         if ($lineLoc=~/(run|pred\S*|do)\s+prosite/i);
    $optRun=~s/,prosite//       if ($lineLoc=~/(no)\s*prosite/i);
				# normal SEG
    $optRun.=",segnorm"         if ($lineLoc=~/(run|do)\s+seg/i &&
				    $lineLoc!~/(run|do)\s+segglob/i);
    $optRun=~s/,segnorm//       if ($lineLoc=~/(no)\s*seg/i);
    $optRun.=",segglob"         if ($lineLoc=~/(run|do)\s+seg\s*glob/i);
    $optRun=~s/,segglob//       if ($lineLoc=~/(no)\s*seg/i);
				# normal Coils
    $optRun.=",coils"           if ($lineLoc=~/(run|pred\S*|do)\s+coils/i);
    $optRun=~s/,coils//         if ($lineLoc=~/(no)\s*coils/i);
				# normal CYSPRED
    $optRun.=",cyspred"         if ($lineLoc=~/(run|pred\S*|do)\s+cyspred/i);
    $optRun=~s/,cyspred//       if ($lineLoc=~/(no)\s*cyspred/i);
				# normal NLS
    $optRun.=",nls"             if ($lineLoc=~/(run|pred\S*|do)\s+predictnls/i);
    $optRun=~s/,nls//           if ($lineLoc=~/(no)\s*predictnls/i);
                                # normal NORS
    $optRun.=",nors"            if ($lineLoc=~/(run|pred\S*|do)\s+nors/i);
    $optRun=~s/,nors//          if ($lineLoc=~/(no)\s*nors/i);
				# NORS only
    $optRun ="nors_only"        if ($lineLoc=~/(run|pred\S*|do)\s+nors_only/i);


				# normal Evalsec
    $optRun.=",evalsec"         if ($lineLoc=~/eval\S?.*pred.*[ -]acc|evalsec/);

				# PSI-blast
    $optRun.=",blastpsi"        if (($lineLoc=~/(run|do|use) (psi.?blast|blast.*psi|psi)/i ||
				     $lineLoc=~/psi/i)  && 
				    $lineLoc !~/(no|not)\s*psi/);

				# --------------------------------------------------
				# databases to use
				# --------------------------------------------------
    if ($lineLoc=~/(db|data.*base)\s*\=\s*(.+)/) {
	$tmp=$2; $tmp=~tr/[A-Z]/[a-z]/;
	if    ($tmp=~/pdb/)    { $optRun.=",db=pdb"; }
	elsif ($tmp=~/big/ ||
	       ($tmp=~/pdb/ && $tmp=~/trembl/ && $tmp=~/swiss/) ||
	       $tmp=~/all/)    { $optRun.=",db=big"; }
	elsif ($tmp=~/swiss/)  { $optRun.=",db=swiss"; }
	elsif ($tmp=~/trembl/) { $optRun.=",db=trembl"; }
	else { 
	    print 
		"-*- WARN $sbr: line=$lineLoc, db option NOT recognised, will take swiss!\n";}}


				# --------------------------------------------------
				# PHD
				# --------------------------------------------------

				# predict secondary structure and accessibility
    $optRun.=",phdsec,phdacc"   
	if ($lineLoc=~/pred\S?.*[ -]sec\S?.*[ -]acc|pred\S?.*[ -]acc\S?.*[ -]sec/);
    $optRun.=",phdsec"          if ($optRun !~ /evalsec/ && $lineLoc=~/pred\S?.*[ -]sec|phdsec/);
    $optRun.=",phdacc"          if ($optRun !~ /evalsec/ && $lineLoc=~/pred\S?.*[ -]acc|phdacc/);
    $optRun.=",phdhtm"          if ($optRun !~ /evalsec/ && 
				    $lineLoc=~/pred.*[ -]htm.*top|pred\S?.*mem\w*.* top/);
    $optRun.=",phdhtm"          if ($optRun !~ /evalsec/ && 
				    $lineLoc=~/pred\S?.*[ -]htm|pred\S?.*membrane|phdhtm/);


				# ------------------------------
				# expert options for PHDhtm
				# in  GLOBAL: $optRun
				# out: GLOBAL append 
				#      ',parPhdhtm(min=n)'
    &extrHdrExpertPhdhtm($lineLoc) 
	if ($lineLoc=~/exp(ert)? phdhtm |(phd)?htm exp(ert)?/i &&
	    $lineLoc=~/(expert.*htm.*|min)\s*=/i);

    
				# ------------------------------
				# PROF vs PHD

				# explicit PHD
#    $optRun.=",phd"             if (($lineLoc=~/phd/ && $lineLoc !~/filter/) ||
#				    ($lineLoc=~/do.*phd/ && $lineLoc !~/filter/));
				# explicit PROF
    $optRun.=",prof"            if (($lineLoc=~/prof/ && $lineLoc !~/filter/) ||
				    ($lineLoc=~/do.*prof/ && $lineLoc !~/filter/));

				# predict secondary structure and accessibility
    $optRun.=",profsec,profacc"   
	if ($lineLoc=~/prof\S?.*[ -]sec\S?.*[ -]acc|prof\S?.*[ -]acc\S?.*[ -]sec/);
    $optRun.=",profsec"         if ($optRun !~ /evalsec/ && $lineLoc=~/prof\S?.*[ -]sec|profsec/);
    $optRun.=",profacc"         if ($optRun !~ /evalsec/ && $lineLoc=~/prof\S?.*[ -]acc|profacc/);
#    $optRun.=",profhtm"         if ($optRun !~ /evalsec/ && 
#				    $lineLoc=~/prof.*[ -]htm.*top|prof\S?.*mem\w*.* top/);
#    $optRun.=",profhtm"         if ($optRun !~ /evalsec/ && 
#				    $lineLoc=~/prof\S?.*[ -]htm|prof\S?.*membrane|profhtm/);
    

				# ------------------------------
				# normal topits
    $optRun.=",topits"          if ($lineLoc=~/threading|topits/ && $lineLoc!~/ret.*topits/);
    				# ------------------------------
    				# normal profcon
    $optRun.=",profcon"          if ($lineLoc =~ /prof con/);

    				# normal chop
    $optRun.=",chop"            if ($lineLoc =~ /chop/);


				# ------------------------------
				# expert options for TOPITS
				# in  GLOBAL: $optRun
				# out: GLOBAL append 
				#      ',parTopits(mix=n nhits=n smax=n go=n ge=n mat=MAT)'
    &extrHdrExpertTopits($lineLoc) 
	if ($lineLoc=~/exp(ert)? topits |topits exp(ert)?/i &&
	    $lineLoc=~/(str[:_]?seq|mix|nhits|nhits_sel|gap\S*|go|ge|mat|smax)\s*=/i);

	
				# ------------------------------
				# expert options for ASP
				# in  GLOBAL: $optRun
				# out: GLOBAL append 
				#      ',parAsp(ws=n z=n min=n)'
    &extrHdrExpertAsp($lineLoc) 
	if ($lineLoc=~/exp(ert)? asp |asp exp(ert)?/i &&
	    $lineLoc=~/(ws|z|min)\s*=/i);
                                # ------------------------------
				# expert options for NORSp
				# in  GLOBAL: $optRun
				# out: GLOBAL append 
				#      ',parNors (ws=n seccut=n acclen=n)'
    &extrHdrExpertNors($lineLoc) 
	if ($lineLoc=~/exp(ert)? nors |nors exp(ert)?/i &&
	    $lineLoc=~/(ws|seccut|acclen)\s*=/i);

				# ------------------------------
                                # expert options for NORSp
                                # in  GLOBAL: $optRun
                                # out: GLOBAL append
                                #      ',parNors (ws=n seccut=n acclen=n)'
    &extrHdrExpertChop($lineLoc)
        if ($lineLoc=~/exp(ert)? chop |chop exp(ert)?/i &&
            $lineLoc=~/(blastE|hmmerE|domcov|minfrag)\s*=/i);

    
				# ---------------------------------------------
                                # return option (ouput format)
				# ---------------------------------------------
				# store output locally
    $optOut.=",ret store"       if ($lineLoc=~/ret\w*.store|ret no\s+e?mail|do\s+not\s+mail/);
    
				# general output: HTML
    $optOut.=",ret html"        if ($lineLoc=~/ret\w*.html/); 
    $optOut.=",ret html detail" if ($lineLoc=~/ret\w*.html\s*detail/i);
    $optOut.=",perline=$1"      if ($lineLoc=~/per.*line=(\d+)/);
    $optOut.=",perline=$1"      if ($lineLoc=~/ret\w*.html\s*detail\s*(\d+)|ret\w*.html\s*(\d+)/i);
				# concise output
    $optOut.=",ret concise"     if ($lineLoc=~/concise res|ret\w* concise/);
				# alignment options
    $optOut.=",ret ali no"      if ($lineLoc=~/ [n]o.?alignment/);
    $optOut.=",ret ali prof"    if ($lineLoc=~/ret\w*.hssp.*prof/);
    $optOut.=",ret ali hssp"    if ($lineLoc=~/ret\w*.hssp/ && $lineLoc!~/ret\w* t\w* hssp/);
    $optOut.=",ret ali blastp"  if ($lineLoc=~/ret\w*(\sali)* blast/);
    $optOut.=",ret ali full"    if ($lineLoc=~/ret\w*(\sali)* full/);
				# phd options
    $optOut.=",ret phd msf"     if ($lineLoc=~/ret\w*.phd.i?n?.?msf/);
    $optOut.=",ret phd casp"    if ($lineLoc=~/ret\w*.phd.*.i?n?.?casp/ &&
				    $lineLoc!~/ret\w*.*phd.*only.*casp/);
    $optOut.=",ret phd casp"    if ($lineLoc=~/ret\w*.casp/ && 
				    $lineLoc!~/ret\w*.*phd.*only.*casp/);
				    
    $optOut.=",ret phd col"     if ($lineLoc=~/ret\w*.col/);
#    $optOut.=",ret phd graph"   if ($lineLoc=~/ret\w*.graph/);
#    $optOut.=",ret phd mach"    if ($lineLoc=~/ret\w*.mach/);
    $optOut.=",ret phd rdb"     if ($lineLoc=~/ret\w*.phd\s*rdb/);
    $optOut.=",ret phd only casp,ret phd casp" 
	if ($lineLoc=~/ret\w*.*phd.*only.*casp/);
    $optOut.=",ret no phd"      if ($lineLoc=~/(\w*\s+|^)not?\s+phd/i);

				# prof options
    $optOut.=",ret prof msf"    if ($lineLoc=~/ret\w*.prof.*msf/);
    # GY ADDED 2004_02_02
    $optOut.=",ret prof con"    if ($lineLoc=~/ret\w*.prof.*con/);
    # END OF ADDITIONS
    $optOut.=",ret prof saf"    if ($lineLoc=~/ret\w*.prof.*saf/);
    $optOut.=",ret prof casp"   if ($lineLoc=~/ret\w*.prof.*casp/ && 
				    $lineLoc!~/ret\w*.*only.*casp/);
    $optOut.=",ret prof col"    if ($lineLoc=~/ret\w*.prof.*col/);
    $optOut.=",ret prof rdb"    if ($lineLoc=~/ret\w*.prof.*rdb/);
    $optOut.=",ret prof graph"  if ($lineLoc=~/ret\w*.prof.*graph/);
    $optOut.=",ret prof only casp,ret prof casp" 
	if ($lineLoc=~/ret\w*.*prof.*only.*casp/);
    $optOut.=",ret no prof"     if ($lineLoc=~/(\w*\s+|^)not?\s+prof/i);

				# topits options
    $optOut.=",ret topits hssp"    if ($lineLoc=~/ret\w*\s+top\w* hssp/);
    $optOut.=",ret topits strip"   if ($lineLoc=~/ret\w*\s+top\w* strip/);
    $optOut.=",ret topits own"     if ($lineLoc=~/ret\w*\s+top\w* (own|det)/);
				# other predictions
    $optOut.=",ret nors verbose"   if ($lineLoc=~/ret\w*\s+nors\w* verbose/);
    $optOut.=",ret no asp"         if ($lineLoc=~/(\w*\s+|^)no\s+asp/);
    $optOut.=",ret no coils"       if ($lineLoc=~/(\w*\s+|^)no\s+coil/);
    $optOut.=",ret no cyspred"     if ($lineLoc=~/(\w*\s+|^)no\s+cyspred/);
    $optOut.=",ret no predictnls"  if ($lineLoc=~/(\w*\s+|^)no\s+predictnls/);
    $optOut.=",ret no prosite"     if ($lineLoc=~/(\w*\s+|^)no\s+prosite/);
    $optOut.=",ret no prodom"      if ($lineLoc=~/(\w*\s+|^)no\s+prodom/);
    $optOut.=",ret no segnorm"     if ($lineLoc=~/(\w*\s+|^)no\s+seg\s*norm/ ||
				    ($lineLoc=~/(\w*\s+|^)no\s+seg/ &&
				     $lineLoc!~/(\w*\s+|^)no\s+seg.*glob/));
    $optOut.=",ret no segglob"     if ($lineLoc=~/(\w*\s+|^)no\s+seg.*glob/);
				# ---------------------------------------------
                                # input format
				# ---------------------------------------------
				# MSF format
    if    ($lineLoc=~/^\s*\#\s*msf/ )             { 
    $optSeq="msf"; $Lok=1;}
    elsif ($lineLoc=~/^\s*\#\s*saf/ )             { 
	$optSeq="saf"; $Lok=1;} # SAF format
    elsif ($lineLoc=~/^\s*\#\s*pir\s*[list|ali]/i){ 
	$Lok=1;
	$optSeq="pirList";	# PIR list format
	if ($optRun=~/do.?not.?ali/i) {
	    $optRun=~s/,\s*do.?not.?ali[a-z]*\s*//ig;
	    $optSeq="pirMul";	# PIR mul
	    $optRun.=",convert";
	}}
    elsif ($lineLoc=~/^\s*\#\s*fasta[\s\-]*[list|ali]/i){ 
	$Lok=1;
	$optSeq="fastaList";	# FASTA list format
	if ($optRun=~/do.?not.?ali/i) {
	    $optRun=~s/,\s*do.?not.?ali[a-z]*\s*//ig;
	    $optSeq="fastaMul";	# FASTA mul
	    $optRun.=",convert";
	}}
    elsif ($lineLoc=~/^\s*\#.*(column|col.*form)/){ 
	$optSeq="col"; $Lok=1;} # column formatted predict
    elsif ($lineLoc=~/^\s*\#/ )                   { 
	$optSeq="ppOld";	# old PP default
	$tmp=substr($lineLoc,index($lineLoc,"#") + 1);
	$tmp=~ s/\n//g; $tmp=~ s/\>/ /g;
	$tmp=~s/\.\./\. /g;	# hack around convert_seq
	$tmp=~s/\.\s$/\. end/g; # hack around convert_seq
	$optSeq.=",$tmp"; $Lok=1;}

				# ------------------------------
				# input is aligned FASTA or PIR list
    $optRun.=",doNotAlign"      if ($lineLoc=~/^\s*do.*not?.*ali(gn)?/);

				# ------------------------------
				# input is aligned FASTA or PIR list
    $optRun.=",doNotPsiblast"   if ($lineLoc=~/^\s*do.*not?.*psi.*blast/i ||
				    $lineLoc=~/.*not?\s*psi.*blast/i      );

				# ---------------------------------------------
				# filter options
				# ---------------------------------------------
    if ($optSeq=~/msf|saf|fastaList|pirList/) {
	$optRun.=",noFilterAli"  if ($optRun !~/,filterAli/  && $optRun !~/,noFilterAli/);
	$optRun.=",noFilterPhd"  if ($optRun !~/,filterPhd/  && $optRun !~/,noFilterPhd/);
	$optRun.=",noFilterProf" if ($optRun !~/,filterProf/ && $optRun !~/,noFilterProf/);
    }

    return($Lok);
}				# end of extrHdrOneLine



#===============================================================================
sub extrHdrExpertAsp {
    local ($lineLoc2) = @_ ;
    local ($tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   extrHdrExpertAsp         extracts parameters for ASP
#       in GLOBAL:              $optRun
#       out GLOBAL:             $optRun
#       in:                     $txt    =
#                               expert asp ws=n z=n min=n
#       out GLOBAL:             $optRun
#                               added: ',parAsp(ws=n z=n min=n)'
#--------------------------------------------------------------------------------
    $lineLoc2=~s/\s*$//g;
    $lineLoc2=~tr/[A-Z]/[a-z]/;	# make case independent!

				# --------------------------------------------------
				# parsable keywords
				# --------------------------------------------------
    $build="";
				# asp ws
    if ($lineLoc2=~ /ws=([0-9]+)/ ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="ws=$tmp,";}}

    if ($lineLoc2=~ /z=([0-9\-\.]+)/ ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="z=$tmp,";}}

    if ($lineLoc2=~ /min=([0-9\.]+)/ ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="min=$tmp,";}}

    $build=~s/\s//g;		# no blanks
    $build=~s/,$//g;		# final comma

				# ------------------------------
				# close brackets for syntax
    if (length($build)>=1) {
	$optRun.=",parAsp(".$build."),";
	$optRun=~s/\s//g; }
}				# end of extrHdrExpertAsp


#===============================================================================
sub extrHdrExpertFilter {
    local ($modeLoc2,$lineLoc2) = @_ ;
    local ($kwd,$line,$kwdTmp,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   extrHdrExpertFilter         extracts parameters for undocumented filter options
#       in GLOBAL:              $optRun
#       out GLOBAL:             $optRun
#       in:                     $modeLoc= [ali|phd] i.e. for filtering the alignment
#                                                   to send or for the one used as
#                                                   input to PHD
#                               $txt    =
#                               filterAli thresh=-5 threshSgi=n mode=[ide|old|sim] 
#                                         excl=n1,n2,n3-n4 incl=n5
#       out GLOBAL:             $optRun
#                               added: ',parFilter(thresh=-5 threshSgi=5 extr=5)'
#--------------------------------------------------------------------------------
    $lineLoc2=~s/^\s*|\s*$//g;	# purge leading blanks

				# --------------------------------------------------
				# parsable keywords
				# --------------------------------------------------
    foreach $kwd ("thresh","threshSgi",
		  "mode","excl","incl","red") {
	$kwdTmp=$kwd; $kwdTmp=~tr/[A-Z]/[a-z]/;
	next if ($lineLoc2 !~ /$kwdTmp=/i);
	$tmp=$lineLoc2; $tmp=~s/^.*$kwdTmp=(\S+)\s*.*$/$1/g;
				# ------------------------------
				# syntax check
				# distance from threshold
	if    ($kwd =~/^thresh/ &&
	    $tmp=~/^[\-0-9\.]+$/ && $tmp > -100 && $tmp < 100) {
	    $Lok=1; }
				# mode
	elsif ($kwd =~ /^mode/  && 
	       $tmp=~/^(ide|sim|hssp|old)/) {
	    $Lok=1; }
				# numbers to include or exclude
	elsif ($kwd =~ /^(excl|incl)/ && 
	       $tmp=~/^[\-,0-9\.]+$/) {
	    $tmp=~s/\./\,/g;	# replace dots by commata
	    $Lok=1; }
				# reduction of redundancy
	elsif ($kwd =~ /^red/ && 
	       $tmp=~/^[\-0-9\.]+$/ && $tmp <= 100 && $tmp >=0) {
	    $Lok=1; }
	else {			# unrecognised
	    $Lok=0;}
	next if (! $Lok);	# unrecognised

				# ------------------------------
				# add to job option
	$optRun.=",parFilterAli(" 
	    if ($modeLoc2 eq "ali" && $optRun !~ /parFilterAli/i);
	$optRun.=",parFilterPhd(" 
	    if ($modeLoc2 eq "phd" && $optRun !~ /parFilterPhd/i);
	$optRun.=" $kwd=$tmp"; 
    }
				# ------------------------------
				# close brackets for syntax
    if ($optRun =~ /parFilter(Ali|Phd)/i) {
	$optRun=~s/(parFilter(Ali|Phd)\s*\()\s*/$1/ig;
	$optRun.=")"; }
}				# end of extrHdrExpertFilter

#===============================================================================
sub extrHdrExpertMaxhom {
    local ($lineLoc2) = @_ ;
    local ($tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   extrHdrExpertMaxhom         extracts parameters for undocumented options
#       in GLOBAL:              $optRun
#       out GLOBAL:             $optRun
#       in:                     $txt    =
#                               Maxhom 'smax=[0-50] go=[1-50] ge=[0.1-50] ide=[0-100] mat=various'
#       out GLOBAL:             $optRun
#                               added: ',parMaxhom(ide=n go=n ge=n mat=MATRIX smax=n)'
#--------------------------------------------------------------------------------
    $lineLoc2=~s/\s*$//g;
    $lineLoc2=~tr/[A-Z]/[a-z]/;	# make case independent!

				# --------------------------------------------------
				# parsable keywords
				# --------------------------------------------------
    $build="";
				# ide
    if ($lineLoc2=~ /ide[a-z]*\s*=\s*([0-9\.]+)/){
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="ide=$tmp,";}}
				# go
    if ($lineLoc2=~ /(gapopen|go|gap.open)\s*=\s*([0-9\.]+)/){
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="go=$tmp,";}}
				# ge
    if ($lineLoc2=~ /(gapelon[a-z]*|ge|gap.elon[a-z]*)\s*=\s*([0-9\.]+)/){
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="ge=$tmp,";}}
				# smax
    if ($lineLoc2=~ /(smax)\s*=\s*([0-9\.]+)/){ 
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="smax=$tmp,";}}
				# matrix
    if ($lineLoc2=~ /(mat[a-z]*)\s*=\s*([a-z0-9\_\-]+)/){ 
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="mat=$tmp,";}}

    $build=~s/\s//g;		# no blanks
    $build=~s/,$//g;		# final comma

				# ------------------------------
				# close brackets for syntax
    if (length($build)>=1) {
	$optRun.=",parMaxhom(".$build."),";
	$optRun=~s/\s//g; }
}				# end of extrHdrExpertMaxhom


#===============================================================================
sub extrHdrExpertNors {
    local ($lineLoc2) = @_ ;
    local ($tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   extrHdrExpertAsp         extracts parameters for ASP
#       in GLOBAL:              $optRun
#       out GLOBAL:             $optRun
#       in:                     $txt    =
#                               expert asp ws=n z=n min=n
#       out GLOBAL:             $optRun
#                               added: ',parAsp(ws=n z=n min=n)'
#--------------------------------------------------------------------------------
    $lineLoc2=~s/\s*$//g;
    $lineLoc2=~tr/[A-Z]/[a-z]/;	# make case independent!

				# --------------------------------------------------
				# parsable keywords
				# --------------------------------------------------
    $build="";
				# asp ws
    if ($lineLoc2=~ /ws=([0-9]+)/ ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="ws=$tmp,";}}

    if ($lineLoc2=~ /seccut=([0-9\-\.]+)/ ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="seccut=$tmp,";}}

    if ($lineLoc2=~ /acclen=([0-9\.]+)/ ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="acclen=$tmp,";}}

    $build=~s/\s//g;		# no blanks
    $build=~s/,$//g;		# final comma

				# ------------------------------
				# close brackets for syntax
    if (length($build)>=1) {
	$optRun.=",parNors(".$build."),";
	$optRun=~s/\s//g; }
}				# end of extrHdrExpertNors

#===============================================================================
sub extrHdrExpertChop {
    local ($lineLoc2) = @_ ;
    local ($tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   extrHdrExpertChop         extracts parameters for CHOP
#       in GLOBAL:              $optRun
#       out GLOBAL:             $optRun
#       in:                     $txt    =
#                               expert chop ws=n z=n min=n
#       out GLOBAL:             $optRun
#                               added: ',parChop(blastE=n hmmerE=n domcov=n)'
#--------------------------------------------------------------------------------
    $lineLoc2=~s/\s*$//g;
#    $lineLoc2=~tr/[A-Z]/[a-z]/;	# make case independent!

				# --------------------------------------------------
				# parsable keywords
				# --------------------------------------------------
    $build="";
				# chop blastE
#    print STDERR "xx line=$lineLoc2\n";
    if ($lineLoc2=~ /blastE=([0-9\.]+)/i ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="blastE=$tmp,";}}

    if ($lineLoc2=~ /hmmerE=([0-9\.]+)/i ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="hmmerE=$tmp,";}}

    if ($lineLoc2=~ /domcov=([0-9\.]+)/i ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="domcov=$tmp,";}}

    if ($lineLoc2=~ /minfrag=([0-9]+)/i ) {
	undef $tmp; $tmp=$1 if ( defined $1);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="minfrag=$tmp,";}}


    $build=~s/\s//g;		# no blanks
    $build=~s/,$//g;		# final comma

				# ------------------------------
				# close brackets for syntax
    if (length($build)>=1) {
	$optRun.=",parChop(".$build."),";
	$optRun=~s/\s//g; }
}				# end of extrHdrExpertChop


#===============================================================================
sub extrHdrExpertPhdhtm {
    local ($lineLoc2) = @_ ;
    local ($tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   extrHdrExpertPhdhtm         extracts parameters for undocumented options
#       in GLOBAL:              $optRun
#       out GLOBAL:             $optRun
#       in:                     $txt    =
#                               phdhtm 'min=0.5'
#       out GLOBAL:             $optRun
#                               added: ',parPhdhtm(min=n)'
#--------------------------------------------------------------------------------
    $lineLoc2=~s/\s*$//g;
    $lineLoc2=~tr/[A-Z]/[a-z]/;	# make case independent!

				# --------------------------------------------------
				# parsable keywords
				# --------------------------------------------------
    $build="";
				# min htm
    if ($lineLoc2=~ /(.*expert.*htm.*|min\s*[a-z]*)\s*=([0-9\.]+)/){
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="min=$tmp,"; }}

    $build=~s/\s//g;		# no blanks
    $build=~s/,$//g;		# final comma

				# ------------------------------
				# close brackets for syntax
    if (length($build)>=1) {
	$optRun.=",parPhdhtm(".$build."),";
	$optRun=~s/\s//g; }
}				# end of extrHdrExpertPhdhtm

#===============================================================================
sub extrHdrExpertTopits {
    local ($lineLoc2) = @_ ;
    local ($tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   extrHdrExpertTopits         extracts parameters for undocumented options
#       in GLOBAL:              $optRun
#       out GLOBAL:             $optRun
#       in:                     $txt    =
#                               topits|threading 'smax=n1 go=n2 str:seq=n3 nhits_sel=n3'
#       out GLOBAL:             $optRun
#                               added: ',parTopits(mix=n nhits=n smax=n go=n ge=n mat=MAT)'
#--------------------------------------------------------------------------------
    $lineLoc2=~s/\s*$//g;
    $lineLoc2=~tr/[A-Z]/[a-z]/;	# make case independent!

				# --------------------------------------------------
				# parsable keywords
				# --------------------------------------------------
    $build="";
				# mix (str:seq)
    if ($lineLoc2=~ /(str:seq|mix|str_seq)\s*=([0-9\.]+)/){
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="mix=$tmp,";}}
				# nhits
    if ($lineLoc2=~ /(nhits_sel|nhits)\s*=([0-9\.]+)/){
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="nhits=$tmp,";}}
				# go
    if ($lineLoc2=~ /(gapopen|go|gap.open)\s*=\s*([0-9\.]+)/){
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="go=$tmp,";}}
				# ge
    if ($lineLoc2=~ /(gapelon[a-z]*|ge|gap.elon[a-z]*)\s*=\s*([0-9\.]+)/){
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="ge=$tmp,";}}
				# smax
    if ($lineLoc2=~ /(smax)\s*=\s*([0-9\.]+)/){ 
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="smax=$tmp,";}}
				# smax
    if ($lineLoc2=~ /(mat[a-z]*)\s*=\s*([a-z0-9\_\-]+)/){ 
	undef $tmp; $tmp=$2     if (defined $2);
	if (defined $tmp && length($tmp) >= 1) {
	    $build.="mat=$tmp,";}}

    $build=~s/\s//g;		# no blanks
    $build=~s/,$//g;		# final comma

				# ------------------------------
				# close brackets for syntax
    if (length($build)>=1) {
	$optRun.=",parTopits(".$build."),";
	$optRun=~s/\s//g; }
}				# end of extrHdrExpertTopits


#===============================================================================
# GY ADDED 11-2003: HMMPfam app
#===============================================================================
sub runHmmpfam {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeCopf,$exeHmmpfam,$fileAliPhdIn,$dirHmmpfam)=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$fileStripOutMod,
	  $fileAliList,$fileFastaSingle,@tmpAppend,$txt,$command, $fhcys, @tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runHmmpfam                : hmmpfam
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runHmmpfam";
    $errTxt="err=541"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
  #  return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);

    return(0,$errTxt,$msg."exeHmmpfam!")        if (! defined $exeHmmpfam);
    return(0,$errTxt,$msg."fileAliPhdIn")     if (! defined $fileAliPhdIn);

    $errTxt="err=542"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=543"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=544"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeHmmpfam) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=545","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

    return(0,"err=546","*** $sbr: no hssp =".$fileAliPhdIn."!")
	if (! -e $fileAliPhdIn && ! -l $fileAliPhdIn);

    $msgErrIntern=    $msgErr{"internal"}; 
    $msgErrConvert=   $msgErr{"runHmmpfam:convert"};
    $msgErrCoils=     $msgErr{"runHmmpfam:pfam"};
#    $msgErr=    $msgErr{":"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/hmmpfam,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/hmmpfam,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/hmmpfam,//g;}
    
				# ---------------------------------------------
				# pfam can only take single sequence
				# in case input is list, get the first fasta file
				# ---------------------------------------------
    if ( $optSeq =~ /saf|msf/) {
	$file{"seq4cys"}=    $dirWork. $fileJobId.  ".fastaSingle";
	push(@kwdRm,"seq4cys");
	
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqFasta"});
	return(0,"err=551",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seq4cys"},$id,$seq);
	return(0,"err=552",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=553",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seq4cys"}."' written \n") if (! -e $file{"seq4cys"});
    } else {
	$file{"seq4cys"} = $file{"seqFasta"};
    }

				# --------------------------------------------------
                                # HMMPFAM program
				# --------------------------------------------------
    if ($optRun =~/hmmpfam/) {
	$file{"hmmpfam"}=        $dirWork.$fileJobId.".cys";   

	push(@kwdRm,"cys");

				# set env HMMPFAMIR (required for the program)
	if (! defined $ENV{"HMMPFAMIR"} ) {
	    $ENV{"HMMPFAMIR"} = $dirHmmpfam;
	}

				# check whether another cycpred is running
				# due to common filename used by cycpred
				# only one should be run for safety
	$exe_ps = $envPP{"exe_ps"};
	while ( 1 ) {
	    ($Lok, $njobs) =
		&envPP::isRunningEnv($exeHmmpfam,$exe_ps, $fhErrSbr);
	    if ( ! $Lok ) {
		return ( 0, "err=555","*** ERROR $sbr\n"."$njobs\n");
	    }
	    if ( $njobs == 0 ) {
	        print $fhErrSbr "--- $sbr: No hmmpfam is running, we are safe.\n";
		last;
	    } elsif ( $njobs >= 1 ) {
		print  $fhErrSbr "--- $sbr: Another hmmpfam is running, we'd better wait 5 sec.\n";
		sleep(5);
	    } else {
		return ( 0, "err=555","*** ERROR $sbr\n"."$njobs\n");
	    }
	}


	$command="$nice $exeHmmpfam ".
	    "$file{\"seq4cys\"} $fileAliPhdIn $file{\"hmmpfam\"}";
	$msgHere="--- $sbr system '$exeHmmpfam $command'";
				# --------------------------------------------------
				# do run HMMPFAM
				# --------------------------------------------------
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=560","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	if (! $Lok || ! -e $file{"hmmpfam"});

				# -------------------------------------------------
				# check result, inform user only when we have some 
				# bonded cycteine
				# -------------------------------------------------
	$fhcys = 'FHCYS';
	$Lok=       &open_file($fhcys,$file{"hmmpfam"});
	return(0,"*** ERROR $sbr: '$file{\"hmmpfam\"}' not opened\n") if (! $Lok);
	
	$Lok = 2;
	while ( <$fhcys> ) {
	    if ( /^No cys in/ ) {
		$Lok = 0;
		$msg .= $_;
		last;
	    } else {
		next if ($_ !~ /YES|NO/i);
		chomp;
		@tmp = split /\s+/;
		if ($tmp[4] eq 'YES') {
		    $Lok = 1;
		    $msg .= "Bonded cys found.\n";
		    last;
		}
	    }
	}
	close $fhcys;
				# -----------------------------------
				# if we have bonded cys, write it out
	if ( $Lok == 1 ) {
	    $#tmpAppend=0;	  
	    push(@tmpAppend,$envPP{"fileAppHmmpfam"},
		 $file{"hmmpfam"},$envPP{"fileAppLine"});
	    
	    # ------------------------------
	    # append HTML output
	    # ------------------------------
	    if ($optOut=~/ret html/ && -e $file{"hmmpfam"}){ 
		# append file
		($Lok,$msg)=&htmlBuild($file{"hmmpfam"},$fileHtmlTmp,$fileHtmlToc,1,"hmmpfam");
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=hmmpfam)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2250",$msg); }
	    }
	}

	
	
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){	# 
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=570",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }

    return(1,"ok","$sbr:$msg");
}				# end runHmmpfam


#===============================================================================
# GY ADDED 1-2004: PROFCON app
#===============================================================================
sub runProfCon {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeCopf,$exeProfCon,$dirProfCon)=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$fileStripOutMod,
	  $fileAliList,$fileFastaSingle,@tmpAppend,$txt,$command, $fhcys, @tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runProfCon                : profcon
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runProfCon";
    $errTxt="err=541"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
#   return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);

    return(0,$errTxt,$msg."exeProfCon!")        if (! defined $exeProfCon);
#   return(0,$errTxt,$msg."fileAliPhdIn")     if (! defined $fileAliPhdIn);

    $errTxt="err=542"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=543"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=544"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeProfCon) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=545","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

#    return(0,"err=546","*** $sbr: no hssp =".$fileAliPhdIn."!")
#	if (! -e $fileAliPhdIn && ! -l $fileAliPhdIn);

    $msgErrIntern=    $msgErr{"internal"}; 
    $msgErrConvert=   $msgErr{"align:convert"};
#    $msgErrProfCon=     $msgErr{"runProfCon:profcon"};
#    $msgErr=    $msgErr{":"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/profcon,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/profcon,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/profcon,//g;}
    
				# ---------------------------------------------
				# profcon can only take single sequence
				# in case input is list, get the first fasta file
				# ---------------------------------------------
    if ( $optSeq =~ /saf|msf/) {
	$file{"seq4profcon"}=    $dirWork. $fileJobId.  ".fastaSingle";
	push(@kwdRm,"seq4profcon");
	
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqFasta"});
	return(0,"err=551",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seq4profcon"},$id,$seq);
	return(0,"err=552",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=553",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seq4profcon"}."' written \n") if (! -e $file{"seq4profcon"});
    } else {
	$file{"seq4profcon"} = $file{"seqFasta"};
    }

				# --------------------------------------------------
                                # profCon program
				# --------------------------------------------------
    if ($optRun =~/profcon/) {
	$file{"profcon"}=        $dirWork.$fileJobId.".profcon";   
	push(@kwdRm,"profcon");

				# set env PROFCON dir (required for the program)
	if (! defined $ENV{"PROFCON"} ) {
	    $ENV{"PROFCON"} = $dirProfCon;
	}

	# TBD: find name of protein
	$UserProtName = "TBD";
	# profcon takes a protein name (up to 8 chars) 
	# To preserve uniquness of filename we use the filejobid and make sure its no longer then last 8 chars
	my $profConProtName = $UserProtName.".".$fileJobId;

	# Usage: ./run_prof08.pl protein_name(MAX 8 char.) file.fasta file.hssp file.rdbProf
	# trim filejobid to be at most 8 chars

	$command="$nice $exeProfCon "."$profConProtName ".
	    "$file{\"seq4profcon\"} $file{\"hsspPsiFil\"} $file{\"profRdb\"} > $file{\"profcon\"} ";
	$msgHere="--- $sbr system '$exeProfCon $command'";
				# --------------------------------------------------
				# do run ProfCon
				# --------------------------------------------------
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=560","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	if (! $Lok || ! -e $file{"profcon"});

				# -------------------------------------------------
				# check result, 
				# -------------------------------------------------
	$fhpcon = 'FHPCON';
	$Lok=       &open_file($fhpcon,$file{"profcon"});
	return(0,"*** ERROR $sbr: '$file{\"profcon\"}' not opened\n") if (! $Lok);
	# TODO: in case there's nothing to return add a message!
#	close $fhcys;

	if ( $Lok == 1 ) {
	    $#tmpAppend=0;	  
	    push(@tmpAppend,$envPP{"fileAppProfCon"},
		 $file{"profcon"},$envPP{"fileAppLine"});
	    
	    # ------------------------------
	    # append HTML output
	    # ------------------------------
	    if ($optOut=~/ret html/ && -e $file{"profcon"}){ 
		# append file
		($Lok,$msg)=&htmlBuild($file{"profcon"},$fileHtmlTmp,$fileHtmlToc,1,"profcon");
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=profcon)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2250",$msg); }
	    }
	}

		
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){	# 
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=570",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }

    return(1,"ok","$sbr:$msg");
}				# end runProfCon



#===============================================================================
# GY ADDED 2-2004: PCC{Predict Cell Cycle} app
#===============================================================================
sub runPredCC {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeCopf,$exePcc,$dirPcc)=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$fileStripOutMod,
	  $fileAliList,$fileFastaSingle,@tmpAppend,$txt,$command, $fhcys, @tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runPcc                    : predict cell cycle
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runPcc";
    $errTxt="err=541"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
#   return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);

    return(0,$errTxt,$msg."exePcc!")        if (! defined $exePcc);
#   return(0,$errTxt,$msg."fileAliPhdIn")     if (! defined $fileAliPhdIn);

    $errTxt="err=542"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=543"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=544"; $msg="*** $sbr: no exe =";
    foreach $exe ($exePcc) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=545","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

#    return(0,"err=546","*** $sbr: no hssp =".$fileAliPhdIn."!")
#	if (! -e $fileAliPhdIn && ! -l $fileAliPhdIn);

    $msgErrIntern=    $msgErr{"internal"}; 
    $msgErrConvert=   $msgErr{"align:convert"};
#    $msgErrProfCon=     $msgErr{"runProfCon:profcon"};
#    $msgErr=    $msgErr{":"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/pcc,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/pcc,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/pcc,//g;}
    
				# ---------------------------------------------
				# predict cell cycle can only take single sequence
				# in case input is list, get the first fasta file
				# ---------------------------------------------
    if ( $optSeq =~ /saf|msf/) {
	$file{"seq4pcc"}=    $dirWork. $fileJobId.  ".fastaSingle";
	push(@kwdRm,"seq4pcc");
	
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqFasta"});
	return(0,"err=551",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seq4pcc"},$id,$seq);
	return(0,"err=552",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=553",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seq4pcc"}."' written \n") if (! -e $file{"seq4pcc"});
    } else {
	$file{"seq4pcc"} = $file{"seqFasta"};
    }

				# --------------------------------------------------
                                # Predict Cell Cycle program
				# --------------------------------------------------
    if ($optRun =~/pcc/) {
	$file{"pcc"}=        $dirWork.$fileJobId.".pcc";   
	push(@kwdRm,"pcc");

				# set env PCC dir (required for the program)
	if (! defined $ENV{"PCC"} ) {
	    $ENV{"PCC"} = $dirPcc;
	}

	# TBD: find name of protein
#	$UserProtName = "TBD";
	# profcon takes a protein name (up to 8 chars) 
	# To preserve uniquness of filename we use the filejobid and make sure its no longer then last 8 chars
#	my $profConProtName = $UserProtName.".".$fileJobId;

	# Usage: ./run_prof08.pl protein_name(MAX 8 char.) file.fasta file.hssp file.rdbProf
	# trim filejobid to be at most 8 chars

	$command="$nice $exePcc ". "$file{\"seq4pcc\"} > $file{\"pcc\"}";
#$file{\"hsspPsiFil\"} $file{\"profRdb\"} > $file{\"profcon\"} ";
	$msgHere="--- $sbr system '$exePcc $command'";
				# --------------------------------------------------
				# do run Predict Cell Cycle
				# --------------------------------------------------
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=560","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	if (! $Lok || ! -e $file{"pcc"});

				# -------------------------------------------------
				# check result, 
				# -------------------------------------------------
	$fhpcc = 'FHPCC';
	$Lok=       &open_file($fhpcc,$file{"pcc"});
	return(0,"*** ERROR $sbr: '$file{\"pcc\"}' not opened\n") if (! $Lok);
	# TODO: in case there's nothing to return add a message!
#	close $fhcys;

	if ( $Lok == 1 ) {
	    $#tmpAppend=0;	  
	    push(@tmpAppend,$envPP{"fileAppPcc"},
		 $file{"pcc"},$envPP{"fileAppLine"});
	    
	    # ------------------------------
	    # append HTML output
	    # ------------------------------
	    if ($optOut=~/ret html/ && -e $file{"pcc"}){ 
		# append file
		($Lok,$msg)=&htmlBuild($file{"pcc"},$fileHtmlTmp,$fileHtmlToc,1,"pcc");
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=pcc)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2250",$msg); }
	    }
	}

		
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){	# 
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=570",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }

    return(1,"ok","$sbr:$msg");
}				# end runPredCC






#===============================================================================
# GY ADDED 2-2004: CHOP
#===============================================================================
sub runChop {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeCopf,$exeChop,$dirChop,$parChopBlastE,$parChopHmmerE,$parChopDomCov,$parChopMinFragLen )=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$fileStripOutMod,$arg,$parChopExp,
	  $fileAliList,$fileFastaSingle,@tmpAppend,$txt,$command, $fhcys, @tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runChop:                    CHOP
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runChop";
    $errTxt="err=541"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
#   return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);

    return(0,$errTxt,$msg."exeChop!")        if (! defined $exeChop);
#   return(0,$errTxt,$msg."fileAliPhdIn")     if (! defined $fileAliPhdIn);
    return(0,$errTxt,$msg."parChopBlastE")        if (! defined $parChopBlastE);
    return(0,$errTxt,$msg."parChopHmmerE")    if (! defined $parChopHmmerE);
    return(0,$errTxt,$msg."parChopDomCov")    if (! defined $parChopDomCov);
    return(0,$errTxt,$msg."parChopMinFragLen")    if (! defined $parChopMinFragLen);

    $errTxt="err=542"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=543"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=544"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeChop) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=545","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

#    return(0,"err=546","*** $sbr: no hssp =".$fileAliPhdIn."!")
#	if (! -e $fileAliPhdIn && ! -l $fileAliPhdIn);

    $msgErrIntern=    $msgErr{"internal"}; 
    $msgErrConvert=   $msgErr{"align:convert"};
#    $msgErrProfCon=     $msgErr{"runProfCon:profcon"};
#    $msgErr=    $msgErr{":"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/chop,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/chop,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/chop,//g;}
    
				# ---------------------------------------------
				# CHOP can only take single sequence
				# in case input is list, get the first fasta file
				# ---------------------------------------------
    if ( $optSeq =~ /saf|msf/) {
	$file{"seq4chop"}=    $dirWork. $fileJobId.  ".fastaSingle";
	push(@kwdRm,"seq4chop");
	
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqFasta"});
	return(0,"err=551",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seq4chop"},$id,$seq);
	return(0,"err=552",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=553",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seq4chop"}."' written \n") if (! -e $file{"seq4chop"});
    } else {
	$file{"seq4chop"} = $file{"seqFasta"};
    }

				# --------------------------------------------------
                                # CHOP program
				# --------------------------------------------------
    if ($optRun =~/chop/) {
	$file{"chop"}=        $dirWork.$fileJobId.".chop";   
	push(@kwdRm,"chop");

					# extract expert options
	if ( $optRun =~ /parChop\(([^\(]+)\)/ ) {
	    $parChopExp = $1;
	    if ( $parChopExp =~ /blastE\=([0-9\.]+)/ ) {
		$parChopBlastE = $1;
	    }
	    if ($parChopExp =~ /hmmerE\=([0-9\.]+)/ ) {
		$parChopHmmerE = $1;
	    }
	    if ($parChopExp =~ /domcov\=([0-9\.]+)/ ) {
		$parChopDomCov = $1;
	    }
	    if ($parChopExp =~ /minfrag\=([0-9]+)/ ) {
		$parChopMinFragLen = $1;
	    }
	}

	$arg = "";
	$arg .= " -hmmerE ".$parChopHmmerE;
	$arg .= " -blastE ".$parChopBlastE;
	$arg .= " -minDomainCover ".$parChopDomCov;
	$arg .= " -minFragLen2report ".$parChopMinFragLen;
	$arg .= " -i $file{\"seq4chop\"} ";
	$arg .= " -o $file{\"chop\"} ";
	if ( $optOut=~/ret html/ ) {
	    $arg .= " -html ";
	}

				# set env CHOP dir (required for the program)
	if (! defined $ENV{"CHOP"} ) {
	    $ENV{"CHOP"} = $dirChop;
	}

	$command="$nice $exeChop $arg";
	$msgHere="--- $sbr system '$exeChop $command'";
				# --------------------------------------------------
				# do run  CHOP
				# --------------------------------------------------
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=560","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	if (! $Lok || ! -e $file{"chop"});

				# -------------------------------------------------
				# check result, 
				# -------------------------------------------------
	$fhchop = 'FHCHOP';
	$Lok=       &open_file($fhchop,$file{"chop"});
	return(0,"*** ERROR $sbr: '$file{\"chop\"}' not opened\n") if (! $Lok);
	# TODO: in case there's nothing to return add a message!

	if ( $Lok == 1 ) {
	    $#tmpAppend=0;

	    push(@tmpAppend,$envPP{"fileAppChop"},
		 $file{"chop"},$envPP{"fileAppLine"});

	    # ------------------------------
	    # append HTML output
	    # ------------------------------

	
	    if ($optOut=~/ret html/ && -e $file{"chop"}){ 
		    # append file
		($Lok,$msg)=&htmlBuild($file{"chop"},$fileHtmlTmp,$fileHtmlToc,0,"chop");
		
		
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=chop)\n".$msg."\n";
			      print $fhTrace $msg; # 
			      return(0,"err=2250",$msg); }
	    }
	}	 
	
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){	# 
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);

		return(0,"err=570",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }

    return(1,"ok","$sbr:$msg");
}			# end runChop


#===============================================================================
# GY ADDED 2-2004: P3I{Predict Prot Prot interaction} app
#===============================================================================
sub runPredZafi {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeMaxhom,$exeZafi,$dirZafi)=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$fileStripOutMod,
	  $fileAliList,$fileFastaSingle,@tmpAppend,$txt,$command, $fhcys, @tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runZafi                    : predict prot prot interaction
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runZafi";
    $errTxt="err=541"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
    return(0,$errTxt,$msg."exeZafi!")        if (! defined $exeZafi);

    $errTxt="err=542"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=543"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=544"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeZafi) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=545","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});


    $msgErrIntern=    $msgErr{"internal"}; 
    $msgErrConvert=   $msgErr{"align:convert"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/zafi,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/zafi,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/zafi,//g;}
    
				# ---------------------------------------------
				# can only take single sequence
				# in case input is list, get the first fasta file
				# ---------------------------------------------
    if ( $optSeq =~ /saf|msf/) {
	$file{"seq4zafi"}=    $dirWork. $fileJobId.  ".fastaSingle";
	push(@kwdRm,"seq4zafi");
	
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqFasta"});
	return(0,"err=551",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seq4zafi"},$id,$seq);
	return(0,"err=552",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=553",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seq4zafi"}."' written \n") if (! -e $file{"seq4zafi"});
    } else {
	$file{"seq4zafi"} = $file{"seqFasta"};
    }

				# --------------------------------------------------
                                # Predict Prot Prot interaction program
				# --------------------------------------------------
    if ($optRun =~/zafi/) {
	$file{"zafi"}=        $dirWork.$fileJobId.".zafi";   
	push(@kwdRm,"zafi");

				# set env ZAFI dir (required for the program)
	if (! defined $ENV{"ZAFI"} ) {
	    $ENV{"ZAFI"} = $dirZafi;
	}

#	$command="$nice $exeZafi ". "$file{\"seq4zafi\"} > $file{\"zafi\"} $exeMaxhom";
	$command="$nice $exeZafi none ". "$file{\"seq4zafi\"} $exeMaxhom";
	$msgHere="--- $sbr system '$exeZafi $command'";
				# --------------------------------------------------
				# do run Predict Prot Prot Interaction
				# --------------------------------------------------
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=560","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	if (! $Lok || ! -e $file{"zafi"});

				# -------------------------------------------------
				# check result, 
				# -------------------------------------------------
	$fhzafi = 'FHZAFI';
	$Lok=       &open_file($fhzafi,$file{"zafi"});
	return(0,"*** ERROR $sbr: '$file{\"zafi\"}' not opened\n") if (! $Lok);

	if ( $Lok == 1 ) {
	    $#tmpAppend=0;	  
	    push(@tmpAppend,$envPP{"fileAppZafi"},
		 $file{"zafi"},$envPP{"fileAppLine"});
	    
	    # ------------------------------
	    # append HTML output
	    # ------------------------------
	    if ($optOut=~/ret html/ && -e $file{"zafi"}){ 
		# append file
		($Lok,$msg)=&htmlBuild($file{"zafi"},$fileHtmlTmp,$fileHtmlToc,1,"zafi");
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=zafi)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2250",$msg); }
	    }
	}

		
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){	# 
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=570",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }

    return(1,"ok","$sbr:$msg");
}				# end ruPredZafi


#===============================================================================
# GY ADDED 3-2004: PROFTMB app
#===============================================================================
sub runProfTmb {
    local($origin,$date,$nice,$fileJobId,$fhOutSbr,$fhErrSbr,
	  $dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,$Ldebug,$optRun,$optOut,
	  $exeCopf,$exeProfTmb,$dirProfTmb)=@_;

    local($sbr,$msgHere,$msg,$fileOut,$Lok,$fileStripOutMod,
	  $fileAliList,$fileFastaSingle,@tmpAppend,$txt,$command, $fhcys, @tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   runProfTmb                : ProfTmb
#       in:                     many
#       in GLOBAL:              $msgErr{""}, $file{""}, @kwdRm, $envPP{"file*"}
#       in GLOBAL:              $file{"seqFasta"}     seq in FASTA format (from modInterpret)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="runProfTmb";
    $errTxt="err=541"; $msg="*** $sbr: not def ";
    return(0,$errTxt,$msg."origin!")          if (! defined $origin);
    return(0,$errTxt,$msg."date!")            if (! defined $date);
    return(0,$errTxt,$msg."nice!")            if (! defined $nice);
    return(0,$errTxt,$msg."fileJobId!")       if (! defined $fileJobId);
    $fhOutSbr="STDOUT"                        if (! defined $fhOutSbr);
    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    return(0,$errTxt,$msg."dirWork!")         if (! defined $dirWork);
    return(0,$errTxt,$msg."filePredTmp!")     if (! defined $filePredTmp);
    return(0,$errTxt,$msg."fileHtmlTmp!")     if (! defined $fileHtmlTmp);
    return(0,$errTxt,$msg."fileHtmlToc!")     if (! defined $fileHtmlToc);
    return(0,$errTxt,$msg."Ldebug!")          if (! defined $Ldebug);
    return(0,$errTxt,$msg."optRun!")          if (! defined $optRun);
    return(0,$errTxt,$msg."optOut!")          if (! defined $optOut);
#   return(0,$errTxt,$msg."exeConvertSeq!")   if (! defined $exeConvertSeq);

    return(0,$errTxt,$msg."exeProfTmb!")        if (! defined $exeProfTmb);
#   return(0,$errTxt,$msg."fileAliPhdIn")     if (! defined $fileAliPhdIn);

    $errTxt="err=542"; $msg="*** $sbr: no dir ="; # 
    return(0,$errTxt,$msg."$dirWork!")        if (! -d $dirWork);

    $errTxt="err=543"; $msg="*** $sbr: no file=";
    return(0,$errTxt,$msg."$filePredTmp!")    if (! -e $filePredTmp && ! -l $filePredTmp);

    $errTxt="err=544"; $msg="*** $sbr: no exe =";
    foreach $exe ($exeProfTmb) {
	return(0,$errTxt,$msg."$exe!")        if (! -e $exe && ! -l $exe); }

    return(0,"err=545","*** $sbr: no seq =".$file{"seq"}."!")   
	if (! -e $file{"seq"} && ! -l $file{"seq"});

#    return(0,"err=546","*** $sbr: no hssp =".$fileAliPhdIn."!")
#	if (! -e $fileAliPhdIn && ! -l $fileAliPhdIn);

    $msgErrIntern=    $msgErr{"internal"}; 
    $msgErrConvert=   $msgErr{"align:convert"};
#    $msgErrProfTmb=     $msgErr{"runProfTmb:ProfTmb"};
#    $msgErr=    $msgErr{":"};
    $msgHere="";
				# ------------------------------
				# convert_seq -> FASTA (if not already)
    if (! defined $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not defined\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/ProfTmb,//g;}
    elsif (! -e $file{"seqFasta"}){
	print $fhErrSbr "*** in $sbr file{seqFasta} not existing (modInterpret lazy??)\n";
	print $fhErrSbr "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/ProfTmb,//g;}
    elsif (! &isFasta($file{"seqFasta"})){
	print $fhErrSbr 
	    "*** in $sbr file{seqFasta}=",$file{"seqFasta"},
	    ", not in FASTA format (modInterpret lazy??)\n",
	    "*** WATCH will change optRun ($optRun)!!\n" x 3;
	$optRun=~s/ProfTmb,//g;}
    
				# ---------------------------------------------
				# ProfTmb can only take single sequence
				# in case input is list, get the first fasta file
				# ---------------------------------------------
    if ( $optSeq =~ /saf|msf/) {
	$file{"seq4ProfTmb"}=    $dirWork. $fileJobId.  ".fastaSingle";
	push(@kwdRm,"seq4ProfTmb");
	
	($Lok,$id,$seq)=&fastaRdGuide($file{"seqFasta"});
	return(0,"err=551",$msgErrConvert."\n".$id."\n".
	       "*** file{seq}=".$file{"seq"}."\n") if (! $Lok);
	$seq=~s/[ \.\~\*]//g;	# remove non amino acids!
	
	($Lok,$msg)=&fastaWrt($file{"seq4ProfTmb"},$id,$seq);
	return(0,"err=552",$msgErrConvert."\n"."*** fastaWrt\n".$msg."*** id=$id, seq=$seq\n")
	    if (! $Lok);
	return(0,"err=553",$msgErrConvert."\n"."*** fastaWrt\n"."*** id=$id, seq=$seq\n".
	       "*** no file '".$file{"seq4ProfTmb"}."' written \n") if (! -e $file{"seq4ProfTmb"});
    } else {
	$file{"seq4ProfTmb"} = $file{"seqFasta"};
    }

				# --------------------------------------------------
                                # ProfTmb program
				# --------------------------------------------------
    if ($optRun =~/ProfTmb/) {
	$file{"ProfTmb"}=        $dirWork.$fileJobId.".ProfTmb";   
	push(@kwdRm,"ProfTmb");

				# set env ProfTmb dir (required for the program)
	if (! defined $ENV{"ProfTmb"} ) {
	    $ENV{"ProfTmb"} = $dirProfTmb;
	}

	# TBD: find name of protein
	$UserProtName = "TBD";
	# ProfTmb takes a protein name (up to 8 chars) 
	# To preserve uniquness of filename we use the filejobid and make sure its no longer then last 8 chars
	my $ProfTmbProtName = $UserProtName.".".$fileJobId;

	# Usage: ./run_prof08.pl protein_name(MAX 8 char.) file.fasta file.hssp file.rdbProf
	# trim filejobid to be at most 8 chars

	$command="$nice $exeProfTmb "."$ProfTmbProtName ".
	    "$file{\"seq4ProfTmb\"} $file{\"hsspPsiFil\"} $file{\"profRdb\"} > $file{\"ProfTmb\"} ";
	$msgHere="--- $sbr system '$exeProfTmb $command'";
				# --------------------------------------------------
				# do run ProfTmb
				# --------------------------------------------------
	($Lok,$msgSys)=&sysSystem("$command");

	return (0,"err=560","*** ERROR $sbr\n"."$msgHere\n"."$Lok\n")
	if (! $Lok || ! -e $file{"ProfTmb"});

				# -------------------------------------------------
				# check result, 
				# -------------------------------------------------
	$fhpcon = 'FHPCON';
	$Lok=       &open_file($fhpcon,$file{"ProfTmb"});
	return(0,"*** ERROR $sbr: '$file{\"ProfTmb\"}' not opened\n") if (! $Lok);
	# TODO: in case there's nothing to return add a message!
#	close $fhcys;

	if ( $Lok == 1 ) {
	    $#tmpAppend=0;	  
	    push(@tmpAppend,$envPP{"fileAppProfTmb"},
		 $file{"ProfTmb"},$envPP{"fileAppLine"});
	    
	    # ------------------------------
	    # append HTML output
	    # ------------------------------
	    if ($optOut=~/ret html/ && -e $file{"ProfTmb"}){ 
		# append file
		($Lok,$msg)=&htmlBuild($file{"ProfTmb"},$fileHtmlTmp,$fileHtmlToc,1,"ProfTmb");
		if (! $Lok) { $msg="*** err=2250 ($sbr: htmlBuild failed on kwd=ProfTmb)\n".$msg."\n";
			      print $fhTrace $msg;
			      return(0,"err=2250",$msg); }
	    }
	}

		
	# --------------------------------------------------
	# append files
	# --------------------------------------------------
	if ($origin =~ /^mail|^html|^testPP/i){
	    if ($#tmpAppend>0){	# 
		# print "debug=$Ldebug; predTmp=$filePredTmp;tmpAp=@tmpAppend\n";
		($Lok,$msg)=&sysCatfile("nonice",$Ldebug,$filePredTmp,@tmpAppend);
		return(0,"err=570",$msgErrIntern."\n". 
		       "align final appending...\n: $msg,\n"."$msgHere") if (! $Lok);}
	}
    }

    return(1,"ok","$sbr:$msg");
}				# end runProfTmb
























1;

#================================================================================
#   end of perl script to run the PHD server
#================================================================================
