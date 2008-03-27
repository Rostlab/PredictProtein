#!/usr/bin/perl
##!/usr/sbin/perl -w
#
# merges PHD.rdb files (Sec,Acc,Htm)
#
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#				version 0.2   	Oct,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;

				# initialise variables
				# a.a
@kwd=("verbose","dirPhdTxt","abbrPhdRdb");
$par{"dirPhdTxt"}=          "/nfs/data5/users/ppuser/server/pub/phd/mat/";
$par{"abbrPhdRdb"}=         $par{"dirPhdTxt"} . "abbrPhdRdb3.txt";
$par{"verbose"}=1;


if ($#ARGV<2){print"goal:     merges PHD.rdb files (Sec,Acc,Htm)\n";
	      print"usage:    file.rdbSec file.rdbAcc file.rdbHtm\n";
	      print"option:   fileOut=x.rdb \n";
	      print"defaults:\n";
	      foreach $kwd(@kwd){printf "%-15s %-s\n",$kwd,$par{"$kwd"};}
	      exit;}

#$fhin="FHIN";
$fileOut="Merge-".$ARGV[1];$fileOut=~s/sec|acc|htm//g;
				# read command line
$#fileIn=0;
foreach $arg (@ARGV){
    if ($arg =~ /^fileOut=(.+)/){
	$fileOut=$1;$fileOut=~s/\s//g;}
    elsif (-e $arg) {
	push(@fileIn,$arg);}
    else {
	$Lok=0;
	foreach $kwd(@kwd){if ($arg =~/^$kwd=(.+)$/){$par{"$kwd"}=$1;$Lok=1;
						     last;}}
	if (! $Lok){
	    print "*** unrecognised input argument $arg\n";
	    exit;}}}
				# do merging
&rdbMergeManager($fileOut,$par{"abbrPhdRdb"},$par{"verbose"},@fileIn);

if ($par{"verbose"}){print "--- ended fine, output in $fileOut\n";}
exit;

#==============================================================================
# library collected (begin)
#==============================================================================


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
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

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
	warn "*** ERROR open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** open_file: Cannot create new file '$file_name'\n" ;}
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


#===============================================================================
sub rdbMergeManager {
    local ($fileRdb,$fileAbbrRdb,$LscreenLoc,@fileRdbLoc) = @_ ;
    local ($fhout_tmp,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbMergeManager             manages merging two PHD *.rdb files ('name'= acc + sec + htm)
#   note:                       returns fileRdb!
#   $fileIn:                    will be digested to yield the input files: 
#                                  fileIn'exp' and fileIn'sec'
#-------------------------------------------------------------------------------
    if ($LscreenLoc eq "STDOUT"){$LscreenLoc=1;}
    if ($#fileRdbLoc<2){	# no merge required
	return; }		# 
    if ($LscreenLoc){ print "--- rdbMergeManager: \t merging RDB files (into $fileRdb)\n";}
				# set defaults
    &rdbMergeDefaults();
				# ------------------------------
				# merge files
				# ------------------------------
    $fhout_tmp = "FHOUT_RDB_MERGE_MANAGER";
    &open_file("$fhout_tmp", ">$fileRdb");
    &rdbMergeDo($fileAbbrRdb,$fhout_tmp,$LscreenLoc,@fileRdbLoc);
    close($fhout_tmp);
}				# end of rdbMergeManager

#===============================================================================
sub rdbMergeDefaults {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbMergeDefaults            sets defaults
#       GLOBAL:                 all variables global
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdbMergeDefault";$fhinLoc="FHIN"."$sbrName";

    @desSec=   ("No","AA","OHEL","PHEL","RI_S","pH","pE","pL","OtH","OtE","OtL");
    @desAcc=   ("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    for $it (0..9){$tmp="Ot".$it; push(@desAcc,$tmp); }
    @desHtm=   ("OHL","PHL","PFHL","PRHL","PiTo","RI_H","pH","pL","OtH","OtL");

    @desOutG=   ("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL",
                "OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    @formOut=  ("4N","1" ,"1"   ,"1"   ,"1N",  "3N", "3N", "3N",
                "3N"  ,"3N"  ,"3N",  "3N",  "1N",  "1",   "1");
    for $it (0..9){$tmp="Ot".$it; push(@desOutG,$tmp); push(@formOut,"3N");}
    push(@desOutG, "OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN");
    push(@formOut,"1"  ,"1"  ,"1"   ,"1"   ,"1"   ,"1N"  ,"3N" ,"3N");

    foreach $it (1..$#desOutG){
        $tmp=$formOut[$it];
        if   ($tmp=~/N$/) {$tmp=~s/N$/d/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        elsif($tmp=~/F$/) {$tmp=~s/F$/f/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        else              {$tmp.="s";    $formOutPrintf{"$desOutG[$it]"}=$tmp;} }
    $sep="\t";                  # separator
}				# end of rdbMergeDefaults

#===============================================================================
sub rdbMergeDo {
    local ($fileAbbrRdb,$fhoutLoc,$LscreenLoc,@fileRdbLoc) = @_ ;
    local ($fhinLoc,$it,$tmp,$Lok,$ct,$sep_tmp,$rd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbMergeSecAcc              merging two PHD *.rdb files ('name'= acc + sec)
#-------------------------------------------------------------------------------
    $fhinLoc="FHIN_MERGE_RDB";
    $LerrLoc=0;			# files existing?
    foreach $file (@fileRdbLoc){
	if (! -e $file){&myprt_empty; $LerrLoc=1;
			&myprt_txt("ERROR: in rdbMergeDo \t file '$file' missing"); }}
    if ($LerrLoc)      {die '*** unwanted exit rdbMergeDo'; }
                                # --------------------------------------------------
                                # reading files
                                # --------------------------------------------------
    $LisAccLoc=$LisHtmLoc=$LisSecLoc=0;
    foreach $file (@fileRdbLoc){
	if (&is_rdb_sec($file)){ # secondary structure
	    $#headerSec=0;&open_file("$fhinLoc", "$file");
	    while(<$fhinLoc>){$rd=$_;
			      if(($rd=~/^\#/) && ($rd !~ /^\# NOTATION/)){
				  push(@headerSec,$rd);}
			      last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisSecLoc=1;
	    %rdSec=&rd_rdb_associative($file,"body",@desSec); }
	elsif (&is_rdb_acc($file)){ # accessibility
	    $#headerAcc=0;&open_file("$fhinLoc", "$file");
	    while(<$fhinLoc>){$rd=$_;
			      if(($rd=~/^\#/) && ($rd !~ /^\# NOTATION/)){
				  push(@headerAcc,$rd);}
			      last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisAccLoc=1;
	    %rdAcc=&rd_rdb_associative($file,"body",@desAcc);} # external lib-prot.pl
	elsif (&is_rdb_htm($file)){ # htm
	    $#headerHtm=0;&open_file("$fhinLoc", "$file");
	    while(<$fhinLoc>){$rd=$_;
			      if(($rd=~/^\#/) && ($rd !~ /^\# NOTATION/)){
				  push(@headerHtm,$rd);}
			      last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisHtmLoc=1;
	    %rdHtm=&rd_rdb_associative($file,"body",@desHtm); # external lib-prot.pl
	    foreach $ct (1..$rdHtm{"NROWS"}){
		$rdHtm{"OTN","$ct"}= $rdHtm{"OHL","$ct"};
		$rdHtm{"PTN","$ct"}= $rdHtm{"PHL","$ct"};
		$rdHtm{"PFTN","$ct"}=$rdHtm{"PFHL","$ct"};
		$rdHtm{"PRTN","$ct"}=$rdHtm{"PRHL","$ct"};
		$rdHtm{"OtT","$ct"}= $rdHtm{"OtH","$ct"};
		$rdHtm{"OtN","$ct"}= $rdHtm{"OtL","$ct"};}}
    }
				# decide when to break the line
    if ($LisHtmLoc){$desNewLine="OtN";}else{$desNewLine="Ot9";}
				# ------------------------------
				# read abbreviations
    $#header=0;
    if (-e $fileAbbrRdb) {
	$Lok=&open_file("$fhinLoc", "$fileAbbrRdb");
	if (!$Lok){print "*** ERROR rdbMergeDo \t no read for '$fileAbbrRdb'\n";
		   return(0);}
	while(<$fhinLoc>){$rd=$_;$rd=~s/\n//g;
			  push(@header,$rd) if ($rd=~/^\# NOTATION/);}}
	close($fhinLoc);
				# --------------------------------------------------
				# write header into file
				# --------------------------------------------------
    &rdbMergeHeader($fhoutLoc,$LscreenLoc);
				# --------------------------------------------------
				# write selected columns
				# --------------------------------------------------
                                # names
    foreach $des (@desOutG) {
        if (defined $rdSec{"$des","1"}||defined $rdAcc{"$des","1"}||defined $rdHtm{"$des","1"}) {
	    if ($des eq $desNewLine){$sep_tmp="\n";}else{$sep_tmp=$sep;}
            print $fhoutLoc "$des","$sep_tmp"; }}
                                # formats
    foreach $it (1..$#format_out) {
        if (defined $rdSec{"$desOutG[$it]","1"} || defined $rdAcc{"$desOutG[$it]","1"} ||
	    defined $rdHtm{"$desOutG[$it]","1"}) {
	    if ($desOutG[$it] eq $desNewLine){$sep_tmp="\n";}else{$sep_tmp=$sep;}
            print $fhoutLoc "$format_out[$it]","$sep_tmp"; } }
                                # data
    foreach $ct (1..$rdSec{"NROWS"}){
        foreach $des("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL") {
            if ( defined $rdSec{"$des","$ct"} ) {
                $tmp="%".$formOutPrintf{"$des"};
                $rd=$rdSec{"$des","$ct"};$rd=~s/\s|\n//g;
                printf $fhoutLoc "$tmp$sep",$rd; }}
        foreach $des("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie",
                   "Ot0","Ot1","Ot2","Ot3","Ot4","Ot5","Ot6","Ot7","Ot8","Ot9") {
            if ( defined $rdAcc{"$des","$ct"} ) {
                $tmp="%".$formOutPrintf{"$des"};
                if ($des eq $desNewLine){$sep_tmp="\n";} else {$sep_tmp=$sep;}
                $rd=$rdAcc{"$des","$ct"};$rd=~s/\s|\n//g;
                printf $fhoutLoc "$tmp$sep_tmp",$rd; }}
	if (! $LisHtmLoc){
	    next;}
        foreach $des("OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN"){
            if ( defined $rdHtm{"$des","$ct"} ) {
                $tmp="%".$formOutPrintf{"$des"};
                $rd=$rdHtm{"$des","$ct"};$rd=~s/\s|\n//g;
		if ($des eq $desNewLine){$sep_tmp="\n";} else {$sep_tmp=$sep;}
                printf $fhoutLoc "$tmp$sep_tmp",$rd; }}
    }
}				# end of rdbMergeSecAcc

#===============================================================================
sub rdbMergeHeader {
    local($fhoutLoc,$LscreenLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbMergeHeader              writes the merged RDB header
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdbMergeHeader";$fhinLoc="FHIN"."$sbrName";

    print $fhoutLoc "\# Perl-RDB\n"; # keyword
    if ($LisSecLoc && $LisAccLoc && $LisHtmLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc+PHDhtm\n",
	    "\# Prediction of secondary structure, accessibility, and transmembrane helices\n";}
    elsif ($LisSecLoc && $LisAccLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc\n",
	    "\# Prediction of secondary structure, and accessibility\n";}
				# special information from header
    foreach $rd (@headerSec){$tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
			     if ($rd =~/^\# (NOTATION|Perl|PHD)/i){
				 next;}
			     $Lok{"$tmp"}=1; # to avoid duplication of information
			     print $fhoutLoc $rd;}
    foreach $rd (@headerAcc){$tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
			     if ($rd =~/^\# (NOTATION|Perl|PHD)/i){
				 next;}
			     if (defined $Lok{"$tmp"}){
				 next;}
			     $Lok{"$tmp"}=1; # to avoid duplication of information
			     print $fhoutLoc $rd;}
    foreach $rd (@headerHtm){$tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
			     if ($rd =~/^\# (NOTATION|Perl|PHD)/i){
				 next;}
			     if (defined $Lok{"$tmp"}){
				 next;}
			     $Lok{"$tmp"}=1; # to avoid duplication of information
			     print $fhoutLoc $rd;}
    foreach $desOut(@desOutG){	# notation
	$Lok=0;
	if    ($desOut =~ /^Ot[1-9]/){ # special case accessibility net out (skip 1-9)
	    next;}
	elsif ($desOut =~ /^Ot0/){ # special case accessibility net out (write 0)
	    foreach $rd(@header){
		if ($rd =~/^Ot\(n\)/){$Lok=1;
				      print $fhoutLoc "$rd\n";
				      last;}}
	    next;}
	foreach $rd(@header){
	    if ($rd =~/$desOut/){$Lok=1;
				 print $fhoutLoc "$rd\n";
				 last;}}
	if ($LscreenLoc && ! $Lok) {
	    print "-*- WARNING rdbMergeDo \t missing description for desOut=$desOut\n";}}
    print $fhoutLoc "\# \n";
}				# end of rdbMergeHeader

