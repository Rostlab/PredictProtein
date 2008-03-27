#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="splits fastaMul into many FASTA files";
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
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName fastaMul'\n";
    print  "               keyword 'list' to digest lists (or extension .list) !!\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","list",   "no value","";
#    printf "      %-15s  %-20s %-s\n","noScreen", "no value","";
#    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "no value","";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$LisList=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif ($arg=~/^list$/)                { $LisList=1;}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ($LisList || $fileIn=~/list$/){
	&open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
	while (<$fhin>) {$_=~s/\n//g;
			 push(@fileTmp,$_); }
	close($fhin); }
    else {
	push(@fileTmp,$fileIn);} }

@fileIn= @fileTmp; 


$#fileOut=0;
				# ------------------------------
				# (1) read file(s)
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";

				# id='id1\nid2'
    ($Lok,$id,$seq)=
	&fastaRdMul($fileIn,0);
    if (! $Lok){ print "*** failed on $fileIn msg=\n","$id\n";
		 exit; }
    $id=~s/^\n*|\n*$//g;   $seq=~s/^\n*|\n*$//g;
    @id=split(/\n/,$id);   @seq=split(/\n/,$seq);
    if ($#id !~ $#seq) { 
	print "*** ERROR from fastRdMul ".$#id." ids read, but ".$#seq." sequences!\n";
	exit;}
				# ------------------------------
				# (3) write output
				# ------------------------------
    foreach $it (1..$#id){
	$id=$id[$it]; $id=~s/\s.*$//g;
	$fileOut=$id.".f";
	&open_file("$fhout",">$fileOut"); 
	print $fhout "> $id\n";
	for ($mue=1; $mue<=length($seq[$it]); $mue+=50) {
	    print $fhout substr($seq[$it],$mue,50),"\n"; }
	close($fhout);
	push(@fileOut,$fileOut) if (-e $fileOut);
    }
}

print "--- output in:",join(',',@fileOut,"\n");

exit;
