#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "RDB file from DSSP (produced by dsspExtrSeqSecAcc.pl need raw labelled 'id' as first)";
$scrGoal="compiles statistics about ASA and RelAcc\n".
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

$narg=$#ARGV;
$nkwd=$#kwd;
$aawant="RKDEHQNSTILMFVWYPCAG";
$aawant="DENQ";
@aawant=split(//,$aawant);

$relmax=100;
$relmin=0;
$accmax=300;
$accmin=0;


				# ------------------------------
if ($narg<1 ||			# help
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
    if (($narg==1 && $ARGV[1]=~/^special/) ||
	($narg >1 && $ARGV[1] =~/^(-h|help)/ && $ARGV[2]=~/^spe/)){
    }

    if (defined %par && $nkwd > 0){
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
	if (defined %par && $nkwd>0) { 
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
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    if ($dirOut){
	$fileOut=$dirOut."Out-".$tmp;}
    else {
	$fileOut="Out-".$tmp;}}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
$nfile=$#fileIn;
@aafound=0;
undef %aafound;

foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    $ctline=0;
    while (<$fhin>) {
	$_=~s/\n//g;
	$line=$_;
	++$ctline;
#	$_=~s/^.*\///g;		# purge directories

	next if ($_=~/^\#/);	# skip comments
	if ($_=~/^id/){
	    @tmp=split(/\s*\t\s*/,$_);
	    $ntmp=$#tmp;
	    $ptr_seq=$ptr_acc=$ptr_sec=0;
	    $ctok=0;
	    foreach $it (1..$ntmp){
		if    ($tmp[$it]=~/seq/){ ++$ctok; $ptr_seq=$it;}
		elsif ($tmp[$it]=~/sec/){ ++$ctok; $ptr_sec=$it;}
		elsif ($tmp[$it]=~/acc/){ ++$ctok; $ptr_acc=$it;}
		last if ($ctok==3);
	    }
	    if ($ctok<3){
		print "*** something missing in line($ctline)=$_!\n";
		print "*** we have ptrseq=$ptr_seq, ptrsec=$ptr_sec, ptracc=$ptr_acc\n";
		exit;}
	    next;}
	@tmp=split(/\s*\t\s*/,$_);
	$ntmp=$#tmp;
	next if ($ntmp<3);
	
	@seq=split(//,$tmp[$ptr_seq]);
	@sec=split(//,$tmp[$ptr_sec]);
	@acc=split(/,/,$tmp[$ptr_acc]);
	$#accrel=0;
	$nres=$#seq;
				# convert to relative acc
	foreach $it (1..$nres){
	    $rel=&convert_acc($seq[$it],$acc[$it]);
	    			# saturation
	    if    ($rel<0)   {$rel=  0;}
	    elsif ($rel>100) {$rel=100;}
	    else             {$rel=int($rel);}
	    push(@accrel,$rel);
	}
				# store statistics
	foreach $it (1..$nres){
	    if (!  defined $aafound{$seq[$it]}){
		push(@aafound,$seq[$it]);
		$aafound{$seq[$it]}=0;
				# set rel to zero
		foreach $itrel ($relmin..$relmax){
		    $res{$seq[$it],"rel",$itrel}=0;
		}
				# set acc to zero
		foreach $itacc ($accmin..$accmax){
		    $res{$seq[$it],"acc",$itacc}=0;
		}
	    }
	    ++$res{$seq[$it],"rel",$accrel[$it]};
	    ++$res{$seq[$it],"acc",$acc[$it]};
	}
				# now the rel->observed stat
	foreach $it (1..$nres){
	    $rel10=&convert_accRel10($accrel[$it]);
	    if (! defined $res{$seq[$it],"rel10",$rel10}){
		$res{$seq[$it],"rel10",$rel10,"num"}=0;
		$res{$seq[$it],"rel10",$rel10,"sum"}=0;
		$res{$seq[$it],"rel10",$rel10}=0;}
	    ++$res{$seq[$it],"rel10",$rel10,"num"};
	    $res{$seq[$it],"rel10",$rel10,"sum"}+=$acc[$it];
	}
	    
    }
    close($fhin);
}
				# ------------------------------
				# (2) 
				# ------------------------------

				# compile sums
foreach $aa (@aawant){
    $sumres=0;
    $accmaxtmp=$accmin;
    $accmintmp=$accmax;
    $relmaxtmp=$relmin;
    $relmintmp=$relmax;
    				# find sum of occurence for $aa and minmax for acc
    foreach $val ($accmin .. $accmax){
	next if (! $res{$aa,"acc",$val});
	next if ($res{$aa,"acc",$val}<1);
	$accmaxtmp=$val if ($val>$accmaxtmp);
	$accmintmp=$val if ($val<$accmintmp);
	$sumres+=$res{$aa,"acc",$val};
    }
    $res{$aa,"acc","max"}=$accmaxtmp;
    $res{$aa,"acc","min"}=$accmintmp;
    				# find minmax for rel
    foreach $val ($relmin .. $relmax){
	next if (! $res{$aa,"rel",$val});
	next if ($res{$aa,"rel",$val}<1);
	$relmaxtmp=$val if ($val>$relmaxtmp);
	$relmintmp=$val if ($val<$relmintmp);
    }
    $res{$aa,"sum"}=$sumres;
    $res{$aa,"rel","max"}=$relmaxtmp;
    $res{$aa,"rel","min"}=$relmintmp;
}


@itrvl_acc=(0,2,8,18,32,50,72,98,128,162,200,300,350); # last for simplicity
$nitrvl_acc=$#itrvl_acc-1;
@itrvl_rel=(0,1,4,9,16,25,36,49,64,81,100,110); #  last for simple
$nitrvl_rel=$#itrvl_rel-1;

				# compile bin counts
foreach $aa (@aawant){
    				# square angstroem
    foreach $it (1..$nitrvl_acc){
	$res{$aa,"acc","bin",$it}=0;
	$sumthis=0;
	foreach $acc ($res{$aa,"acc","min"}..$res{$aa,"acc","max"}){
	    next if (! defined $res{$aa,"acc",$acc} || ! $res{$aa,"acc",$acc});
	    next if ($acc <= $itrvl_acc[$it]);
	    last if ($acc > $itrvl_acc[$it+1]);
	    $sumthis+=$res{$aa,"acc",$acc};
	}
	$res{$aa,"acc","bin",$it}=$sumthis;
    }
    				# relative
    foreach $it (1..$nitrvl_rel){
	$res{$aa,"rel","bin",$it}=0;
	$sumthis=0;
	foreach $rel ($res{$aa,"rel","min"}..$res{$aa,"rel","max"}){
	    next if (! defined $res{$aa,"rel",$rel} || ! $res{$aa,"rel",$rel});
	    next if ($rel <= $itrvl_rel[$it]);
	    last if ($rel > $itrvl_rel[$it+1]);
	    $sumthis+=$res{$aa,"rel",$rel};
	}
	$res{$aa,"rel","bin",$it}=$sumthis;
    }
}

   				# ------------------------------
   				# now find in bins of relative: what is the average of observed square


   				# ------------------------------
    				# write stuff: raw counts
				# square angstroem
$wrt="square counts\n";
$wrt.="valacc";
foreach $itrvl (@itrvl_acc){
    next if ($itrvl==$itrvl_acc[$nitrvl_acc+1]);
    $wrt.=$sep.$itrvl;
}
$wrt.=$sep."min".$sep."max";
$wrt.="\n";

foreach $aa (@aawant){
    				# header
    $wrt.=$aa;
    foreach $it (1..$nitrvl_acc){
	last if ($it  > $nitrvl_acc);
	if ($itrvl_acc[$it]>$res{$aa,"acc","max"}){
	    $wrt.=$sep." ";}
	else {
	    $wrt.=$sep.$res{$aa,"acc","bin",$it};
	}
    }
    $wrt.=$sep.$res{$aa,"acc","min"};
    $wrt.=$sep.$res{$aa,"acc","max"};
    $wrt.="\n";
}

$wrt.="relative accessibility raw counts\n";
$wrt.="valrel";
foreach $itrvl (@itrvl_rel){
    next if ($itrvl==$itrvl_rel[$nitrvl_rel+1]);
    $wrt.=$sep.$itrvl;
}
$wrt.=$sep."min".$sep."max";
$wrt.="\n";

foreach $aa (@aawant){
    				# header
    $wrt.=$aa;
    foreach $it (1..$nitrvl_rel){
	last if ($it  > $nitrvl_rel);
	if ($itrvl_rel[$it]>$res{$aa,"rel","max"}){
	    $wrt.=$sep." ";}
	else {
	    $wrt.=$sep.$res{$aa,"rel","bin",$it};
	}
    }
    $wrt.=$sep.$res{$aa,"rel","min"};
    $wrt.=$sep.$res{$aa,"rel","max"};
    $wrt.="\n";
}



   				# ------------------------------
    				# write stuff: percentages
				# square angstroem
$wrt="square percentage\n";
$wrt.="valacc".$sep."Nocc";
foreach $itrvl (@itrvl_acc){
    next if ($itrvl==$itrvl_acc[$nitrvl_acc+1]);
    $wrt.=$sep.sprintf("%6d",$itrvl);
}
$wrt.="\n";

foreach $aa (@aawant){
    				# header
    $wrt.=$aa;
    $wrt.=$sep.$res{$aa,"sum"};
    foreach $it (1..$nitrvl_acc){
	last if ($it  > $nitrvl_acc);
	if ($itrvl_acc[$it]>$res{$aa,"acc","max"}){
	    $wrt.=$sep." ";}
	else {
	    $tmp=sprintf("%6.2f",100*($res{$aa,"acc","bin",$it}/$res{$aa,"sum"}));
	    $wrt.=$sep.$tmp;
	}
    }
    $wrt.="\n";
}

$wrt.="relative accessibility percentage\n";
$wrt.="valrel".$sep."Nocc";
foreach $itrvl (@itrvl_rel){
    next if ($itrvl==$itrvl_rel[$nitrvl_rel+1]);
    $wrt.=$sep.sprintf("%6d",$itrvl);
}
$wrt.="\n";

foreach $aa (@aawant){
    				# header
    $wrt.=$aa;
    $wrt.=$sep.$res{$aa,"sum"};
    foreach $it (1..$nitrvl_rel){
	last if ($it  > $nitrvl_rel);
	if ($itrvl_rel[$it]>$res{$aa,"rel","max"}){
	    $wrt.=$sep." ";}
	else {
	    $tmp=sprintf("%6.2f",100*($res{$aa,"rel","bin",$it}/$res{$aa,"sum"}));
	    $wrt.=$sep.$tmp;
	}
    }
    $wrt.="\n";
}


   				# ------------------------------
   				# ten state bins
$wrt.="10 state relative accessibility raw counts (occ)\n";
$wrt.="valrel";
foreach $it (0..9){
    $wrt.=$sep.sprintf("%6d",($it*$it));
}
$wrt.="\n";

foreach $aa (@aawant){
    				# header
    $wrt.=$aa;
    foreach $it (0..9){
	$val=$it*$it;
	if ($val>$res{$aa,"rel","max"}){
	    $wrt.=$sep.sprintf("%6s"," ");}
	else {
	    $wrt.=$sep.sprintf("%6d",$res{$aa,"rel10",$val,"num"});
	}
    }
    $wrt.="\n";
}

   				# ten state averages
$wrt.="10 state relative accessibility averages\n";
$wrt.="valrel";
foreach $it (0..9){
    $wrt.=$sep.($it*$it);
}
$wrt.="\n";
foreach $aa (@aawant){
    				# header
    $wrt.=$aa;
    foreach $it (0..9){
	$val=$it*$it;
	if ($val>$res{$aa,"rel","max"}){
	    $wrt.=$sep.sprintf("%6s"," ");}
	else {
	    if ($res{$aa,"rel10",$val,"num"}<1){
		$wrt.=$sep.sprintf("%6d",0);}
	    else {
		$tmp=sprintf("%6.1f",
			     ($res{$aa,"rel10",$val,"sum"}/$res{$aa,"rel10",$val,"num"}));
		$wrt.=$sep.$tmp;
	    }
	}
    }
    $wrt.="\n";
}

   				# ten state differences to simple way of using max*rel
$wrt.="10 state relative accessibility differences new-old\n";
$wrt.="valrel";
foreach $it (0..9){
    $wrt.=$sep.($it*$it);
}
$wrt.="\n";
foreach $aa (@aawant){
    				# header
    $wrt.=$aa;
    foreach $it (0..9){
	$val=$it*$it;
	if ($val>$res{$aa,"rel","max"}){
	    $wrt.=$sep.sprintf("%6s"," ");}
	else {
	    if ($res{$aa,"rel10",$val,"num"}<1){
		$wrt.=$sep.sprintf("%6d",0);}
	    else {
		$new=($res{$aa,"rel10",$val,"sum"}/$res{$aa,"rel10",$val,"num"});
		($Lok,$old)=&convert_accRel2acc($val,$aa);
		$tmp=sprintf("%6.1f",($new-$old));
		$wrt.=$sep.$tmp;
	    }
	}
    }
    $wrt.="\n";
}


print "$wrt";

				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout $wrt;
close($fhout);

   				# write perl code
$fileOutCode=$fileOut."_perlcode";
open($fhout,">".$fileOutCode) || warn "*** $scrName ERROR creating fileOutCode=$fileOutCode";
foreach  $aa (@aawant){
    $#wrt=0;
    foreach $it (0..9){
	$val=$it*$it;
	if (! defined $res{$aa,"rel10",$val,"num"} || $res{$aa,"rel10",$val,"num"}<1){
	    $ave="";}
	else {
	    $ave=sprintf("%6.0f",($res{$aa,"rel10",$val,"sum"}/$res{$aa,"rel10",$val,"num"}));
	}
	$ave=~s/\s//g;
	$wrttmp="\$ACC_REL10_TO_AVESQUARE\{"."\"$aa\",\"$val\"\}=".$ave."\;";
	push(@wrt,$wrttmp);
    }
    foreach $wrttmp (@wrt){
	print $fhout "\t",$wrttmp,"\n";
    }
    print $fhout "\n";
}

    				# B: D or N
$#wrt=0;
$aa="B";
foreach $it (0..9){
    $val=$it*$it;
    $tmpsum=$tmpnum=0;
    if (defined $res{"D","rel10",$val,"num"} && $res{"D","rel10",$val,"num"}>=1){
	$tmpnum+=$res{"D","rel10",$val,"num"};
	$tmpsum+=$res{"D","rel10",$val,"sum"};}
    if (defined $res{"N","rel10",$val,"num"} && $res{"N","rel10",$val,"num"}>=1){
	$tmpnum+=$res{"N","rel10",$val,"num"};
	$tmpsum+=$res{"N","rel10",$val,"sum"};}
    if ($tmpnum<1){
	$ave="";}
    else {
	$ave=sprintf("%6.0f",$tmpsum/$tmpnum);
    }
    $ave=~s/\s//g;
    $wrttmp="\$ACC_REL10_TO_AVESQUARE\{"."\"$aa\",\"$val\"\}=".$ave."\;";
    push(@wrt,$wrttmp);
}
   				# Z:  E  or  Q
$aa="Z";
foreach $it (0..9){
    $val=$it*$it;
    $tmpsum=$tmpnum=0;
    if (defined  $res{"E","rel10",$val,"num"} && $res{"E","rel10",$val,"num"}>=1){
	$tmpnum+=$res{"E","rel10",$val,"num"};
	$tmpsum+=$res{"E","rel10",$val,"sum"};}
    if (defined  $res{"Q","rel10",$val,"num"} && $res{"Q","rel10",$val,"num"}>=1){
	$tmpnum+=$res{"Q","rel10",$val,"num"};
	$tmpsum+=$res{"Q","rel10",$val,"sum"};}
    if ($tmpnum<1){
	$ave="";}
    else {
	$ave=sprintf("%6.0f",$tmpsum/$tmpnum);
    }
    $ave=~s/\s//g;
    $wrttmp="\$ACC_REL10_TO_AVESQUARE\{"."\"$aa\",\"$val\"\}=".$ave."\;";
    push(@wrt,$wrttmp);
}
foreach $wrttmp (@wrt){
    print $fhout "\t",$wrttmp,"\n";
}
print $fhout "\n";
close($fhout);

if ($Lverb){
    print "--- output in $fileOut\n" if (-e $fileOut);
    print "--- code   in $fileOutCode\n";
}
exit;


#===============================================================================
sub convert_acc {
    local ($aa,$acc,$char,$mode) = @_ ;
    local (@tmp1,@tmp2,@tmp,$it,$tmpacc,$valreturn);
#--------------------------------------------------------------------------------
#    convert_acc                converts accessibility (acc) to relative acc
#                               default output is just relative percentage (char = 'unk')
#         in:                   AA, (one letter symbol), acc (Angstroem),char (unk or:
#                    note:      output is relative percentage, default if char empty or='unk'
#                                    ============
#                               char='15:100_b:e' -> returns symbols 
#                                    ============
#                                    b for relacc <15, e for relacc>=15
#                                    ===============
#                               char='4:15:100_b:i:e' -> returns symbols 
#                                    ===============
#                                    b for relacc <4, i: 4<=relacc<15, e for relacc>=15
#         in:                   .... $mode:
#                               mode=''=default, '3ang', '5ang', '07ang' -> different water
#                                    radius, 'RS' then X=0
#         out:                  converted (with return)
#--------------------------------------------------------------------------------

    &exposure_normalise_prepare($mode) if (! %NORM_EXP || ! defined %NORM_EXP);
				# default (3 states)
    if ( ! defined $char || $char eq "unk") {
	$valreturn=  &exposure_normalise($acc,$aa);}
				# optional e.g. char='15:100_b:e'
    elsif ($char =~ /\d:\d/) {
	if (! %NORM_EXP ){print "*** ERROR in convert_acc: NORM_EXP empty \n*** please,",
			  print "    do initialise with exposure_normalise_prepare\n";
			  exit;}
	$tmpacc= &exposure_normalise($acc,$aa);

	@tmp=split(/_/,$char);@tmp1=split(/:/,$tmp[1]);@tmp2=split(/:/,$tmp[2]);
	if   ($tmpacc<$tmp1[1])      {
	    $valreturn=$tmp2[1];}
	elsif($tmpacc>=$tmp1[$#tmp1-1]){
	    $valreturn=$tmp2[$#tmp1];}
	else { 
	    for ($it=2;$it<$#tmp1;++$it) {
		if ( ($tmpacc>=$tmp1[$it-1]) && ($tmpacc<$tmp1[$it+1]) ) {
		    $valreturn=$tmp2[$it]; 
		    last; }}} }
    else {print "*** ERROR calling convert_acc (lib-br) \n";
	  print "***       acc=$acc, aa=$aa, char passed (eg. 15:100_b:4)=$char, not ok\n";
	  exit;}
    $valreturn=100 if ($valreturn>100);	# saturation (shouldnt happen, should it?)
    return $valreturn;
}				# end of convert_acc

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

    $valreturn=10;
    foreach $it (1..9){
	if ($relaccin<($it+1)*($it+1) &&
	    $relaccin>=$it*$it){
	    $valreturn=$it*$it;
	    last;}
    }
    return $valreturn;
}				# end of convert_accRel10

#===============================================================================
sub convert_accRel2acc {
    local ($accRel,$aaLoc) = @_ ;
    local ($sbrName);
#--------------------------------------------------------------------------------
#    convert_accRel2acc         converts relative accessibility (accRel) to full acc
#       in:                     AA, (one letter symbol), accRel (0-100), char (unk or:
#                    note:      output is accessibility in Angstroem if char empty or='unk'
#       out:                    converted (with return, max=248)
#       out:                    1|0,converted
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $sbrName="";
				# check arguments
    return(&errSbr("not def accRel!"))  if (! defined $accRel);
    $aaLoc="A"                          if (! defined $aaLoc);
                                # convert case
    $aaLoc=~tr/[a-z]/[A-Z]/             if ($aaLoc=~/[a-z]/);

    if (defined $NORM_EXP{$aaLoc}){
        $valreturn=($accRel/100)*$NORM_EXP{$aaLoc};}
    else {
        return(0,"*** ERROR $sbrName: accRel=$accRel, aa=$aaLoc, not converted\n");}
        
                                # saturation (shouldnt happen, should it?)
    $valreturn=$NORM_EXP{"max"} if ($valreturn>$NORM_EXP{"max"});
    
    return(1,$valreturn);
}				# end of convert_accRel2acc

#===============================================================================
sub convert_accRel2oneDigit {
    local ($accRelLoc) = @_;
    $[=1;
#----------------------------------------------------------------------
#   convert_accRel2oneDigit     project relative acc to numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       out:                    1|0,msg,$converted_acc
#       err:                    (1,'ok'), (0,'message')
#----------------------------------------------------------------------
				# check input
    return(0,"*** ERROR convert_accRel2oneDigit: relAcc=$accRelLoc???\n")
	if ( $accRelLoc < 0 );
				# SQRT
    $out= int ( sqrt ($accRelLoc) );
                                # saturation: limit to 9
    $out= 9  if ( $out >= 10 );
    return(1,"ok",$out);
}				# end of convert_accRel2oneDigit

#===============================================================================
sub convert_sec {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_sec                converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#                               char=HL    -> H=H,I,G  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure to convert
#         out:                  converted (with return)
#--------------------------------------------------------------------------------
				# default (3 states)
    if ( !defined $char || length($char)==0 || $char eq "HEL" || ! $char) {
	return "H" if ($sec=~/[HIG]/);
	return "E" if ($sec=~/[EB]/);
	return "L";}
				# optional
    elsif ($char eq "HL")    { return "H" if ($sec=~/[HIG]/);
			       return "L";}
    elsif ($char eq "HELT")  { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    elsif ($char eq "HELB")  { return "H" if ($sec=~/HIG/);
			       return "E" if ($sec=~/[E]/);
			       return "B" if ($sec=~/[B]/);
			       return "L";}
    elsif ($char eq "HELBT") { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "B" if ($sec=~/[E]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    else { print "*** ERROR calling convert_sec (lib-br), sec=$sec, or char=$char, not ok\n";
	   return(0);}
}				# end of convert_sec

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

#==========================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#    exposure_normalise_prepare normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
        $NORM_EXP{"max"}=248;

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} = 179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} =  99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} = 199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} = 189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} = 189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} = 259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} = 209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} = 200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 239;  $NORM_EXP{"Z"} =269;         # E or Q
        $NORM_EXP{"max"}=309;

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} = 209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} = 139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} = 199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} = 189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} = 189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} = 309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} = 239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} = 230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 259;  $NORM_EXP{"Z"} =329;         # E or Q
        $NORM_EXP{"max"}=399;

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} = 119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} =  99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} = 169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} = 159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} = 159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} = 169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} = 149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} = 230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 189;  $NORM_EXP{"Z"} =175;         # E or Q
        $NORM_EXP{"max"}=230;

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =194;         # E or Q
        $NORM_EXP{"max"}=248;

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
        $NORM_EXP{"max"}=248;
    }
}				# end of exposure_normalise_prepare 

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
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise          normalise DSSP accessibility with maximal values
#                               (taken from Schneider)
#----------------------------------------------------------------------
    if ( $aa_in !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ]/ ) {
	if ( $aa_in=~/[!.]/ ) { 
	    $aa_in = "X"; }
	else { 
	    print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	    exit; }}

    if ($NORM_EXP{$aa_in}>0) { 
	$exp_normalise= int(100 * ($exp_in / $NORM_EXP{$aa_in}));
	$exp_normalise= 100 if ($exp_normalise > 100);
    }
    else { 
	print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	$NORM_EXP{$aa_in},"\n***\n";
	$exp_normalise=$exp_in/1.8; # ugly ...
	if ($exp_normalise>100){$exp_normalise=100;}
    }
    return $exp_normalise;
}				# end of exposure_normalise

#===============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digit     project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
				# SQRT
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

