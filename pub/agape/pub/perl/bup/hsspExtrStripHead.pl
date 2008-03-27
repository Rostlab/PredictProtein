#!/usr/sbin/perl4 -w
#----------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "hssp_extr_stripHeader";	# name of script
$scriptIn=     "file.strip (or list or *.strip)";		# input
$scriptTask=   "extracts information from HSSP.strip header";	# task
$scriptNarg=   1;		# minimal number of input arguments
#------------------------------------------------------------------------------#
#	Copyright				February,	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	February,	1997	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# ------------------------------
				# include perl libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

$Lok=&ini(@ARGV);		# initialise variables
if (! $Lok){ die; }

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
$Lok=&wrtRdbHeader($fhout,"\t",$fileOut);
if (!$Lok){print "*** ERROR\n";
	   die '$scriptName unnatural death';}

$ctAll=0;			# count through all hits
foreach $fileIn(@fileIn){
    $id=$fileIn;$id=~s/^.*\/\..*$|-.*$//g;$id=~s/[DFHdfh]ssp//g;$id=~s/[._!]//g;
    if ($Lscreen){ print "--- $scriptName \t $fileIn\n";}
				# IAL,VAL,LEN,IDEL,NDEL,ZSCORE,IDEN,
				# STRHOM,LEN2,RMS,NAME,LEN1
    %rd=
	&hsspRdStripHeader($fileIn,$exclTxt,$inclTxt,$minZ,$lowIde,$upIde);
				# write output file
    &wrtRdbOneProt($fhout,"\t"," ",$id);
    &wrtRdbOneProt("STDOUT"," ","not_count",$id);
}
close($fhout);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { &myprt_txt(" $scriptName has ended fine .. -:\)"); 
		&myprt_txt(" output in file: \t $fileOut"); }
exit;

#==========================================================================================
sub ini {
    local(@argv)=@_;
    local (@script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
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
    @script_goal=   (" ",
		     "Task: \t $scriptTask",
		     " ",
		     "Input:\t $scriptIn",
		     " ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$scriptName help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("excl=n1-n2 ",
		     "incl=m1-m2 ",
		     "upIde= ",
		     "lowIde= ",
		     "minZ= ",
		     " ",
		     "not_screen",
		     "fileOut=");
    @script_opt_keydes= 
	            ("sequences n1 to n2 will be excluded: n1-*, n1-n2, or: n1,n5,... ",
		     "sequences m1 to m2 will be included: m1-*, m1-m2, or: m1,m5,... ",
		     "upper level of sequence identity ",
		     "lower level of sequence identity ",
		     "minimal zscore ",
		     " ",
		     "no information written onto screen",
		     "output file name");
    if ( ($argv[1]=~/^help|^man|-h/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) { &myprt_txt("$txt"); } &myprt_empty; 
	&myprt_txt("usage: \t $scriptName $scriptIn"); 
	&myprt_empty;&myprt_txt("optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf "--- %-12s %-s \n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#argv < $scriptNarg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){&myprt_txt("$txt");}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
				# --------------------
				# file
    $fileOut=   "unk";
    $fhout=     "FHOUT";
    $fhin=      "FHIN";
				# --------------------
				# further
    $exclTxt=  "unk";		# n-m -> exclude positions n to m
    $inclTxt=  "unk";
    $minZ=     -100;		# minimal zscore
    $lowIde=   0;		# lower limit for percentage seq identity
    $upIde=    100;		# upper limit for percentage seq identity
				# --------------------
				# logicals
    $Lscreen=   1;		# blabla on screen
				# --------------------
    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $#fileIn=0;
    foreach $arg (@argv){
	if   ($arg=~/^excl=/ )    {$arg=~s/\n|^excl=//g;$arg=~s/\(|\)//g;$exclTxt=$arg;}
	elsif($arg=~/^incl=/ )    {$arg=~s/\n|^incl=//g;$arg=~s/\(|\)//g;$inclTxt=$arg;}
	elsif($arg=~/^lowIde=/ )  {$arg=~s/\n|^lowIde=//g;$lowIde=$arg;}
	elsif($arg=~/^upIde=/ )   {$arg=~s/\n|^upIde=//g;$upIde=$arg;}
	elsif($arg=~/^minZ=/ )    {$arg=~s/\n|^minZ=//g;$minZ=$arg;}
	elsif($arg=~/^not_screen/){$Lscreen=0; }
	elsif($arg=~/^fileOut=/ ) {$tmp=$arg;$tmp=~s/\n|^fileOut=//g; $fileOut=$tmp; }
	elsif(-e $arg){
	    if   (&is_strip($arg)){
		push(@fileIn,$arg);}
	    else {$tmp=$#fileIn;
		  $Lok=&open_file("$fhin","$arg");
		  if (!$Lok){ print "*** ERROR $sbrName open '$arg'\n";
			      return(0);}
		  while(<$fhin>){$_=~s/\s//g;$file=$_;if (length($_)<4){next;}
				 if (&is_strip($file)){
				     push(@fileIn,$file);}}close($fhin);
		  if ($#fileIn==$tmp){
		      print "*** ERROR $sbrName '$arg' was NOT a list!!\n";
		      return(0);}}}
	else {print "*** ERROR $sbrName '$arg' not recognised!\n";
	      return(0);}}
    if ($fileOut eq "unk"){
	$fileOut="Out-hsspStripHeader.tmp";}

    # ------------------------------------------------------------
    # settings onto screen
    # ------------------------------------------------------------
    if ($Lscreen) { &myprt_line; &myprt_txt("perl script that $scriptTask"); 
		    print "--- fileIn:    \t  \t ";
		    foreach $fileIn(@fileIn){print"$fileIn,";}print"\n";
		    print "--- fileOut:   \t  \t $fileOut";
		    if ($exclTxt!~/unk/) {&myprt_txt("exclude pos: \t $exclTxt"); }
		    if ($inclTxt!~/unk/) {&myprt_txt("include pos: \t $inclTxt"); }
		    printf "--- %-20s %-5.2f\n","minZ",$minZ;
		    printf "--- %-20s %-5.2f\n","lowIde",$lowIde;
		    printf "--- %-20s %-5.2f\n","upIde",$upIde;
		    &myprt_line; }
    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lok=1;
    foreach $fileIn(@fileIn){
	if (! -e $fileIn) { print "*** $scriptName no input=$fileIn,\n";$Lok=0;}}
    return($Lok);
}				# end of ini

#==========================================================================================
sub hsspRdStripHeader {
    local($fileInLoc,$exclTxt,$inclTxt,$minZ,$lowIde,$upIde)=@_ ;
    local($fhinLoc,$Lok,$tmp,@excl,@incl,$nalign);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdStripHeader           reads the header of a HSSP.strip file
#       in:                     fileStrip
#                               exclTxt="n1-n2", or "*-n2", or "n1,n3,..."
#                               inclTxt="n1-n2", or "*-n2", or "n1,n3,..."
#                               minimal Z-score; minimal and maximal seq ide
#       out:
#                               $rd{"NROWS"}     = number of rows
#                               $rd{"$des","$ct"} = column $des for pair no $ct
#                               $des=
#                                   IAL,VAL,LEN,IDEL,NDEL,ZSCORE,IDEN,STRHOM,LEN2,RMS,NAME
#--------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."hsspRdStripHeader";$fhinLoc="FHIN"."$sbrName";
				# open file
    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    $#excl=$#incl=0;		# set zero
				# ------------------------------
				# read file
    while (<$fhinLoc>) {	# get Nali
	$tmp=$_;
	last if (/^\s*alignments\s+/);
	if (/^\s*seq_lengt/){$tmp=~s/^\s*seq_len.*:\s+//g;$tmp=~s/[^0-9]//g;$len1=$tmp;}}
    $tmp=~s/^.*:\s+//g;$tmp=~s/[^0-9]//g;$nalign=$tmp;
				# get range to be in/excluded
    if ($inclTxt!~/unk/){ @incl=&get_range($inclTxt,$nalign);} 
    if ($exclTxt!~/unk/){ @excl=&get_range($exclTxt,$nalign);} 
				# ------------------------------
				# read file
    while (<$fhinLoc>) {	# skip before SUMMARY
	last if (/=== SUMMARY ===/); }
    $ct=0;
    while (<$fhinLoc>) {	# 
	last if (/=== ALIGNMENTS ===/);
	$_=~s/\n//g;               if (length($_)<5){next;}
	$rd=$_;
	if (/^\s*IAL\s+/){	# first line: names
	    $rdBeg=substr($rd,1,69);$rdBeg=~s/^\s*|\s*$//g;
	    @name=(split(/\s+/,$rdBeg),"NAME");foreach $name(@name){$name=~s/\%//g;}
	    foreach $it (1..$#name){if   ($name[$it] eq "IDEN")  {$posIde=$it;}
				    elsif($name[$it] eq "ZSCORE"){$posZ=$it;}}
	    next;}
	$rdBeg=substr($rd,1,69);$rdBeg=~s/^\s*|\s*$//g;
	$rdEnd=substr($rd,70);  $rdEnd=~s/^\s*|\s*$//g;
	$rdEnd=~s/^([^\s]+)\s.*$/$1/g; # take only PDBid
	@tmp=(split(/\s+/,$rdBeg),$rdEnd);
	$pos=$tmp[1];
	$Ltake=1;
	if ($#excl>0) {foreach $i (@excl){ if ($i eq $pos){$Ltake=0; 
							   last;}}}
	if (($#incl>0) && $Ltake) { 
	    $Ltake=0;foreach $i (@incl){ if ($i eq $pos) {$Ltake=1; 
							  last;}}}
	if (! $Ltake) {		# dont continue if range to be excluded
	    next; }
	if ((100*$tmp[$posIde]>$upIde)||(100*$tmp[$posIde]<$lowIde)){
	    next; }
	if ($tmp[$posZ]<$minZ){
	    next;}
	++$ct;
	$rdLoc{"LEN1","$ct"}=$len1;
	foreach $it (1..$#tmp){
	    if ($name[$it] eq "IDEN"){$tmp=100*$tmp[$it];}else{$tmp=$tmp[$it];}
	    $rdLoc{"$name[$it]","$ct"}=$tmp; }}close($fhinLoc);
    $rdLoc{"NROWS"}=$ct;
    return (%rdLoc);
}				# end of hsspRdStripHeader

#===============================================================================
sub wrtRdbHeader {
    local($fhoutLoc,$sep,$fileOutLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHeader                writes RDB header
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtRdbHeader";$fhinLoc="FHIN"."$sbrName";

    if ($fhoutLoc ne "STDOUT"){
	$Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
	if (! $Lok){print "*** ERROR $sbrName: '$fileOutLoc' not opened\n";
		    return(0);}}
    print $fhoutLoc "# Perl-RDB\n";
    print $fhoutLoc "# \n";
    print $fhoutLoc "# Extracted Strip header\n";
    print $fhoutLoc "# \n";
    printf $fhoutLoc 
	"%6s$sep%6s$sep%-10s$sep%-10s$sep%6s$sep%6s$sep%4s$sep%5s$sep%5s$sep%5s\n",
	"ct",   "pos", "id1",   "id2",   "valAli","zAli","ide","len1","len2","lali";
    printf $fhoutLoc 
	"%6s$sep%6s$sep%-10s$sep%-10s$sep%6s$sep%6s$sep%4s$sep%5s$sep%5s$sep%5s\n",
	"6N",   "6N",  "10",    "10",    "6.2F",  "6.2F","4N","5N","5N","5N";
}				# end of wrtRdbHeader

#===============================================================================
sub wrtRdbOneProt {
    local($fhoutLoc,$sep,$txtCount,$idLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbOneProt               writes the RDB data for one protein
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtRdbOneProt";$fhinLoc="FHIN"."$sbrName";

    foreach $it (1..$rd{"NROWS"}){
	if ($txtCount ne "not_count"){++$ctAll;}

	printf $fhoutLoc 
	    "%6d$sep%6d$sep%-10s$sep%-10s$sep%6s$sep%6s$sep%4s$sep%5s$sep%5s$sep%5s\n",
	    $ctAll,$rd{"IAL","$it"},"$idLoc",$rd{"NAME","$it"},
	    $rd{"VAL","$it"},$rd{"ZSCORE","$it"},int($rd{"IDEN","$it"}),
	    $rd{"LEN1","$it"},$rd{"LEN2","$it"},$rd{"LEN","$it"};
    }
}				# end of wrtRdbOneProt

