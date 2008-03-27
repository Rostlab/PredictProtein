#!/usr/bin/perl -w


$root_dir = $ENV{'PROFCON'};


##### read predicted values


format OUT_1 =
@>>>>>>> @>>>@>>>
($nn_pred*2-1),$out_1,$out_2
.

format OUT_2 =
@>>>>>>> @>>>@>>>
($nn_pred*2),$out_1,$out_2
.


$nn_pred=0;

$pair=1;
undef $score_pred;

$out=$root_dir."/DATA/out-fil_INPUT";
open(FOUT,">$out");

$prd=$root_dir."/DATA/out_INPUT";
open(PRED,"<$prd");

LOOP_PRED: while (<PRED>) {
if (/^       1/) {$score_pred=1;}
if (defined $score_pred) {

if ($pair==0) {$pair=1; 

$values_pred=substr($_,0,25);
($null_pred,$numb_pred,$out_1_pred,$out_2_pred)=split(/\s+/,$values_pred);
if ($null_pred eq "//") {next LOOP_PRED;}

$pred_anti_1=$out_1_pred;
$pred_anti_2=$out_2_pred;

$out_1=int(($pred_1+$pred_anti_1)/2);
$out_2=int(($pred_2+$pred_anti_2)/2);

        select((select(FOUT),$~ = "OUT_1")[0]);
        write(FOUT);

        select((select(FOUT),$~ = "OUT_2")[0]);
        write(FOUT);

next LOOP_PRED;

		} # end of if ($pair==0)

if ($pair==1) {$pair=0;

$nn_pred=$nn_pred+1;
$values_pred=substr($_,0,25);
($null_pred,$numb_pred,$out_1_pred,$out_2_pred)=split(/\s+/,$values_pred);
if ($null_pred eq "//") {next LOOP_PRED;}

$pred_1=$out_1_pred;
$pred_2=$out_2_pred;

		} # end of if ($pair==1)

         } # end of if (defined $score_pred)

else {print FOUT $_;}

    } # end of LOOP_PRED: while (<PRED>)


close (PRED);
close (FOUT);


