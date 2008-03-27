#!/usr/bin/perl -w
##!/usr/sbin/perl -w

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# script help asf
$scrName=$0;   $scrName=~s/^.*\/|\.pl//g;
$scrGoal=      "make index from directories\n";
$scrGoal.=     "     \t \n";
$scrGoal.=     "     \t";
$scrIn=        "directory (ies)";
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Apr,    	2000	       #
#------------------------------------------------------------------------------#
#
# 
#------------------------------------------------------------------------------#

$[ =1 ;				# count from one

				# ------------------------------
				# wrong input: short help
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","sort",    "no val", "sort files by date";
    printf "%5s %-15s=%-20s %-s\n","","nosort",  "no val", "do NOT sort files by date (alphabet=default)";

    printf "%5s %-15s=%-20s %-s\n","","web|w",   "no val", "write HTML file with INDEX";
    printf "%5s %-15s=%-20s %-s\n","","size|ws", "no val", "add size of files to HTML index";
    printf "%5s %-15s=%-20s %-s\n","","ref|ws",  "no val", "add links to files to HTML index";
    printf "%5s %-15s=%-20s %-s\n","","rel",     "x",      "HREF relative directory of link (=1 -> PLACE_HOLDER!)";

#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
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

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );

$par{"preDataIndex"}=       "INDEX.";
$par{"extDataIndex"}=       "";
$par{"preDataIndexHtml"}=   "INDEX_";
$par{"extDataIndexHtml"}=   ".html";

@kwd=sort (keys %par);

				# file handles
				# additional local parameters:
#$fhout=                        "FHOUT";
#$fhin=                         "FHIN";
$FHTRACE=                       "FHTRACE";
#$FHERROR=                       "STDERR";
$par{"debug"}=                  0;
$par{"verbose"}=                0;


				# initialise variables
$#dirIn=0;
$Lauto= 0;
$Lsort= 0;
$Lweb=      0;
$Lwebsize=  0;
$Lwebref=   0;
$dirWebRel= 0;
$Ldebug=$Lverb=0;

				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if ($arg=~/^de?bu?g$/)                { $Ldebug=$par{"debug"}=  1;
					    $Lverb=$par{"verbose"}= 1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=$par{"verbose"}= 1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=$par{"verbose"}= 0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}

    elsif ($arg=~/^auto$/i)               { $Lauto=          1;}

    elsif ($arg=~/^(web|www|w)$/i)        { $Lweb=           1;}
    elsif ($arg=~/^(size|s)$/i)           { $Lweb=           1;
					    $Lwebsize=       1;}
    elsif ($arg=~/^(ref|r)$/i)            { $Lweb=           1;
					    $Lwebref=        1;}
    elsif ($arg=~/^rel=(.*)$/)            { $dirWebRel=      $1;
					    $dirWebRel=      "PLACE_HOLDER/" if ($dirWebRel eq "1");}

    elsif ($arg=~/^sort$/i)               { $Lsort=          1;}
    elsif ($arg=~/^nosort$/i)             { $Lsort=          0;}

    elsif (-d $arg)                       { push(@dirIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

die ("*** ERROR $scrName: no directory!\n")
    if ($#dirIn < 1);

$dirIn=$dirIn[1];
die ("*** ERROR $scrName: missing input $dirIn!\n") 
    if (! -e $dirIn);


#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------

				# --------------------------------------------------
				# loop over all directories
				# --------------------------------------------------
foreach $dirIn (@dirIn){

    $tmp=$dirIn;
    $tmp=~s/\/$//;		# purge last '/'
    $tmp=~s/^.*\///g;		# purge leading path 'xx/directory_to_check'

    $fileOutIndex=$par{"preDataIndex"}.$tmp.$par{"extDataIndex"};
    print "--- $scrName: working on dir=$dirIn fileout=$fileOutIndex\n";

    if ($Lsort){
	($Lok,$msg,$files)=
	    &sysIndexMakeSort
		($dirIn,$fileOutIndex,0,0,1
		 );             return(&errSbrMsg("after call sysIndexMakeSort($dirIn)",$msg)) if (! $Lok);}
    else {
	$fileOutIndex=$par{"preDataIndex"}.$tmp.$par{"extDataIndex"};
	($Lok,$msg,$files)=
	    &sysIndexMake
		($dirIn,$fileOutIndex,0,1
		 );             return(&errSbrMsg("after call sysIndexMake($dirIn)",$msg)) if (! $Lok);}
				# ------------------------------
				# index to WWW
    next if (! $Lweb);

    $fileOutWeb=$par{"preDataIndexHtml"}.$tmp.$par{"extDataIndexHtml"};

    ($Lok,$msg,$tmp)=
	&htmlIndex
		($dirIn,$fileOutIndex,$fileOutWeb,$Lwebref,$Lwebsize,$dirWebRel,0,0
		 );             return(&errSbrMsg("after call htmlIndex($dirIn,$fileOutIndex)",
						  $msg)) if (! $Lok);

}				# end of loop over directories
				# ------------------------------
exit;


#==============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#==============================================================================
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

#==============================================================================
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
sub htmlIndex {
    local($dirInLoc,$fileInLoc,$fileOutLoc,$LrefLoc,$LsizeLoc,$dirRellinkLoc,
	  $iconLoc,$iconUpLoc) = @_ ;
    local($SBR3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndex                   makes index of WWW directory: output in HTML
#       in:                     $dirInLoc         directory
#       in:                     $fileInLoc        file with full directory index
#       in:                     $fileOutLoc       name of file with index
#                                  =0          -> no file written, just return 'html' text
#                                  =1          -> to standard out
#       in:                     $LrefLoc          write 'A HREF' in HTML
#       in:                     $LsizeLoc         write file size in HTML
#       in:                     $dirRellinkLoc    relative directory link used in 'A HREF'
#       in:                     $iconLoc          file with ICON-gif for dir
#                                  =0          -> no icon
#                                  =1          -> default icon in public_html/Dicon/mis_file.gif
#       in:                     $iconUpLoc        file with ICON-directory-up-gif for dir
#                                  =0          -> no icon
#                                  =1          -> default icon in public_html/Dicon/mis_up.gif
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
#    $SBR3=$packName.":"."htmlIndex";
    $SBR3="htmlIndex";
    $fhinLoc="FHIN_"."htmlIndex";$fhoutLoc="FHOUT_"."htmlIndex";
				# check arguments
    return(&errSbr("not def dirInLoc!",                     $SBR3)) if (! defined $dirInLoc);
    return(&errSbr("not def fileInLoc!",                    $SBR3)) if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc! ('0' for wildcard)",$SBR3)) if (! defined $fileOutLoc);
    return(&errSbr("not def LrefLoc!",                      $SBR3)) if (! defined $LrefLoc);
    return(&errSbr("not def LsizeLoc!",                     $SBR3)) if (! defined $LsizeLoc);
    return(&errSbr("not def dirRellinkLoc!",                $SBR3)) if (! defined $dirRellinkLoc);
#    return(&errSbr("not def !",$SBR3)) if (! defined $);
#    return(&errSbr("not def iconLoc! ('0' for wildcard)",   $SBR3)) if (! defined $iconLoc);
#    return(&errSbr("not def ! ('0' for wildcard)",$SBR3)) if (! defined $);
#    return(&errSbr("not def !",$SBR3)) if (! defined $);

    return(&errSbr("no fileInLoc=$fileInLoc!",$SBR3)) if (! -e $fileInLoc && 
							  ! -l $fileInLoc);

    $iconLoc=    "mis_file.gif" if (! defined $iconLoc     || $iconLoc     eq "1");
    $iconUpLoc=  "mis_up.gif"   if (! defined $iconUpLoc   || $iconUpLoc   eq "1");


    $dirRelative=$dirInLoc;
    $dirRelative=~s/\/$//g;
    $dirRelative=~s/^.*\///g;

    $tmpwrt="";
    $tmpwrt.="<HTML>\n";
    $tmpwrt.="<HEAD><TITLE>INDEX ".$dirRelative."</TITLE></HEAD>\n";
    $tmpwrt.="<BODY BGCOLOR=\"WHITE\">\n";
    $tmpwrt.="<H1>Index for directory ".$dirRelative."</H1>\n";
    $tmpwrt.="<BR>";
	
    if ($iconUpLoc){
	$tmpwrt.="<IMG SRC=\"".$iconUpLoc."\">"."&nbsp\;";
	$tmpwrt.="<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n";}
	    
    if ($LsizeLoc){
	$tmpwrt.="<P> </P>\n";
	$tmpwrt.="<P><I>Note: brackets give size of respective files</I></P>\n";
	$tmpwrt.="<P> </P>\n";}
	
				# ------------------------------
				# read index file
    open($fhinLoc,$fileInLoc)||
	return(&errSbr("failed opening in fileInLoc=".$fileInLoc."!\n",$SBR3));
    while (<$fhinLoc>) {
	$_=~s/\n//g;
#	$_=~s/^.*\///g;		# purge dir
#	$_=~s/\..*$//g;		# purge ext
	$_=~s/\s//g;
	$file=$_;
	$filetmp=$file;
	$filetmp=~s/^.*\///g;
	$fileshow=$filetmp;
	$filetmp=$dirRellinkLoc.$dirRelative."/".$filetmp if ($dirRellinkLoc);
	
	$tmpwrt.="<IMG SRC=\"".$iconLoc."\">"."&nbsp\;" 
	    if ($iconLoc);
	$tmpwrt.="<A HREF=\"".$filetmp."\">"
	    if ($LrefLoc);
	$tmpwrt.=$fileshow;

	$tmpwrt.="</A> &nbsp\; "
	    if ($LrefLoc);

	if ($LsizeLoc){
	    ($tmp,$tmp,$tmp,$tmp,$tmp,$tmp,$tmp,
	     $tmpsize,@tmp)=stat ($file);
	    if ($tmpsize < 1000){
		$tmpsize=$tmpsize/1000;
		$tmpsize=~s/^([\-\d]+\.\d\d).*$/$1/;}
	    else {
		$tmpsize=int($tmpsize/1000);}
	    $tmpwrt.="(".$tmpsize." K)";}

	$tmpwrt.="<BR>\n";
    }
    close($fhinLoc);

    $tmpwrt.="<P><BR></P>\n";

    if ($iconUpLoc){
	$tmpwrt.="<IMG SRC=\"".$iconUpLoc."\">"."&nbsp\;";
	$tmpwrt.="<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n";}
	    
    $tmpwrt.="</BODY>\n";
    $tmpwrt.="</HTML>\n";


				# ------------------------------
				# that is it folks, no file!
				# <-- <-- <-- <-- <-- <-- <-- <-- 
    return(1,"ok",$tmpwrt)
	if (! $fileOutLoc);
				# <-- <-- <-- <-- <-- <-- <-- <-- 
				# ------------------------------

				# ------------------------------
				# 
    if ($fileOutLoc eq "1"){
	$fhoutLoc="STDOUT";}
    else {
	open($fhoutLoc,">".$fileOutLoc) || 
	    return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR3));}
    print $fhoutLoc
	$tmpwrt;
    $tmpwrt="";

    if ($fhoutLoc ne "STDOUT"){
	close($fhoutLoc);
				# ------------------------------
				# make sure it is readable
	$cmd="chmod +r $fileOutLoc";
	($Lok,$msg)=
	    &sysRunProg($cmd,0,
			0); }        

    return(1,"ok $SBR3",1);
}				# end of htmlIndex

#===============================================================================
sub sysIndexMake {
    local($dirInLoc,$fileOutLoc,$exclLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysIndexMake                reads directory and makes index
#                                   OUTPUT sorted by alphabet
#       in:                     $dirInLoc      : directory to read
#       in:                     $fileOutLoc    : name of file with index
#                                  =0          -> no file written, just return list
#                                  =1          -> to standard out
#       in:                     $exclLoc       : regular expression to exclude
#                                  =0          -> no exclusion
#       in:                     $fhErrSbr      : file handle to write
#                                  =0          -> no blabla written
#                                  =1          -> to standard out
#                               
#       out:                    1|0,msg,  implicit:
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."sysIndexMake";
    $fhinLoc="FHIN_"."sysIndexMake";$fhoutLoc="FHOUT_"."sysIndexMake";
				# check arguments
    return(&errSbr("not def dirInLoc!"))                      if (! defined $dirInLoc);
    return(&errSbr("not def fileOutLoc! ('0' for wildcard)")) if (! defined $fileOutLoc);
    return(&errSbr("not def exclLoc! ('0' for wildcard)"))    if (! defined $exclLoc);
    return(&errSbr("not def fhErrSbr! ('0' for wildcard)"))   if (! defined $fhErrSbr);
#    return(&errSbr("not def !"))          if (! defined $);


    return(&errSbr("dirIn=$dirInLoc??"))                      if (length($dirInLoc)<1 ||
								  $dirInLoc=~/^[\.\/\s]+$/);
    return(&errSbr("no dirIn=$dirInLoc!"))                    if (! -d $dirInLoc);

    $fhErrSbr=  "STDOUT"        if ($fhErrSbr eq "1");

				# ------------------------------
				# read directory
    opendir ($fhinLoc,$dirInLoc) || 
	return(&errSbr("dirInLoc=$dirInLoc, not opened"));
    @tmp=grep !/^\.\.?/, readdir($fhinLoc);
    closedir($fhinLoc);

    $dirInLoc.="/"              if ($dirInLoc !~ /\/$/);

    $#tmp2=0;
				# ------------------------------
				# process files
    foreach $tmp (@tmp){
				# ignore those starting with a '.'
	next if ($tmp=~/^\.+/);
				# ignore those wanted to ignore
	next if ($exclLoc &&
		 $tmp=~/$exclLoc/);
	$file=$dirInLoc.$tmp;
	if (! -e $file){
	    print $fhErrSbr
		"*-* BAD WARN: $sbrName: missing file=$file, in dir=$dirInLoc\n"
		    if ($fhErrSbr);
	    next; }
				# add to list
	push(@tmp2,$file);
    }
				# ------------------------------
				# sort alphabetically
    $#tmp=0;
    @tmp=sort(@tmp2);
    $#tmp2=0;
				# ------------------------------
				# write index file
    if ($fileOutLoc){
	if ($fileOutLoc eq "1"){
	    $fhoutLoc="STDOUT";}
	else {
	    open($fhoutLoc,">".$fileOutLoc) || 
		return(&errSbr("fileOutLoc=$fileOutLoc, not created"));}

	foreach $file (@tmp){
	    print $fhoutLoc $file,"\n";
	}
	close($fhoutLoc)        if ($fhoutLoc ne "STDOUT");
    }
				# clean up
    $tmp=join(',',@tmp);
    $#tmp=0;

    return(1,"ok $sbrName",$tmp);
}				# end of sysIndexMake

#===============================================================================
sub sysIndexMakeSort {
    local($dirInLoc,$fileOutLoc,$exclLoc,$cmdLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysIndexMakeSort            reads directory and makes index
#                                   OUTPUT sorted by time
#       in:                     $dirInLoc      : directory to read
#       in:                     $fileOutLoc    : name of file with index
#                                  =0          -> no file written, just return list
#                                  =1          -> to standard out
#       in:                     $exclLoc       : regular expression to exclude
#                                  =0          -> no exclusion
#       in:                     $cmdLoc        : ls command to execute
#                                  =<1|0|>     -> 'ls -1t'
#       in:                     $fhErrSbr      : file handle to write
#                                  =0          -> no blabla written
#                                  =1          -> to standard out
#                               
#       out:                    1|0,msg,  implicit:
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."sysIndexMakeSort";
    $fhinLoc="FHIN_"."sysIndexMakeSort";$fhoutLoc="FHOUT_"."sysIndexMakeSort";
				# check arguments
    return(&errSbr("not def dirInLoc!"))                      if (! defined $dirInLoc);
    return(&errSbr("not def fileOutLoc! ('0' for wildcard)")) if (! defined $fileOutLoc);
    return(&errSbr("not def exclLoc! ('0' for wildcard)"))    if (! defined $exclLoc);
    return(&errSbr("not def fhErrSbr! ('0' for wildcard)"))   if (! defined $fhErrSbr);
#    return(&errSbr("not def !"))          if (! defined $);


    return(&errSbr("dirIn=$dirInLoc??"))                      if (length($dirInLoc)<1 ||
								  $dirInLoc=~/^[\.\/\s]+$/);
    return(&errSbr("no dirIn=$dirInLoc!"))                    if (! -d $dirInLoc);

    $fhErrSbr=  "STDOUT"        if ($fhErrSbr eq "1");
    $cmdLoc="ls -1t"            if ($cmdLoc =~ /^[10]$/ ||
				    length($cmdLoc)<1);

    $cmdLoc.=" $dirInLoc";
				# ------------------------------
				# read directory
    @tmp=`$cmdLoc`;
    print $fhErrSbr "--- $sbrName: system '$cmdLoc'\n"
	if ($fhErrSbr);

    $dirInLoc.="/"              if ($dirInLoc !~ /\/$/);

    $#tmp2=0;
				# ------------------------------
				# process files
    foreach $tmp (@tmp){
				# purge new line, spaces
	$tmp=~s/\n|\s//g;
				# ignore those starting with a '.'
	next if ($tmp=~/^\.+/);
				# ignore those wanted to ignore
	next if ($exclLoc &&
		 $tmp=~/$exclLoc/);
	$file=$dirInLoc.$tmp;
	if (! -e $file){
	    print $fhErrSbr
		"*-* BAD WARN: $sbrName: missing file=$file, in dir=$dirInLoc\n"
		    if ($fhErrSbr);
	    next; }
				# add to list
	push(@tmp2,$file);
    }

				# ------------------------------
				# write index file
    if ($fileOutLoc){
	if ($fileOutLoc eq "1"){
	    $fhoutLoc="STDOUT";}
	else {
	    open($fhoutLoc,">".$fileOutLoc) || 
		return(&errSbr("fileOutLoc=$fileOutLoc, not created"));}

	foreach $file (@tmp2){
	    print $fhoutLoc $file,"\n";
	}
	close($fhoutLoc)        if ($fhoutLoc ne "STDOUT");
    }
				# clean up
    $#tmp=0;
    $tmp=join(',',@tmp2);
    $#tmp2=0;

    return(1,"ok $sbrName",$tmp);
}				# end of sysIndexMakeSort

#======================================================================
sub sysRunProg {
    local ($cmd,$fileScrLoc,$fhErrLoc) = @_ ;
    $[ =1;
#-------------------------------------------------------------------------------
#   sysRunProg                  pipes arguments into $prog, and cats the output
#                               from $prog into a file
#       in:                     $cmd,$fileScrLoc,$fhError
#       in:                     $cmd='prog,arg1,arg2' 
#       in:                          where prog is the program, e.g. 'wc -l, file1,file2'
#       in:                     $fileScrLoc     is the output file
#       in:                        NOTE: if not defined: buffered to STDOUT
#       in:                      = 0            to surpress writing
#       in:                     $fhError        filehandle for ERROR writing
#                                  NOTE: to STDOUT if not defined
#       in:                      = 0            to surpress writing
#       out:                    0|1,message
#       err:                    ok -> 1,ok | err -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system fileOut=$fileScrLoc, cmd=\n$prog\n";}
				# ------------------------------
				# pipe output into file?
    $Lpipe=0;
    $Lpipe=1                    if ($fileScrLoc);
				# hack br: 08-98 to avoid pipe pipe, i.e.
				#          prog="cmd > file" -> 'cmd > file | cat >> filescreen' fails
    $Lpipe=0                    if ($prog =~ /\s+>>?\s+\S+\s*$/);
    $prog.=" | cat >> $fileScrLoc " if ($Lpipe);
#    print "$cmd\n";exit;
				# ------------------------------
				# opens cmdtmp into pipe
    open (CMD, "|$prog") || 
	warn "*** $sbrName cannot run program '$prog $arg'";
				# get input arguments (< arg)
    foreach $tmp (@arg) {
	$tmp=~s/\n|^\s*|\s*$//; # delete end of line, and leading blanks 
	print CMD "$tmp\n" ;}
    close (CMD) ;		# upon closing: cmdtmp < @out_command executed    
    return(1,"ok $sbrName");
}				# end of sysRunProg

