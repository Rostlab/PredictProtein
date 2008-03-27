#!/usr/sbin/perl 
#----------------------------------------------------------------------
# extracts a chain from an HSSP file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	"hssp_chain_length.pl list_of_files (1xyz.hssp_CHAIN)
#               note single file: recognised by '.hssp'
#
# task:		extracting from an HSSP file one chain
#
#----------------------------------------------------------------------
#                                                                      #
#----------------------------------------------------------------------#
#	Burkhard Rost			January, 	1995           #
#			changed:		,      	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name = "hssp_chain_length.pl"; $script_input= "list_of_hssp_files (1xyz.hssp_Chain)";

push (@INC, "/home/rost/perl") ;
# require "ctime.pl"; # require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl";

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 1) {print "*** ERROR: \n*** usage: \t $script_name $script_input \n";
		 print "number of arguments:  \t$ARGV \n"; exit; }

#----------------------------------------
#  read input
#----------------------------------------
$file_list= $ARGV[1]; &myprt_txt("file here: \t \t $file_list"); 

#------------------------------
# defaults
#------------------------------
$file_out=$file_list;$file_out=~s/\s//g;$file_out=~s/.*\///g;$file_out=~s/\.list//g;
$tmp=$file_out;$file_out="Out_"."$tmp";$fhout="FHOUT";

#----------------------------------------
# read file
#----------------------------------------
				# ------------------------------
				# single or list?
				# ------------------------------
if ($file_list =~ /\.hssp/) { print "--- assumed is a single file=$file_list,\n";
			      push(@file_hssp,$file_list); }
else { 
    if (-e $file_list) {
	&open_file("FHIN", "$file_list");
	while ( <FHIN> ) { $tmp=$_; $tmp=~s/\s|\n//g;
			   if (length($tmp)>1) { push(@file_hssp,$tmp);}}
	close(FHIN); } 
    else { print "*** ERROR file '$file_list' missing\n";exit;} }
    

				# --------------------------------------------------
				# now doing job for list
				# --------------------------------------------------
&open_file($fhout, ">$file_out");
foreach $i (@file_hssp) {
    $i=~s/\s//g;$i=~s/\n//g;
    $file_hssp=$i; $file_hssp=~s/(.+\.hssp)_?(.)?/$1/g;
    $chain=$i; $chain=~s/(.+\.hssp)_?(.)?/$2/g;
    if (length($chain)==0){$chain="*";}
    $ct=&hsspGetChainLength($file_hssp,$chain);
    printf $fhout "%-30s %1s %5d\n",$file_hssp,$chain,$ct;
    printf "%-30s %1s %5d\n",$file_hssp,$chain,$ct;
}
close($fhout);
print"--- output in \t\t $file_out\n";

exit;

#==========================================================================================
sub hsspGetChainLength {
    local ($fileIn,$chainLoc) = @_ ;
    local ($file_hssp,$ct,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hsspGetChainLength         extracts the length of a chain in an HSSP file
#       in:                     hssp_file,chain,
#       out:                    length
#--------------------------------------------------------------------------------
    $fileIn=~s/\s//g;$fileIn=~s/\n//g;
    $file_hssp=$fileIn; if ($chainLoc eq "*"){$Lchain=0;}else{$Lchain=1;}
    if (! -e $file_hssp) { print "*** '$fileIn', the hssp file missing\n"; return(0);}
    &open_file("FHIN", "$file_hssp");
    while ( <FHIN> ) { last if (/^ SeqNo/); }
    $ct=0;
    while ( <FHIN> ) { last if (/^\#\# /);
		       $tmp=substr($_,13,1);
		       if    ( $Lchain && ($tmp eq $chainLoc) ) { ++$ct; }
		       elsif ( ! $Lchain )                      { ++$ct; }}close(FHIN);
    return($ct);
}				# end of hsspGetChainLength

