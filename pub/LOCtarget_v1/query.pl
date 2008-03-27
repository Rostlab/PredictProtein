#!/usr/local/bin/perl 

#use CGI;
use CGI qw/:push/;
use CGI::Carp qw(fatalsToBrowser);
#use Mail::Sendmail;
use FileHandle;

$fhin="FHIN";

$STDOUT="STDOUT";
STDOUT->autoflush(1);

$par{'loctarget_url'}     ="http://cubic.bioc.columbia.edu/cgi-bin/var/nair/LOCtarget";
$par{'loctarget_db'}      ="http://cubic.bioc.columbia.edu/db/LOCtarget/";
$par{'dirHome'}       ="/home/httpd/cgi-bin/var/nair/LOCtarget/";
$par{'dirScr'}        =$par{'dirHome'}."/scr/";
$par{'dirDb'}         =$par{'dirHome'}."/db/";
$par{'locDb'}         =$par{'dirDb'}."loctarget.database";
$par{'dirImg'}        =$par{'dirHome'}."img/";



$HEADER = "<BODY BGCOLOR='#FFFFFF'><H1><CENTER> <FONT COLOR='RED'><STRONG> LOCtarget: database of predicted subcellular localization for structural genomics targets from TargetDB.</STRONG></COLOR><FONT COLOR='black'></CENTER></H1>";




$query = new  CGI;
print $STDOUT $query->header;
print $STDOUT $query->start_html( 'LOCtarget Online' );


if ( !$query->param) {
  #the entry form

  #print $STDOUT "$HEADER";

  &print_header();

  print $STDOUT $query->startform();
  #print $STDOUT "<H1> aaascroll=$query->param(scroll)</H1>";
  $remoteDat=$query->remote_user || 'anonymous@' . $query->remote_host;
  system("echo $remoteDat >>log/userLog");

  print $STDOUT "<FONT SIZE='-1' COLOR='blue'><ALIGN='LEFT'>Select the type of object you are looking for and optionally type in a name or a wildcard pattern (? for any one character. * for zero or more characters). If no name is entered,
the search displays all objects of the selected type.";

  print $STDOUT "<P><TABLE>",
  "<TR>",
  "<TD>",
  $query->radio_group(
		      -name=>'type',
		      -Values=>['TargetDB identifier','Subcellular localization class (nuclear, cytoplasmic etc.)','Prediction method (Loc3D, predictNLS, LOChom, LOCkey)'],
		      -default=>'TargetDB identifier',
		      -cols=>1),
  "</TD>",
  "</TR>",
  "<TR>",
  "<TD>",
    $query->textfield('search',$search,25),
  "</TD>",
  "</TR></TABLE></P>";  


  $scroll=0;
  print $STDOUT $query->hidden(
		 -name=>'scroll',
		 -default=>$scroll,
		);

#  $query->param('scroll',$scroll);
  $tmp=$query->param(scroll);
  #print $STDOUT "<h1>tm=$tmp</h1>";

  print $STDOUT $query->submit;

  print $STDOUT "<H1> <FONT SIZE = '+2'><A HREF='$par{'loc3d_url'}/browse.pl'>Browse </A> the contents of the LOCtarget database.</H1>";
  print $STDOUT $query->endform;
  
}
else{

  @list=$query->param();
  $scroll=$query->param(scroll);
  $object= $query->param(type);# the object type that is searched
  $search=$query->param(search); 



  &print_header();
  print $STDOUT "<H2> Results Page: </H2>";
  #print $STDOUT "<H1> bbbscroll=$scroll object=$object search=$search list=@list </H1>";


  $query->delete_all();

  if($object=~/TargetDB/){
    $field=0;
  }
  elsif($object=~/Subcellular/){
    $field=3;
  }
  else{
    $field=2;
  }

  #now read database into memory
  open($fhin,$par{'locDb'}) || die "could not open fileDb=$par{'locDb'}\n";
  while(<$fhin>){
    if (/^\#/){
      next;
    }
    chomp;
    @tmp=split(/\t/,$_);
    @{$db{$tmp[0]}}=@tmp;
  }
  close $fhin;

  #proc search string
  $search=~s /\s//g;
  if(length $search ==0){
    $search=".*";
  }

  $search=~s/\*/\.\*/g;
  $search=~s/\?/\./g;

  #now grep


#  @tmpRes = grep /$search/i ,map $db{$_}[$field]  ,keys %db; # 

  foreach $id (keys %db){
    if(grep /$search/i, $db{$id}[$field]){
      push @tmpRes,$id;
    }
  }


  #sort by confidence!
  #print $STDOUT "<H2>@tmpRes</H2>";
  @res= sort {$db{$b}[3]<=>$db{$a}[3]} @tmpRes;

  if(!$res[0]){
    $numFound=0;
  }
  else{
    $numFound=$#res+1;
  }


  $numPages=int($#res/50)+1;
  
  print $STDOUT "<H2>Number of results matching search query: <STRONG><FONT COLOR='red'>$numFound </FONT></STRONG></H2>";

  #now display results
   
  if ($numFound ==0) {
    print $STDOUT "<H2>No objects found using search query: $search</H2>";
    exit;
  }

  &res_header();

  if($scroll+1 == $numPages){
    $beg=$scroll*50;
    $term=$#res;
  }
  else{
    $beg=$scroll*50;
    $term=$beg+49;
  }

 RES:
  foreach $i ($beg..$term) {

    $id=$res[$i];
    if($id=~/_/){
      $pdbId=$id;
      $pdbId=~s/_\w$//;
    }
    else{
      $pdbId=$id;
    }
    print $STDOUT "<tr valign='top'>",
      "<td><a href='ftp://cubic.bioc.columbia.edu/pub/cubic/LOCtarget/fasta/$pdbId.fasta'>$id</a></td>";

    foreach $j (1..$#{$db{$id}}) {
      if (! defined $db{$id}[$j]) {
	print $STDOUT "</tr>";
	next RES;
      } elsif ($db{$id}[$j] eq 0) {
	print $STDOUT "<td> No details.</td>";
      } else {
	print $STDOUT "<td> $db{$id}[$j]</td>";
      }
    }
    print $STDOUT "</tr>";
  }
  print $STDOUT "</TABLE>";

  if($scroll+1 == $numPages){
    exit;
  }

  print $STDOUT $query->startform();
  $scroll++;


  print $STDOUT $query->hidden(
		 -name=>'scroll',
		 -default=>$scroll,
		);

  print $STDOUT $query->hidden(
		 -name=>'type',
		 -default=>$object,
		);
  print $STDOUT $query->hidden(
		 -name=>'search',
		 -default=>$search,
		);


  print $STDOUT "<BR><BR> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp;";

  print $query->image_button(-name=>'next',
			     -src=>'http://cubic.bioc.columbia.edu/db/LOCtarget/next.gif',
			    -align=>'MIDDLE');	

  print $STDOUT "</BODY>";
  print $STDOUT $query->endform;
}




sub res_header {

  print $STDOUT "<H2> <FONT COLOR='blue' SIZE='-1'> For each protein, subcellular localization predicions are made by upto 4 different methods: predictNLS (nuclear localization signals), LocHom (using homology), LocKey (using keywords) and LOCnet (using neural networks). 'Localization predicition 1' is our most confident subcellular localization prediction for the protein.</FONT></H2>";

  print $STDOUT "<TABLE border='2' cellpadding='8' cellspacing='3'>";
  print $STDOUT "<tr bgcolor='silver'>",
    "<th rowspan=2> PDB identifier</th>";
  
  foreach $i (1..4){
    print $STDOUT "<th colspan=4 rowspan=1> Localization prediction $i</th>";
  }
  print $STDOUT "</tr><tr bgcolor='silver'>";
  
  foreach $i (1..4){
    print $STDOUT "<th rowspan=1> Method </th>",
      "<th rowspan=1> Loci </th>",
	"<th rowspan=1> Confidence</th>",
	  "<th rowspan=1> Details</th>";
	      
  }

}

sub print_header {


  print $STDOUT '<BODY BGCOLOR="#FFFFFF">',
  '<TABLE COLS=2 CELLPADDING=2 WIDTH="100%">',
  '<TR VALIGN=MIDDLE><TD VALIGN=MIDDLE WIDTH="15%">',
  '<CENTER>',
  '<A HREF="browse.pl"><IMG ALIGN=CENTER WIDTH=66 HEIGHT=66 SRC="http://cubic.bioc.columbia.edu/db/LOCtarget/LOCtarget.gif"></A>',
  '</CENTER>',
  '</TD>',
  '<TD VALIGN=MIDDLE WIDTH="85%">',
  '<H1>',
  'LOCtarget:',
  '<FONT SIZE="-1">(database of predicted subcellular localization for structural genomics targets.)</FONT>',
  '</H1>',
  '</TD></TR>',
  '</TABLE>';

}
