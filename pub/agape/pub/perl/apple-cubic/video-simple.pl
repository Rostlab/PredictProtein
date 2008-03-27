#!/usr/bin/perl -w

$[ =1 ;				# count from one

if ($#ARGV < 1){
    print "--- simple version: comma sep into names\n";
    exit;
}
$fhin="FHIN";
$fhout="FHOUT";
#$sep=  "\t";

#$Ldebug=1;

@fileIn=@ARGV;

$fileOut="out-mov.txt";
open($fhout,">".$fileOut);

foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
    open($fhin,$fileIn)|| warn "problem to open $fileIn\n";    
    while (<$fhin>) {
	$_=~s/\n//g;
	$_=~s/^\s*|\s*$//g;
	$_=~s/^\,*|\,*$//g;
	@tmpname=split(/,/,$_);
	foreach $tmpname (@tmpname){
	    $name=&name($tmpname);
	    print $fhout $name,"\n";
	    print "$name\n";
	}
    }				# 
    close($fhin);
}

close($fhout);
print "--- output in $fileOut\n";

sub name {
    local($in)=@_;
    $in=~s/^\s*|\s*$//g;
    @tmp=split(/\s+/,$in);
    $name=$tmp[$#tmp].", ";
    foreach $it (1..($#tmp-1)){
	$tmp[$it]=~s/\.//g;
	$name.= $tmp[$it]." ";
    }
    $name=~s/\s*$//g;
#    $name=~s/\b([A-Z])\./$1/g;
    $name=~s/\s*\,*$//g;
    return($name);
}


