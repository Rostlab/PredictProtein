#!/usr/local/bin/perl -w

undef($cgiparse);
use Env;
use CGI qw(:standard);
#require "getopts.pl";
use Getopt::Std;

#generate the META submit page dynamically
#outline:
#1. check commandline args for input data
#2. handle cookies
#3. assemble basic <HTML> headers if necessary
#4. generate form and paste in data

#NOTE: since this script is run by the web server (user www)
#the permission for metaconfig.pl have to be correct so that read
#access is possible for just about everybody

#$ldbg = 1;
$ldbg = 0;

#$ARGV[0] = "-phm"; #test command line args

if($#ARGV < 0) {
#    print "$0 :: standalone mode\n";
    $skip_header = 0;
    $email = "";
    $seqname = "";
    $sequence = "";
    
} else {
#    print "$0 :: invoked with command line args\n";
    parse_cmdline();
}


#@html = ();
#handle cookies

if($ldbg) {
    $cgi = new CGI({'debug'=>'true'});
} else {
    $cgi = new CGI;
}

#we do NOT use 'expiration' settings since we
#we want the user to be able to use the 'back' button
#from the submission confirmation page
if(!($skip_header)) {
    print $cgi->header(-type=>'text/html',
#		       -expires=>'-1d'
		       );
    
#note that keywords probably don't help that much since this is a dynamic document
    print $cgi->start_html(-title=>'META II - PredictProtein server',
			   -author=>'volker@chem.columbia.edu',
			   meta=>{'keywords'=>'protein structure prediction'},
			   -BGCOLOR=>'white'
			   );
}

if($ldbg) {
    print "<center>";
    print $cgi->h2('DEBUG MODE');
    print "</center>";
}

#the location of the META environment is taken from the environment
#print $cgi->h3('hacked METACONF ... has to be set in the Webserver environment!!!');

#HACK: since 'I' cannot modify www's environment right now we'll have to hack it
$METACONF = "/home/meta/2meta/conf/metaconfig.pl";


if(! defined($METACONF)) {
    print "METACONF environment variable not set\n";
    exit;
} else {
    if($ldbg) {
	print "METACONF=$METACONF\n";
    }
}


require $METACONF;

#init doc defaults
init();

$helpurl = $url{'help'};
#if invoked from another CGI script we might have to skip the
#HTML header information

#print the default header
print_formalities();

#open the form
open_form();

#job information (email, sequence, etc)
print_jobinfo();

#start the list of services
start_services();

#create the header used in all tables
create_services_header();

#services related to function
services_function();

#services related to structure
services_structure();

#generate the complete form table
generate_table();

#submit and clear buttons
print_submit_and_clear();

#close the form
print endform();

#footer
print_footer();

#create the fill out form
#create_form();

print $cgi->end_html unless($skip_header);
exit; #end of the main routine
####

############################################################
#
# open_form

sub open_form {
    print start_form(-method=>'post',
		     -action=>$cgiparse,
#			   -encoding=>'multipart/form-data');
		     -encoding=>'application/x-www-form-urlencoded');
    
} #/open_form

############################################################
#
# print_footer
#

sub print_footer {

    print "
<A NAME=\"bottom\">
<P ALIGN=CENTER>
<A HREF=\"#top\">                    Top</A> - 
<A HREF=\"" . $helpurl . "\">   Further information about META PP</A> - 
<A HREF=\"" . $url{'pp'} . "\">     PP home</A> -
<A HREF=\"" . $url{'pp_help'} . "\">       PP help TOC</A> -
<A HREF=\"" . $url{'pp_links'} . "\">    Links</A>
</P></A>";

    print"<UL>";
    print "<LI>admin: ",$admin->{'name'}," <A HREF=\"mailto:",$admin->{'email'},"\">",$admin->{'email'},"</A>";
    $lastupdate = localtime(time());
    print "<LI>last update: ",$lastupdate;
    print "</UL>";


} #/print_footer



############################################################
#
# print_submit_and_clear
#

sub print_submit_and_clear {
    
    print table (
		 Tr(
		    td(
		       "<FONT SIZE=\"+1\"> <STRONG>".
		       "<INPUT TYPE=\"submit\" VALUE=\"SUBMIT / RUN PREDICTION\"> ".
		       "</STRONG></FONT>"
		       ),
		    td(
		       "<FONT SIZE=\"+1\"> <STRONG>".
		       "<INPUT TYPE=\"reset\"  VALUE=\"CLEAR PAGE\">".
		       "</STRONG></FONT>"
		       ),
		    td($nbsp),
		    td(
		       "<A HREF=\"doc/explain_meta.html#PX_submit\" TARGET=\"doc/explain_meta.html#PX_submit\">Help</A>"
		       )
		    ) #/Tr
		 ); #/table
    
} #/print_submit_and_clear

############################################################
#
# generate_table
#

sub generate_table {
    
    print table({-border=>"1",-cellpadding=>"1"},
		
		Tr({-bgcolor=>$silver,-valign=>"TOP"},
		   $services_header #implicit td()
		   ), #/Tr

		Tr(
		   td({-colspan=>"7",-bgcolor=>$blue},font({-color=>$white,size=>"+1"},strong("PROTEIN FUNCTION"))),
		   ), #/Tr
		
		Tr({-bgcolor=>$blue},
  		   td({-rowspan=>$nservers_function},font({-color=>$white},strong('Motifs')))
		   ), #/Tr

		  
		$servers_function_block,

		Tr(
		   td({-colspan=>"7",-bgcolor=>$blue},font({-color=>$white,size=>"+1"},strong("PROTEIN STRUCTURE"))),
		   ), #/Tr

		Tr({-bgcolor=>$blue},
  		   td({-rowspan=>$nservers_3d},font({-color=>$white},strong($nbsp."3D")))
		   ), #/Tr

		$servers_3d_block,

#  		Tr({-bgcolor=>$blue},
#  		   td({-rowspan=>$nservers_2d},font({-color=>$white},strong($nbsp."2D")))
#  		   ), #/Tr
		
#  		$servers_2d_block,
		
		Tr({-bgcolor=>$blue},
  		   td({-rowspan=>$nservers_1d},font({-color=>$white},strong($nbsp."1D")))
		   ), #/Tr

		$servers_1d_block
		
    		); #/table
    

} #/generate_table

############################################################
#
# services_structure
#

sub services_structure {

# 3D structure
    $nservers_3d = $#servers_structure_3d + 2;
    $servers_3d_block = "";
    foreach $server ( @servers_structure_3d ) {

	$servers_3d_block .= Tr(get_server_row($server));

    } #/foreach @servers_structure_3d

#  # 2D structure
    
    if($#servers_structure_2d > -1 ) {
	$nservers_2d = $#servers_structure_2d + 2;
	$servers_2d_block = "";
	foreach $server ( @servers_structure_2d ) {
	    
	    $servers_2d_block .= Tr(get_server_row($server));
	
	} #/foreach @servers_structure_2d
    } else {
	$servers_2d_block = "";
    }
    
# 1D structure
    $nservers_1d = $#servers_structure_1d + 2;
    $servers_1d_block = "";
    foreach $server ( @servers_structure_1d ) {

	$servers_1d_block .= Tr(get_server_row($server));

    } #/foreach @servers_structure_1d
    


} #/services_structure

############################################################
#
# services_function
#

sub services_function {

    print "\n\n";

#determine the number of "Motif" servers to set ROWSPAN for "Motifs" properly
    $nservers_function = $#servers_function + 2;

#assemble the services rows
    print "\n\n";

    $servers_function_block = "";
    foreach $server (@servers_function) {

	$servers_function_block .= Tr(get_server_row($server));

	} #/foreach @servers_function


#      print table({-border=>"1",-cellpadding=>"1"},

#  		Tr(
#  		   td({-colspan=>"7",-bgcolor=>$blue},font({-color=>$white,size=>"+1"},strong("FUNCTION"))),
#  		   ), #/Tr

#  		Tr({-bgcolor=>$silver,-valign=>"TOP"},
#  		   $services_header #implicit td()
#    		   ), #/Tr

#  		Tr({-bgcolor=>$blue},
#  		   td({-rowspan=>$nservers},font({-color=>$white},strong('Motifs')))
#  		   ), #/Tr
		
#  		$block
		
#    		); #/table
    
    
} #/services_function

############################################################
#
# services_header

sub create_services_header {
    
    $services_header = td("Feature");
    $services_header .= td("Choose");
    $services_header .= td("Type of prediction");
    $services_header .= td("Name of server");
    $services_header .= td("Options (more information under 'About')");
    $services_header .= td("Server",br(),"Info");
    $services_header .= td("Go directly",br(),"to server");

} #/services_header

############################################################
#
# start_services
#

sub start_services {
    print strong(
		 font({-size=>"+2"},
		      "Services available "
		      ), #/font
		      ); #/strong
    print "Choose (at least one) checkbox(es) to request respective services for your protein";
		     
} #/list_services

############################################################
#
# print_jobinfo
#

sub print_jobinfo {

    print table(

#header line
		Tr(
		   td({-bgcolor=>"$silver"},
		      'Type the required information into the fields (and select one or more services)'
		      ), #/td
		   td({-bgcolor=>"$silver"},
		      'Description of field (click on description for help)'
		      ) #/td
		   ), #/Tr

#email address

		Tr(
		   td( 
		      textfield(-name=>"email",-default=>$email,-size=>60)
		      ), #/td
		   td(
		      a({-href=>$helpdoc_url."#userinfo",
			 -target=>$helpdoc_url."#userinfo"},
			strong("Your email address"), "(watch for typos)"
			) #/a
		      ) #/td
		   ), #/Tr
		
#sequence name
		Tr(
		   td(
		      textfield(-name=>"seqname",-default=>$seqname,-size=>60)
		      ), #/td
		   td(
		      a({-href=>$helpdoc_url."#userinfo",
			 -target=>$helpdoc_url."#userinfo"},
			strong("One-line name of protein"), "(optional)"
			) #/a
		      ) #/td
		   ), #/Tr

#sequence
		Tr({-valign=>"top"},
		   td(
		      textarea(-name=>"sequence",-default=>$sequence,-rows=>12,-columns=>60)
		      ),
		   td(
		      a({-href=>$helpdoc_url."#userinfo",
			 -target=>$helpdoc_url."#userinfo"},
			strong("Paste, or type your sequence"), ""
			), #/a
#short description
		      ul(
			 li("amino acids in one-letter code",br(),
			    "(any number of spaces allowed)"),
			 li(
			    a({-href=>$helpdoc_url."#seqformats",
			       -target=>$helpdoc_url."#seqformats"},
			      "other possible formats")
			    ) #/li
			 ), #/ul
		      
		      "For retrieving protein sequences",br(),
		      "from databases we recommend the",br(),
		      "Sequence Retrieval System",
		      
		      a({-href=>$url{'srs'},-target=>"SRS6"},"SRS6")
		      
#		      "For retrieving protein sequences<BR>
#		      from databases we recommend the <BR>
#		      Sequence Retrieval System <A HREF="http://srs6.ebi.ac.uk" TARGET="SRS6">SRS6</A>
		      
		      ) #/td
		   ) #/Tr

		); #/Table
   
    print br();
} #print_jobinfo

############################################################
#
# parse_cmdline():
#
# parse command line arguments and extract username, sequencename, and sequence

sub parse_cmdline {

    my($dbg) = 0;
#-u: username
#-n: sequence name
#-s: sequence
#-h: skip <HTML> header info

#-phm: place holder mode: essential job info is marked with place holders

    getopts('phm');

    if(defined($opt_p) && $opt_p &&
       defined($opt_h) && $opt_h &&
       defined($opt_m) && $opt_m ) {

	print "place holder mode\n" if($dbg);

	$email = "PH_EMAIL_PH";
	$seqname = "PH_SEQNAME_PH";
	$sequence = "PH_SEQUENCE";

	if($dbg) {
	    print "email: $email\n";
	    print "seqname: $seqname\n";
	    print "sequence: $sequence\n";
	}

	$skip_header = 1;

    }

} #end parse_cmdline


################################################################################
#
# print_formalities
#
# assemble the standard header data

sub print_formalities {
#non header info
    print  "<BODY bgcolor=#FFFFFF>" unless($skip_header);
    print  "<A NAME=\"top\"><P ALIGN=CENTER>
<A HREF=\"" . $helpurl . "\">   Further information about META PP</A> - 
<A HREF=\"\#bottom\">                 Bottom</A> - 
<A HREF=\"" . $url{'pp'} . "\">     PP home</A> -
<A HREF=\"" . $url{'pp_help'} . "\">       PP help TOC</A> -
<A HREF=\"" . $url{'pp_links'} . "\">    Links</A>

</P></A>
<P>";
    
    print "
<CENTER>
<TABLE BORDER=3 CELLPADDING=1 WIDTH=600>
<TR>    <TD VALIGN=MIDDLE BGCOLOR=BLUE>
	<BR>
	<CENTER>
	<H1>
	<FONT COLOR=\"\#FFFFFF\" SIZE=\"+3\">
	The META server
	</FONT>
	<FONT COLOR=\"\#FFFFFF\">
	&nbsp; : &nbsp; Volker Eyrich and Burkhard Rost
	</FONT>
	</H1>
	</CENTER>
	</TD>
<!-- 
<TR>    
<TD>    <CENTER>
        <STRONG>
        <FONT SIZE=\"+2\">The META PredictProtein server</FONT></STRONG>
        <BR>by winnie the pooh
        </CENTER>
</TD>
 -->
</TR>

</TABLE>
</CENTER>

<br><br>
";
} #print_formalities


############################################################
#
# init()
#

sub init {

#colors
    $silver = "SILVER";
    $blue = "BLUE";
    $white = "WHITE";

    $nbsp = "&nbsp;";

#    $htmlroot = "/~meta/";
#    $helpdoc_url = $htmlroot."help.html";
    $helpdoc_url = $url{'help'};

} #/init


############################################################
#
# get_server_options
#

sub get_server_options {

    my($server) = shift;

    @serv_with_opt = keys(%{$service_options});
    
    $opt = "";
    if( grep /$server/,@serv_with_opt ) {
	
	$nopts = 0;
	foreach $optref ( @{$service_options->{$server}} ) {
	    $nopts++;
	    }
#	    print "\n\nnumber of options: $nopts\n\n";
	$i = 0;
	foreach $optref ( @{$service_options->{$server}} ) {
	    
	    ($name,$value,$type,$caption) = @{ $optref };
#we have to break with more than three options (a max of three options per line)
#we can not use CGI's checkbox etc functions since the input field is determined by 
#metaconfig.pl
	    $opt .= "<INPUT " . "NAME=\"" . $server . "::" . $name;
	    $opt .= "\" VALUE=\"" . $value;
	    $opt .= "\" TYPE=\"" . $type;
	    $opt .= "\">" . $caption . "</A>";
	    
	    $i++;
	    if( $i%3 == 0 && ($nopts > $i)) {
		$opt .= br();
#		    print "added line break\n";
		}
	    
	}
#	    exit;
    } else {
#           print "no options for this service";
    }
    
    return $opt;
    
} #/get_server_options

############################################################
#
# get_server_row
#

sub get_server_row {

    my($server) = shift;

    $url = %{$services->{$server}}->{'url'};
    $predtype = %{$services->{$server}}->{'predtype'};
    $server_name = %{$services->{$server}}->{'abbr'};
    
    $opt = get_server_options($server);
    
    if(0) {
	print "  server: $server\n";
	print "     url: $url\n";
	print "predtype: $predtype\n";
	print "\n";
    }

#set the max length for the fields
#should an item exceed the max length -> wrap
#otherwise -> pad with &nbsp;

#not needed anymore since we are now creating ONE table and the field
#width is determined by the length of the longest element
#    $predtype = adjust_length($predtype,30);

    $tdrow = "";
    $tdrow .= td({-align=>"center"},
		 checkbox(-name=>$server,-label=>""));
    $tdrow .= td($predtype);
    $tdrow .= td(b($server_name));
    $tdrow .= td(b($opt));
    $tdrow .= td(a({href=>$helpdoc_url."#".$server,-target=>$helpdoc_url."#".$server},'About'));
    $tdrow .= td(a({-href=>$url,-target=>$url},'Go there'));

    return $tdrow;
    
} #/get_server_row

############################################################
#
# adjust_length
#
# adjust the length of table data fields



sub adjust_length {

    my($item) = shift;
    my($maxlength) = shift;

    my($dbg) = 0;

    $len = length($item);
    if($len <= $maxlength) {
	for($i=1;$i<($maxlength-$len);$i++) {
	    $item .= $nbsp;
	}
	return $item;
    } else {
	@letters = ();
	print "item: $item\n" if($dbg);
	$item_temp = $item;
	print "item: $item_temp\n" if($dbg);

	while($letter = chop($item_temp)) {
	    print $letter,"\n" if($dbg);
	    push @letters,$letter;
	}
    }
    @letters = reverse(@letters);
    
    print "letters: ",@letters,"\n" if($dbg);

    $i = 0;
    $item = "";
    foreach $letter ( @letters ) {
	print "i/letter: $i \t $letter\n" if($dbg);
	$i++;
	$item .= $letter;
	if( ($i%$maxlength) == 0 ) {
	    print "break\n" if($dbg);
	    $item .= br();
	    $i = 0;
	}
    }
    print "item: $item\n" if($dbg);
#    exit;

    
#    print "item: $item\n";
#    exit;

    return $item;

}
