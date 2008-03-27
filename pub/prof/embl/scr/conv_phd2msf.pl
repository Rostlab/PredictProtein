#!/usr/bin/perl
##!/usr/bin/perl -w
##!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
# phd2msf
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# should convert x.rdb_phd + x.msf into big msf including prediction
#
# usage: 	phd2msf.pl file.msf 
#
# task:		merges an MSF file and a phd.rdb file to one output
# 		
#------------------------------------------------------------------------------#
#	Copyright				May,        	1996	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.2   	Jun,    	1996	       #
#				version 0.3   	Feb,    	1997	       #
#				version 1.0   	May,    	1998	       #
#				version 1.1   	Oct,    	1998	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# initialise variables
if ($#ARGV<1){ print"goal :   merges id.rdb_phd and id.msf into MSF\n";
	       print"usage:   'script file.msf'\n";
	       print"option:  filePhd=x, fileOut=y, fileMsf=z, charPerLine=N\n";
	       print"         riSec=4, riAcc=3, riSym=. (e.g. 'riSym= ')\n";
	       print"         verbose\n";
	       exit;}
				# spacers
$keyPredictions=" \n  PREDICTIONS:";
#$keyAcc=        "  ACCESSIBILITY:";
$keyAcc=        "unk";
#$keyDetailSec=  "  detail sec:"; 
#$keyDetailAcc=  "  detail acc:";
%acc3Threshold= ('b', "9", 
		 'i', "36",
		 'e', "100");
				# defaults
@desPhdRdb=("body","AA","OHEL","PHEL","RI_S",
	    "OREL","PREL","RI_A","Obie","Pbie",
	    "OTN","PTN","RI_H","PFTN","PRTN","PiTo");
	    
@desPhd=   ("AApred","OBSsec","PHDsec","RELsec","SUBsec",
#	    "$keyAcc",
	    "O_3acc","P_3acc","RELacc","SUBacc","OBSacc","PHDacc",
	    "OBShtm","PHDhtm","RELhtm","PHDhtmfil","PHDhtmref","PHDhtmtop");
@desKey=   ("$keyAcc","$keyPredictions");
$special{"empty"}=" ";

$Lscreen= 1;
$fhout="FHOUT";			# output ='preName' $name 'postName' DATA 'postRow'
$NperLine=50;			# number of residues per line
$riSec=   4;
$riAcc=   3;
$riSym=   ".";

				# ------------------------------
$fileMsf=$ARGV[1];		# read first argument
$fileOut=$fileMsf."_out";
$filePhd=$fileMsf;$filePhd=~s/\.msf/\.rdb_phd/g;

				# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^filePhd=(.+)$/i)      { $filePhd=  $1;}
    elsif ($arg=~/^fileOut=(.+)$/i)      { $fileOut=  $1;}
    elsif ($arg=~/^fileMsf=(.+)$/i)      { $fileMsf=  $1;}
    elsif ($arg=~/^riSec=(.+)$/i)        { $riSec=    $1;}
    elsif ($arg=~/^riAcc=(.+)$/i)        { $riAcc=    $1;}
    elsif ($arg=~/^riSym=(.+)$/i)        { $riSym=    $1;}
    elsif ($arg=~/^charPerLine=(.+)$/i)  { $NperLine= $1;}
    elsif ($arg=~/^verbose|de?bu?g/i)    { $Lscreen=  1;}
    elsif ($arg=~/^(not_?screen|\-s)$/i) { $Lscreen=  0;}
}
				# ------------------------------
$Lerr=0;			# check existenc
if (! -e $fileMsf){print"*** ERROR NO MSF file=$fileMsf!\n";$Lerr=1;}
if (! -e $filePhd){print"*** ERROR NO PHD file=$filePhd!\n";$Lerr=1;}
exit(1)                         if ($Lerr);

				# ------------------------------
				# read MSF
($Lok,$txtDbg,$guide,%rdMsf)=
    &rdMsf($fileMsf);
#print "g=$guide:",$rdMsf{$guide},"\n"; @tmp=split(/,/,$rdMsf{"name"});foreach $tmp (@tmp){print "  $tmp:",substr($rdMsf{"$tmp"},1,60),"\n";}exit; # xx

    
if ($Lscreen){
    print "--- conv_phd2msf after rdMsf: \t '$txtDbg'\n";}

$rdMsf{"preName"}=     " ";
$rdMsf{"postName"}=    " ";
$rdMsf{"postRow"}=     " ";
$rdMsf{"sepRow"}=      " \n \n";
$rdMsf{"LwrtName"}=    1;
$rdMsf{"formatName"}=  "%-15s";
				# length of guide sequence
$rdMSf{"lengthGuide"}= length($rdMsf{$guide});

@name=split(/,/,$rdMsf{"name"});
push(@desPhdRdb,"not_screen")   if (! $Lscreen);

				# --------------------------------------------------
				# read PHD
%rdPhd=
	&rdRdbAssociative($filePhd,@desPhdRdb);

				# digest the stuff read
foreach $des ("AA","OHEL","PHEL","RI_S",
	      "Obie","Pbie","RI_A","OREL","PREL",
	      "OHL","OTN","PHL","PTN","RI_H","PFHL","PFTN","PRHL","PRTN","PiTo"){
    if   ($des eq "PHEL"){ $desOut="PHDsec";}
    elsif($des eq "OHEL"){ $desOut="OBSsec";}
    elsif($des eq "RI_S"){ $desOut="RELsec";}
    elsif($des eq "OHL") { $desOut="OBShtm";}
    elsif($des eq "OTN") { $desOut="OBShtm";}
    elsif($des eq "PHL") { $desOut="PHDhtm";}
    elsif($des eq "PTN") { $desOut="PHDhtm";}
    elsif($des eq "PFHL"){ $desOut="PHDhtmfil";}
    elsif($des eq "PFTN"){ $desOut="PHDhtmfil";}
    elsif($des eq "PRHL"){ $desOut="PHDhtmref";}
    elsif($des eq "PRTN"){ $desOut="PHDhtmref";}
    elsif($des eq "PiTo"){ $desOut="PHDhtmtop";}
    elsif($des eq "RI_H"){ $desOut="RELhtm";}
    elsif($des eq "OREL"){ $desOut="OBSacc";}
    elsif($des eq "PREL"){ $desOut="PHDacc";}
    elsif($des eq "RI_A"){ $desOut="RELacc";}
    elsif($des eq "Obie"){ $desOut="O_3acc";}
    elsif($des eq "Pbie"){ $desOut="P_3acc";}
    elsif($des eq "AA")  { $desOut="AApred";}
    else { 
	print "-*- WARNING phd2msf.pl: undefined des=$des, \n";
	next;}
    $rdMsf{$desOut}="";	
    if (! defined $rdPhd{$des,"1"}){
	next;}
    $flag{$desOut}=1;
				# write PHD output into MSF rd
    $ctMsf=0;
    foreach $it (1..$rdPhd{"NROWS"}){ # loop over all residues
	++$ctMsf;
				# check identity of sequences in PHD and MSF (for expanded!)
	while ($ctMsf < $rdMSf{"lengthGuide"}  && 
	       ((substr($rdMsf{$guide},$ctMsf,1) eq ".") ||
		(substr($rdMsf{$guide},$ctMsf,1) ne $rdPhd{"AA",$it}))){
				# watch it: both insertions -> stop
	    last if (substr($rdMsf{$guide},$ctMsf,1) eq $rdPhd{"AA",$it});
	    if ($des =~ /^empty/){
		$rdMsf{$desOut}.=$special{$des};}
	    else {
		$rdMsf{$desOut}.=".";}
	    ++$ctMsf;}
	if    ($des =~ /^PREL|^OREL/){ # convert relative accessibility
	    $rdPhd{$des,$it}=&exposure_project_1digit($rdPhd{$des,$it});}
	if ($des =~ /^empty/){	# now append to MSF string
	    $rdMsf{$desOut}.=$special{$des};}
	else {$rdMsf{$desOut}.=$rdPhd{$des,$it};}
    }
    if    ($des =~/^OHEL|^PHEL/){ # convert 'L' -> ' '
	$rdMsf{$desOut}=~s/L/ /g;}
    elsif ($des =~/^Pbie|^Obie/){ # convert 'i' -> ' '
	$rdMsf{$desOut}=~s/i/ /g;}
    elsif ($des =~ /^PHL|^OHL|^PTN|^OTN/){ # convert HTM
	$rdMsf{$desOut}=~s/H/T/g;
	$rdMsf{$desOut}=~s/L/ /g;}
    elsif ($des =~ /^PRHL|^PFHL|^PRTN|^PFTN/){ # convert HTM
	$rdMsf{$desOut}=~s/H/T/g;
	$rdMsf{$desOut}=~s/L/ /g;}
}
				# ------------------------------
				# add the 'subset' stuff
foreach $des ("SUBsec","SUBacc"){
    $desOrigin=$des; $desOrigin=~s/SUB/PHD/; # points to key of prediction
    if ((! defined $rdMsf{"$desOrigin"})||(length($rdMsf{"$desOrigin"})<1)){
	next;}
    $flag{$des}=1;
    $rdMsf{$des}="";
    $desRi=$des;$desRi=~s/SUB/REL/g;
				# reliablity index
    if ($des=~/sec/){$riT=$riSec;}else{$riT=$riAcc;}
				# loop over all residues
    foreach $it (1..length($rdMsf{"$desOrigin"})){
	$phd=substr($rdMsf{"$desOrigin"},$it,1);$ri=substr($rdMsf{"$desRi"},$it,1);
				# change for acc
	if ($des eq "SUBacc"){
	    foreach $symAcc ("b","i","e"){
		last if ($phd !~/^\d+$/) ; # avoid errors from non numbers (error anyway...)
		    
		if (($phd*$phd) <= $acc3Threshold{"$symAcc"}){
		    $phd=$symAcc;
		    last;}}}
	if    ($phd eq "."){	# is insertion
	    $rdMsf{$des}.=".";}
	elsif ($ri > $riT){	# RI is above threshold
	    if ($phd eq " "){ $tmp="L"; } else {$tmp=$phd;} # convert ' ' -> 'L'
	    $rdMsf{$des}.=$tmp;}
	else {
	    $rdMsf{$des}.=$riSym;}}}
				# ------------------------------
                                # add PHD to MSF
if (defined $flag{"PHDacc"}){
    $flag{"$keyAcc"}=1;$rdMsf{"$keyAcc"}=" ";}
$flag{"$keyPredictions"}=1;$rdMsf{"$keyPredictions"}=" ";

foreach $des ("$keyPredictions",@desPhd){
    if (defined $flag{$des}){
	if (! defined $rdMsf{$des}){ # security fill blanks!
	    $rdMsf{$des}=" " x length($rdMsf{$guide});}
	$rdMsf{"name"}.=",".$des;} }
$rdMsf{"special"}="";		# define keys to separate lines in one block
foreach $des (@desKey){
    $rdMsf{"special"}.=$des.",";}
$rdMsf{"special"}=~s/^,|,$//g;

@fh=($fhout); 
push(@fh,"STDOUT")              if ($Lscreen);

foreach $fh(@fh){
    &open_file("$fhout",">$fileOut") if ($fh eq "$fhout");

    &wrtNperLineAssArray($fh,$NperLine,%rdMsf);

    close($fhout)               if ($fh eq "$fhout");
}

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen){
    print "conv_phd2msf: \t output in file: \t $fileOut\n";}

exit;

#==========================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   project the percentage value of exposure (relative) onto numbers 0-9
#   by using: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; exit;
    }
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

#======================================================================
sub open_file {
    local ($file_handle, $file_name, $log_file) = @_ ;
    local ($temp_name) ;
    $temp_name= $file_name ;
    $temp_name=~ s/^>>|^>//g ;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** \t INFO: file $temp_name does not exist; create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Can't create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Can't create new file: $temp_name\n" ; } });
	close ("$file_handle") ; }
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** \t Can't open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** \t Can't create new file '$file_name'\n" ; }
	return(0); });
}

#======================================================================
#    sub: myprt_points
#======================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;

    if ( int($npoints/10)!=($npoints/10) ) {
	print "*** ERROR in myprt_npoints (lib-prot.pl): \n";
	print "***       number of points passed should be multiple of 10!\n"; exit; }

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if ( $i==1 ) { $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 ) {  $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ( ($i==($npoints/10))&&($ctprev>=9) ) { 
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else {
           $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
           $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

#===============================================================================
sub rdRdbAssociative {
    local ($fileInLoc,@des_in) = @_ ;
    local ($sbr_name,$fhinLoc,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative            reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhinLoc="FHIN_RDB";$sbr_name="rdRdbAssociative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in (@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
					      push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhinLoc","$fileInLoc");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &rdRdbAssociativeNum($fhinLoc,0);
    close($fhinLoc);
				# ------------------------------
    $#des_head=0;		# process header
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^(PARA\s*:?\s*)?$des_in\s*[ :,\;=]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/^.*$des_in//g;$tmp=~s/^\s*//g;
		    $tmp=~s/^[\s:\t]*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    print
		"--- $sbr_name: \t expected to find in header key word:\n",
		"---            \t '$des_in', but not in file '$fileInLoc'\n"
		    if (!$Lfound && $Lscreen); }}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1; $it<=$#READNAME; ++$it) {
	    $rd=$READNAME[$it];$rd=~s/\s//g;
	    if ($rd eq $des_in) {
		$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);$Lfound=1;
		last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( defined $it && defined $READFORMAT[$it] ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}
    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if   ($nrow_rd==0)    {$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "***         in RDB file '$fileInLoc' for rows with ".
				   "key=$des_in, column=$itrd, prev=$nrow_rd, now=$#tmp,\n";}
	for ($it=1; $it<=$#tmp; ++$it){
	    $rdrdb{"$des_in","$it"}=$tmp[$it];
	    $rdrdb{"$des_in","$it"}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
				# ------------------------------
				# safe memory
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    $#des_headin=$#des_body=$#tmp=$#des_head=0;
    undef %ptr_rd2des;
    $#des_in=0;                 # slim_is_in !
    
    return (%rdrdb);
}				# end of rdRdbAssociative

#===============================================================================
sub rdRdbAssociativeNum {
    local ($fhLoc2,@readnum) = @_ ;
    local ($ctLoc, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#       in:                     $fhLoc,@readnum,$readheader,@readcol,@readname,@readformat
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ctLoc= 0;
    $tmpct=0;
    while ( <$fhLoc2> ) {	# ------------------------------
	++$tmpct;		# header  
	if ( /^\#/ ) { 
	    $READHEADER.= "$_";
	    next; }
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){
		    $readnum[$it]=$it;
		    $READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name"; }
	    next; }
				# ------------------------------
				# skip format?
	if ($ctLoc==2 && $rd!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc; }
	if ($ctLoc==2) {	# read format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; }
	    next; }
				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	foreach $it (1..$#readnum){
	    next if (! defined $tmpar[$readnum[$it]]); 
	    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }
    }
				# ------------------------------
				# massage FORMAT/COL/NAME
    foreach $it (1..$#READCOL){
	$READFORMAT[$it]=~ s/^\s+//g   if (defined $READFORMAT[$it]);
	$READFORMAT[$it]=~ s/\t$|\n//g if (defined $READFORMAT[$it]);
	$READNAME[$it]=~ s/^\s+//g     if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g        if ($#READNAME>0); 
	$READCOL[$it] =~ s/\t$|\n//g;  # correction: last not return!
    }
}				# end of rdRdbAssociativeNum

#==========================================================================================
sub rdMsf {
    local ($fileMsfLoc) = @_ ;
    local ($fhinLoc,$name,@name,%rdLoc,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdMsf                      read content of MSF file into associative array
#       out:
#         $rd{"name"}	        'name1,name2,...'
#	  $rd{"name1"}		=sequence for protein named '1'
#--------------------------------------------------------------------------------
    $fhinLoc="FhInMsf";
    &open_file("$fhinLoc", "$fileMsfLoc");

    while (<$fhinLoc>) {	# check validity of MSF format (first line starts as 'MSF ')
	if (! /^MSF/){
	    return(0,"rdMsf: not correct MSF format");}
	last;}
				# ------------------------------
    $#name=0;$name="";		# read header
    undef %Lok;
    while (<$fhinLoc>) {$_=~s/\n//g;
			if (/[Nn]ame\:/){	# is row with names
			    $_=~s/^.*ame\:\s*|\s*[lL]en\:.*$//g;
			    $_=~s/\s//g;
			    $_=~s/[;.,]//g;$_=~s/^.*\|//g;
			    push(@name,$_);$name.="$_".",";}
			last if (/\/\//);}
    if ($#name<1){		# any name found?
	return(0,"rdMsf: no 'Name:' found!");}
    $name=~s/,$//g;		# cut last comma
    $rdLoc{"name"}=$name;
    undef %Lok;
    $ct=0;
    foreach $_(@name){$rdLoc{"$_"}="";}	# ini names
				# ------------------------------
    $ct=1; undef %Lok;		# read sequences
    while (<$fhinLoc>) {$_=~s/\n//g;
			next if (length($_) < 1 ||
				 $_=~/^[\s\t]*$/);
			if ($ct>$#name){
			    $ct=1; undef %Lok;}
			next if (! defined $name[$ct]);
			next if ($_!~/^\s*$name[$ct]/ &&
				 $_!~/\|$name[$ct]/);
				# avoid duplications!
			next if (defined $Lok{$name[$ct]} && $Lok{$name[$ct]});
			$_=~s/$name[$ct]//;$_=~s/^.*\|//g;$_=~s/[^A-Z.]//g;
#				printf "xx name=%-14s %-s\n",$name[$ct], $_;
			$rdLoc{$name[$ct]}.=$_;
			$Lok{$name[$ct]}=1;
			++$ct;}close($fhinLoc);
    $Lok=1;
    foreach $name(@name){	# check whether or not all same length
	if (length($rdLoc{"$name"}) != length($rdLoc{"$name[1]"})){
	    $Lok=0;}}
    if (!$Lok){
	return(0,"rdMsf: wrong length",$name[1],%rdLoc);}
    else {
    	return(1,"rdMsf: ok",$name[1],%rdLoc);}
}				# end of rdMsf

#==========================================================================================
sub wrtNperLineAssArray {
    local ($fhLoc,$NperLine,%wrt)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtNperLineAssArray        writes associative array into row-wise format
#       in:
#         			$wrt{"preName"}  before name (say 'pre ')
#         			$wrt{"postName"} after name  (say 'post |')
#         			$wrt{"postRow"}  after row   (say '|')
#         			$wrt{"sepRow"}   separation of rows (e.g. '\n')
#         			$wrt{"LwrtName"} =1 => write the name
#         			$wrt{"name"}     'name1,name2, ...'
#         			$wrt{"$name"}    full string
#         			$wrt{"special"}  gives keys to separate lines
#--------------------------------------------------------------------------------
    $wrt{"name"}=~s/,$//;
    @name=split(/,/,$wrt{"name"});
    $formatRow="%"."-"."$NperLine"."s";
    $formatName=$wrt{"formatName"};
    $txt1=$wrt{"preName"}; 		# $txt1X=" " x length($txt1);
    $txt2=$wrt{"postName"};$txt2X=" " x length($txt2);
    $txt3=$wrt{"postRow"}; 		# $txt3X=" " x length($txt3);

    for($it=1;$it<=length($wrt{"$name[1]"});$it+=$NperLine){
				# write points
	$points=&myprt_npoints($NperLine,$it);
	if ($wrt{"LwrtName"}){	# write the name
	    printf $fhLoc "$txt1$formatName$txt2X%-s\n"," ",$points;}
	else {			# write ...
	    printf $fhLoc "$txt1$txt2X%-s\n"," ",$points;}
				# ------------------------------
				# write each row
	foreach $name(@name){
	    if ($wrt{"special"} =~/$name/){
		printf $fhLoc "$txt1$formatName$txt2\n",$name;
		next;}
				# not defined or too short
	    if ((! defined $wrt{"$name"})||(length($wrt{"$name"})<$it)){
		next;}
				# substr = number of characters per line
	    if (length($wrt{"$name"})>=($it+$NperLine)){
		$wrt=substr($wrt{"$name"},$it,$NperLine);}
	    else {$wrt=substr($wrt{"$name"},$it);}

	    if (length($wrt) == $NperLine){
		$formatRowTmp=$formatRow;}
	    else{$formatRowTmp=$formatRow;$formatRowTmp=~s/[\d.]//g;}

	    if ($wrt{"LwrtName"}){
	   	 printf $fhLoc "$txt1$formatName$txt2$formatRowTmp$txt3\n",$name,$wrt;}
	    else {
		printf $fhLoc "$txt1$txt2$formatRowTmp$txt3\n",$name,$wrt;}}
	print $fhLoc $wrt{"sepRow"};
    }
}				# end of wrtNperLineAssArray

