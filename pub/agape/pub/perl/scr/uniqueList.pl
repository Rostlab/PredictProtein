#!/usr/bin/perl -w
##!/bin/env perl
##!/usr/sbin/perl -w
##!/usr/pub/bin/perl -w
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "compiles a list of unique protein (pairs) a la hobohm greedy";
$scrIn=      "pair.RDB (from blastProcess.rdb)";
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= "       Two purposes:\n";
$scrHelpTxt.="  (1)  NEW unique list from BLAST pairs    'help input'\n";
$scrHelpTxt.="  \n";
$scrHelpTxt.="> $scrName pairs.rdb [exclude_file] [include_file] [res|small|large minDis=n]\n";
$scrHelpTxt.="  \n";
$scrHelpTxt.="  (2)  training|val|testing set from list  'help set' \n";
$scrHelpTxt.="  \n";
$scrHelpTxt.="> $scrName pairs.rdb set=file_with_ids nprot=100|nset=5  \n";
$scrHelpTxt.=" \n";
$scrHelpTxt.=" -   explicitly ex|including proteins      'help file'\n";
$scrHelpTxt.=" -   rooting (starting with) by :large|small|res\n";
$scrHelpTxt.="        large : largest family first\n";
$scrHelpTxt.="        small : smallest family first\n";
$scrHelpTxt.="        res   : best structure first\n";
$scrHelpTxt.=" -   distance : dis=N\n";
$scrHelpTxt.=" \n";
$scrHelpTxt.=" e.g. $scrName include.list exclude.list pairs.rdb\n";
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
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Aug,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();			# 
if (! $Lok) { print "*** ERROR $scrName after ini\n",$msg,"\n";
	      die '*** during initialising $scrName   ';}

#-----------------------------------------------------------------------------------
# do the job (here we go)
#-----------------------------------------------------------------------------------
				# --------------------------------------------------
				# global counters, variables
				# --------------------------------------------------
$ctId1=$ctId2=0;
				# pointers
undef %id1ptr; undef %id2ptr;	# $id1ptr{"$id"}= $ctId1    i.e. id to number
$#id1ptr=$#id2ptr=0;		# $id1ptr[$ctId1]=$id       i.e. number to id

				# data
$#len=0;			# $len[$ctId1] length of ctId1
$#res=0;			# $res[$ctId1] resolution of ctId1
$#num=0;			# $num[$ctId1] number of homologues to ctId1
undef $ra_family;		# $ra_family->[$ctId1] reference to @id2[1..$num[$ctId1]],
				#     i.e., all proteins homologous to ctId1
				#     note: $id2[it] gives the number referring to id2 
				#           id2=$id2ptr[$id2[it]]

$#wrtWarn=0;			# greedy_checkit will write warnings for homologues both
				#     included

$#levels=0;			# will hold all levels read in file_include (1,-1,-2,..)

$#set=0;			# will give idnum for all proteins wanted for partitioning
				#     list into sets (trn|val|tst)
				#     $set[1]=$idnum of first in file_set (given by arg: 'set=file')
undef %set;			# $set{$id1}=1 if $id1 in set!

				# --------------------------------------------------
				# read exclude files
				#    note: first as all found here will be omitted
				# --------------------------------------------------
				# out: $rh_excl{$id}=position
if (defined $par{"fileExcl"} && -e $par{"fileExcl"}) {
    ($Lok,$msg,$rh_excl)=
	&fileExclRd($par{"fileExcl"});
    &errScrMsg("failed reading exclude file=".$par{"fileExcl"}."\n".$msg) if (! $Lok); }

				# --------------------------------------------------
				# read set to partition
				# --------------------------------------------------
if ($par{"fileSet"}) {
    &errScrMsg("for mode: partition the file with sets (".$par{"fileSet"}.") missing!") 
	if (! -e $par{"fileSet"});
				# out GLOBAL: $set{$id}=1
    ($Lok,$msg)=
	&fileSetRd($par{"fileSet"});
    &errScrMsg("failed on reading set=".$par{"fileSet"}."\n",$msg) if (! $Lok); }


				# --------------------------------------------------
				# read set with PDB resolution
				# --------------------------------------------------
if (defined $fileRes && -e $fileRes){
				# out GLOBAL: $resolution{$id}=1
				# 
				# format 'id TAB resolution'
    ($Lok,$msg)=
	&fileResRd($fileRes);
    &errScrMsg("failed on reading res=".$fileRes."\n",$msg) if (! $Lok); }

				# --------------------------------------------------
				# read all pairs
				# --------------------------------------------------

foreach $fileIn (@fileIn) {	# in : $rh_excl{$id}=position
    print $fhTrace2 "--- read file $fileIn\n";
				# GLOBAL out: pointers %id12ptr,@id12ptr
				#             data     @len,@res,@num,$ra_family->[]
    ($Lok,$msg)=
	&filePairsRd($fileIn);      
    &errScrMsg("failed reading pairs file=".$fileIn."\n".$msg) if (! $Lok); }

$nid1=$ctId1;
undef %{$rh_excl};		# slim-is-in!

				# --------------------------------------------------
				# additional array for partition
				#    result: @set[1..wanted]=$idnum (!) of wanted
				# --------------------------------------------------
if ($par{"fileSet"}) {
    $#tmp=0;
    foreach $id1 (@set) {
	if (! defined $id1ptr{$id1}){
	    print "-*- WARN $scrName: id1=$id1, seems NOT in pairs.rdb file (no id1ptr)\n";
	    next;}
	push(@tmp,$id1ptr{$id1}); }
    @set=@tmp;}

				# --------------------------------------------------
				# read include files
				# --------------------------------------------------
                                # out: $ra_incl[$idnum]}=level (1,-1,...)
if (defined $par{"fileIncl"} && -e $par{"fileIncl"}) {
    ($Lok,$msg,$levels,$ra_incl_level)=
	&fileInclRd($par{"fileIncl"});

    &errScrMsg("failed reading include file=".$par{"fileIncl"}."\n".$msg) if (! $Lok); 
    $levels=~s/,*$//g; @levels=split(/,/,$levels); 

				# reduce memory load
#    foreach $idnum (1..$nid1) {print "xxnum($idnum)=$num[$idnum],";}print "\n";
    if (0){			# xx
	($Lok,$msg)=
	    &dataReduce();          return(&errSbrMsg("failed reducing data",$msg)) if (! $Lok);
    }
}
    


				# --------------------------------------------------
				# do the greedy optimisation
				# --------------------------------------------------
if (! $par{"fileSet"}) {
    ($Lok,$msg)=
	&greedy();              &errScrMsg("failed greedy\n".$msg) if (! $Lok); 

    ($Lok,$msg)=
	&wrtDbgFin($fhTrace);   &errScrMsg("failed wrtDbgFin ($fhTrace)\n".$msg) if (! $Lok); 

				# write all output files for option greedy !
    ($Lok,$msg)=
	&wrtGreedyFin();        &errScrMsg("failed wrtGreedyFin\n".$msg) if (! $Lok); }

				# --------------------------------------------------
				# partition sets
				# --------------------------------------------------
else {
				# note: output files written directly in partition!
    ($Lok,$msg)=
	&partition();           &errScrMsg("failed on partition",$msg) if (! $Lok); }


				# ==================================================
				# work done, go home
				# --------------------------------------------------

                                # deleting intermediate files
&cleanUp()   if (! $par{"debug"}); 
				# write screen message
&wrtFinLoc() if ($Lverb);

print "-*- WARN $scrName: output appended to the log file ",$par{"fileOutTrace"},"\n"
    if (defined $LfileOutTrace_warningAppended);

				# cheers
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
    $[ =1 ;
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
    foreach $arg(@ARGV){	# highest priority ARCH
	if ($arg=~/ARCH=(.*)$/){
	    $ARCH=$ENV{'ARCH'}=$1; 
	    last;}}
    $ARCH=$ARCH || $ENV{'ARCH'} || "SGI32";
				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
    &iniLib();			# require perl libraries
				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();

				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
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
        if    ($arg=~/^list$/i)               { $par{"isList"}=       1;}

	elsif ($arg=~/^small$/i)              { $par{"modeRoot"}=     "small"; }
	elsif ($arg=~/^large$/i)              { $par{"modeRoot"}=     "large"; }
	elsif ($arg=~/^res$/i)                { $par{"modeRoot"}=     "res"; 
						$par{"do_res"}=       1; }
	elsif ($arg=~/^res=(.*)/i)            { $fileRes=             $1;
						$par{"modeRoot"}=     "res"; 
						$par{"do_res"}=       1; }
	elsif ($arg=~/^fileres=(.*)/i)        { $fileRes=             $1;
						$par{"modeRoot"}=     "res"; 
						$par{"do_res"}=       1; }
     
	elsif ($arg=~/^mindist?=(.+)$/i)      { $par{"minDis"}=       $1; }
	elsif ($arg=~/^dist?=(.+)$/i)         { $par{"minDis"}=       $1; }

	elsif ($arg=~/^incl=(.+)$/i)          { $par{"fileIncl"}=     $1; }
	elsif ($arg=~/^excl=(.+)$/i)          { $par{"fileExcl"}=     $1; }

	elsif ($arg=~/^set=(.*)$/i)           { $par{"fileSet"}=      $1; }
	elsif ($arg=~/^nprot=(.*)$/i)         { $par{"nprot"}=        $1; }
	elsif ($arg=~/^nset=(.*)$/i)          { $par{"nset"}=         $1; }
	
	elsif ($arg=~/^nodis$/i)              { $par{"do_dis"}=       0; }
	elsif ($arg=~/^nores$/i)              { $par{"do_res"}=       0; }
	elsif ($arg=~/^nolen$/i)              { $par{"do_len"}=       0; }
	elsif ($arg=~/^dis$/i)                { $par{"do_dis"}=       1; }
	elsif ($arg=~/^len$/i)                { $par{"do_len"}=       1; }

	elsif ($arg=~/^nohopp$/i)             { $par{"doSetHopp"}=    0; }

	elsif ($arg=~/^nowrtCluster$/i)       { $par{"wrtFamilySize"}=0; }
	elsif ($arg=~/^wrtRes$/i)             { $par{"wrtRes"}=1; 
						$par{"modeRoot"}=     "res"; 
						$par{"do_res"}=       1; }
	elsif ($arg=~/^wrtCluster$/i)         { $par{"wrtFamilySize"}=1; }
	elsif ($arg=~/^wrtFamily[a-z]*$/i)    { $par{"wrtFamilySize"}=1; }

	elsif ($arg=~/^verbDbg$/i)            { $par{"verbDbg"}=     1; }
	elsif ($arg=~/^verb2$/i)              { $par{"verb2"}=       1; }
	elsif ($arg=~/^noDbg$/i)              { $par{"verbDbg"}=     0; }
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}=     "nice -".$1;}
	elsif ($arg eq "nonice")              { $par{"optNice"}=     " ";}
	elsif ($arg eq "debug")               { $par{"debug"}=       1;}
	elsif ($arg eq "dbg")                 { $par{"debug"}=       1;}
	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}
    print "-*- WARNING iniGetArg: command line arguments overwrite '".$par{"fileDefaults"}."\n" 
	if ($par{"verbose"} && defined %defaults && %defaults);
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verbDbg"}=1           if ($par{"debug"});
    $par{"verb2"}=1             if ($par{"debug"});
    $par{"verbose"}=1           if ($par{"verb2"});
	
    $Lverb= $par{"verbose"};
    $Lverb2=$par{"verb2"};

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
				# process input files
				# ------------------------------
    $#fileInTmp=0;
    foreach $fileIn (@fileIn) {
	$tmp=`head -1 $fileIn`; $tmp=~s/\n//;
				# file with ids to exclude
	if ($tmp=~/^\#\s*.*exclude/i) {
	    $par{"fileExcl"}=$fileIn; # for later references
	    next; }
				# file with ids to include
	if ($tmp=~/^\#\s*.*include/i) {
	    $par{"fileIncl"}=$fileIn; # for later references
	    next; }
				# all others: take
	push(@fileInTmp,$fileIn); }
    @fileIn=@fileInTmp;
				# ------------------------------
				# syntax check
				# ------------------------------
    return(&errSbrMsg("for partitoning 'set=".$par{"fileSet"}."', you also have to specify:\n".
		      "either the number of proteins per set: 'nprot=N'\n".
		      "or     the number of set             : 'nset=M'\n"))
	if ($par{"fileSet"} && ! $par{"nset"} && ! $par{"nprot"});

				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
	$par{"$kwd"}.="/"       if ($par{"$kwd"} !~ /\/$/);}

				# ------------------------------
				# output files
				# ------------------------------
    ($Lok,$msg)=
	&iniFileout();          return(&errSbrMsg("failed naming output files",$msg)) if (! $Lok);
    
				# ------------------------------
				# correct settings
				# ------------------------------
    $par{"do_len"}=0            if ($par{"fileSet"});
    
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

				# ------------------------------
				# logical problems
				# ------------------------------
    if (! $par{"do_res"} && $par{"modeRoot"} eq "res"){
	$tmp= "*** $scrName has problems with the parameter choices!\n";
	$tmp.="The mode of the rooting was chosen to be=".$par{"modeRoot"}."\n";
	$tmp.="However, you have not switched on the explicit check of resolution:\n";
	$tmp.="   'do_res=1' \n";
	$tmp.="If you provide this argument on the command line, make sure the resolution\n";
	$tmp.="is given in the input file (of pairs)!\n";
	$tmp.="\n";
	$tmp.="Or: choose a different modeRoot=small|large (according to family size)\n";
	return(&errSbr($tmp,$SBR));}

                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0) {
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($Lverb2);
	if (0 && -e $par{"fileOutTrace"}){ # xx get out the 0
	    $LfileOutTrace_warningAppended=1;
	    &open_file("$fhTrace",">>".$par{"fileOutTrace"}) || 
		return(&errSbr("failed creating trace : ".$par{"fileOutTrace"},$SBR));} 
	else {
	    &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
		return(&errSbr("failed creating trace : ".$par{"fileOutTrace"},$SBR));}}
    else {
	$fhTrace="STDOUT";}
    $fhTrace2=$fhTrace;
    $fhTrace2="STDOUT"          if ($Lverb2 || $par{"debug"}); # note: trace2 = trace for dbg wrt!!
    $#kwdRm=0;
				# ------------------------------
				# write settings
				# ------------------------------
    $exclude="kwd,dir*,ext*";	# keyword not to write
    $fhloc="STDOUT";
    $fhloc=$fhTrace             if (! $par{"debug"} && ! $par{"verb2"});
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
                                # d.d
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/";
    $par{"dirPerl"}=            $par{"dirHome"}. "perl/" # perl libraries
        if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $par{"dirPerl"}. "scr/"; # perl scripts needed
    $par{"dirBin"}=             "/home/rost/pub/phd/bin/"; # FORTRAN binaries of programs needed

    $par{"dirOut"}=            ""; # directory for output files
    $par{"dirWork"}=           ""; # working directory
#    $par{""}=                   "";
                                # further on work
				# --------------------
				# files
    $par{"title"}=              "UNIQUE";                        # output files may be called 'Pre-title.ext'
    $par{"titleTmp"}=           "XUNIQUE";                    # title for temporary files

    $par{"fileOut"}=            "unk";
#    $par{"fileOutTrace"}=       $par{"titleTmp"}."-TRACE"."jobid".".tmp";  # tracing some warnings and errors
    $par{"fileOutTrace"}=       $par{"titleTmp"}."-TRACE". ".tmp";  # tracing some warnings and errors

    $par{"fileOutOk"}=          ""; # ids included in unique list
    $par{"fileOutNo"}=          ""; # ids excluded from unique list
    $par{"fileOutErr"}=         ""; # write ids with errors (neither ok nor not)
    $par{"fileOutWarn"}=        ""; # write warnings: things to check
    $par{"fileOutCluster"}=     ""; # write the entire family clusters
    $par{"fileOutRes"}=         ""; # write unique set + length + resolution

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
#    $par{""}=                   "";

    $par{"fileIncl"}=           "unk"; # file with proteins to include (header '# include')
    $par{"fileExcl"}=           "unk"; # file with proteins to include (header '# exclude')

				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".tmp";
    $par{"extOut"}=             ".dat";
				# file handles
#    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";

                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=$Lverb=     1; # blabla on screen
    $par{"verb2"}=$Lverb2=      0; # more verbose blabla
    $par{"verbDbg"}=            1; # debug write

    $par{"optNice"}=            "nice -15";
#    $par{""}=                   "";
				# --------------------
				# parameters
    $par{"do_len"}=             1; # check for length of protein   
				   #     NOTE: must be column in file pairs
    $par{"do_res"}=             1; # check for resolution of protein
				   #     NOTE: must be column in file pairs
    $par{"do_res"}=             0; # check for resolution of protein
    $par{"do_dis"}=             1; # check for distance (if 0: all pairs in file taken!!)
				   #     NOTE: must be column in file pairs
    $par{"minDis"}=             0; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
#    $par{"minDis"}=            -3; # minimal distance from HSSP(new) curve (-3 -> at least 27%)

    $par{"minRes"}=           2.5; # if resolution below this, do NOT replace bigger cluster
				   #    with higher resolution by smaller cluster and lower res!

    $par{"maxRes"}=        1198.0; # default if no resolution reported in PDB
				   #    
    $par{"minLen"}=            50; # if length above this, do NOT replace bigger cluster
				   #    with shorter protein by smaller cluster with longer protein
    $par{"wrtFamilySize"}=      1; # if 1, a file with the sorted sizes of all clusters is
				   #       written
				   #    note: sorting according to how the algorithm proceeds,
				   #          i.e. obeying the hierarchy imposed by the file
				   #          'fileInclude'
    $par{"wrtRes"}=             1; # if 1, a file with the sorted resolution of all in the final
				   #       unique set is written written

    $par{"modeRoot"}=          ""; # mode of rooting the optimisation
				# The following modes are implemented:
				# (1) 'large' : the largest families have precedence 
				#             -> no sequence-space-hopping in final set!
				# (2) 'small' : the smallest families have precedence
				#             -> good for sequence-space-hopping and for
				#                an optimal variety in the final set
				# (3) 'res'   :  better structures have precedence
				#             -> best in terms of 'good' structures      
    $par{"modeRoot"}=           "res";
    $par{"modeRoot"}=           "small";
    $par{"modeRoot"}=           "large";

    $par{"fileSet"}=            0; # list of proteins to use for partitioning
    $par{"nprot"}=              0; # number of proteins to end up in each partition
    $par{"nset"}=               0; # number of final partitions (sets)
    $par{"doSetHopp"}=          1; # joins all cluster that can be reached by infinite hopping
				# --------------------
				# executables
    $par{"exe"}=                "";
#    $par{""}=                   "";


    $SEP=                       "\t"; # separation of columns in output files

}				# end of iniDef

#===============================================================================
sub iniLib {
#    local(%parLoc)=@_;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniLib                       
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniLib";
    $par{"dirPerl"}=            "/home/rost/perl/"; # directory for perl scripts needed
    $dir=0;			# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/)   {$dir=$1;}
	elsif ($arg=~/ARCH=(.*)$/)     {$ARCH=$1;}
	elsif ($arg=~/PWD=(.*)$/)      {$PWD=$1;}
	elsif ($arg=~/^packName=(.*)/) { $par{"packName"}=$1; 
					 shift @ARGV if ($ARGV[1] eq $arg); }  }

    $ARCH=$ENV{'ARCH'}         if (! defined $ARCH && defined $ENV{'ARCH'});
    $PWD= $ENV{'PWD'}          if (! defined $PWD  && defined $ENV{'PWD'}); 
    $PWD=~s/\/$//              if ($PWD=~/\/$/);
    $pwd= $PWD                 if (defined $PWD);
    $pwd.="/"                  if (defined $pwd && $pwd !~ /\/$/);
    $dir=$dir || "/home/rost/perl/" || $ENV{'PERLLIB'} || 
	$par{"dirPerlLib"} || $par{"dirPerlLib"} || $par{"dirPerl"};
    $dir.="/"                  if (-d $dir && $dir !~/\/$/);
    $dir= ""                   if (! defined $dir || ! -d $dir);
# 				# ------------------------------
# 				# include perl libraries
#     foreach $lib("lib-ut.pl","lib-br.pl"){
# 	require $dir.$lib ||
# 	    die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}

}				# end of iniLib

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
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);


    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help

    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}="";
    $tmp{"special"}.=        "input,file,nohopp,";
    $tmp{"special"}.=        "verb,verb2,";

    $tmp{"special"}.=        "res,";
    

    $tmp{"special"}.=        "nodis".","                if (! $par{"do_dis"});
    $tmp{"special"}.=        "nores".","                if (! $par{"do_res"});
    $tmp{"special"}.=        "nolen".","                if (! $par{"do_len"});
    $tmp{"special"}.=        "dis".","                  if (  $par{"do_dis"});
    $tmp{"special"}.=        "res".","                  if (  $par{"do_res"});
    $tmp{"special"}.=        "len".","                  if (  $par{"do_len"});

    $tmp{"special"}.=        "noDbg".","                if (  $par{"verbDbg"});
    $tmp{"special"}.=        "verbDbg".","              if (! $par{"verbDbg"});
    $tmp{"special"}.=        "wrtRes".",";
    $tmp{"special"}.=        "wrtCluster".","           if (! $par{"wrtFamilySize"});
    $tmp{"special"}.=        "nowrtCluster".","         if (  $par{"wrtFamilySize"});
        
    $tmp{"large"}=           "OR modeRoot=large, root optimisation by largest family";
    $tmp{"small"}=           "OR modeRoot=small, root optimisation by smallest family";
    $tmp{"res"}=             "OR modeRoot=res,   root optimisation by best structure";

    $tmp{"nodis"}=           "OR do_dis=0,       NO check of distance";
    $tmp{"dis"}=             "OR do_dis=1,       do check of distance";
    $tmp{"nolen"}=           "OR do_len=0,       NO check of length";
    $tmp{"len"}=             "OR do_len=1,       do check of length";
    $tmp{"nores"}=           "OR do_res=0,       NO check of resolution";
    $tmp{"res"}=             "OR do_res=1,       do check of resolution\n";
    $tmp{"res"}.=            "OR res=fileRes     to give file with resolution resolution";

    $tmp{"nohopp"}=          "OR doSetHopp=0,    no hopping to join clusters\n";
    $tmp{"nohopp"}.=         "   e.g. A sim B, A NOT sim C, B sim C => A and C in separate sets\n";
    $tmp{"nohopp"}.=         "   NOT entirely true, since ONE hopp allowed anyway!";

    $tmp{"wrtCluster"}=      "OR wrtFamilySize=1 -> write family sizes into file";
    $tmp{"nowrtCluster"}=    "OR wrtFamilySize=0 -> not write family sizes into file";
    $tmp{"wrtRes"}=          "OR wrtRes=1        -> write file with final set sorted by resolution";
#    $tmp{""}=             "OR =1,   i.e. ";

    $tmp{"verbDbg"}=         "OR verbDbg=1,  detailed debug info (not automatic)";
    $tmp{"noDbg"}=           "OR verbDbg=0,  no debug info";
#                            "------------------------------------------------------------\n";

    $tmp{"file"}=            "--- Explicitly ex|including proteins: (help file)\n";
    $tmp{"file"}.=           "--- * excluding file with:\n";
    $tmp{"file"}.=           "1       # exclude' \n";
    $tmp{"file"}.=           "2       name1\t anything       # anything = e.g. '# comment why\n";
    $tmp{"file"}.=           ".       nameN\t anything  \n";
    $tmp{"file"}.=           ".        \" \t     \"  \n";
    $tmp{"file"}.=           "---   \n";
    $tmp{"file"}.=           "--- * including file with:\n";
    $tmp{"file"}.=           "1      # include 1             # or other integer < 0 \n";
    $tmp{"file"}.=           "2      name1\t  comment why\n";
    $tmp{"file"}.=           ".      nameN\t  comment why\n";
    $tmp{"file"}.=           ".        \" \t     \"  \n";
    $tmp{"file"}.=           ".      # include -1 \n";
    $tmp{"file"}.=           ".      nameM\t  comment why\n";
    $tmp{"file"}.=           ".      # include -2'\n";
    $tmp{"file"}.=           ".        \" \t     \"  \n";
    $tmp{"file"}.=           "---   \n";
    $tmp{"file"}.=           "---    -> HARD included all after line '# include 1'\n";
    $tmp{"file"}.=           "---       then: all those with -1 , -2, ...\n";
    $tmp{"file"}.=           "---       That is: do cluster size within each class (1,-1,-2,...).  \n";
    $tmp{"file"}.=           "---       Thus proteins with -2 included even if smaller family than -1!\n";
    $tmp{"file"}.=           "---       included if smaller family than -1!\n";
    $tmp{"file"}.=           "---       Note: the inclusion is hierarchical: first in file=higher priority\n";

    $tmp{"input"}=           "--- To generate the input file of pairs, do:\n";
    $tmp{"input"}.=          "--- (1)  run BLAST on a list of fasta files, e.g.: \n";
    $tmp{"input"}.=          "---      > blastRun.pl file.list|*.f filter db=phd\n";
    $tmp{"input"}.=          "--- (2)  run the post-processing on the output.rdb, e.g.: \n";
    $tmp{"input"}.=          "---      > blastProcessRdb.pl blast*.rdb pdb\n";
    $tmp{"input"}.=          "--- (3)  run $scrName on the output of 2 (Outpairs*)\n";
    $tmp{"input"}.=          "--- \n";

    $tmp{"set"}=             "--- To generate partitions (train|val|test) from the unique list, do:\n";
    $tmp{"set"}.=            "---  \n";
    $tmp{"set"}.=            "---  \n";
    $tmp{"set"}.=            "---  \n";

#                            "------------------------------------------------------------\n";

    return(%tmp);
}				# end of iniHelpNet

#===============================================================================
sub iniFileout {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniFileout                  assigns names for all output files
#       in/out GLOBAL:          all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="iniFileout";             $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;


    $fileOut=  $par{"fileOut"};
    if (! defined $fileOut || ! $fileOut || length($fileOut)<1){
	$fileOut=$par{"fileOut"}=$par{"dirOut"}.$par{"title"}.$par{"extOut"}; }

				# ------------------------------
				# for making the unique list
				# ------------------------------
    if (! $par{"fileSet"}) {
	foreach $kwd ("fileOutOk","fileOutNo",
		      "fileOutErr","fileOutWarn",
		      "fileOutCluster","fileOutRes") {
				# already named: skip
	    next if (defined $par{"$kwd"} && $par{"$kwd"} && length($par{"$kwd"}) > 1);

				# build up name from title
	    $kwd2=$kwd; $kwd2=~s/^fileOut//; $kwd2=~tr/[A-Z]/[a-z]/;
	    $tmp="-".$kwd2.".list"        if ($kwd=~ /Ok|No/);
	    $tmp="-".$kwd2.$par{"extOut"} if ($kwd=~ /Err|Warn|Cluster|Res/);
	    $par{"$kwd"}=$par{"dirOut"}.$par{"title"}.$tmp; }}
				# ------------------------------
				# for partitions of unique
				# ------------------------------
    else {
	foreach $kwd ("fileOutWarn","fileOutStat","fileOutPair","fileOutSet","fileOutFam") {
				# already named: skip
	    next if (defined $par{"$kwd"} && $par{"$kwd"} && length($par{"$kwd"}) > 1);

				# build up name from title
	    $kwd2=$kwd; $kwd2=~s/^fileOut//; $kwd2=~tr/[A-Z]/[a-z]/;
	    $tmp="-".$kwd2.".list"        if ($kwd=~ /Set/);
	    $tmp="-".$kwd2.$par{"extOut"} if ($kwd=~ /Warn|Stat|Pair|Fam/);
	    $par{"$kwd"}=$par{"dirOut"}.$par{"title"}.$tmp; }}
    return(1,"ok $SBR");
}				# end of iniFileout

#===============================================================================
sub bynumberLoc { 
    $[ =1 ;
#-------------------------------------------------------------------------------
#   bynumberLoc                 function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumberLoc

#===============================================================================
sub bynumber_high2lowLoc { 
    $[ =1 ;
#-------------------------------------------------------------------------------
#   bynumber_high2lowLoc        function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2lowLoc

#===============================================================================
sub cleanUp {
    local($SBR,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    $SBR="cleanUp";
    if ($#kwdRm>0){		# remove intermediate files
	foreach $kwd (@kwdRm){
	    next if (! defined $file{"$kwd"} || ! -e $file{"$kwd"});
	    print "--- $SBR unlink '",$file{"$kwd"},"'\n" if ($Lverb2);
	    unlink($file{"$kwd"});}}
    if (0){			# yy
	foreach $kwd ("fileOutTrace"){
	    next if (! defined $par{"$kwd"} || ! -e $par{"$kwd"});
	    print "--- $SBR unlink '",$par{"$kwd"},"'\n" if ($Lverb2);
	    unlink($par{"$kwd"});} }
}				# end of cleanUp

#===============================================================================
sub dataReduce {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dataReduce                  reducing memory by skipping:
#                               1st: all pairings with proteins not in list1 (id1)
#       in/out GLOBAL:          all
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="dataReduce";
				# --------------------------------------------------
				# 2nd: remove all pairings not in list 1
				# --------------------------------------------------
    $#tmp_id2=$#tmp_id2num=$#tmp_dis=$#tmp_disnum=0;
    foreach $idnum (1..$#id1ptr) {
	$id1=$id1ptr[$idnum];
				# ------------------------------
				# is excluded already
	next if (! defined $id1ptr{$id1});
				# ------------------------------
				# check family

	if (defined $ra_family[$idnum]){
	    $ref=$ra_family[$idnum];
	    $#tmp_id2=$#tmp_id2num=0;
	    foreach $tmp (@{$ref}){
		push(@tmp_id2num,$tmp); 
		push(@tmp_id2,$id2ptr[$tmp]); 
	    }}
	if ($par{"do_dis"} && defined $ra_dis[$idnum]){
	    $ref=$ra_dis[$idnum];
	    $#tmp_dis=$#tmp_disnum=0;
	    foreach $tmp (@{$ref}){
		push(@tmp_disnum,$tmp); 
		push(@tmp_dis,$id2ptr[$tmp]); 
	    }}
				# set 0
	$#tmp_oknum=$#tmp_okdis=0;
				# self
	push(@tmp_oknum,$idnum);
	push(@tmp_okdis,$idnum) if ($par{"fileSet"} && $par{"do_dis"});
	
	foreach $it (1..$#tmp_id2) {
	    $id2=$tmp_id2[$it];
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if id2 to exclude
	    if (! defined $id1ptr{$id2}) {
		undef $id2ptr{$id2};
		next; }
				# --------------------
				# build up array for 2
	    push(@tmp_oknum,$id2ptr{$id2}); 
				# only needed for partioning task
	    push(@tmp_okdis,$dis) if ($par{"fileSet"} && $par{"do_dis"});
	}

				# ******************************
				# the real big data comes!!!
	my(@tmp)=          @tmp_oknum;
# correct br 2000-01
#	$num[$ctId1]=      $#tmp_oknum;
#	$ra_family[$ctId1]=\@tmp;
	$num[$idnum]=      $#tmp_oknum;
	$ra_family[$idnum]=\@tmp;
	
	if ($par{"fileSet"} && $par{"do_dis"}) { 
	    my(@tmpDis)=@tmp_okdis;
# correct br 2000-01
#	    $ra_dis[$ctId1]=\@tmpDis; 
	    $ra_dis[$idnum]=\@tmpDis; 
	}
				# ******************************
    }

	
    return(1,"ok $SBR");
}				# end of dataReduce

#===============================================================================
sub fileExclRd {
    local($fileInLoc) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    my(%tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileExclRd                  reads file with names to ex|include
#       in:                     $fileInLoc
#       out:                    1|0,msg,$rh_array->{idnum}=position
#                               i.e. the position (line number) of id in the file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="fileExclRd";          $dbg=$SBR;$dbg=~s/^.*\///g; $dbg="dbg $dbg:";
    $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# 
    if ($par{"verbDbg"}) {
	print $fhTrace2 "dbg ","-" x 60,"\n";
	print $fhTrace2 "$dbg \n";}

    undef %tmp;
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=0;			# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty
	++$ct;			# count ok lines
				# read only first column
	$_=~s/^(\S+)[\s\t]*.*$/$1/g;
	$id=$_;
	$tmp{$id}=$ct;

	print $fhTrace2 "$dbg hard exclude $id, $ct\n" if ($par{"verbDbg"});

    } close($fhinLoc);
    return(1,"ok $SBR",\%tmp);
}				# end of fileExclRd

#===============================================================================
sub fileInclRd {
    local($fileInLoc) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    my(@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileInclRd                  reads file with names to include
#                FORMAT:        
#                               # include 1
#                               # BLABLA
#                               idA     # comment
#                               idB     # comment
#                               # include -1 (after 1)
#                               # BLABLA
#                               idA     # comment
#                               idB     # comment
#                               # include -2 (after -1)
#                               # BLABLA
#                               idA     # comment
#                               idB     # comment
#
#       in GLOBAL:              $id1ptr{}
#
#       in:                     $fileInLoc
#       out:                    1|0,msg,
#                               $string_level= "1,-2,-5" : levels read
#                               $level_ra[idnum]= level of inclusion (1,0=include,-1,-2...)
#                  dormant      $rh_array->{id}=position (line number) of id in the file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="fileInclRd";          $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;
    $dbg=$SBR; $dbg="dbg $dbg:";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# 
    if ($par{"verbDbg"}) {
	print $fhTrace2 "dbg ","-" x 60,"\n";
	print $fhTrace2 "$dbg \n";}

    undef @tmp;

				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=0;			# 
    $level=1;			# default: if no level given: =1
    $levelRd="";		# all levels: '1,-1,..'

				# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
				# digest level
	if ($_=~/^\# incl[a-z]*[\s\t]+[^\-\d]*([\-\d]+)/){
	    $level=$1;
	    $levelRd.="$level,";
	    next;}
				# skip other comments
	next if ($_=~/^[\s\t]*\#/);
	next if (length($_)==0); # skip empty

	++$ct;			# count ok lines
	
	$_=~s/\#.*$//g;		# skip comments in line
				# read only first column
	$_=~s/^(\S+)[\s\t]*.*$/$1/g;
	$id=$_;
				# skip if not in pair list
	next if (! defined $id1ptr{"$id"});
	$idnum=$id1ptr{"$id"};

#	$tmp{$id}=$ct;		# hierarchy: first = higher priority
	$tmp[$idnum]=$level;	# level

	printf $fhTrace2 
	    "$dbg num=%5d %-6s, level=%2d\n",$idnum,$id,$level if ($par{"verbDbg"});

    } close($fhinLoc);
    return(1,"ok $SBR",$levelRd,\@tmp);
}				# end of fileInclRd

#===============================================================================
sub filePairsRd {
    local($fileInLoc) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   filePairsRd                 read all the pair information
#       in:                     $fileInLoc
#       out GLOBAL:
#                   pointers                                   
#                               $id1ptr{"$id"}= $ctId1    i.e. id to number
#                               $id1ptr[$ctId1]=$id       i.e. number to id
#                       data                                                    
#                               $len[$ctId1] length of ctId1                            
#                               $res[$ctId1] resolution of ctId1                        
#                               $num[$ctId1] number of homologues to ctId1              
#                               $ra_family[$ctId1]->[1..n] reference to @id2[1..$num[$ctId1]],
#                                   i.e., all proteins homologous to ctId1
#                                   note: $id2[it] gives the number referring to id2 
#                                         id2=$id2ptr[$id2[it]]
#               if partition    $ra_dis[$ctId1]->[1..n] distances for homologues
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="filePairsRd";         $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;
    
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

    undef %ptr;
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ctline=0;
				# --------------------------------------------------
    while (<$fhinLoc>) {	# read file
				# --------------------------------------------------
				# skip comments
	++$ctline;
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty
				# ------------------------------
				# names
				# ------------------------------
	if ($_=~/^id[12]?[\s\t]+/){ 
	    @tmp=split(/[\t\s]+/,$_); 
	    foreach $tmp(@tmp){$tmp=~s/\s//g;} # purge blanks
	    foreach $it (1..$#tmp){
		if    ($tmp[$it]=~/^id1/){ $ptr{"id1"}=$it; }
		elsif ($tmp[$it]=~/^id2/){ $ptr{"id2"}=$it; }
		elsif ($tmp[$it]=~/^len/){ $ptr{"len"}=$it; }
		elsif ($tmp[$it]=~/^res/){ $ptr{"res"}=$it; }
		elsif ($tmp[$it]=~/^dis/){ $ptr{"dis"}=$it; } }
	    next; }
				# ------------------------------
				# data
				# ------------------------------
	$rd=$_;
	@tmp=split(/[\t\s]+/,$_); 
	foreach $tmp(@tmp){$tmp=~s/\s//g;} # purge blanks

				# --------------------
				# get columns

	$id1=$tmp[$ptr{"id1"}];	# 1st name
	return(&errSbr("filePairs=$fileInLoc, no id1 line=",$rd,"\n")) if (! defined $id1);

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if id1 explicitly to exclude
	if (defined $rh_excl->{$id1}) {
	    print "dbg NOTE $SBR: exclude id1=$id1 (since explicitly to exclude!)\n"
		if ($par{"verbDbg"});
	    next;}
				# skip if id1 without chain explicitly to exclude
	if (length($id1)>4 && defined $rh_excl->{substr($id1,1,4)}){
	    print "dbg NOTE $SBR: exclude id1=$id1 (since explicitly to exclude no chain!)\n"
		if ($par{"verbDbg"});
	    next;}
				# skip if id1 not in set to partition
	if ($par{"fileSet"} && ! defined $set{$id1}){
	    print "dbg NOTE $SBR: exclude id1=$id1 (since NOT in set)\n" 
		if ($par{"verb2"});
	    next;}
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

				# 2nd name (list)
	undef $id2List;		# (may be empty)
	$id2List=$tmp[$ptr{"id2"}];

	if ($par{"do_len"}){	# length
	    $len=$tmp[$ptr{"len"}];
	    return(&errSbr("filePairs=$fileInLoc, no len line $ctline=",$rd,"\n")) 
		if (! defined $len);}
	if ($par{"do_res"}){	# resolution
	    if (defined $resolution{$id}){
		$res=$resolution{$id};}
	    else {
		$res=$tmp[$ptr{"res"}];}
	    return(&errSbr("filePairs=$fileInLoc, no res line $ctline=",$rd,"\n")) 
		if (! defined $res);}
	if ($par{"do_dis"}){	# distance from threshold
	    undef $disList;	# (may be empty)
	    $disList=$tmp[$ptr{"dis"}]; }

				# --------------------
				# build up arrays
	if (! defined $id1ptr{$id1}){
	    ++$ctId1;
	    $id1ptr{$id1}=$ctId1; # pointer: id to number
	    $id1ptr[$ctId1]=$id1;   # pointer: number to id
	    $len[$ctId1]=$len   if ($par{"do_len"});
	    $res[$ctId1]=$res   if ($par{"do_res"}); }

				# --------------------
				# now: go through list
	$#tmp_id2=$#tmp_dis=$#tmp_oknum=$#tmp_okdis=0;
	if (defined $id2List){
	    $id2List=~s/,*$//g; @tmp_id2=split(/,/,$id2List); }
	if ($par{"do_dis"} && defined $disList){
	    $disList=~s/,*$//g; @tmp_dis=split(/,/,$disList); }
	foreach $it (1..$#tmp_id2) {
	    $id2=$tmp_id2[$it];
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if id2 to exclude
	    next if (defined $rh_excl->{$id2});
				# skip if id2 not in set to partition
	    next if ($par{"fileSet"} && ! defined $set{$id2});

				# check for distance
	    if ($par{"do_dis"}){
		$dis=$tmp_dis[$it];
		exit if (! defined $dis);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if too far away
		next if ($dis < $par{"minDis"}); }
				# --------------------
				# build up array for 2
	    if (! defined $id2ptr{$id2}) {
		++$ctId2;
		$id2ptr{$id2}=$ctId2; # pointer: id to number
		$id2ptr[$ctId2]=$id2; # pointer: number to id
	    }

	    push(@tmp_oknum,$id2ptr{$id2}); 
				# only needed for partioning task
	    push(@tmp_okdis,$dis) if ($par{"fileSet"} && $par{"do_dis"});
	}

				# ******************************
				# the real big data comes!!!
	my(@tmp)=          @tmp_oknum;
	$num[$ctId1]=      $#tmp_oknum;
	$ra_family[$ctId1]=\@tmp;

	if ($par{"fileSet"} && $par{"do_dis"}) { 
	    my(@tmpDis)=@tmp_okdis;
	    $ra_dis[$ctId1]=\@tmpDis; }
				# ******************************
	print $fhTrace2 "rdpairs id=$id1, num=$ctId1, family=$num[$ctId1]\n"
	    if ($par{"verbDbg"});

    } close($fhinLoc);
    $#tmp_id2=$#tmp_dis=$#tmp_oknum=$#tmp_okdis=0; # slim-is-in!

    return(1,"ok $SBR");
}				# end of filePairsRd

#===============================================================================
sub fileResRd {
    local($fileInLoc) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileResRd                   reads the file with PDB resolution 
#                               expected format 'id' 'resolution'
#       in/out GLOBAL:          all
#       out GLOBAL:             @set[1..number_of_proteins_wanted]=$id (!) of wanted
#       out GLOBAL:             $set{$id}=1 if $id in @set
#       in:                     $fileInLoc: file with ids sorted as you wish
#                                           them in the end 
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="fileResRd";             $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;
    $dbg=$SBR; $dbg="dbg $dbg:";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# 
    if ($par{"verbDbg"}) {
	print $fhTrace2 "dbg ","-" x 60,"\n";
	print $fhTrace2 "$dbg \n";}

				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=0;			# 
#    $level=1;			# default: if no level given: =1
#    $levelRd="";		# all levels: '1,-1,..'
	
				# ------------------------------
				# read file
    undef %resolution;
    while (<$fhinLoc>) {	# 
	$_=~s/\n//g;
	next if ($_=~/^\#/);
	if ($_=~/^id/){
	    @tmp=split(/\s*\t\s*/,$_);
	    foreach $it (2..$#tmp){
		if ($tmp[$it]=~/^res/){
		    $ptr_res=$it;
		    last;}
	    }
	    next;}
	next if (length($_)==0); # skip empty
	@tmp=split(/\s*\t\s*/,$_);
	$id= $tmp[1];
	$res=$tmp[$ptr_res];
	$res{$id}=$res;
	$id=substr($id,1,4);
	$resolution{$id}=$res;
    } close($fhinLoc);
    return(1,"ok $SBR");
}				# end of fileResRd

#===============================================================================
sub fileSetRd {
    local($fileInLoc) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileSetRd                   reads the proteins for which set ought to be built
#       in/out GLOBAL:          all
#       out GLOBAL:             @set[1..number_of_proteins_wanted]=$id (!) of wanted
#       out GLOBAL:             $set{$id}=1 if $id in @set
#       in:                     $fileInLoc: file with ids sorted as you wish
#                                           them in the end 
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="fileSetRd";             $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;
    $dbg=$SBR; $dbg="dbg $dbg:";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# 
    if ($par{"verbDbg"}) {
	print $fhTrace2 "dbg ","-" x 60,"\n";
	print $fhTrace2 "$dbg \n";}

				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=0;			# 
#    $level=1;			# default: if no level given: =1
#    $levelRd="";		# all levels: '1,-1,..'
	
			# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
				# skip other comments
	next if ($_=~/^[\s\t]*\#/);
	next if (length($_)==0); # skip empty

	++$ct;			# count ok lines
	
	$_=~s/\#.*$//g;		# skip comments in line
				# read only first column
	$_=~s/^(\S+)[\s\t]*.*$/$1/g;
	$id=$_;
	$id=~s/\s|\,//g;	# skip spaces, commata
	next if (length($id)<2);

#	$idnum=$id1ptr{"$id"};
#	$tmp[$idnum]=$level;	# level

	printf $fhTrace2 "$dbg setrd id=%-6s\n",$id if ($par{"verbDbg"});
	push(@set,$id); 
	$set{$id}=1;

    } close($fhinLoc);
    return(1,"ok $SBR");
}				# end of fileSetRd

#===============================================================================
sub greedy {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy                      does the greedy search for largest subset
#                               for details about the algorithm: see greedy_doit
#                               
#                               the following options are triggering the rooting
#                               of the optimisation ($par{"modeRoot"}):
#                               
#                                (1) 'large' : the largest families have precedence     
#                                            -> no sequence-space-hopping in final set! 
#                                (2) 'small' : the smallest families have precedence    
#                                            -> good for sequence-space-hopping and for 
#                                               an optimal variety in the final set     
#                                (3) 'res'   :  better structures have precedence       
#                                            -> best in terms of 'good' structures      
#                               
#                               
#       in/out GLOBAL:          all
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="greedy";              $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;

				# set 0
    $#sort=0;			# $sort[1]=$idnum -> take idnum first
    $#ok=0;			# $ok[$idnum]     -> idnum already in @sort

				# ------------------------------
				# (1) sorting by family size
				#     out/in GLOBAL: @sort, @ok
				#     OBEY hiearchy of levels!
				# ------------------------------
    foreach $level (@levels,"all"){
	($Lok,$msg)=
	    &sortFeature($level); return(&errSbrMsg("failed sort on explicit include level=$level",
						    $msg,$SBR)) if (! $Lok); }
				# all there?
    ($Lok,$msg)=
	&sortAllThere();        return(&errSbrMsg("not all there after family size!",
						  $msg,$SBR)) if (! $Lok);

				# --------------------------------------------------
				# start all over again
    $#ok=0;			# $ok[$idnum]= 2  -> hard take (survivors 1)
				#            = 1  -> was in family 1, but better,
				#                    see whether there will be a better
				#                    if THAT comes up as family root!
				#            = 0  -> hard exclude as in family of 1
				#                    which was taken!
    $#why=0;			# $why[$idnum]    -> reason why excluded:
				#      =$kwd.$id  -> $id was 'better'
				#      $kwd= prev : came earlier in optimisation
				#          fam> : larger  family    (modeSort='large')
				#          fam< : smaller family    (modeSort='small')
				#          res< : better resolution (modeSort='small')
				#          good : the other was better
				# --------------------------------------------------

				# hard wire include=1
    foreach $idnum (@sort){
	$ok[$idnum]=2 if (defined $ra_incl_level->[$idnum] &&
			  $ra_incl_level->[$idnum] eq "1"); }
    
				# ------------------------------
				# (2) optimise by cluster size
				#     note: overriding:
				#     - resolution  (if do_res)
				#     - length      (if do_len)
				# ------------------------------
    ($Lok,$msg)=
	&greedy_doit();          return(&errSbrMsg("failed on do_it1",$msg,$SBR)) if (! $Lok);

    ($Lok,$msg)=
	&wrtDbgFin($fhTrace2);  return(&errSbrMsg("failed on wrtDbgFin",$msg,$SBR)) if (! $Lok);

				# ------------------------------
				# check whether some take twice
    $fh=$fhTrace2; $fh="STDOUT" if ($par{"verb2"});
    ($Lok,$msg)=
	&greedy_checkit($fh);   return(&errSbrMsg("failed on checkit",$msg,$SBR)) if (! $Lok);
				# warnings (things to check!)
    push(@wrtWarn,$msg)         if ($msg !~/^ok/);


    if ($par{"wrtFamilySize"}){
	($Lok,$msg)=
	    &wrtFamilySize();   return(&errSbrMsg("failed on wrtFamilySize",$msg,$SBR)) if (! $Lok);}

				# save memory
    $#sort=0;			# slim-is-in!

				# ------------------------------
				# all reached by direct links to
				# final unique set?
				# ------------------------------
    ($Lok,$msg)=
	&linkDirect();          return(&errSbrMsg("failed on linkDirect",$msg,$SBR)) if (! $Lok);

    return(1,"ok $SBR");
}				# end of greedy

#===============================================================================
sub greedy_checkit {
    my($fhSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy_checkit               checks whether all ok after doit
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="greedy_checkit";      $dbg=$SBR;
    $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;

				# --------------------------------------------------
				# loop over all proteins:
				#    largest clusters (or explicitly include) first
				# --------------------------------------------------
    $errWrt=$warnWrt="";

    foreach $idnum (1..$nid1){
	if (! $ok[$idnum]) {
	    if (defined $ra_incl_level->[$idnum] &&
		$ra_incl_level->[$idnum] eq "1") {
		$errWrt.=  sprintf("*** checkit: include=1 id1=%-6s ($5d), but excluded!\n",
				   $id1ptr[$idnum],$idnum);}
	    next; }

	foreach $it (1..$num[$idnum]) {
	    $id2num=$ra_family[$idnum]->[$it];
	    $id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	    next if (! defined $id1ptr{$id2});
				# pointer of id1 corresponding to homologue
	    $idnumFrom2=$id1ptr{$id2};
				# already treated!
	    next if (! $ok[$idnumFrom2]);
	    $id1=$id1ptr[$idnum];
				# different threshold here?
	    if ($par{"do_dis"}) {
		$warnWrt.= sprintf("-*- WARN checkit: 1=%-6s (%5d) 2=%-6s (%5d) both ok dis??\n",
				   $id1,$idnum,$id2,$idnumFrom2);
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# exclude it!!
		$ok[$idnum]=0;
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		next; }
				# ******************************
				# ERROR overlap but twice ok!
				# ******************************
	    $errWrt.=      sprintf("*** checkit: id1=%-6s (%5d) id2=%-6s (%5d) both ok? ".
				   "(2ndexcluded!)\n",
				   $id1,$idnum,$id2,$idnumFrom2);
	}
    }
    print $errWrt               if (length($errWrt)>1);	# xx
    
    print $fhSbr $warnWrt       if (length($warnWrt)>1);

				# xx warn & error
    return(0,$errWrt)           if (length($errWrt)>1);
    return(1,$warnWrt)          if (length($warnWrt)>1);
    return(1,"ok $SBR");
}				# end of greedy_checkit

#===============================================================================
sub greedy_doit {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy_doit                  do the optimisation: starting with largest clusters
#                               
#   procedure: 
#
#   DO loop MUE over family size (largest first) , family NUE=1,...,num[MUE]
#                    
#      if MUE already taken (ok=2):
#         erase all NUE (family members)
#         keep  MUE
#         
#      if MUE no homologues:
#         take  MUE (but with ok=1, may be it comes up somewhere else...
#                    note: this would be an ERROR!!!)
#         
#      if any homologue to MUE (NUE0) already included:   
#         keep  NUE0 (actually keep it)
#         erase MUE
#         erase all NUE except NUE0
#         
#      DO loop over NUE (all family members to MUE)   
#         
#         find NUE0 with best length AND OR best resolution
#         note: if length good but resolution bad, take only if the
#               resolution of NUE0 is at least not worse than that of MUE!
#         
#      if NUE0 has better resolution and ok length
#         OR NUE0 has better length and resolution not worse than MUE
#         take  NUE0
#         erase MUE
#         erase all NUE except NUE0
#      if none has better features than MUE:
#         take  MUE
#         erase all NUE
#                    
#   DONE      
#                               
#                               
#                               $ok[$idnum]= 2  -> hard take (survivors 1)
#                                          = 1  -> was in family 1, but better,      
#                                                  see whether there will be a better
#                                                  if THAT comes up as family root!  
#                                          = 0  -> hard exclude as in family of 1    
#                                                  which was taken!                  
#                               $why[$idnum]    -> reason why excluded:              
#                                    =$kwd.$id  -> $id was 'better'                  
#                                    $kwd= prev : came earlier in optimisation       
#                                          fam> : larger  family    (modeSort='large')
#                                          fam< : smaller family    (modeSort='small')
#                                          res< : better resolution (modeSort='small')
#                                          good : the other was better
#                               
#                               
#                               
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="greedy_doit";         $fhinLoc="FHIN_".$SBR;$fhoutLoc="FHIN_".$SBR;
    $dbg=$SBR; $dbg="dbg ".$dbg.":";

    $dbgLineNew="$dbg "."-" x 60 ."\n"; 
    $dbgLineNew="\n";

    $len=$lenBest=0;
    $res=$resBest=0; 
    $fam=$famBest=0;
				# --------------------------------------------------
				# loop over all proteins:
				#    largest clusters (or explicitly include) first
				# --------------------------------------------------
    
    print $fhTrace2 "$dbg \n"   if ($par{"verbDbg"});

    foreach $idnum (@sort) {
				# ------------------------------
	$tmpWrt="";		# already taken: ERASE all homos!
	if (defined $ok[$idnum] && $ok[$idnum]==2) {
	    print $fhTrace2 "$dbg yy already defined ok for idnum=$idnum $id1ptr[$idnum]\n";
	    &ass1_eraseAll(0);	# also writes  to debug
	    next; }
				# ------------------------------
				# no homologues
	if (! $num[$idnum]) {
	    printf $fhTrace2 
		"$dbgLineNew"."$dbg take orphan idnum=%5d %-6s \n",
		$idnum,$id1ptr[$idnum] if ($par{"verbDbg"});
				# <<<<<<<<<< + + + + + + + + + +
	    $ok[$idnum]=1;	# TAKE id1
	    next; }		# <<<<<<<<<< + + + + + + + + + +
	
				# ------------------------------
				# any homologue taken?
	$idnumFrom2=
	    &ass2_oneAlready();
	    
	if ($idnumFrom2) { 
				# change it yy
				# erase only id1, keep all its homologues!
	    
#	    &ass1_eraseAll($idnumFrom2);

	    printf $fhTrace 
		"$dbgLineNew"."$dbg erase %5d %-6s as %5d %-6s before\n",
		$idnum,$id1ptr[$idnum],$idnumFrom2,$id1ptr[$idnumFrom2] if ($par{"verbDbg"});
				# <<<<<<<<<< - - - - - - - - - -
	    $ok[$idnum]=0;	# ERASE id1
				# excluded since better one!
	    &ass0_why($idnum,$idnumFrom2,"prev");
	    next; }
				# ------------------------------
				# check length and other features
				# ------------------------------

				# NOTE: only switch on if largest family does NOT
				#       fulfill the criteria !
	$len=$len[$idnum]       if ($par{"do_len"}   && $len[$idnum] < $par{"minLen"});
	$res=$res[$idnum]       if ($par{"do_res"} );
	$resCheck=1             if ($par{"do_res"}   && $res[$idnum] > $par{"minRes"});
	$resCheck=0             if (! $par{"do_res"} || $res[$idnum] <=$par{"minRes"});
	$fam=$num[$idnum]       if ($par{"modeRoot"} eq "res");

	$lenBest=$len; $resBest=$res;  $famBest=$fam;  $lenBestPos=$resBestPos=$famBestPos=$best=0;
	$#tmp=0;		# will hold the numbers (id2num) to re-consider in 
				#    round (2)

	printf $fhTrace2 
	    "$dbgLineNew"."$dbg precedence idnum=%5d %-s (l=%5d r=%5.1f)\n",
	    $idnum,$id1ptr[$idnum],$len,$res if ($par{"verbDbg"});

				# ------------------------------
				# round (1) get length + res for 
				#           all homologues to this protein
				# ------------------------------
	foreach $it (1..$num[$idnum]) {
	    $id2num=$ra_family[$idnum]->[$it];
	    $id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	    next if (! defined $id1ptr{$id2});
				# pointer of id1 corresponding to homologue
	    $idnumFrom2=$id1ptr{$id2};
				# already treated!
	    next if (defined $ok[$idnumFrom2]);
				# is it any better than id1?
	    $is_better=
		&ass3_precedence();
	    next if ($is_better);
	    printf $fhTrace2 "$dbg round 1 ERASE=%5d\n",$idnumFrom2 if ($par{"verbDbg"});

				# <<<<<<<<<< - - - - - - - - - -
	    $ok[$idnumFrom2]=0;	# ERASE id2 !!
				# excluded since 1 has larger family
	    &ass0_why($idnumFrom2,$idnum,"feature");}

				# ******************************
	if ($#tmp==0){		# no round (2) !!
	    print $fhTrace2 "$dbg round 2 none good take=$idnum\n" if ($par{"verbDbg"});

				# <<<<<<<<<< + + + + + + + + + +
	    $ok[$idnum]=2;	# TAKE id1
	    next; }
				# ------------------------------
				# round (2) get the best resolved, 
				#           longest homologue, instead!
				# ------------------------------
	$best=
	    &ass4_precedenceWin();

	foreach $idnumFrom2 (@tmp) {
	    next if ($idnumFrom2 == $best); # skip best
	    print $fhTrace2 "$dbg round 2 ERASE=$idnumFrom2\n" if ($par{"verbDbg"});

				# <<<<<<<<<< - - - - - - - - - -
	    $ok[$idnumFrom2]=0;	# ERASE id2 !!
				# excluded since best is better
	    &ass0_why($idnumFrom2,$best,"good"); }

	if ($idnum != $best) {	# <<<<<<<<<< - - - - - - - - - -
	    $ok[$idnum]=0;	# ERASE id1           !!!!!!!!!!
				# excluded since best is better
	    &ass0_why($idnum,$best,"good"); }

				# <<<<<<<<<< + + + + + + + + + +
	$ok[$best]=1;		# TAKE id2                 !!!!! 
	$ok[$best]=2            if ($idnum == $best);

	if ($par{"verbDbg"}) {
	    printf $fhTrace2 "$dbg round 3 take 2=%5d (%-s)   !!!\n",$best,$id1ptr[$best];
	    printf $fhTrace2 "$dbg round 3 ERASE1=%5d (%-s) !!!!!\n",$idnum,$id1ptr[$idnum]
		if ($best != $idnum);}
    }

    return(1,"ok $SBR");
}				# end of greedy_doit

#===============================================================================
sub ass0_why {
    local($idnumLoc,$idnumWinLoc,$reason) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ass0_why                    assigns value to @why
#       in/out GLOBAL:          all
#       in:                     $idnumLoc    : pointer to idnumber of excluded
#       in:                     $idnumWinLoc : pointer to idnumber of better one
#       in:                     $reason=
#                                   'feature' better because of family size|res
#                                   'prev'    other one include before!
#                                   'good'    other one was better 
#                                                (in non-sorting feature!)
#                                   ''
#                                   ''
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------

				# better because of family size|res
    if    ($reason eq "feature"){
	$why[$idnumLoc]="fam> ".$id1ptr[$idnumWinLoc] if ($par{"modeRoot"} eq "large");
	$why[$idnumLoc]="fam< ".$id1ptr[$idnumWinLoc] if ($par{"modeRoot"} eq "small");
	$why[$idnumLoc]="res< ".$id1ptr[$idnumWinLoc] if ($par{"modeRoot"} eq "res"); }
				# other one include before!
    elsif ($reason eq "prev"){
	$why[$idnumLoc]="prev ".$id1ptr[$idnumWinLoc];}
				# other one was better (in non-sorting feature)
    elsif ($reason eq "good"){
	$why[$idnumLoc]="good ".$id1ptr[$idnumWinLoc];}
    else {
	print 
	    "*** WARN $scrName:ass0_why: no good reason \n",
	    "***      $reason idnum=$idnumLoc, idnumWin=$idnumWinLoc)\n"; }
}				# end of ass0_why

#===============================================================================
sub ass1_eraseAll {
    local($idnumFrom2_excl) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ass1_eraseAll               erase all homologues
#       in:                     $idnumFrom2_excl = 0 -> really all
#                                                = N -> all except for N!
#       in/out GLOBAL:          all
#-------------------------------------------------------------------------------
    $SBR="ass1_eraseAll";

    $tmpWrt="";
				# ------------------------------
				# loop over entire family
				# ------------------------------
    foreach $it (1..$num[$idnum]) {
	$id2num=$ra_family[$idnum]->[$it];
	$id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	next if (! defined $id1ptr{$id2});
				# IS  in list of ID1 -> find ptr:
				#     pointer of id1 corresponding to homologue
	$idnumFrom2Loc=$id1ptr{$id2};
				# already treated!
	next if (defined $ok[$idnumFrom2Loc]);
				# IS  in list, but ought to be excluded (calling arg)
	next if ($idnumFrom2_excl && $idnumFrom2Loc == $idnumFrom2_excl);
	$tmpWrt.="$idnumFrom2Loc," if ($par{"verbDbg"});
				# <<<<<<<<<< - - - - - - - - - -
	$ok[$idnumFrom2Loc]=0;	# ERASE id2 !!

				# excluded since best is better
	&ass0_why($idnumFrom2Loc,$idnum,"feature")           if (! $idnumFrom2_excl);
	&ass0_why($idnumFrom2Loc,$idnumFrom2_excl,"feature") if (  $idnumFrom2_excl);
    }

				# ------------------------------
				# debug write
				# ------------------------------
    if ($par{"verbDbg"} && length($tmpWrt) > 0) {
	printf $fhTrace2 
	    "$dbgLineNew"."$dbg now idnum=%5d id1=%-s\n",$idnum,$id1ptr[$idnum];
	printf $fhTrace2 
	    "$dbg idnum=%5d already ok=%-1s -> ERASE all: %-s\n",
	    $idnum,$ok[$idnum],$tmpWrt       if (! $idnumFrom2_excl);
	printf $fhTrace2 
	    "$dbg idnum=%5d ERASE all (except %5d) %-s\n",
	    $idnum,$idnumFrom2_excl,$tmpWrt  if ($idnumFrom2_excl); }
}				# end of ass1_eraseAll

#===============================================================================
sub ass2_oneAlready {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ass2_oneAlready             erase all homologues
#       in/out GLOBAL:          all
#       out:                    idnumFrom2 of the one already ok
#-------------------------------------------------------------------------------
    $SBR="ass2_oneAlready";

    foreach $it (1..$num[$idnum]) {
	$id2num=$ra_family[$idnum]->[$it];
	$id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	next if (! defined $id1ptr{$id2});
				# pointer of id1 corresponding to homologue
	$idnumFrom2=$id1ptr{$id2};
				# already treated!
	return($idnumFrom2)     if (defined $ok[$idnumFrom2] && $ok[$idnumFrom2]==2);}
	    
    return(0);
}				# end of ass2_oneAlready

#===============================================================================
sub ass3_precedence {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ass3_precedence             checks the precedence: any in family 'better'?
#       in/out GLOBAL:          all
#       out:                    1 -> skip it for round 1, as seems better
#                               0 -> erase it, is junk
#-------------------------------------------------------------------------------
    $SBR="ass3_precedence";

    printf  $fhTrace2 
	"$dbg round 1 it=%3d id2num=%5d %-s\n",
	$it,$idnumFrom2,$id2    if ($par{"verbDbg"});

    $len2=$fam2=0; $res2=$par{"maxRes"};

				# ------------------------------
				# get features
    $res2=  $res[$idnumFrom2]   if ($resCheck && 
				    ($res[$idnumFrom2] < $par{"minRes"} || $res[$idnumFrom2] < $res) ); 
    $len2=  $len[$idnumFrom2]; 
    $fam2=  $num[$idnumFrom2]   if ($num[$idnumFrom2] > $famBest);
	
				# ------------------------------
				# hierarchy:
				# (1) resolution
				# (2) family size (for root=res)
				# (3) length

				# default assumption: it IS better
    $ok=1;
				# nothing if resolution worse !
    if ($resCheck){
	$ok=0 if ( $res2 == $par{"maxRes"} || $res2 > $res );
				# is better resolution: label it
	$ok=2 if ( $ok  && $res2 < $res );}
				# if resolution not to be checked, it must really be GOOD!
    elsif ($par{"do_res"}) {
	$ok=0 if ( $res2 > $par{"minRes"}  || $res2 > $res );}

				# for root = resolution: skip if family smaller
    $ok=0 if ($ok && $par{"modeRoot"} eq "res" &&
	      $fam2 < $fam);
				# do length only if resolution NOT better!
    $ok=0 if ($ok==1 && 
	      $len2 < $len);
				# ------------------------------
				# consider as better if either
				#    length or resolution or size good
    if ($ok){
	printf $fhTrace2
	    "$dbg round 1 GOOD len2=%4d res2=%5.1f idnum=%5d\n",
	    $len2,$res2,$idnumFrom2                    if ($par{"verbDbg"});

	if ($len2 > $lenBest) { $lenBest=$len2; $lenBestPos=$idnumFrom2;}
	if ($res2 < $resBest) { $resBest=$res2; $resBestPos=$idnumFrom2;}
	if ($fam2 < $resBest) { $famBest=$fam2; $famBestPos=$idnumFrom2;}
	push(@tmp,$idnumFrom2);
				# <<<<
	return(1);		# IS better!
    }

    return(0);			# means: was NOT better

}				# end of ass3_precedence

#===============================================================================
sub ass4_precedenceWin {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ass4_precedenceWin          determines the winner 
#                               (1) ass3_precedence may have found many
#                               (2) original may be somehow better than 'best'..
#       in/out GLOBAL:          all
#       out:                    idnum of winner!
#-------------------------------------------------------------------------------
    $SBR="ass4_precedenceWin";

				# simple 1: best = highest resolution
    if    (  ($resBestPos || $famBestPos) && ! $lenBestPos) {
	$bestLoc=$resBestPos; }

				# simple 2: best = longest
    elsif (! ($resBestPos || $famBestPos) &&   $lenBestPos) {
	$bestLoc=$lenBestPos; }

				# decision: best = highest resolution
				#               OR largest family
    elsif (  $resBestPos || $famBestPos ) {
	$bestLoc=($resBestPos || $famBestPos); }
				# none better than id1 ...
    else {
	$bestLoc=$idnum; }

    printf $fhTrace2 
	"$dbg looser idnum=%5d (%-6s) got best=%5d (%-6s) ok for that=%1s\n",
	$idnum,$id1ptr[$idnum],$bestLoc,$id1ptr[$bestLoc],("?"||$ok[$bestLoc]) 
	    if ($par{"verbDbg"});

    return($bestLoc);
}				# end of ass4_precedenceWin 

#===============================================================================
sub linkDirect {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok,@okLink);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   linkDirect                  checks whether or not in the final list all
#                               are reached by direct links
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="linkDirect";
    

    $#okLink=$ctLink=0;

    foreach $idnum (1..$nid1){
	next if (! defined $ok[$idnum] || ! $ok[$idnum]);
				# also count itself for orphans
	$okLink[$idnum]=1;
	++$ctLink;
				# ------------------------------
				# all homologues
	foreach $it (1..$num[$idnum]) {
	    $id2num=$ra_family[$idnum]->[$it];
	    $id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	    next if (! defined $id1ptr{$id2});
				# pointer of id1 corresponding to homologue
	    $idnumFrom2=$id1ptr{$id2};
				# also ok?
	    next if ($ok[$idnumFrom2]);
				# already connected
	    next if (defined $okLink[$idnumFrom2]);
	    $okLink[$idnumFrom2]=1;
	    ++$ctLink; }
    }
				# some are missing??
    if ($ctLink != $nid1){
	foreach $idnum (1..$nid1){
	    next if (defined $okLink[$idnum]);
				# yy
	    $tmpWrt=sprintf ("missing idnum=%5d %-6s\n",$idnum,$id1ptr[$idnum]); 
	    printf $fhTrace2 $tmpWrt;
	    push(@wrtWarn,$tmpWrt);
	}}
    elsif ($ctLink==1) {
	print "WATCH YA! all found in one link!\n";
    }

    return(1,"ok $SBR");
}				# end of linkDirect

#===============================================================================
sub partition {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   partition                   partitions proteins provided in file_set (@set) into 
#                               $par{"nset"} sets, or into sets with $par{"nprot"} proteins
#                               depending on which of the two is defined, higher
#                               priority: $par{"nset"}!
#                               
#                               For example: 
#                               - input list: A B C D E F G H I
#                               - similar:    AD AF
#                                             B
#                                             CH CI
#                                             EF
#                                             G
#                               - nprot:      4
#                               
#                               the following lists will be returned
#                               (1) A D F B
#                               (2) C H I    (no fourth because E+F come as pairs)
#                               (3) E F G
#                               
#                               -> you can train on 2+3, test on 1 ...
#                               
#       in/out GLOBAL:          all
#       out GLOBAL:             pushes to @fileOut !!!  (fileSet 1..$nset)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="partition";           $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;
    $dbg="dbg $SBR:";

				# ------------------------------
				# determine splitting numbers
				# ------------------------------
    undef $nprot;
    $nprot=$par{"nprot"}           if ($par{"nprot"});
    $nprot=int($#set/$par{"nset"}) if ($par{"nset"});
    return(&errSbr("the number of proteins per set should be > 0, and < ".$#set."\n".
		   "actually is=$nprot\n")) if ($#set < $nprot || $nprot < 0);

				# --------------------------------------------------
				# (0) re-defined distances (to avoid A-B, B-C A not C)
				# out GLOBAL:
				# --------------------------------------------------
    ($Lok,$msg)=
	&assp0_disPairs();     return(&errSbrMsg("failed to build up sets",$msg)) if (! $Lok);

				# --------------------------------------------------
				# (1) build up sets
				# ---> NOTE: here minDis is USED !!!
				# out GLOBAL:
				#    $set_id1[mue]=$id1, mue= all proteins in fileSet
				#    $set_id2{$id1}='id2A,id2B'
				#    $set_dis{$id1}='disA,disB'
				# --------------------------------------------------
    ($Lok,$msg)=
	&assp1_buildSet();      return(&errSbrMsg("failed to build up sets",$msg)) if (! $Lok);

				# --------------------------------------------------
				# (2) group all possible links
				# out GLOBAL:
				#    $set_hopp[$it]='idA,idB,idC'     
				#        all proteins for cluster $it 
				#    $nhopp=        number of clusters
				# --------------------------------------------------
    ($Lok,$msg)=
	&assp2_joinClusters();  return(&errSbrMsg("failed to join clusters",$msg)) if (! $Lok);
				# now we have nhopp big clusters each of which has
				#    all possible homologues to the root

				# --------------------------------------------------
				# (3) partition the clusters
				# out GLOBAL:
				#    $part[it]='idA,idB,'.. i.e. all in that set 
				#    $nset=         final number of sets         
				# --------------------------------------------------
    ($Lok,$msg)=
	&assp3_finalPartition();return(&errSbrMsg("failed on final partition",$msg)) if (! $Lok);

				# --------------------------------------------------
				# (4) verify: any of set I any match in any set J ?
				# out GLOBAL: $wrtWarn (sprintf ready to write)
				# --------------------------------------------------
    ($Lok,$msg)=
	&assp4_verify();        return(&errSbrMsg("failed on verification",$msg)) if (! $Lok);
    
				# ------------------------------
				# build up the final write out
				# out GLOBAL: $wrtStat, $wrtPair (sprintf ready to write)
    &partitionWrtBuild();
				# ------------------------------
				# debug write
    &partitionWrtDbg()          if ($par{"verbDbg"});
	
				# ------------------------------
				# write statistics
    ($Lok,$msg)=
	&partitionWrtStat($par{"fileOutStat"});
    return(&errSbrMsg("failed writing statistics (".$par{"fileOutStat"}.")",$msg,$SBR)) if (! $Lok);
		      
				# ------------------------------
				# write pairs
    ($Lok,$msg)=
	&partitionWrtPair($par{"fileOutPair"});
    return(&errSbrMsg("failed writing pairs (".$par{"fileOutPair"}.")",$msg,$SBR)) if (! $Lok);
		      
				# ------------------------------
				# write families
    ($Lok,$msg)=
	&partitionWrtFam($par{"fileOutFam"});
    return(&errSbrMsg("failed writing family (".$par{"fileOutFam"}.")",$msg,$SBR)) if (! $Lok);
		      
				# ------------------------------
				# write warn
    ($Lok,$msg)=
	&partitionWrtWarn($par{"fileOutWarn"});
    return(&errSbrMsg("failed writing warn (".$par{"fileOutWarn"}.")",$msg,$SBR)) if (! $Lok);

				# ------------------------------
				# write all sets
				# ------------------------------
    foreach $it (1..$nset) {
	$fileOutLoc=$par{"fileOutSet"};
	$tmp="0".$it            if ($nset >= 10 && $it < 10);
	$tmp=$it                if ($nset <  10 || $it >=10);
	$fileOutLoc=~s/(\-set)/$1$tmp/;
	push(@fileOut,$fileOutLoc);

	($Lok,$msg)=
	    &partitionWrtSet($fileOutLoc,$part[$it]);
	return(&errSbrMsg("failed writing set $it (".$fileOutLoc.")",$msg,$SBR)) if (! $Lok); }

    return(1,"ok $SBR");
}				# end of partition

#===============================================================================
sub assp0_disPairs {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assp0_disPairs              re-defined distances (to avoid A-B, B-C A not C)
#       in GLOBAL:              $set[1..num_proteins_in_fileSet]=$idnum
#       in GLOBAL:              $set{"$id"}=1 if $id to take
#       in GLOBAL:              $ra_family[$ctId1]->[1..n] reference to @id2[1..$num[$ctId1]],
#                                   i.e., all proteins homologous to ctId1
#                                   note: $id2[it] gives the number referring to id2 
#                                         id2=$id2ptr[$id2[it]]
#       in GLOBAL:              $ra_dis[$ctId1]->[1..n] reference to distances
#       out GLOBAL:             $set_id1[mue]=$id1, mue= all proteins in fileSet
#       out GLOBAL:             $set_id2{$id1}='id2A,id2B'
#       out GLOBAL:             $set_dis{$id1}='disA,disB'
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="assp0_disPairs";             $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;

    undef %dis;			# $dis{$id1,$id2}=max (D(id1,id2),D(id2,id1))

				# ------------------------------
				# (1) get em all
				# ------------------------------
    foreach $idnum (@set) {
	$id1=$id1ptr[$idnum];
	foreach $it (1..$num[$idnum]) {
				# pointer of id1 corresponding to homologue
	    $id2num=$ra_family[$idnum]->[$it];
	    $id2=   $id2ptr[$id2num];
				# ignore all that are not in SET (names in fileSet)
	    next if (! defined $set{$id2});
	    $dis=$ra_dis[$idnum]->[$it];
	    next if ($dis <= ($par{"minDis"} -3 ));
	    $dis{$id1,$id2}=$dis; }}

				# ------------------------------
				# (2) get maxima
				# ------------------------------
    foreach $it1 (1..$#set) {
	$idnum=$set[$it1];
	$id1=$id1ptr[$idnum];

	foreach $it2 (($it1+1)..$#set) {
	    $idnum2=$set[$it2];
	    $id2=$id1ptr[$idnum2];
				# none of the two
	    next if (! defined $dis{$id1,$id2} && ! defined $dis{$id2,$id1});

				# D(1,2) yes, D(2,1) not
	    if (defined $dis{$id1,$id2} && ! defined $dis{$id2,$id1}) {
		$dis{$id2,$id1}=$dis{$id1,$id2};
		next; }
				# D(1,2) not, D(2,1) yes
	    if (! defined $dis{$id1,$id2} && defined $dis{$id2,$id1}) {
		$dis{$id1,$id2}=$dis{$id2,$id1};
		next; }

	    next if ($dis{$id1,$id2} == $dis{$id2,$id1});

				# D(1,2) > D(2,1) 
	    if ($dis{$id1,$id2} > $dis{$id2,$id1}) {
		$dis{$id2,$id1}=$dis{$id1,$id2}; 
		next; }
				# D(1,2) < D(2,1) 
	    if ($dis{$id1,$id2} < $dis{$id2,$id1}) {
		$dis{$id1,$id2}=$dis{$id2,$id1};
		next; }
	}
    }

    return(1,"ok $SBR");
}				# end of assp0_disPairs

#===============================================================================
sub assp1_buildSet {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assp1_buildSet              build up sets
#       in GLOBAL:              $set[1..num_proteins_in_fileSet]=$idnum
#       in GLOBAL:              $set{"$id"}=1 if $id to take
#       in GLOBAL:              $ra_family[$ctId1]->[1..n] reference to @id2[1..$num[$ctId1]],
#                                   i.e., all proteins homologous to ctId1
#                                   note: $id2[it] gives the number referring to id2 
#                                         id2=$id2ptr[$id2[it]]
#       in GLOBAL:              $ra_dis[$ctId1]->[1..n] reference to distances
#       out GLOBAL:             $set_id1[mue]=$id1, mue= all proteins in fileSet
#       out GLOBAL:             $set_id2{$id1}='id2A,id2B'
#       out GLOBAL:             $set_dis{$id1}='disA,disB'
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="assp1_buildSet";             $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;

    undef @set_id1;		# $set_id1[mue]=$id1, mue= all proteins in fileSet
    undef %set_id2;		# $set_id2{$id1}='id2A,id2B'
    undef %set_dis;		# $set_dis{$id1}='disA,disB'

				# ------------------------------
				# loop over all names to take
				# ------------------------------
    foreach $idnum (@set) {
	$id1=$id1ptr[$idnum];
	push(@set_id1,$id1);	# from idnum -> id
	$#id2Loc=$#disLoc=0;
	foreach $it (1..$num[$idnum]) {
				# pointer of id1 corresponding to homologue
	    $id2num=$ra_family[$idnum]->[$it];
	    $id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	    next if (! defined $id1ptr{$id2});
				# ignore all that are not in SET (names in fileSet)
	    next if (! defined $set{$id2});
				# --------------------------------------------------
				# --> here comes minDis !
				# ignore in pair list if below distance threshold
	    next if ($par{"do_dis"} && $ra_dis[$idnum]->[$it] <= $par{"minDis"});
				# --> here came minDis !
				# --------------------------------------------------
	    push(@id2Loc,$id2); 
	    push(@disLoc,$ra_dis[$idnum]->[$it]) if ($par{"do_dis"}); }
	$set_id2{$id1}=join(',',@id2Loc);
	$set_dis{$id1}=join(',',@disLoc) if ($par{"do_dis"});
    }
    $#id2Loc=$#disLoc=0;	# slim-is-in

    return(1,"ok $SBR");
}				# end of assp1_buildSet

#===============================================================================
sub assp2_joinClusters {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assp2_joinClusters          groups all possible links (infinite hopping, i.e.
#                               infinite = until no further hopp possible)
#       in GLOBAL:              $set_id1[mue]= $id1, mue= all proteins in fileSet
#       out GLOBAL:             $set_hopp[$it]='idA,idB,idC'
#                                   all proteins for cluster $it
#       out GLOBAL:             $nhopp=        number of clusters
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="assp2_joinClusters";  
    
    undef %taken; 
    $#set_hopp=0; $ct_hopp=0;
				# --------------------------------------------------
				# loop over all proteins wanted in list
				# --------------------------------------------------
    $ctAll=0;
    foreach $id1 (@set_id1) {
				# skip if cluster already added
	next if (defined $taken{$id1});
	$taken{$id1}=1;
				# ------------------------------
				# now enlarge by hopping
				#    until no new cluster found
				# ------------------------------
	@hopp_one=($id1);	# first: id1
	@again=   ($id1);

	$ctDeepness=0;
				# add homologue and all its homologues
	while (@again) {	# until: no new family member found
	    $id_current=shift @again;
	    @id2Loc=split(/,/,$set_id2{$id_current});
	    next if ($#id2Loc==1 && 
		     ($id2Loc[1] eq $id_current || $id2Loc[1] eq "*"));
				# allow one level hopp
	    if (! $par{"doSetHopp"} && $id_current eq $id1) {
		undef %tmpHopp;
		foreach $id2Loc (@id2Loc) {
		    $tmpHopp{$id2Loc}=1; }}
	    ++$ctDeepness;

	    foreach $id2 (@id2Loc) {
		next if (defined $taken{$id2});
		$taken{$id2}=1;
		push(@hopp_one, $id2);
				# surpress hopping further
		next if (! $par{"doSetHopp"} && ! defined $tmpHopp{$id2});
				# hopp further
		push(@again,    $id2); 
	    } 
#	    print "xtmp id=$id_current, deep=$ctDeepness, NARRAYid2=",$#id2Loc,", tot=",$#hopp_one,",\n";
	}
	++$ct_hopp;
	$set_hopp[$ct_hopp]=join(',',@hopp_one);

	$ctAll+=$#hopp_one;
	printf $fhTrace2 
	    "--- dbg $SBR: id1=%-15s , ctAll=%5d numHopp_one=%5d\n",
	    $id1,$ctAll,$#hopp_one if ($par{"verbDbg"});
    }
    $nhopp=$ct_hopp;

    undef %taken;undef %tmpHopp; # slim-is-in!
    $#again=$#hopp_one=$#tmp=$#taken=0;	# slim-is-in
    
    return(1,"ok $SBR");
}				# end of assp2_joinClusters

#===============================================================================
sub assp3_finalPartition {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assp3_finalPartition        final partition of the clusters
#       in GLOBAL:              $set_hopp[$it]='idA,idB,idC' all proteins for cluster $it
#       in GLOBAL:              $nhopp=        number of clusters
#       out GLOBAL:             $part[it]='idA,idB,'.. i.e. all in that set
#       out GLOBAL:             $nset=         final number of sets         
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="assp3_finalPartition";             $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;

				# --------------------------------------------------
				# loop over all clusters
				# --------------------------------------------------
    $ctset=0;
    $#part=0;
    $#tmp=0;
    foreach $it (1..$nhopp) {
	@hopp_one=split(/,/,$set_hopp[$it]);
				# ------------------------------
				# too big: set only for this
	if    (($#hopp_one >= $nprot) && 
	    ($ctset < $par{"nset"})){
	    ++$ctset;
	    $part[$ctset]=join(',',@hopp_one);}
				# ------------------------------
				# add to current
	elsif ((($#tmp + $#hopp_one) <= $nprot) || 
	       ($par{"nset"} && (($ctset+1)>=$par{"nset"}))) {
	    push(@tmp,@hopp_one); }
				# ------------------------------
				# finish current, start new
	else {
	    ++$ctset;
	    $part[$ctset]=join(',',@tmp); 
	    @tmp=@hopp_one; }
    }
				# last partition
    ++$ctset;
    $part[$ctset]=join(',',@tmp);
    $nset=$ctset;

    $#tmp=$#hopp_one=0;		# slim-is-in

    return(1,"ok $SBR");
}				# end of assp3_finalPartition

#===============================================================================
sub assp4_verify {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assp4_verify                verify: any of set I any match in any set J ?
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="assp4_verify";             $fhinLoc="FHIN_".$SBR; $fhoutLoc="FHIN_".$SBR;
    
    undef %ptr2set;
				# --------------------------------------------------
				# find all pointers
				#    $ptr2set{$id}=itset (set of $id
				# --------------------------------------------------
    foreach $it (1..$nset) {
	@id1Loc=split(/,/,$part[$it]);
	foreach $id1 (@id1Loc) {
	    $ptr2set{$id1}=$it; 
	}
    }


				# ------------------------------
				# now check cross connections
    $wrtWarn="";		# ------------------------------
    foreach $it (1..$nset) {
	@id1Loc=split(/,/,$part[$it]);
				# all proteins (id1) in set itset
	foreach $id1 (@id1Loc) {
	    @id2Loc=split(/,/,$set_id2{$id1});
	    @disLoc=split(/,/,$set_dis{$id1});
				# all homologues to id1
	    foreach $itpair (1..$#id2Loc) {
		$id2=$id2Loc[$itpair];
		next if (! defined $ptr2set{$id2});
		if (! defined $ptr2set{$id1}) {
		    print "*** ERROR $SBR: missing id1 $id1\n";
		    exit;}

		next if ($ptr2set{$id2} == $ptr2set{$id1});
				# one mismatch !
		$wrtWarn.= sprintf("%-6s".$SEP."%4d".$SEP,$id1,$ptr2set{$id1});
		$wrtWarn.= sprintf("%6.1f".$SEP,          $res[$id1ptr{$id1}]) if ($par{"do_res"});
		$wrtWarn.= sprintf("%-6s".$SEP."%4d".$SEP,$id2,$ptr2set{$id2});
		$wrtWarn.= sprintf("%6.1f".$SEP,          $res[$id1ptr{$id2}]) if ($par{"do_res"});
		$wrtWarn.= sprintf($SEP."%3d\n",          $disLoc[$itpair]);
	    }
	}
    }
				# ------------------------------
				# warnings found, store them
				# ------------------------------
    if (length($wrtWarn) > 0) {
	$hdr= "# Perl-RDB\n"."# \n";
	$hdr.="# Check the following 'remote' links!!\n"."# \n"; # 
	$hdr.="# What happened: A set I, B set J, and A-B similar (via 3rd link)!\n";
	$hdr.=sprintf("%-6s".$SEP."%4s".$SEP."%6s".$SEP."%-6s".$SEP."%4s".$SEP."%6s".$SEP."%3s\n",
		      "id1","set1","res1","id2","set2","res2","dis");
	$wrtWarn=$hdr.$wrtWarn; }
    else {
	$wrtWarn=0; }

    return(1,"ok $SBR");
}				# end of assp4_verify

#===============================================================================
sub partitionWrtBuild {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   partitionWrtBuild           builds up output to write
#       in/out GLOBAL:          all
#       in GLOBAL:		$part[it]='idA,idB,'.. i.e. all in that set
#       in GLOBAL:              $set_id2{$id1}='id2A,id2B'
#       in GLOBAL:              $set_dis{$id1}='disA,disB'
#       out GLOBAL:             $wrtStat, $wrtPair (sprintf ready to write)
#-------------------------------------------------------------------------------
    $SBR="partitionWrtBuild"; 

    $wrtStat=               sprintf ("%3s".$SEP."%5s\n",
				     "set","num");
    $wrtPair=               sprintf ("%3s".$SEP."%-6s".$SEP."%-6s".$SEP."%3s",
				     "set","id1","id2","dis");
    $wrtPair.=              sprintf ($SEP."%6s".$SEP."%6s",
				     "res1","res2") if ($par{"do_res"});
    $wrtPair.=              "\n";
				     

    foreach $it (1..$nset) {
	@id1Loc=split(/,/,$part[$it]);
	$wrtStat.=          sprintf ("%3d".$SEP."%5d\n",$it,$#id1Loc);
	foreach $id1 (@id1Loc) {
	    @id2Loc=split(/,/,$set_id2{$id1});
	    @disLoc=split(/,/,$set_dis{$id1});
	    foreach $itpair (1..$#id2Loc) {
		$wrtPair.=  sprintf ("%3d".$SEP."%-6s".$SEP."%-6s".$SEP."%3d",
				     $it,$id1,$id2Loc[$itpair],$disLoc[$itpair]);
		$wrtPair.=  sprintf ($SEP."%6.1f".$SEP."%6.1f",
				     $res[$id1ptr{$id1}],
				     $res[$id1ptr{$id2Loc[$itpair]}]) if ($par{"do_res"});
		$wrtPair.="\n"; }
				# also write itself
	    if (! defined @id2Loc || ! @id2Loc ) {
		$wrtPair.=  sprintf ("%3d".$SEP."%-6s".$SEP."%-6s".$SEP." ",
				     $it,$id1,"*");
		$wrtPair.=  sprintf ($SEP."%6.1f",
				     $res[$id1ptr{$id1}]) if ($par{"do_res"}); 
		$wrtPair.=  $SEP." \n"; }
	} }
}				# end of partitionWrtBuild

#===============================================================================
sub partitionWrtDbg {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   partitionWrtDbg             writes partition dbg messages
#-------------------------------------------------------------------------------
    $SBR="partitionWrtDbg";     

    print $fhTrace2 "$dbg ","-" x 60 ,"\n";
    print $fhTrace2 "$dbg statistics on the $nset partitions\n";
    print $fhTrace2 "$dbg ",$wrtStat;
    print $fhTrace2 "$dbg \n";

    print $fhTrace2 "$dbg ","-" x 60 ,"\n";
    print $fhTrace2 "$dbg all pairs (above ",$par{"minDis"},") of the $nset partitions\n";
    print $fhTrace2 "$dbg ",$wrtPair;
    print $fhTrace2 "\n"; 
}				# end of partitionWrtDbg

#===============================================================================
sub partitionWrtStat {
    my($fileOutLoc)=@_;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   partitionWrtStat            writes partition statistics (set number_of_prot)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="partitionWrtStat";    $fhoutLoc="FHIN_".$SBR;

				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));

				# write header
    $tmpWrt=             "# Perl-RDB\n"."# \n";
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","numSet",$nset);
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","minDis",$par{"minDis"});
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","numProt",$#set);
    print $fhoutLoc $tmpWrt; 

				# write data
    print $fhoutLoc $wrtStat; 
    close($fhoutLoc);

    return(1,"ok $SBR");
}				# end of partitionWrtStat

#===============================================================================
sub partitionWrtPair {
    my($fileOutLoc)=@_;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   partitionWrtPair            writes partition all pairs (set id1 id2)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="partitionWrtPair";    $fhoutLoc="FHIN_".$SBR;

				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));

				# write header
    $tmpWrt=             "# Perl-RDB\n"."# \n";
    $tmpWrt.=            "# NOTE: this file lists only those pairs with a distance\n";
    $tmpWrt.=            "#       above the threshold minDis=".$par{"minDis"}."\n";
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","numSet",$nset);
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","minDis",$par{"minDis"});
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","numProt",$#set);
    print $fhoutLoc $tmpWrt; 
				# write data
    print $fhoutLoc $wrtPair; 
    close($fhoutLoc);

    return(1,"ok $SBR");
}				# end of partitionWrtPair

#===============================================================================
sub partitionWrtFam {
    my($fileOutLoc)=@_;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   partitionWrtFam            writes partition for all families
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="partitionWrtFam";    $fhoutLoc="FHIN_".$SBR;

				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));

				# write header
    $tmpWrt=             "# Perl-RDB\n"."# \n";
    $tmpWrt.=            "# NOTE: this file lists only those pairs with a distance\n";
    $tmpWrt.=            "#       above the threshold minDis=".$par{"minDis"}."\n";
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","numSet",$nset);
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","minDis",$par{"minDis"});
    $tmpWrt.=   sprintf ("# PARA: %-12s =\t%5d\n","numProt",$#set);
    print $fhoutLoc $tmpWrt; 
    print $fhoutLoc "id1".$SEP."num".$SEP."id2".$SEP."dis\n";
				# write data
    @tmp=split(/\n/,$wrtPair);
    $id1=$idPrev=0;

    foreach $tmp (@tmp){
	next if ($tmp=~/^set/);	# skip names
	$tmp=~s/^[\s\t]*|[\s\t]*$//g;
	@tmp2=split(/[\s\t]+/,$tmp);

				# only for first: ini
	if    (! $idPrev) {
	    $idPrev=$tmp2[2]; 
	    $#id2Tmp=$#disTmp=0;}
	$id1=$tmp2[2];
				# new id: write
	if    ($id1 ne $idPrev) {
	    $tmpWrt=      $idPrev.$SEP.$#id2Tmp;
	    if ($#id2Tmp > 0 && $id2Tmp[1] ne "*" ) {
		$tmpWrt.= $SEP.join(',',@id2Tmp);
		$tmpWrt.= $SEP.join(',',@disTmp) if ($par{"do_dis"});}
	    else {
		$tmpWrt.= $SEP."*";
		$tmpWrt.= $SEP."    "            if ($par{"do_dis"});}
	    print $fhoutLoc "$tmpWrt\n";
	    $idPrev=$id1;
	    $#id2Tmp=$#disTmp=0; }
				# push
	push(@id2Tmp,$tmp2[3]);
	push(@disTmp,$tmp2[4])   if ($par{"do_dis"});
    }
				# print last
    if ($id1 ne $idPrev) {
	$tmpWrt=      $idPrev.$SEP.$#id2Tmp;
	if ($#id2Tmp > 0) {
	    $tmpWrt.= $SEP.join(',',@id2Tmp);
	    $tmpWrt.= $SEP.join(',',@disTmp) if ($par{"do_dis"});}
	else {
	    $tmpWrt.= $SEP."    ";
	    $tmpWrt.= $SEP."    "            if ($par{"do_dis"});}
	print $fhoutLoc "$tmpWrt\n"; }

    close($fhoutLoc);

    $#tmp=$#tmp2=$#id2Tmp=$#disTmp=0; # slim-is-in!

    return(1,"ok $SBR");
}				# end of partitionWrtFam

#===============================================================================
sub partitionWrtSet {
    my($fileOutLoc,$partition)=@_;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   partitionWrtSet             writes all names for particular partition
#       in:                     $fileOutLoc
#       in:                     $partition='idA,idB,'..
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="partitionWrtSet";    $fhoutLoc="FHIN_".$SBR;

				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));

				# write data
    @idTmp=split(/,/,$partition);
    foreach $id (@idTmp) {
	print $fhoutLoc "$id\n";
    }
    close($fhoutLoc);

    return(1,"ok $SBR");
}				# end of partitionWrtSet

#===============================================================================
sub partitionWrtWarn {
    my($fileOutLoc)=@_;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   partitionWrtWarn            writes partition all warns (set id1 id2)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="partitionWrtWarn";    $fhoutLoc="FHIN_".$SBR;

				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));

				# write header
    print $fhoutLoc $wrtWarn; 
    close($fhoutLoc);

    return(1,"ok $SBR");
}				# end of partitionWrtWarn

#===============================================================================
sub sortAllThere {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sortAllThere                checks whether or not all have been considered
#                               returns error message if not!
#       in/out GLOBAL:          all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="sortAllThere";

    return(1,"ok $SBR") if ($#sort == $#ok && $#sort == $nid1);

    if ($#sort != $#ok) {
	$errWrt="ARRAY_sort not same number (".$#sort.") as ARRAY_ok (".$#ok.")\n";}
    else {
	$errWrt="ARRAY_sort not all proteins (".$#sort."), want=$nid1\n";}
	
    foreach $idnum (1..$nid1) {
	next if ($ok[$idnum]);
	$errWrt.="missing idnum=$idnum, id=".$id1ptr[$idnum].",\n"; }
    return(0,$errWrt);
}				# end of sortAllThere

#===============================================================================
sub sortFeature {
    local($levelLoc) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sortFeature                 sorts those not included so far by family size or res
#                               either: large ones first ($par{"modeRoot"}='large')
#                               or    : small ones first ($par{"modeRoot"}='small')
#                               or:  best resolution 1st ($par{"modeRoot"}='res')
#                               
#       in/out GLOBAL:          all
#                               
#       in:                     $level = 1,-1,-2,'all': i.e. take only those
#                                        with $ra_incl_level[$idnum]=$level
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="sortFeature";          $dbg=$SBR; $dbg="$dbg";

    $#sortFeature=0;		# featur to sort: family size (uniq numbers)
				#             or: resolution
    $#ptr=0;			# for $sortFeature[it]=N, 
				#     $ptr[N]=number_of_proteins_with_size_N
				#     $ptr[N][mue]=idnum, the mue-th element 
				#         from protein idnum
    $#ptrlist=0;
    $levelPrt="x";
    $levelPrt=$levelLoc         if ($levelLoc ne "all");

				# ------------------------------
				# get family sizes for all ids
				#    or the resolutions
				# ------------------------------
    $#priorityIncl=0;		# all those to be explicitly included FIRST!
    foreach $idnum (1..$nid1) {
				# skip if already taken
	next if (defined $ok[$idnum]);
				# skip if no level
	next if ($levelLoc ne "all" && ! defined $ra_incl_level->[$idnum]);
				# skip if not correct level
	next if ($levelLoc ne "all" && defined $ra_incl_level->[$idnum] &&
		 $ra_incl_level->[$idnum] ne $levelLoc);
				# skip if all AND level
	if ($levelLoc eq "all" && defined $ra_incl_level->[$idnum]) {
	    push(@priorityIncl,$idnum);
	    next;}
				# sorting by resolution
	if ($par{"modeRoot"} eq "res"){
	    $num=$res[$idnum];	# resolution
				# pointer to it
	    $numArray=int(100*$num); }
	else {
	    $num=$num[$idnum];	# family size
				# pointer to it
	    $numArray=$num+1;}	# note: num may be zero -> for array count +1

	printf $fhTrace2 
	    "$dbg level=%2s idnum=%5d %-6s num=%-s\n",
	    $levelPrt,$idnum,$id1ptr[$idnum],$num  if ($par{"verbDbg"});

	if (! defined $ptr[$numArray]){
	    push(@sortFeature,$num);
	    $ptr[$numArray]=1; $tmp=1;
	    $ptrlist[$numArray][$tmp]=$idnum;}
	else {
	    ++$ptr[$numArray]; $tmp=$ptr[$numArray]; 
	    $ptrlist[$numArray][$tmp]=$idnum; } 
    }
				# ------------------------------
				# return if none found at given
				# level
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    return(1,"ok $SBR") if ($#sortFeature == 0);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


				# ------------------------------
				# sort according to feature
				# ------------------------------
    if    ($par{"modeRoot"} eq "large"){
	@sortFeature=sort bynumber_high2lowLoc @sortFeature; }
    elsif ($par{"modeRoot"} eq "small"){
	@sortFeature=sort bynumberLoc @sortFeature; }
    elsif ($par{"modeRoot"} eq "res"){
	@sortFeature=sort bynumberLoc @sortFeature; }
    else {
	return(&errSbr("modeRoot=".$par{"modeRoot"}.", not understood",$SBR));}

    if ($par{"verbDbg"}) {
	print $fhTrace2 "$dbg ","-" x 60,"\n";
	print $fhTrace2 "$dbg level=$levelLoc features sorted:",join(',',@sortFeature,"\n");
	print $fhTrace2 "$dbg ","-" x 60,"\n"; }

				# ------------------------------
				# get family succession
				# ------------------------------
    foreach $feature (@sortFeature) {
	if ($par{"modeRoot"} eq "res"){
	    $index=int(100*$feature); }
	else {
	    $index=$feature+1; }
	    
	$num=$ptr[$index];
	printf $fhTrace2 "$dbg on size=%5d ptr=%5d:",$feature,$num if ($par{"verbDbg"});
	    
				# for all proteins of that size
	foreach $it (1..$num){
	    
	    $idnum=$ptrlist[$index][$it];
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if already in @sort
	    next if (defined $ok[$idnum]);
	    print $fhTrace2 "$idnum "                            if ($par{"verbDbg"});
	    push(@sort,$idnum);
	    $ok[$idnum]=1; } 
	print $fhTrace2 "\n"                                     if ($par{"verbDbg"});
    }

    undef @sortFeature; undef @ptr;	# slim-is-in

				# add all those with HARD include (read by fileIncl)
    foreach $idnum (@priorityIncl){
	$ok[$idnum]=2;
    }
				# add hard_include to array
    @sort=(@priorityIncl,@sort);

    return(1,"ok $SBR");
}				# end of sortFeature

#===============================================================================
sub wrtDbgFin {
    my($fhSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtDbgFin                   debug write of final stuff
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtDbgFin";               

				# ------------------------------
				# all ok
				# ------------------------------
    printf $fhSbr 
	"dbg: ok  %-6s %5s %5s %6s %5s\n","id","idnum","len","res","famSize";
    foreach $idnum (1..$nid1){
	next if (! defined $ok[$idnum] || ! $ok[$idnum]);
	printf $fhSbr "dbg: ok  %-6s %5d",$id1ptr[$idnum],$idnum; 
	printf $fhSbr " %5d",$len[$idnum]   if ($par{"do_len"}); 
	printf $fhSbr " %6.1f",$res[$idnum] if ($par{"do_res"}); 
	printf $fhSbr " %5d\n",$num[$idnum]; }

    printf $fhSbr "dbg: not %-6s %5s","id","idnum";
    printf $fhSbr " %5s","len"              if ($par{"do_len"});
    printf $fhSbr " %6s","res"              if ($par{"do_res"});
    printf $fhSbr " %5s %-s\n","famSize","why";

    foreach $idnum (1..$nid1){
	next if (! defined $ok[$idnum]  || $ok[$idnum] >= 1 ||
		 ! defined $len[$idnum] ||
		 ! defined $id1ptr[$idnum] ||
		 ! defined $res[$idnum] ||
		 ! defined $why[$idnum] ||
		 ! defined $num[$idnum]);
	printf $fhSbr "dbg: not %-6s %5d",$id1ptr[$idnum],$idnum; 
	printf $fhSbr " %5d",  $len[$idnum]  if ($par{"do_len"}); 
	printf $fhSbr " %6.1f",$res[$idnum]  if ($par{"do_res"});
	printf $fhSbr " %5d %-s\n",$num[$idnum],$why[$idnum]; }

    foreach $idnum (1..$nid1){
	next if (defined $ok[$idnum]);
	printf $fhSbr "dbg: ERR %-6s %5d",$id1ptr[$idnum],$idnum; 
	printf $fhSbr " %5d",  $len[$idnum]  if ($par{"do_len"}); 
	printf $fhSbr " %6.1f",$res[$idnum]  if ($par{"do_res"});
	printf $fhSbr " %5d %-s\n",$num[$idnum],$why[$idnum]; }

    return(1,"ok $SBR");
}				# end of wrtDbgFin

#===============================================================================
sub wrtFamilySize {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtFamilySize                     
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtFamilySize";       $fhoutLoc="FHIN_". $SBR; $dbg=$SBR; $dbg="dbg $dbg:";
    
    $LverbDbgLoc=$par{"verbDbg"};
    $LverbDbgLoc=0;
    $fileOutCluster=$par{"fileOutCluster"};

    &open_file("$fhoutLoc",">$fileOutCluster") || 
	return(&errSbr("fileOutCluster=$fileOutCluster, not created"));
				# ------------------------------
				# names
    print $fhoutLoc "id1",$SEP,"num",$SEP,"level",$SEP,"ok",$SEP,"why not?",$SEP,"id2","\n";

    if ($LverbDbgLoc) {
	print  $fhTrace2 "--- ","-" x 80,"\n","$dbg \n"; 
	print  $fhTrace2 "dbg: ","id1",$SEP,"num",$SEP,"level",$SEP,"ok",$SEP;
	printf $fhTrace2 "%-10s","why not?";
	print  $fhTrace2 $SEP,"id2","\n"; }
				# ------------------------------
				# all clusters
    foreach $idnum (@sort) {
	$num=$num[$idnum];
	$id1=$id1ptr[$idnum];
	$tmp="";
	foreach $it (1..$num) {
	    $id2num=$ra_family[$idnum]->[$it];
	    $id2=$id2ptr[$id2num];
	    $tmp.="$id2,";}
	$tmp=~s/,*$//;
	$level="?";
	$level=$ra_incl_level->[$idnum] if (defined $ra_incl_level->[$idnum]);

	$ok=  "?";
	$ok=  $ok[$idnum]       if (defined $ok[$idnum]);
	$why= " ";
	$why= $why[$idnum]      if (defined $why[$idnum]);
	$why= sprintf("%-10s",$why);
	$tmpWrt=$id1.$SEP.$num.$SEP.$level.$SEP.$ok.$SEP.$why.$SEP.$tmp;

	print $fhoutLoc $tmpWrt,"\n";
	print $fhTrace2 "dbg: ",$tmpWrt,"\n"          if ($LverbDbgLoc);
    }
    close($fhoutLoc);

    return(1,"ok $SBR");
}				# end of wrtFamilySize

#===============================================================================
sub wrtFinLoc {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtFinLoc                   writing output and screen message
#       in/out GLOBAL:          all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtFinLoc";
                                # ------------------------------
                                # final words
    print "--- ","-" x 80,"\n";
    print "--- $scrName ended fine .. -:\)\n";
                                # ------------------------------
    $timeEnd=time;		# runtime , run time
    $timeRun=$timeEnd-$timeBeg;
    print 
	"--- date     \t \t $Date \n",
	"--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";
                                # ------------------------------
    print "--- \n";		# output files
    print "--- output file";print "s" if ($#fileOut>1); print ":\n";
    foreach $_(@fileOut){
	printf "--- %-20s %-s\n"," ",$_ if (-e $_);}
				# ------------------------------
				# statistics: only for new set
    if (! $par{"fileSet"}) {
	print  "--- statistics:\n";
	printf "--- %-20s %5d\n","largest set (ok):",$ctOk   if (defined $ctOk);
	printf "--- %-20s %5d\n","not unique  (no):",$ctNo   if (defined $ctNo);
	printf "--- %-20s %5d\n","problems   (err):",$ctErr  if (defined $ctErr); 
	printf "--- %-20s %5d\n","to check! (warn):",$ctWarn if (defined $ctWarn);  }
    else {
	print "--- statistics:\n";
	print $wrtStat; }

}				# end of wrtFinLoc

#===============================================================================
sub wrtGreedyFin {
    my($SBR,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtGreedyFin                write all output files for mode: do new list
#       in/out GLOBAL:          all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtGreedyFin";        $fhoutLoc="FHIN_".$SBR;
    
				# reset array
    $#sort=0;
				# write data + resolution (sorted by res)
				# out GLOBAL: @sorted = idnum sorted
    if ($par{"do_res"} && $par{"wrtRes"}) {
	&wrtResolution(); }
    else {
	foreach $idnum (1..$nid1) { 
	    next if (! defined $ok[$idnum] || ! $ok[$idnum]);
	    push(@sort,$idnum);}}

				# list of ids ok (i.e. in final unique list)
    &open_file("$fhoutLoc",">".$par{"fileOutOk"});  $ctOk=$#sort;
    foreach $idnum (@sort) { 
	print $fhoutLoc "$id1ptr[$idnum]\n"; } close($fhoutLoc);

				# list of ids excluded (overlap with previous)
    &open_file("$fhoutLoc",">".$par{"fileOutNo"});  $ctNo=0;
    foreach $idnum (1..$nid1) { 
	next if (! defined $ok[$idnum] || $ok[$idnum]);
	++$ctNo;
	print $fhoutLoc $id1ptr[$idnum],"\n"; } close($fhoutLoc);

    &open_file("$fhoutLoc",">".$par{"fileOutErr"}); $ctErr=0;
    foreach $idnum (1..$nid1) { 
	next if (defined $ok[$idnum]);
	++$ctErr;
	print $fhoutLoc $id1ptr[$idnum],"\n"; } close($fhoutLoc);
				# delete if none found
    unlink($par{"fileOutErr"})  if ($ctErr==0);

    if ($#wrtWarn > 0) {
	&open_file("$fhoutLoc",">".$par{"fileOutWarn"}); $ctWarn=$#wrtWarn;
	foreach $warn (@wrtWarn) {
	    $warn=~s/\n//;
	    print $fhoutLoc "$warn\n";}
	close($fhoutLoc); }

    return(1,"ok $SBR");
}				# end of wrtGreedyFin

#===============================================================================
sub wrtResolution {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtResolution                     
#       in/out GLOBAL:          all
#       out GLOBAL:             @sort = idnum (ok>0) sorted by resolution
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtResolution";       $fhoutLoc="FHOUT_".$SBR; $dbg="dbg $SBR:";

    $#sortFeature=0;		# featur to sort: family size (uniq numbers)
				#             or: resolution
    $#ptr=0;			# for $sortFeature[it]=N, 
				#     $ptr[N]=number_of_proteins_with_size_N
				#     $ptr[N][mue]=idnum, the mue-th element 
				#         from protein idnum
    $#ptrlist=0;
				# ------------------------------
				# get resolutions
				# ------------------------------
    foreach $idnum (1..$nid1) {
				# skip if already taken
	next if (! defined $ok[$idnum] || ! $ok[$idnum]);
	$res=$res[$idnum];	# resolution
				# pointer to it
	$numArray=int(100*$res);

	if (! defined $ptr[$numArray]){
	    push(@sortFeature,$res);
	    $ptr[$numArray]=1; $tmp=1;
	    $ptrlist[$numArray][$tmp]=$idnum;}
	else {
	    ++$ptr[$numArray]; $tmp=$ptr[$numArray]; 
	    $ptrlist[$numArray][$tmp]=$idnum; } 
    }

    @sortFeature=sort bynumberLoc @sortFeature;


    if ($par{"verbDbg"}) {
	print $fhTrace2 "$dbg ","-" x 60,"\n";
	print $fhTrace2 "$dbg resolution sorted:",join(',',@sortFeature,"\n");
	print $fhTrace2 "$dbg ","-" x 60,"\n"; }
    
				# ------------------------------
				# get family succession
				# ------------------------------
    &open_file("$fhoutLoc",">".$par{"fileOutRes"}) || 
	return(&errSbr("fileOutRes=".$par{"fileOutRes"}.", not created"));
				# write names
    $tmpWrt=    "# Perl-RDB\n"."# \n";
    $tmpWrt.=   sprintf("%-6s$SEP%5s$SEP%5s","id1","len","fam");
    $tmpWrt.=   sprintf("$SEP%6s","res") if ($par{"do_res"});
    $tmpWrt.=   "\n";
    print $fhoutLoc $tmpWrt; 

				# write data
    $#tmp=0;
    foreach $feature (@sortFeature) {
	$index=int(100*$feature); 
	$num=$ptr[$index];
#	printf $fhTrace2 "$dbg on size=%5d ptr=%5d:",$feature,$num if ($par{"verbDbg"});
	    
				# for all proteins of that size
	foreach $it (1..$num){
	    $idnum=$ptrlist[$index][$it];
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if already in @sort
	    next if (defined $tmp[$idnum]);

				# GLOBAL out! 
	    push(@sort,$idnum);

	    $tmp[$idnum]=1; 
	    $tmpWrt= sprintf("%-6s$SEP%5d$SEP%5d",
			     $id1ptr[$idnum],$len[$idnum],$num[$idnum]);
	    $tmpWrt.=sprintf("$SEP%6.1f",$res[$idnum]) if ($par{"do_res"});
	    $tmpWrt.="\n";
	    printf $fhTrace2 $tmpWrt if ($par{"verbDbg"});
	    print $fhoutLoc $tmpWrt; }
    }
    close($fhoutLoc);

    return(1,"ok $SBR");
}				# end of wrtResolution


