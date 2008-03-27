#!/usr/sbin/perl -w
#
# reads a couple of FSSP files and reports overlapping proteins 
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
if ($#ARGV<1){print"goal:   reads a couple of FSSP files and reports overlapping proteins \n";
	      print"usage:  script *.fssp \n";
	      exit;}

$fhin="FHIN";$fhout="FHOUT";
$fileOut="clusterFssp-".$$.".tmp";
$des="body,STRID1,STRID2";
$dirFssp="/data/fssp/";

$#id1=$#id2=0;
foreach $file (@ARGV){
    if ($file !~ /fssp$/){$file.=".fssp";}
    if (! -e $file){$file=~s/-//g;}
    if (! -e $file){$file=$dirFssp.$file;}

    if (! -e $file){
	print "xx missing $file\n";
	next;}

    print "xx reading $file\n";
    %rd=&fsspRdSummary($file,$des);
    $id1=$rd{"STRID1","1"};
    $tmp="";
    foreach $it (1..$rd{"NROWS"}){
	$id2=$rd{"STRID2","$it"};
	if (! defined $ptr{"$id2"}){$ptr{"$id2"}=$id1;push(@id2,$id2);}
	else {$ptr{"$id2"}.=",".$id1;}
	$tmp.="$id2,";}
    $tmp=~s/,$//g;
    $res{"$id1"}=$tmp;push(@id1,$id1);}

foreach $id2 (@id2){		# clean up
    $ptr{"$id2"}=~s/^,|,$//g;}
				# count overlaps

print "\# all ids read (id2) : fssp origin\n";
foreach $id2(@id2){
    $id1=substr($id1[1],1,4);$tmp=$ptr{"$id2"};
    if (($tmp=~/,/)&&($tmp=~/$id1/)){
	printf "\# %-10s %-s\n",$id2,$ptr{"$id2"},"\n";}}

print "id1\tctOv\tids found\n";
$cross="";%cross=0;
foreach $id1 (@id1){
    @tmp2=split(/,/,$res{"$id1"});
    $ct=0;$ok="";
    foreach $tmp2(@tmp2){@tmpF=split(/,/,$ptr{"$tmp2"});
			 foreach $tmpF(@tmpF){
			     next if ($tmpF =~/$id1/);
			     $ok.="$tmpF".",";++$ct;
			     if (! defined $cross{$tmp2}){$cross.="$tmp2,";$cross{$tmp2}=1;}
			     last;}}
				# sort ids
    @tmp2=split(/,/,$res{"$id1"});
    @tmp=sort @tmp2;$tmp2="";
    foreach $tmp(@tmp){$tmp2.="$tmp,";}
#    print "$id1\t$ct\t",$res{"$id1"},"\n";
    $tmp2=~s/-//g;
    if ($ct>0){
#	print "$id1\t$ct\t$tmp2\n";
	print "$id1,$tmp2\n";
    }
}
print "cross\t \t$cross\n";
    
	

#&open_file("$fhout",">$fileOut"); close($fhout);

exit;
