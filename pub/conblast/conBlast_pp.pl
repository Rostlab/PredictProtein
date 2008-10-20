#! /usr/bin/perl -w 
$dbg=0;


#------------------------------------------------------------------------------#
#	Copyright				        	2006	       #
#	Dariusz Przybylski	dudek@cubic.bioc.columbia.edu		       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street						       #
#	New York, NY 10032						       #
#	version 1.0                                       Sept, 2006           #
#------------------------------------------------------------------------------#

($qFasta,$prefix,$fileOutBoth,@l_flags)=@ARGV;

die "ERROR: arguments not defined, stopped"
    if(! defined $qFasta || ! defined $prefix || 
       ! defined $fileOutBoth);


if(! -e $qFasta){
    die "ERROR: input fasta file $qFasta not found, stopped";
}

$par{"blastpgp_exe"}            = "/usr/pub/molbio/blast/blastpgp";

$par{"db_train_bin"}            = "/data/blast/big_80";
#$par{"db_train_bin"}            = "/data/blast/pdb";

$par{"db_swiss_consensus_bin"}  = "/data/blast/swisscons";
$par{"db_pdb_consensus_bin"}    = "/data/blast/pdbcons";
$par{"db_swiss_raw_txt"}        = "/data/derived/big/swissraw";
$par{"db_pdb_raw_txt"}          = "/data/derived/big/pdbraw";
$par{"dir_work"}                = $ENV{'HOME'}."/server/pub/conblast/work/";
#$par{"dir_work"}                = "/home/dudek/workTmp/";


if(! -e $par{"dir_work"} || ! -d $par{"dir_work"} || ! -w $par{"dir_work"}){
    die "ERROR: work directory $par{dir_work} not found or not writable, stopped";
}
$par{"dir_work"}  .="/" if($par{"dir_work"} !~/\/$/);

$dbConsBin=$dbRawTxt="";
foreach $flag (@l_flags){
    if($flag =~/^swiss$|^sprot$|^swissprot$/i)   {
	$dbConsBin .=$par{"db_swiss_consensus_bin"}." ";
	$dbRawTxt  .=$par{"db_swiss_raw_txt"}." ";
    }
    elsif($flag =~/^pdb$/i)                      {
	$dbConsBin .=$par{"db_pdb_consensus_bin"}." ";
	$dbRawTxt  .=$par{"db_pdb_raw_txt"}." ";
    }
    else{
	die "ERROR: input argument $flag not understood, stopped"
    }
}
$dbConsBin =~s/\s*$//;
$dbRawTxt  =~s/\s*$//;

if($dbConsBin eq ""){ 
    $dbConsBin=$par{"db_pdb_consensus_bin"}." ".$par{"db_swiss_consensus_bin"};
    $dbRawTxt =$par{"db_pdb_raw_txt"}." ".$par{"db_swiss_raw_txt"};
}



$blastpgp_exe= $par{"blastpgp_exe"};
die "ERROR: executable not found, stopped"
    if(! -e $blastpgp_exe || ! -x $blastpgp_exe);

$dbTrain= $par{"db_train_bin"};
die "ERROR: binary version of blast database file $dbTrain not found, stopped"
    if(! -e $dbTrain.".pin" || ! -e $dbTrain.".psq" || ! -e $dbTrain.".phr");

@l_dbsConsBin=split(/\s+/,$dbConsBin);
foreach $it (@l_dbsConsBin){
    die "ERROR: binary version of blast database file $it not found, stopped"
	if(! -e $it.".pin" || ! -e $it.".psq" || ! -e $it.".phr");
}

@l_dbsRawTxt=split(/\s+/,$dbRawTxt);
foreach $it (@l_dbsRawTxt){
    die "ERROR: database of raw sequences $it not found, stopped"
	if(! -e $it);
}

$coreName         =$qFasta;
$coreName         =~s/.*\///;
$coreName         =~s/\..*$//;
$fileOutCons     =$par{"dir_work"}.$prefix.$coreName.".cons".$$;
$fileOutConsRaw  =$par{"dir_work"}.$prefix.$coreName.".raw".$$;
$fileCheck       =$par{"dir_work"}.$prefix.$coreName.".check".$$;


$cmd1=$blastpgp_exe." -i ".$qFasta." -d \"".$dbTrain."\" -C ".$fileCheck." -j 5 -F F -v 1000 -b 1000 -h 0.0005 -e 0.0005 -a 2 > /dev/null";
print $cmd1,"\n\n" if($dbg);
system($cmd1)==0 ||
    die "ERROR: command:\"$cmd1\" failed, stopped";

$cmd2=$blastpgp_exe." -i ".$qFasta." -d \"".$dbConsBin."\" -R ".$fileCheck." -o ".$fileOutCons." -F F -a 2 >& /dev/null";
print $cmd2,"\n\n" if($dbg);
system($cmd2)==0 ||
    die "ERROR: command:\"$cmd2\" failed, stopped";

unlink($fileCheck) if(! $dbg);

print "&convert_blast_file($fileOutCons,$fileOutConsRaw,$dbRawTxt)\n"
    if($dbg);
&convert_blast_file($fileOutCons,$fileOutConsRaw,$dbRawTxt);

open(FHIN,$fileOutCons) || 
    die "ERROR: failed to open $fileOutCons, stopped";
@l_fileOutCons=(<FHIN>);
close FHIN;

open(FHIN,$fileOutConsRaw) || 
    die "ERROR: failed to open $fileOutConsRaw, stopped";
@l_fileOutConsRaw=(<FHIN>);
close FHIN;

die "ERROR: number of lines in $fileOutCons and $fileOutConsRaw differ, stopped"
    if($#l_fileOutCons != $#l_fileOutConsRaw);

$headerBoth="";
open(FHOUT,">".$fileOutBoth) ||
    die "ERROR: failed to open $fileOutBoth for output, stopped";


$headerBoth ="This file contains alignments of the query sequence with consensus sequences.\n";
$headerBoth.="On the left side:  consensus sequences are translated back into native (real) sequences.\n";
$headerBoth.="On the right side: consensus sequences are not translated.\n";
$headerBoth.="NOTE1: Only the sequences were translated; all scores, alignment residue identities, etc.\n";
$headerBoth.=" pertain to the alignments of consensus sequences\n\n";
$headerBoth.="NOTE2: it is known that PSI-BLAST profiles sometimes degenerate as the number of iterations\n";
$headerBoth.=" increases (here we use 5 iterations) and retrieve many unrelated sequences. In such cases \n";$headerBoth.=" an additional search against consensus sequence databases is likely to retrieve even more\n";
$headerBoth.=" unrelated sequences. The solution would be to somehow guard PSI-BLAST profiles.\n"; 
$headerBoth.="                     *******\n\n";
$headerRaw = "-------- Native sequences  --------";
$headerRaw = sprintf "%-82s", $headerRaw;
$headerBoth.= $headerRaw." | "."-------- Consensus sequences (in the \"Sbjct:\" fields) --------\n";
$tmp=" "; $tmp = sprintf "%-82s", $tmp;
$headerBoth.=$tmp." | "."     \n";
#print $headerBoth;
print FHOUT $headerBoth;
for $i (0 .. $#l_fileOutConsRaw){
    $lineConsRaw = $l_fileOutConsRaw[$i];
    $lineConsRaw =~s/\n$//;
    $lineConsRaw = sprintf "%-82s", $lineConsRaw;
    $lineCons    = $l_fileOutCons[$i];
    $lineBoth    = $lineConsRaw." | ".$lineCons;
    #print $lineBoth;
    print FHOUT $lineBoth;
}
close FHOUT;

if(! $dbg){ unlink $fileOutCons; unlink $fileOutConsRaw; }

#--------------------------------------------------------------------
sub convert_blast_file{
    my $sbr="convert_blast_file";
    my ($fileIn,$fileOut,$dbRaw)=@_;
    die "$sbr: arguments not defined: ".@_.", stopped"
	if(! defined $fileIn || ! defined $fileOut || ! defined $dbRaw);


## parse to get the sequence ids needed
    my %h_id2len;
    my ($id,$len);
    open(FHIN,$fileIn) || 
	die "ERROR: failed to read file=$fileIn\n";
    my $firstLine=<FHIN>; 
    if($firstLine !~ /^BLAST/){
	die "ERROR: $fileIn is not in the right format\n";
    }
    while(<FHIN>){
	if(/^>(\S+)/){ $id=$1; $h_id2len{$id}=1; }
	elsif(/^\s+Length =\s*(\d+)/){ $len=$1; $h_id2len{$id}=$len; }
    }
    close FHIN;


## read sequences
    my %h_id2seq; 
    my @l_dbsRaw = split(/\s+/,$dbRaw);
    foreach $dbLoc (@l_dbsRaw){
	#print "reading $dbLoc\n";
	open(FHIN,$dbLoc) || die "ERROR: failed to read file=$dbLoc\n";	
	my $read=0;
	while(<FHIN>){
	    if(/^>(\S+)/){ 
		$id=$1;
		if(defined $h_id2len{$id}){ 
		    $read=1; 
		    if(defined $h_id2seq{$id}){
			print STDERR "INFO: found multiple entries for $id in $dbLoc. Using only the first one\n";
		    $read = 0;
		    }
		}
		else{ $read=0; }
	    }elsif($read==1){
		s/\s//g;
		$h_id2seq{$id}.=$_;
	    }
	}
	close FHIN;
    }


    foreach $id (sort keys %h_id2len){
	if(! defined $h_id2seq{$id}){
	    die "ERROR: did not find an entry for $id in $dbRaw\n";
	}
    }
    

    my $lenCheck;
    foreach $id (sort keys %h_id2seq){
	$lenCheck=length($h_id2seq{$id});
	if($lenCheck != $h_id2len{$id}){
	    die "ERROR: discrepancy in sequence length for $id . The length found in $dbRaw is $lenCheck while the length indicated in $fileIn is $h_id2len{$id}\n";
	}
    }

    my $fileOutTmp=$fileOut."-tmp";
    my $fhOut="FHOUT".$sbr;
    open($fhOut,">".$fileOutTmp) ||
	die "ERROR: failed to open $fileOutTmp for output, stopped";    
    my $fhIn="FHIN".$sbr;

    my ($edge1,$beg,$specer1,$gfrag,$specer2,$end,$edge2);
    my ($newfrag,$spos);
    open($fhIn,$fileIn) || 
	die "ERROR: failed to open file=$fileIn\n";
    while(<$fhIn>){
	if(/^>(\S+)/){ $id=$1;}
	elsif(/^Sbjct:/){
	    ($edge1,$beg,$specer1,$gfrag,$specer2,$end,$edge2)=
		($_=~/^(Sbjct:\s*)(\d+)(\s*)(\S+)(\s*)(\d+)(\s*)/);
	    $newfrag=""; $spos=$beg;
	    for $i (0 .. length($gfrag)-1){
		if(substr($gfrag,$i,1) ne "-"){ 
		    $newfrag.=substr($h_id2seq{$id},$spos-1,1);
		    $spos++;
		}else{ $newfrag.="-";    }
	    }
	    $_=$edge1.$beg.$specer1.$newfrag.$specer2.$end.$edge2;
	}
	print $fhOut $_;
    }
    close $fhIn;
    close $fhOut;
    rename($fileOutTmp, $fileOut) ||
	die "ERROR: failed to rename $fileOutTmp to $fileOut, stopped";
    
    return;
}
#---------------------------------------------------------------------
