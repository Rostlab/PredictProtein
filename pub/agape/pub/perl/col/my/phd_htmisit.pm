#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#

package phd_htmisit;

#===============================================================================
sub phd_htmisit {
#-------------------------------------------------------------------------------
#   phd_htmisit                   package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0



    @ARGV=@_;			# pass from calling

    &ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# prepare output file
    if (! $par{"not_file_out_wrt"}) {
	&wrt_out_header($fhout,$file_out,$sep,$Lscreen,
			$par{"do_avlen"},$par{"not_extract"},$par{"min_val"});}
				# --------------------------------------------------
				# loop over files
				# --------------------------------------------------
    $#val=$#num=$#avlen=0;
    foreach $file_in(@file_in){
				# ------------------------------
				# read PHDhtm RDB files
	@phd=
	    &htmisit_rd($file_in);
				# ------------------------------
				# get score for maximal helix
	($max_val,$max_pos)=
	    &get_max_htm($par{"min_htm"});
				# ------------------------------
	if ($par{"do_avlen"}) {	# get average length
	    ($htm_num,$htm_avlen)=
		&get_avlen_htm(); }
				# ------------------------------
				# write output
	if (! $par{"not_extract"}){
	    if ($max_val>=$par{"min_val"}) {
		$Linclude=1;}
	    else {
		$Linclude=0;} }
	else {
	    $Linclude=1;}

	if ($Linclude){		# 
	    push(@val,$max_val);	# store for averages
	    if ($par{"do_avlen"}) {
		push(@num,$htm_num);push(@avlen,$htm_avlen);}
	    &wrt_out_line($fhout,$sep,$par{"do_avlen"},$Lscreen,
			  $file_in,$max_pos,$max_val,$htm_num,$htm_avlen) 
		if (! $par{"not_file_out_wrt"}); }
	else {
	    if (! $par{"not_file_out_flag"}) {
		$tmp_file=$par{"file_out_flag"};
		if ($tmp_file eq "unk"){
		    $tmp=$file_in; $tmp=~s/^.*\///g; $tmp=~s/\.rdb.*$|\.phd.?rdb.*$//g;
		    $tmp_file=$par{"dir_work"}.$tmp.$par{"ext_file_out_flag"};}
		&open_file($fhout2, ">$tmp_file");
		print $fhout2 "claimed to be not a membrane protein\n";
		close($fhout2); }}
    }				# end of loop over all files
				# --------------------------------------------------

				# write averages (all global)
    &wrt_out_ave                if (($#val>1) && (! $par{"not_file_out_wrt"}));
	
    close($fhout)               if (! $par{"not_file_out_wrt"});
    

    if ($Lscreen && (! $par{"not_file_out_wrt"}) ) {
	&myprt_txt("$script_name: output in file: \t '$file_out'"); &myprt_line; }

    return(1,"ok");
}				# end of phd_htmisit

#==========================================================================================
sub ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------

				# include libraries
    $USERID=`whoami`; $USERID=~s/\s//g;
    if ($USERID eq "phd"){
	require "/home/phd/ut/perl/lib-br.pl";
	require "/home/phd/ut/perl/lib-ut.pl";}
    else { 
	$dir=0;
	foreach $arg(@ARGV){
	    if ($arg=~/dirLib=(.*)$/){$dir=$1;
				      last;}}
	if (! defined $dir || ! $dir || ! -d $dir) {
	    $dir=$dir || "/home/rost/pub/phd/scr/" || "/home/rost/perl/" || $ENV{'PERLLIB'} ||
		$ENV{'PWD'} || `pwd`; }
	if (! defined $dir || ! $dir || ! -d $dir) {
	    $tmp=$0; $tmp=~s/^\.\///g; $tmp=~s/^(.*\/)(.*)$/$1/; $tmp=~s/^scr\/?//g;
	    $dir=$tmp."scr/";  $dir=~s/\/$//g; }
	if (! defined $dir || ! $dir || ! -d $dir) {
	    $dir=""; }
	else { $dir.="/"     if ($dir !~/\/$/); }
	foreach $lib ("lib-br.pl","lib-ut.pl"){
	    require $dir.$lib ||
		die ("*** $scrName failed requiring perl libs \n".
		     "*** give as command line argument 'dirLib=DIRECTORY_WHERE_YOU_FIND:lib-ut.pl'"); }}

    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "htmisit_phd";
    $script_input=  "file_rdb_phd (list allowed, as well)";
    $script_goal=   "check for false positives (globular proteins predicted with HTM)";
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
    @script_opt_key=("not_extract",
		     "do_avlen",
		     "min_val=",
		     " ",
		     "title=",
		     "file_out_flag=",
		     "not_file_out_flag",
		     "not_file_out_wrt",
		     " ",
		     "ext_rdb_in=",
		     "ext_out",
		     " ",
		     "not_screen",
		     "dir_out=",
		     "dir_work=",
		     "dir_hssp=",
		     "dir_rdb=",
		     );
    @script_opt_keydes= 
	            ("do not restrict analysis to cases above threshold?",
		     "compute average length of helices",
		     "exclude all cases with average helix score > value ",
		     " ",
		     "title of output file",
		     "name of output file (x.not_membrane)",
		     "don't write a flag file with name x.not_membrane ",
		     "don't write results into output file (number of HTM, score, average len)",
		     " ",
		     "extension of PHD RDB file (output, i.e., refined PHDhtm)",
		     "extension of output file",
		     " ",
		     "no information written onto screen",
		     "output dir name,       default: local",
		     "working dir name,      default: local",
		     "dir of HSSP files,     default: local",
		     "dir of PHD.rdb files,  default: local",
		     );

    if ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
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
				# --------------------
				# executables
				# --------------------
				# directories
    $par{"dir_rdb"}=            "";
    $par{"dir_out"}=            "";
    $par{"dir_work"}=           "";
				# --------------------
				# files
    $par{"title"}=              "unk";
    $par{"file_out_flag"}=      "unk"; # flag file written if NOT membrane
				# file extensions
    $par{"ext_rdb_in"}=         "unk";
    $par{"ext_out"}=            ".dat";
    $par{"ext_file_out_flag"}=  ".not_membrane"; # flag file written if NOT membrane
				# file handles
    $fhout=                     "FHOUT";
    $fhout2=                    "FHOUT2";
    $fhin=                      "FHIN";
				# --------------------
				# further
    $par{"min_htm"}=            18; # minimal length of transmembrane helix
    $par{"min_val"}=            0.8; # minimal average helix score to be accepted
				# note: will be corrected if either 'isit_relax' or
				#       'isit_tense' chosen
    $min_tense=			0.8; # 2.5% false positives
#    $min_tense=			0.92; # 2.5% false positives  x.x
    $min_relax=			0.7; # 5.3% false positives

    $sep=                       "\t"; # separator for output file
				# --------------------
				# logicals
    $par{"not_extract"}=        1; #
    $par{"not_extract"}=        0; # evaluate only cases with score above threshold
    $par{"do_avlen"}=           0; # compute average length of helices?
#    $par{"do_avlen"}=           1; # compute average length of helices?
    $par{"not_file_out_flag"}=  0; # flag file written if NOT membrane
    $par{"not_file_out_wrt"}=   0; #
    $par{"isit_tense"}=         0; # take main_vla = 0.8
    $par{"isit_relax"}=         0; # take main_vla = 0.7
    $Lscreen=                   1; # blabla on screen
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    $des_aa=       "VLIMFWYGAPSTCHRKQEND";
    @des_aa=split(//,$des_aa);
    @des_def=     ("title","not_extract","do_avlen","min_val","file_out_flag",
		   "not_file_out_flag","not_file_out_wrt","ext_file_out_flag",
		   "isit_tense","isit_relax",
		   "ext_rdb_in","ext_out","dir_out","dir_work","dir_rdb");

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $file_in=                   $ARGV[1];
    $file_out=                  "unk";
    if ($#ARGV>$script_narg) {
	for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	    $_=$ARGV[$it];
	    next if ($_ =~ /^dirLib/);
	    if ( /not_screen/ ) {    $Lscreen=0; }
	    elsif(/not_extract/) {   $par{"not_extract"}=1; }
	    elsif(/do_avlen/) {      $par{"do_avlen"}=1; }
	    elsif(/isit_tense/) {    $par{"isit_tense"}=1; }
	    elsif(/isit_relax/) {    $par{"isit_relax"}=1; }
	    elsif(/not_file_out_wrt/){$par{"not_file_out_wrt"}=1; }
	    elsif(/not_file_out_flag/){$par{"not_file_out_flag"}=1; }
	    else {
		$Lok=0;
		foreach $des (@des_def){
		    if (/^$des=/){
			$_=~s/\s|\n|^.*$des=//g; $par{"$des"}=$_; $Lok=1; 
			last; 
		    }}
		if (! $Lok){print "*** $script_name: unrecognised argument: $_\n";
			    exit;}
	    } }}
    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    if ($file_out eq "unk") {
	if  ($par{"title"} ne "unk") {
	    $file_out=$par{"dir_out"}.$par{"title"}}
	else {
	    $tmp=$file_in; $tmp=~s/.*\///g; $tmp=~s/\..*$//g;
	    if (! $par{"not_extract"}){
		$file_out="Outextr_".$tmp; }
	    else {
		$file_out="Out_".$tmp; } }
	if ($par{"ext_out"} ne "unk") {
	    $file_out.=$par{"ext_out"};}}
    if (length($par{"dir_rdb"})>1) {  $par{"dir_rdb"}=&complete_dir($par{"dir_rdb"});
				      $tmp=$file_in; $file_in=$par{"dir_rdb"}."$tmp";}
    if (length($par{"dir_out"})>1) {  $par{"dir_out"}=&complete_dir($par{"dir_out"});
				      $tmp=$file_out; $file_out=$par{"dir_out"}."$tmp";}
    if (length($par{"dir_work"})>1) { $par{"dir_work"}=&complete_dir($par{"dir_work"}); }
				# minimal threshold filter
    if ($par{"isit_tense"}) { $par{"min_val"}=$min_tense; }
    if ($par{"isit_relax"}) { $par{"min_val"}=$min_relax; }

    # ------------------------------------------------------------
    # interpret input file
    # ------------------------------------------------------------
    $#file_in=0;
    if (-e $file_in) {		# input file exists (either RDB or list)
	if (! &is_rdbf($file_in)){ # list
	    &open_file("$fhin", "$file_in");
	    while (<$fhin>) {$_=~s/\n|\s//g;
			     next if (length($_)==0);
			     $Lok=0;
			     if (-e $_){$Lok=1;}
			     else { $tmp=$par{"dir_rdb"}."$_";
				    $Lok=1 if (-e $_); }
			     push(@file_in,$_) if ($Lok); }
	    close($fhin); }
	else {
	    push(@file_in,$file_in);}}
    else {			# does NOT exist -> must be PDBid!
	$tmp1=                  $file_in . $par{"ext_rdb_in"};
	$tmp2=$par{"dir_rdb"} . $file_in . $par{"ext_rdb_in"};
	$Lok=0;
	if    (-e $tmp1) { $Lok=1; $file_in=$tmp1; }
	elsif (-e $tmp2) { $Lok=1; $file_in=$tmp2; }
	else {
	    print "*** ERROR $script_name: input file '$file_in' missing\n";
	    exit;}}
	
    if ($Lscreen) { &myprt_line; &myprt_txt("$script_goal"); &myprt_empty; 
		    print "---\n--- end of '"."$script_name"."'_ini settings are:\n"; 
		    &myprt_txt("file_in: \t \t $file_in"); 
		    &myprt_txt("file_out:\t \t $file_out"); 
		    foreach $des (@des_def) {
			if ( (length($par{"$des"})>0) && ($par{"$des"} ne "unk") ) {
			    printf "--- %-20s '%-s'\n",$des,$par{"$des"};}}
		    &myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($file_in)>0) && (! -e $file_in) ) {
	&myprt_empty;&myprt_txt("ERROR $script_name:\t file_in '$file_in' does not exist");
	exit;}
}				# end of ini

#==========================================================================================
sub get_max_htm {
    local ($hmin) = @_ ;
    local ($sum,$it,$sum_max,$old,$new,$pos_max);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_max_htm                finds the maximal helix
#       in:                     $hmin (length of helix), @phd PHD output for helix unit
#       out:                    max_value and max_position
#--------------------------------------------------------------------------------
    $sum=0;			# compute first helix
    foreach $it (1..$hmin) {
	next if (!defined $phd[$it]);
	$sum+=$phd[$it];}
    $sum_max=$sum;$pos_max=1;
				# search maximal helix
    foreach $it (2..($#phd-$hmin+1)){
	$old=$phd[$it-1];
	$new=$phd[$it+$hmin-1];
	if ( ($sum-$old+$new) > $sum_max ){
	    $pos_max=$it;
	    $sum_max=$sum-$old+$new;}
	$sum=$sum-$old+$new; }
				# normalise maximum
    $sum_max=$sum_max/(100*$hmin);
    return($sum_max,$pos_max);
}				# end of get_max_htm

#==========================================================================================
sub get_avlen_htm {
    local ($numh,$lenh,$Lish,$phd,$ave);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_avlen_htm              compiles the average length of HTM's
#       in:                     $hmin (length of helix), @phd PHD output for helix unit
#       out:                    max_value and max_position
#--------------------------------------------------------------------------------
    $numh=$lenh=0;
    $Lish=0;
    foreach $phd (@phd) {
	if ($phd>=50) {
	    if (!$Lish) {
		$Lish=1;
		++$numh;}
	    ++$lenh;}
	elsif ($Lish){
	    $Lish=0;} }
    if ($lenh>0){		# average length
	$ave=int($lenh/$numh);}
    else {
	$ave=0;}
    return($numh,$ave);
}				# end of get_avlen_htm

#==========================================================================================
sub htmisit_rd {
    local ($file_in) = @_ ;
    local ($des,$it,@res,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   htmisit_rd                   reads the PHDhtm RDB files
#--------------------------------------------------------------------------------
    $des="OtH";
    %rd=&rd_rdb_associative($file_in,"not_screen","header","body",$des);
				# compose strings
    $#res=0;
    foreach $it (1..$rd{"NROWS"}){
	$tmp=$rd{"$des","$it"};
	$tmp=~s/\s//g;
	push(@res,$tmp);}
    undef %rd;
    undef %rd;
    return(@res);
}				# end of htmisit_rd

#==========================================================================================
sub wrt_out_header {
    local ($fhout,$file_out,$sep,$Lscreen,$Lavlen,$Lextract,$min_val) = @_ ;
    local (@fh,$fh);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_out_header             write header for output file  
#--------------------------------------------------------------------------------
    &open_file($fhout, ">$file_out");
    print  $fhout 
	"# NOTATION: beg    first residue in maximal helix\n",
	"# NOTATION: score  sum over PHD H output units\n",
	"# NOTATION: Nhtm   number of predicted HTM's\n",
	"# NOTATION: avlen  average length of predicted helices\n";
    if (! $Lextract) {
	print  $fhout "# \n# exclude only hits with:\n";
	printf $fhout "%-19s %5.2f\n# \n","#           score  >",$min_val; }

    $#fh=0; push(@fh,$fhout); if ($Lscreen){push(@fh,"STDOUT");}
    foreach $fh(@fh){
	if (! $Lavlen){
	    printf $fh "%-15s$sep%3s$sep%5s\n","name","beg","score"; }
	else {
	    printf $fh "%-15s$sep%3s$sep%5s$sep%3s$sep%3s\n","name","beg","score","Nhtm","avlen";}}
}				# end of wrt_out_header

#==========================================================================================
sub wrt_out_line {
    local ($fhout,$sep,$Lavlen,$Lscreen,$name,$beg,$val,$num,$avlen) = @_ ;
    local (@fh,$fh);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_out_line               write line for output file for one protein
#--------------------------------------------------------------------------------
    $#fh=0; push(@fh,$fhout); if ($Lscreen){push(@fh,"STDOUT");}

    $name=~s/^.*\///g; $name=~s/\.rdb.*$//g;

    foreach $fh(@fh){
	if (! $Lavlen){
	    printf $fh "%-15s$sep%3d$sep%5.2f$sep%3d$sep%3d\n",$name,$beg,$val; }
	else {
	    printf $fh
		"%-15s$sep%3d$sep%5.2f$sep%3d$sep%3d\n",$name,$beg,$val,$num,$avlen;} }
}				# end of wrt_out_line

#==========================================================================================
sub wrt_out_ave {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_out_ave                 write averages for output file for one protein
#--------------------------------------------------------------------------------
				# compute averages
    ($val_ave,$val_var)=&stat_avevar(@val);
    ($val_min)=&get_min(@val);($val_max)=&get_max(@val);
    ($num_ave,$num_var)=&stat_avevar(@num);
    if ($par{"do_avlen"}) {
	($avlen_ave,$avlen_var)=&stat_avevar(@avlen);
	($avlen_min)=&get_min(@avlen);($avlen_max)=&get_max(@avlen);
	$name="averages_".$#file_in; 
	printf $fhout
	    "%-15s$sep%3s$sep%5.2f$sep%3d$sep%3d\n",
	    $name,"-",$val_ave,int($num_ave),int($avlen_ave);
	$name="variances_".$#file_in;
	printf $fhout
	    "%-15s$sep%3s$sep%5.2f$sep%3d$sep%3d\n",
	    $name,"-",$val_var,int($num_var),int($avlen_var);
	$name="min_".$#file_in;
	printf $fhout
	    "%-15s$sep%3s$sep%5.2f$sep%3s$sep%3d\n",$name,"-",$val_min,"-",$avlen_min;
	$name="max_".$#file_in;
	printf $fhout
	    "%-15s$sep%3s$sep%5.2f$sep%3s$sep%3d\n",$name,"-",$val_max,"-",$avlen_max; }
    else {
	$name="averages_".$#file_in; 
	printf $fhout "%-15s$sep%3s$sep%5.2f\n",$name,"-",$val_ave;
	$name="variances_".$#file_in;
	printf $fhout "%-15s$sep%3s$sep%5.2f\n",$name,"-",$val_var;
	$name="min_".$#file_in;      
	printf $fhout "%-15s$sep%3s$sep%5.2f\n",$name,"-",$val_min;
	$name="max_".$#file_in;      
	printf $fhout "%-15s$sep%3s$sep%5.2f\n",$name,"-",$val_max;
    }
}				# end of wrt_out_ave

1;
