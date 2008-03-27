#!/usr/bin/perl
##!/bin/env perl
##!/usr/bin/perl -w
##!/usr/sbin/perl -w
##!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# phdrdb_to_pred
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	phdrdb_to_pred.pl list(.rdb_phd) files from PHD
#
# task:		in: list of PHD RDB files, out: format for EVALSEC
#               
# 		
#
#------------------------------------------------------------------------------#
#	Copyright				Sep,        	1995	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 1.0   	Oct,    	1998	       #
#------------------------------------------------------------------------------#

#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;
&ini();
				# --------------------------------------------------
				# loop over all files
				# --------------------------------------------------
$ctfile=$#id=0;
foreach $file_in (@fileIn) {
    %rd=&rd_rdb_associative($file_in,"not_screen","body",@des_rd);
    next if ($rd{"NROWS"}<5);	# skip short ones
    $Lexcl=0;			# security check
    foreach $des (@des_rd){
	if (! defined $rd{"$des","1"}){
	    next if ( ($opt_phd eq "acc") && ($des eq "OHEL"));
	    $ok{$des}=0;
	    print "-*- WARN $scrName des=$des, missing in '$file_in' \n"; }
	$ok{$des}=1;}
#    $Lexcl=0;			# xx
    next if ($Lexcl);
    ++$ctfile;
    $id=$file_in;$id=~s/^.*\/([^\.]*)\..*/$1/; $id=~s/\..*//g;
    push(@id,$id);
    $all{"$id","NROWS"}=$rd{"NROWS"};
    foreach $des (@des_rd){
	next if (! defined $ok{$des} || ! $ok{$des});
				# hack 31-05-97 to allow acc, only
	if (($opt_phd eq "acc")&&($des eq "OHEL")&&(! defined $rd{"$des","1"})){
	    foreach $itres (1..$rd{"NROWS"}){
		$rd{"$des","$itres"}=" ";$rd{"SS","$itres"}=" ";}}
	$all{"$id","$des"}="";
	if ($des =~/^[OP]REL/){
	    foreach $itres (1..$rd{"NROWS"}){
		$all{"$id","$des"}.=&exposure_project_1digit($rd{"$des","$itres"});}}
	else {
	    foreach $itres (1..$rd{"NROWS"}){
		$all{"$id","$des"}.=$rd{"$des","$itres"}; 
	    }
	    if ($des=~/O.*L|P.*L/){	# convert L->" "
		if ($opt_phd eq "htmx") {
		    $all{"$id","$des"}=~s/E/ /g;}
		$all{"$id","$des"}=~s/L/ /g;}
	}
    }
}

				# --------------------------------------------------
				# now write out
				# --------------------------------------------------
$desvec=join(',',@des_out); $desvec=~s/,*$//g;
$idvec= join(',',@id);      $idvec=~s/,*$//g;

&phdRdb2phdWrt($fileOut,$idvec,$desvec,$opt_phd,$nresPerRow,$LnoHdr,%all);

print "--- $scrName output in file=$fileOut\n"      if ($Lscreen && -e $fileOut);
print "*** $scrName output file=$fileOut missing\n" if (! -e $fileOut);
exit;

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                       
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."ini";$fhinLoc="FHIN"."$sbrName";

    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
    $script_goal=      "in: list of PHD RDB files, out: format for EVALSEC";
    $script_input=     "*.rdb_phd files from PHD + mode <sec|acc|htm>";
    $script_opt_ar[1]= "output file";
    $script_opt_ar[2]= "option for PHDx keys=both,sec,acc,htm,";
    $script_opt_ar[3]= "noHdr        -> no comment lines";
    $script_opt_ar[4]= "nresPerRow=n -> number of residues per row";
    $script_opt_ar[5]= "dirLib=/perl/-> directory of perl libs";
    $script_opt_ar[6]= "dirOut=      -> output directory";
				#----------------------------------------
				# about script
    				#----------------------------------------
    if ( ($#ARGV < 2) || $ARGV[1]=~/^(help|man)$/ ) { 
	print "$scrName '$script_input'\n";
	print "\t $script_goal\n";
	print "1st arg= list of RDB files\n";
	print "other  : keys=not_screen, fileOut=, 'htm,acc,sec,both' , 'fil,ref,ref2,nof'\n";
	foreach $kwd(@script_opt_ar){
	    print "       : $kwd\n";}
	exit;}
				#----------------------------------------
				# read input
				#----------------------------------------
    $Lscreen=    1;
    $fileOut=    "unk";
    $opt_phd=    "unk";
    $opt=        "unk";
    $LnoHdr=     0;
    $nresPerRow=80;		# number of residues per row (in output)

    $#fileIn=0;
    foreach $arg(@ARGV){
	if    ($arg=~/^not_screen/)          {$Lscreen=0;}
	elsif ($arg=~/^file.?[Oo]ut=(.+)$/)  {$fileOut=$1;}
	elsif ($arg=~/^dirOut=(.+)$/)        {$dirOut=$1; $dirOut.="/" if ($dirOut !~/\/$/);}
	elsif ($arg=~/^htm/)                 {$opt_phd="htm";}
	elsif ($arg=~/^sec/)                 {$opt_phd="sec";}
	elsif ($arg=~/^acc/)                 {$opt_phd="acc";}
	elsif ($arg=~/^both/)                {$opt_phd="both";}
	elsif ($arg=~/^nof/)                 {$opt="nof";}
	elsif ($arg=~/^fil/)                 {$opt="fil";}
	elsif ($arg=~/^ref2/)                {$opt="ref2";}
	elsif ($arg=~/^ref/)                 {$opt="ref";}
	elsif ($arg=~/^noHdr/)               {$LnoHdr=1;}
	elsif ($arg=~/^nresPerRow=(\d+)$/)   {$nresPerRow=$1;}
	elsif (-e $arg && &isRdb($arg))      {push(@fileIn,$arg);}
	elsif (-e $arg && &isRdbList($arg))  {$fileIn=$arg;}
	else                                 {print "*** ERROR $scrName: arg '$arg' not understood\n";
					      exit;}}
				#----------------------------------------
				# defaults
				#----------------------------------------
    if ($opt_phd eq "unk"){$opt_phd=   "htm";}
    if ($opt_phd eq "sec"){$opt=       "unk";}
    if ($opt_phd eq "acc"){$opt=       "unk";}
    if ($opt eq "unk")    {$opt=       "fil";}
    
    if     ($opt_phd eq "htm") {
	if    ($opt eq "nof") { @des_rd= ("AA","OHL","PHL","RI_S");
				@des_out=("AA","OHL","PHL","RI_S");}
	elsif ($opt eq "fil") { @des_rd= ("AA","OHL","PFHL","RI_S");
				@des_out=("AA","OHL","PFHL","RI_S");}
	elsif ($opt eq "ref") { @des_rd= ("AA","OHL","PRHL","RI_S");
				@des_out=("AA","OHL","PRHL","RI_S");}
	elsif ($opt eq "ref2"){ @des_rd= ("AA","OHL","PR2HL","RI_S");
				@des_out=("AA","OHL","PR2HL","RI_S");}
	else                  { print "*** ERROR $scrName:ini: opt=$opt, not ok\n";
				exit;}}
    elsif ($opt_phd eq "sec") { @des_rd= ("AA","OHEL","PHEL","RI_S");
				@des_out=("AA","OHEL","PHEL","RI_S");}
    elsif ($opt_phd eq "acc") { @des_rd= ("AA","OHEL","OREL","PREL","RI_A");
				@des_out=("AA","OHEL","OREL","PREL","RI_A");}
    else                      { print "*** ERROR $scrName:ini: opt_phd=$opt_phd, not ok\n";
				exit;}

				# ------------------------------
				# output file
    if ($#fileIn == 1) {
	$fileOut=$fileIn . "_out"  if ($fileOut eq "unk" && defined $fileIn);
	$fileOut=$fileIn[1]."_out" if ($fileOut eq "unk" && defined $fileIn[1] && $#fileIn==1);
	$fileOut="Out".$scrName.$$ if ($fileOut eq "unk" && ! defined $fileIn);
	$fileOut=~s/^.*\///g;
	$fileOut=$dirOut. $fileOut if (defined $dirOut && -d $dirOut); }
    else {
	if ($opt_phd =~ /^(htm|acc|sec)$/) {
	    $fileOut="Out-".$opt_phd.".predrel"; }
	else {
	    $fileOut="Out-phd.predrel"; }}

				#----------------------------------------
				# check existence of files
				#----------------------------------------
    if (defined $fileIn && ! -e $fileIn) {
	print "*** ERROR $scrName:ini: fileIn=$fileIn does not exist\n"; 
	exit; }
    elsif (defined $fileIn){	# list of RDB
	&open_file($fhinLoc, "$fileIn");
	while(<$fhinLoc>){$_=~s/\s|\n//g;
		       next if (length($_)<3) ;
		       if (-e $_){
			   push(@fileIn,$_); }
		       else {
			   print "*** phdrdb_to_pred: file '$_' missing \n";}}close($fhinLoc);}

}				# end of ini

#==============================================================================
# library collected (begin)
#==============================================================================

#==============================================================================
sub isRdb {local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	   return (0) if (! -e $fileInLoc);$fh="FHIN_CHECK_RDB";
	   &open_file("$fh", "$fileInLoc") || return(0);
	   $tmp=<$fh>;close($fh);
	   return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
	   return 0; }	# end of isRdb


#==============================================================================
sub isRdbList {local ($fileInLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isRdbList                   checks whether or not file is list of Rdb files
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	       return(0) if (! -e $fileInLoc); $fhinLoc="FHIN_RDBLIST";$Lok=0;
	       $Lok=&open_file("$fhinLoc","$fileInLoc");
	       if (! $Lok){ print "*** ERROR in isRdbList, opening '$fileInLoc'\n";
			    return(0);}
	       while (<$fhinLoc>){ 
                   $_=~s/\s|\n//g;
                   if ($_=~/^\#/ || ! -e $_){close($fhinLoc);
                                             return(0);}
                   $fileTmp=$_;
                   if (&isRdb($fileTmp)&&(-e $fileTmp)){
                       close($fhinLoc);
                       return(1);}
                   last;}close($fhinLoc);
	       return(0); }	# end of isRdbList


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
	print "*** ERROR in myprt_npoints: \n";
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
	warn "*** ERROR open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** open_file: Cannot create new file '$file_name'\n" ;}
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
	    print "-*- WARN read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";}
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of read_rdb_num2

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------
    @tmp=("/home/rost/perl/ctime.pl","/nfs/data5/users/ppuser/server/pub/perl/ctime.pl");
				# ------------------------------
				# get function
    if (defined &localtime) {
	foreach $tmp(@tmp){
	    if (-e $tmp){$Lok=require("$tmp");
			 last;}}
	if (defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#	    print "xx enter\n";
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);}
    }
				# ------------------------------
				# or get system time
    $localtime=`date`;
    @Date=split(/\s+/,$localtime);
    $Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]";
    return($Date);
}				# end of sysDate


#==============================================================================
# library collected (end)
#==============================================================================

#==========================================================================================
sub phdRdb2phdWrt {
    local ($fileOutLoc,$idvec,$desvec,$opt_phd,$nres_per_row,$LnoHdr,%all) = @_ ;
    local ($fh,@des,@id,$tmp,@tmp,$id,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    phdRdb2phdWrt              writes into file readable by EVALSEC
#       in:                     $fileOutLoc:     output file name
#       in:                     $idvec:          'id1,id2,..' i.e. all ids to write
#       in:                     $desvec:         
#       in:                     $opt_phd:        sec|acc|htm|?
#       in:                     $nres_per_row:   number of residues per row (80!)
#       in:                     %all
#       out:                    
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."subx";$fh="FHOUT_"."subx";
				# check arguments
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def idvec!")            if (! defined $idvec);
    return(0,"*** $sbrName: not def desvec!")           if (! defined $desvec);
    return(0,"*** $sbrName: not def opt_phd!")          if (! defined $opt_phd);
    return(0,"*** $sbrName: not def nres_per_row!")     if (! defined $nres_per_row);
				# vector to array
    @des=split(/,/,$desvec);
    @id= split(/,/,$idvec);


    &open_file($fh, ">$fileOutLoc");
				# ------------------------------
				# header
    print $fh  "* PHD_DOTPRED_8.95 \n"; # recognised key word!
    print $fh  "*" x 80, "\n","*"," " x 78, "*\n";
    if   ($opt_phd eq "sec"){$tmp="PHDsec: secondary structure prediction by neural network";}
    elsif($opt_phd eq "acc"){$tmp="PHDacc: solvent accessibility prediction by neural network";}
    elsif($opt_phd eq "htm"){$tmp="PHDhtm: helical transmembrane prediction by neural network";}
    else                    {$tmp="PHD   : Profile prediction by system of neural networks";}
    printf $fh "*    %-72s  *\n",$tmp;
    printf $fh "*    %-72s  *\n","~" x length($tmp);
    printf $fh "*    %-72s  *\n"," ";
    if   ($desvec =~/PRHL/) {$tmp="VERSION: REFINE: best model";}
    elsif($desvec =~/PR2HL/){$tmp="VERSION: REFINE: 2nd best model";}
    elsif($desvec =~/PFHL/ ){$tmp="VERSION: FILTER: old stupid filter of HTM";}
    elsif($desvec =~/PHL/ ) {$tmp="VERSION: probably no HTM filter, just network";}
    printf $fh "*    %-72s  *\n",$tmp;
    print  $fh "*"," " x 78, "*\n";
    @tmp=("Burkhard Rost, EMBL, 69012 Heidelberg, Germany",
	  "(Internet: rost\@EMBL-Heidelberg.DE)");
    foreach $tmp (@tmp) {
	printf $fh "*    %-72s  *\n",$tmp;}
    print  $fh "*"," " x 78, "*\n";
    $tmp=&sysDate();
    printf $fh "*    %-72s  *\n",substr($tmp,1,70);
    print  $fh "*"," " x 78, "*\n";
    print  $fh "*" x 80, "\n";
				# numbers
    $tmp=$#id;
    printf $fh "num %4d\n",$tmp;
    if ($opt_phd eq "acc"){print $fh "nos(ummary)\n";}
				# ------------------------------
				# all proteins
    foreach $it (1..$#id) {
	$id=$id[$it]; 
	&wrt_res1_fin($fh,$id,$nres_per_row,$opt_phd,$desvec,$LnoHdr,%all);
    }
    print $fh "END\n";
    close($fh);
    return(1,"ok $sbrName");
}				# end of phdRdb2phdWrt

#==========================================================================================
sub wrt_res1_fin {
    local ($fhLoc2,$id,$nresPerRowLoc,$opt_phd,$desvec,$LnoHdrLoc,%all) = @_ ;
    local ($it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_res1_fin               writes the final output files for EVALSEC/ACC
#         A                     A
#--------------------------------------------------------------------------------
    @des=split(/,/,$desvec);
    $nres=$all{"$id","NROWS"};
				# header (name, length)
    if (! $LnoHdrLoc){
	if ($opt_phd eq "acc"){
	    printf $fhLoc2 "    %-6s %5d\n",substr($id,1,6),$nres;}
	else {
	    printf $fhLoc2 "    %10d %-s\n",$nres,$id;}}
				# rest
    for ($it=1; $it<=$nres; $it+=$nresPerRowLoc ) {
	$tmp=&myprt_npoints($nresPerRowLoc,$it);
	printf $fhLoc2 "%-3s %-s\n"," ",$tmp;
	foreach $des (@des) {
	    if ($opt_phd =~ /sec/)    { if   ($des=~/AA/)       {$txt="AA"; }
					elsif($des=~/OHEL/)     {$txt="DSP"; }
					elsif($des=~/PHEL/)     {$txt="PRD"; }
					elsif($des=~/RI_S/)     {$txt="Rel"; } }
	    elsif ($opt_phd eq "acc") { if   ($des=~/AA/)       {$txt="AA"; }
					elsif($des=~/OHEL/)     {$txt="SS"; }
					elsif($des=~/OREL/)     {$txt="Obs"; }
					elsif($des=~/PREL/)     {$txt="Prd"; }
					elsif($des=~/RI_A/)     {$txt="Rel"; } }
	    elsif ($opt_phd eq "htm") { if   ($des=~/AA/)       {$txt="AA"; }
					elsif($des=~/OHL/)      {$txt="OBS"; }
					elsif($des=~/PHL/)      {$txt="PHD"; }
					elsif($des=~/PFHLOC2L/) {$txt="FIL"; }
					elsif($des=~/PRHL/)     {$txt="PHD"; }
					elsif($des=~/PR2HL/)    {$txt="PHD"; }
					elsif($des=~/RI_S/)     {$txt="Rel"; } }
	    next if (! defined $all{"$id","$des"});
	    next if (length($all{"$id","$des"}) < $it);

	    $tmp=substr($all{"$id","$des"},$it,$nresPerRowLoc);
	    printf $fhLoc2 "%-3s|%-s|\n",$txt,$tmp;
	}
    }
    undef %all;
}				# end of wrt_res1_fin
