#!/usr/local/bin/perl
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="writes the TOPITS format from: .hssp + .strip \n";
#
$[ =1 ;
				# --------------------------------------------------
				# initialise variables, process command line
&ini;

$par{"mix"}="unk" if (! defined $par{"mix"});

&topitsWrtOwnHere($fileHssp,$fileStrip,$fileOut,$par{"mix"},"STDOUT");

print "--- output in $fileOut\n";
exit;

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         initialise subroutine
#       in GLOBAL:              all
#       out GLOBAL:             all
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."ini";$fhinLoc="FHIN"."$sbrName";

				# include libraries
    push (@INC, "//home/$ENV{USER}/server/pub/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
    require "ctime.pl";
    require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
    $par{"extHssp"}= "hsspTopits"; # expected extension of TOPITS HSSP file
    $par{"extStrip"}="stripTopits";	# expected extension of TOPITS STRIP file
    $par{"extOut"}=  "topits";	# default output extension
				# ------------------------------
    if ($#ARGV<1){		# help
	print "goal:\t $scrGoal\n";
	print "use: \t '$scrName file.hsspTopits file.stripTopits' (or id -> id.hsspTopits ..)\n";
	print "opt: \t extHssp =",$par{"extHssp"},"  (id.'ext' searched)\n";
	print "     \t extStrip=",$par{"extStrip"}," (id.'ext' searched)\n";
	print "     \t extOut  =",$par{"extOut"},"   (id.'ext' written)\n";
	print "     \t dirHssp =",$par{"dirInHssp"}," ('dir'/id.ext searched, def = local)\n";
	print "     \t dirStrip=",$par{"dirInStrip"},"  ('dir'/id.ext searched, def = local)\n";
	print "     \t fileOut =x\n";
	print "     \t mix     =",$par{"mix"}," (ratio str:seq used for TOPITS not in file!!!)\n";
	print "NOTE:\t the option 'mix' must given if the respective information ought to appear\n";
	exit;}
				# initialise variables
#    $fhin="FHIN";$fhout="FHOUT";
    $#fileIn=0;
				# read command line
    $idIn=$ARGV[1]; push(@fileIn,$idIn) if (-e $idIn);

    foreach $_(@ARGV){
	next if ($_ eq $ARGV[1]);
	if   ($_=~/^fileOut=(.*)$/) {$fileOut=$1;}
	elsif($_=~/^extHssp=(.*)$/) {$par{"extHssp"}= $1;}
	elsif($_=~/^extStrip=(.*)$/){$par{"extStrip"}=$1;}
	elsif($_=~/^extOut=(.*)$/)  {$par{"extOut"}=  $1;}
	elsif($_=~/^dirHssp=(.*)$/) {$par{"dirHssp"}= &complete_dir($1);}
	elsif($_=~/^dirStrip=(.*)$/){$par{"dirStrip"}=&complete_dir($1);}
	elsif($_=~/^mix=(.*)$/)     {$par{"mix"}=     $1;}
#    elsif($_=~/^=(.*)$/){$par{""}=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
	elsif(-e $_)                {push(@fileIn,$_);}
	else {print"*** wrong command line arg '$_'\n";
	      die;}}
				# ------------------------------
				# (1) find input files
    if ($#fileIn==0){		# id on command line -> compose
	$fileHssp= $par{"dirHssp"} .$idIn.".".$par{"extHssp"};
	$fileStrip=$par{"dirStrip"}.$idIn.".".$par{"extStrip"};
	if (! -e $fileHssp) {print "*** $scrName no TOPITS.hssp file '$fileHssp'\n";
			     exit;}
	if (! -e $fileStrip){print "*** $scrName no TOPITS.strip file '$fileStrip'\n";
			     exit;}}
    else {			# files given on command line
				# --------------------
				# more than one file given?
	if ($#fileIn<2)     {print "*** $scrName either you give correct id on the command line\n";
			     print "***          or BOTH topits.hssp AND topits.strip as args\n";
			     exit;}
				# --------------------
				# check existence
	foreach $file(@fileIn){
	    if (! -e $file) {print "*** $scrName no input file '$file'\n";
			     exit;}}
				# --------------------
				# sort out which is which
	if (&is_hssp($fileIn[1])){$fileHssp= $fileIn[1];
				  $fileStrip=$fileIn[2];}
	else                     {$fileHssp= $fileIn[2];
				  $fileStrip=$fileIn[1];}}
				# ------------------------------
				# determine name of output file
    if (! defined $fileOut){
	$fileOut=$fileHssp;$fileOut=~s/^.*\///g;$fileOut=~s/$par{"extHssp"}/$par{"extOut"}/g;
	$fileOut=~s/\.hssp.*$/\.topits/g if ($fileOut eq $fileHssp); # security hack
    }
}				# end of ini

#===============================================================================
sub topitsWrtOwnHere {
    local($fileHsspLoc,$fileStripLoc,$fileOutLoc,$mix,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok,$txt,$kwd,$it,$wrtTmp,$wrtTmp2,
	  %rdHdr,@kwdLoc,@kwdOutTop2,@kwdOutSummary2,%wrtLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtOwnHere          writes the TOPITS format
#       in:                     $fileHsspLoc,$fileStripLoc,$fileOutLoc,$mix,$fhErrSbr
#       out:                    file written ($fileOutLoc)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."topitsWrtOwnHere";
    $fhinLoc= "FHIN". "$sbrName";
    $fhoutLoc="FHOUT"."$sbrName";
    $sep="\t";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileHsspLoc!")          if (! defined $fileHsspLoc);
    return(0,"*** $sbrName: not def fileStripLoc!")         if (! defined $fileStripLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")           if (! defined $fileOutLoc);
    $fhErrSbr="STDOUT"                                      if (! defined $fhErrSbr);
    return(0,"*** $sbrName: miss in file '$fileHsspLoc'!")  if (! -e $fileHsspLoc);
    return(0,"*** $sbrName: miss in file '$fileStripLoc'!") if (! -e $fileStripLoc);
    @kwdOutTop2=
	("len1","nali","listName","sortMode","weight1","weight2",
	 "smin","smax","gapOpen","gapElon","indel1","indel2","threshold");
    @kwdOutSummary2=
	("id2","pide","lali","ngap","lgap","len2",
	 "Eali","Zali","strh","ifir","ilas","jfir","jlas","name");
				# ------------------------------
				# set up keywords
    @kwdLoc=
	 (
	  "hsspTop",   "threshold","len1",
	  "hsspPair",  "id2","pdbid2","pide","ifir","ilas","jfir","jlas",
	               "lali","ngap","lgap","len2",
	  "stripTop",  "nali","listName","sortMode","weight1","weight2",
	               "smin","smax","gapOpen","gapElon","indel1","indel2",
	  "stripPair", "energy","zscore","strh","name");

    $des_expl{"mix"}=      "weight structure:sequence";
    $des_expl{"nali"}=     "number of alignments in file";
    $des_expl{"listName"}= "fold library used for threading";
    $des_expl{"sortMode"}= "mode of ranking the hits";
    $des_expl{"weight1"}=  "YES if guide sequence weighted by residue conservation";
    $des_expl{"weight2"}=  "YES if aligned sequence weighted by residue conservation";
    $des_expl{"smin"}=     "minimal value of alignment metric";
    $des_expl{"smax"}=     "maximal value of alignment metric";
    $des_expl{"gapOpen"}=  "gap open penalty";
    $des_expl{"gapElon"}=  "gap elongation penalty";
    $des_expl{"indel1"}=   "YES if insertions in sec str regions allowed for guide seq";
    $des_expl{"indel2"}=   "YES if insertions in sec str regions allowed for aligned seq";
    $des_expl{"len1"}=     "length of search sequence, i.e., your protein";
    $des_expl{"threshold"}="hits above this threshold included (ALL means no threshold)";

    $des_expl{"rank"}=     "rank in alignment list, sorted according to sortMode";
    $des_expl{"Eali"}=     "alignment score";
    $des_expl{"Zali"}=     "alignment zcore;  note: hits with z>3 more reliable";
    $des_expl{"strh"}=     "secondary str identity between guide and aligned protein";
    $des_expl{"pide"}=     "percentage of pairwise sequence identity";
    $des_expl{"lali"}=     "length of alignment";
    $des_expl{"lgap"}=     "number of residues inserted";
    $des_expl{"ngap"}=     "number of insertions";
    $des_expl{"len2"}=     "length of aligned protein structure";
    $des_expl{"id2"}=      "PDB identifier of aligned structure (1pdbC -> C = chain id)";
    $des_expl{"name"}=     "name of aligned protein structure";
    $des_expl{"ifir"}=     "position of first residue of search sequence";
    $des_expl{"ilas"}=     "position of last residue of search sequence";
    $des_expl{"jfir"}=     "pos of first res of remote homologue (e.g. DSSP number)";
    $des_expl{"jlas"}=     "pos of last res of remote homologue  (e.g. DSSP number)";
    $des_expl{""}=    "";

				# ------------------------------
    undef %rdHdr;		# read HSSP + STRIP header

    ($Lok,$txt,%rdHdr)=
	  &hsspRdStripAndHeader($fileHsspLoc,$fileStripLoc,$fhErrSbr,@kwdLoc);
    return(0,"$sbrName: returned 0\n$txt\n") if (! $Lok);
				# ------------------------------
				# write output in TOPITS format
    $Lok=&open_file("$fhoutLoc",">$fileOutLoc"); 
    return(0,"$sbrName: couldnt open new file $fileOut") if (! $Lok);
				# corrections
    $rdHdr{"threshold"}=~s/according to\s*\:\s*//g if (defined $rdHdr{"threshold"});
    foreach $it (1..$rdHdr{"NROWS"}){
	$rdHdr{"Eali","$it"}=$rdHdr{"energy","$it"} if (defined $rdHdr{"energy","$it"});
	$rdHdr{"Zali","$it"}=$rdHdr{"zscore","$it"} if (defined $rdHdr{"zscore","$it"});
    }
#    $rdHdr{"name","$it"}=$rdHdr{"zscore","$it"} if (defined $rdHdr{"zscore","$it"});
				# ------------------------------
    $wrtTmp=$wrtTmp2="";	# build up for communication with subroutine
    undef %wrtLoc;
    foreach $kwd(@kwdOutTop2){
	$wrtLoc{"$kwd"}=       $rdHdr{"$kwd"};
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp.="$kwd,";}
    if (defined $mix && $mix ne "unk" && length($mix)>1){
	$kwd="mix";
	$wrtLoc{"$kwd"}=       $mix;
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp.="$kwd,";}
    foreach $kwd(@kwdOutSummary2){
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp2.="$kwd,";}
				# ------------------------------
				# write header
    ($Lok,$txt)=
	&topitsWrtOwnHereHdr($fhoutLoc,$wrtTmp,$wrtTmp2,%wrtLoc);
    undef %wrtLoc;
				# ------------------------------
				# write names of first block
    print $fhoutLoc 
	"# BLOCK    TOPITS HEADER: SUMMARY\n";
    printf $fhoutLoc "%-s","rank";
    foreach $kwd(@kwdOutSummary2){
#	$sepTmp="\n" if ($kwd eq $kwdOutTop2[$#kwdOutTop2]);
	printf $fhoutLoc "$sep%-s",$kwd;}
    print $fhoutLoc "\n";
				# ------------------------------
				# write first block of data
    foreach $it (1..$rdHdr{"NROWS"}){
	printf $fhoutLoc "%-s",$it;
	foreach $kwd(@kwdOutSummary2){
	    printf $fhoutLoc "$sep%-s",$rdHdr{"$kwd","$it"};}
	print $fhoutLoc "\n";
    }
				# ------------------------------
				# next block (ali)
#    print $fhoutLoc
#	"# --------------------------------------------------------------------------------\n",
#	;
				# ------------------------------
				# correct file end
    print $fhoutLoc "//\n";
    close($fhoutLoc);
    undef %rdHdr;		# read HSSP + STRIP header
    return(1,"ok $sbrName");
}				# end of topitsWrtOwnHere

#===============================================================================
sub topitsWrtOwnHereHdr {
    local($fhoutTmp,$desLoc,$desLoc2,%wrtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtOwnHereHdr             writes the HEADER for the TOPITS specific format
#       in:                     FHOUT,"kwd1,kwd2,kwd3",%wrtLoc
#                               $wrtLoc{"$kwd"}=result of paramter
#                               $wrtLoc{"expl$kwd"}=explanation of paramter
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName="$tmp"."topitsWrtOwnHereHdr";
				# ------------------------------
				# keywords to write
    $desLoc=~s/^,*|,*$//g;      $desLoc2=~s/^,*|,*$//g;
    @kwdHdr=split(/,/,$desLoc); @kwdCol=split(/,/,$desLoc2);
    
				# ------------------------------
				# begin
    print $fhoutTmp
	"# TOPITS (Threading One-D Predictions Into Three-D Structures)\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORMAT   begin\n",
	"# FORMAT   general:    - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORMAT   general:    - columns are delimited by tabs\n",
	"# FORMAT   general:    - the data are given in BLOCKS, each introduced by a line\n",
	"# FORMAT   general:      beginning with a hash and a keyword\n",
	"# FORMAT   parameters: '# PARA:tab     keyword =tab value tab (further-information)'\n",
	"# FORMAT   notation:   '# NOTATION:tab keyword tab explanation'\n",
	"# FORMAT   info:       '# INFO:tab     text'\n",
	"# FORMAT   blocks 0:   '# BLOCK        keyword'\n",
	"# FORMAT   blocks 1:    column names (tab delimited)\n",
	"# FORMAT   blocks n>1:  column data  (tab delimited)\n",
	"# FORMAT   file end:   '//' is the end of a complete file\n",
	"# FORMAT   end\n",
	"# --------------------------------------------------------------------------------\n",
	;
				# ------------------------------
				# write parameters
    print $fhoutTmp
	"# PARA     begin\n",
	"# PARA     TOPITS HEADER: PARAMETERS\n";
    foreach $des (@kwdHdr){
	next if (! defined $wrtLoc{"$des"});
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$wrtLoc{"$des"}=~s/\s//g; # purge blanks
	if ($des eq "mix"){
	    $mix=~s/\D//g;
	    printf $fhoutTmp 
		"# PARA:\t%-10s =\t%-6d\t(i.e. str=%3d%1s, seq=%3d%1s)\n",
		"str:seq",int($mix),int($mix),"%",int(100-$mix),"%";}
	else {
	    printf $fhoutTmp 
		"# PARA:\t%-10s =\t%-6s\n",$des,$wrtLoc{"$des"};}}
    print $fhoutTmp
	"# PARA     end\n",
	"# --------------------------------------------------------------------------------\n",
	;
				# ------------------------------
				# explanations
    print $fhoutTmp
	"# NOTATION begin\n",
	"# NOTATION TOPITS HEADER: ABBREVIATIONS PARAMETERS\n";
    foreach $des (@kwdHdr){
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$tmp=length($wrtLoc{"expl"."$des"});$tmp.="s";
	$des2=$des;  # $des2=~tr/[a-z]/[A-Z]/;
	$des2="str:seq" if ($des2 eq "mix");
	printf $fhoutTmp "# NOTATION:\t%-12s:\t%-$tmp\n",$des2,$tmp1;}
    print $fhoutTmp
	"# NOTATION TOPITS HEADER: ABBREVIATIONS SUMMARY\n";
    foreach $des (@kwdCol){
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$tmp=length($wrtLoc{"expl"."$des"});$tmp.="s";
	$des2=$des;  # $des2=~tr/[a-z]/[A-Z]/;
	printf $fhoutTmp "# NOTATION:\t%-12s:\t%-$tmp\n",$des2,$tmp1;}
	
    print $fhoutTmp
	"# NOTATION end\n",
	"# --------------------------------------------------------------------------------\n",
	;
				# ------------------------------
				# information about method
    print $fhoutTmp 
	"# INFO     begin\n",
	"# INFO     TOPITS HEADER: ACCURACY\n",
	"# INFO:\t Tested on 80 proteins, TOPITS found the correct remote homologue in about\n",
	"# INFO:\t 30%of the cases.  Detection accuracy was higher for higher z-scores:\n",
	"# INFO:\t ZALI>0   => 1st hit correct in 33% of cases\n",
	"# INFO:\t ZALI>3   => 1st hit correct in 50% of cases\n",
	"# INFO:\t ZALI>3.5 => 1st hit correct in 60% of cases\n",
	"# INFO     end\n",
	"# --------------------------------------------------------------------------------\n",
	;
}				# end of topitsWrtOwnHereHdr

#===============================================================================
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
sub topitsWrtOwnHereAliInfo {
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#   topitsWrtOwnHereAliInfo         not used at moment!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#                               c
#       in:                     
#         $fhoutLoc             file handle print output
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."topitsWrtOwnHereAliInfo";$fhinLoc="FHIN"."$sbrName";

    print $fhout "--- TOPITS ALIGNMENTS HEADER: SUMMARY\n";
    printf $fhout " %4s ","RANK"; # descriptor
#    foreach $des (@des){
#	$tmp=$ptr_form_txt{"$des"};
#	$tmp2=$des;$tmp2=~tr/[a-z]/[A-Z]/;
#	printf $fhout "%$tmp ",$tmp2;
#    }print $fhout "\n";
    # data
#    foreach $it(1..$ntaken){
#	printf $fhout " %4d ",$it;
#	foreach $des (@des){
#	    $tmp=$ptr_form{"$des"};
#	    printf $fhout "%$tmp ",$rds{"$des","$it"};
#	}print $fhout "\n";
#    }
    print $fhout "--- \n";
    print $fhout "--- TOPITS ALIGNMENTS: SYMBOLS AND EXPLANATIONS\n";
    printf $fhout "--- %-12s : %-s\n","BLOCK 1","your protein and its predicted 1D structure,";
    printf $fhout "--- %-12s : %-s\n","","i.e., secondary structure and solvent accessibility";
    printf $fhout "--- %-12s : %-s\n","line 1","amino acid sequence (one-letter-code)";
    printf $fhout "--- %-12s : %-s\n","line 2","predicted secondary structure:";
    printf $fhout "--- %-12s : %-s\n","H","helix";
    printf $fhout "--- %-12s : %-s\n","E","strand (extended)";
    printf $fhout "--- %-12s : %-s\n","L","other (no regular secondary structure)";
    printf $fhout "--- %-12s : %-s\n","line 3","predicted residue relative solvent accessibility";
    printf $fhout "--- %-12s : %-s\n","B","buried, i.e., relative accessibility < 15%";
    printf $fhout "--- %-12s : %-s\n","O","exposed (outside), i.e., relative accessibility >= 15%";
    printf $fhout "--- %-12s : %-s\n","","";
    printf $fhout "--- %-12s : %-s\n","BLOCKS 1-20","20 best hits of the prediction-based threading ";
    printf $fhout "--- %-12s : %-s\n","   ATTENTION","We chose to include all first 20 hit.  However,";
    printf $fhout "--- %-12s : %-s\n","   ATTENTION","most of them will not constitute true remote";
    printf $fhout "--- %-12s : %-s\n","   ATTENTION","homologues.  Instead, all hits with a zscore ";
    printf $fhout "--- %-12s : %-s\n","   ATTENTION","(ZALI) < 3.5 are, at best, rather speculative!";
    printf $fhout "--- %-12s : %-s\n","","for each aligned protein:";
    printf $fhout "--- %-12s : %-s\n","line 1","amino acids conserved between guide (yours) and the";
    printf $fhout "--- %-12s : %-s\n","","aligned protein (putative homologue)";
    printf $fhout "--- %-12s : %-s\n","line 1","sequence of aligned protein";
    printf $fhout "--- %-12s : %-s\n","line 3","secondary structure, taken from DSSP (assignment";
    printf $fhout "--- %-12s : %-s\n","","of secondary structure based on experimental coordinates)";
    printf $fhout "--- %-12s : %-s\n","line 4","relative solvent accessibility, taken from DSSP";
    print $fhout "--- \n";
    print $fhout "--- TOPITS ALIGNMENTS\n";
#    foreach $line (@strip) {
#	print $fhout $line;
#    }
    print $fhout "--- \n";
    print $fhout "--- TOPITS ALIGNMENTS END\n";
    print $fhout "--- \n";
    
}				# end of topitsWrtOwnHereAliInfo

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         $fhoutLoc             file handle print output
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print $fhErrSbr "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);

}				# end of subx

