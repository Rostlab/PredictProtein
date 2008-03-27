#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#----------------------------------------------------------------------
# pdbid_sort
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	pdbid_sort.pl list_of_files
#
# task:		sorts a list of HSSP/PDB/DSSP/FSSP files according to letter 
#               (instead of number of PDBID)
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       June	,       1995           #
#			changed:       .	,    	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "/home/rost/pub/phd/scr/lib-ut.pl"; require "/home/rost/pub/phd/scr/lib-br.pl";
				# initialise variables
&ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# read list
&open_file("$fhin", "$file_in");
$Lswiss=0;
$#tmp=$#tmp3=0;
while (<$fhin>) {		# check whether PDBID or SWISSPROT
    $tmp=$_;$tmp=~s/\n//g;
    if (length($tmp)==0) { next; }
    $tmp1=$tmp;$tmp1=~s/.*\/|\.hssp|\.dssp|\.fssp|\.pdb|\.pred|\.phd|\.rdb.*$|\.exp//g;
    $tmp1=~s/^Extr_all_//g;
    $tmp3=$tmp1;
    $tmp3=~s/^([^\s]*) .*/$1/g;
    if ($tmp3 !~/^\d\w\w\w/){
	$Lswiss=1;}
    push(@tmp3,$tmp3);		# no dir, no extension, no nothing
    push(@tmp,$tmp);		# full file or id
}
close($fhin);
foreach $it (1..$#tmp) {		# now store 
    $tmp=$tmp[$it];$tmp3=$tmp3[$it];
    if (! $Lswiss){
	$tmp2=substr($tmp3,2);}	# pdb: throw version number
    else {
	$tmp2=$tmp3;}
    $rd{"$tmp"}=$tmp2;
    print"x.x '$tmp', '$tmp2',\n";
    push(@rd,$tmp); }		# full file or id

@sorted=sort values(%rd);	# sort
				# ------------------------------
				# write sorted
undef %tmp;
&open_file("$fhout", ">$file_out");
foreach $sorted (@sorted){
    foreach $rd (@rd){
	next if (defined $tmp{"$rd"});
	if ($rd{"$rd"} eq $sorted){
	    $tmp{"$rd"}=1;
	    print $fhout "$rd\n";
	    print "$rd\n";}
    }
}
close($fhout);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { &myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 
		&myprt_empty; &myprt_txt(" output in file: \t $file_out"); }

exit;

#==========================================================================================
sub ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#
    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "pdbid_sort";
    $script_input=  "list_of_files";
    $script_goal=   "sorts a list of HSSP/PDB/DSSP/FSSP files according to letter ".
	"(instead of number of PDBID)";
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
    @script_opt_key=(" ",
		     "not_screen",
		     "file_out=",
		     "dir_in=",
		     "dir_out=",
		     "dir_work=",
		     );
    @script_opt_keydes= 
	            (" ",
		     "no information written onto screen",
		     "output file name",
		     "input dir name,   default: local",
		     "output dir name,  default: local",
		     "working dir name, default: local",
		     );

    if ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){if($txt !~ /Done:/){&myprt_txt("$txt");}}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    elsif ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_empty;&myprt_txt("Optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf "--- %-12s %-s \n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    
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
    $fhout=     "FHOUT";
    $fhin=      "FHIN";
				# --------------------
				# further

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
    $file_out=  $file_in."_sorted"; 

    foreach $arg (@ARGV){
	next if ($arg eq $ARGV[1]);
	if    ($_=~/not_screen/ )   { $Lscreen=0; }
	elsif ($_=~/file_out=(.*)/) { $file_out=$1; }
	elsif ($_=~/fileOut=(.*)/)  { $file_out=$1; }
	elsif ($_=~/dir_in=(.*)/)   { $dir_in=$1; }
	elsif ($_=~/dir_out=(.*)/)  { $dir_out=$1; }
	elsif ($_=~/dir_work=(.*)/) { $dir_work=$1; } }

    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    if (length($dir_in)>1) {   &complete_dir($dir_in);$dir_in=$DIR;
			       $tmp=$file_in; $file_in="$dir_in"."$tmp";}
    if (length($dir_out)>1) {  &complete_dir($dir_out);$dir_out=$DIR;
			       $tmp=$file_out; $file_out="$dir_out"."$tmp";}
    if (length($dir_work)>1) { &complete_dir($dir_work);$dir_work=$DIR; }

    if ($Lscreen) { &myprt_line; &myprt_txt("$script_goal"); &myprt_empty; 
		    &myprt_txt("file_in: \t \t $file_in"); 
		    &myprt_txt("file_out:\t \t $file_out"); 
		    &myprt_txt("end of setting up,\t let's work on it"); 
		    &myprt_empty; &myprt_line; &myprt_empty; }

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($file_in)>0) && (! -e $file_in) ) {
	&myprt_empty;&myprt_txt("ERROR $script_name:\t file_in '$file_in' does not exist");exit;}

}				# end of ini
