#!/usr/bin/perl
#
$scriptName=$0;$scriptName=~s/^.*\/|\.pl//g;
#  
#  does a tar on a directory for which argument list is too long
#
$[ =1 ;

$par{"nmax"}=1000;
$par{"nmax"}=500;
				# help
if ($#ARGV<2){print "goal:    runs a command on a directory for which argument list is too long\n";
	      print "usage:   'script 'command' dir' (dir ='.' for current, files also as *file)\n";
	      print "options: pat=x       (pattern to be matched in file list)\n";
	      print "         dev=x       (default file, alternative tape=/dev/tape, dat=/dev/dat)\n";
	      print "         nmax=x      (maximal number of files in one go: SGI specific)\n";
	      print "syntax:  'copf FILE' would run copf on all files in directory\n";
	      exit;}
				# command line
$command=$ARGV[1];
$dirIn=  $ARGV[2]; $dirIn=~s/^dirIn=//i;
$#fileIn=0;
foreach $_(@ARGV){next if ($_ eq $ARGV[1]);
		  next if ($_ eq $ARGV[2]);
		  if   ($_=~/^pat=(.*)$/) {$pat=$1;}
		  elsif($_=~/^dev=(.*)$/) {$dev=$1;}
		  elsif($_=~/^nmax=(.*)$/){$par{"nmax"}=$1;}
		  elsif(-e $_)            {push(@fileIn,$_);}
		  else {print"*** wrong command line arg '$_'\n";
			die;}}
				# check
$PWD=$ENV{'PWD'}    if (defined $ENV{'PWD'});
$PWD=`pwd`          if (! defined $PWD || ! -d $PWD);

$dirIn=$PWD         if ($dirIn eq "." && defined $PWD && -d $PWD);
$pat=""             if (! defined $pat);
# 

if (! -d $dirIn && $#fileIn < 1 ) {
    print "*** directory '$dirIn' not existing, and no file given on command line\n";
#    die;
}

if ($#fileIn>0){
    @file=@fileIn;}
else {				# list all files (should be local after chdir)
    @file=&fileLsAll($dirIn);
}

$#tmp=0;			# ------------------------------
foreach $file(@file){		# filter those not matching pattern
    $tmp=$file;
    $tmp=~s/$dirInTmp//g if (defined $dirInTmp && length($dirInTmp)>0 && $LremovePath);
    next if (length($tmp)<1);
    next if ($tmp =~/\// && $LremovePath); # skip if subdirectory
    next if ($file !~ /$pat/);
    next if ($file !~ /^(.*\/)?1\w\w\w\.hssp/);
#     next if ($Lbeg && $file !~/^$pat/);
#     next if ($Lend && $file !~/$pat$/);
#     next if (! $Lbeg && ! $Lend && $file !~ /$pat/);
    push(@tmp,$tmp) if (-e $file);
}
$#file=0;
@file=@tmp;
				# ------------------------------
				# do the command
$numRepeat=1+int($#file/$par{"nmax"});
foreach $it (1..$numRepeat){
    $itBeg=1+($it-1)*$par{"nmax"};
    $itEnd=$itBeg+$par{"nmax"}-1; $itEnd=$#file if ($#file<$itEnd);

    $tmp=join(' ',@file[$itBeg..$itEnd]);

    $cmd=$command;
    $cmd=~s/FILE/$tmp/i;

    print "--- $cmd\n";
    system("$cmd");
}

exit;


#==========================================================================================
sub fileLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   dirLsAll                    will return all directories in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    if (! defined $dirLoc || $dirLoc eq "." || 
	length($dirLoc)==0 || $dirLoc eq " " || ! $dirLoc){
	if (defined $ENV{'PWD'}){
	    $dirLoc=$ENV{'PWD'}; }
	else {
	    $dirLoc=`pwd`; } }
				# directory missing/empty
    return(0)                   if (! -d $dirLoc || ! defined $dirLoc || $dirLoc eq "." || 
				    length($dirLoc)==0 || $dirLoc eq " " || ! $dirLoc);
				# ok, now do
    $sbrName="fileLsAll";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# read dir
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$_=~s/\s//g; 
		       next if ($_=~/\$/);
				# avoid reading subdirectories
		       $tmp=$_;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
#		       next if ($tmp=~/^\//);
		       next if (-d $_);
		       push(@tmp,$_);}close($fhinLoc);
    return(@tmp);
}				# end of dirLsAll

