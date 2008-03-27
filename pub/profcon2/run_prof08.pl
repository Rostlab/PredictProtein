#!/usr/bin/perl -w


$root_dir = $ENV{'PROFCON'};


$none1=0;
$none2=0;

#### GENERATE INPUT FOR NN ###

#### this program - gen_nn_input.pl - generates the input files for the neural networks
#### it uses two files as input which I indicated here as input.hssp and input.rdbProf
#### i.e., the hssp alignment file and the prof output file
####  prot_name is the running protein name


if (@ARGV<3){ die "Usage: $0 protein_name(MAX 8 char.) file.fasta file.hssp file.rdbProf \n";}

@e=@ARGV;
$input_name=$e[0];
$input_fasta=$e[1];
$input_hssp=$e[2];
$input_prof=$e[3];

system("$root_dir/PROGS/gen_nn_input.pl $input_name $input_hssp $input_prof");

system("cat $root_dir/DATA/INPUT.sample_all >> $root_dir/DATA/TITLE.sample_all");

system("mv $root_dir/DATA/TITLE.sample_all $root_dir/DATA/INPUT.sample_all");


##### EXTRACT NUMBER OF SAMPLES ####

$file_tmp="$root_dir/DATA/INPUT.sample_all";
open(TMP,"<$file_tmp");

READ_TMP: while (<TMP>) {

if (/^NUMSAMFILE/) {

($none1,$none2,$nn_samples)=split(/\s+/,$_); chomp($nn_samples);

last READ_TMP;
			}
	
		} # end of READ_TMP: while (<TMP>)


#### RUN NN ##################

system("$root_dir/PROGS/NetRun.LINUX switch 642 30 2 $nn_samples 100 $root_dir/DATA/INPUT.sample_all $root_dir/DATA/jct_train.in $root_dir/DATA/out_INPUT");

system("rm $root_dir/DATA/INPUT.sample_all");


#### FILTER NN OUTPUT  #######

system("$root_dir/PROGS/filter.pl");

system("rm $root_dir/DATA/out_INPUT");


####  ORDER FILTERED OUTPUT PREDICTIONS ####

system("$root_dir/PROGS/order.pl");

system("rm $root_dir/DATA/out-fil_INPUT");


#### WRITE OUTPUT PREDICTIONS IN THE EVA FORMAT ##############


system("$root_dir/PROGS/format.pl $input_fasta");

################################################################

system("cat $root_dir/DATA/$input_name.dat >> $root_dir/DATA/$input_name.profcon");

system("cat $root_dir/DATA/frmt_end_file >> $root_dir/DATA/$input_name.profcon");

system("mv $root_dir/DATA/$input_name.profcon $root_dir/DATA/PROFcon_$input_name");

system("rm $root_dir/DATA/NUMB_all.dat");

system("rm $root_dir/DATA/$input_name.dat");



####### END #######

