#!/usr/bin/perl -w
$[ =1 ;
# removes moves all files in input file, or by date
if ($#ARGV<1){print "goal:    moves all files from input file or by pattern to DIR\n";
	      print "usage:   'script list-of-files dir-to-move-into'\n";
	      print "OR:      'script patterns dir'\n";
	      print "option:  older hour=22|day=31|month=2|year=97 (remove older than that)\n";
	      print "         newer hour=22|day=31|month=2|year=97 (remove newer files)\n";
	      print "         pat='*X*'  (will list all with *X* and apply older/newer\n";
	      print "         dir=x      (default: current, i.e. dir to move from)\n";
	      print "         size=5     (remove those smaller)\n";
	      print "         \n";
	      exit;}
$older=$newer=0;
foreach $_(@ARGV){
    if    ($_=~/^older/)      {$older=1;}
    elsif ($_=~/^newer/)      {$newer=1;}
    elsif ($_=~/^hour=(\d+)/) {$hour=$1; $mode="hour";}
    elsif ($_=~/^day=(\d+)/)  {$day=$1;  $mode="day";}
    elsif ($_=~/^month=(\d+)/){$month=$1;$mode="month";}
    elsif ($_=~/^year=(\d+)/) {$year=$1; $mode="year";}
    elsif ($_=~/^pat=(.+)$/)  {$pat=$1;}
    elsif ($_=~/^dir=(.+)$/)  {$dir=$1;}
    elsif ($_=~/^size=(.+)$/) {$size=$1;}
    elsif (-d $_)             {$dirInto=$_;}
    elsif (-e $_)             {$fileIn=$_;}
    else { print "*** wrong command line argument\n";
	   die;}}
if (!defined $dirInto || ! -d $dirInto){
    print "*** you HAVE to give an existing directory to move to \n";
    die;}
				# ------------------------------
				# mode: is file list
if (defined $fileIn){
    $#fileIn=0;
    $fhin="FHIN";
    open ("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\n//g; 
		     if ($_=~/\*$/){chop $_;} # chop stars
		      if (-e $_){
			 push(@fileIn,$_);}
		     else {
			 print "missing?? '$_'\n";}}close($fhin);
    foreach $file (@fileIn){
	$arg="mv $file $dirInto"; print "--- system \t '$arg'\n";
	system("$arg");
    }
    exit; }
				# ------------------------------
				# mode make list, then do..
if (! defined $dir || ! -d $dir){
    if (defined $ENV{'PWD'}){
	$dir=$ENV{'PWD'};}
    else {
	$dir=".";}}

@list=`ls -l $dir`;		# list all files

				# process 'ls -l'
$#usr=$#file=$#size=$#month=$#day=$#date=0;
foreach $tmp (@list){
    next if ($tmp=~/^total/);
    @tmp=split(/\s+/,$tmp);
    $file=$tmp[8];
    next if ((defined $pat)&&($file !~ /$pat/));
    push(@file,$tmp[8]);push(@usr,$tmp[3]);push(@size,$tmp[4]);
    push(@month,$tmp[5]);push(@day,$tmp[6]);push(@date,$tmp[7]);}

if (defined $size){
    foreach $it (1..$#file){
	if ($size[$it] < $size) { 
	    print "--- size= $size[$it] => remove $file[$it]\n";
	    system("mv $file[$it] $dirInto");
	}}}
else {				# currently only one of the following
    if    ($mode eq "hour") {@do=@date; $do=$hour;} # watch it: year = hour
    elsif ($mode eq "day")  {@do=@day;  $do=$day;}
    elsif ($mode eq "month"){@do=@month;$do=$month;}
    elsif ($mode eq "year") {@do=@date; $do=$year;} # watch it: year = hour

    foreach $it (1..$#file){
	print "xx checks $file[$it], (mode=$mode, older=$older, do=$do val=$do[$it])\n";
	next if ( ($mode eq "hour") && ($do[$it] !~ /\:/) );
	next if ( ($mode eq "year") && ($do[$it] =~ /\:/) );
	if ($mode eq "hour"){$do[$it]=~s/\:\d+$//g;}
	if    ($older && ($do[$it] < $do)){
	    print "--- $mode: $do[$it] => remove $file[$it]\n";
	    system("mv $file[$it] $dirInto");
	}
	elsif ($newer && ($do[$it] > $do)){
	    print "--- $mode= $do[$it] => remove $file[$it]\n";
	    system("mv $file[$it] $dirInto");
	}}}

exit;
