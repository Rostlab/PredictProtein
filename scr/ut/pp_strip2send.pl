#!/usr/local/bin/perl -w
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
				# initialise variables
				# --------------------------------------------------
&ini();

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------

				# read strip file
($ntaken,@strip)=
    &rd_strip($fileIn,$excl_txt,$incl_txt,$maxlen_line,$exclpos_beg,$exclpos_end,$Lscreen);

if ($ntaken==0){
    die '*** pp_strip2send none read, in=$fileIn';}
				# write output file
&open_file("$fhout",">$fileOut");
print $fhout "--- \n";
print $fhout "--- ------------------------------------------------------------\n";
print $fhout "--- TOPITS prediction-based threading \n";
print $fhout "--- ------------------------------------------------------------\n";
print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS HEADER: PARAMETERS\n";
				# header
foreach $des (@desh){
    $tmp1=$des_expl{$des};$tmp2=length($tmp1);$tmp="$tmp2"."s";
    if ($des eq "mix"){
	printf $fhout 
	    "--- %-7s = %-3d: %-$tmp,i.e. str=%3d%1s, seq=%3d%1s\n",
	    "str:seq",int($mix),$des_expl{$des},int($mix),"%",int(100-$mix),"%";}
    else {
	printf $fhout "--- %-5s= %-6s: %-$tmp\n",$des,$rdh{$des},$des_expl{$des};}}

print $fhout "--- \n";
print $fhout "--- TOPITS ALIGNMENTS HEADER: ABBREVIATIONS\n";
				# explanations
foreach $des ("RANK",@des){
    $tmp1=$des_expl{$des};$tmp2=length($tmp1);$tmp="$tmp2"."s";
    $tmp=length($des_expl{$des});$tmp.="s";
    $des2=$des; $des2=~tr/[a-z]/[A-Z]/;
    printf $fhout "--- %-12s : %-$tmp\n",$des2,$des_expl{$des};}

print  $fhout "--- \n";
print  $fhout "--- TOPITS ALIGNMENTS HEADER: ACCURACY\n";
printf $fhout "--- %-12s : %-s\n"," ","Tested on 80 proteins, TOPITS found the";
printf $fhout "--- %-12s : %-s\n"," ","correct remote homologue in about 30% of";
printf $fhout "--- %-12s : %-s\n"," ","the cases, detection accuracy was higher";
printf $fhout "--- %-12s : %-s\n"," ","for higher z-scores (ZALI):";
printf $fhout "--- %-12s : %-s\n","ZALI>0  ","1st hit correct in 33% of cases";
printf $fhout "--- %-12s : %-s\n","ZALI>3  ","1st hit correct in 50% of cases";
printf $fhout "--- %-12s : %-s\n","ZALI>3.5","1st hit correct in 60% of cases";
print  $fhout "--- \n";
print  $fhout "--- TOPITS ALIGNMENTS HEADER: SUMMARY\n";
printf $fhout " %4s ","RANK"; # descriptor
foreach $des (@des){
    $tmp=$ptr_form_txt{$des};
    $tmp2=$des;$tmp2=~tr/[a-z]/[A-Z]/;
    printf $fhout "%$tmp ",$tmp2;
}print $fhout "\n";
				# data
foreach $it(1..$ntaken){
    printf $fhout " %4d ",$it;
    foreach $des (@des){
	$tmp=$ptr_form{$des};
	printf $fhout "%$tmp ",$rds{"$des","$it"};
    }print $fhout "\n";
}
print  $fhout "--- \n";
print  $fhout "--- TOPITS ALIGNMENTS: SYMBOLS AND EXPLANATIONS\n";
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
print  $fhout "--- \n";
print  $fhout "--- TOPITS ALIGNMENTS\n";
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
print "--- output in file: \t $fileOut\n" if ($Lscreen);
    
exit;



#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_range                   converts range=n1-n2 into @range (1,2)
#       in:                     'n1-n2' NALL: e.g. incl=1-5,9,15 
#                               n1= begin, n2 = end, * for wild card
#                               NALL = number of last position
#       out:                    @takeLoc: begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    $#range=0;
    if (! defined $range_txt || length($range_txt)<1 || $range_txt eq "unk" 
	|| $range_txt !~/\d/ ) {
	print "*** ERROR in get_range: argument: range=$range_txt, nall=$nall, not digestable\n"; 
	return(0);}
    $range_txt=~s/\s//g;	# purge blanks
    $nall=0                     if (! defined $nall);
				# already only a number
    return($range_txt)          if ($range_txt !~/[^0-9]/);
    
    if ($range_txt !~/[\-,]/) {	# no range given
	print "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n"; 
	return(0);}
				# ------------------------------
				# dissect commata
    if    ($range_txt =~ /\,/) {
	@range=split(/,/,$range_txt);}
				# ------------------------------
				# dissect hyphens
    elsif ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	@range=&get_rangeHyphen($range_txt,$nall);}

				# ------------------------------
				# process further elements with hyphens
    $#range2=0;
    foreach $range (@range){
	if ($range =~ /(\d*|\*)-(\d*|\*)/) {
	    push(@range2,&get_rangeHyphen($range,$nall));}
	else {
            push(@range2,$range);}}
    @range=@range2; $#range2=0;
				# ------------------------------
    if ($#range>1){		# sort
	@range=sort {$a<=>$b} @range;}
    return (@range);
}				# end of get_range

#==============================================================================
sub get_rangeHyphen {
    local ($range_txt,$nall) = @_ ;
    local (@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_rangeHyphen             reads 'n1-n2'  
#       in:                     'n1-n2', NALL (n1= begin, n2 = end, * for wild card)
#                               NALL = number of last position
#       out:                    begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    if ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	($range1,$range2)=split(/-/,$range_txt);
	if ($range1=~/\*/) {$range1=1;}
	if ($range2=~/\*/) {$range2=$nall;} 
	for($it=$range1;$it<=$range2;++$it) {
	    push(@rangeLoc,$it);} }
    else { 
	@rangeLoc=($range_txt);}
    return(@rangeLoc);
}				# end of get_rangeHyphen

#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file



#==============================================================================
# library collected (end)
#==============================================================================


1;
#==========================================================================================
sub ini {
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------

    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
    $scrIn=         "file_strip ";
    $scrGoal=       "extracts the information for N hits from a strip file";

				# ------------------------------
				# defaults
    %par=(
	  '', "",			# 
	  );
    @kwd=sort (keys %par);
				# ------------------------------
    if ($#ARGV<1){			# help
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName $scrIn'\n";
	print  "opt:  \n";
	#      'keyword'   'value'    'description'
	printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x", "";
	printf "%5s %-15s=%-20s %-s\n","","dirWork",  "x", "";
	printf "%5s %-15s=%-20s %-s\n","","mix",      "x", "mix str:seq";
	printf "%5s %-15s=%-20s %-s\n","","excl",     "x", "sequences n1 to n2 will be excluded: n1-*, n1-n2, or: n1,n5,... ";
	printf "%5s %-15s=%-20s %-s\n","","incl",   "x", "sequences m1 to m2 will be included: m1-*, m1-m2, or: m1,m5,... ";
#	printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#	printf "%5s %-15s %-20s %-s\n","","",   "no value","";

	printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
    $fhin="FHIN";$fhout="FHOUT";

    $dirWork=  "";
				# --------------------
				# files
				# file extensions
				# file handles
    $fhout=     "FHOUT";
    $fhin=      "FHIN";
				# --------------------
				# further
    $cutoff_name2="25";
    $excl_txt=  0;		# n-m -> exclude positions n to m
    $incl_txt=  0;

    $maxlen_line=130;		# shorten strip lines to < this
				# --------------------
				# logicals
    $Lscreen=   1;		# blabla on screen
    $Ldebug=    0;

				# ------------------------------
				# read command line

    $fileIn=   $ARGV[1];	# name of strip HSSP
    $fileOut=  $fileIn . "_extr"; 

    foreach $arg (@ARGV){
	next if ($arg eq $ARGV[1]);
	if    ($arg=~/^(fileOut|file_out)=(.*)$/)  { $fileOut=  $2;}
	elsif ($arg=~/^excl=(.*)$/)                { $excl_txt= $1;}
	elsif ($arg=~/^incl=(.*)$/)                { $incl_txt= $1;}
	elsif ($arg=~/^mix=(.*)$/)                 { $mix=      $1;}
	elsif ($arg=~/^de?bu?g/i)                  { $Lscreen=  1;
						     $Ldebug=   1; }
	elsif ($arg=~/not_screen|noScreen/i)       { $Lscreen=0; }
#	elsif ($arg=~/^=(.*)$/){ $=$1;}
	else {
	    $Lok=0; 
	    if (defined %par && $#kwd>0) { 
		foreach $kwd (@kwd){ 
		    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					       last;}}}
	    if (! $Lok){ print "*** wrong command line arg '$arg'\n";
			 exit;}}}


    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    
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
	$ptr_form{$des}="4d";$ptr_form_txt{$des}="4s";}
    
    
    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    $dirWork.="/"               if ($dirWork && length($dirWork) > 1
				    && $dirWork!~/\/$/);


    if ($Lscreen) { print "--- $scrName: fileIn =$fileIn\n";
		    print "--- $scrName: fileout=$fileOut\n";
		    print "--- $scrName: exclPos=$excl_txt\n" if ($excl_txt);
		    print "--- $scrName: inclPos=$incl_txt\n" if ($incl_txt); 
		}


    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($fileIn)>0) && (! -e $fileIn) ) {
	print "*** ERROR $scrName: missing input file=$fileIn!\n";
	exit(0); }
}				# end of ini

#==========================================================================================
sub rd_strip {
    local ($fileIn,$excl_txt,$incl_txt,$maxlen_line,
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
    &open_file("$fhin","$fileIn");
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
    if ($incl_txt){ 
	print "xx 1 came in with incl_txt=$incl_txt, got range=",join(",",@incl,"\n");
	@incl=&get_range($incl_txt,$nalign);} 
    else {
	$#incl=0;}

				# ----------------------------------------
				# read summary
    $ct=$#strip=$Lfst=0;
    while (<$fhin>){		# stop if                    "==="
	if ($_=~/^\s*===/){
	    if (! $Lfst) {
		$Lfst=1;}
	    else { $_= "--- \n--- TOPITS ALIGNMENTS CONTINUED \n--- \n";
		   push(@strip,$_);}
	    last;}
	if ($_=~/^\s*IAL/){
	    next;}		# description header?
	else {
	    $pos=$_;$pos=~s/^\s*([0-9]+) .+$/$1/;$pos=~s/\D//g;
	    $Ltake_it=1;
	    if ($#excl>0) {
		foreach $i (@excl) { 
		    if ($i == $pos) { 
			$Ltake_it=0; 
			last;}} }
	    if (($#incl>0) && $Ltake_it) { 
		$Ltake_it=0;
		foreach $i (@incl) { 
		    if ($i == $pos) { 
			$Ltake_it=1; 
			last;}} }
	    next if (! $Ltake_it);  # don't continue if range to be excluded

	    $_=~s/\s{5,100}/ /; # purge many blanks (>5)
	    $_=~s/\n//;
	    $_=substr($_,1,$maxlen_line) if ($maxlen_line>0);  # shortens lines
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
				# ----------------------------------------
				# hack 99-03: somehow strange numbers at
				#             end of strip file, hack out
				# ----------------------------------------
	    next if ($_=~/^\s*\d+\s*\d+\s*\d+\s*$/);


	    $tmpLine=$_;
				# until next line with       "=== ALIGNMENTS ==="
	    if ($_=~/=== ALIGNMENTS ===/){
		$_= "--- \n--- TOPITS ALIGNMENTS CONTINUED \n--- \n";
		push(@tmp,$_);
		$Lis_ali=1;
		last;}
				# stop if                    "COLLAGE"
				# ignore last line
	    elsif ($_=~/=======|\/\//){
		$Lis_ali=0;
		last; }
				# first line for alis x-(x+100), i.e. guide
	    elsif ( $_=~/^\s*\d+ -\s+\d+ / ){
		$Lguide=1;$Ltake_it=1;
		push(@tmp,$_); }
	    elsif ( $Ltake_it && $Lguide) { 
		++$ct_guide; 
		if ($ct_guide>=3){
		    $Lguide=0;
		    $_.="\n";}
		push(@tmp,$_); }
	    elsif ( $_=~/^\s*\d+\. /) { # aligned sequence
		$it=$_;$it=~s/^\s*(\d+)\..*/$1/g;$it=~s/\s//g;
		$Ltake_it=0;	# mode exclude
		foreach $i (@incl) { 
		    if ($i == $it) { 
			$Ltake_it=1; 
			last;} }
		if ($Ltake_it){
		    $Laligned=$Lok=1;
		    push(@tmp,$_); }}
	    elsif ($Ltake_it && $Laligned) {  
		++$ct_aligned; 
		if ($ct_aligned>=2){
		    $Laligned=0;
		    $ct_aligned=0;}
		push(@tmp,$_); }
	}
	$Lis_ali=0              if (length($tmpLine)<1 || ! <$fhin>);
				# --------------------
				# take it?
	push(@strip,@tmp)       if ($Lok);
	    
    }				# end of alis
				# ------------------------------
    close($fhin);
				# not: end sign
    $tmp1=$#strip-3;
    $tmp2=$#strip;
    foreach $it ( $tmp1 .. $tmp2 ) {
	next if (! defined $strip[$it]);
	$strip[$it]=""          if ($strip[$it]=~/^---/); }

				# ------------------------------
				# write onto screen?
    if ($Lscreen) { print"--- $scrName \t read in from '$fileIn'\n";
		    foreach $tmp (@strip){
			print "$tmp";}}
    return ($nread,@strip);
}				# end of rd_strip

#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system #
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost         rost@columbia.edu                                         #
# http://cubic.bioc.columbia.edu/~rost/                                           #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu                             #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu                             #
#                                                                                 #
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 #
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            #
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               #
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#================================================================================ #
