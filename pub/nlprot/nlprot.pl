#!/usr/local/bin/perl
$path_app = $ENV{HOME}."/server/pub/nlprot/";
$path_app_tmp = $path_app . "tmp/";
$path_app_db = $path_app . "name_dbs/";
$path_app_data = $path_app . "data/";

{
	$path_check = $path_app; $path_check =~ s/\/$//;
	#die2("You have to run this script from it's own directory: $path_app\nIf you recently changed the path of NLProt, it might help to run the install.pl script again.\n") if ($ENV{"PWD"} ne $path_check);
}

use LWP::Simple;
use DB_File;

# -------------------------------------------------------
# NLProt is a program to find protein names
# in scientific text
# and assign DB-Identifiers to these names
# -------------------------------------------------------

# -------------------------------------------------------
# Variables
# and command line options
# -------------------------------------------------------
@pats_insensitive = ( # exclusion patterns for found protein names (words that are definitely not protein names)
						# paterns are case insensitive

	# name matches non-protein multi-word
	'^(transcription factors?)$',
#	'name matches non-protein multi-word',

	# aminoacids
	'^(ala(nine)?|cys(teine)?|asp(aragine)?|glu(tamine)?|phe(nylalanine)?|gly(cine)?|his(tidine)?|ile|isoleucine|lys(ine)?|leu(cine)?|met(hionine)?|asn|aspartic acid|aspartate|pro(line)?|gln|glutamic acid|glutamate|arg(inine)?|ser(ine)?|thr(eonine)?|val(ine)?|trp|tryptophane|tyr(osine)?)(-| )?\(?\d+\)?$',
#	'name looks like an aminoacid',

	'^(type|beta|alpha|gamma|eps[iy]lon|zeta|kappa|class|switch)( |-)(\d+|[ivx]+)$',
#	'type/class/greek-letter not enough for a full name',

	# \d+ kDa
	'^[\d.]+[ \-]?k(Da?|b(yte)?)$',
#	'kDa pattern',

	# name contains punctuation characters
	'(^| )[.,!?:;]( |$)',
#	'punctuation in name',

	# name contains too many dots
        '\.[^.]+\.[^.]+\.',
#	'too many dots in name',

	# name contains digits and dots in bad combination
	'(^| )\d+\.\d{2,}$',
#	'too many dots and digits in name',

	# name contains 'cell-type' key-words at the end
	'(^| |-)(cells?|\w+cytes?)$',
#	'seems to be cell type/name 1',

	# name contains number plus plural word
	'^([\d.,]+|two|three|four|fife|six|seven|eight|nine|ten|eleven|twelve) \w+[^s]s$',
#	'number plus plural noun',

	# name contains 'cell' at the beginning plus only one following word (like cell type or cell division)
	'^(cells?)( |-)\w+$',
#	'seems to be some cell-?? word',

	# name contains weird prepositions or personal pronouns
	'(^| )(and(\/or)?|or|its|their|our|this|that|these|those|are|was|were|been|may|which|where|what|when|but|both|then|if|whether)( |$)',
#	'name contains bad word',

	# name matches to-be/to-have form plus adverb or past participle (e.g. "was ubiquitously", "is restricted", "has analyzed")
	'(^| )(was|were|is|are|been|have|has) (\w+ly|\w+ed|bound|put|found|set|caught|brought)( |$)',
#	'name is form of to-be plus adverb or participle',

	# too many consecutive digits
	'[\d\.]{5}',
#	'more than 4 consecutive digits',

	# '=' or '°C' or '->' in name (impossible)
	'[=%;#@$?!]|°.?[CF]|->',
#	'name contains rare characters (#=;%°@$?!)',

	# bad ending
	'\w+(ation|ism)s?$',
#	"bad ending 'ation' or 'ism'",

	# bad beginning
	'^\w+(ation)s? of ',
#	"bad start '..ation of'",

	# name seems to be chemical compound
	# compounds get also filtered by the "filtering procedure" (compound ending-file)
	'(^| )\S*(radical|ox[yi]gen|nitrogen|formiate|calcium|magnesium|kalium|ammonium|ose)s?$',
#	'chemical compound',

	# name seems to be a physical unit
	'(\/|^\d+ ?)(cm2|[nm]?mol|ml|kg|l|h|mg|g|min)( |$)',
#	'name looks like a physical unit',

	# name seems to be an author's name
	'\bet( \.)? al\b',
#	'name seems to be an author\'s name',

	# name patterns is very unlikely to be a protein name
	'(^\w\/\w$|^\d[a-z])',
#	'name matches unlikely pattern',

);
@pats_sensitive = ( # exclusion patterns for found protein names (words that are definitely not protein names)
				# paterns are case sensitive
	# pubmed stuff
	'^(PMID|PubMed|USA)$',#|APPROACH|RESULTS?|(EXPERIMENTAL )?DESIGN|SETTING|SAMPLE|(MATERIALS AND )?METHODS?|CONCLUSIONS?|REVIEW|OBJECTIVES?|BACKGROUND|PURPOSE( OF REVIEW)?|(RECENT )?FINDINGS|SUMMARY|OBJECTIVES)$',
#	'common pubmed abstract words',

	# mutations
	'^([ACDEFGHIKLMNPQRSTVWY]|Ala(nine)?|Cys(teine)?|Asp(aragine)?|Glu(tamine)?|Phe(nylalanine)?|Gly(cine)?|His(tidine)?|Ile|Isoleucine|Lys(ine)?|Leu(cine)?|Met(hionine)?|Asn|Aspartic acid|Aspartate|Pro(line)?|Gln|Glutamic acid|Glutamate|Arg(inine)?|Ser(ine)?|Thr(eonine)?|Val(ine)?|Trp|Tryptophane|Tyr(osine)?)\d{2,4}([ACDEFGHIKLMNPQRSTVWY]|Ala(nine)?|Cys(teine)?|Asp(aragine)?|Glu(tamine)?|Phe(nylalanine)?|Gly(cine)?|His(tidine)?|Ile|Isoleucine|Lys(ine)?|Leu(cine)?|Met(hionine)?|Asn|Aspartic acid|Aspartate|Pro(line)?|Gln|Glutamic acid|Glutamate|Arg(inine)?|Ser(ine)?|Thr(eonine)?|Val(ine)?|Trp|Tryptophane|Tyr(osine)?)$', # usually no mutation in 1st 10 residues
#	'name looks like a mutation',

	# aminoacids
	'^(Ala|Cys|Asp|Glu|Phe|Gly|His|Ile|Lys|Leu|Met|Asn|Pro|Gln|Arg|Ser|Thr|Val|Trp|Tyr)$',
#	'name looks like an aminoacid',

	# aminoacids plus position
	'^[ACDEFGHIKLMNPQRSTVWY]\d{3}$', # 
#	'name looks like an aminoacid',

	# name seems to be internet address
	'(^(ht|f)tp://)|(\.html?)|(\.(com|de|uk|il|it|gov|edu|es|fr|nl|dk|ru|jp|ca|net)$)',
#	'name seems to be an internet address',

	# name ends in ion-symbol plus charge information
	'(^|\W)(Ca|K|Na|H|Mg|Li|Fe|Ni|Mn|H|O|S|N|P)\W?\(?\d[+\-]+\)?(\D.{0,2})?$',
#	'name looks like an ion',

	# name looks like a name
	'^[A-Z]\. ?[A-Z][a-z]{4,}$',
#	'name looks like a persons name',

	# name looks like a dna-sequence
	'^[AGTC]{5,}$',
#	'name looks like a DNA sequence',

	# name looks like an rna-sequence
	'^[AGUC]{5,}$',
#	'name looks like an RNA sequence',

	# name looks like an rna/dna-type
	'^([A-Z]?[a-z]+[RD]NAs?|RNAi|NADP?H?\+?)$',
#	'name looks like an RNA/DNA type',

	# name looks like a Swedberg value or a decade (1960ies | 1950s | 50ies)
	'^(\d+[ \-]?S|[12]?[890]?\d0(ies|s))$',
#	'name looks like a Swedberg (S) value or decade',

	# name patterns is very unlikely to be a protein name
	'^([A-DF-Z]\d|[A-Z]I{1,3}|[a-z]\.[a-z]\.?|\d+:\d+.*|\w\(-?\d+\))$',
#	'name matches unlikely pattern',

	# name seems to be a physical unit (2)
	'^(pH|pK[asb]?|pI)( =? ?[\d.]+|\(\w\))?$',
#	'name looks like a pK/pH unit',

	# name seems to be nucleotide
	'^(nt[- ]?\d+|p?([ACGTU]p)+[ACGTU]p?|[dc]?[AGCTU][TDM]P|c?N[TDM]Ps?)$',
#	'name looks like a nucleotide',

);

# -------------------------------------------------------
# Variables
# -------------------------------------------------------
$pubmed_html = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=";

$array = join(" ", @ARGV);
if ($array !~ /-i/ || $array !~ /-o/) {
	die2 ("You have to give an input- and output-filename as an option!\nPlease read the README.txt file for more information.\n");
}

$window = 9;
$half_window = round($window / 2, "down");
$max_number_of_words_in_protein_name = 5;
$prtnm = "prtnm";

# DBM-things
$dbfile = $path_app_data . "dictionary_sp_tr.db";
 #$dbfile = $path_app_data . "test.db";
dbmopen(%sp_tr_names, $dbfile, 0644);# or die "Error opening sp_tr.db-file!\n";


# --------------------------------------------------------
# command line options
# --------------------------------------------------------
$species = "1";
$outformat = "html";
$informat = "txt";
$database = "sptr";
$fasta = "0";

while ($par = shift(@ARGV)) {
	if ($par !~ /^-(f|d|i|o|s|n|a)$/) {
		die2("Invalid Option $par from @ARGV Please read the README.txt file for more information.\n");
	}
	elsif ($par eq "-i") {
		$val = shift(@ARGV);
		if (! -e $val) {die2 ("Could not find the natural-text input file $val.");}else {$input = $val;}
	}
	elsif ($par eq "-o") {
		$val = shift(@ARGV);
		if (-e $val) {
			print "The given outputfile already exists! Overwrite (y/n)?\n>";
			#$par = <STDIN>; chomp($par);
			$par = "y";
			if ($par ne "y") {
				print "\nNLProt terminated!\n";
				exit;
			}
		}
		if (! open(F, ">$val")) {die2 ("Could not open the output file $val. Maybe a directory does not exist.\n");}
		else {close F;$output = $val;}
	}
	elsif ($par eq "-d") {
		$val = shift(@ARGV);
		if ($val !~ /^(sp|tr|sptr)$/i) {
			die2 ("Invalid database $val!\nOnly 'sp', 'tr' or 'sptr' allowed.\n");
		}
		else {
			$database = $val;
		}
	}
	# output format (text or html)
	elsif ($par eq "-f") {
		$val = shift(@ARGV);
		if ($val !~ /^(html|txt)$/i) {
			die2 ("Invalid output-format $val!\nOnly 'html' or 'txt' allowed.\n");
		}
		else {
			$outformat = $val;
		}
	}
	# input format (text or ids)
	elsif ($par eq "-n") {
		$val = shift(@ARGV);
		if ($val !~ /^(txt|ids)$/i) {
			die2 ("Invalid input-format $val!\nOnly 'txt' or 'ids' allowed.\n");
		}
		else {
			$informat = $val;
		}
	}
	# species mode (only give ID which matches protein name && species!)
	elsif ($par eq "-s") {
		$val = shift(@ARGV);
		if ($val !~ /^(off|on)$/i) {
			die2 ("Invalid species option $val!\nOnly 'on' or 'off' allowed.\n");
		}
		else {
			$species = ($val eq "on" ? 1 : 0);
		}
	}
	# fasta file for found proteins
	elsif ($par eq "-a") {
		$val = shift(@ARGV);
		if ($val !~ /^(off|on)$/i) {
			die2 ("Invalid fasta option $val!\nOnly 'on' or 'off' allowed.\n");
		}
		else {
			$fasta = ($val eq "on" ? 1 : 0);
		}
	}
}
# --------------------------------------------------------------------

writelog("Reading databases and dictionaries ...\n");

# ------------------------------------------
# get PUBMED articles
# ------------------------------------------
if ($informat eq "ids") {
	my($real_input, $aut, $dep, $title, $abstr);
	open(IN, "<$input") or die2("Could not open input-file for reading: $input!");
	while (<IN>) {
		chomp();
		$html = get($pubmed_html . $_);
		if ($html =~ /<br><font size="\+1"><b>([^<]+)<\/b><\/font><br><br><b>([^<]+)<\/b><br><br>([^<]+)<br><br>([^<]+)</) {
			$title = $1; $aut = $2; $dep = $3; $abstr = $4;
			$aut =~ s/ /=s=/g;
			$dep =~ s/ /=s=/g;
			$real_input .= "$_>$title $aut $dep $abstr\n";
		}
		else {
			$real_input .= "$_>Your=s=submitted=s=PubMed=s=ID=s=($_)=s=did=s=not=s=return=s=any=s=PubMed=s=abstract!\n";
		}
	}
	close IN;
	open(IN, ">$input") or die2("Could not open input-file for writing: $input!");
	print IN $real_input;
	close IN;
}
else { # test input file for right format
	writelog("Checking input-file for formatting errors. ");
	open(IN, "<$input") or die2("\nCould not open input-file: $input!");
	while (<IN>) {
		chomp();
		if ($_ !~ /^(\d+)>(.+)/) {
			die2("\nLine $. of your input file has a wrong format:\nEach line has to start with a number (article ID) followed by '>' and the article/abstract.\n".
				"Example:\n189384532>text text text text etc ...\n\nPlease read the README.txt file for more information about the required input format.\n");
		}
	}
	close IN;
	writelog("Input ok.\n");
}
# ------------------------------------------


# ------------------------------------------
# read dictionary
# ------------------------------------------

open(IN, "<${path_app_data}dictionary.txt") or die2("could not open dictionary.txt for reading. \npath=${path_app_data}dictionary.txt \n$!\n");
while (<IN>) {
#	chomp();
	if (/^(.+)\t(.+)/) {
		$dictionary{$1} = $2;
	}
}
close IN;
# ------------------------------------------

# ------------------------------------------
# read swissprot-trembl curation list
# ------------------------------------------
# open(IN, "<${path_app_data}dictionary_sp_tr_curation.txt") or die2("could not open dictionary_sp_tr_curation.txt for reading\n");
# while (<IN>) {
# #	chomp();
# 	if (/^(.+)\t(.+)/) {
# 		$sp_tr_names_curate{$1} = 1;
# 	}
# 	elsif (/^END/) {
# 		close IN;
# 	}
# }
# close IN;
# ------------------------------------------

# ------------------------------------------
# read common-words-file
# ------------------------------------------
open(IN, "<${path_app_data}common_words_not_in_sp_or_tr.txt") or die2("common_words_not_in_sp_or_tr.txt\n");
while (<IN>) {
	chomp();
	$bad_words{$_} = 1;
}
close IN;
# ------------------------------------------

# ------------------------------------------
# 1) read in-databases
# contain all protein names ending in 'in'
# like hemoglobin, etc. and tells whether
# they are protein names or not
# 2) read bad_words_in_front_of_parentheses
# ------------------------------------------
open(IN, "<${path_app_data}in_ending_negatives.txt") or die2("in_ending_negatives.txt\n");
while (<IN>) {
	chomp();
	$in_neg{"\L$_"} = 1;
}
close IN;
open(IN, "<${path_app_data}good_words_in_front_of_parentheses.txt") or die2("good_words_in_front_of_parentheses.txt\n");
while (<IN>) {
	chomp();
	last if (/^END/);
	if (/^(.+)\t\d+$/) {
		$good_words_in_front_of_parentheses{"\L$1"} = 1;
	}
}
close IN;
# --------------------------

# ------------------------------------------
# read tissue and species-databases
# ------------------------------------------
open(IN, "<${path_app_data}tissue.txt") or die2("tissue.txt\n");
$num = 1;
while (<IN>) {
	chomp();
	$tissue_names{$_} = $num;
	$tissue_names[$num] = $_;
	$hash = "tis_" . substr($_, 0, 1);
	$key = substr($_, 0, 8);
	$key =~ s/ .+//;
	${${$hash}{$key}}{$_} = 1;
	$num ++;
}
close IN;
open(IN, "<${path_app_data}species.txt") or die2("species.txt\n");
$num = 1;
while (<IN>) {
	chomp();
	if (/^(.+)\t(\w+)/) {
		$spec = $1;
		$org_code = $2;

		$spec2 = $spec3 = $spec;
		if ($spec2 =~ s/^(\w+) (\w+)/\1/) {
			$spec3 = $2;
		}

		$species_codes{$spec} = $org_code;
		$species_names{$spec} = $num;
		$species_names{$spec2} = $num + 1;
		$species_names{$spec3} = $num + 2;
		$species_names[$num] = $spec;
		$species_names[$num + 1] = $spec2;
		$species_names[$num + 2] = $spec3;

		$hash = "spec_" . substr($spec, 0, 1);
		$key = substr($spec, 0, 8);
		$key =~ s/ .+//;
		${${$hash}{$key}}{$spec} = 1;
	}
	else {
		die2("Error in species.txt file wrong format in line $.\n");
		exit();
	}
	$num += 3;
}
close IN;

# read TrEMBL-species links
if ($species) {
	open(IN, "<${path_app_data}trembl_species_links.txt") or die2("trembl_species_links.txt\n");
	while (<IN>) {
		if (/^>(\w+)/) {
			$spec = $1;
		}
		elsif (/^(\w+)/) {
			$trembl_sp{$1} = $spec;
		}
	}
	close IN;
}
# --------------------------

# ------------------------------
# read chemical-endings database
# 4-letter endings for chemical compounds
# (no protein names)
# and mineral database
# ------------------------------
open(F, "<${path_app_data}chemical_compounds_endings.txt") or die2("could not open chemical_compounds_endings.txt file\n");
while (<F>) {
	chomp();
	if (/^\d+\t(\w+)/) { # each ending = 4-6 letters
		$chemical_compounds_endings{"\L$1"} = 1;
	}
}
close F;
open(F, "<${path_app_data}minerals.txt") or die2("could not open minerals.txt file\n");
while (<F>) {
	chomp();
	if (/^(\S+)\t(\S+)/) {
		$name = $1; $formula = $2;
		$name =~ s/^\W+|\W+$//g;
		$formula =~ s/^\W+|\W+$//g;
		$mineral_names{"\L$name"} = 1;
		$mineral_formulas{"$formula"} = 1;
	}
}
close F;
# --------------------------


# --------------------------------------------------------
# Generate BLAST-species-name databases
# !only needs to be done once!
# --------------------------------------------------------
if (! -e $path_app_db) {
	print '
The databases for assigning UniProt IDs (SWISSPROT/TrEMBL) to found names have to be gererated now.
These files will take another ~50Mb on your harddrive.
It will take about 20 minutes on a 2GHz machine to finish this job.
Fortunately this database generation is only necessary once and only if you want to assign Database IDs to the found names.
Should I go ahead (y), skip this step for now (n) OR always skip this step from now on and NEVER ask you again (a)?
>';
	$par = <STDIN>; chomp($par);
	if ($par eq "n") {
		print "\nSkipped database generation! I will ask you again next time you run NLProt.\n";
	}
	elsif ($par eq "a") {
		mkdir($path_app_db);
		print "\nSkipped database generation! I will not ask you again next time you run NLProt.\nHowever, if you want to generate the databases later, please delete the directory ${path_app_db} on your computer and run NLProt again.\n";
	}
	else {
		%already_open = ();
		print "Generating databases .. (please be patient)\n";
		mkdir($path_app_db);
		foreach $letter ("a" .. "z") {
			mkdir($path_app_db . "$letter");
		}
		# generate BLAST-DBs
		$x = 0;
		#{
		#$name = "grf-9";
		foreach $name (keys(%sp_tr_names)) {
			if (! ($x % 10000)) {
				writelog(".");
			}
			@ids = split(/:/, $sp_tr_names{$name});
			shift(@ids); # empty ID, because $ids starts with ":"
			foreach $id (@ids) {
				if ($id =~ /_(\w+)/) {
					$org = "\U$1";
				}
				else {
					$org = "\U$trembl_sp{$id}";
				}
				open($org, ">${path_app_db}" . substr("\L$org", 0, 1) . "/\L$org") if (! $already_open{$org});
				print $org ">${id}___$name\n" . text_to_nucleotide($name) . "\n" if ($name);
				$already_open{$org} = 1;
			}
			$x ++;
		}

		# close all files
		foreach $fh (keys(%already_open)) {
			close $fh;
		}

		writelog("\nCreating binary database-files for all organisms:\n");
		foreach $letter ("a" .. "z") {
			writelog("$letter.");
			opendir(DIR, $path_app_db . $letter);
			@files = grep(/\w/, readdir(DIR));
			closedir(DIR);
			foreach $file (@files) {
				system("formatdb -i $path_app_db$letter/$file -p F");
				#unlink("$path_app_db$letter/$file"); # delete text file
			}
		
		}
		print "\nDatabases generated!\n";

	}
}
# --------------------------------------------------------


# --------------------------
# read word-db-file
# --------------------------
open(F, "<${path_app_data}word_frequencies.txt") or die2("could not open word_frequencies.txt file\n");
$_ = <F>; # window size
if ($_ !~ /^WINDOW=(\d+)/i) { print "Error in word_frequencies.txt: no WINDOW information!\n"; exit();}
$window = $1; $half_window = round($window / 2, "down");
$_ = <F>; # number of features
if ($_ !~ /^NUMFEATURES=(\d+)/i) { print "Error in word_frequencies.txt: no NUMFEATURES information!\n"; exit();}
$num_features = $1;
$_ = <F>; # max number of words in protein name
if ($_ !~ /^NUMWORDSINNAME=(\d+)/i) { print "Error in word_frequencies.txt: no NUMWORDSINNAME information!\n"; exit();}
$max_number_of_words_in_protein_name = $1;
$_ = <F>; # short for protein name
if ($_ !~ /^PRTNAME=(\w+)/i) { print "Error in word_frequencies.txt: no PRTNAME information!\n"; exit();}
$prtnm = $1;
$count = 0;
while (<F>) {
	$count ++;
	chomp();
	if (/^(\d+)\t(.*)/) {
		if ($count <= $num_features) {
			$words{$2} = $count;
		}
	}
}
close F;
# --------------------------
# --------------------------
# read word-db_names-file
# --------------------------
open(F, "<${path_app_data}word_frequencies_names.txt") or die2("could not open word_frequencies_names.txt file\n");
$_ = <F>; # number of features
if ($_ !~ /^NUMFEATURES=(\d+)/i) { print "Error in word_frequencies.txt: no NUMFEATURES information!\n"; exit();}
die2("different NUMFEATURES values in 1 and 2 SVM-word-lists!\n") if ($1 != $num_features);
$num_features = $1;
$count = 0;
while (<F>) {
	$count ++;
	chomp();
	if (/^(\d+)\t(.*)/) {
		if ($count <= $num_features) {
			$words_name{$2} = $count;
		}
	}
}
close F;
# --------------------------
# --------------------------
# read word-db_overlap-file
# --------------------------
open(F, "<${path_app_data}word_frequencies_overlap.txt") or die2("could not open word_frequencies_overlap.txt file\n");
$_ = <F>; # number of features
if ($_ !~ /^NUMFEATURES=(\d+)/i) { print "Error in word_frequencies.txt: no NUMFEATURES information!\n"; exit();}
die2("different NUMFEATURES values in 2 and 5 SVM-word-lists!\n") if ($1 != $num_features);
$num_features = $1;
$count = 0;
while (<F>) {
	$count ++;
	chomp();
	if (/^(\d+)\t(.*)/) {
		if ($count <= $num_features) {
			$words_overlap{$2} = $count;
		}
	}
}
close F;
# --------------------------


# --------------------------
# read input file
# --------------------------
open(IN, "<$input") or die2("Could not open input-file: $input!");
$input_line = 0;
while ($inputtext = <IN>) {
	chomp($inputtext);
	$input_line ++;
	writelog("\nReading input file. Line $input_line ...\n");
	$inputtext =~ /^(\d+)>(.+)/;
	$title = $1; $inputtext = $2;

$original_inputtext = "\L$inputtext";

# separate point at end
$inputtext =~ s/\.$/ ./;

# process abstract
$inputtext =~ s/(<\/?[^>]+>)+/ /g; # replace html-tags
$inputtext =~ s/&quot;/"/g; # replace quote-tags
$inputtext =~ tr/\[\{\}\]/(())/; # replace weird parentheses
$inputtext =~ s/&\w+;/ /g; # replace other-tags
$inputtext =~ s/PMID: \d+ .{0,40}$//; # replace end bs  "[PubMed - in process]</dd>"

# make punctuation important
$inputtext =~ s/([,.!?:;]) / \1 /g;

# original solution
# (EBNA2(-) LMP1(-)) => ( EBNA2(-) LMP1(-) )
# (EBNA2(-)/LMP1(-)) => ( EBNA2(-)/LMP1(-) )
$inputtext =~ s/ \(([^()]*)\(([^)]+)\)([^()]*)\(([^()]+)\)\s*\)([ \-'"])/' ( '.$1.'('.$2.')'.$3.'('.$4.')'.' ) '.$5/eg;
# (EBNA2(-)/LMP1) => ( EBNA(-)/LMP1 )
$inputtext =~ s/ \(([^()]*)\(([^)]+)\)([^()]*)\)([ \-'"])/' ( '.$1.'('.$2.')'.$3.' ) '.$4/eg;
# (bla) simple parentheses
$inputtext =~ s/ \(([^()]+)\)([ \-'"])/ ( \1 ) \2/g;
# (bla) again simple parentheses for '(bla) (bla)' problem
$inputtext =~ s/ \(([^()]+)\)([ \-'"])/ ( \1 ) \2/g;

$inputtext = ("endtag " x $half_window) . $inputtext . (" endtag" x ($half_window + $max_number_of_words_in_protein_name));

# ----------------------------------------------------------
# Find organisms and tissue in text, replace them by tags
# and store their positions
# ----------------------------------------------------------
$what = "";
$code = '$num_code = $what . ($what eq "spec_" ? $species_names{$name} : $tissue_names{$name}); " $num_code ";';

@text = split(/ +/, $inputtext);
foreach $what ("spec_", "tis_") {
word:
	foreach $word (@text) {
		next if ($word eq "endtag");
		$hash = $what . substr("\L$word", 0, 1);
		$key = substr("\L$word", 0, 8);
plural_s:
		foreach $name (sort sort_len keys %{${$hash}{$key}}) {
			$inputtext =~ s/ $name /eval($code)/ieg;
		}

		if ($plural_s) {
			$plural_s = 0;
		}
		elsif (length($word) <= 8 && $key =~ /s$/) {
			$key =~ s/s$//;
			$plural_s = 1;
			goto plural_s;
		}
	}
}
# convert roman numbers into digits
$inputtext =~ s/( )([IXV]+)( )/$1.conv_roman($2).$3/ieg;
# remove double spaces
$inputtext =~ s/ +/ /g;

# need @abstracts for filter-function in special.pm
$abstracts[0] = $inputtext;
# -----------------------------------
writelog("Sampling input text ... ");


# --------------------------------------
# calculate @vecs
# --------------------------------------
$st = 0;
@text = split(/ +/, $inputtext);
$prt = round(scalar(@text) / 10);
$prt_count = 0;
@vecs = ();

vector:
for (my($x) = 1; $x < (scalar(@text) - $window + 1 - $max_number_of_words_in_protein_name + 1); $x ++) {
	
	$prt_count ++;
	if ($prt_count == $prt) {
		$prt_count = 0;
		$st += 10;
		writelog("$st% . ");
	}
	
	for (my($y) = 0; $y <= ($max_number_of_words_in_protein_name - 1); $y ++) {
		# build $sent (as part of the test-text)
		@sent = (); $name = "";
		for (my($z) = $half_window; $z <= $half_window + $y; $z ++) { # real protein name
			$name .= " " . $text[($x - 1 + $z)]; # real protein name
		}
		$name = substr($name, 1);
		@name = split(/ +/, $name);
#		if (filter($name, 0)) { # 0 = abstract-number
			$filter = 1;
			for (my($z) = 0; $z < $half_window; $z ++) {
				push(@sent, $text[($x - 1 + $z)]);
			}
			push(@sent, $prtnm); # protein name replacement
			for (my($z) = ($half_window + 1); $z < ($half_window * 2 + 1); $z ++) {
				push(@sent, $text[($x - 1 + $z + $y)]);
			}
			if (scalar(@sent) != $window) {
				print "Error @sent is not $window words long!\n";
				next vector;
			}

			$sent = join(" ", @sent);
			$overlap = $sent[$half_window - 1] . " " . $name[0] . " " . $name[$#name] . " " . $sent[$half_window + 1];
			push(@vecs, [$filter, $sent, $overlap, $name, ($x + $half_window - 1), ($y + 1)]);
#		}
#		else {
##			$filter = 0;
#		}

	}
}
# ----------------------------------
writelog("100%\n");
writelog("Running 1st SVM ...\n");

# --------------------------------------
# generate svm-1 file
# --------------------------------------
open(OUT, ">${path_app_tmp}svm_classify_1_$$.txt") or die2("could not open svm_classify_1_$$.txt file\n");
$block = scalar(keys(%words));
vector1:
foreach my $vec (@vecs) {
	($filter, $text, $overlap, $name, $pos, $len) = @{$vec};
	#$feat_count ++;
	@sent = split(/ +/, $text);
	if (scalar(@sent) != $window) {
		print "***** Error $text is not $window words long!\n";
		next vector1;
	}
	# replace punctuations
	map($_ =~ s/,/k_omma/g, @sent);
	map($_ =~ s/;/s_emikolon/g, @sent);
	map($_ =~ s/\./p_unkt/g, @sent);
	map($_ =~ s/:/d_oppelpunkt/g, @sent);
	map($_ =~ s/\(/k_auf/g, @sent);
	map($_ =~ s/\)/k_zu/g, @sent);
	map($_ =~ s/!/a_usrufezeichen/g, @sent);
	map($_ =~ s/\?/f_ragezeichen/g, @sent);
	
	map($_ =~ s/^\W+|\W+$//g, @sent);
	print OUT "1";
	print OUT " 1:" . length($name);
	%array = ();

	for (my($x) = 0; $x <= 2; $x ++) {
		$word = $sent[$x];
		process_svm_1($word);
		if ($word) {
			$array{$word} = ($x + 1) * 0.25;
		}
	}
	for (my($x) = 3; $x <= 3; $x ++) {
		$word = $sent[$x];
		process_svm_1($word);
		if ($word) {
			$array{($block + $word)} = 1;
		}
	}
	for (my($x) = 5; $x <= 5; $x ++) {
		$word = $sent[$x];
		process_svm_1($word);
		if ($word) {
			$array{(($block * 2) + $word)} = 1;
		}
	}
	for (my($x) = 6; $x <= 8; $x ++) {
		$word = $sent[$x];
		process_svm_1($word);
		if ($word) {
			$array{(($block * 3) + $word)} = ($window - $x) * 0.25;
		}
	}
	foreach (sort sort_num_1 keys(%array)) {
		print OUT " " . ($_ + 1) . ":$array{$_}";
	}
	
	print OUT "\n";
}
close OUT;
# ----------------------------------
# ----------------------------------
# run 1st SVM
# add score from 1st SVM to each vector
# ----------------------------------
system("${path_app}svmc ${path_app_tmp}svm_classify_1_$$.txt ${path_app_data}svm_model_1_j10.txt ${path_app_tmp}svm_out_1_$$.txt > ${path_app_tmp}svm_output_$$.txt");
open(F, "<${path_app_tmp}svm_out_1_$$.txt") or die2("Could not open svm_out_1_$$.txt!\n");
$slot = 0;
while (<F>) {
	chomp();
	${$vecs[$slot]}[6] = $_;
	$slot ++;
}
close F;
# ----------------------------------
writelog("Running 2nd SVM ...\n");

# ----------------------------------
# create 2nd svm_file
# ----------------------------------
open(OUT, ">${path_app_tmp}svm_classify_2_$$.txt") or die2("could not open svm_classify_2_$$.txt file\n");
foreach my $vec (@vecs) {
	($filter, $text, $overlap, $name, $pos, $len, $score1) = @{$vec};
	print OUT "1";

#	name_features($name);

	$start = 1;# if (! $start);
	$block = scalar(keys(%words_name));
	$num_word = 0;

	$name =~ s/(.|^)(alpha|sigma|beta|gamma|kappa|eps[iy]lon|zeta|delta)(.|$)/\1-\2-\3/ig;
	$name =~ s/(.|^)(alpha|sigma|beta|gamma|kappa|eps[iy]lon|zeta|delta)(.|$)/\1-\2-\3/ig; # in case of "alphabetaalhabetaalpha"
	$name =~ s/^\W+|\W+$//g;

	my(@names) = split(/[ \-]+/, $name);
	# replace punctuations
	map($_ =~ s/,/k_omma/g, @names);
	map($_ =~ s/;/s_emikolon/g, @names);
	map($_ =~ s/\./p_unkt/g, @names);
	map($_ =~ s/:/d_oppelpunkt/g, @names);
	map($_ =~ s/\(/k_auf/g, @names);
	map($_ =~ s/\)/k_zu/g, @names);
	map($_ =~ s/!/a_usrufezeichen/g, @names);
	map($_ =~ s/\?/f_ragezeichen/g, @names);
	
	map($_ =~ s/^\W+|\W+$//g, @names);
	map($_ = "\L$_", @names);
	map($_ = ($_ =~ /^(was|were|is|are|am|be|being|been)$/ ? "tobe" : $_), @names);
	map($_ = ($_ =~ /^\d+$/ ? "numb" : $_), @names);
	map($_ = ($_ eq "" ? "other_symbol" : $_), @names);

	print OUT " $start:" . scalar(@names);
		
	# first word in name
	$word = $names[0];
	process_svm_2();
	print OUT " " . ($word + 1 + $start)  . ":1" if ($word);

	# last word in name
	$word = $names[$#names];
	process_svm_2();
	print OUT " " . ($block + $word + 1 + $start)  . ":1" if ($word);

	# word-bag in middle of name
	%array = ();
	for(my($x) = 1; $x < $#names; $x ++) {
		$word = $names[$x];
		process_svm_2();
		if ($word) {
			$array{(($block * 2) + $word + 1 + $start)} = 1;
		}
	}

	foreach (sort sort_num_1 keys(%array)) {
		print OUT " $_:$array{$_}";
	}		
		
	print OUT "\n";
}
close OUT;
# ---------------------------------
# ----------------------------------
# run 2nd SVM
# add score from 2nd SVM to each vector
# ----------------------------------
system("${path_app}svmc ${path_app_tmp}svm_classify_2_$$.txt ${path_app_data}svm_model_2_j10.txt ${path_app_tmp}svm_out_2_$$.txt > ${path_app_tmp}svm_output_$$.txt");
open(F, "<${path_app_tmp}svm_out_2_$$.txt") or die2("Could not open svm_out_2_$$.txt!\n");
$slot = 0;
while (<F>) {
	chomp();
	${$vecs[$slot]}[7] = $_;
	$slot ++;
}
close F;
# ----------------------------------
writelog("Running 3rd SVM ...\n");

# -----------------------------------------
# create 5th svm-file
# -----------------------------------------
$block = scalar(keys(%words_overlap));
$" = ":1 ";
open(OUT, ">${path_app_tmp}svm_classify_5_$$.txt") or die2("could not open svm_classify_5_$$.txt file\n");
vector5:
foreach my $vec (@vecs) {
	($filter, $text, $overlap, $name, $pos, $len, $score1, $score2) = @{$vec};
	@sent = split(/ +/, $overlap);
	if (scalar(@sent) != 4) {
		print "***** Error $overlap is not 4 words long!\n";
		next vector5;
	}
	# replace punctuations
	map($_ =~ s/,/k_omma/g, @sent);
	map($_ =~ s/;/s_emikolon/g, @sent);
	map($_ =~ s/\./p_unkt/g, @sent);
	map($_ =~ s/:/d_oppelpunkt/g, @sent);
	map($_ =~ s/\(/k_auf/g, @sent);
	map($_ =~ s/\)/k_zu/g, @sent);
	map($_ =~ s/!/a_usrufezeichen/g, @sent);
	map($_ =~ s/\?/f_ragezeichen/g, @sent);
	
	map($_ =~ s/^\W+|\W+$//g, @sent);

	print OUT "1";
	%array = ();
	for (my($x) = 0; $x <= 3; $x ++) {
		$word = $sent[$x];
		process_svm_5($word);
		if ($word) {
			$array{(($block * $x) + $word)} = 1;
		}
	}
	foreach (sort sort_num_1 keys(%array)) {
		print OUT " $_:$array{$_}";
	}
	print OUT "\n";
}
close OUT;
# --------------------------------


# ----------------------------------
# run 5th SVM
# add score from 5th SVM to each vector
# ----------------------------------
system("${path_app}svmc ${path_app_tmp}svm_classify_5_$$.txt ${path_app_data}svm_model_5_j10.txt ${path_app_tmp}svm_out_5_$$.txt > ${path_app_tmp}svm_output_$$.txt");
open(F, "<${path_app_tmp}svm_out_5_$$.txt") or die2("Could not open svm_out_5_$$.txt!\n");
$slot = 0;
while (<F>) {
	chomp();
	${$vecs[$slot]}[8] = $_;
	$slot ++;
}
close F;
# ----------------------------------
writelog("Running 4th SVM ...\n");


# -----------------------------------------
# find dictionary entries
# -----------------------------------------
$slot = 0;
foreach my $vec (@vecs) {
	($filter, $text, $overlap, $name, $pos, $len, $score1, $score2, $score5) = @{$vec};
	($score, $ids) = get_protein_dic_entry($name);
	${$vecs[$slot]}[9] = $score;
	${$vecs[$slot]}[10] = $ids;

	$slot ++;
}
# -----------------------------------------


# ----------------------------------
# create svm-3_file
# to train SVM-3 on the first three scores plus dictionary score
# ----------------------------------
open(OUT, ">${path_app_tmp}svm_classify_3_$$.txt") or die2("could not open svm_classify_3_$$.txt file\n");
foreach my $vec (@vecs) {
	($filter, $text, $overlap, $name, $pos, $len, $score1, $score2, $score5, $dicscore, $ids) = @{$vec};
	print OUT "1 1:$score1 2:$score2 3:$score5 4:$dicscore\n";
}
close OUT;
# ---------------------------------
# ----------------------------------
# run 3rd SVM
# add score from 3rd SVM to each vector
# ----------------------------------
system("${path_app}svmc ${path_app_tmp}svm_classify_3_$$.txt ${path_app_data}svm_model_3_j1.txt ${path_app_tmp}svm_out_3_$$.txt > ${path_app_tmp}svm_output_$$.txt");
open(F, "<${path_app_tmp}svm_out_3_$$.txt") or die2("Could not open svm_out_3_$$.txt!\n");
$slot = 0;
while (<F>) {
	chomp();
	${$vecs[$slot]}[11] = $_;
	$slot ++;
}
close F;
# ----------------------------------


# -----------------------------------------
# Filtering:
# -----------------------------------------
writelog("Filtering ... \n");

@vecs2 = @vecs;
@vecs = ();
filter:
foreach $vec (@vecs2) {
	($filter, $text, $overlap, $name, $pos, $len, $score1, $score2, $score5, $dicscore, $ids, $score3) = @{$vec};
	# some correction of SVM3-output (final SVM) (not necessarily kick out everything < 0 (if strong dictionary entry))
	next filter if ((! $filter) || ($score3 < -1 && $dicscore < 1));
	next filter if ($score3 < 0 && ($dicscore < 0.5 || ($score1 < 0 && $score2 < 0 && $score5 < 0)));

	if (filter($name, 0)) { # 0 = abstract-number
		push(@vecs, $vec);
	}
}
# ----------------------------------

# ------------------------------------
# Fishing out overlaps after last SVM
# rule: Take highest score if there is overlap
# ------------------------------------
%already = (); # 1 if this slot is taken by a protein name
@results = ();
fish:
foreach $vec (sort sort_9_11_hl @vecs) {
	($filter, $text, $overlap, $name, $pos, $len, $score1, $score2, $score5, $dicscore, $ids, $score3) = @{$vec};
#	next fish if ($score3 < 0);

	for (my($x) = $pos; $x <= ($pos + $len - 1); $x ++) {
		if ($already{$x}) {
			next fish;
		}
	}
	for (my($x) = $pos; $x <= ($pos + $len - 1); $x ++) {
		$already{$x} = "$pos:$len";
	}
	push(@results, $vec);
}
# ------------------------------------

# ------------------------------------
# Merge names if they are adjacent
# ------------------------------------
@results2 = @results;
@results = ();
$pos_merge = -1; $pos_merge2 = -1; # impossible word-positions
foreach $vec (sort sort_4_lh @results2) {
	($filter, $text, $overlap, $name, $pos, $len, $score1, $score2, $score5, $dicscore, $ids, $score3) = @{$vec};
	# word right after name is also a name
	$after_name = $already{($pos + $len)};
	if ($after_name =~ /(\d+):(\d+)/) {
		$pos_merge = $1;
		$len += $2;
		for ($x = $pos_merge; $x <= ($pos_merge + $len - 2); $x ++) {
			$name .= " $text[$x]";
		}
		# check for triple merge (very unlikely if not impossible)
		$after_name = $already{($pos + $len)};
		if ($after_name =~ /(\d+):(\d+)/) {
			$pos_merge2 = $1;
			$len += $2;
		}
	}
	elsif ($pos == $pos_merge || $pos == $pos_merge2) {
		# correct old scores
#		$results[$#results][6] = ($score1 + $results[$#results][6]) / 2; # $score1 # scores 1, 2 and 5 do not matter
#		$results[$#results][7] = ($score2 + $results[$#results][7]) / 2; # $score2
#		$results[$#results][8] = ($score5 + $results[$#results][8]) / 2; # $score5
		$results[$#results][11] = ($score3 + $results[$#results][11]) / 2; # $score3
		($results[$#results][9], $results[$#results][10]) = get_protein_dic_entry($results[$#results][3]); # $ids
		next;
	}
	push(@results, [$filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, "SVM", $ids]);
}
# ------------------------------------


writelog("Extend found names to entire text ...\n");

# ----------------------------------------------------------
# extend already found words to
# rest of the text
# ----------------------------------------------------------
extend_names_to_rest_of_text(1); # first time extension
# ----------------------------------------------------------

# ------------------------------------------------------------------
# Process abbreviations in parentheses (length 2-5 letters)
# e.g. interleukin-6 (IL-6) => interleukin-6 does not have secure 
# ID, but IL-6 has => project IL-6 ID to interleukin-6
# ------------------------------------------------------------------
$x = -1;
%name_links = ();
$link_name = 0;
@results2 = @results;
@results = ();
foreach $vec (sort sort_2_hl @results2) {# start from end
	$x ++;
	($filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids) = @{$vec};

	# name from previous loop (inside parenthesis; abbreviation) has to be linked to this name (in front of parenthesis; long name)
	if ($link_name) {
		$name_links{"\L$name"} = $link_name;
		$name_links{$link_name} = "\L$name";
		$link_name = 0;
	}

	if ($len == 1 && $text[$pos - 1] eq "(") {
		$name2 = $name;
		$name2 =~ s/\W//g;
		@abbr = split(//, $name2);
		$long = "";
		$match = 0; # 1 = seems to be abbreviation of something in front of parentheses
		for ($y = $pos - 6; $y <= $pos - 2; $y ++) {
			$long .= " $y:$text[$y]";
		}
		if (length($name2) == 2 && $long =~ /.* (\d+):$abbr[0].*$abbr[1]/i) {
			$new_pos = $1; $match = 1;
		}
		elsif (length($name2) == 3 && $long =~ /.* (\d+):$abbr[0].*$abbr[1].*$abbr[2]/i) {
			$new_pos = $1; $match = 1;
		}
		elsif (length($name2) == 4 && $long =~ /.* (\d+):$abbr[0].*$abbr[1].*$abbr[2].*$abbr[3]/i) {
			$new_pos = $1; $match = 1;
		}
		elsif (length($name2) == 5 && $long =~ /.* (\d+):$abbr[0].*$abbr[1].*$abbr[2].*$abbr[3].*$abbr[4]/i) {
			$new_pos = $1; $match = 1;
		}
		if ($match) {
			$long =~ s/.*$new_pos://;
			$long =~ s/ \d+:/ /g;
			# put into results (may be problematic!)
			if (! $already{($pos - 2)}) {
				($new_dicscore, $new_ids) = get_protein_dic_entry($long);
				$new_len = ($pos - $new_pos - 1);
				push(@results, [$filter, $long, $new_pos, $new_len, $score3, $score1, $score2, $score5, $new_dicscore, "abbr.-ext.", $new_ids]);
				$already{$new_pos} = $new_pos.":".$new_len;
				$x ++;
				# link the two names
				$name_links{"\L$name"} = "\L$long";
				$name_links{"\L$long"} = "\L$name";
			}
			else {
				$link_name = "\L$name";
			}
		}
	}
	push(@results, [$filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids]);
}
# ------------------------------------

# ----------------------------------------------------------
# extend abbreviations from above to
# rest of the text
# ----------------------------------------------------------
extend_names_to_rest_of_text(2); # second time extension
# ----------------------------------------------------------


# ----------------------------------------------------------
# Find organisms for all found proteins
# and keep only most likely ID for each protein
# ----------------------------------------------------------
writelog("Find species names in text ...\n");
%organisms_in_text = ();
%tissues_in_text = ();
if ($species) {
	$pos = -1;
	foreach $word (@text) {
		if ($word =~ /^spec_(\d+)/) {
			$organisms_in_text{$pos} = $species_names[$1];
		}
		elsif ($word =~ /^tis_(\d+)/) {
			$tissues_in_text{$pos} = $tissue_names[$1];
		}
		$pos ++;
	}
}

@results2 = @results;
@results = ();
%names_to_blast = ();
foreach $vec (@results2) { # sort by position
	($filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids) = @{$vec};

	if (! %organisms_in_text) {
		if (! $species) {
			# do not provide organism if species-option not given
			$org_nice = "not opted";
		}
		else {
			# assign all to human (most likely case (?))
			$org = "HUMAN";
			$org_nice = "homo sapiens";
		}
	}
	else {
		# look for closest organism
		$dist = 1000000; $org = ""; $org_nice = "";
		foreach (keys(%organisms_in_text)) {
			if (($_ - $pos >= 0) && ($_ - $pos < $dist)) {
				$dist = ($_ - $pos);
				$org_nice = $organisms_in_text{$_};
				$org = $species_codes{$org_nice};
			}
			elsif (($pos - $_ >= 0) && ($pos - $_ < $dist)) {
				$dist = ($pos - $_);
				$org_nice = $organisms_in_text{$_};
				$org = $species_codes{$org_nice};
			}
		}
	}

	$ids = "\U$ids";
	# check if protein has entry for this organism (SWISS-PROT has priority before TrEMBL)
	if ($species) {
		$do_blast = 0;
		if ($database =~ /sp/ && $ids =~ /(^|:)([A-Z0-9]+_$org)($|:)/) { # SWISS-PROT
			$ids = $2 . " #100"; ## = high reliability (matches dictionary entry 100%)
		}
		elsif ($ids =~ /(^|:)[A-Z0-9]+($|:)/) { # TrEMBL
			@ids = split(/:/, $ids);
			$new_ids = "";
			map(($trembl_sp{$_} eq $org ? ($new_ids = $_) : ""), @ids);
			if ($new_ids) {
				$ids = $new_ids . " #100"; ## = high reliability (matches dictionary entry 100%)
			}
			else {
				$do_blast = 1;
			}
		}
		else { # only SWISSPROT (but not the right organism => do blast)
			$do_blast = 1;
		}

		# do blast to find correct ID
		if ((! $ids) || ($do_blast)) { # nothing found => use blast to find names
			$ids = "";
			$name2 = $name;
			$name2 =~ s/\W+/-/g;
			$name2 =~ s/([a-zA-Z])(\d)/\1-\2/g;
			$name2 =~ s/(\d)([a-zA-Z])/\1-\2/g;
			$name2 =~ s/^\W+|\W+$//g;

			$name3 = $name2;
			$name3 =~ s/\W/_/g;

			$names_to_blast{$org} .= ">${pos}_$name3" .  "\n" . text_to_nucleotide($name2) . "\n";
		}
	}

	push(@results, [$filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids, $org_nice]);
}
# ----------------------------------------------------------

@ids = ();

if ($species) {
	writelog("Assign Database-IDs to found names ...\n");
	foreach $org (keys(%names_to_blast)) {
		open(FASTA, ">${path_app_tmp}blast_in_$$.txt") or die2("could not open blast_in_$$.txt for writing!\n");
		print FASTA $names_to_blast{$org};
		close F;
		$letter = substr("\L$org", 0, 1);

		open(STDERR, ">${path_app_tmp}blast_err.log") or die2("could not open blast_err.log file!\n");
		system("${path_app}blastall -p blastn -q -10 -r 2 -e 0.01 -b 1 -v 1 -W 9 -F F -i ${path_app_tmp}blast_in_$$.txt -d ${path_app_db}$letter/\L$org\E -o ${path_app_tmp}blast_out_$$.txt"); # add more options
		close STDERR;

		open(BLAST, "${path_app_tmp}blast_out_$$.txt") or die2("could not open blast_out_$$.txt for reading!\n");
		while (<BLAST>) {
			if (/Query= (\d+)_(\w+)/) { # found name
				$pos = $1; $name = $2;
				$hits = 1;
				$_ = <BLAST>;
				if ($_ !~ /\((\d+) letters\)/) {
					$_ = <BLAST>; /\((\d+) letters\)/ or die2("wrong blast pattern in blast_out_$$.txt line $.\n");
				}
				$querylen = ($1 / 4);
				($qstart, $qstop, $sstart, $sstop) = (0, 100000, 0, 100000);
			}
			elsif (/^>(\w+)___(\S+)/) { # db-name
				$dbid = $1; $dbname = $2;
				$_ = <BLAST>;
				while ($_ !~ /Length = (\d+)/) {
					/^\s*(\S+)/ or die2("wrong blast pattern in blast_out_$$.txt line $.\n"); $dbname .= $1; $_ = <BLAST>;
				}
				/Length = (\d+)/ or die2("wrong blast pattern in blast_out_$$.txt line $.\n");
				$dblen = ($1 / 4);
				$_ = <BLAST>; $_ = <BLAST>; $_ = <BLAST>;
				/Identities = (\d+)\/(\d+) \((\d+)%\)/ or die2("wrong blast pattern in blast_out_$$.txt line $.\n");
				$alilen = ($2 / 4); $pide = $3;
			}
			elsif (/Query: (\d+).*(\d+)$/) { # found name
				$qstart = $1 if ($1 < $qstart);
				$qstop = $2 if ($2 > $qstop);
			}
			elsif (/Sbjct: (\d+).*(\d+)$/) { # db-name
				$sstart = $1 if ($1 < $sstart);
				$sstop = $2 if ($2 > $sstop);
			}
			elsif (/\* No hits found \*/) {
				$hits = 0;
			}
			elsif (/^Matrix:/ && $hits) { # end of alignment => do calculations
				if (
					($name =~ /(\d+|[IVX]+|[a-z][A-Z])$/ && $qstop != (length($name) * 4)) || # if number at end (alignment has to cover exact-end of name)
					(length($name) < 6 && ($qstop - $qstart != (length($name) * 4))) || 
					#(length($name) >= 6 && ($alilen < (2 + 0.6 * length($name)))) || # function for alilen vs namelen requirement (how long does alignment have to be to count as valid if protein-name has a certain length)
					#(($sstop - $sstart) > ($qstop - $qstart + 60)) || # make sure db-name is not much longer than found name
					(0)
					) {
					$ids[$pos] = "\U$dbid #1"; # not certain about selected ID (low reliability)
				}
				else {
					# calculate edit-distance (divided by average length of names)
					# the longer the names the smaller the distance
					$dist = round(100 * (1 - (fastdistance($name, $dbname) / ((length($name) + length($dbname)) / 2) / 2)));
					$ids[$pos] = "\U$dbid #$dist";
				}
			}
#			if (/(\d+)_(\w+)\s+(\w+)\s+([\d\.]+)\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+[\.\de\-]+\s+[\d\.]+/) {
#				$pos = $1; $name = $2; $dbid = $3; $pide = $4; $alilen = ($5 / 4); $start = $6; $stop = $7;
#			}
		}
		close BLAST;
	}
}


# ----------------------------------------------------------
# check for linked names (abbreviations) and assign best
# DB-ID to all names in the linked family
# ----------------------------------------------------------
$x = -1;
foreach $vec (@results) { # sort by position
	$x ++;
	($filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids, $org_nice) = @{$vec};
	if (! $ids) { # no IDs found in dictionary
		$id_status = ((! $ids[$pos]) ? 1 : ($ids[$pos] =~ /#/ ? 2 : 3)); # no IDs found by blast = 1; insecure blast = 2; secure blast = 3
	}
	else {
		$id_status = 4;
	}

	if ($name_links{"\L$name"}) {# && $id_status != 4) {
loop90:
		foreach $vec2 (@results) {
			($filter2, $name2, $pos2, $len2, $score32, $score12, $score22, $score52, $dicscore2, $why2, $ids2, $org_nice2) = @{$vec2};
			if ($name_links{"\L$name"} eq "\L$name2") {
				if (! $ids2) { # no IDs found in dictionary
					$id_status2 = ((! $ids[$pos2]) ? 1 : ($ids[$pos2] =~ /#/ ? 2 : 3)); # no IDs found by blast = 1; insecure blast = 2; secure blast = 3
				}
				else {
					$id_status2 = 4;
				}
				last loop90;
			}
		}
		if (
			($id_status != 4 && (($id_status < $id_status2) || ($id_status == $id_status2 && length($name2) > length($name)))) ||
			($id_status2 == 4 && length($name2) > length($name))
			) {
				# adopt ids from better match (batter blast or direct dictionary match)
				${$results[$x]}[10] = $ids2;
				$ids[$pos] = $ids[$pos2] if ($ids[$pos2]);
		}
	}
}


# ----------------------------------------------------------




# ----------------------------------------------------------
# Generate fasta file of sequences of found proteins
# ----------------------------------------------------------
if ($fasta) {
	open(OUT, ">$output.fasta") or die2("Could not open $output.fasta for writing!");
	foreach $vec (@results) {
		($filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids, $org_nice) = @{$vec};
		$seq = seq($ids); # no "fasta"-mode since seq-function is adapted here to fit this specific code
		print OUT $seq if ($seq =~ /^\>/);
	}
	close OUT;
}
# ----------------------------------------------------------


# --------------------------
# writing output
# --------------------------
#print "Writing output-file\n";
open(OUT, ">>$output") or die2("Could not open $output for writing!");

if ($outformat eq "html" && (! $html_head_already)) {
	print OUT '<html>
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
   <meta name="GENERATOR" content="Mozilla/4.79 [en] (X11; U; Linux 2.4.18-17.7.x i686) [Netscape]">
   <meta name="Author" content="Sven Mika">
   <meta name="Keywords" content="NLP, natural language processing, data mining, nlprot, SVM, machine learning, support vector machine, sven mika, protein names, CUBIC">
   <title>NLProt - Result Page</title>
</head>
<body bgcolor="#FFFFFF">

<tt>
NLProt output:<br>
<font color="#FF0000">red</font>' . ("&nbsp;" x 13) . 'protein names<br>
<font color="#0000FF">blue</font>' . ("&nbsp;" x 12) . 'species/organism<br>
<font color="#00AA00">green</font>' . ("&nbsp;" x 11) . 'tissue/cell types<br>
TXT-POS' . ("&nbsp;" x 9) . 'Text position of the first word of the name (note any non-word character such as "." count as one word)<br>
SCORE' . ("&nbsp;" x 11) . 'Score of NLProt (protein name if > 0)<br>
METHOD' . ("&nbsp;" x 10) . 'SVM = found by SVM<br>' . ("&nbsp;" x 16) . 'projected = found by SVM but at another position than this one<br>
' . ("&nbsp;" x 16) . 'inherited = similar to an already found name (e.g. CCR4 and CCR5)<br>
' . ("&nbsp;" x 16) . 'dictionary = strong dictionary entry (long name in protein dictionary)<br>
DB-ID(S)' . ("&nbsp;" x 8) . 'List of database identifiers for proteins with this name (in database specified in query)<br>
';

	print OUT "<br><br><font color=\"#DD0000\">A fasta file with all the sequences can be found <a href=\"ftp://cubic.bioc.columbia.edu/pub/cubic/nlprot/$$.fasta\">here</a></font>.<br>" if ($fasta);
	print OUT "\n<hr>\n";

	$html_head_already = 1; # only write html-header once!
}
elsif (! $html_head_already) {
	print OUT 'NLProt output:
<n>          protein names
<s>          species/organism
<t>          tissue/cell types
TXT-POS      Text position of the first word of the name (note any non-word character such as '.' count as one word)
SCORE        Score of NLProt (protein name if > 0)
METHOD       SVM = found by SVM;
             projected = found by SVM but at another position than this one
             inherited = similar to an already found name (e.g. CCR4 and CCR5)
             abbr.-ext. = long form of an abbreviation of an obvious protein name (e.g. "Interleucin-6 (IL-6)")
DB-ID(S)     List of database identifiers for proteins with this name (in database specified in query)
';
	print OUT "\n\nA fasta file with all the sequences can be found under the following link:\nftp://cubic.bioc.columbia.edu/pub/cubic/nlprot/$$.fasta\n" if ($fasta);
	print OUT "__________________________________________________________________________________________________________________________________________\n\n";

	$html_head_already = 1;
}

@text2 = @text; # use @text2 for tagging
$out = "";
if ((@results)) {
	$out .= "\n\nThe following protein names could be found by NLProt:\n\n";

	if ($outformat eq "txt") {
		$out .= "NAME  " . (" " x (45 - 4)) . "  ORGANISM            TXT-POS    SCORE   METHOD     DB-ID(S)\n";
	}
	else {
		$out .= "<table width=\"100%\">".
			"<tr><td width=\"28%\" bgcolor=\"#AAAAAA\"><tt>NAME</td>\n<td width=\"19%\" bgcolor=\"#AAAAAA\"><tt>ORGANISM</td>\n<td width=\"6%\" bgcolor=\"#AAAAAA\" align=right><tt>TXT-POS</td>\n<td width=\"5%\" bgcolor=\"#AAAAAA\" align=right><tt>SCORE</td>\n<td width=\"8%\" bgcolor=\"#AAAAAA\"><tt>METHOD</td>\n<td width=\"34%\" bgcolor=\"#AAAAAA\"><tt>DB-ID(S)</td></tr>\n";
	}

	foreach my $vec (sort sort_2_lh @results) {
		($filter, $name, $name_pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids, $org_nice) = @{$vec};
		$ids = $ids[$name_pos] if (! $ids);
		$name_pos_2 = $name_pos_3 = $name_pos - ($half_window - 1);
		$name_pos_2 =~ s/^(\d+)$/(" " x (5 - length($1))) . $1/e;

		$score3 = round($score3, 3);
		$score3 =~ s/^(\d+)\.?(\d*)$/"$1.$2" . ("0" x (3 - length($2)))/e;
		
		if ($score3 < 0) {
			$why = "dictionary"; $score3 = 0.001;
		}

		if ($outformat eq "txt") {
			$org_nice = substr($org_nice, 0, 18) . "." if (length($org_nice) > 19);
			$ids =~ s/ #(\d+)/" ($1" . "%)"/e;
			#$ids =~ s/ #/ (low reliability)/;
			$ids = "no ID found" if (! $ids);
			$out .= "$name  " . (" " x (45 - length($name))) .
				"  " . $org_nice  . (" " x (19 - length($org_nice))) .
				" $name_pos_2     ".
				($score3 < 0 ? "$score3" : " $score3").
				"   $why".($why eq "SVM" ? "        " : ($why =~ /projected|inherited/ ? "  " : " "))."$ids\n";
		}
		else {
			$ids =~ s/ #(\d+)/" ($1" . "%)"/e;
			$ids =~ s/^(\w+)/<a href="http:\/\/us.expasy.org\/cgi-bin\/niceprot.pl?\1">\1<\/a>/;
			#$ids =~ s/ #/ (low reliability)/;
			$ids = "no ID found" if (! $ids);
			$out .= "<tr><td bgcolor=\"#CCCCCC\"><tt><font color=\"#AA0000\">$name</font></td><td bgcolor=\"#CCCCCC\"><tt>$org_nice</td><td bgcolor=\"#CCCCCC\" align=right><tt>$name_pos_2</td><td bgcolor=\"#CCCCCC\" align=right><tt>$score3</td><td bgcolor=\"#CCCCCC\"><tt>$why</td><td bgcolor=\"#CCCCCC\"><tt>$ids</td></tr>\n";
			#$out .= "<tr><td bgcolor=\"#CCCCCC\"><tt><font color=\"#AA0000\">$name</font></td><td bgcolor=\"#CCCCCC\"><tt>$score1</td><td bgcolor=\"#CCCCCC\"><tt>$score2</td><td bgcolor=\"#CCCCCC\"><tt>$score5</td><td bgcolor=\"#CCCCCC\"><tt>$dicscore</td><td bgcolor=\"#CCCCCC\"><tt>$score3</td></tr>\n";
		}

		$text2[$name_pos] = "<n>" . $text2[$name_pos];
		$text2[$name_pos + $len - 1] = $text2[$name_pos + $len - 1] . "</n>";
	}

	# tag organisms
	foreach $pos (sort sort_num_1 keys(%organisms_in_text)) {
		$text2[$pos + 1] = "<s>" . $text2[$pos + 1] . "</s>";
	}
	# tag tissues
	foreach $pos (sort sort_num_1 keys(%tissues_in_text)) {
		$text2[$pos + 1] = "<t>" . $text2[$pos + 1] . "</t>";
	}

	$out .= "</tt></table>" if ($outformat eq "html");
}
else {
	$out .= "\n\nNo protein names could be found by NLProt!\n";
}


# Tagged $text in multiple-line-format
#foreach (@newlines) {
#	$text2[$_ - 1] .= "\n";
#}
$text2 = join(" ", @text2);
$text2 =~ s/ ([.,:;?!]( |\n))/\1/g;
$text2 =~ s/ \( / (/g;
$text2 =~ s/ \)([,.]?( |\n))/)\1/g;
$text2 =~ s/(endtag | endtag)//g;
$text2 =~ s/^ +| +$//gm;

## Tagged $text in one-line-format
 #$onelinetext = $text2;

# remove author and department protection (=s=) from pubmed articles
 #$onelinetext =~ s/=s=/ /g;
$text2 =~ s/=s=/ /g;


$out = ($outformat eq "html" ? "\n<tt>\nID: $title\n$text2" : "ID: $title\n$text2") .
	#($outformat eq "txt" ? "\nText in ONELINE-format:\n" . $onelinetext : "") .
	"\n" . $out . ($outformat eq "html" ? "\n<hr>" : "\n__________________________________________________________________________________________________________________________________________\n\n");

$out =~ s/<[ts]>([^<]*<n>[^<]+)<\/[ts]>([^<]*<\/n>)/\1\2/g; # <t><n>glial</t> fibrillary acidic protein</n>

# replace organism-tissue tags '(spec_|tis_)\d+' by real names
$out =~ s/spec_(\d+)/$species_names[$1]/g;
$out =~ s/tis_(\d+)/$tissue_names[$1]/g;

if ($outformat eq "html") {
	$out =~ s/\n/\n<br>\n/g;
	$out =~ s/(<\/t[rd]>\n)<br>/\1/g;	
	$out =~ s/<t>/<font color="#00AA00">/g;
	$out =~ s/<s>/<font color="#0000FF">/g;
	$out =~ s/<n>/<font color="#FF0000">/g;
	$out =~ s/<\/[nst]>/<\/font>/g;
}

print OUT $out;
close OUT;

# --------------------------


}# close while (<IN>) input file


open(OUT, ">>$output") or die2("Could not open $output for writing!");
print OUT "// END OF NLPROT OUTPUT";
print OUT "\n<br>\n<br><a href=\"http://www.rostlab.org/services/nlprot/submit.html\">Back to NLProt submit-page</a>\n<br>" if ($outformat eq "html");
close OUT;

# --------------------------

writelog("Job done\n");

# --------------------------------
# Write new dictionary
# --------------------------------
#open(OUT, ">${path_app_data}dictionary.txt") or warn "could not open dictionary.txt for writing\n";
#foreach (sort keys(%dictionary)) {
#	print OUT "$_\t$dictionary{$_}\n";
#}
#close OUT;
# --------------------------------


# --------------------------------
# clean up old crap from $sdir
# and fasta dir
# --------------------------------
opendir(DIR, $path_app_tmp);
@files = grep(/(classify_\d|svm_output|out_\d|blast_out|input|log|in)_$$\.txt/, readdir(DIR));
closedir(DIR);
foreach (@files) {
	if (/output_\d+\.txt/ || /blast/) {
		unlink("$path_app_tmp$_") if (-M $path_app_tmp.$_ > 1);
	}
	else {
		unlink("$path_app_tmp$_");
	}
}
# --------------------------------


# --------------------------------
# END of program
# --------------------------------

sub sort_len {
	length($b) <=> length($a);
}
sub sort_num_1 {
	$a <=> $b;
}
sub sort_1_lh {
	my($c) = ${$a}[1];
	my($d) = ${$b}[1];
	$c <=> $d;
}
sub sort_2_lh {
	my($c) = ${$a}[2];
	my($d) = ${$b}[2];
	$c <=> $d;
}
sub sort_2_hl {
	my($c) = ${$a}[2];
	my($d) = ${$b}[2];
	$d <=> $c;
}
sub sort_3_lh {
	my($c) = ${$a}[3];
	my($d) = ${$b}[3];
	$c <=> $d;
}
sub sort_3_hl {
	my($c) = ${$a}[3];
	my($d) = ${$b}[3];
	$d <=> $c;
}
sub sort_4_lh {
	my($c) = ${$a}[4];
	my($d) = ${$b}[4];
	$c <=> $d;
}

sub sort_10_hl {
	my($c) = ${$a}[10];
	my($d) = ${$b}[10];
	$d <=> $c;
}
sub sort_11_hl {
	my($c) = ${$a}[11];
	my($d) = ${$b}[11];
	$d <=> $c;
}

sub sort_9_11_hl {
	my($c) = ${$a}[9];
	my($d) = ${$b}[9];
	my($e) = ($d <=> $c);
	if (! $e) {
		$e = ${$a}[11];
		my($f) = ${$b}[11];
		$f <=> $e;
	}
	else {
		$e;
	}
}


sub process_svm_1 {
	$word = "\L$word";
	$word_orig = $word;
	$word = "tobe" if ($word =~ /^(was|were|is|are|am|be|being|been)$/); # forms of "to be"
	$word = "numb" if ($word =~ /^\d+$/);
	$word = $1 if ($word =~ /^(spec_|tis_)\d+$/);
	$word = "other_symbol" if ($word eq "");
	$word = $words{$word};
	if (! $word) {
		$dic = $dictionary{$word_orig};
		if ((! $dic) || $dic =~ /^(no|protein|abbreviation)$/) {
			$word = $words{'not_in_list'};
		}
		elsif ($word_orig =~ /(ing|ed)$/) {
			$word = $words{$dic . "_$1"};
		}
	}
}

sub process_svm_2 {
	$word_orig = $word;
	$word = "tobe" if ($word =~ /^(was|were|is|are|am|be|being|been)$/); # forms of "to be"
	$word = "numb" if ($word =~ /^\d+$/);
	$word = $1 if ($word =~ /^(spec_|tis_)\d+$/);
	$word = "other_symbol" if ($word eq "");
	$word = $words_name{$word};
	if (! $word) {
		$dic = $dictionary{$word_orig};
		if ((! $dic) || $dic =~ /^(no|protein|abbreviation)$/) {
			$word = $words_name{'not_in_list'};
		}
		elsif ($word_orig =~ /(ing|ed)$/) {
			$word = $words_name{$dic . "_$1"};
		}
	}
}

sub process_svm_5 {
	#$word = "\L$word";
	#$word = "tobe" if ($word =~ /^(was|were|is|are|am|be|being|been)$/); # forms of "to be"
	$word_orig = "\L$word";
	$word = "numb" if ($word =~ /^\d+$/);
	$word = $1 if ($word =~ /^(spec_|tis_)\d+$/);
	$word = "other_symbol" if ($word eq "");
	$word = $words_overlap{$word};
	if (! $word) {
		$dic = $dictionary{$word_orig};
		if ((! $dic) || $dic =~ /^(no|protein|abbreviation)$/) {
			$word = $words_overlap{'not_in_list'};
		}
		elsif ($word_orig =~ /(ing|ed)$/) {
			$word = $words_overlap{$dic . "_$1"};
		}
	}
}


sub writelog {
	my($st) = shift;
	print $st;
	system("");
}

# just exits instead of dying with a last message
sub die2 {
	my($comment) = shift;
	print $comment;
	exit();
}


sub filter {

	my($name) = shift;
	my($abstr_num) = shift;
	
	$abstr = @abstracts[$abstr_num];
	$delete = 0;
	$name_pat = $name;
	$name_pat =~ s/(\W)/\\\1/g;
	if (length($name) < 2) {		
		$delete = "name too short (1 character)";
		return 0;
	}
	elsif ($abstr =~ /\W$name_pat (CELLS?|cells?|Cells?)\W(?!cycle)/) { # 'cells' is case insensitive, but the protein name is not
		$delete = "name seems to be cell type/name 2";
		return 0;
	}
	elsif ($name =~ /(\w(\w(\w{4})))$/i && ($chemical_compounds_endings{"\L$3"} || $chemical_compounds_endings{"\L$2"} || $chemical_compounds_endings{"\L$1"})) {
		$delete = "chemical compound";
		return 0;
	}
	elsif (($name =~ /(form|rate|tone|enes|thal)$/i && $name !~ /(isoform|substrate|histone|genes|lethal)$/i)) {
		$delete = "chemical compound";
		return 0;
	}
	elsif ($name =~ /^(\w+in)s?([ \-]\S+)?$/ && $in_neg{"\L$1"}) {
		$delete = "$1 is not a protein name";
		return 0;
	}
	# production of inositol trisphosphate ( IP(3) )
	elsif ($abstr =~ /\w+(\w{4}) \( $name_pat/ && $chemical_compounds_endings{"\L$1"}) {
		$delete = "chemical compound";
		return 0;
	}
	# production of IP(3) ( inositol trisphosphate  )
	elsif ($abstr =~ /$name_pat \( \w+(\w{4}) \)/ && $chemical_compounds_endings{"\L$1"}) {
		$delete = "chemical compound";
		return 0;
	}
	# word matches no letters
	elsif ($name =~ /^[^a-z]+$/i && $name ne "14-3-3") {
		$delete = "word matches no letters";
		return 0;
	}
	# minerals and salts
	elsif ($mineral_names{"\L$name"}) {
		$delete = "mineral name";
		return 0;
	}
	elsif ($mineral_formulas{"$name"}) {
		$delete = "mineral formula";
		return 0;
	}
	elsif ($species_names{"\L$name"}) {
		$delete = "name of a species";
		return 0;
	}
	elsif ($tissue_names{"\L$name"}) {
		$delete = "name is a tissue-type";
		return 0;
	}
	# response element ( GRE ); matrix attachment region ( MAR )
	elsif ($abstr =~ /(\S+) (([A-Z]|\d+|[IXV]+) )?\( $name_pat (\)|;|,|and)/ && (! $good_words_in_front_of_parentheses{"\L$1"}) && $dictionary{"\L$1"} && $dictionary{"\L$1"} !~ /^(no|protein)$/) {
		$delete = "name seems to be an abbreviation for a non-protein term";
		return 0;
	}
	elsif ($abstr =~ /(spec_|tis_)\d+ (([A-Z]|\d+|[IXV]+) )?\( $name_pat (\)|;|,|and)/) {
		$delete = "name seems to be an abbreviation for a species- or tissue-name";
		return 0;
	}
	
	# only two words, starts with number => has to end in certain pattern
	elsif ($name =~ /^\S+\s+\S+$/ && $name =~ /^\d.*\b(\w+)$/ && $1 !~ /(protein|gene|factor|hormone|homolog(ue)?|collagen|pump|antibody|precursor|molecule|isoform|receptor|regulator|proteasome|allele|peptide|keratin|cytokine|chemokine|activator|transporter|ribozyme|antigen|translocator|subunit|repressor|receptor|channel|inhibitor|enzyme|ase|in)$/i) {
		$delete = "bad pattern";
		return 0;
	}

	foreach $pat (@pats_insensitive) { # special patterns that should not be protein names (case insensitive)
#		$pat = $pats_insensitive[$x];
#		$explanation = $pats_insensitive[$x + 1];
		if ($name =~ /$pat/i) {
#			$delete = $explanation;
			return 0;
		}
	}

	foreach $pat (@pats_sensitive) { # special patterns that should not be protein names (case insensitive)
#		$pat = $pats_sensitive[$x];
#		$explanation = $pats_sensitive[$x + 1];
		if ($name =~ /$pat/) {
#			$delete = $explanation;
			return 0;
		}
	}

	if ($abstr =~ /$name_pat ,([^,]{1,10},){0,5} and .{2,10} cells?/i) {
		$delete = "name seems to be cell type/name 3";
		return 0;
	}
	elsif ($abstr =~ /cell lines? $name_pat/i) {
		$delete = "name seems to be cell type/name 4";
		return 0;
		#Human breast cancer cell lines <n:288e>MCF-7<
	}
	elsif ($abstr =~ /cells? (lines? )?\( $name_pat /i) {
		$delete = "name seems to be cell type/name 5";
		return 0;
	}
	elsif ($abstr =~ /virus(\Wtype)?(\W[\di]+)? \( $name_pat \)/i) {
		$delete = "name seems to be some kind of virus";
		return 0;
		#Epstein-Barr virus ( EBV )
	}
	elsif ($abstr =~ /$name_pat( ,)?([^,]+,)* and \S{2,30}( ,)? (19|20|')\d\d\W/i && $name_pat !~ /\d/) {
		$delete = "name seems to be an author's name";
		return 0;
		#Meyers and Kornberg, 2000
	}
	elsif ($abstr =~ /$name_pat , (19|20|')\d\d\W/ && $name_pat !~ /\d/) {
		$delete = "name seems to be an author's name";
		return 0;
		#Meyers and Kornberg, 2000
	}
	elsif ($name =~ /^[A-Z][a-z]{2,}$/ && ($abstr =~ /\b$name_pat , [A-Z] ?\./ || $abstr =~ /\b[A-Z] ?\.( [A-Z] ?\.)? $name_pat/)) {
		$delete = "name seems to be an author's name";
		return 0;
		# Meyers, L. , Kornberg, B.
	}
	elsif ($abstr =~ /$name_pat (et|and)( \.)? (al|colleagues)\b/) {
		$delete = "name seems to be an author's name";
		return 0;
		#Darst et al., 2003
	}
	elsif ($abstr =~ /$name_pat .?=|= $name_pat/) {
		$delete = "name seems to be part of an equation";
		return 0;
	}
	if ($name =~ /[()]/) {
		$name2 = $name3 = $name;
		$num_open = ($name2 =~ s/\(//g);
		$num_closed = ($name3 =~ s/\)//g);
		if ($num_open != $num_closed || $name =~ /^[^(]*\)/ || $name =~ /\([^)]*$/ || $name =~ /^\(.*\)$/) {
			$delete = "parentheses conflict";
			return 0;		
		}
	}

	if ($name =~ /^\S+$/i || $name =~ /^(the|an?) \S+$/) {
		$name2 = $name;
		$name2 =~ s/(^(the|an?) )|\(s\)$//g;
		$name2 =~ s/^\W+|\W+$//g;
		$name2 =~ s/'s$//i; # cut apostroph s
		#$name2 =~ s/^(non|pre)-?(\w{3,})/\2/;
		
		if ($name2 =~ /[a-z][A-Z]/ || ($name2 =~ /^[A-Z\d]{2,}$/ && length($name) < 6)) {#($name2 =~ /^[A-Z]/ && $abstr !~ / \. $name_pat2/)) {
			# nothing
		}
		else {
			$dict = $dictionary{"\L$name2"};
			if ($dict =~ /^(no)?$/) {
				if ($name2 =~ s/^(non|pre|pro|per|co|over|under|un|de|re)-?(\w{3,})/\2/ ||
					$name2 =~ s/^(\w{3,})-?((mediat|deriv|relat|activat|inhibit|regulat|induc|transfect)(ed|ing)|bound|binding|dependent)/\1/
					) {
						$dict = $dictionary{"\L$name2"};
						$dictionary{"\L$name2"} = ($dict ? $dict : "no");
				}
				else {
					$dictionary{"\L$name2"} = "no";
				}
			}
			if ($dict !~ /^(protein|abbreviation|no)$/) {
				$delete = "name is in dictionary";
				return 0;
			}
		}
	}
	
	if ($name =~ /\s\d+$/ && $abstr =~ /$name_pat (\w+s)\b/) {
		$dict = $dictionary{"\L$1"};
		#$dict = dictionary($1);
		if ($dict eq "noun") {
			$delete = "name ends in number followed by plural noun";
			return 0;
		}
	} # cultures 3 hours after


	# --------------------------------------------
	# FORMER POST-FILTERING (why should I !post! filter if performance of svms might get better with cleaner sets??)
	# Takes long time, but only if you filter in advance (in final architecture (trained svms), I should post filter!!)
	# --------------------------------------------
	# according to common-words-list
	# derived from medline abstract words
	# that don't show up in swissprot or trembl
	# RULE: kick out everything that has a word in it which shows up frequently in medline
	# but does not show up in swissprot or trembl names
	# --------------------------------------------
	$name2 = $name;
	$name2 =~ s/([a-z])(\d)/\1-\2/ig;
	$name2 =~ s/(\d)([a-z])/\1-\2/ig;
	$name2 =~ s/([a-z])([A-Z])/\1-\2/ig;
	$name2 =~ s/(.|^)(alpha|beta|sigma|gamma|kappa|eps[iy]lon|zeta|delta)(.|$)/\1-\2-\3/ig;
	$name2 =~ s/(.|^)(alpha|beta|sigma|gamma|kappa|eps[iy]lon|zeta|delta)(.|$)/\1-\2-\3/ig; # in case of "alphabetaalhabetaalpha"
	$name2 =~ s/^\W+|\W+$//g;
	@name = split(/\W+/, $name2);
	map($_ =~ s/^\W+|\W+$//g, @name);
	map($_ = "\L$_", @name);
	foreach (@name) {
		if ($bad_words{$_}) {
			$delete = "name has bad word ($_) in it";
			return 0;
		}
	}

	return 1;
}

# prints special name-features into an opened SVM-file trainings/classification-file ("OUT")
# depending on the $name variable and the first special-feature number
# - used by find_proteins_in_text.pl and make_svm_file_from_abstracts_and_protein_names_file.pl
sub name_features {

	my($name) = shift;
	my($start) = 1;# if (! $start);
	my($block) = scalar(keys(%words_name));
	my($num_word) = 0;

	$name =~ s/(.|^)(alpha|beta|gamma|kappa|eps[iy]lon|zeta|delta)(.|$)/\1-\2-\3/ig;
	$name =~ s/(.|^)(alpha|beta|gamma|kappa|eps[iy]lon|zeta|delta)(.|$)/\1-\2-\3/ig; # in case of "alphabetaalhabetaalpha"
	$name =~ s/^\W+|\W+$//g;

	my(@names) = split(/[ \-]+/, $name);
	# replace punctuations
	map($_ =~ s/,/k_omma/g, @names);
	map($_ =~ s/;/s_emikolon/g, @names);
	map($_ =~ s/\./p_unkt/g, @names);
	map($_ =~ s/:/d_oppelpunkt/g, @names);
	map($_ =~ s/\(/k_auf/g, @names);
	map($_ =~ s/\)/k_zu/g, @names);
	map($_ =~ s/!/a_usrufezeichen/g, @names);
	map($_ =~ s/\?/f_ragezeichen/g, @names);
	
	map($_ =~ s/^\W+|\W+$//g, @names);
	map($_ = "\L$_", @names);
	map($_ = ($_ =~ /^(was|were|is|are|am|be|being|been)$/ ? "tobe" : $_), @names);
	map($_ = ($_ =~ /^\d+$/ ? "numb" : $_), @names);
	map($_ = ($_ eq "" ? "other_symbol" : $_), @names);

	print OUT " $start:" . scalar(@names);
	print OUT " " . ($words_name{$names[0]} + 1 + $start)  . ":1" if ($words_name{$names[0]});
	print OUT " " . ($block + $words_name{$names[$#names]} + 1 + $start)  . ":1" if ($words_name{$names[$#names]});

	%array = ();
	for(my($x) = 1; $x < $#names; $x ++) {
		$word = $names[$x];
		$word = $words_name{$word};
		if ($word) {
			$array{(($block * 2) + $word + 1 + $start)} = 1;
		}
	}

	foreach (sort sort_num_1 keys(%array)) {
		print OUT " $_:$array{$_}";
	}

}

sub get_protein_dic_entry {
	my($name) = shift();
	$name2 = "\L$name";
	$name2 =~ s/\W+/-/g;
	$name2 =~ s/([a-z])(\d)/\1-\2/ig;
	$name2 =~ s/(\d)([a-z])/\1-\2/ig;
	$name2 =~ s/^\W+|\W+$//g;
# 	$curate = $sp_tr_names_curate{$name2};
# 	if ($curate) {
# 		return(0, "");
# 	}
	$entry = $sp_tr_names{$name2};
	if ($entry) {
		$score = length($name2) / 25;
		$ids = substr($entry, 1); # store sp/tr-ids for name
		if ($database eq "sp") {
			$ids = ":" . $ids;
			$ids =~ s/:[a-zA-Z0-9]{6,}//g;
		}
		elsif ($database eq "tr") {
			$ids =~ s/(^|:)\w+_\w+//g;
		}
		$ids =~ s/^:+|:+$//g;
	}
	else {
		$score = 0;
		$ids = "";
	}
	return($score, $ids);
#	return($score);
}

# returns a sequence (mode seq: one-line) or the whole fasta-file-entry (mode fasta: multiple lines)
# for a given Database ID
sub seq {
	my($id) = shift;
	chomp($id);
	$id =~ s/^(\w+).*/\1/;
	my($seq);
	my(@file) = split(/\n/, get("http://us.expasy.org/cgi-bin/get-sprot-fasta?$id"));
	$_ = shift(@file);
	$seq = $_ . "\n";# if ($mode eq "fasta");
	while ($_ = shift(@file)) {
		$seq .= $_ . "\n";
	}
	return $seq;
}

# rounds numbers 'up', 'down' or cuts digits after floating point
sub round {
	my($arg) = shift;
	my($mode) = shift; # up = round to next full integer
						# down = round to previous full integer
						# any number = round to [number] digits after point
	$arg =~ s/^(-?)(\d)\.(\d+)e-(\d+)$/$1 . "0." . ("0" x ($4 - 1)) . $2 . $3/e;

	if ($mode =~ /^\d+$/ && $arg =~ /^-?\d+\./) {
		$arg =~ s/^(-?\d+\.\d{$mode}).*/\1/;
		return $arg;
	}
	$arg =~ s/^(\d+)\.(\d)\d*/($mode eq "up" ? ($1 + 1) : ($mode eq "down" ? $1 : ($2 > 4 ? ($1 + 1) : $1)))/e;	
	return $arg;
}

sub conv_roman {
	my($number) = shift();
	my($mode) = shift;
	if ($mode ne "back") {
		$number =~ s/^1$/I/;
		$number =~ s/^2$/II/;
		$number =~ s/^3$/III/;
		$number =~ s/^4$/IV/;
		$number =~ s/^5$/V/;
		$number =~ s/^6$/VI/;
		$number =~ s/^7$/VII/;
		$number =~ s/^8$/VIII/;
		$number =~ s/^9$/IX/;
		$number =~ s/^10$/X/;
		$number =~ s/^11$/XI/;
		$number =~ s/^12$/XII/;
		$number =~ s/^13$/XIII/;
		$number =~ s/^14$/XIV/;
		$number =~ s/^15$/XV/;
		$number =~ s/^16$/XVI/;
		$number =~ s/^17$/XVII/;
		$number =~ s/^18$/XVIII/;
		$number =~ s/^19$/XIX/;
		$number =~ s/^20$/XX/;
	}
	else {
		$number =~ s/^I$/1/;
		$number =~ s/^II$/2/;
		$number =~ s/^III$/3/;
		$number =~ s/^IV$/4/;
		$number =~ s/^V$/5/;
		$number =~ s/^VI$/6/;
		$number =~ s/^VII$/7/;
		$number =~ s/^VIII$/8/;
		$number =~ s/^IX$/9/;
		$number =~ s/^X$/10/;
		$number =~ s/^XI$/11/;
		$number =~ s/^XII$/12/;
		$number =~ s/^XIII$/13/;
		$number =~ s/^XIV$/14/;
		$number =~ s/^XV$/15/;
		$number =~ s/^XVI$/16/;
		$number =~ s/^XVII$/17/;
		$number =~ s/^XVIII$/18/;
		$number =~ s/^XIX$/19/;
		$number =~ s/^XX$/20/;
	}
	return $number;
}



sub text_to_nucleotide {
	
	# Please place these lines at the beginning if running with nucleotide sequences
	# genetic code (like M. Krauthammer: "Using BLAST for identifying gene and protein names in journal articles")
	# except for '.' has extra code
my(%code) = (
		'A' => 'AAAA',
		'B' => 'AACC',
		'C' => 'AAGG',
		'D' => 'AATT',

		'E' => 'ACAA',
		'F' => 'ACCC',
		'G' => 'ACGG',
		'H' => 'ACTT',

		'I' => 'AGAA',
		'J' => 'AGCC',
		'K' => 'AGGG',
		'L' => 'AGTT',

		'M' => 'ATAA',
		'N' => 'ATCC',
		'O' => 'ATGG',
		'P' => 'ATTT',

		'Q' => 'CAAA',
		'R' => 'CACC',
		'S' => 'CAGG',
		'T' => 'CATT',

		'U' => 'CCAA',
		'V' => 'CCCC',
		'W' => 'CCGG',
		'X' => 'CCTT',

		'Y' => 'CGAA',
		'Z' => 'CGCC',

		'0' => 'GGAA',
		'1' => 'GGCC',
		'2' => 'GGGG',
		'3' => 'GGTT',
		'4' => 'GTAA',
		'5' => 'GTCC',
		'6' => 'GTGG',
		'7' => 'GTTT',
		'8' => 'GAAA',
		'9' => 'GACC',

		',' => 'TTAA',
		'.' => 'TTCC',
		'\'' => 'TTCC',
		'(' => 'TTCC',
		')' => 'TTCC',
		'[' => 'TTCC',
		']' => 'TTCC',
		':' => 'TTAA',
		' ' => 'TTGG',
	);
my($rest_code) = "TTTT"; # for all other characters


	my($string) = shift();
	my($seq, $test);

	# is case insensitive
	$string = "\U$string";

	for (my($pos) = 0; $pos <= length($string) - 1; $pos ++) {
		$test = $code{substr($string, $pos, 1)};
		if ($test) {
			$seq .= $test;
		}
		else {
			$seq .= $rest_code;
		}
	}
	return $seq;
	
}

sub extend_names_to_rest_of_text {

my($round) = shift();

@results2 = @results;
@results = ();
$mode = 0;

foreach $vec (sort sort_9_11_hl @results2) {
	($filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids) = @{$vec};

	if ($round == 2 && $why !~ /abbr.-ext.|inherited/) {
		push(@results, [$filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids]);
		next;
	}

	$marker = 0;
	$word_pos = 0;
	
	@split_name = split(/ +/, $name);

	# digit at end => look for same name with different digits at end
	if ($name =~ /\D(\d+)$/) {
		$mode = 1; $name_pat = $name; $name_pat =~ s/(\W)/\\\1/g;
		# check for things like caspase-1, -2, -3, -4 and -5
		if ($inputtext =~ / $name_pat(( , -?\d+)+)( and (-?\d+))?/) {
			$add = $1; $and = $4;
			$add =~ s/^ , //;
			@add = split(/ , /, $add);
			push(@add, $and);
			$new_pos = $pos + 2;
			foreach $add (@add) {
				$new_name = $name; $new_name =~ s/\-?\d+$/$add/;
				($score, $ids) = get_protein_dic_entry($new_name);
				push(@results, [$filter, $new_name, $new_pos, $len, $score3, $score1, $score2, $score5, $dicscore, "inherited", ($score ? $ids : "")]); # stores additional name
				$new_pos += 2;
			}
		}
	}
	# upper case letter => look for different upper case letters at end 
	elsif ($name =~ /[a-z]( |\-)?([A-Z]|alpha|beta|gamma|delta|epsylon|kappa|sigma|omega|II|IV|III|VI|VII|VIII|IX)$/) {
		$mode = 2;
	}
	# only project exact same name
	else {
		$mode = 3;
	}

	# case insensitive OR not (depending on length of name)
	if (length($name) > 5) {
		$imode = 1;
	}
	else {
		$imode = 0;
	}


outer_loop:
	for (my($x) = 0; $x <= $#split_name; $x ++) {
		$split_name = $split_name[$x];
word:
		for (my($y) = $word_pos; $y <= $#text; $y ++) {
			$word_pos ++;
			next word if ($already{$y});
			$word = $text[$y];
			$word =~ s/^["']// if ($x == 0);
			$word =~ s/["']$// if ($x == $#split_name);
			$split_name_pat = $split_name; $split_name_pat =~ s/(\W)/\\\1/g;
			
			if ($mode == 1 && $x == $#split_name) {
				$split_name_pat =~ s/\d+$//;
			}
			elsif ($mode == 2 && $x == $#split_name) {
				$split_name_pat =~ s/([A-Z]|alpha|beta|gamma|delta|epsylon|kappa|sigma|omega|II|IV|III|VI|VII|VIII|IX)$//;
			}

			if (
				($mode == 3 && $imode == 0 && (($split_name eq $word) || (($x == $#split_name) && ($word =~ /^$split_name_pat[\-\/_(:](\w+ed)?/)))) || # e.g. IL-6-mediated OR PFK-induced etc.
				($mode == 3 && $imode && (("\L$split_name" eq "\L$word") || (($x == $#split_name) && ($word =~ /^$split_name_pat[\-\/_(:](\w+ed)?/i)))) || # e.g. IL-6-mediated OR PFK-induced etc.
				($mode == 1 && $imode == 0 && ((($x == $#split_name) && ($word =~ /^$split_name_pat(\d+)[\-\/_(:]?(\w+ed)?$/)) || ($split_name eq $word))) ||
				($mode == 1 && $imode && ((($x == $#split_name) && ($word =~ /^$split_name_pat(\d+)[\-\/_(:]?(\w+ed)?$/i)) || ("\L$split_name" eq "\L$word"))) ||
				($mode == 2 && $imode == 0 && ((($x == $#split_name) && ($word =~ /^$split_name_pat([A-Z]|alpha|beta|gamma|delta|epsylon|kappa|sigma|omega|II|I|IV|III|VI|VII|X|VIII|IX)[\-\/_(:]?(\w+ed)?$/)) || ($split_name eq $word))) ||
				($mode == 2 && $imode && ((($x == $#split_name) && ($word =~ /^$split_name_pat([A-Z]|alpha|beta|gamma|delta|epsylon|kappa|sigma|omega|II|I|IV|III|VI|VII|X|VIII|IX)[\-\/_(:]?(\w+ed)?$/i)) || ("\L$split_name" eq "\L$word")))
				#(0)
				) {
				$change = $1;
				$marker ++;
				$x ++; $split_name = $split_name[$x];
				if ($x > $#split_name) {
					$marker = 0;
					$new_name = $name;
					if ($mode == 1) {
						$new_name =~ s/(\d+)$/$change/;
						$old = $1;
						($score, $ids) = get_protein_dic_entry($new_name);
						push(@results, [$filter, $new_name, ($word_pos - $len), $len, $score3, $score1, $score2, $score5, $dicscore, ($old eq $change ? "projected" : "inherited"), ($score ? $ids : "")]); # stores additional name
					}
					elsif ($mode == 2) {
						$new_name =~ s/([A-Z]|alpha|beta|gamma|delta|epsylon|kappa|sigma|omega|II|IV|III|VI|VII|VIII|IX)$/$change/;
						$old = $1;
						($score, $ids) = get_protein_dic_entry($new_name);
						push(@results, [$filter, $new_name, ($word_pos - $len), $len, $score3, $score1, $score2, $score5, $dicscore, ($old eq $change ? "projected" : "inherited"), ($score ? $ids : "")]); # stores additional names
					}
					elsif ($mode == 3 || $mode == 4) {
						push(@results, [$filter, $name, ($word_pos - $len), $len, $score3, $score1, $score2, $score5, $dicscore, "projected", $ids]); # stores additional names
					}
					
					for (my($z) = ($word_pos - $len); $z <= ($word_pos - 1); $z ++) {
						$already{$z} = ($word_pos - $len) . ":" . $len;
					}
					$x = -1;
					goto outer_loop;
				}
			}
			elsif ($marker) {
				$x -= $marker;
				$word_pos -= $marker;
				$y -= $marker;
				$marker = 0; $split_name = $split_name[$x];
			}
		}	
	}

	push(@results, [$filter, $name, $pos, $len, $score3, $score1, $score2, $score5, $dicscore, $why, $ids]);
}

}

sub fastdistance {
	my $word1 = shift;
	my $word2 = shift;

	return 0 if $word1 eq $word2;
	my @d;

	my $len1 = length $word1;
	my $len2 = length $word2;

	$d[0][0] = 0;
	for (1 .. $len1) {
		$d[$_][0] = $_;
		return $_ if $_!=$len1 && substr($word1,$_) eq substr($word2,$_);
	}
	for (1 .. $len2) {
		$d[0][$_] = $_;
		return $_ if $_!=$len2 && substr($word1,$_) eq substr($word2,$_);
	}

	for my $i (1 .. $len1) {
		my $w1 = substr($word1,$i-1,1);
		for (1 .. $len2) {
			$d[$i][$_] = _min($d[$i-1][$_]+1, $d[$i][$_-1]+1, $d[$i-1][$_-1]+($w1 eq substr($word2,$_-1,1) ? 0 : 1));
		}
	}
	return $d[$len1][$len2];
}

sub _min {
	return $_[0] < $_[1]
		? $_[0] < $_[2] ? $_[0] : $_[2]
		: $_[1] < $_[2] ? $_[1] : $_[2];
}


__END__

# returns the word class of a word
# 0 if word not a dictionary word
sub dictionary {

	my($word) = shift();
	my($mode) = shift(); # 'online' if only online check; 'offline' if only offline-check; '' if both checks (default)

	return "short word" if (length($word) == 1);
	return 0 if ($word =~ /[\d()_&]/);
	
	my($wordl) = "\L$word";
	return $dic_cache{$wordl} if ($dic_cache{$wordl});

	my($file_dic) = "/misc/carnation/mika/data/nlp/dictionary/" . substr($wordl, 0, 1) . "/" . substr($wordl, 0, 2) . "/" . substr($wordl, 0, 3) . ".dic";

	if ($mode ne 'online') {
		my($word_pat) = $wordl;
		$word_pat =~ s/(\W)/\\\1/g;
		open(DIC, "<$file_dic");# or warn("No dictionary-file $file_dic!\n");
		while (<DIC>) {
			if (/^$word_pat\t(.+)/) {
				close DIC;
				$dic_cache{$wordl} = $1;
				return $1;
			}
		}
		close DIC;
	}

	my($res);
	if ($mode ne "offline") {
		# on-line dictionary 'Merriam-Webster'
		my($entry) = get("http://www.m-w.com/cgi-bin/dictionary?$wordl");
		if ($entry =~ /2 entries found for <b>([^<]+)<\/b>/) {
			$res = $1;
			if ($res =~ / / || ($res =~ /-/ && $word !~ /-/)) { # entry consists of two words (usually not wanted: eg. look for 're' and get 're-entering')
				$dic_cache{$wordl} = 0;
				return 0;
			}
		}
		elsif ($entry =~ /(Function|Usage):\s+<i>([^<]+)<\/i>/i) {
			$res = $2;
		}
		# past-tense forms of verbs
		elsif ($entry =~ /<i>(past|present) .*of<\/i><a href="dictionary\?book=Dictionary/) {
			$res = "verb";
		}
		elsif ($entry =~ /\d+ entries found for/) {
			$res = "ambiguous class";
		}
	}
	
	if ($res && $mode ne 'online') {
		open(DIC, ">>$file_dic");# or warn("Could not open for appending to dictionary-file:\n$file_dic!\n");
		print DIC "\L$wordl\t$res\n";
		close DIC;
		$dic_cache{$wordl} = "\L$res";
		return "\L$res";
	}
	elsif ($res) {
		$dic_cache{$wordl} = "\L$res";
		return "\L$res";
	}
	$dic_cache{$wordl} = 0;
	return 0;
}
