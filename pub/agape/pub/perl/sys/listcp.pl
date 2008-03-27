#!/usr/bin/perl5 -w
$[ =1 ;

# moves all input files from file'old' to file'new'

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
    print "--- system 'cp $file $fileNew'\n";
    system("\\cp $file $fileNew");
}

exit;
