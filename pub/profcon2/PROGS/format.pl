#!/usr/bin/perl -w

$root_dir = $ENV{'PROFCON'};


$none=0;

if (@ARGV<1){ die "Usage: $0 input_sequence \n";}

@e=@ARGV;
$input_seq=$e[0];

($in_name)=split(/\./,$input_seq);

$numb_all=$root_dir."/DATA/NUMB_all.dat";
open(NUMB_F,"<$numb_all");

NUMB: while (<NUMB_F>) {

($none,$id)=split(/\s+/,$_);
last NUMB;

			} # end of NUMB: while (<NUMB_F>)


$seq=$root_dir."/".$input_seq;
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


$frmt=$root_dir."/DATA/".$in_name.".profcon";
open(FRMT_F,">$frmt");

$runs=int($nn/40)+1;

format OUTPUT =
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"PFRMAT","RR"
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"TARGET",$id
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"AUTHOR","Marco Punta & Burkhard Rost, CUBIC, Columbia University New York"
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"REMARK","Reference: xxx"
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"METHOD","Feed Forward Neural Network with Back Propagation"
@<<<<<<
"MODEL"
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
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"SEQRES",$print_final
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


#for ($kk=1; $kk<($runs+1); $kk++) {
#
#print FRMT_F "SEQRES  ",$resid[1+($kk-1)*40],$resid[2+($kk-1)*40],$resid[3+($kk-1)*40],$resid[4+($kk-1)*40],
#$resid[5+($kk-1)*40],$resid[6+($kk-1)*40],$resid[7+($kk-1)*40],$resid[8+($kk-1)*40],$resid[9+($kk-1)*40],
#$resid[10+($kk-1)*40],$resid[11+($kk-1)*40],$resid[12+($kk-1)*40],$resid[13+($kk-1)*40],$resid[14+($kk-1)*40],
#$resid[15+($kk-1)*40],$resid[16+($kk-1)*40],$resid[17+($kk-1)*40],$resid[18+($kk-1)*40],$resid[19+($kk-1)*40],
#$resid[20+($kk-1)*40],$resid[21+($kk-1)*40],$resid[22+($kk-1)*40],$resid[23+($kk-1)*40],$resid[24+($kk-1)*40],
#$resid[25+($kk-1)*40],$resid[26+($kk-1)*40],$resid[27+($kk-1)*40],$resid[28+($kk-1)*40],$resid[29+($kk-1)*40],
#$resid[30+($kk-1)*40],$resid[31+($kk-1)*40],$resid[32+($kk-1)*40],$resid[33+($kk-1)*40],$resid[34+($kk-1)*40],
#$resid[35+($kk-1)*40],$resid[36+($kk-1)*40],$resid[37+($kk-1)*40],$resid[38+($kk-1)*40],$resid[39+($kk-1)*40],
#$resid[40+($kk-1)*40],"\n";
#
#				} # end of for ($kk=1


