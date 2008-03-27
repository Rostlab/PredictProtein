#!/usr/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl4 -w
#----------------------------------------------------------------------
# hssp_extr_strip
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hssp_extr_strip.pl file_strip Nhits-to-be-extracted
#
# task:		extracts the information for N hits from a strip file
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       March	,       1995           #
#			changed:       August	,    	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[ =1 ;
				# --------------------------------------------------
				# include libraries
				# --------------------------------------------------
require "/home/phd/ut/perl/ctime.pl";
require "/home/phd/ut/perl/lib-prot.pl";
require "/home/phd/ut/perl/lib-ut.pl";
require "/home/phd/ut/perl/lib-comp.pl";
#require "/home/phd/ut/perl/lib-pp.pl";
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
&ini();

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------

				# read strip file
($ntaken,@strip)=
    &rd_strip($file_in,$excl_txt,$incl_txt,$maxlen_line,$exclpos_beg,$exclpos_end,$Lscreen);

if ($ntaken==0){
    die '*** pp_strip2send none read, in=$file_in';}
				# write output file
&open_file("$fhout",">$file_out");
print $fhout "--- \n";
print $fhout "--- ------------------------------------------------------------\n";
print $fhout "--- TOPITS prediction-based threading \n";
print $fhout "--- ------------------------------------------------------------\n";
print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS HEADER: PARAMETERS\n";
				# header
foreach $des (@desh){
    $tmp1=$des_expl{"$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
    if ($des eq "mix"){
	printf $fhout 
	    "--- %-7s = %-3d: %-$tmp,i.e. str=%3d\%, seq=%3d\%\n","str:seq",
	    int($mix),$des_expl{"$des"},int($mix),int(100-$mix);}
    else {
	printf $fhout "--- %-5s= %-6s: %-$tmp\n",$des,$rdh{"$des"},$des_expl{"$des"};}}

print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS HEADER: ABBREVIATIONS\n";
				# explanations
foreach $des ("RANK",@des){
    $tmp1=$des_expl{"$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
    $tmp=length($des_expl{"$des"});$tmp.="s";
    $des2=$des; $des2=~tr/[a-z]/[A-Z]/;
    printf $fhout "--- %-12s : %-$tmp\n",$des2,$des_expl{"$des"};}

print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS HEADER: ACCURACY\n";
printf $fhout "--- %-12s : %-s\n"," ","Tested on 80 proteins, TOPITS found the";
printf $fhout "--- %-12s : %-s\n"," ","correct remote homologue in about 30% of";
printf $fhout "--- %-12s : %-s\n"," ","the cases, detection accuracy was higher";
printf $fhout "--- %-12s : %-s\n"," ","for higher z-scores (ZALI):";
printf $fhout "--- %-12s : %-s\n","ZALI>0  ","1st hit correct in 33% of cases";
printf $fhout "--- %-12s : %-s\n","ZALI>3  ","1st hit correct in 50% of cases";
printf $fhout "--- %-12s : %-s\n","ZALI>3.5","1st hit correct in 60% of cases";
print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS HEADER: SUMMARY\n";
printf $fhout " %4s ","RANK"; # descriptor
foreach $des (@des){
    $tmp=$ptr_form_txt{"$des"};
    $tmp2=$des;$tmp2=~tr/[a-z]/[A-Z]/;
    printf $fhout "%$tmp ",$tmp2;
}print $fhout "\n";
				# data
foreach $it(1..$ntaken){
    printf $fhout " %4d ",$it;
    foreach $des (@des){
	$tmp=$ptr_form{"$des"};
	printf $fhout "%$tmp ",$rds{"$des","$it"};
    }print $fhout "\n";
}
print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS: SYMBOLS AND EXPLANATIONS\n";
printf $fhout "--- %-12s : %-s\n","BLOCK 1","your protein and its predicted 1D structure,";
printf $fhout "--- %-12s : %-s\n","","i.e., secondary structure and solvent accessibility";
printf $fhout "--- %-12s : %-s\n","line 1","amino acid sequence (one-letter-code)";
printf $fhout "--- %-12s : %-s\n","line 2","predicted secondary structure:";
printf $fhout "--- %-12s : %-s\n","H","helix";
printf $fhout "--- %-12s : %-s\n","E","strand (extended)";
printf $fhout "--- %-12s : %-s\n","L","other (no regular secondary structure)";
printf $fhout "--- %-12s : %-s\n","line 3","predicted residue relative solvent accessibility";
printf $fhout "--- %-12s : %-s\n","B","buried, i.e., relative accessibility < 15%";
printf $fhout "--- %-12s : %-s\n","O","exposed (outside), i.e., relative accessibility >= 15%";
printf $fhout "--- %-12s : %-s\n","","";
printf $fhout "--- %-12s : %-s\n","BLOCKS 1-20","20 best hits of the prediction-based threading ";
printf $fhout "--- %-12s : %-s\n","   ATTENTION","We chose to include all first 20 hit.  However,";
printf $fhout "--- %-12s : %-s\n","   ATTENTION","most of them will not constitute true remote";
printf $fhout "--- %-12s : %-s\n","   ATTENTION","homologues.  Instead, all hits with a zscore ";
printf $fhout "--- %-12s : %-s\n","   ATTENTION","(ZALI) < 3.5 are, at best, rather speculative!";
printf $fhout "--- %-12s : %-s\n","","for each aligned protein:";
printf $fhout "--- %-12s : %-s\n","line 1","amino acids conserved between guide (yours) and the";
printf $fhout "--- %-12s : %-s\n","","aligned protein (putative homologue)";
printf $fhout "--- %-12s : %-s\n","line 1","sequence of aligned protein";
printf $fhout "--- %-12s : %-s\n","line 3","secondary structure, taken from DSSP (assignment";
printf $fhout "--- %-12s : %-s\n","","of secondary structure based on experimental coordinates)";
printf $fhout "--- %-12s : %-s\n","line 4","relative solvent accessibility, taken from DSSP";
print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS\n";
foreach $line (@strip) {
    print $fhout $line;
}
print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS END\n";
print $fhout "--- \n";
close($fhout);


# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
print "--- output in file: \t $file_out\n" if ($Lscreen);
    
exit;

#==========================================================================================
sub ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "hssp_extr_strip";
    $script_input=  "file_strip ";
    $script_goal=   "extracts the information for N hits from a strip file";
    $script_narg=   1;
    @script_goal=   (" ",
		     "Task: \t $script_goal",
		     " ",
		     "Input:\t $script_input",
		     " ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$script_name help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("excl=n1-n2 ",
		     "incl=m1-m2 ",
		     "mix= ",
		     " ",
		     "not_screen",
		     "file_out=",
		     "dir_in=",
		     "dir_out=",
		     "dir_work=",
		     );
    @script_opt_keydes= 
	            ("sequences n1 to n2 will be excluded: n1-*, n1-n2, or: n1,n5,... ",
		     "sequences m1 to m2 will be included: m1-*, m1-m2, or: m1,m5,... ",
		     "mix str:seq ",
		     " ",
		     "no information written onto screen",
		     "output file name",
		     "input dir name,   default: local",
		     "output dir name,  default: local",
		     "working dir name, default: local",
		     );

    if ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) { &myprt_txt("$txt"); } &myprt_empty; 
	&myprt_txt("usage: \t $script_name $script_input"); 
	&myprt_empty;&myprt_txt("optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf "--- %-12s %-s \n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){&myprt_txt("$txt");}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
				# --------------------
				# directories
    $dir_in=    "";
    $dir_out=   "";
    $dir_work=  "";
				# --------------------
				# files
				# file extensions
				# file handles
    $fhout=     "FHOUT";
    $fhin=      "FHIN";
				# --------------------
				# further
    $cutoff_name2="25";
    $excl_txt=  "unk";		# n-m -> exclude positions n to m
    $incl_txt=  "unk";

    $maxlen_line=130;		# shorten strip lines to < this
				# --------------------
				# logicals
    $Lscreen=   1;		# blabla on screen
				# --------------------
				# executables

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $file_in=   $ARGV[1];	# name of strip HSSP
				# output file
    $file_out=  $file_in . "_extr"; 

    if ($#ARGV>$script_narg) {
	for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	    $_=$ARGV[$it];
	    if   ($_=~/excl=/ ) {    $tmp=$ARGV[$it];$tmp=~s/\n|excl=//g;
				     $excl_txt=$tmp; $excl_txt=~s/\(|\)//g; }
	    elsif($_=~/incl=/ ) {    $tmp=$ARGV[$it];$tmp=~s/\n|incl=//g;
				     $incl_txt=$tmp; $incl_txt=~s/\(|\)//g; }
	    elsif($_=~/mix=(.*)/ )  {$mix=$1;}
	    elsif($_=~/not_screen/) {$Lscreen=0; }
	    elsif($_=~/file_out=/ ) {$tmp=$ARGV[$it];$tmp=~s/\n|file_out=//g; 
				     $file_out=$tmp; }
	    elsif($_=~/dir_in=/ )   {$tmp=$ARGV[$it];$tmp=~s/\n|dir_in=//g; 
				     $dir_in=$tmp; }
	    elsif($_=~/dir_out=/ ) { $tmp=$ARGV[$it];$tmp=~s/\n|dir_out=//g; 
				     $dir_out=$tmp; }
	    elsif($_=~/dir_work=/ ) {$tmp=$ARGV[$it];$tmp=~s/\n|dir_work=//g; 
				     $dir_work=$tmp; }
	}
    }
    $des_expl{"RANK"}="rank in alignment list, sorted according to z-score";
    $des_expl{"mix"}= "weight structure/sequence";
    $des_expl{"smin"}="minimal value of alignment metric";
    $des_expl{"smax"}="maximal value of alignment metric";
    $des_expl{"go"}="gap open penalty";
    $des_expl{"ge"}="gap elongation penalty";
    $des_expl{"len1"}="length of search sequence, i.e., your protein";
    $des_expl{"Eali"}="alignment score";
    $des_expl{"lali"}="length of alignment";
    $des_expl{"idel"}="number of residues inserted";
    $des_expl{"ndel"}="number of insertions";
    $des_expl{"zali"}="alignment zcore;  note: hits with z>3 more reliable ";
    $des_expl{"pide"}="percentage of pairwise sequence identity";
    $des_expl{"len2"}="length of aligned protein structure";
    $des_expl{"id2"}="PDB identifier of aligned structure";
    $des_expl{"name2"}="name of aligned protein structure";

    @desh=("mix","smin","smax","go","ge","len1");
    @des= ("Eali","lali","idel","ndel","zali","pide","len2","id2","name2");

    $ptr_form{"Eali"}="6.2f";$ptr_form_txt{"Eali"}="6s";
    $ptr_form{"zali"}="6.2f";$ptr_form_txt{"zali"}="6s";
    $ptr_form{"id2"}="4s";$ptr_form_txt{"id2"}="4s";
    $ptr_form{"name2"}="-$cutoff_name2"."s";$ptr_form_txt{"name2"}="-$cutoff_name2"."s";
    foreach $des ("lali","idel","ndel","pide","len2") {
	$ptr_form{"$des"}="4d";$ptr_form_txt{"$des"}="4s";}
    
    
    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    if (length($dir_in)>1) {   &complete_dir($dir_in);$dir_in=$DIR;
			       $tmp=$file_in; $file_in="$dir_in"."$tmp";}
    if (length($dir_out)>1) {  &complete_dir($dir_out);$dir_out=$DIR;
			       $tmp=$file_out; $file_out="$dir_out"."$tmp";}
    if (length($dir_work)>1) { &complete_dir($dir_work);$dir_work=$DIR; }


    if ($Lscreen) { &myprt_line; &myprt_txt("perl script that $script_goal"); 
		    &myprt_empty; 
		    &myprt_txt("file_in: \t \t $file_in"); 
		    &myprt_txt("file_out:\t \t $file_out"); 
		    if ($excl_txt!~/unk/) {&myprt_txt("exclude pos:\t\t$excl_txt"); }
		    if ($incl_txt!~/unk/) {&myprt_txt("include pos:\t\t$incl_txt"); }
		    &myprt_txt("end of setting up,\t let's work on it"); 
		    &myprt_empty; &myprt_line; &myprt_empty; }

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($file_in)>0) && (! -e $file_in) ) {
	&myprt_empty;&myprt_txt("ERROR $script_name:\t file_in '$file_in' does not exist");exit;}

}				# end of ini

#==========================================================================================
sub rd_strip {
    local ($file_in,$excl_txt,$incl_txt,$maxlen_line,
	   $exclpos_beg,$exclpos_end,$Lscreen) = @_ ;
    local ($fhin,@strip,$Lis_ali,$Lok,$tmp,@excl,@incl,$nalign);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_strip                       
#         reads the information for the N first hits from strip file
#       in:
#         strip file, extr_txt,incl_txt,maximal length of output lines
#                               excl_txt="n1-n2", or "*-n2", or "n1,n3,..."
#                               incl_txt="n1-n2", or "*-n2", or "n1,n3,..."
#       out:
#         @strip                all lines extracted (returned)
#         A                     A
#--------------------------------------------------------------------------------
				# settings
    $fhin="FHIN_STRIP";
    $#strip=$#excl=$#incl=$nalign=0;
				# read file
    &open_file("$fhin","$file_in");
				# ----------------------------------------
				# header
    while (<$fhin>) {
	if ($_=~/^\s*alignments\s*\:/){ 
	    $tmp=$_;$tmp=~s/\s*alignments\s*:\s*//;
	    $nalign=$tmp;}
				# stop if                    "=== SUMMARY ==="
	elsif ($_=~/==+\s+SUMMARY\s+==+/) {
	    last;} 
	if ($_=~/^\s*seq_length/){   
	    $tmp=$_;$tmp=~s/^\sseq_length\s*\://g;
	    $tmp=~s/\s|\n//g;
	    $rdh{"len1"}=$tmp;}
	elsif ($_=~/^\s*smax/){
	    $tmp=$_;$tmp=~s/^\ssmax\s*\://g;
	    $tmp=~s/\s|\n//g;
	    $rdh{"smax"}=$tmp;}
	elsif ($_=~/^\s*smin/){
	    $tmp=$_;$tmp=~s/^\ssmin\s*\://g;
	    $tmp=~s/\s|\n//g;
	    $rdh{"smin"}=$tmp;}
	elsif ($_=~/^\s*gap_open/){
	    $tmp=$_;$tmp=~s/^\sgap_open\s*\://g;
	    $tmp=~s/\s|\n//g;
	    $rdh{"go"}=$tmp;}
	elsif ($_=~/^\s*gap_elongation/){
	    $tmp=$_;$tmp=~s/^\sgap_elongation\s*\://g;
	    $tmp=~s/\s|\n//g;
	    $rdh{"ge"}=$tmp;}
    }

    if ($nalign==0) {           print "*** hssp_extr_strip: error nalign=0\n";
				return(0);}
				# get range to be in/excluded
    if ($incl_txt!~/unk/){ @incl=&get_range($incl_txt,$nalign);} else {$#incl=0;}

				# ----------------------------------------
				# read summary
    $ct=$#strip=$Lfst=0;
    while (<$fhin>){		# stop if                    "==="
	if ($_=~/^\s*===/){
	    if (! $Lfst) {$Lfst=1;}
	    else { $_= "--- \n--- TOPITS ALIGNMENTS CONTINUED \n--- \n";
		   push(@strip,$_);}
	    last;}
	if ($_=~/^\s*IAL/){
	    next;}		# description header?
	else {
	    $pos=$_;$pos=~s/^\s*([0-9]+) .+$/$1/;$pos=~s/\D//g;
	    $Ltake_it=1;
	    if ($#excl>0) {
		foreach $i (@excl) { if ($i == $pos) { $Ltake_it=0; last;}} }
	    if (($#incl>0) && $Ltake_it) { 
		$Ltake_it=0;
		foreach $i (@incl) { if ($i == $pos) { $Ltake_it=1; last;}} }
	    if (! $Ltake_it) { next; } # don't continue if range to be excluded

	    $_=~s/\s{5,100}/ /; # purge many blanks (>5)
	    $_=~s/\n//;
	    if($maxlen_line>0){$_=substr($_,1,$maxlen_line)} # shortens lines
	    $_=~s/^\s*|\s$//g;	# purge leading blanks
	    $#tmp=0;@tmp=split(/\s+/,$_);
	    ++$ct;
	    $rds{"Eali","$ct"}=$tmp[2];
	    $rds{"lali","$ct"}=$tmp[3];
	    $rds{"idel","$ct"}=$tmp[4];
	    $rds{"ndel","$ct"}=$tmp[5];
	    $rds{"zali","$ct"}=$tmp[6];
	    $rds{"pide","$ct"}=int(100*$tmp[7]);
	    $rds{"len2","$ct"}=$tmp[9];
	    $rds{"id2","$ct"}=$tmp[12];
	    $rds{"name2","$ct"}=substr($_,76,$cutoff_name2);
	} }
    $nread=$ct;
    $Lis_ali=1;
				# ----------------------------------------
    while ($Lis_ali) {		# loop over all parts of the alis
	$Lok=0;$#tmp=$ct=$ct_guide=$ct_aligned=0;
	$Ltake_it=$Lguide=$Laligned=0;
	while (<$fhin>) {
	    $tmpLine=$_;
				# until next line with       "=== ALIGNMENTS ==="
	    if ($_=~/=== ALIGNMENTS ===/){
		$_= "--- \n--- TOPITS ALIGNMENTS CONTINUED \n--- \n";
		push(@tmp,$_);$Lis_ali=1;
		last;}
				# stop if                    "COLLAGE"
				# ignore last line
	    elsif ($_=~/=======|\/\//){$Lis_ali=0;
				   last; }
				# first line for alis x-(x+100), i.e. guide
	    elsif ( $_=~/^\s*\d+ -\s+\d+ / ){
		$Lguide=1;$Ltake_it=1;
		push(@tmp,$_); }
	    elsif ( $Ltake_it && $Lguide) { 
		++$ct_guide; if ($ct_guide>=3){$Lguide=0;$_.="\n ";}
		push(@tmp,$_); }
	    elsif ( $_=~/^\s*\d+\. /) { # aligned sequence
		$it=$_;$it=~s/^\s*(\d+)\..*/$1/g;$it=~s/\s//g;
		$Ltake_it=0;	# mode exclude
		foreach $i (@incl) { if ($i == $it) { $Ltake_it=1; last;} }
		if ($Ltake_it){$Laligned=$Lok=1;
			       push(@tmp,$tmpx,$_);} }
	    elsif ( $Ltake_it && $Laligned) { 
		++$ct_aligned; if ($ct_aligned>=2){$Laligned=0;$ct_aligned=0;}
		push(@tmp,$_); }
	    else {$tmpx=$_;} # store one (identical residues)
	}
	$Lis_ali=0 if (length($tmpLine)<1 || ! <$fhin>);
				# --------------------
	if ($Lok) {		# take it?
	    push(@strip,@tmp);}
    }				# end of alis
				# ------------------------------
    close($fhin);
				# not: end sign
    $tmp1=$#strip-3;
    $tmp2=$#strip;
    foreach $it ( $tmp1 .. $tmp2 ) {
	if ($strip[$it]=~/^---/) {$strip[$it]="";}}
				# ------------------------------
				# write onto screen?
    if ($Lscreen) { print"--- $script_name \t read in from '$file_in'\n";
		    foreach $tmp (@strip){print"$tmp";}}
    return ($nread,@strip);
}				# end of rd_strip
