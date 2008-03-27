#! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Sep,    	1998	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with routines generally related to writing scripts.          #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   scr                         internal subroutines:
#                               ---------------------
# 
#   brIniErr                    error check for initial parameters
#   brIniGetArg                 standard reading of command line arguments
#   brIniHelp                   initialise help text
#   brIniHelp_unikwd            cleans up list of keywords
#   brIniHelpLoop               loop over help 
#   brIniHelpRdItself           reads the calling perl script (scrName),
#   brIniRdDef                  reads defaults for initialsing parameters
#   brIniRdDefWhere             searches for a default file
#   brIniSet                    changing parameters according to input arguments
#   brIniWrt                    write initial settings on screen
#   date_monthDayYear2num       converts date from 'Feb 14, 1999' -> 14-02-1999
#   date_monthName2num          converts month name to number
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#   errScrMsg                   writes message and EXIT!!
#   fctRunTime                  #   fctRunTimeLeft              estimates the run time of the job
#   fctRunTimeLeft              estimates the time the job still needs to run
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#   get_in_keyboard             gets info from keyboard
#   get_range                   converts range=n1-n2 into @range (1,2)
#   get_rangeHyphen             reads 'n1-n2'  
#   getSysARCH                  tries to get the system architecture
#   is_rdb                      checks whether or not file is in RDB format
#   is_rdbf                     checks whether or not file is in RDB format
#   isName                      returns 1 if $tmp is a 'given name'
#   month2num                   converts name of month to number
#   myprt_array                 prints array ('sep',@array)
#   myprt_empty                 writes line with '--- \n'
#   myprt_line                  prints a line with 70 '-'
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#   myprt_points80              1
#   myprt_strings               
#   myprt_txt                   adds '---' and '\n' for writing text
#   printm                      print on multiple filehandles (in:$txt,@fh; out:print)
#   prtRemain                   writes remaining time
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   scr                         external subroutines:
#                               ---------------------
# 
# 
#   call from scr:              brIniHelp,brIniHelpRdItself,brIniRdDef,errSbrMsg,fctSeconds2time
#                               get_in_keyboard,get_rangeHyphen,myprt_points80
# 
# -----------------------------------------------------------------------------# 
# 

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
	    if (!defined $tmp{$tmp2}){
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
	    ($Lok,$msg,@kwdLoc)=
		&brIniHelp_unikwd(@kwdLoc);
	    foreach $kwd (@kwdLoc){
		$tmp=" "; $tmp=$tmp{$kwd} if (defined $tmp{$kwd});
		$tmp=~s/\n$//;
		$tmpWrt=sprintf ("---   %-15s %-s\n",$kwd,$tmp); 
		push(@scrSpecialLoc,$tmpWrt); } 
	}}
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
		($Lok,$msg,@kwdLoc)=
		    &brIniHelp_unikwd(@kwdLoc);
		print $syntaxLoc;
		$ct=0;print "OPT \t ";
		foreach $kwd (@kwdLoc){
		    ++$ct;
		    printf "%-20s ",$kwd;
		    if ($ct==4){
			$ct=0;print "\nOPT \t ";}}
		print "\n";
	    }
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
	    foreach $txt(@tmp) {
		print "--- $txt\n";++$ct;}}
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
	    foreach $txt(@tmp){
		print "--- $txt\n";++$ct;}}
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
		($Lok,$msg,@kwdLoc)=
		    &brIniHelp_unikwd(@kwdLoc);
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                foreach $kwd (@kwdLoc){
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};
		}
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
	$tmpSpecial=$tmp{$tmp}  if (defined $tmp{$tmp});
	$tmpSpecial=$tmp{$tmp2} if (! defined $tmp{$tmp} && defined $tmp{$tmp2});

        $#kwdLoc=$#expLoc=0;    # (1) get all respective keywords
        if (defined %par && $kwdHelp ne "special"){
            @kwdLoc=keys (%par);$#tmp=0;
	    ($Lok,$msg,@kwdLoc)=
		&brIniHelp_unikwd(@kwdLoc);
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
	    ($Lok,$msg,@kwdLoc)=
		&brIniHelp_unikwd(@kwdLoc);
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
	    ($Lok,$msg,@kwdLoc)=
		&brIniHelp_unikwd(@kwdLoc);
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
	    undef %tmp2;
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            printf "--- %-20s   %-s\n","keyword","explanation";
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
	    ($Lok,$msg,@kwdLoc)=
		&brIniHelp_unikwd(@kwdLoc);
            foreach $it (1..$#kwdLoc){
                $tmp=" "; $tmp=$expLoc[$it] if (defined $expLoc[$it]);
                printf "--- %-20s   %-s\n",$kwdLoc[$it],$tmp;}
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            print "--- \n";$Lerr=0;
	}

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
		($Lok,$msg,@kwdLoc)=
		    &brIniHelp_unikwd(@kwdLoc);
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
sub brIniHelp_unikwd {
    @tmploc2 = @_ ;
    local($sbrName2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelp_unikwd            cleans up list of keywords
#       in:                     @keywords
#       out:                    (1,'ok',@keywords_cleaned)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2=$tmp."brIniHelp_unikwd";
    return(1,"ok",$#tmploc2)     if ($#tmploc2<1);

    undef %tmploc3;
    $#tmploc3=0;
    foreach $kwd (@tmploc2){
	next if (defined $tmploc3{$kwd});
	$tmploc3{$kwd}=1;
	push(@tmploc3,$kwd);
    }
    undef %tmploc3;
    @tmploc2=@tmploc3; 
    $#tmploc3=0;
    
    return(1,"ok $sbrName",@tmploc2);
}				# end of brIniHelp_unikwd

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
    $sbrName="lib-col:"."brIniHelpLoop";$fhinLoc="FHIN_"."brIniHelpLoop";

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
				# blabla only for first time loop
	    if (! $ct){
		printf "%-s %-s\n",      $promptLoc,"-" x (79 - length($promptLoc));
		printf "%-s %-15s %-s\n",$promptLoc,"",              "Interactive help";
		printf "%-s %-15s %-s\n",$promptLoc,"OPTIONS","";
		foreach $txt (@scrHelpLoop2) { 
		    printf "%-s %-15s %-s\n",$promptLoc," ",$txt; }
		printf "%-s %-15s %-s\n",$promptLoc,"","";
	    }
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
				# add by default previous wish (help OR def)
	    if ($#ARGV < 2){
		@ARGV=($def,$ARGV[1]);}
	    else {
		$ARGV[1]="help" if ($ARGV[1] eq "h" || $ARGV[1] eq "H");
		$ARGV[1]="def"  if ($ARGV[1] eq "d" || $ARGV[1] eq "D");}

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
	    $tmp{"loop"}=1;
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

    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n");
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

    open($fhin,$fileLoc) ||
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

#===============================================================================
sub brIniRdDefWhere {
    local($scrName,$sourceFileLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniRdDefWhere             searches for a default file
#       in:                     $scrName = 'script' , $sourceName = 'dir/script.pl'
#       out:                    name of default file, or 0
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniRdDefWhere";$fhinLoc="FHIN"."$sbrName";

    foreach $_(@ARGV){		# default file given on command line?
	if ($_=~/^fileDefaults=(.+)$/){
	    $fileDefaultsLoc=$1;
	    return(0,"*** ERROR $sbrName: default file '",$fileDefaultsLoc,"' missing\n") 
		if (! -e $fileDefaultsLoc);
	    last;}}
    return($fileDefaultsLoc) if (defined $fileDefaultsLoc && -e $fileDefaultsLoc);
				# search in local dir
    $fileDefaultsLoc=$scrName.".defaults" if (defined $scrName);
    return($fileDefaultsLoc) if (defined $fileDefaultsLoc && -e $fileDefaultsLoc);
				# search in original dir
    if (defined $sourceFileLoc){
	$tmp=$sourceFileLoc;$tmp=~s/\.pl//g;
	$fileDefaultsLoc=$tmp.".defaults"; } # script dir
    return($fileDefaultsLoc) if (defined $fileDefaultsLoc && -e $fileDefaultsLoc);
				# any other idea where to search??
    return(0);
}				# end of brIniRdDefWhere

#==============================================================================
sub brIniSet {
    local($excludeLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniSet                    changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniSet";
    @kwd=sort keys(%par) if (defined %par && %par);
    $#tmpExclude=0;
    if (defined $excludeLoc){
	@tmpExclude=split(/,/,$excludeLoc);
	$excludeLoc=join("|",@tmpExclude);
    }
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
	next if ($kwd !~ /^file(Out|Web|Log)/);
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
	    next if ($kwd =~ /^file(In|Out|Help|Def|Web|Log)/i);
	    next if (defined $excludeLoc &&
		     $kwd=~/$excludeLoc/);
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
	    $exclLoc{$tmp}=1; }
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
sub date_monthDayYear2num {
    local($datein) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   date_monthDayYear2num       converts date from 'Feb 14, 1999' -> 14-02-1999
#       in:                     $date
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."date_monthDayYear2num";
    return(0,"no input")        if (! defined $datein);
    return(0,"no valid input")  
	if ($datein !~ /([a-zA-z][a-zA-z][a-zA-z])[\s\-_\.,]+(\d+)[\s\-_\.,]+(\d+)/);
    $month=$1;
    $day=  $2;
    $year= $3;
				# convert month
    ($Lok,$msg,$num)=&date_monthName2num($month);
    return(0,"failed converting month=$month! msg=\n".$msg) if (! $Lok);
				# add leading zeroes
    $day=  "0".$day             if (length($day)<2);
    $num=  "0".$num             if (length($num)<2);
    $out=$day."-".$num."-".$year;
    return(1,$out);
}				# end of date_monthDayYear2num

#===============================================================================
sub date_monthName2num {
    local($txtIn) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   date_monthName2num          converts month name to number
#       in:                     $month
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."date_monthName2num";
    return(1,"ok","01") if ($txtIn=~/^jan/i);
    return(1,"ok","02") if ($txtIn=~/^feb/i);
    return(1,"ok","03") if ($txtIn=~/^mar/i);
    return(1,"ok","04") if ($txtIn=~/^apr/i);
    return(1,"ok","05") if ($txtIn=~/^may/i);
    return(1,"ok","06") if ($txtIn=~/^jun/i);
    return(1,"ok","07") if ($txtIn=~/^jul/i);
    return(1,"ok","08") if ($txtIn=~/^aug/i);
    return(1,"ok","09") if ($txtIn=~/^sep/i);
    return(1,"ok","10") if ($txtIn=~/^oct/i);
    return(1,"ok","11") if ($txtIn=~/^nov/i);
    return(1,"ok","12") if ($txtIn=~/^dec/i);
    return(0,"month=$txtIn, is what??",0);
}				# end  date_monthName2num

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
sub fctRunTime {
    local($timeBegLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTime                  estimates the run time of the job
#       in:                     $timeBegLoc : time (time) when job began
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."fctRunTime";

    $timeNow=time;
    $timeRun=$timeNow-$timeBegLoc;

    $tmp=
	&fctSeconds2time($timeRun); 
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

    return($estimateLoc);
}				# end of fctRunTime

#===============================================================================
sub fctRunTimeFancy {
    local($nameLoc,$percLoc,$LdoTimeLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeFancy             fancy way to write run time estimate
#       NEED:                   &fctSeconds2time
#       GLOBAL in/out:          $timeBegLoc
#                               
#       in:                     $nameLoc=    name of directory or file or job
#       in:                     $percLoc=    percentage of job done so far
#       in:                     $LdoTimeLoc= 1-> estimate remaining runtime
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."fctRunTimeFancy";
				# check arguments
    return(&errSbr("not def nameLoc!")) if (! defined $nameLoc);
    return(&errSbr("not def percLoc!")) if (! defined $percLoc);
    $LdoTimeLoc=0                       if (! defined $LdoTimeLoc);
#    return(&errSbr("not def !"))          if (! defined $);

				# local parameter
#    $par{"fctRunTimeFancy","maxdot"}=72 if (! defined $par{"fctRunTimeFancy","maxdot"});
    $par{"fctRunTimeFancy","maxdot"}=60 if (! defined $par{"fctRunTimeFancy","maxdot"});
    $tmpformatLoc="%-".$par{"fctRunTimeFancy","maxdot"}."s"
	if (! defined $tmpformatLoc);

    $nameLoc=~s/\/$//g;
    $nameLoc=~s/^.*\///g;
    $tmpdots=int((100-$percLoc)*$par{"fctRunTimeFancy","maxdot"}/100);

				# estimate remaining run time?
    if ($LdoTimeLoc){
	$timeNowLoc=time;
	$timeBegLoc=$timeBeg    if (! defined $timeBegLoc && defined $timeBeg);
	$timeBegLoc=0           if (! defined $timeBegLoc);
	$timeRunLoc=$timeNowLoc-$timeBegLoc;

	if ($percLoc>0 && $timeNowLoc ne $timeBegLoc) {
	    $timeTotLoc=int($timeRunLoc*100/(100-$percLoc));
	    $timeLeftLoc=$timeTotLoc-$timeRunLoc;
	    $timeTxtLoc=
		&fctSeconds2time($timeLeftLoc); 
				# remove leading 0h 0m if perc < 20
	    if    ($percLoc > 80 && $timeTxtLoc=~/^0+\:0+\:/){
		$Lpurge_timehm_loc=1;
		$timeTxtLoc=~s/^0+\:0+\://g;}
				# remove leading 0h 0m if perc < 20
	    elsif ($percLoc > 80 && $timeTxtLoc=~/^0+\:/){
		$Lpurge_timeh_loc=1;
		$timeTxtLoc=~s/^0+\://g;}
	    elsif (defined $Lpurge_timehm_loc && $Lpurge_timehm_loc){
		$timeTxtLoc=~s/^0+\:0+\://g;}
	    elsif (defined $Lpurge_timeh_loc && $Lpurge_timeh_loc){
		$timeTxtLoc=~s/^0+\://g;}

	    @tmpLoc=split(/:/,$timeTxtLoc); 
	    foreach $tmp (@tmpLoc){
		$tmp=~s/^0//g;}
	    if    ($#tmpLoc==3){
		$tmptime=sprintf("%3s %3s%3s",
				 $tmpLoc[1]."h",$tmpLoc[2]."m",$tmpLoc[3]."s");}
	    elsif ($#tmpLoc==2){
		$tmptime=sprintf("%3s%3s",
				 $tmpLoc[1]."m",$tmpLoc[2]."s");}
	    elsif ($#tmpLoc==1){
		$tmptime=sprintf("%3s",
				 $tmpLoc[1]."s");}
	    else {
		$tmptime=$timeTxtLoc;}
	}
	elsif ($percLoc==0) {
	    $tmptime="done";
	}
	else {
	    $tmptime="??";
	}
    }
    else {
	$tmptime="";}
				# write
    $tmp=
	sprintf("%-15s %3d%-1s |".$tmpformatLoc."| %-s\n",
		substr($nameLoc,1,15),
		int($percLoc),
		"%",
		"*" x $tmpdots,
		$tmptime
		);
    return(1,"ok $sbrName",$tmp);
}				# end of fctRunTimeFancy

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

#===============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#===============================================================================
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

#===============================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_range                   converts range=n1-n2 into @range (1,2)
#       in:                     'n1-n2' NALL: e.g. incl=1-5,9,15 
#                               n1= begin, n2 = end, * for wild card
#                               NALL = number of last position
#       out:                    @takeLoc: begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    $#range=0;
    if (! defined $range_txt || length($range_txt)<1 || $range_txt eq "unk" 
	|| $range_txt !~/\d/ ) {
	print "*** ERROR in get_range: argument: range=$range_txt, nall=$nall, not digestable\n"; 
	return(0);}
    $range_txt=~s/\s//g;	# purge blanks
    $nall=0                     if (! defined $nall);
				# already only a number
    return($range_txt)          if ($range_txt !~/[^0-9]/);
    
    if ($range_txt !~/[\-,]/) {	# no range given
	print "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n"; 
	return(0);}
				# ------------------------------
				# dissect commata
    if    ($range_txt =~ /\,/) {
	@range=split(/,/,$range_txt);}
				# ------------------------------
				# dissect hyphens
    elsif ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	@range=&get_rangeHyphen($range_txt,$nall);}

				# ------------------------------
				# process further elements with hyphens
    $#range2=0;
    foreach $range (@range){
	if ($range =~ /(\d*|\*)-(\d*|\*)/) {
	    push(@range2,&get_rangeHyphen($range,$nall));}
	else {
            push(@range2,$range);}}
    @range=@range2; $#range2=0;
				# ------------------------------
    if ($#range>1){		# sort
	@range=sort {$a<=>$b} @range;}
    return (@range);
}				# end of get_range

#===============================================================================
sub get_rangeHyphen {
    local ($range_txt,$nall) = @_ ;
    local (@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_rangeHyphen             reads 'n1-n2'  
#       in:                     'n1-n2', NALL (n1= begin, n2 = end, * for wild card)
#                               NALL = number of last position
#       out:                    begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    if ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	($range1,$range2)=split(/-/,$range_txt);
	if ($range1=~/\*/) {$range1=1;}
	if ($range2=~/\*/) {$range2=$nall;} 
	for($it=$range1;$it<=$range2;++$it) {push(@rangeLoc,$it);} }
    else { @rangeLoc=($range_txt);}
    return(@rangeLoc);
}				# end of get_rangeHyphen

#===============================================================================
sub getSysARCH {
    local($exePvmgetarch,@argLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSysARCH                  tries to get the system architecture
#                               
#       in:                     $exePvmgetarch:  bin-shell script to get ARCH
#                                  = 0           to not execute that one..
#       in:                     @argLoc:         all arguments passed to program, checks
#                                                for one with:
#                                  ARCH=SGI64    .. or so
#       out:                    <0,$ARCH>
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."getSysARCH";

    $archFound=0;
    $exePvmgetarch=0            if (! defined $exePvmgetarch);

				# ------------------------------
				# (1) find in arguments passed
				# ------------------------------
    if (defined @argLoc && $#argLoc > 0) {
	foreach $arg (@argLoc) {
	    if ($arg=~/^ARCH=(\S+)/i) {
		$archFound=$1;
				# archs are upper case: convert
		$archFound=~tr/[a-z]/[A-Z]/;
		last; }} }
    return($archFound)          if ($archFound);
	
				# ------------------------------
				# (2) try env asf
				# ------------------------------
    $archFound=$ENV{'ARCH'} || $ENV{'CPUARC'} || 0;
    return($archFound)          if ($archFound);

				# ------------------------------
				# (3) run bin shell script given
				# ------------------------------
    if ($exePvmgetarch && (-e $exePvmgetarch || -l $exePvmgetarch)) {
	$scr=$exePvmgetarch;
	$archFound=`$scr`;	# system call
	$archFound=~s/\s|\n//g; 
	$archFound=0            if (length($archFound < 3) || $archFound !~ /[A-Z][A-Z]/);}
    return($archFound)          if ($archFound);

				# ------------------------------
				# (4) search bin shell script 
				# ------------------------------
    foreach $possible ("/home/rost/pub/phd/scr/pvmgetarch.sh",
		       "/home/rost/etc/pvmgetarch.sh") {
	if (-e $possible || -l $possible) {
	    $exePvmgetarch=$possible; 
	    last; }}
				# somewhere in relative paths
    if (! $exePvmgetarch) {
	$dirRelative=$0; $dirRelative=~s/\.\///g; $dirRelative=~s/^(.*\/).*$/$1/;
	foreach $possible ("scr/pvmgetarch.sh","scr/which_arch.sh",
			   "bin/pvmgetarch.sh","bin/which_arch.sh",
			   "etc/pvmgetarch.sh","etc/which_arch.sh",
			   "pvmgetarch.sh","which_arch.sh") {
	    if (-e $possible || -l $possible) {
		$exePvmgetarch=$possible; 
		last; }}}
				# ******************************
				# script not found
    return(0)                   if (! $exePvmgetarch);
				# ******************************
	
				# ------------------------------
				# (5) run bin shell script 
				# ------------------------------
    $scr=$exePvmgetarch;
    $archFound=`$scr`;		# system call
    $archFound=~s/\s|\n//g; 
    $archFound=0               if (length($archFound) < 3 || $archFound !~ /[A-Z][A-Z]/);
    return($archFound);
}				# end of getSysARCH

#===============================================================================
sub is_rdb {
    local ($fh_in) = @_ ;
#--------------------------------------------------------------------------------
#   is_rdb                      checks whether or not file is in RDB format
#       in:                     filehandle
#       out (GLOBAL):           $LIS_RDB
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    while ( <$fh_in> ) {
	if (/^\# Perl-RDB/) {$LIS_RDB=1;}else{$LIS_RDB=0;}
	last;
    }
    return $LIS_RDB ;
}				# end of is_rdb

#===============================================================================
sub is_rdbf {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_rdbf                     checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $file_in);
    $fh="FHIN_CHECK_RDB";
    $Lok=open($fh, $file_in);
    return(0)                   if (! $Lok);
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_rdbf

#===============================================================================
sub isName {
    local($tmp) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isName                      returns 1 if $tmp is a 'given name'
#                               i.e. not 'unk', '', 0
#       in:                     $tmp
#       out:                    1|0
#-------------------------------------------------------------------------------
    return(0) if (! defined $tmp);
    return(0) if (! $tmp);
    return(0) if (length($tmp)<1);
    return(0) if ($tmp=~/^unk$/i);
    return(1);
}				# end of isName

#===============================================================================
sub month2num {
    local($nameIn) = @_ ;
    local($sbrName,%tmp);
#-------------------------------------------------------------------------------
#   month2num                   converts name of month to number
#       in:                     Jan (or january)
#       out:                    1
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."month2num";$fhinLoc="FHIN"."$sbrName";
    return(0) if (! defined $nameIn);
    $nameIn=~tr/[A-Z]/[a-z]/;	# all small letters
    $nameIn=substr($nameIn,1,3);
    %tmp=('jan',1,'feb',2,'mar',3,'apr', 4,'may', 5,'jun',6,
	  'jul',7,'aug',8,'sep',9,'oct',10,'nov',11,'dec',12);
    return($tmp{"$nameIn"});
}				# end of month2num

#===============================================================================
sub myprt_array {
    local($sep,@A)=@_;$[=1;local($a);
#   myprt_array                 prints array ('sep',@array)
    foreach $a(@A){print"$a$sep";}
    print"\n" if ($sep ne "\n");
}				# end of myprt_array

#===============================================================================
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#===============================================================================
sub myprt_line  {
    local($fhx)=@_;
#   myprt_line                  prints a line with 70 '-'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "-" x 70,"\n","--- \n";
}				# end of myprt_line
		 
#===============================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    $npoints=10*(1+int($npoints/10))
	if ( int($npoints/10)!=($npoints/10) );

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
	    $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ($i==($npoints/10) && $ctprev>=9){
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else                                   {
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }
	last if ($num>$num_in);
    }
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

#===============================================================================
sub myprt_points80 {
   local ($num_in) = @_; 
   local ($tmp9, $tmp8, $tmp7, $tmp, $out, $ct, $i);
   $[=1;

   $tmp9 = "....,...."; $tmp8 =  "...,...."; $tmp7 =   "..,....";
   $ct   = (  int ( ($num_in -1 ) / 80 )  *  8  );
   $out  = "$tmp9";
   if    ( $ct == 0 ) {for( $i=1; $i<8; $i++ )  {$out .= "$i" . "$tmp9" ;}
		       $out .= "8";}
   elsif ( $ct == 8 ) {$out .= "9" . "$tmp9";
		       for( $i=2; $i<8; $i++ )  {$tmp = $ct+$i;
						 $out .= $tmp . "$tmp8" ;}
		       $out .= "16";}
   elsif (($ct>8) && 
	  ($ct<96) )  {for( $i=1; $i<8; $i++ )  {$tmp = $ct+$i;
						 $out .= $tmp . "$tmp8" ;}
		       $tmp = $ct+8;
		       $out .= $tmp;}
   elsif ( $ct == 96) {for( $i=1; $i<=3; $i++ ) {$tmp = $ct+$i;
						 $out .= $tmp . "$tmp8" ;}
		       for( $i=4; $i<8; $i++ )  {$tmp = $ct+$i;
						 $out .= $tmp . "$tmp7" ;}
		       $tmp = $ct+8;
		       $out .= $tmp ;}
   else               {for( $i=1; $i<8 ; $i++ ) {$tmp = $ct+$i;
						 $out .= $tmp . "$tmp7" ;}
		       $tmp = $ct+8;
		       $out .= $tmp ;}
   $myprt_points80=$out;
}				# end of myprt_points80

#===============================================================================
sub myprt_strings {
    local($nperlineLoc,$LnumLoc,@tmpLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   myprt_strings                       
#       in:                     $nperlineLoc :  number of points per line
#       in:                     $Lnum :         write numbers if 1
#       in:                     @tmpLoc=($string1,$string2): strings
#                                               note: name1=string1,name2=string2
#                               e.g.      ....,....1
#                                   name1 ABCDAAAAAA
#                                   name2 KKKKKKKKKK
#                                         ....,....2
#                                   name1 YYYYYY
#                                   name2 KKKKKK
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."myprt_strings";
    $fhinLoc="FHIN_"."myprt_strings";$fhoutLoc="FHOUT_"."myprt_strings";
				# check arguments
    return(&errSbr("not def nperlineLoc!"))      if (! defined $nperlineLoc);
    return(&errSbr("not def LnumLoc!"))          if (! defined $LnumLoc);
    return(&errSbr("not def ARRAYtmpLoc!"))      if (! defined @tmpLoc);
    return(&errSbr("empty ARRAYtmpLoc!"))        if (! $#tmpLoc);
#    return(&errSbr("not def !"))          if (! defined $);
    
    $#tmpValLoc=0;
    $#tmpKwdLoc=0;
				# any names given?
    foreach $tmp (@tmpLoc){
	if ($tmp=~/^(.+)=(.+)$/){
	    $tmp_kwd=$1;
	    $tmp_val=$2;
	    push(@tmpValLoc,$tmp_val);
	    push(@tmpKwdLoc,$tmp_kwd);}
	else {
	    push(@tmpValLoc,$tmp);
	}}
    if (! $#tmpKwdLoc){
	foreach $it (1..$#tmpLoc){
	    push(@tmpKwdLoc,sprintf("%3d",$it));
	}}
				# now do it 
    $tmp_len=   length($tmpValLoc[1]);
    $tmp_numrow=int($tmp_len/$nperlineLoc)+1;
    $tmp_wrt=   0;
    foreach $ittmp_block (1..$tmp_numrow){
	$tmp_beg=($ittmp_block-1)*$nperlineLoc+1;
	$tmp_end= $ittmp_block   *$nperlineLoc;
	$tmp_end= $tmp_len      if ($tmp_end > $tmp_len);
				# numbers
	if ($LnumLoc){
	    $tmp_wrt.=sprintf("%-5s: "," ");
	    $tmp_wrt.=&myprt_npoints($nperlineLoc,$tmp_end)."\n";
	}
	    
				# data
	foreach $ittmp_data (1..$#tmpValLoc){
	    $tmp_wrt.=sprintf("%-5s: ",$tmpKwdLoc[$ittmp_data]);
	    $tmp_wrt.=substr($tmpValLoc[$ittmp_data],$tmp_beg,(1+$tmp_end-$tmp_beg))."\n";
	}
    }
				# slim-is-in
    $#tmpKwdLoc=$#tmpValLoc=0;
    return(1,"ok $sbrName",$tmp_wrt);
}				# end of myprt_strings

#===============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt
		 
#===============================================================================
sub printm { 
    local ($txt,@fh) = @_ ;local ($fh);$[ =1 ;
#--------------------------------------------------------------------------------
#   printm                      print on multiple filehandles (in:$txt,@fh; out:print)
#       in:                     $txt,@fh,
#       out:                    print on all @fh
#--------------------------------------------------------------------------------
    foreach $fh (@fh) { 
	print $fh $txt if (! eof($fh) || $fh eq "STDOUT" ); }
}				# end of printm

#===============================================================================
sub prtRemain {
    local($timeBegLoc,$fileInLoc,$nFileLoc,$ctFileLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prtRemain                   writes remaining time
#       in:                     $timeBegLoc: time when current job began
#       in:                     $fileInLoc : currently treated file
#       in:                     $nFileLoc  : number of all files (100% of job)
#       in:                     $ctFileLoc : current file number (x% of job)
#       out:                    1|0,msg, sprintf($line)
#-------------------------------------------------------------------------------
    $sbrName="scr:"."prtRemain";
    $ncharFileLoc=  "30"        if (! defined $ncharFileLoc);
				# check arguments
    $timeBegLoc=time            if (! $timeBegLoc);
    $estimate=  &fctRunTimeLeft($timeBeg,$nFileLoc,$ctFileLoc);
    $ncharFileLoc=length($fileInLoc)   if (length($fileInLoc) > $ncharFileLoc);
    if ($ctFileLoc < 5) {
	$tmp=sprintf("--- %-".$ncharFileLoc."s %4d (%5.1f%-1s)\n",
		     $fileInLoc,$ctFileLoc,(100*$ctFileLoc/$nFileLoc),"%"); 
	return($tmp); }
    if ($ctFileLoc < $nFileLoc) {
	$tmp=sprintf("--- %-".$ncharFileLoc."s %4d (%5.1f%-1s) wait: %-s\n",
		     $fileInLoc,$ctFileLoc,(100*$ctFileLoc/$nFileLoc),"%",$estimate); 
	return($tmp); }
				# fin
    $tmp=    sprintf("--- %-".$ncharFileLoc."s %4d (%5.1f%-1s) -> done it!\n",
		     $fileInLoc,$ctFileLoc,(100*$ctFileLoc/$nFileLoc),"%"); 
    return($tmp);
}				# end of prtRemain


1;
