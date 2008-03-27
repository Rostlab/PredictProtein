#!/usr/bin/perl -w

$[ =1 ;				# count from one

@fileIn=
    (
     "mov.txt"
     );

@fileIn=@ARGV;

$fhin="FHIN";
$fhout="FHOUT";
$sep=  "\t";

$Ldebug=1;


$fileOut="out-mov.txt";
open($fhout,">".$fileOut);

foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
    open($fhin,$fileIn)|| warn "problem to open $fileIn\n";    
    while (<$fhin>) {
	next if ($_=~/^(see|You Save|List Price)/ ||
		 $_=~/^(Price:|Availability|Edition|See more product|Cast List)/);	
	next if ($_=~/^\s*(Eligible|Used )/);
	next if ($_=~/^\s*$/);
	$_=~s/\n//g;
	if    ($_=~/^.*director:\s*(\S.*)$/i){
	    $dir=$1;
	    $name=&name($dir);
	    print $fhout "director $name\n";
	}
	elsif ($_!~/ \.\.\. / &&
	       $_=~/[A-Za-z]+ [A-Za-z]+\s*$/) {
	    $name=&name($_);
	    print $fhout $name,"\n";
	    print "xx1 ($name)\n";
	}
	elsif ($_!~/\.\.\./ && $_!~/director/i){
	    print $fhout $_,"\n";
	    print "xx here $_\n";
	}
	else {
	    $_=~s/\s*\.\.+.*$//g;
	    $name=&name($_);
	    print $fhout $name,"\n";
	    print "xx2 ($name)\n";
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
    return($name);
}


