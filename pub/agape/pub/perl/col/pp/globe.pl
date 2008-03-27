#!/usr/pub/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="compiles the globularity for a PHD file\n";
#
$[ =1 ;
				# include libraries
push (@INC, "/home/phd/ut/perl") ;
require "ctime.pl"; require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
if (defined &ctime){
    @Date = split(' ',&ctime(time)) ; 
    $date="$Date[2] $Date[3], $Date[5]"; }
else {$date=`date`;}
    
				# ------------------------------
				# defaults
$par{"lenMin"}=      30;	$par{"expl","lenMin"}=  "minimal length of proteins considered";
$par{"exposed"}=     16;	$par{"expl","exposed"}= "if rel Acc > will be considered exposed";
$par{"isPred"}=       1;	$par{"expl","isPred"}=  "file without observed columns";

				# fit: (N- $fit2Fac*(N^1/3-$fit2Add)^3) 
$par{"fit2Ave"}=      1.4;	$par{"expl","fit2Ave"}=  "average of fit for data base";
$par{"fit2Sig"}=      9.9;	$par{"expl","fit2Sig"}=  "1 sigma of fit for data base";
$par{"fit2Add"}=      0.78;     $par{"expl","fit2Add"}=  "add of fit= 'N - fac*(N1/3-add)^3";
$par{"fit2Fac"}=      0.84;	$par{"expl","fit2Fac"}=  "fac of fit= 'N - fac*(N1/3-add)^3";

$par{"fit2Ave100"}=   0.1;
$par{"fit2Sig100"}=   6.2;
$par{"fit2Add100"}=   0.41;
$par{"fit2Fac100"}=   0.64;
$par{"doFixPar"}=     0;	$par{"expl","doFixPar"}= "do NOT change the fit para if length<100";
$par{"doReturn"}=     0;	# return output on screen (len,nexp,nfit,diff,explanation)
$par{"verbose"}=      0;	# write comments asf onto screen

@par=("lenMin","exposed","isPred","doFixPar",
      "fit2Ave",   "fit2Sig",   "fit2Add",   "fit2Fac",
      "fit2Ave100","fit2Sig100","fit2Add100","fit2Fac100");
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName filePHDrdb' (or many *)\n";
    print "opt: \t fix      (if not set short proteins treated by statistics on < 100 res)\n";
    print "     \t verbose  (will write onto screen)\n";
    print "     \t return   (will return output on screen:\n";
    print "                     'len,nexp,nfit,diff,explanation')\n";
    print "     \t fileOut=x\n";
    foreach $kwd(@par){
	print "     \t $kwd=",$par{"$kwd"},"\n";}
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$#fileIn=0;
$fileOut="Out-".$scrName;

foreach $_(@ARGV){
    $Lok=0;
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;$Lok=1;}
    elsif($_=~/^isPred/)       {$par{"isPred"}=  1;$Lok=1;}
    elsif($_=~/^fix/)          {$par{"doFixPar"}=1;$Lok=1;}
    elsif($_=~/^verbose/)      {$par{"verbose"}= 1;$Lok=1;}
    elsif($_=~/^[r]eturn/)     {$par{"doReturn"}=1;$Lok=1;}
    foreach $kwd (@par){
	if ($_=~/^$kwd=(.*)$/) {$par{"$kwd"}=$1;$Lok=1;}}
    if (! $Lok && -e $_){
	push(@fileIn,$_); $Lok=1;}
    if (! $Lok){
	print"*** wrong command line arg '$_'\n";
	die;}}

die ("missing input $fileIn[1]\n") if (! -e $fileIn[1]);
$exposed=$par{"exposed"};
				# ------------------------------
$#id=0;undef %res;		# (1) read files
foreach $fileIn(@fileIn){
    if (! -e $fileIn ){
	print "-*- WARN $scrName ($fileIn) not existing\n";
	next;}
    &open_file("$fhin", "$fileIn");
    print "--- $scrName reading $fileIn\n" if ($par{"verbose"});
    $id=$fileIn;$id=~s/^.*\///g;$id=~s/\.[^\.]+rdb.*$//ig;
    $ctTmp=$Lboth=$Lsec=$len=$numExposed=0;
    while (<$fhin>) {
	++$ctTmp;
	if ($_=~/^\# LENGTH\s+\:\s*(\d+)/){
	    $lenRd=$1;}
	if ($ctTmp<3){if    ($_=~/^\# PHDsec\+PHDacc/){$Lboth=1;}
		      elsif ($_=~/^\# PHDacc/)        {$Lboth=0;}
		      elsif ($_=~/^\# PHDsec/)        {$Lsec=1;}}
				# ******************************
	last if ($Lsec);	# ERROR is not PHDacc, at all!!!
				# ******************************
	next if ($_=~/^\#|^No|^4N/); # skip comments and first line
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);	# $id,$chain,$len,$nali,$seq,$sec,$acc,$rel
	if ($#tmp<6){
	    print "*** ERROR too few elements in id=$id, line=$_\n";
	    exit;}
	foreach $tmp(@tmp){$tmp=~s/\s//g;} # skip blanks
	if    ($Lboth){		# PHDsec+acc
	    $pos=9; $pos=12 if (! $par{"isPred"});} # correct for pred+obs
	else          {		# PHDacc
	    $pos=4; $pos=6  if (! $par{"isPred"});} # correct for pred+obs
	$rel=$tmp[$pos];
	if ($rel =~/[^0-9]/){	# xx hack out, somewhere error
	    print "*** error rel=$rel, ";
	    if ($par{"isPred"}){print "isPred ";}else{print "isPrd+Obs ";}
	    if ($Lboth)        {print "isBoth ";}else{print "isPHDacc ";}
	    print "line=$_,\n";
	    exit;}
	++$len;
	++$numExposed if ($rel>=$exposed);
    }close($fhin);
    if (defined $len && defined $numExposed){
	push(@id,$id);
	$res{"$id","lenRd"}=     $lenRd;
	$res{"$id","len"}=       $len;
	$res{"$id","numExposed"}=$numExposed;}
}				# end of loop over all files
$#tmp=0;
				# ------------------------------
				# get the expected number of res
foreach $id (@id){
    if (! $par{"doFixPar"} && ($res{"$id","len"} < 100)){
	$fit2Add=$par{"fit2Add100"};$fit2Fac=$par{"fit2Fac100"};}
    else {
	$fit2Add=$par{"fit2Add"};   $fit2Fac=$par{"fit2Fac"};}

    $res{"$id","numExpect"}=
	&funcNsurfacePhdFit2($res{"$id","len"},$fit2Add,$fit2Fac,$par{"exposed"});
}
				# ------------------------------
				# write output
if (! $par{"doReturn"}){
    $#fh=0;push(@fh,$fhout); push(@fh,"STDOUT") if ($par{"verbose"});

    foreach $fh (@fh){&open_file("$fhout",">$fileOut") if ($fh eq $fhout);
		      &globeWrt($fh);
		      close($fhout) if ($fh eq $fhout);}

    print "--- output in $fileOut\n" if (-e $fileOut && $par{"verbose"});}
				# ------------------------------
else {				# return results on screen
    $diff=$res{"$id[1]","numExposed"}-$res{"$id[1]","numExpect"};
    if    ($diff > 20){
	$evaluation="your protein may be globular, but it is not as compact as a domain";}
    elsif ($diff > (-5)){
	$evaluation="your protein appears as compact, as a globular domain";}
    elsif ($diff > (-10)){
	$evaluation="your protein appears not as globular, as a domain";}
    else {
	$evaluation="your protein appears not to be globular";}

    return($res{"$id[1]","len"},
	   $res{"$id[1]","numExposed"},$res{"$id[1]","numExpect"},$diff,$evaluation);}
exit;

#===============================================================================
sub funcNsurfacePhdFit2 {
    local($lenIn,$add,$fac,$expLoc) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcNsurfacePhdFit2_16      length to number of surface molecules
#                               fitted to PHD error 
#                               out=(N ^ 1/3 - 2) ^ 3
#       in:                     len, acc-cut-off (allowed: 9, 16)
#       out:                    NsurfacePhdFit2
#-------------------------------------------------------------------------------
    $expLoc=16 if (! defined $expLoc); # default
    if   ($expLoc == 9) {
	return($lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    elsif($expLoc == 16) {
	return($lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    else{ print "*** ERROR in $scrName funcNsurfacePhdFit2 only defined for exp=16 or 9\n";
	  die;}
}				# end of funcNsurfacePhdFit2

#===============================================================================
sub globeWrt {
    local($fhoutTmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeWrt                    writes output for GLOBE
#       in:                     FILEHANDLE to print
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globeWrt";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    print $fhoutTmp
	"# Perl-RDB generated by:$scrName on:$date\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORMAT   begin\n",
	"# FORMAT   general:    - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORMAT   general:    - columns are delimited by tabs\n",
	"# FORMAT   parameters: '# PARA:tab     keyword =tab value tab (further-information)'\n",
	"# FORMAT   notation:   '# NOTATION:tab keyword tab explanation'\n",
	"# FORMAT   info:       '# INFO:tab     text'\n",
	"# FORMAT   blocks 0:   '# BLOCK        keyword'\n",
	"# FORMAT   blocks 1:    column names (tab delimited)\n",
	"# FORMAT   blocks n>1:  column data  (tab delimited)\n",
	"# FORMAT   file end:   '//' is the end of a complete file\n",
	"# FORMAT   end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# write parameters
    print $fhoutTmp
	"# PARA     begin\n",
	"# PARA     $scrName HEADER: PARAMETERS\n";
    foreach $des (@par){
	$expl="";$expl=$par{"expl","$des"} if (defined $par{"expl","$des"});
	next if ($des eq "doFixPar" && (! $par{"doFixPar"}));
	printf $fhoutTmp 
	    "# PARA:\t%-10s =\t%-6s\t%-s\n",$des,$par{"$des"},$expl;}
    print $fhoutTmp
	"# PARA     end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# explanations
    print $fhoutTmp
	"# NOTATION begin\n",
	"# NOTATION HEADER: ABBREVIATIONS COLUMN NAMES\n";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","id",        "protein identifier";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","len",       "length of protein";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","nExposed",  "number of predicted exposed residues (PHDacc)";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","nExpect",   "number of expected exposed res";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","diff",      "nExposed - nExpect";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","evaluation",
	"comment about globularity predicted for your protein";
    print $fhoutTmp
	"# NOTATION end\n",
	"# --------------------------------------------------------------------------------\n";
				# column names
    printf $fhoutTmp 
	"%-s\t%8s\t%8s\t%8s\t%8s\t%-s\n",
	"id","len","nExposed","nExpect","diff","evaluation";

				# data
    foreach $id (@id){
	$diff=$res{"$id","numExposed"}-$res{"$id","numExpect"};
	if    ($diff > 20){
	    $evaluation="your protein may be globular, but it is not as compact as a domain";}
	elsif ($diff > (-5)){
	    $evaluation="your protein appears as compact, as a globular domain";}
	elsif ($diff > (-10)){
	    $evaluation="your protein appears not as globular, as a domain";}
	else {
	    $evaluation="your protein appears not to be globular";}
	printf $fhoutTmp 
	    "%-s\t%8d\t%8d\t%8.2f\t%8.2f\t%-s\n",
	    $id,$res{"$id","len"},$res{"$id","numExposed"},$res{"$id","numExpect"},
	    $diff,$evaluation;}
}				# end of globeWrt

