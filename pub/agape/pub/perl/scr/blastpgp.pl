#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="runs iterated PSI-BLAST on bigX\n".
    "     \t \n".
    "     \t ";
#  
# default package file
$packDefault=       "/home/rost/perl/scr/pack/blastpgp.pm";

# default settings
$par{"exeBlast"}=   "/home/rost/molbio/bin/blastpgp".".ARCH";
$par{"dbBlast"}=    "/data/blast/bigx_coil_seg";
$par{"argBlast"}=   "-j 3 -e .001 -b 5000 -d";

$par{"optNice"}=    "nice -15";

$par{"extBlastpgp"}=".blastpgp";
$par{"extBlastmat"}=".blastmat";
$par{"extSaf"}=     ".saf";

$ARCH_DEFAULT=      "SGI64";


# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#       Dariusz Przybelski      dudek@cubic.bioc.columbia.edu   	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032						       #
#				version 0.1   	Apr,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one
&helpLocal()                    if ($#ARGV<1 || $ARGV[1]=~/^(-h|help|\?|def)$/i);

				# ------------------------------
				# check command line
$LOCAL=0;
$#tmp=0;
while (@ARGV) { 
    $_= shift @ARGV;
    if    ($_=~/^pack.*=(.*)/) { $pack=   $1; }
    elsif ($_=~/^loca?l?$/i)   { $LOCAL=   1; }
    else                       { push(@tmp,$_); } }
@ARGV=@tmp; 

				# is local run
if ($LOCAL){
    $pack=$0;
    $pack=~s/\.pl/.pm/;}
else {
    $pack=$packDefault;}

				# given on command line?
if (! -e $pack || -d $pack){
    die "*** pack is =".$pack.", but not existing"."\n".
	"*** give 'pack=PATH/blastpgp.pm' as argument on command line, missing ..." ;}

				# ------------------------------
				# read environment variables
				# ------------------------------
$Lok=require "$pack";

die ("*** ERROR $0: failed to require pack=".$pack." at startup\n") 
    if (! $Lok);
				# ------------------------------
				# get input arguments
				# ------------------------------
($Lok,$msg)=
    &ini();
die ("*** ERROR $0: failed to understand command line arguments:".join(',',@ARGV,"\n").$msg."\n")
    if (! $Lok);

				# ------------------------------
				# finally run 'real' script
				# ------------------------------
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileIn,$ctfile,(100*$ctfile/$#fileIn)
	    if ($Lverb);
				# output files
    $id=$fileIn; $id=~s/^.*\/|\..*$//g;
				# BLAST output
    if ($#fileIn ==1 && defined $fileOut && length($fileOut) > 3){
	$fileOutBlast=$fileOut;}
    else {
	$fileOutBlast=$dirOut.$id.$par{"extBlastpgp"}; }
				# BLAST matrix
    if ($#fileIn ==1 && defined $fileOutMat && length($fileOutMat) > 3){
	$fileOutMat=$fileOutMat;}
    else {
	$fileOutMat=$dirOut.$id.$par{"extBlastmat"}; }
				# BLAST -> SAF

    if ($#fileIn ==1 && defined $fileOutSaf && length($fileOutSaf) > 3){
	$fileOutSaf=$fileOutSaf; }
    else {
	$fileOutSaf=$dirOut.$id.$par{"extSaf"}; }

    ($Lok,$msg)=
	&blastp::blastit($fileIn,$par{"exeBlast"},$par{"dbBlast"},$par{"argBlast"},
			 $fileOutBlast,$fileOutMat,$fileOutSaf,$dirWork,$dirOut,$par{"optNice"}); 

    print "*** package ($pack) returned ERROR:\n".$msg."\n" if (! $Lok);
}

exit;


#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         initialise variables, get input files
#-------------------------------------------------------------------------------

    $LisList=0;
    $#fileIn=0;
    $dirOut= "";
    $dirWork="";
    $fileOutMat=$fileOutSaf=0;
				# ------------------------------
				# read command line
    foreach $arg (@ARGV){
#	next if ($arg eq $ARGV[1]);
	if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
	elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
						$dirOut.=        "/" if ($dirOut !~/\/$/);}
	elsif ($arg=~/^(work|dirWork)=(.*)$/i){ $dirWork=        $2; 
						$dirWork.=       "/" if ($dirWork !~/\/$/);}

	elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
						$Lverb=          1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

	elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}

	elsif ($arg=~/^exe.*=(.*)$/)          { $par{"exeBlast"}=$1;}
	elsif ($arg=~/^db.*=(.*)$/)           { $par{"dbBlast"}= $1;}

	elsif ($arg=~/^saf=(.*)$/)            { $fileOutSaf=     $1;}
	elsif ($arg=~/^saf$/)                 { $fileOutSaf=     1;}
	elsif ($arg=~/^mat=(.*)$/)            { $fileOutMat=     $1;}
	elsif ($arg=~/^mat$/)                 { $fileOutMat=     1;}

	elsif ($arg=~/^(arg|argBlast)=(.*)$/i){ $par{"argBlast"}=$2;}

	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}="nice -".$1;}
	elsif ($arg eq "nonice")              { $par{"optNice"}=" ";}

	elsif ($arg=~/^ARCH=(.*)$/i)          { $ARCH=           $1;}

#	elsif ($arg=~/^=(.*)$/){ $=$1;}

	elsif (-e $arg)                       { push(@fileIn,$arg); 
						$LisList=        1 if ($arg=~/\.list/);}
	else {
	    print "*** wrong command line arg '$arg'\n";
	    exit;}}

    $Lverb=1                    if ($Ldebug);

    $fileIn=$fileIn[1];
    die ("missing input $fileIn\n") if (! -e $fileIn);

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
    $#fileTmp=0;		# slim-is-in


				# --------------------------------------------------
				# setenv ARCH 
				# --------------------------------------------------
                                # given in local env ?
    $ARCH= $ARCH || $ENV{'ARCH'} || $ARCH_DEFAULT || 'unk';
    $par{"exeBlast"}=~s/ARCH/$ARCH/
	if ($par{"exeBlast"}=~/ARCH/);
	

				# ------------------------------
				# priority
    if (defined $par{"optNice"} && $par{"optNice"} ne " " && length($par{"optNice"})>0){
	$niceNum="";
	if    ($par{"optNice"}=~/nice\s*-/){
	    $par{"optNice"}=~s/nice-/nice -/;
	    $niceNum=$par{"optNice"};$niceNum=~s/\s|nice|\-|\+//g; }
	elsif ($par{"optNice"}=~/^\d+$/){
	    $niceNum=$par{"optNice"};}
	$niceNum=~s/\D//g;
	setpriority(0,0,$niceNum) if (length($niceNum)>0); }

    return(1,"ok");		# end of ini
}

 
#===============================================================================
sub helpBlast{
    $btex= "some of the PSI-BLAST options\n";
    $btex.="  -i  Query File [File In]\n";
    $btex.="      The query should be in FASTA format.  If multiple FASTA entries\n";
    $btex.="      are in the input file, all queries will be searched.\n";
    $btex.="  -e  Expectation value (E) [Real]\n";
    $btex.="      default = 10.0\n";
    $btex.="  -d  databese address\n";
    $btex.="  -o  BLAST report Output File [File Out]  Optional\n";
    $btex.="      default = stdout\n";
    $btex.="  -b  number of aligned sequences to be included in the output file\n";
    $btex.="  -j  is the maximum number of rounds (default 1; i.e., regular BLAST)\n";
    $btex.="  -Q  Output File for PSI-BLAST Matrix in ASCII [File Out]  Optional\n";
    $btex.="  -C  stores the query and frequency count ratio matrix in a file \n";
    $btex.="  -R  restarts from a file stored previously.\n";
    $btex.="  -B flag provides a way to jump start PSI-BLAST from a master-slave\n";
    $btex.="   multiple alignment computed outside PSI-BLAST.\n";
    $btex.="  -F  Filter query sequence (DUST with blastn, SEG with others) [T/F]\n";
    $btex.="    default = T\n";

    print $btex;
}				# end of helpBlast

#===============================================================================
sub helpLocal {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   helpLocal                       
#-------------------------------------------------------------------------------


    if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName file.fasta (*.fast|fasta.list) '\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s=%-20s %-s\n","","local",   "x",     "will do local run";
	printf "%5s %-15s %-20s %-s\n","","",        "",      "assuming all libs asf in local dir";
	printf "%5s %-15s=%-20s %-s\n","","pack",    "blastpgp.pm", "package for this";

	printf "%5s %-15s=%-20s %-s\n","","exe",     "blast.X", "blast executable (def=",$par{"exeBlast"},")";
	printf "%5s %-15s=%-20s %-s\n","","db",      "bigX",    "blast database (def=",$par{"dbBlast"},")";

	printf "%5s %-15s=%-20s %-s\n","","work|dirWork","pwd", "working directory (def=local)";

	printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
	printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "(path concatenated to Blast output files, def: local)";
	printf "%5s %-15s=%-20s %-s\n","","dirWork", "x",       "working directory (def: local)";

	printf "%5s %-15s=%-20s %-s\n","","mat",     "x",       "either just 'mat' -> will write BLAST mat";
	printf "%5s %-15s %-20s %-s\n","","",        "",        "or full name of matrix file";

	printf "%5s %-15s=%-20s %-s\n","","saf",     "x",       "either just 'saf' -> will do conversion";
	printf "%5s %-15s %-20s %-s\n","","",        "",        "or full name of SAF file";

	printf "%5s %-15s %-20s %-s\n","","nonice",  "no value","no nice level when running";
	printf "%5s %-15s %-20s %-s\n","","nice-N",  "no value","nice level when running";

#	printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#	printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#	printf "%5s %-15s %-20s %-s\n","","",   "no value","";

	printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
	printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
	printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

	&helpBlast();

	exit;
    }
}				# end of helpLocal

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


