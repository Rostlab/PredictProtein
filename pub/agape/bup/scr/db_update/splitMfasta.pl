#! /usr/local/bin/perl -w

($mfasta,$dirOut)=@ARGV;

if(! defined $dirOut){ 
    $dirOut="./";
}else{ $dirOut.="/" if($dirOut !~ /\/$/); }

open(FHIN,$mfasta) || 
    die "*** could not open $mfasta\n";
while (<FHIN>) {
    next if($_=~/^\n/);
    if (/^>/) {
	($name)=/^>(\S+)/;
	$id=$name; $id=~s/.*\|//;
	$fileOut=$dirOut.$id.".f";
	open (FHOUT, ">$fileOut") ||
	    die "failed to open $fileOut for writing, stopped";
    }
    print FHOUT $_;	       
}
close FHOUT;
close FHIN;	
	      

  	    
