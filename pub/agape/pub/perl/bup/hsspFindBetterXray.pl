#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="takes a list produced by scr hsspExtrNaliXray.pl \n".
    "     \t and finds alternative PDBs in HSSP if resolution too high";
#  
#
$[ =1 ;
				# ------------------------------
foreach $arg(@ARGV){		# include libraries
    last if ($arg=~/dirLib=(.*)$/);}
$dir=$1 || "/home/rost/perl/" || $ENV{'PERLLIB'}; 
$dir.="/" if (-d $dir && $dir !~/\/$/);
$dir= ""  if (! defined $dir || ! -d $dir);
foreach $lib("lib-ut.pl","lib-br.pl"){
    require $dir.$lib || 
 	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}

				# ------------------------------
				# defaults
%par=(
      'dirPdb',       "/home/rost/data/pdb/",            # directory of PDB
      'extPdb',       ".brk",	                         # extension of PDB
      'dirHssp',      "/home/rost/data/hssp/",           # dir HSSP
      'extHssp',      ".hssp", 
      'fsspTable2',   "/home/rost/data/fssp/TABLE2",     # FSSP table giving 'id1' is similar to 'id2'
      '', "", 
      'fileOut',      0,	# file with overall statistics
      'fileOutOk',    0,	# list of those matching condition (original or new: one line per original)
      'fileOutNo',    0,	# list of those not matching (original file)
      'fileMissPdb',  "Missing-pdb.list",  # missing pdb files
      'fileMissHssp', "Missing-hssp.list", # missing HSSP files
      '', "", 
      '', "", 
      );
$sep="\t";
$resMax=1107;
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file-hssp.dat (from hsspExtrNaliXray.pl) | list.hssp | *.hssp'\n";
    print "opt: \t \n";
    print "     \t nali=(ge|gt|le|lt)x : only those with nali    >=,>,<=,< x\n";
    print "     \t len=(ge|gt|le|lt)x  : only those with length  >=,>,<=,< x\n";
    print "     \t res=(ge|gt|le|lt)x  : only those with respective X-ray resolution\n";
    print "     \t \n";
    print "     \t noali               -> don NOT look up NALIGN\n";
    print "     \t nolen               -> don NOT look up SEQLENGTH\n";
    print "     \t nores               -> don NOT look up PDB resolution\n";
    print "     \t \n";
    print "     \t fileOut=x           (current (name nali len res) best (name nali len res))\n";
    print "     \t fileOutOk=x         (all which fulfill condition)\n";
    print "     \t fileOutNo=x         (all which dont)\n";
#    print "     \t \n";
    if (defined %par){
	foreach $kwd (@kwd){
	    printf "     \t %-20s=%-s (def)\n",$par{"$kwd"};}}
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$Lnoali=$Lnolen=$Lnores=0;
				# ------------------------------
$#fileIn=0;			# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)            { $fileOut=$1;}
    elsif ($arg=~/^fileOutOk=(.*)$/)          { $fileOutOk=$1;}
    elsif ($arg=~/^fileOutNo=(.*)$/)          { $fileOutNo=$1;}
    elsif ($arg=~/^nali=([glet]+)(\d+)$/)     { $naliExcl=$2; $modeNali=$1;}
    elsif ($arg=~/^len=([glet]+)(\d+)$/)      { $lenExcl=$2;  $modeLen= $1;}
    elsif ($arg=~/^res=([glet]+)([\d\.]+)$/)  { $resExcl=$2;  $modeRes= $1;}
    elsif ($arg=~/^noali$/)                   { $Lnoali=1;}
    elsif ($arg=~/^nolen$/)                   { $Lnolen=1;}
    elsif ($arg=~/^nores$/)                   { $Lnores=1;}
#    elsif ($arg=~/^=(.*)$/) { $=$1;}
    else  {$Lok=0;
	   if (-e $arg){$Lok=1;
			push(@fileIn,$arg);}
	   if (! $Lok && defined %par){
	       foreach $kwd (keys %par){
		   if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					      last;}}}
	   if (! $Lok){print"*** wrong command line arg '$arg'\n";
		       die;}}}
$fileIn=$fileIn[1];
$par{"dirPdb"}.="/"                 if ($par{"dirPdb"}!~/\/$/);
$par{"extPdb"}=".".$par{"extPdb"}   if ($par{"extPdb"}!~/^\./);
$par{"dirHssp"}.="/"                if ($par{"dirHssp"}!~/\/$/);
$par{"extHssp"}=".".$par{"extHssp"} if ($par{"extHssp"}!~/^\./);

die ("missing input $fileIn\n") if (! -e $fileIn);
				# ------------------------------
				# output file name
$tmp=$fileIn;$tmp=~s/^.*\///g;
$tmp2="";
if (defined $naliExcl){$tmp2.="nali-";
		       $tmp2="gt".$naliExcl."-"  if ($modeNali eq "gt");
		       $tmp2="ge".$naliExcl."-"  if ($modeNali eq "ge");
		       $tmp2="lt".$naliExcl."-"  if ($modeNali eq "lt");
		       $tmp2="le".$naliExcl."-"  if ($modeNali eq "le"); }
if (defined $lenExcl) {$tmp2.="len-";
		       $tmp2="gt".$lenExcl."-"  if ($modeLen eq "gt");
		       $tmp2="ge".$lenExcl."-"  if ($modeLen eq "ge");
		       $tmp2="lt".$lenExcl."-"  if ($modeLen eq "lt");
		       $tmp2="le".$lenExcl."-"  if ($modeLen eq "le"); }
if (defined $resExcl) {$tmp2.="res-";
		       $tmp2="gt".$resExcl."-"  if ($modeRes eq "gt");
		       $tmp2="ge".$resExcl."-"  if ($modeRes eq "ge");
		       $tmp2="lt".$resExcl."-"  if ($modeRes eq "lt");
		       $tmp2="le".$resExcl."-"  if ($modeRes eq "le"); }
if (! defined $fileOut)  { 
    if (defined $par{"fileOut"} && $par{"fileOut"}) {
	$fileOut=$par{"fileOut"}; }
    else {
	$fileOut="Out-".$tmp2.$tmp;} }
if (! defined $fileOutOk){
    if (defined $par{"fileOutOk"} && $par{"fileOutOk"}) {
	$fileOutOk=$par{"fileOutOk"}; }
    else {
	$fileOutOk="Out-ok-".$tmp2.$tmp; } }
if (! defined $fileOutNo){
    if (defined $par{"fileOutNo"} && $par{"fileOutNo"}) {
	$fileOutNo=$par{"fileOutNo"}; }
    else {
	$fileOutNo="Out-no-".$tmp2.$tmp; } }
if (! defined $fileOutBest){
    if (defined $par{"fileOutBest"} && $par{"fileOutBest"}) {
	$fileOutBest=$par{"fileOutBest"}; }
    else {
	$fileOutBest="Out-best-".$tmp2.$tmp; } }

				# ------------------------------
				# (0) read input list
				# ------------------------------
print "--- $scrName: read list '$fileIn'\n";
&open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
$#fileIn=0; $it=0; undef %fin;
while (<$fhin>) { $_=~s/\n//g;
		  next if (length($_)<5);
		  @tmp=split(/[\s\t]+/,$_);
		  ++$it;
		  $file=$tmp[1];
		  if ($#tmp > 1) {
		      $nali=$tmp[2];$nali=~s/\s//g;
		      $len= $tmp[3];$len=~s/\s//g;
		      $res= $tmp[4];$res=~s/\s//g;
		      $fin{"nali","$it"}=$nali; $fin{"len","$it"}=$len; $fin{"res","$it"}=$res; }
		  if ($file=~/\.hssp_[A-Z0-9]/){ # purge chain
		      $file=~s/(\.hssp)_[A-Z0-9]/$1/;}
		  push(@fileIn,$file);  } close($fhin);
				# --------------------------------------------------
				# (1) read FSSP table to find alternatives
				# --------------------------------------------------
($Lok,$msg,%tmp)=
    &fsspRdTable2($par{"fsspTable2"},"nochain");
if (! $Lok){ print "*** $scrName: failed reading FSSP table=",$par{"fsspTable2"},".\n",$msg,"\n";
	     exit;}
undef %fssp; 
foreach $it (1..$tmp{"NROWS"}){
    ($id,@tmp)=split(/,/,$tmp{"$it"});
    foreach $id2 (@tmp){
	next if ($id2 eq $id);
	$fssp{"$id"}=""         if (! defined $fssp{"$id"});
	$fssp{"$id"}.="$id2,";}
    $fssp{"$id"}=~s/,*$//       if (defined $fssp{"$id"}); }

				# --------------------------------------------------
				# (2) read file(s)
                                # --------------------------------------------------
$#missPdb=$#missHssp=$ctNmr=0;
undef %res;
foreach $itfile (1..$#fileIn){
    $fileIn=$fileIn[$itfile];
    $resIn= $fin{"res","$itfile"};
    $idIn=$fileIn;$idIn=~s/^.*\/|\.hssp.*$//g;

    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $Lok=1;
    print "--- work on $fileIn, res=$resIn\n";
				# ------------------------------
				# first find alternatives
				# ------------------------------
				# grep in HSSP
    ($Lok,$msg,$other)=
	&hsspGrepPdbid($fileIn);
    return(&errSbrMsg("failed on grepping PDBids from $fileIn",$msg)) if (! $Lok);

				# FSSP given?
    $other.=",".$fssp{"$idIn"}  if (defined $fssp{"$idIn"});
    $other=~s/,,+/,/g;

    next if (length($other)<3);	# skip if no alternative structure found

				# avoid repetitions
    @other=split(/,/,$other);
    undef %tmp; $#tmp=0;
    foreach $id (@other){
	next if (defined $tmp{"$id"});
	next if ($id eq $idIn);
	$tmp{"$id"}=1; push(@tmp,$id);}
    @other=@tmp;
				# ------------------------------
				# check alternatives for resolution
    $res{"$itfile"}="";
    foreach $id (@other){
	next if (length($id)<4);
	$Lno=0;			# is HSSP existing?
	$fileNew=$par{"dirHssp"}.$id.$par{"extHssp"};
	if (! -e $fileNew) { push(@missHssp,$fileNew); 
			     $Lno=1;}
				# is PDB existing?
	$filePdb=$par{"dirPdb"}. $id.$par{"extPdb"};
	if (! -e $filePdb) { push(@missPdb,$filePdb); 
			     print "-*- HSSP $id ok, but no PDB ($filePdb)\n";
			     $Lno=1;}
	next if ($Lno);
				# grep resolution
	($Lok,$msg,$res)=
	    &pdbGrepResolution($filePdb,0,0,$resMax);
	return(&errSbrMsg("failed on grepping PDB resolution from $filePdb",$msg)) if (! $Lok);
	$res{"$itfile"}.="$id,";
	$res{"$itfile","$id"}=$res; }
				# ------------------------------
				# find best resolution
    $min=$resMax;
    foreach $id (@other){
	next if (! defined $res{"$itfile","$id"});
	if ($res{"$itfile","$id"} < $min) {
	    $idMin=$id;
	    $min=$res{"$itfile","$id"};}}     
    $res{"$itfile"}=~s/,*$//g;
    next if ($min >= $resIn);	# flop 1: best not better than original

				# ------------------------------
				# if better one found: grep stuff
				# ------------------------------
    $fileNew=$par{"dirHssp"}.$idMin.$par{"extHssp"};
    if (! -e $fileNew) { print "-*- looks fine for $idMin, res=$min, but no HSSP=$fileNew\n";
			 exit; }
				# grep NALIGN
    ($Lok,$msg,$nali)=
	&hsspGrepNali($fileNew,0,0);
#	&hsspGrepNali($fileNew,$naliExcl,$modeNali);
    return(&errSbrMsg("failed on grepping NALI from $fileNew",$msg)) if (! $Lok);
				# grep SEQLENGTH
    ($Lok,$msg,$len)=
	&hsspGrepLen($fileNew,0,0);
#	&hsspGrepLen($fileNew,$lenExcl,$modeLen);
    return(&errSbrMsg("failed on grepping LEN from $fileNew",$msg)) if (! $Lok);
				# ------------------------------
				# store
    $fin{"newfile","$itfile"}=  $fileNew;
    $fin{"newnali","$itfile"}=  $nali;
    $fin{"newlen","$itfile"}=   $len;
    $fin{"newres","$itfile"}=   $min;
}

				# ------------------------------
				# (3) condition fulfilled?
$#fileOk=$#fileNo=0;
foreach $itfile (1..$#fileIn){
    $Lok=0;
    if (defined $fin{"newfile","$itfile"}){
	$Lok1=&conditionFulfilled($fin{"newnali","$itfile"},$naliExcl,$modeNali);
	$Lok2=&conditionFulfilled($fin{"newlen","$itfile"}, $lenExcl, $modeLen);
	$Lok3=&conditionFulfilled($fin{"newres","$itfile"}, $resExcl, $modeRes);
	if ($Lok1 && $Lok2 && $Lok3){
	    push(@fileOk,$fin{"newfile","$itfile"});
	    $Lok=1;}}
    else {
	$Lok1=&conditionFulfilled($fin{"nali","$itfile"},$naliExcl,$modeNali);
	$Lok2=&conditionFulfilled($fin{"len","$itfile"}, $lenExcl, $modeLen);
	$Lok3=&conditionFulfilled($fin{"res","$itfile"}, $resExcl, $modeRes);
	if ($Lok1 && $Lok2 && $Lok3){
	    push(@fileOk,$fileIn[$itfile]);
	    $Lok=1;}}
    if (! $Lok){
	push(@fileNo,$fileIn[$itfile]);}}
	    
				# ------------------------------
				# (4) write output
&open_file("$fhout",">$fileOut"); 
printf $fhout 
    "#%-30s$sep%5s$sep%5s$sep%8s$sep%-30s$sep%5s$sep%5s$sep%8s$sep%5s\n",
    "original","NALI","LEN","RES","best","NALI","LEN","RES","which";

foreach $itfile (1..$#fileIn){
    $tmp= sprintf("%-s",      $fileIn[$itfile]);
    $tmp.=sprintf("$sep%5d",  $fin{"nali","$itfile"});
    $tmp.=sprintf("$sep%5d",  $fin{"len","$itfile"});
    $tmp.=sprintf("$sep%8.2f",$fin{"res","$itfile"});

    if (defined $fin{"newfile","$itfile"}){
	++$ctNmr                if ($fin{"newres","$itfile"} == $resMax);
	push(@fileBest,$fin{"newfile","$itfile"});
	$file=$fin{"newfile","$itfile"}; $file=~s/^.*\//yyyy\//;
	$tmp.=sprintf("$sep%-s",  $file);
	$tmp.=sprintf("$sep%5d",  $fin{"newnali","$itfile"});
	$tmp.=sprintf("$sep%5d",  $fin{"newlen","$itfile"});
	$tmp.=sprintf("$sep%8.2f",$fin{"newres","$itfile"});
	$tmp.=sprintf("$sep%5s",  "best");}

    else {
	++$ctNmr                if ($fin{"res","$itfile"} == $resMax);
	push(@fileBest,$fileIn[$itfile]);
	$file=$fileIn[$itfile]; $file=~s/^.*\//yyyy\//;
	$tmp.=sprintf("$sep%-s",  $file);
	$tmp.=sprintf("$sep%5s",  "dito");
	$tmp.=sprintf("$sep%5s",  "dito");
	$tmp.=sprintf("$sep%8s",  "dito");
	$tmp.=sprintf("$sep%5s",  "orig");}
    $tmp.="\n";
    
    print $tmp;
    printf $fhout $tmp; }
close($fhout);
				# best
&open_file("$fhout",">$fileOutBest"); 
foreach $file (@fileBest){
    print $fhout "$file\n";} close($fhout);
				# ok
&open_file("$fhout",">$fileOutOk"); 
foreach $file (@fileOk){
    print $fhout "$file\n";} close($fhout);
				# not
&open_file("$fhout",">$fileOutNo"); 
foreach $file (@fileNo){
    print $fhout "$file\n";} close($fhout);
				# missing HSSP
&open_file("$fhout",">".$par{"fileMissHssp"}); 
undef %ok;
foreach $file (sort @missHssp){
    next if (defined $ok{$file});
    $ok{$file}=1;
    print $fhout "$file\n";} close($fhout);
				# missing PDB
undef %ok;
&open_file("$fhout",">".$par{"fileMissPdb"}); 
foreach $file (@missPdb){
    next if (defined $ok{$file});
    $ok{$file}=1;
    print $fhout "$file\n";} close($fhout);

				# ------------------------------
				# all alternatives
foreach $itfile (1..$#fileIn){
    $file=$fileIn[$itfile];$id=$file;$id=~s/^.*\/|\.hssp//g;
    printf "%5s %6.1f ",$id,$fin{"res","$itfile"};
    if (! defined $res{"$itfile"} || (length($res{"$itfile"})<4)){
	print "\n";
	next;}
    @id=split(/,/,$res{"$itfile"});
    foreach $id (@id){
	printf "%5s %6.1f ",$id,$res{"$itfile","$id"};
    }
    print "\n"; }
	
print "--- output in     all=$fileOut\n";
print "---              best=$fileOutBest\n";
print "---                ok=$fileOutOk,\n";
print "---                no=$fileOutNo \n";
print "---      missing hssp=",$par{"fileMissHssp"},"\n"  if (-e $par{"fileMissHssp"});
print "---      missing  pdb=",$par{"fileMissPdb"}, "\n"  if (-e $par{"fileMissPdb"});
print "--- statistics:\n";
print "--- \n";
print "--- ok = ",$#fileOk,"\n";
print "--- not= ",$#fileNo,"\n";
print "--- nmr= ",$ctNmr,"\n"   if ($ctNmr>0);
print "--- all= ",$#fileBest,"\n";
exit;

#===============================================================================
sub conditionFulfilled {
    local($numLoc,$exclLoc,$modeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   conditionFulfilled          returns 1 if condition fulfilled, 0 else
#       in:                     $exclLoc=    limit for LEN  (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       out:                    1|0,msg,$len (0 if condition not fulfilled)
#-------------------------------------------------------------------------------
    $sbrName="conditionFulfilled";$fhinLoc="FHIN_"."conditionFulfilled";
				# restrict?
    $tmp=$numLoc; $Lok=1;
    if (defined $exclLoc && $exclLoc) { 
	$Lok=0  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	$Lok=0  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	$Lok=0  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	$Lok=0  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }
    return($Lok);
}				# end of conditionFulfilled

#===============================================================================
sub fsspRdTable2 {
    local($fileInLoc,$modeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fsspRdTable2                returns the pairs from TABLE2
#       in:                     $fileInLoc,$mode="nochain" -> chain ignored, i.e., 1cseI = 1cseE
#       out:                    1|0,msg,$tmp{} with
#                               $tmp{"NROWS"}= number of primary (second id in file)
#                               $tmp{"$it"}=   'id of primary,@id_all_similar_ones'
#                                              where @id is a list separated by ','
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fsspRdTable2";$fhinLoc="FHIN_"."fsspRdTable2";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $modeLoc=0                                     if (! defined $modeLoc || $modeLoc ne "nochain");
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# ------------------------------
				# read file
    while (<$fhinLoc>) {
	last if ($_=~/^PDBid/);	# thereafter the list starts
    }
    undef %tmp;$ct=0; undef %ok;
				# ------------------------------
    while (<$fhinLoc>) {	# read pairs
	$_=~s/\n//g;
	next if (length($_)<10);
	($id1,$idMaster,@tmp)=split(/[\s\t]+/,$_);
				# purge chain
	$idMaster=substr($idMaster,1,4) if ($modeLoc eq "nochain");

	if (! defined  $ok{$idMaster}){ ++$ct;
					$ok{$idMaster}=$ct;
					$tmp{"$ct"}="$idMaster,"; }
	$pos=$ok{$idMaster};
				# purge chain
	$id1=substr($id1,1,4)           if ($modeLoc eq "nochain");
				# avoid repeats
	next if (defined $ok{"$idMaster","$id1"});
	$tmp{"$pos"}.="$id1,";
	$ok{"$idMaster","$id1"}=1;
    } close($fhinLoc);
				# ------------------------------
				# fin
    $tmp{"NROWS"}=$ct;
    foreach $it (1..$ct){
	$tmp{"$it"}=~s/,*$//g;}
    undef %ok;			# slick-is-in !
    return(1,"ok $sbrName",%tmp);
}				# end of fsspRdTable2

