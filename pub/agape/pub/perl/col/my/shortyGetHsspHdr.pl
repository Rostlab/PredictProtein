#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads HSSP file header, lists short hits";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# default
$par{"minLen"}=      30;
$par{"maxLen"}=     100;
$par{"minRatio"}=     0.7;
$par{"minDistIde"}=  -5;
$par{"maxIde"}=      95;	# maximal percentage seq identity (avoid same)
$par{"organism"}=    "yeast";	# used for title of WWW page
$par{"nperLine"}=    50;	# number of residues per line (HTML sequence)


@kwdDes=("minLen","maxLen","minRatio","minDistIde","maxIde","organism","nperLine"); # a.a
@kwdFin=("id1","len1","nali","seq","len2","lali","ratio","pide","nhit","id2mul");
%formFin=('id1',  "%-s",  'id2mul',"%-s",
	  'len1', "%5d",  'len2',"%5d",  'lali',"%5d", 'nhit',"%5d",
	  'nali', "%5d",  'seq', "%-s",'ratio',"%6.2f",'pide',"%6.2f");
				# ------------------------------
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName hssp-file (or *, or list-of-files)'\n";
    print "opt: \t title=x      (output x.rdb x.html)\n";
    print "     \t fileOutRdb=x\n";
    print "     \t fileOutHtml=x\n";
    print "     \t noNali       (dont write NALI column)\n";
    print "     \t noSeq        (dont write Sequence column)\n";
    print "     \t noSingle     (dont write sequences without ali)\n";
    print "     \t nperLine=",  $par{"nperLine"},  "      (default for WWW file seq)\n";
    print "     \t organism=",  $par{"organism"},  "      (default for WWW file title)\n";
    print "     \t minLen=",    $par{"minLen"},    "      (min length of hit considered)\n";
    print "     \t maxLen=",    $par{"maxLen"},    "      (max length of hit considered)\n";
    print "     \t minRatio=",  $par{"minRatio"},  "      (min len overlap of hit taken)\n";
    print "     \t minDistIde=",$par{"minDistIde"},"      (min distance in PIDE of hit)\n";
    print "     \t maxIde=",    $par{"maxIde"},    "      (max ide between guide and hit)\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$#fileIn=0;
$fileIn=$ARGV[1];
foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOutRdb=(.*)$/) {$fileOutRdb=$1;}
    elsif($_=~/^fileOutHtml=(.*)$/){$fileOutHtml=$1;}
    elsif($_=~/^title=(.*)$/)      {$title=$1;}
    elsif($_=~/^noNali/)           {$LnoNali=1;}
    elsif($_=~/^noSingle/)         {$LnoSingle=1;}
    elsif($_=~/^noSeq/)            {$LnoSeq=1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {$Lok=0;
	  if (-e $_){push(@fileIn,$_);
		     next;}
	  foreach $kwd(@kwdDes){
	      if ($_=~/^$kwd=(.*)$/){$par{"$kwd"}=$1;
				     $Lok=1;}}
	  if (! $Lok){
	      print"*** wrong command line arg '$_'\n";
	      die;}}}
push(@fileIn,$fileIn);

$LnoNali=    0              if (! defined $LnoNali);
$LnoSingle=  0              if (! defined $LnoSingle);
$LnoSeq=     0              if (! defined $LnoSeq);
$tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;
$title=      $tmp           if (! defined $title);
$fileOutRdb= $title.".rdb"  if (! defined $fileOutRdb);
$fileOutHtml=$title.".html" if (! defined $fileOutHtml);
$par{"organism"}=$title     if (! defined $par{"organism"});

				# ------------------------------
if (&is_hssp_list($fileIn)){	# (1) read file list
    $#fileIn=0;
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\s//g;
		     push(@fileIn,$_) if (-e $_);}close($fhin);}
				# --------------------------------------------------
undef %fin; $ctProt=$ctOk=0;	# (2) read files
foreach $fileIn(@fileIn){
    print "--- reading '$fileIn'\n"; undef %res;
    ($Lok,$err,%res)=
	&shortyAnaHsspHdr($fileIn,$par{"minDistIde"},$par{"maxIde"},
			  $par{"minLen"},$par{"maxLen"},$par{"minRatio"});
    if (! $Lok){
	print "*** $scrName err=$err\n";
	next;}
				# read sequence
    if (! $LnoSeq) {undef %rd; 
		    ($Lok,%rd)=&hsspRdSeqSecAcc($fileIn,"*","*");
		    if (! $LnoSeq) {$seq="";
				    foreach $it (1..$rd{"NROWS"}){$seq.=$rd{"seq","$it"};}}}
    ++$ctProt;$fin{"id1","$ctProt"}=$res{"id1"};$fin{"len1","$ctProt"}=$res{"len1"};
    $fin{"seq","$ctProt"}= $seq if (! $LnoSeq);
    $fin{"nali","$ctProt"}=$res{"nali"};
				# ------------------------------
    if ($res{"NROWS"}==0){	# no hit
	foreach $kwd(@kwdFin){
	    next if ($kwd=~/^id1|^len1|^seq|^nali/);
	    $fin{"$kwd","$ctProt"}=0;}
	next;}
				# ------------------------------
    ++$ctOk;			# has hit
    $max=0;$#tmp=0;undef %tmp;
    foreach $it (1..$res{"NROWS"}){
	if ($max < $res{"ratio","$it"}){$max=$res{"ratio","$it"};
					$maxPos=$it;}
	$tmp{$res{"ratio","$it"}}=$res{"id2","$it"};
	push(@tmp,$res{"ratio","$it"});}
#    @tmpSort= sort bynumber_high2low (@tmp); # sort according to ratio
    @tmpSort=@tmp;		# no sort according to ratio xx
    $id2="";foreach $ratio(@tmpSort){$id2.=$tmp{$ratio}.",";} # ids in string "id2a,id2b,.."
				# final result
    foreach $kwd(@kwdFin){next if ($kwd=~/^id1|^len1|^nali|^seq/);
			  if ($kwd=~/^(len2|lali|ratio|pide)/){
			      $fin{"$kwd","$ctProt"}=$res{"$kwd","$maxPos"};}
			  elsif ($kwd eq "nhit")  {$fin{"$kwd","$ctProt"}=$res{"NROWS"};}
			  elsif ($kwd eq "id2mul"){$fin{"$kwd","$ctProt"}=$id2;}
			  else{
			      print "*** $scrName unrecognised kwd=$kwd, in fin{}=\n";}}
}
$fin{"NROWS"}=$ctProt;
				# ------------------------------
				# (3) write RDB output
&open_file("$fhout",">$fileOutRdb"); 
print $fhout 
    "# Perl-RDB\n","# generated by $scrName ($fileIn)\n";
				# results
printf $fhout "# RESULTS          %-s\n","-" x 60;
printf $fhout "# RES NPROT%5d : total number of proteins\n",$ctProt;
printf $fhout "# RES NHIT %5d : number of proteins with significant database hits\n",$ctOk;
printf $fhout "# PARAMETERS       %-s\n","-" x 60;
printf $fhout "# PAR DEF  %5s : hits were regarded as significant if they had\n"," ";
printf $fhout "# PAR LALI %5d : as minimal alignment length\n",$par{"minLen"};
printf $fhout "# PAR RATIO%5d : as minimal ratio of length guide/best hit\n",$par{"minRatio"};
$tmp=25-$par{"minDistIde"};
printf $fhout "# PAR DIST %5d : as minimal seq identity (length dependent)\n",$tmp;

				# header
printf $fhout "# NOTATION         %-s\n","-" x 60;
printf $fhout "# NOTATION %-5s : %-s\n","id1",  "identifier of protein";
printf $fhout "# NOTATION %-5s : %-s\n","nali", "number of database hits";
printf $fhout "# NOTATION %-5s : %-s\n","len1", "length of protein";
printf $fhout "# NOTATION %-5s : %-s\n","nhit", "number of significant database hits";
printf $fhout "# NOTATION %-5s : %-s\n","len2", "length of best hit found";
printf $fhout "# NOTATION %-5s : %-s\n","lali", "number of residues aligned with best hit founds";
printf $fhout "# NOTATION %-5s : %-s\n","ratio","length ratio: guide/best hit";
printf $fhout "# NOTATION %-5s : %-s\n","pide", "sequence identity: guide / best hit";
printf $fhout "# NOTATION %-5s : %-s\n","id2",  "SWISS-PROT identifiers of hits";
printf $fhout "# NOTATION %-5s : %-s\n","seq",  "sequence (one letter amino acid code)";

				# names
print $fhout "num","\t","id1","\t","len1";
print $fhout "\tnali"       if (! $LnoNali);
foreach $kwd (@kwdFin){
    next if ($kwd =~/len1|id1|nali|seq/);
    if ($kwd =~ /id2mul/){ $tmp="id2";}else{$tmp=$kwd;}
    printf $fhout "\t%-s",$tmp;}
print $fhout "\tseq"        if (! $LnoSeq);
print $fhout "\n";

				# body
foreach $fh ("STDOUT",$fhout){
    foreach $it (1..$fin{"NROWS"}){
	print $fh $it,"\t",$fin{"id1","$it"},"\t",$fin{"len1","$it"};
	print $fh "\t",$fin{"nali","$it"}   if (! $LnoNali);
	foreach $kwd (@kwdFin){
	    next if ($kwd =~/len1|id1|nali|seq/);
	    $tmp=$formFin{"$kwd"};
	    printf $fh "\t$tmp",$fin{"$kwd","$it"};}
	print $fh "\t",$fin{"seq","$it"}    if (! $LnoSeq);
	print $fh "\n";}
}
close($fhout);

				# ------------------------------
				# (4) write output (HTML)
$Llink=1;
&rdb2htmlHere($fileOutRdb,$fileOutHtml,$fhout,$Llink);


print "--- output in $fileOutRdb,$fileOutHtml\n";
exit;

#===============================================================================
sub shortyAnaHsspHdr {
    local($fileInLoc,$minDistIdeLoc,$maxIdeLoc,$minLenLoc,$maxLenLoc,$minRatioLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$it,%rd,$len1,$len2,$lali,%res);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   shortyAnaHsspHdr            reads HSSP header and analyses significant hits
#       in:                     $fileInHssp,$minDistIde,$maxIde,$minLen,$maxLen,$minRatio
#       out:                    error: (0,msg,0) ok: (1,ok,%res) with 
#         $res{"NROWS"}         number of hits
#         $res{"id1"}           id of query protein
#         $res{"len1"}          length of query protein
#         $res{"lali",$ct}      alignment length for correct hit $ct
#         $res{"len2",$ct}      length of aligned protein
#         $res{"pide",$ct}      percentage sequence identity
#         $res{"ratio",$ct}     len1/len2 (or opposite, i.e., <1)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."shortyAnaHsspHdr";$fhinLoc="FHIN"."$sbrName";

				# ------------------------------
    undef %rd;			# reading HSSP header
    ($Lok,%rd)=
	&hsspRdHeader($fileInLoc,"PDBID","SEQLENGTH","NALIGN","ID","IDE","LALI","LSEQ2");

				# delete spaces
    foreach $kwd("PDBID","SEQLENGTH","NALIGN"){$rd{"$kwd"}=~s/\s//g;}
    foreach $it (1..$rd{"NROWS"}){
	foreach $kwd("ID","IDE","LALI","LSEQ2"){$rd{"$kwd","$it"}=~s/\s//g;}}

    return(0,"$sbrName \&hsspRdHeader($fileIn) failed\n","") if (! $Lok);

    undef %res; 
    $len1=$res{"len1"}=$rd{"SEQLENGTH"}; # length of guide sequence
    $res{"id1"}= $rd{"PDBID"};	# id of guide sequence
    $res{"nali"}=$rd{"NALIGN"};
				# ------------------------------
    $ct=0;			# analyse other hits
    $res{"NROWS"}=0;
    foreach $it (1..$rd{"NROWS"}){
	$rd{"IDE","$it"}=100*$rd{"IDE","$it"};
				# ignore if below threshold
	if (($rd{"IDE","$it"}-&getDistanceNewCurveIde($rd{"LALI","$it"}))<$minDistIdeLoc){
	    print "--- it=$it, below threshold ($minDistIdeLoc)\n";
	    next;}
	if ($rd{"IDE","$it"}>$maxIdeLoc){ # ignore too similar
	    print "--- it=$it, too similar (",$rd{"IDE","$it"},">$maxIdeLoc)\n";
	    next;}
	if ($rd{"LSEQ2","$it"}<$minLenLoc){ # ignore if too short
	    print "--- it=$it, too short (",$rd{"LSEQ2","$it"},"<$minLenLoc)\n";
	    next;}
	if ($rd{"LSEQ2","$it"}>$maxLenLoc){ # ignore if too long
	    print "--- it=$it, too long (",$rd{"LSEQ2","$it"},">$maxLenLoc)\n";
	    next;}
	$lali=$rd{"LALI","$it"};$len2=$rd{"LSEQ2","$it"};
				# ignore if too different in length
	if ( ($lali/$len1)<$minRatioLoc || ($lali/$len2)<$minRatioLoc ){
	    print "--- it=$it, too different in length (",$lali/$len1,"<$minRatioLoc)\n";
	    next;}
	if ($len1>$len2){$ratio=$len1/$len2;}
	else            {$ratio=$len2/$len1;}
	if ($ratio<$minRatioLoc){
	    print "--- it=$it, too different in length (",$ratio,"<$minRatioLoc)\n";
	    next;}
				# --------------------
				# all constraints ok
	++$ct;$res{"id2","$ct"}=$rd{"ID","$it"};
	$res{"ratio","$ct"}=$ratio;$res{"pide","$ct"}=$rd{"IDE","$it"};
	$res{"lali","$ct"}=$lali;$res{"len2","$ct"}=$len2;}
    $res{"NROWS"}=$ct;
    return(1,"ok $sbrName",%res);
}				# end of shortyAnaHsspHdr

#==========================================================================================
sub rdb2htmlHere {
    local ($fileRdb,$fileHtml,$fhout,$Llink) = @_ ;
    local (@headerRd,$tmp,@tmp,@colNames,$colNames,%body,$des,$ct,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    sub: rdb2html              convert an RDB file to HTML
#         input:		$fileRdb,$fileHtml,$fhout,$Llink 
#                               (Llink=1 -> links from column names to Notation in header)
#--------------------------------------------------------------------------------
    $fhin="FHinRdb2html";
    &open_file("$fhin", "$fileRdb"); # external lib-ut.pl
    
    $#headerRd=0;		# ------------------------------
    while (<$fhin>) {		# read header of RDB file
	$tmp=$_;$_=~s/\n//g;
	last if (! /^\#/);
	push(@headerRd,$_);}
				# ------------------------------
				# get column names
    $tmp=~s/\n//g;$tmp=~s/^\t*|\t*$//g;
    @colNames=split(/\t/,$tmp);

    $body{"COLNAMES"}="";	# store column names
    foreach $des (@colNames){$body{"COLNAMES"}.="$des".",";}
	
    $ct=0;			# ------------------------------
    while (<$fhin>) {		# read body
	next if ($_=~/\t\d+[NFD\t]\t/); # skip format
	$_=~s/\n//g;$_=~s/^\t*|\t*$//g;	# purge leading
	next if (length($_)<1);
	@tmp=split(/\t/,$_);
	++$ct;
	foreach $it (1..$#tmp){	# store body
	    $key=$colNames[$it];
	    $body{"$ct","$key"}=$tmp[$it];}}
    $body{"NROWS"}=$ct;
				# end of reading RDB file
				# ------------------------------

				# ------------------------------
				# write output file
    &open_file("$fhout", ">$fileHtml") if ($fhout ne "STDOUT");
    @tmp=			# write header   external lib-ut.pl
	&wrtRdb2HtmlHeaderHere($fhout,$Llink,$body{"COLNAMES"},@headerRd);
				# mark keys to be linked
    foreach $col (@colNames){$body{"link","$col"}=0;}
    foreach $col (@tmp)     {$body{"link","$col"}=1;}
	
				# write body
    &wrtRdb2HtmlBodyHere($fhout,$Llink,%body);

    close($fhin);close($fhout) if ($fhout ne "STDOUT");
}				# end of rdb2htmlHere

#==========================================================================================
sub wrtRdb2HtmlHeaderHere {
    local ($fhout,$LlinkLoc,$colNamesLoc,@headerLoc) = @_ ;
    local (@colNamesLoc,$Lnotation,$LlinkHere,$col,@namesLink);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlHeader		write the HTML header
#         input:		$fhout,$fileLoc,$LlinkLoc,$colNamesLoc,@headerLoc
#                               where colName="name1,name2,"
#                               and @headerLoc contains all lines in header
#         output:               @nameLinks : names of columns with links (i.e.
#                               found as NOTATION in header line
#--------------------------------------------------------------------------------
    $#namesLink=0;

    $colNamesLoc=~s/^,*|,*$//g;
    @colNamesLoc=split(/,/,$colNamesLoc);

    print $fhout 
	"<HTML>\n",
	"<TITLE>Database search results for ",$par{"organism"},"</TITLE>\n",
	"<BODY>\n",
	"<CENTER>\n",
	"<H1>Database search results for ",$par{"organism"},"</H1>\n",
	"<H2>Burkhard Rost</H2>\n",
	"<P><P>\n",
	"</CENTER>\n",
	"\n",
	"<P><P>\n",
	"<FONT SIZE=2> 69 012 Heidelberg, Germany, ",
	"<A HREF=\"mailto:rost\@EMBL-Heidelberg.de\">rost\@embl-heidelberg.de</A>, ",
	"<A HREF=\"http://www.embl-heidelberg.de/~rost/\">http://www.embl-heidelberg.de/~rost/</A>",
	"<BR> </FONT>\n",
	"\n",
	"<P><P>\n",
	"\n",
	"<UL>\n",
	"<LI><A HREF=\"\#HEADER\">Header (descriptions of column names)</A>",
	"<LI><A HREF=\"\#BODY\">  Table<A>",
	"</UL>\n",
	"<P><P>\n",
	"\n",
	"\n",
	"<HR>\n",
	"<P><P>\n",
	"<A NAME=\"HEADER\"><H2>Header (description of column names)</H2></A>\n",
	"<P><P>\n";

    print $fhout "<PRE>\n";
    $Lnotation=0;undef %ok;
    foreach $_(@headerLoc){
	$LlinkHere=0;$Lnotation=1 if ($_=~/NOTATION/);
	$_=~s/^\s*\#\s*//g;
	if ($Lnotation){
	   foreach $col(@colNamesLoc){
	       $LlinkHere=0;
		if ($_=~/NOTATION\s*$col[\s\:]+/){ 
		    $colFound=$col;$LlinkHere=1;
		    if (! defined $ok{$col}){$ok{$col}=1;
					     push(@namesLink,$col);}
		    last;}}
	   if ($LlinkLoc && $LlinkHere){ 
		print $fhout "<A NAME=\"$colFound\">";}}
	print $fhout "$_";
	if ($LlinkHere){
	   print $fhout "</A>";}
	print $fhout "\n";}
    print $fhout "\n</PRE>\n";
    print $fhout "<BR>\n";
    return(@namesLink);
}				# end of wrtRdb2HtmlHeaderHere

#==========================================================================================
sub wrtRdb2HtmlBodyHere {
    local ($fhout,$LlinkLoc,%bodyLoc) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBodyHere		writes the body for a RDB->HTML file
#                               where $body{"it","colName"} contains the columns
#--------------------------------------------------------------------------------
    print $fhout 
	"<P><P><HR><P><P>\n\n",
	"<A NAME=\"BODY\"><H2>Table</H2><\/A>\n",
	"<P><P>\n";
				# get column names
    $bodyLoc{"COLNAMES"}=~s/^,*|,*$//g;
    @colNames=split(/,/,$bodyLoc{"COLNAMES"});

    print $fhout "<TABLE BORDER>\n";
				# ------------------------------
    				# write column names with links
    &wrtRdb2HtmlBodyColNamesHere($fhout,@colNames);

				# ------------------------------
				# write body
    foreach $it (1..$body{"NROWS"}){
	print $fhout "\n<TR>   ";
	foreach $itdes (1..$#colNames){
	    if    ($colNames[$itdes]=~/^(num|nali|len)/){
		print $fhout "<TD ALIGN=RIGHT>";}
	    elsif ($colNames[$itdes]=~/^(id|seq)/){
		print $fhout "<TD ALIGN=LEFT>";}
	    else {print $fhout "<TD>";}
	    
	    if (defined $body{"$it","$colNames[$itdes]"} && $colNames[$itdes] eq "seq") {
		$seq=$body{"$it","$colNames[$itdes]"};
		if ($par{"nperLine"}>=length($seq)){
		    print $fhout $seq;}
		else{
		    $seqTmp="";
		    for ($res=1;$res<=(length($seq)-$par{"nperLine"});$res+=$par{"nperLine"}){
			$len=$par{"nperLine"}; 
			$len=(length($seq)-$res) if ((length($seq)-$res)<$par{"nperLine"});
#			$seqTmp.=substr($seq,$res,$len)." ";
			$seqTmp.=substr($seq,$res,$len)."<BR>";
		    }
		    print $fhout $seqTmp;}}
	    elsif (defined $body{"$it","$colNames[$itdes]"}){
	    	print $fhout $body{"$it","$colNames[$itdes]"};}
	    else {print $fhout " ";} 
	    print $fhout "</TD>";}
	print $fhout "</TR>\n";
				# ------------------------------
				# repeat names
	if (int($it/50)==($it/50)){
	    &wrtRdb2HtmlBodyColNamesHere($fhout,@colNames);}

    }

    print $fhout "\n";
    print $fhout "</TABLE>\n";
    print $fhout "\n\n";
				# ------------------------------
				# final words
    print $fhout
	"<P><P><BR><BR><P><P>\n"."<HR>\n"."<!--"."=" x 50 ."-->\n\n",
	"<A HREF=\"http://www.embl-heidelberg.de/\"> ",
	"<IMG WIDTH=50 HEIGHT=50 ALIGN=MIDDLE SRC=\"http://www.embl-heidelberg.de/~rost/Dfig/icon-embl.gif\" ALT=\"EMBL Home\"></A> \n",
	"<A HREF=\"http://www.embl-heidelberg.de/~rost/index.html\">",
	"<IMG WIDTH=50 HEIGHT=50 ALIGN=MIDDLE SRC=\"http://www.embl-heidelberg.de/~rost/Dfig/icon-br-home.gif\" ALT=\"Rost Home\"></A>\n",
	"<A HREF=\"mailto:rost\@EMBL-Heidelberg.de\">",
	"<IMG WIDTH=50 HEIGHT=50 ALIGN=MIDDLE SRC=\"http://www.embl-heidelberg.de/~rost/Dfig/icon-br-home-mail.gif\" ALT=\"Mail to Rost\"></A>\n\n",
	"<A HREF=\"http://www.embl-heidelberg.de/predictprotein/predictprotein.html\">",
	"<IMG ALIGN=MIDDLE WIDTH=50 HEIGHT=50 SRC=\"http://www.embl-heidelberg.de/~rost/Dfig/icon-pp.gif\" ALT=\"PredictProtein\"></A>\n",
	"<A HREF=\"http://www.embl-heidelberg.de/~rost/aqua.html\">",
	"<IMG ALIGN=MIDDLE WIDTH=50 HEIGHT=50 SRC=\"http://www.embl-heidelberg.de/~rost/Dfig/icon-aqua.gif\" ALT=\"Aqua Home\"></A>\n\n",
	"</BODY>\n","</HTML>\n";
	

}				# end of wrtRdb2HtmlBodyHere

#==========================================================================================
sub wrtRdb2HtmlBodyColNamesHere {
    local ($fhout,@colNames)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   WrtRdb2HtmlBodyColNames   writes the column names (called by previous)
#       GLOBAL input:		%bodyLoc
#         input:                $fhout,@colNames
#--------------------------------------------------------------------------------
    print $fhout "<TR ALIGN=LEFT>  ";
    foreach $des (@colNames){
	print $fhout "\t<TH>";
	if ($LlinkLoc && $bodyLoc{"link","$des"}){
	    print $fhout "<A HREF=\"\#$des\">";}
	print $fhout $des," ";
	if ($LlinkLoc && $bodyLoc{"link","$des"}){
	    print $fhout "</A>";}
	print $fhout "</TH>\n";
    }
    print $fhout "</TR>\n";
}				# end of wrtRdb2HtmlBodyColNamesHere

