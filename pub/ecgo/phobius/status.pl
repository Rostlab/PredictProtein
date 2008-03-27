#!/usr/bin/perl

#$homedir = "/home/kernytsky/enzyme/prof";
$homedir = ".";
opendir HOME, $homedir or die "error changing to prof\n";
#@files = grep /^work.*/, readdir HOME;
#@files = grep /^work.\d+/, readdir HOME;
@files = grep /^work..\d+/, readdir HOME;
print "\x1b[2J";
$refresh = 15;

while (1) {
    print "PROF Job Status Display\n                                      \n";
    $linepos=0; $totaldone=0;
    foreach $file (@files) {
	@temp = split /\./, $file;
	$filenum = $temp[1];
	#open FIND, ("find $homedir/work.$filenum/result -name \"*.rdbProf\" | wc |") or die "error executing find\n";
	open FIND, ("find $homedir/$file -name \"*.rdbPhd\" | wc |") or die "error executing find\n";
	@temp = split /\s+/, <FIND>;
	close FIND;
	
	if ($temp[1] ne $lineval[$linepos]) {
	    print "\x1b[1;32m"; # Green, bold
	    $age[$linepos] = 0;
	} 
	if ($age[$linepos] > (7*60/$refresh)) {
	    print "\x1b[33m";} # Yellow
	if ($age[$linepos] > (14*60/$refresh)) {
	    print "\x1b[1;31m";} # Red, bold
	if ($age[$linepos] > (20*60/$refresh)) {
	    print "\x1b[5;1;31m";} # Red, bold, flashing
    
	printf "Chunk %2s: ",$filenum;
	print "$temp[1]                                         \n";
	print "\x1b[0m";
	$lineval[$linepos] = $temp[1];
	$age[$linepos]++;
	$linepos++;
	$totaldone += $temp[1];
    }
    printf ("\nTotal: $totaldone\n");
    sleep $refresh;
    #print "\x1b[2J";
    for ($i=0; $i<2; $i++) {
	print "\r                                  \n";
    }
    printf ("%c[%1dA", 27, $linepos+1+10+2+2);
}
