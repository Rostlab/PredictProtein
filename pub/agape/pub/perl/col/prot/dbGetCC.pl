#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# hsspExtrCC.pl
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hsspExtrCC.pl file.hssp
# optional:     list of HSSP files
# task:		extract pattern of C-C from DSS
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       September,       1996           #
#			changed:       .	,    	1996           #
#	EMBL			       Version 0.1                     #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
#
#
				# sets array count to start at 1, not at 0
$[ =1 ;

push (@INC, "/home/rost/perl","/u/rost/perl","/usr/people/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

				# ------------------------------
				# optional input keys
@opt=("dirHssp","dirDssp","extHssp","extDssp");
				# ------------------------------
				# help
if ($#ARGV<1){print"goal:      extract pattern of C-C from HSSP\n";
	      print"usage:     'script file.hssp pat=abba'\n";
	      print"or   :     'script List-of-HSSP-files pat=abba'\n";
	      print"optional:  usage: add in command line 'key=x', where x is your choice and x=\n";
	      print"           ";
	      foreach $opt(@opt){print"$opt,";}print"\n";
	      exit;}
				# ------------------------------
				# defaults
$fhout="FHOUT";
$fileOut="Out-cc.tmp";
$fileDsspOk="Out-dssp.list";
$fileHsspOk="Out-hssp.list";

$par{"dirHssp"}=      "/data/hssp/";
$par{"dirDssp"}=      "/data/dssp/";
$par{"extHssp"}=      ".hssp";
$par{"extDssp"}=      ".dssp";

@desRdDssp=("posDssp","posPdb","aa","sec","acc");

				# ------------------------------
$#fileIn=0;			# read command line input
foreach $arg(@ARGV){$Lok=0;
		    foreach $opt(@opt){
			if ($arg=~/^$opt=/){$arg=~s/^$opt=|\s//g;$par{"$opt"}=$arg;
					    $Lok=1;
					    last;}}
		    if (! $Lok){push(@fileIn,$arg);}}
				# ------------------------------
				# get input files
&getInputFiles($par{"dirDssp"},$par{"dirHssp"},$par{"extDssp"},$par{"extHssp"},@ARGV);

&exposure_normalise_prepare;	# prepare normalisation of accessibility

				# --------------------------------------------------
				# read files
$#fileHsspOk=$#fileDsspOk=$#idOk=0;
foreach $itFile (1..$#fileDssp){
				# ------------------------------
				# read the cysteines in DSSP
				# $rdCC{"$ct","x"}, x='posDssp', 'posPdb', 'aa', 'sec', 'acc'
    print"x.x reading it=$itFile, file\$fileDssp[$itFile], chain=$chain[$itFile],\n";

    ($ctCC,%rdCC)=
	&dsspGetCC($fileDssp[$itFile],$chain[$itFile]);
    if ($ctCC<1) { print "--- \t \t $fileDssp[$itFile]_$chain[$itFile]: no cysteine found\n";
		   next;}
				# get PDBid
    $id=$fileDssp[$itFile];$id=~s/^.*\/|\..*$//g;
    if ($chain[$itFile] ne " "){$id=$id."_".$chain[$itFile];}

    print "x.x file Dssp=$fileDssp[$itFile],\n";foreach $it (1..$rdCC{"NROWS"}){printf "x.x %4d ",$it;foreach $des(@desRdDssp){printf "%4s ",$rdCC{"$it","$des"};}print"\n";}
    
				# ------------------------------
				# store information DSSP
    $res{"$id","nCC"}=$rdCC{"NROWS"};push(@idOk,$id);
    foreach $it (1..$rdCC{"NROWS"}){
	foreach $des(@desRdDssp){
	    $res{"$id","$it","$des"}=$rdCC{"$it","$des"};}
	$res{"$id","$it","acc"}=~s/\s//g; }

				# ------------------------------
				# read the profiles in HSSP
    ($tmpName,%tmp)=
	&hsspGetCCprof($fileHssp[$itFile],$chain[$itFile]);

				# ------------------------------
				# store information HSSP
				# HSSP headers: V,L,I,M,F,W,Y,G,A,P,S,T,C,H,R,K,Q,E,N,D,
				#               NOCC,NDEL,NINS,ENTROPY,RELENT,WEIGHT
    @desHsspRd=split(/\s+/,$tmpName);
    foreach $it (1..$rdCC{"NROWS"}){
	$pos=$rdCC{"$it","posPdb"};
	if (defined $tmp{"$pos"}){@tmp=split(/\s+/,$tmp{"$pos"});
				  foreach $itKey (1..$#desHsspRd){
				      $des=$desHsspRd[$itKey];
				      $res{"$id","$it","$des"}=$tmp[$itKey];}}
	else {foreach $itKey (1..$#desHsspRd){$des=$desHsspRd[$itKey]; # set zero x.x
					      $des=$desHsspRd[$itKey];
					      $res{"$id","$it","$des"}="";}
	      print "*** ERROR miss pos=$pos, hssp=$fileHssp[$itFile], chain=$chain[$itFile],\n";}}

				# ------------------------------
				# store file with hits
    push(@fileDsspOk,$fileDssp[$itFile]);
    push(@fileHsspOk,$fileHssp[$itFile]);
    push(@chainOk,$chain[$itFile]);

}
				# --------------------------------------------------
				# write list of files with Cysteins
if ($#fileDsspOk>0){&open_file("$fhout", ">$fileDsspOk");
		    foreach $it(1.. $#fileDsspOk){
			if ($chainOk[$it] ne " "){
			    print $fhout "$fileDsspOk[$it]_$chainOk[$it]\n";}
			else {
			    print $fhout "$fileDsspOk[$it]\n";}}close($fhout);
		    print "--- list of DSSP with Cysteines in $fileDsspOk\n";}
if ($#fileHsspOk>0){&open_file("$fhout", ">$fileHsspOk");
		    foreach $it(1.. $#fileHsspOk){
			if ($chainOk[$it] ne " "){
			    print $fhout "$fileHsspOk[$it]_$chainOk[$it]\n";}
			else {
			    print $fhout "$fileHsspOk[$it]\n";}}close($fhout);
		    print "--- list of HSSP with Cysteines in $fileHsspOk\n";}

&compileStatCC("STDOUT");

&open_file("$fhout", ">$fileOut");
&compileStatCC("$fhout");
close($fhout);

exit;

#==========================================================================================
sub getInputFiles {
    local($dirDssp,$dirHssp,$extDssp,$extHssp,@inLoc)=@_;
    local($fileTmp,$file,$chain);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   getInputFiles               reads the files given on the command line, options allowed: 
#                               1. Single files
#                                  single DSSP/HSSP file or PDBid 
#                                     (with or without chain: file.dssp_C, file.hssp_C, id_C)
#                               2. List of files
#                                  list of DSSP/HSSP files or PDBids'
#                                     (with or without chain: file.dssp_C, file.hssp_C, id_C)
#       out:                    global: @fileDssp,@fileHssp,@chain,
#                                  (where $fileDssp[n] corresponds to $fileHssp[n])
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_GET_INPUT_FILES";
    $#fileDssp=$#fileHssp=$#chain=0;

    $#fileTmp=0;		# --------------------------------------------------
    foreach $file (@inLoc){	# first check whether list of id's
	if    (&is_dssp_list($file)){&open_file("$fhinLoc", "$file");
				     while(<$fhinLoc>){$_=~s/\s|\n//g;
						       if (length($_)<6){next;}
						       push(@fileTmp,$_);}close($fhinLoc);}
	elsif (&is_hssp_list($file)){&open_file("$fhinLoc", "$file");
				     while(<$fhinLoc>){$_=~s/\s|\n//g;
						       if (length($_)<6){next;}
						       push(@fileTmp,$_);}close($fhinLoc);}
	elsif (&is_pdbid_list($file)){&open_file("$fhinLoc", "$file");
				      while(<$fhinLoc>){$_=~s/\s|\n//g;
							if (length($_)<6){next;}
							push(@fileTmp,$_);}close($fhinLoc);}}
    if ($#fileTmp>0){
	@inLoc=@fileTmp;}
				# --------------------------------------------------
    foreach $file (@inLoc){	# loop over all input arguments/files
				# ------------------------------
	$chain=" ";		# get chain id
	if ($file=~/_[A-Z0-9]$/){$chain=substr($file,(length($file)-2),2);$chain=~s/_//g;
				 $file=~s/_[A-Z0-9]$//g;}
				# ------------------------------
	if (! -e $file){	# is not existing, try to append directories
	    $fileTmp=$dirDssp.$file; # append DSSP directory
	    if (! -e $fileTmp){$fileTmp=$dirHssp.$file;} # append HSSP directory
	    if (! -e $fileTmp){$fileTmp=$dirDssp.$file.$extDssp;} # append DSSP dir and extension
	    if (! -e $fileTmp){print "-*- WARNING getInputFiles: no file found '$file'\n";
			       next;}
	    else {$file=$fileTmp;}}
				# ------------------------------
	if   (&is_dssp($file)){ # appears to be DSSP file
	    $tmp=$file;$tmp=~s/^.*\/|$extDssp.*//g;
	    $hssp=$dirHssp.$tmp.$extHssp; # get corresponding HSSP file
	    if (&is_hssp($hssp)){push(@fileDssp,$file);push(@fileHssp,$hssp);
				 $Lok=1;push(@chain,$chain);}
	    else {               print "-*- WARNING getInputFiles: no HSSP for '$file'\n";$Lok=0;}}
				# ------------------------------
	elsif(&is_hssp($file)){ # appears to be HSSP file
	    $tmp=$file;$tmp=~s/^.*\/|$extHssp.*//g;
	    $dssp=$dirDssp.$tmp.$extDssp; # get corresponding DSSP file
	    if (&is_dssp($dssp)){push(@fileHssp,$file);push(@fileDssp,$dssp);
				 $Lok=1;push(@chain,$chain);}
	    else {               print "-*- WARNING getInputFiles: no DSSP for '$file'\n";$Lok=0;}}
    }
}				# end of getInputFiles

#==========================================================================================
sub dsspGetCC {
    local ($fileLoc,$chainLoc) = @_ ;
    local ($fhinLoc,%rdLoc,$ctCC);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dsspGetCC                   reads the cysteines from a DSSP file
#       in:                     file (and optionally the chain)
#       out:                    ($ctCC,%rdLoc) [0 if file not found]
#                               $rdLoc{"ct","x"}
#                               x= 'posDssp', 'posPdb', 'aa', 'sec', 'acc'
#       note:                   returned values are relative solvent accessibility
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_RD_DSSP_CC";
    if (! -e $fileLoc){
	print "*** ERROR dsspGetCC: Dssp file '$fileLoc' missing\n";
	return(0);}
				# read file
    &open_file("$fhinLoc", "$fileLoc");
    $ctCC=0;%rdLoc=0;
    while (<$fhinLoc>) {	# take all cysteines
	if ((defined $chainLoc)&&($chainLoc ne " ")){
	    $chainRd=substr($_,12,1);
	    if ($chainRd ne $chainLoc){
		next;}}
	if (! /^ .... ....   [a-zC]/){ 
	    next;}
	++$ctCC;
	$_=~s/\n//g;
	$rdLoc{"$ctCC","posDssp"}=substr($_,1,5); $rdLoc{"$ctCC","posDssp"}=~s/\s//g;
	$rdLoc{"$ctCC","posPdb"}= substr($_,6,5); $rdLoc{"$ctCC","posPdb"}=~s/\s//g;
	$rdLoc{"$ctCC","aa"}=     substr($_,14,1); 
	$acc=substr($_,35,4);$acc=~s/\s//g;$ss= substr($_,17,1); 
				# convert secondary structure to 4 states
	$rdLoc{"$ctCC","acc"}=
	    &convert_acc("C",$acc); # external lib-prot.pl
				# convert secondary structure to 4 states
	$rdLoc{"$ctCC","sec"}=
	    &convert_sec($ss,"HEL"); # external lib-prot.pl
    }close($fhinLoc);
    $rdLoc{"NROWS"}=$ctCC;
    return($ctCC,%rdLoc);
}				# end of dsspGetCC

#==========================================================================================
sub hsspGetCCprof {
    local ($fileLoc,$chainLoc) = @_ ;
    local ($fhinLoc,$tmpName,$chainRd,$pos);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetCCprof                        
#                               
#       in:                     
#       out:                    
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_RD_HSSP_CC_PROF";
    %tmp=0;
    if (! -e $fileLoc){
	print "*** ERROR hsspGetCCprof: Hssp file '$fileLoc' missing\n";
	return(0);}
				# --------------------------------------------------
				# read file
    &open_file("$fhinLoc", "$fileLoc");
				# skip everything before profile
    while (<$fhinLoc>) { last if (/^\#\# SEQUENCE PROFILE AND ENTROPY/); }
				# read header of profile
    while (<$fhinLoc>) { $_=~s/\n//g;
			 $tmpName=substr($_,13);$tmpName=~s/^\s*|\s*$//g;
			 last;}
				# read profile
    while (<$fhinLoc>) { $_=~s/\n//g;
			 last if (/^\#\#|^\//);
			 $chainRd=substr($_,12,1);
			 if ( (defined $chainLoc)&&($chainLoc ne " ") ){
			     if ($chainRd ne $chainLoc){
				 next;}}
			 $pos=substr($_,7,4);$pos=~s/\s//g;
			 $tmp{"$pos"}=substr($_,13);$tmp{"$pos"}=~s/^\s*|\s+$//g;}close($fhinLoc);
    return($tmpName,%tmp);
}				# end of hsspGetCCprof

#==========================================================================================
sub compileStatCC {
    local ($fhLoc) = @_ ;
#    local ($fhinLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   compileStatCC                        
#                               
#       in:                     
#       out:                    
#--------------------------------------------------------------------------------
    $sep="\t";

    foreach $mode ("all","con","non"){
	print $fhLoc "$mode\n";
	printf $fhLoc 
	    "%3s$sep%-6s$sep%3s$sep%3s$sep%3s$sep%1s$sep%1s$sep%3s\n","des","id","pos",
	    "dssp","pdb","aa","ss","acc","RELENT";

	$ct{"H"}=$ct{"E"}=$ct{"L"}=$avRelent{"H"}=$avRelent{"E"}=$avRelent{"L"}=
	    $ctC=$avAcc=$avRelent=0;
	foreach $id (@idOk){
	    foreach $it (1..$res{"$id","nCC"}){
		if    (($mode eq "con") && ($res{"$id","$it","aa"} eq "C")){
		    next;}
		elsif (($mode eq "non") && ($res{"$id","$it","aa"} ne "C")){
		    next;}
		printf $fhLoc 
		    "%3s$sep%-6s$sep%3d$sep%3d$sep%3d$sep%1s$sep%1s$sep%3d$sep%3d\n",$mode,$id,$it,
		    $res{"$id","$it","posDssp"},$res{"$id","$it","posPdb"},
		    $res{"$id","$it","aa"},$res{"$id","$it","sec"},$res{"$id","$it","acc"},
		    $res{"$id","$it","RELENT"};
		$avAcc+=$res{"$id","$it","acc"};
		$avRelent+=$res{"$id","$it","RELENT"};
		$tmpSec=$res{"$id","$it","sec"};
		++$ct{"$tmpSec"};$avRelent{"$tmpSec"}+=$res{"$id","$it","RELENT"};
		++$ctC;
	    }
	}
	printf  $fhLoc "x.x %-20s %-4d\n","$mode: num C=",$ctC;
	printf  $fhLoc "x.x %-20s %-4d\n","$mode: ave acc=",($avAcc/$ctC);
	foreach $sec ("H","E","L"){
	    printf  $fhLoc "x.x %-20s %-4d\n","$mode: count $sec=",$ct{"$sec"};}
	printf  $fhLoc "x.x %-20s %-4d\n","$mode: ave relent=",($avRelent/$ctC);
	foreach $sec ("H","E","L"){
	    printf  $fhLoc "x.x %-20s %-4d\n","$mode: relent $sec=",$avRelent{"$sec"}/$ct{"$sec"};}
    }
    
	    
}				# end of compileStatCC

#==========================================================================================
sub subx {
#    local ($fileLoc) = @_ ;
#    local ($fhinLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   subx                        
#                               
#       in:                     
#       out:                    
#--------------------------------------------------------------------------------

}				# end of subx

