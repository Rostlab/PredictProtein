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
if ($file_out eq "unk") {
    $tmp=$file_in;$tmp=~s/\.list$//;
    $file_out="Seg-".$tmp . ".dat";
    $file_out_det="Segdet-".$tmp . ".dat";}
else {
    $file_out_det=$file_out;$file_out_det=~s/_ana$/_det/;}

$fhin=           "FHIN";
$fh=             "FHOUT";
$fh2=            "FHOUT_DET";
$Lscreen=        1;

@des_rd= ("AA","OHL","PHL","PFHL","RI_S","PRHL","PR2HL");

@des_out=("AA","OHL","PFHL","RI_S");
#@des_out=("AA","OHL","PRHL","RI_S");
#@des_out=("AA","OHL","P2RHL","RI_S");

if    ($opt eq "fil") { @des_out=("AA","OHL","PFHL","RI_S");}
elsif ($opt eq "nof") { @des_out=("AA","OHL","PHL","RI_S");}
elsif ($opt eq "ref") { @des_out=("AA","OHL","PRHL","RI_S");}
elsif ($opt eq "ref2"){ @des_out=("AA","OHL","PR2HL","RI_S");}

@des_res=("Nok","Nobs","Nphd","NPok","NPoks","RiRef","RiRefD");

$symh=           "H";		# symbol for HTM
$des_obs=        $des_out[2];
$des_phd=        $des_out[3];

$des_Nok=        $des_res[1];	# key for number of correctly predicted
$des_Nobs=       $des_res[2];	# key for number of observed helices
$des_Nphd=       $des_res[3];	# key for number of predicted helices
$des_Nphd2=      "Nphd2";	# key for number of predicted helices for 2nd best model
$des_NPok=       $des_res[4];	# key for number of proteins correctly predicted
				# correct number of helices(100%)
$des_NPoks=      $des_res[5];	# key for number of proteins correctly predicted
				# if more HTM are allowed to be predicted in end
$des_riref=      $des_res[6];	# key for reliability of refinement model (zscore)
$des_rirefD=     $des_res[7];	# key for reliability of refinement model (best-snd)

if ($opt_phd eq "unk"){		# security
    $opt_phd="htm";}

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
$ctfile=$#id=$#ri=$#riD=$#nphd2=0;
foreach $file_in (@file_in) {
    %rd=&rd_rdb_associative($file_in,"header","NHTM_2ND_BEST","REL_BEST","REL_BEST_DIFF",
			    "body",@des_rd);
    if ($rd{"NROWS"}<5) {	# skip short ones
	next; }
    ++$ctfile;
    $id=$file_in;$id=~s/^.*\/([^\.]*)\..*/$1/;$id=~s/\.rdb_.*$//g;
    push(@id,$id);
    if ($opt=~/ref/){
	$rel_best=$rd{"REL_BEST"};$rel_best=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$rel_best=~s/\s|\n//g;
	$rel_bestD=$rd{"REL_BEST_DIFF"};
	$rel_bestD=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$rel_bestD=~s/\s|\n//g;
	$nphd2=$rd{"NHTM_2ND_BEST"};$nphd2=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$nphd2=~s/\s|\n//g;
	push(@ri,$rel_best); push(@riD,$rel_bestD); push(@nphd2,$nphd2); }
    $all{"$id","NROWS"}=$rd{"NROWS"};
    foreach $des (@des_rd){
	$all{"$id","$des"}="";
	foreach $itres (1..$rd{"NROWS"}){
	    $all{"$id","$des"}.=$rd{"$des","$itres"}; }
				# convert L->" "
	if ($des=~/O.*L|P.*L/){
            if ($opt_phd eq "htm") {
                $all{"$id","$des"}=~s/E/ /g;}
	    $all{"$id","$des"}=~s/L/ /g;} }
}
				# --------------------------------------------------
				# analyse segment accuracy
				# --------------------------------------------------
$idvec= ""; foreach $id (@id) {$idvec.="$id\t";} $idvec=~s/\t$//g;

%res=
    &anal_seg($idvec,$symh,$des_obs,$des_phd,
	      $des_Nok,$des_NPok,$des_NPoks,$des_Nobs,$des_Nphd,%all);
				# add ri
if ($opt=~/ref/){
    foreach $it(1..$#id){$res{"$id[$it]","$des_riref"}=$ri[$it];}
    foreach $it(1..$#id){$res{"$id[$it]","$des_rirefD"}=$riD[$it];}
    foreach $it(1..$#id){$res{"$id[$it]","$des_Nphd2"}=$nphd2[$it];}}
				# --------------------------------------------------
				# now write out
				# --------------------------------------------------
$desvec=""; foreach $des (@des_res){$desvec.="$des\t";} $desvec=~s/\t$//g;
$idvec= ""; foreach $id (@id) {$idvec.="$id\t";} $idvec=~s/\t$//g;

&wrt_res("STDOUT",$opt,$idvec,$desvec,%res);

&open_file($fh, ">$file_out");
&wrt_res($fh,$opt,$idvec,$desvec,%res);
close($fh);


if ($Lscreen) {
    &myprt_txt("evalhtm_seg output in file: \t '$file_out'"); &myprt_line; }
    
exit;

#==========================================================================================
sub anal_seg {
    local ($idvec,$symh,$des_obs,$des_phd,
	   $des_Nok,$des_NPok,$des_NPoks,$des_Nobs,$des_Nphd,%all) = @_ ;
    local ($fhx,@des,@id,$tmp,@tmp,$id,$it,@fh);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    anal_seg                writes into file readable by EVALSEC
#--------------------------------------------------------------------------------
				# vector to array
    @id=split(/\t/,$idvec);
    $ctprot_ok=$ctprot_oksucc=$ctres_ok=$ctres_obs=$ctres_phd=0;
    $#fh=0;push(@fh,$fh2);if ($Lscreen){push(@fh,"STDOUT");}
    
    &open_file($fh2, ">$file_out_det");
    foreach $fhx (@fh) {
	printf $fhx
	    "%-15s %-3s %-3s-%-3s %-3s %-3s-%-3s\n","id","obs","beg","end","phd","beg","end";}
    foreach $it (1..$#id){
	$id=$id[$it];
				# note: $x{"$symh","beg","$it"}
	%obs= &get_secstr_segment_caps($all{"$id","$des_obs"},$symh);
	%phd= &get_secstr_segment_caps($all{"$id","$des_phd"},$symh);

	$ctres_obs+=$obs{"$symh","NROWS"};
	$ctres_phd+=$phd{"$symh","NROWS"};
	foreach $fhx (@fh) {
	    printf $fhx
		"%-15s %-3d %-3s-%-3s %-3d %-3s-%-3s\n",
		"$id",$obs{"$symh","NROWS"}," "," ",$phd{"$symh","NROWS"}," ","";}
				# ini
	foreach $it(1..$phd{"$symh","NROWS"}){$Lok[$it]=1;}
	$ctok=$ctsucc=0;
	foreach $ctobs (1..$obs{"$symh","NROWS"}) {
	    foreach $ctphd (1..$phd{"$symh","NROWS"}) {
		last if ($phd{"$symh","beg","$ctphd"}>$obs{"$symh","end","$ctobs"});
		if ($phd{"$symh","end","$ctphd"}<$obs{"$symh","beg","$ctobs"}){
		    next;}
		elsif (($phd{"$symh","beg","$ctphd"}<($obs{"$symh","end","$ctobs"}-3))||
		       ($phd{"$symh","end","$ctphd"}>($obs{"$symh","beg","$ctobs"}+3))){
		    if ($Lok[$ctphd]){
			if ($ctok==0){$fst_phd=$ctphd;}
			if (($ctobs==$ctphd)||(($ctphd-$fst_phd+1)==$ctobs)){
			    ++$ctsucc;}
			foreach $fhx (@fh) {
			    printf $fhx
				"%-15s %-3d %-3d-%-3d %-3d %-3d-%-3d\n"," ",
				$ctobs,$obs{"$symh","beg","$ctobs"},
				$obs{"$symh","end","$ctobs"},$ctphd,
				$phd{"$symh","beg","$ctphd"},$phd{"$symh","end","$ctphd"};}
				
			$Lok[$ctphd]=0;
			++$ctok;
			last;}}}}
	$res{"$id","$des_Nok"}= $ctok;
	$res{"$id","$des_Nobs"}=$obs{"$symh","NROWS"};
	$res{"$id","$des_Nphd"}=$phd{"$symh","NROWS"};
	$res{"$id","$des_NPok"}=0;
	$res{"$id","$des_NPoks"}=0;
	$ctres_ok+=$ctok;
	if (($obs{"$symh","NROWS"}==$phd{"$symh","NROWS"}) &&
	    ($obs{"$symh","NROWS"}==$ctok)){
	    $res{"$id","$des_NPok"}=100;
	    ++$ctprot_ok;}
	if ($obs{"$symh","NROWS"}==$ctsucc){
	    $res{"$id","$des_NPoks"}=100;
	    ++$ctprot_oksucc;}
    }
    $res{"NROWS"}=$#id;
    $res{"$des_NPok"}=$ctprot_ok;
    $res{"$des_NPoks"}=$ctprot_oksucc;
    $res{"$des_Nobs"}=$ctres_obs;
    $res{"$des_Nphd"}=$ctres_phd;
    $res{"$des_Nok"}=$ctres_ok;
    close($fh2);		# close file to write out details
    return(%res);
}				# end of anal_seg

#==========================================================================================
sub wrt_res {
    local ($fh,$opt,$idvec,$desvec,%res) = @_ ;
    local (@des,@id,$tmp,$tmpqobs,$tmpqphd,$id,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_res                writes into file readable by EVALSEC
#
#    note: 
#                           des(1)=Nok,des(2)=Nobs,des(3)=Nphd,des(4)=NPok,des(5)=NPoks,
#                           des(6)=RiRef,des(7)=RiRef
#--------------------------------------------------------------------------------
				# vector to array
    @des=split(/\t/,$desvec);
    @id=split(/\t/,$idvec);
    foreach $_(@des){if (/prot.*ok/){$des_NPok=$_;last;}}
				# ------------------------------
				# header
    if ($res{"NROWS"}>0){$tmp=$res{"$des_NPok"}/$res{"NROWS"};
			 $tmps=$res{"$des_NPoks"}/$res{"NROWS"}; }else{$tmp=$tmps=0;}
    
    print  $fh "# final averages:\n";
    printf $fh "# Nok   :%6s,%4d   (N seg correct)  \n"," ",$res{"$des[1]"};
    printf $fh "# Nobs  :%6s,%4d   (N seg observed) \n"," ",$res{"$des[2]"};
    printf $fh "# Nprd  :%6s,%4d   (N seg predicted)\n"," ",$res{"$des[3]"};
    printf $fh "# Nprot :%6s,%4d   (N proteins)     \n"," ",$res{"NROWS"};
    printf $fh "# NPok  :%6.1f,%4d   (P correct)\n",100*($tmp),$res{"$des[4]"};
    printf $fh "# NPoks :%6.1f,%4d   (P corr succession)\n",100*($tmps),$res{"$des[5]"};
    print  $fh "# \n";

    printf $fh "# NOTATION: NPok       number of proteins with Nhtm pred=obs=ok\n";
    printf $fh "# NOTATION: NPok(id)=  100 or 0, \n";
    printf $fh "# NOTATION: NPoks      at least 'core' same number, i.e., succession ok\n";
    printf $fh "# NOTATION: NPoks(id)= 100 or 0, \n";
    printf $fh "# NOTATION: RiRef      reliability of refinement model (zscore)\n";
    printf $fh "# NOTATION: RiRefD     reliability of refinement model (best-snd/len)\n";
    printf $fh "# NOTATION: \n";
    printf $fh "#  \n";
				# names
    printf $fh "%-12s\t","id";
    foreach $it( 1 .. ($#des-2) ){printf $fh "%4s\t",$des[$it];}
    if ($opt=~/ref/){
	printf $fh "%4s\t",$des_Nphd2;
	foreach $it( ($#des-1) .. $#des ){printf $fh "%4s\t",$des[$it];} }
    printf $fh "%5s\t%5s\n","Qobs","Qphd";
				# ------------------------------
				# all proteins
    $qobs=$qphd=$riref=$rirefD=$Nphd2=0;
    foreach $it (1..$#id) {
	$id=$id[$it];
	printf $fh "%-12s\t","$id";
	foreach $itdes(1..($#des-2)){
	    printf $fh "%4d\t",$res{"$id","$des[$itdes]"};}
	if ($opt=~/ref/){
	    $tmp1=$res{"$id","$des[$#des-1]"};$tmp2=$res{"$id","$des[$#des]"};
	    $tmp3=$res{"$id","$des_Nphd2"};}else{$tmp1=$tmp2=$tmp3=0;}
	if ($opt=~/ref/){	# RiRef , RiRefD
	    printf $fh 
		"%4d\t%5.2f\t%5.3f\t",
		$res{"$id","$des_Nphd2"},$res{"$id","$des[$#des-1]"},$res{"$id","$des[$#des]"};}
	$riref+=$tmp1;$rirefD+=$tmp2;$Nphd2+=$tmp3;

	if ($res{"$id","$des[2]"}>0) {
	    $tmpqobs=100*($res{"$id","$des[1]"}/$res{"$id","$des[2]"});}else {$tmpqobs=0;}
	if ($res{"$id","$des[3]"}>0) {
	    $tmpqphd=100*($res{"$id","$des[1]"}/$res{"$id","$des[3]"});}else {$tmpqphd=0;}
	$qobs+=$tmpqobs;$qphd+=$tmpqphd;	# sum
	printf $fh "%5.1f\t%5.1f\n",$tmpqobs,$tmpqphd;
    }
    printf $fh "%-12s\t","all $#id";
    foreach $itdes(1..($#des-4)){
	printf $fh "%4d\t",$res{"$des[$itdes]"};}
    foreach $itdes(($#des-3)..($#des-2)){
	printf $fh "%4d\t",int(100*($res{"$des[$itdes]"}/$#id));}
    if ($opt=~/ref/){
	$tmp1=($riref/$#id);$tmp2=($rirefD/$#id);$tmp3=($Nphd2/$#id);
	printf $fh "%4d\t%5.2f\t%5.3f\t",int(100*$tmp3);$tmp1,$tmp2; }
    printf $fh "%5.1f\t%5.1f\n",($qobs/$#id),($qphd/$#id);

}				# end of wrt_res

