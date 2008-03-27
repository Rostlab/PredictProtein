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

if (@ARGV<2){ die "Usage: $0 file.fasta process_id target_name\n";}

@e=@ARGV;

$input_fasta=$e[0];
$proc_name=$e[1];   # this is a process ID 
$user_name_true=$e[2];  # this is the target name chosen by the user

$user_name = $proc_name;

system ("cp $input_fasta ${root_dir}/${user_name}.fasta");
$input_fasta=${root_dir}."/".${user_name}.".fasta";


#### determine protein length (in aa) ####

open(INFASTA,"<$input_fasta");

while(<INFASTA>) {

if (/^>/) {next;}

elsif (/[A-Z]/) {

$line=$_; chomp($line);

(@seq)=split(//,$line);

for ($ii=0; $ii<100001; $ii++) {

if (not defined $seq[$ii]) {last;}

else {$length=$ii+1;}

	} # end of for ($ii=0; $ii<100001; $ii++)

	   } # end of elsif (/[A-Z]/)

	} # end of while(<INFASTA>)

close(INFASTA);

$iter=(($length-5)*($length-5)/90000);

##### generate .seg file from fasta file ######

system("${root_dir}/PROGS/seg $input_fasta -x > ${root_dir}/${user_name}.seg");


$checkfile="${root_dir}/333333.blastpgp";

if (!-e $checkfile) {

##### run psi-blast - old 2001 version and prof #######

system ("${root_dir}/PROGS/blastpgp.pl $input_fasta saf maxAli=3000 eSaf=1 exe=/usr/pub/molbio/blast-2.2.2/blastpgp dirOut=${root_dir}/ 1>/dev/null");

	} # end of if (!-e $checkfile)

else {
$filetmp="$root_dir/${user_name}.profcon";
open(TMP,">$filetmp");
print TMP "BLAST failed! Sorry, no output from PROFcon"\n";
close(TMP);
die;
	} # end of else

#### check if exist aligned sequences ######

if (system ("grep \"*** No hits found ***\" ${root_dir}/${user_name}.blastpgp") != 0) {


$checkfile="${root_dir}/333333-fil.hssp";

if (!-e $checkfile) {

system ("${root_dir}/PROGS/copf.pl ${root_dir}/${user_name}.saf hssp fileOut=${root_dir}/${user_name}.hssp 1>/dev/null");
system ("${root_dir}/PROGS/hssp_filter.pl ${root_dir}/${user_name}.hssp red=80 fileOut=${root_dir}/${user_name}-fil.hssp 1>/dev/null");

	} # end of if (!-e $checkfile)

else {
$filetmp="$root_dir/${user_name}.profcon";
open(TMP,">$filetmp");
print TMP "COPF or HSSP-FILTER failed! Sorry, no output from PROFcon","\n"; 
close(TMP);
die;
        } # end of else




$checkfile="${root_dir}/333333-fil.rdbProf";

if (!-e $checkfile) {

system ("${root_dir}/PROGS/prof ${root_dir}/${user_name}-fil.hssp fileOut=${root_dir}/${user_name}-fil.rdbProf 1>/dev/null");
	
		} # end of if (!-e $checkfile)

else {
$filetmp="$root_dir/${user_name}.profcon";
open(TMP,">$filetmp");
print TMP "PROF failed! Sorry, no output from PROFcon","\n";
close(TMP);
die;
        } # end of else


else {print STDOUT "PROF failed!","\n"; die;}

system("${root_dir}/COPY/PROGS/gen_nn_input.pl $user_name ${root_dir}/${user_name}-fil.hssp ${root_dir}/${user_name}-fil.rdbProf ${root_dir}/${user_name}.seg");

#system("${root_dir}/PROGS/gen_nn_input.pl $user_name ${root_dir}/${user_name}-fil.hssp ${root_dir}/${user_name}-fil.rdbProf ${root_dir}/${user_name}.seg");

        } # end of if (system ("grep \"*** No hits found 

else {print STDOUT "NO hits! run with one sequence","\n";
       system ("${root_dir}/PROGS/prof $input_fasta");
       system ("mv ${root_dir}/${user_name}.rdbProf ${root_dir}/${user_name}-fil.rdbProf");
system("${root_dir}/PROGS/gen_nn_input_SINGLE.pl $user_name $input_fasta ${root_dir}/${user_name}-fil.rdbProf ${root_dir}/${user_name}.seg");
    }


$input_hssp=${root_dir}."/".${user_name}."-fil.hssp";

####

$pos_file=$root_dir."/".${user_name}."_position.dat";
if (-e $pos_file) {
open(POS_1,"<$pos_file");

while (<POS_1>) {

(@pos)=split(/\,/,$_);

for ($ii=0; $ii<100001; $ii++) {
if (not defined $pos[$ii]) {last;}
else {
$iterations=$ii;
$position[$ii+1]=$pos[$ii];
		} # end of else
	} # end of for ($ii=0; $ii<100001; $ii++)

                        } # end of while (<POS_1>)
close(POS_1);
                                } # end of if (-e $pos_file)

$iterations=$iterations+1;

#system("rm ${root_dir}/${user_name}_position.dat");

for ($ii=1; $ii<($iterations+1); $ii++) {

system("${root_dir}/PROGS/titles.pl $user_name $position[$ii]");

system("cat ${root_dir}/${user_name}_TEST_${ii}.sample_all >> ${root_dir}/${user_name}_TEST_TITLE.sample_all");

system("mv ${root_dir}/${user_name}_TEST_TITLE.sample_all ${root_dir}/${user_name}.sample_all");

$samples=$root_dir."/".${user_name}.".sample_all";
open(SAM,">>$samples");
print SAM "//","\n";
close(SAM);


#system("rm ${root_dir}/${user_name}_TEST.sample_all");
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

#system("cat ${root_dir}/out_${user_name}_${ii} >> ${root_dir}/tmp_out_${user_name}");


#### FILTER NN OUTPUT  #######

system("${root_dir}/PROGS/filter.pl $user_name");

system("rm ${root_dir}/out_${user_name}");


####  ORDER FILTERED OUTPUT PREDICTIONS ####

system("${root_dir}/PROGS/order_2007.pl $user_name $input_fasta $ii");

system("rm ${root_dir}/out-fil_${user_name}");

        } # end of for ($ii=1; $ii<($iterations+2); $ii++)



for ($ii=1; $ii<($iterations+1); $ii++) {

open(DAT,"<${root_dir}/${user_name}_${ii}.dat");

while(<DAT>) {

($nn1,$nn2,$nn3,$nn4,$nn5)=split(/\s+/,$_); chomp($nn5);

if (exists $score{$nn1.",".$nn2.",".$nn3.",".$nn4}) {print "ERROR","\n"; print $_; die;}
else {$score{$nn1.",".$nn2.",".$nn3.",".$nn4}=$nn5;}

		} # end of while(<DAT>)

	} # end of for ($ii=1; $ii<($iterations+2); $ii++)


$newdat=${root_dir}."/".${user_name}.".dat";
open(NEW_DAT,">$newdat");

foreach $score_key (sort { $score{$b} <=> $score{$a} } keys %score) {

($nn1,$nn2,$nn3,$nn4)=split(/\,/,$score_key);

print NEW_DAT $nn1,"\t",$nn2,"\t",$nn3,"\t",$nn4,"\t",$score{$score_key},"\n";

		} # end of foreach $score_key (sort { $score{$b} <=> $score{$a} } keys %score)



#### WRITE OUTPUT PREDICTIONS IN THE EVA FORMAT ##############


system("${root_dir}/PROGS/format_CASP.pl $user_name_true $user_name $input_fasta");


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

##while (<STD>) {print $_;}

#system("rm $root_dir/${user_name}.profcon 2>>$root_dir/log.err");

#system("mv $root_dir/${user_name}.profcon $root_dir/PROFcon_${user_name}  2>>$root_dir/log.err");

#system("rm $root_dir/${user_name}.profcon 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.sample_all 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}_NUMB_all.dat 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.dat 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}-fil.hssp 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.hssp 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}-fil.rdbProf 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.saf 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.fasta 2>>$root_dir/log.err");

system("rm $root_dir/${user_name}.blastpgp 2>>$root_dir/log.err");



####### END #######


####### END #######


####### END #######


####### END #######

