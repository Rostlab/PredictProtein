#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="greps in the big_online.rdb file (file MUST have 'id TAB name TAB sequence'\n".
    "     \t input:  search pattern (<seq=|id=|name=>)\n".
    "     \t output: count of found, numbers found\n".
    "     \t \n".
    "     \t NOTE: default: write only numbers onto screen!\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2001	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	May,    	2001	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
$par{"dirDataBig"}=             "/data/derived/big/";
$par{"fileInDef"}=              $par{"dirDataBig"}."ONELINE_big.rdb";
$par{"fileInDef","swiss"}=      $par{"dirDataBig"}."ONELINE_swiss.rdb";
$par{"fileInDef","trembl"}=     $par{"dirDataBig"}."ONELINE_trembl.rdb";
$par{"fileInDef","pdb"}=        $par{"dirDataBig"}."ONELINE_pdb.rdb";
$par{"db2add"}=                 0;

$ptr{"id"}=   1;		# first column of input file=id
$ptr{"name"}= 2;		# second column of input file=name
$ptr{"seq"}=  3;		# third column of input file=sequence

$markhtmlbeg="<STRONG><FONT COLOR=BLUE>";
$markhtmlend="</FONT></STRONG>";

@kwd=sort (keys %par);
$Ldebug=   0;
$Lverb=    0;
$sep=      "\t";		# separator for output
$Ldetail=  0;

				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName <pdb|swiss|trembl> <id=x|name=y|seq=AAA> (perl pattern)'\n";
    print  "                note: seq='PXXP' will do 'P..P'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

    printf "%5s %-15s=%-20s %-s\n","","db",       "swiss|trembl|pdb", "use that db ('swiss,pdb' for many)";
    printf "%5s %-15s %-20s %-s\n","","swiss",    "no value","check SWISS-PROT";
    printf "%5s %-15s %-20s %-s\n","","trembl",   "no value","check TrEMBL";
    printf "%5s %-15s %-20s %-s\n","","pdb",      "no value","check PDB";

    printf "%5s %-15s %-20s %-s\n","","det",      "no value","write full info onto screen";
    printf "%5s %-15s %-20s %-s\n","","html",     "no value","write HTML with mark-up sequence";

#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
				# special
    if (($#ARGV==1 && $ARGV[1]=~/^special/) ||
	($#ARGV>1 && $ARGV[1] =~/^(-h|help)/ && $ARGV[2]=~/^spe/)){
    }

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
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
$#fileIn= 0;
$dirOut=  0;
$grepid=  0;
$grepname=0;
$grepseq= 0;
$Lhtml=   0;

				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^det$/)                 { $Ldetail=        1;}
    elsif ($arg=~/^html$/)                { $Lhtml=          1;}

    elsif ($arg=~/^db=(.*)$/)             { $par{"db2add"}=  $1;
					    $par{"db2add"}=~tr/[A-Z]/[a-z]/;}

    elsif ($arg=~/^(pdb|swiss|trembl)$/i) { $par{"db2add"}=  $1; 
					    $par{"db2add"}=~tr/[A-Z]/[a-z]/;}

    elsif ($arg=~/^id=(.*)$/)             { $grepid=         $1;}
    elsif ($arg=~/^name=(.*)$/)           { $grepname=       $1;}
    elsif ($arg=~/^seq=(.*)$/)            { $grepseq=        $1;
					    $grepseq=~s/x/\./ig;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

				# ------------------------------
				# (0) determine which files
				# ------------------------------
if ($#fileIn < 1){
				# all dbs to get
    $#db2add=0;
    if ($par{"db2add"}){
	@db2add= split(/,/,$par{"db2add"});
	foreach $db (@db2add){
	    if (! defined $par{"fileInDef",$db}){
		print "*** ERROR $scrName: db=$db, not understood (file missing)\n";
		exit;}
	    push(@fileIn,$par{"fileInDef",$db});
	}}
    else {
	push(@fileIn,$par{"fileInDef"});
    }}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
$#found=0;
$#foundhtml=0;
$wrtHead=   "";
$wrtHead.=  "# SEARCH pattern: ";
$wrtPattern= "";
$wrtPattern.=  " id: ".  $grepid       if ($grepid);
$wrtPattern.=  " name: ".$grepname     if ($grepname);
$wrtPattern.=  " seq: ". $grepseq      if ($grepseq);
$wrtHead.=  $wrtPattern."\n";

print "--- doing: \n",$wrtHead      if ($Lverb);

$wrtHead.=  "# SEARCH files: \n";


$ctnot=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
    while (<$fhin>) {
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	next if ($_=~/^id/);	# skip names

				# now start for keyword search
	@tmp=split(/\t+/,$_);
				# HARD_CODED position
	$Ltake=0;
				# ID
	$Ltake=1 if (            $grepid   && $tmp[$ptr{"id"}]=~/$grepid/i);
				# NAME
	$Ltake=1 if (! $Ltake && $grepname && $tmp[$ptr{"name"}]=~/$grepname/i);
	if ($grepseq && $tmp[$ptr{"seq"}]=~/$grepseq/i){
	    $Ltake=1;
	    if ($Lhtml){
		$tmpseq=$tmp[$ptr{"seq"}];
		$tmpseq=~s/($grepseq)/$markhtmlbeg$1$markhtmlend/gi;
		@tmphtml=@tmp;
		$tmphtml[$ptr{"seq"}]=$tmpseq;
	    }
	}

	if (! $Ltake){
	    ++$ctnot;
	    next;
	}
	push(@found,join("$sep",@tmp));
	push(@foundhtml,join("\t",@tmphtml)) if ($Lhtml);
    }
    close($fhin);
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    $wrtHead.="$tmp";
}
$wrtHead.="\n";
				# ------------------------------
				# (2) 
				# ------------------------------
$wrtHead.=sprintf("# %8d     %-s\n",$#found,"Number of proteins that matched");
$wrtHead.=sprintf("# %8d     %-s\n",$ctnot, "Number of proteins that did NOT match");
$wrtHead.=sprintf("#    %8.2f  %-s\n",
		  100*($#found/($#found+$ctnot)),"Percentage of proteins that matched")
		       if (($ctnot+$#found)>0);
$wrtHead.="# Proteins for which pattern was found \n";

if ($Lhtml){
    $wrtHtmlHead="<HTML>\n<HEAD>\n<TITLE>";
    $wrtHtmlHead.=$wrtPattern;
    $wrtHtmlHead.="</TITLE></HEAD><BODY bgcolor=WHITE>\n";
    $wrtHtmlHead.="<PRE>\n";
    $wrtHtmlHead.=$wrtHead;
    $wrtHtmlHead.="</PRE>\n";
}


$wrtBody= "id".$sep."name".$sep."sequence".$sep."\n";
if ($Lhtml){
    $wrtHtmlBody= "<TABLE WIDTH=\"100\%\">\n";
    $wrtHtmlBody.="<TR><TD>id</TD><TD>name</TD><TD>sequence</TD></TR>\n";
}

foreach $found (@found){
    $wrtBody.=$found."\n";
}

if ($Lhtml){
    foreach $found (@foundhtml){
	@tmp=split(/$sep/,$found);
	$wrtHtmlBody.="<TR><TD>".join("</TD><TD>",@tmp)."</TD></TR>\n";
    }
}
				# ------------------------------
				# (3) write output
				# ------------------------------
if (! defined $fileOut){
    $fileOut="OUT-search.tmp";
    if ($Lhtml){
	$fileOutHtml=$fileOut;
	$fileOutHtml=~s/\.[^\.]+$//;
	$fileOutHtml.=".html";
    }
}

open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut!\n";

print $fhout $wrtHead;
print $fhout $wrtBody;
close($fhout);

if ($Lhtml){
    open($fhout,">".$fileOutHtml) || warn "*** $scrName ERROR creating fileOuthtml=$fileOutHtml!\n";
    print $fhout $wrtHtmlHead;
    print $fhout $wrtHtmlBody;
    print $fhout "</BODY></HTML>\n";
    close($fhout);
}

if ($Lverb && $Ldetail){
    print $wrtBody;
}
print $wrtHead;
print "--- output in $fileOut\n"     if (defined $fileOut && -e $fileOut);
print "--- HTML   in $fileOutHtml\n" if (defined $fileOutHtml && -e $fileOutHtml);
exit;


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

