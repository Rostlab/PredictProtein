#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "runs MAXHOM (+ filter = BLAST)";
$scrIn=      "<seq.x|seq.*|many-seq.list>";
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= " \n";
$scrHelpTxt= "shortcuts for db: <trembl|swiss|big> \n";
$scrHelpTxt.=" \n";
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text markers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  - 
#  
#  
#  - $par{"kwd"}  : global parameters, available on command line by 'kwd=value'
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2003	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 1.0   	Oct,    	1998	       #
#				version 1.1   	Aug,    	2003	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0

($Lok,$msg)=
    &maxhomRunLoc(@ARGV);

print "*** $scrName: final msg=".$msg."\n" if (! $Lok);

exit;

#===============================================================================
sub maxhomRunLoc {
    local($SBR,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomRunLoc                runs MAXHOM (designed to become package)
#       in:                     input like for any script ('file argx=x')
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."maxhomRunLoc";$fhinLoc="FHIN_"."maxhomRunLoc";
    
				# ------------------------------
    ($Lok,$msg)=		# initialise variables
	&iniMaxhom();
    if (! $Lok) { print "*** ERROR $scrName after iniMaxhom\n",$msg,"\n";
		  die '*** during initialising $scrName   ';}

				# ------------------------------
				# redirect STDERR (file handle)
    if (defined $par{"debug"} && ! $par{"debug"}){ 
	$Lopen_stderr=1;
	open(STDERR,">".$par{"fileOutStderr"}) || 
	    do {  print "*-* failed to open traceStderr=".."!\n";
		  $Lopen_stderr=0;};} else { $Lopen_stderr=0;}
	
				# --------------------------------------------------
				# (1) read input file list
				# --------------------------------------------------
    if ($par{"isList"} || $isFastaMul){
	print "--- $SBR: assumed fileIn=$fileIn, is list\n"     if (! $isFastaMul);
	print "--- $SBR: assumed fileIn=$fileIn, is fastaMul\n" if ($isFastaMul);
        ($Lok,$msg,@fileIn)=
	    &maxhomRunRdlist($fileIn,$par{"titleTmp"},$par{"dirWork"},$par{"extFasta"});
	return(&errSbrMsg("failed reading list=$fileIn (maxhomRunRdList)",$msg,$SBR)) if (! $Lok);
                                # temporary files to remove
        if ( $isFastaMul && ! $par{"debug"}){
            foreach $file (@fileIn){
                push(@fileRm,$file);}} }

				# --------------------------------------------------
				# (2) convert all to FASTA format
				# --------------------------------------------------
    if (! &isFasta($fileIn[1]) ){
        ($Lok,$msg,@fileTmp)=
	    &copf2fasta($par{"exeCopf"},$par{"exeConvertSeq"},1,"",$par{"extFasta"},
                        $par{"dirWork"},$par{"fileOutScreen"},$fhTrace,@fileIn);
        return(&errSbrMsg("failed converting to FASTA",$msg,$SBR)) if (! $Lok);
        return(&errSbrMsg("N files converted=".$#fileTmp.
			  ", N files in=".$#fileIn,$msg,$SBR)) if ($#fileTmp != $#fileIn);
        $Lchange=0;
        foreach $it (1..$#fileTmp){
            next if ($fileTmp[$it] eq $fileIn[$it]);
	    $Lchange=1;
	    push(@fileRm,$fileTmp[$it]); }
        @fileIn=@fileTmp; }     $#fileTmp=0; # slim-is-in

				# ------------------------------
				# (3) setenv BLAST
				# ------------------------------
    if ($par{"doBlastp"} || $par{"doBlast3"}){
	($Lok,$msg)=
	    &blastSetenv($par{"BLASTMAT"},$par{"BLASTDB"});
                                return(&errSbrMsg("failed setting env for BLAST",
						  $msg,$SBR)) if (! $Lok);}

				# --------------------------------------------------
				# (4) loop over all input file(s)
				# --------------------------------------------------
    $ctfile=0; $nfileIn=$#fileIn; 
    $lenFileIn=$lenFileOut=0;

    if ($#fileIn > 1 && $par{"doBlast3"}){
	print "*-* WARN $scrName: DEFAULT parameters for running Dariusz wrapper on PSI-BLAST!\n"
	    x 10;
    }
	
    while (@fileIn){
	$fileIn=shift @fileIn;
	if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n"; 
                          next;}
	++$ctfile; $idIn=$fileIn;$idIn=~s/^.*\/|\..*$//g;  

        if ($par{"dirOutHssp"}) {
            $dirOut=$par{"dirOutHssp"}; $dirOut.="/" if ($dirOut !~/\/$/);}
        else {
            $dirOut=$par{"dirOut"}; }

	if ($nfileIn==1){
	    $fileHsspFil=$fileHsspFil if (defined $fileHsspFil);
	    if (defined $fileHssp) {
		$fileHssp=   $fileHssp;}
	    else {
		$fileHssp=$dirOut.$idIn.$par{"extHssp"}; }}
	else {
		$fileHssp=$dirOut.$idIn.$par{"extHssp"}; }

				# ==============================
				# run it
	($Lok,$msg)=
	    &doAli($fileIn,$fileHssp,$fileHsspFil);
	&errScrMsg("failed ali on $fileIn->$fileHssp",$msg) if (! $Lok);

				# ------------------------------
				# estimate time
	$lenFileIn= length($fileIn)   if (length($fileIn)   > $lenFileIn);
	$lenFileOut=length($fileHssp) if (length($fileHssp) > $lenFileOut);
	$estimate=
	    &fctRunTimeLeft($timeBeg,$nfileIn,$ctfile);
	$estimate="?"           if ($ctfile < 5);
	printf 
	    "--- %-".$lenFileIn."s -> %-".$lenFileOut."s %4d (%4.1f%-1s), time left=%-s \n",
	    $fileIn,$fileHssp,$ctfile,(100*$ctfile/$nfileIn),"%",$estimate;
                                # delete raw data
        push(@fileRm,$fileHssp) if (! $par{"keepHsspRaw"} && -e $fileHsspFil);
    }				# end of loop over all input files
				# --------------------------------------------------

                                # ------------------------------
    if (! $par{"debug"}){       # (5) clean up
#	push(@fileRm,$par{"fileOutScreen"},$par{"fileOutTrace"});
	foreach $file (@fileRm){
	    if (defined $file && -e $file){ print "--- remove $file\n";
					    unlink $file;}}}

				# ------------------------------
				# close STDERR
    if ($Lopen_stderr){
	close(STDERR);
	unlink($par{"fileOutStderr"});}
    
                                # ------------------------------
                                # (6) final words
    if ($par{"verbose"}) { 
#	print $fhTrace "--- $scrName ended fine .. -:\)\n";
	print "--- $scrName ended fine .. -:\)\n";
	$timeEnd=time;		# runtime , run time
	$timeRun=$timeEnd-$timeBeg;
#	print $fhTrace 
	print 
	    "--- date     \t \t $Date \n",
	    "--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n"; 
	close($fhTrace)         if ($fhTrace ne "STDOUT" && $fhTrace); }
    return(1,"ok $SBR");
}				# end of maxhomRunLoc



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub blast3RunSimple {
    local($fileInLoc,$fileOutLoc,$exeBlast3Loc,$dbBlastLoc,$parELoc,$parBLoc,
	  $fileOutScreenLoc,$fhSbrErr,$parVloc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blast3RunSimple             simply runs BLASTALL (blast3)
#                               NOTE: for security call &blastSetenv before running
#       in:                     $fileInLoc     : FASTA formatted input file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $dbBlastLoc    : BLASTP db to run             if = 0: swiss
#       in:                     $parELoc       : BLASTP para E                if = 0: default
#       in:                     $parBLoc       : BLASTP para B                if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blast3RunSimple";$fhinLoc="FHIN_"."blast3RunSimple";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeBlast3LocDef=           "/home/rost/pub/molbio/blastall.$ARCH";
    $dbBlastLocDef=             "swiss";
    $parELocDef=             1000;
    $parBLocDef=             2000;
    $parVLocDef=             2000 || $par{"parBlastV"};

                                # ------------------------------
				# check arguments
    $fileOutLoc=0               if (! defined $fileOutLoc);
    $exeBlast3Loc=$exeBlast3LocDef  if (! defined $exeBlast3Loc || ! $exeBlast3Loc);
    $dbBlastLoc=$dbBlastLocDef  if (! defined $dbBlastLoc || ! $dbBlastLoc);
    $parELoc=$parELocDef        if (! defined $parELoc || ! $parELoc);
    $parBLoc=$parBLocDef        if (! defined $parBLoc || ! $parBLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);
    $parVloc=$parVLocDef        if (! defined $parVLoc || ! $parVLoc);

    $cmdSys="";
				# ------------------------------
				# run BLAST
				# ------------------------------
                                    
    $cmd= $exeBlast3Loc." -i $fileInLoc -p blastp -d $dbBlastLoc -F F -e $parELoc -b $parBLoc";
    $cmd.=" -v $parVloc";
    $cmd.=" -o $fileOutLoc"      if ($fileOutLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run BLAST3 on ($fileInLoc)",$msg)) 
        if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName");
}				# end of blast3RunSimple

#==============================================================================
sub blast3RunDariusz {
    local($fileInLoc,$fileOutLoc,
	  $exeBlast3Loc,$exeBlastDariuszLoc,$exeBlastDariuszPackLoc,
	  $dbBlastLoc,$parELoc,$parBLoc,
	  $fileOutScreenLoc,$fhSbrErr,$parVloc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blast3RunDariusz            simply runs PSI-BLAST wrapper from Dariusz
#                               NOTE: for security call &blastSetenv before running
#       in:                     $fileInLoc     : FASTA formatted input file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $exeBlastDariusz: Dariuszs wrapper for PSI-BLAST
#       in:                     $exeBlastDariuszPack: Dariuszs wrapper package for PSI-BLAST
#       in:                     $dbBlastLoc    : BLASTP db to run             if = 0: swiss
#       in:                     $parELoc       : BLASTP para E                if = 0: default
#       in:                     $parBLoc       : BLASTP para B                if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blast3RunDariusz";$fhinLoc="FHIN_"."blast3RunDariusz";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeBlast3LocDef=           "/home/rost/pub/molbio/blastall.$ARCH";
    $exeBlastDariuszLocDef=     "/home/rost/pub/blast/blastpgp.pl";
    $exeBlastDariuszPackLocDef= "/home/rost/pub/blast/blastpgp.pm";
    $dbBlastLocDef=             "big";
    $parELocDef=             1000;
    $parBLocDef=             2000;
    $parVLocDef=             2000 || $par{"parBlastV"};

                                # ------------------------------
				# check arguments
    $fileOutLoc=0               if (! defined $fileOutLoc);
    $exeBlast3Loc=
	$exeBlast3LocDef        if (! defined $exeBlast3Loc || ! $exeBlast3Loc);
	
    $exeBlastDariuszLoc=
	$exeBlastDariuszLocDef  if (! defined $exeBlastDariuszLoc || ! $exeBlastDariuszLoc);
    $exeBlastDariuszPackLoc=
	$exeBlastDariuszPackLocDef  
	                        if (! defined $exeBlastDariuszPackLoc || ! $exeBlastDariuszPackLoc);

    $dbBlastLoc=$dbBlastLocDef  if (! defined $dbBlastLoc || ! $dbBlastLoc);
    $parELoc=$parELocDef        if (! defined $parELoc || ! $parELoc);
    $parBLoc=$parBLocDef        if (! defined $parBLoc || ! $parBLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);
    $parVloc=$parVLocDef        if (! defined $parVLoc || ! $parVLoc);

    $cmdSys="";
				# ------------------------------
				# run BLAST
				# ------------------------------
                                    
    $cmd= $exeBlastDariuszLoc." ";
    $cmd.=$fileInLoc;
#    $cmd.=$fileInLoc." exeBlast=".$exeBlast3Loc;
#    $cmd.=" pack=".$par{"exeBlastDariuszPack"};
    $cmd.=" fileOut=$fileOutLoc"      if ($fileOutLoc);


    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run BLAST3 on ($fileInLoc)",$msg)) 
        if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName");
}				# end of blast3RunDariusz

#==============================================================================
sub blastSetenv {
    local($BLASTMATloc,$BLASTDBloc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastSetenv                 sets environment for BLASTP runs
#       in:                     $BLASTMAT,$BLASTDB (or default)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastSetenv";$fhinLoc="FHIN_"."blastSetenv";
				# defaults
    $BLASTMATdef="/home/rost/oub/molbio/blast/blastapp/matrix";
    $BLASTDBdef= "/home/rost/pub/molbio/db";
				# check arguments
    $BLASTMATloc=$BLASTMATdef   if (! defined $BLASTMATloc);
    $BLASTDBloc=$BLASTDBdef     if (! defined $BLASTDBloc);
				# existence
    if (! -d $BLASTMATloc && ($BLASTMATloc ne $BLASTMATdef)){
	print "-*- WARN $sbrName: changed env BLASTMAT from $BLASTMATloc to $BLASTMATdef\n" x 5;
	$BLASTMATloc=$BLASTMATdef; }
    if (! -d $BLASTDBloc  && ($BLASTDBloc ne $BLASTDBdef)){
	print "-*- WARN $sbrName: changed env BLASTDB from $BLASTDBloc to $BLASTDBdef\n" x 5;
	$BLASTDBloc=$BLASTDBdef; }
    return(&errSbr("BLASTMAT $BLASTMATloc not existing")) if (! -d $BLASTMATloc);
    return(&errSbr("BLASTDB  $BLASTDBloc not existing"))  if (! -d $BLASTDBloc);
				# ------------------------------
				# set env
#    system("setenv BLASTMAT $BLASTMATloc"); # system call
    $ENV{'BLASTMAT'}=$BLASTMATloc;

#    system("setenv BLASTDB $BLASTDBloc"); # system call
    $ENV{'BLASTDB'}=$BLASTDBloc;

    return(1,"ok $sbrName");
}				# end of blastSetenv

#==============================================================================
sub blastpRunSimple {
    local($fileInLoc,$fileOutLoc,$exeBlastpLoc,$dbBlastLoc,$parELoc,$parBLoc,
	  $fileOutScreenLoc,$fhSbrErr,$argBlastpLoc,$parVLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpRunSimple             simply runs BLASTP (blast2)
#                               NOTE: for security call &blastSetenv before running
#       in:                     $fileInLoc     : FASTA formatted input file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $dbBlastLoc    : BLASTP db to run             if = 0: swiss
#       in:                     $parELoc       : BLASTP para E                if = 0: default
#       in:                     $parBLoc       : BLASTP para B                if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       in:                     $argBlastpLoc  : full BLAST argument
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpRunSimple";$fhinLoc="FHIN_"."blastpRunSimple";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

                                # ------------------------------
				# local defaults
    $exeBlastpLocDef=           "/home/rost/pub/molbio/blastp.$ARCH";
    $dbBlastLocDef=             "swiss";
    $parELocDef=             1000;
    $parBLocDef=             2000;
    $parVLocDef=             2000 || $par{"parBlastV"};
    $argBlastpLoc=              0 if (! defined $argBlastpLoc);
                                # ------------------------------
				# check arguments
    $fileOutLoc=0               if (! defined $fileOutLoc);
    $exeBlastpLoc=$exeBlastpLocDef  if (! defined $exeBlastpLoc || ! $exeBlastpLoc);
    $dbBlastLoc=$dbBlastLocDef  if (! defined $dbBlastLoc || ! $dbBlastLoc);

    $parELoc=$parELocDef        if (! defined $parELoc    || ! $parELoc);
    $parBLoc=$parBLocDef        if (! defined $parBLoc    || ! $parBLoc);
    $parVLoc=$parVLocDef        if (! defined $parVLoc    || ! $parVLoc);

				# full argument passed: correct
    if ($argBlastpLoc && $argBlastpLoc =~ /E=/){
	$parELoc=0;}
    if ($argBlastpLoc && $argBlastpLoc =~ /B=/){
	$parBLoc=0;}
				    

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr   || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || 
				    ! $fileOutScreenLoc   ||
				    ! $fileOutLoc);
    $cmdSys="";
				# ------------------------------
				# run BLAST
				# ------------------------------
    $cmd= $exeBlastpLoc." ".$dbBlastLoc." ".$fileInLoc;
    $cmd.=" E=$parELoc"         if ($parELoc);
    $cmd.=" B=$parBLoc"         if ($parBLoc);
    $cmd.=" V=$parVLoc"         if ($parVLoc);
    $cmd.=" ".$argBlastpLoc     if ($argBlastpLoc);
    $cmd.=" >> $fileOutLoc"     if ($fileOutLoc);

    eval "\$cmdSys=\"$cmd\"";

    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run BLASTP on ($fileInLoc)",$msg)) 
	if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName");
}				# end of blastpRunSimple

#==============================================================================
sub brIniErr {
    local($local)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniErr                    error check for initial parameters
#       in GLOBAL:              $par{},@ARGV
#       in:                     $exceptions = 'kwd1,kwd2'
#                                  key words not to check for file existence
#       out:                    ($Lok,$msg)
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."brIniErr";
    @kwd= keys (%par)       if (defined %par && %par);
				# ------------------------------
				# exclude some keyword from check?
    undef %tmp; 
    $#excl=0;
    @excl=split(/,/,$local) if (defined $local);
    if ($#excl>0){
	foreach $kwd(@excl){
	    $tmp{$kwd}=1;}}
    $msgHere="";
				# ------------------------------
    foreach $kwd (@kwd){	# file existence
	next if ($kwd =~ /^file(Out|Help|Def)/i);
	next if (defined $tmp{$kwd});
	if   ($kwd=~/^exe/) { 
	    $msgHere.="*** ERROR executable ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});
	    $msgHere.="*** ERROR executable ($kwd) '".$par{$kwd}."' not executable!\n".
                "***       do the following \t 'chmod +x ".$par{$kwd}."'\n"
                    if (! -x $par{$kwd});}
	elsif($kwd=~/^file/){
	    next if ($par{$kwd} eq "unk" || length($par{$kwd})==0 || !$par{$kwd});
	    $msgHere.="*** ERROR file ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});} # 
    }
    return(0,$msgHere) if ($msgHere=~/ERROR/);
    return(1,"ok $sbrName");
}				# end of brIniErr

#==============================================================================
sub brIniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniGetArg                 standard reading of command line arguments
#       in GLOBAL:              @ARGV,$defaults{},$par{}
#       out GLOBAL:             $par{},@fileIn
#       out:                    @arg_not_understood (i.e. returns 0 if everything ok!)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniGetArg";
    $#argUnk=0;                 # ------------------------------
				# (1) get input directory
    foreach $arg (@ARGV){	# search in command line
	if ($arg=~/^dirIn=(.+)$/){$par{"dirIn"}=$1;
				  last;}}
				# search in defaults
    if ((! defined $par{"dirIn"} || ! -d $par{"dirIn"}) && 
 	defined %defaults && %defaults){
	if (defined $defaults{"dirIn"}){
	    $par{"dirIn"}=$defaults{"dirIn"};
	    $par{"dirIn"}=$PWD    
		if (defined $PWD &&
		    ($par{"dirIn"}=~/^(local|unk)$/ || length($par{"dirIn"})==0));}}
    $par{"dirIn"}.="/" if (defined $par{"dirIn"} && -d $par{"dirIn"} && $par{"dirIn"}!~/\/$/); #  slash
    $par{"dirIn"}=""   if (! defined $par{"dirIn"} || ! -d $par{"dirIn"}); # empty
                                # ------------------------------
    if (defined %par && %par){  # all keywords used in script
        @tmp=sort keys (%par);}
    else{
	$#tmp=0;}

    $Lverb3=0 if (! defined $Lverb3);
    $Lverb2=0 if (! defined $Lverb2);
    $#fileIn=0;                 # ------------------------------
    foreach $arg (@ARGV){	# (2) key word driven input
	if    ($arg=~/^verb\w*3=(\d)/)           {$par{"verb3"}=$Lverb3=$1;}
	elsif ($arg=~/^verb\w*3/)                {$par{"verb3"}=$Lverb3=1;}
	elsif ($arg=~/^verb\w*2=(\d)/)           {$par{"verb2"}=$Lverb2=$1;}
	elsif ($arg=~/^verb\w*2/)                {$par{"verb2"}=$Lverb2=1;}
	elsif ($arg=~/^verbose=(\d)/)            {$par{"verbose"}=$Lverb=$1;}
	elsif ($arg=~/^verbose/)                 {$par{"verbose"}=$Lverb=1;}
	elsif ($arg=~/^not_?([vV]er|[sS]creen)/) {$par{"verbose"}=$Lverb=0; }
	else  {$Lok=0;		# general
               if (-e $arg && ! -d $arg){ # is it file?
                   $Lok=1;push(@fileIn,$arg);}
               if (! $Lok && length($par{"dirIn"})>1 && -e $par{"dirIn"}.$arg){
                   $Lok=1;push(@fileIn,$par{"dirIn"}.$arg);}
				# any of the paras defined ?
               if (! $Lok && $arg=~/=/){
                   foreach $kwd (@tmp){
                       if ($arg=~/^$kwd=(.+)$/){
			   $Lok=1;$par{$kwd}=$1;
			   last;}}}
               push(@argUnk,$arg) if (! $Lok);}}
    return(@argUnk);
}				# end of brIniGetArg

#==============================================================================
sub brIniHelp {
    local(%tmp)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelp                   initialise help text
#       out:                    \d,txt
#       err:                    0,$msg  -> error
#       err:                    1,'fin' -> wanted help, given help
#       err:                    1,$msg  -> continue, was just trying
#       in:                     $tmp{} with
#                               $tmp{sourceFile}=  name and path of calling script
#                               $tmp{scrName}=     name of calling script (no .pl)
#                               $tmp{scrIn}=       input arguments for script
#                               $tmp{scrGoal}=     what script does
#                               $tmp{scrNarg}=     number of argument needed for script
#                               $tmp{scrHelpTxt}=  long blabla about script
#                                   separate by '\n'
#                               $tmp{scrAddHelp}=  help option other than standard
#                                   e.g.: "help xyz     : explain .xyz "
#                                   many: '\n' separated
#                                   NOTE: this will be an entry to $tmp{$special},
#                                   -> $special =  'help xyz' will give explanation 
#                                      $tmp{$special}
#                               $tmp{special}=     'kwd1,kwd2,...' special keywords
#                               $tmp{$special}=    explanation for $special
#                                   syntax: print flat lines (or '--- $line'), separate by '\n'
#                               $tmp{scrHelpHints}= hints (tab separated)
#                               $tmp{scrHelpProblems}= known problems (tab separated)
#       in GLOBULAR:            @ARGV
#                               $par{fileHelpOpt}
#                               $par{fileHelpMan}
#                               $par{fileHelpHints}
#                               $par{fileHelpProblems}
#                               $par{fileDefautlts}
#       in unk:                 leave undefined, or give value = 'unk'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniHelp"; 
				# ------------------------------
				# check input
    if (0){
	foreach $kwd ("sourceFile","scrName","scrIn","scrGoal",
		      "scrNarg","scrAddHelp","special"){
	    print "--- input to $sbrName kwd=$kwd, val=",$tmp{$kwd},",\n";}
    }
    @scrTask=
        ("--- Task:  ".$tmp{"scrGoal"},
         "--- ",
         "--- Input: ".$tmp{"scrIn"},
#         "---                 i.e. requires at least ".$tmp{"scrNarg"}.
#	      " command line argument(s)",
         "--- ");
				# ------------------------------
				# additional help keywords?
				# ------------------------------
    $#tmpAdd=0;
    if (defined $tmp{"scrAddHelp"} && $tmp{"scrAddHelp"} ne "unk"){
	@tmp=split(/\n/,$tmp{"scrAddHelp"});$Lerr=0;
	foreach $tmp(@tmp){
	    push(@tmpAdd,$tmp{"scrName"}.".pl ".$tmp);
	    $tmp2=$tmp;$tmp2=~s/^(.+)\s+\:.*$/$1/;$tmp2=~s/\s*$//g;
	    if (!defined $tmp{"$tmp2"}){
		$Lerr=1;
		print "-*- WARN $sbrName: miss \$tmp{\$special}  for '$tmp2'\n";}}
	if ($Lerr){
	    print  
		"-*- " x 20,"\n","-*- WARN $sbrName: HELP on HELP\n",
		"-*-      if you provide special help in tmp{scrAddHelp}, then\n",
		"-*-      provide also the respective explanation in tmp{\$special},\n",
		"-*-      where \$special is e.g. 'help xyz' in \n",
		"-*-      scrAddHelp='help xyz : what to do'\n","-*- " x 20,"\n";}}
				# ------------------------------
				# build up help standard
				# ------------------------------
    @scrHelp=
	("--- Help:  For further information on input options type:",
	 "--- "." " x length($tmp{"scrName"}).
	 "              ........................................");
    $tmp{"scrName"}=~s/\n$//;
    @scrHelpLoop=
	($tmp{"scrName"}.".pl help          : lists all options",
	 $tmp{"scrName"}.".pl def           : writes default settings",
	 $tmp{"scrName"}.".pl def keyword   : settings for keyword",
	 $tmp{"scrName"}.".pl help keyword  : explain key, how for 'how' and 'howie'");
    push(@scrHelpLoop,
	 $tmp{"scrName"}.".pl problems      : known problems") 
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /problems/);
    push(@scrHelpLoop,
	 $tmp{"scrName"}.".pl hints         : hints for users")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /hints/);
    push(@scrHelpLoop,
	 $tmp{"scrName"}.".pl manual        : will cat the entire manual (... MAY be it will)")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /manual/);
    push(@scrHelpLoop,@tmpAdd) if ($#tmpAdd>0);

    push(@scrHelp,@scrHelpLoop,
	 "--- "." " x length($tmp{"scrName"}).
	        "              ........................................");
				# ------------------------------
				# additional general information
				# ------------------------------
    $#scrHelpTxtLoc=0;
    if (defined $tmp{"scrHelpTxt"}){
	@tmp=split(/\n/,$tmp{"scrHelpTxt"});
				# '--- scrHelptTxt'
				# '> program'       i.e. use: '>' to ommitt '--- '
	foreach $txt (@tmp){
	    push(@scrHelpTxtLoc,"--- $txt\n") if ($txt !~ /^[>\%]/);
	    push(@scrHelpTxtLoc,"$txt\n")     if ($txt =~ /^[>\%]/); }}
				# ------------------------------
				# additional special info
				# ------------------------------
    $#scrSpecialLoc=0;
    if (defined $tmp{"special"}) {
	@kwdLoc=split(/,/,$tmp{"special"});
	if ($#kwdLoc>1){
	    foreach $kwd (@kwdLoc){
		$tmp=" "; $tmp=$tmp{$kwd} if (defined $tmp{$kwd});
		$tmp=~s/\n$//;
		$tmpWrt=sprintf ("---   %-15s %-s\n",$kwd,$tmp); 
		push(@scrSpecialLoc,$tmpWrt); } }}
				# ------------------------------
				# general:
				# ------------------------------
    $fstLineLoc= "-" x 80 . "\n";
    $fstLineLoc.="--- Perl script $scrName.pl (" . $tmp{"sourceFile"} . ")\n";
    $syntaxLoc=  "-" x 80 . "\n";
    $syntaxLoc.= "---    Syntax used to set parameters by command line:\n";
    $syntaxLoc.= "---       'keyword=value'\n";
    $syntaxLoc.= "---    where 'keyword' is one of the following keywords:\n";
	
				# ------------------------------
				# no input
    if ($#ARGV < 1) {		# ------------------------------
	print $fstLineLoc;
	print join("\n",@scrTask,"\n");
	print @scrHelpTxtLoc;
	print join("\n",@scrHelp); print "\n";
	return(1,"fin");}
				# ------------------------------
				# help request
				# ------------------------------
    elsif ($#ARGV < 2 && $ARGV[1] =~ /^(help|man|-m|-h)$/){
	print $fstLineLoc;
	print join("\n",@scrTask,"\n");
	print @scrHelpTxtLoc;
	if ($#scrSpecialLoc > 0) {
	    print "-" x 80,"\n"; 
	    print "---    'special' keywords:\n"; 
	    print @scrSpecialLoc,"\n"; }
        if (defined %par) {
	    @kwdLoc=sort keys (%par);
	    if ($#kwdLoc>1){
		print $syntaxLoc;
		$ct=0;print "OPT \t ";
		foreach $kwd(@kwdLoc){
		    ++$ct;
		    printf "%-20s ",$kwd;
		    if ($ct==4){
			$ct=0;print "\nOPT \t ";}}
		print "\n";}
            print 
                "--- \n",
                "---    you may get further explanations on a particular keyword\n",
                "---    by typing:\n",
                $tmp{"scrName"}.".pl help keyword\n",
                "---    this could explain the key.  Type 'how' for info on ".
		    "'how,howie,show'.\n",
		    "--- \n";}
        else { 
	    print "--- no other options enabled by \%par\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants manual
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "manual"){
	print $fstLineLoc;
	if (defined $par{"fileHelpMan"} &&  -e $par{"fileHelpMan"}){
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){
		print $_;}close(FHIN);}
	else {
	    print "no manual in \%par{'fileHelpMan'}!!\n";}
	return(1,"fin");}
				# ------------------------------
				# wants hints
				# ------------------------------
    elsif ($#ARGV==1  && $ARGV[1] eq "hints"){
	print $fstLineLoc;
	print "--- Hints for users:\n";$ct=0;
	if (defined $par{"fileHelpHints"} && -e $par{"fileHelpHints"}){
	    open("FHIN",$par{"fileHelpHints"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpHints"};
	    while(<FHIN>){
		print $_; ++$ct;}close(FHIN);}
	if (defined $par{"scrHelpHints"}){
	    @tmp=split(/\n/,$par{"scrHelpHints"});
	    foreach $txt(@tmp){print "--- $txt\n";++$ct;}}
	if ($ct==0){
	    print "--- the only hint to give: try another help option!\n";
            print "---                        sorry ...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants problems
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "problems"){
	print $fstLineLoc;
	print "--- Known problems with script:\n";$ct=0;
	if (defined $par{"fileHelpProblems"} && -e $par{"fileHelpProblems"}){
	    open("FHIN",$par{"fileHelpProblems"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpProblems"};
	    while(<FHIN>){
		print $_; ++$ct;}close(FHIN);}
	if (defined $par{"scrHelpProblems"}){
	    @tmp=split(/\n/,$par{"scrHelpProblems"});
	    foreach $txt(@tmp){print "--- $txt\n";++$ct;}}
	if ($ct==0){
	    print "--- One problem is: there is no problem annotated.\n";
            print "---                 sorry ...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants default settings
				# ------------------------------
    elsif ($#ARGV<2 && $ARGV[1] eq "def"){
	print $fstLineLoc;
        if (defined %par){
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                foreach $kwd(@kwdLoc){
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                print 
                    "--- \n",
                    "---    to get settings for particular keywords use:\n",
                    $scrName,".pl def keyword'\n \n";}}
        else { print "--- no setting defined in \%par\n";
	       print "---                       sorry...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# help for particular keyword
				# ------------------------------
    elsif ($#ARGV>=2 && $ARGV[1] eq "help" ||
	   $#ARGV==1 && $ARGV[1] eq "special"){
	print $fstLineLoc;
	$kwdHelp=$ARGV[2]         if ($#ARGV > 1); 
	$kwdHelp=$ARGV[1]         if ($#ARGV== 1); 
	$tmp="help $kwdHelp";	# special?
	$tmp=~tr/[A-Z]/[a-z]/;	# make special keywords case independent 
        $tmp2=$tmp;$tmp2=~s/help //;
	$tmpSpecial=$tmp{"$tmp"}  if (defined $tmp{"$tmp"});
	$tmpSpecial=$tmp{"$tmp2"} if (! defined $tmp{"$tmp"} && defined $tmp{"$tmp2"});

        $#kwdLoc=$#expLoc=0;    # (1) get all respective keywords
        if (defined %par && $kwdHelp ne "special"){
            @kwdLoc=keys (%par);$#tmp=0;
            foreach $kwd (@kwdLoc){
                push(@tmp,$kwd) if ($kwd =~/$kwdHelp/i);
	    }
            @kwdLoc=sort @tmp;}
                                # (2) is there a 'help option file' ?
        if (defined $par{"fileHelpOpt"} && -e $par{"fileHelpOpt"} && 
	    $kwdHelp ne "special"){
	    print $syntaxLoc;
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){
		next if ($_=~/^\#/);
		$line=$_;
		$tmp=$_;$tmp=~s/\s//g;
		next if (length($tmp)<2);
		next if ($_=~/^\s/ && ! $Lok);	   
		if    ($Lok && $_=~/^\s/){
		    print $_;
		    next;}
		elsif ($Lok && $_!~/^\s/){
		    $Lok=0;}
		if (! $Lok && $_ !~ /^[\s\t]+/){
		    $line=$_;
		    ($tmp1,$tmp2)=split(/[\s\t]+/,$_);
		    $Lok=1 if (length($tmp1)>1 && $tmp1 =~ /$kwdHelp/i);
		    print $line if ($Lok);}}close(FHIN);
	    print "-" x 80, "\n";}
				# (4) else: read itself
        elsif ($kwdHelp ne "special"){
            ($Lok,$msg,%def)=
		&brIniHelpRdItself($tmp{"sourceFile"});
            die '.....   verrry sorry the option blew up ... ' if (! $Lok);
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
            @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
            foreach $kwd (@kwdLoc){
                next if ($kwd !~/$kwdHelp/i && $kwdHelp !~ /$kwd/i );
		push(@tmp,$kwd); 
		if (defined $def{$kwd}){
		    $def{$kwd}=~s/\n[\t\s]*/\n---                        /g;
		    push(@expLoc,$def{$kwd});}
		else {push(@expLoc," ");}}
            @kwdLoc=@tmp;}
	$Lerr=1;
        if ($#kwdLoc>0){        # (4) write the stuff
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            printf "--- %-20s   %-s\n","keyword","explanation";
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            foreach $it(1..$#kwdLoc){
                $tmp=" "; $tmp=$expLoc[$it] if (defined $expLoc[$it]);
                printf "--- %-20s   %-s\n",$kwdLoc[$it],$tmp;}
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            print "--- \n";$Lerr=0;}

				# (5) special help?
	if (defined $tmpSpecial || 
	    ($kwdHelp eq "special" && defined $tmp{"special"})){
            print  "---    Special help for '$kwdHelp':\n";
	    if ($kwdHelp eq "special"){
		print @scrSpecialLoc,"\n";}
	    else {
		foreach $scrSpecialLoc (@scrSpecialLoc) {
#		    $scrSpecialLoc=~s/\n$//;
		    next if ($scrSpecialLoc !~ /$kwdHelp/);
		    print "$scrSpecialLoc";}
		print "\n";}
	    $Lerr=0;
	    return(1,"fin") if ($kwdHelp eq "special");}
	print "--- sorry, no explanations found for keyword '$kwdHelp'\n" if ($Lerr);
	return(1,"fin loop?");}
				# ------------------------------
				# wants settings for keyword
				# ------------------------------
    elsif ($#ARGV>=2  && $ARGV[1] eq "def"){
	$kwdHelp=$ARGV[2];
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
        if (defined %par){
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                foreach $kwd(@kwdLoc){
                    next if ($kwd !~ /$kwdHelp/i);
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                print  " \n";}}
	else { print "--- sorry, no setting defined in \%par\n";}
	return(1,"fin loop?");}

    return(1,"ok $sbrName");
}				# end of brIniHelp

#==============================================================================
sub brIniHelpLoop {
    local($promptLoc,%tmp)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelpLoop               loop over help 
#       in/out:                 see brIniHelp
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniHelpLoop";$fhinLoc="FHIN_"."brIniHelpLoop";

    ($Lok,$msg)=		# want help?
	&brIniHelp(%tmp);       
                                return(&errSbrMsg("after brIniHelp",$msg)) if (! $Lok);
				# ------------------------------
				# loop over help
				# ------------------------------
    if ($msg =~ /^fin loop/) {
	$#tmp=0;
	foreach $txt (@scrHelpLoop) { $txt=~s/^.*\.pl\s*//g;
				      push(@tmp,$txt); }
	@scrHelpLoop2=@tmp;
	
	$Lquit=0; 
	$def="help"; 
	while (! $Lquit) {
	    printf "%-s %-s\n",      $promptLoc,"-" x (79 - length($promptLoc));
	    printf "%-s %-15s %-s\n",$promptLoc,"",              "Interactive help";
	    printf "%-s %-15s %-s\n",$promptLoc,"OPTIONS","";
	    foreach $txt (@scrHelpLoop2) { 
		printf "%-s %-15s %-s\n",$promptLoc," ",$txt; }
	    printf "%-s %-15s %-s\n",$promptLoc,"","";
	    printf "%-s %-15s %-s\n",$promptLoc,"ABBREVIATIONS", "h=help, d=def (e.g. 'h kwd')";
	    printf "%-s %-15s %-s\n",$promptLoc,"ENOUGH ?",      "[quit|q|e|exit] to end";

	    $def="$ARGV[1]"     if (defined $def);   # take previous
		
	    $ansr=
		&get_in_keyboard("type",$def,$promptLoc);

				# <--- QUIT
	    $tmp=$ansr;$tmp=~s/\s//g;
	    if ($ansr=~/^[q|quit|e|exit]$/) { 
		$Lquit=1; 
		last; }
				# redefine @ARGV
	    @ARGV=split(/\s+/,$ansr);
	    $ARGV[1]="help"     if ($ARGV[1] eq "h" || $ARGV[1] eq "H");
	    $ARGV[1]="def"      if ($ARGV[1] eq "d" || $ARGV[1] eq "D");

	    $txt1="start again with(";
	    $txt2=join(' ',@ARGV);
	    $lenfin=80 - 6 - (length($txt1) + length($txt2));
	    print "--- ","-" x length($txt1),"#" x length($txt2),"--", "-" x $lenfin,"\n";
	    print "--- ",$txt1,$txt2,")\n";
	    print "--- ","-" x length($txt1),"#" x length($txt2),"--", "-" x $lenfin,"\n";

				# call again
	    ($Lok,$msg)=
		&brIniHelp(%tmp); return(&errSbrMsg("after brIniHelp",$msg)) if (! $Lok);
				# <--- QUIT
	    $Lquit=1            if ($msg eq "fin");
	} 
	$msg="fin";
    }
    return(1,$msg);
}				# end of brIniHelpLoop

#===============================================================================
sub brIniHelpRdItself {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelpRdItself           reads the calling perl script (scrName),
#                               searches for 'sub\siniDef', and gets comment lines
#       in:                     perl-script-source
#       out:                    (Lok,$msg,%tmp), with:
#                               $tmp{"kwd"}   = 'kwd1,kwd2'
#                               $tmp{"$kwd1"} = explanations for keyword 1
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniHelpRdItself";$fhinLoc="FHIN_"."brIniHelpRdItself";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n") if (! $Lok);
                                # read file
    while (<$fhinLoc>) {        # search for initialising subroutine
        last if ($_=/^su[b] iniDef.* \{/);}
    $Lis=0; $#tmp=0;
    undef %tmp;
    while (<$fhinLoc>) {        # read lines with '   %par{"kwd"}= $val  # comment '
        $_=~s/\n//g;
        last if ($_=~/^su[b] .*\{/ && $_!~/^su[b] iniDef.* \{/);
				# new expression 
        if    ($_=~/[\s\t]+\$par\{[\"\']?([^\"\'\}]+)[\"\']?\}[^\#]*\#\s*(.*)$/){
            $Lis=1;$kwd=$1; push(@tmp,$kwd); 
	    $tmp{$kwd}=$2 if (defined $2);}
				# end if only '------' line
        elsif ($Lis && defined $tmp{$kwd} && $_=~/^[\s\t]+\# ?\-+/){
            $Lis=0;}
				# add to previous (only if it had an explanation)
        elsif ($Lis && defined $tmp{$kwd} && $_=~/^[\s\t]*\# (.*)$/){
            $tmp{$kwd}.="\n".$1;}
				# end if nothing followed
        elsif ($Lis){
            $Lis=0;}}close($fhinLoc);
    $tmp{"kwd"}=join(',',@tmp);
    return(1,"ok $sbrName",%tmp);
}				# end of brIniHelpRdItself

#==============================================================================
sub brIniSet {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniSet                    changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniSet";
    @kwd=sort keys(%par) if (defined %par && %par);
				# ------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwd){
        if (defined $kwd && length($kwd)>=1 && defined $par{$kwd}){
            push(@tmp,$kwd);}
	else { print "-*- WARN $sbrName: for kwd '$kwd', par{kwd} not defined!\n";}}
    @kwd=@tmp;
				# jobId
    $par{"jobid"}=$$ 
	if (! defined $par{"jobid"} || $par{"jobid"} eq 'jobid' || length($par{"jobid"})<1);
				# ------------------------------
				# add jobid
    foreach $kwd (@kwd){
	$par{$kwd}=~s/jobid/$par{"jobid"}/;}
                                # ------------------------------
                                # WATCH it for file lists: add dirIn
    if (defined $par{"dirIn"} && $par{"dirIn"} ne "unk" && $par{"dirIn"} ne "local" 
        && length($par{"dirIn"})>1){
	foreach $fileIn(@fileIn){
	    $fileIn=$par{"dirIn"}.$fileIn if (! -e $fileIn);
	    if (! -e $fileIn){ print "*** $sbrName: no fileIn=$fileIn, dir=",$par{"dirIn"},",\n";
			       return(0);}}} 
    $#kwdFileOut=0;		# ------------------------------
    foreach $kwd (@kwd){	# add 'pre' 'title' 'ext' to output files not specified
	next if ($kwd !~ /^fileOut/);
	push(@kwdFileOut,$kwd);
	next if (defined $par{$kwd} && $par{$kwd} ne "unk" && length($par{$kwd})>0);
	$kwdPre=$kwd; $kwdPre=~s/file/pre/;  $kwdExt=$kwd; $kwdExt=~s/file/ext/; 
	$pre="";$pre=$par{"$kwdPre"} if (defined $par{"$kwdPre"});
	$ext="";$ext=$par{"$kwdExt"} if (defined $par{"$kwdExt"});
	if (! defined $par{"title"} || $par{"title"} eq "unk"){
	    $par{"title"}=$scrName;$par{"title"}=~tr/[a-z]/[A-Z]/;} # capitalize title
	$par{$kwd}=$pre.$par{"title"}.$ext;}
				# ------------------------------
				# add output directory
    if (defined $par{"dirOut"} && $par{"dirOut"} ne "unk" && $par{"dirOut"} ne "local" 
        && length($par{"dirOut"})>1){
	if (! -d $par{"dirOut"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirOut"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirOut"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print 
		"*** $sbrName failed making directory '",
		$par{"dirOut"},"'\n" if (! $Lok);}
				# add slash
	$par{"dirOut"}.="/"     if (-d $par{"dirOut"} && $par{"dirOut"} !~/\/$/);
	foreach $kwd (@kwdFileOut){
	    next if ($par{$kwd} =~ /^$par{"dirOut"}/);
	    next if ($par{$kwd} eq "unk" || ! $par{$kwd});
	    $par{$kwd}=$par{"dirOut"}.$par{$kwd} if (-d $par{"dirOut"});}}
				# ------------------------------
				# push array of output files
    $#fileOut=0 if (! defined @fileOut);
    foreach $kwd (@kwdFileOut){
	push(@fileOut,$par{$kwd});}
				# ------------------------------
				# temporary files: add work dir
    if (defined $par{"dirWork"} && $par{"dirWork"} ne "unk" && $par{"dirWork"} ne "local" 
	&& length($par{"dirWork"})>1) {
	if (! -d $par{"dirWork"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirWork"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirWork"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print "*** $sbrName failed making directory '",$par{"dirWork"},"'\n" if (! $Lok);}
	$par{"dirWork"}.="/" if (-d $par{"dirWork"} && $par{"dirWork"} !~/\/$/); # add slash
	foreach $kwd (@kwd){
	    next if ($kwd !~ /^file/);
	    next if ($kwd =~ /^file(In|Out|Help|Def)/i);
            $par{$kwd}=~s/jobid/$par{"jobid"}/ ;
	    next if ($par{$kwd} =~ /^$par{"dirWork"}/);
	    $par{$kwd}=$par{"dirWork"}.$par{$kwd};}}
				# ------------------------------
				# blabla
    $Lverb=1  if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=1 if (defined $par{"verb2"}   && $par{"verb2"});
    $Lverb3=1 if (defined $par{"verb3"}   && $par{"verb3"});
				# ------------------------------
				# add ARCH
    if (defined $ARCH || defined $par{"ARCH"}){
	$ARCH=$par{"ARCH"}      if (! defined $ARCH &&   defined $par{"ARCH"});
	$par{"ARCH"}=$ARCH      if (  defined $ARCH && ! defined $par{"ARCH"});
	foreach $kwd (@kwd){	# add directory to executables
	    next if ($kwd !~ /^exe/);
	    next if ($par{$kwd} !~ /ARCH/);
	    $par{$kwd}=~s/ARCH/$ARCH/;}}

				# ------------------------------
    foreach $kwd (@kwd){	# add directory to executables
	next if ($kwd !~/^exe/);
	next if (-e $par{$kwd} || -l $par{$kwd});
				# try to add perl script directory
	next if (! defined $par{"dirPerl"} || ! -d $par{"dirPerl"});
	next if ($par{$kwd}=~/$par{"dirPerl"}/); # did already, no result
	$tmp=$par{"dirPerl"}; $tmp.="/" if ($tmp !~ /\/$/);
	$tmp=$tmp.$par{$kwd};
	next if (! -e $tmp && ! -l $tmp);
	$par{$kwd}=$tmp; }

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

    return(1);
}				# end of brIniSet

#==============================================================================
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
	    $exclLoc{"$tmp"}=1; }
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

#==============================================================================
sub copf2fasta {
    local($exeCopfLoc,$exeConvertSeqLoc,$extrLoc,$titleLoc,$extLoc,$dirWorkLoc,
	  $fileOutScreenLoc,$fhSbrErr,@fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   copf2fasta                  runs copf.pl converting all input files to FASTA
#       in:                     $exeCopf       : perl script copf.pl          if = 0: default
#       in:                     $exeConvertSeq : FORTRAN exe convert_seq
#       in:                     $extrLoc       : number of file to extract from FASTAmul ..
#                                                                             if = 0: 1
#       in:                     $titleLoc      : title for temporary files    if = 0: 'TMP-$$'
#       in:                     $extLoc        : extension of output files    if = 0: '.fasta'
#       in:                     $dirWorkLoc    : working dir (for temp files) if = 0: ''
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       in:                     @fileInLoc     : array of input files
#       out:                    1|0,msg,@fileWritten
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."copf2fasta";$fhinLoc="FHIN_"."copf2fasta";
                                # ------------------------------
				# local defaults
    $exeCopfLocDef=             "/home/rost/perl/scr/copf.pl";

    if (defined $ARCH) {
	$ARCHTMP=$ARCH; }
    else {
	print "-*- WARN $sbrName: no ARCH defined set it!\n";
	$ARCHTMP=$ENV{'ARCH'} || "SGI64"; }

    $exeConvLocDef=             "/home/rost/pub/bin/convert_seq.".$ARCHTMP;

                                # ------------------------------
				# check arguments
    $exeCopfLoc=$exeCopfLocDef  if (! defined $exeCopfLoc || ! $exeCopfLoc);
    $exeConvertSeqLoc=$exeConvLocDef 
	                        if (! defined $exeConvertSeqLoc || ! $exeConvertSeqLoc);
    $extrLoc=1                  if (! defined $extrLoc || ! $extrLoc);
    $titleLoc=  "TMP-".$$       if (! defined $titleLoc && ! $titleLoc);
    $extLoc=  ".fasta"          if (! defined $extLoc && ! $extLoc);
    $dirWorkLoc=  ""            if (! defined $dirWorkLoc && ! $dirWorkLoc);
    $dirWorkLoc.="/"            if ($dirWorkLoc !~/\/$/ && length($dirWorkLoc)>=1);
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $#fileTmp=0;
    $cmdSys="";
				# ------------------------------
				# loop over input files
				# ------------------------------
    foreach $fileLoc (@fileInLoc) {
	if (! -e $fileLoc){	# file missing
	    print $fhSbrErr 
		"-*- WARN $sbrName: missing file=$fileLoc\n";
	    next; }
				# already FASTA format
	if (&isFasta($fileLoc) && ! ($extrLoc && &isFastaMul($fileLoc)) ){
	    push(@fileTmp,$fileLoc);
	    next; }
	$idIn=$fileLoc;$idIn=~s/^.*\/|\..*$//g;
				# ------------------------------
				# ... else RUN copf
	$fileOutTmp=$dirWorkLoc.$titleLoc.$idIn.$extLoc;

	$cmd= $exeCopfLoc." $fileLoc fasta extr=$extrLoc "."exeConvertSeq=".$exeConvertSeqLoc;
	$cmd.=" fileOut=$fileOutTmp";
	eval "\$cmdSys=\"$cmd\"";
	($Lok,$msg)=
	    &sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
	return(&errSbrMsg("failed convert $fileIn to FASTA ($fileOutTmp)",$msg)) 
	    if (! $Lok || ! -e $fileOutTmp);
	push(@fileTmp,$fileOutTmp);
    }
    return(1,"ok $sbrName",@fileTmp);
}				# end of copf2fasta

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

#==============================================================================
sub fastaRdMul {
    local($fileInLoc,$rd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdMul                  reads many sequences in FASTA db
#       in:                     $fileInLoc,$rd with:
#                               $rd = '1,5,6',   i.e. list of numbers to read
#                               $rd = 'id1,id2', i.e. list of ids to read
#                               NOTE: numbers faster!!!
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaRdMul";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    undef %tmp;
    if (! defined $rd) {
	$LisNumber=1;
	$rd=0;}
    elsif ($rd !~ /[^0-9\,]/){ 
	@tmp=split(/,/,$rd); 
	$LisNumber=1;
	foreach $tmp(@tmp){$tmp{$tmp}=1;}}
    else {$LisNumber=0;
	  @tmp=split(/,/,$rd); }
    
    $ct=$ctRd=0;
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){ # line with id
	    ++$ct;$Lread=0;
	    last if ($rd && $ctRd==$#tmp); # fin if all found
	    next if ($rd && $LisNumber && ! defined $tmp{$ct});
	    $id=$1;$id=~s/\s\s*/ /g;$id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    $Lread=1 if ( ($LisNumber && defined $tmp{$ct})
			 || $rd == 0);

	    if (! $Lread){	# go through all ids
		foreach $tmp(@tmp){
		    next if ($tmp !~/$id/);
		    $Lread=1;	# does match, so take
		    last;}}
	    next if (! $Lread);

	    ++$ctRd;
	    $tmp{"$ctRd","id"}=$id;
	    $tmp{"$ctRd","seq"}="";}
	elsif ($Lread) {	# line with sequence
	    $tmp{"$ctRd","seq"}.="$_";}}

    $seq=$id="";		# join to long strings
    foreach $it (1..$ctRd) { $id.= $tmp{"$it","id"}."\n";
			     $tmp{"$it","seq"}=~s/\s//g;
			     $seq.=$tmp{"$it","seq"}."\n";}
    $#tmp=0;			# save memory
    undef %tmp;			# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdMul

#==============================================================================
sub fastaWrt {
    local($fileOutLoc,$id,$seqLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrt                    writes a sequence in FASTA format
#       in:                     $fileOut,$id,$seq (one string)
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrt";$fhoutLoc="FHOUT_"."$sbrName";
#    print "yy into write seq=$seqLoc,\n";

    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");
    print $fhoutLoc ">$id\n";
    for($it=1;$it<=length($seqLoc);$it+=50){
	foreach $it2 (0..4){
	    last if (($it+10*$it2)>=length($seqLoc));
	    printf $fhoutLoc " %-10s",substr($seqLoc,($it+10*$it2),10);}
	print $fhoutLoc "\n";}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of fastaWrt

#==============================================================================
sub fctRunTimeLeft {
    local($timeBegLoc,$num_to_run,$num_did_run) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeLeft              estimates the time the job still needs to run
#       in:                     $timeBegLoc : time (time) when job began
#       in:                     $num_to_run : number of things to do
#       in:                     $num_did_run: number of things that are done, so far
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fctRunTimeLeft";

    $timeNow=time;
    $timeRun=$timeNow-$timeBegLoc;

    $percLoc=0;
    $percLoc=100*($num_did_run/$num_to_run) if ($num_to_run > 0);

    if ($percLoc) {
	$timeTot=int(100*($timeRun/$percLoc));
	$timeLeft=$timeTot-$timeRun;
	$tmp=
	    &fctSeconds2time($timeLeft); 
	@tmp=split(/:/,$tmp); foreach $tmp (@tmp){$tmp=~s/^0//g;}
	$estimateLoc= "";
	$estimateLoc.=    $tmp[1]."h " if ($tmp[1] > 9);
	$estimateLoc.=" ".$tmp[1]."h " if (9 >= $tmp[1] && $tmp[1] > 0);
	$estimateLoc.=    $tmp[2]."m " if ($tmp[2] > 9);
	$estimateLoc.=" ".$tmp[2]."m " if (9 >= $tmp[2] && $tmp[2] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[2] <= 0 && $tmp[1] > 0);
	$estimateLoc.=    $tmp[3]."s " if ($tmp[3] > 9);
	$estimateLoc.=" ".$tmp[3]."s " if (9 >= $tmp[3] && $tmp[3] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[3] <= 0 && ($tmp[1] > 0 || $tmp[2] > 0));
	$estimateLoc= "done"        if (length($estimateLoc) < 1);}
    else {
	$estimateLoc="?";}
    return($estimateLoc);
}				# end of fctRunTimeLeft

#==============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#==============================================================================
sub get_in_keyboard {
    local($des,$def,$pre,$Lmirror)=@_;local($txt);
#--------------------------------------------------------------------------------
#   get_in_keyboard             gets info from keyboard
#       in:                     $des :    keyword to get
#       in:                     $def :    default settings
#       in:                     $pre :    text string beginning screen output
#                                         default '--- '
#       in:                     $Lmirror: if true, the default is mirrored
#       out:                    $val : value obtained
#--------------------------------------------------------------------------------
    $pre= "---"                 if (! defined $pre);
    $Lmirror=0                  if (! defined $Lmirror || ! $Lmirror);
    $txt="";			# ini
    printf "%-s %-s\n",          $pre,"-" x (79 - length($pre));
    printf "%-s %-15s:%-s\n",    $pre,"type value for",$des; 
    if (defined $def){
	printf "%-s %-15s:%-s\n",$pre,"type RETURN to enter value, or to keep default";
	printf "%-s %-15s>%-s\n",$pre,"default value",$def;}
    else {
	printf "%-s %-15s>%-s\n",$pre,"type RETURN to enter value"; }

    $txt=$def                    if ($Lmirror);	# mirror it
    printf "%-s %-15s>%-s",      $pre,"type",$txt; 

    while(<STDIN>){
	$txt.=$_;
	last if ($_=~/\n/);}     $txt=~s/^\s+|\s+$//g;
    $txt=$def                   if (length($txt) < 1);
    printf "%-s %-15s>%-s\n",    $pre,"--> you chose",$txt;
    return ($txt);
}				# end of get_in_keyboard

#==============================================================================
sub is_dssp {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp                     checks whether or not file is in DSSP format
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    return (0) if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_DSSP";
    open($fh,$fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1
	    if ($_=~/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i);
	last; }
    close($fh);
    return $Lis;
}				# end of is_dssp

#==============================================================================
sub isFasta {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFasta                     checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    &open_file("$fhinLoc2","$fileLoc") || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s|\n//g            if (defined $two);
    close($fhinLoc2);

    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if (($one =~ /^\s*>\s*\w+/) && 
				    $two !~/[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_!]/);
    return(0);
}				# end of isFasta

#==============================================================================
sub isFastaMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#                               (first line /^>\w/, second (non white) = AA *2 
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    &open_file("$fhinLoc2","$fileLoc") || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s//g               if (defined $two);

    return (0)                  if (! defined $two || ! defined $one);
    return (0)                  if (($one !~ /^\s*\>\s*\w+/) || 
				    ($two =~ /[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_!]/i));
    $Lok=0;
    while (<$fhinLoc2>) {next if ($_ !~ /^\s*>\s*\w+/);
			 $Lok=1;
			 last;}close($fhinLoc2);
    return($Lok);
}				# end of isFastaMul

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
    if    (! -e $exeMaxLoc)    {$msg.="$pre"."$exeMaxLoc=    for exe\n";}
    elsif (! -e $fileDefLoc)   {$msg.="$pre"."$fileDefLoc=   default file\n";}
    elsif (! -e $fileMaxIn)    {$msg.="$pre"."$fileMaxIn=    query seq\n";}
    elsif (! -e $fileMaxList)  {$msg.="$pre"."$fileMaxList=  ali DB\n";}
    elsif (! -e $fileMaxMetric){$msg.="$pre"."$fileMaxMetric=metric\n";}
    return ($msg,$warn);
}				# end maxhomGetArgCheck

#==============================================================================
sub maxhomGetThresh {
    local($ideIn)=@_;
    local($tmp,$thresh_txt);
    $[ =1 ;
#----------------------------------------------------------------------
#   maxhomGetThresh             translates cut-off ide into text input for MAXHOM csh
#       in:                     $ideIn (= distance to FORMULA, old)
#       out:                    $txt 'FORMULA+/-n'
#----------------------------------------------------------------------
				# final txt for MAXHOM cshell (FORMULA,FORMULA-n,FORMULA+n)
    if   ($ideIn>25) {
	$tmp=$ideIn-25;
	$thresh_txt="FORMULA+"."$tmp"; }
    elsif($ideIn<25) {
	$tmp=25-$ideIn;
	$thresh_txt="FORMULA-"."$tmp"; }
    else {
	$thresh_txt="FORMULA"; }
    return($thresh_txt);
}				# end of maxhomGetThresh

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
    return(0,"*** $sbrName: miss input file '$fileHsspInLoc'!")  if (! -e $fileHsspInLoc);
    return(0,"*** $sbrName: miss input exe  '$exeMaxLoc'!")      if (! -e $exeMaxLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxDefLoc'!")  if (! -e $fileMaxDefLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxMetrLoc'!") if (! -e $fileMaxMetrLoc);
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
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------
    @tmp=("/home/rost/perl/ctime.pl","/home/rost/pub/perl/ctime.pl");
				# ------------------------------
				# get function
    if (defined &localtime) {
	foreach $tmp(@tmp){
	    if (-e $tmp){$Lok=require("$tmp");
			 last;}}
	if (defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#	    print "xx enter\n";
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);}
    }
				# ------------------------------
				# or get system time
    $localtime=`date`;
    @Date=split(/\s+/,$localtime);
    $Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]";
    return($Date);
}				# end of sysDate

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



#==============================================================================
# library collected (end) lll
#==============================================================================


#===============================================================================
sub iniMaxhom {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniMaxhom                    initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."iniMaxhom";

				# ------------------------------
    foreach $arg (@ARGV){	# highest priority ARCH
	if    ($arg=~/ARCH=(.*)$/)      {$ARCH=$ENV{'ARCH'}=$1;}
	elsif ($arg=~/PWD=(.*)$/)       {$PWD=              $1;} 
    }
    $ARCH=$ARCH || $ENV{'ARCH'} || "SGI32";

    $PWD= $PWD || $ENV{'PWD'};
    if (! defined $PWD){
	$PWD=`pwd`;
	$PWD=~s/\s//g;}
    $PWD=~s/\/$//              if ($PWD=~/\/$/);
    $pwd= $PWD                 if (defined $PWD);
    $pwd.="/"                  if (defined $pwd && $pwd !~ /\/$/);

				# ------------------------------
				# first settings for parameters 
    &iniDefMaxhom();
				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();
				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,
		       %tmp);   return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 

				# ------------------------------
				# read command line
    ($Lok,$msg)=
	&iniRdCmdLine();        return(&errSbrMsg("after iniRdCmcLine",$msg,$SBR)) if (! $Lok);

				# correct psi blast 
    if ($par{"doBlast3"} && $par{"parBlastDb"} ne $par{"dbBig"}){
	print "*-* WARN changed database for running PSI-BLAST you want 'big'!!!\n" x 10;
	$par{"parBlastDb"}=   $par{"dbBig"};
    }
                                                  
				# ------------------------------
				# final settings
    ($Lok,$msg)=
	&iniSet();              return(&errSbrMsg("after iniSet",$msg,$SBR)) if (! $Lok);

				# ------------------------------
                                # check errors
                                # to exclude from error check
    $exclude="exe,fileDefaults,";
        
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n",$msg)) if (! $Lok);  

                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0 && ! $par{"debug"} ) {
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($par{"verbose"});
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$par{"fileOutTrace"}=0;
	$fhTrace="STDOUT";}
    $par{"fileOutScreen"}=0     if ($par{"debug"});

				# ------------------------------
				# set priority
				# ------------------------------
    if ($par{"optNice"}=~/^nice\s*-/ || 
	$par{"optNice"}=~/^[\-0-9]+$/) { 
	$par{"optNice"}=~s/nice-/nice -/;
	$tmp=$par{"optNice"};$tmp=~s/\s|nice|\-|\+//g;
	setpriority(0,0,$tmp) if (length($tmp)>0);}
    

				# ------------------------------
				# write settings
				# ------------------------------
    if ($par{"verbose"}){
	$exclude="kwd,dir*,ext*"; # keyword not to write
	$fhloc="STDOUT";
	$fhloc=$fhTrace         if (! $par{"debug"});
	($Lok,$msg)=
	    &brIniWrt($exclude,$fhloc);
	                        return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR))  if (! $Lok); }

    return(1,"ok $sbrName");
}				# end of iniMaxhom

#===============================================================================
sub iniDefMaxhom {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefMaxhom                 initialise defaults
#-------------------------------------------------------------------------------
                                # d.d
				# --------------------
				# directories
    $par{"dirMax"}=             "/usr/pub/molbio/maxhom/";      # MAXHOM central
    $par{"dirMax"}=             $par{"dirHome"}. "max/";        # MAXHOM central
    $par{"dirMaxMat"}=          $par{"dirMax"}.  "mat/";        # MAXHOM utilities
    $par{"dirBinMax"}=          $par{"dirMax"}.  "bin/";        # FORTRAN binaries of programs needed
    $par{"dirScrMax"}=          $par{"dirMax"}.  "scr/";        # scripts needed for maxhom

    $par{"dirPerlScr"}=         "/usr/pub/molbio/perl/";        # perl scripts needed
    $par{"dirPerlScr"}=         $par{"dirMax"}."scr/"; 
    $par{"dirPubMolbio"}=       "/usr/local/molbio/perl/";      # dariusz perl scripts needed for PSI-BLAST

    $par{"dirBinMolbio"}=       $par{"dirBinMax"};              # FORTRAN binaries of programs needed

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory

    $par{"dirData"}=            "/data/";
    $par{"dirDataBlast"}=       $par{"dirData"}.      "blast/";

    $par{"dbPdb"}=              $par{"dirDataBlast"}. "pdb";
    $par{"dbSwiss"}=            $par{"dirDataBlast"}. "swiss";
    $par{"dbTrembl"}=           $par{"dirDataBlast"}. "trembl";
    $par{"dbBig"}=              $par{"dirDataBlast"}. "big";

    $par{"dbLocipro"}=          $par{"dirDataBlast"}."loci-proka";
    $par{"dbLocieuk"}=          $par{"dirDataBlast"}."loci-euka";

    $par{"dbProdom"}=           $par{"dirDataBlast"}."prodom_99_1";
    $par{"dbPhd"}=              $par{"dirDataBlast"}."phd1194";
    $par{"dbPhd126"}=           $par{"dirDataBlast"}."phd126";

                                # further on work
				# --------------------
				# files
    $par{"title"}=              "unk";                           # output files will be called 'Pre-title.ext'
    $par{"titleTmp"}=           "MaxHom-";                       # title for temporary files

    $par{"fileOut"}=            0;
#    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE-"."jobid".".tmp"; # file tracing warnings and errors
#    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN-"."jobid".".tmp"; # file for running system commands

    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE".$$. ".tmp"; # file tracing warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN".$$. ".tmp"; # file for running system commands
    $par{"fileOutStderr"}=      $par{"titleTmp"}."STDERR".$$. ".tmp"; # file for running system commands

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
				# file extensions
    $par{"extHssp"}=            ".hssp";
    $par{"extHsspFil"}=         ".hsspFil";
    $par{"dirOutHssp"}=         0;
    $par{"dirOutHsspFile"}=     0;
    $par{"extBlastp"}=          ".blastp";
    $par{"extBlast3"}=          ".blast3";
    $par{"extFasta"}=           ".fasta";

				# file handles
#    $fhout=                     "FHOUT";
#    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";

                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=            1; # blabla on screen
    $par{"verb2"}=              0; # more verbose blabla

    $par{"optNice"}=            "nice -15";

    $par{"keepBlast"}=          0; # =1 -> do NOT delete blast
    $par{"keepBlastFil"}=       0; # =1 -> do NOT delete filter-blast
    $par{"keepHsspRaw"}=        1; # =1 -> the unfiltered HSSP file will be kept
				# --------------------
				# parameters BLAST
    $par{"BLASTMAT"}=           "/data/blast/blastp/blastapp/matrix";  # env for BLASTP
    $par{"BLASTDB"}=            "/data/blast";                    # env for BLASTP
    $par{"BLASTDB"}=            "/data/swissprot/swiss"; # 

    $par{"doBlastp"}=           1; # if 1: runs BLASTP as pre-filter
    $par{"doBlast3"}=           0; # if 1: runs PSI-BLAST as pre-filter

    $par{"parBlastE"}=       1000;
    $par{"parBlastV"}=       2000;
    $par{"parBlastB"}=       2000;
    $par{"parBlastDb"}=         $par{"dbSwiss"};
    $par{"argBlast"}=           0;  # provide full argument, e.g. 'E=1000 B=2000 -olfraction 0.25'
    $par{"parBlastFilterMaxP"}= ""; # filter the BLAST list with values p < this

				# --------------------
				# parameters MaxHom
    $par{"doSelf"}=             0; # if 1: runs sequence against itself -> no ali
    $par{"doDirect"}=           0; # if 1: no pre-filter by BLAST, but directly MaxHom against DB

    $par{"parMaxhomDis"}=       5; # minimal distance from HSSP curve
				   #       for FORTRAN program Maxhom -> old thresholds!
				   #       -> 0 = 25% !
    $par{"parMaxhomThresh"}=    0; # minimal sequence identity (dependent on choice of dist)

    $par{"doFilterHssp"}=       1; # if 1: filter the HSSP file
                                          # command for filtering HSSP file:
    $par{"filter"}=             0;
    $par{"filter"}=             "red=70";
    $par{"filter"}=             "mode=ide thresh=4 threshSgi=-10";
    $par{"filter"}=             "mode=ide thresh=5";
				   #       - exclude by position (e.g. excl=1-5,7,9-11,30-*)
				   #       - include by position (e.g. incl=1-5,7,9-11,30-*)
				   #       - include by sequence identity|similarity 
				   #         minIde=x,maxIde=x,
				   #         minSim=x,maxSim=x,
				   #         thresh=x
				   #         threshSgi
				   #         mode=ide|sim|ruleBoth|ruleSgi|old
				   #       - exclude mutually too similar pairs 
				   #         (too redundant alis, red=80, see help red)
                                   #       - combination by e.g.:
                                   #         'thresh=8 threshSgi=-10 mode=ide red=90'
    
    $par{"fileMaxhomDefaults"}= $par{"dirMax"}.          "maxhom.default";
#    $par{"fileMaxhomMetr"}=     $par{"dirMaxMat"}.       "Maxhom_McLachlan.metric";
#    $par{"fileMaxhomMetr"}=     $par{"dirMaxMat"}.       "Maxhom_GCG.metric";
    $par{"fileMaxhomMetr"}=     $par{"dirMaxMat"}.       "Maxhom_Blosum.metric";

				# not implemented!!
#    $par{"fileSwissRelnotes"}=  $par{"dirMaxMat"}.       "relnotes.txt";

    $par{"parMaxhomMaxNres"}=   "5000";      # maximal length of sequence
    $par{"parMaxhomLprof"}=     "NO";        # read profiles?

    				# old from Reinhard  Schneider
#    $par{"parMaxhomSmin"}=     -0.5;         # minimal value in metric
#    $par{"parMaxhomSmax"}=      1.0;         # maximal value in metric
#    $par{"parMaxhomGo"}=        3.0;         # gap open penalty
#    $par{"parMaxhomGe"}=        0.1;         # gap elongation penalty

				# most similar to PSI-BLAST (?: from Dariusz, for blossum)
    $par{"parMaxhomGo"}=       10.0;         # gap open penalty
    $par{"parMaxhomGe"}=        1.0;         # gap elongation penalty
    $par{"parMaxhomSmin"}=     -4.0;         # minimal value in metric
    $par{"parMaxhomSmax"}=     11.0;         # maximal value in metric

    $par{"parMaxhomW1"}=        "YES";       # use weights for guide
    $par{"parMaxhomW2"}=        "NO";        # use weights for aligned
    $par{"parMaxhomI1"}=        "YES";       # allow insertions/deletions for guide
    $par{"parMaxhomI2"}=        "NO";        # allow insertions/deletions for aligned
    $par{"parMaxhomNali"}=   1000;           # number of alignments given in HSSP file
    $par{"parMaxhomSort"}=      "DISTANCE";  # sorting final alignment by distance
    $par{"parMaxhomProfOut"}=   "NO";        # write profiles='yes'
    $par{"parMaxhomStripOut"}=  "NO";        # write strip output file='yes'

    $par{"parMaxhomProfIn2"}=   "NO";        # 2nd file is profile?

    $par{"parMaxhomTimeOut"}=10000;          # secnd ~ 3hrs, then: send alarm MaxHom suicide!

    $par{"parMinLaliPdb"}=     30;           # minimal length of ali to report: 'has 3D homo'


    $par{"isList"}=             0; # assume input file is list of FASTA files, or FASTAmul
    $par{"doNew"}=              1; # overwrite existing BLAST/MaxHom files (i.e. run again)

				# --------------------
				# executables
    $par{"exeCopf"}=            $par{"dirPerlScr"}.      "copf.pl";
    $par{"exeFilterHssp"}=      $par{"dirPerlScr"}.      "hssp_filter.pl";
#    $par{"exeBlastFilter"}=     $par{"dirBinMax"}.       "filter_blastp";
    $par{"exeBlastFilter"}=     $par{"dirScrMax"}.       "filter_blastp_big.pl";

    $par{"exeBinMaxhom"}=       $par{"dirBinMax"}.       "maxhom.ARCH";
#    $par{"exeBinMaxhom"}=       $par{"dirBinMax"}.       "maxhom_big.ARCH";
#    $par{"exeBinMaxhom"}=       "/home/phd/server/bin/maxhom.SGI64";
#    $par{"exeBinMaxhom"}=       "/home/rost/lion/src-lib/maxhom.SGI64";
    $par{"exeBinFilterHssp"}=   $par{"dirBinMax"}.       "filter_hssp.ARCH";
    $par{"exeBinBlastp"}=       $par{"dirBinMolbio"}.    "blastp.ARCH";
    $par{"exeBinBlast3"}=       $par{"dirBinMolbio"}.    "blastall.ARCH";
    $par{"exeBlastDariusz"}=    $par{"dirPubMolbio"}.    "blastpgp.pl";
    $par{"exeBlastDariuszPack"}=$par{"dirPubMolbio"}.    "pack/blastpgp.pm";
    $par{"exeBinConvertSeq"}=   $par{"dirBinMolbio"}.    "convert_seq.ARCH";

    @kwd=sort (keys %par);
    $#fileRm=0;
}				# end of iniDefMaxhom

#===============================================================================
sub iniHelp {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpNet                  specific help settings
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniHelp";
				# standard help
    $tmp=0;
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);

    $tmp{"s_k_i_p"}=         "problems,manual,hints";

#    $tmp{"problems"}=        "when providing the output file name by ";

				# special help
    $tmp{"scrAddHelp"}=      "";

    $tmp{"special"}=         "";
    $tmp{"special"}.=        "list,verb,verb2,verbDbg,";
    $tmp{"special"}.=        "skip,new,blast,filter,thresh,threshSgi,mode,red,";
    $tmp{"special"}.=        "self,dis,direct,";
    foreach $kwd ("swiss","big","trembl","pdb") {
	$tmp{"special"}.=    "$kwd,"      if ($par{"parBlastDb"} !~ /$kwd$/);}
    $tmp{"special"}.=        "db,blastE,blastB,blastV,blastDb,psi,";
    $tmp{"special"}.=        "keepBlast,keepBlastFil,keepHsspRaw,delHsspRaw,";
#    $tmp{"special"}.=        "noblast,";

    $tmp{"special"}=~s/,*$//g;
    $tmp="---                      ";
        
    $tmp{"verb"}=            "OR verbose=1,      i.e. verbose output";
    $tmp{"verb2"}=           "OR verb2=1,        i.e. very verbose output";
    $tmp{"verbDbg"}=         "OR verbDbg=1,      detailed debug info (not automatic)";


    $tmp{"list"}=            "OR isList=1,       i.e. input file is list of files";
    $tmp{"skip"}=            "OR doNew=0         -> will not run again if output file exists";
    $tmp{"new"}=             "OR doNew=1         -> will overwrite existing output file!";

    $tmp{"self"}=            "OR doSelf=1,       -> runs sequence against itself";
    $tmp{"direct"}=          "OR doDirect=1,     -> runs without BLAST (watch CPU!!)";
    $tmp{"dis"}=             "<disN|dis=N|N>     -> run MaxHom with distance N (0=25, -5=20, 5=30)";
    $tmp{"filter"}=          "OR doHsspFilter=1  -> filters HSSP file by:\n";
    $tmp{"filter"}.=    $tmp."   ".$par{"filter"}."\n";
    $tmp{"filter"}.=    $tmp."   ='cmd'          -> runs hssp_filter with 'cmd'\n";
    $tmp{"filter"}.=    $tmp."   e.g.    'excl=1,2-5 incl=5 red=80 minSim=30 minIde=30 threshSgi'";
    $tmp{"filter"}.=    $tmp."   for PHD 'thresh=8 threshSgi=-10 mode=ide red=90'";
    $tmp{"thresh"}=          "thresh=8           -> filters HSSP file with thresh=8";
    $tmp{"threshSgi"}=       "threshSgi=-10      -> filters HSSP file with threshSgi=-10";
    $tmp{"mode"}=            "mode=<ide|sim>     -> filters HSSP based on identity or similarity";
    $tmp{"red"}=             "red=90             -> reduces redundancy in HSSP file by 90%";

    $tmp{"swiss"}=           "OR parBlastDb=swiss -> runs against SWISS-PROT (default)";
    $tmp{"big"}=             "OR parBlastDb=big   -> runs against SWISS+PDB+TREMBL";
    $tmp{"trembl"}=          "OR parBlastDb=trembl-> runs against TREMBL";
    $tmp{"pdb"}=             "OR parBlastDb=pdb   -> runs against PDB";

    $tmp{"blast"}=           "OR doBlastp=1      -> runs BLASTP as prefilter";
    $tmp{"psi"}=             "OR doBlast3=1      -> will run PSI-blast \n";
    $tmp{"psi"}.=       $tmp."   note: default = BLASTP, i.e. blast2\n";

    $tmp{"db"}=              "OR parBlastDb=x    -> set BLAST DB";
    $tmp{"blastDb"}=         "OR parBlastDb=x    -> set BLAST DB";
    $tmp{"blastE"}=          "OR parBlastE=x     -> set BLAST E parameter";
    $tmp{"blastB"}=          "OR parBlastB=x     -> set BLAST B parameter (number of hits)";
    $tmp{"blastV"}=          "OR parBlastV=x     -> set BLAST V parameter (number of hits)";

    $tmp{"keepBlast"}=       "OR keepBlast=1     -> do NOT delete BLAST output";
    $tmp{"keepBlastFil"}=    "OR keepBlastFil=1  -> do NOT delete BLAST-filter list";
    $tmp{"keepHsspRaw"}=     "OR keepHsspRaw=1   -> do NOT overwrite unfiltered HSSP file";
    $tmp{"delHsspRaw"}=      "OR keepHsspRaw=0   -> do overwrite unfiltered HSSP file!";
#    $tmp{"nopre"}=           "                   -> do NOT pre-filte, i.e. NO  BLAST, at all!";

#                            "------------------------------------------------------------\n";
    foreach $kwd (keys %tmp){
	$tmp{$kwd}.="\n";
    }
    return(%tmp);
}				# end of iniHelp

#===============================================================================
sub iniRdCmdLine {
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniRdCmdLine                digests the command line input
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniRdCmdLine";
				# ------------------------------
    $#fileIn=0;			# read command line input standard

    @argUnk=			# standard command line handler
	&brIniGetArg();
				# ------------------------------
				# interpret specific command line arguments
    foreach $arg (@argUnk){
	next if ($arg=~/ARCH=/);
	if    ($arg=~/^fileOut=(.*)$/)        { $par{"fileOut"}=      $1; }
	elsif ($arg=~/^fileHssp=(.*)$/)       { $fileHssp=            $1; } # note: only for 1
	elsif ($arg=~/^fileHsspFil=(.*)$/)    { $fileHsspFil=         $1; } # note: only for 1
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}=      "nice -".$1; }
	elsif ($arg eq "nonice")              { $par{"optNice"}=      " ";}
	elsif ($arg =~ /^de?bu?g$/)           { $par{"debug"}=1;}
        
	elsif ($arg=~/^dirHssp=(.+)$/)        { $par{"dirOutHssp"}=   $1; }
	elsif ($arg=~/^dirHsspFil=(.+)$/)     { $par{"dirOutHsspFil"}=$1; }
        
	elsif ($arg=~/^self$/)                { $par{"doSelf"}=       1;  }
	elsif ($arg=~/^(doDirect|direct)$/i)  { $par{"doDirect"}=     1; }
	elsif ($arg=~/^dist?=?([\-0-9]+)$/)   { $par{"parMaxhomDis"}= $1; }
	elsif ($arg=~/^([\-0-9]+)$/)          { $par{"parMaxhomDis"}= $1; }

	elsif ($arg=~/^skip[A-Za-z]*$/)       { $par{"doNew"}=        0; }
	elsif ($arg=~/^new$/)                 { $par{"doNew"}=        1; }

	elsif ($arg=~/^filter$/)              { $par{"doFilterHssp"}= 1;  }
	elsif ($arg=~/^filter=(.+)$/)         { $par{"doFilterHssp"}= 1;  
						$par{"filter"}=       $1; }
        elsif ($arg=~/^(thresh|threshSgi|mode|red)=(.+)$/) {
            $kwd=$1; $val=$2;
            $par{"doFilterHssp"}= 1;  
            $par{"filter"}=       "" if (! defined $par{"filter"} || ! $par{"filter"});
                                # delete defaults (if there are any)
            $par{"filter"}=~s/$kwd=[\d\-\.a-z]+//g;
            $par{"filter"}.=      " $kwd=$val";}

	elsif ($arg=~/^keepBlast$/i)          { $par{"keepBlast"}=    1;  }
	elsif ($arg=~/^keepBlastFil/i)        { $par{"keepBlastFil"}= 1;  }
	elsif ($arg=~/^keepHsspRaw/i)         { $par{"keepHsspRaw"}=  1;  }
	elsif ($arg=~/^keepHssp/i)            { $par{"keepHsspRaw"}=  1;  }
	elsif ($arg=~/^delHsspRaw/i)          { $par{"keepHsspRaw"}=  0;  }

	elsif ($arg=~/^blast$/)               { $par{"doBlastp"}=     1;  }
	elsif ($arg=~/^psi$/)                 { $par{"doBlast3"}=     1;  
						print "-*- WARN for PSI-BLAST use command line 'big'!!\n"; }
	elsif ($arg=~/^db=(.*)$/)             { $par{"parBlastDb"}=   $1; }
	elsif ($arg=~/^blastDb=(.*)$/)        { $par{"parBlastDb"}=   $1; }
	elsif ($arg=~/^blastE=(.*)$/i)        { $par{"parBlastE"}=    $1; }
	elsif ($arg=~/^blastB=(.*)$/i)        { $par{"parBlastB"}=    $1; }
	elsif ($arg=~/^blastV=(.*)$/i)        { $par{"parBlastV"}=    $1; }

	elsif ($arg=~/^argBlast=(.*)$/i)      { $par{"argBlast"}=     $1; }
	elsif ($arg=~/^parBlastFil.*MaxP=(.*)$/i){ $par{"parBlastFilterMaxP"}=     $1; }

	elsif ($arg=~/^big$/)                 { $par{"parBlastDb"}=   $par{"dbBig"}; }
	elsif ($arg=~/^swiss$/)               { $par{"parBlastDb"}=   $par{"dbSwiss"}; }
	elsif ($arg=~/^trembl$/)              { $par{"parBlastDb"}=   $par{"dbTrembl"}; }
	elsif ($arg=~/^pdb$/)                 { $par{"parBlastDb"}=   $par{"dbPdb"}; }

#	elsif ($arg=~/^noblast$/)             { $par{"doBlastp"}=     0; 
#						$par{"doBlast3"}=     0; }

	elsif ($arg=~/^list$/)                { $par{"isList"}=       1; }

# 	elsif ($arg=~/^(.*dssp)_([a-z0-9A-Z])$/) { push(@fileIn,$1);
# 						   $chain{$1}=$2;}

	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}}
    return(1,"ok $sbrName");
}				# end of iniRdCmdLine

#===============================================================================
sub iniSet {
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniSet                      final settings
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniSet";

				# ------------------------------
				# hierarchy of blabla
    $par{"verb3"}=1             if ($par{"debug"});
    $par{"verb2"}=1             if ($par{"verb3"});
    $par{"verbose"}=1           if ($par{"verb2"});

				# ------------------------------
				# maxhom threshold
    $par{"parMaxhomThresh"}=    $par{"parMaxhomDis"}+25;
    $par{"parMaxhomThreshOld"}= $par{"parMaxhomDis"}+20;

				# ------------------------------
				# pre filter BLAST
    $par{"doBlastp"}=
	$par{"doBlast3"}=0      if ($par{"doSelf"} || $par{"doDirect"});
    $par{"doBlastp"}=0          if ($par{"doBlast3"});

				# ------------------------------
				# directories (for filter_blast)
    $par{"dirSwiss"}=~s/\/$//g;

                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    $fileIn=$fileIn[1];
				# automatic list finding
    $par{"isList"}= 1           if ($#fileIn==1 && $fileIn =~ /\.list$/);
    $isFastaMul=0;
    $isFastaMul=1               if (-e $fileIn && &isFastaMul($fileIn));

    die ("missing input $fileIn\n") if (! -e $fileIn);
    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);

				# ------------------------------
				# final settings
    return(&errSbr("please provide 'ARCH=XYZ' on the command line, or do 'setenv ARCH XYZ'".
		   " in your shell")) if (! defined $ARCH);

    $Lok=			# standard settings
	&brIniSet;              return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);

				# ------------------------------
				# rename DB
    $par{"dbMaxhom"}=
	$par{"parBlastDb"}      if ($par{"doDirect"});

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    return(1,"ok no BLAST")     if ($par{"doDirect"});
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

                                # ------------------------------
                                # special settings
                                # 'dir/title' -> 'title'
    if    ($par{"parBlastDb"} =~ /^(.+)\/(.+)$/){
        $par{"BLASTDB"}=$1;
        $par{"parBlastDb"}=$2;}
                                # assign defaults

				# --------------------
				# PHD
    if    ($par{"parBlastDb"} =~ /^phd126/){
        $db=$par{"parBlastDb"}=$par{"dbPhd126"}; $db=~s/^(.*)\/(.*)$/$1/; $par{"BLASTDB"}=$db; }
    elsif ($par{"parBlastDb"} =~ /^phd/){
        $db=$par{"parBlastDb"}=$par{"dbPhd"};    $db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }

				# --------------------
				# SWISS
    elsif ($par{"parBlastDb"} =~ /^swiss/){
        $db=$par{"parBlastDb"}=$par{"dbSwiss"};  $db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }

				# --------------------
				# ProDom
    elsif ($par{"parBlastDb"} =~ /^prodom/){
        $db=$par{"parBlastDb"}=$par{"dbProdom"}; $db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }
				# --------------------
				# PDB
    elsif ($par{"parBlastDb"} =~ /^pdb5/){
        $db=$par{"parBlastDb"}=$par{"dbPdb5881"};$db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }
    elsif ($par{"parBlastDb"} =~ /^pdb1267/){
        $db=$par{"parBlastDb"}=$par{"dbPdb1267"};$db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }
    elsif ($par{"parBlastDb"} =~ /^pdb/){
        $db=$par{"parBlastDb"}=$par{"dbPdb"};    $db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }

				# --------------------
				# locations
    elsif ($par{"parBlastDb"} =~ /^proka/){
        $db=$par{"parBlastDb"}=$par{"dbLocipro"};$db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }
    elsif ($par{"parBlastDb"} =~ /^euka/){
        $db=$par{"parBlastDb"}=$par{"dbLocieuk"};$db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }

                                # get rid of dir
    foreach $kwd ("BLASTDB","BLASTMAT"){
        $par{"$kwd"}=~s/\/$//g;}
				# which BLAST
    if ($par{"doBlast3"}){
	$par{"extBlast"}=$par{"extBlast3"}; }
    else {
	$par{"extBlast"}=$par{"extBlastp"}; }

}				# end of iniSet

#===============================================================================
sub maxhomRunRdlist {
    local($fileInLoc,$titleLoc,$dirWorkLoc,$extLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomRunRdlist              reads input file list (or chops FASTAmul into many)
#       in:                     $fileInLoc
#       in:                     $titleLoc   : title for temporary files    if = 0: 'TMP-$$'
#       in:                     $dirWorkLoc : working dir (for temp files) if = 0: ''
#       in:                     $extLoc     : extension of output files    if = 0: '.fasta'
#       out:                    1|0,msg,@fileWritten
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."maxhomRunRdlist";$fhinLoc="FHIN_"."maxhomRunRdlist";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $titleLoc=  "TMP-".$$       if (! defined $titleLoc && ! $titleLoc);
    $dirWorkLoc=  ""            if (! defined dirWorkLoc && ! dirWorkLoc);
    $dirWorkLoc.="/"            if ($dirWorkLoc !~/\/$/ && length($dirWorkLoc)>=1);
    $extLoc=  ".fasta"          if (! defined $extLoc && ! $extLoc);
    $#fileTmp=0;
                                # --------------------------------------------------
                                # (1) CASE: first line: is FASTAmul
                                # --------------------------------------------------
    if (&isFastaMul($fileInLoc)){
        ($Lok,$id,$seq)=
	    &fastaRdMul($fileInLoc);
	return(&errSbrMsg("failed reading FASTAmul format ($fileInLoc)",$msg)) if (! $Lok);
	$id=~s/^\n*|\n*$//g;   $seq=~s/^\n*|\n*$//g;
	@id=split(/\n/,$id);   @seq=split(/\n/,$seq);
        return(&errSbr("from fastRdMul ".$#id." ids read, but ".$#seq." sequences!"))
            if ($#id !~ $#seq);
        foreach $it (1..$#id){
	    $id=$id[$it]; $id=~s/\s.*$//g;
            $file=$dirWorkLoc.$id.$extLoc;
                                # write file
            ($Lok,$msg)=
                &fastaWrt($file,$id,$seq[$it]);
            return(&errSbrMsg("failed writing $file (fasta)",$msg)) if (! $Lok || ! -e $file); 
            push(@fileTmp,$file); }
        return(1,"ok $sbrName",@fileTmp); }

                                # --------------------------------------------------
                                # (2) CASE: is list of filenames
                                # --------------------------------------------------

				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# ------------------------------
                                # read
    while (<$fhinLoc>) {	# ------------------------------
        $_=~s/\n|\s//g;
        next if (length($_)<1);
        push(@fileTmp,$_); }
    close($fhinLoc);
    return(1,"ok $sbrName",@fileTmp);
}				# end of maxhomRunRdlist

#===============================================================================
sub doAli {
    local($fileInLoc,$fileHssp,$fileHsspFil) = @_ ;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   doAli                       runs the pre-filter (BLAST), MaxHom, (self), Filter_hssp
#       in GLOBAL:              %par{}
#       in:                     $fileInLoc,$fileHssp (output)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."doAli";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileHssp!"))           if (! defined $fileHssp);
    $fileHsspFil=0                                 if (! defined $fileHssp);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

    $msgHere="";
				# ------------------------------
				# maxhom LOG file
    $fileMaxhomLog="MAXHOM.LOG_".$par{"jobid"}; 
    $fileMaxhomAli="MAXHOM_Ali.".$par{"jobid"}; 
    @fileTmp=($fileMaxhomLog,$fileMaxhomAli);
				# ------------------------------
				# run self?
    $LrunSelf=1                 if ($par{"doSelf"});
    $LrunSelf=0                 if (! $par{"doSelf"});

				# ------------------------------
    $Lskip=0;			# skip?
    $Lskip=1                    if (! $par{"doNew"} && -e $fileHssp);
				# ------------------------------
				# existing, but empty -> run self
    if ($Lskip && &is_hssp_empty($fileHssp)) {
	$Lskip=0;
	$LrunSelf=1; }
				# ----------------------------------------
				#           <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    return(1,"ok") if ($Lskip);	# return
				#           <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# ----------------------------------------

				# ------------------------------
				# build up BLAST 
				# ------------------------------
    if (! $LrunSelf) {
				# RUN BLAST: intermediate files
	if (! $par{"doDirect"}) {
	    foreach $kwd ("fasta","blast","blastFil"){
		$file{$kwd}=$par{"dirWork"}.$par{"titleTmp"}.$idIn.".$kwd";
		$file{$kwd}=$par{"dirWork"}.$idIn.".$kwd"; }
				# hack br: 98-10: must end with list for MaxHom!!
	    $file{"blastFil"}.="_list";
	    push(@fileTmp,$file{"blast"})    if (! $par{"keepBlast"});
	    push(@fileTmp,$file{"blastFil"}) if (! $par{"keepBlastFil"});

	    $LskipBlast=0;
	    $LskipBlast=1       if (! $par{"doBlastp"} && ! $par{"doBlast3"});
	    $LskipBlast=1       if (! $par{"doNew"} && -e $file{"blastFil"}); }
				# DO NOT run BLAST: 
	else {
	    $fileTmp= $par{"dbMaxhom"};
				# hack br: 98-10: must end with list for MaxHom!!
	    if ($fileTmp !~ /list$/) {
		$tmp=$fileTmp; $tmp=~s/^.*\///g;
		$fileWant=$par{"dirWork"}.$tmp."_list";
		if (! -e $fileWant) {
		    ($Lok,$msg)=&sysSystem("cp $fileTmp $fileWant");
		    push(@fileTmp,$fileWant);}}
	    else {
		$fileWant=$fileTmp;}
	    $file{"blastFil"}=$fileWant;
	    $LskipBlast=1; }

	print $fhTrace "--- \t NOTE: skipping BLAST since ".$file{"blastFil"}." exists\n"
	    if ($LskipBlast && ($par{"doBlastp"} || $par{"doBlast3"})); }

				# --------------------------------------------------
                                # pre-filter to speed up MaxHom (BLAST)
				# --------------------------------------------------
	    
				# ------------------------------
				# BLASTP (blast2)   <<< BLASTP
				# ------------------------------
    if (! $LrunSelf && ! $LskipBlast && ! $par{"doBlast3"}){
	$tmp="--- run blast2 $fileInLoc -> ".$file{"blast"}." (db=".$par{"parBlastDb"}.")\n";
	print $fhTrace $tmp; $msgHere.=$tmp;

	($Lok,$msg)= 
	    &blastpRunSimple($fileInLoc,$file{"blast"},$par{"exeBinBlastp"},$par{"parBlastDb"},
			     $par{"parBlastE"},$par{"parBlastB"},$par{"fileOutScreen"},$fhTrace,
			     $par{"argBlast"},$par{"parBlastV"}); 
	return(&errSbrMsg("failed blastp (".$par{"exeBinBlastp"}.
			  ": $fileIn->".$file{"blast"}.")",$msg,$SBR)) if (! $Lok); }

				# ------------------------------
				# PSI blast (blast3) <<< BLAST3
				# ------------------------------
    elsif (! $LrunSelf && ! $LskipBlast){
	$tmp="--- run blast3 $fileInLoc -> ".$file{"blast"}." (db=".$par{"parBlastDb"}.")\n";
	print $fhTrace $tmp; $msgHere.=$tmp;

	if (0){
	    ($Lok,$msg)= 
		&blast3RunSimple($fileIn,$file{"blast"},$par{"exeBinBlast3"},$par{"parBlastDb"},
				 $par{"parBlastE"},$par{"parBlastB"},
				 $par{"fileOutScreen"},$fhTrace,$par{"parBlastV"}); 
	}
	($Lok,$msg)= 
	    &blast3RunDariusz($fileIn,$file{"blast"},$par{"exeBinBlast3"},
			      
			      $par{"exeBlastDariusz"},$par{"exeBlastDariuszPack"},
			      $par{"parBlastDb"},
			      $par{"parBlastE"},$par{"parBlastB"},
			      $par{"fileOutScreen"},$fhTrace,$par{"parBlastV"}); 
	return(&errSbrMsg("failed blast3 (".$par{"exeBlast3"}.
			  ": $fileIn->".$file{"blast"}.")",$msg,$SBR)) if (! $Lok); }

				# ------------------------------
				# extract hits from BLASTP-output
				# ------------------------------
    if (! $LrunSelf && ! $LskipBlast) {
	unlink($file{"blastFil"}) 
	    if (-e $file{"blastFil"});

	if ($par{"exeBlastFilter"} =~/big/) {
	    $cmd= $par{"exeBlastFilter"}." ".$file{"blast"};
                                # hack br 99-06: remove directory
            $tmp_parBlastDb=$par{"parBlastDb"}; $tmp_parBlastDb=~s/^.*\///g;
	    $cmd.=" db=".$tmp_parBlastDb;}
	else {
	    $cmd=$par{"exeBlastFilter"}." ".$file{"blast"}; 
	}
	$cmd.=" p=".$par{"parBlastFilterMaxP"} if (defined $par{"parBlastFilterMaxP"} &&
						   $par{"parBlastFilterMaxP"} &&
						   length($par{"parBlastFilterMaxP"})>0);
	
	$cmd.=" >> ".$file{"blastFil"};
	($Lok,$msg)=&sysSystem($cmd);

	return(&errSbrMsg("failed filtering",$msg,$SBR)) 
	    if (! $Lok || ! -e $file{"blastFil"}); 

	open("FHIN",$file{"blastFil"}) ||
	    return(0,"*** ERROR $SBR after ".$par{"exeBlastpFil"}." no output '".$file{"blastFil"}."'\n");
	$firstLine=<FHIN>;
	close(FHIN);
	$firstLine=~s/\s|\n//g  if (defined $firstLine);
				# replace list by itself
	&sysSystem("\\cp $fileInLoc ".$file{"blastFil"})
	    if (defined $firstLine && $firstLine=~/none/i);}

				# ------------------------------
				# build up MaxHom command
				# ------------------------------
    if (! $LrunSelf) {
	$thresh=		# get the threshold
	    &maxhomGetThresh($par{"parMaxhomThreshOld"});

	($msg,$msg)=		# check existence of files asf
	    &maxhomGetArgCheck($par{"exeBinMaxhom"},$par{"fileMaxhomDefaults"},
			       $fileInLoc,$file{"blastFil"},$par{"fileMaxhomMetr"});
	return(&errSbrMsg("maxhom arg check returned error",$msg,$SBR)) if (length($msg)>1);
    
	$cmd=			# get command line argument for starting MaxHom
	    &maxhomGetArg(" ",$par{"exeBinMaxhom"},$par{"fileMaxhomDefaults"},
			  $par{"jobid"},$fileInLoc,$file{"blastFil"},
			  $par{"parMaxhomProfIn2"},$par{"fileMaxhomMetr"},
			  $par{"parMaxhomSmin"},$par{"parMaxhomSmax"},
			  $par{"parMaxhomGo"},$par{"parMaxhomGe"},
			  $par{"parMaxhomW1"},$par{"parMaxhomW2"},
			  $par{"parMaxhomI1"},$par{"parMaxhomI2"},
			  $par{"parMaxhomNali"},$thresh,
			  $par{"parMaxhomSort"},$fileHssp,$par{"dirPdb"},
			  $par{"parMaxhomProfOut"},$par{"parMaxhomStripOut"});

				# ========================================
				# run MaxHom
				# ========================================
	($Lok,$msg)=
	    &sysRunProg($cmd,$par{"fileOutScreen"},$fhTrace);
    
	return(&errSbrMsg("failed MaxHom ($cmd)",$msg,$SBR)) if (! $Lok); 

				# ------------------------------
				# filter HSSP
				# ------------------------------
	if (-e $fileHssp && ! &is_hssp_empty($fileHssp) &&
	    $par{"doFilterHssp"}) {
	    if (! $fileHsspFil){
		$fileHsspFil=$fileHssp; $fileHsspFil=~s/$par{"extHssp"}/$par{"extHsspFil"}/;
                                # replace dir
		if ($par{"dirOutHsspFil"}) {
		    $dirOutFil=$par{"dirOutHsspFil"}; $dirOutFil.="/" if ($dirOutFil !~/\/$/);
		    $fileHsspFil=~s/^.*\//$dirOutFil/;}
	    }
	    $cmdLoc=  $par{"exeFilterHssp"}." $fileHssp fileOut=$fileHsspFil ";
	    $cmdLoc.= "exe=".$par{"exeBinFilterHssp"}." ".$par{"filter"};
	    $cmdLoc.= " dbg"    if ($par{"debug"});
	    eval      "\$cmd=\"$cmdLoc\""; 

				# RUN filter
	    ($Lok,$msg)=
		&sysRunProg($cmd,$par{"fileOutScreen"},$fhTrace);
	    return(&errSbr("failed to filter HSSP=$fileHssp with (".
			   $par{"exeBinFilterHssp"}.")\n".
			   "cmd=$cmd\n",$msg,$SBR)) if (! $Lok || ! -e $fileHsspFil); }
    }				# end of alignment part
				# <- <- <- <- <- <- <- <- <- <- <- <- <- <- <- <- <- <- <- <- <- 

				# ------------------------------
				# correct for empty HSSP files
				# ------------------------------
    $LrunSelf=1                 if (! $LrunSelf && 
				    (! -e $fileHssp || &is_hssp_empty($fileHssp)));
    if ($LrunSelf) {
	$fhScreenLoc="STDOUT"   if ($par{"debug"});
	$fhScreenLoc=$fhTrace   if (! $par{"debug"});

	($Lok,$msg)=
	    &maxhomRunSelf($par{"optNice"},$par{"exeBinMaxhom"},$par{"fileMaxhomDefaults"},
			   $par{"jobid"},$fileIn,$fileHssp,$par{"fileMaxhomMetr"},
			   $fhScreenLoc,$par{"fileOutScreen"});
	print 
	    "*** $scrName failed to get HSSPself ($fileHssp) from seq=$fileIn\n",
	    "***    reason: \n$msg (from maxhomRunSelfLoc)\n" if (! $Lok); }
    
				# delete temporary
    if (! $par{"debug"}){
	foreach $file (@fileTmp){ 
	    unlink ($file) if (-e $file);
	}}

    return(1,"ok $sbrName");
}				# end of doAli

