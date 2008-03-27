#!/usr/bin/perl -w
##!/usr/sbin/perl -w

#
# reads file and converts all tabs to commata
#
$[ =1 ;

$fhin="FHIN";$fhout="FHOUT";
foreach $arg (@ARGV){
    $file_in=$arg;
    $file_out=$file_in;$file_out=~s/^.*\///g;$file_out=~s/\.[^.]*$/\.prt/g; # 
    $file_out=".tmp" if ($file_out eq $file_in);

    open($fhin, $file_in)      || die ("*** failed to open file=$file_in!\n");
    open($fhout,">".$file_out) || die ("*** failed to open fileout=$file_out!\n");
    while (<$fhin>) {
	$_=~s/\t/,/g;
	print $fhout $_;
    }
    close($fhin);close($fhout);
    print "--- output in $file_out\n";
}
exit;
