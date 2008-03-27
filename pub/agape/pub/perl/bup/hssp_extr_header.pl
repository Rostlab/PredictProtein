#!/usr/sbin/perl -w
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# hssp_extr_header
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hssp_extr_header.pl file_hssp
#
# task:		extracts the header of an HSSP file (or list thereof) and statistics: 
#               how many proteins with with pide>low and lenAli>lowLen ?
# 		
# subroutines   hssp_rd_header_loc
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       November,        1996           #
#			changed:       January	,    	1997           #
#			changed:       March	,    	1997           #
#			changed:       .	,    	1997           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

#local($fileIn,$fileOut,$fhout,$sep,@des,%ptr_form,%rd,$Lok,$des,$tmp_form,$tmp,$ct);
      
$[ =1 ;				# sets array count to start at 1, not at 0

push (@INC, "/home/rost/perl","/u/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# defaults
$lowPide=30;
$lowLali=40;
$lowLali=10;

if ($#ARGV<1){
    print"goal:   how many proteins with pide>low and lenAli>lowLen?\n";
    print"usage:  'script hssp_file' (list of files, or *.hssp)\n";
    print"   or:  'script options hssp_file1 hssp_file2' (list of files, e.g. with *)\n";
    print"option: low=30    (default=$lowPide)\n";
    print"        len=50    (default=$lowLali)\n";
    print"        up=95     (default=100, upper cut-off for PIDE)\n";
    print"        lowR12>x  (min for len1/len2 ratio, i.e., 0.5), \n";
    print"        lowR1A    (len1/lenAli), lowR2A (len2/lenAli)\n";
    print"        notStat   (by default histograms will be compiled)\n";
    print"        wrtRdb    (append all headers into RDB output file)\n";
    print"        notExcl   (don't exclude first hit, is for Hom Modelling statistics)\n";
    print"        title=XX  (output files will be named XX)\n";
    print"        fileOutRdb=x\n";
    print"        fileTrue=x (file with true PDB pairs, if not given not used)\n";
#    print"        chainId as (file.hssp_C, or chain=C)\n";
    exit;}

				# defaults
$interv= 2;			# compute histogram for every percentage point
@intervRatio=("1","0.8","0.6","0.4","0.2","0");
$fhin="FHIN";$fhout="FHOUT";$fhoutTrue="FHOUT_TRUE";$fhoutFalse="FHOUT_FALSE";$fhoutRdb="FHOUT_RDB";
$LexclSelf=1;

$lowPide=  0;			# minimal seq identity
$upPide= 100;			# maximal seq identity

$lowR12=   0;			# minimum for: len1/len2
$lowR1A=   0;			# minimum for: len1/lenAli
$lowR2A=   0;			# minimum for: len2/lenAli

$LwrtRdb=  0;			# write rdb output?
$Lstat=    1;			# by default: compile statistics

$LwrtRdb=  1;			# write rdb output?
$Lscreen=  1;
#$Lscreen=  0;
$Lscreen2= 0;

$sep=      "\t";		# separater for output (between columns)
$sepRdb=   "\t";

$title=    "";
				# desired column names
@desRd=    ("ID","STRID","IDE","WSIM","LALI","NGAP","LGAP","LEN2","ACCNUM","NAME",
	    "IFIR","ILAS","JFIR","JLAS");
@desOut=   ("ID","STRID","IDE","WSIM","LALI","NGAP","LGAP","LEN2","ACCNUM","NAME");
@desOutRdb=("ID1","ID","STRID","IDE","WSIM","LEN1","LEN2","LALI","NGAP","LGAP",
	    "IFIR","ILAS","JFIR","JLAS");
#	    "IFIR","ILAS","JFIR","JLAS","NAME");
				# perl printf formats
$ptr_form{"ID1"}=   "%-6s";
$ptr_form{"ID"}=    "%-10s";
$ptr_form{"STRID"}= "%-6s";
foreach $des ("LEN1","IDE","WSIM","LALI","NGAP","LGAP","LEN2","IFIR","ILAS","JFIR","JLAS"){
    $ptr_form{"$des"}="%4d";}
$ptr_form{"ACCNUM"}="%6s";
$ptr_form{"NAME"}=  "%-25s";

$#fileHssp=$LisList=0;
foreach $_ (@ARGV){
    if   (/^(low|lowPide)=(.+)$/){$lowPide=$2;    $lowPide=~s/\s//g;}
    elsif(/^(up|upPide)=(.+)$/)  {$upPide=$2;     $upPide=~s/\s//g;}
    elsif(/^file.*Rdb=(.+)$/)    {$fileOutRdb=$1; $fileOutRdb=~s/\s//g;}
    elsif(/^fileTrue=(.+)$/)     {$fileTrue=$1; $fileTrue=~s/\s//g;}
    elsif(/^(lowLen|len)=/)      {$_=~s/^.*[Ll]en=//g;$_=~s/\s//g;$lowLali=$_;}
    elsif(/^lowLali=/){$_=~s/^.*[Ll]en=//g;$_=~s/\s//g;$lowLali=$_;}
    elsif(/^lowR12=/) {$_=~s/^lowR12=//g;$_=~s/\s//g;$lowR12=$_;}
    elsif(/^lowR1A=/) {$_=~s/^lowR1A=//g;$_=~s/\s//g;$lowR1A=$_;}
    elsif(/^lowR2A=/) {$_=~s/^lowR2A=//g;$_=~s/\s//g;$lowR2A=$_;}
    elsif(/^title=/)  {$_=~s/^title=//g;$_=~s/\s//g;$title=$_;}
    elsif(/^chain=/)  {$_=~s/^chain=//g;$_=~s/\s//g;$chain=$_;}
    elsif(/^wrtRdb/)  {$LwrtRdb=1;}
    elsif(/^notExcl/) {$LexclSelf=0;}
    elsif(/^notStat/) {$Lstat=0;}
    elsif(/^not(_?[sS]creen|_?[vV]erbose)/) {$Lscreen=0;}
    else {
	$tmp=$_;$tmp=~s/\n//g;
	if    (&is_hssp($tmp)){	# external lib-prot.pl
	    push(@fileHssp,$tmp);}
	elsif (&is_hssp_list($tmp)){ # external lib-prot.pl
	    $LisList=1;$fileIn=$tmp;
	    &open_file("$fhin", "$tmp"); # external lib-ut.pl
	    while(<$fhin>){$_=~s/\n//g;
			   if(-e $_){push(@fileHssp,$_);}}close($fhin);}
	else {
	    print "*** unknown argument '$_' tmp=$tmp,\n";
	    exit;}}
}

$idMemory="";
if ($Lscreen){ print "--- settings:\n","--- low=$lowPide, up=$upPide, len=$lowLali"; 
	       if(! $LexclSelf){print" don't excl self,";}print",\n";}

if (length($title)<1){
    if ($LisList){
	$title=$fileIn;$title=~s/^.*\///g;$title=~s/\..*$//g;}
    else {
	$title="hsspExtrHeader";}}
$fileOut=         "Out-".     "$title"."-p"."$lowPide"."-l"."$lowLali";
$fileOutId=       "OutId-".   "$title"."-p"."$lowPide"."-l"."$lowLali".".list";
$fileOutSwiss=    "OutSwiss-"."$title"."-p"."$lowPide"."-l"."$lowLali".".rdb";
$fileOutDet=      "OutDet-".  "$title"."-p"."$lowPide"."-l"."$lowLali";
$fileOutHis=      "OutHis-".  "$title"."-p"."$lowPide"."-l"."$lowLali";
$fileOutDis=      "OutDis-".  "$title"."-p"."$lowPide"."-l"."$lowLali";
if (! defined $fileOutRdb){
    $fileOutRdb=   "Out-"."$title".".rdb";}
if (defined $fileTrue){		# separate true and false
    $fileOutDetTrue=$fileOutDet;$fileOutDetTrue=~s/Det-/DetT-/;
    $fileOutDetFalse=$fileOutDet;$fileOutDetFalse=~s/Det-/DetF-/;}

$#fileOut=0;
				# ------------------------------
				# read true pairs
if (defined $fileTrue){
    if (! -e $fileTrue){print "*** ERROR hssp_extr_header: fileTrue '$fileTrue' missing\n";
			exit;}
    &open_file("$fhin", "$fileTrue"); # external lib-ut.pl
    while(<$fhin>){$_=~s/\n//g;
		   ($tmp1,$tmp2)=split(/\t/,$_);
		   $id1=substr($tmp1,1,4); # purge chains
		   $tmp2=~s/,$//g;
		   @tmp2=split(/,/,$tmp2);
		   foreach $tmp2 (@tmp2){
		       $id2=substr($tmp2,1,4); # purge chains
		       if (! defined $true{"$id1,$id2"}){
			   $true{"$id1,$id2"}=1;}}}close($fhin);}
				# --------------------------------------------------
				# loop over all proteins
				# --------------------------------------------------

if ($LwrtRdb){			# RDB header
    &open_file("$fhoutRdb", ">$fileOutRdb");
    &wrtRdbHeader($fhoutRdb,$sepRdb,@desOutRdb); # other all global
    if ($Lscreen2){ 
	&wrtRdbHeader("STDOUT"," ",@desOutRdb);} # other all global
}

$ratioResCovered=$ctAll=0;$#idSwiss=$#idHssp=0;
foreach $fileIn (@fileHssp){
    if ($Lscreen){ print"--- now reading \t '$fileIn'\n"; }

    $idSeq=$fileIn;$idSeq=~s/^.*\/|\+5|\s|\.hssp.*$//g;
    %rd=0;
    %rd=&hssp_rd_header_loc($fileIn); # reader
    if (! %rd){
	print "*** ERROR no HSSP for '$fileIn'\n";
	next;}

    if ($rd{"LEN1"}==0){	# error?
	print "*** ERROR for it=$it, len1=0, file=$fileIn,\n";
	next;}
    if ($#fileHssp==1){		# ------------------------------
	&open_file("$fhout", ">$fileOut");
	&wrtSingle($fhout,$sep,@desOut); # write output file for single
	close($fhout);push(@fileOut,$fileOut);
	if ($Lscreen2){ 
	    &wrtSingle("STDOUT"," ",@desOut); }  # write output file for single
	if (! $LwrtRdb){
	    next;}}		# continue only to write RDB!!
				# store only file name, no path
    $rd{"ID1"}=$fileIn;$rd{"ID1"}=~s/^.*\///g;$rd{"ID1"}=~s/\.hssp.*$//g;
				# ------------------------------
				# loop over aligned protein pairs
    foreach $itSeq (1..$rd{"NROWS"}){
	$idStr=$rd{"$itSeq","ID"};
	if    ($rd{"$itSeq","IDE"}==1){ # exclude self
	    $flag{"$idSeq"}=1; $idMemory=$idSeq; 
	    if ($LexclSelf){
		next;}}
	elsif ("$idMemory" ne "$idSeq"){ # exclude first hitSeq <100 if none had 100
	    $flag{"$idSeq"}=1; $idMemory=$idSeq; 
	    if ($LexclSelf){
		next;}}
	if ((100*$rd{"$itSeq","IDE"})<$lowPide){ # minimal percentage seq identity
	    next;}
	if ((100*$rd{"$itSeq","IDE"})>$upPide){ # maximal percentage seq identity
	    next;}
	if ($rd{"$itSeq","LALI"}<=$lowLali){ # minimal length
	    next;}
	if (($rd{"$itSeq","LEN2"}==0)||($rd{"$itSeq","LALI"}==0)){ # error?
	    next;}
				# ratio cut off?
	if (($lowR12>0)&&(($rd{"len1"}/$rd{"$itSeq","LEN2"})<$lowR12)){
	    next;}
	if (($lowR1A>0)&&(($rd{"len1"}/$rd{"$itSeq","LALI"})<$lowR1A)){
	    next;}
	if (($lowR2A>0)&&(($rd{"$itSeq","LALI"}/$rd{"$itSeq","LEN2"})<$lowR2A)){
	    next;}
				# ------------------------------
	++$ct;			# statistics
	if ($Lstat){
	    $ratioResCovered+=($rd{"$itSeq","LALI"}/$rd{"$itSeq","LEN2"});
	    if ($Lscreen2){ 
		printf 
		    "%-30s$sep%-35s$sep%-5d$sep%-5d$sep%-6.2f\n",
		    $idSeq,$idStr,(100*$rd{"$itSeq","IDE"}),
		    $rd{"$itSeq","LALI"},($rd{"$itSeq","LALI"}/$rd{"$itSeq","LEN2"});}
				# store unique ids (avoid counting twice!)
	    if (! defined $flag{"$idStr"}){
		$flag{"$idStr"}=1;push(@idFound,$idStr);
		$res{"$idStr","idSeq"}= $idSeq;
		$res{"$idStr","pide"}=  100*$rd{"$itSeq","IDE"};
		$res{"$idStr","psim"}=  100*$rd{"$itSeq","WSIM"};
		$res{"$idStr","ratio"}= ($rd{"$itSeq","LALI"}/$rd{"$itSeq","LEN2"});
				# compute distance to threshold
		$res{"$idStr","distance"}=
		    ($res{"$idStr","pide"}-&getDistanceHsspCurve($rd{"$itSeq","LALI"}));
		$res{"$idStr","nIns"}=  $rd{"$itSeq","NGAP"};
		$res{"$idStr","lenIns"}=  $rd{"$itSeq","LGAP"};
		$res{"$idStr","lenAli"}=$rd{"$itSeq","LALI"};}
				# replace if higher identitSeqy
	    elsif (   ((defined $flag{"$idStr"})&&$flag{"$idStr"})&&(defined $res{"$idStr","pide"})
		   && ((100*$rd{"$itSeq","IDE"})>$res{"$idStr","pide"})){
		$res{"$idStr","idSeq"} =$idSeq;
		$res{"$idStr","pide"}=100*$rd{"$itSeq","IDE"};
		$res{"$idStr","psim"}=100*$rd{"$itSeq","WSIM"};
		$res{"$idStr","ratio"} =($rd{"$itSeq","LALI"}/$rd{"$itSeq","LEN2"});
		$res{"$idStr","distance"}=
		    ($res{"$idStr","pide"}-&getDistanceHsspCurve($rd{"$itSeq","LALI"}));
		$res{"$idStr","lenAli"}=$rd{"$itSeq","LALI"};}}
	push(@idHssp,$rd{"ID1"});push(@idSwiss,$rd{"$itSeq","ID"}); # store all Swiss (ids found)
	if ($LwrtRdb){		# writSeqe RDB output
	    ++$ctAll;
	    &wrtRdbLine($fhoutRdb,$sepRdb,$itSeq,@desOutRdb); # all global
	    if ($Lscreen2){
		&wrtRdbLine("STDOUT"," ",$itSeq,@desOutRdb); }} # all global
    }close($fhin);		# end of loop over all pairs
}				# end loop over proteins

if ($LwrtRdb && ($fhoutRdb ne "STDOUT")){ # close RDB file
    close($fhoutRdb);push(@fileOut,$fileOutRdb);}

if ($Lscreen){ 
    print "number of id's (unique) found=",$#idFound,"\n";
    print "write output into $fileOut\n";
    if ($Lstat){
	if ($ct==0){print "ratio covered=NN (ct=0)\n";}
	else {print "ratio covered=",($ratioResCovered/$ct),"\n";}}}
				# ------------------------------
				# all swiss ids
&open_file("$fhout", ">$fileOutSwiss");
print  $fhout "\# Perl-RDB\n\# \n","\# all proteins found\n\# \n";
printf $fhout "%-12s\t%-6s\n","idSwiss","idHssp";printf $fhout "%-12s\t%-6s\n","12","6";
foreach $it (1..$#idSwiss){printf $fhout "%-12s\t%-6s\n",$idSwiss[$it],$idHssp[$it];}
close($fhout);
				# ------------------------------
				# file with id's
if ($#idFound>0){&open_file("$fhout", ">$fileOutId");
		 foreach $id(@idFound){
		     print $fhout "$id\n";}close($fhout);
		 push(@fileOut,$fileOutId);
				# ------------------------------
				# file with details
		 &open_file("$fhout", ">$fileOutDet");
		 print $fhout "# distHssp = distance to HSSP threshold 25% on 80 residues\n";
		 printf $fhout 
		     "%-15s\t%-15s\t%-5s\t%-5s\t%-5s\t%-5s\t%-5s\t%-6s\t%8s",
		     "idSeq","idStr","pide","psim","lenAli","nIns","lenIns",
		     "ali/l2","distHssp";
		 if (defined $fileTrue){
		     printf $fhout "\t%-5s","ok?";}print $fhout "\n";
		 foreach $id(@idFound){
		     printf $fhout 
			 "%-15s\t%-15s\t%-5d\t%-5d\t%-5d\t%-5d\t%-5d\t%-6.2f\t%-8.2f",
			 $res{"$id","idSeq"},"$id",$res{"$id","pide"},$res{"$id","psim"},
			 $res{"$id","lenAli"},$res{"$id","nIns"},$res{"$id","lenIns"},
			 $res{"$id","ratio"},$res{"$id","distance"};
		     if (defined $fileTrue){
			 $tmpId1=substr($res{"$id","idSeq"},1,4);$tmpId2=substr($id,1,4);
			 if (defined $true{"$tmpId1,$tmpId2"}){
			     $true="true";} # different number
			 elsif (substr($tmpId1,2,3) eq substr($tmpId2,2,3)){ # same protein,
			     $true{"$tmpId1,$tmpId2"}=1;
			     $true="true";}
			 else{$true="false";}
#			 print "xx true=",$true,", for '$tmpId1,$tmpId2'\n";
			 printf $fhout "\t%-5s",$true;}print $fhout "\n";}close($fhout);
		 push(@fileOut,$fileOutDet);
				# ------------------------------
				# file with details for true
		 if (defined $fileTrue){
		     &open_file("$fhoutTrue", ">$fileOutDetTrue");
		     &open_file("$fhoutFalse", ">$fileOutDetFalse");
		     foreach $fhoutLoc("$fhoutTrue","$fhoutFalse"){
			 print $fhoutLoc  
			     "# distHssp = distance to HSSP threshold 25% on 80 residues\n";
			 printf $fhoutLoc 
			     "%-15s\t%-15s\t%-5s\t%-5s\t%-5s\t%-5s\t%-5s\t%-6s\t%8s\n",
			     "idSeq","idStr","pide","psim","lenAli","nIns","lenIns",
			     "ali/l2","distHssp";}
		     foreach $id(@idFound){
			 $tmpId1=substr($res{"$id","idSeq"},1,4);$tmpId2=substr($id,1,4);
			 if ($true{"$tmpId1,$tmpId2"}){
			     $fhoutLoc=$fhoutTrue;}
			 else {
			     $fhoutLoc=$fhoutFalse;}
			 printf $fhoutLoc
			     "%-15s\t%-15s\t%-5d\t%-5d\t%-5d\t%-5d\t%-5d\t%-6.2f\t%-8.2f\n",
			     $res{"$id","idSeq"},"$id",$res{"$id","pide"},$res{"$id","psim"},
			     $res{"$id","lenAli"},$res{"$id","nIns"},$res{"$id","lenIns"},
			     $res{"$id","ratio"},$res{"$id","distance"};}
		     close($fhoutTrue);close($fhoutFalse);
		     push(@fileOut,$fileOutDetTrue,$fileOutDetFalse);}}
				# ------------------------------
				# file with histograms
				# ini histo
if ($Lstat && ($#idFound>0)){
    &wrtHis;
}				# end of stat

				# ------------------------------
				# file with histogram of HSSP threshold distance
				# ini histo
if ($Lstat && ($#idFound>0)){
    &wrtDis;
}				# end of stat

if ($Lscreen){ 
    if ($Lstat){print"x.x $pideAll,\n";}
    print "output in files:"; foreach $file (@fileOut){print "$file,";}print"\n";}

exit;

#==========================================================================================
sub hssp_rd_header_loc {
    local ($file_hssp,@num) = @_ ;
    local (@des1,@des2,%ptr,$ptr,$len_strid,$Lis_long_id,$fhin,$Lget_all,
	   %rd,@tmp,$tmp,$beg,$mid,$end,$ct,$id,$strid,$des,$num,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hssp_rd_header_loc             reads the header of an HSSP file for numbers 1..$#num
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_HSSP_HEADER";
    if ($#num==0){$Lget_all=1;}else {$Lget_all=1;}

#    @des1=   ("IDE","WSIM","IFIR","ILAS","JFIR","JLAS","LALI","NGAP","LGAP","LEN2","ACCNUM");
#    @des2=   ("STRID");
    $#des1=$#des2=0;
    foreach $des (@desRd){
	if ($des =~/^STRID/){
	    push(@des2,$des);}
	else {
	    push(@des1,$des);}}

    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;
    $ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LEN2"}=10; $ptr{"ACCNUM"}=11;

    $len_strid=    4;		# minimal length to identify PDB identifiers

    if ( ! -e $file_hssp) {	# check existence
	return(0); }
				# ini
    $Lis_long_id=0;
				# get HSSP file/chain
    if (! -e $file_hssp){
	($tmp,$chain)=&hsspGefFile($file_hssp,$Lscreen); # external lib-prot.pl
	if ((! $tmp)||(! -e $tmp)){
	    return(0);}
	elsif (! &is_hssp($tmp)){ # external lib-prot.pl		
	    return(0);}
	elsif (&is_hssp_empty($tmp)){ # external lib-prot.pl
	    return(0);}
	$file_hssp=$tmp; }
				# ------------------------------
				# get begin and end of chain (not used, yet)
#    if (($chain =~/[A-Z0-9]/) && (defined $chain)){
#	($tmp,$beg,$end)=
#	    &hsspGetChainLength($file_hssp,$chain); # external lib-prot.pl
#    }
				# ------------------------------
				# read file
    &open_file("$fhin","$file_hssp");
    while ( <$fhin> ) {		# length, lond-id
	last if (/^\#\# PROTEINS/); 
	if (/^PARAMETER  LONG-ID :YES/) {$Lis_long_id=1;}
	elsif (/^SEQLENGTH /) {$_=~s/\n|\s|SEQLENGTH//g;
			       $rd{"len1"}=$rd{"LEN1"}=$_; } }
    $ct_taken=0;
    while ( <$fhin> ) { 
	last if (/^\#\# ALIGNMENTS/); 
	if (/^  NR\./){next;}	# skip describtors
	if ($Lis_long_id){
	    $beg=substr($_,1,56);$end=substr($_,109);$mid=substr($_,57,115); }
	else {
	    $beg=substr($_,1,28);$end=substr($_,90);$mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$|\n//g; # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks

				# begin: counter and id
	$ct=$beg;$ct=~s/\s*(\d+)\s+\:.*/$1/;$ct=~s/\s//g;
				# ------------------------------
	$Lok=0;			# read it?
	if (! $Lget_all) {
	    foreach $num (@num) {if ($ct eq "$num"){
		$Lok=1;
		last;}}
	    if (! $Lok){
		next;} }
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $Lis_long_id) {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=$beg;$strid=~s/$id|\s//g; }
	else {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=substr($_,49,6);$strid=~s/\s//g; }
	$tmp=$len_strid-1;
	if ( (length($strid)<$len_strid) && 
	    ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
	    $strid=substr($id,1,$len_strid); }
	$rd{"$ct","ID"}=$id;
	$rd{"$ct","STRID"}=$strid;
	$rd{"$ct","NAME"}=$end;
	++$ct_taken;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}
	foreach $des (@des1){ 
	    if ( ! defined $ptr{"$des"}) {
		next; }
	    $ptr=$ptr{"$des"};
	    $rd{"$ct","$des"}=$tmp[$ptr]; }
    }close($fhin);
    $rd{"NROWS"}=$ct_taken;
    return(%rd);
}				# end of hssp_rd_header_loc

#===============================================================================
sub wrtDis {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtDis                      writes histogram for distances from HSSP thresh
#       out:                    all GLOBAL
#-------------------------------------------------------------------------------
    $tmp=$interv;$#interv=0;
    while( (100-$tmp)>=($lowPide-100)){push(@interv,(100-$tmp));$tmp+=$interv;}
    foreach $tmp(@interv){foreach $des("dis","disT","disF"){$his{"$des","$tmp"}=0;}}
    foreach $id(@idFound){	# compile histo
	foreach $dist(@interv){
	    if ($res{"$id","distance"} >= $dist){
		++$his{"dis","$dist"};
		if (defined $fileTrue){
		    $tmpId1=substr($res{"$id","idSeq"},1,4);$tmpId2=substr($id,1,4);
		    if    ($true{"$tmpId1,$tmpId2"})  {++$his{"disT","$dist"};
#						  print "xx ok--->id=$id, true\n";
				       }
		    elsif (! $true{"$tmpId1,$tmpId2"}){++$his{"disF","$dist"};
#					   print "xx no,,,-id=$id, true\n";
				       }
		    else  { print "*** ERROR histogram id=$id, true not defined\n";}}
		last;}}}
				# write file
    &open_file("$fhout", ">$fileOutDis");
    printf $fhout "%-6s\t","dist"; # header
    @des=("dis","disCum");
    if (defined $fileTrue){push(@des,"disT","disF","disCumT","disCumF");}
    foreach $des(@des){printf $fhout "%-6s\t",$des;}
    print $fhout "\n";
    $distDis=0;			# x.x
    foreach $des(@des){
	$sum{"$des"}=0;}
    foreach $it(1..$#interv){		# body
	$dist=$interv[$#interv-$it+1];
	if ($his{"dis","$dist"}==0){ # ignore 0 counts
	    next;}
	printf $fhout "%-6s\t",$dist;
	foreach $des(@des){
	    if    ($des eq "dis")     {$sum{"$des"}+=$his{"$des","$dist"};
				       printf $fhout "%-6d\t",$his{"$des","$dist"};}
	    elsif ($des eq "disT")    {$sum{"$des"}+=$his{"$des","$dist"};
				       printf $fhout "%-6d\t",$his{"$des","$dist"};}
	    elsif ($des eq "disF")    {$sum{"$des"}+=$his{"$des","$dist"};
				       printf $fhout "%-6d\t",$his{"$des","$dist"};}
	    elsif ($des eq "disCum")  {printf $fhout "%-6d\t",$sum{"dis"};}
	    elsif ($des eq "disCumT") {printf $fhout "%-6d\t",$sum{"disT"};}
	    elsif ($des eq "disCumF") {printf $fhout "%-6d\t",$sum{"disF"};}
	    else                      {$sum{"$des"}+=$his{"$des","$dist"};
				       printf $fhout "%-6d\t",$sum{"$des"};}}
	$distDis+=$his{"dis","$dist"}; # x.x
	print $fhout "\n";}
    close($fhout); push(@fileOut,$fileOutDis);
}				# end of wrtDis

#===============================================================================
sub wrtHis {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHis                      writes histogram 
#       out:                    all GLOBAL
#-------------------------------------------------------------------------------
    $tmp=$interv;$#interv=0;
    while( (100-$tmp)>=$lowPide){
	push(@interv,(100-$tmp));$tmp+=$interv;}
    foreach $tmp(@interv){
	foreach $des("all","allT","allF",@intervRatio){$his{"$des","$tmp"}=0;}}
				# compile histo
    foreach $id(@idFound){
	foreach $pide(@interv){
	    if ($res{"$id","pide"} >= $pide){
		++$his{"all","$pide"};
		if (defined $fileTrue){
		    $tmpId1=substr($res{"$id","idSeq"},1,4);$tmpId2=substr($id,1,4);
		    if    ($true{"$tmpId1,$tmpId2"})  {
			++$his{"allT","$pide"};}
		    elsif (! $true{"$tmpId1,$tmpId2"}){++$his{"allF","$pide"};}
		    else { print "*** ERROR histogram id=$id, true not defined\n";}}
		foreach $ratio(@intervRatio){
		    if ($res{"$id","ratio"} >= $ratio){
			++$his{"$ratio","$pide"};
			last;}}
		last;}}}
				# write file
    &open_file("$fhout", ">$fileOutHis");
    printf $fhout "%-6s\t","pide"; # header
    @des=("all","allCum");
    if (defined $fileTrue){push(@des,"allT","allF","allCumT","allCumF");}push(@des,@intervRatio);
    foreach $des(@des){printf $fhout "%-6s\t",$des;}
    print $fhout "\n";

    $pideAll=0;			# x.x
    foreach $des(@des){
	$sum{"$des"}=0;}
    foreach $it(1..$#interv){		# body
	$pide=$interv[$#interv-$it+1];
	if ($his{"all","$pide"}==0){
	    next;}
	printf $fhout "%-6s\t",$pide;
	foreach $des(@des){
	    if    ($des eq "all")     {$sum{"$des"}+=$his{"$des","$pide"};
				       printf $fhout "%-6d\t",$his{"$des","$pide"};}
	    elsif ($des eq "allT")    {$sum{"$des"}+=$his{"$des","$pide"};
				       printf $fhout "%-6d\t",$his{"$des","$pide"};}
	    elsif ($des eq "allF")    {$sum{"$des"}+=$his{"$des","$pide"};
				       printf $fhout "%-6d\t",$his{"$des","$pide"};}
	    elsif ($des eq "allCum")  {printf $fhout "%-6d\t",$sum{"all"};}
	    elsif ($des eq "allCumT") {printf $fhout "%-6d\t",$sum{"allT"};}
	    elsif ($des eq "allCumF") {printf $fhout "%-6d\t",$sum{"allF"};}
	    else                      {$sum{"$des"}+=$his{"$des","$pide"};
				       printf $fhout "%-6d\t",$sum{"$des"};}}
	$pideAll+=$his{"all","$pide"}; # x.x
	print $fhout "\n";}
    close($fhout); push(@fileOut,$fileOutHis);
}				# end of wrtHis

#==========================================================================================
sub wrtSingle {
    local($fhoutLoc,$sepLoc,@desLoc)=@_;
    local($tmpSep,$tmpForm,$des,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtHeader                  writes header for output file (single conversion)
#--------------------------------------------------------------------------------
    $Lok=1;
    &wrtHeader($fhoutLoc);
    foreach $it (1..$#desLoc){		# print $fhoutLoc descriptors
	$des=$desLoc[$it];
	$tmpForm=$ptr_form{"$des"};$tmpForm=~s/d|\.\d+f/s/g;
	if ($it == $#desLoc) {$tmpSep="\n";}else {$tmpSep="$sepLoc";}
	printf $fhoutLoc "$tmpForm$tmpSep",$des; }
    
				# ------------------------------
    foreach $ct (1..$rd{"NROWS"}){ # print data
	foreach $it (1..$#desLoc){
	    $des=$desLoc[$it];
	    if ($it==$#desLoc) {$tmpSep="\n";}else {$tmpSep="$sepLoc";}
	    if (! defined $ptr_form{"$des"}){
		print "*** ERROR undefined ptr_form\{$des\}\n";
		exit;}
	    $tmpForm=$ptr_form{"$des"};

	    if (! defined $rd{"$ct","$des"}) {printf $fhoutLoc "$tmpForm$tmpSep"," ";
					      next;}
	    if ($des eq "NAME"){
		$tmp=substr($rd{"$ct","$des"},1,25);}
	    else {
		if ($des =~ /IDE|WSIM/){
		    $tmp=int(100*$rd{"$ct","$des"}); }
		else {
		    $tmp=$rd{"$ct","$des"}; }}
	    if (! defined $tmp){
		print "*** ERROR undefined res for des=$des,\n";
		exit;}
	    printf $fhoutLoc "$tmpForm$tmpSep",$tmp; }}
    print $fhoutLoc
	"--- \n",
	"--- MAXHOM ALIGNMENT: IN MSF FORMAT\n";
}				# end of wrtSingle

#==========================================================================================
sub wrtHeader {
    local ($fhoutLoc)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtHeader                  writes header for output file (single conversion)
#--------------------------------------------------------------------------------
    print $fhoutLoc
	"--- ------------------------------------------------------------\n",
	"--- MAXHOM multiple sequence alignment\n",
	"--- ------------------------------------------------------------\n",
	"--- \n",
	"--- MAXHOM ALIGNMENT HEADER: ABBREVIATIONS FOR SUMMARY\n",
	"--- ID           : identifier of aligned (homologous) protein\n",
	"--- STRID        : PDB identifier (only for known structures)\n",
	"--- PIDE         : percentage of pairwise sequence identity\n",
	"--- WSIM         : percentage of weighted similarity\n",
	"--- LALI         : number of residues aligned\n",
	"--- NGAP         : number of insertions and deletions (indels)\n",
	"--- LGAP         : number of residues in all indels\n",
	"--- LSEQ2        : length of aligned sequence\n",
	"--- ACCNUM       : SwissProt accession number\n",
	"--- NAME         : one-line description of aligned protein\n",
	"--- \n",
	"--- MAXHOM ALIGNMENT HEADER: SUMMARY\n";
}				# end of wrtHeader

#==========================================================================================
sub wrtRdbHeader {
    local($fhoutLoc,$sepLoc,@desLoc)=@_;
    local($itLoc,$des,$form,$formOut);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdbHeader                       
#--------------------------------------------------------------------------------
    print  $fhoutLoc "\# Perl-RDB \n\# \n";
    printf $fhoutLoc "%5s$sepLoc%5s$sepLoc","NoAll","NoOne";
    foreach $itLoc (1..$#desLoc){	# writLoce names
	$des=$desLoc[$itLoc];
	if ($itLoc == $#desLoc){$tmpSep="\n";}else{$tmpSep=$sepLoc;}
	$form=$ptr_form{"$des"};$form=~s/d|\.\d+f/s/g;
	printf $fhoutLoc "$form$tmpSep",$des;}
    printf $fhoutLoc "%5s$sepLoc%5s$sepLoc","5N","5N";
    foreach $itLoc (1..$#desLoc){	# writLoce formats
	$des=$desLoc[$itLoc];
	if ($itLoc == $#desLoc){$tmpSep="\n";}else{$tmpSep=$sepLoc;}
	$formOut=&form_perl2rdb($ptr_form{"$des"}); # external lib-prot.pl
	$form=$ptr_form{"$des"};$form=~s/d|\.\d+f/s/g;
	printf $fhoutLoc "$form$tmpSep",$formOut;}
}				# end of wrtRdbHeader

#==========================================================================================
sub wrtRdbLine {
    local($fhoutLoc,$sepLoc,$itIn,@desLoc)=@_;
    local($itLoc,$des,$form,$formOut);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdbLine                       
#--------------------------------------------------------------------------------
    printf $fhoutLoc "%5d$sepLoc%5d$sepLoc",$ctAll,$ct;
	
    foreach $itLoc (1..$#desLoc){	# writLoce data
	$des=$desLoc[$itLoc];
	if ($itLoc == $#desLoc){$tmpSep="\n";}else{$tmpSep=$sepLoc;}
	$form=$ptr_form{"$des"};
	if   ($des=~/^ID1|^LEN1/){
	    $tmp=$rd{"$des"};}
	elsif($des=~/^IDE|^WSIM/){
	    $tmp=100*$rd{"$itIn","$des"};}
	else {
	    $tmp=$rd{"$itIn","$des"};}
	printf $fhoutLoc "$form$tmpSep",$tmp;
    }
}				# end of wrtRdbLine


