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

if ($#ARGV<2){print"goal:   replaces protein by list in truePairs849.list\n";
	      print"usage:  script truePairs849.list matches.file \n";
	      exit;}

$fileIn1=$ARGV[1];
$fileIn2=$ARGV[2];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="out-".$fileIn1;
				# read matches table
&open_file("$fhin", "$fileIn2");
while (<$fhin>) {$_=~s/\n//g;$_=~s/^\s+|\s+$//g;$_=~s/-//g;
		 if (length($_)<5){
		     next;}
		 ($id,$tmp)=split(/\s+/,$_);
		 $tmp=~s/^,+|,+$//g;
		 if (! defined $rd{$id}){$rd{$id}=$tmp;
					 push(@id,$id);}
		 else {$rd{$id}.=",".$tmp;}}close($fhin);
				# look for unique stuff
$#id2=0;
foreach $id(@id){
    $tmp="";@tmp=split(/,/,$rd{$id});
    foreach $tmpid(@tmp){
	if ($tmpid !~ $id){$tmp.=",".$tmpid;}}
    $tmp=~s/^,+|,+$//g;
    $rd{$id}=$tmp;
    if (length($rd{$id})>3){push(@id2,$id);}}
@id=@id2;

foreach $id (@id){$tmp{$id}=$rd{$id};}
%rd=%tmp;
				# now read true list and add
&open_file("$fhin", "$fileIn1");
&open_file("$fhout", ">$fileOut");
while (<$fhin>) {$_=~s/\n//g;$_=~s/^\s+|\s+$//g;
		 ($id,$tmp)=split(/\s+/,$_);
		 $tmp=~s/^,+|,+$//g;
		 @tmp=split(/,/,$tmp);
		 $new="";
		 foreach $tmp(@tmp){$new.="$tmp,";
				    if (defined $rd{$tmp}){
					$new.=$rd{$tmp}.",";}
				    elsif (length($tmp)>4){
					$tmp=substr($tmp,1,4);
					if (defined $rd{$tmp}){$new.=$rd{$tmp}.",";}}}
		 $new=~s/^,+|,+$//g;
				# now avoid duplications
		 @tmp=split(/,/,$new);
		 $new="";%ok=0;
		 foreach $tmp(@tmp){if (! defined $ok{$tmp}){$new.="$tmp,";$ok{$tmp}=1;}}
		 $new=~s/^,+|,+$//g;
				# sort
		 @tmp=split(/,/,$new);
		 @tmp2=sort @tmp;
		 $new="";foreach $tmp(@tmp2){$new.=",".$tmp;}
		 $new=~s/^,+|,+$//g;
		 print $fhout "$id\t$new\n";}
close($fhin);close($fhout);

print "-- output in $fileOut\n";
exit;
