#! /usr/bin/perl -w

#read mfasta and write out lengths of sequences

($mfasta,$fileOut)=@ARGV;

if(! defined $fileOut){
    $fileOut=$mfasta; $fileOut=~s/^.*\/|\..*$//g;
    $fileOut.=".lengths";
}

open(FHIN,$mfasta) || 
    die "failed to open mfasta=$mfasta, stopped";
$seqLoc="RRRR";
while(<FHIN>){
    if(/^>/){
	if($seqLoc !~ /[^ACGUTIXF]/i){ 
	    print "WARNING: $id; sequence maybe DNA/RNA:$seqLoc\n";
	}
	($id)=/^>(\S*)/;
	die "id not understood in line:\n$_, stopped"
	    if(length($id) <1);
	$seqLoc="";
	$h_lengths{$id}=0;
    }else{
	s/\n$//;
	s/\s//g;
	$seqLoc.=$_;
	$tmp=length($_);
	$h_lengths{$id}+=$tmp;
    }
}
close FHIN;

open(FHOUT,">$fileOut") ||
    die "failed to open fileOut=$fileOut, stopped";
foreach $id (sort keys %h_lengths){
    print FHOUT $id."\t".$h_lengths{$id}."\n";
}
close FHOUT;
