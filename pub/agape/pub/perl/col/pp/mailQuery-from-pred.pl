#!/usr/pub/bin/perl -w
#
# for files in dirPred and not in dirMail the query file will be made  
#
$[ =1 ;
				# include libraries
require "/home/phd/ut/perl/ctime.pl";
require "/home/phd/ut/perl/lib-prot.pl";
require "/home/phd/ut/perl/lib-ut.pl";
require "/home/phd/ut/perl/lib-comp.pl";
				# help
$dirMail="/home/phd/server/mail/";
$dirPred="/home/phd/server/pred/tmp-frsvr/";

if ($#ARGV<1){
    print "goal:    for files in dirPred and not in dirMail the query file will be made \n";
    print "usage:   script mail=dirMail pred=dirPred\n";
    print "options: def (will read $dirMail, $dirPred)\n";
    print "         missing one will be reported\n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$Ldef=0;
foreach $_(@ARGV){
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^def\w*$/)      {$Ldef=1;}
    elsif($_=~/^mail=(.*)$/)   {$dirMail=$1; if ($dirMail !~/\/$/){$dirMail.="/";}}
    elsif($_=~/^pred=(.*)$/)   {$dirPred=$1; if ($dirPred !~/\/$/){$dirPred.="/";}}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

@file=`ls -1 $dirPred`;
$#missing=0;
foreach $file (@file){
    next if ($file !~/^pred/);
    $file=~s/\n|\s//g;
    $name=$file;$name=~s/^.*\///g;
    $mail=$dirMail.$name."_query";
    next if (-e $mail);
    print "xx missing $mail\n";
    if ($file !~ /$dirPred/){
	$file=~s/^.*\///g;
	$file=$dirPred.$file;}
				# read pred file
    &open_file("$fhin", "$file");
    $user=$orig="";
    while (<$fhin>) {
	$_=~s/\n//g;
	last if ($_=~/\s*\#/);
	if    ($_=~/^\s*from /){$_=~s/^\s*from\s*//g;$_=~s/\s//g;
				$user=$_;}
	elsif ($_=~/^\s*orig /){$_=~s/^\s*orig\s*//g;$_=~s/\s//g;
				$orig=$_;
				last;}}
    close($fhin);
    if (defined $user && (length($user)>3)){
	$mail=~s/^.*\///g;
	&open_file("$fhout",">$mail"); 
	print $fhout "from $user\n";
	print $fhout "orig $orig\n";
	print $fhout "resp MAIL\n";
	close($fhout);}
    else {
	push(@missing,$file);
	print "missing user in $file\n";}
}

print "no user given in \n";
foreach $tmp(@missing){
    print "$tmp\n";}
exit;
