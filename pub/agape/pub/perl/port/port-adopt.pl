#!/bin/env perl
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# port-adopt
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	port-adopt old=x1,x2,x3 new=y1,y2,y3
# task:		changes names: x1->y1, x2->y2 and x3->y3
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

&ini();				# initialise variables

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# security backup
$fileNew=$$."x.tmp";
$dirSave=$par{"dirSave"};
if (-e $dirSave){
    unlink($dirSave); }
if (-d $dirSave){		# make it if not there
    system("\\rm -r $dirSave");} # empty if there
if (! -d $dirSave) {
    system("mkdir $dirSave");}

				# ------------------------------
if ($#fileIn>0){		# case: file list passed
    @allTxtFiles=@fileIn;}
				# ------------------------------
else {$#allTxtFiles=0;		# case: read dir
      if (-e $par{"fileList"}){
	  $fileList=$par{"fileList"};
	  &open_file("$fhin","$fileList");
	  while(<$fhin>){$tmp=$_;$tmp=~s/\s|\t|\*$//g;
			 if ((-e $tmp)&&(-T $tmp)){
			     push(@allTxtFiles,$tmp)}}close($fhin);}
      else {
	  $par{"dirFind"}=`pwd` if (length($par{"dirFind"})<2);
	  @allTxtFiles=		# list all text files
	      &lsAllTxtFiles($par{"dirFind"});	# external lib-ut.pl
      } }
    
				# ------------------------------
				# change all files
foreach $fileOld (@allTxtFiles){
    if ($fileOld =~/\.tar/){	# exclude tar files
	next;}
    if ($fileOld =~/^$dirSave/){	# exclude save files
	next;}
    if ($Lscreen)             { print "--- now check \t '$fileOld'\n";}
    &open_file("$fhin","$fileOld");&open_file("$fhout",">$fileNew");$Ldiff=0;
    while(<$fhin>){$line=$_;
		   foreach $it (1..$#old){
		       if ($line=~/$old[$it]/){
			   $line=~s/$old[$it]/$new[$it]/g;
			   $Ldiff=1;}}
		   print $fhout $line;}close($fhin);close($fhout);
    if ($Ldiff){
	$dirSave=$par{"dirSave"}."/";
	$cmd1="\\mv $fileOld $dirSave";
	$cmd2="\\mv $fileNew $fileOld";
	foreach $cmd ($cmd1,$cmd2){
	    system("$cmd");if($Lscreen){print"--- system \t '$cmd'\n";}}}
}	
system("\\rm $fileNew");
exit;				# 

#==========================================================================================
sub ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#
    $PWD=                       $ENV{'PWD'};

    &iniDefaults();             # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp();
				# ------------------------------
				# predefined key words
    $par{"old"}=$par{"new"}="";
    foreach $arg (@ARGV){
	if    ($arg=~/^old=(.+)/){$par{"old"}=$1;}
	elsif ($arg=~/^new=(.+)/){$par{"new"}=$1;}
	last if (length($par{"old"})>0 && length($par{"new"})>0);
    }
    @old=split(/,/,$par{"old"}); foreach $old (@old) {$old=~s/_?KWD_empty_?//ig; }
    @new=split(/,/,$par{"new"}); foreach $new (@new) {$new=~s/_?KWD_empty_?//ig; }
    if ($#old != $#new){
	print
	    "*** ERROR different numbers in: old ($ARGV[1]) new ($ARGV[2])\n",
	    "old (".$par{"old"}.")=",join("*",@old),"\n",
	    "new (".$par{"new"}.")=",join("*",@new),"\n";
	exit;}
    &iniGetArg();		# read command line input

    if (($par{"dirFind"} eq "unk")||(! -d $par{"dirFind"})){
	$par{"dirFind"}=$PWD;}

    if ($Lscreen) { print "--- $script_goal\n--- \n"; 
		    print "---\n--- end of '"."$scrName"."'_ini settings are:\n"; 
		    foreach $des (@desDef) {
			printf "--- %-20s '%-s'\n",$des,$par{"$des"};}}
}				# end of ini

#==========================================================================================
sub iniHelp {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniHelp                       
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $scrName=   "port-adopt";
    $script_input=  "old=/usr/pub/bin/perl,home/rost new=/usr/bin/perl,u/rost";
    $script_goal=   "changes names: x1->y1, x2->y2, and x3->y3";
    $script_narg=   2;
    @script_goal=   (" ",
		     "Task: \t $script_goal"," ",
		     "Input:\t $script_input dir (or: now *.file)"," ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$scrName help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("old=",
		     "new=",
		     "fileList=",
		     "not_screen",
		     );
    @script_opt_keydes= 
	            ("previous strings (x1,x2,x3)           ",
		     "new strings (x1->y1, x2->y2, x3->y3)  _KWD_EMPTY_ for exp->''",
		     "list of files to change",
		     "no information written onto screen",
		     );

    if ( ($ARGV[1]=~/^help|^man|^-h/) ) { 
	print "-" x 80, "\n", "--- \n--- Perl script \n"; 
	foreach $desOpt(@desDef){
	    printf "--- %-12s=x \t (def:=%-s) \n",$desOpt,$par{"$desDef"};}
	print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n--- Perl script \n";
	foreach $txt (@script_goal){if($txt !~ /Done:/){print "--- $txt\n";}}
	print"-" x 80,"\n";exit;}
}				# end of iniHelp

#==========================================================================================
sub iniDefaults {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniDefaults                       
#       in:
#       out:
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
				# expressions
    $par{"old"}=                "/home/rost,/usr/pub/bin/perl";
    $par{"new"}=                "newHome,newPerl";
				# files
    $par{"fileList"}=           "unk"; # list of files to change
    $fhin=                      "FHIN";
    $fhout=                     "FHOUT";
    $par{"dirSave"}=            "save";
    $par{"dirFind"}=            "";
				# --------------------
				# logicals
    $Lscreen=                   1;      # blabla on screen
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @desDef=     ("old","new","fileList","dirSave","dirFind");
}				# end of iniDefaults

#==========================================================================================
sub iniGetArg {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniGetArg                  read command line arguments
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    
    return if ($#ARGV==$script_narg);
	
    $#fileIn=0;
    foreach $arg(@ARGV){
	next if ($arg=~/^(old|new)=/);
	next if (length($arg)<1);
	if    ($arg=~/not_screen/ ) { $Lscreen=0; }
	elsif ($arg=~/^dir=(\S+)/)  { $par{"dirFind"}=$1;}
	    
	else {$Lok=0;
				# is directory
	      if (-d $arg){ $par{"dirFind"}=$arg;
			    next; }
				# is file
	      if (-e $arg){push(@fileIn,$arg);
			   next; }
	      foreach $des (@desDef){
		  if ($arg=~/^$des=(.+)$/){$par{"$des"}=$1; 
					   $Lok=1;
					   last;}}
	      if (! $Lok){ print "*** iniGetArg: unrecognised argument=$arg!\n";
			   die;}}}
}				# end of iniGetArg

#======================================================================
sub open_file {
    local ($file_handle, $file_name, $log_file) = @_ ;
    local ($temp_name) ;

    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
       print "*** \t INFO: file $temp_name does not exist; create it\n" ;
       open ($file_handle, ">$temp_name") || ( do {
             warn "***\t Can't create new file: $temp_name\n" ;
             if ( $log_file ) {
                print $log_file "***\t Can't create new file: $temp_name\n" ;
             }
       } );
       close ("$file_handle") ;
    }
  
    open ($file_handle, "$file_name") || ( do {
             warn "*** \t Can't open file '$file_name'\n" ;
             if ( $log_file ) {
                print $log_file "*** \t Can't create new file '$file_name'\n" ;
             }
             return(0);
       } );
}				# end of open_file

#==========================================================================================
sub lsAllTxtFiles {
    local($dirLoc) = @_ ;
    local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#    lsAllTxtFiles              will return all text files in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    if (! -d $dirLoc){		# directory empty
	return(0);}
    $sbrName="lsAllTxtFiles";$fhinLoc="FHIN"."$sbrName";$#tmp=0;
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$line=$_; $line=~s/\s//g;
		       if (-T $line && ($line!~/\~$/)){
			   push(@tmp,$line);}}close($fhinLoc);
    return(@tmp);
}				# end of lsAllTxtFiles

