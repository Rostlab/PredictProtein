#!/usr/sbin/perl -w
# 
# statistics (true/false) on files OutDetF* and OutDetT
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

$par{"itrv"}=1;
if ($#ARGV<2){print"goal:    statistics (true/false) on files OutDetF* and OutDetT\n";
	      print"usage:   script fileT fileF\n";
	      print"options: itrv=\n";
	      exit;}

$fileInt=$ARGV[1];
$fileInf=$ARGV[2];
$fhin="FHIN";$fhout="FHOUT";$fileOut="Stat-newThreshSim2.dat";
				# ------------------------------
				# defaults
				# column names to be read
@kwdRd=("idSeq","idStr","pide","psim","lenAli","nIns","lenIns","ali/l2","distHssp");
@kwdRd=("pide","psim","lenAli","nIns","lenIns","ali/l2","distHssp");
@kwdWrt=("dIde","dSim","dAdd2","dMul2","dDif2","dRul2",
	 ,,,,,);
@kwdWrt2=("nT","nF","t/f","pT","pF");
				# which column are they in?
%posRd=('idSeq',"1",'idStr',"2",'pide',"3",'psim',"4",
	'lenAli',"5",'nIns',"6",'lenIns',"7",'ali/l2',"8",'distHssp',"9");


$#kwdParPot=0;$#kwdParBeg=0;
#for ($it0=340;$it0<=400;$it0+=5)  {push(@kwdParBeg,$it0);}
#for ($itp=0.5;$itp<=0.6;$itp+=0.005){push(@kwdParPot,$itp);}
				# sim 1
#for ($it0=250;$it0<=350;$it0+=10)  {push(@kwdParBeg,$it0);}
#for ($itp=0.5;$itp<=0.7;$itp+=0.02){push(@kwdParPot,$itp);}
				# sim 2
#for ($it0=300;$it0<=400;$it0+=10)  {push(@kwdParBeg,$it0);}
#for ($itp=0.4;$itp<=0.6;$itp+=0.02){push(@kwdParPot,$itp);}
				# sim 3
for ($it0=350;$it0<=450;$it0+=10)  {push(@kwdParBeg,$it0);}
for ($itp=0.4;$itp<=0.6;$itp+=0.02){push(@kwdParPot,$itp);}

				# ------------------------------
				# read true
&open_file("$fhin", "$fileInt");$#true=$ct=0;
while (<$fhin>) {next if /^\#|^idS/;$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
		 next if (length($_)<3);
		 ++$ct;@tmp=split(/\t/,$_);
		 foreach $it (1..$#kwdRd){$pos=$posRd{$kwdRd[$it]};$tmp[$pos]=~s/\s//g;
					  $true{"$ct","$kwdRd[$it]"}=$tmp[$pos];}}close($fhin);
$nTrue=$ct;
				# ------------------------------
				# read false
&open_file("$fhin", "$fileInf");$#false=$ct=0;
while (<$fhin>) {next if /^\#|^idS/;$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
		 next if (length($_)<3);
		 ++$ct;@tmp=split(/\t/,$_);
		 foreach $it (1..$#kwdRd){$pos=$posRd{$kwdRd[$it]};$tmp[$pos]=~s/\s//g;
					  $false{"$ct","$kwdRd[$it]"}=$tmp[$pos];}}close($fhin);
$nFalse=$ct;

$LcheckNew=0;
$LparaNewIde=0;
$LparaNewSim=1;
				# ------------------------------
				# new curve
if ($LcheckNew){
    $colOut="d20";  &getHsspThreshNew(20,10);
    $colOut="d30";  &getHsspThreshNew(30,10);
    $colOut="d40";  &getHsspThreshNew(40,10);
    $colOut="d50";  &getHsspThreshNew(50,10);
    $colOut="d60";  &getHsspThreshNew(60,10);
    $colOut="d70";  &getHsspThreshNew(70,10);
    $colOut="d80";  &getHsspThreshNew(80,10);
    $colOut="d90";  &getHsspThreshNew(90,10);
    $colOut="d100"; &getHsspThreshNew(100,10);
    $colOut="d200"; &getHsspThreshNew(110,90);
    $colOut="d400"; &getHsspThreshNew(200,200);
    $colOut="d800"; &getHsspThreshNew(400,1000);
}
				# ------------------------------
				# new parameters
if ($LparaNewIde){
    foreach $it0 (@kwdParBeg){foreach $itp(@kwdParPot){
	$tmp="$itp";$tmp=substr($tmp,1,5);
	$colOut="IDE$it0-$tmp";print "xx trying $colOut,\n";
	&getHsspThreshNewLineIde($it0,$itp);   }}}
if ($LparaNewSim){
    foreach $it0 (@kwdParBeg){foreach $itp(@kwdParPot){
	$tmp="$itp";$tmp=substr($tmp,1,5);
	$colOut="SIM$it0-$tmp";print "xx trying $colOut,\n";
	&getHsspThreshNewLineSim($it0,$itp);   }}}
    
&wrtOutNew("STDOUT"," ");

&open_file("$fhout",">$fileOut"); 
&wrtOutNew($fhout,"\t");
close($fhout);
exit;				# xx
				# ------------------------------
				# statistics
$col="distHssp";$colOut="dIde";
&getHsspThreshPide;		# HSSP threshold


$col="psim";$colOut="dSim";
&getHsspThreshPsim;		# HSSP threshold on psim


$col="psim";$colOut="dAdd2";
&getHsspThreshPadd2;		# HSSP threshold on Pide+psim

$col="psim";$colOut="dMul2";
&getHsspThreshPmul2;		# HSSP threshold on Pide*psim


$col="psim";$colOut="dDif2";
&getHsspThreshPdiff2;		# HSSP threshold on Pide*psim

$col="psim";$colOut="dRul2";
&getHsspThreshPrule2;		# HSSP threshold on Pide*psim
# &tmpxx;


&wrtOut("STDOUT"," ");

&open_file("$fhout",">$fileOut"); 
&wrtOut($fhout,"\t");
close($fhout);


exit;

sub tmpxx{
    $[=1;@tmp=split(/,/,$res{"$colOut"});
    foreach $it(@tmp){
	print "xx $it t=",$res{"$it","$colOut"."true"},", f=",$res{"$it","$colOut"."false"},"\n";}}
    

#===============================================================================
sub getHsspThreshNew {
    local($laliLoc,$itrvlLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshNew           out=New (i.e. HSSP threshold on psim)
#-------------------------------------------------------------------------------
    $ctTrue=$ctFalse=0;
    foreach $it (1..$nTrue) {
	if (($true{"$it","lenAli"}>=$laliLoc)&&($true{"$it","lenAli"}<($laliLoc+$itrvlLoc))){
	    $pide=&getDistanceHsspCurve($true{"$it","lenAli"});
	    if ($true{"$it","pide"}>=$pide){
		++$ctTrue;}}}
    foreach $it (1..$nFalse){
	if (($false{"$it","lenAli"}>=$laliLoc)&&($false{"$it","lenAli"}<($laliLoc+$itrvlLoc))){
	    $pide=&getDistanceHsspCurve($false{"$it","lenAli"});
	    if ($false{"$it","pide"}>=$pide){
		++$ctFalse;}}}
    $res{"$colOut"."true"}=$ctTrue;
    $res{"$colOut"."false"}=$ctFalse;
}				# end of getHsspThreshNew

#===============================================================================
sub getHsspThreshNewLineIde {
    local($n0,$pot)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshNewLineIde     out=NewLine (i.e. HSSP threshold on ide)
#-------------------------------------------------------------------------------
    $ctTrue=$ctFalse=0;
    foreach $it (1..$nTrue) {
	$pide=&getDistanceHsspCurveNew($true{"$it","lenAli"},100,$n0,$pot);
	if ($true{"$it","pide"}>=$pide){
	    ++$ctTrue;}}
    foreach $it (1..$nFalse){
	$pide=&getDistanceHsspCurveNew($false{"$it","lenAli"},100,$n0,$pot);
	if ($false{"$it","pide"}>=$pide){
	    ++$ctFalse;}}
    $res{"$colOut"."true"}=$ctTrue;
    $res{"$colOut"."false"}=$ctFalse;
}				# end of getHsspThreshNewLineIde

#===============================================================================
sub getHsspThreshNewLineSim {
    local($n0,$pot)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshNewLineSim     out=NewLine (i.e. HSSP threshold on psim)
#-------------------------------------------------------------------------------
    $ctTrue=$ctFalse=0;
    foreach $it (1..$nTrue) {
	$pide=&getDistanceHsspCurveNew($true{"$it","lenAli"},100,$n0,$pot);
	if ($true{"$it","psim"}>=$pide){
	    ++$ctTrue;}}
    foreach $it (1..$nFalse){
	$pide=&getDistanceHsspCurveNew($false{"$it","lenAli"},100,$n0,$pot);
	if ($false{"$it","psim"}>=$pide){
	    ++$ctFalse;}}
    $res{"$colOut"."true"}=$ctTrue;
    $res{"$colOut"."false"}=$ctFalse;
}				# end of getHsspThreshNewLineSim

#===============================================================================
sub getHsspThreshPide {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshPide           out=psim (normal HSSP threshold)
#-------------------------------------------------------------------------------
    $#tmpT=$#tmpF=0;		# sort
    foreach $it (1..$nTrue) {
	push(@tmpT,$true{"$it","$col"});}
    @tmpT=sort bynumber(@tmpT);
    foreach $it (1..$nFalse){
	push(@tmpF,$false{"$it","$col"});} 
    @tmpF=sort bynumber(@tmpF);
    &histoThresh;
}				# end of getHsspThreshPide

#===============================================================================
sub getHsspThreshPsim {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshPsim           out=psim (i.e. HSSP threshold on psim)
#-------------------------------------------------------------------------------
    $#tmpT=$#tmpF=0;		# sort
    foreach $it (1..$nTrue) {$psim=&getDistanceHsspCurve($true{"$it","lenAli"});
			     $out=$true{"$it","psim"}-$psim;
			     push(@tmpT,$out);}  
    @tmpT=sort bynumber(@tmpT);
    foreach $it (1..$nFalse){$psim=&getDistanceHsspCurve($false{"$it","lenAli"});
			     $out=$false{"$it","psim"}-$psim;
#			     if ($out>60){print "xx false it=$it, out=$out, psim=$psim, lali=",$false{"$it","lenAli"},", psim=",$false{"$it","psim"},",\n";}
			     push(@tmpF,$out);} 
#			     exit;
    @tmpF=sort bynumber(@tmpF);

    &histoThresh;
}				# end of getHsspThreshPsim

#===============================================================================
sub getHsspThreshPadd2 {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshPadd2          out=sqrt(psim+pide)
#-------------------------------------------------------------------------------
    $#tmpT=$#tmpF=0;		# sort
    foreach $it (1..$nTrue) {$psim=&getDistanceHsspCurve($true{"$it","lenAli"});
			     $out=($true{"$it","psim"}+$true{"$it","pide"})/2-$psim;
			     push(@tmpT,$out);}  
    @tmpT=sort bynumber(@tmpT);
    foreach $it (1..$nFalse){$psim=&getDistanceHsspCurve($false{"$it","lenAli"});
			     $out=($false{"$it","psim"}+$false{"$it","pide"})/2-$psim;
			     push(@tmpF,$out);} 
    @tmpF=sort bynumber(@tmpF);

    &histoThresh;
}				# end of getHsspThreshPadd2

#===============================================================================
sub getHsspThreshPmul2 {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshPmul2          out=sqrt(psim*pide)
#-------------------------------------------------------------------------------
    $#tmpT=$#tmpF=0;		# sort
    foreach $it (1..$nTrue) {$psim=&getDistanceHsspCurve($true{"$it","lenAli"});
			     $out=sqrt(($true{"$it","psim"}*$true{"$it","pide"}))-$psim;
			     push(@tmpT,$out);}  
    @tmpT=sort bynumber(@tmpT);
    foreach $it (1..$nFalse){$psim=&getDistanceHsspCurve($false{"$it","lenAli"});
			     $out=sqrt($false{"$it","psim"}*$false{"$it","pide"})-$psim;
			     push(@tmpF,$out);} 
    @tmpF=sort bynumber(@tmpF);

    &histoThresh;
}				# end of getHsspThreshPmul2

#===============================================================================
sub getHsspThreshPdiff2 {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshPdiff2         out=psim-pide
#-------------------------------------------------------------------------------
    $#tmpT=$#tmpF=0;		# sort
    foreach $it (1..$nTrue) {$psim=&getDistanceHsspCurve($true{"$it","lenAli"});
			     $out=$true{"$it","psim"}-$psim+
				 ($true{"$it","psim"}-($true{"$it","pide"}));
#			     $out=($true{"$it","psim"}-$true{"$it","psim"});
			     push(@tmpT,$out);}  
    @tmpT=sort bynumber(@tmpT);
    foreach $it (1..$nFalse){$psim=&getDistanceHsspCurve($false{"$it","lenAli"});
			     $out=$false{"$it","psim"}-$psim+
				 ($false{"$it","psim"}-($false{"$it","pide"}));
			     push(@tmpF,$out);} 
    @tmpF=sort bynumber(@tmpF);

    &histoThresh;
}				# end of getHsspThreshPdiff2

#===============================================================================
sub getHsspThreshPrule2 {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshPrule2         out=true if 
#                                      psim>pide
#                               or:    thresh(psim)>HSSP+5
#                               or:    thresh(pide)>HSSP+5
#-------------------------------------------------------------------------------
    $#tmpT=$#tmpF=0;		# sort
    foreach $it (1..$nTrue) {$psim=&getDistanceHsspCurve($true{"$it","lenAli"});
			     $out=sqrt(($true{"$it","psim"}*$true{"$it","pide"}))-$psim;
			     if (($true{"$it","psim"}>=$true{"$it","pide"})||
				 ($true{"$it","psim"}>=$psim)||
				 ($true{"$it","pide"}>=$psim)){
				 push(@tmpT,$out);} }
    @tmpT=sort bynumber(@tmpT);
    foreach $it (1..$nFalse){$psim=&getDistanceHsspCurve($false{"$it","lenAli"});
			     $out=sqrt($false{"$it","psim"}*$false{"$it","pide"})-$psim;
			     if (($false{"$it","psim"}>=$false{"$it","pide"})||
				 ($false{"$it","psim"}>=$psim)||
				 ($false{"$it","pide"}>=$psim)){
				 push(@tmpF,$out);} }
    @tmpF=sort bynumber(@tmpF);

    &histoThresh;
}				# end of getHsspThreshPrule2

#==========================================================================================
sub getDistanceHsspCurveNew {
    local ($lali,$laliMax,$n0,$pot) = @_ ;
    $[=1;
#--------------------------------------------------------------------------------
#   getDistanceHsspCurveNew     computes the HSSP curve for input: ali length
#        input:                 $lali
#                               note1: thresh=0 for HSSP, 5 for 30%, -5 for 20% ..
#                               note2: saturation at 100
#        output:                value curve (i.e. percentage identity)
#                               HSSP-curve  according to t(L)=(290.15 * L ** -0.562)
#--------------------------------------------------------------------------------
    $lali=~s/\s//g;if (!defined $laliMax){$laliMax=100;}
	
    if ($lali>$laliMax){$lali=$laliMax;}
    $val= $n0*($lali **(-1*$pot)); 
    return ($val);
}				# end getDistanceHsspCurveNew

#===============================================================================
sub histoThresh {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   histoThresh                       
#-------------------------------------------------------------------------------
    $res{"$colOut"}="";		# into histogram
    for($it=75;$it>=(-25);$it-=$par{"itrv"}){
	$res{"$colOut"}.="$it,";	# push all values considered
	$it2=1;$res{"$it","$colOut"."true"}=0; # add occurring
	while (($it2<=$#tmpT)&&($tmpT[$#tmpT-$it2+1]>=$it)){
	    ++$res{"$it","$colOut"."true"};++$it2;}
	$it2=1;$res{"$it","$colOut"."false"}=0;
	while (($it2<=$#tmpF)&&($tmpF[$#tmpF-$it2+1]>=$it)){
	    ++$res{"$it","$colOut"."false"};++$it2;}}
    $res{"$colOut"}=~s/^,|,$//g;    
}				# end of histoThresh

#===============================================================================
sub wrtOut {
    local($fhLoc,$sepLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtOut                       
#-------------------------------------------------------------------------------
    print $fhLoc 
	"\# Perl-RDB\n","\# nTrue =$nTrue\n","\#nFalse=$nFalse\n";
    $tmp="no$sepLoc";
    foreach $kwd(@kwdWrt){
	foreach $kwd2 (@kwdWrt2){$tmp.="$kwd$kwd2$sepLoc";}}
    $tmp=~s/$sepLoc$/\n/g;
    print $fhLoc $tmp;

				# get data for threshold
    for($it=75;$it>=(-25);$it-=$par{"itrv"}){
	printf $fhLoc "%4d$sepLoc",$it;
	foreach $kwd(@kwdWrt){$tmpT=$res{"$it","$kwd"."true"};$tmpF=$res{"$it","$kwd"."false"};
			      if (! defined $tmpT || ! defined $tmpF){print "xx miss $kwd\n";exit;}
			      if (($tmpF+$tmpT)>0){$tmpP=100*$tmpT/($tmpF+$tmpT);}else{$tmpP=0;}
			      $tmpPF=100*$tmpF/$nFalse;$tmpPT=100*$tmpT/$nTrue;
			      printf $fhLoc 
				  "%5d$sepLoc%5d$sepLoc%5.2f$sepLoc%5.2f$sepLoc%5.2f",
				  $tmpT,$tmpF,$tmpP,$tmpPT,$tmpPF;
			      if ($kwd eq $kwdWrt[$#kwdWrt]){$tmp="\n";}else{$tmp=$sepLoc;}
			      print $fhLoc $tmp;}
    }
		
    
}				# end of wrtOut

#===============================================================================
sub wrtOutNew {
    local($fhLoc,$sepLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtOutNew                       
#-------------------------------------------------------------------------------
    if ($LcheckNew){
	@kwdTmp=("d20","d30","d40","d50","d60","d70","d80","d90",
		 "d100","d200","d400","d800");}
    else {$#kwdTmp=0;}

    if ($LparaNewIde){foreach $it0 (@kwdParBeg){foreach $itp(@kwdParPot){
	$tmp="$itp";$tmp=substr($tmp,1,5);
	$colOut="IDE$it0-$tmp";
	push(@kwdTmp,$colOut);}}}
    if ($LparaNewSim){foreach $it0 (@kwdParBeg){foreach $itp(@kwdParPot){
	$tmp="$itp";$tmp=substr($tmp,1,5);
	$colOut="SIM$it0-$tmp";
	push(@kwdTmp,$colOut);}}}

    @kwdTmp2=("nT","nF","t/f","pT","pF");
    print $fhLoc 
	"\# Perl-RDB\n","\# nTrue =$nTrue\n","\#nFalse=$nFalse\n";
    $tmp="range$sepLoc";
    foreach $kwd2(@kwdTmp2){$tmp.="$kwd2$sepLoc";}
    $tmp=~s/$sepLoc$/\n/g;
    print $fhLoc $tmp;
				# get data for threshold
    foreach $kwd(@kwdTmp){
	$tmpT=$res{"$kwd"."true"};$tmpF=$res{"$kwd"."false"};
	if (($tmpF+$tmpT)>0){$tmpP=100*$tmpT/($tmpF+$tmpT);}else{$tmpP=0;}
	if (($LparaNewIde||$LparaNewSim) &&($tmpP<95)){		# plot only if t/f > 95%
	    next;}

	printf $fhLoc "%-10s$sepLoc",$kwd;
	foreach $kwd2(@kwdTmp2){
	    $tmpPF=100*$tmpF/$nFalse;$tmpPT=100*$tmpT/$nTrue;
	    printf $fhLoc 
		"%5d$sepLoc%5d$sepLoc%5.2f$sepLoc%5.2f$sepLoc%5.2f",
		$tmpT,$tmpF,$tmpP,$tmpPT,$tmpPF;
	    if ($kwd2 eq $kwdTmp2[$#kwdTmp2]){$tmp="\n";}else{$tmp=$sepLoc;}
	    print $fhLoc $tmp;}}
}				# end of wrtOutNew

#===============================================================================
sub getHsspThreshNewIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshNewIde         out=NewIde (i.e. HSSP threshold on psim)
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
    $loc= 510 * $laliLoc ** ($expon);
    return($loc);
}				# end of getHsspThreshNewIde

#===============================================================================
sub getHsspThreshNewSim {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspThreshNewSim         out=NewSim (i.e. HSSP threshold on psim)
#       in:                     $lali
#       out:                    $sim
#                               psim= 420 * L ^ { -0.335 (1 + e ^-(L/2000)) }
#-------------------------------------------------------------------------------
    $expon= - 0.335 * ( 1 + exp (-$laliLoc/2000) );
    $loc= 420 * $laliLoc ** ($expon);
    return($loc);
}				# end of getHsspThreshNewSim

#===============================================================================
sub subx {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#-------------------------------------------------------------------------------
}				# end of subx

