#! /usr/bin/perl -w

($ListFile,$fileOut)=@ARGV;

if(! defined $fileOut){
    $fileOut=$ListFile; $fileOut=~s/^.*\/|\..*$//g;
    $fileOut.=".comb";
}
open(FHLIST,$ListFile) || die "no $ListFile, stopped";
while(<FHLIST>){
    next if(/^\s+$/);
    s/\s*$//;
    push @RdbList, $_;
}
close FHLIST;


open(FHOUT,">".$fileOut) || die "no $fileOut, stopped";

foreach $RdbFile (@RdbList){
    if($RdbFile=~/\.gz$/){
	$cmd="gunzip -c $RdbFile";
	open(FHIN,"$cmd |") ||
	    die "ERROR failed to open $cmd, stopped";
    }else{
	open(FHIN,$RdbFile) ||
	    die "ERROR failed to open RdbFile=$RdbFile, stopped";
    }
 
    while(<FHIN>){
	next if (/^\s+$/);
	next if (/^\#/);
	if(/^id1/){
	    $headerLoc=$_;
	    if(! defined $header){ $header=$headerLoc; print FHOUT $header; }
	    next;
	}
	#s/pdb\|pdb\|//;
	print FHOUT $_;
    }
    close FHIN;
}
close FHOUT;
