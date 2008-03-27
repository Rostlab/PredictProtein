#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="run evaluation of secondary structure prediction accuracy (old)\n";
#

#------------------------------------------------------------------------------#
#	Copyright		Nov		        	1993	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.2   	Mar,    	1994	       #
#				version 0.3   	Aug,    	1994	       #
#				version 0.4   	Sep,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'exeFor',        "/home/rost/pub/bin/xevalsec_98_07.ARCH",
      'exeFor',        "/home/rost/pub/bin/xevalsec.ARCH",
      'exeFor',        "/home/rost/pub/bin/evalsec.SGI64",
      'exeAveRi',      "/home/rost/perl/col/my/get-avRelSec-phdPred.pl",
      'fileOutTrace',  "EVALSEC-TRACE.tmp",
      'debug',         0,
      '', "",
      );
@kwd=sort (keys %par);
$ARCH= $ENV{'ARCH'}  || `which_arch.sh` ;


$LdoRelAve=       1;		# compile averages of rel index

$numfilesread=  1;
$LexclChain=      "N";		# excluding protein chains from analysis ?
$LrdPredGrep=     "N";		# assume len=80 does not give an empty section
$LrdRel=          "Y";		# reading reliability index?
$LisRel=          1;
$LfromPdbCompare= "N";		# assuming pdb comparions
$LconvDssp=       "Y";		# convert DSSP
$LoldVersion=     "N";		# assuming old files = 80 produces empty

				# ------------------------------
				# further defaults
$devnom=          50;
$numAvRel=         1;		# number of residues to be excluded for averaging rel
$LtabPo=          "N";		
$LtabSeg=         "N";		
$LtabQils=        "Y";		
$LwrtGraph=       "Y";		# write length distribution

$command="";			# avoid warning
$fhTrace=    "FHTRACE";
$fhTrace=    "STDOUT";



				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName <file.pred|*.pred|many_pred.list>'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";

    printf "%5s %-15s %-20s %-s\n","","noAve",    "no value","do NOT compile RI averages";
    printf "%5s %-15s %-20s %-s\n","","do_excl",   "no value","exclude proteins (old 126 only)";
    printf "%5s %-15s %-20s %-s\n","","is_phdgrep","no value","file from old(sic) program secstron";
    printf "%40s   %-s\n"," ","reason: use pred file with fault: 80 + empty -> not_phdgrep",
    printf "%5s %-15s %-20s %-s\n","","not_secstr","no value","no secondary structure read";
    printf "%5s %-15s %-20s %-s\n","","not_rel",   "no value","no reliability index";
    printf "%5s %-15s %-20s %-s\n","","not_conv",  "no value","no conversion of DSSP";
    printf "%5s %-15s %-20s %-s\n","","is_pdb",    "no value","is from PDB comparison";
    printf "%5s %-15s %-20s %-s\n","","is_old",    "no value","assumes old version, i.e. 80 = 1 empty";
    printf "%5s %-15s=%-20s %-s\n","","exeAve",    "x",       "perl script to compile ave RI";
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
$fhin="FHIN";$fhout="FHOUT";
$LisList=0;
$#fileIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1; }
    elsif ($arg=~/^no_?[aA]ve?$/i)        { $LdoRelAve=      0; }
    elsif ($arg=~/^do_excl$/i)            { $LexclChain=     "Y"; }
    elsif ($arg=~/^(is_phdgr|is_grep)$/i) { $LrdPredGrep=    "Y"; }
    elsif ($arg=~/^not_rel$/i)            { $LrdRel=         "N";
					    $LisRel=         0; }
    elsif ($arg=~/^not_conv$/i)           { $LconvDssp=      "N"; }
    elsif ($arg=~/^is_old$/i)             { $LoldVersion=    "Y"; }
    elsif ($arg=~/^is_pdb$/i)             { $LfromPdbCompare="Y";
					    $LrdRel=         "N"; }
    elsif ($arg=~/^ARCH=(.*)$/i)          { $ARCH=           $1;}
#    elsif ($arg=~/^$/i){ }

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
				# binary executable automatically detected
    elsif (-x $arg && -b $arg)            { $par{"exeFor"}=  $1;}
    elsif ($arg=~/^list$/i)               { $LisList=        1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    # automatic detection of list
					    $LisList=        1 if ($arg =~ /\.list/); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					   last; }}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
				# executables
$par{"exeFor"}=~s/ARCH/$ARCH/ if ($par{"exeFor"}=~/ARCH/);

foreach $kwd ("exeFor","exeAveRi") {
    &errScrMsg("no executable $kwd=".$par{"$kwd"}) if (! -e $par{$kwd}); }

				# ??????????????????????????????
if (0){				# ??? 98-07
    if ($evalsec_exe=~/Len/){	# new exe (1.98)
	$arg= "$numfilesread,$title,$devnom,$LexclChain,$LconvDssp,$LrdPredGrep,";
	$arg.="$LrdRel,$LoldVersion,$LtabPo,$LtabSeg,$LtabQils,$LfromPdbCompare,$numAvRel,$LwrtGraph";
	eval "\$command=\"$evalsec_exe,$arg\""; }
    else {
	$arg= "$numfilesread,$title,$devnom,$LexclChain,$LconvDssp,$LrdPredGrep,";
	$arg.="$LrdRel,$LoldVersion,$LtabPo,$LtabSeg,$LtabQils,$LfromPdbCompare";
	eval "\$command=\"$evalsec_exe,$arg\""; }
}
				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}


                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
    length($par{"fileOutTrace"}) > 0 &&
    $fhTrace ne "STDOUT" &&
    ! $par{"debug"}) {
    print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n";
    open($fhTrace,">".$par{"fileOutTrace"}) || 
	return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$scrName));}
else {
    $par{"fileOutTrace"}=0;
    $fhTrace="STDOUT";}

				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ($fileIn !~ /\.list/) {
	push(@fileTmp,$fileIn);
	next;}
    ($Lok,$msg,$file,$tmp)=
	&fileListRd($fileIn);   if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
					     exit; }

    @tmpf=split(/,/,$file); 
    push(@fileTmp,@tmpf);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ct=0;
$Lis_ppcol=0;
foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn);
				# ------------------------------
				# is from PP-server (PP column)?
				# ------------------------------
    if (&is_ppcol($fileIn)){
	$Lis_ppcol=1;
	$file_dotpred=$fileIn;
	$file_dotpred=~s/\.(.+)/_ppcol2dot.pred/;
				# convert to required input format
	($Lok,$LisRel)= 
	    &ppcol_2_dotpred($fileIn,$file_dotpred);
	if (! $Lok) { &errScrMsg("output from ppcol_2_dotpred ($fileIn,$file_dotpred)");
		      exit;}

	if ($LisRel) { $file_tmp=$file_dotpred."rel";
		       system"\\mv $file_dotpred $file_tmp";
		       $file_dotpred=$file_tmp;}
	print "--- $scrName: CHANGE $fileIn -> $file_dotpred !!!\n" x 3;
	$fileInTmp=$file_dotpred; }
				# ------------------------------
				# is normal: also change extension!
    else {			# ------------------------------
	if ($LisRel && $fileIn =~/pred$/) {
	    $fileInTmp=$fileIn."rel";
	    $cmd="\\cp $fileIn $fileInTmp";
	    print "--- $scrName: system \t '$cmd'\n";
	    system("$cmd"); }
	else {
	    $fileInTmp=$fileIn;}}
				# ----------------------------------------
				# execute fortran program xevalsec
				# ----------------------------------------
    $title=$fileInTmp; $title=~s/^.*\/|\.pred.*$//g;

    $arg= "$numfilesread,$title,$devnom,$LexclChain,$LconvDssp,$LrdPredGrep,";
    $arg.="$LrdRel,$LoldVersion,$LtabPo,$LtabSeg,$LtabQils,";
    $arg.="$LfromPdbCompare,$numAvRel,$LwrtGraph";
    $evalsec_exe=$par{"exeFor"};
    eval "\$command=\"$evalsec_exe,$arg\""; 
#    print "xx \n$command\n";die;

    ($Lok,$msg)=
	&sysRunProg($command ,$par{"fileOutTrace"},$fhTrace);
    &errScrMsg("failed running ".$par{"exeFor"},$msg) if (! $Lok);

				# ----------------------------------------
				# now write new if PPcol
				# ----------------------------------------
    if ($Lis_ppcol){
	print "xx trying to read it!\n";
	$file_table="Tableqils-".$title;
	&evalsec_rd_tableqils($file_table,$file_out); }
    elsif ($LdoRelAve) {
	print "--- compile average RI \n";
	$arg=$par{"exeAveRi"}." $fileInTmp";
	print "--- system \t '$arg'\n";
	system("$arg"); }
    unlink($fileInTmp)          if ($fileInTmp ne $fileIn);
}

close($fhTrace)                 if ($par{"fileOutTrace"} && $fhTrace ne "STDOUT");
print "--- $scrName ended fine\n";
print "---   trace file: ",$par{"fileOutTrace"},"\n" if ($par{"fileOutTrace"});
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
sub is_ppcol {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_ppcol                    checks whether or not file is in RDB format
#       in:                     $file
#       out:                    1 if is ppcol, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$_=~tr/[A-Z]/[a-z]/;
		     if (/^\# pp.*col/) {$Lis=1;}else{$Lis=0;}last; }
    close($fh);
    return $Lis;
}				# end of is_ppcol

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

exit;

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
    $sbrName="lib-ut:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if    ($fhErrLoc && ! @arg) {
	print $fhErrLoc "-*- WARN $sbrName: no arguments to pipe into:\n$prog\n";
    }
    elsif ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system cmd=\n$prog\n--- $sbrName: fileOut=$fileScrLoc cmd IN:\n$cmd\n";}
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
sub ppcol_2_dotpred {
    local ($fileIn,$file_out) = @_ ;
    local (@des,%rd,$Lfalse_sec,$Lfalse_obs,$name,$ct,$LisRel,$des,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppcol_2_dotpred            converts the input from PP (column format) into
#                               the format required for evalsec
#--------------------------------------------------------------------------------
				# ------------------------------
				# defaults and ini
				# ------------------------------
    @des=("NAME","AA","SEC","OBS","RI");
				# ------------------------------
				# read PP-column format
				# ------------------------------
    %rd= &ppcol_rd($fileIn,@des);

				# ------------------------------
				# error check
				# ------------------------------
    foreach $name (@NAME) {
	$ct=1;$Lfalse_sec=$Lfalse_obs=0;
	while (defined $rd{"$name","NAME","$ct"}){
	    $Lfalse_sec=1 if ($rd{"$name","SEC","$ct"}=~/[^HEL \.]/);
	    $Lfalse_obs=1 if ($rd{"$name","OBS","$ct"}=~/[^HEL \.]/);
	    last if ($Lfalse_sec && $Lfalse_obs);
	    ++$ct; }
	if ($Lfalse_sec){
	    print "*** extract_seq: COLUMN format: wrong predicted secondary structure, \n";
	    print "***              allowed are: H,E,L\n"; }
	if ($Lfalse_obs){
	    print "*** extract_seq: COLUMN format: wrong observed secondary structure, \n";
	    print "***              allowed are: H,E,L\n"; }
    }
				# ------------------------------
				# is RI?
				# ------------------------------
    $LisRel=0;
    foreach $des (@DESRD){
	if ($des=~/RI/){
	    $LisRel=1;
	    last;}}

				# --------------------------------------------------
				# write file in dotpred format for evalsec
				# --------------------------------------------------
    if ((! $Lfalse_sec)&&(! $Lfalse_obs)){
	&dotpred_wrt($file_out,%rd);
	$Lok=1;
    } else { $Lok=0;}
    return($Lok,$LisRel);
}				# end of ppcol_2_dotpred

#===============================================================================
sub ppcol_rd {
    local ($fileIn,@des) = @_ ;
    local ($fhin,$ct,%seq,%sec,%ri,%obs,%name,$Lis_name,$Lfst,@tmp,$tmp,$des,
	   $Lok,$it,%ptr,$ctprot,$ctres,$name,$ptr);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppcol_rd                   read the PP column format
#       in:                     $fileIn,@des
#       out:                    %rd (returned)
#                               @name,@desloc (global)
#--------------------------------------------------------------------------------
    $fhin="FHIN_PPCOL";

    $ct=0;			# initialise arrays asf
    undef %seq; undef %sec; undef %ri; undef %obs; undef %name; undef %ptr;
    $#DESRD=$Lis_name=0;
    $Lfst=1;
				# ------------------------------
				# read file
				# ------------------------------
    open($fhin,"$fileIn")  || die "Can not open '$fileIn' (ppcol_rd) $!\n";
    while ( <$fhin> ) {
	$_=~tr/[a-z]/[A-Z]/;	# upper caps
	$_=~s/\n//g;		# purge newline
	$_=~s/^[ ,\t]*|[ ,\t]*$//g; # purge leading blanks, tabs, commata
	if ( (length($_)<1)|| ($_=~/^\#/) ) {
	    next;}
	if ($Lfst){		# how many columns, and which?
	    $Lfst=$#tmp=0;
	    @tmp=split(/[\s\t,]+/,$_);
	    foreach $des (@des){
		$Lok=0;
		foreach $it (1..$#tmp) {
		    if ($tmp[$it]=~/$des/) { 
			$Lok=1; $ptr{"$des"}=$it; push(@DESRD,$des); }
		    last if ($Lok); }}
	    foreach $des (@DESRD){
		if ($des =~ /NAME/) { $Lis_name=1; last; }} }
	else {		# expected to be sequence info now!
	    ++$ct; 
	    $#tmp=0;@tmp=split(/[\s\t,]+/,$_); # split spaces, tabs, or commata
	    if ($ct==1){	# get name
		$ctprot=1;$ctres=0;
		if ($Lis_name){$ptr=$ptr{"NAME"};$name=$tmp[$ptr]; }
		else {$name="name1";} 
		push(@NAME,$name); }
	    elsif ($Lis_name){ # new protein?
		$ptr=$ptr{"NAME"};$tmp=$tmp[$ptr]; 
		if ($tmp ne $name){
		    ++$ctprot;$ctres=0;
		    $name=$tmp;push(@NAME,$name); }}
	    ++$ctres;
	    foreach $des (@DESRD) {
		$ptr=$ptr{"$des"};
		$rd{"$name","$des","$ctres"}=$tmp[$ptr];
	    }
	}
    }
    close($fhin);
				# ------------------------------
				# save memory
    undef %seq; undef %sec; undef %ri; undef %obs; undef %name; undef %ptr;
    $#tmp=0;			# slim-is-in !
    return(%rd);
}				# end of ppcol_rd

#===============================================================================
sub dotpred_wrt {
    local ($fileIn,%rd) = @_ ;
    local ($fhout,$name,$ct,$aa,$sec,$obs,$ri);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    dotpred_wrt                write dotpred format (for evalsec)
#    in:                        $file_out, %rd{}
#                 GLOBAL        @NAME,@DESRD
#--------------------------------------------------------------------------------
    $fhout="DOTPRED_OUT";
    if ($fhout !~ /STDOUT/){
	open($fhout,">$file_out")  || die "Ca not open '$file_out' (dotpred_wrt) $!\n";
    }
    print  $fhout "# PHD DOTPRED 8.95 \n";
    printf $fhout "num %4d \n", $#NAME;
    undef %Lok;
    foreach $des (@DESRD){$Lok{"$des"}=1;}

    foreach $name (@NAME) {
	$ct=1;$aa=$sec=$obs=$ri="";
	while (defined $rd{"$name","NAME","$ct"}){
	    foreach $des (@DESRD){
		if   ($des=~/AA/  && defined $Lok{"$des"}) { $aa.= $rd{"$name","$des","$ct"};}
		elsif($des=~/SEC/ && defined $Lok{"$des"}) { $sec.=$rd{"$name","$des","$ct"};}
		elsif($des=~/OBS/ && defined $Lok{"$des"}) { $obs.=$rd{"$name","$des","$ct"};}
		elsif($des=~/RI/  && defined $Lok{"$des"}) { $ri.= $rd{"$name","$des","$ct"};}
		elsif($des=~/NAME/&& defined $Lok{"$des"}) { $name=$rd{"$name","$des","$ct"};}
	    }
	    ++$ct;
	}
				# correction
	if (! defined $Lok{"AA"}){
	    foreach $it (1..length($sec)){$aa.="U";}}
	
	printf $fhout "\# 1 %10d %-s\n",length($aa),$name;
				  
	if (! defined $Lok{"RI"}){
	    &write80_data_prepdata($aa,$obs,$sec);
	    &write80_data_preptext("AA ","Obs","Prd");  }
	else {
	    &write80_data_prepdata($aa,$obs,$sec,$ri);
	    &write80_data_preptext("AA ","Obs","Prd","Rel");  }
	&write80_data_do("$fhout");
    }
    print $fhout "END\n";
    close($fhout)               if ($fhout ne "STDOUT");
}				# end of dotpred_wrt

#===============================================================================
sub evalsec_rd_tableqils {
    local ($fileIn,$file_out) = @_ ;
    local ($fhin,$fhout,@des_sec,$des,$des1,$des2,$name,$len,$ctprot,$ctline,$ctfin,
	   $Lok,$Lend,$Lfin,$Lextra,$tmp,@tmp,$num_res,$bad,$under,$over,);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils       first reads, then writes content of Tableqils
#                               as generated by evalsec
#       in:          GLOBAL     @NAME, %rd
#--------------------------------------------------------------------------------
    $fhin="FHIN_TABLEQILS";
    $fhout="FHOUT_TABLEQILS";
    @des_sec=("H","E","L");	# secondary structure symbols
				# key-words for averages at end of file
    @des_sec2=("H","E");

    push(@NAME,"Average over all residues") if ($#NAME > 1);
				# --------------------------------------------------
				# read and write file
				# --------------------------------------------------
    open($fhin,"$fileIn")   || die "Ca not open '$fileIn' (evalsec_rd_tableqils) $!\n";
    open($fhout,">$file_out")|| die "Ca not open out: '$file_out' (evalsec_rd_tableqils) $!\n";

    $ctprot=$ctfin=$Lok=$Lend=$Lfin=0;
    while(<$fhin>){
	$_=~s/\n//g;
	$tmp=$_;$tmp=~s/\s//g;
	if (length($tmp)<1){$Lok=0;
			    next;}
	if (!$Lok && $_=~/^ \+\-/ && !$Lfin && !$Lend){
	    $Lok=1;
	    if ( ($ctprot>0)&&($ctprot<=$#NAME) ) {
				# ------------------------------
				# write
				# ------------------------------
				# compute sums
		$num_res=$rd{"num","Sprd","Sobs"};

		$bad=0;		# bad predictions H->E, E->H
		foreach $des1 ("H","E"){foreach $des2 ("H","E"){
		    if ($des1 !~ $des2) { $bad+=$rd{"num","$des1","$des2"}; }}}
		$under=0;	# under predictions H->L, E->L
		foreach $des1 ("H","E"){$under+=$rd{"num","$des1","L"};}
		$over=0;	# over predictions L->H, E->H
		foreach $des2 ("H","E"){$over+=$rd{"num","L","$des2"};}
		if ($num_res != 0) { 
		    $rd{"bad"}=  100*($bad/$num_res);
		    $rd{"under"}=100*($under/$num_res);
		    $rd{"over"}= 100*($over/$num_res); }
		else{
		    $rd{"bad"}=$rd{"under"}=$rd{"over"}=0;}
		
		$Lextra=1;
		print  $fhout "# \n# ","*" x (length($NAME[$ctprot])+24),"\n";
		printf $fhout "# Prediction accuracy for %-40s\n",$NAME[$ctprot];
		print  $fhout "# ","*" x (length($NAME[$ctprot])+24),"\n";
			
		if ($ctprot==$#NAME) {$tmp="ALL";}
		else                 {$tmp="$ctprot";}
		    
		&evalsec_wrt_num($fhout,$Lextra,@des_sec);
		&evalsec_wrt_state($fhout,$Lextra,@des_sec);
		&evalsec_wrt_tot($fhout,$Lextra,@des_sec);
	    }			# end of writing
				# ------------------------------
	    if ($ctprot==$#NAME) {
		$Lok=0;$Lend=1; }
	    $ctline=0;
	    ++$ctprot;}
	if ($Lok){
	    ++$ctline;
	    if ($ctline==2){
		$name=$NAME[$ctprot];
		$len= substr($_,12,5);$len=~s/\s//g;}
	    elsif ( $ctline >= 8  &&  $ctline <= 10 ) {
		$_=~s/\s//g;	# purging blanks
		$_=~s/^\|+|\|+$//g; # purging and "| .... |"
		$#tmp=0;@tmp=split(/\|/,$_);
		
		$des1=$tmp[1];$des1=~s/DSSP//;$des1=~s/C/L/;
				# reading numbers for H, E, O
		&evalsec_rd_tableqils_1st($des1,$_,@des_sec);
		&evalsec_rd_tableqils_2nd($des1,$_,@des_sec); }
	    elsif ($ctline==12) {
		$_=~s/\s//g;	# purging blanks
		$_=~s/^\||\|$//g; # purging and "| .... |"
				# reading sums of numbers for H, E, O
		$des1="Sprd";
		&evalsec_rd_tableqils_1st($des1,$_,@des_sec);}
	    elsif ($ctline==13) { # correlation, Q3
		$_=~s/\s//g;	# purging blanks
		$_=~s/^\|+|\|+$//g;	# purging and "| .... |"
		&evalsec_rd_tableqils_3rd($_,@des_sec);}
	    elsif ($ctline==19){ # SOV, entropy
		$_=~s/\s//g;	# purging blanks
		$_=~s/^\||\|$//g; # purging and "| .... |"
		&evalsec_rd_tableqils_4th($_,@des_sec);
	    }
	}			# end of reading per protein stuff
				# ------------------------------
	if ($Lend){		# now read averages over all proteins
	    if ($#NAME>1){
		if ($_=~/Q3mean =/){            
		    $_=~s/[\s\-\|]|Q3mean.*=//g;
		    $rd{"q3ave"}=$_;}
		elsif ($_=~/sqrt\( Q3var \) =/){
		    $_=~s/[\s\-\|]|sqrt.*\(Q3var.*\).*=//g;
		    $rd{"q3var"}=$_; } }
	    if ($_=~/all sets: contav /){
		$_=~s/[\s\-\|]|all sets: contav//g;
		foreach $des(@des_sec2){
		    if ($_=~/$des.*=/) {
			$_=~s/^.*$des=//g;
			$tmp1=$_;$tmp1=~s/(\d+\.\d+).+/$1/g;
			$tmp2=$_;$tmp1=~s/sqrt \(var\).*=(\d+\.\d+).+/$1/g;
			$rd{"contave","$des"}=$tmp1;
			$rd{"contvar","$des"}=$tmp2;} }}
	    if ($_=~/Sorting into structure class according to paper of Zhang Chou/){
		$Lfin=1; $ctfin=0; $Lend=0;}
	}			# end of reading overall averages
				# ------------------------------
	if ($Lfin){		# read class prediction
	    $_=~s/^ ---\s+//g; 
	    $_=~s/rest /other/;
	    $_=~s/DSSP/ obs/; 
	    $_=~s/\%DSSP/\%obs /; 
	    $_=~s/PRED/ prd/; 
	    $_=~s/\%PRED/\%prd /;
	    if ($_=~/^[\+\|]/){
		++$ctfin;
		$rd{"class","$ctfin"}=$_; }}
    }
    close($fhin);
				# ----------------------------------------
				# finally writing averages and class stuff
				# ----------------------------------------
    if ($#NAME>1){
	$tmp=$#NAME-1;
	&evalsec_wrt_ave($fhout,$tmp,$rd{"q3ave"},$rd{"q3ave"}); }
    &evalsec_wrt_class($fhout,@des_sec2); 
    print $fhout "END\n";
    close($fhout);
    
}				# end of evalsec_rd_tableqils

#===============================================================================
sub evalsec_rd_tableqils_1st {
    local ($des1,$line,@des_sec)= @_ ;
    local ($ct,$it,$des2,@tmp);
    $[=1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils_1st   read line:
# |        |net H |net E |net C |sum DS|
# | DSSP H |    8 |    0 |    2 |   10 |
#--------------------------------------------------------------------------------
    $#tmp=0;@tmp=split(/\|/,$line);
				# numbers
    foreach $it (1..$#des_sec) {$des2=$des_sec[$it];
				$rd{"num","$des1","$des2"}=$tmp[$it+1]; }
				# reading sum of numbers
    $ct=$#des_sec+2;$des2="Sobs";$rd{"num","$des1","$des2"}=$tmp[$ct];
}				# end of evalsec_rd_tableqils_1st

#===============================================================================
sub evalsec_rd_tableqils_2nd {
    local ($des1,$line,@des_sec) = @_ ;
    local ($ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils_2nd   read line:
#   H  |  E  |  C  | H | E | C |DSSP| Net|DSSP| Net|
#  80.0|  0.0| 20.0|100|  0| 28|   2|   2| 5.0| 4.0|
#--------------------------------------------------------------------------------
    $ct=$#des_sec+2;
				# percentage of observed
    foreach $it (1..$#des_sec) {++$ct;$des2=$des_sec[$it];
				$rd{"qobs","$des1","$des2"}=$tmp[$ct]; }
				# percentage of predicted
    foreach $it (1..$#des_sec) {++$ct;$des2=$des_sec[$it];
				$rd{"qprd","$des1","$des2"}=$tmp[$ct]; }
				# segment: obs numb, prd num, obs av, prd av
    ++$ct;$des2="nsegobs";  $rd{"seg","$des1","$des2"}=$tmp[$ct];
    ++$ct;$des2="nsegprd";  $rd{"seg","$des1","$des2"}=$tmp[$ct];
    ++$ct;$des2="nsegavobs";$rd{"seg","$des1","$des2"}=$tmp[$ct];
    ++$ct;$des2="nsegavprd";$rd{"seg","$des1","$des2"}=$tmp[$ct];
}				# end of evalsec_rd_tableqils_2nd

#===============================================================================
sub evalsec_rd_tableqils_3rd {
    local ($line,@des_sec) = @_ ;
    local ($ct,$it,$des2,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils_3rd   read line:
#--------------------------------------------------------------------------------
    $#tmp=0;@tmp=split(/\|+/,$line);
				# correlation
    foreach $it (1..$#des_sec) {$des2=$des_sec[$it];
				$rd{"cor","$des2"}=$tmp[$it]; }
				# Q3
    $rd{"q3"}=$tmp[$#des_sec+1];
}				# end of evalsec_rd_tableqils_3rd

#===============================================================================
sub evalsec_rd_tableqils_4th {
    local ($line,@des_sec) = @_ ;
    local ($ct,$it,$des2,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_rd_tableqils_4th   read line:
#--------------------------------------------------------------------------------
    $#tmp=0;@tmp=split(/\|+/,$line);
    $ct=1;
				# SOV %obs
    foreach $it (1..$#des_sec) {++$ct;$des2=$des_sec[$it]."obs";
				$rd{"sov","$des2"}=$tmp[$ct]; }
    ++$ct;$des2="Sobs";$rd{"sov","$des2"}=$tmp[$ct]; 
				# SOV %prd
    foreach $it (1..$#des_sec) {++$ct;$des2=$des_sec[$it]."prd";
				$rd{"sov","$des2"}=$tmp[$ct]; }
    ++$ct;$des2="Sprd";$rd{"sov","$des2"}=$tmp[$ct]; 
				# entropy
    ++$ct;$des2="obs";$rd{"entropy","$des2"}=$tmp[$ct]; 
    ++$ct;$des2="Pobs";$rd{"entropy","$des2"}=$tmp[$ct]; 
    ++$ct;$des2="prd";$rd{"entropy","$des2"}=$tmp[$ct]; 
    ++$ct;$des2="Pprd";$rd{"entropy","$des2"}=$tmp[$ct]; 
}				# end of evalsec_rd_tableqils_4th

#===============================================================================
sub evalsec_wrt_num {
    local ($fh,$Lextra,@des_sec) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_num            writes numbers (Aij)
#--------------------------------------------------------------------------------

    print  $fh "# \n# A(i,j): number of residues observed in state i, predicted in j:\n# \n";
    &evalsec_wrt_num_extra($fh,$#des_sec) if ($Lextra);
				# 1. row: symbols
    printf $fh "DAT | NUMBERS |";
    foreach $des1 (@des_sec){printf $fh "  %3s  %1s |","prd",$des1;}
    print $fh " obs Sum | \n";

    &evalsec_wrt_num_extra($fh,$#des_sec) if ($Lextra);
    
    foreach $des1 (@des_sec,"Sprd"){ # 2.-5. row: numbers
	if ($des1 =~ /Sprd/) {
	    &evalsec_wrt_num_extra($fh,$#des_sec) if ($Lextra);
	    print  $fh "DAT | prd Sum |";}
	else                 {
	    printf $fh "DAT |  obs  %1s |",$des1;}
	
	foreach $des2 (@des_sec,"Sobs"){
	    printf $fh " %7d |",$rd{"num","$des1","$des2"}; }
	print $fh "\n";
    }
    &evalsec_wrt_num_extra($fh,$#des_sec) if ($Lextra);
}				# end of evalsec_wrt_num

#===============================================================================
sub evalsec_wrt_num_extra {
    local ($fh,$num_sec) = @_ ;
    local ($it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_num_extra      writes line: +--------+ ...
#--------------------------------------------------------------------------------
    print $fh "DAT +---------+";
    foreach $it (1..($num_sec+1)) {
	print $fh "---------+";
    }
    print $fh "\n";
}				# end of evalsec_wrt_num_extra

#===============================================================================
sub evalsec_wrt_state {
    local ($fh,$Lextra,@des_sec) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_state            writes numbers (Aij)
#--------------------------------------------------------------------------------
    print  $fh "# \n# Per-residue and Per-segment scores:\n# \n";
    print $fh "DAT +---------------------------------+ +---------------------------------------+\n";
    print $fh "DAT |        Per-residue scores       | |           Per-segment scores          |\n";
    print $fh "DAT +---------+-------+-------+-------+ +---------+---------+---------+---------+\n";
    print $fh "DAT | SCORES  |Q(i)obs|Q(i)prd| COR(i)| |SOV(i)obs|SOV(i)prd|avL(i)obs|avL(i)prd|\n";
    &evalsec_wrt_state_extra($fh,$#des_sec) if ($Lextra);

    foreach $des1 (@des_sec){
				# per-residue
	printf $fh "DAT | i =  %1s  |",$des1;
	printf $fh "%6d |",int($rd{"qobs","$des1","$des1"}); # Qi %obs
	printf $fh "%6d |",int($rd{"qprd","$des1","$des1"}); # Qi %prd
	printf $fh "%6.2f |",$rd{"cor","$des1"};	# correlation
				# per-segment
	print $fh  " |";
	foreach $des2("obs","prd"){
	    $des_tmp=$des1.$des2;
	    printf $fh " %7.1f |",$rd{"sov","$des_tmp"}; 
	}
	foreach $des2 ("nsegavobs","nsegavprd"){
	    printf $fh "  %6.1f |",$rd{"seg","$des1","$des2"};
	}
	print $fh " \n";
    }
    &evalsec_wrt_state_extra($fh,$#des_sec) if ($Lextra);
}				# end of evalsec_wrt_state

#===============================================================================
sub evalsec_wrt_state_extra {
    local ($fh) = @_ ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_state_extra      writes line: +--------+ ...
#--------------------------------------------------------------------------------
    print $fh "DAT +---------+-------+-------+-------+ +---------+---------+---------+---------+\n";
}				# end of evalsec_wrt_state_extra

#===============================================================================
sub evalsec_wrt_tot {
    local ($fh,$Lextra,@des_sec) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_tot            writes numbers (Aij)
#--------------------------------------------------------------------------------
    print  $fh "# \n# Overall scores:\n# \n";
    print $fh "DAT +---------------------------------+ +---------------------------------------+\n";
    print $fh "DAT |   Overall per-residue scores    | |       Overall per-segment scores      |\n";
    print $fh "DAT +-------+--------+-------+--------+ +---------+---------+---------+---------+\n";
    printf 
	$fh "DAT | OVER  | %5.1f  | UNDER | %5.1f  | |                                       |\n",
	$rd{"over"},$rd{"under"};
    printf 
	$fh "DAT | I obs |  %5.2f | I prd |  %5.2f | |                                       |\n",
	$rd{"entropy","obs"},$rd{"entropy","obs"};
    printf 
	$fh "DAT |  Q3   | %5.1f  |  BAD  | %5.1f  | | SOV3obs | %6.1f  | SOV3prd | %6.1f  |\n",
	$rd{"q3"},$rd{"bad"},$rd{"sov","Sobs"},$rd{"sov","Sprd"};
    if ($Lextra) { 
	print 
	    $fh "DAT +-------+========+-------+--------+ ",
	    "+---------+=========+---------+---------+\n";
    }
}				# end of evalsec_wrt_tot

#===============================================================================
sub evalsec_wrt_ave {
    local ($fh,$numprot,$q3ave,$q3var) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_ave            writes final averages over sets
#--------------------------------------------------------------------------------
    printf $fh "# \n# Per-residue accuracy averaged over all %5d proteins:\n# \n",$numprot;
    print  $fh "+---------------------+---------------------------------+\n";
    printf $fh "| <Q3>/prot  = %6.2f | one standard deviation = %6.2f |\n",$q3ave,$q3var;
    print  $fh "+---------------------+---------------------------------+\n";
}				# end of evalsec_wrt_ave

#===============================================================================
sub evalsec_wrt_class {
    local ($fh,@des) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    evalsec_wrt_class            writes final class values
#--------------------------------------------------------------------------------
    print  $fh "# \n# Accuracy of predicting secondary structural content:\n# \n";
    print  $fh "DAT +---------------------+---------------------------------+\n";
    foreach $des(@des){
	printf 
	    $fh "DAT | Dcontent %1s = %6.2f | one standard deviation = %6.2f |\n",
	    $des,$rd{"contave","$des"},$rd{"contvar","$des"};
    }
    print  $fh "DAT +---------------------+---------------------------------+\n";
				# class
    print  $fh "# \n# Accuracy of predicting secondary structural class:\n# \n";
    print  
	$fh "#        Sorting into structure class according to \n",
	"#        Zhang, C.-T. and Chou, K.-C., Prot. Sci. 1:401-408, 1992:\n",
	"#           all-H: percentage of H >= 45% , percentage of E <  5%\n",
	"#           all-E: percentage of H <   5% , percentage of E >=45%\n",
	"#           mix  : percentage of H >= 30% , percentage of E >=20%\n# \n";
    $ct=1;
    while ( defined $rd{"class","$ct"} ){
	print $fh "DAT ",$rd{"class","$ct"},"\n";
	++$ct;
    }
}				# end of evalsec_wrt_class

