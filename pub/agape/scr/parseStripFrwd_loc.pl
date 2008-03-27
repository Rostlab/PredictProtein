#! /usr/bin/perl -w

($StripListFile,$idFile,$K_evd,$lambda_evd,$db_residue_ct)=@ARGV;

die "arguments not defined StripListFile=$StripListFile idFile=$idFile K_evd=$K_evd lambda_evd=$lambda_evd db_residue_ct=$db_residue_ct, stopped"
    if(! defined $StripListFile || ! defined $idFile ||
       ! defined $K_evd || ! defined $lambda_evd || 
       ! defined $db_residue_ct);

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


undef %gh_ids;
open(FHIN,$idFile) || die "failed to open idFile=$idFile, stopped";
while(<FHIN>){
    next if(/^\#|^\s*$/);
    s/\s//g;
    s/.*\///; s/\..*$//;
    $gh_ids{$_}=1;
}
close FHIN;


foreach $StripFile (@StripList){
    print "\n------------------\n";

    ($Lok,$msg)=&parse_strip($StripFile,$K_evd,$lambda_evd);
    die "$msg, stopped" if(! $Lok);
}

#==============================================================================
sub parse_strip{
    my $sbr='parse_strip';
    my ($StripFile,$K_evd,$lambda_evd)=@_;
    die "$0: $sbr: ERROR arguments not defined, stopped"
	if(! defined $StripFile ||
	   ! defined $K_evd || ! defined $lambda_evd);
    my ($FileOut,$HomID,$Iden,$Query,$Rank,$Read,$Score,$Zscore);
    my ($QueryLen,$HomLen,$hclass,$qclass,$class_mean,$class_stddev,
	$class_stderr,$class_size,$class_lambda,$class_miu,
	$Eval,$Pval,$EvalLoc,$z,$size,$sizeDB,$scoreTmp,$coef,$disp);
    my ($mean,$stddev,$stderr,$score,$scoreCt,$Lali);
    my (@l_ids_related_to_first);

    my ($class_miu_evd,$class_lambda_evd,$miu_evd,$Eval_evd,
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
	if(! defined $gh_ids{$HomID} ){ 
	    print "HomID=$HomID not among db ids considered\n";
	    next;
	}
	if(defined $h_Results{ $HomID } )  { next; }  #take best alignment

	
	$Zscore   =$data[ $h_field2column{'ZSCORE'} ];
	$Score    =$data[ $h_field2column{'VAL'} ];
	$Iden     =$data[ $h_field2column{'%IDEN'} ];
	$HomLen   =$data[ $h_field2column{'LEN2'} ];
	$Lali     =$data[ $h_field2column{'LEN'} ];

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
	$h_Results{$HomID}{'lali'}    =$Lali;
	$h_Results{$HomID}{'hclass'}  =$hclass;

       
	push @l_aligned_ids, $HomID;
	push @l_scores, $Score;
	push @l_loglen_scores, [log($HomLen),$Score];
    }
    close $fh;

    $sizeDB=$#l_scores + 1;
    
    foreach $HomID (keys %h_Results){
	$Score =$h_Results{$HomID}{'VAL'};
	#print "K_evd=$K_evd QueryLen=$QueryLen db_residue_ct=$db_residue_ct lambda_evd=$lambda_evd Score=$Score\n";
	$Eval=$K_evd * $QueryLen * $db_residue_ct * exp(-$lambda_evd * $Score);
	$Pval =1 - exp( -$Eval );
	print "HomID: $HomID Score: $Score Eval: $Eval Pval: $Pval\n";
	
	$h_Results{$HomID}{'Eval'}            =$Eval;
       	$h_Results{$HomID}{'Pval'}            =$Pval;
    }
    
    $FileOut=$StripFile; $FileOut=~s/.*\/|\..*$//g;
    $FileOutReg=$FileOut.".frwd-parsed";

    @l_files=(["FHOUTREG",$FileOutReg,"Pval"]);
    
    foreach $rl (@l_files){
	($fh,$FileOut,$key)=@{ $rl };
	
	open($fh,">".$FileOut) ||
	    die "failed to open FileOut=$FileOut, stopped";
        
	print $fh "queryID\trank\thomID\tP-val\tE-val\tScore\tsizeDB\tK\tlambda\n";
	$Rank=0;
	foreach $HomID (sort { $h_Results{$a}{$key} <=> $h_Results{$b}{$key} } keys %h_Results ){
	    $Rank++; $Pval=$h_Results{$HomID}{$key};
	    #$keyEval=$key; $keyEval=~s/Pval/Eval/;
	    $Eval       =$h_Results{$HomID}{"Eval"};
	    if($g_maxRankEval !~ /all/i){
		last if($Rank > $g_maxRankEval);
	    }
	    $Score =$h_Results{$HomID}{'VAL'};
	    print $fh $Query."\t".$Rank."\t".$HomID."\t".$Pval."\t".$Eval."\t".$Score."\t".$sizeDB."\t".$K_evd."\t".$lambda_evd."\n";
	
	}
	close $fh;
    }
    return(1,"$sbr: OK");
}
#===============================================================================
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
