#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extract a range (and or chain) from DSSP file (and runs MaxHom on HSSP header)";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
if (! defined $ENV{'ARCH'}){print "*** setenv ARCH to machine type\n";
			    exit;}
$ARCH=$ENV{'ARCH'};
$par{"exeHsspExtrHdrId"}=   "/home/rost/perl/scr/hssp_extr_id.pl";
$par{"dirSwissCurrent"}=    "/data/swissprot/current/";
$par{"exeMax"}=             "/home/rost/pub/max/bin/". "maxhom.".$ARCH;
$par{"fileMaxDef"}=         "/home/rost/pub/max/".     "maxhom.default";
$par{"fileMaxMat"}=         "/home/rost/pub/max/mat/". "Maxhom_GCG.metric";
$par{"parMaxThresh"}=       "FORMULA +5"; # identity cut-off for Maxhom threshold of hits taken
$par{"parMaxProf"}=         "NO";
$par{"parMaxSmin"}=        -0.5;         # standard job
$par{"parMaxSmax"}=         1.0;         # standard job
$par{"parMaxGo"}=           3.0;         # standard job
$par{"parMaxGe"}=           0.1;         # standard job
$par{"parMaxW1"}=           "YES";       # standard job
$par{"parMaxW2"}=           "NO";        # standard job
$par{"parMaxI1"}=           "YES";       # standard job
$par{"parMaxI2"}=           "NO";        # standard job
$par{"parMaxNali"}=       500;           # standard job
$par{"parMaxSort"}=         "DISTANCE";  # standard job
$par{"parMaxProfOut"}=      "NO";        # standard job
$par{"parMaxStripOut"}=     "NO";        # standard job

				# ------------------------------
				# help
if ($#ARGV<2){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file_hssp chain ('0' for wild card)'\n";
    print "opt: \t pdbno=1-5,8-100 (reads PDBno as given, i.e., 2nd column in DSSP)\n";
    print "or:  \t no=1-5,8-100    (reads the DSSP no, i.e., first column)\n";
    print "     \t noMax / noDssp  (will no run Maxhom/not store DSSP file\n";
    print "     \t fileOutDssp=x\n";
    print "     \t fileOutHssp=x\n";
    print "     \t fileHssp=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$LnoPhd=$LnoMax=$LnoDssp=0;
				# read command line
$fileIn=  $ARGV[1];
$chainIn= $ARGV[2];
$tmp=$fileIn;$tmp=~s/^.*\///g;
$fileOutDssp=$tmp;
$fileOutHssp=$tmp;$fileOutHssp=~s/dssp/hssp/;

$Ldssp=$Lpdb=0;
foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);next if ($_ eq $ARGV[2]);
    if   ($_=~/^fileOutHssp=(.*)$/) {$fileOutHssp=$1;}
    elsif($_=~/^fileOutDssp=(.*)$/) {$fileOutDssp=$1;}
    elsif($_=~/^no=(.*)$/)          {$rangeIn=$1;$Ldssp=1;}
    elsif($_=~/^pdbno=(.*)$/i)      {$rangeIn=$1;$Lpdb=1;}
    elsif($_=~/^fileHssp=(.*)$/)    {$fileHssp=$1;}
    elsif($_=~/^noMax/i)            {$LnoMax=1;}
    elsif($_=~/^noDssp/i)           {$LnoDssp=1;}

    else { print"*** wrong command line arg '$_'\n";
	   die;}}
if (!defined $fileHssp){
    $fileHssp=$fileIn;$fileHssp=~s/dssp/hssp/g;}
if (! -e $fileHssp){
    print "-*- WARNING no HSSP $fileHssp\n";
    $Lhssp=0;}else{$Lhssp=1;}
if ($LnoMax){$Lhssp=0;}
if (! -e $fileIn){
    print "*** ERROR no DSSP $fileHssp for $fileIn\n";
    die;}
$#fileRm=0;
				# ------------------------------
				# (1) get range
@tmp=split(/,/,$rangeIn);
foreach $it (1..10000){$ok[$it]=0;}
$nres=0;
foreach $tmp(@tmp){
    $tmp=~s/\s//g;
    @tmp2=split(/-/,$tmp);
    foreach $it ($tmp2[1]..$tmp2[2]){++$nres;
				     $ok[$it]=1;}
    $max=$tmp2[2];}
				# ------------------------------
				# (2) read DSSP file
&open_file("$fhin", "$fileIn");
$#rd=0;
while (<$fhin>) {push(@rd,$_);
		 last if ($_=~/^\s+\#\s+RES/);}
while (<$fhin>) {$line=$_;
		 $chain=substr($_,12,1);
		 $pdbNo=substr($_,6,5);$pdbNo=~s/\s//g;
		 next if ($chainIn ne "0" && $chain ne $chainIn);
		 next if (! $ok[$pdbNo]);
		 push(@rd,$line);
		 ++$ctRes; 
		 if ($ctRes > ($nres+10)){ # allow for more (PDB 64,64A,...)
		     print "*** $fileIn too many residues now $ctRes max=$max, nres=$nres,\n";
		     exit;}}
close($fhin);
$nres=$ctRes;			# correct for additional PDB residues

				# ------------------------------
				# (3) write DSSP output
if ($LnoDssp){
    $fileTmpDssp="DSSP_EXTR_RANGE_".$$.".dssp";push(@fileRm,$fileTmpDssp);}
else {$fileTmpDssp=$fileOutDssp;}
print "--- write DSSP $fileTmpDssp\n";
&open_file("$fhout",">$fileTmpDssp"); 
foreach $rd(@rd){
    if ($rd =~/TOTAL NUMBER OF RES/){
	printf $fhout "%5d%-s\n",$nres,substr($rd,6);}
    else{
	print $fhout $rd;}}
close($fhout);
				# ------------------------------
				# (4) extract Swiss ids
if ($Lhssp){
    $fileHssp=$fileIn;$fileHssp=~s/dssp/hssp/g;
    $exe=$par{"exeHsspExtrHdrId"};
    $fileTmp="DSSP_EXTR_RANGE_".$$.".tmp";push(@fileRm,$fileTmp);
    $arg="swiss fileSwiss=$fileTmp";
    print "--- system \t '$exe $fileHssp $arg'\n";
    system("$exe $fileHssp $arg"); # run external script
				# ------------------------------
				# (5) read DSSP file
    &open_file("$fhin", "$fileTmp");
    $#rd=0;
    while (<$fhin>) {next if (/^id1/);
		     $_=~s/\n//g;
		     next if (length($_)<10);
		     ($tmp,$swiss)=split(/\s+/,$_);}
    close($fhin);
}
if (defined $swiss){
    @swiss=split(/,/,$swiss);}
if ($#swiss>=1){
				# ------------------------------
				# (6) write swiss-list
    $fileTmpList="DSSP_EXTR_RANGE_".$$.".list";push(@fileRm,$fileTmpList);
    &open_file("$fhout",">$fileTmpList"); 
#    @swiss=split(/,/,$swiss);
    foreach $swiss(@swiss){$swiss=~s/\s//g;
			   $dir=$swiss;$dir=~s/^[^\_]+\_(.).+$/$1/g;
			   $tmp=$par{"dirSwissCurrent"}."$dir"."/".$swiss;
			   next if (! -e $tmp);	# ignore missing files
			   print $fhout "$tmp\n";}
    close($fhout);
				# ------------------------------
				# (7) run Maxhom
    $cmd=&maxhomGetArg(" ",$par{"exeMax"},$par{"fileMaxDef"},$$,$fileTmpDssp,$fileTmpList,
		       $par{"parMaxProf"},$par{"fileMaxMat"},
		       $par{"parMaxSmin"},$par{"parMaxSmax"},$par{"parMaxGo"},$par{"parMaxGe"},
		       $par{"parMaxW1"},$par{"parMaxW2"},$par{"parMaxI1"},$par{"parMaxI2"},
		       $par{"parMaxNali"},$par{"parMaxThresh"},$par{"parMaxSort"},$fileOutHssp,
		       "/data/pdb/",$par{"parMaxProfOut"},$par{"parMaxStripOut"});
    $Lok=&run_program("$cmd","STDOUT"); # its running!
}
				# ------------------------------
				# (8) if missing: run self
if (! -e $fileOutHssp || &is_hssp_empty($fileOutHssp)){
    $Lok=$err=0;
    print "--- $scrName: running self ($fileTmpDssp)\n";
    ($Lok,$err)=
	&maxhomRunSelf(" ",$par{"exeMax"},$par{"fileMaxDef"},$$,$fileTmpDssp,
		       $fileOutHssp,$par{"fileMaxMat"},"STDOUT"); # 
}
				# ------------------------------
				# (9) clean up
if ($Lok){
    foreach $fileRm(@fileRm){
	unlink($fileRm);}
    system("\\rm MAXHOM*$$*");
    system("\\rm DSSP*$$*");
}
				# ------------------------------
				# (2) write output
print "--- output in $fileOutHssp\n";
exit;
