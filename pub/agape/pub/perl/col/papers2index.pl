#!/usr/bin/perl
##!/usr/sbin/perl -w
##!/bin/env perl
##!/usr/pub/bin/perl -w
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal="converts the RDB with all papers into the index.html page for cubic/pages\n".
    "     \t note: to produce: select EN+ style for that, save as text";
$scrIn=      "RDB_file_with_word_from_EN+_document";
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= " \n";
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
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://cubic.bioc.columbia.edu/ 	       #
#				version 0.1   	Jul,    	1999	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0
$| = 1;				# autoflush output (no buffering)


				# ------------------------------
				# initialise variables
#$ARGV[1]="publications.txt";	# xx
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
undef %res;

				# ------------------------------
				# (1) process input files
				# ------------------------------
foreach $fileIn (@fileIn) {
    &errScrMsg("no input file=$fileIn!"," ",$scrName) if (! -e $fileIn);
    print "--- now working on file $fileIn\n" if ($par{"verbose"});
				# read RDB file
    open($fhin,$fileIn) || die "*** $scrName ERROR opening file $fileIn";

    while (<$fhin>) {
	next if ($_=~/^\#/);	# skip comments
	$_=~s/\n//g; $line=$_;
	@tmp=split(/\t/,$_);
				# skip empty
	next if ($tmp[$trans_field2col{"author"}]=~/^\s*$/);

				# ignore some papers
	next if ($tmp[$trans_field2col{"no"}]=~/^(A 00[158]|O |0 |1 |XW 003|XW 011|P 001)/);
	next if ($tmp[$trans_field2col{"author"}]=~/Rost T/i);
#	next if ($tmp[$trans_field2col{"author"}]=~/^\C*$/);

	++$ct;
	print "--- read $fileIn ok: ct=$ct\n" if ($Ldebug);

				# initialise all fields
	foreach $field (@field){
	    $res{$field,$ct}="";
	}
				# translate
	foreach $field (@field){
	    $pos=$trans_field2col{$field};
	    if (! defined $tmp[$pos] && $Ldebug) {
		print "*** no field $field (pos=$pos) in line=$line!\n";
		next;}
	    $res{$field,$ct}=$tmp[$pos];
				# extract fund info (in subj 'fund=a1,a2')
	    if ($field=~/subj/ && $tmp[$pos]=~/^.*fund=\s*([^\;]+).*$/){
		$res{"fund",$ct}=$1;
		$res{"fund",$ct}=~s/^\s*|\s*$//g;
		$res{$field,$ct}=~s/\;?\s*fund=.*$//g;
	    }
		
	}
				# correct
	$res{"journal",$ct}=~s/(Proteins):.*$/$1/g;
    }
    close($fhin);
};


$res{"NROWS"}=$ct;


if ($Ldebug){
    foreach $it (1..$res{"NROWS"}){
	foreach $field (@field){
				# skip if empty
	    next if (length($res{$field,$it})<1 || $res{$field,$it}=~/^\s*$/);
	    printf "--- yyy field=%-10s val=%-s\n",$field,$res{$field,$it};
	}
#	die if ($res{"title",$it}=~/catalo/i);
    }}

				# ------------------------------
				# (2) read WWW templates
($Lok,$msg)=
    &rdTemplates();
    
				# ------------------------------
				# (3) write ouptput files
				# ------------------------------
				# sorted by year www page
($Lok,$msg)=
    &wrtOutYear();

if ($Ltest){
    print "--- NOTE left because test mode!\n";
    exit;}
				# index
($Lok,$msg)=
    &wrtOutIndex();
				# sorted by subject
($Lok,$msg)=
    &wrtOutSubj();
				# ascii page
($Lok,$msg)=
    &wrtOutAscii();

				# center page
($Lok,$msg)=
    &wrtOutCenter();

print "--- $scrName finished output files:\n";
foreach $kwd (
	      "fileOut_index",
	      "fileOut_subj","fileOut_year","fileOut_ascii"
	      ) {
				# change name
    if ($kwd eq "fileOut_index") { 
	$file=$par{$kwd}; $file=~s/list/index/g;
	@cmd=(
	      "mv ".$par{$kwd}." $file",
#	      "ln -s $file ".$par{$kwd}
	      );
	unlink ($file) if (-e $file);
	foreach $cmd (@cmd) {
	    print "--- system \t $cmd\n";
	    system("$cmd");
	}
    }

    print "--- $kwd=",$par{$kwd},"\n" if (-e $par{$kwd});
}

print "*** missing abstracts:\n";
foreach $tmp (@missing_abstr) {
    print "$tmp\n";
}

print "*** missing WWW:\n";
foreach $tmp (@missing_www) {
    print "$tmp\n";
}

				# statistics
if ($Lverb){
    print "--- statistics: \n";
    foreach $year ("pending",@year_sorted){
	print $occ_year{$year}," ",$year,", ";
    }
    print "\n";
}
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
	    $tmp{$kwd}=1;
	}
	$excltmp=join("|",@excl);
    }
    $msgHere="";
				# ------------------------------
    foreach $kwd (@kwd){	# file existence
	next if ($kwd =~ /^file(Out|Help|Def)/i);
	next if (defined $tmp{$kwd});
	next if ($kwd =~/$excltmp/);
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

    $#fileIn=0;                 # ------------------------------
    foreach $arg (@ARGV){	# (2) key word driven input
	if    ($arg=~/^verb\w*3=(\d)/)           {$par{"verb3"}=$1;}
	elsif ($arg=~/^verb\w*3/)                {$par{"verb3"}=1;}
	elsif ($arg=~/^verb\w*2=(\d)/)           {$par{"verb2"}=$1;}
	elsif ($arg=~/^verb\w*2/)                {$par{"verb2"}=1;}
	elsif ($arg=~/^verbose=(\d)/)            {$par{"verbose"}=$1;}
	elsif ($arg=~/^verbose/)                 {$par{"verbose"}=1;}
	elsif ($arg=~/^not_?([vV]er|[sS]creen)/) {$par{"verbose"}=0; }
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

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

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
    return($Date);
}				# end of sysDate



#==============================================================================
# library collected (end) lll
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
    &iniDef();			# set general parameters

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();
    $date=$Date;  $date=~s/(1999|200\d)\s+.*$/$1/g;


				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,
		       %tmp);   return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 
				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg();

    foreach $arg (@argUnk){     # interpret specific command line arguments
	if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
	elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
						$dirOut.=        "/" if ($dirOut !~/\/$/);}
	elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
						$Lverb=          1;}
	elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
	elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
	elsif ($arg=~/^force$/)               { $Lforce=         1;}
	elsif ($arg=~/^tst|test$/)            { $Ltest=          1;
						$par{"dirOut"}=  "";
						$par{"titleOut"}="test";
						$Lforce=         1;}
#	elsif ($arg=~/^=(.*)$/){ $=$1;}
	elsif (-e $arg)                       { push(@fileIn,$arg); }
	else {
	    $Lok=0; 
	    if (defined %par && $#kwd>0) { 
		foreach $kwd (@kwd){ 
		    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					       last;}}}
	    if (! $Lok){ print "*** wrong command line arg '$arg'\n";
			 exit;}}}
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verbose"}=1           if ($par{"debug"});
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

				# ------------------------------
				# (2) names of output files
				# ------------------------------
    foreach $kwd ("fileOut_index",
		  "fileOut_center",
		  "fileOut_subj","fileOut_year","fileOut_ascii") {
	if    ($kwd =~ /index/) {
#	    $file=$par{"dirOut"}."index.$par{"extOut"};}
	    $file=$par{"dirOut"}.$par{"titleOut"}.$par{"extOut"};}
	elsif ($kwd =~ /ascii/) {
	    $file=$par{"dirOut"}.$par{"titleOut"}."_ascii". $par{"extOut_ascii"};}
	elsif ($kwd =~ /center/) {
	    $file=$par{"dirOut"}.$par{"titleOut"}."_center".$par{"extOut_center"};}
	else {
	    $tmp=$kwd; $tmp=~s/fileOut_//g;
	    $file=$par{"dirOut"}.$par{"titleOut"}."_".$tmp.$par{"extOut"};}
	
	$par{$kwd}=$file if (! defined $par{$kwd} || ! $par{$kwd} ||
			     $par{$kwd} =~/^(title|unk)$/ || length($par{$kwd}) < 2);
    }

    @subject=split(/,/,$par{"subject"});

				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet();            return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);
    $fileOut=$par{"fileOut"};

    $#fileOut=0;                # reset output files
    if (! defined $fileOut || ! $fileOut || length($fileOut)<1){
        foreach $it (1..$#fileIn){
            $tmp=$fileIn[$it]; $tmp=~s/^.*\///g;$tmp=~s/$par{"extHssp"}//g;
            $fileOut=$par{"dirOut"}.$tmp.$par{"extOut"};
            push(@fileOut,$fileOut);}}
    else{
	push(@fileOut,$fileOut);}

				# correct settings for executables: add directories
    if (0){
	foreach $kwd (keys %par){
	    next if ($kwd !~/^exe/);
	    next if (-e $par{"$kwd"} || -l $par{"$kwd"});
	}
    }


				# ------------------------------
				# check errors
    $exclude="exe,fileDefaults"; # to exclude from error check
    $exclude.=",fileWeb"        if ($Lforce);
	
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n",$msg)) if (! $Lok);  


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
				# central cubic web pages
    $par{"dirWeb_cubic"}=       "/home/cubic/public_html/";
#    $par{"dirWeb_cubic"}=       "/home/rost/public_html/";

    $par{"dirWeb_papers"}=      $par{"dirWeb_cubic"}."papers/";
    $par{"reldirWeb_papers"}=   "w/new/"; # xx
    $par{"reldirWeb_papers"}=   ""; # xx
				# material used (templates of WWW pages)
    $par{"dirWeb_MAT"}=         $par{"dirWeb_cubic"}."MAT/";
				# HTML pages with results
    $par{"dirWeb_genomes"}=     $par{"dirWeb_cubic"}."genomes/";
    $par{"dirWeb_genomesOrg"}=  $par{"dirWeb_cubic"}."genomes/org/";

    $par{"dirFtp_genomes"}=     "/home/ftp/pub/cubic/data/genomes/";
    $par{"dirFtp_genomesSeq"}=  "/home/ftp/pub/cubic/data/genomes/seq/";
    $par{"dirFtp_genomesOrg"}=  "/home/ftp/pub/cubic/data/genomes/org/";
    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
#    $par{""}=         "";
                                # further on work
				# --------------------
				# files

    $par{"fileTemplate_"."head"}=    $par{"dirWeb_MAT"}."template_head.html";
    $par{"fileTemplate_"."links"}=   $par{"dirWeb_MAT"}."template_links.html";
    $par{"fileTemplate_"."section"}= $par{"dirWeb_MAT"}."template_section.html";
    $par{"fileTemplate_"."contact"}= $par{"dirWeb_MAT"}."template_contact.html";
    $par{"fileTemplate_"."navi_top"}=$par{"dirWeb_MAT"}."template_navigate_top.html";
    $par{"fileTemplate_"."navi_bot"}=$par{"dirWeb_MAT"}."template_navigate_bottom.html";

    $par{"fileMat_address"}=         $par{"dirWeb_MAT"}."cubic_address.rdb";

    $par{"fileWeb_"."cubic"}=        $par{"dirWeb_cubic"}."index.html";
    $par{"fileWeb_"."genomes"}=      $par{"dirWeb_cubic"}."genomes/";

    $par{"fileWeb_"."papers"}=       "index.html";

    $par{"fileWeb_"."abstr_rost"}=      "abstrRost.html";
    $par{"fileWeb_"."abstr_rost_pdf"}=  "abstrRost.pdf";
    $par{"fileWeb_"."abstr_cubic"}=     "abstrCUBIC.html";
    $par{"fileWeb_"."abstr_cubic_pdf"}= "abstrCUBIC.pdf";
#    $par{"fileWeb_"."abstr_cubicx"}=    "abstrColla.html";
#    $par{"fileWeb_"."abstr_cubicx_pdf"}="abstrColla.pdf";
    

				# file extensions
#    $par{"preOut"}=             "summary";
#    $par{"extOut"}=             ".html";
    $par{"titleOut"}=           "list";
    $par{"extOut"}=             ".html";
    $par{"extOut_ascii"}=       ".txt";
    $par{"extOut_center"}=      ".rdb";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";
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
    $par{"cubicAdminEmail"}=    "cubic\@cubic.bioc.columbia.edu";
    $par{"cubicFtpServer"}=     "cubic.bioc.columbia.edu";

    $par{"formatWidthLink"}=    20;
    $par{"formatWidthTitle"}=   50;
    $par{"formatWidthQuote"}=   90;
    $par{"formatWidthSubj"}=    40;
    $par{"formatWidthFund"}=    20;


    $par{"formatWidthLinkPerc"}= "\"10\%\"";
    $par{"formatWidthTitlePerc"}="\"30\%\"";
    $par{"formatWidthQuotePerc"}="\"40\%\"";
    $par{"formatWidthSubjPerc"}= "\"20\%\"";
    $par{"formatWidthSubjFund"}= "\"5\%\"";

				# --------------------
				# executables
#    $par{"exe"}=                "";
#    $par{""}=                   "";
				# ------------------------------
				# parameters

				# subjects to use for separated display of papers
    $par{"subject"}=            "";
    $par{"subject"}.=           "structure,function,localization,interaction";
    $par{"subject"}.=           "";
    $par{"subject"}.=           ",secondary,accessibility,transmembrane,threading,evolution";
    $par{"subject"}.=           ",evaluation,cluster,alignment,structural gen,proteomics";
    $par{"subject"}.=           ",service,sequence ana,review,database,method,algorithm";
				

#    $par{"present_subj"}=       "title:author,year,journal,vol,page";
#    $par{"present_year"}=       "author,year,journal,vol,page:title:subj";
#    $par{"present_ascii"}=      "";
#    $par{""}=			"";

    $par{"groupCUBIC"}=         "b rost,d przybylski,r nair,j liu,caf andersen";
    $par{"groupCUBIC"}.=        ",m cokol,v eyrich,h bigelow,cf chen,a kernytsky";


    $Lforce=                    0; # if 1: do not check existence of files
    $Ltest=                     0; # if 1: only in test mode, will only write index for years 'test.html'

				# ------------------------------
				# a.a arrays


    %trans_field2col=			# which column has which keyword?
	('no',      1,
	 'author',  2,
	 'year',    3,
	 'title',   4,
	 'journal', 5,
	 'vol',     6,
	 'page',    7,
	 'short',   8,
	 'www',     9,
	 'subj',   10,
	 );

    %trans_subj2full=
	('secondary',            "Secondary structure",
	 'accessibility',        "Solvent accessibility",
	 'transmembrane',        "Transmembrane segments",
	 'threading',            "Threading (remote homology)",
	 'comparative model',    "Comparative modelling",

	 'evolution',            "Evolution",
	 'function',             "Protein function",
	 'structure',            "Protein structure",
	 'localization',         "Sub-cellular localization",
	 'interaction',          "Protein-protein interaction",

	 'sequence ana',         "Sequence analysis",
	 'service',              "Prediction services",
	 'evaluation',           "Evaluation of prediction methods",
	 'cluster',              "Clustering proteins",
	 'alignment',            "Alignment methods",

	 'structural gen',       "Structural genomics",
	 'proteomics',           "Protemics predictions",

	 'database',             "Databases",
	 'algorithm',            "Algorithms",
	 'method',               "Methods",

	 'review',               "Reviews",
	 );
	 

				# fields in table
    @field=  ('no','author','year','title','journal','vol','page','short','subj','www');
				# different presentations
    @present=('year','subj','ascii');

    
				# subjects
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
    $tmp{"special"}.=        "list,verb,verb2,verbDbg,force,";
    $tmp{"special"}.=        ",";
        
#    $tmp{""}=         "<*|=1> ->    ";
    $tmp{"list"}=            "<*|isList=1>     -> input file is list of files";

    $tmp{"verb"}=            "<*|verbose=1>    -> verbose output";
    $tmp{"verb2"}=           "<*|verb2=1>      -> very verbose output";
    $tmp{"verbDbg"}=         "<*|verbDbg=1>    -> detailed debug info (not automatic)";
    $tmp{"force"}=           "<*>              -> do not check existence of files";

    $tmp="---                      ";
#    $tmp{"zz"}=              "expl             -> action\n";
#    $tmp{"zz"}.=        $tmp."    expl continue\n";
    $tmp{"special"}=~s/,*$//g;
#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelp

#===============================================================================
sub rdTemplates {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
    $| = 1;				# autoflush output (no buffering)
#-------------------------------------------------------------------------------
#   rdTemplates                 reads the CUBIC www templates
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="rdTemplates";
    $fhinLoc="FHIN_"."rdTemplates";
				# ------------------------------
				# read template files
				# ------------------------------
#    $prev="../cubic.html";
#    $next="index.html";
    undef %template;
    foreach $kwd ("head","contact","section","links","navi_top","navi_bot"){
	$file=$par{"fileTemplate_".$kwd};
	return(&errMsgSbr("missing template for kwd=$kwd, file=$file",$SBR))
	    if (! -e $file);
#	print "xyx- kwd=$kwd, temp=$file\n";
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
#	    $template{$kwd}=~s/title(_x+)?/$info{"title"}/g; 
	    $template{$kwd}=~s/(\")style/$1\.\.\/style/g;
#	    $template{$kwd}=~s/prev_x+/$prev/;
#	    $template{$kwd}=~s/next_x+/$next/; 
	}
				# navigate: next and previous
	elsif ($kwd=~/navi/) {
#	    $template{$kwd}=~s/prev_x+/$prev/;
#	    $template{$kwd}=~s/next_x+/$next/;
	}
    }

				# ------------------------------
				# author addresses

    $file=$par{"fileMat_address"};
    return(&errMsgSbr("missing template for kwd=fileMat_address, file=$file",$SBR))
	if (! -e $file);
#    print "xyx- kwd=$kwd, temp=$file\n";
    open($fhinLoc,$file) || return(&errSbr("file(fileMat_address)=$file, not opened",$SBR));
    $template{"address"}="";
    $cttmp=0;
    while (<$fhinLoc>) {
	++$cttmp;
	next if ($_=~/^\#/);
	next if ($_=~/^Name/i);
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);
	if ($#tmp<2){
	    print "-*- WARN problem with addresses ($file): line=$cttmp, $_ no tab?\n";
	    next;
	}
	$name=$tmp[1];
	$name=~s/^\s*|\s*$//g;	# leading blanks
	$name=~tr/[A-Z]/[a-z]/;	# all small caps
	$name=~s/[^a-z\s]//g;	# non blank/character
	$template{"address"}.=$name."\t";
	$template{"address",$name}=$#tmp-1;
	foreach $it (2..$#tmp){
	    $template{"address",$name,($it-1)}=$tmp[$it];
	}
    }
    close($fhinLoc);

    return(1,"ok $SBR");
}				# end of rdTemplates

#===============================================================================
sub wrtOut_assist {
    local($itLoc,$mode) = @_ ;
    $[ =1 ;
    $| = 1;				# autoflush output (no buffering)
#-------------------------------------------------------------------------------
#   wrtOut_assist                       
#       in:                     $number_referring_to_%res,$mode=<year|subj|ascii>
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2="wrtOut_assist";

    $fileAbstr= 0;
    $fileWeb=   0;
    $filePdf=   0;
    $titlePaper=0;

    $fileAbstr=$res{"short",$itLoc} if (defined $res{"short",$itLoc} && $res{"short",$itLoc}  && 
					length($res{"short",$itLoc}) > 1 && $res{"short",$itLoc} !~/^\s*$/);
    $titlePaper=$fileAbstr
	if ($fileAbstr);
    $fileAbstr=$par{"reldirWeb_papers"}.$fileAbstr."/"."abstract.html"
	if ($fileAbstr);
				# normal WWW page
    $fileWebOld=0;

    $fileWeb=      $par{"reldirWeb_papers"}.$titlePaper."/"."paper".".html";
    $fileWebIndex= $par{"reldirWeb_papers"}.$titlePaper."/"."index".".html";
    $filePdf=      $par{"reldirWeb_papers"}.$titlePaper."/"."paper".".pdf";

				# ------------------------------
				# there is a WWW site
    if (defined $res{"www",$itLoc} && $res{"www",$itLoc} &&
	$res{"www",$itLoc} !~ /none/ && $res{"www",$itLoc} !~ /^\s*$/) {
	$fileWebOld=$res{"www",$itLoc} if ($res{"www",$itLoc} =~ /rost\//);
	if ($fileAbstr) {
	    $fileWeb=  $par{"reldirWeb_papers"}.$titlePaper."/"."paper".".html";
	    $filePdf=  $par{"reldirWeb_papers"}.$titlePaper."/"."paper".".pdf";
	}
	else {
#	    print "xx missing abstract for itloc=$itLoc, file=$fileWeb,\n";
	}
    }
				# ------------------------------
				# no WWW but PDF or something
    else {
	if ($fileWeb=~/20\d\d_/){
	    print "xx missing WWW1=",$res{"www",$itLoc},", for itloc=$itLoc, file=$fileWeb,\n";
	}
    }

    $fileWeb=0                  if (! defined $fileWeb || ! $fileWeb || ! -e $fileWeb);
    $fileWeb=$res{"www",$itLoc} if (! $fileWeb && $res{"www",$itLoc}=~/http/);

    $fileWebIndex=0             if (! defined $fileWebIndex || ! $fileWebIndex || ! -e $fileWebIndex);
    $fileAbstr=0                if (! defined $fileAbstr || ! $fileAbstr || ! -e $fileAbstr);
    $filePdf=0                  if (! defined $filePdf || ! $filePdf || ! -e $filePdf);
#    $fileWeb=0                  if (! defined $fileWeb || ! $fileWeb || ! -e $fileWeb);


    				# appendices
    if (! $fileWeb && $res{"short",$itLoc} =~/^(.+)_appendix/) {
	if ($fileAbstr) {
	    $fileWeb=  $par{"reldirWeb_papers"}.$1."/"."appendix.html"; }}
    				# www docs
    if ($res{"www",$itLoc} =~/http/ &&
	$res{"author",$itLoc} =~/ WWW/) {

	if ($fileAbstr && $Ldebug) {
	    print "xyx- res=",$res{"www",$itLoc},"\n";
	    $fileWeb=  $res{"www",$itLoc}; 
	}
    }
    elsif ($fileWeb !~ /http/ && ! -e $fileWeb) {
	$fileWeb=$res{"www",$itLoc};
#	print "xyx- missing WWW2=",$res{"www",$itLoc},", for itloc=$itLoc, file=$fileWeb, short=",$res{"short",$itLoc},", no=",$res{"no",$itLoc},"\n";
    }


    $fileAbstr= 0        if (! -e $fileAbstr);
    $fileWeb=   0        if (! -e $fileWeb && $fileWeb !~ /http/);
    $fileWebOld=0        if (! $fileWebOld || ! -e $fileWebOld);
    $filePdf=   0        if (! $filePdf || ! -e $filePdf);
    $fileWebIndex=0      if (! defined $fileWebIndex || ! $fileWebIndex || ! -e $fileWebIndex);
	    
    				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    				# 
    				#       CHANGE values for submitted 
    				# 
				# hack: delete web pages for submitted papers
    				# 
    				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    $fileWeb=$fileWebIndex=$fileWebOld=
	0                       if ($res{"page",$itLoc}=~/submit/ ||
				    $res{"vol",$itLoc}=~/submit/);

    $author=$res{"author",$itLoc};
    $author=~s/ WWW\s*$//g
	    if ($res{"author",$itLoc}=~/ WWW/);
    $quote =$author." (".$res{"year",$itLoc}.") ".$res{"journal",$itLoc};
    $quote.=", ".$res{"vol",$itLoc}.", ".$res{"page",$itLoc};
    $quote=~s/(,\s*),/$1/g;
    $quote=~s/[,\.][\s\t]*$//g;
    $quote=~s/_?pages_xxx?//g;

    $title= $res{"title",$itLoc};

    $link="";
    $LonlyIndex=0;

    if    ($fileWeb && $fileWebOld){
	$web=   "<A HREF=\"". $fileWeb.   "\">"."www"."</A>";
	$web.=  " <A HREF=\"".$fileWebOld."\">(old)</A> ";}
    elsif ($fileWeb && $fileWebIndex)  {
	$web=   "<A HREF=\"". $fileWebIndex.   "\">"."index"."</A> - ";
	$web.=  "<A HREF=\"". $fileWeb.   "\">"."www"."</A>";}
    elsif ($fileWebOld && $fileWebIndex)  {
	$web=   "<A HREF=\"". $fileWebIndex.   "\">"."index"."</A> - ";
	$web.=  "<A HREF=\"". $fileWebOld.    "\">"."www"."</A>";}
    elsif ($fileWeb) {
	$web=   "<A HREF=\"". $fileWeb.   "\">"."www"."</A>";}
    elsif ($fileWebOld) {
	$web=   "<A HREF=\"". $fileWebOld."\">"."www"."</A>";}
    elsif ($fileWebIndex) {
	$LonlyIndex=1;
	$web=   "<A HREF=\"". $fileWebIndex."\">"."index"."</A>";}
    else {
	$LonlyIndex=1;
	$web=   0;}


#    print "xyx- title=".$title." web=$web, fileWeb=$fileWeb, old=$fileWebOld,\n" if ($res{"year",$itLoc} eq "2004");
       
    
    if    ($fileAbstr) {
	$abstr= "<A HREF=\"". $fileAbstr. "\">abstr</A>";}
    else {
	$abstr= 0;}
    if    ($filePdf) {
	$pdf= "<A HREF=\"". $filePdf. "\">pdf</A>";}
    else {
	$pdf=   0;}

				# build up link: (1) lots of stuff in www dir -> link to index
    if (! $LonlyIndex){
	$link.="$web-"              if ($web);
	$link.="$abstr-"            if ($abstr);
	$link.="$pdf-"              if ($pdf);
    }
				# build up link: (2) only one (either abstr or pdf) -> no index
    else {
	$link.="$web-"              if ($web && ($abstr || $pdf));
	$link.="$abstr-"            if ($abstr && $web);
	$link.="$pdf-"              if ($pdf && $web);
    }

				# correct for results and index:
    if ($res{"no",$itLoc}=~/^X/ && -e $fileWebIndex){
	$web=   "<A HREF=\"". $fileWebIndex."\">"."index"."</A>";
	$link=  "$web-"; }
	
    $link=~s/\-\s*$//g;
    $link="-"                   if (length($link)<1);

				# --------------------
				# find matching subjects
    if    ($mode=~/year/){
	$subj="";
	foreach $tmp (@subject) {
	    next if ($res{"subj",$itLoc} !~ /$tmp/i);
	    if (defined $trans_subj2full{$tmp}) {
		$subj.=" ".$trans_subj2full{$tmp};}
	    else {
		$subj.=" $tmp";}
	}
	$subj="-"               if (length($subj)<2);
	$fund=" ";
	$fund=$res{"fund",$itLoc} if (defined $res{"fund",$itLoc} && 
				      length($res{"fund",$itLoc})>2);
	return(1,"ok $SBR2",$title,$quote,$link,$subj,$fund);}
    elsif ($mode=~/subj/){
	 return(1,"ok $SBR2",$title,$quote,$link);}
    elsif ($mode=~/ascii/) {
	return(1,"ok $SBR2",$title,$quote,$link);}
    else {
	return(0,"*** ERROR $SBR2: mode=$mode, not understood (<year|subj|ascii>)");}
}				# end of wrtOut_assist

#===============================================================================
sub wrtOutIndex {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
    $| = 1;				# autoflush output (no buffering)
#-------------------------------------------------------------------------------
#   wrtOutIndex                 writes the index page
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtOutIndex";
    $fhoutLoc="FHOUT_"."wrtOutIndex";
				# open file
#    $fileOutTmp=$par{"fileOut_index"};
#    $new="index.html";
#    $fileOutTmp=~s/^(.*\/).*$/$1$new/;

    open($fhoutLoc,">".$par{"fileOut_index"}) || 
	return(&errSbr("fileOutLoc=".$par{"fileOut_index"}.", not created",$SBR));
#    open($fhoutLoc,">".$fileOutTmp) || 
#	return(&errSbr("fileOutLoc=".$fileOutTmp.", not created",$SBR));
				# ------------------------------
				# adjust title and navigation
    $title="CUBIC publications (index)";
    $prev= "../index.html";
    $next= $par{"fileOut_year"}; 
    $navi_add= " ";
    $navi_add.=" <A HREF=\"".$par{"fileOut_year"}. "\">Papers by year</A> - ";
    $navi_add.=" <A HREF=\"".$par{"fileOut_subj"}. "\">Papers by subject</A> - ";
    $navi_add.=" <A HREF=\"".$par{"fileOut_ascii"}."\">Papers as flat file</A>\n";
    $kwd_navi_add="<!-- navi_add_x -->";

    $template_head=$template{"head"};
    $template_head=~s/title_x+/$title/g;
    $template_head=~s/prev_x+/$prev/g;
    $template_head=~s/next_x+/$next/g;

    $template_navi_top=$template{"navi_top"};
    $template_navi_top=~s/prev_x+/$prev/g;
    $template_navi_top=~s/next_x+/$next/g;
    $template_navi_top=~s/$kwd_navi_add/$navi_add/g;
    $template_navi_top=~s/<P ALIGN=CENTER>//g;

    $template_navi_bot=$template{"navi_bot"};
    $template_navi_bot=~s/prev_x+/$prev/g;
    $template_navi_bot=~s/next_x+/$next/g;
    $template_navi_bot=~s/$kwd_navi_add/$navi_add/g;
    $template_navi_bot=~s/<P ALIGN=CENTER>//g;

#    $template_links=   $template{"links"};
#    $template_links=~s/(SRC=\")(Dicon)/$1\.\.\/$2/g;

    $template_contact= $template{"contact"};
    $template_contact=~s/date_x+/$date/g;

				# ------------------------------
				# build up header of page
				# ------------------------------
    print $fhoutLoc
	$template_head,"\n",
	"\n",
	"<BODY>\n",
	"\n",
	$template_navi_top,"\n",
	"<H1>".$title."<\/H1>\n",
	"<P>\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<!-- ", "beg: intro ", " -->\n",
	"<H2>To go from here:</H2>\n",
	"<UL>\n",
	"<LI>publications sorted by <A HREF=\"".   $par{"fileOut_year"}. "\">year</A>\n",
	"<LI>publications sorted by <A HREF=\"".   $par{"fileOut_subj"}. "\">subject</A>\n",
	"<LI>publications by year as a <A HREF=\"".$par{"fileOut_ascii"}."\">flat file</A> (no links)<BR>\n",

	"<LI>collected abstracts (CUBIC) :<BR>",
	"<A HREF=\"".$par{"fileWeb_"."abstr_cubic"}."\">"."html"."</A> - ",
	"<A HREF=\"".$par{"fileWeb_"."abstr_cubic_pdf"}."\">"."pdf"."</A>\n",

#	"<LI>collected abstracts (CUBIC collaborations) :<BR>",
#	"<A HREF=\"".$par{"fileWeb_"."abstr_cubicx"}."\">"."html"."</A> - ",
#	"<A HREF=\"".$par{"fileWeb_"."abstr_cubicx_pdf"}."\">"."pdf"."</A>\n",

	"<LI>collected abstracts (Rost 1992-1998) :<BR>",
	"<A HREF=\"".$par{"fileWeb_"."abstr_rost"}."\">"."html"."</A> - ",
	"<A HREF=\"".$par{"fileWeb_"."abstr_rost_pdf"}."\">"."pdf"."</A>\n",
#	"<LI><A HREF=\"".."\">".."</A>\n",
	"</UL>\n",
	"<!-- ", "end: intro ", " -->\n",
	"<!-- ", "=" x 80 , " -->\n",
	"\n";

				# ------------------------------
				# build up statistics
				# ------------------------------


    print $fhoutLoc
        "<HR>\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<!-- ", "beg: stat ", " -->\n",
	"<H2>Annual statistics:</H2>\n",
        "<TABLE>\n",
        "<FONT SIZE=\"-1\">\n";

    $tmp="<IMG WIDTH=12 HEIGHT=12 SRC=\"../Dicon/line-blue.gif\">";

    foreach $year ("pending","submitted",@year_sorted){
	$txt_year=$year;
	$txt_year="in press"  if ($txt_year=~/pending/);
	$txt_year="submitted" if ($txt_year=~/submitted/);
	print $fhoutLoc
	    "<TR>",
	    "<TD>",
	    "<A HREF=\"list_year.html\#".$year."\">",
	    $txt_year,
	    "</A>",
	    "</TD>",
	    "<TD ALIGN=RIGHT>",$occ_year{$year},"</TD>",
	    "<TD>",
	    $tmp x $occ_year{$year},
	    "</TD>",
	    "</TR>\n";
    }

    print $fhoutLoc
        "</FONT>\n",
        "</TABLE>\n",
	"<!-- ", "end: stat ", " -->\n",
	"<!-- ", "=" x 80 , " -->\n",
        "<HR>\n",
	"\n";
       
				# ------------------------------
				# build up bottom of page
				# ------------------------------
    print $fhoutLoc
#	$template_links,"\n",
	$template_contact,"\n",
	$template_navi_bot,"\n",
	"\n",
	"</BODY>\n",
	"</HTML>\n";

    close($fhoutLoc);

    return(1,"ok $sbrName");
}				# end of wrtOutIndex

#===============================================================================
sub wrtOutYear {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
    $| = 1;				# autoflush output (no buffering)
#-------------------------------------------------------------------------------
#   wrtOutYear                  writes the publication table sorted by year
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtOutYear";
    $fhoutLoc="FHOUT_"."wrtOutYear";
				# open file
    open($fhoutLoc,">".$par{"fileOut_year"}) || 
	return(&errSbr("fileOutLoc=".$par{"fileOut_year"}.", not created",$SBR));
				# ------------------------------
				# adjust title and navigation
    $title="CUBIC publication list sorted by year";
    $prev= $par{"fileOut_index"};
    $next= $par{"fileOut_subj"};

    $navi_add= " ";
    $navi_add.=" <A HREF=\"".$par{"fileWeb_papers"}. "\">CUBIC papers</A> - ";
#    $navi_add.=" <A HREF=\"".$par{"fileOut_year"}.   "\">Papers by year</A> - ";
    $navi_add.=" <A HREF=\"".$par{"fileOut_subj"}.   "\">Papers by subject</A> - ";
    $navi_add.=" <A HREF=\"".$par{"fileOut_ascii"}.  "\">Papers as flat file</A>\n";
    $kwd_navi_add="<!-- navi_add_x -->";

    $template_head=$template{"head"};
    $template_head=~s/title_x+/$title/g;
    $template_head=~s/prev_x+/$prev/g;
    $template_head=~s/next_x+/$next/g;

    $template_navi_top=$template{"navi_top"};
    $template_navi_top=~s/prev_x+/$prev/g;
    $template_navi_top=~s/next_x+/$next/g;
    $template_navi_top=~s/$kwd_navi_add/$navi_add/g;
    $template_navi_top=~s/<P ALIGN=CENTER>//g;

    $template_navi_bot=$template{"navi_bot"};
    $template_navi_bot=~s/prev_x+/$prev/g;
    $template_navi_bot=~s/next_x+/$next/g;
    $template_navi_bot=~s/$kwd_navi_add/$navi_add/g;
    $template_navi_bot=~s/<P ALIGN=CENTER>//g;

#    $template_links=   $template{"links"};
#    $template_links=~s/(SRC=\")(Dicon)/$1\.\.\/$2/g;

    $template_contact= $template{"contact"};
    $template_contact=~s/date_x+/$date/g;

				# ------------------------------
				# build up header of page
				# ------------------------------
    print $fhoutLoc
	$template_head,"\n",
	"\n",
	"<BODY>\n",
	"\n",
	$template_navi_top,"\n",
	"\n",
	"<H1>".$title."<\/H1>\n",
	"<P></P>\n";

				# ------------------------------
				# sort list
				# ------------------------------
    undef %tmp; $#tmp=0;
    undef %fin;

    foreach $it (1..$res{"NROWS"}){
	$year=$res{"year",$it};
	next if ($year=~/\D/);
	if (! defined $tmp{$year}) {
	    $tmp{$year}="";
	    push(@tmp,$year);}
	$tmp{$year}.="$it,";
    }

    @sort=sort bynumber_high2low @tmp;

				# ------------------------------
				# links to years
				# ------------------------------
    print $fhoutLoc
	"<P> </P>\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<!-- ", "beg: summary ", " -->\n",
	"<UL>\n",
	"<LI><A HREF=\"#pending-press\">   Pending (in press)</A></LI>\n",
	"<LI>years:<BR>";

    foreach $year (@sort) {
	print $fhoutLoc " <A HREF=\"#$year\">$year</A> - ";
    }
    @year_sorted=@sort;

    print $fhoutLoc
	"</LI>\n",
	"<LI><A HREF=\"#pending-submitted\"> Pending (submitted)</A></LI>\n",
	"<LI><A HREF=\"#preprint\">  Preprints</A></LI>\n",
	"<LI><A HREF=\"#appendix\">  Appendices to papers</A></LI>\n",
	"<LI><A HREF=\"#wwwdoc\">    WWW documents</A></LI>\n",
	"</UL>\n",
	"<!-- ", "end: summary", " -->\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<P></P>\n";

				# ------------------------------
				# table begin
    print $fhoutLoc
	"<P> </P>\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<!-- ", "beg: table ", " -->\n",
	"<TABLE BORDER=1 COLS=4 CELLPADDING=3 CELLSPACING=2 WIDTH=\"100%\">\n";

				# column names
    $spacer="&nbsp;";
    $spacer="";
    print $fhoutLoc 
	"",
	"<TR>";
    foreach $kwd (
		  "Link",
		  "Title",
		  "Quote",
		  "Subj",
		  "Fund"
		  ){
	$tmp=$kwd;
	$tmp="Subject"          if ($kwd =~/Subj/);
	$tmp="\$\$"             if ($kwd =~/Fund/);
	$kwdPerc="formatWidth".$kwd."Perc";
	$kwdLen= "formatWidth".$kwd;

#	print $fhoutLoc
#	    "<TH WIDTH=".$par{$kwdPerc}."><STRONG>".$tmp,$spacer x $par{$kwdLen},"</STRONG></TH>\t";
	print $fhoutLoc
	    "<TH WIDTH=".$par{$kwdLen}."><STRONG>".$tmp,$spacer x $par{$kwdLen},"</STRONG></TH>\t";
    }

    print $fhoutLoc
	"</TR>\n"; 
				# ------------------------------
				# loop over years
				# ------------------------------
    foreach $year (@sort) {
	next if (! defined $tmp{$year});
	$tmp{$year}=~s/,$//g;
	@tmp=split(/,/,$tmp{$year});
	$occ_year[$year]=0;
	$occ_year{$year}=0;
#	print "xyx1- year=$year, tmp=",join(',',@tmp,"\n");
				# ------------------------------
				# different treat: 
				#    pending, preprint, wwwdoc
	foreach $it (@tmp) {
#	    print " it=$it, title=",$res{"title",$it},", author:",$res{"author",$it},"\n";
	    if ($res{"title",$it}=~/Appendix/i) {
		$fin{"appendix"}="" if (! defined $fin{"appendix"});
		$fin{"appendix"}.="$it,";
#		print "xyx- it=$it, skip 1\n";
		next; }
	    if ($res{"author",$it}=~/www/i) {
		$fin{"wwwdoc"}=""   if (! defined $fin{"wwwdoc"});
		$fin{"wwwdoc"}.="$it,";
#		print "-xyx- it=$it, skip 2\n";
		next; }
	    if ($res{"no",$it}=~/^P /i ||
		$res{"no",$it}=~/^A 005/ || # ismb 95
		$res{"no",$it}=~/^A 008/ # paper J Mol Evol
		) {
		$fin{"preprint"}="" if (! defined $fin{"preprint"});
		$fin{"preprint"}.="$it,";
#		print "xyx- PREPRINT (P) $it ",$res{"page",$it},", title=",$res{"title",$it},"\n";
#		print "xyx- it=$it, skip 3\n";
		next; }
	    if (($res{"page",$it} !~/\d+\-\d/i &&
		 $res{"page",$it} !~/\d+/ &&     # nature
		 $res{"page",$it} !~/R\d+\-R\d/  # folding and design 
		) ||
		(
		 $res{"page",$it}=~/submitted|xx/
		 )
		) {
		$fin{"pending"}=""    if (! defined $fin{"pending"});
		$fin{"submitted"}=""  if (! defined $fin{"submitted"});
		if ($res{"page",$it} =~ /submitted/){
		    $fin{"submitted"}.="$it,";}
		else {
		    $fin{"pending"}.="$it,";
		}
#		print "xyx- it=$it, skip 4\n";
		print "xyx- PENDING $it ",$res{"page",$it},", title=",$res{"title",$it},"\n";
		next;
	    }
	    elsif ($res{"page",$it}=~/xx/){
		print "xx else for $it\n";
	    }

#	    print "xyx- it=$it, skip   no\n";
				# normal sort: per year
	    $fin{$year}=""          if (! defined $fin{$year});
	    $fin{$year}.="$it,";
	    ++$occ_year[$year];
	    ++$occ_year{$year};
	}
    }


    $#tmp_num_pending=$#tmp_num_submitted=0;

    if (defined $fin{"pending"} && length($fin{"pending"})>0){
	$tmpx_pending=$fin{"pending"};
	$tmpx_pending=~s/^,*|,*$//g;   
	@tmp_num_pending=split(/,/,$fin{"pending"});
	$occ_year{"pending"}=$#tmp_num_pending;
    }

    if (defined $fin{"submitted"} && length($fin{"submitted"})>0){
	$tmpx_submitted=$fin{"submitted"};
	$tmpx_submitted=~s/^,*|,*$//g;   
	@tmp_num_submitted=split(/,/,$fin{"submitted"});
	$occ_year{"submitted"}=$#tmp_num_submitted;
    }
    
    if (0){			# skipped
	if ($#tmp_num_submitted){
	    $fin{"pending"}.=",".$fin{"submitted"};
	}
    }

				# ------------------------------
				# pending, preprint, wwwdoc,
    foreach $kwd ("pending",@sort,"submitted","preprint","appendix","wwwdoc") {
	next if (! defined $fin{$kwd});
	$fin{$kwd}=~s/^,|,$//g;
	@tmp=split(/,/,$fin{$kwd});
	$kwd2="";
	next if ($#tmp==0);
	if    ($kwd eq "pending") {
	    $kwd2="pending-press";
	    $tmp="Pending (in press)";}
	elsif ($kwd eq "submitted") {
	    $kwd2="pending-submitted";
	    $tmp="Pending (submitted)";}
	elsif ($kwd eq "preprint") {
	    $tmp="Preprints";}
	elsif ($kwd eq "wwwdoc") {
	    $tmp="WWW documents";}
	elsif ($kwd eq "appendix") {
	    $tmp="Appendices to papers";}
	elsif ($kwd =~ /^(199|2)/){
	    $tmp=   "year";}
	else {
	    print "*** ERROR $SBR: kwd=$kwd not recognised!\n" x 3; }

	if ($tmp ne "year"){
	    $tmpkwd=$kwd;
	    $tmpkwd=$kwd2 if (length($kwd2)>0);
	    print $fhoutLoc
		"\n",
		"<TR><TD COLSPAN=6><STRONG><FONT SIZE=\"+2\"><BR>",
		"<A NAME=\"".$tmpkwd."\">".$tmp."</A></FONT></STRONG></TD</TR>\n";
	}
	else {
				# title
	    print $fhoutLoc
		"\n",
		"<TR><TD COLSPAN=6><STRONG><FONT SIZE=\"+2\"><BR>",
		"<A NAME=\"".$kwd."\">".$kwd."</A></FONT></STRONG></TD</TR>\n";
	}
				# ------------------------------
 				# resort papers by record number
	$#tmpno=0; undef %tmpno; # security reset
	foreach $it (@tmp){
	    push(@tmpno,$res{"no",$it});
	    $tmpno{$res{"no",$it}}=$it;
	}
	@tmpno=sort(@tmpno);
	$#tmp2=0;		# security reset
	foreach $tmpno (@tmpno){
	    push(@tmp2,$tmpno{$tmpno});
	}
	$#tmp=0;		# security reset
	@tmp=@tmp2;

	$#tmp2=0;$#tmpno=0;undef %tmpno; # security reset
	
				# ------------------------------
				# resort pending papers by
				#    1 press
				#    2 submitted
	if ($kwd=~/pending/){
	    $#tmpsubmitted=$#tmppress=$#tmpunk=0;
	    foreach $it (@tmp){
		if    ($res{"page",$it}=~/submit/){
		    push(@tmpsubmitted,$it);}
		elsif ($res{"page",$it}=~/page/){
		    push(@tmppress,$it);}
		else {
		    push(@tmpunk,$it);}
	    }
	    @tmp2=(@tmppress,@tmpunk,@tmpsubmitted);

#	    print "xx press=",join(",",@tmppress,"\n");
#	    print "xx   unk=",join(",",@tmpunk,"\n");
#	    print "xx   sub=",join(",",@tmpsubmitted,"\n");

	    $#tmp=0;		# security reset
	    @tmp=@tmp2;
	    $#tmp2=0; $#tmpsubmitted=$#tmppress=$#tmpunk=0; # security reset
	}
	    
				# ------------------------------
				# write
	foreach $it (@tmp) {
	    ($Lok,$msg,$title,$quote,$link,$subj,$fund)=
		&wrtOut_assist($it,"year");
	    return(0,"*** $SBR failed (assist year):\n".$msg."\n") if (! $Lok);

				# if normal: add rows for years

#	    print "xx $link $title $quote\n";
		
				# all major fields
	    print $fhoutLoc
		"<TR>",
		"<TD WIDTH=".$par{"formatWidthLinkPerc"}. ">".$link. "</TD>\t",
		"<TD WIDTH=".$par{"formatWidthTitlePerc"}.">".$title."</TD>\t",
		"<TD WIDTH=".$par{"formatWidthQuotePerc"}.">".$quote."</TD>\t",
		"<TD WIDTH=".$par{"formatWidthSubjPerc"}. ">".$subj. "</TD>\t",
		"<TD WIDTH=".$par{"formatWidthSubjFund"}. ">".$fund. "</TD>\t",
		"</TR>\n";
	}
    }

				# ------------------------------
				# table end
    print $fhoutLoc
	"\n",
	"</TABLE>\n",
	"<P>\n",
	"<!-- ", "end: table ", " -->\n",
	"<!-- ", "=" x 80 , " -->\n",
	"\n";
				# ------------------------------
				# build up bottom of page
				# ------------------------------
    print $fhoutLoc
#	$template_links,"\n",
	$template_contact,"\n",
	"<P>\n",
	$template_navi_bot,"\n",
	"\n",
	"</BODY>\n",
	"</HTML>\n";

    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of wrtOutYear

#===============================================================================
sub wrtOutSubj {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
    $| = 1;				# autoflush output (no buffering)
#-------------------------------------------------------------------------------
#   wrtOutSubj                  writes the publication table sorted by subject
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtOutSubj";
    $fhoutLoc="FHOUT_"."wrtOutSubj";
				# open file
    open($fhoutLoc,">".$par{"fileOut_subj"}) || 
	return(&errSbr("fileOutLoc=".$par{"fileOut_subj"}.", not created",$SBR));
				# ------------------------------
				# adjust title and navigation
    $title="CUBIC publication list sorted by subject";
    $prev= $par{"fileOut_index"};
    $next= $par{"fileOut_year"};

    $navi_add= " ";
    $navi_add.=" <A HREF=\"".$par{"fileWeb_papers"}. "\">CUBIC papers</A> - ";
    $navi_add.=" <A HREF=\"".$par{"fileOut_year"}.   "\">Papers by year</A> - ";
#    $navi_add.=" <A HREF=\"".$par{"fileOut_subj"}.   "\">Papers by subject</A> - ";
    $navi_add.=" <A HREF=\"".$par{"fileOut_ascii"}.  "\">Papers as flat file</A>\n";
    $kwd_navi_add="<!-- navi_add_x -->";

    $kwd_navi_add="<!-- navi_add_x -->";

    $template_head=$template{"head"};
    $template_head=~s/title_x+/$title/g;
    $template_head=~s/prev_x+/$prev/g;
    $template_head=~s/next_x+/$next/g;

    $template_navi_top=$template{"navi_top"};
    $template_navi_top=~s/prev_x+/$prev/g;
    $template_navi_top=~s/next_x+/$next/g;
    $template_navi_top=~s/$kwd_navi_add/$navi_add/g;
    $template_navi_top=~s/<P ALIGN=CENTER>//g;

    $template_navi_bot=$template{"navi_bot"};
    $template_navi_bot=~s/prev_x+/$prev/g;
    $template_navi_bot=~s/next_x+/$next/g;
    $template_navi_bot=~s/$kwd_navi_add/$navi_add/g;
    $template_navi_bot=~s/<P ALIGN=CENTER>//g;

#    $template_links=   $template{"links"};
#    $template_links=~s/(SRC=\")(Dicon)/$1\.\.\/$2/g;

    $template_contact= $template{"contact"};
    $template_contact=~s/date_x+/$date/g;

				# ------------------------------
				# build up header of page
				# ------------------------------
    print $fhoutLoc
	$template_head,"\n",
	"\n",
	"<BODY>\n",
	"\n",
	$template_navi_top,"\n",
	"\n",
	"<H1>".$title."<\/H1>\n",
	"<P>\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<!-- ", "beg: summary ", " -->\n";

				# ------------------------------
				# sort list (by subject)
				# ------------------------------
    undef %tmp; $#tmp=0;
    foreach $it (1..$res{"NROWS"}){
	foreach $subj (@subject) {
	    next if ($res{"subj",$it} !~ /$subj/i);
				# specials
	    next if ($res{"subj",$it} =~ /review/ &&
		     $subj!~/review/);
	    next if ($res{"subj",$it} =~ /threading/ &&
		     $subj=~/accessibility|secondary|sequence ana/);
	    if (! defined $tmp{$subj}) {
		push(@tmp,$subj);
		$tmp{$subj}="";}
	    $tmp{$subj}.="$it,"; }
    }

				# ------------------------------
				# links to subjects
				# ------------------------------
    print $fhoutLoc
	"<P>\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<!-- ", "beg: summary ", " -->\n",
	"<UL>\n";

    foreach $subj (@subject) {
	next if (! defined $tmp{$subj});
	$subjTmp=$subj;
	$subjTmp=$trans_subj2full{$subj} if (defined $trans_subj2full{$subj});
	print $fhoutLoc
	    "<LI><A HREF=\"#".$subj."\">".$subjTmp."</A></LI>\n";
    }
    print $fhoutLoc
	"</UL>\n",
	"<!-- ", "end: summary", " -->\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<P>\n";
				# ------------------------------
				# table begin
    print $fhoutLoc
	"<P>\n",
	"<!-- ", "=" x 80 , " -->\n",
	"<!-- ", "beg: table", " -->\n",
	"<TABLE BORDER=1 COLS=3 CELLPADDING=3 CELLSPACING=2 WIDTH=\"100%\">\n";
				# column names
    $spacer="&nbsp;";
    $spacer="";
    
    print $fhoutLoc 
	"<TR>",
	"<TH WIDTH=".$par{"formatWidthLink"}. "><STRONG>Link", $spacer x $par{"formatWidthLink"}, "</STRONG></TH>\t",
	"<TH WIDTH=".$par{"formatWidthTitle"}."><STRONG>Title",$spacer x $par{"formatWidthTitle"},"</STRONG></TH>\t",
	"<TH WIDTH=".$par{"formatWidthQuote"}."><STRONG>Quote",$spacer x $par{"formatWidthQuote"},"</STRONG></TH>\t",
	"</TR>\n" ;
				# --------------------------------------------------
				# all subjects
				# --------------------------------------------------
#    $ctSection=0;
    foreach $subj (@subject) {
	next if (! defined $tmp{$subj});
				# title
	$subjHere=$subj;
	$subjHere=$trans_subj2full{$subj} if (defined $trans_subj2full{$subj});
	print $fhoutLoc
	    "\n\n\n",
	    "<TR><TD COLSPAN=4><STRONG><FONT SIZE=\"+2\">",
	    "<A NAME=\"$subj\">$subjHere</A></FONT></STRONG></TD</TR>\n";

#	++$ctSection;

				# dissect
	$tmp{$subj}=~s/,$//g;
	@tmp=split(/,/,$tmp{$subj});
				# 	print $fhoutLoc

				# ------------------------------
				# sort by year
	$#tmp2=0; undef %tmp2;
	foreach $it (@tmp) {
	    $year=$res{"year",$it};
	    if (! defined $tmp2{$year}) {
		$tmp2{$year}="$it";
		push(@tmp2,$year);}
	    else{
		$tmp2{$year}.=",$it";}}

	@sort=sort bynumber_high2low @tmp2;
	$#tmp=0;
	foreach $year (@sort) {
	    @tmp2=split(/,/,$tmp2{$year});
	    next if ($#tmp2 < 1 || length($tmp2[1])<1);
	    push(@tmp,@tmp2);}

				# ------------------------------
				# all in that subj
	foreach $it (@tmp) {
	    ($Lok,$msg,$title,$quote,$link)=
		&wrtOut_assist($it,"subj");
	    return(0,"*** $SBR failed (assist subj):\n".$msg."\n") if (! $Lok);
				# all major fields
	    print $fhoutLoc
		"<TR>",
		"<TD WIDTH=".$par{"formatWidthLink"}. ">".$link."</TD>\t",
		"<TD WIDTH=".$par{"formatWidthTitle"}.">".$title."</TD>\t",
		"<TD WIDTH=".$par{"formatWidthQuote"}.">".$quote."</TD>\t",
		"</TR>\n";
	}
    }
    print $fhoutLoc
	"</TABLE>\n",
	"<P>\n",
	"<!-- ", "end: table ", " -->\n",
	"<!-- ", "=" x 80 , " -->\n",
	"\n";
		
				# table end
				# ------------------------------
				# build up bottom of page
				# ------------------------------
    print $fhoutLoc
#	$template_links,"\n",
	$template_contact,"\n",
	"<P>\n",
	$template_navi_bot,"\n",
	"\n",
	"</BODY>\n",
	"</HTML>\n";

    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of wrtOutSubj

#===============================================================================
sub wrtOutAscii {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
    $| = 1;				# autoflush output (no buffering)
#-------------------------------------------------------------------------------
#   wrtOutAscii                 writes the publication table sorted by year
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtOutAscii";
    $fhoutLoc="FHOUT_"."wrtOutAscii";
				# open file
    open($fhoutLoc,">".$par{"fileOut_ascii"}) || 
	return(&errSbr("fileOutLoc=".$par{"fileOut_ascii"}.", not created",$SBR));

				# ------------------------------
				# build up header of page
				# ------------------------------
    print $fhoutLoc
	"\n",
	"--- ","-" x 60 , " ---\n",
	"--- "."List of publications from CUBIC"."\n",
	"--- ","-" x 60 , " ---\n",
	"\n";

				# ------------------------------
				# sort list
				# ------------------------------
    undef %tmp; $#tmp=0;
    undef %fin;

    foreach $it (1..$res{"NROWS"}){
	$year=$res{"year",$it};
	next if ($year=~/\D/);
	if (! defined $tmp{$year}) {
	    $tmp{$year}="";
	    push(@tmp,$year);}
	$tmp{$year}.="$it,";
    }

    @sort=sort bynumber @tmp;

    $ct_published=$ct_wwwdoc=$ct_pending=$ct_preprint=0; 
    $#preprint=$#wwwdoc=$#pending=$#published=0;
				# ------------------------------
				# (1) 'normal' papers
    foreach $year (@sort) {
	next if (! defined $tmp{$year});
	$tmp{$year}=~s/,$//g;
	@tmp=split(/,/,$tmp{$year});

	push(@published,"\n".$year."\n"."\n");
				# all in that year
	foreach $it (@tmp) {
	    $quote= $res{"author",$it}." (".$res{"year",$it}.") ".$res{"title",$it}.". ";
	    $quote.=$res{"journal",$it}.", ".$res{"vol",$it}.", ".$res{"page",$it}; 
	    $quote=~s/[\s,]+$//g;

	    if ($res{"author",$it}=~/www/i) {
		$quote.=" (".$res{"www",$it}.") ";
		++$ct_wwwdoc;
		push(@wwwdoc,$ct_wwwdoc.".\t".$quote);
		next; }
	    if ($res{"no",$it}=~/^P /i ||
		$res{"no",$it}=~/^A 005/ || # ismb 95
		$res{"no",$it}=~/^A 008/ # paper J Mol Evol
		) {
		++$ct_preprint;
		push(@preprint,$ct_preprint.".\t".$quote);
		next; }
	    if ($res{"page",$it} !~/\d+\-\d/i &&
		$res{"page",$it} !~/\d+/ && # nature
		$res{"page",$it} !~/R\d+\-R\d/ # folding and design 
		) {
		++$ct_pending;
		push(@pending,$ct_pending.".\t".$quote);
		next;}
	    ++$ct_published;
				# normal sort: per year
	    push(@published,$ct_published.".\t".$quote);
	}
    }

				# ------------------------------
				# (2) published
    print $fhoutLoc
	"\n",
	"--- ","-" x 60 , " ---\n",
	"--- "."Papers published"."\n",
	"--- ","-" x 60 , " ---\n",
	"\n";
    $ct=0;
    foreach $quote (@published) {
	print $fhoutLoc $quote,"\n"; 
    }
    
				# ------------------------------
				# (3) pending
    print $fhoutLoc
	"\n",
	"--- ","-" x 60 , " ---\n",
	"--- "."Papers pending"."\n",
	"--- ","-" x 60 , " ---\n",
	"\n";
    foreach $quote (@pending) {
	print $fhoutLoc $quote,"\n"; }
    
				# ------------------------------
				# (4) preprints
    print $fhoutLoc
	"\n",
	"--- ","-" x 60 , " ---\n",
	"--- "."Preprints and unpublished documents"."\n",
	"--- ","-" x 60 , " ---\n",
	"\n";
    foreach $quote (@preprint) {
	print $fhoutLoc $quote,"\n"; }
				# ------------------------------
				# (5) www documents
    print $fhoutLoc
	"\n",
	"--- ","-" x 60 , " ---\n",
	"--- "."WWW published documents"."\n",
	"--- ","-" x 60 , " ---\n",
	"\n";
    foreach $quote (@wwwdoc) {
	print $fhoutLoc $quote,"\n"; }
    
    close($fhoutLoc);

    $ct=0; $#preprint=$#wwwdoc=$#pending=0; # slim-is-in

    return(1,"ok $sbrName");
}				# end of wrtOutAscii

#===============================================================================
sub wrtOutCenter {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
    $| = 1;				# autoflush output (no buffering)
#-------------------------------------------------------------------------------
#   wrtOutCenter                writes the publication table in RDB for center
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="wrtOutCenter";
    $fhoutLoc="FHOUT_"."wrtOutCenter";
				# open file
    open($fhoutLoc,">".$par{"fileOut_center"}) || 
	return(&errSbr("fileOutLoc=".$par{"fileOut_center"}.", not created",$SBR));

				# ------------------------------
				# build up header of page
				# ------------------------------
    print $fhoutLoc
	"\# Perl-RDB\n",
	"\# List of publications from CUBIC"."\n",
	"\# \n",
	"\# --------------------------------------------------\n",
	"\# About format\n",
	"\# --------------------------------------------------\n",
	"\# \n",
	"\# - lines starting with '\#' are ignored\n",
	"\# - columns separated by TAB\n",
	"\# - names of columns MUST be identical (succession not)\n",
	"\# \n",
	"\# \n",
	"\# --------------------------------------------------\n",
	"\# About columns\n",
	"\# --------------------------------------------------\n",
	"\# \n",
	"\# PI:       Name of PI\n",
	"\# Status:   <published|pending|preprint|www>\n",
	"\# Year:     dddd\n",
	"\# Cite:     citation, PLEASE use like 'Bxx Rost,J Liu (2000) Title. Journal, Vol, pp.'\n",
	"\# Link:     full path to your URL of paper\n",
	"\# Subj:     subject: must be one of a defined set, TBA\n",
	"\#           suggest the following\n";

    foreach $tmp (@subject) {
	next if (! defined $trans_subj2full{$tmp});
	print $fhoutLoc
	    "\#           ".$trans_subj2full{$tmp}."\n",
    }

    print $fhoutLoc
	"\#           \n",
	"\# \n",
	"\# --------------------------------------------------\n",
	"\# Additional information in header\n",
	"\# --------------------------------------------------\n",
	"\# \n",
	"\# - begin with hash '#'\n",
	"\# - use following format:\n",
	"\#   GROUP TAB list of group members separated by comma, e.g. 'Bxx Rost,J Liu'\n",
	"\# \n",
	"\# \n",
	"\# --------------------------------------------------\n",
	"\# GLOBAL VALUES\n",
	"\# --------------------------------------------------\n",
	"\# \n",
	"\# GROUP\t".$par{"groupCUBIC"}."\n",
	"\# \n",
	"\# \n";


				# ------------------------------
				# sort list
				# ------------------------------
    undef %tmp; $#tmp=0;
    undef %fin;

    foreach $it (1..$res{"NROWS"}){
	$year=$res{"year",$it};
	next if ($year=~/\D/);
				# only >=2001
	next if ($year=~/19|2000/);
	if (! defined $tmp{$year}) {
	    $tmp{$year}="";
	    push(@tmp,$year);
	}
	$tmp{$year}.="$it,";
    }

    @sort=sort bynumber_high2low @tmp;

    $ct_published=$ct_wwwdoc=$ct_pending=$ct_preprint=0; 
    $#preprint=$#wwwdoc=$#pending=$#published=0;
				# ------------------------------
				# (1) 'normal' papers
    $Lerr_subj=0;
    foreach $year (@sort) {
	next if (! defined $tmp{$year});
	$tmp{$year}=~s/,$//g;
	@tmp=split(/,/,$tmp{$year});

	push(@published,"\n".$year."\n"."\n");
				# ------------------------------
				# all in that year
	foreach $it (@tmp) {
				# get status
	    if    ($res{"author",$it}=~/www/i) {
		$status="www";}
	    elsif ($res{"no",$it}=~/^P /i ||
		   $res{"no",$it}=~/^A 005/ || # ismb 95
		   $res{"no",$it}=~/^A 008/ # paper J Mol Evol
		   ) {
		$status="preprint";}
	    elsif ($res{"page",$it} !~/\d+\-\d/i &&
		   $res{"page",$it} !~/\d+/ && # nature
		   $res{"page",$it} !~/R\d+\-R\d/ # folding and design 
		   ) {
		$status="pending";}
	    else {
		$status="published";}
				# get subject
	    $subj="";
	    foreach $tmp (@subject){
		next if (! defined $trans_subj2full{$tmp});
		next if ($res{"subj",$it} !~ /$tmp/i);
		$subj.=",".$trans_subj2full{$tmp};
	    }
	    $subj=~s/^,//;
	    if (length($subj)<5){
		print "-*- WARN c2b2 no subj for it=$it, no=",$res{"no",$it}," (subj=",$res{"subj",$it},")\n";
		$Lerr_subj=1;
	    }
	    if (! defined $res{"www",$it} ||
		length($res{"www",$it})<5){
		print "-*- WARN c2b2 no link for it=$it, no=",$res{"no",$it},"\n";
	    }

	    $quote= "rost"."\t".$res{"year",$it}."\t".$status;
	    $quote.="\t".$res{"author",$it}." (".$res{"year",$it}.") ".$res{"title",$it}.". ";
	    $quote.=$res{"journal",$it}.", ".$res{"vol",$it}.", ".$res{"page",$it}; 

	    if (defined $res{"www",$it} && $res{"www",$it} && length($res{"www",$it})){
		$quote.="\t".$res{"www",$it};}
	    else {
		$quote.="\t"." ";}

	    $quote.="\t".$subj;

	    $quote=~s/[,]+$//g;
	    $quote=~s/\s+\t/-\t/g;
	    $quote=~s/\t\s+/\t-/g;

	    if ($res{"author",$it}=~/www/i) {
		++$ct_wwwdoc;
		push(@wwwdoc,$quote);
		next; }
	    if ($res{"no",$it}=~/^P /i ||
		$res{"no",$it}=~/^A 005/ || # ismb 95
		$res{"no",$it}=~/^A 008/ # paper J Mol Evol
		) {
		++$ct_preprint;
		push(@preprint,$quote);
		next; }
	    if ($res{"page",$it} !~/\d+\-\d/i &&
		$res{"page",$it} !~/\d+/ && # nature
		$res{"page",$it} !~/R\d+\-R\d/ # folding and design 
		) {
		++$ct_pending;
		push(@pending,$quote);
		next;}
	    ++$ct_published;
				# normal sort: per year
	    push(@published,$quote);
	}
    }
    if ($Lerr_subj){
	print "--- problem with subject columns, valid are:\n";
	print join(",",@subject,"\n");
	print "---    did nevertheless continue ...\n";
    }

				# ------------------------------
				# (2) published
    print $fhoutLoc
	"PI"."\t",
	"Year"."\t",
	"Status"."\t",
	"Cite"."\t",
	"Link","\t",
	"Subj",
	"\n";
	
    foreach $quote (@published) {
	print $fhoutLoc $quote,"\n"; 
    }
    
				# ------------------------------
				# (3) pending
    foreach $quote (@pending) {
	print $fhoutLoc $quote,"\n"; }
    
				# ------------------------------
				# (4) preprints
    foreach $quote (@preprint) {
	print $fhoutLoc $quote,"\n"; 
    }

    close($fhoutLoc);

    $ct=0; $#preprint=$#wwwdoc=$#pending=0; # slim-is-in

    return(1,"ok $sbrName");
}				# end of wrtOutCenter

