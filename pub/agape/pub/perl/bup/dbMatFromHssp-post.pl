#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="processes the matrix produced by dbMatFromHssp.pl (perl/scr)";
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
$par{"aa"}=                     "VLIMFWYGAPSTCHRKQEND"; 

@aa=split(//,$par{"aa"});
foreach $tmp(@aa){
    $aa{$tmp}=1;}
$aa=$par{"aa"};

				# ini matrix
foreach $it1 (1..$#aa){
    foreach $it2 (1..$#aa){
	$mat{"$aa[$it1]","$aa[$it2]"}=0;}}



@kwd=sort (keys %par);
$sep="\t";
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName '\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
    print "     \t num|perc|cperc|odds  -> write num|perc|cperc|odds, only (def: perc)\n";
    print "     \t                  num:   simple total counts\n";
    print "     \t                  perc:  percentages over total counts\n";
    print "     \t                  cperc: percentages over sums over rows\n";
    print "     \t                  odd:   log odds\n";
    print "     \t fano|rob|bayes       -> write info (fano,robson,bayes)\n";
    print "     \t                  fano:  Fano information\n";
    print "     \t                  rob:   Robson= information difference state/non-state\n";
    print "     \t                  bayes: Bayes probability \n";
    print "     \t all            -> all written\n";
#    print "     \t \n";
#    print "     \t \n";
    if (defined %par){
	foreach $kwd (@kwd){
	    printf "     \t %-20s=%-s (def)\n",$par{"$kwd"};}}
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
$#fileIn=$#chainIn=0;		# read command line
$ctMode=0;
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=   $1;}
    elsif ($arg=~/^num$/)                 { $LwrtNum=   1; ++$ctMode; }
    elsif ($arg=~/^perc?$/)               { $LwrtPerc=  1; ++$ctMode; }
    elsif ($arg=~/^cperc?$/)              { $LwrtCperc= 1; ++$ctMode; }
    elsif ($arg=~/^odd.?$/)               { $LwrtOdds=  1; ++$ctMode; }
    elsif ($arg=~/^fano$/)                { $LwrtFano=  1; ++$ctMode; }
    elsif ($arg=~/^rob\w*$/)              { $LwrtRobson=1; ++$ctMode; }
    elsif ($arg=~/^bay\w*$/)              { $LwrtBayes= 1; ++$ctMode; }
    elsif ($arg=~/^all$/)                 { $LwrtNum=$LwrtPerc=$LwrtOdds=$LwrtCperc=
						$LwrtFano=$LwrtRobson=$LwrtBayes=1; 
					    $ctMode=7; }
#    elsif ($arg=~/^=(.*)$/){$=$1;}
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
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp; $fileOut=~s/\..*$/\.rdb/;}
$LwrtPerc=1                     if ($ctMode == 0);

$des="num";
				# ------------------------------
				# (1) read matrix (only numbers)
foreach $fileIn (@fileIn){
    print "--- $scrName: working on '$fileIn'\n";
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
    while (<$fhin>) {
	next if ($_=~/^\#/);
	next if ($_!~/^\s*$des/);
	$_=~s/\n//g;
	$_=~s/^\s*$des//g;
	$_=~s/^[\s\t]*|[\s\t]*$//g;
	$line=$_;
	($txt,@tmp)=split(/[\s\t]+/,$line);
	if ($tmp[1]=~/[A-Z]/){
	    @name=@tmp;}
	else { foreach $it (1..$#tmp){
		   $mat{"$txt","$name[$it]"}=$tmp[$it];
	       } }
    } close($fhin); }

$finWrt="";
				# ------------------------------
				# (2) process (general)
$mat{"R"}=join(',',@aa);
$mat{"S"}=join(',',@aa);

if (1){
    ($Lok,$msg,$tmpWrt)=
	&stat2DarrayWrt($sep,$LwrtNum,$LwrtPerc,$LwrtCperc,$LwrtFano,$LwrtRobson,$LwrtBayes,%mat);
    if (! $Lok){ print "*** ERROR $scrName: stat2DarrayWrt returned:\n",$msg,"\n";
		 exit; }
    $finWrt.=$tmpWrt;
}
				# ------------------------------
				# (3) process (special)
if (0 || $LwrtOdds){
    ($Lok,$msg,$tmp)=
	&massageLoc(%mat); 
    if (! $Lok){ print "*** ERROR $scrName: massageLoc returned:\n",$msg,"\n";
		 exit; }
    $finWrt.=$tmp;
}
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
				# ------------------------------
				# screen
print "--- ","-" x 60,"\n";
print "--- statistics:\n";
$tmp=$finWrt; $tmp=~s/\t//g;
print $tmp;

				# ------------------------------
				# build up RDB header
$tmp=$fileIn[1];$tmp=~s/^.*\/|\..*//g;
$tmp{"name"}=           "dbMatFromHssp";
$tmp{"nota","expect"}=  "des,aa".join(',',@aa)."sum";
$tmp{"nota","des"}=     "data type, e.g. num|perc|cperc|odds|fano|robson|bayes";
$tmp{"nota","A"}=       "A-Y: amino acids";
$tmp{"nota","sum"}=     "sums of rows";
$tmp{"nota","1"}=       "amino acids"."\t".join('',@aa);
$tmp{"nota","2"}=       "num".    "\t"."simple total counts";
$tmp{"nota","3"}=       "perc".   "\t"."percentages over total counts";
$tmp{"nota","4"}=       "cperc".  "\t"."percentages over sums over rows";
$tmp{"nota","5"}=       "fano".   "\t"."Fano information: I  (S;R) = log [ (f(S,R)/f(R)) / (f(S)/N) ]";
$tmp{"nota","6"}=       "robson". "\t"."Robson info diff, DI (S;R) = I (S;R) - I (non-S;R)";
$tmp{"nota","7"}=       "bayes".  "\t"."Bayes probability: P(S|R)";
$tmp{"para","expect"}=  "database";
$tmp{"para","database"}=$tmp;
				# ------------------------------
				# file
&open_file("$fhout",">$fileOut"); 
				# RDB header
&rdbGenWrtHdr($fhout,%tmp);

print $fhout $finWrt; 

close($fhout);

print "--- output in $fileOut\n";
exit;

#===============================================================================
sub massageLoc {
    local(%mat)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   massageLoc                  processes the matrix
#       in/out GLOBAL:          all
#       out:                    1|0,msg,$tmpWrt (sprintf: ready to print)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."massageLoc";$fhinLoc="FHIN_"."massageLoc";

				# ------------------------------
				# normalise by total counts
				# of particular residue
    undef @sum; $sum=0;
    foreach $it1 (1..$#aa){
	$sum[$it1]=0;}
    foreach $it1 (1..$#aa){
	foreach $it2 (1..$#aa){
	    $sum[$it1]+=$mat{"$aa[$it1]","$aa[$it2]"};
	    $sum[$it1]+=$mat{"$aa[$it2]","$aa[$it1]"}; }
	$sum+=$sum[$it1];
    }
    if (0){
	$tmp=0;
	foreach $it1 (1..$#aa){
	    $tmp+=100*($sum[$it1]/$sum);
	    printf "xx %3d sum=%8d p=%6.2f\n",$it1,$sum[$it1],100*($sum[$it1]/$sum);
	}
	print "tot=$sum (s=$tmp)\n";exit;}

    if (0){			# normalise number...
	foreach $it1 (1..$#aa){
	    foreach $it2 (1..$#aa){
		$mat{"$aa[$it1]","$aa[$it2]"}=
		    $mat{"$aa[$it1]","$aa[$it2]"} * 
			($sum[$it1]*$sum[$it2])/$sum;
	    }
	}
    }


				# --------------------------------------------------
				# (2) normalise mat
				# --------------------------------------------------
    foreach $it1 (1..$#aa){
	$sum[$it1]=0;
	foreach $it2 (1..$#aa){	# sam all rows
	    $sum[$it1]+=$mat{"$aa[$it1]","$aa[$it2]"}; }
				# ------------------------------
				# compile percentages
	if ($LwrtPerc || $LwrtOdds){
	    $sumPerc[$it1]=0;
	    foreach $it2 (1..$#aa){
		if ($sum[$it1]<=1){
		    $matPerc{"$aa[$it1]","$aa[$it2]"}=0;}
		else {
		    $matPerc{"$aa[$it1]","$aa[$it2]"}=100*($mat{"$aa[$it1]","$aa[$it2]"}/$sum[$it1]);} 
		$tmp=sprintf("%5.1f",$matPerc{"$aa[$it1]","$aa[$it2]"}); $tmp=~s/\s//g;
		$sumPerc[$it1]+=$tmp;
	    } }
 				# ------------------------------
				# log odds
	if ($LwrtOdds){
	    foreach $it2 (1..$#aa){
		if ($matPerc{"$aa[$it1]","$aa[$it2]"}>0){
		    $matOdds{"$aa[$it1]","$aa[$it2]"}=
			($matPerc{"$aa[$it1]","$aa[$it2]"}/100)*
			    log($matPerc{"$aa[$it1]","$aa[$it2]"}/100); }
		else { $matOdds{"$aa[$it1]","$aa[$it2]"}=0;} } }
    }
				# --------------------------------------------------
				# (3) arrays to write
				# --------------------------------------------------
    $#tmpWrt=0;
    if ($LwrtNum){		# counts
	$tmpWrt=         sprintf ("%3s$sep%4s","num","x->y");
	foreach $it1 (1..$#aa){ 
	    $tmpWrt.=    sprintf ("$sep%8s",$aa[$it1]);} 
	$tmpWrt.=        sprintf ("%8s\n","sum");
	push(@tmpWrt,$tmpWrt);
	foreach $it1 (1..$#aa){
	    $tmpWrt=     sprintf ("%3s$sep%-4s","num",$aa[$it1]);
	    foreach $it2 (1..$#aa){	# 
		$tmpWrt.=sprintf ("$sep%8d",$mat{"$aa[$it1]","$aa[$it2]"});} 
	    $tmpWrt.=    sprintf ("$sep%8d",$sum[$it1]);
	    $tmpWrt.=    "\n";
	    push(@tmpWrt,$tmpWrt); } }
    
    if ($LwrtPerc){		# percentages
	$tmpWrt=         sprintf ("%-4s","per");
	foreach $it1 (1..$#aa){ 
	    $tmpWrt.=    sprintf ("$sep%5s",$aa[$it1]);} 
	$tmpWrt.=        sprintf("$sep%6s\n","sum");
	push(@tmpWrt,$tmpWrt);
	foreach $it1 (1..$#aa){
	    $tmpWrt=     sprintf ("%-4s",$aa[$it1]);
	    foreach $it2 (1..$#aa){
		$tmpWrt.=sprintf ("$sep%5.1f",$matPerc{"$aa[$it1]","$aa[$it2]"});} 
	    $tmpWrt.=    sprintf ("$sep%6.1f\n",$sumPerc[$it1]);
	    push(@tmpWrt,$tmpWrt); } }
    
    if ($LwrtOdds){		# log odds
	$tmpWrt=         sprintf ("%3s$sep%4s","odd","x->y");
	foreach $it1 (1..$#aa){ 
	    $tmpWrt.=    sprintf ("$sep%5s",$aa[$it1]);} 
	$tmpWrt.=        sprintf("$sep%6s\n","sum");
	push(@tmpWrt,$tmpWrt);
	foreach $it1 (1..$#aa){
	    $tmpWrt=     sprintf ("%3s$sep%5s","odd",$aa[$it1]);
	    $sumtmp=0;
	    foreach $it2 (1..$#aa){	# 
		$tmpWrt.=sprintf ("$sep%5.2f",$matOdds{"$aa[$it1]","$aa[$it2]"});
		$sumtmp+=$matOdds{"$aa[$it1]","$aa[$it2]"};
	    } 
	    $tmpWrt.=    sprintf ("$sep%6.1f\n",$sumtmp);
	    push(@tmpWrt,$tmpWrt); } }
    $tmpWrt=join('',@tmpWrt);
    return(1,"ok $sbrName",$tmpWrt);
}				# end of massageLoc

