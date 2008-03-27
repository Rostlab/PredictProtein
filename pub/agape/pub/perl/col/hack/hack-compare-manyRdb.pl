#!/usr/sbin/perl -w
#
#  reads 1xxx.rdb_bl1 and 1xxx.rdb_bl2 and includes only pairs in both
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:    reads 1xxx.rdb_bl1 and 1xxx.rdb_bl2 and includes only pairs in both\n";
    print "            output will be in 1xxx.rdb_bl1_cor 1xxx.rdb_bl2_cor\n";
    print "usage:   script *.rdb_bl1 (assumed the others are: rdb_bl2, rdb_max\n";
    print "            note: the other will get same name, but bl1 -> bl2\n";
    print "options: \n";
    print "         fileOut=x\n";
    print "         \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# --------------------------------------------------
foreach $fileIn(@ARGV){		# read files from command line
    next if (! -e $fileIn);
    $file2=$fileIn;$file2=~s/bl1/bl2/g;
    $file3=$fileIn;$file3=~s/bl1/max/g;
    next if (! -e $file2 || ! -e $file3);
    print "--- reading $fileIn, ";
				# ------------------------------
    undef %id1;$#id1=$#line1=0; # 1st file (blast old)
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\n//g;
		     push(@line1,$_);
		     next if (/^id/); # line with names
		     $id=$_;$id=~s/^[\w\d]+\t([\w\d]+)\t.*$/$1/g;$id=~s/_.*//g; # purge chain
		     if (!defined $id1{$id}){push(@id1,$id);$id1{$id}=1;}}close($fhin);
    print "$file2, ";		# ------------------------------
    undef %id2;$#id2=$#line2=0; # 2nd file (blast new)
    &open_file("$fhin", "$file2");
    while (<$fhin>) {$_=~s/\n//g;
		     push(@line2,$_);
		     next if (/^id/); # line with names
		     $id=$_;$id=~s/^[\w\d]+\t([\w\d]+)\t.*$/$1/g;$id=~s/_.*//g; # purge chain
		     if (!defined $id2{$id}){push(@id2,$id);$id2{$id}=1;}}close($fhin);
    print "$file3\n";		# ------------------------------
    undef %id3;$#id3=$#line3=0; # 3rd file (maxhom)
    &open_file("$fhin", "$file3");
    while (<$fhin>) {next if (/^\#|^4[\t\s]+6S/); # ignore comments and RDB format
		     $_=~s/\n//g;
		     push(@line3,$_);
		     next if (/^pos/); # line with names
		     $id=$_;
		     $id=~s/^[\w\d]+[\t\s]+[\w\d]+[\t\s]+([\w\d]+)[\t\s]+.*$/$1/g;
		     $id=~s/\s//g; $id=substr($id,1,4);  # purge chain
		     if (!defined $id3{$id}){push(@id3,$id);$id3{$id}=1;}}close($fhin);
				# --------------------------------------------------
				# now: rewrite
    $fileOut1=$fileIn;$fileOut1=~s/^.*\///g;$fileOut1.="_cor";
    print "--- writing $fileOut1, ";
    undef %done;
    &open_file("$fhout",">$fileOut1");
    foreach $line(@line1){
	if ($line=~/^id/){print $fhout "$line\n";}
	else{
	    $id=$line;$id=~s/^[\w\d]+\t([\w\d]+)\t.*$/$1/g;$id=~s/_.*//g;
	    next if (! defined $id1{$id} || ! defined $id2{$id} || ! defined $id3{$id});
	    next if (! $id1{$id} || ! $id2{$id} || ! $id3{$id});
	    next if (defined $done{$id} && $done{$id});	# avoid doubling
	    $done{$id}=1;
	    print $fhout "$line\n";}} close($fhout);
    $fileOut2=$file2;$fileOut2=~s/^.*\///g;$fileOut2.="_cor";
    print " $fileOut2, ";
    &open_file("$fhout",">$fileOut2"); 
    undef %done;
    foreach $line(@line2){
	if ($line=~/^id/){print $fhout "$line\n";}
	else{
	    $id=$line;$id=~s/^[\w\d]+\t([\w\d]+)\t.*$/$1/g;$id=~s/_.*//g;
	    next if (! defined $id1{$id} || ! defined $id2{$id} || ! defined $id3{$id});
	    next if (! $id1{$id} || ! $id2{$id} || ! $id3{$id});
	    next if (defined $done{$id} && $done{$id});	# avoid doubling
	    $done{$id}=1;
	    print $fhout "$line\n";}} close($fhout);
    close($fhout);
    $fileOut3=$file3;$fileOut3=~s/^.*\///g;$fileOut3.="_cor";
    print "$fileOut3, \n";
    &open_file("$fhout",">$fileOut3");
    undef %done;
    foreach $line(@line3){
	if ($line=~/^id/){print $fhout "$line\n";}
	else{
	    $id=$line;
	    $id=~s/^[\w\d]+[\t\s]+[\w\d]+[\t\s]+([\w\d]+)[\t\s]+.*$/$1/g;
	    $id=~s/\s//g; $id=substr($id,1,4);  # purge chain
	    next if (! defined $id1{$id} || ! defined $id2{$id} || ! defined $id3{$id});
	    next if (! $id1{$id} || ! $id2{$id} || ! $id3{$id});
	    next if (defined $done{$id} && $done{$id});	# avoid doubling
	    $done{$id}=1;
	    print $fhout "$line\n";}} close($fhout);
}

exit;
