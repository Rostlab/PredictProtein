#!/usr/bin/perl -w

if (defined $ENV{'PROFCON'}){
    $root_dir = $ENV{'PROFCON'};
}else{
    $root_dir = "/home/$ENV{'USER'}/server/pub/profcon";
}

$none=0;

if (@ARGV<1){ die "Usage: $0 input_sequence iinput_fasta \n";}

@e=@ARGV;
$user_name=$e[0];
$input_fasta=$e[1];


$numb_all=$root_dir."/".${user_name}."_NUMB_all.dat";
open(NUMB_F,"<$numb_all");


NUMB: while (<NUMB_F>) {

($none,$id)=split(/\s+/,$_);
last NUMB;

			} # end of NUMB: while (<NUMB_F>)


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

#format OUTPUT =
#@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#"PFRMAT","RR"
#@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#"TARGET",$id
#@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#"AUTHOR","Marco Punta & Burkhard Rost, CUBIC, Columbia University New York"
#@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#"REMARK","Reference: xxx"
#@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#"METHOD","Feed Forward Neural Network with Back Propagation"
#@<<<<<<
#"MODEL"
#.

print FRMT_F "PFRMAT","\t","RR","\n";
print FRMT_F "TARGET","\t",$id,"\n";
print FRMT_F "AUTHOR","\t","Marco Punta & Burkhard Rost, CUBIC, Columbia University New York","\n";
print FRMT_F "REMARK","\t","Reference: xxx","\n";
print FRMT_F "METHOD","\t","Feed Forward Neural Network with Back Propagation","\n";
print FRMT_F "MODEL","\n";


#        select((select(FRMT_F),$~ = "OUTPUT")[0]);
#        write (FRMT_F);

for ($kk=1; $kk<($runs+1); $kk++) {

undef @tmp_res;

for ($ii=1; $ii<(40+1); $ii++) {

if (defined $resid[$ii+($kk-1)*40]) {
push(@tmp_res,$resid[$ii+($kk-1)*40]);
				      }

			} # end of for ($ii=1


@{$print_res[$kk]}=@tmp_res;


		} # end of for ($kk=1


#format OUTPUT_LAST =
#@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#"SEQRES",$print_final
#.

for ($kk=1; $kk<($runs+1); $kk++) {

undef $print_final;

for ($ii=0; $ii<40; $ii++) {

if (defined $print_res[$kk][$ii]) {

if (not defined $print_final) {$print_final=$print_res[$kk][$ii];}
else {$print_final=$print_final.$print_res[$kk][$ii];}

			} # end of if (defined $print_res[$kk][$ii])

		} # end of for ($ii=1; $ii<(40+1); $ii++)

print FRMT_F "SEQRES","\t",$print_final,"\n";

#        select((select(FRMT_F),$~ = "OUTPUT_LAST")[0]);
#        write (FRMT_F);

			} # end of for ($kk=1


############# END ################

