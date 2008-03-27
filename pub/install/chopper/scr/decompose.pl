#!/usr/bin/perl -w

#============================================================
# decompose a sequence according to:
# (1) blast against PrISM domains
# (2) HMMER against pfam
# (3) blast against SwissProt
#===============================================================


use lib 'DIRLIB';
use Getopt::Long;
use File::Copy;
use libBlast;
use libHmmer qw(isHmmer parseHmmer);


				# initialization
				# set options, global variables
&ini();



$run = 0;			# run 0, original seq

				# first get the info about input
($origin,$seqLen,$seq) = &getSeqInfo($inFile);
&printInput($fhOut, $origin,$seqLen);

				# format the input sequence and copy it to tmp dir
$seqName = $id."_r$run"."_1";
&writeFragmentSeq($seqName,$origin,0,1,$seqLen,'unchecked',$seq);

				# chop by blast against prism
				# 
$ctSeq = 1;

if ( $opt_run_prism ) {
    ($run,$ctSeq) = &chopByBlast($run,$ctSeq,$dbBlastPrism);
    print $fhTrace
	"P) after blast PrISM: run_number=$run, out_seq=$ctSeq\n";
    if ( $opt_debug ) {
	print STDERR
	    "P) after blast PrISM: run_number=$run, out_seq=$ctSeq\n";
	
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
$fragments = &fragSum($run,$ctSeq);

				# print the fragment info
&printSum($fragments,$fhOut);

				# close file handles
close $fhOut;
close $fhTrace;

				# clean up
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
    $dir_package = 'DIRPACKAGE';
    $dir_package .= '/' if ( $dir_package !~ /\/$/ );

				# general options
    $opt_help = '';
    $inFile = '';
    $outFile = '';
    $opt_debug = 0;

    $dirOut = './';
    $dirTmp = '';
				# specific options
    $opt_blastE = 1e-2;
    $exeBlast = $dirBio.'blast/blastpgp';
    $dirBlast = $dir_package.'dbblast/';
    $opt_hmmerE = 1e-2;
    $exeHmmer = $dirBio.'bin/hmmpfam';
    $dirPfam = '/data/pfam/';

    $minDomainLen = 30;
    $minDomainCover = 0.8;
    $minFragmentLen = 10; 
    
    $opt_prismTrim = 1;
    $opt_multiChop = 0;

    $opt_run_prism = 1;
    $opt_run_pfamLocal = 0;
    $opt_run_pfamGlobal = 1;
    $opt_run_swiss = 1;

    $Lok = GetOptions ('debug!' => \$opt_debug,
		       'help'  => \$opt_help,
		       'i=s' => \$inFile,
		       'o=s' => \$outFile,
		       'dirOut=s' => \$dirOut,
		       'dirTmp=s' => \$dirTmp,
		       'exeBlast=s' => \$exeBlast,
		       'dirBlast=s' => \$dirBlast,
		       'exeHmmer=s' => \$exeHmmer,
		       'dirPfam=s' => \$dirPfam,
		       'prism!' => \$opt_run_prism,
		       'dirPfam' => \$dirPfam,
		       'pfamGlobal!' => \$opt_run_pfamGlobal,
		       'pfamLocal!' => \$opt_run_pfamLocal,
		       'swiss!' => \$opt_run_swiss,
		       'prismTrim!' => \$opt_prismTrim,
		       'multiChop!' => \$opt_multiChop,
		       'minDomainLen' => \$minDomainLen,
		       'blastE=f'     => \$opt_blastE,
		       'hmmerE=f'     => \$opt_hmmerE,
		       'minDomainCover=f' => \$minDomainCover,
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
	    "Usage: $nameScr [options] -i in_file -o out_file \n",
	    "  Opt:  -h, --help               print this help\n",
	    "        -i, --inFile <file>      input file (REQUIRED)\n",
	    "        -o, --outFile <file>     output file (default STDOUT)\n",
	    "        -dirOut <directory>      output directory (default ./)\n",
	    "        -dirTmp <directory>      tmp directory (default=dirOut)\n",
	    "        -exeBlast <file>         BLAST executable\n",
	    "        -dirBlast <directory>    BLAST db directory\n",
	    "        -exeHmmer <file>         Hmmer executable\n",
	    "        -dirPfam <directory>    Pfam db directory\n",
	    "        -minDomainLen <int>      minimum length of domain to be processed at each run(default=30)\n",
	    "        -minDomainCover <real>   min coverage of target to be called a hit(default=0.8)\n",
	    "        -minFragmentLen <int>    min length of fragment to be reported(default=10)\n",
	    "        -pfamLocal               to run pfam local alignment(DEFAULT=false)\n",
	    "        -(no)prismTrim           use trim version of prism(DEFAULT=trim)\n",
	    "        --debug or --nodebug     print debug info(default=nodebug)\n";
	exit(1);
    }
    
    if ( ! $inFile ) {
	print STDERR
	    "Usage: $nameScr [options]  \n",
	    "Try $nameScr --help for more information\n";
	exit(1);
    }
    
    if ( ! -f $inFile ) {
	print STDERR
	    "input file '$inFile' not found, exiting..\n";
	exit(1);
    }
    
    if ( ! $dirTmp ) {
	$dirTmp = $dirOut;
    }
    
    if ( ! -d $dirTmp or ! -w $dirTmp ) {
	print STDERR
	    "tmp dir $dirTmp not found or not writable\n",
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
    
    if ( $opt_prismTrim ) {
	$dbPrism = 'prism_trim';
    } else {
	$dbPrism = 'prism_notrim';
    }
    $dbBlastPrism = $dirBlast.$dbPrism;
    if ( ! -e $dbBlastPrism ) {
	print STDERR
	    "blast database for PrISM $dbBlastPrism not found, abort..\n";
	exit(1);
    }

    $dbBlastSwiss = $dirBlast.'swiss';
    if ( ! -e $dbBlastSwiss and $opt_run_swiss ) {
	print STDERR
	    "blast database for SWISSPROT $dbBlastSwiss not found, abort..\n";
	exit(1);
    }

    
    $fhOut = 'STDOUT';
    if ( $outFile ) {
	$fhOut = 'OUT';
	open ( $fhOut, ">$outFile") or die "cannot write to $outFile:$!";
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
	&writeFragmentSeq($seqName,$origin,$offset,1,$queryStart-1,$newStatus,$seq);
    }
	
				# processed fragment
    $ctSeq++;
    $ctSeqOut++;
    $ctSeqOutTotal++;
    $seqName = $id."_r$runNo"."_$ctSeq";
    $homoInfo = $homo."($expect,$homoStart-$homoEnd)";
    $newStatus = 'final'."\t$method".'/'.$db;
    
    $newStatus .= "\t$homoInfo";
    &writeFragmentSeq($seqName,$origin,$offset,$queryStart,$queryEnd,$newStatus,$seq);

				# following fragment
    $fragLen = $len - $queryEnd;
    $ctSeqOutTotal++;
    if ( $fragLen > $minFragmentLen ) {
	$newStatus = "unchecked";
	$ctSeq++;
	$ctSeqOut++;
	$seqName = $id."_r$runNo"."_$ctSeq";
	&writeFragmentSeq($seqName,$origin,$offset,$queryEnd+1,$len,$newStatus,$seq);
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
	    $bestHsp = &pickHsp($fileBlast);
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
		    $bestHsp->{'queryEnd'},"\n";
	    }
				# hit found, chop
	    $db = $dbBlast;
	    $db =~ s/.*\///g;
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



#==================================================
sub fragSum {
    my ( $run,$ctSeq ) = @_;
    my (%entry,$seqName,$fileSeq,@tmp,@frag);
    my ( $nameSub, $fhSeq_sub );
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
		($entry{'region'},$entry{'status'}) = @tmp[3,4];
		if ( $entry{'status'} eq 'final' ) {
		    ($entry{'method'},$entry{'homo'}) = @tmp[5,6];
		    #print "xx ??reached here?\n";
		} else {
		    $entry{'method'} = 'NULL';
		    $entry{'homo'} = 'NULL';
		}
		push @frag,{%entry};
		last;
	    }
	}
	close $fhSeq_sub;
    }
    return [@frag];
}				# END of SUB fragSum


#========================================================
sub getSeqInfo {
    my ($fileFasta) = @_;
    my ( $id,$seq,$seqLen );
    my ( $nameSub, $fhSeq_sub );
#--------------------------------------------------------

    $nameSub = 'getSeqInfo';
    $fhSeq_sub = $nameSub."_SEQ";

    $seq = "";
    open ($fhSeq_sub,$fileFasta) or die "cannot open $fileFasta:$!";
    while (<$fhSeq_sub>) {
	chomp;
	if ( /^\s*\>/ ) {
	    $id = $_;
	    $id =~ s/^\s*\>\s*//g;
	    $id =~ s/\s+.*//g;
	    if ( $id =~ /\bgi\|(\d+)\|/i ) { # if we have a GI number
                $id = $1;
	    } elsif ( $id =~ /\|(\w+)$/ ) {
		$id =~ s/.*\|//g;
	    } else {		# we just take the file name
		$id = $fileFasta;
		$id =~ s/.*\///g;
		$id =~ s/\..*//g;
	    }
	    next;
	} 
	$seq .= $_;
    }
    close $fhSeq_sub;
    $seq =~ s/\s+//g;
    $seqLen = length $seq;
    return ($id,$seqLen,$seq);
}				# END of SUB getSeqInfo


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

#=============================================================
sub printInput {
    my ( $fhOut, $seqName,$seqLen ) = @_;
#-------------------------------------------------------------

    print $fhOut
	"<?xml version=\"1.0\"?>\n",
	"<protein>\n",
	"<proteinID>$seqName</proteinID>\n",
	"<Length>$seqLen</Length>\n";
    return;
}				# END of SUB printInput


#=============================================================
sub printInputTxt {
    my ( $fhOut, $seqName,$seqLen ) = @_;
#-------------------------------------------------------------

    print $fhOut
	"# Query  : $seqName\n",
	"# Length : $seqLen\n";
    return;
}				# END of SUB printInput

#=============================================================
sub printSum {
    my ( $table,$fhOut ) = @_;
    my ( $space, $entry,$homo,$eValue,$format,$bar );
#-------------------------------------------------------------

    $space = ' ';
    $bar = "-";
    $format = "%-10s%3s%-20s%3s%-10s%3s%-20s\n";
    printf $fhOut
	$format,
	"Fragments",$space,"Homologue(region)",$space,
	"E_value",$space,"Method";
    printf $fhOut
	$format,
	$bar x10,$space,$bar x20,$space,
	$bar x10,$space,$bar x20;

    foreach $entry ( @$table ) {
	$homo = $entry->{'homo'};
	if ( $homo ne 'NULL' ) {
	    $homo =~ s/\((.*),/\(/;
	    $eValue = $1;
	} else {
	    $eValue = 'NULL';
	}
	
	print $fhOut
	    "<domain>\n",
	    "<domainRegion>",$entry->{'region'},"</domainRegion>\n",
	    "<homoMethod>",$entry->{'method'},"</homoMethod>\n",
	    "<homoName>",$homo,"</homoName>\n",
	    "<homoEvalue>",$eValue,"</homoEvalue>\n",
	    "</domain>\n";
    }
    print $fhOut "</protein>\n";

    return;
}				# END of SUB printSum

#=============================================================
sub printSumTxt {
    my ( $table,$fhOut ) = @_;
    my ( $space, $entry,$homo,$eValue,$format,$bar );
#-------------------------------------------------------------

    $space = ' ';
    $bar = "-";
    $format = "%-10s%3s%-20s%3s%-10s%3s%-20s\n";
    printf $fhOut
	$format,
	"Fragments",$space,"Homologue(region)",$space,
	"E_value",$space,"Method";
    printf $fhOut
	$format,
	$bar x10,$space,$bar x20,$space,
	$bar x10,$space,$bar x20;

    foreach $entry ( @$table ) {
	$homo = $entry->{'homo'};
	if ( $homo ne 'NULL' ) {
	    $homo =~ s/\((.*),/\(/;
	    $eValue = $1;
	} else {
	    $eValue = 'NULL';
	}
				
	printf $fhOut 
	    $format,
	    $entry->{'region'},$space,
	    $homo,$space,
	    $eValue,$space,
	    $entry->{'method'};
    }
    print $fhOut "//\n";

    return;
}				# END of SUB printSum



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
    $optHmmer = " --acc  ";
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


#===============================================================
sub writeFragmentSeq {
    my ( $seqName,$origin,$offset,$start,$end,$status,$seq ) = @_;
    my ( $fragLen,$seqFrag,$adjustedStart,$adjustedEnd,$fileOut );
    my ( $nameSub,$fhOut_sub );
#---------------------------------------------------------------

    $nameSub = 'writeFragmentSeq';
    $fragLen = $end - $start + 1;
    $seqFrag = substr($seq,$start-1,$fragLen);
    $adjustedStart = $start + $offset;
    $adjustedEnd = $end + $offset;

    print $fhTrace
	"w) writing $adjustedStart-$adjustedEnd part of original seq to $seqName\n";
    if ( $opt_debug ) {
	print STDERR 
	    "w) writing $adjustedStart-$adjustedEnd part of original seq to $seqName\n";
    }
	
    $fileOut = $dirTmp.$seqName.".f";
    $fhOut_sub = $nameSub.'_OUT';
    open ($fhOut_sub, ">$fileOut") or die "cannot write to $fileOut:$!";
    print $fhOut_sub
	">$seqName\t","$fragLen\t",
	"$origin\t","$adjustedStart-$adjustedEnd\t","$status\n",
	"$seqFrag\n";
    close $fhOut_sub;
    push @toDelete,$fileOut;
    return;
}				# END of SUB writeFragmentSeq


