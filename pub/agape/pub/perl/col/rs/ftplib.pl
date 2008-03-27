#
#   This is a set of ftp library routines using chat2.pl
# 
#   Return code information taken from RFC 959

#   Written by Gene Spafford  <spaf@cs.purdue.edu>
#       Last update: 10 April 92,   Version 0.9
#

#
#   Most of these routines communicate over an open ftp channel
#   The channel is opened with the "ftp'open" call.
#

package ftp;
require "chat2.pl";
require "syscall.ph";


###########################################################################
#
#  The following are the variables local to this package.
#  I declare them all up front so I can remember what I called 'em. :-)
#
###########################################################################

LOCAL_VARS: {	
    $Control;
    $Data_handle;
    $Host;
    $Myhost = "\0" x 65;
    (syscall(&SYS_gethostname, $Myhost, 65) == 0) || 
	die "Cannot 'gethostname' of local machine (in ftplib)\n";
    $Myhost =~ s/\0*$//;
    $NeedsCleanup;
    $NeedsClose;
    $ftp_error;
    $ftp_matched;
    $ftp_trans_flag;
    @ftp_list;

    local(@tmp) = getservbyname("ftp", "tcp");
    ($FTP = $tmp[2]) || 
	die "Unable to get service number for 'ftp' (in ftplib)!\n";

    @std_actions = (
	    'TIMEOUT',
	    q($ftp_error = "Connection timed out for $Host!\n"; undef),
	    'EOF', 
	    q($ftp_error = "Connection to $Host timed out unexpectedly!\n"; undef)
    );

    @sigs = ('INT', 'HUP', 'TERM', 'QUIT');  # sigs we'll catch & terminate on
}



###########################################################################
#
#  The following are intended to be the user-callable routines.
#  Each of these does one of the ftp keyword functions.
#
###########################################################################

sub error { ## Public
    $ftp_error;
}
  
#######################################################

#   cd up a directory level

sub cdup { ## Public
    &do_ftp_cmd(200, "cdup");
}

#######################################################

# close an open ftp connection

sub close { ## Public
    return unless $NeedsClose;
    &do_ftp_cmd(221, "quit");
    &chat'close($Control);
    undef $NeedsClose;
    &do_ftp_signals(0);
}

#######################################################

# change remote directory

sub cwd { ## Public
    &do_ftp_cmd(250, "cwd", @_);
}
  
#######################################################

#  delete a remote file

sub delete { ## Public
     &do_ftp_cmd(250, "dele", @_); 
}

#######################################################

#  get a directory listing of remote directory ("ls -l")

sub dir { ## Public
    &do_ftp_listing("list", @_);
}

#######################################################

#  get a remote file to a local file
#    get(remote[, local])

sub get { ## Public
    local($remote, $local) = @_;
    ($local = $remote) unless $local;

    unless (open(DFILE, ">$local")) {
	$ftp_error =  "Open of local file $local failed: $!";
	return undef;
    } else {
	$NeedsCleanup = $local;
    }

    return undef unless &do_open_dport; 	# Open a data channel
    unless (&do_ftp_cmd(150, "retr $remote")) {
	$ftp_error .= "\nFile $remote not fetched from $Host\n";
	close DFILE;
	unlink $local;
	undef $NeedsCleanup;
	return;
    }

    $ftp_trans_flag = 0;

    do {
	&chat'expect($Data_handle, 60,
		     '.|\n', q{print DFILE ($chat'thisbuf) ||
			($ftp_trans_flag = 3); undef $chat'S},
		     'EOF',  '$ftp_trans_flag = 1',
		     'TIMEOUT', '$ftp_trans_flag = 2');
    } until $ftp_trans_flag;

    close DFILE;
    &chat'close($Data_handle);		# Close the data channel

    undef $NeedsCleanup;
    if ($ftp_trans_flag > 1) {
	unlink $local;
	$ftp_error = "Unexpected " . ($ftp_trans_flag == 2 ? "timeout" :
		($ftp_trans_flag != 3 ? "failure" : "local write failure")) .
                " getting $remote\n";
    }
    
    &do_ftp_cmd(226);
}

#######################################################

#  Do a simple name list ("ls")

sub list { ## Public
    &do_ftp_listing("nlst", @_);
}

#######################################################

#   Make a remote directory

sub mkdir { ## Public
    &do_ftp_cmd(257, "mkd", @_);
}

#######################################################

#  Open an ftp connection to remote host

sub open {  ## Public
    if ($NeedsClose) {
	$ftp_error = "Connection still open to $Host!";
	return undef;
    }

    $Host = shift(@_);
    local($User, $Password, $Acct) = @_;
    $User = "anonymous" unless $User;
    $Password = "-" . $main'ENV{'USER'} . "@$Myhost" unless $Password;
    $ftp_error = '';

    unless($Control = &chat'open_port($Host, $FTP)) {
	$ftp_error = "Unable to connect to $Host ftp port: $!";
	return undef;
    }

    unless(&chat'expect($Control, 60,
		        "^220 .*\n",	 "1",
		        "^\d\d\d .*\n",  "undef")) {
	$ftp_error = "Error establishing control connection to $Host";
        &chat'close($Control);
	return undef;
    }
    &do_ftp_signals($NeedsClose = 1);

    unless (&do_ftp_cmd(331, "user $User")) {
	$ftp_error .= "\nUser command failed establishing connection to $Host";
	return undef;
    }

    unless (&do_ftp_cmd("(230|332|202)", "pass $Password")) {
	$ftp_error .= "\nPassword command failed establishing connection to $Host";
	return undef;
    }

    return 1 unless $Acct;

    unless (&do_ftp_cmd("(230|202)", "pass $Password")) {
	$ftp_error .= "\nAcct command failed establishing connection to $Host";
	return undef;
    }
    1;
}

#######################################################

#  Get name of current remote directory

sub pwd { ## Public
    if (&do_ftp_cmd(257, "pwd")) {
	$ftp_matched =~ m/^257 (.+)\r?\n/;
	$1;
    } else {
	undef;
    }    
}

#######################################################

#  Rename a remote file

sub rename { ## Public
    local($from, $to) = @_;

    &do_ftp_cmd(350, "rnfr $from") && &do_ftp_cmd(250, "rnto $to");
}

#######################################################

#  Set transfer type

sub type { ## Public
    &do_ftp_cmd(200, "type", @_); 
}


###########################################################################
#
#  The following are intended to be utility routines used only locally.
#  Users should not call these directly.
#
###########################################################################

sub do_ftp_cmd {  ## Private
    local($okay, @commands, $val) = @_;

    $commands[0] && 
	&chat'print($Control, join(" ", @commands), "\r\n");

    &chat'expect($Control, 60, 
		 "^$okay .*\\n",        '$ftp_matched = $&; 1',
		 '^(\d)\d\d .*\\n', '($String = $&) =~ y/\r\n//d; 
		     $ftp_error = qq{Unexpected reply for ' .
		     "@commands" . ': $String}; 
		     $1 > 3 ? undef : 1',
		 @std_actions
		);
}

#######################################################

sub do_ftp_listing { ## Private
    local(@lcmd) = @_;
    @ftp_list = ();
    $ftp_trans_flag = 0;

    return undef unless &do_open_dport;

    return undef unless &do_ftp_cmd(150, @lcmd);
    do {			#  Following is grotty, but chat2 makes us do it
        &chat'expect($Data_handle, 30,
		"(.*)\r?\n",    'push(@ftp_list, $1)',
		"EOF",     '$ftp_trans_flag = 1');
    } until $ftp_trans_flag;

    &chat'close($Data_handle);
    return undef unless &do_ftp_cmd(226);

    grep(y/\r\n//d, @ftp_list);
    @ftp_list;
}  

#######################################################

sub do_open_dport { ## Private
    local(@foo, $port) = &chat'open_listen;
    ($port, $Data_handle) = splice(@foo, 4, 2);

    unless ($Data_handle) {
	$ftp_error =  "Unable to open data port: $!";
	return undef;
    }

    push(@foo, $port >> 8, $port & 0xff);
    local($myhost) = (join(',', @foo));
    
    &do_ftp_cmd(200, "port $myhost");
}

#######################################################
#
#  To cleanup after a problem
#

sub do_ftp_abort {
    die unless $NeedsClose;

    &chat'print($Control, "abor", "\r\n");
    &chat'close($Data_handle);
    &chat'expect($Control, 10, '.', undef);
    &chat'close($Control);

    close DFILE;
    unlink($NeedsCleanup) if $NeedsCleanup;
    die;
}

#######################################################
#
#  To set signals to do the abort properly
#

sub do_ftp_signals {
    local($flag, $sig) = @_;

    local ($old, $new) = ('DEFAULT', "ftp'do_ftp_abort");
    $flag || (($old, $new) = ($new, $old));
    foreach $sig (@sigs) {
	($SIG{$sig} == $old) && ($SIG{$sig} = $new);
    }
}

1;
