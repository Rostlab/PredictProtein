#!/usr/bin/perl
##------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#				version 0.2   	Oct,    	1998	       #
#------------------------------------------------------------------------------#

package phd_htmtop;

#===============================================================================
sub phd_htmtop {
#-------------------------------------------------------------------------------
#   phd_htmtop                  package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0



    @ARGV=@_;			# pass from calling

    &ini();

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
    if ($par{"mode"} eq "obs"){	# special output written for analysis of statistics
	$file_out=~s/\.rdb.*$/.dat/;
	&open_file($fhout, ">$file_out");
	print $fhout "# statistics for R and K in observed loops\n";
	foreach $desx("odd","even"){
	    foreach $aa (@des_20aa,"nres","npos"){$stat_ave{$desx,$aa}=0;}}
	&wrt_statistics_header($fhout,",");}
				# --------------------------------------------------
				# loop over files
				# --------------------------------------------------

    foreach $file_in (@file_in){
	if ($par{"do_htmref"}) {	# generate prediction
	    $file_rdb=
		&htmref_exe($file_in); }
	else {
	    $file_rdb=$file_in;}
				# read PHDhtm RDB files
	%res=&htmref_rd($file_rdb);

	print "--- \n--- ","-" x 60, "\n--- \n"     if ($Lscreen && $#file_in>1);
	print "--- now processing \t '$file_rdb'\n" if ($Lscreen);
	
				# read HSSP file?
	if ($par{"do_profile"}) {
	    $id=$file_rdb;$id=~s/^.*\/|\..*$//g;
	    print "file hssp=",$par{"file_hssp"},",\n";
	    if ($par{"file_hssp"} eq "unk") {
		$file_hssp=$par{"dir_hssp"}."$id".$par{"ext_hssp"}; }
	    else {
		$file_hssp=$par{"file_hssp"};}
				# purge chain?
	    if (! -e $file_hssp) {
		$file_hssp=~s/_(.)$//;
		$chain=$1;}
	    else {
		$chain="*"; }

	    if (! -e $file_hssp){
		print 
                    "\n","\n","\n",
		    "-*- WARN PHD_PROF_htmtop: could not find HSSP file ($file_hssp) -> no profile mode\n",
		    "-*-                  provide it by command line argument:\n",
		    "file_hssp=x\n","\n","\n","\n";
#		exit if (defined $ENV{'USER'} && $ENV{'USER'} eq "rost");
		$par{"do_profile"}=0; } }
	if ($par{"do_profile"}) {
	    ($file_hssp_ok,$seq_hssp,$nalign,$thresh)=
		&profile_rd($file_hssp,$id,$chain);
	    $file_hssp=$file_hssp_ok; # security
	    $res{"$id","nalign"}=$nalign;$res{"$id","thresh"}=$thresh;
	    if ($res{"AA"} ne $seq_hssp){
		print "*** WARNING $scrName: seq_phd ne seq_hssp ($file_hssp,$file_rdb)\n";
		&xprt_strings($res{"AA"},$seq_hssp);
		$par{"do_profile"}=0;  } }

	&profile_get($res{"AA"},@des_aa) if (! $par{"do_profile"}); 
	    
				# ------------------------------
				# predict topology
	if ($par{"mode"} eq "top"){
	    &pred_htmtop_top; }
	else {
	    &pred_htmtop;}
				# ------------------------------
				# write output rdb file
	if ($#file_in>1) {	# new name for output file
	    $file_out_rdb=$file_rdb; $ext_tmp=$par{"ext_rdb_top"};$dir_tmp=$par{"dir_out"};
	    $file_out_rdb=~s/^.*\/(.+)\..+$/$dir_tmp$1$ext_tmp/;}
	else {
	    $file_out_rdb=$file_out;}
	if ($par{"mode"} ne "obs"){ # no output written for analysis of statistics
	    &open_file($fhout, ">$file_out_rdb");
	    &wrt_rdb_htmtop($fhout,$file_rdb,"\t");
	    close($fhout);}
	else {
	    &wrt_statistics($fhout,",");}
    }				# end of loop over all files
				# --------------------------------------------------

    if ($par{"mode"} eq "obs"){
	&wrt_statistics_ave($fhout,",",$#file_in);
	close($fhout);}
    
    if ($Lscreen) {
	if (($#file_in==1) || ($par{"mode"} eq "obs") ){
	    print "--- $scrName: output in file: \t '$file_out'\n";}
	else {
	    $ext_tmp=$par{"ext_rdb_top"};
	    print "--- $scrName: output in files:\t '*$ext_tmp'\n";}}

				# delete intermediate files
    &clean_up(@file_del);

    return(1,"ok");
}				# end of tlprof_htmtop

#==========================================================================================
sub ini {
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------

    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
    $scrGoal="assigns the topology for a transmembrane protein";

    &iniDef();

				# ------------------------------
    if ($#ARGV < 1){		# help
	print  "goal: $scrGoal\n";
	print  "use:  '$scrName file_prof_rdb'  (or list, for profiles: HSSP recognised by extension!)\n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s %-10s %-s\n","","mode",   "no value","type of input RDB: nof|fil|ref|ref2|top";
	printf "%26s %-s\n",      "","NOTE: for mode=obs statistics on observed done, no prediction!\n";
	printf "%5s %-15s %-10s %-s\n","","do_htmref", "no value","also run htmref";
	printf "%5s %-15s %-10s %-s\n","","do_htmref_snd",   "no value","consider alternative model (2nd best)";
	printf "%5s %-15s %-10s %-s\n","","do_eval",   "no value","do the evaluation";
	printf "%5s %-15s %-10s %-s\n","","do_profile","no value","do profiles (i.e. positive inside for ali)";
	printf "%5s %-15s %-10s %-s\n","","force",     "no value","will force topology pred even for Nloop==1";

	printf "%5s %15s=%-10s %-s\n","","file_hssp", "x",       "HSSP file to read the profiles";
	printf "%5s %15s=%-10s %-s\n","","file_out",  "x",       "name of output file";

	printf "%5s %15s=%-10s %-s\n","","ext_hssp",   "x", "ext of HSSP file (include '.' e.g., '.hssp')";
	printf "%5s %15s=%-10s %-s\n","","ext_rdb_in", "x", "ext of PHD_PROF RDB file (input=pure PHD_PROFhtm)";
	printf "%5s %15s=%-10s %-s\n","","ext_rdb_ref","x", "ext of PHD_PROF RDB file (output=refined PHD_PROFhtm)";
	printf "%5s %15s=%-10s %-s\n","","ext_rdb_top","x", "extension of output file";
	
#	printf "%5s %15s=%-10s %-s\n","","",   "x", "";
#	printf "%5s %-15s  %-10s %-s\n","","",   "no value","";

	if (defined %par ){
	    $tmp= sprintf("%5s %-15s  %-10s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	    $tmp.=sprintf("%5s %-15s  %-10s %-s\n","","other:","default settings: "," ");
	    $tmp2="";
	    foreach $kwd (@kwd){
		next if ($kwd=~/^do_(eval|htmref|htmref_snd|profile)$/ ||
			 $kwd=~/^force$/ ||
			 $kwd=~/^file_(hssp|out)$/ ||
			 $kwd=~/^ext_(hssp|_rdb_in|rdb_ref|rdb_top)$/);
			 
		next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
		if    ($par{"$kwd"}=~/^\d+$/){
		    $tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
		elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		    $tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
		else {
		    $tmp2.=sprintf("%5s %-15s= %-10s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	    } 
	    print $tmp, $tmp2       if (length($tmp2)>1);
	}
    exit; }

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $file_in=                   $ARGV[1];
    $file_out=                  "unk";
    foreach $arg (@ARGV){
	next if ($arg eq $ARGV[1]);
	next if ($arg =~/dirLib/); # already done

	if    ( $arg=~/^not_?screen$/i)                 { $Lscreen=          0; }
	elsif ( $arg=~/^(verb[^=]*|de?bu?g)$/ )         { $Lscreen=          1; }
	elsif ( $arg =~ /^(ref|ref2|fil|nov|obs|top)$/) { $par{"mode"}=      $1; }
	elsif ( $arg eq "not_profile")                  { $par{"do_profile"}=0; }
	elsif ( $arg =~/^do_prof.*=(.*)/)               { $par{"do_profile"}=$1; }
	elsif ( $arg=~/^fileOut=(.*)$/)                 { $file_out=$par{"file_out"}=$1; }
	elsif ( $arg=~/^file_out=(.*)$/)                { $file_out=$par{"file_out"}=$1; }
	elsif ( $arg=~/^file_hssp=(.*)$/)               { $file_hssp=$par{"file_hssp"}=$1; }
	elsif ( $arg=~/\.hssp/)                         { $file_hssp=$par{"file_hssp"}=$arg; }
#	elsif ( $arg=~/^=(.*)$/){ $=$1;}
	elsif ( defined %par && $#kwd>0)       { 
	    $Lok=0; 
	    foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							    last;}}
	    if (! $Lok){ print "*** $scrName: wrong command line arg '$arg'\n";
			 exit;}}
	else { print "*** $scrName: wrong command line arg '$arg'\n"; 
	       exit;} }

    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    $par{"ext_rdb_top"}=~s/_refp.*\./_nof\./ if ($par{"mode"} eq "nof");
    $par{"ext_rdb_top"}=~s/_refp.*\./_fil\./ if ($par{"mode"} eq "fil");
    $par{"ext_rdb_top"}=~s/_refp.*\./_top\./ if ($par{"mode"} eq "top");
    if (defined $par{"file_out"}){
	$file_out=$par{"file_out"};}
    else {
	$file_out="unk";
	if  ($par{"title"} ne "unk") {
	    $file_out=$par{"dir_out"}.$par{"title"}}
	else {
	    $file_out=$file_in; $file_out=~s/.*\///g; $file_out=~s/\..*$//g;}
	$ext_rdb_top=$par{"ext_rdb_top"};
	if    ( ($par{"ext_rdb_top"} ne "unk") && ($file_out !~ /$ext_rdb_top$/) ) {
	    $file_out.=$par{"ext_rdb_top"};}
	elsif ( ($par{"ext_rdb_top"} eq "unk") && ($file_out !~ /\./) ) {
	    $file_out=$file_out.".rdb_out";}}

    if (length($par{"dir_rdb"})>1) {  $par{"dir_rdb"}=&complete_dir($par{"dir_rdb"});
				      $tmp=$file_in; $file_in=$par{"dir_rdb"}."$tmp";}
    if (length($par{"dir_out"})>1) {  $par{"dir_out"}=&complete_dir($par{"dir_out"});
				      $tmp=$file_out; $file_out=$par{"dir_out"}."$tmp";}
    if (length($par{"dir_work"})>1) { $par{"dir_work"}=&complete_dir($par{"dir_work"}); }

    # ------------------------------------------------------------
    # interpret input file
    # ------------------------------------------------------------
    $#file_in=0;
    if (-e $file_in) {		# input file exists (either RDB or list)
	if (! &is_rdbf($file_in)){ # list
	    &open_file("$fhin", "$file_in");
	    while (<$fhin>) {$_=~s/\n|\s//g;
			     if (length($_)==0) { next; }
			     $Lok=0;
			     if (-e $_){$Lok=1;}
			     else { $tmp=$par{"dir_rdb"}."$_";
				    if (-e $_){$Lok=1;}}
			     if ($Lok){ push(@file_in,$_);} }
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
	    print "*** ERROR $scrName: input file '$file_in' missing\n";
	    exit;}}
	
    if ($Lscreen) { print "---\n--- end of '"."$scrName"."'_ini settings are:\n"; 
		    print "--- file_in: \t \t $file_in\n"; 
		    print "--- file_out:\t \t $file_out\n";
		    foreach $kwd (keys %par) {
			printf "--- %-20s %-s\n",$kwd,$par{"$kwd"};}}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    die "*** ERROR $scrName: input file=$file_in, not existing !!\n" 
	if ( (length($file_in)>0) && (! -e $file_in) );
}				# end of ini

#===============================================================================
sub iniDef {
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."iniDef";

				# --------------------
				# executables
    $par{"exe_htmref"}=         "/nfs/data5/users/ppuser/server/pub/phd/scr/htmref_phd.pl";
#    $par{"exe_htmref"}=         "htmref_phd.pl";
				# --------------------
				# directories
    $par{"dir_rdb"}=            "";
    $par{"dir_hssp"}=           "/home/rost/data/hssp/";
    $par{"dir_hssp"}=           "/home/rost/data/hsspMembrane/";
    $par{"dir_out"}=            "";
    $par{"dir_work"}=           "";
				# --------------------
				# files
    $par{"title"}=              "unk";
    $par{"file_hssp"}=          "unk";
    $par{"file_obstop"}=        "piero_top.obs";
    $par{"file_obstop"}=        "Topo_obs_set83.dat";
    $par{"file_obstop"}=        "Topo_obs_set46.dat";
    $par{"file_obstop"}=        "Experiment_top.dat";
				# file extensions
    $par{"ext_rdb_in"}=         "unk";
    $par{"ext_rdb_ref"}=        "unk"; 
    $par{"ext_rdb_top"}=        "_refp.rdb_phdtop"; 

				# note: if 'unk' the files generated by exe_htmref
				#       will be deleted in end, otherwise they'll be stored
    $par{"ext_hssp"}=           ".hssptm";
    $par{"ext_out"}=            "unk";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
				# --------------------
				# further
    $par{"htmref_Lmin"}=        18;    # minimal length of transmembrane helix
    $par{"htmref_Lmax"}=        27;    # maximal length of transmembrane helix
    $par{"htmref_Lloop"}=       4;     # minimal length of loop region between two HTM's
    $par{"htmref_Tgrid"}=       100;   # grid for comparing scores (avoid always short segments)
    $par{"htmref_Tminval"}=     0.4;   # to reduce CPU time, only segments treated with a 
    $par{"htm_weak"}=           0.8;   # when compiling models based on highest charge difference,
				       # all HTM's > this will be treated as certain!
				       #      per-residue score > $Tmin_score

    $par{"mode"}=               "ref"; # mode for reading RDB file (nof,fil,ref,ref2,top) 
				       #    NOTE: recognised by word
				       # for mode = obs=>statistics on observed will be done, no prediction
				       #    
				       #    

#    $par{"max_Lloop"}=         200;    # for longer loops take only flanking residues
    $par{"max_Lloop"}=          60;    # for longer loops take only flanking residues
#    $par{"max_Lloop_flank"}=    60;    # number of flanking residues
#    $par{"max_Lloop_flank"}=    40;    # number of flanking residues
#    $par{"max_Lloop_flank"}=    30;    # number of flanking residues
				# this seems to be taken!! (99-07)
    $par{"max_Lloop_flank"}=    25;    # number of flanking residues

#    $par{"max_Lloop_flank"}=    20;    # number of flanking residues
#    $par{"max_Lloop_flank"}=    15;    # number of flanking residues
				# --------------------
				# logicals
    $Lscreen=                   1; # blabla on screen
    $par{"do_htmref"}=          0; # do execute the refinement (just read the files)
#    $par{"do_htmref"}=          1; # do execute the refinement (just read the files)
    $par{"do_htmref_snd"}=      0; # do use 2nd best model
#    $par{"do_htmref_snd"}=      1; # do use 2nd best model

    $par{"do_eval"}=            0; # read observed segments
    $par{"do_profile"}=         0; # read the HSSP profiles for applying positive inside rule
    $par{"do_profile"}=         1; # read the HSSP profiles for applying positive inside rule
    $par{"force"}=              0;
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    $des_aa=       "VLIMFWYGAPSTCHRKQEND";
    @des_aa=split(//,$des_aa);
    @des_positive_res=("K","R");
    @des_20aa=("K","R","A","C","D","E","F","G","H","I","L","M","N","P","Q","S","T","V","W","Y");
    @aa_pos=  ("K","R");
    @aa_neg=  ("D","E");
    @aa_hyd=  ("A","I","L","V");
#    @aa_p=("P");@aa_f=("F");@aa_m=("M");@aa_c=("C");@aa_g=("G");
    @aa_pol=  ("N","Q","S","T","Y");
    @aa_bdg=  ("H","W");
}				# end of iniDef


#==============================================================================
# library collected (begin)
#==============================================================================

#==============================================================================
sub complete_dir { return(&completeDir(@_)); } # alias

#===============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir

#==============================================================================
sub func_absolute {
    local ($num)=@_;local ($tmp);
#----------------------------------------------------------------------
#   func_absolute               compiles the absolute value
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
    if ($num>=0){
	return($num);}
    else {
	$tmp=(-1)*$num;
	return($tmp);}
}				# end of func_absolute

#==============================================================================
sub func_permut_mod {
    local ($num)=@_;
    local (@mod_out,@mod_in,@mod,$it,$tmp,$it2,@tmp); 
    $[=1;
#----------------------------------------------------------------------
#   func_permut_mod             computes all possible permutations for $num, e.g. n=4:
#                               output is : '1,2' '1,3' '1,4' '2,3' asf.
#       in:                     $num
#       out:                    @permutations (as text:'n,m,..')
#----------------------------------------------------------------------
    $#mod=$#mod_out=0;
    foreach $it (1..$num){
	if ($it==1) { 
	    foreach $it2 (1 .. $num) {
		$tmp="$it2"; 
		push(@mod,$tmp);} }
	else {
	    @mod_in=@mod;
	    @mod=&func_permut_mod_iterate($num,@mod_in); }
	push(@mod_out,@mod); }
    return(@mod_out);
}				# end of func_permut_mod

#==============================================================================
sub func_permut_mod_iterate {
    local ($num,@mod_in)=@_;
    local (@mod_out,$it,$tmp,@tmp); 
    $[=1;
#----------------------------------------------------------------------
#   func_permut_mod_iterate     repeats permutations (called by func_permut_mod)
#                               computes all possible permutations for $num 
#                               (e.g. =4) as maximum, and
#       input is :              '1,2' '1,3' '1,4' '2,3' asf.
#----------------------------------------------------------------------
    $#mod_out=0;
    foreach $it (1..$#mod_in){
	@tmp=split(/,/,$mod_in[$it]);
	foreach $it2 (($tmp[$#tmp]+1) .. $num) {
	    $tmp="$mod_in[$it]".","."$it2";
	    push(@mod_out,$tmp);}}
    return(@mod_out);
}				# end of func_permut_mod_iterate

#==============================================================================
sub get_secstr_segment_caps {
    local ($string,@des) = @_ ;
    local ($des,$it,@beg,@end,%segment);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_secstr_segment_caps     returns positions of secondary str. segments in string
#       out:                    $segment{"H","beg",1}= first residue in first helix
#                               $segment{"H","end",1}= last residue in first helix
#--------------------------------------------------------------------------------
				# convert vector to array (begin and end different)
    @aa=("#");push(@aa,split(//,$string)); push(@aa,"#");

    foreach $des (@des) {
	$#beg=$#end=0;		# loop over all residues
	foreach $it ( 2 .. $#aa ){ # note 1st and last ="#"
	    if   ( ($aa[$it] ne $des) && ($aa[$it-1] eq $des) ){
		push(@end,($it-2)); }
	    elsif( ($aa[$it] eq $des) && ($aa[$it-1] ne $des) ){
		push(@beg,($it-1)); }  }
	if ($#end != $#beg) {	# consistency check!
	    print "*** get_secstr_segment_caps: des=$des, Nend=",$#end,", Nbeg=",$#beg,",\n";
	    exit;}
	foreach $it (1..$#end){	# store segment begins (Ncap) and ends (Ccap)
	    $segment{$des,"beg",$it}=$beg[$it];
	    $segment{$des,"end",$it}=$end[$it]; } 
	$segment{$des,"NROWS"}=$#beg;
    }
    return(%segment);
}				# end of get_secstr_segment_caps

#==============================================================================
sub is_odd_number {
    local($num)=@_ ;
#--------------------------------------------------------------------------------
#   is_odd_number               checks whether number is odd
#       in:                     number
#       out:                    returns 1 if is odd, 0 else
#--------------------------------------------------------------------------------
    return 0 if (int($num/2) == ($num/2));
    return 1;
}				# end of is_odd_number

#==============================================================================
sub is_rdbf {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_rdbf                     checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_rdbf

#==============================================================================
sub myprt_array {
    local($sep,@A)=@_;$[=1;local($a);
#   myprt_array                 prints array ('sep',@array)
    foreach $a(@A){print"$a$sep";}
    print"\n" if ($sep ne "\n");
}				# end of myprt_array

#==============================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    if ( int($npoints/10)!=($npoints/10) ) {
	print "*** ERROR in myprt_npoints (lib-br.pl): \n";
	print "***       number of points should be multiple of 10 (is $npoints)!\n"; 
	return(" "); }
    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
	    $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ($i==($npoints/10) && $ctprev>=9){
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else                                   {
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

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
    &open_file("$fhin","$file_in");
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
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
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
		if ($rd eq $des_in) {$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);
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
	$it=$ptr_rd2des{"$des_in"};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}

    $nrow_rd=0;$names="";
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if ($nrow_rd==0){
	    $nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){
	    print "*** WARNING $sbr_name: different number of rows\n";
	    print "*** WARNING in RDB file '$file_in' for rows with ".
		  "key= $des_in and previous column no=$itrd,\n";}
	$names.="$des_in".",";
	for($it=1;$it<=$#tmp;++$it){
	    $rdrdb{"$des_in",$it}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==============================================================================
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
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT= 0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {$READHEADER.= "$_"; # header  
		      next;}
	++$ct;			# rest
	if ( $ct >= 3 ) {	              # col content
	    @tmpar=split(/\t/);
	    for ($it=1; $it<=$#readnum; ++$it) {
		if (defined $tmpar[$readnum[$it]]) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }} }
	elsif ( $ct==1 ) {	      # col name
	    $_=~s/\t$//g;@tmpar=split(/\t/);
				# care about wild card
	    if ( ($#readnum==0)||($readnum[1]==0) ) {
		for ($it=1;$it<=$#tmpar;++$it) {$readnum[$it]=$it;}
		for ($it=1;$it<=$#tmpar;++$it) {$READCOL[$it]=""; } }
	    
	    for ($it=1; $it<=$#readnum; ++$it) {$tmp_name=$tmpar[$readnum[$it]];
						$tmp_name=~s/\s|\n//g;
						$READNAME[$it]="$tmp_name";} }
	elsif ( $ct==2 ) {	      # col format
	    if ($_=~/\t\d+[NSF]|\d+[NSF]\t/){
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		    $READFORMAT[$it]=$tmp;}}
	    else {		# no format given, read line
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    if (defined $tmpar[$readnum[$it]]) {
			$READCOL[$it].=$tmpar[$readnum[$it]] . "\t";}}}}
    }
    for ($it=1; $it<=$#READNAME; ++$it) {
	if (!defined $READFORMAT[$it]){
	    print "-*- WARN lib-br.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";}
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of read_rdb_num2



#==============================================================================
# library collected (end)
#==============================================================================


#======================================================================
sub clean_up {
    local(@file)=@_;;
    $[ =1 ;
#--------------------------------------------------
#   clean up for cross validation
#--------------------------------------------------
    foreach $file (@file) {
	next if (! -e $file);
	print "--- clean_up \t \t '\\rm $file'\n";
	unlink($file);}
}				# end of clean_up

#================================================================================
sub comp_charge {
    local ($beg,$end,$itloop,$nloop,$Lscreen_loc)=@_;
    local (@beg_loc,@end_loc,$tmp,$aa,%tmp,$itflank,$itres,$ct_charge);
    $[=1;
#----------------------------------------------------------------------
#   computes the charge for one loop
#----------------------------------------------------------------------
				# ------------------------------
				# get flanking beg/end
    if ( ($end-$beg+1) > $par{"max_Lloop"} ) { # take only flanking regions
	$#beg_loc=$#end_loc=0;	# ini
	if ($itloop>1){	# all but first
	    push(@beg_loc,$beg);
	    push(@end_loc,($beg+$par{"max_Lloop_flank"}-1));}
	if ($itloop<$nloop){ # all but last
	    push(@beg_loc,($end-$par{"max_Lloop_flank"}+1));
	    push(@end_loc,$end);}}
    else {
	@beg_loc=($beg);@end_loc=($end); }
    $tmp=0;
    foreach $aa (@des_20aa){
	$tmp{$aa}=0;} # ini
				# ------------------------------
				# sum positive over segment
    $ct_charge=$ctres=0;
    foreach $itflank (1..$#beg_loc){
	$beg=$beg_loc[$itflank];$end=$end_loc[$itflank];
	foreach $itres( $beg .. $end ) {
	    ++$ctres;
	    foreach $aa (@des_positive_res){	# sum over positive residues (K,R)
		$ct_charge+=($profile{$aa,$itres}/100); }}
	print"--- comp_charge: seg=$itloop, flank=$itflank, pos:$beg-$end, charge=$ct_charge\n"
	    if ($Lscreen_loc);
    }			# end of loop over flanks
    return($ct_charge,$ctres);
}				# end of comp_charge

#==========================================================================================
sub comp_charge_diff {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    comp_charge_diff           computes the charge differences
#       in: GLOBAL              @beg,@end (begin and end of all loops)
#       out:
#         A                     A
#--------------------------------------------------------------------------------
    $#eveC=$#oddC=$#eveN=$#oddN=0;$eveC=$oddC=$eveN=$oddN=0;	# ini
    $Lscreen_loc=0;
    $Lscreen_loc=1;		# x.x
				# ----------------------------------------
				# summed charge differences
    foreach $it2 (1..int($#beg/2)){
	$itodd=2*$it2-1;$iteve=2*$it2;
	($charge,$nres)=&comp_charge($beg[$itodd],$end[$itodd],$itodd,$#beg,$Lscreen_loc);
	$oddC+=$charge;$oddN+=$nres;$oddC[$itodd]=$charge;$oddN[$itodd]=$nres;
	($charge,$nres)=&comp_charge($beg[$iteve],$end[$iteve],$iteve,$#beg,$Lscreen_loc);
	$eveC+=$charge;$eveN+=$nres;$eveC[$iteve]=$charge;$eveN[$iteve]=$nres; }
    if (&is_odd_number($#beg)){	# last loop
	$itodd=$#beg;
	($charge,$nres)=&comp_charge($beg[$itodd],$end[$itodd],$itodd,$#beg,$Lscreen_loc);
	$oddC+=$charge;$oddN+=$nres;$oddC[$itodd]=$charge;$oddN[$itodd]=$nres; }
				# ----------------------------------------
    $Deach=0;			# charge differences for each segment
    foreach $it2 (1.. ($#beg-1)){
	if ( &is_odd_number($it2) ) {
	    $Deach+=( ($eveC[$it2+1]/$eveN[$it2+1])-($oddC[$it2]/$oddN[$it2]) );}
	else {
	    $Deach+=( ($eveC[$it2]/$eveN[$it2])-($oddC[$it2+1]/$oddN[$it2+1]) );} }
				# ----------------------------------------
				# now make decision positive inside!
    $top_diff_all=100*(($eveC/$eveN)-($oddC/$oddN));
    $top_diff_sep=100*($Deach/($#beg-1));
    return($top_diff_all,$top_diff_sep);
}				# end of comp_charge_diff

#================================================================================
sub comp_mix_permut_arrays {
    local (@mod_in)=@_;
    local (@mod_out,$it,$tmp,$it1,@tmp,@tmp2,@stmp,$stmp); 
    $[=1;
#----------------------------------------------------------------------
#   @mod = permutations of @weak, @strong will be sorted into that
#   GLOBAL: @weak,@strg
#----------------------------------------------------------------------
    $#mod_out=0;
				# first 0 assumption: no weak one
    if ($#strg>0){
	$#stmp=0; @stmp=sort bynumber(@strg);
	$tmp=""; foreach $stmp (@stmp){$tmp.="$stmp".",";}
	push(@mod_out,$tmp);}
				# now: add permutations of weak models
    foreach $it (1..$#mod_in){
	$#tmp=0;  
	@tmp=split(/,/,$mod_in[$it]); # text: '1,2,5' -> numbers
	$#tmp2=0;
	foreach $tmp(@tmp){	# numbers to original numbers
	    push(@tmp2,$weak[$tmp]);}
	$#tmp=0;  @tmp=(@strg,@tmp2);
	$#stmp=0; @stmp=sort bynumber (@tmp);
	$tmp="";
	foreach $stmp (@stmp){
	    $tmp.="$stmp".",";}
	push(@mod_out,$tmp);}
    return(@mod_out);
}				# end of comp_mix_permut_arrays

#==========================================================================================
sub comp_sorting_models_rd {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    comp_sorting_models_rd     sorting the models according to residue numbers
#--------------------------------------------------------------------------------
    $#beg=0;
    foreach $it (1..$res{"MODEL_DAT","nmod"}){
	$beg=$res{"MODEL_DAT","range",$it};$beg=~s/^(\d+)\-.*$/$1/g;
	$ptr{"$beg"}=$it;
	push(@beg,$beg);
    }
    $#stmp=0;@stmp=sort bynumber(@beg);
    foreach $it (1..$res{"MODEL_DAT","nmod"}){
	$tmp=$ptr{"$stmp[$it]"};
	$res_sorted{"MODEL_DAT","range",$it}=$res{"MODEL_DAT","range",$tmp};
	$res_sorted{"MODEL_DAT","max",$it}=  $res{"MODEL_DAT","max",$tmp};
	$res_sorted{"MODEL_DAT","score",$it}=$res{"MODEL_DAT","score",$tmp};}
}				# end of comp_sorting_models_rd


#==========================================================================================
sub conv_all2loop {
    local (@in)=@_;
    local (@out,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    conv_all2loop               input: all segments out> loops
#--------------------------------------------------------------------------------
    foreach $tmp (@in){
	next if ($tmp !~ /loop/);
	($range,$_)=split(/,/,$tmp);
	push(@out,$range); }
    return(@out)
}				# end of conv_all2loop

#==========================================================================================
sub conv_htm2all {
    local ($nres,@htm)=@_;
    local (@beg,@end,$it,$tmp,$tmp1,$it1,@seg_loc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    conv_htm2all               input: HTM's (beg-end) output: all segments (beg-end)
#--------------------------------------------------------------------------------
    $#beg=$#end=0;
    foreach $it (1..$#htm){
	$tmp=$htm[$it];
	($beg,$end)=split(/-/,$tmp);
	push(@beg,$beg);push(@end,$end);}
    foreach $it (1..$#beg){
	if ($it==1){$beg=1;}
	else       {$it1=$it-1;$beg=($end[$it1]+1);}
	$end=($beg[$it]-1);
	$tmp="$beg-$end,loop";
	push(@seg_loc,$tmp);
	$tmp="$beg[$it]-$end[$it],htm";
	push(@seg_loc,$tmp);}
    $tmp1=$end[$#end]+1;
    $tmp="$tmp1-$nres,loop";
    push(@seg_loc,$tmp);
    return(@seg_loc)
}				# end of conv_htm2all

#==========================================================================================
sub get_final {
    local ($mode,$Lscreen_loc) = @_ ;
    local (@htm,$string_prd,$ctL,$ctH);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_final                  compiles the final results
#--------------------------------------------------------------------------------
    if    ($mode eq "all") {@seg_all=@max_seg_all;$nloop=$#max_loop_all;$diff=$max_diff_all;}
    elsif ($mode eq "sep") {@seg_all=@max_seg_sep;$nloop=$#max_loop_sep;$diff=$max_diff_sep;}
			    
    else {
	print "*** get_final mode = 'all', or 'sep' given: $mode,\n";
	exit;}
				# separate loops and HTM
    $#htm=0;$string_prd="";$ctL=$ctH=0;
    foreach $seg(@seg_all){
	if ($seg=~/loop/){($tmp,$_)=split(/,/,$seg);($beg,$end)=split(/-/,$tmp);++$ctL;
			  $seg{"L","beg","$ctL"}=$beg;$seg{"L","end","$ctL"}=$end;
			  $string_prd.="L" x ($end-$beg+1);}
	else             {($tmp,$_)=split(/,/,$seg);($beg,$end)=split(/-/,$tmp);++$ctH;
			  $seg{"H","beg","$ctH"}=$beg;$seg{"H","end","$ctH"}=$end;
			  $string_prd.="H" x ($end-$beg+1);
			  $tmp="$beg-$end";push(@htm,$tmp);}}
    $seg{"L","NROWS"}=$nloop;$seg{"H","NROWS"}=$#htm;

				# get final topology
    if ($diff<0){$top_pred="in";}else{$top_pred="out";}
    $top_string=
	&get_top_string($des_prd,$top_pred);

    $res{$des_prd,"diff",$mode}=  $diff;
    $res{$des_prd,"pred",$mode}=  $top_pred;
    $res{$des_prd,"string",$mode}=$top_string;
    $res{$des_prd,"mod_top",$mode}=$string_prd;
    $res{$des_prd,"nhtm",$mode}=  $#htm;

    
    print 
	"--- get_final mode=$mode, Nloop=",$seg{"L","NROWS"},", Nhtm=",$seg{"H","NROWS"},",\n"
	    if ($Lscreen_loc);
}				# end of get_final

#==========================================================================================
sub get_max_charge {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_max_charge             assigns some values to model with max Delta charge
#    NOTE: all variables GLOBAL
#--------------------------------------------------------------------------------
    if (&func_absolute($top_diff_all)>$max_all){
	$max_all=&func_absolute($top_diff_all);
	$max_diff_all=$top_diff_all;
	$max_pos_all=$it;
	$max_eveC=$eveC;$max_eveN=$eveN;$max_oddC=$oddC;$max_oddN=$oddN;
	@max_seg_all=@all_seg;@max_loop_all=@loop;}

    if (&func_absolute($top_diff_sep)>$max_sep){
	$max_sep=&func_absolute($top_diff_sep);
	$max_diff_sep=$top_diff_sep;
	$max_pos_sep=$it;
	@max_seg_sep=@all_seg;@max_loop_sep=@loop;}
}				# end of get_max_charge

#==========================================================================================
sub get_top_string {
    local($des_prd,$top_pred_in)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_top_string      build up the topology string 
#                               " " means in, "o" means out
#--------------------------------------------------------------------------------
    $top_string="";
    if ($top_pred_in eq "in"){$sym1=" ";$sym2="o"; }
    else                     {$sym1="o";$sym2=" "; }
    $cth=$ctl=$ctres=0;
    if ($res{$des_prd}=~/^H/){ # prediction starting with HTM?
	++$cth;
	foreach $itres($seg{"H","beg","$cth"}..$seg{"H","end","$cth"}){
	    ++$ctres;
	    $top_string.="T";}}
    while( ($cth+$ctl) <= ($seg{"L","NROWS"}+$seg{"H","NROWS"}) ) {
	++$ctl;
	$sym=$sym2;
	$sym=$sym1              if (&is_odd_number($ctl));
	    
	foreach $itres($seg{"L","beg","$ctl"}..$seg{"L","end","$ctl"}){
	    ++$ctres;
	    $top_string.=$sym;}
	last if ($ctres>=length($res{$des_prd}));
	++$cth;
	foreach $itres($seg{"H","beg","$cth"}..$seg{"H","end","$cth"}){
	    ++$ctres;
	    $top_string.="T";}
	last if ($ctres>=length($res{$des_prd}));}
    return($top_string);
}				# end of get_top_string

#==========================================================================================
sub htmref_exe {
    local ($file_in) = @_ ;
    local ($exe,@des,$file_out,$id,$arg);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   htmref_exe                  does the refinement (calling htmref)
#--------------------------------------------------------------------------------
    $exe=$par{"exe_htmref"};
    @des=("htmref_Lmin","htmref_Lmax","htmref_Lloop","htmref_Tgrid","htmref_Tminval");
    if ($par{"ext_rdb_ref"} eq "unk") {
	$file_out="HTMREF_".$$.".rdb"; push(@file_del,$file_out); }
    else {
	$id=$file_in;$id=~s/^.*\/|\..*$//g;
	$file_out=$par{"dir_out"}."$id" . $par{"ext_rdb_ref"}}

    $arg="file_out=$file_out not_screen";
    foreach $des(@des){
	$arg.=" $des=".$par{$des};}
    
    print "--- system:           '$exe $file_in $arg'\n" if ($Lscreen);
    system("$exe $file_in $arg");
    return($file_out)           if (-e $file_out);

    print "*** ERROR $scrName-htmref_exe: no output '$file_out'\n";
    return(0);
}				# end of htmref_exe

#==========================================================================================
sub htmref_rd {
    local ($file_in) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   htmref_rd                   reads the PHDhtm RDB files
#--------------------------------------------------------------------------------
				# merely read files
    $#des_prd=0;
    @des_rd=("AA");
    @header=();
    if ($par{"do_eval"}) { push(@des_rd,"OHL"); }
    if    ($par{"mode"} eq "ref")  {push(@des_rd,"PRHL");push(@des_prd,"PRHL");
				    push(@header,"MODEL_DAT");
				    if ($par{"do_htmref_snd"}) {
					push(@des_rd,"PR2HL");push(@des_prd,"PR2HL");}}
    elsif ($par{"mode"} eq "ref2") {push(@des_rd,"PR2HL");push(@des_prd,"PR2HL");}
    elsif ($par{"mode"} eq "fil")  {push(@des_rd,"PFHL"); push(@des_prd,"PFHL");}
    elsif ($par{"mode"} eq "nof")  {push(@des_rd,"PHL");  push(@des_prd,"PHL");}
    elsif ($par{"mode"} eq "obs")  {push(@des_rd,"OHL");  push(@des_prd,"OHL");}
    elsif ($par{"mode"} eq "top")  {push(@des_rd,"PRHL");push(@des_prd,"PRHL");
				    push(@header,"MODEL_DAT");}
    else  { print "*** ERROR in $scrName, mode not recognised '",$par{"mode"},"'\n";
	    exit;} 

    %rd=&rd_rdb_associative($file_in,"not_screen","header",@header,"body",@des_rd);
				# compose strings
    @des_out=@des_rd;
    foreach $des(@des_out){
	$res{$des}="";
	foreach $it (1..$rd{"NROWS"}){
	    $res{$des}.=$rd{$des,$it};}}
    if (defined $rd{"MODEL_DAT"}){
	@tmp=split(/\t/,$rd{"MODEL_DAT"});
	foreach $it(1..$#tmp){
	    $tmp=$tmp[$it];
	    $tmp=~s/^[\s:,]*|[\s:,]*$//g;
	    @tmp2=split(/,/,$tmp);foreach $tmp(@tmp2){$tmp=~s/\s//g;}
	    $res{"MODEL_DAT","score",$it}=$tmp2[2];
	    $res{"MODEL_DAT","max",$it}=  $tmp2[3];
	    $res{"MODEL_DAT","range",$it}=$tmp2[4];
	    $res{"MODEL_DAT","nmod"}=$it;}}
	 undef %rd;
    return(%res);
}				# end of htmref_rd

#==========================================================================================
sub pred_htmtop {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    pred_htmtop                       
#--------------------------------------------------------------------------------
    foreach $des_prd(@des_prd){	# possibly best and 2nd best; or refine and filter
	if ($res{$des_prd}=~/^LLLH|^LLH|^LH/){
	    $res{$des_prd}=~s/^LLLH/HHHH/;
	    $res{$des_prd}=~s/^LLH/HHH/;
	    $res{$des_prd}=~s/^LH/HH/;}
	%seg=
	    &get_secstr_segment_caps($res{$des_prd},"H","L");
	next if (($seg{"L","NROWS"}==1)&&(! $par{"force"}) ) ;
	print 
	    "--- pred_htmtop \t $des_prd, Nloop=",
	    $seg{"L","NROWS"},", Nhtm=",$seg{"H","NROWS"},", \n" if ($Lscreen);
	$even=$odd=$ct_even=$ct_odd=$Lodd=0; # ini
	foreach $desx("odd","even"){
	    foreach $aa (@des_20aa,"nres"){
		$stat{$desx,$aa}=0;}}
				# --------------------------------------------------
				# sum over all segments
	$ct_even=$ct_odd=0;
	for($it=1;$it<=$seg{"L","NROWS"};++$it){
				# ------------------------------
				# odd or even
	    if (($it/2)!=int($it/2)){ # odd
		$Lodd=1;$beg=$seg{"L","beg",$it};$end=$seg{"L","end",$it}; }
	    else {		     # even
		$Lodd=0;$beg=$seg{"L","beg",$it};$end=$seg{"L","end",$it}; }
				# ------------------------------
				# get flanking beg/end
	    if ( ($end-$beg+1) > $par{"max_Lloop"} ) { # take only flanking regions
		$#beg=$#end=0;	# ini
		if ($it>1){	# all but first
		    push(@beg,$beg);push(@end,($beg+$par{"max_Lloop_flank"}-1));}
		if ($it<$seg{"L","NROWS"}){ # all but last
		    push(@beg,($end-$par{"max_Lloop_flank"}+1));push(@end,$end);}}
	    else {
		@beg=($beg);@end=($end); }
	    print "--- seg no=$it, pos:$beg-$end,\n" if ($Lscreen);
	    $tmp=0;foreach $aa (@des_20aa){$tmp{$aa}=0;}
				# ------------------------------
				# sum positive over segment
	    foreach $itflank (1..$#beg){
		$beg=$beg[$itflank];$end=$end[$itflank];
		foreach $itres( $beg .. $end ) {
		    if ($Lodd){++$ct_odd;}else{++$ct_even;}
		    foreach $aa (@des_positive_res){	# sum over positive residues (K,R)
			$tmp+=($profile{$aa,$itres}/100); }}
		if ($par{"mode"} eq "obs"){ # for analysis of observed statistics
		    foreach $itres( $beg .. $end ) {foreach $aa (@des_20aa){
			$tmp{$aa}+=($profile{$aa,$itres}/100);}}
		    if($Lodd){foreach $aa (@des_20aa){$stat{"odd",$aa}+=$tmp{$aa};}}
		    else     {foreach $aa (@des_20aa){$stat{"even",$aa}+=$tmp{$aa};}}}
	    }			# end of loop over flanks
	    if ($Lodd){ $odd+=$tmp;}else { $even+=$tmp;}
	    if ($par{"mode"} eq "obs"){ # for analysis of observed statistics
		$stat{"odd","nres"}=$ct_odd;$stat{"even","nres"}=$ct_even;}
	}			# end of loop over loops

	$ct_even=1 if ($ct_even<1);
	$ct_odd=1  if ($ct_odd<1);
	$top_diff=100*(($even/$ct_even)-($odd/$ct_odd));
	if ($Lscreen){
	    print "even:ct=$ct_even,sum=$even, perc =",100*($even/$ct_even),",\n";
	    print "odd :$ct_odd, sum=$odd, perc =",100*($odd/$ct_odd),", diff=$top_diff,\n";}
	if ($top_diff<0) { $top_pred="in";} 
	else             { $top_pred="out";}
	if ($par{"mode"} ne "obs") { # no writing for analysis of observed statistics
	    &get_top_string($des_prd,$top_pred);}

	$res{$des_prd,"diff"}=  $top_diff;
	$res{$des_prd,"pred"}=  $top_pred;
	$res{$des_prd,"string"}=$top_string;

	if ($Lscreen) {
	    printf "--- mode=%-5s,  %-s=%5.1f (Nres=%5d), %-s=%5.1f (Nres=%5d)\n",
	           $des_prd,"%(R+K)even",$even,$ct_even,"%(R+K)odd",$odd,$ct_odd;
	    printf "--- pred=%-5s, D(even-odd)=%8.3f\n",$top_pred,$top_diff;
	    $tmp=$res{"AA"};$tmp=~s/[^KR]/ /g;
	    if ($par{"mode"} ne "obs") { # no writing for analysis of observed statistics
		&xprt_strings($res{"AA"},$tmp,$res{$des_prd},$top_string);}}
    }
				# ------------------------------
				# highest difference = prediction
    $max=$des_max=0;
    if   ($#des_prd>1)    {
	foreach $des_prd(@des_prd){
	    $abs=sqrt($res{$des_prd,"diff"}*$res{$des_prd,"diff"});
	    if ($abs>$max){$max=$abs;
			   $des_max=$des_prd;}}}
    elsif($#des_prd==1)   {
	$des_max=$des_prd[1];
	if (! defined $res{"$des_prd[1]","diff"}){
	    $max=0;}
	else {$max=sqrt($res{"$des_prd[1]","diff"}*$res{"$des_prd[1]","diff"});}}
    else                  {$des_max="PRHL";$max=0;}
    foreach $des ("diff","pred","string"){
	if (! defined $res{"$des_max",$des}){
	    $res{"top_fin",$des}=0     if ($des eq "diff");
	    $res{"top_fin",$des}="unk" if ($des eq "pred");
	    $res{"top_fin",$des}=" "   if ($des eq "string");}
	else {$res{"top_fin",$des}=$res{"$des_max",$des};}}
}				# end of pred_htmtop

#==========================================================================================
sub pred_htmtop_top {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    pred_htmtop_top                       
#--------------------------------------------------------------------------------
    $des_prd=$des_prd[1];
    $Lscreen_loc=1;		# x.x

    &comp_sorting_models_rd;	# first sort models read in RDB header
				# separate into weakly and strongly predicted HTM's
    $nhtm=$res{"MODEL_DAT","nmod"};
    $#weak=$#strg=0;		# ini
    foreach $it (1..$nhtm){
	if ($res_sorted{"MODEL_DAT","max",$it}<$par{"htm_weak"}){
	    push(@weak,$it);}
	else {
	    push(@strg,$it);}}
    if ($Lscreen) {
	printf "--- pred_htmtop_top:  weak (<  %4.2f)=",$max_loc;&myprt_array(",",@weak);
	printf "--- pred_htmtop_top:  strg (>= %4.2f)=",$max_loc;&myprt_array(",",@strg);}
				# $npossible=&func_n_over_k_sum($#weak);

				# get permutations
    @weak_permut=
	&func_permut_mod($#weak);
    @permut=			# note: global @weak,@strg
	&comp_mix_permut_arrays(@weak_permut);

				# --------------------------------------------------
				# get model with maximal charge difference
				# --------------------------------------------------
    $max_all=$max_sep=0;
    foreach $it(1..$#permut){
				# now convert begin/end
	$permut[$it]=~s/^,|,$//g;
	$#tmp=0; @tmp=split(/,/,$permut[$it]);
	$#htm=0;
	foreach $ithtm(@tmp){	# get segments
	    push(@htm,$res_sorted{"MODEL_DAT","range",$ithtm});}
	@all_seg=			# helices -> loop + helices
	    &conv_htm2all(length($res{"$des_prd[1]"}),@htm);
	@loop=			# all -> loop
	    &conv_all2loop(@all_seg);
#	print "x.x $it: nall=$#all_seg, Nhtm=$#htm, Nloop=$#loop,\n";
	$#beg=$#end=0;		# get begin and end of loops
	foreach $range(@loop){($beg,$end)=split(/-/,$range);
			      push(@beg,$beg);push(@end,$end);}
				# compute charge difference
	($top_diff_all,$top_diff_sep)=
	    &comp_charge_diff;
	&get_max_charge;	# assign max values (all variables global)
#	print "x.x all:it=$it, diff=$top_diff_all, even=$eveC ($eveN), odd=$oddC ($oddN)\n";
#	print "x.x sep:        diff=$top_diff_sep\n";
    }
				# ----------------------------------------
				# save results of topology prediction
				# ----------------------------------------
				# final prediction of topology
				# all (i.e. summed charge)
    foreach $mode("all","sep"){
	&get_final($mode,$Lscreen_loc);
				# convert to 'final '
	foreach $des ("diff","pred","string","mod_top","nhtm"){
	    $res{"top_fin",$des,$mode}=$res{$des_prd,$des,$mode};}}

    if ($Lscreen) {
	printf 
	    "--- mode=%-5s,  \%(R+K)even=%5.1f (Nres=%5d), \%(R+K)odd=%5.1f (Nres=%5d)\n",
	    $des_prd,$max_eveC,$max_eveN,$max_oddC,$max_oddN;
	printf "--- pred all=%-5s, D(even-odd)=%8.3f, max_it=%4d\n",
	$res{"top_fin","pred","all"},$top_diff_all,$max_pos_all;
	printf "--- pred sep=%-5s, D(even-odd)=%8.3f, max_it=%4d\n",
	$res{"top_fin","pred","sep"},$top_diff_sep,$max_pos_sep;
	$tmp=$res{"AA"};$tmp=~s/[^KR]/ /g;
	&xprt_strings($res{"AA"},$tmp,$res{$des_prd},$res{$des_prd,"string","all"});}
}				# end of pred_htmtop_top

#==========================================================================================
sub profile_get {
    local ($string,@des_aa) = @_ ;
    local ($numres,$it,$aa);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   profile_get                 translates a sequence to a profile
#--------------------------------------------------------------------------------
    $numres=length($string);
    if ($numres<1) { print "*** empty string into profile_get ($scrName)\n";
		     exit;}
    foreach $it(1..$numres){	# all residues
	$aa=substr($string,$it,1);
	$profile{$aa,$it}=100;
	foreach $_ (@des_aa){
	    $profile{"$_",$it}=0 if ($_ ne $aa); }}
}				# end of profile_get

#==========================================================================================
sub profile_rd {
    local ($file_hssp,$id,$chain) = @_ ;
    local ($numres,$it,$aa,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   profile_rd                  reads the profiles from a HSSP file
#--------------------------------------------------------------------------------
    $fhin="RDHSSP";
    $idloc=$id;
    if ($chain eq "*") {$chain=" ";} 

    if (!-e $file_hssp){
	print "*** profile_rd ($scrName): no HSSP file $file_hssp\n";
	exit; }

    print 
	"--- profile_rd, compute topology for profile of '$file_hssp',",
	"id=$id,chain=$chain,\n" if ($Lscreen);
	
    &open_file("$fhin", "$file_hssp");
    while (<$fhin>) {
	if    ($_=~/^NALIGN/)   {$_=~s/^NALIGN\s+(\d+).*$/$1/g; $nalign_rd=$_;}
	elsif ($_=~/^THRESHOLD/){$_=~s/^THRESHOLD.*-0\.562\)\D+(\d*)\D*$/$1/g;
				 if (length($_)>0){$thresh_rd=$_;}else{$thresh_rd=0;}}
	last if ($_=~/^ SeqNo/);}
    $Lfst=1;$aa="";		# sequence
    while (<$fhin>) {
	if   ($_=~/^\#\# ALI/) { 
	    $Lfst=0;}
	elsif($_=~/^\#\# SEQUENCE PROFILE/) { 
	    last;}
	next if (! $Lfst) ;
	$ch_rd=substr($_,13,1);$aa_rd=substr($_,15,1);
	next if ( ($chain ne " ") && ($chain ne $ch_rd) );
	$aa.=$aa_rd;}

    $#des=$ct=0;		# profile
    while (<$fhin>) {
	last if ($_=~/^\#\#|^\//);
	if ($_=~/^ SeqNo/){ 
	    $_=substr($_,14);$_=~s/^\s*|\n|\s*$//g;
	    @des=split(/\s+/,$_);}
	else          {
	    $ch_rd=substr($_,12,1);
	    next if ( ($chain ne " ") && ($chain ne $ch_rd) );
	    ++$ct;$_=substr($_,14);$_=~s/^\s*|\n|\s*$//g;
	    $#tmp=0;@tmp=split(/\s+/,$_);
	    foreach $it (1 .. 20){
		$tmp[$it]=~s/\s//g;
		$profile{"$des[$it]","$ct"}=$tmp[$it];}}}
    close($fhin);
    return($file_hssp,$aa,$nalign_rd,$thresh_rd);
}				# end of profile_rd

#==========================================================================================
sub rd_top_obs {
    local ($file_obstop,$file_in) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_top_obs                 reads the file with all observed topologies
#--------------------------------------------------------------------------------
				# ------------------------------
				# read observed topology
    $id=$file_in;$id=~s/^.*\/(.*)\..*$/$1/g;
    $top_obs="unk";
    if (-e $file_obstop){
	print "--- read observed topology '$file_obstop'\n" if ($Lscreen);
	&open_file("$fhin", $file_obstop);
	while (<$fhin>) {
	    $_=~s/^\s*(.*)\s*\n/$1/g;
	    next if (length($_)==0);
	    $#tmp=0;@tmp=split(/\s+/,$_);
	    if ( $#tmp>1 && $id=~/$tmp[1]/){
		$top_obs=$tmp[2];
		last;}}
	close($fhin); }
    elsif ($Lscreen) { 
	print "--- no observed topology file '$file_obstop'\n";}
    $top_obs=~tr/[A-Z]/[a-z]/;
    return($top_obs);
}				# end of rd_top_obs

#==========================================================================
sub wrt_rdb_htmtop {
    local ($fhout,$file_in,$sep_in) = @_ ;
    local (@des,@tmp,$id,$des,$tmp,$fhin,$top_obs);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   writes the RDB format written by PHD
#--------------------------------------------------------------------------------
    $fhin="FHIN_WRT";
				# read observed topology
    $top_obs="unk";
    $top_obs=&rd_top_obs($par{"file_obstop"},$file_in) if (-e $par{"file_obstop"});

    if ($Lscreen) { 
	if ($top_obs eq "unk"){
	    print "*** no observed  topology: '$top_obs'\n";}
	else {
	    print "--- observed  topology '$top_obs'\n";}
	if ($par{"mode"} eq "top"){
	    print "--- predicted top (all) '",$res{"top_fin","pred","all"},"'\n";
	    print "--- predicted top (sep) '",$res{"top_fin","pred","sep"},"'\n"; }
	else {
	    foreach $des_prd("top_fin",@des_prd){
		next if (! defined $res{$des_prd,"pred"});
		print "--- predicted topology '",$res{$des_prd,"pred"},"' ($des_prd)\n";}}}
				# --------------------------------------------------
				# read and write files (append to old)
				# --------------------------------------------------
    &open_file("$fhin", "$file_in");
    $ct=0;$Lfst_notation=1;	# ------------------------------
    while (<$fhin>) {		# header
	++$ct;$rd=$_;
	last if (!/^\#/);
	$Lok=1;
	if ( ($ct<5) && (/^\#\s*PHD/) ) {
	    $Lok=0;		# change header
	    print $fhout 
		"\# PHDhtm_top: prediction of topology ",
		"for helical transmembrane proteins\n"; }
	elsif ( (/\# NOTATION/) && ($Lfst_notation) ) {
	    $Lfst_notation=0;
				# add results before Notations
	    printf $fhout "# HTMTOP_OBS    : %4s       (first loop region)\n",$top_obs; 
	    if ($par{"mode"} eq "top"){
		foreach $mode("all","sep"){
		    if ($mode eq "all"){
			$txt1="HTMTOP_PRD_A";$txt2="HTMTOP_NHTM_A";
			$txt3="HTMTOP_RID_A";$txt4="HTMTOP_RIP_A";}
		    else               {
			$txt1="HTMTOP_PRD_S";$txt2="HTMTOP_NHTM_S";
			$txt3="HTMTOP_RID_S";$txt4="HTMTOP_RIP_S";}
		    printf $fhout 
			"# %-13s : %4s       (first loop region)\n",
			$txt1,$res{"top_fin","pred",$mode};
		    printf $fhout
			"# %-13s : %6d       (model with maximal charge difference)\n",
			$txt2,$res{"top_fin","nhtm",$mode}; 
		    printf $fhout
			"# %-13s :%7.3f     (difference num(K+R), even-odd)\n",
			$txt3,$res{"top_fin","diff",$mode};
		    $tmp=sqrt($res{"top_fin","diff",$mode}*$res{"top_fin","diff",$mode});
		    $rip=int($tmp) ; $rip=9 if ($tmp>=10);
		    printf $fhout
			"# %-13s :%7.3f     (difference num(K+R), even-odd)\n",$txt4,$rip;}}
	    else {
		foreach $des_prd("top_fin",@des_prd){
		    if ($des_prd eq "top_fin"){$txt="HTMTOP_PRD"; }
		    else                      {$txt="HTMTOP_MODPRD"; }
		    $tmp=$res{$des_prd,"pred"}    if (defined $res{$des_prd,"pred"});
		    $tmp="unk"                      if (! defined $res{$des_prd,"pred"});
		    printf $fhout 
			"# %-13s : %4s       (first loop region, mode=%-s)\n",
			$txt,$tmp,$des_prd;}
                $res{"top_fin","diff"}=0
		    if (!defined $res{"top_fin","diff"} || $res{"top_fin","diff"} !~/\d/ ||
			length($res{"top_fin","diff"})<1);
		printf $fhout 
		    "# HTMTOP_RID    :%7.3f     (difference num(K+R), even-odd)\n",$res{"top_fin","diff"}; 
		$tmp=sqrt($res{"top_fin","diff"}*$res{"top_fin","diff"});
		$rip=int($tmp); $rip=9 if ($tmp>=10);
		printf $fhout 
		    "# HTMTOP_RIP    :%7d     (reliability index =int(min{9,2*sqrt((DC)^2)}) )\n",$rip;}
	    if (defined $id) {	# print NALIGN asf
		printf $fhout "# \n# HSSP_NALIGN   :  %5d\n",$res{"$id","nalign"} if (defined $res{"$id","nalign"});
		printf $fhout     "# HSSP_THRESH   :  %5d\n",(25+$res{"$id","thresh"})
		    if (defined $res{"$id","thresh"});}
	    print $fhout "# \n";}
	if ($Lok) {
	    if ( (! $Lfst_notation) && (length($_)<4) ) { # add notations
		print $fhout 
		    "# NOTATION PTHLA: predicted model for maximal charge difference (all)\n";
		print $fhout 
		    "# NOTATION PTHLS: predicted model for maximal charge difference (sep)\n";
		print $fhout 
		    "# NOTATION PiTo : predicted topology of transmembrane regions\n";
		print $fhout 
		    "# NOTATION PiTo :    i=loop inside, T=transmembrane, o=loop outside\n";
	    } 
				# correct (hacks)
	    $_=~s/\# NOTATION PHL  : H=helical/\# NOTATION PHL  :    H=helical/;
	    $_=~s/(\# LENGTH        :   )\s*(\d)/$1 $2/;
	    $_=~s/(\# NHTM.*) \(/$1     \(/;
	    $_=~s/(\# REL_BEST\S*\s+: )\s*([\d.]+)\s+\(([^\)]+)\).*/$1 $2     \($3\)/;
	    $_=~s/(\# REL_BEST_DPROJ\s*: )\s*([\d]+)\s+\(([^\)]+)\).*/$1     $2     \($3\)/;
	    print $fhout "$_"; }}
				# ------------------------------
    $rd=~s/\n//;		# names
    print $fhout "$rd$sep_in";
    if ($par{"mode"} eq "top"){
	print $fhout "PTHLA$sep_in","PTHLS$sep_in";}
    print $fhout "PiTo\n";
				# ------------------------------
    while (<$fhin>) {		# formats
	$rd=$_;$rd=~s/\n//;
				# '1' -> '1S'
	$tmp="S";$rd=~s/(\d)([\t\n])/$1$tmp$2/g;$rd=~s/(\d)$/$1$tmp/g;
	print $fhout "$rd$sep_in";
	if ($par{"mode"} eq "top"){
	    print $fhout "1S","$sep_in","1S","$sep_in";}
	print $fhout "1S\n";
	last;}
    if (defined $res{"top_fin","string"}){$tmp=$res{"top_fin","string"}; }
    else                                 {$tmp=$res{"top_fin","string","all"}; }

#    $tmp=~s/T/H/g;		# replace "T" -> "H"
    $tmp=~s/ /i/g;		# replace " " -> "i"
    $#top_fin=0;@top_fin=split(//,$tmp);
    if ($par{"mode"} eq "top"){
	$tmp=$res{"top_fin","mod_top","all"};$#prd_topa=0;@prd_topa=split(//,$tmp);
	$tmp=$res{"top_fin","mod_top","sep"};$#prd_tops=0;@prd_tops=split(//,$tmp);}
    $ct=0;			# ------------------------------
    while (<$fhin>) {		# rest
	$rd=$_;$rd=~s/\n//;++$ct;
	print  $fhout "$rd","$sep_in";
	printf $fhout "%1s$sep_in%1s$sep_in",$prd_topa[$ct],$prd_tops[$ct] if ($par{"mode"} eq "top");
	if (defined $top_fin[$ct]){
	    printf $fhout "%1s\n",$top_fin[$ct]; }
	else {printf $fhout "%1s\n","?"; }}
}				# end wrt_rdb_htmtop

#==========================================================================================
sub wrt_statistics {
    local ($fh,$sep) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_statistics             writes the statistics for all observed residues
#--------------------------------------------------------------------------------
				# read observed topology
    $id=$file_in;$id=~s/^.*\/(.*)\..*$/$1/g;
    $id=~s/_ref.*$|_fil.*$|_nof.*$//g;
    $top_obs=
	&rd_top_obs($par{"file_obstop"},$file_in);
    $id=~s/_ref.*$|_fil.*$|_nof.*$//g;

    foreach $desx("odd","even"){
	if ($stat{$desx,"nres"}>0) {
	    $perc{$desx,"npos"}=
		100*($stat{$desx,"R"}+$stat{$desx,"K"})/$stat{$desx,"nres"};}
	else {$perc{$desx,"npos"}=0;}
	foreach $aa (@des_20aa){
	    $perc{$desx,$aa}=100*($stat{$desx,$aa}/$stat{$desx,"nres"});}}
				# print
    if ($top_obs eq $top_pred) {$tmp=100;}else{$tmp=0;}
    printf $fh "%-15s$sep%3s$sep%3s$sep%3d$sep%6.2f$sep",$id,$top_obs,$top_pred,$tmp,$top_diff;
    foreach $desx("odd","even"){
	printf $fh 
	    "%3d$sep%3d$sep",$perc{$desx,"npos"},
	    int($stat{$desx,"R"}+$stat{$desx,"K"});}
    foreach $desx("odd","even"){
	$tmp{$desx,"pos"}=0;foreach $aa(@aa_pos){$tmp{$desx,"pos"}+=$stat{$desx,$aa};}
	$tmp{$desx,"neg"}=0;foreach $aa(@aa_neg){$tmp{$desx,"neg"}+=$stat{$desx,$aa};}
	$tmp{$desx,"hyd"}=0;foreach $aa(@aa_hyd){$tmp{$desx,"hyd"}+=$stat{$desx,$aa};}
	$tmp{$desx,"pol"}=0;foreach $aa(@aa_pol){$tmp{$desx,"pol"}+=$stat{$desx,$aa};}
	$tmp{$desx,"bdg"}=0;foreach $aa(@aa_bdg){$tmp{$desx,"bdg"}+=$stat{$desx,$aa};}
	foreach $des2("P","F","M","C","G"){
	    $tmp{$desx,"$des2"}=$stat{$desx,"$des2"};}
	$tmp{$desx,"KR"}=0; foreach $aa(@aa_pos){$tmp{$desx,"KR"}+=$stat{$desx,$aa};}}
    foreach $aa ("pos","neg","hyd","pol","bdg","P","F","M","C","G"){
	$tmp_sum=$tmp{"even",$aa}+$tmp{"odd",$aa};
	$tmp_dif=$tmp{"even",$aa}-$tmp{"odd",$aa};
	if ($tmp_sum>0){
	    $perc{"sum",$aa}=100*($tmp{"even",$aa}/$tmp_sum);}
	else{
	    $perc{"sum",$aa}=0;}
	$perc{"dif",$aa}=$tmp_dif;
	printf $fh "%8d$sep%8d$sep",
	int($perc{"sum",$aa}),$perc{"dif",$aa};}
    print $fh "\n";
				# compile sums
    foreach $desx("odd","even"){
	foreach $aa (@des_20aa,"npos"){
	    $stat_ave{$desx,$aa}+=$perc{$desx,$aa};}}
    $tmp=sqrt($top_diff*$top_diff);
    if(defined $stat_ave{"top_diff"}){
	$stat_ave{"top_diff"}+=$tmp;}
    else{
	$stat_ave{"top_diff"}=$tmp;}
    if ($top_obs eq $top_pred){
	if (defined $stat_ave{"top_corr"}){
	    ++$stat_ave{"top_corr"};}
	else{
	    $stat_ave{"top_corr"}=1;}}
    foreach $aa ("pos","neg","hyd","pol","bdg","P","F","M","C","G"){
	foreach $des("dif","sum"){
	    if (defined $stat_ave{$des,$aa}){
		$stat_ave{$des,$aa}+=$perc{$des,$aa};}
	    else {
		$stat_ave{$des,$aa}=$perc{$des,$aa};}}}
}				# end of wrt_statistics

#==========================================================================================
sub wrt_statistics_ave {
    local ($fh,$sep,$nprot) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
				# print
    printf $fh 
	"%-15s$sep%3s$sep%3d$sep%6.2f$sep","ave"," ",
	int(100*($stat_ave{"top_corr"}/$nprot)),($stat_ave{"top_diff"}/$nprot);
    foreach $desx("odd","even"){
	printf $fh "%3d$sep%5d$sep",int($stat_ave{$desx,"npos"}/$nprot),0;}
    foreach $aa ("pos","neg","hyd","pol","bdg","P","F","M","C","G"){
	foreach $des("dif","sum"){
	    printf $fh "%8d$sep",int($stat_ave{$des,$aa}/$nprot);}}
    print $fh "\n";
}				# end of wrt_statistics_ave

#==========================================================================================
sub wrt_statistics_header {
    local ($fh,$sep) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
    print  $fh 
	"# KR\t positive\n","# DE\t negative\n","# AVIL\t hydrophob\n","# STNQY\t polar\n",
	"# HW\t polar \n","# F,P,M,C,C,G\t separate\n";
    printf $fh "%-15s$sep%3s$sep%3s$sep%3s$sep%6s$sep","id","obs","prd","Tok","ev-od";
    foreach $desx("o","e"){
	printf $fh "%3s$sep%3s$sep","\%$desx","N$desx";}
    foreach $aa ("pos","neg","hyd","pol","bdg","P","F","M","C","G"){
	foreach $desx("e-o","e/o+e"){printf $fh "%8s$sep","$aa:$desx";}}
    print $fh "\n";
}				# end of wrt_statistics_header

#==========================================================================================
sub xprt_strings {
    local (@vec) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
    for($it=1;$it<=length($vec[1]);$it+=60){
	$tmp0=&myprt_npoints(60,$it);
	printf "%3s  %s\n"," ",$tmp0;
	foreach $_(@vec){
	    $tmp=substr($_,$it,60);
	    printf "%3s |%s|\n"," ",$tmp;}}
}				# end of xprt_strings


1;
