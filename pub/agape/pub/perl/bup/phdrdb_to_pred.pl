#!/usr/bin/perl -w
##!/usr/sbin/perl -w
##!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# phdrdb_to_pred
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	phdrdb_to_pred.pl list(.rdb_phd) files from PHD
#
# task:		in: list of PHD RDB files, out: format for EVALSEC
#               
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			September,      1995           #
#			changed:		,      	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;
&ini;
				# --------------------------------------------------
				# loop over all files
				# --------------------------------------------------
$ctfile=$#id=0;
foreach $file_in (@fileIn) {
    %rd=&rd_rdb_associative($file_in,"not_screen","body",@des_rd);
    next if ($rd{"NROWS"}<5);	# skip short ones
    $Lexcl=0;			# security check
    foreach $des (@des_rd){
	if (! defined $rd{"$des","1"}){
	    next if ( ($opt_phd eq "acc") && ($des eq "OHEL"));
	    $ok{$des}=0;
	    print "-*- WARN $scrName des=$des, missing in '$file_in' \n"; }
	$ok{$des}=1;}
#    $Lexcl=0;			# xx
    next if ($Lexcl);
    ++$ctfile;
    $id=$file_in;$id=~s/^.*\/([^\.]*)\..*/$1/; $id=~s/\..*//g;
    push(@id,$id);
    $all{"$id","NROWS"}=$rd{"NROWS"};
    foreach $des (@des_rd){
	next if (! defined $ok{$des} || ! $ok{$des});
				# hack 31-05-97 to allow acc, only
	if (($opt_phd eq "acc")&&($des eq "OHEL")&&(! defined $rd{"$des","1"})){
	    foreach $itres (1..$rd{"NROWS"}){
		$rd{"$des","$itres"}=" ";$rd{"SS","$itres"}=" ";}}
	$all{"$id","$des"}="";
	if ($des =~/^[OP]REL/){
	    foreach $itres (1..$rd{"NROWS"}){
		$all{"$id","$des"}.=&exposure_project_1digit($rd{"$des","$itres"});}}
	else {
	    foreach $itres (1..$rd{"NROWS"}){
		$all{"$id","$des"}.=$rd{"$des","$itres"}; 
	    }
	    if ($des=~/O.*L|P.*L/){	# convert L->" "
		if ($opt_phd eq "htmx") {
		    $all{"$id","$des"}=~s/E/ /g;}
		$all{"$id","$des"}=~s/L/ /g;}
	}
    }
}

				# --------------------------------------------------
				# now write out
				# --------------------------------------------------
$desvec=join(',',@des_out); $desvec=~s/,*$//g;
$idvec= join(',',@id);      $idvec=~s/,*$//g;

&phdRdb2phdWrt($fileOut,$idvec,$desvec,$opt_phd,$nresPerRow,$LnoHdr,%all);

print "--- $scrName output in file=$fileOut\n"      if ($Lscreen && -e $fileOut);
print "*** $scrName output file=$fileOut missing\n" if (! -e $fileOut);
exit;

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                       
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."ini";$fhinLoc="FHIN"."$sbrName";

    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
    $script_goal=      "in: list of PHD RDB files, out: format for EVALSEC";
    $script_input=     ".rdb_phd files from PHD";
    $script_opt_ar[1]= "output file";
    $script_opt_ar[2]= "option for PHDx keys=both,sec,acc,htm,";
    $script_opt_ar[3]= "noHdr        -> no comment lines";
    $script_opt_ar[4]= "nresPerRow=n -> number of residues per row";
    $script_opt_ar[5]= "dirLib=/perl/-> directory of perl libs";
    $script_opt_ar[6]= "dirOut=      -> output directory";
				# ------------------------------
				# include libraries
				#----------------------------------------
    $USERID=`whoami`; $USERID=~s/\s//g;
    if ($USERID eq "phd"){require "/home/phd/ut/perl/lib-br.pl"; 
 			  require "/home/phd/ut/perl/lib-ut.pl"; }
    else{
	foreach $arg (@ARGV){
	    if ($arg=~/dirLib=(.*)$/){$dir=$1;
				      last;}}
	$dir=$dir || "/home/rost/pub/phd/scr/lib-ut.pl" || "/home/rost/perl/" || $ENV{'PERLLIB'} ;
	$dir.="/" if ($dir !~/\/$/);
	require "lib-ut.pl"; require "lib-br.pl"; }

				#----------------------------------------
				# about script
    				#----------------------------------------
    if ( ($#ARGV < 1) || $ARGV[1]=~/^(help|man)$/ ) { 
	print "$scrName '$script_input'\n";
	print "\t $script_goal\n";
	print "1st arg= list of RDB files\n";
	print "other  : keys=not_screen, fileOut=, 'htm,acc,sec,both' , 'fil,ref,ref2,nof'\n";
	foreach $kwd(@script_opt_ar){
	    print "       : $kwd\n";}
	exit;}
				#----------------------------------------
				# read input
				#----------------------------------------
    $Lscreen=    1;
    $fileOut=    "unk";
    $opt_phd=    "unk";
    $opt=        "unk";
    $LnoHdr=     0;
    $nresPerRow=80;		# number of residues per row (in output)

    $#fileIn=0;
    foreach $arg(@ARGV){
	if    ($arg=~/^not_screen/)          {$Lscreen=0;}
	elsif ($arg=~/^file.?[Oo]ut=(.+)$/)  {$fileOut=$1;}
	elsif ($arg=~/^dirOut=(.+)$/)        {$dirOut=$1; $dirOut.="/" if ($dirOut !~/\/$/);}
	elsif ($arg=~/^htm/)                 {$opt_phd="htm";}
	elsif ($arg=~/^sec/)                 {$opt_phd="sec";}
	elsif ($arg=~/^acc/)                 {$opt_phd="acc";}
	elsif ($arg=~/^both/)                {$opt_phd="both";}
	elsif ($arg=~/^nof/)                 {$opt="nof";}
	elsif ($arg=~/^fil/)                 {$opt="fil";}
	elsif ($arg=~/^ref2/)                {$opt="ref2";}
	elsif ($arg=~/^ref/)                 {$opt="ref";}
	elsif ($arg=~/^noHdr/)               {$LnoHdr=1;}
	elsif ($arg=~/^nresPerRow=(\d+)$/)   {$nresPerRow=$1;}
	elsif (-e $arg && &isRdb($arg))      {push(@fileIn,$arg);}
	elsif (-e $arg && &isRdbList($arg))  {$fileIn=$arg;}
	else                                 {print "*** ERROR $scrName: arg '$arg' not understood\n";
					      exit;}}
				#----------------------------------------
				# defaults
				#----------------------------------------
    $fileOut=$fileIn . "_out"  if ($fileOut eq "unk" && defined $fileIn);
    $fileOut=$fileIn[1]."_out" if ($fileOut eq "unk" && defined $fileIn[1] && $#fileIn==1);
    $fileOut="Out".$scrName.$$ if ($fileOut eq "unk" && ! defined $fileIn);
    $fileOut=~s/^.*\///g;
    $fileOut=$dirOut. $fileOut if (defined $dirOut && -d $dirOut);
    if ($opt_phd eq "unk"){$opt_phd=   "htm";}
    if ($opt_phd eq "sec"){$opt=       "unk";}
    if ($opt_phd eq "acc"){$opt=       "unk";}
    if ($opt eq "unk")    {$opt=       "fil";}
    
    if     ($opt_phd eq "htm") {
	if    ($opt eq "nof") { @des_rd= ("AA","OHL","PHL","RI_S");
				@des_out=("AA","OHL","PHL","RI_S");}
	elsif ($opt eq "fil") { @des_rd= ("AA","OHL","PFHL","RI_S");
				@des_out=("AA","OHL","PFHL","RI_S");}
	elsif ($opt eq "ref") { @des_rd= ("AA","OHL","PRHL","RI_S");
				@des_out=("AA","OHL","PRHL","RI_S");}
	elsif ($opt eq "ref2"){ @des_rd= ("AA","OHL","PR2HL","RI_S");
				@des_out=("AA","OHL","PR2HL","RI_S");}
	else                  { print "*** ERROR $scrName:ini: opt=$opt, not ok\n";
				exit;}}
    elsif ($opt_phd eq "sec") { @des_rd= ("AA","OHEL","PHEL","RI_S");
				@des_out=("AA","OHEL","PHEL","RI_S");}
    elsif ($opt_phd eq "acc") { @des_rd= ("AA","OHEL","OREL","PREL","RI_A");
				@des_out=("AA","OHEL","OREL","PREL","RI_A");}
    else                      { print "*** ERROR $scrName:ini: opt_phd=$opt_phd, not ok\n";
				exit;}

				#----------------------------------------
				# check existence of files
				#----------------------------------------
    if (defined $fileIn && ! -e $fileIn) {
	print "*** ERROR $scrName:ini: fileIn=$fileIn does not exist\n"; 
	exit; }
    elsif (defined $fileIn){	# list of RDB
	&open_file($fhinLoc, "$fileIn");
	while(<$fhinLoc>){$_=~s/\s|\n//g;
		       next if (length($_)<3) ;
		       if (-e $_){
			   push(@fileIn,$_); }
		       else {
			   print "*** phdrdb_to_pred: file '$_' missing \n";}}close($fhinLoc);}
}				# end of ini

#==========================================================================================
sub phdRdb2phdWrt {
    local ($fileOutLoc,$idvec,$desvec,$opt_phd,$nres_per_row,$LnoHdr,%all) = @_ ;
    local ($fh,@des,@id,$tmp,@tmp,$id,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    phdRdb2phdWrt              writes into file readable by EVALSEC
#       in:                     $fileOutLoc:     output file name
#       in:                     $idvec:          'id1,id2,..' i.e. all ids to write
#       in:                     $desvec:         
#       in:                     $opt_phd:        sec|acc|htm|?
#       in:                     $nres_per_row:   number of residues per row (80!)
#       in:                     %all
#       out:                    
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."subx";$fh="FHOUT_"."subx";
				# check arguments
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def idvec!")            if (! defined $idvec);
    return(0,"*** $sbrName: not def desvec!")           if (! defined $desvec);
    return(0,"*** $sbrName: not def opt_phd!")          if (! defined $opt_phd);
    return(0,"*** $sbrName: not def nres_per_row!")     if (! defined $nres_per_row);
				# vector to array
    @des=split(/,/,$desvec);
    @id= split(/,/,$idvec);


    &open_file($fh, ">$fileOutLoc");
				# ------------------------------
				# header
    print $fh  "* PHD_DOTPRED_8.95 \n"; # recognised key word!
    print $fh  "*" x 80, "\n","*"," " x 78, "*\n";
    if   ($opt_phd eq "sec"){$tmp="PHDsec: secondary structure prediction by neural network";}
    elsif($opt_phd eq "acc"){$tmp="PHDacc: solvent accessibility prediction by neural network";}
    elsif($opt_phd eq "htm"){$tmp="PHDhtm: helical transmembrane prediction by neural network";}
    else                    {$tmp="PHD   : Profile prediction by system of neural networks";}
    printf $fh "*    %-72s  *\n",$tmp;
    printf $fh "*    %-72s  *\n","~" x length($tmp);
    printf $fh "*    %-72s  *\n"," ";
    if   ($desvec =~/PRHL/) {$tmp="VERSION: REFINE: best model";}
    elsif($desvec =~/PR2HL/){$tmp="VERSION: REFINE: 2nd best model";}
    elsif($desvec =~/PFHL/ ){$tmp="VERSION: FILTER: old stupid filter of HTM";}
    elsif($desvec =~/PHL/ ) {$tmp="VERSION: probably no HTM filter, just network";}
    printf $fh "*    %-72s  *\n",$tmp;
    print  $fh "*"," " x 78, "*\n";
    @tmp=("Burkhard Rost, EMBL, 69012 Heidelberg, Germany",
	  "(Internet: rost\@EMBL-Heidelberg.DE)");
    foreach $tmp (@tmp) {
	printf $fh "*    %-72s  *\n",$tmp;}
    print  $fh "*"," " x 78, "*\n";
    $tmp=&sysDate();
    printf $fh "*    %-72s  *\n",substr($tmp,1,70);
    print  $fh "*"," " x 78, "*\n";
    print  $fh "*" x 80, "\n";
				# numbers
    $tmp=$#id;
    printf $fh "num %4d\n",$tmp;
    if ($opt_phd eq "acc"){print $fh "nos(ummary)\n";}
				# ------------------------------
				# all proteins
    foreach $it (1..$#id) {
	$id=$id[$it]; 
	&wrt_res1_fin($fh,$id,$nres_per_row,$opt_phd,$desvec,$LnoHdr,%all);
    }
    print $fh "END\n";
    close($fh);
    return(1,"ok $sbrName");
}				# end of phdRdb2phdWrt

#==========================================================================================
sub wrt_res1_fin {
    local ($fhLoc2,$id,$nresPerRowLoc,$opt_phd,$desvec,$LnoHdrLoc,%all) = @_ ;
    local ($it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_res1_fin               writes the final output files for EVALSEC/ACC
#         A                     A
#--------------------------------------------------------------------------------
    @des=split(/,/,$desvec);
    $nres=$all{"$id","NROWS"};
				# header (name, length)
    if (! $LnoHdrLoc){
	if ($opt_phd eq "acc"){
	    printf $fhLoc2 "    %-6s %5d\n",substr($id,1,6),$nres;}
	else {
	    printf $fhLoc2 "    %10d %-s\n",$nres,$id;}}
				# rest
    for ($it=1; $it<=$nres; $it+=$nresPerRowLoc ) {
	$tmp=&myprt_npoints($nresPerRowLoc,$it);
	printf $fhLoc2 "%-3s %-s\n"," ",$tmp;
	foreach $des (@des) {
	    if ($opt_phd =~ /sec/)    { if   ($des=~/AA/)       {$txt="AA"; }
					elsif($des=~/OHEL/)     {$txt="DSP"; }
					elsif($des=~/PHEL/)     {$txt="PRD"; }
					elsif($des=~/RI_S/)     {$txt="Rel"; } }
	    elsif ($opt_phd eq "acc") { if   ($des=~/AA/)       {$txt="AA"; }
					elsif($des=~/OHEL/)     {$txt="SS"; }
					elsif($des=~/OREL/)     {$txt="Obs"; }
					elsif($des=~/PREL/)     {$txt="Prd"; }
					elsif($des=~/RI_A/)     {$txt="Rel"; } }
	    elsif ($opt_phd eq "htm") { if   ($des=~/AA/)       {$txt="AA"; }
					elsif($des=~/OHL/)      {$txt="OBS"; }
					elsif($des=~/PHL/)      {$txt="PHD"; }
					elsif($des=~/PFHLOC2L/) {$txt="FIL"; }
					elsif($des=~/PRHL/)     {$txt="PHD"; }
					elsif($des=~/PR2HL/)    {$txt="PHD"; }
					elsif($des=~/RI_S/)     {$txt="Rel"; } }
	    next if (! defined $all{"$id","$des"});
	    next if (length($all{"$id","$des"}) < $it);

	    $tmp=substr($all{"$id","$des"},$it,$nresPerRowLoc);
	    printf $fhLoc2 "%-3s|%-s|\n",$txt,$tmp;
	}
    }
    undef %all;
}				# end of wrt_res1_fin
