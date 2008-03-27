#!/usr/bin/perl -w

if (defined $ENV{'PROFCON'}){
    $root_dir = $ENV{'PROFCON'};
}else{
    $root_dir = "/home/$ENV{'USER'}/server/pub/profcon";
			}


if (@ARGV<1){ die "Usage: $0 protein_name number_of_samples \n";}

@e=@ARGV;
$input_name=$e[0];
$count_all=$e[1];


format SAMPLEST_TITLE =
@<<<<<<<<<<<<<<<<<<<<<
"* overall: (A,T25,I8)"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"NUMIN                 :      738"
@<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>
"NUMSAMFILE            : ",$count_all
@<
"*"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"* samples: count (A8,I8) NEWLINE 1..NUMIN (25I6)"
.

$sample_all=$root_dir."/".${input_name}."_TEST_TITLE.sample_all";
open (SAMPLEST_TITLE, ">$sample_all");

        write(SAMPLEST_TITLE);


###### END #########


