#!/usr/bin/perl -w

#============================================================
# decompose a sequence according to:
# (1) blast against PrISM domains
# (2) HMMER against pfam
# (3) blast against SwissProt
#===============================================================


use lib '/nfs/data5/users/ppuser/server/pub/chopper/scr/lib';
use Getopt::Long;
use File::Copy;
use Storable;
use libBlast;
use libHmmer qw(isHmmer parseHmmer);
use libChopper;

				# initialization
				# set options, global variables
&ini();



$run = 0;			# run 0, original seq

				# first get the info about input
($origin,$seqLen,$seq) = &get_seq_info($file_in);
if ( ! $prot_id ) {
    $prot_id = $origin;
}

# format the input sequence and copy it to tmp dir
$seqName = $id."_r$run"."_1";
$fileSeqTmp = $dirTmp.$seqName.'.f';
&writeFragmentSeq($fileSeqTmp,$seqName,$origin,0,1,$seqLen,'unchecked',$seq);
print $fhTrace
    "w) writing 1-$seqLen part of original seq to $seqName\n";
if ( $opt_debug ) {
    print STDERR
	"w) writing 1-$seqLen part of original seq to $seqName\n";
}
push @toDelete,$fileSeqTmp;

				# chop by blast against prism
				# 
$ctSeq = 1;

if ( $opt_run_pdb ) {
    ($run,$ctSeq) = &chopByBlast($run,$ctSeq,$dbBlastPDB);
    print $fhTrace
	"P) after blast PDB domains: run_number=$run, out_seq=$ctSeq\n";
    if ( $opt_debug ) {
	print STDERR
	    "P) after blast PDB domains: run_number=$run, out_seq=$ctSeq\n";
	
    }
}

				# chop by HMMER against CATH
if ( $opt_run_cathhmm ) {
    ($run,$ctSeq) = &chopByCath($run,$ctSeq,$hmm_cath);
    if ( $opt_debug ) {
	print STDERR
	    "P) after CATH HMMs: run_number=$run, out_seq=$ctSeq\n";
    }
}


				# chop by HMMER against Pfam
				# first global, then local

if ( $opt_run_pfamGlobal ) {
    ($run,$ctSeq) = &chopByPfam($run,$ctSeq,'global');
    if ( $opt_debug ) {
	print STDERR
	    "P) after Pfam global: run_number=$run, out_seq=$ctSeq\n";
    }
}

if ( $opt_run_pfamLocal ) {
    ($run,$ctSeq) = &chopByPfam($run,$ctSeq,'local');
    print $fhTrace
	"P) after Pfam local: run_number=$run, out_seq=$ctSeq\n";
    if ( $opt_debug ) {
	print STDERR
	    "P) after Pfam local: run_number=$run, out_seq=$ctSeq\n";
    }
}

				# chop by BLAST against SWISSPROT

if ( $opt_run_swiss ) {
    ($run,$ctSeq) = &chopByBlast($run,$ctSeq,$dbBlastSwiss);
    print $fhTrace
	"P) after blast swiss: run_number=$run, out_seq=$ctSeq\n";
    if ( $opt_debug ) {
	print STDERR
	    "P) after blast swiss: run_number=$run, out_seq=$ctSeq\n";
    }
}


				# get the fragment info from
				# final run
$chop{'domains'} = &fragSum($run,$ctSeq);
$chop{'proteinID'} = $prot_id;
$chop{'length'} = $seqLen;

&format_output(\%chop,$file_out);

				# clean up
close $fhTrace;

if ( ! $opt_debug ) {
    foreach $f ( @toDelete ) {
	unlink $f if ( -f $f );
    }
}


exit;				# END of MAIN




#===========================================================
sub ini {
#-----------------------------------------------------------
# initialization: set global variables, get command line options
#-----------------------------------------------------------

    
				# ========================
				# default options
				# ========================

    $dirBio = '/usr/pub/molbio/';
    $dir_package = '/nfs/data5/users/ppuser/server/pub/chopper/';
    $dir_package .= '/' if ( $dir_package !~ /\/$/ );

				# general options
    $opt_help = '';
    $file_in = '';
    $file_out = '';
    $format_out = 'xml';	# default output XML
    $opt_xml = 1;		# keep XML by default if other format
    $opt_debug = 0;

    $dirTmp = './';
				# specific options
    $opt_blastE = 1e-2;
    $exeBlast = $dirBio.'blast/blastpgp';
    $exeFastacmd = $dirBio.'blast/fastacmd';
    $dirBlast = $dir_package.'dbblast/';
    $opt_hmmerE = 1e-2;
    $exeHmmer = $dirBio.'bin/hmmpfam';
    $dirPfam = '/data/pfam/';
    $hmm_cath = $dirBlast.'cathv3_hmmer';

    $minDomainLen = 30;
    $minDomainCover = 0.8;
    $minFragmentLen = 10; 
    
    $opt_prismTrim = 0;
    $opt_multiChop = 0;

    $opt_run_pdb = 1;
    $opt_run_pfamLocal = 0;
    $opt_run_pfamGlobal = 1;
    $opt_run_swiss = 1;
    $opt_run_cathhmm = 1;


    $Lok = GetOptions ('debug!' => \$opt_debug,
		       'h'  => \$opt_help,
		       'i=s' => \$file_in,
		       'o=s' => \$file_out,
		       'of=s' => \$format_out,
		       'id=s' => \$prot_id,
		       'dirTmp=s' => \$dirTmp,
		       'exeBlast=s' => \$exeBlast,
		       'exeFastacmd=s' => \$exeFastacmd,
		       'dirBlast=s' => \$dirBlast,
		       'dbBlastPDB=s' => \$dbBlastPDB,
		       'exeHmmer=s' => \$exeHmmer,
		       'dirPfam=s' => \$dirPfam,
		       'pdb!' => \$opt_run_pdb,
		       'cathhmm!' => \$opt_run_cathhmm,
		       'pfamGlobal!' => \$opt_run_pfamGlobal,
		       'pfamLocal!' => \$opt_run_pfamLocal,
		       'swiss!' => \$opt_run_swiss,
		       'prismTrim!' => \$opt_prismTrim,
		       'multiChop!' => \$opt_multiChop,
		       'minDomainLen=s' => \$minDomainLen,
		       'blastE=f'     => \$opt_blastE,
		       'hmmerE=f'     => \$opt_hmmerE,
		       'minDomainCover=f' => \$minDomainCover,
		       'xml!'         => \$opt_xml, # keep xml
		       );
    
    if ( ! $Lok ) {
	print STDERR "*** ERROR: Invalid arguments found, -h for help\n";
	&usage();
	exit(1);
    }
    
    
    
    if ( $opt_help ) {
	&usage();
	exit(1);
    }
    
    if ( ! $file_in or ! $file_out ) {
	print STDERR "*** ERROR: input or output file not defined\n";
	&usage();
	exit(1);
    }
    
    if ( ! -f $file_in ) {
	print STDERR
	    "*** ERROR: input file '$file_in' not found\n";
	&usage();
	exit(1);
    }
    
    if ( ! $dirTmp ) {
	$dirTmp = './';
    }
    $dirTmp .= '/' if ( $dirTmp !~ /\/$/ );

    if ( ! -d $dirTmp or ! -w $dirTmp ) {
	print STDERR
	    "*** ERROR: tmp dir $dirTmp not found or not writable\n",
	    "please specify a tmp writable directory by --dirTmp option\n";
	exit(1);
    }
    
    if ( ! -e $exeBlast or ! -x $exeBlast ) {
	print STDERR
	    "blast executable $exeBlast not found or not executable, abort\n";
	exit(1);
    }
    if ( ! -d $dirBlast ) {
	print STDERR
	    "blast database directory $dirBlast not found, abort..\n";
	exit(1);
    }
    if ( ! -e $exeHmmer or ! -x $exeHmmer ) {
	print STDERR
	    "blast executable $exeBlast not found or not executable, abort\n";
	exit(1);
    }
    if ( ! -d $dirPfam ) {
	print STDERR
	    "Pfam database directory $dirPfam not found, abort..\n";
	exit(1);
    }

    
    if ( ! $dbBlastPDB ) {
	$dbBlastPDB = $dirBlast.'scop_cath_prism';
    }

    $dbinfo = &blastdb_info($dbBlastPDB);
    if ( ! $dbinfo or ! $dbinfo->{seq} ) {
	print STDERR
	    "blast database for PDB $dbBlastPDB not found, abort..\n";
	exit(1);
    }

    $dbBlastSwiss = $dirBlast.'swiss';
    if ( $opt_run_swiss ) {
	$dbinfo = &blastdb_info($dbBlastSwiss);
	if ( ! $dbinfo or ! $dbinfo->{seq} ) {
	    print STDERR
		"blast database for SWISSPROT $dbBlastSwiss not found, abort..\n";
	    exit(1);
	}
    }

    

				# end of option/sanity check


    if ( defined $ENV{'HOSTNAME'} ) {
	$hostName = $ENV{'HOSTNAME'};
	$hostName =~ s/\..*//g;
    } else {
	$hostName = 'host';
    }
    $jobId = $hostName."-".$$;
    $id = "TEMP-CHOP-$jobId";

				# trace file to record all debuggin message
    $fileTrace = $dirTmp.$id.'.trace';
    $fhTrace = 'TRACE';
    open ($fhTrace,">$fileTrace") or die "cannot write to $fileTrace:$!";
    push @toDelete, $fileTrace;
    
    print $fhTrace
	"Debug notation:\n",
	"E) error\n",
	"i) information\n",
	"P) progress indicator\n",
	"r) system command\n",
	"w) writing file\n\n\n",

	"i) minDomainLen=$minDomainLen\n",
	"i) minDomainCover=$minDomainCover\n",
	"i) minFragmentLen=$minFragmentLen\n",
	"i) opt_blastE=$opt_blastE\n",
	"i) opt_hmmerE=$opt_hmmerE\n\n\n";

    if ( $opt_debug ) {
	print STDERR
	    "Debug notation:\n",
	    "E) error\n",
	    "i) information\n",
	    "P) progress indicator\n",
	    "r) system command\n",
	    "w) writing file\n\n\n",

	    "i) minDomainLen=$minDomainLen\n",
	    "i) minDomainCover=$minDomainCover\n",
	    "i) minFragmentLen=$minFragmentLen\n",
	    "i) opt_blastE=$opt_blastE\n",
	    "i) opt_hmmerE=$opt_hmmerE\n\n\n";
    }
    
}				# END of SUB ini

sub blastdb_info {
    my ( $db ) = @_;
    my ( $job_id,$file_dbinfo,$cmd_dbinfo,$line,$fh,$dbname );

    if ( ! -s $exeFastacmd or ! -x $exeFastacmd ) {
	print STDERR "*** fastacmd executable $exeFastacmd not found\n";
	return undef;
    }

    my $info = { };

    $info->{seq} = 0;
    $info->{letter} = 0;

    $job_id = $ENV{HOSTNAME}."_$$";

    $dbname = $db;
    $dbname =~ s/.*\///;
    $file_dbinfo = $dirTmp.$dbname."_".$job_id.".dbinfo";

    $cmd_dbinfo = $exeFastacmd. " -I -d $db -o $file_dbinfo 2>/dev/null";
    system $cmd_dbinfo;
    if ( ! -s $file_dbinfo ) {
	print STDERR "after $cmd_dbinfo, $file_dbinfo not found\n";
	return $info;
    }

    open ($fh,$file_dbinfo) or warn "cannot open $file_dbinfo:$!";
    while ($line=<$fh>) {
        $line =~ s/,//g;
        if ( $line =~ /^\s+(\d+) sequences; (\d+) total letters/ ) {
            $info->{seq} = $1;
            $info->{letter} = $2;
            last;
        }
    }
    close $fh;

    unlink $file_dbinfo if ( ! $opt_debug );
    return $info;
}    


#===================================================================
sub chop {
    my ( $fileIn,$runNo, $ctSeq, $method, $db, $info ) = @_;
    my ( $ctSeqOut,$seq,@tmp,$len,$origin,$pos,$status );
    my ( $oriStart,$oriEnd,$offset,$homo,$homoStart,$homoEnd );
    my ( $queryStart,$queryEnd,$expect,$fragLen,$newStatus );
    my ( $seqName,$homoInfo,$ctSeqOutTotal );
    my ( $nameSub,$fhIn_sub);

#------------------------------------------------------------------			
# chop sequence apart according to 
# BLAST or HMMER
#-----------------------------------------------------------------
    
    $nameSub = 'chop';
    $fhIn_sub = $nameSub."_IN";	# local file handle

				# number of output sequences
				# ctSeqOutTotal includes those short unreported ones
    $ctSeqOut = 0;
    $ctSeqOutTotal = 0;
				# read the master sequence info
    open ($fhIn_sub, $fileIn) or die "cannot open $fileIn:$!";
    $seq = "";
    while (<$fhIn_sub>) {
	if ( /^\s*\>/ ) {
	    chomp;
	    @tmp = split/\t+/;
	    ($len,$origin,$pos,$status) = @tmp[1..4];
	    ($oriStart,$oriEnd) = split /-/,$pos;
	    next;
	}
	s/\s+//g;
	$seq .= $_;
    }
    close $fhIn_sub;

				# offset between original sequence 
				# and the master sequence
    $offset = $oriStart - 1;


				# info about split
				# eValue, postition of query and homologue
    if ( $method eq 'BLAST' ) {
	$homo = $info->{'nameLine'};
	$homo =~ s/\s+.*//g;
	$homo =~ s/.*\|//g;
	$homoStart = $info->{'subjStart'};
	$homoEnd = $info->{'subjEnd'};
	$queryStart = $info->{'queryStart'};
	$queryEnd = $info->{'queryEnd'};
	$expect = $info->{'expect'};
    } elsif ( $method eq 'HMMER' ) {
	$homo = $info->{'model'};
	$homoStart = $info->{'hmm_f'};
	$homoEnd = $info->{'hmm_t'};
	$queryStart = $info->{'seq_f'};
	$queryEnd = $info->{'seq_t'};
	$expect = $info->{'expect'};
    } else {
	print STDERR
	    "unknown method '$method', should be blast|pfam..\n";
	print $fhTrace
	    "unknown method '$method', should be blast|pfam..\n";
	die;
    }



    print $fhTrace
	"i) chopping $fileIn..\n",
	"i) master sequence: $oriStart-$oriEnd\n",
	"i) offset: $offset\n",
	"i) processed part: $queryStart-$queryEnd\n";
    if ( $opt_debug ) {
	print STDERR
	    "i) chopping $fileIn..\n",
	    "i) master sequence: $oriStart-$oriEnd\n",
	    "i) offset: $offset\n",
	    "i) processed part: $queryStart-$queryEnd\n";
    }


				

				# preceeding fragment
    $ctSeqOutTotal++;
    $fragLen = $queryStart - 1;
    if ( $fragLen > $minFragmentLen ) {
	$newStatus = "unchecked";
	$ctSeq++;
	$ctSeqOut++;
	
	$seqName = $id."_r$runNo"."_$ctSeq";
	$fileSeqTmp = $dirTmp.$seqName.'.f';
	&writeFragmentSeq($fileSeqTmp,$seqName,$origin,$offset,1,$queryStart-1,$newStatus,$seq);
	print $fhTrace
	    "w) writing part of original seq to $seqName\n";
	if ( $opt_debug ) {
	    print STDERR
		"w) writing part of original seq to $seqName\n";
	}
	push @toDelete,$fileSeqTmp;
    }
	
				# processed fragment
    $ctSeq++;
    $ctSeqOut++;
    $ctSeqOutTotal++;
    $seqName = $id."_r$runNo"."_$ctSeq";
    $homoInfo = $homo."($expect,$homoStart-$homoEnd)";
    $newStatus = 'final'."\t$method".'/'.$db;
    
    $newStatus .= "\t$homoInfo";
    $fileSeqTmp = $dirTmp.$seqName.'.f';
    &writeFragmentSeq($fileSeqTmp,$seqName,$origin,$offset,$queryStart,$queryEnd,$newStatus,$seq);
    print $fhTrace
	"w) writing part of original seq to $seqName\n";
    if ( $opt_debug ) {
	print STDERR
	    "w) writing part of original seq to $seqName\n";
    }
    push @toDelete,$fileSeqTmp;


				# following fragment
    $fragLen = $len - $queryEnd;
    $ctSeqOutTotal++;
    if ( $fragLen > $minFragmentLen ) {
	$newStatus = "unchecked";
	$ctSeq++;
	$ctSeqOut++;
	$seqName = $id."_r$runNo"."_$ctSeq";
	$fileSeqTmp = $dirTmp.$seqName.'.f';
	&writeFragmentSeq($fileSeqTmp,$seqName,$origin,$offset,$queryEnd+1,$len,$newStatus,$seq);
	print $fhTrace
	    "w) writing part of original seq to $seqName\n";
	if ( $opt_debug ) {
	    print STDERR
		"w) writing part of original seq to $seqName\n";
	}
	push @toDelete,$fileSeqTmp;

    }

    return(1,$ctSeqOut,$ctSeqOutTotal,"ok");
				
}				# END of SUB chop

#============================================================
sub chopByBlast {		
    my ($runNo,$ctSeqIn,$dbBlast) = @_;
    my ($ctSeq,$ctSeqNext,$ctSeqNextTotal,$seqName,$fileSeq,$fileBlast);
    my ($seqNameNext,$fileSeqNext,$Lok,$errMsg,$bestHsp,$ctSeqOut,$db);
#-------------------------------------------------------------
# chopByBlast: run BLAST
# pick best HSP, then chop
# ------------------------------------------------------------
    

    $ctSeq = $ctSeqIn;
				# first clear off all temp "checked"
				# mark from the last run
    for $i ( 1..$ctSeq ) {
	$seqName = $id."_r$runNo"."_$i";
	$fileSeq = $dirTmp.$seqName.".f"; 
	&markChecked($fileSeq,0);
    }

    while (1) {
	$nextRun = $runNo +1;
				# counter for sequences of next run
				# ctSeqNextTotal includes those short unreported ones
	$ctSeqNext = 0;
	$ctSeqNextTotal = 0;
	for $i ( 1..$ctSeq ) {
	    $seqName = $id."_r$runNo"."_$i";
	    $fileSeq = $dirTmp.$seqName.".f"; 
	    $fileBlast = $dirTmp.$seqName.'.blast';

				# if the sequence has already been processed 
				# or too short(shorter than minDomainLen)
				# just copy it to next run
	    if ( ! &toProcess($fileSeq) ) {
		print $fhTrace
		    "i) $fileSeq processed or too short, skip..\n";
		if ( $opt_debug ) {
		    print STDERR 
			"i) $fileSeq processed or too short, skip..\n";
		}
		$ctSeqNext++;
		$ctSeqNextTotal++;
		$seqNameNext = $id."_r$nextRun"."_$ctSeqNext";
		$fileSeqNext = $dirTmp.$seqNameNext.'.f';
		copy($fileSeq,$fileSeqNext) or die "copy failed: $!";
		push @toDelete, $fileSeqNext;
		next;
	    }

	    ($Lok,$errMsg) = &runBlast($seqName, $dbBlast);
	    if ( $dbBlast =~ /swiss/i ) { 
		$bestHsp = &pickHsp($fileBlast);
	    } else {
		$bestHsp = &pickHspPDB($fileBlast);
	    }
	    if ( ! $bestHsp ) {	# no hits from BLAST, copy
		print $fhTrace
		    "i) No blast hits found for $fileSeq against $dbBlast, skip..\n";
		if ( $opt_debug ) {
		    print STDERR 
			"i) No blast hits found for $fileSeq against $dbBlast, skip..\n";
		}
		$ctSeqNext++;
		$ctSeqNextTotal++;
		$seqNameNext = $id."_r$nextRun"."_$ctSeqNext";
		$fileSeqNext = $dirTmp.$seqNameNext.'.f';
		copy($fileSeq,$fileSeqNext) or die "copy failed: $!";
		&markChecked($fileSeqNext,1);
		push @toDelete, $fileSeqNext;
		next;
	    }

	    print $fhTrace
		"i) blast hits found for $fileSeq: ",
		$bestHsp->{'queryStart'},"-",
		$bestHsp->{'queryEnd'},"\n";

	    if ( $opt_debug ) {
		print STDERR
		    "i) blast hits found for $fileSeq: ",
		    $bestHsp->{'queryStart'},"-",
		    $bestHsp->{'queryEnd'},", ",$bestHsp->{nameLine},"\n";
	    }
				# hit found, chop
	    $db = $dbBlast;
	    $db =~ s/.*\///g;
#	    if ( $db =~ /prism/i ) {
#		$db = $bestHsp->{subjId};
	    $db = $bestHsp->{nameLine};
	    $db =~ s/\|.*//g;
#	    }
	    ($Lok,$ctSeqOut,$ctSeqOutTotal,$errMsg) = 
		&chop($fileSeq,$nextRun,$ctSeqNext,'BLAST',$db,$bestHsp);
	    $ctSeqNext += $ctSeqOut;
	    $ctSeqNextTotal = $ctSeqNext + $ctSeqOutTotal;
	}

				# if number of sequences remain unchanged
				# stop the iteration
	if ( $ctSeqNextTotal != $ctSeq ) {
	    $runNo = $nextRun;
	    $ctSeq = $ctSeqNext;
	} else {
	    last;
	}
    }
    
    return($runNo,$ctSeq);
				
}				# END of SUB chopByBlast


#===========================================================
sub chopByCath {
    my ($runNo,$ctSeqIn,$hmm) = @_;
    my ($ctSeq,$ctSeqNext,$ctSeqNextTotal,$seqName,$fileSeq,$fileBlast);
    my ($seqNameNext,$fileSeqNext,$Lok,$errMsg,$bestHsp,$ctSeqOut);
#-----------------------------------------------------------

    $optHmmer = " --cpu 1 ";
    $ctSeq = $ctSeqIn;
    				# first clear off all temp "checked"
				# mark from the last run
    for $i ( 1..$ctSeq ) {
	$seqName = $id."_r$runNo"."_$i";
	$fileSeq = $dirTmp.$seqName.".f"; 
	&markChecked($fileSeq,0);
    }
				
    while (1) {
	$nextRun = $runNo +1;
				# counter for sequences of next run
				# ctSeqNextTotal includes those short unreported ones
	$ctSeqNext = 0;
	$ctSeqNextTotal = 0;
	for $i ( 1..$ctSeq ) {
	    $seqName = $id."_r$runNo"."_$i";
	    $fileSeq = $dirTmp.$seqName.".f"; 
	    $fileout_cathhmm = $dirTmp.$seqName.".cath_hmm";

				# if the sequence has already been processed 
				# or too short(shorter than minDomainLen)
				# just copy it to next run
	    if ( ! &toProcess($fileSeq) ) {
		print $fhTrace
		    "i) $fileSeq processed or too short, skip..\n";
		if ( $opt_debug ) {
		    print STDERR 
			"i) $fileSeq processed or too short, skip..\n";
		}
		$ctSeqNext++;
		$ctSeqNextTotal++;
		$seqNameNext = $id."_r$nextRun"."_$ctSeqNext";
		$fileSeqNext = $dirTmp.$seqNameNext.'.f';
		copy($fileSeq,$fileSeqNext) or die "copy failed: $!";
		push @toDelete, $fileSeqNext;
		next;
	    }

	    #($Lok,$errMsg) = &runHm($seqName,$mode);

	    $cmdHmmer = "$exeHmmer $optHmmer $hmm $fileSeq > $fileout_cathhmm ";
	    print $fhTrace "r) $cmdHmmer\n";
	    if ( $opt_debug ) {
		print STDERR "r) $cmdHmmer\n";
	    }

	    system $cmdHmmer and die "failed Hmmer:$!";
	    push @toDelete, $fileout_cathhmm;

	    $bestHmm = &pickHmm($fileout_cathhmm);
	    if ( ! $bestHmm ) {
		print $fhTrace
		    "i) No CATH hits found for $fileSeq, skip..\n";
		if ( $opt_debug ) {
		    print STDERR 
			"i) No CATH hits found for $fileSeq, skip..\n";
		}
		$ctSeqNext++;
		$ctSeqNextTotal++;
		$seqNameNext = $id."_r$nextRun"."_$ctSeqNext";
		$fileSeqNext = $dirTmp.$seqNameNext.'.f';
		copy($fileSeq,$fileSeqNext) or die "copy failed: $!";
		&markChecked($fileSeqNext,1);
		push @toDelete, $fileSeqNext;
		next;
	    }
	    
	    print $fhTrace
		"i) CATH HMM hits found for $fileSeq: ",
		$bestHmm->{'seq_f'},"-",
		$bestHmm->{'seq_t'},"\n";
	    if ( $opt_debug ) {
		print STDERR
		    "i) CATH HMM hits found for $fileSeq: ",
		    $bestHmm->{'seq_f'},"-",
		    $bestHmm->{'seq_t'},"\n";
	    }

	    ($Lok,$ctSeqOut,$ctSeqOutTotal,$errMsg) = 
		&chop($fileSeq,$nextRun,$ctSeqNext,'HMMER','cath_hmm',$bestHmm);
	    $ctSeqNext += $ctSeqOut;
	    $ctSeqNextTotal = $ctSeqNext + $ctSeqOutTotal;
	}
	if ( $ctSeqNextTotal != $ctSeq ) {
	    $runNo = $nextRun;
	    $ctSeq = $ctSeqNext;
	} else {
	    last;
	}
    }
				
    return($runNo,$ctSeq);
}				# END of SUB chopByPfam


#===========================================================
sub chopByPfam {
    my ($runNo,$ctSeqIn,$mode) = @_;
    my ($ctSeq,$ctSeqNext,$ctSeqNextTotal,$seqName,$fileSeq,$fileBlast);
    my ($seqNameNext,$fileSeqNext,$Lok,$errMsg,$bestHsp,$ctSeqOut);
    my ($dbPfam);
#-----------------------------------------------------------

    $ctSeq = $ctSeqIn;
    				# first clear off all temp "checked"
				# mark from the last run
    for $i ( 1..$ctSeq ) {
	$seqName = $id."_r$runNo"."_$i";
	$fileSeq = $dirTmp.$seqName.".f"; 
	&markChecked($fileSeq,0);
    }

    if ( $mode eq 'global' ) {
	$dbPfam = 'Pfam_ls';
    } elsif ( $mode eq 'local' ) {
	$dbPfam = 'Pfam_fs';
    }
				
    while (1) {
	$nextRun = $runNo +1;
				# counter for sequences of next run
				# ctSeqNextTotal includes those short unreported ones
	$ctSeqNext = 0;
	$ctSeqNextTotal = 0;
	for $i ( 1..$ctSeq ) {
	    $seqName = $id."_r$runNo"."_$i";
	    $fileSeq = $dirTmp.$seqName.".f"; 
	    $filePfam = $dirTmp.$seqName.".pfam_$mode";

				# if the sequence has already been processed 
				# or too short(shorter than minDomainLen)
				# just copy it to next run
	    if ( ! &toProcess($fileSeq) ) {
		print $fhTrace
		    "i) $fileSeq processed or too short, skip..\n";
		if ( $opt_debug ) {
		    print STDERR 
			"i) $fileSeq processed or too short, skip..\n";
		}
		$ctSeqNext++;
		$ctSeqNextTotal++;
		$seqNameNext = $id."_r$nextRun"."_$ctSeqNext";
		$fileSeqNext = $dirTmp.$seqNameNext.'.f';
		copy($fileSeq,$fileSeqNext) or die "copy failed: $!";
		push @toDelete, $fileSeqNext;
		next;
	    }

	    ($Lok,$errMsg) = &runPfam($seqName,$mode);
	    $bestHmm = &pickHmm($filePfam);
	    if ( ! $bestHmm ) {
		print $fhTrace
		    "i) No Pfam hits found for $fileSeq, skip..\n";
		if ( $opt_debug ) {
		    print STDERR 
			"i) No Pfam hits found for $fileSeq, skip..\n";
		}
		$ctSeqNext++;
		$ctSeqNextTotal++;
		$seqNameNext = $id."_r$nextRun"."_$ctSeqNext";
		$fileSeqNext = $dirTmp.$seqNameNext.'.f';
		copy($fileSeq,$fileSeqNext) or die "copy failed: $!";
		&markChecked($fileSeqNext,1);
		push @toDelete, $fileSeqNext;
		next;
	    }
	    
	    print $fhTrace
		"i) Pfam hits found for $fileSeq: ",
		$bestHmm->{'seq_f'},"-",
		$bestHmm->{'seq_t'},"\n";
	    if ( $opt_debug ) {
		print STDERR
		    "i) Pfam hits found for $fileSeq: ",
		    $bestHmm->{'seq_f'},"-",
		    $bestHmm->{'seq_t'},"\n";
	    }

	    ($Lok,$ctSeqOut,$ctSeqOutTotal,$errMsg) = 
		&chop($fileSeq,$nextRun,$ctSeqNext,'HMMER',$dbPfam,$bestHmm);
	    $ctSeqNext += $ctSeqOut;
	    $ctSeqNextTotal = $ctSeqNext + $ctSeqOutTotal;
	}
	if ( $ctSeqNextTotal != $ctSeq ) {
	    $runNo = $nextRun;
	    $ctSeq = $ctSeqNext;
	} else {
	    last;
	}
    }
				
    return($runNo,$ctSeq);
}				# END of SUB chopByPfam


sub format_output {
    my ( $pred,$file_out ) = @_ ;
    my ( $file_xml );
				# always output XML
    $file_xml = $file_out.'.xml';
    &hash2xml($pred,$file_xml);
				# output
    if ( $format_out eq 'storable' ) {
	store($pred,$file_out);
    } elsif ( $format_out eq 'xml' ) {
	move ($file_xml,$file_out) or die "cannot move $file_xml to $file_out:$!";
    } elsif ( $format_out eq 'casp' ) {
	&xml2casp($file_xml,$seq,$file_out);
    } elsif ( $format_out eq 'txt' ) {
	&xml2txt_chop($file_xml,$file_out);
    } elsif ( $format_out eq 'html' ) {
	&xml2html_chop($file_xml,$file_out);
    }

    if ( ! $opt_xml ) {
	push @toDelete, $file_xml;
    }

    return;
}


#==================================================
sub fragSum {
    my ( $run,$ctSeq ) = @_;
    my (%entry,$seqName,$fileSeq,@tmp,$domainRegion,$domain_len,@frag);
    my ( $homo, $method, $nameSub, $fhSeq_sub );
#--------------------------------------------------

    $nameSub = 'fragSum';
    $fhSeq_sub = $nameSub."_SEQ"; # local seq file handle

    undef @frag;
    for $i ( 1..$ctSeq ) {
	undef %entry;
	$seqName = $id."_r$run"."_$i";
	$fileSeq = $dirTmp.$seqName.".f"; 
	open ($fhSeq_sub,$fileSeq) or die "cannot open $fileSeq:$!";
	while (<$fhSeq_sub>) {
	    if ( /^\s*\>/ ) {
		chomp;
		@tmp = split/\t+/;
		($domainRegion,$entry{'status'}) = @tmp[3,4];
		($entry{'domainStart'},$entry{'domainEnd'}) = split /-/,$domainRegion;
		$domain_len = $entry{'domainEnd'} - $entry{'domainStart'} + 1;
		next if ( $domain_len < $minDomainLen );
		if ( $entry{'status'} eq 'final' ) {
		    ($method,$homo) = @tmp[5,6];
		    ($entry{'homoMethod'},$entry{'homoDB'}) = split /\//,$method;
		    
		    if ( $homo ne 'NULL' ) {
			$homo =~ s/\((.*),/\(/;
			$entry{'homoEvalue'} = $1;
			($entry{'homoName'},$entry{'homoRegion'}) = split /\(/, $homo;
			$entry{'homoRegion'} =~ s/\)$//;
			
		    } else {
			$entry{'homoEvalue'} = 'NULL';
		    }
		} else {
		    $entry{'homoMethod'} = 'NULL';
		    $entry{'homoName'} = 'NULL';
		    $entry{'homoEvalue'} = 'NULL';
		}
		push @frag,{%entry};
		last;
	    }
	}
	close $fhSeq_sub;
    }
    return [@frag];
}				# END of SUB fragSum


#============================================================
sub markChecked {
    my ( $fileIn,$check ) = @_;
    my ( $fileTmp,$fhIn_sub,$fhTmp_sub,$nameSub );
#------------------------------------------------------------

    $nameSub = 'markChecked';
    $fhIn_sub = $nameSub.'_IN';
    $fhTmp_sub = $nameSub.'_TMP';

    $fileTmp = $fileIn.'_tmp';

    #print "xx ?? reached here?\n";
    open ($fhIn_sub, $fileIn) or die "cannot open $fileIn:$!";
    open ($fhTmp_sub,">$fileTmp") or die "cannot write to $fileTmp:$!";
    while (<$fhIn_sub>) {
	if ( /^\s*\>/ ) {
	    if ( $check ) {
		s/\tunchecked/\tchecked/;
	    } else {
		s/\tchecked/\tunchecked/;
	    }
	}
	print $fhTmp_sub $_;
    }
    close $fhIn_sub;
    close $fhTmp_sub;
    move($fileTmp,$fileIn);
    return;
}				# END of SUB markChecked


#=============================================================
sub pickHmm {
    my ( $fileHmm ) = @_;
    my ( $bestHmm,$hmms,$hmm,$lowestE );
#-------------------------------------------------------------

    undef $bestHmm;
    #$maxQueryAlignLen = 0;

    $lowestE = $opt_hmmerE;
    $hmms = &parseHmmer($fileHmm);
    foreach $hmm ( @$hmms ) {
	next if ( $hmm->{'expect'} > $opt_hmmerE );
	
	$domainLen = $hmm->{'seq_t'} - $hmm->{'seq_f'} + 1;
	if ( $opt_debug ) {
	    print STDERR 
		"domainlen=$domainLen\n";
	}
	next if ( $domainLen < $minDomainLen );

	if ( $hmm->{'expect'} < $lowestE ) {
	    $lowestE = $hmm->{'expect'};
	    $bestHmm = $hmm;
	}
    }

    if ( defined $bestHmm ) {
	return {%$bestHmm};
    } else {
	return undef;
    }
}				# END of SUB pickHmm


#============================================================
sub pickHsp {
    my ( $fileBlast ) = @_;
    my ( $minQueryAlignLen,$hsps,$hsp,$queryAlignLen,$subjAlignLen);
    my ( $bestHsp, $domainCover );
#------------------------------------------------------------

    undef $bestHsp;
    $minQueryAlignLen = 10000;
   
    $hsps = &rdBlastHsp($fileBlast);
    foreach $hsp ( @$hsps ) {
	next if ($hsp->{'expect'} > $opt_blastE);
	$queryAlignLen = $hsp->{'queryEnd'} - $hsp->{'queryStart'} + 1;
	$subjAlignLen = $hsp->{'subjEnd'} - $hsp->{'subjStart'} + 1;
	$domainCover = $subjAlignLen/$hsp->{'subjLength'};
	if ( $opt_debug ) {
	    print STDERR 
		$hsp->{'nameLine'},': ',
		"query alignlen=$queryAlignLen, ",
		"domain coverage=$domainCover\n";
	}
	next if ( $domainCover < $minDomainCover );
	next if ( $queryAlignLen < $minDomainLen );

	if ( $queryAlignLen < $minQueryAlignLen ) {
	    $bestHsp = $hsp;
	    $minQueryAlignLen = $queryAlignLen;
	}
    }
    if ( defined $bestHsp ) {
	return {%$bestHsp};
    } else {
	return undef;
    }
}				# END of SUB pickHsp


#============================================================
sub pickHspPDB {
    my ( $fileBlast ) = @_;
    my ( %minQueryAlignLen,$hsps,$hsp,$queryAlignLen,$subjAlignLen);
    my ( %best, $bestHsp, $domainCover );
#------------------------------------------------------------

    undef $bestHsp;
    undef %best;

    %minQueryAlignLen = ( "scop" => 10000,
			  "cath" => 10000,
			  "prism" => 10000,
			  );
   
    $hsps = &rdBlastHsp($fileBlast);
    foreach $hsp ( @$hsps ) {
	next if ($hsp->{'expect'} > $opt_blastE);
	$queryAlignLen = $hsp->{'queryEnd'} - $hsp->{'queryStart'} + 1;
	$subjAlignLen = $hsp->{'subjEnd'} - $hsp->{'subjStart'} + 1;
	$domainCover = $subjAlignLen/$hsp->{'subjLength'};
	if ( $opt_debug ) {
	    print STDERR 
		$hsp->{'nameLine'},': ',
		"query alignlen=$queryAlignLen, ",
		"domain coverage=$domainCover\n";
	}
	next if ( $domainCover < $minDomainCover );
	next if ( $queryAlignLen < $minDomainLen );

	$blastdb = $hsp->{nameLine};
	$blastdb =~ s/\|.*//;
	
	if ( $queryAlignLen < $minQueryAlignLen{$blastdb} ) {
	    $best{$blastdb} = $hsp;
	    $minQueryAlignLen{$blastdb} = $queryAlignLen;
	}
    }

    if ( defined $best{scop} and defined $best{cath} ) {
	$bestHsp = ($minQueryAlignLen{scop} <= $minQueryAlignLen{cath})?
	    $best{scop}:$best{cath};
    } else {
	$bestHsp = $best{scop} || $best{cath} || $best{prism};
    }

    return $bestHsp;
}				# END of SUB pickHspPDB



#=============================================================
sub pickMultiHmm {
    my ( $fileHmm ) = @_;
    my ( $hmms,$hmm,@goodHmms,@seq,$toPick,@finalHmms);
    my ( $queryAlignLen );
#-------------------------------------------------------------


    undef @goodHmms;
    undef @seq;
    undef @finalHmms;
    $hmms = &parseHmmer($fileHmm);
				# 
				# get all models that are above the threshold
    foreach $hmm ( @$hmms ) {
	next if ( $hmm->{'expect'} > $opt_hmmerE );
	push @goodHmms, $hmm;
    }

    return undef if ( ! @goodHmms );

				# sort according to E value
    @goodHmms = sort { $a->{'expect'} <=> $b->{'expect'} } @goodHmms;

				# pick unoverlapping models
    foreach $hmm ( @goodHmms ) {
	$toPick = 1;
	for $i ( $hmm->{'seq_f'}..$hmm->{'seq_t'} ) {
	    if ( $seq[$i] ) {
		$toPick = 0;
		last;
	    }
	}

	if ( $toPick ) {
	    push @finalHmms, $hmm;
	    for $i ( $hmm->{'seq_f'}..$hmm->{'seq_t'} ) {
		$seq[$i] = 1;
	    }
	}
    }

    return [@finalHmms];
}				# END of SUB pickMultiHmm


#======================================================
sub runBlast {
    my ( $seqName, $dbBlast ) = @_;
    my ( $fileSeq,$fileBlast,$optBlast,$cmdBlast );
#------------------------------------------------------

    $fileSeq = $dirTmp.$seqName.'.f';
    $fileBlast = $dirTmp.$seqName.'.blast';
    unlink $fileBlast if ( -f $fileBlast );
    $optBlast = " -d $dbBlast ";
    $cmdBlast = "$exeBlast -i $fileSeq -o $fileBlast $optBlast ";
    print $fhTrace "r) $cmdBlast\n";
    if ( $opt_debug ) {
	print STDERR "r) $cmdBlast\n";
    }

    system $cmdBlast and die "failed blast:$!";
    push @toDelete, $fileBlast;
    if (! &isBlast($fileBlast) ) {
	return(0, "output file not found/corrupted after BLAST");
    } else {
	return(1,"ok");
    }
}				# END of SUB runBlast


#===========================================================
sub runPfam {
    my ( $seqName, $mode) = @_;
    my ( $fileSeq,$filePfam,$optHmmer,$datPfam,$cmdHmmer);
#-----------------------------------------------------------

    $fileSeq = $dirTmp.$seqName.'.f';
    $filePfam = $dirTmp.$seqName.".pfam_$mode";
    unlink $filePfam if ( -f $filePfam );
    $optHmmer = " --acc  --cpu 1 ";
    if ( $mode eq 'global' ) {
	$datPfam = $dirPfam.'Pfam_ls';
    } elsif ( $mode eq 'local' ) {
	$datPfam = $dirPfam.'Pfam_fs';
    } else {
	print STDERR "HMMER mode (global|local) not specified or not correct\n";
	die;
    }

    $cmdHmmer = "$exeHmmer $optHmmer $datPfam $fileSeq > $filePfam ";
    print $fhTrace "r) $cmdHmmer\n";
    if ( $opt_debug ) {
	print STDERR "r) $cmdHmmer\n";
    }

    system $cmdHmmer and die "failed Hmmer:$!";
    push @toDelete, $filePfam;
    if (! &isHmmer($filePfam) ) {
	return(0, "output file not found/corrupted after BLAST");
    } else {
	return(1,"ok");
    }
}				# END of SUB runPfam


#==============================================================
sub toProcess {
    my ($fileIn) = @_;
    my ($toDo,@tmp,$reg,$status,$len,$nameSub,$fhIn_sub);
#--------------------------------------------------------------

    $toDo = 1;
    $nameSub = 'toProcess';
    $fhIn_sub = $nameSub.'_IN';
    open ($fhIn_sub, $fileIn) or die "cannot open $fileIn:$!";
    while (<$fhIn_sub>) {
	if ( /^\s*\>/ ) {
	    chomp;
	    @tmp = split/\t+/;
	    ($len,$status) = @tmp[1,4];
	    if ( $status eq 'final' or $status eq 'checked' ) {
		$toDo = 0;
		last;
	    }
	    
	    if ( $len < $minDomainLen ) {
		$toDo = 0;
		last;
	    }
	}
    }
    close $fhIn_sub;
    return $toDo;
}				# END of SUB toProcess


sub usage {
    $nameScr = $0;
    $nameScr =~ s/.*\///g;
    print STDERR
	"$nameScr: CHOP protein into domains according to homology \n",
	"Usage: $nameScr [options] -i in_file -o out_file \n",
	"  Opt:  -h, --help               print this help\n",
	"        -i <file>                input file (REQUIRED)\n",
	"        -o <file>                output file (REQUIRED)\n",
	"        -of <string>,            output format (xml|casp|storable|txt|html), DEFAULT=xml\n",
	"        -id <string>,            name of the protein(DEFAULT: taken from sequence)\n",
	"        -dirTmp <directory>      tmp directory (DEFAULT=./)\n",
	"        -exeBlast <file>         BLAST executable\n",
	"        -exeFastacmd <file>      fastacmd executable\n",
	"        -dirBlast <directory>    BLAST db directory\n",
	"        -dbBlastPDB <blastdb>    blastdb for PDB (SCOP+CATH+PRISM)\n",
	"        -exeHmmer <file>         Hmmer executable\n",
	"        -dirPfam <directory>     Pfam db directory\n",
	"        -(no)pdb                 to run against PDB domains(DEFAULT=true)\n",
	"        -(no)cathhmm             to run against CATH HMMs (DEFAULT=true)\n",
	"        -(no)pfamLocal           to run pfam local alignment(DEFAULT=false)\n",
	"        -(no)pfamGlobal          to run pfam global alignment(DEFAULT=true)\n",
	"        -(no)swiss               to run against Swiss-Prot(DEFAULT=true)\n",
	"        -minDomainLen <int>      minimum length of domain to be processed at each run(DEFAULT=30)\n",
	"        -minDomainCover <double> min coverage of target to be called a hit(DEFAULT=0.8)\n",
	"        -minFragmentLen <int>    min length of fragment to be reported(DEFAULT=10)\n",
	"        -blastE <double>         blast evalue threshold(DEFAULT=$opt_blastE)\n",
	"        -hmmerE <double>         HMMER evalue threshold(DEFAULT=$opt_hmmerE)\n",

	"        -(no)debug               print debug info(DEFAULT=nodebug)\n";
    return;
}


		      
