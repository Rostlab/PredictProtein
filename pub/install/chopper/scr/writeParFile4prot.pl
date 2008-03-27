#!/usr/bin/perl -w

#============================================================
# template for scripts using Getopt.pm
#===============================================================

use Getopt::Long;

				# default options
$opt_help = '';
$opt_debug = 0;
$opt_init = 0;
$opt_valid = 0;
$dirOut = '';
$ctNodeOut = 2;
$ctNodeHid = 10;
$ctSample = 0;
$ctFileIn_in = 1;
$ctFileIn_out = 1;
$ctFileOut_out = 1;
$ctFileOut_jct = 1;
$step_swp_max = 0;
$step_max = 0;
$step_in_file = 1;
$epsilon = 0.01;
$alpha = 0.1;
$temperature = 1;

$fileIn_in = 'vector_train.in';
$fileIn_out = 'vector_train.out';
$fileIn_jct = 'nn_train.jct';
$fileIn_sam = 'sample.train';
$fileOut_out = 'nn_train.out';
$fileOut_jct = "nn_train.jct"."_tmpprot";
$fileOut_err = 'NNo_tst_err.dat';
$fileOut_yeah = 'NNo-yeah.tmp';
$filePar = "";

$Lok = GetOptions ('debug!' => \$opt_debug,
		   'filePar=s' => \$filePar,
		   'fileInIn=s' => \$fileIn_in,
		   'fileInOut=s' => \$fileIn_out,
		   'fileInJct=s' => \$fileIn_jct,
		   'fileOut=s' => \$fileOut_out,
		   'fileSample=s' => \$fileIn_sam,
		   'init!' => \$opt_init,
		   'valid!' => \$opt_valid,
		   'dirOut=s' => \$dirOut,
		   'inNode=i' => \$ctNodeIn,
		   'outNode=i' => \$ctNodeOut,
		   'hidNode=i' => \$ctNodeHid,
		   'ctSample=i' => \$ctSample,
		   'epsilon=f' => \$epsilon,
		   'alpha=f' => \$alpha,
		  
		   'temp=f' => \$temperature,
		   'help'  => \$opt_help,
		   );

if ( ! $Lok ) {
    print STDERR "Invalid arguments found, -h or --help for help\n";
    exit(1);
}

$nameScr = $0;
$nameScr =~ s/.*\///g;

if ( $opt_help ) {
    print STDERR
	"$nameScr: purpose of script \n",
	"Usage: $nameScr [options] \n",
	"  Opt:  -h, --help    print this help\n",
	"        -i <file>     input file (REQUIRED)\n",
	"        -o <file>     output file (default STDOUT)\n",
	"        --(no)debug    print debug info(default=nodebug)\n";
    exit(1);
}



#if ( ! $dirOut or ! -d $dirOut ) {
#    print STDERR
#	"output directory not defined or not found, abort..\n";
#    exit(1);
#}
#$dirOut .= '/' if ( $dirOut !~ /\/$/ );

if ( $dirOut eq './' ) {
    $dirOut = "";
} 

if ( ! $ctNodeIn ) {
    print STDERR
	"number of input node not defined, abort..\n";
    exit(1);
}
if ( ! $ctSample ) {
    print STDERR
	"number of unique samples not defined, abort..\n";
    exit(1);
}

				# end of option/sanity check




$format_string = '%-22s';
$format_int = '%8d';
$format_float = '%15.6f';
$format_free = '%s';
open (PAR, ">$filePar") or die "cannot write to $filePar:$!";
print PAR "* I8\n";
printf PAR "$format_string".": $format_int\n", "NUMIN",$ctNodeIn;
printf PAR "$format_string".": $format_int\n", "NUMHID",$ctNodeHid;
printf PAR "$format_string".": $format_int\n", "NUMOUT",$ctNodeOut;
printf PAR "$format_string".": $format_int\n", "NUMLAYERS",2;
printf PAR "$format_string".": $format_int\n", "NUMSAM",$ctSample;
printf PAR "$format_string".": $format_int\n", "NUMFILEIN_IN",$ctFileIn_in;
printf PAR "$format_string".": $format_int\n", "NUMFILEIN_OUT",$ctFileIn_out;
printf PAR "$format_string".": $format_int\n", "NUMFILEOUT_OUT",$ctFileOut_out;
printf PAR "$format_string".": $format_int\n", "NUMFILEOUT_JCT",$ctFileOut_jct;
printf PAR "$format_string".": $format_int\n", "STPSWPMAX",$step_swp_max;
printf PAR "$format_string".": $format_int\n", "STPMAX",$step_max;
printf PAR "$format_string".": $format_int\n", "STPINF",$step_in_file;
printf PAR "$format_string".": $format_int\n", "ERRBINSTOP",0;
printf PAR "$format_string".": $format_int\n", "BITACC",100;
printf PAR "$format_string".": $format_int\n", "DICESEED",100025;
printf PAR "$format_string".": $format_int\n", "DICESEED_ADDJCT",0;
printf PAR "$format_string".": $format_int\n", "LOGI_RDPARWRT",1;
printf PAR "$format_string".": $format_int\n", "LOGI_RDINWRT",0;
printf PAR "$format_string".": $format_int\n", "LOGI_RDOUTWRT",0;
printf PAR "$format_string".": $format_int\n", "LOGI_RDJCTWRT",0;

print PAR 
    "* --------------------\n",
    "* F15.6\n";
printf PAR "$format_string".": $format_float\n", "EPSILON",$epsilon;
printf PAR "$format_string".": $format_float\n", "ALPHA",$alpha;
printf PAR "$format_string".": $format_float\n", "TEMPERATURE",$temperature;
printf PAR "$format_string".": $format_float\n", "ERRSTOP",0;
printf PAR "$format_string".": $format_float\n", "ERRBIAS",0;
printf PAR "$format_string".": $format_float\n", "ERRBINACC",0.2;
printf PAR "$format_string".": $format_float\n", "THRESHOUT",0.5;
printf PAR "$format_string".": $format_float\n", "DICEITRVL",0.1;


print PAR
    "* --------------------\n",
    "* A13\n";
printf PAR "$format_string".": $format_free\n", "TRNTYPE","ONLINE";
printf PAR "$format_string".": $format_free\n", "TRGTYPE","SIG";
printf PAR "$format_string".": $format_free\n", "ERRTYPE","DELTASQ";
printf PAR "$format_string".": $format_free\n", "MODEPRED","sec";
printf PAR "$format_string".": $format_free\n", "MODENET","1st,unbal";
printf PAR "$format_string".": $format_free\n", "MODEIN","win=5,loc=aa";
printf PAR "$format_string".": $format_free\n", "MODEOUT","KN";
printf PAR "$format_string".": $format_free\n", "MODEJOB","mode_of_job";
printf PAR "$format_string".": $format_free\n", "FILEIN_IN",$fileIn_in;
printf PAR "$format_string".": $format_free\n", "FILEIN_OUT",$fileIn_out;
printf PAR "$format_string".": $format_free\n", "FILEIN_JCT",$fileIn_jct;
printf PAR "$format_string".": $format_free\n", "FILEIN_SAM",$fileIn_sam;
printf PAR "$format_string".": $format_free\n", "FILEOUT_OUT",$fileOut_out;
printf PAR "$format_string".": $format_free\n", "FILEOUT_JCT",$fileOut_jct;
printf PAR "$format_string".": $format_free\n", "FILEOUT_ERR",$fileOut_err;
printf PAR "$format_string".": $format_free\n", "FILEOUT_YEAH",$fileOut_yeah;
print PAR "//\n";
close PAR;

exit;


