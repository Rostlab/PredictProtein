#!/usr/bin/perl
##!/usr/local/bin/perl -w
$profcon_file= $ARGV[0];
$prof_file= $ARGV[1];
$prot_name= $ARGV[2];
$output_file=$ARGV[3];
$home = "/nfs/data5/users/ppuser/server";
system ("perl $home/pub/prenup/calc_energy_1seq.pl 60 $profcon_file $prof_file $prot_name");
system ("perl $home/pub/prenup/smooth_1seq.pl $prot_name 11 $output_file");
