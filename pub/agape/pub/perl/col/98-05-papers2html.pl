#!/usr/sbin/perl -w
#
#
# take in papers written as HTML by word 6
# put out: links to figures and references
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
#require "ctime.pl";
#require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
require "lib-ut.pl"; require "lib-br.pl"; 

#$ARGV[1]="sisyphus.html";		# xx mac
#$ARGV[2]="Dfig/CABIOS97/";	# xx mac

if ($#ARGV<2){print "goal:     add links to papers saved in Word 6 as HTML\n";
	      print "note 1:   format references in style 'xx-ms2www'\n";
	      print "note 2:   give file its final name (for TOC)\n";
	      print "usage:    'script paper dirFig '\n";
	      exit;}

$fileIn=$ARGV[1];
$dirFig=$ARGV[2]; $dirFig.="/" if ($dirFig !~ /\/$/);
foreach $arg (@ARGV){next if ($arg eq $ARGV[1] || $arg eq $ARGV[2]);
		     if   ($_=~/^ol/){$par{"order"}=1;}
		     elsif($_=~/^ul/){$par{"order"}=0;}}
$title=$fileIn;$title=~s/\.html//g;
$fileToc=$title."Toc.html";

$contact="contact e-mail:<A HREF=\"mailto:rost\@embl-heidelberg.de\">rost\@embl-heidelberg.de</A>\n";

$endOfDoc="<P><BR><P>\n"."<!--"."=" x 50 ."-->\n\n"."<HR>\n"."<P>".
    "<A HREF=\"../index.html\"><IMG WIDTH=50 HEIGHT=50 ALIGN=MIDDLE SRC=\"../Dfig/icon-br-home.gif\" ALT=\"Rost Home\"></A> \n".
    "<A HREF=\"mailto:rost\@EMBL-Heidelberg.de\"><IMG WIDTH=50 HEIGHT=50 ALIGN=MIDDLE SRC=\"../Dfig/icon-br-home-mail.gif\" ALT=\"Mail to Rost\"></A> \n".
    "<A HREF=\"http://www.lion-ag.de/\"> <IMG WIDTH=50 HEIGHT=50 ALIGN=MIDDLE SRC=\"../Dfig/icon-lion.gif\" ALT=\"LION Home\"></A> \n".
    "<A HREF=\"http://www.embl-heidelberg.de/\"> <IMG WIDTH=50 HEIGHT=50 ALIGN=MIDDLE SRC=\"../Dfig/icon-embl.gif\" ALT=\"EMBL Home\"></A> \n".
    "<A HREF=\"http://www.expasy.hcuge.ch\"><IMG WIDTH=50 HEIGHT=50 ALIGN=MIDDLE SRC=\"../Dfig/icon-expasy.gif\" ALT=\"ExPasy\"></A>\n".
    "<A HREF=\"http://www.embl-heidelberg.de/predictprotein/predictprotein.html\"><IMG ALIGN=MIDDLE WIDTH=50 HEIGHT=50 SRC=\"../Dfig/icon-pp.gif\" ALT=\"PredictProtein\"></A>\n".
    "</BODY>\n".
    "</HTML>\n";
$begOfDoc="<HTML>\n"."<HEAD>\n".
    "<META NAME=\"FirstName\" value=\"Burkhard\">\n"."<META NAME=\"LastName\" value=\"Rost\">\n".
    "<META name=\"description\" content=\"KEYWORDSxyz\"\n".
    "<META name=\"keywords\"    content=\"KEYWORDSxyz\"\n".
    "<TITLE>TITLExyz<\/TITLE>\n".
    "<\/HEAD>\n"."\n"."<!--"."=" x 50 ."-->\n\n"."<BODY>\n";

$fhin="FHIN";$fhout="FHOUT";$fileOut="PERLED-".$fileIn;

				# --------------------------------------------------
				# (1) read all, join <Hx>name \n </Hx> into single
&open_file("$fhin", "$fileIn");

$#content=0;$Lhold=$Lhold1=0;
while (<$fhin>) {$_=~s/\n//;
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
		     push(@content,$tmp);}}close($fhin);
				# --------------------------------------------------
				# (2) digest the content of the file
$#rd=$#cap=0;$Lmerge=$LmergeRef=$Lref=$Lcap=$Ltab=$kwdHdr=$LkwdHdrFin=$eqnNum=0;
$line=$lineRef=$kwdNow="";
foreach $_ (@content){
    next if ($_ =~ /^\<(META|\/?HEAD|BODY|\/?TITLE|HTML)/i); # skip from reading
    if ($_ =~ /<H1>(.+)$/){
	$title=$1;$title=~s/<.?CENTER>|<.?H1>|<.?B>//gi;}
    $Lref=1 if ($_ =~ /<H\d>.*reference/i);
    $Lcap=1 if ($_ =~ /<H\d>.*figure caption/i);
    $Ltab=1 if ($_ =~ /<H\d>.*table caption/i);
    if ($_ =~ /\(e?q?n?\.?\s*(\d+)\)\s*$/){
	$eqnNum=$1;}

    $lineRd=$_;
    if (! $LkwdHdrFin){		# extract keywords
	if   ($lineRd =~ /Key words[\s:\t]+(.*)/i){$kwdHdr=$1;$kwdHdr=~s/^\s*<.*>\s*//g;
						   if ($kwdHdr=~/[<]/){$kwdHdr=~s/<.*$//g;$LkwdHdrFin=1;}}
	elsif($kwdHdr && $lineRd=~/[<>]/)         {$LkwdHdrFin=1;}
	elsif($kwdHdr)                            {$kwdHdr.="$lineRd";}}
				# links to references
    if (! $Lref && $lineRd=~/\[xxx \d/){
	$lineRd=&linkToRef($lineRd);}
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
    if ($Lcap){			# store figure captions
	&processCapFig($lineRd) if ($lineRd !~ /<H\d>.*figure caption/i);}
    if ($Ltab){			# store figure captions
	&processCapTab($lineRd) if ($lineRd !~ /<H\d>.*table caption/i);}
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
				# (3) write header
				# --------------------------------------------------
&open_file("$fhout", ">$fileOut");
$title=~s/\<FONT SIZE=\d+\>|\<\/FONT\>//g;
$kwdHdr=~s/\.\s*$//g;
$begOfDoc=~s/TITLExyz/$title/;
$begOfDoc=~s/KEYWORDSxyz/$kwdHdr/g;
print $fhout $begOfDoc;

                                # ------------------------------
                                # (4) write body
$#toc=0;$Lref=0;                # ------------------------------
foreach $line (@rd){
    $lineRd=$line;
#    print "xx rd=$lineRd\n";
				# fill in directory for images
    if ($line=~/SRC=\"Image/){
	$line=~s/(Image)/$dirFig$1/g;}
				# fill in address
    if    ($line=~ /<H\d>.*abstract/i){
	$line="<P>\n"."$contact"."<P><BR><P>\n\n\n"."<!--"."=" x 50 . "-->\n".
	    "<H2><I><A HREF=\"$dirFig$fileToc\" TARGET=\"$dirFig$fileToc\">".
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
	    "<CENTER> <A HREF=\"$dirFig$fig\"><IMG ALIGN=ABSMIDDLE SRC=\"$dirFig$fig\" ".
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
	$Lref=1;}
    elsif ($Lref && ($line=~/xxx /)){
	@tmp=&linkFromRef($line);
	$line="<P><BR>";foreach $tmp(@tmp){$line.="$tmp";}$line.="<BR><P>";}
    print $fhout "$line\n";
}
print $fhout "</UL>\n\n";
print $fhout "$endOfDoc\n";
close($fhout);
				# --------------------------------------------------
				# table of contents
				# --------------------------------------------------
$fileInPath="../../$fileIn";
&open_file("$fhout", ">$fileToc");
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
print $fhout $endOfDoc;
print "--- TOC END\n";
close($fhout);


print "--- ","-" x 80,"\n";
print "--- output in :                \t $fileOut\n";
print "--- toc    in :                \t $fileToc\n";
print "--- put links (and toc) into : \t $dirFig\n";
print "--- ","-" x 80,"\n";
exit;

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
    ($tmp,@tmp)=split(/xxx /,$in);
    @out=("<UL>\n");
    foreach $tmp(@tmp){
#	next if ($tmp eq $tmp[1]); # ignore first (as starts with '  xxx 1')
	$tmp1=$tmp;$tmp1=~s/^\s*(\d+) .*$/$1/;
	$tmp1="<A NAME=\"ref$tmp1\">$tmp1<\/A>".". ";
	$tmp=~s/^\d+ (.*)$/$tmp1 $1/;
	push(@out,"<LI> $tmp\n");
    }
    push(@out,"</UL>\n");
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
    if ($lineTmp=~/eq\D*\s+\d+\s*[\-,]?\s*\d*/i){ # allow many
	$tmp1=$lineTmp; $ct=0;
	while ($tmp1 =~ /eq\D*\s+\d+\s*[\-,]?\s*\d*/i && $ct<10){
	    ++$ct;
	    $tmp1=~s/(eq\D*\s+\d+\s*[\-,]?\s*\d*)//io;
	    $tmp2=$1;
	    $range=$tmp2;$range=~s/^\D*(\d+\s*[\-,]?\s*\d*).*$/$1/;$range=~s/\s//g;
            @num=&get_range($range);$new="";
	    foreach $num(@num){
		$new.=" <A HREF=\"\#eqn$num\">eqn\. $num<\/A>, ";}
	    $new=~s/, $//g;
	    $lineTmp=~s/$tmp2/$new /;}}
    return($lineTmp);
}				# end of iterateInTxtLinksEqn

