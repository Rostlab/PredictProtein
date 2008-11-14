##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
##!/usr/pub/bin/perl
#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system # 
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost		rost@columbia.edu			                  #
# http://cubic.bioc.columbia.edu/~rost/	                                          #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu  	                          #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu        	                  #
#                                                                                 # 
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 # 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #   
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            # 
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               # 
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#------------------------------------------------------------------------------   #
#	Copyright				  May,    	 1998	          #
#	Burkhard Rost 		rost@EMBL-Heidelberg.DE			          #
#	EMBL			http://www.embl-heidelberg.de/~rost/	          #
#	D-69012 Heidelberg						          #
#			        v 1.1   	  Jan,           1999             #
#------------------------------------------------------------------------------   #
# 
#   library of subroutines specific for PP scripts
#   
# 
# NOTE: it returns (1,'ok','formatSend=<ASCII|HTML>') to the calling program
#         ... or:  (0,'error_message')
# 
# 
# -----------------------------------------------------------------------------# 

#===============================================================================
sub copfLocal {
    local($fileInLoc,$fileOutLoc,$formatInLoc,$formatLoc,
	  $LdoExpandLoc,$exeCopfLoc,$exeConvertSeqLoc,
	  $dirWorkLoc,$fileJobIdLoc,$niceLoc,$LdebugLoc,$fhSbr2) = @_ ;
    local($sbrName2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   copfLocal                   runs COPF for predictPP.pm
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2="lib-pp:copfLocal";
				# check arguments
    return(0,"*** $sbr: not def=fileInLoc!")               if (! defined $fileInLoc);
    return(0,"*** $sbr: not def=fileOutLoc!")              if (! defined $fileOutLoc);
    return(0,"*** $sbr: not def=formatInLoc!")             if (! defined $formatInLoc);
    return(0,"*** $sbr: not def=formatLoc!")               if (! defined $formatLoc);
    return(0,"*** $sbr: not def=LdoExpandLoc!")            if (! defined $LdoExpandLoc);
    return(0,"*** $sbr: not def=exeCopfLoc!")              if (! defined $exeCopfLoc);
    return(0,"*** $sbr: not def=exeConvertSeqLoc!")        if (! defined $exeConvertSeqLoc);
    return(0,"*** $sbr: not def=dirWorkLoc!")              if (! defined $dirWorkLoc);
    return(0,"*** $sbr: not def=fileJobIdLoc!")            if (! defined $fileJobIdLoc);
    $LdebugLoc=0                                           if (! defined $LdebugLoc);
    $fhSbr2="STDOUT"                                       if (! defined $fhSbr2);
    return(0,"*** $sbrName2: miss  in=$fileInLoc!")        if (! -e $fileInLoc && ! -d $fileInLoc);
    return(0,"*** $sbrName2: miss exe=$exeCopfLoc!")       if (! -e $exeCopfLoc && ! -d $exeCopfLoc);
    return(0,"*** $sbrName2: miss exe=$exeConvertSeqLoc!") if (! -e $exeConvertSeqLoc && 
							       ! -d $exeConvertSeqLoc);

				# screen file names
    $file_copfScreenFor=$dirWorkLoc.$fileJobIdLoc.".copfScreenFor";
    $file_copfTrace=    $dirWorkLoc.$fileJobIdLoc.".copfTrace";    
    $file_copfScreen=   $dirWorkLoc.$fileJobIdLoc.".copfScreen";   
				# build up command
    $cmd= $niceLoc." ".$exeCopfLoc;
    $cmd.=" ".$fileInLoc;
    $cmd.=" formatIn=". $formatInLoc if ($formatInLoc);
    $cmd.=" formatOut=".$formatLoc." fileOut=".$fileOutLoc;
    $cmd.=" exeConvertSeq=".$exeConvertSeqLoc;
    $cmd.=" expand"             if ($LdoExpandLoc);

    $cmd.=" fileOutScreen=".$file_copfScreen." fileOutTrace=".$file_copfTrace." >> ".$file_copfScreen;
#    $cmd.=" fileOutScreen=".$file_copfScreen." fileOutTrace=".$file_copfTrace." dbg";

    $msgHereLoc="\n--- $sbrName2 system \t ".$cmd."\n";
    print $fhSbr2 "--- $sbrName2 system \t",$cmd,"\n" if ($LdebugLoc);

				# system call
    system("$cmd");
				# ------------------------------
				# conversion failed!
    if (! -e $fileOutLoc) {
	$Lok=0;
				# trace file
	if (-e $file_copfTrace) {
	    $msgHereLoc.="--- $sbrName2 copf trace file $file_copfTrace\n";
	    open(FHINTMP,$file_copfTrace);    
	    while(<FHINTMP>){
		$msgHereLoc.=$_;}
	    close(FHINTMP); }
				# screen dump from COPF
	if (-e $file_copfScreenFor) {
	    $msgHereLoc.="--- $sbrName2 copf screen file $file_copfScreenFor\n";
	    open(FHINTMP,$file_copfScreenFor);
	    while(<FHINTMP>){
		$msgHereLoc.=$_;}
	    close(FHINTMP); } }
    else {
	$Lok=1;}
				# dump screen output in any case!
    $msgHereLoc.="--- $sbrName2 copf screen out $file_copfScreen\n";
    if (-e $file_copfScreen) {
	open(FHINTMP,$file_copfScreen);   
	while(<FHINTMP>){
	    $msgHereLoc.=$_;}
	close(FHINTMP);  }
				# ------------------------------
				# delete files
    foreach $file ($file_copfScreenFor,$file_copfTrace,$file_copfScreen) {
	next if (! defined $file || ! -e $file);
	print $fhSbr2 "--- $sbrName2 unlink $file\n" if ($LdebugLoc);
	unlink($file); }
		
    return($Lok,$msgHereLoc);
}				# end of copfLocal

#===============================================================================
sub ctime {
    local($time) = @_;
    local($[) = 0;
    local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
#----------------------------------------------------------------------
# ctime.pl is a simple Perl emulation for the well known ctime(3C) function.
#
# Waldemar Kebsch, Federal Republic of Germany, November 1988
# kebsch.pad@nixpbe.UUCP
# Modified March 1990, Feb 1991 to properly handle timezones
#  $RCSfile: lib-pp_liu.pm,v $$Revision: 1.1 $$Date: 2001/03/13 19:45:56 $
#   Marion Hakanson (hakanson@cse.ogi.edu)
#   Oregon Graduate Institute of Science and Technology
#
# usage:
#
#     #include <ctime.pl>          # see the -P and -I option in perl.man
#     $Date = &ctime(time);
#----------------------------------------------------------------------
    @DoW = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    @MoY = ('Jan','Feb','Mar','Apr','May','Jun',
	    'Jul','Aug','Sep','Oct','Nov','Dec');

    # Determine what time zone is in effect.
    # Use GMT if TZ is defined as null, local time if TZ undefined.
    # There's no portable way to find the system default timezone.

    $TZ = defined($ENV{'TZ'}) ? ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' ) : '';
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        ($TZ eq 'GMT') ? gmtime($time) : localtime($time);

    # Hack to deal with 'PST8PDT' format of TZ
    # Note that this can't deal with all the esoteric forms, but it
    # does recognize the most common: [:]STDoff[DST[off][,rule]]

    if($TZ=~/^([^:\d+\-,]{3,})([+-]?\d{1,2}(:\d{1,2}){0,2})([^\d+\-,]{3,})?/){
        $TZ = $isdst ? $4 : $1;
    }
    $TZ .= ' ' unless $TZ eq '';

    $year += ($year < 70) ? 2000 : 1900;
    sprintf("%s %s %2d %2d:%02d:%02d %s%4d\n",
	    $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $TZ, $year);
}

#===============================================================================
sub ctrlDbgMsg {
    local ($message,$fhOutLoc,$debugLoc) = @_;
#----------------------------------------------------------------------
#   ctrlDbgMsg                  print a message to STDOUT if debug flag is on
#       in:                     message
#       out:                    DEBUG:
#----------------------------------------------------------------------
    $message= "     DEBUG: $message\n";
    $debugLoc=1                 if (! defined $debugLoc);
    $fhOutLoc="STDOUT"          if (! defined $fhOutLoc);
    print $fhOutLoc $message; 
#    print $fhOutLoc $message; if ($debugLoc);

}				# end of ctrlDbgMsg

#===============================================================================
sub filePurgeBlankLines {
    local ($fileTo_filter,$file_filtered,$fileTmp) = @_;
    local ($fhin,$tmp,@tmp,$fhout,$fileOutLoc);
#--------------------------------------------------------------------------------
#   filePurgeBlankLines         removes all blank lines from a file
#       in:                     fileTo_be_filtered
#       out:                    
#                               filtered_file (will have same name)
#                               if no specific filename is defined
#           NOTE:               temporary write into fileTmp for security
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="filePurgeBlankLines";
    return(0,"*** $sbrName: not def fileTo_filter!") if (! defined $fileTo_filter);
    return(0,"*** $sbrName: not def file_filtered!") if (! defined $file_filtered);
    return(0,"*** $sbrName: not def fileTmp!")       if (! defined $fileTmp);
    return(0,"*** $sbrName ERROR missing input file ($fileTo_filter)")
	if (! -e $fileTo_filter );
				# ------------------------------
    $fhin="FHIN_FILTER";	# open file
    open ("$fhin","$fileTo_filter");
				# ------------------------------
    $#tmp=0;			# read file
    while (<$fhin>) {$_=~s/\n//g;$line=$_;$_=~s/^\s*|\s*$//g;
		     next if (length($_)<1);
		     push(@tmp,$line)}
    close($fhin);

    $fhout="FHOUT_filePurgeBlankLines";
				# ------------------------------
				# write new output
    if ($fileTo_filter eq $file_filtered){
	$fileOutLoc=$fileTmp;}	# security: temporary file
    else {$fileOutLoc=$file_filtered;}

    open ("$fhout", ">$fileOutLoc")  ||
	return(0,"*** $sbrName ERROR opening output file ($fileOutLoc)");
    foreach $tmp(@tmp){
	next if (! defined $tmp);
	$tmp=~s/\n|\s$//g;
	next if (length($tmp)<1);
	print $fhout "$tmp\n";}
    close("$fhout");
    $#tmp=0;			# save space
    if (! -e $fileOutLoc){
	return(0,"*** $sbrName ERROR missing output file ($fileOutLoc)");}
				# ------------------------------
				# delete file
    if ($fileTo_filter eq $file_filtered){
	unlink $fileTo_filter;
	($Lok,$msg)=
	    &sysMvfile($fileOutLoc,$file_filtered);
	return(0,"\n*** $sbrName ERROR mv file error\n"."$msg") if (! $Lok);}
    if (! -e $file_filtered){
	return(0,"*** $sbrName ERROR missing output file ($file_filtered)");}
    return(1,"$sbrName ok");
}				# end filePurgeBlankLines 

#===============================================================================
sub filePurgeNullChar {
    local ($fileTo_filter,$file_filtered,$fileTmp) = @_;
    local ($fhin,$tmp,@tmp,$fhout);
#--------------------------------------------------------------------------------
#   filePurgeNullChar           removes all null characters
#       in:                     fileTo_be_filtered
#       out:                    
#                               filtered_file (will have same name)
#                               if no specific filename is defined
#                               NOTE: temporary write into fileTmp for security
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="filePurgeNullChar";
    return(0,"*** $sbrName: not def fileTo_filter!") if (! defined $fileTo_filter);
    return(0,"*** $sbrName: not def file_filtered!") if (! defined $file_filtered);
    return(0,"*** $sbrName: not def fileTmp!")       if (! defined $fileTmp);
    return(0,"*** $sbrName ERROR missing input file ($fileTo_filter)")
	if (! -e $fileTo_filter );
				# open file
    $fhin="FHIN_purgeNullChar";
    open ("$fhin","$fileTo_filter");
				# ------------------------------
    $#tmp=0;			# read file
    while (<$fhin>) {$_=~s/\0//g;
		     push(@tmp,$_);}
    close($fhin);
				# ------------------------------
				# write new output
    $fhout="FHOUT_filePurgeNullChar";	
    if ($fileTo_filter eq $file_filtered){
	$fileOutLoc=$fileTmp;}	# security: temporary file
    else {
	$fileOutLoc=$file_filtered;}

    open ("$fhout", ">$fileOutLoc")  ||
	return(0,"*** $sbrName ERROR opening output file ($fileOutLoc)");
    foreach $tmp (@tmp){
	next if (! defined $tmp);
	$tmp=~s/\n|\s$//g;
	next if (length($tmp)<1);
	print $fhout "$tmp\n";}
    close("$fhout");

    $#tmp=0;			# save space
    if (! -e $fileOutLoc){
	return(0,"*** $sbrName ERROR missing output file ($fileOutLoc)");}
				# ------------------------------
				# delete file
    if ($fileTo_filter eq $file_filtered){
	unlink $fileTo_filter;
	($Lok,$msg)=
	    &sysMvfile($fileOutLoc,$file_filtered);
	return(0,"\n*** $sbrName ERROR mv file error='"."$msg'\n") if (! $Lok);}
    if (! -e $file_filtered){
	return(0,"*** $sbrName ERROR missing output file ($file_filtered)");}
    return(1,"$sbrName ok");
}				# end filePurgeNullChar

#===============================================================================
sub filePurgePat1Pat2 {
    local ($fileTo_filter,$file_filtered,$fileTmp,$pattern1,$pattern2) = @_;
    local ($hide,$fhin,);
#--------------------------------------------------------------------------------
#   filePurgePat1Pat2           remove from input file all lines between the line 
#                               with pattern1 (include) and the line with pattern2 (exclude)
#                               pattern search is case insensitive
#                               if pattern2 = "EOF" then remove till end
#       in:                     $fileTo_filter,$file_filtered,$fileTmp,$pattern1,$pattern2
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="filePurgePat1Pat2";
    return(0,"*** $sbrName: not def fileTo_filter!") if (! defined $fileTo_filter);
    return(0,"*** $sbrName: not def file_filtered!")  if (! defined $file_filtered);
    return(0,"*** $sbrName: not def fileTmp!")       if (! defined $fileTmp);
    return(0,"*** $sbrName: not def pattern1!")       if (! defined $pattern1);
    return(0,"*** $sbrName: not def pattern2!")       if (! defined $pattern2);
    return(0,"*** $sbrName ERROR missing input file ($fileTo_filter)")
	if (! -e $fileTo_filter );
				# ------------------------------
    $pattern1=~ tr/a-z/A-Z/;	# comparison done in upper case
    $pattern2=~ tr/a-z/A-Z/;
				# open file
    $fhin="FHIN_purgeNullChar";
    open ("$fhin","$fileTo_filter");
				# ------------------------------
    $#tmp=$hide=0;		# read file
    while (<$fhin>) {$tmp= $_;
		     $tmp=~tr/a-z/A-Z/;
		     if ($tmp =~ /$pattern1/) { $hide=1;}
		     if ($tmp =~ /$pattern2/) { $hide=0;}
		     if (!$hide) {
			 push(@tmp,$_);}}
    close($fhin);
				# ------------------------------
                                # if we miss the second pattern
                                #    do not apply filter
    if (!$hide || $pattern2 eq "EOF") {
                            	# overwrite the input file with the temp file
#	system "mv $fileTmp $fileTo_filter"; 
				# br: should be the other way around!
				# just don't touch file
    }
    else {			# remove the temp file
				# ------------------------------
				# write new output
	$fhout="FHOUT_filePurgePat1Pat2";	
	if ($fileTo_filter eq $file_filtered){
	    $fileOutLoc=$fileTmp;}	# security: temporary file
	else {
	    $fileOutLoc=$file_filtered;}
	
	open ("$fhout", ">$fileOutLoc")  ||
	    return(0,"*** $sbrName ERROR opening output file ($fileOutLoc)");
	foreach $tmp(@tmp){
	    print $fhout "$tmp\n";}
	close("$fhout");
	
	$#tmp=0;		# save space
	
	if (! -e $fileOutLoc){
	    return(0,"*** $sbrName ERROR missing output file ($fileOutLoc)");}
				# ------------------------------
				# delete file
	if ($fileTo_filter eq $file_filtered){
	    unlink $fileTo_filter;
	    ($Lok,$msg)=
		&sysMvfile($fileOutLoc,$file_filtered);
	    return(0,"\n*** $sbrName ERROR mv file error\n"."$msg") if (! $Lok);}
	if (! -e $file_filtered){
	    return(0,"*** $sbrName ERROR missing output file ($file_filtered)");}
    }
    return(1,"$sbrName ok");

}				# end filePurgePat1Pat2

#===============================================================================
sub filterLocal {
    local($fileInLoc,$fileOutLoc,$optFilterLoc,$exeFilterLoc,$exeFilterForLoc,
	  $dirWorkLoc,$fileJobIdLoc,$niceLoc,$LdebugLoc,$fhSbr2) = @_ ;
    local($sbrName2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   filterLocal                 runs FILTER_HSSP for predictPP.pm
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName2="lib-pp:filterLocal";
				# check arguments
    return(0,"*** $sbrName2: not def=fileInLoc!")       if (! defined $fileInLoc);
    return(0,"*** $sbrName2: not def=fileOutLoc!")      if (! defined $fileOutLoc);
    return(0,"*** $sbrName2: not def=optFilterLoc!")    if (! defined $optFilterLoc);
    return(0,"*** $sbrName2: not def=exeFilterLoc!")    if (! defined $exeFilterLoc);
    return(0,"*** $sbrName2: not def=exeFilterForLoc!") if (! defined $exeFilterForLoc);
    return(0,"*** $sbrName2: not def=dirWorkLoc!")      if (! defined $dirWorkLoc);
    return(0,"*** $sbrName2: not def=fileJobIdLoc!")    if (! defined $fileJobIdLoc);
    return(0,"*** $sbrName2: not def=niceLoc!")         if (! defined $niceLoc);
    $LdebugLoc=0                                        if (! defined $LdebugLoc);
    $fhSbr2="STDOUT"                                    if (! defined $fhSbr2);
    return(0,"*** $sbrName2: miss in=$fileInLoc!")      if (! -e $fileInLoc && ! -d $fileInLoc);

				# screen file names
    $file_filterScreenFor=$dirWorkLoc.$fileJobIdLoc.".filterScreenFor";
    $file_filterTrace=    $dirWorkLoc.$fileJobIdLoc.".filterTrace";    
    $file_filterScreen=   $dirWorkLoc.$fileJobIdLoc.".filterScreen";   
				# build up command
    $cmd= $niceLoc." ".$exeFilterLoc;
    $cmd.=" ".$fileInLoc." fileOut=".$fileOutLoc;
    $cmd.=" ".$optFilterLoc." exeFilterHssp=".$exeFilterForLoc;
    $cmd.=" dirWork=$dirWorkLoc jobid=$fileJobIdLoc";
    $cmd.=" fileOutScreen=".$file_filterScreen." fileOutTrace=".$file_filterTrace;
    $cmd.=" >> ".$file_filterScreen;
    $msgHereLoc="\n--- $sbrName2 system \t $cmd\n";
    print $fhSbr2 "--- $sbrName2 system \t",$cmd,"\n" if ($LdebugLoc);
				# system call
    system("$cmd");
				# ------------------------------
				# conversion failed!
    if (! -e $fileOutLoc) {
	$Lok=0;
				# trace file
	if (-e $file_filterTrace) {
	    $msgHereLoc.="--- $sbrName2 filter trace file $file_filterTrace\n";
	    open(FHINTMP,$file_filterTrace);    
	    while(<FHINTMP>){
		$msgHereLoc.=$_;}
	    close(FHINTMP); }
				# screen dump from FILTER
	if (-e $file_filterScreenFor) {
	    $msgHereLoc.="--- $sbrName2 filter screen file $file_filterScreenFor\n";
	    open(FHINTMP,$file_filterScreenFor);
	    while(<FHINTMP>){
		$msgHereLoc.=$_;}
	    close(FHINTMP); } }
    else {
	$Lok=1;}
				# dump screen output in any case!
    if (-e $file_filterScreen) {
	$msgHereLoc.="--- $sbrName2 filter screen out $file_filterScreen\n";
	open(FHINTMP,$file_filterScreen) ||
	    return(0,"*** $sbrName2 failed opening filescreen=$file_filterScreen\n".
		   $msgHereLoc."\n");
	while(<FHINTMP>){
	    $msgHereLoc.=$_;}
	close(FHINTMP);  }
				# ------------------------------
				# delete files
    foreach $file ($file_filterScreenFor,$file_filterTrace,$file_filterScreen) {
	next if (! defined $file || ! -e $file);
	print $fhSbr2 "--- $sbrName2 unlink $file\n";
	unlink($file); }
		
    return($Lok,$msgHereLoc);
}				# end of filterLocal

#===============================================================================
sub htmlBlast {
    local($fileInBlastLoc,$exeMviewLoc,$parStandardLoc,$optOut,
	  $fileOutLoc,$fileOutHtmlLoc,$fileOutHtmlTocLoc,$isPsiBlast,$fhoutSbr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$kwdLoc,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlBlast                   writes the HTML part for BLAST
#       in:                     $fileInBlastLoc=  direct output from Blast BLAST
#       in:                     $exeMview=        executable (perl)
#       in:                     $paraStandard=    standard parameters
#                                   =0            for standard setting
#       in:                     $optOut=          general string written by extrHdrOnline
#                                                 used here 'perline=N'
#       in:                     $fileOut=         name of output file written by MView
#       in:                     $fileOutHtml=     file into which to write (BODY)
#       in:                     $fileOutHtmlToc=  file into which to write TOC
#       in:                     $isPsiBlast=      whether it is Psi-Blast
#       in:                     $fhoutSbr=        file handle to write system call
#                                  =0             no output reported
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlBlast";
    $fhinLoc="FHIN_"."htmlBlast";$fhoutLoc="FHOUT_"."htmlBlast";
    $errMsg="*** ERROR in arg for $sbrName: ";
				# check arguments
    return(0,0,$errMsg."not def fileInBlastLoc!")       if (! defined $fileInBlastLoc);
    return(0,0,$errMsg."not def exeMviewLoc!")          if (! defined $exeMviewLoc);
    return(0,0,$errMsg."not def parStandard!")          if (! defined $parStandardLoc);
    return(0,0,$errMsg."not def optOut!")               if (! defined $optOut);
    return(0,0,$errMsg."not def fileOut!")              if (! defined $fileOutLoc);
    return(0,0,$errMsg."not def fileOutHtmlLoc!")       if (! defined $fileOutHtmlLoc);
    return(0,0,$errMsg."not def fileOutHtmlTocLoc!")    if (! defined $fileOutHtmlTocLoc);
    $fhoutSbr=0                                         if (! defined $fhoutSbr);
#    return(0,$errMsg."not def !")          if (! defined $);

    return(0,0,$errMsg."no fileInBlast=$fileInBlastLoc!") if (! -e $fileInBlastLoc);
    return(0,0,$errMsg."no fileIn=$exeMviewLoc!")         if (! -e $exeMviewLoc && 
							      ! -l $exeMviewLoc);

				# ------------------------------
				# restrict line width
    if ($optOut=~/perline=(\d+)/) {
	$parStandardLoc.=" -label2 -label3 -label4 -width $1"; }

				# --------------------------------------------------
				# produce MView version of ProDom Blastp alignment
				# --------------------------------------------------
    ($Lok,$msg)=
	&mviewRun($fileInBlastLoc,"blast"," ",$exeMviewLoc,$parStandardLoc,
		  $fileOutLoc,"data",$fhoutSbr);

				# if no output: just append BLAST file
    if (! $Lok) { $msg="*** $sbrName: htmlBuild failed on kwd=blast\n".$msg."\n";
		  print $fhTrace $msg;
		  $fileOutLoc=$fileInBlastLoc; }

				# --------------------------------------------------
				# append file
				# --------------------------------------------------
    if ( $isPsiBlast ) {
	$kwdLoc = "ali_psiBlast";
    } else {
	$kwdLoc = "ali_blast";
    }
    ($Lok,$msg)=
	&htmlBuild($fileOutLoc,$fileOutHtmlLoc,$fileOutHtmlTocLoc,0,$kwdLoc);
    if (! $Lok) { $msg="*** err=2238 ($sbrName: htmlBuild failed on kwd=blast)\n".$msg."\n";
		  print $fhTrace $msg;
		  return(0,"err=2238",$msg); }

    return(1,"ok","ok $sbrName");
}				# end of htmlBlast

#===============================================================================
sub htmlBuild {
    local($fileInHtml,$fileOutHtmlLoc,$fileOutHtmlTocLoc,$PRE,$kwdLoc) = @_ ;
    local($sbrName3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlBuild                   writes HTML text
#       in:                     $fileInLoc=   file to paste into HTML
#                                   0         if not to use (e.g. for 'begin' 'end')
#       in:                     $fileOutHtml= file into which to write (BODY)
#       in:                     $fileOutHtmlToc= file into which to write TOC
#       in:                     $PRE=         <1|0> 
#                                    1 ->     simply <PRE><fhin></PRE>
#                                    0 ->     simply write as is (expected to be HTML, already)
#       in:                     $kwdLoc=      one of the keywords defined in iniHtmlBuild
#                      OR       begin
#                      OR       end->         final words
#                      OR       txt->         simply write text
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName3=$tmp."htmlBuild";
    $fhinLoc="FHIN_"."htmlBuild";$fhoutLoc="FHOUT_"."htmlBuild";$fhoutTocLoc="FHOUTTOC_"."htmlBuild";
    $errMsg="*** err=2101\n"."*** ERROR $sbrName3 (top): ";
				# check arguments
    return(0,$errMsg."not def fileInHtml!")             if (! defined $fileInHtml);
    return(0,$errMsg."not def fileOutHtmlLoc!")         if (! defined $fileOutHtmlLoc);
    return(0,$errMsg."not def fileOutHtmlTocLoc!")      if (! defined $fileOutHtmlTocLoc);
    return(0,$errMsg."not def PRE!")                    if (! defined $PRE);
    return(0,$errMsg."not def kwdLoc!")                 if (! defined $kwdLoc);

    return(0,$errMsg."miss in file=$fileInHtml!")       if ($kwdLoc !~ /txt/ &&
							    $fileInHtml &&
							    ! -e $fileInHtml);

				# ------------------------------
				# create output file
    if (! -e $fileOutHtmlLoc) {
	$Lnew=1;
	open($fhoutLoc,">".$fileOutHtmlLoc) || 
	    return(0,"*** err=2102\n".
		   "*** ERROR $sbrName3: fileOutHtmlLoc=$fileOutHtmlLoc, not created"); 
	open($fhoutTocLoc,">".$fileOutHtmlTocLoc) || 
	    return(0,"*** err=2103\n".
		   "*** ERROR $sbrName3: fileOutHtmlTocLoc=$fileOutHtmlTocLoc, not created"); }
				# ------------------------------
				# append to output file
    else {
	$Lnew=0;
	open($fhoutLoc,">>".$fileOutHtmlLoc) || 
	    return(0,"*** err=2104\n".
		   "*** ERROR $sbrName3: fileOutHtmlLoc=$fileOutHtmlLoc, not created"); 
	open($fhoutTocLoc,">>".$fileOutHtmlTocLoc) || 
	    return(0,"*** err=2105\n".
		   "*** ERROR $sbrName3: fileOutHtmlTocLoc=$fileOutHtmlTocLoc, not created"); }

    

				# ------------------------------
				# OPENING files
				# ------------------------------
    if ($Lnew) {
				# TOC
#	print $fhoutTocLoc "<H2>TOC for file ".$fileInHtml."</H2>\n","<OL>\n";
	print $fhoutTocLoc "<H2>Table Of Contents</H2>\n","<OL>\n";
				# BODY
#	print $fhoutLoc 
#	    "<H2>BEG of results </H2>\n","<P><BR><P>\n";
 }

				# ------------------------------
				# closing files (and return)
				# ------------------------------
    if ($kwdLoc=~/end/) {
				# closing TOC
#	print $fhoutTocLoc 
#	    "</OL><BR>\n",
#	    "END of TOC<BR>\n",
#	print $fhoutTocLoc   "<P><BR><P><HR><P><BR><P>\n"; 
	close($fhoutTocLoc)     if ($fhoutTocLoc ne "STDOUT");
				# closing BODY

	$fileTmp=$fileOutHtmlLoc; $fileTmp=~s/^.*\/|\..*$//g;
#	print $fhoutLoc 
#	    "END of results for file ".$fileTmp."<BR>\n",
#	    "<P><BR><P><HR><P><BR><P>\n"; 
	close($fhoutLoc)        if ($fhoutLoc ne "STDOUT");
	return(1,"ok"); }
	
				# ------------------------------
				# writing text and return
				# note: the file name is the
				#       text to write!
				# ------------------------------
    if ($kwdLoc=~/txt/) {
				# 
	close($fhoutTocLoc)     if ($fhoutTocLoc ne "STDOUT");
	print $fhoutLoc 
	    "<PRE>\n",
	    $fileInHtml,"\n",
	    "</PRE>\n";
	close($fhoutLoc)        if ($fhoutLoc ne "STDOUT");
	return(1,"ok"); }
	
				# **************************************************
				# keyword not found
    return(0,"*** err=2110\n".
	   "*** ERROR $sbrName3: failed identifying htmlKwd for kwd=$kwdLoc!\n")
	if (! defined $htmlKwd{$kwdLoc});
				# **************************************************

				# --------------------------------------------------
				# (1) make TOC entry (keyword driven)
				# --------------------------------------------------

				# alignment specials: write only for first call!
				# note: means risking empty links...
    if ($kwdLoc=~/^ali_maxhom/ && $kwdLoc!~/^ali_maxhom_/) {
	print $fhoutTocLoc 
#	    "<LI><A HREF=\"#".$kwdLoc."\">".       $htmlKwd{$kwdLoc}."</A> (TOC)\n",
	    "<LI><A HREF=\"#".$kwdLoc."\">".       $htmlKwd{$kwdLoc}."</A>\n",
	    "<UL>".
#		"<LI><A HREF=\"#ali_maxhom_head\">".$htmlKwd{"ali_maxhom_head"}."</A> (TOC)\n",
#		"<LI><A HREF=\"#ali_maxhom_body\">".$htmlKwd{"ali_maxhom_body"}."</A> (TOC)\n".
		"<LI><A HREF=\"#ali_maxhom_head\">".$htmlKwd{"ali_maxhom_head"}."</A>\n",
		"<LI><A HREF=\"#ali_maxhom_body\">".$htmlKwd{"ali_maxhom_body"}."</A>\n".
		    "</UL>\n"; 
	$html{"flag","maxhom"}=1;}
				# all others 
    else {
	print $fhoutTocLoc 
#	    "<LI><A HREF=\"#".$kwdLoc."\">".$htmlKwd{$kwdLoc}."</A> (TOC)\n"; 
	    "<LI><A HREF=\"#".$kwdLoc."\">".$htmlKwd{$kwdLoc}."</A>\n"; 
	$html{"flag",$kwdLoc}=1;}
    close($fhoutTocLoc)         if ($fhoutTocLoc ne "STDOUT");

				# --------------------------------------------------
				# (2) write BODY entry (keyword driven)
				# --------------------------------------------------

				# keyword line with reference
    print $fhoutLoc
	"<H2><A NAME=\"".$kwdLoc."\">".$htmlKwd{$kwdLoc}."</A></H2>\n",
	"<BR>\n";
				# pointers to move in document
    $kwdTmp=$kwdLoc; $kwdTmp=~s/ali_|_body|_hssp|_prof|_own|_msf|_saf|_norm|_glob//g;

    $html{"flag_method",$kwdTmp}=1 if (! defined $html{"flag_method",$kwdTmp} &&
				       defined $method{"quote_".$kwdTmp});

    if (defined $method{"quote_".$kwdTmp} && $kwdTmp !~/globe/) {
	print $fhoutLoc
	    "<CENTER>",
	    "<A HREF=\"#top\">TOP</A> - ",
	    "<A HREF=\"#bottom\">BOTTOM</A> - \n",
	    "<A HREF=\"#quote_".$kwdTmp."\">",
	            $method{"name_".$kwdTmp}."</A>";
	print $fhoutLoc
	    " - <A HREF=\"#quote_".$kwdTmp."\">MView</A>"
		    if ($kwdTmp=~/blast|maxhom|prodom/);
	print $fhoutLoc
	    "</CENTER>\n"; 
    } 

    return(0,"*** err=2120",
	   "*** ERROR $sbrName3: input file fileInHtml not defined ($fileInHtml)\n")
	if (! $Lnew && (! $fileInHtml || ! -e $fileInHtml));

				# open input file
    open($fhinLoc,$fileInHtml) || 
	return(0,"*** err=2120\n".
	       "*** ERROR $sbrName3: fileInHtml=$fileInHtml, not opened"); 

				# quote literature
#     print $fhoutLoc 
# 	"<BR><STRONG>QUOTE for following output: ".$method{"quote_".$kwdLoc}." </STRONG><BR>\n"
# 	    if (defined $method{"quote_".$kwdLoc});
	
				# <PRE> <fhin> </PRE> the data
    print $fhoutLoc "<PRE>\n"   if ($PRE); # 
    
    if ($kwdLoc=~/received by the server/){
	print $fhoutLoc "<PRE>\n";
    }


				# add a line for SEGnorm
    if ($kwdLoc=~/^seg/) { 
	print $fhoutLoc "<P>\n";
	$styleSegBeg="<FONT style=\"color:red\">";
	$styleSegEnd="<\/FONT>"; }

    $Lwrt=1;
    $Lwrt=0                     if ($kwdLoc=~/^phd_body/  && ! $PRE);
    $Lwrt=0                     if ($kwdLoc=~/^prof_body/ && ! $PRE);

				# ------------------------------
    while (<$fhinLoc>) {	# read and paste file
	$line=$_; 
	$line=~s/\n//g;
	
	if (! $Lwrt && $line=~/<BODY.*>/) {
	    $Lwrt=1;
	    next; }
	if ($Lwrt && ! $PRE && $line=~/<.*BODY>/) {
	    $Lwrt=0;
	    next; }
	
	next if (! $Lwrt);
				# add links
	if ($line=~/http/ && $line !~/a href/i) {
	    $line=~s/(http[^\s\"]+)/<A HREF=\"$1\">$1<\/A>/g; 
	}
				# correct SEG
	if ($kwdLoc=~/^seg/) {
	    $line.="<BR>\n"      if ($line=~/^\s*>/);
	    $line=~s/(x+)/$styleSegBeg$1$styleSegEnd/g;
	}
	print $fhoutLoc $line,"\n";
    }
    close($fhinLoc);
				# close PRE
    print $fhoutLoc "</PRE><P>\n" if ($PRE);

				# quote literature again
				# br 99-04: commented out!
#     if (defined $method{"quote_".$kwdTmp}) {
# 	print $fhoutLoc
# 	    "<CENTER>",
# 	    "<A HREF=\"#top\">TOP</A> - ",
# 	    "<A HREF=\"#bottom\">BOTTOM</A> - \n",
# 	    "<A HREF=\"#quote_".$kwdTmp."\">quote for previous method ",
# 	       $method{"name_".$kwdTmp}."</A>";
# 	print $fhoutLoc
# 	    " - <A HREF=\"#quote_".$kwdTmp."\">quote for MView (alignment display)</A>"
# 		    if ($kwdTmp=~/blast|maxhom|prodom/);
# 	print $fhoutLoc
# 	    "</CENTER>\n"; }
	
				# final line
    print $fhoutLoc "<P><HR><P>\n"; 
	    
    close($fhoutLoc)            if ($fhoutLoc ne "STDOUT");
    return(1,"ok $sbrName");
}				# end of htmlBuild


#===============================================================================
sub htmlFin {
    local($fileJobId,$dirWork,$filePredTmp,$fileHtmlTmp,$fileHtmlToc,
	  $fileAppHtmlHead,$fileAppHtmlFoot,$fileAppHtmlQuote, $fileAppHtmlStyles,$fileOutLoc) = @_ ;
    local($sbrName2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlFin                     writes the final HTML page
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2=$tmp."htmlFin";
    $fhinLoc="FHIN_"."htmlFin";$fhoutLoc="FHOUT_"."htmlFin";
				# check arguments
#    return(0,"*** $sbrName2: not def !")          if (! defined $);
    return(0,"*** $sbrName2: not def fileJobId!")         if (! defined $fileJobId);
    return(0,"*** $sbrName2: not def dirWork!")           if (! defined $dirWork);
    return(0,"*** $sbrName2: not def filePredTmp!")       if (! defined $filePredTmp);
    return(0,"*** $sbrName2: not def fileHtmlTmp!")       if (! defined $fileHtmlTmp);
    return(0,"*** $sbrName2: not def fileHtmlToc!")       if (! defined $fileHtmlToc);
    return(0,"*** $sbrName2: not def fileAppHtmlHead!")   if (! defined $fileAppHtmlHead);
    return(0,"*** $sbrName2: not def fileAppHtmlFoot!")   if (! defined $fileAppHtmlFoot);
    return(0,"*** $sbrName2: not def fileAppHtmlStyles!") if (! defined $fileAppHtmlStyles);
    return(0,"*** $sbrName2: not def fileOutLoc!")        if (! defined $fileOutLoc);
    return(0,"*** $sbrName2: not def fileAppHtmlQuote!")  if (! defined $fileAppHtmlQuote);

				# ------------------------------
				# (1) close HTML files
				# ------------------------------
    ($Lok,$msg)=
	&htmlBuild(0,$fileHtmlTmp,$fileHtmlToc,1,"end");
    return(0,"*** ERROR $sbrName2: failed closing temporary HTML files ($fileHtmlTmp,$fileHtmlToc)".
	     $msg."\n")
	if (! $Lok);

				# ------------------------------
				# (2) open final output file
				# ------------------------------
    open($fhoutLoc,">".$fileOutLoc) ||
	return(0,"*** ERROR $sbrName2: failed opening output file=$fileOutLoc!");

				# ------------------------------
				# (3) add HEADER (all styles!)
				# ------------------------------
    $Lok=0;
    if (-e $fileAppHtmlHead || -l $fileAppHtmlHead) {
	($Lok=open($fhinLoc,$fileAppHtmlHead)) ||
	    do { print "*** ERROR $sbrName2: failed opening fileAppHtmlHead=$fileAppHtmlHead\n"; };

	if ($Lok) {
	    while (<$fhinLoc>) {
		$line=$_;
		$line=~s/VAR_jobid/$fileJobId/g
		    if ($_=~/VAR_jobid/);

		if ($line=~/<TITLE>/) {
				# hack br 99-04
#		    $tmp= "<HTML><HEAD>\n";
		    $tmp="\n";
		    $tmp.="<!-- \n";
		    $tmp.="PPhdr from: $User_name\n";
		    $tmp.="PPhdr orig: MAIL\n" if ($fileJobId=~/_e/);
		    $tmp.="PPhdr orig: HTML\n" if ($fileJobId=~/_h/);
		    $tmp.="PPhdr resp: MAIL\n";
		    $tmp.="PPhdr want: HTML\n";
		    $tmp.=" -->\n";
		    print $fhoutLoc $tmp;}

		print $fhoutLoc $line; 
	    }
	    close($fhinLoc); } }
    if (! $Lok) {		# write anew

				# hack br 99-04
	$tmp= "<HTML><HEAD>\n";
	$tmp.="<!-- \n";
	$tmp.="PPhdr from: $User_name\n";
	$tmp.="PPhdr orig: MAIL\n" if ($fileJobId=~/_e/);
	$tmp.="PPhdr orig: HTML\n" if ($fileJobId=~/_h/);
	$tmp.="PPhdr resp: MAIL\n";
	$tmp.="PPhdr want: HTML\n";
	$tmp.=" -->\n";
	    
				# dirty
	$tmp= `cat $fileAppHtmlStyles`; # dirty system call
	
	$tmp.="<TITLE>PredictProtein results for $fileJobId</TITLE>";
#	$tmp.="<link rel=\"stylesheet\" type=\"text/css\" href=\"http://www.predictprotein.org/newwebsite/css/main.css\"/>"; 
	$tmp.="</HEAD>\n";
	$tmp.="<BODY style=\"background:white\">\n";
	$tmp.="<H1>PredictProtein results for $fileJobId</H1>\n";
	print $fhoutLoc $tmp; }

				# ------------------------------
				# (4) add TOC
				# ------------------------------
    if (-e $fileHtmlToc) {
	($Lok=open($fhinLoc,$fileHtmlToc)) ||
	    do { print "*** ERROR $sbrName2: failed opening fileHtmlToc=$filetmlToc\n"; };
	if ($Lok) {
	    while (<$fhinLoc>) {
		print $fhoutLoc $_; 
	    }
	    close($fhinLoc); } }
				# ------------------------------
				# (5) add BODY
				# ------------------------------
    if (-e $fileHtmlTmp) {
	($Lok=open($fhinLoc,$fileHtmlTmp)) ||
	    do { print "*** ERROR $sbrName2: failed opening fileHtmlTmp=$filetmlTmp\n"; };
	if ($Lok) {
	    while (<$fhinLoc>) {
		print $fhoutLoc $_; 
	    }
	    close($fhinLoc); } }
    return(0,"*** ERROR $sbrName2: serious error no HTML body file ($fileHtmlTmp)!\n".
	   $msg."\n")           if (! $Lok);

				# ------------------------------
				# (6) add specific FOOTER (quotes)
				# ------------------------------

    $Lok=0;
    if (-e $fileAppHtmlQuote || -l $fileAppHtmlQuote) {
	($Lok=open($fhinLoc,$fileAppHtmlQuote)) || # 
	    do { print "*** ERROR $sbrName2: failed opening fileAppHtmlQuote=$fileAppHtmlQuote\n"; };

	if ($Lok) {		# 
	    while (<$fhinLoc>) {# 
				    $line=$_;
				    $line=~s/VAR_jobid/$fileJobId/g
					if ($_=~/VAR_jobid/);
				    # skip comments
				    next if ($line=~/^\s*<!\-\-.*\-\->/);
				    print $fhoutLoc $line; 
				}
	    close($fhinLoc); } }# 
				# alternative: write anew
		if (! $Lok) {
		    print "-*- WARN $sbrName2: failed appending quotes ($fileAppHtmlQuote)\n";
		    $tmp="</BODY>\n</HTML>\n";
		    print $fhoutLoc $tmp;
		}



    # ---------------
    # Old Way Quotes
    # ---------------

#    print $fhoutaLoc 
#	"<P><BR><P>\n",
#	"<H2>Quotes for methods</H2>\n",
#	"<OL>\n";

#    undef %tmp;
#    foreach $kwd (keys %html){
#	next if ($kwd !~/^flag_method/);
#	$kwdLoc=$kwd; $kwdLoc=~s/flag_method//g; $kwdLoc=~s/[^a-zA-Z0-9\_\-]//g;
#	$kwdTmp=$kwdLoc; $kwdTmp=~s/ali_|_head|_info|_body|_hssp|_prof|_own|_msf|_saf//g;
#	$kwdTmp=~s/_norm|_glob//g;
#	next if (! defined $method{"quote_".$kwdTmp});
#	$tmp{$kwdTmp}=1;}
#    foreach $kwdTmp ("pp","prosite","seg","prodom","blast","maxhom","mview",
#		     "phd", "phd_sec", "phd_acc", "phd_htm",
#		     "prof","prof_sec","prof_acc","prof_htm",
#		     "globe","topits","norsp",
#		     "coils","cyspred","asp") {
#	next if (! defined $tmp{$kwdTmp});
#	$quote=$method{"quote_".$kwdTmp};
#	print $fhoutLoc
#	    "<LI><A NAME=\"quote_".$kwdTmp."\">".
#		"<STRONG><FONT SIZE=\"+1\">".
#		    $method{"name_".$kwdTmp}."</FONT>: </A>\n".
#		    "<CITE>".$quote."</CITE></STRONG>\n";
#	$tmp="";
#	$tmp.="<LI>Author:      ".$method{"author_".$kwdTmp}."\n" 
#	    if (defined $method{"author_".$kwdTmp} && length($method{"author_".$kwdTmp})>0);
#	$tmp.="<LI>Contact:     ".$method{"contact_".$kwdTmp}."\n" 
#	    if (defined $method{"contact_".$kwdTmp} && length($method{"contact_".$kwdTmp})>0);
#	$tmp.="<LI>Url:         "."<A HREF=\"".$method{"url_".$kwdTmp}."\">".
#	    $method{"url_".$kwdTmp}."</A>\n" 
#	    if (defined $method{"url_".$kwdTmp} && length($method{"url_".$kwdTmp})>0);
#	$tmp.="<LI>Copyright:   ".$method{"copyright_".$kwdTmp}."\n" 
#	    if (defined $method{"copyright_".$kwdTmp} && length($method{"copyright_".$kwdTmp})>0);
#	$tmp.="<LI>Version:     ".$method{"version_".$kwdTmp}."\n" 
#	    if (defined $method{"version_".$kwdTmp} && length($method{"version_".$kwdTmp})>0);
#	$tmp.="<LI>Description: ".$method{"des_".$kwdTmp}."\n" 
#	    if (defined $method{"des_".$kwdTmp} && length($method{"des_".$kwdTmp})>0);

#	print $fhoutLoc
#	    "<UL>\n",
#	    $tmp,
#	    "</UL>\n"          if (length($tmp) > 1); }
#    print $fhoutLoc "</OL>\n","<P><BR><P>\n";

				# ------------------------------
				# (7) add general FOOTER (links)
				# ------------------------------
    $Lok=0;
    if (-e $fileAppHtmlFoot || -l $fileAppHtmlFoot) {
	($Lok=open($fhinLoc,$fileAppHtmlFoot)) ||
	    do { print "*** ERROR $sbrName2: failed opening fileAppHtmlFoot=$fileAppHtmlFoot\n"; };

	if ($Lok) {
	    while (<$fhinLoc>) {
		$line=$_;
		$line=~s/VAR_jobid/$fileJobId/g
		    if ($_=~/VAR_jobid/);
				# skip comments
		next if ($line=~/^\s*<!\-\-.*\-\->/);
		print $fhoutLoc $line; 
	    }
	    close($fhinLoc); } }
				# alternative: write anew
    if (! $Lok) {
	print "-*- WARN $sbrName2: failed appending footer ($fileAppHtmlFoot)\n";
	$tmp="</BODY>\n</HTML>\n";
	print $fhoutLoc $tmp;}

    return(1,"ok $sbrName2");
}				# end of htmlFin

#===============================================================================
sub htmlMaxhom {
    local($fileInAliMsfLoc,$fileInAliFilOutLoc,$exeMviewLoc,$parStandardLoc,$optOut,
	  $fileOutLoc,$fileOutHtmlLoc,$fileOutHtmlTocLoc,$fhoutSbr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlMaxhom                  writes the HTML part for MaxHom
#       in:                     $fileInBlastLoc=     direct output from Blast BLAST
#       in:                     $fileInAliFilOutLoc= file from filter (for security if MView fails)
#       in:                     $exeMview=           executable (perl)
#       in:                     $paraStandard=       standard parameters
#                                   =0               for standard setting
#       in:                     $optOut=          general string written by extrHdrOnline
#                                                 used here 'perline=N'
#       in:                     $fileOut=            name of output file written by MView
#       in:                     $fileOutHtml=        file into which to write (BODY)
#       in:                     $fileOutHtmlToc=     file into which to write TOC
#       in:                     $fhoutSbr=           file handle to write system call
#                                  =0                no output reported
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlMaxhom";
    $fhinLoc="FHIN_"."htmlMaxhom";$fhoutLoc="FHOUT_"."htmlMaxhom";
    $errMsg="*** ERROR in arg for $sbrName: ";
				# check arguments
    return(0,0,$errMsg."not def fileInAliMsfLoc!")      if (! defined $fileInAliMsfLoc);
    return(0,0,$errMsg."not def fileInAliFilOutLoc!")   if (! defined $fileInAliFilOutLoc);
    return(0,0,$errMsg."not def exeMviewLoc!")          if (! defined $exeMviewLoc);
    return(0,0,$errMsg."not def parStandard!")          if (! defined $parStandardLoc);
    return(0,0,$errMsg."not def optOut!")               if (! defined $optOut);
    return(0,0,$errMsg."not def fileOut!")              if (! defined $fileOutLoc);
    return(0,0,$errMsg."not def fileOutHtmlLoc!")       if (! defined $fileOutHtmlLoc);
    return(0,0,$errMsg."not def fileOutHtmlTocLoc!")    if (! defined $fileOutHtmlTocLoc);
    $fhoutSbr=0                                         if (! defined $fhoutSbr);
#    return(0,$errMsg."not def !")          if (! defined $);

    return(0,0,$errMsg."no fileInAliMsf=$fileInAliMsfLoc!") if (! -e $fileInAliMsfLoc);
    return(0,0,$errMsg."no fileIn=$exeMviewLoc!")           if (! -e $exeMviewLoc && 
								! -l $exeMviewLoc);
				# ------------------------------
				# restrict line width
    if ($optOut=~/perline=(\d+)/) {
	$parStandardLoc.=" -label2 -label3 -label4 -width $1"; }


				# --------------------------------------------------
				# produce MView version of ProDom Blastp alignment
				# --------------------------------------------------
    $format="msf";
    $format="hssp"
	if ($fileInAliMsfLoc=~/\.hssp|maxhom/i);
    ($Lok,$msg)=
	&mviewRun($fileInAliMsfLoc,$format," ",$exeMviewLoc,$parStandardLoc,
		  $fileOutLoc,"data",$fhoutSbr);

    $fileHtmlMviewOut=$fileOutLoc;
				# ------------------------------
				# problem: take original ali
    if (! $Lok) { 
	print $fhTrace "*** $sbr: failed to MView msg=",$msg,"\n"; 
	$fileHtmlMviewOut=$fileInAliFilOutLoc; }
				# ------------------------------
    else {			# mview ok: write quote
				# quote literature
				# pointers to move in document
	$kwdTmp="mview";
# 	$txt= "<UL>\n";
# 	$txt.="<LI> Go to quote for method <A HREF=\"#quote_".$kwdTmp."\">$kwdTmp</A>";
# 	$txt.="</UL>\n";
# 	($Lok,$msg)=
# 	    &htmlBuild($txt,$fileOutHtmlLoc,$fileOutHtmlTocLoc,1,"txt");
	$html{"flag_method",$kwdTmp}=1 if (! defined $html{"flag_method",$kwdTmp});}

				# ------------------------------
				# now build ali to return
				# ------------------------------
    ($Lok,$msg)=
	&htmlBuild($fileHtmlMviewOut,$fileOutHtmlLoc,$fileOutHtmlTocLoc,0,"ali_maxhom_body");
    if (! $Lok) { $msg="*** err=2242 ($sbr: htmlBuild failed kwd=ali_maxhom_body)\n".$msg."\n";
		  print $fhTrace $msg;
		  return(0,"err=2242",$msg); }

    return(1,"ok","ok $sbrName");
}				# end of htmlMaxhom

#===============================================================================
sub htmlProdom {
    local($fileInProdomBlastLoc,$fileInProdomFinLoc,$exeMviewLoc,$parStandardLoc,$optOut,
	  $fileOutLoc,$fileOutHtmlLoc,$fileOutHtmlTocLoc,$fhoutSbr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlProdom                  writes the HTML part for PRODOM
#       in:                     $fileInProdomBlastLoc=       
#                                                 direct output from ProDom BLAST
#       in:                     $fileInProdomFinLoc=
#                                                 output processed by prodomRun
#       in:                     $exeMview=        executable (perl)
#       in:                     $paraStandard=    standard parameters
#                                   =0            for standard setting
#       in:                     $optOut=          general string written by extrHdrOnline
#                                                 used here 'perline=N'
#       in:                     $fileOut=         name of output file written by Mview
#       in:                     $fileOutHtml=     file into which to write (BODY)
#       in:                     $fileOutHtmlToc=  file into which to write TOC
#       in:                     $fhoutSbr=        file handle to write system call
#                                  =0             no output reported
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlProdom";
    $fhinLoc="FHIN_"."htmlProdom";$fhoutLoc="FHOUT_"."htmlProdom";
    $errMsg="*** ERROR in arg for $sbrName: ";
				# check arguments
    return(0,0,$errMsg."not def fileInProdomBlastLoc!") if (! defined $fileInProdomBlastLoc);
    return(0,0,$errMsg."not def fileInProdomFinLoc!")   if (! defined $fileInProdomFinLoc);
    return(0,0,$errMsg."not def exeMviewLoc!")          if (! defined $exeMviewLoc);
    return(0,0,$errMsg."not def parStandard!")          if (! defined $parStandardLoc);
    return(0,0,$errMsg."not def optOut!")               if (! defined $optOut);
    return(0,0,$errMsg."not def fileOut!")              if (! defined $fileOutLoc);
    return(0,0,$errMsg."not def fileOutHtmlLoc!")       if (! defined $fileOutHtmlLoc);
    return(0,0,$errMsg."not def fileOutHtmlTocLoc!")    if (! defined $fileOutHtmlTocLoc);
    $fhoutSbr=0                                         if (! defined $fhoutSbr);
#    return(0,$errMsg."not def !")          if (! defined $);

    return(0,0,$errMsg."no fileInBlast=$fileInProdomBlastLoc!") if (! -e $fileInProdomBlastLoc);
    return(0,0,$errMsg."no fileInFin  =$fileInProdomFinLoc!")   if (! -e $fileInProdomBlastLoc);
    return(0,0,$errMsg."no fileIn=$exeMviewLoc!")               if (! -e $exeMviewLoc && 
								    ! -l $exeMviewLoc);
				# ------------------------------
				# restrict line width
    if ($optOut=~/perline=(\d+)/) {
	$parStandardLoc.=" -label2 -label3 -label4 -width $1"; }

				# --------------------------------------------------
				# produce MView version of ProDom Blastp alignment
				# --------------------------------------------------
    ($Lok,$msg)=
	&mviewRun($fileInProdomBlastLoc,"blast"," ",$exeMviewLoc,$parStandardLoc,
		  $fileOutLoc,"data",$fhoutSbr);

				# --------------------------------------------------
				# append the stuff extracted by prodomRun
				# --------------------------------------------------
    open($fhinLoc,$fileInProdomFinLoc) ||
	return(0,0,"*** ERROR $sbrName: failed opening fileInProdomFinLoc=$fileInProdomFinLoc!");
    while (<$fhinLoc>) {
	last if ($_=~/^[\- ]* END of BLAST/i);}
    open($fhoutLoc,">>".$fileOutLoc) ||
	return(0,0,"*** ERROR $sbrName: failed appending to fileOut=$fileOutLoc!");
	
    print $fhoutLoc "<PRE>\n";
    while (<$fhinLoc>) {
	$line=$_;
	$line=~s/\n//g;
				# add links
	if ($line=~/http/ && $line !~/a href/i) {
	    $line=~s/(http[^\s\"]+)/<A HREF=\"$1\">$1<\/A>/g; 
	}
	print $fhoutLoc $line,"\n";
    }
    print $fhoutLoc "</PRE><P>\n";
    close($fhinLoc);
    close($fhoutLoc);
				# --------------------------------------------------
				# append file
				# --------------------------------------------------
    ($Lok,$msg)=
	&htmlBuild($fileOutLoc,$fileOutHtmlLoc,$fileOutHtmlTocLoc,0,"prodom");
    if (! $Lok) { $msg="*** err=2233 ($sbr: htmlBuild failed on kwd=prodom)\n".$msg."\n";
		  print $fhTrace $msg;
		  return(0,"err=2233",$msg); }

    return(1,"ok","ok $sbrName");
}				# end of htmlProdom

#===============================================================================
sub htmlTopits {
    local($fileInTopitsLoc,$exeMviewLoc,$parStandardLoc,$optOut,
	  $fileOutLoc,$fileOutHtmlLoc,$fileOutHtmlTocLoc,$fhoutSbr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlTopits                  writes the HTML part for TOPITS
#       in:                     $fileInTopitsLoc=  direct output from Topits Topits
#       in:                     $exeMview=        executable (perl)
#       in:                     $paraStandard=    standard parameters
#                                   =0            for standard setting
#       in:                     $optOut=          general string written by extrHdrOnline
#                                                 used here 'perline=N'
#       in:                     $fileOut=         name of output file written by MView
#       in:                     $fileOutHtml=     file into which to write (BODY)
#       in:                     $fileOutHtmlToc=  file into which to write TOC
#       in:                     $fhoutSbr=        file handle to write system call
#                                  =0             no output reported
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlTopits";
    $fhinLoc="FHIN_"."htmlTopits";$fhoutLoc="FHOUT_"."htmlTopits";
    $errMsg="*** ERROR in arg for $sbrName: ";
				# check arguments
    return(0,0,$errMsg."not def fileInTopitsLoc!")       if (! defined $fileInTopitsLoc);
    return(0,0,$errMsg."not def exeMviewLoc!")          if (! defined $exeMviewLoc);
    return(0,0,$errMsg."not def parStandard!")          if (! defined $parStandardLoc);
    return(0,0,$errMsg."not def optOut!")               if (! defined $optOut);
    return(0,0,$errMsg."not def fileOut!")              if (! defined $fileOutLoc);
    return(0,0,$errMsg."not def fileOutHtmlLoc!")       if (! defined $fileOutHtmlLoc);
    return(0,0,$errMsg."not def fileOutHtmlTocLoc!")    if (! defined $fileOutHtmlTocLoc);
    $fhoutSbr=0                                         if (! defined $fhoutSbr);
#    return(0,$errMsg."not def !")          if (! defined $);

    return(0,0,$errMsg."no fileInTopits=$fileInTopitsLoc!") if (! -e $fileInTopitsLoc);
    return(0,0,$errMsg."no fileIn=$exeMviewLoc!")           if (! -e $exeMviewLoc && 
								! -l $exeMviewLoc);

				# ------------------------------
				# restrict line width
    if ($optOut=~/perline=(\d+)/) {
	$parStandardLoc.=" -label2 -label3 -label4 -width $1"; }


				# --------------------------------------------------
				# produce MView version of ProDom Topitsp alignment
				# --------------------------------------------------
    ($Lok,$msg)=
	&mviewRun($fileInTopitsLoc,"msf"," ",$exeMviewLoc,$parStandardLoc,
		  $fileOutLoc,"data",$fhoutSbr);

				# if no output: just append Topits file
    if (! $Lok) { $msg="*** $sbrName: htmlBuild failed on kwd=topits_msf\n".$msg."\n";
		  print $fhTrace $msg;
		  $fileOutLoc=$fileInTopitsLoc; }

				# --------------------------------------------------
				# append file
				# --------------------------------------------------

    ($Lok,$msg)=
	&htmlBuild($fileOutLoc,$fileOutHtmlLoc,$fileOutHtmlTocLoc,1,"topits_msf");
    if (! $Lok) { $msg="*** err=2288 ($sbrName: htmlBuild failed on kwd=topits_msf)\n".$msg."\n";
		  print $fhTrace $msg;
		  return(0,"err=2288",$msg); }

    return(1,"ok","ok $sbrName");
}				# end of htmlTopits

#==============================================================================
sub interpretSeqCol {
    local ($fileOutLoc,$fileOutGuideLoc,$nameFileIn,$Levalsec,$fhErrSbr,@seqIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,@tmp,$fhout,$fhout2,$Lhead,$ct,$ctok,
	   $it,$des,$Lptr,$Lguide,$seqGuide,$nameGuide,@des_column_format,@des_evalsec,
	   $sec,$acc,$itx,%rd,%ptrkey2,%ptr2rd);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqCol             extracts the column input format and writes it
#       in:                     $fileOutLoc,$fileOutGuideLoc,$nameFileIn,$Levalsec,
#       in:                     $fhErrSbr,@seqIn
#       out:                    either write for EVALSEC or DSSP format and guide in FASTA
#       in/out GLOBAL:          @NUM,@SEQ,@SEC(HE ),@ACC,@RISEC,@RIACC (for wrt_dssp_phd)
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> ERROR while writing output
#       err:                    c: (3,msg) -> guide sequence not written
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqCol";
    return(0,"*** $sbrName: not def fileOutLoc!") if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def nameFileIn!") if (! defined $nameFileIn);
    return(0,"*** $sbrName: not def Levalsec!")   if (! defined $Levalsec);
    return(0,"*** $sbrName: not def fhErrSbr!")   if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def seqIn[1]!")   if (! defined $seqIn[1]);
				# desired column names for COLUMN format (make non-local)
#    @des_column_all=("AA","PHEL","OHEL","RI_S","OTH","OTE","OTL","PACC","PREL","RI_A","PBIE",
#		     "OT0","OT1","OT2","OT3","OT4","OT5","OT6","OT7","OT8","OT9","NAME");

    @des_column_format=("AA","PHEL","RI_S","PACC","RI_A","OHEL","NAME");
    @des_evalsec=      ("NAME","AA","PHEL","OHEL");
    %ptrkey2=('AA',   "AA",     'NAME', "NAME",
	      'PHEL', "PSEC",   'OHEL', "OSEC",   'PACC', "PACC", 
	      'RI_S', "RI_SEC", 'RI_A', "RI_ACC");
    $fhout="FHOUT_".$sbrName;$fhout2="FHOUT2_".$sbrName;
    $ct=0;			# initialise arrays asf
    $#SEQ=$#SEC=$#ACC=$#RISEC=$#RIACC=$#OSEC=$#NAME=0; # GLOBAL for wrt_dssp_phd
                                # ----------------------------------------
                                # continue reading open file
                                # ----------------------------------------
    foreach $_ (@seqIn){
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	next if (length($_)==0);
	$tmp=$_;$tmp=~s/\n//g;
	$tmp=~tr/[a-z]/[A-Z]/;	# lower to upper
	++$ct;
	last if ($_ !~/[\s\t]*\d+/ && $ct>1);
	$tmp=~s/^[ ,\t]*|[ ,\t]*$//g; # purge leading blanks begin and end
	$#tmp=0;
	@tmp=split(/[\s\t,]+/,$tmp); # split spaces, tabs, or commata
	if ($ct==1){		# first line: check identifiers passed
	    undef %ptr2rd;$ctok=$Lok=0;
	    foreach $des (@des_column_format){
		foreach $it (1..$#tmp) {
		    if ($des eq $tmp[$it]) {
			++$ctok;$Lok=1;$ptr2rd{$des}=$it; 
			last; }
				# alternative key?
		    elsif (defined $ptrkey2{$des} && $ptrkey2{$des} eq $tmp[$it]) {
			++$ctok;$Lok=1;$ptr2rd{$des}=$it; 
			last; } }
		if (! $Lok) {
		    if ($des=~/AA|PHEL|PACC/){$ctok=0;
					      last;}
		    print $fhErrSbr
			"*** $sbrName ERROR: names in columns, des=$des, not found\n";} }
	    $Lptr=1 if ($ctok>=3);} # at least 3 found?
	elsif ($ct>1) {		# for all others read
	    if (! $Lptr){	# stop if no amino acid
		print $fhErrSbr "*** $sbrName ERROR: not Lptr error? (30.6.95) \n";
		next;}
	    if (defined $ptr2rd{"AA"})  {
		$tmp=$tmp[$ptr2rd{"AA"}];
		if ($tmp !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ\.\- ]/){
		    $Lptr=0;
		    last;}
		push(@SEQ,  $tmp[$ptr2rd{"AA"}]);}
	    push(@SEC,  $tmp[$ptr2rd{"PHEL"}]) if (defined $ptr2rd{"PHEL"});
	    push(@ACC,  $tmp[$ptr2rd{"PACC"}]) if (defined $ptr2rd{"PACC"});
	    push(@OSEC, $tmp[$ptr2rd{"OHEL"}]) if (defined $ptr2rd{"OHEL"});
	    push(@RISEC,$tmp[$ptr2rd{"RI_S"}]) if (defined $ptr2rd{"RI_S"});
	    push(@RIACC,$tmp[$ptr2rd{"RI_A"}]) if (defined $ptr2rd{"RI_A"});
	    push(@NAME, $tmp[$ptr2rd{"NAME"}]) if (defined $ptr2rd{"NAME"}); }
    }
                                # ----------------------------------------
				# error checks
                                # ----------------------------------------
    $Lok=1;
    foreach $sec (@SEC){
	if ($sec=~/[^HEL \.]/){
	$Lok=0;			# wrong secondary structure symbol
	$msg="wrong secStr: allowed H,E,L ($sec)";
	print $fhErrSbr "*** $sbrName ERROR: $msg\n";
	last;}}
    if ($Lok && ($#ACC>0)){
	foreach $acc (@ACC){
	    if (($acc=~/[^0-9]/) || (int($acc)>500) ){
		$Lok=0;		# wrong values for accessibility
		$msg="wrong acc: allowed 0-500 ($acc)";
		print $fhErrSbr "*** $sbrName ERROR: $msg\n";
		last;}}}
    if ($Lok && ($#SEQ<1)){
	$Lok=0;			# not enough sequences
	$msg="sequence array empty";print $fhErrSbr "*** $sbrName ERROR: $msg\n";}
    if ($Lok && ( $Levalsec && ($#OSEC<1))){
	$Lok=0;			# EVALSEC: must have observed sec str
	$msg="for EVALSEC OSEC must be defined\n";print $fhErrSbr "*** $sbrName ERROR: $msg\n";}
				# ******************************
				# error: read/write col format
    return(2,"*** $sbrName ERROR $msg") if (! $Lok);
				# ******************************

                                # ----------------------------------------
				# write output file
                                # ----------------------------------------
				# added br may 96, as noname crushed!
    $itx=0;			# to avoid warnings
    if ($#NAME==0){
	foreach $itx(1..$#SEC){
	    push(@NAME,"unk");}}
				# open file
    open("$fhout",">$fileOutLoc")  || 
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
				# avoid warning
    $#NUM=0                     if (! defined @NUM);

				# ------------------------------
    if ($Levalsec){		# write PP2dotpred format 
	undef %rd;
	$rd{"des"}="";		# convert to global
	foreach $des (@des_evalsec){
	    $rd{"des"}.=$des."  ";
	    if    ($des=~/AA/)  { foreach $it (1..$#SEQ) { $rd{$des,$it}=$SEQ[$it];}}
	    elsif ($des=~/PHEL/){ foreach $it (1..$#SEC) { $rd{$des,$it}=$SEC[$it];}}
	    elsif ($des=~/OHEL/){ foreach $it (1..$#OSEC){ $rd{$des,$it}=$OSEC[$it];}}
	    elsif ($des=~/NAME/){ foreach $it (1..$#NAME){ $rd{$des,$it}=$NAME[$it];} }}
	($Lok,$msg)=
	    &wrt_ppcol("$fhout",%rd); }
				# ------------------------------
    else {			# write DSSP file
	foreach $it (1..$#SEQ){
	    push(@NUM,$it);}	# convert to global
	$Lok=
	    &wrt_dssp_phd("$fhout",$nameFileIn);}
    close("$fhout");

				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n")
	if (! -e $fileOutLoc);
				# ******************************
				# error: read/write col format
    return(2,"*** $sbrName internal error while writing fileOutLoc=$fileOutLoc\n")
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    if (! $Levalsec){
	if (defined $NAME[1]){
	    $nameGuide=$NAME[1];}
	else {
	    $nameGuide=$fileOutGuideLoc;$nameGuide=~s/^.*\/|\..*$//g;}
	$seqGuide="";
	foreach $tmp(@seq){
	    $seqGuide.=$tmp;}
	$seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g; # delete non amino acid characters!
	($Lok,$msg)=
	    &fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
	return(3,"*** $sbrName cannot write fasta of guide\n".
	       "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	       "*** ERROR message: $msg\n") if (! $Lok || ! -e $fileOutGuideLoc);}
				# ------------------------------
    undef %rd; $#seqIn=0;	# save space
    $#SEQ=$#SEC=$#ACC=$#RISEC=$#RIACC=$#OSEC=$#NAME=0;
    $seqGuide="";		# save space

    return(1,"$sbrName ok");
}				# end of interpretSeqCol

#==============================================================================
sub interpretSeqFastalist {
    local ($fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,
	   $optJobLoc,@seqIn)=@_;
    local (@seq,$ct,$ctprot,$fhout_guide,$fhout_other,$sbrName,$name,@name,%seq,%name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqFastalist       extracts the Fasta list input format
#       in:                     $fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn
#       out:                    writes 2 Fasta files for guide and to-be-aligned
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> wrong format 
#       err:                    c: (3,msg) -> too few alis 
#       err:                    d: (4,msg) -> seq too short
#       err:                    e: (1,msg) -> ok
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqFastalist";
    return(0,"*** $sbrName: not def fileOutLocGuide!") if (! defined $fileOutLocGuide);
    return(0,"*** $sbrName: not def fileOutLocOther!") if (! defined $fileOutLocOther);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def lenMinLoc!")       if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);

    $fhout_guide="FILEFASTALIST_GUIDE";
    $fhout_other="FILEFASTALIST_OTHER";
    $ct=$#name=0; undef %seq; undef %name;
				# --------------------------------------------------
    while (@seqIn) {		# first: check format by correctness of first tag '>'
	$_ = shift @seqIn;
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	next if ($_!~/^\s*>/);	# search first '>' = guide sequence
	$_=~s/\n//g;
	$_=~s/^\s*>\s*//g;$_=~s/\s*$//g; # purge blanks asf
	if ( /\bgi\|(\d+)\b/ ) {
	    $_ = $1;
	}
	$_=~s/\s|\./_/g;	# blanks, dots to '_'
	$_=~s/^\_*|\_*$//g;	# purge off leading '_'
	$_=~s/^.*\|//g;		# purge all before first '|'
	$_=~s/,.*$//g;		# purge all after comma
	$name=substr($_,1,15);	# shorten
	$name=~s/__/_/g;	# '__' -> '_'
	$name=~s/,//g;		# purge comma
	last;}
    return(2,"*** $sbrName ERROR no tag '>' found\n") if (length($name)<1 || ! defined $name);

    $name{$name}=1;push(@name,$name);$seq{$name}=""; # for guide sequence
    $ctprot=0;			# --------------------------------------------------
    while (@seqIn) {		# now extract the guide sequence, and all others
	$_ = shift @seqIn;$_=~s/\n//g;
				# ------------------------------
	if ($_=~/^\s*\>/ ) {	# name
	    ++$ctprot;$ct=1;$#seq=0;
	    $_=~s/^\s*\>\s*//g;$_=~s/\s*$//g; # purge blanks asf
	    if ( /\bgi\|(\d+)\b/ ) {
		$_ = $1;
	    }
	    $_=~s/[\s\.]/_/g;	# blanks, dots to '_'
	    $_=~s/^\_*|\_*$//g;	# purge off leading '_'
	    $_=~s/^.*\|//g;	# purge all before first '|'
	    $_=~s/,.*$//g;	# purge all after comma
	    $_=~s/\//_/g;       # '/' -> '_'
	    $name=substr($_,1,14); # shorten
	    $name=~s/__/_/g;	# '__' -> '_'
	    $name=~s/,//g;	# purge comma
	    $name=~s/[\(\)].*$//g; # purge '(..'
	    $name=~s/_*$//;	# purge off leading '_'
	    if (defined $name{$name}){
		$ctTmp=1;$name=substr($name,1,13); # shorten further
		while (defined $name{$name.$ctTmp}){
		    $name=substr($name,1,12) if ($ctTmp==9);
		    ++$ctTmp;}
		$name.=$ctTmp;}
	    $name{$name}=1;
	    $name.=$name."_".$ctprot if (length($name)<5);
	    $seq{$name}="";push(@name,$name);}
				# ------------------------------
	else {			# sequence
	    $_=~s/^[\d\s]*(.)/$1/g; # purge leading blanks/numbers
	    $_=~s/\s//g;	# purge all blanks
	    $_=~tr/[a-z]/[A-Z]/; # upper case
				# correct non-residue
	    $_=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ\.]/X/g;
	    $seq{$name}.=$_ . "\n" 
		if (! /[^ABCDEFGHIKLMNPQRSTVWXYZ\.]/); }
    }				# end of loop over input array
				# --------------------------------------------------

				# print new file in FASTA format
				# ------------------------------
				# guide sequence in FASTA format
    open($fhout_guide,">$fileOutLocGuide") ||
	return(0,"*** $sbrName cannot open new fileOutLocGuide=$fileOutLocGuide\n");
    $seq{$name[1]}=~s/\.|\_//g  if ($optJobLoc !~/doNotAlign/);
    print $fhout_guide ">".$name[1]."\n".$seq{$name[1]}."\n" ;
    close($fhout_guide);
				# ------------------------------
				# others in FASTA format (as list)
#********************************************************************************x.1
#   set to 1, 2 ... if you want to allow alignments with at least 2, 3, .. sequences
#********************************************************************************x.1
				# too few alis
    return(3,"*** ERROR $sbrName wrong format in seq to pir list (too few alis)!\n")
	if ( $#name < 1);
				# seq too short
    return(4,"*** ERROR $sbrName len=".length($seq{$name[1]}).
	   ", i.e. too few residues in $name[1]!\n")
	if (length($seq{$name[1]}) <= $lenMinLoc);

    open($fhout_other,">$fileOutLocOther") ||
	return(0,"*** ERROR $sbrName cannot open new fileOutLocOther=$fileOutLocOther\n");
    foreach $it (1..$#name){
	$seq=$seq{$name[$it]};
	return(4,"*** ERROR $sbrName wrong FASTA format\n".
	       "*** protein name=$name[$it], seems to have only ".length($seq)." residues!")
	    if (length($seq) <= ($lenMinLoc - 10) ||
		length($seq) == 0);
	$seq{$name[$it]}=~s/\.|\_//g
	    if ($optJobLoc !~/doNotAlign/);
	print $fhout_other 
	    ">$name[$it]\n",	# name
	    $seq{$name[$it]};	# sequence
				# sequence end
	print $fhout_other "\n" if ($seq{"$name[$it]"} !~/\n$/);}
    close($fhout_other);
    return(1,"$sbrName ok");
}				# end of interpretSeqFastalist

#==============================================================================
sub interpretSeqFastamul {
    local ($fileOutLocGuide,$lenMinLoc,$fhErrSbr,@seqIn)=@_;
    local (@seq,$ct,$ctprot,$fhout_guide,$fhout_other,$sbrName,$name,@name,%seq,%name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqFastamul       extracts the Fasta list input format
#       in:                     $fileOutLocGuide,$lenMinLoc,$fhErrSbr,@seqIn
#       out:                    writes 2 Fasta files for guide and to-be-aligned
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> wrong format 
#       err:                    c: (3,msg) -> too few alis 
#       err:                    d: (4,msg) -> seq too short
#       err:                    e: (1,msg) -> ok
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqFastamul";
    return(0,"*** $sbrName: not def fileOutLocGuide!") if (! defined $fileOutLocGuide);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def lenMinLoc!")       if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);

    $fhout_guide="FILEFASTAMUL_GUIDE";
    $ct=$#name=0; undef %seq; undef %name;
				# --------------------------------------------------
    while (@seqIn) {		# first: check format by correctness of first tag '>'
	$_ = shift @seqIn;
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	next if ($_!~/^\s*\>/);	# search first '>' = guide sequence
	$_=~s/\n//g;
	$_=~s/^\s*\>\s*//g;$_=~s/\s*$//g; # purge blanks asf
	if ( /\bgi\|(\d+)\b/ ) {
	    $_ = $1;
	}			# 
 	$_=~s/[\s\.]/_/g;	# blanks, dots to '_'
	$_=~s/^\_|\_$//g;	# purge off leading '_'
	$_=~s/^.*\|//g;		# purge all before first '|'
	$_=~s/,.*$//g;		# purge all after comma
	$name=substr($_,1,15);	# shorten
	$name=~s/__/_/g;	# '__' -> '_'
	$name=~s/,//g;		# purge comma
	last;}
    return(2,"*** $sbrName ERROR no tag '>' found OR name < 2 characters\n") 
	if (length($name)<2 || ! defined $name);

    $name{$name}=1;push(@name,$name);$seq{$name}=""; # for guide sequence

    $ctprot=0;			# --------------------------------------------------
    while (@seqIn) {		# now extract the guide sequence, and all others
	$_ = shift @seqIn;
	$_=~s/\n//g;
				# ------------------------------
	if ($_=~/^\s*>/ ) {	# name
	    ++$ctprot;$ct=1;$#seq=0;
	    $_=~s/^\s*\>\s*//g;$_=~s/\s*$//g; # purge blanks asf
	    $_=~s/\s|\./_/g;	# blanks, dots to '_'
	    if ( /\bgi\|(\d+)\b/ ) {
		$_ = $1;
	    }
	    $_=~s/^\_|\_$//g;	# purge off leading '_'
	    $_=~s/^.*\|//g;	# purge all before first '|'
	    $_=~s/,.*$//g;	# purge all after comma
	    $name=substr($_,1,14); # shorten
	    $name=~s/__/_/g;	# '__' -> '_'
	    $name=~s/,//g;	# purge comma
	    $name=~s/[\(\)].*$//g; # purge '(..'
	    $name=~s/_*$//;	# purge off leading '_'
	    if (defined $name{$name}){
		$ctTmp=1;$name=substr($name,1,13); # shorten further
		while(defined $name{$name.$ctTmp}){
		    $name=substr($name,1,12) if ($ctTmp==9);
		    ++$ctTmp;}
		$name.=$ctTmp;}
	    $name{$name}=1;
	    $name.=$name."_$ctprot" if (length($name)<5);
	    $seq{$name}="";push(@name,$name);}
				# ------------------------------
	else {			# sequence
				# purge leading blanks/numbers
	    $_=~s/^[\d\s]*(.+)|[\d\s]$/$1/g;
				# purge all blanks
	    $_=~s/\s//g;
				# upper case
	    $_=~tr/[a-z]/[A-Z]/;
				# strange to dot
	    $_=~s/[\-_]/\./g;
	    $seq{$name}.=$_ . "\n" 
		if ($_ !~ /[^ABCDEFGHIKLMNPQRSTVWXYZ\.\-]/);}
    }				# end of loop over input array
				# --------------------------------------------------
				# print new file in FASTA format
				# ------------------------------
				# guide sequence in FASTA format
    open("$fhout_guide",">$fileOutLocGuide") ||
	return(0,"*** $sbrName cannot open new fileOutLocGuide=$fileOutLocGuide\n");
    foreach $it (1..$#name){
				# name
	$tmpPrt= ">".$name[$it]."\n";
				# sequence
	$tmpPrt.=$seq{"$name[$it]"};
				# sequence end
	$tmpPrt.="\n"           if ($seq{$name[$it]} !~/\n$/);
	print $fhout_guide $tmpPrt;
    }
    close($fhout_guide);
				# ------------------------------
				# others in FASTA format (as list)
#********************************************************************************x.1
#   set to 1, 2 ... if you want to allow alignments with at least 2, 3, .. sequences
#********************************************************************************x.1
				# too few alis
    return(3,"*** ERROR $sbrName wrong format in seq to pir list (too few alis)!\n")
	if ( $#name < 1);
				# seq too short
    return(4,"*** ERROR $sbrName len=".length($seq{$name[1]}).
	   ", i.e. too few residues in $name[1]!\n")
	if (length($seq{$name[1]}) <= $lenMinLoc);

    return(1,"$sbrName ok");
}				# end of interpretSeqFastamul

#==============================================================================
sub interpretSeqMsf {
    local ($fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@seqIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$LfirstLine,$Lhead,
	   $Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqMsf             extracts the MSF input format
#       in:                     $fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@seqIn
#       out:                    write alignment in MSF format and guide seq in FASTA
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> chechMsfFormat returned ERROR
#       err:                    c: (3,msg) -> guide sequence not written
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqMsf";
    return(0,"*** $sbrName: not def fileOutLoc!")      if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);
				# open output files
    $fhout="FHOUT_".$sbrName;
    open("$fhout",">$fileOutLoc")  || 
	return(0,"*** $sbrName cannot open new fileOutLoc=$fileOutLoc\n");
    $Lhead=1;
    $LfirstLine=0;		# hack 2-98: add first line 'MSF of: xyz from: 1 to: 600'
    $Lguide=0;$seqGuide="";	# for extracting guide sequence

    $ctName=$LisAli=0;		# hack 98-05 to prevent only one protein
				# goebel= error if only one in MSF!!
				# ------------------------------
    foreach $_ (@seqIn){	# write MSF
	$_=~s/\n//g;
	$in=$_;
				# yet another hack around Goebel, 9-95, br
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
				# allow for 'PileUp' asf before first line
	if ($_=~/\s*MSF.*\:.*heck|\s*MSF\s*of\s*\:/){
	    $Lhead=0;}
	next if ($Lhead);	# skip all before line with 'MSF .*:'
	if    ($_=~/\sMSF\s*of\s*\:\s*.*from\s*\:\s*\d/){
	    $LfirstLine=1;}
	elsif (($_=~/\s+MSF\s*\:\s*(\d+).*[cC]heck\:/)&&! $LfirstLine){
	    $_="MSF of: yyy from: 1 to: $1\n".$_;}
	$tmp=$_;
	$tmp=~tr/[A-Z]/[a-z]/;	# and another (\t -> '  ') ; 3-96 br
	$tmp=~s/\t/   /g;	# tab to '   '
	if ($tmp=~ /name\:/i){
	    $in=~s/name\:/Name\:/;$in=~s/len\:/Len\:/;$in=~s/check\:/Check\:/;
	    ++$ctName;		# hack 98-05
				# only to extract guide sequence
	    if (!$Lguide){ $nameGuide=$in;
			   $nameGuide=~s/\s*Name\:\s*(\S+)\s.*$/$1/g;
			   $Lguide=1;}
	    $nameRemember=$in;$nameRemember=~s/$nameGuide/117REPEAT/; 
	}
	$in=~s/[\*\~\-]/\./g;	# '~' and '-' to '.' for insertions
	last if ($in=~/^[^a-zA-Z0-9\.\*\_\- \n\b\\\/]/);
				# hack 98-05: if only one repeat!!
	if    ($in=~/\/\// && $ctName==1){ # now repeat name
	    print $fhout "$nameRemember\n";}
	elsif ($LisAli && $ctName==1){ # now repeat sequence part
	    $tmp2=$_;$tmp2=~s/$nameGuide/117REPEAT/i;
	    print $fhout "$tmp2\n";}
				# end hack 98-05: if only one repeat!!

	print $fhout "$in\n";  
	print $fhout " \n" if ($LisAli && $ctName==1); # hack 98-05 security additional column

	$LisAli=1 if ($in=~/\/\//); # for hack 98-05: if only one repeat!!
				# only to extract guide sequence
	next if (! $Lguide || $in=~/name|\/\//i || $in !~/^\s*$nameGuide/i);
	$in=~s/$nameGuide//ig;
	$in=~s/\s//g;
	$seqGuide.=$in;
    }
    print $fhout "\n";
    close("$fhout");
    $#seqIn=0;			# save space
				# ------------------------------
    return(0,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);	# file existing??
				# ------------------------------
				# make a basic test of msf format
    ($Lok,$msg)=
	&msfCheckFormat($fileOutLoc);
    return(2,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") 
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    $seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//ig; # delete non amino acid characters!
    ($Lok,$msg)=
	&fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
    $seqGuide="";		# save space
    
    return(3,"*** $sbrName cannot write fasta of guide\n".
	   "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	   "*** ERROR message: $msg\n") if (! $Lok || (! -e $fileOutGuideLoc));
    return(1,"$sbrName ok");
}				# end of interpretSeqMsf

#==============================================================================
sub interpretSeqPP {
    local($fileOutLoc,$nameLoc,$charPerLine,$lenMinLoc,$lenMaxLoc,$geneLoc,@seqIn) = @_ ;
    local($sbrName,$seq,$len,$ct);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretSeqPP              suppose it is old PP format: write sequenc file
#       in:                     $fileOutLoc,$nameLoc,$charPerLine,
#       in:                     $lenMinLoc,$lenMaxLoc,$geneLoc,@seqIn
#       out:                    err:   0,msg
#       out:                    short: 2,msg
#       out:                    long:  3,msg
#       out:                    gene:  4,msg
#       out:                    ok:    1,ok
#-------------------------------------------------------------------------------
    $sbrName="interpretSeqPP";
    return(0,"*** $sbrName: not def fileOutLoc!")  if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def nameLoc!")     if (! defined $nameLoc);
    return(0,"*** $sbrName: not def lenMinLoc!")   if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def lenMaxLoc!")   if (! defined $lenMaxLoc);
    return(0,"*** $sbrName: not def geneLoc!")     if (! defined $geneLoc);
    return(0,"*** $sbrName: not def charPerLine!") if (! defined $charPerLine);
    return(0,"*** $sbrName: not def seqIn[1]!")    if (! defined $seqIn[1]) ;
				# ------------------------------
				# read sequence
    $seq="";$Lswiss=0;
    foreach $_ (@seqIn){
				# allow for SWISS-PROT files
	if ($_=~/^ID\s+[A-Z0-9]+_/){ # recognise SWISS-PROT by 'ID  PAHO_CHICK' in 1st line
	    $Lswiss=1;$Lread=0;
	    next;}
	elsif ($Lswiss && ($_=~/^SQ\s+/)){
	    $Lread=1;		# start reading after line 'SQ  SEQUENCE'
	    next;}
	next if ($Lswiss && (! $Lread));
				# ------------------------------
				# normal sequence now?
	$_=~ tr/a-z/A-Z/;	# lower case -> upper
	$_=~ s/^[\s\d]+//g;	# purge numbers and leading blanks
	$_=~ s/[\s\d]+$//g;	# purge ending numbers and ending blanks
	$_=~ s/[\s]//g;		# purge off blanks *!*
	$_=~ s/[\.]//g;		# purge dots (may be insertions)
	$_=~ s/\*$|^\*//g;	# purge leading / ending star
	last if ( /[^ABCDEFGHIKLMNPQRSTVWXYZ]/ );
	$seq.= $_; }
    $len=length($seq);
				# ******************************
    if ($len < $lenMinLoc ) {	# exit : too short
	return(2,"*** $sbrName ERROR: too short  len=$len, min=$lenMinLoc");}
				# ******************************
    if ($len > $lenMaxLoc ) {	# exit : too long
	return(3,"*** $sbrName ERROR: too long   len=$len, min=$lenMaxLoc");}
				# ******************************
				# exit : gene sequence
    $tmp=$seq; $tmp=~ s/[^ACTG]//g;
    $tmp=100*(length($tmp)/length($seq));
    if ( $tmp > $geneLoc ) {
	return(4,"*** $sbrName ERROR: too ACGT   ratio=$tmp, maxGCGT=$geneLoc");}

				# ------------------------------
				# appears fine -> write file in pir
    $fhout="FHOUT_SEQ_PP";
    open("$fhout","> $fileOutLoc") ||
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
    print $fhout ">prot (#) $nameLoc\n";
#    print STDERR "************************************\n";
#    print STDERR "---lib-pp: line 1799 fileout is $fileOutLoc\n";
    for($ct=1; $ct<=length($seq); $ct+=$charPerLine){
#	print  STDERR substr($seq,$ct,$charPerLine), "\n"; 
	print $fhout substr($seq,$ct,$charPerLine),"\n"; 
    }

#    print STDERR "************************************\n";

    
    close("$fhout");
    return(1,"$sbrName ok",$len);
}				# end of interpretSeqPP



#==============================================================================
sub interpretPdb {
    local($fileOutLoc,$nameLoc,$charPerLine,$lenMinLoc,$lenMaxLoc,$geneLoc,$dirPdb, @seqIn) = @_ ;
    local($sbrName,$seq,$len,$ct);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretPdb                write pdb to sequqnce file, currently without validatiom
#       in:                     $fileOutLoc,$nameLoc,$charPerLine,
#       in:                     $lenMinLoc,$lenMaxLoc,$geneLoc,@seqIn
#       out:                    err:   0,msg
#       out:                    short: 2,msg
#       out:                    long:  3,msg
#       out:                    gene:  4,msg
#       out:                    ok:    1,ok
#-------------------------------------------------------------------------------
    $sbrName="interpretPdb";
    return(0,"*** $sbrName: not def fileOutLoc!")  if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def nameLoc!")     if (! defined $nameLoc);
    return(0,"*** $sbrName: not def lenMinLoc!")   if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def lenMaxLoc!")   if (! defined $lenMaxLoc);
    return(0,"*** $sbrName: not def geneLoc!")     if (! defined $geneLoc);
    return(0,"*** $sbrName: not def charPerLine!") if (! defined $charPerLine);
    return(0,"*** $sbrName: not def seqIn[1]!")    if (! defined $seqIn[1]) ;
				# ------------------------------
				# read sequence
    
    # if pdb code retrieve it from the database
    if ($nameLoc =~ /code/){
	$pdbFile = pop @seqIn;
	$pdbFile .= ".pdb" if ($pdbFile !~ /.pdb$/);
	$pdbFile = $dirPdb.$pdbFile;

       	$#seqIn=0;		
	if (-e $pdbFile ){
	    open ($fh_pdbFile,$pdbFile ) ||
		return(0,"*** $sbrName could not open local pdb file system error"."$!",0);
	    @seqIn = <$fh_pdbFile>;
	    close $fh_pdbFile;
	    return(0,"No pdb content could be read please check whether your".
		   " filename is correct!",0) 
		if ( $#seqIn<0 );	
	}else{
	    return(0,"The pdb code=$pdbFile provided does not match any pdb in our database ".
		   "Please make suure that the pdb code provided is correct!",0);
	}
    }

    $seq="";$Lswiss=0;
    foreach $_ (@seqIn){
	$seq.= $_; 
	$seq.="\n"   if ($seq!~/\n$/); 
    }
    $len=length($seq);

				# ------------------------------
				# appears fine -> write file 
    $fhout="FHOUT_PDB";
    open("$fhout","> $fileOutLoc") ||
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
    #warn "---lib-pp: line 1799 fileout is $fileOutLoc\n";
    print $fhout  $seq; 
#   print STDERR "************************************\n";
    close("$fhout");
    return(1,"$sbrName ok",$len);
}				# end of interpretPdb




#==============================================================================
sub interpretText {
    local($fileOutLoc,@seqIn) = @_ ;
    local($sbrName,$seq,$len,$ct);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretPdb                write text to sequqnce, currently without validatiom
#       in:                     $fileOutLoc,$nameLoc
#       in:                     @seqIn
#       out:                    err:   0,msg
#       out:                    short: 2,msg
#       out:                    long:  3,msg
#       out:                    gene:  4,msg
#       out:                    ok:    1,ok
#-------------------------------------------------------------------------------
    $sbrName="interpretText";
    return(0,"*** $sbrName: not def fileOutLoc!")  if (! defined $fileOutLoc);
#    return(0,"*** $sbrName: not def nameLoc!")     if (! defined $nameLoc);
#    return(0,"*** $sbrName: not def lenMinLoc!")   if (! defined $lenMinLoc);
#    return(0,"*** $sbrName: not def lenMaxLoc!")   if (! defined $lenMaxLoc);
#    return(0,"*** $sbrName: not def geneLoc!")     if (! defined $geneLoc);
#    return(0,"*** $sbrName: not def charPerLine!") if (! defined $charPerLine);
    return(0,"*** $sbrName: not def seqIn[1]!")    if (! defined $seqIn[1]) ;
#    print STDOUT "$sbrName: fileOutLoc = $fileOutLoc\n";
				# ------------------------------
				# read sequence
    $seq="";
    foreach $_ (@seqIn){
	$seq.= $_; 
	$seq.="\n"   if ($seq!~/\n$/); 
    }
    $len=length($seq);
				# ------------------------------
				# appears fine -> write file 
    $fhout="FHOUT_TEXT";
    open("$fhout","> $fileOutLoc") ||
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
#   print STDERR "---lib-pp: line 1799 fileout is $fileOutLoc\n";
    print $fhout  $seq; 
#   print STDERR "************************************\n";
    close("$fhout");
    return(1,"$sbrName ok",$len);
}				# end of interpretText







#==============================================================================
sub interpretSeqPirlist {
    local ($fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,
	   $optJobLoc,@seqIn)=@_;
    local (@seq,$ct,$ctprot,$fhout_guide,$fhout_other,$sbrName,$name,@name,%seq,%name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqPirlist         extracts the PIR list input format
#       in:                     $fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn
#       out:                    writes 2 PIR files for guide and to-be-aligned
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> wrong format 
#       err:                    c: (3,msg) -> too few alis 
#       err:                    d: (4,msg) -> seq too short
#       err:                    e: (1,msg) -> ok
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqPirlist";
    return(0,"*** $sbrName: not def fileOutLocGuide!") if (! defined $fileOutLocGuide);
    return(0,"*** $sbrName: not def fileOutLocOther!") if (! defined $fileOutLocOther);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def lenMinLoc!")       if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);

    $fhout_guide="FILEPIRLIST_GUIDE";
    $fhout_other="FILEPIRLIST_OTHER";
    $ct=$#name=0; undef %seq; undef %name;
				# --------------------------------------------------
    while (@seqIn){		# first: check format by correctness of first tag 'P1;'
	$_ = shift @seqIn;
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	$_=~s/\n//g;
	$_=~tr/a-z/A-Z/; # upper case
	return(2,"*** $sbrName ERROR first tag not '>P1\;' but ($_)\n") 
	    if ($_!~ /P.?\;/ ); # wrong format
	$_=~ s/\>.*P.*\;//;
	return(2,"*** $sbrName ERROR first tag not '>P1\;' but ($_)\n") 
	    if ($_=~/\S/ );	# wrong format
	last;}
    
    $ct=1;$ctprot=0;		# --------------------------------------------------
    while(@seqIn) {		# now extract the guide sequence, and all others
	$_ = shift @seqIn;$_=~s/\n//g;
	if ($_=~/\>.*P1.*\;|\>.*p1.*\;/ ) {
	    ++$ctprot;$ct=1; $#seq=0;
	    next;}
	++$ct;
	if  ($ct==2) {		# 2nd: name (1st = tag, ignored here)
	    $_=~s/\s+/_/g;	# replace spaces by '_'
	    $_=~s/^[_\s]*|[\s_]*$//g;	# purge off leading blanks
	    $_=~s/__/_/g;	# '__' -> '_'
	    $_=~s/,//g;		# purge comma
	    $_=~s/[\(\)].*$//g; # purge '(..'
	    $_=~s/_*$//;	# purge off leading '_'
	    $name=substr($_,1,15); # extr first 15
	    if (defined $name{$name}){
		$ctTmp=1;
		while(defined $name{$name.$ctTmp}){
		    ++$ctTmp;}
		$name.=$ctTmp;}
	    $name{$name}=1;
				# security: add if name too short
	    $Ladd=0;
	    while (length($name)<5) {
		if (! $Ladd) {
		    $name.="_";
		    $Ladd=1; }
		$name.="x";}
	    $seq{$name}="";
	    push(@name,$name);}
				# sequence
	elsif ($ct> 2){
	    $_=~s/^\s(.)/$1/g;
	    $_=~s/\n//g;
	    $_=~s/\s//g;	# purge blanks
	    $_=~s/[\-_]/\./g;	# strange to dot
	    $_=~tr/[a-z]/[A-Z]/; # upper case
#	    $_=~s/\W//g;	# hidden strange
	    $_=~s/J/X/g;	# typo??
				# no amino acid?
	    last if ($_=~/[\;\=\"\(\)\:]/);
	    next if ($_=~/[^ABCDEFGHIKLMNPQRSTVWXYZ\.]/); 
	    $seq{$name}.=$_."\n"; }
    }				# end of loop over input array
				# --------------------------------------------------
				# print new file in FASTA format
				# ------------------------------
				# guide sequence in FASTA format
    open($fhout_guide,">".$fileOutLocGuide) ||
	return(0,"*** $sbrName cannot open new fileOutLocGuide=$fileOutLocGuide\n");
    $seq{$name[1]}=~s/\.|\_//g  if ($optJobLoc !~/doNotAlign/);
    print $fhout_guide ">".$name[1]."\n".$seq{$name[1]}."\n" ;
    close($fhout_guide);
				# ------------------------------
				# others in FASTA format (as list)
#********************************************************************************x.1
#   set to 1, 2 ... if you want to allow alignments with at least 2, 3, .. sequences
#********************************************************************************x.1
				# too few alis
    return(3,"*** ERROR $sbrName wrong format in seq to pir list (too few alis)!\n")
	if ( $#name < 1);
				# seq too short
    return(4,"*** ERROR $sbrName len=".length($seq{$name[1]}).
	   ", i.e. too few residues in $name[1]!\n")
	if (length($seq{$name[1]}) <= $lenMinLoc);
    

    open($fhout_other,">$fileOutLocOther") ||
	return(0,"*** ERROR $sbrName cannot open new fileOutLocOther=$fileOutLocOther\n");
    foreach $it (1..$#name){
	$seq{$name[$it]}=~s/\.|\_//g
	    if ($optJobLoc !~/doNotAlign/);
	print $fhout_other ">",$name[$it],"\n",$seq{$name[$it]};
	print $fhout_other "\n" if ($seq{$name[$it]} !~/\n$/);
    }
    close($fhout_other);
    return(1,"$sbrName ok");
}				# end of interpretSeqPirlist

#==============================================================================
sub interpretSeqPirmul {
    local ($fileOutLocGuide,$lenMinLoc,$fhErrSbr,@seqIn)=@_;
    local (@seq,$ct,$ctprot,$fhout_guide,$fhout_other,$sbrName,$name,@name,%seq,%name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqPirmul         extracts the PIR list input format
#       in:                     $fileOutLocGuide,$lenMinLoc,$fhErrSbr,@seqIn
#       out:                    writes 2 PIR files for guide and to-be-aligned
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> wrong format 
#       err:                    c: (3,msg) -> too few alis 
#       err:                    d: (4,msg) -> seq too short
#       err:                    e: (1,msg) -> ok
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqPirmul";
    return(0,"*** $sbrName: not def fileOutLocGuide!") if (! defined $fileOutLocGuide);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def lenMinLoc!")       if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);

    $fhout_guide="FILEPIRMUL_GUIDE";
    $fhout_other="FILEPIRMUL_OTHER";
    $ct=$#name=0; undef %seq; undef %name;
				# --------------------------------------------------
    while (@seqIn){		# first: check format by correctness of first tag 'P1;'
	$_ = shift @seqIn;
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	$_=~s/\n//g;$_=~tr/a-z/A-Z/; # upper case
	return(2,"*** $sbrName ERROR first tag not '>P1\;' but ($_)\n") 
	    if ($_!~ /P.?\;/ ); # wrong format
	$_=~ s/\>.*P.*\;//;
	return(2,"*** $sbrName ERROR first tag not '>P1\;' but ($_)\n") 
	    if ($_=~/\S/ );	# wrong format
	last;}
    
    $ct=1;$ctprot=0;		# --------------------------------------------------
    while(@seqIn) {		# now extract the guide sequence, and all others
	$_ = shift @seqIn;$_=~s/\n//g;
	if ($_=~/\>.*P1.*\;|\>.*p1.*\;/ ) {
	    ++$ctprot;$ct=1; $#seq=0;
	    next;}
	++$ct;
	if  ($ct==2) {		# 2nd: name (1st = tag, ignored here)
	    $_=~s/\s+/_/g;	# replace spaces by '_'
	    $_=~s/^[_\s]*|[\s_]*$//g;	# purge off leading blanks
	    $_=~s/__/_/g;	# '__' -> '_'
	    $_=~s/,//g;		# purge comma
	    $_=~s/[\(\)].*$//g; # purge '(..'
	    $_=~s/_*$//;	# purge off leading '_'
	    $name=substr($_,1,15); # extr first 15
	    if (defined $name{$name}){
		$ctTmp=1;
		while(defined $name{$name.$ctTmp}){
		    ++$ctTmp;}
		$name.=$ctTmp;}
	    $name{$name}=1;
				# security: add if name too short
	    $Ladd=0;
	    while (length($name)<5) {
		if (! $Ladd) {
		    $name.="_";
		    $Ladd=1; }
		$name.="x";}
	    $seq{$name}="";
	    push(@name,$name);}
	elsif ($ct> 2){
				# ignore strange lines (br 99-06)
	    next if ($_!~/^[\t\sABCDEFGHIKLMNPQRSTUVWXYZ\.]+$/);
	    $_=~s/^\s(.)/$1/g;
	    $_=~s/\s//g;	# purge blanks
	    $_=~s/[\-_]/\./g;	# strange to dot
	    $_=~tr/[a-z]/[A-Z]/; # upper case
	    $seq{$name}.=$_."\n" if ($_!~/[^ABCDEFGHIKLMNPQRSTVWXYZ\.]/); }
    }				# end of loop over input array
				# --------------------------------------------------
				# print new file in FASTA format
				# ------------------------------
				# all in FASTA format
    open($fhout_guide,">$fileOutLocGuide") ||
	return(0,"*** $sbrName cannot open new fileOutLocGuide=$fileOutLocGuide\n");
    foreach $it (1..$#name){
	print $fhout_guide ">",$name[$it],"\n",$seq{$name[$it]};
	print $fhout_guide "\n" if ($seq{$name[$it]} !~/\n$/);}
    close($fhout_guide);

#********************************************************************************x.1
#   set to 1, 2 ... if you want to allow alignments with at least 2, 3, .. sequences
#********************************************************************************x.1
				# too few alis
    return(3,"*** ERROR $sbrName wrong format in seq to pir list (too few alis)!\n")
	if ( $#name < 1);
				# seq too short
    return(4,"*** ERROR $sbrName len=".length($seq{$name[1]}).
	   ", i.e. too few residues in $name[1]!\n")
	if (length($seq{$name[1]}) <= $lenMinLoc);
    
    return(1,"$sbrName ok");
}				# end of interpretSeqPirmul

#==============================================================================
sub interpretSeqSaf {
    local ($fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@safIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$fhout2,$LfirstLine,$Lhead,
	   $name,$seq,$nameFirst,$lenFirstBeforeThis,
	   %nameInBlock,$ctBlocks,$line,$Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqSaf             extracts the SAF input format
#       in:                     $fileOutLoc,$fileOutGuideLoc,$fhErrSbr output file (for MSF),
#       in:                     @safInLoc=lines read from file
#       out:                    write alignment in MSF format
#       in/out GLOBAL:          $safIn{$name}=seq, @nameLoc: names (first is guide)
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written (msfWrt)
#       err:                    c: (3,msg) -> ERROR from msfCheckFormat
#       err:                    c: (4,msg) -> guide sequence not written
#       err:                    c: (5,msg) -> wrong format?
#   specification of format
#   ------------------------------
#   EACH ROW
#   ------------
#   two columns: 1. name (protein identifier, shorter than 15 characters)
#                2. one-letter sequence (any number of characters)
#                   insertions: dots (.), or hyphens (-)
#   ------------
#   EACH BLOCK
#   ------------
#   rows:        1. row must be guide sequence (i.e. always the same name,
#                   this implies, in particular, that this sequence shold
#                   not have blanks
#                2, ..., n the aligned sequences
#   comments:    *  rows beginning with a '#' will be ignored
#                *  rows containing only blanks, dots, numbers will also be ignored
#                   (in particular numbering is possible)
#   unspecified: *  order of sequences 2-n can differ between the blocks,
#                *  not all 2-n sequences have to occur in each block,
#                *  
#                *  BUT: whenever a sequence is present, it should have
#                *       dots for insertions rather than blanks
#                *  
#   ------------
#   NOTE
#   ------------
#                The 'freedom' of this format has various consequences:
#                *  identical names in different rows of the same block
#                   are not identified.  Instead, whenever this applies,
#                   the second, (third, ..) sequences are ignored.
#                   e.g.   
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                      name-1   GGAPTLPETL
#                   will be interpreted as:
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                   wheras:
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                      name_1   GGAPTLPETL
#                   has three different names.
#   ------------
#   EXAMPLE 1
#   ------------
#     t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#   ------------
#   EXAMPLE 2
#   ------------
#                         10         20         30         40         
#     t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#              50         60         70         80         90
#     t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_22  .......... .......... .......... ........
#     name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_2   .......... NVAGGAPTLP 
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqSaf";
    return(0,"*** $sbrName: not def fileOutLoc!") if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def fhErrSbr!")   if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def safIn[1]!")   if (! defined $safIn[1]);
				# ------------------------------
				# extr blocks
    $#nameLoc=0;$ctBlocks=0;undef %safIn;
    foreach $_(@safIn){
	next if ($_=~/\#/);	# ignore comments
	last if ($_!~/\#/ && $_=~/^\s*[\-\_]+\s*$/); # stop when address
	$line=$_; $line=~s/\n//g;
	$tmp=$_;$tmp=~s/[^A-Za-z]//g;

				# br 99-04b: be more restrictive again: 
				#    WRONG format if looks like FASTA!
	return(5,"ERROR in input format?\n".
	       "Did you confuse SAF-format with a FASTA-list?\n".
	       "problem: '$line' starts with '>'")
	    if ($line=~/^\s*>/);

				# br 99-04: be more restrictive: 
				#    no 'name SEQWENCE' -> ignore!
	next if ($line!~/\w[\s\t]+[A-Z]+/);
	next if (length($tmp)<1); # ignore lines with numbers, blanks, points only
	$line=~s/^\s*|\s*$//g;	# purge leading blanks

	$name=$line;$name=~s/^\s*([^\s\t]+)\s+.*$/$1/;
	$name=substr($name,1,14); # maximal length: 14 characters (because of MSF2Hssp)
	$name=~s/\-/_/g;	# '-' -> '_'
	$name=~s/\[|\]//g;	# get rid of '[' or ']'
#	$seq=$line;$seq=~s/^\s*//;$seq=~s/^$name//;$seq=~s/\s//g;
	$seq=$line;
	$seq=~s/\~/ /g;		# br 99-06: GCG uses '~' for begin and end
	$seq=~s/^\s*//;
	$seq=~s/^[^\s\t]+//;
	$seq=~s/\s//g;
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~s/\-/\./g;
	$seq=~tr/[a-z]/[A-Z]/;
# 	next if ($seq =~/^ACDEFGHIKLMNPQRSTVWXYZ/i);  # check this!!
#	print "--- interpretSeqSaf: name=$name, seq=$seq,\n";
	$nameFirst=$name if ($#nameLoc==0);	# detect first name
	if ($name eq $nameFirst){ # count blocks
	    ++$ctBlocks; undef %nameInBlock;
	    if ($ctBlocks==1){
		$lenFirstBeforeThis=0;}
	    else{
		$lenFirstBeforeThis=length($safIn{$nameFirst});}
	    &interpretSeqSafFillUp if ($ctBlocks>1);} # manage proteins that did not appear
	next if (defined $nameInBlock{$name}); # avoid identical names
	if (! defined ($safIn{$name})){
	    push(@nameLoc,$name);
#	    print "--- interpretSeqSaf: new name=$name,\n";
	    if ($ctBlocks>1){	# fill up with dots
#		print "--- interpretSeqSaf: file up for $name, with :$lenFirstBeforeThis\n";
		$safIn{$name}="." x $lenFirstBeforeThis;}
	    else{
		$safIn{$name}="";}}
	$safIn{$name}.=$seq;
	$nameInBlock{$name}=1; # avoid identical names
    } 
    &interpretSeqSafFillUp;	# fill up ends
				# store names for passing variables
    foreach $it (1..$#nameLoc){
	$safIn{$it}=$nameLoc[$it];}

				# --------------------------------------------------
				# br 99-04: further restriction of liberty
				# only one sequence and looks strange
				# --------------------------------------------------
    return(5,"ERROR in input format?\n".
	   "You want SAF format, this lead to the interpretation:\n".
	   "name=$nameLoc[1]\n".
	   "seq =".$safIn{$nameLoc[1]}."\n".
	   "seems strange!")
	if (! defined @nameLoc ||
	    ($#nameLoc==1 && 
	    (! defined $safIn{$nameLoc[1]} || $safIn{$nameLoc[1]}=~/\./)));
				# ------------------------------
				# repeat guide sequence if only
				#     one sequence in ali
    if ($#nameLoc==1) {
	$nameRepeat=$nameLoc[1];
				# shorten
	$nameRepeat=substr($nameRepeat,1,13) if (length($nameRepeat)>=14);
				# add to name
	$add="x";
	$add="y"                if (length($nameLoc[1]) >= 14 && 
				    substr($nameLoc[1],14,1) eq "x");
	$nameRepeat.=$add;
	push(@nameLoc,$nameRepeat);
	$safIn{"2"}=$nameRepeat;
	$safIn{$nameRepeat}=$safIn{$nameLoc[1]};}

				# ------------------------------
				# build up for sbr call
    $safIn{"NROWS"}=$#nameLoc;
    $safIn{"FROM"}="PP_".$nameLoc[1];
    $safIn{"TO"}=$fileOutLoc;
				# ------------------------------
				# write an MSF formatted file
    $fhout="FHOUT_MSF_FROM_SAF";
    open($fhout,">$fileOutLoc")  || # open file
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
    $Lok=
	&msfWrt("$fhout",%safIn); # write the file
    close("$fhout");
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    ($Lok,$msg)=
	&msfCheckFormat($fileOutLoc);
    return(3,$msg."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n")
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    if (defined $nameLoc[1]){
	$nameGuide=$nameLoc[1];}
    else {
	$nameGuide=$fileOutGuideLoc;$nameGuide=~s/^.*\/|\..*$//g;}
    $seqGuide=$safIn{$nameGuide};
    $seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g; # delete non amino acid characters!
    ($Lok,$msg)=
	&fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
    return(4,"*** $sbrName cannot write fasta of guide\n".
	   "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	   "*** ERROR message: $msg\n") if (! $Lok || ! -e $fileOutGuideLoc);

				# --------------------------------------------------
				# security for PP use: avoid people who sent a single
				#    sequence as SAF format
				# --------------------------------------------------
    $Lstrange=0;
    foreach $name (@nameLoc) {
	$Lstrange=1 if (length($name)==1 && $name!~/^\d$/);}

				# ------------------------------
    $#safIn=$#nameLoc=0;	# save space
	undef %safIn; undef %nameInBlock; $#nameLoc=0;

    return(2,"seems not SAF format! (is it a single sequence?)\n".
	   "reason: $sbrName assumes that if the protein name is only one character,\n".
	   "        this character is a number!\n")
	if ($Lstrange);
    return(1,"$sbrName ok");
}				# end of interpretSeqSaf

#==============================================================================
sub interpretSeqSafFillUp {
    local($tmpName,$lenLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretSeqSafFillUp       fill up with dots if sequences shorter than guide
#     all GLOBAL
#       in GLOBAL:              $safIn{$name}=seq
#                               @nameLoc: names (first is guide)
#       out GLOBAL:             $safIn{$name}
#-------------------------------------------------------------------------------
    foreach $tmpName(@nameLoc){
	if ($tmpName eq "$nameLoc[1]"){ # guide sequence
	    $lenLoc=length($safIn{"$tmpName"});
	    next;}
	$safIn{"$tmpName"}.="." x ($lenLoc-length($safIn{"$tmpName"}));
    }
}				# end of interpretSeqSafFillUp

#==========================================================================
sub is_commercial {
    local ($addr) = @_;
#--------------------------------------------------------------------------------
#   test if the address belong to a commercial user.
#   return TRUE or FALSE
#--------------------------------------------------------------------------------

				# aol, t-online
    return(0)                   if ($addr =~ /[\@\.](aol|hotmail|t-online|netscape)\.com/);
    return(0)                   if ($addr =~ /[\@\.](yahoo|compuserve|mailcity)\.com/);
    return(0)                   if ($addr =~ /[\@\.](netmail|angelfire)\.com/);

				# e.g. 'singnet.com.sg'
    return(0)                   if ($addr =~ /net\.com\.[a-z][a-z]$/);
				# .com extension
    return(1)                   if ($addr =~ /\.com$/i);

				# .co.uk|jp extension
    return(1)                   if ($addr =~ /\.co\.(uk|jp|[a-z][a-z])$/i);
    return(1)                   if ($addr =~ /\.com\.(uk|jp|[a-z][a-z])$/i);
    return(1)                   if ($addr =~ /\.mil$/i);
    return(1)                   if ($addr =~ /\.firm$/i);
    return(1)                   if ($addr =~ /\.store$/i);
    return(1)                   if ($addr =~ /\.ltd\.[a-z][a-z]$/i);
    return(1)                   if ($addr =~ /\.plc\.[a-z][a-z]$/i);
    return(1)                   if ($addr =~ /\.tm$/i);
	
    return(0);			# not comercial
}				# end is_commercial

#==========================================================================================
sub is_swissprot {
    return(&isSwiss(@_));}

#===============================================================================
sub isRunning{
    local ($process,$ps_cmd,$fhLoc) = @_;
    local ($sbrName,$ctJobs,@result);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isRunning                   test if a program runs (returns nr of occ found)
#       in:                     $process,$ps_cmd,$fhLoc
#       out:                    number of jobs running
#-------------------------------------------------------------------------------
    $sbrName="isRunning";
    return(0,"*** $sbrName: no process given!")    if (! defined $process);
    return(0,"*** $sbrName: no ps_comand given!")  if (! defined $ps_cmd) ;
    
    $process=~s/nice\s*\d+\s*//g; # no nice
    $process=~s/^.*\///;	  # remove path
    if (defined $fhLoc){
	print $fhLoc "ps=$ps_cmd "."|"." grep $process "."|"." grep -v 'grep'\n";}
				# run a ps command
    @result= `$ps_cmd | grep $process | grep -v 'grep' `;
#    @result= `$ps_cmd | grep $process | grep -v 'grep' | grep -v '$process\.\.'`;

    $ctJobs=$#result;
    print "lib-pp:$sbrName: #result=$ctJobs\n";

    return (1,$ctJobs);		# return the number of processes found 
}				# end of isRunning

#===============================================================================
sub license_updateCounts {
    local($fileGivenLoc,$fileCountLoc,$fileCountFlag,$userEmailLoc,$passwordLoc,$dateLoc) = @_ ;
    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   license_updateCounts        reads counts done, and adds one
#       in:                     $fileGivenLoc=   /home/$ENV{USER}/server/log/licenseGiven.rdb
#       in:                     $fileCountLoc=   /home/$ENV{USER}/server/log/licenseCount.rdb
#       in:                     $fileCountFlag=  /home/$ENV{USER}/server/log/FLAG_writes_licenseCount
#       in:                     $userLoc=        user email
#       in:                     $passwordLoc=    user password (\c\d\d\d\c)
#       in:                     $dateLoc=        day-month-year (year=\d\d\d\d)
#       out:                    (1|0,$msg,$LlicenseOk)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-pp::license_updateCounts";
    $fhinLoc="FHIN_"."license_updateCounts";$fhoutLoc="FHOUT_"."license_updateCounts";
				# check arguments
    return(0,"*** ERROR $sbrName: not def fileGivenLoc!")  if (! defined $fileGivenLoc);
    return(0,"*** ERROR $sbrName: not def fileCountLoc!")  if (! defined $fileCountLoc);
    return(0,"*** ERROR $sbrName: not def fileCountFlag!") if (! defined $fileCountFlag);
    return(0,"*** ERROR $sbrName: not def userEmailLoc!")  if (! defined $userEmailLoc);
    return(0,"*** ERROR $sbrName: not def passordLoc!")    if (! defined $passwordLoc);
    return(0,"*** ERROR $sbrName: not def dateLoc!")       if (! defined $dateLoc);
    return(0,"*** ERROR $sbrName: no fileIn=$fileInLoc!")  if (! -e $fileGivenLoc &&
							      ! -l $fileGivenLoc);
				# ini time out
    $numCycles2wait=10;
    $sleepTime=     10;
				# massage password
    $passwordLoc=~s/\s//g;
				# massage date
    $tmp=  $dateLoc;            # assumed 'May 13, 1999'
    $month=$tmp; $month=~s/^([a-z]+)\s+.*$/$1/i; $month=~tr/[A-Z]/[a-z]/;
    $day=  $tmp; $day=~s/^[a-z]+\s+(\d+)\,.*$/$1/i; 
    $year= $tmp; $year=~s/^[a-z]+\s+\d+\,\s*(\d+).*$/$1/i;
    $monthNum=&date_monthName2num($month);
    $dateNow=$day."-".$monthNum."-".$year;

				# --------------------------------------------------
				# check number of counts done
    ($Lok,$msg,$LalreadyIn,$LoverCount,$LoverTime,$lineRead,$numDone)=
	&license_updateGetCounts($fileCountLoc,$passwordLoc,$dateNow);
				# --------------------------------------------------
				# CASE: internal ERROR -> let them
    return(0,
	   "*** ERROR in $sbrName:license_updateGetCounts($fileGivenLoc,$passwordLoc,$dateNow)\n".
	   "*** returned message=$msg",
	   1)                   if (! $Lok);

				# --------------------------------------------------
				# CASE: not in count list, yet -> license_update
    if (! $LalreadyIn) {
	($Lok,$msg,$LlicenseOk)=
	    &license_updateNewLicense($fileGivenLoc,$fileCountLoc,$fileCountFlag,
				      $userEmailLoc,$passwordLoc,
				      $numCycles2wait,$sleepTime);
				# internal ERROR -> let them
	return(0,$msg,1)        if (! $Lok);
				# missing license -> DO NOT let them
	return(0,$msg,0)        if (! $LlicenseOk);
	return(1,"ok",1);}
				# --------------------------------------------------
				# CASE: over time or count -> do NOT let them
    return(0,
	   $msg,		# Explanation written by subroutine
	   0)                   if ($LoverCount || $LoverTime);

				# --------------------------------------------------
				# CASE: ok -> count up and add to file

				# ------------------------------
				# read license count file
    open($fhinLoc,$fileCountLoc) || 
	return(0,"*** ERROR $sbrName: fileCountLoc=$fileCountLoc, not opened");
    $#rd=0;
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	if ($_=~/^\#/ ||	# comments or other users
	    $_ ne $lineRead) {
	    push(@rd,$_);
	    next; }
				# this user
	$numNew=$numDone+1;
	$lineNew=$lineRead;
	$lineNew=~s/(^\w+[\s\t]+\d+)[\s\t]+$numDone/$1\t$numNew/;
	push(@rd,$lineNew);}
    close($fhinLoc);
				# ------------------------------
				# write new license count
				# WATCH whether someone is writing
				# ------------------------------
    $ct=0;
    while (-e $fileCountFlag && $ct < $numCycles2wait) {
	sleep($sleepTime);
	++$ct; }

    if (! -e $fileCountFlag) {
	system("echo $dateLoc > $fileCountFlag");}
    else {
	$msg="*** WARN $sbrName: trouble could never update fileLicenseCount=$fileCountLoc,\n".
	    "***      since someone writes to flag=$fileCountFlag!\n";
	print $msg;
				# internal error -> let them!
	return(0,$msg,1); }

    open($fhoutLoc,">".$fileCountLoc) || 
	return(0,"*** ERROR $sbrName: fileCount out=$fileCountLoc, not opened");
    foreach $tmp (@rd) {
	print $fhoutLoc $tmp,"\n";
    }
    close($fhoutLoc);
				# delete flag
    unlink($fileCountFlag);
    return(1,"ok",1);		# everything fine

}				# end of license_updateCounts

#===============================================================================
sub license_updateGetCounts {
    local($fileInLoc,$passwordLoc,$dateLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   license_updateGetCounts     finds out from file with counts (licenseCounts.rdb),
#                               how many jobs the user with $password has done so far,
#                               and whether or not that was within the time period..
#       in:                     $fileInLoc=   /home/$ENV{USER}/server/log/licenseCounts.rdb
#       in:                     $passwordLoc= user password (\c\d\d\d\c)
#       in:                     $dateLoc=     day-month-year (year=\d\d\d\d)
#       out:                    (1|0,msg,$LalreadyIn(<1|0>),
#                                        $overCount(<1|0>),$overTime(<1|0>),$line,$numDone)
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-pp::license_updateGetCounts";
    $fhinLoc="FHIN_"."license_updateGetCounts";$fhoutLoc="FHOUT_"."license_updateGetCounts";
				# check arguments
    return(0,"*** ERROR $sbrName: not def fileInLoc!")    if (! defined $fileInLoc);
    return(0,"*** ERROR $sbrName: not def passordLoc!")   if (! defined $passwordLoc);
    return(0,"*** ERROR $sbrName: not def dateLoc!")      if (! defined $dateLoc);
    return(0,"*** ERROR $sbrName: no fileIn=$fileInLoc!") if (! -e $fileInLoc &&
							      ! -l $fileInLoc);
    return(0,"*** ERROR $sbrName: date should be 'dd-dd-dddd', is=$dateLoc!")
	if ($dateLoc !~ /\d\d*\-\d\d*\-\d\d\d\d/);
				# massage password
    $passwordLoc=~s/\s//g;
				# open file
    open($fhinLoc,$fileInLoc) || 
	return(0,"*** ERROR $sbrName: fileInLoc=$fileInLoc, not opened");
    $line=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	next if ($_!~/^$passwordLoc/);
	$line=$_; $line=~s/\n//g;
	last; }
    close($fhinLoc);
				# ------------------------------
				# none found
    return(1,"ok",0,0,0,0,0)    if (! $line);
				# ------------------------------
				# digest line
#passw	Ngiven	Ndone	start_date	end_date	company (separe fields with tab) 
    ($tmp,$numGiven,$numDone,$tmp,$end,@tmp)=
	split(/[\s\t]+/,$line);
				# ------------------------------
				# check number of counts
    return(1,"Your license has expired, since you saturated your quota of requests.\n".
	     "given=$numGiven, done=$numDone!",
	   1,1,0,$line,$numDone)
	if ($numDone >= $numGiven);
				# ------------------------------
				# check date
    ($tmp,$month_end,$year_end)= split(/\-/,$end);
    ($tmp,$month_now,$year_now)= split(/\-/,$dateLoc);
    $month_now=~s/^0//g; $month_end=~s/^0//g;
    return(1,"Your license has expired, since its ending date was $end.\n",
	   1,0,1,$line,$numDone)
	if (($year_now > $year_end) ||
	    (($month_now > $month_end) && ($year_now==$year_end)));
				# ------------------------------
				# all ok
    return(1,"ok",1,0,0,$line,$numDone);
}				# end of license_updateGetCounts

#===============================================================================
sub license_updateNewLicense {
    local($fileGivenLoc,$fileCountLoc,$fileCountFlag,$userEmailLoc,$passwordLoc,
	  $numCycles2wait,$sleepTime) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   license_updateNewLicense    license_updates the file 
#                                  /home/$ENV{USER}/server/log/licenseCount.rdb
#                               for new users which appear in:
#                                  /home/$ENV{USER}/server/log/licenseGiven.rdb
#       in:                     $fileGivenLoc=   /home/$ENV{USER}/server/log/licenseGiven.rdb
#       in:                     $fileCountLoc=   /home/$ENV{USER}/server/log/licenseCount.rdb
#       in:                     $fileCountFlag=  /home/$ENV{USER}/server/log/FLAG_writes_licenseCount
#       in:                     $userLoc=        user email
#       in:                     $passwordLoc=    user password (\c\d\d\d\c)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-pp::license_updateNewLicense";
    $fhinLoc="FHIN_"."license_updateNewLicense";$fhoutLoc="FHOUT_"."license_updateNewLicense";
				# check arguments
    return(0,"*** ERROR $sbrName: not def fileGivenLoc!")  if (! defined $fileGivenLoc);
    return(0,"*** ERROR $sbrName: not def fileCountLoc!")  if (! defined $fileCountLoc);
    return(0,"*** ERROR $sbrName: not def fileCountFlag!") if (! defined $fileCountFlag);
    return(0,"*** ERROR $sbrName: not def userEmailLoc!")  if (! defined $userEmailLoc);
    return(0,"*** ERROR $sbrName: not def passordLoc!")    if (! defined $passwordLoc);
    $numCycles2wait=10                                     if (! defined $numCycles2wait);
    $sleepTime=10                                          if (! defined $sleepTime);

				# open file
    open($fhinLoc,$fileGivenLoc) || 
	return(0,"*** ERROR $sbrName: fileGivenLoc=$fileGivenLoc, not opened");

    $line=$passwordCorrect=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	if ($_=~/^$passwordLoc/) {
	    $line=$_; $line=~s/\n//g;
	    last; }
	if ($_=~/$userEmailLoc/) {
	    $passwordCorrect=$_; $passwordCorrect=~s/^(\S+)[\s\t]+.*$/$1/;
	    last; }}
    close($fhinLoc);
				# ------------------------------
				# none found -> DO NOT let them
    return(1,"Your license could NOT be verified (reason: wrong password=$passwordLoc)!",
	   0)                   if ($passwordCorrect);
    return(1,"Your license could NOT be verified (password used=$passwordLoc)!",
	   0)                   if (! $line);

				# new line to add to count file
    @tmp=split(/[\s\t]+/,$line);
    $lineNew= $tmp[1];		# password
    $lineNew.="\t".$tmp[2];	# number allowed
    $lineNew.="\t"."1";		# number done (this is first)
    $lineNew.="\t".$tmp[3];	# start date (\d\d-\d\d-\d\d\d\d)
    $lineNew.="\t".$tmp[4];	# end date (\d\d-\d\d-\d\d\d\d)
    $lineNew.="\t";
    foreach $it (5..$#tmp) {	# other stuff
	$lineNew.=" ".$tmp[$it];
    }
				# ------------------------------
				# write new license count
				# WATCH whether someone is writing
				# ------------------------------
    $ct=0;
    while (-e $fileCountFlag && $ct < $numCycles2wait) {
	sleep($sleepTime);
	++$ct; }

    if (! -e $fileCountFlag) {
	system("echo $dateLoc > $fileCountFlag");}
    else {
	$msg="*** WARN $sbrName: trouble could never license_update fileLicenseCount=$fileCountLoc,\n".
	    "***      since someone writes to flag=$fileCountFlag!\n";
	print $msg;
				# internal error -> let them!
	return(0,$msg,1); }

				# ------------------------------
				# append to count file
    open($fhoutLoc,">>".$fileCountLoc) ||
	return(0,"*** ERROR $sbrName: fileCount out=$fileCountLoc, not opened");
    print $fhoutLoc $lineNew,"\n";
    close($fhoutLoc);
				# delete flag
    unlink($fileCountFlag);
    return(1,"ok",1);
}				# end of license_updateNewLicense

#===============================================================================
sub mviewRun {
    local($fileInLoc,$formatInLoc,$chainInLoc,
	  $exeMviewLoc,$parStandardLoc,$fileOutLoc,$optOutLoc,$fhoutSbr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   mviewRun                    runs MView (Nigel Brown) on an alignment
#            COPYRIGHT          Nigel Brown
#            QUOTE              N P Brown, C Leroy, C Sander (1998), Bioinformatics. 14(4):380-381
#                               (MView: A Web compatible database search or multiple alignment viewer)
#       in:                     $fileInLoc=       file with alignment (format recognised by extension)
#       in:                     $formatInLoc=     <hssp|msf|blast>
#       in:                     $chainInLoc=      chain for HSSP format (otherwise=0)
#                                  =' '           not used
#       in:                     $exeMview=        executable (perl)
#       in:                     $paraStandard=    standard parameters
#                                   =0            for standard setting
#       in:                     $fileOut=         name of output file
#                                  =0             -> will name it
#       in:                     $optOut=          HTML option <body|data|title>
#                                  =0             full HTML page
#       in:                     $fhoutSbr=        file handle to write system call
#                                  =0             no output reported
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."mviewRun";
    $fhinLoc="FHIN_"."mviewRun";$fhoutLoc="FHOUT_"."mviewRun";
    $errMsg="*** ERROR in arg for $sbrName: ";
				# check arguments
    return(0,$errMsg."not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,$errMsg."not def formatInLoc!")        if (! defined $formatInLoc);
    return(0,$errMsg."not def chainInLoc!")         if (! defined $chainInLoc);
    return(0,$errMsg."not def exeMviewLoc!")        if (! defined $exeMviewLoc);
    return(0,$errMsg."not def parStandard!")        if (! defined $parStandardLoc);
    return(0,$errMsg."not def fileOut!")            if (! defined $fileOutLoc);
    $optOut=0                                       if (! defined $optOutLoc);
    $fhoutSbr=0                                     if (! defined $fhoutSbr);
#    return(0,$errMsg."not def !")          if (! defined $);

    return(0,$errMsg."no fileIn=$fileInLoc!")       if (! -e $fileInLoc);
    return(0,$errMsg."no fileIn=$exeMviewLoc!")     if (! -e $exeMviewLoc && !-l $exeMviewLoc);

				# local defaults
    if (! $parStandardLoc) {
	$parStandardLoc= "-css on -srs on";
	$parStandardLoc.=" -html head -ruler on";
	$parStandardLoc.=" -coloring consensus -threshold 50 -consensus on -con_coloring any";}

    $cmd= $exeMviewLoc." ".$parStandardLoc." ";

				# ------------------------------
				# HSSP input
    if    ($formatInLoc=~/hssp/) {
	$cmd.=" -in hssp"; 
	$cmd.=" -chain $chainInLoc"
	    if (defined $chainInLoc && $chainInLoc =~ /^[0-9A-Z]$/); }
				# MSF input
    elsif ($formatInLoc=~/msf/) {
	$cmd.=" -in msf"; }
				# BLAST input
    elsif ($formatInLoc=~/blast/) {
	$cmd.=" -in blast"; }
				# unk input format
    else {
	return(0,"*** WARN $scrName: skipped $fileInLoc, since format ($formatInLoc) unk\n"); }

				# ------------------------------
				# output
    if (! $fileOutLoc) {
	$fileOutLoc=$fileInLoc; 
				# purge dirs for data bases asf
	$fileOutLoc=~s/^.*\///g if (! -w $fileInLoc);

	$fileOutLoc=~s/\.(hssp|msf).*$//g;
	$fileOutLoc.=".html_mview"; }
				# security 1: same as input?
    $fileOut="mview_of".$fileInLoc.".html" if ($fileOutLoc eq $fileInLoc);
				# security 2: delete if exists
    if (-e $fileOutLoc) { 
	print "-*- WARN $sbrName deletes file $fileOutLoc\n";
	unlink($fileOutLoc); }
				# full HTML page?
    $cmd.=" -html $optOutLoc"
	if ($optOut);
				# finally add input file
    $cmd.=" ".$fileInLoc;
				# past into output file!
    $cmd.=" >> ".$fileOutLoc;

				# ------------------------------
				# run program
    ($Lok,$msg)=
	&sysSystem("$cmd",$fhoutSbr);

    return(0,"*** ERROR $scrName: failed on mview (from $fileInLoc):\n".$msg."\n")
	if (! $Lok);
		  
    return(1,$fileOutLoc);
}				# end of mviewRun

#===============================================================================
sub sendMailAlarm {
    local($messageLoc,$userLoc,$exe_mailLoc) = @_ ;
    local($sbrName,$tmp,$Lok,$dateLoc,@dateLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sendMailAlarm               sends alarm mail to user
#       in:                     $message, $user, $exe_mail
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="sendMailAlarm";
    return(0,"*** $sbrName: not def messageLoc!")            if (! defined $messageLoc);
    return(0,"*** $sbrName: not def userLoc!")               if (! defined $userLoc);
    return(0,"*** $sbrName: not def exe_mailLoc!")           if (! defined $exe_mailLoc);
    return(0,"*** $sbrName: missing exe_mail=$exe_mailLoc!") if (! -e $exe_mailLoc);

    $dateLoc=&sysDate();

    $message=  "\n"."*** $dateLoc\n"."*** from sendMailAlarm (lib-x.pl)\n"."***$message\n";
    system("echo '$messageLoc' | $exe_mailLoc -s PP_ERROR $userLoc");
    return(1,"ok $sbrName");
}				# end of sendMailAlarm

#===============================================================================
sub userAllowed {
    local($userLoc,$passwordLoc,$dateLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   userAllowed                 checks whether or not user is commercial
#                               and if so whether or not has valid license
#       in:                     $userLoc=     email address of user
#       in:                     $passwordLoc= user password (\c\d\d\d\c)
#       in:                     $dateLoc=     May 13, 1999
#       out:                    (1|0,msg,$LisCommercial(<1|0>),$LisOk(<1|0>))
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-pp::userAllowed";
    $fhinLoc="FHIN_"."userAllowed";$fhoutLoc="FHOUT_"."userAllowed";
				# check arguments
    return(0,"*** ERROR $sbrName: not def userLoc!")       if (! defined $userLoc);
    return(0,"*** ERROR $sbrName: not def passwordLoc!")   if (! defined $passwordLoc);
    $dateLoc=&sysDate()                                    if (! defined $dateLoc);
				# massage email and password
    $userLoc=~s/\s//g; 
    $passwordLoc=~s/\s//g;
    $logMessage=$userLoc."\t".$passwordLoc;

				# --------------------------------------------------
				# user NOT commercial -> all ok
    if (! &is_commercial($userLoc)) {
				# log the user for checks
	system("echo $logMessage >> ".$envPP{"file_licenceNotLog"});
	return(1,"ok",0,1); }
				# --------------------------------------------------
				# does user have a licence?
				# --------------------------------------------------
    if ($passwordLoc ne $envPP{"password_def"}) {
	($Lok,$msg,$LlicenseOk)=
	    &license_updateCounts($envPP{"file_licenceGiven"},$envPP{"file_licenceCount"},
				  $envPP{"flag_licenceCount"},
				  $userLoc,$passwordLoc,$dateLoc);
	return(0,$msg,1,1)      if (! $Lok); }

    if ($LlicenseOk) {
				# log the user for checks
	$logMessage.="\t"."ok";
	system("echo $logMessage >> ".$envPP{"file_licenceComLog"});
	return(1,"valid license",1,1);}

				# --------------------------------------------------
				# answer is: user does NOT have valid license
				# --------------------------------------------------
				# has they already tried?
    if (-e $envPP{"file_badGuy"}) {
	$cmd="grep '$userLoc' ".$envPP{"file_badGuy"};
	$tmp=`$cmd`; }
    else {
	$tmp="";}

    $count_badGuy=0;
				# new bad guy
    if (! defined $tmp || length($tmp)<2) {
	$lineNew=$userLoc."\t"."1";}
    else {
	$tmp=~s/\n//g;
	$tmp=~s/^[^\s\t]+[\s\t]+(\d+).*$/$1/;
	if (defined $tmp) {
	    $tmp=~s/\D//g;
	    if (length($tmp)<1) {
		$lineNew=$userLoc."\t"."1";}
	    else {
		++$tmp;
		$count_badGuy=$tmp;
		$lineNew=$userLoc."\t".$tmp;}}
	else {
	    $lineNew=$userLoc."\t"."1";}}
				# ------------------------------
				# too many of the one?
    return(1,"no valid license",1,0)
	if ($count_badGuy > $envPP{"par_num4badGuy"});

				# ------------------------------
				# add to bad guy file
				# WATCH whether someone is writing
				# ------------------------------
    $ct=0;
    while (-e $envPP{"flag_badGuy"} && $ct < $numCycles2wait) {
	sleep($sleepTime);
	++$ct; }

    if (! -e $envPP{"flag_badGuy"}) {
	system("echo $dateLoc > ".$envPP{"flag_badGuy"});}
    else {
	$msg="*** WARN $sbrName: trouble could never update file_badGuy=".
	    $envPP{"file_badGuy"}.",\n".
		"***      since someone writes to flag=".$envPP{"flag_badGuy"}."!\n";
	print $msg;
				# internal error -> let them!
	$logMessage.="\t"."not (but internal error flag=".
	    $envPP{"flag_badGuy"}.", not deleted!";
	system("echo $logMessage >> ".$envPP{"file_licenceComLog"});
	return(0,$msg,1,1); }

    $logMessage.="\t"."not ";
    system("echo $logMessage >> ".$envPP{"file_licenceComLog"});
    
    
				# ------------------------------
				# append to count file if new
    if ($Lnew_badGuy) {
	open($fhoutLoc,">>".$envPP{"file_badGuy"}) ||
				# internal error: let them
	    return(0,
		   "*** ERROR $sbrName: file_badGuy=".$envPP{"file_badGuy"}.", not appended",
		   1,1);
	print $fhoutLoc $lineNew;
	close($fhoutLoc);
				# delete flag
	unlink($envPP{"flag_badGuy"});}
				# ------------------------------
				# old bad guy
    else {
	$#rd=0;
				# (1) read
	if (-e $envPP{"file_badGuy"}) {
	    open($fhinLoc,$envPP{"file_badGuy"}) ||
		do { unlink($envPP{"flag_badGuy"});
				# internal error: let them
		     return(0,
			    "*** ERROR $sbrName: fileBadGuy in=".
			    $envPP{"file_badGuy"}.", not opened",
			    1,1);};
		       
	    while (<$fhinLoc>) {	# read file
		$_=~s/\n//g;
		if ($_=~/$userLoc/) {
		    push(@rd,$lineNew);}
		else {
		    push(@rd,$_);}}
	    close($fhinLoc); }
	else {
	    push(@rd,$lineNew);}
	    
				# (2) write
	open($fhoutLoc,">".$envPP{"file_badGuy"}) ||
				# internal error: let them
	    do { unlink($envPP{"flag_badGuy"});
		 return(0,
			"*** ERROR $sbrName: file_badGuy=".$envPP{"file_badGuy"}.", not appended",
			1,1);};
	foreach $line (@rd) {
	    print $fhoutLoc $line,"\n";}
	close($fhoutLoc);
				# delete flag
	unlink($envPP{"flag_badGuy"});}
				# delete flag
    return(1,"bad but less than n=".$envPP{"par_num4badGuy"},1,1);
}				# end of userAllowed





#===============================================================================
sub checkExistResult{
    local($fileResult) = shift;
    local($sbrName,$fhinLoc,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   checkExistResult            checks to see if there's already a cached result
#                                                                          
#       in:                     $fileResult=    file to check if exists from cache
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-pp::checkExistResult";
    $fhinLoc="FHIN_"."checkExistResult";$fhoutLoc="FHOUT_"."checkExistResult";

    if (-e $fileResult){
	return (1);		
#	return (1,"$sbrName fileResult=$fileResult retrieved from cache" );		
    }
    return (0);
#    return(0,"$sbrName ok");
}				# end of checkExistResult




#===============================================================================
sub extrChain{
    local($fileInPdb, $fileOutPdb, $chain) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   extrChain                   extracts a chain from a pdb file        
#                                                                          
#       in:                     $fileInPdb=     pdb to extract chain
#       in:                     $fileOutPdb     output file with a single chain
#       in:                     $chain          chain to be extracted
#                                               if not provided defualt is space
#       out:                                                                 
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------

    $sbrName="lib-pp::extrChain";
    $fhinLoc="FHIN_"."extrChain";$fhoutLoc="FHOUT_"."extrChain";
				# check arguments
    return(0,"*** ERROR $sbrName: not def fileInLoc!")    if (! defined $fileInPdb);
    return(0,"*** ERROR $sbrName: not def passordLoc!")   if (! defined $fileOutPdb );
    $chain = " "                                          if (! defined $chain   );
    $tout = $fileOutPdb;
    open ($fhoutLoc,">$tout");
    $swc=0;$prevc="";  
    $cmd = "cat ".$fileInPdb;
    foreach $p (`$cmd `){
	if (($p=~/^HEADER/) or ($p=~/^TITLE/)or ($p=~/^COMPND/)){print  $fhoutLoc $p}
	if ($p=~/^ATOM/){

	    $c=substr($p,22,1);
	    next if ((($chain=~/[a-z]/) && ($c=~/[A-Z]/))||(($chain=~/[a-z]/) && ($c=~/[A-Z]/)));	    
	    if (($c ne $prevc) and ($prevc eq $chain)){$swc++;}
	    if ($swc==2){print  $fhoutLoc "TER\nEND";print "$p getting out\n";last}
	    $prevc=$c;
	    if ($c eq $chain){print $fhoutLoc $p}
	}
	if (($p=~/^TER/) and ($prevc eq $chain)){  print  $fhoutLoc $p; last;}
	
    }
    close $fhoutLoc;		
}

#===============================================================================
sub getHtmlBval{
    local ($fileInProfBval, $fileInHeading) = @_;
    $[ =0 ;
#-------------------------------------------------------------------------------
#   extrChain                   creates nice html table for profbval results
#                                                                          
#       in:                     $fileInProfBval=     profbval results
#       out:                    $profBvalHtm=        html output file with table
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------

    $fhErrSbr="STDOUT"                        if (! defined $fhErrSbr);
    open (FI,$fileInProfBval) || return(0, "fileIn=$fielInProfBval error:$!\n");

    $x=0;
    @t=('','','','acc','','strict','reliability');
    $str ="<table border='0' cellpadding='10' cellspacing='4'>";
    while (<FI>){
	if (length($_) > 1){
	    @l = split /\t/,$_; 
	    if ($x>0){
		if ($l[0] eq 'y'){
		    $class = "bval-2";
#		    $bg = "#0000ff";
#		    $font = "white";
		}else{
		    $class = "bval-1";
#		    $bg = "cccccc";
#		    $font = "black";
		}
		$str .="<tr>\n";	
		for ($i=1; $i< scalar(@l); $i++){
		    $str .="<TD width='20%' class=\"$class\">\n";
#		    $str .= "<font color='$font' <font face='Verdana, Arial, Helvetica, sans-serif'>\n";	
		    $str .= "$l[$i]";
#		    $str .= "</font>\n";	
		    $str .= "</TD>\n";  
		}
		
		$str .= "</tr>\n";	
		
	    }else{
		$str .= "<tr>\n";
		for ($i=1; $i< scalar(@l); $i++){
		    $str .= "<th align='left' width='20%'><font face='Verdana, Arial, Helvetica, sans-serif'><a href=\"\#$t[$i]\">$l[$i]</a></font></th>\n";
		}			 
		$str .= "</tr>\n";	    			
	    }			

	}
	$x++;
    }			      
    close FI;
    $str .="</table>\n";

    $fileOutProfBvalHtm = "$fileInProfBval.html";
    $cmd = "cat $fileInHeading > $fileOutProfBvalHtm";
    ($Lok,$msg)= &sysSystem("$cmd",$fhoutSbr);    


    open (FO,">>$fileOutProfBvalHtm")|| return(0, "fileOut=$fileOutProfBvalHtm error:$!\n");
    print FO $str;
    close (FO);			

    return (1,$fileOutProfBvalHtm);
}
1;				# must return true

