#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="joins a couple of output files from evalsec-simple (min,max,q3,sov)\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName files.dat'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s=%-20s %-s\n","","excl",    "x",       "exclude all methods match x from min_max";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
				# special
    if (($#ARGV==1 && $ARGV[1]=~/^special/) ||
	($#ARGV>1 && $ARGV[1] =~/^(-h|help)/ && $ARGV[2]=~/^spe/)){
    }

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$excl=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^excl=(.*)$/)           { $excl=           $1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    $tmp=~s/\-.*$//g;$fileOut="Out-".$tmp.".dat";}
$sep="\t";

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
undef %id;
$#id=0;
$#method=0;
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
    $method=$fileIn;
    $method=~s/^.*\///g;
    $method=~s/\..*$//g;
    if (defined $res{$method}){
	print "xx oops problem already have method=$method\n";
	die;}
    $res{$method}=1;
    push(@method,$method);
    undef %ptr;
    while (<$fhin>) {
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	if ($_=~/^id/){		# skip names
	    @tmp=split(/[\s\t]+/,$_);
	    foreach $it (1..$#tmp){
		if    ($tmp[$it]=~/id/){
		    $ptr{"id"}=$it;}
		elsif ($tmp[$it]=~/^q3$/i){
		    $ptr{"q3"}=$it;}
		elsif ($tmp[$it]=~/nres/i){
		    $ptr{"nres"}=$it;}
		elsif ($tmp[$it]=~/^sov$/i){
		    $ptr{"sov"}=$it;}
	    }
	    next;}
	@tmp=split(/[\s\t]+/,$_);
	$id=$tmp[$ptr{"id"}];
	$id=~s/\..*$//g;
	if (! defined $res{$id,"nres"}){
	    push(@id,$id);
	    $res{$id,"nres"}=$tmp[$ptr{"nres"}];
	}
	foreach $kwd ("q3","sov"){
	    next if (! defined $ptr{$kwd});
	    $res{$id,$method,$kwd}=$tmp[$ptr{$kwd}];
	}
    }
    close($fhin);
}
				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout
    join($sep,"id","nres","Average over all methods (Q3)","Worst method (Q3)","Best method (Q3)");
foreach $method (@method){
    $tmp=$method;
    $tmp=~s/set\d+\-//g;
    print $fhout
	$sep,$tmp."_Q3";
}
				# add SOV
if (defined $ptr{"sov"}){
    print $fhout
	join($sep,"id","nres","<sov3>","minSov","maxSov");
    foreach $method (@method){
	$tmp=$method;
	$tmp=~s/set\d+\-//g;
	print $fhout
	    $sep,$tmp."_SOV";
    }}

print $fhout "\n";
if ($excl){
    $nmethod2ave=0;
    foreach $method (@method){
	if (! $excl || ( $excl && $method !~ /$excl/)){
	    ++$nmethod2ave;}}}
else {
    $nmethod2ave=$#method;}



foreach $id (@id){
    $#tmp=0;
    $#tmp2=0;
    $#tmp2sov=0;
    push(@tmp,$id,$res{$id,"nres"});
    $min=   100;$max=   0;$sum=0;
    $minsov=100;$maxsov=0;$sumsov=0;
    
    foreach $method (@method){
	$q3= $res{$id,$method,"q3"};
	if (! defined $q3){
	    print "*** ERROR id=$id, method=$method, no q3!\n";
	    die;}
	push(@tmp2,$q3);

	if (! $excl || ( $excl && $method !~ /$excl/)){
	    if    ($q3 < $min){
		$min=$q3;}
	    if    ($q3 > $max){
		$max=$q3;}
	    $sum+=$q3;}

	if (defined $ptr{"sov"}){
	    $sov=$res{$id,$method,"sov"};
	    push(@tmp2sov,$sov);
	    if (! $excl || ( $excl && $method !~ /$excl/)){
		if (! defined $sov){
		    print "*** ERROR id=$id, method=$method, no sov!\n";
		    die;}
		if    ($sov < $minsov){
		    $minsov=$sov;}
		if    ($sov > $maxsov){
		    $maxsov=$sov;}
		$sumsov+=$sov;}}
    }
    $ave=$sum/$nmethod2ave;
    $ave=~s/(\.\d).*$/$1/g;
    push(@tmp,$ave,$min,$max,@tmp2);
    if (defined $ptr{"sov"}){
	$avesov=$sumsov/$nmethod2ave;
	$avesov=~s/(\.\d).*$/$1/g;
	push(@tmp,$avesov,$minsov,$maxsov,@tmp2sov);}

    print $fhout 
	join($sep,@tmp),"\n";
}
    
close($fhout);

print "--- output in $fileOut\n" if (-e $fileOut);
exit;


#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

