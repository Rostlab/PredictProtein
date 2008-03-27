#!/usr/local/bin/perl -w

$time = localtime();
print "$time\n";

$dirXch = "/home/$ENV{USER}/server/xch/";
@dir2check = ( 'prd/', 'res/' );

$ctRemove = 0;
foreach $dir ( @dir2check ) {
    $fullDir = $dirXch.$dir;
    unless (opendir (DIR, $fullDir)) {
	print "$fullDir cannot be opened: $!";
	exit;
    }
        
    @listFile = grep /_lock$/, readdir DIR;
    closedir DIR;
    
    foreach $file ( @listFile ) {
	$fullFile = $fullDir.$file;
	next if ( ! -f $fullFile );
	$age = -M $fullFile;
	if ($age > 0.05) {
	    printf "%s is %.2f days old, removing..\n",$fullFile,$age;
	    unlink $fullFile;
	    $ctRemove++;
	}
    }
}

print "total lock files removed=$ctRemove\n\n";

exit;


