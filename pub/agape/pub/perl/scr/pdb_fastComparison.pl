#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="fast comparison of two lists of PDB files (in FASTA format):\n".
    "     \t reads list of fasta 1 (e.g. 1194), and purges all from list 2 (e.g. 8000) that\n".
    "     \t have an identical sequence to any of those in list1 (e.g 1194)\n".
    "     \t also: arg pieces=2|3 results in that partially 100% identical ones also found!\n";
#  
#

$[ =1 ;
				# ------------------------------
foreach $arg(@ARGV){		# include libraries
    last if ($arg=~/dirLib=(.*)$/);}
$dir=$1 || "/home/rost/perl/" || $ENV{'PERLLIB'}; 
$dir.="/" if (-d $dir && $dir !~/\/$/);
$dir= ""  if (! defined $dir || ! -d $dir);
foreach $lib("lib-ut.pl","lib-br.pl"){
    require $dir.$lib ||
	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}
				# ------------------------------
				# defaults
%par=(
      'dirShortList',    "/home/rost/data/hsspFasta/",     # dir of the files to take 1st
      'dirLongList',     "/home/rost/data/hsspFastaFull/", # dir of files to reduce
      'minLen',          40,	# minimal length when chopping into pieces
      '', "",			# 
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<2){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName list1-of-fasta (to take) list2-of-fasta (to possibly exclude)'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s= %-20s %-s\n","","fileOut",  "x",       "list2-of-fasta to take (survivors)";
    printf "%5s %-15s  %-20s %-s\n","","pieces",   "n",       "chops the sequence in list1";
    printf "%-40s %-s\n","into n pieces and skips if any of the pieces existing (=> skip highly identical!)";
    printf "%-40s %-s\n","max N = 3!!!";

#    printf "%5s %-15s  %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s  %-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s  %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin= "FHIN";
$fhoutOk="FHOUT_OK"; $fhoutNo="FHOUT_NO";
$fherr="FHERR";

$file1=$ARGV[1];
$file2=$ARGV[2];
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    next if ($arg eq $ARGV[2]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^pieces=(.*)$/)         { $pieces=$1; 
					    $pieces=3 if ($pieces>3); } # note: MAXIMUM HARD_CODED
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}

die ("missing input1 $file1\n") if (! -e $file1);
die ("missing input2 $file2\n") if (! -e $file2);

if (! defined $fileOut){
    $tmp=$file1;$tmp=~s/^.*\///g;
    $fileOutOk="Out-ok-".$tmp;
    $fileOutNo="Out-no-".$tmp; }
$fileErr="ERROR-reduce.tmp";

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"           if ($par{"$kwd"} !~ /\/$/);}


				# ------------------------------
				# read list 1
				# ------------------------------
$#list=0;
print "--- $scrName: read 1 '$file1'\n";
&open_file("$fhin", "$file1") || die '*** '.$scrName.' ERROR opening file '. $file1;
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge dir
    $_=$par{"dirShortList"}.$_;	# add new dir
    next if (! -e $_);
    push(@list,$_);
} close($fhin);

				# ------------------------------
				# read files to take
				# ------------------------------
undef %take; undef %seq;
foreach $fileIn (@list){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    ($Lok,$id,$seq)=
	&fastaRdGuide($fileIn); if (! $Lok) { print "*** failed on $fileIn\n",$id,"\n";
					      exit; }
    $id=$fileIn;$id=~s/^.*\/|\.f//g;
    $seq=~s/[^ABCDEFGHIKLMNPQRSTVWYZ]//g; 
    $len=length($seq);
    $take{$id}=1; $seq{$seq}=$id;
				# ------------------------------
				# chop into pieces
    if (defined $pieces && $len > $par{"minLen"}){
	@tmp=&get_slices_of_sequence();
	foreach $tmp (@tmp) {
	    $seq{$tmp}=$id;}}
}
				# ------------------------------
				# read list 2
				# ------------------------------
$#list=0;
print "--- $scrName: read 1 '$file2'\n";
&open_file("$fhin", "$file2") || die '*** '.$scrName.' ERROR opening file '.$file2;
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge dir
    $_=$par{"dirLongList"}.$_;	# add new dir
    next if (! -e $_);
    push(@list,$_);
} close($fhin);

				# ------------------------------
				# process all 2nd files
				# ------------------------------
&open_file("$fhoutOk",">$fileOutOk") || die '*** '.$scrName.' ERROR opening new fileOutok='. $fileOutOk;
&open_file("$fhoutNo",">$fileOutNo") || die '*** '.$scrName.' ERROR opening new fileOutno='. $fileOutNo;
&open_file("$fherr",">$fileErr") || die '*** '.$scrName.' ERROR opening new fileErr '. $fileErr;

$ctOk=0;
foreach $fileIn (@list){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}

    $id2=$fileIn;$id2=~s/^.*\/|\.f//g;
#    print "xx working on $id2\n";
				# ignore those identical to list1
    if (defined $take{$id2}) {
	print $fhoutOk "$fileIn\n"; 
	++$ctOk; 
	next; }
	

    ($Lok,$idrd,$seq)=
	&fastaRdGuide($fileIn); if (! $Lok) { print $fherr "*** failed on $fileIn\n",$idrd,"\n";
					      next; }
				# ignore identical
    $seq=~s/[^ABCDEFGHIKLMNPQRSTVWYZ]//g;
    if (defined $seq{$seq}) {
	print $fhoutNo "$id2\t->\t",$seq{$seq},"\n";
	next; }
				# ------------------------------
				# chop into pieces
    if (defined $pieces && length($seq) > $par{"minLen"}){
	@tmp=&get_slices_of_sequence();
	$Lok=0;
	foreach $tmp (@tmp) {
	    next if (! defined $seq{$tmp});
	    print $fhoutNo "$id2\t->\t",$seq{$tmp},"\t slices (length=",length($tmp),")\n";
	    $Lok=1;
	    last; }
	next if ($Lok); }

    ++$ctOk; 
    print $fhoutOk "$fileIn\n";
}

close($fhoutOk);close($fherr);close($fhoutNo);

				# ------------------------------
				# (2) 
				# ------------------------------
print "--- new list in $fileOutOk\n" if (-e $fileOutOk);
print "--- skip     in $fileOutNo\n" if (-e $fileOutNo);
print "--- errro    in $fileErr\n" if (-e $fileErr);

print "--- started with ",$#list,", ended with $ctOk\n";

exit;


sub get_slices_of_sequence {
    my($len,@tmp);

				# in GLOBAL: $seq
    $len=length($seq);
    $#tmp=0;

    if ($pieces==2 || $len < 2 * $par{"minLen"}) {
	if ($len < 2 * $par{"minLen"}){
	    @tmp=(substr($seq,1,$par{"minLen"}),
		  substr($seq,($len-$par{"minLen"}))); }
	else {
	    $lenSplit=int($len/2);
	    @tmp=(substr($seq,1,$lenSplit),
		  substr($seq,,($len-$lenSplit)));}}
    if ($pieces==3){
	if ($len < 3 * $par{"minLen"}){
	    @tmp=(substr($seq,1,$par{"minLen"}),
		  substr($seq,$par{"minLen"},$par{"minLen"}),
		  substr($seq,($len-$par{"minLen"}))); }
	else {
	    $lenSplit=int($len/3);
	    @tmp=(substr($seq,1,$lenSplit),
		  substr($seq,$lenSplit,$lenSplit),
		  substr($seq,,($len-$lenSplit)));}}
    return(@tmp);
}
