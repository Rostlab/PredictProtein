#!/usr/bin/perl
##! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Sep,    	1998	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with routines related to manipulating files.                 #
#    NOTE: also all format checkers (isHssp) are here!                         #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   file                        internal subroutines:
#                               ---------------------
# 
#   fileListArrayRd             returns array of HSSP files
#   fileListRd                  reads a list of files
#   fileListWrt                 writes a list of files
#   form_perl2rdb               converts printf perl (d,f,s) into RDB format (N,F, ) 
#   form_rdb2perl               1
#   htmlWrtHead                 writes header of HTML file
#   is_dssp                     checks whether or not file is in DSSP format
#   is_dssp_list                checks whether or not file is a list of DSSP files
#   is_fssp                     checks whether or not file is in FSSP format
#   is_fssp_list                1
#   is_hssp                     checks whether or not file is in HSSP format
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#   is_list                     returns 1 if list of existing files
#   is_nndb_rdb                 
#   is_nninFor                  is input for FORTRAN input
#   is_ppcol                    checks whether or not file is in RDB format
#   is_rdb_acc                  checks whether or not file is in RDB format from PHDacc
#   is_rdb_htm                  checks whether or not file is in RDB format from PHDhtm
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#   is_rdb_nnDb                 checks whether or not file is in RDB format for NN.pl
#   is_rdb_sec                  checks whether or not file is RDB from PHDsec
#   is_strip                    checks whether or not file is in HSSP-strip format
#   is_strip_list               checks whether or not file contains a list of HSSPstrip files
#   is_strip_old                checks whether file is old strip format
#   is_swissprot                
#   isDaf                       checks whether or not file is in DAF format
#   isDafGeneral                checks (and finds) DAF files
#   isDafList                   checks whether or not file is list of Daf files
#   isDsspGeneral               checks (and finds) DSSP files
#   isFasta                     checks whether or not file is in FASTA format 
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#   isFsspGeneral               checks (and finds) FSSP files
#   isGcg                       checks whether or not file is in Gcg format (/# SAF/)
#   isGcgArray                  checks whether or not file is in Gcg format (/# SAF/)
#   isHelp                      returns 1 if : help,man,-h
#   isHsspGeneral               checks (and finds) HSSP files
#   isMsf                       checks whether or not file is in MSF format
#   isMsfGeneral                checks (and finds) MSF files
#   isMsfList                   checks whether or not file is list of Msf files
#   isPdb                       checks whether or not file is PDB format
#   isPhdAcc                    checks whether or not file is in PHD.rdb_acc format
#   isPhdBoth                   checks whether or not file is in PHD.rdb format 
#   isPhdHtm                    checks whether or not file is in PHD.rdb_htm format
#   isPhdSec                    checks whether or not file is in PHD.rdb_sec format
#   isPir                       checks whether or not file is in Pir format 
#   isPirMul                    checks whether or not file contains many sequences 
#   isRdb                       checks whether or not file is in RDB format
#   isRdbGeneral                checks (and finds) RDB files
#   isRdbList                   checks whether or not file is list of Rdb files
#   isSaf                       checks whether or not file is in SAF format (/# SAF/)
#   isSwiss                     checks whether or not file is in SWISS-PROT format (/^ID   /)
#   isSwissGeneral              checks (and finds) SWISS files
#   isSwissList                 checks whether or not file is list of Swiss files
#   getFileFromArray            finds the file associated to 'keyword' from the
#   open_file                   opens file, writes warning asf
#   rd_col_associative          reads the content of a comma separated file
#   rd_rdb_associative          reads the content of an RDB file into an associative
#   rdb2html                    convert an RDB file to HTML
#   rdbGenWrtHdr                writes a general header for an RDB file
#   rdRdbAssociative            reads content of an RDB file into associative array
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#   read_rdb_num                reads from a file of Michael RDB format:
#   read_rdb_num2               reads from a file of Michael RDB format:
#   wrtRdb2HtmlHeader           write the HTML header
#   wrtRdb2HtmlBody             writes the body for a RDB->HTML file
#   wrtRdb2HtmlBodyColNames     writes the column names (called by previous)
#   wrtRdb2HtmlBodyAve          inserts a break in the table for the averages at end of
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   file                        external subroutines:
#                               ---------------------
# 
#   call from file:             isDaf,isDafList,isMsf,isMsfList,isRdb,isRdbList,isSwiss
#                               isSwissList,is_dssp,is_dssp_list,is_fssp,is_fssp_list
#                               is_hssp,is_hssp_empty,is_hssp_list,is_strip,open_file
#                               rdRdbAssociativeNum,read_rdb_num2,wrtRdb2HtmlBody,wrtRdb2HtmlBodyAve
#                               wrtRdb2HtmlBodyColNames,wrtRdb2HtmlHeader
# 
#   call from formats:          dsspGetFile,dsspGetFileLoop,fsspGetFile,fsspGetFileLoop
#                               swissGetFile
# 
#   call from hssp:             hsspGetChain,hsspGetFile,hsspGetFileLoop
# 
#   call from scr:              errSbr
# 

#===============================================================================
sub fileListArrayRd {
    local($listFileInLoc,$extDbFileLoc,$extChainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListArrayRd             returns array of HSSP files
#       in:                     $extDbfile=     expected file extension (.hssp)
#                                  note:        necessary to purge chains!
#       in:                     $extChain=      expected chain extension (e.g. '_')
#       in:                     $listFileInLoc= list of files, e.g.:
#                                  '1ppt.hssp,list-of-hssp.files,1cse.hssp_E'
#       out:                    1|0,msg,$file(f1,f2,f3,..,),$chain(c1,c2,c3)
#                                  note:        chain '*' for no given chain
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListArrayRd";$fhinLoc="FHIN_"."fileListArrayRd";
				# check arguments
    return(0,"*** $sbrName: not def listFileInLoc!",0)  if (! defined $listFileInLoc);
    return(0,"*** $sbrName: not def extDbFileLoc!",0)   if (! defined $extDbFileLoc);
    return(0,"*** $sbrName: not def extChainLoc!",0)    if (! defined $extChainLoc);
    $listFileInLoc=~s/^,*|,*$//g;
    @fileInLoc=split(/,/,$listFileInLoc);
    return(&errSbr("no file input ($listFileInLoc)"),0) if ($#fileInLoc == 0);

				# ------------------------------
				# loop over list
				# ------------------------------
    $#tmpf=$#tmpc=0;
    foreach $fileIn (@fileInLoc){
				# HSSP + chain
	if ($fileIn=~/^(.*$extDbFileLoc)$extChainLoc(.)$/ && $2 =~ /[A-Za-z0-9]/) {
	    $tmp=$rd; $tmp=~s/$extChainLoc.*$//g;       $file=$tmp;
	    $tmp=$rd; $tmp=~s/^.*$extChainLoc(.)$/$1/g; $chain=$tmp; 
	    push(@tmpf,$file); push(@tmpc,$chain); 
	    next; }
				# is e.g. HSSP (checked by extension)
	if ($fileIn=~/^(.*$extDbFileLoc)$/) {
	    push(@tmpf,$fileIn); push(@tmpc,"*"); 
	    next; }
				# is list?
	&open_file("$fhinLoc", "$fileIn") || return(&errSbr("fileIn=$fileIn"),0);
	while (<$fhinLoc>) {
	    $_=~s/\s|\n//g; $rd=$_; 
	    $file=$rd; $chain="*"; 
	    if ($rd =~ /.*$extDbFileLoc$extChainLoc(.)$/ && $1 =~ /[A-Za-z0-9]/){
		$tmp=$rd; $tmp=~s/$extChainLoc.*$//g;       $file=$tmp;
		$tmp=$rd; $tmp=~s/^.*$extChainLoc(.)$/$1/g; $chain=$tmp; }
	    return(&errSbr("file rd from list ($fileIn)=$file, not ext=$extDbFileLoc,"))
		if ($file !~ /$extDbFileLoc$/);
	    push(@tmpf,$file);push(@tmpc,$chain);} close($fhinLoc); 
    }
                                # ------------------------------
                                # ERROR
    return(&errSbr("no file found in ($listFileInLoc) with ".
                   "extDb=$extDbFileLoc, extChain=$extChainLoc"),0) if ($#tmpf<1);
				# ------------------------------
				# final lists
				# ------------------------------
    $file= join(',',@tmpf); $file =~s/,*$//g;
    $chain=join(',',@tmpc); $chain=~s/,*$//g;

    return(1,"ok $sbrName",$file,$chain);
}				# end of fileListArrayRd

#===============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#===============================================================================
sub fileListWrt {
    local($fileOutLoc,$fhErrSbr,@listLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListWrt                 writes a list of files
#       in:                     fileOut,$fhErrSbr (to report missing files),@list
#       out:                    1|0,msg : implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListWrt";$fhoutLoc="FHOUT_"."fileListWrt";
				# check arguments
    return(0,"*** $sbrName: not def fileOutLoc!")          if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def \@list!")              if (! defined @listLoc || ! @listLoc);
    $#tmp=0;                    # ------------------------------
    foreach $file (@listLoc){   # check existence
	if    (-e $file) {
	    push(@tmp,$file);}	# file ok
	elsif ($file=~/^(.*[hd]ssp\.*)_[0-9A-Z]$/ && -e $1){
	    push(@tmp,$file);}	# is chain
	else { print $fhErrSbr "-*- WARN $sbrName missing file=$file,\n";}}
    @listLoc=@tmp;

    return(0,"*** $sbrName: after check none in\@list!")   if (! defined @listLoc || ! @listLoc);
				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") ||
	return(0,"*** ERROR $sbrName: fileNew=$fileOutLoc, not created\n",0);
    foreach $file (@listLoc){   # write
	print $fhoutLoc $file,"\n";}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of fileListWrt

#===============================================================================
sub form_perl2rdb {
    local ($format) = @_ ;
#--------------------------------------------------------------------------------
#   form_perl2rdb               converts printf perl (d,f,s) into RDB format (N,F, ) 
#--------------------------------------------------------------------------------
    $format=~s/[%-]//g;$format=~s/f/F/;$format=~s/d/N/;$format=~s/s/S/;
    return $format;
}				# end of form_perl2rdb

#===============================================================================
sub form_rdb2perl {
    local ($format) = @_ ;
    local ($tmp);
#--------------------------------------------------------------------------------
#   form_perl2rdb               converts RDB (N,F, ) to printf perl format (d,f,s)
#--------------------------------------------------------------------------------
    $format=~tr/[A-Z]/[a-z]/;
    $format=~s/n/d/;$format=~s/(\d+)$/$1s/;
    if ($format =~ /[s]/){
	$format="%-".$format;}
    else {
	$format="%".$format;}
    return $format;
}				# end of form_rdb2perl

#===============================================================================
sub htmlWrtHead {
    local($fhoutLoc,$titleLoc,$txtLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlWrtHead                 writes header of HTML file
#       in:                     $fhoutLoc=    file handle to write
#       in:                     $titleLoc=    title for file
#       in:                     $txtLoc=      optional text (e.g. styles asf)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlWrtHead";
				# check arguments
    return(&errSbr("not def fhoutLoc!"))     if (! defined $fhoutLoc);
    return(&errSbr("not def titleLoc!"))     if (! defined $titleLoc);
    $txtLoc=0                                if (! defined $txtLoc);
#    return(&errSbr("not def !"))          if (! defined $);

				# header tag
    print $fhoutLoc
	"<HTML>\n",
	"<HEAD>\n";
				# additional text (style asf)
    print $fhoutLoc
	$txtLoc,"\n"            if ($txtLoc);

				# title
    print $fhoutLoc
	"<TITLE>\n",
	"        $titleLoc\n",
	"</TITLE>\n",

    return(1,"ok $sbrName");
}				# end of htmlWrtHead

#==============================================================================
sub is_dssp {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp                     checks whether or not file is in DSSP format
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    return (0) if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_DSSP";
    open($fh,$fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1
	    if ($_=~/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i);
	last; }
    close($fh);
    return $Lis;
}				# end of is_dssp

#===============================================================================
sub is_dssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp_list                checks whether or not file is a list of DSSP files
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_DSSP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$tmp=$_;$tmp=~s/\s|\n//g;
		     if (length($tmp)<5){next;}
		     if (! -e $tmp)     {$tmp=~s/_.$//;} # purge chain
		     if ( -e $tmp )     { # is existing file?
			 if (&is_dssp($tmp)) {$Lis=1; }
			 else { $Lis=0; } }
		     else {$Lis=0; } 
		     last; } close($fh);
    return $Lis;
}				# end of is_dssp_list

#==============================================================================
sub is_fssp {
    local ($fileInLoc) = @_ ;
#--------------------------------------------------------------------------------
#   is_fssp                     checks whether or not file is in FSSP format
#       in:                     $file
#       out:                    1 if is fssp; 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP";
    open($fh, $fileInLoc) || return(0);
    $tmp=<$fh> ;
    close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^FSSP/);
    return(0);
}				# end of is_fssp

#===============================================================================
sub is_fssp_list {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_fssp_lis                 checks whether or not file is a list of FSSP files
#       in:                     $file
#       out:                    1 if is list of fssp files; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$_=~s/\s|\n//g;
		     if ( -e $_ ) { # is existing file?
			 $Lis=1 if (&is_fssp($_));
			 last; } } close($fh);
    return $Lis;
}				# end of is_fssp_list

#===============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#===============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp_empty: filein=$fileInLoc, not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    while ( <$fh> ) {
	next if ($_!~/^NALIGN\s+(\d+)/);
	if ($1 eq "0"){
	    close($fh); 
	    return(1);}
	else {
	    close($fh); 
	    return(0);}
    }
    return 0;
}				# end of is_hssp_empty

#===============================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     next if (length($fileRd)<5);
		     ($fileLoc,$chainLoc)= 
			 &hsspGetFile($fileRd,$LscreenLoc);
		     $Lis=1 if (&is_hssp($fileLoc));
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#===============================================================================
sub is_list {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   is_list                     returns 1 if list of existing files
#       in:                     $fileInLoc
#       out:                    1|0,msg,$LisList
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."is_list"; $fhinLoc="FHIN_"."is_list";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ctLoc=$LisList=0;		# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n|\s//g;
	next if ($_=~/^\#/);
	++$ctLoc;
	$LisList=1              if (-e $_);
	last if ($LisList || $ctLoc==2); # 2 not existing files -> say NO!
	$tmp=$_; $tmp=~s/_?[A-Z0-9]$//g; # purge chain
	$LisList=1              if (-e $tmp);
    } close($fhinLoc);
    return(1,"ok $sbrName",$LisList);
}				# end of is_list

#===============================================================================
sub is_nndb_rdb { return(&is_rdb_nnDb(@_)); } # alias

#===============================================================================
sub is_nninFor {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   is_nninFor                  is input for FORTRAN input
#       in:                     $fileInLoc
#       out:                    1|0,msg,$Lis_nninFor
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."is_nninFor";$fhinLoc="FHIN_"."is_nninFor";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $Lis=0;
    $lineFirst=<$fhinLoc>;
    close($fhinLoc);
    $Lis=1 if ($lineFirst =~/NNin_in/i);
    return(1,"ok $sbrName",$Lis);
}				# end of is_nninFor

#==============================================================================
sub is_ppcol {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_ppcol                    checks whether or not file is in RDB format
#       in:                     $file
#       out:                    1 if is ppcol, 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc);
    $Lis=0;
    while ( <$fh> ) {
	$_=~tr/[A-Z]/[a-z]/;
	$Lis=1 if ($_=~/^\# pp.*col/);
	last; }
    close($fh);
    return $Lis;
}				# end of is_ppcol

#===============================================================================
sub is_rdb_acc {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lisacc);
#--------------------------------------------------------------------------------
#   is_rdb_acc                  checks whether or not file is in RDB format from PHDacc
#       in:                     $file
#       out:                    1 if is rdb_acc; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDACC";$Lisrdb=$Lisacc=0;
    &open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*acc/){$Lisacc=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lisacc);
}				# end of is_rdb_acc

#===============================================================================
sub is_rdb_htm {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htm                  checks whether or not file is in RDB format from PHDhtm
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$fileInLoc");
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { ++$ctLoc;
		      $Lisrdb=1       if (/^\# Perl-RDB/);
		      last if (! $Lisrdb);
		      $Lishtm=1       if (/^\#\s*PHD\s*htm\:/);
		      last if ($Lishtm);
		      last if ($_ !~/^\#/);
		      last if ($ctLoc > 5); }close($fh);
    return ($Lishtm);
}				# end of is_rdb_htm

#==============================================================================
sub is_rdb_htmref {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_PHDHTM_REF";$Lisrdb=$Lishtm=0;
    open($fh, $fileInLoc) || return(0); 
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { 
	++$ctLoc;
	$Lisrdb=1       if ($_=~/^\# Perl-RDB/);
	last if (! $Lisrdb);
	$Lishtm=1       if ($_=~/^\#\s*PHD\s*htm.*ref\:/);
	last if ($Lishtm);
	last if ($_ !~/^\#/);
	last if ($ctLoc > 5); }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmref

#==============================================================================
sub is_rdb_htmtop {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
	
    $fh="FHIN_CHECK_RDB_PHDHTM_TOP";$Lisrdb=$Lishtm=0;
    open($fh, $fileInLoc) || return(0); 
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { 
	++$ctLoc;
	$Lisrdb=1       if ($_=~/^\# Perl-RDB/);
	last if (! $Lisrdb);
	$Lishtm=1       if ($_=~/^\#\s*PHD\s*htm.*top\:/);
	last if ($Lishtm);
	last if ($_ !~/^\#/);
	last if ($ctLoc > 5); }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmtop

#==============================================================================
sub is_rdb_nnDb {
    local ($fileInLoc) = @_ ;
    local ($fh);
#--------------------------------------------------------------------------------
#   is_rdb_nnDb                 checks whether or not file is in RDB format for NN.pl
#       in:                     $file
#       out:                    1 if is rdb_nn; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_RDBNN";
    open($fh, $fileInLoc) || return(0);
    $tmp=(<$fh>);
    close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^\# Perl-RDB.*NNdb/i);
    return (0);
}				# end of is_rdb_nnDb

#===============================================================================
sub is_rdb_sec {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lissec);
#--------------------------------------------------------------------------------
#   is_rdb_sec                  checks whether or not file is RDB from PHDsec
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDSEC";$Lisrdb=$Lissec=0;
    &open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*sec/){$Lissec=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lissec);
}				# end of is_rdb_sec

#==============================================================================
sub is_strip {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip                    checks whether or not file is in HSSP-strip format
#       in:                     $file
#       out:                    1 if is strip; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_STRIP";
    open($fh, $fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1 if ($_=~/===  MAXHOM-STRIP  ===/);
	last; }
    close($fh);
    return $Lis;
}				# end of is_strip

#===============================================================================
sub is_strip_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#    is_strip_list              checks whether or not file contains a list of HSSPstrip files
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     if (length($fileRd)<5){
			 next;}
		     if (&is_strip($fileLoc)){$Lis=1;}else { $Lis=0;}
		     last; } close($fh);
    return $Lis;
}				# end of is_strip_list

#===============================================================================
sub is_strip_old {
    local ($fileInLoc)= @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip_old                checks whether file is old strip format
#                               (first SUMMARY, then ALIGNMENTS)
#       in:                     $file
#       out:                    1 if is strip; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP_OLD";
    &open_file("$fh", "$fileInLoc");
    $#tmp=0;
    while(<$fh>){if (/=== ALIGNMENTS ===/){$Lok_ali=1;
					   push(@tmp,"ALIGNMENTS");}
		 elsif (/=== SUMMARY ===/){$Lok_sum=1;
					   push(@tmp,"SUMMARY");}
		 last if ($Lok_ali && $Lok_sum) ;}
    close($fh);
    if ($tmp[1] =~/ALIGNMENTS/){
	$Lis=1;}
    else {
	$Lis=0;}
    return $Lis;
}				# end of is_strip_old

#===============================================================================
sub is_swissprot {return(&isSwiss(@_));} # alias

#==============================================================================
sub isDaf {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isDaf                       checks whether or not file is in DAF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_DAF","$fileLoc");
    while (<FHIN_DAF>){	if ($_=~/^\# DAF/){$Lok=1;}
			else            {$Lok=0;}
			last;}close(FHIN_DAF);
    return($Lok);
}				# end of isDaf

#===============================================================================
sub isDafGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isDafGeneral                checks (and finds) DAF files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not daf|isDaf|isDafList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isDafGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&isDaf($fileInLoc))    { # file is daf
	return(1,"isDaf",$fileInLoc); } 
				# ------------------------------
    elsif (&isDafList($fileInLoc)) { # file is daf list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			    if (length($_)==0) { 
				next;}
			    if    ((-e $tmp) && &isDaf($tmp)) { 
				push(@tmp,$tmp);}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isDafList",@tmp);}}
    else{
	return(0,"not daf",$fileInLoc);}
}				# end of isDafGeneral

#===============================================================================
sub isDafList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isDafList                   checks whether or not file is list of Daf files
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_DafList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=~s/\n|\s//g;
			if (&isDaf($fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isDafList

#===============================================================================
sub isDsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isDsspGeneral               checks (and finds) DSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not dssp|isDssp|isDsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isDsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for DSSP
	($file,$chain)=
	    &dsspGetFile($fileInLoc,@dirLoc);
	return(1,"isDssp",$file,$chain) if ((-e $file) && &is_dssp($file));
	return(0,"not dssp",$fileInLoc); }
				# ------------------------------
    if (&is_dssp($fileInLoc)){	# file is dssp
	return(1,"isDssp",$fileInLoc); } 	
				# ------------------------------
				# file is dssp list
    elsif (&is_dssp_list($fileInLoc)) {
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {
	    $_=~s/\n|\s//g;$rd=$_;
	    next if (length($_)==0);
				# file exists ...
	    if    (-e $rd) {
		if (&is_dssp($rd)) { # ... and is DSSP       -> bingo
		    push(@tmpFile,$rd); 
		    push(@tmpChain," "); }
		next; }		     # ... may just be empty -> skip
				# file does NOT exist (chain? dir?)
	    ($file,$chain)=	# search again
		&dsspGetFile($rd,1,@dirLoc);
				# ... bingo
	    if    (-e $file && &is_dssp($file)) { 
		push(@tmpFile,$file);
		push(@tmpChain,$chain); }
	    next;		# GIVE UP ...
	} close($fhinLoc);
				# ... none in list ??
	return(0,"none in list",$fileInLoc) if ($#tmpFile==0);
				# ok -> go home
	return(1,"isDsspList",@tmpFile,"chain",@tmpChain);}
    
				# ------------------------------
    else {			# search for DSSP
	($file,$chain)=
	    &dsspGetFile($fileInLoc,@dirLoc);
	return(1,"isDssp",$file,$chain)     if (-e $file && &is_dssp($file));
	return(0,"not dssp",$fileInLoc); 
    }
}				# end of isDsspGeneral

#===============================================================================
sub isFasta {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFasta                     checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    open($fhinLoc2,$fileLoc) || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s|\n//g            if (defined $two);
    close($fhinLoc2);

    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if ($one =~ /^\s*>\s*\w+/ && 
				    $two !~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/);
    return(0);
}				# end of isFasta

#==============================================================================
sub isFastaMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#                               (first line /^>\w/, second (non white) = AA *2 
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    open($fhinLoc2,$fileLoc) || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s//g               if (defined $two);

    return (0)                  if (! defined $two || ! defined $one);
    return (0)                  if (($one !~ /^\s*\>\s*\w+/) || 
				    ($two =~ /[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i));
    $Lok=0;
    while (<$fhinLoc2>) {
	next if ($_ !~ /^\s*>\s*\w+/);
	$Lok=1;
	last;}close($fhinLoc2);
    return($Lok);
}				# end of isFastaMul

#===============================================================================
sub isFsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isFsspGeneral               checks (and finds) FSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not fssp|isFssp|isFsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isFsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&is_fssp($fileInLoc))    { # file is fssp
	return(1,"isFssp",$fileInLoc); } 
				# ------------------------------
    elsif (&is_fssp_list($fileInLoc)) { # file is fssp list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;if (length($_)==0)             { next;}
			    $tmp=$_;
			    if    ((-e $tmp) && &is_fssp($tmp))        { push(@tmp,$tmp);}
			    else { # search for valid FSSP file
				($file,$chain)=&fsspGetFile($fileInLoc,@dirLoc);
				if    ((-e $file) && &is_fssp($file))        { push(@tmp,$file);}
				next;}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isFsspList",@tmp);}}
				# ------------------------------
    else {			# search for FSSP
	($file,$chain)=&fsspGetFile($fileInLoc,@dirLoc);
	if    ((-e $file) && &is_fssp($file))        { 
	    return(1,"isFssp",$file); } 
	else {
	    return(0,"not fssp",$fileInLoc); }}
}				# end of isFsspGeneral

#==============================================================================
sub isGcg {
    local ($fileLoc) = @_ ; $[ =1 ;
#--------------------------------------------------------------------------------
#    isGcg                      checks whether or not file is in Gcg format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
# EXA: paho_chick from:    1 to:   80
# EXA: PANCREATIC HORMONE PRECURSOR (PANCREATIC POLYPEPTIDE) (PP).
# EXA:  paho_chick.gcg          Length:   80   31-May-98  Check: 8929 ..
# EXA:        1  MPPRWASLLL LACSLLLLAV PPGTAGPSQP TYPGDDAPVE DLIRFYNDLQ
# EXA:       51  QYLNVVTRHR YGRRSSSRVL CEEPMGAAGC
#--------------------------------------------------------------------------------
    return(0) if (! defined $fileLoc || ! -e $fileLoc);
    $fhinLoc="FHIN_GCG";
    open($fhinLoc,$fileLoc) || do { warn "-*- isGcg failed opening=$fileLoc\n";
				    return(0); };
    $ctLocFlag=$#tmp=0;
    while(<$fhinLoc>){++$ctLocFlag;
		      push(@tmp,$_);
		      last if ($ctLocFlag==5);}
    close($fhinLoc);
    $ctLocFlag=$already_sequence=0;
    foreach $tmp (@tmp){
	last if ($tmp=~/^\#/); # avoid being too friendly to GCG!
	if   ($tmp=~/from\s*:\s*\d+\s*to:\s*\d+/i)          {
	    ++$ctLocFlag;}
	elsif($tmp=~/^\s*\w+\s+Length\s*:\s+\d+\s+\d\d\-/i) {
	    ++$ctLocFlag;}
	elsif(! $already_sequence && $tmp=~/[\s\t]*\d+\s+[A-Z]+/i) {
	    $already_sequence=1;
	    ++$ctLocFlag;}
	last if ($ctLocFlag==3);}
    return(1) if ($ctLocFlag==3);
    return(0) ;
}				# end of isGcg

#==============================================================================
sub isGcgArray {
    local (@tmp) = @_ ; $[ =1 ;
#--------------------------------------------------------------------------------
#    isGcgArray                      checks whether or not file is in Gcg format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
# EXA: paho_chick from:    1 to:   80
# EXA: PANCREATIC HORMONE PRECURSOR (PANCREATIC POLYPEPTIDE) (PP).
# EXA:  paho_chick.gcg          Length:   80   31-May-98  Check: 8929 ..
# EXA:        1  MPPRWASLLL LACSLLLLAV PPGTAGPSQP TYPGDDAPVE DLIRFYNDLQ
# EXA:       51  QYLNVVTRHR YGRRSSSRVL CEEPMGAAGC
#--------------------------------------------------------------------------------
    return(0)                    if (! defined @tmp || ! $#tmp);
    $ctLocFlag=$already_sequence=0;
    foreach $tmp (@tmp){
	last if ($tmp=~/^\#/); # avoid being too friendly to GCG!
	if   ($tmp=~/from\s*:\s*\d+\s*to:\s*\d+/i)          {
	    ++$ctLocFlag;}
	elsif($tmp=~/^\s*\w+\s+Length\s*:\s+\d+\s+\d\d\-/i) {
	    ++$ctLocFlag;}
	elsif(! $already_sequence && $tmp=~/[\s\t]*\d+\s+[A-Z]+/i) {
	    $already_sequence=1;
	    ++$ctLocFlag;}
	last if ($ctLocFlag==3);}
    return(1)                   if ($ctLocFlag==3);
    return(0) ;
}				# end of isGcgArray

#===============================================================================
sub isHelp {
    local ($argLoc) = @_ ;
#--------------------------------------------------------------------------------
#   isHelp		        returns 1 if : help,man,-h
#       in:                     argument
#       out:                    returns 1 if is help, 0 else
#--------------------------------------------------------------------------------
    return(1)
	if ( $argLoc eq "help" || $argLoc eq "man" || $argLoc eq "-h" );
    return(0);
}				# end of isHelp

#===============================================================================
sub isHsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isHsspGeneral               checks (and finds) HSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not hssp|isHssp|isHsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isHsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain) if ((-e $file) && &is_hssp($file));
	return(0,"empty", $file)    	if ((-e $file) && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); }
				# ------------------------------
    if (&is_hssp($fileInLoc)){	# file is hssp
	return(0,"empty hssp",$fileInLoc)
	    if (&is_hssp_empty($fileInLoc));
	return(1,"isHssp",$fileInLoc); } 
				# ------------------------------
				# file is hssp list
    elsif (&is_hssp_list($fileInLoc)) {
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {
	    $_=~s/\n|\s//g;$rd=$_;
	    next if (length($_)==0);
				# file exists ...
	    if    (-e $rd) {
		if (&is_hssp($rd)) { # ... and is HSSP       -> bingo
		    push(@tmpFile,$rd); 
		    push(@tmpChain," "); }
		next; }		     # ... may just be empty -> skip
				# file does NOT exist (chain? dir?)
	    ($file,$chain)=	# search again
		&hsspGetFile($rd,1,@dirLoc);
				# ... bingo
	    if    (-e $file && &is_hssp($file)) { 
		push(@tmpFile,$file);
		push(@tmpChain,$chain); }
	    next;		# GIVE UP ...
	} close($fhinLoc);
				# ... none in list ??
	return(0,"none in list",$fileInLoc) if ($#tmpFile==0);
				# ok -> go home
	return(1,"isHsspList",@tmpFile,"chain",@tmpChain);}
    
				# ------------------------------
    else {			# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain)     if (-e $file && &is_hssp($file));
	return(0,"empty" ,$file,"err")      if (-e $file && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); 
    }
}				# end of isHsspGeneral

#==============================================================================
sub isMsf {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isMsf                       checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_MSF","$fileLoc");
    while (<FHIN_MSF>){ $Lok=0;
			$Lok=1  if ($_=~/\s*MSF[\s:]+/ ||
				# new PileUp shit
				     $_=~/\s*PileUp|^\s*\!\!AA_MULTIPLE_ALIGNMENT/);
			last;} 
    close(FHIN_MSF);
    return($Lok);
}				# end of isMsf

#===============================================================================
sub isMsfGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isMsfGeneral                checks (and finds) MSF files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not msf|isMsf|isMsfList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isMsfGeneral";$fhinLoc="FHIN"."$sbrName";
    if (! -e $fileInLoc){
	return(0,"not existing",$fileInLoc);}
				# ------------------------------
    if (&isMsf($fileInLoc))    { # file is msf
	return(1,"isMsf",$fileInLoc); } 
				# ------------------------------
    elsif (&isMsfList($fileInLoc)) { # file is msf list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			    if (length($_)==0) { 
				next;}
			    if    ((-e $tmp) && &isMsf($tmp)) { 
				push(@tmp,$tmp);}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isMsfList",@tmp);}}
    else{
	return(0,"not msf",$fileInLoc);}
}				# end of isMsfGeneral

#===============================================================================
sub isMsfList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isMsfList                   checks whether or not file is list of Msf files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_MsfList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			if (&isMsf($fileTmp)&&(-e $fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isMsfList

#===============================================================================
sub isPdb { 
    local ($fileLoc) = @_ ; 
    local ($Lok,$fhinLoc);
#--------------------------------------------------------------------------------
#   isPdb                       checks whether or not file is PDB format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_PDB";$Lok=0;
    open($fhinLoc,$fileLoc) || 
	do { warn "*** isPdb failed opening file=$fileLoc!\n";
	     return(0); };
    while(<$fhinLoc>){
	$tmp=$_; $tmp=~s/\n//g;
	last;}
    close($fhinLoc);
#HEADER    PANCREATIC HORMONE                      16-JAN-81   1PPT      1PPT   3
#HEADER    PANCREATIC HORMONE                      16-JAN-81   1PPT      1PPTA  3
#HEADER    PANCREATIC HORMONE                      16-JAN-81   1PPT      1PPT  
    return(1)
	if ($tmp=~/^HEADER\s+.*\d\w\w\w\w?\s+\d+\s*$/ ||
	    $tmp=~/^HEADER\s+.*\d\w\w\w\w?\s*$/);
    return(0);
}				# end of isPdb

#==============================================================================
sub isPhdAcc {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdAcc                    checks whether or not file is in PHD.rdb_acc format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDACC",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDACC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){
	    $Lok=1;}
	elsif ($ctLoc==1)                  { 
	    close(FHIN_RDB_PHDACC); 
	    return(0);}
	elsif ($_=~/PHDacc/)            { 
	    close(FHIN_RDB_PHDACC); 
	    return(1);}}
    close(FHIN_RDB_PHDACC);
    return(0);
}				# end of isPhdAcc

#===============================================================================
sub isPhdBoth {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdBoth                   checks whether or not file is in PHD.rdb format 
#                               acc + sec
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDBOTH",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDBOTH>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { 
	    $Lok=1;}
	elsif ($ctLoc==1)                       { 
	    close(FHIN_RDB_PHDBOTH); 
	    return(0); }
	elsif ($_=~/PHDsec/ && $_=~/PHDacc/) { 
	    close(FHIN_RDB_PHDBOTH); 
	    return(1);}}
    close(FHIN_RDB_PHDBOTH);
    return(0);
}				# end of isPhdBoth

#==============================================================================
sub isPhdHtm {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdHtm                    checks whether or not file is in PHD.rdb_htm format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDHTM",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDHTM>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){
	    $Lok=1;}
	elsif ($ctLoc==1) { 
	    close(FHIN_RDB_PHDHTM); 
	    return(0);}
	elsif ($_=~/PHDhtm/){
	    close(FHIN_RDB_PHDHTM); 
	    return(1);}}
    close(FHIN_RDB_PHDHTM);
    return(0);
}				# end of isPhdHtm

#==============================================================================
sub isPhdSec {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdSec                    checks whether or not file is in PHD.rdb_sec format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDSEC",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDSEC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { 
	    $Lok=1;}
	elsif ($ctLoc==1)                       { 
	    close(FHIN_RDB_PHDSEC); 
	    return(0); }
	elsif ($_=~/PHDsec/)                 { 
	    close(FHIN_RDB_PHDSEC); 
	    return(1);}}
    close(FHIN_RDB_PHDSEC);
    return(0);
}				# end of isPhdSec

#==============================================================================
sub isPir {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isPir                    checks whether or not file is in Pir format 
#                               (first line /^>P1\;/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_PIR",$fileLoc) || return(0);
    $one=(<FHIN_PIR>);close(FHIN_PIR);
    return(1)                   if (defined $one && $one =~ /^\>P1\;/i);
    return(0);
}				# end of isPir

#==============================================================================
sub isPirMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPirMul                    checks whether or not file contains many sequences 
#                               in PIR format 
#                               more than once: first line /^>P1\;/
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_PIR",$fileLoc) || return(0);
    $ctLoc=0;
    while(<FHIN_PIR>){
	++$ctLoc if ($_=~/^>P1\;/i);
	last if ($ctLoc>1);}
    close(FHIN_PIR);
    return(1)                   if ($ctLoc>1);
    return(0);
}				# end of isPirMul

#==============================================================================
sub isRdb {
    local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    return (0) if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB";
    open($fh,$fileInLoc) ||
	do { print "*** ERROR isRdb: filein=$fileInLoc, not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;
    close($fh);
    return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
    return 0; 
}				# end of isRdb

#===============================================================================
sub isRdbGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isRdbGeneral                checks (and finds) RDB files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not rdb|isRdb|isRdbList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isRdbGeneral";$fhinLoc="FHIN"."$sbrName";
				# is RDB
    return(1,"isRdb",$fileInLoc)   if (&isRdb($fileInLoc));
				# not list
    return(0,"not rdb",$fileInLoc) if (! &isRdbList($fileInLoc));

				# ------------------------------
				# read list

    open($fhinLoc,$fileInLoc) ||
	do { print "*** ERROR isRdbGeneral: filein=$fileInLoc, not opened to $fhinLoc\n";
	     return (0) ;};	# missing file -> 0

    while (<$fhinLoc>) {
	$_=~s/\n//g;$tmp=$_;
	next if (length($_)==0);
	push(@tmp,$tmp) if (-e $tmp && &isRdb($tmp));}
    close($fhinLoc);
    return(0,"none in list",$fileInLoc) if ($#tmp==0);
    return(1,"isRdbList",@tmp);
}				# end of isRdbGeneral

#===============================================================================
sub isRdbList {local ($fileInLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isRdbList                   checks whether or not file is list of Rdb files
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	       return(0) if (! -e $fileInLoc); 
	       $fhinLoc="FHIN_RDBLIST";$Lok=0;
	       open($fhinLoc,$fileInLoc) ||
		   do { print "*** ERROR isRdbList: filein=$fileInLoc, not opened to $fhinLoc\n";
			return (0) ;};	# missing file -> 0
	       while (<$fhinLoc>){ 
                   $_=~s/\s|\n//g;
                   if ($_=~/^\#/ || ! -e $_){close($fhinLoc);
                                             return(0);}
                   $fileTmp=$_;
                   if (&isRdb($fileTmp)&&(-e $fileTmp)){
                       close($fhinLoc);
                       return(1);}
                   last;}close($fhinLoc);
	       return(0); }	# end of isRdbList

#==============================================================================
sub isSaf {
    local ($fileLoc) = @_ ; 
#--------------------------------------------------------------------------------
#    isSaf                      checks whether or not file is in SAF format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    return(0)            if (! defined $fileLoc || ! -e $fileLoc);
    $fhinLoc="FHIN_SAF";
    open("$fhinLoc",$fileLoc) || return (0);
    $tmp=<$fhinLoc>; 
    close("$fhinLoc");
    return(1)            if (defined $tmp && $tmp =~ /^\#.*SAF/);
    return(0);
}				# end of isSaf
#==============================================================================
sub isSwiss {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_SWISS";
    open($fhinLoc,$fileLoc) ||
	do { print "*** ERROR isSwiss: filein=$fileLoc, not opened to $fhinLoc\n";
	     return (0) ;};	# missing file -> 0
    while (<$fhinLoc>){ 
	$Lok=1                  if ($_=~/^ID   /);
	last;}
    close($fhinLoc);
    return($Lok);
}				# end of isSwiss

#===============================================================================
sub isSwissGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isSwissGeneral              checks (and finds) SWISS files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not swiss|isSwiss|isSwissList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:isSwissGeneral";$fhinLoc="FHIN"."$sbrName";
    return(1,"isSwiss",$fileInLoc) if (&isSwiss($fileInLoc)) ;  # file is swiss
				# ------------------------------
    if (&isSwissList($fileInLoc)) { # file is swiss list
	open($fhinLoc,$fileInLoc) ||
	    do { print "*** ERROR isSwiss: filein=$fileInLoc, not opened to $fhinLoc\n";
		 return (0,"not opened=",$fileInLoc) ;};	# missing file -> 0
	while (<$fhinLoc>) {$_=~s/\n//g;	    
			    next if (length($_)==0);
			    $tmp=$_;
			    if    ((-e $tmp) && &isSwiss($tmp))        { 
				push(@tmp,$tmp);}
			    else {		# search for valid SWISS file
				($file,$chain)=&swissGetFile($fileInLoc,@dirLoc);
				if    ((-e $file) && &isSwiss($file))        { 
				    push(@tmp,$file);}
				next;}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isSwissList",@tmp);}}
				# ------------------------------
    else {			# search for SWISS
	($file,$chain)=
	    &swissGetFile($fileInLoc,@dirLoc);
	return(1,"isSwiss",  $file) if ((-e $file) && &isSwiss($file));
	return(0,"not swiss",$fileInLoc);}
}				# end of isSwissGeneral

#===============================================================================
sub isSwissList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isSwissList                 checks whether or not file is list of Swiss files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_SwissList";$Lok=0;
    open($fhinLoc,$fileLoc) ||
	do { print "*** ERROR isSwissList: filein=$fileLoc, not opened to $fhinLoc\n";
	     return (0) ;};	# missing file -> 0
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			return (0) if (! -e $fileTmp);
			$Lok=1 if (&isSwiss($fileTmp) && -e $fileTmp);
			last;}close($fhinLoc);
    return($Lok);
}				# end of isSwissList

#===============================================================================
sub getFileFromArray {
    local($kwdInLoc,$LcaseIndependent,$fileListInLoc,$dirListInLoc) = @_ ;
    local($sbrName,@fileInLoc,@dirInLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFromArray            finds the file associated to 'keyword' from the
#                               array of files (return 1,'ok',0 if none found!)
#       in:                     $keyword        name of file to find 
#                                               e.g. blosum in Maxhom_Blosum.metr
#       in:                     $LcaseIndependent=<1|0> if 1: search case independent
#                                               blosum matches BLOSum ..
#       in:                     $fileList       files to search, many=
#                                  'file1,file2'
#       in:                     $dirList        directories to try: 
#                                  'dir1,dir2,dir3'
#       out:                    1|0,msg,($file|0=>none found!)
#       err:                    (1,'ok',$file), (0,'message',0)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."getFileFromArray";
				# check arguments
    return(&errSbr("not def kwdInLoc!"))         if (! defined $kwdInLoc);
    return(&errSbr("not def LcaseIndependent!")) if (! defined $LcaseIndependent);
    return(&errSbr("not def fileListInLoc!"))    if (! defined $fileListInLoc);
    $dirListInLoc=""                             if (! defined $dirListInLoc);
				# set 0
    $fileFoundLoc=$#fileInLoc=$#dirInLoc=0;
    $fileListInLoc=~s/^,|,$//g;
    $dirListInLoc=~s/^,|,$//g   if (defined $dirListInLoc);
				# search case independent!
    $kwdInLoc=~tr/[A-Z]/[a-z]/  if ($LcaseIndependent);

				# ------------------------------
				# (1) split file and dir list
    @fileInLoc=split(/,/,$fileListInLoc);
    @dirInLoc=("");		# first one empty: no dir search
    push(@dirInLoc,split(/,/,$dirListInLoc)) if (defined $dirListInLoc);
				# <--- <--- <--- <---
				# none found
    return(1,"none found",0)    if (! @fileInLoc);
				# <--- <--- <--- <---

				# ------------------------------
				# (2) loop over all 
    foreach $file (@fileInLoc) {
	foreach $dir (@dirInLoc) {
	    $file=~s/^.*\///g   if (length($dir)>=1);                # strip dir from file
	    $dir.="/"           if (length($dir)>=1 && $dir!~/\/$/); # append slash
	    $fileTmp=$dir.$file; # file to take
	    $fileTmp2=$fileTmp;
				# skip non-existing files
	    next if (! -e $fileTmp);
				# search case independent!
	    $fileTmp2=~tr/[A-Z]/[a-z]/  if ($LcaseIndependent);
	    if ($fileTmp2=~/$kwdInLoc/) {
				# (-: (-: (-: (-: (-: 
				# ok one found, go home
		return(1,"ok",$fileTmp); }
	}}
				# ------------------------------
				# (3) note: coming here means:
				#           none FOUND!!
    return(1,"ok $sbrName",$fileFoundLoc);
}				# end of getFileFromArray

#===============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#===============================================================================
sub rd_col_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$it,@tmp,$tmp,$des_in,%ptr,%rdcol);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_col_associative         reads the content of a comma separated file
#       in:                     Names used for columns in perl file, e.g.,
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
				# set some defaults
    $fhin="FHIN_COL";
    $sbr_name="rd_col_associative";
    undef %rdcol; undef %ptr;
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open($fhin,$file_in) || die("*** ERROR $sbr_name: failed to open file_in=$file_in\n");
    $ctLoc=0;
    while(<$fhin>){
	$_=~s/\n//g;
	next if (/^\#/);	# ignore RDB header
	++$ctLoc;			# delete leading blanks, commatas and tabs
	$_=~s/^\s*|\s*$|^,|,$|^\t|\t$//g;
	$#tmp=0;@tmp=split(/[,\t ]+/,$_);
	if ($ctLoc==1){
	    $Lok=0;
	    foreach $des (@des_in) {
		foreach $it (1..$#tmp) {
		    if ($des =~ /$tmp[$it]/){
			$ptr{$des}=$it;
			$Lok=1;
			last;}}}
	    if (!$Lok){print"*** ERROR in reading col format ($sbr_name), none found\n";
		       exit;}}
	else {
	    foreach $des (@des_in){
		if (defined $ptr{$des}){
		    $tmp=$ctLoc-1;
		    $rdcol{"$des","$tmp"}=$tmp[$ptr{$des}];}}}
    }close($fhin);
    $rdcol{"NROWS"}=$ctLoc-1;
    return (%rdcol);
}				# end of rd_col_associative

#===============================================================================
sub rd_rdb_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rd_rdb_associative          reads the content of an RDB file into an associative
#                               array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#                       ALL:    'head,body'
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#                       HEADER: rdrdb{"header"}
#                       NAMES:  rdrdb{"names"} 
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhin="FHIN_RDB";
    $sbr_name="rd_rdb_associative";
				# get input
    $Lhead=$Lbody=$Lhead_all=$Lbody_all=$#des_headin=$#des_bodyin=0;
    foreach $des_in(@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; $Lbody_all=1;}
	elsif($Lhead)                        {push(@des_headin,$des_in); $Lhead_all=0;}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;; $Lbody_all=0;
					      push(@des_bodyin,$des_in);}
	else {print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open($fhin,$file_in) || die("*** ERROR $sbr_name: failed to open file_in=$file_in\n");

				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &read_rdb_num2($fhin,0);
    close($fhin);
				# ------------------------------
				# process header
    $#des_head=0;
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^$des_in[ :,\;]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;
		    $tmp=~s/$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{$des_in}){
			$rdrdb{$des_in}.="\t".$tmp;}
		    else {
			$rdrdb{$des_in}=$tmp;}
		    push(@des_head,$des_in);
		    $Lfound=1;} }
	    if(!$Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find in header key word:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}
	}}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { 
	    $rd=~s/^\s?|\n//g;
	    $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
				# get column numbers to be read
    $#des_body=0;
    if (! $Lbody_all){
	foreach $des_in (@des_bodyin) {
	    $Lfound=0;
	    for($it=1;$it<=$#READNAME;++$it) {
		$rd=$READNAME[$it];
		if ($rd eq $des_in) {$ptr_rd2des{$des_in}=$it;push(@des_body,$des_in);
				     $Lfound=1;last;} }
	    if((!$Lfound) && $Lscreen){
		print"--- $sbr_name: \t expected to find column name:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}}}
    else {
	foreach $it(1..$#READNAME){
	    $name=$READNAME[$it];$ptr_rd2des{"$name"}=$it;
	    push(@des_body,$name);}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{$des_in};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{$des_in,"format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{$des_in,"format"}="8";}}

    $nrow_rd=0;$names="";
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{$des_in};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if ($nrow_rd==0){
	    $nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){
	    print "*** WARNING $sbr_name: different number of rows\n";
	    print "*** WARNING in RDB file '$file_in' for rows with ".
		  "key= $des_in and previous column no=$itrd,\n";}
	$names.=$des_in.",";
	for($it=1;$it<=$#tmp;++$it){
	    $rdrdb{$des_in,$it}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#===============================================================================
sub rdb2html {
    local ($fileRdb,$fileHtml,$fhout,$Llink,$scriptName) = @_ ;
    local (@headerRd,$tmp,@tmp,@colNames,$colNames,%body,$des,$ct,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdb2html                    convert an RDB file to HTML
#       in:		        $fileRdb,$fileHtml,$fhout,$Llink 
#                               (Llink=1 -> links from column names to Notation in header)
#       ext                     open_file, 
#       ext                     wrtRdb2HtmlHeader,wrtRdb2HtmlBody
#       ext GLOBULAR:           wrtRdb2HtmlBodyColNames,wrtRdb2HtmlBodyAve
#--------------------------------------------------------------------------------
    $fhin="FHinRdb2html";
    &open_file("$fhin", "$fileRdb");

    $#headerRd=0;
				# ------------------------------
    while (<$fhin>) {		# read header of RDB file
	$tmp=$_;
	$_=~s/\n//g;
	last if (! /^\#/);
	push(@headerRd,$_);}
				# ------------------------------
				# get column names
    $tmp=~s/\n//g;$tmp=~s/^\t*|\t*$//g;
    @colNames=split(/\t/,$tmp);

    $body{"COLNAMES"}="";
    foreach $des (@colNames){	# store column names
	$body{"COLNAMES"}.="$des".",";}
	
				# ------------------------------
    while (<$fhin>) {		# skip formats
	$tmp=$_;
	last;}
				# ------------------------------
				# read body
    $ct=0;$Lave=0;
    while (<$fhin>) {
	$_=~s/\n//g;
	$_=~s/^\t*|\t*$//g;
	if (length($_)<1){
	    next;}
	@tmp=split(/\t/,$_);
	++$ct;
	foreach $it (1..$#tmp){	# store body
	    $key=$colNames[$it];
	    $body{"$ct","$key"}=$tmp[$it];}
	if ($tmp[1] =~ "^ave"){$Lave=1;}
    }
    
    $body{"NROWS"}=$ct;
				# end of reading RDB file
				# ------------------------------

				# ------------------------------
				# write output file
    if ($fhout ne "STDOUT"){
	&open_file("$fhout", ">$fileHtml");}

    @tmp=			# write header
	&wrtRdb2HtmlHeader($fhout,$scriptName,$fileRdb,$Llink,$Lave,$body{"COLNAMES"},@headerRd);
				# mark keys to be linked
    foreach $col (@colNames){
	$body{"link","$col"}=0;}
    foreach $col (@tmp){
	$body{"link","$col"}=1;}
				# write body
    &wrtRdb2HtmlBody($fhout,$Llink,%body);

				# add icons
    print $fhout 
	"<P><P><HR><P><P>\n",
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/icons\/embl_home.gif\" ",
	      "ALT=\"EMBL Home\"><\/A>\n",
	"<A HREF=\"http:\/\/www.sander.embl-heidelberg.de\/descr\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.sander.embl-heidelberg.de\/sander-icon.gif\" ",
	      "ALT=\"Sander Group\"><\/A>\n",
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/~rost\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-br-home.gif\" ",
	       "ALT=\"Rost Home\"><\/A>\n",
	"<A HREF=\"mailto\:rost\@embl-heidelberg.de\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-br-home-mail.gif\" ",
	       "ALT=\"Mail to Rost\"><\/A>\n",
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/predictprotein\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-pp.gif\" ",
	      "ALT=\"PredictProtein\"><\/A>\n",
	"<\/BODY>\n","<\/HTML>\n";
    print $fhout "\n";
    close($fhin);close($fhout);
}				# end of rdb2html

#===============================================================================
sub rdbGenWrtHdr {
    local($fhoutLoc2,%tmpLoc)= @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbGenWrtHdr                writes a general header for an RDB file
#       in:                     $file_handle_for_out
#       in:                     $tmp2{}
#                               $tmp2{"name"}    : name of program/format/.. eg. 'NNdb'
#                notation:     
#                               $tmp2{"nota","expect"}='name1,name2,...,nameN'
#                                                : column names listed
#                               $tmp2{"nota","nameN"}=
#                                                : description for nameN
#                               
#                               additional notations:
#                               $tmp2{"nota",$ct}='kwd'.'\t'.'explanation'  
#                                                : the column name kwd (e.g. 'num'), and 
#                                                  its description, 
#                                                  e.g. 'is the number of proteins'
#                parameters:           
#                               $tmp2{"para","expect"}='para1,para2' 
#                               $tmp2{"para","paraN"}=
#                                                : value for parameter paraN
#                               $tmp2{"form","paraN"}=
#                                                : output format for paraN (default '%-s')
#       out:                    implicit: written onto handle
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."rdbGenWrtHdr";
                                # defaults, read
    $name="";        $name=$tmpLoc{"name"}." "   if (defined $tmpLoc{"name"});
    $#colNamesTmp=0; @colNamesTmp=split(/,/,$tmpLoc{"nota","expect"})
                                                 if (defined $tmpLoc{"nota","expect"});
    $#paraTmp=0;     @paraTmp=    split(/,/,$tmpLoc{"para","expect"})
                                                 if (defined $tmpLoc{"para","expect"});

    print $fhoutLoc2 
	"# Perl-RDB  $name"."format\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORM  beg          $name\n",
	"# FORM  general:     - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORM  general:     - columns are delimited by tabs\n",
	"# FORM  format:      '# FORM  SPACE keyword SPACE further-information'\n",
	"# FORM  parameters:  '# PARA: SPACE keyword SPACE=TAB value TAB (further-info)'\n",
	"# FORM  notation:    '# NOTA: SPACE keyword SPACE=TAB explanation'\n",
	"# FORM  1st row:     column names  (tab delimited)\n",
	"# FORM  2nd row (may be): column format (tab delimited)\n",
	"# FORM  rows 2|3-N:  column data   (tab delimited)\n",
        "# FORM  end          $name\n",
	"# --------------------------------------------------------------------------------\n";
                                # ------------------------------
				# explanations
                                # ------------------------------
    if ($#colNamesTmp>0 || defined $tmpLoc{"nota","1"}){
        print  $fhoutLoc2 
            "# NOTA  begin        $name"."ABBREVIATIONS\n",
            "# NOTA               column names \n";
        foreach $kwd (@colNamesTmp) { # column names
            next if (! defined $kwd);
            next if (! defined $tmpLoc{"nota","$kwd"});
            printf $fhoutLoc2 "# NOTA: %-12s =\t%-s\n",$kwd,$tmpLoc{"nota","$kwd"}; }
        print  $fhoutLoc2 
            "# NOTA               parameters\n";
        foreach $it (1..1000){      # additional info
            last if (! defined $tmpLoc{"nota",$it});
            ($kwd,$expl)=split(/\t/,$tmpLoc{"nota",$it});
            next if (! defined $kwd);
            $expl="" if (! defined $expl);
            printf $fhoutLoc2 "# NOTA: %-12s =\t%-s\n",$kwd,$expl; }
        print $fhoutLoc2 
            "# NOTA  end          $name"."ABBREVIATIONS\n",
            "# --------------------------------------------------------------------------------\n"; }

                                # ------------------------------
				# parameters
                                # ------------------------------
    if ($#paraTmp > 0) {
        print $fhoutLoc2
            "# PARA  beg          $name\n";
        foreach $kwd (@paraTmp){
	    next if (! defined $tmpLoc{"para","$kwd"});
            $tmp="%-s";
            $tmp=$tmpLoc{"form","$kwd"} if (defined $tmpLoc{"form","$kwd"});
	    printf $fhoutLoc2
		"# PARA: %-12s =\t$tmp\n",$kwd,$tmpLoc{"para","$kwd"}; }
        print $fhoutLoc2 
            "# PARA  end          $name\n",
            "# --------------------------------------------------------------------------------\n"; }

}				# end of rdbGenWrtHdr

#===============================================================================
sub rdRdbAssociative {
    local ($fileInLoc,@des_in) = @_ ;
    local ($sbr_name,$fhinLoc,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative            reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhinLoc="FHIN_RDB";$sbr_name="rdRdbAssociative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in (@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
					      push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open($fhinLoc,$fileInLoc) || die ("*** ERROR $sbr_name: failed opening fileIn=$fileInLoc!\n");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &rdRdbAssociativeNum($fhinLoc,0);
    close($fhinLoc);
				# ------------------------------
    $#des_head=0;		# process header
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^(PARA\s*:?\s*)?$des_in\s*[ :,\;=]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/^.*$des_in//g;$tmp=~s/^\s*//g;
		    $tmp=~s/^[\s:\t]*//g;
		    if (defined $rdrdb{$des_in}){
			$rdrdb{$des_in}.="\t".$tmp;}
		    else {
			$rdrdb{$des_in}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    print
		"--- $sbr_name: \t expected to find in header key word:\n",
		"---            \t '$des_in', but not in file '$fileInLoc'\n"
		    if (!$Lfound && $Lscreen); }}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1; $it<=$#READNAME; ++$it) {
	    $rd=$READNAME[$it];$rd=~s/\s//g;
	    if ($rd eq $des_in) {
		$ptr_rd2des{$des_in}=$it;push(@des_body,$des_in);$Lfound=1;
		last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{$des_in};
	if ( defined $it && defined $READFORMAT[$it] ) {
	    $rdrdb{$des_in,"format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{$des_in,"format"}="8";}}
    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{$des_in};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if   ($nrow_rd==0)    {$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "***         in RDB file '$fileInLoc' for rows with ".
				   "key=$des_in, column=$itrd, prev=$nrow_rd, now=$#tmp,\n";}
	for ($it=1; $it<=$#tmp; ++$it){
	    $rdrdb{$des_in,$it}=$tmp[$it];
	    $rdrdb{$des_in,$it}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
				# ------------------------------
				# safe memory
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    $#des_headin=$#des_body=$#tmp=$#des_head=0;
    undef %ptr_rd2des;
    $#des_in=0;                 # slim_is_in !
    
    return (%rdrdb);
}				# end of rdRdbAssociative

#===============================================================================
sub rdRdbAssociativeNum {
    local ($fhLoc2,@readnum) = @_ ;
    local ($ctLoc, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#       in:                     $fhLoc,@readnum,$readheader,@readcol,@readname,@readformat
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ctLoc= 0;
    $tmpct=0;
    while ( <$fhLoc2> ) {	# ------------------------------
	++$tmpct;		# header  
	if ( /^\#/ ) { 
	    $READHEADER.= "$_";
	    next; }
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){
		    $readnum[$it]=$it;
		    $READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name"; }
	    next; }
				# ------------------------------
				# skip format?
	if ($ctLoc==2 && $rd!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc; }
	if ($ctLoc==2) {	# read format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; }
	    next; }
				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	foreach $it (1..$#readnum){
	    next if (! defined $tmpar[$readnum[$it]]); 
	    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }
    }
				# ------------------------------
				# massage FORMAT/COL/NAME
    foreach $it (1..$#READCOL){
	$READFORMAT[$it]=~ s/^\s+//g   if (defined $READFORMAT[$it]);
	$READFORMAT[$it]=~ s/\t$|\n//g if (defined $READFORMAT[$it]);
	$READNAME[$it]=~ s/^\s+//g     if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g        if ($#READNAME>0); 
	$READCOL[$it] =~ s/\t$|\n//g;  # correction: last not return!
    }
}				# end of rdRdbAssociativeNum

#===============================================================================
sub read_rdb_num {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[=1 ; 
#----------------------------------------------------------------------
#   read_rdb_num                reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read
#         $readheader:          returns the complete header as one string
#         @readcol:             returns all columns to be read
#         @readname:            returns the names of the columns
#         @readformat:          returns the format of each column
#----------------------------------------------------------------------
    $readheader=""; 
    $#readcol=$#readname=$#readformat=0;

    for ($it=1; $it<=$#readnum; ++$it) { 
	$readcol[$it]=$readname[$it]=$readformat[$it]=""; 
    }
				# ------------------------------
				# read file
    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {		              # header  
	    $readheader .= "$_"; }
	else {		              # rest:
	    ++$ct;
	    if ( $ct >= 3 ) {	              # col content
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
                    if (defined $tmpar[$readnum[$it]]){
                        $readcol[$it].= $tmpar[$readnum[$it]] . " ";}}}
	    elsif ( $ct == 1 ) {              # col name
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
                    if (defined $tmpar[$readnum[$it]]){
                        $readname[$it].= $tmpar[$readnum[$it]];}} }
	    elsif ( $ct == 2 ) {	      # col format
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos= $readnum[$it];
                    if (defined $tmpar[$readnum[$ipos]]){
                        $tmp= $tmpar[$ipos]; $tmp =~ s/\s//g;
                        $readformat[$it].= $tmp . " ";}}}
	}
    } 
    for ($it=1; $it<=$#readname; ++$it) {
	$readcol[$it] =~ s/^\s+//g;	      # correction, if first characters blank
	$readformat[$it] =~ s/^\s+//g; $readname[$it] =~ s/^\s+//g;
	$readcol[$it] =~ s/\n//g;	      # correction: last not return!
	$readformat[$it] =~ s/\n//g; $readname[$it] =~ s/\n//g; 
    }
}				# end of read_rdb_num

#===============================================================================
sub read_rdb_num2 {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   read_rdb_num2               reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME= 0;
    foreach $it (1..$#readnum){
	$READCOL[$it]=""; }
    $ct= 0;
				# --------------------------------------------------
				# read file
				# --------------------------------------------------

    while ( <$fh> ) {
				# ------------------------------
				# header
	if ( $_=~/^\#/ ) {
	    $READHEADER.= "$_";
	    next;}
	++$ct;			# rest
	$_=~s/\n//g;
				# ------------------------------
				# read formats
	if ($ct==2 && 
	    ($_!~/\dN[\s\t]+/ && $_!~/S[\s\t]+/ && $_!~/F[\s\t]+/)){
	    if ($_=~/\t\d+[NSF]|\d+[NSF]\t/){
		@tmpar=split(/\t/,$_);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		    $READFORMAT[$it]=$tmp;
		}
		next;}
	    else {		# no format given, read line
		++$ct;
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    if (defined $tmpar[$readnum[$it]]) {
			$READCOL[$it].=$tmpar[$readnum[$it]] . "\t";}}
				# continue to read if no format
	    }}

				# ------------------------------
	if ( $ct >= 3 ) {	# col content
	    @tmpar=split(/\t/,$_);
	    for ($it=1; $it<=$#readnum; ++$it) {
		if (defined $tmpar[$readnum[$it]]) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }} }

				# ------------------------------
	elsif ( $ct==1 ) {	# col name
	    $_=~s/\t$//g;@tmpar=split(/\t/,$_);
				# care about wild card
	    if ( ($#readnum==0)||($readnum[1]==0) ) {
		for ($it=1;$it<=$#tmpar;++$it) {$readnum[$it]=$it;}
		for ($it=1;$it<=$#tmpar;++$it) {$READCOL[$it]=""; } }
	    
	    for ($it=1; $it<=$#readnum; ++$it) {$tmp_name=$tmpar[$readnum[$it]];
						$tmp_name=~s/\s|\n//g;
						$READNAME[$it]="$tmp_name";} }
    }
				# ------------------------------
				# change arrays
    for ($it=1; $it<=$#READNAME; ++$it) {
	if (!defined $READFORMAT[$it]){
	    print "-*- WARN lib-br.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";}
	$READFORMAT[$it]=~ s/^\s+//g;
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READNAME[$it]=~s/^\s+//g if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g   if ($#READNAME>0);
    }
}				# end of read_rdb_num2

#===============================================================================
sub wrtRdb2HtmlHeader {
    local ($fhout,$scriptNameLoc,$fileLoc,$LlinkLoc,$LaveLoc,$colNamesLoc,@headerLoc) = @_ ;
    local (@colNamesLoc,$Lnotation,$LlinkHere,$col,@namesLink);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlHeader		write the HTML header
#       in:	                $fhout,$fileLoc,$LlinkLoc,$colNamesLoc,@headerLoc
#                               where colName="name1,name2,"
#                               and @headerLoc contains all lines in header
#       out:                  @nameLinks : names of columns with links (i.e.
#                               found as NOTATION in header line
#--------------------------------------------------------------------------------
    $#namesLink=0;

    $colNamesLoc=~s/^,*|,*$//g;
    @colNamesLoc=split(/,/,$colNamesLoc);

    print $fhout 
	"<HTML>\n",
	"<TITLE>Extracted from $fileLoc </TITLE>\n",
	"<BODY>\n",
	"<H1>Results from $scriptNameLoc</H1>\n",
	"<H3>Extraction of data from RDB file '$fileLoc' </H3>\n",
	"<P><P>\n",
	"<UL>\n",
	"<LI><A HREF=\"\#HEADER\">RDB header<\/A>\n",
	"<LI><A HREF=\"\#BODY\">RDB table<\/A>\n";
    if ($LaveLoc){
	print $fhout "<LI><A HREF=\"\#AVERAGES\">Averages over columns<\/A>\n";}
	    
    print $fhout 
	"<\/UL>\n",
	"<P><P>\n",
	"<HR>\n",
	"<P><P>\n",
	"<A NAME=\"HEADER\"><H2>RDB header</H2><\/A>\n",
	"<P><P>\n";

    print $fhout "<PRE>\n";
    $Lnotation=0;
    foreach $_(@headerLoc){
	$LlinkHere=0;
	if (/NOTATION/){ $Lnotation=1;}
	if ($Lnotation){
	   foreach $col(@colNamesLoc){
		if (/^\#\s*$col\W/){ 
		    $colFound=$col;$LlinkHere=1;
		    push(@namesLink,$col);
		    last;}}
	   if ($LlinkLoc && $LlinkHere){ 
		print $fhout "<A NAME=\"$colFound\">";}}
	print $fhout "$_";
	if ($LlinkHere){
	   print $fhout "</A>";}
	print $fhout "\n";}
    print $fhout "\n</PRE>\n";
    print $fhout "<BR>\n";
    return(@namesLink);
}				# end of wrtRdb2HtmlHeader

#===============================================================================
sub wrtRdb2HtmlBody {
    local ($fhout,$LlinkLoc,%bodyLoc) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBody		writes the body for a RDB->HTML file
#       in:	                $fhout,$LlinkLoc,%bodyLoc
#                               where $body{"it","colName"} contains the columns
#--------------------------------------------------------------------------------
    print $fhout 
	"<P><P><HR><P><P>\n\n",
	"<A NAME=\"BODY\"><H2>RDB table</H2><\/A>\n",
	"<P><P>\n";
				# get column names
    $bodyLoc{"COLNAMES"}=~s/^,*|,*$//g;
    @colNames=split(/,/,$bodyLoc{"COLNAMES"});

    print $fhout "<TABLE BORDER>\n";
				# ------------------------------
    				# write column names with links
    &wrtRdb2HtmlBodyColNames($fhout,@colNames);

				# ------------------------------
				# write body
    $LfstAve=0;
    foreach $it (1..$body{"NROWS"}){
	print $fhout "<TR>   ";
	foreach $itdes (1..$#colNames){
				# break for Averages
	    if ( ($itdes==1) && (! $LfstAve) &&
		($body{$it,"$colNames[1]"} =~ /^ave/) ){
		$LfstAve=1;
		&wrtRdb2HtmlBodyAve($fhout,@colNames);}
		    
	    if (defined $body{$it,"$colNames[$itdes]"}) {
	    	print $fhout "<TD>",$body{$it,"$colNames[$itdes]"};}
	    else {
		print $fhout "<TD>"," ";}}
	print $fhout "\n";}

    print $fhout "</TABLE>\n";
}				# end of wrtRdb2HtmlBody

#===============================================================================
sub wrtRdb2HtmlBodyColNames {
    local ($fhout,@colNames)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBodyColNames     writes the column names (called by previous)
#       in GLOBAL:		%bodyLoc
#       in:                     $fhout,@colNames
#--------------------------------------------------------------------------------
    print $fhout "<TR>  ";
    foreach $des (@colNames){
	print $fhout "<TH>";
	if ($LlinkLoc && $bodyLoc{"link","$des"}){
	    print $fhout "<A HREF=\"\#$des\">";}
	print $fhout $des," ";
	if ($LlinkLoc && $bodyLoc{"link","$des"}){
	    print $fhout "</A>";}
    }
    print $fhout "\n";
}				# end of wrtRdb2HtmlBodyColNames

#===============================================================================
sub wrtRdb2HtmlBodyAve {
    local ($fhout,@colNames)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBodyAve          inserts a break in the table for the averages at end of
#                               all rows
#       in:		        $fhout,@colNames
#--------------------------------------------------------------------------------
    foreach $_(@colNames){
	print $fhout "<TD>  ";}print $fhout "\n";
    print $fhout 
	"</TABLE>\n<P><HR><P>\n",
	"<P><P>\n",
	"<A NAME=\"AVERAGES\"><H4> Averages </H4><\/A><P>\n",
	"<TABLE BORDER>\n";

    &wrtRdb2HtmlBodyColNames($fhout,@colNames);
    print $fhout "<TR>   ";
}				# end of wrtRdb2HtmlBodyAve

1;
