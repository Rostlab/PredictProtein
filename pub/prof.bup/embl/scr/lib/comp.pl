#!/usr/bin/perl
##! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Sep,    	1998	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with routines related to manipulating numbers.               #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   comp                        internal subroutines:
#                               ---------------------
# 
#   bynumber                    function sorting list by number
#   bynumber_high2low           function sorting list by number (start with high)
#   correlation                 between x and y
#   equal_tolerance             returns 0, if v1==v2 +- $tol
#   fRound                      returns the rounded integer of real input (7.6->8; 7.4->7)
#   func_absolute               compiles the absolute value
#   func_faculty                compiles the faculty
#   func_n_over_k               compiles N over K
#   func_n_over_k_sum           compiles sum/i {N over i}
#   func_permut_mod             computes all possible permutations for $num, e.g. n=4:
#   func_permut_mod_iterate     repeats permutations (called by func_permut_mod)
#   func_sigmoid                compiles the neural network sigmoid function
#   func_sigmoidGen             compiles the neural network sigmoid function:
#   funcInfoConditional         Fano information
#   funcLog                     converts the perl log (base e) to any log
#   funcNormMinMax              normalises numbers with (min1,max1) to a range of (min0,max0)
#   get_max                     returns the maximum of all elements of @in
#   get_min                     returns the minimum of all elements of @in
#   get_sum                     computes the sum over input data
#   get_zscore                  returns the zscore = (score-ave)/sigma
#   is_odd_number               checks whether number is odd
#   numerically                 function sorting list by number
#   stat_avevar                 computes average and variance
#   stat2DarrayWrt              writes counts
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   comp                        external subroutines:
#                               ---------------------
# 
#   call from comp:             funcInfoConditional,func_absolute,func_faculty,func_n_over_k
#                               func_permut_mod_iterate,stat_avevar
# 
#   call from scr:              errSbr,errSbrMsg
# 
# 
# 
#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

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
	if ($it<=$ncol) { push(@v1,$data[$it]); }
	else            { push(@v2,$data[$it]); }
    }
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
sub equal_tolerance { 
    local($v1,$v2,$tol)=@_; 
#-------------------------------------------------------------------------------
#   equal_tolerance             returns 0, if v1==v2 +- $tol
#-------------------------------------------------------------------------------
    return(0) if ( $v1 < ($v2-$tol) || $v1 > ($v2+$tol) );
    return(1);
}				# end of equal_tolerance

#===============================================================================
sub fRound {local ($num)=@_;local($signLoc,$tmp);
#----------------------------------------------------------------------
#   fRound                      returns the rounded integer of real input (7.6->8; 7.4->7)
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
	    if ($num<0){$signLoc=-1;}else{$signLoc=1;}
	    $num=&func_absolute($num);
	    if ($num-int($num)>=0.5){
		$tmp=int($num)+1;}
	    else {
		$tmp=int($num)+1;}
	    if ($tmp==0){
		return(0);}
	    else {
		return($signLoc*$tmp);}
}				# end of fRound

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
sub func_faculty {
    local ($num)=@_;
    local ($tmp,$it,$prd);
    $[ =1;
#----------------------------------------------------------------------
#   func_faculty                compiles the faculty
#       in:                     $num
#       out:                    returned $fac
#----------------------------------------------------------------------
    $prd=1;
    foreach $it (1..$num){
	$prd=$prd*$it; }
    return ($prd);
}				# end of func_faculty

#===============================================================================
sub func_n_over_k {
    local ($n,$k)=@_;
    local ($res,$t1,$t2,$t3);
#----------------------------------------------------------------------
#   func_n_over_k               compiles N over K
#       in:                     $n,$k
#       out:                    returned $res
#----------------------------------------------------------------------
    $res=1;
    if ($k==0){
	return(1);}
    elsif ($k==$n){
	return(1);}
    else {
	$t1=&func_faculty($n);
	$t2=&func_faculty($k);
	$t3=&func_faculty(($n-$k));
	$res=$t1/($t2*$t3); 
	return($res);}
}				# end of func_n_over_k

#===============================================================================
sub func_n_over_k_sum {
    local ($n)=@_;
    local ($sum,$it,$tmp);
#----------------------------------------------------------------------
#   func_n_over_k_sum           compiles sum/i {N over i}
#       in:                     $n,$k
#       out:                    returned $res
#----------------------------------------------------------------------
    $sum=0;
    foreach $it (1..$n){
	$tmp=&func_n_over_k($n,$it);
	$sum+=$tmp;
    }
    return($sum);
}				# end of func_n_over_k_sum

#===============================================================================
sub func_permut_mod {
    local ($num)=@_;
    local (@mod_out,@mod_in,@mod,$it,$tmp,$it2,@tmp); 
    $[=1;
#----------------------------------------------------------------------
#   func_permut_mod             computes all possible permutations for $num, e.g. n=4:
#                               output is : '1,2' '1,3' '1,4' '2,3' asf.
#       in:                     $num
#       out:                    @permutations (as text:'n,m,..')
#----------------------------------------------------------------------
    $#mod=$#mod_out=0;
    foreach $it (1..$num){
	if ($it==1) { 
	    foreach $it2 (1 .. $num) {
		$tmp="$it2"; 
		push(@mod,$tmp);} }
	else {
	    @mod_in=@mod;
	    @mod=&func_permut_mod_iterate($num,@mod_in); }
	push(@mod_out,@mod); }
    return(@mod_out);
}				# end of func_permut_mod

#===============================================================================
sub func_permut_mod_iterate {
    local ($num,@mod_in)=@_;
    local (@mod_out,$it,$tmp,@tmp); 
    $[=1;
#----------------------------------------------------------------------
#   func_permut_mod_iterate     repeats permutations (called by func_permut_mod)
#                               computes all possible permutations for $num 
#                               (e.g. =4) as maximum, and
#       input is :              '1,2' '1,3' '1,4' '2,3' asf.
#----------------------------------------------------------------------
    $#mod_out=0;
    foreach $it (1..$#mod_in){
	@tmp=split(/,/,$mod_in[$it]);
	foreach $it2 (($tmp[$#tmp]+1) .. $num) {
	    $tmp="$mod_in[$it]".","."$it2";
	    push(@mod_out,$tmp);}}
    return(@mod_out);
}				# end of func_permut_mod_iterate

#===============================================================================
sub func_sigmoid {
    local($x) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   func_sigmoid                compiles the neural network sigmoid function
#-------------------------------------------------------------------------------
    $y=1/( 1 + exp ((-1)*$x));
    return($y);
}				# end of func_sigmoid

#===============================================================================
sub func_sigmoidGen {
    local($x,$temperatureLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   func_sigmoidGen             compiles the neural network sigmoid function:
#                               WITH temperature
#-------------------------------------------------------------------------------
    $y=1/( 1 + exp ((-1)*$temperatureLoc*$x));
    return($y);
}				# end of func_sigmoid

#===============================================================================
sub funcInfoConditional {
    local($Lfano,$Lrobson,$Lbayes,%tmpLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcInfoConditional         Fano information
#                               R. Fano, Transmission of information, Wiley, New York, 1961
#                               
#                               S= state
#                               R= residue (feature)
#                               f= counts
#                               N= total number of residues, counts
#                               
#                               I (S;R) = log [ ( f(S,R) / f(R) ) / (f(S) / N) ]
#                               
#                               information difference:
#                               B. Robson, Biochem J., 141, 853 (1974)
#                               
#                               I (DelS;R)=I(S;R)-I(!S;R)=
#                                          log [ f(S,R)/f(!S,R) ] + log [ f(!S)/f(S) ]
#                               
#				Bayes
#				                P(S) * P(R|S)
#				P(S|R) =  -------------------------
#				          SUM/j { P(Sj) * P(R|Sj) }
#				           
#				P(S|R) = probability for state S, given res R
#                               
#       in:                     $Lfano=  1|0:    compile fano info
#       in:                     $Lrobson=1|0:    compile robsons info diff
#       in:                     $Lbayes= 1|0:    compile bayes prob
#       in:                     $tmp{}:
#                               $tmp{"S"}=       "s1,s2,.."
#                               $tmp{"R"}=       "r1,r2,.."
#                               $tmp{"$R","$S"}= count of the number of residues $res in state $S
#       out:                    1|0,msg,  $res{}
#                               $res{"Rsum","$r"}=              sum for res $r
#                               $res{"Ssum","$s"}=              sum for state $s
#                               $res{"sum"}=                    total sum
#                               $res{"fano","$r","$s"}=         Fano information
#                               $res{"robson","$r","$s"}=       Robson information difference
#                               $res{"bayes","$r","$s"}=        Bayes prob (S|R, i.e. given R->S)
#                               $res{"bayes","Rsum","$r"}=      Bayes sum over all states for res $r
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."funcInfoConditional";$fhinLoc="FHIN_"."funcInfoConditional";
				# ------------------------------
				# get states/features
    return(&errSbr("tmp{R} not defined")) if (! defined $tmpLoc{"R"});
    return(&errSbr("tmp{S} not defined")) if (! defined $tmpLoc{"S"});
    $tmpLoc{"R"}=~s/^,*|,*$//g;
    $tmpLoc{"S"}=~s/^,*|,*$//g;
    @resLoc=split(/,/,$tmpLoc{"R"});
    @secLoc=split(/,/,$tmpLoc{"S"});
    undef %tmp2;
				# ------------------------------
    $sum=0;			# compile sums
    foreach $r (@resLoc) {	# features
	$tmp2{"Rsum","$r"}=0; 
	foreach $s (@secLoc) { 
	    $tmp2{"Rsum","$r"}+=$tmpLoc{"$r","$s"}; }
	$sum+=$tmp2{"Rsum","$r"};}
    foreach $s (@secLoc) {	# states
	$tmp2{"Ssum","$s"}=0; 
	foreach $r (@resLoc) { 
	    $tmp2{"Ssum","$s"}+=$tmpLoc{"$r","$s"}; }}
    $tmp2{"sum"}=$sum;
	
				# --------------------------------------------------
				# info (fano)
				# --------------------------------------------------
    if ($Lfano){
	foreach $r (@resLoc) {
	    $nr=$tmp2{"Rsum","$r"};
	    foreach $s (@secLoc) { 
		$up=0;
		$up=$tmpLoc{"$r","$s"}/$nr                  if ($nr>0);
		$lo=$tmp2{"Ssum","$s"}/$sum;
		$info=0;
		if ($lo>0){$info=$up/$lo;
			   $info=log($info)                 if ($info!=0); } 

		$tmp2{"fano","$r","$s"}=$info;
	    } }
    }

				# --------------------------------------------------
				# info DIFF (robson)
				# I (DelS;R)=I(S;R)-I(!S;R)=
				#        log [ f(S,R)/f(!S,R) ] + log [ f(!S)/f(S) ]
				# --------------------------------------------------
    if ($Lrobson){
	foreach $r (@resLoc) {
	    foreach $s (@secLoc) { 
		$neg=0;
		foreach $s2 (@secLoc) { next if ($s2 eq $s);
					$neg+=$tmpLoc{"$r","$s2"}; }
		$one=0;
		$one=$tmpLoc{"$r","$s"}/$neg                if ($neg>0);
		$one=log($one)                              if ($one>0);
		
		$two=0;
		$two=($sum-$tmp2{"Ssum","$s"})
		    /$tmp2{"Ssum","$s"}                     if ($tmp2{"Ssum","$s"}>0);
		$two=log($two)                              if ($two>0);
	    
		$tmp2{"robson","$r","$s"}=$one+$two; 
	    }} 
    }
				# --------------------------------------------------
				# Bayes
				#                    P(S) * P(R|S)
				# P(S|R) =  -------------------------
				#           SUM/j { P(Sj) * P(R|Sj) }
				#           
				# P(S|R) = probability for state S, given res R
				# --------------------------------------------------
    if ($Lbayes){
				# (1) get P(S) = SUM/j { P(Rj) * P(S|Rj) }
	foreach $s (@secLoc) { 
	    $tmp2{"bayes","pS","$s"}=0;
	    $tmp2{"bayes","pS","$s"}=($tmp2{"Ssum","$s"}/$sum)   if ($sum > 0);
	}
				# (2) get P(R|S)
	foreach $r (@resLoc) {
	    foreach $s (@secLoc) { 
		$tmp2{"bayes","RS","$r","$s"}=0;
		$tmp2{"bayes","RS","$r","$s"}=
		    ($tmpLoc{"$r","$s"}/$tmp2{"Ssum","$s"}) if ($tmp2{"Ssum","$s"} > 0); 
	    } }

				# (3) get P(S|R) = Bayes
	foreach $s (@secLoc) { 
	    foreach $r (@resLoc) {
		$tmp=0;
		foreach $s2 (@secLoc) { 
		    $tmp+= ( $tmp2{"bayes","pS","$s2"} * $tmp2{"bayes","RS","$r","$s2"} ); }
		$tmp2{"bayes","$r","$s"}=0;
		$tmp2{"bayes","$r","$s"}=
		    ($tmp2{"bayes","pS","$s"}*$tmp2{"bayes","RS","$r","$s"}) / $tmp 
			if ($tmp > 0);
	    } }
	foreach $r (@resLoc) {	# (4) get sum P(S|R) over S
	    $tmp=0;
	    foreach $s (@secLoc) { 
		$tmp+=$tmp2{"bayes","$r","$s"}; }
	    $tmp2{"bayes","Rsum","$r"}=$tmp; }
    }
				# ------------------------------
    undef %tmpLoc;		# slim-is-in!

    return(1,"ok $sbrName",%tmp2);
}				# end of funcInfoConditional

#===============================================================================
sub funcLog {
    local ($numLoc,$baseLoc)=@_;
    $[ =1;
#----------------------------------------------------------------------
#   funcLog                     converts the perl log (base e) to any log
#       in:                     $num,$base
#       out:                    log($num)/log($base)
#----------------------------------------------------------------------
    if (($numLoc==0) || (! defined $numLoc)) {
	return "*** funcLog: log (0) not defined\n";}
    if (($baseLoc<=0)|| (! defined $baseLoc)) {
	return "*** funcLog: base must be > 0 is '$baseLoc'\n";}
    return (log($numLoc)/log($baseLoc));
}				# end of funcLog

#===============================================================================
sub funcNormMinMax {
    local($numLoc,$minNow,$maxNow,$minWant,$maxWant) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcNormMinMax              normalises numbers with (min1,max1) to a range of (min0,max0)
#                               
#                               N(new) = N(now) * S + ( Min(want) - Min(now) * S )
#                               
#                               with S:
#                                         Max(want) - Min(want)
#                               S      =  ---------------------
#                                         Max(now)  - Min(now)
#                               
#       in:                     $numLoc,$minNow,$maxNow,$minWant,$maxWant
#       out:                    1|0,msg,$numNew
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."funcNormMinMax";$fhinLoc="FHIN_"."funcNormMinMax";
    return(0,"no minNow")                           if (! defined $minNow);
    return(0,"no maxNow")                           if (! defined $maxNow);
    return(0,"no minWant")                          if (! defined $minWant);
    return(0,"no maxWant")                          if (! defined $maxWant);
    $diffNow=$maxNow-$minNow;
    return(0,"maxNow-minNow ($maxNow,$minNow)=0 !") if ($diffNow==0);
    $scale= ( $maxWant-$minWant ) / $diffNow;
    $new=   $numLoc * $scale + ($minWant - $minNow * $scale);
    return(1,"ok $sbrName",$new);
}				# end of funcNormMinMax

#===============================================================================
sub get_max { $[=1;local($ct,$pos,$max);$max=-1000000;$ct=$pos=0; 
#----------------------------------------------------------------------
#   get_max                     returns the maximum of all elements of @in
#       in:                     @in
#       out:                    returned $max,$pos (position of maximum)
#----------------------------------------------------------------------
	      foreach $_(@_){if(defined $_){
		  ++$ct; 
		  if($_>$max){$max=$_;$pos=$ct;}}}
	      return ($max,$pos); } # end of get_max

#===============================================================================
sub get_min { $[=1;local($ct,$pos,$min);$min=100000; $ct=0; 
#----------------------------------------------------------------------
#   get_min                     returns the minimum of all elements of @in
#       in:                     @in
#       out:                    returned $min,$pos (position of minimum)
#----------------------------------------------------------------------
	      foreach $_(@_){++$ct; if($_<$min){$min=$_;$pos=$ct;}}
	      return ($min,$pos); } # end of get_min

#===============================================================================
sub get_sum { local(@data)=@_;local($it,$ave,$var,$sum);$[=1;
#----------------------------------------------------------------------
#   get_sum                     computes the sum over input data
#       in:                     @data
#       out:                    $sum,$ave,$var
#----------------------------------------------------------------------
	      $sum=0;foreach $_(@_){if(defined $_){$sum+=$_;}}
	      ($ave,$var)=&stat_avevar(@data);
	      return ($sum,$ave,$var); } # end of get_sum

#===============================================================================
sub get_zscore { local ($score,@data) = @_ ; local ($ave,$var,$sig,$zscore);
		 $[ =1 ;
#--------------------------------------------------------------------------------
#   get_zscore                  returns the zscore = (score-ave)/sigma
#       in:                     $score,@data
#       out:                    zscore
#--------------------------------------------------------------------------------
		 ($ave,$var)=&stat_avevar(@data);
		 $sig=sqrt($var);
		 if ($sig != 0){ $zscore=($score-$ave)/$sig; }
		 else          { print"xx get_zscore: sig=$sig,=0?\n";$zscore=0; }
		 return ($zscore);
}				# end of get_zscore

#===============================================================================
sub is_odd_number {
    local($num)=@_ ;
#--------------------------------------------------------------------------------
#   is_odd_number               checks whether number is odd
#       in:                     number
#       out:                    returns 1 if is odd, 0 else
#--------------------------------------------------------------------------------
    return 0 if (int($num/2) == ($num/2));
    return 1;
}				# end of is_odd_number

#===============================================================================
sub numerically { 
#-------------------------------------------------------------------------------
#   numerically                 function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of numerically

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

#===============================================================================
sub stat2DarrayWrt {
    local($sepL,$Lnum,$Lperc,$Lcperc,$Lfano,$Lrobson,$Lbayes,%tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   stat2DarrayWrt               writes counts
#       in:                     $sep        :    symbol for separating columns
#       in:                     $Lnum=   1|0:    write simple counts
#       in:                     $Lperc=  1|0:    write percentages (of total sum)
#       in:                     $Lcperc= 1|0:    write row percentages (of sum over rows)
#       in:                     $Lfano=  1|0:    write fano info
#       in:                     $Lrobson=1|0:    write robsons info diff
#       in:                     $Lbayes= 1|0:    write bayes prob
#       in:                     $tmp{}:
#                               $tmp{"S"}=       "s1,s2,.."
#                               $tmp{"R"}=       "r1,r2,.."
#                               $tmp{"$R","$S"}= number of residues $res in state $S
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."stat2DarrayWrt";$fhinLoc="FHIN_"."stat2DarrayWrt";

				# ------------------------------
				# get states/features
    return(&errSbr("tmp{R} not defined")) if (! defined $tmp{"R"});
    return(&errSbr("tmp{S} not defined")) if (! defined $tmp{"S"});
    $tmp{"R"}=~s/^,*|,*$//g;
    $tmp{"S"}=~s/^,*|,*$//g;
    @rloc=split(/,/,$tmp{"R"});
    @sloc=split(/,/,$tmp{"S"});
    undef %tmp2;
				# ------------------------------
				# get info
    ($Lok,$msg,%tmp2)=
	&funcInfoConditional($Lfano,$Lrobson,$Lbayes,%tmp);
    return(&errSbrMsg("stat2DarrayWrt: failed on info",$msg)) if (! $Lok);

				# --------------------------------------------------
				# build up to write
				# --------------------------------------------------
    $tmpWrt="";
				# ------------------------------
				# numbers
    $des="num";			# ------------------------------
    if ($Lnum){
	$f0="%-6s";
	$f2="%8d";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp{"$rloc","$sloc"}); }
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp2{"Rsum","$rloc"});
	    $tmpWrt.=           "\n"; }
				# sum
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"sum");
	foreach $sloc (@sloc) {
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp2{"Ssum","$sloc"}); }
	$tmpWrt.=               sprintf("$sepL$f2",   $tmp2{"sum"});
	$tmpWrt.=               "\n"; 
    }
				# ------------------------------
				# percentages (over total counts)
    $des="perc";		# ------------------------------
    if ($Lperc){
	$f0="%-6s";
	$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   100*($tmp{"$rloc","$sloc"}/$tmp2{"sum"}));}
	    $tmpWrt.=           sprintf("$sepL$f2",   100*($tmp2{"Rsum","$rloc"}/$tmp2{"sum"}));
	    $tmpWrt.=           "\n"; }
				# sum
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"sum");
	foreach $sloc (@sloc) {
	    $tmpWrt.=           sprintf("$sepL$f2" ,  100*($tmp2{"Ssum","$sloc"}/$tmp2{"sum"}));}
	$tmpWrt.=               sprintf("$sepL$f2",   100);
	$tmpWrt.=               "\n";
    }
				# ------------------------------
				# c-percentages (row counts)
    $des="cperc";		# ------------------------------
    if ($Lcperc){
	$f0="%-6s";
	$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    $tmp=0;
	    foreach $sloc (@sloc) {
		$cperc=0;$cperc=100*($tmp{"$rloc","$sloc"}/$tmp2{"Rsum","$rloc"})
		    if ($tmp2{"Rsum","$rloc"}>0);
		$tmp+=$cperc;
		$tmpWrt.=       sprintf("$sepL$f2",   $cperc); }
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp);
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Fano information
    $des="fano";		# ------------------------------
    if ($Lfano){
	$f0="%-6s";
	$f2="%6.2f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp2{"fano","$rloc","$sloc"}); }
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Robson information
    $des="robson";		# ------------------------------
    if ($Lrobson){
	$f0="%-6s";
	$f2="%6.2f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp2{"robson","$rloc","$sloc"}); }
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Bayes prob
    $des="bayes";		# ------------------------------
    if ($Lbayes){
	$f0="%-6s";$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   100*$tmp2{"bayes","$rloc","$sloc"}); }
	    $tmpWrt.=           sprintf("$sepL$f2",   100*$tmp2{"bayes","Rsum","$rloc"});
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
    undef %tmp; undef %tmp2;	# slim-is-in!
    return(1,"ok $sbrName",$tmpWrt);
}				# end of stat2DarrayWrt

1;
