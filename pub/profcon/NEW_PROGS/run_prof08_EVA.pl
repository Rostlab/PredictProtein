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

if ((defined $proc_name) and ($proc_name ne "")) {$user_name=$proc_name;}
$input_fasta=$e[1];
$input_hssp=$e[2];
$input_prof=$e[3];

##### generate .seg file from fasta file ######

system("${root_dir}/PROGS/seg $input_fasta -x > ${root_dir}/${user_name}.seg");

####

system("${root_dir}/PROGS/gen_nn_input.pl $user_name $input_hssp $input_prof ${root_dir}/${user_name}.seg");

$pos_file=$root_dir."/"."position.dat";
if (-e $pos_file) {
open(POS_1,"<$pos_file");
TURN_1: while (<POS_1>) {
$position=$_; chomp($position); $position =~ s/\s//g; last TURN_1;
                        }
close(POS_1);
                                } # end of if (-e $pos_file)

system("rm ${root_dir}/position.dat");

system("${root_dir}/PROGS/titles.pl $position");

system("cat ${root_dir}/TEST.sample_all >> ${root_dir}/TEST_TITLE.sample_all");

system("mv ${root_dir}/TEST_TITLE.sample_all ${root_dir}/${user_name}.sample_all");

$samples=$root_dir."/".${user_name}.".sample_all";
open(SAM,">>$samples");
print SAM "//","\n";
close(SAM);

system("mv ${root_dir}/NUMB_all.dat  ${root_dir}/${user_name}_NUMB_all.dat");

system("rm ${root_dir}/TEST.sample_all");
system("rm ${root_dir}/${user_name}.seg");

#####################
##### RUN THE NN ####
#####################

#### READ N_INPUT_NODES AND N_SAMPLES ############

$filein=$root_dir."/".${user_name}.".sample_all";
open(IN,"<$filein");

while(<IN>) {

if (/^NUMIN/) {
($none1,$none2,$nn_input)=split(/\s+/,$_);
chomp ($nn_input);
                        } # end of if if (/^NUMIN/)

if (/^NUMSAMFILE/) {
($none1,$none2,$nn_samples)=split(/\s+/,$_);
chomp ($nn_samples);
                        } # end of if (/^NUMSAMFILE/)

        } # end of while(<IN>)

close (IN);


##### RUN NN IN switch MODE ##############

system("${root_dir}/PROGS/NetRun.LINUX switch $nn_input 100 2 $nn_samples 100 ${root_dir}/${user_name}.sample_all ${root_dir}/JCT_TRAIN/jct_train.in ${root_dir}/out_${user_name}");

#### FILTER NN OUTPUT  #######

system("${root_dir}/PROGS/filter.pl $user_name");

system("rm ${root_dir}/out_${user_name}");


####  ORDER FILTERED OUTPUT PREDICTIONS ####

system("${root_dir}/PROGS/order_EVA.pl $user_name");

system("rm ${root_dir}/out-fil_${user_name}");


#### WRITE OUTPUT PREDICTIONS IN THE EVA FORMAT ##############


system("${root_dir}/PROGS/format_EVA.pl $user_name $input_fasta");


################################################################


system("cat ${root_dir}/${user_name}.dat >> ${root_dir}/${user_name}.profcon");

$filetmp="$root_dir/${user_name}.profcon";
open(TMP,">>$filetmp");

print TMP "END";

close (TMP);

#system("mv ${root_dir}/${user_name}.profcon ${root_dir}/${user_name}.dat");

#system("rm $input_fasta");


$to_stdout="$root_dir/".${user_name}.".profcon";
open(STD,"<$to_stdout");

READ_STD: while (<STD>) {print $_;}

system("mv $root_dir/${user_name}.profcon $root_dir/PROFcon_${user_name}  2>>$root_dir/log.err");

#system("rm $root_dir/${user_name}.profcon 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}_NUMB_all.dat 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.dat 2>>$root_dir/log.err");



####### END #######


####### END #######


####### END #######


####### END #######

