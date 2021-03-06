#!/usr/bin/perl
##------------------------------------------------------------------------------#
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
#    PERL library with routines related to converting PHD.rdb to HTML.         #
#    Note: entire thing exchangable with conv_phd2html.pl                      #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 

#===============================================================================
sub convPhd2Html {
    local($fileInLoc,$fileOutLoc,$modeWrtLoc,$nresPerLineLoc,
	  $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html                convert PHDrdb to HTML
#       in:                     $fileInLoc=       PHDrdb file
#       in:                     $fileOutLoc=      HTML output file
#                               =0                -> STDOUT
#       in:                     $modeWrtLoc=      mode for job
#                                  html:all       write head,body
#                                  html:<head|body>
#                                  data:all       write brief,normal,detail
#                                  data:<brief|norm|detail>
#                                  e.g. 'data:brief,data:normal,html:body'
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."convPhd2Html";
    $fhinLoc="FHIN_"."convPhd2Html";$fhoutLoc="FHOUT_"."convPhd2Html";
				# check arguments
    return(&errSbr("not def fileInLoc!"))      if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))     if (! defined $fileOutLoc);
    return(&errSbr("not def modeWrtLoc!"))     if (! defined $modeWrtLoc);
    return(&errSbr("not def nresPerLineLoc!")) if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!"))    if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!"))    if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!"))    if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!"))    if (! defined $riSubSymLoc);

    return(&errSbr("no fileIn=$fileInLoc!"))   if ($fileInLoc && ! -e $fileInLoc);

				# ------------------------------
				# HTML file handle
    $fileOutLoc=0               if ($fileOutLoc eq "STDOUT");
    $fhoutHtml="FHOUT_HTML_convPhd2Html";
    $fhoutHtml="STDOUT"         if (! $fileOutLoc);

				# ------------------------------
				# digest mode
				# ------------------------------
    $Lbrief=$Lnormal=$Ldetail=
	$Lhead=$Lbody=0;

				# what to write
    $modeWrtLoc.="data:all"     if ($modeWrtLoc!~/data/);
    $Lbrief=          1         if ($modeWrtLoc=~/data:(brief|all)/);
    $Lnormal=         1         if ($modeWrtLoc=~/data:(normal|all)/);
    $Ldetail=         1         if ($modeWrtLoc=~/data:(det|all)/);
				# which part of HTML
    $modeWrtLoc.="html:all"     if ($modeWrtLoc!~/html/);
    $Lhead=           1         if ($modeWrtLoc=~/html:(head|all)/);
    $Lbody=           1         if ($modeWrtLoc=~/html:(body|all)/);
    
				# --------------------------------------------------
				# (0) ini names
				# out GLOBAL: @kwdBody,$lenAbbr,%transSec2Htm
				#             %transSym,%transAbbr,%transDescr
				# --------------------------------------------------
    ($Lok,$msg)=
	&convPhd2Html_ini($nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc);
    return(&errSbr("failed on convPhd2Html_ini($nresPerLineLoc,".
		   "$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc)\n".
		   $msg."\n",$sbrName)) if (! $Lok);

                                # ini HTML css_styles
				# out GLOBAL: %css_phd
    &convPhd2Html_iniStyles();

				# ------------------------------
				# (1a) read RDB file OR: use
				#      GLOBAL input %rdb
				# ------------------------------
    ($Lok,$msg)=
	&rdRdb_here($fileInLoc,\@kwdHead,\@kwdBody
		    )           if ($fileInLoc);
    if (0){
	foreach $kwd (sort keys %rdb){
	    print "kwd=$kwd rdb=",$rdb{$kwd},"\n";
	}
	die;}

    return(&errSbr("failed rdRdb on $fileInLoc")) if (! $rdb{"NROWS"});
				# alternative (actually USED):
				#    data passed from lib-phd2000

				# ------------------------------
				# assign mode
    if (! defined $par{"optPhd"}){
	if    ($rdb{"1","PHEL"} && $rdb{"1","PREL"} && $rdb{"1","PiMo"}){
	    $par{"optPhd"}="3"; }
	elsif ($rdb{"1","PHEL"} && $rdb{"1","PREL"}){
	    $par{"optPhd"}="both"; }
	elsif ($rdb{"1","PHEL"}){
	    $par{"optPhd"}="sec"; }
	elsif ($rdb{"1","PREL"}){
	    $par{"optPhd"}="acc"; }
	elsif ($rdb{"1","PiMo"}){
	    $par{"optPhd"}="htm"; } }

				# ------------------------------
				# correct column names
				#    effective for PHDhtm single AND '3'
    ($Lok,$msg)=
	&convRdb2html_correct(); return(&errSbrMsg("failed correcting column names",
						   $msg,$SBR1)) if (! $Lok);

				# ------------------------------
				# (2) get some statistics asf
				# ------------------------------

    $titleLoc=$fileInLoc; $titleLoc=~s/^.*\/|\..*$//g;
    $titleLoc=$rdb{"prot_id"}." ".$rdb{"prot_name"} if (! $titleLoc);
	
    ($Lok,$msg)=
        &convPhd2Html_preProcess(
				 ); return(&errSbr("failed convPhd2Html_preProcess".
						   $msg."\n"))  if (! $Lok);

				# ------------------------------
				# (3) write HTML header
				# ------------------------------
    ($Lok,$msg)=
	&convPhd2Html_wrtHead($fileInLoc,$titleLoc,$Lhead,$fhoutHtml,$fileOutLoc,\%css_phd);

    return(&errSbr("failed convPhd2Html_wrtHead".
                   $msg."\n"))  if (! $Lok);
                                # ------------------------------
                                # (4) write HTML body (header)
				# in GLOBAL: @kwdBody,
				#            %transDescr,%transAbbr
				#            $Lbrief,$Lnormal,$Ldetail
                                # ------------------------------

    ($Lok,$msg)=
	&convPhd2Html_wrtBodyHdr($titleLoc,$fhoutHtml
				 ); return(&errSbr("failed convPhd2Html_wrtBodyHdr".
						   $msg."\n"))  if (! $Lok);
				# ------------------------------
				# prepare write predictions
				# ------------------------------
    $nblocks=1;                 # number of blocks to write
    $nblocks=1+int($rdb{"NROWS"}/$nresPerLineLoc)
	if ($nresPerLineLoc > 0);
	
				# --------------------------------------------------
				# (5) write HTML body: prediction
				# --------------------------------------------------
				# make all of same length
    print $fhoutHtml 
	"<PRE style=\"font-type:courier\">\n";

				# ------------------------------
				# brief summary
				# ------------------------------
    if ($Lbrief) {
	$#kwdBodyTmp=0;
	foreach $kwd (@kwdBody) {
	    next if ($kwd=~/^[OP](REL|RTN|RHL|RMN)|^p[HELTMN]/);
	    push(@kwdBodyTmp,$kwd); }
	print $fhoutHtml "<h3><A NAME=\"phd_brief\">PHD results (brief)<\/A><\/h3><P>\n";
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"brief",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      \%css_phd,\@kwdBodyTmp);
	print $fhoutHtml "<P><BR><R><\/HR>\n"; }

				# ------------------------------
				# normal 
				# ------------------------------
    if ($Lnormal) {
	print $fhoutHtml "<h3><A NAME=\"phd_normal\">PHD results (normal)<\/A><\/h3><P>\n";
	$#kwdBodyTmp=0;
	foreach $kwd (@kwdBody) {
	    next if ($kwd=~/^[OP](REL)|^p[HELTMN]/);
	    push(@kwdBodyTmp,$kwd); }
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"normal",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      \%css_phd,\@kwdBodyTmp);
	print $fhoutHtml "<P><BR><R><\/HR>\n";}

				# ------------------------------
				# full details
				# ------------------------------
    if ($Ldetail) {
	print $fhoutHtml "<STRONG><A NAME=\"phd_detail\">PHD results (detail)<\/A><\/STRONG><P>\n";
	$#kwdBodyTmp=0;
	foreach $kwd (@kwdBody) {
	    next if ($kwd=~/^RI/ || 
		     $kwd=~/^(PHEL|OHEL|Obie|PRMN|OMN|PMN|PiMo)$/);
	    next if ($Lis_htm_only && $kwd=~/^p[HETL]$/);
	    push(@kwdBodyTmp,$kwd); }

				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,
				      "detail",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      \%css_phd,\@kwdBodyTmp);
	print $fhoutHtml "<P><BR><R><\/HR>\n"; }
    print $fhoutHtml "<\/PRE>\n";

				# ------------------------------
				# (6) write HTML body: fin
				# ------------------------------
	print $fhoutHtml 
	"</BODY>\n",
	"</HTML>\n";
    close($fhoutHtml)           if ($fhoutHtml ne "STDOUT");

    return(1,"ok $sbrName");
}				# end of convPhd2Html

#===============================================================================
sub convPhd2Html_ini {
    local($nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc)=@_;
    local($sbrName2,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_ini                       
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2=$tmp."convPhd2Html_ini";
    $fhinLoc="FHIN_"."convPhd2Html_ini";$fhoutLoc="FHOUT_"."convPhd2Html_ini";
				# check arguments
    return(&errSbr("not def nresPerLineLoc!",$sbrName2))     if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!",$sbrName2))        if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",$sbrName2))        if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",$sbrName2))        if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",$sbrName2))        if (! defined $riSubSymLoc);

				# columns to read
    @kwdBody=
	(
	 "AA",
	 "OHEL","PHEL","RI_S",               "pH","pE","pL",
	 "Obie","Pbie","RI_A",               "OREL","PREL",
	 "OMN", "PMN", "RI_M","PRMN","PiMo", "pM","pN",
#	 "OHL", "PHL", "RI_H","PRHL","PiTo", "pH","pL",
#	 "","","","",
	 );
				# for HTM : header
    @kwdHead=
	("NHTM_BEST","NHTM_2ND_BEST",
	 "REL_BEST","REL_BEST_DIFF", "REL_BEST_DPROJ",
	 "MODEL","MODEL_DAT",
	 "HTMTOP_OBS","HTMTOP_PRD","HTMTOP_MODPRD","HTMTOP_RID","HTMTOP_RIP",

	 "prot_id","prot_name",
	 "prot_nres","prot_nali","prot_nchn","prot_kchn","prot_nfar",
	 "ali_orig","ali_used","ali_para",
	 "phd_fpar","phd_nnet","phd_mode","phd_version","phd_skip"
	 );

				# e.g. 'L' to ' ' in writing
    %transSym=
	('L',    " ",
	 'i',    " ",
	 'N',    " ",
	 );
				# translate PHDsec to PHDhtm
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
	 'PiTo',   "PiMo",
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
	 'PHEL',   "PHD_sec",
	 'RI_S',   "Rel_sec",
	 'SUBsec', "SUB_sec",
	 'pH',     " pH_sec",
	 'pE',     " pE_sec",
	 'pL',     " pL_sec",
#	 '', "",

	 'OREL',   "OBS_acc",
	 'PREL',   "PHD_acc",
	 'Obie',   "O_3_acc",
	 'Pbie',   "P_3_acc",
	 'RI_A',   "Rel_acc",
	 'SUBacc', "SUB_acc",
#	 '', "",

	 'OMN',    "OBS_htm",
	 'PMN',    "PHD_htm",
	 'PRMN',   "PHDrhtm",
#	 'PFMN',   "PHDfhtm",
	 'PiMo',   "PiMohtm",
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
	           
	         
	 'PHEL',   "PHD predicted secondary structure: H=helix, E=extended (sheet), blank=other (loop)".
	           "\n"."PHD = PHD: Profile network prediction HeiDelberg",
	 'RI_S',   "reliability index for PHDsec prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBsec', "subset of the PHDsec prediction, for all residues with an expected average accuracy > 82% (tables in header)\n".
	           "     NOTE: for this subset the following symbols are used:\n".
	           "  L: is loop (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubSecLoc\n",
	 'pH',     "'probability' for assigning helix (1=high, 0=low)",
	 'pE',     "'probability' for assigning strand (1=high, 0=low)",
	 'pL',     "'probability' for assigning neither helix, nor strand (1=high, 0=low)",


				# solvent accessibility
	 'OREL',   "observed relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
	 'PREL',   "PHD predicted relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
	 'Obie',   "observerd relative solvent accessibility (acc) in 3 states: b = 0-9%, i = 9-36%, e = 36-100%.",
	 'Pbie',   "PHD predicted relative solvent accessibility (acc) in 3 states: b = 0-9%, i = 9-36%, e = 36-100%.",
	 'RI_A',   "reliability index for PHDacc prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBacc', "subset of the PHDacc prediction, for all residues with an expected average correlation > 0.69 (tables in header)\n".
	           "     NOTE: for this subset the following symbols are used:\n".
	           "  I: is intermediate (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubAccLoc\n",

	 '', "",

	 'OMN',    "observed membrane helix: M=helical transmembrane region, blank=non-membrane",
	           
	         
	 'PMN',    "PHD predicted membrane helix: M=helical transmembrane region, blank=non-membrane".
	           "\n"."PHD = PHD: Profile network prediction HeiDelberg",
	 'PRMN',   "refined PHD prediction: M=helical transmembrane region, blank=non-membrane",
	 'PiMo',   "PHD prediction of membrane topology: T=helical transmembrane region, i=inside of membrane, o=outside of membrane",
	 'RI_M',   "reliability index for PHDhtm prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'RI_H',   "reliability index for PHDhtm prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBhtm', "subset of the PHDhtm prediction, for all residues with an expected average accuracy > 98% (tables in header)\n".
	           "     NOTE: for this subset the following symbols are used:\n".
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

    $lenAbbr=10;		# width of abbreviation at begin of each row
		
    return(1,"ok $sbrName2");
}				# end of convPhd2Html_ini

#===============================================================================
sub convPhd2Html_iniStyles {
#-------------------------------------------------------------------------------
#   convPhd2Html_iniStyles    sets styles for convPhd2Html
#       out GLOBAL:             %css_phd{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#-------------------------------------------------------------------------------

    %css_phd=
	(
				# residue charges
	 'res-K',    "{color:blue}",
	 'res-R',    "{color:blue}",
	 'res-D',    "{color:red}",
	 'res-E',    "{color:red}",
				# secondary structure
	 'sec-H',    "{color:red}",
	 'sec-E',    "{color:blue}",
	 'sec-L',    "{color:green}",

	 'sec-Hsub', "{background-color:red;color:white}",
	 'sec-Esub', "{background-color:blue;color:white}",
	 'sec-Lsub', "{background-color:green;color:white}",

	 'sec-pH',   "{background-color:red;color:white}",
	 'sec-pE',   "{background-color:blue;color:white}",
	 'sec-pL',   "{background-color:green;color:white}",

	 'sec-0',    "{color:silver}",
	 'sec-1',    "{color:silver}",
	 'sec-2',    "{color:silver}",
	 'sec-3',    "{color:silver}",
	 'sec-4',    "{color:gray}",
	 'sec-5',    "{color:gray}",
	 'sec-6',    "{color:gray}",
	 'sec-7',    "{color:black}",
	 'sec-8',    "{color:black}",
	 'sec-9',    "{color:black}",
				# transmembrane
	 'htm-M',    "{color:purple}",
	 'htm-N',    "{color:olive}",
	 'htm-H',    "{color:purple}",
	 'htm-L',    "{color:olive}",

	 'htm-Msub', "{background-color:purple;color:white}",
	 'htm-Nsub', "{background-color:olive;color:white}",
	 'htm-Hsub', "{background-color:purple;color:white}",
	 'htm-Lsub', "{background-color:olive;color:white}",

 	 'htm-pM',   "{background-color:purple;color:white}",
	 'htm-pN',   "{background-color:olive;color:white}",
 	 'htm-pH',   "{background-color:purple;color:white}",
	 'htm-pL',   "{background-color:olive;color:white}",

	 'htm-i',    "{color:olive}",
	 'htm-o',    "{color:teal}",

	 'htm-0',    "{color:silver}",
	 'htm-1',    "{color:silver}",
	 'htm-2',    "{color:silver}",
	 'htm-3',    "{color:silver}",
	 'htm-4',    "{color:silver}",
	 'htm-5',    "{color:gray}",
	 'htm-6',    "{color:gray}",
	 'htm-7',    "{color:gray}",
	 'htm-8',    "{color:black}",
	 'htm-9',    "{color:black}",
				# accessibility
	 'acc-e',    "{color:aqua}",
	 'acc-i',    "{color:gray}",
	 'acc-b',    "{color:maroon}",
	 'acc-esub', "{background-color:aqua;color:white}",
	 'acc-isub', "{background-color:gray;color:white}",
	 'acc-bsub', "{background-color:maroon;color:white}",

	 'acc-PREL', "{background-color:gray;color:white}",
	 'acc-OREL', "{background-color:gray;color:white}",

	 'acc-0',    "{color:silver}",
	 'acc-1',    "{color:silver}",
	 'acc-2',    "{color:gray}",
	 'acc-3',    "{color:gray}",
	 'acc-4',    "{color:gray}",
	 'acc-5',    "{color:black}",
	 'acc-6',    "{color:black}",
	 'acc-7',    "{color:black}",
	 'acc-8',    "{color:black}",
	 'acc-9',    "{color:black}",

	 );
}				# end of convPhd2Html_iniStyles

#===============================================================================
sub convRdb2html_correct {
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convRdb2html_correct        correct column names for old PHD stuff
#                               effective for PHDhtm single AND '3'
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."convRdb2html_correct";

				# ------------------------------
    $Lis_htm_only=0;		# correct for PHDhtm single
    if ((defined $rdb{"1","PiTo"} && ! defined $rdb{"1","PTN"}) ||
	(defined $rdb{"1","PiMo"} && ! defined $rdb{"1","PMN"}) ||
	(defined $rdb{"1","PiTo"} && 
	 defined $rdb{"1","RI_S"} &&   defined $rdb{"1","OtH"}) ) {
	$Lis_htm_only=1;
	foreach $kwd ("PHL","OHL","PRHL","RI_S","pH","pL","OtH","OtL","PiTo","PTN") {
	    next if (! defined $transData{$kwd} || ! defined $rdb{"1",$kwd});
	    $kwdNew=$transData{$kwd}; $tmp1="";$tmp2="";
	    foreach $it (1 .. $rdb{"NROWS"}) {
		$rdb{$it,$kwdNew}=$sym=$rdb{$it,$kwd};
		$tmp1.=$sym;
		next if (! defined $transSec2Htm{$sym});
		undef $rdb{$it,$kwd};
		$symNew=$transSec2Htm{$sym};
		$tmp2.=$symNew;
		$rdb{$it,$kwdNew}=$symNew;}}}
				# ------------------------------
				# correct for PHDhtm all 3
    else {
	foreach $kwd ("OTN", "PTN", "PRTN","PRFTN","PR2TN","PiTo","RI_H", 
		      "OtT","pT","pN") {
	    next if (! defined $rdb{"1",$kwd});
	    $kwdNew=$kwd;
	    $kwdNew=$transData{$kwd}  if (defined $transData{$kwd});
	    foreach $it (1 .. $rdb{"NROWS"}) {
				# (1) change symbol used
		$sym=$rdb{$it,$kwd};
		$sym=$transSec2Htm{$sym} if (defined $transSec2Htm{$sym});
		undef $rdb{$it,$kwd};
		$rdb{$it,$kwd}=$sym;
				# (2) change keyword
		$rdb{$it,$kwdNew}=$rdb{$it,$kwd} if ($kwdNew ne $kwd);
	    }
	}}
    return(1,"ok $SBR2");
}				# end of convRdb2html_correct

#===============================================================================
sub convPhd2Html_wrtOneLevel {
    local($nblocksLoc,$lenAbbrLoc,$fhoutHtml,$fileOutLoc,$modeLoc,
	  $nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
	  $rh_css_phd,$ra_kwdBodyLoc)=@_;
    local($sbrName3,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_wrtOneLevel    writes one level of detail
#       in:                     $nblocksLoc=      number of blocks 
#                                                 (with NresPerlLineLoc written per block)
#       in:                     $lenAbbrLoc=      
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $fileOutLoc=      HTML output file
#       in:                     $modeLoc=         controls what to write
#                                   <brief|normal|detail>
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#       in:                     $rh_css_phd=      reference to %css_phd{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#       in:                     
#       in GLOBAL:              %transSym,%transAbbr
#       out:                    1|0,msg,  implicit: write to $fhoutHtml
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."convPhd2Html_wrtOneLevel";
				# check arguments
    return(&errSbr("not def nblocksLoc!",$sbrName3))     if (! defined $nblocksLoc);
    return(&errSbr("not def lenAbbrLoc!",$sbrName3))     if (! defined $lenAbbrLoc);
    return(&errSbr("not def fhoutHtml!",$sbrName3))      if (! defined $fhoutHtml);
    return(&errSbr("not def fileOutLoc!"))               if (! defined $fileOutLoc);
    return(&errSbr("not def modeLoc!"))                  if (! defined $modeLoc);
    return(&errSbr("not def nresPerLineLoc!",$sbrName3)) if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!",$sbrName3))    if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",$sbrName3))    if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",$sbrName3))    if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",$sbrName3))    if (! defined $riSubSymLoc);
    return(&errSbr("not def rh_css_phd!",$sbrName3))     if (! defined $rh_css_phd);
    return(&errSbr("not def $ra_kwdBodyLoc!",$sbrName3)) if (! $ra_kwdBodyLoc);

				# --------------------------------------------------
				# loop over all blocks
				#    i.e. residues 1-60 ..
				# --------------------------------------------------

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

	$string=&myprt_npoints($ncount,$itEnd);
	$tmp=" " x $lenAbbrLoc;
	print $fhoutHtml "$tmp"," ",$string,"\n";

				# --------------------------------------------------
				# loop over all keywords
				#    i.e. all rows (AA,OHEL,PHEL)
				# --------------------------------------------------
	foreach $itKwd (1..$#{$ra_kwdBodyLoc}) {
	    $kwd=$ra_kwdBodyLoc->[$itKwd];
	    next if (! defined $rdb{$itBeg,$kwd});
				# all into one string
	    $string="";
				# ri
	    if    ($kwd eq "RI_S") { $relStrong=$riSubSecLoc; }
	    elsif ($kwd eq "RI_A") { $relStrong=$riSubAccLoc; }
	    elsif ($kwd eq "RI_M") { $relStrong=$riSubHtmLoc; }
				# probability
	    $#string=0
		if ($kwd=~/^p[HELTMN]$/ || $kwd=~/^[OP]REL/);
	    
				# ------------------------------
				# loop over protein
				# ------------------------------
	    foreach $itRes ($itBeg .. $itEnd) {
		$sym=$rdb{$itRes,$kwd}; 
				# normalise relative acc to numbers 0-9
		$sym=&exposure_project_1digit($sym)
		    if ($kwd =~ /^[OP]REL/);
		
				# ------------------------------
				# probability PHDsec, PHDhtm
		if ($kwd=~/^p[HELTMN]$/) {
		    foreach $it (1..10){
			if ($sym <= ($it-1)) {
			    $string[$it].=" "; }
			else {
			    $string[$it].="."; }}}
				# ------------------------------
				# relative accessibility
		elsif ($kwd=~/^[OP]REL$/) {
		    foreach $it (1..10){
			if ($sym <= ($it-1)) {
			    $string[$it].=" "; }
			else {
			    $string[$it].="."; }}}
				# ------------------------------
				# simple strings
		else {
		    $symPrt=$sym;
				# HTM: from 'HL' -> 'MN'
		    $symPrt=$transSec2Htm{$sym} if ($kwd=~/^[OP](MN|RMN|FMN)|^[OP](HL|RHL|FHL)/);
				# for brief RI =< |*>
		    if ($modeLoc eq "brief" && $kwd=~/^RI/) {
			$symPrt="*";
			$symPrt=" " if ($sym < $relStrong); }
				# which style
		    if    ($kwd=~/^[OP]HEL|^p[HEL]|RI_S/)  { 
			$kwdCss="sec-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](REL|bie)|^RI_A/)    { 
			$kwdCss="acc-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](MN|RMN|iMo)|^p[MN]|^RI_M/) { 
			$kwdCss="htm-".$symPrt  if ($symPrt !~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](HL|RHL|iTo)|^p[HL]|^RI_H/) { 
			$kwdCss="htm-".$symPrt  if ($symPrt !~/^[ \*]$/); }
				# sequence
		    elsif ($kwd=~/^AA/){
			$kwdCss="res-".$symPrt  if ($symPrt !~/^[ \*]$/); }
				# 'L' -> ' '
		    $symPrt=$transSym{$sym} if (defined $transSym{$sym} &&
						$kwd !~/^[OP]REL/       &&
						$kwd ne "AA"            && 
						$kwd !~/PiMo/           && 
						$kwd !~/PiTo/           && 
						$symPrt ne " "          && 
						$symPrt ne "*"             );

		    if    ($kwd eq "AA" && defined $kwdCss && defined $rh_css_phd->{$kwdCss}) {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."<\/FONT>"; 
		    }
		    elsif (! defined $kwdCss    || ! defined $rh_css_phd->{$kwdCss} 
			   || $kwd =~/^[OP]REL/ || $kwd eq "AA"
			   || $symPrt eq " "    || $symPrt eq "*" || $symPrt eq ".") {
			$string.=$symPrt; }
		    else {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."<\/FONT>"; } 
		} 
	    }			# end of loop over protein

	    $abbr=$kwd;
	    $abbr=$transAbbr{$kwd} if (defined $transAbbr{$kwd});
	    $empty=" " x ($lenAbbrLoc-length($abbr));
	    $lenTotal=length($empty.$abbr);
				# link description of row to header
	    if ($fileOutLoc) {
#		$abbr="<A HREF=\"$fileOutLoc#$kwd\">$abbr</A>$empty";}
		$abbr="<A HREF=\"#$kwd\">$abbr</A>$empty";}
	    else {
		$abbr="<A HREF=\"#$kwd\">$abbr</A>$empty";}

				# probability PHDsec
	    if ($kwd=~/^p[HELTMN]$/) {
		if ($kwd=~/^p[HEL]$/) {
		    $kwdCss="sec-".$kwd; }
		elsif ($kwd=~/^p[TMN]$/) {
		    $kwdCss="htm-".$kwd; }

		if (! defined $kwdCss    || ! defined $rh_css_phd->{$kwdCss}) {
		    $tmp1="";
		    $tmp2=""; }
		else {
		    $tmp1="<FONT CLASS=".$kwdCss.">";
		    $tmp2="<\/FONT>";}
		foreach $it (1..9) {
		    $it2=10-$it;
		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)/10;
		    $txt= $abbr.$string[$it2].sprintf("  %2.1f ",$tmp3);
		    $txt.=$abbr if (! $nresPerLineLoc);
		    print $fhoutHtml $txt,"\n";}
		print $fhoutHtml " " x $lenTotal, "-" x $ncount,"\n";}

				# relative acc PHDacc
	    elsif ($kwd=~/^[OP]REL$/) {
		$kwdCss="acc-".$kwd;
		if (! defined $kwdCss    || ! defined $rh_css_phd->{$kwdCss}) {
		    $tmp1="";
		    $tmp2=""; }
		else {
		    $tmp1="<FONT CLASS=".$kwdCss.">";
		    $tmp2="<\/FONT>";}
		foreach $it (1..9) {
		    $it2=10-$it;
		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)*($it2+1);
		    $txt= $abbr.$string[$it2].sprintf("  %3d%-s ",int($tmp3),"%");
		    $txt.=$abbr if (! $nresPerLineLoc);
		    print $fhoutHtml $txt,"\n";}
		print $fhoutHtml " " x $lenTotal, "-" x $ncount,"\n";}

	    else {
		print $fhoutHtml "$abbr $string\n"; }

				# ------------------------------
				# skip if brief (or detail)
	    if ($modeLoc eq "brief" || $modeLoc eq "detail") {
				# spacer
		print $fhoutHtml "\n"
		    if ($kwd=~/RI/);
		next; }

				# ------------------------------
				# subset after REL
	    if ($kwd=~/RI/) {
		if    ($kwd eq "RI_S") { 
		    $kwdTmp="PHEL"; $kwdTmp2="SUBsec"; $abbr=$transAbbr{"SUBsec"};}
		elsif ($kwd eq "RI_A") { 
		    $kwdTmp="Pbie"; $kwdTmp2="SUBacc"; $abbr=$transAbbr{"SUBacc"};}
		elsif ($kwd eq "RI_M") { 
		    $kwdTmp="PMN";  $kwdTmp2="SUBhtm"; $abbr=$transAbbr{"SUBhtm"};}

		$string="";
		foreach $itRes ($itBeg .. $itEnd) {
		    $sym=$rdb{$itRes,$kwdTmp}; 
		    $rel=$rdb{$itRes,$kwd}; 
		    if ($rel >= $relStrong) {
			$symPrt=$sym; 
				# HTM: from 'HL' -> 'MN'
			$symPrt=$transSec2Htm{$sym} if ($kwd=~/^RI_M/);}
		    else {
			$symPrt=$riSubSymLoc; }
		    if    ($kwd=~/^RI_S/) { $kwdCss="sec-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_A/) { $kwdCss="acc-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_M/) { $kwdCss="htm-".$symPrt."sub"; }

		    if (! defined $kwdCss || ! defined $rh_css_phd->{$kwdCss} || $symPrt eq " ") {
			$string.=$symPrt; }
		    else {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."<\/FONT>";}  
		}

		$empty=" " x ($lenAbbrLoc-length($abbr));
				# link description of row to header
		if ($fileOutLoc) {
#		    $abbr="<A HREF=\"$fileOutLoc#$kwdTmp2\">$abbr</A> $empty"; }
		    $abbr="<A HREF=\"#$kwdTmp2\">$abbr</A> $empty"; }
		else {
		    $abbr="<A HREF=\"#$kwd\">$abbr</A> $empty";}

		print $fhoutHtml $abbr,$string,"\n";
				# after: spacer
		print $fhoutHtml "\n";
	    }			# end of subset

	}			# end of loop over all rows
	print $fhoutHtml "\n";

    }				# end of all blocks
    print $fhoutHtml "\n";
    return(1,"ok $sbrName3");
}				# end of convPhd2Html_wrtOneLevel

#===============================================================================
sub convPhd2Html_preProcess {
#    local($rh_rdb)=@_;
    local($sbrName3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_preProcess     compiles probabilites from network output
#                               and composition AND greps stuff from HEADER!
#       in:                     $rh_rdb{}= reference passed from reading RDB file
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
    $sbrName3=$tmp."convPhd2Html_preProcess";
				# check arguments
#    return(&errSbr("not def rh_rdb!",   $sbrName3))    if (! defined $rdb{'NROWS'});

				# ------------------------------
				# compile residue composition
				# ------------------------------
    if (defined $rdb{"1","AA"}) {
	undef %tmp;
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    $sym=$rdb{$itRes,"AA"};
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
				# compile PHDsec prob
				#      pH, pE, pL normalised to 0-9
				#      pH + pE +pL = 9
				# ------------------------------
    if (! defined $rdb{"1","pH"} && defined $rdb{"1","OtH"}) {
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    $sum=$rdb{$itRes,"OtH"}+$rdb{$itRes,"OtE"}+$rdb{$itRes,"OtL"};
	    $rdb{$itRes,"pH"}=int(10*($rdb{$itRes,"OtH"}/$sum));
	    $rdb{$itRes,"pH"}=9  if ($rdb{$itRes,"pH"} > 9);
	    $rdb{$itRes,"pE"}=int(10*($rdb{$itRes,"OtE"}/$sum)); 
	    $rdb{$itRes,"pE"}=9  if ($rdb{$itRes,"pE"} > 9);
	    $rdb{$itRes,"pL"}=int(10*($rdb{$itRes,"OtL"}/$sum)); 
	    $rdb{$itRes,"pL"}=9  if ($rdb{$itRes,"pL"} > 9);
	} }
    
				# ------------------------------
				# compile sec str composition
				# ------------------------------
    if (defined $rdb{"1","PHEL"}) {
	undef %tmp;
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    $sym=$rdb{$itRes,"PHEL"};
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
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    $sum=$rdb{$itRes,"OtM"}+$rdb{$itRes,"OtN"};
	    $rdb{$itRes,"pM"}=int(10*($rdb{$itRes,"OtM"}/$sum));
	    $rdb{$itRes,"pM"}=9 if ($rdb{$itRes,"pM"} > 9);
	    $rdb{$itRes,"pN"}=int(10*($rdb{$itRes,"OtN"}/$sum)); 
	    $rdb{$itRes,"pN"}=9 if ($rdb{$itRes,"pN"} > 9);
	}}

				# ------------------------------
				# HTM header
				# ------------------------------
    if ($#kwdHead > 0 && defined $rdb{"1","PiMo"}) {
	@tmp=split(/\#/,$rdb{"header"});
	undef %tmp;
	foreach $tmpHdr (@tmp) {
	    foreach $kwd (@kwdHead) {
		next if ($tmpHdr !~ /$kwd[\s\t:]/);
		$tmp=$tmpHdr;
		$tmp=~s/^.*$kwd[\s\t:]+(.+)$/$1/g;
		$tmp=~s/^\s*|[\s\n]*$//g;
		$tmp{$kwd}.="\n".$tmp if (defined $tmp{$kwd}); 
		$tmp{$kwd}=$tmp       if (! defined $tmp{$kwd});
		last; }}
	foreach $kwd (@kwdHead) {
	    next if (! defined $tmp{$kwd});
	    $rdb{"header",$kwd}=$tmp{$kwd}; }}

				# ------------------------------
				# compile accessibility composition
				# ------------------------------
    if (defined $rdb{"1","PREL"}) {
	undef %tmp;foreach $sym ("b","e","bsub","esub"){$tmp{$sym}=0;}
	foreach $itRes (1..$rdb{"NROWS"}) { 
	    if (! defined $rdb{$itRes,"Pbe"}){
		$par{"thresh2acc"}=16   if (! defined $par{"thresh2acc"});
		$sym="b";
		$sym="e" if ($rdb{$itRes,"PREL"} > $par{"thresh2acc"}); }
	    else { 
		$sym=$rdb{$itRes,"Pbe"};}
	    ++$tmp{$sym};
	    ++$tmp{$sym."sub"}  if ($rdb{$itRes,"RI_A"}>= $riSubAccLoc);}

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

    return(1,"ok $sbrName3");
}				# end of convPhd2Html_preProcess

#===============================================================================
sub convPhd2Html_wrtHead {
    local($fileInLoc,$titleLoc,$Lhead,$fhoutHtml,$fileOutLoc,$rh_css_phd)=@_;
    local($sbrName3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_wrtHead        writes HEAD part of HTML file
#       in:                     $fileInLoc=       PHDrdb file
#       in:                     $titleLoc=        to be used for HTML title
#       in:                     $Lhead=           if 1 write header,
#                                                 if 0 open file only
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $fileOutLoc=      HTML output file
#       in:                     $rh_css_phd=      reference to %css_phd{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."convPhd2Html_wrtHead";
				# check arguments
    return(&errSbr("not def fileInLoc!", $sbrName3)) if (! defined $fileInLoc);
    return(&errSbr("not def titleLoc!",  $sbrName3)) if (! defined $titleLoc);
    return(&errSbr("not def fileOutLoc!",$sbrName3)) if (! defined $fileOutLoc);
    return(&errSbr("not def fhoutHtml!", $sbrName3)) if (! defined $fhoutHtml);
    return(&errSbr("not def rh_css_phd!",$sbrName3)) if (! defined $rh_css_phd);

    
    if ($fileOutLoc) {
	open($fhoutHtml,">".$fileOutLoc) || 
	    return(&errSbr("fileOutLoc=$fileOutLoc, not created",$sbrName3)); }

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    return(1,"ok $sbrName3")    if (! $Lhead);

    $style= "<STYLE TYPE=\"text/css\">\n";
    $style.="<!-- \n";
				# PHDsec
    foreach $kwd ("H","E","L") {
	$style.="FONT."."sec-".$kwd.$rh_css_phd->{"sec-".$kwd}."\n";
	$style.="FONT."."sec-".$kwd."sub".$rh_css_phd->{"sec-".$kwd."sub"}."\n"; 
	$style.="FONT."."sec-"."p".$kwd.$rh_css_phd->{"sec-"."p".$kwd}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."sec-".$kwd.$rh_css_phd->{"sec-".$kwd}."\n";}
				# PHDacc
    foreach $kwd ("e","i","b") {
	$style.="FONT."."acc-".$kwd.$rh_css_phd->{"acc-".$kwd}."\n"; 
	$style.="FONT."."acc-".$kwd."sub".$rh_css_phd->{"acc-".$kwd."sub"}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."acc-".$kwd.$rh_css_phd->{"acc-".$kwd}."\n";}
    foreach $kwd ("PREL","OREL"){
	$style.="FONT."."acc-".$kwd.$rh_css_phd->{"acc-".$kwd}."\n";}
				# PHDhtm
    foreach $kwd ("M","N") {
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n"; 
	$style.="FONT."."htm-".$kwd."sub".$rh_css_phd->{"htm-".$kwd."sub"}."\n"; 
	$style.="FONT."."htm-"."p".$kwd.$rh_css_phd->{"htm-"."p".$kwd}."\n"; }
    foreach $kwd ("i","o") {
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n";}

				# sequence: only for HTM
    if ($#kwdHead > 0 && defined $rdb{"1","PiMo"}) {
	foreach $kwd ("E","D","K","R") {
	    $style.="FONT."."res-".$kwd.$rh_css_phd->{"res-".$kwd}."\n";}}

				# subtoc
    $style.="DIV.subtoc { padding: 1em\; margin: 1em 0\;border: thick inset \;background: silver\;}\n";
    $style.=" -->\n";
    $style.="<\/STYLE>\n";

    ($Lok,$msg)=
	&htmlWrtHead($fhoutHtml,"PHD prediction ($titleLoc)",$style);

    return(&errSbr("failed writing HTML header (file=$fileInLoc)",$sbrName3))
	if (! $Lok);

    return(1,"ok $sbrName3");
}				# end of convPhd2Html_wrtHead

#===============================================================================
sub convPhd2Html_wrtBodyHdr {
    local($titleLoc,$fhoutHtml)=@_;
    local($sbrName3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_wrtBodyHdr     writes first part of HTML BODY (TOC, syntax)
#       in:                     $titleLoc=        to be used for HTML title
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $rh_rdb{}= reference passed from reading RDB file
#       in GLOBAL:              @kwdBody,%transDescr,%transAbbr
#       in GLOBAL:              $Lbrief,$Lnormal,$Ldetail
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."convPhd2Html_wrtBodyHdr";
				# check arguments
    return(&errSbr("not def titleLoc!",  $sbrName3)) if (! defined $titleLoc);
    return(&errSbr("not def fhoutHtml!", $sbrName3)) if (! defined $fhoutHtml);
#    return(&errSbr("not def rh_rdb!",    $sbrName3)) if (! defined $rdb{'NROWS'});

    undef %tmp_taken;
				# ------------------------------
				# TOC asf
				# ------------------------------
    print $fhoutHtml 
	'<div class="nice">',
#	"<BODY style=\"background:white\">\n", # body tag
#	"<H1>PHD predictions for $titleLoc</H1>\n",
	"\n";

#    print $fhoutHtml 
#	"<!-- -------------------------------------------------------------------------------- -->\n",
#	"<!-- BEG TOC -->\n",
#	"<DIV class=\"subtoc\">\n",
#	"<P><\/P>\n",
#	"<STRONG>Contents:</STRONG>\n",
#	"<P>\n",
#	"<UL>\n";
#    print $fhoutHtml 
#	"<LI><A HREF=\"#phd_syn\">SYNOPSIS of prediction<\/A><\/LI>\n",
#	"\t <OL>\n";
#    print $fhoutHtml 
#	"\t <LI><A HREF=\"#phd_syn_class\"> secondary structure class<\/A><\/LI>\n"
#	    if (defined $rdb{"sec","class"});
#    print $fhoutHtml 
#	"\t <LI><A HREF=\"#phd_syn_seccom\">secondary structure composition <\/A><\/LI>\n" 
#	    if (defined $rdb{"1","PHL"} || defined $rdb{"1","PHEL"});
#    print $fhoutHtml 
#	"\t <LI><A HREF=\"#phd_syn_acccom\">surface/core ratio <\/A><\/LI>\n" 
#	    if (defined $rdb{"acc","b"});
#    print $fhoutHtml 
#	"\t <LI><A HREF=\"#phd_syn_htm\">   transmembrane helices <\/A><\/LI>\n" 
#	    if (defined $rdb{"header","NHTM_BEST"});
#    print $fhoutHtml 
#	"\t <\/OL>\n";

#    print $fhoutHtml 
#	"<LI><A HREF=\"#phd_hdr\">HEADER information   <\/A><\/LI>\n",
#	"\t <OL>\n",
#	"\t <LI><A HREF=\"#phd_hdr_prot\"> about protein <\/A><\/LI>\n",
#	"\t <LI><A HREF=\"#phd_hdr_ali\">  about alignment <\/A><\/LI>\n",
#	"\t <LI><A HREF=\"#phd_hdr_res\">  residue composition <\/A><\/LI>\n";

#    print $fhoutHtml 
#	"\t <LI><A HREF=\"#phd_hdr_tech\"> about method used <\/A><\/LI>\n",
#	"\t <LI><A HREF=\"#phd_hdr_quote\">please quote<\/A><\/LI>\n",
#	"\t <LI><A HREF=\"#phd_hdr_copy\"> copyright & contact<\/A><\/LI>\n",
#	"\t <LI><A HREF=\"#phd_hdr_abbr\"> abbreviations used <\/A><\/LI>\n",
#	"\t <\/OL>\n",
#	"<LI><A HREF=\"#phd_body\">BODY with predictions <\/A><BR>\n",
#	"    <I>Different levels of data:</I><\/LI>\n",
#	"\t <OL>\n";
#    print $fhoutHtml 
#	"\t <LI><A HREF=\"#phd_brief\"> PHD brief <\/A><\/LI>\n"  if ($Lbrief);
#    print $fhoutHtml 
#	"\t <LI><A HREF=\"#phd_normal\">PHD normal<\/A><\/LI>\n"  if ($Lnormal);
#    print $fhoutHtml 
#	"\t <LI><A HREF=\"#phd_detail\">PHD detail<\/A><\/LI>\n"  if ($Ldetail);
#    print $fhoutHtml 
#	"\t <\/OL>\n",
#	"<\/UL>\n",
#	"<\/DIV>\n",
#	"<P><BR><P>\n","\n",
#	"<!-- END TOC -->\n",
#	"<!-- -------------------------------------------------------------------------------- -->\n",
#	"\n",
#	"<P><BR>\n";
				# --------------------------------------------------
				# summary for protein
				# --------------------------------------------------
#    print $fhoutHtml 
#	"<BR><HR><P><\/P><BR>\n",
#	"<!-- -------------------------------------------------------------------------------- -->\n",
#	"<!-- BEG SUMMARY -->\n",
#	"<P><\/P>\n",
#	"<H3><A NAME=\"phd_syn\">SYNOPSIS of prediction<\/A><\/H3>\n",
#	"<P><\/P>\n";
				# ------------------------------
				# summary:sec
    if (defined $rdb{"sec","class"}) {
	print $fhoutHtml 
	    "<UL><LI><STRONG><A NAME=\"phd_syn_class\">PHDsec summary<\/A><\/STRONG>\n";
	$rdb{"sec","class","txt"}=~s/\n/\n<LI>/g;
	$rdb{"sec","class","txt"}=~s/<LI>$//g;
	print $fhoutHtml 
	    "overall your protein can be classified as:<BR>",
	    "<STRONG>",$rdb{"sec","class"},"<\/STRONG>\n",
	    " given the following classes:<BR>\n",
	    "<UL><LI>",$rdb{"sec","class","txt"},"<\/UL>\n"; 
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<P><BR><P>\n";}
				# ------------------------------
				# write sec str composition
    if (defined $rdb{"1","PHL"} || defined $rdb{"1","PHEL"}) {
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG><A NAME=\"phd_syn_seccom\">Predicted secondary structure composition ",
	    "for your protein:<\/A></STRONG>\n",
	    "<TABLE BORDER=1 CELLPADDING=2>\n",
	    "<TR>";
	@tmp1=("sec str type");
	@tmp2=("\% in protein");
	foreach $sym (split(//,"HEL")) {
	    next if (! defined $rdb{"sec",$sym});
	    push(@tmp1,"\t".$sym);
	    push(@tmp2,"\t".$rdb{"sec",$sym});}
	foreach $tmp (@tmp1){
	    print $fhoutHtml 
		"<TD>$tmp<\/TD>";}
	print $fhoutHtml 
	    "<\/TR>\n";
	foreach $tmp (@tmp2){
	    print $fhoutHtml 
		"<TD>$tmp<\/TD>";}
	print $fhoutHtml 
	    "<\/TR>\n",
	    "<\/TABLE>\n",
	    "<\/LI><\/UL><P><BR>\n";}
    print $fhoutHtml 
	"\n";
				# ------------------------------
				# summary:htm
    if (defined $rdb{"header","NHTM_BEST"}) {
	print $fhoutHtml 
	    "<h3><A NAME=\"phd_syn_htm\">PHDhtm summary<\/A><\/h3>\n";

	$nbest=$rdb{"header","NHTM_BEST"};    $nbest=~s/(\d+).*$/$1/g;
	$n2nd= $rdb{"header","NHTM_2ND_BEST"};$n2nd=~s/(\d+).*$/$1/g;
	$txtBest= "helix"; $txtBest= "helices" if ($nbest > 1);
	$txt2nd=  "helix"; $txt2nd=  "helices" if ($n2nd > 1);
	
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG>NHTM=$nbest<\/STRONG><BR>\n",
	        "PHDhtm detected <STRONG>$nbest<\/STRONG> membrane ".
		"$txtBest for the <STRONG>best<\/STRONG> model.".
		    "The second best model contained $n2nd $txt2nd.\n";
	$top=           $rdb{"header","HTMTOP_PRD"}; $top=~s/(\S+).*$/$1/g;
	$rel_best_dproj=$rdb{"header","REL_BEST_DPROJ"};$rel_best_dproj=~s/^(\S+).*$/$1/g;
	$rel_best=      $rdb{"header","REL_BEST"};$rel_best=~s/^(\S+).*$/$1/g;
	$htmtop_rid=    $rdb{"header","HTMTOP_RID"};$htmtop_rid=~s/^(\S+).*$/$1/g;
	$htmtop_rip=    $rdb{"header","HTMTOP_RIP"};$htmtop_rip=~s/^(\S+).*$/$1/g;
	print $fhoutHtml 
	    "<LI><STRONG>TOP=$top<\/STRONG><BR>\n",
	         "PHDhtm predicted the topology ",$top,", i.e. the first loop region is $top",
	      " (Note: this prediction may be problematic when the sequence you sent ",
	      "starts or ends with a region predicted in a membrane helix!)\n",
	    "<LI>Reliability of best model=",$rel_best_dproj," (0 is low, 9 is high)\n",
	    "<LI>Zscore for best model=",$rel_best,"\n",
	    "<LI>Difference of positive charges (K+R) inside - outside=",
	      $htmtop_rid," (the higher the value, the more reliable)\n",
	    "<LI>Reliability of topology prediction =",
	      $htmtop_rip," (0 is low, 9 is high)\n";
				# strength of single HTMs
	if (defined $rdb{"header","MODEL_DAT"}) {
	    @tmp=split(/\n/,$rdb{"header","MODEL_DAT"});
	    print $fhoutHtml 
		"<LI>Details of the strength of each predicted membrane helix:<BR>\n",
		"(sorted by strength, strongest first)<BR>\n";
	    
	    print $fhoutHtml
		"<TABLE>\n",
		"<TR><TD>N HTM<TD>Total score<TD>Best HTM<TD>c-N<\/TR>\n";
	    foreach $tmp (@tmp) {
		$tmp=~s/\n+//g;@tmp2=split(/,/,$tmp);
		print $fhoutHtml "<TR>";
		foreach $tmp2 (@tmp2) {
		    print $fhoutHtml "<TD>$tmp2"; }
		print $fhoutHtml "<\/TR>\n"; }
	    print $fhoutHtml "<\/TABLE>\n"; }
				# table with regions
	$tmp="";
	foreach $it (1..$rdb{"NROWS"}){
	    $tmp.=$rdb{$it,"PiMo"};}
				# get segments
				# out GLOBAL: %segment
	($Lok,$msg)=
	    &getSegment($tmp);  return(&errSbrMsg("failed to get segment for $tmp",
						  $sbrName3)) if (! $Lok);

	print $fhoutHtml
	    "Overview over transmembrane segments:<BR><BR>\n",
	    "<TABLE>\n",
	    "<TR><TD>Positions<TD>Segments<TD>Explain<\/TR>\n";
	foreach $ctSegment (1..$segment{"NROWS"}){
	    $sym=$segment{$ctSegment};
	    $txt="?=error";
	    $txt=$transDescrShort{$sym} if (defined $transDescrShort{$sym});
	    print $fhoutHtml
		"<TR><TD>",
		sprintf("%5d",$segment{"beg",$ctSegment}),"-",
		sprintf("%5d",$segment{"end",$ctSegment}),
		"<TD>",$segment{$ctSegment},$segment{"seg",$ctSegment},
		"<TD>$txt ",$segment{"seg",$ctSegment},
		"<\/TR>\n"; }
	print $fhoutHtml
	    "<\/TABLE>\n";
	    
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<BR>\n";}
		
	
				# ------------------------------
				# solvent acc composition
    if (defined $rdb{"1","PREL"}) {
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG><A NAME=\"phd_syn_acccom\">Predicted solvent accessibility composition ",
	    "(core/surface ratio) for your protein:<\/A></STRONG><BR>\n",
	    "\t Classes used:\n",
	    "\t <UL>\n",
	    "\t <LI>e: residues exposed with more than ".$par{"thresh2acc"}."% of their surface<\/LI>\n",
	    "\t <LI>b: all other residues.<\/LI>\n",
	    "\t <\/UL>\n";
	print $fhoutHtml 
	    "<LI>The subsets are for the fractions of residues predicted at higher levels ",
	    "of reliability, i.e. accuracy. This set covers ".int($rdb{"acc","sub"}),
	    "% of all residues.<\/LI>\n"
		if (defined $rdb{"acc","sub"} && ($rdb{"acc","sub"}>30));
	print $fhoutHtml 
	    "<TABLE BORDER=1 CELLPADDING=2>\n";
				# all residue surface/core
	@tmp1=("accessib type");
	@tmp2=("\% in protein");
	foreach $sym (split(//,"be")) {
	    next if (! defined $rdb{"acc",$sym});
	    push(@tmp1,"\t".$sym);
	    push(@tmp2,"\t".$rdb{"acc",$sym});}
				# subset statistics (higher reliability)
	if (defined $rdb{"acc","sub"} && $rdb{"acc","sub"}>30){
	    push(@tmp1,"\&nbsp\;","sub...:","accessib type");
	    push(@tmp2,"\&nbsp\;","...set:","\% in subset");
	    foreach $sym (split(//,"be")) {
		next if (! defined $rdb{"acc",$sym."sub"});
		push(@tmp1,"\t".$sym);
		push(@tmp2,"\t".$rdb{"acc",$sym."sub"});}}

	print $fhoutHtml 
	    "<TR>\n";
	foreach $tmp (@tmp1){
	    print $fhoutHtml 
		"<TD>$tmp<\/TD>";}
	print $fhoutHtml 
	    "<\/TR>\n",
	    "<TR>\n";
	foreach $tmp (@tmp2){
	    print $fhoutHtml 
		"<TD>$tmp<\/TD>";}
	print $fhoutHtml 
	    "<\/TR>\n";
	print $fhoutHtml 
	    "<\/TABLE>\n",
	    "<\/LI><\/UL><P><BR>\n";}
    print $fhoutHtml 
	"\n";
    print $fhoutHtml 
	"<!-- END SUMMARY -->\n",
	"<!-- -------------------------------------------------------------------------------- -->\n",
	"<BR>\n";
	
				# --------------------------------------------------
				# HEADER= general information
				# --------------------------------------------------
#    print $fhoutHtml 
#	"<BR><HR><P><\/P><BR>\n",
#	"<!-- -------------------------------------------------------------------------------- -->\n",
#	"<!-- BEG HEADER -->\n",
#	"<P><\/P>\n",
#	"<H3><A NAME=\"phd_hdr\">HEADER information<\/A><\/H3>\n",
#	"<P><\/P>\n";

				# ------------------------------
				# protein
    print $fhoutHtml 
#	"<UL>\n",
#	"<LI><STRONG><A NAME=\"phd_hdr_prot\">About your protein:<\/A></STRONG>\n",
#	"<TABLE BORDER=1 CELLPADDING=2>\n";
#    foreach $kwd (@kwdHead){
#	next if ($kwd !~/^prot/);
#	next if (! defined $rdb{$kwd});
#	$tmp_taken{$kwd}=1;
#	print $fhoutHtml 
#	    "<TR><TD><A HREF=\"\#".$kwd."\">".$kwd."<\/A><\/TD><TD>",$rdb{$kwd},"<\/TD><\/TR>\n";
#    }
#    print $fhoutHtml
#	"<\/TABLE>\n",
#	"<\/UL><BR>\n";
				# ------------------------------
				# alignment
 #   print $fhoutHtml 
#	"<UL>\n",
#	"<LI><STRONG><A NAME=\"phd_hdr_ali\">About the alignment used:<\/A></STRONG>\n",
#	"<TABLE BORDER=1 CELLPADDING=2>\n";
    undef %tmp_taken;

#    foreach $kwd (@kwdHead){
#	next if ($kwd !~/^ali/);
#	next if (! defined $rdb{$kwd});
#	$tmp_taken{$kwd}=1;
#	print $fhoutHtml 
#	    "<TR><TD><A HREF=\"\#".$kwd."\">".$kwd."<\/A><\/TD><TD>",$rdb{$kwd},"<\/TD><\/TR>\n";
#    }
#    print $fhoutHtml
#	"<\/TABLE>\n",
#	"<\/UL><P>\n";
				# ------------------------------
				# write residue composition
    print $fhoutHtml 
#	"<UL>\n",
	"<h3><A NAME=\"phd_hdr_res\">Residue composition for your protein:<\/A></h3>\n",
	"<TABLE CELLPADDING=2>\n",
	"<TR>";
    $ct=0;
    foreach $aa (split(//,"ACDEFGHIKLMNPQRSTVWY")) {
	++$ct;
	if ($ct > 5) {$ct=1;
		      print $fhoutHtml "<\/TR>\n<TR>";}
	printf $fhoutHtml "%-s %3.1f","<TD>%"."$aa:",$rdb{$aa,"seq"};}
    print $fhoutHtml 
	"<\/TABLE>\n";
#	"<\/UL><P>\n";
				# ------------------------------
				# technical information
#    print $fhoutHtml 
#	"<UL>\n",
#	"<LI><STRONG><A NAME=\"phd_hdr_tech\">About the PHD methods used:<\/A></STRONG>\n",
#	"<TABLE BORDER=1 CELLPADDING=2>\n";
#    foreach $kwd (@kwdHead){
#	next if ($kwd !~/^phd/);
#	next if (! defined $rdb{$kwd});
#	$tmp_taken{$kwd}=1;
#	print $fhoutHtml 
#	    "<TR><TD><A HREF=\"\#".$kwd."\">".$kwd."<\/A><\/TD><TD>",$rdb{$kwd},"<\/TD><\/TR>\n";
#    }
#    print $fhoutHtml
#	"<\/TABLE>\n",
#	"<\/UL><P>\n";
				# ------------------------------
				# please quote
#    print $fhoutHtml 
#	"<UL>\n",
#	"<LI><STRONG><A NAME=\"phd_hdr_quote\">Please quote:<\/A></STRONG>\n";
#    print $fhoutHtml 
#	"\t <OL>\n",
#	"\t <LI> PHD: ".$par{"txt","quote","phd1994"}."<\/LI>\n";

#    print $fhoutHtml 
#	"\t <LI> PHDsec:\n".$par{"txt","quote","phdsec"}."<\/LI>\n"
#	    if ($par{"optPhd"}=~/^(3|both|sec)/);
#    print $fhoutHtml 
#	"\t <LI> PHDacc:\n".$par{"txt","quote","phdacc"}."<\/LI>\n"
#	    if ($par{"optPhd"}=~/^(3|both|acc)/);
#    print $fhoutHtml 
#	"\t <LI> PHDhtm:\n".$par{"txt","quote","phdhtm"}."<\/LI>\n"
#	    if ($par{"optPhd"}=~/^(3|htm)/);
#    print $fhoutHtml 
#	"\t <\/OL>\n",
#	"<\/UL><P>\n";
				# ------------------------------
				# copyright
#    print $fhoutHtml 
#	"<UL>\n",
#	"<LI><STRONG><A NAME=\"phd_hdr_copy\">Copyright \&amp\; Contact:<\/A></STRONG><BR>\n",
#	"\t <UL>\n",
#	"\t <LI> ".$par{"txt","copyright"}."<\/LI>\n",
#	"\t <LI> Email: <A HREF=\"".$par{"txt","contactEmail"}."\">",
#	    $par{"txt","contactEmail"}."<\/A><\/LI>\n",
#	"\t <LI> WWW: <A HREF=\"".$par{"txt","contactWeb"}."\">",
#	    $par{"txt","contactWeb"}."<\/A><\/LI>\n",
#	"\t <LI> Fax: ".$par{"txt","contactFax"}."<\/LI>\n",
#	"\t <\/UL>\n",
#	"<\/UL><P>\n";
	
				# ------------------------------
				# syntax style:
				#      kwd : explanation
				# ------------------------------
#    print $fhoutHtml 
#	"<P><BR><P>\n",
#	"<UL>\n",
#	"<LI><STRONG><A NAME=\"phd_hdr_abbr\">ABBREVIATIONS used:<\/A></STRONG>\n",
#	"<TABLE BORDER=1 CELLPADDING=2>\n";
#				# (1) data keywords
#    foreach $kwd (@kwdBody) {
#	next if (! defined $rdb{"1",$kwd});
#	$tmp=$transDescr{$kwd}; $tmp=~s/\n$//; $tmp=~s/\n\n+/\n/g; $tmp=~s/\n/<BR>/g;
#	$tmp_taken{$kwd}=0;
#	print $fhoutHtml
#	    "<TR VALIGN=TOP>",
#	    "<TD><A NAME=\"$kwd\">",$transAbbr{$kwd},"<\/A>: <\/TD>",
#	    "<TD>$tmp<\/TD><\/TR>\n";
				# subset after REL
#	next if ($kwd !~ /RI/);
#	if    ($kwd eq "RI_S") { $kwd2="SUBsec"; }
#	elsif ($kwd eq "RI_A") { $kwd2="SUBacc"; }
#	elsif ($kwd eq "RI_M") { $kwd2="SUBhtm"; }
#	$abbr= $transAbbr{$kwd2};
#	$descr=$transDescr{$kwd2}; $descr=~s/\n$//; $descr=~s/\n\n+/\n/g; $descr=~s/\n/<BR>/g;
#	$tmp_taken{$abbr}=0;
#	print $fhoutHtml
#	    "<TR VALIGN=TOP>",
#	    "<TD><A NAME=\"$abbr\">",$abbr,"<\/A>: <\/TD>",
#	    "<TD>$descr<\/TD><\/TR>\n";
				# finish with empty line
#	print $fhoutHtml 
#	    "<TR><TD> <\/TD><TD> <\/TD><\/TR>\n";
#    } 
				# (2) header asf
 #   print $fhoutHtml
#	"<TR><TD> <\/TD><TD> <\/TD><\/TR>\n";
#    foreach $kwd (@kwdHead){
#	next if (! defined $kwd || $kwd=~/^\s*$/);
#	if ($kwd=~/phd_skip/){
#	    print $fhoutHtml
#		"<TR><TD><A NAME=\"".$kwd."\">",$kwd,"<\/A>: <\/TD>",
#		"<TD>".$par{"notation",$kwd}."<\/TD><\/TR>\n";
#	    next;}
#	next if (! defined $par{"notation",$kwd});
#	next if (! defined $tmp_taken{$kwd} || ! $tmp_taken{$kwd});
#	$notation=$par{"notation",$kwd};
#	$notation=~s/\n/<BR>/g;	# replace newlines
#	print $fhoutHtml
#	    "<TR><TD><A NAME=\"".$kwd."\">",$kwd,"<\/A>: <\/TD>",
#	    "<TD>".$notation."<\/TD><\/TR>\n";
#    }

#    print $fhoutHtml 
#	"<\/TABLE>\n",
#	"<\/LI><\/UL>",
#	"\n";

#    print $fhoutHtml 
#	"<!-- END HEADER -->\n",
#	"<!-- -------------------------------------------------------------------------------- -->\n";
	
    print $fhoutHtml 
#	"<P><BR><P>\n",
#	"<HR>\n",
#	"<P><BR><P>\n",
#	"<!-- -------------------------------------------------------------------------------- -->\n",
#	"<!-- BEG BODY -->\n",
#	"<P><\/P>\n",
#	"<H3><A NAME=\"phd_body\">BODY with predictions<\/A><\/H3>\n",
#	"<P><\/P>\n";
	

    undef %segment;		# slim-is-in
    return(1,"ok $sbrName3");
}				# end of convPhd2Html_wrtBodyHdr

#===============================================================================
sub htmlWrtHead {
    local($fhoutLoc,$titleLoc,$txtLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlWrtHead                 writes header of HTML file
#       in:                     $fhoutLoc=    file handle to write
#       in:                     $titleLoc=    title for file
#       in:                     $txtLoc=      optional text (e.g. styles asf)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlWrtHead";
				# check arguments
    return(&errSbr("not def fhoutLoc!"))     if (! defined $fhoutLoc);
    return(&errSbr("not def titleLoc!"))     if (! defined $titleLoc);
    $txtLoc=0                                if (! defined $txtLoc);
#    return(&errSbr("not def !"))          if (! defined $);

				# header tag
    print $fhoutLoc
	"<HTML>\n",
	"<HEAD>\n";
				# additional text (style asf)
    print $fhoutLoc
	$txtLoc,"\n"            if ($txtLoc);

				# title
    print $fhoutLoc
	"<TITLE>\n",
	"        $titleLoc\n",
	"<\/TITLE>\n",
	"<\/HEAD>\n";

    return(1,"ok $sbrName");
}				# end of htmlWrtHead

1;
