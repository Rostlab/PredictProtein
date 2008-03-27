#!/usr/bin/perl
##!/bin/env perl
##!/usr/bin/perl -w
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
#------------------------------------------------------------------------------#
#	Copyright				Jun,        	1995	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 1.0   	Oct,    	1998	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# initialise variables
&ini();

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
	if    ($_=~/not_?screen/i ) { $Lscreen=0; }
	elsif ($_=~/^verb(ose)?$/ ||
	       $_=~/^de?bu?g$/)     { $Lscreen=1; }
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

#==============================================================================
# library collected (begin)
#==============================================================================

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

#==============================================================================
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#==============================================================================
sub myprt_line  {
    local($fhx)=@_;
#   myprt_line                  prints a line with 70 '-'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "-" x 70,"\n","--- \n";
}				# end of myprt_line

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
sub complete_dir { return(&completeDir(@_)); } # alias

#===============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir

#==============================================================================
# library collected (end)
#==============================================================================

