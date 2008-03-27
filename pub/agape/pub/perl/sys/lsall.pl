#!/usr/bin/perl -w
#
#  lists all files in all subdirectories
#
$[ =1 ;

				# help
if ($#ARGV<1){print "goal:    lists all files in all subdirectories\n";
	      print "usage:   script dir (or '.')\n";
	      print "options: txt|bin    (only text or binaries)\n";
	      print "         pat=xx     (only files matching this)\n";
	      print "         fileOut=x  (default: standard out)\n";
	      exit;}
				# initialise variables
$dir=$ARGV[1];
$Ltxt=$Lbin=0;
foreach $_(@ARGV){
    next if ($_ eq $dir);
    if    ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif ($_=~/^txt$/)         {$Ltxt=1;}
    elsif ($_=~/^bin$/)         {$Lbin=1;}
    elsif ($_=~/^pat=(.*)$/)    {$pat=$1;}
    elsif ($_ eq ".")           {next;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
print "--- dir \t $dir\n";
print "--- pat \t $pat\n" if (defined $pat);

if   ($Ltxt){
    @file=&fileLsAllTxt("$dir");}
else {
    @file=&fileLsAll("$dir");}

if (defined $fileOut){
    open("$fhout",">$fileOut") || die "*** failed opening output file=$fileOut"; }
else {
    $fh="STDOUT";}

foreach $file(@file){
    next if ($Lbin && (-T $file));
    next if ((defined $pat) && ($file !~ /$pat/));
    $file=~s/^\.\///g;		# purge './'
    print $fh "$file\n";}

if (defined $fileOut){
    close($fh);
    print "--- output in $fileOut\n";}

exit;

#==========================================================================================
sub fileLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAll                   will return a list of all files in dirLoc (and
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
}				# end of fileLsAll

#==========================================================================================
sub fileLsAllLong {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAllLong               will return 'ls -l' of all text files in dirLoc
#                               (and subdirectories therof)
#                               shitty SGI dont know 'find -ls' so hack...
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    $sbrName="fileLsAllLong";$fhinLoc="FHIN"."$sbrName";
    return(0) if (! defined $dirLoc || ! -d $dirLoc);

    $#tmp2=0;
    @tmp=&fileLsAll($dirLoc); # get a list of all text files

    foreach $tmp(@tmp){$ls=`ls -l $tmp`; 
		       push(@tmp2,"$ls");}
    return(@tmp2);
}				# end of fileLsAllLong

#==========================================================================================
sub fileLsAllTxt {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAllTxt                will return all text files in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    $sbrName="fileLsAllTxt";$fhinLoc="FHIN"."$sbrName";
    if (! -d $dirLoc){		# directory empty
	return(0);}
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$line=$_; $line=~s/\s//g;
		       if (-T $line && ($line!~/\~$/)){
			   $tmp=$line;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
			   next if ($tmp=~/\#|\~$/); # skip temporary
#			   next if ($tmp=~/\//);
			   push(@tmp,$line);}}close($fhinLoc);
    return(@tmp);
}				# end of fileLsAllTxt

