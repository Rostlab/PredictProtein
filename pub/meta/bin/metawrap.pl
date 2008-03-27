#!/usr/local/bin/perl -w

#the MetaServer [w]rapper
#basic responsibilies
#1. identify incoming messages (request/result)
#2. update request logs
#3. request: who requests? which service? input? (input validation is done in the handlers)
#4. distribute to handlers

$\ = "\n";
#$dbg = 1;
$true = 1;
$false = 0;
select(STDERR);

############################################################
# establish the correct output channels for messages and debug info
#

#open(MSG,"> msg.log");
#$msglogunit = MSG;
$msglogunit = STDERR; #default messagelog is STDERR (not buffered)

if(0) {
    open(DBG,"> /dev/null");
    $dbglogunit = DBG;
} else {
    $dbglogunit = STDERR; #default debug log is STDERR
}
#
############################################################

############################################################
#
#  INITIALIZATION

#which mail program to use
$mailcmd = "/usr/sbin/Mail";

if(!(-x $mailcmd)) {
    &msglog("mail executable missing");
    die ("mail executable missing");
}

#sendmail for the massaged backup mail messages
# -i: ignores dots on a line by themselves
$sendmail = "/usr/lib/sendmail";
$sendmailopts = "-i";
if(!(-x $sendmail)) {
    &msglog("sendmail executable missing");
    die ("sendmail executable missing");
}


#the program that generates temporary filenames
$tmpnamcmd = "/home/meta/server/bin/tmpnam.exe";
if(!(-x $tmpnamcmd)) {
    &msglog("tmpnamcmd executable missing");
    die ("tmpnamcmd executable missing");
}

#services we know:
#@services_available = ('netoglyc','chlorop','signalp','tmhmm',
#		       'pssm','genthreader','memsat','psipred','basic','jpred');

@services_available = ('netoglyc','chlorop','signalp','tmhmm',
		       'pssm','jpred');

#
############################################################


############################################################
#cache the message (and determine whether this is a request or a result)
#
#@msg=<STDIN>; #the quick way
@msg = ();
$lrequest=$false;
while(<STDIN>) {
    push @msg, $_;
    if($_ =~ /META-REQUEST/) {
	$lrequest = $true;
    }
}

if($lrequest) {
    &msglog('received meta-request');
    &handle_request(@msg);
}
else {
    &dbglog('received result from service');
}
############################################################

&msglog('METAWRAP EXIT');
exit(0);




############################################################
#handle incoming request for services
#msg: is assumed to be the global message
sub handle_request {
    my $user;
    my $service;

    $seqstart = $false;
    @rawseq = ();
    $options = "";
#we use foreach because while can cause problems on WIN32
  LINE:    foreach ( @msg ) {
      chomp;
      $line=$_;
      print $_;
      @temp = split(/::/,$line);
      if(!defined($temp[0])) {next LINE;}
#	if($line =~ /user/) {
      if($temp[0] eq "user" ) {
	  $user = $temp[1];
	  &dbglog("user: $user");
      }
      
      if($temp[0] eq "service") {
	  $service = $temp[1];
	  &dbglog("service: $service");
      }

#options are give as one string of name/value pairs
      if($temp[0] eq "options") {
	  $options .= $temp[1];
	  $options .= "&";
	  &dbglog('option string: ',$options);
      }
      
#the sequence has to be the last item in the request
#once we have the 'sequence' token we the rest of the message is
#interpreted as the sequence (or multiple sequences in a later implement)
      
      if($seqstart) {
	  push @rawseq, $line;
      }
      
      if($temp[0] eq "sequence") {
	  $seqstart = $true;
	  &dbglog('FOUND SEQUENCE START');
	  push @rawseq, $temp[1];
      }

      if($temp[0] eq "seqname") {
	  $seqname = $temp[1];
	  &dbglog('seqname: ',$seqname);
      }
      
  }
    if(substr($options,length($options)-1,1) eq "&") {
	chop($options);
	&dbglog('option string: ',$options);
    }
    &dbglog('sequence: ',@rawseq);
    
#check inconsistencies in the input
#parse the sequence (we prepare two different formats)
#1. single sequence (one letter code)
#2. FASTA format
    
    &dbglog('REQUEST HANDLER');
#do we have a (reasoable) user name?
    if(length($user) > 0 && $user =~ /\@/) {
#can we actually handle this service?
	if(grep /$service/, @services_available) {
	    &dbglog("KNOWN SERVICE: $service");
	    &dbglog("sequence: @rawseq");
	    &$service($user,$options,$seqname,@rawseq);
	}
	else {
	    &dbglog("UNKNOWN SERVICE REQUESTED: service: $service");
	}
    } 
    else {
	&dbglog("MISSING USER NAME: user: $user");
    }
}
############################################################


#the standard message log
sub msglog {
    print $msglogunit "<MSG>",@_,"</MSG>";
}

#the debug message log
sub dbglog {
    print $dbglogunit "<DBG>",@_,"</DBG>";
}


############################################################
#
#   SEQUENCE HANDLING
#
#   parse input sequence (raw data) and produce
#   * single sequence (first sequence in a multiple sequence file)
#   * multiple sequence file in FASTA format
#   * additional formats if required by services
#
#   input: 
#   * sequence format to be returned ( 1=single sequence )
#   * raw sequence information (no assumed formatting)
# 
#   output:
#   1. single sequence (one letter code)
#   2. FASTA format (single sequence)

#  UNDONE:
#  more consistent sequence handling (means: splitting multiple
#  sequence into separate single sequences, generation of FASTA input)
sub parse_seq {

    &dbglog('PARSE_SEQ');
    my($returntype) = shift @_;
    my(@rawsequence) = @_;
    my($retseq) = "";

    &dbglog('returntype: ',$returntype);
    &dbglog('raw sequence: ',@rawsequence);
    
#if the we return a single sequence -> delete all whitespace
    if($returntype == 1) {
	&dbglog('SINGLE SEQUENCE');
	$tempseq = join "", @rawsequence;
	$tempseq =~ tr /a-z/A-Z/;
	for($i=0;$i<=length($tempseq);$i++) {
	    $char = substr($tempseq,$i,1);
	    if($char =~ /\S/) {
		$retseq .= $char;
	    }
	}
	&dbglog('PARSE_SEQ...DONE');
	return $retseq;
    }


    if($returntype == 2) {
	&dbglog('SINGLE SEQUENCE FASTA FORMAT');
	$retseq = ">FASTA format\n";
	$tempseq = join "", @rawsequence;
	$tempseq =~ tr /a-z/A-Z/;
	for($i=0;$i<=length($tempseq);$i++) {
	    $char = substr($tempseq,$i,1);
	    if($char =~ /\S/) {
		$retseq .= $char;
	    }
	}
	&dbglog('New Sequence: ',$retseq);
	&dbglog('PARSE_SEQ...DONE');
	return $retseq;
    }

    &dbglog('PARSE_SEQ...DONE');
#    return @rawsequence;
    
    
}
############################################################



#   THE ACTUAL SERVICE HANDLERS
#
#
############################################################
#
#   NETOGLYC
#
sub netoglyc {

    &dbglog("NETOGLYC SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/netoglyc.cgi";
#    my($serveraddr) = "http://genome.cbs.dtu.dk/htbin/nph-webface";
    &dbglog('NETOGLYC serveraddress: ',$serveraddr);



#backup mail service if available
    my($servermail) = "meta\@dodo.chem.columbia.edu";
#    my($servermail) = "netOglyc\@cbs.dtu.dk";
    &dbglog('NETOGLYC mailserveraddress: ',$servermail);

#this service has both an email and a WWW interface
#we try the WWW interface first (easier for us because we can 
#finish the handle the request in one step

#if we time out on the connection (the computations themselves
#seem to be pretty short) the problem is probably somewhere else
#-> send email as backup 

#prepare the input sequence (netoglyc accepts
#single sequences by default)

    my($seq) = &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);

#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast
#email backup is still available, so ...

#	$ua->timeout(1);
	$ua->timeout(300);
	

	#assemble the form data
	#configfile
	$data = "configfile=/home/genome2/www/Public_html/services/NetOGlyc-2.0/NetOGlyc.cf";
	#any options as preformatted string
	if(length($options) > 0) {
	    $data .= "&".$options;
	}
	#sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
	#sequence data
	print "SEQUENCE: ", $seq;
	$data .= "&"."SEQ=";
	$data .= $seq;

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	
	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-netoglyc',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);

	    &mail($user,'meta-netoglyc-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('NETOGLYC server timed out ... ');
	}
    }
    if($timeout) {
	&msglog('NETOGLYC server timed out repeatedly ... trying email');
#to avoid having to receive the message again we
#can try to use sendmails -F and -f options we would allow
#us to send the mail directly to the recipient if all
#the target server does is respond to incoming mail	
	
#we also have to massage the user name (escape the @)
	$newuser = &massage_email($user);
	&dbglog('new email name: ',$newuser);
	
	open(MAIL,"| $sendmail $sendmailopts -F$newuser $servermail") || die "cannot send backup mail";
	print MAIL $seq;
	print MAIL ".";
	print MAIL "\n";
	close(MAIL);
	&dbglog('netoglyc backup mail send');
    }
    
    &dbglog("NETOGLYC SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   CHLOROP
#
sub chlorop {

    &dbglog("CHLOROP SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);


#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/chlorop.cgi";
#    my($serveraddr) = "http://genome.cbs.dtu.dk/htbin/nph-webface";

    &dbglog('CHLOROP serveraddress: ',$serveraddr);

#submission procedure similar to netoglyc
#prepare the input sequence (chlorop accepts
#single sequences by default)
#! note that chlorop wants between 100-150 residues

    my($seq) = &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    if(length($seq) > 150) {
	$seq = substr($seq,0,150);
	&dbglog('CHLOROP sequence truncated');
	&dbglog('new sequence: ',$seq);
	&dbglog('length of new sequence: ',length($seq));
    }

#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast
#email backup is still available, so ...
	$ua->timeout(300);
	

	#assemble the form data
	#configfile
	$data = "configfile=/home/genome2/www/Public_html/services/chlorp-0.0/chlorop.cf";

#add this point ChloroP does not accept options
#	#any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

	#sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
	#sequence data
	print "SEQUENCE: ", $seq;
	$data .= "&"."SEQ=";
	$data .= $seq;

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	
	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-chlorop',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);

	    &mail($user,'meta-chlorop-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('CHLOROP server timed out ... ');
	}
    }
    if($timeout) {
	&msglog('CHLOROP server timed out repeatedly ... trying email');
    }
    
    &dbglog("CHLOROP SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   SignalP
#
sub signalp {

    &dbglog("SIGNALP SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/signalp.cgi";
#    my($serveraddr) = "http://genome.cbs.dtu.dk/htbin/nph-webface";
    &dbglog('SIGNALP serveraddress: ',$serveraddr);


#backup mail service if available
    my($servermail) = "meta\@dodo.cpmc.columbia.edu";
#    my($servermail) = "signalp\@cbs.dtu.dk";
    &dbglog('SIGNALP mailserveraddress: ',$servermail);

#this service has both an email and a WWW interface
#we try the WWW interface first (easier for us because we can 
#finish the handle the request in one step

#if we time out on the connection (the computations themselves
#seem to be pretty short) the problem is probably somewhere else
#-> send email as backup 

#prepare the input sequence (signalp accepts
#single sequences by default)

    my($seq) = &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);

#note that SignalP wants between 50-70 N-terminal residues 
    if(length($seq) > 70) {
	$seq = substr($seq,0,70);
	&dbglog('CHLOROP sequence truncated');
	&dbglog('new sequence: ',$seq);
	&dbglog('length of new sequence: ',length($seq));
    }


#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast
#email backup is still available, so ...

#	$ua->timeout(1);
	$ua->timeout(300);
	

	#assemble the form data
	#configfile
	$data = "configfile=/home/genome2/www/Public_html/services/SignalP/signalp.cf";
	#any options as preformatted string
	if(length($options) > 0) {
	    $data .= "&".$options;
	}
	#sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
	#sequence data
	print "SEQUENCE: ", $seq;
	$data .= "&"."SEQ=";
	$data .= $seq;

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	
	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-signalp',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);

	    &mail($user,'meta-signalp-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('SIGNALP server timed out ... ');
	}
    }
    if($timeout) {
	&msglog('SIGNALP server timed out repeatedly ... trying email');
#to avoid having to receive the message again we
#can try to use sendmails -F and -f options we would allow
#us to send the mail directly to the recipient if all
#the target server does is respond to incoming mail	
	
#we also have to massage the user name (escape the @)
	$newuser = &massage_email($user);
	&dbglog('new email name: ',$newuser);
	
	open(MAIL,"| $sendmail $sendmailopts -F$newuser $servermail") || die "cannot send backup mail";
	print MAIL $seq;
	print MAIL ".";
	print MAIL "\n";
	close(MAIL);
	&dbglog('signalp backup mail send');
    }
    
    &dbglog("SIGNALP SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   TMHMM
#
sub tmhmm {

    &dbglog("TMHMM SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/tmhmm.cgi";
#    my($serveraddr) = "http://genome.cbs.dtu.dk/htbin/nph-webface";
    &dbglog('TMHMM serveraddress: ',$serveraddr);



#this service has a WWW interface only

#if we time out on the connection (the computations themselves
#seem to be pretty short) the problem is probably somewhere else

#prepare the input sequence (tmhmm accepts
#single sequences in FASTA format by default)

    my($seq) = &parse_seq(2,@rawseq);
#    &dbglog('Single Sequence: ',$seq);

#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast
#email backup is still available, so ...

#	$ua->timeout(1);
	$ua->timeout(300);
	

	#assemble the form data
	#configfile
	$data = "configfile=/home/genome2/www/Public_html/services/TMHMM-1.0/TMHMM.cf";

#not supported options at this point
#	#any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

	#sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
	#sequence data
	print "SEQUENCE: ", $seq;
	$data .= "&"."SEQ=";
	$data .= $seq;

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	
	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-tmhmm',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);

	    &mail($user,'meta-tmhmm-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('TMHMM server timed out ... ');
	}
    }
    if($timeout) {
	&msglog('TMHMM server timed out repeatedly ... trying email');
    }
    &dbglog("TMHMM SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   3D-PSSM
#
sub pssm {

    &dbglog("3D-PSSM SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;
    my($data) = "";

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi";
#    my($serveraddr) = "http://bonsai.lif.icnet.uk/cgi-bin/fold_dir/master.pl";
    &dbglog('PSSM serveraddress: ',$serveraddr);

#this service has a WWW interface only
#by default we will use single sequence letter code
    my($seq) = &parse_seq(2,@rawseq);
#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast

#	$ua->timeout(1);
	$ua->timeout(300);

#NOTE: we supply the default options for now
#for advanced use the script or form assembling the 
#META-REQUEST has to preprocess ALL options


	#assemble the form data
	#any options as preformatted string

	if(length($options) > 0) {
	    $data .= "&".$options;
	}
	else {
	    &dbglog('USING DEFAULT OPTIONS');
	    $data .= "usr-email=";
#	    $newuser = &massage_email($user);
	    $data .= $user;
	    $data .= "&";
	    
	    $data .= "PSSM_TYPE=";
	    $data .= "3DPSSM";
	    $data .= "&"; 

	    $data .= "use_ss=";
	    $data .= "SS";
	    $data .= "&"; 

	    $data .= "prob_ss=";
	    $data .= "YES";
	    $data .= "&"; 

	    $data .= "alignmet=";
	    $data .= "GLOBAL";
	    $data .= "&"; 

	    $data .= "gap=";
	    $data .= "-10";
	    $data .= "&"; 

	    $data .= "extend=";
	    $data .= "-1";
	    $data .= "&"; 

	    $data .= "seq-format=";
	    $data .= "single";
	    $data .= "&"; 

	    $data .= "Radio Button Group=";
	    $data .= "yes";
	    $data .= "&"; 

	}

	#sequence name (ID)
	$data .= "seq-desc=";
	$data .= $seqname;
	$data .= "&"; 
	
	#sequence data
	my($seq) = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq;
	$data .= "sequence=";
	$data .= $seq;
	
#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	


	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-pssm',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);

#we won't send the 'jobs has been placed in the Q' response
#	    &mail($user,'meta-pssm-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('PSSM server timed out ... ');
	}
    }

#now email service available
#    if($timeout) {
#	&msglog('PSSM server timed out repeatedly ... trying email');
#    }

    &dbglog("PSSM SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   GenTHREADER
#
sub genthreader {

    &dbglog("GenTHREADER SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;
    my($data) = "";

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi";
#    my($serveraddr) = "http://137.205.156.147/cgi-bin/psipred/psipred.cgi";
    &dbglog('GenTHREADER serveraddress: ',$serveraddr);

#this service has a WWW interface only
#by default we will use single sequence letter code
    my($seq) = &parse_seq(2,@rawseq);
#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast

#	$ua->timeout(1);
	$ua->timeout(300);

#NOTE: we supply the default options for now
#for advanced use the script or form assembling the 
#META-REQUEST has to preprocess ALL options


	#assemble the form data
	#any options as preformatted string

	#user email address
	$data .= "Email=";
	$data .= $user;
	$data .= "&";

	#set the password to EMPTY
	$data .= "Password=";
	$data .= "";
	$data .= "&";

	#sequence name
	$data .= "Subject=";
	$data .= $seqname;
	$data .= "&";

	#sequence data
	my($seq) = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq;
	$data .= "Sequence=";
	$data .= $seq;
	$data .= "&";


	#name="Program" value="genthreader" selects standard GenThreader
	$data .= "Program=";
	$data .= "genthreader";
	$data .= "&";

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	


	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-genthreader',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);


	    &mail($user,'meta-genthreader-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('GenTHREADER server timed out ... ');
	}
    }

#now email service available
#    if($timeout) {
#	&msglog('GenTHREADER server timed out repeatedly ... trying email');
#    }

    &dbglog("GenTHREADER SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   MEMSAT (basically equivalent to GenTHREADER - only one keyword differs)
#
sub memsat {

    &dbglog("MEMSAT SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;
    my($data) = "";

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi";
#    my($serveraddr) = "http://137.205.156.147/cgi-bin/psipred/psipred.cgi";
    &dbglog('MEMSAT serveraddress: ',$serveraddr);

#this service has a WWW interface only
#by default we will use single sequence letter code
    my($seq) = &parse_seq(2,@rawseq);
#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast

#	$ua->timeout(1);
	$ua->timeout(300);

#NOTE: we supply the default options for now
#for advanced use the script or form assembling the 
#META-REQUEST has to preprocess ALL options


	#assemble the form data
	#any options as preformatted string

	#user email address
	$data .= "Email=";
	$data .= $user;
	$data .= "&";

	#set the password to EMPTY
	$data .= "Password=";
	$data .= "";
	$data .= "&";

	#sequence name
	$data .= "Subject=";
	$data .= $seqname;
	$data .= "&";

	#sequence data
	my($seq) = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq;
	$data .= "Sequence=";
	$data .= $seq;
	$data .= "&";


	#name="Program" value="memsat" selects standard MEMSAT
	$data .= "Program=";
	$data .= "memsat";
	$data .= "&";

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	


	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-MEMSAT',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);


	    &mail($user,'meta-MEMSAT-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('MEMSAT server timed out ... ');
	}
    }

#now email service available
#    if($timeout) {
#	&msglog('MEMSAT server timed out repeatedly ... trying email');
#    }

    &dbglog("MEMSAT SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   PSIpred (basically equivalent to GenTHREADER - only one keyword differs)
#
sub psipred {

    &dbglog("PSIpred SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;
    my($data) = "";

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi";
#    my($serveraddr) = "http://137.205.156.147/cgi-bin/psipred/psipred.cgi";
    &dbglog('PSIpred serveraddress: ',$serveraddr);

#this service has a WWW interface only
#by default we will use single sequence letter code
    my($seq) = &parse_seq(2,@rawseq);
#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast

#	$ua->timeout(1);
	$ua->timeout(300);

#NOTE: we supply the default options for now
#for advanced use the script or form assembling the 
#META-REQUEST has to preprocess ALL options


	#assemble the form data
	#any options as preformatted string

	#user email address
	$data .= "Email=";
	$data .= $user;
	$data .= "&";

	#set the password to EMPTY
	$data .= "Password=";
	$data .= "";
	$data .= "&";

	#sequence name
	$data .= "Subject=";
	$data .= $seqname;
	$data .= "&";

	#sequence data
	my($seq) = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq;
	$data .= "Sequence=";
	$data .= $seq;
	$data .= "&";


	#name="Program" value="psipred" selects standard PSIpred
	$data .= "Program=";
	$data .= "psipred";
	$data .= "&";

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	


	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-PSIpred',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);


	    &mail($user,'meta-PSIpred-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('PSIpred server timed out ... ');
	}
    }

#now email service available
#    if($timeout) {
#	&msglog('PSIpred server timed out repeatedly ... trying email');
#    }

    &dbglog("PSIpred SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   BASIC: Genome Analysis @ http://cape6.scripps.edu/leszek/
#
sub basic {

    &dbglog("BASIC SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;
    my($data) = "";

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi";
#    my($serveraddr) = "http://cape6.scripps.edu/leszek/genome/cgi-bin/comp.pl";
    &dbglog('BASIC serveraddress: ',$serveraddr);

#this service has a WWW interface only (uses GET method though)
#by default we will use single sequence letter code
    my($seq) = &parse_seq(2,@rawseq);
#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast

#	$ua->timeout(1);
	$ua->timeout(300);

#NOTE: we supply the default options for now
#for advanced use the script or form assembling the 
#META-REQUEST has to preprocess ALL options


	#assemble the form data
	#any options as preformatted string


	#sequence data
	my($seq) = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq;
	$data .= "seq=";
	$data .= $seq;
	$data .= "&";

	#user email address
	$data .= "email=";
	$data .= $user;
	$data .= "&";

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);
	

#the formatted query string has to be attached to
#the URL for GET requests
	$serveraddr .= "?".$data;
	&dbglog('GET REQUEST URL: ',$serveraddr);

	# Create a request
#	my $req = new HTTP::Request POST => $serveraddr;
	my $req = new HTTP::Request GET => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
	
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-basic',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#	    open(TMP,");
#	    while(<TMP>) {
#		$string .= $_;
#	    }
#	    close(TMP);


	    &mail($user,'meta-basic-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('BASIC server timed out ... ');
	}
    }

    &dbglog("BASIC SERVICE HANDLER...DONE");
}
############################################################



############################################################
#
#   Jpred: http://circinus.ebi.ac.uk:8081
#
sub jpred {

    &dbglog("JPRED SERVICE HANDLER");
    &dbglog("INPUT");
    my($user) = shift;
    my($options) = shift;
    my($seqname) = shift;
    my($rawseq) = @_;
    my($data) = "";

    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);

#the debug and production serveraddresses
    my($serveraddr) = "http://www.chem.columbia.edu/~volker/cgi-bin/handler.cgi";
#    my($serveraddr) = "http://circinus.ebi.ac.uk:8081/jpred-bin/pred_form";
    &dbglog('JPRED serveraddress: ',$serveraddr);

#this service has a WWW interface only (uses POST method though)
#by default we will use single sequence letter code
    my($seq) = &parse_seq(1,@rawseq);
#first try the net connection
    $try = 0; #to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
#the time out should be something like 5 minutes max for this
#because the computations seem to be pretty fast

#	$ua->timeout(1);
	$ua->timeout(300);

#NOTE: we supply the default options for now
#for advanced use the script or form assembling the 
#META-REQUEST has to preprocess ALL options


	#assemble the form data
	#any options as preformatted string

	#user email address
	$data .= "email=";
	$data .= $user;
	$data .= "&";

	#sequence data
	my($seq) = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq;
	$data .= "seq=";
	$data .= $seq;
	$data .= "&";

	#input data format
	#by default we will use single sequence single letter format
	$data .= "Input=";
	$data .= "seq";
	$data .= "&";

	#users_id is supposed to be a unique string for WHAT?
	$data .= "users_id=";

	if(length($seqname) > 8) {
	    $tmp = substr($seqname,0,8);
	    $data .= $tmp;
	    $data .= "&";
	    &dbglog('sequence name truncated');
	} else {
	    $data .= $seqname;
	    $data .= "&";
	}


	#two other options are possible ('nssp' and 'pdb' which have value 'on'
	#if selected or are missing as keys if turned off)
	#they can both be handled as $options later
	#any options as preformatted string
	if(length($options) > 0) {
	    $data .= $options;
	}
	

	

	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	my $req = new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
    # Pass request to the user agent and get a response back
	my $res = $ua->request($req);
	
  # Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
	    &mail($user,'meta-jpred',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$tmpnamcmd`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content;
	    close(TMP);
	    
	    system("lynx -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

	    &mail($user,'meta-jpred-txt',$string);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('JPRED server timed out ... ');
	}
    }

    &dbglog("JPRED SERVICE HANDLER...DONE");
}
############################################################



############################################################
#
#  SERVICENAME



############################################################



############################################################
#
#  generic mailing routine

sub mail {
    
    my($user) = shift @_;
    my($subject) = shift @_;
    my(@msgbody) = @_;

    &dbglog('MAIL to user: ',$user,' with subject: ',$subject,'\n');

    open(MAIL,"| $mailcmd -s \"$subject\" $user") || die "cannot open MAIL";
    print MAIL @msgbody;
    close(MAIL);
    &dbglog('MAIL...done');

}

############################################################


############################################################
#
#   email address massage (replace @ by \@)

sub massage_email {
    
    my($in) = shift;
    my($out) = "";
    my($char) = "";
    
    &dbglog('input address: ',$in);
    for($i=0;$i<=length($in);$i++) {
	$char = substr($in,$i,1);
	if($char =~ /@/) {
	    $out .= "\\";
	}
	$out .= $char;
    }
    &dbglog('output address: ',$out);
    return $out;

    
}

############################################################
