#!/usr/bin/perl -w


$root_dir = $ENV{'PROFCON'};

format OUTPUT =
@<<<<<< @>>>>>> @>>>>>> @>>>>>> @>>>>>> @>>>>>> @>>>>>> @>>>>>>
"CONTC",$p_res1,$p_res2,$p_type1,$p_type2,"0","8",$val{$val_key}
.

undef %val;
undef @combo;


$numb_all=$root_dir."/DATA/NUMB_all.dat";
open(NUMB_F,"<$numb_all");


$nn=-1;


NUMB: while (<NUMB_F>) {


$nn=$nn+1;

$line=$_;


($none,$id,$res1,$res2,$type1,$type2)=split(/\s+/,$line);

$combo[$nn]=($id.",".$res1.",".$res2.",".$type1.",".$type2);

			} # end of NUMB: while (<NUMB_F>)


$parity=0;

$out_test=$root_dir."/DATA/out-fil_INPUT";
open(TEST,"<$out_test");

OUT: while(<TEST>) {

if (/out vec/) {$check=1; next OUT;}

if (not defined $check) {next OUT;}

if ($parity==1) {$parity=0; next OUT;}

if ($parity==0) {$parity=1;

$line=$_;

($none,$numb,$left)=split(/\s+/,$line);

$val{($numb+1)/2-1}=$left; chomp($val{($numb+1)/2-1});


			} # end of if ($parity==0)

		} # end of OUT: while(<TEST>)


foreach $val_key (sort { $val{$b} <=> $val{$a} } keys %val) {

($p_name,$p_res1,$p_res2,$p_type1,$p_type2)=split(/\,/,$combo[$val_key]);

$out=$root_dir."/DATA/".$p_name.".dat";
open(OUTPUT,">>$out");

$val{$val_key}=$val{$val_key}/100;

write (OUTPUT);

close (OUTPUT);

			} # end of foreach $val_key


