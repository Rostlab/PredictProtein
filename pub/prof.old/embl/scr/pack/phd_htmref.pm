#!/usr/bin/perl
##------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#				version 0.2   	Oct,    	1998	       #
#------------------------------------------------------------------------------#

package phd_htmref;

#===============================================================================
sub phd_htmref {
#-------------------------------------------------------------------------------
#   phd_htmref                  package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0

    @ARGV=@_;			# pass from calling

				# ------------------------------
    ($Lok,$msg)=		# initialise variables
	&ini;
    if (! $Lok) { print "*** ERROR $scrName after ini\n",$msg,"\n";
		  die "*** during initialising $scrName   ";}

# --------------------------------------------------------------------------------
# loop over list of RDB files
# --------------------------------------------------------------------------------

    foreach $file_in (@file_in) {
				# get PDBid and output file name
	$id=$file_in;$id=~s/.*\/|\n|\s|\..*$//g;
	$file_out="$title"."$ext_out"                      if ($title ne "unk");
	$file_out="$id"."$ext_out"                         if ( ($file_out eq "unk") || ($#file_in>1) );
	print $fhout_det "--- id=$id, file_in=$file_in \n" if ($Ldo_wrt_det);
	
	undef %rd;
	%rd=
	    &rd_rdb_associative($file_in,"not_screen","header","body",@des_rd);
				# ------------------------------
				# correct RDB
				# ------------------------------
	$#tmp=0;
	foreach $des_rd(@des_rd){
	    foreach $des (keys %des_trsl){ # change names
		next if ($des_rd ne $des);
		foreach $it(1..$rd{"NROWS"}){
		    $desNew=$des_trsl{$des};
		    $rd{$desNew,$it}=$rd{$des_rd,$it};}
		$des_rd=$des_trsl{$des};
		last;}
	    push(@tmp,$des_rd) if (defined $rd{$des_rd,"1"});}
	@des_rd=@tmp; $#tmp=0;
				# ------------------------------
				# htmref : dynamic programming 
				#          refinement of PHDhtm
				# ------------------------------
	$desvec="";		# concetenate @des into one vector (tab separated)
	foreach $_(@des_rd){$desvec.="$_"."\t";}
	$desvec=~s/\t$//g;
	($nmax,$model_max,$n2nd,$model_2nd,$ri,$ri_diff)=    
	    &htmref($Lmin,$Lmax,$Lloop,$Tminval,$Tgrid,$desvec,$syml,$symh,
		    $Ldo_wrt_det,$fhout_det,$Lscreen);
	
	$rd{"PRHL","format"}= "1S";
	$rd{"PR2HL","format"}="1S";
	$rd{"RI_H","format"}= "1N";
	foreach $it (1..length($model_max)) {
	    $rd{"PRHL",$it}= substr($model_max,$it,1);
	    $rd{"PR2HL",$it}=substr($model_2nd,$it,1); }
				# ------------------------------
				# now write filtered version
				# ------------------------------
	foreach $_(@des_out){$desvec.="\t"."$_";} 

#	&wrt_rdb_htmref("STDOUT",$desvec,"\t",$nmax,$n2nd,$ri,$ri_diff) if ($Lscreen);

	&open_file($fhout, ">$file_out");
	&wrt_rdb_htmref($fhout,$desvec,"\t",$nmax,$n2nd,$ri,$ri_diff);
	close($fhout);

	print "--- htmref_phd output in file: \t '$file_out'\n" if ($Lscreen);
    }				# end of loop over all files

    close($fhout_det)           if ($Ldo_wrt_det);
    return(1,"ok");
}				# end of phd_htmref


#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $scrName=$0; $scrName=~s/^.*\/|\.pl//g;
    $scrGoal=    "refine the prediction of PHDhtm";

    $scrIn=      ".rdb_phd file from PHD";
    $scrNarg=    1;		# minimal number of input arguments


    $SBR="$scrName:"."ini";     
				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
#    &iniLib();			# require perl libraries

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();
				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelp(%tmp);   
                                return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 

				# ------------------------------
				# other defaults
				# ------------------------------
    $file_out=$title="unk";
    $ext_out=        ".rdb_phdref";
    $dir_rdb=        "";
    $Ldo_wrt_det=    0;
				# ------------------------------
				# read command line input
    
    $file_in= $ARGV[1]; 	
    foreach $arg (@ARGV) {	# interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
	next if ($arg eq $ARGV[1]);

	if    ($arg=~/^file_out=(.+)$/)         { $file_out=   $1;}
	elsif ($arg=~/^title=(.+)$/)            { $title=      $1;}
	elsif ($arg=~/^ext_out=(.+)$/)          { $ext_out=    $1;}
	elsif ($arg=~/^dir_rdb=(.+)$/)          { $dir_rdb=    $1;
						  $dir_rdb.="/" if ($dir_rdb !~/\/$/);}
	elsif ($arg=~/^do_wrt_det/)             { $Ldo_wrt_det=1;}

	elsif ($arg=~/^not_?screen$/i)          { $Lscreen=    0; }
	elsif ($arg=~/^(verb[^=]*|de?bu?g)$/)   { $Lscreen=    1; }

	elsif ($arg=~/^.*htmref_Lmin=(.+)$/)    { $Lmin=       $1;}
	elsif ($arg=~/^.*htmref_Lmax=(.+)$/)    { $Lmax=       $1;}
	elsif ($arg=~/^.*htmref_Lloop=(.+)$/)   { $Lloop=      $1;}
	elsif ($arg=~/^.*htmref_Tminval=(.+)$/) { $Tminval=    $1;}
	elsif ($arg=~/^.*htmref_Tgrid(.+)$=/)   { $Tgrid=      $1;} 

	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}

    $fhout="FHOUT";
    $fhin="FHIN";
    $fhout_det="FHOUT_DET";
    $tmp=$file_in;$tmp=~s/^.*\///g;$tmp=~s/\.rdb.*$|\.list.*$//g;
    $file_out_det="Refdet_".$tmp.".txt";

				# --------------------------------------------------
				# interpret input file (list or RDB file?)
				# --------------------------------------------------
    if (! -e $file_in){
	print "*** ERROR ($scrName): file $file_in does not exist!\n";
	exit; }

    $#file_in=0;
				# input file exists (either RDB or list)
    if (! &is_rdbf($file_in)){ # list
	&open_file("$fhin", "$file_in");
	while (<$fhin>) {
	    $_=~s/\n|\s//g; 
	    next if (length($_)==0);
	    $Lok=0;
	    if (-e $_){
		$Lok=1;
		$tmp=$_; }
	    else { 
		$tmp = $dir_rdb ."$_";
		$Lok=1; }
	    push(@file_in,$tmp) if ($Lok && &is_rdbf($tmp)); 
	} close($fhin); 

	if ($#file_in==0){
	    print "*** ERROR ($scrName) no valid RDB file found in list '$file_in'\n";
	    exit; }}
    else {
	push(@file_in,$file_in);}

				# ------------------------------
				# change some defauls
				# ------------------------------
				# intermediate write all results into dir
    if ($Ldo_wrt_det){
	&open_file($fhout_det, ">$file_out_det");
	printf $fhout_det 
	    "# Lmin=%4d, Lmax=%4d, Lloop=%4d, Tminval=%5.2f, Tgrid=%5.1f\n",
	    $Lmin,$Lmax,$Lloop,$Tminval,$Tgrid;}

				# ------------------------------
				# write settings
				# ------------------------------
    if ($Lscreen){
	print  "--- $scrName\n","---\n";
	printf "--- %-20s %-s\n","file_in",       $file_in;
	printf "--- %-20s %-s\n","file_out",      $file_out;
	printf "--- %-20s %-s\n","title",         $title;
	printf "--- %-20s %-s\n","ext_out",       $ext_out;
	printf "--- %-20s %-s\n","dir_rdb",       $dir_rdb;
	printf "--- %-20s %-s\n","do_wrt_det",    $do_wrt_det;
	printf "--- %-20s %-s\n","htmref_Lmin",   $Lmin;
	printf "--- %-20s %-s\n","htmref_Lmax",   $Lmax;
	printf "--- %-20s %-s\n","htmref_Lloop",  $Lloop;
	printf "--- %-20s %-s\n","htmref_Tminval",$Tminval;
	printf "--- %-20s %-s\n","htmref_Tgrid",  $Tgrid;
	print  "--- \n"; }

    return(1,"ok $SBR");
}				# end of ini

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      initialise defaults
#-------------------------------------------------------------------------------
                                # d.d

#------------------------------------------------------------------------------------------
# parameters for refinement
# .........................
#
# cutshort=n           cut anything < n
# Lmin                 minimal length of transmembrane helix
# Lmax                 maximal length of transmembrane helix
# Lmin                 minimal length of loop region between two HTM's
# Tlengthen            threshold for probability: if (otH/(otH+otL))>T -> lengthen helix!
#------------------------------------------------------------------------------------------

    $Lmin=          18;		# minimal length of transmembrane helix
#    $Lmin=          19;		# minimal length of transmembrane helix
    $Lmax=          25;		# maximal length of transmembrane helix
    $Lloop=          4;		# minimal length of loop region between two HTM's
    $Tminval=        0.5;	# to reduce CPU time, only segments treated with a 
				#      per-residue score > $Tmin_score
    $Tgrid=        100;		# grid for comparing scores (avoid getting always short segments)
#    $Tgrid=         50;		# grid for comparing scores (avoid getting always short segments)
#
# version 00: 17,27, 0.6, 4  (note 3rd = Tlengthen, dead now)
# version 01: 16,25, 0.6, 4
# version 02: 16,27, 0.6, 5
# version 03: 16,25, 0.5, 5

# version 10-95: 18, 27, 4 grid=100
# version 01-96: 18, 25, 4 grid= 50, excl=0.4


    $syml="L"; $symh="H";	# symbols used for HTM and non-HTM


    @des_rd= ("No","AA","OHL","PHL","PFHL","RI_H","RI_S","pH","pL","OtH","OtL");
    @des_out=("PRHL","PR2HL");
    %des_trsl=('RI_S',"RI_H");	# output will be 'RI_H' (input may be RI_S)


}				# end of iniDef

#===============================================================================
sub iniLib {
#    local(%parLoc)=@_;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniLib                       
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniLib";
    $par{"dirPerl"}=            "/home/rost/perl/"; # directory for perl scripts needed

    $USERID=`whoami`; $USERID=~s/\s//g;
    if ($USERID eq "phd"){
	require "/home/phd/ut/perl/lib-br.pl";
	require "/home/phd/ut/perl/lib-ut.pl";}
    else { 
	$dir=0;
	foreach $arg(@ARGV){
	    if ($arg=~/dirLib=(.*)$/){$dir=$1;
				      last;}}
	if (! defined $dir || ! $dir || ! -d $dir) {
	    $dir=$dir || "/nfs/data5/users/ppuser/server/pub/phd/scr/" || "/home/rost/perl/" || $ENV{'PERLLIB'} ||
		$ENV{'PWD'} || `pwd`; }
	if (! defined $dir || ! $dir || ! -d $dir) {
	    $tmp=$0; $tmp=~s/^\.\///g; $tmp=~s/^(.*\/)(.*)$/$1/; $tmp=~s/^scr\/?//g;
	    $dir=$tmp."scr/";  $dir=~s/\/$//g; }
	if (! defined $dir || ! $dir || ! -d $dir) {
	    $dir=""; }
	else { $dir.="/"     if ($dir !~/\/$/); }
	foreach $lib ("lib-br.pl","lib-ut.pl"){
	    require $dir.$lib ||
		die ("*** $scrName failed requiring perl libs \n".
		     "*** give as command line argument 'dirLib=DIRECTORY_WHERE_YOU_FIND:lib-ut.pl'"); }}
}				# end of iniLib

#===============================================================================
sub iniHelp {
    local($SBR);
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
    $tmp{"special"}=         "title".",";
    $tmp{"special"}.=        "file_out".","; 
    $tmp{"special"}.=        "ext_out".","; 
    $tmp{"special"}.=        "dir_rdb".","; 
    $tmp{"special"}.=        "do_wrt_det".","; 
    $tmp{"special"}.=        "htmref_Lmin".","; 
    $tmp{"special"}.=        "htmref_Lmax".","; 
    $tmp{"special"}.=        "htmref_Lloop".","; 
    $tmp{"special"}.=        "htmref_Tminval".","; 
    $tmp{"special"}.=        "htmref_Tgrid".","; 
        
    $tmp{"title"}=           "title of output file (adds ext .rdb_phdref)";
    $tmp{"file_out"}=        "output file";
    $tmp{"ext_out"}=         "use PDBid 'ext_out' for output RDB files";
    $tmp{"dir_rdb"}=         "directory of input RDB files";
    $tmp{"do_wrt_det"}=      "for all results, details written into file Refdet_* list name";
    $tmp{"htmref_Lmin"}=     "minimal length of HTM";
    $tmp{"htmref_Lmax"}=     "maximal length of HTM";
    $tmp{"htmref_Lloop"}=    "minimal loop between two HTMs";
    $tmp{"htmref_Tminval"}=  "minimal score of HTM to be processed (safe CPU time)";
    $tmp{"htmref_Tgrid"}=    "grid to distinguish best/2nd best (=50 brings less short ones)";

#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelp

#==============================================================================
# library collected (begin)
#==============================================================================

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
	    print "--- input to $sbrName kwd=$kwd, val=",$tmp{"$kwd"},",\n";}
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
		$tmp=" "; $tmp=$tmp{"$kwd"} if (defined $tmp{"$kwd"});
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
                    printf "--- %-20s = %-s\n",$kwd,$par{"$kwd"};}
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
		    if (defined $def{"$kwd","expl"}){
			$def{"$kwd","expl"}=~s/\n/\n---                        /g;
			push(@expLoc,$def{"$kwd","expl"});}
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
		if (defined $def{"$kwd"}){
		    $def{"$kwd"}=~s/\n[\t\s]*/\n---                        /g;
		    push(@expLoc,$def{"$kwd"});}
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
                    printf "--- %-20s = %-s\n",$kwd,$par{"$kwd"};}
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
    $Lis=0;undef %tmp; $#tmp=0;
    while (<$fhinLoc>) {        # read lines with '   %par{"kwd"}= $val  # comment '
        $_=~s/\n//g;
        last if ($_=~/^su[b] .*\{/ && $_!~/^su[b] iniDef.* \{/);
				# new expression 
        if    ($_=~/[\s\t]+\$par\{[\"\']?([^\"\'\}]+)[\"\']?\}[^\#]*\#\s*(.*)$/){
            $Lis=1;$kwd=$1; push(@tmp,$kwd); 
	    $tmp{"$kwd"}=$2 if (defined $2);}
				# end if only '------' line
        elsif ($Lis && defined $tmp{"$kwd"} && $_=~/^[\s\t]+\# ?\-+/){
            $Lis=0;}
				# add to previous (only if it had an explanation)
        elsif ($Lis && defined $tmp{"$kwd"} && $_=~/^[\s\t]*\# (.*)$/){
            $tmp{"$kwd"}.="\n".$1;}
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

    undef %defaults; $#kwd=0; $Lis=0;
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
	    $kwd=$1; push(@kwd,$kwd); $defaults{"$kwd"}=$2; 
            $defaults{"$kwd","expl"}=$3 if (defined $3 && length($3)>1); $Lis=1;}
				# (2) case 'kwd  val'
	elsif ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]*$/){
	    $kwd=$1; $defaults{"$kwd"}=$2; $Lis=1; $defaults{"$kwd","expl"}=""; }
				# (3) case '          # ----'
	elsif ($Lis && $line =~ /^\#\s*[\-\=\_\.\*]+/){
	    $Lis=0;}
	elsif ($Lis && defined $defaults{"$kwd","expl"} && $line =~ /^\#\s*(.*)$/){
	    $defaults{"$kwd","expl"}.="\n".$1;}}
    close($fhin);
				# ------------------------------
    foreach $kwd (@kwd){        # fill in wild cards
        $defaults{"$kwd"}=$ARCH if ($defaults{"$kwd"}=~/ARCH/);}
                                # ------------------------------
    foreach $kwd (@kwd){        # complete it
	$defaults{"$kwd","expl"}=" " if (! defined $defaults{"$kwd","expl"});}
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
	    $par{"$kwd"}=$defaults{"$kwd"};}}
    return(0,"*** ERROR $sbrName failed finishing to read defaults file\n") if (! $Lok);

    return(1,"ok $sbrName",%defaults);
}				# end of brIniRdDef

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
sub form_rdb2perl {
    local ($format) = @_ ;
    local ($tmp);
#--------------------------------------------------------------------------------
#   form_perl2rdb               converts RDB (N,F, ) to printf perl format (d,f,s)
#--------------------------------------------------------------------------------
    $format=~tr/[A-Z]/[a-z]/;
    $format=~s/n/d/;$format=~s/(\d+)$/$1s/;
    if ($format =~ /[s]/){
	$format="%-".$format;}
    else {
	$format="%".$format;}
    return $format;
}				# end of form_rdb2perl

#==============================================================================
sub get_max { $[=1;local($ct,$pos,$max);$max=-1000000;$ct=$pos=0; 
#----------------------------------------------------------------------
#   get_max                     returns the maximum of all elements of @in
#       in:                     @in
#       out:                    returned $max,$pos (position of maximum)
#----------------------------------------------------------------------
	      foreach $_(@_){if(defined $_){
		  ++$ct; 
		  if($_>$max){$max=$_;$pos=$ct;}}}
	      return ($max,$pos); } # end of get_max


#==============================================================================
sub get_min { $[=1;local($ct,$pos,$min);$min=100000; $ct=0; 
#----------------------------------------------------------------------
#   get_min                     returns the minimum of all elements of @in
#       in:                     @in
#       out:                    returned $min,$pos (position of minimum)
#----------------------------------------------------------------------
	      foreach $_(@_){++$ct; if($_<$min){$min=$_;$pos=$ct;}}
	      return ($min,$pos); } # end of get_min


#==============================================================================
sub get_zscore { local ($score,@data) = @_ ; local ($ave,$var,$sig,$zscore);
		 $[ =1 ;
#--------------------------------------------------------------------------------
#   get_zscore                  returns the zscore = (score-ave)/sigma
#       in:                     $score,@data
#       out:                    zscore
#--------------------------------------------------------------------------------
		 ($ave,$var)=&stat_avevar(@data);
		 $sig=sqrt($var);
		 if ($sig != 0){ $zscore=($score-$ave)/$sig; }
		 else          { print"x.x get_zscore: sig=$sig,=0?\n";$zscore=0; }
		 return ($zscore);
}				# end of get_zscore

#==============================================================================
sub is_rdbf {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_rdbf                     checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_rdbf

#==============================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    if ( int($npoints/10)!=($npoints/10) ) {
	print "*** ERROR in myprt_npoints (lib-br.pl): \n";
	print "***       number of points should be multiple of 10 (is $npoints)!\n"; 
	return(" "); }
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
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#==============================================================================
sub rd_rdb_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rd_rdb_associative          reads the content of an RDB file into an associative
#                               array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#                       ALL:    'head,body'
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#                       HEADER: rdrdb{"header"}
#                       NAMES:  rdrdb{"names"} 
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhin="FHIN_RDB";
    $sbr_name="rd_rdb_associative";
				# get input
    $Lhead=$Lbody=$Lhead_all=$Lbody_all=$#des_headin=$#des_bodyin=0;
    foreach $des_in(@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; $Lbody_all=1;}
	elsif($Lhead)                        {push(@des_headin,$des_in); $Lhead_all=0;}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;; $Lbody_all=0;
					      push(@des_bodyin,$des_in);}
	else {print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &read_rdb_num2($fhin,0);
    close($fhin);
				# ------------------------------
				# process header
    $#des_head=0;
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^$des_in[ :,\;]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;
		    $tmp=~s/$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);
		    $Lfound=1;} }
	    if(!$Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find in header key word:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}
	}}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { 
	    $rd=~s/^\s?|\n//g;
	    $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
				# get column numbers to be read
    $#des_body=0;
    if (! $Lbody_all){
	foreach $des_in (@des_bodyin) {
	    $Lfound=0;
	    for($it=1;$it<=$#READNAME;++$it) {
		$rd=$READNAME[$it];
		if ($rd eq $des_in) {$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);
				     $Lfound=1;last;} }
	    if((!$Lfound) && $Lscreen){
		print"--- $sbr_name: \t expected to find column name:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}}}
    else {
	foreach $it(1..$#READNAME){
	    $name=$READNAME[$it];$ptr_rd2des{"$name"}=$it;
	    push(@des_body,$name);}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}

    $nrow_rd=0;$names="";
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if ($nrow_rd==0){
	    $nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){
	    print "*** WARNING $sbr_name: different number of rows\n";
	    print "*** WARNING in RDB file '$file_in' for rows with ".
		  "key= $des_in and previous column no=$itrd,\n";}
	$names.="$des_in".",";
	for($it=1;$it<=$#tmp;++$it){
	    $rdrdb{"$des_in",$it}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==============================================================================
sub read_rdb_num2 {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   read_rdb_num2               reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT= 0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {$READHEADER.= "$_"; # header  
		      next;}
	++$ct;			# rest
	if ( $ct >= 3 ) {	              # col content
	    @tmpar=split(/\t/);
	    for ($it=1; $it<=$#readnum; ++$it) {
		if (defined $tmpar[$readnum[$it]]) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }} }
	elsif ( $ct==1 ) {	      # col name
	    $_=~s/\t$//g;@tmpar=split(/\t/);
				# care about wild card
	    if ( ($#readnum==0)||($readnum[1]==0) ) {
		for ($it=1;$it<=$#tmpar;++$it) {$readnum[$it]=$it;}
		for ($it=1;$it<=$#tmpar;++$it) {$READCOL[$it]=""; } }
	    
	    for ($it=1; $it<=$#readnum; ++$it) {$tmp_name=$tmpar[$readnum[$it]];
						$tmp_name=~s/\s|\n//g;
						$READNAME[$it]="$tmp_name";} }
	elsif ( $ct==2 ) {	      # col format
	    if ($_=~/\t\d+[NSF]|\d+[NSF]\t/){
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		    $READFORMAT[$it]=$tmp;}}
	    else {		# no format given, read line
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    if (defined $tmpar[$readnum[$it]]) {
			$READCOL[$it].=$tmpar[$readnum[$it]] . "\t";}}}}
    }
    for ($it=1; $it<=$#READNAME; ++$it) {
	if (!defined $READFORMAT[$it]){
	    print "-*- WARN lib-br.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";}
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of read_rdb_num2

#==============================================================================
sub stat_avevar {
    local(@data)=@_;
    local($i, $ave, $var);
    $[=1;
#----------------------------------------------------------------------
#   stat_avevar                 computes average and variance
#       in:                     @data (vector)
#       out:                    $AVE, $VAR
#          GLOBAL:              $AVE, $VAR (returned as list)
#----------------------------------------------------------------------
    $ave=$var=0;
    foreach $i (@data) { $ave+=$i; } 
    if ($#data > 0) { $AVE=($ave/$#data); } else { $AVE="0"; }
    foreach $i (@data) { $tmp=($i-$AVE); $var+=($tmp*$tmp); } 
    if ($#data > 1) { $VAR=($var/($#data-1)); } else { $VAR="0"; }
    return ($AVE,$VAR);
}				# end of stat_avevar

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------
    @tmp=("/home/rost/perl/ctime.pl","/nfs/data5/users/ppuser/server/pub/perl/ctime.pl");
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
# library collected (end)
#==============================================================================

#==========================================================================================
sub get_htm_best {
    local ($numres,$des_model,$des_score,%model) = @_ ;
    local ($max,$snd,$pos_max,$pos_snd,$it,$sum,$ri);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_htm_best               gets best and second best model, and reliability
#--------------------------------------------------------------------------------
				# get maxima
    push(@score,$model{"$des_score","0"});
    $max=$snd=$pos_max=$pos_snd=$#score=0;
    foreach $it (1 .. $model{"NROWS"}) {
	push(@score,$model{"$des_score",$it});
	if (int($model{"$des_score",$it})>=int($max)){
	    $max=$model{"$des_score",$it};
	    $pos_max=$it;} }
    foreach $it (1 .. $model{"NROWS"}) {
	next if ($model{"$des_score",$it}==$max);
	next if ($model{"$des_score",$it}<=$snd);
	$snd=$model{"$des_score",$it};
	$pos_snd=$it; }
				# compute reliability
    if ($#score>1){
	$ri=&get_zscore($max,@score);}
    else {
	$ri=99;}
    return($max,$pos_max,$model{"$des_model","$pos_max"},
	   $snd,$pos_snd,$model{"$des_model","$pos_snd"},$ri);
}				# end of get_htm_best

#==========================================================================================
sub get_htm_model {
    local ($model_in,$Ncap,$Ccap,$symh)= @_ ;
    local ($it,$model);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_htm_model              returns the assignment for current model
#--------------------------------------------------------------------------------
    $model=$model_in;
				# first: assign new helix
    foreach $it ($Ncap .. $Ccap) {
	substr($model,$it,1)=$symh; }
    return($model);
}				# end of get_htm_model

#==========================================================================================
sub get_htm_score {
    local ($Ncap,$Ccap,$prh,$prl)= @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_htm_score               gets difference between old and new score
#   GLOBAL in:                  $rd{}
#--------------------------------------------------------------------------------
    $score_old=$score_new=0;
    foreach $it ($Ncap .. $Ccap) {
	$score_old+=$rd{"$prl",$it};
	$score_new+=$rd{"$prh",$it}; }
    return ($score_old,$score_new);
}				# end of get_htm_score

#==========================================================================================
sub get_prob {
    local ($numres,$oth,$otl,$prh,$prl)= @_ ;
    local ($sum,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_prob                    computes the probabilities: prH= OtH/ (OtH + OtL)
#   GLOBAL in:                  $rd{}
#--------------------------------------------------------------------------------
    foreach $it (1..$numres){
	$sum=$rd{"$oth",$it} + $rd{"$otl",$it};
	if ($sum>0) { $rd{"$prh",$it}=$rd{"$oth",$it}/$sum;
		      $rd{"$prl",$it}=$rd{"$otl",$it}/$sum; }
	else        { $rd{"$prh",$it}=0;
		      $rd{"$prl",$it}=0; } }
}				# end of get_prob

#==========================================================================================
sub htmref {
    local ($Lmin,$Lmax,$Lloop,$Tminval,$Tgrid,
	   $desvec,$syml,$symh,$Ldo_wrt_det,$fhout_det,$Lscreen) = @_ ;
    local ($oth,$otl,$prh,$prl,$phd,$ri,$Ncap,$Ccap,
	   @des,$ct,$numres,$it,$Lcontinue,$ct_htm,$model_act,$score,$model_out,
	   %model,$max,$posmax,$Ncap,$Ccap,$score_old,$score_new,
	   $pos_max,$model_max,$snd,$pos_snd,$model_snd,$ri);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    htmref                     implements the following algorithm:
#       loop until all residues = HTM
#            * find best = maximum of all sums of PrH=[OtH/(OtH+OtL)] over segments
#                 of minimal length Lmin
#            * compile score (sum over Pr(H or L), depending on current prediction
#                 (alternative: score only over helices)
#            * block (i.e. exclude from further analysis): 
#                 - Lloop residues on both sides of helix
#                 - too short loops (<Lmin)
#                 - Lmin residues on either side of (Ncap-Lloop) or (Ccap+Lloop)
#       select best model
#       compute scores and reliability (currently score/sum(max+two neighbours))
#
#   global variables            @Smin,@Smin_new,%Smin_ptr2seq,%Smin_ptr2seq_new,
#                               (used for communication with sbr's inside of this
#      
#--------------------------------------------------------------------------------
				# vector to array
    @des=split(/\t/,$desvec);
				# initialise wanted keys (imported %rd)
    $oth="OtH"; $otl="OtL"; $phd="PHL"; $ri="RI_H";
				# used from here on
    $prh="PrH"; $prl="PrL"; 
				# check input (expected to find: "PHL","RI_H","OtH","OtL"
    $ct=0;
    foreach $_ (@des){ 
	++$ct if ($_ =~ /$oth|$otl|$phd|$ri/); }
    if ($ct != 4) {
	print "*** ERROR in htmref: wants the following names:$oth,$otl,$phd,$ri,\n";
	exit;}
				# --------------------------------------------------
				# refine
				# --------------------------------------------------
    $numres=$rd{"NROWS"};	# number of residues

				# compile probabilities
    print "--- htmref: \t \t compute probabilities\n" if ($Lscreen);
    &get_prob($numres,$oth,$otl,$prh,$prl);

				# compute scores summed over all helices (GLOBAL rd,all)
    print "--- htmref: \t \t compute scores for minimal segments ($Lmin)\n" if ($Lscreen);
    &htmref_all($numres,$Lmin,$Lmax,$Tminval,$Tgrid,$prh,$prl);
    $nseg=     $all{"NROWS"};
    $Lcontinue=1;		# initialise
    $ct_htm=   0;
    $model_act="";foreach $it (1..$numres){$model_act.="$syml";}
    $model_ini=$model_max=$model_snd=$model_act;
    foreach $it (1..$all{"NROWS"}){
	$all{$it}=0;}
				# score for assumption: all loop
    $score=0;
    foreach $it (1..$numres){
	$score+=$rd{"$prl",$it};} 
    $model{"string","0"}=$model_act;
    $model{"score","0"}=$score;
				# -----------------------------------------
				# now loop until all HTM possible are built
    while ($Lcontinue){
	++$ct_htm;
				# get segment with maximal per-residue score
	($max,$posmax)=
	    &htmref_max($Tgrid);
	$Ncap=$all{"$posmax","beg"};$Ccap=$all{"$posmax","end"}; # caps
	($Nlim,$tmp)=&get_max(1,($Ncap-$Lloop)); # limits (including minimal loop regions)
	($Clim,$tmp)=&get_min($numres,($Ccap+$Lloop));
				# update the flip counter ($all{}  GLOBAL)
	$nseg=
	    &htmref_flip($posmax,$Nlim,$Clim,$nseg);
				# build up model
	$model_out=
	    &get_htm_model($model_act,$Ncap,$Ccap,$symh);
	$model_act=$model_out;
				# compute score
	($score_old,$score_new)=
	    &get_htm_score($Ncap,$Ccap,$prh,$prl);
	$model{"model","$ct_htm"}=$model_act;
	$score=$score-$score_old+$score_new;
	$model{"score","$ct_htm"}=$score; 
	$res_model{"score","$ct_htm"}=$score/$numres; $res_model{"max","$ct_htm"}=$max;
	$res_model{"Ccap","$ct_htm"}=$Ccap;$res_model{"Ncap","$ct_htm"}=$Ncap;
	
	$tmp=sprintf("--- mod %2d =%5.3f max=%5.2f iseg=%4d (%4d-%4d) l=%3d left=%3d htms\n",
		     $ct_htm,($score/$numres),$max,$posmax,$Ncap,$Ccap,($Ccap-$Ncap+1),$nseg);
	
	print $tmp              if ($Lscreen);
	print $fhout_det $tmp   if ($Ldo_wrt_det);

				# check whether another sweep (unassigned = long enough?)
	if ($nseg<1){
	    $Lcontinue=0; 
	    last;}
	if ($ct_htm>($numres/($Lmin+2*$Lloop))){
	    print "xx failed in htmref ($scrName)\n";
	    last;}	# x.x
#	if ($ct_htm>=1){print "x.x left\n";last;}
    }
				# end of loop over all possible models
				# --------------------------------------------------
				# now get best model
    $model{"NROWS"}=$ct_htm;
    if ($ct_htm>1) {
	($max,$pos_max,$model_max,$snd,$pos_snd,$model_snd,$ri)=
	    &get_htm_best($numres,"model","score",%model);}
    else {
	($max,$pos_max,$model_max,$snd,$pos_snd,$model_snd)=
	    ($model{"score","1"},1,$model_act,0,0,$model_ini);
	$snd=$model{"score","0"};}
    $ri_diff=($max-$snd)/$numres;
    if ($Lscreen) {
	printf 
	    "best model has %2d helices (%4d), 2nd best has %2d (%4d), ri=%5.2f, D=%5.2f\n",
	    $pos_max,int($max),$pos_snd,int($snd),$ri,$ri_diff;
	$model_phd="";
	foreach $it(1..$numres){
	    $model_phd.=$rd{"$phd",$it};}
	for($it=1;$it<=$numres;$it+=60){
	    $tmp0=&myprt_npoints(60,$it);
	    $tmp1="";
	    foreach$it2($it..($it+59)){
		$tmp1.=$rd{"OHL","$it2"} if (defined $rd{"OHL","$it2"}); }
	    $tmp1=~s/L/ /g;
	    $tmp2=substr($model_phd,$it,60);$tmp2=~s/L/ /g;
	    $tmp3=substr($model_max,$it,60);$tmp3=~s/L/ /g;
	    $tmp4=substr($model_snd,$it,60);$tmp4=~s/L/ /g;

	    printf "%3s  %s\n"," ",$tmp0;
	    printf "%3s |%s|\n","obs",$tmp1 if ((defined $tmp1)&&(length($tmp1)==length($tmp2)));
	    printf "%3s |%s|\n","old",$tmp2;
	    printf "%3s |%s|\n","new",$tmp3;
	    printf "%3s |%s|\n","2nd",$tmp4;
	    printf "%3s |","ri";
	    foreach $it2($it..($it+59)){
		printf "%1d",$rd{"RI_H","$it2"} if (defined $rd{"RI_H","$it2"}); }
	    print "\n";		# x.x
	    printf "%3s |","pr";
	    foreach $it2($it..($it+59)){
		printf "%1d",int(10*$rd{"$prh","$it2"})  if (defined $rd{"$prh","$it2"});}
	    print "\n";		# x.x
	}
    }
    return($pos_max,$model_max,$pos_snd,$model_snd,$ri,$ri_diff);
}				# end of htmref

#==========================================================================================
sub htmref_all {
    local ($numres,$Lmin,$Lmax,$Tminval,$Tgrid,$prh,$prl)= @_ ;
    local ($sum,$it,$itres,$Lscreen_loc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    htmref_all                 computes the sums over all helical predictions
#                               for segments of length Lmin up to Lmax
#                               note: segments with length > Lmin only if average
#                                     per-residue score higher than previous
#   GLOBAL in:                  $rd{}
#   GLOBAL out:                 $all{}
#--------------------------------------------------------------------------------
    $ct=0;
    $Lscreen_loc=1;
    $Lscreen_loc=0;
				# all residues
    foreach $itres (1..($numres+1-$Lmin)){
	$sum=0;			# segments of length Lmin
	foreach $it ( $itres .. ($itres+$Lmin-1) ){
	    $sum+=$rd{"$prh",$it}; }
	$val_tmp=$sum/$Lmin;
	if (int($Tgrid*$val_tmp)>=int($Tgrid*$Tminval)){
	    ++$ct;
	    $all{$ct,"beg"}=$itres; $all{$ct,"end"}=$itres+$Lmin-1; $all{$ct,"len"}=$Lmin;
	    $all{$ct,"val"}=$val_tmp;             # per-residue score
	    &htmref_all_prt("STDOUT",$ct,$Tgrid)    if ($Lscreen_loc);
	    $val_mem=$all{$ct,"val"};}
	else {
	    $val_mem=$val_tmp; }
	$len_tmp=$Lmin;
	$sum=    $val_mem*$Lmin;
				# lengthen until maximal length
	foreach $it ( ($itres+$Lmin) .. ($itres+$Lmax-1) ){
#	    if (! defined $rd{"$prh",$it}){
#		next;}
	    $sum+=$rd{"$prh",$it} if (defined $rd{"$prh",$it});
	    ++$len_tmp;$val_tmp=$sum/$len_tmp;
	    if ((int($Tgrid*$val_tmp)>=int($Tgrid*$val_mem)) && 
		(int($Tgrid*$val_tmp)>=int($Tgrid*$Tminval)) ) {
		++$ct;
		$all{$ct,"beg"}=$itres;$all{$ct,"end"}=$it;$all{$ct,"len"}=$len_tmp;
		$all{$ct,"val"}=$val_tmp;       # per-residue score
		&htmref_all_prt("STDOUT",$ct,$Tgrid) if ($Lscreen_loc); }}
    }
    $all{"NROWS"}=$ct;
    return (%all);
}				# end of htmref_all

#==========================================================================================
sub htmref_all_prt {
    local ($fh,$ct,$Tgrid) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
    printf $fh 
	"%3d %3d-%3d=%3d sc=%6d\n",
	$ct,$all{$ct,"beg"},$all{$ct,"end"},$all{$ct,"len"},int($Tgrid*$all{$ct,"val"});
	
}				# end of htmref_all_prt

#==========================================================================================
sub htmref_flip {
    local ($posmax,$Nlim,$Clim,$nseg)= @_ ;
    local ($itseg);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   htmref_flip                 updates the flags 
#   GLOBAL (in/out)             $all{}
#--------------------------------------------------------------------------------
    foreach $itseg ( 1 .. $all{"NROWS"} ){
	if (! $all{"$itseg"}) {
	    if    ( ($all{"$itseg","beg"} >= $Nlim) && ($all{"$itseg","beg"} <= $Clim) ) {
		--$nseg;
		$all{"$itseg"}=1;}
	    elsif ( ($all{"$itseg","end"} >= $Nlim) && ($all{"$itseg","end"} <= $Clim) ) {
		--$nseg;
		$all{"$itseg"}=1;}
	    elsif ( ($all{"$itseg","beg"} <= $Nlim) && ($all{"$itseg","end"} >= $Clim) ) {
		--$nseg;
		$all{"$itseg"}=1;}
	}}
    return($nseg);
}				# end of htmref_flip

#==========================================================================================
sub htmref_max {
    local ($Tgrid)= @_ ;
    local ($itseg,$max,$seg_max);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   htmref_max                  gets the segment with maximal score
#                               note: constraints (i.e. htm's taken already) @Ldone
#   GLOBAL (in/out)             $all{}
#--------------------------------------------------------------------------------
    $max=0;$seg_max=1;
				# maximal of all segments
    foreach $itseg ( 1 .. $all{"NROWS"} ){
#	if (! $Lexxx){
#	    printf "x.x %4d val=%4.2f len=%4d pos=%4d\n",$itseg,$all{"$itseg","val"},$all{"$itseg","len"},$all{"$itseg","beg"};}

	if (! $all{"$itseg"}) {
	    if     (int($Tgrid*$all{"$itseg","val"}) > $max ) { # > take
		$max=int($Tgrid*$all{"$itseg","val"});
		$len_max=$all{"$itseg","len"};
		$seg_max=$itseg; }
	    elsif ((int($Tgrid*$all{"$itseg","val"}) == $max ) &&
		   ($all{"$itseg","len"}>$len_max) ) { # =, longer one
		$max=int($Tgrid*$all{"$itseg","val"});
		$len_max=$all{"$itseg","len"};
		$seg_max=$itseg; }
	}}
#    $Lexxx=1;			# x.x
    return ($all{"$seg_max","val"},$seg_max);
}				# end of htmref_max

#==========================================================================
sub wrt_rdb_htmref {
    local ($fhout,$desvec,$sep_in,$nmax,$n2nd,$ri,$ri_diff) = @_ ;
    local (@des,@tmp,$Lnotation,$des,$sep,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   writes the RDB format written by PHD
#--------------------------------------------------------------------------------
    @des=split(/\t/,$desvec);
				# header
    @tmp=split(/\#/,$rd{"header"});
    $Lnotation=$Lok=0;
    foreach $_(@tmp){
	$Lok=1                  if ($_=~/Perl-RDB/);
	next if (! $Lok);
	if ($_=~/PHDhtm: prediction of helical transmembrane regions/){
	    $old="PHDhtm: prediction of helical transmembrane regions";
	    $new="PHDhtm_ref: refined prediction of transmembrane helices";
	    $_=~s/$old/$new/;}
	if (!$Lnotation && (/NOTATION/)){
				# avoid warnings (ri_diff and ri may be empty)
	    $ri=~s/[^0-9.]//g;$ri_diff=~s/[^0-9.]//g;$n2nd=~s/[^0-9.]//g;$nmax=~s/[^0-9.]//g;
	    $ri=0               if (length($ri)==0) ;
	    $ri_diff=0          if (length($ri_diff)==0);
	    printf $fhout 
		"# NHTM_BEST     : %6d (number of helices for best model)\n",$nmax;
	    printf $fhout 
		"# NHTM_2ND_BEST : %6d (number of helices for second best model)\n",$n2nd;
	    printf $fhout 
		"# REL_BEST      : %6.3f (reliability of best model =zscore)\n",$ri;
	    printf $fhout 
		"# REL_BEST_DIFF : %6.3f (reliability of best model =1st-2nd)\n",$ri_diff;
	    $tmp=$ri_diff;$tmp=int(100*$tmp);if ($tmp>9){$tmp=9;}
	    printf $fhout 
		"# REL_BEST_DPROJ: %6d (reliability of best model projection of (1st-2nd))\n",$tmp;
	    print $fhout "#\n";
	    print $fhout "# MODEL         : iteratively adding transmembrane helices (HTM's)\n";
	    printf $fhout 
		"# MODEL         : %-10s , %-12s , %-10s ,%5s - %5s\n",
		"N HTM","Total Score","Best HTM","C","N";
	    $ct=1;
	    while(defined $res_model{"score",$ct}){
		printf $fhout 
		    "# MODEL_DAT     : %-10d , %-12.4f , %-10.4f ,%5d - %5d\n",
		    $ct,$res_model{"score",$ct},$res_model{"max",$ct},
		    $res_model{"Ncap",$ct},$res_model{"Ccap",$ct};
		++$ct;}
	    print $fhout "#\n";
	    $Lnotation=1;}
	if ($Lnotation) {
	    if (/\w+/){ 
		print $fhout "#",$_; }
	    else      { 
		$Lnotation=0;
		print $fhout "# NOTATION PRHL : refined prediction (maximum score model)\n";
		print $fhout 
		    "# NOTATION PR2HL: refined prediction (second best maximum score model)\n";
		print $fhout "#",$_;}}
	else {
	    $_=~s/RI_S/RI_H/g if ($_=~ /RI_S/); # correct
	    print $fhout "#",$_;}}
				# ------------------------------
				# now names
    foreach $des(@des){
	if ($des eq $des[$#des]){$sep="\n";}else {$sep="$sep_in";}
	$tmp=$rd{$des,"format"};$tmp=~s/(.*\d+)\D.*/$1s/;
	foreach $key (keys %des_trsl){
	    if ($des eq $key){$des=$des_trsl{"$key"};
			      last;}}
	print $fhout "$des$sep";}
#	printf $fhout "%-$tmp$sep",$des;}
				# now format
    foreach $des(@des){
	if ($des eq $des[$#des]){$sep="\n";}else {$sep="$sep_in";}
	$tmp=$rd{$des,"format"};$tmp=~s/(.*\d+)\D.*/$1s/;
				# '1' -> '1S'
	$rd{$des,"format"}.="S" if ($rd{$des,"format"}!~/[A-Z]/);
#	printf $fhout "%-$tmp$sep",$rd{$des,"format"};}
	print $fhout $rd{$des,"format"},"$sep";}
				# ------------------------------
				# Now data
    foreach $itres (1..$rd{"NROWS"}){
	foreach $des(@des){
	    if ($des eq $des[$#des]){$sep="\n";}else {$sep="$sep_in";}
	    $tmp=&form_rdb2perl($rd{$des,"format"});
	    $tmpWrt=" "                  if (! defined $rd{$des,$itres});
	    $tmpWrt=$rd{$des,$itres} if (defined $rd{$des,$itres});
	    $tmpWrt=~s/\s//g;
	    printf $fhout "$tmp$sep",$tmpWrt;}}
}				# end wrt_rdb_htmref


1;
