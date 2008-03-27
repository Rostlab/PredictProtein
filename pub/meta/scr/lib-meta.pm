# #!/usr/local/bin/perl -w

#require "ctime.pl";

#===============================================================================
sub email_correct {
    my($userLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   email_correct               changes the email address for standard errors
#       in:                     $userLoc
#       out:                    <$userLoc|error_message>
#-------------------------------------------------------------------------------
    $sbrName="emailaddress_correct";
				# first: lower caps
    $userLoc=~tr/[A-Z]/[a-z]/;
				# we
    $userLoc="eyrich\@dodo.cpmc.columbia.edu" 
	if ($userLoc=~/^(voe|volker|eyrich)/ && $userLoc !~/\@/);
    $userLoc="rost\@dodo.cpmc.columbia.edu"
	if ($userLoc=~/^rost/ && $userLoc !~/\@/);
				# correct address
    $userLoc=~s/\.$//g;
    $userLoc=~s/\.nyu$/.nyu.edu/g;
    $userLoc=~s/\.du$/\.edu/;
    $userLoc=~s/\.(e.u|.du|ed.)$/\.edu/;
    $userLoc=~s/\.eu$/\.edu/;
    $userLoc=~s/\.ed$/\.edu/;
    $userLoc=~s/([^\.])edu$/$1.edu/;
    $userLoc=~s/edu\.usa$/usa.edu/;
    $userLoc=~s/come$/com/;
    $userLoc=~s/cn\.net$/cn/;
    $userLoc=~s/-uk.net$/.net.uk/g;
    $userLoc=~s/uk\.ac$/ac.uk/g;
    return($userLoc);
}				# end of emailaddress_correct

############################################################
#   email address massage (replace @ by \@)
sub email_massage {
    my($in)=shift;
    my($out)=  "";
    my($char)= "";
    
    &dbglog('input address: ',$in);
#    $out=$in; $out=~s/\@/\\\\\@/g;
    $out=$in; $out=~s/\@/\\\@/g;
    &dbglog('output address: ',$out);
    return($out);
}				# end of email_massage

#===============================================================================
sub email_valid {
    my   ($user) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   email_valid                 simple checks on validity of user address
#       in:                     $email_address
#       out:                    <1|0>
#-------------------------------------------------------------------------------
    $sbrName="email_valid";
				# no argument passed
    return(0) if (! defined $user || ! $user || $user !~/\@/);
    $user=~s/\s//g;		# security: purge blanks
	
				# last must be 
				# either  <gov|org|mil|com|edu>
    return(1) if ($user=~/\.(com|edu|gov|mil|org)$/);
    return(0) if ($user=~/\.(com|edu|gov|mil|org)[^\.]+$/);
				# or      2 characters
#    return(0) if ($user=~/\....$/);
    return(1);			# assume: it is ok
}				# end of email_valid

############################################################
# handle incoming request for services
# msg: is assumed to be the global message
sub handle_request {
    my($user,$service,$sbr);
    $[ =0 ;

    $seqstart=0;
    @rawseq=  ();
    $options= "";
    $sbr=     "handle_request";

    # we use foreach because while can cause problems on WIN32
  LINE:    
    foreach ( @msg ) {
	chomp;
	$line=$_;
	next if (! defined $line ||
		 $line=~/^[\s\t]*$/);
	@temp = split(/::/,$line);
	next LINE if (! defined($temp[0])); 

	if($temp[0] eq "user" ) {
	    $user= $temp[1];
				# correct obvious mistakes
	    $user=&email_correct($user);
				# is it valid
	    $Lis_valid=&email_valid($user);
	    if (! $Lis_valid) {
		&dbglog("wrong email user=$user");
		&abort("ERROR $sbr: wrong email user=$user"); }
				# commercial ?
	    $Lis_commercial=&is_commercial($user);
	    if ($Lis_commercial){
		&dbglog("COMMERCIAL user=$user");
				# yy do something if commercial
	    }
	    &dbglog("user: $user"); }
      
	if ($temp[0] eq "service") {
	    $service = $temp[1];
	    &dbglog("service: $service"); }
	
	# options are give as one string of name/value pairs
	if ($temp[0] eq "options" && 
	    defined $temp[1] && length($temp[1]) > 2) {
	    $options .= $temp[1];
	    $options .= "&";
	    &dbglog('option string: ',$options); }
      
	# the sequence has to be the last item in the request
	# once we have the 'sequence' token we the rest of the message is
	# interpreted as the sequence (or multiple sequences in a later implement)
      
	if ($seqstart) {
	    &dbglog('LINE:',$line);
	    push (@rawseq, $line) if (defined $line && 
				      $line !~/^[\s\t]*$/ &&
				      length($line)>1); 
	    next;}
      
	if ($temp[0] eq "sequence") {
	    $seqstart=1;
	    &dbglog('FOUND SEQUENCE START');
	    &dbglog('LINE:',$temp[1]);
	    push(@rawseq, $temp[1])  if (defined $temp[1] && 
					 $temp[1] !~/^[\s\t]*$/ &&
					 length($temp[1])>1); 
	}

	if ($temp[0] eq "seqname") {
	    $seqname= $temp[1];
	    $seqname=~s/\s+/_/g;
	    &dbglog('seqname: ',$seqname); }
    }				# 
    if (substr($options,length($options)-1,1) eq "&") {
	chop($options);
	&dbglog('option string: ',$options);
    }
    &dbglog('handlerequest:sequence: ',join("\n",@rawseq));
#    &dbglog('handlerequest:sequence: ',@rawseq);
    
    # check inconsistencies in the input
    # parse the sequence (we prepare two different formats)
    # 1. single sequence (one letter code)
    # 2. FASTA format

    &dbglog('REQUEST HANDLER');
#    &dbglog('services: ',@services);
#do we have a (reasoable) user name?
    if(length($user) > 0 && $user =~ /\@/) {
#can we actually handle this service?
	if( grep /$service/, @services) {
	    &dbglog("KNOWN SERVICE: $service");
	    &dbglog("sequence: @rawseq");
	    &$service($user,$options,$seqname,@rawseq);

#statistics echo
	    $time = &ctime(time);
	    chop($time);
	    $submit_time = "service_request: $service ";
	    $submit_time .= " time: ".$time;
	    $submit_time .= " for: ".$user;
	    $submit_time .= "\n"; 
	    &msglog($submit_time);
	
	}
	else {
	    &dbglog("UNKNOWN SERVICE REQUESTED: service: $service");
	}
    } 
    else {
	&dbglog("MISSING USER NAME: user: $user");
    }
}				# end of handle_request

#==========================================================================
sub is_commercial {
    my($addr)= @_;
#--------------------------------------------------------------------------------
#   is_commercial               test if the address belongs to a commercial user
#       in:                     $addr= email address 
#       out:                    <0|1>
#--------------------------------------------------------------------------------
				# aol, t-online
    return(0) if ($addr =~ /[\@\.](aol|hotmail|t-online|netscape)\.com/);
    return(0) if ($addr =~ /[\@\.](yahoo|compuserve|mailcity)\.com/);
    return(0) if ($addr =~ /[\@\.](netmail|angelfire)\.com/);
				# e.g. 'singnet.com.sg'
    return(0) if ($addr =~ /net\.com\.[a-z][a-z]$/);
				# .com extension
    return(1) if ($addr =~ /\.com$/i);
				# .co.uk|jp extension
    return(1) if ($addr =~ /\.co\.(uk|jp|[a-z][a-z])$/i);
    return(1) if ($addr =~ /\.com\.(uk|jp|[a-z][a-z])$/i);
    return(1) if ($addr =~ /\.mil$/i);
    return(1) if ($addr =~ /\.firm$/i);
    return(1) if ($addr =~ /\.store$/i);
    return(1) if ($addr =~ /\.ltd\.[a-z][a-z]$/i);
    return(1) if ($addr =~ /\.plc\.[a-z][a-z]$/i);
    return(1) if ($addr =~ /\.tm$/i);
    return(0);			# not commercial
}				# end is_commercial

############################################################
#
#  generic mailing routine
sub mail {
    my($user) = shift @_;
    my($subject) = shift @_;
    my(@msgbody) = @_;

    &dbglog('MAIL to user: ',$user,' with subject: ',$subject,'\n');

    open(MAIL,"| ".$par{"exe_mail"}." -s \"$subject\" $user") || 
	&abort("ERROR mail: cannot open MAIL");
    foreach $msg (@msgbody) {
	print MAIL $msg,"\n";}
    close(MAIL);
    &dbglog('MAIL...done');
}				# end of mail

############################################################
# 
#  MUTT_MAIL:
#  mail messages with attachments using mutt

#	    &mutt_mail($user,'meta-${service_name}',$string,
#		       @filelist);


sub mutt_mail {
    my($user) = shift;
    my($subject) = shift;
    my($message) = shift;
    my(@filelist) = @_;

    &dbglog('MUTT_MAIL to user: ',$user,' with subject: ',$subject);
#    &dbglog('MAIL_MSG: ',$message);
    &dbglog('Files to attach:');
    foreach $file ( @filelist ) {
	&dbglog('FILE: ',$file);
	if(!(-e $file)) {
	    &dbglog('attachment $file is missing');
	}
    }

    $cmd = $par{'exe_mutt'};
    $cmd .= " -x"; #emulate mailx mode
    $cmd .= " -s $subject";
    foreach $file ( @filelist ) {
 	if(-e $file) {
 	    $cmd .= " -a \"$file\"";
 	} else {
 	    &dbglog('attachment: $file is missing');
 	}
     }
    $cmd .= " $user";
    &dbglog('MUTT_CMD: ',$cmd);
    open(MUTT,"| $cmd") || die "failed to open $cmd\n";
    print MUTT $message;
    print MUTT ".";
    close(MUTT);

} #sub mutt_mail


############################################################
#
#   LINK EXTRACTION
#
#getlinks is a simple wrapper around LinkExtor from HTML-Tree-0.51
sub getlinks {
    my($htmldoc) = shift;
    require HTML::LinkExtor;
    $p = HTML::LinkExtor->new(\&cb);
    
#to parse an HTML file
#    $p->parse_file("file.html");
#to parse an HTML 'string'
    $p->parse($htmldoc);
}

#the call back routine required by LinkExtor
#simply push all IMG and A tags onto a stack
#needs two 'global' arrays: @imgs, @href
#note that entries are added without erasing previous content
sub cb {
    my($tag, %links) = @_;
    return if ($tag ne 'img' && $tag ne 'a') ;
#    print "$tag @{[%links]}";
    if($tag eq 'img') {
	    push(@imgs,values %links);
	}
    if($tag eq 'a') {
	push(@href,values %links);
    }
}
############################################################


############################################################
#
#   ServerRoot
#
#   obtain the server root for a given URL

sub getserverroot {
    my($url) = shift;
    my($root) = "";
#    print "getserverrroot";
    $url =~ s/http:\/\///;
    @temp = split(/\//,$url);
    $root = 'http://'.$temp[0];
    $root .= "/";
#    print "Root: $root";
    return $root;
}

############################################################

############################################################
#
#   URLRoot
#
#   obtain the root for a given URL

sub geturlroot {
    my($url) = shift;
    my($root) = "";
#    print "geturlroot";
    @temp = split(/\//,$url);
    $root = substr($url,0,length($url)-length($temp[$#temp]));
    $root .= "/";
#    print "Root: $root";
    return $root;
}

############################################################

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
#
#  UNDONE:
#  more consistent sequence handling (means: splitting multiple
#  sequence into separate single sequences, generation of FASTA input)
sub parse_seq {
    my($returntype,@rawsequence)=@_;
    my($seq,$Lok,$format,$sbr);
#-------------------------------------------------------------------------------
#       in:                     (<1|2>,@array_with_all_info_from_user)
#       out:                    (<0|1>,<error_message|sequence_in_one_string|@ali)
#-------------------------------------------------------------------------------
    $sbr="parse_seq";
    $retseq="";

    &dbglog('PARSE_SEQ');
    &dbglog('returntype: ',  $returntype);
    &dbglog('raw sequence: ',@rawsequence);
    
				# ------------------------------

				# which format
    ($Lok,$format)=&getFileFormat(\@rawsequence);
    &abort("ERROR in $sbr: failed getting format for sequence ($Lok,$format)")
	if (! $Lok);

				# ------------------------------
				# digest single sequence
				# ------------------------------
    if ($returntype == 1 || $returntype == 2) {
	$Lok=0;
	if    ($format eq "meta")  {
	    $seq= join("", @rawsequence);
	    $Lok=1; }
	elsif ($format eq "dssp")  { 
	    ($Lok,$tmp,$seq)=&dsspRdSeq(\@rawsequence,"*"); }
	elsif ($format =~ /^fasta/) {
	    ($Lok,$id,$seq)=&fastaRdGuide(\@rawsequence); }
	elsif ($format eq "gcg") {
	    ($Lok,$id,$seq)=&gcgRd(\@rawsequence); }
	elsif ($format eq "msf") {
	    ($Lok,$msg,%tmp)=&msfRd(\@rawsequence); 
	    if ($Lok) {
		$id= $tmp{"id","1"};
		$seq=$tmp{"seq","1"};
		$Lok=0          if (! defined $seq || length($seq) < 2);}}
	elsif ($format eq "pdb") {
	    ($Lok,$tmp,%tmp)=&pdbExtrSequence(\@rawsequence,"*"); 
	    if ($Lok && defined $tmp{"chains"}) {
		$seq="";
		foreach $chain (split(/,/,$tmp{"chains"})) {
		    $seq.=$tmp{$chain};
		    $seq.="!";}
		$seq=~s/!$//g;}}
	elsif ($format =~ /^pir/) {
	    ($Lok,$idTmp,$seqTmp)=&pirRdMul(\@rawsequence); 
	    if ($Lok) {
		$id= $idTmp;  $id=~s/\n.*$//g;
		$seq=$seqTmp; $seq=~s/\n.*$//g;}}
	elsif ($format eq "saf") {
	    ($Lok,$tmp,%tmp)=&safRd(\@rawsequence); 
	    if ($Lok) {
		$id= $tmp{"1"};
		$seq=$tmp{"seq","1"};}}
	elsif ($format eq "swiss") {
	    ($Lok,$id,$seq)=&swissRdSeq(\@rawsequence); }
	else {
	    &abort("ERROR $sbr: format of sequence ($format) not digestable!"); }

				# security change of sequence
	$seq=~ tr /a-z/A-Z/;
	$seq=~s/\s//g;
	$id="meta_by_default"   if (! defined $id);
    } else {
	$Lok=1;			# yy correct this
    }
    
    &abort("ERROR $sbr: failed eating sequence=\n".
	   join("\n",@rawsequence,"\n")) 
	if (! $Lok);
				# ------------------------------
				# return single sequence
    if ($returntype == 1) {
	&dbglog('$sbr: SINGLE SEQUENCE');
	&dbglog('PARSE_SEQ...DONE');
	return($seq); }
				# ------------------------------
				# return single sequence in FASTA
    if ($returntype == 2) {
	&dbglog('$sbr: SINGLE SEQUENCE IN FASTA');
	$seq=">$id\n".$seq;
	&dbglog('New Sequence: ',$seq);
	&dbglog('PARSE_SEQ...DONE');
	return($seq); }
				# ------------------------------
				# alignment to return
				# ------------------------------
    &dbglog('PARSE_SEQ...DONE: ERROR returntype=$returntype unidentified!');
}				# end of parse_seq

############################################################
#
#   ALIGNMENT HANDLING
#
#   parse input sequence (raw data) and produce
#   * many sequences (first sequence in a multiple sequence file)
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
#
sub parse_seq_ali {
    my($returntype,@rawsequence)=@_;
    my($seq,$Lok,$format,$sbr);
#-------------------------------------------------------------------------------
#       in:                     (<1|2>,@array_with_all_info_from_user)
#       out:                    (<0|1>,<error_message|sequence_in_one_string|@ali)
#-------------------------------------------------------------------------------
    $sbr="parse_seq_ali";
    $retseq="";

    &dbglog('PARSE_SEQ_ALI');
    &dbglog('returntype: ',  $returntype);
    &dbglog('raw sequence: ',@rawsequence);
    
				# ------------------------------

				# which format
    ($Lok,$format)=&getFileFormat(\@rawsequence);
    &abort("ERROR in $sbr: failed getting format for sequence ($Lok,$format)")
	if (! $Lok);

				# ------------------------------
				# digest single sequence
				# ------------------------------
    if ($returntype == 1 || $returntype == 2) {
	$Lok=0;
	if    ($format eq "meta")  {
	    $seq= join("", @rawsequence);
	    $Lok=1; }
	elsif ($format eq "dssp")  { 
	    ($Lok,$tmp,$seq)=&dsspRdSeq(\@rawsequence,"*"); }
	elsif ($format =~ /^fasta/) {
	    ($Lok,$id,$seq)=&fastaRdGuide(\@rawsequence); }
	elsif ($format eq "gcg") {
	    ($Lok,$id,$seq)=&gcgRd(\@rawsequence); }
	elsif ($format eq "msf") {
	    ($Lok,$msg,%tmp)=&msfRd(\@rawsequence); 
	    if ($Lok) {
		$id= $tmp{"id","1"};
		$seq=$tmp{"seq","1"};
		$Lok=0          if (! defined $seq || length($seq) < 2);}}
	elsif ($format eq "pdb") {
	    ($Lok,$tmp,%tmp)=&pdbExtrSequence(\@rawsequence,"*"); 
	    if ($Lok && defined $tmp{"chains"}) {
		$seq="";
		foreach $chain (split(/,/,$tmp{"chains"})) {
		    $seq.=$tmp{$chain};
		    $seq.="!";}
		$seq=~s/!$//g;}}
	elsif ($format =~ /^pir/) {
	    ($Lok,$idTmp,$seqTmp)=&pirRdMul(\@rawsequence); 
	    if ($Lok) {
		$id= $idTmp;  $id=~s/\n.*$//g;
		$seq=$seqTmp; $seq=~s/\n.*$//g;}}
	elsif ($format eq "saf") {
	    ($Lok,$tmp,%tmp)=&safRd(\@rawsequence); 
	    if ($Lok) {
		$id= $tmp{"1"};
		$seq=$tmp{"seq","1"};}}
	elsif ($format eq "swiss") {
	    ($Lok,$id,$seq)=&swissRdSeq(\@rawsequence); }
	else {
	    &abort("ERROR $sbr: format of sequence ($format) not digestable!"); }

				# security change of sequence
	$seq=~ tr /a-z/A-Z/;
	$seq=~s/\s//g;
	$id="meta_by_default"   if (! defined $id);
    } else {
	$Lok=1;			# yy correct this
    }
    
    &abort("ERROR $sbr: failed eating sequence=\n".
	   join("\n",@rawsequence,"\n")) 
	if (! $Lok);
				# ------------------------------
				# return single sequence
    if ($returntype == 1) {
	&dbglog('$sbr: SINGLE SEQUENCE');
	&dbglog('PARSE_SEQ_ALI...DONE');
	return($seq); }
				# ------------------------------
				# return single sequence in FASTA
    if ($returntype == 2) {
	&dbglog('$sbr: SINGLE SEQUENCE IN FASTA');
	$seq=">$id\n".$seq;
	&dbglog('New Sequence: ',$seq);
	&dbglog('PARSE_SEQ_ALI...DONE');
	return($seq); }
				# ------------------------------
				# alignment to return
				# ------------------------------
    &dbglog('PARSE_SEQ_ALI...DONE: ERROR returntype=$returntype unidentified!');
}				# end of parse_seq_ali 

1;
