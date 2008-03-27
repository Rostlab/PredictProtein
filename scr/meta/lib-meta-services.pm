# #!/usr/local/bin/perl -w

############################################################
#
#  TESTALI
sub testali {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="testali";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog($service_name," SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog($service_name,' serveraddress: ',$serveraddr);

    # general notes:
    # submission procedure similar to netoglyc
    # prepare the input sequence (chlorop accepts
    # single sequences by default)
    # ! note that chlorop wants between 100-150 residues

    $seq= &parse_seq("2_saf",@rawseq);
    print "xx after seq=$seq, \n";exit;
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data="";

	# any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

				# sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
				# sequence data
	print "SEQUENCE: ", $seq,"\n";
	$data .= "&"."SEQ=";
	$data .= $seq;

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
#	    &mail($user,'meta-'.$service_name,$res->content);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
#uuencode the html output and attach to mail
	    $seqname=~s/\s+/_/g;
	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
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

#attach the HTML output
	    $string .= "\nAttachment: ";
	    $string .= $uuhtmlname;
	    $string .= "\n\n";
	    foreach $x ( @uuhtml ) {
		$string .= $x;
	    }
	    $string .= "\n\n";

	    &mail($user,'meta-'.$service_name,$string);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog($service_name ,'server timed out ... ');
	}
    }
    &msglog($service_name ,' server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog($service_name ," SERVICE HANDLER...DONE");
}				# end of testali 



############################################################
#
#   THE ACTUAL SERVICE HANDLERS
#
############################################################

############################################################
#
#  GENERIC_SERVICE
sub generic_service {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="generic_service";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog($service_name," SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog($service_name,' serveraddress: ',$serveraddr);

    # general notes:
    # submission procedure similar to netoglyc
    # prepare the input sequence (chlorop accepts
    # single sequences by default)
    # ! note that chlorop wants between 100-150 residues

    $seq= &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data="";

	# any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

				# sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
				# sequence data
	print "SEQUENCE: ", $seq,"\n";
	$data .= "&"."SEQ=";
	$data .= $seq;

#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
#	    &mail($user,'meta-'.$service_name,$res->content);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
#uuencode the html output and attach to mail
	    $seqname=~s/\s+/_/g;
	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
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

#attach the HTML output
	    $string .= "\nAttachment: ";
	    $string .= $uuhtmlname;
	    $string .= "\n\n";
	    foreach $x ( @uuhtml ) {
		$string .= $x;
	    }
	    $string .= "\n\n";

	    &mail($user,'meta-'.$service_name,$string);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog($service_name ,'server timed out ... ');
	}
    }
    &msglog($service_name ,' server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog($service_name ," SERVICE HANDLER...DONE");
}				# end of generic_service


############################################################
#
#   BASIC: Genome Analysis @ http://cape6.scripps.edu/leszek/
#
sub basic {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="basic";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("BASIC SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('BASIC serveraddress: ',$serveraddr);

#this service has a WWW interface only (uses GET method though)
#by default we will use single sequence letter code
    $seq = &parse_seq(2,@rawseq);
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
	$seq = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq,"\n";
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
	my $req = new HTTP::Request POST => $serveraddr;
#	my $req = new HTTP::Request GET => $serveraddr;
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
#	    &mail($user,'meta-basic',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
#uuencode the html output and attach to mail
#	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
#	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-basic',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

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
#   CHLOROP
#
sub chlorop {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $service_name= "chlorop";
    $data=         "";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("CHLOROP SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('CHLOROP serveraddress: ',$serveraddr);

#submission procedure similar to netoglyc
#prepare the input sequence (chlorop accepts
#single sequences by default)
#! note that chlorop wants between 100-150 residues

    $seq = &parse_seq(1,@rawseq);
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
	print "SEQUENCE: ", $seq,"\n";
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
#	    &mail($user,'meta-chlorop',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#old mailing routine
#	    &mail($user,'meta-chlorop',$string);

#mail text and HTML output using MUTT
#filelist contains the list of files to attach to 
#the email message
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

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
#  CPHMODELS
sub cphmodels {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="cphmodels";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog($service_name," SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog($service_name,' serveraddress: ',$serveraddr);

    # general notes:
    # submission procedure similar to netoglyc
    # prepare the input sequence (chlorop accepts
    # single sequences by default)
    # ! note that chlorop wants between 100-150 residues

    $seq= &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data = "configfile=/home/genome2/www/Public_html/services/CPHmodels/cm.cf";

				# sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
				# sequence data
	print "SEQUENCE: ", $seq,"\n";
	$data .= "&"."SEQ=";
	$data .= $seq;

	# any options as preformatted string
# 	if(length($options) > 0) {
# 	    $data .= "&".$options;
# 	}


#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
#	    &mail($user,'meta-'.$service_name,$res->content);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
#uuencode the html output and attach to mail
#	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
#	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-'.$service_name,$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);
	    
	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog($service_name ,'server timed out ... ');
	}
    }
    &msglog($service_name ,' server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog($service_name ," SERVICE HANDLER...DONE");
}				# end of cphmodels


############################################################

############################################################
#
#   GenTHREADER
#
sub genthreader {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------

    $data=        "";
    $service_name="genthreader";
    $serveraddr=   $services{"cgi_".$service_name};
    $serveraddr=   $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("GenTHREADER SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('GENTHREADER serveraddress: ',$serveraddr);

#this service has a WWW interface only
#by default we will use single sequence letter code
    $seq = &parse_seq(2,@rawseq);
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
	$seq = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq,"\n";
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
#	    &mail($user,'meta-genthreader',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
#uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-genthreader',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

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
#   Jpred: http://circinus.ebi.ac.uk:8081
#
sub jpred {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="jpred";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("JPRED SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('JPRED serveraddress: ',$serveraddr);

#this service has a WWW interface only (uses POST method though)
#by default we will use single sequence letter code
    $seq = &parse_seq(1,@rawseq);
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
	$seq = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq,"\n";
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
#	    &mail($user,'meta-jpred',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);
# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-jpred',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

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
#   MEMSAT (basically equivalent to GenTHREADER - only one keyword differs)
#
sub memsat {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="memsat";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("MEMSAT SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('MEMSAT serveraddress: ',$serveraddr);

#this service has a WWW interface only
#by default we will use single sequence letter code
    $seq = &parse_seq(2,@rawseq);
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
	$seq = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq,"\n";
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
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";
#	    &mail($user,'meta-MEMSAT',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-MEMSAT',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

#remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('MEMSAT server timed out ... ');
	}
    }

#no email service available
#    if($timeout) {
#	&msglog('MEMSAT server timed out repeatedly ... trying email');
#    }

    &dbglog("MEMSAT SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#   NETOGLYC
#
sub netoglyc {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="netoglyc";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("NETOGLYC SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('NETOGLYC serveraddress: ',$serveraddr);


#backup mail service if available
    $servermail= "netOglyc\@cbs.dtu.dk";
    $servermail= "meta\@dodo.chem.columbia.edu" if ($Ltest);

    &dbglog('NETOGLYC mailserveraddress: ',$servermail);

#this service has both an email and a WWW interface
#we try the WWW interface first (easier for us because we can 
#finish the handle the request in one step

#if we time out on the connection (the computations themselves
#seem to be pretty short) the problem is probably somewhere else
#-> send email as backup 

#prepare the input sequence (netoglyc accepts
#single sequences by default)

    $seq = &parse_seq(1,@rawseq);
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
	print "SEQUENCE: ", $seq,"\n";
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
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";
#	    &mail($user,'meta-netoglyc',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-netoglyc',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

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
	$newuser = &email_massage($user);
	&dbglog('new email name: ',$newuser);
	
	open(MAIL,"| ".$par{"exe_sendmail"}." ".
	     $par{"opt_sendmail"}." -F$newuser $servermail") || 
		 &abort("ERROR netoglyc: cannot send backup mail");
	print MAIL $seq,"\n";
	print MAIL ".","\n";
	print MAIL "\n","\n";
	close(MAIL);
	&dbglog('netoglyc backup mail send');
    }
    
    &dbglog("NETOGLYC SERVICE HANDLER...DONE");
}
############################################################

############################################################
#
#  NETPICO
sub netpico {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="netpico";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog($service_name," SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog($service_name,' serveraddress: |'.$serveraddr.'|');

    # general notes:
    # submission procedure similar to netoglyc
    # prepare the input sequence (chlorop accepts
    # single sequences by default)
    # ! note that chlorop wants between 100-150 residues

    $seq= &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data = "configfile=/home/genome2/www/Public_html/services/NetPicoRNA/netprna.cf";


	# any options as preformatted string
	if(length($options) > 0) {
	    $data .= "&".$options;
	}


				# sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
				# sequence data
	print "SEQUENCE: ", $seq,"\n";
	$data .= "&"."SEQ=";
	$data .= $seq;


#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
#	    &mail($user,'meta-'.$service_name,$res->content);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-'.$service_name,$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog($service_name ,'server timed out ... ');
	}
    }
    &msglog($service_name ,' server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog($service_name ," SERVICE HANDLER...DONE");
}				# end of netpico


############################################################
#
#  NETPHOS
sub netphos {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="netphos";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog($service_name," SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog($service_name,' serveraddress: |'.$serveraddr.'|');

    # general notes:
    # submission procedure similar to netoglyc
    # prepare the input sequence (netphos accepts
    # single sequences by default)

    $seq= &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data = "configfile=/home/genome2/www/Public_html/services/NetPhos/NetPhos.cf";


	# any options as preformatted string
	if(length($options) > 0) {
	    $data .= "&".$options;
	}


				# sequence name (ID)
	$data .= "&"."SEQNAME=";
	$data .= $seqname;
				# sequence data
	print "SEQUENCE: ", $seq,"\n";
	$data .= "&"."SEQ=";
	$data .= $seq;


#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content;
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
#	    &mail($user,'meta-'.$service_name,$res->content);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format;
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-'.$service_name,$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog($service_name ,'server timed out ... ');
	}
    }
    &msglog($service_name ,' server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog($service_name ," SERVICE HANDLER...DONE");
}				# end of netphos

############################################################
#
#   PSIpred (basically equivalent to GenTHREADER - only one keyword differs)
#
sub psipred {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="psipred";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("PSIpred SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('PSIpred serveraddress: ',$serveraddr);

#this service has a WWW interface only
#by default we will use single sequence letter code
    $seq = &parse_seq(2,@rawseq);
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
	$seq = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq,"\n";
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
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";
#	    &mail($user,'meta-PSIpred',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-PSIpred',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

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
#   PSSM (3D-PSSM)
#
sub pssm {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="pssm";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("3D-PSSM SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('PSSM serveraddress: ',$serveraddr);

#this service has a WWW interface only
#by default we will use single sequence letter code
    $seq = &parse_seq(2,@rawseq);
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
#	    $newuser = &email_massage($user);
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
	$seq = &parse_seq(1,@rawseq);
	print "SEQUENCE: ", $seq,"\n";
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
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";
#	    &mail($user,'meta-pssm',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

#we won't send the 'job has been placed in the Q' response
#	    &mail($user,'meta-pssm',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);
	    
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
#   SignalP
#
sub signalp {
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="signalp";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("SIGNALP SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('SIGNALP serveraddress: ',$serveraddr);


#backup mail service if available
    $servermail = "signalp\@cbs.dtu.dk";
    $servermail = "meta\@dodo.cpmc.columbia.edu" if ($Ltest);
    &dbglog('SIGNALP mailserveraddress: ',$servermail);

#this service has both an email and a WWW interface
#we try the WWW interface first (easier for us because we can 
#finish the handle the request in one step

#if we time out on the connection (the computations themselves
#seem to be pretty short) the problem is probably somewhere else
#-> send email as backup 

#prepare the input sequence (signalp accepts
#single sequences by default)

    &dbglog('signalp::sequence: ',@rawseq);

    $seq = &parse_seq(1,@rawseq);
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
	print "SEQUENCE: ", $seq,"\n";
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
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";
#	    &mail($user,'meta-signalp',$res->content);


#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);

# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;
#	    &dbglog('uuhtmlname: ', $uuhtmlname);
#	    &dbglog('uuhtml',@uuhtml);

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# #	    &dbglog('mail string: ',$string);

# 	    &mail($user,'meta-signalp',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);
	    
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
	$newuser = &email_massage($user);
	&dbglog('new email name: ',$newuser);
	
	open(MAIL,"| ".$par{"exe_sendmail"}." ".
	     $par{"opt_sendmail"}." -F$newuser $servermail") || 
		 &abort("ERROR signalp: cannot send backup mail");
	print MAIL $seq,"\n";
	print MAIL ".","\n";
	print MAIL "\n","\n";
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
    my($user,$options,$seqname,@rawseq)=@_;
    my($data,$service_name,$serveraddr,$seq);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="tmhmm";
    $serveraddr=  $services{"cgi_".$service_name};
    $serveraddr=  $services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("TMHMM SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('TMHMM serveraddress: ',$serveraddr);

#this service has a WWW interface only

#if we time out on the connection (the computations themselves
#seem to be pretty short) the problem is probably somewhere else

#prepare the input sequence (tmhmm accepts
#single sequences in FASTA format by default)

    $seq = &parse_seq(2,@rawseq);
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
	print "SEQUENCE: ", $seq,"\n";
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
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";
#	    &mail($user,'meta-tmhmm',$res->content);

#the HTML parser is giving us some problems
#	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-tmhmm',$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);
	    
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
#  DAS
sub das {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="das";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("$service_name SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('$service_name serveraddress: ',$serveraddr);

    $seq= &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data="";

	# add this point DAS does not accept options
#	# any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

				# sequence name (ID)
#	$data .= "&"."SEQNAME=";
#	$data .= $seqname;
				# sequence data
	print "SEQUENCE: ", $seq,"\n";
	$data .= "QUERY ..=";
	$data .= $seq;

	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
 	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;

# we now have to save the HTML document because
#the request object is reused

	    $htmlcontent = $res->content;
	    &dbglog('HTML content: ',$htmlcontent);

#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";

#now we can filter out the links and expand the URLS
#in order for us to get the embedded images wehave to create yet another
#request that targets the gif or ps image

#for extracting the links from the HTML document we use the LinkExtor
#module provided with HTML-Tree-0.51 and up
	    @imgs = ();
	    @href = ();
	    &getlinks($htmlcontent);
	    print "DAS-output","\n";
	    @gifout = grep /output/,@imgs;
	    @psout = grep /output/,@href;
	    print "OUTPUT-IMG: ",@gifout,"\n";
	    print "OUTPUT-PS: ",@psout,"\n";

#to actually retrieve the images we have to prepend the server root
#there might be a method for obtaining the server root of an HTTP request
#for now we'll prepend the server root
#server root is assumed to be the URL up to the last / (slash)
#note also that in the case of DAS we could also use $url_das which points
#to the main server site
#both images could also be handled in one loop 

	    $tmpbasename = `$exe_tmpname`;

#	    my($urlroot) = &geturlroot($serveraddr);
	    my($urlroot) = &getserverroot($serveraddr);

	    chop($urlroot);
	    &dbglog('DAS: URLroot: ',$urlroot);

# 	    &dbglog('gifname:' ,$gifout[0]);
# 	    &dbglog('gif-url: ',$urlroot.$gifout[0]);
# 	    &dbglog('psname:' ,$psout[0]);
# 	    &dbglog('ps-url: ',$urlroot.$psout[0]);

	    my($gifurl) = $urlroot.$gifout[0];
	    my($psurl) = $urlroot.$psout[0];
	    
	    &dbglog('gifname:' ,$gifout[0]);
	    &dbglog('gif-url: ',$gifurl);
	    &dbglog('psname:' ,$psout[0]);
	    &dbglog('ps-url: ',$psurl);


	    $gifreq= new HTTP::Request GET => $gifurl;
	    $gifreq->content_type('application/x-www-form-urlencoded');
	    $res= $ua->request($gifreq);

	    $req->method('GET');
#	    $req->url($urlroot.$gifout[0]);

#download the GIF first
	    $res= $ua->request($gifreq);
	    $gifok = 0;
	    if ($res->is_success) {
		$gifok = 1;
		&dbglog('retrieved: ',$gifout[0]);
		$tmpgifname = $tmpbasename.".gif";
		&dbglog('temporary gif: ',$tmpgifname);
		open(TMP,"> $tmpgifname");
		print TMP $res->content,"\n";
		close(TMP);
		@filelist = $tmpgifname;
		&dbglog('FILELIST: ',@filelist);
#		$uugifname = 'DAS_result.gif';
#		@uugif = `$exe_uuencode $tmpgifname $uugifname`;
#		$tmpcmd = "$exe_uuencode $tmpgifname $uugifname";
#		&dbglog('uugifcmd: ',$tmpcmd);
#		unlink $tmpgifname;
#		&dbglog('uunencode: ',@uugif);
	    } else {
		&dbglog('unable to retrieve: ',$gifout[0]);
	    }
#to be able to mail the images we uuencode them
	    
#now download the PostScript Plot

	    $psreq= new HTTP::Request GET => $psurl;
	    $psreq->content_type('application/x-www-form-urlencoded');
	    $res= $ua->request($psreq);

#	    $req->method('GET');
#	    $req->url($urlroot.$psout[0]);

	    $res= $ua->request($psreq);
	    $psok = 0;
	    if ($res->is_success) {
		$psok = 1;
		&dbglog('retrieved: ',$psout[0]);
		$tmppsname = $tmpbasename.".ps";
		&dbglog('temporary ps: ',$tmppsname);
		open(TMP,"> $tmppsname");
		print TMP $res->content,"\n";
		close(TMP);
		push @filelist,$tmppsname;
		&dbglog('FILELIST: ',@filelist);
#		$uupsname = 'DAS_result.ps';
#		@uups = `$exe_uuencode $tmppsname $uupsname`;
#		$tmpcmd = "$exe_uuencode $tmppsname $uupsname";
#		&dbglog('uupscmd: ',$tmpcmd);
		
#		unlink $tmppsname;
#		&dbglog('uunencode: ',@uups);
	    } else {
		&dbglog('unable to retrieve: ',$psout[0]);
	    }

#we now have all the necessary information (server HTML output
#gif image and PostScript image
#-> assemble the email message

#	    &mail($user,'meta-'.$service_name,$htmlcontent);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $htmlcontent,"\n";
	    close(TMP);
	    push @filelist,$tmphtml;
	    &dbglog('FILELIST: ',@filelist);
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;
# 	    $tmpcmd = "$exe_uuencode $tmphtml $uuhtmlname";
# 	    &dbglog('uuhtmlcmd: ',$tmpcmd);

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt |grep -v localhost`;
	    $string .= "----------------------------------------\n";

#we filter out all 'localhost' references from the lynx textoutput
#alternatively we could expand all href to include the serverroot

#	    open(TMP,"$tmptxt");
#	    while(<TMP>) {
#		if(!($_ =~ /localhost/)) {
#		    $string .= $_;
#		}
#	    }
#	    close(TMP);

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

# #we can simply append the images to the mail message because
# #they've been converted to ASCII already
# #gif image comes first
# 	    $string .= "Attachment: ";
# 	    if($gifok) {
# 		$string .= $uugifname;
# 		$string .= " - ";
# 	    }
# 	    if($psok) {
# 		$string .= $uupsname;
# 		$string .= " - ";
# 	    }
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";

# 	    if($gifok) {
# 		foreach $x ( @uugif ) {
# 		    $string .= $x;
# 		}
# 		$string .= "\n\n";
# 	    } else {
# 		&dbglog('gifoutput not available - SKIP');
# 	    }

# #ps image next
# #some mail clients AND the uudecode program seem to have problems
# #with multiple attachments
# #netscape mail seems to be able to handle multiple attachments
# #if we do NOT insert additional lines between two uuencode attachments

# 	    if($psok) {
# 		foreach $x ( @uups ) {
# 		    $string .= $x;
# 		}
# 		$string .= "\n\n"; 
# 	    } else {
# 		&dbglog('gifoutput not available - SKIP');
# 	    }

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-'.$service_name,$string);
#	    @filelist = ( $tmphtml, $tmpgifname, $tmppsname );
	    print "filelist: ",join '|',@filelist,"\n";
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    if($gifok) {unlink $tmpgifname;}
	    if($psok) {unlink $tmppsname;}
	    
	} else {
	    &msglog('$service_name server timed out ... ');
	}
    }
    &msglog('$service_name server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog("$service_name SERVICE HANDLER...DONE");
}				# end of DAS service

############################################################
#
#  Toppred
#
sub toppred {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="toppred";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("$service_name SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('$service_name serveraddress: ',$serveraddr);

    $seq= &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data="";

#	# any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

				# sequence name (ID)
	$data .= "&"."sequence_name=";
	$data .= $seqname;
				# sequence data
	print "SEQUENCE: ", $seq,"\n";
	$data .= "&"."sequence=";
	$data .= $seq;

#the default options
#hard-coded for now 
	$data .= "&"."organism=";
	$data .= "prokaryot";
	
	$data .= "&"."upper_cutoff=";
	$data .= "1.0";

	$data .= "&"."lower_cutoff=";
	$data .= "0.6";

	$data .= "&"."core_win=";
	$data .= "11";

	$data .= "&"."full_win=";
	$data .= "21";

	$data .= "&".".cgifields=";
	$data .= "organism";
	

	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
 	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;

# we now have to save the HTML document because
#the request object is reused

	    $htmlcontent = $res->content;
	    &dbglog('HTML content: ',$htmlcontent);

#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";

#now we can filter out the links and expand the URLS
#in order for us to get the embedded images wehave to create yet another
#request that targets the gif or ps image

#for extracting the links from the HTML document we use the LinkExtor
#module provided with HTML-Tree-0.51 and up
	    @imgs = ();
	    @href = ();
	    &getlinks($htmlcontent);
	    print $service_name."-output","\n";

#NOTE: toppred is a little damaged because its image URLs start
#from the 'real' serverroot (means URL of the following type 
#           SRC="/output/toppred.12625.gif"
#

	    @gifout = grep /output/,@imgs;
#	    @psout = grep /output/,@href;
	    print "OUTPUT-IMG: ",@gifout,"\n";
#	    print "OUTPUT-PS: ",@psout,"\n";

#to actually retrieve the images we have to prepend the server root
#there might be a method for obtaining the server root of an HTTP request
#for now we'll prepend the server root
#server root is assumed to be the URL up to the last / (slash)
#note also that in the case of DAS we could also use $url_das which points
#to the main server site
#both images could also be handled in one loop 

	    $tmpbasename = `$exe_tmpname`;

	    my($urlroot) = &getserverroot($serveraddr);
	    chop($urlroot);
	    &dbglog($service_name,': serverroot: ',$urlroot);

	    my($gifurl) = $urlroot.$gifout[0];

#	    &dbglog('gifurl: ',$urlroot.$gifout[0]);
	    &dbglog('gifurl: ',$gifurl);

#	    $req->method('GET');
#	    $req->url($urlroot.$gifout[0]);

	    $gifreq= new HTTP::Request GET => $gifurl;
	    $gifreq->content_type('application/x-www-form-urlencoded');
	    $res= $ua->request($gifreq);

#obtain the GIF first
	    $gifok = 0;
	    $res= $ua->request($gifreq);
	    
	    $giftry = 4;
	    while($giftry--) {
		&dbglog('trying to retrieve: ',$req->url);
		if ($res->is_success) {
		    $giftry = 0;
		    $gifok = 1;
		    &dbglog('retrieved: ',$gifout[0]);
		    $tmpgifname = $tmpbasename.".gif";
		    &dbglog('temporary gif: ',$tmpgifname);
		    open(TMP,"> $tmpgifname");
		    print TMP $res->content,"\n";
		    close(TMP);

		    @filelist = ();
		    push @filelist, $tmpgifname;
		    &dbglog('FILELIST: ',@filelist);
#		    $uugifname = $service_name.'_result.gif';
#		    @uugif = `$exe_uuencode $tmpgifname $uugifname`;
#		    unlink $tmpgifname;
#		&dbglog('uunencode: ',@uugif);
		} else {
		    sleep(2);
		}
	    }
#to be able to mail the images we uuencode them

#we now have all the necessary information (server HTML output
#gif image and PostScript image
#-> assemble the email message

#	    &mail($user,'meta-'.$service_name,$htmlcontent);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $htmlcontent,"\n";
	    close(TMP);
	    push @filelist,$tmphtml;
	    &dbglog('FILELIST: ',@filelist);
##uuencode the html output and attach to mail
#	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
#	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt |grep -v localhost`;
	    $string .= "----------------------------------------\n";

#we filter out all 'localhost' references from the lynx textoutput
#alternatively we could expand all href to include the serverroot

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

#we can simply append the images to the mail message because
#they've been converted to ASCII already
#gif image comes first
# 	    $string .= "Attachment: ";
# 	    if($gifok) {
# 		$string .= $uugifname;
# 		$string .= '-';
# 	    }
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";

# 	    if($gifok) {
# 		foreach $x ( @uugif ) {
# 		    $string .= $x;
# 		}
# 		$string .= "\n\n";
# 	    } else {
# 		&dbglog('gifoutput not available - SKIP');
# 	    }

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

#	    &mail($user,'meta-'.$service_name,$string);
	    &dbglog('FILELIST: ',@filelist);
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('$service_name server timed out ... ');
	}
    }
    &msglog('$service_name server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog("$service_name SERVICE HANDLER...DONE");
}				# end of generic_service

############################################################
#
#  SwissModel
sub swissmodel {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="swissmodel";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog("$service_name SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog('$service_name serveraddress: ',$serveraddr);

    $seq= &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data="";

	# any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

#hard-coded options/values taken from submit page
	$data .= "FOC=";
	$data .= "F";

	$data .= "&"."email=";
	$data .= $user;

	$data .= "&"."title=";
#	$data .= $seqname;
	$data .= "meta-request";

	$data .= "&"."sequence=";
	$data .= $seq;

	$data .= "&"."blast=";
	$data .= "0.00001";

	$data .= "&"."results=";
	$data .= "Normal";

	$data .= "&"."FOLDREC=";
	$data .= "Never";

#by special request
#> > If you use already a similar keyword for PredictProtein, let's just stay
#> > with the same. Otherwise we could take something like
#> > NAME="request_from" VALUE="metapp".

	$data .= "&"."request_from=";
	$data .= "metapp";


#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";
#	    &mail($user,'meta-'.$service_name,$res->content);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta'.$service_name,$string);

	    @filelist = ( $tmphtml );
#we skip swissmodel submission confirmation
#	    &mutt_mail($user,'meta-'.$service_name,$string,
#		       @filelist);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog('$service_name server timed out ... ');
	}
    }
    &msglog($service_name,' server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog($service_name, "SERVICE HANDLER...DONE");
}				# end of generic_service


############################################################

############################################################
#
#  FRSVR
sub frsvr {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="frsvr";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog($service_name," SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog($service_name,' serveraddress: ',$serveraddr);

    $seq = &parse_seq(1,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data="";

	# any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

				# sequence data
	print "SEQUENCE: ", $seq,"\n";
	$data .= "seqprot=";
	$data .= $seq;

				# sequence name (ID)
	$data .= "&"."protname=";
	$data .= $seqname;

	$data .= "&"."email=";
	$data .= $user;

#we'll add the options maunally at this point due to the 
#fact that the server doesn't seem to be very stable

	$data .= "&"."blast=";
	$data .= "yes";

	$data .= "&"."topits=";
	$data .= "no";

	$data .= "&"."dontlog=";
	$data .= "yes";

#the following two options can be turned on via options
#we have to be able to override default settings selectively
#one way around this is to use default values on the submission
#page and override the defaults when the checkboxes are selected

	if(length($options) > 0) {
#	    $data .= "&".$options;
	    @temp = split(/&/,$options);

#is the profile search option checked?
	    if($options =~ /profsea/) {
		foreach $x (@temp) {
		    if($x =~ /profsea/) {
			$data .= "&".$x;
		    }
		}
	    } 
	    else
	    {
		$data .= "&"."profsea=";
		$data .= "no";
	    }

#is the t3p2 option checked?
	    if($options =~ /t3p2/) {
		foreach $x (@temp) {
		    if($x =~ /t3p2/) {
			$data .= "&".$x;
		    }
		}
	    } 
	    else
	    {
		$data .= "&"."t3p2=";
		$data .= "no";
	    }
	    &dbglog($service_name," custom options: ",$data);
	} 
	else 
#no options at all
	{
	    $data .= "&"."t3p2=";
	    $data .= "no";
	    
	    $data .= "&"."profsea=";
	    $data .= "no";

	}


#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content),"\n";
#	    &mail($user,'meta-'.$service_name,$res->content);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-'.$service_name,$string);
	    @filelist = ( $tmphtml );
	    &mutt_mail($user,'meta-'.$service_name,$string,
		       @filelist);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog($service_name ,'server timed out ... ');
	}
    }
    &msglog($service_name ,' server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog($service_name ," SERVICE HANDLER...DONE");
}				# end of generic_service


############################################################


############################################################
#
#  SAMT98
sub samt98 {
    my($user,$options,$seqname,$rawseq)=@_;
    my($serveraddr,$seq,$req,$res);
#-------------------------------------------------------------------------------
    $data=        "";
    $service_name="samt98";
				# the debug and production serveraddresses
    $serveraddr=$services{"cgi_".$service_name};
    $serveraddr=$services_test{"cgi_".$service_name} if ($Ltest);

    &dbglog($service_name," SERVICE HANDLER");
    &dbglog("INPUT");
    &dbglog('   user:',$user);
    &dbglog('options:',$options);
    &dbglog('seqname:',$seqname);
    &dbglog($service_name,' serveraddress: ',$serveraddr);

    # general notes:
    # submission procedure similar to netoglyc
    # prepare the input sequence (chlorop accepts
    # single sequences by default)
    # ! note that chlorop wants between 100-150 residues

#SAMT98's readseq chokes on the single sequence raw format
#seems to work fine with FASTA

    $seq= &parse_seq(2,@rawseq);
#    &dbglog('Single Sequence: ',$seq);
    
    # first try the net connection
    $try = 0;			# to disable during testing
    $try = 3;
    $timeout = 1;
    while($try--) {
	use LWP::UserAgent;
#	require HTML::FormatText;
	use HTML::Parser;

	$ua = new LWP::UserAgent;
	$ua->agent("AgentName/0.1 " . $ua->agent);
	# the time out should be something like 5 minutes max for this
	# because the computations seem to be pretty fast
	# email backup is still available, so ...
	$ua->timeout(300);

	# assemble the form data
	$data="";

	# any options as preformatted string
#	if(length($options) > 0) {
#	    $data .= "&".$options;
#	}

				# sequence data
	$data .= "address=";
	$data .= $user;

	$data .= "&"."subjectline=";
	$data .= $seqname;

	print "SEQUENCE: ", $seq,"\n";
	$data .= "&"."sequence=";
	$data .= $seq;

	$data .= "&"."sum=";
	$data .= "1";

	$data .= "&"."lib=";
	$data .= "pdb";

	$data .= "&"."cutoff=";
	$data .= "-5";




#	foreach $x ( @seq ) {
#	    $data .= $x;
#	}
	&dbglog('INPUT: ',$data);
#	exit(1);

	# Create a request
	$req= new HTTP::Request POST => $serveraddr;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content($data);
	
	# Pass request to the user agent and get a response back
	$res= $ua->request($req);
	
	# Check the outcome of the request
	if ($res->is_success) {
	    $try = 0;
	    $timeout = 0;
#	    print $res->content,"\n";
#	    $formatter = FormatText->new();
#	    print $formatter->format($res->content);
#	    &mail($user,'meta-'.$service_name,$res->content);

	    # the HTML parser is giving us some problems
	    #	    print parse_html($res->content)->format,"\n";
	    $tmpbase = `$exe_tmpname`;
	    $tmphtml = $tmpbase.".html";
	    $tmptxt = $tmpbase.".txt";
	    &dbglog('tmphtml:', $tmphtml);
	    &dbglog('tmptxt:', $tmptxt);

	    open(TMP,"> $tmphtml");
	    print TMP $res->content,"\n","\n";
	    close(TMP);
	    
# #uuencode the html output and attach to mail
# 	    $uuhtmlname = $service_name.'.'.$seqname.'.html';
# 	    @uuhtml = `$exe_uuencode $tmphtml $uuhtmlname`;

	    system($par{"exe_lynx"}." -dump $tmphtml > $tmptxt");
	    $string = "";
	    $string = `cat $tmptxt`;

	    open(TMP,"$tmptxt");
	    while(<TMP>) {
		chomp;
		&dbglog($_);
	    }
	    close(TMP);

# #attach the HTML output
# 	    $string .= "\nAttachment: ";
# 	    $string .= $uuhtmlname;
# 	    $string .= "\n\n";
# 	    foreach $x ( @uuhtml ) {
# 		$string .= $x;
# 	    }
# 	    $string .= "\n\n";

# 	    &mail($user,'meta-'.$service_name,$string);
	    @filelist = ( $tmphtml );
#we skip samt's submission conformation
#	    &mutt_mail($user,'meta-'.$service_name,$string,
#		       @filelist);

	    # remove the temporary files
	    unlink $tmphtml, $tmptxt;
	    
	} else {
	    &msglog($service_name ,'server timed out ... ');
	}
    }
    &msglog($service_name ,' server timed out repeatedly ... trying email')
	if ($timeout) ;
    &dbglog($service_name ," SERVICE HANDLER...DONE");
}				# end of samt98


############################################################

#packages return true
1;

