#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#

package phd_htmfil;

#===============================================================================
sub phd_htmfil {
#-------------------------------------------------------------------------------
#   phd_htmfil                   package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0



    @ARGV=@_;			# pass from calling



    $script_name      = "htmfil_phd";
    $script_goal      = "filter the transmembrane regions for PHD file";
    $script_input     = ".pred file from PHD";
    $script_opt_ar[1] = "output file";

				# include libraries
    $USERID=`whoami`; $USERID=~s/\s//g;
#     if ($USERID eq "phd"){
# 	require "/home/phd/ut/perl/lib-br.pl";
# 	require "/home/phd/ut/perl/lib-ut.pl";}
#     else { 
# 	$dir=0;
# 	foreach $arg(@ARGV){
# 	    if ($arg=~/dirLib=(.*)$/){$dir=$1;
# 				      last;}}
# 	if (! defined $dir || ! $dir || ! -d $dir) {
# 	    $dir=$dir || "/home/rost/pub/phd/scr/" || "/home/rost/perl/" || $ENV{'PERLLIB'} ||
# 		$ENV{'PWD'} || `pwd`; }
# 	if (! defined $dir || ! $dir || ! -d $dir) {
# 	    $tmp=$0; $tmp=~s/^\.\///g; $tmp=~s/^(.*\/)(.*)$/$1/; $tmp=~s/^scr\/?//g;
# 	    $dir=$tmp."scr/";  $dir=~s/\/$//g; }
# 	if (! defined $dir || ! $dir || ! -d $dir) {
# 	    $dir=""; }
# 	else { $dir.="/"     if ($dir !~/\/$/); }
# 	foreach $lib ("lib-br.pl","lib-ut.pl"){
# 	    require $dir.$lib ||
# 		die ("*** $scrName failed requiring perl libs \n".
# 		     "*** give as command line argument 'dirLib=DIRECTORY_WHERE_YOU_FIND:lib-ut.pl'"); }}



#------------------------------
# number of arguments ok?
#------------------------------
    if ($#ARGV < 1) {
	die "*** ERROR: \n*** usage: \t $script_name $script_input \n";
	print "number of arguments:  \t$ARGV \n";
    }

#----------------------------------------
# about script
#----------------------------------------
    if ($#ARGV>3) {$Lscreen=$ARGV[4];}else{$Lscreen=1;}
    if (! defined $Lscreen || ! $Lscreen) {
	foreach $arg (@ARGV) {
	    if ($arg=~ /^de?bu?g$/ || $arg=~/^verb(ose|2)?$/) { 
		$Lscreen=1;
		last; } }}
    if ($Lscreen) {
	&myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
	&myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
	for ($it=1; $it<=$#script_opt_ar; ++$it) {
	    print"--- opt $it: \t $script_opt_ar[$it] \n"; 
	} &myprt_empty; }
    if ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { exit; }

#----------------------------------------
# read input
#----------------------------------------
    $file_in= $ARGV[1]; 	
    $fhin="FHIN";

    $opt_passed = "";
    for ( $it=1; $it <= $#ARGV; ++$it ) { 
	next if ($ARGV[$it]=~/dirLib/);
	$opt_passed .= " " . "$ARGV[$it]"; }
    if ($Lscreen) { &myprt_empty;&myprt_txt("file in: \t \t $file_in"); 
		    &myprt_txt("options passed:"); 
		    &myprt_txt("      \t \t$opt_passed"); &myprt_empty; }

#------------------------------
# defaults
#------------------------------
    if ($#ARGV > 1) { $file_out=$ARGV[2];$file_out=~s/\n|\s//g; }
    else            { $file_out=$file_in."fil"; }
    $id=$file_in;$id=~s/\s|\n|\.pred.*//g;$id=~s/_tmnof//g;
    if ($#ARGV > 2) { $file_flag_not_membrane=$ARGV[3];$file_flag_not_membrane=~s/\n|\s//g; }
    else            { $file_flag_not_membrane="$id".".not_membrane";}
    $fhout="FHOUT";

#------------------------------------------------------------------------------------------
# parameters for filtering
# ........................
#
# cutshort=n           cut anything < n
# cutshort_single=n    cut if only one segment in protein < n
# cutrel_single=ri     elongate putative-to-be-cut single segments if RI>ri
# cutrelav_single      if > then short segments will be elongated
#
# splitlong=n          split all segments > 1.5*n into m = int(length/n) ones of length length/m
#                      position chosen according to minimal RI or simply equidistant
# splitrel=ri          means that more than one residue in the middle of a to be splitted segment
#                      is flipped if RI>ri
# splitmaxflip=n       2*n+1 = number of residues flipped maximally if RI<splitrel and 
#                      length>splitlong
# splitlong_low        same as before (splitlong), but now the number is smaller to cover
#                      segments which have a low reliability (which are purely splitted even if
#                      shorter)
# splitlong_lowrel     reliability index to decide that splitting (splitlong_low),
#                      if <= ri
# 
# shorten_len=n        means segments > than splitlong or splitlong_low are not split
#                      but shortened by up to n residues at both ends if reliability
#                      index is lower than:
# shorten_rel=ri       s.a. (shorten if < ri)
#                      
#                      
#------------------------------------------------------------------------------------------

    $cutshort=         11; 
    $cutshort_single=  17;  $cutrel_single=   5; $cutrelav_single=5;
    $splitlong=        25;  $splitrel=        6; 
    $splitmaxflip=      2;
    $splitlong2=       38;
				# commented out 27-2-97 (not needed?)
#$splitlong_low=    15; $splitlong_lowrel= 3;
    $shorten_len=       8; $shorten_rel=      4;
    
    $LNOT_MEMBRANE=0;

#------------------------------
# check existence of file
#------------------------------
    if (! -e $file_in) { &myprt_txt("ERROR:\t file $file_in does not exist"); 
			 exit; }

    print "--- phd_htmfil after ini phase\n";

#----------------------------------------
# read file
#----------------------------------------
				# check: is it RDB or PHD.pred?
    &open_file($fhin, "$file_in"); $LIS_RDB=0;
    &is_rdb($fhin); if ($LIS_RDB) {$Lis_rdb=1;}else{$Lis_rdb=0;}
    close($fhin);
    if ($Lscreen) {
	if ($Lis_rdb) { print "--- file is found to be RDB format (htmfil_phd)\n"; }
	else          { print "--- file is found to be phd dotpred format (htmfil_phd)\n"; } }
    if ($Lis_rdb) { 
	&rd_rdb_phdhtm($file_in);}
    else          { 
	print "*** ERROR in phd_htmfil reading of dotpred_phd not supported anymore\n" x 10; 
	die(1);
	&open_file($fhin, "$file_in");
	&read_dotpred_phd($fhin); 
	close($fhin);
    }

#----------------------------------------
# now filter protein
#----------------------------------------
    ($LNOT_MEMBRANE,$FIL,$RELFIL)=
	&filter_oneprotein($cutshort,$cutshort_single,$cutrel_single,$cutrelav_single,
			   $splitlong,$splitlong2,$splitrel,$splitmaxflip,
			   $shorten_len,$shorten_rel,$PRD,$REL);
				# version before: 27-2-97
#    &filter_oneprotein($cutshort,$cutshort_single,$cutrel_single,$cutrelav_single,
#                       $splitlong,$splitlong2,$splitrel,$splitmaxflip,
#                       $splitlong_low,$splitlong_lowrel,
#                       $shorten_len,$shorten_rel,$PRD,$REL);

    if (0){				# x.x
	for($it=1;$it<=length($SEC);$it+=80){
	    $tmp=&myprt_npoints(80,$it);
	    $SEC=~s/L/ /g;$PRD=~s/L/ /g;$FIL=~s/L/ /g;
	    printf "        %-s\n",$tmp;
	    printf "x.x obs=%-s\n",substr($SEC,$it,80);
	    printf "x.x prd=%-s\n",substr($PRD,$it,80);
	    printf "x.x fil=%-s\n",substr($FIL,$it,80);
	    printf "x.x ri =%-s\n",substr($REL,$it,80);
	}
	exit;				# x.x
    }

#--------------------------------------------
# write flag file = is not a membrane protein
#--------------------------------------------
				# initialise assosiative keys
    &conv_vec2ass_ini;
    &conv_vec2ass;

    if (0){
	if ($LNOT_MEMBRANE) {
	    &open_file($fhout, ">$file_flag_not_membrane");
	    print $fhout "claimed to be not a membrane protein\n";
	    close($fhout);
	}
    }

#----------------------------------------
# now write filtered version
#----------------------------------------
    &open_file($fhout, ">$file_out");

    if ($Lis_rdb) { 
	if ($Lscreen) { &writerdb_pred_phd("STDOUT"); }
	&writerdb_pred_phd($fhout); }
    close($fhout);
    
    if ($Lscreen) {&myprt_txt("htmfil_phd filter output in file: \t '$file_out'"); &myprt_empty; }
    return(1,"ok");
}				# end of phd_htmfil


#==============================================================================
# library collected (begin)
#==============================================================================

#==============================================================================
sub is_rdb {
    local ($fh_in) = @_ ;
#--------------------------------------------------------------------------------
#   is_rdb                      checks whether or not file is in RDB format
#       in:                     filehandle
#       out (GLOBAL):           $LIS_RDB
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    while ( <$fh_in> ) {
	if (/^\# Perl-RDB/) {$LIS_RDB=1;}else{$LIS_RDB=0;}
	last;
    }
    return $LIS_RDB ;
}				# end of is_rdb

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
	    $rdrdb{"$des_in","$it"}=$tmp[$it];}
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

#==============================================================================
sub filter1_change {
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_change              ??? (somehow to do with filter_oneprotein)
#--------------------------------------------------------------------------------
    $Lchanged=0;  
    if    ($Ntmp < $Ncap){ 
	$Lchanged=1;
	foreach $_( $Ntmp .. ($Ncap-1)){
	    $Lflip[$_]=1; } }
    elsif ($Ntmp > $Ncap){ 
	$Lchanged=1;
	foreach $_( $Ncap .. ($Ntmp-1) ){
	    $Lflip[$_]=1; } }
    if    ($Ctmp < $Ccap){ 
	$Lchanged=1;
	foreach $_( ($Ctmp+1) .. $Ccap ){
	    $Lflip[$_]=1; } }
    elsif ($Ctmp > $Ccap){ 
	$Lchanged=1;
	foreach $_( ($Ccap+1) .. $Ctmp){
	    $Lflip[$_]=1; } }
    if ($Lchanged)     {	# if changed update counters
	$Ncap=$Ntmp;
	$Ccap=$Ctmp;}
    return($Lchanged);
}				# end of filter1_change

#==============================================================================
sub filter1_rel_lengthen {
    local ($rel,$cut,$Ncap,$Ccap,$nmax) = @_ ; local ($num,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_rel_lengthen        checks in N- and C-term, whether rel > cut
#--------------------------------------------------------------------------------
    $ct=$Ncap-1;		# Ncap
    $num=0;
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ncap=$ct; 
	last if ($num==$nmax);	# not more than nmax changes
	--$ct;}
    $num=0;
    $ct=$Ccap+1;	# Ccap
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ccap=$ct; 
	last if ($num==$nmax);	# not more than nmax changes
	++$ct;}
    return($Ncap,$Ccap);
}				# end of filter1_rel_lengthen

#==============================================================================
sub filter1_rel_shorten {
    local ($rel,$cut,$Ncap,$Ccap,$nmax) = @_ ; local ($num,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_rel_shorten         checks in N- and C-term, whether rel > cut
#--------------------------------------------------------------------------------
    $ct=$Ncap;			# Ncap
    $num=0;
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ncap=($ct+1); 
	last if ($num==$nmax);	# not more than nmax changes
	++$ct;}
    $num=0;
    $ct=$Ccap;			# Ccap
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ccap=($ct-1); 
	last if ($num==$nmax);	# not more than nmax changes
	--$ct;}
    return($Ncap,$Ccap);
}				# end of filter1_rel_shorten

#==============================================================================
sub filter_oneprotein {
    local ($cutshort,$cutshort_single,$cutrel_single,$cutrelav_single,
           $splitlong,$splitlong2,$splitrel,$splitmaxflip,$shorten_len,$shorten_rel,
	   $PRD,$REL)=@_;
				# called by phd_htmfil.pl only!
    local ($ct,$tmp,$it,$it2,$itsplit,@ptr,$Lsplit,$splitloc);
    $[=1;
#--------------------------------------------------------------------------------
#   filter_oneprotein           reads .pred files
#       in GLOBAL:              ($PRD, $REL)
#       out GLOBAL:             $LNOT_MEMBRANE, $FIL, $RELFIL,
#--------------------------------------------------------------------------------
				# --------------------------------------------------
    @symh=("H","T","M");	# extract segments
    foreach $symh (@symh){
	%seg=&get_secstr_segment_caps($PRD,$symh);
	if ($seg{"$symh","NROWS"}>=1) {$tmp=$symh;
				       last;}}
    $symh=$tmp;			# --------------------------------------------------
				# none found? 
    if ((defined $symh) && (defined $seg{"$symh","NROWS"})) {
	$nseg=$seg{"$symh","NROWS"};
	if ($nseg<1) {
	    return(1,$PRD,$REL);} }
    else {
	return(1,$PRD,$REL);}
    $nres=length($PRD);		# ini
    $#Lflip=0;foreach $it(1..$nres){$Lflip[$it]=0;}
				# --------------------------------------------------
				# first long helices with rel ="000" split!
    $prdnew=$PRD;
    foreach $ct (1..$nseg) {
	$len=$seg{"$symh","end","$ct"}-$seg{"$symh","beg","$ct"}+1;
	if ( $len > $splitlong2 ) {
	    foreach $it ($seg{"$symh","beg","$ct"} .. 
			 ($seg{"$symh","end","$ct"}-$splitlong) ) {
		if (substr($REL,$it,3) eq "000") {
		    foreach $it2 ($it .. ($it+2)) {
			$Lflip[$it2]=1;}
		    substr($prdnew,$it,3)="LLL";}}}}
    if ($prdnew ne $PRD) {	# redo
	%seg=&get_secstr_segment_caps($prdnew,$symh);}
    $nseg=$seg{"$symh","NROWS"};
				# --------------------------------------------------
				# delete all < 11 , store len
				# --------------------------------------------------
    $#ptr_ok=0;
    foreach $ct (1..$nseg) {
	$seg{"len","$ct"}=($seg{"$symh","end","$ct"}-$seg{"$symh","beg","$ct"}+1);
				# first shorten if < 17
	if (($nseg>1) && ($seg{"len","$ct"}<$cutshort_single)){
	    $Ncap=$seg{"$symh","beg","$ct"};
	    $Ccap=$seg{"$symh","end","$ct"};
	    ($Ntmp,$Ctmp)=
		&filter1_rel_shorten($REL,($shorten_rel-1),$Ncap,$Ccap,$shorten_len);
	    $len=$Ctmp-$Ntmp+1;
	    if ($len<$cutshort) {
		foreach $it2 ( $Ncap .. $Ccap ){
		    $Lflip[$it2]=1;}} 
	    else {
		push(@ptr_ok,$ct);}}
	elsif ($seg{"len","$ct"}>$cutshort){
	    push(@ptr_ok,$ct);}}
    if ($#ptr_ok<1){
	print "********* HTMfil: filter_one_protein: no region > $cutshort\n";
	return(1,$PRD,$REL);}
				# --------------------------------------------------
				# only one and < 17?
				# --------------------------------------------------
    if ($#ptr_ok == 1) {
	$pos=$ptr_ok[1];
	$len=$seg{"len","$pos"};
	if ($len<$cutshort_single){
	    $Ncap=$seg{"$symh","beg","$pos"};
	    $Ccap=$seg{"$symh","end","$pos"};
	    $ave=0;		# average reliability
	    foreach $it ( $Ncap .. $Ccap){$ave+=substr($REL,$it,1);}
	    $ave=$ave/$len;	# average reliability > thresh -> elongate
	    if ($ave>=$cutrelav_single) { # add no more than 2 = HARD coded
				# add to N and C-term
		($Ntmp,$Ctmp)=
		    &filter1_rel_lengthen($REL,$cutrel_single,$Ncap,$Ccap,2);
		$Lchange=
		    &filter1_change(); # all GLOBAL
#		    &filter1_change($pos); # all GLOBAL
		if ($Lchange){
		    $seg{"$symh","beg","$pos"}=$Ncap;
		    $seg{"$symh","end","$pos"}=$Ccap;}}
	    else {
		print "********* HTM: filter_one_protein: single region, too short ($len)\n";
		return(1,$PRD,$REL);} }}
				# --------------------------------------------------
				# too long segments: shorten, split, ..
				# --------------------------------------------------
    foreach $it (@ptr_ok){
	$len=$seg{"len","$it"};
	$Ncap=$seg{"$symh","beg","$it"};
	$Ccap=$seg{"$symh","end","$it"};
				# ----------------------------------------
				# is it too long ? -> first try to shorten
	if ( ($len > 2*$splitlong) || ($len >= $splitlong2) ) {
				# cut fro N and C-term
	    ($Ntmp,$Ctmp)=
		&filter1_rel_shorten($REL,$shorten_rel,$Ncap,$Ccap,$shorten_len);
	    $Lchange=
		&filter1_change(); # all GLOBAL
#		&filter1_change($it); # all GLOBAL
	    if ($Lchange) {
		$len=$Ccap-$Ncap+1;} 
	}
				# ----------------------------------------
                                # still too long ? -> now split 
	$Lsplit=0;
                                # direct
	if    ( $len > ($splitlong+$splitlong2) ) {
	    $Lsplit=1;$splitloc=$splitlong; }
                                # only two segments => different cut-off
	elsif ( $len > $splitlong2 ) {
	    $Lsplit=1;$splitloc=$len/2; }
				# ----------------------------------------
                                # do split the HAIR
	if ($Lsplit) {
	    $splitN=int($len/$splitloc);
				# correction 9.95: add if e.g. > 50+11, eg. 65->3 times
	    if ($len>($splitN*$splitloc)+$cutshort_single){++$splitN;} # 9.95
				# correction 9.95: one less eg. > 100 , 
				#                  now: =4 times, but 100< 3*25+36 -> 4->3
	    if ( ($splitN>3) && ($len<($splitN-2)*$splitlong+$splitlong2+17) ) {
		--$splitN;}
	    if ($splitN>1){
		$splitL=int($len/$splitN);
				# --------------------
                                # loop over all splits
				# --------------------
		foreach $itsplit (1..($splitN-1)) {
		    $pos=$Ncap+$itsplit*$splitL; 
		    $min=substr($REL,$pos,1);
                                # in area +/-3 around split lower REL?
		    foreach $it2 (($pos-3)..($pos+3)){
			if (substr($REL,$it2,1)<$min){$min=substr($REL,$it2,1);
						      $pos=$it2;}}	
                                # flip 1,2, or 3 residues?
		    foreach $it2 (($pos-$splitmaxflip)..($pos+$splitmaxflip)){
			if   ( ($it2==$pos-1)||($it2==$pos)||($it2==$pos+1)) { 
			    $Lflip[$it2]=1; }
			elsif(substr($REL,$it2,1)<$splitrel){
			    $Lflip[$it2]=1;}} 
		}}		# end loop over splits
	}
    }				# end of loop over all HTM's
				# ----------------------------------------
				# now join segments to filtered version
    $PRD=~s/ |E/L/g;
    $FIL="";
    foreach $it (1..$nres) {
	if (! $Lflip[$it]) { 
	    $FIL.=substr($PRD,$it,1);}
	else {
	    if (substr($PRD,$it,1) eq $symh){
		$FIL.="L";}
	    else {
		$FIL.=$symh;}}}
				# ----------------------------------------
				# correct reliability index
    $RELFIL="";
    for ($it=1;$it<=length($FIL);++$it) {
	if (substr($FIL,$it,1) ne substr($PRD,$it,1)) {$RELFIL.="0";}
	else {$RELFIL.=substr($REL,$it,1);} }

    return(0,$FIL,$RELFIL);
}                               # end of filter_oneprotein

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
	    if   ( ($aa[$it] ne "$des") && ($aa[$it-1] eq "$des") ){
		push(@end,($it-2)); }
	    elsif( ($aa[$it] eq "$des") && ($aa[$it-1] ne "$des") ){
		push(@beg,($it-1)); }  }
	if ($#end != $#beg) {	# consistency check!
	    print "*** get_secstr_segment_caps: des=$des, Nend=",$#end,", Nbeg=",$#beg,",\n";
	    exit;}
	foreach $it (1..$#end){	# store segment begins (Ncap) and ends (Ccap)
	    $segment{"$des","beg","$it"}=$beg[$it];
	    $segment{"$des","end","$it"}=$end[$it]; } 
	$segment{"$des","NROWS"}=$#beg;
    }
    return(%segment);
}				# end of get_secstr_segment_caps

#==========================================================================================
sub conv_vec2ass {
    local ($des);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    conv_vec2ass                       
#         converts the vectors SEQ,SEC,FIL,RELFIL,PRTM,PRNO,SUB into assosiative
#         array: %data
#         keys, names, and formats for that array in: @des, @des_name, @des_form
#--------------------------------------------------------------------------------
    foreach $des (@des) {
	if ($des eq "seq")      {$data{"$des"}=$SEQ;}
	elsif ($des eq "sec")   {$data{"$des"}=$SEC;} 
	elsif ($des eq "prd")   {$data{"$des"}=$PRD;}
	elsif ($des eq "fil")   {$data{"$des"}=$FIL;}
	elsif ($des eq "relfil"){$data{"$des"}=$RELFIL;}
	elsif ($des eq "prtm")  {$data{"$des"}=$PRTM;}
	elsif ($des eq "prno")  {$data{"$des"}=$PRNO;}
	elsif ($des eq "sub")   {if ((defined $SUB)&&(length($SUB)>1)) {$data{"$des"}=$SUB;}}
	else {print"*** htmfil_phd, conv_vec2ass: unknown des=$des,\n";}
    }
}				# end of conv_vec2ass

#==========================================================================================
sub conv_vec2ass_ini {
    local ($it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    conv_vec2ass_ini                       
#         converts the vectors SEQ,SEC,FIL,RELFIL,PRTM,PRNO,SUB into assosiative
#         array: %data
#         keys, names, and formats for that array in: @des, @des_name, @des_form
#--------------------------------------------------------------------------------
    @des=     ("seq","sec","prd","fil", "relfil","prtm","prno","sub");
    @des_name=("AA", "Obs","PHD","PHDF","Rel",   "prH-","prL-","SUB");
    for($it=1;$it<=$#des;++$it) {
	$data{"$des[$it]","name"}=$des_name[$it];
    }
}				# end of conv_vec2ass_ini


#==========================================================================
sub rd_rdb_phdhtm {
    local ($file_in) = @_ ;
    local ($fhin,
           $tmp,@def_col_name,$it,$ct,$name,$name_read);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   reads the RDB format written by PHD
#   GLOBAL output:      
#   - @HEADER           anything on top (inclusive number of proteins asf)
#   - @FOOTER           anything below prediction
#   - $SEQ, $SEC, $PRD, $REL, $PRTM, $PRNO, @PRTM_OUT, @PRNO_OUT
#--------------------------------------------------------------------------------
				# ------------------------------
				# initialise
				# ------------------------------
    $fhin="FHIN_RD_RDB_PHDHTM";
    @des_rd=("No","AA","OHL","PHL","RI_H","RI_S","pH","pL","OtH","OtL");
    $READHEADER="";
    &open_file($fhin, "$file_in"); # read header
    $ct=0;
    while(<$fhin>){if(/\#/){$READHEADER.="$_";}
                   else{
                       ++$ct;
                       if    ($ct==1){$READNAME=$_; $READNAME=~s/^[\s]*|[\t\n]*$//g;}
                       elsif ($ct==2){$READFORMAT=$_;$READFORMAT=~s/^[\s]*|[\t\n]*$//g;}
                       else {
                           last;}}}close($fhin);
    
    $#READNAME=$#READFORMAT=0;   # for old writing routine
    @rdname=split(/\t/,$READNAME);
    @rdform=split(/\t/,$READFORMAT);
    foreach $des (@des_rd){
        foreach $it (1..$#rdname){
            if ($rdname[$it] eq $des) { push(@READNAME,$des);push(@READFORMAT,$rdform[$it]);
                                        last;}}}
                                # end of for old writing
    %rd=&rd_rdb_associative($file_in,"not_screen","body",@des_rd);
				# change names (hack Mar 97)
    foreach $tmp (@READNAME){
	if ($tmp eq "RI_S"){ $tmp="RI_H";}}

    foreach $des (@des_rd){
        if    ($des=~/^AA|^OHL|^PHL|^RI_H|^RI_S/){
            $ct=1;$tmp="";
            while (defined $rd{"$des","$ct"}){
                $tmp.=$rd{"$des","$ct"};
				# hack mar 97
		if ($des=~/^RI_S/){
		    $rd{"RI_H","$ct"}=$rd{"$des","$ct"};} # update RI_S -> RI_H
                ++$ct;}
            if (length($tmp)>0){
                if   ($des eq "AA")   { $SEQ=$tmp; }
                elsif($des eq "OHL")  { $SEC=$tmp; }
                elsif($des eq "PHL")  { $PRD=$tmp; }
                elsif($des eq "RI_H") { $REL=$tmp; } 
                elsif($des eq "RI_S") { $REL=$tmp; } }}
        elsif ($des=~/^pH|^pL|^OtH|^OtL/){
            $ct=1;$#tmp=0;
            while (defined $rd{"$des","$ct"}){
                push(@tmp,$rd{"$des","$ct"}); 
                ++$ct;}
            if ($#tmp>0){
                if   ($des eq "pH")   { @PRTM=@tmp; }
                elsif($des eq "pL")   { @PRNO=@tmp; }
                elsif($des eq "OtH")  { @PRTM_OUT=@tmp; }
                elsif($des eq "OtL")  { @PRNO_OUT=@tmp; } } }
    }
}				# end read_rdbpred_phd

#==========================================================================
sub writerdb_pred_phd {
    local ($fhout) = @_ ;
    local ($tmp,@def_col_name,$it,$ct,$name,$name_read,@out);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   writes the RDB format written by PHD
#   GLOBAL input:      
#   - $READHEADER       header read from RDB file
#   - @READNAME         names read from RDB file
#   - @READFORMAT       formats read from RDB file
#   - $SEQ, $SEC, $FIL, $RELFIL, @PRTM, @PRNO, @PRTM_OUT, @PRNO_OUT
#--------------------------------------------------------------------------------
				# massage header
    $READHEADER=~s/^\#//g;
    @tmp=split(/\#/,$READHEADER);
    $#out=0;$Lchange=$L1st=1;

    foreach $tmp (@tmp) {
	$add="";
	$tmp=~s/^\#|\n//g;		# purge leading hashes and newline
	if    ($tmp=~/OHEL/) {
	    if ($L1st) { $tmp=~s/OHEL/OHL /;    $L1st=0; }
	    else       { $tmp=~s/OHEL :/     :/;} }
	elsif ($tmp=~/PH.?L/) {
	    $tmp=~s/PHEL/PHL /;
				# changed 22-8-95, otherwise trouble in phd.pl
	    $add=" NOTATION PFHL : filtered prediction of transmembrane helices";}
	if ($tmp=~/^.s*LENGTH/){$Lchange=0;} # hack aug 95
	push(@out,$tmp); 
	if (length($add)>1){
	    push(@out,$add);}	# hack 2 aug95
    }
    foreach $tmp(@out){
	if( ($tmp=~/NOTATION/) && $Lchange){ # hack aug95
	    printf $fhout "# %-15s %5d\n","LENGTH",length($FIL);$Lchange=0;} # end hack aug95
	print $fhout "#",$tmp,"\n";}
				# end of header
				# ------------------------------
				# correction hack 30-8-95
    foreach $it(1..$#READNAME){$READNAME[$it]=~s/\n|\s//g;$READFORMAT[$it]=~s/\n|\s//g; }
				# now write names
    for($it=1;$it<=$#READNAME;++$it) { print $fhout $READNAME[$it]; 
				       if ($it<$#READNAME) {print $fhout "\t";}
				       else {print $fhout "\n";}
				# add new column for non filter
				       if($READNAME[$it]eq"PHL"){print $fhout "PFHL\t";} }
				# now write formats
    for($it=1;$it<=$#READNAME;++$it) { print $fhout $READFORMAT[$it]; 
				       if ($it<$#READNAME) {print $fhout "\t";}
				       else {print $fhout "\n";} 
				       if($READNAME[$it]eq"PHL"){print $fhout "1\t";} }
				# ------------------------------
				# now the data
    for($it=1;$it<=length($SEQ);++$it) {
	if (substr($FIL,$it,1) eq " ") {$tmpfil="L";} else {$tmpfil=substr($FIL,$it,1);}
	if (substr($PRD,$it,1) eq " ") {$tmpprd="L";} else {$tmpprd=substr($PRD,$it,1);}
				# changed 22-8-95, otherwise trouble in phd.pl
	printf $fhout "%4d\t",$it;
	if((defined $SEQ)&&(length($SEQ)>0))      {printf $fhout "%1s\t",substr($SEQ,$it,1);}
	if((defined $SEC)&&(length($SEC)>0))      {printf $fhout "%1s\t",substr($SEC,$it,1);}
	if((defined $tmpprd)&&(length($tmpprd)>0)){printf $fhout "%1s\t",$tmpprd;}
	if((defined $tmpfil)&&(length($tmpfil)>0)){printf $fhout "%1s\t",$tmpfil;}
	if((defined $RELFIL)&&(length($RELFIL)>0)){printf $fhout "%1s\t",substr($RELFIL,$it,1);}
	if((defined $PRTM[$it])&&($#PRTM>0))      {printf $fhout "%1d\t",$PRTM[$it];}
	if((defined $PRNO[$it])&&($#PRNO>0))      {printf $fhout "%1d\t",$PRNO[$it];}
	if((defined $PRTM_OUT[$it])&&($#PRTM_OUT>0)){printf $fhout "%3d\t",$PRTM_OUT[$it];}
	if((defined $PRNO_OUT[$it])&&($#PRNO_OUT>0)){printf $fhout "%3d\n",$PRNO_OUT[$it];}
	else {print $fhout "\n";}
				# end of changed 22-8-95, otherwise trouble in phd.pl
    }
}				# end writerdb_pred_phd

1;

