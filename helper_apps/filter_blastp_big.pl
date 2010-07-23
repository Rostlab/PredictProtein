#!/usr/bin/perl -w

$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extracts list of proteins from BLAST output";

$[ =1 ;				# start counting at one

				# ------------------------------
				# defaults
$p_value_out=       10;
$dbDef=             "swiss"; 
$dbDef=             "big";   
$dirOut=0;
$extOut=".blast_list";		# note: for Maxhom must end with list ..

#my $ppData;

				# ------------------------------
				# help
if ($#ARGV < 1 || $ARGV[1]=~/^(help|\-h|\-m)$/){
    print "goal: $scrGoal\n";
    print "use:  $scrName file <options>\n";
    print "opt:  p=Pvalue_cutoff  (def=$p_value_out)\n";
    print "      db=<swiss|big>   (def=$dbDef)\n";
#    print "      ppData=/path\n";
    print "      dir=directory    directory with db split into many FASTA|SWISS-PROT\n";
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
    

$dir_db=$dbWant=$fileOut=$Ldebug=$Lverb=0;
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
#    elsif ($arg=~/^ppData=(.*)$/o)        { $ppData =        $1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^p=(.*)$/)              { $p_value_out=    $1;}
    elsif ($arg=~/^db=(.*)$/)             { $dbWant=             $1; $dbWant = lc( $dbWant ); }
    elsif ($arg=~/^dir=(.*)$/)            { $dir_db=         $1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
	else
	{
		print "*** $0: wrong command line arg=$arg!\n";
		exit(1);
	}
}

#if( !$ppData ){ die("no ppData"); }
#$dir_db_swiss=      "$ppData/swissprot/current/";
#$dir_db_big=        "$ppData/derived/big/";
#$dir_db_big_pdb=    $dir_db_big."splitPdb/";
#$dir_db_big_swiss=  $dir_db_big."splitSwiss/";
#$dir_db_big_trembl= $dir_db_big."splitTrembl/";

$dir_dbDef=$dir_db_swiss;
$dir_dbDef=$dir_db_big             if ($dbDef eq "big");


if    (! $dbWant && ! $dir_db) {	# both NOT passed
    $dir_db=$dir_dbDef;
    $dir_db=$dir_db_big         if ($dbWant eq "big");
    $dir_db=$dir_db_big         if ($dbWant eq "pdb");
    $dir_db=$dir_db_big         if ($dbWant eq "trembl");
    $dbWant=    $dbDef;
    $dbWant=$dbDef;}
elsif (! $dbWant) {			# db NOT passed
    $dbWant=$dbDef;
} elsif (! $dir_db) {		# dir NOT passed, but db
die( $dbWant);
    $dir_db=$dir_db_swiss;
    $dir_db=$dir_db_big         if ($dbWant eq "big"); 
    $dir_db=$dir_db_big         if ($dbWant eq "pdb");
    $dir_db=$dir_db_big         if ($dbWant eq "trembl");
}

$dir_db.="/"                    if ($dir_db !~/\/$/); # add slash

				# automaticly name output file
$fileOut=$dirOut.$fileOut       if ($dirOut && $fileOut); 

				# ------------------------------
				# check input
die "*** unrecognised db=$dbWant (must be <big|swiss>)\n" if ($dbWant !~/^(big|swiss|pdb|trembl)/);
die "*** non-existing dir=$dir_db!\n"                 if (! -d $dir_db);
die "*** missing input file:$fileIn!\n"               if (! -e $fileIn);

				# ------------------------------
				# now read
				# ------------------------------
open(FHIN,$fileIn) || die "*** $0: failed opening fileIn=$fileIn!\n";

				# skip before section with summary
$LoldVersion=1;

while (<FHIN>){
    $LoldVersion=0              if ($LoldVersion && $_=~/BLASTP [2-9]/);
    last if ($_=~/^Sequences producing .*:/);
}
$ctFound=0;

undef %already;
$#found=0;

while (<FHIN>){
    $line=$_; $line=~s/\n//g;
    last if ( $line=~ /^Parameters\:/ );

#    next if ($line=~/^\S/);
    if ($line=~/^\s*>/) {
	last if ($LoldVersion);
	next;}

				# <*** <*** <*** <*** <*** <*** <*** <*** <*** 
				# none (beg)
    if ($line =~ /\*+\s+NONE\s+\*+/) {
	print "none\n";
	close($fhout)           if ($fhout ne "STDOUT");
#	exit(0,"none"); 
	exit(0);
    }
				# none (end)
				# <*** <*** <*** <*** <*** <*** <*** <*** <*** 
    next if ($line=~/^\s*$/);

    if (! $LoldVersion && $line=~/^Sequences producing .*:/) {
	$#found=0;
	undef %already;}
	
    next if (! $LoldVersion && 
	     ($line=~/^Query/     ||
	      $line=~/^Sbjct/     ||
	      $line=~/^Searching/ ||
	      $line=~/^Results/   ||
	      $line=~/^Sequences /) );


# swiss|Q8HXX3|MC4R_MACFA Melanocortin receptor 4 OS=Macaca fascic...   625   e-179
# swiss|Q0H8Y4|COX1_USTMA Cytochrome c oxidase subunit 1 OS=Ustila...    29   9.2
# pdb|1crn PLANTSEEDPROTEIN CRAMBIN source=ABYSSINIAN CABB...   262  1.8e-32   1
# 1ppt.pdb PANCREATICHORMONE AVIAN PANCREATIC POLYPEPTI               82  4e-16
    
    #                 1      2       3          4
    if ($line=~/^\s*(\S+)\s+(.*)\s+(\d+)\s+([\-x\d\.e]+)\s*.*$/) {
	
				# finish reading if Pvalue too high
        # lkajan: perl does not recognize e-179 as a number. It does recognize 1e-179 though.
        my $e_val = $4; if( $e_val =~ /^e/o ){ $e_val = "1$e_val"; }
	if ($e_val > $p_value_out){ last; }

	#$db_info=$1;
				# (1) big redundant db 
	if    ($line=~/pdb\|/) {
	    $dbHere="pdb";
	    #$dir_dbSplit=$dir_db_big_pdb;
	}
	elsif ($line=~/trembl\|/) {
	    $dbHere="trembl";
	    #$dir_dbSplit=$dir_db_big_trembl;
        }
	else {
	    $dbHere="swiss";
	    #$dir_dbSplit=$dir_db_big_swiss;
	}
				# skip wrong db for BIG

	if( !defined($dbWant) || ( $dbWant ne "big" && $dbWant ne $dbHere ) ){ next; }

				# (2) ordinary swiss-prot
	if ($dbWant eq "swiss") {
	    $tmp=$line;  
	    $tmp=~s/^(.*\|)[^\|]+.*$/$1/g;
#	    print STDERR "tmp=$tmp\n";	    
	    $id=$line;   
	    $id=~s/^.*\|([^\|\s]+).*$/$1/g;
#	    $id = $1;
	    #print STDERR "Line 181: id=$id\n";
	    $id=~tr/[A-Z]/[a-z]/;
	    $sub_dir=substr($id,index($id,'_')+1,1);

	    $file=$dir_db.$sub_dir."/".$id;
	    #print STDERR $file,"\n";
	    next if (! -e $file);
	    push(@found,$file);
	    #print $fhout $dir_db.$sub_dir."/".$id."\n";
	    #print STDERR $file,"\n";

	    ++$ctFound;
	    next; }

	$line=~s/^\s*\S+\|//g;

	$id=$line;   $id=~s/^(\S+).*$/$1/g;

	$id=~tr/[A-Z]/[a-z]/ if ($dbHere ne "pdb");
				# split into /data/derived/big/splitSwiss/o/prot_organism
	
	if    ($dbHere =~/^swiss/) {
	    $tmp=$id; $tmp=~s/^[^_]*_(\w).*$/$1/;
	    $dir_dbSplit.=$tmp."/";}
				# split into /data/derived/big/splitTrembl/a/af001_1;
	elsif ($dbHere =~/^trembl/) {
	    $tmp=substr($id,1,1);
	    $dir_dbSplit.=$tmp."/";}
#	print STDERR $id  ;	# 
	
			# note: split into PDB done already

	$file=$dir_dbSplit.$id.".f";



	next if (! -e $file);	# skip if missing
	next if (defined $already{$id});
	$already{$id}=1;
	++$ctFound;

	push(@found,$file);
#	print  $file,"\n";
    }
}
close(FHIN);


				# ------------------------------
				# open output handle
my $fhout;			# default
if ($fileOut) {
    open($fhout,">".$fileOut) || die "*** $0: failed opening out=$fileOut\n";
}
else
{
	$fhout = \*STDOUT;
}

foreach $found (@found){
    print $fhout $found,"\n";
}

if (! $ctFound) {
#    print $fhout "none\n";
    close($fhout)           if ($fhout ne "STDOUT");
    #exit(0,"none");
    exit(0);
}

print "$0 output in $fileOut\n"       if ($fileOut && -e $fileOut);
print "ERROR $0 no output=$fileOut\n" if ($fileOut && ! -e $fileOut);

exit;

# vim:ai:et:
