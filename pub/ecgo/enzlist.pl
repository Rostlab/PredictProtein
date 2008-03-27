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

$debug = 1;
use lib '/nfs/data5/users/ppuser/server/pub/ecgo/';

#$hssp_filter_pl = "/usr/pub/molbio/prof/scr/hssp_filter.pl"
#$hssp_filter_bin = "/usr/pub/molbio/prof/bin/filter_hssp_big.LINUX"
#$copf_pl = "/usr/pub/molbio/prof/scr/copf.pl"
$hssp_filter_pl = "/nfs/data5/users/ppuser/server/pub/prof/scr/hssp_filter.pl";
$hssp_filter_bin = "/nfs/data5/users/ppuser/server/pub/prof/bin/filter_hssp_big.LINUX";
$copf_pl = "/nfs/data5/users/ppuser/server/pub/prof/scr/copf.pl";

goto skip_protfun;
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

$homedir = "/home/kernytsky/work";
$clustalx_exe = "$homedir/clustalw/clustalx1.82.linux/clustalx";
$phobius_exe = "$homedir/enzyme/phobius/phdhtm_from_hssp.pl";

unshift (@INC, "$homedir/enzyme/data/"); 
use prof;
use File::Copy;
use Cwd;

sub show_usage() {
    print "\nUsage:\n\nenzlist.pl\n";
    print "\t-pp=fasta_file,prof_file,phd_file,hssp_file\n";
    print "\t\tPredictProtein mode; expects almost everything to be prepared for it (single sequence only)\n";
    print "\t-seqfile=fasta_file\n";
    print "\t\tFully automatic mode; expects only fasta file (single sequence only)\n";
    exit();
}

$no_result = 0;
$start_line = -1;
$end_line = 2000000000;
$swiss_filename = "/data/swissprot/old/42/sprot42.dat";
if ($#ARGV == -1) { show_usage(); }
foreach (@ARGV) {
    if (/^no_result$/) {
	print "### no_result selected; will create intermediate files but not result files\n";
	$no_result = 1;
    }elsif (/^start_line\s*\=\s*(\d+)/) {
	$start_line = $1;
    }elsif (/^end_line\s*\=\s*(\d+)/) {
	$end_line = $1;
    }elsif (/^\-seq\=(\S+)/) {
	$fasta_filename = $1;
	$novel_seq = 1;
    }elsif (/^\-pp\=(\S+)$/){ # this is for sequoia + PP interaction
	($fasta_filename, $pp_prof_filename, $pp_hssp_filename) = 
	    m/^\-pp=(.*?),(.*?),(.*?)$/;
	if (! defined($2) ) { 
	    print "Wrong number of parametrs to option -pp\n";
	    show_usage();
	}
	#print ($fasta_filename, $pp_prof_file, $pp_phd_file, $pp_hssp_file);
	$sequoia_seq = 1;

	### change paths
	$ecgo_homedir = "/nfs/data5/users/ppuser/server/pub/ecgo";
	$clustalx_exe = "$ecgo_homedir/clustalx/clustalx";
	$phobius_exe = "$ecgo_homedir/phobius/phdhtm_from_hssp.pl";
    }else{
	print "Unrecognized command line parameter $_\n";
	show_usage();
    }
}

if ($novel_seq or $sequoia_seq) {
    $novel_workdir = cwd()."/work_enzlist";# "work_$$";
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
	if (/^>/) {
	    goto WRITE_ENTRY; # should become subroutine to process >1 seq
	    $sequence = "";
	    next;
	}else{
	    $sequence .= $_;
	}
    }
    goto WRITE_ENTRY;
}
   
#open FIN, "/data/swissprot/release45.dat" or die "couldn't find swissprot file\n";
open FIN, $swiss_filename or die "couldn't find swissprot file\n";

open PS, "<$homedir/enzyme/data/prosite_count" or die "prosite_count file\n";
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
    open EZ, ">$homedir/enzyme/data/enzyme-unique7.sp" or die "EZ file\n";
    open NEZ, ">$homedir/enzyme/data/nonenzyme-unique7.sp" or die "NEZ file\n";
}
print "Start line: $start_line\nEnd line: $end_line\n";

$sge = 0;
if ($sge) {
    open UNI, "<$homedir/enzyme/prof/swissvswiss/uniquedist0/UNIQUE-ok.list.$ENV{SGE_TASK_ID}" or die "UNIQUE file\n";
}else{
    open UNI, "<$homedir/enzyme/data/UNIQUE-ok-dist0-cleanedup.list" or die "UNIQUE file\n";
}


#$starttime=0;
$IP_string = "";
$startt = (times)[0];
$line=0; $enzymes=0; $entries=0; $fe=0; $ec1=0;
$next_uni = uc <UNI>;
chomp $next_uni;
#DEBUG
#$next_uni = "YB44_SCHPO";
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
	if (/\(EC (\d)\.(\d)/) {
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
	
	### Skip sequences that are not listed in unique file
	if (!$novel_seq and !$sequoia_seq) { # don't check uniqueness if we have a novel seq
	    if ($id eq "") { print "Error, no ID found for seq at line $line\n"; }
	    if ($id gt $next_uni) {
		print "Skipping unique prot $next_uni because SP $id passed with no $next_uni\n";
		$next_uni = uc <UNI>;
		chomp $next_uni;
		$uni_num++;
	    }
	    if ($id ne $next_uni) {
		$id = "";
		next;
	    }
	}
	### We know we have a valid unique protein now
	$uni_num_in_ec[$fe]++;
	#goto SKIP_SEQ; # This is a hack to prevent file output when we
	# just want to count the number of prots in each EC class

	if (($uni_num >= $start_line) && ($uni_num <= $end_line)) {

	    ### Check that PS hit exists, skip this entry if it doesn't
	    ### Print to file the PS hits
	    if (!$novel_seq and !$sequoia_seq) {
		if ($psid ne "") {
		    goto HAVEPSID;
		}
		$ps_line = "";
		while (<PS>) {
		    if (/^>/) {
			chomp;
			s/^>//;
			$psid = $_;
		      HAVEPSID:
			if ($next_uni gt $psid) {
			    #print "Skipping unique prot $next_uni because SP $psid passed with no $next_uni\n";
			}else{
			    if ($psid ne $next_uni) {
				print "Skipping unique prot $next_uni because PS hit $psid passed with no $next_uni\n";
				$next_uni = uc <UNI>;
				chomp $next_uni;
				$uni_num++;
				last;
			    }
			    #print "$psid $next_uni\n";
			    $_ = <PS>;
			    $ps_line = "PS\t$_";
			    #print $fh "PS\t$_";
			    $psid = "";
			    last;
			}
		    }
		}
		if ($ps_line eq "") { next; }
	    }# if novel_seq

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
		print "#### Sequence length < 30, skipping this prot\n";
		goto SKIP_SEQ;
	    }
 	    if (scalar(@frag) != 0) {
		print "<SKIP> Skipping because protein is fragment / hypothetical\n";
		print "\t".join("\t",@frag);
		print "</SKIP>\n";
		goto SKIP_SEQ;
	    }
	  WRITE_ENTRY:
	    #print $fh ">".$id; # Print Seq ID and sequence in FASTA file
 	    print $fh "ID\t".$id."\n"; #print >id
	    print $fh "Acc\t".$acc."\n";
	    print $fh "Seq\t".$sequence."\n";
	    
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
		if ($ps_line ne "") { print $fh $ps_line; }
		#else { die "Error: $psid, $spid\n"; }
	    }

	    ### Generate (if needed) and print conservation score
	    $path = "$homedir/enzyme/prof/finished";
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
		    command ("$hssp_filter_pl $path/$id.hssp exe=$hssp_filter_bin fileOut=$path/$id-fil.hssp red=80");
		    $nalign = get_nalign_from_hssp("$path/$id-fil.hssp");
		    if ($nalign > 1) {
			command ("$copf_pl $path/$id-fil.hssp fileOut=$path/$id-fil.saf saf");
			command ("$copf_pl $path/$id-fil.saf fileOut=$path/$id-fil.f fasta");
			### sed is doing two things:
			### - replacing all . with - since clustal recognizes only -
			### - replacing X with - since we want X to be treated as gap in sequence  
			command ("sed s/[.X]/-/g $path/$id-fil.f > $path/$id-fil.f2");
			command ("$clustalx_exe $path/$id-fil.f2");
			#command ("$homedir/clustalw/clustalx1.82.linux/clustalx $path/$id-fil.f2");
		    }
		}
		if ($nalign == 1) {
		    print "### HSSP file has only one alignment. Will manually create a single-alignment qscores file.\n";
		    open QSCORES, ">$path/$id-fil.qscores" or die "could not open $path/$id-fil.qscores\n";
		    open HSSP, "<$path/$id.hssp" or print "### !STRONG WARN! could not open $path/$id-fil.hssp\n"; # 006/01/06 changed $id-fil.hssp to $id.hssp because if we have only one seq it shouldn't matter whether we use filtered or not (and we only get unflitered hssp in pp mode)

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
	    
	    # Calculate AA_evo - most common residue - property
	    print "### Calculating most common residue score from HSSP\n";
	    print $fh "AA_evo\t".get_AA_evo_from_hssp("$path/$id-fil.hssp")."\n";

	    # Print phdHTM results
	    $htm_path = "$homedir/enzyme/phobius/18K_phdhtm/preds";
	    if ($novel_seq or $sequoia_seq) {$htm_path = $path;}
	    $htm_file = "$htm_path/$id-fil.phd_human";
	    if (! -e $htm_file) { # try to make .phd_human file
		command("$phobius_exe seqfile=$novel_workdir/novel_seq-fil.hssp"); }
	    if (-e $htm_file) {
		if (open (HTMF, $htm_file)) {
		    $type = <HTMF>;
		    chomp $type;
		    $filt_HL = <HTMF>;
		    $prob_L = <HTMF>;
		    #$unfilt_HL = <HTMF>;
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

	    # Commented out just for when we're not trying to generate QSCORES
	    if (-e "$path/$id-fil.qscores") {
		#$clustal_res = ## we're not using the result of extract_clustal_preds
		extract_clustal_preds("$path/$id-fil.qscores",$sequence);
		#print $fh $clustal_res;
	    }else{
		#print "#### WARINNG No QSCORES file was generated!\n";
		print "#### WARINNG No .F2 file was generated!\n";
	    }
	    
	    ++$cons_iters;
	    print "### $cons_iters files finished\n";
	    #if (++$cons_iters >= 25) {
	    #    die "reached $cons_iters iterations\n";
	    #}
	    
	    if (!$novel_seq and !$sequoia_seq) {
		### Print InterPro hits
		if ($IP_string eq "") {$IP_string = ".";}
		$IP_string =~ s/\,$/\./;
		print $fh "IP\t".$IP_string."\n";
		
		### Print EC first #
		print $fh "EC\t".$ec1."\n";
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
	$next_uni = uc <UNI>;
	chomp $next_uni;
	$uni_num++;
	$id="";
	$IP_string = "";
    }
    if (($swiss_entries % 1000)==0) {
	if (!$printed) {
	    $printed = 1;
	    print "$swiss_entries entries, $enzymes enzymes, $entries unique prots processed, next uniqueprot is $next_uni...\n";
	    system();
	}
    }
    #if ($line > 100000) { last; }
}
print "\n";
#$elapsed = gettimeofday-$starttime;
$endt = (times)[0];
printf "%.2f CPU seconds\n", $endt-$startt;

print "Enzymes: $uni_num_in_ec[0]\n";
print "Nonenzymes: $uni_num_in_ec[1]\n";

sub command {
    my $cmd = shift;
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
	#$num_total = ($all_query_res =~ tr/A-Z\-//);

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
    open HSSP, "<$filename" or print "### !STRONG WARN! could not open $path/$id-fil.hssp\n";
    while ((<HSSP>)) { if (/^\#\# ALIGNMENTS/){last;} }
    <HSSP>;
    $i=0;
    $cons_seq="";
    while (<HSSP>) {
	if (/^\#\# SEQUENCE/) {last;}
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
	for ($i=3; $i<23; $i++) {
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
	
	#if (0) {
	    #print substr ($seq,$pos,1). " | ".$headers[$highest_index]." ".$highest_count;
	    #if (substr ($seq,$pos,1) ne $headers[$highest_index]) { 
		#print " *"; 
	    #}else{
		#print "  ";
	    #}
	    #print "  $prof_pos[$pos]\n";
	    #$pos++;
	#}
    }
    close HSSP;
    return $cons_seq;
}

sub gen_prof () {

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
























