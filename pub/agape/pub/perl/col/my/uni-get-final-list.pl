#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="do the following steps:\n".
    "     \t (1) fssp_rd_table1.pl on list from FSSP TABLE1\n".
    "     \t (2) run hsspExtrNaliXray.pl on OUT1\n".
    "     \t (3) run 'hsspFindBetterXray.pl OUT2-nochn.dat len=gt30 res=lt2.5'\n".
    "     \t (4) hand filtering on the lists (or take as are)\n".
    "     \t (5) run 'wrt_rdbSort.pl OUT4-sorted.rdb col=4 incr nonum' (rdb file)\n".
    "     \t (6) run this script on OUT5 for final list";
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
      'dirHssp',     "/home/rost/data/hssp/",
      'fsspTable2',  "/home/rost/data/fssp/TABLE2",
      '', "",			# 
      );
@kwd=sort (keys %par);
$ptr{"name"}=1;
$ptr{"nali"}=2;
$ptr{"len"}= 3;
$ptr{"res"}= 4;

				# ------------------------------
if ($#ARGV<2){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName RDB-file file-with-list-of-hssp+chain '\n";
    print  "          watch it: assumes col1=name, 2=nali, 3=len, 4=resolution\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","nali",   "(ge|gt|le|lt)x","only those with nali >=,>,<=,< x";
    printf "      %-15s  %-20s %-s\n","len",    "(ge|gt|le|lt)x","only those with res  >=,>,<=,< x";
    printf "      %-15s  %-20s %-s\n","res",    "(ge|gt|le|lt)x","only those with len  >=,>,<=,< x";
#    printf "      %-15s  %-20s %-s\n","noScreen", "no value","";
    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("      %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("      %-15s  %-20s %-s\n","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("      %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("      %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=$#chainIn=0;
$fileIn[1]=$ARGV[1];
$fileChain=$ARGV[2];
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    next if ($arg eq $ARGV[2]);
    if    ($arg=~/^fileOut=(.*)$/)            { $fileOut=$1;}
    elsif ($arg=~/^nali=([glet]+)(\d+)$/)     { $naliExcl=$2; $modeNali=$1;}
    elsif ($arg=~/^len=([glet]+)(\d+)$/)      { $lenExcl=$2;  $modeLen= $1;}
    elsif ($arg=~/^res=([glet]+)([\d\.]+)$/)  { $resExcl=$2;  $modeRes= $1;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");}
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input rdb=$fileIn\n")      if (! -e $fileIn);
die ("missing input chain=$fileChain (must be 2nd argument!!)\n") if (! -e $fileChain);

$fsspTable2=$par{"fsspTable2"};
die ("missing fssp TABLE2=$fsspTable2\n") if (! -e $fsspTable2);


if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
$par{"dirHssp"}.="/"            if ($par{"dirHssp"} !~ /\/$/);

				# ------------------------------
				# (1) read chains
print "--- read chains $fileChain\n";
&open_file("$fhin", "$fileChain") || die '*** $scrName ERROR opening file $fileIn';
$#id=$#idnochn=0; undef %id; undef %idnochn; undef %chn;
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge dir
    $_=~s/\.hssp//g;		# purge extension
    $_=~s/_//g;
    $id=$_; $idnochn=substr($_,1,4);
    push(@id,$id);           $id{$id}=1;
    push(@idnochn,$idnochn); $idnochn{$idnochn}=1;
    $chn{"$idnochn"}=""         if (! defined $chn{"$idnochn"});
    if ($id eq $idnochn){
	$chn{"$idnochn"}.=" "; }
    else {
	$chn{"$idnochn"}.=substr($id,5,1); }
}
close($fhin);

				# --------------------------------------------------
				# (2) read FSSP table to find alternatives
				# --------------------------------------------------
($Lok,$msg,%tmp)=
    &fsspRdTable2($par{"fsspTable2"});
#    &fsspRdTable2($par{"fsspTable2"},"nochain");
if (! $Lok){ print "*** $scrName: failed reading FSSP table=",$par{"fsspTable2"},".\n",$msg,"\n";
	     exit;}
undef %fssp; 
foreach $it (1..$tmp{"NROWS"}){
    ($id,@tmp)=split(/,/,$tmp{"$it"});
#    if (length($id) > 4) {$id=substr($id,1,4)."_".substr($id,5,1); }
    
				# note id is taken in the HSSP list with chains
				#      id2 are all names that are similar to id
    foreach $id2 (@tmp){
	next if ($id2 eq $id);
	$fssp{"$id"}=""         if (! defined $fssp{"$id"});
	$fssp{"$id"}.="$id2,";
				# back pointer from id2 (the one that may appear in the
				#      input RDB file) and id_master (the one in the
				#      HSSP list with chains)
	$tmp=substr($id2,1,4);
	$fssp2nochn{"$tmp"}=""  if (! defined $fssp2nochn{"$tmp"}) ;
	$fssp2nochn{"$tmp"}.="$id2,";
	$fssp2ptr{"$id2"}=$id;
    }
    $fssp{"$id"}=~s/,*$//       if (defined $fssp{"$id"}); 
}


				# --------------------------------------------------
				# (3) loop on RDB file(s)
				# --------------------------------------------------
$ctok=$ctnmr=$ctno=0;
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
				# ------------------------------
				# read RDB file(s)
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
    $ctDanger=$ct=0;		# read
    $#danger=0;
    while (<$fhin>) {
	next if ($_=~/^\#/);	# skip comments
	++$ct;
	next if ($ct==1);	# skip names
	next if ($ct==2 && $_=~/\d+[NFS]?[\s\t]+|[\s\t]+\d+[NFS]?/); # skip formats
	++$it;
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);
	foreach $tmp (@tmp) {
	    $tmp=~s/\s//g; }
	$ncol=$#tmp            if ($#tmp > $ncol);
	foreach $itcol (1..$#tmp){
	    $rd[$it][$itcol]=$tmp[$itcol];
	    $Lnum[$itcol]=1    if (! defined $Lnum[$itcol]);     # ini: all numerical
	    $Lnum[$itcol]=0    if ($tmp[$itcol] !~ /^[\d\.]+$/); # non numerical
	}
    }
    $nrow=$it;
    close($fhin);
				# ------------------------------
				# process exclusion
    $#many=$#danger=$#ok=$#nmr=$#no=0;
    if (! defined $naliExcl && ! defined $lenExcl && ! defined $resExcl){
	foreach $itrow(1..$nrow){
	    push(@ok,$itrow);}}
    else {
	foreach $itrow (1..$nrow){
	    $Lok=1;
				# check exclusion
	    if (defined $naliExcl) {
		$ptr=$ptr{"nali"};
		$Lok=&conditionFulfilled($rd[$itrow][$ptr],$naliExcl,$modeNali); }
	    if ($Lok && defined $lenExcl) {
		$ptr=$ptr{"len"};
		$Lok=&conditionFulfilled($rd[$itrow][$ptr],$lenExcl,$modeLen); }
	    if ($Lok && defined $resExcl) {
		$ptr=$ptr{"res"};
		$res=$rd[$itrow][$ptr];
		$Lok=&conditionFulfilled($rd[$itrow][$ptr],$resExcl,$modeRes); }
	    if ($Lok){
		push(@ok,$itrow);
		next; }
	    if ($res > 100){
		push(@nmr,$itrow); }
	    else {
		push(@no,$itrow);} }}

    undef %done; undef @skip;
				# ------------------------------
				# process names
    foreach $itrow (1..$nrow){
	$ptr=$ptr{"name"};
	$name=$rd[$itrow][$ptr];
	$name=~s/^.*\/|\.hssp//g;
	$name=substr($name,1,4); # purge to simple
	$name[$itrow]=$name;
	if (! defined $done{$name}){
	    $done{$name}=1; }

	else {			# avoid duplications!!
	    $skip[$itrow]=1; 
	    push(@many,$name);
	    next; }

	if (defined $idnochn{$name}){
	    $chn[$itrow]=$chn{"$name"};  # note: not comma separated!
	    next; }

				# print now the problem: find corresponding ones
	if (defined $fssp2nochn{"$name"}) {
				# first find all this matches to
	    $fssp2nochn=$fssp2nochn{"$name"};  $fssp2nochn=~s/,*$//g;
	    @id2=       split(/,/,$fssp2nochn);
	    $ct=0;
	    undef $chn[$itrow];
	    foreach $it (1..$#id2){
		$id1=$fssp2ptr{"$id2[$it]"};
		if (defined $id{$id1}){ $chn[$itrow]="" if (! defined $chn[$itrow]);
					if (length($id2[$it])==4){
					    $chn[$itrow].=" ";}
					else {
					    $chn[$itrow].=substr($id2[$it],5,1);} } }
	    next if (defined $chn[$itrow]); }
	++$ctDanger; push(@danger,$name);
	$chn[$itrow]=" ";
    }

				# --------------------------------------------------
				# (3) write output lists
				# --------------------------------------------------

				# ------------------------------
				# ok
    $fileOutTmp=$fileOut;  $fileOutTmp=~s/Out/Out-ok/;
    if ($fileOutTmp eq $fileOut) {
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-ok-".$tmp;}
    &open_file("$fhout",">$fileOutTmp"); 
    foreach $it (@ok){
	next if (defined $skip[$it] && $skip[$it]);
	$id=$name[$it];
	$file=$par{"dirHssp"}.$id.".hssp";
	$chn=$chn[$it];
	@tmp=split(//,$chn);
	$#file=0;
	foreach $chn (@tmp){
	    if    ($chn eq " ")          { push(@file,$file);          ++$ctok; }
	    elsif ($chn =~ /^[A-Z0-9]$/) { push(@file,$file."_".$chn); ++$ctok; }
	    else { print "*** id=$id, chn=$chn ($chn[$it]) it=$it no real chain?\n";
		   exit; }}
	foreach $file (@file){
	    print $fhout "$file\n"; } }
    close($fhout);
    $fileOutOk=$fileOutTmp;

				# ------------------------------
				# nmr
    $fileOutTmp=$fileOut;  $fileOutTmp=~s/Out/Out-nmr/;
    if ($fileOutTmp eq $fileOut) {
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-nmr-".$tmp;}
    &open_file("$fhout",">$fileOutTmp"); 
    foreach $it (@nmr){
	next if (defined $skip[$it] && $skip[$it]); 
	$id=$name[$it];
	$file=$par{"dirHssp"}.$id.".hssp";
	$chn=$chn[$it];
	@tmp=split(//,$chn);
	$#file=0;
	foreach $chn (@tmp){
	    if    ($chn eq " ")          { push(@file,$file);          ++$ctnmr; }
	    elsif ($chn =~ /^[A-Z0-9]$/) { push(@file,$file."_".$chn); ++$ctnmr}
	    else { print "*** id=$id, chn=$chn ($chn[$it]) it=$it no real chain?\n";
		   exit; }}
	foreach $file (@file){
	    print $fhout "$file\n"; } } 
    close($fhout);
    $fileOutNmr=$fileOutTmp;
				# ------------------------------
				# no
    $fileOutTmp=$fileOut;  $fileOutTmp=~s/Out/Out-no/;
    if ($fileOutTmp eq $fileOut) {
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-no-".$tmp;}
    &open_file("$fhout",">$fileOutTmp"); 
    foreach $it (@no){
	next if (defined $skip[$it] && $skip[$it]);
	$id=$name[$it];
	$file=$par{"dirHssp"}.$id.".hssp";
	$chn=$chn[$it];
	@tmp=split(//,$chn);
	$#file=0;
	foreach $chn (@tmp){
	    if    ($chn eq " ")          { push(@file,$file);          ++$ctno; }
	    elsif ($chn =~ /^[A-Z0-9]$/) { push(@file,$file."_".$chn); ++$ctno; }
	    else { print "*** id=$id, chn=$chn ($chn[$it]) it=$it no real chain?\n";
		   exit; }}
	foreach $file (@file){
	    print $fhout "$file\n"; } }close($fhout);
    $fileOutNo=$fileOutTmp;

				# ------------------------------
				# danger
    $fileOutTmp=$fileOut;  $fileOutTmp=~s/Out/Out-danger/;
    if ($fileOutTmp eq $fileOut) {
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-danger-".$tmp;}
    &open_file("$fhout",">$fileOutTmp"); 
    foreach $id (@danger){
	print $fhout "$id\n";  }close($fhout);
    $fileOutDanger=$fileOutTmp;
				# ------------------------------
				# many
    $fileOutTmp=$fileOut;  $fileOutTmp=~s/Out/Out-many/;
    if ($fileOutTmp eq $fileOut) {
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-many-".$tmp;}
    &open_file("$fhout",">$fileOutTmp"); 
    foreach $id (@many){
	print $fhout "$id\n";  }close($fhout);
    $fileOutMany=$fileOutTmp;
}

print "--- output in files:\n";
foreach $file (@fileOut){
    print "$file," if (-e $file);}print "\n";


print "--- output in     \n";
print "---        ok= $fileOutOk\n";
print "---        no= $fileOutNo\n";
print "---        nmr=$fileOutNmr\n";
print "---       MANY=$fileOutMany\n";
print "---     DANGER=$fileOutDanger\n";
print "--- statistics:\n";
print "--- \n";
printf "--- ok =   %5d (chn=%5d)\n",$#ok,$ctok;
printf "--- no =   %5d (chn=%5d)\n",$#no,$ctno;
printf "--- nmr=   %5d (chn=%5d)\n",$#nmr,$ctnmr;
printf "--- nmr=   %5d (chn=%5d)\n",$nrow,($ctnmr+$ctno+$ctok);
print "--- \n";
printf "--- danger=%5d\n",$#danger;
printf "--- many=  %5d\n",$#many;


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

