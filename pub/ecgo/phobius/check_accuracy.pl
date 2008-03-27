#!/usr/bin/perl

#$filename = shift;
#if (! defined $filename) {print "Usage: $0 filename\n";}

$homedir = ".";
opendir HOME, $homedir or die "error changing to prof\n";
@files = grep /^g\d\.faa.phdHTM/, readdir HOME;
#@files = grep /^glob.f.\d+.phdHTM/, readdir HOME;
#@files = grep /\.phdHTM$/, readdir HOME;

$mistakes = 0;
$correct = 0;

foreach $filename (@files) {
    open FIN, $filename or die "could not open $filename\n";
    
    while (<FIN>){
	if (/^>/){
	    $_ = <FIN>;
	    chomp;
	    if (/H/) {
		$mistakes++;
	    }else{
		$correct++;
	    }
	    <FIN>; #throw away this line
	}
    }
    close FIN;
}

print "Total preds: ".($mistakes+$correct)."\n";
print "Mistakes $mistakes\n";
print "Correct $correct\n";
printf "Accuracy: %.0f%%\n",($correct/($mistakes+$correct))*100;
