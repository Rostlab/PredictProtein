#! /usr/bin/perl -w

($fileFrwd,$fileRvsd,$fileOut)=@ARGV;

$this=$0; $this=~s/^.*\///;

die "$0: arguments not defined, stopped"
    if(! defined $fileFrwd || ! defined $fileRvsd || ! defined $fileOut);


undef $rank; undef %h_frwd;
open(FHIN,$fileFrwd) || die "$this: failed to open fileFrwd=$fileFrwd, stopped";
while(<FHIN>){
    next if(/^(QUERY)|^\s*$/);
    next if(/^queryID/);
    $_=~s/\s*$//;
    ($id1,$rank,$id2,$pval,$Eval,$score,$sizeDBloc,$miuFrwd,$lambdaFrwd)=split(/\t/,$_);
    die "$this: data not defined: id1=$id1, id2=$id2, rank=$rank, pval=$pval, eval=$Eval, score=$score, sizeDB=$sizeDBloc, miuFrwd=$miuFrwd, lambdaFrwd=$lambdaFrwd, stopped"
	if(! defined $id1 || ! defined $rank || ! defined $id2 || ! defined $pval || ! defined $Eval || ! defined $score || ! defined $sizeDBloc || ! defined $miuFrwd || ! defined $lambdaFrwd);
    if(! defined $qID1){ $qID1=$id1; }
    if(defined $h_frwd{$id1}{$id2}){
	die "$this: score for $id1 $id2 already defined, stopped";
    }
    die "$this: size of database not defined in line:$_\n, stopped"
	if(! defined $sizeDBloc);
    if(! defined $sizeDB1){ $sizeDB1=$sizeDBloc; }
    $h_frwd{$id1}{$id2}{'pval'}    =$pval;
    $h_frwd{$id1}{$id2}{'eval'}    =$Eval;
    $h_frwd{$id1}{$id2}{'miu'}     =$miuFrwd;
    $h_frwd{$id1}{$id2}{'lambda'}  =$lambdaFrwd;
    $h_frwd{$id1}{$id2}{'score'}   =$score;
}
close FHIN;

undef $rank; undef %h_rvsd;
open(FHIN,$fileRvsd) || die "$this: failed to open fileRvsd=$fileRvsd, stopped";
while(<FHIN>){
    next if(/^(QUERY)|^\s*$/);
    next if(/^queryID/);
    $_=~s/\s*$//;
    ($id1,$rank,$id2,$pval,$Eval,$score,$sizeDBloc,$miuRvsd,$lambdaRvsd)=split(/\t/,$_); 
    die "$this: data not defined: id1=$id1, id2=$id2, rank=$rank, pval=$pval, eval=$Eval, score=$score, sizeDB=$sizeDBloc, miuRvsd=$miuRvsd, lambdaRvsd=$lambdaRvsd, stopped"
	if(! defined $id1 || ! defined $rank || ! defined $id2 || ! defined $pval || ! defined $Eval || ! defined $score || ! defined $sizeDBloc || ! defined $miuRvsd || ! defined $lambdaRvsd);
    if(! defined $qID2){ $qID2=$id1; }
    if(defined $h_rvsd{$id1}{$id2}){
	die "$this: score for $id1 $id2 already defined, stopped";
    }
    die "$this: size of database not defined in line:$_\n, stopped"
	if(! defined $sizeDBloc);
    if(! defined $sizeDB2){ $sizeDB2=$sizeDBloc; }
    $h_rvsd{$id1}{$id2}{'pval'}    =$pval;
    $h_rvsd{$id1}{$id2}{'eval'}    =$Eval;
    $h_rvsd{$id1}{$id2}{'miu'}     =$miuRvsd;
    $h_rvsd{$id1}{$id2}{'lambda'}  =$lambdaRvsd;
    $h_rvsd{$id1}{$id2}{'score'}   =$score;
}
close FHIN;

die "$this: different query ids for frwd and revrsd searches: $qID1 and $qID2, stopped"
    if($qID1 ne $qID2);
$qID=$qID1;

die "$this: different frwd and rvsd database sizes: dbFrwd=$sizeDB1 and dbRvsd$sizeDB2, stopped"
    if($sizeDB1 ne $sizeDB2);
$sizeDB=$sizeDB1;

@l_frwdIds=keys %{ $h_frwd{$qID} }; 
$sizeDB1Found=$#l_frwdIds +1;
die "$this: sizeDB frwd declared not equal to found: $sizeDB $sizeDB1Found, stopped"
    if($sizeDB1Found ne $sizeDB);

@l_rvsdIds=keys %{ $h_frwd{$qID} }; 
$sizeDB2Found=$#l_rvsdIds +1;
die "$this: sizeDB rvsd declared not equal to found: $sizeDB $sizeDB2Found, stopped"
    if($sizeDB2Found ne $sizeDB);


foreach $id1 (sort keys %h_frwd){ 
    foreach $id2 (sort keys %{ $h_frwd{$id1} }){
	if(! defined $h_rvsd{$id1}{$id2}{'pval'}){
	    $h_rvsd{$id1}{$id2}{'pval'}=1;
	}
    }
}

foreach $id1 (sort keys %h_rvsd){ 
    foreach $id2 (sort keys %{ $h_rvsd{$id1} }){
	if(! defined $h_frwd{$id1}{$id2}{'pval'}){
	    $h_frwd{$id1}{$id2}{'pval'}=1;
	}
    }
}

undef %h_combPval; 
foreach $id1 (sort keys %h_frwd){ 
    foreach $id2 (sort keys %{ $h_frwd{$id1} }){
	next if( defined $h_combPval{$id1}{$id2}{'pval'} );
	$score =$h_frwd{$id1}{$id2}{'pval'}*$h_rvsd{$id1}{$id2}{'pval'}; 
	$score =&qfast(2,$score);
	$h_combPval{$id1}{$id2} =$score;
    }
}

#$tmp1=$fileIn1; $tmp1=~s/^.*\///; $tmp1=~s/\..*//;
#$tmp2=$fileIn2; $tmp2=~s/^.*\///; $tmp2=~s/\..*//;
#$fileOut=$tmp1."-and-".$tmp2.".comb";


open(FHOUT,">".$fileOut) || 
    die "$this: failed to open fileOut=$fileOut, stopped";
print FHOUT "queryID\trank\thomID\tcombPval\tbetter\tcombEval\tscore\tmiuBest\tlambdaBest\tfrwdPval\tfrwdEval\trvsdPval\trvsdEval\n";
foreach $id1 (sort keys %h_combPval){
    $rank=0;
    foreach $id2 (sort {$h_combPval{$id1}{$a} <=> $h_combPval{$id1}{$b}} keys %{ $h_combPval{$id1} }){
	$rank++;
	$combPval=$h_combPval{$id1}{$id2};
	$combEval=$combPval * $sizeDB;
	$frwdPval=$h_frwd{$id1}{$id2}{'pval'};
	$frwdEval=$h_frwd{$id1}{$id2}{'eval'};
	$rvsdPval=$h_rvsd{$id1}{$id2}{'pval'};
	$rvsdEval=$h_rvsd{$id1}{$id2}{'eval'};
	undef $score; undef $miuBest; undef $lambdaBest;
	if($h_frwd{$id1}{$id2}{'pval'} <= $h_rvsd{$id1}{$id2}{'pval'}){ 
	    $better     ="frwd"; 
	    $score      =$h_frwd{$id1}{$id2}{'score'};
	    $miuBest    =$h_frwd{$id1}{$id2}{'miu'};
	    $lambdaBest =$h_frwd{$id1}{$id2}{'lambda'};
	}else{ 
	    $better     ="rvsd"; 
	    $score      =$h_rvsd{$id1}{$id2}{'score'};
	    $miuBest    =$h_rvsd{$id1}{$id2}{'miu'};
	    $lambdaBest =$h_rvsd{$id1}{$id2}{'lambda'};
	}
	die "$this: values not defined: score=$score, miuBest=$miuBest, lambdaBest=$lambdaBest, combPval=$combPval, combEval=$combEval, frwdPval=$frwdPval, frwdEval=$frwdEval, rvsdPval=$rvsdPval, rvsdEval=$rvsdEval, stopped"
	    if(! defined $score || ! defined $miuBest || ! defined $lambdaBest || ! defined $combPval || ! defined $combEval || ! defined $frwdPval || ! defined $frwdEval || ! defined $rvsdPval || ! defined $rvsdEval);
	@l_line=($id1,$rank,$id2,$combPval,$better,$combEval,$score,$miuBest,$lambdaBest,$frwdPval,$frwdEval,$rvsdPval,$rvsdEval);
	$line=join "\t", @l_line;
	print FHOUT $line,"\n";
    }
}
close FHOUT;



#====================================================================================
sub qfast{
    my $sbr="qfast";
    my ($distN,$distProd)=@_;
    my ($x,$t,$q,$i);
    die "$this: ERROR: $sbr: distN=$distN or distProd=$distProd not defined, stopped"
	if(! defined $distProd || ! defined $distProd);
    if($distProd ==0 ){ return 0; }
    if($distN > 1){ 
	$x=-log( $distProd); 
	$t=$distProd;
	$q=$distProd;
	for $i (1 .. $distN -1){
	    $t=$t * $x/$i;
	    $q=$q + $t;
	}
    }else{ $q=$distProd; }
    return $q; 
}
#====================================================================================	
