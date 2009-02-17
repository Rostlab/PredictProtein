#!/usr/bin/perl -w


if (defined $ENV{'PROFCON'}){
    $root_dir = $ENV{'PROFCON'};
}else{
    $root_dir = "/home/$ENV{'USER'}/server/pub/profcon";
}


if (@ARGV<1){ die "Usage: $0 protein_name input_fasta \n";}

@e=@ARGV;
$user_name=$e[0];
$input_fasta=$e[1];

###### READ SEQ LENGTH ######

$seq=$input_fasta;
open(SEQ_F,"<$seq");

$nn=0;

LOOP_SEQ: while (<SEQ_F>) {

if (/^>/) {next LOOP_SEQ;}

$line=substr($_,0,10000);  $line =~ s/\s//g; chomp $line;
undef @array;
@array = split(//, $line);

for ($kk=0; $kk<10000; $kk++) {

if (defined $array[$kk]) {
$nn=$nn+1;
                        }

else {next LOOP_SEQ;}

                } # end of for ($kk=1

        } # end of LOOP_SEQ: while (<SEQ_F>)

$length=$nn;


##############################

undef %val;
undef @combo;


$numb_all=$root_dir."/".${user_name}."_NUMB_all.dat";
open(NUMB_F,"<$numb_all");


$nn=-1;


NUMB: while (<NUMB_F>) {


$nn=$nn+1;

$line=$_;


($none,$id,$res1,$res2,$type1,$type2)=split(/\s+/,$line);

$combo[$nn]=($id.",".$res1.",".$res2.",".$type1.",".$type2);

			} # end of NUMB: while (<NUMB_F>)


$parity=0;

$out_test=$root_dir."/out-fil_".$user_name;
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


$out_pred=0;

$out=$root_dir."/".$user_name.".dat";
open(OUTPUT,">$out");
foreach $val_key (sort { $val{$b} <=> $val{$a} } keys %val) {

$out_pred=$out_pred+1;

#if ($out_pred > (2*$length)) {last;}

($none1,$p_res1,$p_res2)=split(/\,/,$combo[$val_key]);
$val{$val_key}=$val{$val_key}/100;

printf OUTPUT ("%d %5d   0  8   %4.2f\n",$p_res1,$p_res2,$val{$val_key});

			} # end of foreach $val_key

close (OUTPUT);


####### END ######


