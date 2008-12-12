#!/usr/sbin/perl -w
#
# statistics on file blast.blastOut (generated by hack-runANDextrBlast.pl)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# defaults

$fhin="FHIN";$fhout="FHOUT";$Lverb= 1;

$gridLali=      10;		# i.e. take int(len/2)=len/2
$gridLali=       5;		# i.e. take int(len/2)=len/2

@gridProb=(    "5",   "5",   "3",   "2",  "1",  "0.2", "0.1", "0.01",     "0.001");
@gridFlip=("-2000","-300","-100", "-50","-10", "-4"  , "0"  , "2",    "20000");

@gridProb=(   "10",   "5",   "2",   "1",    "0.5", "0.2", "0.2",    "0.2");
@gridFlip=("-2000","-100", "-50", "-10",   "-4"  , "0"  , "2",    "20000");

@gridProb=(   "2",   "2",    "1",  "0.5",   "0.2", "0.2",    "0.2");
@gridFlip=("-2000","-50",  "-10",   "-4"  , "0"  , "2",    "20000");

@gridProb=(   "10",   "5",   "2",   "1",    "1",  "0.5","0.2","0.1","0.1", "0.1");
@gridFlip=("-2000","-100", "-50", "-10",   "-4",  "0",  "1",  "2",  "10",  "100");
				# initialise variables
if ($#ARGV<2){print"goal:   stat on statHisProb/Score (generated by blastHeaderRdb2stat)\n";
	      print"usage:  script score statHisS-split*.dat    (i.e. many files)\n";
	      print"  xor:  script prob statHisP-split*.dat    (i.e. many files)\n";
	      print"  xor:  script det  detF/T-split*.dat      (i.e. many files T or F)\n";
	      print"           i.e. on Prob, Score, or det \n";
	      print"option: fileOut=\n";
	      print"        name=xx    (will append xx to each column)\n";
	      exit;}
$#fileIn=0;
foreach $_ (@ARGV){
    if   (/^[vV]erb/)     {$Lverb=0;}
    elsif(/^verbose/)     {$Lverb=1;}
    elsif(/^fileOut=(.*)/){$fileOut=$1;}
    elsif(/^score$/)      {$mode="score";}
    elsif(/^prob$/)       {$mode="prob";}
    elsif(/^det$/)        {$mode="det";}
    elsif(/^name=(.*)/)   {$name=$1;}
    elsif(-e $_)          {push(@fileIn,$_);}
    else {print "*** ARGUMENT '$_' not understood\n";
	  die;}}
$fileName=$fileIn[1];$fileName=~s/^.*\///g;
if (! defined $mode){
    print "*** 2nd argument must be score|prob|det\n";
    die;}
if ($#fileIn<1){
    print "*** you have to provide some existing file!\n";
    die;}

$Lprob=$Lscore=$Ldet=0;
if   ($mode eq "prob") {$Lprob=1;}
elsif($mode eq "score"){$Lscore=1;}
elsif($mode eq "det")  {$Ldet=1;}

if (! defined $fileOut){
    $fileOut=$fileName; 
    if ($Ldet){
	$fileOut=~s/spl\d+/merge/g; $fileOut=~s/det/lali/g;}
    else {
	if (defined $name){
	    $tmp=substr($mode,1,1);$tmp=~tr/[a-z]/[A-Z]/;
	    $fileOut="his".$tmp."-".$name."-849.dat";}
	else {
	    $fileOut=~s/spl\d+/merge/g;}}}
if ($fileOut eq $fileIn[1]){
    $fileOut="merge-".$fileIn[1];}

				# --------------------------------------------------
				# speed up through lookup table
#for($r=-2000;$r<=2000;$r+=0.01){
#    ($tmp,$fac)=&project2grid($r);$grid=$tmp*$fac;$table{"$r"}=$grid;}
 
				# --------------------------------------------------
undef %res;			# now read files
$#score=0;$ctx=0;
foreach $fileIn(@fileIn){
    &open_file("$fhin", "$fileIn"); # external lib-ut.pl
    $ct1=&rdFile;
    close($fhin);
    $ctx+=$ct1;
}
				# ------------------------------
				# security check for det
$ctLineFile=$ctx;
if ($Ldet){
    $ct=0;
    foreach $tmp(@score){
#	print "xx score=$tmp, -> len=",$res{"$tmp"},"\n";
	$res{"$tmp"}=~s/,*$//g;
	@len=split(/,/,$res{"$tmp"});
	foreach $len(@len){
	    next if ((length($len)<1)||($len =~ /\D/));
	    $kwd="$tmp".","."$len";
	    if (! defined $res{"$kwd"}){
		print "xx undefined for $kwd\n";}
	    $ct+=$res{"$kwd"};
#	    print "    =",$gridLali*$len," nocc=",$res{"$kwd"},"\n";
	}
    }
    $ctOcc=$ct;}
				# ------------------------------
				# do histogram
&open_file("$fhout", ">$fileOut");
				# sort
if    ($Lscore){@scoreS=sort bynumber_high2low (@score);}
elsif ($Lprob) {@scoreS=sort bynumber (@score);}
elsif ($Ldet)  {@scoreS=sort bynumber (@score);}

if (! defined $name){$name=" ";}
if ($Lscore || $Lprob){
    &wrtHis("STDOUT",$mode,$name,@scoreS);
    &wrtHis("$fhout",$mode,$name,@scoreS);
}else{
    &wrtDet("STDOUT",$mode,@scoreS);
    &wrtDet("$fhout",$mode,@scoreS);
}

close($fhout);

print "--- security: lines read=$ctLineFile, Nocc (claimed)=$ctOcc\n" if ($Ldet);
print "--- output in $fileOut\n";
exit;

#===============================================================================
sub rdFile{
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdFile                      reads one file
#-------------------------------------------------------------------------------
    $ctLine=0;		# security check
    print "---  reading: $fileIn\n";
    while(<$fhin>){
	next if (/^\#|^prob|^score|^id/); # skip header
	$line=$_;$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
	@tmp=split(/\t/,$_);	# split by tabs
	if ((! $Ldet && ($#tmp<5)) || ($Ldet && ($#tmp<6))){
	    print "***  ERROR reading '$fileIn', not enough columns for:\n";
	    print "***  line=$line, now=$_,\n";
	    die;}
	foreach $tmp(@tmp){$tmp=~s/\s//g;} # purge spaces
				# ------------------------------
	if (! $Ldet){		# specific to HisS and HisP
	    foreach $tmp(@tmp){	# correct empty ones
		if (($tmp!~/\d/)&&(length($tmp)<1)){
		    $tmp=0;}}
	    $score=$tmp[1];	# note: here it is the lg(p)
	    
	    if ($Lprob){
		if    ($score<-50){$scoreNorm=10*int($score/10);}
		elsif ($score<-5) {$scoreNorm=5*int($score/5);}
		elsif ($score<-1) {$scoreNorm=int($score);}
		elsif ($score< 1) {$scoreNorm=int(10*$score)/10;}
		else            {$scoreNorm=int(100*$score)/100;}
#		($score,$fac)=&project2grid($score);
#		$score=$fac*$score;
	    }else{$scoreNorm=$score;}
	    if (! defined $res{"$scoreNorm"}){
		push(@score,$scoreNorm);$res{"$scoreNorm"}=1;
		$res{"$scoreNorm","Ntrue"}=$tmp[2];$res{"$scoreNorm","Nfalse"}=$tmp[3];}
	    else {
		$res{"$scoreNorm","Ntrue"}+= $tmp[2];
		$res{"$scoreNorm","Nfalse"}+=$tmp[3];}}
				# ------------------------------
	else {			# specific to det (id1 id2 pide lali blScore blProb)
	    $prob=$tmp[6];$lali=$tmp[4];
				# project to grid
	    $prob=&funcLog($prob,"10");	# lg
	    ($tmp,$fac)=&project2grid($prob);
	    $prob=$fac*$tmp;
	    $lali=int($lali/$gridLali);
	    $kwd="$prob".","."$lali";

	    ++$ctLine;
#	    print "xx kwd=$kwd ($tmp[6]",",",$lali*$gridLali,"), line=$line";
	    if (! defined $res{"$prob"}){
		push(@score,$prob);$res{"$prob"}="";}
	    if (! defined $res{"$kwd"}){
		$res{"$kwd"}=1;$res{"$prob"}.="$lali".",";}
	    else {++$res{"$kwd"};}}
    }				# end of file 
    return($ctLine);
}				# end of rdFile

# ================================================================================
sub project2grid{		# ------------------------------
    local($probIn)=@_;		# project onto grid

    $Lok=0;
#    foreach $it (2 .. $#gridProb){print "it=$it, grid = $gridFlip[$it-1]-$gridFlip[$it],\n";}

    foreach $it (2 .. $#gridProb){
#	if (!defined $gridFlip[$it-1]){print"missing it-1, it=$it,\n";exit;}
#	if (!defined $gridFlip[$it])  {print"missing it,   it=$it,\n";exit;}
#	if (!defined $probIn)         {print"missing probIn,\n";exit;}
	if (($gridFlip[$it-1]<$probIn)&&($probIn<=$gridFlip[$it])){
	    $probIn=int($probIn/$gridProb[$it]);
	    $Lok=1;
	    $fac=$gridProb[$it];}}
    print "none for  prob=$probIn, \n" if (! $Lok);
    return($probIn,$fac);
}				# end of project2grid

#===============================================================================
sub wrtDet{
    local($fhLoc,$txtLoc,@tmpLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtDet                      writes score vs. lali
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    if    ($txtLoc eq "score"){$Lscore=1;}else{$Lscore=0;}

    printf $fhLoc "%-6s\t%-10s\t%-10s\t%-5s\t%-5s\n","lg(p)","prob","xprob","lali","Nocc";
    foreach $tmp (@tmpLoc){
	$res{"$tmp"}=~s/,*$//g;	# split occurring lengths
	@len=split(/,/,$res{"$tmp"});
	@len=sort bynumber_high2low (@len);
	foreach $len(@len){
#	    next if ((length($len)<1)||($len =~ /\D/));
	    if ((length($len)<1)||($len =~ /\D/)){
		print "xx wrong $len\n";exit;}
	    $kwd="$tmp".","."$len";
#	    next if (! defined $res{"$kwd"});
	    if (! defined $res{"$kwd"}){
		print "xx wrong kwd=$kwd, $len\n";exit;}
	    $ct+=$res{"$kwd"};
	    printf $fhLoc 
		"%-6d\t%10s\t%10.3e\t%5d\t%5d\n",$tmp,"",(10**$tmp),
		$gridLali*$len,$res{"$kwd"};
	}
    }
}				# end of wrtDet

#===============================================================================
sub wrtHis{
    local($fhLoc,$txtLoc,$nameLoc,@tmpLoc) = @_ ;
    local($tmp,$ctT,$ctF);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHis                      writes histogram
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    if    ($txtLoc eq "score"){$Lscore=1;}else{$Lscore=0;}
				# compile totals susm (for percentages)
    $allT=$allF=0;
    foreach $tmp (@tmpLoc){$allT+=$res{"$tmp","Ntrue"};
			   $allF+=$res{"$tmp","Nfalse"};}

    if ($Lscore){printf $fhLoc "%-6s","$txtLoc";}
    else        {printf $fhLoc "%-8s\t%-10s","lg($txtLoc)","$txtLoc$nameLoc";}
    print  $fhLoc 
	"\t","nT$nameLoc","\t","nF$nameLoc","\t","nCT$nameLoc","\t","nCF$nameLoc";
    printf $fhLoc 
	"\t%5s\t%5s\t%5s\t%5s\n","nT/nf $nameLoc","ncT/nc $nameLoc",
	"ncF/nc $nameLoc","ncT/allT $nameLoc";
    $ctT=$ctF=0;$ncT=$ncF=0;
    foreach $tmp (@tmpLoc){	# histogram (score)
				# blast score/prob
	if ($Lscore){printf $fhLoc "%-6d","$tmp";}
	else        {printf $fhLoc "%-8.2f\t%10.3e",$tmp,(10**$tmp);}
	$nT=$res{"$tmp","Ntrue"};   $nF=$res{"$tmp","Nfalse"};
	print $fhLoc "\t",$nT,"\t", $nF;
	$ncT+=$res{"$tmp","Ntrue"}; $ncF+=$res{"$tmp","Nfalse"};
	print $fhLoc "\t",$ncT,"\t",$ncF;
	printf $fhLoc "\t%5.2f",100*($nT/($nT+$nF));
	printf $fhLoc 
	    "\t%5.2f\t%5.2f\t%5.2f\n",
	    100*($ncT/$allT),100*($ncF/$allF),100*($ncT/($ncT+$ncF));
    }
}				# end of wrtHis
