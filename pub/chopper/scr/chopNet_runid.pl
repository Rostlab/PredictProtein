#!/usr/bin/perl -w

#============================================================
# take files containing chain lists, write NN files for input and output vector
#===============================================================

use lib '/nfs/data5/users/ppuser/server/pub/chopper/scr/lib';
use Getopt::Long;
use libGenome;
use libPHD qw(getLenPHD);
				# default options
$opt_help = '';
$opt_debug = 0;


#$dir_scr = $0;
#$dir_scr =~ s/[^\/]+$//g;

$dir_package = '/nfs/data5/users/ppuser/server/pub/chopper/';
$dir_package .= '/' if ( $dir_package !~ /\/$/ );
$dir_scr = $dir_package.'scr/';
$dir_bin = $dir_package.'bin/';
$dir_etc = $dir_package.'etc/';

$scr_prof2split = $dir_scr.'prof2split_domain.pl';
$scr_vector = $dir_scr."get_nn_vector.pl";
$scr_sample = $dir_scr."writeSam4val.pl";
$scr_par = $dir_scr."writeParFile4prot.pl";
$scr_report = $dir_scr."write_report_per_protein.pl";
$scr_process = $dir_scr."post_process_nn.pl";
$scr_process_2domain = $dir_scr."post_process_nn_2domain2.pl";
$binNN = $dir_bin."domainNet.LINUX";

$ext_domain = '.info';
$dir_out = './';

$file_in{'jct'} = $dir_etc.'chopnet.jct';
$file_in{'opt'} = $dir_etc.'opt_vector';

@files_in= qw(jct opt prof hssp);

$nodeOut = 2;			# two output nodes

$Lok = GetOptions ('debug!' => \$opt_debug,
		   'jct=s' => \$file_in{'jct'},
		   'opt=s' => \$file_in{'opt'},
		   'prof=s' => \$file_in{'prof'},
		   'hssp=s' => \$file_in{'hssp'},
		   'o=s'    => \$file_result,
		   'domain=i' => \$domain_known,
                   'extDomain=s' => \$ext_domain,
		   'nodeOut=i' => \$nodeOut,
		   'dirOut=s' => \$dir_out,
		   'h'  => \$opt_help,
		   );

if ( ! $Lok ) {
    print STDERR "Invalid arguments found, -h or --help for help\n";
    exit(1);
}

$nameScr = $0;
$nameScr =~ s/.*\///g;

if ( $opt_help ) {
    print STDERR
	"$nameScr: run ChopNet for a protein \n",
	"Usage: $nameScr [options] -opt opt_file -jct jct_file -prof prof_file -hssp hssp_file\n",
	"  Opt:  -h             print this help\n",
	
	"        --(no)debug    print debug info(default=nodebug)\n";
    exit(1);
}

foreach $in ( @files_in ) {
    if ( ! $file_in{$in} ) {
	print STDERR 
	    "input file for $in not defined, abort..\n",
	    "try $nameScr -h for help\n";
	
	exit(1);
    }
    if ( ! -f $file_in{$in} or ! -s $file_in{$in} ) {
	print STDERR
	    "input file $file_in{$in} for $in not found or empty, abort..\n",
	    "try $nameScr -h for help\n";
	exit(1);
    }
}


$dir_out .= '/' if ( $dir_out !~ /\/$/ );

if ( defined $domain_known and $domain_known == 2 ) {
    $scr_process = $scr_process_2domain;
    print STDERR
	"query known as a 2-domain protein, using '$scr_process'\n";
}


				# end of option/sanity check




($ctNodeIn,$ctNodeHid,$ctNodeOut,$epsilon,$alpha) = &rdJct($file_in{'jct'});

if ( $ctNodeOut != $nodeOut ) {
    print STDERR
	"*** conflict: output node=$nodeOut, from JCT file=$ctNodeOut\n";
    exit(1);
}

$id = $file_in{'prof'};
$id =~ s/.*\///g;
$id =~ s/\..*//g;

$file_splitdomain = $dir_out.$id.'.splitdomain';
$file_sam2pos = $dir_out.$id.'.sam2pos';
$file_vector_in = $dir_out.$id.'.vector_in';
$file_vector_out = $dir_out.$id.'.vector_out';
$file_sample = $dir_out.$id.'.sample';
$file_err = $dir_out.$id.'.err';
$file_par = $dir_out.$id.'.par';
$file_nn_out = $dir_out.$id.'.nn_out';
$file_nn_err = $dir_out.$id.'.nn_err';
$file_report = $dir_out.$id.'.report';
$file_result = $dir_out.$id.'.domain' if ( ! $file_result );

push @tmp_files,$file_splitdomain,$file_sam2pos,$file_vector_in,
    $file_vector_out,$file_sample,$file_err,$file_par,$file_nn_out,
    $file_nn_err,$file_report,'NNo_tst_err.dat','nn_train.jct_tmpprot',
    'NNo-yeah.tmp';


    				# list file contains only this ID
#open (LIST,">$file_list") or die "cannot write to $file_list:$!";
#print LIST $id,"\n";
#close LIST;

				# convert PROF RDB file into 'split_domain' file
$cmd_prof2split = "$scr_prof2split -i $file_in{'prof'} -o $file_splitdomain";
print STDERR $cmd_prof2split,"\n" if ( $opt_debug );
system $cmd_prof2split;
if ( ! -s $file_splitdomain ) {
    print STDERR
	"after executing '$cmd_prof2split', one of the output file not found, abort..\n";
    die;
}


    				# write vector files
$cmd_vector = "$scr_vector -opt $file_in{'opt'} -hssp $file_in{'hssp'} -pred $file_splitdomain -i $file_vector_in -o $file_vector_out -pos $file_sam2pos > $file_err 2>&1 ";
print STDERR "$cmd_vector\n" if ( $opt_debug );
system $cmd_vector;
if ( ! -f $file_vector_in or ! -f $file_vector_out or ! -f $file_sam2pos ) {
    print STDERR
	"after executing '$cmd_vector', one of the output file not found, abort..\n";
    die;
}

# write sample file
$cmd_sample = "$scr_sample -i $file_vector_out -o $file_sample";
print STDERR "$cmd_sample\n" if ( $opt_debug );
system $cmd_sample;
if ( ! -f $file_sample ) {
    print STDERR
	"after executing '$cmd_sample', sample file $file_sample not found, abort..\n";
    die;
}

    				# write NN par file
$ct_sample = `wc -l $file_sam2pos`;
$ct_sample =~ s/^\s+//g;
$ct_sample =~ s/\s+.*//g;
$cmd_par = "$scr_par -inNode $ctNodeIn -hid $ctNodeHid -ep $epsilon -alpha $alpha  -ctSample $ct_sample -valid -dirOut $dir_out -fileInIn $file_vector_in -fileInOut $file_vector_out -fileInJct $file_in{'jct'} -fileOut $file_nn_out -filePar $file_par -fileSample $file_sample ";
print STDERR "$cmd_par\n" if ( $opt_debug );
system $cmd_par;
if ( ! -f $file_par ) {
    print STDERR
	"after executing '$cmd_par', par file $file_par not found, abort..\n";
    die;
}
    
    				# run NN
$cmdNN = "$binNN $file_par >$file_nn_err";
print STDERR "$cmdNN\n" if ( $opt_debug );
system $cmdNN;
if ( ! -f $file_nn_out ) {
    print STDERR 
	"after executing '$cmdNN', $file_nn_out not found, abort..\n";
    exit(1);
}

    				# generate report for the protein
$cmd_report = "$scr_report -obs $file_vector_out -pred $file_nn_out -pos $file_sam2pos -o $file_report";
print STDERR "$cmd_report\n" if ( $opt_debug );
system $cmd_report;
if ( ! -f $file_report ) {
    print STDERR
	"after executing '$cmd_report', $file_report not found, abort..\n";
    exit(1);
}

				# postprocessing and report

$prot_len = &getLenPHD($file_in{'prof'});
if ( ! $prot_len ) {
    print STDERR "Length from prof file not defined or zero, abort..\n";
    exit(1);
}
$cmd_process = "$scr_process -i $file_report -l $prot_len -o $file_result";
print STDERR "$cmd_process\n" if ( $opt_debug );
system $cmd_process;
if ( ! -f $file_result ) {
    print STDERR
	"after executing '$cmd_process', $file_result not found, abort..\n";
    exit(1);
}


if ( ! $opt_debug ) {
    foreach $file ( @tmp_files ) {
	unlink $file;
    }
}

exit;



sub rdJct {
    my ( $file ) = @_;
    my $sbr = "rdJct";
    my $fh = "FH_$sbr";
    my ($entries,$ctNode,$ctNodeHid,$ctNodeOut,$e,$a);
    open ( $fh, $file ) or die "cannot open $file:$!";
    while ( <$fh> ) {
	if ( /^\*\s+NUMIN, -HID, -OUT(.*)$/ ) {
	    $entries = $1;
	    $entries =~ s/\s+//g;
	    ($ctNode,$ctNodeHid,$ctNodeOut) = split /,/,$entries;
	    next;
	}
	if ( /^\*\s+EPSILON, ALPHA, TEMP(.*)$/ ) {
	    $entries = $1;
	    $entries =~ s/\s+//g;
	    ($e,$a) = split /,/,$entries;
	    last;
	}
    }
    close $fh;
    return ($ctNode,$ctNodeHid,$ctNodeOut,$e,$a);
}


sub read_opt {
    my ( $file ) = @_;
    my $opt;

    return if ( ! -s $file );
    chomp($opt = `cat $file`);

    return $opt;
}
