#!/usr/sbin/perl4 -w
#----------------------------------------------------------------------
# hssp_extr_strip
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hssp_extr_strip.pl file_strip Nhits-to-be-extracted
#
# task:		extracts the information for N hits from a strip file
# 		
#----------------------------------------------------------------------#
#	Burkhard Rost		       March	,       1995           #
#			changed:       May	,    	1996           #
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
#push (@INC, "/home/uranus4/rost/perl") ;
push (@INC, "/home/rost/perl") ;
# require "ctime.pl"; # require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
&hssp_extr_strip_ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
if (&is_strip_old($file_in)){		# read old strip file
    @strip=
	&rd_strip_old($file_in,$excl_txt,$incl_txt,$maxlen_line,
		      $exclpos_beg,$exclpos_end,$Lscreen);}
else {				# read new strip file
    @strip=
	&rd_strip($file_in,$excl_txt,$incl_txt,
		  $maxlen_line,$exclpos_beg,$exclpos_end,$Lscreen);}

				# write output file
&open_file("$fhout",">$file_out");
foreach $line (@strip) {
    print $fhout $line;
}
close($fhout);


# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { &myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 
		&myprt_empty; &myprt_txt(" output in file: \t $file_out"); }

exit;

#==========================================================================================
sub hssp_extr_strip_ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 

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
	    if   (/excl=/ ) {    $tmp=$ARGV[$it];$tmp=~s/\n|excl=//g;
				 $excl_txt=$tmp; $excl_txt=~s/\(|\)//g; }
	    elsif(/incl=/ ) {    $tmp=$ARGV[$it];$tmp=~s/\n|incl=//g;
				 $incl_txt=$tmp; $incl_txt=~s/\(|\)//g; }
	    elsif(/not_screen/) {$Lscreen=0; }
	    elsif(/file_out=/ ) {$tmp=$ARGV[$it];$tmp=~s/\n|file_out=//g; 
				 $file_out=$tmp; }
	    elsif(/dir_in=/ )   {$tmp=$ARGV[$it];$tmp=~s/\n|dir_in=//g; 
				 $dir_in=$tmp; }
	    elsif(/dir_out=/ ) { $tmp=$ARGV[$it];$tmp=~s/\n|dir_out=//g; 
				 $dir_out=$tmp; }
	    elsif(/dir_work=/ ) {$tmp=$ARGV[$it];$tmp=~s/\n|dir_work=//g; 
				 $dir_work=$tmp; }
	}
    }

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

}				# end of hssp_extr_strip_ini

#==========================================================================================
sub rd_strip_old {
    local ($file_in,$excl_txt,$incl_txt,$maxlen_line,$exclpos_beg,$exclpos_end,$Lscreen) = @_ ;
    local ($fhin,@strip,@strip_head,@strip_tail,@strip_ali,@strip_sum,
	   $Lis_ali,$Lok,$tmp,@excl,@incl,$nalign);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_strip_old               first SUMMARY, then ALIGNMENTS
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
    $#strip_head=$#strip_tail=$#strip_ali=$#strip_sum=$#excl=$#incl=$nalign=0;
				# read file
    &open_file("$fhin","$file_in");
				# ----------------------------------------
				# header
    while (<$fhin>) {if (/^\s*alignments\s*\:/){ 
			 $tmp=$_;$tmp=~s/\s*alignments\s*:\s*//;
			 $nalign=$tmp;
			 push(@strip_head,$_); }
				# stop if                    "=== SUMMARY ==="
		     elsif (/=== SUMMARY ===/) {
			 $_= "==================================== SUMMARY ".
			     "===================================\n";
			 push(@strip_sum,$_); 
			 last;} 
		     else { 
			 push(@strip_head,$_); }}
    $Lis_ali=1;
    if ($nalign==0) {           print "*** hssp_extr_strip: error nalign=0\n";}
				# get range to be in/excluded
    if ($incl_txt!~/unk/){ @incl=&get_range($incl_txt,$nalign);} else {$#incl=0;}

				# ----------------------------------------
				# read summary
    $ct=0;
    while (<$fhin>){		# stop if                    "==="
	if (/^===/){
	    $_= "================================== ALIGNMENTS ".
		"==================================\n";
	    push(@strip_ali,$_);
	    last;}
	if (/^\s*IAL/){push(@strip_sum,$_);} # description header?
	else {
	    $pos=$_;$pos=~s/^\s*([0-9]+) .+$/$1/;$pos=~s/\D//g;
	    $Ltake_it=1;
	    if ($#excl>0) {
		foreach $i (@excl) { if ($i == $pos) { 
		    $Ltake_it=0; 
		    last;}} }
	    if (($#incl>0) && $Ltake_it) { 
		$Ltake_it=0;
		foreach $i (@incl) { if ($i == $pos) { 
		    $Ltake_it=1; 
		    last;}} }
	    if (! $Ltake_it) { 
		next; }		# don't continue if range to be excluded

	    $_=~s/\s{5,100}/ /; # purge many blanks (>5)
	    $_=~s/\n//;
	    if($maxlen_line>0){$_=substr($_,1,$maxlen_line)} # shortens lines
	    $_.="\n";
	    push(@strip_sum,$_);
	} }
    $Lis_ali=1;
				# ----------------------------------------
    while ($Lis_ali) {		# loop over all parts of the alignments
	$Lok=0;$#tmp=$ct=$ct_guide=$ct_aligned=0;
	$Ltake_it=$Lguide=$Laligned=0;
	while (<$fhin>) {
	    if (length($_)<2) {	# ignore blank lines
		next;}
				# until next line with       "=== ALIGNMENTS ==="
	    if (/=== ALIGNMENTS ===/ ){ 
		$_= "================================== ALIGNMENTS ".
		    "==================================\n";
		push(@tmp,$_);$Lis_ali=1;
		last;}
				# ignore last line
	    elsif (/=======/){
		$_= "=================================== COLLAGE =".
		    "===================================\n";
		push(@strip_tail,$_);$Lis_ali=0; 
		last;}
				# first line for alis x-(x+100), i.e. guide
	    elsif ( /^\s*\d+ -\s+\d+ / ){
		$Lguide=1;$Ltake_it=1;
		push(@tmp,$_); }
	    elsif ( $Ltake_it && $Lguide) { 
		++$ct_guide; if ($ct_guide>=4){$Lguide=0;}
		push(@tmp,$_); }
	    elsif ( /^\s*\d+\. /) { # aligned sequence
		$it=$_;$it=~s/^\s*(\d+)\..*/$1/g;$it=~s/\s//g;
		$Ltake_it=0;	# mode exclude
		foreach $i (@incl) { if ($i == $it) { 
		    $Ltake_it=1; 
		    last;} }
		if ($Ltake_it){
		    $Laligned=$Lok=1;
		    push(@tmp,$tmpx,$_);} }
	    elsif ( $Ltake_it && $Laligned) { 
		++$ct_aligned; if ($ct_aligned>=1){$Laligned=0;$ct_aligned=0;}
		push(@tmp,$_); }
	    else {$tmpx=$_;} # store one (identical residues)
	}
				# --------------------
	if ($Lok) {		# take it?
	    push(@strip_ali,@tmp);}
				# not: end sign
	elsif ( ($tmp[$#tmp] =~ /====/) && ($tmp[$#tmp] !~ /=== ALIGNMENTS ===/) ){
	    if ($strip[$#strip] =~ /=== ALIGNMENTS ===/) {
		$_= "=================================== COLLAGE =".
		    "===================================\n";
		push(@strip_tail,$_);}
	    else {
		$_= "=================================== COLLAGE =".
		    "===================================\n";
		push(@strip_tail,$_);}
	}
    }				# end of alis
				# ------------------------------

    while (<$fhin>){		# read tail
	push(@strip_tail,$_);}

    close($fhin);
				# ------------------------------
				# compose strip
    if ($strip_ali[$#strip_ali]=~/ALIGNMENTS/){	# correct end
	pop(@strip_ali);}
    @strip=(@strip_head,@strip_ali,@strip_sum,@strip_tail);

				# ------------------------------
				# write onto screen?
    if ($Lscreen) { print"--- $script_name \t read in from '$file_in'\n";
		    foreach $tmp (@strip){print"$tmp";}}
    return (@strip);
}				# end of rd_strip_old

#==========================================================================================
sub rd_strip {
    local ($file_in,$excl_txt,$incl_txt,$maxlen_line,$exclpos_beg,$exclpos_end,
	   $Lscreen) = @_ ;
    local ($fhin,@strip,@strip_head,@strip_tail,@strip_ali,@strip_sum,
	   $Lis_ali,$Lok,$tmp,@excl,@incl,$nalign);
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
    $#strip_head=$#strip_tail=$#strip_ali=$#strip_sum=$#excl=$#incl=$nalign=0;
				# get range to be in/excluded
    if ($incl_txt!~/unk/){ @incl=&get_range($incl_txt,$nalign);} else {$#incl=0;}
				# read file
    &open_file("$fhin","$file_in");
				# ----------------------------------------
				# header
    $Lsummary=0;
    while (<$fhin>) {if (/^\s*alignments\s*\:/){
			 $tmp=$_;$tmp=~s/\s*alignments\s*:\s*//;
			 $nalign=$tmp;
			 push(@strip_head,$_); }
				# stop if                    "=== SUMMARY ==="
		     elsif (/=== ALIGNMENTS ===/) {
			 $_= "==================================== ALIGNMENTS ".
			     "===================================\n";
			 push(@strip_ali,$_); 
			 last;} 
		     elsif (/=== SUMMARY ===/){
			 push(@strip_head,$_);
			 $Lsummary=1;}
		     elsif ($Lsummary){
			 if (/^\s*IAL/){
			     push(@strip_head,$_); }
			 else {
			     $tmp=substr($_,1,4);$tmp=~s/\s//g;
			     $Lok=0;
			     foreach $incl(@incl){if ($tmp==$incl){$Lok=1;
								   last;}}
			     if ($Lok){
				 push(@strip_head,$_); }}}
		     else { 
			 push(@strip_head,$_); }}
    $Lis_ali=1;
    if ($nalign==0) {           print "*** hssp_extr_strip: error nalign=0\n";}
				# ----------------------------------------
    while ($Lis_ali) {		# loop over all parts of the alignments
	$Lok=0;$#tmp=$ct=$ct_guide=$ct_aligned=0;
	$Ltake_it=$Lguide=$Laligned=0;
	while (<$fhin>) {
	    if (length($_)<2) {	# ignore blank lines
		next;}
				# until next line with       "=== ALIGNMENTS ==="
	    if (/=== ALIGNMENTS ===/ ){ 
		$_= "================================== ALIGNMENTS ".
		    "==================================\n";
		push(@tmp,$_);$Lis_ali=1;
		last;}
				# ignore last line
	    elsif (/=======/){
		$Lis_ali=0; 
		last;}
	    elsif(/^\s*\w*\s*COLLAGE/){	# new exit for new format
		$Lis_ali=0; 
		last;}
				# first line for alis x-(x+100), i.e. guide
	    elsif ( /^\s*\d+ -\s+\d+ / ){
		$Lguide=1;$Ltake_it=1;
		push(@tmp,$_); }
	    elsif ( $Ltake_it && $Lguide) { 
		++$ct_guide; if ($ct_guide>=4){$Lguide=0;} # read five lines
		push(@tmp,$_); }
	    elsif ( /^\s*\d+\. /) { # aligned sequence: first line
		$it=$_;$it=~s/^\s*(\d+)\..*/$1/g;$it=~s/\s//g;
		$Ltake_it=0;	# mode exclude
		foreach $i (@incl) { if ($i == $it) { 
		    $Ltake_it=1; 
		    last;} }
		if ($Ltake_it){
		    $Laligned=$Lok=1;
		    push(@tmp,$tmpx,$_);} }
	    elsif ( $Ltake_it && $Laligned) { # aligned sequence: other lines
		++$ct_aligned; if ($ct_aligned>=1){$Laligned=0;$ct_aligned=0;}
		push(@tmp,$_); }
	    else {$tmpx=$_;} # store one (identical residues)
	}
				# --------------------
	if ($Lok) {		# take it?
	    push(@strip_ali,@tmp);}
	if (! <$fhin>){$Lis_ali=0;} # hack if file empty!
				# not: end sign
    }
				# ----------------------------------------
				# read summary
    $ct=0;
    while (<$fhin>){		# stop if                    "==="
	if (/^===/){
	    $_= "=================================== COLLAGE =".
		"===================================\n";
	    push(@strip_tail,$_);
	    last;}
	elsif(/^\s*\w*\s*COLLAGE/){	# new exit for new format
	    $_= "=================================== COLLAGE =".
		"===================================\n";
	    push(@strip_tail,$_);
	    last;}
	if (/^\s*IAL/){push(@strip_sum,$_);} # description header?
	else {
	    $pos=$_;$pos=~s/^\s*([0-9]+) .+$/$1/;$pos=~s/\D//g;
	    $Ltake_it=1;
	    if ($#excl>0) {
		foreach $i (@excl){ if ($i eq $pos){$Ltake_it=0; 
						    last;}} }
	    if (($#incl>0) && $Ltake_it) { 
		$Ltake_it=0;
		foreach $i (@incl){ if ($i eq $pos) {$Ltake_it=1; 
						     last;}} }
	    if (! $Ltake_it) { next; } # don't continue if range to be excluded

	    $_=~s/\s{5,100}/ /; # purge many blanks (>5)
	    $_=~s/\n//;
	    if($maxlen_line>0){$_=substr($_,1,$maxlen_line)} # shortens lines
	    $_.="\n";
	    push(@strip_sum,$_);
	} }
    $Lis_ali=1;
				# ------------------------------
    while (<$fhin>){		# read tail
	push(@strip_tail,$_);}
    close($fhin);
				# ------------------------------
				# compose strip
    if ($strip_ali[$#strip_ali]=~/ALIGNMENTS/){	# correct end
	pop(@strip_ali);}
    @strip=(@strip_head,@strip_ali,@strip_sum,@strip_tail);
				# ------------------------------
				# write onto screen?
    if ($Lscreen) { print"--- $script_name \t read in from '$file_in'\n";
		    foreach $tmp (@strip){print"$tmp";}}
    return (@strip);
}				# end of rd_strip

