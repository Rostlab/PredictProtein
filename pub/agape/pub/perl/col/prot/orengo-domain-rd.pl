#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads the domain file from orengo";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file'\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

				# ------------------------------
				# (1) read file
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
    next if (length($_)<10);
    $beg=substr($_,1,14);$beg=~s/^\s+|\s*$//g;
    $end=substr($_,15);$end=~s/^\s+|\s*$//g;
				# ------------------------------
				# process first 14 characters '1aam00 D02 F01 '
    @tmpBeg=split(/\s+/,$beg);
    $tmpBeg[1]=~s/0$//g;	# redundant ending '0' for name
    $id=   substr($tmpBeg[1],1,4);
    $chain=substr($tmpBeg[1],5,1); 
    $chain="*" if ($chain eq "0"); # notation for no chain is '0' -> '*'
    $ndom=$tmpBeg[2];$ndom=~s/^D0?//g;
    if ($ndom=~/[^0-9]/){
	print "*** domain number wrong ndom=$ndom, line=$_\n";
	exit;}
				# ------------------------------
				# process remainder of line
    @tmp=split(/\s+/,$end);	# split into columns
    $ct=0;
    foreach $it (1..$ndom){
	++$ct;$nfrag=$tmp[$ct];
	print "xx nfrag=$nfrag, ct=$ct, itDomain=$it, (end=$end)\n";
	$txt="";
	foreach $it2 (1..$nfrag){
	    $ct+=2;		# ignore chain (redundant)
	    $txt.=$tmp[$ct]."-"; # fragment begin
	    $ct+=3;		# ignore '-' and chain again
	    $txt.=$tmp[$ct].","; # fragment end
	    ++$ct;		# ignore '-'
	    print "xx itfrag=$it2, ct=$ct, txt=$txt,\n";
	    if ($tmp[$ct] ne "-"){
		print "*** ERROR id=$id ($chain) it=$it (nd=$ndom), it2=$it2 (nf=$nfrag)\n";
		print "*** ct=$ct, tmp=",$tmp[$ct],",\n";
		exit;}}
	push(@id,"$id"."_"."$chain"."_"."$it");
	$txt=~s/,$//g;		# purge leading commata
	push(@dom,$txt); }
}close($fhin);
				# ------------------------------
				# (2) 

				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
print $fhout "no\t","idx\t","len\t","id\t","chain\t","pdbNo\n";
foreach $it(1..$#id){
    $ctRes=0;@tmp=split(/,/,$dom[$it]);
    foreach $tmp(@tmp){$tmp=~s/\s//g;($beg,$end)=split(/-/,$tmp);
		       $ctRes+=($end-$beg+1);}
    $id=$id[$it];$id=~s/_\d+$//g;$chain=$id;$chain=~s/^[A-Za-z0-9]+_//g;$id=~s/_.*$//g;
    print $fhout 
	$it,"\t",$id[$it],"\t",$ctRes,"\t",$id,"\t",$chain,"\t",$dom[$it],"\n";
}close($fhout);
print "--- output in $fileOut\n";
exit;
