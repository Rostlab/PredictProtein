#!/usr/bin/perl
use Cwd;
use File::Copy;
if (@ARGV<1)  {
	die "\nUsage: $0 [fasta]\n";
	}
$file=$ARGV[0];
$fileroot= $file;
$fileroot=~ s/\.f//;
$fasta=$file;
$blastpgp="$fileroot" . ".blastpgp";
$hssp= "$fileroot" . ".hssp";
$saf=  "$fileroot" . ".saf";
$hsspfil="$fileroot-fil.hssp";
$file1= "$fileroot-fil.rdbProf";
print "### Blasting\n";
system ("/home2/pub/molbio/blast/blastpgp -i $fasta -j 3 -d /data/blast/big -o $blastpgp ");
print "### Converting to SAF format\n";
system ("perl /home2/pub/molbio/perl/blast2saf.pl $blastpgp maxAli=3000 eSaf=1");
system ("mv *.saf saf/");
print "### Converting to HSSP format\n";
system ("/home2/rost/pub/prof/scr/copf.pl $saf hssp");
system ("mv *.hssp hssp/");
print "### Filtering HSSP file\n";
system ("/home2/rost/pub/prof/scr/hssp_filter.pl $hssp red=80");
system ("mv *.hssp hssp/");
print "### Running PROF\n";
system ("/home2/rost/pub/prof/prof $hsspfil");
print "### DONE work on $fileroot?!\n";
