#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
#  removes HSSP files with NALIGN < input
#
$[ =1 ;

if ($#ARGV<1){print"goal:   removes HSSP files with NALIGN < num\n";
	      print"usage:  'script num files <dbg>'\n";
	      exit;}

$Ldebug=0;
$num=$ARGV[1];
foreach $it (2..$#ARGV){
    $_=$ARGV[$it];
    if    (-e $_){
	push(@fileIn,$_);}
    elsif ($_=~/^de?bu?g$/i) {
	$Ldebug=1;}
}
$fhin="FHIN";
foreach $fileHssp(@fileIn){
    open($fhin, $fileHssp) || 
	do { warn "*** failed opening fileHssp=$fileHssp!\n";
	     next; };
    while (<$fhin>) {
	next if ($_!~/^NALIGN/);
	$_=~s/^NALIGN//g;$_=~s/\D//g;
	$Ldel=0;		# 
	$Ldel=1 if ($_ < $num);
	last;}
    close($fhin);
    if ($Ldel) {
	print "--- system \t '\\rm $fileHssp'\n" if ($Ldebug);
	unlink($fileHssp);
    }
}
exit;
