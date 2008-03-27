#!/usr/bin/perl -w
##!/usr/local/bin/perl -w
$mode=1;
if (@ARGV<1)  {
	die "\nUsage: $0 [fasta] [prof] [hssp] [output_file] [window] [mode] [target_name]\n";
	}
$seq_file=$ARGV[0];
$rdbProf_file=$ARGV[1];
$hssp_file=$ARGV[2];
$output_file=$ARGV[3];
$wind_size=$ARGV[4];
$mode=$ARGV[5];
$target_name=$ARGV[6];

$dir = "/nfs/data5/users/ppuser/server/pub/profbval";
$createDataFile_exe = "$dir/createDataFile.pl";
$profBval_exe = "$dir/PROFbval.pl";


print "perl $createDataFile_exe $seq_file $rdbProf_file $hssp_file\n";
system ("perl $createDataFile_exe $seq_file $rdbProf_file $hssp_file ");
print "perl $profBval_exe $seq_file $output_file $wind_size $mode $target_name\n";
system ("perl $profBval_exe $seq_file $output_file $wind_size $mode $target_name");
