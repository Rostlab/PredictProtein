#!/usr/bin/perl -w


if (defined $ENV{'PROFCON'}){
    $root_dir = $ENV{'PROFCON'};
}else{
    $root_dir = "/home/$ENV{'USER'}/server/pub/profcon";
}


$none1=0;
$none2=0;

#### GENERATE INPUT FOR NN ###

#### this program - gen_nn_input.pl - generates the input files for the neural networks
#### it uses two files as input which I indicated here as input.hssp and input.rdbProf
#### i.e., the hssp alignment file and the prof output file
####  prot_name is the running protein name


if (@ARGV<3){ die "Usage: $0 protein_name file.fasta file.hssp file.rdbProf \n";}

@e=@ARGV;
$input_name=$e[0];
($user_name,$proc_name)=split(/\./,$input_name);

if ($proc_name ne "") {$user_name=$proc_name;}
$input_fasta=$e[1];
$input_hssp=$e[2];
$input_prof=$e[3];

system("$root_dir/PROGS/gen_nn_input.pl $user_name $input_hssp $input_prof");

system("cat $root_dir/${user_name}.sample_all >> $root_dir/${user_name}_TITLE.sample_all");

system("mv $root_dir/${user_name}_TITLE.sample_all $root_dir/${user_name}.sample_all");


##### EXTRACT NUMBER OF SAMPLES ####

$file_tmp="$root_dir/${user_name}.sample_all";
open(TMP,"<$file_tmp");

READ_TMP: while (<TMP>) {

if (/^NUMSAMFILE/) {

($none1,$none2,$nn_samples)=split(/\s+/,$_); chomp($nn_samples);

last READ_TMP;
			}
	
		} # end of READ_TMP: while (<TMP>)


#### RUN NN ##################

system("$root_dir/PROGS/NetRun.LINUX switch 642 30 2 $nn_samples 100 $root_dir/${user_name}.sample_all $root_dir/jct_train.in $root_dir/out_${user_name}");

system("rm $root_dir/${user_name}.sample_all");


#### FILTER NN OUTPUT  #######

system("$root_dir/PROGS/filter.pl $user_name");

system("rm $root_dir/out_${user_name}");


####  ORDER FILTERED OUTPUT PREDICTIONS ####

system("$root_dir/PROGS/order.pl $user_name");

system("rm $root_dir/out-fil_${user_name}");


#### WRITE OUTPUT PREDICTIONS IN THE EVA FORMAT ##############


system("$root_dir/PROGS/format.pl $input_fasta $user_name");

################################################################

system("cat $root_dir/${user_name}.dat >> $root_dir/${user_name}.profcon");

system("cat $root_dir/frmt_end_file >> $root_dir/${user_name}.profcon");


$to_stdout="$root_dir/".$user_name.".profcon";
open(STD,"<$to_stdout");

READ_STD: while (<STD>) {print $_;}


#system("mv $root_dir/${user_name}.profcon $root_dir/PROFcon_${user_name}  2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.profcon 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}_NUMB_all.dat 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.dat 2>>$root_dir/log.err");



####### END #######

