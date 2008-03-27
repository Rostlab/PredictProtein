#!/usr/local/bin/perl
##!/usr/sbin/perl
# 
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extracts list of PDB hits from BLAST output";

$[ =1 ;				# start counting at one

				# ------------------------------
				# defaults
$p_value_out=       10;
$extOut=".blastPdb";		# note: for Maxhom must end with list ..

				# ------------------------------
				# help
if ($#ARGV < 1 || $ARGV[1]=~/^(help|\-h|\-m)$/){
    print "goal: $scrGoal\n";
    print "use:  $scrName $file <options>\n";
    print "opt:  p=Pvalue_cutoff  (def=$p_value_out)\n";
#    print "      db=<swiss|big>   (def=$db)\n";
#    print "      dir=directory    directory with db split into many FASTA|SWISS-PROT (def=$dir_db)\n";
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
    

#$dir_db=$db=0;
$fileOut=$Ldebug=$Lverb=0;
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
#    elsif ($arg=~/^db=(.*)$/)             { $db=             $1;}
#    elsif ($arg=~/^dir=(.*)$/)            { $dir_db=         $1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    else {
	print "*** $0: wrong command line arg=$arg!\n";
	exit;}}

# if    (! $db && ! $dir_db) {	# both NOT passed
#     $dir_db=$dir_dbDef;
#     $dir_db=$dir_db_big         if ($db eq "big");
#     $db=    $dbDef;}
# elsif (! $db) {			# db NOT passed
#     $db=$dbDef;}
# elsif (! $dir_db) {		# dir NOT passed, but db
#     $dir_db=$dir_db_swiss;
#     $dir_db=$dir_db_big         if ($db eq "big"); }

# $dir_db.="/"                    if ($dir_db !~/\/$/); # add slash

				# automaticly name output file
$fileOut=$dirOut.$fileOut       if ($dirOut && $fileOut); 

				# ------------------------------
				# check input
#die "*** unrecognised db=$db (must be <big|swiss>)\n" if ($db !~/^(big|swiss)/);
#die "*** non-existing dir=$dir_db!\n"                 if (! -d $dir_db);
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
	next if ($db_info !~/pdb\|/);

	$line=~s/^\s*\S+\|//g;
	$id=$line;   $id=~s/^(\S+).*$/$1/g;
	$id=~tr/[A-Z]/[a-z]/;

	print $fhout  "pdb:".$id."\n";
    }
}
close(FHIN);
close($fhout)                   if ($fileOut);
print "$0 output in $fileOut\n"       if ($fileOut && -e $fileOut);
print "ERROR $0 no output=$fileOut\n" if ($fileOut && ! -e $fileOut);

exit;
