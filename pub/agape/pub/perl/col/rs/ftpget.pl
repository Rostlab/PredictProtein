#!/bin/perl

#############################################################################
#
# Copyright 1993 Scott Bolte (scott@craycos.com)
#
#	Leave this copyright alone. But feel free to do with the script
#	as you please. Sending me enhancements would be appreciated.
#
#	If you feel like pretending this is shareware, and want to
#	send some money my way, feel free. I promise not to object.
#
# Summary of ftpget:
#
#	Obtain a file via ftp from a remote system. Anonymous ftp
#	is used. Can be asked to delay the actual ftp request. 
#	On failure print out a call that can be used to try again.
#
# History:
#
#	1993.06.14	Initial implementation.
#
#	1993.06.15	Made remote and local file name processing safe
#			even when the file name contains white space.
#
#	1993.06.28	Added interface to use "at" internally.
#
# Examples:
#
#	ftpget --at 23:30 prep.ai.mit.edu pub/gnu/perl-4.036.tar.gz
#
#	ftpget --at 23:30 prep.ai.mit.edu pub/gnu/perl-4.036.tar.gz new-perl
#
#    If you have an ftp hierarchy, as I do, the remote system can be
#    derived from the current path.
#
#	cd ~/ftp/prep.ai.mit.edu
#	ftpget --at 23:30 - pub/gnu/perl-4.036.tar.gz
#
#############################################################################

$zero =  $0;
$zero =~ s,.*/,,;

sub usage {
	print <<EOS;
Usage: $zero [options] system remote_file [local_file]
    --			 Stop command line processing.
    -a or --at time    	 At the given time, which should be in hh:mm format,
			 run the $0 command.
    -d or --debug    	 Do not run the actual ftp command, use cat instead.
    -v or --verbose	 Enable the verbose status message.
    -? or -h or --help	 Print this usage statement.

    If the system is "-" try to determine the remote system from
    the current path.
EOS
}

#
# Set the default values.
#
$verbose  = 0;
$debug	  = 0;
$cmd      = "ftp -n";	# change "ftp -n" to "cat -n" for testing.
$time     = time;	# Get the time so we can recreate an "at"
			# command if need be.

#
# Process the command line.
#
while ($ARGV[0] =~ /^-./) {
	$_ = shift;
	if (/^--$/) {
		last;
	}

	if (/^-a$/ || /^--at$/) {
		$delay_time = shift;
		if ( $delay_time !~ /^\d\d?:\d\d$/ ) {
			print(STDERR
				"Bad time specification \"$delay_time\".\n");
			&usage();
			exit(1);
		}
		next;
	}
	if (/^-d$/ || /^--debug$/) {
		$debug++;
		$cmd   = "cat -n";
		next;
	}
	if (/^-v$/ || /^--verbose$/) {
		$verbose++;
		next;
	}

	if (/^-\?$/ || /^-h$/ || /^--help$/) {
		&usage();
		exit(0);
	}
	print "I don't recognize this switch: $_\n";
	&usage();
	exit(1);
}

#
# Verify we have the right number of positional arguments.
#
if ( $#ARGV < 1 || $#ARGV > 2 ) {
	&usage();
	exit(1);
}
$system      = $ARGV[0];
$remote_file = $ARGV[1];

#
# If the system spec was "-" try to figure out where we are. From that
# we might be able to construct a default host.
#
if ( $system eq "-" ) {
	$system   = `/bin/pwd`;
	$system   =~ s/\n//;
	$original =  $system;
	$system   =~ s,^.*/ftp/,,;
	$system   =~ s,/.*$,,;
	die("Could not determine system given path \"$original\".\n")
		if $system eq "";
	print(STDERR "Derived system is \"$system\".\n") if $verbose;
}

#
# Either take the optional third argument or construct it from the second.
#

if ( "$remote_file" eq "" ) {
	print(STDERR "Must specify a non-null file name.\n");
	exit(1);
}
if ( $#ARGV == 2 ) {
	$local_file = $ARGV[2];
	$explicit   = 1;
} else {
	$local_file =  $remote_file;
	$local_file =~ s,/+$,,;
	$local_file =~ s,.*/,,;
	$explicit   =  0;

	print(STDERR "Derived local path is \"$local_file\".\n") if $verbose;
	if ( "$local_file" eq "" ) {
		print(STDERR "Unable to construct a local filename.\n");
		exit(1);
	}
}


#
# Make the path specifications safe even when they contain spaces.
#
$safe_remote =  $remote_file;
$safe_local  =  $local_file;
$safe_remote =~ s/(.*)/"$1"/ if $safe_remote =~ /\s/;
$safe_local  =~ s/(.*)/"$1"/ if $safe_local  =~ /\s/;

#
# If a delay was asked for run the command later.
#
if ( $delay_time ne "" ) {
	$me  =  $0;
	$me .= " --verbose"		if $verbose;
	$me .= " --debug"		if $debug;
	$me .= " $system $safe_remote";
	$me .= " $safe_local"		if $explicit;
	$at  = "at $delay_time";
	print(STDERR "At $delay_time the following command will be run:\n");
	print(STDERR "  $me\n");
	if ( $debug ) {
		print(STDERR "Skipping command in debug mode.\n");
		exit(0);
	}
	open(CMD, "|$at") || die("Could not run command ($at). $!\n");
	print(CMD $me);
	close(CMD);
	exit(0);
}

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
	get $safe_remote $safe_local
	bye
";

#
# Run the batch ftp command.
#
print(STDERR "Running command ($cmd).\n") if $verbose;
open(CMD, "|$cmd") || die("Could not start command ($cmd). $!\n");
print CMD $template;
close(CMD);


# Note whether or not the local file was obtained.
#
if ( -f $local_file ) {
	print("Obtained \"$local_file\" from $system.\n");
} else {
	$pwd=`pwd`;
	chop($pwd);
	@time = localtime($time);
	$next = sprintf("%2d:%02d", $time[2], $time[1]);

	$sep  = "\t\\\n\t    ";
	$cmd  = "$0";
	$cmd .= "$sep--at $next";
	$cmd .= "$sep$system";
	$cmd .= "$sep$safe_remote";
	$cmd .= "$sep$safe_local"	if $explicit;

	print("
Unable to obtained \"$local_file\" from $system.
To try again the following command might be used:

cd $pwd;
$cmd
");
}
