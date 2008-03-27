#!/usr/sbin/perl4 -w
##!/usr/bin/perl
#-------------------------------------------------------------------------------
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "hssp_extr_compoAA";
$scriptIn=     "list of HSSP files (or *.hssp)";
$scriptTask=   "extract amino acid composition (buried, exp, all) from HSSP";
$scriptNarg=   1;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# subroutines   (internal):  
#     ini                       initialises variables/arguments
#     iniHelp                   initialise help text
#     iniDefaults               initialise defaults
#     iniGetArg                 read command line arguments
#     iniChangePar              changing parameters according to input arguments
#     cleanUp                   deletes intermediate files
#     getCompo                  compiles the composition (for one HSSP file)
#     getLoci                   looks up the location
#     rdLoci                    reads file with locations
#     wrtCompoHeader            write out statistics for profiles
#     wrtCompoOne               write out statistics for profiles
# 
# subroutines   (external):
#     lib-ut.pl       complete_dir,dirMk,fileRm,get_in_keyboard,
#                     myprt_empty,myprt_line,myprt_txt,open_file,
#     lib-prot.pl     convert_acc,exposure_normalise_prepare,
#                     hsspGetChain,hsspRdProfile,hsspRdSeqSecAcc,isHsspGeneral,is_hssp,
#
#------------------------------------------------------------------------------#
#	Copyright				May,    	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	May,    	1997	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# ------------------------------
				# include perl libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# intermediate x.x

#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
$Lok=&ini;			# initialise variables
if (! $Lok){ die; }
				# ------------------------------
				# file with list or list of files?
if (($#fileIn == 1)&&(! &is_hssp($fileIn[1]))){
    $fileIn=$fileIn[1];
    $#fileIn=$Lerror=0;
    &open_file("$fhin","$fileIn");
    while(<$fhin>){$_=~s/\s//g;
		   next if (! -e $_);
		   $file=$_;
		   ($Lok,$txt,$fileTmp,$chain)=&isHsspGeneral($file);
		   if ($txt eq "isHssp"){
		       push(@fileIn,$file);}
		   else {print "*** expected HSSP file '$file' txt=$txt (returned $fileTmp)\n";
			 $Lerror=1;}}close($fhin);
    if ($Lerror){die '*** unwanted exit after extract HSSP files';}}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
				# read locations from file
if (-e $par{"fileInLoci"}){
    $Lok=&rdLoci($par{"fileInLoci"});
    if (! $Lok){ print "*** ERROR $scriptName read locations ",$par{"fileInLoci"},",\n";
		 die '*** unwanted after trying to read locations';}}

				# ------------------------------
				# write output headers
&wrtCompoHeader();		# will open all files

				# --------------------------------------------------
				# loop over all HSSP files
				# --------------------------------------------------
$ctProt=0;
foreach $fileIn (@fileIn){
    %rdChain=%rdHssp=%rdProf=0;
    $id=$fileIn;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    ($chain,%rdChain)=&hsspGetChain($fileIn); # get chain identifiers
				# ------------------------------
				# loop over all chains
    foreach $itChain (1..$rdChain{"NROWS"}){
	$ifir=$rdChain{"$itChain","ifir"};$ilas=$rdChain{"$itChain","ilas"};
	$chain=$rdChain{"$itChain","chain"};
	if ($chain ne " "){$idChain=$id."_".$chain;}else{$idChain=$id;}
	$lenChain=($ilas-$ifir+1);
	if ($lenChain<$par{"statMinLen1"}){ # protein shorter than minimal length?
	    next;}
				# ------------------------------
				# read HSSP sequence, secondary structure, and accessibility
	if ($Lverb){printf 
			"--- reading %-20s: chain=%1s:%3d-%3d\n",$fileIn,$chain,$ifir,$ilas;}
	($Lok,%rdHssp)=&hsspRdSeqSecAcc($fileIn,$ifir,$ilas);
	if (! $Lok){ print "*** ERROR $scriptName read HSSP $fileIn, chn=$chain:$ifir-$ilas\n";
		     die '*** unwanted after trying to read HSSP';}
				# ------------------------------
				# read HSSP profile
	if ($Lverb){printf 
			"--- reading %-20s: profiles:%3d-%3d\n",$fileIn,$ifir,$ilas;}
	($Lok,%rdProf)=&hsspRdProfile($fileIn,$ifir,$ilas);
	if (! $Lok){ print "*** ERROR $scriptName rd HSSPprof $fileIn, c=$chain:$ifir-$ilas\n";
		     die '*** unwanted after trying to read HSSPprof';}
				# ------------------------------
				# consistency check: same length?
	if ($rdHssp{"NROWS"} != $rdHssp{"NROWS"}){
	    print "*** ERROR $scriptName($fileIn) length HSSP (",$rdHssp{"NROWS"},
	          ") and HSSPprof(",$rdHssp{"NROWS"},", don't match\n";
	    next;}
				# ------------------------------
	$Lok=&getCompo;		# compile composition
	if (! $Lok){
	    next;}
	++$ctProt;
	$loci=&getLoci($id);
	print "xx loci=$loci, (for id=$id)\n";
				# ------------------------------
				# write composition
	&wrtCompoOne($ctProt,$idChain,$lenChain,$loci);
    }
}
close($fhoutProfE);close($fhoutProfB);close($fhoutProfA);
close($fhoutSingE);close($fhoutSingB);close($fhoutSingA);

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
if (! $par{"debug"}){		# deleting intermediate files
    &cleanUp();}
if ($Lverb) { &myprt_empty; &myprt_line; &myprt_txt("$scriptName ended fine .. -:\)"); 
	      &myprt_txt("output files  \t ");
	      foreach $_(@fileOut){
		  if (-e $_){
		      printf "--- %-20s %-s\n"," ",$_;}}}
exit;

#===============================================================================
sub ini {
    local (@scriptTask,@scriptHelp,@scriptKwd,@scriptKwdDescr,$txt);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                        initialises variables/arguments
#-------------------------------------------------------------------------------
#	$date is e.g.:		Thu Oct 14, 1993 13:06:47
#	@Date is e.g.:		Oct,14,13:06:47,1993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; 
    $date="$Date[1] $Date[2] $Date[3], $Date[5] $Date[4]"; shift (@Date) ; 
    
#    $PWD=                       $ENV{'PWD'}; $pwd=&complete_dir($PWD);
    $ARCH=                      $ENV{'ARCH'}; 
    if (!defined $ARCH)         {print "-*- WARNING \t no architecture defined\n";}

    &iniDefaults;               # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp;

    $Lok=&iniGetArg;		# read command line input
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniGetArg\n";
		return(0);}

    $Lok=&iniChangePar;
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniChangePar\n";
		return(0);}

    if ($Lverb){&myprt_line; 
		print "--- Settings of $scriptName are:\n--- \n"; 
		if ($#fileIn==1) {printf "--- %-20s '%-s'\n","fileIn:",$fileIn[1]; }
		else {&myprt_txt("input files:  \t ");
		      foreach $_(@fileIn){printf "--- %-20s '%-s'\n"," ",$_;}}
		if ($#fileOut==1){printf "--- %-20s '%-s'\n","fileOut:",$fileOut[1]; }
		else {&myprt_txt("output files:  \t ");
		      foreach $_(@fileOut){if (!  $_){next;}
					   printf "--- %-20s '%-s'\n"," ",$_;}}
		foreach $kwd (@kwdDef) {
		    if ($kwd=~/^fileOut|^fileIn/){
			next;}
		    if (! defined $par{"$kwd"}){$tmp="!! UNDEF !!";}else{$tmp=$par{"$kwd"};}
		    if ((length($tmp)<1)||($tmp eq "unk")){
			next;}
		    printf "--- %-20s '%-s'\n",$kwd,$tmp;}&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lmiss=0;
    foreach $kwd(@kwdDef){
	if ($kwd =~/^(fileIn|exe)/){
	    if ((! defined  $par{"$kwd"})||(length($par{"$kwd"})<1)){
		next;}
	    if (! -e $par{"$kwd"}){
		printf "*** %-20s '%-s'\n","MISSING $kwd",$par{"$kwd"};$Lmiss=1;}}}
    if ($Lmiss){
	print "*** try to locate the missing files/executables before continuing!\n";
	print "*** left script '$scriptName' after ini date: $date\n";
	return(0);}
    return(1);
}				# end of ini

#===============================================================================
sub iniHelp {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelp                     initialise help text
#-------------------------------------------------------------------------------
    @scriptTask=   (" ",
		     "Task: \t $scriptTask",
		     " ",
		     "Input:\t $scriptIn",
		     " ",
		     "Done: \t ");
    @scriptHelp=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$scriptName help'",
		     "      \t ............................................................");
    @scriptKwd=     ("fileInLoci=",
		     "title=",
		     " ",
		     "not_screen",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=",
		     );
    @scriptKwdDescr=("RDB file(s) (commata with locations (Euka2-allLociTransl.rdb,Proka2-.)", 
		     "title of output files",
		     " ",
		     "no information written onto screen",
		     "input directory        default: local",
		     "output directory       default: local",
		     "working directory      default: local ",
		     );

    if ( ($ARGV[1]=~/^help|^man|^-h/) ) { 
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $kwdOpt(@kwdDef){
	    if (! defined $par{"$kwdOpt"}){$tmp="undef";}else{$tmp=$par{"$kwdOpt"};}
	    printf "--- %-12s=x \t (def:=%-s) \n",$kwdOpt,$tmp;}
	&myprt_empty; print "-" x 80,"\n"; die; }
    elsif ( $#ARGV < $scriptNarg ) {
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $txt (@scriptHelp){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";die;}
}				# end of iniHelp

#===============================================================================
sub iniDefaults {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefaults                 initialise defaults
#-------------------------------------------------------------------------------
				# --------------------
				# directories
    $par{"dirIn"}=              ""; # directory with input files
    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
				# databases
    $par{"dirHssp"}=            "/data/hssp/";
    $par{"dirLoci"}=            "/home/rost/pub/data/swiss/";
				# --------------------
				# files
    $par{"fileInLoci"}=         ""; # file with locations (RDB: no\tid\tlocation\tsource)

    $par{"title"}=              "Loci3Pdb-";
#    $par{"title"}=              "Loci3Pred-";
#    $par{"title"}=              "PhdLoci-";
    $par{"extOut"}=             ".rdb";
				# read title and extension from command line
    @tmp=@ARGV;
    foreach $_ (@tmp){if   ($_ =~ /^title=(.+)/) {$par{"title"}=$1;}
		      elsif($_ =~ /^extOut=(.+)/){$par{"extOut"}=$1;}}

    $par{"fileOutProfE"}=   $par{"title"}."profExp".$par{"extOut"}; # general
    $par{"fileOutProfB"}=   $par{"title"}."profBur".$par{"extOut"}; # general
    $par{"fileOutProfA"}=   $par{"title"}."profAll".$par{"extOut"}; # irrespective of acc
    $par{"fileOutSingE"}=   $par{"title"}."singExp".$par{"extOut"}; # only AAs from pdb
    $par{"fileOutSingB"}=   $par{"title"}."singBur".$par{"extOut"}; # only AAs from pdb
    $par{"fileOutSingA"}=   $par{"title"}."singAll".$par{"extOut"}; # only AAs from pdb
				# file extensions
    $par{"extOut"}=             ".tmp";
				# file handles
#    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
				# --------------------
				# logicals
    $Lverb=                     1; # blabla on screen
    $Lverb2=                    0; # more verbose blabla
    $Lverb3=                    0; # more verbose blabla
    $par{"verbose"}=$Lverb;$par{"verbose2"}=$Lverb2;$par{"verbose3"}=$Lverb3;
				# --------------------
				# other
    $par{"statExposed"}=        25; # acids with relative accessibility higher than that
				# regarded as exposed
    $par{"statMinLen1"}=        30; # minimal length of protein
    $par{"lociUnk"}=            "?"; # name used for unknown locations
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("debug","verbose","verbose2","verbose3",
		  "dirIn","dirOut","dirWork","dirHssp","dirLoci",

		  "title","extOut",
		  "fileInLoci",
		  "fileOutProfE","fileOutProfB","fileOutProfA",
		  "fileOutSingE","fileOutSingB","fileOutSingA",

		  "statExposed","statMinLen1","lociUnk"
		  );

    @aaNamesHssp= ("V","L","I","M","F","W","Y","G","A","P",
		   "S","T","C","H","R","K","Q","E","N","D");
#    @aaNamesAbcd= ("A","C","D","E","F","G","H","I","K","L",
#		   "M","N","P","Q","R","S","T","V","W","Y")
#    $lociUnk=       "?";
#    %lociInterpret= ('cytoplasmic',  "cyt", 
#		     'extracellular',"ext",
#		     'nuclear',      "nuc",
#		     'all-other',    "$lociUnk",);
#    %LlociInterpret=('cytoplasmic',"1",
#		     'extracellular',"1",
#		     'nuclear',      "1",);
}				# end of iniDefaults

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
    $Lokdef=0; $#fileIn=$#tmp=0;
    foreach $arg (@ARGV){	# key word driven input
	if    ( $arg=~ /verbose3/ )    { $Lverb3=1; }
	elsif ( $arg=~ /verbose2/ )    { $Lverb2=1; }
	elsif ( $arg=~ /verbose/ )     { $Lverb=1; }
	elsif ( $arg=~ /not_verbose/ ) { $Lverb=0; }
	else {			# general
	    $Lok=0;
	    foreach $kwd (@kwdDef){ # 
		if ($arg=~/^$kwd=(.+)$/){$tmp=$1;$tmp=~s/\s//g;
					 if ($kwd =~/^dir/){ # add '/' at end of directories
					     $tmp=&complete_dir($tmp);}	# external lib-ut.pl
					 $par{"$kwd"}=$tmp; $Lok=1;$Lokdef=1;
					 last;}}
	    if    ((! $Lok)&&($arg=~/=/)){
		print "*** iniGetArg: unrecognised argument: $arg\n";
		return(0);}
	    elsif ((! $Lok)&&(-e "$arg")){ # input file?
		push(@fileIn,$arg);}
	    elsif (!$Lok){	# possibly add dirIn
		print "x.x still missing '$arg'\n";
		push(@tmp,$arg);}}}
    foreach $tmp (@tmp){	# check unrecognised input arguments
	$tmp1=$par{"dirIn"}.$tmp;
	if (-e "$tmp1"){push(@fileIn,$tmp1);}
	else { print "*** iniGetArg: unrecognised argument(2): '$tmp'\n";
	       return(0);}}	# 
    return(1);
}				# end of iniGetArg

#===============================================================================
sub iniChangePar {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniChangePar                changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwdDef){
	push(@tmp,$kwd) unless ((! defined $kwd)||(length($kwd)<1));}
    @kwdDef=@tmp;
				# ------------------------------
				# add input directory
    if ((defined $par{"dirIn"})&&($par{"dirIn"} ne "unk")&&($par{"dirIn"} ne "local")&&
	(length($par{"dirIn"})>1)){
	foreach $fileIn(@fileIn){
	    if (! -e "$fileIn"){
		$fileIn=$par{"dirIn"}.$fileIn;}
	    if (! -e "$fileIn"){
		print "*** iniChangePar: no in file=$fileIn, dirIn=",$par{"dirIn"},",\n";
		return(0);}}}
				# ------------------------------
    foreach $kwd (@kwdDef){	# add 'pre' 'title' 'ext'
	if ($kwd=~/^fileOut/){
	    if ((defined $par{"$kwd"})&&($par{"$kwd"} eq "no")){
		$par{"$kwd"}=0;
		next;}
	    if ((!defined $par{"$kwd"})||($par{"$kwd"} eq "unk")){
		$kwdPre=$kwd; $kwdPre=~s/file/pre/; 
		if (defined $par{"$kwdPre"}){$pre=$par{"$kwdPre"};}else{$pre="";}
		$kwdExt=$kwd; $kwdExt=~s/file/ext/; 
		if (defined $par{"$kwdExt"}){$ext=$par{"$kwdExt"};}else{$ext="";}
		if ((! defined $par{"title"})||($par{"title"} eq "unk")){
		    $par{"title"}=$scriptName;}
		$par{"$kwd"}=$pre.$par{"title"}.$ext;}}}
				# ------------------------------
				# add output directory
    if ((defined $par{"dirOut"})&&($par{"dirOut"} ne "unk")&&($par{"dirOut"} ne "local")&&
	(length($par{"dirOut"})>1)){
	if (! -d $par{"dirOut"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirOut"});}else{@tmp=($par{"dirOut"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    if ($kwd=~/^fileOut/){
		if ($par{"$kwd"} !~ /^$par{"dirOut"}/){
		    $par{"$kwd"}=$par{"dirOut"}.$par{"$kwd"};}}}}
				# ------------------------------
				# push array of output files
    if (! defined @fileOut){$#fileOut=0;}
    foreach $kwd (@kwdDef){
	if ($kwd=~/^fileOut/){
	    push(@fileOut,$par{"$kwd"});}}
				# ------------------------------
				# add working directory
    if ((defined $par{"dirWork"})&&($par{"dirWork"} ne "unk")&&($par{"dirWork"} ne "local")&&
	(length($par{"dirWork"})>1)){
	if (! -d $par{"dirWork"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirWork"});}else{@tmp=($par{"dirWork"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
		if ($par{"$kwd"} !~ /^$par{"dirWork"}/){
		    $par{"$kwd"}=$par{"dirWork"}.$par{"$kwd"};}}}}
				# ------------------------------
				# array of Work files
    if (! defined @fileWork){$#fileWork=0;}
    foreach $kwd (@kwdDef){
	if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
	    push(@fileWork,$par{"$kwd"});}}
				# ------------------------------
				# blabla
    if ((defined $par{"verbose"}) &&($par{"verbose"})) {$Lverb=1; }
    if ((defined $par{"verbose2"})&&($par{"verbose2"})){$Lverb2=1;}
    if ((defined $par{"verbose3"})&&($par{"verbose3"})){$Lverb3=1;}
				# ------------------------------
				# add directory to executables
    foreach $kwd (@kwdDef){
	if (($kwd=~/^exe/)&&(defined $par{"$kwd"})&&(! -e $par{"$kwd"})){
	    $par{"$kwd"}=$par{"dirPerl"}.$par{"$kwd"};}}

    return(1);
}				# end of iniChangePar

#===============================================================================
sub cleanUp {
    local($sbrName,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";} $sbrName="$tmp"."cleanUp";
    if ($#fileWork>0){		# remove intermediate files
	if ($Lverb){@tmp=("STDOUT",@fileWork);}else{@tmp=(@fileWork);}
	($Lok,@tmp)=
	    &fileRm(@tmp);}	# external lib-ut.pl
}				# end of cleanUp

#===============================================================================
sub getCompo {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getCompo                    compiles the composition (for one HSSP file)
#   variables are GLOBAL        %rdHssp,%rdProf
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getCompo";$fhinLoc="FHIN"."$sbrName";
				# normalise accessibility 
    &exposure_normalise_prepare("RS"); # external lib-prot.pl
				# ------------------------------
				# postprocess sequence, get relAcc
    foreach $itRes (1..$rdHssp{"NROWS"}){
	$rdHssp{"seq","$itRes"}=~tr/[a-z]/C/; # lower cap to C
	$rdHssp{"relAcc","$itRes"}=	# relative acc (convert_acc: external lib-prot.pl)
	    &convert_acc($rdHssp{"seq","$itRes"},$rdHssp{"acc","$itRes"},"unk","RS"); }
				# ------------------------------
				# normalise profile by counts
    foreach $itRes (1..$rdHssp{"NROWS"}){
	foreach $aa (@aaNamesHssp){
	    $profNocc{"$aa","$itRes"}=
		int((1/100)*$rdProf{"$aa","$itRes"}*$rdProf{"NOCC","$itRes"});}}
				# ------------------------------
    $nresProfE=$nresProfB=$nresProfA=0; # set zero
    $nresSingE=$nresSingB=$nresSingA=0;
    foreach $aa (@aaNamesHssp){$ctProfE{$aa}=$ctProfB{$aa}=$ctProfA{$aa}=0;
			       $ctSingE{$aa}=$ctSingB{$aa}=$ctSingA{$aa}=0;}
				# ------------------------------
				# get protein averages (single)
    foreach $itRes (1..$rdHssp{"NROWS"}){
	$aa=$rdHssp{"seq","$itRes"};
	if    ($rdHssp{"relAcc","$itRes"}<$par{"statExposed"}){ # buried
	    ++$nresSingB;++$ctSingB{$aa};}
	else {		# exposed
	    ++$nresSingE;++$ctSingE{$aa};}
	++$nresSingA;++$ctSingA{$aa};}
				# ------------------------------
				# get protein averages
    foreach $itRes (1..$rdHssp{"NROWS"}){
	foreach $aa (@aaNamesHssp){
	    if    ($rdHssp{"relAcc","$itRes"}<$par{"statExposed"}){ # buried
		$nresProfB+=$profNocc{"$aa","$itRes"};
		$ctProfB{$aa}+=$profNocc{"$aa","$itRes"};}
	    else {		# exposed
		$nresProfE+=$profNocc{"$aa","$itRes"};
		$ctProfE{$aa}+=$profNocc{"$aa","$itRes"};}
	    $nresProfA+=$profNocc{"$aa","$itRes"};
	    $ctProfA{$aa}+=$profNocc{"$aa","$itRes"};}}
    return(1);
}				# end of getHsspProf

#===============================================================================
sub getLoci {
    local($idInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getLoci                     returns the location for the given id
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getLoci";$fhinLoc="FHIN"."$sbrName";

    if (defined $loci{$idInLoc}){
	return ($loci{$idInLoc});}
    else {
	return ($par{"lociUnk"});}
}				# end of getLoci

#===============================================================================
sub rdLoci {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdLoci                      read file with locations
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdLoci";$fhinLoc="FHIN"."$sbrName";

    $fileInLoc=~s/^,|,$//g;
    @fileInLoc=split(/,/,$fileInLoc);
    $Lok=0;			# loop over many files
    foreach $fileInLoc (@fileInLoc){
	if (! -e $fileInLoc){
	    $fileInLoc=$par{"dirLoci"}.$fileInLoc;}
	if (! -e $fileInLoc){
	    next;}
	$Lok=       &open_file("$fhinLoc","$fileInLoc");
	if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		    return(0);}
	while (<$fhinLoc>) {if(/^\#|^\s*lineNo|^\s*5S/){next;}
			    $_=~s/\n//g;$_=~s/^\s*|\s*$//g;
			    @tmp=split(/\t/,$_);
			    $tmp[2]=~s/\s//g;$tmp[3]=~s/\s//g;
			    $loci{$tmp[2]}=$tmp[3];}close($fhinLoc);
    }
    return($Lok);
}				# end of rdLoci

#===============================================================================
sub wrtCompoHeader {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtCompoHeader           write out statistics for profiles
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtCompoHeader";$fhinLoc="FHIN"."$sbrName";
				# file names
    $fileOutProfE=$par{"fileOutProfE"};$fileOutSingE=$par{"fileOutSingE"};
    $fileOutProfB=$par{"fileOutProfB"};$fileOutSingB=$par{"fileOutSingB"};
    $fileOutProfA=$par{"fileOutProfA"};$fileOutSingA=$par{"fileOutSingA"};
				# file handles
    $fhoutProfE="FHOUT_PROF_E";$fhoutProfB="FHOUT_PROF_B";$fhoutProfA="FHOUT_PROF_A";
    $fhoutSingE="FHOUT_SING_E";$fhoutSingB="FHOUT_SING_B";$fhoutSingA="FHOUT_SING_A";
				# open files
    &open_file("$fhoutProfB",">$fileOutProfB");&open_file("$fhoutSingE",">$fileOutSingE");
    &open_file("$fhoutProfE",">$fileOutProfE");&open_file("$fhoutSingB",">$fileOutSingB");
    &open_file("$fhoutProfA",">$fileOutProfA");&open_file("$fhoutSingA",">$fileOutSingA");

    $accExposed=$par{"statExposed"}; # RDB header
    foreach $fh ("$fhoutProfE","$fhoutProfB","$fhoutProfA",
		 "$fhoutSingE","$fhoutSingB","$fhoutSingA"){
	print $fh "\# Perl-RDB\n","\# \n","\# Profile-compositionss for HSSP files\n";
	if    ($fh =~ /$fhoutProfE|$fhoutSingB/){
	    print $fh "\# PARAMETER Accessibility:  0 - $accExposed \% rel. accessibil.\n";}
	elsif ($fh =~ /$fhoutProfB|$fhoutSingE/){
	    print $fh "\# PARAMETER Accessibility:  $accExposed - 100 \% rel. accessibil.\n";}
	elsif ($fh =~ /$fhoutProfA|$fhoutSingA/){
	    print $fh "\# PARAMETER Accessibility:  0-100 \% rel. accessibility\n";}
	print $fh 
	    "\# NOTATION ------------------------------------------------------------\n",
	    "\# NOTATION COLUMN-NAMES\n",
	    "\# NOTATION loci:  sub-cellular locations taken from SWISS-PROT\n",
	    "\# NOTATION id:    PDB identifier\n",
	    "\# NOTATION nres:  number of residues used for composition (i.e. in chain)\n",
	    "\# NOTATION AA:    percentage of amino acids per protein\n",
	    "\# NOTATION ------------------------------------------------------------\n";}

    foreach $fh ("$fhoutProfE","$fhoutProfB","$fhoutProfA",
		 "$fhoutSingE","$fhoutSingB","$fhoutSingA"){
	printf $fh		# names
	    "%5s\t%-15s\t%-10s\t%6s","no","loci","id1","nres";
	foreach $aa (@aaNamesHssp){
	    printf $fh "\t%5s",$aa;}
	printf $fh "\t%5s\n","sum";
	printf $fh		# formats
	    "%5s\t%-15s\t%-10s\t%6s","5N","15S","10S","6N";
	foreach $_ (1..20){printf $fh "\t%5s","5.2F";}
	printf $fh "\t%5s\n","5.2F";}
}				# end of wrtCompoHeader

#===============================================================================
sub wrtCompoOne {
    local($itLoc,$idLoc,$lenChainLoc,$lociLoc)=@_;
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtCompoOne              write out statistics for profiles
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtCompo";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# for easy looping
    $nres{"$fhoutProfE"}=$nresProfE;$nres{"$fhoutSingE"}=$nresSingE;
    $nres{"$fhoutProfB"}=$nresProfB;$nres{"$fhoutSingB"}=$nresSingB;
    $nres{"$fhoutProfA"}=$nresProfA;$nres{"$fhoutSingA"}=$nresSingA;
				# ------------------------------
				# loop over all files
    foreach $fhLoc("$fhoutProfE","$fhoutProfB","$fhoutProfA",
		   "$fhoutSingE","$fhoutSingB","$fhoutSingA"){
	if (! $nres{"$fhLoc"}){
	    print "xx too few (wrtCompoOne, id=$idLoc) fhLoc=$fhLoc,\n";
	    next;}
	printf $fhLoc	# RDB general
	    "%5d\t%-15s\t%-10s\t%6d",$itLoc,$lociLoc,$idLoc,$lenChainLoc;
	$sum=0;			# RDB per residue counts
	if    ($fhLoc eq "FHOUT_PROF_E"){ # exposed (prof)
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctProfE{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfE{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_PROF_B"){ # buried (prof)
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctProfB{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfB{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_PROF_A"){ # all (prof)
	    foreach $aa (@aaNamesHssp){ 
		$sum+=100*($ctProfA{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfA{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_SING_E"){ # exposed (sing)
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctSingE{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctSingE{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_SING_B"){ # buried (sing)
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctSingB{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctSingB{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_SING_A"){ # all (sing)
	    foreach $aa (@aaNamesHssp){ 
		$sum+=100*($ctSingA{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctSingA{$aa}/$nres{"$fhLoc"});}}
	printf $fhLoc "\t%5.2f\n",$sum;}
}				# end of wrtCompoOne

#===============================================================================
sub subx {
#    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if (length($_)==0){
	    next;}
    } close($fhinLoc);

}				# end of subx

