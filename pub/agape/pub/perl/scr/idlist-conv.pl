#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads a file with a list of ids (names,proteins) and\n".
    "     \t adds directory AND|OR extension\n".
    "     \t purges chain (returns unique list!)\n".
    "     \t gets only the id (for file_list) \n".
    "     \t NOTE: if dir or ext given, they will be added!!\n";
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
if ($#ARGV < 1){		# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName list '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
    printf "%5s %-15s=%-20s %-s\n","","dir",      "x",       "directory to add";
    printf "%5s %-15s=%-20s %-s\n","","ext",      "x",       "extension to add";

    printf "%5s %-15s=%-20s %-s\n","","purge",    "dir,ext", "purge dir,extension";
    printf "%5s %-15s %-20s %-s\n","","purge",    "no value","purges dir AND extension!!";

    printf "%5s %-15s %-20s %-s\n","","nochn",    "no value","purges chain";
    printf "%5s %-15s %-20s %-s\n","","uni",      "no value","if chain purged, write only unique ids";
    printf "%5s %-15s %-20s %-s\n","","chn=end",  "no value","puts chain at end (1cse.hssp_I)";
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
$fhin="FHIN"; $fhout="FHOUT"; 

$#fileIn=0;$Lpurge=0;
undef $purge;
$Luni=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^dir=(.*)$/)            { $dir=$1;}
    elsif ($arg=~/^ext=(.*)$/)            { $ext=$1;}
    elsif ($arg=~/^purge=(.*)$/)          { $purge=$1; }
    elsif ($arg=~/^purge$/)               { $Lpurge=1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^nochn$/i)              { $LchnDel=      1;}
    elsif ($arg=~/^uni$/i)                { $LchnDel=      1;
					    $Luni=         1;}
    elsif ($arg=~/^chn=end$/i)            { $LchnEnd=      1;}
    elsif (-e $arg)                       { push(@fileIn,$arg);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}
				# treat dir
$dir.="/"                       if (defined $dir && $dir !~/\/$/);

$fileIn=$fileIn[1];
die ("missing input   in:$fileIn\n")   if (! -e $fileIn);

if (! defined $fileOut && $#fileIn == 1){
    $tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;
    $fileOut=                "Out-".$tmp.".tmp"; }
elsif ($#fileIn > 1) {
    print "--- ","- * -" x 20,"\n";
    print "--- watcha for more than one input file, the name of the output file will\n";
    print "--- be assigned automatically!\n";
    print "--- ","- * -" x 20,"\n";
    $fileOut=0; }

@purge=split(/,/,$purge)        if (defined $purge && ! $Lpurge);

				# ------------------------------
				# (1) read list
foreach $fileIn (@fileIn) {
    print "--- $scrName: working on '$fileIn'\n";

    open("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';

    undef %id; 
    $#id=0;

    while (<$fhin>) {
	$rd=$_; $rd=~s/\n//g; 
				# --------------------
				# purge chain
	$rd=~s/[_:][A-Z0-9]$//     if (defined $LchnDel && $LchnDel);

				# --------------------
	if (defined $dir) {	# add dir
	    $rd=$dir.$rd; }
				# --------------------
				# .. or: purge dir
	elsif (defined $Lpurge && $Lpurge &&
	       ! defined $purge) {
	    $rd=~s/^.*\///; }
	$rd=~s/^.*\///g         if (defined $Lpurge && $Lpurge);

				# --------------------
	if (defined $ext) {	# add ext
	    if ($LchnEnd && $rd=~/[_:][A-Z0-9]$/) {
		$rd=~s/^(.*)([_:][A-Z0-9])$/$1$ext$2/; }
	    else {
		$rd.=$ext; }}
				# --------------------
				# .. or: purge ext
	elsif (! defined $purge) {
	    $keepChn="";	# keep chain
	    $keepChn=$1         if (defined $LchnDel && ! $LchnDel && $rd=~/([_:][A-Z0-9])$/);
	    $rd=~s/\..*$//g     if (defined $LchnDel && $LchnDel); 
	    $rd=~s/\..*$//g	if (defined $Lpurge && $Lpurge); # watch it same as before!!!
	    $rd.=$keepChn       if (length($keepChn)>0);}
				# --------------------
				# to purge
	if (defined $purge) {
	    foreach $tmp (@purge) {
		$rd=~s/$tmp//g;}}

	if (! defined $id{$rd}) {
	    $id{$rd}=1; push(@id,$rd); }
    }
    close($fhin);

				# ------------------------------
				# write out:
    if ($#fileIn > 1) {
	$fileOut=$fileIn; $fileOut=~s/^.*\///g; $fileOut="Out-".$fileOut; }
    open("$fhout",">".$fileOut); 
    undef %tmp;
    foreach $id (@id) {
	next if ($LchnDel && $Luni && defined $tmp{$id});
	$tmp{$id}=1;
	print $fhout "$id\n";
    }
    close($fhout); 
    print "--- wrote $fileOut\n" if (-e $fileOut);

}

print  "--- $scrName ended\n";

exit;
