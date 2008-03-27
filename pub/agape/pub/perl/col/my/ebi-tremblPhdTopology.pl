#!/usr/bin/perl
##!/usr/sbin/perl -w
#----------------------------------------------------------------------
# tremblPhdTopology
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	tremblPhdTopology.pl list_of_trembl_files
#
# task:		find all transmembrane helical proteins in TREMBL
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       July,            1996           #
#			changed:       August	,    	1996           #
#			changed:       .	,    	1996           #
#	EMBL			       Version 0.1                     #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
$Lembl=0;
				# include libraries
push (@INC, "/home/rost/perl","/u/rost/perl/") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
&tremblPhdTopology_ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# trace file
$fhtrace="STDOUT";		# x.x
if ($fhtrace ne "STDOUT"){ $file=$par{"fileTrace"};&open_file("$fhtrace", ">$file");}

&open_file("$fhin", "$file_in");

while (<$fhin>) {
    $_=~s/\n|\s//g;$fileTrembl=$_;
    if (! -e $fileTrembl){      print"*** missing trembl '$fileTrembl'\n";
				next;}
    $#fileTrash=0;		# collect trash files (to be deleted after completion)
    $id=$fileTrembl;$id=~s/^.*\///g;$id=~s/\..*$//g; # purge directories and extensions
				# append list of id's processed for run-control
    system("echo '$id' >> $file_done");


    $fileHssp=$par{"dir_work"} . "$id" . ".hssp"; push(@fileTrash,$fileHssp);
				# ------------------------------
    $Lok=			# run MaxHom self
	&maxSelf($par{"exeMax"},$par{"exeConvSeq"},$fileTrembl,$id,$fileHssp,
		 $par{"dir_work"},$par{"dirData"},$par{"dirDataPdb"},$par{"dirDataSwiss"},
		 $par{"maxThreshTxt"},$par{"maxDb"},$par{"maxMetMcLachlan"},$fhtrace);
    if (! $Lok){                print "*** serious ERROR no MaxHom self!!\n";
				next;}
				# ------------------------------
    $Lok=			# run PHDhtm (check no HTM?)
	&phdHtmSingle($fileHssp,$id,$par{"dir_work"},$par{"exePhdPerl"},
		      $par{"phdMinHtmRelax"},$par{"phdOptNice"},$ARCH,$Ldebug,$fhtrace);
    if (! $Lok){		# ------------------------------
	next;}			# not membrane EXIT !
				# ------------------------------
    $Lok=			# if found: do full alignment
	&maxAli($par{"exeMax"},$par{"exeConvSeq"},$par{"exeBlastp"},$par{"exeFilterBlastp"},
		$fileTrembl,$id,$fileHssp,
		$par{"dir_work"},$par{"dirData"},$par{"dirDataPdb"},$par{"dirDataSwiss"},
		$par{"maxThreshTxt"},$par{"maxDb"},$par{"maxMetMcLachlan"},
		$par{"blastpMat"},$par{"blastpDb"},$fhtrace);
    if (! $Lok){		# error in MaxHom -> leave!
	next;}
				# ------------------------------
    ($Lok,$filePhdRdb)=		# run PHDhtm (check no HTM?)
	&phdHtmAli($fileHssp,$id,$par{"dir_work"},$par{"exePhdPerl"},
		   $par{"phdMinHtmTense"},$par{"phdOptNice"},$ARCH,$Ldebug,$fhtrace);
    if (! $Lok){		# ------------------------------
	next;}			# not membrane EXIT !
				# ------------------------------
				# write output
    ($Lok,%res)=		# read RDB (header only)
	&rdPhdRdb($filePhdRdb,$fhtrace);
    if (! $Lok){		# check
	print "*** ERROR after rdPhdRdb panick!!\n";
	next;}
				# write new TREMBL
    $fileOutPhdTrembl=$id . $par{"extOutPhdTrembl"};
    &wrtTremblPhd($fileTrembl,$fileOutPhdTrembl,$fhtrace,%res);
    $fileOutHssp=     $id . $par{"extOutHssp"};
				# move and delete files
    &finMoveFiles($par{"dir_out"},
		  $fileOutHssp,$par{"dirOutHssp"},$fileOutPhdTrembl,$par{"dirOutPhdTrembl"},
		  $filePhdRdb,$par{"dirOutPhdRdb"},$fhtrace);
    
} close($fhin);if ($fhtrace ne "STDOUT"){close($fhtrace);}

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { &myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); }

exit;

#==========================================================================================
sub tremblPhdTopology_ini {
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
#    $PWD=                       $ENV{'PWD'};

    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "tremblPhdTopology";
    $script_input=  "list_of_trembl_files";
    $script_goal=   "find all transmembrane helical proteins in TREMBL";
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
    @script_opt_key=("ARCH ",
		     " ",
		     "title=",
		     "debug",
		     "not_screen",
		     "dir_work=",
		     "dir_out=",
		     );
    @script_opt_keydes= 
	            ("CPU architecture (SGI64, ALPHA=dec alpha)",
		     " ",
		     "title of output file",
		     "no deletion of intermediate files ",
		     "no information written onto screen",
		     "working directory      default: local",
		     "output directory       default: local",
		     );

    if ( (! defined $ARGV[1]) || ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_empty;&myprt_txt("Optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf "--- %-12s %-s \n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){if($txt !~ /Done:/){&myprt_txt("$txt");}}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
    foreach $_(@ARGV){if(/^ARCH=/){$arg=$_;$arg=~s/^ARCH=|\s//g;$ARCH=$arg;
					   last;}}
    if (! defined $ARCH){$ARCH=$env{"ARCH"};}
    if (! defined $ARCH){$ARCH=$env{"CPUARC"};}
    if (! defined $ARCH){$ARCH="SGI64";}
    $par{"dir_work"}=      "";
    $par{"dir_out"}=       "";
    $par{"file_done"}=     "";
				# --------------------
				# directories
    if ($Lembl){
	$par{"dirPhd"}=         "/home/rost/pub/phd/";
	$par{"dirMax"}=         "/home/rost/prog/$ARCH/";
	$par{"dirMax"}=         "/sander/purple1/rost/prog/$ARCH/";
	$par{"dirMaxMat"}=      "/home/rost/pub/max/";
	$par{"dirBlastp"}=      "/usr/pub/bin/molbio/";
	$par{"dirFilterBlastp"}="/usr/pub/bin/molbio/";
	$par{"dirConvSeq"}=     "/usr/pub/bin/molbio/";
	$par{"dirData"}=        "/data/";
	$par{"dirDataPdb"}=     $par{"dirData"}."pdb/";
	$par{"dirDataSwiss"}=   $par{"dirData"}."swissprot/current/";
	$par{"dirDataTrembl"}=  "/sander/purple1/rost/work/trembl/trembl";
	$par{"dirOutHssp"}=     "hssp/";
	$par{"dirOutPhdRdb"}=   "phdRdb/";
	$par{"dirOutPhdTrembl"}="phdTrembl/";
    } else {
	$par{"dirPhd"}=         "/u/rost/pub/phd/";
	$par{"dirMax"}=         "/u/rost/pub/max/";
	$par{"dirMaxMat"}=      "/u/rost/pub/max/";
	$par{"dirBlastp"}=      "/u/rost/pub/max/";
	$par{"dirFilterBlastp"}="/u/rost/pub/max/";
	$par{"dirConvSeq"}=     "/u/rost/pub/max/";
	$par{"dirData"}=        "/data/research/";
	$par{"dirDataPdb"}=     $par{"dirData"}."pdb/";
	$par{"dirDataSwiss"}=   $par{"dirData"}."swissprot/current/";
	$par{"dirDataTrembl"}=  "/data/research/trembl";
	$par{"dirOutHssp"}=     "hssp/";
	$par{"dirOutPhdRdb"}=   "phdRdb/";
	$par{"dirOutPhdTrembl"}="phdTrembl/";
    }
				# --------------------
				# executables
    $par{"exePhdPerl"}=         $par{"dirPhd"}."phd.pl";
    if ($Lembl){
	$par{"exeMax"}=         $par{"dirMax"}."maxhom";
	$par{"exeBlastp"}=      $par{"dirBlastp"}."blastp";
	$par{"exeFilterBlastp"}=$par{"dirFilterBlastp"}."filter_blastp";
	$par{"exeConvSeq"}=     $par{"dirConvSeq"}."convert_seq";
    }else{
	$par{"exeMax"}=         $par{"dirMax"}."maxhom.$ARCH";
	$par{"exeBlastp"}=      $par{"dirBlastp"}."blastp.$ARCH";
	$par{"exeFilterBlastp"}=$par{"dirFilterBlastp"}."filter_blastp.pl";
	$par{"exeConvSeq"}=     $par{"dirConvSeq"}."convert_seq.$ARCH";
    }
    
				# --------------------
				# files
    $par{"title"}=		"unk"; # used to name output files (title.extension)
    $par{"fileTrace"}=          "TRACE_$$.tmp";
				# file extensions
    $par{"extOutHssp"}=         ".hssp";
    $par{"extOutPhdTrembl"}=    ".phdTrembl";
				# file handles
#    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhtrace=                   "FH_TRACE";
				# --------------------
				# further
    $par{"maxThreshTxt"}=       "FORMULA+5";
    if ($Lembl){
	$par{"maxDb"}=		"/data/swissprot/"; # database to run MaxHom
	$par{"blastpMat"}=      "/home/pub/molbio/blast/blastapp/matrix";
	$par{"blastpDb"}=       "/data/db/";
    }else{
	$par{"maxDb"}=		"/data/research/swissprot/"; # database to run MaxHom
	$par{"blastpMat"}=      "/u/schneide/blast/blastapp/matrix";
	$par{"blastpDb"}=       "/data/research/db/";
    }
    $par{"maxDefaults"}=        $par{"dirMaxMat"}."maxhom.defaults";
    $par{"maxMetGCG"}=          $par{"dirMaxMat"}."Maxhom_GCG.metric";
    $par{"maxMetMcLachlan"}=    $par{"dirMaxMat"}."Maxhom_McLachlan.metric";

    $par{"phdMinHtmTense"}=     0.8; # secure threshold (after alignment)
    $par{"phdMinHtmTense"}=     0.2; # secure threshold (after alignment)
    $par{"phdMinHtmRelax"}=     0.6; # relaxed threshold (before alignment)
    $par{"phdMinHtmRelax"}=     0.2; # relaxed threshold (before alignment)
    $par{"phdOptNice"}=         "nice-19";
    $par{"phdOptNice"}=         " ";

				# --------------------
				# logicals
    $Lscreen=                   1; # blabla on screen
    $Ldebug=                    0; # if 1 : keep intermediate files
				# --------------------
				# executables

				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @des_def=     ("dir_work","dir_out",
		   "dirPhd","dirMax","dirMaxMat","dirBlastp","dirFilterBlastp",
		   "dirConvSeq","dirDataSwiss","dirDataPdb","dirData",
		   "dirDataTrembl","dirOutHssp","dirOutPhdRdb","dirOutPhdTrembl",
		   "exePhdPerl","exeMax","exeBlastp","exeFilterBlastp","exeBlastp",
		   "title","fileTrace","extOutHssp","extOutPhdTrembl",
		   "maxThreshTxt","maxDb","maxDefaults","maxMetGCG","maxMetMcLachlan",
		   "blastpMat","blastpDb","phdMinHtmTense","phdMinHtmRelax","phdOptNice"
		   );

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $file_in=   $ARGV[1];
    if ($#ARGV>$script_narg) {
	for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	    $_=$ARGV[$it];
	    if   (/^not_screen/){ $Lscreen=0; }
	    elsif(/^dir_work=/ ){ $_=~s/\n|dir_work=//g;$par{"dir_work"}=$_; }
	    elsif(/^dir_out=/ ){ $_=~s/\n|dir_out=//g;$par{"dir_out"}=$_; }
	    elsif(/^title=/    ){ $_=~s/\n|title=//g;$par{"title"}=$_; }
	    elsif(/^debug/    ) { $Ldebug=1;}
	    elsif(/^ARCH=/)     { $ARCH=$_;} # no action
	    else {
		$Lok=0;
		foreach $des (@des_def){
		    if (/^$des=/){
			$_=~s/\s|\n|^.*$des=//g; $par{"$des"}=$_; $Lok=1; last; }}
		if (! $Lok){print "*** $script_name: unrecognised argument: $_\n";
			    exit;}
	    } }}
    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    if (length($par{"dir_work"})>1) { $par{"dir_work"}=&complete_dir($par{"dir_work"}); }
    if (length($par{"dir_out"})>1) { $par{"dir_out"}=&complete_dir($par{"dir_out"}); }
    $par{"file_done"}=$file_done="DONE-".$file_in;

    if ($Lscreen) { &myprt_line; &myprt_txt("$script_goal"); &myprt_empty; 
		    print "---\n--- end of '"."$script_name"."'_ini settings are:\n"; 
		    &myprt_txt("file_in: \t \t $file_in"); 
		    &myprt_txt("processed listed in: \t $file_done"); 
		    foreach $des (@des_def) {
			printf "--- %-20s '%-s'\n",$des,$par{"$des"};}&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($file_in)>0) && (! -e $file_in) ) {
	&myprt_empty;&myprt_txt("ERROR $script_name:\t file_in '$file_in' does not exist");exit;}

}				# end of tremblPhdTopology_ini

#==========================================================================
sub check_hssp {
    local ($file_in,$fhtrace)= @_;
    local ($tmp,$s,$found,$Llong_id,$fhinLoc,$cut);
    $[=1;
#----------------------------------------------------------------------
#   check hssp for PHD server
#   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   usage: "checkhssp.pl file.hssp"
#   exit if: 	no homology detected in HSSP file	file.no_homology
#   warning if: exists a PDB file in alignment		file.ilya_pdb
#----------------------------------------------------------------------
    $fhinLoc="FHIN_check_hssp";
    $Llong_id=0;
    print $fhtrace "--- checkhssp.pl: \t input file: '$file_in' \n";
    if ( ! -e $file_in ) {	# existing file?
	print $fhtrace "WARNING: HSSP file $file_in does not exist \n";
	return(1,0);}
				# open
    open($fhinLoc,$file_in)  || warn "Can't open $file_in: $!\n";
				# ----------------------------------------
				# skip everything before "## PROTEINS"
				# ----------------------------------------
    while( <$fhinLoc> ) {
	if (/^PARAMETER  LONG-ID :YES/) { # is long id?
	    $Llong_id=1;}
	tr/a-z/A-Z/;		# lower case -> upper
	if ( /^\#\# PROTEINS/ ) {$tmp = "T"; }
	last if ( /^\#\# PROTEINS/ ); }
    if ($tmp eq "T") { 
	print $fhtrace "homologue found \n"; }
    else {			# exit if no homology found
	print $fhtrace "no homologue found by fasta\/maxhom! \n";
	close($fhinLoc);
	return(1,0); }
				# ----------------------------------------
				# now search for PDB identifiers
				# ----------------------------------------
    if ($Llong_id){ $cut=47; } else { $cut=21; }
    $found="";
    while ( <$fhinLoc> ) {
	if (! /^\s*\d+ \:/){
	    next;}
	$s=substr($_,$cut,4); $s=~ s/\s//g;
	if ( length($s) > 1) { $found .= "$s".", ";} 
	last if ( /\#\# ALIGNMENT/ ); }
    print $fhtrace "PDB homologues: $found \n";
    close($fhinLoc);
    if (length($found) > 2) {
	return(0,1); }
    return(0,0);
}				# end of check_hssp

#==========================================================================================
sub cleanUp {
    local ($fhtrace,@fileClean) = @_ ;local ($file);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    cleanUp                    removes intermediate files
#--------------------------------------------------------------------------------
    foreach $file (@fileClean){
	&file_rm($fhtrace,$file); }
}				# end of cleanUp

#==========================================================================
sub convert_seq2fasta {
    local($exe_loc,$file_in_loc,$file_out_loc,$fhtrace)=@_;
    local($outformat,$an,$command);
#----------------------------------------------------------------------
#   convert_seq2fasta           convert all formats to fasta
#----------------------------------------------------------------------
    $outformat=                 "F";
    $an=                        "N";
    eval "\$command=\"$exe_loc,$file_in_loc,$outformat,$an,$file_out_loc,$an,\"";
    &run_program("$command");
    if (! -e $file_out_loc){
	print $fhtrace "ERROR convert_seq2fasta: no conversion successful\n";
	return(0);}
    return(1);
}				# end of convert_seq2fasta

#==========================================================================================
sub finMoveFiles {
    local ($dirLoc{"out"},$fileLoc{"hssp"},$dirLoc{"hssp"},$fileLoc{"rdb"},$dirLoc{"rdb"},
	   $fileLoc{"phd"},$dirLoc{"phd"},$fhtrace) = @_ ;
    local ($dirLoc2{"hssp"},$dirLoc2{"rdb"},$dirLoc2{"phd"},@desLoc,$fileIn,$fileOut);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    finMoveFiles               move files to final destination, and clean up
#       GLOBAL in/out           @fileTrash
#--------------------------------------------------------------------------------
    @desLoc=("hssp","rdb","phd");
    foreach $des (@desLoc){	# purge directories
	$fileLoc{"$des"}=~s/^.*\///g;}
    foreach $des (@desLoc){	# put 'dir_out' before 'special_dir_out'
	$dirLoc2{"$des"}=$dirLoc{"out"}.$dirLoc{"$des"};}
    foreach $des ("out",@desLoc){ # make directories
	if ($des eq "out"){$dir=$dirLoc{"$des"};}else{$dir=$dirLoc2{"$des"};}
	if (!-d $dir){print $fhtrace "--- finMoveFiles: \t system 'mkdir $dir'\n";
		      system("mkdir $dir");}}
    foreach $des (@desLoc){	# move files
	$fileIn=$fileLoc{"$des"};$fileOut=$dirLoc2{"$des"}.$fileLoc{"$des"};
	if (-e $fileIn){
	    print $fhtrace "--- finMoveFiles: \t system '\\mv $fileIn $fileOut'\n";
	    system("\\mv $fileIn $fileOut");}
	else {
	    print $fhtrace "***\n*** finMoveFiles: '$fileIn' missing!\n***\n";}}
				# ------------------------------
    if (! $Ldebug){		# clean up
	&cleanUp($fhtrace,@fileTrash);}
}				# end of finMoveFiles

#==========================================================================
sub maxAli {
    local ($exe_maxhom,$exe_convert_seq,$exe_blastp,$exe_filter_blastp,
	   $file_trembl,$id_loc,$fileHsspLoc,$dir_workLoc,$dir_data,$dir_pdb,$dir_swiss,
	   $thresh_txt,$max_db,$max_metric,$blast_mat,$blastpDb,$fhtrace)=@_;
    local ($file_out_conv,$file_out_blastp,$command,$tmp,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   runs:                       convert_seq, blastp, and maxhom 
#       GLOBAL in/out           @fileTrash
#--------------------------------------------------------------------------------
    if(! defined $fhtrace){     print "WARNING maxAli: handle for trace?\n";$fhtrace="STDOUT";}
    print $fhtrace              "--- maxAli: \t entered with arg=";
    foreach$_(@_){print $fhtrace "$_,";}print $fhtrace "\n";
                                # ----------------------------------------
				# convert seq to FASTA
    $file_out_conv="$id_loc" . ".y"; push(@fileTrash,$file_out_conv);
    $Lok=&convert_seq2fasta($exe_convert_seq,$file_trembl,$file_out_conv,$fhtrace);
    if (!$Lok){                 print "*** maxAli: convert_seq failed\n";
				return(0); }
                                # ----------------------------------------
                                # pre-filter to speed up MaxHom (BLAST)
    $file_out_blastp="$dir_workLoc"."filter.list_".$$; push(@fileTrash,$file_out_blastp);
    &maxBlastp($exe_blastp,$exe_filter_blastp,$blast_mat,$blastpDb,
	       $dir_swiss,$file_out_conv,$file_out_blastp,$dir_workLoc,$fhtrace);
	       
                                # ----------------------------------------
                                # safety check before maxhom
    if (! -f $file_out_blastp ) { # existence of filter file?
	print "*** maxAli: blastp failed\n";return(0); }
    if (! -d $dir_data  ) {	# existence of database device
	print "*** maxAli: database '$dir_data' missing\n";return(0); }
				# ----------------------------------------
				# get the arguments for the MAXHOM csh
    $dir_pdb=&complete_dir($dir_pdb);
    print $fhtrace
	"maxAli: '\&maxGetArg($exe_maxhom,",
	"$file_trembl,$file_out_blastp,$fileHsspLoc,$dir_pdb,$thresh_txt)'\n";
    $command=   
	&maxGetArg($exe_maxhom,$file_out_conv,$file_out_blastp,$fileHsspLoc,
		   $max_metric,$dir_pdb,$thresh_txt,$fhtrace);
				# --------------------------------------------------
                                # run maxhom
    print $fhtrace "maxAli: '$command'\n";
    &run_program("$command");	# it's running!
				# ------------------------------
				# safety check
    if (! -f $fileHsspLoc){print "*** maxAli: Maxhom failed\n";return(0); }
				# is there a homologue?
    ($LisNoHom,$LisPdb)=&check_hssp($fileHsspLoc,$fhtrace);
    if ($LisPdb){
#	print $fhtrace "--- maxAli: \t PDB file detected -> break! \n";return(0);
    }
				# --------------------------------------------------
    if ( $LisNoHom ) {		# maxhom against itself (since no homologues)
	$command=
	    &maxGetArg($exe_maxhom,$file_out_conv,$file_out_conv,$fileHsspLoc,
		       $max_metric,$dir_pdb,$thresh_txt,$fhtrace);
	print $fhtrace "--- maxAli:  run self '$command'\n"; 
	&run_program("$command"); # run self
	if (!-f $fileHsspLoc){print "*** maxAli: no HSSP file AFTER self!!\n";return(0);}}
    return(1);
}				# end maxAli

#==========================================================================
sub maxBlastp {
    local($exe_blastp,$exe_filter_blastp,$blastMat,$blastDb,
	  $dir_swiss,$file_in,$file_out,$dir_workLoc,$fhtrace)=@_;
    local($blast_out);
#----------------------------------------------------------------------
#   Prefilter for maxhom: BLASTP
#   NOTE : requires environment variables:
#          "BLASTMAT" = /home/pub/molbio/blast/blastapp/matrix
#          "BLASTDB"  = /data/db/
#----------------------------------------------------------------------
    if(! defined $fhtrace){     print "WARNING maxBlastp: handle for trace?\n";$fhtrace="STDOUT";}
    print $fhtrace              "--- maxBlastp: \t entered with arg=";
    foreach$_(@_){print $fhtrace "$_,";}print $fhtrace "\n";
				# ------------------------------
                                # prepare blastp
    if (! defined $ENV{'BLASTMAT'}){ $ENV{'BLASTMAT'}="$blastMat";}
    if (! defined $ENV{'BLASTDB'}) { $ENV{'BLASTDB'}="$blastDb";}
				     

    $blast_out="$dir_workLoc"."blast.x_"."$$"; push(@fileTrash,$blast_out); # Blast output
    if ($dir_swiss =~/swiss/){
	$command="$exe_blastp swiss $file_in B=2000 > $blast_out";}
    else {
	$command="$exe_blastp nrdb $file_in B=2000 > $blast_out";}
    print $fhtrace "maxBlastp: '$command'\n";
    &run_program("$command" ,"$fhtrace","die");	# run BLAST
#    &run_program("rm -f $file_in" ) unless $Debug;
				# ------------------------------
                                # extract hits from blast-output
    $command="$exe_filter_blastp $dir_swiss < $blast_out > $file_out";
    print $fhtrace "maxBlastp: '$command'\n";
    &run_program("$command" ,"$fhtrace","die");
#    &run_program("rm $blast_out_loc" ) unless $Debug;
}				# end of maxBlastp

#==========================================================================
sub maxGetArg {
    local($exe_max_loc,$file_max_in,$file_max_list,$file_hssp_loc,
	  $file_metric,$dir_pdb_loc,$thresh_txt_loc,$fhtrace)=@_;
    local ($command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxGetArg                 gets the input arguments to run MAXHOM
#--------------------------------------------------------------------------------
    $command="";
    eval "\$command=\"$exe_max_loc -nopar,
         COMMAND        NO ,
         BATCH ,
         PID:           $$ ,
         SEQ_1          $file_max_in ,      
         SEQ_2          $file_max_list ,
         PROFILE        NO ,
         METRIC         $file_metric ,
         NORM_PROFILE   DISABLED , 
         MEAN_PROFILE   0.0 ,
         FACTOR_GAPS    0.0 ,
         SMIN           -0.5 , 
         SMAX           1.0 ,
         GAP_OPEN       3.0 ,
         GAP_ELONG      0.1 ,
         WEIGHT1        YES ,
         WEIGHT2        NO ,
         WAY3-ALIGN     NO ,
         INDEL_1        YES,
         INDEL_2        YES,
         RELIABILITY    NO ,
         FILTER_RANGE   10.0,
         NBEST          1 ,
         MAXALIGN       500 ,
         THRESHOLD      $thresh_txt_loc ,
         SORT           DISTANCE ,
         HSSP           $file_hssp_loc ,
         SAME_SEQ_SHOW  YES ,
         SUPERPOS       NO ,
         PDB_PATH       $dir_pdb_loc ,
         PROFILE_OUT    NO ,
         STRIP_OUT      NO ,
         DOT_PLOT       NO ,
         RUN ,\"";
    print $fhtrace "$command\n";
    return ($command);
}				# end maxGetArg

#==========================================================================
sub maxSelf {
    local ($exe_maxhom,$exe_convert_seq,$file_trembl,$id_loc,$fileHsspLoc,
	   $dir_workLoc,$dir_data,$dir_pdb,$dir_swiss,
	   $thresh_txt,$max_db,$max_metric,$fhtrace)=@_;
    local ($file_out_conv,$file_out_blastp,$command,$tmp,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   runs:                       convert_seq, blastp, and maxhom 
#       GLOBAL in/out           @fileTrash
#--------------------------------------------------------------------------------
    if(! defined $fhtrace){     print "WARNING maxSelf: handle for trace?\n";$fhtrace="STDOUT";}
    print $fhtrace              "--- maxSelf: \t entered with arg=";
    foreach$_(@_){print $fhtrace "$_,";}print $fhtrace "\n";
                                # ----------------------------------------
				# convert seq to FASTA
    $file_out_conv="$id_loc" . ".y"; push(@fileTrash,$file_out_conv);
    $Lok=&convert_seq2fasta($exe_convert_seq,$file_trembl,$file_out_conv,$fhtrace);
    if (!$Lok){                 print "*** maxSelf: convert_seq failed\n";
				return(0); }
				# --------------------------------------------------
				# maxhom against itself (since no homologues)
    $command=
	&maxGetArg($exe_maxhom,$file_out_conv,$file_out_conv,$fileHsspLoc,
		   $max_metric,$dir_pdb,$thresh_txt,$fhtrace);
    print $fhtrace "--- maxSelf:  run self '$command'\n"; 
    &run_program("$command");	# run self
				# security check
    if (!-f $fileHsspLoc){	print "*** maxSelf: no HSSP file AFTER self!!\n";
				return(0);}
    return(1);
}				# end maxSelf

#==========================================================================================
sub phdHtmSingle {
    local ($fileHsspLoc,$idLoc,$dir_workLoc,$exePhdPerl,$phdMinHtm,$phdOptNice,
	   $archLoc,$Ldebug,$fhtrace) = @_ ;
    local ($arg,$filePhdRdb,$filePhdOut,$filePhdNotMem);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    phdHtmSingle               runs PHDhtm for the first time, i.e., no Ali
#                               relaxed criterion for detection (0.6)
#       GLOBAL in/out           @fileTrash
#--------------------------------------------------------------------------------
    if(! defined $fhtrace){print "WARNING maxSelf: handle for trace?\n";$fhtrace="STDOUT";}
    print $fhtrace              "--- phdHtmSingle: \t entered with arg=";
    foreach$_(@_){print $fhtrace "$_,";}print $fhtrace "\n";
				# ------------------------------
				# build up command line arguments
    $arg= " htm not_htmref not_htmtop not_htmfil";
    $arg.=" opt_htmisit_min_val="."$phdMinHtm"." "."opt_do_htmfil=0";
    $arg.=" ARCH=$archLoc $phdOptNice ";
    $filePhdRdb=   "$dir_workLoc"."$idLoc"."_pre".".rdb_phd";     push(@fileTrash,$filePhdRdb);
    $filePhdOut=   "$dir_workLoc"."$idLoc"."_pre".".phd";         push(@fileTrash,$filePhdOut);
    $filePhdNotMem="$dir_workLoc"."$idLoc"."_pre".".not_membrane";push(@fileTrash,$filePhdNotMem);
    $arg.=" file_phd=$filePhdOut file_rdb=$filePhdRdb file_not_membrane=$filePhdNotMem ";
    if ($Ldebug){ $arg.=" debug";}
				# ------------------------------
				# running PHD
    print $fhtrace "--- phdHtmSingle \t system '$exePhdPerl $fileHsspLoc $arg'\n";
    system("$exePhdPerl $fileHsspLoc $arg");
				# ------------------------------
				# checking output
    if (! -e $filePhdRdb){	# output missing
	print $fhtrace "*** ERROR phdHtmSingle: \t Phd.rdb file missing -> stop!\n";
	return(0);}
    if (-e $filePhdNotMem){	# no HTM detected
	print $fhtrace "xxx no HTM for '$idLoc'\n";
	&cleanUp($fhtrace,@fileTrash);
	return(0);}
    return(1);
}				# end of phdHtmSingle

#==========================================================================================
sub phdHtmAli {
    local ($fileHsspLoc,$idLoc,$dir_workLoc,$exePhdPerl,$phdMinHtm,$phdOptNice,
	   $archLoc,$Ldebug,$fhtrace) = @_ ;
    local ($arg,$filePhdRdb,$filePhdOut,$filePhdNotMem);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    phdHtmAli                  runs PHDhtm for the second time, i.e., with Ali
#                               secure criterion for detection (0.8)
#       GLOBAL in/out           @fileTrash
#--------------------------------------------------------------------------------
    if(! defined $fhtrace){print "WARNING maxSelf: handle for trace?\n";$fhtrace="STDOUT";}
    print $fhtrace              "--- phdHtmAli: \t entered with arg=";
    foreach$_(@_){print $fhtrace "$_,";}print $fhtrace "\n";
				# ------------------------------
				# build up command line arguments
    $arg= " htm ";
    $arg.=" opt_htmisit_min_val="."$phdMinHtm"." "."opt_do_htmfil=0";
    $arg.=" ARCH=$archLoc $phdOptNice ";
    $filePhdRdb=   "$dir_workLoc"."$idLoc".".rdb_phd";     push(@fileTrash,$filePhdRdb);
    $filePhdOut=   "$dir_workLoc"."$idLoc".".phd";         push(@fileTrash,$filePhdOut);
    $filePhdNotMem="$dir_workLoc"."$idLoc".".not_membrane";push(@fileTrash,$filePhdNotMem);
    $arg.=" file_phd=$filePhdOut file_rdb=$filePhdRdb file_not_membrane=$filePhdNotMem ";
    if ($Ldebug){ $arg.=" debug";}
				# ------------------------------
				# running PHD
    print $fhtrace "--- phdHtmAli \t system '$exePhdPerl $fileHsspLoc $arg'\n";
    system("$exePhdPerl $fileHsspLoc $arg");
				# ------------------------------
				# checking output
    if (! -e $filePhdRdb){	# output missing
	print $fhtrace "*** ERROR phdHtmAli: \t Phd.rdb file missing -> stop!\n";
	return(0,0);}
    if (-e $filePhdNotMem){	# no HTM detected
	print $fhtrace "xxx no HTM for '$idLoc'\n";
	&cleanUp($fhtrace,@fileTrash);
	return(0,0);}
    return(1,$filePhdRdb);
}				# end of phdHtmAli

#==========================================================================================
sub rdPhdRdb {
    local ($fileRdb,$fhtrace) = @_ ;
    local (%rd,%res,@des_rd,@header,$nhtm,$top,%model,@begSort,@begTmp,$beg,@range,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdPhdRdb                   reads header of phd.rdb file
#       out:                    $res{"x"}, x=nhtm,top,1,...,N (N=nhtm),len
#                               nhtm= number of transmembrane helices
#                               top = predicted topology (in,out)
#                               n   = range of helix number n (n1-n2)
#                               len = length of protein
#--------------------------------------------------------------------------------
    if(! defined $fhtrace){print "WARNING rdPhdRdb: handle for trace?\n";$fhtrace="STDOUT";}
    print $fhtrace              "--- rdPhdRdb: \t entered with arg=$fileRdb,$fhtrace,\n";
    
    @des_rd=("");
    @header=("LENGTH","NHTM_BEST","MODEL_DAT","HTMTOP_PRD");
				# read only header
    %rd=&rd_rdb_associative($fileRdb,"not_screen","header",@header,"body",@des_rd);
				# process header
    $len=  $rd{"LENGTH"};    $len=~s/\D//g;
    $nhtm= $rd{"NHTM_BEST"}; $nhtm=~s/\D//g;
    $top=  $rd{"HTMTOP_PRD"};$top=~s/^[:\s]+([\S]+)\s.*$/$1/g;
    $rd{"MODEL_DAT"}=~s/^:|:$//g;
    @model=split(/:/,$rd{"MODEL_DAT"});
    $#begTmp=0;
    foreach $it(1..$nhtm){	# get ranges
	$tmp=$model[$it];$tmp=~s/^[\s,]*|[\s,]*$//g;$tmp=~s/\s//g;
	@tmp=split(/,/,$tmp);
	$beg=$tmp[4]; $beg=~s/-.*$//g; push(@begTmp,$beg);
	$model{"$beg"}=$tmp[4];}
    @begSort= sort {$a<=>$b}  @begTmp; # sort
    foreach $it(1..$nhtm){	# sort ranges
	$beg=$begSort[$it];
	$range[$it]=$model{"$beg"};}
				# check 
    if ((! defined $nhtm)||(! defined $top)||($#range==0) ){
	return(0);}
    $res{"nhtm"}=$nhtm;$res{"top"}=$top;$res{"len"}=$len;
    foreach $it (1..$nhtm){$res{"$it"}=$range[$it];}
    return(1,%res);
}				# end of rdPhdRdb

#==========================================================================================
sub wrtTremblPhd {
    local ($fileLoc,$fileOut,$fhtrace,%res) = @_ ;
    local ($fhoutLoc,$fhinLoc,$rdLine,$beg,$end,@beg,@end,@begHtm,@endHtm,$it,@seg,@top);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtTremblPhd               reads old TREMBL , writes new one, inserting HTM's
#       in:                     file old AND:
#                               $res{"x"}, x=nhtm,top,1,...,N (N=nhtm),len
#                               nhtm= number of transmembrane helices
#                               top = predicted topology (in,out)
#                               n   = range of helix number n (n1-n2)
#                               len = length of protein
#--------------------------------------------------------------------------------
    if(! defined $fhtrace){print "WARNING rdPhdRdb: handle for trace?\n";$fhtrace="STDOUT";}
    print $fhtrace              "--- rdPhdRdb: \t entered with arg=$fileLoc,$fileOut,$fhtrace,+\n";
    $fhinLoc="FHIN_wrtTremblPhd";$fhoutLoc="FHOUT_wrtTremblPhd";
				# --------------------------------------------------
				# read TREMBL/write new
    &open_file("$fhinLoc", "$fileLoc");
    &open_file("$fhoutLoc", ">$fileOut");
				# ------------------------------
				# mirror everything before 'CC'
    while(<$fhinLoc>){ $rdLine=$_;
		       last if ($rdLine=~/^CC|^SQ/);
		       print $fhoutLoc $rdLine;}
				# ------------------------------
				# insert HTM's
    $#begHtm=$#endHtm=0;	# get begin and ends
    foreach $it (1..$res{"nhtm"}){
	($beg,$end)=split(/-/,$res{"$it"});push(@begHtm,$beg);push(@endHtm,$end);}
				# for first segment
    $#beg=$#end=$#seg=$#top=0;	# set zero
    if ($begHtm[1]==1){		# is HTM
	push(@seg,"TRANSMEM");push(@beg,$begHtm[1]); push(@end,$endHtm[1]);}
    else {			# is globular
	push(@seg,"DOMAIN");  push(@beg,1);    push(@end,($begHtm[1]-1));
	push(@seg,"TRANSMEM");push(@beg,$begHtm[1]); push(@end,$endHtm[1]);}
				# all other segments
    foreach $it (2..$res{"nhtm"}){
	push(@seg,"DOMAIN");  push(@beg,($endHtm[$it-1]+1));push(@end,($begHtm[$it]-1));
	push(@seg,"TRANSMEM");push(@beg,$begHtm[$it]); push(@end,$endHtm[$it]);}
				# last segment
    if ($endHtm[$#endHtm]<$res{"len"}){
	push(@seg,"DOMAIN");  push(@beg,($endHtm[$#endHtm]+1));push(@end,$res{"len"});}
    if ($res{"top"} eq "in"){	# topology
	if ($begHtm[1]==1){foreach $it (1..$#begHtm){push(@top,"htm","cyto","htm","non-cyto");}}
	else {             foreach $it (1..$#begHtm){push(@top,"cyto","htm","non-cyto","htm");}}}
    else {
	if ($begHtm[1]==1){foreach $it (1..$#begHtm){push(@top,"htm","non-cyto","htm","cyto");}}
	else {             foreach $it (1..$#begHtm){push(@top,"non-cyto","htm","cyto","htm");}}}
    foreach $it (1..$#seg){	# write the HTM's
	printf $fhoutLoc "FT   %-8s %6d %6d       ",$seg[$it],$beg[$it],$end[$it];
	if    ($top[$it] eq "htm"){
	    printf $fhoutLoc "%-s","POTENTIAL (PREDICTED BY PHD_TOPOLOGY).\n";}
	elsif ($top[$it] eq "cyto"){
	    printf $fhoutLoc "%-s","CYTOPLASMIC (POTENTIAL\;\n";
	    print $fhoutLoc "FT                                PREDICTED BY PHD_TOPOLOGY).\n";}
	elsif ($top[$it] eq "non-cyto"){
	    printf $fhoutLoc "%-s","NON-CYTOPLASMIC (POTENTIAL\;\n";
	    print $fhoutLoc "FT                                PREDICTED BY PHD_TOPOLOGY).\n";}
	else {
	    print "*** ERROR wrtTremblPhd: topology '$top[$it]' for it=$it, not recognised\n";}
    }
    print $fhoutLoc $rdLine;	# last line read
				# finish off
    while(<$fhinLoc>){ $rdLine=$_;
		       print $fhoutLoc $rdLine;}
    close($fhinLoc);close($fhoutLoc);
}				# end of wrtTremblPhd

#==========================================================================================
sub subx {
#    local ($file_in, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    subx                       
#         c
#       in:
#         A                     A
#       out:
#         A                     A
#--------------------------------------------------------------------------------

}				# end of subx

