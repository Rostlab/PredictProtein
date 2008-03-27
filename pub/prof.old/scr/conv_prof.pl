#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="converts a PROF.rdb file to PROF.prof ASCII human readable format.\n".
    "     \t AND/OR to <MSF|SAF|DSSP|CASP|HTML>\n".
    "     \t ";
# 
# 
# NOTE: for easy exchange with PROF, all major subroutines shared between
#       PROF and this program appear at the end of it (after 'lllend')
# 
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Mar,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# find library
$dirScr=$0; $dirScr=~s/^(.*\/)[^\/]*$/$1/;
@lib=(
      "lib-profwrt.pl",
      "lib-profhtml.pl",
      "lib-prof.pl"
      );
$Lok=$ctok=0;
undef %tmp; 
foreach $dir ($dirScr,
	      "",
	      "lib/","pack/",
	      $dirScr."lib/",$dirScr."pack/",
	      "/home/rost/pub/prof/scr/",
	      "/home/rost/pub/prof/scr/lib/",
	      "/home/rost/pub/prof/scr/pack/"
	      ){
    foreach $lib (@lib) {
	next if (defined $tmp{$lib});
	next if (! -e $dir.$lib);
	$Lok=require($dir.$lib); 
	if ($Lok) {
	    $tmp{$lib}=1;
	    ++$ctok;
	    last if ($ctok==$#lib);
	}
    }
}

die("*** ERROR $scrName: could NOT find libs=".join(',',@lib,"\n")) if ($ctok < $#lib);

				# ------------------------------
				# ini
($Lok,$msg)=&ini();		die("*** ERROR $scrName: failed in ini:\n".
				    $msg."\n") if (! $Lok);

				# ------------------------------
				# note about what to do
print "--- $scrName: will do conversions to:",join(',',@formatOutWant,"\n")
    if ($par{"verbose"});
    
				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileIn,$ctfile,(100*$ctfile/$#fileIn);

				# ------------------------------
				# find alignment if to be done
				# ------------------------------
    if ($par{"ali"}){
	$id=$fileIn; $id=~s/^.*\///g;
	$id=~s/\..*$//g;
	$id2=$id; $id2=~s/_.$// if ($id2=~/_[0-9A-Z]$/);
	if    (defined $fileAli{$id}){
	    $fileAli=$fileAli{$id};}
	elsif (defined $fileAli{$id2}){
	    $fileAli=$fileAli{$id2};}
	else {
	    $fileAli=$id.$par{"extHssp"};
	    if (! -e $fileAli){
		print "-*- WARN $scrName: you want the ali, but file=$fileAli, missing!\n";
		$fileAli=0;}}}
    else {
	$fileAli=0;}
				# ------------------------------
				# ASCII, Casp, DSSP, MSF SAF
				# ------------------------------
    if ($par{"ascii"} || $par{"casp"}  || 
	$par{"dssp"}  || $par{"msf"}   || $par{"saf"}){

				# output file: more than one format wanted 
	if    ($#fileIn <= 1 && $#formatOutWant > 1){
	    foreach $kwd (@formatOutWant){
		if ((  defined $fileOut       && length($fileOut) > 3     ) &&
		    (! defined $fileOut{$kwd} || length($fileOut{$kwd})<=3)){
		    $tmpfile=$fileOut; 
		    $tmp2=substr($kwd,1,1); $tmp3=substr($kwd,2);
		    $tmp2=~tr/[a-z]/[A-Z]/;
		    $tmpext= $tmp2.$tmp3;
		    $tmpfile=~s/\..[^\.]*$/$tmpext/;
		    $fileOut{$kwd}=$tmpfile;
		}
	    }}
				# output file: just one format wanted 
	elsif ($#fileIn <= 1 && 
	       ($#formatOutWant == 1 || ($#formatOutWant==2 && $par{"html"}))){
	    $kwd=$formatOutWant[1];
	    $kwd=$formatOutWant[2] if ($kwd eq "html");
	    if    ((  defined $fileOut       && length($fileOut)>=3      ) &&
		   (! defined $fileOut{$kwd} || length($fileOut{$kwd})<=3)){
		$fileOut{$kwd}=$fileOut;}
	    elsif ((! defined $fileOut       || length($fileOut)<=3      ) &&
		   (  defined $fileOut{$kwd} && length($fileOut{$kwd})>3 )){
		$fileOut=$fileOut{$kwd};}
	    else{
		$fileOut=$fileIn; 
		$fileOut=~s/^.*\///g; # purge dir
		$fileOut=~s/\.rdbProf//g; # purge ext

#		$tmp2="Prof".$tmp;
#		$extTmp=".prof".$tmp1.$tmp2;
#		$extTmp=$par{"ext".$kwd}  if (defined $par{"ext".$kwd} && 
#					      length($par{"ext".$kwd})>2);
#		$extTmp=$par{"ext".$tmp2} if (defined $par{"ext".$tmp2} && 
#					      length($par{"ext".$tmp2})>2);
#		$fileOut=~s/\.rdb.*$//; 
				# get extension for keyword
		$tmp1=substr($kwd,1,1);
		$tmp1=~tr/[a-z]/[A-Z]/;
		$tmp2=substr($kwd,2);  
		$tmp= $tmp1.$tmp2;
		$fileOut=$par{"dirOut"}.$fileOut.$par{"extProf".$tmp};
		$fileOut{$kwd}=$fileOut;}
	}
				# output file: many input files
	elsif ($#fileIn > 1 || ! defined $fileOut || length($fileOut)<1){
	    $fileOut=$fileIn; $fileOut=~s/^.*\///g; 
	    $fileOut=~s/\.rdb.*$/\.prof/; 
	    $fileOut=$par{"dirOut"}.$fileOut; 
	}
				# output file: many input files
	else {
	    $fileOut=$fileIn; 
	    $fileOut=~s/^.*\///g; 
	    $fileOut=$par{"dirOut"}.$fileOut.
	    $fileOut=~s/\.rdb.*$/\.prof/; 
	    $fileOut=$par{"dirOut"}.$fileOut; 
	}
				# security
	$fileOut.=".tmp"        if ($fileOut eq $fileIn);
				# watch ya: remove existing output file
	if (-e $fileOut) {
	    $fileOutTmp=$fileOut.".tmp";
	    print "-*- WARN $scrName: move existing output file $fileOut->$fileOutTmp\n";
	    system("\\mv $fileOut $fileOutTmp");
	}

				# do conversion
	($Lok,$msg)=
	    &convProf
		($fileIn,$fileAli,$fileOut,$modeWrt,$par{"nresPerRow"},
		 $par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSec"},$par{"riSubSym"},
		 $par{"txtPreRow"},$par{"debug"},\%fileOut
		 ); 
	if (! $Lok){
	    $tmpwrt= "*** ". "***" x 20 ."\n";
	    $tmpwrt.="*** \n";
	    $tmpwrt.="*** ERROR $scrName: \n";
	    $tmpwrt.="***      serious problem converting $fileIn!\n";
	    $tmpwrt.="***      for info see file=".$par{"fileOutError"}."!\n";
	    $tmpwrt.="*** msg below this line\n";
	    $tmpwrt.=$msg."\n";
	    $tmpwrt.="*** msg above this line\n";
	    $tmpwrt.="*** ". "***" x 20 ."\n";
	    print $FHTRACE $tmpwrt;
	    open("FHOUT_ERROR",">>".$par{"fileOutError"});
	    print FHOUT_ERROR $tmpwrt;
	    close("FHOUT_ERROR");
	    $tmpwrt="";}
    }

				# ------------------------------
				# HTML
				# ------------------------------
    if ($par{"html"}){
				# name of output file
	if    ($#fileIn <= 1 && 
	       defined $fileOut{"html"} && length($fileOut{"html"})>3 ){
	    $fileOut=$fileOut{"html"};}
	elsif ($#fileIn > 1 || ! defined $fileOut || length($fileOut)<1 || $fileOut !~ /\.htm/){
	    $fileOut=$fileIn; $fileOut=~s/^.*\///g; 
	    $fileOut=~s/\.rdb.*$/$par{"extProfHtml"}/; 
	    $fileOut=$par{"dirOut"}.$fileOut; }
				# security
	$fileOut.=".tmp"        if ($fileOut eq $fileIn);
				# watch ya: remove existing output file
	if (-e $fileOut) {
	    $fileOutTmp=$fileOut.".tmp";
	    print "-*- WARN $scrName: move existing output file $fileOut->$fileOutTmp\n";
	    system("\\mv $fileOut $fileOutTmp");
	}
				# do conversion
	($Lok,$msg)=
	    &convProf2html
		($fileIn,$fileAli,$fileOut,$modeWrt,
		 $par{"nresPerRow"},
		 $par{"riSubSec"},$par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSym"},
		 "STDOUT");
	if (! $Lok)       { 
	    print 
		"*** ERROR $scrName: convProf2html($fileIn,$fileAli,$fileOut,$modeWrt)\n",
		"***       produced no output=$fileOut, msg where it failed:\n",
		"$msg\n";
	    next;}
	if (! -e $fileOut){ 
	    print "*** $scrName: no output=$fileOut\n";
	    next;}
	elsif ($par{"verbose"}){
	    print "--- $scrName: out=$fileOut\n";}
    }
}

print "--- last output in $fileOut\n" if (-e $fileOut);
exit;

#===============================================================================
sub ini {
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."ini";

    %par=(
	  'thresh2acc',        "16",    # <16 -> buried, >= -> exposed
	  'thresh3acc',        "9,36", # <9 -> buried, >=36 -> exposed, else intermediate

	  'ascii',             1,
	  'html',              0,			# 
	  'saf',               0,			# 
	  'dssp',              0,			# 
	  'msf',               0,			# 
	  'casp',              0,			# 
	  'casponly',          0,			# 
	  '', "",			# 

	  'notation',          1,       # explain notation
	  'averages',          1,       # include information about AA composition and SS composition
	  'header',            1,       # write information iin RDB header?
	  'summary',           1,       # write info about statistics (% AA, sec str asf)
	  'info',              1,       # write info about protein (length NALI asf)
	  'brief',             0,       # also give short version of prediction
	  'normal',            1,       # the typical OLD PROF output
	  'subset',            1,       # write line with subset ?
	  'detail',            1,       # write line with detail ?
	  'graph',             1,       # include ASCII graphics
	  'normal',            1,       # the old PROF info

	  'html_head',         1,       # if 1: write HTML header
	  'html_body',         1,       # if 1: write HTML body

	  'ali',               0,       # if 1: add alignment (expected in id.hssp)

	  'txtPreRow',         "",      # each row will begin with '$pre'
	  '',                  "",      # 
	  'nresPerRow',        60,      # number of residues per row
	  'scroll',            1,       # if 1: the HTML format will NOT be dissected into blocks
				        #       of e.g. 60 residues, rather it will be one long
				        #       line to scroll
	  
	  'riSubAcc',          4,       # minimal reliability index for SUBSET acc
	  'riSubHtm',          7,       # minimal reliability index for SUBSET htm
	  'riSubSec',          5,       # minimal reliability index for SUBSET sec
	  'riSubSym',          ".",     # symbol for residues predicted with RI<SubSec/Acc
	  
	  '',      "",

	  'optProf',            "htm",   # note the following are currently NOT being used!
	  'optDoHtmref',       1,
	  'optDoHtmtop',       1,

	  'dirOut',            "",         # name of directory for output files

	  'extHssp',            ".hssp",    # alignment expected to be in file 'id.hssp'

	  'extProfAscii',       ".prof",      # extension of file with PROF in ASCII format
	  'extProfDssp',        ".profDssp",  # extension of file with PROF in DSSP format
	  'extdssp',            ".profDssp",  # extension of file with PROF in DSSP format
	  'extProfMsf',         ".profMsf",   # extension of file with PROF + alignment in MSF format
	  'extmsf',             ".profMsf",   # extension of file with PROF + alignment in MSF format
	  'extProfSaf',         ".profSaf",   # extension of file with PROF + alignment in SAF format
	  'extsaf',             ".profSaf",   # extension of file with PROF + alignment in SAF format
	  'extProfCasp',        ".profCasp",  # extension of file with PROF in CASP format
	  'extcasp',            ".profCasp",  # extension of file with PROF in CASP format
	  'extProfHtml',        "_prof.html", # extension of file with PROF in HTML format


				        # used to steer what will be written, possible
				        #    'html:<all|body|head>'
				        #    'data:<all|brief|normal|detail>'
	  'parHtml',   "html:all,data:all",

	  );

    $par{"fileOutError"}=      "PROFconv.errors";
    $par{"fileOutWarn"}=       "PROFconv.warnings";

    $par{"aliMinLen"}=         20;        # minimal number of aligned residues to report alignment

    $par{"numresMin"}=         17;        # minimal number of residues to run network 
    $par{"numresMin"}=          9;        # minimal number of residues to run network 
				          #    otherwise prd=symbolPrdShort
    $par{"symbolPrdShort"}=     "*";      # default prediction for too short sequences
				          #    NOTE: also taken if stretch between two chains too short!
    $par{"symbolChainAny"}=     "*";      # chain name if chain NOT specified!
    $par{"acc2Thresh"}=         16;       # threshold for 2-state description of solvent accessibility, i.e.


    $par{"srsPath"}=            "http://srs6.ebi.ac.uk/srs6bin/cgi-bin/wgetz?-e+";
	
#    "[swissprot-id:paho_didma]"

    $par{"txt","copyright"}=       "Burkhard Rost, CUBIC NYC / LION Heidelberg";
    $par{"txt","contactEmail"}=    "rost\@columbia.edu";
    $par{"txt","contactFax"}=      "+1-212-305 3773";
    $par{"txt","contactWeb"}=      "http://cubic.bioc.columbia.edu";
    $par{"txt","version"}=         "2000.02";
    $par{"url","pp"}=              "http://cubic.bioc.columbia.edu/predictprotein/";
#    $par{"txt"}=       "";
    
    $par{"txt","modepred","sec"}=  "prediction of secondary structure";
    $par{"txt","modepred","cap"}=  "prediction of secondary structure caps";
    $par{"txt","modepred","acc"}=  "prediction of solvent accessibility";
    $par{"txt","modepred","htm"}=  "prediction of transmembrane helices";
    $par{"txt","modepred","loc"}=  "prediction of sub-cellular location";

    $par{"txt","quote","phd1994"}= "B Rost (1996) Methods in Enzymology, 266:525-539";
    $par{"txt","quote","prof1994"}="B Rost (1996) Methods in Enzymology, 266:525-539";
    $par{"txt","quote","prof"}=    "B Rost & C Sander (1993) J Mol Biol, 232:584-599";
    $par{"txt","quote","profsec"}= "B Rost & C Sander (1993) J Mol Biol, 232:584-599";
    $par{"txt","quote","profacc"}= "B Rost & C Sander (1994) Proteins, 20:216-226";
    $par{"txt","quote","profhtm"}= "B Rost, P Fariselli & R Casadio (1996) Prot Science, 7:1704-1718";
    $par{"txt","quote","globe"}=   "B Rost (1998) unpublished";
    $par{"txt","quote","topits"}=  "B Rost, R Schneider & C Sander (1997) J Mol Biol, 270:1-10";


    $par{"notation","prot_id"}=    "identifier of protein [w]";
    $par{"notation","prot_name"}=  "name of protein [w]";
    $par{"notation","prot_nres"}=  "number of residues [d]";
    $par{"notation","prot_nali"}=  "number of proteins aligned in family [d]";
    $par{"notation","prot_nchn"}=  "number of chains (if PDB protein) [d]";
    $par{"notation","prot_kchn"}=  "PDB chains used [0-9A-Z]";
    $par{"notation","prot_nfar"}=  "number of distant relatives [d]";

    $par{"notation","ali_orig"}=   "input file";
    $par{"notation","ali_used"}=   "input file used";
    $par{"notation","ali_para"}=   "parameters used to filter input file";
    $par{"notation","ali_pide"}=   "percentage of identical residues";
    $par{"notation","ali_lali"}=   "number of aligned residues";

    $par{"notation","prof_fpar"}=   "name of parameter file, used [w]";
    $par{"notation","prof_nnet"}=   "number of networks used for prediction [d]";
    $par{"notation","prof_fnet"}=   "name of network architectures, used [w]";
    $par{"notation","prof_mode"}=   "mode of prediction [w]";
    $par{"notation","prof_version"}="version of PROF";

    $par{"notation","prof_skip"}=   "note: sequence stretches with less than ".$par{"numresMin"}.
	                           " are not predicted, the symbol '".$par{"symbolPrdShort"}.
				       "' is used!";

				# protein
    $par{"notation","No"}=         "counting residues [d]";
    $par{"notation","AA"}=         "amino acid one letter code [A-Z!a-z]";
    $par{"notation","CHN"}=        "protein chain [A-Z!a-z]";
    $par{"notation","pide"}=       "percentage of identical residues [0-9] ";
    $par{"notation","lali"}=       "number of residues aligned [0-9] ";

				# secondary structure
    $par{"notation","OHEL"}=       "observed secondary structure: H=helix, E=extended (sheet), ".
	                           "blank=other (loop)";
    $par{"notation","PHEL"}=       "PROF predicted secondary structure: ".
	                           "H=helix, E=extended (sheet), blank=other (loop). ".
		"\nPROF: Profile-based neural network prediction originally from HeiDelberg";
    $par{"notation","RI_S"}=       "reliability index for PROFsec prediction (0=lo 9=high). ".
	                           "\nNote: for this presentation strong predictions marked by '*'.";


    $par{"notation","OHELBGT"}=    "observed secondary structure: H=helix, E=extended (sheet), ".
	                           "B=beta-turn, G=3/10 helix, T=turn, blank=other (loop)";
    $par{"notation","PHELBGT"}=    "PROF predicted secondary structure: ".
	                           "H=helix, E=extended (sheet), blank=other (loop). ".
	                           "B=beta-turn, G=3/10 helix, T=turn, blank=other (loop)".
		"\nPROF: Profile-based neural network prediction originally from HeiDelberg";

    $par{"notation","SUBsec"}=     "subset of the PROFsec prediction, for all residues with an ".
	                           "expected average accuracy > 82% (tables in header). ".
				   "\n     NOTE: for this subset the following symbols are used: ".
				   "\n  L: is loop (for which above ' ' is used), ".
				   "\n  ".$par{"riSubSym"}.": means that no prediction is made ".
				   "\nfor this residue, as the reliability is:  Rel < ".$par{"riSubSec"};
    $par{"notation","pH"}=         "'probability' for assigning helix (1=high, 0=low)";
    $par{"notation","pE"}=         "'probability' for assigning strand (1=high, 0=low)";
    $par{"notation","pL"}=         "'probability' for assigning neither helix, nor strand (1=high, 0=low)";

				# solvent accessibility
    $par{"notation","OACC"}=       "observed solvent accessibility in square Angstroem ";
    $par{"notation","OREL"}=       "observed relative solvent accessibility (acc) in 10 states: ".
	"\na value of n (0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % ".
	    "\n(e.g. for n=5: 16-25%).";
    $par{"notation","PACC"}=       "PROF predicted solvent accessibility in square Angstroem ";
    $par{"notation","PREL"}=       "PROF predicted relative solvent accessibility (acc) in 10 states: ".
	"\na value of n (0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % ".
	    "\n(e.g. for n=5: 16-25%). ".
		"\nPROF: Profile-based neural network prediction originally from HeiDelberg";
    $par{"notation","Obe"}=        "observed relative solvent accessibility (acc) in 2 states: ".
	"b=0-".$par{"acc2Thresh"}."% , e= ".$par{"acc2Thresh"}."-100%.";
    $par{"notation","Obie"}=       "observed relative solvent accessibility (acc) in 3 states: ".
	"b=0-9%, i = 9-36%, e = 36-100%.";
    $par{"notation","Pbe"}=        "PROF predicted relative solvent accessibility (acc) in 2 states: ".
	"b=0-".$par{"acc2Thresh"}."%, e= ".$par{"acc2Thresh"}."-100%.";
    $par{"notation","Pbie"}=       "PROF predicted relative solvent accessibility (acc) in 3 states: ".
	"b=0-9%, i = 9-36%, e = 36-100%.";
    $par{"notation","RI_A"}=       "reliability index for PROFacc prediction (0=low to 9=high). ".
	                           "\nNote: for this presentation strong predictions marked by '*'.";
    $par{"notation","SUBacc"}=     "subset of the PROFacc prediction, for all residues with an".
	" expected average correlation > 0.69 (tables in header). ".
	    "\n     NOTE: for this subset the following symbols are used: ".
		"\n  I: is intermediate (for which above ' ' is used), ".
		    "\n  ".$par{"riSubSym"}.": means that no prediction is made for this ".
			"\nresidue, as the reliability is:  Rel < ".$par{"riSubAcc"};

				# membrane helices
    $par{"notation","OMN"}=        "observed membrane helix: M=helical transmembrane region, ".
	"blank=non-membrane";
    $par{"notation","Otop"}=       "observed membrane topology: i=inside, M=membrane, o=outside";
    $par{"notation","OiTo"}=       "observed membrane topology: M=helical transmem".
	                           "brane region, i=inside of membrane, o=outside of membrane";
    $par{"notation","OiMo"}=       "observed membrane topology: M=helical transmem".
	                           "brane region, i=inside of membrane, o=outside of membrane";

    $par{"notation","PMN"}=        "PROF predicted membrane helix: M=helical transmembrane region, ".
	                           "blank=non-membrane. ".
	    "\nPROF: Profile-based neural network prediction originally from HeiDelberg";
    $par{"notation","PRMN"}=       "refined PROF prediction: M=helical transmembrane region, ".
	"blank=non-membrane";
    $par{"notation","PR2MN"}=      "2nd best model for membrane prediction: M=helical transmem-".
	"brane region, blank=non-membrane";
    $par{"notation","Ptop"}=       "PROF predicted membrane topology: i=inside, M=membrane, o=outside";
    $par{"notation","PiTo"}=       "PROF prediction of membrane topology: T=helical transmem".
	"brane region, i=inside of membrane, o=outside of membrane";
    $par{"notation","PiMo"}=       "PROF prediction of membrane topology: M=helical transmem".
	"brane region, i=inside of membrane, o=outside of membrane";
    $par{"notation","RI_M"}=       "reliability index for PROFhtm prediction (0=low to 9=high). ".
	                           "Note: for this presentation strong predictions marked by '*'.";
    $par{"notation","RI_H"}=       "reliability index for PROFhtm prediction (0=low to 9=high). ".
	                           "Note: for this presentation strong predictions marked by '*'.";
    $par{"notation","SUBhtm"}=     "subset of the PROFhtm prediction, for all residues with an ".
	"expected average accuracy > 98% (tables in header).".
	    "\n     NOTE: for this subset the following symbols are used: ".
		"\n  N: is non-membrane region (for which above ' ' is used), ".
		    "\n  ".$par{"riSubSym"}.": means that no prediction is made for this ".
			"\nresidue, as the reliability is:  Rel < ".$par{"riSubHtm"};
    $par{"notation","pM"}=         "'probability' for assigning transmembrane helix";
    $par{"notation","pN"}=         "'probability' for assigning globular region";


    @kwd=sort (keys %par);

    $Ldebug=0;
    $Lverb= 0;
				# ------------------------------
    if ($#ARGV<1 ||		# help
	$ARGV[1]=~/^(def|set|help|\-h)$/){
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName file.rdb'\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
	printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "name of output directory";
	printf "%5s %-15s=%-20s %-s\n","","nres",    "N",       "will print N residues per row ";

#	printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#	printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#	printf "%5s %-15s %-20s %-s\n","","",   "no value","";

	print  "      \n";
	print  "      run options\n";
	printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
	printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
	printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

	print  "      \n";
	print  "      OUTPUT formats\n";
	&asshelp("<ascii|noascii>","write (or not) PROF prediction in ASCII format","ascii");
	&asshelp("<html|nohtml>",  "write (or not) PROF prediction in HTML format", "html");
	&asshelp("<msf|nomsf>",    "write (or not) PROF prediction in MSF format",  "msf");
	&asshelp("<saf|nosaf>",    "write (or not) PROF prediction in SAF format",  "saf");
	&asshelp("<dssp|nodssp>",  "write (or not) PROF prediction in DSSP format", "dssp");
	&asshelp("<casp|nocasp>",  "write (or not) PROF prediction in CASP format", "casp");

#	&asshelp("<|no>","write (or not) PROF prediction in  ","");
#	&asshelp("<|no>","write (or not)  ","");

	print  "      \n";
	print  "      OUTPUT options: HTML\n";
	&asshelp("<scroll|noscroll>","write HTML in one scrollable long line", "scroll");
	printf "%5s %-15s %-s\n"," "," ","NOTE: if 'noscroll' def line length=".$par{'nresPerRow'},"\n";
	printf "%5s %-15s %-s\n"," "," ","      to change give argument 'nres=N'\n";
	&asshelp("<head|nohead>",    "write (or not) header for HTML",         "html_head");
	&asshelp("<body|nobody>",    "write (or not) body for HTML",           "html_body");
	&asshelp("<det|nodet>",      "write (or not) 'detail' row ",           "detail");

	print  "      \n";
	print  "      OUTPUT options: HTML + ASCII\n";
	&asshelp("fileAli=yy.hssp",  "provide alignment file explicitly", " ");

	&asshelp("<normal|nonormal>","write (or not) 'normal' PROF.prof output", "normal");

	&asshelp("<sum|nosum>",      "write (or not) summary about prediction","summary");
	&asshelp("<info|noinfo>",    "write (or not) info about prot asf",     "info");
	&asshelp("<ave|noave>",      "write (or not) info about composition",  "averages");
	&asshelp("<nota|nonota>",    "annotate (or not) meaning of columns" ,  "notation");
	&asshelp("<ali|noali>",      "add (or not) alignment to prediction",   "ali");
	printf "%5s %-15s %-s\n"," "," ","NOTE: this option needs an HSSP alignment as input";
	printf "%5s %-15s %-s\n"," "," ","      assumption HSSP file corresponding to PROF";
	printf "%5s %-15s %-s\n"," "," ","      id'.rdbProf' -> id'.hssp'";

	print  "      \n";
	print  "      OUTPUT options: ASCII\n";
	&asshelp("<hdr|nohdr>",      "write (or not) header with summary info","header");
	&asshelp("<brief|nobrief>",  "write (or not) 'brief' prediction",      "brief");
	&asshelp("<sub|nosub>",      "write (or not) 'subset' row",            "subset");
	&asshelp("<graph|nograph>",  "write (or not) 'ASCII' graphics of PROF", "graph");

	print  "      \n";

	print  "      \n";
	print  "      ----------------------------------------------------------------------\n";
	printf "%5s %-15s %-s\n"," ","NOTE","all these options can be given as a comma ";
	printf "%5s %-15s %-s\n"," ","EASE","separated list, e.g. using the following keyword";
	printf "%5s %-s\n",      " ","ascii,saf,nobrief,graph";
	printf "%5s %-s\n",      " ","casp,casponly";
	print  "      ----------------------------------------------------------------------\n";
	print  "      \n";
	if ($#ARGV < 1){
	    print  "      to see more options and settings, please type:\n";
	    print  "$0 def\n";
	    exit;}
				# --------------------------------------------------
				# continue here only if requested!!!
				# --------------------------------------------------

	print  "      \n";
	if (defined %par && $#kwd > 0){
	    $tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	    $tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	    $tmp2="";
	    foreach $kwd (@kwd){
		next if (! defined $par{$kwd});
		next if ($kwd=~/^\s*$/);
		next if ($kwd=~/^(notation|txt)/);
#		next if ($kwd=~/^(saf|msf|ali|ascii|casp)/);
#		next if ($kwd=~/^(brief|normal|graph|ave|sum|head|subset|detail)/);
		
		if    ($par{$kwd}=~/^\d+$/){
		    $tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
		elsif (length($par{$kwd})>1 && $par{$kwd}=~/^[0-9\.]+$/){
		    $tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
		else {
		    $tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	    } 
	    print $tmp, $tmp2       if (length($tmp2)>1);
	}
	exit;}
				# initialise variables
#    $fhin="FHIN";$fhout="FHOUT";
    $FHTRACE=0;			# avoid warning
    $FHTRACE=$FHTRACE2="STDOUT";
    $#fileIn=0;
				# ------------------------------
				# read command line
    $#formatOutWant=0;
    undef %tmp;
    
    foreach $arg (@ARGV){
#	next if ($arg eq $ARGV[1]);
	if    ($arg=~/^fileOut=(.*)$/)                { 
	    $fileOut=            $1;
	    $fileOut{"generic"}= $fileOut;}
	elsif ($arg=~/^fileOut(Ascii|Msf|Saf|Casp|Dssp|Html)=(.*)$/i) { 
	    $tmp=                $1; 
	    $file=               $2;
	    $tmp=~tr/[A-Z]/[a-z]/;
	    if (! defined $tmp{$tmp}){
		push(@formatOutWant, $tmp);
		$tmp{$tmp}=1;}
	    $par{$tmp}=          1;
	    $fileOut{$tmp}=      $file; }

	elsif ($arg=~/^dirOut=(.*)$/)                 { $par{"dirOut"}=     $1;}

	elsif ($arg=~/^de?bu?g$/)                     { $Ldebug=            1;
							$Lverb=             1;
							$par{"debug"}=      1;
							$par{"verbose"}=    1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)            { $Lverb=             1;}
	elsif ($arg=~/^silent$|^\-s$/)                { $Lverb=             0;}

	elsif ($arg=~/^(is)?list$/i)                  { $LisList=           1;}

	elsif ($arg=~/^ali$/)                         { $par{"ali"}=        1;}

	elsif ($arg=~/^(ascii|saf|msf|dssp|casp)$/)   { $par{$1}=           1;
							if (! defined $tmp{$1}){
							    push(@formatOutWant, $1);
							    $tmp{$1}=1;}
							$par{"ali"}=        1 if ($arg=~/saf|msf/);}
	elsif ($arg=~/^(casponly)$/i)                 { $par{$1}=           1;
							$par{"casp"}=       1;}
	elsif ($arg=~/^no(ascii|saf|msf|dssp|casp)$/) { $par{$1}=          0;}
	
	elsif ($arg=~/^(html|scroll)$/)               { $par{$1}=           1;}
	elsif ($arg=~/^no(html|scroll)$/)             { $par{$1}=           0;}

	elsif ($arg=~/^(info|brief|normal|graph)$/)   { $par{$1}=           1;}
	elsif ($arg=~/^no(info|brief|normal|graph)$/) { $par{$1}=           0;}

	elsif ($arg=~/^(head|body)$/)                 { $par{"html_".$1}=   1; 
							$par{"html"}=       1; 
							if (! defined $tmp{"html"}){
							    push(@formatOutWant, "html");
							    $tmp{"html"}=1;}}
							
	elsif ($arg=~/^no(head|body)$/)               { $par{"html_".$1}=   0; $par{"html"}=1; }

	elsif ($arg=~/^ave$/)                         { $par{"averages"}=   1;}
	elsif ($arg=~/^noave$/)                       { $par{"averages"}=   0;}
	elsif ($arg=~/^hdr$/)                         { $par{"header"}=     1;}
	elsif ($arg=~/^nohdr$/)                       { $par{"header"}=     0;}
	elsif ($arg=~/^sum.*$/)                       { $par{"summary"}=    1;}
	elsif ($arg=~/^nosum$/)                       { $par{"summary"}=    0;}
	elsif ($arg=~/^nota.*$/)                      { $par{"notation"}=   1;}
	elsif ($arg=~/^nonota$/)                      { $par{"notation"}=   0;}
	elsif ($arg=~/^sub$/)                         { $par{"subset"}=     1;}
	elsif ($arg=~/^nosub$/)                       { $par{"subset"}=     0;}
	elsif ($arg=~/^det$/)                         { $par{"detail"}=     1;}
	elsif ($arg=~/^nodet$/)                       { $par{"detail"}=     0;}

	elsif ($arg=~/^nres=(.*)$/)                   { $par{"nresPerRow"}= $1;}

	elsif ($arg=~/^(.*,.*)$/i)                    { $modeWrt=           $1;}
	elsif ($arg=~/^modeWrt=(.*)$/i)               { $modeWrt=           $1;}

	elsif ($arg=~/^ali=(.*)$/i)                   { $fileAli=           $1; 
							$par{"ali"}=        1; }
	elsif ($arg=~/^fileAli=(.*)$/i)               { $fileAli=           $1;
							$par{"ali"}=        1; }
	elsif ($arg=~/^fileHssp=(.*)$/i)              { $fileAli=           $1;
							$par{"ali"}=        1; }

	elsif (-e $arg)                               { push(@fileIn,$arg); }
	else {
	    $Lok=0; 
	    if (defined %par && $#kwd>0) { 
		foreach $kwd (@kwd){ 
		    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					       last;}}}
	    if (! $Lok){ print "*** wrong command line arg '$arg'\n";
			 exit;}}}

    $par{"normal"}=1            if ($par{"ali"} && ! $par{"normal"});

    $fileIn=$fileIn[1];
    die ("*** ERROR $scrName: missing input $fileIn\n") 
	if (! -e $fileIn);
				# ------------------------------
				# build up mode
    $modeWrt="";
    foreach $kwd ("ascii","dssp","msf","saf","casp"){
	$par{$kwd}=0            if ($par{"casponly"} && $kwd ne "casp");
	$modeWrt.=$kwd.","      if ($par{$kwd});
    }
    $par{"html"}=0              if ($par{"casponly"});

    foreach $kwd (
		  "header","summary","info","notation","averages","summary",
		  "brief","normal","graph","detail","subset",
		  "ali","scroll",  
		  ){
	$par{$kwd}=0            if ($par{"casponly"});
	if ($par{$kwd}){
	    $modeWrt.=$kwd.",";
	    if ($par{"html"} && $kwd =~ /(brief|normal|detail)/){
		$modeWrt.="data:".$1.",";
	    }
	}
    }
				# HTML specific
    foreach $kwd (
		  "head","body"
		  ){
	$modeWrt.="html:".$kwd.",";
    }

				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" );
	$par{$kwd}.="/"          if ($par{$kwd} !~ /\/$/);
	if ($kwd=~/dirOut/ && 
	    (! -d $par{$kwd} || ! -l $par{$kwd})){
	    $dir=$par{$kwd};
	    $dir=~s/\/$//g;
	    system("mkdir $dir");}}

				# ------------------------------
				# digest file (list?)
				# ------------------------------
    $#fileTmp=0;
    foreach $fileIn (@fileIn){
	if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	    ($Lok,$msg,$file,$tmp)=
		&fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
						  exit; }
	    @tmpf=split(/,/,$file); 
	    push(@fileTmp,@tmpf);
	    next;}
	push(@fileTmp,$fileIn);
    }
    @fileIn= @fileTmp;
    $#fileTmp=0;		# slim-is-in

				# ------------------------------
				# separate alignment from PROFrdb
				# ------------------------------
    $#fileTmp=0;
    foreach $file (@fileIn){
	if    ($#fileIn==1 && defined $fileAli){
	    $id=$file; 
	    $id=~s/^.*\///g;
	    $id=~s/$par{"extHssp"}//g;
	    $id=~s/\.[^\.]*$//g;
	    $par{"ali"}=1;
	    $fileAli{$id}=$fileAli;
	    push(@fileTmp,$file);}
	elsif ($file =~ /$par{"extHssp"}/){
	    $id=$file; 
	    $id=~s/^.*\///g;	 # purge dir
	    $id=~s/$par{"extHssp"}//g;
	    $id=~s/\.[^\.]*$//g; # purge extension
	    $par{"ali"}=1;
	    $fileAli{$id}=$file;}
	else {
	    push(@fileTmp,$file);}
    }
    @fileIn=@fileTmp;
    $#fileTmp=0;

    if ($par{"ali"} && $modeWrt !~ /ali,|,ali|^ali$/){
	if (! $par{"normal"}){
	    $par{"normal"}=1;
	    $modeWrt.="normal,";}
	$modeWrt.="ali,";}
    return(1,"ok $sbrName");
}				# end of ini

#==============================================================================
# library collected (begin) lllbeg
#==============================================================================


#===============================================================================
sub asshelp    {
    local($kwd,$txt,$kwddef) = @_ ;
#-------------------------------------------------------------------------------
#   asshelp                     formats help
#-------------------------------------------------------------------------------
    if (! defined $par{$kwddef}){
	printf "%5s %-15s %-s\n","",$kwd,$txt;
    }
    else {
	printf "%5s %-15s %-s (def=%-s)\n","",$kwd,$txt,$par{$kwddef};
    }
}				# end of asshelp

#===============================================================================
sub bynumber2 { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg


#===============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digit     project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
				# SQRT
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

#===============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

#==============================================================================
sub getFileFormatQuick {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormatQuick          quick scan for file format: assumptions
#                               file exists
#                               file is db format (i.e. no list)
#       in:                     file
#       out:                    0|1,format
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."getFileFormatQuick";$fhinLoc="FHIN_"."getFileFormatQuick";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # alignments (EMBL 1)
    return(1,"HSSP")         if (&is_hssp($fileInLoc));
    return(1,"STRIP")        if (&is_strip($fileInLoc));
#    return(1,"STRIPOLD")     if (&is_strip_old($fileInLoc));
    return(1,"DSSP")         if (&is_dssp($fileInLoc));
    return(1,"FSSP")         if (&is_fssp($fileInLoc));
                                # alignments (EMBL 1)
    return(1,"DAF")          if (&isDaf($fileInLoc));
    return(1,"SAF")          if (&isSaf($fileInLoc));
                                # alignments other
    return(1,"MSF")          if (&isMsf($fileInLoc));
    return(1,"FASTAMUL")     if (&isFastaMul($fileInLoc));
    return(1,"PIRMUL")       if (&isPirMul($fileInLoc));
                                # sequences
    return(1,"FASTA")        if (&isFasta($fileInLoc));
    return(1,"SWISS")        if (&isSwiss($fileInLoc));
    return(1,"PIR")          if (&isPir($fileInLoc));
    return(1,"GCG")          if (&isGcg($fileInLoc));
    return(1,"PDB")          if (&isPdb($fileInLoc));
                                # PP
    return(1,"PPCOL")        if (&is_ppcol($fileInLoc));
				# NN
    return(1,"NNDB")         if (&is_rdb_nnDb($fileInLoc));
                                # PROF
    return(1,"PROFRDBBOTH")   if (&isProfBoth($fileInLoc));
    return(1,"PROFRDBACC")    if (&isProfAcc($fileInLoc));
    return(1,"PROFRDBHTM")    if (&isProfHtm($fileInLoc));
    return(1,"PROFRDBHTMREF") if (&is_rdb_htmref($fileInLoc));
    return(1,"PROFRDBHTMTOP") if (&is_rdb_htmtop($fileInLoc));
    return(1,"PROFRDBSEC")    if (&isProfSec($fileInLoc));
                                # RDB
    return(1,"RDB")          if (&isRdb($fileInLoc));
    return(1,"unk");
}				# end of getFileFormatQuick

#==============================================================================
sub getFileFormatQuicker {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormatQuicker        quicker scan for file format: assumptions
#       out ???:                <unk>
#       out ali:                <HSSP|MSF|SAF|DAF|FASTAMUL|PIRMUL|>
#       out seq:                <FASTA|PIR|SWISS|GCG|DSSP|FSSP|PDB|>
#       out seq:                SEQ=single one-letter sequence
#       out prof:                <PPCOL|NNDB|PROF2PARA>
#       out prof:                <PROFRDBBOTH|PROFRDBACC|PROFRDBSEC|PROFRDBHTM|PROFRDBHTMREF|PROFRDBTOP>
#       out file:               RDB
#       in:                     file
#       out:                    0|1,format:
#                         
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."getFileFormatQuicker";$fhinLoc="FHIN_"."getFileFormatQuicker";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return("*** ERROR $sbrName: failed opening filein=$fileInLoc");
				# read first 50 lines
    $#tmp=0;
    while(<$fhinLoc>){ $_=~s/\n//g;
		       push(@tmp,$_);
		       ++$ct;
		       last if ($ct>10); }
    close($fhinLoc);
				# ------------------------------
				# now test 
				# ------------------------------
                                # alignments (EMBL 1)
    return(1,"HSSP")            if ($tmp[1]=~/^HSSP/);
    return(1,"STRIP")           if ($tmp[1]=~/===  MAXHOM-STRIP  ===/);
    return(1,"DSSP")            if ($tmp[1]=~/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i);
    return(1,"FSSP")            if ($tmp[1]=~/^FSSP/);
	
				# ------------------------------
                                # alignments (EMBL 2)
    return(1,"DAF")             if ($tmp[1]=~/^\#\s*DAF/);
    return(1,"SAF")             if ($tmp[1]=~/^\#\s*SAF/);
    return(1,"SAF")             if ($tmp[1]=~/clustalW/i);

				# ------------------------------
                                # alignments other
    return(1,"MSF")             if ($tmp[1]=~/pileup/i);
    return(1,"MSF")             if ($tmp[1]=~/\s*MSF[\s:]+/);
    
				# ------------------------------
				# fasta
    if ($tmp[1]=~/^\s*\>\s*\w+/ && $tmp[2]=~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i){
	$ct=1;
	foreach $it (3..$#tmp){
	    if ($tmp[$it]=~/^\s*\>\s*\w+/){
		++$ct;
		last;}}
	return(1,"FASTAMUL")    if ($ct>1);
	return(1,"FASTA");}
				# ------------------------------
				# PIR: strict old definition
    if ($tmp[1]=~/^\s*\>P\d?\s*\;/    && 
	$tmp[3]=~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i){
	$ct=1;
	foreach $it (3..$#tmp){
	    if ($tmp[$it]=~/^\s*\>P\d?\s*\;/    && 
		$tmp[$it+2]=~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i){
		++$ct;
		last;}}
	return(1,"PIRMUL")      if ($ct>1);
	return(1,"PIR");}

				# ------------------------------
                                # sequences
    return(1,"SWISS")           if ($tmp[1]=~/^ID   /);
    return(1,"PDB")             if ($tmp[1]=~/HEADER\s+.*\d\w\w\w\s+\d+\s*$/);

				# ------------------------------
				# br stuff
                                # PP
    return(1,"PPCOL")           if ($tmp[1]=~/^\#\s*pp.*col/i);
				# NN
    return(1,"NNDB")            if ($tmp[1]=~/^\#\s*Perl-RDB.*NNdb/i);
    return(1,"NNJCT")           if ($tmp[1]=~/^\*\s*NNout_jct/);
                                # PROF
    return(1,"PROF2PARA")        if ($tmp[1]=~/PROF\d*\s+PARA/);
    if ($tmp[1]=~/^\#?\s*Perl-RDB/){
	return(1,"PROFRDBBOTH")  if ($tmp[2]=~/PROFacc/i && $tmp[2]=~/PROFsec/i );
	return(1,"PROFRDBACC")   if ($tmp[2]=~/PROFacc/i );
	return(1,"PROFRDBHTM")   if ($tmp[2]=~/PROFhtm/i );
	return(1,"PROFRDBHTMREF")if ($tmp[2]=~/^\#\s*PROF\s*htm.*ref/ );
	return(1,"PROFRDBHTMTOP")if ($tmp[2]=~/^\#\s*PROF\s*htm.*top/ );
	return(1,"PROFRDBSEC")   if ($tmp[2]=~/PROFsec/i );
                                # RDB
	return(1,"RDB");}
				# ------------------------------
				# GCG
    return(1,"GCG")             if (&isGcgArray(@tmp));
    
				# ------------------------------
				# PIR: new
    if ($tmp[1]=~/^\s*\>\s*/    && 
	$tmp[3]=~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i){
	$ct=1;
	foreach $it (3..$#tmp){
	    if ($tmp[$it]=~/^\s*\>\s*/    && 
		$tmp[$it+2]=~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i){
		++$ct;
		last;}}
	return(1,"PIRMUL")      if ($ct>1);
	return(1,"PIR");}
				# ------------------------------
				# simple one-letter coded sequence
    return(1,"SEQ")             if (&isSeqArray(@tmp));

    return(1,"unk");
}				# end of getFileFormatQuicker

#===============================================================================
sub getSegment {
    local($stringInLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSegment                  takes string, writes segments and boundaries
#       in:                     $stringInLoc=  '  HHH  EE HHHHHHHHHHH'
#       out:                    1|0,msg, 
#       out GLOBAL:             %segment (as reference!)
#                               $segment{"NROWS"}=   number of segments
#                               $segment{$it}=       type of segment $it (e.g. H)
#                               $segment{"beg",$it}= first residue of segment $it 
#                               $segment{"end",$it}= last residue of segment $it 
#                               $segment{"ct",$it}=  count segment of type $segment{$it}
#                                                    e.g. (L)1,(H)1,(L)2,(E)1,(H)2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."getSegment";
    $fhinLoc="FHIN_"."getSegment";$fhoutLoc="FHOUT_"."getSegment";
				# check arguments
    return(&errSbr("not def stringInLoc!"))          if (! defined $stringInLoc);
    return(&errSbr("too short stringInLoc!"))        if (length($stringInLoc)<1);

				# set zero
    $prev=""; 
    undef %segment;  
    undef %ctSegment;
    $ctSegment=0; 
				# into array
    @tmp=split(//,$stringInLoc);
    foreach $it (1..$#tmp) {	# loop over all 'residues'
	$sym=$tmp[$it];
				# continue segment
	next if ($prev eq $sym);
				# finish off previous
	$segment{"end",$ctSegment}=($it-1)
	    if ($it > 1);
				# new segment
	$prev=$sym;
	++$ctSegment;
	++$ctSegment{$sym};
	$segment{$ctSegment}=      $sym;
	$segment{"beg",$ctSegment}=$it;
	$segment{"seg",$ctSegment}=$ctSegment{$sym};
    }
				# finish off last
    $segment{"end",$ctSegment}=$#tmp;
				# store number of segments
    $segment{"NROWS"}=$ctSegment;

    $#tmp=0;			# slim-is-in
    return(1,"ok");
}				# end of getSegment

#===============================================================================
sub hsspRd {
    local ($fileInLoc,$kwdInLoc) = @_ ;
    local ($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd                       
#       in:                     $fileHssp (must exist), 
#       in:                     $kwdInLoc:  default keywords separated by comma, also
#       in:           kwd=~/nohead/     surpresses reading header information
#       in:           kwd=~/nopair/     surpresses reading pair information
#       in:           kwd=~/noseq/      surpresses reading sequence
#       in:           kwd=~/nosec/      surpresses reading secondary structure
#       in:           kwd=~/noacc/      surpresses reading accessibility
#       in:           kwd=~/noali/      surpresses reading alignments
#       in:           kwd=~/noalifill/  surpresses writing full aligned sequences (no ins!)
#       in:           kwd=~/chn=A,B/    read chains A,B
#       in:           kwd=~/ali=1-5,7/   read alis of seq1-5 and 7
#       in:           kwd=~/ali=id1,id2/ read alis of id1 and id2 (note: no '-' here!)
#       in:           kwd=~/noprof/     surpresses reading profiles
#       in:           kwd=~/no/ surpresses reading of  information
#       in:           kwd=~/no/ surpresses reading of  information
#       in GLOBAL:              from hsspRd_ini:
#       in GLOBAL:              %hsspRd_ini
#       in GLOBAL:              @hsspRd_iniKwdHdr,@hsspRd_iniKwdPair,
#       in GLOBAL:              @hsspRd_iniKwdAli,
#                               
#       out GLOBAL:   %hssp:
#                     $hssp{$kwd}          for all keywords in HEADER (@hsspRd_iniKwdHdr)
#                     $hssp{$kwd,$ctali}   for all pair keywords, data for ali no $ctali
#                     $hssp{'[chain|seq|sec|acc]',$ctres} 
#                     $hssp{'chain'}        e.g. A,B,
#                     $hssp{'chain',$chain,'beg'} first residue of chain $chain
#                     $hssp{'chain',$chain,'end'} last residue of chain $chain
#                     $hssp{'ali',  $numali,$ctres} residue aliged at $ctres residue for ali=$numali
#                               NOTE: can be more than one residue for insertions!
#                     $hssp{'prof',$kwd,$ctres} kwd like in PROF (@hsspRd_iniKwdProf)
#                     $hssp{'fin',$numali}= full sequence (NOTE: guide=$numali=0)          
#                               
#                               
#                               
#         special               ID=ID1, $rd{"kwd",$it} existes for ID1 and ID2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR2=$tmp."hsspRd";
    $fhinLoc="FHIN_"."hsspRd";$fhoutLoc="FHOUT_"."hsspRd";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR2))     if (! defined $fileInLoc);
    $kwdInLoc=0                                     if (! defined $kwdInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!",$SBR2))  if (! -e $fileInLoc);

				# ------------------------------
				# initialis pointers and keywords
    $Lok=1;
    ($Lok,$msg)=
	&hsspRd_ini()           if (! defined %hsspRd_ini);
    return(&errSbr("failed in hsspRd_ini \n".$msg,$SBR2)) if (! $Lok);
    
				# ------------------------------
				# check input arguments
    $LnoHead=$LnoPair=$LnoAli=$LnoProf=$LnoIns=0;
    $LnoHead=1                  if ($kwdInLoc && $kwdInLoc=~/nohead/);
    $LnoPair=1                  if ($kwdInLoc && $kwdInLoc=~/nopair/);
    $LnoAli= 1                  if ($kwdInLoc && $kwdInLoc=~/noali/);
    $LnoSeq= 1                  if ($kwdInLoc && $kwdInLoc=~/noseq/);
    $LnoSec= 1                  if ($kwdInLoc && $kwdInLoc=~/nosec/);
    $LnoAcc= 1                  if ($kwdInLoc && $kwdInLoc=~/noacc/);
    $LnoProf=1                  if ($kwdInLoc && $kwdInLoc=~/noprof/);
    $LnoIns=1                   if ($kwdInLoc && $kwdInLoc=~/noins/);
    $LnoAliFill=1               if ($kwdInLoc && $kwdInLoc=~/noalifill/);

				# conflicting stuff
    $LnoSeq=0                   if (! $LnoAliFill && $LnoSeq);

				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened",$SBR2));
    undef %hssp;
    undef %tmp;
    undef %tmp_chain            if (defined %tmp_chain);
				# ------------------------------------------------------------
				# read header
				# note: all variable global!
				# ------------------------------------------------------------
    ($Lok,$msg)=
	&hsspRd_head();         return(&errSbr("file=$fileInLoc: problem with hsspRd_head:".
					       $msg."\n",$SBR2)) if (! $Lok);

				# ------------------------------------------------------------
				# read pairs
				# note: all variable global!
				# ------------------------------------------------------------
    ($Lok,$msg)=
	&hsspRd_pair();         return(&errSbr("file=$fileInLoc: problem with hsspRd_pair:".
					       $msg."\n",$SBR2)) if (! $Lok);

				# ------------------------------------------------------------
				# read alignments
				# ------------------------------------------------------------

				# digest what to read
    undef %tmp;
				# in  GLOBAL: $hssp{"ali",$num}
				# out GLOBAL: $tmp{"chain",$chain}=1 -> read chain, undefined else
				# out GLOBAL: $tmp{"ali",$num}=1     -> read protein, undefined else
				# out GLOBAL: @wantNum=   numbers for alignments to read
				# out GLOBAL: @wantBlock= num of blocks with alignments to read
    ($Lok,$msg)=
	&hsspRd_aliPre();       return(&errSbr("file=$fileInLoc: problem with hsspRd_aliPre:".
					       $msg."\n",$SBR2)) if (! $Lok);

				# finally go off reading
				# in GLOBAL: $tmp{"chain",$chain}=1 -> read chain, undefined else
				# in GLOBAL: $tmp{"ali",$num}=1     -> read protein, undefined else
				# in GLOBAL: @wantNum=   numbers for alignments to read
				# in GLOBAL: @wantBlock= num of blocks with alignments to read
    ($Lok,$msg)=
	&hsspRd_ali();          return(&errSbr("file=$fileInLoc: problem with hsspRd_ali:".
					       $msg."\n",$SBR2)) if (! $Lok);

    $#exclLoc=0;		# correct number of alis for chains 
				#    see end of routine

    if (! $LnoAli){		# correct missing parts
	foreach $itali (1..$hssp{"NALIGN"}){
	    $tmp="";
	    foreach $it (1..$hssp{"ali","numres"}){
		if    (! defined $hssp{"ali",$itali,$it}){
		    $hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		elsif ($hssp{"ali",$itali,$it} eq " "){
		    $hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		$tmp.=$hssp{"ali",$itali,$it};
	    }
				# not aligned to chain
	    $exclLoc[$itali]=1
		if (($hsspRd_ini{"symbolInsertion"} eq "." && $tmp=~/^\.+$/) ||
		    ($hsspRd_ini{"symbolInsertion"} ne "." && 
		     $tmp=~/^$hsspRd_ini{"symbolInsertion"}+$/));
	}}
				# ------------------------------------------------------------
				# read profiles
				# ------------------------------------------------------------
    ($Lok,$msg,$LisEOF)=
	&hsspRd_prof();         return(&errSbr("file=$fileInLoc: problem with hsspRd_prof:".
					       $msg."\n",$SBR2)) if (! $Lok);
				# ------------------------------------------------------------
				# read insertions
				# ------------------------------------------------------------
    if (! $LnoIns){
	($Lok,$msg,@insMax)=
	    &hsspRd_ins();      return(&errSbr("file=$fileInLoc: problem with hsspRd_ins:".
					       $msg."\n",$SBR2)) if (! $Lok);
    }

    close($fhinLoc);		# finally close the file

				# ------------------------------------------------------------
				# fill in insertions asf
				# ------------------------------------------------------------
    if (! $LnoIns && ! $LnoAli && $#wantNum){
	($Lok,$msg)=
	    &hsspRd_fill(@insMax); return(&errSbr("file=$fileInLoc: problem with hsspRd_fill:".
						  $msg."\n",$SBR2)) if (! $Lok);
    }

				# ------------------------------
				# which alis wanted?
				# ------------------------------
    if (! $LnoAli && $#wantNum){
	$hssp{"ali","numbers_wanted"}="";
	foreach $numAli (@wantNum){
	    $hssp{"ali","numbers_wanted"}.=$numAli.",";
	}
	$hssp{"ali","numbers_wanted"}=~s/,*$//g;
    }
				# --------------------------------------------------
				# correct number of alis if chain to be read
				# --------------------------------------------------
				# correct alignment (for chains)
    if ($#exclLoc>=1){
	$ctali=0;
				# pair info
	foreach $itali (1..$hssp{"NALIGN"}){
	    next if (defined $exclLoc[$itali]);
	    ++$ctali;
				# pair info
	    if (! $LnoPair){
		foreach $kwd (@hsspRd_iniKwdPair){
		    $hssp{$kwd,$ctali}=$hssp{$kwd,$itali};}}
				# ali info
	    if (! $LnoAli){
		foreach $kwd ("ali"){
		    foreach $itres (1..$hssp{"ali","numres"}){
			$hssp{$kwd,$ctali,$itres}=$hssp{$kwd,$itali,$itres};}}}
				# fill 
	    if (! $LnoAliFill){
		foreach $kwd ("fin"){
		    $hssp{$kwd,$ctali}=$hssp{$kwd,$itali};}}
	}
				# CHANGE number of alis!!!
	$hssp{"numali"}=$hssp{"NALIGN"}=$ctali;
    }
				# clean up
    $#wantNum=$#wantBlock=$#wantNumLoc=
	$#insMax=$#tmp=0;	# slim-is-in

    return(1,"ok $SBR2");
}				# end of hsspRd

#===============================================================================
sub hsspRd_ini {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($SBR3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_ini                  initialises stuff necessary to read HSSP
#       out GLOBAL:             %hsspRd_ini
#       out GLOBAL:             @hsspRd_iniKwdHdr,@hsspRd_iniKwdPair,
#       out GLOBAL:             @hsspRd_iniKwdAli,@hsspRd_iniKwdPair,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."hsspRd_ini";

    undef %hsspRd_ini;
				# settings describing format HEADER
    @hsspRd_iniKwdHdr= 
	(
	 "PDBID","DATE","SEQBASE","PARAMETER","THRESHOLD",
	 "REFERENCE","HEADER","COMPND","SOURCE","AUTHOR",
	 "SEQLENGTH","NCHAIN","KCHAIN","NALIGN"
	 );
    foreach $kwd (@hsspRd_iniKwdHdr){
	$hsspRd_ini{"head",$kwd}=1;
    }
    
				# HEADER pair information
    @hsspRd_iniKwdPair= 
	(
	 "NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
	 "JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN"
	 );
    foreach $kwd (@hsspRd_iniKwdPair){
	$hsspRd_ini{"pair",$kwd}=1;
    }
				# ALI information
    @hsspRd_iniKwdAli= 
	(
	 "PDBNo","SeqNo","chain","seq","sec","acc","ali"
	 );
    foreach $kwd (@hsspRd_iniKwdAli){
	$hsspRd_ini{"ali",$kwd}=1;
    }
				# PROF information
    @hsspRd_iniKwdProf= 
	(
#	 "SeqNo","PDBNo",
	 "V","L","I","M","F","W","Y","G","A","P",
	 "S","T","C","H","R","K","Q","E","N","D",
	 "NOCC","NDEL","NINS","ENTROPY","RELENT","WEIGHT"
	 );
    foreach $kwd (@hsspRd_iniKwdProf){
	$hsspRd_ini{"prof",$kwd}=1;
    }


    $hsspRd_ini{"regexpBegPair"}=   "^\#\# PROTEINS";           # begin of reading 
    $hsspRd_ini{"regexpEndPair"}=   "^\#\# ALIGNMENTS";         # end of reading

    $hsspRd_ini{"regexpLongId"}=    "^PARAMETER  LONG-ID :YES"; # identification of long id

    $hsspRd_ini{"regexpBegAli"}=    "^\#\# ALIGNMENTS";         # begin of reading
    $hsspRd_ini{"regexpEndAli"}=    "^\#\# SEQUENCE PROFILE";   # end of reading
    $hsspRd_ini{"regexpSkip"}=      "^ SeqNo";                  # skip lines with pattern
    $hsspRd_ini{"nmaxBlocks"}=      100;	                # maximal number of blocks considered (=7000 alis!)
    $hsspRd_ini{"regexpProfNames"}= "^ SeqNo";                  # lines with description of profile columns 
    $hsspRd_ini{"nmaxRes"}=       10000;	                # maximal number of residues (only if ONLY prof to read)

    $hsspRd_ini{"regexpBegIns"}=    "^\#\# INSERTION LIST";     # begin of reading insertion list
    $hsspRd_ini{"regexpInsNames"}=  "^ AliNo  IPOS";            # lines with description of profile columns 

    $hsspRd_ini{"regexpEndIns"}=    "^\/\/";                    # end of reading insertion list
    

    $hsspRd_ini{"lenStrid"}=          4;	# minimal length to identify PDB identifiers
    $hsspRd_ini{"LisLongId"}=         0;	# long identifier names

    $hsspRd_ini{"symbolInsertion"}= ".";        # symbol used for insertions

				# pointers
    $hsspRd_ini{"ptr","IDE"}=       1;
    $hsspRd_ini{"ptr","WSIM"}=      2;
    $hsspRd_ini{"ptr","IFIR"}=      3;
    $hsspRd_ini{"ptr","ILAS"}=      4;
    $hsspRd_ini{"ptr","JFIR"}=      5;
    $hsspRd_ini{"ptr","JLAS"}=      6;
    $hsspRd_ini{"ptr","LALI"}=      7;
    $hsspRd_ini{"ptr","NGAP"}=      8;
    $hsspRd_ini{"ptr","LGAP"}=      9;
    $hsspRd_ini{"ptr","LSEQ2"}=    10;
    $hsspRd_ini{"ptr","ACCNUM"}=   11;
    $hsspRd_ini{"ptr","PROTEIN"}=  12;

    $hsspRd_ini{"ptr","SeqNo"}=     1;
    $hsspRd_ini{"ptr","PDBNo"}=     7;
    $hsspRd_ini{"ptr","chain"}=    13;
    $hsspRd_ini{"ptr","seq"}=      15;
    $hsspRd_ini{"ptr","sec"}=      18;
    $hsspRd_ini{"ptr","acc"}=      37;
    $hsspRd_ini{"ptr","ali"}=      52;

    $hsspRd_ini{"ptr","prof"}=     14;
    $hsspRd_ini{"ptr","profchain"}=12;

    $hsspRd_ini{"ptr","ins","alino"}=1;
    $hsspRd_ini{"ptr","ins","ipos"}= 2;
    $hsspRd_ini{"ptr","ins","jpos"}= 3;
    $hsspRd_ini{"ptr","ins","len"}=  4;
    $hsspRd_ini{"ptr","ins","seq"}=  5;


    $modeSec="HETL";
    $modeSec=$par{"modeSec"} if (defined $par{"modeSec"});

    return(1,"ok $SBR3");
}				# end of hsspRd_ini

#===============================================================================
sub hsspRd_debug {
    local($modeDebugLoc)=@_;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_debug             writes debug and dies
#       in:                     $modeDebugLoc=[all|head|pair|seq|ali|prof|ins|nfar]
#                                           if any set: will write info, and stop!
#       in GLOBAL:              ALL (%hssp= results)
#       out GLOBAL:             ALL
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5="hsspRd_debug";
    if ($modeDebugLoc && $modeDebugLoc=~/head/){
	foreach $kwd (@hsspRd_iniKwdHdr){
	    print $FHTRACE2 "dbg $SBR5: $kwd=",$hssp{$kwd},"\n";
	}}
    if ($modeDebugLoc && $modeDebugLoc=~/pair/){
	foreach $it (1..$hssp{"NALIGN"}){
	    printf "dbg $SBR5: %3d ",$it;
	    foreach $kwd (@hsspRd_iniKwdPair){
		if (! defined $hssp{$kwd,$it}){
		    print $FHTRACE2 "-*- WARN not defined it=$it, kwd=$kwd\n";
		    next;}
		print $FHTRACE2 $hssp{$kwd,$it}," ";
	    }
	    print $FHTRACE2 "\n";
	}}
    if ($modeDebugLoc && $modeDebugLoc=~/ali/){
	print $FHTRACE2 "dbg $SBR5:seq,sec,acc\n";
	foreach $it(1..$hssp{"SEQLENGTH"}){
	    foreach $kwd (@hsspRd_iniKwdAli){
		next if ($kwd eq "ali");
		next if ($kwd eq "seq" && $LnoSeq);
		next if ($kwd eq "sec" && $LnoSec);
		next if ($kwd eq "acc" && $LnoAcc);
		print $FHTRACE2 $hssp{$kwd,$it},"\t";
	    }
	    print"\n";
	}
	if (! $LnoAli){
	    print $FHTRACE2 "dbg $SBR5:ali\n";
	    foreach $itali (1..$hssp{"NALIGN"}){
		$seq="";
		foreach $it (1..$hssp{"ali","numres"}){
		    if    (! defined $hssp{"ali",$itali,$it}){
			$hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		    elsif ($hssp{"ali",$itali,$it} eq " "){
			$hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		    $seq.=$hssp{"ali",$itali,$it};
		}
		printf "dbg %3d %-s\n",$itali,substr($seq,1,80);}
	    print $FHTRACE2 "dbg $SBR5: seq restricted to 80 residues!\n";
	}}
    
    if ($modeDebugLoc && $modeDebugLoc=~/prof/){
	print $FHTRACE2 "dbg $SBR5:prof\n";
	foreach $itRes (1..$hssp{"ali","numres"}){
	    printf "dbg: %4d prof:",$itRes;
	    foreach $kwd (@hsspRd_iniKwdProf){
		$tmp=3; $tmp=1+length($hssp{"prof",$kwd,$itRes}) if (length($hssp{"prof",$kwd,$itRes})>3);
		printf "%".$tmp."s",$hssp{"prof",$kwd,$itRes};}
	    print $FHTRACE2 "\n";
	}}

    if ($modeDebugLoc && $modeDebugLoc=~/ins/){
	print $FHTRACE2 "dbg $SBR5:ins\n";
	foreach $itali (1..$hssp{"NALIGN"}){
	    $seq="";
	    foreach $it (1..$hssp{"ali","numres"}){
		if    (! defined $hssp{"ali",$itali,$it}){
		    $hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		elsif ($hssp{"ali",$itali,$it} eq " "){
		    $hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		$seq.=$hssp{"ali",$itali,$it};
	    }
	    printf "dbg %3d %-s\n",$itali,substr($seq,1,80);}
	print $FHTRACE2 "dbg $SBR5: seq restricted to 80 residues!\n"; }

    if ($modeDebugLoc && $modeDebugLoc=~/nfar/){
	print $FHTRACE2 "dbg $SBR5: nfar ($distCount,$distCountMode) ndist=",$hssp{"ndist"},",\n";
	if (! defined $distCount || ! defined $distCountMode){
	    print "*** ERROR $SBR5: missing distCount=$distCount, or distCountMode=$distCountMode\n";
	    exit;}
	foreach $tmp (@tmpChain){
	    print $FHTRACE2 "dbg $SBR5: chain=$tmp, number of members=",$hssp{"ndist",$tmp},"\n";
	}}

    if ($modeDebugLoc && $modeDebugLoc=~/fill/){
	print $FHTRACE2 "dbg $SBR5:fill\n";
	foreach $itali (0..$hssp{"NALIGN"}){
	    printf "dbg %3d %-s\n",$itali,substr($hssp{"fill",$itali},1,80);
	}}

    return(1,"ok $SBR5");
}				# end of hsspRd_debug

#===============================================================================
sub hsspRd_getNfar {
    local($distLoc,$distModeLoc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_getNfar              
#       in:                     $chainInLoc  : chain to read
#                                   '*' for omitting the test
#       in:                     $distLoc     : limiting distance from HSSP (new Ide)
#                                   '0' in NEXT variable for omitting the test
#       in:                     $chainInLoc:  current chain
#       in:                     $distModeLoc: [gt|ge|lt|le]: if mode=gt: all with
#                                             dist > distLoc counted
#                                   '0' for omitting the test
#       in GLOBAL:              ALL (%hssp= results)
#       out GLOBAL:             ALL
#       in:                     $fileInLoc
#       out:                    1|0,msg,$num,$take:
#                               $num= number of alis in chain and below $distLoc
#                               $take='n,m,..': list of pairs ok
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_getNfar";

				# ------------------------------
				# get chains
    $take="";
    if ($Lchain){
	$tmp=$hssp{'chain'};
	$tmp=~s/,*$//g;
	$tmp=~s/\s//g;
	@tmpChain=split(/,/,$tmp);}
    else {
	@tmpChain=("*");
    }
				# --------------------------------------------------
				# get number of distant alignments
				# --------------------------------------------------
    foreach $chainInLoc (@tmpChain){
	next if (length($chainInLoc)<1);
	foreach $itali (1..$hssp{"pair","numali"}){
				# ------------------------------
				# (1) is it aligned to chain?
	    next if ($Lchain &&
		     (($hssp{"IFIR",$itali} > $hssp{"chain",$chainInLoc,"endSeqNo"}) ||
		      ($hssp{"ILAS",$itali} < $hssp{"chain",$chainInLoc,"begSeqNo"}) ));
				# ------------------------------
				# (2) is it correct distance?
	    if ($distModeLoc){
		$lali= $hssp{"LALI",$itali}; 
		$pide= 100*$hssp{"IDE",$itali};
		return(&errSbr("distModeLoc=$distModeLoc, pair=$itali, no lali|ide ($lali,$pide)",$SBR3))
		    if (! defined $lali || ! defined $pide);
                                # compile distance to HSSP threshold (new)
		($pideCurve,$msg)= 
		    &getDistanceNewCurveIde($lali);
		return(&errSbrMsg("failed on getDistanceNewCurveIde($lali)\n".$msg."\n",$SBR3))
		    if (! $pideCurve && ($msg !~ /^ok/));
	    
		$dist=$pide-$pideCurve;
				# mode
		next if (($distModeLoc eq "gt" && $dist <= $distLoc) ||
			 ($distModeLoc eq "ge" && $dist <  $distLoc) ||
			 ($distModeLoc eq "lt" && $dist >= $distLoc) ||
			 ($distModeLoc eq "le" && $dist >  $distLoc)); }
				# ------------------------------
				# (3) ok, take it
	    $take.="$itali,"; 
	}

	$num=0;
	if ($take=~/,/){
	    $take=~s/^,*|,*$//g;
	    @tmp=split(/,/,$take);
	    $num=$#tmp;}
	$hssp{"ndist",$chainInLoc}= $num;
	$hssp{"ndist"}=             0 if (! defined $hssp{"ndist"});
	$hssp{"ndist"}+=            $num;
    }

    undef @tmp;		# slim-is-in!

    return(1,"ok $SBR3");
}				# end of hsspRd_getNfar

#===============================================================================
sub hsspRd_head {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_head                 read section with HEADER info
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_head";
				# ------------------------------------------------------------
				# read header
				# ------------------------------------------------------------
    $ctRd=0;			# force reading "NALIGN" "SEQLENGTH"
    $ctMinRead=2;
    $hsspRd_ini{"head","SEQLENGTH"}=1;
    $hsspRd_ini{"head","NALIGN"}=   1;

    while ( <$fhinLoc> ) {
				# finish this part if pairs start
	last if ($_=~ /$hsspRd_ini{"regexpBegPair"}/); 
				# skip reading
	next if ($LnoHead && $ctRd < $ctMinRead);
	chop; $line=$_;
	$kwd=$_; $kwd=~s/^(\S+)\s+(.*)$/$1/;
	undef $remain;
	$remain=$2              if (defined $2);
				# line to read
	if (defined $hsspRd_ini{"head",$kwd}){
	    next if (! defined $remain);
	    $tmp=$remain;
	    $tmp=~s/^\s*|\s*$//g;
				# purge non digits
	    if ($kwd=~/SEQLENGTH/ ||
		$kwd=~/NCHAIN/ ||
		$kwd=~/NALIGN/){
		$tmp=~s/(\d+)\D*.*$/$1/;}
	    $hssp{$kwd}=$tmp;
	    ++$ctRd;
	    next;}
				# is long id
	if ($line =~ /$hsspRd_ini{"regexpLongId"}/) {
	    $LisLongId=1;
	    next; }
    }				# end of HEADER
    
				# ------------------------------
				# correct errors (holm)
    if (defined $hsspRd_ini{"head","KCHAIN"} &&
	! defined $hssp{"KCHAIN"}){
	$hssp{"KCHAIN"}=1;
    }

    return(1,"ok $SBR3");
}				# end of hsspRd_head

#===============================================================================
sub hsspRd_pair {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_pair                 read HEADER pair info
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_pair";

				# switch on reading ids if to read ali
    $LwantAliById=0;
    if ($LnoPair && ! $LnoAli &&
	$kwdInLoc && $kwdInLoc=~/ali=[A-Za-z0-9][A-Za-z0-9]+/){
	$LnoPair=0;
	$hsspRd_ini{"pair","ID"}=1;
	$LwantAliById=1;}
				# now read
    $ctAli=0;
    while ( <$fhinLoc> ) { 
				# finish this part if end of pair (begin of ali)
	last if ($_ =~ /$hsspRd_ini{"regexpEndPair"}/); 
				# supress reading pair info
	next if ($LnoPair);
				# skip descriptors
	next if ($_ =~ /^  NR\./);
	$_=~s/\n//g;
	$lenLine=length($_);
	if ($LisLongId){
	    $maxMid=115; $maxMid=($lenLine-56) if ($lenLine < 115);
	    $maxEnd=109; $maxEnd=$lenLine      if ($lenLine < 109);
	    $beg=substr($_,1,56);
	    $end=0; $end=substr($_,109)        if ($lenLine >=109);
	    $mid=substr($_,57,115); }
	else {
	    $maxMid= 62; $maxMid=($lenLine-28) if ($lenLine <  90);
	    $beg=substr($_,1,28);
	    $end=0; $end=substr($_,90)         if ($lenLine >=90);
	    $mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$//g;   # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	if ($lenLine > 86) {
	    $accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g ; }
	else {
	    $accnum=0;}
				# begin: counter and id
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $LisLongId) {
	    $id=$beg;$id=~s/([^\s]+).*$/$1/;
	    $strid=$beg;$strid=~s/$id|\s//g;
	    $strid=0            if ($strid=~/^\s*$/);}
	else              {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=substr($line,$hsspRd_ini{"pos","STRIDlong"},6);$strid=~s/\s//g; 
	    $strid=0            if ($strid=~/^\s*$/);}
	if ($strid){
	    $tmp=$hsspRd_ini{"lenStrid"}-1;
	    if ( (length($strid)<$hsspRd_ini{"lenStrid"}) && 
		($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
		$strid=substr($id,1,$hsspRd_ini{"lenStrid"}); }}
	++$ctAli;
	$hssp{"numali"}=$hssp{"pair","numali"}=$ctAli;

	if (defined $hsspRd_ini{"pair","ID"}){
	    $hssp{"ID",$ctAli}=     $id;}
	if (defined $hsspRd_ini{"pair","STRID"}){
	    $strid=""           if (! $strid);
	    $hssp{"STRID",$ctAli}=  $strid;
				# correct for ID = PDBid
	    $hssp{"STRID",$ctAli}=  $id if ($strid=~/^\s*$/ && 
					 $id=~/\d\w\w\w.?\w?$/);}
	if (defined $hsspRd_ini{"pair","PROTEIN"}){
	    $hssp{"PROTEIN",$ctAli}=$end; }
	if (defined $hssp{"PDBID"}){
	    $hssp{"ID1",$ctAli}=    $hssp{"PDBID"};}
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {
	    $_=~s/\s//g;}

	foreach $kwd (@hsspRd_iniKwdPair){
	    next if (! defined $hsspRd_ini{"ptr",$kwd});
	    next if (! defined $hsspRd_ini{"pair",$kwd});
	    $ptr=$hsspRd_ini{"ptr",$kwd};
	    $val=$tmp[$ptr]; 
	    $val=~s/\s//g if ($kwd !~/PROTEIN/);
	    $hssp{$kwd,$ctAli}=$val;
				# store for 'want ali by id'
	    $hssp{"ali",$val}=$ctAli if ($LwantAliById);
	}
    }				# end of PAIRS

    return(1,"ok $SBR3");
}				# end of hsspRd_pair

#===============================================================================
sub hsspRd_aliPre {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_aliPre               finds out what to read
#       in GLOBAL:              $hssp{"ali",$num}
#       out GLOBAL:             $tmp{"chain",$chain}=1 if that chain to read 
#                                   else: undefined
#       out GLOBAL:             $tmp{"ali",$num}=1 if that protein to read (by number)
#                                   else: undefined
#       out GLOBAL:             @wantNum=   numbers for alignments to read
#       out GLOBAL:             @wantBlock= numbers of blocks which contain alignments to read
#       out GLOBAL:             
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_aliPre";

				# ------------------------------
				# read particular chain?
    $Lchain=0;

    if ($kwdInLoc && $kwdInLoc=~/(chain|chn)=(.+)/){
	if (! defined $2){
	    print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, missing chain?\n";}
	else { $tmp=$2;
	       $tmp=~s/([A-Z0-9,\*]+)(no|ali|seq|sec|acc)*.*$/$1/g;
	       if ($tmp !~/[A-Z0-9\*]/){
		   print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, chain=$tmp?\n";}
	       else {
		   $tmp=~s/^,|,$//g;
		   foreach $tmp (split(/,/,$tmp)){
		       $tmp{"chain",$tmp}=1;
		   }
		   $Lchain=1;
	       }}}
				# ------------------------------
				# read particular ali?
    $LaliNo= 0;
    if (! $LnoAli && $kwdInLoc && $kwdInLoc=~/ali=(.+)/){
	if (! defined $1){
	    print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, missing ali=?\n";}
	else { $tmp=$1;
				# mode 1: given by number
	       if ($tmp=~/^\d+$/    || 
		   $tmp=~/^\d+[\-,]/){
		   @tmp2=split(/[,]/,$tmp);
		   $#tmp=0;
		   foreach $tmp (@tmp2){
				# finish if not number
		       last if ($tmp !~/^\d+$/ && 
				$tmp !~/^\d+\-\d+/);
				# is range
		       if ($tmp=~/^(\d+)\-(\d+)$/){
			   foreach $it ($1..$2){
			       push(@tmp,$it);
			   }}
				# is single number
		       else {
			   push(@tmp,$tmp);}}
		   if ($#tmp > 0){
		       $LaliNo=1;
		       foreach $tmp (@tmp){
			   $tmp{"ali",$tmp}=1;
		       }}}
				# mode 2: given id
	       else {
		   $#tmp=0;
		   @tmp2=split(/[,]/,$tmp);
		   foreach $tmp (@tmp2){
				# finish if not id
		       last if ($tmp !~ /^[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]/);
		       next if (! defined $hssp{"ali",$tmp} ||
				$hssp{"ali",$tmp}!~/^\d+$/);
		       $it=$hssp{"ali",$tmp};
		       push(@tmp,$it);}
		   if ($#tmp > 0){
		       $LaliNo=1;
		       foreach $tmp (@tmp){
			   $tmp{"ali",$tmp}=1;
		       }}
	       }
	       if ($LaliNo && $#tmp > 0){
				# get numbers to take
		   @wantNum=sort bynumber2 (@tmp);
		   $#tmp=0;
				# get blocks to take
		   $wantLast=$wantNum[$#wantNum];$#wantBlock=0;
		   foreach $ctBlock (1..$hsspRd_ini{"nmaxBlocks"}){
		       $beg=1+($ctBlock-1)*70;
		       $end=$ctBlock*70;
		       last if ($wantLast < $beg);
		       $Ltake=0;
		       foreach $num (@wantNum){
			   if ( ($beg<=$num) && ($num<=$end) ){
			       $Ltake=1;
			       last;}}
		       if ($Ltake){
			   $wantBlock[$ctBlock]=1;}
		       else{
			   $wantBlock[$ctBlock]=0;}}
	       }
	   }}
				# read all blocks
    elsif (! $LnoAli){
	foreach $ctBlock (1..$hsspRd_ini{"nmaxBlocks"}){
	    $wantBlock[$ctBlock]=1;}
	$#wantNum=0;
	foreach $ctAli (1..$hssp{"NALIGN"}){
	    push(@wantNum,$ctAli);}
    }

    $#tmp=$#tmp2=0;		# slim-is-in
    return(1,"ok $SBR3");
}				# end of hsspRd_aliPre

#===============================================================================
sub hsspRd_ali {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_ali                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       in GLOBAL:              $tmp{"chain",$chain}=1 if that chain to read 
#                                   else: undefined
#       in GLOBAL:              $tmp{"ali",$num}=1 if that protein to read (by number)
#                                   else: undefined
#       in GLOBAL:              @wantNum=   numbers for alignments to read
#       in GLOBAL:              @wantBlock= numbers of blocks which contain alignments to read
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_ali";

    $ctRes=  0;
    $ctBlock=1;
				# ------------------------------
				# check what to read of first block
    if (! $LnoAli && $wantBlock[$ctBlock]){
				# out GLOBAL: @wantNumLoc: relative position of ali to read
	($Lok,$msg,$LreadBlock,$numFirstAli,$numLastAli)=
	    &hsspRd_aliBlockIni(0); return(&errSbr("file=$fileInLoc: problem with hsspRd_aliBlockIni:".
						   $msg."\n",$SBR3)) if (! $Lok); }

				# ------------------------------------------------------------
				# read ALIGNMENT section
				# ------------------------------------------------------------
    while (<$fhinLoc>) {
	$line=$_; $line=~s/\n//g;
				# ------------------------------
				# end of alignments
	last if ($line=~/$hsspRd_ini{"regexpEndAli"}/); 

				# skip line
	next if ($line=~/$hsspRd_ini{"regexpSkip"}/);
				# ------------------------------
				# new alignment block 
	if (! $LnoAli && $line=~/$hsspRd_ini{"regexpBegAli"}/){
	    ++$ctBlock;
	    $numLastAli=0;
	    $LreadBlock=0;
	    $ctRes=     0;	# reset counting of residues!

	    if ($wantBlock[$ctBlock]) {
				# out GLOBAL: @wantNumLoc: relative position of ali to read
		($Lok,$msg,$LreadBlock,$numFirstAli,$numLastAli)=
		    &hsspRd_aliBlockIni($line); 
		return(&errSbr("file=$fileInLoc: problem with hsspRd_aliBlockIni:".
			       $msg."\n",$SBR3)) if (! $Lok);}
	    next;		# skip rest of line
	}
	elsif ($line=~/$hsspRd_ini{"regexpBegAli"}/){
	    $ctRes=     0;	# reset counting of residues!
	    next; }
				# ------------------------------
				# chain
        $chainRd=substr($line,$hsspRd_ini{"ptr","chain"},1);  # grep out chain identifier
	next if ( $Lchain && ! defined $tmp{"chain",$chainRd});
	++$ctRes;
	$hssp{"ali","numres",$ctBlock}=$ctRes;
				# ------------------------------
				# mark begin and end of chain
	if ($Lchain) { $hssp{"chain"}=""            if (! defined $hssp{"chain"});
		       if (! defined $hssp{"chain",$chainRd,"beg"}){
			   $hssp{"chain"}.=              $chainRd.",";
			   $hssp{"chain",$chainRd,"beg"}=$ctRes;}
		       $hssp{"chain",$chainRd,"end"}=    $ctRes; }
	$hssp{"chain",$ctRes}=$chainRd if (defined $hsspRd_ini{"ali","chain"});
				# ------------------------------
				# read sequence, sec str, acc
				# only for first block!
	if ($ctBlock==1){
	    $hssp{"ali","numres"}=$hssp{"numres"}=$hssp{"NROWS"}=$ctRes;
	    ($Lok,$msg)=
		&hsspRd_aliSeqSecAcc($line); 
	    return(&errSbr("file=$fileInLoc: problem with hsspRd_aliSeqSecAcc:".
			   $msg."\n",$SBR3)) if (! $Lok); }

				# ------------------------------
				# now to the alignments
				# ------------------------------
	next if ($LnoAli);
				# skip block
	next if (! $LreadBlock);
				# skip since no alis
	next if (length($line)<$hsspRd_ini{"ptr","ali"});

				# DEFAULT insertions for all positions
	foreach $numAliLoc (@wantNumLoc){
	    $hssp{"ali",($numAliLoc+$numFirstAli-1),$ctRes}=$hsspRd_ini{"symbolInsertion"};
	}
				# now the alignments
	$tmp=substr($line,$hsspRd_ini{"ptr","ali"}); 
	@tmp=split(//,$tmp);
				# NOTE: @wantNumLoc has the positions to read in current block,
				#       e.g. want no 75, block=71-90, => 75->4
	foreach $numAliLoc (@wantNumLoc){
				# missing ?
	    next if ($numAliLoc > $#tmp);
				# note: numFirstAli=71 in the example above
	    $numAli= $numAliLoc+$numFirstAli-1; 
	    $hssp{"ali",$numAli,$ctRes}=$tmp[$numAliLoc];
	    $hssp{"ali",$numAli}=1 if (! defined $hssp{"ali",$numAli});
	}
    }				# end of reading the alignments and seq,sec,acc,chain

				# clean up
    $#wantNumLoc=0;		# slim-is-in

    return(1,"ok $SBR3");
}				# end of hsspRd_ali

#===============================================================================
sub hsspRd_aliBlockIni {
    local($line)=@_;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_aliBlockIni          new block to read?
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             @wantNumLoc: relative position of ali to read
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4="hsspRd_aliBlockIni";
    $LreadBlock=0;
				# which numbers are in this block?
				# first block
    if (! $line){ 
	$beg=1;
	$end=70; 
	$end=$hssp{"NALIGN"} if ($hssp{"NALIGN"}<70);}
    else {
	$tmp=$line; $tmp=~s/^[^0-9]+(\d+) -\s+(\d+).*$//;
	$beg=$1;$end=$2;}
    $LreadBlock=1;
    $#wantNumLoc=0;		# local numbers
    foreach $num (@wantNum){
	if ( ($beg<=$num) && ($num<=$end) ){
	    $tmp=($num-$beg)+1; 
	    if ($tmp<1){
		print $FHTRACE2 
		    "-*- WARN $SBR2: negative local alignment number !\n",
		    "-*-             tmp=$tmp,$beg,$end,\n";}
	    else {
		push(@wantNumLoc,$tmp);
	    }
	}
    }
    return(1,"ok $SBR4",$LreadBlock,$beg,$end);
}				# end of hsspRd_aliBlockIni

#===============================================================================
sub hsspRd_aliSeqSecAcc {
    local($line)=@_;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_aliSeqSecAcc                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4="hsspRd_aliSeqSecAcc";
				# get numbers
    if (defined $hsspRd_ini{"ali","SeqNo"}) {
	$SeqNo=  substr($line,$hsspRd_ini{"ptr","SeqNo"},6);
	exit if (! defined $SeqNo || length($SeqNo)<1);
	$SeqNo=~s/\s//g;
	$hssp{"SeqNo",$ctRes}=$SeqNo;
	$hssp{"chain",$chainRd,"begSeqNo"}=$SeqNo if (! defined $hssp{"chain",$chainRd,"begSeqNo"});
	$hssp{"chain",$chainRd,"endSeqNo"}=$SeqNo;}
    
    if (defined $hsspRd_ini{"ali","PDBNo"}) {
	$PDBNo=  substr($line,$hsspRd_ini{"ptr","PDBNo"},6);
	$PDBNo=~s/\s//g;
	$hssp{"PDBNo",$ctRes}=$PDBNo;}
				# for later: restrict to fragment yy
#	    next if ( $ifirLoc  && ($SeqNo < $ifirLoc));
#	    next if ( $ilasLoc  && ($SeqNo > $ilasLoc));
				# sequence
    if (! $LnoSeq && defined $hsspRd_ini{"ali","seq"}) {
	$hssp{"seq",$ctRes}=  substr($line,$hsspRd_ini{"ptr","seq"},1);}
				# secondary structure
    if (! $LnoSec && defined $hsspRd_ini{"ali","sec"}) {	    
	$hssp{"sec",$ctRes}=  substr($line,$hsspRd_ini{"ptr","sec"},1);}
				# solvent accessibility
    if (! $LnoAcc && defined $hsspRd_ini{"ali","acc"}) {	    
	$hssp{"acc",$ctRes}=  substr($line,$hsspRd_ini{"ptr","acc"},3);
	$hssp{"acc",$ctRes}=~s/\D//g; }

    return(1,"ok $SBR4");
}				# end of hsspRd_aliSeqSecAcc

#===============================================================================
sub hsspRd_prof {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_prof                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_prof";
				# ------------------------------
				# read the profile
				# ------------------------------
    $LisEOF=0;
    $ctRes=0;
    while (<$fhinLoc>) {	# 
	$line=$_; $line=~s/\n//g;
				# no insertions will follow: is END of file
        if ($_=~/^$hsspRd_ini{"regexpEndIns"}/){
	    $LisEOF=1;
	    last;}
				# finish reading
	last if ($line=~/^$hsspRd_ini{"regexpBegIns"}/);
				# skip reading until end
	next if ($LnoProf);
				# ------------------------------
				# is line with column names
	if ($line=~/^$hsspRd_ini{"regexpProfNames"}/){
				# skip part with 'SeqNo PDBNo ' (including chain)
	    $tmp=substr($line,$hsspRd_ini{"ptr","prof"});
	    $tmp=~s/^\s*|\s*$//g;
	    @tmp=split(/\s+/,$tmp);
	    $#tmp_wantCol=$#tmp_kwdCol=0;
	    foreach $it (1..$#tmp){
				# not to be read
		next if (! defined $hsspRd_ini{"prof",$tmp[$it]});
		push(@tmp_kwdCol,$tmp[$it]);
		push(@tmp_wantCol,$it);
	    }
	    $#tmp=0;
	    next;}
				# seems to be an error
	next if (length($line)<$hsspRd_ini{"ptr","prof"});

				# check out chain
	if ($Lchain){
	    $chainRd=substr($line,$hsspRd_ini{"ptr","profchain"},1);
				# chain, in fact not to be read
	    next if (! defined $hssp{"chain",$chainRd,"beg"}); }

				# yy allow for fragment selection later yy
#	next if ( $ifirLoc  && ($SeqNo < $ifirLoc));
#	next if ( $ilasLoc  && ($SeqNo > $ilasLoc));

				# skip part with 'SeqNo PDBNo ' (including chain)
	$tmp=substr($line,$hsspRd_ini{"ptr","prof"});
	$tmp=~s/^\s*|\s*$//g;
	@tmp=split(/\s+/,$tmp);

	++$ctRes;
	$hssp{"prof","numres"}=$ctRes;
	foreach $it (1..$#tmp_wantCol){
	    $it_wantCol=$tmp_wantCol[$it];
	    $hssp{"prof",$tmp_kwdCol[$it_wantCol],$ctRes}=
		$tmp[$it_wantCol];
	}
    }				# end of reading profiles

				# clean up
    $#tmp=$#tmp_wantCol=$#tmp_kwdCol=0;	# slim-is-in
    return(1,"ok $SBR3",$LisEOF);
}				# end of hsspRd_prof

#===============================================================================
sub hsspRd_ins {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_ins                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    $insMax[$itres]= maximal number of insertions
#                               for residue $itres
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="lib-prof:hsspRd_ins";

    undef @insMax;		# note: $insMax[$SeqNo]=5 means at residue 'SeqNo'
    $numres=0;
    $numres=$hssp{"ali","numres",1}  if (! $numres && defined $hssp{"ali","numres",1});
    $numres=$hssp{"SEQLENGTH"}       if (! $numres && defined $hssp{"SEQLENGTH"});
    $numres=$hsspRd_ini{"nmaxRes"}   if (! $numres);

				# set number of maximal insertions to 0
    foreach $itRes (1..$numres){
	$insMax[$itRes]=0;
    }

				# ------------------------------
				# read the insertions
    while (<$fhinLoc>){
				# end reading insertion list
        last if ($_=~/^$hsspRd_ini{"regexpEndIns"}/); 

				# --------------------------------------------------
				# read insertion list
				# 
				# syntax of insertion list:  
				#    ....,....1....,....2....,....3....,....4
				#    AliNo  IPOS  JPOS   Len Sequence
				#         9    58    59     5 kQLGAEi
				# 
				# --------------------------------------------------
	$line=$_; $line=~s/\n//;

				# skip line with names
	next if ($line=~/^$hsspRd_ini{"regexpInsNames"}/);
				# --------------------------------------------------
				# continuation of previous line
	if ($line=~/^\s+\+\s*(\S+)$/){ 
	    $seqIns.=$1;
				# number of residues inserted
	    $nresIns=(length($seqIns) - 2);
				# increase count of maximally inserted residues
	    $insMax[$ipos]=$nresIns if ($nresIns > $insMax[$ipos]);

				# NOTE: here $tmp{$it,$SeqNo} gets more than
				#       one residue assigned (ref=11)
				# change 'ACinK' -> 'ACINEWNK'
	    $hssp{"ali",$alino,$ipos}=substr($seqIns,1,(length($seqIns)-1));
	    next; }
	    
				# --------------------------------------------------
				# ERROR should not happen (see syntax)
        if ($line !~ /^\s*\d+/) {
	    print "-*- WARN $SBR3: problem with line=$line, insertion list!\n";
	    next;}
	$tmp=$line;
				# purge leading blanks
	$tmp=~s/^\s*\+*|\s*$//g;
				# note written into columns ' AliNo  IPOS  JPOS   Len Sequence'
	@tmp=split(/\s+/,$tmp);

	$alino=$tmp[$hsspRd_ini{"ptr","ins","alino"}];
				# skip since it did NOT want that one, anyway
	next if (! defined $hssp{"ali",$alino});

				# ok -> take
				# residue position in insertion
	$ipos=   $tmp[$hsspRd_ini{"ptr","ins","ipos"}];
				# sequence at insertion 'kQLGAEi'
	$seqIns= $tmp[$hsspRd_ini{"ptr","ins","seq"}];
				# number of residues inserted
	$nresIns=(length($seqIns) - 2);
				# increase count of maximally inserted residues
	$insMax[$ipos]=$nresIns if (! defined $insMax[$ipos] ||
				    $nresIns > $insMax[$ipos]);

				# --------------------------------------------------
				# NOTE: here $tmp{$it,$SeqNo} gets more than
				#       one residue assigned (ref=11)
				# --------------------------------------------------
				# change 'ACinK' -> 'ACINEWNK'
	$hssp{"ali",$alino,$ipos}=substr($seqIns,1,(length($seqIns)-1));
    }				# end of reading insertions

    @tmp=@insMax;
    $#insMax=0;			# slim-is-in
    return(1,"ok $SBR3",@tmp);
}				# end of hsspRd_ins

#===============================================================================
sub hsspRd_fill {
    local(@insMax)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_fill                 fills the insertion list asf out: final alignment
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."hsspRd_fill";

    $numres=0;
    $numres=$hssp{"ali","numres",1}  if (! $numres && defined $hssp{"ali","numres",1});
    $numres=$hssp{"SEQLENGTH"}       if (! $numres && defined $hssp{"SEQLENGTH"});
    $numres=$hsspRd_ini{"nmaxRes"}   if (! $numres);

				# set to ''
    foreach $itAli (0,@wantNum){
	$hssp{"fin",$itAli}="";
    }
				# --------------------------------------------------
				# loop over residues
				# --------------------------------------------------
    foreach $itRes (1..$numres){
	$insMax=$insMax[$itRes];
				# ------------------------------
				# guide sequence
	$hssp{"fin",0}.=$hssp{"seq",$itRes};
				# dirty: fill in the end
	$hssp{"fin",0}.="." x $insMax if ($insMax);

				# ------------------------------
				# loop over all alis
	foreach $itAli (@wantNum){
	    $hssp{"fin",$itAli}.=$hssp{"ali",$itAli,$itRes};
	    $hssp{"fin",$itAli}.="." x (1 + $insMax - length($hssp{"ali",$itAli,$itRes}));
	}
    }
				# ------------------------------
				# now assign to final
    foreach $itAli (0,@wantNum){
				# replace ' ' -> '.'
	$hssp{"fin",$itAli}=~s/\s/\./g;
	next if ($itAli==0);
				# all capital for aligned (NOT for sequence)
	$hssp{"fin",$itAli}=~tr/[a-z]/[A-Z]/;
    }
				# clean up
    $#tmp=0;

    return(1,"ok $SBR3");
}				# end of hsspRd_fill

#===============================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    $npoints=10*(1+int($npoints/10))
	if ( int($npoints/10)!=($npoints/10) );

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
	    $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ($i==($npoints/10) && $ctprev>=9){
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else                                   {
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

#===============================================================================
sub myprt_npointsfull {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npointsfull           writes line with N dots of the form '....,....10...,....2'  (full numbers=22000)
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    $npoints=10*(1+int($npoints/10))
	if ( int($npoints/10)!=($npoints/10) );

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
#	    $tmp=substr($num,1,1); 
	    $tmp=$num;
	    $out="....,....".$tmp; 
	    $prevover=length($num);
	}
	else                                   {
	    $tmp=$num;
	    $out.= "." x (5-$prevover) .",....".$tmp; 
	    $prevover=length($num);
	}
	last if ($num>$num_in);
    }
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npointsfull

#===============================================================================
sub rdRdb_here {
    local ($fileInLoc,$ra_kwdRdHead,$ra_kwdRdBody) = @_ ;
    local ($sbr_name);
    my    ($fhinLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdb_here                  reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               $ra_kwdRdHead: $ra_kwdRdHead->[1]  = $kwdRdHead[1]
#       out:                    $rdb{"NROWS"} returns the numbers of rows read
#                               $rdb{$itres,$kwd}
#--------------------------------------------------------------------------------
				# avoid warning
    $sbr_name="rdRdb_here";
				# set some defaults
    $fhinLoc="FHIN_RDB";
				# get input
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open($fhinLoc,$fileInLoc) || return(&errSbr("failed opening fileIn=$fileInLoc!\n",$sbr_name));

    undef %rdb;
    $#ptr_num2name=$#col2read=0;

				# ------------------------------
				# for quick finding
    if (! defined %kwdRdBody){
	foreach $kwd (@$ra_kwdRdBody){
	    $kwdRdBody{$kwd}=1;}}

	
    $ctLoc=$ctrow=0;
				# ------------------------------
				# header  
    while ( <$fhinLoc> ) {	# 
	$_=~s/\n//g;
	$line=$_;
	if ( $_=~/^\#/ ) { 
	    if ($_=~/PARA|VALUE/){
		foreach $kwd (@$ra_kwdRdHead){
#		    next if (defined $rdb{$kwd});
		    if ($_=~/^.*(PARA\S*|VAL\S*)\s*:?\s*$kwd\s*[ :,\;=]+(\S+.*)$/i){
			if (! defined $rdb{$kwd}){
			    $rdb{$kwd}=$2;}
			else {
			    $rdb{$kwd}.="\t".$2;}
			next; }
		    next if (! defined $rdb{$kwd});
		}}
	    next; }
	last; }
				# ------------------------------
				# names
    @tmp=split(/\s*\t\s*/,$line);
    foreach $it (1..$#tmp){
	$kwd=$tmp[$it];
	next if (! defined $kwdRdBody{$kwd});
	$ptr_num2name[$it]=$kwd;
	push(@col2read,$it); }

    $ctLoc=2;
    while ( <$fhinLoc> ) {	# 
	$_=~s/\n//g;
	$line=$_;
				# ------------------------------
				# skip format?
	if    ($ctLoc==2 && $line!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc;}
	elsif ($ctLoc==2){
	    next; }
				# ------------------------------
				# data
	if ($ctLoc>2){
	    ++$ctrow;
	    $line=~s/^\s*//g;
	    @tmp=split(/\s*\t\s*/,$line);
	    foreach $it (@col2read){
		$rdb{$ctrow,$ptr_num2name[$it]}=$tmp[$it];
	    }
	}
    }
    close($fhinLoc);
    $rdb{"NROWS"}=$ctrow;

    $#col2read=0; 
    undef %ptr_num2name;

    return (1,"ok");
}				# end of rdRdb_here

#==============================================================================
# library collected (end)   lllend
#==============================================================================

