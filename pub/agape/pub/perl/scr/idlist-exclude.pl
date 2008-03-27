#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads a file with a list of ids (names,proteins) and excludes all found in FILE_TO_SHRINK\n".
    "     \t files written: \n".
    "     \t       new_file_to_shrink : all lines of file_to_shrink that matched an id in LIST \n".
    "     \t       lines_purged       : all lines that did NOT match\n".
    "     \t       ids_in_LIST_found  : all ids from LIST that matched\n".
    "     \t       ids_in_LIST_not    : all that did not\n".
    "     \t note: in id file: comment lines ignored, anything after '#' deleted!\n";

#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
#      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<2){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName list_of_ids file_to_exclude_from'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
    printf "%5s %-15s %-20s %-s\n","","purge",    "no value","purge dirs and ext from exclusion file";
    printf "%5s %-15s %-20s %-s\n","","beg",      "no value","consider matches at line begin only";
    printf "%5s %-15s %-20s %-s\n","","faster",   "no value","this switch does NOT return the ids";
    printf "%25s     \n","","from LIST that matched or did not, but is faster!";
    printf "%5s %-15s %-20s %-s\n","","id",       "no value","very fast ONLY for two lists of ids";


#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN"; $fhout="FHOUT"; $fhoutPurge="FHOUT_PURGE";
$LisList=0;
$fileExcl=$ARGV[1];
$fileIn=  $ARGV[2];

$#fileIn=$#chainIn=0;
$Lpurge=$LmatchBeg=0; $LslowVersion=1;
$Lisid=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    next if ($arg eq $ARGV[2]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^purge$/i)              { $Lpurge=         1;}
    elsif ($arg=~/^beg$/i)                { $LmatchBeg=      1;}
    elsif ($arg=~/^fast$/i)               { $LslowVersion=   0;}
    elsif ($arg=~/^id$/i)                 { $Lisid=          1;}
#    elsif ($arg=~/^list$/i)               { $LisList=        1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");
					    # automatic detection of list
					    $LisList=        1 if ($arg =~ /\.list/); }
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}

die ("missing input   in:$fileIn\n")   if (! -e $fileIn);
die ("missing input excl:$fileExcl\n") if (! -e $fileExcl);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;
    $fileOut=                "Out-".       $tmp.".tmp";
    $fileOutPurge=           "Out-purged-".$tmp.".tmp";
    $fileOutListOk=          "Out-idok-".  $tmp.".tmp";
    $fileOutListNo=          "Out-idno-".  $tmp.".tmp"; }
else {
    $fileOutPurge=$fileOut.  "-purged-lines.tmp"; 
    $fileOutListOk=$fileOut. "-idok.tmp"; 
    $fileOutListNo=$fileOut. "-idno.tmp"; }
    

				# ------------------------------
				# (1) read exclusion list

print "--- $scrName: working on list of ids=$fileExcl!\n";
$#excl=0;
undef %excl;
open("$fhin", "$fileExcl") || die '*** $scrName ERROR opening file $fileExcl';
while (<$fhin>) {
    $_=~s/\n|\s//g;
    next if ($_=~/^\#/);	# ignore comment lines
    $_=~s/\#.*$//g;		# purge comments
    $_=~s/^.*\/|\..*$//         if ($Lpurge);
    push(@excl,$_);
    $excl{$_}=1;
} close($fhin);

				# faster but does not give a list of those found or not found
if (! $LslowVersion) {
    $excl=join('|',@excl); }

				# ------------------------------
				# (2) read real file to grep
print "--- $scrName: working on file to grep=$fileIn!\n";
open("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
open("$fhout",">$fileOut"); 
open("$fhoutPurge",">$fileOutPurge"); 

$ctPurge=$ctKeep=0;
undef %exclFound;
$#take=0;
while (<$fhin>) {
    $rd=$_; $rd=~s/\n//g;
    $Lmatch=0; 
				# skip over header
    if ($rd=~/^\#/ || $rd=~/^[\s\t\#]+$/) {
	print $fhout "$rd\n";
	next; }
				# only for id comparison
    if ($Lisid){
	next if (defined $excl{$rd});
	push(@take,$rd);
	next;}
	

    elsif (! $LslowVersion){
	if (! $LmatchBeg) {	# match anywhere
	    $Lmatch=1           if ($rd=~/$excl/);}
	else {			# match at begin
	    $Lmatch=1           if ($rd=~/^($excl)/);}

	if ($Lmatch) { ++$ctPurge;
		       print $fhoutPurge "$rd\n";
#		       print "xx excluded: $rd\n"; 
		       next ; }
	print $fhout "$rd\n";
	next; }			# for fast version: that is it!

				# --------------------------------------------------
				# only slow version continues here

				# ------------------------------
				# loop over all patterns to exclude
    foreach $excl (@excl){
	if (! $LmatchBeg) {	# match anywhere
	    $Lmatch=1           if ($rd=~/$excl/);}
	else {			# match at begin
	    $Lmatch=1           if ($rd=~/^$excl/);}
	next if (! $Lmatch);

	++$ctPurge;
	print $fhoutPurge "$rd\n";
#	print "xx excluded: $rd (excl=$excl)\n";
	$exclFound{$excl}=1;	# keep in mind
	last; 
    }
    next if ($Lmatch);
    ++$ctKeep;
    print $fhout "$rd\n";
}
close($fhin); close($fhout); close($fhoutPurge);

				# ------------------------------
				# write lists of matching, non-
				#    matching from LIST
if ($Lisid){
    open("$fhout",">$fileOutListOk"); 
    foreach $ok (@take) {
	print $fhout $ok,"\n";
    }
    close($fhout);
    print "--- idlist only one output file=$fileOutListOk\n";
    exit;
}


if ($LslowVersion ){
    open("$fhout",">$fileOutListOk"); 
    open("$fhoutPurge",">$fileOutListNo"); 
    $ctOk=$ctNo=0;
    foreach $excl (@excl) {
				# was found
	if (defined $exclFound{$excl}){
	    ++$ctOk;
	    print $fhout      "$excl\n";}
	else {			# was not
	    ++$ctNo;
	    print $fhoutPurge "$excl\n";} }

    close($fhout); close($fhoutPurge); 
    unlink($fileOutListOk)   if ($ctOk == 0);
    unlink($fileOutListNo)      if ($ctNo == 0); }
	


unlink ($fileOutPurge)          if ($ctPurge == 0);

				# ------------------------------
				# final commands

print  "--- $scrName ended, output in:\n";

printf  
    "--- %5d lines from:%-s not found in:%-s file=%-s\n",
    $ctKeep,$fileIn,$fileExcl,$fileOut           if (-e $fileOut);
printf  
    "--- %5d lines from:%-s matched  ids:%-s file=%-s\n",
    $ctPurge,$fileIn,$fileExcl,$fileOutPurge     if (-e $fileOutPurge);

if ($LslowVersion) {		# slower version
    printf  
	"--- %5d ids from:%-s   matched in:%-s file=%-s\n",
	$ctOk,$fileExcl,$fileIn,$fileOutListOk;
    printf  
	"--- %5d ids from:%-s not found in:%-s file:%-s\n",
	$ctNo,$fileExcl,$fileIn,$fileOutListNo; }
else {
    print "--- you chose the faster option -> no statistics on ids from $fileExcl\n";}

exit;
