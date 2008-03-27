#!/usr/local/bin/perl -w

# 
# ------------------------------
# comments
# 
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  - 
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Volker Eyrich		volker@dodo.cpmc.columbia.edu		       #
#	CUBIC (Columbia Univ)	http://dodo.cpmc.columbia.edu/cubic/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032						       #
#				version 0.1   	May,    	1999	       #
#------------------------------------------------------------------------------#
#
# 
				# ------------------------------
				# local parameter definition
require "envMeta.pm";		# HARD_CODED

				# hack around warnings
$#services=0;
undef %services;
$debug=0;


&ini();
				# keys of HTML page
&iniHtmlKeywords();
    

&ReadParse(*input);

$debug = 1; #off
#$debug = 0; #on

$nl=      "<br>\n"; 
$bold=    "<b>";
$endbold= "</b>";


############################################################
#
# the metaserver recipient
#


$ref_page= $ENV{'HTTP_REFERER'};
print &PrintHeader;
print &HtmlTop ("Response for $ref_page");



#print the information to MAIL or STDOUT
print "Response processed:",$bold,&ctime(time),$endbold,$nl;
print "Referring page: ",$bold,$ref_page,$endbold,$nl;
print "Remote Host: ",$bold,$ENV{'REMOTE_HOST'},$endbold,$nl;
print "Remote Addr: ",$bold,$ENV{'REMOTE_ADDR'},$endbold,$nl;    

print "Keys and associated values defined in the document",$nl,$nl;
foreach $key ( sort(keys(%input)) ) {
    print $key,":\t",$input{$key},$nl;
}


#now we simply assemble emails for every service requested
$email=   $input{'email'};
$seq=     $input{'seq'};
$seqname= $input{'seqname'};

print $bold,"email address: ",$endbold,$input{$IN_usr_email},$nl
    if (defined $input{$IN_usr_email});
print $bold,"password:      ",$endbold,$input{$IN_usr_pwd},$nl
    if (defined $input{$IN_usr_pwd});
print $bold,"sequence name: ",$endbold,$input{$IN_seqname},$nl
    if (defined $input{$IN_seqname});
print $bold,"sequence:      ",$endbold,$input{$TX_sequence},$nl
    if (defined $input{$TX_sequence});



#remove all whitespace from the sequence
@requests= ();
foreach $serv ( @services ) {
    
#    print $serv," - ";
    if(defined($input{$serv}) && $input{$serv} eq "true") {
#	print "requested service";
	push @requests, $serv;
    }
#    print "<br>";


}

print "<b>Services requested:</b><br>";
print join " - ", @requests, "<br>";

foreach $serv ( @requests ) {
#strange but TRUE ... no space between " and |

#parse the options strings: format is very simple
#e.g: INPUT NAME="jpredopt::nnssp" TYPE="checkbox"
#jpredopt is an optional setting for the service jpred and if present 
#we give it the name nnssp
    
    $options = "";
    foreach $key ( sort(keys(%input)) ) {
#    print $key,":\t",$input{$key},$nl;
#the string we are looking for
	$tmp = $serv."opt";
#    print "looking for option: $tmp",$nl;
	if($key =~ /$tmp/) {
	    print "match: ",$key,"\t",$input{$key},"<br>";
	    @temp = split(/::/,$key);
	    if(length($options) > 0) {
		$options .= "&";
	    }
	    $options .= $temp[1]."=";
	    $options .= $input{$key};
	    print "option: $options",$nl;
	}
	
}




#sendmail seems kind of picky
    $subjectline = "\"METAREQUEST ";
    $subjectline .= &ctime(time);
    $subjectline .= "\"";
    
    print "Subjectline: $subjectline<br>";
#    open(MAIL, "| /usr/sbin/sendmail $metamail") || die "sendmail problem";
#    open(MAIL, "| /usr/bin/Mail -s METAREQUEST $metamail") || die "sendmail problem";
    open(MAIL, "| /usr/sbin/Mail -s $subjectline $metamail") || die "sendmail problem";
    print MAIL "META-REQUEST\n";
    print MAIL "user::",$email,"\n";
    print MAIL "service::",$serv,"\n";
    print MAIL "options::",$options,"\n";
    print MAIL "seqname::",$seqname,"\n";
    print MAIL "sequence::",$seq,"\n";

    print "MAIL MESSAGE",$nl;
    print "META-REQUEST",$nl;
    print "user::",$email,$nl;
    print "service::",$serv,$nl;
    print "options::",$options,$nl;
    print "seqname::",$seqname,$nl;
    print "sequence::",$seq,$nl;
#    print MAIL "."; #terminates the mail in sendmail?
    print "mailed $serv to $metamail<br>";
    close(MAIL);
}


print "<HR>";
print $bold,"CGI-Environment", $endbold,$nl;
print "<TABLE>";
foreach $key( sort(keys(%ENV)) ) {
    print "<TR>";
    print "<TD>",$key,"</TD>","<TD>",$ENV{$key},"</TD>";
    print "</TR>";
}
print "</TABLE>";


print $nl,$nl;
print &HtmlBot;


exit;

#===============================================================================
sub ini {
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         initialise settings
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="ini";

				# ------------------------------
				# define parameters
				# GLOBAL out:
				# %par{$kwd},
				#    with $kwd=<exe_*|lib_*|opt_*>
				# @services= list of all services
				# $DIR_
    &iniEnv(1);
				# ------------------------------
				# require libs
    foreach $kwd ("lib_cgi","lib_ctime") {
	next if (! defined $kwd || length($kwd)<1);
	$Lok=
	    require $par{$kwd};
	next if ($Lok);
				# error
	$msg="*** ERROR during ini of $0: require $kwd (".$par{$kwd}.") failed";
	&htmlPrintNormal($msg);
	&abort($msg); }

				# ------------------------------
				# 
    $metamail=$par{"par_cgi_metamail"};

    return(1,"ok $sbrName");
}				# end of ini

#===============================================================================
sub iniHtmlKeywords {
    local($sbrName);
#-------------------------------------------------------------------------------
#   iniHtmlKeywords             assigns the default keywords to parse the WWW
#                               submission form
#       in GLOBAL:              all
#       out GLOBAL:             all
#-------------------------------------------------------------------------------
    $sbrName="iniHtmlKeywords";
    # --------------------------------------------------------------------------------
    # Define the html controls
    # 
    #   $IN ==> Input
    #   $TX ==> Textarea
    #   $SE ==> Select
    #   $CB ==> Checkbox 
    # 
    # =====  ***********************************************************
    # NOTE:  also setting the keywords! 
    #        these MUST be identical to the WWW page for submission!!
    #        
    # =====  ***********************************************************
    # 
    # --------------------------------------------------------------------------------


                                # --------------------
                                # textarea
    $IN_usr_email=        "email";      # user identity
    $IN_usr_pwd=          "password";	# password for commercial

				# ------------------------------
                                # sequence
    $IN_seqname=          "seqname";	# name (one row)
				# --------------------
				# textarea (10 rows)
    $TX_sequence=         "sequence"; 
}				# end of iniHtmlKeywords

