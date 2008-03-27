#!/usr/local/bin/perl 

use lib '..';
use CGI qw/:standard/;
use CGI::Carp qw/fatalsToBrowser/;
use FileHandle;
# used to interpret annotations.
#------------------------------------------------------------------------------------------
#DNA Bind Motif anno list
$binAnno{'hbox'}="HOMEOBOX";$binAnno{'bas'}= "BASIC DOMAIN";
$binAnno{'fork'}= "FORK-HEAD"; $binAnno{'hlh'}= "HELIX-LOOP-HELIX";
$binAnno{'myb'}= "MYB"; $binAnno{'hmg'}="HMG BOX";
$binAnno{'znc'}= "ZINC FINGERS"; $binAnno{'ets'}="ETS-DOMAIN";
$binAnno{'fun'}="FUNGAL-TYPE"; $binAnno{'hook'}= "A.T HOOK";
#--------------------------------------------------------------------------------------------

$par{"dirHome"}=                      "/home/httpd/cgi-bin/var/nair/LOCtarget/";


$fhin="FHIN";
$fhdata= "FHDATA";
$STDOUT="STDOUT";

STDOUT->autoflush(1);

$query = new  CGI;

print $STDOUT $query->header;
print $STDOUT $query->start_html( 'LOCtarget Online' );

# Print the first form
if ( !$query->param) {
  print $STDOUT "<BODY BGCOLOR='#FFFFFF'>";
  print $STDOUT "<H1><ALIGN='CENTER'> <STRONG> LOCtarget sequence input Form <FONT SIZE='-1'></FONT></STRONG></CENTER></H1>";
  print $STDOUT $query->start_multipart_form(-target=>'_new');
 # print $STDOUT $query->startform;
  $remoteDat=$query->remote_user || 'anonymous@' . $query->remote_host;
  system("echo $remoteDat >>log/userLog");
  $name="";
  
  print $STDOUT "<P><TABLE>",
  "<TR>",
  "<TD VALIGN=TOP>",
  $query->textfield('name',$name,50),"&nbsp; your email address(required)",
  "<BR>";
  print $STDOUT "<FONT SIZE='-1'>The prediction results will be emailed as soon as they are available.<BR> . <P></FONT>";
  print $STDOUT "</TD></TR>";
  
#  $query->radio_group(-name=>'choice',-values=>['  no ',' yes'],-defaults=>['  no ']),"<BR>",
  print $STDOUT "<TR><TD VALIGN=TOP>";

  print $STDOUT "Upload a sequence file or paste an amino acid sequence in fasta format. <P>",
  "</TD>";
  print $STDOUT "<TD> </TD>",
  "</TR>",
  
	"<TR>",
	  "<TD>",
	    "Type an identifier for your protein",
     "</TD>",
      "</TR>",
	"<TR>",
	  "<TD>",
	    $query->textfield('protId',$protId,20),
      "</TD>",
      "</TR>",
      "<TR>",
	  "<TD>",
	    "Type of organism (Eukaryotic or Prokaryotic)",
     "</TD>",
      "</TR>",
	"<TR>",
	  "<TD>",
	    $query->textfield('orgType',$orgType,20),
      "</TD>",
      "</TR>",
      "<TR><TD>",
	"&nbsp;",
	  "<H3> Choose from one of the options below</H3>",
    "",
      $query->radio_group(
			-name=> 'option',
			-Values=> ['Paste an amino acid sequence'],
#			-default=>['Paste an amino acid sequence'],
			-cols=>1),
	$query->textarea(-name=>'data',-rows=>8,-columns=>50),
     "<TR>",
	"<TD>",
	  $query->radio_group(
			-name=> 'option',
			-Values=> ['Upload a sequence file'],
			-default=>['Paste an amino acid sequence'],
			-cols=>1),
			  $query->filefield(-name=>'Struct'),
    
 
      "</TD>",
      "</TR>",
   "<TR>",
    "<TD>",
    "&nbsp; &nbsp; &nbsp; ",
      "</TD>",
      "</TR>",
    "<TR>",
    "<TD>",	

	  
	  

      "</TD>",
      "</TR>",
   "<TR>",
    "<TD>",
    "&nbsp; &nbsp; ",
      "</TD>",
      "</TR>",
      "</TABLE>";
  print $STDOUT $query->submit(-label=>'Submit');
   
  
  
  #print $STDOUT "<H2>Contact:</H2>";
  #print $STDOUT " <H2><A href=\"mailto:cubic@tulip.bioc.columbia.edu\">cubic@tulip.bioc.columbia.edu</A></H2>";
  print $STDOUT $query->endform;
  
}
else {
  print $STDOUT "<BODY BGCOLOR='#FFFFFF'>";
  print $STDOUT "<H1><CENTER> <STRONG>LOCtarget Online </STRONG></CENTER></H1>";
  print $STDOUT "<H1><STRONG>Confirmation:</STRONG></H1>";
  
 
  # allocate data from web to var
  $name= $query->param(name);
  $protId=$query->param(protId);
  $orgType=$query->param('orgType');

  if($orgType =~ /proka/i){
    $orgType="Prokaryotic";
  }
  else{
    $orgType="Eukaryotic";
  }
  if($name=~ /\w+\@\w+/){
    $mail ="yes";
  }
  else{
    $mail= "no";
  }


  if ($mail=~ /yes/) {
    print $STDOUT "<H3>Sequence data received. The results will be emailed to address submitted:<em> $name</em></H3>";
    print $STDOUT "<H3>Organism Type= $orgType\n";
  }
  else{
    print $STDOUT "<H2>No email address was provided. Please resubmit.</H2>";
    exit;
  }

  if($protId !~ /\w/){
    $protId=$name;
    print $STDOUT "<H3>No protein Id provided. Email address will be used to identify protein";
  }

  
  $jobId=int(rand 10000) + 1;
 # initialize working directories and files.
  $dirOut="tmp/";# the output dir for temp files generated
  chdir($dirOut);#change dir to tmp

  $option=$query->param('option');
  print $STDOUT "<H2> option= $option</H2>";


  $fileData="Struct".$jobId;# all files in tmp dir which is writable to all
  open($fhin,">".$fileData) || die "could not open $fileData\n";
  print $fhin "#out gen by $0\n";

  if($option=~ /Paste an amino/){
    $data=$query->param('data'); # the structure data
 
    if(length $data == 0) {
      print $STDOUT "<H2>No protein sequence data was pasted in the text field.<BR>Please Retry</H2>";
      exit;
    }
    print $fhin "$data";
    print $fhin "\n";
    print $STDOUT "<H3>data received= $data</H3>";
 
  }
  else{# file uploaded


    $fileStr=$query->param(Struct);
    $fakeId= $fileStr;
    if(!fileStr){
      print $STDOUT "<H2>No protein sequence file was uploaded.<BR>Please Retry</H2>";
      exit;
    }
    $upData="";
    while(<$fileStr>){
      $upData.=$_;
      print $fhin "$_";
      #print  "$_";
    }
#    if($upData !~ />/){
#      print $STDOUT "<H2>File uploaded not in fasta format.<BR>Please Retry</H2>";
#      exit;
#    }
  }
  close($fhin);


  $fileErr="err.out";
# finish initializations.
  $fileRun="run.out".$jobId;
  #now submit job

  $scrRun=$par{"dirHome"}."predLoci.pl";

  system("$scrRun fileIn=$fileData fileErr=$fileErr emailId=$name protId=$protId orgType=$orgType jobId=$jobId >$fileRun &");

#  $tmpRun=$par{"dirHome"}."dbStruct.pl";
#  if($fakeId=~ /(\/|\\)/){
#    $fakeId=~m /(\/|\\)(\w+?)/;
#    $realId=$2;
#  }
#  else{
#    $realId=$fakeId;
#  }
  #system("$tmpRun $realId $name $jobId $protId>$fileRun &");

}

print $STDOUT $query->end_html;


	 
