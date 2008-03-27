#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads PHDhtm RDB file (+ hssp) and writes table (rdb + html)";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
$par{"extRdb"}=        ".rdbHtm";
$par{"extHssp"}=       ".hssp";
$par{"extHsspSelf"}=   ".hsspSelf";
$par{"dirHssp"}=       "hsspRaw/";
$par{"dirHsspSelf"}=   "hsspSelf/";
$par{"organism"}=      "E. coli";
$par{"organism"}=      "Organism";
$par{"nperLine"}=      100;	# number of residues per line (HTML sequence)
$par{"minLen"}=         20;	# minimal number of residues to consider 

@kwdDes=("extRdb","extHssp","extHsspSelf","dirHssp","dirHsspSelf","organism","nperLine",
	 "minLen"); # a.a

@kwdFin=("id","nhtm","top","nali","len1","riTop","riMod","topD","htmCN","seq");
	 
%formFin=('nhtm',"%5d",'len1',"%5d",'riTop',"%1d",'riMod',"%1d",'topD',"%6.2f",
	  'id',"%-s",'nali',"%-s",'top',"%-s",'htmCN',"%-s",'seq',"%-s");
%known=('af', "Archaeoglobus fulgidus",
	'as', "Helicobacter pylori (as)",
	'bb', "Borrelia burgdorferi",
	'bs', "Bacillus subtilis",
	'cy', "Synechocystis sp. (cyanobacterium)",
	'ec', "Escherichia coli",
	'hi', "Haemophilus influenzae",
	'hp', "Helicobacter pylori",
	'hs', "Homo Sapiens",
	'mg', "Mycoplasma genitalium",
	'mj', "Methanococcus jannaschii",
	'mp', "Mycoplasma pneumoniae",
	'mt', "Methanobacterium thermoautotrophicum",
	'sc', "Saccaromyces cerevisiae",
	'', "",
	);
$known=join('|',sort keys(%known));

				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName list-of-rdb-files (or *)'\n";
    print "opt: \t org=",        $par{"organism"},   "\t(for title, e.g. 'org=Homo sapiens')\n";
    print "     \t      note: use full title except for:\n";
    print "     \t      ($known)\n";
    print "     \t      which are automatically translated\n";
    print "     \t minLen=",     $par{"minLen"},     "\t\t(minimal length to take prot)\n";
    print " !!! \t nprot=          \tMUST BE DEFINED for cumulative\n";
    print "     \n";
    print "     \t nperLine=",   $par{"nperLine"},   "\t\t(for HTML output of seq, =0 => no sequence)\n";
#    print "     \t title=x         \toutput files will use this string\n";
    print "     \t fileOut=x\n";
    print "     \t extRdb=",     $par{"extRdb"},     "\t\t(default)\n";
    print "     \t extHssp=",    $par{"extHssp"},    "\t\t(default)\n";
    print "     \t extHsspSelf=",$par{"extHsspSelf"},"\t(default)\n";
    print "     \t dirHssp=",    $par{"dirHssp"},    "\t\t(default)\n";
    print "     \t dirHsspSelf=",$par{"dirHsspSelf"},"\t(default)\n";
    print "     \t \n";
    print "     \t note: for WWW you still have to do 'phdHtm-rmSeq-fromRdb.pl'\n";
    print "     \t       ... and hack-www-reformat.pl ...\n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$#fileIn=0;
foreach $_(@ARGV){
#    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^nprot=(.*)$/)  {$par{"nprot"}=$1;}
    elsif($_=~/^org=(.*)$/)    {$par{"organism"}=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {$Lok=0;
	  if (-e $_){push(@fileIn,$_);
		     next;}
	  foreach $kwd(@kwdDes){
	      if ($_=~/^$kwd=(.*)$/){$par{$kwd}=$1;
				     $Lok=1;}}
	  if (! $Lok){
	      print"*** wrong command line arg '$_'\n";
	      die;}}}

$fileIn=$fileIn[1];
				# ------------------------------
				# output file name
if (! defined $fileOut && $#fileIn>1){
    $tmp=0;
    $tmp=$par{"organism"} if (defined $par{"organism"});
    $tmp="OUT-phdHtm-rdb2table" if (! defined $tmp || ! $tmp);
    $tmp=~s/\s/\-/g;
    $fileOut=$tmp.".out";}
elsif (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    $fileOut="Out-".$tmp.".dat";}

				# ------------------------------
if (! defined $par{"nprot"}){	# number of proteins obligatory!
    print "*** ERROR give number of all proteins as 'nprot=xx'\n";
    die;}
if (! -e $fileIn){
    print "*** ERROR no fileIn=$fileIn, \n";die;}
				# ------------------------------
if (&isRdbList($fileIn)){	# read file list
    $#fileIn=0;
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\s//g;
		     push(@fileIn,$_) if (-e $_);}close($fhin);}
				# ------------------------------
$ctProt=0;			# (1) read files
$maxNhtm=$maxNali=0;
foreach $fileIn(@fileIn){
    $id=$fileIn;$id=~s/^.*\///g;$id=~s/$par{"extRdb"}//g;
    print "--- reading $id ($fileIn)\n";
    $Lok=&open_file("$fhin", "$fileIn");
    next if (! $Lok);
    ++$ctProt;
				# --------------------
				# read file (all in/out global)
    &rdRdbHtmHere;
				# output:
				# res{"x","ct"} x=len1,nhtm,riMod,riTop,topD,top,htm,seq,htmCN
				#            htmCN=1-5,10-200, gives the position of the HTMs
    close($fhin);
				# --------------------
				# search HSSP file
    $hssp=    $par{"dirHssp"}.$id.$par{"extHssp"};
    $hsspSelf=$par{"dirHsspSelf"}.$id.$par{"extHsspSelf"};
    if    (-e $hssp)    {print "--- corresponding HSSP $hssp\n";
			 $tmp=`grep "^NALIGN" $hssp`;
			 $nali=$tmp;$nali=~s/^NALIGN\s+(\d+)\D*.*$/$1/g;}
    elsif (-e $hsspSelf){print "--- corresponding HSSPself $hsspSelf\n";
			 $tmp=`grep "^NALIGN" $hsspSelf`;
			 $nali=$tmp;$nali=~s/^NALIGN\s+(\d+)\D*.*$/$1/g;}
    else                {print "--- no HSSP for $id ($hssp)\n";
			 $nali="?";}
    $res{"nali","$ctProt"}=$nali;
    $res{"id","$ctProt"}=$id;
    $maxNali=$nali if ($nali>$maxNali);
    $maxNhtm=$res{"nhtm","$ctProt"} if ($res{"nhtm","$ctProt"}>$maxNhtm);
}

$res{"NROWS"}=$ctProt;
				# ------------------------------
$#order=$#ok=0;$nhtm=$maxNhtm;	# (2) sort the results
undef %stat;
while ($nhtm>0){
    $nali=$maxNali;		# top = in
    $stat{"$nhtm","in"}=$stat{"$nhtm","out"}=0;
    while ($nali>0){
	foreach $it(1..$res{"NROWS"}){
	    if (! defined $nhtm){print "id=",$res{"id",$it},"\n";print "xx ERROR it=$it, nhtm not defined, \n";die;}
	    if (! defined $nali){print "id=",$res{"id",$it},"\n";print "xx ERROR it=$it, nali not defined, \n";die;}
	    if (! defined $res{"top",$it}){print "id=",$res{"id",$it},"\n";print "xx ERROR it=$it, res{top} not defined, \n";die;}
	    if (! defined $res{"nhtm",$it}){print "id=",$res{"id",$it},"\n";print "xx ERROR it=$it, res{nhtm} not defined, \n";die;}
	    if (! defined $res{"nali",$it}){print "id=",$res{"id",$it},"\n";print "xx ERROR it=$it, res{nali} not defined, \n";die;}
		
	    if ((defined $res{"nhtm",$it}) && ($res{"top",$it}=~/in/i) &&
		($res{"nhtm",$it}==$nhtm) && ($res{"nali",$it}==$nali)){ 
		++$stat{"$nhtm","in"};
		push(@order,$it);
		$ok[$it]=1;}}
	--$nali;}
    $nali=$maxNali;		# top = not in
    while ($nali>0){
	foreach $it(1..$res{"NROWS"}){
	    if (($res{"nhtm",$it}==$nhtm) && ($res{"nali",$it}==$nali) && 
		($res{"top",$it}!~/in/i)){
		++$stat{"$nhtm","out"};
		push(@order,$it);
		$ok[$it]=1;}}
	--$nali;}
    --$nhtm;}
foreach $it(1..$res{"NROWS"}){
    if (! defined $ok[$it]){
	print "*** missing it=$it, nali=",$res{"nali",$it},", nhtm=",$res{"nhtm",$it},",\n";}}

				# ------------------------------
				# write output (RDB)
$fileOutRdb=$fileOut;$fileOutRdb=~s/\..*$/\.rdb/;
&open_file("$fhout",">$fileOutRdb"); 
foreach $fh ("STDOUT",$fhout){
    if ($fh ne "STDOUT"){&wrtRdbHdrHere($fh);}
    &wrtRdbHere($fh);}close($fhout);
				# ------------------------------
				# write output (HTML)
$fileOutHtml=$fileOut;$fileOutHtml=~s/\..*$/\.html/;
$Llink=1;
&rdb2htmlHere($fileOutRdb,$fileOutHtml,$fhout,$Llink);

				# ------------------------------
                                # compute statistics (RDB)

				# ------------------------------
				# write output statistics (RDB)

$fileOutStat=$fileOutRdb;$fileOutStat=~s/^Out/Stat/;
if ($fileOutStat eq $fileOutRdb || $fileOutStat !~/Stat/){
    $fileOutStat="Stat-".$fileOutStat;}
&open_file("$fhout",">$fileOutStat"); 
$add=$fileOutStat;$add=~s/^.*\///g;$add=~s/Stat-//g;$add=~s/\..*$//g;$add=~s/[\-]|htm|rdb|0//g;
#$add=~tr/[a-z]/[A-Z]/;
$add=~s/phdh/PHDh/i;
foreach $fh ("STDOUT",$fhout){
    &wrtStat($fh,$add);}close($fhout);

print "--- output in $fileOutRdb,$fileOutHtml,$fileOutStat\n";
exit;

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
    foreach $des (@colNames){
        next if ($des =~ /seq/i && $par{"nperLine"}==0); # ignore sequence!
        $body{"COLNAMES"}.="$des".",";}
	
    $ct=0;			# ------------------------------
    while (<$fhin>) {		# read body
	next if ($_=~/\t\d+[NFD\t]\t/); # skip format
	$_=~s/\n//g;$_=~s/^\t*|\t*$//g;	# purge leading
	next if (length($_)<1);
	@tmp=split(/\t/,$_);
	++$ct;
	foreach $it (1..$#tmp){	# store body
	    $key=$colNames[$it];
	    $body{$ct,"$key"}=$tmp[$it];}}
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

#===============================================================================
sub rdRdbHtmHere {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdRdbHtmHere                reads RDB file
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."rdRdbHtmHere";
    $tmp="";			# ------------------------------
    while (<$fhin>) {		# read header
	last if ($_!~/^\#/);
	if    ($_=~/^\# LENGTH\s*\:\s*(\d+)\D+.*$/)            {$res{"len1","$ctProt"}=$1;}
	elsif ($_=~/^\# NHTM_BEST\s*\:\s*(\d+)\D+.*$/)         {$res{"nhtm","$ctProt"}=$1;}
	elsif ($_=~/^\# REL_BEST_DPROJ\s*\:\s*([\d\.]+)\D+.*$/){$res{"riMod","$ctProt"}=$1;}
#	elsif ($_=~/^\# REL_BEST_DIFF\s*\:\s*([\d\.]+)\D+.*$/) {$res{"relRefDif","$ctProt"}=$1;}
#	elsif ($_=~/^\# REL_BEST\s*\:\s*([\d\.]+)\D+.*$/)      {$res{"relRefZ","$ctProt"}=$1;}
	elsif ($_=~/^\# HTMTOP_RID\s*\:\s*([\-\d\.]+)\D+.*$/)  {$res{"topD","$ctProt"}=$1;}
	elsif ($_=~/^\# HTMTOP_RIP\s*\:\s*(\d+)\D+.*$/)        {$res{"riTop","$ctProt"}=$1;}
	elsif ($_=~/^\# HTMTOP_PRD\s*\:\s*([a-z]+)\W+.*$/)     {$res{"top","$ctProt"}=$1;}
	elsif ($_=~/^\# MODEL_DAT\s*\:\s*(.+)$/)               {$tmp.="\n".$1;}
    }
    $res{"top","$ctProt"}="unk" if (! defined $res{"top","$ctProt"}); # if difference 0!!
				# ------------------------------
				# digest regions
    @tmp=split(/\n/,$tmp);
    $res{"htmCN","$ctProt"}="";
    foreach $tmp(@tmp){
	$tmp=~s/^\s*|\s*$//g;	# purge leading blanks
	@tmp2=split(/,/,$tmp);
	next if ($#tmp2<4);
	$res{"htmCN","$ctProt"}.=",".$tmp2[4];}
    $res{"htmCN","$ctProt"}=~s/^,*|,*$//g; # purge leading commata
	
				# ------------------------------
				# read sequence, htm
    $res{"seq","$ctProt"}="";
    $res{"htm","$ctProt"}="";
    while (<$fhin>) {		# read header
	next if ($_=~/^(No|4N)/); # skip headers
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);
	next if ($#tmp<5);
	if ($tmp[2]!~/[ACDEFGHIJKLMNPQRSTVWXYZ!]/){
	    print "-*- WARN $sbrName res=$tmp[2] strange AA\n";}
	if    (! defined $tmp[11] && $tmp[3] =~/[ LH]/){
	    $tmp=$tmp[3];}
	elsif ((! defined $tmp[11] || $tmp[11]!~/[ LH]/) && $tmp[3]!~/[ LH]/){
	    print "-*- STRONG !! WARN $sbrName prd=$tmp[11] strange prediction !! (HL)\n";
	    $tmp="?";}
	else  {$tmp=$tmp[11];}
	$res{"seq","$ctProt"}.=$tmp[2];
	$res{"htm","$ctProt"}.=$tmp;}
				# correct if NHTM not defined
    if (! defined $res{"nhtm","$ctProt"}){
	$tmp=$res{"htm","$ctProt"};
	$tmp=~s/HH*/H/g;$tmp=~s/[ L]//g;
	$res{"nhtm","$ctProt"}=length($tmp);}
	
}				# end of rdRdbHtmHere

#===============================================================================
sub wrtRdbHere {
    local($fhLoc)=@_;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHere                  writes RDB file
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtRdbHere";
				# ------------------------------
    print $fhLoc "num";		# write names
    foreach $kwd (@kwdFin){
	printf $fhLoc "\t%-s",$kwd;}
    print $fhLoc "\n";
				# ------------------------------
    $ct=0;			# write data
    foreach $it (@order){	# loop over all proteins
	++$ct;printf $fhLoc "%5d",$ct;
	foreach $kwd (@kwdFin){	# all columns to write
	    $tmpForm=$formFin{$kwd};
	    if (defined $res{$kwd,$it}){
		$tmpData=$res{$kwd,$it};$tmpData=~s/\s//g;}
	    else {$tmpData="";}
	    next if ($fhLoc eq "STDOUT" && $kwd eq "seq");
	    printf $fhLoc "\t$tmpForm",$tmpData;}
	print $fhLoc "\n";}
}				# end of wrtRdbHere

#===============================================================================
sub wrtRdbHdrHere {
    local($fhLoc)=@_;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHdrHere               writes RDB header 
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtRdbHdrHere";
				# ------------------------------
				# write header
    print  $fhLoc "# Perl-RDB\n# \n";
    printf $fhLoc "# NOTATION %-5s : %-s\n","id",   "identifier of protein";
    printf $fhLoc "# NOTATION %-5s : %-s\n","nhtm", "number of transmembrane helices predicted";
    printf $fhLoc 
	"# NOTATION %-5s : %-s\n","top",  "topology, i.e., location of first loop region";
    printf $fhLoc "# NOTATION %-5s : %-s\n","nali", "number of sequence in family";
    printf $fhLoc "# NOTATION %-5s : %-s\n","len1", "length of protein";
    printf $fhLoc 
	"# NOTATION %-5s : %-s\n","riTop","reliability of topology prediction (9=high, 0=low)";
    printf $fhLoc "# NOTATION %-5s : %-s\n","riMod","reliability of best model (9=high, 0=low)";
    printf $fhLoc 
	"# NOTATION %-5s : %-s\n","topD", 
	"difference in number of charged loop residues (K+R): all even loops - all odd loops";
    printf $fhLoc "# NOTATION %-5s : %-s\n","htmCN","position (C-N) of predicted helices";
    printf $fhLoc "# NOTATION %-5s : %-s\n","seq",  "sequence (one letter amino acid code)";
    print $fhLoc "# \n";
}				# end of wrtRdbHdrHere


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
    $organism=$par{"organism"};
    if (defined $known{"$organism"}){
	$organismFull=$known{"$organism"};}
    else {
	$organismFull=$organism;}
    $organismTitle="$organismFull"; $organismTitle.=" ($organism)" if ($organism ne $organismFull);

    print $fhout 
	"<HTML>\n",
	"<TITLE>Transmembrane helices for ",$organismTitle,"</TITLE>\n",
	"<BODY>\n",
	"<CENTER>\n",
	"<H1>Transmembrane helices for ",$organismTitle,"</H1>\n",
	"<H2>Jinfeng Liu & Burkhard Rost</H2>\n",
	"<P><P>\n",
	"</CENTER>\n",
	"\n",
	"<P><P>\n",
	"<FONT SIZE=2>CUBIC Columbia Univ., Dept Biochem & Mol Biophysics (",
	"<A HREF=\"mailto:jl840\@columbia.edu\">jl840\@columbia.edu</A>, ",
	"<A HREF=\"mailto:rost\@columbia.edu\">rost\@columbia.edu</A>, ",
	"<A HREF=\"http://dodo.cpmc.columbia.edu/cubic/\">http://dodo.cpmc.columbia.edu/cubic/</A>)",
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
	    if    ($colNames[$itdes]=~/^(num|nhtm|nali|len1|ri|top)/){
		print $fhout "<TD ALIGN=RIGHT>";}
	    elsif ($colNames[$itdes]=~/^(id|htmCN)/){
		print $fhout "<TD ALIGN=LEFT>";}
	    elsif ($colNames[$itdes] eq "seq" && $par{"nperLine"}>0){
		print $fhout "<TD ALIGN=LEFT>";}
	    elsif ($colNames[$itdes] ne "seq"){
		print $fhout "<TD>";}
	    
	    if (defined $body{$it,"$colNames[$itdes]"} && $colNames[$itdes] eq "seq") {
		$seq=$body{$it,"$colNames[$itdes]"};
		if ($par{"nperLine"}>=length($seq)){
		    print $fhout $seq;}
		elsif ($par{"nperLine"}>0){
		    $seqTmp="";
		    for ($res=1;$res<=(length($seq)-$par{"nperLine"});$res+=$par{"nperLine"}){
			$len=$par{"nperLine"}; 
			$len=(length($seq)-$res) if ((length($seq)-$res)<$par{"nperLine"});
			$seqTmp.=substr($seq,$res,$len)." ";}
		    print $fhout $seqTmp;}}
	    elsif (defined $body{$it,"$colNames[$itdes]"} && $colNames[$itdes] eq "htmCN") {
		@tmp=split(/,/,$body{$it,"$colNames[$itdes]"});
		if ($#tmp<5){print $fhout $body{$it,"$colNames[$itdes]"};}
		else        {$tmp="";
			     for ($itx=1;$itx<=($#tmp-5);$itx+=5){
				 foreach $itx2($itx..($itx+5)){
				     last if ($itx2>$#tmp);
				     $tmp.="$tmp[$itx]".",";}
				 $tmp.=" ";}
			     print $fhout $tmp;}}
	    elsif (defined $body{$it,"$colNames[$itdes]"}){
	    	print $fhout $body{$it,"$colNames[$itdes]"};}
	    else {print $fhout " ";} 
	    print $fhout "</TD>";}
	print $fhout "</TR>\n";
				# ------------------------------
				# repeat names
	if (int($it/250)==($it/250)){
	    &wrtRdb2HtmlBodyColNamesHere($fhout,@colNames);}

    }

    print $fhout "\n";
    print $fhout "</TABLE>\n";
    print $fhout "\n\n";
				# ------------------------------
				# final words
    print $fhout
	"<P><P><BR><BR><P><P>\n"."<HR>\n"."<!--"."=" x 50 ."-->\n\n",
	"<A HREF=\"http://dodo.cpmc.columbia.edu/predictprotein\">",
	"<IMG ALIGN=MIDDLE WIDTH=50 HEIGHT=50 SRC=\"../Dfig/icon-pp.gif\" ALT=\"PredictProtein\"></A>\n",
	"<A HREF=\"http://dodo.cpmc.columbia.edu/cubic\">",
	"<IMG ALIGN=MIDDLE WIDTH=50 HEIGHT=50 SRC=\"../Dfig/cubic.gif\" ALT=\"CUBIC\"></A>\n",
	"<A HREF=\"mailto://cubic\@dodo.cpmc.columbia.edu\">",
	"<IMG ALIGN=MIDDLE WIDTH=50 HEIGHT=50 SRC=\"../Dfig/cubic-mail.gif\" ALT=\"Mail to CUBIC\"></A>\n",
	"</BODY>\n","</HTML>\n";
	

}				# end of wrtRdb2HtmlBodyHere

#==========================================================================================
sub wrtRdb2HtmlBodyColNamesHere {
    local ($fhout,@colNames)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBodyColNames      writes the column names (called by previous)
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

#===============================================================================
sub wrtStat {
    local($fhLoc,$title) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtStat                     writes overall statistics
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtStat";


				# ------------------------------
    $cum=$cumIn=$cumOut=0;	# cumulative
    foreach $it(1..$maxNhtm){	# print all
	$ct=$maxNhtm+1-$it;
	$stat{$ct,"in"}=0  if (! defined $stat{$ct,"in"});
	$stat{$ct,"out"}=0 if (! defined $stat{$ct,"out"});
	$stat{$ct,"sum"}= $stat{$ct,"in"} + $stat{$ct,"out"};
	$cum+=   $stat{$ct,"sum"};$stat{$ct,"sum","cum"}=$cum;
	$cumIn+= $stat{$ct,"in"}; $stat{$ct,"in","cum"}= $cumIn;
	$cumOut+=$stat{$ct,"out"};$stat{$ct,"out","cum"}=$cumOut;}
				# ------------------------------
				# header
    print $fhLoc 
	"# Nprd        number of HTM predicted\n",
	"# Nsum        Sum of occurrences\n",
	"# Nin/out     Sum for 'in'/'out'\n",
	"# NBin/out    Sum over proteins with both caps 'in','out'\n",
	"# NC          cumulative sum (starting from highest)\n",
	"# NCin/out    cumulative for 'in'/'out'\n",
#	"# Nexcluded   ",$res{"nProtExcl"}," (as shorter than ",$par{"minLen"},")\n",
	"# NprotTot    ",$par{"nprot"}," (total number of proteins)\n",
	"# NprotHtm    ",$res{"NROWS"}," (total number of proteins with HTMs)\n",
	"# PC/in/out   percentage cumulative (all ORF's =)",int(100*$cum/$par{"nprot"}),")\n";

    printf $fhLoc 
	"%3s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s",
	"Nprd".$title,"Nsum".$title,"Nin".$title,"Nout".$title,
	"NBin","NBout","NC".$title,"NCin".$title,"NCout".$title;
    if ($fhLoc ne "STDOUT" && (defined $par{"nprot"})&&($par{"nprot"}>1)){
	printf $fhLoc 
	    "\t%5s\t%5s\t%5s\n","PC".$title,"PCin".$title,"PCout".$title;}
    else {print $fhLoc "\n";}
    $ct_caps_in=$ct_caps_out=0;
    foreach $ct(1..$maxNhtm){	# print all
	if (($ct/2)==int($ct/2)) {$Leven=1;}else{$Leven=0;}
	if (! $Leven){$stat{$ct,"caps_in"}=$stat{$ct,"in"};
		      $stat{$ct,"caps_out"}=$stat{$ct,"out"};}
	else{$stat{$ct,"caps_in"}=$stat{$ct,"caps_out"}=0;}
	$ct_caps_in+=$stat{$ct,"caps_in"};$ct_caps_out+=$stat{$ct,"caps_out"};
	
	printf $fhLoc "%3d",$ct;
	foreach $kwd ("sum","in","out","caps_in","caps_out"){
	    printf $fhLoc "\t%5d",$stat{$ct,$kwd};}
	foreach $kwd ("sum","in","out"){
	    printf $fhLoc "\t%5d",$stat{$ct,$kwd,"cum"};}
	if (($fhLoc ne "STDOUT")&&(defined $par{"nprot"})&&($par{"nprot"}>1)){
	    printf $fhLoc 
		"\t%5d\t%5d\t%5d\n",
		(100*$stat{$ct,"sum","cum"}/$par{"nprot"}),
		(100*$stat{$ct,"in", "cum"}/$par{"nprot"}),
		(100*$stat{$ct,"out","cum"}/$par{"nprot"});
	}else {print $fhLoc "\n";}
    }
}				# end of wrtStat

