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
# Summary of ftpls:
#
#	Do a ls in a specific directory on a remote ftp system.
#	Anonymous ftp is used.
#
# History:
#
#       1993.06.28      Initial implementation.
#
# Examples:
#
#       ftpls remote_system remote_dir
#
#############################################################################

$cmd   = "ftp -n";	# change "ftp -n" to "cat -n" for testing.
$zero =  $0;
$zero =~ s,.*/,,;

#############################################################################
#
# Verify the arguments
#
if ( $#ARGV != 1 ) {
	print(STDERR "Usage: $zero system remote_dir\n");
	exit(1);
}

$system      = $ARGV[0];
$remote_dir  = $ARGV[1];

#############################################################################
#
# Build the batch ftp command.
#
$user        =  (getpwuid($<))[0];	# safe when run from "at".
$localhost   =  `hostname`; chop($localhost);
if ( $localhost !~ /\./ ) {
	#
	# If the host name does not have '.' notation try to
	# get an alias. We then hope it is in domain name notation.
	#
	@fullhost  = gethostbyname($localhost);
	$localhost = $fullhost[1] if $fullhost[1] ne ""; 
}
$template =
"	open $system
	user anonymous ${zero}4$user@$localhost
	bin
	cd $remote_dir
	ls -l
	bye
";

#############################################################################
#
# Run the batch ftp command.
#
open(CMD, "|$cmd") || die("Could not start command ($cmd). $!\n");
print CMD $template;
close(CMD);

exit(0);
