#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@columbia.edu	       #
#	Wilckensstr. 15		http://cubic.bioc.columbia.edu/ 	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Sep,    	1998	       #
#				version 0.2   	Oct,    	1998	       #
#				version 0.3   	Dec,    	1999	       #
#				version 0.4   	Mar,    	2000	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with routines related to converting PROF.rdb to PROF.prof.      #
#    Note: entire thing exchangable with conv_prof2mis.pl                     #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 

#===============================================================================
sub convProf {
    local($fileInRdbLoc,$fileInAliLoc,$fileOutLoc,$modeWrtLoc,$nresPerLineLoc,
	  $riSubAccLoc,$riSubHtmLoc,$riSubSecLoc,$riSubSymLoc,
	  $txtPreRowLoc,$Lscreen,$rh_fileOut
#	  ,$kwdokLoc
	  ) = @_ ;
    local($SBR1,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf                     convert PROF.rdb to <ASCII|MSF|SAF|DSSP|CASP>
#                               
#       in:                     $fileInRdbLoc=    PROFrdb file (0, if %rdb already defined)
#       in:                     $fileInAliLoc=    HSSP file (0, if already read OR NOT to take)
#           if NO file GLOBAL in:   %rdb{"NROWS"},$rdb{$itres,$kwd},                        
#       in:                     $fileOutLoc=      HTML output file
#                               =0                -> STDOUT
#       in:                     $modeWrtLoc=      mode for job, any of the following (or all)
#                                  dssp           write DSSP format
#                                  msf            write MSF format
#                                  saf            write SAF format
#                                  casp           write CASP2 format
#                               
#                                  header         write header with notation
#                                  notation       
#                                  averages       compile averages (AA,SS)
#                                         
#                                  brief          only secondary structure and reliability
#                                  normal         predictions + rel + subsets
#                                  subset         include SUBset of more reliable predictions
#                                  detail         include ASCII graph
#                                  ali            include alignment 
#                                         
#                                         
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       in:                     $txtPreRowLoc=    'pre' will be used before every row
#       in:                     $Lscreen=         =1 (or filehandle) will additionally write
#                                                 output to screen (at least, some of it)
#       in (option):            $rh_fileOut=      $rh_fileOut{<saf|msf|dssp|casp|ascii>}
#       in (option):            $kwdok=           list of keyword in %rdb (comma separated)
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR1=$tmp."convProf";
				# check arguments
    return(&errSbr("not def fileInRdbLoc!",  $SBR1)) if (! defined $fileInRdbLoc);
    return(&errSbr("not def fileInAliLoc!",  $SBR1)) if (! defined $fileInAliLoc);
    return(&errSbr("not def fileOutLoc!",    $SBR1)) if (! defined $fileOutLoc);
    return(&errSbr("not def modeWrtLoc!",    $SBR1)) if (! defined $modeWrtLoc);
    return(&errSbr("not def nresPerLineLoc!",$SBR1)) if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubAccLoc!",   $SBR1)) if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",   $SBR1)) if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSecLoc!",   $SBR1)) if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubSymLoc!",   $SBR1)) if (! defined $txtPreRowLoc);
    return(&errSbr("not def txtPreRowLoc!",  $SBR1)) if (! defined $txtPreRowLoc);
    $Lscreen=   0                                    if (! defined $Lscreen);
    $rh_fileOut=0                                    if (! defined $rh_fileOut);
    $kwdokLoc=  0                                    if (! defined $kwdokLoc);

    return(&errSbr("no fileInRdb=$fileInRdbLoc!",$SBR1))   if ($fileInRdbLoc  && ! -e $fileInRdbLoc);
    return(&errSbr("no fileInAli=$fileInAliLoc!",$SBR1))   if ($fileInAliLoc && ! -e $fileInAliLoc);

				# --------------------------------------------------
				# (0) ini names
				# out GLOBAL: @kwdBody,$lenAbbr,%transSec2Htm
				#             %transSym,%transAbbr,%transDescr
				# --------------------------------------------------
    ($Lok,$msg)=
	&convProf_ini($nresPerLineLoc,$modeWrtLoc,
		      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
		      $txtPreRowLoc
		      );        return(&errSbr("failed on convProf_ini($nresPerLineLoc,".
					       "$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc)\n".
					       $msg."\n",$SBR1)) if (! $Lok);

				# --------------------------------------------------
				# (1a) read RDB file OR: use
				#      GLOBAL IN/OUT %rdb
				#      GLOBAL IN/OUT %prot
				#      alternative (actually USED):
				#      data passed from lib-prof
				# --------------------------------------------------
    if ($fileInRdbLoc || $fileInAliLoc){
	($Lok,$msg)=
	    &convProf_rdinput($fileInRdbLoc,$fileInAliLoc
			     ); return(&errSbrMsg("failed rdb=$fileInRdbLoc, prot=$fileInAliLoc",
						  $msg,$SBR1)) if (! $Lok);}

				# ------------------------------
				# (1b) correct column names
				#      effective for 
				#      --> PROFhtm
				#      --> 3
    ($Lok,$msg)=
	&convProf_correct
	    ($kwdokLoc);        return(&errSbrMsg("failed correcting column names",
						  $msg,$SBR1)) if (! $Lok);

    $titleLoc= $fileInRdbLoc; $titleLoc=~s/^.*\/|\..*$//g;
    if (! $titleLoc){
	$titleLoc=  $rdb{"prot_id"};
	$titleLoc.=" ".$rdb{"prot_name"} if (defined $rdb{"prot_name"});
    }
    $rdb{"id"}=$titleLoc        if (! defined $rdb{"id"} || length($rdb{"id"}) < 1);

				# --------------------------------------------------
				# (2a) ASCII
				# --------------------------------------------------
	
    if ($modeWrtLoc=~/ascii/){
				# get some statistics asf
	if ($Lsummary || $Laverages){
	    ($Lok,$msg)=
		&convProf_preProcess
		    ($riSubAccLoc
		     );         return(&errSbr("failed convProf_preProcess".$msg,
					       $SBR1)) if (! $Lok); }
	$fileOutLoc2=$fileOutLoc;
	$fileOutLoc2=~s/\.misProf/\.prof/;
	$fileOutLoc2=$rh_fileOut->{"ascii"} if (defined $rh_fileOut->{"ascii"} && 
						length($rh_fileOut->{"ascii"})>3);

				# open output file
	open($fhoutMis,">".$fileOutLoc2) || 
	    return(&errSbr("fileOutLoc2=$fileOutLoc2, not created",$SBR1));
				# write ASCII header
				# in GLOBAL: %transDescr,%transAbbr,$Lbrief,$Lnormal,$Ldetail
	if ($Lheader){
	    ($Lok,$msg)=
		&convProf_wrtHead
		    ($titleLoc,$fhoutMis,\@kwdHead,\@kwdBody
		     );         return(&errSbr("failed convProf_wrtHead".$msg,$SBR1))  if (! $Lok); }
				# now do write
	($Lok,$msg)=
	    &convProf_wrtAsciiBody
		($fhoutMis,$txtPreRowLoc
		 );             return(&errSbr("failed convProf_wrtAsciiBody".$msg,$SBR1)) if (! $Lok); 
	close($fhoutMis)        if ($fhoutMis ne "STDOUT"); 

#	print "--- $SBR1: wrote file ASCII=$fileOutLoc2\n" 
#	    if (defined $par{"verbose"} && $par{"verbose"});
    }
    

				# --------------------------------------------------
				# (2b) all others
				# --------------------------------------------------
				# get all to write
    foreach $tmp ("msf","saf","dssp","casp"){
	push(@formatTmp,$tmp)   if ($modeWrtLoc=~/$tmp/);}
				# loop over all formats
    foreach $formatWant (@formatTmp){

				# check whether protein file exists
	if ($formatWant =~ /^(msf|saf)$/i && ! $fileInAliLoc){
	    print "*** ERROR $SBR1: you MUST give an alignment file for the option $formatWant!\n";
	    next; }

	$#kwdBodyTmp=0;
	foreach $kwd (@kwdBody) {
	    next if ($kwd=~/^p[HELTMN]|^[OP]be/ && $formatWant !~/casp/) ;
	    push(@kwdBodyTmp,$kwd); }
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	$tmp1=substr($formatWant,1,1); 
	$tmp1=~tr/[a-z]/[A-Z]/;
	$tmp=$tmp1.substr($formatWant,2);
	if (defined $par{"extProf".$tmp}){
	    $ext=$par{"extProf".$tmp};}
	else{
	    $ext=".".$formatWant."Prof";}
	$fileOutLoc2=$fileOutLoc; 
	$fileOutLoc2=~s/\..*$/$ext/;
	$fileOutLoc2=$rh_fileOut->{$formatWant} if (defined $rh_fileOut->{$formatWant} && 
						    length($rh_fileOut->{$formatWant})>3);
				# open output file
	if ($fhoutMis ne "STDOUT"){
	    open($fhoutMis,">".$fileOutLoc2) || 
		return(&errSbr("fileOutLoc2=$fileOutLoc2, not created",$SBR1));
	}

				# ------------------------------
				# MSF and SAF
	if    ($formatWant=~/saf|msf/) {
	    ($Lok,$msg)=
		&convProf_wrtAliBody
		    ($fhoutMis,$formatWant
		     );         return(&errSbrMsg("failed convProf_wrtAliBody",
						  $msg,$SBR1)) if (! $Lok); }
				# ------------------------------
				# CASP
	elsif ($formatWant=~/casp/){
	    ($Lok,$msg)=
		&convProf_wrtCaspBody
		    ($fhoutMis
		     );         return(&errSbrMsg("failed convProf_wrtCaspBody",
						  $msg,$SBR1)) if (! $Lok); }
				# ------------------------------
				# DSSP
	elsif ($formatWant=~/dssp/){
	    ($Lok,$msg,$wrtWarn)=
		&convProf_wrtDsspBody
		    ($fhoutMis
		     );         return(&errSbrMsg("failed convProf_wrtDsspBody",
						  $msg,$SBR1)) if (! $Lok); 
				# warnings
	    if (length($wrtWarn) > 1){
		$fileWarn="PROFconv.warnings";
		$fileWarn=$par{"fileOutWarn"} if (defined $par{"fileOutWarn"});
		print 
		    "-*- ". "-*-" x 20 ,"\n",
		    "-*- WARN $SBR1: \n",
		    "-*-      serious problem converting $fileInRdbLoc to DSSP!\n",
		    "-*-      for info see file=$fileWarn!\n",
		    "-*- ". "-*-" x 20 ,"\n";
		open("FHOUT_WARN",">>".$fileWarn);
		print FHOUT_WARN $wrtWarn;
		close("FHOUT_WARN");
		$wrtWarn="";}}
	else {
	    print "-*- WARN $SBR1: formatWant=$formatWant, not recognised\n";
	}
	close($fhoutMis)    if ($fhoutMis ne "STDOUT"); 

#	print "--- $SBR1: wrote file $formatWant=$fileOutLoc2\n" 
#	    if (defined $par{"verbose"} && $par{"verbose"});
    }
    return(1,"ok $SBR1");
}				# end of convProf

#===============================================================================
sub convProf_ini {
    local($nresPerLineLoc,$modeWrtLoc,
	  $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
	  $txtPreRowLoc)=@_;
    local($SBR3,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_ini                 initialise variables
#                               
#       in:                     $nresPerLineLoc=  number of residues per line
#                               
#       in:                     $modeWrtLoc=      mode for job, any of the following (or all)
#                                  dssp           write DSSP format
#                                  msf            write MSF format
#                                  saf            write SAF format
#                                  casp           write CASP2 format
#                               
#                                  header         write header with notation
#                                  notation       
#                                  averages       compile averages (AA,SS)
#                                         
#                                  brief          only secondary structure and reliability
#                                  normal         predictions + rel + subsets
#                                  subset         include SUBset of more reliable predictions
#                                  detail         include ASCII graph
#                                  ali            include alignment 
#                                         
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       in:                     $txtPreRowLoc=    'pre' will be used before every row
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."convProf_ini";
    $fhinLoc="FHIN_"."convProf_ini";$fhoutLoc="FHOUT_"."convProf_ini";
				# check arguments
    return(&errSbr("not def nresPerLineLoc!",$SBR3))  if (! defined $nresPerLineLoc);
    return(&errSbr("not def modeWrtLoc!",    $SBR1))  if (! defined $modeWrtLoc);
    return(&errSbr("not def riSubSecLoc!",   $SBR3))  if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",   $SBR3))  if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",   $SBR3))  if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",   $SBR3))  if (! defined $riSubSymLoc);
    return(&errSbr("not def txtPreRowLoc!",  $SBR3))  if (! defined $txtPreRowLoc);

				# ------------------------------
				# file handle
    $fileOutLoc=0               if ($fileOutLoc eq "STDOUT");
    $fhoutMis="FHOUT_convProf";
    $fhoutMis="STDOUT"          if (! $fileOutLoc);

				# ------------------------------
				# digest mode
				# ------------------------------
    $Lheader=$Lnotation=$Laverages=$Lsummary=
	$Lbrief=$Lnormal=$Lgraph=$Lsubset=$Ldetail=
	    $Lali=0;

				# what to write: header
    $Lheader=         1         if ($modeWrtLoc=~/header/);
    $Laverages=       1         if ($modeWrtLoc=~/average/);
    $Lnotation=       1         if ($modeWrtLoc=~/notation/);
    $Lsummary=        1         if ($modeWrtLoc=~/summary/);
    $Linfo=           1         if ($modeWrtLoc=~/info/);
				# what to write: body
    $Lbrief=          1         if ($modeWrtLoc=~/brief/);
    $Lnormal=         1         if ($modeWrtLoc=~/normal/);
    $Lsubset=         1         if ($modeWrtLoc=~/subset/);
    $Ldetail=         1         if ($modeWrtLoc=~/detail/);
    $Lgraph=          1         if ($modeWrtLoc=~/graph/);

    $Lali=            1         if ($modeWrtLoc=~/ali|msf|saf/);

    $fhscreen="STDOUT";
    $fhscreen=$Lscreen          if ($Lscreen && $Lscreen ne "1");

				# columns to read
    @kwdBody=
	(
	 "AA",
	 "OHEL","PHEL",                          "RI_S",               "pH","pE","pL",
	 "OHELBGT","PHELBGT",
	 "Obe","Pbe","Obie","Pbie","OREL","PREL","RI_A",               

	 "OMN", "PMN","PRMN","PR2MN","PiTo",     "RI_M",               "pM","pN",
				# caps HTM
	 "OHcapH","PHcapH",                      "RI_HcapH",           "ph_HcapH", "pn_HcapH",
	 "OEcapH","PEcapH",                      "RI_EcapH",           "pe_EcapH", "pn_EcapH",
	 "OHcapH","PHcapH",                      "RI_HEcapH",          "pp_HEcapH","pn_HEcapH",
				# caps SEC
	 "OHcapS","PHcapS",                      "RI_HcapS",           "ph_HcapS", "pn_HcapS", 
	 "OEcapS","PEcapS",                      "RI_EcapS",           "pe_EcapS", "pn_EcapS", 
	 "OHcapS","PHcapS",                      "RI_HEcapS",          "pp_HEcapS","pn_HEcapS",

#	 "","","","",
	 );
    @kwdBodyOld=
	(
	 "OTN","PTN","OHL","PHL","RI_H","PRTN","PRHL","PiTo","pT","pN"
	 );
				# for HTM : header
    @kwdHead=
	(
	 "HTM_NHTM_BEST","HTM_NHTM_2ND_BEST",
	 "HTM_REL_BEST","HTM_REL_BEST_DIFF", "HTM_REL_BEST_DPROJ",
	 "HTM_MODEL","HTM_MODEL_DAT",
	 "HTM_HTMTOP_OBS","HTM_HTMTOP_PRD","HTM_HTMTOP_MODPRD",
	 "HTM_HTMTOP_RID","HTM_HTMTOP_RIP",

	 "NHTM_BEST","NHTM_2ND_BEST",
	 "REL_BEST","REL_BEST_DIFF", "REL_BEST_DPROJ",
	 "MODEL","MODEL_DAT",
	 "HTMTOP_OBS","HTMTOP_PRD","HTMTOP_MODPRD","HTMTOP_RID","HTMTOP_RIP",

	 "NALIGN",
	 
	 "prot_id","prot_name",
	 "prot_nres","prot_nali","prot_nchn","prot_kchn","prot_nfar",
	 "prot_cut",
	 "ali_orig","ali_used","ali_para",
	 "prof_fpar","prof_nnet","prof_mode","prof_version","prof_skip"
	 );

				# e.g. 'L' to ' ' in writing
    %transSym=
	('L',    " ",
#	 'i',    " ",
	 'N',    " ",
	 'n',    " ",
	 );
				# translate PROFsec to PROFhtm
    %transSec2Htm=
	('H',    "M",
	 'E',    "N",
	 'L',    "N",
	 'T',    "M",
	 'M',    "M",
	 'N',    "N",

	 );
				# abbreviations translated in array read
    %transData=
	('OTN',    "OMN",
	 'PTN',    "PMN",
	 'PRTN',   "PRMN",
#	 'PFTN',   "PFMN",
#	 'PiTo',   "PiMo",
	 'PiMo',   "PiTo",
	 'RI_H',   "RI_M",
	 'OtT',    "OtM",
	 'pH',     "pM",
	 'pT',     "pM",
	 'pL',     "pM",
	 
	 'RI_S',   "RI_M",
	 
	 'OHL',    "OMN",
	 'PHL',    "PMN",
	 'PRHL',   "PRMN",
	 'pH',     "pM",
	 'pL',     "pN",
	 'OtH',    "OtM",
	 'OtL',    "OtN",
	 );

				# abbreviations used to write the rows
    %transAbbr=
	(
	 'AA'  ,   "AA ",

	 'OHEL',   "OBS_sec",
	 'PHEL',   "PROF_sec",
	 'OHELBGT',"OBS_sec6",
	 'PHELBGT',"PROF_sec6",
	 'RI_S',   "Rel_sec",
	 'SUBsec', "SUB_sec",
	 'pH',     " pH_sec",
	 'pE',     " pE_sec",
	 'pL',     " pL_sec",
#	 '', "",

	 'OREL',   "OBS_acc",
	 'PREL',   "PROF_acc",
	 'Obe',    "O_2_acc",
	 'Pbe',    "P_2_acc",
	 'Obie',   "O_3_acc",
	 'Pbie',   "P_3_acc",
	 'RI_A',   "Rel_acc",
	 'SUBacc', "SUB_acc",
#	 '', "",

	 'OMN',    "OBS_htm",
	 'PMN',    "PROF_htm",
	 'PRMN',   "PROFrhtm",
	 'PR2MN',  "PROF2htm",
#	 'PFMN',   "PROFfhtm",
#	 'PiMo',   "PiMohtm",
	 'PiTo',   "PiTohtm",
	 'RI_M',   "Rel_htm",
	 'SUBhtm', "SUB_htm",
	 'pM',     " pT_htm",
	 'pN',     " pN_htm",
#	 '', "",

	 );
	       
    %transDescr=
	(
				# sequence
	 'AA',     "amino acid sequence",
				# secondary structure
	 'OHEL',   "observed secondary structure: H=helix, E=extended (sheet), blank=other (loop)",
	           
	         
	 'PHEL',   "PROF predicted secondary structure: H=helix, E=extended (sheet), blank=other (loop)".
	           "\n"."PROF = PROF: Profile network prediction HeiDelberg",
	 'OHELBGT',"observed secondary structure: H=helix, E=extended (sheet), B=bet-turn, G=3/10 helix, T=turn, blank=other (loop)",
	           
	         
	 'PHELBGT',"PROF predicted secondary structure: H=helix, E=extended (sheet), B=bet-turn, G=3/10 helix, T=turn, blank=other (loop)".
	           "\n"."PROF = PROF: Profile network prediction HeiDelberg",
	 'RI_S',   "reliability index for PROFsec prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBsec', "subset of the PROFsec prediction, for all residues with an expected average accuracy > 82% (tables in header)\n".
	           "NOTE: for this subset the following symbols are used:\n".
	           "  L: is loop (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubSecLoc\n",
	 'pH',     "'probability' for assigning helix (1=high, 0=low)",
	 'pE',     "'probability' for assigning strand (1=high, 0=low)",
	 'pL',     "'probability' for assigning neither helix, nor strand (1=high, 0=low)",


				# solvent accessibility
	 'OREL',   "observed relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
	 'PREL',   "PROF predicted relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
	 'Obe',    "observerd relative solvent accessibility (acc) in 2 states: b = 0-16%, e = 16-100%.",
	 'Obie',   "observerd relative solvent accessibility (acc) in 3 states: b = 0-9%, i = 9-36%, e = 36-100%.",
	 'Pbe',    "PROF predicted  relative solvent accessibility (acc) in 2 states: b = 0-16%, e = 16-100%.",
	 'Pbie',   "PROF predicted relative solvent accessibility (acc) in 3 states: b = 0-9%, i = 9-36%, e = 36-100%.",
	 'RI_A',   "reliability index for PROFacc prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBacc', "subset of the PROFacc prediction, for all residues with an expected average correlation > 0.69 (tables in header)\n".
	           "NOTE: for this subset the following symbols are used:\n".
	           "  I: is intermediate (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubAccLoc\n",

	 '', "",

	 'OMN',    "observed membrane helix: M=helical transmembrane region, blank=non-membrane",
	           
	         
	 'PMN',    "PROF predicted membrane helix: M=helical transmembrane region, blank=non-membrane".
	           "\n"."PROF = PROF: Profile network prediction HeiDelberg",
	 'PRMN',   "refined PROF prediction: M=helical transmembrane region, blank=non-membrane",
	 'PROFrhtm',   "refined PROF prediction: M=helical transmembrane region, blank=non-membrane",
	 'PR2MN',  "2nd best model: M=helical transmembrane region, blank=non-membrane",
	 'PROF2htm',  "2nd best model: M=helical transmembrane region, blank=non-membrane",
#	 'PiMo',   "PROF prediction of membrane topology: T=helical transmembrane region, i=inside of membrane, o=outside of membrane",
	 'PiTo',   "PROF prediction of membrane topology: T=helical transmembrane region, i=inside of membrane, o=outside of membrane",
	 'RI_M',   "reliability index for PROFhtm prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'RI_H',   "reliability index for PROFhtm prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBhtm', "subset of the PROFhtm prediction, for all residues with an expected average accuracy > 98% (tables in header)\n".
	           "NOTE: for this subset the following symbols are used:\n".
	           "  N: is non-membrane region (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubHtmLoc\n",
	 'pM',     "'probability' for assigning transmembrane helix",
	 'pN',     "'probability' for assigning globular region",


	 );
    %transDescrShort=
	('i',      "inside region",
	 'o',      "outside region",
	 'M',      "membrane helix",
	 );

    $lenAbbrBef=9;		# width of empty space BEFORE abbreviation at begin of each row
    $lenAbbrAll=18;		# width of all before the prediction
    $lenLineHdr=72;		# width of typical line

				# ------------------------------
				# number of white spaces in header
    $line_pre= "# ";
    $line_h1=  $line_pre. "=" x ($lenLineHdr-4) ;
    $line_h3=  $line_pre. "-" x ($lenLineHdr-4) ;
    $line_prerow=$txtPreRowLoc;

    return(1,"ok $SBR3");
}				# end of convProf_ini

#===============================================================================
sub convProf_correct {
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_correct             correct column names for old PROF stuff
#                               effective for PROFhtm single AND '3'
#                               
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."convProf_correct";

				# ------------------------------
    $Lis_htm_only=0;		# correct for PROFhtm single
    if ((defined $rdb{"1","PiMo"} && ! defined $rdb{"1","PTN"}) ||
	(defined $rdb{"1","PiMo"} && ! defined $rdb{"1","PMN"}) ||
	(defined $rdb{"1","PiTo"} && 
	 defined $rdb{"1","RI_S"} &&   defined $rdb{"1","OtH"}) ) {
	$Lis_htm_only=1;
	foreach $kwd ("PHL","OHL","PRHL","RI_S","pH","pL","OtH","OtL","PiMo","PTN") {
	    next if (! defined $transData{$kwd} || ! defined $rdb{"1",$kwd});
	    $kwdNew=$transData{$kwd}; $tmp1="";$tmp2="";
	    foreach $it (1 .. $rdb{"NROWS"}) {
		$rdb{$it,$kwdNew}=$sym=$rdb{$it,$kwd};
		$tmp1.=$sym;
		next if (! defined $transSec2Htm{$sym});
#		undef $rdb{$it,$kwd};
		$symNew=$transSec2Htm{$sym};
		$tmp2.=$symNew;
		$rdb{$it,$kwdNew}=$symNew;
	    }
	}}
				# ------------------------------
				# correct for PROFhtm all 3
    else {
	foreach $kwd (
		      "OTN", "PTN", "PRTN","PRFTN","PR2TN","PiMo","RI_H", 
		      "OtT","pT","pN"
		      ) {
	    next if (! defined $rdb{"1",$kwd});
	    $kwdNew=$kwd;
	    $kwdNew=$transData{$kwd}  if (defined $transData{$kwd});
	    next if ($kwd eq $kwdNew);
	    foreach $it (1 .. $rdb{"NROWS"}) {
				# (1) change symbol used
		$sym=$rdb{$it,$kwd};
		$sym=$transSec2Htm{$sym} if (defined $transSec2Htm{$sym});
#		undef $rdb{$it,$kwd};
		$rdb{$it,$kwd}=$sym;
				# (2) change keyword
		$rdb{$it,$kwdNew}=$rdb{$it,$kwd} if ($kwdNew ne $kwd);
	    }
	}}
				# ------------------------------
				# correct PiMo 'T' -> 'M'
    if (defined $rdb{1,"PiMo"}){
	foreach $it (1 .. $rdb{"NROWS"}) {
	    if (! defined $rdb{$it,"PiMo"}){
		print "xx missing res=$it pimo\n";
		foreach $kwd (@kwdRdb){
		    print "$kwd ",$rdb{$it,$kwd},"\n";
		}
		die;
	    }
	    $rdb{$it,"PiMo"}="M" if ($rdb{$it,"PiMo"} eq "T");
	    die "xx $SBR2 (it=$it no PiMo)\n" if (! defined $rdb{$it,"PiMo"});
	}}

    return(1,"ok $SBR2");
}				# end of convProf_correct

#===============================================================================
sub convProf_preProcess {
    local($riSubAccLoc)=@_;
    local($SBR3,$sum,$itres,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_preProcess          compiles probabilites from network output
#                               and composition AND greps stuff from HEADER!
#                               
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $rh_rdb{}= reference passed from reading RDB file
#                               
#       out:                    $rh_rdb{'p<HELTMN>',$it}=   probability
#       out:                    $rh_rdb{'sec','<HELTMN>'}=  secondary str composition
#				         accuracy: 2 decimals, in percentage
#       out:                    $rh_rdb{'sec','class'}=    sec str class 
#                                                          <all-alpha|all-beta|alpha-beta|mixed>
#       out:                    $rh_rdb{'sec','class','txt'}=description of classes (
#                                                          formatted text)
#       out:                    $rh_rdb{'seq','$aa'}=     residue composition
#				         accuracy: 2 decimals, in percentage
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."convProf_preProcess";
				# check arguments
    return(&errSbr("not def riSubAccLoc!",$SBR4))    if (! defined $riSubAccLoc);
#    return(&errSbr("not def rh_rdb!",   $SBR3))    if (! defined $rdb{'NROWS'});

				# ------------------------------
				# compile residue composition
				# ------------------------------
    if (defined $rdb{"1","AA"}) {
	undef %tmp;
	foreach $itres (1..$rdb{"NROWS"}) { 
	    $sym=$rdb{$itres,"AA"};
	    $tmp{$sym}=0        if (! defined $tmp{$sym});
	    ++$tmp{$sym}; }
				# set zero
	foreach $sym (split(//,"ACDEFGHIKLMNPQRSTVWY")) {
	    $rdb{$sym,"seq"}=0; }
	
	if ($rdb{"NROWS"} > 0) {
	    foreach $sym (keys %tmp){
				# accuracy: 2 decimals, in percentage
		$rdb{$sym,"seq"}=
		    sprintf("%6.2f",(100*$tmp{$sym}/$rdb{"NROWS"})) ; }}}
	
				# ------------------------------
				# compile PROFsec prob
				#      pH, pE, pL normalised to 0-9
				#      pH + pE +pL = 9
				# ------------------------------
    if (! defined $rdb{"1","pH"} && defined $rdb{"1","OtH"}) {
	foreach $itres (1..$rdb{"NROWS"}) { 
	    $sum=$rdb{$itres,"OtH"}+$rdb{$itres,"OtE"}+$rdb{$itres,"OtL"};
	    $rdb{$itres,"pH"}=int(10*($rdb{$itres,"OtH"}/$sum));
	    $rdb{$itres,"pH"}=9  if ($rdb{$itres,"pH"} > 9);
	    $rdb{$itres,"pE"}=int(10*($rdb{$itres,"OtE"}/$sum)); 
	    $rdb{$itres,"pE"}=9  if ($rdb{$itres,"pE"} > 9);
	    $rdb{$itres,"pL"}=int(10*($rdb{$itres,"OtL"}/$sum)); 
	    $rdb{$itres,"pL"}=9  if ($rdb{$itres,"pL"} > 9);
	} }
    
				# ------------------------------
				# compile sec str composition
				# ------------------------------
    if (defined $rdb{"1","PHEL"}) {
	undef %tmp;
	foreach $itres (1..$rdb{"NROWS"}) { 
	    $sym=$rdb{$itres,"PHEL"};
	    $tmp{$sym}=0        if (! defined $tmp{$sym});
	    ++$tmp{$sym}; }
                                # set 0
        foreach $sym ("H","E","L","T","N") {
            $rdb{"sec",$sym}=0; }
                                # assign
	if ($rdb{"NROWS"} > 0) {
	    foreach $sym (keys %tmp){
				# accuracy: 2 decimals, in percentage
		$rdb{"sec",$sym}=
		    sprintf("%6.2f",(100*$tmp{$sym}/$rdb{"NROWS"})) ; }}

				# ------------------------------
				# assign SEC STR class
				# ------------------------------
        $description= "'all-alpha':   %H > 45% AND %E <  5%\n";
        $description.="'all-beta':    %H <  5% AND %E > 45%\n";
        $description.="'alpha-beta':  %H > 30% AND %E > 20%\n";
        $description.="'mixed':       all others\n";
        $rdb{"sec","class","txt"}=$description;
        if    ($rdb{"sec","H"} > 45 && $rdb{"sec","E"} <  5) {
            $rdb{"sec","class"}="all-alpha";}
        elsif ($rdb{"sec","H"} >  5 && $rdb{"sec","E"} > 45) {
            $rdb{"sec","class"}="all-beta";}
        elsif ($rdb{"sec","H"} > 30 && $rdb{"sec","E"} > 20) {
            $rdb{"sec","class"}="alpha-beta";}
        else {
            $rdb{"sec","class"}="mixed";}
    }
				# ------------------------------
				# compile membrane prob
				#      pT and pN normalised to 0-9
				#      pT + pN = 9
				# ------------------------------
    if (defined $rdb{"1","OtM"}) {
	foreach $itres (1..$rdb{"NROWS"}) { 
	    $sum=$rdb{$itres,"OtM"}+$rdb{$itres,"OtN"};
	    $rdb{$itres,"pM"}=int(10*($rdb{$itres,"OtM"}/$sum));
	    $rdb{$itres,"pM"}=9 if ($rdb{$itres,"pM"} > 9);
	    $rdb{$itres,"pN"}=int(10*($rdb{$itres,"OtN"}/$sum)); 
	    $rdb{$itres,"pN"}=9 if ($rdb{$itres,"pN"} > 9);
	}}
				# ------------------------------
				# HTM header
				# ------------------------------
    if ($#kwdHead > 0 && defined $rdb{"1","PiMo"}) {
	foreach $kwd (@kwdHead) {
	    next if (! defined $rdb{$kwd});
	    $rdb{"header",$kwd}=$rdb{$kwd}; 
	}}

				# ------------------------------
				# compile accessibility composition
				# ------------------------------
    if (defined $rdb{"1","PREL"}) {
	undef %tmp;foreach $sym ("b","e","bsub","esub"){$tmp{$sym}=0;}
	foreach $itres (1..$rdb{"NROWS"}) { 
	    if (! defined $rdb{$itres,"Pbe"}){
		$par{"thresh2acc"}=16   if (! defined $par{"thresh2acc"});
		$sym="b";
		$sym="e" if ($rdb{$itres,"PREL"} > $par{"thresh2acc"}); }
	    else { 
		$sym=$rdb{$itres,"Pbe"};}
	    ++$tmp{$sym};
	    ++$tmp{$sym."sub"}  if ($rdb{$itres,"RI_A"}>= $riSubAccLoc);}

                                # assign
	if ($rdb{"NROWS"} > 0) {
				# accuracy: 2 decimals, in percentage
	    foreach $sym ("b","e"){
		$rdb{"acc",$sym}=
		    sprintf("%6.2f",(100*$tmp{$sym}/$rdb{"NROWS"})); }
	    $sumsub=$tmp{"bsub"}+$tmp{"esub"};
	    $rdb{"acc","sub"}=
		sprintf("%6.2f",(100*$sumsub/$rdb{"NROWS"})); 
	    if ($sumsub>0){
		foreach $sym ("b","e"){
		    $rdb{"acc",$sym."sub"}=
			sprintf("%6.2f",(100*$tmp{$sym."sub"}/$sumsub));}}
	}}

    return(1,"ok $SBR3");
}				# end of convProf_preProcess

#===============================================================================
sub convProf_rdinput {
    local($fileInRdbLoc,$fileInAliLoc) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_rdinput             read all input files
#       in:                     $fileInRdbLoc=    PROFrdb file (0, if %rdb already defined)
#       in:                     $fileInAliLoc=   HSSP file (0, if already read)
#                               
#       out GLOBAL:     PROF     %rdb {"NUMROWS"}, $rdb{$itres,"kwd"};
#       out GLOBAL:     HSSP    $rdb{"numali"},   %rdb{"numres"},   
#                               $rdb{"id",$itali},$rdb{"pide",$itali},
#                               $rdb{"seq",$itres},$rdb{$id,$itres}
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."convProf_rdinput";
				# check arguments
    return(&errSbr("not def fileInRdbLoc!",  $SBR2)) if (! defined $fileInRdbLoc);
    return(&errSbr("not def fileInAliLoc!",  $SBR2)) if (! defined $fileInAliLoc);

    return(&errSbr("no fileInRdb=$fileInRdbLoc!",$SBR2))  if ($fileInRdbLoc  && ! -e $fileInRdbLoc);
    return(&errSbr("no fileInProt=$fileInAliLoc!",$SBR2)) if ($fileInAliLoc && ! -e $fileInAliLoc);

				# ------------------------------
				# local settings
    if (! defined $par{"aliMinLen"}){
	$minlen=20;}		# minimal length for reporting alignment hits
    else {
	$minlen= $par{"aliMinLen"};}
    
				# ------------------------------
				# read PROF.RDB file
				# out GLOBAL %rdb
    if ($fileInRdbLoc){
	@tmp=(@kwdBody,@kwdBodyOld);
	($Lok,$msg)=
	    &rdRdb_here
		($fileInRdbLoc,\@kwdHead,\@tmp
		 );             return(&errSbrMsg("failed reading RDB=$fileInRdbLoc",
						  $msg,$SBR2)) if (! $Lok); }
				# check again ...
    return(&errSbr("HASH_rdb not defined (file=$fileInRdbLoc)",$SBR2)) if (! $rdb{"NROWS"});
    

				# ------------------------------
				# read HSSP file
    if ($fileInAliLoc){
				# initialise pointers and keywords
	if (! defined %hsspRd_ini){
	    ($Lok,$msg)=
		&hsspRd_ini
		    ();		return(&errSbr("failed on hsspRd_ini from lib\n".$msg,
					       $SBR2)) if (! $Lok);}

				# get chain
	$id=$fileInRdbLoc;
	$id=~s/^.*\///g;
	$id=~s/\.rdb.*$//g;
	$modetmp="noprof,nofill,noins";
	if ($id=~/_([0-9A-Z])$/ && $fileInAliLoc !~/[:_]$1/){
	    $modeadd=",chn=".$1;
	    $modetmp.=",".$modeadd;}
				# read HSSP
	($Lok,$msg)=
	    &hsspRd
		($fileInAliLoc,$modetmp,$par{"debug"}
		 );             return(&errSbrMsg("failed reading HSSP=$fileInAliLoc, ".
						  "mode=$modetmp msg=",
						  $msg,$SBR2)) if (! $Lok); 
				# --------------------------------------------------
				# cut out proteins with too few aligned residues
	$ct=0;

	undef %tmp;
	foreach $itali (1..$hssp{"numali"}){
	    $seq="";
	    foreach $itres (1 .. $hssp{"numres"}) {
		$seq.=$hssp{"ali",$itali,$itres};
	    }
	    $seq=~s/[\-\.~]//g;
	    if (length($seq) < $minlen){
		$tmp{$itali}=1;
		next; 
	    }
	    ++$ct;
	    foreach $kwd ("ID","IDE","LALI"){
		next if (! defined $hssp{$kwd,$itali});
		$hssp{$kwd,$ct}=   $hssp{$kwd,$itali};
	    }
	    foreach $kwd ("ali"){
		foreach $itres (1 .. $hssp{"numres"}) {
		    $hssp{$kwd,$ct,$itres}=$hssp{$kwd,$itali,$itres};
		}}
	}
	$hssp{"numali"}=$ct if ($ct < $hssp{"numali"}); 

				# add to RDB
	$rdb{"prot_nres"}=
	    $rdb{"numres"}=$hssp{"numres"};
	$rdb{"prot_nali"}=
	    $rdb{"numali"}=$hssp{"numali"};
	$rdb{"prot_id"}=
	    $rdb{"id"}=    $hssp{"PDBID"};
				# protein names
	foreach $itali (1..$hssp{"numali"}){
	    $rdb{"id",$itali}=  $hssp{"ID",$itali}; 
	    $rdb{"pide",$itali}=int(100*$hssp{"IDE",$itali}); 
	    $rdb{"lali",$itali}=$hssp{"LALI",$itali}; 
	}
				# guide sequence
	foreach $itres (1..$hssp{"numres"}){
	    $rdb{"seq",$itres}=$hssp{"seq",$itres}; 
	}
				# all alignments
	foreach $itali (1..$hssp{"numali"}){
	    $id=$hssp{"ID",$itali};
	    foreach $itres (1..$hssp{"numres"}){
		$rdb{$id,$itres}=$hssp{"ali",$itali,$itres};
	    }}
	undef %hssp;		# slim-is-in
	$rdb{"FROM"}=$fileInAliLoc;
	$rdb{"TO"}=  $rdb{"numres"};
	if (0){
	    foreach $itali (1..$rdb{"numali"}){
		$tmp="";
		foreach $itres (1..$rdb{"numres"}){
		    $tmp.=$rdb{$rdb{"id",$itali},$itres};}
		printf "xx %5d %-10s %-s\n",$itali,$rdb{"id",$itali},$tmp;
	    }
	    die;}
				# check again ...
	return(&errSbr("failed to read protein file=$fileInAliLoc!\n".
		   "numali=".$rdb{"numali"}.", numres=".$rdb{"numres"}.", seq(1)=".$rdb{"seq",1},$SBR2)) 
	    if ($Lali &&
		(! defined  $rdb{"numali"} || ! defined  $rdb{"numres"} || ! defined $rdb{"seq",1}));
    }
				# no protein info given
    else {
	$Lali=0;
    }
    return(1,"ok $SBR2");
}				# end of convProf_rdinput

#===============================================================================
sub convProf_wrtAliBody {
    local($fhoutLoc,$formatLoc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_wrtAliBody          write alignment + PROF prediction in MSF|SAF
#                               
#       in:                     $fileInLoc
#       in:                     $formatLoc = <msf|saf|dssp|casp>
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."convProf_wrtAliBody";
				# check arguments
    return(&errSbr("not defined fhoutLoc!", $SBR3)) if (! defined $fhoutLoc);
    return(&errSbr("not defined formatLoc!",$SBR3)) if (! defined $formatLoc);


				# ------------------------------
				# prepare write predictions
				# ------------------------------
    $nblocks=1;                 # number of blocks to write
    $nblocks=1+int($rdb{"NROWS"}/$nresPerLineLoc)
	if ($nresPerLineLoc > 0);

				# --------------------------------------------------
				# process input
				# --------------------------------------------------
    $#nameLoc=$#stringLoc=$#tmp=0;
    $max=0;
				# ------------------------------
				# guide
    $name=$rdb{"id"};
    push(@nameLoc,$name);
    $max=length($name)          if (length($name)>$max);
    $seq="";
    foreach $itres (1..$rdb{"numres"}){
	$seq.=$rdb{"seq",$itres};}
    push(@stringLoc,$seq);
				# ------------------------------
				# all others
    foreach $it (1..$rdb{"numali"}){
	$name=$rdb{"id",$it};
	push(@nameLoc,$name);	# store the names
	$max=length($name)      if (length($name)>$max);
				# store sequences
	$seq="";
	foreach $itres (1..$rdb{"numres"}){
	    $seq.=$rdb{$name,$itres}; }
	push(@stringLoc,$seq);
    }
				# ------------------------------
				# predictions
    foreach $kwd (@kwdBody){
	next if ($kwd=~/^p[HELTMNhepn]/ ||
		 $kwd=~/^[OP]be/    ||
		 $kwd=~/^AA/);
	next if (! defined $rdb{1,$kwd});
	$string="";
	$abbr=$kwd;
	$abbr=$transAbbr{$kwd} if (defined $transAbbr{$kwd});
				# relative acc
	if ($kwd=~/REL/){
	    foreach $itres (1..$rdb{"numres"}){
		$string.=&exposure_project_1digit($rdb{$itres,$kwd});}}
				# all others
	else {
	    foreach $itres (1..$rdb{"numres"}){
		$string.=$rdb{$itres,$kwd};}}
				# replace 'i' and 'L' -> ' '
#	$string=~s/i/ /g;
#	$string=~s/L/ /g;
	push(@nameLoc,$abbr);	# store names
	push(@stringLoc,$string); # store sequences
    }
				# --------------------------------------------------
				# ali: header
				# --------------------------------------------------

				# ------------------------------
				# MSF
    if ($formatLoc =~/msf/){
	print $fhoutLoc 
	    "MSF of: ",$rdb{"FROM"}," from:    1 to:   ",length($stringLoc[1])," \n",
	    $rdb{"TO"}," MSF: ",length($stringLoc[1]),
	    "  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";

	foreach $it (1..$#stringLoc){
	    printf 
		$fhoutLoc "Name: %-".$max."s Len: %-5d Check: 2222 Weight: 1.00\n",
		$nameLoc[$it],length($stringLoc[$it]); 
	}
	print $fhoutLoc 
	    " \n","\/\/\n"," \n";}
				# ------------------------------
				# SAF
    else {
	print $fhoutLoc
	    "# SAF\n";}

				# --------------------------------------------------
				# ali: body
				# --------------------------------------------------
    $nres_block=6;
    $tmp=       int($nresPerLineLoc/10); 
    $nres_block=$tmp            if ($tmp<5);
    $nres_block=1               if ($tmp<1);
    $numres=    length($stringLoc[1]);

				# loop over all residues per line (i.e. all blocks)
    for($it=1;$it<=$numres;$it+=$nresPerLineLoc){
	$itend=$it-1+$nresPerLineLoc;
	last if ($it > $itend);
	$itend=$numres          if ($numres<$itend);
	$nresHere=(1+$itend-$it);
	$tmpspace="";		# spacer in between 'columns'
	$tmpspace=" "           if ($formatLoc=~/msf/);
				# ------------------------------
				# numbers
	if ($formatLoc=~/msf/){
	    $nblank=int(($nresHere-1)/10);
	    printf $fhoutLoc
		"%-".$max."s   %-s%-".($nblank+$nresHere-length($it)-length($itend))."s%-s\n",
		" ",$it, " ", $itend;}
	else {
	    $string=&myprt_npointsfull($nresHere,$itend);
	    $string=&myprt_npointsfull($nresPerLineLoc,$itend);
	    printf $fhoutLoc
		"%-".$max."s  %-s\n"," ",$string; }
		
				# ------------------------------
				# now sequences in stretches of 10
	foreach $it2 (1..$#stringLoc){
	    printf $fhoutLoc 
		"%-".$max."s  ",$nameLoc[$it2];
	    foreach $it3 (1..$nres_block){
		last if (length($stringLoc[$it2])<($it+($it3-1)*10));
		printf $fhoutLoc 
		    $tmpspace."%-10s",substr($stringLoc[$it2],($it+($it3-1)*10),10);}
	    print $fhoutLoc 
		"\n";}
	print $fhoutLoc 
	    "\n"; 
    }
    print $fhoutLoc 
	"\n";

    $#nameLoc=$#stringLoc=0;	# save space

    return(1,"ok $SBR3");
}				# end of convProf_wrtAliBody

#===============================================================================
sub convProf_wrtAsciiBody {
    local($fhoutLoc,$txtPreRowLoc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_wrtAsciiBody                     
#       in:                     $fileInLoc
#       in:                     $txtPreRowLoc=    'pre' will be used before every row
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."convProf_wrtAsciiBody";
				# check arguments
    return(&errSbr("not defined fhoutLoc!",$SBR3)) if (! defined $fhoutLoc);
    return(&errSbr("not def txtPreRowLoc!",$SBR3)) if (! defined $txtPreRowLoc);

				# ------------------------------
				# prepare write predictions
				# ------------------------------
    $nblocks=1;                 # number of blocks to write
    $nblocks=1+int($rdb{"NROWS"}/$nresPerLineLoc)
	if ($nresPerLineLoc > 0);
	
				# --------------------------------------------------
				# (1) ASCII: brief summary
				# --------------------------------------------------
    if ($modeWrtLoc =~ /ascii/ && ($Lbrief || $Lscreen)) {
	$#kwdBodyTmp=0;
				# select those to write
	foreach $kwd (@kwdBody) { 
	    next if ($kwd=~/^[OP](REL|RTN|RHL|R2MN|be|iMo)|^p[HELTMNhepn]|^O[H|E|HE]cap/);
	    push(@kwdBodyTmp,$kwd); }
	$tag="PROF results (brief)";
	@wrtloc=
	    ($line_pre. "-" x length($tag) ."\n",
	     $line_pre. $tag."\n",
	     $line_pre. "-" x length($tag) ."\n",
	     $line_pre. "\n");
	print $fhoutLoc @wrtloc if ($Lbrief);
	print $fhscreen @wrtloc if ($Lscreen);
				# in  GLOBAL:  %transSym,%transAbbr,%transSec2Htm
				# out GLOBAL:  @wrtloc
	($Lok,$msg)=
	    &convProf_wrtAsciiBodyOneLevel
		($nblocks,$lenAbbrBef,$lenAbbrAll,$fileOutLoc,"brief",$nresPerLineLoc,
		 $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
		 \@kwdBodyTmp); return(&errSbr("failed convProf_wrtAsciiBodyOneLevel (brief)".
					       $msg,$SBR1))  if (! $Lok); 
	foreach $tmp (@wrtloc){
	    print $fhoutLoc 
		$txtPreRowLoc,$tmp;
	}
	print $fhoutLoc 
	    $line_h3,"\n";

	print $fhscreen @wrtloc if ($Lscreen); 
    }
				# --------------------------------------------------
				# (2) ASCII: normal
				# --------------------------------------------------
    if ($modeWrtLoc =~ /ascii/ && $Lnormal) {
	$tag="PROF results (normal)";
	print $fhoutLoc 
	    $line_pre. "-" x length($tag) ."\n",
	    $line_pre. $tag."\n",
	    $line_pre. "-" x length($tag) ."\n",
	    $line_pre. "\n";
	$#kwdBodyTmp=0;
	foreach $kwd (@kwdBody) {
	    next if ($kwd=~/^[OP]be/);
#	    next if ($kwd=~/^p[HELTMNhepn]/);
	    push(@kwdBodyTmp,$kwd); }
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convProf_wrtAsciiBodyOneLevel
		($nblocks,$lenAbbrBef,$lenAbbrAll,$fileOutLoc,"normal",$nresPerLineLoc,
		 $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
		 \@kwdBodyTmp); return(&errSbr("failed convProf_wrtAsciiBodyOneLevel (normal)".
					       $msg,$SBR1))  if (! $Lok);
	foreach $tmp (@wrtloc){
	    print $fhoutLoc 
		$txtPreRowLoc,$tmp;
	}
	print $fhoutLoc 
	    $line_h3,"\n";
    }
				# --------------------------------------------------
				# (3) ASCII: full details (graphics)
				# --------------------------------------------------
    if ($modeWrtLoc =~ /ascii/ && $Lgraph) {
	$tag="PROF results (detailed ASCII 'graphics')";
	print $fhoutLoc 
	    $line_pre. "-" x length($tag) ."\n",
	    $line_pre. $tag."\n",
	    $line_pre. "-" x length($tag) ."\n",
	    $line_pre. "\n";
	$#kwdBodyTmp=0;
	foreach $kwd (@kwdBody) {
	    next if ($kwd=~/^RI/ || 
		     $kwd=~/^(PHEL|PMN|PRMN|PR2MN|PiMo|PiTo|P.*cap|O.*cap)/);
	    next if ($Lis_htm_only && $kwd=~/^p[HETLehpn]$/);
	    push(@kwdBodyTmp,$kwd); }

				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convProf_wrtAsciiBodyOneLevel
		($nblocks,$lenAbbrBef,$lenAbbrAll,$fileOutLoc,
		 "graph",$nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
		 \@kwdBodyTmp);
	foreach $tmp (@wrtloc){
	    print $fhoutLoc 
		$txtPreRowLoc,$tmp;
	}
	print $fhoutLoc 
	    $line_h3,"\n";
    }
				# ------------------------------
				# (6) write end and close file
				# ------------------------------
    print $fhoutLoc 
	"\n";

    return(1,"ok $SBR3");
}				# end of convProf_wrtAsciiBody

#===============================================================================
sub convProf_wrtAsciiBodyOneLevel {
    local($nblocksLoc,$lenAbbrLoc,$lenAbbrAdd,$fileOutLoc,$modeLoc,
	  $nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
	  $ra_kwdBodyLoc)=@_;
    local($SBR4,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_wrtAsciiBodyOneLevel   writes one level of detail
#       in:                     $nblocksLoc=      number of blocks 
#                                                 (with NresPerlLineLoc written per block)
#       in:                     $lenAbbrLoc=      
#       in:                     $fileOutLoc=      HTML output file
#       in:                     $modeLoc=         controls what to write
#                                   <brief|normal|detail>
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       in:                     
#                               
#       in GLOBAL:              %transSym,%transAbbr
#                               
#       out GLOBAL:             @wrtloc= field ready to write
#                               
#       out:                    1|0,msg,  
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR4=$tmp."convProf_wrtAsciiBodyOneLevel";
				# check arguments
    return(&errSbr("not def nblocksLoc!",$SBR4))     if (! defined $nblocksLoc);
    return(&errSbr("not def lenAbbrLoc!",$SBR4))     if (! defined $lenAbbrLoc);
    return(&errSbr("not def lenAbbrAdd!",$SBR4))     if (! defined $lenAbbrAdd);
    return(&errSbr("not def fileOutLoc!",$SBR4))     if (! defined $fileOutLoc);
    return(&errSbr("not def modeLoc!",   $SBR4))     if (! defined $modeLoc);
    return(&errSbr("not def nresPerLineLoc!",$SBR4)) if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!",$SBR4))    if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",$SBR4))    if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",$SBR4))    if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",$SBR4))    if (! defined $riSubSymLoc);
    return(&errSbr("not def $ra_kwdBodyLoc!",$SBR4)) if (! $ra_kwdBodyLoc);

				# --------------------------------------------------
				# loop over all blocks
				#    i.e. residues 1-60 ..
				# --------------------------------------------------
    $#wrtloc=0;
    foreach $itBlock (1..$nblocksLoc) {
				# begin and end of current block
	$itBeg=1+($itBlock-1)*$nresPerLineLoc;
	if ($nresPerLineLoc) {	# split into blocks
	    $itEnd=$itBlock*$nresPerLineLoc;}
	else {
	    $itEnd=$rdb{"NROWS"} }
				# correct
	$itEnd=$rdb{"NROWS"} if ($itEnd > $rdb{"NROWS"});

	last if ($itEnd<$itBeg);

				# first: counter
	$ncount=1+$itEnd-$itBeg;

	$string=&myprt_npointsfull($ncount,$itEnd);
	$tmp=" " x $lenAbbrAll;
	push(@wrtloc,
	     $tmp." "."\n",	# empty line before
	     $tmp." ".$string." \n"
	     );

				# --------------------------------------------------
				# loop over all keywords
				#    i.e. all rows (AA,OHEL,PHEL)
				# --------------------------------------------------
	foreach $itKwd (1..$#{$ra_kwdBodyLoc}) {
	    $kwd=$ra_kwdBodyLoc->[$itKwd];
	    next if (! defined $rdb{$itBeg,$kwd} || length($rdb{$itBeg,$kwd})<1);
				# all into one string
	    $string="";
				# ri
	    if    ($kwd eq "RI_S") { $relStrong=$riSubSecLoc; }
	    elsif ($kwd eq "RI_A") { $relStrong=$riSubAccLoc; }
	    elsif ($kwd eq "RI_M") { $relStrong=$riSubHtmLoc; }
	    else                   { $relStrong=6; }
				# probability
	    $#string=0
		if ($kwd=~/^p[HELTMNhepn]/ || $kwd=~/^[OP]REL/);
	    
				# ------------------------------
				# loop over protein fragment
				# ------------------------------
	    foreach $itres ($itBeg .. $itEnd) {
		$sym=$rdb{$itres,$kwd}; 
				# normalise relative acc to numbers 0-9
		$sym=&exposure_project_1digit($sym)
		    if ($kwd =~ /^[OP]REL/);
		
				# ------------------------------
				# probability PROFsec, PROFhtm
		if ($modeLoc eq "graph" && $kwd=~/^p[HELTMN]$/) {
		    if ($sym!~/^[0-9]$/){
			print "xx problem itres=$itres, kwd=$kwd, sym=$sym\n";die;
		    }
		    foreach $it (1..10){
			if ($sym <= ($it-1)) {
			    $string[$it].=" "; }
			else {
			    $string[$it].="#"; }}}
				# ------------------------------
				# probability caps
		elsif ($modeLoc eq "graph" && $kwd=~/^p[hepn]/) {
		    foreach $it (1..10){
			if ($sym*2 <= ($it-1)) {
			    $string[$it].=" "; }
			else {
			    $string[$it].="#"; }}}
				# ------------------------------
				# relative accessibility
		elsif ($modeLoc eq "graph" && $kwd=~/^[OP]REL$/) {
		    foreach $it (1..10){
			if ($sym <= ($it-1)) {
			    $string[$it].=" "; }
			else {
			    $string[$it].="#"; }}}
				# ------------------------------
				# simple strings
		else {
		    $symPrt=$sym;
				# HTM: from 'HL' -> 'MN'
		    $symPrt=$transSec2Htm{$sym} if ($kwd=~/^[OP](MN|RMN|FMN)/);
				# for brief RI =< |*>
		    if ($modeLoc eq "brief" && $kwd=~/^RI/) {
			$symPrt="*";
			$symPrt=" " if ($sym < $relStrong); }
				# which style
		    if    ($kwd=~/^[OP]HEL|^p[HEL]|RI_S/)  { 
			$kwdPrt="sec-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](REL|bie)|^RI_A/)    { 
			$kwdPrt="acc-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](MN|RMN|iMo)|^p[MN]|^RI_M/) { 
			$kwdPrt="htm-".$symPrt  if ($symPrt !~/^[ \*]$/); }
		    
				# sequence
		    elsif ($kwd=~/^AA/){
			$kwdCss="res-".$symPrt  if ($symPrt !~/^[ \*]$/); }
				# 'L' -> ' '
		    $symPrt=$transSym{$sym} if (defined $transSym{$sym} && $kwd !~/^[OP]REL/
						&& $kwd ne "AA" && $kwd !~/PiMo/ 
						&& $symPrt ne " " && $symPrt ne "*");
		    $symPrt=" "             if ($symPrt eq "N" && $kwd eq "OMN");
			
		    $string.=$symPrt; }
	    }
	    $abbr=$kwd;
	    $abbr=$transAbbr{$kwd} if (defined $transAbbr{$kwd});
	    $tmp= "";
				# either for observed 3 state, or if that missing, for predicted
	    if    ($kwd=~/Obie/ ||  ($kwd=~/Pbie/ && ! defined $rdb{$itBeg,"Obie"})){
		$tmp=" 3st: "; }
				# either for observed 10, or if missing for pred
	    elsif (($modeLoc ne "graph" && $kwd=~/OREL/) ||
		   ($kwd=~/PREL/ && ! defined $rdb{$itBeg,"OREL"})){
		$tmp=" 10st:"; }
	    elsif ($modeLoc eq "graph" && $kwd=~/[PO]REL/){
		$tmp=" graph:"; }
	    elsif ($modeLoc eq "graph" && $kwd=~/p[HELTMNhepn]/){
		$tmp=" graph:"; }
	    $pre=    $tmp." " x ($lenAbbrLoc-length($tmp));
	    $lenTotal=length($pre.$abbr);
	    $after=  " " x ($lenAbbrAll-$lenTotal);
	    
				# probability PROFsec
	    if    ($modeLoc eq "graph" && $kwd=~/^p[HELTMN]$/){
		push(@wrtloc,
		     " " x $lenAbbrAll. "+" . "-" x $ncount . "+" . "\n");
		foreach $it (1..9) {
		    $it2=10-$it;
#		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)/10;
		    $txt= $pre.$abbr.$after."|".$string[$it2]."|".sprintf("  %2.1f ",$tmp3);
		    push(@wrtloc,
			 $txt."\n");}
		push(@wrtloc,
		     " " x $lenAbbrAll . "+" . "-" x $ncount . "+" . "\n");}

				# probability caps
	    elsif ($modeLoc eq "graph" && $kwd=~/^p[hepn]/) {
		push(@wrtloc,
		     " " x $lenAbbrAll. "+" . "-" x $ncount . "+" . "\n");
		foreach $it (1..10) {
		    $it2=(10-$it);
#		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)/10;
		    next if ($it2 <= 5);
		    $txt= $pre.$abbr.$after."|".$string[$it2]."|".sprintf("  %2.1f ",$tmp3);
		    push(@wrtloc,
			 $txt."\n");}
		push(@wrtloc,
		     " " x $lenAbbrAll . "+" . "-" x $ncount . "+" . "\n");}

				# relative acc PROFacc
	    elsif ($modeLoc eq "graph" && $kwd=~/^[OP]REL$/) {
		push(@wrtloc,
		     " " x $lenAbbrAll . "+" . "-" x $ncount . "+" . "\n");
		foreach $it (1..9) {
		    $it2=10-$it;
#		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)*($it2+1);
		    $txt= $pre.$abbr.$after."|".$string[$it2]."|".sprintf("  %3d%-s ",int($tmp3),"%");
		    push(@wrtloc,
			 $txt."\n");}
		push(@wrtloc,
		     " " x $lenAbbrAll. "+" . "-" x $ncount . "+" . "\n")
		    if ($kwd=~/PREL/);}
				# sequence: insert alignment!
	    elsif ($kwd=~/^AA/ && $modeLoc=~/normal/ && $Lali){
		push(@wrtloc,
		     $pre.$abbr.$after."|".$string."|"."\n"); 
		if (defined $rdb{"numali"} && $rdb{"numali"}){
				# announce coming ali
		    $pre=    " alignment:";
		    $tmp=    " " x ($lenAbbrAll-length($pre));
		    push(@wrtloc,
			 $pre.$tmp. " " . " " x length($string) . " ". "pide" . " ". "lali" . "\n");
				# now let it come ...
		    foreach $itali (1..$rdb{"numali"}){
			$string="";
			$id= $rdb{"id",$itali};
			foreach $itres ($itBeg .. $itEnd) {
			    $string.=$rdb{$id,$itres};
			}
			$pre=    " ".sprintf("%3d",$itali)." ";
			$tmp=    $id; $tmp=~s/^.*\|//g;	# purge db
			$idshort=substr($tmp,1,10);
			$tmp=    " " x ($lenAbbrAll-length($pre.$idshort));
			push(@wrtloc,
			     $pre.$idshort.$tmp."|".$string."|".
			     " ".sprintf("%3d %4d",$rdb{"pide",$itali},
					 $rdb{"lali",$itali})."\n")
			    if (defined $rdb{"pide",$itali} && 
				defined $rdb{"lali",$itali});
		    }
				# add empty line
		    $pre=" prediction:";
		    $tmp=    " " x ($lenAbbrAll-length($pre));
		    push(@wrtloc,
			 $pre.$tmp. " " . " " x length($string) . " " . "\n");
		}}
				# ALL others: skip fot time being
	    elsif ($kwd !~ /^(p[HELTMNhepn]|[OP]REL)$/){
		push(@wrtloc,
		     $pre.$abbr.$after."|".$string."|"."\n"); }

				# ------------------------------
				# skip if brief (or detail)
	    if ($modeLoc eq "brief" || $modeLoc eq "graph") {
				# spacer
		push(@wrtloc)   if ($kwd=~/RI/);
		next; }

				# ------------------------------
				# after REL (1) detail 
	    if ($kwd=~/RI_[SMHM]/ && $Ldetail) {
		$Lok=1;
		if    ($kwd eq "RI_S") { @kwdtmp=("pH","pE","pL"); }
		elsif ($kwd eq "RI_M") { @kwdtmp=("pM","pN"); }
		else {
		    print "-*- WARN $SBR4: cannot run detail, kwd=$kwd, not recognised, yet\n";
		    $Lok=0;}
		if ($Lok){
		    foreach $ittmp (1..$#kwdtmp){
			$string[$ittmp]="";
			foreach $itres2 ($itBeg .. $itEnd) {
			    if (! defined $kwdtmp[$ittmp]){
				print "-*- WARN $SBR4 REL (1) detail: not defined kwd($ittmp)!\n"
				    if ($itres2==1);
				$string[$ittmp].=" ";
				next;}
			    if (! defined $rdb{$itres2,$kwdtmp[$ittmp]}){
				print 
				    "-*- WARN $SBR4 REL (1) detail: ",
				    "not defined rdb(1,kwd($ittmp)=$kwdtmp[$ittmp]!\n"
					if ($itres2==1);
				$string[$ittmp].=" ";
				next;}
			    $string[$ittmp].=$rdb{$itres2,$kwdtmp[$ittmp]}; 
			} }
				# write detail
		    $tmp=     " detail:";
		    push(@wrtloc,
			 $tmp." " x ($lenAbbrLoc-length($tmp)) ."\n");
		    $tmp=     " ";
		    $pre=     $tmp." " x ($lenAbbrLoc-length($tmp));
		    foreach $ittmp (1..$#kwdtmp){
			$abbr=$transAbbr{$kwdtmp[$ittmp]};
			$lenTotal=length($pre.$abbr);
			$after=   " " x ($lenAbbrAll-$lenTotal);
			push(@wrtloc,
			     $pre.$abbr.$after."|".$string[$ittmp]."|"."\n");
		    }
		}}		# end of detail
	    
				# ------------------------------
				# subset after REL (2) resp. AFTER
				#        detail
	    if ($kwd=~/RI/ && $Lsubset) {
		$Lskip=0;
		if    ($kwd eq "RI_S") { 
		    $kwdTmp="PHEL"; $kwdTmp2="SUBsec"; $abbr=$transAbbr{"SUBsec"};}
		elsif ($kwd eq "RI_A") { 
		    $kwdTmp="Pbie"; $kwdTmp2="SUBacc"; $abbr=$transAbbr{"SUBacc"};}
		elsif ($kwd eq "RI_M") { 
		    $kwdTmp="PMN";  $kwdTmp2="SUBhtm"; $abbr=$transAbbr{"SUBhtm"};}
		else                   {
		    $Lskip=1;}
				# NO subset, since mode not recognised!
		next if ($Lskip);

		$string="";
		foreach $itres ($itBeg .. $itEnd) {
		    $sym=$rdb{$itres,$kwdTmp}; 
		    if (! defined $sym && $itres==1){
			print "xx not defined $sym for kwdTmp=$kwdTmp, kwd=$kwd\n" ;
			foreach $kwd (sort keys %rdb){
			    next if ($kwd=~/\d\d|ali|seq|_/);
			    next if ($kwd!~/1\D/);
			    print "$kwd ",$rdb{$kwd},"\n";
			}

			die;}
		    $rel=$rdb{$itres,$kwd}; 
		    if ($rel >= $relStrong) {
			$symPrt=$sym; 
				# HTM: from 'HL' -> 'MN'
			$symPrt=$transSec2Htm{$sym} if ($kwd=~/^RI_M/ && 
							defined $transSec2Htm{$sym});
		    }
		    else {
			$symPrt=$riSubSymLoc; }
		    if    ($kwd=~/^RI_S/) { $kwdCss="sec-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_A/) { $kwdCss="acc-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_M/) { $kwdCss="htm-".$symPrt."sub"; } 

		    $string.=$symPrt;
		}


				# write subset
		$tmp=     " subset:";
		$pre=     $tmp." " x ($lenAbbrLoc-length($tmp));
		$lenTotal=length($pre.$abbr);
		$after=   " " x ($lenAbbrAll-$lenTotal);
		push(@wrtloc,
		    $pre.$abbr.$after."|".$string."|"."\n");
				# after: spacer
		push(@wrtloc,
		     "\n");
	    }			# end of subset

	}			# end of loop over all rows
    }				# end of all blocks
    push(@wrtloc,
	 "\n");
    return(1,"ok $SBR4");
}				# end of convProf_wrtAsciiBodyOneLevel

#===============================================================================
sub convProf_wrtCaspBody {
    local($fhoutLoc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_wrtCaspBody         write PROF prediction in CASP format
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."convProf_wrtCaspBody";
				# check arguments
    return(&errSbr("not defined fhoutLoc!",$SBR3))  if (! defined $fhoutLoc);

				# ------------------------------
				# prepare write predictions
				# ------------------------------
    $nblocks=1;                 # number of blocks to write
    $nblocks=1+int($rdb{"NROWS"}/$nresPerLineLoc)
	if ($nresPerLineLoc > 0);

				# --------------------------------------------------
				# process input
				# --------------------------------------------------

    $tNalign1=8;		# threshold in Nali for which ri=ri/10 +1
    $tNalign2=3;		# threshold in Nali for which ri=ri/10
				# note: below take 1/2 ri
    $numOfSubmission=1;		# number of predictions submitted before


				# --------------------------------------------------
				# write
				# --------------------------------------------------
    $from=  "rost\@columbia.edu\n";
    $copy=  "Burkhard Rost, CUBIC Columbia Univ, New York / LION Heidelberg";
    $urlsrv="http://cubic.bioc.columbia.edu/predictprotein";
    $urlprd="unk";
    $from=  $par{"txt","contactEmail"} if (defined $par{"txt","contactEmail"});
    $urlsrv=$par{"txt","contactWeb"}   if (defined $par{"txt","contactWeb"});
    $copy=  $par{"txt","copyright"}    if (defined $par{"txt","copyright"});

    print $fhoutLoc 
	"From: ".$from."\n",
	"To: submit\@sb7.llnl.gov\n",
	"Subject: prediction ABF1 (".$rdb{"id"}.")\n",
	"--text follows this line--\n"; 
				# for CASP auto (99)
    print $fhoutLoc
	"PFRMAT SS\n",
	"TARGET ".$rdb{"id"}."\n",
	"AUTHOR 1604-9596-8389\n",
	"REMARK Automatic usage of PROFsec and PROFacc\n",
	"REMARK PARAMETERS:    DEFAULT\n",
	"REMARK\n",
	"METHOD SERVERNAME:    PredicProtein\n",
	"METHOD PROGRAM:       PROF secondary structure \n",
	"METHOD SERVER URL:    ".$urlsrv."\n",
#	"METHOD SERVER URL:    http:\/\/cubic.bioc.columbia.edu\n",
	"MODEL 1\n";


#    print $fhoutLoc 
#	"PFRMAT SS\n",
#	"TARGET ".$rdb{"id"}."\n",
#	"AUTHOR ".$copy.", ".$from."\n",
#	"REMARK Automatic usage of PROFsec and PROFacc\n",
#	"REMARK PARAMETERS:    DEFAULT\n",
#	"REMARK \n",
#	"METHOD SERVERNAME:    PredicProtein\n",
#	"METHOD PROGRAM:       PROF secondary structure and solvent accessibility prediction\n",
#	"METHOD URL:           ".$urlprd."\n",
#	"METHOD SERVER URL:    ".$urlsrv."\n";
    

				# --------------------------------------------------
				# write predictions
				# --------------------------------------------------
    if    (defined $rdb{"prot_nali"}){
	$nali=$rdb{"prot_nali"};}
    elsif (defined $rdb{"numali"}){
	$nali=$rdb{"numali"};}
    else {
	$nali=0;}
				# change reliability to confidence
    if    ($nali > $tNalign1) { 
	$conf=0.72;}
    elsif ($nali > $tNalign2) { 
	$conf=0.70;}
    else { 
	$conf=0.68;} 
#    printf $fhoutLoc 
#	"BEGDAT 1.1 %-2d %-3.1f\n",1,$conf;
#    print $fhoutLoc 
#	"MODEL 1\n";
				# ------------------------------
				# secondary structure
    if (defined $rdb{1,"PHEL"}){
#	printf $fhoutLoc 
#	    "SS %6d\n",$rdb{"NROWS"};
	foreach $itres (1..$rdb{"NROWS"}){
	    $aa= $rdb{$itres,"AA"};
	    $sec=$rdb{$itres,"PHEL"}; 
	    $sec="C"                if ($sec eq "L");

	    printf $fhoutLoc 
		"%-1s   %-1s",$aa,$sec;

	    if (defined $rdb{1,"RI_S"}){
		$ri= $rdb{$itres,"RI_S"};
				# correct RI
		if    ($nali>$tNalign1){
		    ++$ri; $ri=$ri/10;}
		elsif ($nali>$tNalign2){
		    $ri=$ri/10;}
		else                   {
		    $ri=$ri/20; }
		printf $fhoutLoc 
		    " %5.2f",$ri;}
	    printf $fhoutLoc 
		"\n"; 
	}}
				# ------------------------------
				# accessibility
    if (0){			# note: commented out!
	if (defined $rdb{1,"PREL"}){
	    printf $fhoutLoc 
		"ACC %6d\n",$rdb{"NROWS"};
	    foreach $itres (1..$rdb{"NROWS"}){
		$aa= $rdb{$itres,"AA"};
		$acc=$rdb{$itres,"PREL"};
		
		printf $fhoutLoc 
		    "%-1s %3s",$aa,$acc,$ri;

		if (defined $rdb{1,"RI_A"}){
		    $ri= $rdb{$itres,"RI_A"};
				# correct RI
		    if    ($nali>$tNalign1){
			++$ri; $ri=$ri/10;}
		    elsif ($nali>$tNalign2){
			$ri=$ri/10;}
		    else                   {
			$ri=$ri/20;}
		    printf $fhoutLoc 
			" %5.2f",$ri; }
		printf $fhoutLoc 
		    "\n";
	    }}
    }

    print $fhoutLoc 
#	"ENDDAT 1.1\n",
	"END\n";
    return(1,"ok $SBR3");
}				# end of convProf_wrtCaspBody

#===============================================================================
sub convProf_wrtDsspBody {
    local($fhoutLoc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_wrtDsspBody         write PROF prediction in DSSP format
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."convProf_wrtDsspBody";
				# check arguments
    return(&errSbr("not defined fhoutLoc!",$SBR3))  if (! defined $fhoutLoc);

				# ------------------------------
				# prepare write predictions
				# ------------------------------
    $nblocks=1;                 # number of blocks to write
    $nblocks=1+int($rdb{"NROWS"}/$nresPerLineLoc)
	if ($nresPerLineLoc > 0);

				# --------------------------------------------------
				# process input
				# --------------------------------------------------
    $from=  "rost\@columbia.edu\n";
    $copy=  "Burkhard Rost, CUBIC Columbia Univ, New York / LION Heidelberg";
    $urlsrv="http://cubic.bioc.columbia.edu/predictprotein";
    $urlprd="unk";
    $from=  $par{"txt","contactEmail"} if (defined $par{"txt","contactEmail"});
    $urlsrv=$par{"txt","contactWeb"}   if (defined $par{"txt","contactWeb"});
    $copy=  $par{"txt","copyright"}    if (defined $par{"txt","copyright"});

				# --------------------------------------------------
				# write
				# --------------------------------------------------

				# DSSP header
    print $fhoutLoc 
	"**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, here PROF prediction\n",
	"REFERENCE  B ROST \& C SANDER (1993) J Mol Biol 232:584-599\n",
	"HEADER     ".$rdb{"id"}."\n",
	"COMPND        \n",
	"SOURCE        \n",
	"AUTHOR        \n",
	"  \#  RESIDUE AA STRUCTURE BP1 BP2  ACC   ".
	    "N-H-->O  O-->H-N  N-H-->O  O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA  \n";

				# ------------------------------
				# DSSP body
				# ------------------------------
    $chain=" ";
    $chain=$rdb{"prot_kchn"}    if (defined $rdb{"prot_kchn"});
    $wrtWarn="";
    foreach $itres (1..$rdb{"NROWS"}){
				# defaults
	$riacc=$risec=0;$seq=$sec="U"; $acc=999;$CHAIN=" ";
				# fill in
	$seq=   $rdb{$itres,"AA"}    if (defined $rdb{$itres,"AA"});
	$sec=   $rdb{$itres,"PHEL"}  if (defined $rdb{$itres,"PHEL"});
	$acc=   $rdb{$itres,"PREL"}  if (defined $rdb{$itres,"PREL"});
	$risec= $rdb{$itres,"RI_S"}  if (defined $rdb{$itres,"RI_S"});
	$riacc= $rdb{$itres,"RI_A"}  if (defined $rdb{$itres,"RI_A"});
				# ERROR messages
	$wrtWarn.= "-*- WARN $SBR3: itres=$itres, SEQ not defined\n" if ($seq eq "U"  );
	$wrtWarn.= "-*- WARN $SBR3: itres=$itres, SEC not defined\n" if ($sec eq "U"  );
	$wrtWarn.= "-*- WARN $SBR3: itres=$itres, ACC not defined\n" if ($acc eq "999");
				# write it
	printf $fhoutLoc 
	    " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	    $itres,$itres,$chain,$seq,$sec,$acc,$risec,$riacc;
    }
    return(1,"ok $SBR3",$wrtWarn);
}				# end of convProf_wrtDsspBody

#===============================================================================
sub convProf_wrtHead {
    local($titleLoc,$fhoutLoc,$ra_kwdHead,$ra_kwdBody)=@_;
    local($SBR3,$sum,$itres,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf_wrtHead       writes HEAD part of HTML file
#       in:                     $titleLoc=        to be used for HTML title
#       in:                     $fhoutLoc=       file handle for writing HTML
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."convProf_wrtHead";
				# check arguments
    return(&errSbr("not def titleLoc!",  $SBR3)) if (! defined $titleLoc);
    return(&errSbr("not def fhoutLoc!",$SBR3)) if (! defined $fhoutLoc);

				# ------------------------------
				# local settings
    $numwhiteNotation=10;

    undef %tmp_taken;
				# ------------------------------
				# title
				# ------------------------------
    $#wrtloc=0;
    push(@wrtloc,
	 $line_pre. "\n",
	 $line_h1.  "\n",
	 $line_pre. "PROF predictions for $titleLoc\n",
	 $line_h1.  "\n",
	 $line_pre. "\n");

				# --------------------------------------------------
				# summary for protein
				# --------------------------------------------------
    if ($Lsummary &&
	(defined $rdb{"sec","class"} || 
	 defined $rdb{"1","PHL"}     || defined $rdb{"1","PHEL"}  ||
	 defined $rdb{"1","PMN"})   ){
	push(@wrtloc,
	     $line_h3,  "\n",
	     $line_pre. "SYNOPSIS of prediction\n",
	     $line_h3,  "\n"); }

				# ------------------------------
				# summary:sec
    if ($Lsummary && defined $rdb{"sec","class"}) {
	push(@wrtloc,
	     $line_pre. "\n",
	     $line_pre. "PROFsec summary\n",
	     $line_pre. "\n");

	push(@wrtloc,
	     $line_pre. "overall your protein can be classified as:\n",
	     $line_pre. "\n",
	     $line_pre. ">>>   ".$rdb{"sec","class"}."  <<<\n",
	     $line_pre. "\n",
	     $line_pre. "given the following classes:\n");
	     
	@tmp=split(/\n/,$rdb{"sec","class","txt"});
	foreach $tmp (@tmp){
	    push(@wrtloc,
		 $line_pre. $tmp ."\n");
	}}
				# ------------------------------
				# write sec str composition
    if ($Lsummary && 
	(defined $rdb{"1","PHL"} || defined $rdb{"1","PHEL"})) {
	push(@wrtloc,
	     $line_pre. "\n",
	     $line_pre. "Predicted secondary structure composition:\n");

	$ct=0; $tmp="";
	$tmp= $line_pre.sprintf("+-%15s-+"."-%5s-+" x 3 ,"-" x 15 ,"-----","-----","-----");
	$tmp1=$line_pre.sprintf("| %-15s |","sec str type");
	$tmp2=$line_pre.sprintf("| %-15s |","\% in protein");
	foreach $sym (split(//,"HEL")) {
	    next if (! defined $rdb{"sec",$sym});
	    $tmp1.= sprintf(" %5s |",$sym);
	    $tmp2.= sprintf(" %5.1f |",$rdb{"sec",$sym});
	}
	push(@wrtloc,
	     $tmp. "\n",$tmp1."\n",$tmp2."\n",
	     $line_pre.sprintf("+-%15s-+"."-%5s-+" x 3 ."\n","-" x 15 ,"-----","-----","-----"),
	     $line_pre. "\n"); }
				# ------------------------------
				# summary for protein (htm)
				# ------------------------------
    if ($Lsummary && defined $rdb{"header","NHTM_BEST"}) {
	push(@wrtloc,
	     $line_pre. "PROFhtm summary\n",
	     $line_pre. "\n");

	$nbest=$rdb{"header","NHTM_BEST"};    $nbest=~s/(\d+).*$/$1/g;
	$n2nd= $rdb{"header","NHTM_2ND_BEST"};$n2nd=~s/(\d+).*$/$1/g;
	$txtBest= "helix"; $txtBest= "helices" if ($nbest > 1);
	$txt2nd=  "helix"; $txt2nd=  "helices" if ($n2nd > 1);
	
	push(@wrtloc,
	     $line_pre. "NHTM=$nbest\n",
	     $line_pre. "->  PROFhtm detected $nbest membrane $txtBest for the best model.",
	     $line_pre. "-> The second best model contained $n2nd $txt2nd.\n");
	    
	$top=           $rdb{"header","HTMTOP_PRD"}; $top=~s/(\S+).*$/$1/g;
	$rel_best_dproj=$rdb{"header","REL_BEST_DPROJ"};$rel_best_dproj=~s/^(\S+).*$/$1/g;
	$rel_best=      $rdb{"header","REL_BEST"};$rel_best=~s/^(\S+).*$/$1/g;
	$htmtop_rid=    $rdb{"header","HTMTOP_RID"};$htmtop_rid=~s/^(\S+).*$/$1/g;
	$htmtop_rip=    $rdb{"header","HTMTOP_RIP"};$htmtop_rip=~s/^(\S+).*$/$1/g;
	push(@wrtloc,
	     $line_pre. "TOP = $top\n",
	     $line_pre. "->  PROFhtm predicted the topology ".$top.", i.e. the first loop region is $top",
	     $line_pre. "          (Note: this prediction may be problematic when the sequence you sent \n",
	     $line_pre. "          starts or ends with a region predicted in a membrane helix!)\n",
	     $line_pre. "->  Reliability of best model=".$rel_best_dproj." (0 is low, 9 is high)\n",
	     $line_pre. "->  Zscore for best model=".$rel_best,"\n",
	     $line_pre. "->  Difference of positive charges (K+R) inside - outside",
	     $line_pre. "->  = ".$htmtop_rid." (the higher the value, the more reliable)\n",
	     $line_pre. "->  Reliability of topology prediction =\n",
	     $line_pre. "->  = ".$htmtop_rip." (0 is low, 9 is high)\n",
	     $line_pre. "\n");
				# strength of single HTMs
	if (defined $rdb{"header","MODEL_DAT"}) {
	    @tmp=split(/\n/,$rdb{"header","MODEL_DAT"});
	    push(@wrtloc,
		 $line_pre. "PROFhtm: Details of the strength of each predicted membrane helix:\n",
		 $line_pre. "        (sorted by strength, strongest first)\n");
	    
	    push(@wrtloc,
		 sprintf("%5s | %8s | %12s | %5s \n","N HTM","Total score","Best HTM","c-N"));
	    push(@wrtloc,
		 sprintf("%5s-+-%8s-+-%12s-+-%5s-\n","-----","--------","------------","-----"));
	    foreach $tmp (@tmp) {
		$tmp=~s/\n+//g;@tmp2=split(/,/,$tmp);
		push(@wrtloc,
		     sprintf("%5s | %8s | %12s | %5s \n",@tmp2));
	    }
	    push(@wrtloc,
		 sprintf("%5s-+-%8s-+-%12s-+-%5s-\n","-----","--------","------------","-----"));
	    push(@wrtloc,
		 $line_pre. "\n");
	}
				# table with regions
	$tmp="";
	foreach $it (1..$rdb{"NROWS"}){
	    $tmp.=$rdb{$it,"PiMo"};}
				# get segments
				# out GLOBAL: %segment
	($Lok,$msg)=
	    &getSegment($tmp);  return(&errSbrMsg("failed to get segment for $tmp",
						  $SBR3)) if (! $Lok);

	push(@wrtloc,
	     $line_pre. "PROFhtm: overview over transmembrane segments:\n",
	     $line_pre. "\n");
	push(@wrtloc,
	     sprintf("%12s | %12s | %20s \n","Positions","Segments","Explain"));
	push(@wrtloc,
	     sprintf("%12s-+-%12s-+-%20s-\n","------------","------------","--------------------"));

	foreach $ctSegment (1..$segment{"NROWS"}){
	    $sym=$segment{$ctSegment};
	    $txt="?=error";
	    $txt=$transDescrShort{$sym} if (defined $transDescrShort{$sym});
	    push(@wrtloc,
		 $line_pre. 
		 sprintf("%5d",$segment{"beg",$ctSegment})."-".
		 sprintf("%5d",$segment{"end",$ctSegment})." ".
		 "|".$segment{$ctSegment},$segment{"seg",$ctSegment}.
		 "| ".$txt." ".$segment{"seg",$ctSegment}."\n"); 
	}
	push(@wrtloc,
	     sprintf("%12s-+-%12s-+-%20s-\n","------------","------------","--------------------"));
	push(@wrtloc,
	     $line_pre. "\n");
    }
	
				# ------------------------------
				# summary:acc GLOBE
    if ($Lsummary && defined $rdb{"acc","globe"}) {
	push(@wrtloc,
	     $line_pre. "\n",
	     $line_pre. "PROFacc/GLOBE summary\n",
	     $line_pre. "\n");
	push(@wrtloc,
	     $line_pre. "overall your protein can be classified as:\n",
	     $line_pre. "\n",
	     $line_pre. ">>>   ".$rdb{"sec","globe"}."  <<<\n",
	     $line_pre. "\n",
	     $line_pre. "given the following classes:\n");
	@tmp=split(/\n/,$rdb{"sec","globe","txt"});
	foreach $tmp (@tmp){
	    push(@wrtloc,
		 $line_pre. $tmp ."\n");
	}}
				# ------------------------------
				# solvent acc composition
    if ($Lsummary && defined $rdb{"1","PREL"}) {
	push(@wrtloc,
	     $line_pre. "\n",
	     $line_pre. "Predicted solvent accessibility composition (core/surface ratio):\n",
	     $line_pre. "  Classes used:\n",
	     $line_pre. "    e: residues exposed with more than ".$par{"thresh2acc"}."% of their surface\n",
	     $line_pre. "    b: all other residues.\n");
	push(@wrtloc,
	     $line_pre. "  The subsets are for the fractions of residues predicted at higher levels\n",
	     $line_pre. "  of reliability, i.e. accuracy. This set covers ".int($rdb{"acc","sub"}).
	                   "% of all residues.\n")
	    if (defined $rdb{"acc","sub"} && $rdb{"acc","sub"}>30);
				# all residue surface/core
	$tmp0=$line_pre.sprintf("+-%12s-+"."-%5s-+" x 2 ,"-" x 12 ,"-----","-----");
	$tmp1=$line_pre.sprintf("| %-12s |","acc type");
	$tmp2=$line_pre.sprintf("| %-12s |","\% in protein");
	foreach $sym (split(//,"be")) {
	    next if (! defined $rdb{"acc",$sym});
	    $tmp1.= sprintf(" %5s |",$sym);
	    $tmp2.= sprintf(" %5.1f |",$rdb{"acc",$sym}); }
				# subset statistics (higher reliability)
	if (defined $rdb{"acc","sub"} && $rdb{"acc","sub"}>30){
	    $tmp0.=sprintf("+-%12s-+"."-%5s-+" x 2 ,"-" x 12 ,"-----","-----");
	    $tmp1.=sprintf("| %-12s |","SUBSET");
	    $tmp2.=sprintf("| %-12s |","\% in subset");
	    foreach $sym (split(//,"be")) {
		next if (! defined $rdb{"acc",$sym."sub"});
		$tmp1.= sprintf(" %5s |",$sym);
		$tmp2.= sprintf(" %5.1f |",$rdb{"acc",$sym."sub"}); }}
	push(@wrtloc,
	     $tmp0."\n",
	     $tmp1."\n",
	     $tmp2."\n",
	     $tmp0."\n",
	     $line_pre."\n"); }

				# --------------------------------------------------
				# HEADER= general information
				# --------------------------------------------------
    if ($Linfo || $Lnotation){
	push(@wrtloc,
	     $line_h3,  "\n",
	     $line_pre. "HEADER information\n",
	     $line_h3,  "\n",
	     $line_pre. "\n"); }
				# ------------------------------
				# protein
    if ($Linfo){
	$tag="About your protein:";
	push(@wrtloc,
	     $line_pre. "." x length($tag) ."\n",
	     $line_pre. $tag,"\n",
	     $line_pre. "." x length($tag) ."\n",
	     $line_pre. "\n");

	foreach $kwd (@{$ra_kwdHead}){
	    next if ($kwd !~/^prot/);
	    next if (! defined $rdb{$kwd});
	    $tmp_taken{$kwd}=1;
	    push(@wrtloc,
		 $line_pre.sprintf("%-15s: %-s\n",$kwd,$rdb{$kwd}));
	}
	push(@wrtloc,
	     $line_pre. "\n");

				# ------------------------------
				# alignment
	$tag="About the alignment used:";
	push(@wrtloc,
	     $line_pre. "." x length($tag) ."\n",
	     $line_pre. $tag ."\n",
	     $line_pre. "." x length($tag) ."\n",
	     $line_pre. "\n");
	foreach $kwd (@{$ra_kwdHead}){
	    next if ($kwd !~/^ali/);
	    next if (! defined $rdb{$kwd});
	    $tmp_taken{$kwd}=1;
	    push(@wrtloc,
		 $line_pre.sprintf("%-15s: %-s\n",$kwd,$rdb{$kwd}));
	}
	push(@wrtloc,
	     $line_pre. "\n"); }
				# ------------------------------
				# write residue composition
    if ($Lsummary && $Laverages){
	$tag="Residue composition for your protein:";
	push(@wrtloc,
	     $line_pre. "." x length($tag) ."\n",
	     $line_pre. $tag."\n",
	     $line_pre. "." x length($tag) ."\n",
	     $line_pre. "\n");

	$tmp=""; 
	$ct=$#tmp=0;
	@tmpaa=split(//,"ACDEFGHIKLMNPQRSTVWY");
	$tmp= $line_pre.sprintf("+-%15s-+"."-%5s-+" x 5 ,"-" x 15 ,
				"-----","-----","-----","-----","-----");
				# get composition
	if (! defined $rdb{$tmpaa[1],"seq"}){
				# ini compo
	    foreach $aa (@tmpaa){
		$rdb{$aa,"seq"}=0;}
				# get compo
	    foreach $itres (1 .. $rdb{"NROWS"}) {
		++$rdb{$rdb{"AA",$itres},"seq"};}
				# norm compo
	    foreach $itres (1 .. $rdb{"NROWS"}) {
		foreach $aa (@tmpaa){
		    $rdb{$aa,"seq"}=int(100*$rdb{$aa,"seq"}/$rdb{"NROWS"});
		}}
	}

	push(@wrtloc,
	     $tmp."\n");
	for ($it=1;$it<=$#tmpaa;$it+=5){
	    $tmp1=$line_pre.sprintf("| %-15s |","amino acid type");
	    $tmp2=$line_pre.sprintf("| %-15s |","\% in protein");
	    foreach $it2 ($it..($it+4)){
		$aa=$tmpaa[$it2];
		next if (! defined $rdb{$aa,"seq"});
		$tmp1.= sprintf(" %5s |",$aa);
		$tmp2.= sprintf(" %5.1f |",$rdb{$aa,"seq"});
	    }
	    push(@wrtloc,
		 $tmp1."\n",$tmp2."\n",$tmp."\n"); }
	push(@wrtloc,
	     $line_pre. "\n");}
				# ------------------------------
				# technical information
    if ($Linfo){
	$tag="About  the PROF methods used:";
	push(@wrtloc,
	     $line_pre. "." x length($tag) ."\n",
	     $line_pre. $tag."\n",
	     $line_pre. "." x length($tag) ."\n",
	     $line_pre. "\n");
	foreach $kwd (@{$ra_kwdHead}){
	    next if ($kwd !~/^prof/);
	    next if (! defined $rdb{$kwd});
	    $tmp_taken{$kwd}=1;
	    push(@wrtloc,
		 $line_pre.sprintf("%-15s: %-s\n",$kwd,$rdb{$kwd}));
	}
	push(@wrtloc,		# 
	     $line_pre. "\n");
    }

				# ------------------------------
				# copyright
    $tag="Copyright & Contact:";
    push(@wrtloc,
	 $line_pre. "." x length($tag) ."\n",
	 $line_pre. $tag."\n",
	 $line_pre. "." x length($tag) ."\n",
	 $line_pre. "\n");
    push(@wrtloc,
	 $line_pre. "-> Copyright:".$par{"txt","copyright"}   ."\n",
	 $line_pre. "-> Email:    ".$par{"txt","contactEmail"}."\n",
	 $line_pre. "-> WWW:      ".$par{"txt","contactWeb"}  ."\n",
	 $line_pre. "-> Fax:      ".$par{"txt","contactFax"}  ."\n");
    push(@wrtloc,
	 $line_pre. "\n"); 

				# ------------------------------
				# please quote
    $tag="Please quote:";
    push(@wrtloc,
	 $line_pre. "." x length($tag) ."\n",
	 $line_pre. $tag."\n",
	 $line_pre. "." x length($tag) ."\n",
	 $line_pre. "\n");
    push(@wrtloc,
	 $line_pre. "-> PROF:      ".$par{"txt","quote","phd1994"}."\n")
	if (defined $par{"txt","quote","phd1994"});
	
    push(@wrtloc,
	 $line_pre. "-> PROFsec:   ".$par{"txt","quote","profsec"}." \n")
	if (defined $rdb{"sec","class"} || defined $rdb{"1","PHEL"});
    push(@wrtloc,
	 $line_pre. "-> PROFacc:   ".$par{"txt","quote","profacc"}." \n")
	if (defined $rdb{"1","PREL"});
    push(@wrtloc,
	 $line_pre. "-> PROFhtm:   ".$par{"txt","quote","profhtm"}." \n")
	if (defined $rdb{"1","PHL"} || defined $rdb{"1","PMN"});
    push(@wrtloc,
	 $line_pre. "\n",
	 $line_pre. "\n");

				# ------------------------------
				# syntax style:
				#      kwd : explanation
				# ------------------------------

    if ($Lsummary && $Lnotation){
	push(@wrtloc,
	     $line_h3,  "\n",
	     $line_pre. "ABBREVIATIONS used:\n",
	     $line_h3,  "\n",
	     $line_pre. "\n");
		
				# (1) data keywords
	foreach $kwd (@{$ra_kwdBody}) {
	    next if (! defined $rdb{"1",$kwd});
	    next if (! defined $transDescr{$kwd} && ! defined $par{$kwd});
	    if (defined $par{$kwd}){
		$tmp=$par{$kwd};}
	    else{
		$tmp= $transDescr{$kwd}; }
	    $tmp=~s/\n\n+/\n/g;
	    $abbr=$transAbbr{$kwd}; $abbr=~s/\s*$//g;
	    $tmp_taken{$kwd}=0;
	    @tmp=split(/\n/,$tmp);
				# first line
	    push(@wrtloc,
		 $line_pre. sprintf("%-".$numwhiteNotation."s: %-s\n",$abbr,$tmp[1]));
				# all following
	    foreach $it (2..$#tmp){
		push(@wrtloc,
		     $line_pre. sprintf("%-".$numwhiteNotation."s  %-s\n","" ,$tmp[$it]));}

				# subset after REL
	    next if ($kwd !~ /RI/);
	    if    ($kwd eq "RI_S") { $kwd2="SUBsec"; }
	    elsif ($kwd eq "RI_A") { $kwd2="SUBacc"; }
	    elsif ($kwd eq "RI_M") { $kwd2="SUBhtm"; }
	    $abbr= $transAbbr{$kwd2};  $abbr=~s/\s*$//g;
	    $descr=$transDescr{$kwd2}; $descr=~s/\n$//; $descr=~s/\n\n+/\n/g; 
	    $tmp_taken{$abbr}=0;
	    @tmp=split(/\n/,$descr);
				# first line
	    push(@wrtloc,
		 $line_pre. sprintf("%-".$numwhiteNotation."s: %-s\n",$abbr,$tmp[1]));
				# all following
	    foreach $it (2..$#tmp){
		push(@wrtloc,
		     $line_pre. sprintf("%-".$numwhiteNotation."s  %-s\n","" ,$tmp[$it]));}
	} 
				# finish with empty line
	push(@wrtloc,
	     $line_pre. "\n");
				# (2) header asf
	foreach $kwd (@{$ra_kwdHead}){
	    next if (! defined $kwd || $kwd=~/^\s*$/);
	    if ($kwd=~/prof_skip/){
		push(@wrtloc,
		     $line_pre. sprintf("%-".$numwhiteNotation."s: %-s\n",$kwd,$par{"notation",$kwd}));
	    }
	    next if (! defined $par{"notation",$kwd});
	    next if (! defined $tmp_taken{$kwd} || ! $tmp_taken{$kwd});
	    $notation=$par{"notation",$kwd};
	    @tmp=split(/\n/,$notation);
				# first line
	    push(@wrtloc,
		 $line_pre. sprintf("%-".$numwhiteNotation."s: %-s\n",$kwd,$tmp[1]));
				# all following
	    foreach $it (2..$#tmp){
		push(@wrtloc,
		     $line_pre. sprintf("%-".$numwhiteNotation."s  %-s\n","" ,$tmp[$it]));}
	}
				# (3) alignment information
	if ($Lali){
	    foreach $kwd ("pide","lali"){
		push(@wrtloc,
		     $line_pre. sprintf("%-".$numwhiteNotation."s: %-s\n",
					"ali_".$kwd,$par{"notation","ali_".$kwd})
		     );
	    }
	    push(@wrtloc,
		 $line_pre. "\n");
	}
    }

    push(@wrtloc,
	 $line_pre. "\n",
	 $line_h1,  "\n",
	 $line_pre. "PROF_BODY with predictions for $titleLoc\n",
	 $line_h1,  "\n",
	 $line_pre. "\n");

    undef %segment;		# slim-is-in

				# --------------------------------------------------
				# NOW write
				# --------------------------------------------------
    $len=$lenLineHdr-1;
    foreach $wrt (@wrtloc) {
	$wrt=~s/\n//g;
	@tmp=split(/\n/,$wrt);
	foreach $tmp (@tmp){
				# normal
	    if (length($tmp)<$len){
		print $fhoutLoc 
		    $tmp. " " x ($len-length($tmp)) ."#\n";
		next; }
				# long lines: to split
	    $lentmp=$len-12;
	    while (length($tmp)>=$len){
		$tmp=~s/^(.{$lentmp}?\S*[\., \-\;\:])//;
		last if (! defined $1);
		print $fhoutLoc 
		    $1. " " x ($len-length($1))  ."#\n";
		$tmp=$line_pre.sprintf("%-".$numwhiteNotation."s  "," ").$tmp;
	    }
	    print $fhoutLoc 
		$tmp. " " x ($len-length($tmp)) ."#\n";
	}
    }
	
    return(1,"ok $SBR3");
}				# end of convProf_wrtHead

1;
