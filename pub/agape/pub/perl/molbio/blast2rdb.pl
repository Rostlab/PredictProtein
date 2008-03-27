#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "extracts RDB from BLASTP/PSI-BLAST";
$scrIn=      "blast(s), or list-thereof";
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= " \n";
$scrHelpTxt.=" \n";
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0

($Lok,$msg)=
    &blast2rdbLoc(@ARGV);

print "*** $scrName: final msg=".$msg."\n" if (! $Lok);

exit;

#===============================================================================
sub blast2rdbLoc {
    local($SBR,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blast2rdbLoc                 runs BLASTP (designed to become package)
#       in:                     $fileInLoc,fileOut=$fileOut, asf. ...
#                               input like for any script
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."blast2rdbLoc";$fhinLoc="FHIN_"."blast2rdbLoc";
    
				# ------------------------------
    ($Lok,$msg)=		# initialise variables
	&iniBlast2rdb();
    if (! $Lok) { print "*** ERROR $scrName after iniBlast2rdb\n",$msg,"\n";
		  die '*** during initialising $scrName   ';}

				# ------------------------------
				# redirect STDERR (file handle)
    $Lopen_stderr=0;
    if (defined $par{"debug"} && ! $par{"debug"}){ 
	$Lopen_stderr=1;
	open(STDERR,">".$par{"fileOutStderr"}) || 
	    do {  print "*-* failed to open traceStderr=".."!\n";
		  $Lopen_stderr=0;};} else { $Lopen_stderr=0;}

				# --------------------------------------------------
				# (1) read input file list
				# --------------------------------------------------
    if ($par{"isList"}){
	print "--- $SBR: assumed fileIn=$fileIn, is list\n"     if (! $isFastaMul);
        ($Lok,$msg,@fileIn)=
	    &blast2rdbRdlist($fileIn,$par{"titleTmp"},$par{"dirWork"},$par{"extFasta"});
	return(&errSbrMsg("failed reading list=$fileIn (blast2rdbRdList)",$msg,$SBR)) if (! $Lok);
    }
    print "xx fileout=$fileOut\n";die;
				# --------------------------------------------------
				# temp file for BLAST summary
				# NOTE: crashes on ERROR!!
				# out GLOBAL: 
				#     $fileBlastSummaryTmp=x
				#     $fhBlastSummary opened
				#     $ptr_colFileTmp{$kwd}=number_of_column 
				#         $kwd=id1|id2|@kwdBlastSummary (except 'id')
				# --------------------------------------------------
    
    &summaryFileTmpOpen()       if ($par{"doThresh"});

				# --------------------------------------------------
				# (3) loop over all input file(s)
				# --------------------------------------------------
    $ctfile=0; $nfileIn=$#fileIn; 
    while (@fileIn){
	$fileIn=shift @fileIn;
	if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n"; 
                          next;}
	++$ctfile; 
	$idIn=$fileIn;
	$idIn=~s/^.*\/|\..*$//g;  
	$idIn=~s/$par{"titleTmp"}//;

	$fileOut=    $par{"dirOut"}.$idIn.$par{"extOut"};
	$fileOutGzip=$fileOut.".gz";

	next if (! $par{"doNew"} && 
		 (-e $fileOut || -l $fileOut || -e $fileOutGzip || -l $fileOutGzip));

                                # ------------------------------
				# read header -> threshold
				# out GLOBAL: $numPairsOk (for time estimate)
				#       write ERRORS to $fhTrace (warning to screen)
	&summaryFileTmpWrt1($fileIn) if ($par{"doThresh"});
				# compress output file
	if ($par{"doGzip"}){
	    $cmd=$par{"exeGzip"}." $fileOut";
	    eval "\$cmdSys=\"$cmd\"";
	    ($Lok,$msg)=
		&sysRunProg($cmdSys,$fileOutScreenLoc,$fhTrace);
	    print $fhTrace "-*- WARN $scrName: failed to gzip ($cmd=>$msg)\n" if (! $Lok); }
	    
				# ------------------------------
				# estimate time
	$estimate=
	    &fctRunTimeLeft($timeBeg,$nfileIn,$ctfile);
	$estimate="?"           if ($ctfile < 5);
	$tmp=  sprintf("--- %-40s %4d (%4.1f%-1s), time left=%-s ",
		       $fileIn,$ctfile,(100*$ctfile/$nfileIn),"%",$estimate);
	$tmp.= sprintf("hits=%5d",$numPairsOk) if ($par{"doThresh"});
	$tmp.= "\n";
	print $tmp; 
    }				# end of loop over all input files
				# --------------------------------------------------

				# --------------------------------------------------
				# (4) final: report which ones ok
				# --------------------------------------------------
    if ($par{"doThresh"}){ 
	close($fhBlastSummary); 
	undef %fin;
	$fin{"NROWS"}= $ctfile;
	($Lok,$msg)=
	    &summaryFileFin();  
	if (! $Lok) { print 
			  "*** ERROR $scrName: almost done, and failed in summaryFileFin\n",
			  "*** file out expected $fileOut, temp=$fileBlastSummaryTmp\n",
			  $msg,"\n";
		      exit; }
	print "--- output in $fileOut\n";  }

				# ------------------------------
				# close STDERR
    if ($Lopen_stderr){
	close(STDERR);
	unlink($par{"fileOutStderr"});}
    
                                # ------------------------------
    if (! $par{"debug"}){       # clean up
	push(@fileRm,$par{"fileScreen"},$par{"fileTrace"});
	foreach $file (@fileRm){
	    if (defined $file && -e $file){ print "--- remove $file\n";
					    unlink $file;}}}
                                # ------------------------------
                                # final words
    if ($par{"verbose"}) { print $fhTrace "--- $scrName ended fine .. -:\)\n";
			   
			   $timeEnd=time;    # runtime , run time
			   $timeRun=$timeEnd-$timeBeg;
			   print $fhTrace 
			       "--- date     \t \t $Date \n",
			       "--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n"; }

    return(1,"ok $SBR");
}				# end of blast2rdbLoc



#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub blastGetSummary_5 {
    my($fileInLoc,$minLaliLoc,$minDistLoc) = @_ ;
    my($sbrName,$fhinLoc,$tmp,$Lok,@idtmp,%tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastGetSummary_5       BLAST out -> summary: IDE,LALI,LEN,PROB,DISTANCE-to-hssp-curve
#       in:                     $fileInLoc    : file with BLAST output
#       in:                     $minLaliLoc   : take those with LALI > x      (=0: all)
#       in:                     $minDistLoc   : take those with $pide>HSSP+X  (=0: all)
#       out:                    1|0,msg,$tmp{}, with
#                               $tmp{"NROWS"}     : number of pairs
#                               $tmp{"id",$it}    : name of protein it
#                               $tmp{"len",$it}   : length of protein it
#                               $tmp{"lali",$it}  : length of alignment for protein it
#                               $tmp{"prob",$it}  : BLAST probability for it
#                               $tmp{"score",$it} : BLAST score for it
#                               $tmp{"pide",$it}  : pairwise percentage sequence identity
#                               $tmp{"dist",$it}  : distance from HSSP-curve
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastGetSummary_5";$fhinLoc="FHIN_"."blastGetSummary_5";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # adjust
    $minLaliLoc=0               if (! defined $minLaliLoc);
    $minDistLoc=-100            if (! defined $minDistLoc);
                                # ------------------------------
                                # read file
                                # ------------------------------
    ($Lok,$msg,$rh_hdrLoc)=   
        &blastRdHdr_5($fileInLoc);
    return(&errSbrMsg("failed reading blast header ($fileInLoc)",$msg)) if (! $Lok);

    $rh_hdrLoc->{"id"}=~s/,*$//g; # interpret
    @idtmp=split(/,/,$rh_hdrLoc->{"id"});
                                # ------------------------------
                                # loop over all pairs found
                                # ------------------------------
    undef %tmp; 
    $ct=0;
    while (@idtmp) {
	$idtmp=shift @idtmp;
        next if ($rh_hdrLoc->{$idtmp,"lali"} < $minLaliLoc);
                                # compile distance to HSSP threshold (new)
        ($pideCurve,$msg)= 
#            &getDistanceHsspCurve($rh_hdrLoc->{$idtmp,"lali"});
            &getDistanceNewCurveIde($rh_hdrLoc->{$idtmp,"lali"});
        return(&errSbrMsg("failed getDistanceNewCurveIde",$msg))  
            if ($msg !~ /^ok/);
            
        $dist=$rh_hdrLoc->{$idtmp,"ide"}-$pideCurve;
        next if ($dist < $minDistLoc);
                                # is ok -> TAKE it
        ++$ct;
        $tmp{"id",$ct}=       $idtmp;
	foreach $kwd ("len","lali","prob","score"){
	    $tmp{$kwd,$ct}= $rh_hdrLoc->{$idtmp,$kwd}; 
	}
        $tmp{"pide",$ct}=     $rh_hdrLoc->{$idtmp,"ide"};
        $tmp{"dist",$ct}=     $dist;
    } 
    $tmp{"NROWS"}=$ct;

    undef %{rh_hdrLoc};		# slim-is-in !
    return(1,"ok $sbrName",\%tmp);
}				# end of blastGetSummary_5

#==============================================================================
sub blastRdHdr_5 {
    my($fileInLoc) = @_ ;
    my($sbrName,$fhinLoc,$tmp,$Lok,@idFoundLoc,
	  $Lread,$name,%hdrLoc,$Lskip,$id,$line);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastRdHdr_5                reads header of BLASTP output file
#       in:                     $fileBlast
#       out:                    (1,'ok',%hdrLoc)
#       out:                    $hdrLoc{$id}='id1,id2,...'
#       out:                    $hdrLoc{$id,$kwd} , with:
#                                  $kwd=(score|prob|ide|len|lali)
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastRdHdr_5";$fhinLoc="FHIN-blastRdHdr_5";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")    if (! defined $fileInLoc);
    return(0,"*** $sbrName: no in file=$fileInLoc") if (! -e $fileInLoc);
				# ------------------------------
				# open BLAST output
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n");
				# ------------------------------
    $#idFoundLoc=$Lread=0;	# read file
    while (<$fhinLoc>) {
	last if ($_=~/^\s*Sequences producing /i);}
				# ------------------------------
				# skip header summary
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)<1 || $_ !~/\S/); # skip empty line
	$Lread=1 if (! $Lread && $_=~/^\s*>/);
	next if (! $Lread);
	last if ($_=~/^\s*Parameters/i); # final
				# ------------------------------
	$line=$_;		# read ali paras
				# id
	if    ($line=~/^\s*>\s*(.*)/){
	    $name=$1;
	    $id=$name;
	    $id=~s/^([\S]+)\s+.*$/$1/g;
	    $id=~tr/[A-Z]/[a-z]/  if (defined $par{"LidLowerCase"} && $par{"LidLowerCase"});
	    if (length($id)>0){
		push(@idFoundLoc,$id);
		$Lskip=0;
		$hdrLoc{$id,"name"}=$name;}
	    else              {
		$Lskip=1;}
	}
				# length
	elsif (! $Lskip && ! defined $hdrLoc{$id,"len"} && 
	       ($line=~/^\s*Length = (\d+)/)) {
	    $hdrLoc{$id,"len"}=$1;}
				# sequence identity
	elsif (! $Lskip && ! defined $hdrLoc{$id,"ide"} &&
	       ($line=~/^\s* Identities = \d+\/(\d+) \((\d+)/) ) {
	    $hdrLoc{$id,"lali"}=$1;
	    $hdrLoc{"ide",$id}=$hdrLoc{$id,"ide"}=$2;
	}
				# score + prob (blast3)
# Score =  819 bits (2092), Expect = 0.0
# Identities = 576/619 (93%), Positives = 595/619 (96%), Gaps = 3/619 (0%)

# Score =  388 bits (985), Expect = e-106
# Identities = 135/458 (29%), Positives = 185/458 (39%), Gaps = 69/458 (15%)

	elsif (! $Lskip && ! defined $hdrLoc{$id,"score"} &&
	       ($line=~/^\s*Score\s*=\s*([\d\.]+)\s+bits \(\d+\).*, Expect\s*=\s*([\d\-\.e]+)/) ) {
	    $hdrLoc{$id,"score"}=$1;
	    $hdrLoc{$id,"prob"}= $2;}
				# score + prob (blast2)
	elsif (! $Lskip && ! defined $hdrLoc{$id,"score"} &&
	       ($line=~/ Score = (\d+)\s+[^,]*, Expect = ([^,]+), .*$/) ) {
	    $hdrLoc{$id,"score"}=$1;
	    $hdrLoc{$id,"prob"}= $2;}
    }
    close($fhinLoc);
				# ------------------------------
    $hdrLoc{"id"}="";		# arrange to pass the result
    for $id (@idFoundLoc){
	$hdrLoc{"id"}.=$id.","; 
				# correct too low for accuracy
	if (defined $hdrLoc{$id,"score"} && 
	    $hdrLoc{$id,"score"} > 600   && $hdrLoc{$id,"prob"} eq "0.0"){
	    if (defined $par{"minProbBlast"}){
		$hdrLoc{$id,"prob"}= $par{"minProbBlast"};}
	    else {
		$hdrLoc{$id,"prob"}= 10**-222;}
	}
				# change probability
	if ($hdrLoc{$id,"prob"} =~/e/){
	    ($tmp1,$tmp2)=split(/e/,$hdrLoc{$id,"prob"});
	    $tmp1=1             if (length($tmp1)<1);
	    $hdrLoc{$id,"prob"}=$tmp1*10**$tmp2;
	}	    
    } 
    $hdrLoc{"id"}=~s/,*$//g;
    

    $#idFoundLoc=0;		# save space
    return(1,"ok $sbrName",\%hdrLoc);
}				# end of blastRdHdr_5 

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
                       if ($arg=~/^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
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
    $tmp{"scrNameFull"}=$0      if (! defined $tmp{"scrNameFull"});
				# ------------------------------
				# additional help keywords?
				# ------------------------------
    $#tmpAdd=0;
    if (defined $tmp{"scrAddHelp"} && $tmp{"scrAddHelp"} ne "unk"){
	@tmp=split(/\n/,$tmp{"scrAddHelp"});$Lerr=0;
	foreach $tmp(@tmp){
	    push(@tmpAdd,$tmp{"scrNameFull"}." ".$tmp);
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
	 "--- "." " x length($tmp{"scrNameFull"}).
	 "              ........................................");
    @scrHelpLoop=
	($tmp{"scrNameFull"}." help          : lists all options",
	 $tmp{"scrNameFull"}." def           : writes default settings",
	 $tmp{"scrNameFull"}." def keyword   : settings for keyword",
	 $tmp{"scrNameFull"}." help keyword  : explain key, e.g. 'special', or how for 'how' and 'howie'");
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." problems      : known problems") 
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /problems/);
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." hints         : hints for users")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /hints/);
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." manual        : will cat the entire manual (... MAY be it will)")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /manual/);

    push(@scrHelpLoop,@tmpAdd) if ($#tmpAdd>0);

    push(@scrHelp,@scrHelpLoop,
	 "--- "." " x length($tmp{"scrNameFull"}).
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
                $tmp{"scrNameFull"}." help keyword\n",
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
                    $tmp{"scrNameFull"}," def keyword'\n \n";}}
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
                push(@tmp,$kwd) if ($kwd =~/$kwdHelp/i);}
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
                                # (3) is there a default file?
        elsif (defined $par{"fileDefaults"} && -e $par{"fileDefaults"} &&
	    $kwdHelp ne "special"){
	    ($Lok,$msg,%def)=&brIniRdDef($par{"fileDefaults"});
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
	    @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
	    foreach $kwd (@kwdLoc){
		if ($kwd =~/$kwdHelp/i){
		    push(@tmp,$kwd); 
		    if (defined $def{$kwd,"expl"}){
			$def{$kwd,"expl"}=~s/\n/\n---                        /g;
			push(@expLoc,$def{$kwd,"expl"});}
		    else {
			push(@expLoc," ");}}}
	    @kwdLoc=@tmp;}
				# (4) else: read itself
        elsif ($kwdHelp ne "special"){
            ($Lok,$msg,%def)=
		&brIniHelpRdItself($tmp{"sourceFile"});
            die '.....   verrry sorry the option blew up ... ' if (! $Lok);
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
            @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
            foreach $kwd (@kwdLoc){
                next if ($kwd !~/$kwdHelp/i && $kwdHelp !~ /$kwd/ );
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
		    $scrSpecialLoc=~s/\n$//;
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
                    next if ($kwd !~ /$kwdHelp/);
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                print  " \n";}}
	else { print "--- sorry, no setting defined in \%par\n";}
	return(1,"fin loop?");}

    return(1,"ok $sbrName");
}				# end of brIniHelp

#==============================================================================
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
sub brIniRdDef {
    local ($fileLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniRdDef                  reads defaults for initialsing parameters
#       in GLOBAL:              $par{},@ARGV
#       out GLOBAL:             $par{} (i.e. changes settings automatically)
#       in:                     file_default
#       out:                    ($Lok,$msg,%defaults) with:
#                               $defaults{"kwd"}=         'kwd1,kwd2,...,'
#                               $defaults{"$kwd1"}=       val1
#                               $defaults{"$kwd1","expl"}=explanation for kwd1
#                               note: long explanations split by '\n'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniRdDef"; $fhin="FHIN_brIniRdDef";

    &open_file("$fhin","$fileLoc") ||
	return(0,"*** ERROR $sbrName: failed to open in '$fileLoc'\n");

    undef %defaults; 
    $#kwd=0; $Lis=0;
				# ------------------------------
    while (<$fhin>){		# read file
	next if (length($_)<3 || $_=~/^\#/ || $_!~/\t/); # ignore lines beginning with '#'
	$_=~s/\n//g;
	$line=$_;
	$tmp=$line; $tmp=~s/[\s\#\-\*\.\=\t]//g;
				# ignore lines with only spaces or '-|#|*|='
	next if (length($tmp)<1);
				# purge leading blanks and tabs
	$line=~s/^[\s\t]*|[\s\t]*$//g;
				# ------------------------------
				# (1) case 'kwd  val  # comment'
	if    ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]+\# ?(.*)$/){
	    $kwd=$1; push(@kwd,$kwd); $defaults{$kwd}=$2; 
            $defaults{$kwd,"expl"}=$3 if (defined $3 && length($3)>1); $Lis=1;}
				# (2) case 'kwd  val'
	elsif ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]*$/){
	    $kwd=$1; $defaults{$kwd}=$2; $Lis=1; $defaults{$kwd,"expl"}=""; }
				# (3) case '          # ----'
	elsif ($Lis && $line =~ /^\#\s*[\-\=\_\.\*]+/){
	    $Lis=0;}
	elsif ($Lis && defined $defaults{$kwd,"expl"} && $line =~ /^\#\s*(.*)$/){
	    $defaults{$kwd,"expl"}.="\n".$1;}}
    close($fhin);
				# ------------------------------
    foreach $kwd (@kwd){        # fill in wild cards
        $defaults{$kwd}=$ARCH if ($defaults{$kwd}=~/ARCH/);}
                                # ------------------------------
    foreach $kwd (@kwd){        # complete it
	$defaults{$kwd,"expl"}=" " if (! defined $defaults{$kwd,"expl"});}
    $defaults{"kwd"}=join(',',@kwd);
				# ------------------------------
				# check the defaults read
				# AND OVERWRITE $par{} !!
    @kwdDef=keys %par; foreach $kwd (@kwdDef){ $tmp{$kwd}=1;}
    $Lok=1;
    foreach $kwd (@kwd){
	if (! defined $tmp{$kwd}){
	    $Lok=0;
	    print 
		"*** ERROR $sbrName: wrong keyword ($kwd) in defaults file ",
		$par{"fileDefaults"},"\n";}
				# ******************************
	else {			# overwrite
				# ******************************
	    $par{$kwd}=$defaults{$kwd};}}
    return(0,"*** ERROR $sbrName failed finishing to read defaults file\n") if (! $Lok);

    return(1,"ok $sbrName",%defaults);
}				# end of brIniRdDef

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
	    next if (-e $fileIn);
	    $fileIn=$par{"dirIn"}.$fileIn if ($fileIn !~/$par{"dirIn"}/);
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
	    next if (-e $par{$kwd});
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
	    next if (-e $par{$kwd});
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
	$ARCHTMP=$ENV{'ARCH'} || "SGI32"; }

    $exeConvLocDef=             "/home/rost/pub/bin/convert_seq98.".$ARCHTMP;

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
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || 
				    ! $fileOutScreenLoc ||
				    $fileOutScreenLoc eq "STDOUT");
    $LdebugLoc=0;
    $LdebugLoc=1                if ($fileOutScreenLoc eq "STDOUT");

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
	$idIn=$fileLoc;
	$idIn=~s/^.*\/|\..*$//g;

				# ------------------------------
				# ... else RUN copf
	$fileOutTmp=$dirWorkLoc.$titleLoc.$idIn.$extLoc;

	$cmd= $exeCopfLoc." $fileLoc fasta extr=$extrLoc";
	$cmd.=" exeConvertSeq=".$exeConvertSeqLoc;
	$cmd.=" fileOut=$fileOutTmp";
	$cmd.=" dbg"            if ($LdebugLoc);
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
    foreach $it (1..$ctRd) { $id.= $tmp{$it,"id"}."\n";
			     $tmp{$it,"seq"}=~s/\s//g;
			     $seq.=$tmp{$it,"seq"}."\n";}
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
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
    $loc= 510 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

#===============================================================================
sub isFasta {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFasta                     checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    open($fhinLoc2,$fileLoc) || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s|\n//g            if (defined $two);
    close($fhinLoc2);

    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if ($one =~ /^\s*>\s*\w+/ && 
				    $two !~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/);
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
    open($fhinLoc2,$fileLoc) || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s//g               if (defined $two);

    return (0)                  if (! defined $two || ! defined $one);
    return (0)                  if (($one !~ /^\s*\>\s*\w+/) || 
				    ($two =~ /[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i));
    $Lok=0;
    while (<$fhinLoc2>) {
	next if ($_ !~ /^\s*>\s*\w+/);
	$Lok=1;
	last;}close($fhinLoc2);
    return($Lok);
}				# end of isFastaMul

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
sub rdbGenWrtHdr {
    local($fhoutLoc2,%tmpLoc)= @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbGenWrtHdr                writes a general header for an RDB file
#       in:                     $file_handle_for_out
#       in:                     $tmp2{}
#                               $tmp2{"name"}    : name of program/format/.. eg. 'NNdb'
#                notation:     
#                               $tmp2{"nota","expect"}='name1,name2,...,nameN'
#                                                : column names listed
#                               $tmp2{"nota","nameN"}=
#                                                : description for nameN
#                               additional notations:
#                               $tmp2{"nota",$ct}='kwd'.'\t'.'explanation'  
#                                                : the column name kwd (e.g. 'num'), and 
#                                                  its description, 
#                                                  e.g. 'is the number of proteins'
#                parameters:           
#                               $tmp2{"para","expect"}='para1,para2' 
#                               $tmp2{"para","paraN"}=
#                                                : value for parameter paraN
#                               $tmp2{"form","paraN"}=
#                                                : output format for paraN (default '%-s')
#       out:                    implicit: written onto handle
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."rdbGenWrtHdr";
                                # defaults, read
    $name="";        $name=$tmpLoc{"name"}." "   if (defined $tmpLoc{"name"});
    $#colNamesTmp=0; @colNamesTmp=split(/,/,$tmpLoc{"nota","expect"})
                                                 if (defined $tmpLoc{"nota","expect"});
    $#paraTmp=0;     @paraTmp=    split(/,/,$tmpLoc{"para","expect"})
                                                 if (defined $tmpLoc{"para","expect"});

    print $fhoutLoc2 
	"# Perl-RDB  $name"."format\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORM  beg          $name\n",
	"# FORM  general:     - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORM  general:     - columns are delimited by tabs\n",
	"# FORM  format:      '# FORM  SPACE keyword SPACE further-information'\n",
	"# FORM  parameters:  '# PARA: SPACE keyword SPACE=TAB value TAB (further-info)'\n",
	"# FORM  notation:    '# NOTA: SPACE keyword SPACE=TAB explanation'\n",
	"# FORM  1st row:     column names  (tab delimited)\n",
	"# FORM  2nd row (may be): column format (tab delimited)\n",
	"# FORM  rows 2|3-N:  column data   (tab delimited)\n",
        "# FORM  end          $name\n",
	"# --------------------------------------------------------------------------------\n";
                                # ------------------------------
				# explanations
                                # ------------------------------
    if ($#colNamesTmp>0 || defined $tmpLoc{"nota","1"}){
        print  $fhoutLoc2 
            "# NOTA  begin        $name"."ABBREVIATIONS\n",
            "# NOTA               column names \n";
        foreach $kwd (@colNamesTmp) { # column names
            next if (! defined $kwd);
            next if (! defined $tmpLoc{"nota",$kwd});
            printf $fhoutLoc2 "# NOTA: %-12s =\t%-s\n",$kwd,$tmpLoc{"nota",$kwd}; }
        print  $fhoutLoc2 
            "# NOTA               parameters\n";
        foreach $it (1..1000){      # additional info
            last if (! defined $tmpLoc{"nota",$it});
            ($kwd,$expl)=split(/\t/,$tmpLoc{"nota",$it});
            next if (! defined $kwd);
            $expl="" if (! defined $expl);
            printf $fhoutLoc2 "# NOTA: %-12s =\t%-s\n",$kwd,$expl; }
        print $fhoutLoc2 
            "# NOTA  end          $name"."ABBREVIATIONS\n",
            "# --------------------------------------------------------------------------------\n"; }

                                # ------------------------------
				# parameters
                                # ------------------------------
    if ($#paraTmp > 0) {
        print $fhoutLoc2
            "# PARA  beg          $name\n";
        foreach $kwd (@paraTmp){
	    next if (! defined $tmpLoc{"para",$kwd});
            $tmp="%-s";
            $tmp=$tmpLoc{"form",$kwd} if (defined $tmpLoc{"form",$kwd});
	    printf $fhoutLoc2
		"# PARA: %-12s =\t$tmp\n",$kwd,$tmpLoc{"para",$kwd}; }
        print $fhoutLoc2 
            "# PARA  end          $name\n",
            "# --------------------------------------------------------------------------------\n"; }

}				# end of rdbGenWrtHdr

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/rost/perl/",
	  "/home/rost/pub/perl/"
	  );
    $exe_ctime="ctime.pl";	# local ctime library

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    foreach $tmp (@tmp){
		$exe_tmp=$tmp.$exe_ctime;
		if (-e $tmp){
		    $Lok=
			require("$exe_tmp");
		    last;}}}
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
    $sbrName="lib-sys:sysRunProg";
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



#==============================================================================
# library collected (end)
#==============================================================================


#===============================================================================
sub iniBlast2rdb {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniBlast2rdb                    initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName".":iniBlast2rdb";
				# ------------------------------
				# highest priority arguments
    foreach $arg(@ARGV){
	next if ($arg !~/=/);
	if    ($arg=~/ARCH=(.*)$/)  { $ARCH=$1; 
				      last; }}

    $ARCH=$ENV{'ARCH'}          if (! defined $ARCH && defined $ENV{'ARCH'});
				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();
				# ------------------------------
				# first settings for parameters 
    &iniDefBlast();

    @kwd=sort (keys %par);
    $#fileRm=0;
				# ------------------------------
				# HELP stuff

				# standard help
    $tmp=$0; $tmp=~s/^\.\///    if ($tmp=~/^\.\//);
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);
				# special help
    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "skip,list,filter,";
    $tmp{"special"}.=        "pdb,swiss,trembl,all,purge,";
    $tmp{"special"}.=        "minDist,gzip,low,split,nosplit,";
        
    $tmp{"skip"}=            "will not run again if output file existing";
    $tmp{"list"}=            "short for isList=1   -> in file is list of files or FASTAmul";
    $tmp{"filter"}=          "short for doThresh=1 -> filter BLAST output with HSSP thresh";

    $tmp{"gzip"}=            "short for doGzip=1   -> will immediately zip all output files to save space";
    $tmp{"low"}=             "convert ids to lower case";

    $tmp{"pdb"}=             "will only write PDB";
    $tmp{"swiss"}=           "will only write SWISS-PROT";
    $tmp{"trembl"}=          "will only write TREMBL";
    $tmp{"purge"}=           "remove database identifier from output";
    $tmp{"split"}=           "write RDB file for each input file";
    $tmp{"nosplit"}=         "do not write RDB file for each input file";

#                            "------------------------------------------------------------\n";
				# ------------------------------
				# want help?
    $tmp{"s_k_i_p"}=         "problems,manual,hints";
    ($Lok,$msg)=
	&brIniHelp(%tmp);       return(&errSbrMsg("after lib:brIniHelp".$msg)) if (! $Lok);
    exit if ($msg =~ /^fin/);
    
				# ------------------------------
    $#fileIn=0;			# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg();
    foreach $arg (@argUnk){     # interpret specific command line arguments
	if    ($arg=~/^fileOut=(.*)$/)        { $par{"fileOut"}=     $1; 
						$par{"doThresh"}=    1; }
	elsif ($arg=~/^dirout=(.*)$/i)        { $par{"dirOut"}=      $1; }
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}=     "nice -".$1; }
	elsif ($arg eq "nonice")              { $par{"optNice"}=     " "; }
	elsif ($arg eq "debug")               { $par{"debug"}=       1; }

	elsif ($arg=~/^de?bu?g$/)             { $par{"debug"}=       1;
						$par{"verbose"}=     1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $par{"verbose"}=     1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $par{"verbose"}=     0;}

	elsif ($arg=~/^filter$/)              { $par{"doThresh"}=    1; }
	elsif ($arg=~/^doThresh$/)            { $par{"doThresh"}=    1; }
	elsif ($arg=~/^noThresh$/)            { $par{"doThresh"}=    0; }
	elsif ($arg=~/^doThresh=(.*_)$/)      { $par{"doThresh"}=    $1; }
	elsif ($arg=~/^swiss$/)               { $par{"takeSwiss"}=   1; }
	elsif ($arg=~/^trembl$/)              { $par{"takeTrembl"}=  1; }
	elsif ($arg=~/^pdb$/)                 { $par{"takePdb"}=     1; }
	elsif ($arg=~/^all$/)                 { $par{"takeAll"}=     1; }

	elsif ($arg=~/^purge$/)               { $par{"Lidpurgedb"}=  1; }

	elsif ($arg=~/^split$/)               { $par{"Lsplit"}=      1; }
	elsif ($arg=~/^nosplit$/)             { $par{"Lsplit"}=      0; }

	elsif ($arg=~/^minDis=(.*)$/)         { $par{"minDist"}=     $1; }
	elsif ($arg=~/^thresh=(.*)$/)         { $par{"minDist"}=     $1; }
	elsif ($arg=~/^dis=(.*)$/)            { $par{"minDist"}=     $1; }

	elsif ($arg=~/^low$/)                 { $par{"LidLowerCase"}=1; }


	elsif ($arg=~/^format$/)              { $par{"doFormat"}=    1; }
	elsif ($arg=~/^blast3$/)              { $par{"blastVersion"}="3"; }
	elsif ($arg=~/^psi$/)                 { $par{"blastVersion"}="psi"; }
	elsif ($arg=~/^(mat|saf|red=\d+)$/)   { $par{"blastCmd"}.=   " ".$1 
						    if ($par{"blastCmd"} !~ /$1/);}
	elsif ($arg=~/^(cmd|command)=(.*)$/i) { $par{"blastCmd"}=    $1; }
	elsif ($arg=~/^E=(.*)$/i)             { $par{"parE"}=        $1; }
	elsif ($arg=~/^B=(.*)$/i)             { $par{"parB"}=        $1; }
	elsif ($arg=~/^V=(.*)$/i)             { $par{"parV"}=        $1; }
	elsif ($arg=~/^list$/)                { $par{"isList"}=      1; }
	elsif ($arg=~/^skip[A-Za-z]*$/)       { $par{"doNew"}=       0; }

	elsif ($arg=~/^gzip$/)                { $par{"doGzip"}=      1; }
	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}
    }
    print "-*- WARNING iniGetArg: command line arguments overwrite '".$par{"fileDefaults"}."\n" 
	if ($par{"verbose"} && defined %defaults && %defaults);
        
                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    $fileIn=$fileIn[1];
    $fileInOriginal=$fileIn;
				# automatic list finding
    $par{"isList"}= 1           if ($#fileIn==1 && $fileIn =~ /\.list$/);
    $isFastaMul=0;
    $isFastaMul=1               if (-e $fileIn && &isFastaMul($fileIn));

    die ("missing input $fileIn\n") if (! -e $fileIn);
    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);

				# correct settings
    if (! $par{"takeAll"}){
	$par{"takeAll"}=1 if ($par{"takePdb"} && $par{"takeSwiss"} && $par{"takeTrembl"});
    }
    else {
	$par{"takeAll"}=0 if (! $par{"takePdb"} || ! $par{"takeSwiss"} || ! $par{"takeTrembl"});
    }
	

				# ------------------------------
				# final settings
    return(&errSbr("please provide 'ARCH=XYZ' on the command line, or do 'setenv ARCH XYZ'".
		   " in your shell")) if (! defined $ARCH);

    $Lok=			# standard settings
	&brIniSet;              return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);
    $#fileOut=0;                # reset output files
    $fileOut=$par{"fileOut"};
    if (! defined $fileOut || ! $fileOut || length($fileOut)<1){
	if ($#fileIn > 1){
	    $tmp="out-blast";}
	else {
	    $tmp=$fileIn; $tmp=~s/^.*\/|\..*$//g;}
	$fileOut=$par{"fileOut"}=$par{"dirOut"}.$tmp.$par{"extOut"};
	if (0){			# xyz
	    foreach $it (1..$#fileIn){
		$tmp=$fileIn[$it]; $tmp=~s/^.*\///g;$tmp=~s/$par{"extHssp"}//g;
		$fileOut=$par{"dirOut"}.$tmp.$par{"extOut"};
		push(@fileOut,$fileOut); }}}
				# ------------------------------
                                # check errors
                                # to exclude from error check
    $exclude="exe,fileDefaults,".
        "exeSetdb,exeFormatdb,exeBlastp,exeBlast3,exeCopf,exeConvertSeq,";
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n",$msg)) if (! $Lok);  
                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0 && ! $par{"debug"}) {
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($par{"verbose"});
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$par{"fileOutScreen"}=0;
	$fhTrace="STDOUT";}
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
}				# end of iniBlast2rdb

#===============================================================================
sub iniDefBlast {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefBlast                 initialise defaults
#-------------------------------------------------------------------------------
                                # d.d
                                # ------------------------------
                                # default file
#    $par{"fileDefaults"}=       "/home/rost/nn/src/nn.defaults";
#    $par{"fileDefaults"}=       ""; # file with defaults
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/";
    $par{"dirPerl"}=            $par{"dirHome"}. "perl/" # perl libraries
        if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $par{"dirPerl"}. "scr/"; # perl scripts needed
    $par{"dirPub"}=             "/home/rost/pub/";

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory

    $par{"dirData"}=            "/data/";

                                # further on work
				# --------------------
				# files
    $par{"title"}=              "unk";                           # output files will be called 'Pre-title.ext'
    $par{"titleTmp"}=           "TMPBLAST".$$;                    # title for temporary files

    $par{"fileOut"}=            0;
    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE-". "jobid".".tmp"; # file tracing warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN-"."jobid".".tmp"; # file for running system commands

    $par{"fileOutStderr"}=      $par{"titleTmp"}."STDERR"."jobid".".tmp"; # file for running system commands

#    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE". ".tmp"; # file tracing warnings and errors
#    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN".".tmp"; # file for running system commands

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".rdbBlast";
				# file handles
    $fhout=                     "FHOUT";
#    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";
    $fhBlastSummary=            "FHBLAST_SUMMARY";

                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=            1; # blabla on screen
    $par{"verb2"}=              0; # more verbose blabla

    $par{"optNice"}=            "nice -15";

    $par{"doGzip"}=             0; # if 1: will automatically gzip all output files
				# --------------------
				# parameters
    $par{"doThresh"}=           1;  # if 1: extract BLAST hits according to HSSP threshold
    
    $par{"minDist"}=           -10; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
    $par{"minLali"}=           12; # minimal alignment length to consider hit
#    $par{""}=                   "";
    $par{"minProbBlast"}=     10**-222; # fill in for non-specified prob (below accuracy)

    $par{"isList"}=             0; # assume input file is list of FASTA files, or FASTAmul
    $par{"doNew"}=              1; # overwrite existing BLAST files (i.e. run again)
    $par{"LidLowerCase"}=       0; # convert ids to lower case if = 1

    $par{"Lidpurgedb"}=         1; # delete db identifier from output
    $par{"Lsplit"}=             0; # writes RDB for each input file


    $par{"takePdb"}=            0; # only write PDB hits
    $par{"takeSwiss"}=          0; # only write SWISS-PROT hits
    $par{"takeTrembl"}=         0; # only write Trembl hits
    $par{"takeAll"}=            1; # write all
    
				# --------------------
				# executables
#    $par{"exe"}=                "";
    $par{"exeCopf"}=            $par{"dirPerlScr"}. "copf.pl";
#    $par{""}=                   "";

    $par{"exeGzip"}=            "/usr/local/bin/gzip";
    $par{"exeGunzip"}=          "/usr/local/bin/gunzip";

    @kwdBlastSummary=
	("id",
#	 "len",
	 "lali",
	 "pide","dist",
	 "prob",
         "score"
	 );
}				# end of iniDefBlast

#===============================================================================
sub blast2rdbRdlist {
    local($fileInLoc,$titleLoc,$dirWorkLoc,$extLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blast2rdbRdlist             reads input file list (BLAST format)
#       in:                     $fileInLoc
#       in:                     $titleLoc   : title for temporary files    if = 0: 'TMP-$$'
#       in:                     $dirWorkLoc : working dir (for temp files) if = 0: ''
#       in:                     $extLoc     : extension of output files    if = 0: '.fasta'
#       out:                    1|0,msg,@fileWritten
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."blast2rdbRdlist";$fhinLoc="FHIN_"."blast2rdbRdlist";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $titleLoc=  "TMP-".$$       if (! defined $titleLoc && ! $titleLoc);
    $dirWorkLoc=  ""            if (! defined dirWorkLoc && ! dirWorkLoc);
    $dirWorkLoc.="/"            if ($dirWorkLoc !~/\/$/ && length($dirWorkLoc)>=1);
    $extLoc=  ".fasta"          if (! defined $extLoc && ! $extLoc);
    $#fileTmp=0;
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
}				# end of blast2rdbRdlist

#===============================================================================
sub summaryFileFin {
    my($sbr,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   summaryFileFin              writes the final summary
#       in/out GLOBAL:          all (except for error stuff)
#       in:                     $fileInLoc
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR=$scrName.":"."summaryFileFin";  $fhinLoc="FHIN_".$SBR;

				# ------------------------------
				# rename if already written
    if (defined $fileOut{$fileOut}){
	$fileOut=$fileInOriginal;
	$fileOut=~s/^.*\///g;
	$fileOut=~s/\..*$//g;
	$fileOut=$par{"dirOut"}.$fileOut.$par{"extOut"};}
    if (defined $fileOut{$fileOut}){
	$fileOut="Out-blast2rdb.rdb";
    }

				# 
				# ------------------------------
				# open output file
				# ------------------------------
    open($fhout,">".$fileOut) || 
	return(&errSbr("fileOut=$fileOut, not created")); 

				# ------------------------------
				# write header 
				# OUT GLOBAL: %form{kwd} = 
				#     format to write column kwd in
				# ------------------------------

    ($Lok,$msg)=
	&summaryFileFinHdr
	    ($fhout);		return(&errSbrMsg("failed writing header onto $fhout (fileout=$fileOut)",
						  $msg)) if (! $Lok);

				# --------------------------------------------------
				# read temporary file AND  write output file
				# --------------------------------------------------
    
    open($fhinLoc, $fileBlastSummaryTmp) || 
	return(&errSbr("failed opening file $fileBlastSummaryTmp",$SBR));

    $sepLoc="\t";

    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
				# ------------------------------
				# names
	next if ($_=~/^(numfile|id)/);
				# ------------------------------
				# data
				# ------------------------------
	$rd=$_; $rd=~s/[\t\s]*$//g;
	@tmp=split(/[\s\t]+/,$rd);

	$tmpWrt=                "";

	foreach $kwd ("id1","id2",
		      @kwdBlastSummary) {
	    next if ($kwd eq "id");
				# pointer to number of column
				# note: comes from summaryFileTmpOpen
	    $col=$ptr_colFileTmp{$kwd};
	    $tmp="";
	    $tmp=$tmp[$col]     if (defined $tmp[$col] && length($tmp[$col])>0);
	    $tmp=~s/\s*//g;	# purge blanks
	    $form="\%-s";	# format of printf
	    $form=$form{$kwd}   if (defined $form{$kwd});
	    if    ($form=~/[fde]/ && ($tmp!~/\d/ || length($tmp)<1 || $tmp=~/^\W*$/)){
		$form="\%-s";}
	    elsif ($form=~/d$/ && $tmp=~/\D/){
		$form=~s/d$/s/;	}
	    elsif ($form=~/[fe]$/ && $tmp=~/[^0-9\.\-]/){
		$form=~s/\.\d+[fe]$/s/;}
	    $tmpWrt.=           sprintf ("$form".$sepLoc,$tmp); 
	}
	$tmpWrt=~s/$sepLoc*$//g;

	print $fhout $tmpWrt,"\n";
	if ($par{"verb2"} || $par{"debug"}) { 
	    $tmpWrt=~s/$sepLoc/ /g;
	    print    " ",$tmpWrt,"\n"; 
	}
    }
    close($fhinLoc);close($fhout);

    return(1,"ok $SBR");
}				# end of summaryFileFin

#===============================================================================
sub summaryFileFinHdr {
    my($fhoutLoc)=@_;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   summaryFileFinHdr           writes the header for the final summary file
#       in/out GLOBAL:          all (except for error stuff)
#       out GLOBAL:             %form{kwd} = format to write column kwd in
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR=$scrName.":"."summaryFileFinHdr";
				# ------------------------------
				# defaults
				# ------------------------------
    $form{"id"}=   "%-15s"; $form{"id1"}=$form{"id2"}=$form{"id"};
    $form{"len"}=  "%5d";
    $form{"lali"}= "%4d";
    $form{"pide"}= "%5.1f";
    $form{"dist"}= "%5.1f";
    $form{"prob"}= "%10.3e";
    $form{"score"}="%5.1f";
    $sepLoc="\t";
    $sepLoc=" "                 if ($fhoutLoc eq "STDOUT");
    undef %tmp;
				# ------------------------------
				# header defaults
				# ------------------------------
    $tmp{"nota","id1"}=         "guide sequence";
    $tmp{"nota","id2"}=         "aligned sequence";
    $tmp{"nota","len"}=         "length of aligned sequence";
    $tmp{"nota","lali"}=        "alignment length";
    $tmp{"nota","pide"}=        "percentage sequence identity";
    $tmp{"nota","dist"}=        "distance from new HSSP curve";
    $tmp{"nota","prob"}=        "BLAST probability";
    $tmp{"nota","score"}=       "BLAST raw score";

    $tmp{"nota","expect"}="";
    foreach $kwd (@kwdBlastSummary) {
	if ($kwd=~/^id/){
	    $tmp{"nota","expect"}.="id1,id2,";}
	else {
	    $tmp{"nota","expect"}.="$kwd,";}}
	    
    $tmp{"nota","expect"}=~s/,*$//g;


    $tmp{"para","expect"}="";
    if ($par{"minLali"} && $par{"minLali"}>0){
	$tmp{"para","expect"}.="minLali,";
	$tmp{"para","minLali"}=$par{"minLali"};
	$tmp{"form","minLali"}="%5d"; }
    if ($par{"minDist"})                     {
	$tmp{"para","expect"}.="minDist,";
	$tmp{"para","minDist"}=$par{"minDist"};
	$tmp{"form","minDist"}="%6.1f"; } 
    $tmp{"para","expect"}=~s/,*$//g; 

				# ------------------------------
				# write header
				# ------------------------------
    ($Lok,$msg)=
	&rdbGenWrtHdr($fhoutLoc,%tmp);
    return(&errSbrMsg("failed writing RDB header (lib-br:rdbGenWrtHdr)",$msg)) if (! $Lok); 
    undef %tmp;                # slim-is-in!
    
				# ------------------------------
				# write names
				# ------------------------------

    $formid=$form{"id"};
    $fin=""; $form=$formid;   $form=~s/(\d+)\.*\d*[dfs].*/$1/;$form.="s";
    $fin.= sprintf ("$form$sepLoc","id1"); 
    foreach $kwd (@kwdBlastSummary) {
	$form=$form{$kwd}; 
	$form=~s/(\d+)\.*\d*[defs].*/$1/;$form.="s";
	$kwd2=$kwd;
	$kwd2="id2" if ($kwd eq "id");
	$fin.= sprintf ("$form$sepLoc",$kwd2); 
    }
    $fin=~s/$sepLoc$//;
    print $fhoutLoc "$fin\n";

    return(1,"ok $SBR");
}				# end of summaryFileFinHdr

#===============================================================================
sub summaryFileTmpOpen {
    my($sbr);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   summaryFileTmpOpen          names temporary file, opens it, writes header
#       in/out GLOBAL:          all (except for error stuff)
#       out GLOBAL:             $ptr_colFileTmp{$kwd}=number_of_column 
#                                   $kwd=id1|id2|@kwdBlastSummary (except 'id')
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR=$scrName.":"."summaryFileTmpOpen";
				# name
    $fileBlastSummaryTmp=$par{"dirWork"}.$par{"titleTmp"}."summary.tmp";
				# to be removed in the end!
    push(@fileRm,$fileBlastSummaryTmp);
				# open
    open($fhBlastSummary,">".$fileBlastSummaryTmp) || 
	die "*** $scrName failed creating temporary BLAST_summary file ".
	    " ($fileBlastSummaryTmp,$fhBlastSummary)"; 
				# 
				# write header
				# 
				# NOTE: first column name recognised by
				#       subsequent sbr 'summaryFileFin'
				#       -> if change here, do there as well!!
				#       

    $tmpWrt=         "# Perl-RDB\n"."# \n";
    $tmpWrt.=        "numfile"."\t"."id1";
    $ptr_colFileTmp{"id1"}=2;
    $ctcol=2;
    foreach $kwd (@kwdBlastSummary){
	++$ctcol;
	if ($kwd =~/^id/) {	# note in blast summary id=id of 2nd
	    $tmpWrt.="\t"."id2";
	    $ptr_colFileTmp{"id2"}=$ctcol; }
	else {
	    $tmpWrt.="\t".$kwd;
	    $ptr_colFileTmp{$kwd}=$ctcol; }
    }
    print $fhBlastSummary $tmpWrt,"\n"; 
}				# end of summaryFileTmpOpen

#===============================================================================
sub summaryFileTmpWrt1 {
    my($fileBlastLoc)=@_;
    my($SBR,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   summaryFileTmpWrt1          writes the BLAST for one line
#       in/out GLOBAL:          all (except for error stuff)
#       in:                     $fileOUT
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR=$scrName.":"."summaryFileTmpWrt1";
    $fhoutLoc="FHOUT_"."summaryFileTmpWrt1";

    ($Lok,$msg,$rh_tmp)=
	&blastGetSummary_5($fileBlastLoc,$par{"minLali"},$par{"minDist"});

    if (! $Lok){ print "*** $SBR detected error when callling '' with file=$fileBlastLoc\n";
		 print $fhTrace 
		     "*** $SBR detected error when callling '' with file=$fileBlastLoc:\n",
		     $msg,"\n"; 
				# ******************************
				# ACTION: clean and leave!
		 undef %{$rh_tmp}; # slim-is-in
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		 return; }	# ERROR:  early return !
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    if (defined $rh_tmp->{"NROWS"} && $rh_tmp->{"NROWS"} > 0){
	$numPairsOk=$rh_tmp->{"NROWS"}; }
    else { 
	$numPairsOk=0;}

    $tmpWrt="";
    $formProb="%10.3e";
    $formProb= $form{"prob"}     if (defined $form{"prob"});
    $#tmpWrt=0;
    foreach $it (1..$numPairsOk){
	$tmpWrt=         $ctfile."\t".$idIn;
				# check id
	$Lok=1;
	if (! $par{"takeAll"}){
	    $id2=$rh_tmp->{"id",$it};
	    $Lok=0;
	    if    ($par{"takePdb"}    && $id2=~/pdb\|/){
		$Lok=1;}
	    elsif ($par{"takeSwiss"}  && $id2=~/swiss\|/){
		$Lok=1;}
	    elsif ($par{"takeTrembl"} && $id2=~/trembl\|/){
		$Lok=1;}
	}
	if (! $Lok){		# not correct database
	    print "$SBR skipped $id2\n" if ($LdebugLoc);
	    next;
	}
	$rh_tmp->{"id",$it}=~s/^.*\|//g if ($par{"Lidpurgedb"}); 
	    
	foreach $kwd (@kwdBlastSummary){
				# all character or integer
	    if    ($kwd=~/^(id|len|lali|pide)/){
		$tmpWrt.="\t".$rh_tmp->{$kwd,$it}; }
	    elsif ($kwd=~/^prob/){ # prob
		$tmp=$rh_tmp->{$kwd,$it};
		$tmp="10".$tmp  if ($tmp=~/^e/);
		$tmpWrt.=sprintf("\t".$formProb,$tmp); 
	    }
	    else {	# real
		$tmpWrt.=sprintf("\t%7.1f",$rh_tmp->{$kwd,$it}); 
	    }}
	push(@tmpWrt,$tmpWrt);
    }				# end of loop over all pairs

				# print to file
    print $fhBlastSummary 
	join("\n",@tmpWrt),"\n";

				# one output for each input
    if ($par{"Lsplit"}){
	$fileOutTmp=$fileBlastLoc;
	$fileOutTmp=~s/^.*\///g;
	$fileOutTmp=~s/\..*$//g;
	$fileOutTmp=$par{"dirOut"}.$fileOutTmp.$par{"extOut"};
	open($fhoutLoc,">".$fileOutTmp) ||
	    warn("*** $SBR failed creating file=$fileOutTmp!\n");
				# header
	$tmpWrt=         "# Perl-RDB\n"."# \n";
	$tmpWrt.=        "id1";
	$ptr_colFileTmp{"id1"}=2;
	$ctcol=2;
	foreach $kwd (@kwdBlastSummary){
	    ++$ctcol;
	    if ($kwd =~/^id/) {	# note in blast summary id=id of 2nd
		$tmpWrt.="\t"."id2";
		$ptr_colFileTmp{"id2"}=$ctcol; }
	    else {
		$tmpWrt.="\t".$kwd;
		$ptr_colFileTmp{$kwd}=$ctcol; }
	}
	print $fhoutLoc 
	    $tmpWrt,"\n"; 
	foreach $tmpWrt (@tmpWrt){
	    $tmpWrt=~s/^\d+\t//g;
	    print $fhoutLoc 
		$tmpWrt,"\n"; 
	}
	close($fhoutLoc);
	$fileOut{$fileOutTmp}=1;
    }

    undef %{$rh_tmp};		# slim-is-in
    $#tmpWrt=0;
    $tmpWrt="";
}				# end of summaryFileTmpWrt1


