#! /usr/bin/perl -w

($StripListFile,$dbRelatFile,$idFile,$fileStatOut)=@ARGV;

die "arguments not defined StripListFile=$StripListFile dbRalatFile=$dbRelatFile idFile=$idFile, stopped"
    if(! defined $StripListFile || ! defined $dbRelatFile || 
       ! defined $idFile);

$g_maxRankEval="all";
$g_doBin=0;

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
undef %h_id2related;
open(FHIN,$dbRelatFile) ||
    die "failed to open dbRelatFile=$dbRelatFile, stopped";
while(<FHIN>){
    next if(/^\#|^\s*$/);
    s/\s*$//;
    ($id,$related)=split(/\t/,$_);
    die "in file $dbRelatFile id or group not found in line:\n$_\n, stopped"
	if(! defined $id || ! defined $related);
    $h_id2related{$id}=$related;
}
close FHIN;  #-------------------------------------------

if(defined $fileStatOut){
    open(FHOUTSTAT,">".$fileStatOut) || 
	die "failed to open $fileStatOut for wrting, stopped";
}

foreach $StripFile (@StripList){
    print "\n------------------\n";

    ($Lok,$msg)=&parse_strip($StripFile);
    die "$msg, stopped" if(! $Lok);
}

#==============================================================================
sub parse_strip{
    my $sbr='parse_strip';
    my ($StripFile)=@_;
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
	%h_ids_related_to_first);   
    
    my $fh=$sbr.$$;
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
	
	push @l_all_lengths, $HomLen;
	#modify score with length dependence
	#$Score=$Score -log($QueryLen) - log($HomLen);
	#$h_Results{$HomID}{'Zscore'}  =$Zscore;
	
	next if($Query eq $HomID);
	
	$scoreCt++;
	$h_Results{$HomID}{'VAL'}     =$Score;
	$h_Results{$HomID}{'%IDEN'}   =$Iden;
	$h_Results{$HomID}{'qlen'}    =$QueryLen;
	$h_Results{$HomID}{'hlen'}    =$HomLen;
	$h_Results{$HomID}{'hclass'}  =$hclass;

       
	if(! defined $firstHomID){
	    $firstHomID=$HomID;
	    print "firstHomID=$firstHomID\n";
	    $tmp=$h_id2related{$HomID};
	    die "related ids for HomID=$HomID not defined, stopped"
		if(! defined $tmp);
	    @l_ids_related_to_first=split(/\,/,$tmp);
	    unshift @l_ids_related_to_first, $firstHomID;
	    foreach $it (@l_ids_related_to_first){ $h_ids_related_to_first{$it}=1; }
	    print "related ids to first one $HomID : @l_ids_related_to_first\n";
	}
	
	push @l_aligned_ids, $HomID;
	push @l_scores, $Score;
	push @l_loglen_scores, [log($HomLen),$Score];
    }
    close $fh;

    $sizeDB=$#l_scores+1;
    ($meanAll,$stddevAll,$stderrAll)=&get_statistics(@l_scores);
    
    
    if(0 >1){
	if($scoreCt != $g_setSize -1){
	    foreach $id (keys %h_ids){
		next if($id eq $Query);
		if(! defined $h_Results{$id}){
		    print "id=$id not found in h_Results hash\n";
		}
	    }
	    foreach $id (keys %h_Results){
		next if($id eq $Query);
		if(! defined $h_ids{$id}){
		    print "id=$id not found in h_ids hash\n";
		}
	    }
	    die "did not find all of the alignments $scoreCt ne $g_setSize, stopped"
	}
    }
    
    if(0<1){
	die "sizes of arrays not equal, stopped" 
	    if($#l_aligned_ids != $#l_scores);
	@l_scoresTmp=@l_scoresTmp2=(); 
	@l_scores_related=@l_loglen_scores_related=();
	for $i (0 .. $#l_aligned_ids){
	    $HomID=$l_aligned_ids[$i];
	    if(! defined $h_ids_related_to_first{$HomID} ){
		push @l_scoresTmp, $l_scores[$i];
		push @l_scoresTmp2, $l_loglen_scores[$i];
	    }else{ 
		push @l_scores_related, $l_scores[$i]; 
		push @l_loglen_scores_related, $l_loglen_scores[$i];
	    }
	}
	@l_scores         =@l_scoresTmp;
	@l_loglen_scores  =@l_scoresTmp2;
	
	#($meanLoc,$stddevLoc,$stderrLoc)=&get_statistics(@l_scores);
	#$lambdaLoc  =3.1415/( sqrt(6) * $stddevLoc);
	#$miuLoc     =$meanLoc - 0.5772/$lambdaLoc;
		
	print "INFO: scores: $#l_scores +1\n";
	print "INFO: scores related: $#l_scores_related +1\n";
    }
    @l_scores   =sort {$b <=> $a} @l_scores;

    
    if($g_doBin){
	$minx=100000; $maxx=-100000; $ctLoc=0;
	foreach $ref (@l_loglen_scores){
	    $x=$ref -> [0];
	    $y=$ref -> [1];
	    $ctLoc++;
	    if($minx > $x){ $minx=$x; };
	    if($maxx < $x){ $maxx=$x; };
	}
	$step=20 * ($maxx - $minx)/$ctLoc;
	print "step: $step\n";
	
	undef %h_score_bins;
	foreach $ref (@l_loglen_scores){
	    $ctLoc++;
	    $x=$ref -> [0];
	    $y=$ref -> [1];
	    $binNo=int ($x/$step);
	    push @{ $h_score_bins{$binNo}{"x"} }, $x;
	    push @{ $h_score_bins{$binNo}{"y"} }, $y;
	}
	print "minx: $minx \t maxx: $maxx \t ctLoc: $ctLoc\n";
	
	@l_bin_vals=();
	foreach $binNo (keys %h_score_bins){
	    @l_tmp=@{ $h_score_bins{$binNo}{"y"} };
	    #next if($#l_tmp <=0);
	    ($aveLoc,$stddevLoc,$stderrLoc)=&get_statistics(@l_tmp);
	    $binCoor=$binNo * $step + 0.5 * $step;
	    $aveLoc=sprintf "%6.1f", $aveLoc;
	    push @l_bin_vals,[$binCoor,$aveLoc];
	}
	undef $aveLoc; undef $stddevLoc; undef $stderrLoc;
    }else{
	@l_bin_vals=();
	foreach $ref (@l_loglen_scores){
	    $x=$ref -> [0];
	    $y=$ref -> [1];
	    push @l_bin_vals,[$x,$y];
	}
    }
    #print "l_bin_vals: ";
    #foreach $it (@l_bin_vals){
#	print " @{ $it }\n";
#    }
#    print "\n";

    ($coef,$disp)=&fit_line(@l_bin_vals);
    $disp=0; 
    #$coef=0;

    print "fit: coef=$coef  disp=$disp\n";
    $h_classDistbn{"coef"}=$coef;
    $h_classDistbn{"disp"}=$disp;
    
   
    @l_scores=(); $nLoc=0;
    foreach $ref (@l_loglen_scores){
	$nLoc++;
	($loglen,$score)=@{ $ref };
	$score=$score - $loglen * $coef - $disp;
	push @l_scores, $score;
    }
    ($meanLoc,$stddevLoc,$stderrLoc) =&get_statistics(@l_scores);
    $lambdaLoc  =3.1415/( sqrt(6) * $stddevLoc );
    $miuLoc     =$meanLoc - 0.5772/$lambdaLoc;
    
    
    $tmp=$#l_loglen_scores_related +1;
    print "total number of possibly related scores: $tmp\n";
    $flagNotPrepend=0; @l_scores2prepend=();
    foreach $ref (@l_loglen_scores_related){
	($loglen,$score) =@{ $ref };
	$score           =$score - $loglen * $coef - $disp;
	push @l_scores2prepend, $score;
	$PvalLoc         =1-exp( -exp( -$lambdaLoc * ($score -$miuLoc) ) );
	$EvalLoc         =($nLoc +1) * $PvalLoc;
	if($EvalLoc >=1){
	    #print "prepending score\n";
	    #@unshift @l_class_scores, $score;
	}else{ $flagNotPrepend=1; }
    }
    if(! $flagNotPrepend){ 
	print "prepending\n";
	unshift @l_scores, @l_scores2prepend; 
    }
    
    @l_scores =sort {$b <=> $a} @l_scores;
    @l_scores =map { sprintf "%6.1f", $_; } @l_scores;
    
    $size=$#l_scores +1;
    
    print "size: $size\n";
    
    if($#l_scores > -1){ 
	($mean,$stddev,$stderr)=
	    &get_statistics(@l_scores);
	undef $stderr;
	$lambda  =3.1415/( sqrt(6) * $stddev);
	$miu     =$mean - 0.5772/$lambda;
	#print "1:   $class_mean, $class_stddev, $class_stderr\n";
	if($#l_scores > 25){
	    $h_classDistbn{"mean"}      =$mean;
	    $h_classDistbn{"stddev"}    =$stddev;
	    $h_classDistbn{"size"}      =$size;
	    
	    ($miu_evd,$lambda_evd)=
		&get_evd(@l_scores);
	    #print "2:   $class_miu_evd, $class_lambda_evd\n";
	    $h_classDistbn{"miu_evd"}   =$miu_evd;
	    $h_classDistbn{"lamda_evd"} =$lambda_evd;
	    
	    
	    ($miu_evd_censd,$lambda_evd_censd)=
		&get_evd_censd(@l_scores);
	    
	    undef $stderr;
	    
	    $h_classDistbn{"miu_evd_censd"}   =$miu_evd_censd;
	    $h_classDistbn{"lamda_evd_censd"} =$lambda_evd_censd;
	    
	}else{
	    print "WARNING: number of scores is smaller than 25\n";
	    if($stddev ==0){ $stddev=1000; } #if zero make scores insignificant
	    $h_classDistbn{"mean"}      =$mean;
	    $h_classDistbn{"stddev"}    =$stddev;
	    $h_classDistbn{"size"}      =$size;
	    $h_classDistbn{"miu_evd"}   =$miu;
	    $h_classDistbn{"lamda_evd"} =$lambda;
	    
	    $h_classDistbn{"miu_evd_censd"}   =$miu;
	    $h_classDistbn{"lamda_evd_censd"} =$lambda;
	    
	}
    }else{ #no scores in that class
	#print "WARNING: no scores found in this class\n";
	die "ERROR no scores found, stopped";
	$stddev=1000;
	$mean=1;
	
	$h_classDistbn{"mean"}      =$mean;
	$h_classDistbn{"stddev"}    =$stddev;
	$h_classDistbn{"size"}      =0;
	$h_classDistbn{"miu_evd"}   =$miu;
	$h_classDistbn{"lamda_evd"} =$lambda;
	
	$h_classDistbn{"miu_evd_censd"}   =$miu;
	$h_classDistbn{"lamda_evd_censd"} =$lambda;
	
    }

    if(defined $fileStatOut){
	print FHOUTSTAT $Query."\t".$coef."\t".$disp."\t".$miu."\t".$lambda."\t".$h_classDistbn{"miu_evd"}."\t".$h_classDistbn{"lamda_evd"}."\t".$h_classDistbn{"miu_evd_censd"}."\t".$h_classDistbn{"lamda_evd_censd"}."\n";
    }

    foreach $HomID (keys %h_Results){
	$score =$h_Results{$HomID}{'VAL'};
	$len   =$h_Results{$HomID}{'hlen'};
	$Eval=$Eval_evd=$Eval_evd_censd=0;

	$coef          =$h_classDistbn{"coef"};
	$disp          =$h_classDistbn{"disp"};
	$score         =$score -log($len) * $coef - $disp;
	$h_Results{$HomID}{'lenAdjScore'}=$score;
	$mean          =$h_classDistbn{"mean"};
	$stddev        =$h_classDistbn{"stddev"};
	$size          =$h_classDistbn{"size"};
	$miu_evd       =$h_classDistbn{"miu_evd"};
	$lambda_evd    =$h_classDistbn{"lamda_evd"};
	
	$miu_evd_censd          =$h_classDistbn{"miu_evd_censd"};
	$lambda_evd_censd       =$h_classDistbn{"lamda_evd_censd"};
	
	
	$lambda     =3.1415/( sqrt(6) * $stddev);
	$miu        =$mean - 0.5772/$lambda;
	$Pval       =1-exp( -exp( -$lambda * ($score -$miu) ) );
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
    $FileOutReg=$FileOut.".frwd-parsed";
    $FileOutEvd=$FileOut.".frwd-parsed_evd";
    $FileOutEvdCensd=$FileOut.".frwd-parsed_evd_c";

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
	    $Eval       =$h_Results{$HomID}{$keyEval};
	    $miuLoc     =$h_Results{$HomID}{'miu'};
	    $lambdaLoc  =$h_Results{$HomID}{'lambda'};
	    if($g_maxRankEval !~ /all/i){
		last if($Rank > $g_maxRankEval);
	    }
	    $Score =$h_Results{$HomID}{'lenAdjScore'};
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
	if($F < $Precision && $F > -$Precision){
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
