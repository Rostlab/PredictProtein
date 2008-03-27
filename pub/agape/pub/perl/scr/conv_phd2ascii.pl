#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="converts a PHD.rdb file to PHD.phd ASCII human readable format.\n".
    "     \t \n".
    "     \t ";
# 
# 
# NOTE: for easy exchange with PHD, all major subroutines shared between
#       PHD and this program appear at the end of it (after 'lllend')
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
$lib="lib-wrtAscii.pm"; $Lok=0;
foreach $dir ($dirScr,"","pack/","/home/rost/pub/phd/scr/","/home/rost/pub/phd/scr/pack/"){
    next if (! -e $dir.$lib);
    $Lok=require($dir.$lib); }
die("*** ERROR $scrName: could NOT find lib=$lib!\n") if (! $Lok);
				# ------------------------------
				# ini
($Lok,$msg)=&ini();		die("*** ERROR $scrName: failed in ini:\n".
				    $msg."\n") if (! $Lok);

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ct=0;
foreach $fileIn (@fileIn){
    ++$ct;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
#    print "--- $scrName: working on fileIn=$fileIn!\n";
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn);

    if ($#fileIn > 1 || ! defined $fileOut || length($fileOut)<1){
	$fileOut=$fileIn; $fileOut=~s/^.*\///g; 
	$fileOut=~s/\.rdb.*$/\.phd/; }
    print "xx fileout=$fileOut\n";

    ($Lok,$msg)=
	&convRdb2ascii
	    ($fileIn,$fileOut,$modeWrt,$par{"nresPerRow"},
	     $par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSec"},$par{"riSubSym"},
	     $par{"txtPreRow"},$par{"debug"}
	     ); die("*** ERROR $scrName: failed on convRdb2ascii for file=$fileInLoc\n".
		    "*** message from where it failed:\n".$msg."\n") if (! $Lok);
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

	  '', "",			# 

	  'notation',          1,       # explain notation
	  'averages',          1,       # include information about AA composition and SS composition
	  'header',            1,       # write information iin RDB header?
	  'brief',             0,       # also give short version of prediction
	  'normal',            1,       # the typical OLD PHD output
	  'subset',            1,       # write line with subset ?
	  'detail',            1,       # write line with detail ?
	  'graph',             1,       # include ASCII graphics

	  'txtPreRow',         "",      # each row will begin with '$pre'
	  '',                  "",      # 
	  'nresPerRow',        60,      # number of residues per row
	  
	  'riSubAcc',          4,       # minimal reliability index for SUBSET acc
	  'riSubHtm',          7,       # minimal reliability index for SUBSET htm
	  'riSubSec',          5,       # minimal reliability index for SUBSET sec
	  'riSubSym',          ".",     # symbol for residues predicted with RI<SubSec/Acc
	  
	  '',      "",

	  'optPhd',            "htm", # note the following are currently NOT being used!
	  'optDoHtmref',       1,
	  'optDoHtmtop',       1,

	  );


    $par{"numresMin"}=         17;        # minimal number of residues to run network 
    $par{"numresMin"}=          9;        # minimal number of residues to run network 
				          #    otherwise prd=symbolPrdShort
    $par{"symbolPrdShort"}=     "*";      # default prediction for too short sequences
				          #    NOTE: also taken if stretch between two chains too short!
    $par{"symbolChainAny"}=     "*";      # chain name if chain NOT specified!
    $par{"acc2Thresh"}=         16;       # threshold for 2-state description of solvent accessibility, i.e.


    $par{"txt","copyright"}=       "Burkhard Rost, CUBIC NYC / LION Heidelberg";
    $par{"txt","contactEmail"}=    "rost\@columbia.edu";
    $par{"txt","contactFax"}=      "+1-212-305 3773";
    $par{"txt","contactWeb"}=      "http://cubic.bioc.columbia.edu";
    $par{"txt","version"}=         "2000.02";
#    $par{"txt"}=       "";
    
    $par{"txt","modepred","sec"}=  "prediction of secondary structure";
    $par{"txt","modepred","cap"}=  "prediction of secondary structure caps";
    $par{"txt","modepred","acc"}=  "prediction of solvent accessibility";
    $par{"txt","modepred","htm"}=  "prediction of transmembrane helices";
    $par{"txt","modepred","loc"}=  "prediction of sub-cellular location";

    $par{"txt","quote","phd1994"}= "B Rost (1996) Methods in Enzymology, 266:525-539";
    $par{"txt","quote","phdsec"}=  "B Rost & C Sander (1993) J Mol Biol, 232:584-599";
    $par{"txt","quote","phdacc"}=  "B Rost & C Sander (1994) Proteins, 20:216-226";
    $par{"txt","quote","phdhtm"}=  "B Rost, P Fariselli & R Casadio (1996) Prot Science, 7:1704-1718";
    $par{"txt","quote","globe"}=   "B Rost (1998) unpublished";
    $par{"txt","quote","topits"}=  "B Rost, R Schneider & C Sander (1997) J Mol Biol, 270:1-10";


    $par{"notation","prot_id"}=    "identifier of protein [\w]";
    $par{"notation","prot_name"}=  "name of protein [\w]";
    $par{"notation","prot_nres"}=  "number of residues [\d]";
    $par{"notation","prot_nali"}=  "number of proteins aligned in family [\d]";
    $par{"notation","prot_nchn"}=  "number of chains (if PDB protein) [\d]";
    $par{"notation","prot_kchn"}=  "PDB chains used [0-9A-Z!\s]";
    $par{"notation","prot_nfar"}=  "number of distant relatives [\d]";

    $par{"notation","ali_orig"}=   "input file";
    $par{"notation","ali_used"}=   "input file used";
    $par{"notation","ali_para"}=   "parameters used to filter input file";

    $par{"notation","phd_fpar"}=   "name of parameter file, used [\w]";
    $par{"notation","phd_nnet"}=   "number of networks used for prediction [\d]";
    $par{"notation","phd_fnet"}=   "name of network architectures, used [\w]";
    $par{"notation","phd_mode"}=   "mode of prediction [\w]";
    $par{"notation","phd_version"}="version of PHD";

    $par{"notation","phd_skip"}=   "note: sequence stretches with less than ".$par{"numresMin"}.
	                           " are not predicted, the symbol '".$par{"symbolPrdShort"}.
				       "' is used!";

				# protein
    $par{"notation","No"}=         "counting residues [\d]";
    $par{"notation","AA"}=         "amino acid one letter code [A-Z!a-z]";
    $par{"notation","CHN"}=        "protein chain [A-Z!a-z]";

				# secondary structure
    $par{"notation","OHEL"}=       "observed secondary structure: H=helix, E=extended (sheet), ".
	                           "blank=other (loop)";
    $par{"notation","PHEL"}=       "PHD predicted secondary structure: ".
	                           "H=helix, E=extended (sheet), blank=other (loop). ".
		"\nPHD: Profile-based neural network prediction originally from HeiDelberg";
    $par{"notation","RI_S"}=       "reliability index for PHDsec prediction (0=lo 9=high). ".
	                           "\nNote: for this presentation strong predictions marked by '*'.";

    $par{"notation","SUBsec"}=     "subset of the PHDsec prediction, for all residues with an ".
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
    $par{"notation","PACC"}=       "PHD predicted solvent accessibility in square Angstroem ";
    $par{"notation","PREL"}=       "PHD predicted relative solvent accessibility (acc) in 10 states: ".
	"\na value of n (0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % ".
	    "\n(e.g. for n=5: 16-25%). ".
		"\nPHD: Profile-based neural network prediction originally from HeiDelberg";
    $par{"notation","Obe"}=        "observed relative solvent accessibility (acc) in 2 states: ".
	"b=0-".$par{"acc2Thresh"}."% , e= ".$par{"acc2Thresh"}."-100%.";
    $par{"notation","Obie"}=       "observed relative solvent accessibility (acc) in 3 states: ".
	"b=0-9%, i = 9-36%, e = 36-100%.";
    $par{"notation","Pbe"}=        "PHD predicted relative solvent accessibility (acc) in 2 states: ".
	"b=0-".$par{"acc2Thresh"}."%, e= ".$par{"acc2Thresh"}."-100%.";
    $par{"notation","Pbie"}=       "PHD predicted relative solvent accessibility (acc) in 3 states: ".
	"b=0-9%, i = 9-36%, e = 36-100%.";
    $par{"notation","RI_A"}=       "reliability index for PHDacc prediction (0=low to 9=high). ".
	                           "\nNote: for this presentation strong predictions marked by '*'.";
    $par{"notation","SUBacc"}=     "subset of the PHDacc prediction, for all residues with an".
	" expected average correlation > 0.69 (tables in header). ".
	    "\n     NOTE: for this subset the following symbols are used: ".
		"\n  I: is intermediate (for which above ' ' is used), ".
		    "\n  ".$par{"riSubSym"}.": means that no prediction is made for this ".
			"\nresidue, as the reliability is:  Rel < ".$par{"riSubAcc"};

				# membrane helices
    $par{"notation","OMN"}=        "observed membrane helix: M=helical transmembrane region, ".
	"blank=non-membrane";
    $par{"notation","Otop"}=       "observed membrane topology: i=inside, M=membrane, o=outside";
    $par{"notation","OiMo"}=       "observed membrane topology: M=helical transmem".
	                           "brane region, i=inside of membrane, o=outside of membrane";

    $par{"notation","PMN"}=        "PHD predicted membrane helix: M=helical transmembrane region, ".
	                           "blank=non-membrane. ".
	    "\nPHD: Profile-based neural network prediction originally from HeiDelberg";
    $par{"notation","PRMN"}=       "refined PHD prediction: M=helical transmembrane region, ".
	"blank=non-membrane";
    $par{"notation","Ptop"}=       "PHD predicted membrane topology: i=inside, M=membrane, o=outside";
    $par{"notation","PiMo"}=       "PHD prediction of membrane topology: M=helical transmem".
	"brane region, i=inside of membrane, o=outside of membrane";
    $par{"notation","RI_H"}=       "reliability index for PHDhtm prediction (0=low to 9=high). ".
	                           "Note: for this presentation strong predictions marked by '*'.";
    $par{"notation","SUBhtm"}=     "subset of the PHDhtm prediction, for all residues with an ".
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
    if ($#ARGV<1){		# help
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName '\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
	printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "name of output directory";

	printf "%5s %-15s %-20s %-s\n","","hdr",     "no value","write header";
	printf "%5s %-15s %-20s %-s\n","","nohdr",   "no value","do NOT write header";
	printf "%5s %-15s %-20s %-s\n","","ave",     "no value","compile average composition";
	printf "%5s %-15s %-20s %-s\n","","noave",   "no value","do NOT compile average composition";
	printf "%5s %-15s %-20s %-s\n","","nota",    "no value","annotate meanig of columns";
	printf "%5s %-15s %-20s %-s\n","","nonota",  "no value","do NOT annotate meanig of columns";
	printf "%5s %-15s %-20s %-s\n","","brief",   "no value","write 'brief' prediction (ONLY HEL)";
	printf "%5s %-15s %-20s %-s\n","","nobrief", "no value","do NOT write 'brief'";
	printf "%5s %-15s %-20s %-s\n","","normal",  "no value","write 'normal' PHD.phd output";
	printf "%5s %-15s %-20s %-s\n","","nonormal","no value","do NOT write that one at all";
	printf "%5s %-15s %-20s %-s\n","","sub",     "no value","write 'subset' row";
	printf "%5s %-15s %-20s %-s\n","","nosub",   "no value","do NOT write 'subset' row";
	printf "%5s %-15s %-20s %-s\n","","det",     "no value","write 'detail' row";
	printf "%5s %-15s %-20s %-s\n","","nodet",   "no value","do NOT write 'detail' row";
	printf "%5s %-15s %-20s %-s\n","","graph",   "no value","write 'ASCII' graphics of prediction";
	printf "%5s %-15s %-20s %-s\n","","nograph", "no value","do NOT write \"graphics\"";
	printf "%5s %-15s=%-20s %-s\n","","nres",    "N",       "will print N residues per row ";

#	printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#	printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#	printf "%5s %-15s %-20s %-s\n","","",   "no value","";

	printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
	printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
	printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

	if (defined %par && $#kwd > 0){
	    $tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	    $tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	    $tmp2="";
	    foreach $kwd (@kwd){
		next if (! defined $par{$kwd});
		next if ($kwd=~/^\s*$/);
		if    ($par{$kwd}=~/^\d+$/){
		    $tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
		elsif ($par{$kwd}=~/^[0-9\.]+$/){
		    $tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
		else {
		    $tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	    } 
	    print $tmp, $tmp2       if (length($tmp2)>1);
	}
	exit;}
				# initialise variables
#    $fhin="FHIN";$fhout="FHOUT";
    $#fileIn=0;
				# ------------------------------
				# read command line
    foreach $arg (@ARGV){
#	next if ($arg eq $ARGV[1]);
	if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=          $1;}
	elsif ($arg=~/^dirOut=(.*)$/)         { $par{"dirOut"}=    $1;}

	elsif ($arg=~/^de?bu?g$/)             { $Ldebug=           1;
						$Lverb=            1;
						$par{"debug"}=     1;
						$par{"verbose"}=   1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=            1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=            0;}

	elsif ($arg=~/^(is)?list$/i)          { $LisList=          1;}

	elsif ($arg=~/^ave$/)                 { $par{"averages"}=  1;}
	elsif ($arg=~/^noave$/)               { $par{"averages"}=  0;}
	elsif ($arg=~/^hdr$/)                 { $par{"header"}=    1;}
	elsif ($arg=~/^nohdr$/)               { $par{"header"}=    0;}
	elsif ($arg=~/^nota$/)                { $par{"notation"}=  1;}
	elsif ($arg=~/^nonota$/)              { $par{"notation"}=  0;}
	elsif ($arg=~/^sub$/)                 { $par{"subset"}=    1;}
	elsif ($arg=~/^nosub$/)               { $par{"subset"}=    0;}
	elsif ($arg=~/^brief$/)               { $par{"brief"}=     1;}
	elsif ($arg=~/^nobrief$/)             { $par{"brief"}=     0;}
	elsif ($arg=~/^normal$/)              { $par{"normal"}=    1;}
	elsif ($arg=~/^nonormal$/)            { $par{"normal"}=    0;}
	elsif ($arg=~/^det$/)                 { $par{"detail"}=    1;}
	elsif ($arg=~/^nodet$/)               { $par{"detail"}=    0;}
	elsif ($arg=~/^graph$/)               { $par{"graph"}=     1;}
	elsif ($arg=~/^nograph$/)             { $par{"graph"}=     0;}

	elsif ($arg=~/^nres=(.*)$/)           { $par{"nresPerRow"}=$1;}

#	elsif ($arg=~/^=(.*)$/){ $=$1;}
	elsif (-e $arg)                       { push(@fileIn,$arg); }
	else {
	    $Lok=0; 
	    if (defined %par && $#kwd>0) { 
		foreach $kwd (@kwd){ 
		    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					       last;}}}
	    if (! $Lok){ print "*** wrong command line arg '$arg'\n";
			 exit;}}}

    $fileIn=$fileIn[1];
    die ("*** ERROR $scrName: missing input $fileIn\n") 
	if (! -e $fileIn);
				# ------------------------------
				# build up mode
    $modeWrt="";
    $modeWrt.="header,"         if ($par{"header"});
    $modeWrt.="averages,"       if ($par{"averages"});
    $modeWrt.="notation,"       if ($par{"notation"});
    $modeWrt.="brief,"          if ($par{"brief"});
    $modeWrt.="normal,"         if ($par{"normal"});
    $modeWrt.="subset,"         if ($par{"subset"});
    $modeWrt.="detail,"         if ($par{"detail"});
    $modeWrt.="graph,"          if ($par{"graph"});

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
	if ( ($#fileIn==1 && ! $LisList) && $fileIn !~/\.list/) {
	    push(@fileTmp,$fileIn);
	    next;}
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);return(&errSbrMsg("failed getting input list, file=$fileIn",
						   $msg))  if (! $Lok);
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
    }
    @fileIn= @fileTmp;
    $#fileTmp=0;		# slim-is-in

    return(1,"ok $sbrName");
}				# end of ini

#==============================================================================
# library collected (begin) lllbeg
#==============================================================================


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
sub rdRdb_here {
    local ($fileInLoc,$ra_kwdRdHead,$ra_kwdRdBody) = @_ ;
    local ($sbr_name);
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
		    next if (defined $rdb{$kwd});
		    if ($_=~/^.*(PARA\S*|VAL\S*)\s*:?\s*$kwd\s*[ :,\;=]+(\S+)/i){
			$rdb{$kwd}=$2;
			next; }}}
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

