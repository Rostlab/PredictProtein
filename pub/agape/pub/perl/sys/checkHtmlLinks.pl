#!/usr/bin/perl -w
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   check existence of local links\n";
	      print"usage:  list of files \n";
	      exit;}

$sbrName="checkHtmlLinks.pl";

$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$sbrName.".tmp";

$href="A HREF";
$name="A NAME";
$src= "SRC";

$#locLink=$#file=0;
foreach $fileIn (@ARGV){
    if (! -e $fileIn){
	print "-*- WARNING '$fileIn' missing\n";
	next;}
    $#line=$#intern=$#internLine=$#name=0;$ctline=0;
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) { 
	++$ctline;
	$line=$_;$line=~s/\n//g;
	$line=~s/[Aa] [Hh][Nn][Aa][Mm][Ee]/$name/g;
	$line=~s/[Aa] [Hh][Rr][Ee][Ff]/$href/g;
	$line=~s/[Ss][Rr][Cc]=/$src=/g;
	if ($line !~/$href=|$name=|$src=/){
	    next;}
	$line=~s/^.<//g;
	@tmp=split(/</,$line);
	foreach $tmp(@tmp){
	    if ($tmp !~/$href=|$name=|$src=/){
		next;}
	    else {
		if ($tmp=~/$name/){$Lname=1;}else{$Lname=0;}
		$tmp=~s/^.*$href=|^.*$name=|^.*$src=//g;
		$tmp=~s/^\"([^\"]+)\".*$/$1/g;
		if (length($tmp)<3){
		    next;}
		if ($tmp =~ /^http|^mailto|^\/cgi|^ftp:|ftp\./){
		    next;}	# deal with non-local later
		if ($tmp=~/html\#/){ # link to other file -> ignore!
		    next;}
		if ($tmp=~/^\#/){ # check internal references (down)
		    push(@intern,$tmp);push(@internLine,$ctline);
		    next;}
		if ($Lname){ # check internal references (down)
		    push(@name,$tmp);
		    next;}
		$tmp=~s/^file\://g;
		if (! -e $tmp){
		    print "*** missing link   '$tmp' in '$fileIn'\n"; 
#		    exit;	# x.x
		    push(@locLink,"$ctline\tlink\t$tmp");push(@file,$fileIn);}}}
    }
    close($fhin);
    foreach $it(1..$#intern){
	$intern=$intern[$it];
	$intern=~s/^\#//g;$Lok=0;
	next if (length($intern)<2);
	foreach $name (@name){
	    if ($intern eq $name){$Lok=1;
				  last;}}
	if (! $Lok){
	    if ($intern =~/html\#/){ # link to other file -> ignore!
		next;}
	    print "*** missing intern '$intern' in '$fileIn'\n"; 
	    push(@locLink,"$internLine[$it]\tintern\t$intern");push(@file,$fileIn);}}
}
				# write output
&open_file("$fhout", ">$fileOut");
print "line  \ttype   \tlink   \tfile\n";
foreach $it (1..$#locLink){
    print "$locLink[$it]\t$file[$it]\n";
    print $fhout "$locLink[$it]\t$file[$it]\n";
}
close($fhout);
print "--- errors in file '$fileOut'\n";

exit;
