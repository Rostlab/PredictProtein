#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="cleans junk: /junk input number of days files are allowed to stay";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Aug,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'dir_junk', "/junk/",			# 
      '',  "",

      );
@kwd=sort (keys %par);
$Ldebug=0;
				# ------------------------------
if ($#ARGV<2){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName dir_junk number_of_days_accepted'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables

$dir_junk=$ARGV[1];
$days_ok= $ARGV[2];
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    next if ($arg eq $ARGV[2]);
    if ($arg=~/^de?bu?g$/)                { $Ldebug=         1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

				# ------------------------------
				# (1) get files
				# ------------------------------
$cmd="find ".$dir_junk." -mtime +".$days_ok;
print "--- system '$cmd'\n"     if ($Ldebug);
@file=`$cmd`;

$ct=0;
$#dir=0;
foreach $file (@file){
				# ignore
    next if ($file=~/www\//);
    $file=~s/\s//g;
    if (-d $file){
	push(@dir,$file);
	next;}
    next if (! -e $file && ! -l $file);
    unlink($file);
    if (-e $file) {
	print "*** $scrName: file=$file, could NOT be removed: check it out, man!\n";
	next;}
    ++$ct;
}
				# now dirs
foreach $dir (@dir) {
				# ignore roots
    next if ($dir eq "$dir_junk");
    next if ($dir=~/$dir_junk\/[a-z0-9]+$/);

    @tmp=stat $dir;
    $size=$tmp[8];
    next if ($size > 10);
    system("\\rm -r $dir");
    ++$ct;}

print "--- $ct directories and files removed\n";
exit;




