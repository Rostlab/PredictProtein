#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads list of ids returns list of existing and missing files";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName'\n";
    print "opt: \t \n";
    print "     \t fileOutOk=x(file for OK, other: fileOutNo)\n";
    print "     \t dir=x      (dir where to search: \$dir.\$id)\n";
    print "     \t ext=x      (ext to add to id:    \$dir.\$id.\$ext)\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$dir= "hsspDom/";
$ext= ".hssp";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$tmp=~s/\..*$//g;$fileOutOk="OutOk-".$tmp.".list";
$fileOutNo=$fileOutOk;$fileOutNo=~s/Ok/No/;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if    ($_=~/^fileOutOk=(.*)$/)   {$fileOutOk=$1;}
    elsif ($_=~/^fileOutNo=(.*)$/){$fileOutNo=$1;}
    elsif ($_=~/^dir=(.*)$/)       {$dir=$1;}
    elsif ($_=~/^ext=(.*)$/)       {$ext=$1;}
#    elsif ($_=~/^=(.*)$/){$=$1;}
    else  {print"*** wrong command line arg '$_'\n";
	   die;}}
$dir=&complete_dir($dir);
if (! -e $fileIn){print "*** missing input file $fileIn\n";
		  die;}
				# ------------------------------
				# (1) read file
$#id=0;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {$_=~s/\n//g;$_=~s/\s//g;
		 $_=~s/^.*\///g; # purge directory
		 next if (length($_)<1);
		 push(@id,$_);}close($fhin);
				# ------------------------------
$#ok=$#not=0;			# (2) search files
foreach $id (@id){
    $file=$dir.$id.$ext;
    if (-e $file){
	push(@ok,$file);}
    else{
	push(@not,$id);}}
				# ------------------------------
				# write output
&open_file("$fhout",">$fileOutOk"); 
foreach $ok(@ok){
    print $fhout "$ok\n";}close($fhout);


&open_file("$fhout",">$fileOutNo"); 
foreach $not(@not){
    print $fhout "$not\n";}close($fhout);

print "--- numid=",$#id,", numOk=",$#ok,", numNo=",$#not,",\n";
print "--- output in $fileOutOk,$fileOutNo\n";
exit;
