#!/usr/bin/perl -w
$[ =1 ;

# moves all input files from file'old' to file'new'
if ($#ARGV<1){print "goal:  moves all input files from file'old' to file'new'\n";
	      print "usage: 'script old=OLD new=NEW \@file\n";
	      exit;}
$#file=0;
foreach $_(@ARGV){
    if    (/^old=(.*)$/)  {$old="$1";}
    elsif (/^new=(.*)$/)  {$new="$1";}
    else  { $_=~s/\s|\n//g;
	    if (-e $_){
		push(@file,$_);}else { print"*** '$_' missing\n";}}}
				# do the move
foreach $file(@file){
    next if (! -e $file);	# may have been removed meanwhile...
    next if ($file !~ /($old)/);
#    next if ($file !~ /\Q$old/);
#    $fileNew=$file;$fileNew=~s/\Q$old/\Q$new/g;$fileNew=~s/^.*\///g;
    $fileNew=$file;$fileNew=~s/$old/$new/;$fileNew=~s/^.*\///g;
    print "--- system 'mv $file $fileNew'\n";
    system("\\mv $file $fileNew");}
exit;
