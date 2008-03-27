#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="splits long SWISS-PROT files into several shorter ones\n";
#  
#
$[ =1 ;
				# ------------------------------
				# include libraries
foreach $arg(@ARGV){
    if ($arg=~/dirLib=(.*)$/){$dir=$1;
			      last;}}
$dir=$ENV{'PERLLIB'}    if (defined $ENV{'PERLLIB'} || ! defined $dir || ! -d $dir);
$dir="/home/rost/perl/" if (! defined $dir || ! -d $dir);
$dir.="/"               if ($dir !~/\/$/);
$dir=""                 if (! -d $dir);
foreach $lib("lib-ut.pl","lib-prot.pl","lib-comp.pl"){
#     $Lok=require $dir."lib-ut.pl";  
require "lib-ut.pl"; require "lib-br.pl";
#     die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n") if (! $Lok);}
				# ------------------------------
				# defaults
$par{"lenSplit"}=      3000;	# number of residues written
$par{"lenOverlap"}=     500;	# number of residues overlapping between split files

				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file_swiss' (or *swiss)\n";
    print "opt: \t \n";
    print "     \t fileOut=x (default id_species -> id[1..n]_species)\n";
#    print "     \t \n";
    foreach $kwd (keys %par){
	print "     \t $kwd=",$par{"$kwd"}," (def)\n";}
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";

				# ------------------------------
$#fileIn=0;			# read command line
foreach $arg (@ARGV){
    if   ($arg=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($arg=~/^=(.*)$/){$=$1;}
    else {$Lok=0;
	  if (-e $arg){$Lok=1;
		       push(@fileIn,$arg);}
	  if (! $Lok && defined %par){
	      foreach $kwd (keys %par){
		  if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					     last;}}}
	  if (! $Lok){print"*** wrong command line arg '$arg'\n";
		      die;}}}
$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;
				# ------------------------------
				# (1) read files
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    $#hdr=0;$seqRd=$id=$sq="";
    $Lok=&open_file("$fhin", "$fileIn");
    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
		next;}
    while (<$fhin>) {
	$_=~s/\n//g;
	if    ($_=~/^ID /){	# first line: id + length
	    $id=$_;}
	elsif ($_=~/^SQ /){	# last before sequence: SQ line
	    $sq=$_;}
	elsif ($_!~/^\s+/){	# no sequence
	    push(@hdr,$_);}
	else {			# is sequence
	    $_=~s/\s//g;
	    $seqRd.=$_;}}close($fhin);
                                # ------------------------------
#                                 # any action required?
    $lenFile=$id; $lenFile=~s/^.* (\d+) AA\..*$/$1/g;
    if ($lenFile <= $par{"lenSplit"}){
        print 
            "--- HEY the sequence in $fileIn is shorter ($lenFile) than the split length (",
            $par{"lenSplit"},")\n",
            "--- => no action!!\n";
        next;}
                                # ------------------------------
                                # determine number of output files needed
    $numOut=int($lenFile/($par{"lenSplit"}-$par{"lenOverlap"}));
    print 
        "--- $fileIn will be split into $numOut files with :\n",
        "---         ",$par{"lenSplit"},", residues each\n",
        "---     and ",$par{"lenOverlap"}," residues overlapping between the files\n";
				# ------------------------------
				# determine new lines for 'ID' 'SQ'
    $idNew=$id; $idNew=~s/^ID\s+([A-Z0-9\_]+) .*$/$1/g;
    $spaceId= 15-length($idNew);
    $spaceLen= 6-length($par{"lenSplit"});
    $addId=   $idNew." " x $spaceId;
    $addLen=  " " x $spaceLen . $par{"lenSplit"};
    $idNew="ID   ".$addId."STANDARD\;      PRT\;".$addLen." AA.";
    $tmp=$sq;$tmp=~s/^SQ\s+SEQUENCE\s+\d+( AA.*)$/$1/;
    $sqNew="SQ   SEQUENCE ".$addLen.$tmp;
				# ------------------------------
				# finally: write new files
    $tmp=$fileIn; $tmp=~s/^.*\///g;
    foreach $it (1..$numOut){
	$fileOut=$tmp;$fileOut=~s/^([^_]+)(_.+)$/$1_spl$it$2/;
	print "--- for $fileIn write $fileOut\n";
	&open_file("$fhout",">$fileOut"); 
	print $fhout "$idNew\n"; # new id
	foreach $hdr(@hdr){	# header
	    print $fhout "$hdr\n";}
	print $fhout "$sqNew\n"; # final header line
				# sequence
	$lenToRd=$par{"lenSplit"};
	$lenToRd=length($seqRd)-(1+($it-1)*($par{"lenSplit"}-$par{"lenOverlap"})) 
	    if ((length($seqRd)-(1+($it-1)*($par{"lenSplit"}-$par{"lenOverlap"})))<$par{"lenSplit"});

	$seqTmp=substr($seqRd,(1+($it-1)*($par{"lenSplit"}-$par{"lenOverlap"})),$lenToRd);

	for($itRes=1;$itRes<=length($seqTmp);$itRes+=60){
	    print $fhout "     ";
	    foreach $itRes2 (1..6){
		last if (($itRes+10*$itRes2)>=length($seqTmp));
		printf $fhout "%-10s ",substr($seqTmp,($itRes+10*$itRes2),10);}
	    print $fhout "\n";}
	print $fhout "\/\/\n";	# final line
	close($fhout);
    }
}

print "--- output in $fileOut\n";
exit;
