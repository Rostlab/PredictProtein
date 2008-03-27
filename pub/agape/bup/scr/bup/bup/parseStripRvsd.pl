#! /usr/bin/perl -w

($StripListFile,$distbnFile,$idFile)=@ARGV;

die "arguments not defined StripListFile=$StripListFile distbnFile=$distbnFile idFile=$idFile, stopped"
    if(! defined $StripListFile || ! defined $distbnFile ||
       ! defined $idFile);

$g_maxRankEval="all";


if($StripListFile =~/\.list/){
    open(FHIN,$StripListFile) || 
	die "StripListFile=$StripListFile not found, stopped";
    while(<FHIN>){
	next if(/^\#|^\s*$/);
	s/\s//g;
	push @StripList, $_;
    }
    close FHIN;
}else{ push @StripList, $StripListFile; }

undef %h_ids;
open(FHIN,$idFile) || die "failed to open idFile=$idFile, stopped";
while(<FHIN>){
    next if(/^\#|^\s*$/);
    s/\s//g;
    s/.*\///; s/\..*$//;
    $h_ids{$_}=1;
}
close FHIN;

#--------------------------------------------------------
undef %h_id2distbn;
open(FHIN,$distbnFile) ||
    die "failed to open distbnFile=$distbnFile, stopped";
while(<FHIN>){
    next if(/^\#|^\s*$/);
    s/\s*$//;
    ($id,$coef,$disp,$miu,$lambda,$miu_evd,$lambda_evd,$miu_evd_censd,$lambda_evd_censd)
	=split(/\t/,$_);
    die "id or group not found in line:\n$_\n, stopped"
	if(! defined $id || ! defined $miu || ! defined $lambda || ! defined $miu_evd || ! defined $lambda_evd || ! defined $miu_evd_censd || ! defined $lambda_evd_censd);
     
    $h_id2distbn{$id}{"miu"}              =$miu;
    $h_id2distbn{$id}{"lambda"}           =$lambda;
    $h_id2distbn{$id}{"miu_evd"}          =$miu_evd;
    $h_id2distbn{$id}{"lambda_evd"}       =$lambda_evd;
    $h_id2distbn{$id}{"miu_evd_censd"}    =$miu_evd_censd;
    $h_id2distbn{$id}{"lambda_evd_censd"} =$lambda_evd_censd;

    $h_id2distbn{$id}{"coef"}   =$coef;
    $h_id2distbn{$id}{"disp"}   =$disp;
    
    @tmp=("miu","lambda","miu_evd","lambda_evd","miu_evd_censd","lambda_evd_censd");
    foreach $it (@tmp){
	if($h_id2distbn{$id}{$it} !~ /\d/){
	    die "for $id: $it is $h_id2distbn{$id}{$it}, stopped";
	}
    }
}
close FHIN;  #-------------------------------------------
undef $miu; undef $lambda;

foreach $StripFile (@StripList){
    print "\n------------------\n";

    ($Lok,$msg)=&parse_strip($StripFile,{%h_ids});
    die "$msg, stopped" if(! $Lok);
}

#==============================================================================
sub parse_strip{
    my $sbr='parse_strip';
    my ($StripFile,$hr_ids)=@_;
    my ($FileOut,$HomID,$Iden,$Query,$Rank,$Read,$Score,$Zscore);
    my ($QueryLen,$HomLen,$hclass,$qclass,$class_mean,$class_stddev,
	$class_stderr,$class_size,$class_lambda,$class_miu,
	$Eval,$Pval,$EvalLoc,$z,$size,$sizeDB,$scoreTmp,$coef,$disp);
    my ($mean,$stddev,$stderr,$score,$scoreCt);
    my (@l_ids_related_to_first);

    my ($class_miu_evd,$class_lambda_evd,$miu_evd,$lambda_evd,$Eval_evd,
	$Pval_evd,$Eval_evd_loc,$Eval_mix,$firstHomID,$meanAll,$stddevAll,$stderrAll);
    my (@data,@fields,@l_scores,@l_fa_homol,@l_sf_homol,@l_cf_homol,
	@l_scoresTmp,@l_loglen_scores,@l_aligned_ids,
	@l_all_lengths);
    my (%h_field2column,%h_Results,%h_scores,%h_classDistbn,%h_sfs,
	%h_loglen_scores,%h_scores_related,%h_loglen_scores_related,
	%h_ids_related_to_first,%h_ids);   
    
    my $fh=$sbr.$$;
    %h_ids=%{ $hr_ids };
    print "\n-------------------- $StripFile -----------------------\n\n";
    
    @l_scores=();
    
    undef $firstHomID; $scoreCt=0;

    if($StripFile=~/\.gz$/){
	$cmd="gunzip -c $StripFile";
	open($fh,"$cmd |") ||
	    return(0,"ERROR failed to open $cmd, stopped");
    }else{
	open($fh,$StripFile) ||
	    return(0,"ERROR failed to open StripFile=$StripFile, stopped");
    }
    
    $Read=0;
    while(<$fh>){
	next if(/^\#|^\s*$/);
	s/^\s*|\s*$//g;
	if(/test\s*sequence\s*:\s*(\S+)/){
	    $Query=$1; $Query=~s/.*\///; $Query=~s/\..*$//;
	}
	if(/seq_length\s*:\s*(\d+)/){$QueryLen=$1; }
	last if(/==\s*ALIGNMENTS/);
	if(/==\s*SUMMARY/){ $Read=1; next;}
	next if(! $Read);
	if(/IAL\s*VAL\s*LEN/){ 
	    @fields=split(/\s+/,$_);
	    #print "Fields:\t",@fields,"\n";
	    for $i (0 .. $#fields){
		#print "field=".$fields[$i]."\tcolumn=".$i."\n";
		$h_field2column{ $fields[$i] }= $i;
	    }
	    next;
	}
	@data=split(/\s+/,$_);
	$HomID    =$data[ $h_field2column{'NAME'} ]; #$HomID=~s/_//;

	if(! defined $h_ids{$HomID} ){ 
	    print "HomID=$HomID not among db ids considered\n";
	    next;
	}
	if(defined $h_Results{ $HomID } )  { next; }  #take best alignment

	
	$Zscore   =$data[ $h_field2column{'ZSCORE'} ];
	$Score    =$data[ $h_field2column{'VAL'} ];
	$Iden     =$data[ $h_field2column{'%IDEN'} ];
	$HomLen   =$data[ $h_field2column{'LEN2'} ];
	
	next if($Query eq $HomID);
	
	$coef=$h_id2distbn{$HomID}{"coef"};
	$disp=$h_id2distbn{$HomID}{"disp"};
	die "length dependence coefficients not defined for HomID=$HomID, stopped"
	    if(! defined $coef || ! defined $disp);
	#$tmpLogLen= log($QueryLen);
	#print "Score before: $Score coef=$coef disp=$disp QueryLen=$QueryLen loglen=$tmpLogLen \n";
	$Score=$Score - log($QueryLen) * $coef - $disp;
	#print "Score after: $Score\n";

	$scoreCt++;
	$h_Results{$HomID}{'VAL'}     =$Score;
	$h_Results{$HomID}{'%IDEN'}   =$Iden;
	$h_Results{$HomID}{'qlen'}    =$QueryLen;
	$h_Results{$HomID}{'hlen'}    =$HomLen;
	
	push @l_aligned_ids, $HomID;
    }
    close $fh;
        
    @l_tmp=keys %h_Results;
    $sizeDB=$size=$#l_tmp +1;
    print "size: $size\n";
    foreach $HomID (keys %h_Results){
	$score =$h_Results{$HomID}{'VAL'};
	$Eval=$Eval_evd=$Eval_evd_censd=0;
	$miu                 =$h_id2distbn{$HomID}{"miu"};
	$lambda              =$h_id2distbn{$HomID}{"lambda"};
	$miu_evd             =$h_id2distbn{$HomID}{"miu_evd"};
	$lambda_evd          =$h_id2distbn{$HomID}{"lambda_evd"};
	$miu_evd_censd       =$h_id2distbn{$HomID}{"miu_evd_censd"};
	$lambda_evd_censd    =$h_id2distbn{$HomID}{"lambda_evd_censd"};
	die "not defined for $HomID: miu=$miu lambda=$lambda miu_evd=$miu_evd lambda_evd=$lambda_evd miu_evd_censd=$miu_evd_censd lambda_evd_censd=$lambda_evd_censd, stopped"
	    if(! defined $miu || ! defined $lambda || ! defined $miu_evd || ! defined $lambda_evd || ! defined $miu_evd_censd || ! defined $lambda_evd_censd );
#	print "$HomID: miu=$miu lambda=$lambda miu_evd=$miu_evd lambda_evd=$lambda_evd miu_evd_censd=$miu_evd_censd lambda_evd_censd=$lambda_evd_censd\n";
	
	$Pval          =1-exp( -exp( -$lambda * ($score -$miu) ) );
	$EvalLoc       =$size * $Pval;
	$Eval         +=$EvalLoc;
	
	$Pval_evd      =1-exp( -exp( -$lambda_evd * ($score -$miu_evd) ) );
	$Eval_evd_loc  =$Pval_evd * $size;
	$Eval_evd     +=$Eval_evd_loc;
	
	$Pval_evd_censd      =1-exp( -exp( -$lambda_evd_censd * ($score -$miu_evd_censd) ) );
	$Eval_evd_censd_loc  =$Pval_evd_censd * $size;
	$Eval_evd_censd     +=$Eval_evd_censd_loc;
	
	
	$h_Results{$HomID}{'Eval'}                =$Eval;
	$h_Results{$HomID}{'Eval_evd'}            =$Eval_evd;
	$h_Results{$HomID}{'Eval_evd_censd'}      =$Eval_evd_censd;

	$h_Results{$HomID}{'Pval'}                =$Pval;
	$h_Results{$HomID}{'Pval_evd'}            =$Pval_evd;
	$h_Results{$HomID}{'Pval_evd_censd'}      =$Pval_evd_censd;
	
	$h_Results{$HomID}{'miu'}                 =$miu;
	$h_Results{$HomID}{'lambda'}              =$lambda;
    }
    
    $FileOut=$StripFile; $FileOut=~s/.*\/|\..*$//g;
    $FileOutReg=$FileOut.".rvsd-parsed";
    $FileOutEvd=$FileOut.".rvsd-parsed_evd";
    $FileOutEvdCensd=$FileOut.".rvsd-parsed_evd_c";

    @l_files=(["FHOUTREG",$FileOutReg,"Pval"],
	      ["FHOUTEVD",$FileOutEvd,"Pval_evd"],
	      ["FHOUTEVDCENSD",$FileOutEvdCensd,"Pval_evd_censd"]);
    
    foreach $rl (@l_files){
	($fh,$FileOut,$key)=@{ $rl };
	
	open($fh,">".$FileOut) ||
	    die "failed to open FileOut=$FileOut, stopped";
        
	print $fh "queryID\trank\thomID\tP-val\tE-val\tScore\tsizeDB\tmiu\tlambda\n";
	$Rank=0;
	foreach $HomID (sort { $h_Results{$a}{$key} <=> $h_Results{$b}{$key} } keys %h_Results ){
	    $Rank++; $Pval=$h_Results{$HomID}{$key};
	    $keyEval=$key; $keyEval=~s/Pval/Eval/;
	    $Eval=$h_Results{$HomID}{$keyEval};
	    $miuLoc     =$h_Results{$HomID}{'miu'};
	    $lambdaLoc  =$h_Results{$HomID}{'lambda'};
	    if($g_maxRankEval !~ /all/i){
		last if($Rank > $g_maxRankEval);
	    }
	    #if($Eval eq 0){ $scoreTmp=1000000; }
	    #else{ $scoreTmp=-log($Eval); }
	    $Score =$h_Results{$HomID}{'VAL'};
	    
	    print $fh $Query."\t".$Rank."\t".$HomID."\t".$Pval."\t".$Eval."\t".$Score."\t".$sizeDB."\t".$miuLoc."\t".$lambdaLoc."\n";
	
	}
	close $fh;
    }
    return(1,"$sbr: OK");
}
#===============================================================================
#=======================================================================================
sub get_statistics{
    my $sbr='get_statistics';
    my @DataVector=@_;
    my ($mean,$variance,$stderr,$stddev);
    my ($size,$sum);
    
    if($#DataVector == -1){
	print "WARNING: $sbr: argument DataVector contains no data\n";
	$mean=$stddev=$stderr=0;
    }else{
	$sum=$size=0;
	foreach $value (@DataVector){
	    if($value !~/[\d\-\+eE\.]/){
		return(0,"ERROR $sbr: found non numerical value=$value");
	    }
	    $sum+=$value; $size++;
	}
	$mean=$sum/$size;
	$variance=0;
	foreach $value (@DataVector){
	    $variance+=($mean-$value)**2;
	}
	if($size>1){
	    $stddev= sqrt( $variance/($size-1) );
	    $stderr= $stddev / sqrt( $size );
	}
	else{ $stddev=$stderr=0; }
    }
    return($mean,$stddev,$stderr);
    
}
#================================================================================
#================================================================================
sub get_evd{
    my $sbr="get_evd";
    my @l_scores=@_;
    my ($n,$mean,$stddev,$stderr,$lambda,$lambdaIni,
	$sum,$sum1,$sum2,$sum3,$miu,$F,$f,$Precision,
	$EvalLast);
    $Precision=0.0000001;
    @l_scores=sort {$a <=> $b} @l_scores;

    $n=$#l_scores + 1;
    ($mean,$stddev,$stderr)=&get_statistics(@l_scores);
    
    # lambda=pi/(sqrt6 * stddev)      
    # P(x)=lambda * exp[ -lambda*(x - miu) - exp( -lambda*(x - miu) ) ]
    #Maximum Likelihood Estimation from Sean Eddy
    
    $lambdaIni=$lambda=3.1415/( sqrt(6) * $stddev);
    	
    #print "$sbr:  START HERE\n";
    for $i (0 .. 1000){
	$sum=$sum1=$sum2=$sum3=0;
	foreach $score (@l_scores){ 
	    $sum    +=$score; 
	    $sum1   +=exp( -$lambda * $score);
	    $sum2   +=$score * exp( -$lambda * $score);
	    $sum3   +=$score * $score * exp( -$lambda * $score);
	}
	$F=1/$lambda - $sum/$n + $sum2/$sum1;
	$f=($sum2**2)/($sum1**2) - $sum3/$sum1 - 1/($lambda**2);
	if($F < $Precision && $F > $Precision){
	    #print "terminated in $i 'th step\n"; 
	    last;
	}
	$lambda =$lambda - $F/$f;
    }
    
    if($lambdaIni != $lambda){} #print "lambdas DIFFER\n"; }
    
    if($F > $Precision || $F < -$Precision){
	die "did not converge: F=$F (should be closer to zero), stopped";
    }
    $miu=(-1/$lambda) * log($sum1/$n);
    #$miu=(-1/$lambda) * log($sum1/$n);
    #$miu=$mean - 0.5772/$lambda;
    #print "final lambda: $lambda\n";
    #print "$sbr:   END HERE\n";
    return($miu,$lambda);
}
#================================================================================
#================================================================================
sub get_evd_censd{
    my $sbr="get_evd_censd";
    my @l_scores=@_;
    my ($Precision,$meanIni,$stddevIni,$lambdaIni,$miuIni,$lambdaCensd,$miuCensd);
    my ($c,$censdNo,$score,$uncsdNo,$tmp);
    my (@l_uncsd_scores,@l_tmp);
    my (%h_uncsd_scores);

    @l_scores=sort {$a <=> $b} @l_scores;
    #print "$sbr:   START\n";
    $Precision=0.0000001; #precision of MLE estimates
    
    ($meanIni,$stddevIni)=&get_statistics(@l_scores);
    $lambdaIni=3.1415/( sqrt(6) * $stddevIni);
    $miuIni=$meanIni - 0.5772/$lambdaIni;
   	
    undef %h_uncsd_scores;
    $censdNo=0; $uncsdNo=0; @l_uncsd_scores=();

    $tmp=int (0.3 * ($#l_scores) ); #find cutoff for censored scores
    $c=$l_scores[$tmp];
    print "$#l_scores +1   loc:$tmp   c:$c\n";
    #print "l_scores:@l_scores\n";

    foreach $score (@l_scores){ 
	if($score < $c){ $censdNo++; }
	else{ push @l_uncsd_scores, $score; $h_uncsd_scores{$score}++; $uncsdNo++;}
    }
    die "number of uncensored equals 0, stopped" if($uncsdNo ==0);
    
    @l_tmp=keys %h_uncsd_scores;
    if($#l_tmp < 1){
	die "number of uncsd scores is too small, stopped";
    }
    
    ($miuCensd,$lambdaCensd)=
	&calcLambdaEvdCensd($Precision,$lambdaIni,$c,$censdNo,@l_uncsd_scores);
    
    
    return($miuCensd,$lambdaCensd);
}
#================================================================================

#================================================================================
sub calcLambdaEvdCensd{
    my $sbr="calcLambdaEvdCensd";
    my ($Precision,$lambda,$c,$z,@l_uncsd_scores)=@_;
    my ($fact,$fact1,$fact2,$sum,$sum1,$sum2,$sum3);
    my ($n,$i,$score,$F,$f,$miu,$EvalLast);

    @l_uncsd_scores=sort {$a <=> $b} @l_uncsd_scores;

    if($#l_uncsd_scores < 0){ die "ERROR $sbr: no data to fit, stopped"; } 

    $n=$#l_uncsd_scores +1;
      
    for $i (0 .. 1000){
	$fact  =$z * exp(-$lambda * $c);
	$fact1 =$z * $c * exp(-$lambda * $c);
	$fact2 =$z * $c * $c * exp(-$lambda * $c);
	$sum=$sum1=$sum2=$sum3=0;
	foreach $score (@l_uncsd_scores){ 
	    $sum    +=$score; 
	    $sum1   +=exp( -$lambda * $score);
	    $sum2   +=$score * exp( -$lambda * $score);
	    $sum3   +=$score * $score * exp( -$lambda * $score);
	}
	
	$F=1/$lambda - $sum/$n + ($fact1 + $sum2)/($fact + $sum1);
	$f=( ( ( $fact1 + $sum2)/($fact + $sum1) ) **2 ) 
	    - ($fact2 + $sum3)/($fact + $sum1) - (1/$lambda)**2;
	
	if($F < $Precision && $F > -$Precision){ last; }
	$lambda =$lambda - $F/$f;
    }
    
    if($F > $Precision || $F < -$Precision){
	die "did not converge: F=$F (should be closer to zero)";
    }
    $miu=(-1/$lambda) * log( 1/($#l_uncsd_scores +1) * ( $fact + 1/$sum1) );
    
    return($miu,$lambda);
}
#====================================================================================
#====================================================================================
sub fit_line{
    my $sbr  ="fit_line";
    my @l_xy =@_;
    my ($sum1,$sum2,$sum3,$sum4,$N,$diff);
    my (%h_fit);
    my ($coef,$disp);


    $N=$#l_xy +1;
    print "number of poits to fit: $N\n";
    foreach $ref (@l_xy){
	$x=@{ $ref }[0];
	$y=@{ $ref }[1];
	$sum1+=$x;
	$sum2+=$y;
	$sum3+=$x * $y;
	$sum4+=$x * $x;
    }
    
    $coef=( $sum2/$N -$sum3/$sum1 )/( $sum1/$N -$sum4/$sum1);
    
    $disp=( $sum2 -$coef * $sum1 )/$N;

    foreach $ref (@l_xy){
	$x=@{ $ref }[0];
	$y=@{ $ref }[1];
	$diff=$y- $x*$coef -$disp;
	$h_fit{$x}{"y"}=$y;
	$h_fit{$x}{"diff"}=$diff;
    }
    #foreach $x (sort { $a <=> $b } keys %h_fit ){
    #foreach $x (sort {$h_fit{$a}{"y"} <=> $h_fit{$b}{"y"}} keys %h_fit ){
	#print "$x \t $h_fit{$x}{y} \t $h_fit{$x}{diff}\n";
    #}
    print "coef: $coef \t disp: $disp\n";
    
    if($coef < 0){
	print "coef=$coef less than zero, changing to zero\n";
	$coef=0;
    }
    return($coef,$disp);
}
#====================================================================================
