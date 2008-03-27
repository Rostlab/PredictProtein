#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="papers written as HTML by word 98 to finals (first save in word5, then re-import\n".
    "     \t note: this is to correct for the MS-EndNote shit";
$scrNarg=2;
$scrNotes=
    "The following conventions are expected\n".
    "     \t \n".
    "     \t Abstract:\n".
    "     \t    - marked by keyword 'Abstract' or 'Summary'\t \n".
    "     \t \n".
    "     \t References:\n".
    "     \t    - in text marked with 'xxx num'\n".
    "     \t    - references section has same 'xxx num' tags\n".
    "     \t    - End of reference section marked by 'References end'\n".
    "     \t \n".
    "     \t Figures:\n".
    "     \t    - insertion of figures marked by '>>> Fig. D <<<'\n".
    "     \t    - material from Word: put all into directory mat/ (sub of final)\n".
    "     \t    - figures expected in GIF\n".
#    "     \t    - \n".
#    "     \t \n".
    "     \t Abbreviations: ".
    "     \t    - start with 'Abbreviations used', format 'abbr, text; abr2, text2'\n".
    "     \t    - end with tag 'abbreviations end'\n".
    "     \t \n".
    "\n";
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

sub tmpshit{
				# stuff used for temporary
    foreach $tmp (@content){
	++$ct;
	$xx=$tmp;$xx=~s/^[^\[\]]*(\[xxx [^\]]*\]?)[^\[\]]*/$1 /g;
	print "xx $ct $xx\n" if (length($xx)>3 && $xx=~/xxx /);
    }die;
    print join("\n",@content,"\n");die;

}

				# ------------------------------
				# initialise variables
($Lok,$msg)=
    &ini();			&errScrMsg("after ini",$msg,$scrName) if (! $Lok); 


				# --------------------------------------------------
				# (1) read all, join <Hx>name \n </Hx> into single
				#     GLOBAL out: @content,@header,$titlePaper
				# --------------------------------------------------
($Lok,$msg)=
    &rdPaper($fileIn);		&errScrMsg("after rdPaper",$msg,$scrName) if (! $Lok); 


				# --------------------------------------------------
				# (2) move <xyz> </xyz> into one line
				#     IN/OUT: @content
($Lok,$msg)=
    &removeShit();		&errScrMsg("after removeShit",$msg,$scrName) if (! $Lok); 

				# ------------------------------
				# (2b) get abstract
				#      GLOBAL IN:    @content
				#      GLOBAL OUT:   @abstract
($Lok,$msg)=
    &getAbstract();		&errScrMsg("after getAbstract",$msg,$scrName) if (! $Lok); 

				# ------------------------------
				# (2c) get paper title
				#      GLOBAL IN:    @content
				#      GLOBAL OUT:   $title_paper
if (defined $titlePaper && $titlePaper && $titlePaper !~/title/i){
    $title_paper=$titlePaper;
}
else {
    ($Lok,$msg)=
	&getTitle();		&errScrMsg("after getTitle",$msg,$scrName) if (! $Lok); 
}
				# security
$title_paper="TITLExyz"
    if (! defined $title_paper || ! $title_paper);

				# ------------------------------
				# (2d  get authors
if ($paperAuthor=~/author/){
    ($Lok,$msg)=
	&getAuthor();		&errScrMsg("after getAuthor",$msg,$scrName) if (! $Lok); 
}

				# ------------------------------
				# (2e) get abbreviations
				#      GLOBAL IN:    @content
				#      GLOBAL OUT:   @abbreviations,$abbreviations{$kwd}=val
$abbreviations="";
$Labbr=0;
($Lok,$msg)=
    &processAbbreviations();    &errScrMsg("after processAbbreviations",$msg,$scrName) if (! $Lok);

				# --------------------------------------------------
				# (3) digest the content of the file
				#      GLOBAL IN:    @content
				#      GLOBAL OUT:   @rd

($Lok,$msg)=
    &processContent();          &errScrMsg("after processContent",$msg,$scrName) if (! $Lok);


				# --------------------------------------------------
				# (4) get TOC
				#      GLOBAL IN:    @rd
				#      GLOBAL OUT:   @toc ("H1=ABSTRACT, txt=abstract")
				#      GLOBAL OUT:   $figlast,$tablast
				# --------------------------------------------------
($Lok,$msg)=
    &getToc();		        &errScrMsg("after getToc",$msg,$scrName) if (! $Lok); 


				# --------------------------------------------------
				# (5) write header
				# --------------------------------------------------
open($fhout, ">".$fileOut) || die "*** ERROR opening output=$fileOut\n";

$title=~s/\<FONT SIZE=\d+\>|\<\/FONT\>//g;
$kwdHdr=~s/\.\s*$//g;

				# old way of doing it ...
if (0){
    $begOfDoc=~s/TITLExyz/$title_paper/;
    $begOfDoc=~s/KEYWORDSxyz/$kwdHdr/g;
    $begOfDoc=~s/STYLExyz/$styleHeader/;
    print $fhout 
	$begOfDoc;
}
($Lok,$msg)=
    &webCubicPapersHead
    ($fhout,
     $title_paper);		&errScrMsg("after webCubicPapersHead",
					   $msg,$scrName) if (! $Lok); 
($Lok,$msg)=
    &webCubicPapersTop
    ($fhout);			&errScrMsg("after webCubicPapersTop",
					   $msg,$scrName) if (! $Lok); 

                                # --------------------------------------------------
                                # (8) write body
                                # --------------------------------------------------
$Lrefmain=0;
$#references=0;
$ctline_main=0;
$is_author= 0;
$authorTMP="";

foreach $line (@rd){
    ++$ctline_main;
    				# mark up links
    if ($line=~/(http\:\/\/S+)/ && $line!~/HREF=.$1/){
	$tmp=$1;
	$line=~s/$tmp/<A HREF=\"$tmp\">$tmp<\/A>/;
    }
    $lineRd=$line;

				# process authors
    if    (! $is_author && $line=~/class=.author/){
	$is_author=1;
	$authorTMP=$line;
	next; }
    elsif ($is_author==1){
	$authorTMP.=" ".$line;
	if ($line=~/\<.P\>/){
	    $is_author=2;
	    $linetmp=
		&processAuthors($authorTMP);
	    print $fhout $linetmp;
	    next;
	}
    }

				# fill in directory for images
    if ($line=~/SRC=\"Image/){
#	$line=~s/(Image)/$dirOut$1/g;}
	$line=~s/(Image)/$1/g;
    }
				# ------------------------------
				# if ABSTRACT: 
				#    - fill in TOC
				#    - fill in address
    if    ($line=~ /<H\d>.*(abstract\b\s*[^<]*|summary\b\s*[^<]*)/i){
	$txtkeep=$1;
	if ($#toc > 1){
	    ($Lok,$msg)=
		&wrtToc
		    ($fhout);    &errScrMsg("after wrtToc",
					   $msg,$scrName) if (! $Lok); 
	}

	$line= "<BR>\n";
#	$line= "<BR>\n";
#	$line.="<!--"."=" x 50 . "-->\n";
#	$line.="<!-- abstract begin -->\n";
	$line.="<H1><A NAME=\"ABSTRACT\">".$txtkeep."</A></H1>\n";
    }
				# headings 2-n
    elsif ($line =~ /<(H[2-9])>/){
	$level=$1;
	$txt=$line;
	$txt=~s/^.*<H\d>(.*)<\/H.*$/$1/;
	$txt=~s/<\/?[a-zA-Z0-9]+>//g;

	$ref=$txt; 
	$ref=~s/\s/_/g;
	$ref=~s/[^a-zA-z0-9_]//g;
	$ref=~tr/[a-z]/[A-Z]/;
	$ref=~s/^[^0-9A-Z]*|[^0-9A-Z]*$//g;
	$toc=$level."=".$ref.", txt=".$txt;
#	print "--- toc entry=$toc\n";
	$line="\n<$level><A NAME=\"$ref\">$txt</A></$level>\n<P>\n";
	$line="<BR>\n"."<!--"."=" x 50 . "-->\n".$line
	    if ($line=~ /<H2/);
	$line="<BR>\n"."<!--"."=" x 50 . "-->\n".$line;
    }
				# links to tables
				# recognise '>>> <<<' for insert figure here
    elsif ($line=~/\&gt\;\&gt\;\&gt\;[\s\t]*(\btable\s+\d+)[\s\t]*\&lt\;\&lt\;\&lt\;/i ||
	   $line=~/class\=.*ins\-fig.*(table\s+\d+)/i ||
				# next line
	   ($line=~/class\=.*ins\-fig.*(table\s*)$/i && $rd[$ctline_main+1]=~/^(\s*\d+)/)
	   ){
	$linetmp=$1;
	if ($linetmp=~/^\s*\d/){
	    $linetmp="table ".$linetmp;
	    $rd[$ctline_main+1]="";
	}
	($Lok,$msg,$line)=
	    &wrtFig
		($linetmp);	&errScrMsg("after wrtFig_table($linetmp)",$msg,$scrName) if (! $Lok); 
    }
				# links to figures
				# recognise '>>> <<<' for insert figure here
    elsif ($line=~/\&gt\;\&gt\;\&gt\;.*(fig\D*\d+).*\&lt\;\&lt\;\&lt\;/i ||
	   $line=~/class\=.*ins\-fig.*(fig[\s\.]+\d+)/i ||
				# next line
	   ($line=~/class\=.*ins\-fig.*(fig[\s\.]*)$/i && $rd[$ctline_main+1]=~/^([\s\.]*\d+)/)
	   ){
	$linetmp=$1;
	if ($linetmp=~/^\s*\d/){
	    $linetmp="fig. ".$linetmp;
	    $rd[$ctline_main+1]="";
	}
	else {
	    $linetmp=$1;
	}

	($Lok,$msg,$line)=
	    &wrtFig
		($linetmp);	&errScrMsg("after wrtFig($linetmp)",$msg,$scrName) if (! $Lok); 
    }
    elsif ($line=~/\&gt\;\&gt\;\&gt\;/){
	print "xx why? '$line'\n";die;
    }
    elsif (! $Lrefmain) {		# link to figures, tables, equations in text
				# figures
	if ($line=~/\bfig[gure\.]*\s+/i  ||
				# next line
	    ($line=~/\bfig[ure\.]*\s*$/ && $rd[$ctline_main+1]=~/^(\d+)/)
	    ) {
	    if (defined $1){
		$line.=" ".$1;
		$rd[$ctline_main+1]=~s/^\d+\s*//g;
	    }
	    $line=&iterateInTxtLinksFig($line);
	    print "--- in-text link (fig)=$line,\n";
	}
				# tables
	if ($line=~/\bTables?\s+\d+/i    ||
				# next line
	    ($line=~/\bTables?\s*$/ && $rd[$ctline_main+1]=~/^(\d+)/)
	    ) {
	    if (defined $1){
		$line.=" ".$1;
		$rd[$ctline_main+1]=~s/^\d+\s*//g;
	    }
	    $line=&iterateInTxtLinksTab($line);
	    print "--- in-text link (tab)=$line,\n";
	}
	if ($line=~/([Ee]q\.|[Ee]qn\.|[Ee]quation|[Ee]qs\.)\s+\d+/i)  { # eqn
	    $line=&iterateInTxtLinksEqn($line);
	    print "--- in-text link (eqn)=$line,\n";
	}
    }

				# references into list
    if ($lineRd=~/(<H\d+>|<FONT.*>).*\breferences/i){
	$Lrefmain=1;
	print "xx ref begin in line $lineRd\n";die;
	
	if ($lineRd=~/$tagref/) {
	    $tmp=$lineRd;$tmp=~s/^[^$tagref]*($tagref.*)$/$1/;
	    push(@references,&linkFromRef($tmp));
	    $lineRd=~s/(<P>)?$tagref.*$//g;
	}}

    elsif ($Lrefmain && $lineRd=~/$tagref/){
	push(@references,&linkFromRef($line));
#	@tmp=&linkFromRef($line);
#	$line="<P><BR>" . join('',@tmp). "<BR><P>"; }
	next;
    }
				# formulas into tables
    elsif (0 &&! $Lrefmain && $line=~/class.*formula/){
	$tmp1=$lineRd;
	$tmp1=~s/\(Eq.*$//g;
	$tmp2=$lineRd;
	$tmp2=~s/^.*(\(Eqn?\.?\d+\)).*$/$1/g;
	$line= "<TABLE COLS=2 BORDER=0 WIDTH=\"100\%\">";
	$line.="<TR>";
	$line.="<TD VALIGN=TOP ALIGN=CENTER WIDTH=\"90\%\">".$tmp1."</TD>";
	$line.="<TD VALIGN=TOP ALIGN=RIGHT WIDTH=\"10\%\">" .$tmp2."</TD>";
	$line.="</TR></TABLE>\n";
    }

				# add comments
    if ($line=~/<h1>.*(abstract|introduction|methods|results|discussion[^<]*|conclusions|references|acknowledgements)/i){
	$tmp=$par{"commentsBeg"};
	$match=$1;
	$tmp=~s/SUBJECT/$match/;
	$line=$tmp.$line;
    }

				# insert line breaks before '<img ..>'
    $line=~s/(<IMG )/\n$1/ig;
				# remove ids from img
    $line=~s/(<IMG [^>]+) id=\"[^\"]+\"/$1/gi;
				# add line break before '<P>'
    $line=~s/(<P|<P class=[^>]+)(>)/\n$1$2/gi;
    print $fhout 
	$line,"\n";

    if (! defined $fhout || ! defined $line){
	print "*** ERROR problem fhout=$fhout, line=$line\n";
	print "***       linerd=$lineRd\n";
	die;
    }
}

				# --------------------------------------------------
				# (8) finally write references
				# --------------------------------------------------
($Lok,$msg)=
    &wrtReferences
    ($referencesFinal);		&errScrMsg("after wrtReferences",
					   $msg,$scrName) if (! $Lok); 
if (0){
    print $fhout 
	"$endOfDoc\n";}
($Lok,$msg)=
    &webCubicPapersBottom
    ($fhout);			&errScrMsg("after webCubicPapersBottom",
					   $msg,$scrName) if (! $Lok); 

close($fhout);
				# --------------------------------------------------
				# (9) extra file with table of contents
				# --------------------------------------------------
if (0){
    ($Lok,$msg)=
	&wrtTocExtra
	    ($fileIn,
	     $fileToc);		if (! $Lok){ print "*** ERROR $scrName $fileIn\n";
					     print "*** wrtToc returned $msg\n";
					     exit;}
}
				# --------------------------------------------------
				# (10) copy index.html and abstract.html
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
    $paperAuthor="Burkhard Rost" 
	if ($paperAuthor=~/author/i);
    while(<$fhin>){
	$_=~s/(<TITLE>.*)title_xx/$1$title/;
	$_=~s/title_xx/$title_paper/g;
	$_=~s/abstract_xx/$abstract/;
	$_=~s/author_xx/$paperAuthor/;
	print $fhout $_;}
    close($fhout);
    close($fhin); }
	
				# 

print "--- ","-" x 80,"\n";
print "--- output in :                \t $fileOut\n";
#print "--- toc    in :                \t $fileToc\n"      if (-e $fileToc);
print "--- index  in :                \t $fileOutIndex\n" if (-e $fileOutIndex);
print "--- abstr  in :                \t $fileOutAbstr\n" if (-e $fileOutAbstr);
print "---           \n";
if (0){
    print "--- ************************************************************ \n";
    print "--- put links (and toc) into : \t $dirOut\n";
    print "--- ************************************************************ \n";
    print "---           \n";
    print "--- ","-" x 80,"\n";
}
exit;



#==============================================================================
# library collected (begin)
#==============================================================================


#===============================================================================
sub brIniWrt {
    local($exclLoc,$fhTraceLocSbr)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniWrt                    write initial settings on screen
#       in:                     $excl     : 'kwd1,kwd2,kw*' exclude from writing
#                                            '*' for wild card
#       in:                     $fhTrace  : file handle to write
#                                  = 0, or undefined -> STDOUT
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniWrt";
    
    return(0,"*** $sbrName: no settings defined in %par\n") if (! defined %par || ! %par);
    $fhTraceLocSbr="STDOUT"    if (! defined $fhTraceLocSbr || ! $fhTraceLocSbr);

    if (defined $Date) {
	$dateTmp=$Date; }
    else {
	$tmp=`date`; $tmp=~s/\n//g if (defined $tmp);
	$dateTmp=$tmp || "before year 2000"; }

    print $fhTraceLocSbr "--- ","-" x 80, "\n";
    print $fhTraceLocSbr "--- Initial settings for $scrName ($0) on $dateTmp:\n";
    @kwd= sort keys (%par);
				# ------------------------------
				# to exclude
    @tmp= split(/,/,$exclLoc)   if (defined $exclLoc);
    $#exclLoc=0; 
    undef %exclLoc;
    foreach $tmp (@tmp) {
	if   ($tmp !~ /\*/) {	# exact match
	    $exclLoc{$tmp}=1; }
	else {			# wild card
	    $tmp=~s/\*//g;
	    push(@exclLoc,$tmp); } }
    if ($#exclLoc > 0) {
	$exclLoc2=join('|',@exclLoc); }
    else {
	$exclLoc2=0; }
	
    
	    
    $#kwd2=0;			# ------------------------------
    foreach $kwd (@kwd) {	# parameters
	next if (! defined $par{$kwd});
	next if ($kwd=~/expl$/);
	next if (length($par{$kwd})<1);
	if ($kwd =~/^fileOut/) {
	    push(@kwd2,$kwd);
	    next;}
	next if ($par{$kwd} eq "unk");
	next if (defined $exclLoc{$kwd}); # exclusion required
	next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{$kwd};}
				# ------------------------------
    if ($#kwd2>0){		# output files
	print $fhTraceLocSbr "--- \n","--- Output files:\n";
	foreach $kwd (@kwd2) {
	    next if ($par{$kwd} eq "unk"|| ! $par{$kwd});
	    next if (defined $exclLoc{$kwd}); # exclusion required
	    next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	    printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{$kwd};}}
				# ------------------------------
				# input files
    if    (defined @fileIn && $#fileIn>1){
				# get dirs
	$#tmpdir=0; 
	undef %tmpdir;
	foreach $file (@fileIn){
	    if ($file =~ /^(.*\/)[^\/]/){
		$tmp=$1;$tmp=~s/\/$//g;
		if (! defined $tmpdir{$tmp}){push(@tmpdir,$tmp);
					     $tmpdir{$tmp}=1;}}}
				# write
	print  $fhTraceLocSbr "--- \n";
	printf $fhTraceLocSbr "--- %-20s number =%6d\n","Input files:",$#fileIn;
	printf $fhTraceLocSbr "--- %-20s dirs   =%-s\n","Input dir:", join(',',@tmpdir) 
	    if ($#tmpdir == 1);
	printf $fhTraceLocSbr "--- %-20s dirs   =%-s\n","Input dirs:",join(',',@tmpdir) 
	    if ($#tmpdir > 1);
	for ($it=1;$it<=$#fileIn;$it+=5){
	    print $fhTraceLocSbr "--- IN: "; 
	    $it2=$it; 
	    while ( $it2 <= $#fileIn && $it2 < ($it+5) ){
		$tmp=$fileIn[$it2]; $tmp=~s/^.*\///g;
		printf $fhTraceLocSbr "%-18s ",$tmp;++$it2;}
	    print $fhTraceLocSbr "\n";}}
    elsif ((defined @fileIn && $#fileIn==1) || (defined $fileIn && -e $fileIn)){
	$tmp=0;
	$tmp=$fileIn    if (defined $fileIn && $fileIn);
	$tmp=$fileIn[1] if (! $tmp && defined @fileIn && $#fileIn==1);
	print  $fhTraceLocSbr "--- \n";
	printf $fhTraceLocSbr "--- %-20s '%-s'\n","Input file:",$tmp;}
    print  $fhTraceLocSbr "--- \n";
    printf $fhTraceLocSbr "--- %-20s %-s\n","excluded from write:",$exclLoc 
	if (defined $exclLoc);
    print  $fhTraceLocSbr "--- \n","--- ","-" x 80, "\n","--- \n";
	
    return(1,"ok $sbrName");
}				# end of brIniWrt

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

#===============================================================================
sub date_monthDayYear2num {
    local($datein) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   date_monthDayYear2num       converts date from 'Feb 14, 1999' -> 14-02-1999
#       in:                     $date
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."date_monthDayYear2num";
    return(0,"no input")        if (! defined $datein);
    return(0,"no valid input")  
	if ($datein !~ /([a-zA-z][a-zA-z][a-zA-z])[\s\-_\.,]+(\d+)[\s\-_\.,]+(\d+)/);
    $month=$1;
    $day=  $2;
    $year= $3;
				# convert month
    ($Lok,$msg,$num)=&date_monthName2num($month);
    return(0,"failed converting month=$month! msg=\n".$msg) if (! $Lok);
				# add leading zeroes
    $day=  "0".$day             if (length($day)<2);
    $num=  "0".$num             if (length($num)<2);
    $out=$day."-".$num."-".$year;
    return(1,$out);
}				# end of date_monthDayYear2num

#===============================================================================
sub date_monthName2num {
    local($txtIn) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   date_monthName2num          converts month name to number
#       in:                     $month
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."date_monthName2num";
    return(1,"ok","01") if ($txtIn=~/^jan/i);
    return(1,"ok","02") if ($txtIn=~/^feb/i);
    return(1,"ok","03") if ($txtIn=~/^mar/i);
    return(1,"ok","04") if ($txtIn=~/^apr/i);
    return(1,"ok","05") if ($txtIn=~/^may/i);
    return(1,"ok","06") if ($txtIn=~/^jun/i);
    return(1,"ok","07") if ($txtIn=~/^jul/i);
    return(1,"ok","08") if ($txtIn=~/^aug/i);
    return(1,"ok","09") if ($txtIn=~/^sep/i);
    return(1,"ok","10") if ($txtIn=~/^oct/i);
    return(1,"ok","11") if ($txtIn=~/^nov/i);
    return(1,"ok","12") if ($txtIn=~/^dec/i);
    return(0,"month=$txtIn, is what??",0);
}				# end  date_monthName2num

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

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
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/rost/perl/ctime.pl",           # HARD_CODED
	  "/home/rost/pub/perl/ctime.pl",       # HARD_CODED
	  "/home/phd/server/scr/lib/ctime.pm"   # HARD_CODED
	  );
    foreach $tmp (@tmp) {
	next if (! -e $tmp && ! -l $tmp);
	$exe_ctime=$tmp;	# local ctime library
	last; }

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    $Lok=
		require($exe_ctime)
		    if (-e $exe_ctime); }
				# ------------------------------
				# found one: use it
	if ($Lok && 
	    defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);} }
				# ------------------------------
	 			# found none: take system
    if (! $Lok) {
	$localtime=`date`;
	@Date=split(/\s+/,$localtime);
	$Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]"; }
    $date=$Date; $date=~s/(199\d|200\d)\s*.*$/$1/g;
    return($Date,$date);
}				# end of sysDate


#==============================================================================
# library collected (end)
#==============================================================================


#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."ini";     

				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
#    &iniLib();			# require perl libraries

				# ------------------------------
    $timeBeg="";		# avoid warning
    $timeBeg=             time;	# date and time
    $DATE_TIME="";		# avoid warning
    ($DATE_TIME,$DATE)=   &sysDate();
    ($Lok,$date_num)=     &date_monthDayYear2num($DATE);
    @tmp=split(/\-/,$date_num);
#    $DATE_SORT=$tmp[3]."_".$tmp[2]."_".$tmp[1];
#    $DATE_YEAR_HERE= $tmp[3];
#    $DATE_MONTH_HERE=$tmp[2];
#    $DATE_DAY_HERE=  $tmp[1];


				# ------------------------------
				# help
    if ($#ARGV < $scrNarg){
	print  $scrNotes;
	print  "goal:  $scrGoal\n";
	print  "use:  '$scrName paper dir_to_put'\n";
	print  "note0: dir_to_put must be of form '2ddd_*'!\n";
	print  "\n";
	print  "\n";
	print  "note1: format references in style 'xx-ms2www'\n";
	print  "note2: give file its final name (for TOC)\n";
	print  "opt:   \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s %-20s %-s\n","","ol",   "no value",   "references numbered";
	printf "%5s %-15s %-20s %-s\n","","ul",   "no value",   "references not numbered";
	printf "%5s %-15s %-20s %-s\n","","small","no value", "figures will NOT be in text, only linked (to save loading time)";

	printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
	printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
	printf "%5s %-15s=%-20s %-s\n","","title",   "x",       "title of manuscript";

#	printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#	printf "%5s %-15s %-20s %-s\n","","",   "no value","";

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
    $fhin=   "FHIN";
    $fhout=  "FHOUT";
#    $fhTrace="FHTRACE";
    $dirOut= 0;
				# ------------------------------
				# read command line
    foreach $arg (@ARGV){
	if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=          $1;}
	elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=           $1; 
						$dirOut.=          "/" if ($dirOut !~/\/$/);}
	elsif ($arg=~/^de?bu?g$/)             { $Ldebug=           1;
						$Lverb=            1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=            1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=            0;}
#	elsif ($arg=~/^=(.*)$/){ $=$1;}
	elsif (-e $arg && ! -d $arg)          { push(@fileIn,$arg); }
	elsif ($arg=~/^ol/)                   { $par{"order"}=     1;}
	elsif ($arg=~/^ul/)                   { $par{"order"}=     0;}
	elsif ($arg=~/^small/i)               { $par{"doLinkFig"}= 1;}
#	elsif ($arg=~/^title=(.*)$/)          { $titleRd=          $1;}
	elsif ($arg=~/^2\d\d\d/)              { $dirOut=           $arg;}
	else {
	    print "xx else $arg\n";
	    if (defined %par && $#kwd>0) { 
		foreach $kwd (@kwd){ 
		    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					       last;}}}
	    if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}
				# 

    $fileIn=$fileIn[1];
    die ("missing input $fileIn\n") if (! -e $fileIn);
    die ("missing dirout (should be input argument with 'yyyy_*') $dirOut\n") if (! defined $dirOut || ! $dirOut);

    if (! -d $dirOut) {
	$dirOut=~s/\/$//g;
	system("mkdir $dirOut");}
    $dirOut.="/"                    if (length($dirOut)>1 && $dirOut !~/\/$/);
    $title=$dirOut if (! defined $titleRd || ! $titleRd);
    
    $contact="contact e-mail:<A HREF=\"mailto:".
	$par{"contact_email"}."\">".$par{"contact_email"}."</A>\n";

    $fileToc=      $dirOut."toc.html";
    $fileOut=      $dirOut."paper.html" if (! defined $fileOut || ! $fileOut);
    $fileOutAbstr= $dirOut."abstract.html";
    $fileOutIndex= $dirOut."index.html";

				# ------------------------------
				# hierarchy of blabla
    $par{"debug"}=  $Ldebug;
    $par{"verbose"}=$Lverb;
    $par{"verb3"}=1             if ($par{"debug"});
    $par{"verb2"}=1             if ($par{"verb3"});
    $par{"verbose"}=1           if ($par{"verb2"});
	
				# ------------------------------
				# write settings
				# ------------------------------
    if ($par{"debug"}){
	$exclude="kwd,dir*,ext*";	# keyword not to write
	$fhloc="STDOUT";
	($Lok,$msg)=
	    &brIniWrt($exclude,$fhloc);
	return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR))  if (! $Lok); 
    }

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $SBR");
}				# end of ini

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      initialise defaults
#-------------------------------------------------------------------------------

				# ------------------------------
				# defaults
    $USER=$ENV{'USER'};

    if (! defined $USER || $USER =~/cubic/i || $USER !~/rost/){
	$par{"dirWeb"}=             "/home/cubic/public_html/papers/";
	$par{"dirWebRoot"}=         "/home/cubic/public_html/";
    }
    else {
	$par{"dirWeb"}=             "/home/rost/public_html/papers/";
	$par{"dirWebRoot"}=         "/home/rost/public_html/";
    }

				# ------------------------------
				# defaults

    $par{"cubicURL"}=           "http://cubic.bioc.columbia.edu/";
    $par{"cubicPapersURL"}=     "http://cubic.bioc.columbia.edu/papers/";
    $par{"cubicURL_rel"}=       "../../index.html";
    $par{"cubicPapersURL_rel"}= "../index.html";
    $par{"cubicAcronym"}=       "CUBIC";
    $par{"contact_email"}=      "rost\@columbia.edu";
#    $par{"templateIndex"}=      "/home/cubic/public_html/MAT/papTemplateIndex.html";
#    $par{"templateAbstr"}=      "/home/cubic/public_html/MAT/papTemplateAbstr.html";

    $par{"templateIndex"}=      "/home/rost/public_html/MAT/papTemplateIndex.html";
    $par{"templateAbstr"}=      "/home/rost/public_html/MAT/papTemplateAbstr.html";
    $par{"fileAddress"}=        "/home/rost/public_html/MAT/cubic_address.rdb";

    $par{"order"}=              0;      # =1 -> ordered reference list

    $par{"doLinkFig"}=          0;      # =1 means figures NOT in text, only linked

    $par{"commentsBeg"}=        "<!-- ================================================== -->\n";
    $par{"commentsBeg"}.=       "<!-- SUBJECT -->\n";
    $par{"commentsBeg"}.=       "<!-- ================================================== -->\n";
    $par{"commentsBeg"}.=       "\n";


    $tagref=    "xxx ";		# recognise references

    @kwd=sort (keys %par);
    $Ldebug=0;
    $Lverb= 0;
    $fhin="FHIN";$fhout="FHOUT";
    $#fileIn=0;


    $style{"DIV.subtoc"}= "DIV.subtoc  { \n";
    $style{"DIV.subtoc"}.="\t padding: 1em; \n";
    $style{"DIV.subtoc"}.="\t margin: 1em 0\;\n";
    $style{"DIV.subtoc"}.="\t border: thick inset\;\n";
    $style{"DIV.subtoc"}.="\t background: silver\; \}\n";
	
    $style{"H1"}=         "H1  { \n";
    $style{"H1"}.=        "\t ansi-language:EN-GB\;\n";
    $style{"H1"}.=        "\t font-size:16.0pt\;\n";
    $style{"H1"}.=        "\t font-family:Times\;\n";
    $style{"H1"}.=        "\t text-align:center\; \}\n";
	
    $style{"H2"}=         "H2  { \n";
    $style{"H2"}.=        "\t ansi-language:EN-GB\;\n";
    $style{"H2"}.=        "\t font-size:14.0pt\;\n";
    $style{"H2"}.=        "\t font-family:Times\;\n";
    $style{"H2"}.=        "\t text-align:left\; \}\n";
	
    $style{"H3"}=         "H3  { \n";
    $style{"H3"}.=        "\t ansi-language:EN-GB\;\n";
    $style{"H3"}.=        "\t font-size:12.0pt\;\n";
    $style{"H3"}.=        "\t font-family:Times\;\n";
    $style{"H3"}.=        "\t text-align:left\; \}\n";
	
    $style{"P.cap"}=      "P.cap { \n";
    $style{"P.cap"}.=     "\t ansi-language:EN-GB\;\n";
    $style{"P.cap"}.=     "\t font-size:10.0pt\;\n";
    $style{"P.cap"}.=     "\t font-family:Times\;\n";
    $style{"P.cap"}.=     "\t text-align:justify\; \}\n";
	
    $style{"P.formula"}=  "P.formula { \n";
    $style{"P.formula"}.= "\t ansi-language:EN-GB\;\n";
    $style{"P.formula"}.= "\t font-size:12.0pt\;\n";
    $style{"P.formula"}.= "\t font-family:Times\;\n";
    $style{"P.formula"}.= "\t text-align:center\; \}\n";
	
    $style{"P.left"}=     "P.left { \n";
    $style{"P.left"}.=    "\t ansi-language:EN-GB\;\n";
    $style{"P.left"}.=    "\t font-size:12.0pt\;\n";
    $style{"P.left"}.=    "\t font-family:Times\;\n";
    $style{"P.left"}.=    "\t text-align:left\; \}\n";
	
    $style{"P.list"}=     "P.list { \n";
    $style{"P.list"}.=    "\t ansi-language:EN-GB\;\n";
    $style{"P.list"}.=    "\t font-family:Times\;\n";
    $style{"P.list"}.=    "\t font-size:12.0pt\;\n";
    $style{"P.list"}.=    "\t text-align:justify\; \}\n";
	
    $style{"P.text"}=     "P.text { \n";
    $style{"P.text"}.=    "\t ansi-language:EN-GB\;\n";
    $style{"P.text"}.=    "\t font-size:12.0pt\;\n";
    $style{"P.text"}.=    "\t font-family:Times\;\n";
    $style{"P.text"}.=    "\t text-align:justify\; \}\n";
	    
    $style{"P.title"}=    "P.title { \n";
    $style{"P.title"}.=   "\t ansi-language:EN-GB\;\n";
    $style{"P.title"}.=   "\t font-weight:bold\;\n";
    $style{"P.title"}.=   "\t font-size:18.0pt\;\n";
    $style{"P.title"}.=   "\t font-family:Times\;\n";
    $style{"P.title"}.=   "\t text-align:center\; \}\n";
	
    $style{"P.author"}=   "P.author { \n";
    $style{"P.author"}.=  "\t ansi-language:EN-GB\;\n";
    $style{"P.author"}.=  "\t font-weight:bold\;\n";
    $style{"P.author"}.=  "\t font-size:14.0pt\;\n";
    $style{"P.author"}.=  "\t font-family:Times\;\n";
    $style{"P.author"}.=  "\t text-align:center\; \}\n";
	
    $style{"LI"}=         "LI { \n";
    $style{"LI"}.=        "\t ansi-language:EN-GB\;\n";
    $style{"LI"}.=        "\t font-size:12.0pt\;\n";
    $style{"LI"}.=        "\t font-family:Times\;\n";
    $style{"LI"}.=        "\t text-align:justify\; \}\n";

    $style{"LI.address"}= "LI.address { \n";
    $style{"LI.address"}.="\t ansi-language:EN-GB\;\n";
    $style{"LI.address"}.="\t font-size:10.0pt\;\n";
    $style{"LI.address"}.="\t font-family:Times\;\n";
    $style{"LI.address"}.="\t text-align:justify\; \}\n";
	
    $style{"LI.ref"}=     "LI.ref { \n";
    $style{"LI.ref"}.=    "\t ansi-language:EN-GB\;\n";
    $style{"LI.ref"}.=    "\t font-size:12.0pt\;\n";
    $style{"LI.ref"}.=    "\t font-family:Times\;\n";
    $style{"LI.ref"}.=    "\t text-align:justify\; \}\n";
	
    $style{"SUP"}=         "SUP { \n";
    $style{"SUP"}.=        "\t ansi-language:EN-GB\;\n";
    $style{"SUP"}.=        "\t font-size:10.0pt\;\n";
    $style{"SUP"}.=        "\t font-family:Times\; \}\n";

    $#tmp2=0;
    undef %tmp2;
    foreach $kwd (sort(keys(%style))){
	if (! defined $tmp2{$kwd}){
	    push(@tmp2,$kwd);
	    $tmp2{$kwd}=1;
	}
    }
    @kwdStyle=@tmp2;
    $#tmp2=0;
    undef %tmp2;

    $styleHeader="";
    foreach $kwd (@kwdStyle){
	$styleHeader.=$style{$kwd}."\n";
    }

    $dirMat="mat/";


				# bottom links for
				# doc in: public_html/DIR
    $endOfDoc="<P>".
	"</BODY>\n".
	    "</HTML>\n";

    $begOfDoc= "<HTML>\n"."<HEAD>\n";
    $begOfDoc.="<META NAME=\"FirstName\" value=\"CUBIC\">\n";
    $begOfDoc.="<META NAME=\"LastName\" value=\"Rost Group\">\n";
    $begOfDoc.="<META name=\"description\" content=\"Papers\">\n";
    $begOfDoc.="<META name=\"keywords\"    content=\"KEYWORDSxyz\">\n";
    $begOfDoc.="<STYLE>\nSTYLExyz\n</STYLE>\n";
    $begOfDoc.="<TITLE>TITLExyz<\/TITLE>\n";
    $begOfDoc.="<\/HEAD>\n"."\n"."<!--"."=" x 50 ."-->\n\n";
    $begOfDoc.="<BODY style=\"background:white\">\n";    

    $nbsp=$gt=$lt="";
    $nbsp="\&nbsp\;";
    $gt=  "\&gt\;";
    $lt=  "\&lt\;";

    $tagSpanBeg= "<span[^>]+>";
    $tagSpanEnd= "<\/span>";
    $tagIfBeg=   "<\!.if[^>]+>";
    $tagIfEnd=   "<\!.endif[^>]+>";
    $tagVshapeBeg=   "<v:shape [^>]+>";
    $tagVshapeEnd=   "<\/v:shape[^>]*>";

    @tagExcl=
	($tagSpanBeg,$tagSpanEnd,
	 $tagIfBeg,$tagIfEnd,
	 $tagVshapeBeg,$tagVshapeEnd,
	 );

}				# end of iniDef

#===============================================================================
sub getAbstract {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getAbstract                       
#       in GLOBAL:              @content
#       out GLOBAL:             @abstract
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."getAbstract";

    $#abstract=$Lok=0;
    foreach $tmp (@content) {
	last if ($tmp=~/end abstract|abstract end/i    ||
		 $tmp=~/key words|abbreviations used/i ||
		 ($Lok && (
			   $tmp=~/introduction/i ||
			   $tmp=~/<H[123]>/)));
	if ($tmp=~/H\d[\s\t\.\>\<]*\b(abstract|summary)\b/i) {
	    $Lok=1;
	    next;}

	next if (! $Lok);
	push(@abstract,$tmp);
    }
    
    return(1,"ok $sbrName");
}				# end of getAbstract

#===============================================================================
sub getAuthor {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getAuthor                   find author names
#                               also reads the author-address template file
#                               MAT/cubic_address.rdb
#       in GLOBAL:              @content
#       out GLOBAL:             $paperAuthor (simple text line with all)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."getAuthor"; $fhinLoc="FHIN_"."getAuthor";
    


				# ------------------------------
				# author addresses
    $file=$par{"fileAddress"};
    return(&errMsgSbr("missing template for kwd=fileAddress, file=$file",$SBR))
	if (! -e $file);
#    print "xyx- kwd=$kwd, temp=$file\n";
    open($fhinLoc,$file) || return(&errSbr("file(fileAddress)=$file, not opened",$SBR));
    $template{"address"}="";
    $cttmp=0;
    while (<$fhinLoc>) {
	++$cttmp;
	next if ($_=~/^\#/);
	next if ($_=~/^\s*$/);
	next if ($_=~/^Name/i);
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);
	if ($#tmp<2){
	    print "-*- WARN problem with addresses ($file): line=$cttmp, $_ no tab?\n";
	    next;
	}
	$name=$tmp[1];
	$name=~s/^\s*|\s*$//g;	# leading blanks
	$name=~tr/[A-Z]/[a-z]/;	# all small caps
	$name=~s/[^a-z\s]//g;	# non blank/character
	$template{"address"}.=$name."\t";
	$template{"address",$name}=$#tmp-1;
	foreach $it (2..$#tmp){
	    $template{"address",$name,($it-1)}=$tmp[$it];
	}
    }
    close($fhinLoc);

				# ------------------------------
				# find authors
    $cttmp=0;
    foreach $tmp (@content) {
	++$cttmp;
	if ($tmp=~/class=.*author[^\>]+>\s*(.*)<\/p>/i){
	    $tmp_author=$1; 
	    $tmp_author=~s/\n//g;
	    $tmp_author=~s/<BR>//ig;
	    print "xx found ($tmp)! $tmp_author\n";
	    last;
	}
				# not full title in line
	elsif ($tmp=~/class=.*author[^\>]+>(.*)/i){
	    $tmp_author=$1." "; 
				# continue reading next lines
	    while ($cttmp < $#content){
		++$cttmp;
		$tmp_author.=$content[$cttmp];
		last if ($content[$cttmp]=~/<\/p>/i);
	    }
	    $tmp_author=~s/<BR>//ig;
	    $tmp_author=~s/<\/p>//ig;
	    $tmp_author=~s/ \s+/ /g;
	    last;
	}
    }
    $tmp_author=~s/<sup>[^>]+<\/sup>//g;
    $paperAuthor=$tmp_author;

    return(1,"ok $sbrName");
}				# end of getAuthor

#===============================================================================
sub getTitle {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getTitle                       
#       in GLOBAL:              @content
#       out GLOBAL:             $title_paper
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."getTitle";

    $cttmp=0;
    $title_paper="";
    foreach $tmp (@content) {
	++$cttmp;
	if ($tmp=~/class=.*title.*>(.*)<\/p>/i){
	    $title_paper=$1; 
	    $title_paper=~s/\n//g;
	    $title_paper=~s/<BR>//ig;
	    last;
	}
				# not full title in line
	elsif ($tmp=~/class=.*title.*>(.*)/i){
	    $title_paper=$1." "; 
				# continue reading next lines
	    while ($cttmp < $#content){
		++$cttmp;
		$title_paper.=$content[$cttmp];
		last if ($content[$cttmp]=~/<\/p>/i);
	    }
	    $title_paper=~s/<BR>//ig;
	    $title_paper=~s/<\/p>//ig;
	    $title_paper=~s/ \s+/ /g;
	    last;
	}
    }
    $paperTitle=$titlePaper=
	$title_paper;

    return(1,"ok $sbrName");
}				# end of getTitle

#===============================================================================
sub getToc {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getToc                       
#       in GLOBAL:              @rd
#       out GLOBAL:             @toc,$figlast,$tablast
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."getToc";

    $#toc=     0;
    $figlast=  0;
    $tablast=  0;
    $ctit=     0;
    $Lref_done=0;
    foreach $line (@rd){
	++$ctit;
	$lineRd=$line;
				# find out how many figures there are
	if ($line=~/\bFig\.\s+(\d+)/     || 
				# next line
	    ($line=~/\bFig\.\s*$/ && $rd[$ctit+1]=~/^(\d+)/)
	    ){
	    $num=$1;
	    $figlast=$num if (defined $num && $num=~/\d/ && $figlast<$num);
	}
				# find out how many tables there are
	if ($line=~/\bTable\s+(\d+)/ ||
				# next line
	    ($line=~/\bTable\s*$/ && $rd[$ctit+1]=~/^(\d+)/)
	    ){
	    $num=$1;
	    $tablast=$num if (defined $num && $num=~/\d/ && $tablast<$num);
	}

	if ($line=~ /\<H\d\>.*(abstract|summary)/i){ 
	    $txt_tmp=$1;
	    push(@toc,"H1=ABSTRACT, txt=".$txt_tmp); 
	    print "--- toc entry(abstr)=$1\n"; 
	    $toc{$txt_tmp,"NAME"}="ABSTRACT"; 
	}  
                          # headings 2-n 
	elsif ($line =~ /<(H[1-9])>/i){ 
	    $level=$1;
	    $txt=$line; $txt=~s/^.*<H\d>(.*)<\/H.*$/$1/i;
	    $txt=~s/^.*<[^>]+>([^<]+)<.*$/$1/g;
	    $txt=~s/<\/?[a-zA-Z0-9]+>//g; 
	    $ref=$txt; 
            $ref=~s/\s/_/g;
	    $ref=~s/[^a-zA-z0-9_]//g; 
            $ref=~tr/[a-z]/[A-Z]/;
	    $ref=~s/^[^0-9A-Z]*|[^0-9A-Z]*$//g; # $ref=~s/NBSP//ig;
	    $toc=$level."=".$ref.", txt=".$txt; 
            print "--- toc entry=$toc\n"; 
            push(@toc,$toc); # add tags for TOC
	    
	    $tmpbeg="<A NAME=\"$ref\">"; $tmpend="</A>";
	    $line=~s/(<H[1-9][^>]*>)(.*)(<.*\/H[1-9]>)/$1$tmpbeg$2$tmpend$3/;
	    $toc{$txt,"NAME"}=$ref; 
	    $Lref_done=1        if ($line=~/\breferences/i);
        } # 
#	elsif ($line=~/\breferences/i){
#	    print "xx toc shit $line\n";die;
#	} 
    }
				# add references
    if (! $Lref_done){
	push(@toc,"H1=REFERENCES, txt=References");
    }
				# add figures and tables to TOC 
    if    ($figlast==1){ 
	push(@toc,"H1=FIGURES, txt=Figure"); 
	$toc{"figures"}=$figlast;
    } 
    elsif ($figlast>1){ 
	push(@toc,"H1=FIGURES, txt=Figures"); 
	$toc{"figures"}=$figlast;
    } 
    if    ($tablast==1){ 
	push(@toc,"H1=TABLES, txt=Table"); 
	$toc{"tables"}=$tablast;
    }
    elsif ($tablast>1){ 
	push(@toc,"H1=TABLES, txt=Tables"); 
	$toc{"tables"}=$tablast;
    }
    return(1,"ok $sbrName");
}				# end of getToc

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
	    $tmp1=~s/(fig\D*\s+\d+\s*[\-,]?\s*\d*)//io;
	    $tmp2=$1;
	    $range=$tmp2;
	    if (length($tmp2)<1){
		print "xx big problem iterateInTxtLinksFig line=$lineTmp, tmp2=$tmp2\n";
		die;}

	    $range=~s/^\D*(\d+\s*[\-,]?\s*\d*).*$/$1/
		if ($range=~/^\D*\d+\s*[\-,]?\s*\d*/);
	    $range=~s/\s//g;
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
    if ($lineTmp=~/\bTables?\s+\d+\s*[\-,]?\s*\d*/i){ # allow many
	$tmp1=$lineTmp; $ct=0;
	while ($tmp1 =~ /\bTables?\s+\d+\s*[\-,]?\s*\d*/i && $ct<10){
	    ++$ct;
	    $tmp1=~s/(\bTables?\s+\d+\s*[\-,]?\s*\d*)//io;
	    $tmp2=$1;
	    $range=$tmp2;
	    $range=~s/^\D*(\d+\s*[\-,]?\s*\d*).*$/$1/;
	    $range=~s/\s//g;
            @num=&get_range($range);$new="";
	    foreach $num(@num){
		$new.=" <A HREF=\"\#table$num\">Table $num<\/A>, ";
	    }
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
    if ($lineTmp=~/\Weqn?s?[\. ]+\d+\s*[\-,]?\s*\d*/i){ # allow many
	$tmp1=$lineTmp; 
	$ct=0;
	while ($tmp1 =~ /\Weqn?s?[\. ]+\d+\s*[\-,]?\s*\d*/i && $ct<10){
	    ++$ct;
	    $tmp1=~s/(\W)(eqn?[s\. ]*\d+\s*[\-,]?\s*\d*)/$1/io;
	    $tmp2=$2;
	    $tmp2=~s/>\s*$//g;
	    $range=$tmp2;
	    $range=~s/^\D*(\d+\s*[\-,]?\s*\d*).*$/$1/;
	    $range=~s/\s//g;
            @num=&get_range($range);
	    $new="";
	    foreach $num(@num){
		if ($lineTmp=~/class=\"?formula/){
		    $new.=" <A NAME=\"eqn$num\">eqn\. $num<\/A>, ";
		}
		else {
		    $new.=" <A HREF=\"\#eqn$num\">eqn\. $num<\/A>, ";
		}
	    }
	    $new=~s/, $//g;
	    $lineTmp=~s/$tmp2/$new/;
	    if ($lineTmp=~/>([\s\n]*)$/){
		if (defined $1){ 
		    $tmpend=$1;}
		else {
		    $tmpend="";}
		$tmp=")";
		$lineTmp=~s/>([\s\n]*)$/$tmp$tmpend/;
	    }
	}
	if ($lineTmp=~/>([\s\n]*)$/){
	    if (defined $1){ 
		$tmpend=$1;}
	    else {
		$tmpend="";}
	    $tmp=")";
	    $lineTmp=~s/>([\s\n]*)$/$tmp$tmpend/;
	}
    }
    return($lineTmp);
}				# end of iterateInTxtLinksEqn

# ================================================================================
sub linkToRef {
    local($in)=@_;
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------

    $tmpLine=$in;
    while ($tmpLine=~/\[xxx \d/){
	$tmp2Line=$tmpLine;
				# note can be [xxx 42; 43; 44;
	$tmp2Line=~s/\[xxx ([^\]]+)\]//;
	$tmp=$1;
	if (! defined $tmp || length($tmp)<1){
	    print "*** linkToRef ERROR with\n  line=$tmpLine, \ntmp2line=$tmp2Line\n";
	    die;
	}
	if (! defined $tmp){
	    print "xx problem with tmpline=$tmpLine, tmp not defined!\n";
	    die;}
	$tmp=~s/\s//g;
	@tmp=split(/\;/,$tmp);
	$tmp2="";
	foreach $tmp (@tmp){
	    $tmp2.="<A HREF=\"\#ref$tmp\">$tmp<\/A>".", ";
	}
	$tmp2=~s/, $//;
	$tmp2=" [".$tmp2."] ";
	$tmpLine=~s/\[xxx ([^\]]+)\]/$tmp2/;
    }
    return($tmpLine);}
# ================================================================================
sub linkFromRef {
    local($in)=@_;local(@out);
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------

    $in=~s/\n//g;
    $in=~s/<P>|<\/P>//g;
    $in=~s/^[^x]*//g;
    @tmp=split(/xxx[\s\t\n]+/,$in);
    $#out=0;
    foreach $tmp (@tmp){
	if ($tmp=~/^(\s*)$/) {
	    next;}
#	next if ($tmp eq $tmp[1]); # ignore first (as starts with '  xxx 1')
	$tmp1=$tmp;$tmp1=~s/^\s*(\d+) .*$/$1/;
	$tmp1="<A NAME=\"ref$tmp1\">$tmp1<\/A>".". ";
	$tmp=~s/^\d+ (.*)$/$tmp1 $1/;
	$tmp=~s/<\/P>[\s\t\n]*$//g;
	$tmp=~s/\s\s+/ /g;
	$tmp=~s/^[\s\t]*|[\s\t]*$//g;
	$tmp=~s/<LI>|<UL>|<OL>//g;
	$tmp=~s/<\/LI>|<\/UL>|<\/OL>//g;
	push(@out,"<LI> $tmp </LI>\n")
	    if (length($tmp)>3);
    }
    return(@out);}

# ================================================================================
sub pattern_replace_new { 
    local($_)=@_;
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------
    $_=~s/[\n\r]/ /g; 
    return($_);
}

# ================================================================================
sub pattern_replace_tab { 
    local($_)=@_;
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------
    $_=~s/\t//g; 
    return($_);
}


# ================================================================================
sub processAbbreviations {
#    local($in)=@_;
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------

    $ct=$ctfirst=$ctlast=0;
    foreach $tmp (@content) {
	++$ct;
	if (($Labbr && $tmp=~/<p/i) ||
	    ($Labbr && $tmp=~/end abbreviations?|abbreviations? end/i) ){
	    $tmp=~s/end abbreviations?|abbreviations end//i;
	    $ctlast=$ct;
	    $tmp="";
	    last;}

	if ($tmp=~/^(.*abbreviations used:\s*)/i){
	    $ctfirst=$ct;
	    $tmp=~s/$1//g;
	    $tmp=~s/<.?b>|<.?i>//gi;
	    $abbreviations.=" ".$tmp;
	    $Labbr=1;
	    $tmp="";
	    next; }
	next if (! $Labbr);
	$abbreviations.=" ".$tmp;
	$tmp="";
    }
				# put into field
    $#abbreviations=0;
    undef %abbreviations;
    if (length($abbreviations)>10){
	$abbreviations=~s/^\s*<\/[^>]+>//g;
	$tmpTag= "\&nbsp\;";
	$tmpAbbr=$abbreviations;
	@tmp=split(/$tmpTag/,$tmpAbbr);
	foreach $tmp (@tmp){
	    $tmp=~s/^\s//g;
	    $tmp=~s/^$tmpTag//g;
	    $tmp=~s/^\s//g;
	}
	$abbreviations=join('',@tmp);
    }
				# text to add

    $tmp=$abbreviations;
    $tmp=~s/^\s*//g;
				# now split by ';'
    @tmp=split(/\;/,$tmp);
				# watch it: references also have ';' -> join
    $tmp2="";
    foreach $tmp (@tmp){
	next if ($tmp=~/^\s*$/);
	if ($tmp=~/^\s*[\d\]]+/){
	    $tmp2=~s/\t$//g;
	    $tmp2.="; ".$tmp."\t";
	}
	else {
	    $tmp=~s/^\s*//g;
	    $tmp2.=$tmp."\t";
	}
    }
    $#tmp=0;
    @tmp=split(/\t/,$tmp2);

    foreach $tmp (@tmp){
	next if ($tmp=~/^\s*$/);
	next if (length($tmp)<2);
	$kwd=$tmp; $kwd=~s/^([^\,]+),.*$/$1/;
	$val=$tmp; $val=~s/^[^\,]+,\s*(.*)$/$1/;
	$kwdTxt=$kwd;
				# remove tags
	$kwd=~s/^<[^>]+>(.+)<\/[^>]+>/$1/;
				# convert to lower
	$kwd=~tr/[A-Z]/[a-z]/;
	next if (length($kwd)<2);
	push(@abbreviations,$kwd);
	$abbreviations{$kwd}=$val;
	$kwdTxt=~s/<B>|<.B>//ig;
	$abbreviations{$kwd,"txt"}=$kwdTxt;
    }
				# ------------------------------
				# text for abbreviations
    $txt="";
    $txt.="<!-- "."." x 80 . " -->\n";
    $txt.="<!-- "."abbreviations begin". " -->\n";
    $txt.="<P class=\"left\"><STRONG>";
    $txt.="<A NAME=\"ABBREVIATIONS\">Abbreviations used</A></STRONG></P>\n";
    $txt.="<TABLE COLS=2 BORDER=0 WIDTH=\"100\%\">\n";
    foreach $kwd (@abbreviations){
	$txt.="<TR style='text-align:justify'>";
	$txt.="<TD VALIGN=TOP ALIGN=LEFT WIDTH=\"25\%\"><A NAME=\"ABBR_".$kwd."\"><STRONG>".
	    $abbreviations{$kwd,"txt"}."</STRONG></A></TD>";
	$txt.="<TD VALIGN=TOP ALIGN=LEFT WIDTH=\"75\%\">".$abbreviations{$kwd}."</TD>";
	$txt.="</TR>\n";
    }
    $txt.="</TABLE><BR><P> \&nbsp\;</P>\n";
    $txt.="<!-- "."abbreviations end". " -->\n";
    $txt.="<!-- "."." x 80 . " -->\n";
    print "$txt\n"              if ($Ldebug);
				# ------------------------------
				# remove respective lines
    $#tmp=0;
    foreach $it (1 .. $ctfirst){
	push(@tmp,$content[$it]);
    }
    push(@tmp,$txt);
    foreach $it (($ctlast+1)..$#content){
	push(@tmp,$content[$it]);
    }
    $#content=0;
    @content=@tmp;
    $#tmp=0;
				# ------------------------------
				# now mark all abbreviations
    foreach $it (($ctlast+1)..$#content){
	$tmp=$content[$it];
	$Lchange=0;
	foreach $kwd (@abbreviations){
	    next if ($tmp !~ /$kwd/i);
	    next if ($tmp !~ /\b($kwd)\b/i);
				# exclude headers
	    next if ($tmp=~/<H\d/i);
	    $txt=$1;
	    $markBeg="<A HREF=\"\#ABBR_".$kwd."\">";
	    $markEnd="</A>";
	    $tmp=~s/\b($kwd)\b/$markBeg$txt$markEnd/gi;
	    $Lchange=1;
	}
	$content[$it]=$tmp 
	    if ($Lchange);
    }
    return(1,"ok");
}				# end processAbbreviations

# ================================================================================
sub processAuthors {
    local($in)=@_;
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------
#   processAuthors              assign affiliations to authors
#       in:                     all_author_lines
#       out:                    new line
#-------------------------------------------------------------------------------

				# remove <SUP>
    $in=~s/\<SUP[^\>]*\>[^\<]+\<.SUP\>//gi;
				# remove ole
    $in=~s/\<a name[^\>]*\>//gi;
    $in=~s/\<.a\>//gi;
				# remove HTML tags
    $in=~s/\<[^\>]*\>//gi;
				# all to comma
    $in=~s/(\&|and)/,/g;

    @tmp_author=split(/\s*,\s*/,$in);
    $cttmp=0;
    $paperAuthor="";
    foreach $tmp (@tmp_author){
	++$cttmp;
	$tmp=~s/^\s*|\s*$|\.//g;
	$tmp=~s/\s+/ /g;
	$paperAuthor.=$tmp.", ";
    }
    $name="burkhard rost";
    if (! defined $template{"address",$name}){
	print "*** ERROR in processAuthors: $name missing!\n";
	die;
    }
    $num_br=$template{"address",$name};
    $#tmp_address=0;
    undef %tmp_address;
    foreach $it (1..$num_br){
	$tmp_address=$template{"address",$name,$it};
	push(@tmp_address,$tmp_address);
	$tmp_address{$tmp_address}=$it;
    }
    $out="";
    foreach $tmp (@tmp_author){
	$out.=$tmp." <SUP>";
	$tmp_name=$tmp;
	$tmp_name=~tr/[A-Z]/[a-z]/;
	if (! defined $template{"address",$tmp_name}){
	    $out.="?";
	}
	else {
	    foreach $it (1..$template{"address",$tmp_name}){
		$tmp2=$template{"address",$tmp_name,$it};
		if (defined $tmp_address{$tmp2}){
		    $out.=$tmp_address{$tmp2}.",";
		}
		else {
		    push(@tmp_address,$tmp2);
		    $tmp_address{$tmp2}=$#tmp_address;
		    $out.=$#tmp_address.",";
		}
	    }
	}
	$out=~s/\,$//g;
	$out.="</SUP>\t";
    }
    $out=~s/\t$//g;
    @tmp=split(/\t/,$out);
    if    ($#tmp==1){
	$out=$tmp[1];}
    elsif ($#tmp==2){
	$out="\n".$tmp[1]." &amp; "."\n".$tmp[2];}
    else {
	$out="";
	foreach $it (1..$#tmp){
	    if    ($it==$#tmp){
		$out.="\n".$tmp[$it];}
	    elsif ($it==($#tmp-1)){
		$out.="\n".$tmp[$it]." and ";}
	    else {
		$out.="\n".$tmp[$it].", ";
	    }
	}
    }
    $out="<P class=\"author\">".$out."</P>\n";
				# ------------------------------
				# now add the table
    $out.="<TABLE>\n";
    foreach $it (1..$#tmp_address){
	$out.="<TR>\t<TD VALIGN=TOP>".$it."</TD>\n";
	$out.="    \t<TD>".$tmp_address[$it]."</TD>\n";
	$out.="    \t</TR>\n";
    }
				# now corresponding
    $name="corresponding author";
    $out.="\n";
    $out.="<TR>\t<TD VALIGN=TOP>"."*"."</TD>\n";
    $out.="    \t<TD>Corresponding author: ".$template{"address",$name,1}."</TD>\n";
    $out.="    \t</TR>\n";

    $out.="</TABLE>\n\n";
    return($out);
}				# end processAuthors

# ================================================================================
sub processCapFig {
    local($in)=@_;
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------
				# start kwd: 'Fig. 5.'
    if ($in=~/^\<.*\>\s*([fF]ig[u]?[r]?[e]?\.?\s+\d+)/){
	$kwd=$tmp=$1; 
	$kwd=~s/[Ff]igure/fig/; 
	$kwd=~s/[\.\s]//g; 
	$kwd=~tr/[A-Z]/[a-z]/;
	$kwdNow=$kwd;
	$cap{$kwd}=$tmp." ";
	$tmp2=$in;$tmp=~s/\n//g;
	$tmp2=~s/^.*$tmp\s*//g;
	while($tmp2=~/^\<\//){
	    $tmp2=~s/^\s*\<\/[^\>]+\>//g;
	}
	$tmp2=~s/^[\s\.]*|\s$//g;
	if (length($tmp2)>0){	# append text after name 'Fig. 5. '
	    $cap{$kwd}.=" ".$tmp2."\n";
	}
	$cap{$kwd}=~s/<p>//i;
	$cap{$kwd}="<P class=\"cap\">".$cap{$kwd} if ($cap{$kwd}!~/<P class=[^>]*cap[^>]*>/);
	if    (! defined $cap{"references"}){
	    $cap{"references"}=$kwd;}
	elsif ($cap{"references"}!~/$kwd/){
	    $cap{"references"}.=",".$kwd;
	}
    }
				# caption text
    elsif (defined $kwdNow && (length($kwdNow)>1) ){
	$cap{$kwdNow}.=$lineRd."\n";
	if    (! defined $cap{"references"}){
	    $cap{"references"}=$kwd;}
	elsif ($cap{"references"}!~/$kwdNow/){
	    $cap{"references"}.=",".$kwdNow;
	}
    }
}				# end processCapFig

# ================================================================================
sub processCapTab {
    local($in)=@_;
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------
				# remove tags
    $in_naked=$in;
    $in_naked=~s/<[^>]+>//g;

    return(1) if ($in !~ /(tr|td|table)>/ &&
		  $in !~ /<(tr|td|table)/ &&
		  ($in_naked =~/^\s*$/            ||
		   $in_naked =~/^\s*\&nbsp\;\s*$/));

				# ------------------------------
				# IS header of table:
				#    -> start kwd: 'Table 5.'
    if ($in=~/^\<.*\>\s*[tT]abl?e?\.?\s+(\d+)/i){
	$kwd="table".$1;
	$tmp="Table ".$1;
	$kwdNow=$kwd;
	$cap{$kwd}=$tmp." \n";
	$tmp2=$in;
	$tmp=~s/\n//g;
	$tmp2=~s/^.*$tmp\s*//g;
	while($tmp2=~/^\<\//){
	    $tmp2=~s/^\s*\<\/[^\>]+\>//g;
	}
	$tmp2=~s/^[\s\.]*|\s$//g;
	if (length($tmp2)>0){	# append text after name 'Tab. 5. '
	    $cap{$kwd}.=" $tmp2\n";
	}
	$cap{$kwd}=~s/\n|\t//g;
	$cap{$kwd}=~s/\s+/ /g;
	if    (! defined $cap{"references"}){
	    $cap{"references"}=$kwd;}
	elsif ($cap{"references"}!~/$kwd/){
	    $cap{"references"}.=",".$kwd;
	}
    }
				# ------------------------------
				# is continuation of table:
				#     -> table raw
				#     -> caption text
    elsif (defined $kwdNow && (length($kwdNow)>1) ){
	if ($lineRd=~/<table >|<.table>/ ||
	    $lineRd=~/^<tr/i){
	    $lineRd="\t\n".$lineRd;
	}
	$cap{$kwdNow}.="\t$lineRd\n";
	if    (! defined $cap{"references"}){
	    $cap{"references"}=$kwd;}
	elsif ($cap{"references"}!~/$kwdNow/){
	    $cap{"references"}.=",".$kwdNow;
	}
    }
    else {
	print "xx else applies rd=$lineRd, \nin=$in\n";die;
    }
}				# end processCapTab

#===============================================================================
sub processContent {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processContent                       
#       in GLOBAL:              @content
#       out GLOBAL:             @rd
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."processContent";

				# ------------------------------
				# problem with eqn images
    $tmp=join("\n",@content);
    $tmp=~s/(<img [^>]+)\s*\n\s*><img (width=\d+ height=\d+)/$1 $2>/gi;

				# insert table for formula

    $tagtmp_beg="\n<TABLE COL=2 BORDER0 WIDTH=\"100%\">\n".
	"<TR><TD VALIGN=MIDDLE ALIGN=CENTER>".
	    "<A NAME=\"eqn"."eqn_xyz"."\">";
    $tagtmp_end="\n</A></TD><TD VALIGN=MIDDLE ALIGN=RIGHT WIDTH=\"10%\">".
	"Eqn. (eqn_xyz)</TD></TR></TABLE>";

    $tmp=~s/<P class=.formula.>(<img [^>]+>)/$tagtmp_beg$1$tagtmp_end/gi;

				# ------------------------------
				# some microsoft shit left
    $tmp=~s/<v:[^><]+>//ig;
    $tmp=~s/<\/v[^><]*>//ig;
				# - 3: still <o: shit left!
    $tmp=~s/<o:[^><]+>//ig;
    $tmp=~s/<\/o[^><]*>//ig;

				# references
    $tmp=~s/($tagref)\n*/$1/g;
    $tmp=~s/(xxx)\s*\n*/$1 /g;
    $tmp=~s/(\[\s*xxx\s*[^\]]+)\n/$1/g;

    @content=split(/\n/,$tmp);
    $tmp="";

				# --------------------------------------------------
				# final processing
				# --------------------------------------------------

    $#rd=$#cap=0;$Lmerge=$LmergeRef=$Lref=$Lcap=$Ltab=$kwdHdr=$LkwdHdrFin=$eqnNum=0;
    $line=$lineRef=$kwdNow="";
    $ctline=0;
    foreach $line (@content){
	++$ctline;
				# extract author names
	if ($paperAuthor=~/author/ && $line=~/author/){
	    $tmp=$line;
	    $tmp=~s/^.*<P class=[^>]+author>(.*)<.*\/P>/$1/i;
	    print "xx 1tmp(getting author)=$tmp\n";
	    $tmp=~s/<sup>[\d\s\,\*]+<\/sup>//g;
	    $tmp=~s/\&amp\;/and/;
	    $tmp=~s/\s\s*/ /g;
	    $paperAuthor=$tmp if (length($tmp)>5 && $tmp=~/rost/i);
	}
	last if ($line =~ /<\/body/i);
	last if ($line =~ /<\/html/i);

	next if (! defined $line);

	next if ($line =~ /^\<(META|\/?HEAD|BODY|\/?TITLE|HTML)/i); # skip from reading

				# corrections for MS shit
	$line=~s/<P>\&nbsp\;<\/P>\s*\n//g;
	$line=~s/<FONT FACE=\.[a-zA-Z]+(\s+SIZE=\d+)?\.>//g;
#	$_=~s/<\/FONT>//g;
	next if (length($line)<1);
	$line=~s/\&\#9\;//g;
	if ($line =~ /<H1>(.+)$/){
	    $title=$1;
	    $title=~s/<.?CENTER>|<.?H1>|<.?B>//gi;}
	if ($line =~ /(<H\d>|<FONT.*>)\bReferences/i ||
	    $line =~ /(<FONT.*>)References/i){
	    $Lref=1;
	    $Ltab=$Lcap=0;}
	if ($line =~ /Figure captions/i){
	    $Lcap=1;
	    $Lref=$Ltab=0;
	}
	if    ($line =~ /\bReferences?\s*end\b.*$/i
	       ){
	    $Lref=$LmergeRef=0;
	    next;}
	elsif ($line =~ /References?\s*end$/i){
	    $Lref=0;
	}
	next if ($line =~ /references begin/i);
	
	$LmergeRef=0 if (! $Lref);

	if ($line =~ />.*table caption/i ||
	    $line=~/<h\d>.*table/i        ){
	    $Ltab=1;
	    $Lref=$Lcap=0;
	}

				# --------------------------------------------------
				# link equation numbers ( ending on: (n) )
	$eqnNum=0;
	if (! $Lref){
	    if ($line =~ /[\t\s]+\([Ee]qn?\.?\s*(\d+)\)\s*\n*$/) {
		$eqnNum=$1; }
	}

	$lineRd=$line;
	if (! $LkwdHdrFin){	# extract keywords
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
	    $lineRd=
		&linkToRef($lineRd);
	}
	
				# merge <h1> /n </h1> into one line
	if (! $Lmerge                  &&
	    $lineRd =~ /<(H\d+|FONT)/  && 
	    $lineRd !~ /<\/$1/           ){
	    $Lmerge=1;
	    $line=    $lineRd;
	    $keyMerge=$1;
	    $begMerge=$line;
	    print "--- wants to merge '$lineRd'\n";
	    next;}
	elsif (! $Lmerge    && 
	       ! $LmergeRef && 
	       $Lref        && 
	       $lineRd!~/<P>/  ){
	    print "--- starts merging ref '$lineRd'\n";
	    $LmergeRef=1;
	    $lineRef=  $lineRd;
	    next;}
	elsif (! $Lmerge) {
#	    print "--- not merged '$lineRd'\n";
	    $line=$lineRd;}

	$Lcap=$Ltab=0 if ($Lref);

				# ------------------------------
				# store figure captions
	&processCapFig($lineRd)     
	    if ($Lcap && $lineRd !~ /\>figu?r?e? caption/i);

				# ------------------------------
				# store figure captions
	&processCapTab($lineRd)     
	    if ($Ltab && $line!~/<H1>Tables?/i);

				# ------------------------------
				# label equations
	if ($eqnNum){
	    $ref="eqn".$eqnNum;
	    $line="<CENTER><A NAME=\"$ref\">\n".$line."\n<\/A></CENTER>\n";
	    $eqnNum=0;}

				# ------------------------------
				# shoot we have to stop at some point
	if ($line=~/<\/body>/i){
	    if ($Lmerge){
		push(@rd,$line);
		$Lmerge=0;}
	    elsif ($LmergeRef){
		$LmergeRef=0;
		push(@rd,$lineRef);
	    }}
	if ($Lmerge){
				# finish merging
	    if ($lineRd =~ /\/$keyMerge/){
		print "--- merging key found=$keyMerge, line=$lineRd'\n";
		$Lmerge=0;
		$line=$line." ".$lineRd;}
				# continue merging
	    else {
		$line=$line." ".$lineRd;
		print "-*- WARN still not found merger key=$keyMerge (beg=$begMerge), line=$lineRd'\n";
		next;}}
	elsif ($LmergeRef){
	    print "--- merge ref $lineRd\n" if ($Ldebug);
	    if ($lineRd !~ /<P>/ && 
		$lineRd !~ /<BR>/){
		$lineRef=$lineRef." ".$lineRd;
		next;
	    }
	    else {
		$LmergeRef=0;
		$line=$lineRef." ".$lineRd;
	    }
	}
	
	push(@rd,$line) if (! $Lcap && ! $Ltab); # store (ignore captions)
	$line="";			# reset
	$lineRef="";		# reset
    }
				# --------------------------------------------------
				# second round bloddy formulas
				# --------------------------------------------------
    $#tmp=0; $Lmerge=0;
    foreach $line (@rd){
				# not formula
	if    ($line!~/class=\"?formula/ && ! $Lmerge){
	       
	    push(@tmp,$line);}
				# formula and closed on same line
	elsif ($line=~/class=\"?formula/ && $line=~/<\/P>/i){
	    $line=~s/\n//g;
	    push(@tmp,$line);}
				# formula NOT closed -> begin merging
	elsif ($line=~/class=\"?formula/ && $line!~/<\/P>/i){
	    $merge= $line;
	    $Lmerge=1;}
				# formula NEVER closed -> end merging
	elsif ($line=~/class=\"?formula/ && $line!~/<[HP]/i){
	    $merge.="</P>";
	    $Lmerge=0;
	    push(@tmp,$merge);
	    push(@tmp,$line);}

				# formula continues, now closed -> add
	elsif ($Lmerge && $line=~/<\/P>/i){
	    $merge.=" ".$line;
	    $Lmerge=0;
	    push(@tmp,$merge);}
	elsif ($Lmerge){
	    $merge.=" ".$line;
	}
	else {
	    print "xx unknown case $line\n";
	    die;
	}
    }
    @rd=@tmp;
    $#tmp=0;
				# --------------------------------------------------
				# third round: bloddy <P>'s on one line
				# --------------------------------------------------
    $#tmp2=0;
    foreach $line (@rd){
	if ($line=~/\S+\s*<[PH]/i){
	    $tmp2=$line;
	    $tmp2=~s/(\S+\s*)(<[PH])/$1\t$2/gi;
	    @tmp2=split(/\t/,$tmp2);
	    push(@tmp,@tmp2);
	}
	else {
	    push(@tmp,$line);
	}}
    @rd=@tmp;
    $#tmp=0;

				# ------------------------------
				# captions: extract titles
				# ------------------------------
    if (defined $cap{"references"}){
	$cap{"references"}=~s/^\,|\,$//g;
	@tmp=split(/,/,$cap{"references"});
	foreach $reftmp (@tmp){
				# get figure title
				# convention 'Fig. \d: *.'
	    if    ($reftmp=~/fig/){
		$tmp=$cap{$reftmp};
		$figNum=$reftmp;
		$figNum=~s/fig//g;
		$figNum=~s/\D//g;
		
		$tmp=~s/^.*\bFig\.[\s\t\:\d]+([^\.]+)\s*\..*$//im;
		$tmp=$1;
		$tmp=~s/[\t\n]/ /g;
				# remove HTML tags
		$tmp=~s/\<[^\>]+\>//gm;
		$tmp=~s/^[^A-Za-z]+|[^A-Za-z]+$//g;
		$toc{"figures",$figNum}=$tmp;
		print "xx fig=$figNum, name=$tmp\n";
	    }
	    elsif ($reftmp=~/table/){
				# get table title
				# convention 'Fig. \d: *.'
				# remove actual table
		@tmp=split(/\<TABLE|\<table/,$cap{$reftmp});
		$tmp=$tmp[1];
		$tmp=~s/^.*\bTable[\s\t\:\d]+([^\.]+)\s*\.//im;
		$tmp=$1;
				# remove HTML tags
		$tmp=~s/\<[^\>]+\>//gm;

		$tmp=~s/[\t\n]/ /gm;
		$tmp=~s/^[^A-Za-z]+|[^A-Za-z]+$//g;
		$figNum=$reftmp;
		$figNum=~s/tabl?e?//g;
		$figNum=~s/\D//g;
		$toc{"tables",$figNum}=$tmp;
	    }
	    else {
		print "*** ERROR processContent: reftmp=$reftmp, not recognised\n";
		die;
	    }
	}
    }
    return(1,"ok $sbrName");
}				# end of processContent

#===============================================================================
sub rdPaper {
    local($fileInLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdPaper                     reads:  @header,@content
#                               finds:  paperAuthor/paperQuote/paperTitle
#                               merges: <Hn></Hn>   into one line
#                               merges: tab|fig|eqn into one line
#                               merges: 
#                               
#                               
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."rdPaper";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhin, $fileInLoc) || die "*** ERROR $sbrName failed opening in=$fileInLoc\n";

    $#content=0;$Lhold=$Lhold1=0;
    $Lbody=0;
    $titlePaper=0;
				# ------------------------------
				# header
    $#header=0;
    $titlePaper= "title";
    $paperAuthor="author";
    $paperQuote= "quote";
    
    while (<$fhin>) {
	$_=~s/\n//;
				# skip shit
	next if (! $Lbody && $_=~/^xmlns/);
	next if (! $Lbody && $_=~/^.*meta.*word/i);
	next if (! $Lbody && $_=~/^.*meta.*microsoft/i);
	next if (! $Lbody && $_=~/^<link rel/);
	if ($titlePaper =~/title/i && 
	    $_=~/title>([^<]+)<.*title/){
	    $titlePaper=$1;
	}
	if (! $Lbody && $_=~/^\s*<body/){
	    $Lbody=1;
	    last;}
	push(@header,$_);
    }
				# ------------------------------
				# body
    $Lhold=$Lref=0;
    while (<$fhin>) {
	$_=~s/\n//;
	$_=~s/<span[^>]*>//g;
	$_=~s/<\/span[^>]*>//g;
				# tags for headings: no end
	if    (! $Lhold && 
	       ($_ =~ /<H\d/i && $_ !~ /<\/H\d/i)){
	    $Lhold=1; $tmp=$_;}
				# tags for headings: end
	elsif ($Lhold && ($_ =~ /<\/H\d/i) ){
	    $Lhold=0; $tmp.=" $_";}
	elsif ($Lhold){
	    $tmp.=" $_";}
	elsif (! $Lhold1 && ($_=~/(tab|fig|eqn)\./i && $_ !~/(tab|fig|eqn)\.\s+\d+/i) ){
	    $tmp=$_; $Lhold1=1;}
	elsif ($Lhold1){
	    $tmp.=" $_"; $Lhold1=0; $tmp=~s/(tab|fig|eqn)(\.\s+\d+)/$1$2\n/i}
	else {
	    $tmp=$_;}
	if (! $Lhold && ! $Lhold1){
	    $tmp=~s/\s\s+/ /g;
				# skip empty lines
	    next if ($tmp=~/^\s*$/);
	    push(@content,$tmp);
	    if    ($titlePaper =~ /title/i &&
		$tmp=~/^.*title>([^<]+)<.*$/i){
		$titlePaper=$1;}
	    elsif (0 &&
		   $paperAuthor =~ /author/i &&
		   $tmp=~/^.*author>([^<]+)<.*$/i){
		$paperAuthor=$1;}
	    elsif (0 &&
		   $paperAuthor =~ /author/i &&
		   $tmp=~/^.*author beg:\s*([^:]+)\s*:\s*author end.*$/i){
		$paperAuthor=$1;}
	    elsif ($paperQuote =~ /quote/i &&
		   $tmp=~/^.*quote beg:\s*([^:]+)\s*:\s*quote end.*$/i){
		$paperQuote=$1;}
	}
    }
    close($fhin);
    
    $paperTitle= $titlePaper;
    return(1,"ok $sbrName");
}				# end of rdPaper

#===============================================================================
sub removeShit {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   removeShit                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."removeShit";


    $tmp=join("\t",@content);
				# remove shit
    $tmp=~s/<P>\&nbsp\;<\/P>//g;
    $tmp=~s/\&\#9\;/ /g;
    $tmp=~s/<.?DIR>//gi;
				# empty tags
    foreach $tag ("o:p",
		  "",
		  ){
	next if (length($tag)<1);
	$tmp=~s/<$tag><\/$tag>//g;
    }
    $tmp=~s/<div[^>]+>|<\/div>//g;

				# unwanted tags
				# - 1: get rid of the xml stuff
    $tmp=~s/<xml>[\s\t]*<w:data>[^<]+<\/w:data>[\s\t]*<\/xml>//g;
				# - 2: <v: shit
				# - 4: other shit
    foreach $tag (@tagExcl){
	$tmp=~s/$tag//g;
    }
    $tmp=~s/<\!\-*\s*\[if[^>]+>//g;
    $tmp=~s/<\!\-*\s*\[endif[^>]+>//g;

				# - 5: now they have tocs ...
#
				# ------------------------------
				# references: 
				# - get reference numbers out
				# - remove tabs between [xxx 45; TAB 47]
    $tmp=~s/ADDIN ENRfu[\s\t]*(\[xxx [\d\s\;\t\n]+\])/ &pattern_replace_tab($1)/ge;
    $tmp=~s/ADDIN ENRfu\s*//g;
				# now merge the final references
    $tmp=~s/(\[xxx [\d\s\;\t\n]+\])/ &pattern_replace_tab($1)/ge;
    $tmp=~s/ADDIN ENBbu (xxx\s*)[\s\t](\d+)\./$1 $2/gi;
				# unwanted class
    $class_text=    "class=\"text\"";
    $class_title=   "class=\"title\"";
    $class_list=    "class=\"list\"";
    $class_formula= "class=\"formula\"";
    $class_author=  "class=\"author\"";
    
				# br-abstract -> H2
    if ($tmp=~/(\<p class.?brabstr[^\>]*\>\s*)(abstract|summary)(\s*\<\/p\>)/i){
	$tmp1=$1.$2.$3;
	$tmp2=$2;
	$tmp=~s/$tmp1/<H1>$tmp2<\/H1>/i;
    }

    if ($tmp=~/(class\=MsoNormal)/i){
	$tmp=~s/$1/$class_text/gi;
	$tmp=~s/(class\=\"text\")[^\>]?/$1/gi; 
    }
    if ($tmp=~/(class\=.?MsoNormal\S*)/i){
	$tmp=~s/$1/$class_text/gi;
	$tmp=~s/(class\=\"text\")[^\>]?/$1/gi; 
    }
    if ($tmp=~/(class\=MsoIndex\S?)/){
	$tmp=~s/$1/$class_text/g;
#	$tmp=~s/(class\=\"text\")[^\>]?/$1/gi; 
    }

				# br-author ->  P.author
    if ($tmp=~/(<p [^>]*class\=[^>]*author[^>]*)\>/i){
	$tmp=~s/$1/<P $class_author>/gi;
	$tmp=~s/($class_author\>)\>/$1/gi;
    }
    if ($tmp=~/(class\=\S+title[^>]*)\>/i){
	$tmp=~s/$1/$class_title>/gi;
	$tmp=~s/($class_title\>)\>/$1/gi;
    }
    if ($tmp=~/(class\=\S+list[^>]*>)/i){
	$tmp=~s/$1/$class_list>/gi;
    }
    if ($tmp=~/(class\=\S+formula[^>]*>)/i){
	$tmp=~s/$1/$class_formula>/gi;
    }
				# remove styles from <Hn|class=text
    $tmp=~s/(<H\d)[^>]+/$1/ig;
    $tmp=~s/(<P class=.*text.*)[^>]+/$1/ig;
    $tmp=~s/(<P class=.*formula.*)[^>]+/$1/ig;
				# upper case tags
    $tmp=~s/<h/<H/g;  $tmp=~s/(<\/)h/$1H/g;
    $tmp=~s/<p/<P/g;  $tmp=~s/(<\/)p/$1P/g;  
    $tmp=~s/<ul/<UL/g;$tmp=~s/(<\/)ul/$1UL/g;
    $tmp=~s/<ol/<OL/g;$tmp=~s/(<\/)ol/$1OL/g;
    $tmp=~s/<li/<LI/g;$tmp=~s/(<\/)li/$1LI/g;

    $tmp=~s/<br clear=ALL style=[^>]+>//gi;
    $tmp=~s/<xml>[\s\t]*<w:data>[^<]+<\/w:data>[\s\t]*<\/xml>//g;


				# correct problems
    foreach $kwd (
		  "B",
		  "I",
		  "STRONG",
		  ){
	next if (length($kwd)<1);
				# get blodddy priorities right <B><P>xx</B></P> -> <P><B>xx</B></P>
	$tmp=~s/(<$kwd>)(<P[^>]*>)([^<]+)(<\/$kwd>)/$2$1$3$4/;
				# no break between brackets <B>xx \t</B> <B>xx </B> 
	$tmp=~s/(<$kwd>)\t*([^\t]*)\t*(<\/$kwd>)/$1$2$3/;
    }

				# start line with '<P>|<FONT>'
    foreach $kwd (
		  "HEAD","TITLE","META",
		  "BODY",
		  
#	      "FONT",
		  "P",
#	      "I",
#	      "B",
#	      "STRONG",
		  "HR",

		  ){
	next if (length($kwd)<1);
	$tmp=~s/<$kwd/\t<$kwd/ig;
	$tmp=~s/\t\t+/\t/g;
				# purge '<font>\nxx</font> i.e. on one line
	$tmp=~s/(<$kwd[^\t]*)\t+([^\t]<\/$kwd)/$1$2/i;
    }

    $tmp=~s/<H(\d)/\t<H$1/g;
    $tmp=~s/(<\/BODY)/\t$1/g;
    $tmp=~s/(<\/HTML)/\t$1/g;
    $tmp=~s/\t\t+/\t/g;
				# more empty tags
    $tmp=~s/<b>\s*<\/b>//g;

				# ==================================================
				# ------------------------------
				# get references out of all
				# get the whole reference shit

				# ==================================================
				# ref=1 !!
    if    ($tmp=~/\bREFERENCES BEGIN(.*)\bREFERENCES END/i){
	$tmp=~s/\bREFERENCES BEGIN(.*)\bREFERENCES END//i;}
    elsif ($tmp=~/BEG\S REFERENCES(.*)\bREFERENCES END/i){
	$tmp=~s/BEG\S REFERENCES(.*)\bREFERENCES END//i;}
    elsif ($tmp=~/\bREFERENCES(.*)\bREFERENCES END/i){
	$tmp=~s/\bREFERENCES(.*)\bREFERENCES END//i;}
    elsif ($tmp=~/\bREFERENCES(.*)\bEND REFERENCES/i){
	$tmp=~s/\bREFERENCES(.*)\bEND REFERENCES//i;}
    else {
	print "*** ERROR references not understood, supposed to be all in:\n";
	print "$tmp\n";
	print "*** ERROR references not understood, supposed to be all in (above)\n";
	exit;
    }

    $referencesFinal=$1;
				# ==================================================
				# ==================================================
				# ==================================================

				# ------------------------------
				# get reference to figures out
    @tmp=split(/($nbsp)+/,$tmp);
    $tmp=join("\&nbsp\;",@tmp);$#tmp=0;
    $tmp=~s/$nbsp$nbsp/$nbsp/g;
    $tmp=~s/$nbsp$nbsp/$nbsp/g;
    $tmp=~s/$nbsp$nbsp/$nbsp/g;
    $tmp=~s/[\s\t]*$nbsp[\s*\t]/$nbsp/g;
				# handle figures
    $tag="<P class=ins-fig>";
    @tmp=split(/<P class=ins\-fig>/i,$tmp);
    $#tmp2=0;
    $ctline=0;
    foreach $tmp (@tmp){
	++$ctline;
	next if (length($tmp)<1);
	next if ($tmp=~/^[\s\t]*$/);
	$tmp=~s/\&nbsp\;[\s\t]*(\&gt\;\&gt\;)/$1/g;
	$tmp=~s/(\&gt\;\&gt\;)[\s\t]*\&nbsp\;/$1/g;
	$tmp=~s/\&nbsp\;[\s\t]*\&lt\;[\s\t]*\&lt\;/$lt$lt/g;
	$tmp=~s/\&lt\;[\s\a\f\e\t]*\&lt\;[\t\a\f\e\s]*\&nbsp\;/$lt$lt/g;
	$tmp=~s/^[^<]*\&gt\;[\s\t]*(fig.*|table)[^0-9]+(\d+)[^<]*\&lt\;[\s\t]*/$gt$gt$gt$1 $2 $lt$lt$lt/gi;
	$tmp=~s/(\&lt\;)\s+(<\/P>)/$1$2/i;
	$tmp=~s/^[\s\t]*|[\s\t]*$//g;
	$tmp.="</P>"             if ($tmp=~/\&lt\;$/);
	push(@tmp2,$tmp);
    }
    $tmp=join("<P class=ins-fig>",@tmp2);$#tmp=$#tmp2=0;

				# ------------------------------
				# change path to material
    $tmp=~s/<v\:\s*image[^\"]+(\")[^\/]+\/([^\"]+\")\s*[^>]*(>)[\t\s]*/<IMG SRC=$1$dirMat$2$3/gi;

    $tmp=~s/<FONT[^>]*>[\s\t\n]*<\/FONT>//g;
    $tmp=~s/(\t)(\;)/$2$1/g;
    @tmp=split(/<\/FONT>/,$tmp); 
    $#content=0;

    $Lxml=0;
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
				# newline before '<P>'
	$tmp=~s/([^\n]<P)/\n$1/g;
				# newline before '<img'
	$tmp=~s/([^\n]<img)/\n$1/g;

				# delete: <XYZ> empty </XYZ>
	$tmp=~s/<B>[\t\s\n]*<\/B>//g;
	$tmp=~s/<I>[\t\s\n]*<\/I>//g;
	$tmp=~s/<FONT>[\t\s\n]*<\/FONT>//g;

				# multiple '\n' in row ..
	$tmp=~s/\n[\s\t\n]*/\n/g;
				# remove '\n' from '\n</FONT> '
	$tmp=~s/\n(<\/FONT>)/$1/g;

	@tmp2=split(/\n/,$tmp);
	push(@content,@tmp2);
    }
				# - get out xml tags
    $#tmp=0;
    foreach $tmp (@content) {
	$Lxml=1 if ($tmp=~/<xml/);
	if ($Lxml && $tmp=~/<\/xml/){
	    $Lxml=0;
	    next;}
	next if ($Lxml && $tmp!~ /<\/xml/);
				# references again
	push(@tmp,$tmp);
    }

				# - and references again
    $tmp=join("\n",@tmp);
    $tmp=~s/(\[xxx [\d\s\;\t\n\r]+\])/ &pattern_replace_tab($1)/ge;
    $tmp=~s/(\[xxx [\d\s\;\t\n\r]+\])/ &pattern_replace_new($1)/ge;
    $tmp=~s/(<\/P>)[\s\t\n]*<\/P>/$1\n/i;

    @tmp=split(/\n/,$tmp);

    $#content=0;
    @content=@tmp; $#tmp=0;
    $ctline=0;
    $ct=0;
    return(1,"ok $sbrName");
}				# end of removeShit

#===============================================================================
sub webCubicPapersBottom {
    local($fhoutLoc2) = @_ ;
    local($SBR9,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   webCubicPapersBottom             writes end of file
#       in:                     $fhoutLoc2:   file handle
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR9=$tmp."webCubicPapersBottom";
				# check arguments
    return(&errSbr("not def fhoutLoc2!",   $SBR9))    if (! defined $fhoutLoc2);

    print $fhoutLoc2
	"<!-- .................................................. -->\n",
	"<!-- www contact and version -->\n",
	"<BR>\n",
	"<TABLE COLS=\"2\" CELLPADDING=0 CELLSPACING=0 BORDER=0 WIDTH=\"100\%\">\n",
	"<TR>\n",
	"<TD ALIGN=\"LEFT\">",
	"<A NAME=\"BOTTOM\">",
	"<STRONG>Contact</STRONG>: \&nbsp\;  \&nbsp\;",
	"</A>",
	"<A HREF=\"mailto:".$par{"contact_email"}."\">".$par{"contact_email"}."</A>",
	"</TD>\n",
	"<TD ALIGN=\"RIGHT\">",
	"<STRONG>Version</STRONG>: \&nbsp\;  \&nbsp\;",
	$DATE,
	"</TD>\n",
	"</TR></TABLE>\n",
	"\n",
	"<!-- .................................................. -->\n",
	"<!-- bottom banner start -->\n",
	"<CENTER>\n",
        "<A NAME=\"\#BOTTOM\">","&nbsp;","</A>",
	"<A HREF=\"\#TOP\">"."top"."</A>"." - ",
        "<A HREF=\"\#TOC\">"."TOC"."</A>"." - ",
	"<A HREF=\"".$par{"cubicPapersURL"}."\">".$par{"cubicAcronym"}."-papers</A>"." - ",
	"<A HREF=\"".$par{"cubicURL"}."\">".$par{"cubicAcronym"}."</A>",
	"</CENTER>\n",
	"<BR>\n",
	"<!-- bottom banner end -->\n",
	"</BODY>\n",
	"</HTML>\n";

    return(1,"ok $SBR9");
}				# end of webCubicPapersBottom

#===============================================================================
sub webCubicPapersHead {
    local($fhoutLoc2,$titleLoc) = @_ ;
    local($SBR9,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   webCubicPapersHead                       
#       in:                     $fhoutLoc2:      file handle
#       in:                     $dirRelHomeLoc2: relative path, e.g. 
#                                                '../'  when in HOME/doc/
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR9=$tmp."webCubicPapersHead";
				# check arguments
    return(&errSbr("not def fhoutLoc2!",   $SBR9))    if (! defined $fhoutLoc2);

				# ------------------------------
				# local parameters
    $titleLoc=$par{"cubicAcronym"}.":papers" if (! defined $titleLoc); 

    print $fhoutLoc2
	"<HTML>\n",
	"<HEAD>\n",
	"<TITLE>\n",
	"	".$titleLoc."\n",
	"</TITLE>\n",
	"\n",
	"<meta name=\"LastName\" value=\"".$par{"cubicAcronym"}."\">\n",
	"<meta name=\"LastName\" content=\"".$par{"cubicAcronym"}."\">\n",
	"\n",
	"<link rel=\"INDEX\"     HREF=\""."../../"."index.html\">\n",
	"<link rel=\"index\"     HREF=\""."../../"."index.html\">\n",
	"\n";
    @tmp=split(/,/,$kwdHdr);
    foreach $tmp (@tmp){
	next if (! defined $tmp);
	next if ($tmp=~/^[\s,]+$/);
	print $fhoutLoc2
	    "<meta name=\"Keywords\" content=\"".$tmp."\">\n";
    }
    print $fhoutLoc2
	"<STYLE TYPE=\"text/css\">\n",
	$styleHeader,
	"</STYLE>\n",

	"</HEAD>\n",
	"<BODY bgcolor=\"#FFFFFF\" LINK=\"BLUE\" VLINK=\"PURPLE\" ALINK=\"GREEN\">\n",
	"\n";

    return(1,"ok $SBR9");
}				# end of webCubicPapersHead

#===============================================================================
sub webCubicPapersTop {
    local($fhoutLoc2) = @_ ;
    local($SBR9,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   webCubicPapersTop           writes the line with 'top/bottom/cubic'
#       in:                     $fhoutLoc2:      file handle
#       in:                     $dirRelHomeLoc2:  relative path, e.g. 
#                                                '../'  when in HOME/doc/
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR9=$tmp."webCubicPapersTop";
				# check arguments
    return(&errSbr("not def fhoutLoc2!",   $SBR9))    if (! defined $fhoutLoc2);

    @tmp=
	(
	 "<!-- .................................................. -->",
	 "<!-- top banner start -->",
	 "<P><CENTER>",
	 "<A NAME=\"TOP\">","&nbsp;","</A>",
	 "<A HREF=\"\#BOTTOM\">"."bottom"."</A>"." - ",
	 "<A HREF=\"\#TOC\">"."TOC"."</A>"." - ",
	 "<A HREF=\"".$par{"cubicPapersURL"}."\">".$par{"cubicAcronym"}."-papers</A>"." - ",
	 "<A HREF=\"".$par{"cubicURL"}."\">".$par{"cubicAcronym"}."</A>",
	 "</CENTER>",
	 "<BR>",
	 "</P>",
	 "<!-- top banner end -->"
	 );

    foreach $tmp (@tmp){
	print $fhoutLoc2 $tmp,"\n";
    }

    $tmpTitle= "TITLE";
    $tmpTitle= $paperTitle      if (defined $paperTitle  && $paperTitle  && $paperTitle !~/title/i);
    $tmpAuthor="Burkhard Rost";
    $tmpAuthor=$paperAuthor     if (defined $paperAuthor && $paperAuthor && $paperAuthor !~/author/i);
    $tmpQuote= "QUOTE";
    $tmpQuote= $paperQuote      if (defined $paperQuote  && $paperQuote  && $paperQuote !~/quote/i);
    @tmp=
	(
	 "<!-- .................................................. -->",
	 "<!-- QUOTE begin -->",
	 "<A NAME=\"QUOTE\">",
	 "<TABLE>",
	 "<TR><TD>Title: </TD><TD><STRONG>".$tmpTitle. "</STRONG></TD></TR>",
	 "<TR><TD>Author:</TD><TD><STRONG>".$tmpAuthor."</STRONG></TD></TR>",
	 "<TR><TD>Quote: </TD><TD><STRONG>".$tmpQuote. "</STRONG></TD></TR>",
	 "</TABLE></A>",
	 "<!-- QUOTE end -->"
	 );

    foreach $tmp (@tmp){
	print $fhoutLoc2 $tmp,"\n";
    }

    return(1,"ok $SBR9");
}				# end of webCubicPapersTop

#===============================================================================
sub wrtFig {
    local($lineLoc) = @_ ;
    local($sbrName,$fhoutLoc8,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtFig                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."wrtFig";
    $format="gif";
    $fhoutLoc8="FHOUT_"."wrtFig";

				# check arguments
    return(&errSbr("not def lineLoc!"))          if (! defined $lineLoc);

    $lineLoc=~s/\s|\.//g;
    $lineLoc=~tr/[A-Z]/[a-z]/; 
    $ref=   $lineLoc; 
    if    ($lineLoc=~/fig/i){
	$ref=~s/[Ff]igure/fig/;
    }
    elsif ($lineLoc=~/table/i){
	$ref=~s/table\s*(\d)/table$1/; 
    }
    else {
	print "*** ERROR wrtFig in=$lineLoc, not recognised\n";
	die;
    }
	 
    $fig=   $lineLoc.".".$format if ($ref=~/fig/);
    $what=  "Table"              if ($ref=~/tab/);
    $what=  "Fig"                if ($ref=~/fig/);
    $figNum=$ref; 
    $figNum=~s/(fig|tabl?e?|\.$format)//g;
				# add captions
    if (defined $cap{$ref}){
	if ($cap{$ref}!~/<P class=\"cap\".>/){
	    $cap="<P class=\"cap\">".$cap{$ref};}
	else {
	    $cap=$cap{$ref};}
	$cap.="\n<HR><BR>\n\n";
	$cap=~s/(<\/B>)/$1\n/;
    }
    elsif ($ref=~/tab/){
	print "-*- WARN no caption for table ($ref)\n";
	$cap="</B>\n<BR>\n\n";
    }
    else {
	print "XXXX $sbrName misising fig CAP for figNum=$figNum, ref=$ref,\n";
	print "yy line  =$lineLoc,\n";
	print "yy lineRd=$lineRd,\n";
#	exit;
	$cap="</B>\n<BR><P class=\"cap\">\n\n";
    }
				# shrink figure caption (no addtional lines in end)
    $end_para_tmp="<\/P>";
    $cap=~s/<P class=normal-cap>[^$end_para_tmp]*<\/P>\n*//g;

				# remove all newlines from cap
    $cap=~s/\n/ /g;

				# mark equations 
    if ($cap=~/([Ee]q\.|[Ee]qn\.|[Ee]quation|[Ee]qs\.)\s+\d+/i)  { # eqn
	$cap=&iterateInTxtLinksEqn($cap);
	print "--- in-cap link (eqn)=$cap,\n";
    }

				# --------------------------------------------------
				# only link figures
				# remove "<img src>" for figures
    $link2fig=0;
    if ($par{"doLinkFig"} && $figNum=~/^\d+$/ && $what=~/fig/i){
	$fileOutFig=$dirOut."fig".$figNum.".html";
	$fileOutFigRel=     "fig".$figNum.".html";
	$filefig="fig".$figNum.".".$format;
	$link2fig=    "<A HREF=\"".$filefig."\">\n".
	    "<IMG src=\"".$filefig."\" ALIGN=ABSMIDDLE ALT=\"".$fig."\"></A>";
	$link2fightml="<A HREF=\"".$fileOutFigRel.
	    "\" TARGET=\"".$fileOutFigRel."\">"."Fig. ".$figNum."</A>";

				# line to refer to the following HTML file
				# NAME
	$lineLoc= "\n<BR>\n<CENTER><B><A NAME=\"";
	$lineLoc.=$ref."\"> LOAD:  </A> \&nbsp\; ";
				# LINK
	$lineLoc.=$link2fightml."</B></CENTER>\n";
				# do not add caption!

				# --------------------
				# write fig1.html
	($Lok,$msg)=
	    &wrtFigHtml
		($fhoutLoc8,
		 $fileOutFig);	&errSbrMsg("problem with writing fig.html",
					   $msg,$sbrName) if (! $Lok);
    }
				# --------------------------------------------------
				# include into text (only for figures)
    elsif ($what=~/Fig/i) {
				# NAME
	$lineLoc= "\n<BR><HR>\n<CENTER><B><A NAME=\"";
	$lineLoc.=$ref."\">".$what."\. ".$figNum."</A></B></CENTER>\n";
				# LINK
	$lineLoc.="<CENTER> <A HREF=\"".$fig."\">\n<IMG SRC=\"".$fig."\" ALIGN=ABSMIDDLE ";
	$lineLoc.=" ALT=\"".$fig."\"> <\/A></CENTER>\n"."\n";

				# add caption!
	$lineLoc.="<B>".$cap;
	$lineLoc=~s/<P class=\"cap\"><P class=\"cap\">/<P class=\"cap\">/;
	$lineLoc=~s/<B><P class=\"cap\">/<P class=\"cap\"><B>/;
	$lineLoc=~s/Fig\.[\s\t]*(\d+)\.[\s\t]*\&nbsp\;/Fig. $1: /;
	$lineLoc=~s/\&nbsp\;/\n<BR>/;
    }

				# --------------------------------------------------
				# try to handle tables
    else {
				# remove 'class text ' in table
	@tmp=split(/<P class=[^>]*text[^>]*>/i,$cap);
	foreach $tmp (@tmp){
	    $tmp=~s/<\/P>//g;
	}
	$cap=join("",@tmp);
				# remove new lines
	@tmp=split(/<\/tr>/i,$cap);
	foreach $tmp (@tmp){
	    $tmp=~s/\n|\t//g;
	}
	$cap=join("</tr>\n",@tmp);
	$cap=~s/(>)\/(<)/$1$2/g;
	$cap=~s/(<table )/\n\t $1/i;
	$cap=~s/(<.table>)/\n\t $1\n\t/i;
	$cap=~s/([^\n])(<tr>)/$1\n\t$2/i;
	$cap=~s/(<tr)/\n\t$1/i;
				# get header of table
	if ($cap=~/<table/){
	    ($tmp1,$tmp2)=split(/<table/i,$cap);
	    $tmp1=~s/^(<P class=.cap[^>]+>)\s*//;
	    $tagtmp=$1;
	    $tableHeader="\n\t<STRONG>".$tmp1."</STRONG><BR>\n";
	    ($table,$cap)=split(/<\/table>/i,$tmp2);
	    $cap=$tableHeader."\n\t"."<TABLE".$table."</TABLE>\n".$tagtmp.$cap;
	}
	$cap=~s/<P>.nbsp\;<br>[\s\n]*$//i;
	$cap.="</P>\n";
				# handle tables that are not '<table>' later xyz yy zz

				# NAME
	$lineLoc= "\n<P><BR><HR>\n<CENTER><B><A NAME=\"";
	$lineLoc.=$ref."\">"."Table "."\. ".$figNum."</A></B></CENTER>\n";

				# LINK
				# add caption (or entire table)
	$lineLoc.=$cap;
	$lineLoc=~s/<P class=\"cap\"><P class=\"cap\">/<P class=\"cap\">/;
	$lineLoc=~s/<B><P class=\"cap\">/<P class=\"cap\"><B>/;
	$lineLoc=~s/Table (\d+)\.\t?\&nbsp\;/Table $1:/;
    }
    return(1,"ok $sbrName",$lineLoc);
}				# end of wrtFig

# ================================================================================
sub wrtFigHtml {
    local($fhoutLoc9,$fileOutFigLoc)=@_;
    local($SBR9);
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------
    $SBR9="wrtFigHtml";

    open($fhoutLoc9,">".$fileOutFigLoc) || 
	return(&errSbr("fileOutFigLoc=$fileOutFigLoc, not created",$SBR9));
    print $fhoutLoc9
	"<HTML><HEAD>\n",
	"<TITLE>",
	$title_paper.": Fig. ".$figNum,
	"</TITLE>\n",
	"<STYLE>\n",
	$style{"P.cap"},
	"</STYLE>\n",
	"</HEAD>",
	"<BODY style=\"background:white\">\n",
	"<H1>Figure ".$figNum."</H1>\n";

    print $fhoutLoc9
	"<CENTER> ".$link2fig."</CENTER>\n"."\n";
    print $fhoutLoc9
	"<BR>",
	"\&nbsp\;",
	"<BR>",
	$cap;
    print $fhoutLoc9
	"</BODY>",
	"</HTML>";
    close($fhoutLoc9);
    return(1,"ok");
}				# end of wrtFigHtml

# ================================================================================
sub wrtReferences {
    local($referencesFinal)=@_;
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------

				# remove class shit
    $referencesFinal=~s/<P class[^>]+>//g;
    $referencesFinal=~s/<\/P>//g;
    $referencesFinal=~s/xxx[^\s]/xxx /g;

    print $fhout 
	"<H1><A NAME=\"REFERENCES\">References</A></H1>\n";
    if ($par{"order"}){
	$tmplist="UL";
	$taglistBeg="<LI>";
	$taglistEnd="</LI>\n";
	print $fhout
	    "<".$tmplist." style=\'text-align:justify\'>\n";
    }
    else {
	$tmplist="OL";
#	$taglistBeg="<TR VALIGN=TO> style=\'text-align:justify\'";
	$taglistBeg="<TR VALIGN=TOP>";
	$taglistEnd="</TR>\n";
	print $fhout
	    "<TABLE COLS=2 WIDTH=\"100\%\" BORDER=0>\n";
    }

				# returns @abbreviations,$abbreviations{$kwd}=val
				# delete all before first reference
    if ($referencesFinal=~/$tagref\d/){
	$referencesFinal=~s/^.*($tagref \d)/$1/;
	$referencesFinal=~s/\t//g;
    }
    else {
	print "yy ref=$referencesFinal|\n";
	print "*** ERROR wrtReferences: problem with referencesFinal, tagref=$tagref, line above!\n";
	die;
    }

    $referencesFinal=~s/\t//g;
    @tmp=split(/xxx\s*/,$referencesFinal);

    $#references=0;
    $#tmp2=0;
    foreach $tmp (@tmp){
	next if ($tmp!~/^\s*x*\s*\d/);
	next if ($tmp=~/^(\s*)$/);
				# purge stuff before number
	$tmp=~s/^\s*x*\s*(\d)/$1/;
	$tmp=~s/<\/P>[\s\t\n]*$//g;
	$tmp=~s/\s\s+/ /g;
	$tmp=~s/^[\s\t]*|[\s\t]*$//g;
	$tmp=~s/<LI>|<UL>|<OL>//g;
	$tmp=~s/<\/LI>|<\/UL>|<\/OL>//g;
	$tmp=~s/<P class[^>]+>//gi;
	$tmp=~s/<\/P>//ig;
	$tmp=~s/\n//g;
	$tmp=~s/^\s*|\s*$//g;
	push(@tmp2,$tmp);
    }
    $#tmp=0;
    @tmp=@tmp2;
    $#tmp2=0;
    foreach $tmp (@tmp){
	next if ($tmp !~/^(\d+)/);
	next if (length($tmp)<5);

	$refnum=$1;
	next if (length($refnum)<1);
	$tagbeg="<A NAME=\"ref".$refnum."\">";
	$tagend="</A>";
				# straight
	if    ($tmplist eq "UL"){
	    $tmp=~s/^(\d+)/$tagbeg$1$tagend./;
	    push(@references,
		 $taglistBeg.$tmp.$taglistEnd);}
				# table
	elsif ($tmplist eq "OL"){
	    $tmp=~s/^\d+\s*//g;
	    $tmpcol1="<TD VALIGN=TOP ALIGN=LEFT WIDTH=\"15\">".$tagbeg.$refnum.$tagend.".</TD>";
#	    $tmpcol2="<TD VALIGN=TOP ALIGN=LEFT class=\"ref\">".$tmp."</TD>";
	    $tmpcol2="<TD VALIGN=TOP ALIGN=LEFT style=\'text-align:justify\'>".$tmp."</TD>";
	    push(@references,
		 $taglistBeg.$tmpcol1.$tmpcol2.$taglistEnd);}
	else {
	    print "*** ERROR wrtReferences: problem with tmplist=$tmplist (not <UL|OL>)\n";
	    exit;}
    }

    foreach $ref (@references){
	$ref=~s/^\n|\n$//g;
	print $fhout 
	    $ref,"\n";
    }
    if ($par{"order"}){
	print $fhout 
	    "</".$tmplist.">\n\n";
    }
    else {
	print $fhout
	    "</TABLE>\n";
    }

    return(1,"ok");
}				# end wrtReferences

# ================================================================================
sub wrtToc {
    local($fhoutLoc)=@_;
				# write table of contents (inside of file)
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------

    $Lwrtloc=0;

    print $fhoutLoc 
	"<!-- ","-" x 80 ," -->\n",
	"<!-- style: beg subtoc (table of contents) -->\n",
	"<DIV class=\"subtoc\">\n",
	"<STRONG><FONT SIZE=\"+2\" COLOUR=WHITE><A NAME=\"TOC\">Table of contents</A></FONT></STRONG>\n";

    $tocWrt="";
    $levelClose=0;
				# do we have to add references, here?
    $Lref=0;
    foreach $toc (@toc){
	$Lref=1 if (! $Lref && $toc=~/\breferences/i);
    }
    if (! $Lref){
	push(@toc,"H1=REFERENCES, txt=References");
    }

    foreach $toc (@toc){
	print "--- TOC make entry=$toc\n" if ($Lwrtloc);
	$toc=~s/(H\d)=//i;
	$level=$1;
	($ref,$txt)=split(/,\s*txt=\s*/,$toc);$ref=~s/\W*$//g;
	next if (length($ref)<1 || length($txt)<2);
	$numLevel=$level;
	$numLevel=~s/H//i;
	$numLevel=~s/\s//g;
	if ($toc !~/figure|table/i){
	    $toc="<A HREF=\""."\#".$ref."\"> $txt </A>";}
	else {
	    $toc="$txt";}
	    
	if (! defined $numLevelPrev){
	    $numLevel=    1;
	    $numLevelPrev=1;
	    $tocWrt.="<UL>\n";
	    ++$levelClose;
	}

	if ($numLevel != $numLevelPrev){
	    if ($numLevel>$numLevelPrev){
		++$levelClose;
		$toc="\t" x ($levelClose-1) . "<UL>\n".
		    "\t" x ($levelClose-1) . "<LI>".$toc."</LI>";
	    }
	    else {
		--$levelClose;
		$toc="\t" x ($levelClose)   . "</UL>\n".
		    "\t" x ($levelClose-1) . "<LI>".$toc."</LI>";
	    }
	    $numLevelPrev=$numLevel;
	}
	else {
	    $toc="\t" x ($levelClose-1) . "<LI>".$toc."</LI>";}

	$tocWrt.=$toc."\n";
				# figures: add links
	if ($toc=~/figure/i){
	    $tocWrt.="\t <UL>\n";
	    foreach $ittmp (1..$toc{"figures"}){
		$tmp="";
		$tmp=$toc{"figures",$ittmp} if (defined $toc{"figures",$ittmp});
		print "xx in toc fig($ittmp):",$toc{"figures",$ittmp},",\n";
		$tocWrt.="\t <LI><A HREF=\"\#fig".$ittmp."\">Fig. ".$ittmp."</A>";
		$tocWrt.=": ".$tmp          if (length($tmp)>0);
		$tocWrt.="</LI>\n";
	    }
	    $tocWrt.="\t </UL>\n";
	}
				# tables: add links
	if ($toc=~/table/i){
	    $tocWrt.="\t <UL>\n";
	    foreach $ittmp (1..$toc{"tables"}){
		$tmp="";
		$tmp=$toc{"tables",$ittmp} if (defined $toc{"tables",$ittmp});
		print "xx in toc tab($ittmp):",$toc{"tables",$ittmp},",\n";
		$tocWrt.="\t <LI><A HREF=\"\#table".$ittmp."\">Table ".$ittmp."</A>";
		$tocWrt.=": ".$tmp          if (length($tmp)>0);
		$tocWrt.="</LI>\n";
	    }
	    $tocWrt.="\t </UL>\n";
	}
    }
				# close others
    for ($it=$levelClose;$it>=1;--$it){
	$tocWrt.="\t" x ($it-1) . "</UL>\n";
    }

    print $fhoutLoc 
	$tocWrt;
    $tocWrt="";
    print $fhoutLoc 
	"</DIV>\n",
	"<!-- style: beg subtoc (table of contents) -->\n",
	"<!-- ","-" x 80 ," -->\n",
	"<BR>\n";
    return(1,"ok");
}				# end wrtToc

# ================================================================================
sub wrtTocExtra {
    local($fileInLoc,$fileTocLoc)=@_;
    local($fhoutLoc9);
    $[ =1 ;			# count from one
#-------------------------------------------------------------------------------
    $fhoutLoc9="FHOUT_wrtTocExtra";

    $fileInPath="../../$fileInLoc";
    open($fhoutLoc9, ">".$fileTocLoc) || die "*** ERROR opening toc=$fileTocLoc\n";
    print $fhoutLoc9 
	"<HTML>\n<HEAD><TITLE>$title</TITLE></HEAD>\n<BODY>\n",
	"<H1>Table of contents</H1>\n",
	"<H2><A HREF=\"$fileInPath\">for: $title </A></H2> ",
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
	next if (length($numLevel)<1);
	next if ($toc=~/^\s*$/);
	$toc="<A HREF=\"$fileInPath"."\#"."$ref\"> $txt </A>";
	if ($level ne "$prev"){
	    if ($numLevel>$numPrev){
		$toc="<UL>\n"."<LI>\t$toc";}
	else {
	    $toc="</UL>\n"."<LI>\t$toc";}
	    $prev=$level;$numPrev=$numLevel;}
	else {
	    $toc="<LI>\t$toc";}
	print $fhoutLoc9 
	    $toc,"\n";
    }
    print $fhoutLoc9
	"</UL>\n";
    print "--- TOC END\n";
    close($fhoutLoc9);
}				# end wrtTocExtra

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."subx";
    $fhinLoc="FHIN_"."subx";$fhoutLoc="FHOUT_"."subx";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty


    } close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of subx

