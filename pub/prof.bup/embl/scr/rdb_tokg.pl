#!/usr/bin/perl
##!/bin/env perl
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# rdb_tokg
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	rdb_tokg.pl file_rdb file_out opt_phd 
#
# task:		RDB (phd) -> kg (i.e. commata)
# 		
# 		note: opt_phd="both","sec","acc","htm"
#
#------------------------------------------------------------------------------#
#	Copyright				Jul        	1994	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Aug,    	1995	       #
#				version 0.2   	Oct,    	1998	       #
#------------------------------------------------------------------------------#

#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

#require "/nfs/data5/users/ppuser/server/pub/phd/scr/lib-br.pl";
#require "/nfs/data5/users/ppuser/server/pub/phd/scr/lib-ut.pl";

#----------------------------------------
# read input
#----------------------------------------
$file_in= $ARGV[1];
$file_out=$ARGV[2];
$opt_phd= $ARGV[3];

if ($#ARGV < 3) {
    print "goal: converts the tab separated columns in the PHD.rdb \n";
    print "      file into comma separated columns\n";
    print " \n";
    print "use:  rdb_tokg.pl file_rdb file_out opt_phd\n";
    print " \n";
    print "with: opt_phd=<both|sec|acc|htm>\n";
    exit; }
				# files existing?
if ( ! -e $file_in ) { 
    print "ERROR: in rdb_tokg \t file in '$file_in' missing\n"; 
    exit;}

#------------------------------
# read and print
#------------------------------
&rdb_tokg_pp($file_in,$file_out,$opt_phd);

exit;


#==============================================================================
# library collected (begin)
#==============================================================================

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

#==========================================================================
sub rdb_tokg_pp {
    local ($file_in,$file_out,$opt_phd) = @_ ;
    local ($tmp,$it,$fhin,$fhout,@des,@format,$des,$sep,$sep_tmp,@header,%rd,
	   $ct,$Lok,$itdes,$itres);
#----------------------------------------------------------------------
#   prints the conversion RDB -> commata delimited graph ...
#----------------------------------------------------------------------
    $fhin= "FHIN_MERGE_RDB";
    $fhout="FHOUT_MERGE_RDB";
                                # ------------------------------
                                # defaults
                                # ------------------------------
    if    ($opt_phd eq "both") {
	@des=   ("No","AA","PHEL","RI_S","OtH","OtE","OtL","PACC","PREL","RI_A","Pbie");
	@format=("4d","1s","1s"  ,"1d",  "3d", "3d", "3d", "3d"  ,"3d",  "1d",  "1s");
	for $it (0..9){$tmp="Ot".$it; push(@des,$tmp); push(@format,"3d");} }
    elsif ($opt_phd eq "sec") {
	@des=   ("No","AA","PHEL","RI_S","pH","pE","pL","OtH","OtE","OtL");
	@format=("4d","2s","4s"  ,"4d"  ,"3d","3d","3d","3d", "3d", "3d"); }
    elsif ($opt_phd eq "acc") {
	@des=   ("No","AA","PACC","PREL","RI_A","Pbie");
	@format=("4d","2s","4d"  ,"4d",  "4d",  "4s");
	for $it (0..9){$tmp="Ot".$it; push(@des,$tmp); push(@format,"3d");}}
    elsif ($opt_phd eq "htm") {
	@des=   ("No","AA","PHL","PFHL","RI_S","pH","pL","OtH","OtL");
	@format=("4d","2s","3s" ,"4s"  ,"4d"  ,"2d","2d","3d", "3d"); }
    elsif ($opt_phd eq "htmtop") {
	@des=   ("No","AA","PHL","PFHL","PRHL","PiTo","RI_S","pH","pL","OtH","OtL");
	@format=("4d","2s","3s" ,"4s"  ,"4s"  ,"4s"  ,"4d"  ,"2d","2d","3d", "3d"); }
    else {
	print "*** ERROR: rdb_tokg_pp: option '$opt_phd' not accepted!\n";
	exit;}
    $sep=",";                   # separator
                                # --------------------------------------------------
                                # reading
                                # --------------------------------------------------
    $#header=0;
    &open_file("$fhin", "$file_in");
    while(<$fhin>){if(/^\#/){push(@header,$_);}else{last;}}
    close($fhin);
    %rd=
        &rd_rdb_associative($file_in,"body",@des);
				# --------------------------------------------------
				# write header into file
				# --------------------------------------------------
    &open_file("$fhout", ">$file_out");
    $ct=0;
    foreach $_ (@header) { 
	++$ct;
        if   (/NOTATION/){      # name used?
            $Lok=0;
            foreach $des(@des) { if ($_=~/$des/) {$Lok=1;last;}}
	    if ( (! $Lok) && ($_=~/Ot/) ) {$Lok=1;} }
	elsif($ct<5){$Lok=0;}
        else {$Lok=1;}
        if ($Lok) {
	    $_=~s/^\#/\*/;
	    print $fhout "$_" ; }}
				# --------------------------------------------------
				# write selected columns
				# --------------------------------------------------
                                # names
    foreach $itdes (1..$#des) {
	$des=$des[$itdes];
        if ( defined $rd{"$des","1"} ) {
	    if ($des eq $des[$#des]){$sep_tmp="\n";}else{$sep_tmp=$sep;}
	    $tmp="%".$format[$itdes];$tmp=~s/d$|\..*f$/\s/g;
	    if ($opt_phd eq "both") {$tmp="\%s";}
            printf $fhout "$tmp$sep_tmp",$des; } }
                                # data
    foreach $itres (1..$rd{"NROWS"}){
        foreach $itdes(1..$#des){
            if ( defined $rd{"$des[$itdes]","$itres"} ) {
                $tmp="%".$format[$itdes];
                if ($des[$itdes] eq $des[$#des]) {$sep_tmp="\n";} else {$sep_tmp=$sep;}
                $rd=$rd{"$des[$itdes]","$itres"};$rd=~s/\s|\n//g;
                printf $fhout "$tmp$sep_tmp",$rd; }}
    }
    print $fhout "\n";
    close($fhout);
}				# end of read_rdb_num

