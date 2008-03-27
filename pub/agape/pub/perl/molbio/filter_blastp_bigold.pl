#!/usr/bin/perl
##!/usr/sbin/perl
# 
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extracts list of proteins from BLAST output";

$[ =1 ;				# start counting at one

				# ------------------------------
				# defaults
$p_value_out=       10;
$dbDef=             "swiss"; 
$dbDef=             "big";   
$dir_db_swiss=      "/data/swissprot/current/";
$dir_db_big=        "/data/derived/big/";
$dir_db_big_pdb=    $dir_db_big."splitPdb/";
$dir_db_big_swiss=  $dir_db_big."splitSwiss/";
$dir_db_big_trembl= $dir_db_big."splitTrembl/";

$dir_dbDef=$dir_db_swiss;
$dir_dbDef=$dir_db_big             if ($dbDef eq "big");
$dirOut=0;
$extOut=".blast_list";		# note: for Maxhom must end with list ..

				# ------------------------------
				# help
if ($#ARGV < 1 || $ARGV[1]=~/^(help|\-h|\-m)$/){
    print "goal: $scrGoal\n";
    print "use:  $scrName $file <options>\n";
    print "opt:  p=Pvalue_cutoff  (def=$p_value_out)\n";
    print "      db=<swiss|big>   (def=$db)\n";
    print "      dir=directory    directory with db split into many FASTA|SWISS-PROT (def=$dir_db)\n";
    print "      fileOut=name_of_output_file (def=$fileIn - extension + .blastLis\n";
    print "      dirOut           directory for output file\n";
    print "      extOut           extension for output file  (def=$extOut)\n";
    print "      dbg              write messages, keep files\n";
    print "      ----           --------\n";
    print "      NOTE: print to standard out if no fileOut=x defined!!\n";
    print "      ----           --------\n";
    print "      \n";
#    print "      \n";
    exit;}
    

$dir_db=$db=$fileOut=$Ldebug=$Lverb=0;
				# ------------------------------
				# read command line
$fileIn=$ARGV[1];
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.="/"     if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^p=(.*)$/)              { $p_value_out=    $1;}
    elsif ($arg=~/^db=(.*)$/)             { $db=             $1;}
    elsif ($arg=~/^dir=(.*)$/)            { $dir_db=         $1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    else {
	print "*** $0: wrong command line arg=$arg!\n";
	exit;}}

if    (! $db && ! $dir_db) {	# both NOT passed
    $dir_db=$dir_dbDef;
    $dir_db=$dir_db_big         if ($db eq "big");
    $db=    $dbDef;}
elsif (! $db) {			# db NOT passed
    $db=$dbDef;}
elsif (! $dir_db) {		# dir NOT passed, but db
    $dir_db=$dir_db_swiss;
    $dir_db=$dir_db_big         if ($db eq "big"); }

$dir_db.="/"                    if ($dir_db !~/\/$/); # add slash

				# automaticly name output file
$fileOut=$dirOut.$fileOut       if ($dirOut && $fileOut); 

				# ------------------------------
				# check input
die "*** unrecognised db=$db (must be <big|swiss>)\n" if ($db !~/^(big|swiss)/);
die "*** non-existing dir=$dir_db!\n"                 if (! -d $dir_db);
die "*** missing input file:$fileIn!\n"               if (! -e $fileIn);

				# ------------------------------
				# open output handle
$fhout="STDOUT";		# default
$fhout="FHOUT"                  if ($fileOut);
if ($fileOut) {
    open($fhout,">".$fileOut) || die "*** $0: failed opening out=$fileOut\n";}

				# ------------------------------
				# now read
				# ------------------------------
open(FHIN,$fileIn) || die "*** $0: failed opening fileIn=$fileIn!\n";

				# skip before section with summary
while (<FHIN>){
    last if ($_=~/^Sequences producing High-scoring Segment Pairs:/);
}
while (<FHIN>){
    $line=$_; $line=~s/\n//g;
    last if ($line=~/^\s*>/);
    next if ($line=~/^\S/);
    next if ($line=~/^\s*$/);

# pdb|1crn PLANTSEEDPROTEIN CRAMBIN source=ABYSSINIAN CABB...   262  1.8e-32   1
	    
    if ($line=~/^ \s*(\S+)\s+(.*)\s+(\d+)\s+([\-x\d\.e]+)\s+(\d+)\s*$/) {
				# finish reading if Pvalue too high
	last if ($4 > $p_value_out);

	$db_info=$1;
				# (1) ordinary swiss-prot
	if ($db eq "swiss") {
	    $tmp=$line;  $tmp=~s/^(.*\|)[^\|]+.*$/$1/g;
	    $id=$line;   $id=~s/^.*\|([^\|\s]+).*$/$1/g;
	    $id=~tr/[A-Z]/[a-z]/;
	    $sub_dir=substr($name,index($name,'_')+1,1);
	    print $fhout $dir_db.$sub_dir."/".$id."\n";
	    next; }
				# (2) big redundant db 
	if    ($line=~/pdb\|/) {
	    $dbHere="pdb";
	    $dir_dbSplit=$dir_db_big_pdb; }
	elsif ($line=~/trembl\|/) {
	    $dbHere="trembl";
	    $dir_dbSplit=$dir_db_big_trembl; }
	else {
	    $dbHere="swiss";
	    $dir_dbSplit=$dir_db_big_swiss; }

	$line=~s/^\s*\S+\|//g;
	$id=$line;   $id=~s/^(\S+).*$/$1/g;
	$id=~tr/[A-Z]/[a-z]/;
				# split into /data/derived/big/splitSwiss/o/prot_organism
	if    ($dbHere =~/^swiss/) {
	    $tmp=$id; $tmp=~s/^[^_]*_(\w).*$/$1/;
	    $dir_dbSplit.=$tmp."/";}
				# split into /data/derived/big/splitTrembl/a/af001_1;
	elsif ($dbHere =~/^trembl/) {
	    $tmp=substr($id,1,1);
	    $dir_dbSplit.=$tmp."/";}

	$file=$dir_dbSplit.$id.".f";
	next if (! -e $file);	# skip if missing
	print $fhout  $file."\n";
    }
}
close(FHIN);
close($fhout)                   if ($fileOut);
print "$0 output in $fileOut\n"       if ($fileOut && -e $fileOut);
print "ERROR $0 no output=$fileOut\n" if ($fileOut && ! -e $fileOut);

exit;
