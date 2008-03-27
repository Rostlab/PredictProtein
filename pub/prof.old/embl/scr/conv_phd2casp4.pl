#!/usr/bin/perl
##!/usr/bin/perl
##!/bin/env perl
##!/usr/bin/perl -w
##!/usr/pub/bin/perl -w
##!/usr/sbin/perl -w
#
# convert PHD .rdb_phd into CASP4 format
#
#
$[ =1 ;

# push (@INC, "//home/phd/server/pub/perl", "/home/phd/ut/perl") ;
# require "/home/phd/server/pub/phd/scr/scr/lib-ut.pl"; 
# require "/home/phd/server/pub/phd/scr/scr/lib-br.pl"; 

if ($#ARGV<1){print"goal:    convert to CASP4 format NOTE: you HAVE to give NALIGN\n";
	      print"usage:   'script t000x.rdb_phd nalign'\n";
	      print"option:  fileOut=x, nali=n, notScreen\n";
	      exit;}

$filePhd=$ARGV[1];
$fhout="FHOUT";$Lscreen=1;

$tNalign1=8;			# threshold in Nali for which ri=ri/10 +1
$tNalign2=3;			# threshold in Nali for which ri=ri/10
				# note: below take 1/2 ri
$numOfSubmission=1;		# number of predictions submitted before

foreach $arg (@ARGV){ if    ($arg=~/^fileOut=/)  {$arg=~s/^.+=|\s//g; $fileOut=$arg;}
		      elsif ($arg=~/^nali.*=/)   {$arg=~s/^.+=|\s//g; $nalign=$arg;}
		      elsif ($arg=~/^notScreen|^not_screen/) {$Lscreen=0;}}
if (! defined $fileOut){ $fileOut=$filePhd; 
			 $fileOut=~s/\.rdb.*$/\.abf1_casp/g;}
$nalign=0                       if (! defined $nalign);

$name=$filePhd; $name=~s/\.rdb.*$//g; 
#print"*** name should be 't0005'\n" if ($name !~/^t/);
$name=~s/^t/T/;


@desRdb=("body","AA","PHEL","RI_S","PREL","RI_A","Pbie");

%rd=
    &rd_rdb_associative($filePhd,@desRdb);
                                # grep NALI
if (! defined $nalign || ! $nalign) {
    $filePhd2=$filePhd;$filePhd2=~s/\..*$//g;
    $filePhd2.=".phd";
    if (-e $filePhd2){
        $nalignGrep=`grep NALIGN $filePhd2`;
        if (defined $nalignGrep && $nalignGrep=~/\d/){
            $nalignGrep=~s/^\D*(\d+)\D*$/$1/g;
            $nalign=$nalignGrep;}}}
        
				# write file
&open_file("$fhout", ">$fileOut");
&wrtCasp4("$fhout",$name,$nalign,$tNalign1,$tNalign2,$numOfSubmission);
close($fhout);

if ($Lscreen) {			# screen
    &wrtCasp4("STDOUT",$name,$nalign,$tNalign1,$tNalign2,$numOfSubmission);
    print "--- conv_phd2casp4: output in '$fileOut'\n";}

exit;


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

#===============================================================================
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

#===============================================================================
sub read_rdb_num {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[=1 ; 
#----------------------------------------------------------------------
#   read_rdb_num                reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read
#         $readheader:          returns the complete header as one string
#         @readcol:             returns all columns to be read
#         @readname:            returns the names of the columns
#         @readformat:          returns the format of each column
#----------------------------------------------------------------------
    $readheader = ""; $#readcol = 0; $#readname = 0; $#readformat = 0;

    for ($it=1; $it<=$#readnum; ++$it) { 
	$readcol[$it]=""; $readname[$it]=""; $readformat[$it]=""; }

    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {		              # header  
	    $readheader .= "$_"; }
	else {		              # rest:
	    ++$ct;
	    if ( $ct >= 3 ) {	              # col content
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
                    if (defined $tmpar[$readnum[$it]]){
                        $readcol[$it].= $tmpar[$readnum[$it]] . " ";}}}
	    elsif ( $ct == 1 ) {              # col name
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
                    if (defined $tmpar[$readnum[$it]]){
                        $readname[$it].= $tmpar[$readnum[$it]];}} }
	    elsif ( $ct == 2 ) {	      # col format
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos= $readnum[$it];
                    if (defined $tmpar[$readnum[$ipos]]){
                        $tmp= $tmpar[$ipos]; $tmp =~ s/\s//g;
                        $readformat[$it].= $tmp . " ";}}}
	}
    } 
    for ($it=1; $it<=$#readname; ++$it) {
	$readcol[$it] =~ s/^\s+//g;	      # correction, if first characters blank
	$readformat[$it] =~ s/^\s+//g; $readname[$it] =~ s/^\s+//g;
	$readcol[$it] =~ s/\n//g;	      # correction: last not return!
	$readformat[$it] =~ s/\n//g; $readname[$it] =~ s/\n//g; 
    }
}				# end of read_rdb_num

#===============================================================================
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

#==========================================================================================
sub wrtCasp4 {
    local ($fhloc,$name,$nalignLoc,$tNalign1,$tNalign2,$numOfSubmission) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtCasp4                       
#--------------------------------------------------------------------------------

    if ($name =~ /^t/i){
	$idLoc=$name;$idLoc=~s/^.*\/|\..*$//g;
	print $fhloc 
	    "From: rost\@columbia.edu\n",
	    "To: submit\@predictioncenter.llnl.gov\n",
	    "Subject: prediction SS ($name)\n",
	    "--text follows this line--\n"; 
				# for CASP auto (99)
	print $fhloc
	    "PFRMAT SS\n",
	    "TARGET $idLoc\n",
	    "AUTHOR 2031-3812-4177, Rost, CUBIC, Columbia, rost\@","columbia.edu\n",
	    "REMARK Automatic usage of PHDsec\n",
	    "REMARK CAFASP\n",
	    "METHOD SERVERNAME:    PredictProtein/PHD\n",
	    "METHOD PROGRAM:       PHD secondary structure and solvent accessibility prediction\n",
	    "METHOD PARAMETERS:    DEFAULT\n",
#	    "METHOD URL:           http://cubic.bioc.columbia.edu/predictprotein\n",
	    "METHOD SERVER URL:    http://cubic.bioc.columbia.edu/predictprotein\n";

	print $fhloc 
    }
    else {
	print $fhloc 
	    "PFRMAT SS\n",
	    "TARGET $name\n",
	    "AUTHOR your_name and your_email \n",
	    "REMARK Automatic usage of PHDsec\n",
	    "REMARK CAFASP\n",
	    "METHOD SERVERNAME:    PredictProtein/PHD\n",
	    "METHOD PROGRAM:       PHD secondary structure and solvent accessibility prediction\n",
	    "METHOD PARAMETERS:    DEFAULT\n",
#	    "METHOD URL:           http://cubic.bioc.columbia.edu/predictprotein\n",
	    "METHOD SERVER URL:    http://cubic.bioc.columbia.edu/predictprotein\n";
    }
	
    if    ($nalignLoc>$tNalign1){$conf=0.72;}
    elsif ($nalignLoc>$tNalign2){$conf=0.70;}
    else                        {$conf=0.68;} 
    print $fhloc "MODEL 1\n";
				# sec
#    printf $fhloc "SS %6d\n",$rd{"NROWS"};
    foreach $it (1..$rd{"NROWS"}){
	$aa=$rd{"AA","$it"};
	$sec=$rd{"PHEL","$it"}; if ($sec eq "L"){$sec="C";}
	$ri=$rd{"RI_S","$it"};
	if    ($nalignLoc>$tNalign1){++$ri; $ri=$ri/10;}
	elsif ($nalignLoc>$tNalign2){$ri=$ri/10;}
	else                        {$ri=$ri/20;}
	printf $fhloc "%-1s  %-1s  %5.2f\n",$aa,$sec,$ri;}
				# acc
#    printf $fhloc "ACC %6d\n",$rd{"NROWS"};
#    foreach $it (1..$rd{"NROWS"}){
#	$aa=$rd{"AA","$it"};
#	$acc=$rd{"PREL","$it"};
#	$ri=$rd{"RI_A","$it"};
#	if    ($nalignLoc>$tNalign1){++$ri; $ri=$ri/10;}
#	elsif ($nalignLoc>$tNalign2){$ri=$ri/10;}
#	else                        {$ri=$ri/20;}
#	printf $fhloc "%-1s  %-1s  %5.2f\n",$aa,$acc,$ri;}

#    print $fhloc "ENDDAT 1.1\n";
    print $fhloc "END\n";
}				# end of wrtCasp4


