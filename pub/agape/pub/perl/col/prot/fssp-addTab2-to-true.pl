#!/usr/sbin/perl -w
#
# replaces representative set pdb by all similar ones (TABLE2)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   replaces representative set pdb by all similar ones (TABLE2)\n";
	      print"usage:  script true*list \n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
$fileTab="/data/fssp/TABLE2";
				# read FSSP table
&open_file("$fhin", "$fileTab");
while (<$fhin>) {last if /^PDBid/;}
while (<$fhin>) {$_=substr($_,1,12);$_=~s/^\s+|\s+$//g;$_=~s/-//g;
		 @tmp=split(/\s+/,$_);
		 if (! defined $fssp{$tmp[2]}){$fssp{$tmp[2]}=$tmp[1];
					       push(@id,$tmp[2]);}
		 else {$fssp{$tmp[2]}.=",".$tmp[1];}}close($fhin);
				# look for unique stuff
$#id2=0;
foreach $id(@id){
    $tmp="";@tmp=split(/,/,$fssp{$id});
    foreach $tmpid(@tmp){
	if ($tmpid !~ $id){$tmp.=",".$tmpid;}}
    $tmp=~s/^,+|,+$//g;
    $fssp{$id}=$tmp;
    if (length($fssp{$id})>3){push(@id2,$id);}}
@id=@id2;

foreach $id (@id){$tmp{$id}=$fssp{$id};}
%fssp=%tmp;
				# now read true list and add
&open_file("$fhin", "$fileIn");
&open_file("$fhout", ">$fileOut");
while (<$fhin>) {$_=~s/\n//g;$_=~s/^\s+|\s+$//g;
		 ($id,$tmp)=split(/\s+/,$_);
		 $tmp=~s/^,+|,+$//g;
		 @tmp=split(/,/,$tmp);
		 $new="";
		 foreach $tmp(@tmp){$new.="$tmp,";
				    if (defined $fssp{$tmp}){$new.=$fssp{$tmp}.",";}}
		 $new=~s/^,+|,+$//g;
		 print $fhout "$id\t$new\n";}
close($fhin);close($fhout);

print "-- output in $fileOut\n";
exit;
