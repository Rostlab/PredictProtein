#!/usr/sbin/perl -w
#
# takes truePairs849.list and replaces all by all:
# eg: id1=j1,j2,id2,j3
#     id2=k1,k2,k3
# =>  id1=j1,j2,k1,k2,k3,j3
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   sorts truePairs849.list and purges double\n";
	      print"usage:  script truePairs849.list\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="out-".$fileIn;
				# now read true list and add
&open_file("$fhin", "$fileIn");
$#id=0;
while (<$fhin>) {$_=~s/\n//g;$_=~s/^\s+|\s+$//g;
		 ($id,$tmp)=split(/\s+/,$_);$rd{$id}=$tmp;push(@id,$id);}close($fhin);

&open_file("$fhout", ">$fileOut");
foreach $id (@id){
    $tmp=$rd{$id};
    $tmp=~s/^,+|,+$//g;
				# now append all others
    @tmp=split(/,/,$tmp);
    $new="";
    foreach $tmp(@tmp){ 
	if (! defined $rd{$tmp}){$new.="$tmp,";}}
    $new=~s/^,+|,+$//g;
				# now avoid duplications
    @tmp=split(/,/,$tmp);
    $new="";%ok=0;
    foreach $tmp(@tmp){
	if (! defined $ok{$tmp}){$new.="$tmp,";$ok{$tmp}=1;}}
    $new=~s/^,+|,+$//g;
				# sort
    @tmp=split(/,/,$new);
    @tmp2=sort @tmp;
    $new="";foreach $tmp(@tmp2){$new.=",".$tmp;}
    $new=~s/^,+|,+$//g;
    print $fhout "$id\t$new\n";
}
close($fhout);

print "-- output in $fileOut\n";
exit;
