#!/usr/bin/perl -w

if (defined $ENV{'PROFCON'}){
    $root_dir = $ENV{'PROFCON'};
}else{
    $root_dir = "/home/$ENV{'USER'}/server/pub/profcon";
}

$none=0;

if (@ARGV<1){ die "Usage: $0 user_name_true input_sequence input_fasta \n";}

@e=@ARGV;
$user_name_true=$e[0]; $user_name_true=uc($user_name_true);
$user_name=$e[1];
$input_fasta=$e[2];

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
$resid[$nn]=$array[$kk];
			}

else {next LOOP_SEQ;}

		} # end of for ($kk=1

	} # end of LOOP_SEQ: while (<SEQ_F>)


$frmt=$root_dir."/".$user_name.".profcon";
open(FRMT_F,">$frmt");

if (($nn/40) == int($nn/40)) {$runs=int($nn/40);}
else {$runs=int($nn/40)+1;}

format OUTPUT =
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"PFRMAT","RR"
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"TARGET",$user_name_true
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"AUTHOR","4215-4423-5894"
#"AUTHOR","Marco Punta & Burkhard Rost, CUBIC, Columbia University New York"
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"REMARK","Number of predicted pairs is equal to 2*L, L protein length"
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"REMARK","Reference: Punta and Rost, Bioinformatics. 2005;21(13):2960-8"
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"METHOD","Feed Forward Neural Network with Back Propagation"
@<<<<<< @<<
"MODEL","1"
.

        select((select(FRMT_F),$~ = "OUTPUT")[0]);
        write (FRMT_F);

for ($kk=1; $kk<($runs+1); $kk++) {

undef @tmp_res;

for ($ii=1; $ii<(40+1); $ii++) {

if (defined $resid[$ii+($kk-1)*40]) {
push(@tmp_res,$resid[$ii+($kk-1)*40]);
				      }

			} # end of for ($ii=1


@{$print_res[$kk]}=@tmp_res;


		} # end of for ($kk=1


format OUTPUT_LAST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$print_final
.

for ($kk=1; $kk<($runs+1); $kk++) {

undef $print_final;

for ($ii=0; $ii<40; $ii++) {

if (defined $print_res[$kk][$ii]) {

if (not defined $print_final) {$print_final=$print_res[$kk][$ii];}
else {$print_final=$print_final.$print_res[$kk][$ii];}

			} # end of if (defined $print_res[$kk][$ii])

		} # end of for ($ii=1; $ii<(40+1); $ii++)

        select((select(FRMT_F),$~ = "OUTPUT_LAST")[0]);
        write (FRMT_F);

			} # end of for ($kk=1


############# END ################

