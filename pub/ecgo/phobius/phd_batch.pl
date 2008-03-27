#!/usr/bin/perl

opendir DIR, ".";
@files = readdir DIR;

foreach (@files) {
    if (($_ !~ /^\./) and ($_ =~ /\.faa$/)) {
	system "qsub -cwd -S /usr/bin/perl phdhtm.pl $_";
	$iter++;
	#if ($iter >= 3) {last;}
    }
}
