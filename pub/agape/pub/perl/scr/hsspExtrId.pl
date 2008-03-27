#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# extracts all sequence identifiers from HSSP files
#
$[ =1 ;

$dirHssp="/data/hssp/";
$Lout=0;

if ($#ARGV<1){print "goal:    extracts all sequence identifiers from HSSP files\n";
	      print "usage:   script *.hssp (or list , chain=file.hssp_C)\n";
	      print "options: keywords \n";
	      print "         <swiss|pdb>\n";p
	      print "         file     (will write output files)\n";
	      print "         filePdb=x, fileSwiss=y (only those)\n";
	      print "         minDist=x (minimal distance from HSSP, default: all)\n";
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
	    $dist=(100*$rd{"IDE","$it"})-&getDistanceHsspNewCurve($rd{"LALI","$it"});
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
	$fileSwiss="OutSwiss-".$$.".dat" if (!defined $fileSwiss);
	open($fhoutSwiss, ">".$fileSwiss) || 
	    die("*** ERROR failed to open out fileSwiss=$fileSwiss!\n");
	$Lout=1;
	print $fhoutSwiss "\# minimal distance to HSSP-curve = $minDist\n"
	    if (defined $minDist);
	print $fhoutSwiss "id1\tid2\n";
    }
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
	foreach $tmp(@tmp){
	    if (!defined $ok{$tmp}){$ok{$tmp}=1;push(@tmp2,$tmp);}}
	@id2=sort @tmp2;$tmp="";foreach $id2(@id2){$tmp.="$id2".",";}$tmp=~s/,$//g;
	print "$id1\tswiss\t$tmp\n";
	print $fhoutSwiss "$id1\t$tmp\n" if ($Lout);
    }

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



#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub complete_dir { return(&completeDir(@_)); } # alias

#===============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir

#==============================================================================
sub getDistanceHsspCurve {
    local ($laliLoc,$laliMaxLoc) = @_ ;
    $[=1;
#--------------------------------------------------------------------------------
#   getDistanceHsspCurve        computes the HSSP curve for in:    ali length
#       in:                     $lali,$lailMax
#                               note1: thresh=0 for HSSP, 5 for 30%, -5 for 20% ..
#                               note2: saturation at 100
#       out:                    value curve (i.e. percentage identity)
#                               HSSP-curve  according to t(L)=(290.15 * L ** -0.562)
#--------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceHsspCurve";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);
    $laliMaxLoc=100             if (! defined $laliMaxLoc);
    $laliLoc=~s/\s//g;

    $laliLoc=$laliMaxLoc        if ($laliLoc > $laliMaxLoc);	# saturation
    $val= 290.15*($laliLoc **(-0.562)); 
    $val=100                    if ($val > 100);
    $val=25                     if ($val < 25);
    return ($val,"ok $sbrName");
}				# end getDistanceHsspCurve

#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc,$tmp)=@_; 
    local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

#==============================================================================
sub hsspGetChainLength {
    local ($fileIn,$chainLoc) = @_ ;
    local ($file_hssp,$ct,$tmp,$beg,$end,$pos);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChainLength          extracts the length of a chain in an HSSP file
#       in:                     hssp_file,chain,
#       out:                    $length,$ifir,$ilas
#--------------------------------------------------------------------------------
    $fileIn=~s/\s//g;$fileIn=~s/\n//g;
    $file_hssp=$fileIn; $Lchain=1; 
    $Lchain=0                   if ($chainLoc eq "*" || ! &is_chain($chainLoc)); 
    if (! -e $file_hssp){
	print "*** ERROR hsspGetChainLength: no HSSP=$fileIn,\n"; 
	return(0,"*** ERROR hsspGetChainLength: no HSSP=$fileIn,");}
    &open_file("FHIN", "$file_hssp") ||
	return(0,"*** ERROR hsspGetChainLength: failed opening HSSP=$fileIn,");

    while ( <FHIN> ) { 
	last if (/^ SeqNo/); }
    $ct=$pos=0;
    while ( <FHIN> ) { 
	last if (/^\#\# /);
	++$pos;$tmp=substr($_,13,1);
	if    ( $Lchain && ($tmp eq $chainLoc) ) { ++$ct; }
	elsif ( ! $Lchain )                      { ++$ct; }
	elsif ( $ct>1 ) {
	    last;}
	$beg=$pos if ($ct==1); } close(FHIN);
    $end=$pos;
    return($ct,$beg,$end);
}				# end of hsspGetChainLength

#==============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#                               kwd  = noSearch -> no DB search
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
    if (-d $Lscreen) { 
	@dir=($Lscreen,@dir);
	$Lscreen=0;}
    $fileInLoc=~s/\s|\n//g;
				# ------------------------------
				# is HSSP ok
    return($fileInLoc," ")      if (-e $fileInLoc && &is_hssp($fileInLoc));

				# ------------------------------
				# purge chain?
    if ($fileInLoc=~/^(.*\.hssp)_?([A-Za-z0-9])$/){
	$file=$1; $chainLoc=$2;
	return($file,$chainLoc) if (-e $file && &is_hssp($file)); }

				# ------------------------------
				# try adding directories
    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/hssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/hssp/") if (!$Lok); # give default

				# ------------------------------
				# before trying: purge chain
    $file=$fileInLoc; $chainLoc=" ";
    $file=~s/^(.*\.hssp)_?([A-Za-z0-9])$/$1/; 
    $chainLoc=$2 if (defined $2);
				# loop over all directories
    $fileHssp=
	&hsspGetFileLoop($file,$Lscreen,@dir);
    return($fileHssp,$chainLoc) if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
                                # still not: dissect into 'id'.'chain'
    $tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
    $fileHssp=
        &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
    return($fileHssp,$chainLoc)    if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
				# change version of file (1sha->2sha)
    $tmp1=substr($idLoc,2,3);
    foreach $it (1..9) {
        $tmp_file="$it"."$tmp1".".hssp";
        $fileHssp=
            &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
	last if ($fileHssp ne "0");}
    return (0)                  if ( ! -e $fileHssp || &is_hssp_empty($fileHssp));
    return($fileHssp,$chainLoc);
}				# end of hsspGetFile

#===============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# missing extension
    $fileInLoop.=".hssp"        if ($fileInLoop !~ /\.hssp/);
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	$tmp=~s/\/\//\//g;	# '//' -> '/'
	print "--- hsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_hssp($tmp) );
    }
    return(0);			# none found
}				# end of hsspGetFileLoop

#==============================================================================
sub hsspRdHeader {
    local ($fileInLoc,@kwdInLoc) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,
	   @kwdDefHsspTopLoc,@kwdDefHsspHdrLoc,@kwdHsspTopLoc,@kwdHsspHdrLoc,@tmp,
	   $regexpBegHeader,$regexpEndHeader,$regexpLongId,$lenStrid,$LisLongId,
	   %ptr,$kwd,$Lok,$Lpdb,$des,$beg,$end,$mid,$ct,$id,$strid,$ptr,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdHeader                reads a HSSP header
#       in:                     $fileHssp (must exist), 
#         @kwdInLoc             = one of the default keywords 
#                               (@kwdLocHsspTop,@kwdLocHsspHeader)
#       in:                     'nopair' surpresses reading of pair information
#       out:                    for top  (e.g. NALIGN): $rd{"kwd"}
#                               for prot (e.g. LALI):   $rd{"kwd","$it"}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#         special               ID=ID1, $rd{"kwd","$it"} existes for ID1 and ID2
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdHeader";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if (! -e $fileInLoc || ! &is_hssp($fileInLoc) ){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# settings describing format
    @kwdDefHsspTopLoc= ("PDBID","DATE","SEQBASE","PARAMETER","THRESHOLD",
			"REFERENCE","HEADER","COMPND","SOURCE","AUTHOR",
			"SEQLENGTH","NCHAIN","KCHAIN","NALIGN");
    @kwdDefHsspHdrLoc= ("NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
			"JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN");
    $regexpBegHeader=   "^\#\# PROTEINS"; # begin of reading 
    $regexpEndHeader=   "^\#\# ALIGNMENTS"; # end of reading
    $regexpLongId=      "^PARAMETER  LONG-ID :YES"; # identification of long id

    $lenStrid=          4;	# minimal length to identify PDB identifiers
    $LisLongId=         0;	# long identifier names

    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;$ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LSEQ2"}=10; $ptr{"ACCNUM"}=11;

				# ------------------------------
				# check input arguments
    $#kwdHsspTopLoc=$#kwdHsspHdrLoc=$Lpdb=$LnoPair=0;
    foreach $kwd (@kwdInLoc){
	$Lok=0;
	if ($kwd eq "nopair"){
	    $LnoPair=1;
	    next;}
	$Lpdb=1 if (! $Lpdb && ($kwd =~/^PDBID/));
	foreach $des (@kwdDefHsspTopLoc)   {
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspTopLoc,$kwd);
			       last;}}
	next if ($Lok || $LnoPair);
	foreach $des (@kwdDefHsspHdrLoc){
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspHdrLoc,$kwd);
			       last;} }
	print "-*- WARNING $sbrName input kwd=$kwd, makes no sense??\n" if (! $Lok);}

				# force reading of NALI
    push(@kwdHsspTopLoc,"PDBID") if (! $Lpdb);
	
				# get column numbers to read
				# ------------------------------
				# now start to read
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName HSSP file could not be opened '$fileInLoc'\n";
		return(0);}
    undef %tmp;		# save space
				# ------------------------------
    while ( <$fhinLoc> ) {	# read top
	last if ($_ =~ /$regexpBegHeader/); 
	if ($_ =~ /$regexpLongId/) {
	    $LisLongId=1;}
	else{$_=~s/\n//g;$arg=$_;
	     foreach $des (@kwdHsspTopLoc){
		 if ($arg  =~ /^$des\s+(.+)$/){
		     if (defined $ok{"$des"}){ # multiple lines!
			 $tmp="$1"."\t";
			 if  (defined $tmp{"$des"}){
			     $tmp{"$des"}.=$tmp;}
			 else{$tmp{"$des"}=$tmp;}}
		     else {$ok{"$des"}=1;$tmp{"$des"}=$1;}
		     if ($des=~/SEQLENGTH|NCHAIN|KCHAIN|NALIGN/){
			 $tmp{"$des"}=~s/^(\d+)[^0-9]+.*$/$1/;} # purge blanks
		     last;}}}}
				# ------------------------------
    $ct=0;			# read header
    while ( <$fhinLoc> ) { 
	last if ($LnoPair);	# supress reading pair info
	last if ($_ =~ /$regexpEndHeader/); 
	next if ($_ =~ /^  NR\./); # skip descriptors
	$_=~s/\n//g;
	$lenLine=length($_);
	if ($LisLongId){
	    $maxMid=115; $maxMid=($lenLine-56) if ($lenLine < 115);
	    $maxEnd=109; $maxEnd=$lenLine  if ($lenLine < 109);
	    $beg=substr($_,1,56);
	    $end=0; $end=substr($_,109)        if ($lenLine >=109);
	    $mid=substr($_,57,115); }
	else {
	    $maxMid= 62; $maxMid=($lenLine-28) if ($lenLine <  90);
	    $beg=substr($_,1,28);
	    $end=0; $end=substr($_,90)         if ($lenLine >=90);
	    $mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$//g;   # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	if ($lenLine > 86) {
	    $accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g ; }
	else {
	    $accnum=0;}
				# begin: counter and id
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $LisLongId) {$id=$beg;$id=~s/([^\s]+).*$/$1/;
			   $strid=$beg;$strid=~s/$id|\s//g; }
	else              {$id=$beg;$id=~s/(.+_\S+).*/$1/;
			   $strid=substr($_,49,6);$strid=~s/\s//g; }
	    $tmp=$lenStrid-1;
	if ( (length($strid)<$lenStrid) && ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
	    $strid=substr($id,1,$lenStrid); }
	++$ct;

	$tmp{"ID","$ct"}=     $id;
	$tmp{"NR","$ct"}=     $ct;
	$tmp{"STRID","$ct"}=  $strid;
				# correct for ID = PDBid
	$tmp{"STRID","$ct"}=  $id if ($strid=~/^\s*$/ && &is_pdbid($id));
	    
	$tmp{"PROTEIN","$ct"}=$end;
	$tmp{"ID1","$ct"}=$tmp{"PDBID"};
	$tmp{"ACCNUM","$ct"}=$accnum;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}

	foreach $des (@kwdHsspHdrLoc){ 
	    next if ( ! defined $ptr{"$des"});
	    next if ( $des =~/^ACCNUM/);
	    $ptr=$ptr{"$des"};
	    $tmp{"$des","$ct"}=$tmp[$ptr]; }}close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    $#kwdInLoc=$#kwdDefHsspHdrLoc=$#kwdHsspTopLoc=$#tmp=
	$#kwdDefHsspTopLoc=$#kwdHsspHdrLoc=0;
    undef %ptr;
    return(1,%tmp);
}				# end of hsspRdHeader

#==============================================================================
sub is_chain {
    local($tmp) = @_ ;
#-------------------------------------------------------------------------------
#   is_chain                    checks whether or not a PDB chain
#       in:                     character
#       out:                    1,0
#-------------------------------------------------------------------------------
    return(0) if (! defined $tmp);
    return(1) if ($tmp=~/[A-Z0-9]/);
    return(0);
}				# end of is_chain

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
	
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || 
	do {print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	    return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1) if ($tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#==============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#==============================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     next if (length($fileRd)<5);
		     ($fileLoc,$chainLoc)= 
			 &hsspGetFile($fileRd,$LscreenLoc);
		     $Lis=1 if (&is_hssp($fileLoc));
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#==============================================================================
sub is_pdbid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    return 1
	if ((length($id) <= 6) &&
	    ($id=~/^[0-9][0-9a-z]{3,3}[^0-9a-z]?/));
    return 0;
}				# end of is_pdbid

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
# library collected (end)
#==============================================================================

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

