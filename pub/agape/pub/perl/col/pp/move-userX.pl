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

#$dir="/home/phd/server/pred";
				# help
if ($#ARGV<3){
    print "goal:    will move all requests from user x e.g. 'frsvr2\@mbi.ucla.edu'\n";
    print "usage:   script user dirToMoveTo file* (i.e. many)\n";
    print "options: dir=x (dir to move from)\n";
    print "         fileOut=x\n";
    exit;}
				# initialise variables
$user=   $ARGV[1];
$dirMove=$ARGV[2];
$fileOut="list-of-user".$$.".tmp";
$#fileIn=0;
foreach $_(@ARGV){
    next if ($_ eq $user ||$_ eq $dirMove);
    if    ($_=~/^dir=(.*)$/){$dir=$1;}
    elsif ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif (-e $_){push(@fileIn,$_);}
    else  {print "*** ERROR unrecognised argument '$_'\n";
	   die;}
}
if (defined $dir || -d $ARGV[3]){
    $dir=$ARGV[3] if (! defined $dir);
    @fileIn=`ls -1 $dir`;}

if ($#fileIn<1){
    print "*** no input file given\n";die;}

$fhin="FHIN";
$ct=0;
foreach $file(@fileIn){
    &open_file("$fhin","$file"); 
    $Lmove=0;
    while(<$fhin>){next if ($_!~/^\s*from /);
		   if ($_ =~/$user/i){
		       print "xx $user in $file\n";
		       $Lmove=1;}
		   last;}close($fhin);
    if ($Lmove){$cmd="\\mv $file $dirMove";
		print "--- system '$cmd'\n";
		++$ct;
		system("$cmd");}}

print "number of files found = $ct\n";
exit;
