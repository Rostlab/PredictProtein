#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# hssp_extract_pdb
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hssp_extract_pdb.pl hssp_file (or list)
#
# task:		extracts sequences with PDB id from HSSP files
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       March	,       1995           #
#			changed:       May	,    	1996           #
#			changed:       November	,    	1996           #
#			changed:       January	,    	1997           #
#	EMBL			       Version 0.1                     #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[ =1 ;
				# --------------------------------------------------
				# include libraries
				# --------------------------------------------------
push (@INC, "/home/rost/perl") ;
# require "ctime.pl"; # require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
&hssp_extract_pdb_ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# ------------------------------
				# read id's to exclude
$#excl=0;
if ($file_excl ne "unk"){
    &open_file("$fhin", "$file_excl");
    while(<$fhin>){if (/\#/){next;}
		   $_=~s/\n|\s//g;$_=~s/^.*\///g;$_=~s/\.[hdf]ssp.$//g;
		   if (length($_)<4){next;}
		   push(@excl,$_);}close($fhin);
    foreach $excl(@excl){$flag{"$excl"}=1;}}
				# ------------------------------
				# handle list
$#hssp_file=0;
if ($Lis_list) {
    &open_file("$fhin", "$file_in");
    while ( <$fhin> ) { $tmp=$_;$tmp=~s/\n//g;
			if (length($tmp)==0) {next;}
			push(@hssp_file,$tmp); }
    close($fhin); }
else { push(@hssp_file,$file_in); }

				# ------------------------------
				# now extract
&open_file("$fhout", ">$file_out");
&open_file("$fhout2", ">$file_out2");
&open_file("$fhout3", ">$file_out3");
print $fhout "# Perl-RDB\n";
print $fhout "# \n";
print $fhout "# pos1\t counts files read\n";
print $fhout "# pos2\t counts proteins with known structure found\n";
print $fhout "# id1\t PDB id of guide sequence\n";
print $fhout "# id2\t PDB id of aligned sequence\n";
print $fhout "# %IDE\t percentage pairwise sequence identity\n";
print $fhout "# \n";
printf $fhout "%4s\t%4s\t%6s\t%6s\t%4s\n","pos1","pos2","id1","id2",'%IDE';
printf $fhout "%4s\t%4s\t%6s\t%6s\t%4s\n","4N","4N","6","6","4N";
$#id=0;$ctFileOk=$ctWithPdb=$ctAllPdb=0;
for ($it=1;$it<=$#hssp_file;++$it) {
    $ct=0;
    if (! -e $hssp_file[$it] ) {next;}

    ++$ctFileOk;		# count all hssp files
    &open_file("$fhin", "$hssp_file[$it]");
    $#idFoundHere=0;		# list of PDBids found in current
				# skip everything before list of aligned sequences
    $id1=$hssp_file[$it];$id1=~s/.*\///g;$id1=~s/\.hssp.*//g;
    $LisLongId=0;
    while ( <$fhin> ) { 
	last if (/^  NR\./);
	if (/^PARAMETER  LONG-ID :YES/) {$LisLongId=1;}}
    while ( <$fhin> ) {
	last if (/^\#\# ALI/);	# skip everything after list
	$tmp=$_;$tmp=~s/\n//g;
	if (length($tmp)==0) {
	    next;}
	if ($LisLongId){
	    $tmp2=substr($_,49,6);$tmp2=~s/\s//g;$tmp2=~tr/[A-Z]/[a-z]/;}
	else {
	    $tmp2=substr($_,21,6);$tmp2=~s/\s//g;$tmp2=~tr/[A-Z]/[a-z]/;}
	if ( (length($tmp2)>1) && ($tmp2 ne $id1) ) {
	    ++$ct;
	    if ($tmp2=~/_/){$tmp2a=$tmp2;$tmp2a=~s/_.//g;$tmp2b=$tmp2;$tmp2b=~s/^.*_//g;
			     $tmp2b=~tr/[a-z]/[A-Z]/;
			     $tmp2="$tmp2a"."_"."$tmp2b";}
	    push(@id,$tmp2);push(@idFoundHere,$tmp2);
	    $tmpperc=substr($tmp,29,4);$tmpperc=~s/\s//g;$tmpperc=100*$tmpperc;
	    if ((defined $flag{"$tmp2"})&&($flag{"$tmp2"})){ # exclude some
		next;}
	    if ($Lscreen){
		printf "%-4d\t%-4d\t%-6s\t%-6s\t%4d\n",$it,$ct,$id1,$tmp2,$tmpperc;}
	    printf $fhout "%-4d\t%-4d\t%-6s\t%-6s\t%4d\n",$it,$ct,$id1,$tmp2,$tmpperc;
	    if ($tmp2 =~/_\?/){$tmp2=~s/_\?//g;}
	    printf $fhout2 "$id1\t$tmp2\n";
	} } close($fhin);
				# all id's found into one row
    if ($#idFoundHere>0){++$ctWithPdb;}
    $ctAllPdb+=$#idFoundHere;
    printf $fhout3 "%-s\t%5d\t",$id1,$#idFoundHere;
    foreach $idFoundHere(@idFoundHere){print $fhout3 "$idFoundHere,";}
    print  $fhout3 "\n";
}
printf $fhout3 "%-s\t%5d\t%6d\n","tot($ctFileOk)",$ctWithPdb,$ctAllPdb;
if (($ctFileOk>0)&&($ctWithPdb>0)){
    printf $fhout3 
	"%-s\t%5.1f\t%6.1f\n","per",(100*$ctWithPdb/$ctFileOk),(100*$ctAllPdb/$ctWithPdb);
}
close($fhout);close($fhout2);close($fhout2);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { &myprt_empty;&myprt_line;&myprt_txt(" $script_name has ended fine .. -:\)"); 
		&myprt_txt(" output in files: \t $file_out, $file_out2, $file_out3"); }
if ($#hssp_file==1){
    print"--- PDB id's found for $hssp_file[1]:\n";
    &myprt_array(",",@id);}
exit;

#==========================================================================================
sub hssp_extract_pdb_ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 

    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "hssp_extract_pdb";
    $script_input=  "hssp_file (or list)";
    $script_goal=   "extracts sequences with PDB id from HSSP files";
    $script_narg=   1;
    @script_goal=   (" ",
		     "Task: \t $script_goal",
		     " ",
		     "Input:\t $script_input",
		     " ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$script_name help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("excl=",
		     "not_screen",
		     "file_out=",
		     "dir_in=",
		     "dir_out=",
		     "dir_work=",
		     );
    @script_opt_keydes= 
	            ("file with id's to exclude (in final list: directories and extensions ok)",
		     "no information written onto screen",
		     "output file name",
		     "input dir name,   default: local",
		     "output dir name,  default: local",
		     "working dir name, default: local",
		     );

    if ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) { &myprt_txt("$txt"); } &myprt_empty; 
	&myprt_txt("usage: \t $script_name $script_input"); 
	&myprt_empty;&myprt_txt("optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    print"--- $script_opt_key[$it] \t $script_opt_keydes[$it] \n"; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){&myprt_txt("$txt");}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
				# --------------------
				# directories
    $dir_in=    "";
    $dir_out=   "";
    $dir_work=  "";
				# --------------------
				# files
				# file extensions
				# file handles
    $fhin="FHIN";$fhout="FHOUT";$fhout2="FHOUT2";$fhout3="FHOUT3";
				# --------------------
				# logicals
    $Lscreen=   1;		# blabla on screen
				# --------------------
				# executables

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $file_in=   $ARGV[1];
				# output file
    $tmp=$file_in;$tmp=~s/^.*\///g;
    $file_out=  "Out-". $tmp; 
    $file_out2= "Out2-".$tmp; 
    $file_out3= "Out3-".$tmp; 
    $file_excl= "unk";

				# is it single HSSP file or list?
    &open_file("$fhin", "$file_in");
    $Lis_list=1;
    while ( <$fhin> ) { if (/^HSSP/) { $Lis_list=0; }
			last; }
    close($fhin);

    if ($#ARGV>$script_narg) {
	for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	    $_=$ARGV[$it];
	    if ( /not_screen/ ) { $Lscreen=0; }
	    elsif ( /file_out=/ ){ $tmp=$ARGV[$it];$tmp=~s/\n|file_out=//g; 
				   $file_out=$tmp; }
	    elsif ( /dir_in=/ ) {  $tmp=$ARGV[$it];$tmp=~s/\n|dir_in=//g; 
				   $dir_in=$tmp; }
	    elsif ( /dir_out=/ ) { $tmp=$ARGV[$it];$tmp=~s/\n|dir_out=//g; 
				   $dir_out=$tmp; }
	    elsif ( /dir_work=/ ){ $tmp=$ARGV[$it];$tmp=~s/\n|dir_work=//g; 
				   $dir_work=$tmp; }
	    elsif (/^excl=/)     { $_=~s/^excl=|\n|\s//g;
				   $file_excl=$_;}
	}
    }

    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    if (length($dir_in)>1) {   &complete_dir($dir_in);$dir_in=$DIR;
			       $tmp=$file_in; $file_in="$dir_in"."$tmp";}
    if (length($dir_out)>1) {  &complete_dir($dir_out);$dir_out=$DIR;
			       $tmp=$file_out; $file_out="$dir_out"."$tmp";}
    if (length($dir_work)>1) { &complete_dir($dir_work);$dir_work=$DIR; }

    if ($Lscreen) { &myprt_line; &myprt_txt("perl script that $script_goal"); 
		    &myprt_empty; &myprt_txt("file_in: \t \t $file_in"); 
		    &myprt_txt("end of setting up,\t let's work on it"); 
		    &myprt_empty; &myprt_line; &myprt_empty; }

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($file_in)>0) && (! -e $file_in) ) {
	&myprt_empty;&myprt_txt("ERROR $script_name:\t file_in '$file_in' does not exist");exit;}
    if ( ($file_excl ne "unk") && (!-e $file_excl) ){
	&myprt_txt("ERROR $script_name:\t file_excl '$file_excl' does not exist");exit;}

}				# end of hssp_extract_pdb_ini

