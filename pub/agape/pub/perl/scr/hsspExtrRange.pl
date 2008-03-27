#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extract a range (and or chain) from DSSP file (and runs MaxHom on HSSP header)";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
if (! defined $ENV{'ARCH'}){print "*** setenv ARCH to machine type\n";
			    exit;}
$ARCH=$ENV{'ARCH'};
$par{"exeHsspExtrHdrId"}=   "/home/rost/perl/scr/hssp_extr_id.pl";
$par{"dirSwissCurrent"}=    "/data/swissprot/current/";
$par{"exeMax"}=             "/home/rost/pub/max/bin/". "maxhom.".$ARCH;
$par{"fileMaxDef"}=         "/home/rost/pub/max/".     "maxhom.default";
$par{"fileMaxMat"}=         "/home/rost/pub/max/mat/". "Maxhom_GCG.metric";
$par{"parMaxThresh"}=       "FORMULA +5"; # identity cut-off for Maxhom threshold of hits taken
$par{"parMaxProf"}=         "NO";
$par{"parMaxSmin"}=        -0.5;         # standard job
$par{"parMaxSmax"}=         1.0;         # standard job
$par{"parMaxGo"}=           3.0;         # standard job
$par{"parMaxGe"}=           0.1;         # standard job
$par{"parMaxW1"}=           "YES";       # standard job
$par{"parMaxW2"}=           "NO";        # standard job
$par{"parMaxI1"}=           "YES";       # standard job
$par{"parMaxI2"}=           "NO";        # standard job
$par{"parMaxNali"}=       500;           # standard job
$par{"parMaxSort"}=         "DISTANCE";  # standard job
$par{"parMaxProfOut"}=      "NO";        # standard job
$par{"parMaxStripOut"}=     "NO";        # standard job

				# ------------------------------
				# help
if ($#ARGV<2){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file_hssp chain ('0' for wild card)'\n";
    print "opt: \t pdbno=1-5,8-100 (reads PDBno as given, i.e., 2nd column in DSSP)\n";
    print "or:  \t no=1-5,8-100    (reads the DSSP no, i.e., first column)\n";
    print "     \t noMax / noDssp  (will no run Maxhom/not store DSSP file\n";
    print "     \t fileOutDssp=x\n";
    print "     \t fileOutHssp=x\n";
    print "     \t fileHssp=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$LnoPhd=$LnoMax=$LnoDssp=0;
				# read command line
$fileIn=  $ARGV[1];
$chainIn= $ARGV[2];
$tmp=$fileIn;$tmp=~s/^.*\///g;
$fileOutDssp=$tmp;
$fileOutHssp=$tmp;$fileOutHssp=~s/dssp/hssp/;

$Ldssp=$Lpdb=0;
foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);next if ($_ eq $ARGV[2]);
    if   ($_=~/^fileOutHssp=(.*)$/) {$fileOutHssp=$1;}
    elsif($_=~/^fileOutDssp=(.*)$/) {$fileOutDssp=$1;}
    elsif($_=~/^no=(.*)$/)          {$rangeIn=$1;$Ldssp=1;}
    elsif($_=~/^pdbno=(.*)$/i)      {$rangeIn=$1;$Lpdb=1;}
    elsif($_=~/^fileHssp=(.*)$/)    {$fileHssp=$1;}
    elsif($_=~/^noMax/i)            {$LnoMax=1;}
    elsif($_=~/^noDssp/i)           {$LnoDssp=1;}

    else { print"*** wrong command line arg '$_'\n";
	   die;}}
if (!defined $fileHssp){
    $fileHssp=$fileIn;$fileHssp=~s/dssp/hssp/g;}
if (! -e $fileHssp){
    print "-*- WARNING no HSSP $fileHssp\n";
    $Lhssp=0;}else{$Lhssp=1;}
if ($LnoMax){$Lhssp=0;}
if (! -e $fileIn){
    print "*** ERROR no DSSP $fileHssp for $fileIn\n";
    die;}
$#fileRm=0;
				# ------------------------------
				# (1) get range
@tmp=split(/,/,$rangeIn);
foreach $it (1..10000){$ok[$it]=0;}
$nres=0;
foreach $tmp(@tmp){
    $tmp=~s/\s//g;
    @tmp2=split(/-/,$tmp);
    foreach $it ($tmp2[1]..$tmp2[2]){++$nres;
				     $ok[$it]=1;}
    $max=$tmp2[2];}
				# ------------------------------
				# (2) read DSSP file
&open_file("$fhin", "$fileIn");
$#rd=0;
while (<$fhin>) {push(@rd,$_);
		 last if ($_=~/^\s+\#\s+RES/);}
while (<$fhin>) {$line=$_;
		 $chain=substr($_,12,1);
		 $pdbNo=substr($_,6,5);$pdbNo=~s/\s//g;
		 next if ($chainIn ne "0" && $chain ne $chainIn);
		 next if (! $ok[$pdbNo]);
		 push(@rd,$line);
		 ++$ctRes; 
		 if ($ctRes > ($nres+10)){ # allow for more (PDB 64,64A,...)
		     print "*** $fileIn too many residues now $ctRes max=$max, nres=$nres,\n";
		     exit;}}
close($fhin);
$nres=$ctRes;			# correct for additional PDB residues

				# ------------------------------
				# (3) write DSSP output
if ($LnoDssp){
    $fileTmpDssp="DSSP_EXTR_RANGE_".$$.".dssp";push(@fileRm,$fileTmpDssp);}
else {$fileTmpDssp=$fileOutDssp;}
print "--- write DSSP $fileTmpDssp\n";
&open_file("$fhout",">$fileTmpDssp"); 
foreach $rd(@rd){
    if ($rd =~/TOTAL NUMBER OF RES/){
	printf $fhout "%5d%-s\n",$nres,substr($rd,6);}
    else{
	print $fhout $rd;}}
close($fhout);
				# ------------------------------
				# (4) extract Swiss ids
if ($Lhssp){
    $fileHssp=$fileIn;$fileHssp=~s/dssp/hssp/g;
    $exe=$par{"exeHsspExtrHdrId"};
    $fileTmp="DSSP_EXTR_RANGE_".$$.".tmp";push(@fileRm,$fileTmp);
    $arg="swiss fileSwiss=$fileTmp";
    print "--- system \t '$exe $fileHssp $arg'\n";
    system("$exe $fileHssp $arg"); # run external script
				# ------------------------------
				# (5) read DSSP file
    &open_file("$fhin", "$fileTmp");
    $#rd=0;
    while (<$fhin>) {next if (/^id1/);
		     $_=~s/\n//g;
		     next if (length($_)<10);
		     ($tmp,$swiss)=split(/\s+/,$_);}
    close($fhin);
}
if (defined $swiss){
    @swiss=split(/,/,$swiss);}
if ($#swiss>=1){
				# ------------------------------
				# (6) write swiss-list
    $fileTmpList="DSSP_EXTR_RANGE_".$$.".list";push(@fileRm,$fileTmpList);
    &open_file("$fhout",">$fileTmpList"); 
#    @swiss=split(/,/,$swiss);
    foreach $swiss(@swiss){$swiss=~s/\s//g;
			   $dir=$swiss;$dir=~s/^[^\_]+\_(.).+$/$1/g;
			   $tmp=$par{"dirSwissCurrent"}."$dir"."/".$swiss;
			   next if (! -e $tmp);	# ignore missing files
			   print $fhout "$tmp\n";}
    close($fhout);
				# ------------------------------
				# (7) run Maxhom
    $cmd=&maxhomGetArg(" ",$par{"exeMax"},$par{"fileMaxDef"},$$,$fileTmpDssp,$fileTmpList,
		       $par{"parMaxProf"},$par{"fileMaxMat"},
		       $par{"parMaxSmin"},$par{"parMaxSmax"},$par{"parMaxGo"},$par{"parMaxGe"},
		       $par{"parMaxW1"},$par{"parMaxW2"},$par{"parMaxI1"},$par{"parMaxI2"},
		       $par{"parMaxNali"},$par{"parMaxThresh"},$par{"parMaxSort"},$fileOutHssp,
		       "/data/pdb/",$par{"parMaxProfOut"},$par{"parMaxStripOut"});
    $Lok=&run_program("$cmd","STDOUT"); # its running!
}
				# ------------------------------
				# (8) if missing: run self
if (! -e $fileOutHssp || &is_hssp_empty($fileOutHssp)){
    $Lok=$err=0;
    print "--- $scrName: running self ($fileTmpDssp)\n";
    ($Lok,$err)=
	&maxhomRunSelf(" ",$par{"exeMax"},$par{"fileMaxDef"},$$,$fileTmpDssp,
		       $fileOutHssp,$par{"fileMaxMat"},"STDOUT"); # 
}
				# ------------------------------
				# (9) clean up
if ($Lok){
    foreach $fileRm(@fileRm){
	unlink($fileRm);}
    system("\\rm MAXHOM*$$*");
    system("\\rm DSSP*$$*");
}
				# ------------------------------
				# (2) write output
print "--- output in $fileOutHssp\n";
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#==============================================================================
sub maxhomGetArg {
    local($niceLoc,$exeMaxLoc,$fileDefaultLoc,$jobid,$fileMaxIn,$fileMaxList,$Lprofile,
	  $fileMaxMetric,$paraMaxSmin,$paraMaxSmax,$paraMaxGo,$paraMaxGe,
	  $paraMaxWeight1,$paraMaxWeight2,$paraMaxIndel1,$paraMaxIndel2,
	  $paraMaxNali,$paraMaxThresh,$paraMaxSort,$fileHsspOut,$dirMaxPdb,
	  $paraMaxProfileOut,$fileStripOut)=@_;
    local ($command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetArg                gets the input arguments to run MAXHOM
#       in:                     
#         $niceLoc              level of nice (nice -n)
#         $exeMaxLoc            fortran executable for MaxHom
#         $fileDefaultLoc       local copy of maxhom default file
#         $jobid                number which will be added to files :
#                               MAXHOM_ALI.jobid, MAXHOM.LOG_jobid, maxhom.default_jobid
#                               filter.list_jobid, blast.x_jobid
#         $fileMaxIn            query sequence (should be FASTA, here)
#         $fileMaxList          list of db to align against
#         $Lprofile             NO|YES                  (2nd is profile)
#         $fileMaxMetric        metric
#         $paraMaxSmin          minimal value of metric (typical -0.5)
#         $paraMaxSmax          maximal value of metric (typical  1.0)
#         $paraMaxGo            gap open penalty        (typical  3.0)
#         $paraMaxGe            gap extension/elongation penalty (typ 0.3)
#         $paraMaxWeight1       YES|NO                  (typ yes)
#         $paraMaxWeight2       YES|NO                  (typ NO)
#         $paraMaxIndel1        YES|NO                  (typ yes)
#         $paraMaxIndel2        YES|NO                  (typ yes)
#         $paraMaxNali          maximal number of alis reported (was 500)
#         $paraMaxThresh              
#         $paraMaxSort          DISTANCE|    
#         $fileHsspOut          NO|name of output file (.hssp)
#         $dirMaxPdb            path of PDB directory
#         $paraMaxProfileOut    NO| ?
#         $fileStripOut         NO|file name of strip file
#       out:                    $command
#--------------------------------------------------------------------------------
    $tmpNice=$niceLoc;
    if ($tmpNice =~ /\d/ || $tmpNice eq "nice"){
	$tmpNice=~s/nice|[ -]//g; 
	$tmpNice=19 if (length($tmpNice)<1);
	if ($exeMaxLoc =~/ALPHA/){$tmpNice="nice -".$tmpNice;}
	else                     {$tmpNice="nice -".$tmpNice;}}
    eval "\$command=\"$tmpNice $exeMaxLoc -d=$fileDefaultLoc -nopar ,
         COMMAND NO ,
         BATCH ,
         PID:          $jobid ,
         SEQ_1         $fileMaxIn ,      
         SEQ_2         $fileMaxList ,
         PROFILE       $Lprofile ,
         METRIC        $fileMaxMetric ,
         NORM_PROFILE  DISABLED , 
         MEAN_PROFILE  0.0 ,
         FACTOR_GAPS   0.0 ,
         SMIN          $paraMaxSmin , 
         SMAX          $paraMaxSmax ,
         GAP_OPEN      $paraMaxGo ,
         GAP_ELONG     $paraMaxGe ,
         WEIGHT1       $paraMaxWeight1 ,
         WEIGHT2       $paraMaxWeight2 ,
         WAY3-ALIGN    NO ,
         INDEL_1       $paraMaxIndel1,
         INDEL_2       $paraMaxIndel2,
         RELIABILITY   NO ,
         FILTER_RANGE  10.0,
         NBEST         1,
         MAXALIGN      $paraMaxNali ,
         THRESHOLD     $paraMaxThresh ,
         SORT          $paraMaxSort ,
         HSSP          $fileHsspOut ,
         SAME_SEQ_SHOW YES ,
         SUPERPOS      NO ,
         PDB_PATH      $dirMaxPdb ,
         PROFILE_OUT   $paraMaxProfileOut ,
         STRIP_OUT     $fileStripOut ,
         LONG_OUT      NO ,
         DOT_PLOT      NO ,
         RUN ,\"";
    return ($command);
}				# end maxhomGetArg

#==============================================================================
sub maxhomGetArgCheck {
    local($exeMaxLoc,$fileDefLoc,$fileMaxIn,$fileMaxList,$fileMaxMetric)=@_;
    local($msg,$warn,$pre);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetArgCheck           performs some basic file-existence-checks
#                               before Maxhom arguments are built up
#       in:                     $exeMaxLoc,$fileDefLoc,$fileMaxIn,$fileMaxList,$fileMaxMetric
#       out:                    msg,warn
#--------------------------------------------------------------------------------
    $msg="";$warn="";$pre="*** maxhomGetArgCheck missing ";
    if    (! -e $exeMaxLoc     && ! -l $exeMaxLoc )   {$msg.="$pre"."$exeMaxLoc=    for exe\n";}
    elsif (! -e $fileDefLoc    && ! -l $fileDefLoc)   {$msg.="$pre"."$fileDefLoc=   default file\n";}
    elsif (! -e $fileMaxIn     && ! -l $fileMaxIn )   {$msg.="$pre"."$fileMaxIn=    query seq\n";}
    elsif (! -e $fileMaxList   && ! -l $fileMaxList)  {$msg.="$pre"."$fileMaxList=  ali DB\n";}
    elsif (! -e $fileMaxMetric && ! -l $fileMaxMetric){$msg.="$pre"."$fileMaxMetric=metric\n";}
    return ($msg,$warn);
}				# end maxhomGetArgCheck

#==============================================================================
sub maxhomRunSelf {
    local($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$fileJobIdLoc,$fileHsspInLoc,
	  $fileHsspOutLoc,$fileMaxMetrLoc,$fhTraceLoc,$fileScreenLoc)=@_;
    local($sbrName,$msgHere,$msg,$tmp,$Lok,$LprofileLoc,$dirMaxPdbLoc,$paraMaxProfOutLoc,
	  $paraMaxSminLoc,$paraMaxSmaxLoc,$paraMaxGoLoc,$paraMaxGeLoc,
	  $paraMaxW1Loc,$paraMaxW2Loc,$paraMaxIndel1Loc,$paraMaxIndel2Loc,
	  $paraMaxNaliLoc,$paraMaxThreshLoc,$paraMaxSortLoc,$fileStripOutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomRunSelf               runs a MaxHom: search seq against itself
#                               NOTE: needs to run convert_seq to make sure
#                                     that 'itself' is in FASTA format
#       in:                     many
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:maxhomRunSelf";
    return(0,"*** $sbrName: not def niceLoc!")            if (! defined $niceLoc);
    return(0,"*** $sbrName: not def exeMaxLoc!")          if (! defined $exeMaxLoc);
    return(0,"*** $sbrName: not def fileMaxDefLoc!")      if (! defined $fileMaxDefLoc);
    return(0,"*** $sbrName: not def fileJobIdLoc!")       if (! defined $fileJobIdLoc);
    return(0,"*** $sbrName: not def fileHsspInLoc!")      if (! defined $fileHsspInLoc);
    return(0,"*** $sbrName: not def fileHsspOutLoc!")     if (! defined $fileHsspOutLoc);
    return(0,"*** $sbrName: not def fileMaxMetrLoc!")     if (! defined $fileMaxMetrLoc);
    $fhTraceLoc="STDOUT"                                  if (! defined $fhTraceLoc);
    $fileScreenLoc=0                                      if (! defined $fileScreenLoc);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileHsspInLoc'!")  if (! -e $fileHsspInLoc &&
								     ! -l $fileHsspInLoc);
    return(0,"*** $sbrName: miss input exe  '$exeMaxLoc'!")      if (! -e $exeMaxLoc &&
								     ! -l $exeMaxLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxDefLoc'!")  if (! -e $fileMaxDefLoc &&
								     ! -l $fileMaxDefLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxMetrLoc'!") if (! -e $fileMaxMetrLoc &&
								     ! -l $fileMaxMetrLoc);
    $msgHere="";
				# ------------------------------
				# security check: is FASTA?
#    $Lok=&isFasta($fileHsspInLoc);
#    if (!$Lok){
#	return(0,"*** $sbrName: input must be FASTA '$fileHsspInLoc'!");}
				# ------------------------------
				# prepare MaxHom
    ($msg,$warn)=		# check existence of files asf
	&maxhomGetArgCheck($exeMaxLoc,$fileMaxDefLoc,$fileHsspInLoc,$fileHsspInLoc,
			   $fileMaxMetrLoc);
    return(0,"$msg")            if (length($msg)>1);
    $msgHere.="--- $sbrName $warn\n";	

    $LprofileLoc=      "NO";	# build up argument
    $paraMaxSminLoc=   "-0.5";     $paraMaxSmaxLoc=   "1";
    $paraMaxGoLoc=     "3.0";      $paraMaxGeLoc=     "0.1";
    $paraMaxW1Loc=     "YES";      $paraMaxW2Loc=     "NO";
    $paraMaxIndel1Loc= "NO";       $paraMaxIndel2Loc= "NO";
    $paraMaxNaliLoc=   "5";        $paraMaxThreshLoc= "ALL";
    $paraMaxSortLoc=   "DISTANCE"; $dirMaxPdbLoc=     "/data/pdb/";
    $paraMaxProfOutLoc="NO";       $fileStripOutLoc=  "NO";
				# --------------------------------------------------
    $maxCmdLoc=			# get command line argument for starting MaxHom
	&maxhomGetArg($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$fileJobIdLoc,
		      $fileHsspInLoc,$fileHsspInLoc,$LprofileLoc,$fileMaxMetrLoc,
		      $paraMaxSminLoc,$paraMaxSmaxLoc,$paraMaxGoLoc,$paraMaxGeLoc,
		      $paraMaxW1Loc,$paraMaxW2Loc,$paraMaxIndel1Loc,$paraMaxIndel2Loc,
		      $paraMaxNaliLoc,$paraMaxThreshLoc,$paraMaxSortLoc,
		      $fileHsspOutLoc,$dirMaxPdbLoc,$paraMaxProfOutLoc,$fileStripOutLoc);
				# --------------------------------------------------
				# run maxhom self
#    $Lok=
#	&run_program($maxCmdLoc,$fhTraceLoc,"warn");

    ($Lok,$msg)=
	&sysRunProg($maxCmdLoc,$fileScreenLoc,$fhTraceLoc);

    return(0,"*** $sbrName: fault in maxhom ($exeMaxLoc)\n")
	if (! $Lok || ! -e $fileHsspOutLoc); # output file missing

    return(1,"ok $sbrName");
}				# end of maxhomRunSelf

#==============================================================================
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

#==============================================================================
sub run_program {
    local ($cmd,$fhLogFile,$action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    print "--- running command: \t $cmdtmp"  if ((! defined $Lverb)||$Lverb);
    print " do='$action'"                    if (defined $action); 
    print "\n" ;
				# opens cmdtmp into pipe
    open (TMP_CMD, "|$cmdtmp") || 
	(do {print $fhLogFile "Cannot run command: $cmdtmp\n" if ( $fhLogFile ) || 
		 warn "Cannot run command: '$cmdtmp'\n" ;
	     exec '$action' if (defined $action);
	 });

    foreach $command (@out_command) { # delete end of line, and leading blanks
	$command=~s/\n//; $command=~s/^\s*|\s*$//g;
	print TMP_CMD "$command\n" ;
    }
    close (TMP_CMD) ;		# upon closing: cmdtmp < @out_command executed
}				# end of run_program

#==============================================================================
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



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
