#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "reads PHDhtm RDB file (+ hssp) and writes table (rdb + html)";
$scrIn=      "list_with_phdhtm_rdb_files org=organism nprot=number_of_proteins_in_entire_genome";
$scrNarg=    3;                  # minimal number of input arguments
$scrHelpTxt= " \n";
$scrHelpTxt.="NOTE: for WWW you still have to do 'phdhtm_seqoffrdb.pl' \n";
$scrHelpTxt.="      ... and hack-www-reformat.pl ...\n";
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
#	Copyright				        	1997	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	Jinfeng Liu Rost	liu@dodo.cpmc.columbia.edu		       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	xxx,    	1997	       #
#				version 0.2   	Apr,    	1998	       #
#				version 0.21   	Jul,    	1999	       #
#------------------------------------------------------------------------------#
#
$[ =1 ;				# sets array count to start at 1, not at 0
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();			&errScrMsg("after ini",$msg,$scrName) if (! $Lok); 

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
				# setting 0
				# ------------------------------

$fileIn=$fileIn[1];
				# ------------------------------
if (&isRdbList($fileIn)){	# read file list
    $#fileIn=0;
    open($fhin, $fileIn) || &errScrMsg("failed opening fileIn=$fileIn!");

    while (<$fhin>) {
	$_=~s/\s//g;
	push(@fileIn,$_)        if (-e $_);}
    close($fhin);}

				# ------------------------------
				# (1) read files
				# ------------------------------
$ctProt=0;$maxNhtm=$maxNali=0;
foreach $fileIn(@fileIn){
    $id=$fileIn;$id=~s/^.*\///g;$id=~s/$par{"extRdb"}//g;
    print "--- reading $id ($fileIn)\n";
    $Lok=&open_file("$fhin", "$fileIn");
    next if (! $Lok);
    ++$ctProt;
				# --------------------
				# read file (all in/out global)
    &rdRdbHtmHere();
				# output:
				# res{"x","ct"} x=len1,nhtm,riMod,riTop,topD,top,htm,seq,htmCN
				#            htmCN=1-5,10-200, gives the position of the HTMs
    close($fhin);
				# --------------------
				# search HSSP file
    $hssp=    $par{"dirHssp"}.$id.$par{"extHssp"};
    $hsspSelf=$par{"dirHsspSelf"}.$id.$par{"extHsspSelf"};
    if    (-e $hssp)    {
	print "--- corresponding HSSP $hssp\n";
	$tmp=`grep "^NALIGN" $hssp`;
	$nali=$tmp;$nali=~s/^NALIGN\s+(\d+)\D*.*$/$1/g;}
    elsif (-e $hsspSelf){
	print "--- corresponding HSSPself $hsspSelf\n";
	$tmp=`grep "^NALIGN" $hsspSelf`;
	$nali=$tmp;$nali=~s/^NALIGN\s+(\d+)\D*.*$/$1/g;}
    else                {
	print "--- no HSSP for $id ($hssp)\n";
	$nali="?";}
    $res{"nali",$ctProt}=$nali;
    $res{"id",$ctProt}=$id;
    $maxNali=$nali if ($nali>$maxNali);
    $maxNhtm=$res{"nhtm",$ctProt} if ($res{"nhtm",$ctProt}>$maxNhtm);
}

$res{"NROWS"}=$ctProt;
				# ------------------------------
$#order=$#ok=0;$nhtm=$maxNhtm;	# (2) sort the results
undef %stat;
while ($nhtm>0){
    $nali=$maxNali;		# top = in
    $stat{"$nhtm","in"}=$stat{"$nhtm","out"}=0;
    while ($nali>0){
	foreach $it(1..$res{"NROWS"}){
	    &errScrMsg("id=".$res{"id",$it}."\n".
		       "xx ERROR it=$it, nhtm not defined\n") if (! defined $nhtm);
	    &errScrMsg("id=".$res{"id",$it}."\n".
		       "xx ERROR it=$it, nali not defined\n") if (! defined $nali);
	    &errScrMsg("id=".$res{"id",$it}."\n".
		       "xx ERROR it=$it, res{top} not defined\n")  if (! defined $res{"top",$it});
	    &errScrMsg("id=".$res{"id",$it}."\n".
		       "xx ERROR it=$it, res{nhtm} not defined\n") if (! defined $res{"nhtm",$it});
	    &errScrMsg("id=".$res{"id",$it}."\n".
		       "xx ERROR it=$it, res{nali} not defined\n") if (! defined $res{"nali",$it});
	    if (defined $res{"nhtm",$it} && ($res{"top",$it}=~/in/i) &&
		($res{"nhtm",$it}==$nhtm) && ($res{"nali",$it}==$nali)){ 
		++$stat{"$nhtm","in"};
		push(@order,$it);
		$ok[$it]=1;}}
	--$nali;}
    $nali=$maxNali;		# top = not in
    while ($nali>0){
	foreach $it(1..$res{"NROWS"}){
	    if (($res{"nhtm",$it}==$nhtm) && ($res{"nali",$it}==$nali) && 
		($res{"top",$it}!~/in/i)){
		++$stat{"$nhtm","out"};
		push(@order,$it);
		$ok[$it]=1;}}
	--$nali;}
    --$nhtm;}
foreach $it(1..$res{"NROWS"}){
    next if (defined $ok[$it]);
    print "*** missing it=$it, nali=",$res{"nali",$it},", nhtm=",$res{"nhtm",$it},",\n";}

				# ------------------------------
				# write output (RDB)
$fileOutRdb=$par{"fileOut"};$fileOutRdb=~s/\..*$/\.rdb/;
$LokOpen=&open_file("$fhout",">$fileOutRdb"); 
foreach $fh ("STDOUT",$fhout){
    if ($fh ne "STDOUT" && ! $LokOpen) {
	print "*** WARNING no output file ($fileOutRdb) written (failed to open it!)!\n";
	next;}
    &wrtRdbHere($fh);}
close($fhout)                   if ($LokOpen);
push(@fileOut,$fileOutRdb)      if (-e $fileOutRdb);

				# ------------------------------
				# write output (HTML)
$fileOutHtml=$par{"fileOut"};$fileOutHtml=~s/\..*$/\.html/;
$Llink=1;
($Lok,$msg)=
    &wrtHtml($fileOutRdb,$fileOutHtml,$fhout,$Llink);
print "*** ERROR (STRONG) $scrName: problem with HTML:\n",$msg,"\n"
    if (! $Lok);
push(@fileOut,$fileOutHtml)     if (-e $fileOutHtml);

				# ------------------------------
				# write output statistics (RDB)
$fileOutStat=$fileOutRdb;$fileOutStat=~s/^Out/Stat/;
if ($fileOutStat eq $fileOutRdb || $fileOutStat !~/Stat/){
    $fileOutStat="Stat-".$fileOutStat;}
$LokOpen=&open_file("$fhout",">$fileOutStat"); 
$add=$fileOutStat;$add=~s/^.*\///g;$add=~s/Stat-//g;$add=~s/\..*$//g;$add=~s/[\-]|htm|rdb|0//g;
#$add=~tr/[a-z]/[A-Z]/;
$add=~s/phdh/PHDh/i;
foreach $fh ("STDOUT",$fhout){
    if ($fh ne "STDOUT" && ! $LokOpen) {
	print "*** WARNING no output file ($fileOutStat) written (failed to open it!)!\n";
	next;}
    &wrtStat($fh,$add);}
close($fhout)                   if ($LokOpen);
push(@fileOut,$fileOutStat)     if (-e $fileOutStat);

				# ------------------------------
				# move output files
if (! defined $par{"dirOut"} || $par{"dirOut"}=~/^(title|unk)$/ ||  
    length($par{"dirOut"})<1) {
    $par{"dirOut"}=$par{"organism"};
    $par{"dirOut"}=~s/\s//g;
    &sysMkdir($par{"dirOut"}) if (! -d $par{"dirOut"});
    $par{"dirOut"}.="/";}

foreach $fileOut (@fileOut) {
    next if (! -e $fileOut);
    next if ($fileOut=~/$par{"titleTmp"}|$par{"fileOutTrace"}/);
    if ($fileOut !~/\//){
	$tmp=$par{"dirOut"}.$fileOut;
	$cmd="\\mv $fileOut $tmp";
	system("$cmd");         print "--- system $cmd\n" if ($par{"dbg"});
    }}


if ($par{"verbose"}) {
    print "--- output in dir=",$par{"dirOut"},"\n";
    $ct=0;
    foreach $fileOut (@fileOut) {
	next if (! -e $par{"dirOut"}.$fileOut);
	next if ($fileOut=~/$par{"titleTmp"}|$par{"fileOutTrace"}/);
	if ($ct==10) { print "\n","--- \t ";
		       $ct=0; }
	if ($fileOut !~ /\d/) {
	    if ($ct) { $ct=0;
		       print "\n"; }
	    print "--- \t $fileOut\n";}
	else {
	    ++$ct;		 
	    print "--- \t "     if ($ct==1);
	    print "$fileOut,"; }
    } print "\n" if ($ct);
    print "--- trace of job in file=",$par{"fileOutTrace"},"\n" 
	if (-e $par{"fileOutTrace"});}

print STDERR 
    "*** DO the following to get the links right:\n",
    "(1) move the RDB output file \n",
    "\t",$fileOutRdb," to :\n",
    "\t",$par{"dirFtp_genomesOrg"}.$par{"dirOut"}.$fileOutRdb,"\n",
    "(2) move the content of the directory ",
    "\t",$par{"dirOut"}," to:\n",
    "\t",$par{"dirWeb_genomesOrg"}.$par{"dirOut"}."\n";
exit;





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
				# (2a) is special help
	if    (defined $tmp{$kwdHelp}) {
	    $#kwdLoc=0;
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            printf "--- %-20s   %-s\n","keyword","explanation";
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
	    printf "--- %-20s   %-s\n",$kwdHelp,$tmp{$kwdHelp};
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            print "--- \n";$Lerr=0;}
                                # (2b) is there a 'help option file' ?
        elsif (defined $par{"fileHelpOpt"} && -e $par{"fileHelpOpt"} && 
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
                                # (2c) is there a default file?
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
				# (2d) else: read itself
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
        if ($#kwdLoc>0){        # (3) write the stuff
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            printf "--- %-20s   %-s\n","keyword","explanation";
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            foreach $it(1..$#kwdLoc){
                $tmp=" "; $tmp=$expLoc[$it] if (defined $expLoc[$it]);
                printf "--- %-20s   %-s\n",$kwdLoc[$it],$tmp;}
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            print "--- \n";$Lerr=0;}

				# (4) special help?
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

#===============================================================================
sub bynumberLoc { 
#-------------------------------------------------------------------------------
#   bynumberLoc                 function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumberLoc

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
sub isRdb {
    local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    return (0) if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB";
    open("$fh", $fileInLoc) || return(0);
    $tmp=<$fh>;
    close($fh);
    return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
    return 0; 
}				# end of isRdb

#==============================================================================
sub isRdbList {local ($fileInLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isRdbList                   checks whether or not file is list of Rdb files
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	       return(0) if (! -e $fileInLoc); $fhinLoc="FHIN_RDBLIST";$Lok=0;
	       $Lok=&open_file("$fhinLoc","$fileInLoc");
	       if (! $Lok){ print "*** ERROR in lib-br.pl:isRdbList, opening '$fileInLoc'\n";
			    return(0);}
	       while (<$fhinLoc>){ 
                   $_=~s/\s|\n//g;
                   if ($_=~/^\#/ || ! -e $_){close($fhinLoc);
                                             return(0);}
                   $fileTmp=$_;
                   if (&isRdb($fileTmp)&&(-e $fileTmp)){
                       close($fhinLoc);
                       return(1);}
                   last;}close($fhinLoc);
	       return(0); }	# end of isRdbList


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
    $date=$Date; $date=~s/(199\d|200\d)\s*.*$/$1/g;
    return($Date,$date);
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
# library collected (end)   lll
#==============================================================================


1;


#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."ini";     
				# ------------------------------
#     foreach $arg(@ARGV){	# highest priority ARCH
# 	if ($arg=~/ARCH=(.*)$/){
# 	    $ARCH=$ENV{'ARCH'}=$1; 
# 	    last;}}
#     $ARCH=$ARCH || $ENV{'ARCH'} || "SGI32";
				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
				# date and time
#    $timeBeg=     time;	    
    ($Date,$date)=&sysDate();

				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,
		       %tmp);   return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 

				# --------------------------------------------------
				# read command line input
				# --------------------------------------------------
    @argUnk=			# standard command line handler
	&brIniGetArg();

    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
        if    ($arg=~/^list$/i)               { $par{"isList"}=   1;}
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}=  "nice -".$1;}
	elsif ($arg eq "nonice")              { $par{"optNice"}=  " ";}
	elsif ($arg =~ /^de?bu?g$/)           { $par{"debug"}=    1;}

	elsif ($arg=~/^nprot=(.*)$/)          { $par{"nprot"}=    $1;}
	elsif ($arg=~/^org=(.*)$/)            { $par{"organism"}= $1;}

	elsif (-e $arg)                       { push(@fileIn,$arg);}

	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verb2"}=1             if ($par{"debug"});
    $par{"verbose"}=1           if ($par{"verb2"});
	
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

    if (defined $par{"isList"} && $par{"isList"} eq "1"){ # input is file list
        &open_file("$fhin","$fileIn[1]") ||
            return(&errSbr("failed to open fileIn=$fileIn\n"));
        $#fileIn=0 if ($#fileIn==1);
        while (<$fhin>) {$_=~s/\s|\n//g;
                         push(@fileIn,$_) if (-e $_);}close($fhin);}

				# ------------------------------
				# final settings

				# output file name
     $fileOut=$par{"fileOut"};
     if (! defined $fileOut  || $fileOut =~/^(title|unk)$/ ||  length($fileOut) < 1){
 	$titleOut=$par{"organism"} if (defined $par{"organism"});
 	$titleOut=$par{"title"}    if (defined $par{"title"} && 
 				       length($par{"title"})>1 && $fileOut =~/^(title)$/);
				# name output file according to input file name
	$titleAdd=$fileIn[1]; $titleAdd=~s/^.*(htm\d*)\D.*$/$1/i; $titleAdd=~tr/[A-Z]/[a-z]/;
 	$fileOut=$par{"dirOut"}.$titleOut."_".$titleAdd.$par{"extOut"};}
     $fileOut="Out-"."rdb2table".".dat"
 	if (! defined $fileOut  || $fileOut =~/^(title|unk)$/ ||  length($fileOut) < 1);
     $par{"fileOut"}=$fileOut;
				# name output file according to input file name
#    $tmp=$fileIn[1]; $tmp=~s/^.*(htm\d*)\D.*$/$1/i; $tmp=~tr/[A-Z]/[a-z]/;
#    $fileOut=$par{"fileOut"}=$tmp.".tmp";
    $#fileOut=0;

    $Lok=			# standard settings
	&brIniSet();            return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);

				# correct settings for executables: add directories
    if (0){
	foreach $kwd (keys %par){
	    next if ($kwd !~/^exe/);
	    next if (-e $par{"$kwd"} || -l $par{"$kwd"});
	}
    }

				# ------------------------------
				# number of proteins obligatory!
    if (! defined $par{"nprot"}){
	print "*** ERROR give number of all proteins as 'nprot=xx'\n";
	die;}
				# ------------------------------
				# check errors
    $exclude="exe,fileDefaults"; # to exclude from error check
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n",$msg)) if (! $Lok);  


                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0) {
	$par{"fileOutTrace"}=~s/$par{"dirOut"}/$par{"dirWork"}/g;
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($par{"verb2"});
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$fhTrace="STDOUT";}
    $#kwdRm=0;
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
    undef %tmp;			# clean memory

    return(1,"ok $SBR");
}				# end of ini

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      initialise defaults
#-------------------------------------------------------------------------------
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/";

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
#    $par{""}=                   "";
				# local
    $par{"dirHssp"}=            "hsspRaw/";
    $par{"dirHssp"}=            "hssp4phd/";
    $par{"dirHssp"}=            "/data/genome/org/arcfu/hssp/";
    $par{"dirHsspSelf"}=        "hsspSelf/";

                                # further on work
				# --------------------
				# files
    $par{"title"}=              "unk";                           # output files may be called 'Pre-title.ext'
    $par{"titleTmp"}=           "TMP_rdb2table_";                # title for temporary files

    $par{"fileOut"}=            "unk";
    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE"."jobid".".tmp";   # tracing some warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN-"."jobid".".tmp"; # dumb out from system calls
    $par{"preHtm"}=             "htm"; # final data files called 'htm'.number_of_htm.'.html'

#    $par{""}=                   "";
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".tmp";

    $par{"extRdb"}=             ".rdbHtm";
    $par{"extHssp"}=            ".hssp";
    $par{"extHsspSelf"}=        ".hsspSelf";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";

				# --------------------
				# CUBIC www stuff
				# central cubic web pages
    $par{"dirWeb_cubic"}=       "/home/cubic/public_html/";
				# material used (templates of WWW pages)
    $par{"dirWeb_MAT"}=         "/home/cubic/public_html/MAT/";
				# HTML pages with results
    $par{"dirWeb_genomes"}=     "/home/cubic/public_html/genomes/";
    $par{"dirWeb_genomesOrg"}=  "/home/cubic/public_html/genomes/org/";

				# CUBIC central relative to where this will end:
				#    /home/cubic/public_html/genomes/org/ABBREVIATION_OF_ORGANISM/this
    $par{"reldirWeb_cubic"}=    "../../../";
    $par{"reldirWeb_genomes"}=  "../../";
    $par{"reldirWeb_genomesOrg"}=  "../";


    $par{"dirFtp_genomes"}=        "/home/ftp/pub/cubic/data/genomes/";
    $par{"dirFtp_genomesOrg"}=     "/home/ftp/pub/cubic/data/genomes/org/";
    $par{"reldirFtp_genomesOrg"}=  "pub/cubic/data/genomes/org/";

    $par{"fileTemplate_"."head"}=    $par{"dirWeb_MAT"}."template_head.html";
    $par{"fileTemplate_"."links"}=   $par{"dirWeb_MAT"}."template_links.html";
    $par{"fileTemplate_"."section"}= $par{"dirWeb_MAT"}."template_section.html";
    $par{"fileTemplate_"."contact"}= $par{"dirWeb_MAT"}."template_contact.html";
    $par{"fileTemplate_"."navi_top"}=$par{"dirWeb_MAT"}."template_navigate_top.html";
    $par{"fileTemplate_"."navi_bot"}=$par{"dirWeb_MAT"}."template_navigate_bottom.html";

    $par{"fileWeb_"."cubic"}=        $par{"dirWeb_cubic"}."cubic.html";
    $par{"fileWeb_"."genomes"}=      $par{"dirWeb_cubic"}."cubic.html";
    $par{"fileWeb_"."explain"}=      $par{"dirWeb_cubic"}."doc/explain_gene.html";
    $par{"relfileWeb_"."explain"}=   $par{"reldirWeb_cubic"}.   "doc/explain_gene.html";
    $par{"fileWeb_"."query"}=        $par{"dirWeb_genomes"}.    "query_gene.html";
    $par{"relfileWeb_"."query"}=     $par{"reldirWeb_genomes"}. "query_gene.html";
    

    $par{"cubicAdminEmail"}=    "cubic\@dodo.cpmc.columbia.edu";
    $par{"cubicFtpServer"}=     "dodo.cpmc.columbia.edu";


                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=            1; # blabla on screen
    $par{"verb2"}=              0; # more verbose blabla

    $par{"optNice"}=            "nice -15";
#    $par{""}=                   "";
				# --------------------
				# parameters

    $par{"organism"}=           "ecoli"; # for title, e.g. 'org=Homo sapiens', or org=human
#    $par{"organism"}=           "Organism";
    $par{"nperLine"}=         100; # number of residues per line (HTML sequence)
    $par{"minLen"}=            20; # minimal number of residues to consider 
				# will split the display of the final data into the following
				# categories
    $par{"numSplit"}=           "10,7,4,3,2,1";
    $par{"numHtm_perLine"}=    10; # number of HTMs in one HTML row
    $par{"seqTake"}=           20; # take only first 30 residues from sequence

				# --------------------
				# executables
    $par{"exe"}=                "";
#    $par{""}=                   "";


				# arrays
				# a.a
#    @kwdDes=("extRdb","extHssp","extHsspSelf","dirHssp","dirHsspSelf","organism","nperLine",
#	     "minLen");
				# 
    @kwdFin=("id","nhtm","top","nali","len1","riTop","riMod","topD","htmCN","seq");
	 
    %formFin=('nhtm',"%5d",'len1',"%5d",'riTop',"%1d",'riMod',"%1d",'topD',"%6.2f",
	      'id',"%-s",'nali',"%-s",'top',"%-s",'htmCN',"%-s",'seq',"%-s");
    %known=(
	    'arcfu',  "Archaeoglobus fulgidus",
	    'helpy',  "Helicobacter pylori",
	    'borbu',  "Borrelia burgdorferi",
	    'bacsu',  "Bacillus subtilis",
	    'caeel',  "C. elegans",
	    'syny1',  "Synechocystis sp. (cyanobacterium)",
	    'ecoli',  "Escherichia coli",
	    'haein',  "Haemophilus influenzae",
	    'helpy',  "Helicobacter pylori",
	    'human',  "Homo sapiens (temporary from SWISS-PROT)",
	    'mycge',  "Mycoplasma genitalium",
	    'metja',  "Methanococcus jannaschii",
	    'mycpn',  "Mycoplasma pneumoniae",
	    'mettm',  "Methanobacterium thermoautotrophicum ",
	    'yeast',  "Saccharomyces cerevisiae",
	    '', "",
	    );
    $known=join('|',sort keys(%known));
    $known=~s/^\|//g;
    $par{"known"}=$known;
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
    $tmp{"special"}.=        "organism,minLen,nprot,nperLine,known,";
    $tmp{"special"}.=        ",";
        
#    $tmp{""}=         "<*|=1> ->    ";
    $tmp{"list"}=            "<*|isList=1>     -> input file is list of files";

    $tmp{"verbose"}=         "<*|verbose=1>    -> verbose output";
    $tmp{"verb2"}=           "<*|verb2=1>      -> very verbose output";
    $tmp{"verbDbg"}=         "<*|verbDbg=1>    -> detailed debug info (not automatic)";

    $tmp="---                      ";
    $tmp{"organism"}=        "'org=Homo sapiens'-> title used\n";
    $tmp{"organism"}.=  $tmp."    NOTE: use full latin name except for all those which\n";
    $tmp{"organism"}.=  $tmp."          are known already (list by typing '$0 def known')\n";
    $tmp{"nprot"}=           "                  -> number of proteins in ENTIRE genome\n";
    $tmp{"nprot"}.=     $tmp."    NOTE: MUST BE DEFINED for cumulative values!!!!\n";
    $tmp{"nperLine"}=        "                  -> for HTML output of seq, =0 => no sequence\n";
    $tmp{"minLen"}=          "                  -> minimal length to take prot\n";
    $tmp{"known"}=           "                     the following abbreviations are 'known':\n";
    foreach $kwd (split(/\|/,$known)) {
	$tmp{"known"}.=     $tmp."    $kwd = ".$known{$kwd}."\n";}

#    $tmp{"zz"}=              "expl             -> action\n";
#    $tmp{"zz"}.=        $tmp."    expl continue\n";

     $tmp{"special"}=~s/,*$//g;
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
    if ($#kwdRm>0){		# remove intermediate files
	foreach $kwd (@kwdRm){
	    next if (! defined $file{"$kwd"} || ! -e $file{"$kwd"});
	    print "--- $SBR unlink '",$file{"$kwd"},"'\n" if ($par{"verb2"});
	    unlink($file{"$kwd"});}}
    foreach $kwd ("fileOutTrace","fileOutScreen"){
        next if (! defined $par{"$kwd"} || ! -e $par{"$kwd"});
        print "--- $SBR unlink '",$par{"$kwd"},"'\n" if ($par{"verb2"});
        unlink($par{"$kwd"});}
}				# end of cleanUp

#===============================================================================
sub rdRdbHtmHere {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdRdbHtmHere                reads RDB file
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."rdRdbHtmHere";
    $tmp="";			# ------------------------------
    while (<$fhin>) {		# read header
	last if ($_!~/^\#/);
	if    ($_=~/^\# LENGTH\s*\:\s*(\d+)\D+.*$/)            {$res{"len1",$ctProt}=$1;}
	elsif ($_=~/^\# NHTM_BEST\s*\:\s*(\d+)\D+.*$/)         {$res{"nhtm",$ctProt}=$1;}
	elsif ($_=~/^\# REL_BEST_DPROJ\s*\:\s*([\d\.]+)\D+.*$/){$res{"riMod",$ctProt}=$1;}
#	elsif ($_=~/^\# REL_BEST_DIFF\s*\:\s*([\d\.]+)\D+.*$/) {$res{"relRefDif",$ctProt}=$1;}
#	elsif ($_=~/^\# REL_BEST\s*\:\s*([\d\.]+)\D+.*$/)      {$res{"relRefZ",$ctProt}=$1;}
	elsif ($_=~/^\# HTMTOP_RID\s*\:\s*([\-\d\.]+)\D+.*$/)  {$res{"topD",$ctProt}=$1;}
	elsif ($_=~/^\# HTMTOP_RIP\s*\:\s*(\d+)\D+.*$/)        {$res{"riTop",$ctProt}=$1;}
	elsif ($_=~/^\# HTMTOP_PRD\s*\:\s*([a-z]+)\W+.*$/)     {$res{"top",$ctProt}=$1;}
	elsif ($_=~/^\# MODEL_DAT\s*\:\s*(.+)$/)               {$tmp.="\n".$1;}
    }
    $res{"top",$ctProt}="unk" if (! defined $res{"top",$ctProt}); # if difference 0!!
				# ------------------------------
				# digest regions
    @tmp=split(/\n/,$tmp);
    $res{"htmCN",$ctProt}="";
    foreach $tmp(@tmp){
	$tmp=~s/^\s*|\s*$//g;	# purge leading blanks
	@tmp2=split(/,/,$tmp);
	next if ($#tmp2<4);
	$res{"htmCN",$ctProt}.=",".$tmp2[4];}
    $res{"htmCN",$ctProt}=~s/^,*|,*$//g; # purge leading commata
	
				# ------------------------------
				# read sequence, htm
    $res{"seq",$ctProt}="";
    $res{"htm",$ctProt}="";
    while (<$fhin>) {		# read header
	next if ($_=~/^(No|4N)/); # skip headers
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);
	next if ($#tmp<5);
	if ($tmp[2]!~/[ACDEFGHIJKLMNPQRSTVWXYZ!]/){
	    print "-*- WARN $sbrName res=$tmp[2] strange AA\n";}
	if    (! defined $tmp[11] && $tmp[3] =~/[ LH]/){
	    $tmp=$tmp[3];}
	elsif ((! defined $tmp[11] || $tmp[11]!~/[ LH]/) && $tmp[3]!~/[ LH]/){
	    print "-*- STRONG !! WARN $sbrName prd=$tmp[11] strange prediction !! (HL)\n";
	    $tmp="?";}
	else  {$tmp=$tmp[11];}
	$res{"seq",$ctProt}.=$tmp[2];
	$res{"htm",$ctProt}.=$tmp;}
				# correct if NHTM not defined
    if (! defined $res{"nhtm",$ctProt}){
	$tmp=$res{"htm",$ctProt};
	$tmp=~s/HH*/H/g;$tmp=~s/[ L]//g;
	$res{"nhtm",$ctProt}=length($tmp);}
	
}				# end of rdRdbHtmHere

#==========================================================================================
sub wrtHtml {
    local ($fileRdb,$fileHtml,$fhout,$Llink) = @_ ;
    local ($tmp,@tmp,$des,$ct,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    sub: rdb2html              convert an RDB file to HTML
#         input:		$fileRdb,$fileHtml,$fhout,$Llink 
#                               (Llink=1 -> links from column names to Notation in header)
#--------------------------------------------------------------------------------
    $sbrName="wrtHtml";
    $fhin="FHinRdb2html";
				# --------------------------------------------------
				# read RDB file
				# out GLOBAL: %body, @headerRd,@colNames,
                                #             @nhtm_interval
				# --------------------------------------------------
    ($Lok,$msg)=
	&wrtHtm_rdrdb($fileRdb);return(&errSbrMsg("failed after rdrdb\n",$msg) ) if (! $Lok);
    $fileFtpRdb=$fileRdb;
    $fileFtpRdb=~s/^.*\///g;	# purge directory
    $dirFtp=$par{"reldirFtp_genomesOrg"};
    $dirFtpFull="/home/ftp/".$dirFtp;
    &sysMkdir($dirFtpFull)      if (! -d $dirFtpFull);
    $dirFtp.="/"                if ($dirFtp !~/\/$/);
    $fileFtpRdb_relative=$dirFtp.$fileFtpRdb;

				# open output file
    if ($fhout ne "STDOUT") {
	open($fhout, ">".$fileHtml) || 
	    return(&errSbr("failed opening fileHtml=$fileHtml!\n"));}

    $size=-s $fileRdb;
    $size=int($size/1000)." K";
    ($Lok,$msg)=		# write header
	&wrtHtmlHead($fhout);
    return(0,"*** $sbrName: failed on wrtHtmlHead, msg=\n",$msg,"\n") if (! $Lok);
	
				# write body
				# in GLOBAL: %body,@colNames
    ($Lok,$msg)=		# write header
	&wrtHtmlBody($fhout);
    return(0,"*** $sbrName: failed on wrtHtmlBody, msg=\n",$msg,"\n") if (! $Lok);
				# ------------------------------
				# final words
    $contact= $template{"contact"};
    $contact=~s/date_x+/$date/g;

    print $fhout
	"\n",
	"</TABLE>\n",
	"<!-- ", "end: full data ", " -->\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<P><P>\n",
	$contact,"\n",
	"\n",
	$template{"navi_bot"},"\n", # from wrtHtmlHead
	"\n",
	"</BODY>\n",
	"</HTML>\n";
    
    close($fhout)               if ($fhout ne "STDOUT");
    return(1,"ok $sbrName");
}				# end of wrtHtml

#===============================================================================
sub wrtHtm_rdrdb {
    local($fileRdb) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHtm_rdrdb                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       out GLOBAL:             %body, @headerRd,@colNames,@nhtm_interval
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbr2="wrtHtm_rdrdb";
    $fhinLoc="FHIN_"."wrtHtm_rdrdb";$fhoutLoc="FHOUT_"."wrtHtm_rdrdb";
    open($fhin, $fileRdb) || return(0,"*** $sbr2: failed opening fileRdb=$fileRdb\n");
    
    $#headerRd=0;		# ------------------------------
    while (<$fhin>) {		# read header of RDB file
	$tmp=$_;$_=~s/\n//g;
	last if (! /^\#/);
	push(@headerRd,$_);}
				# ------------------------------
				# get column names
    $tmp=~s/\n//g;$tmp=~s/^\t*|\t*$//g;
    @colNames=split(/\t/,$tmp);
    undef %body;

    $body{"COLNAMES"}="";	# store column names
    foreach $des (@colNames){
        next if ($des =~ /seq/i && $par{"nperLine"}==0); # ignore sequence!
        $body{"COLNAMES"}.="$des".",";}

    undef %count;
				# ------------------------------
				# read body
    $ct=0;
    $max=0;
    while (<$fhin>) {		# 
	next if ($_=~/\t\d+[NFD\t]\t/); # skip format
	$_=~s/\n//g;$_=~s/^\t*|\t*$//g;	# purge leading
	next if (length($_)<1);
	@tmp=split(/\t/,$_);
	++$ct;
	foreach $it (1..$#tmp){	# store body
	    $kwd=$colNames[$it];
	    $tmpLine=$tmp[$it]; $tmpLine=~s/\s//g;
	    $body{$ct,$kwd}=$tmpLine;
				# count membrane proteins with N helices
	    if    ($kwd eq "nhtm") {
		$body{$ct,$kwd}=~s/\s//g;
		$nhtm=$body{$ct,$kwd};
		$max= $nhtm     if ($max < $nhtm);
		$count{"all",$nhtm}=0 if (! defined $count{"all",$nhtm});
		++$count{"all",$nhtm};}
				# count topology specific
	    elsif ($kwd eq "top") {
		$top=$tmp[$it];
		$count{$top,$nhtm}=0 if (! defined $count{$top,$nhtm});
		++$count{$top,$nhtm};}
				# resort
	    elsif ($kwd eq "htmCN"){
		$body{$ct,$kwd}=~s/^,|,([\s\n]*)$//g; # purge leading commata
		@tmp2=split(/,/,$body{$ct,$kwd});
				# resort by size
		undef %tmp; $#tmp3=0;
		foreach $tmp (@tmp2) {
		    ($beg,$tmp)=split(/\-/,$tmp);
		    $beg=~s/\s//g;
		    push(@tmp3,$beg);
		    $tmp{$beg}=$tmp;}
		$#tmp2=0;
		foreach $tmp (sort bynumberLoc @tmp3) {
		    push(@tmp2,$tmp{$tmp});}
		$body{$ct,$kwd}=join(',',@tmp2);
		$#tmp2=$#tmp3=0;}
	}}
    $body{"NROWS"}=$ct;
    close($fhin);
				# end of reading RDB file
				# ------------------------------

				# ------------------------------
				# cumulative numbers
    foreach $num (1..$max) {
	foreach $kwd ("all","in","out"){
	    $count{"cum",$kwd,$num}=0;}}
    $count{"max"}=$max;

    foreach $num (1..$max) {
	foreach $num2 ($num..$max) {
	    next if (! defined $count{"all",$num2} || ! $count{"all",$num2});
	    $count{"cum","all",$num}+=  $count{"all",$num2};
	    $count{"cum","in",  $num}+=
		$count{"in",$num2}   if (defined $count{"in",$num2});
	    $count{"cum","out", $num}+=
		$count{"out",$num2}  if (defined $count{"out",$num2});
	}}

    return(1,"ok $sbr2");
}				# end of wrtHtm_rdrdb

#==========================================================================================
sub wrtHtmlHead {
    local ($fhoutLoc) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlHeader		write the HTML header
#         input:		$fhout
#         output:               
#--------------------------------------------------------------------------------
    $sbr2="wrtHtmlHead";
				# ------------------------------
				# names asf
				# ------------------------------
    $organism=$par{"organism"};
    if (defined $known{$organism}){
	$organismFull=$known{$organism};}
    else {
	$organismFull=$organism;}
    $organismTitle="$organismFull"; $organismTitle.=" ($organism)" if ($organism ne $organismFull);

				# ------------------------------
				# read CUBIC WWW templates
				# ------------------------------
    $prev=     $par{"reldirWeb_genomes"}."index.html";
    $next=     "index.html";
    $style=    $par{"reldirWeb_cubic"}."style/";

    $titleHead="CUBIC: HTM's for ".$organism; # title for HTML header
    $titleBody="Transmembrane helices for ".$organism." ($organismFull)";

    undef %template;
    foreach $kwd ("head","contact","navi_top","navi_bot"){
	$file=$par{"fileTemplate_".$kwd};
	return(&errMsgSbr("missing template for kwd=$kwd, file=$file",$SBR))
	    if (! -e $file);
	open($fhinLoc,$file) || return(&errSbr("file=$file, not opened",$SBR));
	$template{$kwd}="";
	while (<$fhinLoc>) {
	    $template{$kwd}.=$_;
	}
	close($fhinLoc);
				# ------------------------------
				# replace stuff
				# header (title)
	if    ($kwd=~/head/) {
	    $template{$kwd}=~s/title(_x+)?/$titleHead/g; 
	    $template{$kwd}=~s/(\")style/$1$style/g;
	    $template{$kwd}=~s/prev_x+/$prev/;
	    $template{$kwd}=~s/next_x+/$next/; }
				# navigate: next and previous
	elsif ($kwd=~/navi/) {
	    $template{$kwd}=~s/prev_x+/$prev/;
	    $template{$kwd}=~s/next_x+/$next/;}
    }

				# ------------------------------
				# build up header of page
				# ------------------------------
    @txtHead=
	(
	 $template{"head"},"\n",
	 "\n",
	 "<BODY>\n",
	 "\n",
	 $template{"navi_top"},"\n",
	 "<P>\n",
	 "<!-- ", "=" x 80 , " -->\n",
	 "<!-- ", "beg: intro ", " -->\n",
	 "<H1>_titleBody_</H1>\n",
	 "<STRONG>",
	 "<A HREF=\"mailto:jl840\@columbia.edu\">Jinfeng Liu</A>"," & ",
	 "<A HREF=\"mailto:rost\@columbia.edu\">Burkhard Rost</A>",
	 "</STRONG>\n",
	 "<P>\n",
	 "\n",
	 "<P>\n",
	 "<A HREF=\"http://dodo.cpmc.columbia.edu/cubic/\">",
	 "<FONT SIZE=\"+2\">CUBIC</FONT></A>",
	 " Columbia Univ, Dept Biochem & Mol Biophysics<BR>\n",
	 "<P><P>\n",
	 "\n");


    foreach $txt (@txtHead) {
	$txt=~s/_titleBody_/$titleBody/ if ($txt=~/_titleBody_/);
	print $fhoutLoc $txt;}
				# organisation of page
    $ftpsite="ftp:\/\/".$par{"cubicFtpServer"}."/".$fileFtpRdb_relative;
    print $fhoutLoc
	"<STRONG>You can get:</STRONG><BR>\n",
	"<UL>\n",
	"<LI><A HREF=\"",$par{"relfileWeb_"."query"},"\">query</A>",
	     " the result pages for $organismFull</LI>",
	"<LI><A HREF=\"","#results_here","\">display all results</A>",
	     " sorted by the number of membrane helices predicted</LI>",
	"<LI>get explanations of ",
	     "<A HREF=\"",$par{"relfileWeb_"."explain"}."#htm_notation_gen",
	     "\">terms used</A> on page</LI>",
	"<LI>get explanations for the ",
	     "<A HREF=\"",$par{"relfileWeb_"."explain"}."#htm_notation_col",
	     "\">column names</A> used in the tables</LI>",
	"<LI>get all results in one file (size=$size) by ",
	     "<A HREF=\"$ftpsite\">anonymous ftp</A></LI>",
	"<LI>click on <STRONG>ASCII</STRONG> to view the ASCII results (faster loading)</LI>",
	"<LI>click on <STRONG>HTML</STRONG> to view the respective pages</LI>",
	"</UL>\n",
	"<P><P>\n",
	"<!-- ", "end: intro ", " -->\n",
	"<!-- ", "=" x 80 , " -->\n",
	"\n",
	"<P><P>\n";

				# summary of data
    print $fhoutLoc
	 "<!-- ", "=" x 80 , " -->\n",
	 "<!-- ", "beg: summary ", " -->\n",
	"<H2>Summary of data</H2>\n",
	"<UL>\n",
	"<LI>Percentage of all proteins in $organismFull with at least N membrane helices:\n",
	"</UL>\n";

    print $fhoutLoc
	"<TABLE BORDER=1>\n",
	"<TR><TD> </TD>",
	"<TD COLSPAN=3>Number of proteins</TD>",
	"<TD COLSPAN=3>Cumulative percentage of proteins in entire genome</TD></TR>\n",
	"<TR><TD>Nhtm</TD><TD>all</TD><TD>top=in</TD><TD>top=out</TD>",
	"<TD>all</TD><TD>top=in</TD><TD>top=out</TD></TR>\n";

				# note: @nhtm_interval taken from wrtHtm_rdrdb!
    foreach $num (1 .. $count{"max"}){
	next if (! defined $count{"cum","all",$num} || ! $count{"cum","all",$num});
	next if (! defined $count{"all",$num} || ! $count{"all",$num});
	print $fhoutLoc "<TR><TD>$num</TD>";
	foreach $kwd ("all","in","out"){
	    $tmp=0;
	    $tmp=$count{$kwd,$num} if (defined $count{$kwd,$num});
	    print $fhoutLoc "<TD>",$tmp,"</TD>";}
	foreach $kwd ("all","in","out"){
	    $tmp=0;
	    $tmp=100*($count{"cum",$kwd,$num}/$par{"nprot"})
		if (defined $count{"cum",$kwd,$num});
	    printf $fhoutLoc "<TD>%5.1f</TD>",$tmp;}
	print $fhoutLoc "</TR>\n";}

    print $fhoutLoc
	"</TABLE>\n",
	 "<!-- ", "end: summary ", " -->\n",
	 "<!-- ", "=" x 80 , " -->\n",
	"<P><BR><P>\n",
	"\n";
				# now comes the full data
    
    print $fhoutLoc
	"<!-- ", "=" x 80 , " -->\n",
	"<!-- ", "beg: full data ", " -->\n",
	"<H2>Link to full data</H2>\n",
	"<P>\n",
	"\n";
	
    return(1,"ok $sbr2");
}				# end of wrtHtmlHead

#==========================================================================================
sub wrtHtmlBody {
    local ($fhout) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtHtmlBody		        writes the body for a RDB->HTML file
#                               where $body{"it","colName"} contains the columns
#       in:                     $fhout
#       in GLOBAL:              %body (rdb data)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $sbr2=      "wrtHtmlBody"; 
    $fhout_html="FHOUT_HTML_".$sbr2;
    $fhout_ascii= "FHOUT_TEXT_".$sbr2;

				# get column names
    $body{"COLNAMES"}=~s/^,*|,*$//g;
    @colNames=split(/,/,$body{"COLNAMES"});

                                # ------------------------------
                                # split data
                                # ------------------------------
    @numSplit=split(/,/,$par{"numSplit"});


    print $fhout 
	"<TABLE BORDER>\n",
	"<TR>",
	"<TD><A HREF=\"".$par{"relfileWeb_"."explain"}."#htm_notation_nhtm"."\">",
	     "&gt; nhtm</A></TD>",
	"<TD><A HREF=\"".$par{"relfileWeb_"."explain"}."#htm_notation_html"."\">HTML</A></TD>",
	"<TD><A HREF=\"".$par{"relfileWeb_"."explain"}."#htm_notation_ascii"."\">ASCII</A></TD>",
	"<TD>note</TD>",
	"</TR>\n",
	"\n";
	
				# --------------------------------------------------
				# split according to number of htm
				# --------------------------------------------------
    $#flag=0;			# avoid duplication

    foreach $num (@numSplit) {
	next if ($num!~/^\d+$/);
	$numTxt=$num;
	$numTxt="0".$numTxt     if ($num < 10);
	$titleAdd="";
	$titleAdd=$par{"organism"}."_" if ( $par{"organism"}!~/\s/ && 
					   length($par{"organism"})<6);
	$fileHtmlLoc=  $par{"dirOut"}.$titleAdd.$par{"preHtm"}.$numTxt.".html";
	$fileAsciiLoc=   $par{"dirOut"}.$titleAdd.$par{"preHtm"}.$numTxt.".txt";
	$fileHtml07Loc=$par{"dirOut"}.$titleAdd.$par{"preHtm"}.$numTxt."_low.html";
	$fileAscii07Loc= $par{"dirOut"}.$titleAdd.$par{"preHtm"}.$numTxt."_low.txt";

				# ------------------------------
				# write single files
	open($fhout_html,">".$fileHtmlLoc) || 
	    return(&errSbr("failed to open fileoutHtml=$fileHtmlLoc"));
	open($fhout_ascii,">".$fileAsciiLoc) || 
	    return(&errSbr("failed to open fileoutAscii=$fileAsciiLoc"));

	$titleBody="All proteins with at least $num transmembrane helices in ".
	    $known{"$organism"};

				# @txtHead = in GLOBAL from wrtHtmlHead
	foreach $txt (@txtHead) {
	    $txt=~s/_titleBody_/$titleBody/ if ($txt=~/_titleBody_/);
	    print $fhout_html $txt;}

				# header for ascii
	print $fhout_ascii
	    "--- ","-" x 80, " ---\n",
	    "--- $titleBody\n",
	    "--- ","-" x 80, " ---\n",
	    "--- contact:  cubic\@dodo.cpmc.columbia.edu\n",
	    "--- www page: http://dodo.cpmc.columbia.edu/\n",
	    "--- \n",
	    "--- note:     all use of this data MUST quote the origin!\n",
	    "--- \n",
	    "--- ","-" x 80, " ---\n";
	    
				# column names
	print $fhout_html 
	    "<!-- ","." x 80 , " --> \n",
	    "<!-- beg: table --> \n",
	    "<TABLE BORDER=2>\n";

	&wrtHtmlBody_colNames(1);
		
				# ------------------------------
				# loop over all proteins
				# ------------------------------

	$ct=0;
	foreach $it (1..$body{"NROWS"}){
	    next if ($body{$it,"nhtm"}=~/\D/);
				# skip since not within current interval
				# end loop, since sorted!!!
	    last if ($body{$it,"nhtm"} < $num);
				# already taken
	    next if (defined $flag[$it]);
	    $flag[$it]=1;
	    ++$ct;

	    print $fhout_html "\n<TR>   ";

	    foreach $itdes (1..$#colNames){
		if    ($colNames[$itdes]=~/^(num|nhtm|nali|len1|ri|top)/){
		    print $fhout_html "<TD ALIGN=RIGHT>";}
		elsif ($colNames[$itdes]=~/^(id|htmCN)/){
		    print $fhout_html "<TD ALIGN=LEFT>";}
		elsif ($colNames[$itdes] eq "seq" && $par{"nperLine"}>0){
		    print $fhout_html "<TD ALIGN=LEFT>";}
		elsif ($colNames[$itdes] ne "seq"){
		    print $fhout_html "<TD>";}
	    
				# (1) sequence special
		if (defined $body{$it,$colNames[$itdes]} && 
		    $colNames[$itdes] eq "seq") {
				# take only first 

		    $seqN=substr($body{$it,$colNames[$itdes]},1,$par{"seqTake"});
		    $len= length($body{$it,$colNames[$itdes]});
		    $seqC=substr($body{$it,$colNames[$itdes]},($len-$par{"seqTake"}),
				 $par{"seqTake"});
		    
				# print N and C term separately
		    print $fhout_ascii $seqN,"\t",$seqC;
		    print $fhout_html $seqN,"</TD><TD>",$seqC;}

				# (2) split the positions (htmCN)
		elsif (defined $body{$it,$colNames[$itdes]} && 
		       $colNames[$itdes] eq "htmCN") {
		    @tmp=split(/,/,$body{$it,$colNames[$itdes]});
		    print $fhout_ascii $body{$it,$colNames[$itdes]};
		    if ($#tmp < $par{"numHtm_perLine"}){
			print $fhout_html 
			    $body{$it,$colNames[$itdes]};}
		    else        {
			$tmp="";
			for ($itx=1;$itx<=$#tmp;$itx+=$par{"numHtm_perLine"}){
			    foreach $itx2($itx..($itx+($par{"numHtm_perLine"}-1))){
				last if ($itx2>$#tmp);
				$tmp.="$tmp[$itx2]".",";}
			    $tmp.=" ";}
			$tmp=~s/,([\s\n]*)$/$1/g;
			print $fhout_html $tmp;}}
				# (3) all others if ok
		elsif (defined $body{$it,$colNames[$itdes]}){
		    print $fhout_ascii  $body{$it,$colNames[$itdes]};
		    print $fhout_html $body{$it,$colNames[$itdes]};}
				# (4) all others if not defined
		else {
		    print $fhout_ascii  " ";
		    print $fhout_html " ";} 
		print $fhout_ascii  "\t";
		print $fhout_html "</TD>";}
	    print $fhout_ascii  "\n";
	    print $fhout_html "</TR>\n";
				# repeat names every 100 lines
	    &wrtHtmlBody_colNames(0) if (int($ct/100)==($ct/100));
	}			# end of loop over all proteins
				# ------------------------------

				# closing blabla for current file
	print $fhout_html 
	    "\n",
	    "</TABLE>\n",
	    "<P><P>\n",
	    "<!-- beg: table --> \n",
	    "<!-- ","." x 80 , " --> \n",
	    $template{"navi_bot"},"\n",	# from wrtHtmlHead
	    "\n",
	    "</BODY>\n",
	    "</HTML>\n";
	close($fhout_html);
	close($fhout_ascii);
				# ------------------------------
				# delete, if empty!!
				# ------------------------------
	if ($ct==0){
	    unlink($fileHtmlLoc);
	    unlink($fileAsciiLoc); }
				# ------------------------------
				# add to table if NOT empty
				# ------------------------------
	else {
	    print "--- $sbr2 wrote split: fileHtml=$fileHtmlLoc, fileAscii=$fileAsciiLoc\n" 
		if ($par{"verbose"});
	    push(@fileOut,$fileHtmlLoc,$fileAsciiLoc);
	
	    print $fhout 
		"<TR>",
		"<TD>at least $num HTMs</TD>",
		"<TD><A HREF=\"".$fileHtmlLoc."\">HTML</A></TD>",
		"<TD><A HREF=\"".$fileAsciiLoc. "\">ASCII</A></TD>",
		"<TD> </TD>","</TR>\n", "\n";
				# add row with low reliability
	    if ($num<=2) {
		print $fhout 
		    "<TR>",
		    "<TD>at least $num HTMs</TD>",
		    "<TD><A HREF=\"".$fileHtml07Loc."\">HTML</A></TD>",
		    "<TD><A HREF=\"".$fileAscii07Loc. "\">ASCII</A></TD>",
		    "<TD>lower reliabilty (but higher coverage)</TD>","</TR>\n", "\n";} }

    }				# end of table over current splittings
				# --------------------------------------------------

    print $fhout "</TABLE>\n";
    print $fhout "\n\n";
    return(1,"ok $sbr2");
}				# end of wrtHtmlBody

#==========================================================================================
sub wrtHtmlBody_colNames {
    local ($Lascii)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBodyColNames      writes the column names (called by previous)
#       GLOBAL input:		%bodyLoc
#         input:                $fhout,@colNames
#--------------------------------------------------------------------------------
    print $fhout_html "<TR ALIGN=LEFT>  ";
    foreach $des (@colNames){
	if ($des eq "seq") {
	    print $fhout_html 
		"<TH><A HREF=\"".$par{"relfileWeb_"."explain"}."#htm_notation_seqN".
		    "\">seqN</A></TH>\t";
	    print $fhout_html 
		"<TH><A HREF=\"".$par{"relfileWeb_"."explain"}."#htm_notation_seqC".
		    "\">seqC</A></TH>\t";
	    print $fhout_ascii "seqN\t","seqC\t" if ($Lascii); }
	else {
	    print $fhout_html
		"<TH><A HREF=\"".$par{"relfileWeb_"."explain"}."#htm_notation_".$des.
		    "\">$des</A></TH>\t";

	    print $fhout_ascii "$des\t" if ($Lascii);
	}}
    print $fhout_html "</TR>\n";
    print $fhout_ascii  "\n" if ($Lascii);
}				# end of wrtHtmlBody_colNames

#===============================================================================
sub wrtRdbHere {
    local($fhLoc)=@_;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHere                  writes RDB file
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtRdbHere";
				# ------------------------------
    print $fhLoc "num";		# write names
    foreach $kwd (@kwdFin){
	printf $fhLoc "\t%-s",$kwd;}
    print $fhLoc "\n";
				# ------------------------------
    $ct=0;			# write data
    foreach $it (@order){	# loop over all proteins
	++$ct;printf $fhLoc "%5d",$ct;
	foreach $kwd (@kwdFin){	# all columns to write
	    $tmpForm=$formFin{$kwd};
	    if (defined $res{$kwd,$it}){
		$tmpData=$res{$kwd,$it};$tmpData=~s/\s//g;}
	    else {$tmpData="";}
	    next if ($fhLoc eq "STDOUT" && $kwd eq "seq");
	    printf $fhLoc "\t$tmpForm",$tmpData;}
	print $fhLoc "\n";}
}				# end of wrtRdbHere

#===============================================================================
sub wrtRdbHdrHere {
    local($fhLoc)=@_;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRdbHdrHere               writes RDB header 
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtRdbHdrHere";
				# ------------------------------
				# write header
    print  $fhLoc "# Perl-RDB\n# \n";
    printf $fhLoc "# NOTATION %-5s : %-s\n","id",   "identifier of protein";
    printf $fhLoc "# NOTATION %-5s : %-s\n","nhtm", "number of transmembrane helices predicted";
    printf $fhLoc 
	"# NOTATION %-5s : %-s\n","top",  "topology, i.e., location of first loop region";
    printf $fhLoc "# NOTATION %-5s : %-s\n","nali", "number of sequence in family";
    printf $fhLoc "# NOTATION %-5s : %-s\n","len1", "length of protein";
    printf $fhLoc 
	"# NOTATION %-5s : %-s\n","riTop","reliability of topology prediction (9=high, 0=low)";
    printf $fhLoc "# NOTATION %-5s : %-s\n","riMod","reliability of best model (9=high, 0=low)";
    printf $fhLoc 
	"# NOTATION %-5s : %-s\n","topD", 
	"difference in number of charged loop residues (K+R): all even loops - all odd loops";
    printf $fhLoc "# NOTATION %-5s : %-s\n","htmCN","position (C-N) of predicted helices";
    printf $fhLoc "# NOTATION %-5s : %-s\n","seq",  "sequence (one letter amino acid code)";
    print $fhLoc "# \n";
}				# end of wrtRdbHdrHere


#===============================================================================
sub wrtStat {
    local($fhLoc,$title) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtStat                     writes overall statistics
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtStat";


				# ------------------------------
    $cum=$cumIn=$cumOut=0;	# cumulative
    foreach $it(1..$maxNhtm){	# print all
	$ct=$maxNhtm+1-$it;
	$stat{$ct,"in"}=0  if (! defined $stat{$ct,"in"});
	$stat{$ct,"out"}=0 if (! defined $stat{$ct,"out"});
	$stat{$ct,"sum"}= $stat{$ct,"in"} + $stat{$ct,"out"};
	$cum+=   $stat{$ct,"sum"};$stat{$ct,"sum","cum"}=$cum;
	$cumIn+= $stat{$ct,"in"}; $stat{$ct,"in","cum"}= $cumIn;
	$cumOut+=$stat{$ct,"out"};$stat{$ct,"out","cum"}=$cumOut;}
				# ------------------------------
				# header
    print $fhLoc 
	"# Nprd        number of HTM predicted\n",
	"# Nsum        Sum of occurrences\n",
	"# Nin/out     Sum for 'in'/'out'\n",
	"# NBin/out    Sum over proteins with both caps 'in','out'\n",
	"# NC          cumulative sum (starting from highest)\n",
	"# NCin/out    cumulative for 'in'/'out'\n",
#	"# Nexcluded   ",$res{"nProtExcl"}," (as shorter than ",$par{"minLen"},")\n",
	"# NprotTot    ",$par{"nprot"}," (total number of proteins)\n",
	"# NprotHtm    ",$res{"NROWS"}," (total number of proteins with HTMs)\n",
	"# PC/in/out   percentage cumulative (all ORF's =)",int(100*$cum/$par{"nprot"}),")\n";

    printf $fhLoc 
	"%3s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s",
	"Nprd".$title,"Nsum".$title,"Nin".$title,"Nout".$title,
	"NBin","NBout","NC".$title,"NCin".$title,"NCout".$title;
    if ($fhLoc ne "STDOUT" && (defined $par{"nprot"})&&($par{"nprot"}>1)){
	printf $fhLoc 
	    "\t%5s\t%5s\t%5s\n","PC".$title,"PCin".$title,"PCout".$title;}
    else {print $fhLoc "\n";}
    $ct_caps_in=$ct_caps_out=0;
    foreach $ct(1..$maxNhtm){	# print all
	if (($ct/2)==int($ct/2)) {$Leven=1;}else{$Leven=0;}
	if (! $Leven){$stat{$ct,"caps_in"}=$stat{$ct,"in"};
		      $stat{$ct,"caps_out"}=$stat{$ct,"out"};}
	else{$stat{$ct,"caps_in"}=$stat{$ct,"caps_out"}=0;}
	$ct_caps_in+=$stat{$ct,"caps_in"};$ct_caps_out+=$stat{$ct,"caps_out"};
	
	printf $fhLoc "%3d",$ct;
	foreach $kwd ("sum","in","out","caps_in","caps_out"){
	    printf $fhLoc "\t%5d",$stat{$ct,$kwd};}
	foreach $kwd ("sum","in","out"){
	    printf $fhLoc "\t%5d",$stat{$ct,$kwd,"cum"};}
	if (($fhLoc ne "STDOUT")&&(defined $par{"nprot"})&&($par{"nprot"}>1)){
	    printf $fhLoc 
		"\t%5d\t%5d\t%5d\n",
		(100*$stat{$ct,"sum","cum"}/$par{"nprot"}),
		(100*$stat{$ct,"in", "cum"}/$par{"nprot"}),
		(100*$stat{$ct,"out","cum"}/$par{"nprot"});
	}else {print $fhLoc "\n";}
    }
}				# end of wrtStat

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."subx";
    $fhinLoc="FHIN_"."subx";$fhoutLoc="FHOUT_"."subx";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty


    } close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of subx

