#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="perl wrapper around DSSP\n".
    "     \t \n".
    "     \t ";
#  
# 
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

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'dirOut',            "",	# output directory
      'extDssp',           ".dssp",
      'exeDsspBin',        "/home/rost/molbio/bin/dssp.ARCH",
      'parDsspCheck',      1,	# check DSSP for completeness
      'parDsspDelete',     0,	# delete empty DSSP files
      'optNice',           "nice -15",
      'doNew',             1,	# if 0: existing files will NOT be overwritten, instead job will be skipped
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName pdb_file*|or list'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file (only for one input file)";
    printf "%5s %-15s=%-20s %-s\n","","fileErr", "x",       "name of file with list of faulty DSSP files";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "output dir (only for many input files)";
    printf "%5s %-15s=%-20s %-s\n","","extOut",  "x",       "extension for DSSP (only for many input files)";
    printf "%5s %-15s %-20s %-s\n","","check",   "no value","if set: check DSSP file";
    printf "%5s %-15s %-20s %-s\n","","del",     "no value","delete empty DSSP files";
    printf "%5s %-15s=%-20s %-s\n","","exe",     "x",       "DSSP binary";
    printf "%5s %-15s=%-20s %-s\n","","ARCH",    "x",       "system architecture (SGI32|SGI64|ALPHA|LINUX)";
    printf "%5s %-15s %-20s %-s\n","","new",     "no value","existing DSSP files will be overwritten";
    printf "%5s %-15s %-20s %-s\n","","skip",    "no value","existing DSSP files will NOT be overwritten";


#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
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
#$fhin="FHIN";$fhout="FHOUT";
$fhoutErr="FHERROR";

$#fileIn=0;
$LisList=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=            $1;}
    elsif ($arg=~/^fileErr=(.*)$/i)       { $fileErr=            $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $par{"dirOut"}=      $1;}

    elsif ($arg=~/^check$/)               { $par{"parDsspCheck"}= 1;}
    elsif ($arg=~/^del\S*$/)              { $par{"parDsspDelete"}=1;
					    $par{"parDsspCheck"}= 1;}
    elsif ($arg=~/^exe.*=(.*)$/i)         { $par{"exeDsspBin"}=  $1;}

    elsif ($arg=~/^skip[A-Za-z]*$/)       { $par{"doNew"}=        0; }
    elsif ($arg=~/^new$/)                 { $par{"doNew"}=        1; }

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=             1;
					    $Lverb=              1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=              1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=              0;}

    elsif ($arg=~/^ARCH=(.*)$/i)          { $ARCH=               $1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}

    elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}

    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    $LisList=        1 if ($arg=~/\.list/);}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn);
$fileErr="DSSP_errors.list"     if (! defined $fileErr);

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" );
    $par{$kwd}.="/"          if ($par{$kwd} !~ /\/$/);}

				# ------------------------------
				# executable
if ($par{"exeDsspBin"}=~/ARCH/){
    $ARCH= $ENV{'ARCH'}         if (! defined $ARCH && defined $ENV{'ARCH'} );
    die ("*** ERROR $scrName: no ARCH variable defined, do either of the following:\n".
	 "> setenv ARCH TO_YOUR_ARCH               \n".
	 "                                         (valid: <SGI64|SGI32|ALPHA|LINUX>)\n".
	 "> $0 ".join(' ',@ARGV)." ARCH=YOUR_ARCH  \n".
	 "                                         (valid: <SGI64|SGI32|ALPHA|LINUX>)\n")
	if (! defined $ARCH || $ARCH !~/^(SGI32|SGI64|ALPHA|SUNMP|LINUX)$/);
    $par{"exeDsspBin"}=~s/ARCH/$ARCH/;}

die ("*** ERROR $scrName: missing executable for DSSP=".$par{"exeDsspBin"}."!\n")
    if (! -e $par{"exeDsspBin"} && ! -l $par{"exeDsspBin"});

				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;

foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
					      exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
	next;}
    push(@fileTmp,$fileIn);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ct=$#fileOut=0;
foreach $fileIn (@fileIn){
    ++$ct;
    if (! -e $fileIn){ print "-*- WARN $scrName: no fileIn=$fileIn\n";
		       next;}
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn)
	if ($Lverb);

				# output file not given
    if    (($#fileIn==1 && ! defined $fileOut) ||
	   $#fileIn > 1){
	$fileOut=$fileIn; 
	$fileOut=~s/^.*\///g;
	$fileOut=~s/\.(pdb|brk).*$//gi;
	$fileOut.=$par{"extDssp"}; }

				# skip existing files
    if (-e $fileOut && ! $par{"doNew"}) {
	push(@fileOut,$fileOut);
	$tmp{$fileOut}=$fileIn;
	next; }

				# ------------------------------
				# run it
    ($Lok,$msg)=
	&dsspRun
	    ($fileIn,$fileOut,$par{"exeDsspBin"},$par{"optNice"}
	     );			&errScrMsg("failed dsspRun on $fileIn->$fileOut",$msg) if (! $Lok);

    push(@fileOut,$fileOut);
    $tmp{$fileOut}=$fileIn;
}
				# ------------------------------
				# check DSSP file
$ctErr=0;
if ($par{"parDsspCheck"}){
    open($fhoutErr,">".$fileErr)    || die("*** ERROR $scrName: failed opening fileOutErr=$fileErr!\n");
    foreach $fileOut (@fileOut){
	next if (! -e $fileOut);
	
	($Lok,$msg,$len)=
	    &dsspCheck
		($fileOut);	&errScrMsg("failed dsspCheck on out=$fileOut",$msg) if (! $Lok);
	
	if (! $len){
	    ++$ctErr;
	    print $fhoutErr $tmp{$fileOut},"\n";}
    }
    close($fhoutErr);
    unlink($fileErr)            if (! $ctErr);}

if ($Lverb){
    print "--- last output in $fileOut\n" if (-e $fileOut);
    print "--- ids of $ctErr files with DSSP problems: $fileErr\n" if (-e $fileErr);
}
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


#===============================================================================
sub dsspRun {
    local($fileInLoc,$fileOutLoc,$exeDsspLoc,$optNiceLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspRun                     run DSSP
#       in:                     $fileInLoc:    PDB input file
#       in:                     $fileOutLoc:   DSSP output file
#       in:                     exeDsspLoc:    DSSP binary
#       in:                     optNiceLoc:    nice value (nice -19)
#       in:                     
#       in:                     
#       out:                    1|0,msg,$Lok=1(if file ok) | 0 (if not)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspRun";
    $fhinLoc="FHIN_"."dsspRun";$fhoutLoc="FHOUT_"."dsspRun";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);
    return(&errSbr("not def exeDsspLoc!"))         if (! defined $exeDsspLoc);
    $optNiceLoc=""                                 if (! defined $optNiceLoc ||
						       $optNiceLoc =~ /nice\S/);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc && 
						       ! -l $fileInLoc );

				# local settings
    $exeDsspDef="/home/rost/molbio/bin/dssp.SGI64";
    $exeDsspLoc=$exeDsspDef     if (! -e $exeDsspLoc && ! -l $exeDsspLoc);

				# ------------------------------
				# missing executable
    return(&errSbr("no exeDsspLoc=$exeDsspLoc!"))       
	if (! -e $exeDsspLoc && ! -l $exeDsspLoc);

    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc);
    $fileOutScreenLoc=
	$par{"fileOutScreen"}   if (! $fileOutScreenLoc && defined $par{"fileOutScreen"});
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);

    $cmd=$optNiceLoc." ".$exeDsspLoc." ".$fileInLoc." ".$fileOutLoc;
    ($Lok,$msg)=
	&sysRunProg($cmd,$fileOutScreenLoc,
		    $FHTRACE);  return(&errSbrMsg("failed on system '$cmd'",$msg)) if (! $Lok);

    return(0,"*** ERROR $sbrName: missing $fileOutLoc (from $fileInLoc)")
	if (! -e $fileOutLoc);

    return(1,"ok $sbrName");
}				# end of dsspRun

#===============================================================================
sub dsspCheck {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspCheck                   check whether or not DSSP ok
#       in:                     $fileInLoc:    DSSP file
#       out:                    1|0,msg,$Lok=1(if file ok) | 0 (if not)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspCheck";
    $fhinLoc="FHIN_"."dsspCheck";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc && 
						       ! -l $fileInLoc );
				# ------------------------------
				# check DSSP file
    $Lok=0;
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);
    $len=0;
    while (<$fhinLoc>) {
	if ($_ =~ /^\s*(\d+).*NUMBER OF RESIDUES/){
	    $len=$1;
	    last; }
    }
    close($fhinLoc);

    return(1,"ok $sbrName",$len);
}				# end of dsspCheck


