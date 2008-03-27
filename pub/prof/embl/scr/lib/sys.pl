#!/usr/bin/perl
##! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				June,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.4   	Jul,    	1998	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with routines related to system specifics |system calls.     #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   sys                         internal subroutines:
#                               ---------------------
# 
#   complete_dir                
#   completeDir                 
#   cp_file                     
#   dirLsAll                    will return all directories in dirLoc (and
#   dirMk                       1
#   file_cp                     
#   file_mv                     
#   file_rm                     
#   fileCp                      1
#   fileGetNewest               finds latest file in list (array from: fileLsAll*Long)
#   fileLsAll                   will return a list of all files in dirLoc (and
#   fileLsAllLong               will return 'ls -l' of all text files in dirLoc
#   fileLsAllTxt                will return all text files in dirLoc (and
#   fileLsLong2date             converts output from 'ls -l' to date
#   fileLsAllTxtLong            will return 'ls -l' of all text files in dirLoc
#   fileMv                      
#   fileRm                      
#   hsspGrepLen                 greps the 'SEQLENGTH  ddd' line from HSSP files
#   hsspGrepNali                greps the 'NALIGN  ddd' line from HSSP files
#   hsspGrepPdbid               greps all PDB ids from HSSP files
#   identify_current_user       
#   lsAllDir                    
#   lsAllFiles                  
#   lsAllTxtFiles               
#   pdbGrepResolution           greps the 'RESOLUTION' line from PDB files
#   run_program                 1
#   runSys                      1
#   sysCatfile                  system call 'cat < file1 >> file2'
#   sysCpfile                   system call '\\cp file1 file2' (or to dir)
#   sysDate                     returns $Date
#   sysEchofile                 system call 'echo  $echo >> file'
#   sysGetPwd                   returns local directory
#   sysGetUser                  returns $USER (i.e. user name)
#   sysMkdir                    system call 'mkdir'
#   sysMvfile                   system call '\\mv file'
#   sysRmdir                    removes directory
#   sysRunProg                  pipes arguments into $prog, and cats the output
#   sysSendMailAlarm            sends alarm mail to user
#   sysSystem                   simple way of running system command + documenting them
#   tarRemovePath               removes a dead path from tar file
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   sys                         external subroutines:
#                               ---------------------
# 
#   call from scr:              errSbr,month2num
# 
#   call from sys:              fileLsAll,fileLsAllTxt,fileLsLong2date,sysCpfile,sysMvfile
#                               sysRmdir
# 
#   call from system:            
#                               echo '$messageLoc' | $exe_mailLoc -s PP_ERROR $userLocecho '$messageLoc' | $exe_mailLoc -s PP_ERROR $userLoc
# 
#   call from missing:           
#                               ctime
#                               localtime
# 
# 
# -----------------------------------------------------------------------------# 
# 
##
#===============================================================================
# 
# bb: BEGIN of library
#
#===============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir

#===============================================================================
sub completeDir  { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of completeDir

#===============================================================================
sub cp_file { @outLoc=&fileCp(@_);return(@outLoc);} # alias

#===============================================================================
sub dirLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   dirLsAll                    will return all directories in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    return(0)                   if (! -d $dirLoc); # directory empty
    $sbrName="dirLsAll";$fhinLoc="FHIN"."$sbrName";$#tmp=0;
    $#tmp=0;
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>)    { $_=~s/\s//g;
			    next if (! -d $_);
			    push(@tmp,$_); } close($fhinLoc);
    return(@tmp)                if ($#tmp>1);
				# ------------------------------
				# may have failed for big dirs 
    $#tmp=$#tmp2=0;
    @tmp2=`ls -a1 $dirLoc`; 
    $dirLocTmp=$dirLoc; $dirLocTmp.="/" if ($dirLocTmp !~/\/$/);
    foreach $tmp (@tmp2)  { $tmp=~s/\s|\n//g;
			    next if ($tmp eq ".");
			    next if ($tmp eq "..");
			    next if (length($tmp)<1);
			    $tmp=$dirLocTmp.$tmp;
			    next if (! -d $tmp);
			    push(@tmp,$tmp); } 
    $#tmp2=0;
    return(@tmp);
}				# end of dirLsAll

#==========================================================================
sub dirMk  { 
    local($fhoutLoc,@dirLoc)=@_; local($tmp,@tmp,$Lok,$dirLoc);
    $[ =1 ;
    if   (! defined $fhoutLoc){ 
	$fhoutLoc=0;push(@dirLoc,$fhoutLoc);}
    elsif(($fhoutLoc!~/[^0-9]/)&&($fhoutLoc == 1)) { 
	$fhoutLoc="STDOUT";}
    $Lok=1;$#tmp=0;
    foreach $dirLoc(@dirLoc){
	if ((! defined $dirLoc)||(length($dirLoc)<1)){
	    $tmp="-*- WARNING 'lib-sys:dirMk' '$dirLoc' pretty useless";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    push(@tmp,$tmp);
	    next;}
	if (-d $dirLoc){
	    $tmp="-*- WARNING 'lib-sys:dirMk' '$dirLoc' exists already";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    push(@tmp,$tmp);
	    next;}
	$dirLoc=~s/\/$//g; # purge trailing '/'
	$tmp="'mkdir $dirLoc'"; push(@tmp,$tmp);
	printf $fhoutLoc "--- %-20s %-s\n","fct:","$tmp" if ($fhoutLoc);
	$Lok= mkdir ($dirLoc,umask);
	if (! -d $dirLoc){
	    $tmp="*** ERROR 'lib-sys:dirMk' '$dirLoc' not made";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    $Lok=0; push(@tmp,$tmp);}}
    return($Lok,@tmp);
}				# end of dirMk

#==========================================================================
sub file_cp { @outLoc=&fileCp(@_);return(@outLoc);} # alias
sub file_mv { @outLoc=&fileMv(@_);return(@outLoc);} # alias
sub file_rm { @outLoc=&fileRm(@_);return(@outLoc);} # alias

#==========================================================================
sub fileCp  { 
    local($f1,$f2,$fhoutLoc)=@_; local($tmp);
    $[ =1 ;
    if   (! defined $fhoutLoc){ 
	$fhoutLoc=0;}
    elsif($fhoutLoc eq "1")     { 
	$fhoutLoc="STDOUT";}
    if (! -e $f1){$tmp="*** ERROR 'lib-sys:fileCp' in=$f1, missing";
		  if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		  return(0,"$tmp");}
    if (! defined $f2){$tmp="*** ERROR 'lib-sys:fileCp' f2=$f2, undefined";
		       if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		       return(0,"$tmp");}
    $tmp="'\\cp $f1 $f2'";
    printf $fhoutLoc "--- %-20s %-s\n","&sysCpfile","$tmp" if ($fhoutLoc);
    $Lok=&sysCpfile($f1,$f2);
    if (! -e $f2){$tmp="*** ERROR 'lib-sys:fileCp' out=$f2, missing";
		  if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		  return(0,"$tmp");}
    return(1,"$tmp");
}				# end of fileCp

#===============================================================================
sub fileGetNewest {
    local($dateIn,$opt,@listIn) = @_ ;
    local($sbrName,$monIn,$dayIn,$yearIn,$mon,$day,$year,@tmp,$tmp,
	  $monNew,$dayNew,$yearNew,$line,@all);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileGetNewest               finds latest file in list (array from: fileLsAll*Long)
#       in:                     $date,$opt,@list
#         $date=                Feb-3-1998
#         $opt=                 [one|all] -> returns dates for one, or many!
#         @list=                array from: fileLsAll*Long
#                               '-rwxr-xr-x  1 rost         1368 Jan 12 06:44 file'
#       out:                    $date,$file,@dates (of all others) (date=13-2-1998)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fileGetNewest";$fhinLoc="FHIN"."$sbrName";
    ($monIn,$dayIn,$yearIn)=split(/-/,$dateIn);
    $#all=0;
    $dayNew="19";$monNew="1";$yearNew="1906"; # ini
    $ct=0;
    foreach $line(@listIn){
	$line=~s/\n//g;
	($tmp,$day,$mon,$year)=&fileLsLong2date($dateIn,$line);
	$file=$line;$file=~s/^.*\s+(\S+)$/$1/g;
	if   ($year>$yearNew){
	    $yearNew=$year;$dayNew=$day;$monNew=$mon;$fileNew=$file;}
	elsif(($year==$yearNew)&&($mon >$monNew)){
	    $yearNew=$year;$dayNew=$day;$monNew=$mon;$fileNew=$file;}
	elsif(($year==$yearNew)&&($mon==$monNew)&&($day >$dayNew)){
	    $yearNew=$year;$dayNew=$day;$monNew=$mon;$fileNew=$file;}
	if ($opt eq "all"){push(@all,"$day-$mon-$year");}}
    return("$dayNew-$monNew-$yearNew",$fileNew,@all);
}				# end of fileGetNewest

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
    local($dirLoc,$exprLoc) = @_ ;
    local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAllTxt                will return all text files in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc : directory to search
#       in:                     exprLoc: expression to search " " for nothing
#       out:                    @files
#--------------------------------------------------------------------------------
    $sbrName="fileLsAllTxt";$fhinLoc="FHIN"."$sbrName";
    return(0)                   if (! -d $dirLoc);	# directory empty
    if (defined $exprLoc && length($exprLoc)>0 && $exprLoc ne " "){
	$cmd="find $dirLoc -name '$exprLoc' -print";}
    else {
	$cmd="find $dirLoc -print";}
	
    open($fhinLoc,$cmd." |");
    while (<$fhinLoc>){
	$line=$_; $line=~s/\s//g;
	if (-T $line && 
	    $line!~/\~$/){
	    $tmp=$line;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
				# skip temporary
	    next if ($tmp=~/\#|\~$/);
	    push(@tmp,$line);}
    }
    close($fhinLoc);
    return(@tmp);
}				# end of fileLsAllTxt

#===============================================================================
sub fileLsLong2date {
    local($dateIn2,$lineIn2) = @_ ;
    local($sbrName,$monIn2,$dayIn2,$yearIn2,$monLoc,$dayLoc,$yearLoc,@tmp,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileLsLong2date             converts output from 'ls -l' to date
#       in:                     $dateIn,$lineIn
#         $date=                Feb-3-1998
#         $line (SUN)=          '-rwxr-xr-x  1 rost         1368 Jan 12 06:44 file'
#         $line (other)=        '-rwxr-xr-x  1 rost  group       1368 Jan 12 06:44 file'
#       out:                    $date,$day,$month,$year (date=13-2-1998)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fileLsLong2date";$fhinLoc="FHIN"."$sbrName";
    return (0) if (! defined $dateIn2 || ! defined $lineIn2);
    ($monIn2,$dayIn2,$yearIn2)=split(/-/,$dateIn2);
    @tmp=split(/\s+/,$lineIn2);

    if ($tmp[4]=~/[^0-9]/){	# 4 is group (on SGI/DEC)
	$monLoc=&month2num($tmp[6]);$dayLoc=$tmp[7];$yearLoc=$tmp[8];}
    else {
	$monLoc=&month2num($tmp[5]);$dayLoc=$tmp[6];$yearLoc=$tmp[7];}
				# process year
    if    (($yearLoc=~/:/)&&($monLoc>$monIn2)){
	$yearLoc=($yearIn2-1);}
    elsif ($yearLoc=~/:/){
	$yearLoc=$yearIn2;}
    return("$dayLoc-$monLoc-$yearLoc",$dayLoc,$monLoc,$yearLoc);
}				# end of fileLsLong2date

#==========================================================================================
sub fileLsAllTxtLong {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAllTxtLong            will return 'ls -l' of all text files in dirLoc
#                               (and subdirectories therof)
#                               shitty SGI dont know 'find -ls' so hack...
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    $sbrName="fileLsAllTxtLong";$fhinLoc="FHIN"."$sbrName";
    return(0) if (! defined $dirLoc || ! -d $dirLoc);

    $#tmp2=0;
    @tmp=&fileLsAllTxt($dirLoc); # get a list of all text files

    foreach $tmp(@tmp){$ls=`ls -l $tmp`; 
		       push(@tmp2,"$ls");}
    return(@tmp2);
}				# end of fileLsAllTxtLong

#==========================================================================
sub fileMv  { local($f1,$f2,$fhoutLoc)=@_; local($tmp);
	      if (! -e $f1){$tmp="*** ERROR 'lib-sys:fileMv' in=$f1, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      $tmp="'\\mv $f1 $f2'";
	      printf $fhoutLoc "--- %-20s %-s\n","&sysMvfile","$tmp" if ($fhoutLoc);
	      $Lok=&sysMvfile($f1,$f2);
	      if (! -e $f2){$tmp="*** ERROR 'lib-sys:fileMv' out=$f2, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      return(1,"$tmp");} # end of fileMv

#==========================================================================
sub fileRm  { local($fhoutLoc,@fileLoc)=@_; local($tmp,@tmp,$Lok,$fileLoc);
	      if (-e $fhoutLoc){push(@fileLoc,$fhoutLoc);$fhoutLoc=0;}
	      $Lok=1;$#tmp=0;
	      foreach $fileLoc(@fileLoc){
		  if (-e $fileLoc){
		      $tmp="'\\rm $fileLoc'"; push(@tmp,$tmp);
		      printf $fhoutLoc "--- %-20s %-s\n","unlink ","$tmp" if ($fhoutLoc);
                      unlink($fileLoc);}
		  if (-e $fileLoc){
		      $tmp="*** ERROR 'lib-sys:fileRm' '$fileLoc' not deleted";
		      if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		      $Lok=0; push(@tmp,$tmp);}}
	      return($Lok,@tmp);} # end of fileRm

#===============================================================================
sub hsspGrepLen {
    local($fileInLoc,$exclLoc,$modeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspGrepLen                 greps the 'SEQLENGTH  ddd' line from HSSP files
#       in:                     $fileInLoc=  file
#       in:                     $exclLoc=    limit for LEN  (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       out:                    1|0,msg,$len (0 if condition not fulfilled)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."hsspGrepLen";$fhinLoc="FHIN_"."hsspGrepLen";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $exclLoc=$modeLoc=0                            if (! defined $exclLoc || ! defined $modeLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep '^SEQLENGTH' $fileInLoc`; 
				# process output

    $tmp=~s/^SEQLENGTH\s*(\d+).*$/$1/g; $tmp=~s/\n|\s//g;
    $Lok=1;
				# restrict?
    if (defined $exclLoc && $exclLoc) { 
	$Lok=0  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	$Lok=0  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	$Lok=0  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	$Lok=0  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }
    $tmp=0                      if (! $Lok);
    return(1,"ok $sbrName",$tmp);
}				# end of hsspGrepLen

#===============================================================================
sub hsspGrepNali {
    local($fileInLoc,$exclLoc,$modeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspGrepNali                greps the 'NALIGN  ddd' line from HSSP files
#       in:                     $fileInLoc=  file
#       in:                     $exclLoc=    limit for NALI (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       out:                    1|0,msg,$nali (0 if condition not fulfilled)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."hsspGrepNali";$fhinLoc="FHIN_"."hsspGrepNali";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $exclLoc=$modeLoc=0                            if (! defined $exclLoc || ! defined $modeLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep '^NALIGN' $fileInLoc`; 
				# process output
    $tmp=~s/^NALIGN\s*(\d+).*$/$1/g; $tmp=~s/\n|\s//g;
    $Lok=1;
				# restrict?
    if (defined $exclLoc && $exclLoc) { 
	$Lok=0  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	$Lok=0  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	$Lok=0  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	$Lok=0  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }
    $tmp=0                      if (! $Lok);
    return(1,"ok $sbrName",$tmp);
}				# end of hsspGrepNali

#===============================================================================
sub hsspGrepPdbid {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspGrepPdbid               greps all PDB ids from HSSP files
#       in:                     $fileInLoc=  file
#       out:                    1|0,msg,$list (id1,id2,)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."hsspGrepPdbid";$fhinLoc="FHIN_"."hsspGrepPdbid";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep '^ .*[0-9]* : .* [0-9][A-Z0-9][A-Z0-9][A-Z0-9]  ' $fileInLoc`;
    @tmp=split(/\n/,$tmp);
    $other="";
    foreach $tmp (@tmp){
	$tmp=~s/^ .*[0-9]+\s*:\s*.* ([0-9][A-Z0-9][A-Z0-9][A-Z0-9]) .*$/$1/;
	$other.="$tmp," if ($tmp=~/^([0-9][A-Z0-9][A-Z0-9][A-Z0-9])$/);}
    $other=~s/,*$//g;
    $other=~tr/[A-Z]/[a-z]/;	# change case
    return(1,"ok $sbrName",$other);
}				# end of hsspGrepPdbid

#======================================================================
sub identify_current_user { $identify_current_user=&sysGetUser; }

#======================================================================
sub lsAllDir      { return(&dirLsAll(@_));} # alias

#======================================================================
sub lsAllFiles    { return(&fileLsAll(@_));} # alias

#======================================================================
sub lsAllTxtFiles { return(&fileLsAllTxt(@_));} # alias

#===============================================================================
sub pdbGrepResolution {
    local($fileInLoc,$exclLoc,$modeLoc,$resMaxLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbGrepResolution           greps the 'RESOLUTION' line from PDB files
#       in:                     $fileInLoc=  file
#       in:                     $exclLoc=    limit for RESOLUTION  (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       in:                     $resMaxLoc=  resolution assigned if none found
#       out:                    1|0,msg,$res (0 if condition not fulfilled)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."pdbGrepResolution";$fhinLoc="FHIN_"."pdbGrepResolution";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $exclLoc=$modeLoc=0                            if (! defined $exclLoc || ! defined $modeLoc);
    $resMaxLoc=1107                                if (! defined $resMaxLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep 'RESOLUTION\. ' $fileInLoc`; 
				# process output
    $tmp=~s/\n//g;
    if ($tmp=~/^.*RESOLUTION\.\s*([\d\.]+) .*$/){
	$tmp=~s/^.*RESOLUTION\.\s*([\d\.]+) .*$/$1/g; $tmp=~s/\n|\s//g;}
    else {
	$tmp=$resMaxLoc;}
    $Lok=1;
				# restrict?
    if (defined $exclLoc && $exclLoc) { 
	$Lok=0  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	$Lok=0  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	$Lok=0  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	$Lok=0  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }
    $tmp=0                      if (! $Lok);
    return(1,"ok $sbrName",$tmp);
}				# end of pdbGrepResolution

#======================================================================
sub run_program {
    local ($cmd,$fhLogFile,$action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    print "--- running command: \t $cmdtmp"  if ((! defined $Lverb)||$Lverb);
    print " do='$action'"                    if (defined $action); 
    print "\n" ;
				# opens cmdtmp into pipe
    open (TMP_CMD, "|$cmdtmp") || 
	(do {print $fhLogFile "Cannot run command: $cmdtmp\n" if ( $fhLogFile ) || 
		 warn "Cannot run command: '$cmdtmp'\n" ;
	     exec '$action' if (defined $action);
	 });

    foreach $command (@out_command) { # delete end of line, and leading blanks
	$command=~s/\n//; $command=~s/^\s*|\s*$//g;
	print TMP_CMD "$command\n" ;
    }
    close (TMP_CMD) ;		# upon closing: cmdtmp < @out_command executed
}				# end of run_program

#======================================================================
sub runSys {
    local ($cmd,$FHlog,$action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    if ($FHlog) {print $FHlog "--- running command: \t $cmdtmp";
		 if (defined $action){print $FHlog "do='$action'";}print $FHlog "\n" ;}

    open (TMP_CMD, "|$cmdtmp") || ( do {
	if ( $FHlog ) {print $FHlog "Can't run command: $cmdtmp\n" ;}
	warn "Can't run command: '$cmdtmp'\n" ;
	if (defined $action){
	    exec $action ;}
    } );
    foreach $command (@out_command) {
	# delete end of line, and spaces in front and at the end of the string
	$command=~ s/\n|^ *//;$command=~ s/ *$//g; 
	print TMP_CMD "$command\n" ; }close (TMP_CMD) ;
}				# end of runSys

#===============================================================================
sub sysCatfile {
    local($niceLoc,$LdebugLoc,$fileToCatTo,@fileToCat) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysCatfile                  system call 'cat < file1 >> file2'
#       in:                     $niceLoc,$fileToCatTo,@fileToCat
#                               if not nice pass niceLoc=no (or nonice)
#       out:                    ok=(1,'cat a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysCatfile";
    $niceLoc="" if (! defined $niceLoc ||
		    $niceLoc =~ /^no/ || $niceLoc eq " " || length($niceLoc)==0 );
				# check
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCatTo'!")     if (! defined $fileToCatTo);
    return(0,"*** $sbrName: missing input file '$fileToCat[1]'!") if (! -e $fileToCat[1]);
				# loop over all files
    $msg="";
    foreach $fileToCat (@fileToCat){
	$Lok= system("$niceLoc cat < $fileToCat >> $fileToCatTo");
	$msg.="$sbrName \t '$niceLoc cat < $fileToCat >> $fileToCatTo'\n";
	if ($Lok != 0 || ! -e $fileToCatTo){
	    print "*** $sbrName ERROR: '$fileToCat -> $fileToCatTo' ($Lok)!"."$msg";
	    return(0,"*** $sbrName ERROR: '$fileToCat -> $fileToCatTo' ($Lok)!"."$msg");}}
    print "--- $sbrName: $msg"  if ($LdebugLoc);
    return(1,"$msg");
}				# end of sysCatfile

#===============================================================================
sub sysCpfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysCpfile                   system call '\\cp file1 file2' (or to dir)
#       in:                     file1,file2 (or dir), nice value (nice -19)
#       out:                    ok=(1,'cp a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysCpfile";
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
				# check
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!") if (! defined $fileToCopyTo);

    if (-d $fileToCopyTo){	# is directory
	$fileToCopyTo.="/"      if ($fileToCopyTo !~/\/$/);}

    $Lok= system("$niceLoc \\cp $fileToCopy $fileToCopyTo");
#    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    if    (-d $fileToCopyTo){	# is directory
	$tmp=$fileToCopy;$tmp=~s/^.*\///g;$tmp=$fileToCopyTo.$tmp;
	$Lok=0 if (! -e $tmp);}
    elsif (! -e $fileToCopyTo){ $Lok=0; }
    elsif (-e $fileToCopyTo)  { $Lok=1; }

    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    
    return(1,"$niceLoc \\cp $fileToCopy $fileToCopyTo");
}				# end of sysCpfile

#===============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/rost/perl/ctime.pl",           # HARD_CODED
	  "/nfs/data5/users/ppuser/server/pub/perl/ctime.pl",       # HARD_CODED
	  "/home/phd/server/scr/lib/ctime.pm"   # HARD_CODED
	  );
    foreach $tmp (@tmp) {
	next if (! -e $tmp && ! -l $tmp);
	$exe_ctime=$tmp;	# local ctime library
	last; }

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    $Lok=
		require($exe_ctime)
		    if (-e $exe_ctime); }
				# ------------------------------
				# found one: use it
	if ($Lok && 
	    defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);} }
				# ------------------------------
	 			# found none: take system
    if (! $Lok) {
	$localtime=`date`;
	@Date=split(/\s+/,$localtime);
	$Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]"; }
    $date=$Date; $date=~s/(199\d|200\d)\s*.*$/$1/g;
    return($Date,$date);
}				# end of sysDate

#===============================================================================
sub sysEchofile {
    local($sentence,$fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysEchofile                 system call 'echo  $echo >> file'
#       in:                     $niceLoc,$fileToCatTo,@fileToCat
#                               if not nice pass niceLoc=no (or nonice)
#       out:                    <1|0>,$errormessage,$command (for print)
#-------------------------------------------------------------------------------
    $sbrName="sysEchofile";
				# check arguments
    return(&errSbr("not def sentence!",0))          if (! defined $sentence);
    return(&errSbr("not def fileInLoc!",0))         if (! defined $fileInLoc);

    return(&errSbr("miss in file '$fileInLoc'!",0)) if (! -e $fileInLoc);
				# do
    $cmd="echo '$sentence' >> $fileInLoc";
    $prt="--- $sbrName: system '$cmd'\n";
				# run
    system("$cmd");
    return(1,"ok",$prt);
}				# end of sysEchofile

#===============================================================================
sub sysGetPwd {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysGetPwd                   returns local directory
#       out:                    $DIR (no slash at end!)
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:"."sysGetPwd";

				# already defined or in ENV?
    $pwdLoc=  $PWD || $ENV{'PWD'};

    if (-d $pwdLoc) {
	$pwdLoc=~s/\/$//g;
	return($pwdLoc); }
				# read bin/pwd
    if (-d "/bin/pwd") {
	open(C,"/bin/pwd|");
	$pwdLoc=<C>;
	close(C); }

    if (-d $pwdLoc) {
	$pwdLoc=~s/\/$//g;
	return($pwdLoc); }
				# system call
    $pwdLoc=`pwd`; 
    $pwdLoc=~s/\s|\n//g;

    if (-d $pwdLoc) {
	$pwdLoc=~s/\/$//g;
	return($pwdLoc); }

    return(0);
}				# end of sysGetPwd

#===============================================================================
sub sysGetUser {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysGetUser                  returns $USER (i.e. user name)
#       out:                    USER
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:"."sysGetUser";$fhinLoc="FHIN"."$sbrName";
    if (defined $ENV{'USER'}){
        return($ENV{'USER'});}
    $tmp=`whoami`;
    return($tmp) if (defined $tmp && length($tmp)>0);
    $tmp=`who am i`;            # SUNMP
    return($tmp) if (defined $tmp && length($tmp)>0);
    return(0);
}				# end of sysGetUser

#===============================================================================
sub sysMkdir {
    local($argIn,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMkdir                    system call 'mkdir'
#                               note: system call returns 0 if ok
#       in:                     directory, nice value (nice -19)
#       out:                    ok=(1,'mkdir a') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMkdir";
    $argIn=~s/\/$//             if ($argIn=~/\/$/);
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
    $argIn=~s/\/$//g            if ($argIn =~/\/$/); # chop last '/'
				# exists already
    return(1,"already existing: $argIn");

				# ------------------------------
				# make dir
    $Lok= mkdir ($argIn, "770");
    system("chmod u+rwx $argIn");
    system("chmod go+rx $argIn");

    return(0,"*** $sbrName: couldnt find or make dir '$argIn' ($Lok)!") if (! $Lok);
    return(1,"$niceLoc mkdir $argIn");
}				# end of sysMkdir

#===============================================================================
sub sysMvfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMvfile                   system call '\\mv file'
#       in:                     $fileToCopy,$fileToCopyTo (or dir),$niceLoc
#       out:                    ok=(1,'mv a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMvfile";
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
				# check
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!")  if (! defined $fileToCopyTo);

    system("$niceLoc \\mv $fileToCopy $fileToCopyTo");

    return(0,"*** $sbrName: couldnt copy '$fileToCopy -> $fileToCopyTo' ($Lok)!")
	if (! -e $fileToCopyTo);
    return(1,"$niceLoc \\mv $fileToCopy $fileToCopyTo");
}				# end of sysMvfile

#===============================================================================
sub sysRmdir {
    local($dirLoc,$Ldare_a_lot)= @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysRmdir                    removes directory
#       in:                     dir,[1|0] for daring '\\rm -r '!!
#       out:                    0|1
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:"."sysRmdir";$fhinLoc="FHIN"."$sbrName";
    return(1) if (! -d $dirLoc);
    $Lok=rmdir($dirLoc);
    return(1) if ($Lok);
                                # try cruel!!
    if (defined $Ldare_a_lot && $Ldare_a_lot){
        $cmd="\\rm -r $dirLoc";
        print "-*- $sbrName: WARNING system \t '$cmd'\n" x 10 ; 
        sleep 60;
        system("$cmd");}
    return(1) if (! -d $dirLoc);
    return(0);
}				# end of sysRmdir

#======================================================================
sub sysRunProg {
    local ($cmd,$fileScrLoc,$fhErrLoc) = @_ ;
    $[ =1;
#-------------------------------------------------------------------------------
#   sysRunProg                  pipes arguments into $prog, and cats the output
#                               from $prog into a file
#       in:                     $cmd,$fileScrLoc,$fhError
#       in:                     $cmd='prog,arg1,arg2' 
#       in:                          where prog is the program, e.g. 'wc -l, file1,file2'
#       in:                     $fileScrLoc     is the output file
#       in:                        NOTE: if not defined: buffered to STDOUT
#       in:                      = 0            to surpress writing
#       in:                     $fhError        filehandle for ERROR writing
#                                  NOTE: to STDOUT if not defined
#       in:                      = 0            to surpress writing
#       out:                    0|1,message
#       err:                    ok -> 1,ok | err -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system fileOut=$fileScrLoc, cmd=\n$prog\n";}
				# ------------------------------
				# pipe output into file?
    $Lpipe=0;
    $Lpipe=1                    if ($fileScrLoc);
				# hack br: 08-98 to avoid pipe pipe, i.e.
				#          prog="cmd > file" -> 'cmd > file | cat >> filescreen' fails
    $Lpipe=0                    if ($prog =~ /\s+>>?\s+\S+\s*$/);
    $prog.=" | cat >> $fileScrLoc " if ($Lpipe);
#    print "$cmd\n";exit;
				# ------------------------------
				# opens cmdtmp into pipe
    open (CMD, "|$prog") || 
	warn "*** $sbrName cannot run program '$prog $arg'";
				# get input arguments (< arg)
    foreach $tmp (@arg) {
	$tmp=~s/\n|^\s*|\s*$//; # delete end of line, and leading blanks 
	print CMD "$tmp\n" ;}
    close (CMD) ;		# upon closing: cmdtmp < @out_command executed    
    return(1,"ok $sbrName");
}				# end of sysRunProg

#===============================================================================
sub sysSendMailAlarm {
    local($messageLoc,$userLoc,$exe_mailLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$dateLoc,@dateLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysSendMailAlarm            sends alarm mail to user
#       in:                     $message, $user, $exe_mail
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="sysSendMailAlarm";
    return(0,"*** $sbrName: not def messageLoc!")          if (! defined $messageLoc);
    return(0,"*** $sbrName: not def userLoc!")             if (! defined $userLoc);
    return(0,"*** $sbrName: not def exe_mailLoc!")          if (! defined $exe_mailLoc);
    return(0,"*** $sbrName: mail executable '$exe_mailLoc'!") if (! -e $exe_mailLoc);

    @dateLoc = split(' ',&ctime(time));
    shift (@dateLoc); $dateLoc = join(':',@dateLoc);

    $message= "\n"; $message.="*** $date\n" if (defined $date);
    $message.="*** from sysSendMailAlarm (lib-x.pl)\n"."***$message\n";
    system("echo '$messageLoc' | $exe_mailLoc -s PP_ERROR $userLoc");
    return(1,"ok $sbrName");
}				# end of sysSendMailAlarm

#===============================================================================
sub sysSystem {
    local($cmdLoc,$fhLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysSystem                   simple way of running system command + documenting them
#       in:                     $cmd:   will do system($cmd)
#       in:                     $fhLoc: will write trace onto fhLoc
#                                 =<! defined> -> STDOUT
#                                 =0           -> no output
#       out:                    <1|0>,<"value from system"|$errorMessag>
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."sysSystem";
				# no argument given
    return(0,"*** ERROR $sbrName: no input argument (system command)")
	if (! defined $cmdLoc || ! $cmdLoc);

				# default
    $fhLoc="STDOUT"             if (! defined $fhLoc);
    
				# ------------------------------
				# write
    print $fhLoc "--- system: \t $cmdLoc\n" if ($fhLoc);

				# ------------------------------
				# run system
    $Lsystem=
	system("$cmdLoc");

    return(1,$Lsystem);
}				# end of sysSystem

#===============================================================================
sub tarRemovePath {
    local($fileTarLoc,$cmdTarLoc,$cmdUntarLoc) = @_ ;
    local($sbrName,$tmp,$Lok,$command,@list,$file,@max,@tmp,$ct,$stillOk,
	  $dirWant,$pathDel,$it,$list);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   tarRemovePath               removes a dead path from tar file
#       in:                     $fileTarLoc,$cmdTarLoc,$cmdUntarLoc
#       out:                    will overwrite!
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."tarRemovePath";
    return(0) if (! (defined $fileTarLoc && -e $fileTarLoc && defined $cmdTarLoc && 
		     defined $cmdUntarLoc));
				# ------------------------------
				# remove directory name
    $command="$cmdUntarLoc $fileTarLoc\n";    print "--- $sbrName system \t '$command'\n";
    @list=`$command`;

    foreach $file(@list){$file=~s/\n//g;}
				# get dir common to all 
    $#max=0;
    foreach $file(@list){	# first the maximum
	@tmp=split(/\//,$file);
	if ($#tmp>$#max){@max=@tmp;}}
				# now chop
    $Lok=1;$ct=1;
    while($Lok){$tmp=$max[$ct];
		foreach $file(@list){if ($file!~/$tmp/){$Lok=0;
							last;}}
		if ($Lok){$stillOk=$ct;}
		++$ct;}
    $pathDel="";foreach $it(1..($stillOk-1)){$pathDel.=$max[$it]."/";}
    $dirWant=$max[$stillOk];
    # ------------------------------------------------------------
    # ok now we want to remove '$pathDel' and keep $dirWant
    # ------------------------------------------------------------
				# security erase
    if (-d $dirWant && length($dirWant)>2 && $dirWant !~/^\//){
	rmdir $dirWant;            print "--- $sbrName fct \t 'rmdir $dirWant'\n";}
    if (! -d $dirWant){
	$Lok= mkdir ($argIn,umask);print "--- $sbrName fct \t 'mkdir $argIn'\n";}
    foreach $file(@list){	# move files to working
	$file=~s/\n//g;
	$fileNew=$file;$fileNew=~s/$pathDel//g;$fileNew=$fileNew;
	print "--- sysMvfile \t 'mv $file $fileNew\n";
	$Lok=&sysMvfile($file,$fileNew);}
				# remove the rest
    if (length($pathDel)>1 && $pathDel!~/^\//){
	$pathDel=~s/\/.*$//g;
	$Lok=&sysRmdir($pathDel,1); print "--- $sbrName WARNING !!! rm -r !!! &sysRmdir($pathDel,1)\n";}

    unlink($fileTarLoc);	# remove old and make new
				# make tar without path
    @list=&fileLsAll($dirWant);

    $list="";foreach $file (@list){$list.=" $file";}
    $command="$cmdTarLoc $fileTarLoc $list\n";print "--- $sbrName system \t '$command'\n";
    $Lok=`$command`;
    if (! -e $fileTarLoc){print "*** ERROR $sbrName: tar failed\n";
			  die;}
				# ------------------------------
				# clean up
    foreach $file(@list){
	unlink($file);}
    if (-d $dirWant){
	rmdir $dirWant; print "--- $sbrName fct \t 'rmdir $dirWant'\n";}
}				# end of tarRemovePath

1;
