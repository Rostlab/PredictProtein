#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="take phd.RDB file and write human readable (.phd)\n";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
@kwd=("dirOut","fileOut","title","desOut","header","detail","subset",
      "pre","nresPerRow");
$par{"header"}=       1;	# write information iin RDB header?
$par{"detail"}=       1;	# write line with detail ?
$par{"subset"}=       1;	# write line with subset ?
$par{"pre"}=         "";	# each row will begin with '$pre'
$par{"nresPerRow"}=  60;	# number of residues per row
$par{"verb2"}=        1;
$par{"riSubAcc"}=     4;
$par{"riSubHtm"}=     4;
$par{"riSubSec"}=     5;
$par{"optPhd"}=      "htm";	# 
$par{"optDoHtmref"}=1;		# xx
$par{"optDoHtmtop"}=1;		# xx
$file{"all3"."Phd"}="x.tmp";	# xx
$protname="xx";			# 


@kwdExpect=
    ("AA",
     "OHEL","PHEL",       "RI_S","pH","pE","pL",                  
     "OHEL","OREL","PREL","RI_A","Obie","Pbie",
     "OHL", "PHL",        "RI_H","pH","pL","PFHL","PRHL","PR2HL","PiTo",
     );
	    
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file(s).rdb'\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    foreach $kwd(@kwd){
	print "    \t $kwd= "; print "(default=",$par{"$kwd"},")" if (defined $par{"$kwd"});print "\n";
    }
    print "xx scr not finished!!!!!!!!!\n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];$#fileIn=0;push(@fileIn,$fileIn);
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    elsif (-e $arg && &isRdb($arg)){push(@fileIn,$arg);}
    else {$Lok=0;
	  foreach $kwd(@kwd){
	      if ($arg=~/^$kwd=(.+)$/){$Lok=1;
				       $par{"$kwd"}=$1;
				       last;}}
	  if (! $Lok){
	      print"*** wrong command line arg '$_'\n";
	      die;}}}

die ("missing input $fileIn\n") if (! -e $fileIn);

				# ------------------------------
				# (1) read file
foreach $fileIn(@fileIn){
    next if (! -e $fileIn);
    next if (! &isRdb($fileIn));




				# ------------------------------
				# convert RDB files
    %phd_fin=
	&rdbphd_to_dotpred($par{"verb2"},$par{"nresPerRow"},
			   $par{"riSubAcc"},$par{"riSubHtm"},$par{"riSubSec"},
			   $optPhd_loc,$file{"all3"."Phd"},$protname,
			   $par{"optDoHtmref"},$par{"optDoHtmtop"},$fileIn);
    print "xx scr not finished!!!!!!!!!\n";
    exit;			# xx

    %rdRdb= &rd_rdb_associative($fileIn,"head","body");
    print "xx header=\n";
    print $rdRdb{"header"},"\n";
    print "xx body=\n";
    @des=split(/,/,$rdRdb{"names"});
    foreach $kwd (@des){print "$kwd ";}print "\n";
    foreach $it (1..$rdRdb{"NROWS"}){
	foreach $kwd (@des){
	    print $rdRdb{"$kwd","$it"}," ";
	}
	print "\n";
    }
    exit;			# xx
    
}
exit;				# xx
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;
}
close($fhin);
				# ------------------------------
				# (2) 
				# ------------------------------
				# (2) 

				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
close($fhout);

print "--- output in $fileOut\n";
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digit     project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
				# SQRT
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

#==============================================================================
sub isRdb {
    local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    return (0) if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB";
    open("$fh", $fileInLoc) || return(0);
    $tmp=<$fh>;
    close($fh);
    return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
    return 0; 
}				# end of isRdb

#==============================================================================
sub is_rdb_acc {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lisacc);
#--------------------------------------------------------------------------------
#   is_rdb_acc                  checks whether or not file is in RDB format from PHDacc
#       in:                     $file
#       out:                    1 if is rdb_acc; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDACC";$Lisrdb=$Lisacc=0;
    &open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*acc/){$Lisacc=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lisacc);
}				# end of is_rdb_acc

#==============================================================================
sub is_rdb_htm {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htm                  checks whether or not file is in RDB format from PHDhtm
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$fileInLoc");
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { ++$ctLoc;
		      $Lisrdb=1       if (/^\# Perl-RDB/);
		      last if (! $Lisrdb);
		      $Lishtm=1       if (/^\#\s*PHD\s*htm\:/);
		      last if ($Lishtm);
		      last if ($_ !~/^\#/);
		      last if ($ctLoc > 5); }close($fh);
    return ($Lishtm);
}				# end of is_rdb_htm

#==============================================================================
sub is_rdb_htmref {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_PHDHTM_REF";$Lisrdb=$Lishtm=0;
    open($fh, $fileInLoc) || return(0); 
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { 
	++$ctLoc;
	$Lisrdb=1       if ($_=~/^\# Perl-RDB/);
	last if (! $Lisrdb);
	$Lishtm=1       if ($_=~/^\#\s*PHD\s*htm.*ref\:/);
	last if ($Lishtm);
	last if ($_ !~/^\#/);
	last if ($ctLoc > 5); }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmref

#==============================================================================
sub is_rdb_htmtop {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
	
    $fh="FHIN_CHECK_RDB_PHDHTM_TOP";$Lisrdb=$Lishtm=0;
    open($fh, $fileInLoc) || return(0); 
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { 
	++$ctLoc;
	$Lisrdb=1       if ($_=~/^\# Perl-RDB/);
	last if (! $Lisrdb);
	$Lishtm=1       if ($_=~/^\#\s*PHD\s*htm.*top\:/);
	last if ($Lishtm);
	last if ($_ !~/^\#/);
	last if ($ctLoc > 5); }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmtop

#==============================================================================
sub is_rdb_sec {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lissec);
#--------------------------------------------------------------------------------
#   is_rdb_sec                  checks whether or not file is RDB from PHDsec
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDSEC";$Lisrdb=$Lissec=0;
    &open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*sec/){$Lissec=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lissec);
}				# end of is_rdb_sec

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
    $npoints=10*(1+int($npoints/10))
	if ( int($npoints/10)!=($npoints/10) );

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
	    $rdrdb{"$des_in","$it"}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==============================================================================
sub rdbphd_to_dotpred {
    local($Lscreen,$nres_per_row,$thresh_acc,$thresh_htm,$thresh_sec,
	  $opt_phd,$file_out,$protname,$Ldo_htmref,$Ldo_htmtop,@file) = @_ ;
    local($fhin,@des,@des_rd,@des_sec,@des_rd_sec,@des_acc,@des_rd_acc,@des_htm,@des_rd_htm,
	  %rdb_rd,%rdb,$file,$it,$ct,$mode_wrt,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred           converts RDB files of PHDsec,acc,htm (both/3)
#                               to .pred files as used for PP server
#--------------------------------------------------------------------------------
    $fhin= "FHIN_RDBPHD_TO_DOTPRED";
    $fhout="FHOUT_RDBPHD_TO_DOTPRED";
				# note: @des same succession as @des_rd !!
    @des_rd_0 =     ("No", "AA");
    @des_0=         ("pos","aa");
    @des_rd_acc=    ("Obie","Pbie","OREL","PREL","RI_A");
    @des_acc=       ("obie","pbie","oacc","pacc","riacc");
				# horrible hack 20-01-98
    $fhinLoc="FHIN_rdbphd_to_dotpred";
    &open_file("$fhinLoc",$file[1]);
				# get RI for first file
    while(<$fhinLoc>){
	next if ($_=~/^\#/);
	if    ($_=~/RI\_S/){$riTmp="RI_S";}
	elsif ($_=~/RI\_H/){$riTmp="RI_H";}
	elsif ($_=~/RI\_A/){$riTmp="RI_A";}
	else  {print "*** '$_'\n";print "*** ERROR in RDB header $file[1]\n";}
	last;}close($fhinLoc);
	
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL", "PRHL", "PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","prhtm","pthtm");}
    elsif ($Ldo_htmref) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL", "PRHL");
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","prhtm");}
    elsif ($Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL" ,"PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","pthtm");}
    else {
	@des_rd_htm=("OHL", "PHL", "$riTmp", "pH",    "pL"    ,"PFHL" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm");}
    @des_rd_sec=    ("OHEL","PHEL","$riTmp", "pH",    "pE",    "pL");
    @des_sec=       ("osec","psec","risec",  "prHsec","prEsec","prLsec");
				# headers
    @deshd_rd_0=  ();
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
#		       "REL_BEST","REL_BEST_DIFF",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT",
		       "HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    elsif ($Ldo_htmref) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT");}
    elsif ($Ldo_htmtop) {
	@deshd_rd_htm=("HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    else {
	$#deshd_rd_htm=0;}
				# ------------------------------
				# read RDB files
				# ------------------------------
    $ct=0;
    foreach $file (@file){
	next if (! -e $file);
	++$ct;
	undef %rdb_rd;
	if ($ct==1) {
	    @des_rd=@des_rd_0;@des=@des_0;@deshd_rd=@deshd_rd_0;}
	else {
	    $#des_rd=$#des=$#deshd_rd=0;}
				# find out whether from PHDsec, PHDacc, or PHDhtm
	if   (&is_rdb_sec($file)){
	    $phd="sec";push(@des_rd,@des_rd_sec);push(@des,@des_sec);}
	elsif(&is_rdb_acc($file)){
	    $phd="acc";push(@des_rd,@des_rd_acc);push(@des,@des_acc);}
	elsif(&is_rdb_htmtop($file) || &is_rdb_htmref($file) || &is_rdb_htm($file)){
	    $phd="htm";push(@des,@des_htm);
	    push(@des_rd,@des_rd_htm);push(@deshd_rd,@deshd_rd_htm);}
	else {
	    print "*** ERROR rdbphd_to_dotpred: no RDB format recognised (file=$file)\n";
	    die; }
#	print "--- rdbphd_to_dotpred reading '$file' (phd=$phd)\n";
	%rdb_rd=
	    &rd_rdb_associative($file,"not_screen","header",@deshd_rd,"body",@des_rd); 
				# rename data (separate for PHDsec,acc,htm)
	foreach $it (1 .. $#des_rd) {
	    $ct=1;
	    while (defined $rdb_rd{"$des_rd[$it]","$ct"}) {
		$rdb{"$des[$it]","$ct"}=$rdb_rd{"$des_rd[$it]","$ct"}; 
		++$ct; }}
	foreach $deshdr (@deshd_rd){ # rename header
	    $rdb{"$deshdr"}="UNK";
	    $rdb{"$deshdr"}=$rdb_rd{"$deshdr"} if (defined $rdb_rd{"$deshdr"});}
    }
				# ------------------------------
				# now transform to strings
				# ------------------------------
    &rdbphd_to_dotpred_getstring(@des_0,@des_sec,@des_acc,@des_htm);
				# now subsets
    &rdbphd_to_dotpred_getsubset;
				# convert symbols
    $STRING{"osec"}=~s/L/ /g    if (defined $STRING{"osec"});
    $STRING{"psec"}=~s/L/ /g    if (defined $STRING{"psec"});
    $STRING{"obie"}=~s/i/ /g    if (defined $STRING{"obie"});
    $STRING{"pbie"}=~s/i/ /g    if (defined $STRING{"pbie"});
    if (defined $STRING{"ohtm"}) { 
	$STRING{"ohtm"}=~s/L/ /g;  
	if ($opt_phd !~ /htm/){
	    $STRING{"ohtm"}=~s/H/T/g;$STRING{"ohtm"}=~s/E/ /g; }}
    if (defined $STRING{"phtm"}) { 
	$STRING{"phtm"}=~s/L/ /g;  
	if ($opt_phd !~ /htm/){
	    $STRING{"phtm"}=~s/H/T/g;$STRING{"phtm"}=~s/E/ /g; }}
    if (defined $STRING{"pfhtm"}) { 
	$STRING{"pfhtm"}=~s/L/ /g; 
	if ($opt_phd !~ /htm/){
	    $STRING{"pfhtm"}=~s/H/T/g;$STRING{"pfhtm"}=~s/E/ /g; }}
    if (defined $STRING{"prhtm"}) { 
	$STRING{"prhtm"}=~s/L/ /g; 
	if ($opt_phd !~ /htm/){
	    $STRING{"prhtm"}=~s/H/T/g;$STRING{"prhtm"}=~s/E/ /g; }}

    @des_wrt=@des_0;
    $#htm_header=0;
    if    ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) && 
	    (length($STRING{"phtm"})>3) ) { 
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc",@des_htm,"subhtm"); 
	$mode_wrt="3";}
    elsif ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) ) {
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc"); 
	$mode_wrt="both"; }
    elsif ( length($STRING{"psec"})>3 ) { 
	push(@des_wrt,@des_sec,"subsec");                   
	$mode_wrt="sec"; }
    elsif ( length($STRING{"pacc"})>3 ) { 
	push(@des_wrt,@des_acc,"subacc");                   
	$mode_wrt="acc"; }
    elsif ( length($STRING{"phtm"})>3 ) { 
	push(@des_wrt,"ohtm","phtm","rihtm","prHhtm","prLhtm","subhtm","pfhtm");
	push(@des_wrt,"prhtm")  if ($Ldo_htmref);
	push(@des_wrt,"pthtm")  if ($Ldo_htmtop);
	$mode_wrt="htm"; 
	@htm_header=
	    &rdbphd_to_dotpred_head_htmtop(@deshd_rd_htm)
		if ($Ldo_htmref || $Ldo_htmtop); }
    else {
	print "*** ERROR rdbphd_to_dotpred: no \%STRING defined recognised\n";
	exit; }

    if ($Lscreen) {
	print "--- rdbphd_to_dotpred read from conversion:\n";
	&wrt_phdpred_from_string("STDOUT",$nres_per_row,$mode_wrt,$Ldo_htmref,
				 @des_wrt,"header",@htm_header); }
    &open_file("$fhout",">$file_out");
    &wrt_phdpred_from_string($fhout,$nres_per_row,$mode_wrt,$Ldo_htmref,
			     @des_wrt,"header",@htm_header); 
    close($fhout);
				# --------------------------------------------------
				# now collect for final file
				# --------------------------------------------------
    foreach $des ("aa","osec","psec","risec","oacc","pacc","riacc",
		  "ohtm","phtm","pfhtm","rihtm","prhtm","pthtm") {
	if (defined $STRING{"$des"}) {
	    if   ($des eq "aa") { 
		$nres=length($STRING{"$des"}); }
	    elsif(($des=~/^p/)&&(length($STRING{"$des"})>$nres)){
		$nres=length($STRING{"$des"}); }
	    $phd_fin{"$protname","$des"}=$STRING{"$des"}; }}
    $phd_fin{"$protname","nres"}=$nres;
				# ------------------------------
				# save memory
    undef %STRING; undef %rdb_rd; undef %rdb;
    return(%phd_fin);
}				# end of rdbphd_to_dotpred

#==============================================================================
sub rdbphd_to_dotpred_getstring {
    local (@des) = @_ ;
    local ($des,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#       in::                     file
#       in / out GLOBAL:         %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des (@des) {
	$STRING{"$des"}="";$ct=1;
	if ($des !~ /oacc|pacc/ ){
	    while (defined $rdb{"$des","$ct"}) {
		$STRING{"$des"}.=$rdb{"$des","$ct"};
		++$ct; } }
	else {
	    while (defined $rdb{"$des","$ct"}) {
		$STRING{"$des"}.=&exposure_project_1digit($rdb{"$des","$ct"});
		++$ct; } } }
}				# end of rdbphd_to_dotpred_getstring

#==============================================================================
sub rdbphd_to_dotpred_getsubset {
    local ($des,$ct,$desout,$thresh,$kwdPhd,$desrel);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_getsubset assigns subsets:
#       in:                     file
#       in / out GLOBAL:        %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des ("sec","acc","htm"){
				# assign thresholds
	if    ($des eq "sec") { $thresh=$thresh_sec; }
	elsif ($des eq "acc") { $thresh=$thresh_acc; }
	elsif ($des eq "htm") { $thresh=$thresh_htm; }

	$desphd="p"."$des";
				# note: for PHDacc subset on three states (b,e,i)
	$desphd="p"."bie"       if ($des eq "acc");
				# ignore different modes, than existing
	next if (! defined $rdb{"$desphd","1"});
	$desout="sub"."$des";
	$desrel="ri"."$des";
	$STRING{"$desout"}="";$ct=1; # initialise

	while ( defined $rdb{"$desphd","$ct"}) {
	    if (defined $rdb{"$desrel","$ct"} && 
		$rdb{"$desrel","$ct"} >= $thresh) {
		$STRING{"$desout"}.=$rdb{"$desphd","$ct"}; }
	    else {
		$STRING{"$desout"}.=".";}
	    ++$ct; }
    }
}				# end of rdbphd_to_dotpred_getsubset

#==============================================================================
sub rdbphd_to_dotpred_head_htmtop {
    local (@des)= @_ ;  local ($des,$tmp,@tmp,@out);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_head_htmtop writes the header for htmtop
#--------------------------------------------------------------------------------
    $#out=0;
    foreach $des (@des){
	if (defined $rdb_rd{"$des"}){
	    $tmp=$rdb_rd{"$des"};$tmp=~s/^:*|:*$//g;
	    if ($tmp=~/\:/){
		$#tmp=0;@tmp=split(/:/,$tmp);} else {@tmp=("$tmp");}
	    if ($des !~/MODEL/){ # purge blanks and comments
		foreach $tmp (@tmp) {$tmp=~s/\(.*//g;$tmp=~s/\s//g;}}
	    foreach $tmp (@tmp) {
		push(@out,"$des:$tmp");}}}
    return(@out);
}				# end of rdbphd_to_dotpred_head_htmtop

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
sub wrt_phdpred_from_string {
    local ($fh,$nres_per_row,$mode,$Ldo_htmref,@des) = @_ ;
    local (@des_loc,@header_loc,$Lheader);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string     write body of PHD.pred files from global array %STRING{}
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    if (! %STRING) { 
	print "*** ERROR wrt_phdpred_from_string: associative array \%STRING must be global\n";
	exit; }
    $#des_loc=$#header_loc=0;$Lheader=0;
    foreach $des(@des){
	if ($des eq "header"){ 
	    $Lheader=1;
	    next;}
	if (! $Lheader){push(@des_loc,$des);}
	else           {push(@header_loc,$des);}}
				# get length of proteins (number of residues)
    $des= $des_loc[2];		# hopefully always AA!
    $tmp= $STRING{"$des"};
    $nres=length($tmp);
				# --------------------------------------------------
				# now write out for 'both','acc','sec'
				# --------------------------------------------------
    if ($mode=~/3|both|sec|acc/){
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	print  $fh " \n \n";	# print empty before each PHD block
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (! defined $STRING{"$_"});
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if (length($tmp)==0) ;
				# secondary structure
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/osec/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS sec",$tmp; }
	    elsif($_=~/psec/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD sec",$tmp; }
	    elsif($_=~/risec/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel sec",$tmp; }
	    elsif($_=~/prHsec/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH sec",$tmp; }
	    elsif($_=~/prEsec/){printf $fh "%8s %-7s |%-s|\n"," ","prE sec",$tmp; }
	    elsif($_=~/prLsec/){printf $fh "%8s %-7s |%-s|\n"," ","prL sec",$tmp; }
	    elsif($_=~/subsec/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB sec",$tmp;}
				# solvent accessibility
	    elsif($_=~/obie/)  {if($mode=~/both|3/){print $fh " accessibility: \n"; }
				printf $fh "%-8s %-7s |%-s|\n"," 3st:","O_3 acc",$tmp;}
	    elsif($_=~/pbie/)  {if (length($STRING{"obie"})>1){$txt=" ";} 
				else{if($mode=~/both|3/){print $fh " accessibility \n";}
				     $txt=" 3st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"P_3 acc",$tmp; }
	    elsif($_=~/oacc/)  {printf $fh "%-8s %-7s |%-s|\n"," 10st:","OBS acc",$tmp;}
	    elsif($_=~/pacc/)  {if (length($STRING{"oacc"})>1){$txt=" ";}else{$txt=" 10st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"PHD acc",$tmp; }
	    elsif($_=~/riacc/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel acc",$tmp; }
	    elsif($_=~/subacc/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB acc",$tmp; }
	}
    }
				# --------------------------------------------------
				# now write out for '3','htm'
				# --------------------------------------------------
    if ($mode=~/3|htm/){
	if ($mode=~/3/) {
	    $symh="T";
	    print $fh 
		" \n",
		"************************************************************\n",
		"*    PHDhtm Helical transmembrane prediction\n",
		"*           note: PHDacc and PHDsec are reliable for water-\n",
		"*                 soluble globular proteins, only.  Thus, \n",
		"*                 please take the  predictions above with \n",
		"*                 particular caution wherever transmembrane\n",
		"*                 helices are predicted by PHDhtm!\n",
		"************************************************************\n",
		" \n",
		" PHDhtm\n";
	} else {
	    $symh="H";}
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
				# ------------------------------
				# print header for topology asf
    if ($nres_tmp>0){
	if ($#header_loc>0){
	    &wrt_phdpred_from_string_htm_header($fh,@header_loc);}
	&wrt_phdpred_from_string_htm($fh,$nres_tmp,$nres_per_row,$symh,
				     $Ldo_htmref,@des_loc);}
}				# end of wrt_phdpred_from_string

#==============================================================================
sub wrt_phdpred_from_string_htm {
    local ($fh,$nres_tmp,$nres_per_row,$symh,$Ldo_htmref,@des_loc) = @_ ;
    local ($it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htm body of PHD.pred files from global array %STRING{} for HTM
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    @des=("AA");
    if (defined $STRING{"ohtm"}){
	$tmp=$STRING{"ohtm"}; $tmp=~s/L|\s//g;
	if (length($tmp)==0) {
	    $STRING{"ohtm"}="";}
	else {
	    push(@des,"OBS htm");}}
    push(@des,"PHD htm","Rel htm","detail","prH htm","prL htm",
	      "subset","SUB htm","other","PHDFhtm");
    if (defined $STRING{"prhtm"}){ push(@des,"PHDRhtm");}
    if (defined $STRING{"pthtm"}){ push(@des,"PHDThtm");}
    $sym{"AA"}=     "amino acid in one-letter code";
    $sym{"OBS htm"}="HTM's observed ($symh=HTM, ' '=not HTM)";
    $sym{"PHD htm"}="HTM's predicted by the PHD neural network\n".
	"---                system ($symh=HTM, ' '=not HTM)";
    $sym{"Rel htm"}="Reliability index of prediction (0-9, 0 is low)";
    $sym{"detail"}= "Neural network output in detail";
    $sym{"prH htm"}="'Probability' for assigning a helical trans-\n".
	"---                membrane region (HTM)";
    $sym{"prL htm"}="'Probability' for assigning a non-HTM region\n".
	"---          note: 'Probabilites' are scaled to the interval\n".
	"---                0-9, e.g., prH=5 means, that the first \n".
	"---                output node is 0.5-0.6";
    $sym{"subset"}= "Subset of more reliable predictions";
    $sym{"SUB htm"}="All residues for which the expected average\n".
	"---                accuracy is > 82% (tables in header).\n".
	"---          note: for this subset the following symbols are used:\n".
	"---             L: is loop (for which above ' ' is used)\n".
	"---           '.': means that no prediction is made for this,\n".
	"---                residue as the reliability is:  Rel < 5";
    $sym{"other"}=  "predictions derived based on PHDhtm";
    $sym{"PHDFhtm"}="filtered prediction, i.e., too long HTM's are\n".
	"---                split, too short ones are deleted";
    $sym{"PHDRhtm"}="refinement of neural network output ";
    $sym{"PHDThtm"}="topology prediction based on refined model\n".
	"---                symbols used:\n".
	"---             i: intra-cytoplasmic\n".
	"---             T: transmembrane region\n".
	"---             o: extra-cytoplasmic";
				# write symbols
    if ($Ldo_htmref) {
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION: SYMBOLS\n";
	foreach $des(@des){
	    printf $fh "--- %-13s: %-s\n",$des,$sym{"$des"};}
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION\n";}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if ((! defined $tmp) || (length($tmp)==0));
#	    $format="%-".length($tmp)."s";$len=length($tmp);
				# helical transmembrane regions
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/ohtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS htm",$tmp; }
	    elsif($_=~/phtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD htm",$tmp; }
	    elsif($_=~/pfhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","other"," "; 
				printf $fh "%8s %-7s |%-s|\n"," ","PHDFhtm",$tmp; }
	    elsif($_=~/rihtm/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel htm",$tmp; }
	    elsif($_=~/prHhtm/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH htm",$tmp; }
	    elsif($_=~/prLhtm/){printf $fh "%8s %-7s |%-s|\n"," ","prL htm",$tmp; }
	    elsif($_=~/subhtm/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB htm",$tmp;}

	    elsif($_=~/prhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDRhtm",$tmp; }
	    elsif($_=~/pthtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDThtm",$tmp; }}}
    if ($Ldo_htmref) {
	print $fh
	    "--- \n",
	    "--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION END\n",
	    "--- \n";}
}				# end of wrt_phdpred_from_string

#==============================================================================
sub wrt_phdpred_from_string_htm_header {&wrt_phdpred_from_string_htmHdr(@_);} # alias




#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
#==========================================================================================
sub rdbphd_to_dotpred {
    local($Lscreen,$nres_per_row,$thresh_acc,$thresh_htm,$thresh_sec,
	  $opt_phd,$file_out,$protname,$Ldo_htmref,$Ldo_htmtop,@file) = @_ ;
    local($fhin,@des,@des_rd,@des_sec,@des_rd_sec,@des_acc,@des_rd_acc,@des_htm,@des_rd_htm,
	  %rdb_rd,%rdb,$file,$it,$ct,$mode_wrt,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdbphd_to_dotpred          converts RDB files of PHDsec,acc,htm (both/3)
#                               to .pred files as used for PP server
#--------------------------------------------------------------------------------
    $fhin= "FHIN_RDBPHD_TO_DOTPRED";
    $fhout="FHOUT_RDBPHD_TO_DOTPRED";
				# note: @des same succession as @des_rd !!
    @des_rd_0 =   ("No", "AA");
    @des_0=       ("pos","aa");
    @des_rd_acc=  ("Obie","Pbie","OREL","PREL","RI_A");
    @des_acc=     ("obie","pbie","oacc","pacc","riacc");
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_S", "pH",    "pL"    ,"PFHL", "PRHL", "PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm","prHhtm","prLhtm","pfhtm","prhtm","pthtm");}
    elsif ($Ldo_htmref) {
	@des_rd_htm=("OHL", "PHL", "RI_S", "pH",    "pL"    ,"PFHL", "PRHL");
	@des_htm=   ("ohtm","phtm","rihtm","prHhtm","prLhtm","pfhtm","prhtm");}
    elsif ($Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_S", "pH",    "pL"    ,"PFHL" ,"PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm","prHhtm","prLhtm","pfhtm","pthtm");}
    else {
	@des_rd_htm=("OHL", "PHL", "RI_S", "pH",    "pL"    ,"PFHL" );
	@des_htm=   ("ohtm","phtm","rihtm","prHhtm","prLhtm","pfhtm");}
    @des_rd_sec=  ("OHEL","PHEL","RI_S", "pH",    "pE",    "pL");
    @des_sec=     ("osec","psec","risec","prHsec","prEsec","prLsec");
				# headers
    @deshd_rd_0=  ();
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
#		       "REL_BEST","REL_BEST_DIFF",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT",
		       "HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    elsif ($Ldo_htmref) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT");}
    elsif ($Ldo_htmtop) {
	@deshd_rd_htm=("HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    else {
	$#deshd_rd_htm=0;}
				# ------------------------------
				# read RDB files
				# ------------------------------
    $ct=0;
    foreach $file (@file){
	if (! -e $file) { next; }
	++$ct; undef %rdb_rd;
	if ($ct==1) {
	    @des_rd=@des_rd_0;@des=@des_0;@deshd_rd=@deshd_rd_0;}
	else {
	    $#des_rd=$#des=$#deshd_rd=0;}
				# find out whether from PHDsec, PHDacc, or PHDhtm
	if   (&is_rdb_sec($file)){$phd="sec";push(@des_rd,@des_rd_sec);push(@des,@des_sec);}
	elsif(&is_rdb_acc($file)){$phd="acc";push(@des_rd,@des_rd_acc);push(@des,@des_acc);}
	elsif(&is_rdb_htm($file)||&is_rdb_htmref($file)||&is_rdb_htmtop($file)){
	    $phd="htm";push(@des,@des_htm);
	    push(@des_rd,@des_rd_htm);push(@deshd_rd,@deshd_rd_htm);}
	else {
	    print "*** ERROR rdbphd_to_dotpred: no RDB format recognised\n";
	    exit; }
	%rdb_rd=
	    &rd_rdb_associative($file,"not_screen","header",@deshd_rd,"body",@des_rd); 
	foreach $it (1 .. $#des_rd) { # rename data (separate for PHDsec,acc,htm)
	    $ct=1;
	    while (defined $rdb_rd{"$des_rd[$it]","$ct"}) {
		$rdb{"$des[$it]","$ct"}=$rdb_rd{"$des_rd[$it]","$ct"}; 
		++$ct; }}
	foreach $deshd (@deshd_rd){ # rename header
	    if (defined $rdb_rd{"$deshd"}) {$rdb{"$deshd"}=$rdb_rd{"$deshd"};} 
	    else                           {$rdb{"$deshd"}="UNK";}}
    }
				# ------------------------------
				# now transform to strings
				# ------------------------------
    &rdbphd_to_dotpred_getstring(@des_0,@des_sec,@des_acc,@des_htm);
				# now subsets
    &rdbphd_to_dotpred_getsubset;
				# convert symbols
    if (defined $STRING{"osec"}) { $STRING{"osec"}=~s/L/ /g; }
    if (defined $STRING{"psec"}) { $STRING{"psec"}=~s/L/ /g; }
    if (defined $STRING{"obie"}) { $STRING{"obie"}=~s/i/ /g; }
    if (defined $STRING{"pbie"}) { $STRING{"pbie"}=~s/i/ /g; }
    if (defined $STRING{"ohtm"}) { 
	$STRING{"ohtm"}=~s/L/ /g;  if ($opt_phd !~ /htm/){
	    $STRING{"ohtm"}=~s/H/T/g;$STRING{"ohtm"}=~s/E/ /g; }}
    if (defined $STRING{"phtm"}) { 
	$STRING{"phtm"}=~s/L/ /g;  if ($opt_phd !~ /htm/){
	    $STRING{"phtm"}=~s/H/T/g;$STRING{"phtm"}=~s/E/ /g; }}
    if (defined $STRING{"pfhtm"}) { 
	$STRING{"pfhtm"}=~s/L/ /g; if ($opt_phd !~ /htm/){
	    $STRING{"pfhtm"}=~s/H/T/g;$STRING{"pfhtm"}=~s/E/ /g; }}
    if (defined $STRING{"prhtm"}) { 
	$STRING{"prhtm"}=~s/L/ /g; if ($opt_phd !~ /htm/){
	    $STRING{"prhtm"}=~s/H/T/g;$STRING{"prhtm"}=~s/E/ /g; }}

    @des_wrt=@des_0;
    $#htm_header=0;
    if    ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) && 
	    (length($STRING{"phtm"})>3) ) { 
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc",@des_htm,"subhtm"); $mode_wrt="3";}
    elsif ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) ) {
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc"); $mode_wrt="both"; }
    elsif ( length($STRING{"psec"})>3 ) { 
	push(@des_wrt,@des_sec,"subsec");                   $mode_wrt="sec"; }
    elsif ( length($STRING{"pacc"})>3 ) { 
	push(@des_wrt,@des_acc,"subacc");                   $mode_wrt="acc"; }
    elsif ( length($STRING{"phtm"})>3 ) { 
	push(@des_wrt,"ohtm","phtm","rihtm","prHhtm","prLhtm","subhtm","pfhtm");
	if ($Ldo_htmref){ push(@des_wrt,"prhtm");}
	if ($Ldo_htmtop){ push(@des_wrt,"pthtm");}
	$mode_wrt="htm"; 
	if ($Ldo_htmref || $Ldo_htmtop){
	    @htm_header=&rdbphd_to_dotpred_head_htmtop(@deshd_rd_htm);}}
    else {
	print "*** ERROR rdbphd_to_dotpred: no \%STRING defined recognised\n";
	exit; }

    if ($Lscreen) {
	print "--- rdbphd_to_dotpred read from conversion:\n";
	&wrt_phdpred_from_string("STDOUT",$nres_per_row,$mode_wrt,$Ldo_htmref,
				 @des_wrt,"header",@htm_header); }

    &open_file("$fhout",">$file_out");
    &wrt_phdpred_from_string($fhout,$nres_per_row,$mode_wrt,$Ldo_htmref,
			     @des_wrt,"header",@htm_header); 
    close($fhout);
				# --------------------------------------------------
				# now collect for final file
				# --------------------------------------------------
    foreach $des ("aa","osec","psec","risec","oacc","pacc","riacc",
		  "ohtm","phtm","pfhtm","rihtm","prhtm","pthtm") {
	if (defined $STRING{"$des"}) {
	    if   ($des eq "aa") { 
		$nres=length($STRING{"$des"}); }
	    elsif(($des=~/^p/)&&(length($STRING{"$des"})>$nres)){
		$nres=length($STRING{"$des"}); }
	    $phd_fin{"$protname","$des"}=$STRING{"$des"}; }}
    $phd_fin{"$protname","nres"}=$nres;
    return(%phd_fin);
}				# end of rdbphd_to_dotpred

#==========================================================================================
sub rdbphd_to_dotpred_getstring {
    local (@des) = @_ ;
    local ($des,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#    GLOBAL                     %STRING, %rdb
#--------------------------------------------------------------------------------
    foreach $des (@des) {
	$STRING{"$des"}="";$ct=1;
	if ($des !~ /oacc|pacc/ ){
	    while (defined $rdb{"$des","$ct"}) {
		$STRING{"$des"}.=$rdb{"$des","$ct"};
		++$ct; } }
	else {
	    while (defined $rdb{"$des","$ct"}) {
		$STRING{"$des"}.=&exposure_project_1digit($rdb{"$des","$ct"});
		++$ct; } } }
}				# end of rdbphd_to_dotpred_getstring

#==========================================================================================
sub rdbphd_to_dotpred_getsubset {
    local ($des,$ct,$desout,$thresh,$desphd,$desrel);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdbphd_to_dotpred_getsubset assigns subsets:
#    GLOBAL                     %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des ("sec","acc","htm"){
	$desout="sub"."$des";
				# assign thresholds
	if    ($des eq "sec") { $thresh=$thresh_sec; }
	elsif ($des eq "acc") { $thresh=$thresh_acc; }
	elsif ($des eq "htm") { $thresh=$thresh_htm; }
	$STRING{"$desout"}="";$ct=1; # initialise
				# note: for PHDacc subset on three states (b,e,i)
	if ($des eq "acc") {$desphd="p"."bie";} else { $desphd="p"."$des"; }
	$desrel="ri"."$des";
	while ( defined $rdb{"$desphd","$ct"}) {
	    if ($rdb{"$desrel","$ct"}>=$thresh) {
		$STRING{"$desout"}.=$rdb{"$desphd","$ct"}; }
	    else {
		$STRING{"$desout"}.=".";}
	    ++$ct; }}
}				# end of rdbphd_to_dotpred_getsubset

#==========================================================================================
sub rdbphd_to_dotpred_head_htmtop {
    local (@des)= @_ ;  local ($des,$tmp,@tmp,@out);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdbphd_to_dotpred_head_htmtop: writes the header for htmtop
#--------------------------------------------------------------------------------
    $#out=0;
    foreach $des (@des){
	if (defined $rdb_rd{"$des"}){
	    $tmp=$rdb_rd{"$des"};$tmp=~s/^:*|:*$//g;
	    if ($tmp=~/\:/){
		$#tmp=0;@tmp=split(/:/,$tmp);} else {@tmp=("$tmp");}
	    if ($des !~/MODEL/){ # purge blanks and comments
		foreach $tmp (@tmp) {$tmp=~s/\(.*//g;$tmp=~s/\s//g;}}
	    foreach $tmp (@tmp) {
		push(@out,"$des:$tmp");}}}
    return(@out);
}				# end of rdbphd_to_dotpred_head_htmtop

#==========================================================================================
sub wrt_phdpred_from_string {
    local ($fh,$nres_per_row,$mode,$Ldo_htmref,@des) = @_ ;
    local (@des_loc,@header_loc,$Lheader);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string     writes the body of the PHD.pred files from the
#                               global array %STRING{}
#       in (GLOBAL)
#         A                     %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    if (! %STRING) { 
	print "*** ERROR wrt_phdpred_from_string: associative array \%STRING must be global\n";
	exit; }
    $#des_loc=$#header_loc=0;$Lheader=0;
    foreach $des(@des){
	if ($des eq "header"){ 
	    $Lheader=1;
	    next;}
	if (! $Lheader){push(@des_loc,$des);}
	else           {push(@header_loc,$des);}}
				# get length of proteins (number of residues)
    $des= $des_loc[2];		# hopefully always AA!
    $tmp= $STRING{"$des"};
    $nres=length($tmp);
				# --------------------------------------------------
				# now write out for 'both','acc','sec'
				# --------------------------------------------------
    if ($mode=~/3|both|sec|acc/){
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	print  $fh " \n \n";	# print empty before each PHD block
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    if (length($STRING{"$_"})<$it){
		next;}
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    if (length($tmp)==0) {next;}
				# secondary structure
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/osec/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS sec",$tmp; }
	    elsif($_=~/psec/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD sec",$tmp; }
	    elsif($_=~/risec/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel sec",$tmp; }
	    elsif($_=~/prHsec/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH sec",$tmp; }
	    elsif($_=~/prEsec/){printf $fh "%8s %-7s |%-s|\n"," ","prE sec",$tmp; }
	    elsif($_=~/prLsec/){printf $fh "%8s %-7s |%-s|\n"," ","prL sec",$tmp; }
	    elsif($_=~/subsec/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB sec",$tmp;}
				# solvent accessibility
	    elsif($_=~/obie/)  {if($mode=~/both|3/){print $fh " accessibility: \n"; }
				printf $fh "%-8s %-7s |%-s|\n"," 3st:","O_3 acc",$tmp;}
	    elsif($_=~/pbie/)  {if (length($STRING{"obie"})>1){$txt=" ";} 
				else{if($mode=~/both|3/){print $fh " accessibility \n";}
				     $txt=" 3st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"P_3 acc",$tmp; }
	    elsif($_=~/oacc/)  {printf $fh "%-8s %-7s |%-s|\n"," 10st:","OBS acc",$tmp;}
	    elsif($_=~/pacc/)  {if (length($STRING{"oacc"})>1){$txt=" ";}else{$txt=" 10st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"PHD acc",$tmp; }
	    elsif($_=~/riacc/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel acc",$tmp; }
	    elsif($_=~/subacc/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB acc",$tmp; }
	}
    }
				# --------------------------------------------------
				# now write out for '3','htm'
				# --------------------------------------------------
    if ($mode=~/3|htm/){
	if ($mode=~/3/) {
	    $symh="T";
	    print $fh 
		" \n",
		"************************************************************\n",
		"*    PHDhtm Helical transmembrane prediction\n",
		"*           note: PHDacc and PHDsec are reliable for water-\n",
		"*                 soluble globular proteins, only.  Thus, \n",
		"*                 please take the  predictions above with \n",
		"*                 particular caution wherever transmembrane\n",
		"*                 helices are predicted by PHDhtm!\n",
		"************************************************************\n",
		" \n",
		" PHDhtm\n";
	} else {
	    $symh="H";}
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
				# ------------------------------
				# print header for topology asf
    if ($nres_tmp>0){
	if ($#header_loc>0){
	    &wrt_phdpred_from_string_htm_header($fh,@header_loc);}
	&wrt_phdpred_from_string_htm($fh,$nres_tmp,$nres_per_row,$symh,
				     $Ldo_htmref,@des_loc);}
}				# end of wrt_phdpred_from_string

#==========================================================================================
sub wrt_phdpred_from_string_htm {
    local ($fh,$nres_tmp,$nres_per_row,$symh,$Ldo_htmref,@des_loc) = @_ ;
    local ($it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htm writes body of the PHD.pred files from the
#                               global array %STRING{} for HTM
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    @des=("AA");
    if (defined $STRING{"ohtm"}){
	$tmp=$STRING{"ohtm"}; $tmp=~s/L|\s//g;
	if (length($tmp)==0) {
	    $STRING{"ohtm"}="";}
	else {
	    push(@des,"OBS htm");}}
    push(@des,"PHD htm","Rel htm","detail","prH htm","prL htm",
	      "subset","SUB htm","other","PHDFhtm");
    if (defined $STRING{"prhtm"}){ push(@des,"PHDRhtm");}
    if (defined $STRING{"pthtm"}){ push(@des,"PHDThtm");}
    $sym{"AA"}=     "amino acid in one-letter code";
    $sym{"OBS htm"}="HTM's observed ($symh=HTM, ' '=not HTM)";
    $sym{"PHD htm"}="HTM's predicted by the PHD neural network\n".
	"---                system ($symh=HTM, ' '=not HTM)";
    $sym{"Rel htm"}="Reliability index of prediction (0-9, 0 is low)";
    $sym{"detail"}= "Neural network output in detail";
    $sym{"prH htm"}="'Probability' for assigning a helical trans-\n".
	"---                membrane region (HTM)";
    $sym{"prL htm"}="'Probability' for assigning a non-HTM region\n".
	"---          note: 'Probabilites' are scaled to the interval\n".
	"---                0-9, e.g., prH=5 means, that the first \n".
	"---                output node is 0.5-0.6";
    $sym{"subset"}= "Subset of more reliable predictions";
    $sym{"SUB htm"}="All residues for which the expected average\n".
	"---                accuracy is > 82% (tables in header).\n".
	"---          note: for this subset the following symbols are used:\n".
	"---             L: is loop (for which above ' ' is used)\n".
	"---           '.': means that no prediction is made for this,\n".
	"---                residue as the reliability is:  Rel < 5";
    $sym{"other"}=  "predictions derived based on PHDhtm";
    $sym{"PHDFhtm"}="filtered prediction, i.e., too long HTM's are\n".
	"---                split, too short ones are deleted";
    $sym{"PHDRhtm"}="refinement of neural network output ";
    $sym{"PHDThtm"}="topology prediction based on refined model\n".
	"---                symbols used:\n".
	"---             i: intra-cytoplasmic\n".
	"---             T: transmembrane region\n".
	"---             o: extra-cytoplasmic";
				# write symbols
    if ($Ldo_htmref) {
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION: SYMBOLS\n";
	foreach $des(@des){
	    printf $fh "--- %-13s: %-s\n",$des,$sym{"$des"};}
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION\n";}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if ((! defined $tmp) || (length($tmp)==0));
	    $format="%-".length($tmp)."s";$len=length($tmp);
				# helical transmembrane regions
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/ohtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS htm",$tmp; }
	    elsif($_=~/phtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD htm",$tmp; }
	    elsif($_=~/pfhtm/) {printf $fh "%8s %-7s |%$len-s|\n"," other:"," "," "; 
		                printf $fh "%8s %-7s |%-s|\n"," ","PHDFhtm",$tmp; }
	    elsif($_=~/rihtm/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel htm",$tmp; }
	    elsif($_=~/prHhtm/){printf $fh "%8s %-7s |%$len-s|\n"," detail:"," "," "; 
				printf $fh "%8s %-7s |%-s|\n"," ","prH htm",$tmp; }
	    elsif($_=~/prLhtm/){printf $fh "%8s %-7s |%-s|\n"," ","prL htm",$tmp; }
	    elsif($_=~/subhtm/){printf $fh "%-8s %-7s |%$len-s|\n"," subset:"," "," ";
				printf $fh "%-8s %-7s |%-s|\n"," ","SUB htm",$tmp;}
	    elsif($_=~/prhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDRhtm",$tmp; }
	    elsif($_=~/pthtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDThtm",$tmp; }}}
    if ($Ldo_htmref) {
	print $fh
	    "--- \n",
	    "--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION END\n",
	    "--- \n";}
}				# end of wrt_phdpred_from_string

#==========================================================================================
sub wrt_phdpred_from_string_htm_header {
    local ($fh,@header) = @_ ;
    local ($header,$header_txt,$des,%txt,@des,%dat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htmheader: writes the header for PHDhtm ref and top
#       in: header with (x1:x2), where x1 is the key and x2 the result
#--------------------------------------------------------------------------------
				# define notations
    $txt{"NHTM_BEST"}=     "number of transmembrane helices best model";
    $txt{"NHTM_2ND_BEST"}= "number of transmembrane helices 2nd best model";
    $txt{"REL_BEST_DPROJ"}="reliability of best model (0 is low, 9 high)";
    $txt{"MODEL"}=         "";
    $txt{"MODEL_DAT"}=     "";
    $txt{"HTMTOP_PRD"}=    "topology predicted ('in': intra-cytoplasmic)";
    $txt{"HTMTOP_RID"}=    "difference between positive charges";
    $txt{"HTMTOP_RIP"}=    "reliability of topology prediction (0-9)";
    $txt{"MOD_NHTM"}=      "number of transmembrane helices of model";
    $txt{"MOD_STOT"}=      "score for all residues";
    $txt{"MOD_SHTM"}=      "score for HTM added at current iteration step";
    $txt{"MOD_N-C"}=       "N  -  C  term of HTM added at current step";
    print  $fh			# first write header
	"--- \n",
	"--- ", "-" x 60, "\n",
	"--- PhdTopology prediction of transmembrane helices and topology\n",
	"--- ", "-" x 60, "\n",
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: ABBREVIATIONS\n",
	"--- \n";
				# ------------------------------
    $#des=0;			# extracting info
    foreach $header (@header_loc){
	($des,$header_txt)=split(/:/,$header);
	if ($des !~ /MODEL/){
	    push(@des,$des);
	    $dat{"$des"}=$header_txt;}}
				# writing notation
    foreach $des (@des,"MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C"){
	if ($des eq "MODEL_DAT") { # skip
	    next;}
	$tmp_des=$des;$tmp_des=~s/\_DPROJ//g;$tmp_des=~s/\s//g;
	printf $fh "--- %-13s: %-s\n",$tmp_des,$txt{"$des"};}
				# explaining algorithm
    print $fh 
	"--- \n",
	"--- ALGORITHM REF: The refinement is performed by a dynamic pro-\n",
	"--- ALGORITHM    : gramming-like procedure: iteratively the best\n",
	"--- ALGORITHM    : transmembrane helix (HTM) compatible with the\n",
	"--- ALGORITHM    : network output is added (starting from the  0\n",
	"--- ALGORITHM    : assumption, i.e.,  no HTM's  in the protein).\n",
	"--- ALGORITHM TOP: Topology is predicted by the  positive-inside\n",
	"--- ALGORITHM    : rule, i.e., the positive charges are compiled\n",
	"--- ALGORITHM    : separately  for all even and all odd  non-HTM\n",
	"--- ALGORITHM    : regions.  If the difference (charge even-odd)\n",
	"--- ALGORITHM    : is < 0, topology is predicted as 'in'.   That\n",
	"--- ALGORITHM    : means, the protein N-term starts on the intra\n",
	"--- ALGORITHM    : cytoplasmic side.\n",
	"--- \n";
    print $fh
	"--- PhdTopology REFINEMENT HEADER: SUMMARY\n";
				# writing info: first iteration
    printf $fh 
	" %-8s %-8s %-8s %-s \n","MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C";
    foreach $header (@header_loc){
	if ($header =~ /^MODEL_DAT/){
	    ($des,$header_txt)=split(/:/,$header);
	    @tmp=split(/,/,$header_txt);
	    printf $fh " %8d %8.3f %8.3f %-s\n",@tmp;}}
    print $fh
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: SUMMARY\n";
    foreach $des (@des){	# writing info: now rest
	if ($des ne "MODEL_DAT"){
	    $tmp_des=$des;$tmp_des=~s/_DPROJ|\s//g;
	    printf $fh "--- %-13s: %-s\n",$tmp_des,$dat{"$des"};}}
}				# end of wrt_phdpred_from_string_htm_header

