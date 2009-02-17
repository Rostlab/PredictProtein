#!/usr/bin/perl -w

# Makes enzyme/nonenzyme unique files for enzyme program based on swissprot data and unique lists

### Revision history of enzlist result data files ###
# 1-3 - Not shown
# 4 - Added AA_evo property which incorporates some profile info
#     by taking the most common residue at each position if that 
#     such a residue exists (i.e. >2 seqs are aligned and there 
#     is no tie for fisrt place)
# 5 - early stopping - this script unaffected
# 6 - phdHTM results added
# 7 - added ProtFun predictors
# 9b - change to format not documnted, but increase of numbers of enzymes from 
#      1749 in version 6 to 1795 is from including "-" in the regexp for determin-
#      ing if a prot is an enzyme (EC 1.-.-.- is an enzyme)
# 10- added JSD conservation score (turned on Perl warnings too)
# 11- added Disopred
#     added top swissprot hits EC number (still in progress)


$version_number = 11;

$debug = 1;
goto skip_protfun;

use File::Basename;
print "Reading in ProtFun predictions...\n";
%oglyc = (); %nglyc = ();
while ($res = get_protfun_pred()) {
    #print $res;
    #%oglyc = {};
    if ($res =~ /<b>(\w+?): output of \nNetOGlyc.*?Name:.*?\n(.*?)\nName/s) {
	@lines = split /\n/, $2;
	$num_lines = scalar(@lines)/2;
	for ($i=0; $i<$num_lines; $i++) { shift @lines; }
	$oglyc{$1} = join "", @lines;
	#print "O: ".$oglyc{$1}."\n\n";
    }
    if ($res =~ /<b>(\w+?): output of \nNetNGlyc.*?Name:.*?\n(.*?)\n\n\(Thre/s) {
	@lines = split /\n/, $2;
	$num_lines = scalar(@lines)/2;
	for ($i=0; $i<$num_lines; $i++) { shift @lines; }
	$my_prd = "";
	#print @lines;
	foreach $x (@lines) {
	    $my_prd .= substr ($x, 0, 80);
	} 
	$nglyc{$1} = $my_prd;
	#print "N: ".$my_prd."\n\n";
    }
    #getc();
}
print "Loaded ".$nglyc." NGlyc predictions\n";
skip_protfun:

#$homedir = "/home/kernytsky/work";
$homedir = "/nfs/home1/kernytsky";
$clustalx_exe = "$homedir/clustalw/clustalx1.82.linux/clustalx";
$phobius_exe = "$homedir/enzyme/phobius/phdhtm_from_hssp.pl";

BEGIN{
    #unshift (@INC, "$homedir/enzyme/data/"); 
    unshift (@INC, "/nfs/data5/users/ppuser/server/pub/ecgo"); 
}
use prof;
use File::Copy;
use Cwd;

$no_result = 0;
$start_line = -1;
$end_line = 2000000000;
$swiss_filename = "/data/swissprot/old/42/sprot42.dat";
$swiss_fileroot = $swiss_filename; 
$swiss_fileroot =~ s/.*\///;
$enz_uniq_file = "$homedir/enzyme/data/enzyme-unique$version_number.sp";
$nonenz_uniq_file = "$homedir/enzyme/data/nonenzyme-unique$version_number.sp";
$hssp_filter_bin = "/usr/pub/molbio/prof/scr/hssp_filter.pl exe=/usr/pub/molbio/prof/bin/filter_hssp_big.LINUX";
$copf_bin="/usr/pub/molbio/prof/scr/copf.pl";
foreach (@ARGV) {
    if (/^no_result$/) {
	print "### no_result selected; will create intermediate files but not result files\n";
	$no_result = 1;
    }elsif (/^start_line\s*\=\s*(\d+)/) {
	$start_line = $1;
    }elsif (/^end_line\s*\=\s*(\d+)/) {
	$end_line = $1;
    }elsif (/^seqfile\=(\S+)/) {
	$fasta_filename = $1;
	$novel_seq = 1;
    }elsif (/^\-pp\=(\S+)$/){ # this is for sequoia + PP interaction
	($fasta_filename, $pp_prof_filename, $pp_hssp_filename) =#, $pp_pid) = 
	    m/^\-pp=(.*?),(.*?),(.*?)$/;
	if (! defined($2) ) { 
	    print "Wrong number of parametrs to option -pp\n";
	    show_usage();
	}
	print $fasta_filename, $pp_prof_filename, $pp_hssp_filename;#, $pp_pid;
	$sequoia_seq = 1;

	### change paths
	$ecgo_homedir = "/nfs/data5/users/ppuser/server/pub/ecgo";
	$clustalx_exe = "$ecgo_homedir/clustalx/clustalx";
	$phobius_exe = "$ecgo_homedir/phobius/phdhtm_from_hssp.pl";
	$hssp_filter_bin = "/nfs/data5/users/ppuser/server/pub/phd/scr/hssp_filter.pl exe=/nfs/data5/users/ppuser/prof/bin/filter_hssp_big.LINUX";
	$copf_bin="/nfs/data5/users/ppuser/server/pub/phd/scr/copf.pl"
    }elsif (/^chunks\=(\d+)/) {
	# starts a cluster job and defines the number of chunks
	$chunks = $1;
    }elsif (/^chunk_num\=(\d+)/) {
	# takes the SGE_ID env var as the chunk number to append to input and output files
	$chunk_num = $1;
	#$swiss_filename = $swiss_fileroot.".".$chunk_num;
	$enz_uniq_file = basename($enz_uniq_file).".".$chunk_num;
	$nonenz_uniq_file = basename($nonenz_uniq_file).".".$chunk_num;
    }else{
	die "Unrecognized command line parameter $_\n";
    }
}

if ($novel_seq or $sequoia_seq) {
	$novel_workdir = "./work_enzlist";#_$pp_pid";
	mkdir($novel_workdir);
	system ("cp $fasta_filename $novel_workdir/novel_seq.f");

	### open filehandle for output
	open $fh, ">$novel_workdir/novel_seq.sp" or die "error output file\n";

	### only reads one seq now
	open SEQ, $fasta_filename or die "couldn't open $fasta_filename\n";
	$id="novel_seq";
	$acc="novel_seq_acc";
	$sequence="";
	<SEQ>;
	while (<SEQ>) {
	    chomp;
	    #if (/^>/) {
		#goto WRITE_ENTRY; # should become subroutine to process >1 seq
		#$sequence = "";
		#next;
	    #}else{
	    $sequence .= $_;
	    #}
	}
	$sequence =~ s/[\s\d]//g; # remove any whitespace in the sequence
	print "Running on: ".`hostname`;
	#`/nfs/data5/users/ppuser/server/pub/ecgo/xclock`;
	goto WRITE_ENTRY;
}

if ($chunks) {
    # this section based on split_fasta_prof.pl
    #if (open FLAST, "last_run_chunks") {
#	$last_chunks = <FLAST>;
#	chomp $last_chunks;
#	print "last chunks: $last_chunks\nthis chunks: $chunks\n";
#	if ($last_chunks eq $chunks) {
#	    print "Skipping sprot file split\n";
#	    goto SSH;
#	}
#    }
    #open FSP, $swiss_filename or die "couldn't find swissprot file $swiss_filename\n";
    #$sp_entries=0;
    #print "Splitting sprot file\n";
    #while(<FSP>){ if (/^ID/) {$sp_entries++;} }
    #close FSP;
    #system ("echo $sp_entries >num_sprot_entries");
    #print "Found $sp_entries sequences\n";
    system ("echo $chunks >num_chunks");
    print "Will run $chunks chunks\n";
    goto SSH;

    #open FSP, $swiss_filename or die "couldn't find swissprot file\n";
    #$chunksize = $sp_entries / $chunks;
    #$j=-1;
    #for ($i=1; $i<=$chunks; $i++) {
#	$startseq = int (($i-1) * $chunksize);
#	$endseq = int (($i * $chunksize) - 1);
#	# sanity check
#	if ($i == $chunks) {
#	    if ($endseq != ($sp_entries-1)) {
#		die "Last chunk doesn't end correctly $i $sp_entries\n";
#	    }
#	}
#	print "Processing chunk $i from $startseq to $endseq\n";
#
#	open FOUT, ">$swiss_fileroot.$i" or die "Couldn't open output file $swiss_fileroot.$i\n";
#	if ($i != 1) {print FOUT $last_entry;}
#	#$j=$startseq;
#	$entry="";
#	while (<FSP>) {
#	    $entry.=$_;
#	    if (/^\/\//){
#		$j++;
#		if ($j > $endseq) {last;}
#		#if ($j > ($startseq+10)) {last;} #temp to make short lists for testing
#		print FOUT $entry;
#		$entry="";
#	    }
#	}
#	$last_entry = $entry;
#	
#	close FOUT;
#    }
#    close FSP;
  SSH:
    command("ssh gaia.c2b2.columbia.edu qsub -t 1-$chunks /nfs/home1/kernytsky/enzyme2/data/enzlist.sh");
    #open FLAST, ">last_run_chunks";
    #print FLAST $chunks;
    #close FLAST;
    exit();
}

if ($chunk_num) {
    print "### Running chunk number: $chunk_num\n";

    open FNSE, "num_sprot_entries";
    $sp_entries = <FNSE>;
    print "Number of sprot entrties: $sp_entries\n";

    open FNC, "num_chunks";
    $chunks = <FNC>;
    print "Number of chunks: $chunks\n";
    
    $chunksize = $sp_entries / $chunks;
    $start_line = int (($chunk_num-1) * $chunksize)+1;
    $end_line = int ($chunk_num * $chunksize);
}

   
#open FIN, "/data/swissprot/release45.dat" or die "couldn't find swissprot file\n";
open FIN, $swiss_filename or die "couldn't find swissprot file $swiss_filename\n";

open PS, "<$homedir/enzyme/data/prosite_count" or die "prosite_count file\n";

# this option simply writes out the individual fasta files that would otherwise 
# be written to the .sp files; used because only unique, not non-term, not under 
# 30 residue proteins get written (created to run disopred on 8K seqs, not 18K)
$make_fasta_list = 0;
if ($make_fasta_list) {
    #open FASTOUT, ">enzlist_unique.fasta" or die "enzlist_unique.fasta";
}else{
    if ($no_result) {
	open EZ, ">/dev/null";
	open NEZ, ">/dev/null";
#   if (exists $ENV{SGE_TASK_ID}) {
#	$start_line = $ENV{SGE_TASK_ID} * 1000;
#	$end_line = $ENV{SGE_TASK_ID} * 1000 + 99;
#    }
#}elsif ($novel_seq) {
#    open EZ, ">$novel_workdir/novel_seq.sp" or die "EZ file\n";
#    open NEZ, ">$novel_workdir/novel_seq2.sp" or die "NEZ file\n";
    }else{
	open EZ, ">".$enz_uniq_file or die "EZ file\n";
	open NEZ, ">".$nonenz_uniq_file or die "NEZ file\n";
    }
    print "Start line: $start_line\nEnd line: $end_line\n";
    
# Turn off UTF-8 upgrading of bytes 0x80 through 0xFF
    binmode EZ, ":bytes";
    binmode NEZ, ":bytes";
}


$sge = 0;
if ($sge) {
    open UNI, "<$homedir/enzyme/prof/swissvswiss/uniquedist0/UNIQUE-ok.list.$ENV{SGE_TASK_ID}" or die "UNIQUE file\n";
}else{
    open UNI, "<$homedir/enzyme/data/UNIQUE-ok-dist0-cleanedup.list" or die "UNIQUE file\n";
}

#$starttime=0;
$IP_string = "";
$startt = (times)[0];
$line=0; $enzymes=0; $entries=0; $fe=0; $ec1=0; $swiss_entries_processed=0;
$uni_num_in_ec[0]=$uni_num_in_ec[1]=0;
$uni_num=0; $uni_num_written=0;

%uprots = ();
# new unique protein method 11/6/07
print "Reading in unique prots list...";
while (<UNI>) {
    chomp;
    $uprots{uc($_)} = 1;
}
close UNI;
print "done\n";

# new prosite ID read method 11/6/07
print "Reading in prosite hits list...";
while (<PS>) {
    chomp;
    if (substr($_,0,1) ne ">") {die "error parsing prosite file\n";}
    $psid = substr($_,1);
    $_ = <PS>;
    chomp;
    $prosite_hits{$psid} = $_;
    #print $psid." ==> ".$_."\n";
}
close PS;
print "done\n";

### Read sprot41.dat and unprot_trembl.fasta.jul03 headers
### to get the EC numbers for all known sprot and trembl IDs

%ec_lookup = ();
for $filename ("/data/trembl/knowledgebase1.0/sprot41.fasta.headers_only") {#, "/data/trembl/knowledgebase1.0/uniprot_trembl.fasta.jul03.headers_only") {
    open $fh, $filename or die "Couldn't open $filename\n"; 
    print "Parsing file $filename\n";
    $prots = 0; $enzyme_prots = 0;
    while (<$fh>) {
	# search against all prots
	#if ( (/.*?\|.*?\|(.*?)\s/) ) { #&& (exists $uprots{$1}) ) {
	# search against unique prots
	if (( (/.*?\|.*?\|(.*?)\s/) ) && (exists $uprots{$1})) {
	    $prots++;
	    $id = $1;
 	    if (/.*?\|.*?\|(.*?)\s.*?\(EC (.*?)\)/) {
		$enzyme_prots++;
		#print "$1 $2\n";
		$ec_lookup{$1}=$2;
	    }else{
		$ec_lookup{$1}="0";
	    }
	}
    }
    print "Proteins: $prots\n";
    print "Enzymes: $enzyme_prots\n";
}
print $ec_lookup{"104K_THEPA"}."\n";

#$next_uni = uc <UNI>;
#chomp $next_uni;

while (<FIN>) {
    $line++;
    #if (/^KW/) {
	#if (/enzyme/i) {
	    #print "$line $_\n";
	    #$enzymes++;
	#}
    #}
    #if ($cons_iters >= 8) { exit; }
    if (/^ID/) {
	@temp = split /\s+/;
	$id = $temp[1];
	$swiss_entries++;
	$printed = 0;
	$IP_string = "";
	$ec1 = 0;
	$fe = 0;
	@frag = ();

	# new start_line end_line coded added for doing chunks on 11/8/07
	if ($swiss_entries > $end_line) { $swiss_entries--; last; }
	#print ">>> Starting protein: $id\n";
    }
    ### Get the Accession Number
    if (/^AC/) {
	/^AC\s+(\w+)\;/;
	$acc = $1;
    }
    ### Look at description line for an EC number
    if (/^DE/) {
	#if (/hypothetical|subunit|chain|fragment|putative|probable|polypeptide/i) {
	if (/hypothetical|fragment|putative|probable|polypeptide/i) {
	    push (@frag, $_);
	}
	#if (/\(EC (\d)\.(\d)/) {
	if (/\(EC (.+?)\)/) { # changed between v.6 and v.9 to not require digits
	    # and include dashes
	    $enzymes++;
	    $fe=1;
	    $ec1 = $1;
	    #print "EC#: $ec1\n";
	}#else{
	#    $ec1 = 0;
	#}
    }
    ### Check features entry (FT) to see if any of the terminals are "non-terminal" NON_TERM
    ### (i.e. check if this is not a fragment)
    if (/^FT\s+NON_TER/) {
	push (@frag, $_);
    }
    if (/^DR/) {
	s/^DR\s+//;
	@split = split /\;\s/;
	if ($split[0] eq "InterPro") {
	    $IP_hit_number = $split[1];
	    $IP_hit_number =~ s/IPR//;
	    $IP_string .= $IP_hit_number.",";
	}
    }
    ### Get sequence and copy to appropriate file
    if (/^SQ/) {
	
	# skip if we're not at start_line:
	if ($swiss_entries < $start_line) {  next; }
	$swiss_entries_processed++;

	### Skip sequences that are not listed in unique file
	if (!$novel_seq and !$sequoia_seq) { # don't check uniqueness if we have a novel seq
	    if ($id eq "") { print "Error, no ID found for seq at line $line\n"; }
	    if (exists $uprots{$id}) {
		print "$id is a unique prot.\n";		
		$uni_num++;
	    }else{
		#print "$id is not a unique prot, skipping.\n";
		next;
	    }
	    #if ($id gt $next_uni) {
		#print "Skipping unique prot $next_uni because SP $id passed with no $next_uni\n";
		#$next_uni = uc <UNI>;
		#chomp $next_uni;
		#$uni_num++;
	    #}
	    #if ($id ne $next_uni) {
		#$id = "";
		#next;
	    #}
	}
	### We know we have a valid unique protein now
	#goto SKIP_SEQ; # This is a hack to prevent file output when we
	# just want to count the number of prots in each EC class

	# old start_line last_line code; changed 11/8/07
	#if (($uni_num >= $start_line) && ($uni_num <= $end_line)) {
	{
	    ### Check that PS hit exists, skip this entry if it doesn't
	    ### Print to file the PS hits
	    if (!$novel_seq and !$sequoia_seq) {
		if (exists $prosite_hits{$id}){
		    $ps_line = "PS\t$prosite_hits{$id}";
		}else{
		    print "!!!! No prosite entry for seq $id, skipping entry\n";
		    $ps_line = "PS_ERROR!!!";
		    next;
		}
	    }
		#if ($psid ne "") {
		#    goto HAVEPSID;
		#}
		#$ps_line = "";
		#while (<PS>) {
		    #if (/^>/) {
			#chomp;
			#s/^>//;
			#$psid = $_;
		      #HAVEPSID:
			#if ($next_uni gt $psid) {
			    #print "Skipping unique prot $next_uni because SP $psid passed with no $next_uni\n";
			#}else{
			    #if ($psid ne $next_uni) {
				#print "Skipping unique prot $next_uni because PS hit $psid passed with no $next_uni\n";
				#$next_uni = uc <UNI>;
				#chomp $next_uni;
				#$uni_num++;
				#last;
			    #}
			    ##print "$psid $next_uni\n";
			    #$_ = <PS>;
			    #$ps_line = "PS\t$_";
			    #print $fh "PS\t$_";
			    #$psid = "";
			    #last;
			#}
	    #}
	    #if ($ps_line eq "") { next; }
	    #}# if novel_seq

	    ### Select appropriate file handle
	    if ($fe) {
		$fh = 'EZ';
	    }else{
		$fh = 'NEZ';
	    }

	    ### Print to file the Seq ID and the entire sequence line
	    $sequence = "";
	    while (<FIN>) {
		chomp;
		$_ =~ s/\s//g;
		if ($_ eq "//") { 
		    $entries++;
		    #$fe=0; ### This was a bad place for this because 
		    # $fe was not reset if the protein was skipped for 
		    # not being a unique protein
		    #$id="";
		    last; 
		}
		#print $fh $_; #print one line of seq #we now print the whole seq a few lines later
		$sequence .= $_;
	    }
	    $seq_length = length ($sequence);
	    if ($seq_length < 30) {
		print "#### Sequence length < 30, skipping this prot $id\n";
		goto SKIP_SEQ;
	    }
 	    if (scalar(@frag) != 0) {
		print "<SKIP> Skipping because protein is fragment / hypothetical\n";
		print "\t".join("\t",@frag);
		print "</SKIP>\n";
		goto SKIP_SEQ;
	    }
	  WRITE_ENTRY:
	    $uni_num_written++;
	    $uni_num_in_ec[$fe]++;
	    #print $fh ">".$id; # Print Seq ID and sequence in FASTA file
	    if ($make_fasta_list) {
		### Code for making fasta list for running other data generation 
		### such as Meta-diso
		$base_fasta_dir = "/nfs/home1/kernytsky/enzyme2/data/disopred";
		open FASTOUT, ">$base_fasta_dir/$id.fasta" or die "$base_fasta_dir/$id.fasta";
		print FASTOUT ">$id\n";
		print FASTOUT $sequence."\n";
		close FASTOUT;
		next;
	    }else{
		# normal code:
		print $fh "ID\t".$id."\n"; #print >id
		print $fh "Acc\t".$acc."\n";
		print $fh "Seq\t".$sequence."\n";
	    }
	    ### Print to file the PROF predictions;
	    #system ("$homedir/enzyme/prof/");
	    $prof_filename = "$homedir/enzyme/prof/finished/$id-fil.rdbProf";
	    if ($novel_seq) {
		command("$homedir/enzyme/prof/psi_profsec.pl seq=".$novel_workdir."/novel_seq.f" );
		$prof_filename = $novel_workdir."/novel_seq-fil.rdbProf";
	    }
	    if ($sequoia_seq) {
		$prof_filename = $pp_prof_filename;
	    }
	    $prof_res = prof::extract_preds($prof_filename);
	    print $fh $prof_res;

	    if (!$novel_seq && !$sequoia_seq) {
		### Print PROSITE hits
		if ($ps_line ne "") { print $fh "$ps_line\n"; }
		#else { die "Error: $psid, $spid\n"; }
	    }

	    ### Generate (if needed) and print conservation score
	    $path = "$homedir/enzyme/prof/finished";
	    $disopred_path = "$homedir/enzyme2/data/disopred";
	    $blastpgp_path = "$homedir/enzyme/prof/finished_blastpgp_18K_uniqueset";
	    # sub_path is organized according to result type in order to keep the directories from becoming huge
	    # each result type has its own sub-directory
	    $sub_path = "$homedir/enzyme/prof/sub_finished";
	    if ($novel_seq) {$path = $novel_workdir;}
	    if ($sequoia_seq) {
		$path = $novel_workdir;
		copy($pp_hssp_filename, $novel_workdir."/novel_seq.hssp") or die "failed to copy $pp_hssp_filename\n";
	    }
	    $check_for_file = "$path/$id-fil.qscores";
	    #$check_for_file = "$path/$id-fil.f2";
	    # we were checking for .f2 file when
	    # there was no clustalx working on the other machines
	    # now we check for .qscores file cause that signals that we finished this seq
	    if (!-e $check_for_file) {
		#if (!-e "$path/$id-fil.qscores") {
		# if (1) {
		print "\n\n\n### $check_for_file does not exist, will generate it\n";
		
		# Check if there is more than one alignment in HSSP file
		$nalign = get_nalign_from_hssp("$path/$id.hssp");
		if ($nalign > 1) {
		    $hsspfil_cmd = $hssp_filter_bin." $path/$id.hssp fileOut=$path/$id-fil.hssp red=80";
		    #if ($sequoia_seq) { #Maxhom matrix in wrong place on gaia (sequoia)
			#$hsspfil_cmd .= "  fileMatGcg=/usr/pub/molbio/prof/mat/Maxhom_GCG.metric";
		    #}
		    command ($hsspfil_cmd);
		    $nalign = get_nalign_from_hssp("$path/$id-fil.hssp");
		    if ($nalign > 1) {
			command ($copf_bin." $path/$id-fil.hssp fileOut=$path/$id-fil.saf saf");
			command ($copf_bin." $path/$id-fil.saf fileOut=$path/$id-fil.f fasta");
			### sed is doing two things:
			### - replacing all . with - since clustal recognizes only -
			### - replacing X with - since we want X to be treated as gap in sequence  
			command ("sed s/[.X]/-/g $path/$id-fil.f > $path/$id-fil.f2");
			#command ("$homedir/clustalw/clustalx1.82.linux/clustalx $path/$id-fil.f2");
			command ($clustalx_exe." $path/$id-fil.f2");
		    }
		}
		if ($nalign == 1) {
		    print "### HSSP file has only one alignment. Will manually create a single-alignment qscores file.\n";
		    open QSCORES, ">$path/$id-fil.qscores" or die "could not open $path/$id-fil.qscores\n";
		    open HSSP, "<$path/$id.hssp" or print "### !STRONG WARN! could not open $path/$id.hssp\n";

		    while ((<HSSP>)) {# && ($_ !~ /^\#\# ALIGNMENTS/)) {}
			if (/^\#\# ALIGNMENTS/){last;}
		    }
		    <HSSP>;
		    while (<HSSP>) {
			if (/^\#\# SEQUENCE/) {last;}
			@temp = split /\s+/;
			print QSCORES "$temp[3]\t100\n";
		    }
		    close HSSP;
		}
	    }else{
		print "\n\n\n### $check_for_file alread exists, not regenerating it\n";
	    }

	    $hssp_file = $id."-fil.hssp";
	    if (! -e "$path/$hssp_file") {
		$hssp_file = $id.".hssp";
		if (! -e "$path/$hssp_file") { print "#!STRONG WARN!# Missing filtered and unfiltered HSSP file\n"; }
	    }

	    # Calculate AA_evo - most common residue - property
	    print "### Calculating most common residue score from HSSP\n";
	    print $fh "AA_evo\t".get_AA_evo_from_hssp("$path/$hssp_file")."\n";

	    # Jensen-Shannon Divergence Conservation Score

	    # Check if there is more than one alignment in HSSP file
	    $nalign = get_nalign_from_hssp("$path/$id.hssp");
	    if ($nalign > 1) {
		if ($sequoia_seq) {
		    ### Using filtered sequence because PredictProtein hsspPsiFil sequence
		    ### is already filtered and no unfiltered file exists
		    $jsd_filename_root = "$path/$id-fil";
		    $jsd_score_file = "$novel_workdir/novel_seq-fil.scores";
		}else{
		    $jsd_filename_root = "$path/$id";
		    $jsd_score_file = "$sub_path/jsd_cons/$id.scores";
		}
		if ($novel_seq or $sequoia_seq) { $jsd_score_file = "$novel_workdir/novel_seq.scores"; }
		if (! -e $jsd_score_file) {
		    #command ("/usr/pub/molbio/prof/scr/copf.pl $path/$id.hssp fileOut=$path/$id.saf saf");
		    #command ("/usr/pub/molbio/prof/scr/copf.pl $path/$id.saf fileOut=$path/$id.f fasta");
		    print "### Generating JSD cons score\n";
		    command ("/nfs/home1/kernytsky/enzyme2/prof/hssp2clustal.py $jsd_filename_root.hssp");
		    command ("/nfs/home1/kernytsky/python/bin/python /nfs/home1/kernytsky/enzyme/jsd_cons/score_conservation.py -s js_divergence -w 3 -d /nfs/home1/kernytsky/enzyme/jsd_cons/distributions/blosum62.distribution -m /nfs/home1/kernytsky/enzyme/jsd_cons/matrix/blosum62.bla -o $jsd_score_file -l False $jsd_filename_root.clustal");
		    #print "$cmd\n"; #system $cmd;
		}
		if (-e $jsd_score_file) {
		    print "### Writing JSD_cons score\n";
		    open FJSD, $jsd_score_file or die "error opening $jsd_score_file\n";
		    $score_seq = "";
		    $first_fjsd = 1;
		    while (<FJSD>) {
			if (substr($_,0,1) eq "#") {next;}
			@temp = split/\t/;
			$score = $temp[1];
			if ($score == -1000) {$score = 0.0;}
			#$score = int($score*10);
			$score = int($score*100);
			if ($first_fjsd) {
			    $first_fjsd = 0;
			}else{
			    #$score .= ","; # fixed comma issue for v. 11
			    $score = ",".$score;
			}
			$score_seq .= $score;
		    }
		    #print "$score_seq\n";
		    print $fh "JSD\t$score_seq\n";
		}else{
		    die "Failed to find JSD score file after attempting to create it for seq $id";
		}
	    }else{
		print "### Num alignments in HSSP < 2 so writing all 0 for JSD\n";
		print $fh "JSD\t".("0" x length($sequence))."\n";
	    }

	    # Print phdHTM results
	    $htm_path = "$homedir/enzyme/phobius/18K_phdhtm/preds";
	    if ($novel_seq or $sequoia_seq) {$htm_path = $path;}
	    $htm_file = "$htm_path/$id-fil.phd_human";
	    if ( (! -e $htm_file) and ($novel_seq or $sequoia_seq) )  { # try to make .phd_human file
		#command("$homedir/enzyme/phobius/phdhtm_from_hssp.pl seqfile=$novel_workdir/novel_seq-fil.hssp"); }
		command($phobius_exe." seqfile=$novel_workdir/novel_seq-fil.hssp"); }
	    if (-e $htm_file) {
		if (open (HTMF, $htm_file)) {
		    $type = <HTMF>;
		    chomp $type;
		    $filt_HL = <HTMF>;
		    $prob_L = <HTMF>;
		    #$unfilt_HL = 
		    <HTMF>;
		    if ($type ne "") { # if empty string then phdHTM failed
			print $fh "HTMxist\t";
			if ($type eq "RI_S") {print $fh "0\n";} else {print $fh "1\n";}
			print $fh "HTMpred\t$filt_HL";
			print $fh "HTM_pL\t$prob_L";
		    }else{
			print $fh "HTMxist\t0\nHTMpred\t\nHTM_pL\t\n";
		    }
		}else{
		    print "### !STRONG WARN! could not open $htm_file\n";
		}
	    }

	    # Print ProtFun scores
	    if (!$sequoia_seq) {
		if (exists $oglyc{$id}) {
		    print $fh "OGlyc\t".$oglyc{$id}."\n";
		}else{
		    print "### No OGlyc prediction for $id\n";
		}
		if (exists $nglyc{$id}) {
		    print $fh "NGlyc\t".$nglyc{$id}."\n";
		}else{
		    print "### No NGlyc prediction for $id\n";
		}
	    }

	    # Commented out just for when we're not trying to generate QSCORES
	    if (-e "$path/$id-fil.qscores") {
		#$clustal_res = 
		extract_clustal_preds("$path/$id-fil.qscores",$sequence);
		#print $fh $clustal_res;
	    }else{
		#print "#### WARNING No QSCORES file was generated!\n";
		print "#### WARNING No .F2 file was generated!\n";
	    }
	    
	    print $fh "HSSP\t".binary_hssp("$path/$hssp_file")."\n";

	    if (!$novel_seq and !$sequoia_seq) {
		### Print InterPro hits
		if ($IP_string eq "") {$IP_string = ".";}
		$IP_string =~ s/\,$/\./;
		print $fh "IP\t".$IP_string."\n";
		
		### Print EC first #
		print $fh "EC\t".$ec1."\n";
	    }

	    ### Add DISOPRED prediction v. 11 addition
	    if (! $sequoia_seq) {
		$disopred_file = "$disopred_path/$id.diso";
		print "Parsing $disopred_file\n";
		open DISO, $disopred_file or die "couldn't open disopred file $disopred_file\n";
		foreach $i (1..5) {<DISO>;}
		$diso_str = "";
		while(<DISO>) {
		    $diso_str .= substr($_,8,1);
		}
		if (length($diso_str) != $seq_length) {
		    die("Disoprd legnth $diso_str <> sequence length $seq_length\n");
		}
		print $fh "Disoprd\t$diso_str\n";
	    }

	    ### Add best BLAST hit's EC number
	    if (! $sequoia_seq) {
		$blastpgp_file = "$blastpgp_path/$id.blastpgp";
		print "Parsing $blastpgp_file for best BLAST hit...\n"; 
		open BLASTPGP, $blastpgp_file  or die "couldn't open blastpgp file $blastpgp_file\n";
		while(<BLASTPGP>) {
		    if (/^Sequences producing significant alignments:/) { <BLASTPGP>; last; }
		}
		$best_ec_hit="";
		$best_hit_eval="";
		$num_ec_hits=0;
		$num_unfound_ec_hits=0;
		while(<BLASTPGP>) {
		    if (/^>/) { last; }
		    if (/(swiss)\|\w+\|(\w+)\s/) {
			#if (/(swiss|trembl)\|\w+\|(\w+)\s/) {
			$num_ec_hits++;
			print "$2 $_";
			if (exists $ec_lookup{$2}) {
			    $this_ec_hit = $ec_lookup{$2};
			    $e_val = substr($_, 76, 5);
			    print "$2 $ec_lookup{$2} $e_val\n";
			    #if (($this_ec_hit ne "0") && 
			    if ( ($this_ec_hit ne "") && ($best_ec_hit eq "") && ($id ne $2)) {
				$best_ec_hit = $this_ec_hit;
				$best_hit_eval = $e_val;
				print "id: $id, hit_id: $2, this_hit_ec: $this_ec_hit\n"; 
			    }
			    print "$ec_lookup{$2}\n";
			}else{
			    $num_unfound_ec_hits++;
			}
		    }
		}
		print "Alignments (not found/total/percentage): ";
		print "$num_unfound_ec_hits / $num_ec_hits ";
		printf "(%.1f%%)\n", $num_ec_hits ? ($num_unfound_ec_hits/$num_ec_hits)*100 : 0;
		print "EC: $best_ec_hit\n";
		print $fh "Blst_EC\t$best_ec_hit\n";
		print $fh "Bl_eval\t$best_hit_eval\n";
	    }

	    ### Print record terminator
	    print $fh "//\n";
	    
	    if ($novel_seq or $sequoia_seq) {
		$result_filename = $fasta_filename;
		$result_filename =~ s/\..*$/\.sp/;
		#system ("cp $novel_workdir/novel_seq.sp $result_filename");
		exit();
	    }
	}
	### Read next unique prot name $next_uni
      SKIP_SEQ:
	#$next_uni = uc <UNI>;
	#chomp $next_uni;
	#$uni_num++;
	$id="";
	$IP_string = "";
    }
    if (($swiss_entries_processed % 1000)==0 && $swiss_entries_processed != 0) {
	if (!$printed) {
	    $printed = 1;
	    print "$swiss_entries_processed entries, $enzymes enzymes, $entries unique prots processed\n";#, next uniqueprot is $next_uni...\n";
	    system();
	}
    }
    #if ($line > 2000000) { last; }
}
print "\n";
#$elapsed = gettimeofday-$starttime;
$endt = (times)[0];
printf "%.2f CPU seconds\n", $endt-$startt;

print "Swiss entries processed: $swiss_entries_processed\n";
print "`--unique entries: $uni_num\n";
print "   `--written (!short, frag): $uni_num_written\n";
print "      `--enzymes: $uni_num_in_ec[0]\n";
print "      `--nonenzymes: $uni_num_in_ec[1]\n";

sub command {
    my ($cmd) = shift;
    my $result;

    if ($debug > 0) {print "--> Executing $cmd\n";}
    $result = system $cmd;
    if ($debug > 0) {print "<-- Execution result => $result\n\n";}
    return $result;
}

sub extract_clustal_preds {
    my $file = shift;
    my $i;

    if (! -e $file) {print "File $file containing clustal preds for parsing not found\n"; print $fh "Clustal\tNONE\n";}
    open CLUSTAL, $file or die "Failed to open $file containing clustal preds for parsing not found\n";
    
    $i = 0;
    $qscore_3state_text=""; $qscore_cons_text=""; $qscore_nali_text="";
    while (<CLUSTAL>) {
	/(.*)\t\s*(\d+)/;
	$qscore = $2;
	$all_query_res = $1;
	
	$num_aa = ($all_query_res =~ tr/A-Z//);
	#$num_total = 
	($all_query_res =~ tr/A-Z\-//);

	### This code was eating up 90% of time in profiler
	#@temp = split /\s/, $all_query_res;
	##$query_res = $temp[0];
	#$num_aa=0; $num_total=0;
	#foreach (@temp) {
	#    $num_total++;
	#    if (/\w/) {$num_aa++;}
	#}

	#/\t\s*(\d+)/; $qscore = $1; /(.)\s/; $query_res = $1;
	#if (uc($query_res) ne uc(substr($sequence, $i, 1))) {
        #    print "Query sequence in qscores file doesn't match expected sequence at position $i in sequence $id\n";
	#}
       
	# Generate one residue of full Clustal conservation score
	if ($qscore_cons_text ne "") {
	    $qscore_cons_text .= ",";
	    $qscore_nali_text .= ",";
	}
	$qscore_cons_text .= "$qscore";
	$qscore_nali_text .= "$num_aa";

	# Generate one residue of  ".:|" score 
	if ($qscore==100) {$qscore=99;}
	$new_letter=int($qscore/10);
	if (length($new_letter)>1) {die "long letter\n";}
	if ($new_letter>=9) {
	    $new_letter = "|";
	}else{
	    if ($new_letter>=5) {
		$new_letter = ":";
	    }else{
		$new_letter = ".";
	    }
	}
	$qscore_3state_text.=$new_letter;
	$i++;
    }

    print $fh "CL_shrt\t".$qscore_3state_text."\n";
    print $fh "CL_cons\t".$qscore_cons_text."\n";
    print $fh "CL_nali\t".$qscore_nali_text."\n";
    #return $qscore;
}

sub get_nalign_from_hssp
{
    my $filename = shift;

    $nalign = -1;
    open FHSSP, "<$filename" or return 0;#die "couldn't find HSSP file $filename\n";

    while (<FHSSP>) { 
	chomp;
	if (/^NALIGN\s+(\d+)/) {
	    $nalign = $1;
	}
    }
    if ($nalign == -1) {
	die "Could not find NALIGN file in $path/$id.hssp\n";
    }
    return $nalign;
}

sub get_AA_evo_from_hssp
{
    my $filename = shift;
    if (!open HSSP, "<$filename") {
	print "### !STRONG WARN! could not open $filename\n";
	return "";
    }
    while ((<HSSP>)) { if (/^\#\# ALIGNMENTS/){last;} }
    <HSSP>;
    $i=0;
    $cons_seq="";
    while (<HSSP>) {
	if (/^\#\# SEQUENCE/) {last;}
	if (/^\#\# ALIGNMENTS/) {next;}
	if (/^\sSeqNo/) {next;}
	@temp = split /\s+/;
	$seq .= $temp[3];
	#$prof_pos[$i] = substr($_, 51);
	$i++;
    } #Get to start of section
    #print "$seq\n";
    $_ = <HSSP>;
    @headers = split/\s+/;
    $pos=0;
    while (<HSSP>){
	if (/\/\//) {last;}
	chomp;
	#print;
	@temp = split/\s+/;
	$highest = -1;
	$highest_index = -1;
	$highest_count = 0;
	for ($i=3; $i<23; $i++) { # iterate through columns of # comp. in HSSP file
	    # order of columns is (starting at index 1)
            # SeqNo PDBNo V L I M F W Y G A P S T C H R K Q E N D\
            # NOCC NDEL NINS ENTROPY RELENT WEIGHT

	    if ($temp[$i] > $highest) {
		$highest = $temp[$i];
		$highest_index = $i;
		$highest_count = 1;
	    }elsif ($temp[$i] == $highest) {
		$highest_count++;
	    }
	}
	if ($highest_count == 0) {
	    $cons_seq .= substr ($seq,$pos,1);
	}else{
	    $cons_seq .= $headers[$highest_index];
	}
	
	if (0) {
	    print substr ($seq,$pos,1). " | ".$headers[$highest_index]." ".$highest_count;
	    if (substr ($seq,$pos,1) ne $headers[$highest_index]) { 
		print " *"; 
	    }else{
		print "  ";
	    }
	    #print "  $prof_pos[$pos]\n"; ## code not called because of if(0) but commented this 
	    # out because of warning 
	    $pos++;
	}
    }
    close HSSP;
    return $cons_seq;
}

sub binary_hssp
{ 
# Creates a binary stream of the frequencies of AAs at each residue
# that can be written to enzyme-unique.sp files
    
    my $seq; 
    if (!open FHSSP, $_[0]) {
	print "binary_hssp: couldn't open ".$_[0]."\n";
	return ""
    }
    # Get the sequence
    while (<FHSSP>) {if ($_ =~ /^\#\# ALIGNMENTS/) { <FHSSP>; last;} }
    while (<FHSSP>) {
	if ($_ =~ /^\#\# SEQUENCE/) { <FHSSP>; last;}
	if (/^\#\# ALIGNMENTS/) {next;}
	if (/^\sSeqNo/) {next;}
	$_ =~ /^\s+\S+\s+\S+\s+(\S)/;
	$seq .= $1;
    }
    # Get the profile
    $pos = 0;
    $binstr="";
    while (<FHSSP>) {
	if (/^\/\//) {last;}
	chomp;
	@temp = split/\s+/;
	for ($i=3; $i<23; $i++) { # iterate through columns of % comp. in HSSP file
	    # order of columns is (starting at index 1)
	    # SeqNo PDBNo V L I M F W Y G A P S T C H R K Q E N D\
	    # NOCC NDEL NINS ENTROPY RELENT WEIGHT
	    #if ($temp[$i] != 0) {$str .= $temp[$i];}
	    #$str .= ",";
	    $binstr .= chr($temp[$i]+32);
	}
	#chop $str; #print "$str ";#.length ($str)."\n"; #$avg += length $str;
	#$iter += 1; #$binavg += length $binstr;
	$binstr .= substr($seq, $pos++, 1); # Add the actual sequence residue
    }
    #print $avg/$iter."\n"; #print $binavg/$iter."\n";
    return $binstr;#.chr(215);
}

BEGIN {
    my $initialized = 0;
    my $fpred;
    sub get_protfun_pred_init {
	$initialized = 1;
	open $fpred, "</home/kernytsky/xata/enzyme/compare_with_protfun/predictions.htm" or die "couldn't open protfun pred file";
    }
    
    sub get_protfun_pred 
    {
	if (!$initialized) { get_protfun_pred_init(); }
	my ($res, $capture);
	$res = "";
	$capture = 0;
	while (<$fpred>) {
	    if (/^<b>ProtFun 2\.2 predictions for /) {$capture = 1;}
	    if ($capture) { $res .= $_; }
	    if (/^\/\//) { last; }
	}
	return $res;
    }
}
























