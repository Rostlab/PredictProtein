#!/usr/sbin/perl -w
$[ =1 ;

# finds the HSSP files for a given list of ids or files (/data/x/*.dfhssp_A ignored)

push (@INC, "/home/rost/perl") ;
require "lib-ut.pl"; require "lib-br.pl";

$Lverb=0;

if ( ($#ARGV<1) || &isHelp($ARGV[1])){
    print "goal:   find valid HSSP files (chain as: _C or fourth character\n";
    print "usage:  'script list_of_ids (or files)\n";
    print "option: allChains|all       (will print a list with all chains)\n";
    print "        e.g. 1cse.hssp_E\n";
    print "             1cse.hssp_I\n";
    print "        dir=/data/hssp/     (dir1,dir2 for many)\n";
    print "        ext=.hssp\n";
    print "        nocheck -> not checked whether or not chain existing\n";
    print "                   nor: empty HSSP\n";
    print "        verb                write blabla\n"       if (! $Lverb);
    print "        noscr               no write no blabla\n" if ($Lverb);
    exit;}

$file_in=$ARGV[1];
$LallChains=0; $Lnocheck=0;
$ext=".hssp";
if (defined $ENV{'DATA'}){
    $dir=$ENV{'DATA'}."/hssp/";}

foreach $arg (@ARGV) {
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^all[a-z]*/i)  {$LallChains=1;}
    elsif ($arg=~/^dir=(.+)$/)   {$dir=$1;}
    elsif ($arg=~/^ext=(.+)$/)   {$ext=$1;}
    elsif ($arg=~/^noch[a-z]*$/) {$Lnocheck=1;}
    elsif ($arg=~/^noscr[a-z]*$/){$Lverb=0;}
    elsif ($arg=~/^verb*$/)      {$Lverb=1;}
    else {
	print "*** argument '$arg' not recognised\n";
	exit; }
}

$fhin="FHIN";
$fhoutOk="FHOUT_OK";$fhoutNot="FHOUT_NOT";$fhoutEmpty="FHOUT_EMPTY";$fhoutWrong="FHOUT_WRONG";

$fileOutOk=   $file_in."-ok";
$fileOutNot=  $file_in."-not";
$fileOutEmpty=$file_in."-empty";
$fileOutWrong=$file_in."-wrong";

if (! defined $dir){
    @dir=("/data/hssp/","/sander/purple1/rost/data/hssp/","/home/rost/hssp/");}
else {
    @dir=split(/,/,$dir);}
foreach $dir (@dir){
    $dir.="/"  if ($dir !~/\/$/);}

				# ------------------------------
				# open all files
				# ------------------------------
&open_file("$fhin", "$file_in");
&open_file("$fhoutOk", ">$fileOutOk");
&open_file("$fhoutNot", ">$fileOutNot");
&open_file("$fhoutEmpty", ">$fileOutEmpty");
&open_file("$fhoutWrong", ">$fileOutWrong");
print $fhoutWrong "file             ","\t","chain wanted","\t","chain read","\n";

				# --------------------------------------------------
				# loop over all ids
				# --------------------------------------------------
$ctOk=$ctNot=$ctEmpty=$ctWrong=$ct=0;
$#fileOut=0;

while (<$fhin>) {
    $_=~s/\n|\s//g;
				# chop dir/ext
    $_=~s/^.*\/|$ext//g;

				# handle chain
    $chain="*";
    $_=~s/_(.)$//;
				# handle chain
    $chain=$1                   if (defined $1);

    next if (length($_)<3);	# skip strange ..

				# input file
    $fileIn= $_;
    $fileIn.=$ext;
    $fileIn.="_".$chain           if ($chain ne "*");

				# find respective HSSP file
    print "--- read '$_' \t chain=$chain, file=$fileIn, \n" if ($Lverb);

    ++$ct;
    ($fileRd,$chainRd)=
	&hsspGetFile($fileIn,$Lverb,@dir); 
    $chainRd="*"                if (! defined $chainRd || $chainRd eq " " || length($chainRd)==0);

				# ------------------------------
				# failed to find file: missing
    if (! -e $fileRd){
	++$ctNot;
	print $fhoutNot $fileIn," (chain=$chain)\n";
	next; }
				# ------------------------------
				# found but empty
    if (! $Lnocheck && &is_hssp_empty($fileRd)){
	++$ctEmpty;
	print $fhoutEmpty $fileRd,"\n";
	next; }
				# ------------------------------
    if ($Lnocheck){		# no check!
	push(@fileOut,$fileRd); 
	next; }
				# ------------------------------
				# get all chains actually in file
    ($chainRd2,%tmp)=
	&hsspGetChain($fileRd);

    $chainRd2=~s/ /\*/g;	# replace ' ' -> '*' for no chain
    @chainRd=split(//,$chainRd2);

				# ------------------------------
				# just add all
    if ($chain eq "*"){
	foreach $tmp (@chainRd){
	    $file=$fileRd;
	    $file.="_".$tmp     if ($tmp ne "*");
	    push(@fileOut,$file); } 
	next; }
				# ------------------------------
				# check them
    $Lok=0;
    foreach $tmp (@chainRd) {
	$Lok=1 if ($chain eq $tmp);
	last if ($Lok); }
    if ($Lok){
	$file=$fileRd;
	$file.="_".$chain       if ($chain ne "*");
	push(@fileOut,$file); 
	next; }
				# big shit: wrong chain
    ++$ctWrong;
    print "*** wrong chain for $fileRd: want $chain, got $chainRd2\n";
    print $fhoutWrong $fileRd."\t".$chain."\t".$chainRd2,"\n";
}

foreach $file (@fileOut){
    ++$ctOk;
    print $fhoutOk $file,"\n";}

close($fhin);close($fhoutOk);close($fhoutNot);close($fhoutEmpty);close($fhoutWrong);
				# remove empty
unlink($fileOutWrong)           if ($ctWrong < 1);
unlink($fileOutEmpty)           if ($ctEmpty < 1);
unlink($fileOutNot)             if ($ctNot   < 1);
unlink($fileOutOk)              if ($ctOk    < 1);

print "ok=$ctOk ($fileOutOk)  , not=$ctNot ($fileOutNot)\n";
print "   empty=$ctEmpty ($fileOutEmpty), wrong=$ctWrong ($fileOutWrong)\n";
print "sum =",$ctOk+$ctNot+$ctEmpty+$ctWrong,", sum files=$ct\n";
exit;
