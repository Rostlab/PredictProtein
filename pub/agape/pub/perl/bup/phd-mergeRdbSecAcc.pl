#!/usr/sbin/perl -w
#
# merges PHD.rdb files (Sec,Acc,Htm)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
				# a.a
@kwd=("verbose","dirPhdTxt","abbrPhdRdb");
$par{"dirPhdTxt"}=          "/home/rost/pub/phd/txt/";
$par{"abbrPhdRdb"}=         $par{"dirPhdTxt"} . "abbrPhdRdb3.txt";
$par{"verbose"}=1;


if ($#ARGV<2){print"goal:     merges PHD.rdb files (Sec,Acc,Htm)\n";
	      print"usage:    file.rdbSec file.rdbAcc file.rdbHtm\n";
	      print"option:   fileOut=x.rdb \n";
	      print"defaults:\n";
	      foreach $kwd(@kwd){printf "%-15s %-s\n",$kwd,$par{"$kwd"};}
	      exit;}

$fhin="FHIN";
$fileOut="Merge-".$ARGV[1];$fileOut=~s/sec|acc|htm//g;
				# read command line
$#fileIn=0;
foreach $arg (@ARGV){
    if ($arg =~ /^fileOut=(.+)/){
	$fileOut=$1;$fileOut=~s/\s//g;}
    elsif (-e $arg) {
	push(@fileIn,$arg);}
    else {
	$Lok=0;
	foreach $kwd(@kwd){if ($arg =~/^$kwd=(.+)$/){$par{"$kwd"}=$1;$Lok=1;
						     last;}}
	if (! $Lok){
	    print "*** unrecognised input argument $arg\n";
	    exit;}}}
				# do merging
&rdbMergeManager($fileOut,$par{"abbrPhdRdb"},$par{"verbose"},@fileIn);

if ($par{"verbose"}){print "--- ended fine, output in $fileOut\n";}
exit;

#===============================================================================
sub rdbMergeManager {
    local ($fileRdb,$fileAbbrRdb,$LscreenLoc,@fileRdbLoc) = @_ ;
    local ($fhout_tmp,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbMergeManager             manages merging two PHD *.rdb files ('name'= acc + sec + htm)
#   note:                       returns fileRdb!
#   $fileIn:                    will be digested to yield the input files: 
#                                  fileIn'exp' and fileIn'sec'
#-------------------------------------------------------------------------------
    if ($LscreenLoc eq "STDOUT"){$LscreenLoc=1;}
#     if ($#fileRdbLoc<2){	# no merge required
	return; }		# 
    if ($LscreenLoc){ print "--- rdbMergeManager: \t merging RDB files (into $fileRdb)\n";}
				# set defaults
    &rdbMergeDefaults();
				# ------------------------------
				# merge files
				# ------------------------------
    $fhout_tmp = "FHOUT_RDB_MERGE_MANAGER";
    &open_file("$fhout_tmp", ">$fileRdb");
    &rdbMergeDo($fileAbbrRdb,$fhout_tmp,$LscreenLoc,@fileRdbLoc);
    close($fhout_tmp);
}				# end of rdbMergeManager

#===============================================================================
sub rdbMergeDefaults {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbMergeDefaults            sets defaults
#       GLOBAL:                 all variables global
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdbMergeDefault";$fhinLoc="FHIN"."$sbrName";

    @desSec=   ("No","AA","OHEL","PHEL","RI_S","pH","pE","pL","OtH","OtE","OtL");
    @desAcc=   ("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    for $it (0..9){$tmp="Ot".$it; push(@desAcc,$tmp); }
    @desHtm=   ("OHL","PHL","PFHL","PRHL","PiTo","RI_H","pH","pL","OtH","OtL");

    @desOutG=   ("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL",
                "OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    @formOut=  ("4N","1" ,"1"   ,"1"   ,"1N",  "3N", "3N", "3N",
                "3N"  ,"3N"  ,"3N",  "3N",  "1N",  "1",   "1");
    for $it (0..9){$tmp="Ot".$it; push(@desOutG,$tmp); push(@formOut,"3N");}
    push(@desOutG, "OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN");
    push(@formOut,"1"  ,"1"  ,"1"   ,"1"   ,"1"   ,"1N"  ,"3N" ,"3N");

    foreach $it (1..$#desOutG){
        $tmp=$formOut[$it];
        if   ($tmp=~/N$/) {$tmp=~s/N$/d/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        elsif($tmp=~/F$/) {$tmp=~s/F$/f/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        else              {$tmp.="s";    $formOutPrintf{"$desOutG[$it]"}=$tmp;} }
    $sep="\t";                  # separator
}				# end of rdbMergeDefaults

#===============================================================================
sub rdbMergeDo {
    local ($fileAbbrRdb,$fhoutLoc,$LscreenLoc,@fileRdbLoc) = @_ ;
    local ($fhinLoc,$it,$tmp,$Lok,$ct,$sep_tmp,$rd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbMergeSecAcc              merging two PHD *.rdb files ('name'= acc + sec)
#-------------------------------------------------------------------------------
    $fhinLoc="FHIN_MERGE_RDB";
    $LerrLoc=0;			# files existing?
    foreach $file (@fileRdbLoc){
	if (! -e $file){&myprt_empty; $LerrLoc=1;
			&myprt_txt("ERROR: in rdbMergeDo \t file '$file' missing"); }}
    if ($LerrLoc)      {die '*** unwanted exit rdbMergeDo'; }
                                # --------------------------------------------------
                                # reading files
                                # --------------------------------------------------
    $LisAccLoc=$LisHtmLoc=$LisSecLoc=0;
    foreach $file (@fileRdbLoc){
	if (&is_rdb_sec($file)){ # secondary structure
	    $#headerSec=0;&open_file("$fhinLoc", "$file");
	    while(<$fhinLoc>){$rd=$_;
			      if(($rd=~/^\#/) && ($rd !~ /^\# NOTATION/)){
				  push(@headerSec,$rd);}
			      last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisSecLoc=1;
	    %rdSec=&rd_rdb_associative($file,"body",@desSec); }
	elsif (&is_rdb_acc($file)){ # accessibility
	    $#headerAcc=0;&open_file("$fhinLoc", "$file");
	    while(<$fhinLoc>){$rd=$_;
			      if(($rd=~/^\#/) && ($rd !~ /^\# NOTATION/)){
				  push(@headerAcc,$rd);}
			      last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisAccLoc=1;
	    %rdAcc=&rd_rdb_associative($file,"body",@desAcc);} # external lib-prot.pl
	elsif (&is_rdb_htm($file)){ # htm
	    $#headerHtm=0;&open_file("$fhinLoc", "$file");
	    while(<$fhinLoc>){$rd=$_;
			      if(($rd=~/^\#/) && ($rd !~ /^\# NOTATION/)){
				  push(@headerHtm,$rd);}
			      last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisHtmLoc=1;
	    %rdHtm=&rd_rdb_associative($file,"body",@desHtm); # external lib-prot.pl
	    foreach $ct (1..$rdHtm{"NROWS"}){
		$rdHtm{"OTN","$ct"}= $rdHtm{"OHL","$ct"};
		$rdHtm{"PTN","$ct"}= $rdHtm{"PHL","$ct"};
		$rdHtm{"PFTN","$ct"}=$rdHtm{"PFHL","$ct"};
		$rdHtm{"PRTN","$ct"}=$rdHtm{"PRHL","$ct"};
		$rdHtm{"OtT","$ct"}= $rdHtm{"OtH","$ct"};
		$rdHtm{"OtN","$ct"}= $rdHtm{"OtL","$ct"};}}
    }
				# decide when to break the line
    if ($LisHtmLoc){$desNewLine="OtN";}else{$desNewLine="Ot9";}
				# ------------------------------
				# read abbreviations
    $#header=0;
    $Lok=&open_file("$fhinLoc", "$fileAbbrRdb");
    if (!$Lok){print "*** ERROR rdbMergeDo \t no read for '$fileAbbrRdb'\n";
	       return(0);}
    while(<$fhinLoc>){$rd=$_;$rd=~s/\n//g;
		      if($rd=~/^\# NOTATION/){push(@header,$rd);}}
    close($fhinLoc);
				# --------------------------------------------------
				# write header into file
				# --------------------------------------------------
    &rdbMergeHeader($fhoutLoc,$LscreenLoc);
				# --------------------------------------------------
				# write selected columns
				# --------------------------------------------------
                                # names
    foreach $des (@desOutG) {
        if (defined $rdSec{"$des","1"}||defined $rdAcc{"$des","1"}||defined $rdHtm{"$des","1"}) {
	    if ($des eq $desNewLine){$sep_tmp="\n";}else{$sep_tmp=$sep;}
            print $fhoutLoc "$des","$sep_tmp"; }}
                                # formats
    foreach $it (1..$#format_out) {
        if (defined $rdSec{"$desOutG[$it]","1"} || defined $rdAcc{"$desOutG[$it]","1"} ||
	    defined $rdHtm{"$desOutG[$it]","1"}) {
	    if ($desOutG[$it] eq $desNewLine){$sep_tmp="\n";}else{$sep_tmp=$sep;}
            print $fhoutLoc "$format_out[$it]","$sep_tmp"; } }
                                # data
    foreach $ct (1..$rdSec{"NROWS"}){
        foreach $des("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL") {
            if ( defined $rdSec{"$des","$ct"} ) {
                $tmp="%".$formOutPrintf{"$des"};
                $rd=$rdSec{"$des","$ct"};$rd=~s/\s|\n//g;
                printf $fhoutLoc "$tmp$sep",$rd; }}
        foreach $des("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie",
                   "Ot0","Ot1","Ot2","Ot3","Ot4","Ot5","Ot6","Ot7","Ot8","Ot9") {
            if ( defined $rdAcc{"$des","$ct"} ) {
                $tmp="%".$formOutPrintf{"$des"};
                if ($des eq $desNewLine){$sep_tmp="\n";} else {$sep_tmp=$sep;}
                $rd=$rdAcc{"$des","$ct"};$rd=~s/\s|\n//g;
                printf $fhoutLoc "$tmp$sep_tmp",$rd; }}
	if (! $LisHtmLoc){
	    next;}
        foreach $des("OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN"){
            if ( defined $rdHtm{"$des","$ct"} ) {
                $tmp="%".$formOutPrintf{"$des"};
                $rd=$rdHtm{"$des","$ct"};$rd=~s/\s|\n//g;
		if ($des eq $desNewLine){$sep_tmp="\n";} else {$sep_tmp=$sep;}
                printf $fhoutLoc "$tmp$sep_tmp",$rd; }}
    }
}				# end of rdbMergeSecAcc

#===============================================================================
sub rdbMergeHeader {
    local($fhoutLoc,$LscreenLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbMergeHeader              writes the merged RDB header
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdbMergeHeader";$fhinLoc="FHIN"."$sbrName";

    print $fhoutLoc "\# Perl-RDB\n"; # keyword
    if ($LisSecLoc && $LisAccLoc && $LisHtmLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc+PHDhtm\n",
	    "\# Prediction of secondary structure, accessibility, and transmembrane helices\n";}
    elsif ($LisSecLoc && $LisAccLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc\n",
	    "\# Prediction of secondary structure, and accessibility\n";}
				# special information from header
    foreach $rd (@headerSec){$tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
			     if ($rd =~/^\# (NOTATION|Perl|PHD)/i){
				 next;}
			     $Lok{"$tmp"}=1; # to avoid duplication of information
			     print $fhoutLoc $rd;}
    foreach $rd (@headerAcc){$tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
			     if ($rd =~/^\# (NOTATION|Perl|PHD)/i){
				 next;}
			     if (defined $Lok{"$tmp"}){
				 next;}
			     $Lok{"$tmp"}=1; # to avoid duplication of information
			     print $fhoutLoc $rd;}
    foreach $rd (@headerHtm){$tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
			     if ($rd =~/^\# (NOTATION|Perl|PHD)/i){
				 next;}
			     if (defined $Lok{"$tmp"}){
				 next;}
			     $Lok{"$tmp"}=1; # to avoid duplication of information
			     print $fhoutLoc $rd;}
    foreach $desOut(@desOutG){	# notation
	$Lok=0;
	if    ($desOut =~ /^Ot[1-9]/){ # special case accessibility net out (skip 1-9)
	    next;}
	elsif ($desOut =~ /^Ot0/){ # special case accessibility net out (write 0)
	    foreach $rd(@header){
		if ($rd =~/^Ot\(n\)/){$Lok=1;
				      print $fhoutLoc "$rd\n";
				      last;}}
	    next;}
	foreach $rd(@header){
	    if ($rd =~/$desOut/){$Lok=1;
				 print $fhoutLoc "$rd\n";
				 last;}}
	if ($LscreenLoc && ! $Lok) {
	    print "-*- WARNING rdbMergeDo \t missing description for desOut=$desOut\n";}}
    print $fhoutLoc "\# \n";
}				# end of rdbMergeHeader

