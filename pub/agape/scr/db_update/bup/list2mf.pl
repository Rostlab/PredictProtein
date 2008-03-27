#! /usr/bin/perl -w

($list,$fileOut)=@ARGV;

open(FHIN,$list) || 
    die "failed to open list=$list, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    ($file)=/^(\S+)/;
    $h_filesIn{$file}=1;
}
close FHIN;

if(! defined $fileOut){
    $fileOut=$list; $fileOut=~s/^.*\///;
    $fileOut="mf-".$fileOut;
}

$fileOutTmp=$fileOut.".tmp-".$$;

open(FHOUT,">".$fileOutTmp) || 
    die "failed to open $fileOutTmp for writing, stopped";

foreach $file (sort keys %h_filesIn){
    open(FH,$file) || 
	die "failed to open file=$file\n";
    @l_file=(<FH>);
    close FH;
    foreach $it (@l_file){ print FHOUT $it; }
}
close FHOUT;

rename($fileOutTmp,$fileOut) ||
    die "failed to rename $fileOutTmp to $fileOut, stopped";

