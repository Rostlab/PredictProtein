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
# Summary of ftpmget:
#
#	Obtain a set of files via ftp from a remote system. Anonymous
#	ftp is used. Can be asked to delay the command until a later
#	time. Such a request will result in "at" being used.
#
# History:
#
#	1993.06.14	Initial implementation.
#
#	1993.06.15	Changed so that if a file contains white space
#			it is obtained with get instead of mget.
#
#	1993.06.30	Added --at option to allow delayed operation.
#
# Examples:
#
#	ftpmget hrd769.brooks.af.mil pub/FAQ FAQ_07 FAQ_09
#
#	cd ~/ftp/hrd769.brooks.af.mil
#	ftpmget - pub/FAQ FAQ_07 FAQ_09
#
#	ftpmget hrd769.brooks.af.mil pub/FAQ - << EndOfList
#		FAQ_07
#		FAQ_09
#	EndOfList
#
#############################################################################

$zero =  $0;
$zero =~ s,.*/,,;

sub usage {

	print <<EOS;
Usage: $zero [options] system remote_dir file1 [... fileN]
 or
       $zero [options] system remote_dir -

    --			 Stop command line processing.
    -a or --at time	 At the given time, which should be in hh:mm format,
			 run the $0 command.
    -d or --debug	 Do not run the actual ftp command, use cat instead.
    -v or --verbose	 Enable the verbose status message.
    -? or -h or --help	 Print this usage statement.

    If the system is "-" try to determine the remote system from
    the current path.

    If a "-" is given instead of a list of files the list is read
    from standard input.
EOS
}

##############################################################################
#
#	Set the default values.
#

$verbose  = 0;
$debug	  = 0;
$cmd	  = "ftp -n";	# change "ftp -n" to "cat -n" for testing.
$time	  = time;	# Get the time so we can recreate an "at"
			# command if need be.
$pwd      =`/bin/pwd`; chop($pwd);

##############################################################################
#
#	Process the command line.
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

##############################################################################
#
# Verify the positional arguments
#
if ( $#ARGV < 2 ) {
	&usage();
	exit(1);
}

$system	     = $ARGV[0];
$remote_dir  = $ARGV[1];

##############################################################################
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

##############################################################################
#
#	Get the list of requested files. Either take the files from
#	the command line or from stdin.
#
if ( $ARGV[2] ne "-" ) {
	for( $argc = 2; $argc <= $#ARGV; $argc++) {
		$file =	 $ARGV[$argc];
		push(@files, $file);
	}
} else {
	while(<STDIN>) {
		chop;
		$file =	 $_;
		$file =~ s/^\s+//;		# leading white space
		$file =~ s/\s+$//;		# trailing white space
		$file =~ s/^"(.*)"$/$1/;	# Remove enclosing quotes
		push(@files, $file);
	}
}

#
# Make spaces safe for all mankind. N. Armstrong.
#
foreach $file (@files) {
	next if $file eq "";			# skip empty names
	$file =~ s/(.*)/"$1"/ if $file =~ /\s/; # add quotes if need be.
	push(@tmp, $file);
}
@files = @tmp;
undef	 @tmp;

##############################################################################
#
#	If a delay was asked for run the command later.
#

if ( $delay_time ne "" ) {
	$me  =	$0;
	$me .= " --verbose"		if $verbose;
	$me .= " --debug"		if $debug;
	$me .= " $system $remote_dir - << End_Of_List\n";
	foreach $file (@files) {
		$me .= "\t$file\n";
	}
	$me .= "End_Of_List\n";

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

##############################################################################
#
#	Build the batch ftp command.
#

$user	   = (getpwuid($<))[0]; # safe when run from "at".
$localhost = `hostname`;
	     chop($localhost);
if ( $localhost !~ /\./ ) {
	#
	# If the host name does not have '.' notation try to
	# get an alias. We then hope it is in domain name notation.
	#
	@fullhost  = gethostbyname($localhost);
	$localhost = $fullhost[1] if $fullhost[1] ne "";
}
$template =
"    open $system
    user anonymous ${zero}4$user@$localhost
    bin
    prompt
    cd $remote_dir
";
foreach $file (@files) {
	if ( $file =~ /\s/ ) {
		push(@space_files, $file);
		next;
	}
	if ( length($line) + length($file) + 1 > 75) {
		$template .= sprintf("$line\n");
		$line = "";
	}
	$line  = "    mget" if $line eq "";
	$line .= " $file";
}
$template .= "$line\n";
foreach $file (@space_files) {
	$template .= "	  get $file\n";
}
$template .= "$bye\n";

##############################################################################
#
#	Run the batch ftp command.
#

open(CMD, "|$cmd") || die("Could not start command ($cmd). $!\n");
print CMD $template;
close(CMD);

##############################################################################
#
#	Report whether or not the files were obtained.
#

print("\nReport for file transfers from $system.\n");
print("  Remote directory \"$remote_dir\".\n");
print("  Local directory \"$pwd\".\n");
foreach $file (@files) {
	if ( -f $file ) {
		print("    Obtained \"$file\".\n");
		next;
	}

	if ( $file =~ /^".*"$/ ) {
		$file =~ s/^"(.*)"$/$1/;
		if ( -f $file ) {
			print("    Obtained \"$file\".\n");
			next;
		}
	}
	push(@again, $file);
}

##############################################################################
#
#	If there was a problem getting all the files print out a command
#	that can try again later.
#

if ( $#again >= $[ ) {
	@time = localtime($time);
	$next = sprintf("%2d:%02d", $time[2], $time[1]);

	print <<EOS;

Unable to obtained some files from $system.
To try again the following command might be used:

cd $pwd;
$0 --at $next $system $remote_dir - << End_Of_List
EOS

	foreach $file (@again) {
		print("	   $file\n");
	}
	print("End_Of_List\n");
}
