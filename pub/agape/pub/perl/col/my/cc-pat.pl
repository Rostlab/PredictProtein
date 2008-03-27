#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# xscriptname
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	cc-pat.pl file.dssp pat=abba
# optional:     list of DSSP files
# task:		extract pattern of C-C from DSS
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       August,          1996           #
#			changed:       .	,    	1996           #
#	EMBL			       Version 0.1                     #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
#
#
				# sets array count to start at 1, not at 0
$[ =1 ;

push (@INC, "/home/rost/perl","/u/rost/perl","/usr/people/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   extract pattern of C-C from DSSP\n";
	      print"usage:  'script file.dssp pat=abba'\n";
	      print"or   :  'script List-of-DSSP-files pat=abba'\n";
	      exit;}
				# ------------------------------
				# defaults
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-ccPat-".$$.".tmp";
				# ------------------------------
				# read command line input
$#fileDssp=0;
foreach $arg(@ARGV){
    if (-e $arg){
	if (&is_dssp($arg)){
	    push(@fileDssp,$arg);}
	else {
	    &open_file("$fhin", "$arg");
	    while (<$fhin>) {
		$_=~s/\n|\s//g;$file=$_;
		if (&is_dssp($file)){
		    push(@fileDssp,$file);}}close($fhin);}}
    elsif ($arg =~/^pat=/){
	$par{"pat"}=$arg;$par{"pat"}=~s/^pat=|\s//g;}
    else {
	print "*** false input argument '$arg'\n";}}
				# ------------------------------
				# input
$#fileFound=$#patFound=0;
foreach $file (@fileDssp){
    &open_file("$fhin", "$file");
    $aa="";$txtFoundLoc="";
    while (<$fhin>) {
	if (/^ .... ....   [a-z]/){ # read C=C 
				# (take if lower case letters found in residue column)
	    $_=~s/\n//g;
	    $txt="$file:"."$_";
	    $txtFoundLoc.="$txt"."\t";
	    $_=~s/^ .... ....   ([a-z]).*$/$1/g;
	    print"x.x aa=$_, line=$txt,\n";
	    $aa.=$_;}}
    close($fhin);
    if (length($aa)<length($par{"pat"})){
	next;}
    print "x.x pattern found=$aa,\n";
    if (&compareCCpattern($aa,$par{"pat"})){
	print "x.x OK for $file, '$aa'\n";
	push(@fileFound,$file);
	push(@patFound,$aa);}
    else {
	print "x.x not match '$aa', search=",$par{"pat"},", \n";}
}

if ($#fileFound>0){
    &open_file("$fhout", ">$fileOut");
    foreach $it(1.. $#fileFound){
	print "$fileFound[$it],\t$patFound[$it]\n";
	print $fhout "$fileFound[$it],\t$patFound[$it]\n";}
    close($fhout);

    print "--- result in $fileOut\n";}

exit;

#==========================================================================================
sub compareCCpattern {
    local ($dssp,$want) = @_ ;
    local ($abc,$it,$ct,$string,@pos,$pos,@permut,$permut,$nWant,$nDssp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   compareCCpattern            checks whether or not the wanted and the
#                               observed C=C patterns are identical
#                               e.g. 'abcddbca' = 'abccba'
#       expected notation:      DSSP = small case letters a-z, 
#                               e.g. 'abcdbca' , where the a's, b's, c's and d's bind,
#                               in other words, the first C pair is a, the second b asf.
#       in:                     wanted and observed strings
#       out:                    1 if match (0 else)
#--------------------------------------------------------------------------------
    $abc="abcdefghijklmnopqrstuvwxyz";
				# number of C=C wanted and observed
    $nWant=int(length($want)/2);
    $nDssp=int(length($dssp)/2);
				# consistency: should be even numbers
    if ((2*$nWant) != length($want)){
	print "*** ERROR shuffleCC: $nWant from want=$want, not even number\n";
	exit;}
    if ((2*$nDssp) != length($dssp)){
	print "*** ERROR shuffleCC: $nDssp from dssp=$dssp, not even number\n";
	exit;}
				# ------------------------------
				# get all possible permutation of observed
    @permut=			# calling external function (lib-comp.pl)
	&func_permut_mod($nDssp);
				# ------------------------------
    foreach $permut (@permut){	# scan permutations
	if (length($permut)==(2*$nWant-1)){ # only those with at least nWant sites
	    $#pos=0;@pos=split(/,/,$permut); # get positions
	    $ct=0;$string=$dssp;
	    foreach $it(1..$#pos){++$ct;
				  $old=substr($abc,$pos[$it],1);
				  $new=substr($abc,$ct,1);$new=~tr/[a-z]/[A-Z]/;
				  $string=~s/$old/$new/g;}
	    $string=~s/[a-z]//g; # delete old
	    $string=~tr/[A-Z]/[a-z]/; # change case
	    if ($string eq $want){
		return(1);
	    }}}
    return(0);			# case MATCH has left already!
}				# end of compareCCpattern

