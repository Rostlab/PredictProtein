#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "wrapper to run program SEG (Wootton & Federhen)";
$scrIn=      "fasta-file(s), or list-thereof, or FASTAmul";
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= "modeSeg=<norm|glob> (normal complexity or globular) \n";
$scrHelpTxt= " \n";
$scrHelpTxt= " \n";
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Aug,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0

($Lok,$msg)=
    &segRunScr(@ARGV);
print "*** $scrName: final msg=".$msg."\n" if (! $Lok);

exit;


#===============================================================================
sub segRunScr {
    local($SBR,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   segRunScr                   runs SEGP (designed to become package)
#       in:                     $fileInLoc,fileOut=$fileOut, asf. ...
#                               input like for any script
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."segRunScr";$fhinLoc="FHIN_"."segRunScr";
    
				# ------------------------------
    ($Lok,$msg)=		# initialise variables
	&iniSeg();              &errScrMsg("after iniSeg",$msg,$scrName) if (! $Lok);
    
# ------------------------------------------------------------------------------
# now do it
# ------------------------------------------------------------------------------
				# ------------------------------
				# (1) process files
				# ------------------------------
    $nfileIn= $#fileIn; 
    $ctfileIn=0;
    $#wrtSyn=0;			# ready to write (sprintf), one line per file
    $ctFileWithX=0;		# counts the number of files for which at least one X found

    while (@fileIn) {
	$fileIn=shift @fileIn; ++$ctfileIn;
	$idIn=  $fileIn; $idIn=~s/^.*\/|\..*$//g;
				# ------------------------------
				# estimate time
	$estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
	$estimate="?"           if ($ctfileIn < 5);
	printf 
	    "--- %-20s %4d (%4.1f%-1s), time left=%-s\n",
	    $idIn,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;

				# ------------------------------
				# run SEG
	$fileOut=$fileIn; $fileOut=~s/^.*\/|\..*$//g;
	$fileOut=$par{"dirOut"}.$fileOut.$par{"extOut"};
	$fileOut=0              if ($par{"nofileSeg"});

				# note: @argSeg defined in: iniSeg (towards end)
#	print "xx argSeg=",join(' ',@argSeg),"\n";exit;
	($Lok,$msg)=
	    &segRun($fileIn,$fileOut,$par{"exeSeg"},$par{"cmdSeg"},@argSeg,$fhTrace);
	return(&errSbrMsg("failed running SEG on $fileIn -> $fileOut",$msg,$SBR)) if (! $Lok);

	next if ($par{"nofileSeg"});

				# remove afterwards!
	push(@fileRm,$fileOut)  if (! $par{"wrtSeg"});

				# ------------------------------
				# digest SEG output
				# out: length of entire sequence
				#      number of 'x'
	($Lok,$msg,$lenSeq,$lenCom)=
	    &segInterpret($fileOut);
	return(&errSbrMsg("failed interpreting SEG file=$fileOut",$msg,$SBR)) if (! $Lok);

	$ratio=0;
	$ratio=100*($lenCom/$lenSeq) if ($lenSeq > 0);
	++$ctFileWithX          if ($ratio > 0);

	$tmpWrt= sprintf ("%-20s".$SEP."%6d".$SEP."%6d".$SEP."%6.1f"."\n",
			  $idIn,$lenSeq,$lenCom,$ratio);
	push(@wrtSyn,$tmpWrt);
	print $fhTrace "--- ". $tmpWrt   if ($par{"verbose"});
    }
				# ------------------------------
				# (3) write synopsis
				# ------------------------------

    open("$fhout",">".$par{"fileOutSyn"}) || 
	die "*** $scrName ERROR creating fileOutSyn=".$par{"fileOutSyn"};
				# ------------------------------
				# write header of file
				# ------------------------------
    $ratioFile=0;
    $ratioFile=100*($ctFileWithX/$nfileIn) if ($nfileIn > 0);

    $tmpWrt=  "# Perl-RDB\n"."# \n";
    $tmpWrt.= "# running SEG  with '".join(' ',@argSeg)."'\n";
    $tmpWrt.= sprintf ("# PARA: %-12s =\t%6d\n",  "numProt",     $nfileIn);
    $tmpWrt.= sprintf ("# PARA: %-12s =\t%6d\n",  "numProtWithX",$ctFileWithX);
    $tmpWrt.= sprintf ("# PARA: %-12s =\t%8.1f\n","ratioFound",  $ratioFile);

    $tmpWrt.= $txtQuotePaper;
    $tmpWrt.= sprintf ("# NOTA: %-12s =\t%-s\n","id",      "name of protein");
    $tmpWrt.= sprintf ("# NOTA: %-12s =\t%-s\n","lenSeq",  "length of protein");
    $tmpWrt.= sprintf ("# NOTA: %-12s =\t%-s\n","lenCom",  "number of composition-biased residues");
    $tmpWrt.= sprintf ("# NOTA: %-12s =\t%-s\n","ratioSeg","100*(lenCom/lenSeq)");
    $tmpWrt.= sprintf ("%-20s".$SEP."%6s".$SEP."%6s".$SEP."%6s"."\n",
		       "id","lenSeq","lenCom","ratio");
    print $fhout $tmpWrt;
				# write data
    foreach $wrt (@wrtSyn) {
	print $fhout $wrt;}

    close($fhout);


				# --------------------------------------------------
				# work done, go home
				# --------------------------------------------------
                                # deleting intermediate files
    &cleanUp() if (! $par{"debug"}); 
                                # ------------------------------
                                # final words
    if ($Lverb) { 
	print "--- $scrName ended fine .. -:\)\n";
                                # ------------------------------
	$timeEnd=time;    # runtime , run time
	$timeRun=$timeEnd-$timeBeg;
	print 
	    "--- date     \t \t $Date \n",
	    "--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";
	print "--- output synopsis in ".$par{"fileOutSyn"}."\n" if (-e $par{"fileOutSyn"}); }

    return(1,"ok $SBR");
}				# end of segRunScr




#==============================================================================
# library collected (begin) lll
#==============================================================================


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
                    if (-e $par{$kwd} && ! -x $par{$kwd});}
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
sub segInterpret {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   segInterpret                reads FASTA-formatted output from SEG, counts 'x'
#       in:                     $fileInLoc
#       out:                    1|0,msg,$len(all),$lenComposition(only the 'x')
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="segInterpret";$fhinLoc="FHIN_"."segInterpret";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

				# ------------------------------
				# read FASTA formatted file
				# ------------------------------
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $seq="";			# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	next if ($_=~/^\s*>/);	# skip id
	$seq.=$_;
    } close($fhinLoc);

				# ------------------------------
				# count 'x'
				# ------------------------------
    $seq=~s/\s//g;
    $seq=~tr/[a-z]/[A-Z]/;
				# count 'normal residues'
    $tmp=$seq;
    $tmp=~s/[^ABCDEFGHIKLMNPQRSTVWYZ]//g;
    $lenSeq=length($tmp);
				# count 'x'
    $tmp=$seq;
    $tmp=~s/[^X]//g;
    $lenCom=length($tmp);

    return(1,"ok $sbrName",($lenSeq+$lenCom),$lenCom);
}				# end of segInterpret

#==============================================================================
sub segRun {
    local($fileInLoc,$fileOutLoc,$exeSegLoc,$cmdSegLoc,
	  $modeSegLoc,$winSegLoc,$locutSegLoc,$hicutSegLoc,$optSegLoc,$fhSbrErr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   segRun                      runs the Wootton program SEG on one FASTA sequence
#                               the following parameters can be set:
#         <window> - OPTIONAL window size (default 12) 
#         <locut>  - OPTIONAL low (trigger) complexity (default 2.2) 
#         <hicut>  - OPTIONAL high (extension) complexity (default 2.5) 
#         <options> 
#            -x  each input sequence is represented by a single output 
#                sequence with low-complexity regions replaced by 
#                strings of 'x' characters 
#            -c <chars> number of sequence characters/line (default 60)
#            -m <size> minimum length for a high-complexity segment 
#                (default 0).  Shorter segments are merged with adjacent 
#                low-complexity segments 
#            -l  show only low-complexity segments (fasta format) 
#            -h  show only high-complexity segments (fasta format) 
#            -a  show all segments (fasta format) 
#            -n  do not add complexity information to the header line 
#            -o  show overlapping low-complexity segments (default merge) 
#            -t <maxtrim> maximum trimming of raw segment (default 100) 
#            -p  prettyprint each segmented sequence (tree format) 
#            -q  prettyprint each segmented sequence (block format) 
#                               e.g. globular W=45 3.4 3.75  (for coiled-coil)
#                                    globular W=25 3.0 3.30  (for histones)
#       NOTE: for input options give '0' to take defaults!                       
#       in:                     $fileInLoc : input sequence (FASTA format!)
#       in:                     $fileOutLoc: output of SEG
#                          NOTE: = 0 -> STDOUT!
#       in:                     $exeSegLoc : executable for SEG
#       in:                     $cmdSegLoc : =0 or entire command line to run SEG.ARCH!!
#       in:                     $modeSegLoc: 'norm|glob'
#                                            norm  -> win = 12
#                                            glob-> win = 30
#       in:                     $winSegLoc : window (default = 12, or see above)
#       in:                     $locutSegLoc
#       in:                     $hicutSegloc
#       in:                     $optSegLoc : any of the following as a comma separated list:
#                                            x,c,m,l,h,a,n,o,t,p,q
#                                            default: -x 
#       in:                     $fhSbrErr  : file handle for error messages
#       out:                    1|0,msg   implicit: fileOutLoc
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."segRun";$fhinLoc="FHIN_"."segRun";$fhoutLoc="FHIN_"."segRun";
    
				# ------------------------------
				# defaults
    $exeSegDef=          "/home/rost/pub/molbio/bin/seg".".".$ARCH;
    $modeSegDef=         "glob";
    $winSegGlobDef=    30;
    $locutGlobDef=      3.5;
    $hicutGlobDef=      3.75;

    $winSegNormDef=    12;
    $locutNormDef=      2.2;
    $hicutNormDef=      2.5;


    $optSegDef=          "x";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);
    return(&errSbr("not def exeSegLoc!"))          if (! defined $exeSegLoc);
    return(&errSbr("not def cmdSegLoc!"))          if (! defined $cmdSegLoc);
    return(&errSbr("not def modeSegLoc!"))         if (! defined $modeSegLoc);
    return(&errSbr("not def winSegLoc!"))          if (! defined $winSegLoc);
    return(&errSbr("not def locutSegLoc!"))        if (! defined $locutSegLoc);
    return(&errSbr("not def hicutSegLoc!"))        if (! defined $hicutSegLoc);
    return(&errSbr("not def optSegLoc!"))          if (! defined $optSegLoc);
    return(&errSbr("not def fhSbrErr!"))           if (! defined $fhSbrErr);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# ------------------------------
				# adjust input
    $modeSegLoc="glob"          if ($modeSegLoc =~ /^glob/i);
    $modeSegLoc="norm"          if ($modeSegLoc =~ /^norm/i);
    $modeSegLoc=$modeSegDef     if (! $modeSegLoc);
    $winSegLoc= $winSegGlobDef  if (! $winSegLoc   && $modeSegLoc eq "glob"); 
    $locutSegLoc=$locutGlobDef  if (! $locutSegLoc && $modeSegLoc eq "glob"); 
    $hicutSegLoc=$hicutGlobDef  if (! $hicutSegLoc && $modeSegLoc eq "glob"); 

    $winSegLoc= $winSegNormDef  if (! $winSegLoc   && $modeSegLoc eq "norm"); 
    $locutSegLoc=$locutNormDef  if (! $locutSegLoc && $modeSegLoc eq "norm"); 
    $hicutSegLoc=$hicutNormDef  if (! $hicutSegLoc && $modeSegLoc eq "norm"); 

    $optSegLoc= $optSegDef      if (! $optSegLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr   || ! $fhSbrErr);
    $cmdSys="";			# avoid warnings

    $exeSegLoc=$exeSegDef       if (! $exeSegLoc);
    return(&errSbr("miss exe '$exeSegLoc'!"))     if (! -e $exeSegLoc && ! -l $exeSegLoc);
    return(&errSbr("not executable:$exeSegLoc!")) if (! -x $exeSegLoc);

				# ------------------------------
				# build up input
    $cmd= $exeSegLoc." ".$fileInLoc;
    if (! $cmdSegLoc) {
	@optSegLoc=split(/,/,$optSegLoc);
	$cmd.=" ".$winSegLoc;
	$cmd.=" ".$locutSegLoc      if ($locutSegLoc);
	$cmd.=" ".$hicutSegLoc      if ($hicutSegLoc);
	foreach $tmp (@optSegLoc) {
	    $cmd.=" -".$tmp; } }
    else {
	$cmd.=" ".$cmdSegLoc;}
    
    $cmd.=" >> $fileOutLoc"     if ($fileOutLoc); # otherwise to STDOUT !

                                # security erase
    unlink($fileOutLoc)         if (-e $fileOutLoc);

				# ------------------------------
				# run SEG
    eval "\$cmdSys=\"$cmd\"";

    ($Lok,$msg)=
	&sysRunProg($cmdSys,0,$fhSbrErr);
    return(&errSbrMsg("failed to run SEG on ($fileInLoc)",$msg)) 
	if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));
    return(1,"ok $sbrName");
}				# end of segRun

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/rost/perl/ctime.pl",           # HARD_CODED
	  "/home/rost/pub/perl/ctime.pl",       # HARD_CODED
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
# library collected (end)   lll
#==============================================================================

#===============================================================================
sub iniSeg {
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniSeg                      initialises running SEG 
#       in:                     (in=@ARGV as for any script
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."ini";     
				# ------------------------------
    foreach $arg(@ARGV){	# highest priority ARCH
	if ($arg=~/ARCH=(.*)$/){
	    $ARCH=$ENV{'ARCH'}=$1; 
	    last;}}
    $ARCH=$ARCH || $ENV{'ARCH'} || "SGI32";
				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();

				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();		# specific local stuff

    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,%tmp);   
                                return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 
				# ------------------------------
				# read command line input

    @argUnk=			# standard command line handler
	&brIniGetArg;
    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
        if    ($arg=~/^list$/i)               { $par{"isList"}=1;}

	elsif ($arg=~/^mode=(.*)$/)           { $par{"modeSeg"}=$1;}
	elsif ($arg=~/^win=(.*)$/)            { $par{"winSeg"}=$1;}
	elsif ($arg=~/^locut=(.*)$/)          { $par{"locutSeg"}=$1;}
	elsif ($arg=~/^hicut=(.*)$/)          { $par{"hicutSeg"}=$1;}
	elsif ($arg=~/^cmd=(.*)$/)            { $par{"cmdSeg"}=$1;}
	elsif ($arg=~/^opt=(.*)$/)            { $par{"optSeg"}=$1;}
	elsif ($arg=~/^exe=(.*)$/)            { $par{"exeSeg"}=$1;}

	elsif ($arg=~/^screen$/)              { $par{"nofileSeg"}=1;}

	elsif ($arg=~/^noseg$/i)              { $par{"wrtSeg"}=0;}
	elsif ($arg=~/^(glob|norm)$/i)        { $par{"modeSeg"}=$1;}

	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}="nice -".$1;}
	elsif ($arg eq "nonice")              { $par{"optNice"}=" ";}
	elsif ($arg eq "debug")               { $par{"debug"}=1;}
	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verb2"}=1             if ($par{"debug"});
    $par{"verbose"}=1           if ($par{"verb2"});
	
    $Lverb= $par{"verbose"}     if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=$par{"verb2"}       if (defined $par{"verb2"}   && $par{"verb2"});

				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
	$par{"$kwd"}.="/"       if ($par{"$kwd"} !~ /\/$/);}

                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);

				# ------------------------------
				# (1) input file: read lists
				# ------------------------------
    $#fileTmp=0;
    foreach $fileIn (@fileIn){
	if (! -e $fileIn) { print "*** WARN $scrName: fileIn=$fileIn missing!\n";
			    next; }
				# ------------------------------
				# (1) CASE: is list of FASTA
				# ------------------------------
	if ($fileIn =~ /\.list/ || $par{"isList"}) {
	    &open_file("$fhin","$fileIn") ||
		return(&errSbr("failed to open fileIn=$fileIn\n"));
	    while (<$fhin>) {
		$_=~s/\s|\n//g;
		push(@fileIn,$_) if (-e $_);}close($fhin);
	    next; }
				# ------------------------------
				# (2) CASE: is FASTAmul -> many
				# ------------------------------
	if (&isFastaMul($fileIn)) {
	    print "--- $SBR: assumed fileIn=$fileIn, is fastaMul\n";
	    ($Lok,$id,$seq)=
		&fastaRdMul($fileIn);
	    return(&errSbrMsg("failed reading FASTAmul format ($fileIn)",$msg,$SBR)) if (! $Lok);
	    $id=~s/^\n*|\n*$//g;   $seq=~s/^\n*|\n*$//g;
	    @id=split(/\n/,$id);   @seq=split(/\n/,$seq);
	    return(&errSbr("from fastRdMul ".$#id." ids read, but ".$#seq." sequences!"))
		if ($#id !~ $#seq);
	    foreach $it (1..$#id){
		$id=$id[$it]; $id=~s/\s.*$//g;
		$file=$par{"dirWork"}.$id.$par{"extFasta"};
                                # write file
		($Lok,$msg)=
		    &fastaWrt($file,$id,$seq[$it]);
		return(&errSbrMsg("failed writing $file (fasta)",$msg)) if (! $Lok || ! -e $file); 
		push(@fileRm, $file) if (! $par{"debug"}); # remove at end!
		push(@fileTmp,$file); }
	    next; }
				# ------------------------------
				# (3) CASE: is simple FASTA
				# ------------------------------
	if (&isFasta($fileIn)) {
	    push(@fileTmp,$fileIn);
	    next; }
				# ------------------------------
				# (4) unknown format!!!
				# ------------------------------
	return(&errSbr("input files must be in FASTA, FASTAmul, or a list of either!!\n".
		       "seems not true for $fileIn",$SBR)); 
    }
    @fileIn= @fileTmp;
    $#fileTmp=0;		# slim-is-in
				# ------------------------------
				# output file name
				# ------------------------------
    $fileOut=$par{"fileOut"};
    if (! defined $fileOut || ! $fileOut || $fileOut eq "unk" || length($fileOut) < 1) {
	$par{"fileOutSyn"}=$par{"dirOut"}."syn-seg".".rdb"; }
    else {
	$par{"fileOutSyn"}="syn-seg-".$fileOut; }

				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet;              return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);

				# ------------------------------
				# check errors
    $exclude="exe,fileDefaults"; # to exclude from error check
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n".$msg)) if (! $Lok);  


                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0) {
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($Lverb2);
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$fhTrace="STDOUT";}
    $#fileRm=0;
				# ------------------------------
				# write settings
				# ------------------------------
    $exclude="kwd,dir*,ext*";	# keyword not to write
    $fhloc="STDOUT";
    $fhloc=$fhTrace             if (! $par{"debug"});
    ($Lok,$msg)=
	&brIniWrt($exclude,$fhloc);
    return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR))  if (! $Lok); 

				# ------------------------------
				# digesting SEG arguments
				# ------------------------------

				# call sbr segRun with:
                                #    $fileInLoc : input sequence (FASTA format!)
                                #    $fileOutLoc: output of SEG
                                #   : = 0 -> STDOUT!
                                #    $exeSegLoc : executable for SEG
                                #    $modeSegLoc: 'norm|glob'
                                #                 norm  -> win = 12
                                #                 glob-> win = 30
                                #    $winSegLoc : window (default = 12, or see above)
                                #    $locutSegLoc
                                #    $hicutSegloc
                                #    $optSegLoc : any of the following as a comma separated list:
                                #                 x,c,m,l,h,a,n,o,t,p,q
                                #                 default: -x 
                                #    $fhSbrErr  : file handle for error messages

    if ($par{"cmdSeg"}) {
	@argSeg=(0,0,0,0,0); }
    else {
				# 3 numbers = window_size low_filter high_filter
	$par{"winSeg"}=  $par{"winSegGlob"}   if (! $par{"winSeg"}   && $par{"modeSeg"} eq "glob");
	$par{"locutSeg"}=$par{"locutSegGlob"} if (! $par{"locutSeg"} && $par{"modeSeg"} eq "glob");
	$par{"locutSeg"}=$par{"locutSegGlob"} if (! $par{"locutSeg"} && $par{"modeSeg"} eq "glob");

	$par{"winSeg"}=  $par{"winSegNorm"}   if (! $par{"winSeg"}   && $par{"modeSeg"} eq "norm");
	$par{"locutSeg"}=$par{"locutSegNorm"} if (! $par{"locutSeg"} && $par{"modeSeg"} eq "norm");
	$par{"locutSeg"}=$par{"locutSegNorm"} if (! $par{"locutSeg"} && $par{"modeSeg"} eq "norm");

	@argSeg=($par{"modeSeg"},
		 $par{"winSeg"},$par{"locutSeg"},$par{"hicutSeg"},$par{"optSeg"}); }

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $SBR");
}				# end of iniSeg

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      initialise defaults
#-------------------------------------------------------------------------------
                                # d.d
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/";
    $par{"dirBin"}=             "/home/rost/pub/molbio/bin/"; # FORTRAN binaries of programs needed

    $par{"dirPerl"}=            $par{"dirHome"}. "perl/" # perl libraries
        if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $par{"dirPerl"}. "scr/"; # perl scripts needed

    $par{"dirOut"}=            ""; # directory for output files
    $par{"dirWork"}=           ""; # working directory
#    $par{""}=                   "";
                                # further on work
				# --------------------
				# files
    $par{"extOut"}=             ".seg";
    $par{"extFasta"}=           ".f";

    $par{"fileOutTrace"}=       "SEG-TRACE"."jobid".".tmp";   # tracing some warnings and errors
    $par{"fileOutTrace"}=       "SEG-TRACE".".tmp";   # tracing some warnings and errors

				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";

                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=$Lverb=     1; # blabla on screen
    $par{"verb2"}=$Lverb2=      0; # more verbose blabla

    $par{"optNice"}=            "nice -15";

				# --------------------
				# parameters
    $par{"modeSeg"}=            "norm";	# implies to set the window size to 12
    $par{"modeSeg"}=            "glob";	# implies to set the window size to 30
    $par{"modeSeg"}=            0;	# implies to set the window size to 30

    $par{"winSegGlob"}=        30;      # window size, 0 for mode 'glob'
    $par{"locutSegGlob"}=       3.5;
    $par{"hicutSegGlob"}=       3.75;

    $par{"winSegNorm"}=        12;      # window size, 0 for mode 'norm'
    $par{"locutSegNorm"}=       2.2;
    $par{"hicutSegNorm"}=       2.5;

    $par{"winSeg"}=             0;      # window size, 0 for default (see mode)
    $par{"locutSeg"}=           0;
    $par{"hicutSeg"}=           0;

    $par{"optSeg"}=             "x";    # pass the output print options as comma separated list
				        #    NO '-' needed, see below
    $par{"cmdSeg"}=             0;      # pass the entire command line just as obligatory to run SEG
				        #    on the shell.  NOTE:
				        #    1st number = window size (integer)
				        #    2nd number = low complexity filter
				        #    3rd number = high complexity filter
				        #    options: -x -c -m -l -h -a -n -o -t -p -q
				        #    see lib-br:segRun for explanations!
    $par{"wrtSeg"}=             1;      # =0 -> will deleted all output files from SEG (keep synopsis, only!)
    $par{"nofileSeg"}=          0;      # if 1, output from SEG to STDOUT

				# --------------------
				# executables
    $par{"ARCH"}=               $ARCH;

    $par{"exeSeg"}=             $par{"dirBin"}."seg".".".$ARCH; # executable of SEG

    $SEP="\t";

    $txtQuotePaper= "";
    $txtQuotePaper.="# ------------------------------------------------------------\n";
    $txtQuotePaper.="# Please quote: \n";
    $txtQuotePaper.="#    John C Wootton \& Scott Federhen 1996:  Analysis of com-\n";
    $txtQuotePaper.="#       positionally biased regions in sequence databases.\n";
    $txtQuotePaper.="#       Methods in Enzymology, Vol. 266, pp. 554-571\n";
    $txtQuotePaper.="#       \n";
    $txtQuotePaper.="# ------------------------------------------------------------\n";

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
    $tmp=$0; $tmp=~s/^\.\/// if ($tmp=~/^\.\//);
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 
	  'scrGoal', $scrGoal, 'scrNarg',$scrNarg,
	  'scrHelpTxt', $scrHelpTxt);
				# missing stuff
    $tmp=0;
    $tmp=$0                     if (! defined $tmp || ! $tmp); 

    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help
    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "";
    $tmp{"special"}.=        "list,verb,verb2,verbDbg,";
    $tmp{"special"}.=        "mode,glob,norm,win,locut,hicut,cmd,opt,exe,noseg,screen,";

    $tmp{"mode"}=            "=x     mode of running 'norm|glob'";
    $tmp{"glob"}=            "       mode of running =glob";
    $tmp{"norm"}=            "       mode of running =norm";

    $tmp{"win"}=             "=N     window size (def=12 for norm, 30 for glob)";
    $tmp{"locut"}=           "=N     lower  filter (2.2 def norm, 3.5  def glob)";
    $tmp{"hicut"}=           "=N     higher filter (2.5 def norm, 3.75 def glob)";
    $tmp{"cmd"}=             "=txt   full line as passed to SEG on shell!";
    $tmp{"opt"}=             "='x,p' output options, e.g.: 'x,p,..'";
    $tmp{"exe"}=             "=x     full path of SEG executable";
    $tmp{"noseg"}=           "OR wrtSeg=0, will deleted all output files from SEG (keep synopsis, only!)";
    $tmp{"screen"}=          "       writes SEG output to STDOUT";
#    $tmp{""}=            "";

    $tmp{"list"}=            "OR isList=1,     i.e. ALL (!) input file are lists of FASTA files";

    $tmp{"verb"}=            "OR verbose=1,    i.e. verbose output";
    $tmp{"verb2"}=           "OR verb2=1,      i.e. very verbose output";
    $tmp{"verbDbg"}=         "OR verbDbg=1,    detailed debug info (not automatic)";

    $tmp{"special"}=~s/,*$//g;

#    $tmp{"scrAddHelp"}.=     "help saf-syn  : specification of SAF format\n";

#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelp

#===============================================================================
sub cleanUp {
    local($SBR,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    if ($scrName){$tmp="$scrName".":";}else{$tmp="";} $SBR="$tmp"."cleanUp";
    if ($#fileRm>0){		# remove intermediate files
	foreach $file (@fileRm){
	    next if (! -e $file);
	    print "--- $SBR unlink '",$file,"'\n" if ($Lverb2);
	    unlink($file);}}
    foreach $kwd ("fileOutTrace","fileOutScreen"){
        next if (! defined $par{"$kwd"} || ! -e $par{"$kwd"});
        print "--- $SBR unlink '",$par{"$kwd"},"'\n" if ($Lverb2);
        unlink($par{"$kwd"});}
}				# end of cleanUp

