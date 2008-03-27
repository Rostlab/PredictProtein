#!/usr/bin/perl
##!/usr/bin/perl -w

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
	    $tmp{$kwd}=1;
	}
    }
    $msgHere="";
       				# ------------------------------
       				# exceptions to kill
    if (0){
	if (defined $par{"exeNokill"} && length($par{"exeNokill"})>5){
	    $#kwdnokill=0;
	    @kwdnokill=split(/,/,$par{"exeNokill"});
	}
    }
				# ------------------------------
    foreach $kwd (@kwd){	# file existence
	next if ($kwd =~ /^file(Out|Help|Def)/i);
	next if (defined $tmp{$kwd});
	$kwd2=$kwd;$kwd2=~s/\W//g;
	next if (defined $tmp{$kwd2});
	
	next if (defined $tmp{$kwd});
	if   ($kwd=~/^exe/) { 
	    $msgHere.="*** ERROR executable ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});
	    $msgHere.="*** ERROR executable ($kwd) '".$par{$kwd}."' not executable!\n".
                "***       do the following \t 'chmod +x ".$par{$kwd}."'\n"
                    if ($par{$kwd} !~ /lib/ && -e $par{$kwd} && ! -x $par{$kwd});}
	elsif($kwd=~/^file/){
	    next if ($par{$kwd} eq "unk" || length($par{$kwd})==0 || !$par{$kwd});
	    $msgHere.="*** ERROR file ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});} # 
    }
    return(0,$msgHere) if ($msgHere=~/ERROR/);
    return(1,"ok $sbrName");
}				# end of brIniErr

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
    $sbrName="lib-col:brIniHelp"; 
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
	if ($#scrSpecialLoc > 0 && (! defined $tmp{"loop"} || ! $tmp{"loop"})) {
	    print "-" x 80,"\n"; 
	    print "---    'special' keywords:\n"; 
	    print @scrSpecialLoc,"\n"; }
        if (defined %par) {
	    @kwdLoc=sort keys (%par);
	    if ($#kwdLoc>1){
		print $syntaxLoc;
		$ct=0;
		$tmpwrt="OPT  ";
		foreach $kwd (@kwdLoc){
		    $tmp=substr($kwd,1,3);
		    next if (defined $tmp{"s_k_i_p"} && 
			     $tmp{"s_k_i_p"} =~/$tmp/);
		    ++$ct;
		    $tmpwrt.=sprintf("%-18s ",$kwd);
		    if ($ct==4){
			$ct=0;
			$tmpwrt.="\nOPT  ";
		    }}
		$tmpwrt=~s/OPT  $//g;
		print $tmpwrt,"\n";
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
                foreach $kwd (@kwdLoc){
		    $tmp=substr($kwd,1,3);
		    next if (defined $tmp{"s_k_i_p"} && 
			     $tmp{"s_k_i_p"} =~/$tmp/);
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
	    $tmpItself=$tmp{"sourceFile"};
	    $tmpItself=$tmp{"itself"} if (defined $tmp{"itself"} && -e $tmp{"itself"});
            ($Lok,$msg,%def)=
		&brIniHelpRdItself($tmpItself);
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
	if (! defined $tmp{"loop"} && ! $tmp{"loop"} && 
	    (defined $tmpSpecial || 
	     ($kwdHelp eq "special" && defined $tmp{"special"}))){
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
    $sbrName=""."brIniHelpRdItself";$fhinLoc="FHIN_"."brIniHelpRdItself";

    open($fhinLoc,$fileInLoc) || 
	return(0,"*** ERROR $sbrName: failed reading itself ($fileInLoc)!\n");
                                # read file
    while (<$fhinLoc>) {        # search for initialising subroutine
        last if ($_=/^su[b] iniDef.*\s*\{/);}
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
    $sbrName="lib-col:brIniSet";
    @kwd=sort keys(%par) if (defined %par && %par);
				# ------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwd){
        if (defined $kwd && length($kwd)>=1 && defined $par{$kwd}){
            push(@tmp,$kwd);}
	else { 
	    print "-*- WARN $sbrName: for kwd=$kwd, par{kwd} not defined!\n";
	    die;
	}
    }
    @kwd=@tmp;
				# jobId
    $par{"jobid"}=$$ 
	if (! defined $par{"jobid"} || $par{"jobid"} eq 'jobid' || length($par{"jobid"})<1);
				# ------------------------------
				# add jobid
    foreach $kwd (@kwd){
	$par{$kwd}=~s/jobid/$par{"jobid"}/;}

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
            $tmp=$par{"dirOut"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $cmd="mkdir -p -m +rw".$tmp;
#	    $Lok= mkdir ($tmp,umask);
#	    print 
#		"*** $sbrName failed making directory '",
#		$par{"dirOut"},"'\n" if (! $Lok);
	    system("$cmd");
	    print "--- $sbrName system '$cmd'\n" if ($par{"verb2"});
	}
				# add slash
	$par{"dirOut"}.="/"     if (-d $par{"dirOut"} && $par{"dirOut"} !~/\/$/);
	foreach $kwd (@kwdFileOut){
	    next if (-e $par{$kwd});
	    next if ($par{$kwd} =~ /^$par{"dirOut"}/);
	    next if ($par{$kwd} eq "unk" || ! $par{$kwd});
	    next if ($kwd=~/trace|screen/i);
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
#	    $Lok= mkdir ($tmp,umask);
#	    print "*** $sbrName failed making directory '",$par{"dirWork"},"'\n" if (! $Lok);
	    $cmd="mkdir -p -m +rw ".$tmp;
	    system("$cmd");
	    print "--- $sbrName system '$cmd'\n" if ($par{"verb2"});
	}
	$par{"dirWork"}.="/" if (-d $par{"dirWork"} && $par{"dirWork"} !~/\/$/); # add slash
	foreach $kwd (@kwd){
	    next if ($kwd !~ /^file/);
	    next if ($kwd =~ /^file(In|Help|Def)/i);
	    next if ($kwd =~ /^fileOut/ && $kwd !~/trace|screen/i);
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
#	    next if ($kwd !~ /^exe/);
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
    $sbrName="lib-col:"."brIniWrt";
    
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
	next if ($kwd=~/^\s*(dir|ext|kwd|notation|text|known)/);	# hack br 2000-02
	next if ($kwd=~/expl$/);
	next if (length($par{$kwd})<1);
	if ($kwd =~/^fileOut/) {
	    push(@kwd2,$kwd);
	    next;}
	next if ($par{$kwd} eq "unk");
	next if (defined $exclLoc{$kwd}); # exclusion required
	next if ($exclLoc2 && $kwd =~/$exclLoc2/);
	printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{$kwd};}
				# ------------------------------
    if ($#kwd2>0){		# output files
	print $fhTraceLocSbr "--- \n","--- Output files:\n";
	foreach $kwd (@kwd2) {
	    next if ($par{$kwd} eq "unk"|| ! $par{$kwd});
	    next if (defined $exclLoc{$kwd}); # exclusion required
	    next if ($exclLoc && $kwd =~ /$exclLoc2/);
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
sub convert_acc {
    local ($aa,$acc,$char,$mode) = @_ ;
    local ($it,$tmpacc,$valreturn);
#--------------------------------------------------------------------------------
#    convert_acc                converts accessibility (acc) to relative acc
#                               default output is just relative percentage (char = 'unk')
#         in:                   AA, (one letter symbol), acc (Angstroem),char (unk or:
#                    note:      output is relative percentage, default if char empty or='unk'
#                                    ============
#                               char='15:100_b:e' -> returns symbols 
#                                    ============
#                                    b for relacc <15, e for relacc>=15
#                                    ===============
#                               char='4:15:100_b:i:e' -> returns symbols 
#                                    ===============
#                                    b for relacc <4, i: 4<=relacc<15, e for relacc>=15
#         in:                   .... $mode:
#                               mode=''=default, '3ang', '5ang', '07ang' -> different water
#                                    radius, 'RS' then X=0
#         out:                  converted (with return)
#--------------------------------------------------------------------------------

    &exposure_normalise_prepare($mode) if (! defined %NORM_EXP || %NORM_EXP);
				# default (3 states)
    if ( ! defined $char || $char eq "unk") {
	$valreturn=  &exposure_normalise($acc,$aa);}
				# optional e.g. char='15:100_b:e'
    elsif ($char =~ /\d:\d/) {
	if (! %NORM_EXP ){print "*** ERROR in convert_acc: NORM_EXP empty \n*** please,",
			  print "    do initialise with exposure_normalise_prepare\n";
			  exit;}
	$tmpacc= &exposure_normalise($acc,$aa);

	@tmp=split(/_/,$char);@tmp1=split(/:/,$tmp[1]);@tmp2=split(/:/,$tmp[2]);
	if   ($tmpacc<$tmp1[1])      {
	    $valreturn=$tmp2[1];}
	elsif($tmpacc>=$tmp1[$#tmp1-1]){
	    $valreturn=$tmp2[$#tmp1];}
	else { 
	    for ($it=2;$it<$#tmp1;++$it) {
		if ( ($tmpacc>=$tmp1[$it-1]) && ($tmpacc<$tmp1[$it+1]) ) {
		    $valreturn=$tmp2[$it]; 
		    last; }}} }
    else {print "*** ERROR calling convert_acc (lib-col) \n";
	  print "***       acc=$acc, aa=$aa, char passed (eg. 15:100_b:4)=$char, not ok\n";
	  exit;}
    $valreturn=100 if ($valreturn>100);	# saturation (shouldnt happen, should it?)
    return $valreturn;
}				# end of convert_acc

#===============================================================================
sub convert_accRel2acc {
    local ($accRel,$aaLoc) = @_ ;
    local ($sbrName);
#--------------------------------------------------------------------------------
#    convert_accRel2acc         converts relative accessibility (accRel) to full acc
#       in:                     AA, (one letter symbol), accRel (0-100), char (unk or:
#                    note:      output is accessibility in Angstroem if char empty or='unk'
#       out:                    converted (with return, max=248)
#       out:                    1|0,converted
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $sbrName="";
				# check arguments
    return(&errSbr("not def accRel!"))  if (! defined $accRel);
    $aaLoc="A"                          if (! defined $aaLoc);
                                # convert case
    $aaLoc=~tr/[a-z]/[A-Z]/             if ($aaLoc=~/[a-z]/);
				# initialise the field
    &exposure_normalise_prepare()       if (! defined %NORM_EXP);

    if (defined $NORM_EXP{$aaLoc}){
        $valreturn=int($accRel*$NORM_EXP{$aaLoc}/100);}
    else {
        return(0,"*** ERROR $sbrName: accRel=$accRel, aa=$aaLoc, no NORM_EXP\n");}
        
                                # saturation (shouldnt happen, should it?)
    $valreturn=$NORM_EXP{"max"} if ($valreturn>$NORM_EXP{"max"});
    
    return(1,$valreturn);
}				# end of convert_accRel2acc

#===============================================================================
sub convert_accRel2oneDigit {
    local ($accRelLoc) = @_;
    $[=1;
#----------------------------------------------------------------------
#   convert_accRel2oneDigit     project relative acc to numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       out:                    1|0,msg,$converted_acc
#       err:                    (1,'ok'), (0,'message')
#----------------------------------------------------------------------
				# check input
    return(0,"*** ERROR convert_accRel2oneDigit: relAcc=$accRelLoc???\n")
	if ( $accRelLoc < 0 );
				# SQRT
    $out= int ( sqrt ($accRelLoc) );
                                # saturation: limit to 9
    $out= 9  if ( $out >= 10 );
    return(1,"ok",$out);
}				# end of convert_accRel2oneDigit

#===============================================================================
sub convert_sec {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_sec                converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#                               char=HL    -> H=H,I,G  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure to convert
#         out:                  converted (with return)
#--------------------------------------------------------------------------------
				# default (3 states)
    if ( !defined $char || length($char)==0 || $char eq "HEL" || ! $char) {
	return "H" if ($sec=~/[HIG]/);
	return "E" if ($sec=~/[EB]/);
	return "L";}
				# optional
    elsif ($char eq "HL")    { return "H" if ($sec=~/[HIG]/);
			       return "L";}
    elsif ($char eq "HELT")  { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    elsif ($char eq "HELB")  { return "H" if ($sec=~/HIG/);
			       return "E" if ($sec=~/[E]/);
			       return "B" if ($sec=~/[B]/);
			       return "L";}
    elsif ($char eq "HELBT") { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "B" if ($sec=~/[E]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    else { print "*** ERROR calling convert_sec (lib-col), sec=$sec, or char=$char, not ok\n";
	   return(0);}
}				# end of convert_sec

#===============================================================================
sub convert_secFine {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_secFine            takes an entire string ('HEL') and fine-tunes: ' EHH'-> '  HH'
#                               char=HL    -> H=H,I,G  L=rest
#                               char=EL    -> E=E,B    L=rest
#                               char=TL    -> T=T, single B  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#                               char=HELBGT-> H=H,I G=G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure-string to convert
#         out:                  (1|0,$msg,converted)
#--------------------------------------------------------------------------------
    $sbrName="lib-prot:"."convert_secFine";
				# default
    $char="HEL"                 if (! defined $char || ! $char);
				# unused
    if    ($char eq "HL")     { $sec=~s/[IG]/H/g;  $sec=~s/[EBTS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "EL")     { $sec=~s/[EB]/E/g;  $sec=~s/[HIGTS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "TL")     { $sec=~s/[^B]B[^B]/T/g; 
				$sec=~s/[^T]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HEL")    { $sec=~s/[IG]/H/g;  $sec=~s/[TS !]/L/g;
				$sec=~s/B/E/g;
				$sec=~s/LEH/LLH/g; $sec=~s/HEL/HLL/g; # <-- fine
				return(1,"ok",$sec); }
    elsif ($char eq "HELT")   { $sec=~s/[IG]/H/g;  
				$sec=~s/[S !]/L/g;
				$sec=~s/B/E/g;
				$sec=~s/LEH/LLH/g; $sec=~s/HEL/HLL/g; # <-- fine
				return(1,"ok",$sec); }
    elsif ($char eq "HELB")   { $sec=~s/[IG]/H/g;  $sec=~s/[TS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HELBT")  { $sec=~s/[IG]/H/g;  $sec=~s/[S !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HELBGT") { $sec=~s/[I]/H/g;  $sec=~s/[S !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "Hcap")   { $sec=~s/[IG]/H/g;
				$sec=~s/[^H]HH[^H]/LLLL/g;    # too short (< 3)
				$sec=~s/^HH[^H]/LLL/g;        # too short (< 3)
				$sec=~s/[^H]HH$/LLL/g;        # too short (< 3)
				$sec=~s/[^H]H(H+)/Ln$1/g;     # N-cap -> 'n'
				$sec=~s/([nH]H+)H[^H]/$1cL/g; # C-cap -> 'c'
				$sec=~s/[^ncH]/L/g;           # others -> L
				$sec=~s/(Hc)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;         # correct 'nLLn'
				return(1,"ok",$sec); }
    elsif ($char eq "Ecap")   { $sec=~s/B/E/g;
				$sec=~s/[^E]E[^E]/LLL/g;      # too short (< 2)
				$sec=~s/^E[^E]/LL/g;          # too short (< 2)
				$sec=~s/[^E]E$/LL/g;          # too short (< 2)
				$sec=~s/[^E]E(E+)/Ln$1/g;     # N-cap -> 'n'
				$sec=~s/([nE]E*)E[^E]/$1cL/g; # C-cap -> 'c'
				$sec=~s/[^ncE]/L/g;           # others -> L
				$sec=~s/(Ec)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;         # correct 'nLLn'
				return(1,"ok",$sec); }
    elsif ($char eq "HEcap")  { $sec=~s/B/E/g;
				$sec=~s/[IG]/H/g;
				$sec=~s/[^HE]/L/g;               # nonH, nonE -> L

				$sec=~s/([^H])HH([^H])/$1LL$2/g; # too short (< 3)
				$sec=~s/^HH([^H])/LL$1/g;        # too short (< 3)
				$sec=~s/([^H])HH$/$1LL/g;        # too short (< 3)

				$sec=~s/([^E])E([^E])/$1L$2/g;   # too short (< 2)
				$sec=~s/^E([^E])/L$1/g;          # too short (< 2)
				$sec=~s/([^E])E$/$1L/g;          # too short (< 2)

				$sec=~s/([^H])H(H+)/$1n$2/g;     # N-cap H -> 'n'
				$sec=~s/([nH]H+)H([^H])/$1c$2/g; # C-cap H -> 'c'

				$sec=~s/([^E])E(E+)/$1n$2/g;     # N-cap E -> 'n'
				$sec=~s/([nE]E*)E([^E])/$1c$2/g; # C-cap E -> 'c'

				$sec=~s/([EH]c)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;            # correct 'nLLn'
				return(1,"ok",$sec); }
    else { 
	return(&errSbr("char=$char, not recognised\n")); }
}				# end of convert_secFine

#===============================================================================
sub date_monthName2num {
    local($txtIn) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
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
    $out=$day."-".$num."-".$year;
    return(1,$out);
}				# end of date_monthDayYear2num

#===============================================================================
sub dsspRdSeq {
    local ($fileIn,$chainIn,$begIn,$endIn) = @_ ;
    local ($Lread,$sbrName,$fhin,$aa,$aa2,$seq,$seqC,$chainRd,$pos);
    $[=1;
#----------------------------------------------------------------------
#   dsspRdSeq                   extracts the sequence from DSSP
#       in:                     $file,$chain,$beg,$end
#       in:                     for wild cards beg="", end=""
#       out:                    $Lok,$seq,$seqC (second replaced a-z to C)
#----------------------------------------------------------------------
    $sbrName = "lib-col:dsspRdSeq" ;$fhin="fhinDssp";
    &open_file("$fhin","$fileIn") ||
        return(0,"*** ERROR $sbrName: failed to open input $fileIn\n");
				#----------------------------------------
				# extract input
    if (defined $chainIn && length($chainIn)>0 && $chainIn=~/[A-Z0-9]/){
	$chainIn=~s/\s//g;$chainIn =~tr/[a-z]/[A-Z]/; }else{$chainIn = "*" ;}
    $begIn = "*" if (! defined $begIn || length($begIn)==0); $begIn=~s/\s//g;;
    $endIn = "*" if (! defined $endIn || length($endIn)==0); $endIn=~s/\s//g;;
				#--------------------------------------------------
				# read in file
    while ( <$fhin> ) { 
	last if ( /^  \#  RESIDUE/ ); }	# skip anything before data...
    $seq=$seqC="";
    while ( <$fhin> ) {		# read sequence
	$Lread=1;
	$chainRd=substr($_,12,1); 
	$pos=    substr($_,7,5); $pos=~s/\s//g;

	next  if (($chainRd ne "$chainIn" && $chainIn ne "*" ) || # check chain
                  ($begIn ne "*"  && $pos < $begIn) || # check begin
                  ($endIn ne "*"  && $pos > $endIn)) ; # check end

	$aa=substr($_,14,1);
	$aa2=$aa;if ($aa2=~/[a-z]/){$aa2="C";}	# lower case to C
	$seq.=$aa;$seqC.=$aa2; } close ($fhin);
    return(1,$seq,$seqC) if (length($seq)>0);
    return(0);
}                               # end of: dsspRdSeq 

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

#==========================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#    exposure_normalise_prepare normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
        $NORM_EXP{"max"}=248;

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} = 179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} =  99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} = 199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} = 189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} = 189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} = 259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} = 209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} = 200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 239;  $NORM_EXP{"Z"} =269;         # E or Q
        $NORM_EXP{"max"}=309;

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} = 209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} = 139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} = 199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} = 189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} = 189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} = 309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} = 239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} = 230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 259;  $NORM_EXP{"Z"} =329;         # E or Q
        $NORM_EXP{"max"}=399;

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} = 119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} =  99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} = 169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} = 159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} = 159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} = 169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} = 149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} = 230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 189;  $NORM_EXP{"Z"} =175;         # E or Q
        $NORM_EXP{"max"}=230;

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =194;         # E or Q
        $NORM_EXP{"max"}=248;

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
        $NORM_EXP{"max"}=248;
    }
}				# end of exposure_normalise_prepare 

#===============================================================================
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise          normalise DSSP accessibility with maximal values
#                               (taken from Schneider)
#----------------------------------------------------------------------
    if ( $aa_in !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ]/ ) {
	if ( $aa_in=~/[!.]/ ) { $aa_in = "X"; }
	else { print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	       exit; }}

    if ($NORM_EXP{$aa_in}>0) { $exp_normalise= 100 * ($exp_in / $NORM_EXP{$aa_in});}
    else { print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	   $NORM_EXP{$aa_in},"\n***\n";
	   $exp_normalise=$exp_in/1.8; # ugly ...
	   if ($exp_normalise>100){$exp_normalise=100;}}
    return $exp_normalise;
}				# end of exposure_normalise

#===============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digit     project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
				# SQRT
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

#===============================================================================
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
    $sbrName="lib-col:fastaRdMul";$fhinLoc="FHIN_"."$sbrName";

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

#===============================================================================
sub fctRunTime {
    local($timeBegLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeLeft              estimates the run time of the job
#       in:                     $timeBegLoc : time (time) when job began
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."fctRunTimeLeft";

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
}				# end of fctRunTimeLeft

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
    $sbrName="lib-col:"."fctRunTimeLeft";

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
    $sbrName="lib-col:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
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
sub func_absolute {
    local ($num)=@_;local ($tmp);
#----------------------------------------------------------------------
#   func_absolute               compiles the absolute value
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
    if ($num>=0){
	return($num);}
    else {
	$tmp=(-1)*$num;
	return($tmp);}
}				# end of func_absolute

#===============================================================================
sub gcgRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   gcgRd                       reads sequence in GCG format
#       in:                     $fileInLoc
#       out:                    1|0,$id,$seq 
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:gcgRd";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    $seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;$line=$_;
	if ($line=~/^\s*(\S+)\s*from\s*:/){
	    $id=$1;
	    next;}
	next if ($line !~ /^\s*\d+\s+(.*)$/);
	$tmp=$1;$tmp=~s/\s//g;
	$seq.=$tmp;}close($fhinLoc);

    return(0,"*** ERROR $sbrName: file=$fileInLoc, no sequence found\n") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of gcgRd

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

#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

#==============================================================================
sub getFileFormatQuick {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormatQuick          quick scan for file format: assumptions
#                               file exists
#                               file is db format (i.e. no list)
#       in:                     file
#       out:                    0|1,format
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."getFileFormatQuick";$fhinLoc="FHIN_"."getFileFormatQuick";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # alignments (EMBL 1)
    return(1,"HSSP")         if (&is_hssp($fileInLoc));
    return(1,"STRIP")        if (&is_strip($fileInLoc));
#    return(1,"STRIPOLD")     if (&is_strip_old($fileInLoc));
    return(1,"DSSP")         if (&is_dssp($fileInLoc));
    return(1,"FSSP")         if (&is_fssp($fileInLoc));
                                # alignments (EMBL 1)
    return(1,"DAF")          if (&isDaf($fileInLoc));
    return(1,"SAF")          if (&isSaf($fileInLoc));
                                # alignments other
    return(1,"MSF")          if (&isMsf($fileInLoc));
    return(1,"FASTAMUL")     if (&isFastaMul($fileInLoc));
    return(1,"PIRMUL")       if (&isPirMul($fileInLoc));
                                # sequences
    return(1,"FASTA")        if (&isFasta($fileInLoc));
    return(1,"SWISS")        if (&isSwiss($fileInLoc));
    return(1,"PIR")          if (&isPir($fileInLoc));
    return(1,"GCG")          if (&isGcg($fileInLoc));
    return(1,"PDB")          if (&isPdb($fileInLoc));
                                # PP
    return(1,"PPCOL")        if (&is_ppcol($fileInLoc));
				# NN
    return(1,"NNDB")         if (&is_rdb_nnDb($fileInLoc));
                                # PHD
    return(1,"PHDRDBBOTH")   if (&isPhdBoth($fileInLoc));
    return(1,"PHDRDBACC")    if (&isPhdAcc($fileInLoc));
    return(1,"PHDRDBHTM")    if (&isPhdHtm($fileInLoc));
    return(1,"PHDRDBHTMREF") if (&is_rdb_htmref($fileInLoc));
    return(1,"PHDRDBHTMTOP") if (&is_rdb_htmtop($fileInLoc));
    return(1,"PHDRDBSEC")    if (&isPhdSec($fileInLoc));
                                # RDB
    return(1,"RDB")          if (&isRdb($fileInLoc));
    return(1,"unk");
}				# end of getFileFormatQuick

#==============================================================================
sub getFileFormatQuicker {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormatQuicker        quicker scan for file format: assumptions
#       out ???:                <unk>
#       out ali:                <HSSP|MSF|SAF|DAF|FASTAMUL|PIRMUL|>
#       out seq:                <FASTA|PIR|SWISS|GCG|DSSP|FSSP|PDB|>
#       out seq:                SEQ=single one-letter sequence
#       out phd:                <PPCOL|NNDB|PHD2PARA>
#       out phd:                <PHDRDBBOTH|PHDRDBACC|PHDRDBSEC|PHDRDBHTM|PHDRDBHTMREF|PHDRDBTOP>
#       out file:               RDB
#       in:                     file
#       out:                    0|1,format:
#                         
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."getFileFormatQuicker";$fhinLoc="FHIN_"."getFileFormatQuicker";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return("*** ERROR $sbrName: failed opening filein=$fileInLoc");
				# read first 50 lines
    $ctline=$#tmp=0;
    while(<$fhinLoc>){ $_=~s/\n//g;
		       push(@tmp,$_);
		       ++$ct;
		       last if ($ct>10); }
    close($fhinLoc);
				# ------------------------------
				# now test 
				# ------------------------------
                                # alignments (EMBL 1)
    return(1,"HSSP")            if ($tmp[1]=~/^HSSP/);
    return(1,"STRIP")           if ($tmp[1]=~/===  MAXHOM-STRIP  ===/);
    return(1,"DSSP")            if ($tmp[1]=~/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i);
    return(1,"FSSP")            if ($tmp[1]=~/^FSSP/);
	
				# ------------------------------
                                # alignments (EMBL 2)
    return(1,"DAF")             if ($tmp[1]=~/^\#\s*DAF/);
    return(1,"SAF")             if ($tmp[1]=~/^\#\s*SAF/);
    return(1,"SAF")             if ($tmp[1]=~/clustalW/i);

				# ------------------------------
                                # alignments other
    return(1,"MSF")             if ($tmp[1]=~/pileup/i);
    return(1,"MSF")             if ($tmp[1]=~/\s*MSF[\s:]+/);
    
				# ------------------------------
				# fasta
    if ($tmp[1]=~/^\s*\>\s*\w+/ && 
	$tmp[2]=~/^[ABCDEFGHIKLMNPQRSTVWXYZx\.~_! ]+$/i){
	$ct=1;
	foreach $it (3..$#tmp){
	    if ($tmp[$it]=~/^\s*\>\s*\w+/){
		++$ct;
		last;}}
	return(1,"FASTAMUL")    if ($ct>1);
	return(1,"FASTA");}
    
				# ------------------------------
				# PIR: strict old definition
    if ($tmp[1]=~/^\s*\>P\d?\s*\;/    && 
	$tmp[3]=~/^[ABCDEFGHIKLMNPQRSTVWXYZx\.~_! ]+$/i){
	$ct=1;
	foreach $it (3..$#tmp){
	    if ($tmp[$it]=~/^\s*\>P\d?\s*\;/    && 
		$tmp[$it+2]=~/^[ABCDEFGHIKLMNPQRSTVWXYZx\.~_! ]+$/i){
		++$ct;
		last;}}
	return(1,"PIRMUL")      if ($ct>1);
	return(1,"PIR");}

				# ------------------------------
                                # sequences
    return(1,"SWISS")           if ($tmp[1]=~/^ID   /);
    return(1,"PDB")             if ($tmp[1]=~/HEADER\s+.*\d\w\w\w\s+\d+\s*$/);

				# ------------------------------
				# br stuff
                                # PP
    return(1,"PPCOL")           if ($tmp[1]=~/^\#\s*pp.*col/i);
				# NN
    return(1,"NNDB")            if ($tmp[1]=~/^\#\s*Perl-RDB.*NNdb/i);
    return(1,"NNJCT")           if ($tmp[1]=~/^\*\s*NNout_jct/);
                                # PHD
    return(1,"PHD2PARA")        if ($tmp[1]=~/PHD\d*\s+PARA/);
    if ($tmp[1]=~/^\#?\s*Perl-RDB/){
	return(1,"PHDRDBBOTH")  if ($tmp[2]=~/PHDacc/i && $tmp[2]=~/PHDsec/i );
	return(1,"PHDRDBACC")   if ($tmp[2]=~/PHDacc/i );
	return(1,"PHDRDBHTM")   if ($tmp[2]=~/PHDhtm/i );
	return(1,"PHDRDBHTMREF")if ($tmp[2]=~/^\#\s*PHD\s*htm.*ref/ );
	return(1,"PHDRDBHTMTOP")if ($tmp[2]=~/^\#\s*PHD\s*htm.*top/ );
	return(1,"PHDRDBSEC")   if ($tmp[2]=~/PHDsec/i );
                                # RDB
	return(1,"RDB");}
				# ------------------------------
				# GCG
    return(1,"GCG")             if (&isGcgArray(@tmp));
    
				# ------------------------------
				# PIR: new
    if ($tmp[1]=~/^\s*\>\s*/    && 
	$tmp[3]=~/^[ABCDEFGHIKLMNPQRSTVWXYZx\.~_! ]+$/i){
	$ct=1;
	foreach $it (3..$#tmp){
	    if ($tmp[$it]=~/^\s*\>\s*/    && 
		$tmp[$it+2]=~/^[ABCDEFGHIKLMNPQRSTVWXYZx\.~_! ]+$/i){
		++$ct;
		last;}}
	return(1,"PIRMUL")      if ($ct>1);
	return(1,"PIR");}
				# ------------------------------
				# simple one-letter coded sequence
    return(1,"SEQ")             if (&isSeqArray(@tmp));

    return(1,"unk");
}				# end of getFileFormatQuicker

#===============================================================================
sub getSegment {
    local($stringInLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSegment                  takes string, writes segments and boundaries
#       in:                     $stringInLoc=  '  HHH  EE HHHHHHHHHHH'
#       out:                    1|0,msg, 
#       out GLOBAL:             %segment (as reference!)
#                               $segment{"NROWS"}=   number of segments
#                               $segment{$it}=       type of segment $it (e.g. H)
#                               $segment{"beg",$it}= first residue of segment $it 
#                               $segment{"end",$it}= last residue of segment $it 
#                               $segment{"ct",$it}=  count segment of type $segment{$it}
#                                                    e.g. (L)1,(H)1,(L)2,(E)1,(H)2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."getSegment";
    $fhinLoc="FHIN_"."getSegment";$fhoutLoc="FHOUT_"."getSegment";
				# check arguments
    return(&errSbr("not def stringInLoc!"))          if (! defined $stringInLoc);
    return(&errSbr("too short stringInLoc!"))        if (length($stringInLoc)<1);

				# set zero
    $prev=""; 
    undef %segment;  
    undef %ctSegment;
    $ctSegment=0; 
				# into array
    @tmp=split(//,$stringInLoc);
    foreach $it (1..$#tmp) {	# loop over all 'residues'
	$sym=$tmp[$it];
				# continue segment
	next if ($prev eq $sym);
				# finish off previous
	$segment{"end",$ctSegment}=($it-1)
	    if ($it > 1);
				# new segment
	$prev=$sym;
	++$ctSegment;
	++$ctSegment{$sym};
	$segment{$ctSegment}=      $sym;
	$segment{"beg",$ctSegment}=$it;
	$segment{"seg",$ctSegment}=$ctSegment{$sym};
    }
				# finish off last
    $segment{"end",$ctSegment}=$#tmp;
				# store number of segments
    $segment{"NROWS"}=$ctSegment;

    $#tmp=0;			# slim-is-in
    return(1,"ok");
}				# end of getSegment

#===============================================================================
sub hydrophobicity_scales {
    local($scaleWanted) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hydrophobicity_scales       assigns values to various hydrophobicity scales
#       in:                     $scaleWanted: scale=ges|eisen|kydo|ooi|heijne|htm
#                                             0 to get all scales
#                                             'ges,kydo' for many
#                                             
#                  GES:         D Engelman, T Steitz & A Goldman ()
#                                      theory & exp
#                  EISEN:       D Eisenberg, & AD McLachlan ()
#                                      Solvation free energy   
#                  KYDO:        J Kyte & RF Doolittle
#                                      theory & stat
#                  OOI:         K Nishikawa & T Ooi
#                                      14 A contact number, occupancy numbers
#                  HEIJNE:      G von Heijne & C Blomberg
#                                      exp + theoretical HTM/non-htm
#                  HTM:         WC Wimley & S White:
#                                      experimental HTM/non-htm
#       in:                     $fileInLoc
#       note:                   URL:   http://www.genome.ad.jp/dbget/aaindex.html
#                               QUOTE: S Kawashima, H Ogata, and M Kanehisa:
#                               QUOTE: AAindex: amino acid index database. 
#                               QUOTE: Nucleic Acids Res. 27, 368-369, 1999
# 
#       out:                    (1|0,msg,%HYDRO)  implicit:
#                               $HYDRO{$kwd,$aa}=        raw score
#                               $HYDRO{$kwd,$aa,"norm"}= normalised 0-100
#       out GLOBAL:             %HYDRO
#       err:                    (1,'ok'), (0,'message')
# 
# 
#      +---------------------------------------+-----------------------------------+
#      |        RAW SCORES                     |     NORMALISED scores (0 - 100)   |
# +----+---------------------------------------+-----------------------------------+------+
# | aa | GES  EISEN   KYDO    OOI HEIJNE   HTM | GES EISEN  KYDO   OOI HEIJNE  HTM | sum  |
# +----+---------------------------------------+-----------------------------------+------+
# |                                            |                                   |      |
# | A  -6.70   0.67   1.80  -0.22 -12.04   4.08| 13.1  58.9  70.0  40.6  16.2  47.8| 41.1 |
# | R  51.50  -2.10  -4.50  -0.93  39.23   3.91|100.0   0.0   0.0  33.3 100.0  43.4| 46.1 |
# | N  20.10  -0.60  -3.50  -2.65   4.25   3.83| 53.1  31.9  11.1  15.7  42.9  41.3| 32.7 |
# | D  38.50  -1.20  -3.50  -4.12  23.22   3.02| 80.6  19.1  11.1   0.6  73.8  20.4| 34.3 |
# | C  -8.40   0.38   2.50   4.66   3.95   4.49| 10.6  52.8  77.8  90.6  42.4  58.4| 55.4 |
# | Q  17.20  -0.22  -3.50  -2.76   2.16   3.67| 48.8  40.0  11.1  14.5  39.4  37.2| 31.9 |
# | E  34.30  -0.76  -3.50  -3.64  16.81   2.23| 74.3  28.5  11.1   5.5  63.4   0.0| 30.5 |
# | G  -4.20   0.00  -0.40  -1.62  -7.85   4.24| 16.9  44.7  45.6  26.2  23.1  51.9| 34.7 |
# | H  12.60   0.64  -3.20   1.28   6.28   4.08| 41.9  58.3  14.4  55.9  46.2  47.8| 44.1 |
# | I -13.00   1.90   4.50   5.58 -18.32   4.52|  3.7  85.1 100.0 100.0   6.0  59.2| 59.0 |
# | L -11.70   1.90   3.80   5.01 -17.79   4.81|  5.7  85.1  92.2  94.2   6.8  66.7| 58.4 |
# | K  36.80  -0.57  -3.90  -4.18   9.71   3.77| 78.1  32.6   6.7   0.0  51.8  39.8| 34.8 |
# | M -14.20   2.40   1.90   3.51  -8.86   4.48|  1.9  95.7  71.1  78.8  21.4  58.1| 54.5 |
# | F -15.50   2.30   2.80   5.27 -21.98   5.38|  0.0  93.6  81.1  96.8   0.0  81.4| 58.8 |
# | P   0.80   1.20  -1.60  -3.03   5.82   3.80| 24.3  70.2  32.2  11.8  45.4  40.6| 37.4 |
# | S  -2.50   0.01  -0.80  -2.84  -1.54   4.12| 19.4  44.9  41.1  13.7  33.4  48.8| 33.6 |
# | T  -5.00   0.52  -0.70  -1.20  -4.15   4.11| 15.7  55.7  42.2  30.5  29.1  48.6| 37.0 |
# | W  -7.90   2.60  -0.90   5.20 -16.19   6.10| 11.3 100.0  40.0  96.1   9.5 100.0| 59.5 |
# | Y   2.90   1.60  -1.30   2.15  -1.51   5.19| 27.5  78.7  35.6  64.9  33.4  76.5| 52.8 |
# | V -10.90   1.50   4.20   4.45 -16.22   4.18|  6.9  76.6  96.7  88.4   9.4  50.4| 54.7 |
# +----+---------------------------------------+-----------------------------------+------+
# 
# 
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."hydrophobicity_scales";
    $scaleWanted=0              if (! defined $scaleWanted ||
				    $scaleWanted=~/all/);

    undef %HYDRO;
				# ------------------------------
				# direct for HYDRO-GES
				#    D Engelman, T Steitz & A Goldman
				#    Annu. Rev. Biophys. Chem. 15, 321-353, 1986
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/ges/){
	$HYDRO{"ges","A"}=             -6.70;
	$HYDRO{"ges","R"}=             51.50;
	$HYDRO{"ges","N"}=             20.10;
	$HYDRO{"ges","D"}=             38.50;
	$HYDRO{"ges","C"}=             -8.40;
	$HYDRO{"ges","Q"}=             17.20;
	$HYDRO{"ges","E"}=             34.30;
	$HYDRO{"ges","G"}=             -4.20;
	$HYDRO{"ges","H"}=             12.60;
	$HYDRO{"ges","I"}=            -13.00;
	$HYDRO{"ges","L"}=            -11.70;
	$HYDRO{"ges","K"}=             36.80;
	$HYDRO{"ges","M"}=            -14.20;
	$HYDRO{"ges","F"}=            -15.50;
	$HYDRO{"ges","P"}=              0.80;
	$HYDRO{"ges","S"}=             -2.50;
	$HYDRO{"ges","T"}=             -5.00;
	$HYDRO{"ges","W"}=             -7.90;
	$HYDRO{"ges","Y"}=              2.90;
	$HYDRO{"ges","V"}=            -10.90;
				# normalised (0,100)for HYDRO-GES
	$HYDRO{"ges","A","norm"}=      13.1;
	$HYDRO{"ges","R","norm"}=     100.0;
	$HYDRO{"ges","N","norm"}=      53.1;
	$HYDRO{"ges","D","norm"}=      80.6;
	$HYDRO{"ges","C","norm"}=      10.6;
	$HYDRO{"ges","Q","norm"}=      48.8;
	$HYDRO{"ges","E","norm"}=      74.3;
	$HYDRO{"ges","G","norm"}=      16.9;
	$HYDRO{"ges","H","norm"}=      41.9;
	$HYDRO{"ges","I","norm"}=       3.7;
	$HYDRO{"ges","L","norm"}=       5.7;
	$HYDRO{"ges","K","norm"}=      78.1;
	$HYDRO{"ges","M","norm"}=       1.9;
	$HYDRO{"ges","F","norm"}=       0.0;
	$HYDRO{"ges","P","norm"}=      24.3;
	$HYDRO{"ges","S","norm"}=      19.4;
	$HYDRO{"ges","T","norm"}=      15.7;
	$HYDRO{"ges","W","norm"}=      11.3;
	$HYDRO{"ges","Y","norm"}=      27.5;
	$HYDRO{"ges","V","norm"}=       6.9;
    }
				# ------------------------------
				# direct for HYDRO-EISEN
				#    D Eisenberg, & AD McLachlan
				#    Solvation energy in protein folding and binding
				#    Nature 319, 199-203 (1986)
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/eisen/){
	$HYDRO{"eisen","A"}=            0.67;
	$HYDRO{"eisen","R"}=           -2.10;
	$HYDRO{"eisen","N"}=           -0.60;
	$HYDRO{"eisen","D"}=           -1.20;
	$HYDRO{"eisen","C"}=            0.38;
	$HYDRO{"eisen","Q"}=           -0.22;
	$HYDRO{"eisen","E"}=           -0.76;
	$HYDRO{"eisen","G"}=            0.00;
	$HYDRO{"eisen","H"}=            0.64;
	$HYDRO{"eisen","I"}=            1.90;
	$HYDRO{"eisen","L"}=            1.90;
	$HYDRO{"eisen","K"}=           -0.57;
	$HYDRO{"eisen","M"}=            2.40;
	$HYDRO{"eisen","F"}=            2.30;
	$HYDRO{"eisen","P"}=            1.20;
	$HYDRO{"eisen","S"}=            0.01;
	$HYDRO{"eisen","T"}=            0.52;
	$HYDRO{"eisen","W"}=            2.60;
	$HYDRO{"eisen","Y"}=            1.60;
	$HYDRO{"eisen","V"}=            1.50;
				# normalised (0,100)for HYDRO-EISEN
	$HYDRO{"eisen","A","norm"}=    58.9;
	$HYDRO{"eisen","R","norm"}=     0.0;
	$HYDRO{"eisen","N","norm"}=    31.9;
	$HYDRO{"eisen","D","norm"}=    19.1;
	$HYDRO{"eisen","C","norm"}=    52.8;
	$HYDRO{"eisen","Q","norm"}=    40.0;
	$HYDRO{"eisen","E","norm"}=    28.5;
	$HYDRO{"eisen","G","norm"}=    44.7;
	$HYDRO{"eisen","H","norm"}=    58.3;
	$HYDRO{"eisen","I","norm"}=    85.1;
	$HYDRO{"eisen","L","norm"}=    85.1;
	$HYDRO{"eisen","K","norm"}=    32.6;
	$HYDRO{"eisen","M","norm"}=    95.7;
	$HYDRO{"eisen","F","norm"}=    93.6;
	$HYDRO{"eisen","P","norm"}=    70.2;
	$HYDRO{"eisen","S","norm"}=    44.9;
	$HYDRO{"eisen","T","norm"}=    55.7;
	$HYDRO{"eisen","W","norm"}=   100.0;
	$HYDRO{"eisen","Y","norm"}=    78.7;
	$HYDRO{"eisen","V","norm"}=    76.6;
    }
				# ------------------------------
				# direct for HYDRO-KYDO
				#    J Kyte & RF Doolittle
				#    A simple method for displaying the 
                                #    hydropathic character of a protein
				#    J. Mol. Biol. 157, 105-132 (1982)
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/kydo/){
	$HYDRO{"kydo","A"}=             1.80;
	$HYDRO{"kydo","R"}=            -4.50;
	$HYDRO{"kydo","N"}=            -3.50;
	$HYDRO{"kydo","D"}=            -3.50;
	$HYDRO{"kydo","C"}=             2.50;
	$HYDRO{"kydo","Q"}=            -3.50;
	$HYDRO{"kydo","E"}=            -3.50;
	$HYDRO{"kydo","G"}=            -0.40;
	$HYDRO{"kydo","H"}=            -3.20;
	$HYDRO{"kydo","I"}=             4.50;
	$HYDRO{"kydo","L"}=             3.80;
	$HYDRO{"kydo","K"}=            -3.90;
	$HYDRO{"kydo","M"}=             1.90;
	$HYDRO{"kydo","F"}=             2.80;
	$HYDRO{"kydo","P"}=            -1.60;
	$HYDRO{"kydo","S"}=            -0.80;
	$HYDRO{"kydo","T"}=            -0.70;
	$HYDRO{"kydo","W"}=            -0.90;
	$HYDRO{"kydo","Y"}=            -1.30;
	$HYDRO{"kydo","V"}=             4.20;
				# normalised (0,100)for HYDRO-KYDO
	$HYDRO{"kydo","A","norm"}=     70.0;
	$HYDRO{"kydo","R","norm"}=      0.0;
	$HYDRO{"kydo","N","norm"}=     11.1;
	$HYDRO{"kydo","D","norm"}=     11.1;
	$HYDRO{"kydo","C","norm"}=     77.8;
	$HYDRO{"kydo","Q","norm"}=     11.1;
	$HYDRO{"kydo","E","norm"}=     11.1;
	$HYDRO{"kydo","G","norm"}=     45.6;
	$HYDRO{"kydo","H","norm"}=     14.4;
	$HYDRO{"kydo","I","norm"}=    100.0;
	$HYDRO{"kydo","L","norm"}=     92.2;
	$HYDRO{"kydo","K","norm"}=      6.7;
	$HYDRO{"kydo","M","norm"}=     71.1;
	$HYDRO{"kydo","F","norm"}=     81.1;
	$HYDRO{"kydo","P","norm"}=     32.2;
	$HYDRO{"kydo","S","norm"}=     41.1;
	$HYDRO{"kydo","T","norm"}=     42.2;
	$HYDRO{"kydo","W","norm"}=     40.0;
	$HYDRO{"kydo","Y","norm"}=     35.6;
	$HYDRO{"kydo","V","norm"}=     96.7;
    }
				# ------------------------------
				# direct for HYDRO-OOI
				#    K Nishikawa & T Ooi
				#    Radial locations of amino acid residues in a globular protein:
				#    J. Biochem. 100, 1043-1047 (1986)
				# ------------------------------

    if (! $scaleWanted || $scaleWanted=~/ooi/){
	$HYDRO{"ooi","A"}=             -0.22;
	$HYDRO{"ooi","R"}=             -0.93;
	$HYDRO{"ooi","N"}=             -2.65;
	$HYDRO{"ooi","D"}=             -4.12;
	$HYDRO{"ooi","C"}=              4.66;
	$HYDRO{"ooi","Q"}=             -2.76;
	$HYDRO{"ooi","E"}=             -3.64;
	$HYDRO{"ooi","G"}=             -1.62;
	$HYDRO{"ooi","H"}=              1.28;
	$HYDRO{"ooi","I"}=              5.58;
	$HYDRO{"ooi","L"}=              5.01;
	$HYDRO{"ooi","K"}=             -4.18;
	$HYDRO{"ooi","M"}=              3.51;
	$HYDRO{"ooi","F"}=              5.27;
	$HYDRO{"ooi","P"}=             -3.03;
	$HYDRO{"ooi","S"}=             -2.84;
	$HYDRO{"ooi","T"}=             -1.20;
	$HYDRO{"ooi","W"}=              5.20;
	$HYDRO{"ooi","Y"}=              2.15;
	$HYDRO{"ooi","V"}=              4.45;
				# normalised (0,100)for HYDRO-OOI
	$HYDRO{"ooi","A","norm"}=      40.6;
	$HYDRO{"ooi","R","norm"}=      33.3;
	$HYDRO{"ooi","N","norm"}=      15.7;
	$HYDRO{"ooi","D","norm"}=       0.6;
	$HYDRO{"ooi","C","norm"}=      90.6;
	$HYDRO{"ooi","Q","norm"}=      14.5;
	$HYDRO{"ooi","E","norm"}=       5.5;
	$HYDRO{"ooi","G","norm"}=      26.2;
	$HYDRO{"ooi","H","norm"}=      55.9;
	$HYDRO{"ooi","I","norm"}=     100.0;
	$HYDRO{"ooi","L","norm"}=      94.2;
	$HYDRO{"ooi","K","norm"}=       0.0;
	$HYDRO{"ooi","M","norm"}=      78.8;
	$HYDRO{"ooi","F","norm"}=      96.8;
	$HYDRO{"ooi","P","norm"}=      11.8;
	$HYDRO{"ooi","S","norm"}=      13.7;
	$HYDRO{"ooi","T","norm"}=      30.5;
	$HYDRO{"ooi","W","norm"}=      96.1;
	$HYDRO{"ooi","Y","norm"}=      64.9;
	$HYDRO{"ooi","V","norm"}=      88.4;
    }
				# ------------------------------
				# direct for HYDRO-HEIJNE
				#    G von Heijne & C Blomberg
				#    Trans-membrane translocation of proteins: 
                                #    The direct transfer model
				#    Eur. J. Biochem. 97, 175-181 (1979)
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/heijne/){
	$HYDRO{"heijne","A"}=         -12.04;
	$HYDRO{"heijne","R"}=          39.23;
	$HYDRO{"heijne","N"}=           4.25;
	$HYDRO{"heijne","D"}=          23.22;
	$HYDRO{"heijne","C"}=           3.95;
	$HYDRO{"heijne","Q"}=           2.16;
	$HYDRO{"heijne","E"}=          16.81;
	$HYDRO{"heijne","G"}=          -7.85;
	$HYDRO{"heijne","H"}=           6.28;
	$HYDRO{"heijne","I"}=         -18.32;
	$HYDRO{"heijne","L"}=         -17.79;
	$HYDRO{"heijne","K"}=           9.71;
	$HYDRO{"heijne","M"}=          -8.86;
	$HYDRO{"heijne","F"}=         -21.98;
	$HYDRO{"heijne","P"}=           5.82;
	$HYDRO{"heijne","S"}=          -1.54;
	$HYDRO{"heijne","T"}=          -4.15;
	$HYDRO{"heijne","W"}=         -16.19;
	$HYDRO{"heijne","Y"}=          -1.51;
	$HYDRO{"heijne","V"}=         -16.22;
				# normalised (0,100)for HYDRO-HEIJNE
	$HYDRO{"heijne","A","norm"}=    16.2;
	$HYDRO{"heijne","R","norm"}=   100.0;
	$HYDRO{"heijne","N","norm"}=    42.9;
	$HYDRO{"heijne","D","norm"}=    73.8;
	$HYDRO{"heijne","C","norm"}=    42.4;
	$HYDRO{"heijne","Q","norm"}=    39.4;
	$HYDRO{"heijne","E","norm"}=    63.4;
	$HYDRO{"heijne","G","norm"}=    23.1;
	$HYDRO{"heijne","H","norm"}=    46.2;
	$HYDRO{"heijne","I","norm"}=     6.0;
	$HYDRO{"heijne","L","norm"}=     6.8;
	$HYDRO{"heijne","K","norm"}=    51.8;
	$HYDRO{"heijne","M","norm"}=    21.4;
	$HYDRO{"heijne","F","norm"}=     0.0;
	$HYDRO{"heijne","P","norm"}=    45.4;
	$HYDRO{"heijne","S","norm"}=    33.4;
	$HYDRO{"heijne","T","norm"}=    29.1;
	$HYDRO{"heijne","W","norm"}=     9.5;
	$HYDRO{"heijne","Y","norm"}=    33.4;
	$HYDRO{"heijne","V","norm"}=     9.4;
    }
				# ------------------------------
				# direct for HYDRO-HTM
				#    WC Wimley & S White
				#    Experimentally determined hydrophobicity 
                                #    scale for proteins at membrane
				#    Nature Structual biol. 3, 842-848 (1996)
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/htm/){
	$HYDRO{"htm","A"}=              4.08;
	$HYDRO{"htm","R"}=              3.91;
	$HYDRO{"htm","N"}=              3.83;
	$HYDRO{"htm","D"}=              3.02;
	$HYDRO{"htm","C"}=              4.49;
	$HYDRO{"htm","Q"}=              3.67;
	$HYDRO{"htm","E"}=              2.23;
	$HYDRO{"htm","G"}=              4.24;
	$HYDRO{"htm","H"}=              4.08;
	$HYDRO{"htm","I"}=              4.52;
	$HYDRO{"htm","L"}=              4.81;
	$HYDRO{"htm","K"}=              3.77;
	$HYDRO{"htm","M"}=              4.48;
	$HYDRO{"htm","F"}=              5.38;
	$HYDRO{"htm","P"}=              3.80;
	$HYDRO{"htm","S"}=              4.12;
	$HYDRO{"htm","T"}=              4.11; 
	$HYDRO{"htm","W"}=              6.10;
	$HYDRO{"htm","Y"}=              5.19;
	$HYDRO{"htm","V"}=              4.18;
				# normalised (0,100)for HYDRO-HTM
	$HYDRO{"htm","A","norm"}=      47.8;
	$HYDRO{"htm","R","norm"}=      43.4;
	$HYDRO{"htm","N","norm"}=      41.3;
	$HYDRO{"htm","D","norm"}=      20.4;
	$HYDRO{"htm","C","norm"}=      58.4;
	$HYDRO{"htm","Q","norm"}=      37.2;
	$HYDRO{"htm","E","norm"}=       0.0;
	$HYDRO{"htm","G","norm"}=      51.9;
	$HYDRO{"htm","H","norm"}=      47.8;
	$HYDRO{"htm","I","norm"}=      59.2;
	$HYDRO{"htm","L","norm"}=      66.7;
	$HYDRO{"htm","K","norm"}=      39.8;
	$HYDRO{"htm","M","norm"}=      58.1;
	$HYDRO{"htm","F","norm"}=      81.4;
	$HYDRO{"htm","P","norm"}=      40.6;
	$HYDRO{"htm","S","norm"}=      48.8;
	$HYDRO{"htm","T","norm"}=      48.6;
	$HYDRO{"htm","W","norm"}=     100.0;
	$HYDRO{"htm","Y","norm"}=      76.5;
	$HYDRO{"htm","V","norm"}=      50.4;
    }
    return(1,"ok $sbrName");
}				# end of hydrophobicity_scales

#==============================================================================
sub isDaf {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isDaf                       checks whether or not file is in DAF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_DAF","$fileLoc");
    while (<FHIN_DAF>){	if ($_=~/^\# DAF/){$Lok=1;}
			else            {$Lok=0;}
			last;}close(FHIN_DAF);
    return($Lok);
}				# end of isDaf

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
sub isGcg {
    local ($fileLoc) = @_ ; $[ =1 ;
#--------------------------------------------------------------------------------
#    isGcg                      checks whether or not file is in Gcg format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
# EXA: paho_chick from:    1 to:   80
# EXA: PANCREATIC HORMONE PRECURSOR (PANCREATIC POLYPEPTIDE) (PP).
# EXA:  paho_chick.gcg          Length:   80   31-May-98  Check: 8929 ..
# EXA:        1  MPPRWASLLL LACSLLLLAV PPGTAGPSQP TYPGDDAPVE DLIRFYNDLQ
# EXA:       51  QYLNVVTRHR YGRRSSSRVL CEEPMGAAGC
#--------------------------------------------------------------------------------
    return(0) if (! defined $fileLoc || ! -e $fileLoc);
    $fhinLoc="FHIN_GCG";
    open($fhinLoc,$fileLoc) || do { warn "-*- isGcg failed opening=$fileLoc\n";
				    return(0); };
    $ctLocFlag=$#tmp=0;
    while(<$fhinLoc>){++$ctLocFlag;
		      push(@tmp,$_);
		      last if ($ctLocFlag==5);}
    close($fhinLoc);
    $ctLocFlag=$already_sequence=0;
    foreach $tmp (@tmp){
	last if ($tmp=~/^\#/); # avoid being too friendly to GCG!
	if   ($tmp=~/from\s*:\s*\d+\s*to:\s*\d+/i)          {
	    ++$ctLocFlag;}
	elsif($tmp=~/^\s*\w+\s+Length\s*:\s+\d+\s+\d\d\-/i) {
	    ++$ctLocFlag;}
	elsif(! $already_sequence && $tmp=~/[\s\t]*\d+\s+[A-Z]+/i) {
	    $already_sequence=1;
	    ++$ctLocFlag;}
	last if ($ctLocFlag==3);}
    return(1) if ($ctLocFlag==3);
    return(0) ;
}				# end of isGcg

#==============================================================================
sub isGcgArray {
    local (@tmp) = @_ ; $[ =1 ;
#--------------------------------------------------------------------------------
#    isGcgArray                 checks whether or not file is in Gcg format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
# EXA: paho_chick from:    1 to:   80
# EXA: PANCREATIC HORMONE PRECURSOR (PANCREATIC POLYPEPTIDE) (PP).
# EXA:  paho_chick.gcg          Length:   80   31-May-98  Check: 8929 ..
# EXA:        1  MPPRWASLLL LACSLLLLAV PPGTAGPSQP TYPGDDAPVE DLIRFYNDLQ
# EXA:       51  QYLNVVTRHR YGRRSSSRVL CEEPMGAAGC
#--------------------------------------------------------------------------------
    return(0)                    if (! defined @tmp || ! $#tmp);
    $ctLocFlag=$already_sequence=0;
    foreach $tmp (@tmp){
	last if ($tmp=~/^\#/); # avoid being too friendly to GCG!
	if   ($tmp=~/from\s*:\s*\d+\s*to:\s*\d+/i)          {
	    ++$ctLocFlag;}
	elsif($tmp=~/^\s*\w+\s+Length\s*:\s+\d+\s+\d\d\-/i) {
	    ++$ctLocFlag;}
	elsif(! $already_sequence && $tmp=~/[\s\t]*\d+\s+[A-Z]+/i) {
	    $already_sequence=1;
	    ++$ctLocFlag;}
	last if ($ctLocFlag==3);}
    return(1)                   if ($ctLocFlag==3);
    return(0) ;
}				# end of isGcgArray

#==============================================================================
sub isMsf {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isMsf                       checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_MSF","$fileLoc");
    while (<FHIN_MSF>){ $Lok=0;
			$Lok=1   if ($_=~/\s*MSF[\s:]+/);
			last;} 
    close(FHIN_MSF);
    return($Lok);
}				# end of isMsf

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

#==============================================================================
sub isPdb { 
    local ($fileLoc) = @_ ; 
    local ($Lok,$fhinLoc);
#--------------------------------------------------------------------------------
#   isPdb                       checks whether or not file is PDB format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_PDB";$Lok=0;
    open($fhinLoc,$fileLoc) || 
	do { warn "*** isPdb failed opening file=$fileLoc!\n";
	     return(0); };
    while(<$fhinLoc>){
	$tmp=$_; $tmp=~s/\n//g;
	last;}
    close($fhinLoc);
#HEADER    PANCREATIC HORMONE                      16-JAN-81   1PPT      1PPT   3
    return(1)
	if ($tmp=~/^HEADER\s+.*\d\w\w\w\s+\d+\s*$/);
    return(0);
}				# end of isPdb

#==============================================================================
sub isPhd2Jct {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhd2Jct                   checks whether or not file is PHD2 junction file
#                               = first line '* NNout_jct'
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_LOC",$fileLoc) || return(0);
    $tmp=<FHIN_LOC>;
    return(0)                   if ($tmp!~/^\* NNout_jct/);
    return(1);
}				# end of isPhd2Jct

#==============================================================================
sub isPhd2Para {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhd2Para                  checks whether or not file is PHD2 parameter file
#                               = first line 'PHD2 PARA'
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_LOC",$fileLoc) || return(0);
    $tmp=<FHIN_LOC>;
    return(0)                   if ($tmp!~/PHD2 PARA/);
    return(1);
}				# end of isPhd2Para

#==============================================================================
sub isPhdAcc {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdAcc                    checks whether or not file is in PHD.rdb_acc format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDACC",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDACC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){
	    $Lok=1;}
	elsif ($ctLoc==1)                  { 
	    close(FHIN_RDB_PHDACC); 
	    return(0);}
	elsif ($_=~/PHDacc/)            { 
	    close(FHIN_RDB_PHDACC); 
	    return(1);}}
    close(FHIN_RDB_PHDACC);
    return(0);
}				# end of isPhdAcc

#==============================================================================
sub isPhdBoth {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdBoth                   checks whether or not file is in PHD.rdb format 
#                               acc + sec
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDBOTH",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDBOTH>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { 
	    $Lok=1;}
	elsif ($ctLoc==1)                       { 
	    close(FHIN_RDB_PHDBOTH); 
	    return(0); }
	elsif ($_=~/PHDsec/ && $_=~/PHDacc/) { 
	    close(FHIN_RDB_PHDBOTH); 
	    return(1);}}
    close(FHIN_RDB_PHDBOTH);
    return(0);
}				# end of isPhdBoth

#==============================================================================
sub isPhdHtm {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdHtm                    checks whether or not file is in PHD.rdb_htm format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDHTM",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDHTM>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){
	    $Lok=1;}
	elsif ($ctLoc==1) { 
	    close(FHIN_RDB_PHDHTM); 
	    return(0);}
	elsif ($_=~/PHDhtm/){
	    close(FHIN_RDB_PHDHTM); 
	    return(1);}}
    close(FHIN_RDB_PHDHTM);
    return(0);
}				# end of isPhdHtm

#==============================================================================
sub isPhdSec {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdSec                    checks whether or not file is in PHD.rdb_sec format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDSEC",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDSEC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { 
	    $Lok=1;}
	elsif ($ctLoc==1)                       { 
	    close(FHIN_RDB_PHDSEC); 
	    return(0); }
	elsif ($_=~/PHDsec/)                 { 
	    close(FHIN_RDB_PHDSEC); 
	    return(1);}}
    close(FHIN_RDB_PHDSEC);
    return(0);
}				# end of isPhdSec

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
sub isPirMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPirMul                    checks whether or not file contains many sequences 
#                               in PIR format 
#                               more than once: first line /^>P1\;/
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_PIR",$fileLoc) || return(0);
    $ctLoc=0;
    while(<FHIN_PIR>){
	++$ctLoc if ($_=~/^>P1\;/i);
	last if ($ctLoc>1);}
    close(FHIN_PIR);
    return(1)                   if ($ctLoc>1);
    return(0);
}				# end of isPirMul

#==============================================================================
sub isProf2Jct {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isProf2Jct                   checks whether or not file is PROF2 junction file
#                               = first line '* NNout_jct'
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_LOC",$fileLoc) || return(0);
    $tmp=<FHIN_LOC>;
    return(0)                   if ($tmp!~/^\* NNout_jct/);
    return(1);
}				# end of isProf2Jct

#==============================================================================
sub isProf2Para {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isProf2Para                  checks whether or not file is PROF2 parameter file
#                               = first line 'PROF2 PARA'
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_LOC",$fileLoc) || return(0);
    $tmp=<FHIN_LOC>;
    return(0)                   if ($tmp!~/PHD2 PARA|PROF PARA/);
    return(1);
}				# end of isProf2Para

#==============================================================================
sub isProfAcc {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isProfAcc                    checks whether or not file is in PROF.rdb_acc format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PROFACC",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PROFACC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){
	    $Lok=1;}
	elsif ($ctLoc==1)                  { 
	    close(FHIN_RDB_PROFACC); 
	    return(0);}
	elsif ($_=~/PROFacc/)            { 
	    close(FHIN_RDB_PROFACC); 
	    return(1);}}
    close(FHIN_RDB_PROFACC);
    return(0);
}				# end of isProfAcc

#==============================================================================
sub isProfBoth {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isProfBoth                   checks whether or not file is in PROF.rdb format 
#                               acc + sec
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PROFBOTH",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PROFBOTH>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { 
	    $Lok=1;}
	elsif ($ctLoc==1)                       { 
	    close(FHIN_RDB_PROFBOTH); 
	    return(0); }
	elsif ($_=~/PROFsec/ && $_=~/PROFacc/) { 
	    close(FHIN_RDB_PROFBOTH); 
	    return(1);}}
    close(FHIN_RDB_PROFBOTH);
    return(0);
}				# end of isProfBoth

#==============================================================================
sub isProfHtm {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isProfHtm                    checks whether or not file is in PROF.rdb_htm format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PROFHTM",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PROFHTM>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){
	    $Lok=1;}
	elsif ($ctLoc==1) { 
	    close(FHIN_RDB_PROFHTM); 
	    return(0);}
	elsif ($_=~/PROFhtm/){
	    close(FHIN_RDB_PROFHTM); 
	    return(1);}}
    close(FHIN_RDB_PROFHTM);
    return(0);
}				# end of isProfHtm

#==============================================================================
sub isProfSec {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isProfSec                    checks whether or not file is in PROF.rdb_sec format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PROFSEC",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PROFSEC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { 
	    $Lok=1;}
	elsif ($ctLoc==1)                       { 
	    close(FHIN_RDB_PROFSEC); 
	    return(0); }
	elsif ($_=~/PROFsec/)                 { 
	    close(FHIN_RDB_PROFSEC); 
	    return(1);}}
    close(FHIN_RDB_PROFSEC);
    return(0);
}				# end of isProfSec

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
sub isSaf {
    local ($fileLoc) = @_ ; 
#--------------------------------------------------------------------------------
#    isSaf                      checks whether or not file is in SAF format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    return(0)            if (! defined $fileLoc || ! -e $fileLoc);
    $fhinLoc="FHIN_SAF";
    open("$fhinLoc",$fileLoc) || return (0);
    $tmp=<$fhinLoc>; 
    close("$fhinLoc");
    return(1)            if (defined $tmp && $tmp =~ /^\#.*SAF/);
    return(0);
}				# end of isSaf

#==============================================================================
sub isSeqArray {
    local (@tmp) = @_ ; $[ =1 ;
#--------------------------------------------------------------------------------
#   isSeqArray                  checks whether or not file is one-letter protein sequence
#                               1 only if ALL input strings ok (spaces and '.-_~' ignored)
#       in:                     @tmp: 
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined @tmp || ! $#tmp);
    foreach $tmp (@tmp){
	return(0)               if ($tmp=~/[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_\s]/i);
    }
    return(1);
}				# end of isSeqArray

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

#===============================================================================
sub is_chain {
    local($tmp) = @_ ;
#-------------------------------------------------------------------------------
#   is_chain                    checks whether or not a PDB chain
#       in:                     character
#       out:                    1,0
#-------------------------------------------------------------------------------
    return(0) if (! defined $tmp);
    return(1) if ($tmp=~/[A-Z0-9]/);
    return(0);
}				# end of is_chain

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
sub is_fssp {
    local ($fileInLoc) = @_ ;
#--------------------------------------------------------------------------------
#   is_fssp                     checks whether or not file is in FSSP format
#       in:                     $file
#       out:                    1 if is fssp; 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP";
    open($fh, $fileInLoc) || return(0);
    $tmp=<$fh> ;
    close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^FSSP/);
    return(0);
}				# end of is_fssp

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#==============================================================================
sub is_ppcol {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_ppcol                    checks whether or not file is in RDB format
#       in:                     $file
#       out:                    1 if is ppcol, 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc);
    $Lis=0;
    while ( <$fh> ) {
	$_=~tr/[A-Z]/[a-z]/;
	$Lis=1 if ($_=~/^\# pp.*col/);
	last; }
    close($fh);
    return $Lis;
}				# end of is_ppcol

#==============================================================================
sub is_rdb_htmref {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_PHDHTM_REF";$Lisrdb=$Lishtm=0;
    open($fh, $fileInLoc) || return(0); 
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { 
	++$ctLoc;
	$Lisrdb=1       if ($_=~/^\# Perl-RDB/);
	last if (! $Lisrdb);
	$Lishtm=1       if ($_=~/^\#\s*PHD\s*htm.*ref\:/);
	last if ($Lishtm);
	last if ($_ !~/^\#/);
	last if ($ctLoc > 5); }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmref

#==============================================================================
sub is_rdb_htmtop {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
	
    $fh="FHIN_CHECK_RDB_PHDHTM_TOP";$Lisrdb=$Lishtm=0;
    open($fh, $fileInLoc) || return(0); 
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { 
	++$ctLoc;
	$Lisrdb=1       if ($_=~/^\# Perl-RDB/);
	last if (! $Lisrdb);
	$Lishtm=1       if ($_=~/^\#\s*PHD\s*htm.*top\:/);
	last if ($Lishtm);
	last if ($_ !~/^\#/);
	last if ($ctLoc > 5); }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmtop

#==============================================================================
sub is_rdb_nnDb {
    local ($fileInLoc) = @_ ;
    local ($fh);
#--------------------------------------------------------------------------------
#   is_rdb_nnDb                 checks whether or not file is in RDB format for NN.pl
#       in:                     $file
#       out:                    1 if is rdb_nn; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_RDBNN";
    open($fh, $fileInLoc) || return(0);
    $tmp=(<$fh>);
    close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^\# Perl-RDB.*NNdb/i);
    return (0);
}				# end of is_rdb_nnDb

#==============================================================================
sub is_strip {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip                    checks whether or not file is in HSSP-strip format
#       in:                     $file
#       out:                    1 if is strip; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_STRIP";
    open($fh, $fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1 if ($_=~/===  MAXHOM-STRIP  ===/);
	last; }
    close($fh);
    return $Lis;
}				# end of is_strip

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
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

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
	warn "*** ERROR lib-col:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-col:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#===============================================================================
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
    $sbrName="lib-col:pirRdSeq";$fhinLoc="FHIN"."$sbrName";

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

#===============================================================================
sub pirRdMul {
    local($fileInLoc,$extr) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdMul                    reads the sequence from a PIR file
#       in:                     file,$extr with:
#                               $extr = '1,5,6',   i.e. list of numbers to read
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:pirRdMul";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
        return(0,"*** ERROR $sbrName: fileIn=$fileInLoc not opened\n");

    $extr=~s/\s//g  if (defined $extr);
    $extr=0         if (! defined $extr || $extr =~ /[^0-9\,]/);
    if ($extr){@tmp=split(/,/,$extr); undef %tmp;
	       foreach $tmp(@tmp){
		   $tmp{$tmp}=1;}}

    $ct=$ctRd=$ctProt=0;        # ------------------------------
    while (<$fhinLoc>) {        # read the file
	$_=~s/\n//g;
	if ($_ =~ /^\s*>/){	# (1) = id (>P1;)
            $Lread=0;
	    ++$ctProt;
	    $id=$_;$id=~s/^\s*>\s*P1?\s*\;\s*//g;$id=~s/(\S+)[\s\n]*.*$/$1/g;$id=~s/^\s*|\s*$//g;
	    $id.="_";

	    $id.=<$fhinLoc>;	# (2) still id in second line
	    $id=~s/[\s\t]+/ /g;
	    $id=~s/_\s*$/g/;
	    $id=~s/^[\s\t]*|[\s\t]*$//g;
            if (! $extr || ($extr && defined $tmp{$ctProt} && $tmp{$ctProt})){
                ++$ctRd;$Lread=1;
		$tmp{"$ctRd","id"}=$id;
		$tmp{"$ctRd","seq"}="";}}
        elsif($Lread){		# (3+) sequence
            $_=~s/[\s\*]//g;
            $tmp{"$ctRd","seq"}.="$_";}}close($fhinLoc);
                                # ------------------------------
    $seq=$id="";		# join to long strings
    if ($ctRd > 1) {
	foreach $it(1..$ctRd){
	    $id.= $tmp{"$it","id"}."\n";
	    $tmp{"$it","seq"}=~s/\s//g;$tmp{"$it","seq"}=~s/\*$//g;
	    $seq.=$tmp{"$it","seq"}."\n";} }
    else { $it=1;
	   $id= $tmp{"$it","id"};
	   $tmp{"$it","seq"}=~s/\s//g;$tmp{"$it","seq"}=~s/\*$//g;
	   $seq=$tmp{"$it","seq"}; }
	
    $#tmp=0;			# save memory
    undef %tmp;			# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of pirRdMul

#==============================================================================
sub rdRdbAssociative {
    local ($fileInLoc,@des_in) = @_ ;
    local ($sbr_name,$fhinLoc,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative            reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhinLoc="FHIN_RDB";$sbr_name="rdRdbAssociative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in (@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
					      push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhinLoc","$fileInLoc");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &rdRdbAssociativeNum($fhinLoc,0);
    close($fhinLoc);
				# ------------------------------
    $#des_head=0;		# process header
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^(PARA\s*:?\s*)?$des_in\s*[ :,\;=]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/^.*$des_in//g;$tmp=~s/^\s*//g;
		    $tmp=~s/^[\s:\t]*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    print
		"--- $sbr_name: \t expected to find in header key word:\n",
		"---            \t '$des_in', but not in file '$fileInLoc'\n"
		    if (!$Lfound && $Lscreen); }}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1; $it<=$#READNAME; ++$it) {
	    $rd=$READNAME[$it];$rd=~s/\s//g;
	    if ($rd eq $des_in) {
		$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);$Lfound=1;
		last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( defined $it && defined $READFORMAT[$it] ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}
    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if   ($nrow_rd==0)    {$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "***         in RDB file '$fileInLoc' for rows with ".
				   "key=$des_in, column=$itrd, prev=$nrow_rd, now=$#tmp,\n";}
	for ($it=1; $it<=$#tmp; ++$it){
	    $rdrdb{"$des_in",$it}=$tmp[$it];
	    $rdrdb{"$des_in",$it}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
				# ------------------------------
				# safe memory
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    $#des_headin=$#des_body=$#tmp=$#des_head=0;
    undef %ptr_rd2des;
    $#des_in=0;                 # slim_is_in !
    
    return (%rdrdb);
}				# end of rdRdbAssociative

#===============================================================================
sub rdRdbAssociativeNum {
    local ($fhLoc2,@readnum) = @_ ;
    local ($ctLoc, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#       in:                     $fhLoc,@readnum,$readheader,@readcol,@readname,@readformat
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ctLoc= 0;
    $tmpct=0;
    while ( <$fhLoc2> ) {	# ------------------------------
	++$tmpct;		# header  
	if ( /^\#/ ) { 
	    $READHEADER.= "$_";
	    next; }
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){
		    $readnum[$it]=$it;$READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name"; }
	    next; }
				# ------------------------------
				# skip format?
	if ($ctLoc==2 && $rd!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc; }
	if ($ctLoc==2) {	# read format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; }
	    next; }
				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	foreach $it (1..$#readnum){
	    next if (! defined $tmpar[$readnum[$it]]); 
	    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }
    }
				# ------------------------------
				# massage FORMAT/COL/NAME
    foreach $it (1..$#READCOL){
	$READFORMAT[$it]=~ s/^\s+//g   if (defined $READFORMAT[$it]);
	$READFORMAT[$it]=~ s/\t$|\n//g if (defined $READFORMAT[$it]);
	$READNAME[$it]=~ s/^\s+//g     if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g        if ($#READNAME>0); 
	$READCOL[$it] =~ s/\t$|\n//g;  # correction: last not return!
    }
}				# end of rdRdbAssociativeNum

#===============================================================================
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

    open($fhinLoc,$fileInLoc) || do { $msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
				      return(0,$msg,"error");};
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

#==============================================================================
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
    $niceLoc="" if (! defined $niceLoc);
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!") if (! defined $fileToCopyTo);

    if (-d $fileToCopyTo){	# is directory
	if ($fileToCopyTo !~/\/$/){$fileToCopyTo.="/";}}

    $Lok= system("\\cp $fileToCopy $fileToCopyTo");
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
	  "/home/rost/perl/ctime.pl",           # HARD_CODED
	  "/nfs/data5/users/ppuser/server/pub/perl/ctime.pl",       # HARD_CODED
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
    $sbrName="lib-col:sysRunProg";
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
