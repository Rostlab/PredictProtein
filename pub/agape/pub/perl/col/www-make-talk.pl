#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="thumbnails all GIF files passed on command line\n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'path',                   "", # directory or URL path for files
      '', "",			# 
      'width',                  "150",
      'height',                 "100",
      'email',                  "rost\@columbia.edu",
      'www',                    "http://cubic.bioc.columbia.edu/",
      '', "",			# 
      'arrowUp',                "/home/rost/public_html/MAT/arrow-up.gif",
      'arrowDown',              "/home/rost/public_html/MAT/arrow-down.gif",
      '', "",			# 
      'ftpUrl',                 "ftp://cubic.bioc.columbia.edu/pub/mis/talks/",
#      'exeTar',                 "/usr/bin/tar",
      'exeTar',                 "/bin/tar",
      'exeGzip',                "/bin/gzip",
#      'exeGzip',                "/usr/bin/gzip",
#      'exeGzip',                "/usr/sbin/gzip",
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<2){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName title *gif'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
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
$fhout="FHOUT";
$LisList=0;
$#fileIn=0;
$title=$ARGV[1]; $title=~s/title=//g;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^title=(.*)$/)          { $title=          $1;}

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

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
$fileOut="index.html";
die ("*** output IS 'index.html'!\n".
     "please make sure you run the script in the right directory!\n")
    if (-e $fileOut);

$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && ! $LisList) || $fileIn !~/\.list/) {
	push(@fileTmp,$fileIn);
	next;}
    ($Lok,$msg,$file,$tmp)=
	&fileListRd($fileIn);   if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
					     exit; }

    @tmpf=split(/,/,$file); push(@fileTmp,@tmpf);}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in
				# ------------------------------
				# (1) write index.html
				# ------------------------------
$par{"path"}.="/"               if ($par{"path"} &&
                                    length($par{"path"})>1);


$tmp=$title;
$tmp=~s/ /_/g;
$tmp=~s/,/_/g;
$tmp=~s/__+/_/g;

#$fileOutAll=$tmp."-all.html";
$fileOutAll=    "talk.html";
$fileOutTar=    $par{"ftpUrl"}.$tmp.".tar.gz";

$#fileOutOne=0;
foreach $file (@fileIn){
    $fileOutOne=$file;
    $fileOutOne=~s/\.(gif|j.*g)/.html/;
    push(@fileOutOne,$fileOutOne);
    $img{$fileOutOne}=$file;
}

open($fhout,">".$fileOut) || die "*** $scrName: failed opening output file=$fileOut\n";
print $fhout
    "<HTML>\n",
    "<HEAD>\n",
    "<TITLE>\n",
    "\tSlides for talk $title\n",
    "<\/TITLE>\n",
    "<BODY BGCOLOR=\"WHITE\">\n",
    "<\/HEAD>\n",
    "<H1>Slides for talk $title<\/H1>\n",
    "<H2>Contact: Burkhard Rost, <A HREF=\"mailto:".
    $par{"email"}."\">".$par{"email"}."<\/A><\/H2>\n",
    "<UL>\n",
    "<LI>all slides in <A HREF=\"$fileOutAll\">one file<\/A><\/LI>\n",
    "<LI><A HREF=\"".$fileOutOne[1]."\">walk<\/A> through talk<\/LI>\n",
    "<HR>\n",
    "<LI>all slides to <A HREF=\".".$fileOutTar."\">ftp<\/A> (as tar archive)</LI>\n",
#    "<LI></LI>\n",
    "<LI>CUBIC home<A HREF=\".".$par{"www"}."\">".$par{"www"}."<\/A></LI>\n",
    "<\/UL>\n",
    "<P>\n",
    "<\/BODY>\n",
    "<\/HTML>\n";
				# ------------------------------
				# write summary with all
				# ------------------------------
open($fhout,">".$fileOutAll) || 
    die "*** $scrName: failed opening output file=$fileOutAll\n";
				# header
print $fhout
    "<HTML>\n",
    "<HEAD>\n",
    "<TITLE>\n",
    "\tSlides for talk $title\n",
    "<\/TITLE>\n",
    "<\/HEAD>\n",
    "<BODY BGCOLOR=\"BLUE\" LINK=\"RED\" VLINK=\"SILVER\" ALINK=\"RED\">\n",
    "<CENTER>\n",
    "<FONT COLOR=\"WHITE\" SIZE=\"+3\">\n",
    "<P>\n",
    "<A HREF=\"".$fileOutOne[1]."\">Walk through talk<\/A>\n",
    "<P>\n",
    "<STRONG>Slides for talk $title<P>\n",
    "\tContact: Burkhard Rost, <A HREF=\"mailto:".
    $par{"email"}."\">".$par{"email"}."<\/A>\n",
    "<\/STRONG><P>\n",
    "<P>\n",
    "click thumbnail to see larger image of GIF\n",
    "<P>\n",
    "<\/CENTER>\n",
    "<P>\n";

				# now for all slides
foreach $file (@fileIn){
    print $fhout
	"<A HREF=\"".$par{"path"}.$file."\">",
	"<IMG ALIGN=ABSMIDDLE WIDTH=".$par{"width"}." HEIGHT=".$par{"height"}." SRC=\"",
	$par{"path"}.$file."\" ALT=".$file."\"><\/A> \n";
}

				# final
print $fhout
    "<CENTER>\n",
    "<P>\n",
    "<A HREF=\"".$fileOutOne[1]."\">Walk through talk<\/A>\n",
    "<P>\n",
    "<\/CENTER>\n",
    "<\/FONT>\n",
    "<\/BODY>\n",
    "<\/HEAD>\n",
    "<\/HTML>\n";
close($fhout);

				# ------------------------------
				# write summary with all
				# ------------------------------
$ct=0;
if (-e $par{"arrowUp"}){
    $tmp=$par{"arrowUp"}; $tmp=~s/^.*\///g;
    system("\\cp ".$par{"arrowUp"}." .");
    $prev="<IMG ALIGN=MIDDLE SRC=\"".$tmp."\">";}
else {
    $prev=" PREV ";}

if (-e $par{"arrowDown"}){
    $tmp=$par{"arrowDown"}; $tmp=~s/^.*\///g;
    system("\\cp ".$par{"arrowDown"}." .");
    $next="<IMG ALIGN=MIDDLE SRC=\"".$tmp."\">";}
else {
    $next=" NEXT ";}

foreach $fileOutOne (@fileOutOne){
    ++$ct;
    open($fhout,">".$fileOutOne) || 
	die "*** $scrName: failed opening output file=$fileOutOne\n";
				# header
    print $fhout
	"<HTML>\n",
	"<HEAD>\n",
	"<TITLE>\n",
	"\tSlide $ct for talk $title\n",
	"<\/TITLE>\n",
	"<BODY BGCOLOR=\"WHITE\">\n",
	"<P>\n",
	"<CENTER>\n",
	"\t<A HREF=\"".$fileOutAll."\">ALL-in-one<\/A> - \n";
    print $fhout
	"<\/CENTER>\n",
	"<P>\n",
	"<H1>Slide $ct for talk $title<\/H1>\n",
	"<H2>Contact: Burkhard Rost, <A HREF=\"mailto:".
	    $par{"email"}."\">".$par{"email"}."<\/A><\/H2>\n";
    print $fhout
	"<P>\n",
	"<CENTER>\n";
	    
    print $fhout
	"\t<A HREF=\"".$fileOutOne[$ct-1]."\">".$prev."<\/A> \n"
	    if ($ct>1);
    print $fhout
	"\t<A HREF=\"".$fileOutOne[$ct+1]."\">".$next."<\/A>  \n"
	    if ($ct<$#fileOutOne);
				# image
    print $fhout
	"<A HREF=\"".$par{"path"}.$img{$fileOutOne}."\">",
	"<IMG ALIGN=ABSMIDDLE SRC=\"",
	$par{"path"}.$img{$fileOutOne}."\" ALT=".$img{$fileOutOne}."\"><\/A>\n",
	"<P>\n";

    print $fhout
	"<\/CENTER>\n";

				# final
    print $fhout
	"<P>\n",
	"<\/BODY>\n",
	"<\/HEAD>\n",
	"<\/HTML>\n";

    close($fhout);
}				# end of loop over 'one-by-one'


				# ------------------------------
				# all in TAR
				# ------------------------------
$fileTmp=$fileOutTar; $fileTmp=~s/\.gz//g;
unlink($fileTmp) if (-e $fileTmp);
$cmd=$par{"exeTar"}. " " . $fileTmp . " *.gif";
print "--- system '$cmd'\n";
system("$cmd");

$cmd=$par{"exeGzip"}. " " . $fileTmp;
print "--- system '$cmd'\n";
system("$cmd");


print "--- output=$fileOut\n";

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

#===============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd


