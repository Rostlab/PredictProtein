#!/usr/pub/bin/perl5 -w
$[ =1 ;

# moves all input files from file'old' to file'new'

push (@INC, "/home/rost/perl","/home/phd/etc") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print "goal:  moves all input files from file'old' to file'new'\n";
	      print "usage: 'script old=OLD new=NEW \@file\n";
	      exit;}

$#file=0;
foreach $_(@ARGV){
    if    (/^old=/){$_=~s/^.*=|\n|\s//g;$old=$_;}
    elsif (/^new=/){$_=~s/^.*=|\n|\s//g;$new=$_;}
    else { $_=~s/\s|\n//g;
	   if (-e $_){push(@file,$_);}else { print"*** '$_' missing\n";}}}

foreach $file(@file){
    $fileNew=$file;$fileNew=~s/$old/$new/g;$fileNew=~s/^.*\///g;
    print "--- system 'mv $file $fileNew'\n";
    system("\\mv $file $fileNew");
}

exit;
