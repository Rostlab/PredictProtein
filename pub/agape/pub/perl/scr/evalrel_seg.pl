#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#----------------------------------------------------------------------
# evalhtm_seg
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	evalhtm_seg.pl list(.rdb_phd) files from PHD
#
# task:		in: list of PHDhtm RDB files, out: segment accuracy
# 		
#----------------------------------------------------------------------#
#	Burkhard Rost			September,      1995           #
#			changed:	January	,      	1996           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "evalhtm_seg";
$script_goal      = "in: list of PHDhtm RDB files, out: segment accuracy";
$script_input     = ".rdb_phd files from PHDhtm";
$script_opt_ar[1] = "output file";
$script_opt_ar[2] = "option for PHDx keys=both,sec,acc,htm,";

# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
# #require "xlib-loc.pl";
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
@Date = split(' ',&ctime(time)) ; shift (@Date) ; 

#----------------------------------------
# about script
#----------------------------------------
if ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) || ($#ARGV<1) ) { 
    print "$script_name '$script_input'\n";
    print "\t $script_goal\n";
    print "1st arg= list of RDB files\n";
    print "other  : keys=not_screen, file_out=, fil,ref\n";
    exit;}

#----------------------------------------
# read input
#----------------------------------------
$Lscreen=1;
$file_out= "unk";
$opt_phd=  "unk";
$opt=      "unk";
$file_in= $ARGV[1]; 	

foreach $_(@ARGV){
    if   (/^not_screen/){$Lscreen=0;}
    elsif(/^.*out=/)    {$_=~s/^.*out=//g;
			 $file_out=$_;}
    elsif(/^htm/)       {$opt_phd="htm";}
    elsif(/^sec/)       {$opt_phd="sec";}
    elsif(/^acc/)       {$opt_phd="acc";}
    elsif(/^both/)      {$opt_phd="both";}
    elsif(/^nof/)       {$opt="nof";}
    elsif(/^fil/)       {$opt="fil";}
    elsif(/^ref2/)      {$opt="ref2";}
    elsif(/^ref/)       {$opt="ref";} }

#------------------------------
# defaults
#------------------------------
@relind= (0.50,0.60,0.70,0.80,0.82,
	  0.84,0.85,0.86,0.87,0.88,
	  1.00);		# last (11th for technical reasons)
	  
if ($file_out eq "unk") {
    $tmp=$file_in;$tmp=~s/\.list$//;
    $file_out="Rel-".$tmp . ".dat";}
$fhin=           "FHIN";
$fh=             "FHOUT";
				# security
if ($opt eq "unk"){$opt="ref";}
if ($opt_phd eq "unk"){$opt_phd="htm";}

if    ($opt eq "fil") { $des_prd="PFHL";}
elsif ($opt eq "nof") { $des_prd="PHL"; }
elsif ($opt eq "ref") { $des_prd="PRHL";}
elsif ($opt eq "ref2"){ $des_prd="PR2HL";}
$des_prd_oth=        "OtH";

@des_out=   ("AA","OHL","$des_prd","RI_S");
@des_rd=    ("AA","OHL","$des_prd","RI_S","$des_prd_oth");

$symh=           "H";		# symbol for HTM
$des_obs=        $des_out[2];
$des_prd=        $des_out[3];

#------------------------------
# check existence of file
#------------------------------
if (! -e $file_in) {&myprt_empty; &myprt_txt("ERROR:\t file $file_in does not exist"); exit; }
$#file_in=0;
if ( &is_rdbf($file_in)){
    push(@file_in,$file_in)}
else {
    &open_file($fhin, "$file_in");
    while(<$fhin>){
	$_=~s/\s|\n//g;
	if (length($_)<3) {next;}
	if (-e $_){
	    push(@file_in,$_); }
	else {
	    print "*** evalhtm_seg: file '$_' missing \n";}}
    close($fhin);}
				# --------------------------------------------------
				# loop over all files
				# --------------------------------------------------
$#prot_corr=$#prot_false=$#all_corr=$#all_false=$ctseg=0;
foreach $file_in (@file_in) {
    %rd=&rd_rdb_associative($file_in,"not_screen","header","body",@des_rd);
    if ($rd{"NROWS"}<5) {	# skip short ones
	next; }
    $id=$file_in;$id=~s/^.*\/([^\.]*)\..*/$1/;$id=~s/\.rdb_.*$//g;
    push(@id,$id);
    $nres=$rd{"NROWS"};    
    &anal_seg;
}
				# --------------------------------------------------
				# now write out
				# --------------------------------------------------
#&wrt_res("STDOUT",$opt);

&open_file($fh, ">$file_out");
&wrt_res($fh,$opt);
close($fh);


if ($Lscreen) {
    &myprt_txt("evalhtm_seg output in file: \t '$file_out'"); &myprt_line; }
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


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
sub stat_avevar {
    local(@data)=@_;
    local($i, $ave, $var);
    $[=1;
#----------------------------------------------------------------------
#   stat_avevar                 computes average and variance
#       in:                     @data (vector)
#       out:                    $AVE, $VAR
#          GLOBAL:              $AVE, $VAR (returned as list)
#----------------------------------------------------------------------
    $ave=$var=0;
    foreach $i (@data) { $ave+=$i; } 
    if ($#data > 0) { $AVE=($ave/$#data); } else { $AVE="0"; }
    foreach $i (@data) { $tmp=($i-$AVE); $var+=($tmp*$tmp); } 
    if ($#data > 1) { $VAR=($var/($#data-1)); } else { $VAR="0"; }
    return ($AVE,$VAR);
}				# end of stat_avevar



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
#==========================================================================================
sub anal_seg {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    anal_seg                writes into file readable by EVALSEC
#--------------------------------------------------------------------------------
    $prd=$obs="";
    foreach $itres(1..$nres){
	$obs.=$rd{"$des_obs","$itres"};
	$prd.=$rd{"$des_prd","$itres"};}
				# note: $x{"$symh","beg","$it"}
    %obs= &get_secstr_segment_caps($obs,$symh);
    %prd= &get_secstr_segment_caps($prd,$symh);

				# ------------------------------
				# compute average score
    $#tmp_ave=$sum_ave=0;
    foreach $ctprd (1..$prd{"$symh","NROWS"}) {
	++$ctseg;
	$beg=$prd{"$symh","beg","$ctprd"};
	$end=$prd{"$symh","end","$ctprd"};
	$sum=0;
	foreach $itres ( $beg .. $end ) {
	    $sum+=$rd{"$des_prd_oth","$itres"};}
	$len=$end-$beg+1;
	if ($len>0){
	    $tmp_ave[$ctprd]=$sum/$len;}else{$tmp_ave[$ctprd]=0;}
	$sum_ave+=$tmp_ave[$ctprd];
	print "x.x $id seg=$ctprd, len=$len, sum=$sum, ave=$tmp_ave[$ctprd],\n";}
    $sum_ave=($sum_ave/$prd{"$symh","NROWS"});
				# ini
    foreach $it(1..$prd{"$symh","NROWS"}){$Lok_twice[$it]=1;$Lok[$it]=0;}
				# --------------------------------------------------
				# now for all observed and all predicted segments
    $ctok=0;
    foreach $ctobs (1..$obs{"$symh","NROWS"}) {
	foreach $ctprd (1..$prd{"$symh","NROWS"}) {
	    last if ($prd{"$symh","beg","$ctprd"}>$obs{"$symh","end","$ctobs"});
	    if ($prd{"$symh","end","$ctprd"}<$obs{"$symh","beg","$ctobs"}){
		next;}
	    elsif (($prd{"$symh","beg","$ctprd"}<($obs{"$symh","end","$ctobs"}-3))||
		   ($prd{"$symh","end","$ctprd"}>($obs{"$symh","beg","$ctobs"}+3))){
		if ($Lok_twice[$ctprd]){
		    $Lok_twice[$ctprd]=0;
		    ++$ctok;
		    $Lok[$ctprd]=1;
		    last;}}}
    }
				# now push all averages onto array
    foreach $ctprd (1..$prd{"$symh","NROWS"}) {
	if ($Lok[$ctprd]){
	    push(@all_corr,$tmp_ave[$ctprd]);}
	else { 
	    push(@all_false,$tmp_ave[$ctprd]);}}
				# all correct
    if ($ctok==$obs{"$symh","NROWS"}){
	push(@prot_corr,$sum_ave);}
    else {
	push(@prot_false,$sum_ave);}
}				# end of anal_seg

#==========================================================================================
sub wrt_res {
    local ($fh,$opt) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_res                writes into file readable by EVALSEC
#    allseg:  averages over all segments
#    prot:    averages over all those proteins for which prediction correct, i.e.,
#             all segments correctly predicted (for each of those the average
#             score for a helix was added)
#--------------------------------------------------------------------------------
    $txt{"all"}="all segments used";
    $txt{"prot"}="average values over proteins with all segments correctly predicted";

				# find max
    if ($#all_corr>$#all_false) {$max=$#all_corr;} else {$max=$#all_false;}
				# ------------------------------
				# header
    ($res{"all","corr","ave"},$res{"all","corr","var"})=
	&stat_avevar(@all_corr);
    ($res{"all","false","ave"},$res{"all","false","var"})=
	&stat_avevar(@all_false);
    ($res{"prot","corr","ave"},$res{"prot","corr","var"})=
	&stat_avevar(@prot_corr);
    ($res{"prot","false","ave"},$res{"prot","false","var"})=
	&stat_avevar(@prot_false);
    print $fh "# option : $opt\n"; # header averages
    foreach $des1("all","prot"){
	print $fh "# DATA:  ",$txt{"$des1"},"\n";
	foreach $des2("corr","false"){printf $fh "# DATA:  %-6s (ave,var)",$des2;
				      foreach $des3("ave","var"){
					  printf $fh "%6.2f, ",$res{"$des1","$des2","$des3"};}
				      print $fh "\n";}}
    print  $fh "# HISTO all corr:\n";
    foreach $it (1..$max){
	printf $fh "# HISTO \t%4d\t",$it;
	if(defined $all_corr[$it])  {$tmp1=$all_corr[$it];}  else{$tmp1=0;}
	if(defined $all_false[$it]) {$tmp2=$all_false[$it];} else{$tmp2=0;}
	if(defined $prot_corr[$it]) {$tmp3=$prot_corr[$it];} else{$tmp3=0;}
	if(defined $prot_false[$it]){$tmp4=$prot_false[$it];}else{$tmp4=0;}
	printf $fh "%6.2f\t%6.2f\t%6.2f\t\t%6.2f",$tmp1,$tmp2,$tmp3,$tmp4;
	print $fh "\n";}
    foreach $des3("ave","var"){
	printf $fh "# HISTO \t%4s",$des3;
	foreach $des2("corr","false"){
	    foreach $des1("all","prot"){
		printf $fh "\t%6.2f",$res{"$des1","$des2","$des3"};}}
	print $fh "\n";}

				# now do analysis of cumulative values, for all 
    foreach $ri (1..10) {$corr_all[$ri]=$false_all[$ri]=0;} # ini
    foreach $seg (@all_corr){
	$seg=$seg/100;
	for ($ri=10;$ri>=1;--$ri){if ( ($seg<=$relind[$ri+1]) && ($seg>$relind[$ri]) ) {
	    ++$corr_all[$ri];last;}}}
    foreach $seg (@all_false){
	$seg=$seg/100;
	foreach $ri (1..10) {if ( ($seg<=$relind[$ri+1]) && ($seg>$relind[$ri]) ) {
	    ++$false_all[$ri];last;}}}
    $ntot=$ctseg;
    $nsum=$sum=$nsum_corr=0;	# cumulative
    for ($it=10;$it>=1;--$it){
	$nsum_corr+=$corr_all[$it];$nsum+=($corr_all[$it]+$false_all[$it]);
	$ncum_all[$it]=$nsum_corr;$pcum_all[$it]=100*($nsum/$ntot);
	if ($nsum>0){$cum_all[$it]=100*($nsum_corr/$nsum);}else{$cum_all[$it]=0;}}
				# now for correctly predicted proteins
    foreach $ri (1..10) {$corr_prot[$ri]=$false_prot[$ri]=0;} # ini
    foreach $seg (@prot_corr){
	$seg=$seg/100;
	for ($ri=10;$ri>=1;--$ri){if ( ($seg<=$relind[$ri+1]) && ($seg>$relind[$ri]) ) {
	    ++$corr_prot[$ri];last;}}}
    foreach $seg (@prot_false){
	$seg=$seg/100;
	foreach $ri (1..10) {if ( ($seg<=$relind[$ri+1]) && ($seg>$relind[$ri]) ) {
	    ++$false_prot[$ri];last;}}}
    $ntot=$#file_in;
    $nsum=$sum=$nsum_corr=0;		# cumulative
    for ($it=10;$it>=1;--$it){
	$nsum_corr+=$corr_prot[$it];$nsum+=($corr_prot[$it]+$false_prot[$it]);
	$ncum_prot[$it]=$nsum_corr;$pcum_prot[$it]=100*($nsum/$ntot);
	if ($nsum>0){$cum_prot[$it]=100*($nsum_corr/$nsum);}else{$cum_prot[$it]=0;}}
				# print
    print  $fh "# \n";
    printf $fh "%-5s\t%4s\t%5s\t","RI","ri","valRi";
    printf $fh "%6s\t%6s\t%6s\t","Qall","Ndiff","Nall","Pall";
    printf $fh "%6s\t%6s\t%6s\n","Qprot","Ndiff","Nprot","Pprot";
    foreach $ri (1..10) {
	printf $fh "%-5s\t%4d\%5.2f\t","RI",$ri-1,$relind[$ri];
	printf $fh 
	    "%6.2f\t%6d\t%6.2f\t",$cum_all[$ri],($corr_all[$ri]+$false_all[$ri]),
	    $ncum_all[$ri],$pcum_all[$ri];
	printf $fh 
	    "%6.2f\t%6d\t%6.2f\n",$cum_prot[$ri],($corr_prot[$ri]+$false_prot[$ri]),
	    $ncum_prot[$ri],$pcum_prot[$ri];}
    exit;			# x.x

}				# end of wrt_res

