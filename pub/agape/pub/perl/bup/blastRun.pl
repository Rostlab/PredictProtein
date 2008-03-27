#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "simply runs the old BLASTP (officially: blast2)";
$scrIn=      "fasta-file(s), or list-thereof, or FASTAmul";
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
    &blastRunLoc(@ARGV);

print "*** $scrName: final msg=".$msg."\n" if (! $Lok);

exit;

#===============================================================================
sub blastRunLoc {
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastRunLoc                 runs BLASTP (designed to become package)
#       in:                     $fileInLoc,fileOut=$fileOut, asf. ...
#                               input like for any script
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."blastRunLoc";$fhinLoc="FHIN_"."blastRunLoc";
    
				# ------------------------------
    ($Lok,$msg)=		# initialise variables
	&iniBlast;
    if (! $Lok) { print "*** ERROR $scrName after iniBlast\n",$msg,"\n";
		  die '*** during initialising $scrName   ';}
				# ------------------------------
				# (0) format db and setenv
				# ------------------------------
    if ($par{"doFormat"}){      # format db
        if ($par{"doBlast3"}){  # new blast -> formatdb
            ($Lok,$msg,$par{"dbBlast"})=
		&blast3Formatdb($par{"exeFormatdb"},0,$par{"exeSetdb"},$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("failed on setdb (".$par{"exeSetdb"}.") for db=".
                              $par{"dbBlast"},$msg)) if (! $Lok); } 
        else {
            ($Lok,$msg,$par{"dbBlast"})=
		&blastpFormatdb($par{"dbBlast"},0,$par{"exeSetdb"},$par{"fileOutScreen"},$fhTrace);
	    return(&errSbrMsg("failed on setdb (".$par{"exeSetdb"}.") for db=".
                              $par{"dbBlast"},$msg)) if (! $Lok); } }
                                # ------------------------------
    ($Lok,$msg)=                # setenv
        &blastSetenv($par{"BLASTMAT"},$par{"BLASTDB"});
    return(&errSbrMsg("failed setting env for BLAST",$msg)) if (! $Lok);

				# --------------------------------------------------
				# (1) read input file list
				# --------------------------------------------------
    if ($par{"isList"} || $isFastaMul){
	print "--- $sbrName: assumed fileIn=$fileIn, is list\n"     if (! $isFastaMul);
	print "--- $sbrName: assumed fileIn=$fileIn, is fastaMul\n" if ($isFastaMul);
        ($Lok,$msg,@fileIn)=
	    &blastRunRdlist($fileIn,$par{"titleTmp"},$par{"dirWork"},$par{"extFasta"});
	return(&errSbrMsg("failed reading list=$fileIn (blastRunRdList)",$msg)) if (! $Lok);
                                # temporary files to remove
        if ( $isFastaMul && ! $par{"debug"}){
            foreach $file (@fileIn){
                push(@fileRm,$file);}} }
				# --------------------------------------------------
				# (2) convert all to FASTA format
				# --------------------------------------------------
    if (! &isFasta($fileIn[1])){
        ($Lok,$msg,@fileTmp)=
	    &copf2fasta($par{"exeCopf"},$par{"exeConvertSeq"},1,$par{"titleTmp"},$par{"extFasta"},
                        $par{"dirWork"},$par{"fileOutScreen"},$fhTrace,@fileIn);
        return(&errSbrMsg("failed converting to FASTA",$msg)) if (! $Lok);
        return(&errSbrMsg("N files converted=".$#fileTmp.", N files in=".$#fileIn,$msg)) 
            if ($#fileTmp != $#fileIn);
        $Lchange=0;
        foreach $it (1..$#fileTmp){
            if ($fileTmp[$it] ne $fileIn[$it]){
                $Lchange=1;
                push(@fileRm,$fileTmp[$it]); }}
        @fileIn=@fileTmp; }

				# --------------------------------------------------
				# (3) loop over all input file(s)
    undef %finMain;		# --------------------------------------------------
    $#idIn=0; $ctfileMain=0;
    foreach $fileIn (@fileIn){
	if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n"; 
                          next;}
	++$ctfileMain; $idIn=$fileIn;$idIn=~s/^.*\/|\..*$//g;  push(@idIn,$idIn);      

                                # ##############################
				# finally run BLAST
	$fileBlast=$par{"dirOut"}.$idIn.$par{"extBlast"}; 
	$Lskip=0;
	$Lskip=1                if (! $par{"doNew"} && -e $fileBlast);
				# simple BLASTP (blast2)   <<< BLASTP
	if (! $Lskip && ! $par{"doBlast3"}){
	    print $fhTrace "--- run blast2 $fileIn -> $fileBlast (db=",$par{"dbBlast"},")\n";
	    ($Lok,$msg)= 
		&blastpRunSimple($fileIn,$fileBlast,$par{"exeBlastp"},$par{"dbBlast"},
				 $par{"parE"},$par{"parB"},$par{"fileOutScreen"},$fhTrace); 
	    return(&errSbrMsg("failed blastp (".$par{"exeBlastp"}.
			      ": $fileIn->$fileBlast)",$msg)) if (! $Lok); }

	elsif (! $Lskip){	# PSI blast (blast3)        <<< NEW BLAST3
	    print $fhTrace "--- run blast3 $fileIn -> $fileBlast (db=",$par{"dbBlast"},")\n";
	    ($Lok,$msg)= 
		&blast3RunSimple($fileIn,$fileBlast,$par{"exeBlast3"},$par{"dbBlast"},
				 $par{"parE"},$par{"parB"},$par{"fileOutScreen"},$fhTrace); 
	    return(&errSbrMsg("failed blast3 (".$par{"exeBlast3"}.
			      ": $fileIn->$fileBlast)",$msg)) if (! $Lok); }
                                # END of blast for 1 file  
                                # ##############################

                                # ------------------------------
	if ($par{"doThresh"}){  # read header -> threshold
	    undef %tmp;
            ($Lok,$msg,%tmp)=
                &blastGetSummary($fileBlast,$par{"minLali"},$par{"minDist"});
            &errSbrMsg("failed extracting the BLAST output ($fileBlast)",$msg) if (! $Lok);
	    if (defined $tmp{"NROWS"} && $tmp{"NROWS"} > 0){
		$finMain{"$ctfileMain"}=$tmp{"NROWS"}; }
	    else {
		$finMain{"$ctfileMain"}=0;}
	    $finMain{"id","$ctfileMain"}=$idIn;
	    printf 
		"--- %-40s %4d (%4.1f perc of job): num ok=%5d\n",
		$fileIn,$ctfileMain,(100*$ctfileMain/$#fileIn),$finMain{"$ctfileMain"};

	    foreach $it (1..$finMain{"$ctfileMain"}){
		foreach $kwd (@kwdBlastSummary){
		    $finMain{"$ctfileMain","$kwd","$it"}=$tmp{"$kwd","$it"}; }}
				# security: first must have defined values!
	    if ($ctfileMain==1 && $finMain{"$ctfileMain"} == 0){
		foreach $kwd (@kwdBlastSummary){
		    $finMain{"$ctfileMain","$kwd","1"}=" ";}}
	}
        undef %tmp;             # slick-is-in !
    }				# end of loop over all input files
				# --------------------------------------------------

    $finMain{"NROWS"}= $ctfileMain  if ($par{"doThresh"});

				# --------------------------------------------------
				# (4) final: report which ones ok
				# --------------------------------------------------
    if ($par{"doThresh"}){
        $finMain{"para","expect"}="";
        if ($par{"minLali"} && $par{"minLali"}>0){
	    $finMain{"para","expect"}.="minLali,";
	    $finMain{"para","minLali"}=$par{"minLali"};
	    $finMain{"form","minLali"}="%5d"; }
        if ($par{"minDist"})                     {
	    $finMain{"para","expect"}.="minDist,";
	    $finMain{"para","minDist"}=$par{"minDist"};
	    $finMain{"form","minDist"}="%6.1f"; } 
        $finMain{"para","expect"}=~s/,*$//g; 
#	undef $finMain{"para","expect"} if (length($finMain{"para","expect"})<1);

	if ($par{"verbose"} || $par{"debug"}) { 
            $finMain{"sep"}=" ";
            &blastWrtSummary(0,%finMain); }

	$finMain{"sep"}="\t";
        ($Lok,$msg)=
	    &blastWrtSummary($fileOut,%finMain); 
	                         return(&errSbrMsg("error from writing summary:",$msg)) if (! $Lok);
	print "--- output in $fileOut\n"; }

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

    return(1,"ok $sbrName");
}				# end of blastRunLoc

#===============================================================================
sub iniBlast {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniBlast                    initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName".":iniBlast";
    $par{"dirPerl"}=            "/home/rost/perl/"; # directory for perl scripts needed
    $dir=0;			# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/){$dir=$1;}
	elsif ($arg=~/ARCH=(.*)$/)  {$ARCH=$1;}
    }
    $ARCH=$ENV{'ARCH'}          if (! defined $ARCH && defined $ENV{'ARCH'});
    $dir=$dir || "/home/rost/perl/" || $ENV{'PERLLIB'} || 
	$par{"dirPerlLib"} || $par{"dirPerlLib"} || $par{"dirPerl"};
    $dir.="/" if (-d $dir && $dir !~/\/$/);
    $dir= ""  if (! defined $dir || ! -d $dir);
				# ------------------------------
				# include perl libraries
    foreach $lib("lib-ut.pl","lib-br.pl"){
	require $dir.$lib ||
	    die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate;
				# ------------------------------
				# first settings for parameters 
    &iniDefBlast;			# NOTE: may be overwritten by DEFAULT file!!!!

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
    $tmp{"special"}=         "skip".",". "list".",". "filter".",". "format".",". "psi".",";
    $tmp{"special"}.=        "E".",". "B".",". "db"."," ;
        
    $tmp{"skip"}=            "will not run again if output file existing";
    $tmp{"list"}=            "short for isList=1   -> in file is list of files or FASTAmul";
    $tmp{"filter"}=          "short for doThresh=1 -> filter BLAST output with HSSP thresh";
    $tmp{"E"}=               "short for parE=x     -> set BLAST E parameter";
    $tmp{"B"}=               "short for parB=x     -> set BLAST B parameter";
    $tmp{"format"}=          "will format db first   (blastp: SETDB, blast3: FORMATDB)\n";
    $tmp{"format"}.=    "---                   if you do want this, provide the FASTA-\n";
    $tmp{"format"}.=    "---                   formatted file to BLAST against by arg:\n";
    $tmp{"format"}.=    "---                   'db=your_database_file'";
    $tmp{"psi"}=             "will run PSI-blast     (note: default = BLASTP, i.e. blast2)";
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
	&brIniGetArg;
    foreach $arg (@argUnk){     # interpret specific command line arguments
	if    ($arg=~/^fileOut=(.*)$/)        { $par{"fileOut"}=    $1; 
						$par{"doThresh"}=   1; }
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}=    "nice -".$1; }
	elsif ($arg eq "nonice")              { $par{"optNice"}=    " "; }
	elsif ($arg eq "debug")               { $par{"debug"}=      1; }
	elsif ($arg=~/^filter$/)              { $par{"doThresh"}=   1; }
	elsif ($arg=~/^doThresh$/)            { $par{"doThresh"}=   1; }
	elsif ($arg=~/^noThresh$/)            { $par{"doThresh"}=   0; }
	elsif ($arg=~/^doThresh=(.*_)$/)      { $par{"doThresh"}=   $1; }
	elsif ($arg=~/^db=(.*)$/)             { $par{"dbBlast"}=    $1; }
	elsif ($arg=~/^format$/)              { $par{"doFormat"}=   1; }
	elsif ($arg=~/^psi$/)                 { $par{"doBlast3"}=   1; }
	elsif ($arg=~/^E=(.*)$/i)             { $par{"parE"}=       $1; }
	elsif ($arg=~/^B=(.*)$/i)             { $par{"parB"}=       $1; }
	elsif ($arg=~/^list$/)                { $par{"isList"}=     1; }
	elsif ($arg=~/^skip[A-Za-z]*$/)       { $par{"doNew"}=0; }
	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}}
    print "-*- WARNING iniGetArg: command line arguments overwrite '".$par{"fileDefaults"}."\n" 
	if ($par{"verbose"} && defined %defaults && %defaults);
        
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
                                # special settings
                                # 'dir/title' -> 'title'
    if    ($par{"dbBlast"} =~ /^(.+)\/(.+)$/){
        $par{"BLASTDB"}=$1;
        $par{"dbBlast"}=$2;}
                                # assign defaults
    if    ($par{"dbBlast"} =~ /^phd126/){
        $db=$par{"dbBlast"}=$par{"dbPhd126"};$db=~s/^(.*)\/(.*)$/$1/; $par{"BLASTDB"}=$db; }
    elsif ($par{"dbBlast"} =~ /^phd/){
        $db=$par{"dbBlast"}=$par{"dbPhd"};   $db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }
    elsif ($par{"dbBlast"} =~ /^swiss/){
        $db=$par{"dbBlast"}=$par{"dbSwiss"}; $db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }
    elsif ($par{"dbBlast"} =~ /^prodom/){
        $db=$par{"dbBlast"}=$par{"dbProdom"};$db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }
    elsif ($par{"dbBlast"} =~ /^pdb/){
        $db=$par{"dbBlast"}=$par{"dbPdb"};   $db=~s/^(.*)\/.*$/$1/;   $par{"BLASTDB"}=$db; }
                                # get rid of dir
    foreach $kwd ("BLASTDB","BLASTMAT"){
        $par{"$kwd"}=~s/\/$//g;}
				# which BLAST
    if ($par{"doBlast3"}){
	$par{"extBlast"}=$par{"extBlast3"}; }
    else {
	$par{"extBlast"}=$par{"extBlastp"}; }

				# ------------------------------
                                # check errors
                                # to exclude from error check
    $exclude="exe,fileDefaults,".
        "exeSetdb,exeFormatdb,exeBlastp,exeBlast3,exeCopf,exeConvertSeq,";
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n".$msg)) if (! $Lok);  
				# ------------------------------
				# terminate if no exe
    $Lok=0;
    foreach $kwd ("exeBlastp","exeBlast3"){
	$Lok=1 if (-e $par{"$kwd"} || -l $par{"$kwd"}); }
    if (! $Lok){
	print "*** $sbrName: no exe ok:\n";
	foreach $kwd ("exeBlastp","exeBlast3"){
	    printf "%-15s %-s\n",$kwd,$par{"$kwd"}; }
	die; }
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
}				# end of ini

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
    $par{"dirBin"}=             "/home/rost/pub/molbio/bin/"; # FORTRAN binaries of programs needed

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory

    $par{"dirData"}=            "/home/rost/data/";
    $par{"dirPdb"}=             "/home/rost/pub/molbio/db/";
#    $par{""}=                   "";
    $par{"dbPdb"}=              "/home/rost/pub/molbio/db/pdb";
    $par{"dbSwiss"}=            "/home/rost/data/swiss/swiss";
    $par{"dbProdom"}=           "/home/rost/pub/molbio/db/prodom_34_2";
    $par{"dbPhd"}=              "/home/rost/pub/molbio/db/phd1194";
    $par{"dbPhd126"}=           "/home/rost/pub/molbio/db/phd126";

                                # further on work
				# --------------------
				# files
    $par{"title"}=              "unk";                           # output files will be called 'Pre-title.ext'
    $par{"titleTmp"}=           "TMP-BLAST-";                    # title for temporary files

    $par{"fileOut"}=            0;
    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE-"."jobid".".tmp"; # file tracing warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN-"."jobid".".tmp"; # file for running system commands

#    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE". ".tmp"; # file tracing warnings and errors
#    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN".".tmp"; # file for running system commands

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".rdbBlast";
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
				# --------------------
				# parameters
    $par{"BLASTMAT"}=           "/home/rost/pub/molbio/blast/blastapp/matrix"; # env for BLASTP
    $par{"BLASTDB"}=            "/home/rost/pub/molbio/db/";                    # env for BLASTP
    $par{"BLASTDB"}=            "/home/rost/data/swissprot/"; # 

    $par{"doThresh"}=           1; # if 1: extract BLAST hits according to HSSP threshold
    $par{"doFormat"}=           0; # if 1: format the database for BLAST
    $par{"doBlast3"}=           0; # if 1: format the database for BLAST
    
    $par{"minDist"}=           -5; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
    $par{"minLali"}=           12; # minimal alignment length to consider hit
    $par{"parE"}=            1000;
    $par{"parB"}=            2000;
    $par{"dbBlast"}=            $par{"dbSwiss"};
#    $par{""}=                   "";

    $par{"isList"}=             0; # assume input file is list of FASTA files, or FASTAmul
    $par{"doNew"}=              1; # overwrite existing BLAST files (i.e. run again)

				# --------------------
				# executables
#    $par{"exe"}=                "";
    $par{"exeBlastp"}=          $par{"dirBin"}.    "blastp.ARCH";
    $par{"exeBlast3"}=          $par{"dirBin"}.    "blastall.ARCH";
                                # syntax 'formatdb -t TITLE -i DIR/fasta-file -l logfile'
                                # note:  files will be created in DIR !
    $par{"exeSetdb"}=           $par{"dirBin"}.    "setdb.ARCH";
                                # syntax 'setdb.SGI32 -t TITLE DIR/fasta-file'
                                # note:  files will be created in DIR !
    $par{"exeFormatdb"}=        $par{"dirBin"}.    "formatdb.ARCH";

    $par{"exeCopf"}=            $par{"dirPerlScr"}."copf.pl";
    $par{"exeConvertSeq"}=      "/home/rost/pub/bin/convert_seq98.ARCH";
#    $par{""}=                   "";

    @kwdBlastSummary=
	("id",
#	 "len",
	 "lali",
	 "pide","dist",
#	 "prob","score"
	 );
}				# end of iniDefBlast

#===============================================================================
sub blastRunRdlist {
    local($fileInLoc,$titleLoc,$dirWorkLoc,$extLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastRunRdlist              reads input file list (or chops FASTAmul into many)
#       in:                     $fileInLoc
#       in:                     $titleLoc   : title for temporary files    if = 0: 'TMP-$$'
#       in:                     $dirWorkLoc : working dir (for temp files) if = 0: ''
#       in:                     $extLoc     : extension of output files    if = 0: '.fasta'
#       out:                    1|0,msg,@fileWritten
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."blastRunRdlist";$fhinLoc="FHIN_"."blastRunRdlist";
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
}				# end of blastRunRdlist

