#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "";
$scrGoal="\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   \n".
    "     \t \n".
    "     \t ";
#  
# FIXME:
#------------------------------------------------------------------------------#
#	Copyright				        	2003	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Aug,    	2003	       #
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
$Lverb= 1;
$sep=   "\t";


$acc2Thresh= 16;
$acc3Thresh1= 9;
$acc3Thresh2=36;

				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

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
$dirOut=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
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
				# 
$dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/);

if (! defined $fileOut){
    if ($#fileIn>1){
	$tmp="statprof.rdb";}
    else {
	$tmp=$fileIn;
	$tmp=~s/^.*\///g;
    }
    if ($dirOut){
	$fileOut=$dirOut."Out-".$tmp;}
    else {
	$fileOut="Out-".$tmp;}}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
&exposure_normalise_prepare_rel2acc();

$ctfile=0;
$ctprot=0;
if (0){
    $fileOutacc="BIGacc-pair.txtu";
    $fileOutrel="BIGrel-pair.txtu";
    $fhout_acc="FHOUT_acc";
    $fhout_rel="FHOUT_rel";
    
    open($fhout_acc,">".$fileOutacc);
    open($fhout_rel,">".$fileOutrel);
    print $fhout_acc "OACC",$sep,"PACC","\n";
    print $fhout_rel "OREL",$sep,"PREL","\n";
}

				# set to zero
foreach $ri (0..9){
    foreach $kwd1 ("riold","rinew"){
	$res{"histo",$kwd1,$ri}=0;
	foreach $kwd2 ("ok2","ok3"){
	    $res{"histo",$kwd1,$kwd2,$ri}=0;
	}
	foreach $kwd2 ("obs","prd"){
	    $res{"histo",$kwd1,"corr",$kwd2,$ri}="";
	}
    }}


foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n" if ($Ldebug);
#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    $id=$fileIn;
    $id=~s/^.*\///g;
    $id=~s/\..*$//g;
    $id=~s/\-.*$//g;
    ++$ctprot;
    $id[$ctprot]=$id;

    $ctres=0;
    while (<$fhin>) {
	next if ($_=~/^\#/);	# skip comments
	next if ($_=~/^No/);	# skip names
	$_=~s/\n//g;
	++$ctres;

# 1  2    3    4    5    6    7    8    9   10 11 12 13  14  15   16   17  18  19  20  21  22  23  24  25  26  27  28  29  30
#                                                                                      <1  <4  <9 <16 <25 <36 <49 <64 <81 <100
#No AA OHEL PHEL RI_S OACC PACC OREL PREL RI_A pH pE pL Obe Pbe Obie Pbie OtH OtE OtL Ot0 Ot1 Ot2 Ot3 Ot4 Ot5 Ot6 Ot7 Ot8 Ot9

	@tmp=split(/\t/,$_);
	$seq= $tmp[2];
	$oacc=$tmp[6];
	$pacc=$tmp[7];
    	$orel=$tmp[8];$orel=~s/\D//g;
	$prel=$tmp[9];$prel=~s/\D//g;
#	$ri_a=$tmp[10];
	@p10= @tmp[21..30];

	if ($orel!~/^\d+$/){
	    print "xx problem orel id=$id, ctres=$ctres, orel=$orel\n";exit;}
	if ($prel!~/^\d+$/){
	    print "xx problem prel id=$id, ctres=$ctres, prel=$prel\n";exit;}


	$prel2="b";
	$prel2="e" if ($prel>=$acc2Thresh);
	$orel2="b";
	$orel2="e" if ($orel>=$acc2Thresh);

				# three states
	$prel3="b";
	if    ($prel>=$acc3Thresh2){
	    $prel3="e";}
	elsif ($prel>=$acc3Thresh1){
	    $prel3="i";}
	$orel3="b";
	if    ($orel>=$acc3Thresh2){
	    $orel3="e";}
	elsif ($orel>=$acc3Thresh1){
	    $orel3="i";}

				# redo RI
	($Lok,$tmp,$ri,$rinew)=&get_ri("acc",100,@p10);
	
	++$res{"histo","riold",$ri};
	++$res{"histo","rinew",$rinew};
	++$totno;
	if ($prel2 =~/^$orel2$/){
	    ++$res{"histo","riold","ok2",$ri};
	    ++$res{"histo","rinew","ok2",$rinew};
	    ++$totok2;
	}
	if ($prel3 =~/^$orel3$/){
	    ++$res{"histo","riold","ok3",$ri};
	    ++$res{"histo","rinew","ok3",$rinew};
	    ++$totok3;
	}
				# correlation thingy
	$res{"histo","riold","corr","obs",$ri}.=",".$orel;
	$res{"histo","riold","corr","prd",$ri}.=",".$prel;
	$res{"histo","rinew","corr","obs",$rinew}.=",".$orel;
	$res{"histo","rinew","corr","prd",$rinew}.=",".$prel;

				# do the OACC-PACC thing
	if (0){
	    &accdiff_thing_oneres($oacc,$pacc,$prel,$seq);
	}
    }
    close($fhin);
    $res{$id,"nres"}=$ctres;
    
    if (0){
	&accdiff_thing_oneprot($ctres);
    }
}
				# sum ri
$nrestot=0;
foreach $ri (0..9){
    foreach $kwd1 ("riold","rinew"){
	$res{"histo",$kwd1,$ri}=0 if (! defined $res{"histo",$kwd1,$ri});
	foreach $kwd2 ("ok2"){
	    $res{"histo",$kwd1,$kwd2,$ri}=0 if (! defined $res{"histo",$kwd1,$kwd2,$ri});
	}
    }
    next if (! $res{"histo","riold",$ri});
    $nrestot+=$res{"histo","riold",$ri};
}


$wrt="# total no=$totno ok2=$totok2 p=".sprintf("%6.1f",100*($totok2/$totno))."ok3=$totok3 p=".sprintf("%6.1f",100*($totok3/$totno))."\n";
$wrt.=sprintf("%5s".
	      "$sep%5s$sep%5s".
	      "$sep%6s$sep%6s$sep%6s".
	      "$sep%6s$sep%6s$sep%6s".
	      "$sep%8s$sep%8s".
	      "$sep%5s$sep%5s".
	      "$sep%6s$sep%6s$sep%6s".
	      "$sep%6s$sep%6s$sep%6s".
	      "\n",
	      "ri",
	      "Nold","New",
	      "Pold","Pok2old","Pok3old",
	      "Pnew","Pok2new","Pok3new",
	      "corrOld","corrNew",
	      "NCold","NCnew",
	      "PCold","PCok2old","PCok3old",
	      "PCnew","PCok2new","PCok3new"
	      );

foreach $ri (0..9){
    $riinv=9-$ri;
    $oldno+= $res{"histo","riold",$riinv};
    $newno+= $res{"histo","rinew",$riinv};
    $oldok2+=$res{"histo","riold","ok2",$riinv};
    $newok2+=$res{"histo","rinew","ok2",$riinv};
    $oldok3+=$res{"histo","riold","ok3",$riinv};
    $newok3+=$res{"histo","rinew","ok3",$riinv};


    $pok2old=0;
    $pok2old=100*($res{"histo","riold","ok2",$riinv}/$res{"histo","riold",$riinv}) if ($res{"histo","riold",$riinv}>0);
    $pok2new=0;
    $pok2new=100*($res{"histo","rinew","ok2",$riinv}/$res{"histo","rinew",$riinv}) if ($res{"histo","rinew",$riinv}>0);

    $pok3old=0;
    $pok3old=100*($res{"histo","riold","ok3",$riinv}/$res{"histo","riold",$riinv}) if ($res{"histo","riold",$riinv}>0);
    $pok3new=0;
    $pok3new=100*($res{"histo","rinew","ok3",$riinv}/$res{"histo","rinew",$riinv}) if ($res{"histo","rinew",$riinv}>0);

    $pcok2old=0;
    $pcok2old=100*($oldok2/$oldno)  if ($oldno>0);
    $pcok2new=0;
    $pcok2new=100*($newok2/$newno)  if ($newno>0);

    $pcok3old=0;
    $pcok3old=100*($oldok3/$oldno)  if ($oldno>0);
    $pcok3new=0;
    $pcok3new=100*($newok3/$newno)  if ($newno>0);


    				# correlation
    $corold=$cornew=0;
    if ($res{"histo","riold",$riinv}>0){
	$res{"histo","riold","corr","obs",$riinv}=~s/^,*|,*$//g;
	$res{"histo","riold","corr","prd",$riinv}=~s/^,*|,*$//g;
	@tmpobs=split(/,/,$res{"histo","riold","corr","obs",$riinv});
	@tmpprd=split(/,/,$res{"histo","riold","corr","prd",$riinv});
	$nres=$#tmpobs;
	$corold=&correlation($nres,@tmpobs,@tmpprd);}
    if ($res{"histo","rinew",$riinv}>0){
	$res{"histo","rinew","corr","obs",$riinv}=~s/^,*|,*$//g;
	$res{"histo","rinew","corr","prd",$riinv}=~s/^,*|,*$//g;
	@tmpobs=split(/,/,$res{"histo","rinew","corr","obs",$riinv});
	@tmpprd=split(/,/,$res{"histo","rinew","corr","prd",$riinv});
	$nres=$#tmpobs;
	$cornew=&correlation($nres,@tmpobs,@tmpprd);
    }
    
    $wrt.=sprintf("%5d".
		  "$sep%5d$sep%5d".
		  "$sep%6.1f$sep%6.1f$sep%6.1f".
		  "$sep%6.1f$sep%6.1f$sep%6.1f".
		  "$sep%8.3f$sep%8.3f".
		  "$sep%5d$sep%5d".
		  "$sep%6.1f$sep%6.1f$sep%6.1f".
		  "$sep%6.1f$sep%6.1f$sep%6.1f".
		  "\n",
		  $riinv,
		  $res{"histo","riold",$riinv},$res{"histo","rinew",$riinv},
		  100*($res{"histo","riold",$riinv}/$nrestot),$pok2old,$pok3old,
		  100*($res{"histo","rinew",$riinv}/$nrestot),$pok2new,$pok3new,
		  $corold,$cornew,
		  $oldno,$newno,
		  100*($oldno/$nrestot),$pcok2old,$pcok3old,
		  100*($newno/$nrestot),$pcok2new,$pcok3new
		  );
}
print $wrt;

if (0){
    &accdiff_thing_protave($ctprot);
    &accdiff_thing_wrt($ctprot);
}

				# ------------------------------
				# (2) 
				# ------------------------------

				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout $wrt;
close($fhout);

if ($Lverb){
    print "--- output in $fileOut\n" if (-e $fileOut);
}
exit;


				# compile OACC-PACC for one residue, 
				# output: $res{$id,...}
sub accdiff_thing_oneres{
    ($oacctmp,$pacctmp,$preltmp,$seqtmp)=@_;

    $oacc_root=sqrt($oacctmp);
    $pacc_root=sqrt($pacctmp);

    $diff=$oacctmp-$pacctmp;
    $diff_abs=$oacctmp-$pacctmp; $diff_abs=(-1)*$diff_abs if ($diff_abs<0);
    $diff_square=($oacctmp-$pacctmp)**2; 
    $diff_root_abs=$oacc_root-$pacc_root; $diff_root_abs=(-1)*$diff_root_abs if ($diff_root_abs<0);
    $diff_root_square=($oacc_root-$pacc_root)**2; 
    
    $res{$id,"diff"}+=   $diff;
    $res{$id,"diff_abs"}+=   $diff_abs;
    $res{$id,"diff_square"}+=$diff_square;
    $res{$id,"diff_root_abs"}+=   $diff_root_abs;
    $res{$id,"diff_root_square"}+=$diff_root_square;
    
				# new stuff
    $prel_one=&convert_accRel10($preltmp);
    if (! defined $ACC_REL10_TO_AVESQUARE{$seqtmp,($prel_one)}){
#	    print "xx missing aa=$seq, prel=$prel_one, \n";
	$pacc_new=$pacctmp;
	$pacc_new_root=$pacc_root;
    }
    else {
#	$pacc_new=($prel/85)*$ACC_REL10_TO_AVESQUARE{$seqtmp,81};
	$pacc_new_root=sqrt($pacc_new);
    }

    $diff=$oacc-$pacc_new;
    $diff_abs=$oacc-$pacc_new; $diff_abs=(-1)*$diff_abs if ($diff_abs<0);
    $diff_square=($oacc-$pacc_new)**2; 
    $diff_root_abs=$oacc_root-$pacc_new_root; $diff_root_abs=(-1)*$diff_root_abs if ($diff_root_abs<0);
    $diff_root_square=($oacc_root-$pacc_new_root)**2; 

    $res{$id,"diffnew"}+=   $diff;
    $res{$id,"diffnew_abs"}+=   $diff_abs;
    $res{$id,"diffnew_square"}+=$diff_square;
    $res{$id,"diffnew_root_abs"}+=   $diff_root_abs;
    $res{$id,"diffnew_root_square"}+=$diff_root_square;
}

				# compile OACC-PACC for one protein
				# output: $res{$id,...}
sub accdiff_thing_oneprot{
    ($nrestmp)=@_;
    foreach $kwd ("diff","diff_abs","diff_square","diff_root_abs","diff_root_square",
		  "diffnew","diffnew_abs","diffnew_square","diffnew_root_abs","diffnew_root_square"){
	if ($kwd=~/diff_square|diffnew_square/){
	    $res{$id,$kwd}=sprintf("%6.2f",sqrt($res{$id,$kwd})/$nrestmp);}
	else{
	    $res{$id,$kwd}=sprintf("%6.2f",$res{$id,$kwd}/$nrestmp);
	}
	$res{$id,$kwd}=~s/\s//g;
    }
}

				# compile OACC-PACC: averages over all proteins
				# output: $res{$id,...}
sub accdiff_thing_protave{ 
    ($nprottmp)=@_;
    undef %sumdiff;
    foreach $it (1..$nprottmp){
	$id=$id[$it];
	foreach $kwd ("diff","diff_abs","diff_square","diff_root_abs","diff_root_square",
		      "diffnew","diffnew_abs","diffnew_square","diffnew_root_abs","diffnew_root_square"){
	    $sumdiff{$kwd}+=$res{$id,$kwd};
	}
    }

				# sums
    foreach $kwd ("diff","diff_abs","diff_square","diff_root_abs","diff_root_square",
		  "diffnew","diffnew_abs","diffnew_square","diffnew_root_abs","diffnew_root_square"){
	$sumdiff{$kwd}=sprintf("%6.2f",$sumdiff{$kwd}/$nprottmp);
	$sumdiff{$kwd}=~s/\s//g;
    }
}

				# compile OACC-PACC: write stuff
				# output: $wrt
sub accdiff_thing_wrt{ 
    ($nprottmp)=@_;
    $wrt="\# nprot=$nprottmp\n";
    foreach $kwd ("diff","diff_abs","diff_square","diff_root_abs","diff_root_square",
		  "diffnew","diffnew_abs","diffnew_square","diffnew_root_abs","diffnew_root_square"){
	$wrt.="\# sum ".sprintf("%-20s %6.2f\n",$kwd,$sumdiff{$kwd});
    }
    print $wrt;

    $fileOutTmp=$fileOut."_diffthing";
    open($fhout,">".$fileOutTmp) || warn "*** $scrName ERROR (accdiff_thing_wrt) creating fileOutTmp=$fileOutTmp";
    print $fhout $wrt;
    print $fhout
	"id",join("$sep",
		  "diff","diff_abs","diff_square","diff_root_abs","diff_root_square",
		  "diffnew","diffnew_abs","diffnew_square","diffnew_root_abs","diffnew_root_square"),"\n";
    
    foreach $it (1..$nprottmp){
	$id=$id[$it];
	$wrt=$id;
	foreach $kwd ("diff","diff_abs","diff_square","diff_root_abs","diff_root_square",
		      "diffnew","diffnew_abs","diffnew_square","diffnew_root_abs","diffnew_root_square"){
	    $wrt.=$sep.$res{$id,$kwd};
	}
	print $fhout $wrt,"\n";
    }

    close($fhout);

}

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

#===============================================================================
sub convert_accRel10 {
    local ($relaccin) = @_ ;
    local ($it,$valreturn);
#--------------------------------------------------------------------------------
#    convert_accRel10           converts relative accessibility (relacc) to relative acc in 10 states
#                               with state (i*i) <= accrel < (i+1)*(i+1) MAX=101
#         in:                   relative acc
#         out:                  converted (with return)
#--------------------------------------------------------------------------------

    $valreturn=81;
    foreach $it (1..9){
	if ($relaccin<($it+1)*($it+1) &&
	    $relaccin>=$it*$it){
	    $valreturn=$it*$it;
	    last;}
    }
    return $valreturn;
}				# end of convert_accRel10

#==========================================================================
sub exposure_normalise_prepare_rel2acc {
#    local ($mode) = @_;
#    $[=1;
#----------------------------------------------------------------------
#    exposure_normalise_prepare_rel2acc normalisation weights to
#    convert relative accessibility back to square angstroem number
#       rost, 2003, 11, 3: according to averages
#----------------------------------------------------------------------
      
    $ACC_REL10_TO_AVESQUARE{"R","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"R","1"}=6;
    $ACC_REL10_TO_AVESQUARE{"R","4"}=16;
    $ACC_REL10_TO_AVESQUARE{"R","9"}=31;
    $ACC_REL10_TO_AVESQUARE{"R","16"}=51;
    $ACC_REL10_TO_AVESQUARE{"R","25"}=76;
    $ACC_REL10_TO_AVESQUARE{"R","36"}=105;
    $ACC_REL10_TO_AVESQUARE{"R","49"}=138;
    $ACC_REL10_TO_AVESQUARE{"R","64"}=177;
    $ACC_REL10_TO_AVESQUARE{"R","81"}=218;

    $ACC_REL10_TO_AVESQUARE{"K","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"K","1"}=5;
    $ACC_REL10_TO_AVESQUARE{"K","4"}=14;
    $ACC_REL10_TO_AVESQUARE{"K","9"}=26;
    $ACC_REL10_TO_AVESQUARE{"K","16"}=42;
    $ACC_REL10_TO_AVESQUARE{"K","25"}=63;
    $ACC_REL10_TO_AVESQUARE{"K","36"}=87;
    $ACC_REL10_TO_AVESQUARE{"K","49"}=116;
    $ACC_REL10_TO_AVESQUARE{"K","64"}=147;
    $ACC_REL10_TO_AVESQUARE{"K","81"}=181;

    $ACC_REL10_TO_AVESQUARE{"D","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"D","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"D","4"}=10;
    $ACC_REL10_TO_AVESQUARE{"D","9"}=21;
    $ACC_REL10_TO_AVESQUARE{"D","16"}=34;
    $ACC_REL10_TO_AVESQUARE{"D","25"}=50;
    $ACC_REL10_TO_AVESQUARE{"D","36"}=69;
    $ACC_REL10_TO_AVESQUARE{"D","49"}=91;
    $ACC_REL10_TO_AVESQUARE{"D","64"}=117;
    $ACC_REL10_TO_AVESQUARE{"D","81"}=145;

    $ACC_REL10_TO_AVESQUARE{"E","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"E","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"E","4"}=12;
    $ACC_REL10_TO_AVESQUARE{"E","9"}=24;
    $ACC_REL10_TO_AVESQUARE{"E","16"}=40;
    $ACC_REL10_TO_AVESQUARE{"E","25"}=59;
    $ACC_REL10_TO_AVESQUARE{"E","36"}=83;
    $ACC_REL10_TO_AVESQUARE{"E","49"}=109;
    $ACC_REL10_TO_AVESQUARE{"E","64"}=139;
    $ACC_REL10_TO_AVESQUARE{"E","81"}=171;
      
    $ACC_REL10_TO_AVESQUARE{"H","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"H","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"H","4"}=12;
    $ACC_REL10_TO_AVESQUARE{"H","9"}=23;
    $ACC_REL10_TO_AVESQUARE{"H","16"}=37;
    $ACC_REL10_TO_AVESQUARE{"H","25"}=56;
    $ACC_REL10_TO_AVESQUARE{"H","36"}=78;
    $ACC_REL10_TO_AVESQUARE{"H","49"}=103;
    $ACC_REL10_TO_AVESQUARE{"H","64"}=132;
    $ACC_REL10_TO_AVESQUARE{"H","81"}=163;
      
    $ACC_REL10_TO_AVESQUARE{"Q","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"Q","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"Q","4"}=12;
    $ACC_REL10_TO_AVESQUARE{"Q","9"}=25;
    $ACC_REL10_TO_AVESQUARE{"Q","16"}=41;
    $ACC_REL10_TO_AVESQUARE{"Q","25"}=61;
    $ACC_REL10_TO_AVESQUARE{"Q","36"}=85;
    $ACC_REL10_TO_AVESQUARE{"Q","49"}=111;
    $ACC_REL10_TO_AVESQUARE{"Q","64"}=141;
    $ACC_REL10_TO_AVESQUARE{"Q","81"}=174;

    $ACC_REL10_TO_AVESQUARE{"N","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"N","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"N","4"}=10;
    $ACC_REL10_TO_AVESQUARE{"N","9"}=20;
    $ACC_REL10_TO_AVESQUARE{"N","16"}=33;
    $ACC_REL10_TO_AVESQUARE{"N","25"}=48;
    $ACC_REL10_TO_AVESQUARE{"N","36"}=67;
    $ACC_REL10_TO_AVESQUARE{"N","49"}=88;
    $ACC_REL10_TO_AVESQUARE{"N","64"}=113;
    $ACC_REL10_TO_AVESQUARE{"N","81"}=140;

    $ACC_REL10_TO_AVESQUARE{"S","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"S","1"}=3;
    $ACC_REL10_TO_AVESQUARE{"S","4"}=8;
    $ACC_REL10_TO_AVESQUARE{"S","9"}=16;
    $ACC_REL10_TO_AVESQUARE{"S","16"}=26;
    $ACC_REL10_TO_AVESQUARE{"S","25"}=39;
    $ACC_REL10_TO_AVESQUARE{"S","36"}=55;
    $ACC_REL10_TO_AVESQUARE{"S","49"}=73;
    $ACC_REL10_TO_AVESQUARE{"S","64"}=94;
    $ACC_REL10_TO_AVESQUARE{"S","81"}=115;

    $ACC_REL10_TO_AVESQUARE{"T","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"T","1"}=3;
    $ACC_REL10_TO_AVESQUARE{"T","4"}=9;
    $ACC_REL10_TO_AVESQUARE{"T","9"}=17;
    $ACC_REL10_TO_AVESQUARE{"T","16"}=29;
    $ACC_REL10_TO_AVESQUARE{"T","25"}=43;
    $ACC_REL10_TO_AVESQUARE{"T","36"}=60;
    $ACC_REL10_TO_AVESQUARE{"T","49"}=79;
    $ACC_REL10_TO_AVESQUARE{"T","64"}=101;
    $ACC_REL10_TO_AVESQUARE{"T","81"}=126;

    $ACC_REL10_TO_AVESQUARE{"I","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"I","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"I","4"}=11;
    $ACC_REL10_TO_AVESQUARE{"I","9"}=21;
    $ACC_REL10_TO_AVESQUARE{"I","16"}=34;
    $ACC_REL10_TO_AVESQUARE{"I","25"}=51;
    $ACC_REL10_TO_AVESQUARE{"I","36"}=71;
    $ACC_REL10_TO_AVESQUARE{"I","49"}=94;
    $ACC_REL10_TO_AVESQUARE{"I","64"}=120;
    $ACC_REL10_TO_AVESQUARE{"I","81"}=150;

    $ACC_REL10_TO_AVESQUARE{"L","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"L","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"L","4"}=10;
    $ACC_REL10_TO_AVESQUARE{"L","9"}=20;
    $ACC_REL10_TO_AVESQUARE{"L","16"}=33;
    $ACC_REL10_TO_AVESQUARE{"L","25"}=49;
    $ACC_REL10_TO_AVESQUARE{"L","36"}=69;
    $ACC_REL10_TO_AVESQUARE{"L","49"}=92;
    $ACC_REL10_TO_AVESQUARE{"L","64"}=117;
    $ACC_REL10_TO_AVESQUARE{"L","81"}=145;

    $ACC_REL10_TO_AVESQUARE{"M","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"M","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"M","4"}=12;
    $ACC_REL10_TO_AVESQUARE{"M","9"}=23;
    $ACC_REL10_TO_AVESQUARE{"M","16"}=38;
    $ACC_REL10_TO_AVESQUARE{"M","25"}=57;
    $ACC_REL10_TO_AVESQUARE{"M","36"}=79;
    $ACC_REL10_TO_AVESQUARE{"M","49"}=105;
    $ACC_REL10_TO_AVESQUARE{"M","64"}=135;
    $ACC_REL10_TO_AVESQUARE{"M","81"}=168;

    $ACC_REL10_TO_AVESQUARE{"F","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"F","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"F","4"}=12;
    $ACC_REL10_TO_AVESQUARE{"F","9"}=24;
    $ACC_REL10_TO_AVESQUARE{"F","16"}=40;
    $ACC_REL10_TO_AVESQUARE{"F","25"}=59;
    $ACC_REL10_TO_AVESQUARE{"F","36"}=82;
    $ACC_REL10_TO_AVESQUARE{"F","49"}=110;
    $ACC_REL10_TO_AVESQUARE{"F","64"}=141;
    $ACC_REL10_TO_AVESQUARE{"F","81"}=175;

    $ACC_REL10_TO_AVESQUARE{"V","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"V","1"}=3;
    $ACC_REL10_TO_AVESQUARE{"V","4"}=9;
    $ACC_REL10_TO_AVESQUARE{"V","9"}=17;
    $ACC_REL10_TO_AVESQUARE{"V","16"}=29;
    $ACC_REL10_TO_AVESQUARE{"V","25"}=43;
    $ACC_REL10_TO_AVESQUARE{"V","36"}=60;
    $ACC_REL10_TO_AVESQUARE{"V","49"}=79;
    $ACC_REL10_TO_AVESQUARE{"V","64"}=101;
    $ACC_REL10_TO_AVESQUARE{"V","81"}=126;

    $ACC_REL10_TO_AVESQUARE{"W","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"W","1"}=6;
    $ACC_REL10_TO_AVESQUARE{"W","4"}=15;
    $ACC_REL10_TO_AVESQUARE{"W","9"}=28;
    $ACC_REL10_TO_AVESQUARE{"W","16"}=46;
    $ACC_REL10_TO_AVESQUARE{"W","25"}=68;
    $ACC_REL10_TO_AVESQUARE{"W","36"}=94;
    $ACC_REL10_TO_AVESQUARE{"W","49"}=127;
    $ACC_REL10_TO_AVESQUARE{"W","64"}=162;
    $ACC_REL10_TO_AVESQUARE{"W","81"}=201;

    $ACC_REL10_TO_AVESQUARE{"Y","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"Y","1"}=5;
    $ACC_REL10_TO_AVESQUARE{"Y","4"}=14;
    $ACC_REL10_TO_AVESQUARE{"Y","9"}=27;
    $ACC_REL10_TO_AVESQUARE{"Y","16"}=45;
    $ACC_REL10_TO_AVESQUARE{"Y","25"}=66;
    $ACC_REL10_TO_AVESQUARE{"Y","36"}=93;
    $ACC_REL10_TO_AVESQUARE{"Y","49"}=123;
    $ACC_REL10_TO_AVESQUARE{"Y","64"}=158;
    $ACC_REL10_TO_AVESQUARE{"Y","81"}=195;

    $ACC_REL10_TO_AVESQUARE{"P","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"P","1"}=3;
    $ACC_REL10_TO_AVESQUARE{"P","4"}=9;
    $ACC_REL10_TO_AVESQUARE{"P","9"}=17;
    $ACC_REL10_TO_AVESQUARE{"P","16"}=27;
    $ACC_REL10_TO_AVESQUARE{"P","25"}=41;
    $ACC_REL10_TO_AVESQUARE{"P","36"}=57;
    $ACC_REL10_TO_AVESQUARE{"P","49"}=77;
    $ACC_REL10_TO_AVESQUARE{"P","64"}=98;
    $ACC_REL10_TO_AVESQUARE{"P","81"}=120;

    $ACC_REL10_TO_AVESQUARE{"C","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"C","1"}=3;
    $ACC_REL10_TO_AVESQUARE{"C","4"}=9;
    $ACC_REL10_TO_AVESQUARE{"C","9"}=16;
    $ACC_REL10_TO_AVESQUARE{"C","16"}=27;
    $ACC_REL10_TO_AVESQUARE{"C","25"}=40;
    $ACC_REL10_TO_AVESQUARE{"C","36"}=56;
    $ACC_REL10_TO_AVESQUARE{"C","49"}=75;
    $ACC_REL10_TO_AVESQUARE{"C","64"}=97;
    $ACC_REL10_TO_AVESQUARE{"C","81"}=117;

    $ACC_REL10_TO_AVESQUARE{"A","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"A","1"}=3;
    $ACC_REL10_TO_AVESQUARE{"A","4"}=7;
    $ACC_REL10_TO_AVESQUARE{"A","9"}=13;
    $ACC_REL10_TO_AVESQUARE{"A","16"}=21;
    $ACC_REL10_TO_AVESQUARE{"A","25"}=32;
    $ACC_REL10_TO_AVESQUARE{"A","36"}=45;
    $ACC_REL10_TO_AVESQUARE{"A","49"}=59;
    $ACC_REL10_TO_AVESQUARE{"A","64"}=76;
    $ACC_REL10_TO_AVESQUARE{"A","81"}=93;

    $ACC_REL10_TO_AVESQUARE{"G","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"G","1"}=2;
    $ACC_REL10_TO_AVESQUARE{"G","4"}=5;
    $ACC_REL10_TO_AVESQUARE{"G","9"}=10;
    $ACC_REL10_TO_AVESQUARE{"G","16"}=17;
    $ACC_REL10_TO_AVESQUARE{"G","25"}=25;
    $ACC_REL10_TO_AVESQUARE{"G","36"}=36;
    $ACC_REL10_TO_AVESQUARE{"G","49"}=47;
    $ACC_REL10_TO_AVESQUARE{"G","64"}=61;
    $ACC_REL10_TO_AVESQUARE{"G","81"}=74;

    				# B: D or N
    $ACC_REL10_TO_AVESQUARE{"B","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"B","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"B","4"}=10;
    $ACC_REL10_TO_AVESQUARE{"B","9"}=20;
    $ACC_REL10_TO_AVESQUARE{"B","16"}=33;
    $ACC_REL10_TO_AVESQUARE{"B","25"}=49;
    $ACC_REL10_TO_AVESQUARE{"B","36"}=68;
    $ACC_REL10_TO_AVESQUARE{"B","49"}=90;
    $ACC_REL10_TO_AVESQUARE{"B","64"}=115;
    $ACC_REL10_TO_AVESQUARE{"B","81"}=143;
    
   				# Z:  E  or  Q
    $ACC_REL10_TO_AVESQUARE{"Z","0"}=0;
    $ACC_REL10_TO_AVESQUARE{"Z","1"}=4;
    $ACC_REL10_TO_AVESQUARE{"Z","4"}=12;
    $ACC_REL10_TO_AVESQUARE{"Z","9"}=25;
    $ACC_REL10_TO_AVESQUARE{"Z","16"}=40;
    $ACC_REL10_TO_AVESQUARE{"Z","25"}=60;
    $ACC_REL10_TO_AVESQUARE{"Z","36"}=83;
    $ACC_REL10_TO_AVESQUARE{"Z","49"}=110;
    $ACC_REL10_TO_AVESQUARE{"Z","64"}=140;
    $ACC_REL10_TO_AVESQUARE{"Z","81"}=172;
}				# end of exposure_normalise_prepare_rel2acc 

#===============================================================================
sub stat_avevar {
    local(@data)=@_;
    local($i, $ave, $var);
    $[=1;
#----------------------------------------------------------------------
#   stat_avevar                 computes average and variance
#       in:                     @data (vector)
#       out:                    $AVE, $VAR
#          GLOBAL:              $AVE, $VAR (returned as list)
#----------------------------------------------------------------------
    $ave=$var=0;
				# no data
    return(0,0)                 if ($#data < 1);
				# compile sum
    foreach $i (@data) { 
	$ave+=$i; } 
				# get average
    $AVE=$VAR=0;
    $AVE=($ave/$#data);
				# get variance
    foreach $i (@data) { 
	$tmp=($i-$AVE); 
	$var+=($tmp*$tmp); } 
    $VAR=($var/($#data-1))      if ($#data > 1);
    return ($AVE,$VAR);
}				# end of stat_avevar

#================================================================================
sub correlation {
    local($ncol, @data) = @_;
    local($it, $av1, $av2, $av11, $av22, $av12);
    local(@v1,@v2,@v11,@v12,@v22, $den, $dentmp, $nom);
    $[ =1;
#----------------------------------------------------------------------
#   correlation                 compiles the correlation between x and y
#       in:                     ncol,@data, where $data[1..ncol] =@x, rest @y
#       out:                    returned $COR=correlation
#       out GLOBAL:             COR, AVE, VAR
#----------------------------------------------------------------------

    $#v1=0;$#v2=0;
    for ($it=1;$it<=$#data;++$it) {
	if ($it<=$ncol) { 
	    push(@v1,$data[$it]); 
	    if ($data[$it]=~/\D/ || $data[$it] !~/\d/){
		print "xx problem it=$it, data(v1)=$data[$it],\n";die;}
	}
	else            { 
	    push(@v2,$data[$it]); 
	    if ($data[$it]=~/\D/ || $data[$it] !~/\d/){
		print "xx problem it=$it, data(v2)=$data[$it],\n";die;}
	}
    }
    @v1=@data[1..$ncol];
    @v2=@data[($ncol+1)..$#data];
#   ------------------------------
#   <1> and <2>
#   ------------------------------
    ($av1,$tmp)=&stat_avevar(@v1); 
    ($av2,$tmp)=&stat_avevar(@v2);

#   ------------------------------
#   <11> and <22> and <12y>
#   ------------------------------
    for ($it=1;$it<=$#v1;++$it) { $v11[$it]=$v1[$it]*$v1[$it];} ($av11,$tmp)=&stat_avevar(@v11);
    for ($it=1;$it<=$#v2;++$it) { $v22[$it]=$v2[$it]*$v2[$it];} ($av22,$tmp)=&stat_avevar(@v22);
    for ($it=1;$it<=$#v1;++$it) { $v12[$it]=$v1[$it]*$v2[$it];} ($av12,$tmp)=&stat_avevar(@v12);

#   --------------------------------------------------
#   nom = <12> - <1><2>
#   den = sqrt ( (<11>-<1><1>)*(<22>-<2><2>) )
#   --------------------------------------------------
    $nom=($av12-($av1*$av2));
    $dentmp=( ($av11 - ($av1*$av1)) * ($av22 - ($av2*$av2)) );
    $den="NN";
    $COR="NN";
    $den=sqrt($dentmp)          if ($dentmp>0);
    return($COR)                if ($den eq "NN");
    $COR=$nom/$den              if ($den<-0.00000000001 || $den>0.00000000001);
    return($COR);
}				# end of correlation

#===============================================================================
sub func_absolute {
    local ($num)=@_;local ($tmp);
#----------------------------------------------------------------------
#   func_absolute               compiles the absolute value
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
    if ($num>=0){
	return($num);}
    else {
	$tmp=(-1)*$num;
	return($tmp);}
}				# end of func_absolute

#===============================================================================
sub get_outAcc {
    local($modeoutLoc,$accBuriedSat,$acc2Thresh,$acc3Thresh1,$acc3Thresh2,
	  $bitaccLoc,@vecLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_outAcc                  relative accessibility value for acc=be|bie !
#                               formula e.g. 'be', thresh=16
#                               1:  winner=unit 1 (for b), value=0.75
#                               ->  acc= 16 - (16-0)*   2*(0.75-0.5) 
#                                      =  8
#                               2:  winner=unit 2 (for e), value=0.75
#                               ->  acc= 16 + (100-16)* 2*(0.75-0.5)
#                                      = 58
#       in:                     $modeout:       some unique description of output coding (HEL)
#       in:                     $modeoutLoc:    <BE|BIE|10>
#       in:                     $acc2Thresh:    threshold for 2-state acc, b: acc<=thresh, e: else
#       in:                     $acc3Thresh:    'T1,T2' threshold for 3-state acc, 
#                                               b: acc<=T1, i: T1<acc<=T2, e: acc>T2
#       in:                     $accBuriedSat:  2|3-state model if accPrd < -> 0
#       in:                     $bitacc:        accuracy of @vec, i.e. output= integers, out/bitacc = real
#       in:                     @vec:           output vector 
#                               
#       in GLOBAL:                                      
#                               
#                               
#       out:                    1|0,msg,$accRel
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_outAcc";
				# check arguments
    return(&errSbr("not def modeoutLoc!",$SBR6),0)          if (! defined $modeoutLoc);
    return(&errSbr("not def accBuriedSat!",$SBR6),0)        if (! defined $accBuriedSat);
    return(&errSbr("not def acc2Thresh!",$SBR6),0)          if (! defined $acc2Thresh);
    return(&errSbr("not def acc3Thresh1!",$SBR6),0)         if (! defined $acc3Thresh1);
    return(&errSbr("not def acc3Thresh2!",$SBR6),0)         if (! defined $acc3Thresh2);
    return(&errSbr("bitaccLoc < 1!",$SBR6),0)               if ($bitaccLoc<1);
    return(&errSbr("no vector (vecLoc,$SBR6)!"),0)          if (! defined @vecLoc || $#vecLoc<1);

    $undecidedLoc=$bitaccLoc*0.5 if (! defined $undecidedLoc);

    $acc="";
				# ------------------------------
				# ACC 2 states -> rel acc
				# ------------------------------
    if ($modeoutLoc eq "be") {
				# ->  acc= 16 - (16-0)*   2 * (val - 0.5) 
	if ($vecLoc[1] > $vecLoc[2]) {
	    $diff=(2 / $bitaccLoc) * ($vecLoc[1] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $diff=1             if ($diff >= $accBuriedSat); # correct for high reliability buried!
	    $acc=$acc2Thresh - (    $acc2Thresh    * $diff ); }
				# ->  acc= 16 + (100-16)* 2*  (val - 0.5)
	else {
	    $diff=(2 / $bitaccLoc) * ($vecLoc[2] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $acc=$acc2Thresh + ( (100-$acc2Thresh) * $diff ); }}

				# ------------------------------
				# ACC 3 states -> rel acc
				# ------------------------------
    if ($modeoutLoc eq "bie") {
				# ->  acc= 4 - (4-0)*     2 * (val - 0.5) 
	if    ($vecLoc[1] > $vecLoc[2] &&
	       $vecLoc[1] > $vecLoc[3]) {
	    $diff=(2 / $bitaccLoc) * ($vecLoc[1] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $diff=1             if ($diff >= $accBuriedSat); # correct for high reliability buried!
	    $acc=$acc3Thresh1 - ( $acc3Thresh1          * $diff ); }
				# ->  acc= 4 + (25-4)*    2*  (val - 0.5)
	elsif ($vecLoc[2] > $vecLoc[3]){
	    $diff=(2 / $bitaccLoc) * ($vecLoc[2] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $acc=$acc3Thresh1 + ( ($acc3Thresh2-$acc3Thresh1) * $diff ); }
				# ->  acc= 25 + (100-25)* 2*  (val - 0.5)
	else {
	    $diff=(2 / $bitaccLoc) * ($vecLoc[3] - $undecidedLoc); $diff=0 if ($diff < 0);
	    $acc=$acc3Thresh2 + ( (100-$acc3Thresh2)    * $diff ); }}
    $acc=int($acc);

    return(1,"ok $SBR6",$acc);
}				# end of get_outAcc

#===============================================================================
sub get_outAccBE {
    local($accRelLoc,$acc2Thresh,@prdLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_outAccBE                converts  relative accessibility + actual output
#                               values to two-state model Buried Exposed
#       in:                     $accRelLoc:     relative accessibility
#       in:                     $acc2Thresh:    threshold for 2-state acc, b: acc<=thresh, e: else
#       in:                     @prdLoc:        output vector 
#                               
#       in GLOBAL:                                      
#                               
#                               
#       out:                    1|0,msg,$accRel
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_outAccBE";
				# check arguments
    return(&errSbr("not def accRelLoc!",  $SBR6),0)        if (! defined $accRelLoc);
    return(&errSbr("not def acc2Thresh!", $SBR6),0)        if (! defined $acc2Thresh);
    return(&errSbr("no vector (prdLoc)!", $SBR6),0)        if (! defined @prdLoc || $#prdLoc<1);

				# ------------------------------
				# fast end for others
    if ($#prdLoc<10 || ! $par{"optAcc10Filter2"}){
	return(1,"ok",$acc2SymbolLoc[1]) if ($accRelLoc <= $acc2Thresh);
	return(1,"ok",$acc2SymbolLoc[2]);}

				# ------------------------------
				# compile averages over each state 
				#    for 10 state prediction
    if ($#prdLoc==10){
	$#tmp=$#cttmp=0;
	foreach $itout (1..$#prdLoc){
				# is buried
	    if ((($itout-1)*$itout)<=$acc2Thresh){
		++$cttmp[1];++$tmp[1];}
	    else {		# is exposed
		++$cttmp[2];++$tmp[2];}}
				# normalise
	$max=$pos=0;
	foreach $it (1,2){
	    $tmp[$it]=0; 
	    $tmp[$it]=$tmp[$it]/$cttmp[$it] if ($cttmp[$it]>0);
	    if ($max < $tmp[$it]){
		$max=$tmp[$it];
		$pos=$it;}}
				# now winner gets it
	return(1,"ok",$acc2SymbolLoc[$pos]) if ($pos>0);
				# undecided: give it to traditional winner
	return(1,"ok",$acc2SymbolLoc[1])    if ($accRelLoc <= $acc2Thresh);
	return(1,"ok",$acc2SymbolLoc[2]); }

    return(0,"should have never come here:$SBR6!",0);
}				# end of get_outAccBE

#===============================================================================
sub get_outAccBIE {
    local($accRelLoc,$acc3Thresh1,$acc3Thresh2,@prdLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_outAccBIE               converts  relative accessibility + actual output
#                               values to two-state model Buried Exposed
#       in:                     $accRelLoc:     relative accessibility
#       in:                     $acc3Thresh:    'T1,T2' threshold for 3-state acc, 
#                                               b: acc<=T1, i: T1<acc<=T2, e: acc>T2
#       in:                     @prdLoc:        output vector 
#                               
#       in GLOBAL:                                      
#                               
#                               
#       out:                    1|0,msg,$accRel
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_outAccBIE";
				# check arguments
    return(&errSbr("not def accRelLoc!",  $SBR6),0)        if (! defined $accRelLoc);
    return(&errSbr("not def acc3Thresh1!",$SBR6),0)        if (! defined $acc3Thresh1);
    return(&errSbr("not def acc3Thresh2!",$SBR6),0)        if (! defined $acc3Thresh2);
    return(&errSbr("no vector (prdLoc)!", $SBR6),0)        if (! defined @prdLoc || $#prdLoc<1);

				# ------------------------------
				# compile averages over each state 
				#    for 10 state prediction
    if ($#prdLoc==10){
	$#tmp=$#cttmp=0;
	foreach $itout (1..$#prdLoc){
				# is buried
	    if    ((($itout-1)*$itout) <= $acc3Thresh1){
		++$cttmp[1];++$tmp[1];}
				# is exposed
	    elsif ((($itout-1)*$itout) >  $acc3Thresh2){
		++$cttmp[3];++$tmp[3];}
	    else {		# is intermediate
		++$cttmp[2];++$tmp[2];}}
				# normalise
	$max=$pos=0;
	foreach $it (1,2,3){
	    $tmp[$it]=0; 
	    $tmp[$it]=$tmp[$it]/$cttmp[$it] if ($cttmp[$it]>0);
	    if ($max < $tmp[$it]){
		$max=$tmp[$it];
		$pos=$it;}}
				# now winner gets it
	return(1,"ok",$acc3SymbolLoc[$pos]) if ($pos>0);
				# undecided: give it to traditional winner
	return(1,"ok",$acc3SymbolLoc[1]) if ($accRelLoc <= $acc3Thresh1);
	return(1,"ok",$acc3SymbolLoc[3]) if ($accRelLoc >  $acc3Thresh2);
	return(1,"ok",$acc3SymbolLoc[2]); }

				# ------------------------------
				# fast end for others
    if ($#prdLoc<10){
	return(1,"ok",$acc3SymbolLoc[1]) if ($accRelLoc <= $acc3Thresh1);
	return(1,"ok",$acc3SymbolLoc[3]) if ($accRelLoc >  $acc3Thresh2);
	return(1,"ok",$acc3SymbolLoc[2]); } 

    return(0,"should have never come here:$SBR6!",0);
}				# end of get_outAccBIE

#===============================================================================
sub get_outSym {
    local($modepredLoc,$posWinLoc,@outnum2symLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_outSym                  returns symbol for output winner
#       in:                     $modepred:      short description of what the job is about
#       in:                     $posWin:        number of output unit with highest value
#       in:                     @outnum2sym:    's1,s2,s3' symbols for output units (e.g. 'H,E,L')
#       out:                    1|0,msg,$sym
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_outSym";
				# check arguments
    return(&errSbr("not def modepredLoc!",$SBR6),0)      if (! defined $modepredLoc);
    return(&errSbr("not def posWinLoc!",$SBR6),0)        if (! defined $posWinLoc);
    return(&errSbr("not def outnum2symLoc!",$SBR6),0)    if (! defined @outnum2symLoc || 
							     $#outnum2symLoc<1);
    return(&errSbr("numout must be > 1, here",$SBR6),0)  if ($#outnum2symLoc<2);
    return(&errSbr("undefined symbol for posWinLoc=$posWinLoc, outnum2symLoc=".
                   join(',',@outnum2symLoc,$SBR6)),0)    if ($#outnum2symLoc<$posWinLoc);
                                # ------------------------------
                                # sec|htm|acc (2,3 states)
    if    ($modepredLoc eq "sec" || $modepredLoc eq "htm" ||
        ($modepredLoc eq "acc" && $#outnum2symLoc<=3) ){
        return(&errSbr("for mode=$modepredLoc, should be more than ".$#outnum2symLoc.
                       " output units",$SBR6),0) if ($#outnum2symLoc<2);
        $sym=$outnum2symLoc[$posWinLoc];
        return(1,"ok $SBR6",$sym); }
                                # <--- OK
                                # <--- <--- <--- <--- <--- <--- 

                                # ------------------------------
                                # acc (10 states)
    elsif ($modepredLoc eq "acc" && $#outnum2symLoc>3) {
        return(&errSbr("for mode=acc, should be more less than ".$#outnum2symLoc.
                       " output units",$SBR6),0) if ($#outnum2symLoc>10);
        $sym=$posWinLoc-1;
        return(1,"ok $SBR6",$sym); }
                                # <--- OK
                                # <--- <--- <--- <--- <--- <--- 
                                # ------------------------------
                                # unk
    else { 
        return(&errSbr("combination of modepredLoc=$modepredLoc, numout=".$#outnum2symLoc.
                       ", unknown",$SBR6),0); }

    return(0,"*** ERROR $SBR6: should have never come her...",0);
}				# end of get_outSym

#===============================================================================
sub get_ri {
    local($modepredLoc,$bitaccLoc,@vecLoc) = @_ ;
    my($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   get_ri                      compiles the reliability index from FORTRAN output
#       in:                     $modepred:      short description of what the job is about
#       in:                     $bitacc:        accuracy of @vec, i.e. output= integers, 
#       in:                                     out/bitacc = real
#       in:                     @vec:           output vector 
#       out:                    1|0,msg,$ri
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."get_ri";
				# check arguments
    return(&errSbr("not def modepredLoc!",$SBR6),0)         if (! defined $modepredLoc);
    return(&errSbr("not def bitaccLoc!",$SBR6),0)           if (! defined $bitaccLoc);
    return(&errSbr("bitaccLoc < 1!",$SBR6),0)               if ($bitaccLoc<1);
    return(&errSbr("no vector (vecLoc,$SBR6)!"),0)          if (! defined @vecLoc || $#vecLoc<1);
                                # --------------------------------------------------
                                # distinguish prediction modes
                                # --------------------------------------------------
                                # ------------------------------
                                # sec|htm|acc (2,3 states)
    if    ($modepredLoc eq "sec" || $modepredLoc eq "htm" ||
        ($modepredLoc eq "acc" && $#vecLoc<=3) ){
        return(&errSbr("for mode=$modepredLoc, should be more than ".
		       $#vecLoc." output units",$SBR6),0) 
            if ($#vecLoc<2);
        $max=$max2=0;
        foreach $itout (1..$#vecLoc){
            if    ($vecLoc[$itout]>$max) { 
                $max2=$max;$max=$vecLoc[$itout];}
            elsif ($vecLoc[$itout]>$max2){ 
                $max2=$vecLoc[$itout];}}
                                # define reliability index
        $ri=int( 10 * ($max-$max2)/$bitaccLoc );  $ri=0 if ($ri<0); $ri=9 if ($ri>9);
        return(1,"ok $SBR6",$ri);}
                                # <--- OK
                                # <--- <--- <--- <--- <--- <--- 

                                # ------------------------------
                                # acc (10 states)
    elsif ($modepredLoc eq "acc" && $#vecLoc>3) {
        return(&errSbr("for mode=acc, wrong number of vectors, should be <10 is=".
		       $#vecLoc." output units",$SBR6),0) 
            if ($#vecLoc>10);
        $max=$pos=$max2=$pos2=0;
        foreach $itout (1..$#vecLoc){ # max
            if ($vecLoc[$itout]>$max) { 
                $max=$vecLoc[$itout]; $pos=$itout;}}
        foreach $itout (1..$#vecLoc){ # 2nd best, at least three units away!
            if ($vecLoc[$itout]>$max2 && ( $itout < ($pos-2) || $itout > ($pos+2) ) ){
                $max2=$vecLoc[$itout]; $pos2=$itout;}}
				# correct if 2nd too close
	$max2=0                 if (&func_absolute($pos2-$pos)<3);
            
#        return(&errSbr("for mode=acc and numout=".$#vecLoc.", the maximal unit was found to be:$pos, ".
#                       "the 2nd:$pos2, this is less than 2 units apart (out=".
#		       join(',',@vecLoc).")",$SBR6),0)
                                # define reliability index
        $ri=int( 30 * ($max-$max2)/$bitaccLoc );  
	$ri=0 if ($ri<0); $ri=9 if ($ri>9);


				# try 2 units away
        $max=$pos=$max2=$pos2=0;
        foreach $itout (1..$#vecLoc){ # max
            if ($vecLoc[$itout]>$max) { 
                $max=$vecLoc[$itout]; $pos=$itout;}}
        foreach $itout (1..$#vecLoc){ # 2nd best, at least three units away!
            if ($vecLoc[$itout]>$max2 && ( $itout < ($pos-1) || $itout > ($pos+1) ) ){
                $max2=$vecLoc[$itout]; $pos2=$itout;}}
				# correct if 2nd too close
	$max2=0                 if (&func_absolute($pos2-$pos)<2);
	$rixx=int( 50 * ($max-$max2)/$bitaccLoc );  
	$rixx=0 if ($rixx<0); $rixx=9 if ($rixx>9);


				# try 2 state shit
	$valb=$vale=0;
	foreach $it (1..4){
	    $valb+=$vecLoc[$it];
	}
	foreach $it (5..$#vecLoc){
	    $vale+=$vecLoc[$it];
	}
	$valb=$valb/4;
	$vale=$vale/6;
	$sumval=$valb+$vale;

	$diff=0;
        if    ($valb==$vale){
	    $rixx=0;}
	elsif ($valb>$vale){
	    $diff=$valb-$vale;}
	else {
	    $diff=$vale-$valb;}
	if ($diff){
	    $diff_frac=$diff/$sumval;
	    $factor=10+int($diff_frac*4);
#	    $factor=10+int($ri/1.5);
	    $rixx=int( $factor * $diff_frac );
	}

	$rixx=0 if ($rixx<0); $rixx=9 if ($rixx>9);
	$rixx2=$rixx;

				# try 3 state shit
	$valb=$vale=$vali=0;
	foreach $it (1..3){
	    $valb+=$vecLoc[$it];
	}
	foreach $it (4..6){
	    $vali+=$vecLoc[$it];
	}
	foreach $it (7..$#vecLoc){
	    $vale+=$vecLoc[$it];
	}
	$valb=$valb/3;
	$vali=$vali/3;
	$vale=$vale/4;
	$sumval=$valb+$vali+$vale;
	$valxx[1]=$valb;
	$valxx[2]=$vali;
	$valxx[3]=$vale;

				# try 2 units away
        $max=$pos=$max2=$pos2=0;
	foreach $itout (1..3){
            if ($valxx[$itout]>$max) { 
                $max=$valxx[$itout]; $pos=$itout;}}
        foreach $itout (1..3){ # 2nd best, at least three units away!
	    next if ($itout == $pos);
            if ($valxx[$itout]>$max2){
                $max2=$valxx[$itout]; $pos2=$itout;}
	}

#        $rixx=int( 20 * ($max-$max2)/$sumval );  
	$diff=$max-$max2;
	$diff_frac=$diff/$sumval;
	$factor=15+int($diff_frac*10);
#	  $factor=10+int($ri/1.5);
	$rixx=int( $factor * $diff_frac );

	$rixx=0 if ($rixx<0); $rixx=9 if ($rixx>9);
	$rixx3=$rixx;



        return(1,"ok $SBR6",$ri,$rixx2);}
                                # <--- OK
                                # <--- <--- <--- <--- <--- <--- 

                                # ------------------------------
    else {                      # unk
        return(&errSbr("combination of modepredLoc=$modepredLoc, numout=".$#vecLoc.", unknown",
                       $SBR6),0);}
        
    return(0,"*** ERROR $SBR6: should have never come her...",0);
}				# end of get_ri

