#!/bin/perl

#############################################################################
#
# Copyright 1993 Scott Bolte (scott@craycos.com)
#
#       Leave this copyright alone. But feel free to do with the script
#       as you please. Sending me enhancements would be appreciated.
#
#       If you feel like pretending this is shareware, and want to
#       send some money my way, feel free. I promise not to object.
#
# Summary of ftplist:
#
#	Run ftpls on a bunch of systems. The results are put in files
#	whose names map to the system/directory pair. Older copies are
#	renamed before the new edition is obtained.
#
#	The expectation is that additional scripts will be run after
#	this one.  They will compare the old and new listings to note
#	changes.
#
# History:
#
#       1993.06.28      Initial implementation.
#
# Examples:
#
#       ftplist
#
#############################################################################

%set = (
	"agate.berkeley.edu",		"pub/386BSD/386bsd-0.1/unofficial",
	"bsd.coe.montana.edu",		"pub/patch-kit",
	"hrd769.brooks.af.mil",		"pub/FAQ",
	"prep.ai.mit.edu",		"pub/gnu",
	);

foreach $system (sort(keys(%set))) {
	$file =  "$system:$set{$system}";
	$file =~ s,/,_,g;
	$old  = "$file.OLD";
	if ( -f $file ) {
		$error  = "Could not rename \"$file\" to \"$old\". $!\n";
		$error .= "New listing of $set{$system} will not be obtained.\n";
		rename($file, $old)	|| (warn($error), next);
	}
	$cmd = "ftpls $system $set{$system} > $file";
	system($cmd) && die("Could not run command ($cmd). $!\n");
}
