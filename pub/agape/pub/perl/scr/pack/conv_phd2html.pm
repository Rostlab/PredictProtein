# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	CUBIC (Columbia Univ)	http://www.embl-heidelberg.de/~rost/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Apr,    	1999	       #
#------------------------------------------------------------------------------#
#
# sbr needed by package:
#
# ------- : ------------------------------------------------------------------
# lib     : sbr
# ------- : ------------------------------------------------------------------
# scr.pl  : errSbr, errSbr, errSbrMsg, errScrMsg, myprt_npoints
# prot.pl : exposure_project_1digit,
# all5.pl : rdRdbAssociative_5, rdRdbAssociativeNum_5,
# file.pl : htmlWrtHead, open_file, 
# ------- : ------------------------------------------------------------------
#
#------------------------------------------------------------------------------#

package conv_phd2html;

#===============================================================================
sub convPhd2Html {
    local($fileInLoc,$fileOutLoc,$modeWrtLoc,$nresPerLineLoc,
	  $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,$fhErrSbr) = @_ ;
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
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

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
				# out GLOBAL: @kwdWant,$lenAbbr,%transSec2Htm
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
				# (1) read RDB file
				# ------------------------------
				# open file
    open($fhinLoc,"$fileInLoc") || 
	return(0,"*** ERROR $sbrName: fileInLoc=$fileInLoc, not opened");

    $rh_rdb=
        &rdRdbAssociative_5($fileInLoc,"all");

    return(&errSbr("failed rdRdb on $fileInLoc"))  if (! $rh_rdb || ! $rh_rdb->{"NROWS"});

				# ------------------------------
				# correct for PHDhtm single
    if (defined $rh_rdb->{"PiTo","1"} && ! defined $rh_rdb->{"PTN","1"}) {
	foreach $kwd ("PHL","OHL","PRHL","pH","pL","OtH","OtL") {
	    next if (! defined $changeNames{$kwd} || ! defined $rh_rdb->{$kwd,"1"});
	    $kwdNew=$changeNames{$kwd}; $tmp1="";$tmp2="";
	    foreach $it (1 .. $rh_rdb->{"NROWS"}) {
		$rh_rdb->{$kwdNew,$it}=$sym=$rh_rdb->{$kwd,$it};
		$tmp1.=$sym;
		undef $rh_rdb->{$kwd,$it};
		next if (! defined $transSec2Htm{$sym});
		$symNew=$transSec2Htm{$sym};
		$tmp2.=$symNew;
		$rh_rdb->{$kwdNew,$it}=$symNew;}}}
		

				# ------------------------------
				# (2) get some statistics asf
				# ------------------------------

    $titleLoc=$fileInLoc; $titleLoc=~s/^.*\/|\..*$//g;
    ($Lok,$msg,$rh_rdb)=
        &convPhd2Html_preProcess($rh_rdb);

    return(&errSbr("failed convPhd2Html_preProcess".
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
				# in GLOBAL: @kwdWant,
				#            %transDescr,%transAbbr
				#            $Lbrief,$Lnormal,$Ldetail
                                # ------------------------------
    ($Lok,$msg)=
	&convPhd2Html_wrtBodyHdr($titleLoc,$fhoutHtml,$rh_rdb);

    return(&errSbr("failed convPhd2Html_wrtBodyHdr".
                   $msg."\n"))  if (! $Lok);

				# ------------------------------
				# prepare write predictions
				# ------------------------------
    $nblocks=1;                 # number of blocks to write
    $nblocks=1+int($rh_rdb->{"NROWS"}/$nresPerLineLoc)
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
	$#kwdWantTmp=0;
	foreach $kwd (@kwdWant) {
	    next if ($kwd=~/^[OP](REL|RTN|RHL)|^p[HELTN]/);
	    push(@kwdWantTmp,$kwd); }
	print $fhoutHtml "<STRONG><A NAME=\"phd_brief\">PHD results (brief)<\/A><\/STRONG><P>\n";
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"brief",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      $rh_rdb,\%css_phd,\@kwdWantTmp);
	print $fhoutHtml "<P><BR><R><\/HR>\n"; }

				# ------------------------------
				# normal 
				# ------------------------------
    if ($Lnormal) {
	print $fhoutHtml "<STRONG><A NAME=\"phd_normal\">PHD results (normal)<\/A><\/STRONG><P>\n";
	$#kwdWantTmp=0;
	foreach $kwd (@kwdWant) {
	    next if ($kwd=~/^[OP](REL)|^p[HELTN]/);
	    push(@kwdWantTmp,$kwd); }
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"normal",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      $rh_rdb,\%css_phd,\@kwdWantTmp);
	print $fhoutHtml "<P><BR><R><\/HR>\n";}

				# ------------------------------
				# full details
				# ------------------------------
    if ($Ldetail) {
	print $fhoutHtml "<STRONG><A NAME=\"phd_detail\">PHD results (detail)<\/A><\/STRONG><P>\n";
	$#kwdWantTmp=0;
	foreach $kwd (@kwdWant) {
	    next if ($kwd=~/^RI/ || $kwd=~/^(PHEL|OHEL|Obie|PRTN|OTN|PTN)$/);
	    push(@kwdWantTmp,$kwd); }
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convPhd2Html_wrtOneLevel($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"normal",$nresPerLineLoc,
				      $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
				      $rh_rdb,\%css_phd,\@kwdWantTmp);
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
    @kwdWant=
	(
	 "AA",
	 "OHEL","PHEL","RI_S",               "pH","pE","pL",
	 "Obie","Pbie","RI_A",               "OREL","PREL",
	 "OTN", "PTN", "PRTN","PiTo","RI_H", "pT","pN",
#	 "","","","",
	 );
				# for HTM : header
    @kwdWantHdr=
	("NHTM_BEST","NHTM_2ND_BEST",
	 "REL_BEST","REL_BEST_DIFF", "REL_BEST_DPROJ",
	 "MODEL","MODEL_DAT",
	 "HTMTOP_OBS","HTMTOP_PRD","HTMTOP_MODPRD","HTMTOP_RID","HTMTOP_RIP",
	 );

				# e.g. 'L' to ' ' in writing
    %transSym=
	('L',    " ",
	 'i',    " ",
	 'N',    " ",
	 );
				# translate PHDsec to PHDhtm
    %transSec2Htm=
	('H',    "T",
	 'E',    "N",
	 'L',    "N",
	 'T',    "T",
	 'N',    "N",
	 );
				# change names
    %changeNames=
	('OHL',  "OTN",
	 'PHL',  "PTN",
	 'PRHL', "PRTN",
	 'pH',   "pT",
	 'pL',   "pN",
	 'OtH',  "OtT",
	 'OtL',  "OtN",
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

	 'OTN',    "OBS_htm",
	 'PTN',    "PHD_htm",
	 'PRTN',   "PHDrhtm",
#	 'PFTN',   "PHDfhtm",
	 'PiTo',   "PiTohtm",
	 'RI_H',   "Rel_htm",
	 'SUBhtm', "SUB_htm",
	 'pT',     " pT_htm",
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
	 'OREL',   "observerd relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
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

	 'OTN',    "observed membrane helix: T=helical transmembrane region, blank=other (loop)",
	           
	         
	 'PTN',    "PHD predicted membrane helix: T=helical transmembrane region, blank=other (loop)".
	           "\n"."PHD = PHD: Profile network prediction HeiDelberg",
	 'PRTN',   "refined PHD prediction: T=helical transmembrane region, blank=other (loop)",
	 'PiTo',   "PHD prediction of membrane topology: T=helical transmembrane region, i=inside of membrane, o=outside of membrane",
	 'RI_H',   "reliability index for PHDhtm prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBhtm', "subset of the PHDhtm prediction, for all residues with an expected average accuracy > 98% (tables in header)\n".
	           "     NOTE: for this subset the following symbols are used:\n".
	           "  L: is loop (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubSecLoc\n",
	 'pT',     "'probability' for assigning transmembrane helix",
	 'pN',     "'probability' for assigning globular region",


	 );

    $lenAbbr=10;		# width of abbreviation at begin of each row
		
    return(1,"ok $sbrName2");
}				# end of convPhd2Html_ini

#===============================================================================
sub convPhd2Html_iniStyles {
#-------------------------------------------------------------------------------
#   convPhd2Html_iniStyles    sets styles for convPhd2Html
#       out GLOBAL:             %css_phd{kwd}=
#                                  OREL,PREL,p<HELTN>,<HELTN>,<HELTN>sub
#-------------------------------------------------------------------------------

    %css_phd=
	(
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
	 'htm-T',    "{color:purple}",
	 'htm-N',    "{color:olive}",

	 'htm-Tsub', "{background-color:purple;color:white}",
	 'htm-Nsub', "{background-color:olive;color:white}",

	 'htm-pT',   "{background-color:purple;color:white}",
	 'htm-pN',   "{background-color:olive;color:white}",

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
sub convPhd2Html_wrtOneLevel {
    local($nblocksLoc,$lenAbbrLoc,$fhoutHtml,$fileOutLoc,$modeLoc,
	  $nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
	  $rh_rdb,$rh_css_phd,$ra_kwdWantLoc)=@_;
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
#                                  OREL,PREL,p<HELTN>,<HELTN>,<HELTN>sub
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
    return(&errSbr("not def rh_rdb!",   $sbrName3))      if (! defined $rh_rdb->{'NROWS'});
    return(&errSbr("not def rh_css_phd!",$sbrName3))     if (! defined $rh_css_phd);
    return(&errSbr("not def $ra_kwdWantLoc!",$sbrName3)) if (! $ra_kwdWantLoc);

				# --------------------------------------------------
				# loop over all blocks
				#    i.e. residues 1-60 ..
				# --------------------------------------------------

    foreach $itBlock (1..$nblocksLoc) {
				# begin and end of current block
	$itBeg=1+($itBlock-1)*$nresPerLineLoc;
	$itEnd=1+$itBlock*$nresPerLineLoc;
				# correct
	$itEnd=$rh_rdb->{"NROWS"} if ($itEnd <=$itBeg); # note: case for nresPerLineLoc=0
	$itEnd=$rh_rdb->{"NROWS"} if ($itEnd > $rh_rdb->{"NROWS"});
				# first: counter
	$ncount=$nresPerLineLoc if ($nresPerLineLoc);
	$ncount=10+10*int((1+$itEnd-$itBeg)/10) if (! $nresPerLineLoc);
	$string=&myprt_npoints($ncount,$itEnd);
	$tmp=" " x $lenAbbrLoc;
	print $fhoutHtml "$tmp"," ",$string,"\n";

				# --------------------------------------------------
				# loop over all keywords
				#    i.e. all rows (AA,OHEL,PHEL)
				# --------------------------------------------------
	foreach $itKwd (1..$#{$ra_kwdWantLoc}) {
	    $kwd=$ra_kwdWantLoc->[$itKwd];
	    next if (! defined $rh_rdb->{$kwd,$itBeg});
				# all into one string
	    $string="";
				# ri
	    if    ($kwd eq "RI_S") { $relStrong=$riSubSecLoc; }
	    elsif ($kwd eq "RI_A") { $relStrong=$riSubAccLoc; }
	    elsif ($kwd eq "RI_H") { $relStrong=$riSubHtmLoc; }
				# probability
	    $#string=0
		if ($kwd=~/^p[HELTN]$/ || $kwd=~/^[OP]REL/);
	    
				# ------------------------------
				# loop over protein
				# ------------------------------
	    foreach $itRes ($itBeg .. $itEnd) {
		$sym=$rh_rdb->{$kwd,$itRes}; 
				# normalise relative acc to numbers 0-9
		$sym=&exposure_project_1digit($sym)
		    if ($kwd =~ /^[OP]REL/);
		
				# ------------------------------
				# probability PHDsec, PHDhtm
		if ($kwd=~/^p[HELTN]$/) {
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
				# HTM: from 'HL' -> 'TN'
		    $symPrt=$transSec2Htm{$sym} if ($kwd=~/^[OP](TN|RTN|FTN)/);
				# for brief RI =< |*>
		    if ($modeLoc eq "brief" && $kwd=~/^RI/) {
			$symPrt="*";
			$symPrt=" " if ($sym < $relStrong); }
				# which style
		    if    ($kwd=~/^[OP]HEL|^p[HEL]|RI_S/)  { 
			$kwdCss="sec-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](REL|bie)|^RI_A/)    { 
			$kwdCss="acc-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](TN|RTN|iTo)|^p[TN]|^RI_H/) { 
			$kwdCss="htm-".$symPrt  if ($symPrt!~/^[ \*]$/); }
				# 'L' -> ' '
		    $symPrt=$transSym{$sym} if (defined $transSym{$sym} && $kwd !~/^[OP]REL/
						&& $kwd ne "AA" && $kwd !~/PiTo/ 
						&& $symPrt ne " " && $symPrt ne "*");
						
			
		    if (! defined $kwdCss    || ! defined $rh_css_phd->{$kwdCss} 
			|| $kwd =~/^[OP]REL/ || $kwd eq "AA"
			|| $symPrt eq " "    || $symPrt eq "*" || $symPrt eq ".") {
			$string.=$symPrt; }
		    else {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."<\/FONT>"; } } }
#			$string.="<FONT CLASS=\"".$kwdCss."\">".$symPrt."<\/FONT>"; } } }
	    $abbr=$kwd;
	    $abbr=$transAbbr{$kwd} if (defined $transAbbr{$kwd});
	    $empty=" " x ($lenAbbrLoc-length($abbr));
	    $lenTotal=length($empty.$abbr);
				# link description of row to header
	    if ($fileOutLoc) {
		$abbr="<A HREF=\"$fileOutLoc#$kwd\">$abbr</A>$empty";}
	    else {
		$abbr="<A HREF=\"#$kwd\">$abbr</A>$empty";}

				# probability PHDsec
	    if ($kwd=~/^p[HELTN]$/) {
		if ($kwd=~/^p[HEL]$/) {
		    $kwdCss="sec-".$kwd; }
		elsif ($kwd=~/^p[TN]$/) {
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
		    print $fhoutHtml 
			$abbr,$string[$it2],sprintf("  %2.1f ",$tmp3),
			$abbr,"\n"; }
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
		    print $fhoutHtml 
			$abbr,$string[$it2],sprintf("  %3d%-s ",int($tmp3),"%"),
			$abbr,"\n"; }
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
		elsif ($kwd eq "RI_H") { 
		    $kwdTmp="PTN";  $kwdTmp2="SUBhtm"; $abbr=$transAbbr{"SUBhtm"};}

		$string="";
		foreach $itRes ($itBeg .. $itEnd) {
		    $sym=$rh_rdb->{$kwdTmp,$itRes}; 
		    $rel=$rh_rdb->{$kwd,$itRes}; 
		    if ($rel >= $relStrong) {
			$symPrt=$sym; 
				# HTM: from 'HL' -> 'TN'
			$symPrt=$transSec2Htm{$sym} if ($kwd=~/^RI_H/);}
		    else {
			$symPrt=$riSubSymLoc; }

		    if    ($kwd=~/^RI_S/) { $kwdCss="sec-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_A/) { $kwdCss="acc-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_H/) { $kwdCss="htm-".$symPrt."sub"; }

		    if (! defined $kwdCss || ! defined $rh_css_phd->{$kwdCss} || $symPrt eq " ") {
			$string.=$symPrt; }
		    else {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."<\/FONT>";}  
		}

		$empty=" " x ($lenAbbrLoc-length($abbr));
				# link description of row to header
		if ($fileOutLoc) {
		    $abbr="<A HREF=\"$fileOutLoc#$kwdTmp2\">$abbr</A> $empty"; }
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
    local($rh_rdb)=@_;
    local($sbrName3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_preProcess     compiles probabilites from network output
#                               and composition AND greps stuff from HEADER!
#       in:                     $rh_rdb{}= reference passed from reading RDB file
#       out:                    $rh_rdb{'p<HELTN>',$it}=   probability
#       out:                    $rh_rdb{'sec','<HELTN>'}=  secondary str composition
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
    return(&errSbr("not def rh_rdb!",   $sbrName3))    if (! defined $rh_rdb->{'NROWS'});

				# ------------------------------
				# compile membrane prob
				#      pT and pN normalised to 0-9
				#      pT + pN = 9
				# ------------------------------
    if (defined $rh_rdb->{"OtT","1"}) {
	foreach $itRes (1..$rh_rdb->{"NROWS"}) { 
	    $sum=$rh_rdb->{"OtT",$itRes}+$rh_rdb->{"OtN",$itRes};
	    $rh_rdb->{"pT",$itRes}=int(10*($rh_rdb->{"OtT",$itRes}/$sum));
	    $rh_rdb->{"pT",$itRes}=9 if ($rh_rdb->{"pT",$itRes} > 9);
	    $rh_rdb->{"pN",$itRes}=int(10*($rh_rdb->{"OtN",$itRes}/$sum)); 
	    $rh_rdb->{"pN",$itRes}=9 if ($rh_rdb->{"pN",$itRes} > 9);
	}}

				# ------------------------------
				# compile PHDsec prob
				#      pH, pE, pL normalised to 0-9
				#      pH + pE +pL = 9
				# ------------------------------
    if (! defined $rh_rdb->{"pH","1"} && defined $rh_rdb->{"OtH","1"}) {
	foreach $itRes (1..$rh_rdb->{"NROWS"}) { 
	    $sum=$rh_rdb->{"OtH",$itRes}+$rh_rdb->{"OtE",$itRes}+$rh_rdb->{"OtL",$itRes};
	    $rh_rdb->{"pH",$itRes}=int(10*($rh_rdb->{"OtH",$itRes}/$sum));
	    $rh_rdb->{"pH",$itRes}=9  if ($rh_rdb->{"pH",$itRes} > 9);
	    $rh_rdb->{"pE",$itRes}=int(10*($rh_rdb->{"OtE",$itRes}/$sum)); 
	    $rh_rdb->{"pE",$itRes}=9  if ($rh_rdb->{"pE",$itRes} > 9);
	    $rh_rdb->{"pL",$itRes}=int(10*($rh_rdb->{"OtL",$itRes}/$sum)); 
	    $rh_rdb->{"pL",$itRes}=9  if ($rh_rdb->{"pL",$itRes} > 9);
	} }
    
				# ------------------------------
				# compile residue composition
				# ------------------------------
    if (defined $rh_rdb->{"AA","1"}) {
	undef %tmp;
	foreach $itRes (1..$rh_rdb->{"NROWS"}) { 
	    $sym=$rh_rdb->{"AA",$itRes};
	    $tmp{$sym}=0        if (! defined $tmp{$sym});
	    ++$tmp{$sym}; }
				# set zero
	foreach $sym (split(//,"ACDEFGHIKLMNPQRSTVWY")) {
	    $rh_rdb->{"seq",$sym}=0; }
	
	if ($rh_rdb->{"NROWS"} > 0) {
	    foreach $sym (keys %tmp){
				# accuracy: 2 decimals, in percentage
		$rh_rdb->{"seq",$sym}=
		    sprintf("%6.2f",(100*$tmp{$sym}/$rh_rdb->{"NROWS"})) ; }}}

				# ------------------------------
				# compile sec str composition
				# ------------------------------
    if (defined $rh_rdb->{"PHEL","1"}) {
	undef %tmp;
	foreach $itRes (1..$rh_rdb->{"NROWS"}) { 
	    $sym=$rh_rdb->{"PHEL",$itRes};
	    $tmp{$sym}=0        if (! defined $tmp{$sym});
	    ++$tmp{$sym}; }
                                # set 0
        foreach $sym ("H","E","L","T","N") {
            $rh_rdb->{"sec",$sym}=0; }
                                # assign
	if ($rh_rdb->{"NROWS"} > 0) {
	    foreach $sym (keys %tmp){
				# accuracy: 2 decimals, in percentage
		$rh_rdb->{"sec",$sym}=
		    sprintf("%6.2f",(100*$tmp{$sym}/$rh_rdb->{"NROWS"})) ; }}
				# ------------------------------
				# assign SEC STR class
				# ------------------------------
        $description= "'all-alpha':   %H > 45% AND %E <  5%\n";
        $description.="'all-beta':    %H <  5% AND %E > 45%\n";
        $description.="'alpha-beta':  %H > 30% AND %E > 20%\n";
        $description.="'mixed':       all others\n";
        $rh_rdb->{"sec","class","txt"}=$description;
        if    ($rh_rdb->{"sec","H"} > 45 && $rh_rdb->{"sec","H"} <  5) {
            $rh_rdb->{"sec","class"}="all-alpha";}
        elsif ($rh_rdb->{"sec","H"} >  5 && $rh_rdb->{"sec","H"} > 45) {
            $rh_rdb->{"sec","class"}="all-beta";}
        elsif ($rh_rdb->{"sec","H"} > 30 && $rh_rdb->{"sec","H"} > 20) {
            $rh_rdb->{"sec","class"}="alpha-beta";}
        else {
            $rh_rdb->{"sec","class"}="mixed";}
    }
				# ------------------------------
				# HTM header
				# ------------------------------
    if ($#kwdWantHdr > 0 && defined $rh_rdb->{"PiTo","1"}) {
	@tmp=split(/\#/,$rh_rdb->{"header"});
	undef %tmp;
	foreach $tmpHdr (@tmp) {
	    foreach $kwd (@kwdWantHdr) {
		next if ($tmpHdr !~ /$kwd[\s\t:]/);
		$tmp=$tmpHdr;
		$tmp=~s/^.*$kwd[\s\t:]+(.+)$/$1/g;
		$tmp=~s/^\s*|[\s\n]*$//g;
		$tmp{$kwd}.="\n".$tmp if (defined $tmp{$kwd}); 
		$tmp{$kwd}=$tmp       if (! defined $tmp{$kwd});
		last; }}
	foreach $kwd (@kwdWantHdr) {
	    next if (! defined $tmp{$kwd});
	    $rh_rdb->{"header",$kwd}=$tmp{$kwd}; }}

    return(1,"ok $sbrName3",$rh_rdb);
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
#                                  OREL,PREL,p<HELTN>,<HELTN>,<HELTN>sub
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
	&open_file($fhoutHtml,">$fileOutLoc") || 
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
    foreach $kwd ("T","N") {
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n"; 
	$style.="FONT."."htm-".$kwd."sub".$rh_css_phd->{"htm-".$kwd."sub"}."\n"; 
	$style.="FONT."."htm-"."p".$kwd.$rh_css_phd->{"htm-"."p".$kwd}."\n"; }
    foreach $kwd ("i","o") {
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."htm-".$kwd.$rh_css_phd->{"htm-".$kwd}."\n";}
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
    local($titleLoc,$fhoutHtml,$rh_rdb)=@_;
    local($sbrName3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2Html_wrtBodyHdr     writes first part of HTML BODY (TOC, syntax)
#       in:                     $titleLoc=        to be used for HTML title
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $rh_rdb{}= reference passed from reading RDB file
#       in GLOBAL:              @kwdWant,%transDescr,%transAbbr
#       in GLOBAL:              $Lbrief,$Lnormal,$Ldetail
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."convPhd2Html_wrtBodyHdr";
				# check arguments
    return(&errSbr("not def titleLoc!",  $sbrName3)) if (! defined $titleLoc);
    return(&errSbr("not def fhoutHtml!", $sbrName3)) if (! defined $fhoutHtml);
    return(&errSbr("not def rh_rdb!",    $sbrName3)) if (! defined $rh_rdb->{'NROWS'});

				# ------------------------------
				# TOC asf
				# ------------------------------
    print $fhoutHtml "<BODY style=\"background:white\">\n"; # body tag
    print $fhoutHtml "<H1>PHD predictions for $titleLoc</H1>\n";
    print $fhoutHtml "\n";
    print $fhoutHtml "<I>Different levels of data:</I>\n";
    print $fhoutHtml "<OL>\n";
    print $fhoutHtml "<LI><A HREF=\"#phd_brief\"> PHD brief <\/A>\n"  if ($Lbrief);
    print $fhoutHtml "<LI><A HREF=\"#phd_normal\">PHD normal<\/A>\n"  if ($Lnormal);
    print $fhoutHtml "<LI><A HREF=\"#phd_detail\">PHD detail<\/A>\n"  if ($Ldetail);
    print $fhoutHtml "<\/OL>\n","<P><BR><P>\n","\n";
    print $fhoutHtml "<P><BR>\n";
				# ------------------------------
				# summary for protein (sec)
				# ------------------------------
    if (defined $rh_rdb->{"sec","class"}) {
	print $fhoutHtml 
	    "<UL><LI><STRONG>PHDsec summary<\/STRONG>\n";
	$rh_rdb->{"sec","class","txt"}=~s/\n/\n<LI>/g;
	print $fhoutHtml 
	    "overall your protein can be classified as:<BR>",
	    "<STRONG>",$rh_rdb->{"sec","class"},"<\/STRONG>\n",
	    " given the following classes:<BR>\n",
	    "<UL><LI>",$rh_rdb->{"sec","class","txt"},"<\/UL>\n"; 
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<P><BR><P>\n";}
	
				# ------------------------------
				# summary for protein (htm)
				# ------------------------------
    if (defined $rh_rdb->{"header","NHTM_BEST"}) {
	print $fhoutHtml 
	    "<UL><LI><STRONG>PHDhtm summary<\/STRONG>\n";

	$nbest=$rh_rdb->{"header","NHTM_BEST"};    $nbest=~s/(\d+).*$/$1/g;
	$n2nd= $rh_rdb->{"header","NHTM_2ND_BEST"};$n2nd=~s/(\d+).*$/$1/g;
	$txtBest= "helix"; $txtBest= "helices" if ($nbest > 1);
	$txt2nd=  "helix"; $txt2nd=  "helices" if ($n2nd > 1);
	
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG>NHTM=$nbest<\/STRONG><BR>\n",
	        "PHDhtm detected <STRONG>$nbest<\/STRONG> membrane ".
		"$txtBest for the <STRONG>best<\/STRONG> model.".
		    "The second best model contained $n2nd $txt2nd.\n";
	$top=           $rh_rdb->{"header","HTMTOP_PRD"}; $top=~s/(\S+).*$/$1/g;
	$rel_best_dproj=$rh_rdb->{"header","REL_BEST_DPROJ"};$rel_best_dproj=~s/^(\S+).*$/$1/g;
	$rel_best=      $rh_rdb->{"header","REL_BEST"};$rel_best=~s/^(\S+).*$/$1/g;
	$htmtop_rid=    $rh_rdb->{"header","HTMTOP_RID"};$htmtop_rid=~s/^(\S+).*$/$1/g;
	$htmtop_rip=    $rh_rdb->{"header","HTMTOP_RIP"};$htmtop_rip=~s/^(\S+).*$/$1/g;
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

	if (defined $rh_rdb->{"header","MODEL_DAT"}) {
	    @tmp=split(/\n/,$rh_rdb->{"header","MODEL_DAT"});
	    print $fhoutHtml 
		"<LI>Detail of the strength of each predicted membrane helix:<BR>\n";
	    print $fhoutHtml
		"<TABLE BORDER=1>\n";
	    foreach $tmp (@tmp) {
		$tmp=~s/\n+//g;@tmp2=split(/,/,$tmp);
		print $fhoutHtml "<TR>";
		foreach $tmp2 (@tmp2) {
		    print $fhoutHtml "<TD>$tmp2"; }
		print $fhoutHtml "<\/TR>\n"; }
	    print $fhoutHtml "<\/TABLE>\n"; }
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<\/UL>\n";
	print $fhoutHtml "<P><BR>\n";}
	
				# ------------------------------
				# write residue composition
    print $fhoutHtml 
	"<UL>\n",
	"<LI><STRONG>Residue composition for your protein:</STRONG>\n",
	"<TABLE BORDER=1 CELLPADDING=2>\n",
	"<TR>";
    $ct=0;
    foreach $aa (split(//,"ACDEFGHIKLMNPQRSTVWY")) {
	++$ct;
	if ($ct > 5) {$ct=1;
		      print $fhoutHtml "<\/TR>\n<TR>";}
	printf $fhoutHtml "%-s %3.1f","<TD>%$aa:",$rh_rdb->{"seq",$aa};}
    print $fhoutHtml 
	"<\/TABLE>\n",
	"<\/UL><P><BR>\n";
    
				# ------------------------------
				# write sec str composition
    if (defined $rh_rdb->{"PHL","1"} || defined $rh_rdb->{"PHEL","1"}) {
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG>Predicted secondary structure composition for your protein:</STRONG>\n",
	    "<TABLE BORDER=1 CELLPADDING=2>\n",
	    "<TR>";
	$ct=0;
	foreach $sym (split(//,"HEL")) {
	    next if (! defined $rh_rdb->{"sec",$sym});
	    printf $fhoutHtml "%-s %3.1f","<TD>%$sym:",$rh_rdb->{"sec",$sym};}
	print $fhoutHtml 
	    "<\/TR>\n",
	    "<\/TABLE>\n",
	    "<\/UL><P><BR>\n";}
    print $fhoutHtml "\n";
    
				# ------------------------------
				# syntax style:
				#      kwd : explanation
				# ------------------------------
    print $fhoutHtml "<P><BR><P>\n";
    print $fhoutHtml "<TABLE BORDER=1 CELLPADDING=2>\n";
    foreach $kwd (@kwdWant) {
	next if (! defined $rh_rdb->{$kwd,"1"});
	$tmp=$transDescr{$kwd}; $tmp=~s/\n$//; $tmp=~s/\n\n+/\n/g; $tmp=~s/\n/<BR>/g;
	print $fhoutHtml
	    "<TR VALIGN=TOP>",
	    "<TD><A NAME=\"$kwd\">",$transAbbr{$kwd},"<\/A>: <\/TD>",
	    "<TD>$tmp<\/TD><\/TR>\n";
				# subset after REL
	    if ($kwd=~/RI/) {
		if    ($kwd eq "RI_S") { 
		    $abbr=$transAbbr{"SUBsec"};}
		elsif ($kwd eq "RI_A") { 
		    $abbr=$transAbbr{"SUBacc"};}
		elsif ($kwd eq "RI_H") { 
		    $abbr=$transAbbr{"SUBhtm"};}
		print $fhoutHtml
		    "<TR VALIGN=TOP>",
		    "<TD><A NAME=\"$abbr\">",$abbr,"<\/A>: <\/TD>",
		    "<TD>$tmp<\/TD><\/TR>\n";
				# finish with empty line
		print $fhoutHtml "<TR><TD> <\/TD><TD> <\/TD><TD><\/TD><\/TR>\n";
	    } }
    print $fhoutHtml "<\/TABLE>\n";

    print $fhoutHtml "<P><BR><P>\n";
    print $fhoutHtml "<HR>\n";
    print $fhoutHtml "<P><BR><P>\n";

    return(1,"ok $sbrName3");
}				# end of convPhd2Html_wrtBodyHdr

1;
