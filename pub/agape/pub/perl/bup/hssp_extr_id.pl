#!/usr/sbin/perl -w
#
# extracts all sequence identifiers from HSSP files
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
$dirHssp="/data/hssp/";
$Lout=0;

if ($#ARGV<1){print"goal:    extracts all sequence identifiers from HSSP files\n";
	      print"usage:   script *.hssp (or list , chain=file.hssp_C)\n";
	      print"options: keywords (swiss,pdb)\n";
	      print"         file     (will write output files)\n";
	      print"         filePdb=x, fileSwiss=y (only those)\n";
	      print"         minDist=x (minimal distance from HSSP, default: all)\n";
	      exit;}

$fileIn=$ARGV[1];$#fileIn=$#chainIn=0;
$fhin="FHIN";$fhoutSwiss="FHOUT_SWISS";$fhoutPdb="FHOUT_PDB";

$Lswiss=$Lpdb=0;
foreach $_(@ARGV){next if ($_ eq $ARGV[1]);
		  if    ($_=~/^swiss/)           {$Lswiss=1;}
		  elsif ($_=~/^pdb/)             {$Lpdb=1;}
		  elsif ($_=~/^fileSwiss=(.+)$/) {$fileSwiss=$1;$Lout=1;}
		  elsif ($_=~/^filePdb=(.+)$/)   {$filePdb=$1;  $Lout=1;}
		  elsif ($_=~/^file/)            {$Lout=1;}
		  elsif ($_=~/^minDist=(.+)$/)   {$minDist=$1;}
	      }
if (($Lswiss+$Lpdb)==0){$Lswiss=$Lpdb=1;}

if (&is_hssp_list($fileIn)){
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\n//g;
		     ($file,$chain)=&getHsspFileLoc($_);
		     if (! $file){
			 next;}
		     if (&is_hssp($file)){
			 push(@fileIn,$file);push(@chainIn,$chain);}}close($fhin);}
else {				# list of files
    foreach $arg(@ARGV){
	next if ((defined $fileSwiss && $arg eq $fileSwiss) || 
		 (defined $filePdb   && $arg eq $filePdb));
	($file,$chain)=&getHsspFileLoc($arg); # 
	if (! $file){
	    next;}
	if (&is_hssp($file)){
	    push(@fileIn,$file);push(@chainIn,$chain);}}}
				# --------------------------------------------------
				# now read all
$#fileTmp=$#chainTmp=0;
foreach $it(1..$#fileIn){
    $file=$fileIn[$it];$chain=$chainIn[$it];
    print "xx try to read $file, $chain\n";
    next if (! -e $file);
    if ($chain ne " "){		# read particular chain
	($tmp,$beg,$end)=&hsspGetChainLength($file,$chain); # external lib-prot.pl
	@headerTmp=("ID","STRID","IFIR","ILAS");}
    else {			# read all chains (or no chain)
	@headerTmp=("ID","STRID");}
    if (defined $minDist){push(@headerTmp,"IDE","LALI");}
				# read header
    ($Lok,%rd)=&hsspRdHeader($file,@headerTmp);	# external lib-prot.pl
    next if (!$Lok);
    $fileTmp=$file;$fileTmp=~s/^.*\///g;$id=$strid="";
    foreach $it (1..$rd{"NROWS"}){
	if ($chain ne " "){	# read particular chain
	    $ifir=$rd{"IFIR","$it"};$ilas=$rd{"ILAS","$it"};
	    next if (($beg>$ilas)||($end<$ifir));}
	if (defined $minDist){	# minimal distance from HSSP curve
	    $dist=(100*$rd{"IDE","$it"})-&getDistanceHsspCurve($rd{"LALI","$it"});
	    $pide=100*$rd{"IDE","$it"};$lali=$rd{"LALI","$it"};
	    if ($dist<$minDist){
		print "xx min=$minDist, actual=$dist, pide=$pide, lali=$lali,\n";
		next;}}
	printf "--- %-15s %-5d %-15s ",$fileTmp,$it,$rd{"ID","$it"};
	if ((defined $rd{"STRID","$it"})&&($rd{"STRID","$it"}=~/[A-Za-z0-9]/)){
	    $rd{"STRID","$it"}=~s/_\?//g; # purge unknown chain
	    $strid.=$rd{"STRID","$it"}.",";
	    print " (",$rd{"STRID","$it"},")";}
	print "\n";
	$id.=$rd{"ID","$it"}.",";}
    $strid=~tr/[A-Z]/[a-z]/;
    push(@fileTmp,$fileTmp);push(@chainTmp,$chain);
    $res{"$fileTmp","id"}=$id;$res{"$fileTmp","strid"}=$strid;
}

				# output files?
if ($#fileTmp>0){
    if ($Lswiss && ($Lout || defined $fileSwiss)){
	if (!defined $fileSwiss){$fileSwiss="OutSwiss-".$$.".dat";}
	&open_file("$fhoutSwiss", ">$fileSwiss");$Lout=1;
	if (defined $minDist){
	    print $fhoutSwiss "\# minimal distance to HSSP-curve = $minDist\n";}
	print $fhoutSwiss "id1\tid2\n";}
    if ($Lpdb && ($Lout || defined $filePdb)){
	if (!defined $filePdb){$filePdb="OutPdb-".$$.".dat";}
	&open_file("$fhoutPdb", ">$filePdb");
	if (defined $minDist){
	    print $fhoutPdb "\# minimal distance to HSSP-curve = $minDist\n";}
	print $fhoutPdb "id1\tid2\n";}}

foreach $itFile(1..$#fileTmp){
    $file=$fileTmp[$itFile];$chain=$chainTmp[$itFile];
    $id1=$file;$id1=~s/\.hssp//g; if ($chain =~/[A-Za-z0-9]/){$id1.="_$chain";}
    if ($Lswiss){
	$res{"$file","id"}=~s/^,|,$//g;@tmp=split(/,/,$res{"$file","id"});
	$#tmp2=0; undef %ok;
	foreach $tmp(@tmp){if (!defined $ok{$tmp}){$ok{$tmp}=1;push(@tmp2,$tmp);}}
	@id2=sort @tmp2;$tmp="";foreach $id2(@id2){$tmp.="$id2".",";}$tmp=~s/,$//g;
	print "$id1\tswiss\t$tmp\n";
	if ($Lout){print $fhoutSwiss "$id1\t$tmp\n";}}

    if ($Lpdb){
	$res{"$file","strid"}=~s/^,|,$//g;@tmp=split(/,/,$res{"$file","strid"});
	$#tmp2=0; undef %ok;
	foreach $tmp(@tmp){if (!defined $ok{$tmp}){$ok{$tmp}=1;push(@tmp2,$tmp);}}
	@id2=sort @tmp2;$tmp="";foreach $id2(@id2){$tmp.="$id2".",";}$tmp=~s/,$//g;
	print "$id1\tpdb  \t$tmp\n";
	if ($Lout){print $fhoutPdb "$id1\t$tmp\n";}}
}
if ($Lout){if (defined $fileSwiss && -e $fileSwiss){print "output Swiss $fileSwiss\n";}
	   if (defined $filePdb && -e $filePdb)  {print "output Pdb   $filePdb\n";}}
exit;

#===============================================================================
sub getHsspFileLoc {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspFileLoc              returns chain and file
#       in:                     file.hssp_A
#       out:                    file.hssp,A
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getHsspFileLoc";$fhinLoc="FHIN"."$sbrName";

    $chainLoc=" ";
    if ((! -e $fileInLoc)&&($fileInLoc !~ /\.hssp/)) {
	$fileInLoc.=".hssp";}
    if ((! -e $fileInLoc)&&($fileInLoc !~ /^\/data|^\/sander|^\/purple|^\/home/)){
	$fileInLoc.=$dirHssp.$fileInLoc;}
    if ((! -e $fileInLoc)&&($fileInLoc =~ /hssp_.$/)){
	$chainLoc=$fileInLoc;$chainLoc=~s/^.*\.hssp_(.)$/$1/;$fileInLoc=~s/_.$//g;}
    if (! -e $fileInLoc){
	print "-*- no HSSP $fileInLoc\n";
	return(0,0);}
    return($fileInLoc,$chainLoc);
}				# end of getHsspFileLoc

