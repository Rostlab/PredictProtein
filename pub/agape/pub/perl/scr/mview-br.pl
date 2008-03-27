#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="calling mview with standard parameters";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	CUBIC (Columbia Univ)	http://www.embl-heidelberg.de/~rost/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Mar,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'exeMview',    "/home/rost/molbio/mview/bin/mview",			# 
      '', "",			# 
      'parStandard', "-css on -srs on".
                     " -html head -ruler on".
                     " -coloring consensus -threshold 50 -consensus on -con_coloring any",	
      'parWidth',    0,
      '', "",			# 
      'debug',       0,
      'verbose',     0,
      'format',      "unk",			# 
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName files_to_convert* (or list of those in file)'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","width",   "x",        "number of characters per line (=0 for 'all in one')";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";

    printf "%5s %-20s %-20s %-s\n","","dbg",      "no value","debug mode (full screen)";
    printf "%5s %-20s %-20s %-s\n","","<noScreen|silent>", "no value","no info onto screen";

#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
#$fhin="FHIN";$fhout="FHOUT";
$LisList=0;
$#fileIn=$#chainIn=0;
$fileOut=$#fileOut=0;
				# screen output?

$fhTrace=0                      if (! $par{"debug"} && ! $par{"verbose"});

				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^width=(.*)$/)          { $par{"parWidth"}=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^list$/i)               { $LisList=        1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");
					    # automatic detection of list
					    $LisList=        1 if ($arg =~ /\.list/); }
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
				# logicals: names are in a file
    elsif ($arg =~ /^de?bu?g$/)           { $par{"debug"}=   1; 
					    $par{"verbose"}=1;}
    elsif ($arg =~ /^(\-s|silent|no.creen)$/) { $par{"verbose"}= 0;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=$#chainTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && ! $LisList) || $fileIn !~/\.list/) {
	push(@fileTmp,$fileIn);
	push(@chainTmp,"*");
	next;}
    ($Lok,$msg,$file,$tmp)=
	&fileListRd($fileIn);   if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
					     exit; }

    @tmpf=split(/,/,$file); push(@fileTmp,@tmpf);
    @tmpc=split(/,/,$tmp);
    if ($#tmpc>0) { push(@chainTmp,@tmpc);}
    else { 
	foreach $ct (1..$#tmpf){
	    push(@chainTmp,"*");}} }
@fileIn= @fileTmp; @chainIn=@chainTmp; 
$#fileTmp=$#chainTmp=0;		# slim-is-in

				# --------------------------------------------------
				# (0) build up parameter for MView
				# --------------------------------------------------
				# number of characters per line
$par{"parStandard"}.=
    " -width ".$par{"parWidth"} if ($par{"parWidth"});


				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
$ct=0;
foreach $fileIn (@fileIn){
    ++$ct;
    if (! -e $fileIn && $fhTrace){
	print "-*- WARN $scrName: no fileIn=$fileIn\n";
	next;}

    $LisHssp=0;
    $LisHssp=1                  if ($fileIn=~/\.hssp/);
    print "--- $scrName: working on '$fileIn'\n" if ($par{"verbose"});
    
    $chainIn=" ";
    $chainIn=$chainIn[$ct]      if (defined $chainIn[$ct] && $chainIn[$ct] && $chainIn[$ct] =~ /^[0-9A-Z]$/);

    ($Lok,$fileOut)=
	&mviewRun($fileIn,$chainIn,$par{"exeMview"},$par{"parStandard"},
		  0,$fileOut,$fhTrace);

    if (! $Lok) { print "*** ERROR $scrName: failed on mview (from $fileIn):\n",$fileOut,"\n";
		  next; }

    push(@fileOut,$fileOut);
}
				# ------------------------------
if ($par{"verbose"}) {
    print "--- end of $scrName:\n";
    print "--- fileOut=",join(',',@fileOut),"\n"   if ($#fileOut>0); }

print STDERR "*** ERROR $scrName: no output file written !!!\n" if ($#fileOut==0);

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
    &open_file("$fhinLoc","$fileInLoc") ||
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

#===============================================================================
sub sysSystem {
    local($cmdLoc,$fhLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysSystem                   simple way of running system command + documenting them
#       in:                     $cmd:   will do system($cmd)
#       in:                     $fhLoc: will write trace onto fhLoc
#                                 =<! defined> -> STDOUT
#                                 =0           -> no output
#       out:                    <1|0>,<"value from system"|$errorMessag>
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."sysSystem";
				# no argument given
    return(0,"*** ERROR $sbrName: no input argument (system command)")
	if (! defined $cmdLoc || ! $cmdLoc);

				# default
    $fhLoc="STDOUT"             if (! defined $fhLoc);
    
				# ------------------------------
				# write
    print $fhLoc "--- system: \t $cmdLoc\n" if ($fhLoc);

				# ------------------------------
				# run system
    $Lsystem=
	system("$cmdLoc");

    return(1,$Lsystem);
}				# end of sysSystem

#===============================================================================
sub mviewRun {
    local($fileInLoc,$chainInLoc,$exeMviewLoc,$parStandard,$parWidth,
	  $fileOut,$optOut,$fhoutSbr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   mviewRun                    runs MView (Nigel Brown) on an alignment
#            COPYRIGHT          Nigel Brown
#            QUOTE              N P Brown, C Leroy, C Sander (1998), Bioinformatics. 14(4):380-381
#                               (MView: A Web compatible database search or multiple alignment viewer)
#       in:                     $fileInLoc=       file with alignment (format recognised by extension)
#       in:                     $chainInLoc=      chain for HSSP format (otherwise=0)
#                                  =0             not used
#       in:                     $exeMview=        executable (perl)
#       in:                     $paraStandard=    standard parameters
#                                   =0            for standard setting
#       in:                     $fileOut=         name of output file
#                                  =0             -> will name it
#       in:                     $optOut=          HTML option <body|data|title>
#                                  =0             full HTML page
#       in:                     $fhoutSbr=        file handle to write system call
#                                  =0             no output reported
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."mviewRun";
    $fhinLoc="FHIN_"."mviewRun";$fhoutLoc="FHOUT_"."mviewRun";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))         if (! defined $chainInLoc);
    return(&errSbr("not def exeMviewLoc!"))        if (! defined $exeMviewLoc);
    return(&errSbr("not def parStandard!"))        if (! defined $parStandard);
    return(&errSbr("not def parWidth!"))           if (! defined $parWidth);
    return(&errSbr("not def fileOut!"))            if (! defined $fileOut);
    $optOut=0                                      if (! defined $optOut);
    $fhoutSbr=0                                    if (! defined $fhoutSbr);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);
    return(&errSbr("no fileIn=$exeMviewLoc!"))     if (! -e $exeMviewLoc && !-l $exeMviewLoc);
				# local defaults
    if (! $parStandard) {
	$parStandard= "-css on -srs on";
	$parStandard.=" -html head -ruler on";
	$parStandard.=" -coloring consensus -threshold 50 -consensus on -con_coloring any";}

    $LisHssp=0;
    $LisHssp=1                  if ($fileInLoc=~/\.hssp/);

    $cmd= $exeMviewLoc." ".$parStandard." ";

				# ------------------------------
				# HSSP input
    if    ($LisHssp) {
	$cmd.=" -in hssp"; 
	$cmd.=" -chain $chainInLoc"
	    if (defined $chainInLoc && $chainInLoc && $chainInLoc =~ /^[0-9A-Z]$/); }
				# MSF input
    elsif ($fileIn=~/\.msf/) {
	$cmd.=" -in msf"; }
    elsif (defined $par{"format"} && 
	   $par{"format"} ne "unk"){
	$cmd.=" -in ".$par{"format"};}
				# unk input format
    else {
	return(0,"*** WARN $scrName: skipped $fileInLoc, since format unk\n"); }

				# ------------------------------
				# output
    if (! $fileOutLoc) {
	$fileOutLoc=$fileInLoc; 
				# purge dirs for data bases asf
	$fileOutLoc=~s/^.*\///g if (! -w $fileInLoc);

	$fileOutLoc=~s/\.(hssp|msf).*$//g;
	$fileOutLoc.=".html_mview"; }
				# ------------------------------
				# number of characters per line
    $cmd.=" -width ".$parWidth  if ($parWidth);

				# security 1: same as input?
    $fileOut="mview_of".$fileInLoc.".html" if ($fileOutLoc eq $fileInLoc);
				# security 2: delete if exists
    if (-e $fileOutLoc) { 
	print "-*- WARN $sbrName deletes file $fileOutLoc\n";
	unlink($fileOutLoc); }
				# full HTML page?
    $cmd.=" -html $optOut"
	if ($optOut);
				# finally add input file
    $cmd.=" $fileInLoc";
				# past into output file!
    $cmd.=" >> $fileOutLoc";

				# ------------------------------
				# run program
    ($Lok,$msg)=
	&sysSystem("$cmd",$fhoutSbr);

    return(0,"*** ERROR $scrName: failed on mview (from $fileIn):\n".$msg."\n")
	if (! $Lok);
		  
    return(1,$fileOutLoc);
}				# end of mviewRun

