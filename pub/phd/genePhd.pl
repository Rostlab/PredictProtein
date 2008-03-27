#!/usr/bin/perl
##!/usr/bin/perl -w
##!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$scrName=    "genePhd.pl";
$scrIn=      "list-of-seq (or auto for running PHD only)";
$scrGoal=    "runs PHD jobs for entire genome";
$ARCH_DEF=   "SGI64";
$scrNarg=    1;
$scrHelpTxt= "Note: if you provide the name of a genome as argument, do the following: \n";
$scrHelpTxt.=" \n";
$scrHelpTxt.=" -----------------------------------------------------------------------\n";
$scrHelpTxt.=" first run\n";
$scrHelpTxt.=" (1) create a working directory (/home/cubic/gene/work/hs)\n";
$scrHelpTxt.=" (2) create a directory with many FASTA files (one per sequence), name:\n";
$scrHelpTxt.="     -> /home/cubic/gene/work/hs/seq\n";
$scrHelpTxt.=" \n";
$scrHelpTxt.=" -----------------------------------------------------------------------\n";
$scrHelpTxt.=" re-run (of some files, or some programs)\n";
$scrHelpTxt.=" *   either pass all respective directories as arguments (see sbr ini)\n";
$scrHelpTxt.=" *   or:    make sure you use the following dir structure:\n";
$scrHelpTxt.=" \n";
$scrHelpTxt.="     dirWork/seq      dir with all FASTA sequences\n";
$scrHelpTxt.="     dirWork/hssp     HSSP alignments\n";
$scrHelpTxt.="     dirWork/phd      PHD RDB files (note: if 'keepHuman': these to phdx\n";
$scrHelpTxt.="     dirWork/notHtm   files with flag 'is not HTM'\n";
$scrHelpTxt.=" \n";
$scrHelpTxt.="     OPTIONAL:\n";
$scrHelpTxt.=" \n";
$scrHelpTxt.="     dirWork/hsspRaw  HSSP alignments (unfiltered)  \n";
$scrHelpTxt.="     dirWork/phdDssp  PHD converted to DSSP  \n";
$scrHelpTxt.="     dirWork/    \n";
$scrHelpTxt.="     \n";
$scrHelpTxt.=" \n";
$scrHelpTxt.=" -----------------------------------------------------------------------\n";
$scrHelpTxt.=" Run modes\n";
$scrHelpTxt.=" the following run modes are recognised:\n";
$scrHelpTxt.=" *   hssp         run HSSP (multiple sequence alignment)\n";
$scrHelpTxt.=" *   filter       run HSSP filter";
$scrHelpTxt.=" *   \n";
$scrHelpTxt.=" *   phdSec       run PHD secondary structure\n";
$scrHelpTxt.=" *   phdAcc       run PHD solvent accessibility\n";
$scrHelpTxt.=" *   phdBoth      run PHD secondary structure and solvent accessibility\n";
$scrHelpTxt.=" *   \n";
$scrHelpTxt.=" *   phdDssp      convert PHD output to DSSP format\n";
$scrHelpTxt.=" *   phdHtm       run default mode of PHDhtm (with optHtmisitMin=0.8)\n";
$scrHelpTxt.=" *   rdbHtm07     run PHDhtm with optHtmisitMin=0.7\n";
$scrHelpTxt.=" to run many use e.g. the command line argument:\n";
$scrHelpTxt.="     do='hssp,phdBoth,rdbHtm07,rdbHtm08'\n";
$scrHelpTxt.=" \n";
$scrHelpTxt.=" \n";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
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
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	Jinfeng Liu		liu@dodo.cpmc.columbia.edu		       #
#	CUBIC (Columbia Univ)	http://dodo.cpmc.columbia.edu/cubic/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	May,    	1997	       #
#				version 0.11   	Feb,    	1998	       #
#				version 0.2   	May,    	1998	       #
#				version 0.3   	May,    	1999	       #
#				version 0.4   	Jun,    	1999	       #
#				version 0.5   	Jul,    	1999	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();			&errScrDie("after ini",$msg,$scrName) if (! $Lok); 

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
$LcleanUp=0; $LcleanUp=1 if (! $par{"debug"});
				# --------------------------------------------------
				# orientation what is there OR read seq ids
				# --------------------------------------------------
				# recognise: auto, or file with ids
				# output: @id,@fileHssp,$res{$id,"hssp"}= isHssp/empty/..
				#         

($Lok,$msg)=
    &getIdList($ARGV[1],
	       $fhTrace);       &errScrDie("FIRST argument: file with sequences ids or 'auto'\n".
					   "it is: '$ARGV[1]'\n".
					   "after getIdList",$msg,$scrName) if (! $Lok); 

if ($par{"verb2"}){ print $fhTrace "--- $scrName \t wants to read id:\n";
		    foreach $id(@id){
			$tmp=$id;$tmp=~s/^.*\///g;
			print $fhTrace "$id,";} print $fhTrace "\n";}

				# --------------------------------------------------
				# (1) run essentials:
				#     * do alignment (maxhom)
				# --------------------------------------------------
if ($job{"hssp"}) {
    				# out GLOBAL:             @fileSeq
    ($Lok,$msg)=
	&doAli();               &errScrDie("after doAli:\n",$msg,$scrName) if (! $Lok);

				# move alignment results to final locations
    foreach $kwd (@kwdJobs){
	next if (! $job{$kwd});
	next if ($kwd !~/hssp|ali|filter|blast/);
	$dir=$par{$translate_job2dir{$kwd}};
	$ext=$par{$translate_job2ext{$kwd}};
	($Lok,$msg)=
	    &analyseDirs($par{"verbose"},$par{"verb2"},$fhTrace,$dir,$ext,
			 $kwd); &errScrMsg("after analyseDirs:\n",$msg,$scrName) if (! $Lok); }}
    
				# --------------------------------------------------
				# (2) run PHD predictions for all files 
				#      * PHDboth
				#      * PHDhtm (07,08)
				# --------------------------------------------------
if ($par{"do"}=~/^phd|,phd/) {
    ($Lok,$msg)=
	&doPred();              &errScrDie("after doPred:\n",$msg,$scrName) if (! $Lok); 

				# move prediction results to final locations
    foreach $kwd (@kwdJobs){
	next if (! $job{$kwd});
	next if ($kwd !~/^(phd|coils|signalp)/);
	$dir=$par{$translate_job2dir{$kwd}};
	$ext=$par{$translate_job2ext{$kwd}};
	($Lok,$msg)=
	    &analyseDirs($par{"verbose"},$par{"verb2"},$fhTrace,$dir,$ext,
			 $kwd); &errScrMsg("after analyseDirs:\n",$msg,$scrName) if (! $Lok); }}

				# ------------------------------
				# write results
				# ------------------------------
($Lok,$msg)=
    &wrtFin($par{"verbose"},$par{"verb2"},
	    $fhTrace);          &errScrDie("after wrtFin:\n",$msg,$scrName) if (! $Lok); 

exit;

#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub blastpRun {
    local($niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,$envBlastpMat,
	  $envBlastpDb,$nhits,$parBlastpDb,$fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc)=@_;
    local($sbr,$command,$msg,$Lok);
#----------------------------------------------------------------------
#   blastpRun                   runs BLASTP
#       in:                     $niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,
#       in:                     $envBlastpMat,$envBlastpDb,$numHits,$parBlastpDb,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbr="blastpRun";
    $fhTraceLoc="STDOUT"                               if (! defined $fhTraceLoc);
    return(0,"*** $sbr: not def niceLoc!")          if (! defined $niceLoc);
    return(0,"*** $sbr: not def dirData!")          if (! defined $dirData);
    return(0,"*** $sbr: not def dirSwissSplit!")    if (! defined $dirSwissSplit);
    return(0,"*** $sbr: not def exeBlastp!")        if (! defined $exeBlastp);
    return(0,"*** $sbr: not def exeBlastpFil!")     if (! defined $exeBlastpFil);
    return(0,"*** $sbr: not def envBlastpMat!")     if (! defined $envBlastpMat);
    return(0,"*** $sbr: not def envBlastpDb!")      if (! defined $envBlastpDb);
    return(0,"*** $sbr: not def nhits!")            if (! defined $nhits);
    return(0,"*** $sbr: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbr: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbr: not def fileOutFilLoc!")    if (! defined $fileOutFilLoc);

    return(0,"*** $sbr: miss dir =$dirData!")       if (! -d $dirData);
    return(0,"*** $sbr: miss dir =$dirSwissSplit!") if (! -d $dirSwissSplit);
    return(0,"*** $sbr: miss dir =$envBlastpDb!")   if (! -d $envBlastpDb);
    return(0,"*** $sbr: miss dir =$envBlastpMat!")  if (! -d $envBlastpMat);

    return(0,"*** $sbr: miss file=$fileInLoc!")     if (! -e $fileInLoc);
    return(0,"*** $sbr: miss exe =$exeBlastp!")     if (! -e $exeBlastp);
    return(0,"*** $sbr: miss exe =$exeBlastpFil!")  if (! -e $exeBlastpFil);

				# ------------------------------
				# set environment needed for BLASTP
    $ENV{'BLASTMAT'}=$envBlastpMat;
    $ENV{'BLASTDB'}= $envBlastpDb;
                                # ------------------------------
                                # run BLASTP
                                # ------------------------------
    $command="$niceLoc $exeBlastp $parBlastpDb $fileInLoc B=$nhits > $fileOutLoc";
    $msg="--- $sbr '$command'\n";

    ($Lok,$msgSys)=
	&sysSystem("$command" ,$fhTraceLoc);
    if (! $Lok){
	return(0,"*** ERROR $sbr '$Lok'\n".$msg."\n".$msgSys);}
    if (! -e $fileOutLoc){
	return(0,"*** ERROR $sbr no output '$fileOutLoc'\n"."$msg");}
				# ------------------------------
				# extract hits from BLASTP-output
				# ------------------------------
    $dirSwissSplit=~s/\/$//g;
    if ($exeBlastpFil =~/big/) {
	$command="$niceLoc $exeBlastpFil $fileOutLoc db=$parBlastpDb > $fileOutFilLoc ";}
    else {
	$command="$niceLoc $exeBlastpFil $dirSwissSplit < $fileOutLoc > $fileOutFilLoc ";}
    $msg.="--- $sbr '$command'\n";
    print "--- system: \t $command\n";
    
    $msg=
	system("$command");

    return(0,"*** ERROR $sbr after $exeBlastpFil no output '$fileOutFilLoc'\n")
	if (! -e $fileOutFilLoc);

    open("FHIN",$fileOutFilLoc) ||
	return(0,"*** ERROR $sbr after $exeBlastpFil no output '$fileOutFilLoc'\n");
    $firstLine=<FHIN>;
    close(FHIN);

#    $firstLine=`cat $fileOutFilLoc`;
    $firstLine=~s/\s|\n//g;
    return(2,"none found")
	if ($firstLine=~/none/i);
    return(1,"ok $sbr");
}				# end of blastpRun

#===============================================================================
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
                    if (-e $par{$kwd} && ! -x $par{$kwd});}
	elsif($kwd=~/^file/){
	    next if ($par{$kwd} eq "unk" || length($par{$kwd})==0 || !$par{$kwd});
	    $msgHere.="*** ERROR file ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});} # 
    }
    return(0,$msgHere) if ($msgHere=~/ERROR/);
    return(1,"ok $sbrName");
}				# end of brIniErr

#===============================================================================
sub brIniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniGetArg                 standard reading of command line arguments
#       in GLOBAL:              @ARGV,$defaults{},$par{}
#       out GLOBAL:             $par{},@fileIn
#       out:                    @arg_not_understood (i.e. returns 0 if everything ok!)
#-------------------------------------------------------------------------------
    $sbrName=""."brIniGetArg";
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
	if    ($arg=~/^verb\w*3=(\d)/)           {$par{"verb3"}=  $Lverb3=$1;}
	elsif ($arg=~/^verb\w*3/)                {$par{"verb3"}=  $Lverb3=1;}
	elsif ($arg=~/^verb\w*2=(\d)/)           {$par{"verb2"}=  $Lverb2=$1;}
	elsif ($arg=~/^verb\w*2/)                {$par{"verb2"}=  $Lverb2=1;}
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

#===============================================================================
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
    $sbrName="brIniHelp"; 
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

#===============================================================================
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
    $sbrName=""."brIniHelpLoop";$fhinLoc="FHIN_"."brIniHelpLoop";

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
	$ct=0;
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

	    ++$ct;
				# add keyword help
	    if ($ct > 1 && $#ARGV < 2) {
		$ARGV[2]=$ARGV[1];
		$ARGV[1]="help";}

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
    $sbrName=""."brIniHelpRdItself";$fhinLoc="FHIN_"."brIniHelpRdItself";

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

#===============================================================================
sub brIniSet {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniSet                    changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $sbrName="brIniSet";
    @kwdLoc=sort keys(%par)     if (defined %par && %par);
				# ------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwdLoc){
        if (defined $kwd && length($kwd)>=1 && defined $par{$kwd}){
            push(@tmp,$kwd);}
	else { 
	    print "-*- WARN $sbrName: for kwd '$kwd', par{kwd} not defined!\n";}}
    @kwdLoc=@tmp;
				# jobId
    $par{"jobid"}=$$ 
	if (! defined $par{"jobid"} || $par{"jobid"} eq 'jobid' || length($par{"jobid"})<1);
				# ------------------------------
				# add jobid
    foreach $kwd (@kwdLoc){
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
    foreach $kwd (@kwdLoc){	# add 'pre' 'title' 'ext' to output files not specified
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
	foreach $kwd (@kwdLoc){
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
	foreach $kwd (@kwdLoc){	# add directory to executables
	    next if ($kwd !~ /^exe/);
	    next if ($par{$kwd} !~ /ARCH/);
	    $par{$kwd}=~s/ARCH/$ARCH/;}}

				# ------------------------------
    foreach $kwd (@kwdLoc){	# add directory to executables
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

#===============================================================================
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
    $sbrName=""."brIniWrt";
    
    return(0,"*** $sbrName: no settings defined in %par\n") if (! defined %par || ! %par);
    $fhTraceLocSbr="STDOUT"    if (! defined $fhTraceLocSbr || ! $fhTraceLocSbr);

    if (defined $Date) {
	$dateTmp=$Date; }
    else {
	$tmp=`date`; $tmp=~s/\n//g if (defined $tmp);
	$dateTmp=$tmp || "before year 2000"; }

    print $fhTraceLocSbr "--- ","-" x 80, "\n";
    print $fhTraceLocSbr "--- Initial settings for $scrName ($0) on $dateTmp:\n";
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
    foreach $kwd (@kwdDef) {	# parameters
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
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir


#==============================================================================
sub convSeq2fasta {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc,$frag)=@_;
    local($outformat);
#----------------------------------------------------------------------
#   convSeq2fasta               convert all formats to fasta
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="convSeq2Fasta";
    return(0,"*** $sbrName: not def file_in_loc!")      if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")     if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    $frag=0                                             if (! defined $frag);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);

    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $outformat=        "F";     # output format FASTA
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$anF,$file_out_loc,$an2,\"";
        &run_program("$cmd" ,"$fhTraceLoc","warn"); }
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$file_out_loc,$an2,\"";
        &run_program("$cmd" ,"$fhTraceLoc","warn"); }

    return(0,"*** ERROR $sbrName: no output from FORTRAN convert_seq, couldnt run_program cmd=$cmd\n")
        if (! -e $file_out_loc);
    return(1,"ok $sbrName");
}				# end of convSeq2fasta

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
#   errScrMsg                   writes message
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
}				# end of errScrMsg

#===============================================================================
sub errScrDie {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrDie                   writes message and EXIT!!
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
    $sbrName="fastaWrt";$fhoutLoc="FHOUT_"."$sbrName";
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

#===============================================================================
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
    $sbrName=""."fctRunTimeLeft";

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

#===============================================================================
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
sub fileLsAllTxt {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAllTxt                will return all text files in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    $sbrName="fileLsAllTxt";$fhinLoc="FHIN"."$sbrName";
    if (! -d $dirLoc){		# directory empty
	return(0);}
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$line=$_; $line=~s/\s//g;
		       if (-T $line && ($line!~/\~$/)){
			   $tmp=$line;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
			   next if ($tmp=~/\#|\~$/); # skip temporary
#			   next if ($tmp=~/\//);
			   push(@tmp,$line);}}close($fhinLoc);
    return(@tmp);
}				# end of fileLsAllTxt

#==============================================================================
sub fileMv  { local($f1,$f2,$fhoutLoc)=@_; local($tmp);
	      if (! -e $f1){$tmp="*** ERROR 'fileMv' in=$f1, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      $tmp="'\\mv $f1 $f2'";
	      printf $fhoutLoc "--- %-20s %-s\n","&sysMvfile","$tmp" if ($fhoutLoc);
	      $Lok=&sysMvfile($f1,$f2);
	      if (! -e $f2){$tmp="*** ERROR 'fileMv' out=$f2, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      return(1,"$tmp");} # end of fileMv


#==============================================================================
sub fileRm  { 
    local($fhoutLoc,@fileLoc)=@_; local($tmp,@tmp,$Lok,$fileLoc);
    if (-e $fhoutLoc){push(@fileLoc,$fhoutLoc);$fhoutLoc=0;}
    $Lok=1;$#tmp=0;
    foreach $fileLoc(@fileLoc){
        if (-e $fileLoc){
            $tmp="'\\rm $fileLoc'"; push(@tmp,$tmp);
            printf $fhoutLoc "--- %-20s %-s\n","unlink ","$tmp" if ($fhoutLoc);
            unlink($fileLoc);}
        if (-e $fileLoc){
            $tmp="*** ERROR 'fileRm' '$fileLoc' not deleted";
            if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
            $Lok=0; push(@tmp,$tmp);}}
    return($Lok,@tmp);}         # end of fileRm

#==============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#                               kwd  = noSearch -> no DB search
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
    if (-d $Lscreen) { 
	@dir=($Lscreen,@dir);
	$Lscreen=0;}
    $fileInLoc=~s/\s|\n//g;
				# ------------------------------
				# is HSSP ok
    return($fileInLoc," ")      if (-e $fileInLoc && &is_hssp($fileInLoc));

				# ------------------------------
				# purge chain?
    if ($fileInLoc=~/^(.*\.hssp)_?([A-Za-z0-9])$/){
	$file=$1; $chainLoc=$2;
	return($file,$chainLoc) if (-e $file && &is_hssp($file)); }

				# ------------------------------
				# try adding directories
    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/hssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/hssp/") if (!$Lok); # give default

				# ------------------------------
				# before trying: purge chain
    $file=$fileInLoc; $chainLoc=" ";
    $file=~s/^(.*\.hssp)_?([A-Za-z0-9])$/$1/; 
    $chainLoc=$2 if (defined $2);
				# loop over all directories
    $fileHssp=
	&hsspGetFileLoop($file,$Lscreen,@dir);
    return($fileHssp,$chainLoc) if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
                                # still not: dissect into 'id'.'chain'
    $tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
    $fileHssp=
        &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
    return($fileHssp,$chainLoc)    if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
				# change version of file (1sha->2sha)
    $tmp1=substr($idLoc,2,3);
    foreach $it (1..9) {
        $tmp_file="$it"."$tmp1".".hssp";
        $fileHssp=
            &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
	last if ($fileHssp ne "0");}
    return (0)                  if ( ! -e $fileHssp || &is_hssp_empty($fileHssp));
    return($fileHssp,$chainLoc);
}				# end of hsspGetFile

#==============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# missing extension
    $fileInLoop.=".hssp"        if ($fileInLoop !~ /\.hssp/);
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	$tmp=~s/\/\//\//g;	# '//' -> '/'
	print "--- hsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_hssp($tmp) );
    }
    return(0);			# none found
}				# end of hsspGetFileLoop

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
sub isHsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isHsspGeneral               checks (and finds) HSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not hssp|isHssp|isHsspList'
#-------------------------------------------------------------------------------
    $sbrName=""."isHsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain) if ((-e $file) && &is_hssp($file));
	return(0,"empty", $file)    	if ((-e $file) && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); }
				# ------------------------------
    if (&is_hssp($fileInLoc)){	# file is hssp
	return(0,"empty hssp",$fileInLoc)
	    if (&is_hssp_empty($fileInLoc));
	return(1,"isHssp",$fileInLoc); } 
				# ------------------------------
				# file is hssp list
    elsif (&is_hssp_list($fileInLoc)) {
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {
	    $_=~s/\n|\s//g;$rd=$_;
	    next if (length($_)==0);
				# file exists ...
	    if    (-e $rd) {
		if (&is_hssp($rd)) { # ... and is HSSP       -> bingo
		    push(@tmpFile,$rd); 
		    push(@tmpChain," "); }
		next; }		     # ... may just be empty -> skip
				# file does NOT exist (chain? dir?)
	    ($file,$chain)=	# search again
		&hsspGetFile($rd,1,@dirLoc);
				# ... bingo
	    if    (-e $file && &is_hssp($file)) { 
		push(@tmpFile,$file);
		push(@tmpChain,$chain); }
	    next;		# GIVE UP ...
	} close($fhinLoc);
				# ... none in list ??
	return(0,"none in list",$fileInLoc) if ($#tmpFile==0);
				# ok -> go home
	return(1,"isHsspList",@tmpFile,"chain",@tmpChain);}
    
				# ------------------------------
    else {			# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain)     if (-e $file && &is_hssp($file));
	return(0,"empty" ,$file,"err")      if (-e $file && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); 
    }
}				# end of isHsspGeneral

#==============================================================================
sub isPir {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isPir                    checks whether or not file is in Pir format 
#                               (first line /^>P1\;/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_PIR",$fileLoc) || return(0);
    $one=(<FHIN_PIR>);close(FHIN_PIR);
    return(1)                   if (defined $one && $one =~ /^\>P1\;/i);
    return(0);
}				# end of isPir

#==============================================================================
sub isSwiss {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_SWISS";
    open("$fhinLoc","$fileLoc"); $Lok=0;
    while (<$fhinLoc>){ 
	$Lok=1                  if ($_=~/^ID   /);
	last;}
    close($fhinLoc);
    return($Lok);
}				# end of isSwiss

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc) ;
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1 if (/^HSSP/) ; 
	last; }
    close($fh);
    return $Lis;
}				# end of is_hssp

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
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     next if (length($fileRd)<5);
		     ($fileLoc,$chainLoc)= 
			 &hsspGetFile($fileRd,$LscreenLoc);
		     $Lis=1 if (&is_hssp($fileLoc));
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#==============================================================================
sub maxhomCheckHssp {
    local ($file_in,$laliPdbMin)=@_;
    local ($sbrName,$len_strid,$Llong_id,$msgHere,$tmp,$found,$posPdb,$posLali,$pdb,$len);
    $[ =1;
#----------------------------------------------------------------------
#   maxhomCheckHssp             checks: (1) any ali? (2) PDB?
#       in:                     $fileHssp,$laliMin (minimal ali length to report PDB)
#       out:                    $Lok,$LisEmpty,$LisSelf,$IsIlyaPdb,$pdbidFound
#       out:                    1 error: (0,'error','error message')
#       out:                    1 ok   : (1,'ok',   'message')
#       out:                    2 empty: (2,'empty','message')
#       out:                    3 self : (3,'self', 'message')
#       out:                    4 pdbid: (4,'pdbid','message')
#----------------------------------------------------------------------
    $sbrName="maxhomCheckHssp";
    return(0,"error","*** $sbrName: not def file_in!")            if (! defined $file_in);
    return(0,"error","*** $sbrName: not def laliPdbMin!")         if (! defined $laliPdbMin);
    return(0,"error","*** $sbrName: miss input file '$file_in'!") if (! -e $file_in &&
								      ! -l $file_in);
				# defaults for reading
    $len_strid= 4;		# minimal length to identify PDB identifiers
    $Llong_id=  0;

    $msgHere="--- $sbrName \t in=$file_in\n";
				# open HSSP file
    open(FILEIN,$file_in)  || 
	return(0,"error","*** $sbrName cannot open '$file_in'\n");
				# ----------------------------------------
				# skip everything before "## PROTEINS"
    $Lempty=1;			# ----------------------------------------
    while( <FILEIN> ) {
	if ($_=~/^PARAMETER  LONG-ID :YES/) { # is long id?
	    $Llong_id=1;}
	if ($_=~/^\#\# PROTEINS/ ) {
	    $Lempty=0;
	    last;}}

    if ($Lempty){		# exit if no homology found
	$msgHere.="no homologue found in $file_in!";
	close(FILEIN);
	return(1,"empty",$msgHere); }
				# ----------------------------------------
				# now search for PDB identifiers
				# ----------------------------------------
    if ($Llong_id){ $posPdb=47; $posLali=86;} else { $posPdb=21; $posLali=60;}
    $found="";
    while ( <FILEIN> ) {
	next if ($_ !~ /^\s*\d+ \:/);
	$pdb=substr($_,$posPdb,4);  $pdb=~ s/\s//g;
	$len=substr($_,$posLali,4); $len=~ s/\s//g;
	if ( (length($pdb) > 1) && ($len>$laliPdbMin) ) { # global parameter
	    $found.=$pdb.", ";} 
	last if ($_=~ /\#\# ALIGNMENT/ ); }
    close(FILEIN);

    if (length($found) > 2) {
	return(1,"pdbid","pdbid=".$found."\n$msgHere"); }

    return(1,"ok",$msgHere);
}				# end of maxhomCheckHssp

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
    if ($tmpNice =~ /\d/ || $tmpNice eq "optNice"){
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
sub maxhomRun {
    local($date,$nice,$LcleanUpLoc,$fhErrSbr,
	  $fileSeqLoc,$fileSeqFasta,$fileBlast,$fileBlastFil,$fileHssp,
	  $dirData,$dirSwiss,$dirPdb,$exeConvSeq,$exeBlastp,$exeBlastpFil,$exeMax,
	  $envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,
	  $fileMaxDef,$fileMaxMetr,$Lprof,$parMaxThresh,$parMaxSmin,$parMaxSmax,
	  $parMaxGo,$parMaxGe,$parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,$parMaxNali,
	  $parMaxSort,$parMaxProfOut,$parMaxStripOut,$parMinLaliPdb,$parMaxTimeOut,
	  $fileScreenLoc)=@_;
    local($sbrName,$tmp,$Lok,$jobid,$msgHere,$msg,$thresh,@fileTmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomRun                   runs Maxhom (looping for many trials + self)
#       in:                     give 'def' instead of argument for default settings
#       out:                    (0,'error','txt') OR (1,'ok','name')
#-------------------------------------------------------------------------------
    $sbrName=""."maxhomRun";

    $date=&sysDate()            if (! defined $date);
	
    $nice=" "                                              if (! defined $nice || $nice eq "def");
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    return(0,"*** $sbrName: not def GLOBAL: ARCH!")        if (! defined $ARCH);
				# ------------------------------
				# input file names
    return(0,"*** $sbrName: not def fileSeqLoc!")          if (! defined $fileSeqLoc);
    return(0,"*** $sbrName: not def LcleanUpLoc!")         if (! defined $LcleanUpLoc);
				# ------------------------------
				# temporary files (defaults)
    $jobid=$$;$id=$fileSeqLoc;$id=~s/^.*\///g;$id=~s/\..*$//g;$id=~s/\s//g;
    $fileSeqFasta="MAX-".$jobid."-".$id.".seqFasta"
	                              if (! defined $fileSeqFasta   || $fileSeqFasta   eq "def");
    $fileBlast=   "MAX-".$jobid."-".$id.".blast"
	                              if (! defined $fileBlast      || $fileBlast      eq "def");
    $fileBlastFil="MAX-".$jobid."-".$id.".blastFil"
	                              if (! defined $fileBlastFil   || $fileBlastFil   eq "def");
    $fileHssp=    "MAX-".$jobid."-".$id.".hssp"
	                              if (! defined $fileHssp       || $fileHssp       eq "def");
				# ------------------------------
				# default settings
    $dirData=       "/data"           if (! defined $dirData        || $dirData        eq "def");
    $dirSwiss=      "/data/swissprot" if (! defined $dirSwiss       || $dirSwiss       eq "def");
    $dirPdb=        "/data/pdb"       if (! defined $dirPdb         || $dirPdb         eq "def");
    $exeConvSeq=    "/home/cubic/pub/phd/bin/convert_seq.".$ARCH 
	                              if (! defined $exeConvSeq     || $exeConvSeq     eq "def");
    $exeBlastp=     "/home/phd/bin/".  $ARCH."/blastp"
	                              if (! defined $exeBlastp      || $exeBlastp      eq "def");
    $exeBlastpFil=  "/home/cubic/pub/max/scr/filter_blastp" 
                                      if (! defined $exeBlastpFil   || $exeBlastpFil   eq "def");
    $exeMax=        "/home/cubic/pub/max/bin/maxhom.".$ARCH
                                      if (! defined $exeMax         || $exeMax         eq "def");
    $envBlastpMat=  "/home/pub/molbio/blast/blastapp/matrix"  
                                      if (! defined $envBlastpMat   || $envBlastpMat   eq "def");
    $envBlastpDb=   "/data/db/"       if (! defined $envBlastpDb    || $envBlastpDb    eq "def");
    $parBlastpNhits="2000"            if (! defined $parBlastpNhits || $parBlastpNhits eq "def");
    $parBlastpDb=   "swiss"           if (! defined $parBlastpDb    || $parBlastpDb    eq "def");
    $fileMaxDef=    "/home/cubic/pub/max/maxhom.default" 
	                              if (! defined $fileMaxDef     || $fileMaxDef     eq "def");
    $fileMaxMetr=   "/home/cubic/pub/max/mat/Maxhom_GCG.metric" 
	                              if (! defined $fileMaxMetr    || $fileMaxMetr    eq "def");
    $Lprof=         "NO"              if (! defined $Lprof          || $Lprof          eq "def");
    $parMaxThresh= 30                 if (! defined $parMaxThresh   || $parMaxThresh   eq "def");
    $parMaxSmin=   -0.5               if (! defined $parMaxSmin     || $parMaxSmin     eq "def");
    $parMaxSmax=    1.0               if (! defined $parMaxSmax     || $parMaxSmax     eq "def");
    $parMaxGo=      3.0               if (! defined $parMaxGo       || $parMaxGo       eq "def");
    $parMaxGe=      0.1               if (! defined $parMaxGe       || $parMaxGe       eq "def");
    $parMaxW1=      "YES"             if (! defined $parMaxW1       || $parMaxW1       eq "def");
    $parMaxW2=      "NO"              if (! defined $parMaxW2       || $parMaxW2       eq "def");
    $parMaxI1=      "YES"             if (! defined $parMaxI1       || $parMaxI1       eq "def");
    $parMaxI2=      "NO"              if (! defined $parMaxI2       || $parMaxI2       eq "def");
    $parMaxNali=  500                 if (! defined $parMaxNali     || $parMaxNali     eq "def");
    $parMaxSort=    "DISTANCE"        if (! defined $parMaxSort     || $parMaxSort     eq "def");
    $parMaxProfOut= "NO"              if (! defined $parMaxProfOut  || $parMaxProfOut  eq "def");
    $parMaxStripOut="NO"              if (! defined $parMaxStripOut || $parMaxStripOut eq "def");
    $parMinLaliPdb=30                 if (! defined $parMinLaliPdb  || $parMinLaliPdb  eq "def");
    $parMaxTimeOut= "50000"           if (! defined $parMaxTimeOut  || $parMaxTimeOut  eq "def");
				# ------------------------------
				# check existence of files/dirs
    return(0,"*** $sbrName: miss in dir '$dirData'!")      if (! -d $dirData);
    return(0,"*** $sbrName: miss in dir '$dirSwiss'!")     if (! -d $dirSwiss);
    return(0,"*** $sbrName: miss in dir '$dirPdb'!")       if (! -d $dirPdb);
    return(0,"*** $sbrName: miss in dir '$envBlastpMat'!") if (! -d $envBlastpMat);
    return(0,"*** $sbrName: miss in dir '$envBlastpDb'!")  if (! -d $envBlastpDb);

    return(0,"*** $sbrName: miss in file '$fileSeqLoc'!")  if (! -e $fileSeqLoc &&
							       ! -l $fileSeqLoc);
    return(0,"*** $sbrName: miss in file '$exeConvSeq'!")  if (! -e $exeConvSeq &&
							       ! -l $exeConvSeq);
    return(0,"*** $sbrName: miss in file '$exeBlastp'!")   if (! -e $exeBlastp &&
							       ! -l $exeBlastp);
    return(0,"*** $sbrName: miss in file '$exeBlastpFil'!")if (! -e $exeBlastpFil &&
							       ! -l $exeBlastpFil);
    return(0,"*** $sbrName: miss in file '$fileMaxDef'!")  if (! -e $fileMaxDef &&
							       ! -l $fileMaxDef);
    return(0,"*** $sbrName: miss in file '$fileMaxMetr'!") if (! -e $fileMaxMetr &&
							       ! -l $fileMaxMetr);
    $fileScreenLoc=0                                       if (! defined $fileScreenLoc);

    print "\n"."*** WARN $sbrName: fileBlastFilter=$fileBlastFil must end with 'list'\n"."\n" x 50, "\n"
	if ($fileBlastFil !~ /list$/);
    $msgHere="--- $sbrName started\n";
    $#fileTmp=0;
				# ------------------------------
				# security convert_seq -> FASTA
    if (! &isFasta($fileSeqLoc)){
	$msgHere.="\n--- $sbrName \t call fortran convert_seq ($exeConvSeq,".
	    $fileSeqLoc.",".$fileSeqFasta.",$fhErrSbr)\n";
	($Lok,$msg)=		# call FORTRAN shit to convert to FASTA
	    &convSeq2fasta($exeConvSeq,$fileSeqLoc,$fileSeqFasta,$fhErrSbr);
				# conversion failed!
	return(0,"wrong conversion (convSeq2fasta)\n".
	       "*** $sbrName: fault in convert_seq ($exeConvSeq)\n$msg\n"."$msgHere")
	    if    ( ! $Lok || ! -e $fileSeqFasta);
	push(@fileTmp,$fileSeqFasta) if ($LcleanUpLoc); }
    else {
	$fileSeqFasta=$fileSeqLoc; }

# 	($Lok,$msg)=
# 	    &fileCp($fileSeqLoc,$fileSeqFasta,$fhErrSbr);
# 	return(0,"*** ERROR $sbrName '&fileCp($fileSeqLoc,$fileSeqFasta,$fhErrSbr)'\n".
# 	       "*** $sbrName: fault in convert_seq ($exeConvSeq)\n"."$msg\n"."$msgHere") 
# 	    if (! $Lok);}
				# --------------------------------------------------
                                # pre-filter to speed up MaxHom (BLAST)
				# --------------------------------------------------
    $msgHere.="\n--- $sbrName \t run BLASTP ($dirData,$dirSwiss,$exeBlastp,$exeBlastpFil,".
	"$envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,".
	    $fileSeqLoc.",".$fileBlast.",".$fileBlastFil.",$fhErrSbr)\n";

    ($Lok,$msg)=
	&blastpRun($nice,$dirData,$dirSwiss,$exeBlastp,$exeBlastpFil,
		   $envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,
		   $fileSeqFasta,$fileBlast,$fileBlastFil,$fhErrSbr);
    

    return(0,"*** $sbrName: after blastpRun $msg"."\n"."$msgHere")
	if (! $Lok || ! -e $fileBlastFil);

    push(@fileTmp,$fileBlast,$fileBlastFil) if ($LcleanUpLoc);

				# --------------------------------------------------
				# now run MaxHom
				# --------------------------------------------------
    $thresh=
	&maxhomGetThresh($parMaxThresh); # get the threshold
				# ------------------------------
				# get the arguments for the MAXHOM csh
#    $msgHere.="\n--- $sbrName \t run maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,".
    $msgHere2="\n--- $sbrName \t run maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,".
	"$jobid,$fileSeqFasta,$fileBlastFil,$fileHssp,$fileMaxMetr,$dirPdb,$Lprof,$parMaxSmin,".
	    "$parMaxSmax,$parMaxGo,$parMaxGe,$parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,".
		"$parMaxNali,$thresh,$parMaxSort,$parMaxProfOut,$parMaxStripOut,".
		    "$parMinLaliPdb,parMaxTimeOut,$fhErrSbr,$fileScreenLoc)\n";
				# ------------------------------------------------------------
				# now run it (will also run Self if missing output
				# note: if pdbidFound = 0, then none found!
    ($Lok,$pdbidFound)=
	&maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,$fileSeqFasta,$fileBlastFil,$fileHssp,
		       $fileMaxMetr,$dirPdb,$Lprof,$parMaxSmin,$parMaxSmax,$parMaxGo,$parMaxGe,
		       $parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,$parMaxNali,$thresh,$parMaxSort,
		       $parMaxProfOut,$parMaxStripOut,$parMinLaliPdb,
		       $parMaxTimeOut,$fhErrSbr,$fileScreenLoc);
				# enf of Maxhom
				# ------------------------------------------------------------
    
    return(0,"error","*** ERROR $sbrName maxhomRunLoop failed, pdbidFound=$pdbidFound\n".
	   $msgHere2."\n")      if (! $Lok);
    
    return(0,"error","*** ERROR $sbrName maxhomRunLoop no $fileHssp, ".
	   "pdbidFound=$pdbidFound\n".$msgHere2."\n") if (! -e $fileHssp);
    if ($LcleanUpLoc){
	foreach $file(@fileTmp){
	    next if (! -e $file);
	    unlink ($file) ; $msgHere.="--- $sbrName: unlink($file)\n";}
	system("\\rm MAX*$jobid");
	$msgHere.="--- $sbrName: system '\\rm MAX*$jobid'\n" ;}
    return(1,"ok","$sbrName\n".$msgHere);
}				# end of maxhomRun

#==============================================================================
sub maxhomRunLoop {
    local ($date,$niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,
	   $fileHsspInL,$fileHsspAliListL,$fileHsspOutL,$fileMaxMetricL,$dirMaxPdbL,
	   $LprofileL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,$paraW1L,$paraW2L,
	   $paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,$paraSortL,$paraProfOutL,
	   $fileStripOutL,$fileFlagNoHsspL,$paraMinLaliPdbL,
	   $paraTimeOutL,$fhTraceLoc,$fileScreenLoc)=@_;
    local ($maxCmdL,$start_at,$alarm_sent,$alarm_timer,$thresh_txt);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomRunLoop               loops over a maxhom run (until paraTimeOutL = 3hrs)
#       in:                     see program...
#       out:                    (0,'error message',0), (1,'error in pdbid',1), 
#       out:                    (1,0|pdbidFound,0|1) last arg=0 if self, =1 if ali
#       err:                    ok=(1,'ok|pdbid',0|1), err=(0,'msg',0)
#--------------------------------------------------------------------------------
    $sbrName="maxhomRunLoop";
    return(0,"*** $sbrName: not def date!",0)             if (! defined $date);
    return(0,"*** $sbrName: not def niceL!",0)            if (! defined $niceL);
    return(0,"*** $sbrName: not def exeMaxL!",0)          if (! defined $exeMaxL);
    return(0,"*** $sbrName: not def fileMaxDefL!",0)      if (! defined $fileMaxDefL);
    return(0,"*** $sbrName: not def fileJobIdL!",0)       if (! defined $fileJobIdL);
    return(0,"*** $sbrName: not def fileHsspInL!",0)      if (! defined $fileHsspInL);
    return(0,"*** $sbrName: not def fileHsspAliListL!",0) if (! defined $fileHsspAliListL);
    return(0,"*** $sbrName: not def fileHsspOutL!",0)     if (! defined $fileHsspOutL);
    return(0,"*** $sbrName: not def fileMaxMetricL!",0)   if (! defined $fileMaxMetricL);
    return(0,"*** $sbrName: not def dirMaxPdbL!",0)       if (! defined $dirMaxPdbL);
    return(0,"*** $sbrName: not def LprofileL!",0)        if (! defined $LprofileL);
    return(0,"*** $sbrName: not def paraSminL!",0)        if (! defined $paraSminL);
    return(0,"*** $sbrName: not def paraSmaxL!",0)        if (! defined $paraSmaxL);
    return(0,"*** $sbrName: not def paraGoL!",0)          if (! defined $paraGoL);
    return(0,"*** $sbrName: not def paraGeL!",0)          if (! defined $paraGeL);
    return(0,"*** $sbrName: not def paraW1L!",0)          if (! defined $paraW1L);
    return(0,"*** $sbrName: not def paraW2L!",0)          if (! defined $paraW2L);
    return(0,"*** $sbrName: not def paraIndel1L!",0)      if (! defined $paraIndel1L);
    return(0,"*** $sbrName: not def paraIndel2L!",0)      if (! defined $paraIndel2L);
    return(0,"*** $sbrName: not def paraNaliL!",0)        if (! defined $paraNaliL);
    return(0,"*** $sbrName: not def paraThreshL!",0)      if (! defined $paraThreshL);
    return(0,"*** $sbrName: not def paraSortL!",0)        if (! defined $paraSortL);
    return(0,"*** $sbrName: not def paraProfOutL!",0)     if (! defined $paraProfOutL);
    return(0,"*** $sbrName: not def fileStripOutL!",0)    if (! defined $fileStripOutL);
    return(0,"*** $sbrName: not def fileFlagNoHsspL!",0)  if (! defined $fileFlagNoHsspL);
    return(0,"*** $sbrName: not def paraMinLaliPdbL!",0)  if (! defined $paraMinLaliPdbL);

    return(0,"*** $sbrName: not def paraTimeOutL!",0)     if (! defined $paraTimeOutL);
    $fhTraceLoc="STDOUT"                                  if (! defined $fhTraceLoc);
    $fileScreenLoc=0                                      if (! defined $fileScreenLoc);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileHsspInL'!",0)      if (! -e $fileHsspInL &&
									 ! -l $fileHsspInL);
    return(0,"*** $sbrName: miss input exe  '$exeMaxL'!",0)          if (! -e $exeMaxL &&
									 ! -l $exeMaxL);
    return(0,"*** $sbrName: miss input file '$fileMaxDefL'!",0)      if (! -e $fileMaxDefL &&
									 ! -l $fileMaxDefL);
    return(0,"*** $sbrName: miss input file '$fileHsspAliListL'!",0) if (! -e $fileHsspAliListL &&
									 ! -l $fileHsspAliListL);
    return(0,"*** $sbrName: miss input file '$fileMaxMetricL'!",0)   if (! -e $fileMaxMetricL &&
									 ! -l $fileMaxMetricL);
    $pdbidFound="";
    $LisSelf=0;			# is PDBid in HSSP? / are homologues?

				# ------------------------------
				# set the elapse time in seconds before an alarm is sent
#    $paraTimeOutL= 10000;	# ~ 3 heures
    $msgHere="";
				# ------------------------------
				# (1) build up MaxHom input
    ($msg,$warn)=		# check existence of files asf
	&maxhomGetArgCheck($exeMaxL,$fileMaxDefL,$fileHsspInL,$fileHsspAliListL,
			   $fileMaxMetricL);
    if (length($msg)>1){
	return(0,"$msg",0);} $msgHere.="--- $sbrName $warn\n";
    
    $maxCmdL=			# get command line argument for starting MaxHom
	&maxhomGetArg($niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$fileHsspInL,$fileHsspAliListL,
		      $LprofileL,$fileMaxMetricL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,
		      $paraW1L,$paraW2L,$paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,
		      $paraSortL,$fileHsspOutL,$dirMaxPdbL,$paraProfOutL,$fileStripOutL);
				# --------------------------------------------------
				# the thing that does IT!
				# --------------------------------------------------
    while ( ! -f $fileHsspOutL ) { 
	$msgHere.="--- $sbrName \t first trial to get $fileHsspOutL\n";

#	$Lok=
#	    &run_program($maxCmdL,$fhTraceLoc); # its running!

	($Lok,$msg)=
	    &sysRunProg($maxCmdL,$fileScreenLoc,$fhTraceLoc);

				# ------------------------------
				# no HSSP file -> loop
	if ( ! -f $fileHsspOutL ) {
	    if (!$start_at) {	# switch a timer on
		$start_at= time(); }
				# test if an alarm is needed
	    if (!$alarm_sent && (time() - $start_at) > $paraTimeOutL) {
				# **************************************************
				# NOTE this SBR is PP specific
				# **************************************************
		&ctrlAlarm("SUICIDE: In max_loop for more than $alarm_timer... (killer!)".
			   "$msgHere");
		$alarm_sent=1;
		return(0,"maxhom SUICIDE on $fileHsspOutL".$msgHere,0); }
				# create a trace file
	    open("NOHSSP","> $fileFlagNoHsspL") || 
		warn "-*- $sbrName WARNING cannot open $fileFlagNoHsspL: $!\n";
	    print NOHSSP " problem with maxhom ($fileHsspOutL)\n"," $date\n";
	    print NOHSSP `ps -ela`;
	    sleep 10;
	    close(NOHSSP);
	    unlink ($fileFlagNoHsspL); }
    }				# end of loop 

				# --------------------------------------------------
    if (-e $fileHsspOutL){	# is HSSP file -> check
	($Lok,$kwd,$msg)=
	    &maxhomCheckHssp($fileHsspOutL,$paraMinLaliPdbL);
	return(0,"*** $sbrName ERROR after 'maxhomCheckHssp: ".
	       "kwd=$kwd, msg=$msg'\n".$msgHere,0) if (! $Lok);}
    else {return(0,"*** $sbrName ERROR after loop: no HSSP $fileHsspOutL".
		 $msgHere,0);}
				# --------------------------------------------------
				# maxhom against itself (no homologues found)
    if ($kwd eq "empty") {	# => no ali
	$LisSelf=1;$LisPdb=0;$pdbidFound=" ";
	($Lok,$msg)=
	    &maxhomRunSelf($niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$fileHsspInL,
			   $fileHsspOutL,$fileMaxMetricL,$fhTraceLoc,$fileScreenLoc);
	return(0,"*** ERROR $sbrName 'maxhomRunSelf' wrong".
	       $msg."\n".$msgHere,0) if (! $Lok || ! -e $fileHsspOutL);}
    elsif ($kwd eq "self"){ # is self already
	$LisSelf=1;$LisPdb=0;$pdbidFound=" ";}
    elsif ($kwd eq "pdbid"){
	$tmp=$msg;$tmp=~s/^pdbid=([^\n]*)\n.*$/$1/;
	$LisSelf=0;$LisPdb=1;$pdbidFound=$tmp;}
    elsif ($kwd eq "ok"){
	$LisSelf=0;$LisPdb=0;$pdbidFound=" ";}
    else {
	return(0,"*** $sbrName ERROR after 'maxhomCheckHssp: kwd=$kwd, unclear\n".
	       "msg=$msg\n".$msgHere,0) if (! $Lok);}

    if    ($LisPdb){
	if    (! defined $pdbidFound || length($pdbidFound)<4){
	    return(1,"error in pdbid",0);} # error
	elsif (defined $pdbidFound && length($pdbidFound)>4 && ! $LisSelf){
	    return(1,"$pdbidFound",0);}	# PDBid + ali
	return(1,"$pdbidFound",1);} # appears to be PDB but no ali
    elsif ($LisSelf){
	return(1,0,1);}		# no ali
    return(1,0,0);		# ok
}				# end maxhomRunLoop

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
    $sbrName="maxhomRunSelf";
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
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#==============================================================================
sub myprt_line  {
    local($fhx)=@_;
#   myprt_line                  prints a line with 70 '-'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "-" x 70,"\n","--- \n";
}				# end of myprt_line

#==============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt

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
	warn "*** ERROR open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#==============================================================================
sub pirRdSeq {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdSeq                    reads the sequence from a PIR file
#       in:                     file
#       out:                    (1,name,sequence in one string)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="pirRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,$msg,"error");}
    $seq=$id="";$ct=0;
    while (<$fhinLoc>) {$_=~s/\n//g;++$ct;
			if   ($ct==1){
			    $id=$_;$id=~s/^\s*\>\s*P1\s*\;\s*(\S+)[\s\n]*.*$/$1/g;}
			elsif($ct==2){$id.=", $_";}
			else {$_=~s/[\s\*]//g;
			      $seq.="$_";}}close($fhinLoc);
    $seq=~s/\s//g;$seq=~s/\*$//g;
    return(1,$id,$seq);
}				# end of pirRdSeq

#==============================================================================
sub run_program {
    local ($cmd,$fhLogFile,$action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    print "--- running command: \t $cmdtmp"  if ((! defined $par{"verbose"})||$par{"verbose"});
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
sub swissRdSeq {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissRdSeq                  reads the sequence from a SWISS-PROT file
#       in:                     file
#       out:                    (1,name,sequence in one string)
#-------------------------------------------------------------------------------
    $sbrName="swissRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,$msg,"error");}
    $seq="";
    while (<$fhinLoc>) {$_=~s/\n//g;
			if ($_=~/^ID\s+(\S*)\s*.*$/){
			    $id=$1;}
			last if ($_=~/^\/\//);
			next if ($_=~/^[A-Z]/);
			$seq.="$_";}close($fhinLoc);
    $seq=~s/\s//g;
    return(1,$id,$seq);
}				# end of swissRdSeq

#===============================================================================
sub sysCpfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysCpfile                   system call '\\cp file1 file2' (or to dir)
#       in:                     file1,file2 (or dir), nice value (nice -19)
#       out:                    ok=(1,'cp a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysCpfile";
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
				# check
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!") if (! defined $fileToCopyTo);

    if (-d $fileToCopyTo){	# is directory
	$fileToCopyTo.="/"      if ($fileToCopyTo !~/\/$/);}

    $Lok= system("$niceLoc \\cp $fileToCopy $fileToCopyTo");
#    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    if    (-d $fileToCopyTo){	# is directory
	$tmp=$fileToCopy;$tmp=~s/^.*\///g;$tmp=$fileToCopyTo.$tmp;
	$Lok=0 if (! -e $tmp);}
    elsif (! -e $fileToCopyTo){ $Lok=0; }
    elsif (-e $fileToCopyTo)  { $Lok=1; }

    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    
    return(1,"$niceLoc \\cp $fileToCopy $fileToCopyTo");
}				# end of sysCpfile

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/cubic/perl/ctime.pl",           # HARD_CODED
	  "/home/cubic/pub/perl/ctime.pl",       # HARD_CODED
	  "/home/phd/server/scr/lib/ctime.pm"   # HARD_CODED
	  );
    foreach $tmp (@tmp) {
	next if (! -e $tmp && ! -l $tmp);
	$exe_ctime=$tmp;	# local ctime library
	last; }

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    $Lok=
		require($exe_ctime)
		    if (-e $exe_ctime); }
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
sub sysMkdir {
    local($argIn,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMkdir                    system call 'mkdir'
#                               note: system call returns 0 if ok
#       in:                     directory, nice value (nice -19)
#       out:                    ok=(1,'mkdir a') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMkdir";
    $argIn=~s/\/$//             if ($argIn=~/\/$/);
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
    $argIn=~s/\/$//g            if ($argIn =~/\/$/); # chop last '/'
				# exists already
    return(1,"already existing: $argIn") 
	if (-d $argIn);

				# ------------------------------
				# make dir
    $Lok=1;
#    $Lok= mkdir ($argIn, "770");
    system("mkdir $argIn");
    system("chmod u+rwx $argIn");
    system("chmod go+rx $argIn");

    return(0,"*** $sbrName: could not find or make dir=$argIn ($Lok)!") if (! $Lok);
    return(1,"$niceLoc mkdir $argIn");
}				# end of sysMkdir

#==============================================================================
sub sysMvfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMvfile                   system call '\\mv file'
#       in:                     $fileToCopy,$fileToCopyTo (or dir),$niceLoc
#       out:                    ok=(1,'mv a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMvfile";
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
				# check
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!")  if (! defined $fileToCopyTo);

    system("$niceLoc \\mv $fileToCopy $fileToCopyTo");

    return(0,"*** $sbrName: couldnt copy '$fileToCopy -> $fileToCopyTo' ($Lok)!")
	if (! -e $fileToCopyTo);
    return(1,"$niceLoc \\mv $fileToCopy $fileToCopyTo");
}				# end of sysMvfile

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
    $sbrName="sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system cmd=\n$prog\n",
	    "--- $sbrName: fileOut=$fileScrLoc\n";}
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
# library collected (end)   lll
#==============================================================================


#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         initialises variables/arguments
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."ini";     

    $jobid=$$;
				# sets environment (ARCH, PWD)
    ($Lok,$msg)=
	&iniEnv();              return(&errSbrMsg("after iniEnv",$msg,$SBR)) if (! $Lok);
    
    &iniDef();			# first settings for parameters (command line overwrites!)

				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,
		       %tmp);   return(&errSbrMsg("after ini:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 

    ($Lok,$msg)=		# read command line input
	&iniGetArg();           return(&errSbrMsg("after ini:iniGetArg",$msg,$SBR)) if (! $Lok);

				# ------------------------------
				# final settings
    ($Lok,$msg)=
	&iniSetPar();           return(&errSbrMsg("after ini:iniSetPar",$msg,$SBR)) if (! $Lok);
    
                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0 && ! $par{"debug"} ) {
	print 
	    "--- NOTE: all output will be in files: ",$par{"fileOutTrace"},",",
	    $par{"fileOutScreen"},",\n",
	    "---       open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  
		if ($par{"verbose"});
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$par{"fileOutTrace"}=0;
	$fhTrace="STDOUT";}
    $par{"fileOutScreen"}=0     if ($par{"debugProg"});
    @kwdDef= sort keys (%par);
				# ------------------------------
				# write settings
				# ------------------------------

    $exclude="kwd,dir*,ext*";	# keyword not to write
    $fhloc="STDOUT";
    $fhloc=$fhTrace             if (! $par{"debug"});
    ($Lok,$msg)=
	&brIniWrt($exclude,$fhloc);
                                return(&errSbrMsg("after ini:brIniWrt",$msg,$SBR))  if (! $Lok); 

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $SBR");
}				# end of ini

#===============================================================================
sub iniEnv {
    local($sbrName,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniEnv                      sets environment (ARCH, PWD, asf)
#-------------------------------------------------------------------------------
    $tmp=""; $tmp=$scrName      if (defined $scrName); $tmp=~s/\.p[lm]//g;
    $sbrName=$tmp.":iniEnv";
				# ------------------------------
    $timeBeg=time;		# date and time
    $Date=        &sysDate();
    $date=$Date;
                                # ------------------------------
                                # other
    foreach $arg (@ARGV) {      # given on command line?
        last if ($arg=~/^PWD=(\S+)/i); }
    $PWD=$1                     if (defined $1);
    $PWD=$PWD || $ENV{'PWD'} || 'unk';
				# get local directory
    if ($PWD eq "unk") { 
	undef $cmd;
	$cmd="/bin/pwd"  if (! defined $cmd && -e "/bin/pwd");
	$cmd="/sbin/pwd" if (! defined $cmd && -e "/sbin/pwd");
	if (defined $cmd) {
	    open(C,"/bin/pwd|");$PWD=<C>;close(C);}
	else {
	    $PWD=`pwd`; $PWD=~s/[\s\n]//g;}}
    return(0,"*** ERROR in $sbrName: GIVE the local directory as PWD=\n")
	if (! defined $PWD || $PWD eq "unk" || length($PWD)<1);
    $pwd=$PWD; $pwd.="/"        if ($pwd !~/\/$/); # add slash

				# ------------------------------
				# setenv ARCH
				# ------------------------------
    undef $ARCH;                # 
    foreach $arg (@ARGV) {      # given on command line?
        last if ($arg=~/^ARCH=(\S+)/i); }
    $ARCH=$1                    if (defined $1);
    $ARCH=~tr/[a-z]/[A-Z]/      if (defined $ARCH);	# lower to upper

                                # given in local env ?
    $ARCH= $ARCH || $ENV{'ARCH'}  || 'unk';

                                # try to execute sh script
    if ($ARCH eq "unk") {
        $tmp=$0; $tmp=~s/\.\///g;$tmp=~s/^(.*\/).*$/$1/;
        $scr= $tmp              if (defined $tmp);
        $scr.="scr/which_arch.sh";
	$scr="/home/phd/ut/phd/scr/which_arch.sh" if (! -e $scr);
        if (-e $scr && -x $scr){ $ARCH=`$scr`; 
                                 $ARCH=~s/\s|\n//g; }}
    $ARCH=$ARCH_DEF             if (! defined $ARCH || $ARCH eq "unk");

                                # give in!!
    return(0,"*** ERROR in $sbrName: GIVE the machine architecture by\n".
	     "$scrName file.hssp ARCH=ALPHA|SGI|SGI64|SUNMP\n")
	if (! defined $ARCH || $ARCH eq "unk");
    return(1,"ok");
}				# end of iniEnv

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      initialise defaults
#-------------------------------------------------------------------------------
				# ------------------------------
				# major paths
				# ------------------------------
    $par{"dirPub"}=             "/home/cubic/pub/";                 # roots all programs
    $par{"dirData"}=            "/home/cubic/data";                 # roots all databases used
    $par{"dirWork"}=            "/home/cubic/w/gene/run/";          # working directory
    $par{"dirWork"}=            "";                         # working directory

				# ------------------------------
				# check command line arguments
    if ($#ARGV>0) {
	foreach $arg (@ARGV) {
	    next if ($arg!~/^dir(Pub|Data|Work)=(.*)$/);
	    next if (! defined $1);
	    if    ($1 eq "Pub" && defined $2) {
		$par{"dirPub"}=$2; $par{"dirPub"}.="/" if ($par{"dirPub"} !~/\/$/); }
	    elsif ($1 eq "Data" && defined $2) {
		$par{"dirData"}=$2; $par{"dirData"}.="/" if ($par{"dirData"} !~/\/$/); }
	    elsif ($1 eq "Work" && defined $2) {
		$par{"dirWork"}=$2; $par{"dirWork"}.="/" if ($par{"dirWork"} !~/\/$/); } }}
	
				# --------------------
				# directories
    $par{"dirIn"}=              ""; # directory with input files
    $par{"dirOut"}=             ""; # directory for output files
				# scripts
    $par{"dirProgPhd"}=         $par{"dirPub"}.       "phd/";
    $par{"dirProgPhdScr"}=      $par{"dirProgPhd"}.   "scr/";
    $par{"dirProgPhdBin"}=      $par{"dirProgPhd"}.   "bin/";

    $par{"dirProgMax"}=         $par{"dirPub"}.       "max/";
    $par{"dirProgMaxBin"}=      $par{"dirProgMax"}.   "bin/";
    $par{"dirProgMaxCsh"}=      $par{"dirProgMax"}.   "csh/";
    $par{"dirProgMaxMat"}=      $par{"dirProgMax"}.   "mat/";
    $par{"dirProgMaxScr"}=      $par{"dirProgMax"}.   "scr/";

    $par{"dirProgBio"}=         $par{"dirPub"}.       "molbio/";
    $par{"dirProgBioBin"}=      $par{"dirProgBio"}.   "bin/";

				# databases
    $par{"dirSwiss"}=           $par{"dirData"}. "/". "swissprot";  # Swissprot directory
    $par{"dirSwissSplit"}=      $par{"dirSwiss"}."/". "current";    # SWISS-PROT split
    $par{"dirPdb"}=             $par{"dirData"}. "/". "pdb";        # 

				# output/input (working)
    $par{"dirSeq"}=             $par{"dirWork"}.      "seq";
#    $par{"dirHssp"}=            $par{"dirWork"}.      "hssp";
    $par{"dirHsspSelf"}=        $par{"dirWork"}.      "hsspSelf";
    $par{"dirHsspRaw"}=         $par{"dirWork"}.      "hsspRaw";
    $par{"dirHsspFil"}=         $par{"dirWork"}.      "hsspFil";
    $par{"dirHssp4phd"}=        $par{"dirWork"}.      "hssp4phd";
    $par{"dirPhd"}=             $par{"dirWork"}.      "phd";
    $par{"dirPhdDssp"}=         $par{"dirWork"}.      "phdDssp";
    $par{"dirPhdHtm"}=          $par{"dirWork"}.      "phdHtm";
    $par{"dirPhdNotHtm"}=       $par{"dirWork"}.      "notHtm";
    $par{"dirPhdHtm07"}=        $par{"dirWork"}.      "phdHtm07";
    $par{"dirPhdNotHtm07"}=     $par{"dirWork"}.      "notHtm07";
    $par{"dirCoils"}=           $par{"dirWork"}.      "coils";

				# --------------------
				# executables
    $par{"exePhd"}=             $par{"dirProgPhd"}.   "phd.pl";
    $par{"exePhdFor"}=          $par{"dirProgPhdBin"}."phd."            .$ARCH;
    $par{"exePhd2Dssp"}=        $par{"dirProgPhdScr"}."conv_phd2dssp.pl";
    $par{"exeCopf"}=            $par{"dirProgPhdScr"}."copf.pl";          # executable for format conversion
    $par{"exeConvSeqFor"}=      $par{"dirProgPhdBin"}."convert_seq."    .$ARCH;
    $par{"exeMax"}=             $par{"dirProgMaxScr"}."maxhom.pl";
    $par{"exeMaxFor"}=          $par{"dirProgMaxBin"}."maxhom."         .$ARCH;
    $par{"exeBlastp"}=          $par{"dirProgBioBin"}."blastp."         .$ARCH;
    $par{"exeBlastpFilter"}=    $par{"dirProgMaxScr"}."filter_blastp_big.pl";
    $par{"exeHsspFilter"}=      $par{"dirProgMaxScr"}."hssp_filter.pl";
    $par{"exeHsspFilterFor"}=   $par{"dirProgMaxBin"}."filter_hssp."    .$ARCH,
#    $par{"exeHsspExtrHead"}=    $par{"dirProgMaxScr"}.    "hssp_extr_header.pl";
				# --------------------
				# files in / out
#    $par{"extSeq"}=             ".pir";
#    $par{"extSeq"}=             ".seq";
#    $par{"extSeq"}=             "";
    $par{"extSeq"}=             ".f";
    $par{"extHssp"}=            ".hssp";
    $par{"extHsspFil"}=         ".hssp";
    $par{"extHssp4phd"}=        ".hssp";
    $par{"extHsspRaw"}=         ".hssp";
    $par{"extHsspSelf"}=        ".hsspSelf";
    $par{"extPhdHuman"}=        ".phd";
    $par{"extPhdHtmHuman"}=     ".phdHtm";
    $par{"extPhd"}=             ".rdbPhd";
    $par{"extPhdDssp"}=         ".dsspPhd";
    $par{"extPhdHtm"}=          ".rdbHtm";
    $par{"extPhdNotHtm"}=       ".notHtm";
    $par{"extPhdHtm07"}=        ".rdbHtm";
    $par{"extPhdNotHtm07"}=     ".notHtm";

    $par{"extOut"}=             ".tmp";
    $par{"fileOut"}=            "";

    $par{"titleTmp"}=           "GENEphd-";                       # title for temporary files
    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE-"."jobid".".tmp"; # file tracing warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN-"."jobid".".tmp"; # file for running system commands
    $par{"preOutDo"}=           "Do-";    # file flagging what to do, named 'Do-'.title.job.'.list'
    $par{"preOutOk"}=           "Ok-";    # file flagging what ok, named 'Ok-'.title.job.'.list'
    $par{"preOutTwice"}=        "Twice-"; # file flagging what twice, named 'Twice-'.title.job.'.list'
    $par{"preOutSyn"}=          "Syn-";	  # synopsis of run

				# --------------------
				# file handles
#    $fhout=                     "FHOUT";
#    $fhin=                      "FHIN";
    $fhTrace=                   "STDOUT";
				# files parameter
    $par{"fileMaxDef"}=         $par{"dirProgMax"}.   "maxhom.default";
#    $par{"fileMaxMat"}=         $par{"dirProgMaxMat"}."Maxhom_GCG.metric";
    $par{"fileMaxMat"}=         $par{"dirProgMaxMat"}."Maxhom_McLachlan.metric";
    $par{"envBlastMat"}=        $par{"dirProgBio"}.   "blast/blastapp/matrix";
    $par{"envBlastDb"}=         $par{"dirProgBio"}.   "blast/db/";
    $par{"envBlastDb"}=         $par{"dirData"}.      "blast/";
                                # ----------------------------------------
				# MaxHom: parameters
    $par{"parBlastDb"}=         "swiss";     # database to run BLASTP against

				# beg: commented out br 99-07 (valid for old version with maxhomRun)
#     $par{"parBlastNhits"}=      "2000";
#     $par{"parMaxThresh"}=       30;          # identity cut-off for Maxhom threshold of hits taken
#     $par{"parMaxMaxNres"}=      "5000";      # maximal length of sequence
#     $par{"parMaxProf"}=         "NO";
#     $par{"parMaxSmin"}=        -0.5;         # standard job
#     $par{"parMaxSmax"}=         1.0;         # standard job
#     $par{"parMaxGo"}=           3.0;         # standard job
#     $par{"parMaxGe"}=           0.1;         # standard job
#     $par{"parMaxW1"}=           "YES";       # standard job
#     $par{"parMaxW2"}=           "NO";        # standard job
#     $par{"parMaxI1"}=           "YES";       # standard job
#     $par{"parMaxI2"}=           "NO";        # standard job
#     $par{"parMaxNali"}=       500;           # standard job
#     $par{"parMaxSort"}=         "DISTANCE";  # standard job
#     $par{"parMaxProfOut"}=      "NO";        # standard job
#     $par{"parMaxStripOut"}=     "NO";        # standard job
#     $par{"parMinLaliPdb"}=     30;           #
#     $par{"parMaxTimeOut"}=  10000;           # secnd ~ 3hrs, then: send alarm MaxHom suicide!
				# end: commented out br 99-07 (valid for old version with maxhomRun)

				# new version: Maxhom with perl
                                          # command for filtering HSSP file:
    $par{"filter"}=             "thresh=8 threshSgi=-5 mode=ide";
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
    $par{"filter4phd"}=         "thresh=8 threshSgi=-10 mode=ide red=90";
    
    $par{"doSelf"}=             0; # if 1: runs sequence against itself -> no ali
    $par{"doDirect"}=           0; # if 1: no pre-filter by BLAST, but directly MaxHom against DB
    $par{"doNew"}=              0; # if 1: will overwrite already existing files

    $par{"do"."phdHtm"."Html"}= 1; # if 1: produce HTML output file for PHDhtm

#    $par{"exe"}=        ;
#    $par{"exe"}=        ;
                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
#    $par{"jobid"}=              "xx"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"debugProg"}=          0; # if 1 : output from jobs (MaxHom, PHD asf) onto screen
    $par{"verbose"}=            1; # blabla on screen
    $par{"verb2"}=              0; # more verbose blabla
    $par{"verb3"}=              0; # more verbose blabla
    $par{"keepDir"}=            0; # if set to 1, the directories will not automatically
				   # have the structure 'dirWork'seq|hssp|...
    $par{"optNice"}=               "19";
				# drives which files to search (dirs= same names)
                                # convention: if rdbX -> no .phd files
#    $par{"do"}=                 "phdBoth,phdHtmDef,phdDssp";
#    $par{"do"}=                 "phdBoth,phdHtm07,phdHtm08,phdDssp";
#    $par{"do"}=                 "phdHtm07,phdHtm08";
#    $par{"do"}=                 "hssp,phdBoth,phdHtmdef";
#    $par{"do"}=                 "rdbBoth,rdbHtmdef";
#    $par{"do"}=                 "rdbAcc"; 
#    $par{"do"}=                 "phdHtm07,phdHtm08"; 
#    $par{"do"}=                 "rdbHtmdef";
    $par{"do"}=                 "hssp,filter,filter4phd,phdBoth,phdHtm,phdHtm07";
	
				# default jobs: all
#    $par{"doDef"}=              "hssp,filter,phdSec,phdAcc,phdHtm,phdHtm07,coils";
    $par{"doDef"}=              "hssp,filter,filter4phd,phdSec,phdAcc,phdHtm,phdHtm07";
				# 
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdStatus=  
	(
	 "ok","notHtm","empty","none","delete",
#	 "twice"
	 );
				# possible keywords describing jobs
    @kwdJobs=    
	(
	 "hssp",		# run MaxHom alignment
	 "filter",		# run HSSP filter (for user output)
	 "filter4phd",		# run HSSP filter (for PHD input)
	 "phdSec",
	 "phdAcc",
	 "phdBoth",
	 "coils",
	 "phdHtm",
	 "phdHtm07",		# 
	 );
				# job descriptor to result directory
    %translate_job2dir=
	('hssp',        "dirHsspRaw",
	 'filter',      "dirHsspFil",
	 'filter4phd',  "dirHssp4phd",
	 'phdSec',      "dirPhd",
	 'phdAcc',      "dirPhd",
	 'phdBoth',     "dirPhd",
	 'coils',       "dirCoils",
	 'phdHtm',      "dirPhdHtm",
	 'phdHtm07',    "dirPhdHtm07",
	 );
				# translate for extensions
    foreach $job (@kwdJobs) {
	$tmp=$translate_job2dir{$job};
	$tmp=~s/^dir/ext/;
	$translate_job2ext{$job}=$tmp;}

				# flags for HTML output
				# by default=0
    foreach $job (@kwdJobs) {
				# default off
	$par{"do". $job."Html"}=0 if (! defined $par{"do". $job."Html"});
	$par{"dir".$job."Html"}=$par{$translate_job2dir{$job}}."Html";
	$par{"ext".$job."Html"}="_".$job.".html";
    }
}				# end of iniDef

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
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);

    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help
    $tmp{"scrAddHelp"}=      "";

    $tmp{"special"}=         "";
    $tmp{"special"}.=        "list,verb,verb2,verbDbg,";
    $tmp{"special"}.=        "all,";
    $tmp{"special"}.=        "db,";
    $tmp{"special"}.=        "filter,filter4phd,",
    $tmp{"special"}.=        "self,direct,dis,skip,new,";
    foreach $kwd ("swiss","big","trembl","pdb") {
	$tmp{"special"}.=    "$kwd,"      if ($par{"parBlastDb"} !~ /$kwd$/);}
#    $tmp{"special"}.=        ",";
#    $tmp{"special"}.=        ",";
#    $tmp{"special"}.=        ",";
        
#    $tmp{""}=         "<*|=1> ->    ";
    $tmp{"list"}=            "<*|isList=1>     -> input file is list of files";

    $tmp{"verb"}=            "<*|verbose=1>    -> verbose output";
    $tmp{"verb2"}=           "<*|verb2=1>      -> very verbose output";
    $tmp{"verbDbg"}=         "<*|verbDbg=1>    -> detailed debug info (not automatic)";

    $tmp="---                      ";
    $tmp{"all"}=             "all              -> all jobs (".$par{"doDef"}.") will be run\n";
    $tmp{"db"}=              "db=<swiss|pdb|trembl|big>\n";
    $tmp{"db"}.=        $tmp."  ->    sets the database for the search\n";
    $tmp{"db"}.=        $tmp."        NOTE: cross-check with ".$par{"exeMax"}." this is understood!";
    $tmp{"blastDb"}=         "OR parBlastDb=x  -> set BLAST DB";

    $tmp{"swiss"}=           "OR parBlastDb=swiss -> runs against SWISS-PROT (default)";
    $tmp{"big"}=             "OR parBlastDb=big   -> runs against SWISS+PDB+TREMBL";
    $tmp{"trembl"}=          "OR parBlastDb=trembl-> runs against TREMBL";
    $tmp{"pdb"}=             "OR parBlastDb=pdb   -> runs against PDB";

#    $tmp{"zz"}=              "expl             -> action\n";
#    $tmp{"zz"}.=        $tmp."    expl continue\n";

    $tmp{"self"}=            "OR doSelf=1,       -> runs sequence against itself";
    $tmp{"direct"}=          "OR doDirect=1,     -> runs without BLAST (watch CPU!!)";
    $tmp{"skip"}=            "OR doNew=0         -> will not run again if output file exists";
    $tmp{"new"}=             "OR doNew=1         -> will overwrite existing output file!";

    $tmp{"filter"}=          "OR doHsspFilter=1  -> filters HSSP file by:\n";
    $tmp{"filter"}.=    $tmp."   ".$par{"filter"}."\n";
    $tmp{"filter"}.=    $tmp."   ='cmd'       -> runs hssp_filter with 'cmd'\n";
    $tmp{"filter"}.=    $tmp."   e.g.    'excl=1,2-5 incl=5 red=80 minSim=30 minIde=30 threshSgi'";
    $tmp{"filter"}.=    $tmp."   for PHD 'thresh=8 threshSgi=-10 mode=ide red=90'";
    $tmp{"filter"}.=    $tmp."   recommend 'filter=thresh=9 threshSgi=-3 mode=ide'";
    $tmp{"filter4phd"}=      "                    -> how to filter HSSP input to PHD\n";
    $tmp{"filter4phd"}.=$tmp."   recommend 'filter4phd=thresh=8 threshSgi=-10 mode=ide red=90'";
    undef %tmp2;
    $tmp{"special"}=~s/,*$//g;
#    $tmp{"scrAddHelp"}.=    "help saf-syn  : specification of SAF format\n";
#    $tmp{"scrAddHelp"}= "help zzz      : all info on zzz format\n";
#    $tmp{"scrAddHelp"}.="help zzz2     : all info on zzz2 format\n";
#     foreach $special ("zz3"){
#         $tmp{"special"}.=    "help $special".",";
#         $tmp{"scrAddHelp"}.=
#             "help ".$special." " x (9-length($special)).": ".$special." " x (10 -length($special))."specific info\n";}
#     $tmp{"special"}=~s/,*$//g;

#    $tmp{"help hssp"}=       "DES: HSSP = Homology derived Secondary Structure of Proteins format (ali, IN | OUT)\n";
#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelp

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
    $sbrName="iniGetArg";
				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg();

    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
        if    ($arg=~/^list$/i)                { $par{"isList"}=    1; }
	elsif ($arg=~/^nice-(\d+)$/)           { $par{"optNice"}=   "nice -".$1; }
	elsif ($arg eq "nonice")               { $par{"optNice"}=   " "; }
	elsif ($arg =~ /^de?bu?g$/)            { $par{"debug"}=     1; }
	elsif ($arg =~ /^de?bu?gProg$/i)       { $par{"debugProg"}= 1; }
	elsif ($arg=~ /not_verbose|silent|\-s/){ $par{"verbose"}=   0; }

	elsif ($arg=~ /^(all|doall)$/i)        { $par{"do"}=        $par{"doDef"};}

	elsif ($arg=~ /^db=(.+)$/i)            { $par{"parBlastDb"}=$1; }
	elsif ($arg=~/^big$/)                  { $par{"parBlastDb"}=   $par{"dbBig"}; }
	elsif ($arg=~/^swiss$/)                { $par{"parBlastDb"}=   $par{"dbSwiss"}; }
	elsif ($arg=~/^trembl$/)               { $par{"parBlastDb"}=   $par{"dbTrembl"}; }
	elsif ($arg=~/^pdb$/)                  { $par{"parBlastDb"}=   $par{"dbPdb"}; }

	elsif ($arg=~/^self$/)                 { $par{"doSelf"}=       1; }
	elsif ($arg=~/^(doDirect|direct)$/i)   { $par{"doDirect"}=     1; }

	elsif ($arg=~/^skip[A-Za-z]*$/)        { $par{"doNew"}=        0; }
	elsif ($arg=~/^new$/)                  { $par{"doNew"}=        1; }

	elsif ($arg=~/^filter$/)               { $par{"doFilterHssp"}= 1;  }
	elsif ($arg=~/^filter=(.+)$/)          { $par{"doFilterHssp"}= 1;  
						 $par{"filter"}=       $1; }
	elsif ($arg=~/^filter4phd$/)           { $par{"doFilterHssp"}= 1;  }
	elsif ($arg=~/^filter4phd=(.+)$/)      { $par{"doFilterHssp"}= 1;  
						 $par{"filter4phd"}=   $1; }

	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verb3"}=1             if ($par{"debug"});
    $par{"verb2"}=1             if ($par{"verb3"});
    $par{"verbose"}=1           if ($par{"verb2"});
	

				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" );
	$par{$kwd}.="/"       if ($par{$kwd} !~ /\/$/);}

    return(1,"ok $sbrName");
}				# end of iniGetArg

#===============================================================================
sub iniSetPar {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniSetPar                   changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $sbrName="iniSetPar";
				# correct to-do for PHD
    if ($par{"do"}=~/phdAcc/i && $par{"do"}=~/phdSec/i){
	$par{"do"}=~s/phdSec//i;
	$par{"do"}=~s/phdAcc//i;
	$par{"do"}=~s/,,/,/;$par{"do"}=~s/^,|,$//g;
	$par{"do"}.=",phdBoth";}
				# add filter
    if (defined $par{"doFilterHssp"} && $par{"doFilterHssp"} &&
	$par{"do"} !~/filter/) {
	$par{"do"}=~s/,$//g;
   	$par{"do"}.=",filter";}
    if ($par{"do"} =~/filter/ && (! defined $par{"doFilterHssp"}|| ! $par{"doFilterHssp"})) {
	$par{"doFilterHssp"}=1; }

    $par{"do"}=~s/,,/,/;$par{"do"}=~s/^,|,$//g;

				# ------------------------------
				# which jobs to run?
    foreach $kwd (@kwdJobs) {
	$job{$kwd}=0;		# default: do NOT do it
	$job{$kwd}=1            if ($par{"do"}=~/$kwd,|$kwd$/);
	$job{$kwd."Html"}=0;
	$job{$kwd."Html"}=1     if ($job{$kwd} && $par{"do". $kwd."Html"});
    }
				# add HTML keywords
    $#kwdJobsHtml=0;
    foreach $kwd (@kwdJobs){
	next if (! $job{$kwd});	# not to run!
	next if (! $job{$kwd."Html"});
	push(@kwdJobsHtml,$kwd."Html");}


				# ------------------------------
				# put working directory into dirs
    if (! $par{"keepDir"}){
	print "-*- WARNING on flight change of directories:\n";
	foreach $kwd ("Seq","HsspRaw","HsspFil",
		      "Phd","PhdDssp","PhdHtm","PhdNotHtm","PhdHtm07","PhdNotHtm07") {
	    next if (length($par{"dirWork"}) > 1 && 
		     $par{"dir".$kwd}=~/$par{"dirWork"}/);
	    next if (length($par{"dirWork"})<1);
				# current dir -> work dir
	    $par{"dir".$kwd}=~s/^\.*\//$par{"dirWork"}/g; }
    }
				# ------------------------------
				# update directories (create or delete)
    foreach $kwd (@kwdJobs) {
	$kwdDir=$translate_job2dir{$kwd};
	$kwdExt=$translate_job2ext{$kwd};
				# set 0 if not to run (watch phdBoth, see below)
	$par{$kwdDir}=0         if (! $job{$kwd} && $kwd !~/phd(Both|Acc|Sec)/);
	next if (! $job{$kwd});
				# create
	&sysMkdir($par{$kwdDir}) if (! -d $par{$kwdDir});
				# add 'notHtm' flag dir
	if ($kwd =~/htm/i) {
	    $kwdTmp=$kwdDir; $kwdTmp=~s/Htm/NotHtm/;
	    &sysMkdir($par{$kwdTmp}) if (! -d $par{$kwdTmp});}
				# HTML stuff to add?
	&sysMkdir($par{"dir".$kwd."Html"}) 
	    if ($par{"do".$kwd."Html"} && ! -d $par{"dir".$kwd."Html"});
				# also stuff for filtering for phd
	&sysMkdir($par{"dirHssp4phd"})
	    if ($kwd=~/filter/ && ! -d $par{"dirHssp4phd"});
    }
				# now check phdBoth
    $par{"dirPhd"}=0            if (! $job{"phdAcc"} && ! $job{"phdSec"} && 
				    ! $job{"phdBoth"});

				# ------------------------------
    foreach $kwd (@kwdDef){	# complete directories
	next if ($kwd !~ /^dir/);
	next if (! $par{$kwd});
	next if ($par{$kwd}=~/\/$/);
	$par{$kwd}.="/";
    }
				# ------------------------------
				# add 'title' 'ext'
    if    (! defined $par{"title"} && $ARGV[1] ne "auto"){
	$par{"title"}=$ARGV[1];$par{"title"}=~s/^.*\///g;$par{"title"}=~s/\..*$//g;}
    elsif (! defined $par{"title"}){
	$par{"title"}="genePhd";}
    foreach $kwd (@kwdDef){
	next if ($kwd !~ /^fileOut/);
	if (! defined $par{$kwd} || $par{$kwd} eq "unk" || length($par{$kwd})<2){
	    $kwdExt=$kwd; $kwdExt=~s/file/ext/; 
	    $ext="";
	    $ext=$par{"$kwdExt"} if (defined $par{"$kwdExt"});
	    if (! defined $par{"title"} || $par{"title"} eq "unk"){
		$par{"title"}=$scrName;$par{"title"}=~s/\.pl//g;}
	    $par{$kwd}=$pre.$par{"title"}.$ext;}}

				# ------------------------------
				# add output directory
    if (defined $par{"dirOut"} && $par{"dirOut"} ne "unk" && 
	$par{"dirOut"} ne "local" && length($par{"dirOut"})>1){
	if (! -d $par{"dirOut"}){ # make directory
	    ($Lok,$msg)=
		&sysMkdir($par{"dirOut"});
	    $dirOut=
		&complete_dir($par{"dirOut"});}}
    else{
	$dirOut="";}
				# ------------------------------
				# change names of output files
    foreach $kwd (@kwdDef){
	next if ($kwd !~ /^fileOut/);
	$tmp=$kwd; $tmp=~s/^fileOut//g;
				# do add directory
	if (length($par{"dirOut"}) > 1 && $par{$kwd} !~ /^$par{"dirOut"}/){
	    if (defined $par{$kwd} && length($par{$kwd})>1){
		$par{$kwd}=$par{"dirOut"}.$par{$kwd};}
	    else {
		$par{$kwd}=$par{"dirOut"}.$tmp;}}
				# do NOT add dir
	else {
	    $par{$kwd}=$tmp;}
				# now: add title
	$par{$kwd}.="-".$par{"title"};
	if (defined $par{"extOut"}){
	    $par{$kwd}.=$par{"extOut"};}
	else {
	    $par{$kwd}.=".out";}
	push(@fileOut,$par{$kwd});}
				# ------------------------------
				# add working directory
    if (defined $par{"dirWork"} && $par{"dirWork"} ne "unk" && $par{"dirWork"} ne "local" 
	&& $par{"dirWork"} ne "dirWork" && length($par{"dirWork"})>1) {
				# make directory
	if (! -d $par{"dirWork"}){
	    print "--- $sbrName mkdir ",$par{"dirWork"},"\n" if ($par{"verb2"});
	    ($Lok,$msg)=&sysMkdir($par{"dirWork"});
	    print "*** $sbrName failed making directory '",$par{"dirWork"},"'\n" if (! $Lok);}
	$par{"dirWork"}.="/"    if (-d $par{"dirWork"} && $par{"dirWork"} !~/\/$/); # add slash
	foreach $kwd (@kwdDef){
	    next if ($kwd !~ /^file/);
	    next if ($kwd =~ /^file(In|Out)/);
	    next if ($par{$kwd} =~ /^$par{"dirWork"}/);
	    $par{$kwd}=~s/dirWork/$par{"dirWork"}/;
	    next if ($par{$kwd} =~ /^$par{"dirWork"}/);
	    $par{$kwd}=$par{"dirWork"}.$par{$kwd};}}
				# ------------------------------
				# replace placeholders
    elsif (! $par{"dirWork"} || $par{"dirWork"} eq "unk" || $par{"dirWork"} eq "local" ||
	   $par{"dirWork"} eq "dirWork" || length($par{"dirWork"})<=1) {
	foreach $kwd (@kwdDef){
	    next if ($kwd !~ /^$par{"dirWork"}/);
	    $par{$kwd}=~s/$par{"dirWork"}//;
	}
	$par{"dirWork"}="";}
				# ------------------------------
				# array of Work files
    $#fileWork=0                if (! defined @fileWork);
    foreach $kwd (@kwdDef){
	next if ($kwd !~/^file/ && $kwd =~/file(In|Out)/);
	push(@fileWork,$par{$kwd});}

				# ------------------------------
				# running directory
    $par{"dirWork"}=$pwd        if (length($par{"dirWork"})<1);
	

				# ------------------------------
				# standard settings
				# ------------------------------
    $Lok=
	&brIniSet();            return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);

				# ------------------------------
				# check errors
    $exclude="exe,fileDefaults"; # to exclude from error check
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n",$msg)) if (! $Lok);  

    return(1,"ok $sbrName");
}				# end of iniSetPar

#===============================================================================
sub analyseDirs {
    local($LverbLoc,$Lverb2Loc,$fhloc,$dirLoc,$extLoc,$typeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@fileLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   analyseDirs                 checks which files are there and ok
#-------------------------------------------------------------------------------
    $sbrName="analyseDirs";$fhinLoc="FHIN"."$sbrName";

    print $fhloc 
	"--- $sbrName ","-" x 50,"\n",
	"--- $sbrName analyse type=$typeLoc, \n",
	"--- $sbrName dir=$dirLoc, ext=$extLoc\n" if ($LverbLoc);

				# ------------------------------
				# clean up memory
    $#fileSeq=0;		# slim-is-in

				# ------------------------------
    $#fileLoc=0;		# list local
    $#fileLoc=0;$dir=$dirLoc; $dir=~s/\/$//g; # $dir=~s/^\///g; # purge leading slash
    @fileLoc=
	&fileLsAllTxt($dir); # external lib-ut.pl
    $#fileTmp=0;		# ------------------------------
    foreach $fileLoc (@fileLoc){ # correct extensions?
	push(@fileTmp,$fileLoc) if ($fileLoc=~/$extLoc$/);}
    @fileLoc=@fileTmp;
    $#fileTmp=0;		# slim-is-in

				# ------------------------------
    undef %Lok;			# logicals for speed
    foreach $fileLoc (@fileLoc){
	$fileLoc=~s/^.*\///g;
	$Lok{$fileLoc}=1;}

    $#fileWantLoc=0;		# now all we want
    foreach $id (@id){
	$tmp=$id.$extLoc;
	push(@fileWantLoc,$tmp);}
				# ------------------------------
				# is what you want, what you have?
    foreach $fileWant (@fileWantLoc){
	$id=      $fileWant;$id=~s/\..*$//g;
	$filePath=$dirLoc.$fileWant;
	$file08=  0;
				# for HTM: add files flagging 'notHtm'
	if ($typeLoc !~ /html/ && $typeLoc=~/htm/i){
				# (a) handle directory
	    $dirTmp=$dirLoc;      $dirTmp=~s/phdHtm/notHtm/;
	    $fileNotHtm=$dirTmp.$fileWant; 
				# (b) deal with extension
	    $fileNotHtm=~s/(rdb|phd)Htm/notHtm/; 
				# (c) find the corresponding 08 file
	    if ($typeLoc=~/07/ && $job{"phdHtm"}) {
		$file08=$filePath;
		$file08=~s/07\//\//g; }} # jinfeng

				# --------------------
				# (1)  file existing?
	if    (! defined $Lok{$fileWant}){
				# (1a) is mode HTM but predicted globular
	    if ($typeLoc !~ /html/ && $typeLoc=~/htm/i && -e $fileNotHtm){
		print $fhloc "--- $sbrName \t notHtm ($typeLoc) '$filePath'\n" 
		    if ($Lverb2Loc);
		$res{$id,$typeLoc}="$typeLoc notHtm";}
				# (1b) HTM07 mode, HTM predicted, but also with 08 -> delete!
	    elsif ($typeLoc=~/htm07/i && ! -e $filePath && $file08 && -e $file08) {
		print $fhloc "--- $sbrName \t delete  ($typeLoc) '$filePath'\n" 
		    if ($Lverb2Loc);
		$res{$id,$typeLoc}="$typeLoc delete";}
				# (1c) is any mode
	    else {
		print $fhloc "--- $sbrName \t none   ($typeLoc) '$filePath'\n" 
		    if ($Lverb2Loc);
		$res{$id,$typeLoc}="$typeLoc none";}}
				# --------------------
	elsif (-z $filePath){	# (2)  empty file
	    print $fhloc "--- $sbrName \t empty  ($typeLoc) '$filePath'\n" 
		if ($Lverb2Loc);
	    $res{$id,$typeLoc}="$typeLoc empty";}
				# --------------------
				# (3)  file missing??
	else {
				# (3a) HTM mode but predicted globular
	    if    ($typeLoc=~/htm/i && -e $fileNotHtm){
		print $fhloc "--- $sbrName \t twice  ($typeLoc) '$filePath'\n" 
		    if ($Lverb2Loc);
		$res{$id,$typeLoc}="$typeLoc notHtm";}
				# (3b) HTM07 mode, HTM predicted, but also with 08 -> delete!
	    elsif ($typeLoc=~/htm07/i && -e $filePath && $file08 && -e $file08) {
		print $fhloc "--- $sbrName \t delete  ($typeLoc) '$filePath'\n" 
		    if ($Lverb2Loc);
		$res{$id,$typeLoc}="$typeLoc delete";
		# ****************
		unlink($filePath);
		# ****************
	    }
				# (3c) is any mode
	    else {
		print $fhloc "--- $sbrName \t ok     ($typeLoc) '$filePath'\n" 
		    if ($Lverb2Loc);
				# flag final HSSP files found
		$flag_fileHsspDo{$filePath}=1 
		    if (defined $flag_fileHsspDo{$filePath});
				# if HSSP add 
		$res{$id,$typeLoc}="$typeLoc ok";}}
    }

    return(1,"ok $sbrName");
}				# end of analyseDirs

#===============================================================================
sub doAli {
#    local($fhloc) = @_ ;
    local($sbr,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   doAli                       runs the Maxhom (+Blast) alignment + filter
#       in GLOBAL:              all
#       out GLOBAL:             @fileSeq
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbr="doAli";     $fhoutLoc="FHOUT_".$sbr;

    $dirSeq=    &complete_dir($par{"dirSeq"});
    $#fileSeq=$#fileHsspRaw=0;
				# ------------------------------
				# final dirHssp=dir from filter
    $extHsspRaw= $par{"extHsspRaw"};
    $extHsspFil= $par{"extHsspFil"};
    $extHssp4phd=$par{"extHssp4phd"};
    
    $dirHsspRaw= $par{"dirHsspRaw"};
    $dirHsspFil= $par{"dirHsspFil"};
    $dirHssp4phd=$par{"dirHssp4phd"};

				# final = filtered for phd
    if    ($job{"filter4phd"}){ $EXT_HSSP=$extHssp4phd;
				$DIR_HSSP=$dirHssp4phd;}
				# final = filtered
    elsif ($job{"filter"})    { $EXT_HSSP=$extHsspFil;
				$DIR_HSSP=$dirHsspFil;}
				# final = raw output
    else                      { $EXT_HSSP=$extHsspRaw;
				$DIR_HSSP=$dirHsspRaw;}

				# ------------------------------
				# produce list of input files
    $fileSeqList=$par{"dirWork"}."SEQLIST4phd-".$$.".list"; push(@fileTmp,$fileSeqList);
    $ctHsspToDo=0;
    open($fhoutLoc,">".$fileSeqList) || 
	return(&errSbrMsg("failed opening new fileSeqList=$fileSeqList"));

    foreach $id (@id){
	$fileSeq=    $dirSeq. $id.$par{"extSeq"};
				# fileHssp is the filtered output!
	$fileHssp=   $DIR_HSSP.  $id.$EXT_HSSP;
	$fileHsspRaw=$dirHsspRaw.$id.$extHsspRaw;
				# HSSP is empty: redo
	unlink($fileHssp)       if (-e $fileHssp && &is_hssp_empty($fileHssp));
				# HSSP already exists
	unlink($fileHssp)       if ($par{"doNew"});
        push(@fileSeq,    $fileSeq); 
	next if (-e $fileHsspRaw && ! $par{"doNew"});
	print $fhoutLoc $fileSeq,"\n";
	$fileSeqStore=$fileSeq;
	++$ctHsspToDo;
    }
    close($fhoutLoc);       
    return(&errSbrMsg("failed writing fileSeqList=$fileSeqList")) if (! -e $fileSeqList);
				# only one
    $fileSeqList=$fileSeqStore  if ($ctHsspToDo==1);
	
				# ------------------------------
				# running maxhom
				# ------------------------------
    if ($ctHsspToDo) {
	$arg=     "";
				# maxhom.pl
	$arg.=    " exeBinMaxhom=".$par{"exeMaxFor"};
	$arg.=    " doSelf=".$par{"doSelf"}." doDirect=".$par{"doDirect"}." doNew=".$par{"doNew"};
	$arg.=    " fileMaxhomDefaults=".$par{"fileMaxDef"}." fileMaxhomMetr=".$par{"fileMaxMat"};
	$arg.=    " list"           if ($ctHsspToDo > 1);
	$arg.=    " ARCH=$ARCH"; # not needed, but security!
				# blast stuff
	$arg.=    " exeBinBlastp=".$par{"exeBlastp"}." exeBlastFilter=".$par{"exeBlastpFilter"};
	$arg.=    " db=".$par{"parBlastDb"}." BLASTDB=".$par{"envBlastDb"}." BLASTMAT=".$par{"envBlastMat"};    
	$arg.=    " extHssp=$extHsspRaw"." dirHssp=$dirHsspRaw";
	
	$cmdLoc=$par{"exeMax"}." ".$fileSeqList." ".$arg;
	$cmdLoc.= " dbg"            if ($par{"debug"});
	
	eval      "\$cmd=\"$cmdLoc\""; 

	($Lok,$msg)=
	    &sysRunProg($cmd,$par{"fileOutScreen"},$fhTrace);

	return(&errSbrMsg("failed MaxHom ($cmd)",$msg,$SBR)) if (! $Lok); }

				# --------------------------------------------------
				# run both filters: for display and for PHD
				# --------------------------------------------------
    if ($job{"filter"} || $job{"filter4phd"}){
				# general part of argument to start job
	$argOpt=  " exeFilterHssp=".$par{"exeHsspFilterFor"};
	$argOpt.= " dbg"        if ($par{"debug"});
				# is list of HSSP files
	$argOpt.= " list"	if ($#fileHsspRaw>1);

	if ($par{"optNice"} =~/\d/ && $par{"optNice"} !~/nice/){
	    $exe=    "nice -".$par{"optNice"}." ".$par{"exeHsspFilter"};}
	else {
	    $exe=$par{"optNice"}." ".$par{"exeHsspFilter"};}
	$exe=~s/^\s*//g;
	foreach $id (@id) {
	    $fileHsspRaw= $dirHsspRaw.$id.$extHsspRaw;
	    next if (! -e $fileHsspRaw);
				# ------------------------------
				# (1) filter HSSP for users
	    if ($job{"filter"}) {
		$fileHsspFil=$dirHsspFil.$id.$extHsspFil;
		if ($par{"doNew"} || ! -e $fileHsspFil) {
		    $cmdLoc= $exe." ".$fileHsspRaw." ".$argOpt;
		    $cmdLoc.=" fileOut=".$fileHsspFil;
		    $cmdLoc.=" ".$par{"filter"};
		    eval      "\$cmd=\"$cmdLoc\""; 
		    ($Lok,$msg)=
			&sysRunProg($cmd,$par{"fileOutScreen"},$fhTrace);
		    return(&errSbrMsg("failed filter (4usr):\n".$cmd,$msg,$sbr)) if (! $Lok); }}
	    
				# ------------------------------
				# (2) filter HSSP file for PHD
	    if ($job{"filter4phd"}) {
		$fileHssp4phd=$dirHssp4phd.$id.$extHssp4phd;
		if ($par{"doNew"} || ! -e $fileHssp4phd) {
		    $cmdLoc= $exe." ".$fileHsspRaw." ".$argOpt;
		    $cmdLoc.=" fileOut=".$fileHssp4phd;
		    $cmdLoc.=" ".$par{"filter4phd"};
		    eval      "\$cmd=\"$cmdLoc\""; 
		    ($Lok,$msg)=
			&sysRunProg($cmd,$par{"fileOutScreen"},$fhTrace);
		    return(&errSbrMsg("failed filter (4phd):\n".$cmd,$msg,$sbr)) if (! $Lok); }}
	}}
				# ------------------------------
				# convert to HTML
				# ------------------------------
    if ($par{"do"."hssp"."Html"} || $par{"do"."filter"."Html"}) {
	print 
	    "*** WARN $sbr: HTML output not implemented, yet!!!\n" x 5;
	print $fhTrace 
	    "*** WARN $sbr: HTML output not implemented, yet!!!\n" x 5;
    }

				# ------------------------------
				# remove temporary files
    foreach $file (@fileTmp){
	unlink($file)           if (-e $file);}

    $#fileHsspRaw=0;		# slim-is-in

    return(1,"ok $sbr");
}				# end of doAli

#===============================================================================
sub doPred {
#    local($fhloc) = @_ ;
    local($sbr2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   doPred                      runs the predictions on the HSSP/sequence files
#       in GLOBAL:              all
#       out GLOBAL:             @fileSeq,@fileHssp
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbr2="doPred";     $fhoutLoc="FHOUT_".$sbr2;

    $ctfileIn=0;
    $nfileIn=($#fileHssp+$#fileHsspDo);
				# to mark first file
    $argOptPhdBoth=$argOptPhdHtm=0;

				# --------------------------------------------------
				# loop over all HSSP files
				# --------------------------------------------------
    foreach $fileHssp (@fileHssp,@fileHsspDo){
	next if (! -e $fileHssp);
	$id=$fileHssp;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
				# ------------------------------
	if (! -e $fileHssp){	# no alignment
	    print $fhTrace "*** hssp file '$fileHssp' missing\n";
	    next;}
	if (&is_hssp_empty($fileHssp)){
	    print $fhTrace "*** hssp file '$fileHssp' empty and was not detected\n";
	    next;}
				# ------------------------------
				# estimate time
	$estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
	$estimate="?"           if ($ctfileIn < 5);
	$tmpFile=$fileHssp;$tmpFile=~s/^.*\///g;
	printf $fhTrace 
	    "--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	    $id." ".$tmpFile,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;

				# ------------------------------
                                # (1) runs PHDsec, PHDacc
	if ($par{"do"}=~/phd(Both|Acc|Sec|All|3)/){
	    ($Lok,$msg)=
		&phdRunBoth($fileHssp,$id,$argOptPhdBoth,$fhTrace);
	    print $fhTrace $msg if (! $Lok); }

				# ------------------------------
				# (2) run PHDhtm
	foreach $val("07","08"){
	    next if ($val eq "08" && ! $job{"phdHtm"});
	    next if ($val eq "07" && ! $job{"phdHtm".$val});
	    
	    ($Lok,$msg)=
		&phdRunHtm($val,$fileHssp,$id,$argOptPhdHtm,$fhTrace);
	    print $fhTrace $msg if (! $Lok); }

				# ------------------------------
				# (3) to be continued
	
    }
				# end of loop over all HSSP
				# --------------------------------------------------
    return(1,"ok $sbr2");
}				# end of doPred

#===============================================================================
sub getIdList {
    local($argIn,$fhloc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getIdList                   digests first argument, gets ids to be managed
#-------------------------------------------------------------------------------
    $sbrName="getIdList";       $fhinLoc="FHIN".$sbrName;

    $#id=0;
				# ------------------------------
				# is file with list
				# ------------------------------
    if (-e $argIn){		# read file
	print $fhloc "--- $sbrName \t reading input file '$argIn'\n" if ($par{"verb2"});
	open($fhinLoc,$argIn)   || return(&errSbrMsg("failed opening input file=$argIn"));
	while (<$fhinLoc>) {
	    $_=~s/\s//g;
	    $_=~s/^.*\///g;	# purge dir
	    $_=~s/\.hssp.*$//g;	# purge extensions
	    $_=~s/\..*$//g;
#	    $_=~s/$par{"extSeq"}.*$//g; # 
#	    $_=~s/$par{"extHssp"}.*$//g; # purge extensions
	    next if (length($_)==0);
	    push(@id,$_);}
	close($fhinLoc);
				# get all HSSP files for ids
	$#tmp=$#fileHsspDo=0;
	foreach $id (@id){
	    if    ($job{"filter4phd"}){
		$hssp=$par{"dirHssp4phd"}.$id.$par{"extHssp4phd"};}
	    elsif ($job{"filter"}){
		$hssp=$par{"dirHsspFil"}.$id.$par{"extHsspFil"};}
	    else {
		$hssp=$par{"dirHsspRaw"}.$id.$par{"extHsspRaw"};}
				# not there, yet
	    if    (! -e $hssp)           {
		$res{$id,"hssp"}="hssp none";
		push(@fileHsspDo,$hssp);}
				# there, but empty
	    elsif (&is_hssp_empty($hssp)){
		$res{$id,"hssp"}="hssp emtpy";
		print $fhloc "-*- WARNING $sbrName delete empty hssp $hssp\n";
		unlink($hssp);
		push(@fileHsspDo,$hssp);}
				# exists, already
	    else                         {
		$res{$id,"hssp"}="hssp ok";
		push(@tmp,$hssp);}
	}
	@fileHssp=@tmp;}
				# ------------------------------
				# list all HSSP files present
				# ------------------------------
    elsif ($argIn =~/^auto/){	# 
	if    ($job{"filter"}){
	    $dirHssp=$par{"dirHsspFil"};
	    $extHssp=$par{"extHsspFil"};}
	elsif ($job{"filter4phd"}){
	    $dirHssp=$par{"dirHssp4phd"};
	    $extHssp=$par{"extHssp4phd"};}
	else {
	    $dirHssp=$par{"dirHsspRaw"};
	    $extHssp=$par{"extHsspRaw"};}
	    
				# first move files from local/run dir to HSSP
	print $fhloc 
	    "--- $sbrName \t sort into HSSP dir (",$dirHssp,")\n" if ($par{"verb2"});
		
	$#fileHssp=0;		# now listing all HSSP files
	$dir=$dirHssp;
	$dir=~s/^\///g;		# purge leading slash
	@fileHssp=&fileLsAllTxt($dir); # external lib-ut.pl
	$#tmp=0;
	foreach $hssp (@fileHssp){
	    next if ($hssp !~/$extHssp/);
	    $id=$hssp;$id=~s/$extHssp$//g;$id=~s/^.*\///g;
	    push(@id,$id);
	    ($Lok,$txt,$file)=
		&isHsspGeneral($hssp); # external lib-prot.pl
	    $res{$id,"hssp"}=$txt;
	    $txt="isHssp";	# xx
	    push(@tmp,$file) if ($txt eq "isHssp");
	}
	@fileHssp=@tmp;}
    else {
	return(&errSbrMsg("first argument must be 'list_of_ids' or 'auto'"));}
				# slim-is-in
    return(1,"ok $sbrName");
}				# end of getIdList

#===============================================================================
sub maxRunSelfLoc {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxRunSelfLoc               writes HSSP file from sequence
#-------------------------------------------------------------------------------
    if ($scrName){$tmp="$scrName".":";}else{$tmp="";}
    $sbrName="$tmp"."maxRunSelfLoc";$fhinLoc="FHIN"."$sbrName";

    $id=$fileInLoc;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    $dirHsspSelf=$par{"dirHsspSelf"}; 
				# output hssp self
    $hsspSelf= $par{"dirHsspSelf"}; $hsspSelf=&complete_dir($hsspSelf); 
    $hsspSelf.=$id.$par{"extHsspSelf"};
    return(1,"ok $sbrName",$hsspSelf) if (-e $hsspSelf); # return if already existing

				# ------------------------------
    if (! -d $par{"dirSeq"}){	# is there a correponding sequence?
	print "*** ERROR $scrName fileInLoc=$fileInLoc, no dir for sequence (dirSeq)\n";
	exit;}
    $seq=$par{"dirSeq"}; $seq=&complete_dir($seq);$seq.=$id.$par{"extSeq"};
    if (! -e $seq){
	return(0,
	       "*** ERROR $sbrName fileInLoc=$fileInLoc, no sequence=$seq (in dir=dirSeq)\n",
	       $hsspSelf);}
    $Ldel=0;			# ------------------------------
    if (! &isFasta($seq)){	# check input format (must be fasta)
	if (&isPir($seq)){
	    ($Lok,$idTmp,$seqLoc)= &pirRdSeq($seq);
	    return(0,"*** ERROR $sbrName: after 'pirRdSeq\n$idTmp\n") if (!$Lok);
	    $fastaTmp="FASTA-".$$.".f";$Ldel=1;
	    ($Lok,$err)=           &fastaWrt($fastaTmp,$id,$seqLoc);}
	elsif (&isSwiss($seq)){
	    ($Lok,$idTmp,$seqLoc)= &swissRdSeq($seq);
	    return(0,"*** ERROR $sbrName: after 'swissRdSeq\n$idTmp\n") if (!$Lok);
	    $fastaTmp="FASTA-".$$.".f";$Ldel=1;
	    ($Lok,$err)=           &fastaWrt($fastaTmp,$id,$seqLoc);}
	else {
	    return(0,"*** ERROR $sbrName fileInLoc=$fileInLoc, seq=$seq, wrong format\n",$hsspSelf)}}
    else {$fastaTmp=$seq;}
				# make directory if missing
    ($Lok,$msg)=&sysMkdir($dirHsspSelf) if (! -d $dirHsspSelf);
				# ------------------------------
				# run maxhom self
    $jobId=$par{"jobid"};
    ($Lok,$err)=
	&maxhomRunSelf($par{"optNice"},$par{"exeMax"},$par{"fileMaxDef"},$jobId,$fastaTmp,
		       $hsspSelf,$par{"fileMaxMat"},"STDOUT");

    unlink($fastaTmp) if ($Ldel);
    return(0,"ERROR $sbrName err=$err",$hsspSelf) if (! $Lok);

    system("\\rm MAXHOM*$jobId*");

    return(1,"ok $sbrName",$hsspSelf);
}				# end of maxRunSelfLoc

#===============================================================================
sub phdRunBoth {
    local($fileHssp,$id,$argOpt,$fhloc)=@_;
    local($sbr,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunBoth                  runs PHDsec , PHDacc
#       in/out (GLOBAL):                    
#-------------------------------------------------------------------------------
    $sbr="phdRunBoth";
				# temporary files:
    $filePhd=    $par{"dirWork"}.  $id.$par{"extPhdHuman"};
    $fileRdb=    $par{"dirWork"}.  $id.$par{"extPhd"};
				# only one to keep:
    $fileFinRdb= $par{"dirPhd"}.   $id.$par{"extPhd"};

				# already existing do not repeat!
    if (-e $fileFinRdb && ! $par{"doNew"}){
	print $fhloc "--- $sbr skip PHDboth, as existing phd=$fileFinRdb\n";
	return(1,"already there $fileFinRdb");}

				# ------------------------------
				# build up argument (only 1st time)
    if (! $argOpt) {
	$argOpt="";
	if    ($par{"do"}=~/both/i)  {$argOpt.=" both"; $job="phdBoth";}
	elsif ($par{"do"}=~/acc/i)   {$argOpt.=" acc";  $job="phdAcc"; }
	elsif ($par{"do"}=~/sec/i)   {$argOpt.=" sec";  $job="phdSec"; }
	elsif ($par{"do"}=~/all|3/i) {$argOpt.=" 3";    $job="phdBoth";}
				# default = both (acc + sec)
	else                         {$argOpt.=" both"; $job="phdBoth";}

	$argOpt.=    " exePhd=".$par{"exePhdFor"}." ";

	if ($par{"optNice"} =~/\d/ && $par{"optNice"} !~/nice/){
	    $exe=    "nice -".$par{"optNice"}." ".$par{"exePhd"};}
	else {
	    $exe=$par{"optNice"}." ".$par{"exePhd"};}
	$argOpt.= " dbg"        if ($par{"debug"});

				# convert to HTML
	if ($par{"doHtml_".$job}) {
	    $argOpt.= " html";
	    $dirHtml=$par{"dirHtml_".$job};
	    $extHtml=$par{"extHtml_".$job}; }
    }

    $cmdLoc= "$exe $fileHssp $argOpt fileOutPhd=$filePhd fileOutRdb=$fileRdb ARCH=$ARCH"; 

				# HTML file
    $fileFinHtml=0;
    $fileFinHtml=$dirHtml.$id.$extHtml   if ($par{"doHtml_".$job});

    $cmdLoc.=" fileOutHtml=$fileFinHtml" if ($fileFinHtml);

    eval      "\$cmd=\"$cmdLoc\""; 
				# --------------------------------------------------
				# run PHD
    ($Lok,$msg)=
	&sysRunProg($cmd,$par{"fileOutScreen"},$fhTrace);

    return(&errSbrMsg("failed PhdBoth ($cmd)",$msg,$sbr)) if (! $Lok); 

				# ------------------------------
				# check existence and clean up
    $msgErr="";
    if (! -e $fileRdb){		# missing
	$msgErr.="*** ERROR $sbr: no output fileRdb=$fileRdb ($cmd)\n";}
    else {			# ok: move
	($Lok,$err)=&fileMv($fileRdb,$fileFinRdb,$fhloc);
	$msgErr.=$err."\n"      if (! $Lok);}

				# clean human readable files
    unlink($filePhd);
    return(0,$msgErr)           if (length($msgErr)>0);
    return($Lok,"ok $sbr");
}				# end of phdRunBoth

#===============================================================================
sub phdRunHtm {
    local($valLoc,$fileHssp,$id,$argOpt,$fhloc)=@_;
    local($sbrName,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunHtm                  runs PHDhtm
#       in/out (GLOBAL):                    
#-------------------------------------------------------------------------------
    $sbr="phdRunHtm";

				# temporary files:
    $filePhd=$par{"dirWork"}.$id.$par{"extPhdHtmHuman"};
    $fileRdb=$par{"dirWork"}.$id.$par{"extPhdHtm"};
    $fileNot=$par{"dirWork"}.$id.$par{"extPhdNotHtm"};

				# files to keep:
				# default mode
    if ($valLoc eq "def" || $valLoc eq "08"){
	$dirRdb=$par{"dirPhdHtm"}; # jinfeng
	$dirNot=$par{"dirPhdNotHtm"}; # jinfeng
	$fileFinRdb=$par{"dirPhdHtm"}.   $id.$par{"extPhdHtm"};
	$fileFinNot=$par{"dirPhdNotHtm"}.$id.$par{"extPhdNotHtm"};}
				# optHtmIsit=0.7
    else {
	$dirRdb=$par{"dirPhdHtm"};   $dirRdb=~s/\/$/$valLoc\//;
	$dirNot=$par{"dirPhdNotHtm"};$dirNot=~s/\/$/$valLoc\//;
	$fileFinRdb=$dirRdb.$id.$par{"extPhdHtm"};
	$fileFinNot=$dirNot.$id.$par{"extPhdNotHtm"};}
    
				# already existing dont repeat!
    if (! $par{"doNew"} && (-e $fileFinRdb || -e $fileFinNot)){
	if (-e $fileFinNot) {
	    $fileTmp=$fileFinNot;}
	else {
	    $fileTmp=$fileFinRdb;}
	print $fhloc "--- $sbr skip PHDhtm ($valLoc), as existing=$fileTmp\n";
	return(1,"already there $fileTmp"); }

				# --------------------------------------------------
				# save time: if NOT HTM in 07, skip 08!
    if ($valLoc eq "def" || $valLoc eq "08"){
	$dirNotTmp=  $par{"dirPhdNotHtm"};$dirNotTmp=~s/\/$/07\//;
	$file07Not=  $dirNotTmp.$id.$par{"extPhdNotHtm"};
	if (-e $file07Not) {
	    ($Lok,$msg)=
		&sysCpfile($file07Not,$fileFinNot);
	    if ($Lok && -e $fileFinNot) {
		print $fhloc "--- $sbr skip PHDhtm ($valLoc), as existing=$fileFinNot\n";
		return(1,"already there $fileFinNot"); }}}
				# save time: if HTM07 and already HTM08, skip 07!
    if ($valLoc eq "07") {
	$file08=     $fileFinRdb; $file08=~s/07\//\//g;	# jinfeng
	print $fhloc "--- $sbr skip PHDhtm ($valLoc), as existing=$file08\n";
	return(1,"already there 08=$file08, thus not again 07=$fileFinRdb")
	    if (-e $file08);}
	

				# ------------------------------
				# build up argument (only 1st time)
    if (! $argOpt) {
	$argOpt="htm";
	$argOpt.=    " exePhd=".$par{"exePhdFor"}." ";
	if ($par{"optNice"} =~/\d/ && $par{"optNice"} !~/nice/){
	    $exe=    "nice -".$par{"optNice"}." ".$par{"exePhd"};}
	else {
	    $exe=$par{"optNice"}." ".$par{"exePhd"};}
	$argOpt.= " dbg"        if ($par{"debug"});
				# convert to HTML
	$job= "phdHtm";
	$job.=$valLoc           if ($valLoc =~ /07/);
	if ($par{"doHtml_".$job}) {
	    $argOpt.= " html";
	    $dirHtml=$par{"dirHtml_".$job};
	    $extHtml=$par{"extHtml_".$job}; }
    }
	

    $argAdd="optHtmisitMin=0.8";
    $argAdd="optHtmisitMin=0.7" if ($valLoc eq "07");
	
    $cmdLoc= "$exe $fileHssp $argOpt $argAdd fileOutPhd=$filePhd fileOutRdb=$fileRdb ARCH=$ARCH"; 

				# HTML file
    $fileFinHtml=0;
    $fileFinHtml=$dirHtml.$id.$extHtml   if ($par{"doHtml_".$job});

    $cmdLoc.=" fileOutHtml=$fileFinHtml" if ($fileFinHtml);

    eval      "\$cmd=\"$cmdLoc\""; 
				# --------------------------------------------------
				# run PHD
    ($Lok,$msg)=
	&sysRunProg($cmd,$par{"fileOutScreen"},$fhTrace);

    return(&errSbrMsg("failed PhdHtm ($valLoc) ($cmd)",$msg,$sbr)) if (! $Lok); 

				# ------------------------------
				# check existence and clean up
    $msgErr="";
				# --------------------
				# if not HTM: remove all
    if    (-e $fileNot){
	$tmp=$fileNot;		# $tmp=$valLoc;$tmp="" if ($valLoc eq "def");
	$tmp=$fileNot;$fileNot=~s/$par{"dirWork"}/$dirNot/;
	print $fhloc 
	    "--- $sbr flag file 'no HTM' detected (mv $tmp $fileNot)\n";
	($Lok,$err)=            
	    &sysMvfile($tmp,$fileNot);
				# remove unnessary files
	foreach $file ($filePhd,$fileRdb,$fileFinHtml){
	    unlink($file) if ($file && -e $file);}}
				# --------------------
				# missing output
    elsif (! -e $fileRdb){
	$msgErr.="*** ERROR $sbr: no output fileRdb=$fileRdb ($cmd)\n";}

    else {			# ok: move
	($Lok,$err)=&fileMv($fileRdb,$fileFinRdb,$fhloc);
	$msgErr.=$err."\n"      if (! $Lok);}

				# clean human readable files
    unlink($filePhd);
    return(0,$msgErr)           if (length($msgErr)>0);
    return($Lok,"ok $sbr");
}				# end of phdRunHtm

#===============================================================================
sub wrtFin {
    local($LverbLoc,$Lverb2Loc,$fhloc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtFin                      writes the final reports
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."wrtFin";
    $fhoutLoc=  "FHOUT_".      $sbrName;
    $fhoutOk=   "FHOUT_OK_".   $sbrName;
    $fhoutDo=   "FHOUT_DO_".   $sbrName;
#    $fhoutTwice="FHOUT_TWICE_".$sbrName;

    if (defined $par{"fileOutSyn"} && length($par{"fileOutSyn"})>5){
	$fileOutLoc=$par{"fileOutSyn"} ;}
    else {
	$fileOutLoc=
	    $par{"fileOutSyn"}=$par{"dirWork"}.$par{"preOutSyn"}.$par{"title"}.".rdb";
    }
    $tmp=$fileOutLoc; $tmp=~s/^.*\///g;
    push(@fileOut,$tmp);
    open("$fhoutLoc",">".$fileOutLoc) || return(&errSbrMsg("failed to open fileOut=$fileOutLoc"));

				# --------------------------------------------------
				# loop over all file types
				# --------------------------------------------------
    foreach $kwd (@kwdJobs){
	next if (! $job{$kwd});	# not to run!

				# ------------------------------
				# open files ok/do
	$fileDo=   $par{"dirWork"}.$par{"preOutDo"}.   $kwd.".list"; 
	$fileOk=   $par{"dirWork"}.$par{"preOutOk"}.   $kwd.".list";
	open($fhoutDo,   ">".$fileDo)    || return(&errSbrMsg("failed to open fileDo=$fileDo"));
	open($fhoutOk,   ">".$fileOk)    || return(&errSbrMsg("failed to open fileOk=$fileOk"));

	$ctOk=$ctEmpty=$ctNone=$ctNotHtm=$ctDelete=0;
				# ------------------------------
				# dir/ext for fileDo
	if    ($kwd =~/html/i) {
	    $dirOk= $par{"dir".$kwd};    $extOk=$par{"ext".$kwd};
	    $dirDo= $par{"dir".$kwd};    $extDo=$par{"ext".$kwd};}
	elsif ($kwd =~/hssp/) {
	    $dirOk= $DIR_HSSP;           $extOk=$EXT_HSSP;
	    $dirDo= $par{"dirSeq"};      $extDo=$par{"extSeq"};}
	elsif ($kwd =~/filter4phd/) {
	    $dirOk= $par{"dirHssp4phd"}; $extOk=$par{"extHssp4phd"};
	    $dirDo= $par{"dirHsspRaw"};  $extDo=$par{"extHsspRaw"};}
	elsif ($kwd =~/filter$/) {
	    $dirOk= $par{"dirHsspFil"};  $extOk=$par{"extHsspFil"};
	    $dirDo= $par{"dirHsspRaw"};  $extDo=$par{"extHsspRaw"};}
	else {
	    $kwdDir=$translate_job2dir{$kwd};
	    $kwdExt=$translate_job2ext{$kwd};
	    $dirOk= $par{$kwdDir};       $extOk=$par{$kwdExt};
	    $dirDo= $DIR_HSSP;           $extDo=$EXT_HSSP;}

				# dir/ext for fileOk
	$extOk=~s/(def|Both)//gi;
	$extDo=~s/(def|Both)//gi;

				# ------------------------------
	foreach $id (@id){	# loop over all ids
	    $Lok=0;
	    $kwd=~s/def//g;
	    if    ($res{$id,$kwd} eq "$kwd ok")     {++$ctOk;     $Lok=1;}
	    elsif ($res{$id,$kwd} eq "$kwd notHtm") {++$ctNotHtm; $Lok=1;}
	    elsif ($res{$id,$kwd} eq "$kwd empty")  {++$ctEmpty;  }
	    elsif ($res{$id,$kwd} eq "$kwd none")   {++$ctNone;   }
	    elsif ($res{$id,$kwd} eq "$kwd delete") {++$ctDelete;  }
	    else  {print"*** $sbrName \t strange result id=$id, kwd=$kwd, res=",
		   $res{$id,$kwd},"\n";
		   next;}
				# write into file list
	    $fileOk1=$dirOk.$id.$extOk;
	    $fileDo1=$id;	# write id, only 
#	    $fileDo=$dirDo.$id.$extDo;
	    if    ($Lok && -e $fileOk1){ # file ok
		print $fhoutOk "$fileOk1\n";}
	    elsif ($Lok){	# file do (strange)
		if ($res{$id,$kwd} ne "$kwd notHtm"){
		    print 
			"*** $sbrName \t unidentified result id=$id, kwd=$kwd, res=",
			$res{$id,$kwd}," (fileOk1=$fileOk1, dirOk=$dirOk, extOk=$extOk)\n";
		    next;}}
	    else  {		# file do
		print $fhoutDo "$fileDo1\n";}}
				# count 
	close($fhoutDo);close($fhoutOk);
#	close($fhoutTwice);
	$res{$kwd,"ok"}=    $ctOk;     $res{$kwd,"empty"}= $ctEmpty;
	$res{$kwd,"none"}=  $ctNone;   $res{$kwd,"notHtm"}=$ctNotHtm;
	$res{$kwd,"delete"}=$ctDelete;
				# ------------------------------
				# remove empty files
#	unlink($fileTwice)      if ($ctTwice < 1);
	unlink($fileOk)         if ($ctOk < 1);
	unlink($fileDo)         if ($ctNone < 1);
    }				# end of loop over kwds

				# --------------------------------------------------
				# write overall statistics
				# --------------------------------------------------
    @fhLoc=($fhoutLoc);
    push(@fhLoc,$fhloc)         if ($LverbLoc);
    foreach $fh (@fhLoc){
	print $fh
	    "\# Perl-RDB\n","\# \n",
	    "\# DATA         --------------------------------------------------\n",
	    "\# DATA         Overall statistics\n",
	    "\# DATA         --------------------------------------------------\n",
	    "\# DATA         \n",
	    "\# DATA BEG SUMMARY\n";
	print $fh 
	    "\# DATA  file         ","sum       ";
	foreach $kwd (@kwdStatus){
	    printf $fh "%-10s ",$kwd;}
	print $fh "\n";
	
	foreach $kwd (@kwdJobs){
				# not to run!
	    next if (! $job{$kwd});

	    print  $fh "\# DATA  $kwd"," " x (10-length($kwd))," : ";
                                # get sum
            $sum=0;
	    foreach $kwdStatus (@kwdStatus){
		$sum+=$res{$kwd,$kwdStatus} if (defined $res{$kwd,$kwdStatus});}
	    printf $fh "%-10s ",$sum;
	    foreach $kwdStatus (@kwdStatus){
		$tmp="";
		$tmp=$res{$kwd,$kwdStatus} if (defined $res{$kwd,$kwdStatus});
		printf $fh "%-10s ",$tmp;}
	    print $fh "\n";}
	print $fh "\# DATA END SUMMARY\n";
    }
    print $fhoutLoc "id      ";	# names
    foreach $kwd (@kwdJobs){
	next if (! $job{$kwd});
	print $fhoutLoc "\t$kwd";}
    print $fhoutLoc "\n";

    foreach $id (@id){
	print $fhoutLoc $id;
	foreach $kwd (@kwdJobs){
				# not to run!
	    next if (! $job{$kwd});

	    $tmp=$res{$id,$kwd};$tmp=~s/$kwd //g;
	    $tmp.=" " x (10 - length($tmp));
	    print $fhoutLoc "\t$tmp";}
	print $fhoutLoc "\n";}
    close($fhoutLoc);
				# ------------------------------
				# remove empty files
    $#tmp=0;
    foreach $file (@fileOut){
	next if (! -e $file);	# missing
	if (-z $file){		# empty
	    unlink($file);
	    next;}
	$tmp=`wc -l $file`; $tmp=~s/\D//g;
	if ($tmp < 1) {		# also empty
	    unlink($file);
	    next;}
	push(@tmp,$file);}
    @fileOut=@tmp; 

				# --------------------------------------------------
				# blabla to screen
				# --------------------------------------------------
    if ($Lverb2Loc){  
	print $fhloc 
	    "--- $scrName finished its task\n",
	    "--- \n--- Output files are:\n";
	$it=0;
	for ($it=1; $it<=$#fileOut; $it+=3) {
	    printf $fhloc "--- %-10s "," ";
	    foreach $it2 (0..2) {
		last if (! defined $fileOut[$it+$it2]);
		printf $fhloc "%-20s ",$fileOut[$it+$it2];
	    }
	    print $fhloc "\n"; 
	}
    }
    return(1,"ok $sbrName");
}				# end of wrtFin

