#!/usr/sbin/perl -w
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

push (@INC, "/home/rost/perl") ;
# require "ctime.pl"; # require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
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

