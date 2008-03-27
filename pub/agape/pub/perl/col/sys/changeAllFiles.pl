#!/bin/env perl
#----------------------------------------------------------------------
# changeAllFiles
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	changeAllFiles old=x1,x2,x3 new=y1,y2,y3 list-of-files (or dir's)
#
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

&ini;				# initialise variables

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# security backup
if (! -d $dirSave){		# make it if not there
    if ($Lscreen){ print "--- system \t 'mkdir $dirSave' \n";}
    system("mkdir $dirSave");}
else {
    if ($Lscreen){ print "--- system \t '\\rm -r $dirSave' \n";}
    system("\\rm -r $dirSave");} # empty if there

				# ------------------------------
                                # file lists of directories
$#allTxtFiles=0;
foreach $dir (@dir){
    if (! -d $dir){
	print "-*- WARNING dir=$dir, not existing!\n";
	next;}
    if ($Lscreen){ print "--- \t  \t \t list all text files in dir '$dir'\n";}
    @allTxtFiles=		# list all text files
	&lsAllTxtFiles($par{"dir"});
    push(@file,@allTxtFiles);}
				# ------------------------------
				# change all files
$fileNew=$$."x.tmp";
foreach $file (@file){
    if ($file =~/\.tar|\.gz|\.z|\.Z/){	# exclude tar files
	next;}
    if ($file =~/^$dirSave/){	# exclude save files
	next;}
    if (! -e $file){
	print "-*- WARNING \t '$file' missing\n";
	next;}
    if ($Lscreen)             { print "--- now check \t '$file'\n";}
    &open_file("$fhin","$file");&open_file("$fhout",">$fileNew");$Ldiff=0;
    while(<$fhin>){
	$line=$_;
	foreach $it (1..$#old){
	    if ($line=~/$old[$it]/){
		if ($Lscreen){ print "--- \t \t '$old[$it]' -> '$new[$it]'\n";}
		$line=~s/$old[$it]/$new[$it]/g;$Ldiff=1;}}
	print $fhout $line;}close($fhin);close($fhout);
    if ($Ldiff){
	$fileTmp=$file;$fileTmp=~s/^.*\///g;
	$fileSave=$par{"dirSave"}."/".$fileTmp; 
	$cmd1="\\cp $file $fileSave";
	$cmd2="\\mv $fileNew $file";
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
    $PWD=                       $ENV{'PWD'};  $pwd=$PWD; if ($pwd !~/\/$/){$pwd.="/";}
    

    &iniDefaults;               # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp;
				# ------------------------------
				# predefined key words
    if ($#old != $#new){
	print "*** ERROR different numbers in: old ($ARGV[1]) new ($ARGV[2])\n";
	exit;}

    &iniGetArg;			# read command line input

    if ($Lscreen) { print "--- ","-" x 50,"\n--- end of '$script_name"."'_ini settings are:\n"; 
		    foreach $des (@desDef) {
			printf "--- %-20s '%-s'\n",$des,$par{"$des"};}
		    printf "--- %-20s '%-s'\n","files:"," ";$ct=0;
		    foreach $file (@file) {++$ct;printf "--- %-20s '%-s'\n","$ct",$file;}
		    printf "--- %-20s '%-s'\n","directories:"," ";$ct=0;
		    foreach $dir (@dir) {++$ct;printf "--- %-20s '%-s'\n","$ct",$dir;}
		    print "--- ","-" x 50,"\n--- \n";}
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
    $script_name=   "changeAllFiles";
    $script_input=  "old=/usr/sbin/perl,home/rost new=/usr/bin/perl,u/rost";
    $script_goal=   "changes names: x1->y1, x2->y2, and x3->y3";
    $script_narg=   2;
    @script_goal=   (" ",
		     "Task: \t $script_goal"," ",
		     "Input:\t $script_input dir"," ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$script_name help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("old=",
		     "new=",
		     "file= ",
		     "dir=",
		     "dirSave=",
		     " ",
		     "not_screen");
    @script_opt_keydes= 
	            ("previous strings (x1,x2,x3)",
		     "new strings (x1->y1, x2->y2, x3->y3) (if empty: 'new=')",
		     "file name (or list of files)",
		     "directory name (or list, all files searched)",
		     "directory with security backup of old files",
		     " ",
		     "no information written onto screen");

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
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniDefaults                       
#--------------------------------------------------------------------------------
				# expressions
    $par{"old"}=                "";
    $par{"new"}=                "";
				# files
    $par{"file"}=               ""; # list of files to change
    $par{"dir"}=                ""; # list of files to change
    $fhin=                      "FHIN";
    $fhout=                     "FHOUT";
				# --------------------
				# logicals
    $Lscreen=                   1;      # blabla on screen
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @desDef=     ("old","new","file","dir","dirSave");
}				# end of iniDefaults

#==========================================================================================
sub iniGetArg {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniGetArg                  read command line arguments
#--------------------------------------------------------------------------------
    $#old=$#new=$#dir=$#file=0;
    if ($#ARGV==$script_narg) {
	return;}
    for($it=1;$it<=$#ARGV;++$it) {
	$_=$ARGV[$it];
	if ( /not_screen/ ) {    $Lscreen=0; }
	else {
	    $Lok=0;
	    foreach $des (@desDef){
		if (/^$des=/){$_=~s/\s|\n|^.*$des=//g;
			      $par{"$des"}=$_; $Lok=1;
			      last;}}
	    if (! $Lok){
		if (/=/){print "*** iniGetArg: unrecognised keyword: $_\n";
			 exit;}
		elsif (-d $_){
		    push(@dir,$_);}
		elsif (-e $_){
		    push(@file,$_);}
		else    {print "*** iniGetArg: unrecognised argument: $_\n";
			 exit;}}}}
				# update on directories
    @old= split(/,/,$par{"old"});
    @new= split(/,/,$par{"new"});
    push(@dir,split(/,/,$par{"dir"}));
    push(@file,split(/,/,$par{"file"}));
				# security backup
    $dirSave=$par{"dirSave"}; 
    if ( ($dirSave eq "unk")||(length($dirSave)<3) ){
	$dirSave=$par{"dirSave"}=$pwd."save";}

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
}
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

