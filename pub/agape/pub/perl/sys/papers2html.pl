#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="papers written as HTML by word 98 to finals (first save in word5, then re-import\n".
    "     \t note: this is to correct for the MS-EndNote shit";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Jul,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

#$ARGV[1]="sisyphus.html";		# xx mac
#$ARGV[2]="Dfig/CABIOS97/";	# xx mac

				# ------------------------------
				# defaults
%par=(
      'contact_email',          "rost\@columbia.edu",
      'templateIndex',          "/home/cubic/public_html/MAT/papTemplateIndex.html",
      'templateAbstr',          "/home/cubic/public_html/MAT/papTemplateAbstr.html",
#      'templateIndex',          "papTemplateIndex.html",
#      'templateAbstr',          "papTemplateAbstr.html",
      'order',                  0, # =1 -> ordered reference list
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV < 2){		# help
    print  "goal:  $scrGoal\n";
    print  "use:  '$scrName paper title'\n";
    print  "note1: format references in style 'xx-ms2www'\n";
    print  "note2: give file its final name (for TOC)\n";
    print  "opt:   \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s %-20s %-s\n","","ol",   "no value",   "references numbered";
    printf "%5s %-15s %-20s %-s\n","","ul",   "no value",   "references not numbered";
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;


$fileIn=$ARGV[1]; push(@fileIn,$fileIn);
$title= $ARGV[2]; $dirOut=$title;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    next if ($arg eq $ARGV[2]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif ($arg=~/^ol/)                   { $par{"order"}=   1;}
    elsif ($arg=~/^ul/)                   { $par{"order"}=   0;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);


if (! -d $dirOut) {
    $dirOut=~s/\/$//g;
    $title=$dirOut;
    system("mkdir $dirOut");}
$dirOut.="/"                    if (length($dirOut)>1 && $dirOut !~/\/$/);

$contact="contact e-mail:<A HREF=\"mailto:".
    $par{"contact_email"}."\">".$par{"contact_email"}."</A>\n";

$fileToc=      $dirOut."toc.html";
$fileOut=      $dirOut."paper.html" if (! defined $fileOut || ! $fileOut);
$fileOutAbstr= $dirOut."abstract.html";
$fileOutIndex= $dirOut."index.html";


				# --------------------------------------------------
				# bottom links for
				# doc in: public_html/DIR
$endOfDoc="<P>".
    "</BODY>\n".
    "</HTML>\n";

$begOfDoc="<HTML>\n"."<HEAD>\n".
    "<META NAME=\"FirstName\" value=\"CUBIC\">\n"."<META NAME=\"LastName\" value=\"Rost Group\">\n".
    "<META name=\"description\" content=\"Papers\">\n".
    "<META name=\"keywords\"    content=\"KEYWORDSxyz\">\n".
    "<TITLE>TITLExyz<\/TITLE>\n".
    "<\/HEAD>\n"."\n"."<!--"."=" x 50 ."-->\n\n"."<BODY style=\"background:white\">\n";

$fhin="FHIN";$fhout="FHOUT";

				# --------------------------------------------------
				# (1) read all, join <Hx>name \n </Hx> into single
open($fhin, $fileIn) || die "*** failed opening in=$fileIn\n";

$#content=0;$Lhold=$Lhold1=0;
while (<$fhin>) {
    $_=~s/\n//;
    if   (! $Lhold && ($_ =~ /<H\d/ && $_ !~ /<\/H\d/) ){
	$Lhold=1; $tmp=$_;}
    elsif($Lhold && ($_ =~ /<\/H\d/) ){
	$Lhold=0; $tmp.=" $_";}
    elsif($Lhold){
	$tmp.=" $_";}
    elsif(! $Lhold1 && ($_=~/(tab|fig|eqn)\./ && $_ !~/(tab|fig|eqn)\.\s+\d+/) ){
	$tmp=$_; $Lhold1=1;}
    elsif($Lhold1){
	$tmp.=" $_"; $Lhold1=0; $tmp=~s/(tab|fig|eqn)(\.\s+\d+)/$1$2\n/}
    else {$tmp=$_;}
    if (! $Lhold && ! $Lhold1){
	$tmp=~s/\s\s+/ /g;
	push(@content,$tmp);}}
close($fhin);
				# --------------------------------------------------
				# (2) move <xyz> </xyz> into one line
$tmp=join("\t",@content);
				# remove shit
$tmp=~s/<P>\&nbsp\;<\/P>//g;
$tmp=~s/\&\#9\;/ /g;
$tmp=~s/<.?DIR>//g;

$tmp=~s/<FONT[^>]*>[\s\t\n]*<\/FONT>//g;
@tmp=split(/<\/FONT>/,$tmp); $#content=0;
foreach $tmp (@tmp) {
    if    ($tmp=~/<FONT FACE..times/i) {
	$tmp=~s/<FONT FACE=[^>]+>//g;}
    elsif ($tmp=~/<FONT/) {
	$tmp.="</FONT>\n";}
				# purge ending empties
    $tmp=~s/[\s\t\n]*$//g;
				# all tabs to \n
    $tmp=~s/\t/\n/g;
				# newline after '</P>'
    $tmp=~s/(<\/P>)[^\n]/$1\n/g;
				# delete: <XYZ> empty </XYZ>
    $tmp=~s/<B>[\t\s\n]*<\B>//g;
    $tmp=~s/<I>[\t\s\n]*<\I>//g;
    $tmp=~s/<FONT>[\t\s\n]*<\FONT>//g;

    $tmp=~s/\n[\s\t\n]*/\n/g;	# multiple '\n' in row ..
    $tmp=~s/\n(<\/FONT>)/$1/g;	# remove '\n' from '\n</FONT> '
    @tmp2=split(/\n/,$tmp);
    push(@content,@tmp2);}
				# ------------------------------
				# (2b) get abstract
$#abstract=$Lok=0;
foreach $tmp (@content) {
    last if ($tmp=~/end abstract/i ||
	     ($Lok && (
		       $tmp=~/introduction/i ||
		       $tmp=~/<H[123]>/)));
    if ($tmp=~/H\d>abstract/i) {
	$Lok=1;
	next;}
    next if (! $Lok);
    push(@abstract,$tmp);}
				# (2c) get paper title
$title_paper=0;
foreach $tmp (@content) {
    if ($tmp=~/<TITLE>(.*)<\/TITLE>/){
	$title_paper=$1; $title_paper=~s/\n//g;
	last;}}
$title_paper=$title             if (! $title_paper);
    

				# --------------------------------------------------
				# (3) digest the content of the file
$#rd=$#cap=0;$Lmerge=$LmergeRef=$Lref=$Lcap=$Ltab=$kwdHdr=$LkwdHdrFin=$eqnNum=0;
$line=$lineRef=$kwdNow="";
foreach $_ (@content){
    next if ($_ =~ /^\<(META|\/?HEAD|BODY|\/?TITLE|HTML)/i); # skip from reading

				# corrections for MS shit
    $_=~s/<P>\&nbsp\;<\/P>\s*\n//g;
    $_=~s/<FONT FACE=\.[a-zA-Z]+(\s+SIZE=\d+)?\.>//g;
    $_=~s/<\/FONT>//g;
    next if (length($_)<1);
    $_=~s/\&\#9\;//g;
    if ($_ =~ /<H1>(.+)$/){
	$title=$1;
	$title=~s/<.?CENTER>|<.?H1>|<.?B>//gi;}
    $Lref=1    if ($_ =~ /<H\d>.*reference/i);
    $Lcap=1    if ($_ =~ /<H\d>.*figure caption/i);
    $Ltab=1    if ($_ =~ /<H\d>.*table caption/i);
				# --------------------------------------------------
				# link equation numbers ( ending on: (n) )
    $eqnNum=0;
    if ($_ =~ /[\t\s]+\(e?q?n?\.?\s*(\d+)\)\s*\n*$/) {
	$eqnNum=$1; }

    $lineRd=$_;
    if (! $LkwdHdrFin){		# extract keywords
	if   ($lineRd =~ /Key words[\s:\t]+(.*)/i){
	    $kwdHdr=$1;$kwdHdr=~s/^\s*<.*>\s*//g;
	    if ($kwdHdr=~/[<]/){
		$kwdHdr=~s/<.*$//g;
		$LkwdHdrFin=1;}}
	elsif($kwdHdr && $lineRd=~/[<>]/)         {
	    $LkwdHdrFin=1;}
	elsif($kwdHdr)                            {
	    $kwdHdr.="$lineRd";}}
				# links to references
    if (! $Lref && $lineRd=~/\[xxx \d/){
	$lineRd=&linkToRef($lineRd);
#	print "xx ref (link) out  =$lineRd\n";
    }
	
				# merge <h1> /n </h1> into one line
    if (($lineRd =~ /<(H\d+|FONT)/) && ($lineRd !~ /<\/$1/) && (! $Lmerge)){
	$Lmerge=1;$line=$lineRd;$keyMerge=$1;
	print "--- wants to merge '$lineRd'\n";
	next;}
    elsif ( (! $Lmerge) && (! $LmergeRef) && $Lref && ($lineRd!~/<P>/)){
#	print "xx starts merging ref '$lineRd'\n";
	$LmergeRef=1;$lineRef=$lineRd;
	next;}
    elsif (! $Lmerge) {
	$line=$lineRd;}

    $Lcap=$Ltab=0 if ($Lref);
				# store figure captions
    &processCapFig($lineRd)     if ($Lcap && $lineRd !~ /<H\d>.*figure caption/i);
				# store figure captions
    &processCapTab($lineRd)     if ($Ltab && $lineRd !~ /<H\d>.*table caption/i);

    if ($eqnNum){		# label equations
	$ref="eqn".$eqnNum;
	$line="<CENTER><A NAME=\"$ref\">\n".$line."\n<\/A></CENTER>\n";
	$eqnNum=0;}

    if ($Lmerge){
	if ($lineRd =~ /\/$keyMerge/){	# finish merging
	    print "--- merging key found=$keyMerge, line=$lineRd'\n";
	    $Lmerge=0;
	    $line=$line." ".$lineRd;}
	else {			# continue merging
	    $line=$line." ".$lineRd;
	    print "-*- WARN still not found merger key=$keyMerge, line=$lineRd'\n";
	    next;}}
    elsif ($LmergeRef){
	if (($lineRd !~ /<P>/)&&($lineRd !~ /<BR>/)){
	    $lineRef=$lineRef." ".$lineRd;
	    next;}
	else {
	    $LmergeRef=0;
	    $line=$lineRef." ".$lineRd;}}
    push(@rd,$line) if (! $Lcap && ! $Ltab); # store (ignore captions)
    $line="";			# reset
    $lineRef="";		# reset
}

				# --------------------------------------------------
				# (4) write header
				# --------------------------------------------------
open($fhout, ">".$fileOut) || die "*** ERROR opening output=$fileOut\n";

$title=~s/\<FONT SIZE=\d+\>|\<\/FONT\>//g;
$kwdHdr=~s/\.\s*$//g;
$begOfDoc=~s/TITLExyz/$title/;
$begOfDoc=~s/KEYWORDSxyz/$kwdHdr/g;
print $fhout $begOfDoc;

                                # ------------------------------
                                # (5) write body
$#toc=0;$Lref=0;                # ------------------------------
$#references=0;
foreach $line (@rd){
    $lineRd=$line;
#    print "xx rd=$lineRd\n";
				# fill in directory for images
    if ($line=~/SRC=\"Image/){
#	$line=~s/(Image)/$dirOut$1/g;}
	$line=~s/(Image)/$1/g;}
				# fill in address
    if    ($line=~ /<H\d>.*abstract/i){
	$line="<P>\n"."$contact"."<P><BR><P>\n\n\n"."<!--"."=" x 50 . "-->\n".
	    "<H2><I><A HREF=\"$fileToc\" TARGET=\"$fileToc\">".
		"Table of Contents</A></I></H2>\n"."<P><HR><P>\n\n".
		    "<!--"."=" x 50 . "-->\n".
			"<CENTER><H1><A NAME=\"ABSTRACT\">Abstract</A></H1></CENTER>\n<P>\n";
	push(@toc,"H2=ABSTRACT, txt=Abstract");}
				# headings 2-n
    elsif ($line =~ /<(H[2-9])>/){
	$level=$1;
	$txt=$line;$txt=~s/^.*<H\d>(.*)<\/H.*$/$1/;$txt=~s/<\/?[a-zA-Z0-9]+>//g;
	$ref=$txt; $ref=~s/\s/_/g;$ref=~s/[^a-zA-z0-9_]//g;$ref=~tr/[a-z]/[A-Z]/;$ref=~s/^[^0-9A-Z]*|[^0-9A-Z]*$//g;
	$toc=$level."=".$ref.", txt=".$txt;
	print "--- toc entry=$toc\n";
	push(@toc,$toc);
	$line="\n<$level><A NAME=\"$ref\">$txt</A></$level>\n<P>\n";
	if ($line=~ /<H2/){
	    $line="<P><BR><P>\n"."<!--"."=" x 50 . "-->\n".$line;}}
				# links to figures and tables
				# recognise '>>> <<<' for insert figure here
    elsif ($line =~ /\&gt\;\&gt\;\&gt\;(.+)\&lt\;\&lt\;\&lt\;/){
	$line=  $1;   $line=~s/\s|\.//g;$line=~tr/[A-Z]/[a-z]/; 
	$ref=   $line; $ref=~s/table/tab/; $ref=~s/[Ff]igure/fig/;
	$fig=   $line.".gif" if ($ref=~/fig/);
	$what=  "Tab"        if ($ref=~/tab/);
	$what=  "Fig"        if ($ref=~/fig/);
	$figNum=$ref; $figNum=~s/(fig|tabl?e?|\.gif)//g;
				# add captions
	if (defined $cap{"$ref"}){
	    $add=$cap{"$ref"}."\n<P><BR><P>\n\n";$add=~s/(<\/B>)/$1\n/;}
	elsif ($ref=~/tab/){
	    print "-*- WARN no caption for table ($ref)\n";
	    $add="</B>\n<P>\n<P><BR><P>\n\n";}
	else {print "XXXX misising fig CAP for figNum=$figNum, ref=$ref,\n";
	      print "xx line  =$line,\n";
	      print "xx lineRd=$lineRd,\n";
	      exit;}
	$line="\n<P><BR><P>\n<HR>\n<CENTER><B><A NAME=\"$ref\">$what\. $figNum</A></B></CENTER>\n".
	    "<CENTER> <A HREF=\"$fig\"><IMG ALIGN=ABSMIDDLE SRC=\"$fig\" ".
		" ALT=\"$fig\"> <\/A></CENTER>\n"."\n".
		    "<P><B>$add";}
    elsif (! $Lref) {		# linke to figures, tables, equations in text
	if ($line=~/fig\D*\s+\d+/i) { # fig
	    $line=&iterateInTxtLinksFig($line);
	    print "--- in-text link (fig)=$line,\n";}
	if ($line=~/tab\D*\s*\d+/i) { # tab
	    $line=&iterateInTxtLinksTab($line);
	    print "--- in-text link (tab)=$line,\n";}
	if ($line=~/(eq\.|eqn\.|equation|eqs\.)\s+\d+/i)  { # eqn
	    $line=&iterateInTxtLinksEqn($line);
	    print "--- in-text link (eqn)=$line,\n";}}
				# references into list
    if ($lineRd=~/<H\d+>.*[Rr]eferences/i){
	$Lref=1;
	if ($lineRd=~/xxx /) {
	    $tmp=$lineRd;$tmp=~s/^.*(xxx .*)$/$1/g;
	    push(@references,&linkFromRef($tmp));
	    $lineRd=~s/(<P>)?xxx .*$//g;}}

    elsif ($Lref && ($line=~/xxx /)){
	push(@references,&linkFromRef($line));
#	@tmp=&linkFromRef($line);
#	$line="<P><BR>" . join('',@tmp). "<BR><P>"; }
	next;
    }
    print $fhout "$line\n";
}

				# finally write references
print $fhout "<UL>\n";
print $fhout join("\n",@references,"\n");
print $fhout "</UL>\n\n";
print $fhout "$endOfDoc\n";
close($fhout);
				# --------------------------------------------------
				# (6) table of contents
				# --------------------------------------------------
$fileInPath="../../$fileIn";
open($fhout, ">".$fileToc) || die "*** ERROR opening toc=$fileToc\n";
print $fhout 
    "<HTML>\n<HEAD><TITLE>$title</TITLE></HEAD>\n<BODY>\n",
    "<H1>Table of contents</H1>\n",
    "<H2><A HREF=\"$fileInPath\">for: $title </A><\H2> ",
    "<P>\n"."$contact","<P><BR><P>\n\n\n".
    "<P><HR><P>\n\n","<!--"."=" x 50 . "-->\n<P>\n\n",
    "<UL>\n";
$prev="H2";$numPrev=2;
print "--- \n--- write toc file $fileToc\n--- TOC BEGIN\n";
foreach $toc (@toc){
    print "--- TOC make entry=$toc\n";
    $toc=~s/(H\d)=//;$level=$1;
    ($ref,$txt)=split(/,\s*txt=\s*/,$toc);$ref=~s/\W*$//g;
    $numLevel=$level;$numLevel=~s/H//;$numLevel=~s/\s//g;
    $toc="<A HREF=\"$fileInPath"."\#"."$ref\"> $txt </A>";
    if ($level ne "$prev"){
	if ($numLevel>$numPrev){
	    $toc="<UL>\n"."<LI>\t$toc";}
	else {
	    $toc="</UL>\n"."<LI>\t$toc";}
	$prev=$level;$numPrev=$numLevel;}
    else {
	$toc="<LI>\t$toc";}
    print $fhout "$toc\n";}
print $fhout "</UL>\n";
print "--- TOC END\n";
close($fhout);
				# --------------------------------------------------
				# (7) copy index.html and abstract.html
				# --------------------------------------------------
				# index: 
if (defined $par{"templateIndex"} && -e $par{"templateIndex"}) {
    open($fhin,$par{"templateIndex"}) ||
	die "*** ERROR $scrName: failed opening templateIndex=".$par{"templateIndex"}."\n";
    open($fhout,">".$fileOutIndex) ||
	die "*** ERROR $scrName: failed opening outIndex=".$fileOutIndex."\n";
    while(<$fhin>){
	$_=~s/(<TITLE>.*)title_xx/$1$title/;
	$_=~s/title_xx/$title_paper/g;
	print $fhout $_;}
    close($fhout);
    close($fhin); }
				# abstr: 
if (defined $par{"templateAbstr"} && -e $par{"templateAbstr"}) {
    open($fhin,$par{"templateAbstr"}) ||
	die "*** ERROR $scrName: failed opening templateAbstr=".$par{"templateAbstr"}."\n";
    open($fhout,">".$fileOutAbstr) ||
	die "*** ERROR $scrName: failed opening outAbstr=".$fileOutAbstr."\n";
    $abstract=join("\n",@abstract,"\n");
    while(<$fhin>){
	$_=~s/(<TITLE>.*)title_xx/$1$title/;
	$_=~s/title_xx/$title_paper/g;
	$_=~s/abstract_xx/$abstract/;
	print $fhout $_;}
    close($fhout);
    close($fhin); }
	
				# 

print "--- ","-" x 80,"\n";
print "--- output in :                \t $fileOut\n";
print "--- toc    in :                \t $fileToc\n"      if (-e $fileToc);
print "--- index  in :                \t $fileOutIndex\n" if (-e $fileOutIndex);
print "--- abstr  in :                \t $fileOutAbstr\n" if (-e $fileOutAbstr);
print "---           \n";
print "--- ************************************************************ \n";
print "--- put links (and toc) into : \t $dirOut\n";
print "--- ************************************************************ \n";
print "---           \n";
print "--- ","-" x 80,"\n";
exit;



#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_range                   converts range=n1-n2 into @range (1,2)
#       in:                     'n1-n2' NALL: e.g. incl=1-5,9,15 
#                               n1= begin, n2 = end, * for wild card
#                               NALL = number of last position
#       out:                    @takeLoc: begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    $#range=0;
    if (! defined $range_txt || length($range_txt)<1 || $range_txt eq "unk" 
	|| $range_txt !~/\d/ ) {
	print "*** ERROR in get_range: argument: range=$range_txt, nall=$nall, not digestable\n"; 
	return(0);}
    $range_txt=~s/\s//g;	# purge blanks
    $nall=0                     if (! defined $nall);
				# already only a number
    return($range_txt)          if ($range_txt !~/[^0-9]/);
    
    if ($range_txt !~/[\-,]/) {	# no range given
	print "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n"; 
	return(0);}
				# ------------------------------
				# dissect commata
    if    ($range_txt =~ /\,/) {
	@range=split(/,/,$range_txt);}
				# ------------------------------
				# dissect hyphens
    elsif ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	@range=&get_rangeHyphen($range_txt,$nall);}

				# ------------------------------
				# process further elements with hyphens
    $#range2=0;
    foreach $range (@range){
	if ($range =~ /(\d*|\*)-(\d*|\*)/) {
	    push(@range2,&get_rangeHyphen($range,$nall));}
	else {
            push(@range2,$range);}}
    @range=@range2; $#range2=0;
				# ------------------------------
    if ($#range>1){		# sort
	@range=sort {$a<=>$b} @range;}
    return (@range);
}				# end of get_range

#==============================================================================
sub get_rangeHyphen {
    local ($range_txt,$nall) = @_ ;
    local (@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_rangeHyphen             reads 'n1-n2'  
#       in:                     'n1-n2', NALL (n1= begin, n2 = end, * for wild card)
#                               NALL = number of last position
#       out:                    begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    if ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	($range1,$range2)=split(/-/,$range_txt);
	if ($range1=~/\*/) {$range1=1;}
	if ($range2=~/\*/) {$range2=$nall;} 
	for($it=$range1;$it<=$range2;++$it) {push(@rangeLoc,$it);} }
    else { @rangeLoc=($range_txt);}
    return(@rangeLoc);
}				# end of get_rangeHyphen

#===============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file



#==============================================================================
# library collected (end)
#==============================================================================


# ================================================================================
sub linkToRef {
    local($in)=@_;
    $tmpLine=$in;
    while ($tmpLine=~/\[xxx \d/){
	$tmp2Line=$tmpLine;
	$tmp2Line=~s/\[xxx ([^\]]+)\]//;
	$tmp=$1;$tmp=~s/\s//g;
	@tmp=split(/\;/,$tmp);
	$tmp2="";
	foreach $tmp (@tmp){
	    $tmp2.="<A HREF=\"\#ref$tmp\">$tmp<\/A>".", ";}
	$tmp2=~s/, $//;
	$tmp2=" [".$tmp2."] ";
	$tmpLine=~s/\[xxx ([^\]]+)\]/$tmp2/;
    }
    return($tmpLine);}
# ================================================================================
sub linkFromRef {
    local($in)=@_;local(@out);

    $in=~s/\n//g;
    $in=~s/<P>|<\/P>//g;
    $in=~s/^[^x]*//g;
    @tmp=split(/xxx /,$in);
    $#out=0;
    foreach $tmp (@tmp){
	if ($tmp=~/^(\s*)$/) {
	    next;}
#	next if ($tmp eq $tmp[1]); # ignore first (as starts with '  xxx 1')
	$tmp1=$tmp;$tmp1=~s/^\s*(\d+) .*$/$1/;
	$tmp1="<A NAME=\"ref$tmp1\">$tmp1<\/A>".". ";
	$tmp=~s/^\d+ (.*)$/$tmp1 $1/;
	$tmp=~s/<\/P>[\s\t\n]*$//g;
	push(@out,"<LI> $tmp </LI>\n");
    }
    return(@out);}
# ================================================================================
sub processCapFig {
    local($in)=@_;
				# start kwd: 'Fig. 5.'
    if ($in=~/^\<.*\>\s*([fF]ig[u]?[r]?[e]?\.?\s+\d+)/){
	$kwd=$tmp=$1; $kwd=~s/[Ff]igure/fig/; $kwd=~s/[\.\s]//g; $kwd=~tr/[A-Z]/[a-z]/;
	$kwdNow=$kwd;
	$cap{"$kwd"}="$tmp. ";
	$tmp2=$in;$tmp=~s/\n//g;
	$tmp2=~s/^.*$tmp\s*//g;
	while($tmp2=~/^\<\//){
	    $tmp2=~s/^\s*\<\/[^\>]+\>//g;}$tmp2=~s/^[\s\.]*|\s$//g;
	if (length($tmp2)>0){	# append text after name 'Fig. 5. '
	    $cap{"$kwd"}.="\t$tmp2\n";}}
				# caption text
    elsif (defined $kwdNow && (length($kwdNow)>1) ){
	$cap{"$kwdNow"}.="\t$lineRd\n";}
}

# ================================================================================
sub processCapTab {
    local($in)=@_;
				# start kwd: 'Table 5.'
    if ($in=~/^\<.*\>\s*[tT]abl?e?\.?\s+(\d+)/){
	$kwd="tab".$1;
	$cap{"$kwd"}="$tmp. \n";
	$tmp2=$in;$tmp=~s/\n//g;
	$tmp2=~s/^.*$tmp\s*//g;
	while($tmp2=~/^\<\//){
	    $tmp2=~s/^\s*\<\/[^\>]+\>//g;}$tmp2=~s/^[\s\.]*|\s$//g;
	if (length($tmp2)>0){	# append text after name 'Tab. 5. '
	    $cap{"$kwd"}.="\t$tmp2\n";}}
				# caption text
    elsif (defined $kwdNow && (length($kwdNow)>1) ){
	$cap{"$kwdNow"}.="\t$lineRd\n";}
}

#===============================================================================
sub iterateInTxtLinksFig {
    local($lineTmp) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iterateInTxtLinks           iteratively replacing all pat='Fig. N' to link
#       in:                     $current_line,$mode (mode=fig|eqn|tab)
#       out:                    new line
#-------------------------------------------------------------------------------
    if ($lineTmp=~/fig\D*\s+\d+\s*[\-,]?\s*\d*/i){ # allow many
	$tmp1=$lineTmp; $ct=0;
	while ($tmp1 =~ /fig\D*\s+\d+\s*[\-,]?\s*\d*/i && $ct<10){
	    ++$ct;
	    $tmp1=~s/(fig\D\s+\d+\s*[\-,]?\s*\d*)//io;
	    $tmp2=$1;
	    $range=$tmp2;$range=~s/^\D*(\d+\s*[\-,]?\s*\d*).*$/$1/;$range=~s/\s//g;
            @num=&get_range($range);$new="";
	    foreach $num(@num){
		$new.=" <A HREF=\"\#fig$num\">Fig\. $num<\/A>, ";}
	    $new=~s/, $//g;
	    $lineTmp=~s/$tmp2/$new /;}}
    return($lineTmp);
}				# end of iterateInTxtLinksFig

#===============================================================================
sub iterateInTxtLinksTab {
    local($lineTmp) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iterateInTxtLinks           iteratively replacing all pat='Tab. N' to link
#       in:                     $current_line,$mode (mode=tab|eqn|tab)
#       out:                    new line
#-------------------------------------------------------------------------------
    if ($lineTmp=~/tab\D*\s+\d+\s*[\-,]?\s*\d*/i){ # allow many
	$tmp1=$lineTmp; $ct=0;
	while ($tmp1 =~ /tab\D*\s+\d+\s*[\-,]?\s*\d*/i && $ct<10){
	    ++$ct;
	    $tmp1=~s/(tab\D*\s+\d+\s*[\-,]?\s*\d*)//io;
	    $tmp2=$1;
	    $range=$tmp2;$range=~s/^\D*(\d+\s*[\-,]?\s*\d*).*$/$1/;$range=~s/\s//g;
            @num=&get_range($range);$new="";
	    foreach $num(@num){
		$new.=" <A HREF=\"\#tab$num\">Table $num<\/A>, ";}
	    $new=~s/, $//g;
	    $lineTmp=~s/$tmp2/$new /;}}
    return($lineTmp);
}				# end of iterateInTxtLinksTab

#===============================================================================
sub iterateInTxtLinksEqn {
    local($lineTmp) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iterateInTxtLinks           iteratively replacing all pat='Eqn. N' to link
#       in:                     $current_line,$mode (mode=eqn|eqn|tab)
#       out:                    new line
#-------------------------------------------------------------------------------
    if ($lineTmp=~/\Weq[s\. ]*\d+\s*[\-,]?\s*\d*/i){ # allow many
	$tmp1=$lineTmp; $ct=0;
	while ($tmp1 =~ /\Weq[s\. ]*\d+\s*[\-,]?\s*\d*/i && $ct<10){
	    ++$ct;
	    $tmp1=~s/(\W)(eq[s\. ]*\d+\s*[\-,]?\s*\d*)/$1/io;
	    $tmp2=$2;
	    $range=$tmp2;
	    $range=~s/^\D*(\d+\s*[\-,]?\s*\d*).*$/$1/;$range=~s/\s//g;
            @num=&get_range($range);$new="";
	    foreach $num(@num){
		$new.=" <A HREF=\"\#eqn$num\">eqn\. $num<\/A>, ";}
	    $new=~s/, $//g;
	    $lineTmp=~s/$tmp2/$new /;}}
    return($lineTmp);
}				# end of iterateInTxtLinksEqn

