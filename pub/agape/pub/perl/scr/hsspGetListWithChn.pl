#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="in: a list of hssp files (or *.hssp) with, or without chains\n".
    "     \t out: a list with all chains";
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
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal:\t $scrGoal\n";
    print  "use: \t '$scrName list (or *hssp)'\n";
    print  "opt: \t \n";
    print  "     \t fileOut=x\n";
				#      'keyword'   'value'    'description'
    printf "     \t %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "     \t %-15s  %-20s %-s\n","noScreen", "no value","";
#    printf "     \t %-15s  %-20s %-s\n","",   "","";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	printf "     \t %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30;
	printf "     \t %-15s  %-20s %-s\n","other:","default settings: "," ";
	foreach $kwd (@kwd){
	    if    ($par{"$kwd"}!~/\D/){
		printf "     \t %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    elsif ($par{"$kwd"}!~/[0-9\.]/){
		printf "     \t %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    else {
		printf "     \t %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)";} } }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
$#fileIn=$#chainIn=0;
				# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
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
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# --------------------------------------------------
$#tmpf=$#tmpc=$ct=0;		# (1) read list (if there is)
				# --------------------------------------------------
foreach $fileIn (@fileIn){
    ++$ct;
    if (&is_hssp($fileIn)){	# is HSSP
	push(@tmpf,$fileIn);
	push(@tmpc,$chainIn[$ct]); 
	next;}
				# is list?
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
    $#tmpf2=$#tmpc2=0;
    while (<$fhin>) {$_=~s/\s|\n//g;$rd=$_;
		     $chain="*";
		     if ($rd =~ /^(.*\.hssp)_([A-Z0-9])/){
			 $chain=$2;
			 $file= $1; }
		     else {
			 $file=$rd;}
		     if (! &is_hssp($file)){
			 print "*** ERROR $scrName: $fileIn assumed to be list of HSSP\n";
			 print "***       but '$file' seems not to be (rd=$rd)\n";
			 die;}
		     push(@tmpf2,$file);push(@tmpc2,$chain);}
    close($fhin);
    push(@tmpf,@tmpf2);push(@tmpc,@tmpc2); }
    
@fileIn=@tmpf;
@chainIn=@tmpc;
				# --------------------------------------------------
				# (2) loop over all file(s)
				# --------------------------------------------------
$#fin=$#wrt=0;
foreach $itfile (1..$#fileIn){
    $fileIn= $fileIn[$itfile];
    $chainIn=$chainIn[$itfile];
				# ------------------------------
				# already chain given
    if ($chainIn ne "*") {
	$fileIn.="_".$chainIn;
	printf 
	    "--- already ok %-20s no = %4d chain=%1s file=%-s\n",$fileIn,$itfile,$chainIn,$fileIn[$itfile];
	push(@fin,$fileIn);
	next; }

    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    
				# ------------------------------
				# get chains
    ($Lok,$msg,%tmp)=
	&hsspGetChainBreaks($fileIn);
    print "*** ERROR $scrName: failed on chain breaks for $fileIn\n",$msg,"\n" if (! $Lok);

    if ($tmp{"NROWS"} == 1 && $tmp{"1"} eq "*") {
	push(@fin,$fileIn);	# take as is (no chain)
	next; }

				# ------------------------------
				# more than one, or real chain
    $#tmp=0;
    $tmpWrt="";
    foreach $it (1..$tmp{"NROWS"}){
	$chain=$tmp{"$it"};
	if ($chain=~/^[A-Z0-9]/){
	    push(@tmp,substr($chain,1,1)); }
	$tmpWrt.=sprintf("%3d\t%-3s\t%5d\t%5d\t%-s\n",
			 $it,$tmp{"$it"},$tmp{"ifir","$it"},$tmp{"ilas","$it"},$fileIn); }
    push(@wrt,$tmpWrt);
				# unique, real chains
    undef %tmp; $chain="";
    foreach $tmp (@tmp){
	next if ($tmp eq "*");	# no real
	next if (defined $tmp{$tmp}); # already taken
	$tmp{$tmp}=1;
	$chain.="$tmp"; }
    if    (length($chain)==0){
	push(@fin,$fileIn); }	# take as is (no chain)
    else {
	@tmp=split(//,$chain);
	foreach $tmp (@tmp){
	    push(@fin,$fileIn."_".$tmp); }}
}
				# ------------------------------
				# (2) write output
				# ------------------------------
&open_file("$fhout",">$fileOut"); 
foreach $fin (@fin){
    print $fhout "$fin\n"; }
close($fhout);

				# non-real chains
if ($#wrt>0){
    $fileOut2=$fileOut; $fileOut2=~s/^Out-//g;
    $fileOut2="Outall-".$fileOut2;

    &open_file("$fhout",">$fileOut2"); 
    $tmpWrt=sprintf("%3s\t%-3s\t%5s\t%5s\t%-s\n","no","chn","ifir","ilas","file");
    print $fhout $tmpWrt;
    foreach $wrt (@wrt){
	print $fhout $wrt; }
    close($fhout);
				# screen
    print $tmpWrt;
    foreach $wrt (@wrt){
	$wrt=~s/\t/ /g;
	print $wrt; } }

print "--- output in $fileOut\n"  if (-e $fileOut);
print "--- output in $fileOut2\n" if (-e $fileOut2);
exit;
