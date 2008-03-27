#!/usr/sbin/perl -w
#
# extracts file with fold libraries (and probs) from TOPITS aliList\n";
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl";require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
				# ------------------------------
				# ini (a.a)
@kwd=           ("exeFsspExtrIde","dirFssp","fileOutList","fileOutRdb","verbose","debug");
@kwdFsspLibProb=("pdbId","prob","homosId");
$fhout="FHOUT";

$par{"exeFsspExtrIde"}="/home/rost/perl/scr/fssp_ide_ali.pl";
$par{"argFsspExtrIde"}="up=95 zmin=3 ";
$par{"dirFssp"}=       "/data/fssp/";

$par{"fileOutList"}=   "unk";
$par{"fileOutRdb"}=    "unk";

$par{"verbose"}=       1;
$par{"debug"}=         0;
				# ------------------------------
				# help
if ($#ARGV<1){print"goal:    extracts file with fold libraries (and probs) from TOPITS aliList\n";
	      print"usage:   'script aliList'\n";
	      print"options: \n";
	      foreach $kwd (@kwd){print "         $kwd='x' (def: ",$par{"$kwd"},")\n";}
	      exit;}
				# ------------------------------
$fileIn=$ARGV[1]; shift @ARGV;	# digest command line
foreach $arg (@ARGV){ 
    $Lok=0;
    foreach $kwd (@kwd){
	if ($arg=~/^$kwd=/){$arg=~s/^.*=//g;$arg=~s/\s//g;
			    $par{"$kwd"}=$arg;$Lok=1;
			    last;}}
    if (!$Lok){print"*** unrecognised argument '$arg'\n";
	       exit;}}
foreach $des ("fileOutList","fileOutRdb"){ # change output file names
    if ($par{"$des"} eq "unk"){$par{"$des"}=$fileIn;$par{"$des"}=~s/dssp/fsspPairs/;
			       if ($par{"$des"} eq $fileIn){$par{"$des"}="XX-".$par{"$des"};}}
    if ($des eq "fileOutRdb") {$par{"$des"}=~s/\.list/\.rdb/;}}
				# ------------------------------
$#fileTmp=0;			# temporary files
$fileTmpFsspList="List-fssp".$$.".tmp";$fileOutError="Error-missing-fssp".$$.".tmp";
$fileTmpOrphans="Orphans-fssp".$$.".tmp";
$fileTmpIdpairs="Idpairs-fssp".$$.".tmp";
$fileTmpOut=    "Out-fssp".$$.".tmp";

				# ------------------------------
				# convert TOPITS aliList to FSSP
$Lok= &convDsspList2FsspList($fileIn,$fileTmpFsspList,$fileOutError,
			     $fileTmpFsspList,$par{"dirFssp"});

push(@fileTmp,$fileTmpFsspList); # temporary
				# ------------------------------
				# extract information from FSSP
$arg= $par{"exeFsspExtrIde"}." $fileTmpFsspList ".$par{"argFsspExtrIde"}." file=".$fileIn;
$arg.=" fileOut=$fileTmpOut fileOutIdpairs=$fileTmpIdpairs fileOutOrphans=$fileTmpOrphans";

print "--- system \t '$arg'\n";
system ("$arg");		# call fssp_ide_ali.pl

foreach $file ("$fileTmpOut","$fileTmpIdpairs","$fileTmpOrphans"){ # temporary
    if (-e $file){ push(@fileTmp,$file);}}
				# ------------------------------
				# read ids from lists
@rd=
    &getIds($fileTmpIdpairs,$fileTmpOrphans);
				# ------------------------------
				# write list
$fileOut=$par{"fileOutList"};
$Lok=       &open_file("$fhout",">$fileOut");
if (! $Lok){print "*** ERROR fssp_extr_foldLibProb.pl: fileOut=$fileOut, not opened\n";
	    die;}
foreach $rd(@rd){print $fhout "$rd\n";}close($fhout);
				# ------------------------------
				# write RDB
$Lok= 
    &getFsspPairList($fileOut,$par{"fileOutRdb"});
				# ------------------------------
                                # consistency check
%lib=
    &getFsspLibProb($par{"fileOutRdb"},@kwdFsspLibProb);

@tmp=split(/,/,$lib{"all"});
print "xx consistency check (all pairs):\n";
foreach $tmp (@tmp){
    print "xx $tmp, p=",$lib{"prob","$tmp"},", homos=",$lib{"homosId","$tmp"},",\n";}

if (! $par{"debug"}){
    foreach $file (@fileTmp){ unlink $file;}}

print "--- output in files: ";
foreach $des ("fileOutList","fileOutRdb"){ print $par{"$des"},",";}print"\n";
exit;


#===============================================================================
sub convDsspList2FsspList {
    local($fileInLoc,$fileOutLoc,$fileOutNotLoc,$dirFsspLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convDsspList2FsspList       reads in a list of dssp files (from Topits aliList)
#                               and returns list of fssp files
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."convDsspList2FsspList";
    $fhinLoc="FHIN"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";$fhoutNotLoc="FHOUT_NOT"."$sbrName";
    $LscreenLoc2=0;

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOutLoc' not opened\n";
		return(0);}
    $Lok=       &open_file("$fhoutNotLoc",">$fileOutNotLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOutNotLoc' not opened\n";
		return(0);}

    while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			if (length($_)==0){
			    next;}
			$_=~s/^.*\///g;	# purge before dir
			$_=~s/dssp|hssp//g; $_=~s/[_!\.]//g;
			if (length($_)<4){
			    print "xx strange=$_, rd=$tmp,\n";
			    next;}
			$id=$_;
			$fssp=&fsspGetFile($id,$LscreenLoc2,$dirFsspLoc);
			if (-e $fssp){
			    print $fhoutLoc "$fssp\n";}
			else {
			    print $fhoutNotLoc "-*- $sbrName missing FSSP=$fssp, for id=$id, \n";}}
    close($fhinLoc);close($fhoutLoc);
    return(1);
}				# end of convDsspList2FsspList

#===============================================================================
sub getFsspPairList {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$sepLoc,$tmp,$Lok,$tmpId,$tmpMatchList,$id,
	  @idRd,@idTot,@tmp,%Lok,%rd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFsspPairList             reads file written by fssp_ide_ali.pl
#       in:                     file with: 'idGuide  id1,id2,...'
#                                      or: 'idGuide  none'
#       out:                    RDB file ($fileOut):
#                                    'idGuide  prob(=Nhomos/N_folds_in_library)  idList'
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getFsspPairList";$fhinLoc="FHIN"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";
    $sepLoc="\t";		# for RDB file: separation of columns by sepLoc

    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
				# ------------------------------
    $#idRd=$#idTot=0;		# read file
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if (length($_)==0){
	    next;}
	$_=~s/_//g;		# delete HSSP chain identifier _
	@tmp=split(/\t/,$_); foreach $tmp (@tmp){$tmp=~s/\s//g;} # split 'idGuide  id1,id2,..'
	if (! defined $Lok{"$tmp[1]"}){	# collect unique list
	    push(@idTot,$tmp[1]); $Lok{"$tmp[1]"}=1; }
	push(@idRd,$tmp[1]);$tmpId=$tmp[1]; $tmpMatchList=$tmp[2]; $tmpMatchList=~s/^,*|,*$//g;
	$rd{"id","$tmpId"}=$tmpMatchList;
	@tmp=split(/,/,$tmpMatchList);foreach $tmp(@tmp){$tmp=~s/\s//g;} # split list of homologues
	$rd{"n","$tmpId"}=$#tmp;
	if ($tmpMatchList eq "none"){
	    next;}
	foreach $idMatch(@tmp){
	    if (! defined $Lok{"$idMatch"}){
		push(@idTot,$idMatch); $Lok{"$idMatch"}=1; }}}close($fhinLoc);

				# ------------------------------
				# write new file
    $Lok=&open_file("$fhoutLoc",">$fileOutLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    print $fhoutLoc "# Perl-RDB\n","# \n","# FSSP pairs and counts\n","# \n",;
    printf $fhoutLoc "# %-20s : %6d (total number of chains in fold library)\n","NTOT",$#idTot;
    printf $fhoutLoc "# %-20s : %-s\n","NOTATION PDBid","PDB (4 char) + chain (1 char) identifier";
    printf $fhoutLoc 
	"# %-20s : %-s\n","NOTATION PROB","=Nhits/NTOT, i.e. chance of hitting on family";
    printf $fhoutLoc "# %-20s : %-s\n","NOTATION HOMOS","PDB + chain identifiers of homologues";
				# names and formats
    printf $fhoutLoc "%15s$sepLoc%10s$sepLoc%s\n","pdbId","prob","homosId";
    printf $fhoutLoc "%15s$sepLoc%10s$sepLoc%s\n","15","10.8F"," ";
    foreach $id (@idRd){
	printf $fhoutLoc 
	    "%-15s$sepLoc%10.8f$sepLoc%-s\n",$id,($rd{"n","$id"}/$#idTot),$rd{"id","$id"}; }
    return(1);
}				# end of getFsspPairList

#===============================================================================
sub getFsspLibProb {
    local ($fileInLoc,@desLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFsspLibProb              reads the file with the fold families
#       in:                     file
#       out:                    $rd{"all"}                -> idGuide1,idGuid2,...
#                               $rd{"allN"}               -> number of folds read
#                               $rd{"homosId","$idGuide"} -> matching familiy for idGuide
#                               $rd{"prob","$idGuide"}    -> probability of random hit for idGuide
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getFsspLibProb";$fhinLoc="FHIN"."$sbrName";

    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){
	print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
	return(0);}
				# read RDB file
				#    keywords should be 'pdbId,prob,homosId'
    %rdLoc=
	&rdRdbAssociative($fileInLoc,"body",@desLoc);
				# convert
    $rd{"all"}="";$#idAll=0;
    foreach $it (1..$rdLoc{"NROWS"}){
	foreach $kwd (@desLoc){	# purge blanks
	    if (!defined $rdLoc{"$kwd","$it"}){
		print "-*- WARNING $sbrName rdLoc it=$it, kwd=$kwd, not defined\n";}
	    else { $rdLoc{"$kwd","$it"}=~s/\s//g;}}
	$id=$rdLoc{"pdbId","$it"};
	push(@idAll,$id);$rd{"all"}.="$id,";
	foreach $kwd (@desLoc){
	    $rd{"$kwd","$id"}=$rdLoc{"$kwd","$it"};}}
    return(%rd);
}				# end of getFsspLibProb

#===============================================================================
sub getIds {
    local($fileInLoc1,$fileInLoc2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getIds                      reads ids from the files written by fssp_ide_ali.pl
#      in (file formats):
#                               file 1: idpairs
#                                   1ak2    2ak3_B,2ak3_A,
#                                   2ak3A   1ak2,
#                               file 2: orphans
#                                   /data/fssp/1aep.fssp
#                                   /data/fssp/1aep.fssp
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getIds";$fhinLoc="FHIN"."$sbrName";
				# read idpairs
    $Lok=       &open_file("$fhinLoc","$fileInLoc1");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc1' not opened\n";
		return(0);}
    $ct=0;
    while (<$fhinLoc>) {$_=~s/\n//g;$_=~s/,$//g;
			if (length($_)==0){
			    next;}++$ct;
			$rd{"pair","$ct"}="$_";}close($fhinLoc);$rd{"pair","NROWS"}=$ct;
				# read orphans
    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc2' not opened\n";
		return(0);}
    $ct=0;
    while (<$fhinLoc>) {$_=~s/\n//g;$_=~s/^.*\///g;$_=~s/\.fssp//g;
			if (length($_)==0){
			    next;}++$ct;
			$rd{"orph","$ct"}="$_\tnone";}close($fhinLoc);$rd{"orph","NROWS"}=$ct;
				# ------------------------------
				# sort
    $#tmp=0;			# 1pdb -> pdb
    foreach $des ("pair","orph"){
	foreach $it(1..$rd{"$des","NROWS"}){
	    ($tmp1,$tmp)=split(/\s+/,$rd{"$des","$it"});
	    $id=substr($tmp1,2);
	    $ptr{"$id"}="$des,$it";
	    push(@tmp,$id);}}
    @tmpSort=sort (@tmp);
    foreach $id (@tmpSort){
	($des1,$des2)=split(/,/,$ptr{"$id"});
	push(@tmpFin,$rd{"$des1","$des2"});
    }
    return(@tmpFin);
}				# end of getIds

#===============================================================================
sub subx {
#    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#         c
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

