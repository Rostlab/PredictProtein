#!/usr/sbin/perl -w
#
#  in:  bl*split*rdb  RDB blast out headers  (from blast2-runANDextr.pl) 
#  out: same split, but delete multiple pairs        
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

$fileTrue="/home/rost/pub/data/truePairs849Triangle.dat";
if ($#ARGV<1){print"goal:   in:  bl*split*rdb =RDB blast headers (from blast2-runANDextr.pl)\n";
	      print"       out:  same split, but delete multiple pairs\n";
	      print"\n";
	      print"usage:  script file1 file2 \n";
	      print"option: nonum  (will ignore 1xim when 2xim there, only for 2nd id)\n";
	      print"               if the file $fileTrue exists, will give priority to \n";
	      print "              those ids in file when ignoring\n";
	      exit;}

$#fileIn=0;$Lnonum=0;
foreach $_(@ARGV){
    if (/^no\w*$/){$Lnonum=1;}
    else {
	push(@fileIn,$_);}}
@fileIn=@ARGV;$#fileOk=0;

$fhin="FHIN";$fhout="FHOUT";

				# --------------------------------------------------
				# read true
if ($Lnonum){
    if (! -e $fileTrue){print "*** ERROR blastHeaderRdb2stat: fileTrue '$fileTrue' missing\n";
			exit;}
    &open_file("$fhin", "$fileTrue"); # external lib-ut.pl
    while(<$fhin>){
	$_=~s/\n//g;
	$_=~s/^([0-9a-zA-Z_]+)[\s\t].*$//g;
	$id1=substr($_,1,4); # purge chains
	$priority{$id1}=1;}close($fhin);}
				# ----------------------------------------
				# first round : get pairs
undef %line;undef %pair;
$ctIncl=$ctExcl=$ctFile=0;
print "--- will report every 1000 pair read with a dot\n";print "-" x 50, "\n";

$ctId=0; undef %id;		# safe space
foreach $fileIn(@fileIn){
    if (!-e $fileIn){print "*** not existing file (command line input) '$fileIn'\n";
		     next;}
				# read file
    &open_file("$fhin", "$fileIn");
    push(@fileOk,$fileIn);$fileName=$fileIn;$fileName=~s/^.*\///g;
    $ct=0;++$ctFile;
    while (<$fhin>) {
	++$ct;$_=~s/\n//g;
	next if ((! defined $_) || (length($_)<1));
	next if ($_ !~ /^\d/);
	@tmp=split(/\s+/,$_);
	next if ($#tmp<3); 
	$id1=$tmp[1];$id2=$tmp[2];$id2NoChain=substr($id2,1,4);
				# safe memory: store numbers
	if (!defined $id{$id1}){++$ctId;$id{$id1}=$ctId;}
	if ($Lnonum && (! defined $priority{$id2NoChain})){
	    $id2=substr($id2,2);} # purge number 1xim -> xim
	if (!defined $id{$id2}){++$ctId;$id{$id2}=$ctId;}
	$posId1=$id{$id1};$posId2=$id{$id2};

	print "." if (int($ct/1000) == ($ct/1000)); # intermediate write 

	if ($posId1 == $posId2){ # purge self
	    ++$ctExcl;
	    print "xx self $id1\n";
	    next;}
	    
	if ((! defined $pair{"$posId1,$posId2"})&&(! defined $pair{"$posId2,$posId1"})){
	    ++$ctIncl;
#	    print "xx take $id1,$id2\n";
	    $pair{"$posId1,$posId2"}=1;
	    $line{"$ctFile","$ct"}=1;}
	else {
	    print "xx no  $id1,$id2\n";
	    ++$ctExcl;}}
    close($fhin); print "\n";
}
				# clean memory
undef %pair; undef %id;

print  "--- -----------------------------------\n";
print  "--- after reading: \n";
printf "--- taken       =%10d\n",$ctIncl;
printf "--- not taken   =%10d\n",$ctExcl;
printf "--- sum         =%10d\n",($ctIncl+$ctExcl);
    
				# ----------------------------------------
$ctExcl2=$ctFile=0;		# second round : write new
foreach $fileIn(@fileOk){
    &open_file("$fhin", "$fileIn");$fileName=$fileIn;$fileName=~s/^.*\///g;++$ctFile;
    $fileOut="Out-".$fileName;print "--- write '$fileOut'\n";
    &open_file("$fhout",">$fileOut"); 
    $ct=0;
    while (<$fhin>) {
	++$ct;	$_=~s/\n//g;
	if    ($_!~/^\d/){	# header
	    print $fhout "$_\n";}
	elsif (defined $line{"$ctFile","$ct"}){ # ok take
	    print $fhout "$_\n";}
	else {			# dont take
	    ++$ctExcl2;}}
    close($fhin); 
    close($fhout);
}				# 
    
print  "--- -----------------------------------\n";
print  "--- security check : \n";
printf "--- taken       =%10d\n",$ctIncl;
printf "--- not taken   =%10d\n",$ctExcl;
printf "--- not taken 2 =%10d\n",$ctExcl2;
printf "--- sum         =%10d\n",($ctIncl+$ctExcl);
print "--- output in $fileOut\n";
exit;
