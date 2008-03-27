#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# reads /data/hssp/hssp_swissprot.table and extracts statistics: how many
# proteins with with pide>low and lenAli>lowLen ?
#
$[ =1 ;

				# defaults
$lowPide=30;
$lowLali=40;

$lowPide=10;
$lowLali=30;

$interv= 1;			# compute histogram for every 5 percentage points

if ($#ARGV<1){
    print "goal:   how many proteins with pide>low and lenAli>lowLen?\n";
    print "        extract from /data/hssp/hssp_swissprot.table\n";
    print "usage:  script hssp_swissprot.table (option low=90, len=50)\n";
    print "option: option low=90 (default=$lowPide), len=50 (default=$lowLali)\n";
    print "option: notExcl (don't exclude first hit, is for Hom Modelling statistics)\n";
    print "        swiss   (write SWISS ids)\n";
    print "        dbg     (debug)\n";
    exit;}
				# defaults
$fileTable=$ARGV[1];
# $fileTable="/data/hssp/hssp_swissprot.table";

@intervRatio=("1","0.8","0.6","0.4","0.2","0");
$fhin="FHIN";$fhout="FHOUT";
$LexclSelf=1;
$LwrtSwiss=0;
$Ldebug=   0;
				# read input
foreach $_ (@ARGV){
    if   (/^low=/)   {$_=~s/^low=//g;$_=~s/\s//g;$lowPide=$_;}
    elsif(/^len=/)   {$_=~s/^len=//g;$_=~s/\s//g;$lowLali=$_;}
    elsif(/^dbg/)    {$Ldebug=1;   }
    elsif(/^notExcl/){$LexclSelf=0;}
    elsif(/^swiss/)  {$LwrtSwiss=1;}
}
print "--- low=$lowPide, len=$lowLali, ";
print" don't excl self," if(! $LexclSelf);
print",\n";

$title=$fileTable;$title=~s/^.*\///g;$title=~s/\..*$//g;
$fileOut=     "Out-".   $title.  "-pide".$lowPide."-len"."$lowLali";
$fileOutDet=  "OutDet-".$title.  "-pide".$lowPide."-len"."$lowLali";
$fileOutHis=  "OutHis-".$title.  "-pide".$lowPide."-len"."$lowLali";
$fileOutSwiss="OutSwiss-".$title."-id".  $lowPide."-len".$lowLali;

#$fileOut="xxOut-"."$lowPide"."-"."$lowLali" ;$fileOutDet="xxOutDet-"."$lowPide"."-"."$lowLali";$fileOutHis="xxOutHis-"."$lowPide"."-"."$lowLali";


$idMemory="";
open($fhin,$fileTable) || die "*** ERROR failed to open fileTable=$fileTable!\n";

$ct=$ctRd=0;$ratioResCovered=0;
undef %tmp;
$#swiss=0;
$ctline=0;
while (<$fhin>) {
    ++$ctline;
				# exclude header
    next if ($_ !~ /^ \d/ && $_ !~ /^\d/);
    $_=~s/\n//g;$tmp=$_;
# 966c         1 : cog1_human  2AYK    
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8....,....
# 966c         1 : cog1_human  2AYK    1.00  1.00    1  156  108  263  156    0    0  469  
#   34 : myg_ponpy           0.83  0.89    3  154    2  153  152    0    0  153  P02148     MYOGLOBIN
#101m          1 : myg_phyca   1DXC    0.99  0.99    2  154    1  153  153    0    0  153 

    if (1){			# new Holm
	$idSeq=  substr($tmp,19,8);  $idSeq=~s/\s//g; 
	$idStr=  substr($tmp,1,7);   $idStr=~s/([^\s]+) .*$/$1/g;
	$pide=   substr($tmp,39,4); 
	$lenAli= substr($tmp,69,8);  $lenAli=~s/\s//g;
	$lenSeq2=substr($tmp,84,6);  $lenSeq2=~s/\s//g;
    }
    else {			# old Schneider
	$idSeq=  substr($tmp,1,8);   $idSeq=~s/\s//g; 
	$idStr=  substr($tmp,19,10); $idStr=~s/([^\s]+) .*$/$1/g;
	$pide=   substr($tmp,39,4); 
	$lenAli= substr($tmp,69,8);  $lenAli=~s/\s//g;
	$lenSeq2=substr($tmp,84,6);  $lenSeq2=~s/\s//g;
    }

    if ($pide !~ /\d\.\d\d/){
	print "*** pide=$pide in line=$ctline, file=$fileTable\n";
	exit;}
    if ($lenAli !~ /\d/){
	print "*** lenAli=$lenAli in line=$ctline, file=$fileTable\n";
	exit;}
    if ($lenSeq2 !~ /\d/){
	print "*** lenSeq2=$lenSeq2 in line=$ctline, file=$fileTable\n";
	exit;}

    if    ($pide==1){ # exclude self
	$flag{$idSeq}=1; $idMemory=$idSeq; 
	if ($LexclSelf){
	    next;}}
    elsif ("$idMemory" ne $idSeq){ # exclude first hit <100 if none had 100
	$flag{$idSeq}=1; $idMemory=$idSeq; 
	if ($LexclSelf){
	    next;}}
    ++$ctRd;
    if (((100*$pide)>=$lowPide)&&($lenAli>$lowLali)){
	++$ct;$ratioResCovered+=($lenAli/$lenSeq2);
#	if ($ct>100){last;}	# x.x
	printf 
	    "%-15s %-15s %-5d %-5d %-6.2f\n",
	    $idSeq,$idStr,100*$pide,$lenAli,($lenAli/$lenSeq2)
		if ($Ldebug);
				# store unique id's (avoid counting twice!)
	if (! defined $flag{$idStr}){
	    $flag{$idStr}=1;
	    push(@idFound,$idStr);
	    $res{$idStr,"idSeq"}=$idSeq;
	    $res{$idStr,"pide"} =(100*$pide);
	    $res{$idStr,"ratio"}=($lenAli/$lenSeq2);
	    $res{$idStr,"lenAli"}=$lenAli;}
	elsif ($flag{$idStr} && 
	       ((100*$pide)>$res{$idStr,"pide"})){ # replace if higher identity
	    $res{$idStr,"idSeq"}=$idSeq;
	    $res{$idStr,"pide"} =(100*$pide);
	    $res{$idStr,"ratio"}=($lenAli/$lenSeq2);
	    $res{$idStr,"lenAli"}=$lenAli;}
    }
				# write swissprot ids
    next if (! $LwrtSwiss);
    next if ($idSeq !~ /\_/);	# not swiss prot
    if (! defined $tmp{$idSeq}){
	$tmp{$idSeq}=1;
	push(@swiss,$idSeq);
    }
				# 
}close($fhin);

print "number of id's (unique) found=",$#idFound,"\n";print "write output into $fileOut\n";
print "ratio covered=",($ratioResCovered/$ct),"\n";

				# ------------------------------
				# write SWISS ids
if ($LwrtSwiss){
    open($fhout, ">".$fileOutSwiss) || die "*** ERROR opening fileOutSwiss=$fileOutSwiss!\n";
    foreach $id (sort @swiss){
	print $fhout "$id\n";}
    close($fhout);}

				# ------------------------------
				# file with id's
open($fhout, ">".$fileOut) || die "*** ERROR opening fileout=$fileOut!\n";
foreach $id(@idFound){
    print $fhout "$id\n";}
close($fhout);
				# ------------------------------
				# file with details
open($fhout, ">".$fileOutDet) || die "*** ERROR opening fileOutDet=$fileOutDet!\n";
printf $fhout "%-15s\t%-15s\t%-5d\t%-5s\t%-6s\n","idSeq","idStr","pide","lenAli","ali/l2";
foreach $id(@idFound){
    printf $fhout 
	"%-15s\t%-15s\t%-5d\t%-5d\t%-6.2f\n",
	$res{"$id","idSeq"},"$id",$res{"$id","pide"},$res{"$id","lenAli"},$res{"$id","ratio"};
}
close($fhout);

				# ------------------------------
				# file with histograms
				# ini histo
$tmp=$interv;$#interv=0;
while( (100-$tmp)>=$lowPide){push(@interv,(100-$tmp));$tmp+=$interv;}
foreach $tmp(@interv){foreach $des("all",@intervRatio){$his{"$des","$tmp"}=0;}}
				# compile histo
foreach $id(@idFound){
    foreach $pide(@interv){
	if ($res{"$id","pide"} >= $pide){
	    ++$his{"all","$pide"};
	    foreach $ratio(@intervRatio){
		if ($res{"$id","ratio"} >= $ratio){
		    ++$his{"$ratio","$pide"};
		    last;}}
	    last;}}
}
				# write file
open($fhout, ">".$fileOutHis) || die "*** ERROR opening fileOutHis=$fileOutHis!\n";
printf $fhout "%-6s\t","pide";	# header
foreach $des("all","allCum",@intervRatio){
    printf $fhout "%-6s\t",$des;
}
print $fhout "\n";

$pideAll=0;			# xx
foreach $des("all",@intervRatio){
    $sum{"$des"}=0;
}

foreach $it(1..$#interv){		# body
    $pide=$interv[$#interv-$it+1];
    printf $fhout "%-6s\t",$pide;
    foreach $des ("all","allCum",@intervRatio){
	if    ($des eq "all"){
	    $sum{"$des"}+=$his{"$des","$pide"};
	    printf $fhout "%-6d\t",$his{"$des","$pide"};}
	elsif ($des eq "allCum"){
	    printf $fhout "%-6d\t",$sum{"all"};}
	else {
	    $sum{"$des"}+=$his{"$des","$pide"};
	    printf $fhout "%-6d\t",$sum{"$des"};}}

    $pideAll+=$his{"all","$pide"}; # x.x
    print $fhout "\n";}
close($fhout);
print"xx $pideAll,\n";
print "output in files:$fileOut,$fileOutDet,$fileOutHis,\n";
print "          $fileOutSwiss\n" if ($LwrtSwiss);

exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


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
# library collected (end)   lll
#==============================================================================


1;
