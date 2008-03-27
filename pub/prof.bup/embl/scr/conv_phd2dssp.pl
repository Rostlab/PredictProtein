#!/usr/bin/perl
##!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
# phd2dssp
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	phd2dssp.pl phd.rdb (optional: output dir_phd dir_dssp)
#
# task:		write phd output into DSSP format
#
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Jul,    	1994	       #
#				version 0.2   	Oct,    	1994	       #
#				version 0.3   	Aug,    	1995	       #
#				version 0.4   	May,    	1996	       #
#				version 1.0   	Feb,    	1997	       #
#				version 1.1   	Oct,    	1998	       #
#				version 1.2   	Feb,    	1999	       #
#------------------------------------------------------------------------------#

#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "phd2dssp";
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
#$script_goal      = "write phd output into DSSP format";
$script_input     = "phd.rdb (optional: output dir_phd(.rdb) dir_dssp)";

#require "/home/rost/perl/lib-br.pl";
#require "/home/rost/perl/lib-ut.pl";

#------------------------------
# number of arguments ok?
#------------------------------
if ( $#ARGV<1  || $ARGV[1]=~/help/ ) {
    print "--- usage: \t $script_name $script_input \n";
    print "options:                    say 1st argument called id.rdb\n";
    print "         file_out=x,     => output file (DSSP) named x\n";
    print "         dir_phd=x,      => input= 'x/id.rdb'\n";
    print "         dir_dssp=x(out),=> output='x/id.dssp_phd'\n";
    print "         chain=A         => output file named 'idA.dssp_phd' \n";
    print "         ext_out=x       => output file named 'id.x' \n \n";
    print "input can be: one rdb file or a list of rdb files\n";
    exit;
}

#------------------------------
# defaults
#------------------------------
#$dir_dssp= "out_dssp/"; 
#$dir_dssp= "dphd_dssp/"; 
#$dir_phd=  "dphd_rdb/"; 
$dir_phd=    "";
$dir_dssp=   "";
$ext_dssp=   ".dssp_phd"; 

$file_out="unk";
$CHAIN=" ";

$fhinphd="FHINPHD"; $fhoutdssp="FHOUTDSSP";
$Lscreen=1;

#----------------------------------------
# read input
#----------------------------------------
				# input file (phd.rdb)
$file_in= $ARGV[1]; 	        print "--- file in: \t \t $file_in\n"; 
$id=$file_in;$id=~s/^.*\///g;$id=~s/\s|\n|\.rdb.*//g;
if (! -e $file_in || ! &isRdb($file_in)){
    print "*** input has to be PHD rdb format\n"; 
    die;}
				# optional: dir_phd, dir_dssp (i.e. input and output directory)
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    if ($arg=~/dir_phd=(.*)/)     { $dir_phd=$1;$dir_phd=~s/\n|\s|unk//g;
				    $dir_phd.="/"  if ($dir_phd !~ /\/$/); }
    elsif ($arg=~/dir_dssp=(.*)/) { $dir_dssp=$1;$dir_dssp=~s/\n|\s|unk//g;
				    $dir_dssp.="/" if ($dir_dssp !~ /\/$/); }
    elsif ($arg=~/file_out=(.*)/) { $file_out=$1;$file_out=~s/\n|\s|unk//g; }
    elsif ($arg=~/fileOut=(.*)/)  { $file_out=$1;$file_out=~s/\n|\s|unk//g; }
    elsif ($arg=~/ext_out=(.*)/)  { $ext_dssp=$1;$ext_dssp=~s/\n|\s|unk//g; }
    elsif ($arg=~/chain=(.*)/)    { $CHAIN=$1;$CHAIN=~s/\n|\s|unk//g;} }

				# change output file?
$file_out=$dir_dssp.$id.$ext_dssp if (length($file_out)<4);
				# change input file?
if (length($dir_phd)>2)  { $tmp=$file_in;$file_in="$dir_phd"."$tmp";}
$fhTrace="STDOUT";
$fhTrace=0                      if (! $Lscreen);
    
#------------------------------
# check existence of file
#------------------------------
if (! -e $file_in) { print "*** ERROR:\t file $file_in does not exist\n"; 
                     exit; }

				# ------------------------------
				# input = list?
				# ------------------------------
$#file_in=0;
if (&isRdb($file_in)){
    push(@file_in,$file_in);}
else {
    &open_file("$fhinphd", "$file_in");
    while(<$fhinphd>){$_=~s/\s|\n//g;
		      push(@file_in,$_);}
    close($fhinphd); }

#----------------------------------------------------------------------
# read phd .rdb file (i.e. the prediction)
#----------------------------------------------------------------------
foreach $file_in (@file_in) {
    if ($#file_in>1){
	$id=$file_in;$id=~s/\/.*\///g;$id=~s/\s|\n|\.rdb.*//g;$id=~s/^.*\///g;
	$file_out="$dir_dssp"."$id"."$ext_dssp";}
    elsif (! defined $file_out) {
	$file_out=$file_in; $file_out=~s/\..*$/\.dssp/; }
    
    ($Lok,$msg)=
	&convPhd2dssp($file_in,$file_out,$CHAIN,$fhTrace);
    if (! $Lok) { $msgErr= 
		      "*** ERROR $scrName: failed phd2dssp ($file_in->$file_out)\n".$msg;
		  print $msgErr,"\n";
		  die; }
}

exit(1);

#===============================================================================
sub convPhd2dssp {
    local($fileInLoc,$fileOutLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2dssp                converts PHDrdb format to DSSP format
#       in:                     $fileInLoc,$fileOutLoc,$fhErrSbr
#       out:                    1|0,msg,  implicit: writes fileDSsp
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."convPhd2dssp";
    $fhinLoc="FHIN_"."convPhd2dssp";$fhoutLoc="FHOUT_"."convPhd2dssp";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))    if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))   if (! defined $fileOutLoc);
    $fhErrSbr="STDOUT"                       if (! defined $fhErrSbr);

#    return(&errSbr("not def !"))          if (! defined $);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!")) if (! -e $fileInLoc);

				# ------------------------------
				# defaults
				# keywords to read from RDB file
    @kwdLoc =("No","AA","PHEL","RI_S","PACC","RI_A");
    $idLoc=$fileInLoc;
    $idLoc=~s/^.*\///g;$idLoc=~s/\s|\n|\.rdb.*//g;

				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    undef %rd;
    %rd=
        &rdRdbAssociative($fileInLoc,"body",@kwdLoc); 
	
				# --------------------------------------------------
				# store into NUM, SEQ, SEC, RISEC, ACC, RIACC
				# --------------------------------------------------
    $#NUM=$#SEQ=$#SEC=$#RISEC=$#ACC=$#RIACC=0;
    foreach $kwd (@kwdLoc) {
	next                    if (! defined $rd{$kwd,"1"}) ;
	if    ($kwd eq "No") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@NUM,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "AA") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@SEQ,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "PHEL") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@SEC,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "RI_S") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@RISEC,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "PACC") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@ACC,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "RI_A") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@RIACC,$rd{$kwd,$ct});++$ct;}}
    }
				# ------------------------------
				# convert L->' '
    foreach $it(1..$#SEC){
	$SEC[$it]=~s/L/ /;}
				# --------------------------------------------------
				# writing phd into DSSP format
				# --------------------------------------------------
    print $fhErrSbr
	"--- $sbrName: writing id=$idLoc, chain=$CHAIN, fileOut=$fileOutLoc\n"
	    if ($fhErrSbr);
				# NOTE: GLOBAL in: all $CHAIN,@NUM,@SEQ,@SEC,@ACC,@RI*
    ($Lok,$msg)=
	&dsspWrtFromPhd($fileOutLoc,$idLoc);

    if (! $Lok) { $msgErr="*** ERROR $scrName: failed writing $fileOutLoc\n".$msg;
		  print $msgErr,"\n";
		  die; }

    $#NUM=$#SEQ=$#SEC=$#RISEC=$#ACC=$#RIACC=0; # slim-is-in!
    undef %rd;			# slim-is-in!

    return(1,"ok $sbrName");
}				# end of convPhd2dssp

#===============================================================================
sub dsspWrtFromPhd {
    local ($fileOutLoc,$id_in)=@_;
    local ($it,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspWrtFromPhd                       
#       in:                     $fileOutLoc
#       in GLOBAL:              @NUM, @SEQ, @SEC(HE ), @ACC, @RISEC, @RIACC
#       in GLOBAL:              $CHAIN
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspWrtFromPhd"; $fhoutLoc="FHOUT_"."dsspWrtFromPhd";
    
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileOutLoc!"))          if (! defined $fileOutLoc);
#    return(&errSbr("not def !"))          if (! defined $);
#    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

				# chain identifier
    $CHAIN=" "                  if (! defined $CHAIN || 
				    length($CHAIN) != 1);

				# ------------------------------
				# open new file
    &open_file("$fhoutLoc",">$fileOutLoc") || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));

				# ------------------------------
				# DSSP header
    print $fhoutLoc 
	"**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, here PHD prediction\n",
	"REFERENCE  B. ROST AND C. SANDER, PROTEINS 19 (1994) 55-72 \n",
	"HEADER     $id_in \n",
	"COMPND        \n",
	"SOURCE        \n",
	"AUTHOR        \n",
	"  \#  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  O-->H-N  N-H-->O  O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA  \n";

				# ------------------------------
				# body
				# ------------------------------
    for ($it=1; $it<=$#SEC; ++$it) {
				# defaults
	$num=$it; $riacc=0; $risec=0;
	$seq="U"; $sec="U"; $acc=999;
				# fill in
	$num=  $NUM[$it]        if (defined $NUM[$it]);
	$seq=  $SEQ[$it]        if (defined $SEQ[$it]);
	$sec=  $SEC[$it]        if (defined $SEC[$it]);
	$acc=  $ACC[$it]        if (defined $ACC[$it]);
	$risec=$RISEC[$it]      if (defined $RISEC[$it]);
	$riacc=$RIACC[$it]      if (defined $RIACC[$it]);
				# ERROR messages
	print "*** ERROR $sbrName: it=$it, SEQ not defined\n" if ($seq eq "U"  );
	print "*** ERROR $sbrName: it=$it, SEC not defined\n" if ($sec eq "U"  );
	print "*** ERROR $sbrName: it=$it, ACC not defined\n" if ($acc eq "999");
				# write it
	printf $fhoutLoc 
	    " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	    $num, $num, $CHAIN, $seq, $sec, $acc, $risec, $riacc;
    }
    close($fhoutLoc);
    return(1,"ok");
}				# end of dsspWrtFromPhd

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
sub isRdb {local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	   return (0) if (! -e $fileInLoc);$fh="FHIN_CHECK_RDB";
	   &open_file("$fh", "$fileInLoc") || return(0);
	   $tmp=<$fh>;close($fh);
	   return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
	   return 0; }	# end of isRdb

#===============================================================================
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

