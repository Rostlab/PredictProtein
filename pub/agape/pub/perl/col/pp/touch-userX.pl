#!/usr/pub/bin/perl4 -w
#
#  will touch all jobs from user x e.g. 'frsvr2\@mbi.ucla.edu'
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;
if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}

require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

$dir="/home/phd/server/pred";
				# help
if ($#ARGV<1){
    print "goal:    will touch all jobs from user x e.g. 'frsvr2\@mbi.ucla.edu'\n";
    print "         with argument pat=#.*msf it will find all with this pattern\n";
    print "usage:   script user\n";
    print "options: dir=x (default is $dir)\n";
    print "         fileOut=x\n";
    exit;}
				# initialise variables
$user=$ARGV[1];
$fileOut="list-of-user".$$.".tmp";
foreach $_(@ARGV){
    if    ($_=~/^dir=(.*)$/){$dir=$1;}
    elsif ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif ($_=~/^pat=(.*)$/){$pat=$1;}
}
if ($dir !~ /\/$/) {$dir.="/";}

@file=`ls -1 $dir`;
if ((defined $pat)&&(length($pat)>1)){
    $grep="$pat";$user=$pat;}
else{
    $grep="from .*$user";}

$fhout="FHOUT";
&open_file("$fhout",">$fileOut"); 
$ct=0;
foreach $file(@file){
    $file=$dir.$file;$file=~s/\n//g;
    $txt=`grep -i '$grep' $file`; $txt=~s/\n//g;$txt=~s/from //g;
#    print "file =$file, grep=$grep, res=$txt\n";
    if ($txt=~/$user/){
	system("touch $file");
	++$ct;
	print "found '$txt' ($user) in $file\n";
	print $fhout "$file\n";
    }
}

close($fhout);

print "list of all files in $fileOut\n";
print "number of files found = $ct\n";
exit;
