#!/bin/env perl
#----------------------------------------------------------------------
# usage: 	port-unpack dir
# task:		unzip,untar,unzip on dir
# 		
#----------------------------------------------------------------------#
#	Burkhard Rost		       January,         1997           #
#			changed:       .	,    	1997           #
#	EMBL			       Version 0.1                     #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;

if ($ARGV[1]=~/help|^-h|^man/){
    print "--- usage:  'port-unpack /home/rost/port/'\n";
    print "--- goal:   unzip,untar,unzip on dir\n";}

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
$dir=$ARGV[1]; 
				# default
$cmdTar="tar -xvf";

if (! -d $dir){
    print "*** ERROR dir=$dir, missing\n";
    exit;}

system("gunzip *z");
system("$cmdTar *tar");
				# ------------------------------
@allDir=			# list all text files
    &lsAllDir($dir);	# external lib-ut.pl
				# ------------------------------
				# change all files
foreach $dirRd (@allDir){
    print "--- system \t 'gunzip $dirRd/*z'\n";
    system("gunzip $dirRd/*z");
}	
exit;				# 

#==========================================================================================
sub lsAllDir {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#    lsAllDir                   will return all directories in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    if (! -d $dirLoc){		# directory empty
	return(0);}
    $sbrName="lsAllDir";$fhinLoc="FHIN"."$sbrName";
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$_=~s/\s//g;
		       if (-d $_){
			   push(@tmp,$_);}}close($fhinLoc);
    return(@tmp);
}				# end of lsAllDir

