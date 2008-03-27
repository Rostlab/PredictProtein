#!/usr/bin/perl -w
$[ =1 ;


if ($#ARGV<1){print "usage 'script file.rdb' (option: 2nd=output)\n";
	      exit;}

$fileRdb=$ARGV[1];
if ($#ARGV==2){$fileHtml=$ARGV[2];}else{$fileHtml=$fileRdb;$fileHtml=~s/\.rdb/\.html/g;}

$Llink=1;
$fhout = "STDOUT";
$fhout = "FHOUT";

&rdb2html($fileRdb,$fileHtml,$fhout,$Llink);

if (-e $fileHtml){
    print "--- ok out=$fileHtml\n";}else{print"*** error output '$fileHtml' missing\n";}

exit;

#==========================================================================================
sub rdb2html {
    local ($fileRdb,$fileHtml,$fhout,$Llink) = @_ ;
    local (@headerRd,$tmp,@tmp,@colNames,$colNames,%body,$des,$ct,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    sub: rdb2html              convert an RDB file to HTML
#         input:		$fileRdb,$fileHtml,$fhout,$Llink 
#                               (Llink=1 -> links from column names to Notation in header)
#--------------------------------------------------------------------------------
    $fhin="FHinRdb2html";
    open("$fhin", "$fileRdb") || die "*** failed opening input file=$fileRdb";
    
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
	
				# ------------------------------
    while (<$fhin>) {		# skip formats
	$tmp=$_;
	last;}

    $ct=0;			# ------------------------------
    while (<$fhin>) {		# read body
	$_=~s/\n//g;
	$_=~s/^\t*|\t*$//g;
	if (length($_)<1){
	    next;}
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
    if ($fhout ne "STDOUT"){
	open("$fhout",">$fileHtml") || die "*** failed opening output file=$fileHtml";
    }

    @tmp=			# write header   external lib-ut.pl
	&wrtRdb2HtmlHeader($fhout,$fileRdb,$Llink,$body{"COLNAMES"},@headerRd);
				# mark keys to be linked
    foreach $col (@colNames){$body{"link","$col"}=0;}
    foreach $col (@tmp)     {$body{"link","$col"}=1;}
	
				# write body
    &wrtRdb2HtmlBody($fhout,$Llink,%body);

    close($fhin);if ($fhout ne "STDOUT"){close($fhout);}
}				# end of rdb2html

#==========================================================================================
sub wrtRdb2HtmlHeader {
    local ($fhout,$fileLoc,$LlinkLoc,$colNamesLoc,@headerLoc) = @_ ;
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
	"<TITLE>Extracted from $fileLoc </TITLE>\n",
	"<BODY>\n",
	"<H1>Extraction of data from RDB format:$fileLoc </H1>\n",
	"<P><P>\n",
	"<UL>\n",
	"<LI><A HREF=\"\#HEADER\">RDB header<\/A>",
	"<LI><A HREF=\"\#BODY\">RDB table<\/A>",
	"<LI><A HREF=\"\#AVERAGES\">Averages over columns<\/A>",
	"<\/UL>\n",
	"<P><P>\n",
	"<HR>\n",
	"<P><P>\n",
	"<A NAME=\"HEADER\"><H2>RDB header</H2><\/A>\n",
	"<P><P>\n";

    print $fhout "<PRE>\n";
    $Lnotation=0;
    foreach $_(@headerLoc){
	$LlinkHere=0;
	if (/NOTATION/){ $Lnotation=1;}
	if ($Lnotation){
	   foreach $col(@colNamesLoc){
		if (/$col/){ 
		    $colFound=$col;$LlinkHere=1;
		    push(@namesLink,$col);
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
}				# end of wrtRdb2HtmlHeader

#==========================================================================================
sub wrtRdb2HtmlBody {
    local ($fhout,$LlinkLoc,%bodyLoc) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBody		writes the body for a RDB->HTML file
#                               where $body{"it","colName"} contains the columns
#--------------------------------------------------------------------------------
    print $fhout 
	"<P><P><HR><P><P>\n\n",
	"<A NAME=\"BODY\"><H2>RDB table</H2><\/A>\n",
	"<P><P>\n";
				# get column names
    $bodyLoc{"COLNAMES"}=~s/^,*|,*$//g;
    @colNames=split(/,/,$bodyLoc{"COLNAMES"});

    print $fhout "<TABLE BORDER>\n";
				# ------------------------------
    				# write column names with links
    &wrtRdb2HtmlBodyColNames($fhout,@colNames);

				# ------------------------------
				# write body
    $LfstAve=0;
    foreach $it (1..$body{"NROWS"}){
	print $fhout "<TR>   ";
	foreach $itdes (1..$#colNames){
				# break for Averages
	    if ( ($itdes==1) && (! $LfstAve) &&
		($body{"$it","$colNames[1]"} =~ /^ave/) ){
		$LfstAve=1;
		&wrtRdb2HtmlBodyAve($fhout,@colNames);}
		    
	    if (defined $body{"$it","$colNames[$itdes]"}) {
	    	print $fhout "<TD>",$body{"$it","$colNames[$itdes]"};}
	    else {
		print $fhout "<TD>"," ";}}
	print $fhout "\n";}

    print $fhout "</TABLE>\n","</BODY>\n","</HTML>\n";
}				# end of wrtRdb2HtmlBody

#==========================================================================================
sub wrtRdb2HtmlBodyColNames {
    local ($fhout,@colNames)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   WrtRdb2HtmlBodyColNames   writes the column names (called by previous)
#       GLOBAL input:		%bodyLoc
#         input:                $fhout,@colNames
#--------------------------------------------------------------------------------
    print $fhout "<TR>  ";
    foreach $des (@colNames){
	print $fhout "<TH>";
	if ($LlinkLoc && $bodyLoc{"link","$des"}){
	    print $fhout "<A HREF=\"\#$des\">";}
	print $fhout $des," ";
	if ($LlinkLoc && $bodyLoc{"link","$des"}){
	    print $fhout "</A>";}
    }
    print $fhout "\n";
}				# end of wrtRdb2HtmlBodyColNames

#==========================================================================================
sub wrtRdb2HtmlBodyAve {
    local ($fhout,@colNames)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    WrtRdb2HtmlBodyAve         inserts a break in the table for the averages at end of
#                               all rows
#         input:		$fhout,@colNames
#--------------------------------------------------------------------------------
    foreach $_(@colNames){
	print $fhout "<TD>  ";}
    print"\n";
    print $fhout 
	"</TABLE>\n<P><HR><P>\n",
	"<P><P>\n",
	"<A NAME=\"AVERAGES\"><H4> Averages </H4><\/A><P>\n",
	"<TABLE BORDER>\n";

    &wrtRdb2HtmlBodyColNames($fhout,@colNames);
    print $fhout "<TR>   ";
}				# end of wrtRdb2HtmlBodyAve

