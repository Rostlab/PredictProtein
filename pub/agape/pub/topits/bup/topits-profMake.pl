#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="calls profile_make and makes profile with PHD for MaxHom";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
                                # ------------------------------
                                # defaults
$par{"exeProfileMake"}= "/home/rost/pub/max/bin/profile_make.$ARCH";
$par{"exeProfileMake"}= "/sander/purple1/rost/max/bin/profile_make_new.SGI64";

                                # ------------------------------
if ($#ARGV<2){                  # help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file.hssp file.rdbPhd'\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileHsspIn=$ARGV[1];
$filePhdIn= $ARGV[2];
$tmp=$fileHsspIn;$tmp=~s/^.*\///g;$tmp=~s/\.hssp|[\_\!]///g;$fileOut=$tmp.".profileTopits";

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1] || $_ eq $ARGV[2]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^ARCH=(.*)$/){$ARCH=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {$Lok=0;
          foreach $kwd ("exeProfileMake"){
              if ($_=~/^$kwd=(.*)$/){$par{"$kwd"}=$1;
                                     $Lok=1;
                                     last;}}
          if (! $Lok){
              print"*** wrong command line arg '$_'\n";
              die;}}}
				# ------------------------------
				# check existence
foreach $file ($fileHsspIn,$filePhdIn,$par{"exeProfileMake"}){
    if (! -e $file){ print "*** $scrName '$file' missing\n";
                     exit;}}
				# ------------------------------
				# (1) make the HSSP profile
($Lok,$msg)=
    &profileMakeHssp($fileHsspIn,$fileOut,$par{"exeProfileMake"},"STDOUT");

print "xx fileout=$fileOut\n";
exit;                           # xx

				# ------------------------------
				# (1) read file PHD
&open_file("$fhin", "$filePhdIn");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge directory
}
close($fhin);
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge directory
}
close($fhin);

				# ------------------------------
				# (2) 

				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
close($fhout);

print "--- output in $fileOut\n";
exit;

#===============================================================================
sub profileMakeHssp {
    local($fileInLoc,$fileOutLoc,$exeProfileMakeLoc,$fhTrace)= @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   profileMakeHssp                       
#                               c
#       in:                     
#         $fhoutLoc             file handle print output
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."profileMakeHssp";$fhinLoc="FHIN"."$sbrName";

    $fhTrace="STDOUT" if (!defined $fhTrace);
    return(0,"*** $sbrName: not def fileInLoc!")                if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")               if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def exeProfileMakeLoc!")        if (! defined $exeProfileMakeLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")        if (! -e $fileInLoc);
    return(0,"*** $sbrName: miss in exe '$exeProfileMakeLoc'!") if (! -e $exeProfileMakeLoc);
    
                                # ------------------------------
                                # defaults
    $anSelectOption="EXIT";     # can be: Box, Metric, Profile, Exit, ...
    $anNo="NO";

    eval "\$command=\"$exeProfileMakeLoc , $fileInLoc, $fileOutLoc, $anSelectOption, $anNo\"";
         
    $msgHere.="--- $sbrName \t make profile ($command)\n";
                                # ------------------------------
                                # run
    $Lok=
        &run_program("$command",$fhTrace); # its running!
    return (0,"$msgHere\n".$Lok) if (! $Lok);
    return(1,"ok $sbrName
}				# end of profileMakeHssp

