#!/usr/bin/perl -w

#=======================================================
# 
# 
#======================================================

if ( ! @ARGV ) {
    print "need at least two argument: switch mode (dev|pack) and target file\n";
    exit;
}

$dir_lib_dev = '/home/liu/project/domain/chopper/scr/lib';
$dir_lib_pack = 'DIRLIB';

$dir_root_dev = '/home/liu/project/domain/chopper/';
$dir_root_pack = 'DIRPACKAGE';

$mode = shift @ARGV;
if ( $mode eq 'dev' ) {
    $to_dev = 1;
} elsif ( $mode eq 'pack' ) {
    $to_dev = 0;
} else {
    print STDERR "*** ERROR: first argument must be dev|pack\n";
    exit;
}

while ( $fileIn = shift @ARGV ) {
    next if ( $fileIn !~ /\.pl$/ );
    next if ( $fileIn eq 'change_path.pl' );
    $fileTmp = $fileIn."_tmp$$";
    $changed = 0;
    $is_exe = 0;
    ($atime, $mtime) = (stat($fileIn))[8,9];

    open (TMP, ">$fileTmp") or die "cannot write to $fileTmp:$!";
    open (IN, $fileIn) or die "cannot open $fileIn:$!";
    while (<IN>) {
	$line = $_;
	if ( $mode eq 'dev' ) {
	    if ( $line =~ m!$dir_lib_pack! ) {
		$line =~ s!$dir_lib_pack!$dir_lib_dev!g;
		$changed = 1;
	    }
	    if ( $line =~ m!$dir_root_pack! ) {
		$line =~ s!$dir_root_pack!$dir_root_dev!g;
		$changed = 1;
	    }
	} else {
	    if ( $line =~ m!$dir_lib_dev! ) {
		$line =~ s!$dir_lib_dev!$dir_lib_pack!g;
		$changed = 1;
	    }
	    if ( $line =~ m!$dir_root_dev! ) {
		$line =~ s!$dir_root_dev!$dir_root_pack!g;
		$changed = 1;
	    }
	}
	print TMP $line;
    }
    close IN;
    close TMP;
    
    
    if ( $changed ) {
	if ( -x $fileIn ) {
	    $is_exe = 1;
	}
	print "modifying file $fileIn ..";
	rename $fileTmp,$fileIn or die "cannot rename $fileTmp to $fileIn:$!";
	utime($atime, $mtime, $fileIn) or die "cannot recover the timestamp:$!";
	if ( $is_exe ) {
	    chmod 0755,$fileIn or die "cannot change the permission:$!";
	}
	print "done\n";
    } else {
	print "$fileIn: nothing to be modified\n";
	unlink $fileTmp;
    }
}

exit;
