#!/usr/bin/perl -w
##!/usr/sbin/perl -w
##!/usr/pub/bin/perl -w
#----------------------------------------------------------------------
# xscriptname
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	xscriptname.pl xscriptin
#
# task:		reads the FSSP table families
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       April	,       1995           #
#			changed:       .	,    	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# include libraries
#push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
#require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
                                # defaults
$fhin=    "FHIN";
$fhout=   "FHOUT";$fhout2=  "FHOUT2";
$file_out=     "fssp-unique.list";
$fileDsspAll=  "dssp-all.list";
$fileDsspAllNo="dssp-all-noChain.list";
$fileHsspAll=  "hssp-all.list";
$fileHsspAllNo="hssp-all-noChain.list";
$fileHsspUni=  "hssp-uni.list";
$fileHsspUniNo="hssp-uni-noChain.list";

$level=       1;                    # number of levels of tree read
$max_level=   6;                   # maximal level in table
$Lcheck_level=1;

$file_in=$ARGV[1]; if ($#ARGV<1){print "input:   1 \t TABLE1 from /data/fssp \n";
                                 print "optional:2 \t n, take level (def=$level)\n";
				 print "           \t highest level 6\n";
#				 print"***        \t is a lie, not implemented!\n";
                                 exit;}
$level=$ARGV[2] if ($#ARGV>1);
$Lcheck_level=0                  if ($level>=$max_level);

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------

open($fhin, $file_in);
while (<$fhin>) {               # read until "Family index"
    last if ($_=~/Family index/); }
$ct[$level]=$#idall=0;
while (<$fhin>) {
    next if ($_ !~ /^\s*\d*\./); # must start with 'blanks number'
    $_=~s/^\s*|\s*\n$//g;	# purge leading blanks
#    $line=$_;
                                # everything before SWISS name
    $tmp=$_;$tmp=~s/([\d\.]*\s+\S*).+/$1/;
    $name=$_;$name=~s/$tmp\s*//g; # SWISS name
    $name=~s/\(.+\)//g;$name=~s/\s\s+/ /g;   # purge (E.C. asf) and double blanks
    $name=~s/\"//g;		# purge double quotes '"'
    @tmp=split(/ +/,$tmp);      # seperate number and PDBID
    $num=$tmp[1];$num=~s/\s//g;
    $id=$tmp[2]; $id=~s/\s|[_-]//g;
    @num=split(/\./,$num);      # seperate levels
    $Lok=1;                     # take it if all counters > level =1
    if ($Lcheck_level) {
	foreach $i (($level+1)..$max_level) { 
	    $num[$i]=10             if ($num[$i]=~/\D/);
	    print "xx i=$i, (level)num=$num[$i],\n";
	    if ($num[$i] != 1) {
		$Lok=0;
		last;} }
	if ( $Lok && ( ! defined $L1st{"$num[1]"} ) ) {
	    $L1st{"$num[1]"}=1;
	    ++$ct[$level];
	    $id{"$level","$ct[$level]"}=$id;
	    $name{"$level","$ct[$level]"}=$name;}
    }
    else {
	++$ct[1];
	$name{"1",$ct[1]}=$name;
	$id{"1",$ct[1]}=$id;}
    push(@idall,$id);
}
close($fhin);
                                # print info read
print "read:\n";
foreach $ct (1..$ct[$level]) {
    print "$ct\t",$id{"$level","$ct"},"\t",$name{"$level","$ct"},"\n";
}

				# --------------------------------------------------
				# write fssp
                                # sort fssp ids
$#tmp=0;
foreach $ct (1..$ct[$level]) {
    push(@tmp,$id{"$level","$ct"});}
print "--- read tmp=",join(",",@tmp,"\n");
@id=&sort_by_pdbid(@tmp);

				# ------------------------------
				# write into file: unique FSSP
open($fhout, ">".$file_out);
foreach $id (@id){ 
    print $fhout "/data/fssp/$id",".fssp\n";}close($fhout);

				# --------------------------------------------------
				# write dssp
                                # sort dssp ids
@idUni=@id;
@id=&sort_by_pdbid(@idall);
foreach $id (@id){ print "$id,";}print"\n"; # 
				# ------------------------------
				# write into file : all DSSP
&open_file("$fhout", ">$fileDsspAll");&open_file("$fhout2", ">$fileDsspAllNo");
undef %tmp;
foreach $id (@id){ 
    $idx=substr($id,1,4);$tmp="$idx".".dssp";
    if (length($id)>4){$chainHere=substr($id,5,1);}else{$chainHere="unk";}
    ($file,$chainRd)=&dsspGetFile($tmp,1);
    if (($file ne "0")&&(defined $chainRd)&&
	(length ($chainRd)>0)&&($chainRd ne $chainHere)&&($chainHere ne "unk")){
	print "-?- \t from dsspGetFile: chainRd=$chainRd, local chainHere=$chainHere,\n";}
    if (-e $file){
	if (! defined $tmp{$file}){
	    $tmp{$file}=1;
	    print $fhout2 "$file\n";} # no chain
	if ($chainHere ne "unk"){$tmp2=$file."_"."$chainHere";}else{$tmp2=$file;}
	print $fhout $tmp2,"\n";}
    else {
	print "*   missing DSSP in=$tmp, out dsspGetFile=$file,\n";}}
close($fhout);close($fhout2);
				# ------------------------------
				# unique HSSP (write)
&open_file("$fhout", ">$fileHsspUni");&open_file("$fhout2", ">$fileHsspUniNo");
undef %tmp;
foreach $id (@idUni){ 
    $idx=substr($id,1,4);$tmp="$idx".".hssp";
    if (length($id)>4){$chainHere=substr($id,5,1);}else{$chainHere="unk";}
    ($file,$chainRd)=&hsspGetFile($tmp,1);
    if (($file ne "0")&&(length ($chainRd)>0)&&($chainRd ne $chainHere)&&($chainHere ne "unk")){
	print "-?- \t from hsspGetFile: chainRd=$chainRd, local chainHere=$chainHere,\n";}
    if (-e $file){
	if (! defined $tmp{$file}){
	    $tmp{$file}=1;
	    print $fhout2 "$file\n";} # no chain
	print $fhout2 "$file\n"; # no chain
	if ($chainHere ne "unk"){$tmp2=$file."_!_"."$chainHere";}else{$tmp2=$file;}
	print $fhout $tmp2,"\n";}
    else {
	print "*   missing HSSP in=$tmp, out hsspGetFile=$file,\n";}}close($fhout);close($fhout2);

				# ------------------------------
				# all HSSP (write)
&open_file("$fhout", ">$fileHsspAll");
&open_file("$fhout2", ">$fileHsspAllNo");
undef %tmp;
foreach $id (@id){ 
    $idx=substr($id,1,4);$tmp=$idx.".hssp";
    if (length($id)>4){$chainHere=substr($id,5,1);}else{$chainHere="unk";}
    ($file,$chainRd)=
	&hsspGetFile($tmp,1);
				# file ok?
    if ($file ne "0" && length ($chainRd)>0 &&
	$chainRd ne $chainHere && $chainHere ne "unk"){
	print "-?- \t from hsspGetFile: chainRd=$chainRd, local chainHere=$chainHere,\n";}
    if (-e $file){
				# no chain unique
	if (! defined $tmp{$file}){
	    $tmp{$file}=$file;
	    print $fhout2 "$file\n"; }
				# build up name with chain
	if ($chainHere ne "unk"){$tmp2=$file."_"."$chainHere";}else{$tmp2=$file;}
	print $fhout $tmp2,"\n";}}close($fhout);close($fhout2);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
&myprt_txt(" ended fine .. -:\)"); 
&myprt_txt(" output in file: \t $file_out"); 
&myprt_txt(" dssp in file:   \t $fileDsspAll,$fileDsspAllNo"); 
&myprt_txt(" Hssp in files:  \t $fileHsspAll,$fileHsspAllNo,$fileHsspUni,$fileHsspUniNo"); 


exit;


#==============================================================================
# library collected (begin)
#==============================================================================


#===============================================================================
sub complete_dir { return(&completeDir(@_)); } # alias

#===============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir

#==============================================================================
sub dsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileDssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dsspGetFile                 searches all directories for existing DSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($dssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.dssp not found -> try 1prc.dssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
    if (-d $Lscreen) { 
	@dir=($Lscreen,@dir);
	$Lscreen=0;}
    $dsspFileTmp=$fileInLoc;$dsspFileTmp=~s/\s|\n//g;
				# ------------------------------
				# is DSSP ok
    return($dsspFileTmp," ")    if (-e $dsspFileTmp && &is_dssp($dsspFileTmp));

				# ------------------------------
				# purge chain?
    if ($dsspFileTmp=~/^(.*\.dssp)_?([A-Za-z0-9])$/){
	$file=$1; $chain=$2;
	return($file,$chain)    if (-e $file && &is_dssp($file)); }

				# ------------------------------
				# try adding directories

    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/dssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/dssp/") if (!$Lok); # give default

				# loop over all directories
    $fileDssp=
	&dsspGetFileLoop($dsspFileTmp,$Lscreen,@dir);

				# ------------------------------
    if ( ! -e $fileDssp ) {	# still not: dissect into 'id'.'chain'
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.dssp.*)$/$1$2/g;
	$fileDssp=
	    &dsspGetFileLoop($tmp_file,$Lscreen,@dir);}

				# ------------------------------
				# change version of file (1sha->2sha)
    if ( ! -e $fileDssp) {
	$tmp1=substr($idLoc,2,3);
	foreach $it (1..9) {
	    $tmp_file="$it"."$tmp1".".dssp";
	    $fileDssp=
		&dsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
    return (0)                  if ( ! -e $fileDssp);

    return($fileDssp,$chainLoc);
}				# end of dsspGetFile

#==============================================================================
sub dsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_dssp($fileInLoop));
				# missing extension
    $fileInLoop.=".dssp"        if ($fileInLoop !~ /\.dssp/);
				# already ok 
    return($fileInLoop)         if (&is_dssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	print "--- dsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_dssp($tmp) );
    }
    return(0);			# none found
}				# end of dsspGetFileLoop

#==============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
				# passed dir instead of Lscreen
    if (-d $Lscreen) { @dir=($Lscreen,@dir);
		       $Lscreen=0;}
    $fileInLoc=~s/\s|\n//g;
				# ------------------------------
				# is HSSP ok
    return($fileInLoc," ")      if (-e $fileInLoc && &is_hssp($fileInLoc));

				# ------------------------------
				# purge chain?
    if ($fileInLoc=~/^(.*\.hssp)_?([A-Za-z0-9])$/){
	$file=$1; $chainLoc=$2;
	return($file,$chainLoc) if (-e $file && &is_hssp($file)); }

				# ------------------------------
				# try adding directories
    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/hssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/hssp/") if (!$Lok); # give default

				# ------------------------------
				# before trying: purge chain
    $file=$fileInLoc; $chainLoc=" ";
    $file=~s/^(.*\.hssp)_?([A-Za-z0-9])$/$1/; 
    $chainLoc=$2 if (defined $2);
				# loop over all directories
    $fileHssp=
	&hsspGetFileLoop($file,$Lscreen,@dir);
    return($fileHssp,$chainLoc) if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
                                # still not: dissect into 'id'.'chain'
    $tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
    $fileHssp=
        &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
    return($fileHssp,$chainLoc)    if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
				# change version of file (1sha->2sha)
    $tmp1=substr($idLoc,2,3);
    foreach $it (1..9) {
        $tmp_file="$it"."$tmp1".".hssp";
        $fileHssp=
            &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
	last if ($fileHssp ne "0");}
    return (0)                  if ( ! -e $fileHssp || &is_hssp_empty($fileHssp));
    return($fileHssp,$chainLoc);
}				# end of hsspGetFile

#==============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# missing extension
    $fileInLoop.=".hssp"        if ($fileInLoop !~ /\.hssp/);
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	$tmp=~s/\/\//\//g;	# '//' -> '/'
	print "--- hsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_hssp($tmp) );
    }
    return(0);			# none found
}				# end of hsspGetFileLoop

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
    $fh="FHIN_CHECK_DSSP";&open_file("$fh","$fileInLoc");
    while ( <$fh> ) {
	if (/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i){$Lis=1;}else{$Lis=0;}
	last; }close($fh);
    return $Lis;
}				# end of is_dssp

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc) ;
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$Lis=1 if (/^HSSP/) ; 
		     last; }close($fh);
    return $Lis;
}				# end of is_hssp

#==============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#==============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt

#==============================================================================
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

#==============================================================================
sub sort_by_pdbid {
    local (@idLoc) = @_ ;
    local ($id,$des,%tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   sort_by_pdbid               sorts a list of ids by alphabet (first number opressed)
#--------------------------------------------------------------------------------
    undef %tmp;
    foreach $id (@idLoc) {
	$des=substr($id,2).substr($id,1,1);
	$tmp{$des}=$id; }
    $#idLoc=0;
    foreach $keyid (sort keys(%tmp)){
	push(@idLoc,$tmp{$keyid});}
    undef %tmp;
    return (@idLoc);
}				# end of sort_by_pdbid



#==============================================================================
# library collected (end)
#==============================================================================


1;
