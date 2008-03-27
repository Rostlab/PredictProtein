#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="changes profile for few distant homologues in HSSP file";
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
      'dirHssp',      "/home/rost/data/hssp/",
      'extIn',        ".hssp",
      'extOut',       "_skew.hssp",
      'extChain',     "_",
      'fileMatdb',    "/home/rost/pub/lib/mat/Mat-perc-hsspFil1229.rdb", # file with DB matrix
#      'fileMatdb',    "/home/rost/pub/lib/mat/Mat-perc-blosum.rdb",      # file with DB matrix
#      'fileMatdb',    "/home/rost/pub/lib/mat/Mat-perc-lachlan.rdb",     # file with DB matrix
      'naliSat',      10,	# saturation of mix
#      'naliSat',      5,	# saturation of mix
      'naliDist',     3,
      'modeDist',     "le",
      '', "",
      '', "",
      );
@kwd=sort (keys %par);
#@aa= split(//,"VLIMFWYGAPSTCHRKQEND");

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal:\t $scrGoal\n";
    print  "use: \t '$scrName file_list (or *.hssp)'\n";
    print  "opt: \t \n";
    print  "     \t fileOut=x\n";
				#      'keyword'   'value'    'description'
    printf "     \t %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "     \t %-15s  %-20s %-s\n","mat=",     "file.rdb","RDB file with db metric";
    printf "     \t %-15s  %-20s %-s\n","sat=",     "n",       "nali for saturation of mix DB/Rd";
    printf "     \t %-15s  %-20s %-s\n","dist=",    "n",       "minimal distance to count nali";
#    printf "     \t %-15s  %-20s %-s\n","",   "","";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	printf "     \t %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30;
	printf "     \t %-15s  %-20s %-s\n","other:","default settings: "," ";
	foreach $kwd (@kwd){
	    if    ($par{"$kwd"}=~/^\d+$/){
		printf "     \t %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		printf "     \t %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    else {
		printf "     \t %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)";} } }
    exit;}
				# initialise variables
#$fhin="FHIN";
#$fhout="FHOUT";

$#fileIn=$#chainIn=0;		# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1; }
    elsif ($arg=~/^mat=(.*)$/)            { $par{"fileMatdb"}=$1; }	  # db metric
    elsif ($arg=~/^sat=(.*)$/)            { $par{"naliSat"}=$1;   }
    elsif ($arg=~/^dist=(.*)$/)           { $par{"naliDist"}=$1;  }
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/$par{"extIn"}.?.?$/)    { push(@fileIn,$arg); } # all matching extension
    elsif (-e $arg)                       { push(@fileIn,$arg); } # for lists (not matching extension)
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
($Lok,$msg,$file,$chain)=
    &fileListArrayRd(join(',',@fileIn),$par{"extIn"},$par{"extChain"});
if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
	     die; }
@fileIn= split(/,/,$file);
@chainIn=split(/,/,$chain);
				# --------------------------------------------------
				# (1) read file(s)
$#fileOut=0;			# --------------------------------------------------
foreach $itfile (1..$#fileIn){
    $file= $fileIn[$itfile];
    $chain=$chainIn[$itfile];

    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$file'\n";

    if ($#fileIn==1 && defined $fileOut) {
	$fileOutLoc=$fileOut; }
    else {
	$fileOutLoc=$file; $fileOutLoc=~s/^.*\///g; $fileOutLoc=~s/$par{"extIn"}/$par{"extOut"}/; }

				# ------------------------------
				# change profile
				# ------------------------------
    ($Lok,$msg)=
	&hsspSkewProf($file,$chain,$fileOutLoc,$par{"fileMatdb"},
		      $par{"naliSat"},$par{"naliDist"},$par{"modeDist"});

    if (! $Lok) { print "*** ERROR $scrName: file=$file, c=$chain, it=$itfile\n",$msg,"\n";
		  die ; }
    push(@fileOut,$fileOutLoc);
}


print "--- output in:",join(',',@fileOut,"\n") if ($#fileOut>=1);

exit;

