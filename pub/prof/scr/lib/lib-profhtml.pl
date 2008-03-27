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
#    PERL library with routines related to converting PROF.rdb to HTML.         #
#    Note: entire thing exchangable with conv_prof2html.pl                      #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 

#===============================================================================
sub convProf2html {
    local($fileInRdbLoc,$fileInAliLoc,$fileOutLoc,$modeWrtLoc,$nresPerLineLoc,
	  $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html                convert PROFrdb to HTML
#                               
#       in:                     $fileInRdbLoc=    PROFrdb file
#       in:                     $fileInAliLoc=    HSSP file (or 0 -> no ali written)
#       in:                     $fileOutLoc=      HTML output file
#                               =0                -> STDOUT
#                               
#       in:                     $modeWrtLoc=      mode for job
#                                  html:all       write head,body
#                                  html:<head|body>
#                                  data:all       write brief,normal,detail
#                                  data:<brief|norm|detail>
#                                  e.g. 'data:brief,data:normal,html:body'
#                               
#                                  scroll         -> scrollable long line, rather than blocks written
#                               
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR1=$tmp."convProf2html";
    $fhinLoc="FHIN_"."convProf2html";$fhoutLoc="FHOUT_"."convProf2html";
				# check arguments
    return(&errSbr("not def fileInRdbLoc!",  $SBR1)) if (! defined $fileInRdbLoc);
    return(&errSbr("not def fileInAliLoc!",  $SBR1)) if (! defined $fileInAliLoc);
    return(&errSbr("not def fileOutLoc!",    $SBR1)) if (! defined $fileOutLoc);
    return(&errSbr("not def modeWrtLoc!",    $SBR1)) if (! defined $modeWrtLoc);
    return(&errSbr("not def nresPerLineLoc!",$SBR1)) if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!",   $SBR1)) if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",   $SBR1)) if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",   $SBR1)) if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",   $SBR1)) if (! defined $riSubSymLoc);

    return(&errSbr("no fileInRdb=$fileInRdbLoc!",$SBR1)) if ($fileInRdbLoc && ! -e $fileInRdbLoc);
    return(&errSbr("no fileInAli=$fileInAliLoc!",$SBR1)) if ($fileInAliLoc && ! -e $fileInAliLoc);

				# --------------------------------------------------
				# (0) ini names
				#     digest mode (CHANGES $modeWrtLoc !!!!)
				# 
				#     out GLOBAL: @kwdBody,$lenAbbr,%transSec2Htm
				#                 %transSym,%transAbbr,%transDescr
				#                 
				#                 $Lxyz 
				# --------------------------------------------------
    ($Lok,$msg)=
	&convProf2html_ini
	    ($nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc
	     );                 return(&errSbrMsg("failed on convProf2html_ini($nresPerLineLoc,".
						  "$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc)\n",
						  $msg,$SBR1)) if (! $Lok);

                                # ini HTML css_styles
				# out GLOBAL: %css_prof
    &convProf2html_iniStyles();

				# --------------------------------------------------
				# (1a) read RDB file OR: use
				#      GLOBAL IN/OUT %rdb
				#      GLOBAL IN/OUT %prot
				#      alternative (actually USED):
				#      data passed from lib-prof
				# --------------------------------------------------
    if ($fileInRdbLoc || $fileInAliLoc){
	($Lok,$msg)=
	    &convProf2html_rdinput
		($fileInRdbLoc,$fileInAliLoc
		 );             return(&errSbrMsg("failed rdb=$fileInRdbLoc, prot=$fileInAliLoc",
						  $msg,$SBR1)) if (! $Lok);}

				# alternative (actually USED for PROF):
				#    data passed from lib-prof

				# ------------------------------
				# assign mode
    if (! defined $par{"optProf"}){
	if    ($rdb{"1","PHEL"} && $rdb{"1","PREL"} && $rdb{"1","PiTo"}){
	    $par{"optProf"}="3"; }
	elsif ($rdb{"1","PHEL"} && $rdb{"1","PREL"}){
	    $par{"optProf"}="both"; }
	elsif ($rdb{"1","PHEL"}){
	    $par{"optProf"}="sec"; }
	elsif ($rdb{"1","PREL"}){
	    $par{"optProf"}="acc"; }
	elsif ($rdb{"1","PiTo"}){
	    $par{"optProf"}="htm"; } }

				# ------------------------------
				# (1b) correct column names
				#      effective for 
				#      --> PROFhtm
				#      --> 3
    ($Lok,$msg)=
	&convProf2html_correct
	    ();                 return(&errSbrMsg("failed correcting column names",
						  $msg,$SBR1)) if (! $Lok);

				# ------------------------------
				# (2) get some statistics asf
				# ------------------------------
    $titleLoc=$fileInRdbLoc; $titleLoc=~s/^.*\/|\..*$//g;
    $rdb{"prot_id"}=  "id_unk"     if (! defined $rdb{"prot_id"});
    $rdb{"prot_name"}="name_unk"   if (! defined $rdb{"prot_name"});

    $titleLoc=$rdb{"prot_id"}." ".$rdb{"prot_name"} if (! $titleLoc);
	
    ($Lok,$msg)=
        &convProf2html_preProcess
	    ();			return(&errSbrMsg("failed convProf2html_preProcess",
						  $msg,$SBR1))  if (! $Lok);

				# ------------------------------
				# (3) write HTML header
				# ------------------------------
    ($Lok,$msg)=
	&convProf2html_wrtHead
	    ($fileInRdbLoc,$titleLoc,$Lhead,$fhoutHtml,$fileOutLoc,\%css_prof
	     );			return(&errSbrMsg("failed convProf2html_wrtHead($fileInRdbLoc)",
						  $msg,$SBR1)) if (! $Lok);
                                # ------------------------------
                                # (4) write HTML body (header)
				# in GLOBAL: @kwdBody,
				#            %transDescr,%transAbbr
				#            $Lbrief,$Lnormal,$Ldetail
                                # ------------------------------
    ($Lok,$msg)=
	&convProf2html_wrtBodyHdr
	    ($titleLoc,$fhoutHtml
	     );                 return(&errSbrMsg("failed convProf2html_wrtBodyHdr",
						  $msg,$SBR1))  if (! $Lok);

				# ------------------------------
				# prepare to write predictions
				# ------------------------------
    $nblocks=1;                 # number of blocks to write
    $nblocks=1+int($rdb{"NROWS"}/$nresPerLineLoc)
	if ($nresPerLineLoc > 0);

				# no block, but long continuous line
    if ($Lscroll){
	$nblocks=1;
	$nresPerLineLoc=$rdb{"NROWS"};}
	
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
	    next if ($kwd=~/^[OP](REL|RTN|RHL|RMN)|^p[HELTMN]|^[OP]be/);
	    push(@kwdBodyTmp,$kwd); }
	print $fhoutHtml "<STRONG><A NAME=\"prof_brief\">PROF results (brief)</A></STRONG><P>\n";
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convProf2html_wrtOneLevel
		($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"brief",$nresPerLineLoc,
		 $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
		 \%css_prof,\@kwdBodyTmp
		 );		print "-*- WARN $SBR1: failed on brief\n",$msg,"\n" if (! $Lok);
	print $fhoutHtml "<P><BR><R></HR>\n"; 
    }

				# ------------------------------
				# normal 
				# ------------------------------
    if ($Lnormal) {
	print $fhoutHtml "<STRONG><A NAME=\"prof_normal\">PROF results (normal)</A></STRONG><P>\n";
	$#kwdBodyTmp=0;
	foreach $kwd (@kwdBody) {
	    next if ($kwd=~/^[OP](REL)|^p[HELTMN]|^[OP]be/);
	    push(@kwdBodyTmp,$kwd); }
				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convProf2html_wrtOneLevel
		($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,"normal",$nresPerLineLoc,
		 $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
		 \%css_prof,\@kwdBodyTmp
		 );		print "-*- WARN $SBR1: failed on normal\n",$msg,"\n" if (! $Lok);
	print $fhoutHtml "<P><BR><R></HR>\n";
    }

				# ------------------------------
				# full details
				# ------------------------------
    if ($Ldetail) {
	print $fhoutHtml "<STRONG><A NAME=\"prof_detail\">PROF results (detail)</A></STRONG><P>\n";
	$#kwdBodyTmp=0;
	foreach $kwd (@kwdBody) {
	    next if ($kwd=~/^RI/ || 
		     $kwd=~/^[OP](HEL|bie|be|MN)$/ ||
		     $kwd=~/^(PRMN|PiMo)$/);
	    next if ($Lis_htm_only && $kwd=~/^p[HETL]$/);
	    push(@kwdBodyTmp,$kwd); 
	}

				# in GLOBAL:  %transSym,%transAbbr,%transSec2Htm
	($Lok,$msg)=
	    &convProf2html_wrtOneLevel
		($nblocks,$lenAbbr,$fhoutHtml,$fileOutLoc,
		 "detail",$nresPerLineLoc,
		 $riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
		 \%css_prof,\@kwdBodyTmp
		 );		print "-*- WARN $SBR1: failed on detail\n",$msg,"\n" if (! $Lok);
	print $fhoutHtml "<P><BR><R></HR>\n"; 
    }
    print $fhoutHtml "</PRE>\n";

				# ------------------------------
				# (6) write HTML body: fin
				# ------------------------------

				# navigation TOP BOTTOM SUMMARY PREDICTION PredictProtein
    print $fhoutHtml
	"<A NAME=\"bottom\">",
	"<TABLE CELLPADDING=1 CELLSPACING=2 BORDER=1 WIDTH=100%>\n",
	"<TR VALIGN=TOP ALIGN=CENTER><TD VALIGN=TOP BGCOLOR=\"silver\" WIDTH=100%><STRONG>",
	"<FONT COLOR=\"white\">",
	"<A HREF=\"\#top\">     Top    </A> &nbsp\; - &nbsp\;",
	"<A HREF=\"\#prof_syn\"> Summary</A> &nbsp\; - &nbsp\;",
	"<A HREF=\"\#prof_body\">Details</A> &nbsp\; - &nbsp\;",
	"<A HREF=\"".$par{"url","pp"}."\">PredictProtein</A> ",
	"</FONT></STRONG></TD></TR>\n",
	"</TABLE>",
	"</A>\n";

    print $fhoutHtml 
	"</BODY>\n",
	"</HTML>\n";
    close($fhoutHtml)           if ($fhoutHtml ne "STDOUT");

    return(1,"ok $SBR1");
}				# end of convProf2html

#===============================================================================
sub convProf2html_ini {
    local($nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc)=@_;
    local($sbrName2,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html_ini                       
#                               
#       in:                     $nresPerLineLoc=  number of residues per line
#       in:                     $riSubSec=        if rel < this -> strong prediction
#       in:                     $riSubAcc=        if rel < this -> strong prediction
#       in:                     $riSubHtm=        if rel < this -> strong prediction
#       in:                     $riSubSymLoc=     symbol used to display less accurate regions
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2=$tmp."convProf2html_ini";
    $fhinLoc="FHIN_"."convProf2html_ini";$fhoutLoc="FHOUT_"."convProf2html_ini";
				# ------------------------------
				# check arguments
    return(&errSbr("not def nresPerLineLoc!",$sbrName2))     if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!",$sbrName2))        if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",$sbrName2))        if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",$sbrName2))        if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",$sbrName2))        if (! defined $riSubSymLoc);

				# ------------------------------
				# HTML file handle
    $fileOutLoc=0               if ($fileOutLoc eq "STDOUT");
    $fhoutHtml="FHOUT_HTML_convProf2html";
    $fhoutHtml="STDOUT"         if (! $fileOutLoc);

				# ------------------------------
				# digest mode
				# ------------------------------
    $Lbrief=$Lnormal=$Ldetail=
	$Lhead=$Lbody=$Lscroll=0;

				# what to write
    $modeWrtLoc.="data:all"     if ($modeWrtLoc!~/data/);
    $Lbrief=          1         if ($modeWrtLoc=~/data:(brief|all)/);
    $Lnormal=         1         if ($modeWrtLoc=~/data:(normal|all)/);
    $Ldetail=         1         if ($modeWrtLoc=~/data:(det|all)/);
    $Lscroll=         1         if ($modeWrtLoc=~/scroll/);
    $Lali=            1         if ($modeWrtLoc=~/ali/);

				# which part of HTML
    $modeWrtLoc.="html:all"     if ($modeWrtLoc!~/html/);
    $Lhead=           1         if ($modeWrtLoc=~/html:(head|all)/);
    $Lbody=           1         if ($modeWrtLoc=~/html:(body|all)/);
    

				# ------------------------------
				# columns to read
    @kwdBody=
	(
	 "AA",
	 "OHEL","PHEL",                          "RI_S",               "pH","pE","pL",
	 "Obe","Pbe","Obie","Pbie","OREL","PREL","RI_A",               
	 "OMN", "PMN",                           "RI_M","PRMN","PiMo", "pM","pN",
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
	 'i',    " ",
	 'N',    " ",
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
	 'PHEL',   "PROF_sec",
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
#	 'PFMN',   "PROFfhtm",
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
	           
	         
	 'PHEL',   "PROF predicted secondary structure: H=helix, E=extended (sheet), blank=other (loop)".
	           "\n"."PROF = PROF: Profile network prediction HeiDelberg",
	 'RI_S',   "reliability index for PROFsec prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBsec', "subset of the PROFsec prediction, for all residues with an expected average accuracy > 82% (tables in header)\n".
	           "     NOTE: for this subset the following symbols are used:\n".
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
	           "     NOTE: for this subset the following symbols are used:\n".
	           "  I: is intermediate (for which above ' ' is used)\n".
	           "  $riSubSymLoc: means that no prediction is made for this residue, as the reliability is:  Rel < $riSubAccLoc\n",

	 '', "",

	 'OMN',    "observed membrane helix: M=helical transmembrane region, blank=non-membrane",
	           
	         
	 'PMN',    "PROF predicted membrane helix: M=helical transmembrane region, blank=non-membrane".
	           "\n"."PROF = PROF: Profile network prediction HeiDelberg",
	 'PRMN',   "refined PROF prediction: M=helical transmembrane region, blank=non-membrane",
	 'PiMo',   "PROF prediction of membrane topology: T=helical transmembrane region, i=inside of membrane, o=outside of membrane",
	 'RI_M',   "reliability index for PROFhtm prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'RI_H',   "reliability index for PROFhtm prediction (0=low to 9=high)".
	           "\n"."Note: for the brief presentation strong predictions marked by '*'",
	 'SUBhtm', "subset of the PROFhtm prediction, for all residues with an expected average accuracy > 98% (tables in header)\n".
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
}				# end of convProf2html_ini

#===============================================================================
sub convProf2html_iniStyles {
#-------------------------------------------------------------------------------
#   convProf2html_iniStyles    sets styles for convProf2html
#       out GLOBAL:             %css_prof{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#-------------------------------------------------------------------------------

    %css_prof=
	(
				# residue charges
	 'res-K',    "{color:blue}",
	 'res-R',    "{color:blue}",
	 'res-D',    "{color:red}",
	 'res-E',    "{color:red}",
				# cysteine
	 'res-C',    "{color:black;font-weight:bold}",
				# glycine
	 'res-G',    "{color:#404040;font-weight:bold}",
				# polar
#	 'res-S',    "{color:gray}",
#	 'res-T',    "{color:gray}",
	 'res-Y',    "{color:#FF00FF}",
#	 'res-N',    "{color:gray}",
#	 'res-Q',    "{color:gray}",
				# binding
	 'res-H',    "{color:fuchsia}",
	 'res-W',    "{color:fuchsia}",
				# hydrophobicity
	 'res-A',    "{color:green}",
	 'res-V',    "{color:green}",
	 'res-I',    "{color:green}",
	 'res-L',    "{color:green}",
	 'res-F',    "{color:green}",

	 'res-M',    "{color:#804080}",
	 'res-P',    "{color:olive}",

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

	 'htm-Msub', "{background-color:purple;color:white}",
	 'htm-Nsub', "{background-color:olive;color:white}",

	 'htm-pM',   "{background-color:purple;color:white}",
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
}				# end of convProf2html_iniStyles

#===============================================================================
sub convProf2html_correct {
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html_correct       correct column names for old PROF stuff
#                               effective for PROFhtm single AND '3'
#                               
#       in:                     $fileInRdbLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."convProf2html_correct";

				# ------------------------------
    $Lis_htm_only=0;		# correct for PROFhtm single
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
		$rdb{$it,$kwdNew}=$symNew;
	    }
	}}
				# ------------------------------
				# correct for PROFhtm all 3
    else {
	foreach $kwd ("OTN", "PTN", "PRTN","PRFTN","PR2TN","PiTo","RI_H", 
		      "OtT","pT","pN") {
	    next if (! defined $rdb{"1",$kwd});
	    $kwdNew=$kwd;
	    $kwdNew=$transData{$kwd}  if (defined $transData{$kwd});
	    next if ($kwd eq $kwdNew);
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

				# ------------------------------
				# correct PiMo 'T' -> 'M'
    if (defined $rdb{1,"PiMo"}){
	foreach $it (1 .. $rdb{"NROWS"}) {
	    $rdb{$it,"PiMo"}="M" if ($rdb{$it,"PiMo"} eq "T");
	}}

    return(1,"ok $SBR2");
}				# end of convProf2html_correct

#===============================================================================
sub convProf2html_preProcess {
#    local($rh_rdb)=@_;
    local($SBR3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html_preProcess     compiles probabilites from network output
#                               and composition AND greps stuff from HEADER!
#                               
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
    $SBR3=$tmp."convProf2html_preProcess";
				# check arguments
#    return(&errSbr("not def rh_rdb!",   $SBR3))    if (! defined $rdb{'NROWS'});

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
				# compile PROFsec prob
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
	foreach $kwd (@kwdHead) {
	    next if (! defined $rdb{$kwd});
	    $rdb{"header",$kwd}=$rdb{$kwd}; 
	}}

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

    return(1,"ok $SBR3");
}				# end of convProf2html_preProcess

#===============================================================================
sub convProf2html_rdinput {
    local($fileInRdbLoc,$fileInAliLoc) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html_rdinput        read all input files (RDB and may be HSSP)
#                               
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
    $SBR2=""."convProf2html_rdinput";
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
    if ($fileInRdbLoc){
	@tmp=(@kwdBody,@kwdBodyOld);
	($Lok,$msg)=
	    &rdRdb_here
		($fileInRdbLoc,\@kwdHead,\@tmp
		 );             return(&errSbrMsg("failed reading RDB=$fileInRdbLoc",
						  $msg,$SBR2)) if (! $Lok); 
    }
				# check again ...
    return(&errSbr("HASH_rdb not defined (file=$fileInRdbLoc)",$SBR2)) if (! $rdb{"NROWS"});
    
				# ------------------------------
				# read HSSP file
    if ($fileInAliLoc){
				# initialise pointers and keywords
	if (! defined %hsspRdProf_ini){
	    ($Lok,$msg)=
		&hsspRdProf_ini
		    ();		return(&errSbr("failed on hsspRdProf_iniHere\n".$msg,$SBR2)) if (! $Lok);}

				# get chain
	$id=$fileInRdbLoc;
	$id=~s/^.*\///g;
	$id=~s/\.rdb.*$//g;
	if ($id=~/_([0-9A-Z])$/){
	    $modeadd=",chn=".$1;}
	else {
	    $modeadd="";}
				# read HSSP
	($Lok,$msg)=
	    &hsspRdProf
		($fileInAliLoc,"nofill,noins,noprof".$modeadd,$par{"debug"}
		 );             return(&errSbrMsg("failed reading HSSP=$fileInAliLoc, mode=$modeadd",
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
	$rdb{"numres"}=$hssp{"numres"};
	$rdb{"numali"}=$hssp{"numali"};
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
		printf "xx %5d %-10s %-s\n",$itali,$rdb{"id",$itali},$tmp;}die;}
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
}				# end of convProf2html_rdinput

#===============================================================================
sub convProf2html_wrtAli {
    local($begLoc,$endLoc,$lenNumbersLoc,$rh_css_prof) = @_ ;
    local($SBR4,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html_wrtAli         write the alignment for one block
#                               
#       in:                     $begLoc:   first residue in current block
#       in:                     $endLoc:   last residue in current block
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR4=$tmp."convProf2html_wrtAli";

				# ------------------------------
				# check arguments
    return(&errSbr("not def begLoc!",$SBR4)) if (! defined $begLoc);
    return(&errSbr("not def endLoc!",$SBR4)) if (! defined $endLoc);

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# no ali found
    return(0,"missing alignment","")
	if (! defined $rdb{"numali"} || ! $rdb{"numali"});
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

				# begin with empty line
    $tmpwrt="\n";

				# now let it come ...
    foreach $itali (1..$rdb{"numali"}){
	$id= $rdb{"id",$itali};

	$tmp=    $id; $tmp=~s/^.*\|//g;	# purge db
	$idshort=substr($tmp,1,10);
	$idnodb= $id;
	$idnodb=~s/^.*\|//g;$idnodb=~tr/[A-Z]/[a-z]/;
	
				# link to SRS6
	$txt="<A HREF=\"".$par{"srsPath"}."[";
				# identify db
	$db=0;
	if    ($id =~ /(swiss|trembl|pdb)/)                           { $db=$1; }
	elsif ($idnodb =~ /[a-z0-9][a-z0-9]_[a-z0-9][a-z0-9]/)        { $db="swiss"; }
	elsif ($idnodb =~ /[1-9][a-z0-9][a-z0-9][a-z0-9]_?[a-z0-9]?/) { $db="pdb"; 
									$idnodb=substr($idnodb,1,4);}
				# identify SRS id
	$Lok=1;
	if    ($db =~ /swiss/)  { $txt.="swissprot-id:".$idnodb;}
	elsif ($db =~ /trembl/) { $txt.="sptrembl-id:". $idnodb;}
	elsif ($db =~ /pdb/)    { $txt.="pdb-id:".      $idnodb;}
	else                    { $Lok=0;}
	if ($Lok){
	    $txt.="]\">".$idnodb."</A>";}
	else{
	    $txt=$idnodb;}
				# now get sequences
	$string="";
	foreach $itres ($begLoc .. $endLoc) {
	    $res=$rdb{$id,$itres}; 
				# watch small caps in HSSP asf
	    $res2=$res; $res2=~tr/[a-z]/[A-Z]/;
	    $kwdCss="res-".$res2;
	    $res="<FONT CLASS=\"".$kwdCss."\">".$res."</FONT>"
		if (defined $rh_css_prof->{$kwdCss});
	    $string.=$res;
	}

	$tmpwrt.=$txt. " " x (10-length($idnodb)) . " ";
	$tmpwrt.=$string;
	$tmpwrt.=" " x ($lenNumbersLoc - (1+$endLoc-$begLoc));
	if ($modeLoc =~ /normal/ && $Lali){
	    $add= "";
	    $add.=" | <I>".sprintf("%4d",$rdb{"pide",$itali})."</I>";
	    $add.=" | <I>".sprintf("%4d",$rdb{"lali",$itali})."</I>";
	    $add.="";
	    $tmpwrt.=$add."\n";}
    }
				# add empty line
    $tmpwrt.="\n";

    return(1,"ok $SBR4",$tmpwrt);
}				# end of convProf2html_wrtAli

#===============================================================================
sub convProf2html_wrtBodyHdr {
    local($titleLoc,$fhoutHtml)=@_;
    local($SBR3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html_wrtBodyHdr     writes first part of HTML BODY (TOC, syntax)
#                               
#       in:                     $titleLoc=        to be used for HTML title
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $rh_rdb{}= reference passed from reading RDB file
#                               
#       in GLOBAL:              @kwdBody,%transDescr,%transAbbr
#       in GLOBAL:              $Lbrief,$Lnormal,$Ldetail
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."convProf2html_wrtBodyHdr";
				# check arguments
    return(&errSbr("not def titleLoc!",  $SBR3)) if (! defined $titleLoc);
    return(&errSbr("not def fhoutHtml!", $SBR3)) if (! defined $fhoutHtml);
#    return(&errSbr("not def rh_rdb!",    $SBR3)) if (! defined $rdb{'NROWS'});

    undef %tmp_taken;

    $prot_name="";
    $prot_nameTxt="";
    $prot_id=  $titleLoc;
    $prot_id=  $rdb{"prot_id"}   if (defined $rdb{"prot_id"});
    $prot_name=$rdb{"prot_name"} if (defined $rdb{"prot_name"});
    $prot_nameTxt="";
    $prot_nameTxt=$prot_name;
    $prot_nameTxt=~tr/[A-Z]/[a-z]/;
    $prot_nameTxt="(<I>".$prot_nameTxt."</I>)" 
	if (length($prot_nameTxt) > 3);

				# ------------------------------
				# TOC asf
				# ------------------------------

				# body tag
    print $fhoutHtml
	"<BODY style=\"background:white\">\n";
				# navigation TOP BOTTOM SUMMARY PREDICTION PredictProtein
    print $fhoutHtml
	"<A NAME=\"top\">",
	"<TABLE CELLPADDING=1 CELLSPACING=2 BORDER=1 WIDTH=100%>\n",
	"<TR VALIGN=TOP ALIGN=CENTER><TD VALIGN=TOP BGCOLOR=\"silver\" WIDTH=100%><STRONG>",
	"<FONT COLOR=\"#FFFFFF\">",
	"<A HREF=\"\#bottom\">   Bottom </A> &nbsp\; - &nbsp\;",
	"<A HREF=\"\#prof_syn\">  Summary</A> &nbsp\; - &nbsp\;",
	"<A HREF=\"\#prof_body\"> Details</A> &nbsp\; - &nbsp\;",
	"<A HREF=\"".$par{"url","pp"}."\">PredictProtein</A> ",
	"</FONT></STRONG></TD></TR>\n",
	"</TABLE>",
	"</A>\n";
				# title
    print $fhoutHtml
	"\n",
	"<TABLE CELLPADDING=1 CELLSPACING=2 BORDER=1 WIDTH=100%>\n",
	"<TR VALIGN=TOP ALIGN=CENTER><TD VALIGN=TOP BGCOLOR=\"#0000FF\" WIDTH=100%><STRONG>",
	"<FONT COLOR=\"#FFFFFF\">",
	"<BR><H1>PROF predictions for ",$prot_id," ".$prot_nameTxt."</H1>",
	"</A></FONT></STRONG></TD></TR>\n",
	"</TABLE>\n";

    print $fhoutHtml 
	"<!-- -------------------------------------------------------------------------------- -->\n",
	"<!-- BEG TOC -->\n",
	"<DIV class=\"subtoc\">\n",
	"<STRONG>Contents:</STRONG>\n",
	"<UL>\n";
    print $fhoutHtml 
	"<LI><A HREF=\"#prof_syn\">SYNOPSIS of prediction for ".$prot_id." ".$prot_nameTxt."</A></LI>\n",
	"\t <OL>\n";
    print $fhoutHtml 
	"\t <LI><A HREF=\"#prof_syn_class\"> secondary structure class</A></LI>\n"
	    if (defined $rdb{"sec","class"});
    print $fhoutHtml 
	"\t <LI><A HREF=\"#prof_syn_seccom\">secondary structure composition </A></LI>\n" 
	    if (defined $rdb{"1","PHL"} || defined $rdb{"1","PHEL"});
    print $fhoutHtml 
	"\t <LI><A HREF=\"#prof_syn_acccom\">surface/core ratio </A></LI>\n" 
	    if (defined $rdb{"acc","b"});
    print $fhoutHtml 
	"\t <LI><A HREF=\"#prof_syn_htm\">   transmembrane helices </A></LI>\n" 
	    if (defined $rdb{"header","NHTM_BEST"});
    print $fhoutHtml 
	"\t </OL>\n";

    print $fhoutHtml 
	"<LI><A HREF=\"#prof_hdr\">HEADER information   </A></LI>\n",
	"\t <OL>\n",
	"\t <LI><A HREF=\"#prof_hdr_prot\"> about protein </A></LI>\n",
	"\t <LI><A HREF=\"#prof_hdr_ali\">  about alignment </A></LI>\n",
	"\t <LI><A HREF=\"#prof_hdr_res\">  residue composition </A></LI>\n";

    print $fhoutHtml 
	"\t <LI><A HREF=\"#prof_hdr_tech\"> about method used </A></LI>\n",
	"\t <LI><A HREF=\"#prof_hdr_quote\">please quote</A></LI>\n",
	"\t <LI><A HREF=\"#prof_hdr_copy\"> copyright & contact</A></LI>\n",
	"\t <LI><A HREF=\"#prof_hdr_abbr\"> abbreviations used </A></LI>\n",
	"\t </OL>\n",
	"<LI><A HREF=\"#prof_body\">BODY with predictions </A><BR>\n",
	"    <I>Different levels of data:</I></LI>\n",
	"\t <OL>\n";
    print $fhoutHtml 
	"\t <LI><A HREF=\"#prof_brief\"> PROF brief </A></LI>\n"  if ($Lbrief);
    print $fhoutHtml 
	"\t <LI><A HREF=\"#prof_normal\">PROF normal</A></LI>\n"  if ($Lnormal);
    print $fhoutHtml 
	"\t <LI><A HREF=\"#prof_detail\">PROF detail</A></LI>\n"  if ($Ldetail);
    print $fhoutHtml 
	"\t </OL>\n",
	"</UL>\n",
	"</DIV>\n",
	"<!-- END TOC -->\n",
	"<!-- -------------------------------------------------------------------------------- -->\n",
	"<P><BR>\n";
				# --------------------------------------------------
				# summary for protein
				# --------------------------------------------------
    print $fhoutHtml 
	"<BR><HR><BR>\n",
	"<!-- -------------------------------------------------------------------------------- -->\n",
	"<!-- BEG SUMMARY -->\n",
	"<TABLE CELLPADDING=1 CELLSPACING=2 BORDER=1 WIDTH=100%>\n",
	"<TR VALIGN=TOP><TD VALIGN=TOP BGCOLOR=\"#0000FF\" WIDTH=100%><STRONG>",
	"<FONT COLOR=\"#FFFFFF\">",
	"<BR><H3><A NAME=\"prof_syn\">SYNOPSIS of prediction for ".$prot_id." ".$prot_nameTxt."</A></H3>\n",
	"</FONT></STRONG></TD></TR>\n",
	"</TABLE>\n";

				# ------------------------------
				# summary:sec
    if (defined $rdb{"sec","class"}) {
	print $fhoutHtml 
	    "<UL><LI><STRONG><A NAME=\"prof_syn_class\">PROFsec summary</A></STRONG>\n";
	$rdb{"sec","class","txt"}=~s/\n/\n<LI>/g;
	$rdb{"sec","class","txt"}=~s/<LI>$//g;
	print $fhoutHtml 
	    "overall your protein can be classified as:<BR>",
	    "<STRONG>",$rdb{"sec","class"},"</STRONG>\n",
	    " given the following classes:<BR>\n",
	    "<UL><LI>",$rdb{"sec","class","txt"},"</UL>\n"; 
	print $fhoutHtml "</UL>\n";
	print $fhoutHtml "<P><BR><P>\n";}
				# ------------------------------
				# write sec str composition
    if (defined $rdb{"1","PHL"} || defined $rdb{"1","PHEL"}) {
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG><A NAME=\"prof_syn_seccom\">Predicted secondary structure composition ",
	    "for your protein:</A></STRONG>\n",
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
		"<TD>$tmp</TD>";}
	print $fhoutHtml 
	    "</TR>\n";
	foreach $tmp (@tmp2){
	    print $fhoutHtml 
		"<TD>$tmp</TD>";}
	print $fhoutHtml 
	    "</TR>\n",
	    "</TABLE>\n",
	    "</LI></UL><P><BR>\n";}
    print $fhoutHtml 
	"\n";
				# ------------------------------
				# summary:htm
    if (defined $rdb{"HTM_NHTM_BEST"}) {
	print $fhoutHtml 
	    "<UL><LI><STRONG><A NAME=\"prof_syn_htm\">PROFhtm summary</A></STRONG>\n";

	$nbest=$rdb{"HTM_NHTM_BEST"};    $nbest=~s/(\d+).*$/$1/g;
	$n2nd= $rdb{"HTM_NHTM_2ND_BEST"};$n2nd=~s/(\d+).*$/$1/g;
	$txtBest= "helix"; $txtBest= "helices" if ($nbest > 1);
	$txt2nd=  "helix"; $txt2nd=  "helices" if ($n2nd > 1);

	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG>NHTM=$nbest</STRONG><BR>\n",
	        "PROFhtm detected <STRONG>$nbest</STRONG> membrane ".
		"$txtBest for the <STRONG>best</STRONG> model.".
		    "The second best model contained $n2nd $txt2nd.\n";
	$top=           $rdb{"HTM_HTMTOP_PRD"}; $top=~s/(\S+).*$/$1/g;
	$rel_best_dproj=$rdb{"HTM_REL_BEST_DPROJ"};$rel_best_dproj=~s/^(\S+).*$/$1/g;
	$rel_best=      $rdb{"HTM_REL_BEST"};$rel_best=~s/^(\S+).*$/$1/g;
	$htmtop_rid=    $rdb{"HTM_HTMTOP_RID"};$htmtop_rid=~s/^(\S+).*$/$1/g;
	$htmtop_rip=    $rdb{"HTM_HTMTOP_RIP"};$htmtop_rip=~s/^(\S+).*$/$1/g;
	print $fhoutHtml 
	    "<LI><STRONG>TOP=$top</STRONG><BR>\n",
	         "PROFhtm predicted the topology ",$top,", i.e. the first loop region is $top",
	      " (Note: this prediction may be problematic when the sequence you sent ",
	      "starts or ends with a region predicted in a membrane helix!)\n",
	    "<LI>Reliability of best model=",$rel_best_dproj," (0 is low, 9 is high)\n",
	    "<LI>Zscore for best model=",$rel_best,"\n",
	    "<LI>Difference of positive charges (K+R) inside - outside=",
	      $htmtop_rid," (the higher the value, the more reliable)\n",
	    "<LI>Reliability of topology prediction =",
	      $htmtop_rip," (0 is low, 9 is high)\n";
				# strength of single HTMs
	if (defined $rdb{"HTM_MODEL_DAT"}) {
	    @tmp=split(/\t/,$rdb{"HTM_MODEL_DAT"});
	    print $fhoutHtml 
		"<LI>Details of the strength of each predicted membrane helix:<BR>\n",
		"(sorted by strength, strongest first)<BR>\n";
	    
	    print $fhoutHtml
		"<TABLE BORDER=1>\n",
		"<TR><TD>N HTM<TD>Total score<TD>Best HTM<TD>c-N</TR>\n";
	    foreach $tmp (@tmp) {
		$tmp=~s/\n+//g;@tmp2=split(/,/,$tmp);
		print $fhoutHtml "<TR>";
		foreach $tmp2 (@tmp2) {
		    print $fhoutHtml "<TD>$tmp2"; }
		print $fhoutHtml "</TR>\n"; }
	    print $fhoutHtml "</TABLE>\n"; }
				# table with regions
	$tmp="";
	foreach $it (1..$rdb{"NROWS"}){
	    $tmp="?";
	    $tmp.=$rdb{$it,"PiMo"} if (defined $rdb{$it,"PiMo"});
	}
	if (0){
	    if (! defined $rdb{1,"PiMo"}){
		print "xx missing\n";
		foreach $kwd (sort keys %rdb){
		    if ($kwd=~/^\d\D|^\D+$/){
			print"$kwd ",$rdb{$kwd},"\n";}}print "\n";die;}}
				# get segments
				# out GLOBAL: %segment
	($Lok,$msg)=
	    &getSegment($tmp);  return(&errSbrMsg("failed to get segment for $tmp",
						  $SBR3)) if (! $Lok);

	print $fhoutHtml
	    "<LI>Overview over transmembrane segments:<BR>\n",
	    "<TABLE BORDER=1>\n",
	    "<TR><TD>Positions<TD>Segments<TD>Explain</TR>\n";
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
		"</TR>\n"; 
	}
	print $fhoutHtml
	    "</TABLE>\n";
	    
	print $fhoutHtml "</UL>\n";
	print $fhoutHtml "</UL>\n";
	print $fhoutHtml "<P><BR>\n";
    }
#     else {
# 	print "xx blooddy missing:\n";
# 	foreach $kwd (keys %rdb){
# #	    next if ($kwd !~ /htm/i);
# 	    next if ($kwd =~ /^\d/);
# 	    next if ($kwd =~ /\d$/);
# 	}
# 	die;
#     }
				# ------------------------------
				# solvent acc composition
    if (defined $rdb{"1","PREL"}) {
	print $fhoutHtml 
	    "<UL>\n",
	    "<LI><STRONG><A NAME=\"prof_syn_acccom\">Predicted solvent accessibility composition ",
	    "(core/surface ratio) for your protein:</A></STRONG><BR>\n",
	    "\t Classes used:\n",
	    "\t <UL>\n",
	    "\t <LI>e: residues exposed with more than ".$par{"thresh2acc"}."% of their surface</LI>\n",
	    "\t <LI>b: all other residues.</LI>\n",
	    "\t </UL>\n";
	print $fhoutHtml 
	    "<LI>The subsets are for the fractions of residues predicted at higher levels ",
	    "of reliability, i.e. accuracy. This set covers ".int($rdb{"acc","sub"}),
	    "% of all residues.</LI>\n"
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
		"<TD>$tmp</TD>";}
	print $fhoutHtml 
	    "</TR>\n",
	    "<TR>\n";
	foreach $tmp (@tmp2){
	    print $fhoutHtml 
		"<TD>$tmp</TD>";}
	print $fhoutHtml 
	    "</TR>\n";
	print $fhoutHtml 
	    "</TABLE>\n",
	    "</LI></UL><P><BR>\n";}
    print $fhoutHtml 
	"\n";
    print $fhoutHtml 
	"<!-- END SUMMARY -->\n",
	"<!-- -------------------------------------------------------------------------------- -->\n",
	"<BR>\n";
	
				# --------------------------------------------------
				# HEADER= general information
				# --------------------------------------------------
    print $fhoutHtml 
	"<BR><HR><BR>\n",
	"<!-- -------------------------------------------------------------------------------- -->\n",
	"<!-- BEG HEADER -->\n",
	"<TABLE CELLPADDING=1 CELLSPACING=2 BORDER=1 WIDTH=100%>\n",
	"<TR VALIGN=TOP><TD VALIGN=TOP BGCOLOR=\"#0000FF\" WIDTH=100%><STRONG>",
	"<FONT COLOR=\"#FFFFFF\">",
	"<BR><H3><A NAME=\"prof_hdr\">HEADER information</A></H3>\n",
	"</FONT></STRONG></TD></TR>\n",
	"</TABLE>\n";
	

				# ------------------------------
				# protein
    print $fhoutHtml 
	"<UL>\n",
	"<LI><STRONG><A NAME=\"prof_hdr_prot\">About your protein:</A></STRONG>\n",
	"<TABLE BORDER=1 CELLPADDING=2>\n";
    foreach $kwd (@kwdHead){
	next if ($kwd !~/^prot/);
	next if (! defined $rdb{$kwd});
	$tmp_taken{$kwd}=1;
	if ($kwd =~ /prot_cut/){
	    print $fhoutHtml 
		"<TR><TD><A HREF=\"\#".$kwd."\">".$kwd."</A></TD><TD><STRONG>",
		$rdb{$kwd},"</STRONG></TD></TR>\n";}
	else {
	    print $fhoutHtml 
		"<TR><TD><A HREF=\"\#".$kwd."\">".$kwd."</A></TD><TD>",$rdb{$kwd},"</TD></TR>\n";}
    }
    print $fhoutHtml
	"</TABLE>\n",
	"</UL><BR>\n";
				# ------------------------------
				# alignment
    print $fhoutHtml 
	"<UL>\n",
	"<LI><STRONG><A NAME=\"prof_hdr_ali\">About the alignment used:</A></STRONG>\n",
	"<TABLE BORDER=1 CELLPADDING=2>\n";
    undef %tmp_taken;

    foreach $kwd (@kwdHead){
	next if ($kwd !~/^ali/);
	next if (! defined $rdb{$kwd});
	$tmp_taken{$kwd}=1;
	print $fhoutHtml 
	    "<TR><TD><A HREF=\"\#".$kwd."\">".$kwd."</A></TD><TD>",$rdb{$kwd},"</TD></TR>\n";
    }
    print $fhoutHtml
	"</TABLE>\n",
	"</UL><P>\n";
				# ------------------------------
				# write residue composition
    print $fhoutHtml 
	"<UL>\n",
	"<LI><STRONG><A NAME=\"prof_hdr_res\">Residue composition for your protein:</A></STRONG>\n",
	"<TABLE BORDER=1 CELLPADDING=2>\n",
	"<TR>";
    $ct=0;
    foreach $aa (split(//,"ACDEFGHIKLMNPQRSTVWY")) {
	++$ct;
	if ($ct > 5) {$ct=1;
		      print $fhoutHtml "</TR>\n<TR>";}
	printf $fhoutHtml "%-s %3.1f","<TD>%"."$aa:",$rdb{$aa,"seq"};}
    print $fhoutHtml 
	"</TABLE>\n",
	"</UL><P>\n";
				# ------------------------------
				# technical information
    print $fhoutHtml 
	"<UL>\n",
	"<LI><STRONG><A NAME=\"prof_hdr_tech\">About the PROF methods used:</A></STRONG>\n",
	"<TABLE BORDER=1 CELLPADDING=2>\n";
    foreach $kwd (@kwdHead){
	next if ($kwd !~/^prof/);
	next if (! defined $rdb{$kwd});
	$tmp_taken{$kwd}=1;
	print $fhoutHtml 
	    "<TR><TD><A HREF=\"\#".$kwd."\">".$kwd."</A></TD><TD>",$rdb{$kwd},"</TD></TR>\n";
    }
    print $fhoutHtml
	"</TABLE>\n",
	"</UL><P>\n";
				# ------------------------------
				# please quote
    print $fhoutHtml 
	"<UL>\n",
	"<LI><STRONG><A NAME=\"prof_hdr_quote\">Please quote:</A></STRONG>\n";
    print $fhoutHtml 
	"\t <OL>\n",
	"\t <LI> PROF: ".$par{"txt","quote","prof"}."</LI>\n";
    print $fhoutHtml 
	"\t <LI> PROFsec:\n".$par{"txt","quote","profsec"}."</LI>\n"
	    if ($par{"optProf"}=~/^(3|both|sec)/);
    print $fhoutHtml 
	"\t <LI> PROFacc:\n".$par{"txt","quote","profacc"}."</LI>\n"
	    if ($par{"optProf"}=~/^(3|both|acc)/);
    print $fhoutHtml 
	"\t <LI> PROFhtm:\n".$par{"txt","quote","profhtm"}."</LI>\n"
	    if ($par{"optProf"}=~/^(3|htm)/);
    print $fhoutHtml 
	"\t </OL>\n",
	"</UL><P>\n";
				# ------------------------------
				# copyright
    print $fhoutHtml 
	"<UL>\n",
	"<LI><STRONG><A NAME=\"prof_hdr_copy\">Copyright \&amp\; Contact:</A></STRONG><BR>\n",
	"\t <UL>\n",
	"\t <LI> ".$par{"txt","copyright"}."</LI>\n",
	"\t <LI> Email: <A HREF=\"".$par{"txt","contactEmail"}."\">",
	    $par{"txt","contactEmail"}."</A></LI>\n",
	"\t <LI> WWW: <A HREF=\"".$par{"txt","contactWeb"}."\">",
	    $par{"txt","contactWeb"}."</A></LI>\n",
	"\t <LI> Fax: ".$par{"txt","contactFax"}."</LI>\n",
	"\t </UL>\n",
	"</UL><P>\n";
	
				# ------------------------------
				# syntax style:
				#      kwd : explanation
				# ------------------------------
    print $fhoutHtml 
	"<P><BR><P>\n",
	"<UL>\n",
	"<LI><STRONG><A NAME=\"prof_hdr_abbr\">ABBREVIATIONS used:</A></STRONG>\n",
	"<TABLE BORDER=1 CELLPADDING=2>\n";
				# (1) data keywords
    foreach $kwd (@kwdBody) {
	next if (! defined $rdb{"1",$kwd});
	$tmp=$transDescr{$kwd}; $tmp=~s/\n$//; $tmp=~s/\n\n+/\n/g; $tmp=~s/\n/<BR>/g;
	$tmp_taken{$kwd}=0;
	print $fhoutHtml
	    "<TR VALIGN=TOP>",
	    "<TD><A NAME=\"$kwd\">",$transAbbr{$kwd},"</A>: </TD>",
	    "<TD>$tmp</TD></TR>\n";
				# subset after REL
	next if ($kwd !~ /RI/);
	if    ($kwd eq "RI_S") { $kwd2="SUBsec"; }
	elsif ($kwd eq "RI_A") { $kwd2="SUBacc"; }
	elsif ($kwd eq "RI_M") { $kwd2="SUBhtm"; }
	$abbr= $transAbbr{$kwd2};
	$descr=$transDescr{$kwd2}; $descr=~s/\n$//; $descr=~s/\n\n+/\n/g; $descr=~s/\n/<BR>/g;
	$tmp_taken{$abbr}=0;
	print $fhoutHtml
	    "<TR VALIGN=TOP>",
	    "<TD><A NAME=\"$abbr\">",$abbr,"</A>: </TD>",
	    "<TD>$descr</TD></TR>\n";
				# finish with empty line
	print $fhoutHtml 
	    "<TR><TD> </TD><TD> </TD></TR>\n";
    } 
				# (2) header asf
    print $fhoutHtml
	"<TR><TD> </TD><TD> </TD></TR>\n";
    foreach $kwd (@kwdHead){
	next if (! defined $kwd || $kwd=~/^\s*$/);
	if ($kwd=~/prof_skip/){
	    print $fhoutHtml
		"<TR><TD><A NAME=\"".$kwd."\">",$kwd,"</A>: </TD>",
		"<TD>".$par{"notation",$kwd}."</TD></TR>\n";
	    next;}
	next if (! defined $par{"notation",$kwd});
	next if (! defined $tmp_taken{$kwd} || ! $tmp_taken{$kwd});
	$notation=$par{"notation",$kwd};
	$notation=~s/\n/<BR>/g;	# replace newlines
	print $fhoutHtml
	    "<TR><TD><A NAME=\"".$kwd."\">",$kwd,"</A>: </TD>",
	    "<TD>".$notation."</TD></TR>\n";
    }

				# (3) alignment information
    if ($Lali){
	print $fhoutHtml
	    "<TR><TD> </TD><TD> </TD></TR>\n";
	foreach $kwd ("pide","lali"){
	    $notation=$par{"notation","ali_".$kwd};
	    $notation=~s/\n/<BR>/g;	# replace newlines
	    print $fhoutHtml
		"<TR><TD><A NAME=\"".$kwd."\">",$kwd,"</A>: </TD>",
		"<TD>".$notation."</TD></TR>\n";
	}}

    print $fhoutHtml 
	"</TABLE>\n",
	"</LI></UL>",
	"\n";

    print $fhoutHtml 
	"<!-- END HEADER -->\n",
	"<!-- -------------------------------------------------------------------------------- -->\n";
	
    print $fhoutHtml 
	"<P><BR><P>\n",
	"<HR>\n",
	"<BR><P><BR>\n",
	"<!-- -------------------------------------------------------------------------------- -->\n",
	"<!-- BEG BODY -->\n",
	"<TABLE CELLPADDING=1 CELLSPACING=2 BORDER=1 WIDTH=100%>\n",
	"<TR VALIGN=TOP><TD VALIGN=TOP BGCOLOR=\"#0000FF\" WIDTH=100%><STRONG>",
	"<FONT COLOR=\"#FFFFFF\">",
	"<BR><H3><A NAME=\"prof_body\">BODY with predictions for ".$prot_id." ".$prot_nameTxt."</A></H3>\n",
	"</FONT></STRONG></TD></TR>\n",
	"</TABLE>\n";
	

    undef %segment;		# slim-is-in
    return(1,"ok $SBR3");
}				# end of convProf2html_wrtBodyHdr

#===============================================================================
sub convProf2html_wrtHead {
    local($fileInLoc,$titleLoc,$Lhead,$fhoutHtml,$fileOutLoc,$rh_css_prof)=@_;
    local($SBR3,$sum,$itRes,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html_wrtHead        writes HEAD part of HTML file
#                               
#       in:                     $fileInLoc=       PROFrdb file
#       in:                     $titleLoc=        to be used for HTML title
#       in:                     $Lhead=           if 1 write header,
#                                                 if 0 open file only
#       in:                     $fhoutHtml=       file handle for writing HTML
#       in:                     $fileOutLoc=      HTML output file
#       in:                     $rh_css_prof=      reference to %css_prof{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."convProf2html_wrtHead";
				# check arguments
    return(&errSbr("not def fileInLoc!", $SBR3)) if (! defined $fileInLoc);
    return(&errSbr("not def titleLoc!",  $SBR3)) if (! defined $titleLoc);
    return(&errSbr("not def fileOutLoc!",$SBR3)) if (! defined $fileOutLoc);
    return(&errSbr("not def fhoutHtml!", $SBR3)) if (! defined $fhoutHtml);
    return(&errSbr("not def rh_css_prof!",$SBR3)) if (! defined $rh_css_prof);

    
    if ($fileOutLoc) {
	open($fhoutHtml,">".$fileOutLoc) || 
	    return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR3)); }

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    return(1,"ok $SBR3")    if (! $Lhead);

    $style= "<STYLE TYPE=\"text/css\">\n";
    $style.="<!-- \n";
				# PROFsec
    foreach $kwd ("H","E","L") {
	$style.="FONT."."sec-".$kwd.$rh_css_prof->{"sec-".$kwd}."\n";
	$style.="FONT."."sec-".$kwd."sub".$rh_css_prof->{"sec-".$kwd."sub"}."\n"; 
	$style.="FONT."."sec-"."p".$kwd.$rh_css_prof->{"sec-"."p".$kwd}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."sec-".$kwd.$rh_css_prof->{"sec-".$kwd}."\n";}
				# PROFacc
    foreach $kwd ("e","i","b") {
	$style.="FONT."."acc-".$kwd.$rh_css_prof->{"acc-".$kwd}."\n"; 
	$style.="FONT."."acc-".$kwd."sub".$rh_css_prof->{"acc-".$kwd."sub"}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."acc-".$kwd.$rh_css_prof->{"acc-".$kwd}."\n";}
    foreach $kwd ("PREL","OREL"){
	$style.="FONT."."acc-".$kwd.$rh_css_prof->{"acc-".$kwd}."\n";}
				# PROFhtm
    foreach $kwd ("M","N") {
	$style.="FONT."."htm-".$kwd.$rh_css_prof->{"htm-".$kwd}."\n"; 
	$style.="FONT."."htm-".$kwd."sub".$rh_css_prof->{"htm-".$kwd."sub"}."\n"; 
	$style.="FONT."."htm-"."p".$kwd.$rh_css_prof->{"htm-"."p".$kwd}."\n"; }
    foreach $kwd ("i","o") {
	$style.="FONT."."htm-".$kwd.$rh_css_prof->{"htm-".$kwd}."\n"; }
    foreach $kwd (0..9){
	$style.="FONT."."htm-".$kwd.$rh_css_prof->{"htm-".$kwd}."\n";}

				# sequence: only for HTM
    if ($#kwdHead > 0 && ! $Lali && defined $rdb{"1","PiMo"}) {
	foreach $kwd ("E","D","K","R") {
	    $style.="FONT."."res-".$kwd.$rh_css_prof->{"res-".$kwd}."\n";
	}}
    if ($#kwdHead > 0 && $Lali){
	foreach $kwd (
		      "E","D","K","R","P","M","S","G","A","F",
		      "V","I","L","T","Y","N","Q","H","W","C"
		      ){
	    next if (! defined $rh_css_prof->{"res-".$kwd});
	    $style.="FONT."."res-".$kwd.$rh_css_prof->{"res-".$kwd}."\n";
	}}

				# subtoc
    $style.="DIV.subtoc { padding: 1em\; margin: 1em 0\;border: thick inset \;background: silver\;}\n";
    $style.=" -->\n";
    $style.="</STYLE>\n";

    ($Lok,$msg)=
	&htmlWrtHead($fhoutHtml,"PROF prediction ($titleLoc)",$style);

    return(&errSbrMsg("failed writing HTML header (file=$fileInLoc)",$msg,$SBR3))
	if (! $Lok);

    return(1,"ok $SBR3");
}				# end of convProf2html_wrtHead

#===============================================================================
sub convProf2html_wrtOneLevel {
    local($nblocksLoc,$lenAbbrLoc,$fhoutHtml,$fileOutLoc,$modeLoc,
	  $nresPerLineLoc,$riSubSecLoc,$riSubAccLoc,$riSubHtmLoc,$riSubSymLoc,
	  $rh_css_prof,$ra_kwdBodyLoc)=@_;
    local($SBR3,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convProf2html_wrtOneLevel    writes one level of detail
#                               
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
#       in:                     $rh_css_prof=      reference to %css_prof{kwd}=
#                                  OREL,PREL,p<HELTMN>,<HELTMN>,<HELTMN>sub
#       in:                     
#                               
#       in GLOBAL:              %transSym,%transAbbr
#                               
#       out:                    1|0,msg,  implicit: write to $fhoutHtml
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."convProf2html_wrtOneLevel";
				# check arguments
    return(&errSbr("not def nblocksLoc!",$SBR3))     if (! defined $nblocksLoc);
    return(&errSbr("not def lenAbbrLoc!",$SBR3))     if (! defined $lenAbbrLoc);
    return(&errSbr("not def fhoutHtml!",$SBR3))      if (! defined $fhoutHtml);
    return(&errSbr("not def fileOutLoc!"))               if (! defined $fileOutLoc);
    return(&errSbr("not def modeLoc!"))                  if (! defined $modeLoc);
    return(&errSbr("not def nresPerLineLoc!",$SBR3)) if (! defined $nresPerLineLoc);
    return(&errSbr("not def riSubSecLoc!",$SBR3))    if (! defined $riSubSecLoc);
    return(&errSbr("not def riSubAccLoc!",$SBR3))    if (! defined $riSubAccLoc);
    return(&errSbr("not def riSubHtmLoc!",$SBR3))    if (! defined $riSubHtmLoc);
    return(&errSbr("not def riSubSymLoc!",$SBR3))    if (! defined $riSubSymLoc);
    return(&errSbr("not def rh_css_prof!",$SBR3))     if (! defined $rh_css_prof);
    return(&errSbr("not def $ra_kwdBodyLoc!",$SBR3)) if (! $ra_kwdBodyLoc);

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

	$string=&myprt_npointsfull($ncount,$itEnd);	
				# force same length as sequence
	$lenNumbers=length($string);
	if ($lenNumbers > (3+$itEnd-$itBeg) ){
	    $string=substr($string,1,(1+$itEnd-$itBeg));
	    $lenNumbers=length($string);}

	$tmp=" " x $lenAbbrLoc;
	if ($modeLoc =~ /normal/ && $Lali){
	    $add= " | ";
	    $add.="<A HREF=\"\#pide\"><I>pide</I></A>";
	    $add.=" | ";
	    $add.="<A HREF=\"\#lali\"><I>lali</I></A>";}
	else {
	    $add="";}
	    
	print $fhoutHtml "$tmp"," ",$string,$add,"\n";

	

				# --------------------------------------------------
				# loop over all keywords
				#    i.e. all rows (AA,OHEL,PHEL)
				# --------------------------------------------------
	foreach $itKwd (1..$#{$ra_kwdBodyLoc}) {
	    $kwd="";
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
#		if (!defined $rdb{$itRes,$kwd} && $itRes==1){
#		    print "xx missing $kwd in HTML\n";die;}

		next if (! defined $rdb{$itRes,$kwd}); # hack br 2002-04 br
		    
		$sym=$rdb{$itRes,$kwd}; 
				# normalise relative acc to numbers 0-9
		$sym=&exposure_project_1digit($sym)
		    if ($kwd =~ /^[OP]REL/);
		
				# ------------------------------
				# probability PROFsec, PROFhtm
#		if ($kwd=~/^p[HELTMN]$/ && $sym !~/[0-9]/) {
#		    print "xx trouble kwd=$kwd itres=$itRes val=$sym\n";
#		    next;}
		if ($kwd=~/^p[HELTMN]$/) {
		    foreach $it (1..10){
			if ($sym <= ($it-1)) {
			    $string[$it].=" "; }
			else {
			    $string[$it].="."; }
		    }
		}
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
		    $symPrt=$transSec2Htm{$sym} if ($kwd=~/^[OP](MN|RMN|FMN)/);
				# for brief RI =< |*>
		    if ($modeLoc eq "brief" && $kwd=~/^RI/) {
			$symPrt="*";
			$symPrt=" " if ($sym < $relStrong); 
		    }
				# which style
		    if    ($kwd=~/^[OP]HEL|^p[HEL]|RI_S/)  { 
			$kwdCss="sec-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](REL|bie)|^RI_A/)    { 
			$kwdCss="acc-".$symPrt  if ($symPrt!~/^[ \*]$/); }
		    elsif ($kwd=~/^[OP](MN|RMN|iMo)|^p[MN]|^RI_M/) { 
			$kwdCss="htm-".$symPrt  if ($symPrt !~/^[ \*]$/); }
				# sequence
		    elsif ($kwd=~/^AA/){
			$kwdCss="res-".$symPrt  if ($symPrt !~/^[ \*]$/); }
				# 'L' -> ' '
		    $symPrt=$transSym{$sym} if (defined $transSym{$sym} && $kwd !~/^[OP]REL/
						&& $kwd ne "AA" && $kwd !~/PiMo/ 
						&& $symPrt ne " " && $symPrt ne "*");
						
			
		    if    ($kwd eq "AA" && defined $kwdCss && defined $rh_css_prof->{$kwdCss}) {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."</FONT>"; 
		    }
		    elsif (! defined $kwdCss    || ! defined $rh_css_prof->{$kwdCss} 
			   || $kwd =~/^[OP]REL/ || $kwd eq "AA"
			   || $symPrt eq " "    || $symPrt eq "*" || $symPrt eq ".") {
			$string.=$symPrt; 
		    }
		    else {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."</FONT>"; 
		    } 
		} 

	    }			# end of loop over current block
				# ------------------------------

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

				# probability PROFsec
	    if ($kwd=~/^p[HELTMN]$/) {
		if ($kwd=~/^p[HEL]$/) {
		    $kwdCss="sec-".$kwd; }
		elsif ($kwd=~/^p[TMN]$/) {
		    $kwdCss="htm-".$kwd; }

		if (! defined $kwdCss    || ! defined $rh_css_prof->{$kwdCss}) {
		    $tmp1="";
		    $tmp2=""; }
		else {
		    $tmp1="<FONT CLASS=".$kwdCss.">";
		    $tmp2="</FONT>";}
		foreach $it (1..9) {
		    $it2=10-$it;
		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)/10;

#		    $txt= $abbr.$string[$it2].sprintf("  %2.1f ",$tmp3);
		    $txt= $abbr." ".$string[$it2].sprintf("  %2.1f ",$tmp3); # br hack 2007/08/31
		    $txt.=$abbr if (! $nresPerLineLoc);
		    print $fhoutHtml $txt,"\n";

		}
#		print $fhoutHtml " " x $lenTotal, "-" x $ncount,"\n";
		print $fhoutHtml " " x $lenTotal, " ", "-" x $ncount,"\n"; # br hack 2007/08/31
	    }

				# relative acc PROFacc
	    elsif ($kwd=~/^[OP]REL$/) {
		$kwdCss="acc-".$kwd;
		if (! defined $kwdCss    || ! defined $rh_css_prof->{$kwdCss}) {
		    $tmp1="";
		    $tmp2=""; }
		else {
		    $tmp1="<FONT CLASS=".$kwdCss.">";
		    $tmp2="</FONT>";}
		foreach $it (1..9) {
		    $it2=10-$it;
		    $string[$it2]=~s/([\.]+)/$tmp1$1$tmp2/g;
		    $tmp3=($it2+1)*($it2+1);

#		    $txt= $abbr.$string[$it2].sprintf("  %3d%-s ",int($tmp3),"%");
		    $txt= $abbr." ".$string[$it2].sprintf("  %2.1f ",$tmp3); # br hack 2007/08/31
		    $txt.=$abbr if (! $nresPerLineLoc);

		    print $fhoutHtml $txt,"\n";
		}
#		print $fhoutHtml " " x $lenTotal, "-" x $ncount,"\n";
		print $fhoutHtml " " x $lenTotal, " ", "-" x $ncount,"\n"; # br hack 2007/08/31
	    }

	    else {
		print $fhoutHtml "$abbr $string\n"; }

				# ------------------------------
				# insert alignment
	    if ($kwd=~/^AA/ && $modeLoc=~/normal/ && $Lali){
		($Lok,$msg,$stringAli)=
		    &convProf2html_wrtAli
			($itBeg,$itEnd,$lenNumbers,$rh_css_prof);
		print $fhoutHtml $stringAli;
	    }			# end of ali


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
#		    print "xx kwd=$kwd, sym=$sym, symPrt=$symPrt,\n";
		    if    ($kwd=~/^RI_S/) { $kwdCss="sec-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_A/) { $kwdCss="acc-".$symPrt."sub"; }
		    elsif ($kwd=~/^RI_M/) { $kwdCss="htm-".$symPrt."sub"; }

		    if (! defined $kwdCss || ! defined $rh_css_prof->{$kwdCss} || $symPrt eq " ") {
			$string.=$symPrt; }
		    else {
			$string.="<FONT CLASS=".$kwdCss.">".$symPrt."</FONT>";}  
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
    return(1,"ok $SBR3");
}				# end of convProf2html_wrtOneLevel

#===============================================================================
sub htmlWrtHead {
    local($fhoutLoc,$titleLoc,$txtLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlWrtHead                 writes header of HTML file
#                               
#       in:                     $fhoutLoc=    file handle to write
#       in:                     $titleLoc=    title for file
#       in:                     $txtLoc=      optional text (e.g. styles asf)
#                               
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
	"</TITLE>\n",
	"</HEAD>\n";

    return(1,"ok $sbrName");
}				# end of htmlWrtHead

1;
